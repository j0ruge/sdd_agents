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
# O diário do runner é efêmero e mora fora da árvore commitada (`log_dir()` em bin/sdd).
PIPELINE_LOG="$FIX/.sdd/logs/$MISSION/pipeline.log"
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

# --- a projeção não pode escrever no diário da missão ----------------------
# Achado da fase QA da missão 20260814-dry-run-completo: com um incremento `blocked`, o
# dry-run escapa pelo Jidoka de `cmd_run` ANTES de chegar ao bloco DRY_RUN, e aquele caminho
# chama `pipeline_log_line` sem guarda. Resultado: uma projeção — comando de leitura, que o
# usuário roda justamente para NÃO mexer em nada — grava no `pipeline.log` da missão um evento
# BLOCKED que nunca aconteceu, mentindo na trilha de auditoria. Pior num repo-alvo recém
# instalado: o `sdd install` só põe `.sdd/logs/` no `.gitignore`, então o `pipeline.log` fica
# como untracked e suja o working tree — e tree sujo reprova `gate_REVIEW` e o `sdd preflight`.
# Um comando de projeção não pode derrubar gate de outra fase.
echo "== projeção não escreve no diário da missão (incremento blocked) =="
sed -i 's/| pending |/| blocked |/' "$MDIR/checkpoint.md"
git add -A && git commit -qm "fixture: incremento blocked"

before_b="$(tree_snapshot)"
out3="$( "$SDD" run "$MISSION" --dry-run 2>&1 )"; rc3=$?
after_b="$(tree_snapshot)"

# Escalar é o comportamento certo e honesto: "se você rodar isto, a linha para". Guarda de
# regressão — isto já passava antes do achado.
assert_eq "dry-run de missão blocked escala com exit 3" "3" "$rc3"
# O Red do achado: a projeção não pode deixar rastro no disco, nem no caminho de escalação.
# O diário mora em `.sdd/logs/<missão>/` (mudou de lugar em 53cf63a — antes era `$MDIR`, dentro
# da árvore commitada, onde sujava o `git status` e derrubava `gate_REVIEW`). Esta asserção
# precisa apontar para onde o runner ESCREVE hoje: apontada para o caminho velho ela passa a
# ser decoração — verificado por mutação, com o bug do F1 reintroduzido ela continuava verde.
assert_eq "projeção blocked não escreve o pipeline.log" "" \
  "$( [ -e "$PIPELINE_LOG" ] && echo "pipeline.log criado" || true )"
assert_eq "árvore idêntica antes e depois (caminho blocked)" "$before_b" "$after_b"
assert_eq "working tree continua limpo (caminho blocked)" "" "$(git status --porcelain)"

# --- o outro lado da guarda: o caminho REAL ainda escreve --------------------
# Toda asserção acima afirma que a projeção NÃO escreve. Nenhuma afirmava que uma execução de
# verdade ESCREVE — então inverter a guarda (`= "1"` virar `!= "1"`) mataria o diário da missão
# em silêncio, com a suíte verde. Escrever de verdade normalmente exigiria uma `run_phase`, que
# chamaria o `claude`; o caminho de escalação `blocked` é a exceção: ele loga e retorna 3 ANTES
# de qualquer sessão, então dá para exercitar o caminho real sem gastar token nem rede.
echo "== o caminho real (não-dry) ainda escreve no diário =="
# Apagar antes é o que torna a asserção causal em vez de circunstancial: sem isto, um diário
# deixado para trás pela projeção (exatamente o que acontece se a guarda for invertida) faria
# o `[ -e ]` passar pelo motivo errado. Verificado por mutação — foi o que aconteceu na 1ª
# versão desta seção, que dava "ok" com a guarda invertida.
rm -f "$PIPELINE_LOG"
"$SDD" run "$MISSION" >/dev/null 2>&1; rc4=$?
assert_eq "execução real de missão blocked escala com exit 3" "3" "$rc4"
assert_eq "o caminho real ESCREVE o pipeline.log em .sdd/logs/<missão>/" "existe" \
  "$( [ -e "$PIPELINE_LOG" ] && echo existe || echo "ausente" )"
assert_eq "o evento registrado é o BLOCKED" "1" \
  "$(grep -c 'BLOCKED' "$PIPELINE_LOG" 2>/dev/null || echo 0)"
# O diário é efêmero por contrato: `.sdd/logs/` está no `.gitignore` que o `sdd install` escreve.
# Se ele voltar para dentro da árvore commitada, suja o working tree e derruba `gate_REVIEW`.
assert_eq "o diário fica FORA da árvore commitada" "" "$(git status --porcelain)"
assert_eq "nada de pipeline.log em docs/handoffs/" "0" \
  "$(find docs/handoffs -name 'pipeline.log' 2>/dev/null | wc -l | tr -d ' ')"

# Agora que o diário EXISTE, a asserção do F1 fica mais forte: a projeção não pode nem criar
# nem ALTERAR o diário. `tree_snapshot` compara nomes, não conteúdo — só o md5 pega a escrita
# num arquivo que já existia, que é o caso de qualquer missão que já rodou uma vez de verdade.
md5_before="$(md5sum "$PIPELINE_LOG" | cut -d' ' -f1)"
"$SDD" run "$MISSION" --dry-run >/dev/null 2>&1
md5_after="$(md5sum "$PIPELINE_LOG" | cut -d' ' -f1)"
assert_eq "projeção não ALTERA um pipeline.log preexistente" "$md5_before" "$md5_after"

sed -i 's/| blocked |/| pending |/' "$MDIR/checkpoint.md"

# ---------------------------------------------------------------------------
echo
if [ "$fails" -eq 0 ]; then
  echo "projeção do dry-run correta"
  exit 0
fi
echo "$fails asserção(ões) falharam" >&2
exit 1
