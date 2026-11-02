"""Classifies how each parse result changed between two parser-conformance.json files.

Usage: python3 -I analyze-parser-changes.py <old parser-conformance.json> <new parser-conformance.json>

New results are normalized first (built-in calls' `mappedProps`, `fn`, error `severity` and
`rootExpression` removed); what still differs is then attributed to root / errors / orphans / ...
"""
import json
import sys
from collections import Counter, defaultdict

BUILTIN_CALLS = {'Count', 'First', 'Last', 'Sum', 'Avg', 'Min', 'Max', 'Sort', 'Filter', 'Round', 'Abs',
                 'Floor', 'Ceil', 'Each', 'Run', 'ToAssistant', 'OpenUrl', 'Set', 'Reset', 'Action'}

old = {c['name']: c for c in json.load(open(sys.argv[1], encoding='utf-8'))}
new = {c['name']: c for c in json.load(open(sys.argv[2], encoding='utf-8'))}
common = [n for n in old if n in new]

annotation = Counter()


def normalize(v):
    if isinstance(v, list):
        return [normalize(x) for x in v]
    if not isinstance(v, dict):
        return v
    out = {}
    for k, x in v.items():
        if k == 'mappedProps' and v.get('k') == 'Comp' and v.get('name') in BUILTIN_CALLS:
            annotation['mappedProps on built-in call'] += 1
            continue
        if k == 'fn' and v.get('k') == 'Comp':
            annotation['fn: true on @call'] += 1
            continue
        if k == 'severity' and 'code' in v:
            annotation['error severity'] += 1
            continue
        if k == 'rootExpression':
            annotation['rootExpression'] += 1
            continue
        out[k] = normalize(x)
    return out


def err_key(e):
    return (e['code'], e.get('statementId'), e.get('component'), e.get('path'))


def classify(a, b):
    cats = []
    if a == b:
        return cats
    if a.get('root') != b.get('root'):
        ra, rb = a.get('root'), b.get('root')
        if (ra is None) != (rb is None) or (ra and rb and (ra.get('statementId'), ra.get('typeName')) != (rb.get('statementId'), rb.get('typeName'))):
            cats.append('root (entry) changed')
        else:
            cats.append('root tree changed')
    ma, mb = a['meta'], b['meta']
    if Counter(map(err_key, ma['errors'])) != Counter(map(err_key, mb['errors'])):
        cats.append('errors changed')
    elif ma['errors'] != mb['errors']:
        cats.append('error text/order changed')
    for k in ['orphaned', 'unresolved', 'incomplete', 'statementCount']:
        if ma.get(k) != mb.get(k):
            cats.append(f'meta.{k} changed')
    for k in ['stateDeclarations', 'queryStatements', 'mutationStatements']:
        if a.get(k) != b.get(k):
            cats.append(f'{k} changed')
    if not cats:
        cats.append('other')
    return cats


one_shot = defaultdict(list)
stream = defaultdict(list)
code_delta = Counter()
stream_code_delta = Counter()
annotation_only_one_shot = []
for n in common:
    a, b = old[n]['result'], new[n]['result']
    nb = normalize(b)
    if a != b and nb == a:
        annotation_only_one_shot.append(n)
    for cat in classify(a, nb):
        one_shot[cat].append(n)
    ea, eb = Counter(e['code'] for e in a['meta']['errors']), Counter(e['code'] for e in b['meta']['errors'])
    for code in set(ea) | set(eb):
        if eb[code] != ea[code]:
            code_delta[code] += eb[code] - ea[code]
    for i, (sa, sb) in enumerate(zip(old[n]['streamResults'], new[n]['streamResults'])):
        nsb = normalize(sb)
        for cat in classify(sa, nsb):
            stream[cat].append((n, i))
        ea, eb = Counter(e['code'] for e in sa['meta']['errors']), Counter(e['code'] for e in sb['meta']['errors'])
        for code in set(ea) | set(eb):
            if eb[code] != ea[code]:
                stream_code_delta[code] += eb[code] - ea[code]

print('annotations stripped (all results, all cases):', dict(annotation))
print(f'one-shot results that differ only by annotations: {len(annotation_only_one_shot)}: {annotation_only_one_shot}')
print('one-shot categories (after normalizing):')
for cat, names in sorted(one_shot.items(), key=lambda x: -len(x[1])):
    print(f'  {cat}: {len(names)} cases: {names}')
print('one-shot error code deltas (new - old):', dict(code_delta))
print('stream snapshot categories (after normalizing):')
for cat, items in sorted(stream.items(), key=lambda x: -len(x[1])):
    cases = sorted(set(n for n, _ in items))
    print(f'  {cat}: {len(items)} snapshots in {len(cases)} cases: {cases}')
print('stream error code deltas (new - old):', dict(stream_code_delta))
total = sum(len(old[n]['streamResults']) for n in common)
changed = sum(1 for n in common for sa, sb in zip(old[n]['streamResults'], new[n]['streamResults']) if sa != sb)
print(f'stream snapshots changed: {changed} of {total}')
cr = [n for n in new if new[n].get('completeResult') is not None and new[n]['streamResults'] and new[n]['completeResult'] != new[n]['streamResults'][-1]]
print(f'cases whose completeResult differs from the last streamResult: {len(cr)}: {cr}')
cr2 = [n for n in new if new[n].get('completeResult') is not None and new[n]['completeResult'] != new[n]['result']]
print(f'cases whose completeResult differs from the one-shot result: {len(cr2)}: {cr2}')
