---
missao: 20261126-l5b-o-worker-e-os-verbos-dele
fase: REVIEW
rodada: 4
status: done
sessao: 01a21f2d-e475-75f0-93c9-d40c7b6d609d
data: 2026-11-27 20:03
gate: tests/run-all.sh em 13103d36ebf370347bf1aa12d914b5c489e49b9f → rc 0, suite green em 21 etapas, 108 sondas do worker, 101 âncoras de achados e 1.017 âncoras do catálogo. A etapa Codex registrou 3 skipped. Árvore limpa durante a suíte. REVIEW não passou. Platô mesmo após o conserto de R6. Code Quality (Zen), Error Handling, Security e Test Coverage permanecem em B. R7 pending.
reviewed_head: 13103d36ebf370347bf1aa12d914b5c489e49b9f
---

# Review — rodada r4 — O worker e os verbos dele

## TL;DR

O R6 fechou os dois casos da r3 em `9551b6e3`.
Uma falsa cerca dentro de HTML bruto faz o worker descartar um título visível ou aceitar um pedido ambíguo ou oculto.
O achado virou R7. As notas repetiram as da r3 e o gate não fechou.
Nenhum código foi alterado nesta revisão.

## Nota da rodada

Aplicado `codereview base=7ebeb5a93e1e9a7ccf0b84a41b5ebd601c93a5b3` até `13103d36ebf370347bf1aa12d914b5c489e49b9f`.
O delta tem quatro commits e nove caminhos, dos quais oito foram analisados. As notas de execução foram
excluídas da leitura e da varredura. Usei o handoff QA para a jornada original e conferi o fechamento
do R6 contra o checkpoint e o handoff EXEC. As sabotagens apontadas pelo EXEC não entram como
execuções desta revisão. Nenhuma interface mudou de nome neste delta.

### Detecção de segredos

| Resultado | Varredores | Arquivos | Linhas acrescentadas | Achados | Erros |
|---|---|---:|---:|---:|---:|
| PASS | `regex`, `gitleaks` | 8 | 248 | 0 | 0 |

No SHA revisado, executei
`git -P diff 7ebeb5a93e1e9a7ccf0b84a41b5ebd601c93a5b3...HEAD --unified=0 -- . ':(exclude)docs/handoffs/20261126-l5b-o-worker-e-os-verbos-dele/checkpoint-notas.md' |
bash /home/joruge/.agents/skills/codereview/scripts/scan_secrets.sh`.

### Cobertura e documentação do delta

| Caminho | Evidência |
|---|---|
| `bin/sdd-worker-ahead` | Único arquivo de produto alterado, com cobertura atualizada em `tests/check-worker-ahead.py` e `tests/check-worker.sh`. AST válida. Os controles de R6 ficaram vermelhos na base e verdes no head. |
| `tests/check-worker-ahead.py` e `tests/check-worker.sh` | Sintaxe verificada. Os 26 cenários de marcação conferem com a contagem de títulos ATX do `markdown-it` 3.0.0. O sensor confere a ordem e o número de eventos, stderr e o veredito da espera. |
| `commands/sdd-worker.md` e `docs/pipeline.md` | O contrato novo fala de cerca válida em item de lista, não de linhas que apenas parecem abrir uma cerca. Declara corretamente a política que o leitor tem de cumprir. |
| `20-handoff-exec.md`, `40-review-r3.md` e `checkpoint.md` | O fechamento de R6 tem um commit de código ancestral do head, dois casos observáveis e sensor na suíte. O falso verde já registrado na r2 não foi reaberto. |

Na saída da etapa do worker de `tests/run-all.sh`, cada asserção dos Checks R1 a R6 apareceu
exatamente uma vez, incluindo a jornada de reserva única.

### Varredura de código morto

Todos os nomes novos do leitor e da sonda têm consumidor no respectivo arquivo. No head revisado,
`ruff check --no-cache --select F401,F811,F821 bin/sdd-worker-ahead tests/check-worker-ahead.py`
saiu 0. O delta não acrescenta exportações nem remove o último consumidor de um símbolo.
O legado não foi varrido.

