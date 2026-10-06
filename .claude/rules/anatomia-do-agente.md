# A anatomia do agente — sete componentes, o que o kit faz e o que declara como dívida

> Rule deste repositório, carregada em toda sessão que trabalha **no kit**. Nasceu em 2026-09-03
> da auditoria [`docs/superpowers/specs/2026-09-03-anatomia-do-agente.md`](../../docs/superpowers/specs/2026-09-03-anatomia-do-agente.md),
> depois de a missão `20260902-o-rascunho-legado-fala-cru` custar US$ 174 com **76% num laço de
> revisão sem nenhum achado funcional**. Um sistema de agente tem sete componentes; sem eles o
> pipeline é uma máquina de gastar tokens.
>
> Cada seção diz a **regra** (uma frase, verificável), **onde mora hoje** (âncora em função ou
> arquivo — nunca só número de linha, que envelhece) e a **dívida declarada**. A régua é a D15 do
> `CLAUDE.md`: dívida escrita é limite, dívida calada é fail-open. Quem **fecha** uma dívida apaga a
> linha aqui no mesmo commit; quem **abre** uma nova a escreve aqui, não no `TODO.md` — o `TODO.md`
> recebe o achado, esta rule recebe o limite.

## 1. System prompt — caráter e restrições

**Regra.** O agente descreve **o que produzir e onde**. Restrição que vale para toda fase mora em
`boot_prompt()` do `bin/sdd`, uma definição só, nunca copiada em N agentes (é a regra do enum do
`CLAUDE.md`: uma definição por programa). O que o agente **não pode fazer** é fronteira de
ferramenta ou de gate, não frase de prompt — frase é lembrete, gate é regra.

**Onde mora hoje.** Sete chapéus em `agents/*.md`, carregados por `--agent` em `run_phase()`;
`boot_prompt()` injeta fase, missão, `OUTPUT_LANG`, ordem de leitura e tarefa; `phase_extra()`
acrescenta restrição só para REVIEW e QA.

**Dívida declarada.** "O revisor não toca código" e "o publisher não mergeia" são frases; o
runner avisava (`REVIEW-EDITED-CODE`); desde `20260903-a-fronteira-do-chapeu` ele **para** (`hat-crossed`). A regra "nunca encerre o turno com trabalho em
background" vivia só no `sdd-reviewer.md` e custou duas sessões do publisher em 2026-09-02 —
fechada movendo-a para `boot_prompt()` (L3 da auditoria). Desde #234 o `turn_rule` diz também, a
toda fase, que o processo posto em background (`nohup … &`) entra na família do pipeline — o `sdd
run` não termina e o checkout segue preso até ele morrer — e que a sessão nunca para nem reinicia
processo que não começou (o app sob teste é do humano): medido no `sales_quote`, uma sessão de QA
matou o backend do humano e o relançou com `nohup`, e o `sdd run` ficou vivo até o servidor morrer.

## 2. Ferramentas — capacidades, não todas as possíveis

**Regra.** Cada chapéu declara o mínimo que o **gate da sua fase** exige, e o runner passa
`--allowedTools` **por fase**. Revisor lê e escreve três artefatos; publisher empurra e abre PR;
só o executor edita código. Ferramenta a mais é superfície de erro que nenhum gate mede.

**Onde mora hoje.** `ALLOWED_TOOLS` e `PERMISSION_MODE` são chaves de config
(`config/starter.conf`), teto `acceptEdits`, `bypassPermissions` recusado por `load_config`;
`phase_hat()` é a única tabela passo → chapéu, `hat_disallowed()`/`hat_mcp()` montam as flags em
`run_phase()`, `HAT_DENY_BASE` é o que nenhuma fase usou, e `sdd census <missão>` mede o depois.

