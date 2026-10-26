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
