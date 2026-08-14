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
# `|| exit`: sem `set -e`, um `cd` que falha seguiria rodando `git init`, `sed -i` e
# `git commit` no repo REAL de quem rodou o teste.
cd "$FIX" || exit 1

# Nenhum teste pode gastar token nem rede. O `sdd run` real logo abaixo só é seguro porque o
# Jidoka de `blocked` escapa ANTES de qualquer `run_phase`; se essa ordem quebrar, o runner
# chamaria o `claude` de verdade. O stub torna isso impossível por construção.
mkdir -p "$FIX/.stub"
cat > "$FIX/.stub/claude" <<'STUB'
#!/usr/bin/env bash
echo "ERRO: o teste invocou o claude de verdade — o caminho de escalação não escapou antes da sessão" >&2
exit 97
STUB
chmod +x "$FIX/.stub/claude"
PATH="$FIX/.stub:$PATH"

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

# --- TICKET ----------------------------------------------------------------
echo "== fase TICKET =="
sed -i 's/^JIRA_ENABLED=false/JIRA_ENABLED=true/' .sdd/config.sh
sed -i 's/^aprovacao: auto/aprovacao: auto\nversao: 0.1.0/' "$MDIR/00-missao.md"
printf 'PROJECT=FX\nBOARD=1\n' > .jira-project
assert_phase "JIRA ligado e sem 10-ticket.md" "TICKET"
assert_why   "TICKET acusa o arquivo faltando" "TICKET" "10-ticket.md"

printf -- '---\nfase: TICKET\nstatus: done\nissue: FX-1\n---\n' > "$MDIR/10-ticket.md"
assert_phase "issue sem sprint não passa (card no backlog é trabalho invisível)" "TICKET"
assert_why   "TICKET acusa a sprint faltando" "TICKET" "SPRINT ATIVA|sprint"

printf -- '---\nfase: TICKET\nstatus: done\nissue: FX-1\nsprint: Sprint 1\n---\n' > "$MDIR/10-ticket.md"
assert_phase "issue na sprint ativa passa" "EXEC"

# volta ao estado sem JIRA para o resto do teste
sed -i 's/^JIRA_ENABLED=true/JIRA_ENABLED=false/' .sdd/config.sh
rm -f .jira-project "$MDIR/10-ticket.md"

# --- EXEC ------------------------------------------------------------------
echo "== fase EXEC =="
sed -i 's/| I1 | fatia um | `true` → 0 | pending | — |/| I1 | fatia um | `true` → 0 | done | — |/' \
  "$MDIR/checkpoint.md"
assert_phase "incremento 'done' SEM commit não passa" "EXEC"
assert_why   "EXEC acusa rótulo sem artefato" "EXEC" "sem commit|não é artefato|rótulo"

sed -i 's/| I1 | fatia um | `true` → 0 | done | — |/| I1 | fatia um | `true` → 0 | done | deadbeef |/' \
  "$MDIR/checkpoint.md"
assert_phase "incremento 'done' com commit inexistente não passa" "EXEC"
assert_why   "EXEC acusa commit fantasma" "EXEC" "não existe no repositório"

echo "mudança" >> arquivo.txt
git add -A && git commit -qm "feat: fatia um"

# Commit ORFAO: existe no banco de objetos, mas saiu da historia depois de um amend. É o caso
# que `git cat-file -e` deixa passar — ele so pergunta se o objeto existe. Sem checar
# alcancabilidade, um checkpoint citando o hash pre-amend satisfaz o gate apontando para fora
# da historia, e o commit ainda pode sumir no gc com o gate verde. Medido pelo sdd-qa na missão
# 20260814-dry-run-completo, com um amend de verdade.
ORPHAN_HASH="$(git rev-parse --short HEAD)"
git commit -q --amend -m "feat: fatia um (amendado)"
REAL_HASH="$(git rev-parse --short HEAD)"
sed -i "s/deadbeef/$ORPHAN_HASH/" "$MDIR/checkpoint.md"
if git cat-file -e "${ORPHAN_HASH}^{commit}" 2>/dev/null; then
  pass "fixture: o commit órfão AINDA existe no banco de objetos (é o que engana o gate ingênuo)"
else
  fail "fixture do commit órfão" "objeto ainda no banco" "objeto já coletado"
fi
assert_phase "commit órfão (existe mas fora da história) não passa" "EXEC"
assert_why   "EXEC acusa commit fora da história" "EXEC" "NÃO está na história|alcançável"

