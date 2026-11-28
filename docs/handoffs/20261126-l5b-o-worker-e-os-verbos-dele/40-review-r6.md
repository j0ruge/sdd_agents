---
missao: 20261126-l5b-o-worker-e-os-verbos-dele
fase: REVIEW
rodada: 6
status: done
sessao: 01a21fc0-1001-7c02-b92f-15647236551a
data: 2026-11-27 22:41
gate: tests/run-all.sh em 61398c9ab0350f11dd98b1ee703985e2d79cb548 → rc 0, suite green, 21 etapas e 110 sondas do worker em 1036,23 s. A etapa Codex teve 3 casos skipped. Árvore limpa durante a execução. REVIEW não passou. Code Quality (Zen), Error Handling, Security e Test Coverage repetiram B. Documentation caiu de A para B por rastreabilidade, critério tolerado. R8 confirmado e R9 pending.
reviewed_head: 61398c9ab0350f11dd98b1ee703985e2d79cb548
---

# Review — rodada r6 — O worker e os verbos dele

## TL;DR

R8 fechou em `1a50dd42`. Os 15 cenários novos passam e as três inversões da r5 foram corrigidas.
Quando os dois marcadores de lista estão na mesma linha, HTML de um item interno ainda pode ocultar
um título do item externo. A regressão confirmada virou R9. A falta de evidência bruta para as
sabotagens do EXEC foi registrada no backlog. Nenhum código foi alterado.

## Nota da rodada

Apliquei `codereview base=0c4cd1371334e7e11f02b387f7cacb306f2a91ef` até
`61398c9ab0350f11dd98b1ee703985e2d79cb548`. Quatro commits alteraram nove caminhos.
Revisei oito, excluindo o arquivo de notas. Usei apenas a cauda fornecida no boot.
O handoff QA já cobre a reserva única e a ordem da jornada. A r5 serviu de referência
para o diferencial de R8. O delta não renomeou nenhuma interface.

### Detecção de segredos

| Resultado | Varredores | Arquivos | Linhas acrescentadas | Achados | Erros |
|---|---|---:|---:|---:|---:|
| PASS | `regex`, `gitleaks` | 8 | 273 | 0 | 0 |

No head revisado:

~~~bash
git -P diff 0c4cd1371334e7e11f02b387f7cacb306f2a91ef...61398c9ab0350f11dd98b1ee703985e2d79cb548 --unified=0 -- . ':(exclude)docs/handoffs/20261126-l5b-o-worker-e-os-verbos-dele/checkpoint-notas.md' |
  bash /home/joruge/.claude/plugins/cache/chewiesoft-marketplace/codereview/2.30.2/skills/codereview/scripts/scan_secrets.sh
~~~

### Cobertura e documentação do delta

| Caminho | Evidência |
|---|---|
| `bin/sdd-worker-ahead` | O leitor passou a guardar recuos de lista para o HTML bruto. O recuo é inteiro e a pilha conserva o nível raiz. A comparação de dois formatos de lista aninhada localizou o erro no consumo de um só marcador por linha. Nenhuma chamada externa nova. |
| `tests/check-worker-ahead.py` e `tests/check-worker.sh` | Os 15 cenários de R8 passaram no head. A asserção verifica ordem e número de eventos, stderr vazio e veredito. O cenário aninhado existente põe o marcador interno em outra linha. A suíte não mede a variante compacta. |
| `commands/sdd-worker.md` e `docs/pipeline.md` | O contrato especifica um título único fora de HTML bruto e limita o bloco ao item. A variante compacta contradiz esse contrato no código. O R9 cobre o comportamento reproduzido. |
| `20-handoff-exec.md`, `checkpoint.md` e `40-review-r5.md` | O hash e os casos nomeados para R8 conferem. O reteste independente confirmou a suíte e a jornada. O handoff não vincula a saída das sabotagens a seus resultados. |

Em cópias descartáveis do head, seis alterações isoladas inverteram a ordem ou presença de
`start` em uma sonda de R8 que passava na cópia intacta. As alterações impediram a remoção do recuo,
mantiveram o HTML após a saída, usaram recuo absoluto para abrir HTML, permitiram que uma lista
ordenada interrompesse um parágrafo em qualquer número, removeram a guarda de separador temático
ou reconheceram lista dentro de HTML. Os seis mutantes saíram 1 por divergência de eventos, com
o mesmo veredito do runner. Isso verifica esses sensores, não reproduz as contagens do EXEC.

### Varredura de código morto e desempenho

`ruff check --no-cache --select F401,F811,F821 bin/sdd-worker-ahead tests/check-worker-ahead.py` e
`bash -n tests/check-worker.sh` saíram 0. Os dois novos locais do leitor têm consumidores
no próprio delta. O shell chama os 15 casos adicionados à fixture. Nenhum símbolo introduzido
ou órfão sem uso no delta. O legado não foi varrido.

