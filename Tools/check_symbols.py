"""Сверка использованных членов наших собственных API с их объявлениями.

Ловит опечатки вида `store.freeMinutesToday` -> `store.freeMinuteToday`,
`PulsePalette.inkTeritary`, `PulseFont.titel` и т.п.
"""

from __future__ import annotations

import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "Sources")


def all_files() -> dict[str, str]:
    result = {}
    for base, _dirs, files in os.walk(SRC):
        for name in files:
            if name.endswith(".swift"):
                path = os.path.join(base, name)
                result[path] = open(path, encoding="utf-8").read()
    return result


def members_of(path: str, pattern: str) -> set[str]:
    text = open(path, encoding="utf-8").read()
    return set(re.findall(pattern, text))


def main() -> int:
    files = all_files()
    core = os.path.join(SRC, "Core")
    store_path = os.path.join(core, "AppStore.swift")

    # Члены AppStore: свойства и методы.
    store_text = open(store_path, encoding="utf-8").read()
    store_members = set(re.findall(r"\b(?:var|let)\s+([a-zA-Z_][A-Za-z0-9_]*)\s*[:=]", store_text))
    store_members |= set(re.findall(r"\bfunc\s+([a-zA-Z_][A-Za-z0-9_]*)", store_text))
    store_members |= {"settings", "tasks", "events", "habits", "sessions", "categories", "achievements"}

    # Члены enum'ов/структур дизайна.
    theme_text = open(os.path.join(SRC, "Design", "PulseTheme.swift"), encoding="utf-8").read()
    date_text = open(os.path.join(core, "DateUtils.swift"), encoding="utf-8").read()

    def enum_members(name: str, text: str) -> set[str]:
        # Берём тело enum/структуры по имени и вытаскиваем static/обычные члены.
        match = re.search(rf"\b(?:enum|struct)\s+{name}\b[^{{]*{{", text)
        if not match:
            return set()
        start = match.end()
        depth = 1
        i = start
        while i < len(text) and depth > 0:
            if text[i] == "{":
                depth += 1
            elif text[i] == "}":
                depth -= 1
            i += 1
        body = text[start:i]
        members = set(re.findall(r"\b(?:static\s+)?(?:var|let|func)\s+([a-zA-Z_][A-Za-z0-9_]*)", body))
        members |= set(re.findall(r"\bcase\s+([a-zA-Z_][A-Za-z0-9_]*)", body))
        return members

    palette = enum_members("PulsePalette", theme_text)
    font = enum_members("PulseFont", theme_text)
    motion = enum_members("PulseMotion", theme_text)
    metrics = enum_members("PulseMetrics", theme_text)
    gradient = enum_members("PulseGradient", theme_text)
    pulse_date = enum_members("PulseDate", date_text)
    ru_cal = enum_members("RuCal", date_text)

    # Члены Router.
    router_path = os.path.join(SRC, "App", "Router.swift")
    router_text = open(router_path, encoding="utf-8").read()
    router_members = set(re.findall(r"\b(?:var|let)\s+([a-zA-Z_][A-Za-z0-9_]*)\s*[:=]", router_text))
    router_members |= set(re.findall(r"\bfunc\s+([a-zA-Z_][A-Za-z0-9_]*)", router_text))

    checks = {
        "store": (store_members, re.compile(r"(?<![\w.])store\.([a-zA-Z_][A-Za-z0-9_]*)")),
        "router": (router_members, re.compile(r"(?<![\w.])router\.([a-zA-Z_][A-Za-z0-9_]*)")),
        "PulsePalette": (palette, re.compile(r"\bPulsePalette\.([a-zA-Z_][A-Za-z0-9_]*)")),
        "PulseFont": (font, re.compile(r"\bPulseFont\.([a-zA-Z_][A-Za-z0-9_]*)")),
        "PulseMotion": (motion, re.compile(r"\bPulseMotion\.([a-zA-Z_][A-Za-z0-9_]*)")),
        "PulseMetrics": (metrics, re.compile(r"\bPulseMetrics\.([a-zA-Z_][A-Za-z0-9_]*)")),
        "PulseGradient": (gradient, re.compile(r"\bPulseGradient\.([a-zA-Z_][A-Za-z0-9_]*)")),
        "PulseDate": (pulse_date, re.compile(r"\bPulseDate\.([a-zA-Z_][A-Za-z0-9_]*)")),
        "RuCal": (ru_cal, re.compile(r"\bRuCal\.([a-zA-Z_][A-Za-z0-9_]*)")),
    }

    problems = 0
    for key, (declared, pattern) in checks.items():
        used: dict[str, list[str]] = {}
        for path, text in files.items():
            for match in pattern.finditer(text):
                name = match.group(1)
                used.setdefault(name, []).append(os.path.basename(path))
        missing = {name: places for name, places in used.items() if name not in declared}
        if missing:
            print(f"\n!! {key}: используются, но не объявлены")
            for name, places in sorted(missing.items()):
                problems += 1
                print(f"    {key}.{name}  <-  {', '.join(sorted(set(places)))}")
        else:
            print(f"OK  {key}: {len(used)} использованных имён найдены в объявлениях")

    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
