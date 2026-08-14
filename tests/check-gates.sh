#!/usr/bin/env bash
# Sensor da máquina de estados do runner.
#
# O kit inteiro se apoia numa aposta: a fase corrente é DERIVADA dos artefatos em disco, e
# nenhum gate pode ser satisfeito por texto do modelo. Este teste monta um repo-fixture,
# faz os artefatos aparecerem um a um e afirma qual fase o runner deriva a cada passo —
# incluindo os casos em que o gate DEVE reprovar (done sem commit, nota B, matriz Pending,
# bug aberto no registry).
#
# Uso: tests/check-gates.sh   (exit 0 = máquina de estados correta)

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SDD="$ROOT/bin/sdd"
FIX="$(mktemp -d "${TMPDIR:-/tmp}/sdd-gates-XXXXXX")"
MISSION="20260101-fixture"
MDIR=""
fails=0
trap 'rm -rf "$FIX"' EXIT

pass() { printf '  ok    %s\n' "$1"; }
fail() { printf '  FALHA %s\n         esperado: %s\n         obtido:   %s\n' "$1" "$2" "$3" >&2
         fails=$((fails + 1)); }

# assert_phase <descrição> <fase esperada>
assert_phase() {
  local desc="$1" want="$2" got
  got="$( cd "$FIX" && "$SDD" phase "$MISSION" 2>&1 )"
  if [ "$got" = "$want" ]; then pass "$desc → $want"; else fail "$desc" "$want" "$got"; fi
}

