---
missao: 20260829-o-incremento-que-andou
atualizado: 2026-08-30 02:20
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
| I1 | o runner escreve `pending_before`, `pending_after` e `increments_total` na linha EXEC | `bash -n bin/sdd; o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    an EXEC row carries pending_before, pending_after and increments_total' <<< "$o"` → `1` | done | 4571faf |
| I2 | `outcome` lê o fato: incremento que andou é `advanced`, não `churned` | `o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    a session that advanced its increment reads advanced, not churned' <<< "$o"` → `1` | done | 4a33f78 |
| I3 | o caminho histórico: linha EXEC sem os campos lê o `N of M` do `gate_why`, declarado e contado | `o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    the historical path and the fields agree on one history' <<< "$o"` → `1` | done | 7615536 |
| I4 | o juiz lê `outcome`: `leve` só com churn real, `advance_rate` conta os incrementos | `o=$(bash tests/check-kaizen.sh 2>&1); grep -c '^  ok    a designed loop reads ok, and advance_rate counts the increments that advanced' <<< "$o"` → `1` | pending | — |
| I5 | docs, agente do juiz + espelho, `CONTEXT.md`, `KAIZEN_LOG.md` com antes → depois medidos | `o=$(grep -l 'o-incremento-que-andou' KAIZEN_LOG.md CONTEXT.md docs/pipeline.md agents/sdd-kaizen.md .claude/agents/sdd-kaizen.md); wc -l <<< "$o"; diff -q agents/sdd-kaizen.md .claude/agents/sdd-kaizen.md; echo rc=$?` → `5 e rc=0` | pending | — |

## Notas de execução

> Uma linha por evento relevante: bloqueio, decisão tomada, desvio do plano com justificativa.
> É o que a próxima sessão lê para não repetir um erro que já custou caro.

