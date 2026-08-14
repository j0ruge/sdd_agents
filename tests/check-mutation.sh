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

mut_PLAN_aprovacao_vazia() {  # gate_PLAN passa a aceitar `aprovacao:` vazia
  sed -i 's/^    auto)          : ;;/    auto)          : ;;\n    "")            : ;;/' "$1"
}

CATALOGO=(PLAN_aprovacao_vazia)

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
