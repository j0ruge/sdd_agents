---
missao: 20261126-l5b-o-worker-e-os-verbos-dele
fase: REVIEW
rodada: 3
status: done
sessao: 01a21efa-2229-73a2-af42-f001f41e0881
data: 2026-11-27 19:01
gate: tests/run-all.sh em 7ebeb5a93e1e9a7ccf0b84a41b5ebd601c93a5b3 → rc 0, suite green, 107 sondas do worker e 1.017 âncoras do catálogo. A etapa Codex registrou 3 skipped. Árvore limpa durante a suíte. REVIEW não passou. Code Quality (Zen), Error Handling e Test Coverage continuaram em B, Security caiu de A para B. R6 pending.
reviewed_head: 7ebeb5a93e1e9a7ccf0b84a41b5ebd601c93a5b3
---

# Review — rodada r3 — O worker e os verbos dele

## TL;DR

Os dois casos da r2 estão fechados em `ebeda0b`. Os dez cenários do R5 passaram.
A marca de comentário dentro de código em lista faz o worker rejeitar um título válido ou aceitar uma referência ambígua.
O achado virou R6. Security caiu de A para B e o gate não fechou.
Não houve alteração de código.

## Nota da rodada

A revisão aplicou `codereview base=65862f397633e348b2bf430cbcd08a0953797076` até
`7ebeb5a93e1e9a7ccf0b84a41b5ebd601c93a5b3`, com três commits e 11 caminhos no inventário.
Foram usados o handoff da QA, o fechamento do EXEC e os casos deixados pela r2. O conteúdo de
`checkpoint-notas.md` não foi lido nem varrido. As notas fornecidas no boot registram as 15 sabotagens
do EXEC. A REVIEW não as contou como execuções próprias.

### Detecção de segredos

| Varredores | Arquivos | Linhas acrescentadas | Achados | Erros |
|---|---:|---:|---:|---:|
| `regex`, `gitleaks` | 10 | 257 | 0 | 0 |

`git -P diff 65862f397633e348b2bf430cbcd08a0953797076...HEAD --unified=0 -- . ':(exclude)docs/handoffs/20261126-l5b-o-worker-e-os-verbos-dele/checkpoint-notas.md'`
foi entregue a `bash /home/joruge/.agents/skills/codereview/scripts/scan_secrets.sh` no SHA revisado.

### Cobertura do delta

| Caminho | Evidência no SHA revisado |
|---|---|
| `bin/sdd-worker-ahead` | Único arquivo de produto alterado. Sintaxe Python válida. As dez execuções de `python3 tests/check-worker-ahead.py "$PWD" --preceding-markup <caso>` e a execução com `--owner-request` saíram 0. |
| `tests/check-worker-ahead.py` e `tests/check-worker.sh` | Sintaxe Python e Bash válidas. A sonda do R5 mede número e ordem dos eventos e o resultado da espera. Duas entradas novas ficam vermelhas na cópia usando a mesma sonda. |
| `commands/sdd-worker.md` e `docs/pipeline.md` | A referência deve apontar para um título fora de cerca e comentário. O achado contraria essa regra no leitor, sem exigir mudança de regra. |
| Handoff EXEC, relatório r2 e checkpoint | O hash e os casos de R5 conferem com o diff, os retestes e o estado dos incrementos. O falso verde já registrado na r2 não foi reaberto. |

Na varredura de código morto do delta, as novas variáveis do leitor e da sonda têm consumidores
nos respectivos arquivos. A busca no trecho alterado e `ruff check --no-cache --select F401,F811,F821 bin/sdd-worker-ahead tests/check-worker-ahead.py`
não apontaram import ou símbolo órfão. Não houve varredura de legado.