- 2026-08-29 21:30 · `plan` · plano fechado com o humano presente (6 decisões, § Decisões do grill do `00-missao.md`); branch criada de `chore/o-item-fechado-sai-do-todo` (PR #29), que é `main` mais o chore pós-merge do PR #28.
- 2026-08-29 23:10 · `I1` · **desvio do plano, com motivo medido: três mutantes em vez de dois.** O plano previa `LEDGER_progress_not_written` e `EXEC_tally_counts_done` e supunha que fora do EXEC os três campos ficariam vazios pelos defaults de `autonomy_session_row`. Não ficam: `GATE_EXEC_PENDING` sobrevive ao gate por construção (o `cmd_run` o lê uma tela depois da chamada), então os chamadores precisaram de guarda de fase — código novo, com modo de falha real, e mutante próprio (`LEDGER_progress_leaks_across_phases`). Catálogo 179 → 182.
- 2026-08-29 23:10 · `I1` · **a passada de sabotagem trocou o fixture da guarda de fase, e essa é a lição que a próxima sessão não deve repetir.** A primeira asserção `a non-EXEC row carries the three as null` foi escrita sobre o fixture `review→draft`, com o argumento de que `current_phase` avalia `gate_EXEC` a cada volta. Sabotagem verde: `current_phase` roda como `$(...)`, e os globais que ela seta morrem no subshell. O único mundo alcançável é um gate EXEC que passa no shell **pai** (a chamada `gate_"$phase"` da porta 1) seguido de outra volta — fixture `the EXEC counts do not follow the run into the next phase`. Argumento de alcançabilidade sem sabotagem que o prove é palpite: aqui apontava para o lado certo pelo motivo errado.
- 2026-08-29 23:10 · `I1` · o `mut_EXEC_tally_counts_done` mata 29 asserções e não só a nomeada, porque a contagem é UMA — sabotar o helper sabota junto a frase `N of M` do `gate_EXEC` e nenhum gate EXEC passa mais. É o desenho, não ruído: o assassino nomeado (`an EXEC row carries…`) reprova, e está declarado no comentário do mutante.
- 2026-08-30 00:40 · `I2` · **desvio do plano, com motivo medido: três mutantes e uma asserção a mais.** O plano previa um mutante (`AUTONOMY_progress_ignored`) e três asserções. `jq` ordena `null` abaixo de todo número, então `null < 2` é **verdade**: sem a guarda `pending_before != null and pending_after != null`, a sessão cujo gate **recusou** o checkpoint (publica `pending_after` null) leria como o progresso mais alto do ledger — fail-open na direção da lisonja, que é o que a missão inteira existe para impedir. A guarda é código novo com modo de falha real ⇒ linha `s5` no fixture, asserção `a gate that published no pending_after is not an increment that advanced` (dos dois lados: nem o histograma `4·1·1`, nem `33% waste`) e mutante `AUTONOMY_progress_null_blind`. Catálogo 182 → 184.
- 2026-08-30 00:40 · `I2` · **o fixture mudou de 5 para 6 linhas, e os números do plano com ele.** O plano dizia `3 advanced · 1 churned · 1 idle` a `40% waste`; com a linha da guarda de null são `3 advanced · 2 churned · 1 idle` a `50% waste`, contra `1·4·1` a `83%` da régua antiga e `4·1·1` a `33%` sem a guarda — três regimes, três histogramas distintos, nenhum alcançável por acidente. Os **nomes** das asserções, que são o contrato do Check, não mudaram.
- 2026-08-30 00:40 · `I2` · ⚠️ **o I3 não pode usar `has("pending_before")` como guarda.** Medido na própria linha desta missão no ledger real: `autonomy_session_row` monta o objeto com `($pbefore | tonumber? // null)`, então a **chave existe sempre**, com valor `null` na linha velha — `has(…)` responde `true` para todas as 49 linhas históricas e o caminho histórico não anotaria nenhuma. A guarda é `.pending_before == null`. (A linha da sessão do I1 é exatamente esse caso: escrita pelo runner carregado **antes** da edição do I1, ela tem os três campos `null` e `gate_why: "4 of 5 increment(s) still to execute"`.)
- 2026-08-30 00:40 · `I2` · os três mutantes foram provados em cópia antes do commit — aplica, `diff` mostra **uma** linha, `bash -n`, e o sensor nomeado fica vermelho na asserção nomeada. O `KAIZEN_outcome_inlined_old` foi rodado junto para provar que a asserção de paridade nova não é decoração: ela reprova sozinha com a cópia local na régua velha.
- 2026-08-30 02:20 · `I3` · **desvio do plano, com motivo medido: quatro mutantes em vez de um, e um quinto re-escrito.** O plano previa `AUTONOMY_historic_progress_dropped`. O caminho histórico tem quatro regras com modo de falha próprio (o caminho inteiro; M mudou; `pass` zera a memória; a guarda `.pending_before == null`), e cada uma vira um número errado numa direção diferente — regra sem probe é regra que ninguém percebe sair. Catálogo 184 → 188.
- 2026-08-30 02:20 · `I3` · ⚠️ **a sabotagem pegou um fixture que apontava para a regra certa pelo motivo errado, e essa é a lição desta sessão.** O primeiro fixture do `m4` (total que cresce) punha um `pass` antes do crescimento; o reset do `pass` limpava a memória primeiro, o `2 of 6` lia `advanced` sem a regra do M participar, e o `mut_AUTONOMY_historic_total_change_blind` **sobreviveu** — verde com a regra sabotada. O fixture foi reescrito sem nenhum `pass` na missão. Probe que não mata o mutante prova que o probe está errado, nunca que a regra é redundante.
- 2026-08-30 02:20 · `I3` · **o `mut_KAIZEN_outcome_inlined_old` teve de mudar de forma, e é achado, não capricho.** Ele apagava o splice e carregava a própria cópia de tudo que precisava manter vivo; com `historic_progress` no splice, a cópia deixou o `kaizen_series` sem a definição e o `jq` parou de compilar — o mutante passou a matar **dez** asserções em dois arquivos por CRASH, não pela divergência que existe para reproduzir. É exatamente o acidente que o comentário dele já avisara uma vez, sobre o `outcome_tally`. Agora ele **sombreia**: o splice fica e a cópia velha é anexada depois (o `jq` usa a última definição). Reproduz a mesma divergência e não envelhece a cada `def` novo. Provado: mata as três asserções de paridade e nada mais.
- 2026-08-30 02:20 · `I3` · a guarda de vacuidade do diferencial foi provada com sabotagem própria — com as duas âncoras do `grep` trocadas para casar nada, o diferencial compara `""` com `""` e passa; quem fica vermelha é `that agreement is not vacuous`. Diferencial sem testemunha de não-vacuidade é decoração.
- 2026-08-30 02:20 · `I3` · medido no ledger real depois do commit: `runner-sem-dividas` `5 advanced · 10 churned` → **`14 · 1`** (o alvo exato da métrica), versões a `100% waste` `49 de 107` → **`10 de 109`**, `51` linhas lidas da prosa. Suíte 678 → 689 `ok`.

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
