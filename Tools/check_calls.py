"""Проверка вызовов наших view-структур: метки аргументов и порядок.

Для каждого типа (struct …: View) собираем memberwise-параметры
(хранимые свойства без property wrapper, var — даже с дефолтом, let — без дефолта)
и проверяем каждый вызов TypeName(...) в остальных файлах:
  - метка должна существовать,
  - порядок меток должен совпадать с порядком объявления.
"""

from __future__ import annotations

import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "Sources")

WRAPPERS = ("@State", "@Binding", "@Environment", "@EnvironmentObject", "@ObservedObject",
            "@Namespace", "@FocusState", "@GestureState", "@AppStorage", "@SceneStorage")


def swift_files() -> list[str]:
    paths = []
    for base, _d, files in os.walk(SRC):
        for name in files:
            if name.endswith(".swift"):
                paths.append(os.path.join(base, name))
    return sorted(paths)


def body_of(text: str, start: int) -> tuple[str, int]:
    """Открывающая скобка уже найдена; вернуть тело и позицию после '}'."""
    depth = 1
    i = start
    while i < len(text) and depth > 0:
        if text[i] == "{":
            depth += 1
        elif text[i] == "}":
            depth -= 1
        i += 1
    return text[start:i - 1], i


PROP = re.compile(
    r"^(?P<indent>[ \t]*)"
    r"(?P<attrs>(?:@[A-Za-z_][A-Za-z0-9_]*(?:\([^)]*\))?\s+)*)"
    r"(?P<mods>(?:(?:private|public|internal|fileprivate|final|lazy|weak)\s+)*)"
    r"(?P<kind>var|let)\s+(?P<name>[A-Za-z_][A-Za-z0-9_]*)\s*(?::[^=\n]*)?(?P<default>=)?",
    re.M,
)


def stored_params(type_name: str, body: str) -> tuple[list[str], set[str], set[str]]:
    """Возвращает (memberwise-параметры по порядку, параметры явного init, все имена)."""
    params: list[str] = []
    all_names: set[str] = set()

    depth = 0
    current: list[str] = []
    for ch in body:
        if ch == "{":
            depth += 1
            if depth == 1:
                current = []
            continue
        if ch == "}":
            depth -= 1
            if depth == 0:
                # закончилась строка с открывающей скобкой — сбрасываем
                current = []
            continue
        if depth == 0:
            if ch == "\n":
                line = "".join(current).strip()
                current = []
                if not line:
                    continue
                all_names |= set(re.findall(r"[A-Za-z_][A-Za-z0-9_]*", line.split("(")[0]))
                match = re.match(
                    r"^(?P<attrs>(?:@[A-Za-z_][A-Za-z0-9_]*(?:\([^)]*\))?\s+)*)"
                    r"(?P<mods>(?:(?:private|public|internal|fileprivate|final|lazy|weak|static)\s+)*)"
                    r"(?P<kind>var|let)\s+(?P<name>[A-Za-z_][A-Za-z0-9_]*)",
                    line,
                )
                if not match:
                    continue
                attrs = match.group("attrs") or ""
                kind = match.group("kind")
                has_default = _has_default(line)
                wrapped_state = any(w in attrs for w in WRAPPERS)
                if wrapped_state:
                    all_names.add(match.group("name"))
                    if "@Binding" in attrs:
                        params.append(match.group("name"))
                    continue
                if kind == "let" and has_default:
                    continue
                if kind == "var" and "{" in line:
                    continue
                params.append(match.group("name"))
            else:
                current.append(ch)
        # внутри скобок содержимое не нужно
    if current:
        line = "".join(current).strip()
        if line:
            all_names |= set(re.findall(r"[A-Za-z_][A-Za-z0-9_]*", line.split("(")[0]))

    init_params: set[str] = set()
    init_match = re.search(r"\binit\s*\(", body)
    if init_match:
        depth_p = 1
        i = init_match.end()
        buf: list[str] = []
        while i < len(body) and depth_p > 0:
            ch = body[i]
            if ch == "(":
                depth_p += 1
            elif ch == ")":
                depth_p -= 1
                if depth_p == 0:
                    break
            buf.append(ch)
            i += 1
        args = "".join(buf)
        depth_p = 0
        segments: list[str] = []
        current_seg: list[str] = []
        for ch in args:
            if ch in "([":
                depth_p += 1
            elif ch in ")]":
                depth_p -= 1
            if ch == "," and depth_p == 0:
                segments.append("".join(current_seg))
                current_seg = []
            else:
                current_seg.append(ch)
        segments.append("".join(current_seg))
        for segment in segments:
            stripped = segment.strip()
            if not stripped:
                continue
            head = stripped.split(":")[0].strip()
            if head:
                init_params.add(head.split()[-1])
    return params, init_params, all_names