Para medir o custo local, comparei a função `local_anchors` extraída por AST nos dois SHAs.
Cada amostra repete 2.000 ou 4.000 vezes `"Texto sem marcação.\n\n- ```html\n  <!-- fechado -->\n\n"`
e termina com `"# Owner request\n"`. Ambos os leitores devolvem `['owner-request']`.
O mínimo de `timeit.repeat(lambda: reader(sample), number=20, repeat=5)` dividido por 20 foi
4,979 → 6,515 ms em 10.001 linhas e 9,975 → 12,963 ms em 20.001 linhas. A medição não inclui I/O.

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | B | A abertura da cerca em lista ainda depende só da forma da linha e desconsidera o bloco HTML que a contém. |
| Type Safety | A | Os grupos opcionais são verificados antes de indexar ou converter o marcador. O resultado continua sendo uma lista de fragmentos. |
| Error Handling | B | O título visível único cai silenciosamente na rota de sugestão por causa da falsa cerca. A espera conserva o diagnóstico do predecessor. |
| Security | B | O delta permite iniciar um turno simulado tanto com dois títulos visíveis iguais quanto com o único título dentro de comentário. Delegação e orçamento continuam exigidos. |
| Performance | A | A leitura local permaneceu linear na amostra. No head, 10.001 e 20.001 linhas levaram 6,515 e 12,963 ms, sem nova consulta externa. |
| Test Coverage | B | Os dez cenários do R5, os dezesseis do R6 e a jornada de reserva passam, mas faltam os três contrastes do R7. |
| Documentation | A | O runbook e o pipeline declaram que a cerca deve ser válida e a referência inequívoca. O handoff descreve a reprodução específica do R6, que foi confirmada. |
| **Overall** | **B** | O fix de R6 fecha os casos da r3, mas o novo reconhecimento de cerca troca a decisão de despacho nos três casos com bloco HTML bruto. |

## Achados da rodada

| # | Severidade | Achado | Onde |
|---|---|---|---|
| 1 | HIGH | Uma linha de HTML bruto que parece abrir cerca de lista cria uma cerca fantasma. O leitor oculta títulos visíveis ou deixa de reconhecer um comentário real. A referência passa a produzir a decisão de despacho oposta à esperada. | `bin/sdd-worker-ahead:67–90` |

### Reprodução

Usei o bloco público de `run` com a fixture de `tests/check-worker-ahead.py`, Git local, relay do kit
e adaptador simulado. Mantive comandos, fixture e relay iguais e troquei apenas
`bin/sdd-worker-ahead`. A base recebeu o blob da revisão anterior via
`git show 7ebeb5a93e1e9a7ccf0b84a41b5ebd601c93a5b3:bin/sdd-worker-ahead`. O head
recebeu o arquivo do checkout, idêntico ao blob de `git show HEAD:bin/sdd-worker-ahead`
segundo `cmp`. Não acionei GitHub nem Codex reais.

Acrescentei na cópia descartável da fixture, ao dicionário de `--preceding-markup`, as entradas abaixo.
Imprimi `events`, `result.stderr` e a última linha de `result.stdout` antes da asserção que compara
os eventos.

~~~python
# Dentro da fixture, `instruction` contém o título ATX e o pedido original.
block = "<div>\n- ```html\n  </div>\n\n"
cases = {
    "html-before-unique": (block + "  " + instruction, True),
    "html-before-duplicate": (
        instruction + "\n" + block + "  # Owner request\n\nDo not plan the next lot.\n", False
    ),
    "html-before-comment": (block + "  <!--\n\n" + instruction + "-->\n", False),
}
~~~

Com `MarkdownIt().parse(source)` do `markdown-it` 3.0.0, o prefixo até a primeira linha vazia forma
um bloco HTML, sem cerca nem lista. O oráculo contou, respectivamente, um título `Owner request`,
dois títulos iguais e nenhum título. No terceiro caso, o `<!--` está depois do bloco HTML e abre
o comentário que contém o título escrito com `#`.

Executei `timeout 30s python3 "$copia/check-worker-ahead.py" "$copia/$rev" --preceding-markup "$caso"`
nos dois lados. Os números na tabela são os rc da sonda, não os rc do predecessor.