No ensaio de `local_anchors` extraído por AST dos dois blobs Git, 1.000 e 10.000 linhas de texto
mais um título custaram 0,088 e 0,901 ms na base e 0,541 e 5,430 ms no head. Foi usado o menor de três
lotes de 20 chamadas via `timeit.repeat`, dividido por 20. A leitura local ficou mais cara, mas
a amostra cresceu na proporção da entrada e o despacho não acrescentou consulta remota.

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | B | O leitor confunde texto de código em lista com comentário HTML aberto e descarta o título real. |
| Type Safety | A | O delta manipula somente linhas e grupos de regex após a correspondência, sem alterar os tipos do resultado ou o contrato do fragmento. |
| Error Handling | B | O fragmento válido cai na rota silenciosa de pedido ausente. A espera mantém o veredito original, mas não há turno nem diagnóstico da recusa indevida. |
| Security | B | O caso diferencial com dois títulos visíveis iniciou o relay no head. O leitor descartou o segundo título e aceitou uma referência que a base recusava como ambígua. |
| Performance | A | A amostra de 10.000 linhas ficou em 5,430 ms na leitura local. A jornada coberta preserva o turno único por sucessor e não acrescenta consulta remota ao parse. |
| Test Coverage | B | Os dez cenários de R5 passaram, mas não cobrem a marca de comentário numa cerca aberta por item de lista. Com esse conteúdo, ficam vermelhos tanto o controle único quanto o ambíguo. |
| Documentation | A | Runbook e pipeline descrevem a exigência correta, e a evidência sustenta os dois reparos descritos no handoff. O desvio confirmado é do leitor. |
| **Overall** | **B** | R5 resolveu os dois casos anteriores, mas outra entrada do mesmo leitor tanto impede um despacho válido quanto permite um despacho com referência ambígua. |

Houve progresso nos dois casos anteriores. Code Quality (Zen), Error Handling e Test Coverage
permaneceram em B, e Security caiu de A para B. O ciclo de revisão para aqui pela queda de nota.
O Check de R6 registra o trabalho necessário para retomar.

## Achados da rodada

| # | Severidade | Achado | Onde |
|---|---|---|---|
| 1 | HIGH | Uma marca de comentário dentro de uma cerca em lista oculta títulos reais do leitor. O worker deixa de iniciar um PLAN autorizado ou inicia um PLAN com referência ambígua, conforme a posição dos títulos. | `bin/sdd-worker-ahead:64–68` |

### Reprodução

Acrescentei somente duas entradas ao dicionário de `--preceding-markup` e a impressão do rastro
em cópias descartáveis de `tests/check-worker-ahead.py`:

~~~python
"list-fenced-comment-marker": ("- ```html\n  <!--\n\n" + instruction, True),
"duplicate-after-list-code": (instruction + "\n- ```html\n  <!--\n\n# Owner request\n\nDo not plan the next lot.\n", False),
~~~

O conteúdo da fonte no caso de título único é:

