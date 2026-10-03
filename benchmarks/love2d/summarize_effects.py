"""Summarize raw native LÖVE effect benchmark measurements."""

from __future__ import annotations

import argparse
import csv
import statistics
from collections import defaultdict
from pathlib import Path


def median(rows: list[dict[str, str]], key: str) -> float:
    return statistics.median(float(row[key]) for row in rows)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--runtime", default="unavailable")
    parser.add_argument("--host-os", default="unavailable")
    parser.add_argument("--cpu", default="unavailable")
    args = parser.parse_args()

    with args.input.open(newline="", encoding="utf-8") as source:
        rows = list(csv.DictReader(source))
    groups: dict[tuple[str, str, str], list[dict[str, str]]] = defaultdict(list)
    for row in rows:
        groups[(row["quality"], row["effect"], row["scenario"])].append(row)
    if not rows:
        parser.error("input CSV contains no measurements")

    baseline = {
        quality: median(group, "mean_draw_ms")
        for (quality, effect, scenario), group in groups.items()
        if effect == "baseline" and scenario == "baseline"
    }
    lines = [
        "# LÖVE Effect Performance",
        "",
        f"- Runtime: LÖVE {args.runtime}",
        "- Resolution: 320×180; hidden window; VSync disabled",
        f"- Repetitions: {len({row['run'] for row in rows})} per row",
        "- Warm-up/sample frames: baseline and typical use 30 / 120; saturated cases use 30 / 600 (recorded per row in the raw CSV)",
        "- CPU metric: median per-frame Lua update/draw time; p95 is reported from frame samples",
        "- Memory metrics: Lua heap deltas in KB and LÖVE texture memory in KB; shader compilation is included in setup where supported",
        f"- Host OS: {args.host_os}",
        f"- CPU: {args.cpu}",
        "- Every measured draw includes the same 320×180 scene; screen effects draw it through the module's scene callback, and per-module baseline rows use an idle effect instance",
        "- Saturated workloads fill each configured helper/pool capacity; particles, flames, and electricity reach those counts through their documented per-update emission caps",
        "",
        "The table reports medians across repetition-level means and p95 values. Draw delta compares the effect row with the same profile's baseline draw time. `pixel_deform` and `palette_fx` report helper-call workload counts instead of object pools. This measures Lua submission time, not GPU completion. Texture memory includes runtime and canvas allocations, so use the before/after values to identify additional resources rather than treating the total as shader-only memory.",
        "",
        "| Profile | Effect | Workload | Active / limit | Update mean / p95 (ms) | Draw mean / p95 (ms) | Draw Δ vs baseline (ms) | Setup heap Δ (KB) | Sample heap Δ (KB) | Texture before / after (KB) | Mode 7 shader |",
        "| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |",
    ]
    for quality in ("low", "medium", "high"):
        for effect in ("baseline", "particles", "screen_fx", "pixel_deform", "palette_fx", "pseudo3d", "flames", "electricity"):
            for scenario in ("baseline", "typical", "saturated"):
                group = groups.get((quality, effect, scenario))
                if not group:
                    continue
                update_mean = median(group, "mean_update_ms")
                update_p95 = median(group, "p95_update_ms")
                draw_mean = median(group, "mean_draw_ms")
                draw_p95 = median(group, "p95_draw_ms")
                active = int(median(group, "active_items"))
                capacity = int(median(group, "capacity"))
                lines.append(
                    f"| {quality} | {effect} | {scenario} | {active} / {capacity} | "
                    f"{update_mean:.4f} / {update_p95:.4f} | {draw_mean:.4f} / {draw_p95:.4f} | "
                    f"{draw_mean - baseline.get(quality, 0):+.4f} | "
                    f"{median(group, 'setup_heap_kb'):+.2f} | {median(group, 'sample_heap_delta_kb'):+.2f} | "
                    f"{median(group, 'texture_memory_before_kb'):.2f} / {median(group, 'texture_memory_after_kb'):.2f} | "
                    f"{'yes' if median(group, 'mode7_shader') >= 1 else 'no'} |"
                )
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Wrote LÖVE effect summary to {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
