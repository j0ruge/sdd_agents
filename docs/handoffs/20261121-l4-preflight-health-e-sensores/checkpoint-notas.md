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
- 2026-11-21 20:36 · `EXEC` · I5 em `6ca6f20`: todo_preamble_verdict (chamada, publica global) compara o trecho até o 1º marcador com o template de hoje e com cada revisão do git do kit; kit sem git próprio (cópia dentro de outro repo inclusive) é unknown e cala; todo_template_for vira a escolha única do install; o TODO.md do kit sai author (dim), um template de 2026-10-24 sai stale; PRE_todo_preamble_stale_silent, PRE_todo_preamble_author_warned e INSTALL_todo_preamble_unchecked caught by check-preflight.sh; 23 âncoras remapeadas e a citação da linha 561 à mão; suíte verde (970 mutantes aplicam)
- 2026-11-21 21:05 · `EXEC` · I6 em `95598f4`: phase_skills_wanted + phase_skills_check <voz> (uma definição; o preflight só avisa, o run/retry param em uncovered e broken com bad + um die, antes do branch, dos gates e da sessão; dry-run avisa); isolate-git.sh exporta SDD_SKILLS_ROOT num diretório vazio por usuário; RUN_skill_uncovered_not_stopped, RETRY_skill_uncovered_not_stopped, RUN_skill_broken_not_stopped, RUN_skill_dry_run_stops e RUN_skill_missing_stops caught by check-preflight.sh, e os 7 mutantes do bloco antigo retargetados para a função nova (todos pegos por --only); 26 âncoras remapeadas, a do item 7 (bin/sdd:6361) e a citação da linha 561 à mão; check-preflight 190 ok; suíte verde (975 mutantes aplicam)
- 2026-11-21 21:36 · `EXEC` · I7 em `dfaeeb4`: run_check_cmd exporta SDD_CHECK_TAG (nome do log) só para o comando e publica LAST_CHECK_TAG; test_cmd_stragglers lê /proc/*/environ e devolve pid + comm; o preflight dá um warn por processo antes do veredito (até 10), sem argumentos nem argv[0] (o fixture usa exec -a l4argvsecret); sem shellcheck numa árvore com tests/check-mutation.sh, warn do lint pulado; verbete novo no failure-modes; PRE_test_cmd_stragglers_unnamed, PRE_test_cmd_stragglers_print_args e PRE_lint_absent_silent caught by check-preflight.sh; o `sleep 5 300` do plano dormiria 305 s (GNU soma os argumentos), trocado por exec -a; 42 âncoras remapeadas e a citação da linha 561 à mão; check-preflight 193 ok; suíte verde em 16 min 36 s (978 mutantes aplicam)
- 2026-11-21 22:17 · `EXEC` · I8 em `a3e4c86`: kit_stale_check (chamado, guarda KIT_STALE_SAID) no run, retry e preflight; branch padrão = origin/HEAD do kit (recuo origin/main, origin/master); kit sem git próprio pelo --show-toplevel igual ao SDD_HOME; repo_is_linked_worktree escolhe o remédio do chapéu não instalado (link-agents no worktree, install --force no principal); o probe da função remove o 'readonly SDD_HOME' ao sourçar, e as portas run e retry são medidas sobre o KP_REPO (o retry grava nota intervention ali, no fim do sensor); o Red da parte (b) foi provado pelo mutante, não antes da implementação; RUN_kit_off_branch_silent, RUN_kit_behind_silent, RUN_kit_reads_target_branch (check-preflight.sh) e RUN_agent_missing_worktree_names_install (check-dry-run.sh) caught por --only; 28 âncoras remapeadas e a do item 14 reapontada para `sdd install --force`; suíte verde (982 mutantes aplicam)
- 2026-11-21 22:44 · `EXEC` · I9 em `261acc8`: cmd_kaizen arma hat_guard_arm antes de cada run_phase KAIZEN, lê hat_guard_check "$phase" (before/after da sessão anterior) e para em hat_crossed_escalation "$phase" depois da linha de sessão; guarda de kit fora; o mutante "unarmed" tira os dois hat_guard_arm e é pego porque o mundo do juiz saudável deixa um README-human.md não rastreado antes da corrida (sem isso o arm não teria probe); KAIZEN_hat_guard_first_door_dropped, KAIZEN_hat_guard_retry_door_dropped e KAIZEN_hat_guard_unarmed caught by check-kaizen.sh; censo 13 → 15 portas, hat_guard_check 4 → 6 (o CLAUDE.md ainda diz 13: linha ⛔ da DOCS); 7 âncoras remapeadas pelo diff; suíte verde (985 mutantes aplicam)
- 2026-11-21 23:19 · `EXEC` · I10 em `21a9af7`: regra 7 do check-checkpoint.sh (frontmatter_updated + CLOCK_RE, V_CLOCK somado ao --check e ao scan, linha ok própria na varredura); 8 probes (PROBE_FLOOR 452 → 460, RULE_FLOOR 10 → 11); sabotagem à mão numa cópia em mktemp (timeout 300, grupo próprio): comparação que aceita tudo → probe do futuro e do scan vermelhos; V_CLOCK fora da soma do check_one → vermelho; scan sem rc=1 → vermelho; leitura além do frontmatter → probe do corpo vermelho; CLOCK_RE frouxo → placeholder e outra forma vermelhos; 2 âncoras do TODO.md remapeadas (linhas 81 e 139); suíte verde
