#!/usr/bin/env bash
# Sensor do sensor: prova que a suíte MEDE alguma coisa.
#
# Sabota o runner numa CÓPIA e exige que a suíte fique VERMELHA. Uma asserção que não pode
# falhar não se distingue de uma que passa — foi assim que três bugs de gate da MESMA família
# atravessaram a suíte verde e só apareceram em uso real, a ~US$ 40 em sessões re-rodadas
# (ver KAIZEN_LOG). Fixture escrito de memória concorda com o gate errado para sempre.
#
# ATENÇÃO: exportar SDD_MUTANT no shell pula shellcheck E mutação na suíte inteira — a
# variável é o mecanismo anti-recursão, não uma opção de usuário.
#
# Uso: tests/check-mutation.sh   (exit 0 = catálogo íntegro e toda mutação não-listada pega)

set -uo pipefail

# Guarda dupla contra recursão: o run-all.sh já não chama este script quando SDD_MUTANT está
# setada. Se chegou aqui com ela setada, a guarda de lá caiu — morrer alto é melhor do que
# forkbombar a máquina de quem rodou a suíte.
if [ -n "${SDD_MUTANT:-}" ]; then
  echo "check-mutation.sh rodando DENTRO de um mutante — a guarda do run-all.sh caiu" >&2
  exit 1
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
JOBS="${SDD_MUTATION_JOBS:-4}"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/sdd-mut-XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

# ---------------------------------------------------------------------------
# Catálogo
#
# Idioma de mutação: achar a linha por uma âncora ÚNICA e mexer só nela. Se a âncora sumir
# num refactor, o `cmp` lá embaixo acusa "não aplicou" em vez de contar ponto — mutação que
# não sabota é a asserção decorativa que este arquivo existe para caçar, um nível acima.
#
# Nome: mut_<GATE>_<slug> para gate, mut_RUN_<slug> para o que não é gate. O `sdd health`
# usa esse prefixo para cobrar uma mutação por gate — mudar a convenção cega o health.
# ---------------------------------------------------------------------------

mut_PLAN_aprovacao_vazia() {  # aceita `aprovacao:` vazia — plano não aprovado vira executável
  sed -i 's/^    auto)          : ;;/    auto)          : ;;\n    "")            : ;;/' "$1"
}

mut_TICKET_sem_sprint() {     # para de exigir `sprint:` — card no backlog é trabalho invisível
  sed -i "s|.*if ! grep -qiE '\^sprint:.*|  if false; then|" "$1"
}

mut_EXEC_done_sem_commit() {  # aceita incremento 'done' com commit '—' — rótulo vira artefato
  sed -i 's|.*\[ "\$commit" = "—" \].*|        if false; then|' "$1"
}

mut_EXEC_commit_orfao() {     # volta ao `cat-file -e`: objeto solto passa por commit da história
  sed -i 's|.*git merge-base --is-ancestor.*|        if false; then|' "$1"
}

mut_EXEC_ignora_TEST_CMD() {  # descarta o rc da suíte — o gate deixa de medir o TEST_CMD
  sed -i 's|.*run_check_cmd "\$TEST_CMD" "gate-exec-test".*|  if false; then|' "$1"
}

# Bug histórico 1 (piloto SQ-97, ~US$ 15/volta): a skill emite
# `- **Started:** <ts> · **Status:** in-progress`, e o gate exigia `**Status:**` ABRINDO a
# linha. Nunca casava; o runner re-rodava qa-execution para sempre.
mut_QA_status_inicio_linha() {
  sed -i "s|.*grep -qE '\^\[\[:space:\]\]\*-\.\*\\\\\*\\\\\*Status.*|  grep -qE '^\\\\*\\\\*Status:\\\\*\\\\*[[:space:]]*closed' \"\$report\"|" "$1"
}

# Enum frouxo: o `closed` tem que vir logo depois de `**Status:**`. Com `.*closed` a legenda
# do template (`<!-- in-progress | closed -->`) casa, e um relatório EM ANDAMENTO passa.
mut_QA_status_enum_frouxo() {
  sed -i "s|.*grep -qE '\^\[\[:space:\]\]\*-\.\*\\\\\*\\\\\*Status.*|  grep -qE '\\\\*\\\\*Status:\\\\*\\\\*.*closed' \"\$report\"|" "$1"
}