Isolei `raw_html_end` e `local_anchors` por AST nos blobs de base e head. O mínimo de
`timeit.repeat(lambda: f(sample), number=8, repeat=4)` dividido por oito, sem I/O, em 12.003 e
24.003 linhas, foi 9,675 e 19,040 ms na base e 12,533 e 25,225 ms no head. A amostra repetiu
`"Parágrafo comum.\n\n<div>\nTexto de exemplo\n</div>\n\n"` e terminou na instrução da fixture.
O tempo dobrou com a amostra e houve cerca de 6 ms a mais no maior arquivo. Ambos retornaram
uma âncora.

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | B | O estado só consome um marcador por linha e pode associar HTML do item interno ao recuo do item externo. |
| Type Safety | A | A pilha de inteiros conserva a raiz e o casamento de lista é testado antes de usar grupo ou posição. |
| Error Handling | B | Um título visível único é recusado silenciosamente na variante compacta, embora a espera preserve o diagnóstico original. |
| Security | B | A variante compacta pode reduzir dois títulos visíveis a um e iniciar um turno simulado. As guardas de delegação, orçamento e checkout não mudaram. |
| Performance | A | O custo cresceu na proporção da amostra e o delta não introduziu I/O no leitor. |
| Test Coverage | B | O sensor R8 matou seis mutações amostradas e passou nos 15 casos, mas nenhum cobre os dois marcadores de lista na mesma linha. |
| Documentation | B | O reteste confirma os casos nomeados para R8. A contagem das sabotagens não vem acompanhada de saída auditável no handoff. |
| **Overall** | **B** | R8 fechou nos casos da r5, mas a regressão irmã ainda altera a decisão sobre o pedido escrito. |

## Achados da rodada

| # | Severidade | Achado | Onde |
|---|---|---|---|
| 1 | HIGH | Em uma lista aninhada iniciada na mesma linha, o leitor não entra no item interno. Uma tag parecida com HTML dentro do bloco interno passa a abrir HTML no item externo e oculta seu título. Um pedido válido deixa de disparar ou um pedido ambíguo dispara. | `bin/sdd-worker-ahead:99–106` |
| 2 | MEDIUM | O handoff EXEC informa totais de sabotagens detectadas e de controles, sem apontar a saída por execução. A cauda entregue traz as contagens e exemplos, mas não permite conferir a série completa. Lacuna de registro, sem achado de produto adicional. | `docs/handoffs/20261126-l5b-o-worker-e-os-verbos-dele/20-handoff-exec.md:88` |

### Reprodução do achado 1

Mantive o mesmo runbook, relay e a mesma fixture nas duas cópias de teste. Alterei apenas
`bin/sdd-worker-ahead`, com os blobs obtidos por
`git show 0c4cd1371334e7e11f02b387f7cacb306f2a91ef:bin/sdd-worker-ahead` e
`git show 61398c9ab0350f11dd98b1ee703985e2d79cb548:bin/sdd-worker-ahead`. `cmp` confirmou
que o segundo é idêntico ao checkout. Não houve chamada a GitHub ou Codex.

Copiei `tests/check-worker-ahead.py` para `probe.py` em `/tmp` e acrescentei ao dicionário de
`--preceding-markup` os casos abaixo. `instruction` já contém `# Owner request`, linha vazia
e o pedido. Após a execução, imprimi `events`, `stderr` e a última linha de `stdout` antes das
asserções existentes. Para cada lado e caso, executei
`timeout 25s python3 "$copia/probe.py" "$copia/$rev" --preceding-markup "$caso"`.

~~~python
compact = "- - <script>\n    <div>\n  "
expanded = "- Outro texto\n  - <script>\n    <div>\n  "
cases = {
    "compact-nested-unique": (compact + instruction, True),
    "compact-nested-duplicate": (instruction + "\n" + compact + instruction, False),
    "expanded-nested-unique": (expanded + instruction, True),
    "expanded-nested-duplicate": (instruction + "\n" + expanded + instruction, False),
    "compact-nested-closed": (compact[:-2] + "    </script>\n  " + instruction, True),
}
~~~

`MarkdownIt('commonmark', {'html': True})` em `markdown-it` 3.0.0 marcou, respectivamente, títulos
ATX nas linhas `[3]`, `[1, 7]`, `[4]`, `[1, 8]` e `[4]`. No primeiro caso, o `html_block` termina
antes do `list_item_close` interno, seguido de `heading_open` dentro do item externo.

