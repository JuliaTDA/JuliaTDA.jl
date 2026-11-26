"""One peer benchmark per process so the runner can measure peak RSS."""
import argparse
from importlib.metadata import version
from pathlib import Path
from shutil import copyfile
from statistics import median
from time import perf_counter

import numpy as np


def measure(operation, endpoints, repeats, output_path):
    times = []
    for sample in range(repeats + 1):
        start = perf_counter()
        output = operation()
        times.append(perf_counter() - start)
        bars = np.asarray(sorted(map(tuple, endpoints(output))), dtype=np.float64).reshape(-1, 3)
        path = output_path.with_suffix(f".sample-{sample}.tsv")
        np.savetxt(path, bars, delimiter="\t", fmt=["%d", "%.17g", "%.17g"])
    copyfile(path, output_path)
    print("timing", "end_to_end", times[0], median(times[1:]), "",
          ",".join(map(str, times[1:])), sep="\t")
    return output


def rips_bars(diagrams):
    return [(d, b, e) for d, diagram in enumerate(diagrams) for b, e in diagram]


def cubical_bars(result):
    bars = result[:, :3].copy()
    # CubicalRipser V-construction uses maximum Float64 for essential deaths.
    bars[bars[:, 2] == np.finfo(np.float64).max, 2] = np.inf
    return bars


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("workload")
    parser.add_argument("method")
    parser.add_argument("data")
    parser.add_argument("output", type=Path)
    parser.add_argument("n", type=int)
    parser.add_argument("dim", type=int)
    parser.add_argument("threshold", type=float)
    parser.add_argument("threads", type=int)
    parser.add_argument("repeats", type=int)
    args = parser.parse_args()

    print("version", "NumPy", np.__version__, sep="\t")
    print("count", "threads", args.threads, sep="\t")
    if args.workload == "rips":
        from gph import ripser_parallel

        print("version", "giotto-ph", version("giotto-ph"), sep="\t")
        matrix = np.fromfile(args.data, np.float32).reshape((args.n, args.n))
        measure(lambda: ripser_parallel(
            matrix, metric="precomputed", maxdim=args.dim, coeff=2,
            thresh=np.float32(args.threshold), n_threads=args.threads,
            collapse_edges=args.method == "giotto-collapse",
        )["dgms"], rips_bars, args.repeats, args.output)
    else:
        import cripser

        print("version", "cripser", version("cripser"), sep="\t")
        shape = (args.n,) * (2 if args.workload == "image" else 3)
        grid = np.fromfile(args.data, np.float64).reshape(shape, order="F")
        locations = args.method == "cripser-locations"
        result = measure(lambda: cripser.computePH(
            grid, maxdim=args.dim, top_dim=False, location="yes" if locations else "none",
            n_threads=args.threads,
        ), cubical_bars, args.repeats, args.output)
        if locations:
            bars = cubical_bars(result)
            print("count", "birth_locations", len(bars), sep="\t")
            print("count", "death_locations", np.isfinite(bars[:, 2]).sum(), sep="\t")


if __name__ == "__main__":
    main()
