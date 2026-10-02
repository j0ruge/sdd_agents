# Notas de execução — Onde o comando do humano escreve

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

- 2026-10-02 10:38 · `PLAN` · plano escrito pelo `sdd-planner` com o humano (via sessão coordenadora, duas rodadas de grill); 12 decisões no `00-missao.md`; 8 issues reproduzidas sobre `5e75fdc`; suíte verde em 271,4 s (532 mutantes aplicam); `adr: none`; PR #195 (TODO + catraca) aberto e fora desta branch
- 2026-10-02 10:49 · `PLAN` · teste de autocontenção por subagente sem memória: I1 sem lacuna bloqueante; I7 com 1 bloqueante (`mut_APPROVE_adr_file_left_out` sem mundo) e 5 de custo (âncoras de `mut_RUN_branch_switch_dead` e `mut_APPROVE_base_branch_warn_dead`, fixture `SHUT`, fixtures dos probes 3 e 4); as 10 conferidas no código e escritas no `01-plano.md`

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

- 2026-10-02 14:07 · `I1` · Red medido trips:4 sob o veneno armado; a limpeza ficou dentro de `foreign_elsewhere` (subshell com `unset GIT_REFLOG_ACTION`), o que protege também o mundo `RSB`; piso usa repo descartável `reviewscope-venom` sob `$OUTSIDE`; suíte verde, anchors 532
- 2026-10-02 14:25 · `I2` · Red medido: traceback depois de `signal recovers: 15` com o veneno armado e sem o reset; conserto por `preexec_fn=default_signals` em `start()` (SIGINT e SIGQUIT), veneno só no laço de sinais com o handler restaurado; Check 3 lançado com `&` e em primeiro plano; âncora do TODO.md 786 → 816; suíte verde, anchors 532
