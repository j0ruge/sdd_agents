---
missao: 20261121-l5-saida-humana-e-contrato-do-runner
fase: REVIEW
rodada: 6
status: done
sessao: 01a218ab-0afe-76d3-9c10-df8a5f49c407
data: 2026-11-26 13:42
gate: "tests/run-all.sh em 2ab5f3469f61c2db62bbd83d4f86a7d804274c8b deu rc 0, 21 etapas, 2496 linhas ok, 0 linhas FAIL, 1117 s, suite green. R7 1 1, controles R6 1 1 1. REVIEW não fecha. Performance regrediu de A para B e Test Coverage segue B. R8 pending. Na entrada só as 262 inserções locais de checkpoint-notas.md, preservadas fora do commit."
reviewed_head: 2ab5f3469f61c2db62bbd83d4f86a7d804274c8b
---

# Review — rodada r6 — L5 — saída humana e contrato do runner

## TL;DR

O R7 fechou a troca de provas entre parágrafos. O delta trouxe uma regressão de
desempenho: um backlog válido de cerca de 1 MB, quase todo de linhas vazias,
fez o leitor e o `sdd close` excederem 10 s. O achado virou R8. Esta revisão
não alterou código.

## Nota da rodada

**Escopo.** `codereview:codereview base=1591328ec9e1558c413838e1f8540a2d7518a6cd`,
até `2ab5f3469f61c2db62bbd83d4f86a7d804274c8b`. Cinco commits, nove arquivos
analisados, 341 inserções e 27 remoções. As notas append-only ficaram fora do
conteúdo da análise, conforme o boot. Dois verificadores leram 20 unidades de
prosa em seis arquivos. A nota de documentação cobre essas unidades e o
confronto com a r5, lida como fonte dos achados anteriores.

**Segredos — PASS.** As passadas regex e gitleaks leram nove arquivos e 341 linhas
adicionadas. Zero achados e zero erros. O delta não altera autoridade, provas
Git ou escrita no backlog pelo fechamento.

**Cobertura.** `tests/check-todo.sh` é o leitor e traz o selftest de saída TSV.
`tests/check-gates.sh` chama a CLI e exige título, linha, prova e preservação
do backlog. R7 mede quebra simples, linha vazia, fronteira só com espaços e
tab, frase e registro partidos, valor inválido e acumulação de hashes. Não
exerce o custo de sequências longas de linhas vazias. A suíte desta rodada
foi `tests/run-all.sh`, no SHA acima. Foram 21 etapas e 2496 linhas `ok`, com 0 linhas `FAIL`. O comando terminou com rc 0 em 1117 s. Saída e código estão em `/tmp/sdd-l5-review-r6.tEsKk8/suite.log` e `/tmp/sdd-l5-review-r6.tEsKk8/suite.rc`.

