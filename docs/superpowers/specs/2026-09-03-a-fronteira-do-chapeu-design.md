# A fronteira do chapéu — o chapéu declara, o runner aplica, o artefato prova (2026-09-03)

> Spec da próxima missão de kit, escrita com o humano presente numa sessão de brainstorming
> (Fable), no mesmo dia em que o PR #35 (a anatomia do agente, lote 1) foi mergeado. Fecha a
> dívida da seção 2 da rule [`anatomia-do-agente.md`](../../../.claude/rules/anatomia-do-agente.md)
> ("ferramentas por fase — é a próxima missão desta rule") e a metade "fronteira" da seção 6. Todo
> número aqui saiu de um comando, e o comando está no apêndice; nenhum foi escrito de memória.

## 1. Por que esta missão, e não outra

A rule da anatomia nomeia três dívidas com dono "próxima missão de kit". Uma delas já estava
fechada antes de a linha ser escrita: "não existe *pare depois desta fase*" — existe, é
`--phase X --max-phases 1`, e foi exatamente o que o incidente das 18:45 usou. Sobram duas, e a
medição desta sessão mostrou que elas têm **raiz comum**: a sessão headless herda o harness inteiro
do humano. O que separa as duas é o instrumento e o dinheiro, e por isso viraram duas missões:

| | Fronteira (esta missão) | Dieta (a seguinte) |
|---|---|---|
| o que fecha | rule 2 (ferramentas por chapéu) e a metade da rule 6 (guarda de kit vira parada) | rule 3 (contexto) |
| número que move | MCP visível 9 → 0; ferramentas dos chapéus mecânicos 29 → ~10; escritas fora do chapéu → 0 | releitura dos artefatos, US$ 35–52 por missão |
| precondição de | publicação (nenhum estranho instala um kit cuja fase headless vê o Gmail do dono) | custo |

Decisão do humano nesta sessão: **fronteira agora, dieta depois**, com o instrumento de censo
entrando nesta missão para que a dieta nasça com baseline no kit e não num scratchpad.

## 2. O que foi medido

Duas missões, 43 sessões, todos os `stream.jsonl` e `usage` dos `.json` em `.sdd/logs/`:
`20260902-o-rascunho-legado-fala-cru` (SQ-115, `sales_quote`, 18 sessões com JSON de resultado;
19 streams — a EXEC das 22:46 morreu sem resultado e conta só onde o stream basta) e
`20260901-o-revisor-so-acha` (o kit sobre si mesmo, 25 sessões).

### 2.1 Ferramentas por fase (SQ-115)

| Fase | Modelo | Ferramentas chamadas | Bash dominante |
|---|---|---|---|
| TICKET | sonnet | Bash 17, Read 7, Write 1, Edit 1, Skill 1 | git, curl, acli |
| EXEC ×9 | opus | Bash 358, Edit 129, Read 88, Write 5, ToolSearch 2, Monitor 1 | git, npm, npx |
| QA | opus | Bash 51, Read 8, Edit 5, Write 3 | git, grep |
| REVIEW ×4 | opus + sonnet | Bash 639, Read 121, Edit 26, Agent 10, ListAgents 6, Write 5, Skill 3 | git diff/show/log 173, git commit 4, cp 20 |
| DOCS | sonnet | Bash 52, Read 15, Write 3, Edit 2 | git, grep |
| PR ×2 | sonnet | Bash 44, Read 7, ScheduleWakeup 2, Write 1, Edit 1 | gh, sleep 180, ps, kill |

- **Negações de permissão: 0 em 43 sessões.** O `--allowedTools "Bash"` de hoje nunca negou nada
  a ninguém; a lista é decorativa.
- **O revisor read-only** escreveu 3× `packages/frontend/src/test/zz-scratch-probe.test.tsx` na
  árvore de código, abriu 10 subagentes (`general-purpose`, sonnet, despachados pela skill
  `codereview`), e fez 4 `git commit` (os três artefatos que o contrato permite).
- **Só a fase PR empurra.** `git push` ×2 e `gh pr create` ×1, ambos na PR da missão do kit;
  TICKET faz `git checkout -b`; REVIEW fez um `gh pr view` (leitura). Nenhuma outra fase tocou em
  `push`, `gh pr` ou `merge`.
