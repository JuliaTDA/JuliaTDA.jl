# Persistence performance benchmarks

Use sibling checkouts of JuliaTDA and the dependency packages. From the workspace
root, resolve them with JuliaTDA's local source setup.

```sh
julia --project=JuliaTDA.jl JuliaTDA.jl/scripts/setup.jl --local
python3.11 -m venv /tmp/juliatda-bench-venv
. /tmp/juliatda-bench-venv/bin/activate
python -m pip install numpy==2.4.6 giotto-ph==0.2.4 cripser==0.0.38
B=JuliaTDA.jl/benchmarks/performance
OUT=/tmp/juliatda-bench
python "$B/run.py" "$OUT" --sweep --record-peer-mismatches
```

The runner uses one fresh process per implementation and fixture. Linux GNU
`time` measures peak RSS for that process. Cold operation time includes the
first call's JIT compilation, where applicable. Process wall time also includes
runtime startup, imports, fixture I/O, repeated calls and result serialization.
The raw samples and medians exclude fixture I/O. The runner compares every
peer sample and records mismatches with full endpoint deltas. An unexpected
mismatch returns a nonzero exit status by default. Use
`--record-peer-mismatches` to finish a comparison that includes a known
unstable peer. Julia also reports managed
allocation per timed call. Julia cubical processes gather stage measurements
after end-to-end measurements, so their peak RSS covers both probes. Hardware,
revisions, working-tree fingerprints, input hashes, observed package versions,
precisions, field, thread counts and output metadata are recorded in the output.

The Rips peers share symmetric Float32 distance matrices and cutoffs on
`torus10k`, `klein500` and `o3_1024`. The torus additionally measures Float64
point-cloud construction, including the cost of finding distances. The runner
rounds the torus point-cloud endpoints to the shared matrix precision for
comparison. The sparse Float64 paths can also be compared directly using the
saved output files. CubicalRipser and Julia use the same vertex-valued input
with a non-periodic boundary and compare every endpoint, including infinite
deaths. Their location metadata is available on the indicated arms. Tied
locations can differ between implementations. The volume fixture consists of
quantized periodic functions sampled in a box with a non-periodic boundary.

Use `--workload torus`, `--workload klein`, `--workload o3`, `--workload lena` or
`--workload volume` to select fixtures. Repeating the option selects multiple
fixtures. Set `--threads` to change the threaded arms or `--repeats` to change
the number of warm samples. Choose separate output directories for runs you
want to keep.

## Julia sweeps

These commands compare a serial pairwise nerve with point memberships, sweep
radius graph construction, and compare ToMATo to a whole-vector relabeling
reference using the same merge rule.

```sh
export OPENBLAS_NUM_THREADS=1
julia --project=JuliaTDA.jl -t 8 "$B/sweeps.jl" nerves
julia --project=JuliaTDA.jl -t 1 "$B/sweeps.jl" radius
julia --project=JuliaTDA.jl -t 1 "$B/sweeps.jl" tomato
julia --project=JuliaTDA.jl -t 1 "$B/sweeps.jl" multiparameter
for t in 1 2 4 8; do
    /usr/bin/time -f 'peak_rss_kib=%M' julia --project=JuliaTDA.jl -t "$t" \
        "$B/sweeps.jl" permutation 112 "$t"
    julia --project=JuliaTDA.jl -t "$t" "$B/sweeps.jl" kernel "$OUT/grams"
done
julia --project=JuliaTDA.jl -t 1 "$B/collapse_profile.jl" "$OUT/klein-500-1.5/input.bin" 500 1.5
julia --project=JuliaTDA.jl -t 1 "$B/collapse_profile.jl" "$OUT/o3-1024-1.8/input.bin" 1024 1.8
```

Permutation output fields are points per sample, workers, p-value, warm
milliseconds and Julia-allocated MiB. Every worker count is checked against the
complete seeded serial null distribution.

## Optional CUDA experiments

Use a CUDA-capable device and an appropriate CuPy installation. The recorded
GPU run used CuPy CUDA 12 version 14.2.0 with CUDA runtime 12.9.

```sh
python -m pip install cupy-cuda12x==14.2.0
python "$B/device.py" gram "$OUT/grams"
julia --project=JuliaTDA.jl -t 8 "$B/apparent_input.jl" \
    "$OUT/klein-500-1.5/input.bin" "$OUT/apparent-klein" 500 2 1.5 300000
python "$B/device.py" apparent "$OUT/apparent-klein"
julia --project=JuliaTDA.jl -t 8 "$B/apparent_input.jl" \
    "$OUT/o3-1024-1.8/input.bin" "$OUT/apparent-o3" 1024 3 1.8 300000
python "$B/device.py" apparent "$OUT/apparent-o3"
```

The scale-space prototype removes essential intervals and packs finite intervals
with offsets, including zero-length slices for empty diagrams. It compares the
Float64 Gram matrix with Julia. The separate apparent-pair experiment checks
every selected cofacet on supplied, already assembled dense Rips columns. It
measures discovery only. CUDA timings synchronize upload, compute, and download.
VRAM is reported as a high-water mark for CuPy's device array pool. The separate
device free-memory delta includes driver overhead and can reflect activity by
other users of the device.
