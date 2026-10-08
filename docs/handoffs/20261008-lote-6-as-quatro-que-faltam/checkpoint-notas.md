# Notas de execução — Lote 6: as quatro que faltam

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

- 2026-10-08 11:32 · `PLAN` · plano escrito pelo `sdd-planner` com o humano na sala (relay do `/sdd-plan`), seis decisões de grill; suíte verde em `fc32329` no worktree (548 s); #240 reproduzida sobre as funções extraídas (1800 caminhos → rc 126; o nome com `\n` dá a mesma árvore antes e depois da edição).

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

- 2026-10-08 12:39 · `PLAN` · teste de autocontenção por subagente sem memória ("yes, with caveats"; 46 fatos conferidos, 9 linhas corrigidas, 12 ressalvas fechadas no plano). Esperados do I2 (4 → 7) e do I3 (5 → 6) subiram; `--red` rodado de novo: 7 de 7 vermelhos no HEAD (612 s).
- 2026-10-08 13:26 · `EXEC I1` · Red: `check-health.sh` rc 90, `SENSOR-BROKEN … read as 'check-late.sh check-none.sh' over 8 file(s)`; Check 0 → 1. Sabotagem em 12 cópias sem `.git` (controle rc 0): (a) sem a alternativa do caminho → `check-abspath.sh` some, rc 90; (b) sem a da variável → `check-var.sh` some, rc 90; (c) `GIT[A-Z_]*`, (d) sem o `/`, (e) sem a classe da direita, (f) sem o `[}]` → `check-gitdir.sh` aparece, rc 90; (g) sem o `pass` → Check 0; expectativa antiga, `SEEN = 7` e cada fixture novo apagado → rc 90. Desvio: o programa awk do censo quebra a linha depois de `&&`/`||`, sem barra de continuação. Âncora do #238 não andou (`:1733`); nenhum mutante.
- 2026-10-08 14:06 · `EXEC I2` · Red: 4 `FAIL` com `got: REVIEW|REVIEW` (til dentro de crases e fecho mais curto, nos dois leitores de bug); os 3 controles passavam; Check 3 → 7. 30 `--only` mortos (os 8 tocados + vizinhos de `gate_DOCS`, `bug_decision_recorded` e do extrator). Ruling: o `fence_line` perdeu o valor de retorno — as sabotagens s8/s9/s10 (trocar os `return`) ficaram verdes porque `fence { next }` já pula toda linha que o retorno nomeava e a linha que fecha casa nenhuma regra; os três leitores ficam com a forma `{ fence_line($0) }` + `fence { next }`; custo se errado: um leitor futuro cuja regra case uma linha de cerca precisa pular a que fecha. Ruling: a sabotagem s1 (cerca de til não abre) sobrevivia porque o mundo `a ~~~ fence hides the quote…` não media o til desde a issue 63 — o corpo dele passa a citar um cabeçalho inteiro; e s2 (sem tirar os brancos) sobrevivia — dois mundos novos no leitor de decisão (cerca de til; fecho indentado), SEM o prefixo `fence: ` para o Check do plano continuar `7`; custo se errado: nenhum além de nome. Sabotagens finais (cópias, controle rc 0): s1–s7, s11 e as 6 de chamada/fragmento → rc 1, cada uma no mundo certo. Âncoras #239/#236/#240 → 1585/10934/4034. Suíte inteira verde.
- 2026-10-08 14:20 · `EXEC I3` · Red: `rc:3 named:0 sessions:2` (a corrida real abria duas sessões do `loud_stub`) e `warned:0` na projeção; os 4 controles passavam; Check 4 → 6. 11 `--only` mortos (4 novos + 3 `KAIZEN_reminder_*` + `kit_door_per_worktree` + os 3 de faixa `cmd_kaizen`). Sabotagem em cópias (controle rc 0): readlink, `case`, `return` final, `if`, texto do comando, texto do aviso e as duas frases do lembrete → rc 1; `local shared_why` apagado → verde, inobservável (nada lê a variável depois do `die`/`warn`). Ruling: a asserção do lembrete fora do kit (`outside the kit the reminder tells the truth about the judge`) também passou a exigir o termo novo — a 2ª frase do P6 mudava sem probe; custo se errado: nenhum. Desvio: a frase do `die` diz "this is the checkout every target's 'sdd run' executes…" (o plano não fixava o texto, só o conteúdo). Âncora do #236 → 10948. Suíte inteira verde.