| Caso | Base `0c4cd137` | Head `61398c9a` |
|---|---|---|
| `html-list-end-unique` e `html-list-end-script` | `wait` · 1 nos dois | `start, wait` · 0 nos dois |
| `html-list-end-duplicate` | `start, wait` · 1 | `wait` · 0 |
| `html-list-still-inside` | `start, wait` · 1 | `wait` · 0 |
| `compact-nested-unique` | `start, wait` · 0 | `wait` · 1 |
| `compact-nested-duplicate` | `wait` · 0 | `start, wait` · 1 |
| `expanded-nested-unique` | `start, wait` · 0 | `start, wait` · 0 |
| `expanded-nested-duplicate` | `wait` · 0 | `wait` · 0 |
| `compact-nested-closed` | `start, wait` · 0 | `wait` · 1 |

O rc da tabela é da sonda. Nos casos da tabela houve um único `wait`, stderr vazio e o
veredito `verdict|3|phase-ceiling|sdd run stop: phase-ceiling — fixture` nos dois SHAs.
Na abertura compacta, o `if` reconhece só o primeiro `-` e deixa o segundo antes de `<script>`.
Na linha seguinte, a tag `<div>` fica recuada apenas duas colunas em relação ao nível que o leitor
guardou e abre seu próprio HTML. O título com duas colunas não desempilha esse nível. Mesmo um
`</script>` explícito não fecha o HTML incorretamente iniciado como `<div>`.

## Incrementos de conserto (R<n>)

| R<n> | Achado | Check escrito no checkpoint |
|---|---|---|
| R9 | #1 | `o=$(bash tests/check-worker.sh 2>&1) && [ "$(grep -c '^  ok    owner request bounds raw html by its compact nested list item$' <<< "$o")" = 1 ] && [ "$(grep -c '^  ok    owner request bounds raw html by its list item$' <<< "$o")" = 1 ] && grep -c '^  ok    authorized ahead planning starts once before wait$' <<< "$o"` → `1` |

## O que virou incremento

- `R9` — Repetir a jornada de `run` com os três casos compactos e os controles expandidos.
  Título único deve iniciar um turno antes de esperar. Duplicado deve manter só a espera.
  Confirmar espera única, `rc=3`, `phase-ceiling`, diagnóstico original, R5–R8 e reserva única.
- `R8` — Conserto de `1a50dd42` confirmado. Três inversões da r5 saíram 1 na base e 0 no head.
  O controle ainda dentro do HTML, os 15 casos de R8 e os marcadores de R8 e reserva única
  passaram no head. O R9 isola uma regressão nova do contexto de lista, não reabre R8.

## O que foi refutado

- **R8 não corrigiu os três casos da r5.** A comparação dos blobs e a execução dos quatro casos
  históricos mostraram o despacho esperado no head e o oposto na base.
- **A regressão também afeta a forma com os marcadores em linhas separadas.** Os dois controles
  expandidos conservaram o despacho esperado e a espera nos dois SHAs.
- **O verde da suíte do EXEC não é corroborado.** `tests/run-all.sh` foi reexecutado no head
  revisado. `git -P diff --name-only 1a50dd42..61398c9a -- . ':(exclude)docs/handoffs/**'` não
  listou alterações. A verificação confirma o estado da implementação, não a saída histórica
  exata do processo do EXEC. A lacuna de auditoria das sabotagens continua registrada.

## Achados fora de escopo

- Achado #2 registrado no `TODO.md`, categoria Comentário e registro, com a contagem atualizada
  em `tests/health-baseline.txt`. Nenhum R novo por prosa.
- O falso verde pré-existente de `local/ci` com `TEST_CMD` só de espaços não foi reavaliado.
  O produtor de `local/ci` não faz parte deste delta.

## Pendências / Decisions for a Human

A correção de R8 é verificável. Code Quality (Zen), Error Handling, Security e Test Coverage
continuam em B. Documentation caiu de A para B por rastreabilidade da evidência e não bloqueia
sozinha. O loop de revisão para nesta rodada e a retomada com R9 fica a critério do mantenedor.

## Boot da próxima fase

Se a revisão for retomada, leia R9 no checkpoint e repita os três casos compactos e os controles
expandidos acima. Compare só os blobs de `0c4cd137` e `61398c9a` antes de consertar. Preserve o
Check R8 e a jornada de reserva única. O teste usa o bloco público de `run` com Git local e
adaptadores simulados.

## Ações recomendadas

**CRITICAL**

Nenhuma.

**HIGH**

- Se o ciclo for retomado, fechar R9 em TDD. O HTML precisa respeitar o limite do item interno
  tanto com os marcadores em linhas separadas quanto na mesma linha.

**MEDIUM/LOW**

- Preservar a saída individual das sabotagens citadas no handoff de EXEC ou qualificar o que
  foi preservado. Encaminhado ao backlog.

_Pegada de custo — skill Codex 2.27.38 indicada no boot, contrato de verificação da versão instalada 2.30.2 aplicado. Zero agentes de código, uma verificadora gpt-6.1-terra, 14 unidades e 19 chamadas declaradas. Análise de código, varredura e reprodução na sessão principal. Custo faturado indisponível._
