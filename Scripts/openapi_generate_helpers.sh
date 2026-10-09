# shellcheck shell=bash

pruned_endpoints=()

# Keep only the coding direction each internal model needs.
# Required because OpenAPI generator emits all models with Codable conformance
# even when it is used for decoding or encoding only. This helps to save
# SDK size when Codable is reduced to Encodable or Decodable.
# Requires bigger change in the generator for applying it there.
apply_directional_coding_conformances() {
  local encodable_csv decodable_csv codable_csv
  encodable_csv="$(IFS=,; echo "${encodable_only_models[*]}")"
  decodable_csv="$(IFS=,; echo "${decodable_only_models[*]},${allowed_events[*]/%/DTO}")"
  codable_csv="$(IFS=,; echo "${codable_models[*]}")"

  python3 - \
    "$OUTPUT_DIR_CHAT/models" \
    "$encodable_csv" \
    "$decodable_csv" \
    "$codable_csv" <<'PY'
import pathlib
import re
import sys

models_dir = pathlib.Path(sys.argv[1])
groups = {
    "Encodable": set(filter(None, sys.argv[2].split(","))),
    "Decodable": set(filter(None, sys.argv[3].split(","))),
    "Codable": set(filter(None, sys.argv[4].split(","))),
}

all_classified = set()
for direction, names in groups.items():
    overlap = all_classified.intersection(names)
    if overlap:
        raise SystemExit(f"Models classified more than once: {sorted(overlap)}")
    all_classified.update(names)

generated = {path.stem for path in models_dir.glob("*.swift")}
unclassified = generated - all_classified
missing = all_classified - generated
if unclassified:
    raise SystemExit(f"Unclassified generated models: {sorted(unclassified)}")
if missing:
    raise SystemExit(f"Classified models missing from generated output: {sorted(missing)}")

# Every model gets an explicit init(from:) and encode(to:) from the generator; the one
# for the dropped coding direction no longer compiles. The other one must stay: without
# CodingKeys, synthesis would take the wire keys from the camelCase property names.
# Keyed by the direction that doesn't need the coder.
unused_coder = {
    "Decodable": r"func encode\(to encoder: Encoder\) throws",
    "Encodable": r"init\(from decoder: Decoder\) throws",
}

declaration = re.compile(
    r"^(\s*(?:public )?(?:final )?(?:class|struct|enum)\s+([A-Za-z0-9_]+)[^:\n]*:\s*)(.*)$"
)

for direction, names in groups.items():
    for name in sorted(names):
        path = models_dir / f"{name}.swift"
        lines = path.read_text().splitlines(keepends=True)
        output = []
        top_level_conformances = None

        for line in lines:
            ending = "\n" if line.endswith("\n") else ""
            content = line[:-1] if ending else line
            match = declaration.match(content)
            if match:
                prefix, declared_name, conformances = match.groups()
                if declared_name == name:
                    if direction != "Codable":
                        conformances = re.sub(r"\bCodable\b", direction, conformances)
                        if direction == "Decodable":
                            conformances = re.sub(r",\s*JSONEncodable\b", "", conformances)
                    content = f"{prefix}{conformances}"
                    top_level_conformances = conformances
            output.append(content + ending)

        if top_level_conformances is None:
            raise SystemExit(f"Could not find the top-level declaration for {name}")
        if not re.search(rf"\b{direction}\b", top_level_conformances):
            raise SystemExit(f"{name} does not conform to {direction}")
        if direction == "Decodable" and re.search(
            r"\bEncodable\b|\bJSONEncodable\b", top_level_conformances
        ):
            raise SystemExit(f"{name} retains an encoding conformance")

        text = "".join(output)
        if direction in unused_coder:
            text = re.sub(
                rf"\n?^    (?:public )?{unused_coder[direction]} \{{\n.*?^    \}}\n",
                "",
                text,
                count=1,
                flags=re.M | re.S,
            )
        path.write_text(text)
PY
}

# Exact membership test (macOS bash 3.2 — no associative arrays).
contains() {
  local needle="$1"; shift
  printf '%s\n' "$@" | grep -qxF "$needle"
}

