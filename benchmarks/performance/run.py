"""Run cross-framework PH benchmarks and verify whole barcode multisets."""
import argparse
from collections import Counter
import hashlib
import json
import os
from pathlib import Path
import platform
import subprocess
import sys
from time import perf_counter

import numpy as np

HERE = Path(__file__).resolve().parent
UMBRELLA = HERE.parents[1]
WORKSPACE = UMBRELLA.parent
DATA = WORKSPACE / "TDARipserer.jl" / "benchmark" / "data"
CASES = {
    "torus": ("rips", "torus10k.pts", 5000, 2, 0.15),
    "klein": ("rips", "klein500.pts", 500, 2, 1.5),
    "o3": ("rips", "o3_1024.pts", 1024, 3, 1.8),
    "lena": ("image", "lena1024.dipha", 256, 1, float("inf")),
    "volume": ("volume", "", 32, 2, float("inf")),
}
SWEEP = {
    "torus": [(2500, 0.10), (2500, 0.20), (5000, 0.10)],
    "klein": [(250, 1.25), (250, 1.5), (500, 1.25)],
    "o3": [(512, 1.6), (512, 1.8), (1024, 1.6)],
    "lena": [(512, float("inf")), (1024, float("inf"))],
    "volume": [(64, float("inf"))],
}


def git_source(repo):
    def git(*args):
        return subprocess.check_output(["git", "-C", repo, *args])
    status = git("status", "--porcelain").decode().splitlines()
    digest = hashlib.sha256(git("diff", "--binary", "HEAD"))
    for filename in git("ls-files", "--others", "--exclude-standard", "-z").decode().split("\0"):
        if filename:
            digest.update(filename.encode())
            digest.update((repo / filename).read_bytes())
    return {"revision": git("rev-parse", "HEAD").decode().strip(),
            "working_tree_sha256": digest.hexdigest(), "working_tree_changes": status}


def run_process(command, env, temp):
    rss_file = temp / "rss.txt"
    start = perf_counter()
    output = subprocess.check_output(
        ["/usr/bin/time", "-f", "%M", "-o", rss_file, *command], env=env, text=True
    )
    result = {"process_seconds": perf_counter() - start,
              "peak_rss_kib": int(rss_file.read_text()), "stages": {}}
    for line in output.splitlines():
        fields = line.split("\t")
        if len(fields) < 2:
            continue
        tag, name, *values = fields
        if tag == "timing":
            cold, warm, allocations, runs = values
            result["stages"][name] = {
                "first_seconds": float(cold), "warm_median_seconds": float(warm),
                "warm_samples_seconds": list(map(float, runs.split(","))),
                "warm_median_allocated_bytes": float(allocations) if allocations else None,
            }
        elif tag == "count":
            result[name] = int(values[0])
        elif tag == "version":
            result.setdefault("versions", {})[name] = values[0]
    return result


def barcode(path, precision=np.float64):
    if path.stat().st_size == 0:
        return Counter()
    rows = np.loadtxt(path, ndmin=2, dtype=precision)
    return Counter(map(tuple, rows.tolist()))


def barcode_delta(reference, observed):
    result = {}
    for key, delta in (("missing", reference - observed), ("extra", observed - reference)):
        result[key] = [[int(dim), birth, None if np.isposinf(death) else death, count]
                       for (dim, birth, death), count in sorted(delta.items())]
    return result


def validate_barcodes(reference, files, precision):
    runs = [barcode(file, precision) for file in files]
    reference = runs[0] if reference is None else reference
    matches = [run == reference for run in runs]
    mismatches = [{"sample": i, **barcode_delta(reference, bars)} for i, bars in enumerate(runs)
                  if not matches[i]]
    return reference, runs[-1], matches, mismatches