- **Skills por fase:** REVIEW invoca `codereview:codereview` (5×); TICKET invoca `ticket` (1×);
  QA:plan/QA:exec são os prompts `/qa-report` e `/qa-execution`. Nenhuma fase chamou ferramenta
  MCP nenhuma.

### 2.2 O que a sessão headless enxerga

A linha `init` do stream de qualquer sessão lista o que o modelo tem à mão. Na r1 de REVIEW da
SQ-115: **104 ferramentas** (29 nativas + 75 MCP), **9 servidores MCP** — `code-search`,
`designer`, `playwright`, `atlassian`, `stitch`, e os conectores da conta claude.ai do humano:
Google Drive, Context7, Google Calendar, **Gmail** —, 14 agentes, 109 skills. O `atlassian` traz
`createJiraIssue`, `editJiraIssue`, `createConfluencePage`. De onde vem: `~/.claude.json`,
`projects["…/sales_quote"].mcpServers` (escopo *local* do humano), mais o `code-search` global e o
`designer` do `.mcp.json` do alvo. Nenhuma fase usou nenhum deles.

### 2.3 O prefixo fixo, decomposto por probe

Probes `claude -p "Reply with the single word: ok" --model haiku --max-turns 1` no `sales_quote`,
com o env do harness apagado como o `run_phase` faz. Tokens = `input + cache_creation +
cache_read` do primeiro e único turno (tokenizer do haiku; nas sessões reais opus o mesmo prefixo
mede 94K):

| Probe | Flags | Tokens | Leitura |
|---|---|---|---|
| A | hoje: `--setting-sources user,project,local --agent sdd-executor` | 70 718 | baseline |
| B | `--setting-sources project,local` | 69 268 | tirar `user` poupa **1,4K (2%)** e quebra REVIEW, TICKET e QA, cujas skills moram em `~/.claude/skills` e no marketplace do humano — **alavanca refutada** |
| C | B + `--tools Bash,Read,Edit,Write` | 83 631 | `--tools` **sobe** 13K: desliga o carregamento adiado e os 75 esquemas MCP entram inteiros |
| E | `--safe-mode` (sem CLAUDE.md, skills, plugins, MCP, agentes) | 17 874 | o piso do harness |
| F | A sem `--agent` | 75 074 | o agente **substitui** ~4K do prompt padrão |
| G | diretório vazio, `user,project,local` | 23 520 | skills + plugins + MCP do humano ≈ 5,6K |
| I | A + `--disallowedTools Edit,Write,Agent` | 67 831 | remove da visão do modelo **e** poupa 3K |
| J | I + `--strict-mcp-config` | 66 537 | MCP some por inteiro; −4K (6%) |

Conclusão: dos ~71K, **~52K (73%) são o `CLAUDE.md` + `.claude/rules/` do alvo** (130 KB no
`sales_quote`; no kit, 48 KB e 48K tokens). O kit não corta o livro de regras do alvo — isso é da
dieta, como **sensor** no preflight, nunca como corte. O que o kit corta é o que a fase não
declara: MCP e ferramenta.

### 2.4 O que `--disallowedTools` faz de verdade

- Probe H (`--tools Bash,Read`): o modelo listou só `Bash, Read` + as 75 MCP. `--tools` remove
  nativas, não MCP.
- Probe L (repo git vazio, `--disallowedTools "Bash(git push:*)"`, prompt manda rodar
  `git push --dry-run` e `printf sdd-ok`): resposta `DENIED for command 1. Command 2 returned:
  sdd-ok`, e `permission_denials: [{"tool":"Bash","cmd":"git push --dry-run origin main"}]`.
  **O padrão nega, o resto do Bash segue livre, e a negação fica no JSON da sessão** — artefato.
- Docs do harness (via `claude-code-guide`, `code.claude.com/docs/en/sub-agents.md`): em `-p`
  com `--agent`, o frontmatter honra `model`, `permissionMode` e `skills`; **`tools:` e
  `disallowedTools:` valem só para subagente**. Logo o chapéu declara e o **runner** aplica por
  flag; nada muda se um dia o harness passar a honrar a chave, porque os dois concordam.
- Probe K: um agente com chave desconhecida (`writes:`) no frontmatter carrega normalmente.

### 2.5 A releitura, que é onde o dinheiro está (contexto para a missão 2)

