#!/usr/bin/env python3
#
# Usage: ./addAvailability.py "iOS 15.0, macOS 12.0, *" Sources/StreamChatAI/StreamMarkdownUI
#
# Adds an @available attribute to every top-level declaration in the Swift files of the given directories, unless the
# declaration already has one that is at least as recent. Swift has no module-wide availability, and SwiftPM has no
# per-target platforms, so this is how a target requires a newer OS than the package's minimum.

import re
import sys
from pathlib import Path

MODIFIERS = {
    "distributed", "fileprivate", "final", "indirect", "infix", "internal", "nonisolated", "open", "package",
    "postfix", "prefix", "private", "public",
}
DECLARATIONS = {"actor", "class", "enum", "extension", "func", "let", "protocol", "struct", "typealias", "var"}


def parse_versions(arguments):
    return {
        platform: tuple(int(part) for part in version.split("."))
        for platform, version in re.findall(r"\b(\w+)\s+(\d+(?:\.\d+)*)", arguments)
    }


def top_level_lines(text):
    """For each line, whether it starts outside any braces, parentheses, comments and strings."""
    result = []
    depth = 0
    contexts = []
    i = 0
    length = len(text)
    line_start = True
    while i < length:
        if line_start:
            result.append(depth == 0 and not contexts)
            line_start = False
        character = text[i]
        context = contexts[-1] if contexts else None
        if character == "\n":
            line_start = True
            if context and context[0] == "line comment":
                contexts.pop()
            i += 1
            continue
        if context and context[0] == "line comment":
            i += 1
        elif context and context[0] == "block comment":
            if text.startswith("*/", i):
                contexts.pop()
                i += 2
            elif text.startswith("/*", i):
                contexts.append(("block comment",))
                i += 2
            else:
                i += 1
        elif context and context[0] == "string":
            _, hashes, multiline = context
            delimiter = ('"""' if multiline else '"') + "#" * hashes
            escape = "\\" + "#" * hashes
            if text.startswith(escape, i):
                i += len(escape)
                if text.startswith("(", i):
                    contexts.append(("interpolation", 0))
                if not text.startswith("\n", i):
                    i += 1
            elif text.startswith(delimiter, i):
                contexts.pop()
                i += len(delimiter)
            else:
                i += 1
        else:
            string = re.match(r'(#*)("""|")', text[i:i + 64])
            if text.startswith("//", i):
                contexts.append(("line comment",))
                i += 2
            elif text.startswith("/*", i):
                contexts.append(("block comment",))
                i += 2
            elif string:
                contexts.append(("string", len(string.group(1)), string.group(2) == '"""'))
                i += len(string.group(0))
            elif context and context[0] == "interpolation":
                if character == "(":
                    contexts[-1] = ("interpolation", context[1] + 1)
                elif character == ")":
                    if context[1] == 0:
                        contexts.pop()
                    else:
                        contexts[-1] = ("interpolation", context[1] - 1)
                i += 1
            else:
                if character in "{(":
                    depth += 1
                elif character in "})":
                    depth -= 1
                i += 1
    return result


def skip_balanced(text, position):
    depth = 0
    while position < len(text):
        if text[position] == "(":
            depth += 1
        elif text[position] == ")":
            depth -= 1
            if depth == 0:
                return position + 1
        position += 1
    return position


def declaration_head(text):
    """The keyword of the declaration starting the text, its attributes, and where the keyword is."""
    attributes = []
    position = 0
    while True:
        while position < len(text) and text[position].isspace():
            position += 1
        if text.startswith("@", position):
            name = re.match(r"@[\w.]+", text[position:])
            if not name:
                return None, attributes, position
            end = position + len(name.group(0))
            if text.startswith("(", end):
                end = skip_balanced(text, end)
            attributes.append(text[position:end])
            position = end
            continue
        word = re.match(r"\w+", text[position:])
        if not word:
            return None, attributes, position
        if word.group(0) in MODIFIERS:
            position += len(word.group(0))
            if text.startswith("(", position):
                position = skip_balanced(text, position)
            continue
        return word.group(0), attributes, position


def is_covered(attributes, required):
    existing = {}
    for attribute in attributes:
        if attribute.startswith("@available("):
            for platform, version in parse_versions(attribute).items():
                existing[platform] = max(existing.get(platform, ()), version)
    return all(existing.get(platform, ()) >= version for platform, version in required.items())


def annotate(text, attribute, required):
    lines = text.split("\n")
    top_level = top_level_lines(text)
    output = []
    index = 0
    while index < len(lines):
        line = lines[index]
        stripped = line.strip()
        if index < len(top_level) and top_level[index] and re.match(r"[@\w]", stripped):
            rest = "\n".join(lines[index:index + 20])
            keyword, attributes, position = declaration_head(rest)
            keyword_line = index + rest.count("\n", 0, position)
            if keyword in DECLARATIONS and not is_covered(attributes, required):
                indentation = line[:len(line) - len(line.lstrip())]
                output.append(indentation + attribute)
            output.extend(lines[index:keyword_line + 1])
            index = keyword_line + 1
            continue
        output.append(line)
        index += 1
    return "\n".join(output)


def main():
    if len(sys.argv) < 3:
        sys.exit(f"Usage: {sys.argv[0]} \"iOS 15.0, macOS 12.0, *\" <directory>...")
    arguments = sys.argv[1]
    attribute = f"@available({arguments})"
    required = parse_versions(arguments)
    for directory in sys.argv[2:]:
        for file in sorted(Path(directory).rglob("*.swift")):
            text = file.read_text()
            annotated = annotate(text, attribute, required)
            if annotated != text:
                file.write_text(annotated)


if __name__ == "__main__":
    main()
