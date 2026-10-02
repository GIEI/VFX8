"""Summarize raw Picotron benchmark records by effect, profile, and workload."""

from __future__ import annotations

import argparse
import csv
import statistics
from collections import defaultdict
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--host-os", default="unavailable")
    parser.add_argument("--cpu", default="unavailable")
    args = parser.parse_args()

    with args.input.open(newline="", encoding="utf-8") as source:
        rows = list(csv.DictReader(source))
    if not rows or len(rows) % 45:
        parser.error(f"expected a multiple of 45 raw records, found {len(rows)}")
    repetitions = len(rows) // 45

    groups: dict[tuple[str, str, str], list[dict[str, str]]] = defaultdict(list)
    for row in rows:
        groups[(row["quality"], row["effect"], row["scenario"])].append(row)
    for key, records in groups.items():
        if len(records) != repetitions:
            parser.error(f"expected {repetitions} records for {key}, found {len(records)}")

    baseline = {
        quality: statistics.median(float(row["mean_cpu"]) for row in groups[(quality, "baseline", "baseline")])
        for quality in ("low", "medium", "high")
    }
    version = rows[0]["engine_version"]
    output = [
        "# Picotron Effect Performance",
        "",
        f"- Runtime: Picotron {version}",
        "- Run mode: isolated headless home; 240×136 logical display",
        f"- Repetitions: {repetitions} per row; {rows[0]['warmup_frames']} warm-up frames and {rows[0]['sample_frames']} sampled frames per repetition",
        "- CPU metric: `stat(1)` fraction of the runtime CPU budget; table values are percentages",
        "- FPS metric: minimum observed `stat(7)` operating mode (60/30/20/15), not a high-resolution frame-time measurement",
        "- Memory metric: Lua heap delta in KB from `collectgarbage(\"count\")`; setup delta includes allocations made by the effect constructor and initial trigger",
        f"- Host OS: {args.host_os}",
        f"- CPU: {args.cpu}",
        "- Baseline scene: fixed background field with no effect; every other row uses the same field before drawing the effect",
        "- Saturated: fills fixed pools where possible or reaches the profile's configured workload cap; `pixel_deform` and `palette_fx` use explicit high call counts because their APIs do not own pools",
        "- Source/runtime limits: CPU and frame-mode readings are headless runtime measurements on this host, not guarantees for a different display, cart, or machine",
        "",
        f"CPU values are medians across {repetitions} repetition-level means. `CPU Δ` subtracts the same profile's baseline. Heap values are medians. Sample heap delta includes garbage collection and allocator reuse during rendering; it is not a per-frame allocation counter, so negative values or small repeated plateaus are possible.",
        "",
        "| Profile | Effect | Workload | Active / limit | CPU mean | CPU p95 | CPU Δ vs baseline | Min FPS mode | Setup heap Δ | Sample heap Δ |",
        "| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |",
    ]
    for quality in ("low", "medium", "high"):
        ordered = [("baseline", "baseline")] + [
            (effect, workload)
            for effect in ("particles", "screen_fx", "pixel_deform", "palette_fx", "pseudo3d", "flames", "electricity")
            for workload in ("typical", "saturated")
        ]
        for effect, workload in ordered:
            records = groups[(quality, effect, workload)]
            cpu = statistics.median(float(row["mean_cpu"]) for row in records)
            p95 = statistics.median(float(row["p95_cpu"]) for row in records)
            delta = cpu - baseline[quality]
            active = max(int(row["active_items"]) for row in records)
            limit = max(int(row["capacity"]) for row in records)
            secondary = max(int(row["secondary_items"]) for row in records)
            active_text = f"{active} / {limit}" + (f" (+{secondary} stars)" if effect == "pseudo3d" else "")
            fps = min(int(float(row["min_fps"])) for row in records)
            setup_heap = statistics.median(float(row["setup_heap_kb"]) for row in records)
            sample_heap = statistics.median(float(row["sample_heap_delta_kb"]) for row in records)
            output.append(
                f"| {quality} | {effect} | {workload} | {active_text} | {cpu * 100:.2f}% | {p95 * 100:.2f}% | {delta * 100:+.2f} pp | {fps} | {setup_heap:.2f} KB | {sample_heap:+.2f} KB |"
            )
    output.extend(
        [
            "",
            "`active / limit` reports active pool items and capacity. For coordinate deformation and palette mapping it reports helper calls used as a fixed synthetic workload, not internal allocations. Pseudo-3D also reports its star count. Screen effects use an eight-wave capacity on all quality profiles because that module has no profile-specific capacity.",
            "",
            f"Raw measurements: [`{args.input.name}`]({args.input.name}). Reproduce them with [`benchmarks/picotron/run.ps1`](../picotron/run.ps1).",
            "",
        ]
    )
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text("\n".join(output), encoding="utf-8")
    print(f"Wrote Picotron performance summary to {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