**Dívida declarada.** Fechada em `20260903-a-fronteira-do-chapeu`: cada `agents/*.md` declara
`disallowedTools:`, `writes:` e `mcp:`, o runner passa `--disallowedTools` e `--strict-mcp-config`
por fase, e a linha `init` do stream prova no ledger (`mcp_seen`, `tools_leaked`). Medido antes:
0 negações em 43 sessões, 9 servidores MCP e 104 ferramentas em toda fase; depois, o executor vê
14. ⚠️ Reaberta e fechada de novo em 2026-09-06: o Claude Code 2.1.263 passou a **ler** o
`disallowedTools:` do arquivo do agente, como nomes, e as três regras `Bash(…)` que moravam ali
tiraram o Bash inteiro de toda fase (3 sessões de TICKET, US$ 3,39). As regras vivem em
`permissionsDeny:` (chave do kit), os nomes em `disallowedTools:`, `hat_disallowed` junta as duas na
flag, `tests/check-hat.sh` R3/R4 recusam a mistura, o `sdd preflight` dispara o chapéu do executor e
lê `Bash` na `init`, e a linha `session` do ledger carrega `harness:` para o bump deixar de ser
invisível. O que fica: `--setting-sources user,project,local` continua carregando as skills do
humano — medido, é 2% do prefixo e três fases dependem delas (`codereview`, `ticket`, `qa-*`); a
rota é a linha 2 do ADR 0007, não uma flag.

## 3. Gestão de contexto — o que o agente sabe agora

**Regra.** A sessão lê o que o boot manda, e o boot manda **um orçamento**: as últimas N notas do
checkpoint, o último handoff, nunca as rodadas anteriores inteiras. Artefato que só cresce ganha
teto ou digest; sessão que relê a missão inteira paga a missão inteira de novo.

**Onde mora hoje.** Estado em disco (princípio 3 do `CLAUDE.md`); sessão nova por fase e por
incremento; `--fork-session` no retry. Desde `20260904-a-dieta-de-contexto` o `boot_prompt()`
**aplica o orçamento** em vez de apontar a missão inteira: nomeia `00-missao.md` e `01-plano.md`;
o `checkpoint.md` é só a tabela, e as notas moram em `checkpoint-notas.md` (append-only), das quais
o boot **inlina** as últimas `BOOT_NOTES_TAIL=10` (`boot_notes_tail`) e manda não abrir o arquivo;
**nomeia** o handoff mais recente (`mission_latest_handoff`, sobre a mesma `latest_matching` do gate
de REVIEW) e inlina só `## TL;DR` + a seção de boot (`handoff_boot_sections`); nomeia os templates
da fase (`phase_templates`). Desde `20260922-o-motivo-da-fase` o boot também diz **por que** a fase
foi aberta: a linha `Why this phase:` carrega o `GATE_WHY` que o `derive_phase` publicou (chamado,
nunca `$( )`), ou diz `forced from the CLI` quando o runner não derivou a fase — o executor da
`20260921-amep-backend-0-1-0` abriu sem linha `pending` e sem motivo, e fez commit no-op. O TL;DR tem teto de 20 linhas (`handoff_tldr_ok`), cobrado pelos gates
de EXEC, QA e REVIEW — as três fases cujo chapéu **escreve** o arquivo, senão o gate giraria a
linha. Quem mede: `sdd census` (por arquivo; `boot bill` no último handoff **e no pior ponto**),
`sdd boot <missão> <FASE>` (o prompt, sem sessão), `cache_read` na linha do ledger e a linha
`context bill` do `sdd preflight`. Spec:
`docs/superpowers/specs/2026-09-04-a-dieta-de-contexto-design.md`.

**Dívida declarada.** Medido sobre o **mesmo conteúdo** de `20260901-o-revisor-so-acha` nos dois
layouts: `boot bill` no pior ponto **214 222 → 102 016 B** (−52,4%), contra o teto de 105 000 B
fixado antes de qualquer corte existir. O que sobra, por escrito e não calado: (1) a seção
`## Boot da próxima fase` (8 829 B, 112 linhas) virou o terceiro maior termo do boot e **não tem
teto** — o alvo fechou sem ele, capá-la é missão futura; (2) o `CLAUDE.md` do alvo (~73% do prefixo
fixo por turno; 50 180 B aqui) não é cortado **por decisão** — o kit não corta o livro de regras de
ninguém, só o mede; (3) missão começada antes do split **não migra**: as duas formas convivem, e o
writer e o leitor da `- intervention:` leem os dois mundos; (4) o dólar real por missão fica para a
**janela 4** — o "depois" desta rule é o instrumento e os probes, não a conta. ⚠️ Medido nesta
missão e válido além dela: `Edit` sem `Read` prévio **passa** em sessão interativa e é **recusado**
em `claude -p` headless, que é o regime de toda fase — intuição colhida interativamente não
transfere para a fase (US$ 0,045 para descobrir).

