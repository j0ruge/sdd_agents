# Notas de execução — o sub-passo da QA que andou

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

- 2026-10-01 00:22 · `I1` · `step_after` escrito nas três portas (cmd_run 1ª passada, retry inline, cmd_retry), um probe e um mutante por porta + o da guarda (catálogo 495 → 499). Desvio do plano: o `pending_before`/`pending_after` na linha QA ficou para o I3 — o `check-autonomy.sh` afirma hoje "a non-EXEC row carries the three as null" (e o retry inline idem) sobre uma linha QA, então ligar a foto na QA muda essas asserções e é decisão daquele incremento. Para o retry inline o probe roda SEM `--max-phases`: o teto fica acima do retry e o impediria. Seis âncoras `arquivo:linha` do TODO.md deslocadas pelo diff foram corrigidas no mesmo commit (o `check-todo.sh` as mede).
- 2026-10-01 00:40 · `I2` · braço do sub-passo em `ledger_outcome_defs` (`def step_rank` + 4º braço, guardas de rank não-nulo nos DOIS lados e `.moved != false`). Além do par diferencial do plano, três asserções a mais (moved:false, step desconhecido, sub-passo que volta) e quatro mutantes em vez de dois (`unguarded` e `moved_blind` acrescentados porque eram regras sem probe); catálogo 499 → 503. As linhas do fixture carregam `step_after` explícito para o I4 (recuperação pela próxima linha) não mudar o que este bloco mede. 12 âncoras do TODO.md deslocadas, corrigidas no commit.
- 2026-10-01 01:00 · `I3` · escritor (foto de `pending` na linha QA, três portas, fim = `checkpoint_tally` e não `GATE_EXEC_PENDING`) + quinto braço escopado a `.phase == "QA"`; seis mutantes (503 → 509), todos medidos mortos. As asserções "carries the three as null" da linha QA viraram "none of EXEC's counts" (`0 0` + `increments_total` nulo, que segue segurando `mut_LEDGER_progress_leaks_across_phases`). A foto da porta 3 ficou depois da do REVIEW: colada à do EXEC partia a âncora de `mut_RUN_retry_exec_photographs_every_phase`. Contrato de `pending_*` no `docs/pipeline.md` ajustado ("null outside EXEC and QA"); narrativa fica para o I5. 15 âncoras do TODO.md corrigidas.
- 2026-10-01 01:17 · `I4` · `def historic_steps` anda a lista DE TRÁS PARA FRENTE (a memória é a próxima linha QA da mesma (repo, missão)); guarda `has("step_after") | not` e não `== null` como o irmão do EXEC — o escritor põe a chave em toda linha, e null é foto perdida (não lavar `mut_RUN_qa_step_after_missing`). Jidoka do plano: diff do `--by-mission` real antes × depois mudou SÓ as três linhas da métrica + a frase `(28 QA row(s) older than step_after …)`. Teste em `check-kaizen.sh` (não no `check-autonomy.sh`): a paridade dos leitores compara o juiz com `autonomy --all-repos`, porque o juiz lê todo repo (ADR 0005). Quatro mutantes (509 → 513), em vez de um. 22 âncoras do TODO.md remapeadas pelo diff.
- 2026-10-01 01:33 · `I5` · D16 4ª emenda, verbete Churn, `docs/pipeline.md` (rótulo `leve`), KAIZEN_LOG e também `docs/failure-modes.md` (cita a régua; "three times" → "four times"). O antes/depois foi medido de novo nesta sessão: `git archive 74996fa^` em /tmp × HEAD, `sdd autonomy --all-repos` sobre o ledger real. Fatia `5b98087` 44·9 → 47·6; no `--by-mission` só as três missões da métrica mudam.
- 2026-10-01 01:49 · `I6` · cinco itens saíram do `TODO.md` para os destinos do plano (90 → 85, baseline no mesmo commit); 6 âncoras em `check-health.sh`/`check-autonomy.sh` remapeadas pelas linhas novas dos cabeçalhos; o slug `runner-sem-dividas` no cabeçalho em inglês reprovou o `check-lang.sh` e virou data. O pré-check viu UM vermelho de timing no `check-coordination.sh` (`TimeoutExpired` 8 s após `signal recovers: 15`); sozinho deu 186/0 e a suíte pós-I6 ficou verde, por isso não entrou no `TODO.md` (régua D15: falha fechada, sem consumidor externo). Último incremento, `20-handoff-exec.md` escrito.
- 2026-10-01 02:00 · `QA` · QA sem interface percorrida no terminal (sdd autonomy nas três formas + diferencial com a main + ledger vazio), 0 achados, suíte verde; ressalva registrada no 30-handoff-qa.md: o escritor de step_after ainda não gravou linha real porque o sdd run desta missão subiu antes do I1.
- 2026-10-01 02:20 · `REVIEW r1` · nota B (Code Quality e Test Coverage). `R1` nasce do achado #1 da r1: `historic_steps` recupera `step_after` da próxima linha QA de outro `run_id`, reproduzido em fixture (HEAD 2·0 × main 1·1). 6 das 28 recuperações reais são entre corridas, nenhuma muda de balde. Achado #2 (fixture de `check-autonomy.sh:6409` herda `GIT_REFLOG_ACTION`, vermelho só dentro de sessão REVIEW, também na main) foi para o TODO.md, catraca 85 → 86.
- 2026-10-01 02:40 · `R1` · `historic_steps` guarda `{step, run_id}` e só recupera com `run_id` igual e não nulo (direção da r1). Além da asserção do Check, uma segunda (`m85`, duas linhas sem `run_id`) para a metade "não nulo" da guarda não ficar sem probe; dois mutantes, um por metade, medidos mortos numa cópia (513 → 515). Ledger real: só o rodapé muda (28 → 22), as três linhas da métrica intactas (Check do I4 re-rodado → 4). Suíte rodada com `env -u GIT_REFLOG_ACTION` por causa do achado #2 da r1 (já no TODO.md). 22 âncoras do TODO.md remapeadas.
- 2026-10-01 03:05 · `REVIEW r2` · nota A (Documentation B). `R1` (`8a1b3a5`) verificado: asserções m84/m85 verdes, os dois mutantes mortos numa cópia, Check do I4 → 4 no ledger real (rodapé 28 → 22). Achado #1 da r2 (LOW, só prosa: `docs/pipeline.md:1398` e o verbete Churn sem "da mesma corrida") foi para o TODO.md, catraca 86 → 87. Nenhum `R<n>` novo.
- 2026-10-01 02:54 · `DOCS` · checklist de drift com 15 linhas, sem ✗ e sem ⛔. Achado #1 da r2 (prosa sem "da mesma corrida" no `docs/pipeline.md` e no verbete Churn) consertado em `88ed6ea`. O `RESOLVED by` no `TODO.md` fica para o publisher, porque o `TODO.md` está fora do `writes:` do `sdd-docs`.
- 2026-10-01 03:35 · `PR` · bloqueada antes do push. `sdd health` rodou até o fim (29 min) e voltou vermelho de verdade (não o carimbo de 2026-09-29): `mut_KAIZEN_historic_steps_key_slug_only` sobrevive — o `R1` acrescentou a guarda `run_id`, e o fixture `m82` já tinha `run_id` diferente nas duas linhas por acidente, então a guarda sozinha já separa os dois mundos e a asserção para de ver a metade `repo` da chave. `514 of 515 caught`; carimbo removido por `cmd_health` (catálogo não veio verde). `TODO.md` ganhou `RESOLVED by 88ed6ea` na pendência da r2 (independente do bloqueio). `50-pr.md` escrito com `status: blocked`; direção para EXEC: mesmo `run_id` nas duas linhas do fixture `m82`.
