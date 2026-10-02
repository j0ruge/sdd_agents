---
missao: 20261002-onde-o-comando-do-humano-escreve
fase: REVIEW
rodada: 2
status: done
sessao: sdd-reviewer r2 (headless, 2026-10-02)
data: 2026-10-02 17:49
gate: tests/run-all.sh rc 0, suite green em 310 s (1691 linhas ok, anchors 542 de 542) sobre eba1b24; mutante RUN_intervention_claims_unwritten_note pego pelo probe do R1 numa cópia; árvore limpa antes deste commit; nenhum critério parado — Error Handling subiu de B para A pelo fcb5f4e
---

# Review — rodada r2 — Onde o comando do humano escreve

## TL;DR

Revisei o que mudou depois da r1, `29be081..eba1b24`: o conserto `fcb5f4e` (R1) em `bin/sdd`, o probe
novo em `tests/check-autonomy.sh`, o mutante em `tests/check-mutation.sh` e as 44 âncoras
remapeadas no `TODO.md`. O R1 fecha o achado #1: a nota que não foi escrita deixou de ser afirmada.
O mutante que desfaz o conserto é pego pelo motivo certo. Não há achado novo e nenhum `R<n>` novo.
A suíte está verde em 310 s. Nota: A em todos os critérios, contra B em Error Handling na r1.

## Nota da rodada

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | A | O conserto do R1 é uma troca local: a cadeia mktemp/awk/mv virou a condição de um `if`, sem nova definição nem duplicação. A forma do resto da função não mudou. |
| Type Safety | A | Não há tipos em bash. `tmp` continua `local`, e o `else` lê `${tmp:-}`, então um `mktemp` que falha não leva a `rm -f ""` nem a variável sem definição sob `set -u`. |
| Error Handling | A | O achado #1 da r1 está fechado em fcb5f4e. Um `mv` recusado agora avisa `intervention NOT written`, com a linha para escrever à mão, remove o temporário e retorna antes do commit. Medido pelo probe: `fired claimed:0 named:1`. |
| Security | A | O R1 não toca entrada externa nem caminho novo. O shim do probe mora no `OUTSIDE` privado do sensor e entra só pelo `PATH` da invocação. |
| Performance | A | A suíte leva 310 s, contra 305 s na r1. A diferença é ruído, mais o probe novo, que é uma invocação de `sdd retry`. |
| Test Coverage | A | O probe novo segura o mundo do achado, com o marcador `fired` como piso. Reapliquei o mutante do catálogo numa cópia do HEAD e o `check-autonomy.sh` reprovou com `claimed:1 named:0`. O `--anchors` está verde, com 542 de 542. |
| Documentation | A | O comentário do conserto diz por que a falha é dita e cita o achado. O do probe explica por que um `chmod` não serve (root) e para que serve o piso. O drift de README e pipeline continua com a DOCS. |
| **Overall** | **A** | O único achado que pedia conserto fechou com sensor e mutante. Os outros quatro da r1 continuam refutados ou com o humano, com a evidência na r1. |

## Achados da rodada

| # | Severidade | Achado | Onde |
|---|---|---|---|
| — | — | Nenhum achado novo no diff `29be081..eba1b24` | `bin/sdd:487-504` |

## Incrementos de conserto (R<n>)

Nenhum `R<n>` novo nesta rodada.

| R<n> | Achado | Check escrito no checkpoint |
|---|---|---|
| R1 | achado #1 da r1 (já `done` em fcb5f4e, conferido nesta rodada) | `o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    the intervention note never claims a note it could not write' <<< "$o"` → `1` |

## O que virou incremento

- Nada novo nesta rodada.
- Achado #1 da r1 (a nota de intervenção do layout antigo dizia `noted` quando o `mv` falhava): fechado
  em `fcb5f4e` pelo `sdd-executor`. Duas coisas provam o fechamento. (1) A suíte desta rodada traz
  `ok    the intervention note never claims a note it could not write`. (2) Com o
  `RUN_intervention_claims_unwritten_note` aplicado numa cópia do HEAD (o `|| rm -f "$tmp"` de
  volta), o mesmo probe reprova com `expected: fired claimed:0 named:1 notes:1 leftovers:0` e
  `got: fired claimed:1 named:0 notes:1 leftovers:0`. Ele reprova pelo motivo certo: o shim
  disparou nos dois mundos, e só a afirmação mudou.

## O que foi refutado

- **Que o retorno 0 depois do aviso seja uma regressão em relação ao rc 1 de antes do I3.** A r1
  aceitou as duas saídas, "avisa que NÃO escreveu" ou "morre com `error:`". O runner trata a nota
  como registro e não como gate: as falhas de commit e de árvore suja também são `warn` com
  `return 0`. Agora o aviso nomeia a ausência e entrega a linha para escrever à mão. Era só a
  afirmação falsa que o achado pedia para fechar.
- Os achados #2, #3 e #5 da r1 continuam refutados como incremento. O diff da r2 não toca
  `tests/run-all.sh` nem o `cmd_approve`, então a evidência da r1 vale como está.

## Achados fora de escopo

- Nenhum novo.

## Pendências / Decisions for a Human

- **Achado #4 da r1, ainda aberto:** o `sdd close` sem `pr_url:` imprime `merged and spent` sem ter
  conferido merge nenhum. As três saídas estão na r1 e o item está no `TODO.md`. Cabe ao humano
  escolher.
