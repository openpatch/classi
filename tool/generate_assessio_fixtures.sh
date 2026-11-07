#!/usr/bin/env bash
# Regenerates test/fixtures/assessio/*.json from a typst-assessio checkout.
# The fixtures pin the grading rules classi shares with assessio (maximum
# points, elective groups, grade cutoffs); see exam_calculator_parity_test.dart.
#
# Usage: tool/generate_assessio_fixtures.sh [path/to/typst-assessio]
set -euo pipefail

assessio="${1:-$HOME/Sources/openpatch/typst-assessio}"
out="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/test/fixtures/assessio"
mkdir -p "$out"

for fixture in examples/basic.typ tests/fixtures/grade-rounding.typ tests/fixtures/manifest.typ; do
  name="$(basename "$fixture" .typ)"
  typst eval --root "$assessio" --in "$assessio/$fixture" \
    'query(<assessio-manifest>).first().value' >"$out/$name.json"
  echo "wrote $out/$name.json"
done
