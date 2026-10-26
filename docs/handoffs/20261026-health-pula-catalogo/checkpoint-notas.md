# Notas de execução — o `sdd health` pula o catálogo com a chave já medida

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

- 2026-10-26 00:28 · `PLAN` · plano escrito pelo `sdd-planner` (agente genérico com o contrato `agents/sdd-planner.md`, relay do `/sdd-plan`); base `c114e36`; a linha `RECURRED 6` do achado do `/sdd-plan` (`TODO.md:225`) fica sem commit até o `sdd approve`, por ordem do humano

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
- 2026-10-26 01:08 · `EXEC I1` · RED: `bash tests/check-gates.sh` no `bin/sdd` do HEAD `f7f6cc2`, só com o mundo 14 escrito → rc 1, única falha `stamp: gate_PR reads the key a linked worktree stamped…` com `expected DONE|PR, got PR|DONE` (o leitor velho: a worktree gravou no `.sdd/logs/` dela, e o arquivo velho forjado abriu o gate); o Check deu `0`. A sonda da linha 6 do `check-hat.sh` nasceu vermelha também (`got red 0 and green 1`).
- 2026-10-26 01:08 · `EXEC I1` · `--only PR_stamp_dir_per_worktree check-gates.sh` → exit 0 (pego). Medido sem `SDD_MUTANT`: morre só no mundo 14, `PR|PR`.
- 2026-10-26 01:08 · `EXEC I1` · `--only PR_stamp_valid_any_key check-gates.sh` → exit 0 (pego). Medido sem `SDD_MUTANT`: o mundo 4 lê `DONE` (dentro do `gate_PR: the mutation stamp is demanded…`); a primeira a morrer na rodada é a do 4b (`run stops at the stamp: rc 2, …`), e a do 11b também morre.
- 2026-10-26 01:08 · `EXEC I1` · `--only HEALTH_release_line6_blind check-hat.sh` → exit 0 (pego), pela asserção nova `release: line 6 reads the key from the git common dir…` (`got red 0 and green 1`).
- 2026-10-26 01:08 · `EXEC I1` · decisões fora da letra do plano: `git worktree add --detach` no mundo 14, para o fixture não guardar uma branch `kit-wt`; o `mutation_stamp_dir` tem o arm do git < 2.31 do `ledger_repo_root` (`cd` + `pwd -P`), sem sonda (D15, declarado no comentário); o arquivo do carimbo já leva a procedência (`measured:`, `root:`, a linha `score:`), e o `ok` diz onde gravou; `CAPTURE_FLOOR` 40 → 45; 10 âncoras do `TODO.md` reancoradas na mesma linha de código (a de `:7311` passava por acaso noutra ocorrência de `--with-mutation`).
- 2026-10-26 01:08 · `EXEC I1` · o `--audit` da `todo-to-github-issues` acusa 1 AUTO e 2 MANUAL na linha `RECURRED 6` (`TODO.md:225`, 217 colunas, do `f7f6cc2`), anterior a este incremento; o sensor do kit a aceita (`before clean`). Não mexi: a linha é do humano.
- 2026-10-26 01:08 · `EXEC I1` · correção da nota das decisões: as âncoras reancoradas são **9**, não 10 — 8 do `bin/sdd` (`7311 11792 12051 8555 7896 7839 9368 11920`) e a do `tests/check-mutation.sh:7550` (`KILLERS_FILE`, agora `:7576`).
- 2026-10-26 01:42 · `EXEC I1` · fix round 1 (`b7667e4`): o achado Important da revisão — o `mutation_stamp_dir` era uma segunda cópia da resolução do `ledger_repo_root`, sem sensor, com um comentário falso — virou o helper `git_common_dir_abs`, chamado pelos dois; o `ledger_repo_root` responde byte a byte igual ao do HEAD em 36 casos (9 formatos × git 2.43 e shim pré-2.31 × `CDPATH` limpo e envenenado). `--only` → exit 0 (pego) em todos: `LEDGER_repo_root_common_parent`, `_cdpath_leak`, `_newline_emptied`, `_toplevel`, `_shape_blind`, `_bypasses_shim` contra `check-autonomy.sh`, e `PR_stamp_dir_per_worktree` contra `check-gates.sh`. `CAPTURE_FLOOR` 45 → 43; nenhuma âncora do `TODO.md` reancorada (+8 acima de `:7168`, `0 off target`). A célula Commit do I1 segue `956bd24`.
- 2026-10-26 02:20 · `EXEC I2` · RED: `bash tests/check-health.sh` num clone do `0a29c20` com só os testes novos → rc 1, 56 ok, exatamente as cinco `skip:` em FAIL (argv sempre `--with-mutation`; `--full` como opção desconhecida; a chave do stub vermelho apagada pela regra velha; a receita da chave bateu com o carimbo do runner, `c4a7d50c…`); o Check deu `0`. `bash tests/check-gates.sh` no mesmo clone → rc 1 (139 s), única discordância o mundo 6 (`expected phase DONE, got PR`).
- 2026-10-26 02:20 · `EXEC I2` · decisões fora da letra do plano: a janela virou a PRIMEIRA pergunta da 2c (vale para o pulo e para o catálogo, nada grava nem apaga), então o `mut_HEALTH_stamp_window_blind` foi re-ancorado de `elif` para `if`; o veredito contra a chave mora numa variável `catalogue_against` (`census`/`gap`/`survivor`), lida pelo único `rm -f`; o ramo da chave vazia perdeu o `rm -f`; os dois mutantes de "suíte vermelha apaga" injetam `catalogue_against=suite`, um na linha do pulo (só o pulo a alcança) e um no ramo do score limpo (só o catálogo o alcança), para cada asserção ter o seu; as chaves do stub vermelho e do sobrevivente são forjadas pela receita do `docs/failure-modes.md`, aceita só porque responde o nome do carimbo que o runner gravou (receita errada falha fechado). `CAPTURE_FLOOR` 43 → 44 (`stamp_prov`).
- 2026-10-26 02:25 · `EXEC I2` · `--only HEALTH_skip_never check-health.sh` → exit 0 (pego). Medido sem `SDD_MUTANT`: morrem as `skip:` 1, 3 e 5 (o argv traz `--with-mutation`).
- 2026-10-26 02:25 · `EXEC I2` · `--only HEALTH_full_ignored check-health.sh` → exit 0 (pego); sem `SDD_MUTANT` morrem a `skip:` 2 e a 4 (o `--full` pula e o sobrevivente não é medido). `--only HEALTH_full_ignored check-gates.sh` → exit 0 (pego, 152 s); sem `SDD_MUTANT` só o mundo 7 discorda (`expected phase PR, got DONE`: o `--full` pulou e o sobrevivente não foi medido).
- 2026-10-26 02:25 · `EXEC I2` · `--only HEALTH_full_with_release_accepted check-health.sh` → exit 0 (pego); sem `SDD_MUTANT` morre só a `skip:` 2 (nenhuma recusa nomeada).
- 2026-10-26 02:25 · `EXEC I2` · `--only HEALTH_skip_without_suite check-health.sh` → exit 0 (pego); sem `SDD_MUTANT` morrem as `skip:` 1, 3 e 5 (o argv some; a 3 não lê `suite red`).
- 2026-10-26 02:25 · `EXEC I2` · `--only HEALTH_skip_red_drops_key check-health.sh` → exit 0 (pego); sem `SDD_MUTANT` morre só a `skip:` 3 (a chave do stub vermelho some). `--only HEALTH_skip_red_drops_key check-gates.sh` → exit 0 (pego, 158 s); sem `SDD_MUTANT` só o mundo 6 discorda (`expected phase DONE, got PR`).
- 2026-10-26 02:25 · `EXEC I2` · `--only HEALTH_red_suite_drops_key check-health.sh` → exit 0 (pego); sem `SDD_MUTANT` morre só a `skip:` 4 (a metade do `--full` com rc 1).
- 2026-10-26 02:25 · `EXEC I2` · `--only HEALTH_survivor_keeps_key check-health.sh` → exit 0 (pego); sem `SDD_MUTANT` morre só a `skip:` 4 (a chave do sobrevivente fica). `--only HEALTH_survivor_keeps_key check-gates.sh` → exit 0 (pego, 151 s); sem `SDD_MUTANT` só o mundo 7 discorda (`expected phase PR, got DONE`).
- 2026-10-26 02:25 · `EXEC I2` · re-ancorados: `--only HEALTH_suite_without_mutation check-health.sh` → exit 0 (pego; sem `SDD_MUTANT` morrem o `surface: cmd_health asks the suite for the mutation catalogue` e as `skip:` 1, 2 e 4, que leem o flag no argv do catálogo); `--only HEALTH_stamp_window_blind check-gates.sh` → exit 0 (pego, 151 s).
- 2026-10-26 02:30 · `EXEC I2` · GREEN (`6dbd63c`): Check → `5`; `check-health.sh` rc 0 em 48 s (61 ok; prazo 180 s); `check-gates.sh` rc 0 em 154 s (480 ok); `--anchors` com os 785 aplicando; `check-todo.sh` rc 0 e `--anchors TODO.md` → `0 off target`; `check-lang`, `check-pipefail` e `check-hat` rc 0. Treze âncoras do `TODO.md` na linha exata: as nove que o diff empurrou e as quatro do Minor do I1; o "nearest" do `--anchors` apontava outra ocorrência em `--no-gates` (7919, a certa é 7932) e em `KILLERS_FILE` (7552, a definição é 7640). O comentário do `mut_LEDGER_repo_root_shape_blind` (o outro Minor) agora nomeia o `git_common_dir_abs` e o `|| return 1`. O sensor do `--only` é o nome do arquivo (`check-gates.sh`), não `tests/check-gates.sh`: com o caminho, rc 2.
- 2026-10-26 02:55 · `EXEC I2` · fix round 1 (`11fe1fe`): os dois Important da revisão. (1) A metade "suíte" da regra de gravação não tinha sensor desde a inversão do mundo 6: `mut_HEALTH_red_suite_stamps` (`if [ "$rc" -eq 0 ]; then catalogue_green=1; fi` → `catalogue_green=1`) sobreviveu ao `--only … check-health.sh` (rc 1, `NOT caught`) e ao `--only … check-gates.sh` (rc 1, `NOT caught`, 157 s) antes da asserção; com o `! grep -qF "$STAMPED"` na metade vermelha da `skip:` 4 (nome e Check iguais), `--only … check-health.sh` → exit 0 (pego, 50 s); sem `SDD_MUTANT` morre só a `skip:` 4. (2) A janela do pulo não tinha sensor: `mut_HEALTH_skip_window_blind` (`if [ "$skip" != 1 ] && [ "$stamp_key" != … ]`) sobreviveu a `--only … check-gates.sh` (rc 1, `NOT caught`, 156 s) e a `--only … check-health.sh` (rc 1, `NOT caught`, 46 s); com o mundo 8b (`stamp: a tree that moved while the suite of a skip ran …`, `1|kept|0`), `--only … check-gates.sh` → exit 0 (pego, 154 s); sem `SDD_MUTANT` morre só o mundo 8b. Cabeçalho do bloco i4 reescrito. 787 mutantes (785 + 2); âncora `TODO.md:503` (`KILLERS_FILE`) de `:7640` para `:7656`; o cabeçalho do `check-health.sh` passou a contar 11 chamadas `sdd" health` fixadas (o 8b é a 11ª). A célula Commit do I2 segue `6dbd63c`.
