# Notas de execução — A janela não se parte

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

- 2026-10-01 11:20 · `PLAN` · plano escrito pelo `sdd-planner` com o humano (via sessão coordenadora); 9 decisões do grill no `00-missao.md`; ADR 0014 alocada; suíte verde em `c19e987` (259 s, 515 mutantes aplicam)

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

- I1 (85039c7): RED observado pelo motivo certo (4 asserções kit_rev: com kit_rev/kit_rev_dirty = null, campos crus corretos). Mutantes provados isolados pela receita contra check-autonomy.sh: RUN_kit_rev_is_head rc=1 (pego por 'outside the behaviour paths'), RUN_kit_rev_dirty_whole_tree rc=1 (pego por 'dirt outside'), RUN_kit_guard_reads_rev rc=1 (regime 1 + regimes 4, 5, 7 da guarda). Check do I1 → 5. tests/run-all.sh → suite green, rc 0, anchors 518 mutants. 22 âncoras do TODO.md remapeadas pelo diff (contagem 87 inalterada). Mundo 4 usa agents/kr-probe.txt (não .md) para não tocar o espelho de agentes do install.
- I2 (eedc6d3): RED observado pelo motivo certo (5 asserções kit-version:, A agrupava por aaa0002 e o gêmeo B já respondia certo — controle). Mutantes provados isolados pela receita contra check-kaizen.sh: KAIZEN_kit_version_ignored rc=1 (pega as 4 do juiz), AUTONOMY_kit_version_ignored rc=1 (pega 'the human table'), KAIZEN_kit_rev_dirty_ignored rc=1 (pega 'dirt outside'). Surpresa: com bin/ sujo durante a sessão, duas asserções de check-autonomy.sh (degradação e harness) caíram porque normalizavam só kit_sha/kit_dirty — agora normalizam também kit_rev/kit_rev_dirty. KAIZEN_historic_steps_series_blind reancorado (rc 90 → aplica; pego por 'recover the QA sub-step alike'). Check do I2 → 5. tests/run-all.sh → suite green, rc 0, 263 s, anchors 521 mutants. Âncoras do TODO.md remapeadas (bin/sdd, check-mutation.sh, check-autonomy.sh), contagem 87.