# Mesma família, no registry de bugs: com `.*open` a legenda
# `<!-- open | fixed | verified | wont-fix | invalid -->` casa, e um bug `wont-fix` (decisão
# humana, não bloqueia) passa a bloquear a fase.
mut_QA_bug_enum_frouxo() {
  sed -i "s|\[\[:space:\]\]+open'|.*open'|" "$1"
}

mut_QA_matriz_pending() {     # ignora linha 'Pending' na matriz — jornada não andada passa
  sed -i 's|.*Pending\[\[:space:\]\]\*.*|    if false; then|' "$1"
}

mut_QA_bug_open() {           # ignora bug com Status: open no registry
  sed -i 's|.*\[ "\$openbugs" -gt 0 \].*|  if false; then|' "$1"
}

# Bug histórico 3 (piloto SQ-97, ~US$ 10): o parser saía só em `###`, seguia engolindo as
# tabelas seguintes do relatório e reprovava um review todo Grade A por achar a coluna `Commit`.
mut_REVIEW_para_so_em_heading3() {
  sed -i 's|.*inside && /\^#{1,6}\[\[:space:\]\]/ { exit }.*|      inside \&\& /^###[[:space:]]/ { exit }|' "$1"
}

mut_REVIEW_aceita_B() {       # qualquer nota passa — o gate para de exigir Grade A
  sed -i 's|if (grade != "A")|if (grade == "ZZZ")|' "$1"
}

mut_DOCS_status_pendente() {  # aceita área com Status '✗' no checklist de drift
  sed -i 's|.*\[ -n "\$pending_cell" \].*|  if false; then|' "$1"
}

mut_PR_sem_artefato() {       # 50-pr.md ausente deixa de reprovar — missão "completa" sem PR
  sed -i 's|GATE_WHY="missing 50-pr.md"; return 1|GATE_WHY="missing 50-pr.md"; return 0|' "$1"
}

# Não-gate, e o único bug de asserção decorativa que aconteceu de verdade (TODO.md): a guarda
# invertida faz a PROJEÇÃO (`--dry-run`) escrever no diário e o caminho real ficar mudo —
# comando de leitura sujando o working tree, e trilha de auditoria mentindo nas duas direções.
mut_RUN_diario_invertido() {
  sed -i 's|\[ "\$DRY_RUN" = "1" \] && return 0|[ "$DRY_RUN" = "0" ] \&\& return 0|' "$1"
}

# Não-gate: o repo-alvo declara OUTPUT_LANG e o runner engole o pedido em silêncio. É o modo de
# falha típico de chave de config — a chave existe, o schema a promete, e ninguém a lê (a família
# de LINT_CMD/BUILD_CMD/DEV_UP_CMD, congelada na health-baseline). Âncora em código, não em prosa:
# precisa sobreviver ao commit que traduz o bin/sdd.
mut_RUN_ignores_output_lang() {
  sed -i 's|.*if \[ -n "\$OUTPUT_LANG" \]; then.*|  if false; then|' "$1"
}

CATALOGO=(
  PLAN_aprovacao_vazia
  TICKET_sem_sprint
  EXEC_done_sem_commit
  EXEC_commit_orfao
  EXEC_ignora_TEST_CMD
  QA_status_inicio_linha
  QA_status_enum_frouxo
  QA_bug_enum_frouxo
  QA_matriz_pending
  QA_bug_open
  REVIEW_para_so_em_heading3
  REVIEW_aceita_B
  DOCS_status_pendente
  PR_sem_artefato
  RUN_diario_invertido
  RUN_ignores_output_lang
)

# Mutações que HOJE não são pegas, cada uma com o incremento que a fecha. Catraca nas duas
# direções: não-pega fora da lista reprova, e lacuna listada que PASSOU a ser pega também
# reprova (a lista tem que encolher, nunca virar desculpa permanente).
LACUNAS_ESPERADAS=()

# ---------------------------------------------------------------------------
pass()  { printf '  ok    %s\n' "$1"; }
fail()  { printf '  FALHA %s\n         %s\n' "$1" "$2" >&2; }

