# Notas de execução — Lote 4: a catraca zera

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

- 2026-10-04 21:28 · `PLAN` · plano escrito pelo `sdd-planner` com 8 perguntas de grill repassadas pela sessão coordenadora; 4 verificadores e 5 designers prototiparam cada incremento num clone de `fe9441d` (protótipos opcionais no scratchpad citado em `01-plano.md` § Fatos que atravessam incrementos)

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

- 2026-10-04 22:31 · `EXEC` · I1 (b120607) · Red medido em 6c628be antes de qualquer edição: Check → `0 0 0 20 0 0`, igual ao plano; verde → `1 1 1 23 1 2`. Os textos do plano entraram verbatim (Y7, três decididos, limite na linha 39 do check-templates.sh, § F3 + índice + item 4 da ordem); o `todo_rm.py` apagou 51-57, 152-158, 221-227 e 91-98, as faixas medidas no plano. Conferido antes de escrever no § F3: o #7 está na seção decidida com data 2026-10-03. Sem mutante (só texto), como o plano prevê. Sensores: `check-todo.sh` → 19 finding(s), `--anchors` 19 medidos e 0 fora; `check-templates.sh` rc 0; `check-lang.sh` 0 de 57; `shellcheck -S warning` limpo; suíte rápida verde em 295 s (catálogo 593, âncoras aplicam). Nenhum desvio do plano.
- 2026-10-04 23:47 · `EXEC` · I2 (a1e4f12) · Red medido em dc4aaa1 antes do conserto: Check → `0 0 0 0 0 0 0 same`, igual ao plano; verde → `1 1 1 1 1 1 1 same`. As duas asserções do `check-templates.sh` e o probe do `check-hat.sh` entraram primeiro e ficaram vermelhos pelo motivo certo (rc 92 nomeando `an act outside git commits a record` e `a step after the merge…`; rc 1 no hat). Textos do plano verbatim; a regra cai em `templates/checkpoint.md:35`, o ponteiro do registro. Sabotagens S1–S5 provadas aplicadas por md5: S1–S3 → `check-templates.sh` rc 92 com o FAIL nomeado, S4–S5 → `check-hat.sh` rc 1. Espelho por `sdd install --force` (executor e planner updated). #194 re-ancorado de `:76` para `:83`; `--anchors` 17 medidos, 0 fora. `shellcheck -S warning` limpo, `check-lang.sh` 0 de 57, suíte rápida verde em 295 s. Nenhum desvio do plano.
- 2026-10-04 23:53 · `EXEC` · I3 (9c9c5e1) · Red medido em 000f451: `grep -ci sabot agents/sdd-executor.md` → 0, Check → `0 0 same`; o probe entrou primeiro e ficou vermelho (`FAIL hat: sdd-executor lost the sabotage step…`, rc 1); verde → `1 1 same`. Texto e probe do plano verbatim; o `Watch it fail` segue em `:83` (o passo entra depois dele) e `--anchors` dá 17 medidos, 0 fora. Sabotagens S1 (passo apagado), S2 (escopo tirado do heading e da nota), S3 (linha do `checkpoint-notas.md`), S4 (só a frase, não o parágrafo) e S5 (passo desnumerado), todas provadas aplicadas por md5 → `check-hat.sh` rc 1 com o FAIL nomeado. Espelho por `sdd install --force`. `shellcheck -S warning` limpo, `check-lang.sh` 0 de 57, suíte rápida verde em 296 s. Nenhum desvio do plano.