| | SQ-115 | missão do kit |
|---|---|---|
| turnos / custo | 1067 / US$ 174 | 1501 / US$ 167 |
| cache-read | 176M tokens ≈ **US$ 88 (51%)** | 178M ≈ **US$ 89 (53%)** |
| prefixo fixo × turnos | 94K × 1067 ≈ US$ 50 (29%) | 48K × 1501 ≈ US$ 36 (22%) |
| carregar as leituras de `docs/handoffs/` pelo resto da sessão (estimado) | **US$ 35 (20%)**: REVIEW 17,55, EXEC 12,36 | **US$ 52 (31%)**: REVIEW 23,98, EXEC 19,48 |
| `checkpoint.md` relido | 55× em 10 sessões EXEC (288 KB), 30× em 4 REVIEW (124 KB) | 105× em 18 EXEC (692 KB) |
| composição do checkpoint da SQ-115 | 66 KB; **54 KB são as notas de execução (88 notas)** | |

Preço usado: Opus 5 cobra US$ 0,50/M em cache-read (skill `claude-api`; bate com o custo
reportado da r1 de REVIEW: 17,3M tokens → US$ 8,66 de US$ 14,02).

## 3. Decisões tomadas com o humano

| # | Decisão | Alternativas recusadas |
|---|---|---|
| D1 | A próxima missão é a fronteira do chapéu | publicação primeiro (a própria auditoria diz que a fronteira a precede); rota das pendências de handoff (318, sem número de custo) |
| D2 | Fronteira agora, dieta na missão seguinte; o censo entra nesta como instrumento | as duas numa missão (~12 incrementos; o laço de revisão do kit cresce com a superfície) |
| D3 | "Apto para outros projetos da organização" vira critério de seis linhas, cada uma provada por comando (§ 6), e **a linha 4 — missão real num segundo repo da organização — é obrigatória** | dry-run em fixture (prova instalação, não sessão headless num repo de outra forma); repo de brinquedo público (demo, não prova) |
| D4 | Abordagem A: o chapéu declara no frontmatter, o runner aplica por flag, o artefato prova | B, tudo em config (14 chaves; a fronteira deixa de viajar com o agente portátil); C, só artefato sem cortar ferramenta (regra 2 continua aberta) |
| D5 | Um chapéu, uma fronteira: TICKET sai do publisher para `sdd-ticket.md` | publisher serve as duas fases e o runner nega push só no TICKET (segunda definição da fronteira, no runner) |
| D6 | `KIT-TOUCHED` deixa de ser aviso e vira parada, na mesma porta | manter aviso |
| D7 | `--setting-sources` fica como está; a hipótese e o número entram no `KAIZEN_LOG.md` como refutação | |

## 4. A fronteira de cada chapéu

### 4.1 Três chaves de frontmatter, linha única, separadas por vírgula

- `disallowedTools:` — chave **padrão** do harness. O que este chapéu nega **além** da base.
- `writes:` — chave do kit. Globs do que a fase pode ter tocado ao terminar (commits **e** árvore).
  Placeholders expandidos pelo runner: `$HANDOFF_DIR`, `$MISSION`, `$TODO_FILE`, `$QA_DOCS_PATH`,
  `$E2E_DIR`. Vazio ⇒ tudo.
- `mcp:` — chave do kit. Servidores MCP que a fase pode ver. Vazio ⇒ `--strict-mcp-config`.

O runner guarda **uma** lista base, `HAT_DENY_BASE`, com o que nenhuma fase usou em 43 sessões:
`CronCreate, CronDelete, CronList, DesignSync, EnterWorktree, ExitWorktree, RemoteTrigger,
SendMessage, PushNotification, Workflow, NotebookEdit, ReportFindings, ListMcpResourcesTool,
ReadMcpResourceTool, ReadMcpResourceDirTool, WebSearch, WebFetch`. Base é propriedade do pipeline;
a linha do chapéu é do chapéu. Não são duas definições da mesma coisa.

### 4.2 A tabela