na_lista() { # na_lista <slug>
  local x
  for x in ${LACUNAS_ESPERADAS[@]+"${LACUNAS_ESPERADAS[@]}"}; do
    [ "$x" = "$1" ] && return 0
  done
  return 1
}

sandbox() { # sandbox <dir-destino> — o kit inteiro que a suíte precisa, e nada além
  mkdir -p "$1"
  cp -r "$ROOT/bin" "$ROOT/tests" "$ROOT/templates" "$ROOT/config" "$1/"
}

# roda_mutante <slug> — escreve $WORK/<slug>.rc e $WORK/<slug>.log
roda_mutante() {
  local slug="$1" box="$WORK/$slug"
  sandbox "$box"
  "mut_$slug" "$box/bin/sdd"
  if cmp -s "$ROOT/bin/sdd" "$box/bin/sdd"; then
    echo "a mutação não aplicou — a âncora mudou no bin/sdd?" > "$box.log"
    echo 90 > "$box.rc"; return
  fi
  if ! bash -n "$box/bin/sdd" 2>"$box.log"; then
    echo "o mutante não é bash válido" >> "$box.log"
    echo 91 > "$box.rc"; return
  fi
  SDD_MUTANT=1 "$box/tests/run-all.sh" > "$box.log" 2>&1
  echo $? > "$box.rc"
}

# ---------------------------------------------------------------------------
# Corrida de CONTROLE — a cópia tem que ficar verde SEM sabotagem nenhuma.
#
# Sem isto, uma cópia quebrada (um teste futuro que leia agents/ ou docs/, por exemplo)
# deixaria TODO mutante vermelho e o placar diria 100% medindo exatamente nada — a mesma
# vacuidade que a mutação existe para pegar, agora no próprio medidor.
# ---------------------------------------------------------------------------
echo "== controle =="
sandbox "$WORK/controle"
if SDD_MUTANT=1 "$WORK/controle/tests/run-all.sh" > "$WORK/controle.log" 2>&1; then
  pass "a cópia do kit fica verde sem sabotagem"
else
  fail "HARNESS-QUEBRADO: a cópia não fica verde nem sem sabotagem" \
       "o placar seria 100% por vacuidade — ver $WORK/controle.log"
  tail -20 "$WORK/controle.log" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
echo "== mutantes (levas de $JOBS) =="
i=0
for slug in "${CATALOGO[@]}"; do
  roda_mutante "$slug" &
  i=$((i + 1))
  [ $((i % JOBS)) -eq 0 ] && wait
done
wait

pegas=0; lacunas=0; erros=0
for slug in "${CATALOGO[@]}"; do
  rc="$(cat "$WORK/$slug.rc" 2>/dev/null || echo 99)"
  case "$rc" in
    90|91)
      fail "CATALOGO-QUEBRADO: $slug" "$(cat "$WORK/$slug.log")"; erros=$((erros + 1)) ;;
    0)
      # A suíte ficou VERDE com o runner sabotado: ninguém mede esta sabotagem.
      if na_lista "$slug"; then
        printf '  aviso %s — lacuna conhecida, a suíte não pega (ainda)\n' "$slug"
        lacunas=$((lacunas + 1))
      else
        fail "$slug NÃO é pega" "a suíte ficou verde com o runner sabotado — falta asserção"
        erros=$((erros + 1))
      fi ;;
    99)
      fail "$slug não produziu resultado" "o mutante morreu antes de escrever o rc"
      erros=$((erros + 1)) ;;
    *)
      if na_lista "$slug"; then
        fail "$slug está em LACUNAS_ESPERADAS mas JÁ é pega" \
             "lacuna fechada — remova da lista, senão ela vira desculpa permanente"
        erros=$((erros + 1))
      else
        pass "$slug — a suíte morre (rc $rc)"
        pegas=$((pegas + 1))
      fi ;;
  esac
done

echo
printf 'score: %d pegas, %d lacunas conhecidas, de %d\n' "$pegas" "$lacunas" "${#CATALOGO[@]}"
if [ "$erros" -eq 0 ]; then exit 0; fi
printf '%d problema(s) no catálogo\n' "$erros" >&2
exit 1
