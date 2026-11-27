---
missao: 20261126-l5b-o-worker-e-os-verbos-dele
fase: REVIEW
rodada: 1
status: done
sessao: 01a21e00-8322-7943-b6fa-e4c2d8e2812d
data: 2026-11-27 14:33
gate: tests/run-all.sh em 27c94acb55c18b785db213b2aed3f45ecacce5f1 → rc 0, suite green, 21 etapas, 101 sondas do worker, 100 âncoras do backlog e 1.017 do catálogo. Árvore limpa no teste. Checks F1 e F2 → 1 cada. R1–R4 pending, REVIEW não passou.
reviewed_head: 27c94acb55c18b785db213b2aed3f45ecacce5f1
---

# Review — rodada r1 — O worker e os verbos dele

## TL;DR

A revisão FULL de `8a56249...27c94ac` confirmou cinco achados, reunidos em quatro incrementos para EXEC.
A suíte e os dois retestes de QA passaram, mas a jornada simulada publicou `local/ci` verde sem testar.
O relay foi iniciado sem acesso indicado à fila canônica e também aceitou uma referência local vencida.
A rodada não alterou código nem usou GitHub real.

## Nota da rodada

Escopo integral da L5b sobre a base integrada `8a56249f16143c1446e13751af36708ce7e5b064` do PR #518,
ancestral comum de `origin/main` com o head revisado. São 38 commits e 30 caminhos no inventário.
A análise de conteúdo usa 28 caminhos. Para a nota append-only e o handoff de QA, só foram usadas as
seções e as entradas fornecidas no boot. A análise cobriu o runner, o worker, o helper de antecipação,
o procedimento executável em Markdown, os sensores e os contratos operacionais alterados.
A comparação é contra a base da missão, sem reavaliar a L5 já integrada.

### Detecção de segredos

| Caminhos lidos | Linhas adicionadas | Scanners | Achados | Erros |
|---:|---:|---|---:|---:|
| 28 | 3.747 | regex e gitleaks | 0 | 0 |

### Síntese da revisão

- A separação entre produtor de `local/ci` e consumidor por SHA é clara. O alcance fica incorreto
  quando a execução do teste é inferida do status de um subshell que também carrega o config.
- A reserva com lock é localizada e a retomada preserva uma identidade. A fonte do escopo e a
  fonte da autoridade de antecipar são entradas diferentes. A primeira não chega ao planner e a
  segunda é reduzida à existência de um arquivo no caso local.
- As fixtures exercitam a interface do CLI e os blocos do runbook, não só a presença de texto.
  A revisão repetiu `tests/check-worker-ahead.py` com `e2e/check-worker-lookahead-race.py` (F1) e
  `e2e/check-worker-review-probe.py` (F2), ambos com Check `1` no head revisado.
- A disposição local dos 18 pares foi comprovada cruzando as decisões da missão, os títulos do
  backlog na base integrada e os `RESOLVED by` no head. Todos os hashes citados são ancestrais.
  Esta rodada não consultou um PR remoto da L5b. A publicação das escolhas, disposições e evidência
  no head remoto é verificação futura do ato de PR/review, não resultado desta rodada.

### Cobertura e sincronização

| Superfície | Sonda exercitada | Limite observado |
|---|---|---|
| `bin/sdd` | `tests/check-codex-runner.sh` e `tests/check-autonomy.sh` na suíte integral | Modelo e ledger simulados. |
| `bin/sdd-worker` | `tests/check-worker.sh` e reprodução pelo CLI | Os controles passaram. As lacunas reproduzidas estão em R1 e R4. |
| `bin/sdd-worker-ahead` | `tests/check-worker-ahead.py` e regressão concorrente F1 | A fixture padrão simula o relay. R2 e R3 exigem capturar a entrada real do relay com adaptador falso. |
| Blocos de `commands/sdd-worker.md` | Caminhos de lançamento, escopo, merge e pós-merge pela suíte | As chamadas remotas são simuladas. F2 volta a medir a seleção do delta. |

O `README.md` registra a exigência de inventário NUL. `config/schema.md` e o template da
delegação distinguem a mudança de teto em Claude da reinvocação Codex. A ADR 0027 e
`docs/pipeline.md` documentam quem publica a suíte e sob quais condições o plano é antecipado.

### Disposições dos 18 pares

| Issues | Evidência local |
|---|---|
| #419 | I8 `6ed4ddc` e I9 `2d81fe7`. O produtor e o bloqueio existem, com contraexemplos nesta rodada. |
| #420 | I9 `2d81fe7`. Threads tratados com evidência, com uma falha de validação no lote R4. |
| #421 | I3 `1af340a`. Gasto histórico com identificação da campanha. |
| #424 e #425 | I7 `f7b8071`. Sondas distinguem ancestralidade, nota e árvore suja. |
| #427 e #428 | I2 `d1e8d0f`. Valor exportado e validade relida no ato. |
| #429 | I1 `064098e`. Inventário NUL e recusa de leitura parcial. |
| #430 | I6 `9ce1943`. O PR próprio continua visível depois da primeira página de forks. |
| #431 e #474 | I10 `4edda89`. Aceite e escolhas são testados contra o head e o corpo. |
| #432 e #448 | I12 `f3b4056`. Retomada do PR de acompanhamento e alteração assinada da fila. |
| #433 e #478 | I5 `d7ca654`. O diagnóstico original distingue teto de fase e de missão. |
| #434 | I4 `ac581c8`. Revalidação do teto e interrupção quando o config Codex muda. |
| #473 | I11 `20ffaab` e sensor F2 `9837b00`. Delta sem integração antecipada e nova seleção depois do conflito. |
| #477 | I13 `2e8bd53`. Um lançamento autorizado passa pelo preflight. |

