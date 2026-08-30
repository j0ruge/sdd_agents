---
missao: 20260829-o-incremento-que-andou
atualizado: 2026-08-29 21:30
---

# Checkpoint — o incremento que andou

> **Este arquivo é lido por máquina.** O runner faz parse da tabela abaixo para decidir a
> próxima fase. Não mude as colunas, não mude os tokens de status, não quebre linhas dentro de
> uma célula. Detalhe narrativo vai no `01-plano.md`, não aqui.
>
> ⚠️ **Nada de `|` cru na célula do Check.** A tabela é lida com `awk -F'|'`: um pipe cru parte a
> célula em duas, o Status lido passa a ser um pedaço do comando e o Commit passa a ser `pending`.
> O `gate_EXEC` reprova por "invalid status" e o `sdd status` imprime algo de aparência saudável —
> custou uma missão inteira até alguém olhar. O escape do GFM, `\|`, o runner **hoje entende**:
> `checkpoint_rows` remonta a célula por paridade de `\`, como o `gate_REVIEW` já fazia. Isso é
> rede de segurança, não licença — Check que precisaria de pipe continua virando herestring:
> `` o=$(cmd 2>&1); grep -c 'x' <<< "$o" ``, e o `tests/check-checkpoint.sh` recusa as duas formas
> nos checkpoints deste repo.
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
| I1 | o runner escreve `pending_before`, `pending_after` e `increments_total` na linha EXEC | `bash -n bin/sdd; o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    an EXEC row carries pending_before, pending_after and increments_total' <<< "$o"` → `1` | pending | — |
| I2 | `outcome` lê o fato: incremento que andou é `advanced`, não `churned` | `o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    a session that advanced its increment reads advanced, not churned' <<< "$o"` → `1` | pending | — |
| I3 | o caminho histórico: linha EXEC sem os campos lê o `N of M` do `gate_why`, declarado e contado | `o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    the historical path and the fields agree on one history' <<< "$o"` → `1` | pending | — |
| I4 | o juiz lê `outcome`: `leve` só com churn real, `advance_rate` conta os incrementos | `o=$(bash tests/check-kaizen.sh 2>&1); grep -c '^  ok    a designed loop reads ok, and advance_rate counts the increments that advanced' <<< "$o"` → `1` | pending | — |
| I5 | docs, agente do juiz + espelho, `CONTEXT.md`, `KAIZEN_LOG.md` com antes → depois medidos | `o=$(grep -l 'o-incremento-que-andou' KAIZEN_LOG.md CONTEXT.md docs/pipeline.md agents/sdd-kaizen.md .claude/agents/sdd-kaizen.md); wc -l <<< "$o"; diff -q agents/sdd-kaizen.md .claude/agents/sdd-kaizen.md; echo rc=$?` → `5 e rc=0` | pending | — |

## Notas de execução

> Uma linha por evento relevante: bloqueio, decisão tomada, desvio do plano com justificativa.
> É o que a próxima sessão lê para não repetir um erro que já custou caro.

- 2026-08-29 21:30 · `plan` · plano fechado com o humano presente (6 decisões, § Decisões do grill do `00-missao.md`); branch criada de `chore/o-item-fechado-sai-do-todo` (PR #29), que é `main` mais o chore pós-merge do PR #28.

> **Toda vez que um humano precisou entrar na linha** — um `sdd retry`, um conserto à mão, um
> `BLOCKED` assumido — sai uma linha com o marcador `intervention:`. É a **narrativa** do que o
> humano fez. O **número** de intervenções o `sdd autonomy --by-mission` lê do ledger, em
> `launch(es)` (`run_id` distintos — cada `sdd run`/`sdd retry`), e imprime estas notas ao lado
> como `intervention note(s)`. Medido em 2026-08-28: a missão de três lançamentos tinha zero
> notas — o contador não pode depender de alguém lembrar de escrever; a narrativa, sim, e é a
> única fonte que diz o que o humano *fez*.
>
> ⚠️ O marcador é **inglês e minúsculo**, como `pending`/`done`/`blocked`: é contrato, não prosa.
> O texto depois dos dois-pontos vai no idioma do `OUTPUT_LANG`, como o resto deste arquivo.
> Só conta quando abre a linha — `intervention` no meio de uma frase é prosa e não é contado.
>
> O exemplo abaixo mora **dentro** desta citação de propósito: o `>` quebra o casamento com
> `^[[:space:]]*-`, e sem ele o exemplo era contado verbatim — todo checkpoint recém-instanciado
> nascia devendo uma intervenção fantasma ao instrumento que mede autonomia. Copie a forma para
> fora da citação ao registrar uma intervenção de verdade.
>
> - intervention: <o que o humano teve de fazer> — <fase> — <custo, se houver>

## Incrementos de fix (QA)

> Escritos pelo `sdd-qa` quando um bug sanável é reprovado. Entram na mesma tabela acima com ID
> `F<n>`, e o Check obrigatoriamente inclui **regression test passa** + **re-walk da jornada
> impactada verde**. Bug que exige julgamento humano NÃO vira fix — vai para
> "Decisions for a Human" no handoff de QA.