# Relax selected generated stored properties back to optional. Some models are
#     exposed as public API where a property was historically optional (e.g.
#     Device.createdAt was Date? before the OpenAPI migration). The memberwise init
#     parameter and the init(from:)/encode(to:) lines are relaxed too.
optionalize_property() {
  local file="$OUTPUT_DIR_CHAT/models/$1.swift"
  P="$2" perl -0777 -pi -e '
    my $p = $ENV{P};
    s/^(    let \Q$p\E: [^?\n]+)$/$1?/m;
    s/([(,]\s*)\Q$p\E: ([^,)\n]+)(?=[,)])/${1}$p: $2? = nil/;
    s/^(        self\.\Q$p\E = try container\.)decode\(/${1}decodeIfPresent(/m;
    s/^(        self\.\Q$p\E = try container\.)decodeArrayIgnoringFailures\(/${1}decodeArrayIfPresentIgnoringFailures(/m;
    s/^(        try container\.)encode\(\Q$p\E, /${1}encodeIfPresent($p, /m;
  ' "$file"
}

# Decode a required generated property with a fallback when its key is missing or null.
#     The property stays non-optional; only its init(from:) line changes. Fails when the
#     line isn't a required decode, so a spec change can't silently drop a default.
property_fallback_value() {
  local file="$OUTPUT_DIR_CHAT/models/$1.swift"
  M="$1" P="$2" D="$3" perl -0777 -pi -e '
    my ($m, $p, $d) = ($ENV{M}, $ENV{P}, $ENV{D});
    s/^(        self\.\Q$p\E = try container\.)decode\((.*)\)$/${1}decodeIfPresent($2) ?? $d/m
      or s/^(        self\.\Q$p\E = try container\.)decodeArrayIgnoringFailures\((.*)\)$/${1}decodeArrayIfPresentIgnoringFailures($2) ?? $d/m
      or die "property_fallback_value: $m.$p has no required decode line\n";
  ' "$file"
}

# Keep only allowed_endpoints, delete the rest.
prune_endpoint_factories() {
  local file="$OUTPUT_DIR_CHAT/APIs/DefaultEndpoints.swift"
  local name
  while IFS= read -r name; do
    contains "$name" "${allowed_endpoints[@]}" && continue
    pruned_endpoints+=("$name")
    sed -i '' -E "/^[[:space:]]+static func ${name}\(/,/^[[:space:]]+\}[[:space:]]*$/d" "$file"
  done < <(sed -nE 's/^[[:space:]]+static func ([A-Za-z0-9_]+)\(.*/\1/p' "$file")
}

# Keep generated v2 EndpointPath cases aligned with allowed_endpoints.
prune_generated_endpoint_paths() {
  local file="$OUTPUT_DIR_CHAT/APIs/DefaultEndpoints.swift"
  local allowed_endpoints_csv
  allowed_endpoints_csv="$(IFS=,; echo "${allowed_endpoints[*]}")"

  python3 - "$file" "$allowed_endpoints_csv" <<'PY'
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
allowed = set(filter(None, sys.argv[2].split(",")))

def case_name(line):
    stripped = line.strip()
    if not stripped.startswith("case "):
        return None
    pattern = stripped[len("case "):]
    if pattern.startswith("let "):
        pattern = pattern[len("let "):]
    if pattern.startswith("."):
        pattern = pattern[1:]
    return pattern.split("(", 1)[0].split(" ", 1)[0].split(":", 1)[0]

# Within the EndpointPath enum, drop every `case` line and its (possibly multi-line)
# switch arm whose name isn't allowed; keep every structural line. swiftformat tidies
# the leftover blank lines afterwards.
out, in_enum, keep = [], False, True
for line in path.read_text().splitlines(keepends=True):
    if line.startswith("enum EndpointPath"):
        in_enum = True
    elif line.startswith("final class Endpoint"):
        in_enum = False
    if in_enum:
        name = case_name(line)
        if name is not None:                                     # `case …`: opens a block
            keep = name in allowed
        elif not line.lstrip().startswith(("return ", "let ")):  # structural line
            keep = True                                          # (arm bodies inherit keep)
        if not keep:
            continue
    out.append(line)

path.write_text("".join(out))
PY
}

# Keep only allowed_models, delete the rest.
prune_models() {
  local f base
  for f in "$OUTPUT_DIR_CHAT"/models/*.swift; do
    [ -e "$f" ] || continue
    base="$(basename "$f" .swift)"
    contains "$base" "${allowed_models[@]}" "${allowed_events[@]}" && continue
    rm -f "$f"
  done
}

# Drop the StringCodingKey lets nothing references: the generator emits one per wire key
# of every model in the spec, most of which prune_models removes. A key counts as used
# when a generated file names it as `forKey: .key` or any SDK or test source names it as
# `StringCodingKey.key`. Hand-written `forKey: .key` lines belong to other types'
# CodingKeys enums, so they don't count.
prune_string_coding_keys() {
  python3 - "$OUTPUT_DIR_CHAT/StringCodingKey.swift" "$OUTPUT_DIR_CHAT" \
    "$REPO_ROOT/Sources" "$REPO_ROOT/Tests" "$REPO_ROOT/TestTools" <<'PY'
import pathlib
import re
import sys

keys_file, generated_dir = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
generated_reference = re.compile(r"(?:forKey: \.|StringCodingKey\.)`?(\w+)`?")
reference = re.compile(r"StringCodingKey\.`?(\w+)`?")
used = set()
for root in sys.argv[3:]:
    for path in pathlib.Path(root).rglob("*.swift"):
        if path == keys_file:
            continue
        pattern = generated_reference if path.is_relative_to(generated_dir) else reference
        used.update(pattern.findall(path.read_text()))

declaration = re.compile(r"^    static let `?(\w+)`?: StringCodingKey = ")
kept = [
    line
    for line in keys_file.read_text().splitlines(keepends=True)
    if not (match := declaration.match(line)) or match.group(1) in used
]
keys_file.write_text("".join(kept))
PY
}

prune_wsevent_cases() {
  local file="$OUTPUT_DIR_CHAT/models/WSEvent.swift"
  local allowed_events_csv
  allowed_events_csv="$(IFS=,; echo "${allowed_events[*]}")"

  python3 - "$file" "$allowed_events_csv" <<'PY'
import pathlib
import re
import sys

path = pathlib.Path(sys.argv[1])
allowed = set(filter(None, sys.argv[2].split(",")))
text = path.read_text()

cases = dict(re.findall(r"^    case (\w+)\((\w+)\)$", text, flags=re.M))
missing = allowed - set(cases.values())
if missing:
    raise SystemExit(f"Allowed events missing from WSEvent: {sorted(missing)}")

for name, model in cases.items():
    if model in allowed:
        continue
    text = re.sub(rf"^    case {name}\({model}\)\n", "", text, flags=re.M)
    text = re.sub(rf"^        case \.{name}\(let value\):\n.*\n", "", text, flags=re.M)
    text = re.sub(
        rf"^        (\}} else )?if dto\.type == \"[^\"]*\" \{{\n"
        rf"            let value = try container\.decode\({model}\.self\)\n"
        rf"            self = \.{name}\(value\)\n",
        "",
        text,
        flags=re.M,
    )
text = re.sub(r"(WSEventMapping\.self\)\n        )\} else if", r"\1if", text)

path.write_text(text)
PY
}

# Expose a generated model as public API. The type and its stored properties become
# public, along with the generated Hashable conformance (== and hash(into:)) and the
# init(from:)/encode(to:) that witness the public Decodable/Encodable conformances; the
# memberwise init stays internal.
publicize_model() {
  local file="$OUTPUT_DIR_CHAT/models/$1.swift"
  sed -i '' -E \
    -e 's/^final class /public final class /' \
    -e 's/^    let /    public let /' \
    -e 's/^    var /    public var /' \
    -e 's/^    static func == /    public static func == /' \
    -e 's/^    func hash\(into /    public func hash(into /' \
    -e 's/^    init\(from decoder: /    public init(from decoder: /' \
    -e 's/^    func encode\(to encoder: /    public func encode(to encoder: /' \
    "$file"
}

# Expose a generated RawRepresentable class as public API. Unlike publicize_model, the
#     init must be public too — it is the RawRepresentable requirement — along with every
#     static let holding a known value. The class is looked up by name, since the file
#     named after a model also holds the classes generated for its string properties.
publicize_raw_representable() {
  local file="$OUTPUT_DIR_CHAT/models/$1.swift"
  awk -v n="${2:-$1}" '
    $0 ~ "^final class " n ":" { sub(/^final class /, "public final class "); inside = 1; print; next }
    inside && /^}$/       { inside = 0; print; next }
    inside {
      sub(/^    let /, "    public let ")
      sub(/^    init\(/, "    public init(")
      sub(/^    static let /, "    public static let ")
    }
    { print }
  ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
}

# Remove generated properties (declaration, doc comment, init param, assignment,
#     init(from:)/encode(to:) lines). A deprecated property is emitted as a
#     private `_name` backing property plus a deprecated `name` accessor; both are removed.
#     Runs before publicize, so there are no access modifiers to handle. Assumes the
#     single-line init the generator emits (step 8 re-wraps).
remove_property() {
  local file="$OUTPUT_DIR_CHAT/models/$1.swift"
  local p
  for p in "${@:2}"; do
    awk -v p="$p" '
      function flush() { for (i = 1; i <= n; i++) print b[i]; n = 0 }
      { s = $0; sub(/^[[:space:]]+/, "", s) }
      s ~ /^(\/\/\/|@available)/         { b[++n] = $0; next }
      s ~ "^let " p ": "                 { n = 0; next }
      s ~ "^private let _" p ": "        { n = 0; next }
      s ~ "^var " p ": .* \\{ _" p " \\}$" { n = 0; next }
      s ~ "^self\\._?" p " = " p "$"     { next }
      s ~ "^self\\._?" p " = try container\\.decode(IfPresent|ArrayIgnoringFailures|ArrayIfPresentIgnoringFailures)?\\(.*, forKey: \\." p "\\)$" { next }
      s ~ "^lhs\\._?" p " == rhs\\._?" p "( &&)?$" { next }
      s ~ "^hasher\\.combine\\(_?" p "\\)$"    { next }
      s ~ "^try container\\.encode(IfPresent)?\\(_?" p ", forKey: \\." p "\\)$" { next }
      s ~ /^init\(/ { sub("\\(" p ": [^,)]*, ", "("); sub(", " p ": [^,)]*", ""); sub("\\(" p ": [^,)]*\\)", "()") }
      { flush(); print }
    ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
    # Drop a trailing `&&` left dangling when the removed field was last in an == chain.
    perl -0777 -pi -e 's/ &&(\n\s*\})/$1/g' "$file"
    # A model left without properties has no wire keys, so synthesis can replace coders whose
    # container would go unused.
    perl -0777 -pi -e 's/\n\h*(?:init\(from decoder: Decoder\) throws|func encode\(to encoder: Encoder\) throws) \{\n\h*(?:let|var) container = [^\n]+\n\h*\}\n//g' "$file"
  done
}

remove_type() {
  local file="$OUTPUT_DIR_CHAT/models/$1.swift"
  awk -v e="$2" '
    $0 ~ "^final class " e ":" { skip = 1; next }
    skip && /^}$/               { skip = 0; next }
    skip                        { next }
    { print }
  ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
}

# Rename both the model file and every reference to the type.
rename_generated() {
  local old_path="$OUTPUT_DIR_CHAT/models/$1.swift"
  [[ -f "$old_path" ]] && mv "$old_path" "$OUTPUT_DIR_CHAT/models/$2.swift"
  rename_generated_type "$1" "$2"
}

rename_generated_events() {
  local f base
  for f in "$OUTPUT_DIR_CHAT"/models/*Event.swift; do
    [ -e "$f" ] || continue
    base="$(basename "$f" .swift)"
    [[ "$base" == "WSEvent" ]] && continue
    rename_generated "$base" "${base}DTO"
  done
}

# Rewrite every whole-word reference across the entire generated tree (models/ AND
# APIs/, so endpoint factories in DefaultEndpoints.swift are covered now and for any
# future references).
rename_generated_type() {
  local old="$1"
  local new="$2"
  find "$OUTPUT_DIR_CHAT" -name '*.swift' -exec sed -i '' -E "s/[[:<:]]$old[[:>:]]/$new/g" {} +
}

# Rename a generated property. The coders keep `forKey: .old`: StringCodingKey names
#     follow the wire key, not the property.
rename_property() {
  local file="$OUTPUT_DIR_CHAT/models/$1.swift"
  O="$2" N="$3" perl -0777 -pi -e '
    my ($o, $n) = ($ENV{O}, $ENV{N});
    s/^(\s*(?:public )?let )\Q$o\E:/$1$n:/mg;
    s/([(,]\s*)\Q$o\E:/$1$n:/g;
    s/^(\s*self\.)\Q$o\E = \Q$o\E$/$1$n = $n/mg;
    s/^(\s*self\.)\Q$o\E( = try container\.)/$1$n$2/mg;
    s/(try container\.encode(?:IfPresent)?\()\Q$o\E(, forKey: )/$1$n$2/g;
    s/(lhs\.)\Q$o\E( == rhs\.)\Q$o\E/${1}$n${2}$n/g;
    s/(hasher\.combine\()\Q$o\E(\))/$1$n$2/g;
  ' "$file"
}

require_property() {
  local file="$OUTPUT_DIR_CHAT/models/$1.swift"
  P="$2" perl -0777 -pi -e '
    my $p = $ENV{P};
    s/^(    let \Q$p\E: [^\n]+)\?$/$1/m;
    s/([(,]\s*)\Q$p\E: ([^,)\n]+?)\? = nil(?=[,)])/${1}$p: $2/;
    s/^(        self\.\Q$p\E = try container\.)decodeIfPresent\(/${1}decode(/m;
    s/^(        self\.\Q$p\E = try container\.)decodeArrayIfPresentIgnoringFailures\(/${1}decodeArrayIgnoringFailures(/m;
    s/^(        try container\.)encodeIfPresent\(\Q$p\E, /${1}encode($p, /m;
  ' "$file"
}

# Workaround for non-optional public property being backed with optional property
# Remove in the next major.
restore_nonoptional_property() {
  local file="$OUTPUT_DIR_CHAT/models/$1.swift"
  P="$2" T="$3" D="$4" perl -0777 -pi -e '
    my ($p, $t, $d) = ($ENV{P}, $ENV{T}, $ENV{D});
    s/^    let \Q$p\E: \Q$t\E\?$/    private let _$p: $t?\n    public var $p: $t { _$p ?? $d }/m;
    s/^        self\.\Q$p\E = \Q$p\E$/        self._$p = $p/m;
    s/^(        self\.)\Q$p\E( = try container\.)/${1}_$p$2/m;
    s/^(        try container\.encode(?:IfPresent)?\()\Q$p\E(, forKey: )/${1}_$p$2/m;
  ' "$file"
}

retype_property() {
  local file="$OUTPUT_DIR_CHAT/models/$1.swift"
  P="$2" O="$3" N="$4" perl -0777 -pi -e '
    my ($p, $o, $n) = ($ENV{P}, $ENV{O}, $ENV{N});
    s/(?<!\w)\Q$p\E: \Q$o\E(?!\w)/$p: $n/g;
    s/^(        self\.\Q$p\E = try container\.decode(?:IfPresent|ArrayIgnoringFailures|ArrayIfPresentIgnoringFailures)?\()\Q$o\E\.self/$1$n.self/m;
  ' "$file"
}

shape_wsevent() {
  local file="$OUTPUT_DIR_CHAT/models/WSEvent.swift"
  sed -i '' -E 's/^enum WSEvent: Codable, Hashable \{[[:space:]]*$/enum WSEvent: Codable {/' "$file"
  sed -i '' -E 's/^    var rawValue: Event \{[[:space:]]*$/    var rawValue: EventDTO {/' "$file"
  perl -0777 -pi -e 's/\n    func encode\(to encoder: Encoder\) throws \{\n.*?\n    \}\n//s' "$file"
}

# Strip the generated Hashable conformance from every model not in
# allowed_hashable_models. The Hashable extension is always the last block in the
# file (opening at column 0, running to EOF), so delete from its opening line to end
# of file; swiftformat (step 8) tidies the leftover blank line.
strip_hashable_conformance() {
  local f base
  for f in "$OUTPUT_DIR_CHAT"/models/*.swift; do
    [ -e "$f" ] || continue
    base="$(basename "$f" .swift)"
    contains "$base" "${allowed_hashable_models[@]}" && continue
    sed -i '' -E "/^extension ${base}: Hashable \{\$/,\$d" "$f"
  done
}

strip_streamcore_imports() {
  find "$OUTPUT_DIR_CHAT" -name '*.swift' -exec sed -i '' '/^import StreamCore$/d' {} +
}