| Chapéu | Fase | `disallowedTools:` (além da base) | `writes:` |
|---|---|---|---|
| sdd-executor | EXEC | `Bash(git push:*)`, `Bash(gh pr create:*)`, `Bash(gh pr merge:*)`, ScheduleWakeup, Monitor | (tudo; a guarda de kit cuida do kit) |
| sdd-reviewer | REVIEW | idem | `$HANDOFF_DIR/$MISSION/**`, `$TODO_FILE`, `tests/health-baseline.txt` |
| sdd-qa | QA:plan, QA:exec, QA:close | idem | `$HANDOFF_DIR/$MISSION/**`, `$QA_DOCS_PATH/**`, `$E2E_DIR/**` |
| sdd-docs | DOCS | idem + Agent, ListAgents, Skill | `$HANDOFF_DIR/$MISSION/**`, `README.md`, `CLAUDE.md`, `CONTEXT.md`, `CHANGELOG.md`, `KAIZEN_LOG.md`, `.claude/rules/**`, `docs/**`, `$TODO_FILE` |
| sdd-publisher | PR | `Bash(gh pr merge:*)`, `Bash(git merge:*)`, Agent, ListAgents, Skill, ScheduleWakeup, Monitor | `$HANDOFF_DIR/$MISSION/**` |
| sdd-ticket (novo) | TICKET | como o docs | `$HANDOFF_DIR/$MISSION/**` |
| sdd-kaizen | KAIZEN | como o executor | `$HANDOFF_DIR/**`, `$TODO_FILE`, `KAIZEN_LOG.md` |
| sdd-planner | interativo | declara; o runner nunca o lança | `$HANDOFF_DIR/$MISSION/**` |

`gh pr view` fica permitido a todos: o revisor leu o PR da missão anterior uma vez, e ler não é
sair do chapéu. `mcp:` nasce vazio em todos. O executor e o revisor **mantêm `Agent`**: o revisor porque o
`codereview` despacha subagentes (10 chamadas medidas); o executor porque o prompt dele manda
levar análise para subagentes (`agents/sdd-executor.md:71`), embora o censo mostre **zero** usos
em 27 sessões — a contradição vai para as pendências, não se resolve aqui. `tests/health-baseline.txt`
no revisor é a exceção que o `REVIEW-EDITED-CODE` já abria: registrar achado move a catraca.
A `ticket` skill cita `mcp__atlassian__editJiraIssue` como alternativa ao `acli` (46 menções contra
7); a sessão TICKET medida usou só `acli` e `curl`. Se o primeiro incremento provar que a skill
precisa do MCP como fallback, `sdd-ticket` declara `mcp: atlassian` e é o único chapéu com Jira —
que é a regra 6 da anatomia: credencial só na fase cujo gate a exige.

## 5. O runner: aplicar, parar, provar

### 5.1 Aplicar

`run_phase` passa `--strict-mcp-config` (quando `mcp:` é vazio) e
`--disallowedTools "$HAT_DENY_BASE,<linha do chapéu>"`. A projeção `--dry-run` imprime o comando,
e é assim que `tests/check-dry-run.sh` prova por artefato que **cada** fase leva as duas flags.

`phase_hat()` é a **única** tabela passo → chapéu, e `phase_agent()` passa a derivar dela: os
passos QA:plan e QA:exec continuam subindo **sem** `--agent` (são os prompts das skills), mas
herdam a fronteira do `sdd-qa`. Duas `case` sobre o mesmo enum era o que o `CLAUDE.md` proíbe.

### 5.2 Parar

`hat_guard_check "$phase"` corre nas **mesmas quatro portas** do `kit_guard_check` (as duas do laço
do `cmd_run`, `cmd_retry`, `cmd_close`), depois de `moved2` ser amostrado, pelo mesmo motivo que
o `CLAUDE.md` documenta para a guarda de kit. Ele lê o diff `before..head` dos commits da fase (o
que o `REVIEW-EDITED-CODE` já calcula em `bin/sdd:~2500`) **e** o `git status --porcelain`, e casa
cada caminho com `writes:` expandido. Arquivo fora ⇒ `autonomy_blocked_row "hat-crossed" …`,
linha `HAT-CROSSED` no `pipeline.log`, `ON_ESCALATION_CMD`, `return 3` — a forma do `dirty-tree`.
O aviso `REVIEW-EDITED-CODE` deixa de existir porque virou este caso geral; o comentário de
`bin/sdd:2424` que ensina a não ler `grep -c REVIEW-EDITED-CODE` como prova é reescrito para o
nome novo. `KIT-TOUCHED` ganha `autonomy_blocked_row "kit-touched" …` e `return 3` no mesmo sítio
(D6).

Contrato do marcador, herdado do `CLAUDE.md`: **um** setter, reset na entrada dele, não sobrevive
à volta; **um probe por porta** em `tests/check-autonomy.sh`, no molde dos regimes 1, 4, 5 e 7 da
guarda de kit. `--dry-run` não arma nada.