**Documentação.** O [README](../../../README.md) agora limita a sessão paga
à issue ainda aberta com JIRA habilitado. O [guia do pipeline](../../pipeline.md#after-the-pr)
distingue quebra simples de linha em branco e mantém a exigência da prova
Git. A catraca em `tests/health-baseline.txt` mede 98. O comando
`bash tests/check-todo.sh --anchors TODO.md` confirmou 98 âncoras, zero fora
do alvo.

**Código morto.** Varredura inline do delta. `paragraphs`, `n` e `i` são
locais e usados no leitor. `CLOSE_FIXTURE_DATE` alimenta a fixture. A mudança
não removeu o último consumidor de nenhum símbolo. Varredura de dívida
preexistente não solicitada.

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | A | O recorte por parágrafo conserva a classificação de exemplos e provas e não duplica o leitor. O custo da acumulação está avaliado em Performance. |
| Type Safety | A | O array de parágrafos é local, o índice fica dentro da contagem de split e o resultado conserva linha, hashes e título no mesmo formato TSV. |
| Error Handling | A | Um token malformado continua excluindo o item inteiro. O fechamento só lista uma prova quando a ancestralidade é confirmada. |
| Security | A | Nenhuma credencial detectada, prova Git intacta e backlog preservado byte a byte na CLI. |
| Performance | B | Só inserir linhas vazias em um backlog aceito elevou o leitor de 0,51 s para mais de 10 s e atrasou a listagem do fechamento. |
| Test Coverage | B | Os sensores provaram o R7 nos dois caminhos, mas nenhum tornou vermelha a regressão de custo do R8. |
| Documentation | A | O guia rápido acompanha a CLI, o guia do pipeline distingue as fronteiras testadas e as medidas dos dois sensores foram confrontadas. |
| **Overall** | **B** | O R7 fecha funcionalmente. O R8 é uma regressão reproduzida em entrada válida e impede o selo da revisão. |

## Achados da rodada

| # | Severidade | Achado | Onde |
|---|---|---|---|
| 1 | LOW | Cada linha vazia alonga o corpo acumulado e produz em seguida campos de parágrafo vazios. Em um backlog válido de 1 MB, isso atrasa a listagem pós-merge. | `tests/check-todo.sh:835`, `:536` |

**Reprodução.** Em `2ab5f3469f61c2db62bbd83d4f86a7d804274c8b`,
`bash /tmp/sdd-l5-review-r6.tEsKk8/repro-blank-run.sh "$PWD"` cria um Git
descartável, sem upstream, PR ou JIRA. Um único item usa um hash ancestral de
`main`. A variante muda apenas o número de linhas vazias após a atribuição,
antes de `## Decided`. `bash tests/check-todo.sh --check <backlog>` aceitou
as duas variantes. `git merge-base --is-ancestor <hash> main` deu rc 0 e
`cmp` confirmou os mesmos bytes após cada chamada da CLI.

| Entrada | Leitor em `1591328` | Leitor no HEAD | `sdd close` no HEAD |
|---|---|---|---|
| 1 linha vazia, 212 bytes | rc 0 em 0,03 s | rc 0 em 0,04 s | rc 0 em 0,16 s, listou a prova |
| 1.000.000 de linhas vazias, 1.000.211 bytes | rc 0 em 0,51 s, mesma linha TSV | rc 124 no limite de 10 s | rc 124 no limite de 10 s, sem chegar à lista |

O rc 124 vem do `timeout` da reprodução. Em uma repetição com teto de 60 s, a CLI terminou com rc 0 em 25,30 s, listou a mesma prova e manteve os bytes.
O custo sobe no leitor, não no Git. Os TSVs de 250 mil e 500 mil linhas
preservam a saída do leitor, mas não os tempos. A r7 confirmou essa lacuna.
A severidade é LOW porque o caso comprovado com medição exige uma sequência
atípica de linhas vazias, que representa uma só fronteira.

## Incrementos de conserto (R<n>)

| R<n> | Achado | Check escrito no checkpoint |
|---|---|---|
| R8 | Achado 1 da r6 | `t=$(bash tests/check-todo.sh --selftest 2>&1); g=$(bash tests/check-gates.sh 2>&1); echo "$(grep -c '^  ok    rule: --resolved bounds work on consecutive blank lines' <<< "$t") $(grep -c '^  ok    sdd close lists the same proof after consecutive blank TODO lines$' <<< "$g")"` → `1 1` |

Check R8 no HEAD, pelos dois marcadores da suíte, → `0 0`.

## O que virou incremento

| R8 | Achado 1 da r6 — processar sequências de linhas vazias sem atrasar a listagem de provas | `t=$(bash tests/check-todo.sh --selftest 2>&1); g=$(bash tests/check-gates.sh 2>&1); echo "$(grep -c '^  ok    rule: --resolved bounds work on consecutive blank lines' <<< "$t") $(grep -c '^  ok    sdd close lists the same proof after consecutive blank TODO lines$' <<< "$g")"` → `1 1` | pending | — |

- **R8.** Crie o vermelho no selftest e na CLI com duas entradas equivalentes,
  uma com uma linha vazia e outra com uma sequência longa. Exija a mesma prova,
  com linha, hash e título, e o backlog byte a byte intacto. Use um limite
  amplo e reprodutível para a fixture. Preserve os negativos do R7 e um
  caso em que várias linhas vazias de fato separam dois parágrafos.
- **R7 da r5**, fechado pelo executor em `a3518ea`. Em
  `bash /tmp/sdd-l5-review-r6.tEsKk8/repro-r7.sh "$PWD"`, a versão anterior
  lista o exemplo e omite a prova do segundo parágrafo. No HEAD, o leitor
  e a CLI listam as provas nas linhas 4, 10 e 17, omitem os dois exemplos
  e preservam o backlog (`cmp` rc 0). O mesmo TSV saiu em LF e CRLF.
  R7 `1 1` e R6 `1 1 1` na suíte desta rodada.
- **README da r5**, corrigido em `d21723f`. O texto antigo não aparece mais
  na entrada do guia rápido. `./bin/sdd help` descreve atualizar a base,
  listar a limpeza do backlog e fechar JIRA quando habilitado. O registro
  fica no backlog com `RESOLVED by d21723f` até o pós-merge.

## O que foi refutado

- **As medidas antigas do R7 estariam sem evidência.** Os logs
  `/tmp/l5-r7-suite.qzp0el`, `/tmp/l5-r7-red-todo.JeL9fM` e
  `/tmp/l5-r7-red-close.bAAF4w` mostram 21 etapas, 2496 linhas `ok`,
  zero `FAIL` no verde e os dois vermelhos com a saída errada. O arquivo
  `/tmp/l5-r7-mutation-results.YOi8oc` contém nove resultados com rc 92.
  A duração histórica e a árvore de entrada do EXEC não são medições desta
  rodada. “Nenhum achado novo no R7” descreve o que o EXEC registrou, não
  uma garantia de que a revisão seguinte não encontraria nada.
- **O delta perdeu resoluções da missão ou alterou a gramática TSV.**
  `python -B /tmp/sdd-l5-r5-review.yE8XIE/i18.py` confirmou 17 de 17
  títulos com os hashes exatos. Comparar o leitor do HEAD sobre os dois
  backlogs com `cut -f2-` mostrou só a entrada do README, de 20 para 21
  registros. As provas não foram substituídas.

## Achados fora de escopo

- A expressão histórica de I18 continua registrada no [backlog](../../../TODO.md)
  e ficou fora do delta de código. Com a mesma base `a6fff8e9`, as contagens
  foram 2 na base, 19 em `269ecc7`, 20 em `1591328` e 21 no HEAD. A diferença
  global passou por 17, 18 e 19, sem perda dos 17 itens planejados. É o mesmo
  achado da r5, já registrado para esta missão, sem recorrência duplicada.
  Nenhum item de backlog ou baseline novo nesta rodada.

## Pendências / Decisions for a Human

Nenhuma decisão de produto nova. Comparada com a r5, Code Quality (Zen) e
Documentation subiram de B para A, Test Coverage ficou em B e Performance
caiu de A para B. A regressão está no delta de código e fica indicada no
`gate`. Não há nova revisão sobre o mesmo código. Permanecem as pendências
de aceite no [documento da missão](00-missao.md#pendências-para-o-humano).

## Boot da próxima fase

Comece pelo R8 no [checkpoint](checkpoint.md). Faça o leitor e a CLI
reproduzirem o caso das linhas vazias sem reabrir o escopo de I18. Preserve
os dois marcadores de R7 e os três controles de R6. A próxima REVIEW delta
parte do `reviewed_head` desta rodada. O único caminho sujo na entrada era
`checkpoint-notas.md`, com 262 inserções locais. Elas ficaram fora do índice,
que recebeu apenas a nota desta rodada.

### Ações recomendadas

- **CRITICAL** — nenhuma.
- **HIGH** — nenhuma.
- **MEDIUM/LOW** — fechar R8 com a equivalência de saída e o limite do ensaio, preservando R7.
- **Prosa** — nenhuma nova.
- **Fora de escopo** — manter a evolução da contagem histórica no registro de I18.

_Pegada de custo — codereview 2.27.38 no caminho solicitado, com os passos
de verificação da instalada 2.30.2. Dois verificadores gpt-6.1-terra,
9 chamadas por verificador, análise dos dois arquivos de código e varredura
inline. Custo monetário não aferido._
