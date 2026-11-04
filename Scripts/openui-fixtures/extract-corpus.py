"""Extracts the parser corpus (doc examples, prompt examples, benchmark samples) from an OpenUI clone.

Usage: python3 -I extract-corpus.py <openui-clone> <out.json>

Same extraction as the original 2026-10-08 harness. The frozen output for 69f6783 is
corpus/base-corpus.json; every fixture generation reads that file, so the corpus stays the same
when the generator runs against a newer upstream.
"""
import glob
import json
import os
import re
import subprocess
import sys

up = os.path.abspath(sys.argv[1])
out = sys.argv[2]

blocks = []
for f in sorted(glob.glob(up + '/docs/content/docs/**/*.mdx', recursive=True)):
    text = open(f, encoding='utf-8').read()
    for m in re.finditer(r"```([a-zA-Z-]*)\n(.*?)```", text, re.S):
        lang, body = m.group(1), m.group(2)
        if re.search(r'(^|\n)\s*root\s*=', body) and lang in ('', 'text', 'openui-lang', 'openui'):
            blocks.append({'source': os.path.relpath(f, up), 'code': body})

src = open(up + '/packages/react-ui/src/genui-lib/prompt-options/index.ts', encoding='utf-8').read()
examples = re.findall(r'`(Example \d+ —.*?)`', src, re.S)

samples = up + '/benchmarks/samples'
benchmarks = [
    {'file': f, 'input': open(os.path.join(samples, f), encoding='utf-8').read()}
    for f in sorted(os.listdir(samples)) if f.endswith('.oui')
]

commit = subprocess.run(['git', '-C', up, 'rev-parse', 'HEAD'], capture_output=True, text=True).stdout.strip()
json.dump({'commit': commit, 'docs': blocks, 'examples': examples, 'benchmarks': benchmarks},
          open(out, 'w', encoding='utf-8'), indent=1, ensure_ascii=False)
print(f'{len(blocks)} doc blocks, {len(examples)} prompt examples, {len(benchmarks)} benchmarks from {commit[:7]}')
