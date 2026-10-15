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
- 2026-10-15 16:37 · `EXEC` · I2 feito em `3324d6c`. Red antes do conserto: 6 probes falharam pelo motivo certo (vitest, Playwright, marca colada no `^`, a forma da LH-4 e a volta com as duas aspas: rc 1 onde queriam 0; a mensagem sem "or on a pass mark"). Entraram 15 probes, não 9: Q1–Q9 do plano mais a volta com as duas aspas, a volta sem `^`, a volta com `^` que não ancora (sobrevivente da sabotagem), `' *'` aceito, `'^*✓ '` recusado e o quantificador na marca (`'^ ✓* x'`, que casa toda linha que abre com branco). `PROBE_FLOOR` 76 → 91 (medido com cópia a 999), `RULE_FLOOR` 3 → 4. `--selftest` sob `LC_ALL=C` rc 0 e sob `LC_ALL=C.UTF-8` rc 0, saídas idênticas. Sabotagem: 18 degradações, todas vermelhas. O fixture Q9 copia a I1 da LH-4 com o slug e o arquivo de teste trocados (o `check-lang.sh` recusa o slug pt-BR em `tests/`). Medido: kit `193 cell(s) under the rule, 257 row(s) in 30 file(s)`, igual; LH-4 10 → **2**; os 36 checkpoints dos alvos 122 → **114**. `--anchors` reancorou #258 (`:558` → `:601`, `count_occ`) e #249 (`:567` `ANCHOR_SQ` → `:355` `r2_anchored`). `shellcheck -S warning`, `check-lang`, `check-pipefail`, `check-health`, `check-todo --check` verdes. Check: `1`.
- 2026-10-15 16:37 · `EXEC` · Ruling: a volta (`R2_STRICT=1`, regra da célula) conta a âncora pelo mesmo predicado do leitor (`r2_count_anchored`), e `ANCHOR_SQ`/`ANCHOR_DQ` saem — a decisão 5 aceita o `✓` "ao lado de `^  ok    `" sem separar caminho, e o `CLAUDE.md` manda uma definição por programa para o que é lido em mais de um ponto; com a volta de fora, a mensagem nova diria "0 of 1 anchored on … a pass mark" sobre uma célula ancorada na marca. Custo se errado: a volta fica mais frouxa só para literais que abrem com a marca; um revert parcial.
- 2026-10-15 16:37 · `EXEC` · Ruling: um branco com `*` (`' *'`) entre o `^` e a marca conta como branco — a mensagem que o plano sugere e a própria decisão 5 escrevem `'^ *✓ '`, e recusar a forma que a mensagem manda escrever é falso positivo; `*` sem branco antes (`'^*✓ '`) segue recusado, porque numa ERE ou PCRE pode quantificar o `^`. Custo se errado: um laço de 3 linhas e dois probes.
- 2026-10-15 16:37 · `EXEC` · Ruling: a M1 mediu **2**, não "no máximo 1". A 2ª é a I8 da LH-4: `b=$(npm run build -w packages/frontend 2>&1); grep -ci 'chunks larger than' <<< "$b"` → `0` lê uma captura mesclada sem âncora, e é recusada pela regra da decisão 5 como decidida. O protótipo do planner também recusava a I8, mas pelo `;` entre aspas de outro `grep` da mesma célula, e o plano o descartou como artefato. Não corrigido: isentar um grep de aviso de build (que não é sensor nem runner de teste) pede uma regra além da decisão 5, que é do humano. Fica para o I6 decidir se vira item do `TODO.md` (o consumidor é o planner de alvo que grepa aviso do build numa captura mesclada). Custo se errado: a I8 e as Checks do mesmo molde seguem recusadas, fechado.
- 2026-10-15 16:43 · `EXEC` · I3 feito em `3a7b12f`. Red antes do conserto: W1 (`--check` rc 1 onde queria 0) e W5 (a mensagem sem a saída); W2, W3, W4 e W6 já passavam, porque são os controles fechados. O caminho do fixture tem os 117 caracteres do real do `sales_quote`, com uma palavra pt-BR trocada por uma inglesa do mesmo tamanho (o `check-lang.sh` lê `tests/`). Sabotagem: 12 degradações, todas vermelhas; três sobreviveram primeiro (isentar span com branco e forma de caminho, isentar prosa antes do span, a saída para qualquer span) e apertaram W3 (span com `/` e branco), W5 (termina no span) e W6 (carrega um span sem forma de caminho). A sabotagem do próprio probe de ausência (`w6-absence-gone`) sobrevive sozinha e não é regra do sensor: o `exit-always` vermelho é o que prova a ausência viva. `RULES_FLOOR` 11 → 12, piso total 168 → 192 (exato; a HEAD rodava 186 contra 168). A âncora do #257 (`tests/check-todo.sh:211`, `WIDTH_CAP`) andou 5 linhas e ficou dentro da tolerância: `--anchors` 0 off target. `shellcheck -S warning`, `check-lang`, `check-pipefail`, `check-health` verdes. Check: `1`.
