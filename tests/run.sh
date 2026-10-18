#!/usr/bin/env bash
# tests/run.sh -- the Vim pack is ACTUALLY LOADED into vim and queried with
# synIDattr(synIDtrans(synID(l, c, 1))) at specific positions. Skips (exit 0)
# when vim is missing.
set -uo pipefail
cd "$(dirname "$0")/.."
ROOT="$PWD"
fails=0
VIMDIR="$ROOT"
SAMPLE="$(mktemp -d)/sample.tur"
cat > "$SAMPLE" <<'EOF'
#lang saffron
;;; add -- adds two values.
;; ordinary comment
(defn add [a b] (+ a b))
(defn typed [x : int y :float] : bool (is? x int))
(defn m [^mut w : World] (set! w 1))
(def pi 3.25)
(println "hi" true nil)
#map{:a 1}
(defn p [x : #refine{v : int | (> v 0)}] x)
EOF
# r7rs-lang-plan R9: the Scheme lexemes, active in a `#lang r7rs` file only.
SCHEME_SAMPLE="$(dirname "$SAMPLE")/scheme.tur"
cat > "$SCHEME_SAMPLE" <<'EOF'
#lang r7rs
(define-library (m) (export f))
(define v '#(#t #\space |two words| #x1F))
#| block |# #;(skip)
EOF

# ---------------------------------------------------------------- vim ------
if ! command -v vim >/dev/null 2>&1; then
    echo "SKIP: vim not available -- vim syntax pack not exercised"
else
    PROBE="$(mktemp)"
    OUT="$(mktemp)"
    # line, col, expected TRANSITIVE highlight group.  Transitive because the
    # pack links to standard groups (Function->Identifier, String->Constant,
    # SpecialComment->Special, StorageClass->Type), and those links are what a
    # colourscheme actually reads.
    cat > "$PROBE" <<VIM
set nocompatible
syntax on
set runtimepath+=$VIMDIR
filetype plugin on
edit $SAMPLE
setfiletype turmeric
redir! > $OUT
for [l, c, want, what] in [
      \\ [1, 2,  'PreProc',    '#lang directive'],
      \\ [1, 7,  'Type',       'saffron base'],
      \\ [2, 3,  'Special',    ';;; docstring'],
      \\ [3, 3,  'Comment',    ';; comment'],
      \\ [4, 3,  'Statement',  'defn'],
      \\ [4, 7,  'Identifier', 'the bound name'],
      \\ [5, 20, 'Type',       'SPACED annotation'],
      \\ [5, 27, 'Type',       'FUSED annotation'],
      \\ [6, 11, 'Type',       '^mut attribute'],
      \\ [7, 10, 'Constant',   'float literal'],
      \\ [8, 11, 'Constant',   'string'],
      \\ [9, 2,  'PreProc',    '#map dispatch'],
      \\ [9, 6,  'Constant',   'keyword literal in value position'],
      \\ [10, 37, 'Constant',  'a #refine | is not a Scheme bar symbol outside r7rs']]
  let got = synIDattr(synIDtrans(synID(l, c, 1)), 'name')
  echo (got ==# want ? 'ok  ' : 'BAD ') . what . ' want=' . want . ' got=' . got
endfor
echo 'ft=' . &filetype
edit $SCHEME_SAMPLE
setfiletype turmeric
for [l, c, want, what] in [
      \\ [1, 7,  'Type',       'r7rs base'],
      \\ [2, 2,  'Statement',  'define-library is a Scheme form'],
      \\ [3, 12, 'PreProc',    'the #( vector opener'],
      \\ [3, 14, 'Constant',   '#t boolean'],
      \\ [3, 17, 'Constant',   '#\\space character'],
      \\ [3, 27, 'Identifier', 'inside a |two words| symbol'],
      \\ [3, 38, 'Constant',   '#x1F radix number'],
      \\ [4, 4,  'Comment',    'inside a #| |# block comment'],
      \\ [4, 13, 'Comment',    'the #; datum comment']]
  let got = synIDattr(synIDtrans(synID(l, c, 1)), 'name')
  echo (got ==# want ? 'ok  ' : 'BAD ') . what . ' want=' . want . ' got=' . got
endfor
redir END
qall!
VIM
    vim -es -u NONE -i NONE -S "$PROBE" >/dev/null 2>&1
    if [ ! -s "$OUT" ]; then
        echo "FAIL vim: the probe produced no output (syntax file failed to load?)"
        fails=$((fails + 1))
    else
        if grep -q '^BAD ' "$OUT"; then
            echo "FAIL vim: wrong highlight group(s)"
            grep '^BAD ' "$OUT" | sed 's/^/       /'
            fails=$((fails + 1))
        else
            echo "ok   vim: $(grep -c '^ok  ' "$OUT") highlight positions correct"
        fi
        if ! grep -q '^ft=turmeric$' "$OUT"; then
            echo "FAIL vim: ftdetect did not set filetype=turmeric for a .tur file"
            fails=$((fails + 1))
        fi
    fi
    rm -f "$PROBE" "$OUT"
fi

rm -rf "$(dirname "$SAMPLE")"
if [ "$fails" -ne 0 ]; then
    echo "vim-turmeric: $fails check(s) failed"
    exit 1
fi
echo "vim-turmeric: all checks passed"
