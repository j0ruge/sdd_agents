---
missao: 20261126-l5b-o-worker-e-os-verbos-dele
fase: REVIEW
rodada: 5
status: done
sessao: 01a21f79-65cd-7500-b0c4-579504838213
data: 2026-11-27 21:26
gate: tests/run-all.sh em 0c4cd1371334e7e11f02b387f7cacb306f2a91ef → rc 0, suite green em 21 etapas e 109 sondas do worker. A etapa Codex registrou 3 skipped. Árvore limpa durante a suíte. REVIEW não passou. Platô em Code Quality (Zen), Error Handling, Security e Test Coverage, todos em B como na r4. R7 confirmado e R8 pending.
reviewed_head: 0c4cd1371334e7e11f02b387f7cacb306f2a91ef
---

# Review — rodada r5 — O worker e os verbos dele

## TL;DR

R7 fechou em `9d53509f`. Os três casos da r4 passaram no head e falharam na base.
Ao sair de um item de lista, o novo estado de HTML ainda oculta o título Markdown que vem logo depois.
A regressão confirmada virou R8. As notas repetiram as da r4 e o gate não fechou.
Nenhum código foi alterado nesta revisão.

## Nota da rodada

Apliquei `codereview base=13103d36ebf370347bf1aa12d914b5c489e49b9f` até
`0c4cd1371334e7e11f02b387f7cacb306f2a91ef`. Quatro commits alteraram nove caminhos. Oito entraram
na análise, com as notas de execução excluídas da leitura e da varredura. Usei o handoff QA
para identificar a jornada já coberta, sem reabrir F1 ou F2. Nenhuma interface mudou de nome.

### Detecção de segredos

| Resultado | Varredores | Arquivos | Linhas acrescentadas | Achados | Erros |
|---|---|---:|---:|---:|---:|
| PASS | `regex`, `gitleaks` | 8 | 289 | 0 | 0 |

Executei no head revisado:

~~~bash
git -P diff 13103d36ebf370347bf1aa12d914b5c489e49b9f...HEAD --unified=0 -- . ':(exclude)docs/handoffs/20261126-l5b-o-worker-e-os-verbos-dele/checkpoint-notas.md' |
  bash /home/joruge/.agents/skills/codereview/scripts/scan_secrets.sh
~~~

### Cobertura e documentação do delta

| Caminho | Evidência |
|---|---|
| `bin/sdd-worker-ahead` | Único arquivo de produto alterado. O novo estado distingue HTML bruto de cerca em texto, mas não acompanha o fim do item que contém o HTML. |
| `tests/check-worker-ahead.py` e `tests/check-worker.sh` | AST e `bash -n` passaram. O sensor R7 executa 19 cenários e verifica a ordem e a cardinalidade de `start` e `wait`, stderr e o veredito. Nenhum cenário cobre o fim do item sem linha vazia, distinto do fim da cerca. |
| `commands/sdd-worker.md` e `docs/pipeline.md` | Os dois textos preservam a condição de um título inequívoco fora de HTML bruto e de código cercado. O novo achado é uma violação desse contrato pela implementação. |
| `20-handoff-exec.md`, `40-review-r4.md` e `checkpoint.md` | O commit de R7 é ancestral do head. A reprodução confirmou os três casos enumerados no handoff EXEC e refutou uma leitura da abertura desse trecho como garantia para todo HTML em Markdown. A seção de riscos já delimita o alcance do leitor. |

### Varredura de código morto e desempenho

O novo `raw_html_end` só é chamado por `local_anchors`, e os novos nomes do sensor têm
consumidores. `ruff check --no-cache --select F401,F811,F821 bin/sdd-worker-ahead tests/check-worker-ahead.py` saiu 0.
O delta não muda exportações nem deixa um símbolo sem consumidor. Não varri o legado.

Isolei as funções de leitura por AST nos dois blobs e medi o mínimo de
`timeit.repeat(lambda: f(sample), number=8, repeat=4)` dividido por oito, sem I/O.
Repeti `"Parágrafo comum.\n\n<div>\nTexto de exemplo\n</div>\n\n"` 2.000 ou 4.000 vezes e acrescentei
a instrução da fixture. Os dois blobs retornaram uma âncora. Em 12.003 e 24.003 linhas, a base
levou 8,021 e 16,197 ms e o head levou 9,737 e 19,479 ms. O tempo dobrou com o tamanho na amostra.

