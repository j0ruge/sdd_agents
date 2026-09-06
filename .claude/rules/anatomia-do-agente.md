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
fechada movendo-a para `boot_prompt()` (L3 da auditoria).

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
14. O que fica: `--setting-sources user,project,local` continua carregando as skills do humano —
medido, é 2% do prefixo e três fases dependem delas (`codereview`, `ticket`, `qa-*`); a rota é a
linha 2 do ADR 0007, não uma flag.

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
da fase (`phase_templates`). O TL;DR tem teto de 20 linhas (`handoff_tldr_ok`), cobrado pelos gates
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
no checkpoint, `git log`, `gh pr view`); Check por incremento; catorze sensores em
`tests/run-all.sh`; catálogo de mutação com carimbo no `sdd health`; guarda de kit em quatro
portas.

**Dívida declarada.** A nota de revisão continua sendo rótulo; o que L1 fechou foi que rótulo
sem sensor comprava rodada — hoje `gate_REVIEW` tolera `REVIEW_PROSE_MIN_GRADE` só nas linhas
de `REVIEW_PROSE_CRITERIA` (prosa) e exige A em todo o resto, nome desconhecido incluído. As
Âncoras 1 e 2 do `gate_QA` foram satisfeitas por relatório
de **outra** missão (achado `kit:` no `50-pr.md` daquela missão; aberto).

## 5. Memória — o que persiste entre sessões

**Regra.** O que persiste tem **rota e dono**: achado → `TODO.md` (catraca no `sdd health`);
pendência → seção com dono no handoff; achado `kit:` nascido em repo-alvo → triagem do
`sdd kaizen`; lição → sensor ou verbete do `CONTEXT.md`, nunca parágrafo novo no `CLAUDE.md`.
Memória sem rota é prosa que a próxima sessão paga para reler e não usa.

**Onde mora hoje.** Handoffs por missão, checkpoint, `TODO.md`, `KAIZEN_LOG.md`, `CONTEXT.md`,
`docs/adr/`, ledger de autonomia (`autonomy_log_path`), logs JSON por sessão em `.sdd/logs/`.

**Dívida declarada.** 318 pendências em 82 handoffs sem instrumento (`CONTEXT.md`, verbete das
pendências); três achados `kit:` esperando transporte humano; `CLAUDE.md` em 491 linhas (já esteve
em 861). A memória do harness (`~/.claude/projects/…/memory`) não é do kit e ficou um dia
atrasada em 2026-09-03 — o que o kit precisa lembrar mora no kit.

## 6. Sandboxes — ambiente seguro para executar

**Regra.** A fase roda com o env do harness **limpo**, numa branch de missão, e a guarda de kit é
fronteira nas fases de alvo. Credencial real entra só na fase cujo gate a exige (QA no navegador,
PR no `gh`).

**Onde mora hoje.** `ensure_mission_branch`; `kit_guard_arm`/`kit_guard_check` em quatro portas
(`KIT-TOUCHED`, e desde a fronteira do chapéu uma parada); `hat_guard_check` nos três sítios onde
o `review_scope_check` só avisava, lendo commits **e** árvore contra `writes:`; o catálogo de
mutação sabota **uma cópia** em `mktemp -d`; o env do harness é apagado por `run_phase()` antes do
`claude -p` (L5 da auditoria).

**Dívida declarada.** As fases rodam **no checkout do humano**, com `.env.idp`, Jira e push reais;
a guarda de kit **para a linha** desde `20260903-a-fronteira-do-chapeu` (`kind: kit-touched`), e o
chapéu que escreve fora de `writes:` também (`hat-crossed`) — as duas pela mesma porta,
`hat_crossed_escalation`, em quatro sítios. Sem worktree nem container: o ledger
carimba caminho e um worktree já confundiu a identidade do repo (comentários `WORKTREE` do
`bin/sdd`). Fechar pede desenho próprio, não um `git worktree add` no laço.
⚠️ **Medido em 2026-09-03 18:45, vinte minutos depois de o L4 pousar:** uma segunda sessão
interativa do Claude Code, aberta em outro repo, rodou `sdd run --phase REVIEW --budget-override`
sobre a missão já mergeada do próprio kit — trocou a branch da árvore de trabalho **debaixo de um
`sdd health` em curso** (invalidando o carimbo), abriu uma sessão opus real (morta à mão aos 12
min) e commitou duas notas `intervention:` numa branch mergeada. Nada no kit impede: a CLI é a
porta do humano, e qualquer agente com shell entra por ela. A nota passou a dizer só o que o
runner sabe ("forçada pela CLI"), nunca "o humano".

## 7. Hooks — pontos de intervenção humana

**Regra.** Toda decisão de **abrir mais uma volta ou gastar mais** tem uma porta humana com
artefato: teto por missão, aviso no bloqueio, e a linha `- intervention:` escrita **pelo runner**
quando é ele quem recebe o comando pela CLI (`--phase`, `retry`, `--budget-override`) — dizendo o
que ele sabe, nunca quem estava na CLI. O humano que precisa vigiar um `tail -F` para saber que a
linha parou não tem hook — tem vigília.

**Onde mora hoje.** `aprovacao:` + `sdd approve` (gate PLAN); rc 3 em
`handoff_blocked_escalation`, `app_down_escalation`, `increment-blocked`, `dirty-tree`,
`no-progress`, `budget-exhausted`; `QA_MAX_ITER`/`REVIEW_MAX_ITER`; `--max-budget-usd` por
fase (`phase_budget_usd`); merge do PR é humano; `sdd close`. Desde a auditoria: teto por missão
(`BUDGET_MISSION_USD`), `ON_ESCALATION_CMD` em todo rc 3, e a linha `- intervention:` escrita pelo
runner (L2, L6 e L4).

**Dívida declarada.** "Pare depois desta fase" existe: `--phase X --max-phases 1` — a linha
anterior desta seção dizia que não existia, e estava errada (foi o comando do incidente das 18:45).
O que falta é o inverso: `--phase X` sem `--max-phases` segue em frente, e a DOCS emendou sozinha
depois da r4 em 2026-09-02.
