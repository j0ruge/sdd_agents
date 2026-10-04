# Notas de execução — Lote 3 — a catraca desce

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

- 2026-10-04 00:20 · `PLAN` · plano escrito pelo `sdd-planner` com o humano (via sessão coordenadora, 10 decisões de grill em 2026-10-03). Triagem cética dos 57 por 4 verificadores; os 13 consertos prototipados num clone de `5d55571` por 4 designers. Os 20 Checks rodados contra HEAD: 20 vermelhos com o valor de antes anotado. `check-checkpoint --check` none blind; `adr: none`; `aprovacao: auto`. Os relatórios brutos ficaram no scratchpad da sessão, não no repo.
- 2026-10-04 00:20 · `PLAN` · teste de autocontenção por subagente sem memória (I1, I12, I17): 0 lacuna bloqueante de fato. Lacunas de custo fechadas no plano: I17 concreto (`distinct_killers`, `run_job`, `run_first_control`, `controls_verdict`, `CONTROL_FIRST`), corpos e 4 sítios de drift do I12, cópias de "6 of the 14", commit `chore(checkpoint)` separado, N único, 580 → 592 mutantes, catraca no Check do I14. Achado nascido no planejamento: o `kaizen_reminder` tem o defeito do #121 (registrado no I14).

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

- 2026-10-04 08:48 · `EXEC` · I1 (8577df6) · Red medido `0 5 0`, depois `1 18 1`. 13 itens fora da seção aberta, 13 registros decididos verbatim do plano, catraca 57 → 44. Medido de novo antes de escrever o "6 of the 30": 30 rodadas `40-review-r*.md`, 6 sem `gate:`. check-todo, check-lang e check-pipefail verdes; nenhuma âncora deslocou (edições no lugar).
- 2026-10-04 08:50 · `EXEC` · I2 (db2eee1) · Red `0 0 1 1`, depois `1 2 0 0`. D7 emendada, 🚩 do D7 e do contrato PT-BR apagados, Y5/Y6 na tabela YAGNI, CLAUDE.md § Idioma, anatomia §6 e gaveta P1 sem "está no TODO.md". Contagens do Y5 re-medidas (232 + 364) e 10 alvos pt-BR. Desvio: o `|` dentro do code span do Y5 foi escrito `\|`, porque célula de tabela GFM parte no pipe cru mesmo dentro de crase.
- 2026-10-04 08:58 · `EXEC` · I3 (4af9d0c) · Red `0 0`, depois `1 5`; suíte inteira verde (4m45). Desvios: o comentário do `tail_of` mora dentro do awk entre aspas simples, então a frase do plano ("this sensor's header") foi reescrita sem apóstrofo; o número do #77 é 3 itens vivos com rabo de prosa (o plano mediu 4 sobre `5d55571`, antes do I1/I2); o preâmbulo do bloco Declared debt dizia "These two" sobre quatro entradas e passou a valer para cinco. O motivo do guard do check-todo foi medido numa cópia com a forma do `sandbox()`: `anchor README.md names no file`. Âncoras 4 re-ancoradas (remap + xref), conteúdo conferido.
- 2026-10-04 08:59 · `EXEC` · I4 (921e95e) · Red `0 0 0 1 same`, depois `1 1 1 1 same`. Seção do repasse no `commands/sdd-plan.md` e parágrafo do relay no chapéu; espelho por `sdd install --force` (só o planner mudou). A frase "with the human present" do § Then passou a dizer que é através do relay. check-lang, check-checkpoint e check-hat verdes.