Na saída da suíte, as nove asserções que compõem os Checks de R1–R7 e de reserva única apareceram uma vez cada. O marcador exclusivo proposto para R8 apareceu zero vezes. Não reexecutei as sabotagens do EXEC.

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | B | O estado de HTML bruto não registra o limite do item que contém o bloco. |
| Type Safety | A | O estado acrescentado é uma expressão de fechamento ou `None` e só chega à busca quando preenchido. |
| Error Handling | B | Um título visível único cai silenciosamente na rota de sugestão, embora a espera preserve o diagnóstico do runner. |
| Security | B | Dois títulos visíveis podem resultar em um turno simulado quando o leitor oculta o segundo. Delegação, orçamento e dono do checkout continuam exigidos. |
| Performance | A | O tempo cresceu na proporção do tamanho da amostra e o delta não acrescenta consulta externa. |
| Test Coverage | B | Os 19 cenários novos e os controles passam, mas a saída de item de lista durante HTML bruto ainda não tem sensor permanente. |
| Documentation | A | O contrato público continua explícito e o reteste do handoff EXEC delimita os três casos de R7 que foram confirmados. |
| **Overall** | **B** | O conserto de R7 é real, mas a regressão de escopo do HTML permite despacho ambíguo e impede despacho de título válido. |

## Achados da rodada

| # | Severidade | Achado | Onde |
|---|---|---|---|
| 1 | HIGH | HTML bruto iniciado dentro de um item de lista continua ativo depois que o item termina. O leitor oculta um título visível único ou deixa de contar o segundo título de um pedido ambíguo. A decisão do worker se inverte. | `bin/sdd-worker-ahead:82–98` |

### Reprodução

Copiei `tests/check-worker-ahead.py` para fora do repositório como `probe.py`. Mantive o runbook,
o relay e a fixture iguais nos dois lados. Troquei só `bin/sdd-worker-ahead` pelos blobs
obtidos com `git show 13103d36ebf370347bf1aa12d914b5c489e49b9f:bin/sdd-worker-ahead` e
`git show 0c4cd1371334e7e11f02b387f7cacb306f2a91ef:bin/sdd-worker-ahead`. `cmp` conferiu o
segundo blob contra o checkout. Nenhuma chamada real a GitHub ou Codex.

Incluí os quatro casos no dicionário de `--preceding-markup` e imprimi os eventos, stderr e a
última linha de stdout antes das asserções. `instruction` é o título `# Owner request` e o
pedido já existentes na fixture.

~~~python
item = "- Sample item\n  <div>\n  Sample content\n"
cases = {
    "html-list-end-unique": (item + instruction, True),
    "html-list-end-duplicate": (instruction + "\n" + item + instruction, False),
    "html-list-end-script": (item.replace("<div>", "<script>") + instruction, True),
    "html-list-still-inside": (item + "  " + instruction, False),
}
~~~

Com `MarkdownIt('commonmark', {'html': True})` do `markdown-it` 3.0.0, as listas de linhas
com títulos ATX `Owner request` foram, respectivamente, `[4]`, `[1, 8]`, `[4]` e `[]`.
Nos primeiros três casos, a linha do título sem recuo encerra o item e fica fora do HTML.
No controle com recuo, o título permanece dentro do bloco. O mesmo oráculo conferiu as
expectativas dos 49 cenários de marcação da cópia da fixture, incluindo os quatro novos.

Executei `timeout 25s python3 "$copia/probe.py" "$copia/$rev" --preceding-markup "$caso"`
para cada linha nos dois lados. O rc na tabela é o da sonda, não o do predecessor.

