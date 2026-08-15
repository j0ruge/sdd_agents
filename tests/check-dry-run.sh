#!/usr/bin/env bash
# Sensor da projeção do dry-run.
#
# `sdd run <missão> --dry-run` existe para responder "o que vai acontecer se eu rodar isto?"
# ANTES de gastar token. Responder só pela primeira fase é responder pela metade: o usuário
# não fica sabendo que depois viriam QA, REVIEW, DOCS e PR, nem com que agente cada uma roda.
#
# Este teste monta um repo-fixture parado em EXEC e afirma que o dry-run projeta a sequência
# inteira de fases pendentes, na ordem, cada uma com o agente certo (ou <none>, quando quem
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
    /^--- DRY RUN: phase .* ---$/ { ph = $5; next }
    ph != "" && /agent:/ {
      for (i = 1; i <= NF; i++) if ($i == "agent:") { printf "%s=%s\n", ph, $(i + 1); ph = "" }
    }
  '
}

# Impressão digital de tudo que existe no fixture, exceto o .git. Dry-run não pode mexer aqui.
tree_snapshot() {
  ( cd "$FIX" && find . -path ./.git -prune -o -print | LC_ALL=C sort )
}

# ---------------------------------------------------------------------------
echo "== fixture em $FIX =="
# `|| exit`: `set -e` está fora (precisamos de `rc=$?` depois dos comandos que falham de
# propósito), então um `cd` que falha seguiria rodando `git init`, `sed -i` e `git commit` no
# repo REAL de quem rodou o teste. Falhar aqui é barato; corromper o repo do dev não é.
cd "$FIX" || exit 1

# Nenhum teste pode gastar token nem rede. O caminho "execução real" abaixo depende de o Jidoka
# de `blocked` escapar ANTES de qualquer `run_phase` — se essa ordem quebrar, o runner chamaria
# o `claude` de verdade. Este stub torna isso impossível por construção: em vez de uma sessão
# paga (ou de um hang em CI), o teste falha alto e barato.
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
if printf '%s\n' "$out" | grep -q '^--- DRY RUN: phase TICKET ---$'; then
  fail "fase com gate satisfeito não aparece na projeção" "sem bloco TICKET" "bloco TICKET impresso"
else
  pass "fase com gate satisfeito (TICKET) não aparece na projeção"
fi

# --- nada é executado, nada muda no disco ----------------------------------
echo "== dry-run não toca no disco =="
assert_eq "árvore de arquivos idêntica antes e depois" "$before" "$after"
assert_eq "working tree continua limpo" "" "$(git status --porcelain)"

# --- OUTPUT_LANG chega ao prompt de boot -----------------------------------
# Ancorado no VALOR da chave, nunca na prosa do prompt: o texto do runner vira inglês no I13.5.3,
# e uma asserção presa à prosa morreria junto. Asserção que só sobrevive ao próprio commit não é
# sensor — é decoração com data de validade.
echo "== OUTPUT_LANG =="
# Reaproveita a projeção de cima: é a MESMA invocação, com a chave ausente do config do fixture.
if printf '%s\n' "$out" | grep -q 'pt-BR'; then
  fail "sem OUTPUT_LANG o prompt não fala de idioma" "nenhuma menção a idioma" "menção a pt-BR"
else
  pass "sem OUTPUT_LANG o prompt não fala de idioma (é o estado de todo repo já instalado)"
fi

echo 'OUTPUT_LANG="pt-BR"' >> .sdd/config.sh
out_lang="$( "$SDD" run "$MISSION" --dry-run 2>&1 )"
if printf '%s\n' "$out_lang" | grep -q 'pt-BR'; then
  pass "com OUTPUT_LANG o prompt de boot carrega o idioma pedido"
else
  fail "com OUTPUT_LANG o prompt de boot carrega o idioma pedido" \
       "prompt citando pt-BR" "prompt sem menção a idioma"
fi
# Restaura o fixture byte a byte: as asserções de working tree limpo mais abaixo dependem disso.
sed -i '/^OUTPUT_LANG=/d' .sdd/config.sh
assert_eq "o fixture volta limpo depois do teste de idioma" "" "$(git status --porcelain)"

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
  "QA:plan=<none>" "$(printf '%s\n' "$out2" | projected)"
# O dry-run imprime o prompt com o prefixo "  │ ", então a âncora inclui a primeira linha do
# bloco — é ali que o slash precisa estar para expandir em headless.
if printf '%s\n' "$out2" | grep -q '│ /qa-report docs/qa'; then
  pass "o prompt de boot começa com o slash literal /qa-report"
else
  fail "boot de QA:plan" "prompt começando com /qa-report" "$(printf '%s\n' "$out2" | grep -m1 '│' || echo vazio)"
