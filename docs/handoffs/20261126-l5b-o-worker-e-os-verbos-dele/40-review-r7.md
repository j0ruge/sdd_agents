---
missao: 20261126-l5b-o-worker-e-os-verbos-dele
fase: REVIEW
rodada: 7
status: done
sessao: 01a21fff-1d67-7b91-bd9b-c838acb402a6
data: 2026-11-27 23:50
gate: tests/run-all.sh em fda9359e458ab835c3a21d4d1d4e747b4e96eae4 → rc 0, 21 etapas, suite green, 111 sondas verdes na etapa do worker, 3 casos skipped na etapa Codex. Árvore limpa durante a suíte. REVIEW não passou. Code Quality (Zen), Error Handling, Security e Test Coverage seguem B. Performance caiu de A para B e interrompe o loop. Documentation e Overall em B. R9 confirmado, R10 e R11 pending.
reviewed_head: fda9359e458ab835c3a21d4d1d4e747b4e96eae4
---

# Review — rodada r7 — O worker e os verbos dele

## TL;DR

Confirmei os seis casos de R9 em `0d33f0d0` e reproduzi as três falhas da r6 na base.
Dois achados do delta viraram R10 e R11. O leitor confunde continuação de parágrafo com HTML
e chega a disparar com título duplicado. Uma lista compacta longa também atrasa a espera.
O comportamento anterior com título na linha do marcador ficou no backlog. Nenhum código foi alterado.

## Nota da rodada

Apliquei `codereview base=61398c9ab0350f11dd98b1ee703985e2d79cb548` até
`fda9359e458ab835c3a21d4d1d4e747b4e96eae4`. O intervalo tem quatro commits e 11 caminhos.
O escopo teve dez caminhos, excluído o arquivo de notas, do qual usei só a cauda fornecida.
Três arquivos de código foram analisados na sessão principal. A verificação de prosa delegada
leu 16 unidades de seis caminhos. A entrada de `tests/health-baseline.txt` foi reclassificada
como dado do sensor e conferida com a contagem executada. A r6 foi usada como evidência histórica
e para fechar os achados abertos. O delta não renomeou interface. O QA já cobre F1 e F2,
inclusive corrida de reserva e seleção de revisão. A suíte foi rodada uma vez no checkout limpo.

### Detecção de segredos

| Resultado | Varredores | Arquivos | Linhas acrescentadas | Achados | Erros |
|---|---|---:|---:|---:|---:|
| PASS | `regex`, `gitleaks` | 10 | 272 | 0 | 0 |

~~~bash
git -P diff 61398c9ab0350f11dd98b1ee703985e2d79cb548...fda9359e458ab835c3a21d4d1d4e747b4e96eae4 --unified=0 -- . ':(exclude)docs/handoffs/20261126-l5b-o-worker-e-os-verbos-dele/checkpoint-notas.md' |
  bash /home/joruge/.claude/plugins/cache/chewiesoft-marketplace/codereview/2.30.2/skills/codereview/scripts/scan_secrets.sh
~~~

### Cobertura e documentação do delta

| Caminho | Evidência |
|---|---|
| `bin/sdd-worker-ahead` | O laço com recuo acumulado encerra o HTML de R9 no nível correto. Os novos casos de R10 e R11 exercitam, respectivamente, a continuidade do parágrafo e o custo de reexaminar seu prefixo de lista. |
| `tests/check-worker-ahead.py` e `tests/check-worker.sh` | As seis entradas de R9 pegam o despacho, a espera e o veredito. Nenhuma combina texto no item externo com tag que só abre fora de parágrafo, ou mede o custo por marcador na mesma linha. |
| `commands/sdd-worker.md` e `docs/pipeline.md` | Ambos explicitam o fim do HTML no item compacto. A reprodução de R10 contradiz a decisão esperada sobre o título, não o encerramento do primeiro bloco HTML. |
| `20-handoff-exec.md` e `checkpoint.md` | Os seis resultados de R9, seu commit e os marcadores de R8, R9 e reserva conferem. As 24 sabotagens relatadas pelo EXEC não foram repetidas nesta rodada. |
| `TODO.md` e `tests/health-baseline.txt` | O item de rastreabilidade de R8 persistiu e a contagem de 102 achados do head foi confirmada pelo sensor da suíte. O achado preexistente desta rodada é novo no backlog. |