### Código morto

A varredura de símbolos introduzidos ou órfãos usou busca de referências e não encontrou remoção
justificada. A varredura dos símbolos preexistentes não foi pedida.

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | B | A passagem do escopo canônico ao planner é implícita e a classificação do corpo confunde aprovação simples com achado. |
| Type Safety | B | O leitor GraphQL admite metadados de comentários incompatíveis com o próprio inventário de revisão. |
| Error Handling | B | O retorno antecipado do config é publicado como resultado da suíte e a referência local vencida não muda o despacho. |
| Security | B | Uma publicação verde sem suíte libera a prontidão e um pedido local não recuperável admite a antecipação delegada. |
| Performance | A | As consultas paginadas do PR e a exclusão por reserva preservam a leitura necessária sem abrir um segundo relay no reteste. |
| Test Coverage | B | A suíte passou, mas as sondas não distinguem os cinco contraexemplos reproduzidos nesta rodada. |
| Documentation | A | Plano, ADR e runbook dão o contrato de escopo, autorização e evidência. As divergências observadas são de execução. |
| **Overall** | **B** | Os fluxos principais passaram, com três falhas de integridade em caminhos de entrada e dois defeitos no tratamento da revisão. |

## Achados da rodada

| # | Severidade | Achado | Onde |
|---|---|---|---|
| 1 | HIGH | `review-ci` pode publicar êxito sem iniciar `TEST_CMD`, liberando `pr-ready` no mesmo SHA. | `bin/sdd-worker:1589–1609` |
| 2 | HIGH | A fila canônica não chega ao primeiro turno do planner antecipado quando só existe no primário. | `bin/sdd-worker-ahead:199–200`, `bin/sdd-plan-codex:99–118` |
| 3 | HIGH | Um handoff que aponta para uma seção local inexistente ainda dispara o relay. | `bin/sdd-worker-ahead:60–74`, `bin/sdd-worker-ahead:192–200` |
| 4 | MEDIUM | Confirmação humana simples em português é tratada como achado e bloqueia o merge. | `bin/sdd-worker:1635–1637`, `bin/sdd-worker:1742–1748` |
| 5 | LOW | Metadados de thread resolvida que tornam o inventário ilegível ainda permitem `ready`. | `bin/sdd-worker:1659–1668`, `bin/sdd-worker:1755–1760` |

### Reprodução

**#1.** Em um repositório descartável derivado da fixture de `tests/check-worker.sh:1722`, usei o
produtor `review-ci` e o consumidor `pr-ready` reais, com as respostas do GitHub simuladas.
Mantive `TEST_CMD='bash src/test-ci.sh'`, que registra cada execução, e só acrescentei
`exit 0` ao config versionado. Com a fixture armada para a suíte falhar, o caso com saída
antecipada registrou `pending,success`, zero execuções e `pr-ready` respondeu `ready` com
rc 0. Sem essa saída, a mesma suíte rodou uma vez, publicou `failure` e bloqueou. O controle
verde rodou uma vez e passou. Cada caso partiu sem status no SHA testado.
O rc do subshell não distingue a saída do config da saída do teste.

**#2.** Extraí o bloco público de despacho de `commands/sdd-worker.md:342`. Num Git local descartável,
a fila com o conteúdo exclusivo do lote L2 existia somente no checkout primário. O predecessor
estava vivo com ownership simulado e o relay real rodou com um adaptador que só capturava a
entrada. Houve um turno no checkout do sucessor. O prompt incluía o ID da campanha e `L2`,
mas não o caminho da fila canônica nem seu conteúdo, e o arquivo não existia no checkout
do sucessor. A CLI recebeu `--campaign` corretamente. O relay só usa esse dado para os checks
e o identificador em frontmatter. Não se atribuiu uma resposta ou um plano errado ao modelo.

**#3.** No mesmo arranjo, apontei `ahead-request` para um arquivo existente com fragmento `#pedido`.
A seção havia desaparecido e o texto restante dizia para não antecipar. Mesmo assim houve
um turno. Repeti com a seção presente na primeira leitura e retirada pela fixture durante
`budget`, sem alterar o handoff. Houve um turno também. Quando removi o arquivo inteiro antes
do despacho, houve zero turnos. A segunda leitura compara a mesma referência textual, mas não
verifica se o fragmento ainda recupera a instrução original.

