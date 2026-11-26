---
missao: 20261121-l5-saida-humana-e-contrato-do-runner
fase: REVIEW
rodada: 8
status: done
sessao: 01a2190e-5972-7c60-847a-2558a6cd0789
data: 2026-11-26 15:24
gate: "tests/run-all.sh em 178bf75ac475f7ec9795769efc235141d0f85ac9 deu rc 0, suite green, 21 etapas, 2498 linhas ok, 0 linhas FAIL e 744 s. Checks R8 1 1, R7 1 1 e R6 1 1 1. Os dois achados de prosa da r7 fecharam em dfd2197. Todos os critérios em A, sem R9. Na entrada, só checkpoint-notas.md tinha alterações locais, com 264 inserções fora do índice."
reviewed_head: 178bf75ac475f7ec9795769efc235141d0f85ac9
---

# Review — rodada r8 — L5 — saída humana e contrato do runner

## TL;DR

O delta confirmou os dois ajustes de prosa da r7. O handoff agora conta
26 incrementos e a r6 conserva só os tempos comprovados. Nenhum código mudou.
A suíte passou, todos os critérios ficaram em A e não há R9.

## Nota da rodada

**Escopo.** `/codereview:codereview base=7824ed81f6c0fdb4e0cca7d352e2c89a128cce86` em
`178bf75ac475f7ec9795769efc235141d0f85ac9`. A base é ancestral do HEAD. Os três commits do delta alteraram
quatro artefatos da missão com conteúdo revisável, dois registros do backlog,
a catraca e uma linha de notas. O conteúdo de `checkpoint-notas.md` ficou fora
da leitura. O diff de `bin/`, `tests/*.sh`, `config/` e `templates/` está vazio.
Não houve interface renomeada. A QA em [`30-handoff-qa.md`](30-handoff-qa.md)
já percorreu a CLI em Git descartável e confirmou que o fechamento manteve os
bytes do backlog. Sem app, PR ou JIRA real nesta rodada.

### Segredos

| Estado | Ferramentas | Arquivos | Linhas adicionadas | Achados | Erros |
|---|---|---|---|---|---|
| PASS | regex, gitleaks | 7 | 183 | 0 | 0 |

A pré-varredura usou `git -P diff 7824ed81f6c0fdb4e0cca7d352e2c89a128cce86...178bf75ac475f7ec9795769efc235141d0f85ac9 --unified=0` na entrada de `scan_secrets.sh`.

### Cobertura, integridade e código morto

