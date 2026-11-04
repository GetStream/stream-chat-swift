"""Summarizes how one set of fixtures differs from another (used to write CHANGES.md).

Usage: python3 -I diff-fixtures.py <old-dir> <new-dir> [--examples N]
"""
import json
import re
import sys
from collections import Counter, defaultdict

old_dir, new_dir = sys.argv[1], sys.argv[2]
N = int(sys.argv[sys.argv.index('--examples') + 1]) if '--examples' in sys.argv else 3


def load(d, f):
    return json.load(open(f'{d}/{f}', encoding='utf-8'))


def leaves(a, b, path=''):
    """Yields (path, old, new) for every differing leaf; missing keys are reported as <absent>."""
    if isinstance(a, dict) and isinstance(b, dict):
        for k in list(a.keys()) + [k for k in b if k not in a]:
            p = f'{path}.{k}'
            if k not in b:
                yield p, a[k], '<absent>'
            elif k not in a:
                yield p, '<absent>', b[k]
            else:
                yield from leaves(a[k], b[k], p)
    elif isinstance(a, list) and isinstance(b, list):
        for i in range(max(len(a), len(b))):
            p = f'{path}[{i}]'
            if i >= len(a):
                yield p, '<absent>', b[i]
            elif i >= len(b):
                yield p, a[i], '<absent>'
            else:
                yield from leaves(a[i], b[i], p)
    elif a != b or type(a) != type(b):
        yield path, a, b


def pattern(path):
    p = re.sub(r'\[\d+\]', '[]', path)
    p = re.sub(r'\.props\.[^.\[]+', '.props.*', p)
    p = re.sub(r'\.mappedProps\.[^.\[]+', '.mappedProps.*', p)
    p = re.sub(r'\.stateDeclarations\.[^.\[]+', '.stateDeclarations.*', p)
    return p


def short(v, n=160):
    s = json.dumps(v, ensure_ascii=False)
    return s if len(s) <= n else s[:n] + '…'


def report(title, pairs):
    """pairs: list of (case name, part, old value, new value)."""
    counts = Counter()
    cases = defaultdict(set)
    examples = defaultdict(list)
    for name, part, a, b in pairs:
        for path, x, y in leaves(a, b):
            pat = pattern(part + path)
            counts[pat] += 1
            cases[pat].add(name)
            if len(examples[pat]) < N:
                examples[pat].append((name, part + path, x, y))
    print(f'\n### {title}: {len(counts)} differing path patterns')
    for pat, n in counts.most_common():
        print(f'- {pat}: {n} leaves in {len(cases[pat])} cases')
        for name, path, x, y in examples[pat]:
            print(f'    {name} {path}: {short(x)} -> {short(y)}')


for f in ['parser-conformance.json', 'evaluator-conformance.json', 'prompt-goldens.json']:
    old = {c['name']: c for c in load(old_dir, f)}
    new = {c['name']: c for c in load(new_dir, f)}
    common = [n for n in old if n in new]
    print(f'\n## {f}: {len(old)} old cases, {len(new)} new cases, {len(common)} common, '
          f'{len([n for n in old if n not in new])} removed, {len([n for n in new if n not in old])} added')
    keys_old = Counter(k for c in old.values() for k in c)
    keys_new = Counter(k for c in new.values() for k in c)
    print('case keys old:', dict(keys_old))
    print('case keys new:', dict(keys_new))
    same_inputs = sum(old[n]['input'] == new[n]['input'] for n in common) if 'input' in next(iter(old.values())) else None
    print('common cases with identical input:', same_inputs)
    if f == 'parser-conformance.json':
        print('identical chunks/checkpoints:', sum(old[n]['chunks'] == new[n]['chunks'] and old[n]['checkpoints'] == new[n]['checkpoints'] for n in common))
        changed = [n for n in common if old[n]['result'] != new[n]['result']]
        print(f'one-shot result changed in {len(changed)} of {len(common)} cases')
        schanged = [n for n in common if old[n]['streamResults'] != new[n]['streamResults']]
        print(f'stream results changed in {len(schanged)} of {len(common)} cases')
        report('parser result', [(n, 'result', old[n]['result'], new[n]['result']) for n in common])
        report('parser streamResults', [(n, 'streamResults', old[n]['streamResults'], new[n]['streamResults']) for n in common])
    elif f == 'evaluator-conformance.json':
        changed = [n for n in common if old[n]['evaluatedRoot'] != new[n]['evaluatedRoot']]
        print(f'evaluatedRoot changed in {len(changed)} of {len(common)} cases')
        qchanged = [n for n in common if old[n]['queries'] != new[n]['queries']]
        print(f'queries changed in {len(qchanged)} of {len(common)} cases')
        report('evaluatedRoot', [(n, 'evaluatedRoot', old[n]['evaluatedRoot'], new[n]['evaluatedRoot']) for n in common])
        report('queries', [(n, 'queries', old[n]['queries'], new[n]['queries']) for n in common])
    else:
        for n in common:
            a, b = old[n], new[n]
            print(f'- {n}: options equal: {a["options"] == b["options"]}; prompt equal: {a["prompt"] == b["prompt"]}; '
                  f'lengths {len(a["prompt"])} -> {len(b["prompt"])}')

for f in ['upstream-chat-library.spec.json', 'upstream-playground-library.spec.json']:
    a, b = load(old_dir, f), load(new_dir, f)
    print(f'\n## {f}')
    print('top-level keys:', list(a), '->', list(b))
    print('schema keys:', list(a['schema']), '->', list(b['schema']))
    da, db = a['schema']['$defs'], b['schema']['$defs']
    print('$defs added:', [k for k in db if k not in da], 'removed:', [k for k in da if k not in db],
          'order of common equal:', [k for k in da if k in db] == [k for k in db if k in da])
    print('components added:', [k for k in b['components'] if k not in a['components']],
          'removed:', [k for k in a['components'] if k not in b['components']])
    sig = [k for k in a['components'] if k in b['components'] and a['components'][k] != b['components'][k]]
    print(f'components with changed signature/description: {len(sig)}')
    for k in sig:
        ca, cb = a['components'][k], b['components'][k]
        for field in ['signature', 'description']:
            if ca.get(field) != cb.get(field):
                print(f'  {k}.{field}: {short(ca.get(field), 400)}\n     -> {short(cb.get(field), 400)}')
    defs = [k for k in da if k in db and da[k] != db[k]]
    print(f'$defs entries changed: {len(defs)}: {defs}')
    for k in defs:
        for path, x, y in leaves(da[k], db[k]):
            print(f'  {k}{path}: {short(x, 200)} -> {short(y, 200)}')
    print('componentGroups equal:', a['componentGroups'] == b['componentGroups'])
    if a['componentGroups'] != b['componentGroups']:
        for path, x, y in leaves(a['componentGroups'], b['componentGroups']):
            print(f'  componentGroups{path}: {short(x, 300)} -> {short(y, 300)}')
    for key in ['$schema', 'type', 'properties', 'required', 'additionalProperties']:
        if a['schema'].get(key) != b['schema'].get(key):
            print(f'schema.{key} changed')