**#4.** Na fixture de `pr-ready`, todos os outros requisitos verdes e o mesmo autor, commit e estado
`APPROVED`, `LGTM.` retornou `ready` e `Aprovado.` retornou rc 1 com
`not-ready findings: review 23 has no verified disposition`. A aprovação com uma correção pedida
também bloqueou, assim como `CHANGES_REQUESTED` sem texto, no ramo próprio. O tratamento de
`User` não aceita disposição local, então o ato não consegue corrigir esse falso bloqueio.
O teste deve preservar o bloqueio da mensagem que realmente pede correção.

**#5.** Com a mesma fixture de PR, entreguei `isResolved: true` e `comments: 17` numa thread sem
disposição local. O inventário `review-findings` falhou com rc 3 e o diagnóstico do jq
`Cannot index number with string "nodes"`. `pr-ready` retornou `ready` no mesmo SHA com a
mesma resposta. O defeito confirmado é aceitar o campo presente com tipo incompatível.
Não se exige que o worker refaça a resolução humana de uma thread válida.

## Incrementos de conserto (R<n>)

| R<n> | Achado | Check escrito no checkpoint |
|---|---|---|
| R1 | #1 | `o=$(bash tests/check-worker.sh 2>&1) && grep -c '^  ok    local ci refuses success without a completed test command$' <<< "$o"` → `1` |
| R2 | #2 | `o=$(bash tests/check-worker.sh 2>&1) && grep -c '^  ok    ahead planner receives the canonical queue outside its base$' <<< "$o"` → `1` |
| R3 | #3 | `o=$(bash tests/check-worker.sh 2>&1) && grep -c '^  ok    ahead planning refuses stale owner request references$' <<< "$o"` → `1` |
| R4 | #4 e #5 | `o=$(bash tests/check-worker.sh 2>&1) && [ "$(grep -c '^  ok    plain human approvals do not hide actionable findings$' <<< "$o")" = 1 ] && grep -c '^  ok    review findings and readiness reject malformed resolved threads$' <<< "$o"` → `1` |

## O que virou incremento

- `R1` — reproduza os três mundos do produtor e do consumidor. O caso sem suíte deve falhar sem
  publicar sucesso e o PR não pode ficar pronto. Saídas reais verde e vermelha ficam distinguíveis.
- `R2` — execute a jornada com Git local e relay real, adaptador falso e fila ausente na base do
  checkout reservado. A entrada do primeiro turno deve identificar a fonte primária e o lote.
  Preserve um único PLAN e a retomada sem duplicação.
- `R3` — teste a referência íntegra, a ausente e o fragmento vencido, inclusive se a fonte
  mudar durante a consulta de orçamento. O caso vencido tem zero lançamentos e não substitui a espera ou o veredito do predecessor.
- `R4` — exercite a leitura do inventário e a prontidão por SHA. Aprovação curta informativa não
  bloqueia, mas corpo com achado e pedido vigente bloqueiam. Metadado presente e inválido é
  recusado pelos dois leitores e uma thread válida, resolvida no GitHub, conserva o caminho verde.

## O que foi refutado

- **Dupla reserva no caso concorrente de QA.** F1 voltou a dar `1` em `27c94ac`. Os dois sensores
  executaram a disputa de retomadas e a caminhada da fila. O segundo lançamento não se repetiu
  e o dono alheio não habilitou antecipação.
- **Sonda do delta verde sem entrar nos cenários.** F2 voltou a dar `1` em `27c94ac`. A reprodução
  exige a execução dos 13 casos e distingue a rodada indevidamente `full` do delta elegível.
- **Uma thread resolvida sempre exige disposição local.** A fixture positiva de
  `tests/check-worker.sh:1792` passou sem disposição e a regra documentada deixa a resolução
  do GitHub intacta. O achado #5 é a divergência com metadado presente e ilegível, não a falta
  de um registro local para uma resolução válida.
- **Um novo head herda o resultado de `local/ci` ou o sim de merge.** Os mundos de outro SHA e
  aceite antigo em `tests/check-worker.sh` passaram. O consumidor exige o resultado do SHA
  lido e o ato usa `--match-head-commit`. O falso verde do achado #1 é no próprio SHA.

## Achados fora de escopo

Nenhum encaminhado ao backlog.

## Pendências / Decisions for a Human

Nenhuma decisão de produto nesta rodada. O pedido original do dono continua sendo necessário
para antecipar na campanha real. As decisões 1 e 7 registram onde procurá-lo, mas não
substituem a fonte original. As permissões reais para status, resolução e merge não foram exercidas.

## Ações recomendadas

- **CRITICAL** — nenhuma.
- **HIGH** — EXEC fecha R1, R2 e R3 separadamente, cada um com sua regressão e nova caminhada.
- **MEDIUM/LOW** — EXEC fecha R4 em lote, mantendo um sensor separável por achado.
- **Depois** — repetir a suíte e reavaliar no novo SHA, em rodada independente com delta a partir
  de `reviewed_head`. A régua de merge do worker continua distinta da tolerância de prosa do runner.

Uso do codereview 2.27.38 explicitamente indicado no boot. Cinco tarefas auxiliares em
`gpt-6.1-terra`, incluindo a varredura de código morto. A integração e o reteste foram
feitos na sessão principal. Custo faturado por tarefa indisponível nesta sessão.