## 4. Mecanismos de verificação — como checa o próprio trabalho

**Regra.** É o princípio 1: gate lê **artefato**, nunca rótulo — e **nota de revisão é rótulo**
que o próprio modelo escreve. O gate de REVIEW exige A em todo critério e tolera B só nos que
julgam prosa (`Documentation`, `Overall`), nomeados positivamente; achado de prosa vai para o
`TODO_FILE`, não compra rodada.

**Onde mora hoje.** O componente mais forte do kit: `gate_<FASE>` por artefato (`TEST_CMD`, grep
no checkpoint, `git log`, `gh pr view`); Check por incremento; **dezesseis** sensores em
`tests/run-all.sh` (o décimo sexto é `check-coordination.sh`); catálogo de mutação com carimbo no
`sdd health` (a chave lê `bin/ tests/ templates/ config/ agents/` — `agents/` desde a ADR 0015 §1,
porque o runner lê cada chapéu dali); guarda de kit em quatro portas. Desde `20260917-o-numero-do-adr-nao-e-prosa` o
`gate_PLAN` também cobra o `adr:` sob `ADR_CHECK=block`, e o comentário do gate **nomeia o dono do
artefato** — `sdd-planner`, com o humano na sala —, que é a segunda metade da régua do princípio 1.
É por isso que a recusa mora no PLAN e não no EXEC: nenhum agente do kit decide trade-off
arquitetural, então cobrar a decisão de uma fase sem humano seria o gate insatisfazível. O
próprio kit roda sob `block` desde `20261004-lote-4-a-catraca-zera` (§5).
Desde `20260925-o-sensor-le-o-que-a-ancora-diz` o `TEST_CMD` deixa de ser certificado por grafia:
`config_read_key` é a única leitura de chave fora do `load_config` e diz por que o arquivo não
carrega ("does not parse" ou "does not evaluate", o mesmo rc 2);
`test_cmd_lists_only` é o predicado único do `--list` (health 2b e preflight); e o ramo vermelho
do `TEST_CMD` no preflight chama `_fail`, e só emite `warn` no lugar dele quando o runner **diz**
que falta o manifesto na raiz (`test_cmd_missing_manifest`). A âncora do `TODO.md` também virou
sensor (ADR 0011). Desde #232 a Âncora 3 do `gate_QA` lê a decisão **escrita** do bug `deferred`
(`bug_decision_recorded`: `## Decis…` fora de cerca e com data na seção, os plurais `## Decisions`/`## Decisões`/`## Decisoes` recusados): sem ela o
bug conta como `agent`, barra e é nomeado no motivo — o campo sozinho era rótulo.
Desde `20261004-lote-4-a-catraca-zera` o `tests/check-checkpoint.sh --red <checkpoint>` roda o Check
de cada linha `pending` a partir da raiz do repo e recusa o que já nasce verde, o mudo e o que
foge da forma `` `comando` → `esperado` ``. Ele **executa** texto escrito por modelo, então é
ferramenta do planner com o humano na sala, **nunca gate**: o runner não o chama, o `run-all.sh`
também não, e o `gate_PLAN` não poderia — ele é reavaliado a cada derivação, e o Check do I1
fica verde no instante em que o I1 fecha. Prova "não verde", não "vermelho pelo motivo certo".