| Caso | Base `13103d36` | Head `0c4cd137` |
|---|---|---|
| `closed-comment` e `backtick-info` (R5) | `start, wait` · 0 nos dois | `start, wait` · 0 nos dois |
| `list-fenced-comment-marker` (R6) | `start, wait` · 0 | `start, wait` · 0 |
| `duplicate-after-list-code` (R6) | `wait` · 0 | `wait` · 0 |
| `html-before-unique` (R7) | `wait` · 1 | `start, wait` · 0 |
| `html-before-duplicate` (R7) | `start, wait` · 1 | `wait` · 0 |
| `html-before-comment` (R7) | `start, wait` · 1 | `wait` · 0 |
| `html-list-end-unique` | `start, wait` · 0 | `wait` · 1 |
| `html-list-end-duplicate` | `wait` · 0 | `start, wait` · 1 |
| `html-list-end-script` | `start, wait` · 0 | `wait` · 1 |
| `html-list-still-inside` (controle) | `start, wait` · 1 | `wait` · 0 |

Nas 22 execuções houve um único `wait`, stderr vazio e
`verdict|3|phase-ceiling|sdd run stop: phase-ceiling — fixture`. A condição que mantém
`html_end` só procura o fechamento textual. Não leva em conta o recuo que termina o item,
então consome o título sem testar a âncora. Isso é distinto de uma cerca falsa dentro do HTML,
que R7 passou a ignorar corretamente.

## Incrementos de conserto (R<n>)

| R<n> | Achado | Check escrito no checkpoint |
|---|---|---|
| R8 | #1 | `o=$(bash tests/check-worker.sh 2>&1) && [ "$(grep -c '^  ok    owner request bounds raw html by its list item$' <<< "$o")" = 1 ] && grep -c '^  ok    authorized ahead planning starts once before wait$' <<< "$o"` → `1` |

## O que virou incremento

- `R8` — Na jornada de `run`, o título visível depois do item deve iniciar um turno antes de
  esperar. Dois títulos visíveis devem manter só a espera. O título ainda dentro do HTML deve
  continuar oculto. Cobrir tanto HTML que termina em linha vazia no nível superior quanto o
  tipo que usa fechamento textual, ambos encerrados pela saída do item nos casos reproduzidos.
  Preservar a espera única, `rc=3`, `phase-ceiling` e o diagnóstico original. Manter R5–R7
  e a jornada de reserva única verdes.
- `R7` — Fechado em `9d53509f`. As três inversões da r4 saíram 1 na base e 0 no head. O
  sensor R7 e a jornada de reserva única passaram na suíte desta rodada.

## O que foi refutado

- **O R7 ainda deixa uma falsa cerca dentro de HTML inverter o despacho.** Na comparação
  base/head, os três casos da r4 voltaram ao despacho esperado sem mudar a espera.
- **Os novos casos mostram que cercas abertas em listas ainda escondem títulos depois da lista.**
  Nenhum deles contém uma cerca. Os dois controles de cerca real de R6 passaram nos dois SHAs.
  O defeito desta rodada é o estado de HTML bruto que sobrevive ao fim do item.

## Achados fora de escopo

Nenhum achado fora de escopo confirmado neste delta. O caso já registrado de `local/ci` não
foi reavaliado porque seu produtor não mudou.

## Pendências / Decisions for a Human

O conserto de R7 é verificável, mas todas as letras repetiram as da r4. A REVIEW registra o platô
em Code Quality (Zen), Error Handling, Security e Test Coverage, e deixa ao mantenedor a decisão
de retomar com R8. Nenhuma campanha real é necessária para retestar.

## Boot da próxima fase

Se a revisão for retomada, leia R8 no checkpoint e comece pela reprodução desta rodada. Use os
blobs de `13103d36` e `0c4cd137` para distinguir a regressão nova do conserto confirmado de R7.
A jornada é o bloco público de `run` com Git local e adaptadores simulados.

## Ações recomendadas

**CRITICAL**

Nenhuma.

**HIGH**

- Se o ciclo for retomado, feche R8 em TDD. O estado de HTML precisa respeitar a saída do item
  sem voltar a contar títulos que ainda estejam no bloco.

**MEDIUM/LOW**

Nenhuma.

_Pegada de custo — skill Codex 2.27.38 indicada no boot. Registro Claude 2.30.2. Dois agentes de documentação gpt-6.1-terra, 10 chamadas e nove leituras integrais reportadas. Código, testes, varredura e reprodução na sessão principal. Custo faturado indisponível._
