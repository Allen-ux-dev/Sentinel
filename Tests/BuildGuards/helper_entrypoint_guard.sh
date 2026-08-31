#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
failed=0

while IFS= read -r -d '' file; do
  if grep -Eq '^[[:space:]]*@main\b' "$file"; then
    echo "FAIL: ${file#$ROOT/} declares @main. Swift treats a file named main.swift as a top-level entry point, so @main is not allowed there."
    failed=1
  fi
done < <(find "$ROOT/Sources" -type f -name main.swift -print0)

if [[ "$failed" -ne 0 ]]; then
  exit 1
fi

echo "PASS: no main.swift file declares @main."