**Dívida declarada.** A nota de revisão continua sendo rótulo; o que L1 fechou foi que rótulo
sem sensor comprava rodada — hoje `gate_REVIEW` tolera `REVIEW_PROSE_MIN_GRADE` só nas linhas
de `REVIEW_PROSE_CRITERIA` (prosa) e exige A em todo o resto, nome desconhecido incluído. As
Âncoras 1 e 2 do `gate_QA` satisfeitas por relatório de **outra** missão: fechada em
`20260928-os-achados-da-janela` (ADR 0013) — o relatório é o que a branch da missão adicionou
(`mission_qa_report`), com recuo para a resposta de antes quando o range é vazio. O relatório que
outra missão pôs na ponta da base só conta com o checkpoint desta missão movido pelo commit que o
adicionou (ADR 0015 §3) e deixado num blob que a própria missão escreveu (ADR 0016 §1, #225).
Resíduo: outra missão que reescreve o checkpoint byte a byte igual a uma versão da branch passa.

## 5. Memória — o que persiste entre sessões

**Regra.** O que persiste tem **rota e dono**: achado → `TODO.md` (catraca no `sdd health`);
pendência → seção com dono no handoff; achado `kit:` nascido em repo-alvo → triagem do
`sdd kaizen`; lição → sensor ou verbete do `CONTEXT.md`, nunca parágrafo novo no `CLAUDE.md`.
Memória sem rota é prosa que a próxima sessão paga para reler e não usa.

**Onde mora hoje.** Handoffs por missão, checkpoint, `TODO.md`, `KAIZEN_LOG.md`, `CONTEXT.md`,
`docs/adr/`, ledger de autonomia (`autonomy_log_path`), logs JSON por sessão em `.sdd/logs/`.
Desde `20261004-lote-4-a-catraca-zera` toda linha do ledger carrega `runner_sha`, o HEAD do kit no
lançamento do processo, ao lado do `kit_sha` lido do disco: numa missão cujos commits movem o
próprio kit, o segundo nomeia uma versão que o processo nunca rodou (22 de 35 `sdd run` do kit).
Na mesma missão a fase feita à mão ganhou rota (#153): a página completa do `sdd status`
(`status_unrecorded`) lista as fases de gate verde sem linha `session` nem `manual` desta missão no
ledger **desta máquina**, cada uma com o `sdd note-manual` que a grava — pergunta, não acusação, e
fora do `--no-gates`, que não sabe qual fase está feita. Desde #229 ela cala quando o ledger desta
máquina não tem **nenhuma linha `session`** da missão: é a forma de uma missão rodada em outro
computador, e a pergunta fazia o humano gravar como manual o que uma sessão rodou. Presença é
`session`, nunca "qualquer linha" — a `manual` que a dica manda gravar reabriria a pergunta para
toda outra fase. Limite declarado: missão feita inteira à mão nesta máquina também cala.
O `docs/adr/` deixou de ser memória **sem rota**: `sdd adr new` aloca o número com O_EXCL e escreve
os dois lados do vínculo; `sdd adr check` lê de volta, em dois escopos. A rota do ADR é o
`sdd-planner` com o humano, e o gate de PLAN é quem cobra. Desde `20261004-lote-4-a-catraca-zera`
o próprio kit roda sob `ADR_CHECK=block`: as 14 missões anteriores ao mecanismo declaram `adr:`
(três apontam para a ADR de que nasceram — 0003, 0004 e 0006, que ganharam `Spec:` —, onze dizem
`none`), e o `sdd adr check` responde rc 0 sem nenhuma missão indecisa.

**Dívida declarada.** As ADRs 0001, 0002, 0005 e 0007 do kit seguem sem `Spec:` — nenhuma
nasceu de uma pasta de missão, e escrever a origem seria inventá-la; o limite está no comentário do
`ADR_CHECK` em `.sdd/config.sh`. O namespace local `specs/*/adr/` do repo-alvo não é alcançado por nenhum dos
dois escopos do `sdd adr check` — unificar ou declarar é decisão daquele repo, e o limite está
escrito no cabeçalho do `tests/check-adr.sh` e no `config/schema.md`. Árvore que não tem o formato
`<SPEC_DIR>/<dir>/spec.md` também não é varrida (o `docs/superpowers/` deste repo).
318 pendências em 82 handoffs sem instrumento (`CONTEXT.md`, verbete das
pendências); três achados `kit:` esperando transporte humano; `CLAUDE.md` em 491 linhas (já esteve
em 861). A memória do harness (`~/.claude/projects/…/memory`) não é do kit e ficou um dia
atrasada em 2026-09-03 — o que o kit precisa lembrar mora no kit.

## 6. Sandboxes — ambiente seguro para executar

**Regra.** A fase roda com o env do harness **limpo**, numa branch de missão, e a guarda de kit é
fronteira nas fases de alvo. Credencial real entra só na fase cujo gate a exige (QA no navegador,
PR no `gh`).

**Onde mora hoje.** `ensure_mission_branch`, com hashes crus `--no-filters` (sem normalização
de EOL ou clean filters) e igualdade byte a byte de `00-missao.md` e
`01-plano.md` antes e depois do checkout (progresso fica fora); `kit_guard_arm`/`kit_guard_check` em quatro portas
(`KIT-TOUCHED`, e desde a fronteira do chapéu uma parada; desde #233 a amostra compara também a
árvore suja do kit por caminho e conteúdo — `kit_guard_tree`, com `GIT_OPTIONAL_LOCKS=0` —, e o
motivo diz o que mudou: commits e caminhos); `hat_guard_check` nos três sítios onde
o `review_scope_check` só avisava, lendo commits **e** árvore contra `writes:`; o catálogo de
mutação sabota **uma cópia** em `mktemp -d`. Desde #226 a suíte, o catálogo e todo
`tests/check-*.sh` carregam `tests/isolate-git.sh` — uma definição, lista de
`git rev-parse --local-env-vars` — antes do primeiro `git`; medido, sensor sozinho sob `GIT_DIR` de
uma isca: 12 de 16 a moviam em `89df2e5` (o `check-autonomy` trocava o `.git` inteiro por um gitfile
para um temporário apagado), 0 de 16 depois. O censo mora no `check-health.sh`
(`surface: every sensor sources …`). O env do harness é apagado por `run_phase()` antes do
`claude -p` (L5 da auditoria). Desde o PR #166 isso inclui o effort herdado: `CLAUDE_CODE_EFFORT_LEVEL`
e `CLAUDE_EFFORT` estão no `HARNESS_ENV_UNSET` e no `env -u` do `sdd close`, porque a primeira passa
por cima das settings; o nível da fase é do kit (`EFFORT_<FASE>` → `--effort`, vazio = settings) e
fica no `effort=` do `pipeline.log`, na linha da fase e na do `CLOSE`, já que o stream não o traz. Desde `20260918-a-excecao-do-chapeu-e-o-genero-diferido` a fronteira
é constante do chapéu **mais** variável do projeto: `HAT_WRITES_EXTRA` (`hat_writes_extra_each`, a
única definição da gramática; `hat_extra_path_ok`, a guarda no molde do `adr_dir_ok`;
`hat_writes_extra_for`, somado por chapéu em `hat_writes`), validada no `load_config` e **nunca**
no ponto de uso — lá o `die` cairia num subshell e devolveria a lista vazia, que é a grafia de
"este chapéu escreve em qualquer lugar".
Desde `20260928-os-achados-da-janela` (ADR 0013) o `writes:` do `sdd-docs` não declara mais
`.claude/rules/**`: o `claude -p` headless recusa `Edit`/`Write` ali, e na SQ-145/SQ-146 a sessão
contornou pelo Bash com o caminho dentro do `writes:`. O contorno agora para a linha como
`hat-crossed`, e a regra que muda vira linha `⛔` com texto proposto, que o `gate_DOCS` lê por linha
e o PR leva ao humano — o `gate_PR` confere que o corpo do PR nomeia cada documento `⛔` numa linha
com `⛔`, pelo mesmo leitor da tabela (`docs_checklist_rows`).
Desde `20261004-lote-4-a-catraca-zera` o `cmd_run` relê o `.sdd/config.sh` no topo de cada volta
(`config_reload`): antes de re-sourçar, toda chave de `health_default_keys` volta à **foto do
ambiente** que `config_env_snapshot` tirou no lançamento — `unset` quando o ambiente não dizia nada —,
então chave apagada do arquivo volta ao default e chave exportada (`ON_ESCALATION_CMD=… sdd run`)
sobrevive à volta 2. Config que não carrega para a linha antes de a volta abrir sessão, com o `die`
do `load_config`. Re-exec do `bin/sdd` entre voltas foi recusado: o runner não revisado da missão
julgaria a própria REVIEW. Limites no comentário do `config_reload`: o que o `cmd_run` derivou antes
do laço (branch da missão, `MISSION_DIR`) fica com o valor do lançamento; edição feita durante a
sessão chega ao gate da volta **seguinte**; `sdd retry`, `sdd close` e `sdd kaizen` leem uma vez só.

**Dívida declarada.** O `HAT_WRITES_EXTRA` **alarga** permissão e seu valor vira glob de shell no
`case` do `hat_path_allowed`, então toda frouxidão da guarda falha **aberta** — por isso ela é
literal-only, e por isso a passada de sabotagem é obrigatória antes do merge. Chapéu cujo `writes:`
é vazio (`sdd-executor`) já escreve em qualquer lugar: a entrada é aceita e **ignorada**, com aviso
do `sdd preflight` — estreitar viraria regressão, recusar viraria armadilha.
As fases rodam **no checkout do humano**, com `.env.idp`, Jira e push reais;
a guarda de kit **para a linha** desde `20260903-a-fronteira-do-chapeu` (`kind: kit-touched`), e o
chapéu que escreve fora de `writes:` também (`hat-crossed`) — as duas pela mesma porta,
`hat_crossed_escalation`, em quatro sítios. Desde `20260926-a-carona-antes-do-congelamento`
(issue #51, ADR 0012) a guarda do chapéu **atribui** o commit antes de culpar: toda sessão roda com
`GIT_REFLOG_ACTION=sdd:<passo>:<sid8>` (`session_git_label`, no `run_phase` e no `cmd_close`), e o
`hat_guard_check` lê a janela pelo reflog de `HEAD` — entrada com o rótulo exato é da sessão, sem ele
é alheia e para a linha como `foreign-commit`, com o commit nomeado e o remédio certo; sem reflog
que explique o movimento, o diff do intervalo de antes; a atribuição nunca alarga o diff líquido da
fase. Limites: um git que gravasse mensagem própria no lugar do rótulo trocaria o `kind`, nunca a
parada (nenhum comando medido no git 2.43 faz isso; o `rebase` grava `<rótulo> (pick): …`); sujeira **não commitada** de um escritor
concorrente continua atribuída ao chapéu; a guarda de kit não lê o rótulo. Sem container, e sem worktree
**no laço**: o `sdd run` roda no checkout do humano, e isolar a fase num `git worktree add` dentro do
`cmd_run` pede desenho próprio (Y2 do `CONTEXT.md`). A identidade do repo deixou de ser o obstáculo —
o ledger lê o `.git` comum desde `c514e36`, e worktree do mesmo repo é o mesmo repo. A exceção é a
**missão do próprio kit**, desde o lote 5 (#235, ADR 0016 §2): o `sdd` do PATH é o checkout
principal do kit, e o `kit_guard_check` de todo `sdd run` de alvo compara o `HEAD` e o
`status --porcelain` dele, então um `00-missao.md` não rastreado gravado ali durante o EXEC de um
alvo para aquela corrida com `KIT-TOUCHED`. Por isso o `/sdd-plan` (passo 2 de *Before anything
else*) escreve a missão do kit num worktree ligado, e a sessão **interativa** a executa lá — nunca
um `sdd run` a partir do checkout principal; dentro dele `health`, `preflight` e `install` rodam
por `./bin/sdd`. Medido: worktree sujo e com commit deixa o carimbo do principal em
`89df2e5|false`; o mesmo arquivo no principal, `|true`. É posse do checkout, não isolamento de
filesystem. ⚠️ Dentro de um worktree ligado, `git bisect run`, `git rebase --exec`, os hooks
`pre-commit`/`pre-push` e um alias `!` exportam `GIT_DIR` absoluto; a suíte, o catálogo e cada
sensor o limpam desde #226 (`tests/isolate-git.sh`).
⚠️ **Medido em 2026-09-03 18:45, vinte minutos depois de o L4 pousar:** uma segunda sessão
interativa do Claude Code, aberta em outro repo, rodou `sdd run --phase REVIEW --budget-override`
sobre a missão já mergeada do próprio kit — trocou a branch da árvore de trabalho **debaixo de um
`sdd health` em curso** (invalidando o carimbo), abriu uma sessão opus real (morta à mão aos 12
min) e commitou duas notas `intervention:` numa branch mergeada. A CLI é a porta do humano, e qualquer agente com shell entra por ela. A exclusão por
checkout acrescentada em 2026-09-18 agora recusa essa disputa com `CHECKOUT-BUSY`/75. A nota passou a dizer só o que o
runner sabe ("forçada pela CLI"), nunca "o humano".

**Posse desde 2026-09-18.** `coordination_enter` centraliza admissão antes de config/gates,
com `flock` por checkout físico; worktrees independentes não dividem lock. `health` protege a
árvore medida, `adr new --repo` admite o destino e usa sua config (parser único), e
`sdd-link-agents` entra pela mesma porta. `--spec` é canonicalizado fisicamente e deve ser
arquivo interno ao destino; `..` ou symlink para fora são recusados antes de config/reserva/escrita.
Aliases internos relativos e absolutos continuam aceitos; specs externos antes aceitos passam a
ser recusados, sem lock multi-raiz. O helper Python/Linux
`bin/sdd-coordination.py` é subreaper separado do PID público: morte do owner/worker, FDs
fechados, `setsid` e double-fork não liberam posse antes do reap completo. Auxiliar descendente
reentra por identidade de processo + ancestralidade + FD realmente travado; ambiente sozinho
não autoriza. Pipeline recursivo é recusado. `check-coordination.sh` mede concorrência,
ausência de efeitos, consultas, reentrada e recuperação com barreiras e CLIs isoladas.
Sinais cooperativos alcançam a família ativa, inclusive foreground, outras sessões e filhos
criados por threads; pidfds fixam a identidade após conferir starttime/ancestralidade. Linux
5.3+ com syscalls pidfd permitidas e Python 3.9+ são exigidos antes de config/sessão; não há
fallback para PID numérico reutilizável. A varredura seleciona destinatários, nunca libera
posse: só `ECHILD` prova reap completo. Handlers que ignoram o sinal por escolha não são garantidos.
O helper sobe com `python3 -I -S` (`COORDINATION_PYTHON`, uma definição para os quatro sítios):
o `PYTHONPATH` de quem chama não troca os módulos do processo que decide a posse. As mesmas flags
servem à sonda do remédio do `CHECKOUT-UNAVAILABLE`: `/usr/bin/python3` (ou `SDD_SYSTEM_PYTHON`) só
é oferecido depois de passar no próprio `capable` do helper, nunca por ser executável. O supervisor
acorda pelo pidfd do worker, não pelo tique de 10 ms. Desde #234 ele diz por quem espera: quando o
worker sai sozinho e sobra descendente vivo, imprime uma vez, 1 s depois, o pid e a cmdline de cada
um (`name_stragglers`, só leitura de `/proc`; quem libera o lock continua sendo o `ECHILD`). O hook
não nomeia: o prazo de 5 + 1 s já limita a família dele. O custo que sobra, ~30 ms do 2º Python do
worker em toda chamada coordenada, é limite declarado: não chega ao humano, e o conserto (provar o worker
por FD herdado, com ADR) mora na gaveta, F1 P1.

**Limite da posse.** Coordena entradas do kit, não edição externa nem daemon preexistente.
Matar o supervisor, adulterar arquivos/namespace do lock ou intervenção privilegiada derrota
essa coordenação. Descendente de longa duração conserva o lock até terminar — desde #234 nomeado no
stderr do supervisor, não mais em silêncio —; timeout não libera outro escritor. Não é isolamento de filesystem nem mudança do estado derivado da missão.

## 7. Hooks — pontos de intervenção humana

**Regra.** Toda decisão de **abrir mais uma volta ou gastar mais** tem uma porta humana com
artefato: teto por missão, aviso no bloqueio, e a linha `- intervention:` escrita **pelo runner**
quando é ele quem recebe o comando pela CLI (`--phase`, `retry`, `--budget-override`), e **só onde
a porta compra a sessão** (#227, decisão 11a do lote 5) — dizendo o que ele sabe, nunca quem estava
na CLI. O humano que precisa vigiar um `tail -F` para saber que a
linha parou não tem hook — tem vigília.

**Admissão não é escalada.** `CHECKOUT-BUSY`/75 não abre sessão, não altera checkpoint,
não escreve ledger de missão e não chama hook; `status --no-gates` expõe o proprietário.
O prazo do hook vale para toda a árvore: um subreaper local cancela também filhos em outra
sessão, com os mesmos 5 s + 1 s; o lock externo só sai depois do reap. Background do hook
não pode sobreviver indefinidamente. A semântica geral de órfãos da execução é preservada.

**Onde mora hoje.** `aprovacao:` + `sdd approve` (gate PLAN); rc 2 sem sessão, que é passo humano
desenhado e não escalada (sem linha de ledger, sem hook): o PLAN e, desde
`20261004-lote-4-a-catraca-zera`, o carimbo de mutação quando o PR está aberto e só ele falta
(`GATE_PR_STAMP_WHY`, ADR 0015 §1) — o `sdd run` nomeia a ordem e o `./bin/sdd health`, e desde
#228 o carimbo **impossível** (`GATE_PR_STAMP_IMPOSSIBLE`) troca a ordem por "conserte o que o
motivo nomeia primeiro"; rc 3 em
`handoff_blocked_escalation`, `app_down_escalation`, `increment-blocked`, `dirty-tree`,
`no-progress`, `budget-exhausted`, e desde `20260922-o-motivo-da-fase` `no_work_escalation`
(`kind: "no-work"`) — a única que para a linha **antes** da sessão, quando a célula do checkpoint
é ilegível ou o mesmo passo volta com o mesmo motivo; o journal ganhou a linha
`PHASE <X> reason="…"` por fase derivada, que é o que o humano no `tail -F` lê; `QA_MAX_ITER`/`REVIEW_MAX_ITER`; `--max-budget-usd` por
fase (`phase_budget_usd`); merge do PR é humano; `sdd close`. Desde a auditoria: teto por missão
(`BUDGET_MISSION_USD`, com zero numérico desabilitando e todo valor positivo sendo aplicado),
`ON_ESCALATION_CMD` em todo rc 3 depois da tentativa de escrita durável, limitado a cinco segundos
mais um de encerramento forçado, e a linha `- intervention:` escrita pelo
runner (L2, L6 e L4) — desde o lote 5 logo acima do `before=` da porta que abre a sessão: a do
`--phase` consumida na 1ª volta (`cli_lap`), a do `retry` abaixo do teto, e a do `--budget-override`
publicada pelo `mission_budget_blown` (`BUDGET_OVERRIDE_NOTE`) e escrita por
`budget_override_note_write`; volta parada sem sessão não grava nota. Desde `20261004-lote-4-a-catraca-zera` (#153) a fase feita **à mão** também
tem porta: `sdd note-manual <missão> <FASE>` escreve a `- intervention:` pelo mesmo escritor e a
linha `event:"manual"` do ledger, que não gradua nada — antes dela, o PR publicado à mão de
`20260916-destino-frete-cif` não deixou linha nenhuma, e 0 de 4 missões escreveram a nota. Desde
#230 o `ok` dele diz o que o escritor **fez**, lido do `CHECKPOINT_NOTE` que o
`checkpoint_note_intervention` publica (`committed`, `uncommitted`, `failed`, `none`), e a linha
`manual` é gravada em todo caso — antes, o `ok` afirmava a nota mesmo quando ela não existia.

**Dívida declarada.** "Pare depois desta fase" existe: `--phase X --max-phases 1` — a linha
anterior desta seção dizia que não existia, e estava errada (foi o comando do incidente das 18:45).
O que falta é o inverso: `--phase X` sem `--max-phases` segue em frente, e a DOCS emendou sozinha
depois da r4 em 2026-09-02.
