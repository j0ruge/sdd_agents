# Handoff — triagem do `TODO.md` (2026-08-17)

> **Não é uma missão.** É o material para planejar uma. Arquivo solto de propósito: missão é
> diretório em `docs/handoffs/<slug>/`, e este não deve ser confundido com uma.

## O número que importa

Medido nesta sessão, `git show 8ca54b8:TODO.md` contra o HEAD:

| | itens | linhas |
|---|---|---|
| início da sessão (`8ca54b8`) | 56 | 449 |
| agora (`5a0026e`) | **69** | 544 |

**16 itens foram fechados e apagados** com prova por `git merge-base` (5 do PR #4, 7 do #5, 4 do
#6). Ainda assim o arquivo cresceu **+13**, porque **29 nasceram**. Duas missões completas,
24 sessões, US$ 234,07 — e o backlog terminou maior do que começou.

Taxa de descoberta por dia: 11 (08-14) · 16 (08-15) · 29 (08-16) · 12 (08-17).
O kit produz dívida registrada ~1,8× mais rápido do que a fecha.

## Quem produz

| origem | itens |
|---|---|
| `sdd-reviewer` | 18 |
| `sdd-executor` | 15 |
| `humano` | 9 |
| `sdd-docs` | 6 |
| `/codereview` | 4 |
| `sdd-qa` | 2 |
| `revisao-adversarial` | 2 |

**47 de 68 (69%) vêm dos próprios agentes do pipeline.** Isso não é defeito — é o princípio 5
funcionando: achado fora de escopo vira item em vez de desvio. Mas significa que o backlog é
função da quantidade de missões, não do tamanho do produto: **rodar mais missões aumenta o
`TODO.md`.**

## Onde se acumula

| seção | itens |
|---|---|
| Sensores que faltam | **39** |
| Contrato e configuração | 10 |
| Saída humana e cosmética | 7 |
| Comentário e registro | 7 |
| Adiados por YAGNI | 3 |
| Idioma | 1 |
| Custo e escala | 1 |

57% numa seção só. E a maioria desses 39 não é sensor faltando para o **produto** — é sensor
faltando para o **sensor**: mutação não catalogada, asserção que não discrimina, probe ausente
para uma regra de um `check-*.sh`. O kit está gastando capacidade de melhoria medindo a própria
medição.

## Clusters — o que fecha em lote

A triagem item a item é cara e já foi feita aqui. O que sobra é agrupar. Seis grupos, com o que
têm em comum:

1. **Cosmético do `cmd_autonomy` (5)** — `US$ 2` sem casas · duas linhas em branco · `die` com a
   mesma mensagem para dois defeitos · bloco "no data" duplicado literalmente · tabela ordenando
   versão lexicograficamente. Todos em uma função, todos triviais, nenhum muda número.
   **Cabem num incremento só.** Hoje ocupam 5 itens do arquivo.
2. **Mutação faltando (5)** — duas asserções do ledger · partes do `cmd_kaizen` · três metades do
   `degraded` · call site do `ensure_mission_branch` no `cmd_retry` · `cmd_health` inteiro.
   Mesma forma: acrescentar entrada no catálogo. **Um incremento por grupo, não por item.**
3. **Asserção que não mede o que promete (9)** — os dois ramos do `differential()` · regra do `|`
   sem `doc_rule` · âncora satisfeita por código inline · cauda com travessão · caixa marcada na
   linha seguinte · `dry-run não toca no disco` · sensor pulado por `SDD_MUTANT` · `retry carries
   its own moved` · Check que nasce verde. **É a família mais perigosa** (falha aberta) e a que
   mais cresceu.
4. **Dívida da missão `portas-do-humano` (5)** — `sdd approve` diz "next" com gate fechado ·
   `frontmatter_write` (chmod/symlink/awk) · branch da fase TICKET · releitura pós-checkout ·
   `die` sem probe. Nasceram juntas há um dia; fecham juntas.
5. **Contrato prometido e não cumprido (4)** — 5 chaves fantasma do `schema.md` · `E2E_DIR` ·
   TICKET com agente E slash · `CHANGELOG.md` que a fase DOCS cobra e não existe. Todos são
   "decidir, depois implementar" — **cada um precisa de uma decisão sua**, não de código.
6. **Idioma / i18n (3)** — contrato PT-BR em 5 pontos · `templates/` single-language · 2 arquivos
   fora do sensor de idioma. Escopo grande, risco baixo, sem urgência.

Os 3 de **Adiados por YAGNI** ficam onde estão: são decisões de não-fazer, não dívida.

## O que NÃO é o problema

Verificado, para a próxima sessão não gastar dinheiro nisso:

- **Não é forma.** `tests/check-todo.sh` mede forma, âncora, data e teto de 8 linhas, com 75
  probes e selftest próprio. Verde em todas as medições de hoje.
- **Não é higiene de fechamento.** A convenção "fechado é apagado" funcionou três vezes hoje, cada
  uma com `git merge-base --is-ancestor` como prova. ⚠️ Uma armadilha real apareceu: dois itens
  citavam **hash composto** (`3547a83`+`abac043`, `c514e36+913cb3f`) porque o primeiro commit não
  fechou o achado sozinho. Extração ingênua por regex lê só o primeiro e conta itens a menos.
- **Não é falta de triagem.** Todo item tem âncora, direção e autor.

O problema é **volume e taxa**, e nenhum sensor mede isso hoje.

## A pergunta que precisa de decisão humana

Hoje qualquer agente registra qualquer achado, e o único filtro é "cabe em 8 linhas". Não há
critério de **admissão** — nada distingue "a suíte tem um ponto cego que deixa passar bug real"
de "`sdd autonomy` imprime duas linhas em branco". Os dois ocupam um item, e o segundo já está no
arquivo há dois dias.

Três saídas possíveis, todas exigindo sua decisão:

- **(a) Severidade na admissão** — o item nasce com `alta/média/baixa`, e o kaizen só tritura as
  altas. Barato, mas quem classifica é quem descobre, e o viés é conhecido.
- **(b) Teto duro por seção** — `check-todo.sh` reprova acima de N itens numa seção, forçando
  fechar antes de abrir. Jidoka de verdade, e desconfortável de propósito.
- **(c) Aceitar o crescimento como sinal, não como dívida** — o `TODO.md` é o registro de que o
  kit está sendo exercitado a sério. Nesse caso o que falta é uma **política de expiração**: item
  que ninguém tocou em N missões sai, com o motivo.

## Próximo passo sugerido

Um grill curto (2–3 perguntas) sobre a pergunta acima, e então uma missão de **lote**, não de
item: os clusters 1 e 2 juntos fecham 10 itens com trabalho mecânico e sem decisão nenhuma —
é o corte mais barato disponível e o único que não depende de você.

O cluster 3 é o que mais importa para a qualidade e o que menos cabe em lote: cada asserção
falha aberta por um motivo diferente.

## Contexto verificado (não re-descobrir)

- `TODO.md` no HEAD `5a0026e`: **68 achados**. ⚠️ `grep -c '^- \[ \]'` devolve **69** e está
  errado: a 69ª é a **linha de exemplo do formato**, dentro do bloco cercado do cabeçalho. O
  `check-todo.sh` pula blocos cercados de propósito — foi um estado que o parser precisou aprender
  numa rodada inteira de revisão. Contar itens com `grep` cru reintroduz o erro que o sensor
  resolve; use o sensor.
- Nenhum item traz `RESOLVIDO por` aberto: os quatro do PR #6 saíram em `5a0026e`.
- A missão `20260816-todo-enxuto` **não** foi sobre reduzir o arquivo: ela construiu o
  `check-todo.sh` (12 rodadas de revisão adversarial). O diretório só tem `r12-caixa-partida.*`.
- `docs/handoffs/` é a área PT-BR do repo; o resto de `docs/` é inglês por `check-lang.sh`.