| Superfície | Resultado |
|---|---|
| Código Bash | Nenhum arquivo executável mudou no delta. Continuam válidos os oráculos do leitor e da CLI que a r7 verificou. |
| Suíte | `tests/run-all.sh` em `178bf75ac475f7ec9795769efc235141d0f85ac9` deu rc 0, 21 etapas, 2498 linhas `ok` e 0 `FAIL` em 744 s, com `suite green`. Saída, rc e duração em `/tmp/sdd-l5-review-r8.QFWci9Sc/suite.log`, `suite.rc` e `suite.seconds`. |
| Checkpoint | `bash tests/check-checkpoint.sh --check docs/handoffs/20261121-l5-saida-humana-e-contrato-do-runner/checkpoint.md` confirmou 26 linhas, 25 sob a regra de âncora e nenhuma cega. A tabela tem 26 `done` e nenhuma linha pendente. |
| Backlog e catraca | `bash tests/check-todo.sh --count TODO.md` deu 100, igual a `todo-findings`. `--check` aceitou os 100 registros e `--anchors` encontrou zero fora do alvo. `--resolved` foi de 21 para 23 no delta. |
| Documentação | Dois verificadores leram 68 unidades. As unidades dos dois achados anteriores foram tocadas em `dfd2197`. O fechamento foi verificado abaixo. |
| Código morto | Varredura inline restrita ao delta. A catraca mudou um inteiro e nenhuma definição, chamada ou dependência foi adicionada ou removida. Dívida anterior não faz parte da rodada. |

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | A | O delta não adiciona nem remove definições, chamadas ou dependências. A única mudança em dado da suíte é a contagem aferida da catraca. |
| Type Safety | A | Os contratos Bash não mudaram. As 26 linhas mantêm os mesmos status e hashes e os dois registros novos respeitam a forma do backlog. |
| Error Handling | A | Nenhum caminho de erro mudou. Os sensores do R8 continuam exigindo prazo, prova positiva e backlog intacto no leitor e na CLI. |
| Security | A | Regex e gitleaks leram as adições dos sete caminhos e não reportaram achados nem erros. |
| Performance | A | O código medido na r7 está intacto. Naquela reprodução, leitor e CLI levaram 0,53 s e 0,74 s com um milhão de linhas vazias. Os dois sensores do R8 passaram nesta rodada. |
| Test Coverage | A | A suíte passou em 21 etapas. Os oráculos do R8 deram 1 1, os do R7 deram 1 1 e os do R6 deram 1 1 1. |
| Documentation | A | O handoff bate com as 26 linhas da tabela e a r6 retirou os quatro tempos sem registro. Os dois fechamentos ligam aos artefatos e ao commit que os corrigiu. |
| **Overall** | **A** | Os dois achados da r7 fecharam em um commit de documentação verificável. A suíte passou e não surgiu achado novo no delta. |

## Achados da rodada

Nenhum achado novo confirmado. Os dois achados da r7 ficaram sanados.

## Incrementos de conserto (R<n>)

Nenhum. A rodada não alterou código nem acrescentou linhas ao checkpoint.

## O que virou incremento