def methods(workload, name, many_threads, sweep):
    if workload != "rips":
        return [("cohomology", 1), ("cubical-union-find", 1),
                ("cripser", 1), ("cripser-locations", 1)]
    if name == "torus":
        return [("sparse", 1), ("pointwise-pairwise", 1), ("indexed", 1),
                ("giotto", many_threads)]
    arms = [("cohomology", 1), ("sparse", 1), ("collapse", 1), ("redzed", 1),
            ("parallel", many_threads), ("giotto", 1), ("giotto-collapse", many_threads)]
    if not sweep:
        arms += [("stages", 1), ("parallel-stages", many_threads), ("giotto-collapse", 1)]
    return arms


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", type=Path, help="directory for JSONL, shared fixtures and barcodes")
    parser.add_argument("--workload", choices=CASES, action="append")
    parser.add_argument("--sweep", action="store_true")
    parser.add_argument("--record-peer-mismatches", action="store_true",
                        help="retain peer timings with mismatches clearly marked")
    parser.add_argument("--julia", default="julia")
    parser.add_argument("--project", type=Path, default=UMBRELLA)
    parser.add_argument("--threads", type=int, default=8)
    parser.add_argument("--repeats", type=int, default=5)
    args = parser.parse_args()
    if min(args.threads, args.repeats) < 1:
        parser.error("threads and repeats must be positive")
    args.output.mkdir(parents=True, exist_ok=True)
    env = dict(os.environ, OPENBLAS_NUM_THREADS="1", OMP_NUM_THREADS="1")
    julia = [args.julia, "--startup-file=no", f"--project={args.project.resolve()}"]
    cpu_info = Path("/proc/cpuinfo").read_text()
    machine = {"platform": platform.platform(), "logical_cpus": os.cpu_count(),
               "cpu": next(line.split(":", 1)[1].strip() for line in cpu_info.splitlines()
                           if line.startswith("model name"))}
    source = {repo.name: git_source(repo) for repo in
              [UMBRELLA, WORKSPACE / "TDARipserer.jl", WORKSPACE / "TDAPersistenceDiagrams.jl"]}
    manifest = args.project / "Manifest.toml"
    if manifest.is_file():
        source["manifest_sha256"] = hashlib.sha256(manifest.read_bytes()).hexdigest()
    (args.output / "environment.json").write_text(json.dumps(
        {"machine": machine, "source": source, "python": platform.python_version()},
        indent=2) + "\n")
    rejected = []
    with (args.output / "results.jsonl").open("w") as log:
        for name in args.workload or CASES:
            workload, filename, size, dim, threshold = CASES[name]
            for n, radius in [(size, threshold), *(SWEEP[name] if args.sweep else [])]:
                destination = args.output / f"{name}-{n}-{radius:g}"
                destination.mkdir(exist_ok=True)
                input_file = DATA / filename
                shared = destination / "input.bin"
                subprocess.run([*julia, HERE / "bench.jl", "prepare", workload, input_file, shared,
                                str(n)], env=env, check=True)
                with shared.open("rb") as data:
                    input_hash = hashlib.file_digest(data, "sha256").hexdigest()
                reference = None
                for method, threads in methods(workload, name, args.threads, (n, radius) != (size, threshold)):
                    bars_file = destination / f"{method}-{threads}.tsv"
                    args_common = [str(n), str(dim), str(radius), str(args.repeats)]
                    peer = method.startswith(("giotto", "cripser"))
                    if peer:
                        command = [sys.executable, HERE / "peers.py", workload, method, shared,
                                   bars_file, *args_common[:3], str(threads), args_common[-1]]
                    else:
                        command = [*julia, "-t", str(threads), HERE / "bench.jl", workload, method,
                                   shared, input_file, bars_file, *args_common]
                    record = run_process(command, env, destination)
                    record.update(workload=name, size=n, threshold=None if np.isinf(radius) else radius,
                                  max_dimension=dim, method=method, field=2, input_sha256=input_hash,
                                  input_precision="Float32" if workload == "rips" and
                                  method not in ("indexed", "pointwise-pairwise") else "Float64",
                                  output_metadata="endpoints" if method.startswith("giotto") or
                                  method == "cripser" else "endpoints and locations",
                                  threads=threads, blas_threads=1)
                    if method in ("indexed", "pointwise-pairwise"):
                        record["point_source_sha256"] = hashlib.sha256(input_file.read_bytes()).hexdigest()
                    if not method.endswith("stages"):
                        files = ([bars_file.with_suffix(f".sample-{i}.tsv")
                                  for i in range(args.repeats + 1)] if peer else [bars_file])
                        precision = (np.float32 if name == "torus" and
                                     method in ("indexed", "pointwise-pairwise") else np.float64)
                        reference, bars, matches, differences = validate_barcodes(reference, files, precision)
                        record["barcode_matches_reference"] = all(matches)
                        record["barcode_checks"] = len(matches)
                        record["barcode_mismatches"] = differences
                        record["counts_by_dimension"] = [
                            sum(count for (dim_of_bar, _, _), count in bars.items() if dim_of_bar == d)
                            for d in range(dim + 1)
                        ]
                        if differences:
                            print(f"Barcode mismatch in {bars_file}: {len(differences)}/{len(matches)} samples",
                                  file=sys.stderr, flush=True)
                            if not peer or not args.record_peer_mismatches:
                                rejected.append(bars_file)
                    log.write(json.dumps(record, allow_nan=False) + "\n")
                    log.flush()
                    ms = record["stages"].get("end_to_end", {}).get("warm_median_seconds")
                    print(name, n, radius, method, threads, f"{ms * 1000:.2f} ms" if ms else "", flush=True)
    if rejected:
        raise SystemExit(f"Barcode parity failed in {len(rejected)} benchmark arms. See results.jsonl.")


if __name__ == "__main__":
    main()
