---
missao: 20260901-o-revisor-so-acha
atualizado: 2026-09-01 18:30
---

# Checkpoint — O revisor só acha

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
| I1 | o ledger carrega `turns`, e `sdd autonomy --by-mission` imprime o laço de revisão | `bash -n bin/sdd; o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    a session row carries the turns the session spent' <<< "$o"; grep -c '^  ok    the review loop counts REVIEW and the EXEC sessions after it, never the EXEC before' <<< "$o"` → `1` e `1` | pending | — |
| I2 | o contrato: o revisor só acha, achado vira incremento R — agente, executor, templates, prompt e `docs/pipeline.md` no mesmo commit | `o=$(bash tests/check-gates.sh 2>&1); grep -c '^  ok    a review graded B with a pending R1 hands the ball to EXEC' <<< "$o"; o2=$(bash tests/check-dry-run.sh 2>&1); grep -c '^  ok    the REVIEW boot prompt sends findings to R increments and never fixes in-session' <<< "$o2"; diff -q agents/sdd-reviewer.md .claude/agents/sdd-reviewer.md; echo rc=$?` → `1`, `1` e `rc=0` | pending | — |
| I3 | a guarda de aviso `REVIEW-EDITED-CODE`: sessão REVIEW que editou código fora do diretório da missão é registrada no `pipeline.log` | `o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    a REVIEW session that edited code outside the mission directory is logged REVIEW-EDITED-CODE' <<< "$o"; grep -c '^  ok    a REVIEW session that only wrote the round and the checkpoint is not flagged' <<< "$o"` → `1` e `1` | pending | — |
| I4 | docs: schema, failure-modes, `CONTEXT.md`, `KAIZEN_LOG.md` (antes), e `docs/graphify.md` entra na superfície do `check-lang` | `o=$(grep -l 'o-revisor-so-acha' KAIZEN_LOG.md CONTEXT.md docs/pipeline.md config/schema.md docs/failure-modes.md); wc -l <<< "$o"; s=$(sed -n '/^surface()/,/^}/p' tests/check-lang.sh); grep -c 'docs/graphify.md' <<< "$s"; bash tests/check-lang.sh >/dev/null 2>/dev/null; echo rc=$?` → `5`, `1` e `rc=0` | pending | — |

## Notas de execução

> Uma linha por evento relevante: bloqueio, decisão tomada, desvio do plano com justificativa.
> É o que a próxima sessão lê para não repetir um erro que já custou caro.

- 2026-09-01 18:30 · `PLAN` · plano nascido do grill com o humano presente (5 perguntas, 5 decisões); commit do grill já em disco (graphify + `CONTEXT.md` D22/D23). Ordem obrigatória: I1 → I2 → I3 → I4.

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
>
> ⚠️ **Nesta missão a fase REVIEW passa a fazer o mesmo** (é o objeto do I2): achado a consertar
> entra na tabela acima com ID `R<n>`, escrito pelo `sdd-reviewer`, e o `sdd-executor` o pega como
> qualquer linha `pending` — a REVIEW desta própria missão é a primeira a rodar nesse contrato.
