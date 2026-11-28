---
missao: 20261126-l5b-o-worker-e-os-verbos-dele
fase: REVIEW
rodada: 8
status: done
sessao: 01a22062-bc81-7690-9359-567d4bfc469c
data: 2026-11-28 01:39
gate: SDD_MUTATION_FIXTURE_ROOT="$PWD" tests/run-all.sh em 94efef27ebc012c36d3904bb75ccd86d9219acff → rc 0, suite green, 21 etapas, 113 sondas do worker, 3 casos skipped do Codex. Árvore limpa durante a execução. R10 e R11 confirmados. REVIEW não passou. Performance subiu de B para A. Code Quality (Zen), Error Handling, Security e Test Coverage seguem B. R12 pending.
reviewed_head: 94efef27ebc012c36d3904bb75ccd86d9219acff
---

# Review — rodada r8 — O worker e os verbos dele

## TL;DR

R10 e R11 passaram no reteste diferencial e a suíte deu verde. Um separador temático no
item externo passou a ser tratado como texto de parágrafo. Depois dele, o leitor conta um
título que está dentro de HTML e pode iniciar um planner sem título visível. Registrei o
achado como R12. Nenhum código foi alterado.

## Nota da rodada

Apliquei `codereview base=fda9359e458ab835c3a21d4d1d4e747b4e96eae4` no head
`94efef27ebc012c36d3904bb75ccd86d9219acff`. O delta tem sete commits e 11 caminhos.
Excluí o histórico de notas, usando só a cauda fornecida. O QA anterior já cobre F1 e F2,
incluindo a retomada concorrente e a seleção da revisão, e não foi usado como evidência
para R10 ou R11. Nenhuma interface mudou de nome.

### Detecção de segredos

| Resultado | Varredores | Arquivos | Linhas acrescentadas | Achados | Erros |
|---|---|---:|---:|---:|---:|
| PASS | `regex`, `gitleaks` | 10 | 353 | 0 | 0 |

~~~bash
m=docs/handoffs/20261126-l5b-o-worker-e-os-verbos-dele
git -P diff fda9359e458ab835c3a21d4d1d4e747b4e96eae4...94efef27ebc012c36d3904bb75ccd86d9219acff --unified=0 -- . ":(exclude)$m/checkpoint-notas.md" |
  bash /home/joruge/.claude/plugins/cache/chewiesoft-marketplace/codereview/2.30.2/skills/codereview/scripts/scan_secrets.sh
~~~

### Cobertura e documentação do delta

| Caminho | Evidência |
|---|---|
| `bin/sdd-worker-ahead` | Comparei o estado de parágrafo e os eventos do fluxo público nos blobs da base, de R10 e do head. O avanço por índices conserva a decisão nos quatro cenários de escala de R11. |
| `tests/check-worker-ahead.py`, `tests/check-worker.sh` | Os quatro cenários de R10 e os quatro de R11 passaram no head. R8, R9, reserva única e retomada concorrente emitiram seus marcadores uma vez. Nenhuma dessas sondas combina separador temático no item externo com uma tag personalizada na linha seguinte. |
| `commands/sdd-worker.md`, `docs/pipeline.md` | O contrato é o mesmo nas duas superfícies. A tag pode continuar um parágrafo de texto, e o título no HTML bruto fica fora da contagem. A decisão de R12 contraria esse contrato, não a redação. |
| `20-handoff-exec.md`, `checkpoint.md` | Os quatro casos de cada incremento, os contadores, os hashes e os marcadores do Check conferem. O resultado histórico foi corroborado pelo reteste, sem reaproveitar a saída da execução anterior. |
| `TODO.md`, `tests/health-baseline.txt`, `40-review-r7.md` | R11 reancorou um item existente e não acrescentou outro. A suíte confirmou 103 âncoras. A r7 serviu de referência para os achados anteriores e as notas. |

### Varredura de código morto, tipos e fronteiras