sed -i "s/$ORPHAN_HASH/$REAL_HASH/" "$MDIR/checkpoint.md"
assert_phase "commit real mas sem 20-handoff-exec.md" "EXEC"
assert_why   "EXEC acusa handoff faltando" "EXEC" "20-handoff-exec"

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
# O gate de QA tem DOIS contratos, porque há dois tipos de projeto.
#
# Projeto COM interface: as skills qa-report/qa-execution rodam e a prova é o relatório datado
# delas. Projeto SEM interface: essas skills nem são chamadas (`qa_substep` vai direto ao
# sdd-qa), então cobrar o relatório delas deixaria o gate insatisfazível justamente quando a QA
# fez o trabalho e achou algo — ali a prova é o campo `gate:` do próprio handoff.
echo "== fase QA — projeto COM interface =="
sed -i 's|^E2E_CMD=""|E2E_CMD="true"\nAPP_URL="http://exemplo.invalido"|' .sdd/config.sh
printf -- '---\nfase: QA\nstatus: done\n---\n' > "$MDIR/30-handoff-qa.md"
assert_phase "handoff de QA sem relatório em docs/qa/reports/" "QA"
assert_why   "QA acusa relatório ausente" "QA" "nenhum relatório"

cat > "$FIX/docs/qa/reports/2026-01-01-fixture.md" <<'EOF'
# QA Run Report — 2026-01-01 — fixture
- **Started:** 2026-01-01T10:00:00Z · **Status:** in-progress <!-- in-progress | closed -->
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

echo "== fase QA — projeto SEM interface =="
# Sem E2E_CMD e sem APP_URL a árvore docs/qa/ nunca é criada por ninguém. Aqui o gate mede o
# handoff: `status: done` só passa acompanhado da evidência da jornada andada.
sed -i 's|^E2E_CMD="true"|E2E_CMD=""|; s|^APP_URL=.*||' .sdd/config.sh
printf -- '---\nfase: QA\nstatus: done\n---\n' > "$MDIR/30-handoff-qa.md"
assert_phase "sem interface, 'done' sem evidência não passa" "QA"
assert_why   "QA pede a evidência da jornada" "QA" "evidência da jornada|sem interface"

printf -- '---\nfase: QA\nstatus: done\ngate: "1 jornada andada no CLI; 1 achado virou F1"\n---\n' \
  > "$MDIR/30-handoff-qa.md"
assert_phase "sem interface, 'done' COM evidência passa" "REVIEW"

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

# Relatório real tem seções DEPOIS da tabela de grade, e em nível SUPERIOR (`##`). O parser
# parava só em `###`, seguia lendo as tabelas seguintes e reprovava um relatório todo A ao achar
# uma coluna `Commit`. O fixture reproduz essa forma de propósito.
cat > "$MDIR/40-review-r3.md" <<'EOF'
# Review r3
### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | A | clean |
| Security | A | clean |
| **Overall** | **A** | |

---

## Correções desta rodada

| Commit | O que |
|---|---|
| abc1234 | corrige o teste |

## Achados registrados no TODO

| ID | Severidade | Destino |
|---|---|---|
| R1-03 | MEDIUM | TODO.md |
EOF
assert_phase "review sem a seção Overall Grade num r<N> anterior não importa: vale o último" "REVIEW"
assert_why   "REVIEW acusa tree sujo antes de aprovar" "REVIEW" "tree sujo|working tree"

git add -A && git commit -qm "chore: review"
assert_phase "último review todo A, suíte verde, tree limpo" "DOCS"

# --- DOCS ------------------------------------------------------------------
echo "== fase DOCS =="
# O gate le a COLUNA Status da tabela, nao a palavra solta: um 45-docs.md que cite o TODO.md
# pelo nome — o que o sdd-docs e OBRIGADO a fazer — nao pode reprovar por isso.
printf '# Docs\n\nchecklist de drift\n\n| Área | Doc | Status | Evidência |\n|---|---|---|---|\n| runner | README | ✗ | pendente |\n\nAchados registrados no TODO.md desta missão.\n' \
  > "$MDIR/45-docs.md"
git add -A && git commit -qm "chore: docs parcial"
assert_phase "checklist de drift com item ✗" "DOCS"
assert_why   "DOCS acusa a área com Status pendente, citando o valor" "DOCS" "Status '✗'"

printf '# Docs\n\nchecklist de drift\n\n| Área | Doc | Status | Evidência |\n|---|---|---|---|\n| runner | README | ✅ | commit abc1234 |\n| libs | — | n/a | refactor interno |\n\nAchados registrados no TODO.md desta missão.\n' \
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
