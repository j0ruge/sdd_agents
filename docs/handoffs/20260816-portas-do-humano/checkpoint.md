---
missao: 20260816-portas-do-humano
atualizado: 2026-08-16 22:40
---

# Checkpoint — as portas de controle do humano

> **Este arquivo é lido por máquina.** O runner faz parse da tabela abaixo para decidir a
> próxima fase. Não mude as colunas, não mude os tokens de status, não quebre linhas dentro de
> uma célula. Detalhe narrativo vai no `01-plano.md`, não aqui.
>
> ⚠️ **Nada de `|` na célula do Check — nem escapado como `\|`.** O parser é `awk -F'|'` cru e
> não conhece o escape do GFM: a célula vira duas, o Status lido passa a ser um pedaço do
> comando e o Commit passa a ser `pending`. O `gate_EXEC` reprova por "invalid status" e o
> `sdd status` imprime algo de aparência saudável — custou uma missão inteira até alguém olhar.
> Check que precisaria de pipe vira herestring: `` o=$(cmd 2>&1); grep -c 'x' <<< "$o" ``.
>
> ⚠️ **Check que lê a saída de um sensor ancora em `^  ok    ` — quatro espaços, com o `^`.**
> Todo sensor da suíte imprime `  ok    <asserção>` na **stdout** e `  FAIL  <asserção>` na
> **stderr**, com o *mesmo* `<asserção>`. Um Check que faz `2>&1` e grepa o texto solto devolve o
> mesmo número com a asserção verde e com ela vermelha: ele responde "a asserção existe", nunca
> "a asserção passou". Custou uma missão inteira, achado só na fase QA. A forma certa:
> `` o=$(bash tests/check-x.sh 2>&1); grep -c '^  ok    <asserção>' <<< "$o" `` → `1`.
> O sensor é `tests/check-checkpoint.sh`.
>
> Atualizar o checkpoint é o **último ato** de cada incremento — depois do commit, nunca antes.
> Status válidos: `pending` · `doing` · `done` · `blocked`.

| ID | Incremento | Check (comando → esperado) | Status | Commit |
|---|---|---|---|---|
| I1 | `sdd approve`: o gate humano ganha comando | `o=$(bash tests/check-gates.sh 2>&1); grep -c '^  ok    sdd approve' <<< "$o"` → `3` | done | 96a1f68 |
| I2 | o runner troca para a branch declarada | `o=$(bash tests/check-gates.sh 2>&1); grep -c '^  ok    branch ' <<< "$o"` → `3` | done | b3b8c2f |
| I3 | `sdd retry` vira a quarta porta com aviso | `o=$(bash tests/check-gates.sh 2>&1); grep -c '^  ok    retry ' <<< "$o"` → `2` | pending | — |
| I4 | plano kaizen-born nunca se auto-aprova | `o=$(bash tests/check-gates.sh 2>&1); grep -c '^  ok    kaizen-born' <<< "$o"` → `3` | pending | — |

## Notas de execução

> Uma linha por evento relevante: bloqueio, decisão tomada, desvio do plano com justificativa.
> É o que a próxima sessão lê para não repetir um erro que já custou caro.

- 2026-08-16 21:15 · `PLAN` · os 4 Checks rodados contra o HEAD (`c2c8e73`): todos `0`
  (vermelhos), `tests/check-gates.sh` verde (rc 0) — nenhum Check nasce verde.
- 2026-08-16 21:15 · `PLAN` · prefixos de asserção são contrato com os Checks: `sdd approve `,
  `branch `, `retry `, `kaizen-born` — nomear exatamente assim em `tests/check-gates.sh`.
- 2026-08-16 · `I1` · **desvio da decisão 2 do grill, deliberado:** o assunto do commit do
  `sdd approve` é `chore(missao): plan <missão> approved by the human` (inglês, escopo `missao`
  mantido), não a frase pt-BR do `00-missao.md`. O runner é superfície do kit e roda em repo de
  qualquer `OUTPUT_LANG`, e aqui é o único escritor — não há sessão para escrever no idioma alvo.
  Além disso `pelo` está na lista de stopwords do `tests/check-lang.sh`, que mede o `bin/sdd`: a
  frase original é insatisfazível ali. Quem depender do assunto exato (I2/I3/I4, DOCS, PR) leia
  esta linha antes de "corrigir".
- 2026-08-16 · `I1` · o comando imprime o **corpo inteiro** da missão, não seção por seção: os
  headings (`## Pendências para o humano`) são conteúdo em `OUTPUT_LANG`, e um runner que os
  grepasse funcionaria só em repo pt-BR. O fixture do sensor, por isso, não precisa dos headings
  pt-BR — quem guarda esse contrato é o `tests/check-templates.sh`.
- 2026-08-16 · `I1` · passada de sabotagem adversarial: **11 degradações, 10 vermelhas** pela
  asserção pretendida (resposta ignorada, commit varrendo a árvore, sem idempotência, `sed` no
  arquivo inteiro, corpo/incrementos/`titulo:` não impressos, gate ignorando `humano-*`, sem
  `git add`). A 11ª — remover a guarda de read-back — sobrevive verde e está no `TODO.md`.
- 2026-08-16 · `I2` · **o placeholder que o plano cita não existe.** `00-missao.md` (decisão 6) e
  `01-plano.md` dizem `<criada pela fase TICKET>`; `templates/missao.md:6` ship `<nome da branch
  de trabalho>`, e `grep -r` não acha a primeira em lugar nenhum do kit. A guarda casa `'<'*`,
  então cobre as duas — mas o fixture agora **lê** o placeholder do template, e foi ler que achou.
  Quem for escrever fixture nesta missão: copie da fonte, não da prosa do plano.
- 2026-08-16 · `I2` · `templates/missao.md` entrou no commit do incremento, fora do "Onde" do
  plano (que dizia só `bin/sdd`): o campo `branch:` deixou de ser decorativo e virou carga lida
  pelo runner, e contrato de artefato muda nos três lugares no MESMO commit (regra do `CLAUDE.md`).
  **Sobra para a fase DOCS:** `docs/pipeline.md` não documenta o campo em lugar nenhum — não é
  drift criado aqui, mas agora é drift que importa.
- 2026-08-16 · `I2` · o sensor tem **5** asserções, e só 3 levam o prefixo `branch ` que o Check
  conta. As outras duas (checkout recusado ⇒ `die`; `sdd retry` como segundo call site) nasceram
  da sabotagem e são nomeadas fora do prefixo de propósito: `branch ` e `retry ` são os Checks
  deste incremento e do I3, e asserção que infla a contagem do vizinho transforma contrato em
  coincidência.
- 2026-08-16 · `I2` · passada de sabotagem: **21 degradações em 3 rodadas**, parando na rodada que
  não achou nada. As 2 sobreviventes da r1 viraram asserção (`die`→`warn`, a pior: o run SEGUE, que
  é a classe SQ-97; e a linha BRANCH do `pipeline.log`). A r2 achou um **fail-open no que a r1
  tinha acabado de consertar**: sem a asserção positiva do anúncio, a de "no-op silencioso" fica
  verde num runner que nunca anuncia nada — par presente/ausente, nunca só a ausência.

## Incrementos de fix (QA)

> Escritos pelo `sdd-qa` quando um bug sanável é reprovado. Entram na mesma tabela acima com ID
> `F<n>`, e o Check obrigatoriamente inclui **regression test passa** + **re-walk da jornada
> impactada verde**. Bug que exige julgamento humano NÃO vira fix — vai para
> "Decisions for a Human" no handoff de QA.