def _has_default(line: str) -> bool:
    # `= ` вне скобок
    depth = 0
    for ch in line:
        if ch in "([{":
            depth += 1
        elif ch in ")]}":
            depth -= 1
        elif ch == "=" and depth == 0:
            return True
    return False


CALL = re.compile(r"(?<![\w.])([A-Z][A-Za-z0-9_]*)\s*\(")


def call_labels(text: str, open_index: int) -> list[str] | None:
    """Метки аргументов на верхнем уровне вызова (после '(')."""
    depth = 1
    i = open_index
    segments = []
    current = []
    while i < len(text) and depth > 0:
        ch = text[i]
        if ch in "([{":
            depth += 1
        elif ch in ")]}":
            depth -= 1
            if depth == 0:
                break
        if ch == "," and depth == 1:
            segments.append("".join(current))
            current = []
        elif depth >= 1:
            current.append(ch)
        i += 1
    segments.append("".join(current))

    labels = []
    for segment in segments:
        stripped = segment.strip()
        if not stripped:
            continue
        match = re.match(r"([A-Za-z_][A-Za-z0-9_]*)\s*:(?!:)", stripped)
        if match:
            labels.append(match.group(1))
        else:
            labels.append("")
    return labels


def main() -> int:
    files = swift_files()
    texts = {path: open(path, encoding="utf-8").read() for path in files}

    decls: dict[str, tuple[list[str], set[str]]] = {}
    known_all: dict[str, set[str]] = {}
    for path, text in texts.items():
        for match in re.finditer(r"\bstruct\s+([A-Z][A-Za-z0-9_]*)\s*(?:<[^>]*>)?\s*:", text):
            name = match.group(1)
            if name in decls:
                continue
            brace = text.find("{", match.end())
            if brace == -1:
                continue
            body, _end = body_of(text, brace + 1)
            params, init_params, all_names = stored_params(name, body)
            decls[name] = (params, init_params)
            known_all[name] = all_names | set(params) | init_params

    problems = 0
    checked = 0
    for path, text in texts.items():
        for match in CALL.finditer(text):
            name = match.group(1)
            if name not in decls:
                continue
            params, init_params = decls[name]
            labels = call_labels(text, match.end())
            if labels is None:
                continue
            known = known_all[name]
            if not known:
                continue
            checked += 1
            line = text[: match.start()].count("\n") + 1
            for label in labels:
                if label and label not in known:
                    problems += 1
                    print(f"!! {os.path.relpath(path, ROOT)}:{line} — {name}({label}: …) — такого параметра нет.\n"
                          f"   параметры: {', '.join(params) or '—'}")
            if params:
                indexes = []
                for label in labels:
                    if label in params:
                        indexes.append(params.index(label))
                if indexes != sorted(indexes):
                    problems += 1
                    print(f"!! {os.path.relpath(path, ROOT)}:{line} — {name}: нарушен порядок аргументов "
                          f"{labels} при объявлении {params}")

    print(f"\nПроверено вызовов: {checked}; типов: {len(decls)}; проблем: {problems}")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
