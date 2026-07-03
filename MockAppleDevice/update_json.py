#!/usr/bin/env python3
"""Add cornerRadius field to every variant config in device_models.json."""

import json
from pathlib import Path

CORNER_RADIUS_MAP = {
    "iphone": 0.115,
    "ipad": 0.045,
    "macbook": 0.02,
    "appleWatch": 0.22,
}

def main():
    path = Path(__file__).parent / "device_models.json"
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)

    total = 0
    summary = {}

    for category, models in data.items():
        radius = CORNER_RADIUS_MAP.get(category)
        if radius is None:
            print(f"⚠️  Unknown category '{category}', skipping.")
            continue
        count = 0
        for model_name, colors in models.items():
            for color_name, orientations in colors.items():
                for orientation, config in orientations.items():
                    if isinstance(config, dict) and "screenRect" in config:
                        config["cornerRadius"] = radius
                        count += 1
        summary[category] = count
        total += count

    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write("\n")

    print("✅ cornerRadius 已添加完成")
    print(f"   总计修改: {total} 个 variant config")
    for cat, cnt in summary.items():
        print(f"   - {cat}: {cnt} (cornerRadius={CORNER_RADIUS_MAP[cat]})")

if __name__ == "__main__":
    main()