### 5.3 Provar

Depois da sessão, o runner lê a linha `init` do stream e `permission_denials` do JSON — os dois já
estão em `.sdd/logs/` desde o I10 — e grava três campos na linha de sessão do ledger:
`mcp_seen` (servidores MCP visíveis), `tools_leaked` (ferramentas da lista de negação que ainda
apareceram em `tools`) e `denials`. `mcp_seen > 0` ou `tools_leaked > 0` é **a mesma escalada**
`hat-crossed`, com o motivo dizendo qual — o harness não honrou a flag, e uma fase que enxerga o
que não declarou não é fase do pipeline. Um marcador, uma definição, motivos diferentes.

⚠️ A linha `init` grafa `Task` onde o `tool_use` grafa `Agent`. O nome que a comparação usa se fixa
por probe no primeiro incremento, nunca de memória.

## 6. O critério de aptidão: ADR 0007 e `sdd health --release`

"Apto para outros projetos da organização" só vale como **linha verde de comando** com dono por
artefato. Publicar em aberto é decisão separada, com o número ao lado: **48 dos 729 commits**
citam `sales_quote`, 3 citam `JRC`. Estado medido em 2026-09-03:

| # | Linha | Prova por comando | Hoje | Fecha em |
|---|---|---|---|---|
| 1 | instala e passa no preflight num repo que **não** é o `sales_quote`, numa máquina que não é esta | ledger global: sessão em `repo` ≠ kit ≠ `sales_quote` no `kit_sha` corrente | nunca; alvo n=1 | missão 3 |
| 2 | toda dependência de terceiro é manifesto com origem | o preflight nomeia cada skill ausente **e de onde vem** | nomeia 4 skills; 6 moram no escopo do humano, 2 num marketplace pessoal | missão 3 |
| 3 | a fase headless só vê o que o chapéu declara | `mcp_seen = 0` e `tools_leaked = 0` em toda linha do ledger da missão | 9 MCP, 104 ferramentas | **esta** |
| 4 | uma missão real de ponta a ponta num 2º repo da organização, PR aberto, dentro do teto, sem intervenção | ledger da missão | nunca | missão 3 |
| 5 | superfície sem identificador de cliente, e com licença | `grep` → 0 fora de handoffs/TODO/KAIZEN; `LICENSE` existe | `sales_quote` em 7 arquivos, `SQ-` em 15, `j0ruge` 1, `chewiesoft` 2; sem licença | missão 3 |
| 6 | suíte, catraca e carimbo verdes | `sdd health` | verde | já |

- **ADR 0007** (em inglês — `docs/adr/*.md` está na superfície do `check-lang`) registra as seis
  linhas, o dono de cada artefato e a decisão de separar "apto" de "público".
- **`sdd health --release`** é flag opt-in, como `--with-mutation`: imprime as seis linhas em
  verde ou vermelho e sai 1 se alguma reprova. Nasce com **quatro vermelhas**, e é isso que se
  quer: um "pronto" que reprova. `sdd health` sem a flag não muda, então nenhum gate em voo sofre.
  As linhas 1 e 4 leem o ledger global (`~/.sdd/autonomy-log.jsonl`), que já carimba `repo` e
  `kit_sha` por sessão; a linha 2 lê uma tabela `skill_origin()` de definição única no `bin/sdd`,
  que o preflight passa a imprimir.

## 7. Os lugares do contrato, no mesmo commit

- **Agentes:** sete existentes ganham as três chaves; `agents/sdd-ticket.md` nasce da seção
  "TICKET phase" do publisher (`agents/sdd-publisher.md:91-129`); `phase_hat()` mapeia TICKET →
  `sdd-ticket`; `sdd install --force` sincroniza os espelhos — nunca `cp`, nunca Edit.
- **`docs/pipeline.md`:** tabela de fases com o chapéu novo; o parágrafo de `--allowedTools`
  (`:538`) ganha as duas flags; a lista de escaladas ganha `hat-crossed` e `kit-touched`.
- **`config/schema.md`:** a linha de `ALLOWED_TOOLS` explica que negação vence permissão, e os
  placeholders de `writes:`. Nenhuma chave de config nova (YAGNI: não há botão para desligar a
  fronteira).
- **`README.md`:** "the 6 agents" (`:140`, `:146`) vira 8, o que fecha o item do `TODO.md`
  (`:663`, "diz 6 e existem 7").
