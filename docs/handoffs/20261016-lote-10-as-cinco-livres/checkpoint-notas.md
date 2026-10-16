# Notas de execução — o lote 10: as cinco livres

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

- <YYYY-MM-DD HH:MM> · `<ID>` · <o que aconteceu>

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

- 2026-10-16 18:56 · `I1` · Red às 18:54:19 `0 0 17 0`; Green às 18:56:00 `1 1 15 1` (commit d8a6290). #277 e #279 na seção decidida com o texto do plano (`cmp` idêntico às linhas 183–184 do `01-plano.md`), baseline `todo-findings 15`, cabeçalho do sensor +5 linhas, só comentário; o `r2_merges` foi de :463 para :468 e a âncora do #278 segue a 5 linhas (`check-todo.sh` verde, sem reancorar — o I2 reancora se precisar). `check-todo`, `check-lang`, `check-pipefail` e `shellcheck -S warning` verdes; `--audit` da skill `auto=0 manual=0` (com `SDD_HOME` no worktree). `tests/run-all.sh` não rodou antes nem depois, por ordem do relay (é do I4).
- 2026-10-16 19:12 · `I2` · Red às 18:57:41 `0`; Green às 19:12:10 `1` (commit c462a1b). TDD: os 14 probes antes do conserto, `--selftest` rc 90 com os 6 "mesclam" e o da regra da célula vermelhos (rc 0 com `0 under`), o `2>|` em processo vermelho e controles verdes; desvio do plano: o da âncora também saiu vermelho, pelo texto (rc 0 certo, mas `0 under` no lugar de `1 under`), que é o motivo certo — ele afirma que a célula está sob a regra. Desvio justificado: o `R2_PROCSUB_RE` lê o texto CRU, não o sem aspas do `R2_STDOUT_RE` (medido no bash 5.2.21: `2>"" >(cat)`, `2>' '>(cat)`, `2'>' >(cat)` e `'2'> >(cat)` não põem a stderr na captura), e um 5º controle (`2>"" >(cat)`) segura a escolha. Pisos exatos: `RULE_FLOOR` 8 → 9, `PROBE_FLOOR` 398 → 412 (lido pela mensagem do piso numa cópia com 99999). Sabotagem numa cópia `tar`, script Python sobre backup, contagem conferida e morte alta se nada muda, sem `SDD_MUTANT`: 16 degradações, 13 mortas — sem `>>` rc 90, sem `>[|]` rc 91, sem `<>` rc 90, sem `[[:blank:]]*` rc 90, `[^0-9]` → nada rc 90, `>[(]` → `[(]` rc 90, teste apagado rc 90, teste sobre o texto sem aspas rc 90 (pelo controle novo), `return 0` → `return 1` rc 90, `rule_ok` neutralizado rc 92, o `mg_merges` do `2>|` apagado rc 92, o controle `12> >(cat)` tirado da lista rc 92, o probe da regra da célula apagado rc 92; vivas (rc 0): `RULE_FLOOR` 9 → 8 sozinho e `PROBE_FLOOR` 412 → 411 sozinho (mínimos, como todo precedente) e a guarda do grupo em `-ge`, que só decide com a regra quebrada (medido: teste apagado imprime a linha `ok rule:` sob `-ge` e não sob `-eq`, rc 90 nos dois) — declarados no cabeçalho. Regressão às 19:10:25: 106 recusas em 37 checkpoints (lighthouse_project 3794fc9, sales_quote a1ad4b74), e a saída do `--check` idêntica byte a byte à do sensor de 3208161; varredura do kit `ok    no checkpoint Check reads a red assertion as green (199 cell(s) under the rule, 266 row(s) in 32 file(s))`. `check-todo` (âncora do #278 segue a 9 linhas, sem reancorar, `TODO.md` intocado), `check-lang`, `check-pipefail`, `shellcheck -S warning` e `--selftest` rc 0; `git diff fec0cca..HEAD -- bin agents templates config` vazio. `tests/run-all.sh` não rodou, por ordem do relay (é do I4).
- 2026-10-16 19:18 · `I3` · Red às 19:14:40 `0 0` (11 linhas `^  ok    command:`); Green às 19:16:12 `1 1` (commit 6cb8a12), 13 linhas `command:`. TDD: `command_branch_cwd_probes` (variáveis `before_sec`/`then_sec`) e o literal `<provisional>` do par `--no-track` antes da prosa; às 19:15:29 o `check-hat.sh` saiu rc 1 com os três `FAIL` certos (`cuts the mission branch without --no-track`, `no longer cuts a provisional branch…`, `no longer keeps the planner out of the main checkout…`). Prosa: o sub-item do passo 2 cresceu 8 → 11 linhas; o *Then* ganhou o parágrafo das duas ordens depois do primeiro; os dez literais, cada um numa linha física. Sabotagem numa cópia `tar` no scratchpad, script Python sobre backup, contagem de cada literal conferida (=1) e morte alta se nada muda, sem `SDD_MUTANT`: 12 de 12 rc 1 com exatamente o `FAIL` do par certo — os nove literais apagados um a um (4 → par do #280, 5 → par do #281), a receita de volta a `-b <branch>` (só o par `--no-track`), o parágrafo do *Then* movido para a seção do relay (os dois pares novos) e `while the branch has no upstream` quebrado em duas linhas (par do #280); cópia restaurada rc 0. `check-todo` rc 0 sem reancorar (#280 segue em `:35` (`git worktree add`); o `sdd-planner` do #281 foi para `:75`, a 3 linhas), `TODO.md` intocado; `check-lang`, `check-pipefail`, `shellcheck -S warning` e `bash -n` verdes; `git diff fec0cca..HEAD -- bin agents templates config` vazio; checkout principal limpo. `tests/run-all.sh` não rodou, por ordem do relay (é do I4). Fora de escopo, sem commit: (a) o item aberto "A devolução do planner ao relay não tem regra de idioma" (`TODO.md:140`, congelado, âncora em `agents/sdd-planner.md:273`) cita na prosa `commands/sdd-plan.md:89` para o `OUTPUT_LANG` da devolução — já era `:92` no HEAD e agora é `:111`; a citação de prosa não é medida pelo `check-todo`, fica para a triagem; (b) o `fail` do par `--no-track` diz "without --no-track" também quando o que falta é o `<provisional>` (medido na sabotagem da receita): o motivo nomeia só uma das duas causas.
- 2026-10-16 20:12 · `I4` · Red às 19:25:46 `0 1 0 1`; Green às 20:11:56 `1 0 3 0` (célula Commit = 071f189, o último commit de conteúdo). Acréscimo 1 do humano (`fbe202e`): o `fail` do par `--no-track` do `check-hat.sh` nomeia as duas causas (sem `--no-track` a branch rastreia a base; sem `<provisional>` a receita nomeia a branch antes de o grill decidir o id); nenhum probe nem selftest lê o texto (grep em `tests/`), o `pass` ficou (a Check da I5 do lote 8 o lê); cópia `tar`: íntegra rc 0 e 13 `command:`, `-b <branch>` rc 1 com o FAIL novo, sem `--no-track` rc 1 com o mesmo FAIL, restaurada rc 0. `RESOLVED by` (`31cfc09`, skill `todo-to-github-issues` antes): c462a1b no #278, 6cb8a12 no #280 e no #281, no fim da última linha do corpo; no #280 a palavra `upstream.` desceu com o token (item em 8 linhas, o teto); `--audit` `auto=0 manual=0`, `check-todo` 15. Acréscimo 2 (mesmo commit): o #266 trocou `commands/sdd-plan.md:89` (já `:92` na `3208161`, `:111` hoje) pela seção `## Relaying the grill to the human` com o literal "written in `OUTPUT_LANG`", título e âncora intactos, 7 linhas. Medida final: alvos 106 → 106 (base `3208161` e HEAD na mesma corrida, 19:29:18–19:29:29, 37 checkpoints, `lighthouse_project` 3794fc9, `sales_quote` a1ad4b74, saídas idênticas byte a byte); varredura do kit `199 cell(s) under the rule, 266 row(s) in 32 file(s)` rc 0 (19:29:34); `command:` 11 → 13 e `rule:` do `--selftest` 8 → 9 (`git archive 3208161` × HEAD, 19:30); grafias 0 de 5 → 5 de 5 (fixtures às 20:00; o `2>|` só em processo, o pipe cru é recusado nos dois sensores); corpus 0 de 67 linhas com grafia aberta e 2 com o `dq` do #279 (20:00:44); Codex 6 rodadas no #267 (6 P2, 1 P1) e 5 no #274 (7 P2), pela API às 20:00:55; `kaizen --series` 20:01 `bad6168`, `missions: 1`, `sufficient: false`, `window_broken: false`. KAIZEN_LOG e gaveta em `071f189`. Suíte: `tests/run-all.sh` no HEAD limpo `071f189`, 20:02:33 → 20:10:30, `suite green` rc 0, 2008 `ok`, 0 `FAIL`. Plano do espelho da branch (só leitura, 20:10): `create=0 update=4 orphans=2` (UPDATE text no #278, #280, #281 e #266; ORPHAN sem RESOLVED by no #277 e #279). `git diff fec0cca..HEAD -- bin agents templates config` vazio em todo commit; checkout principal limpo.