# assert_why <descrição> <fase> <regex esperada no motivo>
assert_why() {
  local desc="$1" ph="$2" re="$3" got
  got="$( cd "$FIX" && "$SDD" why "$MISSION" "$ph" 2>&1 )"
  if printf '%s' "$got" | grep -qE "$re"; then pass "$desc"
  else fail "$desc" "motivo casando /$re/" "$got"; fi
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
mkdir -p "$MDIR" "$FIX/docs/qa/reports" "$FIX/docs/qa/bugs"

# --- PLAN ------------------------------------------------------------------
echo "== fase PLAN =="
assert_phase "missão sem nenhum artefato" "PLAN"

cat > "$MDIR/00-missao.md" <<'EOF'
---
missao: 20260101-fixture
aprovacao:
---
# Missão
EOF
: > "$MDIR/01-plano.md"
cat > "$MDIR/checkpoint.md" <<'EOF'
| ID | Incremento | Check (comando → esperado) | Status | Commit |
|---|---|---|---|---|
| I1 | fatia um | `true` → 0 | pending | — |
EOF
assert_phase "artefatos existem mas 'aprovacao' vazia" "PLAN"
assert_why   "PLAN explica a aprovação faltando" "PLAN" "aprovacao"

sed -i 's/^aprovacao:.*/aprovacao: auto/' "$MDIR/00-missao.md"
assert_phase "plano aprovado (auto) com incremento pendente" "EXEC"

# JIRA ligado sem versão trava no PLAN — rótulo de versão é decisão humana.
sed -i 's/^JIRA_ENABLED=false/JIRA_ENABLED=true/' .sdd/config.sh
assert_phase "JIRA_ENABLED=true sem 'versao:' no 00-missao" "PLAN"
assert_why   "PLAN explica a versão faltando" "PLAN" "versao"
sed -i 's/^JIRA_ENABLED=true/JIRA_ENABLED=false/' .sdd/config.sh

# --- EXEC ------------------------------------------------------------------
echo "== fase EXEC =="
sed -i 's/| I1 | fatia um | `true` → 0 | pending | — |/| I1 | fatia um | `true` → 0 | done | — |/' \
  "$MDIR/checkpoint.md"
assert_phase "incremento 'done' SEM commit não passa" "EXEC"
assert_why   "EXEC acusa rótulo sem artefato" "EXEC" "sem commit|não é artefato|rótulo"

sed -i 's/| I1 | fatia um | `true` → 0 | done | — |/| I1 | fatia um | `true` → 0 | done | deadbeef |/' \
  "$MDIR/checkpoint.md"
assert_phase "incremento 'done' com commit inexistente não passa" "EXEC"
assert_why   "EXEC acusa commit fantasma" "EXEC" "não existe no git log"

echo "mudança" >> arquivo.txt
git add -A && git commit -qm "feat: fatia um"
REAL_HASH="$(git rev-parse --short HEAD)"
sed -i "s/deadbeef/$REAL_HASH/" "$MDIR/checkpoint.md"
assert_phase "commit real mas sem 20-handoff-exec.md" "EXEC"
assert_why   "EXEC acusa handoff faltando" "EXEC" "20-handoff-exec"

sed -i 's/| I1 | fatia um |/| I1 | fatia um |/' "$MDIR/checkpoint.md"
printf -- '---\nfase: EXEC\nstatus: done\n---\n' > "$MDIR/20-handoff-exec.md"
git add -A && git commit -qm "chore: handoff"
assert_phase "handoff escrito, suíte verde" "QA"

# Jidoka: incremento `blocked` escala NA HORA, sem queimar sessão.
# `sdd run` decide isso antes de invocar o claude, então este teste não gasta token.
cp "$MDIR/checkpoint.md" "$MDIR/checkpoint.jidoka.bak"
sed -i "s/| done | $REAL_HASH |/| blocked | — |/" "$MDIR/checkpoint.md"
rm -f "$MDIR/20-handoff-exec.md"
run_out="$( cd "$FIX" && "$SDD" run "$MISSION" 2>&1 )"; run_rc=$?
if [ "$run_rc" -eq 3 ] && printf '%s' "$run_out" | grep -q "BLOCKED em EXEC"; then
  pass "incremento 'blocked' escala na hora (exit 3, sem gastar sessão)"
else
  fail "incremento 'blocked' deve escalar na hora" "exit 3 + 'BLOCKED em EXEC'" "exit $run_rc: $(printf '%s' "$run_out" | tail -3)"
fi
mv "$MDIR/checkpoint.jidoka.bak" "$MDIR/checkpoint.md"
printf -- '---\nfase: EXEC\nstatus: done\n---\n' > "$MDIR/20-handoff-exec.md"

# Status inválido no checkpoint reprova alto, não em silêncio.
cp "$MDIR/checkpoint.md" "$MDIR/checkpoint.bak"
sed -i "s/| done | $REAL_HASH |/| concluído | $REAL_HASH |/" "$MDIR/checkpoint.md"
assert_phase "status fora do enum reprova" "EXEC"
assert_why   "EXEC acusa status inválido" "EXEC" "status inválido"
mv "$MDIR/checkpoint.bak" "$MDIR/checkpoint.md"

# --- QA --------------------------------------------------------------------
echo "== fase QA =="
printf -- '---\nfase: QA\nstatus: done\n---\n' > "$MDIR/30-handoff-qa.md"
assert_phase "handoff de QA sem relatório em docs/qa/reports/" "QA"
assert_why   "QA acusa relatório ausente" "QA" "nenhum relatório"

cat > "$FIX/docs/qa/reports/2026-01-01-fixture.md" <<'EOF'
# QA Run Report — 2026-01-01 — fixture
- **Status:** in-progress
| # | Charter | Status |
|---|---|---|
| 1 | CH-um | Pending |
EOF
assert_phase "relatório aberto (in-progress)" "QA"
assert_why   "QA acusa relatório não fechado" "QA" "closed"

sed -i 's/\*\*Status:\*\* in-progress/**Status:** closed/' "$FIX/docs/qa/reports/2026-01-01-fixture.md"
assert_phase "relatório fechado mas com linha Pending na matriz" "QA"
assert_why   "QA acusa matriz Pending" "QA" "Pending"

sed -i 's/| 1 | CH-um | Pending |/| 1 | CH-um | Pass |/' "$FIX/docs/qa/reports/2026-01-01-fixture.md"
cat > "$FIX/docs/qa/bugs/BUG-20260101-teste.md" <<'EOF'
# BUG-20260101-teste: algo quebrou
- **Status:** open
EOF
assert_phase "bug com Status: open no registry" "QA"
assert_why   "QA acusa bug aberto" "QA" "Status: open|bug\(s\) com Status"

sed -i 's/\*\*Status:\*\* open/**Status:** wont-fix/' "$FIX/docs/qa/bugs/BUG-20260101-teste.md"
assert_phase "wont-fix é decisão humana, não bloqueia" "REVIEW"

# skipped curto-circuita tudo
cp "$MDIR/30-handoff-qa.md" "$MDIR/30.bak"
printf -- '---\nfase: QA\nstatus: skipped\n---\n' > "$MDIR/30-handoff-qa.md"
assert_phase "qa: skipped pula a fase inteira" "REVIEW"
mv "$MDIR/30.bak" "$MDIR/30-handoff-qa.md"

# --- REVIEW ----------------------------------------------------------------
echo "== fase REVIEW =="
cat > "$MDIR/40-review-r1.md" <<'EOF'
# Review r1
### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | A | clean |
| Security | B | um HIGH |
| **Overall** | **B** | |
EOF
assert_phase "review com nota B não passa" "REVIEW"
assert_why   "REVIEW acusa a nota exata" "REVIEW" "Security = B"

cat > "$MDIR/40-review-r2.md" <<'EOF'
# Review r2
### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | A | clean |
| Security | — | Not analyzed |
| **Overall** | **A** | |
EOF
assert_phase "critério '—' (não analisado) também reprova" "REVIEW"

cat > "$MDIR/40-review-r3.md" <<'EOF'
# Review r3
### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | A | clean |
| Security | A | clean |
| **Overall** | **A** | |
EOF
assert_phase "review sem a seção Overall Grade num r<N> anterior não importa: vale o último" "REVIEW"
assert_why   "REVIEW acusa tree sujo antes de aprovar" "REVIEW" "tree sujo|working tree"

git add -A && git commit -qm "chore: review"
assert_phase "último review todo A, suíte verde, tree limpo" "DOCS"

# --- DOCS ------------------------------------------------------------------
echo "== fase DOCS =="
printf '# Docs\n\n| Área | Doc | Status |\n|---|---|---|\n| runner | README | ✗ |\n\nchecklist de drift\n' \
  > "$MDIR/45-docs.md"
git add -A && git commit -qm "chore: docs parcial"
assert_phase "checklist de drift com item ✗" "DOCS"
assert_why   "DOCS acusa item pendente" "DOCS" "pendente"

printf '# Docs\n\n| Área | Doc | Status |\n|---|---|---|\n| runner | README | ✅ |\n\nchecklist de drift\n' \
  > "$MDIR/45-docs.md"
git add -A && git commit -qm "chore: docs"
assert_phase "checklist de drift completo" "PR"
assert_why   "PR acusa 50-pr.md faltando" "PR" "50-pr.md"

# ---------------------------------------------------------------------------
echo
if [ "$fails" -eq 0 ]; then
  echo "máquina de estados correta"
  exit 0
fi
echo "$fails asserção(ões) falharam" >&2
exit 1