- **`.claude/rules/anatomia-do-agente.md`:** as dívidas das seções 2 e 6 que esta missão fecha são
  **apagadas**; a linha 7 troca "não existe pare depois desta fase" por `--phase X --max-phases 1`.
- **`CONTEXT.md`:** verbete "Fronteira do chapéu" (o que é, quem declara, quem aplica, quem prova).
- **Suíte:** `tests/check-hat.sh` (14º sensor) entra nos **cinco** lugares — linha `run` do
  `run-all.sh`, `LINT_FLOOR` 15 → 16, os pisos de superfície do `check-pipefail.sh` e do
  `check-lang.sh`, e o fixture do selftest do pipefail. Ele mede o parser das três chaves, a
  expansão de placeholders e o casamento de globs, com fixtures de `init` **copiados** dos logs
  reais e o caminho no comentário de proveniência. `check-dry-run.sh` ganha as asserções de flag
  por fase; `check-autonomy.sh` os quatro probes de porta e os três campos de ledger;
  `check-preflight.sh` a contagem de agentes. **Catálogo de mutação:** um mutante por flag
  (`--strict-mcp-config` some; `--disallowedTools` some), um pelo guard (`hat_guard_check` sempre
  0), um por porta (as quatro), um pela leitura do `init` (`mcp_seen` sempre 0).
- **`KAIZEN_LOG.md`:** entrada da hipótese refutada do `--setting-sources` (§ 2.3, probe B) agora;
  entrada da fronteira quando a primeira missão pós-merge medir o depois.
- **`tests/health-baseline.txt`:** move se o `TODO.md` mudar (o item dos "6 agentes" sai), e é a
  colisão conhecida com o carimbo: `./bin/sdd health` roda **depois** do último commit de código.

## 8. Números da missão

| Medida | Antes | Depois esperado | Instrumento |
|---|---|---|---|
| servidores MCP por sessão | 9 | 0 | `mcp_seen` no ledger, lido do `init` |
| ferramentas nativas visíveis, chapéus mecânicos (DOCS, PR, TICKET) | 29 | ~10 | `tools_leaked` + a lista do `init` |
| arquivos tocados fora do chapéu por missão | 1 (revisor, 3 escritas) | 0, ou a linha para | `hat-crossed` no ledger |
| prefixo fixo por turno (haiku, `sales_quote`) | 70,7K | 64K–67K (probes I e J) | `usage` do JSON da sessão |
| negações registradas | 0 (nada era negado) | > 0 só quando um chapéu tentar sair | `denials` no ledger |

O "depois" se mede na primeira missão do `sales_quote` após o merge, com o mesmo censo do apêndice
rodando **de dentro do kit** (`sdd autonomy` ganha a coluna). Sem esse número, a entrada do
`KAIZEN_LOG.md` não é escrita.

## 9. Riscos e limites declarados

- **Ferramenta negada que um gate precisa** deixaria a fase insatisfazível — a classe que o
  princípio 1 proíbe. Resposta: a tabela sai do censo medido, `denials` fica no ledger, e a primeira
  missão pós-merge é vigiada; um `denials > 0` numa fase que não deveria querer sair é achado.
- **`writes:` apertado demais para um alvo** (a QA escrevendo screenshots fora de `$QA_DOCS_PATH`,
  por exemplo) para a linha. A mensagem nomeia o arquivo e o chapéu; a saída é editar a linha do
  chapéu no kit e `sdd install --force`, nunca um botão de config.
- **A fronteira é do harness, não do sistema operacional.** Um chapéu com `Bash` continua podendo
  fazer qualquer coisa que um shell faz; `Bash(git push:*)` nega a grafia, não a intenção
  (`git p<TAB>` é a mesma coisa; `gh api` também). A sandbox de verdade — worktree ou container —
  segue como dívida da rule 6, com desenho próprio (ADR), fora desta missão.
- **`Task` × `Agent`** na linha `init`: fixado por probe, declarado aqui até lá.
- **Outros harnesses** ignoram `writes:` e `mcp:`; `disallowedTools:` é chave deles. O agente
  segue portátil; a fronteira, não. Está no verbete do `CONTEXT.md`.

## 10. Fora do escopo, e nomeado

- **Dieta de contexto** (missão 2): digest do checkpoint (54 KB de notas relidos 5–7× por sessão),
  `sdd preflight` imprimindo a conta do `CLAUDE.md` do alvo por missão, o censo de releitura como
  instrumento. Os números estão em § 2.5.
