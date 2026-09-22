# Notas de execução — o motivo da fase

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

- 2026-09-22 18:06 · `PLAN` · plano escrito pelo sdd-planner com o grill do humano repassado pela sessão coordenadora; aprovacao vazia — o humano roda `sdd approve`; execução interativa, nunca `sdd run` no kit

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

- 2026-09-22 18:26 · `EXEC` · I1 done (74e294c): gsub da crase só em f[6]; mutante GATE_EXEC_backtick_kept vermelho pela receita M (check-gates rc=1)
- 2026-09-22 18:38 · `EXEC` · I2 done (f35189f): regex aceita A-F além de a-f (git aceita hex maiúsculo; recusar seria regressão); SC2034 desligado em gate_EXEC até o I5 dar consumidor ao GATE_EXEC_CELL
- 2026-09-22 18:52 · `EXEC` · I3 done (3245bfd): medido antes do conserto — derivado 3 execuções de TEST_CMD × forçado 2 (subshell do derive + pré-checagem do gate_EXEC no pai); depois 2 × 2. A forma do plano ("não cresce com o nº de fases pendentes") não tinha Red — o memo é por $cmd — e virou o diferencial derivado × --phase
- 2026-09-22 18:59 · `EXEC` · I4 done (bb2a9f7): linha 'Why this phase:' logo abaixo da tarefa; compara com ${step%%:*} porque QA inicia por sub-passo; ramos forçado/dry-run do cmd_run zeram CURRENT_PHASE para não herdar motivo de volta anterior
- 2026-09-22 19:16 · `EXEC` · I5 done (d767689): Red reproduziu o incidente (4 sessões + budget-exhausted); fixture 'inline retry records the count' migrou de 'done sem commit' para drift de ADR sob --phase EXEC (o mundo antigo agora é recusado pela porta 1); gate_why_cites_log adiado para o I6, onde tem probe e consumidor
- 2026-09-22 19:22 · `EXEC` · I6 PARADO (Jidoka do plano): forma (a) chaveada em (fase, motivo) para QA com interface — QA:plan e QA:exec terminam com o mesmo 'missing 30-handoff-qa.md', então a 2ª volta de QA vira no-work; progresso real com motivo estável. Levado ao humano; proposta: chavear em (phase_step, motivo). Dois fixtures antigos (moved; review→draft) quebram por (a) mas são o padrão do incidente (sessão mexe no disco sem mudar o que o gate lê) e serão retargeted
- 2026-09-22 19:46 · `EXEC` · I6 done (7295ef4): humano decidiu chavear a forma (a) em (phase_step, motivo); porta 1 desceu para baixo dos Jidokas e tetos (acima deles pré-empatava review-to-draft); volta forçada zera prev; mutante RUN_no_work_cites_log_blind NÃO entrou — medido sobrevivente (log é mktemp por execução), declarado em gate_why_cites_log; 3 fixtures antigos retargeted (commit que não muda o motivo = no-op do incidente)
- intervention: decisão humana sobre a chave da forma (a) — (fase, motivo) parava todo QA com interface após QA:plan; escolhido (phase_step, motivo) — EXEC — sem custo de sessão
