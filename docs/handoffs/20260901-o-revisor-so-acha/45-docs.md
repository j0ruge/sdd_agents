---
missao: 20260901-o-revisor-so-acha
fase: DOCS
status: done
sessao: f69c134b-961c-46fb-943a-e68f6a64796d
data: 2026-09-02 08:43
gate: "`docs/handoffs/20260901-o-revisor-so-acha/45-docs.md` existe, contém a palavra `drift` e a coluna `Status` da tabela de drift não tem célula pendente — **28 linhas, 22 `✅` e 6 `n/a`**, contadas pelo **próprio `awk` do gate** rodado sobre o arquivo e não à mão, cada `✅` com o hash do commit que atualizou o documento e cada `n/a` com a razão concreta. `tests/run-all.sh` → rc 0, `suite green`, **866** `ok`, **0** `FAIL`, rodada no estado final da árvore (depois dos seis commits desta fase E depois do `health`). `tests/check-todo.sh` → `109 finding(s), all within 8 lines and carrying anchor + date`, exatamente a catraca movida para `todo-findings 109` em `tests/health-baseline.txt` no mesmo commit dos 17 itens (`bd71f48`). `tests/check-lang.sh` → rc 0, `0 of 41 surface path(s) still in the allowlist, 0 new` — as quatro edições em `docs/` e `README.md` desta fase são inglês, como manda a superfície do kit. Espelho dos agentes conferido nesta sessão: `diff -q` dos **7** contra `.claude/agents/` sem nenhum stale, e nenhum `agents/*.md` foi tocado aqui. ✅ **CARIMBO DE MUTAÇÃO RE-EMITIDO NESTA FASE**, que era a pendência aberta desde `88432ee`: `./bin/sdd health` → `ok suite green`, `ok mutation: score: 227 caught, 0 known gap(s), of 227`, `ok TEST_CMD runs the suite`, `ok mutation stamp written — gate_PR can see that THIS content ran green`, `ok all 8 gates have a mutation in the catalogue`, `ok provenance: all 3 fixtures match the installed skills`, `ok ratchet: 1 known debt(s), none new`, `ok kit healthy` (rc 0, carimbo `e62cf049f5e032f3acc635dd5e82190c`, 18 min). Rodado **depois** do último commit que toca `bin/ tests/ templates/ config/` (`bd71f48`) e re-conferido idêntico depois da suíte final — os commits posteriores (`060cffe`, `1c59e74` e este handoff) tocam só `README.md`, `docs/` e `CONTEXT.md`, que estão **fora** da chave, então o carimbo entra válido no `gate_PR`. Árvore limpa."
---

# Documentação — O revisor só acha

> Escrito depois do código final e antes do PR. O gate desta fase é a tabela abaixo: **toda** área
> tocada pelo diff tem linha, `✅` exige hash e `n/a` exige justificativa concreta.

## TL;DR

O diff toca **35** arquivos (`git diff --name-only 35863d9..HEAD`, medido depois dos cinco commits
desta fase; 36 com este próprio handoff), e a documentação de contrato
**já vinha sendo escrita dentro da missão**: `docs/pipeline.md` entrou em **onze** commits, dez
deles com `bin/sdd` no mesmo diff — a regra do `CLAUDE.md` para mudança de contrato de artefato.
Esta sessão fez quatro coisas, nesta ordem:

1. **os dois diagramas de ordem canônica** (`README.md:12`, `docs/pipeline.md:26`) desenhavam
   `REVIEW` em linha reta enquanto o laço `REVIEW ⇄ EXEC` existe desde `03187e8`. Era o achado que
   o `F3` deixou explicitamente para esta fase, com o motivo: consertar só o README o poria à
   frente do doc de referência. Os dois no mesmo commit (`51a02dc`);
2. **a coluna Depois do `KAIZEN_LOG.md`** — oito células auto-declarantes, medidas com os comandos
   de `01-plano.md § Para a fase DOCS` (`bebff43`). Uma linha do gemba morreu honestamente e uma
   linha nova a substituiu (§ *Números do "depois"*);