~~~markdown
- ```html
  <!--

# Owner request

Plan the next lot during the run.
~~~

`markdown-it` 3.0.0, chamado com esse arquivo, emitiu `&lt;!--` dentro de
`<pre><code class="language-html">` e `<h1>Owner request</h1>` depois de `</ul>`. A cerca
termina no fim do item de lista. Não há comentário HTML envolvendo o título. No caso ambíguo,
o mesmo comando emitiu dois títulos de nível 1 com o mesmo texto e as duas instruções
contraditórias fora do código.

Executei a fixture como `python3 "$copia/check-worker-ahead.py" "$copia" --preceding-markup "$caso"`
com o procedimento público, Git local, relay real e adaptador simulado. Entre as duas cópias,
só troquei o despachante pelo blob `bin/sdd-worker-ahead` do SHA indicado, extraído com `git show`.

| Caso | `65862f3` (rastro e rc da sonda) | `7ebeb5a` (rastro e rc da sonda) |
|---|---|---|
| Título sem prefixo | `start, wait` · 0 | `start, wait` · 0 |
| Cerca em comentário encerrado | `wait` · 1 | `start, wait` · 0 |
| Crases inválidas na informação da cerca | `wait` · 1 | `start, wait` · 0 |
| Título em comentário real | `start, wait` · 1 | `wait` · 0 |
| Título após cerca dentro de lista, com `<!--` no código | `start, wait` · 0 | `wait` · 1 |
| Título repetido depois do mesmo bloco | `wait` · 0 | `start, wait` · 1 |

Nos doze ensaios da tabela, houve uma única espera, stderr vazio e
`verdict|3|phase-ceiling|sdd run stop: phase-ceiling — fixture`. O leitor não reconhece a
abertura da cerca na linha iniciada pelo marcador da lista. No head, ele passa a tratar o
`<!--` seguinte como abertura de comentário e pula também o título fora da lista.
Com um único título depois do bloco, o pedido não aciona o sucessor e sobra a rota manual.
Com dois títulos iguais, o leitor conta só o primeiro e trata como suficiente uma referência
ambígua. A autoridade e o orçamento da campanha seguem exigidos, mas não substituem o pedido
inequívoco. O lançamento medido foi só no adaptador simulado, sem chamadas reais ao GitHub ou ao
Codex.

## Incrementos de conserto (R<n>)

| R<n> | Achado | Check escrito no checkpoint |
|---|---|---|
| R6 | #1 | `o=$(bash tests/check-worker.sh 2>&1) && [ "$(grep -c '^  ok    owner request distinguishes unique and duplicate headings after list code$' <<< "$o")" = 1 ] && grep -c '^  ok    authorized ahead planning starts once before wait$' <<< "$o"` → `1` |

## O que virou incremento

- `R6` — Acrescentar os dois casos à jornada pública de `run`. Exigir exatamente um `start` antes do único `wait` para o título único e só `wait` quando houver dois títulos iguais. Em ambos, manter `rc=3`, `phase-ceiling` e o diagnóstico original do predecessor. O segundo sensor conserva a jornada de reserva única, retomada e revalidação. Os casos anteriores de R5 devem continuar verdes, inclusive a recusa de títulos em comentário ou cerca reais.
- `R5` — Fechado em `ebeda0b`. A execução comparativa mostra os dois falsos negativos passando de `wait` para `start, wait`. O controle com o título no comentário real passou de `start, wait` para somente `wait`. Os dez cenários normais do R5 saíram 0 no head.

## O que foi refutado

- **R5 ainda rejeita os dois pedidos válidos da r2.** Os casos `closed-comment` e `backtick-info` da tabela dispararam exatamente um turno antes da espera no head e não disparavam na base.
- **O estado novo de comentário esconde também um título após uma cerca de topo devidamente fechada.** O caso `comment-in-fence` de `tests/check-worker-ahead.py:180` saiu 0 e exigiu `start, wait`, stderr vazio e o mesmo veredito. O falso negativo reproduzido depende da cerca aberta pelo item de lista.
- **O handoff EXEC comprova que qualquer título visível funciona.** O registro em `20-handoff-exec.md:61–64` nomeia dois casos e os controles executados, que foram confirmados. A amostra nova refuta a generalização, não a medição original. A divergência observada no runbook e no pipeline tem a mesma causa do achado #1 e não constitui um achado de prosa separado.

## Achados fora de escopo

Nenhum achado novo. O falso verde de `local/ci` com `TEST_CMD` só de espaços permanece aberto em
`TODO.md` desde a r2. O produtor não mudou neste delta, o caso não foi reexecutado e não houve
nova entrada em `RECURRED`.

## Pendências / Decisions for a Human

A queda de Security pede decisão sobre retomar o ciclo com R6. Não há decisão de produto em aberto nem
necessidade de executar a campanha real.

## Ações recomendadas

- **CRITICAL** — nenhuma.
- **HIGH** — se o ciclo for retomado, fechar R6 em TDD com os dois casos reproduzidos e a jornada de turno único.
- **MEDIUM/LOW** — nenhuma.

_Pegada de custo — skill codereview 2.27.38 indicada no boot, registro do plugin Claude em 2.30.2. Dois agentes de documentação gpt-6.1-terra, 10 chamadas e seis leituras integrais reportadas no total. Código, varredura e reproduções na sessão principal. Custo faturado indisponível._