- **r7 #1, contagem do handoff** — fechado em `dfd2197a91d9cffa9a41b60e9e1e258065f45165`.
  A coluna `Status` de `checkpoint.md` tem 26 `done` nos dois extremos do
  delta. Em `7824ed8`, o handoff dizia 25. No HEAD, a
  [linha do inventário](20-handoff-exec.md#artefatos) diz 26 até o R8.
- **r7 #2, tempos sem saída registrada** — fechado no mesmo commit.
  `git diff 7824ed81f6c0fdb4e0cca7d352e2c89a128cce86 178bf75ac475f7ec9795769efc235141d0f85ac9 -- docs/handoffs/20261121-l5-saida-humana-e-contrato-do-runner/40-review-r6.md`
  mostra a retirada dos quatro valores de 250 mil e 500 mil linhas.
  `wc -l /tmp/sdd-l5-review-r6.tEsKk8/perf-{250000,500000}.md.{after,before}`
  dá três linhas por arquivo, todas TSV, sem os tempos. O caso de um milhão
  permanece comprovado em `repro-blank-run.log` e `blank-run-full.seconds`
  no mesmo diretório. O comparativo do R8 na [r7](40-review-r7.md#o-que-virou-incremento)
  também conserva as medidas de 0,53 s e 0,74 s.
- **R8 da r6** — fechado em `2defd6334fef3c06a4c377887748a7c425f2e50a`.
  O código não mudou desde o reteste independente da r7. Os dois marcadores
  ancorados do Check aparecem exatamente uma vez no log desta rodada
  (`1 1`). Os controles de R7 e R6 deram `1 1` e `1 1 1`.
- `178bf75` marcou no backlog os dois ajustes com `RESOLVED by dfd2197`.
  O diff da saída de `bash tests/check-todo.sh --resolved` sobre os dois blobs
  de `TODO.md` contém só esses dois registros a mais. Os 21 anteriores ficaram idênticos.
  Contagens e diff em `/tmp/sdd-l5-review-r8.QFWci9Sc/evidence.log`.

## O que foi refutado

- **O inventário ainda diria 25 segundo `TODO.md:851`.** O registro já
  trazia a descrição do defeito em `8310b12`. O token de resolução acrescentado
  em `178bf75` marca o conserto, conforme o [contrato do backlog](../../../templates/todo.md).
  A leitura em 25 vale no SHA revisado na r7 e a leitura em 26 vale após
  `dfd2197`. Não há defeito atual a reabrir.
- **Os zeros da r7 não seriam verificáveis.** A pré-varredura reproduzida
  sobre `2ab5f3469f61c2db62bbd83d4f86a7d804274c8b...7824ed81f6c0fdb4e0cca7d352e2c89a128cce86`,
  sem o arquivo de notas, devolveu arrays vazios de achados e erros nas duas
  ferramentas. É uma reprodução, não a saída histórica
  (`/tmp/sdd-l5-review-r8.QFWci9Sc/r7-prescan-reproduzida.json`).
  Para a suíte histórica, `awk '/^  FAIL/{n++} END{print n+0}'`
  sobre `/tmp/sdd-l5-review-r7.AhVXIfxz/suite.log` deu zero. A contagem
  é verificável na própria saída preservada
  (`/tmp/sdd-l5-review-r8.QFWci9Sc/r7-suite-contagem.log`).
- **A inspeção de código morto da r7 teria perdido a saída de um sensor.**
  A r7 diz que a inspeção foi inline, limitada à existência de funções,
  interfaces e chamadores órfãos no delta daquela rodada. Não atribui a
  conclusão a um sensor nem a uma contagem automatizada. Nesta rodada,
  o diff de executáveis vazio confirma que os ajustes de prosa e catraca
  não introduziram novos órfãos.

## Achados fora de escopo

- O [registro existente do Check histórico de I18](../../../TODO.md)
  continua aberto. O Check usa a contagem global contra `git merge-base HEAD origin/main`.
  Com a mesma base `a6fff8e`, passou de 19 em `7824ed8` para 21 em `178bf75`
  pelos dois ajustes de prosa. `a033008` continua sendo a evidência histórica
  dos 17 marcadores da missão. Sem novo item nem recorrência da mesma missão.

## Pendências / Decisions for a Human

Nenhuma decisão nova. Documentation e Overall passaram de B para A,
sustentados pelo conserto em `dfd2197`. Os seis critérios estritos
permaneceram em A. Ficam as [pendências de aceite da missão](00-missao.md#pendências-para-o-humano).

## Boot da próxima fase

O relatório satisfaz o piso A. Após o runner validar o gate, DOCS pode usar o
[documento da missão](00-missao.md#métrica) para o registro de entrega e custo.
Use a [QA](30-handoff-qa.md) e o [comparativo da r7](40-review-r7.md#o-que-virou-incremento)
como evidência histórica. Não repita como atuais os tempos sem registro nem
use a contagem global do I18 como medida dos 17 títulos. Preserve as
pendências para o dono e deixe a remoção dos itens para o pós-merge.

Na entrada, só `checkpoint-notas.md` tinha alterações, com 264 inserções
locais e índice vazio. O commit desta rodada inclui apenas a nota nova
desse arquivo. As 264 inserções ficaram fora do índice. Nenhum código,
backup ou mutante entrou no commit. Se código reabrir REVIEW, use o
`reviewed_head` desta rodada como base.

### Ações recomendadas

- **CRITICAL** — nenhuma.
- **HIGH** — nenhuma.
- **MEDIUM/LOW** — nenhuma.
- **Prosa adiada** — nenhuma.
- **Fora de escopo** — manter I18 no item existente do backlog.

_Pegada de custo — codereview local 2.27.38, com a verificação da instalada 2.30.2
(escopo por unidades e regra de fechamento). Dois verificadores gpt-6.1-terra,
68 unidades, 16 e 77 chamadas autorreportadas. Sem agentes por arquivo ou
leitura integral pelos verificadores. Catraca e varredura do delta inline.
Custo monetário não aferido._