### Varredura de código morto, tipos e fronteiras

`ruff check --no-cache --select F401,F811,F821 bin/sdd-worker-ahead tests/check-worker-ahead.py`,
`bash -n tests/check-worker.sh` e a leitura sintática dos dois arquivos Python saíram 0 no head.
Nenhum símbolo novo ou órfão sem consumidor. A pilha continua de inteiros, com zero como raiz.
Cada iteração consome um marcador não vazio. O delta não cria chamada externa nem muda
as checagens de autorização, orçamento, dono do checkout ou reserva. A falha de segurança é a
leitura ambígua do pedido local antes dessas checagens. O legado não foi varrido.

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | B | O HTML usa o texto relativo ao item, mas o estado de parágrafo ainda usa o recuo absoluto. R10 mede a divergência. |
| Type Safety | A | A raiz permanece inteira e os recuos só são usados após casamento não vazio do marcador. |
| Error Handling | B | O leitor recusa silenciosamente um pedido local com título único no caso de R10. A espera ainda preserva o diagnóstico do runner. |
| Security | B | R10 reduz dois títulos visíveis a um e inicia um turno simulado. Delegação, orçamento e ownership continuam exigidos. |
| Performance | B | O laço reaplica a busca por separador temático a todos os sufixos de uma lista compacta longa. R11 mede a curva quadrática e o atraso antes da espera. |
| Test Coverage | B | R9 tem seis testemunhas e reprova na base pelos eventos esperados. A suíte ainda deixa passar R10 e R11. |
| Documentation | B | O registro histórico de R8 não vincula cada sabotagem ao resultado. O reteste confirmou os seis casos de R9 e os limites declarados de simulação. |
| **Overall** | **B** | R9 resolveu os casos da r6, mas o delta introduziu novas falhas de despacho e de desempenho. |

## Achados da rodada

| # | Severidade | Achado | Onde |
|---|---|---|---|
| 1 | HIGH | Ao sair do HTML de um item compacto, a linha de texto do item externo não reabre o parágrafo se tiver quatro espaços absolutos. Uma tag de tipo 7 em continuação vira um novo HTML e oculta o título seguinte. O despacho é invertido nas duas direções. | `bin/sdd-worker-ahead:100–115` |
| 2 | MEDIUM | O laço testa o separador temático novamente em cada sufixo de uma sequência longa de hífens. Um pedido de cerca de 24 KB fez o `run` simulado gastar 5,02 s em vez de 0,67 s antes de concluir sua única espera. | `bin/sdd-worker-ahead:100–104` |
| 3 | MEDIUM, preexistente | Um título ATX na linha do próprio marcador de lista não é contado, com ou sem R9. Quando há outro título na raiz, a omissão faz o pedido ambíguo parecer único. | `bin/sdd-worker-ahead:112` |

### Reprodução diferencial de R9 e dos achados

Em cópias descartáveis, mantive a fixture de `tests/check-worker-ahead.py`, o runbook e os
adaptadores intactos. Troquei apenas `bin/sdd-worker-ahead` pelos blobs lidos com
`git show 61398c9ab0350f11dd98b1ee703985e2d79cb548:bin/sdd-worker-ahead` e
`git show fda9359e458ab835c3a21d4d1d4e747b4e96eae4:bin/sdd-worker-ahead`. `cmp` confirmou
o blob do head contra o checkout. Para cada caso, executei
`timeout 25s bash -c 'ulimit -v 262144; exec python3 "$@"' _ "$copia/probe.py" "$copia/$lado" --preceding-markup "$caso"`.
Imprimi os eventos e a última linha de stdout antes das asserções. Usei Git local e relays
simulados, sem GitHub ou Codex reais.

