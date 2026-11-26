"""Optional CUDA experiments for ragged scale-space Gram and Rips apparent pairs."""
import argparse
import json
from pathlib import Path
from statistics import median
from time import perf_counter

import cupy as cp
import numpy as np

GRAM = r"""
extern "C" __global__ void gram(
    const double* points, const int* offsets, double* out, int n, double sigma
) {
    const int i = blockIdx.x, j = blockIdx.y;
    if (i > j) return;
    const int m = offsets[i+1] - offsets[i], k = offsets[j+1] - offsets[j];
    __shared__ double partial[128];
    double value = 0.;
    for (long long t = threadIdx.x; t < (long long)m*k; t += blockDim.x) {
        const int a = 2*(offsets[i] + t/k), b = 2*(offsets[j] + t%k);
        const double x = points[a], y = points[a+1], u = points[b], v = points[b+1];
        const double dx = x-u, dy = y-v;
        value += exp(-(dx*dx + dy*dy)/(8.*sigma)) *
                 (-expm1(-(y-x)*(v-u)/(4.*sigma)));
    }
    partial[threadIdx.x] = value;
    __syncthreads();
    for (int step = blockDim.x/2; step > 0; step /= 2) {
        if (threadIdx.x < step) partial[threadIdx.x] += partial[threadIdx.x+step];
        __syncthreads();
    }
    if (!threadIdx.x) {
        out[i*n+j] = out[j*n+i] = partial[0]/(8.*3.141592653589793*sigma);
    }
}
"""

APPARENT = r"""
extern "C" __global__ void apparent(
    const float* graph, const int* columns, int* out, int n, int count, int width
) {
    const int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i >= count) return;
    const int* vertices = columns + i * width;
    float grade = 0.f;
    for (int a = 0; a < width; ++a)
        for (int b = 0; b < a; ++b)
            grade = fmaxf(grade, graph[vertices[a]*n + vertices[b]]);

    out[i] = 0;
    for (int x = n-1; x >= 0; --x) {
        float new_grades[4];
        bool qualifies = true;
        for (int a = 0; a < width; ++a) {
            const float grade_ax = graph[x*n + vertices[a]];
            if (grade_ax == 0.f || grade_ax > grade) {
                qualifies = false;
                break;
            }
            new_grades[a] = grade_ax;
        }
        if (!qualifies) continue;

        // Dropping a vertex larger than x gives a smaller colex index.
        // Only an equal-grade facet with that smaller index can be younger.
        for (int drop = 0; drop < width && vertices[drop] > x; ++drop) {
            for (int a = 0; a < width; ++a) {
                if (a == drop) continue;
                if (new_grades[a] == grade) return;
                for (int b = 0; b < a; ++b) {
                    if (b != drop && graph[vertices[a]*n + vertices[b]] == grade) return;
                }
            }
        }
        out[i] = x + 1;
        return;
    }
}
"""


def transfer_benchmark(inputs, result_shape, dtype, launch, repeats):
    pool = cp.get_default_memory_pool()
    stream = cp.cuda.get_current_stream()

    def run():
        start = perf_counter()
        device_inputs = [cp.asarray(data) for data in inputs]
        stream.synchronize()
        upload = perf_counter()
        device_out = cp.empty(result_shape, dtype)
        launch(device_inputs, device_out)
        stream.synchronize()
        computed = perf_counter()
        result = device_out.get()
        end = perf_counter()
        return result, (upload - start, computed - upload, end - computed, end - start), pool.total_bytes()

    pool.free_all_blocks()
    before, _ = cp.cuda.runtime.memGetInfo()
    cold, first, peak = run()
    samples = []
    for _ in range(repeats):
        result, sample, used = run()
        samples.append(sample)
        peak = max(peak, used)
    after, _ = cp.cuda.runtime.memGetInfo()
    fields = ("upload", "compute", "download", "end_to_end")
    return result, {
        "first_seconds": dict(zip(fields, first)),
        "median_seconds": {key: median(times) for key, times in zip(fields, zip(*samples))},
        "peak_vram_pool_bytes": peak,
        "device_memory_delta_bytes": before - after,
    }


def gram_sweep(directory, repeats):
    kernel = cp.RawKernel(GRAM, "gram")
    for path in sorted(directory.glob("gram-*.tsv")):
        n, m = map(int, path.stem.split("-")[1:])
        unpacked = np.loadtxt(path, ndmin=2)
        start = perf_counter()
        finite = unpacked[np.isfinite(unpacked[:, 2])]
        counts = np.bincount(finite[:, 0].astype(int), minlength=n)
        offsets = np.concatenate(([0], np.cumsum(counts, dtype=np.int64))).astype(np.int32)
        points = np.ascontiguousarray(finite[:, 1:], dtype=np.float64)
        packing = perf_counter() - start
        reference = np.fromfile(path.with_suffix(".f64"), dtype=np.float64).reshape((n, n), order="F")

        def launch(inputs, output):
            kernel((n, n), (128,), (*inputs, output, np.int32(n), np.float64(0.7)))

        actual, stats = transfer_benchmark([points, offsets], (n, n), np.float64, launch, repeats)
        np.testing.assert_allclose(actual, reference, rtol=1e-12, atol=1e-13)
        yield dict(stats, experiment="scale-space", diagrams=n, max_intervals=m,
                   empty_diagrams=int(np.count_nonzero(counts == 0)),
                   essential_intervals=len(unpacked) - len(finite),
                   packing_seconds=packing, max_absolute_error=float(np.max(abs(actual-reference))))


def apparent_pairs(directory, repeats):
    n, width, count = map(int, (directory / "shape.txt").read_text().split())
    if width not in (3, 4):
        raise ValueError("the apparent-pair prototype supports H2 and H3")
    distances = np.fromfile(directory / "graph.f32", dtype=np.float32)
    columns = np.fromfile(directory / "columns.i32", dtype=np.int32)
    expected = np.fromfile(directory / "matches.i32", dtype=np.int32)
    kernel = cp.RawKernel(APPARENT, "apparent")

    def launch(inputs, output):
        kernel(((count + 127)//128,), (128,), (*inputs, output, np.int32(n),
                                             np.int32(count), np.int32(width)))

    result, stats = transfer_benchmark([distances, columns], count, np.int32, launch, repeats)
    np.testing.assert_array_equal(result, expected)
    yield dict(stats, experiment="apparent-pairs", points=n, width=width, columns=count,
               pairs=int(np.count_nonzero(result)))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("experiment", choices=["gram", "apparent"])
    parser.add_argument("input", type=Path)
    parser.add_argument("--repeats", type=int, default=5)
    args = parser.parse_args()
    if args.repeats < 1:
        parser.error("repeats must be positive")
    cp.cuda.runtime.free(0)
    metadata = cp.cuda.runtime.getDeviceProperties(cp.cuda.Device().id)
    experiment = gram_sweep if args.experiment == "gram" else apparent_pairs
    for record in experiment(args.input, args.repeats):
        print(json.dumps(dict(record, gpu=metadata["name"].decode(), cupy=cp.__version__,
                              driver=cp.cuda.runtime.driverGetVersion(),
                              runtime=cp.cuda.runtime.runtimeGetVersion())), flush=True)


if __name__ == "__main__":
    main()
