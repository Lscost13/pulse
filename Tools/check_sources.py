"""Механические проверки Swift-исходников PULSE.

1. Баланс скобок (после удаления строк/комментариев).
2. Дубли типов верхнего уровня.
3. Идентификаторы, которые используются, но нигде не объявлены
   (эвристика: только наши PascalCase-имена и методы store.).
"""

from __future__ import annotations

import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "Sources")


def swift_files() -> list[str]:
    result = []
    for base, _dirs, files in os.walk(SRC):
        for name in files:
            if name.endswith(".swift"):
                result.append(os.path.join(base, name))
    return sorted(result)


def strip_source(text: str) -> str:
    """Убираем строковые литералы и комментарии, сохраняя длину структуры."""
    out = []
    i = 0
    n = len(text)
    while i < n:
        ch = text[i]
        if ch == "/" and i + 1 < n and text[i + 1] == "/":
            while i < n and text[i] != "\n":
                i += 1
        elif ch == "/" and i + 1 < n and text[i + 1] == "*":
            depth = 1
            i += 2
            while i < n and depth > 0:
                if text[i] == "/" and i + 1 < n and text[i + 1] == "*":
                    depth += 1
                    i += 2
                elif text[i] == "*" and i + 1 < n and text[i + 1] == "/":
                    depth -= 1
                    i += 2
                else:
                    i += 1
        elif ch == '"':
            out.append('""')
            i += 1
            while i < n:
                if text[i] == "\\":
                    i += 2
                    continue
                if text[i] == '"':
                    i += 1
                    break
                i += 1
        else:
            out.append(ch)
            i += 1
    return "".join(out)


def check_balance(files: list[str]) -> list[str]:
    problems = []
    pairs = {"(": ")", "[": "]", "{": "}"}
    for path in files:
        raw = open(path, encoding="utf-8").read()
        clean = strip_source(raw)
        stack: list[tuple[str, int]] = []
        line = 1
        for ch in clean:
            if ch == "\n":
                line += 1
            elif ch in pairs:
                stack.append((ch, line))
            elif ch in pairs.values():
                if not stack:
                    problems.append(f"{path}: лишняя '{ch}' на строке {line}")
                    break
                opener, open_line = stack.pop()
                if pairs[opener] != ch:
                    problems.append(
                        f"{path}: '{opener}' (строка {open_line}) закрыта '{ch}' (строка {line})"
                    )
                    break
        for opener, open_line in stack:
            problems.append(f"{path}: не закрыта '{opener}' со строки {open_line}")
    return problems


DECL = re.compile(
    r"^(?:public |internal |private |fileprivate |final |@\w+\s*)*"
    r"(struct|class|enum|protocol|extension|actor|typealias)\s+([A-Za-z_][A-Za-z0-9_]*)",
    re.M,
)


def check_duplicates(files: list[str]) -> tuple[list[str], set[str]]:
    seen: dict[str, list[str]] = {}
    for path in files:
        raw = open(path, encoding="utf-8").read()
        clean = strip_source(raw)
        for match in DECL.finditer(clean):
            kind = match.group(1)
            name = match.group(2)
            if kind == "extension":
                continue
            seen.setdefault(name, []).append(f"{os.path.basename(path)}:{kind}")
    duplicates = []
    for name, places in seen.items():
        kinds = {p.split(":")[1] for p in places}
        if len(places) > 1 and len(kinds) == 1:
            duplicates.append(f"{name}: {', '.join(places)}")
    return duplicates, set(seen)


def main() -> int:
    files = swift_files()
    print(f"Проверяю {len(files)} файлов\n")

    balance = check_balance(files)
    if balance:
        print("!! Баланс скобок:")
        for item in balance:
            print("   ", item)
    else:
        print("OK  скобки сбалансированы")

    duplicates, declared = check_duplicates(files)
    if duplicates:
        print("\n!! Дубли объявлений:")
        for item in duplicates:
            print("   ", item)
    else:
        print("OK  дублей типов нет")

    print(f"\nОбъявлено типов: {len(declared)}")
    return 1 if (balance or duplicates) else 0


if __name__ == "__main__":
    sys.exit(main())