fi
# Com charter E relatório fechado, o ciclo avança para o fechamento (sdd-qa). Esta asserção
# existe porque a âncora do "relatório fechado" vivia duplicada no gate e no sub-passo: corrigida
# num lugar só, o gate aceitava e o sub-passo continuava mandando executar — o runner re-rodava
# qa-execution indefinidamente, a US$ 15 por volta. Medido no piloto SQ-97.
mkdir -p docs/qa/charters docs/qa/reports
printf '# CH-um\n' > docs/qa/charters/CH-um.md
printf -- '# QA Run Report\n- **Started:** 2026-01-01T10:00:00Z · **Status:** closed <!-- in-progress | closed -->\n' \
  > docs/qa/reports/2026-01-01-fixture.md
out3="$( "$SDD" run "$MISSION" --dry-run --phase QA 2>&1 )"
assert_eq "com charter e relatório fechado, o sub-passo é close (não re-executa)" \
  "QA:close=sdd-qa" "$(printf '%s\n' "$out3" | projected)"

# E o relatório ainda ABERTO tem que voltar a mandar executar — senão a asserção acima passaria
# por vacuidade, aprovando qualquer coisa.
sed -i 's/\*\*Status:\*\* closed/**Status:** in-progress/' docs/qa/reports/2026-01-01-fixture.md
out4="$( "$SDD" run "$MISSION" --dry-run --phase QA 2>&1 )"
assert_eq "relatório em andamento volta ao sub-passo exec" \
  "QA:exec=<none>" "$(printf '%s\n' "$out4" | projected)"
rm -rf docs/qa/charters docs/qa/reports

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
# O código de saída sozinho não prova que o usuário foi INFORMADO do motivo. Sem esta asserção,
# quebrar a mensagem de escalação passava batido aqui (verificado por mutação: trocar o texto de
# `bad "BLOCKED em EXEC — …"` deixava este arquivo inteiro verde) — e é justamente a mensagem
# que responde "o que acontece se eu rodar isto?", a pergunta que o dry-run existe para responder.
if printf '%s\n' "$out3" | grep -q 'BLOCKED in EXEC'; then
  pass "a projeção EXPLICA a escalação (mensagem 'BLOCKED em EXEC')"
else
  fail "mensagem de escalação do dry-run" "saída contendo 'BLOCKED em EXEC'" \
    "$(printf '%s\n' "$out3" | tail -3 | tr '\n' ' ')"
fi
# O Red do achado: a projeção não pode deixar rastro no disco, nem no caminho de escalação.
# O diário mora em `.sdd/logs/<missão>/` (mudou de lugar em 53cf63a — antes era `$MDIR`, dentro
# da árvore commitada, onde sujava o `git status` e derrubava `gate_REVIEW`). Esta asserção
# precisa apontar para onde o runner ESCREVE hoje: apontada para o caminho velho ela passa a
# ser decoração — verificado por mutação, com o bug do F1 reintroduzido ela continuava verde.
assert_eq "projeção blocked não escreve o pipeline.log" "" \
  "$( [ -e "$PIPELINE_LOG" ] && echo "pipeline.log criado" || true )"
assert_eq "árvore idêntica antes e depois (caminho blocked)" "$before_b" "$after_b"
# ATENÇÃO ao ler esta linha: ela NÃO é o discriminador do F1. `.sdd/logs/` está no `.gitignore`
# que o `sdd install` escreve, então `git status --porcelain` é cego ao `pipeline.log` — com o
# bug do F1 reintroduzido ela continua verde (verificado por mutação). Quem pega o F1 são as
# duas asserções acima. Esta guarda uma coisa diferente e complementar: que a projeção não sujou
# nenhum caminho RASTREADO, que é o que derrubaria `gate_REVIEW` e o `sdd preflight`.
assert_eq "projeção não sujou nenhum arquivo rastreado (caminho blocked)" "" "$(git status --porcelain)"

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

# --- higiene de escopo: nenhuma função lê a `local` do chamador ---------------
# `pstep` é `local` de `run_phase`. Escopo dinâmico do bash faz com que TODA função chamada por
# ela enxergue essa local — então uma outra função referenciar `$pstep` "funciona", mas só por
# coincidência de quem a chama. Sob `set -u`, chamada de qualquer outro lugar, a expansão falha
# DENTRO de um `$( )`: a variável vira vazia, a função retorna 0 e a fase roda sem agente — sem
# erro visível, exatamente o modo de falha silenciosa que este kit existe para impedir.
# Nem `bash -n` nem `shellcheck` pegam isto (o nome ESTÁ atribuído no arquivo, em run_phase),
# por isso o sensor é aqui.
echo "== higiene de escopo do runner =="
offenders="$(awk '
  /^[a-zA-Z_][a-zA-Z0-9_]*\(\)[[:space:]]*\{/ { fn = substr($1, 1, index($1, "(") - 1) }
  /pstep/ && fn != "run_phase" { print fn "():" NR }
' "$ROOT/bin/sdd")"
assert_eq "só run_phase referencia \$pstep (a local do chamador não vaza)" "" "$offenders"

# ---------------------------------------------------------------------------
echo
if [ "$fails" -eq 0 ]; then
  echo "projeção do dry-run correta"
  exit 0
fi
echo "$fails asserção(ões) falharam" >&2
exit 1