`ruff check --no-cache --select F401,F811,F821,F841 bin/sdd-worker-ahead tests/check-worker-ahead.py`
e `bash -n tests/check-worker.sh` saíram 0 no head. A varredura se limitou ao delta.
O laço usa índices inteiros e exige um casamento não vazio antes de avançar.
Os símbolos introduzidos têm consumidor e não houve remoção do último uso de um símbolo.
O delta não acrescentou chamada externa nem alterou as guardas de delegação, orçamento,
ownership ou reserva. O erro está na interpretação da referência local que condiciona o disparo.

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | B | O estado de parágrafo ainda é inferido pelo recuo de linhas que podem ser separadores reais. R12 mostra a divergência. |
| Type Safety | A | O deslocamento é inteiro, cresce a cada marcador e os grupos do casamento são usados depois da guarda. |
| Error Handling | B | O leitor aceita um título oculto e recusa um título visível em duas variantes da mesma entrada. O diagnóstico final do runner permanece intacto. |
| Security | B | Uma referência sem título visível iniciou o relay simulado. Delegação, orçamento e ownership ainda são exigidos. |
| Performance | A | No contador de correspondência integral, dobrar as listas passou de quase quatro vezes o trabalho para cerca de duas, com uma espera por caso. |
| Test Coverage | B | Os vermelhos históricos de R10 e R11 são discriminados, mas a suíte deixa passar R12. |
| Documentation | A | O procedimento e o pipeline preservam a distinção entre parágrafo e HTML. As alegações de R10 e R11 foram corroboradas pelo diferencial e pela suíte. |
| **Overall** | **B** | Melhorou a escala e os casos originais passaram, mas um erro novo ainda altera o disparo automático. |

## Achados da rodada

| # | Severidade | Achado | Onde |
|---|---|---|---|
| 1 | HIGH | Um separador temático com quatro espaços absolutos no item externo passa a marcar o estado como parágrafo. A tag personalizada na linha seguinte, já fora da lista, deixa de iniciar HTML. Um título oculto passa pela guarda do pedido, ou desqualifica um título visível legítimo. | `bin/sdd-worker-ahead:97–120` |

### Reprodução diferencial

Copiei `tests/check-worker-ahead.py` para `/tmp` e acrescentei os quatro casos abaixo
ao mapa de `--preceding-markup`, além de imprimir os eventos e o veredito antes das
asserções. Mantive o bloco público de `run` extraído de `commands/sdd-worker.md`, os
adaptadores e as asserções da fixture. Em cada cópia troquei apenas
`bin/sdd-worker-ahead` pelo blob de `git show "${rev}:bin/sdd-worker-ahead"`.
`cmp` confirmou o blob do head contra o checkout. Para reproduzir cada caso, rodei:

~~~bash
timeout 25s bash -c 'ulimit -v 262144; exec python3 "$@"' _ "$copia/probe.py" "$copia/$lado" --preceding-markup "$caso"
~~~

~~~python
prefix = "10. - <script></script>\n\n    ***\n<sample-box>\n"
instruction = "# Owner request\n\nPlan the next lot during the run.\n"
cases = {
    "thematic-after-html-hidden": (prefix + instruction, False),
    "thematic-after-html-visible": (prefix + "\n" + instruction, True),
    "thematic-after-html-duplicate": (instruction + "\n" + prefix + instruction, True),
    "thematic-after-html-root-duplicate": (instruction + "\n" + prefix + "\n" + instruction, False),
}
~~~

| Caso | Títulos visíveis no CommonMark | Base `fda9359e` | R10 `6402cbd8` e head `94efef27` |
|---|---|---|---|
| `thematic-after-html-hidden` | nenhum | `wait`, sonda 0 | `start, wait`, sonda 1 |
| `thematic-after-html-visible` | linha 6 | `start, wait`, sonda 0 | `start, wait`, sonda 0 |
| `thematic-after-html-duplicate` | linha 1 | `start, wait`, sonda 0 | `wait`, sonda 1 |
| `thematic-after-html-root-duplicate` | linhas 1 e 10 | `wait`, sonda 0 | `wait`, sonda 0 |

`MarkdownIt("commonmark", {"html": True})` 3.0.0 confirmou um separador temático dentro
do item, seguido por um novo bloco HTML fora da lista. O rastreio de `raw_html_end`
recebeu `in_paragraph=False` ao ler `***` nos três blobs. Ao chegar a `<sample-box>`,
recebeu `False` na base e `True` de R10 em diante. O teste de recuo agora usa
`html_line` e toma o separador sem recuo relativo por texto comum. Os quatro casos
preservaram uma espera, stderr vazio e
`verdict|3|phase-ceiling|sdd run stop: phase-ceiling — fixture`. A saída do bloco
público foi 0 em todos os casos. O código 1 da tabela é da asserção da sonda.

### Reteste de R10 e R11

- `compact-paragraph-unique` e `compact-paragraph-duplicate` saíram 1 na base pelas
  decisões invertidas e 0 de `6402cbd8` em diante. Os controles com linha em branco e
  código indentado saíram 0 nos três blobs.
- As listas de hífens e sinais de mais deram `start, wait` nos três blobs. Os dois
  separadores reais deram só `wait`. A sonda de escala falhou na base e em `6402cbd8`
  porque o contador de caracteres submetidos a correspondência integral deu
  4.018.015 e 16.036.015 para 2.000 e 4.000 marcadores. No head, deu 4.023 e 8.023
  para ambas as listas e saiu 0.
