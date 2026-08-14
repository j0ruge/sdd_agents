#!/usr/bin/env bash
# Sensor da projeção do dry-run.
#
# `sdd run <missão> --dry-run` existe para responder "o que vai acontecer se eu rodar isto?"
# ANTES de gastar token. Responder só pela primeira fase é responder pela metade: o usuário
# não fica sabendo que depois viriam QA, REVIEW, DOCS e PR, nem com que agente cada uma roda.
#
# Este teste monta um repo-fixture parado em EXEC e afirma que o dry-run projeta a sequência
# inteira de fases pendentes, na ordem, cada uma com o agente certo (ou <nenhum>, quando quem
# dirige a sessão é uma skill de terceiro pelo slash literal) — e que nada no disco muda.
#
# Uso: tests/check-dry-run.sh   (exit 0 = projeção correta)

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SDD="$ROOT/bin/sdd"
FIX="$(mktemp -d "${TMPDIR:-/tmp}/sdd-dryrun-XXXXXX")"
MISSION="20260101-fixture"
fails=0
trap 'rm -rf "$FIX"' EXIT

pass() { printf '  ok    %s\n' "$1"; }
fail() { printf '  FALHA %s\n         esperado: %s\n         obtido:   %s\n' "$1" "$2" "$3" >&2
         fails=$((fails + 1)); }

# assert_eq <descrição> <esperado> <obtido>
assert_eq() {
  if [ "$2" = "$3" ]; then pass "$1"; else fail "$1" "$2" "$3"; fi
}

# A sequência (fase, agente) que o dry-run imprimiu, uma por linha, na ordem de impressão.
# Uma única asserção cobre quatro coisas: quais fases aparecem, em que ordem, quantas vezes
# cada uma, e qual agente foi anunciado em cada bloco.
projected() {
  awk '
    /^--- DRY RUN: fase .* ---$/ { ph = $5; next }
    ph != "" && /agente:/ {
      for (i = 1; i <= NF; i++) if ($i == "agente:") { printf "%s=%s\n", ph, $(i + 1); ph = "" }
    }
  '
}

# Impressão digital de tudo que existe no fixture, exceto o .git. Dry-run não pode mexer aqui.
tree_snapshot() {
  ( cd "$FIX" && find . -path ./.git -prune -o -print | LC_ALL=C sort )
}

# ---------------------------------------------------------------------------
echo "== fixture em $FIX =="
cd "$FIX"
git init -q -b main
git config user.email "fixture@example.com"
git config user.name "Fixture"
echo "conteúdo" > arquivo.txt
git add -A && git commit -qm "init"

"$SDD" install >/dev/null
cat > .sdd/config.sh <<'EOF'
PROJECT_NAME="fixture"
DEFAULT_BRANCH="main"
TEST_CMD="true"
E2E_CMD=""
HANDOFF_DIR="docs/handoffs"
QA_DOCS_PATH="docs/qa"
JIRA_ENABLED=false
EOF

MDIR="$FIX/docs/handoffs/$MISSION"
mkdir -p "$MDIR"
cat > "$MDIR/00-missao.md" <<'EOF'
---
missao: 20260101-fixture
aprovacao: auto
---
# Missão
EOF
: > "$MDIR/01-plano.md"
cat > "$MDIR/checkpoint.md" <<'EOF'
| ID | Incremento | Check (comando → esperado) | Status | Commit |
|---|---|---|---|---|
| I1 | fatia um | `true` → 0 | pending | — |
EOF
git add -A && git commit -qm "chore: missão-fixture"

# Sanidade: sem isto, um fixture mal montado faria o teste passar/falhar pelo motivo errado.
here="$( "$SDD" phase "$MISSION" 2>&1 )"
assert_eq "fixture parado na fase EXEC" "EXEC" "$here"

# --- projeção completa -----------------------------------------------------
echo "== projeção =="
before="$(tree_snapshot)"
out="$( "$SDD" run "$MISSION" --dry-run 2>&1 )"; rc=$?
after="$(tree_snapshot)"

assert_eq "dry-run sai 0" "0" "$rc"

want="$(printf '%s\n' \
  "EXEC=sdd-executor" \
  "QA:close=sdd-qa" \
  "REVIEW=sdd-reviewer" \
  "DOCS=sdd-docs" \
  "PR=sdd-publisher")"
got="$(printf '%s\n' "$out" | projected)"
assert_eq "projeta EXEC→QA→REVIEW→DOCS→PR, na ordem, cada uma com seu agente" "$want" "$got"

# TICKET tem o gate satisfeito (JIRA_ENABLED=false): fase satisfeita não entra na projeção.
if printf '%s\n' "$out" | grep -q '^--- DRY RUN: fase TICKET ---$'; then
  fail "fase com gate satisfeito não aparece na projeção" "sem bloco TICKET" "bloco TICKET impresso"
else
  pass "fase com gate satisfeito (TICKET) não aparece na projeção"
fi

# --- nada é executado, nada muda no disco ----------------------------------
echo "== dry-run não toca no disco =="
assert_eq "árvore de arquivos idêntica antes e depois" "$before" "$after"
assert_eq "working tree continua limpo" "" "$(git status --porcelain)"

# --- --phase continua imprimindo só a fase pedida --------------------------
echo "== --phase <FASE> =="
out1="$( "$SDD" run "$MISSION" --dry-run --phase QA 2>&1 )"
# QA são três sessões derivadas dos artefatos (planejar → andar → fechar). Este fixture não tem
# interface para andar (E2E_CMD e APP_URL vazios), então o sub-passo é `close`: o sdd-qa julga se
# o diff é user-visible e, não sendo, escreve `qa: skipped`.
assert_eq "--phase QA imprime só o sub-passo corrente" "QA:close=sdd-qa" "$(printf '%s\n' "$out1" | projected)"

# --- o sub-passo de QA muda com a existência de interface ------------------
echo "== sub-passo de QA derivado dos artefatos =="
# Com E2E_CMD definido e nenhum charter na árvore, o ciclo começa pelo planejamento — dirigido
# pela skill qa-report via slash literal, por isso sem agente do kit.
sed -i 's|^E2E_CMD=""|E2E_CMD="true"|' .sdd/config.sh
out2="$( "$SDD" run "$MISSION" --dry-run --phase QA 2>&1 )"
assert_eq "projeto COM interface e sem charters começa em QA:plan (skill qa-report)" \
  "QA:plan=<nenhum>" "$(printf '%s\n' "$out2" | projected)"
# O dry-run imprime o prompt com o prefixo "  │ ", então a âncora inclui a primeira linha do
# bloco — é ali que o slash precisa estar para expandir em headless.
if printf '%s\n' "$out2" | grep -q '│ /qa-report docs/qa'; then
  pass "o prompt de boot começa com o slash literal /qa-report"
else
  fail "boot de QA:plan" "prompt começando com /qa-report" "$(printf '%s\n' "$out2" | grep -m1 '│' || echo vazio)"
fi
sed -i 's|^E2E_CMD="true"|E2E_CMD=""|' .sdd/config.sh

# ---------------------------------------------------------------------------
echo
if [ "$fails" -eq 0 ]; then
  echo "projeção do dry-run correta"
  exit 0
fi
echo "$fails asserção(ões) falharam" >&2
exit 1
