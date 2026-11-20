# Notas de execução — L2: o `/sdd-plan` e o planner

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

- 2026-11-20 08:47 · `PLAN` · plano escrito sobre `336640e`; `--check` → `6 row(s), 5 under the anchor rule, none blind`; `--red` → `6 pending Check(s), every one red at HEAD`; o `sdd run` só depois do merge do L1b e de `git merge origin/main` neste branch (pendência 2 do `00-missao.md`)

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

- 2026-11-20 16:52 · `I1` · Red `0 0 0 0` (4 FAIL, só os da família nova `command_before_probes`) → Green `1 1 1 1`, `check-hat.sh` rc 0 com 128 linhas `ok`; 10 âncoras do `TODO.md` re-apontadas pelo deslocamento (+23, +32, +45), a do item 9 pela frase dela (linha 178), não pela menção nova a `Nothing else resumes the planner` (150); commit `256e9d4`
- 2026-11-20 16:52 · `I1` · ⚠️ `TEST_CMD` vermelho antes e depois do I1, só por ambiente: o `EFFORT_EXEC=xhigh` exportado no lançamento (pendência 10) vaza para o `check-dry-run.sh` e o `check-autonomy.sh` (2 FAIL, os mesmos nas duas corridas); com `env -u EFFORT_EXEC -u CLAUDE_EFFORT` os dois saem rc 0, 0 FAIL. O `gate_EXEC` roda o `TEST_CMD` por `eval` no mesmo ambiente e não fica verde nesta corrida sem conserto: achado no `TODO.md` em `1c8de6a` (catraca 102 → 103). Decide o humano: consertar os dois sensores ou relançar sem a variável exportada
- 2026-11-20 17:05 · `I2` · Red `0 0 0 0 0` (4 FAIL, só os da família nova `command_grill_probes`; o 5º campo é o `cmp` do espelho, ainda igual); base da sessão com os mesmos 2 FAIL de ambiente do I1 (`EFFORT_*` exportado, `check-dry-run` e `check-autonomy`), sem relação com o I2
- 2026-11-20 17:24 · `I2` · Green `1 1 1 1 0`, `check-hat.sh` rc 0 com 132 linhas `ok`; `./bin/sdd install --force` → `agent sdd-planner.md updated (--force)`; 7 âncoras do `TODO.md` re-apontadas pelo deslocamento (5 fora do alvo e, por margem, o item 9 em `:186` e a menção `agents/sdd-planner.md:121` do corpo de outro item); suíte inteira com `env -u EFFORT_EXEC -u CLAUDE_EFFORT` → `suite green`, 0 FAIL; com o ambiente da corrida, os mesmos 2 FAIL de ambiente do I1, e nenhum outro; commit `9bea822`
- 2026-11-20 17:46 · `I3` · Red `0 0 0 0 0` (4 FAIL, só os da família nova `command_acceptance_probes` e a linha nova `check plano.md`; o 5º campo é o `cmp` do espelho, ainda igual); base da sessão com os mesmos 2 FAIL de ambiente do I1 (`EFFORT_*` exportado, `check-dry-run` e `check-autonomy`), sem relação com o I3
- 2026-11-20 18:09 · `I3` · Green `1 1 1 1 0`, `check-hat.sh` rc 0 com 135 linhas `ok`; `./bin/sdd install --force` → `agent sdd-planner.md updated (--force)`; 5 âncoras do `TODO.md` re-apontadas pelo deslocamento (`Measure again`, `N (recommended) of M`, `An approval given before the plan`, `HAT_WRITES_BASE`, `Anywhere else`) e a do item 1 (`Mitigação`, `templates/plano.md:43`); suíte inteira com `env -u EFFORT_EXEC -u CLAUDE_EFFORT` → `suite green`, 0 FAIL; com o ambiente da corrida, na base da sessão, os mesmos 2 FAIL de ambiente do I1; commit `96d1bc5`
- 2026-11-20 18:26 · `I4` · Red `0 0 0 0 0 0` (5 FAIL, só as quatro asserções novas do `check-hat.sh`, três em `planner_agent_probes` e uma na família nova `doc_plan_only_probes`, e a linha nova `check plano.md`; o 6º campo é o `cmp` do espelho, ainda igual); base da sessão com os mesmos 2 FAIL de ambiente do I1 (`EFFORT_*` exportado, `check-dry-run` e `check-autonomy`), sem relação com o I4
- 2026-11-20 18:44 · `I4` · Green `1 1 1 1 1 0`, `check-hat.sh` rc 0 com 139 linhas `ok`; `./bin/sdd install --force` → `agent sdd-planner.md updated (--force)`; a asserção `doc:` lê a mensagem do gate também no `bin/sdd`, para o doc não citar frase que ninguém imprime; 12 âncoras e menções do `TODO.md` re-apontadas pelo deslocamento (o chapéu +1 abaixo do `model:`, o comando +5 abaixo do `## Then`), a menção `agents/sdd-planner.md:121` para `:150`, onde está o `^  ok    ` que ela cita; suíte inteira com `env -u EFFORT_EXEC -u CLAUDE_EFFORT` → `suite green`, 0 FAIL; com o ambiente da corrida, na base da sessão, os mesmos 2 FAIL de ambiente do I1
- 2026-11-20 19:09 · `I5` · Red `0 0` (19 `SENSOR-BROKEN` no selftest do `check-checkpoint.sh`, só os probes novos de `--list`/`--only`, e 1 FAIL no `check-hat.sh`, a asserção nova do aceite); base da sessão com os mesmos 2 FAIL de ambiente do I1 (`EFFORT_*` exportado, `check-dry-run` e `check-autonomy`), sem relação com o I5
- 2026-11-20 19:39 · `I5` · Green `1 1`: `check-checkpoint.sh` rc 0 com 10 linhas `rule:` (31 probes novos; `PROBE_FLOOR` 412 → 443, `RULE_FLOOR` 9 → 10), `check-hat.sh` rc 0 com 140 linhas `ok`; `probe()` passa a levar argumentos depois do modo, e o irmão `probe_on` (`line`, `last`, `absent`, `ran`, `notran`) soma em `PROBES`/`FAILS` e chama `fail_rc`; a gramática dos argumentos mora numa função só (`red_args`); 6 âncoras do `TODO.md` re-apontadas (`check_one` :1573, as duas `red_one` :1634, que passavam só por um comentário na :1618, e `Anywhere else`, `An approval given before the plan`, `N (recommended) of M` e `HAT_WRITES_BASE` pelas +8 linhas do aceite); suíte inteira com `env -u EFFORT_EXEC -u CLAUDE_EFFORT` → `suite green`, 0 FAIL
- 2026-11-20 19:39 · `I5` · sabotagem (cópia restaurada por `cp` no `finally`, `setsid`, 180 s, 4 GB; sem mutante: rc 0): 21 de 21 mortas, nenhuma sobreviveu — `--list` rodando → `--list runs no Check` (rc 91); `--only` rodando todos → `never runs a Check it does not name`; última linha do `--only` com a frase inteira, e só quando k = n → os dois `last`; recusa do id calada → `refuses, by name, an id that is no row` (rc 90); `--list` por `pass` → `line`; k contando ids → `counts a repeated id once`; id vazio, 3º argumento, 4º do `--list`, 5º do `--only`, `--only --list` aceitos → os rc 96; `red_cell` nas linhas não nomeadas → `leaves alone a Check outside the strict form`; pré-passe sem retorno → `before it runs any Check`; sem o 93 → `over no pending row`; pré-passe admitindo `done` → `the id of a done row`; `probe_on` sem o `rm` → `--list runs no Check`; `last` frouxo junto de duas linhas finais → `never says every one red at HEAD`; `probe()` sem os extras → rc 90; um probe apagado e a linha `rule:` apagada → rc 92
- 2026-11-20 20:04 · `I6` · Red `0`, Green `14` (`df7b55e`): o `RESOLVED by` no fim da última linha do corpo, como manda o `templates/todo.pt-BR.md`; em seis itens (6, 9, 10, 11, 13 e 14) a linha passaria de 120 caracteres, e foi quebrada numa fronteira de frase, sem mudar palavra, cada um com 8 linhas, o teto; `check-todo.sh --check` → 103 finding(s), rc 0, `--anchors` → 0 off target, 14 de 14 títulos byte a byte iguais; a catraca fica em 103 (o 92 do plano é de antes do merge da `main`), sem toque; suíte com `env -u EFFORT_EXEC -u CLAUDE_EFFORT` → `suite green`, 0 FAIL, 2231 `ok`; no ambiente da corrida, na base da sessão, os mesmos 2 FAIL de ambiente do I1, que o `gate_EXEC` vai ler (pendência no `20-handoff-exec.md`)
