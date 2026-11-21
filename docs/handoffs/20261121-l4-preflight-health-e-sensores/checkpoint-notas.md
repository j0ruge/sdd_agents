# Notas de execução — L4: preflight, health e sensores

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

- 2026-11-21 04:39 · `PLAN` · plano escrito sobre `a0004df`; `--check` rc 0 (13 linhas) e `--red` rc 0 em duas corridas `--only` (I1 a I5, depois I6 a I13), as 13 vermelhas no HEAD; nenhum commit feito pelo planner; o `sdd run` só depois do merge do L3 e da `main` neste branch, com o `--check` e o `--red` de novo (pendência 1)

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

- 2026-11-21 18:29 · `EXEC` · I1 em `81f6ec6`: `read_rules_cover` lê a lista com `mapfile` (Red: 2 linhas `printf: ` com 400 entradas sob `trap '' PIPE`); a árvore suja nomeia até 10 caminhos e o `info/exclude` (por `git rev-parse --git-path`) só quando todos são `??`; PRE_read_rules_cover_stream_read, PRE_dirty_paths_unnamed e PRE_dirty_exclude_always_named caught by check-preflight.sh; 30 âncoras do TODO.md remapeadas pelo diff; suíte verde (957 mutantes aplicam)
- 2026-11-21 18:54 · `EXEC` · I2 em `641529b`: o ok da sonda do Bash lê o tool_result de um tool_use Bash com o marcador (casamento por tool_use_id, string ou lista de text); resposta sem a chamada é _fail; sem init o ok não afirma a lista de ferramentas; stub A carrega a chamada real; PRE_bash_probe_reads_answer, PRE_bash_probe_any_tool_result e PRE_bash_probe_tool_list_blind caught by check-preflight.sh (cada um na asserção própria); 18 âncoras remapeadas (remap.py --root no worktree); suíte verde (960 mutantes aplicam)
- 2026-11-21 19:28 · `EXEC` · I3 em `3612cb9`: sobre o stream da sonda do Bash e só com init, uma linha por hook_event (contagem, exit codes, bytes), warn pelo hook_name no hook com rc≠0 ou outcome≠success, _fail na skill de wanted ausente do .skills (predicado positivo, type == array); wanted subiu para antes da sonda; PRE_hooks_unlisted, PRE_hook_failure_silent, PRE_skill_absent_from_init_warned e PRE_skill_init_blind caught by check-preflight.sh (cada um na asserção própria); 19 âncoras remapeadas e a citação cruzada da linha 561 seguida à mão; suíte verde (964 mutantes aplicam)
- 2026-11-21 20:06 · `EXEC` · I4 em `9ef4cdc`: o preflight roda `check-todo.sh --check "$TODO_FILE" --allow-empty` do REPO_ROOT (ok com o resumo; warn com a contagem e as 3 primeiras, nunca _fail; a linha do opt-in só sem check-todo.sh no TEST_CMD; "not measured" sem arquivo, sem sensor ou rc fora de 0/1); o mundo limpo leva uma linha em branco para sujar a árvore como o malformado e a contagem de falhas comparar só o bloco; a violação do achado sem âncora e sem data conta 2, não 1; PRE_todo_shape_unmeasured, PRE_todo_shape_fails e PRE_todo_optin_always_named caught by check-preflight.sh; 18 âncoras remapeadas e 2 citações (linhas 561 e 775) seguidas à mão; suíte verde (967 mutantes aplicam)