3. **os 17 achados** que EXEC, QA e as quatro rodadas deixaram para transporte, com a catraca
   `todo-findings` 92 → 109 **no mesmo commit** (`bd71f48`);
4. **três derivas que ninguém tinha pego**, todas criadas pela própria missão: a linha de uso do
   `--by-mission` no `README.md` enumera o conteúdo da célula e ficou para trás do `review loop`;
   a rota do achado-sob-carimbo-morto, executada seis vezes nesta missão, não estava escrita em
   lugar nenhum (`060cffe`); e o verbete do `CONTEXT.md` dizia que o contrato do revisor mora em
   **cinco** lugares quando ele mora em **sete** — a frase estava certa sobre o commit que a
   escreveu e ensinava o próximo agente a editar cinco (`1c59e74`).

Seis commits: `51a02dc`, `bebff43`, `bd71f48`, `060cffe`, `1c59e74` e este handoff.

## Drift checklist

| Área tocada pelo diff | Documento correspondente | Status | Evidência |
|---|---|---|---|
| `bin/sdd` — `run_phase()`, `LAST_PHASE_TURNS` lido de `.num_turns` no mesmo JSON de onde sai o custo | `docs/pipeline.md` § Field reference, linha `turns` | ✅ | `88432ee`, no mesmo commit do código |
| `bin/sdd` — `autonomy_session_row()`, o campo `turns` na linha de sessão | `docs/pipeline.md`, tabela de campos — inclusive o que escalada e `gate_pass` **não** carregam | ✅ | `88432ee` |
| `bin/sdd` — `cmd_autonomy()`, o sufixo `review loop US$ X (N%)` por missão | `docs/pipeline.md` § `--by-mission`; `README.md` § Usage | ✅ | `88432ee` no `pipeline.md`; **só nesta fase** no README (`060cffe`) — aquela linha de uso **enumera** o conteúdo da célula e tinha ficado para trás, que é a mesma classe do `README.md:152` que o `F3` pagou |
| `bin/sdd` — `phase_task`/`phase_extra` do REVIEW: o contrato da sessão | `docs/pipeline.md` § REVIEW; `agents/sdd-reviewer.md`; `agents/sdd-executor.md`; `templates/review.md`; `templates/checkpoint.md` | ✅ | `03187e8` — cinco lugares, um commit. O **sexto** foi `c05b43b` (`README.md:152`, achado da QA) e o **sétimo** é desta fase: `51a02dc`, os dois diagramas de ordem canônica |
| `bin/sdd` — `review_scope_check()` e as três portas (`cmd_run` ×2, `cmd_retry`) | `docs/pipeline.md` § the review scope guard; `docs/failure-modes.md` § the review does not close at Grade A | ✅ | `c8c8ec7` a guarda; `b1cfc27` a barra final de `HANDOFF_DIR` e o limite do braço da baseline; `d06840a` o `core.quotePath`; `bffc79f` e `8cdec98` o fail-open do processo velho, nos três sítios |
| `bin/sdd` — `pipeline_log_line()` e `autonomy_append()`: a ordem da redireção e a guarda one-shot | `docs/pipeline.md`, o parágrafo do journal — "um aviso por journal, **e só esse aviso**" | ✅ | `604d280`, no mesmo commit do conserto; o censo do cabeçalho virou comando em `f8fcb49` |
| `bin/sdd` — `gate_REVIEW()`, o rabo do `GATE_WHY` | `docs/pipeline.md` § Field reference, a recusa que não nomeia arquivo de rodada | ✅ | `541b524` — as palavras **antes** do travessão ficaram verbatim de propósito: `historic_rounds` as lê |
| `bin/sdd` — superfície de comando (comandos, flags, `--help`) | `README.md` § Usage | ✅ | `060cffe`. Nenhum comando nem flag nasceu nesta missão — o que mudou foi o **conteúdo** de uma célula que a linha de uso enumera, e enumeração que fica para trás descreve uma saída que não é a do disco |
| `agents/sdd-reviewer.md` e `agents/sdd-executor.md` | eles mesmos + os espelhos em `.claude/agents/` | ✅ | `03187e8`, `541b524`, `8cdec98`; espelhos sincronizados por `./bin/sdd install --force` (nunca `cp`, nunca Edit) e conferidos nesta sessão: `diff -q` dos **7** vazio |
| `templates/review.md` | ele mesmo, e a citação dele em `agents/sdd-reviewer.md § 4` | ✅ | `03187e8` a seção `## Incrementos de conserto (R<n>)`; `384e36c` a prosa que ainda mandava a rodada registrar o que ela corrigiu |
| `templates/checkpoint.md` | ele mesmo | ✅ | `03187e8` — `## Incrementos de fix (QA e REVIEW)`, com o `R<n>` explicado ao lado do `F<n>` |
| `tests/check-autonomy.sh`, `check-dry-run.sh`, `check-gates.sh`, `check-templates.sh` — asserções novas | `KAIZEN_LOG.md`, linha "Asserções de `tests/run-all.sh`" | ✅ | `bebff43` — 842 → **866**, medido com `grep -c '^  ok'` sobre a saída real da suíte |
| `tests/check-mutation.sh` — mutantes novos | `KAIZEN_LOG.md`, linha "Catálogo de mutação" | ✅ | `bebff43` — 218 → **227**, com os **nove** nomeados um a um, como a célula prometia |
| `tests/check-lang.sh` — `docs/graphify.md` na `surface()`, piso 37 → 41 | o comentário do próprio piso (histórico das sete recontagens); `CONTEXT.md` D9 | ✅ | `a84adeb`. O buraco que sobrou — `surface()` **enumera** em vez de casar `docs/*.md` — virou item de backlog em `bd71f48`, junto com a **classe** do piso que fica para trás |
| `tests/run-all.sh` — a recusa de `SDD_TPL_SELFTEST_CHILD` no ambiente | cabeçalho do `tests/check-templates.sh` (limite declarado) | n/a | nenhum doc-índice enumera as variáveis que a suíte recusa; a primeira (`SDD_MUTANT`) também mora só no sensor, e escrever a segunda no `CLAUDE.md` seria profundidade no índice. A recusa tem probe próprio (`the suite refuses to run with the selftest skip variable set`) e limite declarado no cabeçalho |
| `tests/health-baseline.txt` — catraca `todo-findings` 92 → 109 | `TODO.md` (os 17 itens); `docs/failure-modes.md` § the ratchet | ✅ | `bd71f48` — itens e catraca no **mesmo** commit, contados por `tests/check-todo.sh` e nunca por `grep -c` |
| `config/schema.md` — `BUDGET_REVIEW_USD` e `REVIEW_MAX_ITER` | ele mesmo | ✅ | `a84adeb` — o teto **fica** 40 com o porquê escrito, e o `REVIEW_MAX_ITER` passa a dizer que o caminho normal gasta duas rodadas |
| `docs/pipeline.md` | ele mesmo | ✅ | onze commits, dez com `bin/sdd` no mesmo diff; o de hoje é `51a02dc` (o diagrama e a frase que liga os dois `⇄`) |
| `docs/failure-modes.md` | ele mesmo | ✅ | `a84adeb` e `8cdec98` (o que olhar quando a revisão não fecha em A); `060cffe` (a rota do achado sob carimbo morto) |
| `docs/graphify.md`, `.graphifyignore`, `.gitignore` | `CLAUDE.md` § Graphify; `CONTEXT.md` D23 e o verbete *Zona de competência* | ✅ | `1a51fd0`, o commit do grill — runbook, zona medida e ledger pareado nasceram juntos |
| `CLAUDE.md` | — | n/a | **nenhuma convenção de trabalhar no kit mudou.** O que mudou foi o contrato de uma **fase do pipeline**, cuja casa é `docs/pipeline.md` + `CONTEXT.md`; o princípio que esta missão aplicou (*"Um agente = uma troca de chapéu"*, § Ao mexer nos agentes) já estava escrito antes dela. A única convenção que operou **sem** estar escrita — a rota do achado fora de escopo com o carimbo morto — foi escrita onde este arquivo já roteia (`docs/failure-modes.md`, `060cffe`), não no índice. Escrever regra que não mudou é a dívida que o SDCA proíbe |
| `CONTEXT.md` — D22, D23 e dois verbetes | ele mesmo | ✅ | `1a51fd0` (grill), `a84adeb` (o *como pousou*), `24ee7bf` (o número refutado saindo do verbete durável) e **`1c59e74` nesta fase**: o verbete enumerava as **cinco** casas que o `03187e8` tocou, e o contrato mora em **sete** — a frase estava certa sobre aquele commit e ensinava o próximo agente a editar cinco. Conferido nesta fase, item a item, que a D22 continua batendo com o disco depois de `R4`–`R10` |
| `KAIZEN_LOG.md` — a entrada da missão | ele mesmo | ✅ | `a84adeb` o "antes", `8cdec98` as células auto-declarantes, `bebff43` o "depois" medido + o parágrafo do veredito imediato |
| `TODO.md` | ele mesmo + `tests/health-baseline.txt` | ✅ | `bd71f48` — 17 itens novos, âncoras **re-medidas** contra o HEAD de hoje |
| `docs/handoffs/20260901-o-revisor-so-acha/*` | — | n/a | são os artefatos da própria missão: registro, não documentação viva. Um deles ganhou **item de backlog** em vez de emenda — a refutação R2 do `30-handoff-qa.md:79` cita evidência que não existe —, porque handoff de fase encerrada é trilha de auditoria e reescrevê-lo apagaria o que a fase de fato afirmou |
| `docs/adr/*` | — | n/a | a D22 **é** decisão arquitetural e **já está registrada**, com as alternativas recusadas, em `CONTEXT.md` D22 e em `00-missao.md § Decisões do grill`; o contrato tem casa própria (`docs/pipeline.md § REVIEW`), que é o critério que a D11 e a D21 escrevem em tantas palavras para dispensar ADR. E **nenhuma decisão anterior foi revertida**: `gate_REVIEW` é byte a byte o de `main` (medido no `R5`, diferença de exatamente uma linha, e ela é comentário), `current_phase()` e o teto de rodadas não foram tocados |
| `docs/qa/` (registry de bugs) | — | n/a | é das skills `qa-report`/`qa-execution` e **não foi tocado**: não aparece em `git diff --name-only 35863d9..HEAD`. Os quatro `F<n>` nasceram de jornadas de terminal, com a proveniência de cada um em `30-handoff-qa.md § O que foi feito` |
| `CHANGELOG.md` | — | n/a | o kit não tem um, e é deliberado: mudança **com número** vai para o `KAIZEN_LOG.md` e mudança sem número vive no `git log` + nos handoffs. Criar um aqui seria um terceiro registro que ninguém mantém |