| Caso | Base `7ebeb5a` | Head `13103d36` |
|---|---|---|
| `closed-comment` (R5) | `start, wait` · 0 | `start, wait` · 0 |
| `backtick-info` (R5) | `start, wait` · 0 | `start, wait` · 0 |
| `list-fenced-comment-marker` (R6) | `wait` · 1 | `start, wait` · 0 |
| `duplicate-after-list-code` (R6) | `start, wait` · 1 | `wait` · 0 |
| `html-before-unique` | `start, wait` · 0 | `wait` · 1 |
| `html-before-duplicate` | `wait` · 0 | `start, wait` · 1 |
| `html-before-comment` | `wait` · 0 | `start, wait` · 1 |

Nas 14 execuções houve um único `wait`, stderr vazio e
`verdict|3|phase-ceiling|sdd run stop: phase-ceiling — fixture`.
A linha `- ```html` aciona o novo ramo de `list_prefix` mesmo sem um item Markdown. O fechamento
indentado `</div>` e a linha vazia preservam o estado da cerca. No caso visível, o leitor então
trata o título com recuo de dois espaços como código. No caso do comentário, ignora o `<!--` com o mesmo recuo
e só abandona a cerca falsa no título sem recuo, que acaba contado.
O erro não dispensa a delegação, o orçamento nem a confirmação do dono do checkout. Dispensa, na
prática, a evidência inequívoca do pedido que libera o turno.

## Incrementos de conserto (R<n>)

| R<n> | Achado | Check escrito no checkpoint |
|---|---|---|
| R7 | #1 | `o=$(bash tests/check-worker.sh 2>&1) && [ "$(grep -c '^  ok    owner request ignores list fence lookalikes in raw html$' <<< "$o")" = 1 ] && grep -c '^  ok    authorized ahead planning starts once before wait$' <<< "$o"` → `1` |

## O que virou incremento

- `R7` — Distinguir uma linha dentro de HTML bruto de uma cerca aberta em item Markdown. Na jornada
  pública, o título único deve gerar `start, wait`. Título duplicado ou só dentro do comentário
  deve gerar apenas `wait`. Preservar `rc=3`, `phase-ceiling` e o diagnóstico da fixture em todos
  os casos. Manter os controles R5/R6 verdes e a reserva única nas retomadas.
- `R6` — Fechado em `9551b6e3`. Na comparação acima, a base falhou nos dois casos da r3 e o head
  passou em ambos. Na suíte, o sensor de R6 e a jornada de reserva única passaram.

## O que foi refutado

- **O R6 ainda perde o título depois de uma cerca real em lista.** O caso da r3 que fazia só
  `wait` na base fez exatamente `start, wait` no head. O controle de dois títulos trocou
  `start, wait` por apenas `wait`. O R7 depende de uma falsa abertura dentro de HTML bruto.
- **As aspas e quebras de linha da reprodução da r3 tornam a fixture e o comando inválidos.**
  Extraí o bloco Python literal de `40-review-r3.md:84–87` e
  `ast.parse("{" + trecho + "}")` devolveu um dicionário com duas entradas. A primeira string
  contém quebras de linha reais. Na linha 106, `shlex.split` separou o comando em cinco argumentos,
  sem aspas literais nos caminhos. Não há conserto de prosa a registrar.

## Achados fora de escopo

Nenhum achado novo fora de escopo. O falso verde de `local/ci` com `TEST_CMD` só de espaços já
está em `TODO.md`. O produtor não mudou neste delta, o caso não foi reexecutado e não houve nova
entrada em `RECURRED`.

## Pendências / Decisions for a Human

O conserto de R6 é real, mas as letras repetiram integralmente as da r3. A rodada registra o
platô em Code Quality (Zen), Error Handling, Security e Test Coverage e deixa a decisão de
retomar o ciclo com R7 ao mantenedor. Não é necessário iniciar a campanha real.

## Ações recomendadas

**CRITICAL**

Nenhuma.

**HIGH**

- Se o ciclo for retomado, fechar R7 em TDD com os três casos reproduzidos e preservar as jornadas
  de R5 e R6. A distinção a medir é se a linha pertence a um bloco HTML ou a um item Markdown.

**MEDIUM/LOW**

Nenhuma.

_Pegada de custo — skill Codex 2.27.38 indicada no boot. Registro Claude 2.30.2, com fluxo adicional de verificação de prosa que não foi usado nesta rodada. Dois agentes de documentação gpt-6.1-terra, 19 chamadas e oito leituras integrais reportadas. Código, testes, varredura e reprodução na sessão principal. Custo faturado indisponível._
