# Notas de execução — L5: saída humana e contrato do runner

> **Append-only.** Uma linha por evento; nunca reescreva o arquivo, nunca o releia inteiro.
>
> Este arquivo nasceu em `20260904-a-dieta-de-contexto`, separado do `checkpoint.md` por medição:
> as notas eram **69% daquele arquivo** (67 166 B de 97 865 B em `20260901-o-revisor-so-acha`), e
> aquele arquivo era **44,7% de tudo que a missão releu** — 160 leituras, 1 114 571 B. Enquanto
> tabela e notas dividiam o arquivo havia um piso mecânico: em sessão headless o `Edit` exige um
> `Read` prévio, então toda sessão que atualizasse a tabela pagava o arquivo inteiro. Separadas,
> escrever nota é `>>` e custa **zero leitura**.
>
> O prompt de boot **inlina as últimas 10 notas** (`BOOT_NOTES_TAIL` no `bin/sdd`) e manda
> explicitamente **não abrir este arquivo**. Se você precisa de uma nota mais antiga, ela é
> história — e história se lê no `git log`, não no boot de toda sessão.

## Notas de execução

> Uma linha por evento relevante: bloqueio, decisão tomada, desvio do plano com justificativa.
> É o que a próxima sessão lê para não repetir um erro que já custou caro.

- 2026-11-21 18:48 · `PLAN` · plano escrito sobre `86e16c0`, com o L4 em execução e o PR #460 em revisão: antes do `sdd run`, a `main` entra neste branch e o `--anchors`, o `--check` e o `--red` rodam de novo (pendência 1 do `00-missao.md`)

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
> Desde 2026-09-03 o **runner escreve a linha sozinho** quando é ele quem recebe a mão do humano —
> `sdd run --phase X`, `sdd retry`, `--budget-override` — **e só na volta que abre sessão** (uma
> volta parada antes dela, por PLAN, carimbo, teto ou no-work, não grava nota), e a commita sozinha,
> na hora, para a árvore chegar limpa ao gate da fase seguinte. A linha escrita à mão continua valendo para o que
> o runner não vê: conserto manual, `BLOCKED` assumido. Fase feita à mão tem comando:
> `sdd note-manual <missão> <FASE>` escreve a nota e a linha `manual` do ledger, que não gradua
> nada — escrita só aqui, a fase não existe para o ledger. `sdd approve` não
> escreve nenhuma: aprovar o plano é o gate humano desenhado, não uma entrada na linha. A nota
> diz o que o runner **sabe** ("forçada pela CLI"), nunca quem estava na CLI: outro agente com
> shell entra pela mesma porta, e o runner não distingue — medido em 2026-09-03.
>
> O exemplo abaixo mora **dentro** desta citação de propósito: o `>` quebra o casamento com
> `^[[:space:]]*-`, e sem ele o exemplo era contado verbatim — todo checkpoint recém-instanciado
> nascia devendo uma intervenção fantasma ao instrumento que mede autonomia. Copie a forma para
> fora da citação ao registrar uma intervenção de verdade.
>
> - intervention: <o que o humano teve de fazer> — <fase> — <custo, se houver>