## Números do "depois" — como foram medidos

Os comandos são os de `01-plano.md § Para a fase DOCS`, rodados no fim desta sessão. O que segue é
o que **não** estava previsto e por isso vale escrito:

- **os turnos não vieram do ledger, vieram do disco.** 3 das 4 linhas REVIEW desta missão trazem
  `turns: null` (janela cega do runner velho, declarada cinco vezes), e a r4 concluiu que a metade
  "≤ 60 turnos" da M2 era *"inaferível nesta missão por construção"*. Ela é inaferível **no
  ledger**; a fonte de onde o ledger a lê estava em disco o tempo todo:
  `jq -r '.num_turns' .sdd/logs/<missão>/REVIEW-*.json` → **48 · 107 · 63 · 66**. A r4 é a única
  que carrega o campo no ledger (66) e ele bate com o JSON, o que é a testemunha de que a leitura
  é a mesma. É exatamente a direção que o achado da QA sugeriu ("a métrica citar `.sdd/logs/` como
  fonte no ciclo em que o campo nasce").
- **o corte do gemba mudou de significado, e o número sozinho enganaria.** "Cache-read depois do
  1º `Edit`" media o começo do laço de conserto; no desenho novo o primeiro `Edit`/`Write` de cada
  rodada é o próprio relatório (r1, r3, r4) ou um harness de reprodução em `/tmp` (r2). O proxy
  morreu com a causa. Quem o substitui é a medida **direta**, e ela é o resultado mais forte da
  missão: `git diff --name-only <head de abertura> <head de fechamento>` das quatro rodadas devolve
  **só** `40-review-r<N>.md` e `checkpoint.md` — **0 arquivos de código em 4 de 4** —, e nos streams
  todo `Edit`/`Write` das quatro sessões caiu no diretório da missão, mais um arquivo em `/tmp`.
- **a M2 continua partida ao meio, e a DOCS não a arredondou.** Por rodada o desenho entregou
  (US$ 17,92 → 16,38 → 6,71 → 6,83; média 11,96 contra 31,24); por laço piorou (US$ 102,39 = 68%
  de 150,42, contra os US$ 66,34 = 50% da missão de kit anterior e um alvo de 40). A alavanca que
  sobra está nomeada no `KAIZEN_LOG.md`: **10 sessões `R<n>` a US$ 5,46 cada**, contra o "US$ 1–2
  por boot" com que a decisão 6 do grill dimensionou a régua de lote.
- **a parcela do REVIEW no ledger inteiro não se moveu** (38,9% → 38,8%), e isso é informação, não
  ruído: o gasto saiu da fase e entrou no EXEC. O laço mudou de lugar antes de mudar de tamanho.

## Achados do `TODO.md` conferidos nesta missão

Nenhuma fase escreveu no `TODO.md` — as seis declararam o mesmo motivo (`tests/health-baseline.txt`
está na chave do carimbo de mutação). O transporte foi todo desta sessão, e o que foi conferido:

- **17 itens novos, forma medida e não afirmada:** `tests/check-todo.sh` → `109 finding(s), all
  within 8 lines and carrying anchor + date`. Cada item traz o quê, a âncora em `arquivo:linha`, o
  porquê, a direção e quem descobriu.
- **as âncoras foram re-medidas contra o HEAD de hoje**, e não copiadas dos relatórios: `R4`–`R10`
  só acrescentaram comentário ao `bin/sdd`, mas deslocaram tudo abaixo deles. `bin/sdd:5124` da r1
  virou `:5257`; `:2517` virou `:2650`; `tests/check-autonomy.sh:4387`/`:4398` virou `:4401`.
- **dois pares foram fundidos num item só:** o achado #1 da r4 e o do `R3` são o mesmo defeito
  visto de dois lados (a grafia de três espaços do `ok` e o `calibrate()` cego a ela); a r1 e a r2
  registraram o limite de `reviewscope_files()` separado. Transportar os quatro criaria dois itens
  que ninguém fecharia sem fechar o irmão.
- **um item deliberadamente NÃO transportado:** o achado que o `F2` registrou está riscado como
  `RESOLVIDO por 541b524` no `20-handoff-exec.md` — a r1 o achou de forma independente (achado #5),
  virou parte do lote `R5` e está em disco. Abrir item de backlog para defeito que não existe mais
  é o oposto do que o arquivo faz.
- **uma faxina deliberadamente NÃO feita:** os 4 itens já mergeados (`RESOLVIDO por 594ef07` ×3,
  `c7c2e2e` ×1) que o ciclo de vida do arquivo manda apagar viraram **item**, e não commit. A r1
  examinou o arquivo e roteou a limpeza para a triagem do `sdd kaizen`; apagá-los aqui seria a DOCS
  decidindo por cima da rodada que olhou.
- **catraca movida no mesmo diff:** `todo-findings` 92 → 109 em `bd71f48`. Contada por
  `tests/check-todo.sh`, nunca por `grep -c` — este responde um a mais, contando a linha de exemplo
  do bloco cercado do cabeçalho.

## Estado do repo

- **Branch:** `feat/o-revisor-so-acha` — **51** commits à frente de `main` (`35863d9`), com este
  handoff; sem remoto (quem faz `push` é a fase PR).
- **Working tree:** limpo.
- **Suíte:** `tests/run-all.sh` → rc 0, `suite green`, **866** `ok`, 0 FAIL, rodada no estado final.
- **E2E:** `E2E_CMD=""` — o kit não tem interface; a verificação equivalente é o dry-run, dentro da
  suíte.
- **Checkpoint:** `I1`–`I4`, `F1`–`F4` e `R1`–`R10` todos `done`. Nenhuma linha `pending`.

## Boot da próxima fase

`PR` (`sdd-publisher`). Ler, nesta ordem: `00-missao.md`, este arquivo, `40-review-r4.md`
(a rodada que fechou em A) e `20-handoff-exec.md § Rodada REVIEW r3`. O corpo do PR sai de
`templates/pr-body.md`.

Três coisas que o PR precisa carregar e que não estão em nenhum outro lugar juntas:

1. **a M2 não fecha, e as duas metades apontam para lados diferentes** — por rodada o desenho novo
   entregou, por laço piorou. Os números estão no `KAIZEN_LOG.md` e no § acima; o PR os cita, não
   os re-mede;
2. **a evidência de que o contrato pegou é o diff, não o `pipeline.log`** — 0 arquivos de código em
   4 de 4 rodadas. O `grep -c REVIEW-EDITED-CODE` responde `0` nesta missão **por não ter sido
   carregado** (o processo `sdd run` é anterior à guarda), e essa distinção está declarada em três
   sítios do runner e do `docs/pipeline.md`;
3. **a janela 3 abre no sha do merge** (padrão D19) — 2–3 missões reais do `sales_quote`, sem
   commit na `main` do kit, e então `sdd kaizen`.

## Pendências / Decisions for a Human

- **O teto de rodadas está alcançado** (`review_rounds_on_disk` = 4 contra `REVIEW_MAX_ITER=3`).
  Não afeta este pipeline — o caminho derivado daqui é DOCS → PR e o `gate_REVIEW` lê a nota do
  arquivo mais recente, que é A. Mas se o PR trouxer código novo, a re-revisão precisa da porta
  `--phase REVIEW`, que é isenta por construção.
- **A régua de lote precisa de uma constante nova, e é decisão de desenho.** A decisão 6 do grill
  dimensionou "MEDIUM/LOW baratos viram um lote por rodada" supondo US$ 1–2 por boot de sessão
  EXEC; medido nesta missão, são **US$ 5,46**. A direção está certa e a constante está errada por
  3 a 5×. Quem decide o que fazer com isso (lotes maiores? achado caro subindo o corte para
  `TODO_FILE`?) é a missão que a janela 3 der à luz, com o número na mão.
- **O conserto durável da janela cega do runner velho** (o `sdd run` comparar o hash do `bin/sdd`
  na entrada) segue como decisão humana registrada em `40-review-r1.md § Pendências`: pode reprovar
  missão saudável em voo. O que esta fase fez foi transportar o achado com as **duas** âncoras.

## Riscos e não-feitos

- **Nenhum instrumento mede prosa de contrato fora de `templates/`**, e esta missão pagou o preço
  duas vezes: o `README.md:152` sobreviveu à suíte verde e só caiu numa jornada de QA; os dois
  diagramas de ordem canônica sobreviveram à QA e às quatro rodadas, e só esta fase os pegou. O
  achado está no `TODO.md`; enquanto ele não fecha, **contrato mudado é varredura manual**.
- **O `docs/pipeline.md` continua sendo um índice que carrega profundidade** — o item da divisão
  em `references/` está aberto no `TODO.md` desde `20260817-eixo-do-juiz`, e esta missão o
  engordou em 135 linhas. Não foi executado aqui de propósito: é refator de estrutura e merece a
  missão dele, e fazê-lo no meio desta seria exatamente o "já que estou aqui" que o kit recusa.
- **A coluna Depois é de uma missão só**, no repo que constrói o kit, com um `sdd run` cujo
  processo carregava o runner pré-`88432ee`. Não é a M1, e a linha de base de comparação
  (`20260831`) também é uma missão só. Está dito na própria entrada do `KAIZEN_LOG.md`.

## Achados fora de escopo

Nenhum novo nesta fase. Os 17 que as fases anteriores deixaram foram transportados ao `TODO.md`
em `bd71f48`, com a catraca no mesmo commit — é a rota que agora está escrita em
`docs/failure-modes.md`, e não mais só re-derivada por cada fase.
