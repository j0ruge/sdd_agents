# Notas de execução — os achados da janela do juiz

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

- 2026-09-28 16:11 · `PLAN` · plano nascido do `sdd kaizen` (commit `038a314`) replanejado com o humano: grill de 7 perguntas, escopo B (conserta 3, 4, 6, 7, 8; registra 1, 2, 5), ADR 0013 alocada por `sdd adr new`, branch `fix/os-achados-da-janela` a nascer da `main` depois do PR só de docs do veredito. Ordem de execução ≠ ordem dos achados: I2 = achado 4, I3 = 3, I4 = 6, I5 = 7, I6 = 8.
- 2026-09-28 16:11 · `PLAN` · armadilha que custa a suíte: 41 itens do `TODO.md` ancorados em `bin/sdd:<linha>` (tolerância de 10 linhas); todo incremento que mexe no `bin/sdd` roda `bash tests/check-todo.sh --check TODO.md` e re-ancora no mesmo commit, e `bash tests/check-mutation.sh --anchors` antes de commitar.
- 2026-09-28 16:11 · `PLAN` · `.claude/rules/anatomia-do-agente.md` (I7) é caminho que o headless nega: nunca contornar pelo Bash — é o próprio achado 6; texto proposto no handoff de EXEC.
- 2026-09-28 16:18 · `PLAN` · teste de autocontenção feito de verdade: sessão fria (sem memória desta conversa) leu só `00-missao.md`, `01-plano.md` e `checkpoint.md` e conferiu 25+ âncoras no repo — I1 a I7 executáveis como escritos, nenhuma contradição entre os três, nomes de asserção do plano e do Check idênticos. Consertado na hora: duas âncoras a 1-2 linhas (`sdd-coordination.py:430-437`, gaveta `:18`) e o Check do I1, que passava com a catraca acrescentada em vez de trocada e com os itens fora de lugar (agora `86/11/placed/1`).

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
> `sdd run --phase X`, `sdd retry`, `--budget-override` — e a commita sozinha, na hora, para a
> árvore chegar limpa ao gate da fase seguinte. A linha escrita à mão continua valendo para o que
> o runner não vê: conserto manual, fase feita à mão, `BLOCKED` assumido. `sdd approve` não
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