| Caso | Base `61398c9a` | Head `fda9359e` |
|---|---|---|
| `compact-nested-unique` e `compact-nested-closed` | `wait`, rc 1 | `start, wait`, rc 0 |
| `compact-nested-duplicate` | `start, wait`, rc 1 | `wait`, rc 0 |
| `compact-nested-still-inside` e `expanded-nested-duplicate` | `wait`, rc 0 | `wait`, rc 0 |
| `expanded-nested-unique` | `start, wait`, rc 0 | `start, wait`, rc 0 |
| `compact-lazy-paragraph-unique` | `start, wait`, rc 0 | `wait`, rc 1 |
| `compact-lazy-paragraph-duplicate` | `wait`, rc 0 | `start, wait`, rc 1 |
| `compact-html-after-blank` | `wait`, rc 0 | `wait`, rc 0 |
| `list-marker-heading-unique` | `wait`, rc 1 | `wait`, rc 1 |
| `list-marker-heading-duplicate` | `start, wait`, rc 1 | `start, wait`, rc 1 |

O rc da tabela é o da sonda. Em todos os casos, stderr do bloco público foi vazio e houve uma
espera e `verdict|3|phase-ceiling|sdd run stop: phase-ceiling — fixture`. Os casos novos usam
a mesma instrução da fixture, `# Owner request`, linha vazia e o pedido.

~~~python
markup = "10. - <script>\n    Text\n<sample-box>\n"
unique = markup + instruction
duplicate = instruction + "\n" + unique
after_blank = markup.replace("Text\n", "Text\n\n") + instruction
marker_unique = "- " + instruction
marker_duplicate = instruction + "\n" + marker_unique
~~~

`MarkdownIt("commonmark", {"html": True})` 3.0.0 encontrou, respectivamente, títulos nas
linhas `[4]`, `[1, 8]`, `[]`, `[1]` e `[1, 5]`. `<sample-box>` na primeira amostra é
continuação de parágrafo. Com a linha vazia vira um bloco HTML real. No fluxo da base,
`in_paragraph` chega verdadeiro à linha `<sample-box>`. No head, o `<script>` recém-reconhecido
limpa esse estado. Depois do desempilhamento, `Text` tem recuo relativo zero mas a linha
absoluta tem quatro espaços e não restaura o estado. O segundo HTML abre fora da lista e segue
até a linha em branco, engolindo o título. R10 mantém a distinção do controle com linha vazia.

Para R11, extraí `local_anchors` e `raw_html_end` dos mesmos blobs por AST, sem E/S no trecho
medido. O menor de três `timeit.repeat(lambda: fn(sample), number=1, repeat=3)` foi:

| Marcadores antes de `<script>` | Base com hífens | Head com hífens | Head com sinais `+` |
|---:|---:|---:|---:|
| 2.000 | 0,10 ms | 78,81 ms | 1,65 ms |
| 4.000 | 0,13 ms | 237,25 ms | 3,43 ms |
| 8.000 | 0,24 ms | 909,46 ms | 7,11 ms |
| 16.000 | 0,49 ms | 3.761,44 ms | 16,93 ms |

A entrada foi `marker * tamanho + "<script>\n\n# Owner request\n"`. Nos 4.000 hífens, a sonda
contou uma aplicação da expressão de separador na base e 4.000 no head. Os comprimentos dos
sufixos somaram 8.008 e 16.036.000 caracteres, respectivamente. Na jornada pública, acrescentei
12.000 repetições de `"- "` ou `"+ "` antes de `"<script>\n\n" + instruction` e medi com
`/usr/bin/time` ao redor do mesmo comando de reprodução. Hífens deram 0,67 s na base e 5,02 s
no head. Sinais `+` deram 0,54 s e 0,58 s. Todos os quatro passaram com `start, wait` e o mesmo
veredito. O `run` chama o leitor em primeiro plano antes de esperar, e relê o pedido antes do
primeiro turno. Não foi observado erro de permissão ou de sanidade do veredito nesse cenário.

## Incrementos de conserto (R<n>)

| R<n> | Achado | Check escrito no checkpoint |
|---|---|---|
| R10 | #1 | `o=$(bash tests/check-worker.sh 2>&1) && [ "$(grep -c '^  ok    owner request preserves paragraph after compact nested html$' <<< "$o")" = 1 ] && [ "$(grep -c '^  ok    owner request bounds raw html by its compact nested list item$' <<< "$o")" = 1 ] && grep -c '^  ok    authorized ahead planning starts once before wait$' <<< "$o"` → `1` |
| R11 | #2 | `o=$(bash tests/check-worker.sh 2>&1) && [ "$(grep -c '^  ok    owner request bounds compact list scan before wait$' <<< "$o")" = 1 ] && [ "$(grep -c '^  ok    owner request bounds raw html by its compact nested list item$' <<< "$o")" = 1 ] && grep -c '^  ok    authorized ahead planning starts once before wait$' <<< "$o"` → `1` |

