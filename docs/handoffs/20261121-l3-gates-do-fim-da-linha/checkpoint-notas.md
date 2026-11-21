# Notas de execução — L3: gates do fim da linha

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

- 2026-11-21 02:23 · `PLAN` · plano escrito sobre `6198b68` pelo `sdd-planner`; as 12 respostas do grill vieram delegadas por escrito, na opção recomendada; a base entra no branch antes da corrida (pendência 1 do `00-missao.md`)

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

- 2026-11-21 04:36 · `EXEC` · I1 em `83b2b3e`: RUN_test_cmd_not_run_reads_red caught by check-gates.sh; desvio do plano: sem linha em inglês no log (o shell traduz o strerror sob pt-BR, medido nesta máquina) o motivo cita a última linha não vazia do log, e o probe roda com LC_ALL=C; duas referências cruzadas a `docs/pipeline.md:N` no TODO.md corrigidas à mão (1150→1161, 486→497)
- 2026-11-21 05:32 · `EXEC` · I2 em `c42fa76`: RUN_pr_blocked_not_armed e RUN_review_blocked_not_armed caught by check-autonomy.sh; o reset do marcador no gate_REVIEW é a 1ª linha da função (o plano o punha depois de resolver a rodada, e a rodada ausente não o zeraria); o par de autonomia força a fase com --phase e sobe o REVIEW_MAX_ITER só para o par; dez referências cruzadas do TODO.md corrigidas à mão (o remap.py as lista como NOT-REWRITTEN)
- 2026-11-21 06:35 · `EXEC` · I3 em `5da09d6`: PR_head_unread, PR_verified_head_unchecked, PR_merged_head_read e PR_head_unreadable_passes caught by check-gates.sh; o verified_head só é conferido quando há mission_tip (sem ele as duas comparações pulam juntas); o motivo dos ⛔ tira o número do PR do fim da url (`${live##*/}`); cinco referências cruzadas do TODO.md corrigidas à mão (o remap.py as lista como NOT-REWRITTEN) e a âncora do item 1 seguiu a chamada ao gh (2719→2751)
- 2026-11-21 07:18 · `EXEC` · I4 em `7be7b47`: REVIEW_later_code_unread, REVIEW_later_docs_writes_counted e REVIEW_later_merged_mission_refused caught by check-gates.sh; os mundos rodam num branch missao/l3-later e devolvem o main; o array das refs da base se chama `bases` (com `not` o shellcheck lia `not-git` como aritmética, SC2100); um hat_writes vazio (escreve em qualquer lugar) admite todo caminho; 47 referências `arquivo:linha` do TODO.md deslocadas por script (as que estavam a 10 linhas do símbolo saíram do alvo)
- 2026-11-21 08:09 · `EXEC` · I5 em `66a9bd0`: DOCS_k8_reads_head_off_branch, DOCS_k8_gone_branch_refused e o re-ancorado DOCS_k8_presence_is_enough caught by check-gates.sh; o mundo do branch apagado precisa do main em `$k8_start^` (no `k8_main_before` o commit do log de base entra no intervalo e o diff o lê inteiro como entrada nova); o mutante do branch apagado troca o pulo pelo recuo a HEAD, porque sem a guarda o merge-base com ponta vazia já falha e pula; 45 âncoras bin/sdd do TODO.md deslocadas em +7 e quatro referências cruzadas à mão
- 2026-11-21 08:43 · `EXEC` · I6 em `45c8434`: QA_e2e_history_uncounted e QA_e2e_history_counts_passed caught by check-gates.sh; o histórico entra antes do `See <log>` separado por `; `; o mundo mora no bloco do servidor de página, depois do par do APP_EXPECT, com o E2E_CMD lendo `.page/e2e.out`; 58 referências `arquivo:linha` do TODO.md deslocadas por script (bin/sdd +52/+57, docs/pipeline.md +5)
- 2026-11-21 10:00 · `EXEC` · I7 em `5e8b000`: PR_kit_lines_uncounted e PR_kit_lines_counted_in_quote caught by check-gates.sh; o bloco do corpo passou a pular PR MERGED pelo estado da 1ª chamada ao gh (a 2ª checagem saiu), e três mutantes antigos foram re-ancorados (PR_blocked_docs_not_carried, PR_merged_rechecked, PR_body_unread_is_missing, os três pegos); a linha-modelo `- kit:` do pr-body.md é nua, como o plano pede: um publisher que a deixe no corpo infla a conta em 1; 45 âncoras do TODO.md por script e sete referências cruzadas à mão
