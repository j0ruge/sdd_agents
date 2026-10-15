# Notas de execução — o lote 8: a leva que não parte a janela

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

- 2026-10-15 15:33 · `PLAN` · plano escrito no worktree `/home/joruge/repos/sdd_agents-lote-8`, HEAD `42b1a35`. `tests/check-checkpoint.sh --check` → `ok    checkpoint.md: 6 row(s), 5 under the anchor rule, none blind` (rc 0). `--red` → I1–I5 `is red at HEAD (prints '0', wants '1')`; I6 `is red at HEAD (prints '0 0 0 1', wants '1 5 1 0')`; `ok    checkpoint.md: 6 pending Check(s), every one red at HEAD` (rc 0). A 1ª versão do Check do I6 contava `RESOLVED by` solto e imprimia `0 2 0 1` no HEAD (o #256 cita o token em prosa); passou a exigir 7 hex depois do token.

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

- 2026-10-15 16:08 · `EXEC` · I1 feito em `53057c2`. Red antes do conserto: 4 dos 9 probes novos falharam pelo motivo certo (arquivo, âncora em outro grep, aspas, captura limpa: rc 1 onde queriam 0, ou "1 of 2" onde queriam "0 of 1"). O plano mandava P1–P8; entraram 11 (P9 concatenação, `NAME="$(…)"` com leitura `${o}`, e `$(` entre aspas simples), os dois últimos nascidos de sabotagens que sobreviveram. **Desvio do plano, anotado:** o `check-checkpoint.sh` não contava as linhas `ok rule:`, então "apagar a linha pass" deixava o selftest verde; entrou o `rule_ok` com `RULE_FLOOR=3` (molde do `rule_end` do `check-todo.sh`), e as duas linhas `rule:` que já existiam no selftest passaram por ele. **Piso:** a HEAD rodava 65 probes contra `PROBE_FLOOR=64` desde `802b6d5` (#223), um abaixo da verdade apesar do comentário; agora 76, exato. Sabotagem: 19 degradações, todas vermelhas (sem contaminar, sem as três voltas, aspas em cada um dos três leitores, `a` pela célula, linha `rule:` apagada, probe apagado, sem aninhamento, `${o}` em cada um dos dois lados, literal entre aspas duplas, `;` como separador, fronteira do `grep`, âncora sempre verdadeira). Medido: kit `193 cell(s) under the rule, 257 row(s) in 30 file(s)` igual antes e depois; LH-4 10 → 10 e os 36 checkpoints dos alvos 122 → 122 (as recusas que sobram leem o `✓` do vitest: I2). `--anchors` reancorou #258 (`:310` → `:558`) e #249 (`:313` → `:567`). `check-lang`, `check-pipefail`, `check-health`, `check-todo --check` e `shellcheck -S warning` verdes. Check: `1`.
