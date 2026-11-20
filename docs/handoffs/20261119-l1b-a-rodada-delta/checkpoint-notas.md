# Notas de execução — L1b: a rodada delta

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

- 2026-11-19 17:44 · `PLAN` · plano escrito pelo `sdd-planner` com o humano por relay; nenhum incremento começou

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

- 2026-11-19 18:18 · `PLAN` · ADR 0023 alocada e escrita (decisão 10). O teste de autocontenção (sessão nova, só leitura) achou 4 bloqueios e 9 lacunas no I1–I3, todos corrigidos no `01-plano.md`; os Checks não mudaram, e o `--red` das 17:53 segue valendo
- 2026-11-20 09:01 · `I1` · `review_base_line` e `sdd review-base` no fim do `bin/sdd`; 5 asserções no check-gates.sh e 5 mutantes provados por --only (4 contra check-gates.sh, COORD_review_base_locked contra check-coordination.sh); suíte verde; âncoras do TODO.md 0 off target
- 2026-11-20 09:52 · `I2` · `review_delta_prompt` no fim do `bin/sdd`, chamado pelo `phase_extra REVIEW` no lugar do `;;` (zero linhas deslocadas no meio do arquivo); 3 asserções (dry-run, gates, hat) e o mutante RUN_review_prompt_delta_dropped provado por --only contra check-dry-run.sh; a suíte de base foi reiniciada uma vez porque editei testes com ela rodando; âncoras do chapéu no TODO.md :62→:68 e :95→:106; suíte verde
- 2026-11-20 10:27 · `I3` · `reviewed_head:` no template e no chapéu (§1 e §4); `review_head_ok` no fim do `bin/sdd` e uma linha no `gate_REVIEW` antes da suíte; 5 mundos no check-gates.sh e 4 mutantes REVIEW_head_* provados por --only contra check-gates.sh; o `round()` do check-worker.sh substitui a linha do template; âncoras 0 off target, 914 mutantes aplicam; suíte verde
- 2026-11-20 10:49 · `I4` · ato `review` do `commands/sdd-worker.md` roda `sdd review-base` depois do merge da base e passa a linha ao subagente; `docs/pipeline.md` ganhou o delta na `### REVIEW` e o parágrafo do `reviewed_head:` reescrito; comentários do `bin/sdd-worker` e do `check-worker.sh` reescritos sem mudar linhas; 1 asserção `command:`, vista vermelha antes; âncoras 91 / 0 off target, 914 mutantes aplicam; suíte verde
- 2026-11-20 11:16 · `I5` · `RESOLVED by a3d0b72` na linha `Fonte:` do #436 (item segue em 8 linhas, 91 achados, 0 off target) e `20-handoff-exec.md`; a 1ª suíte foi morta pelo teto de 600 s do background, a 2ª rodou com prazo de 1 h: rc 0, 0 FAIL
- 2026-11-20 11:52 · `QA` · sem interface: jornada do `sdd review-base` no terminal (3 desfechos, clone descartável) e suíte rc 0; 0 achados, 0 F<n>; 30-handoff-qa.md status: done
- 2026-11-20 12:20 · `REVIEW` · r1 inteira sobre a6f1817: 1 MEDIUM reproduzido (review_head_ok lê o último commit que tocou a rodada) → R1; 2 LOW sem rota, registrados na rodada; Error Handling B, Overall B; suíte rc 0
- 2026-11-20 13:11 · `R1` · `review_head_ok` lê o commit que adicionou a rodada (`--diff-filter=A`); o `write_r12` do check-gates.sh recria a r12 a cada mundo, e o mundo novo (rodada + doc num commit posterior) prova o conserto; mutante REVIEW_head_reads_last_touch; a contagem do Check do I3 passa de 5 a 6; achado #3 (LOW) corrigido no 20-handoff-exec.md; suíte verde
- 2026-11-20 13:11 · `R1` · R1 sabotage: --diff-filter=A retirado (mut_REVIEW_head_reads_last_touch) → gate_REVIEW: reviewed_head reads the commit that added the round, not a later one that touched it (--only contra check-gates.sh rc 1)
- 2026-11-20 13:11 · `R1` · R1 sabotage: o git rm do write_r12 neutralizado → os três mundos de intervalo do gate_REVIEW: reviewed_head vermelhos (rc 1, timeout 600 s, setsid)
- 2026-11-20 13:43 · `REVIEW` · r2 delta sobre a6f1817..64a5e5f: achado #1 da r1 fechado em c6c381f (mutante REVIEW_head_reads_last_touch morre); 1 LOW sem rota (Check do I3 responde 6 1); nenhum R<n>; A em todos os critérios; suíte rc 0