- O bloco público preservou uma espera e o mesmo veredito em todos os casos acima.
  Usei Git local, runner e relay simulados. Nenhum GitHub ou Codex real foi acionado.

## Incrementos de conserto (R<n>)

A rodada não corrige código. O executor fecha o incremento em uma sessão própria.

| R<n> | Achado | Check escrito no checkpoint |
|---|---|---|
| R12 | #1 | `o=$(bash tests/check-worker.sh 2>&1) && [ "$(grep -c '^  ok    owner request treats thematic breaks as paragraph boundaries before html$' <<< "$o")" = 1 ] && [ "$(grep -c '^  ok    owner request preserves paragraph after compact nested html$' <<< "$o")" = 1 ] && [ "$(grep -c '^  ok    owner request bounds compact list scan before wait$' <<< "$o")" = 1 ] && grep -c '^  ok    authorized ahead planning starts once before wait$' <<< "$o"` → `1` |

## O que virou incremento

- Achado #1 virou `R12`. A regressão usa a jornada pública de `run` para discriminar
  título só no HTML, um título válido junto a um título oculto e os dois controles de
  visibilidade. Deve preservar uma espera e o veredito, além dos Checks R10, R11 e da
  reserva única. O vermelho do head foi reproduzido nas duas variantes.
- `R10` foi fechado em `6402cbd8`. Os dois vermelhos originais deixaram de ocorrer e os
  controles permaneceram verdes. O separador temático antes do HTML é outro caso e não
  pede reverter a correção do parágrafo de texto.
- `R11` foi fechado em `20664af1`. As quatro decisões do fluxo público se mantiveram
  e o contador passou do crescimento quadrático para cerca do dobro ao dobrar a entrada.

## O que foi refutado

- **R12 foi introduzido pelo salto de sufixos de R11.** Os dois vermelhos já ocorrem em
  `6402cbd8`, antes dessa otimização. Os controles do R11 distinguem separador real de
  marcadores de lista e continuam verdes.
- **A tag no caso novo apenas continua o parágrafo do item externo.** O parser de
  referência reconheceu `***` como separador, sem abrir parágrafo. A variante com
  linha em branco entre a tag e o título expôs o título nos três blobs.
- **Os resultados do EXEC ficaram sem comprovação nesta rodada.** O primeiro log
  entregue à verificadora continha só o diferencial. Completei a evidência com
  `SDD_MUTATION_FIXTURE_ROOT="$PWD" tests/run-all.sh` no head congelado. O log da etapa
  do worker contém uma ocorrência exata de cada marcador de R8–R11, I14 e F1. Aplicar
  as expressões dos Checks a essa saída dá `1` para R8–R11. A suíte terminou com 21
  etapas, 113 sondas do worker e três casos `skipped` do Codex. Entre `20664af1`
  e o head não há diferença em `bin/`, `tests/`, `commands/`, `templates/`,
  `config/`, `.sdd/config.sh`, `docs/pipeline.md` ou `TODO.md`. O log original
  da execução não foi recuperado.
- **Não havia evidência de que R11 abriu zero itens.** O diff de
  `git diff --unified=0 2a7d8917..966a1200 -- TODO.md` adicionou zero linhas de
  abertura de item. A única mudança foi reancorar a entrada já aberta de 112 para 116.
  `tests/health-baseline.txt` não mudou nesse intervalo.

## Achados fora de escopo

Nenhuma entrada nova. O título na linha do marcador de lista continua no item já aberto,
com a âncora atualizada no EXEC. A lacuna histórica das sabotagens de R8 e o falso verde
preexistente de `local/ci` não foram reavaliados neste delta.

## Pendências / Decisions for a Human

Nenhuma. Em relação à r7, Performance e Documentation subiram de B para A e
nenhuma nota caiu. A evolução vem de verificações sobre dois commits de código.
O gate permanece aberto pelos critérios estritos em B e pelo R12 pendente.

## Boot da próxima fase

Leia R12 em `checkpoint.md`. Reproduza os casos `thematic-after-html-hidden` e
`thematic-after-html-duplicate` no head desta rodada usando a fixture pública de `run`.
Os dois controles devem ficar verdes. Preserve o parágrafo de texto do R10, o custo
de R11 e a reserva única. Não há necessidade de GitHub ou Codex reais.

## Ações recomendadas

- CRITICAL — nenhuma.
- HIGH — fechar R12 com vermelhos independentes do veredito de espera e retestar os controles.
- MEDIUM/LOW — nenhuma correção nova neste delta.

_Pegada de custo — skill Codex 2.27.38, verificação da instalação 2.30.2 aplicada
na triagem de prosa. Uma verificadora gpt-6.1-terra leu 17 unidades com 23 chamadas
declaradas. Código, varredura de símbolos e reproduções na sessão principal.
Custo faturado indisponível._