- 2026-11-25 10:02 · `I1` · TDD: três casos externos devolviam 0001 e o controle local passava. Após 436b1f2, Check `1 1 1 1`, suíte `tests/run-all.sh` verde (rc 0), e `ADR_alloc_refs_unread caught by check-adr.sh`, `ADR_alloc_worktrees_unread caught by check-adr.sh` e `ADR_alloc_source_unnamed caught by check-adr.sh`.
- 2026-11-25 10:48 · `I2` · TDD: cinco asserções vermelhas antes da correção. Após 8718ccf, Check `1 1 1 1 1` e suíte `tests/run-all.sh` verde (rc 0). Mutantes: `LINK_commands_unlinked caught by check-preflight.sh`, `LINK_commands_gitignore_dropped caught by check-preflight.sh`, `PRE_sdd_plan_missing_silent caught by check-preflight.sh` e `PRE_sdd_plan_kit_names_link_agents caught by check-preflight.sh`.
- 2026-11-25 11:30 · `I3` · TDD: a falta da receita deu Check `0 0`; em 03091ed, Check `1 1` e `tests/run-all.sh` verde (rc 0, zero FAIL). `HELP_run_detached_form_dropped caught by check-hat.sh` com `--only` em cópia temporária com os guias `finding-prs.md`, `plan-only.md` e `failure-modes.md`. A cópia padrão deu `HARNESS-BROKEN` no controle por faltar esses guias (registrado no `TODO.md`). A saída de suíte preexistente nas notas foi preservada fora dos commits.
- 2026-11-25 12:10 · `I4` · TDD: antes da correção, as duas consultas retornavam rc 0, mas trocavam o inode (Check `0 0`). Após 012044b, Check `1 1` e `tests/run-all.sh` verde (rc 0). `STATUS_leftovers_rewrites_index caught by check-gates.sh` e `WORKER_pr_ready_rewrites_index caught by check-worker.sh`. A saída preexistente de suíte neste arquivo foi preservada fora dos commits.
- 2026-11-25 13:02 · `I5` · TDD: os sete subcomandos não davam a recusa esperada, e `note-manual` alterava o HEAD do fixture (Check `0 0`). Após f7709e3, Check `1 1` e `tests/run-all.sh` verde (rc 0). `RUN_mission_dash_unrefused caught by check-gates.sh`. A âncora de `sandbox` no TODO foi realinhada. As alterações preexistentes neste arquivo foram preservadas fora dos commits.
- 2026-11-25 13:45 · `I6` · TDD: a receita não tinha `--no-track` nem na recusa nem na projeção (Check `0 0`). Após 0fe8217, Check `1 2` e `tests/run-all.sh` verde (rc 0, zero FAIL). `KAIZEN_remedy_tracks_the_base caught by check-kaizen.sh`. As alterações preexistentes nas notas ficaram fora dos commits.
- 2026-11-25 14:29 · `I7` · TDD: a recusa teve rc 75, mas faltava a dica (Check `0`). Após 1f8b722, Check `1`, consulta sem trava sem a dica e `tests/run-all.sh` verde (rc 0, zero FAIL). `COORD_busy_no_gates_unnamed caught by check-coordination.sh`. Quatro âncoras do TODO foram realinhadas. As alterações preexistentes neste arquivo ficaram fora dos commits.
- 2026-11-25 15:01 · `I8` · TDD: Check `0 0 1` antes (controle com o app respondendo já verde) e `1 1 1` após 51203f0. `tests/run-all.sh` verde (rc 0, zero FAIL). Os mutantes `STATUS_app_down_names_run` e `STATUS_app_down_closed_unsaid` foram detectados pelo `check-gates.sh`. Sem handoff, o gate recusa antes da e2e e o status não afirma que o app caiu. Foi registrado no TODO o controle de mutação que falhou sem o clone do fixture de fast-forward e passou na repetição. As alterações preexistentes nas notas ficaram fora dos commits.
- 2026-11-25 15:34 · `I9` · TDD: Check `0 0 0` antes e `1 1 1` após 70c956f. `tests/run-all.sh` verde (rc 0, zero FAIL). `RUN_complete_close_unnamed caught by check-kaizen.sh` e `STATUS_complete_close_unnamed caught by check-kaizen.sh`. Tirar a dica do template em cópia deixou `check-templates.sh` vermelho. Três âncoras do TODO foram realinhadas. A oração sobre listar o que o merge resolveu depende do I11. As alterações preexistentes nas notas ficaram fora dos commits.
- 2026-11-25 16:07 · `I10` · TDD de `0 0 0 0` para `1 1 1 1` em 5348c7d. `tests/run-all.sh` verde antes e depois (rc 0). Na cópia sob os mesmos tetos de 90 s e 1 GiB, o controle passou e o selftest reprovou (rc 92) tanto ao listar exemplo de bloco cercado quanto ao listar item da seção decidida. Espelho do chapéu idêntico após `./bin/sdd install --force`. As alterações preexistentes nestas notas ficaram fora dos commits.