## O que virou incremento

- `R10` mede os casos de título único, duplicado e HTML real depois de linha vazia pelo bloco público.
  Exige `start, wait`, `wait` e `wait`, respectivamente, preservando um `wait`, `rc=3`,
  `phase-ceiling`, o diagnóstico intacto, R9 e a jornada de reserva única.
- `R11` mede o crescimento do trabalho em uma linha com muitos hífens sem separador temático
  real. Controle com sinais `+`, separador real e jornada pública verificam que o custo
  não é mascarado por pular o caso ou mudar a decisão. Prefira contador de trabalho ou
  comparação de crescimento a um teto de relógio dependente da máquina.
- `R9` foi fechado em `0d33f0d0`. Os três vermelhos históricos só ocorreram na base. Os seis casos,
  o Check R9, o Check R8 e a jornada de reserva única passaram no head. Não foi reaberto.

## O que foi refutado

- **R9 não resolveu as inversões da r6.** No diferencial, três casos saíram 1 na base e 0 no head.
  Os três controles passaram dos dois lados.
- **O `<sample-box>` deve abrir HTML independentemente do parágrafo.** Sem linha em branco,
  o parser de referência o colocou no parágrafo nos dois casos de R10. Com linha em branco
  o controle abriu HTML de verdade, e os dois blobs recusaram o título nele.
- **O problema de escala é apenas o custo de ler um arquivo maior ou do relay simulado.**
  O custo aparece no leitor isolado e o controle de mesmo comprimento com `+` não reproduz
  o atraso no bloco público.
- **O handoff declara, sem evidência, que R9 deixou o produto sem achados.** A frase em
  `20-handoff-exec.md:165` limita-se aos achados novos registrados na execução de R9.
  `git -P diff 9fd01c4a..3f48337a --name-only -- TODO.md tests/health-baseline.txt` não listou
  mudança, e as notas fornecidas não registram achado de backlog novo. Isso não é evidência
  de ausência de defeitos nem contradiz R10 e R11, que são achados de REVIEW.

## Achados fora de escopo

- Achado #3 registrado no `TODO.md`, em Contrato e configuração. O mesmo disparo indevido
  foi reproduzido na base e no head, sem HTML ou aninhamento. A expressão que lê o título
  não mudou, portanto esse caso independente não é R.
- A lacuna histórica de R8 continua no item aberto em Comentário e registro. A r7 não
  releu as notas integrais para reconstituir a série e não criou um item duplicado.
- O falso verde preexistente de `local/ci` com `TEST_CMD` só de espaços não foi reavaliado.

## Pendências / Decisions for a Human

Performance caiu de A para B em relação à r6, com regressão reproduzida. Pela regra de
parada do loop, esta sessão termina com a nota real e R10 e R11 pendentes. A retomada do
ciclo é decisão do mantenedor.

## Boot da próxima fase

Leia R10 e R11 no checkpoint. Reproduza os casos de parágrafo e de escala acima no head
`fda9359e` em cópia descartável. Separe os vermelhos e os commits. Use a fixture pública
de `run` e preserve R8, R9 e a jornada de reserva única. Não há necessidade de GitHub ou
Codex reais.

## Ações recomendadas

**CRITICAL**

Nenhuma.

**HIGH**

- Fechar R10 antes de reavaliar o despacho automático.

**MEDIUM/LOW**

- Fechar R11 sem mudar os eventos do `run`. Tratar o título na linha do marcador no backlog.

_Pegada de custo — skill Codex 2.27.38, contrato de verificação da versão instalada 2.30.2.
Zero agentes de código, uma verificadora gpt-6.1-terra com 16 unidades e 22 chamadas declaradas.
Análise de código, varredura e reprodução na sessão principal. Custo faturado indisponível._