- **Aptidão** (missão 3): linhas 1, 2, 4 e 5 de § 6, incluindo a missão real num segundo repo da
  organização, a origem de cada skill de terceiro, `LICENSE` e a limpeza da superfície.
- **`--setting-sources`:** refutado (§ 2.3); não se mexe.
- **Frontmatter `tools:`:** o harness a ignora na sessão principal; não se escreve.
- **O executor e os subagentes:** o prompt manda, o censo mede zero. Pendência com dono (o
  planner da missão 2, que revisita os prompts para a dieta).
- **Sandbox real** (worktree/container): ADR próprio.

## 11. O roteiro

```text
missão 1  a fronteira do chapéu     ← esta spec     fecha § 6 linha 3, rule 2, rule 6 (metade)
missão 2  a dieta de contexto        ← § 2.5          fecha rule 3
missão 3  apto para a organização    ← § 6            fecha linhas 1, 2, 4, 5; publicar é decisão à parte
```

Cada missão do roteiro cita qual linha de § 6 fecha, e `sdd health --release` é o placar.

## Apêndice — os comandos de onde os números saíram

```bash
# ferramentas por fase (tool_use por nome), numa missão
for s in .sdd/logs/<missão>/<FASE>-*.stream.jsonl; do
  jq -r 'select(.type=="assistant") | .message.content[]? | select(.type=="tool_use") | .name' "$s"
done | sort | uniq -c | sort -rn

# o que a sessão enxergava (linha init): ferramentas, MCP, agentes, skills
jq -c 'select(.type=="system" and .subtype=="init")
       | {n_tools: (.tools|length), mcp: (.mcp_servers|map(.name)), agents: (.agents|length), skills: (.skills|length)}' \
   .sdd/logs/<missão>/REVIEW-*.stream.jsonl | head -1

# custo, turnos, cache-read, negações — por fase
jq -s '{sessions: length, turns: (map(.num_turns)|add), cost: (map(.total_cost_usd)|add),
        cache_read_M: (map(.usage.cache_read_input_tokens)|add/1e6), denials: (map(.permission_denials|length)|add)}' \
   .sdd/logs/<missão>/<FASE>-*[0-9a-f].json

# prefixo fixo no 1º turno de cada sessão (cache_read + cache_creation + input)
for s in .sdd/logs/<missão>/*.stream.jsonl; do
  printf '%s ' "$(basename "$s" .stream.jsonl)"
  jq -c 'select(.type=="assistant") | .message.usage | (.cache_read_input_tokens + .cache_creation_input_tokens + .input_tokens)' "$s" | head -1
done

# git push / gh / merge por fase
jq -r 'select(.type=="assistant") | .message.content[]? | select(.type=="tool_use" and .name=="Bash") | .input.command' \
   .sdd/logs/<missão>/<FASE>-*.stream.jsonl | grep -oE 'git push[^;&|]{0,30}|gh (pr|api)[^;&|]{0,20}' | sort | uniq -c

# de onde vêm os MCP que a sessão vê
jq -r '.projects | to_entries[] | select(.value.mcpServers|length>0) | "\(.key): \(.value.mcpServers|keys|join(","))"' ~/.claude.json

# critério de aptidão, linha 5
for w in sales_quote JRC SQ- j0ruge chewiesoft; do
  printf '%-12s files=%s\n' "$w" "$(grep -rlE "$w" bin agents docs/*.md docs/adr templates config README.md tests | wc -l)"
done; git log --oneline -S sales_quote | wc -l; git rev-list --count HEAD; ls LICENSE*
```

O probe de prefixo (§ 2.3) é `claude -p "Reply with the single word: ok" --model haiku --max-turns 1
--output-format json --permission-mode acceptEdits --allowedTools Bash --max-budget-usd 1` mais as
flags de cada linha, rodado no `sales_quote` com `env -u CLAUDECODE -u CLAUDE_CODE_CHILD_SESSION
-u CLAUDE_CODE_MESSAGING_SOCKET -u CLAUDE_CODE_MESSAGING_TOKEN -u CLAUDE_PID -u CLAUDE_CODE_SESSION_ID
-u CLAUDE_CODE_BRIDGE_SESSION_ID`, que é o `HARNESS_ENV_UNSET` do `run_phase`. Cada probe custou
entre US$ 0,11 e US$ 0,17.
