---
missao: 20261117-o-worker-orquestrador
fase: DOCS
status: done
sessao: 05ca3d1f-fab0-4e59-a1e3-33869e290ff2
data: 2026-11-18 10:17
gate: docs em `d15222e`; `tests/run-all.sh` no `1eafd8c` → rc 0, 2140 ok, nenhuma linha FAIL, anchors 854 de 854; `tests/check-worker.sh` → rc 0, 45 ok, 0 FAIL (`docs:` incluída); `tests/check-templates.sh` → rc 0, 117 ok; `tests/check-adr.sh` → rc 0, 81 ok; `tests/check-lang.sh` → `0 of 71 surface path(s) still in the allowlist, 0 new`; `tests/check-todo.sh --check TODO.md` → `83 finding(s), all within 8 lines, carrying anchor + date, every anchor on target`; `--anchors TODO.md` → `83 measured, 0 off target`; `bin/sdd-worker level docs/superpowers/campaigns/20261117-zerar-as-issues` → `level assisted — illegible`, 83 itens
---

# Handoff — DOCS — O worker orquestrador

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

O EXEC já tinha escrito a seção `## The worker` do `docs/pipeline.md`, o README, o schema, o glossário, a ADR 0022, a gaveta e o caderno (§4), e os R mantiveram a prosa a cada conserto.
Esta fase fechou as derivas LOW que as r1 a r4 e a QA mandaram para cá, todas em `d15222e`: em qual checkout o worker lê o pager e o teto (pipeline, ADR, schema, CONTEXT, os dois `delegation.md`), "before any `.sdd/config.sh` is read", o digest da ADR §3, o `sdd-worker` no arranjo de symlink do README, os dezessete sensores do `CLAUDE.md`, e dois limites declarados novos.
Entrada nova no `KAIZEN_LOG.md` (o K8 não está `skipped`), e uma `RECURRED` no item do `READ_EXTRA` do `TODO.md`.
Ficam duas linhas `⛔`, com texto proposto: `commands/sdd-worker.md:143` (fora do `writes:`) e a rule `.claude/rules/anatomia-do-agente.md` (seções 1, 4, 5, 6 e 7).

## Estado do repo

- **Branch:** `feat/o-worker-orquestrador`, no worktree `/home/joruge/repos/sdd_agents-worker`, merge-base
  `7ea43e3` com a `origin/main`; sem push nesta fase.
- **Último commit:** a nota da suíte, sobre `1eafd8c` (este `45-docs.md`), sobre `d15222e` (os docs).
- **Working tree:** limpo depois do commit.
- **Suíte:** `tests/run-all.sh` no `1eafd8c` → verde: rc 0, 2140 ok, nenhuma linha `FAIL` (as mesmas 12
  ocorrências de `FAIL` dentro de linhas ok da r4), `anchors: all 854 mutants still apply`, 10:19 → 10:33.
  Antes do commit rodaram os sensores que leem o que a fase tocou (`check-worker`, `check-templates`,
  `check-adr`, `check-lang`, `check-todo` e `--anchors`), todos verdes.
- **E2E:** não se aplica (o kit não declara `E2E_CMD` nem `APP_URL`).

## O que foi feito

- `d15222e` — `docs/pipeline.md`: só o `HANDOFF_DIR` é lido na raiz, o `ON_ESCALATION_CMD` e o
  `BUDGET_MISSION_USD` em todo checkout (achado 1 da r4); a célula rc do `budget` cita o teto zero; "before
  any `.sdd/config.sh` is read" (r3); dois limites declarados novos: o conjunto largo executa o config de
  todo worktree (achado 3 da r4) e o worker só falha fechado num alvo cujo config fixa a chave (pendências
  da r1 a r4 sobre o lado do runner).
- `d15222e` — ADR 0022: §3 diz que o digest cobre as seis chaves e o teto de cada lote (pendência 2 da r1,
  deriva 3 da QA); §4 diz em qual checkout o pager vazio rebaixa (achado 4 da r4); Consequences ganha os
  mesmos dois limites. A ADR nasce nesta missão e não está na `main`: nenhuma decisão aceita foi reescrita.
- `d15222e` — `config/schema.md` e `CONTEXT.md`: a mesma precisão nas linhas do `BUDGET_MISSION_USD` e do
  nível de autonomia.
- `d15222e` — `templates/delegation.md` e a delegação do kit: a dica do `budget_mission_usd:` diz todo
  checkout e que zero para; a linha órfã do parágrafo do teto saiu, e as alternativas viraram dois
  caminhos (r3); o passo 1 da delegação do kit diz todo checkout do repo, não só os de missão (achado 2 da
  r4), e aponta a pendência 2 da r4 para a escolha da rota.
- `d15222e` — `README.md`: o `sdd-worker` fora do `PATH` no arranjo de symlink (deriva 1 da QA) e o índice
  de docs com `commands/` e os dois templates novos.
- `d15222e` — `CLAUDE.md`: "Os dezessete de hoje", com o `check-worker.sh`, e "Dezesseis dos dezessete
  rodam no `TEST_CMD`" (pendência 3 da r1; `ls tests/check-*.sh` → 17).
- `d15222e` — `KAIZEN_LOG.md`: a entrada da missão (K8), com o antes e o depois medidos e a corrida.
- `d15222e` — `TODO.md`: `RECURRED 1: sdd_agents/20261117-o-worker-orquestrador (2026-11-18)` no item do
  `READ_EXTRA` que não cobre o `codereview` (6 `Read` negados nas `references/` dele nas r2 a r4).

## Drift checklist

| Área tocada pelo diff | Documento correspondente | Status | Evidência |
|---|---|---|---|
| `bin/sdd-worker` (os seis verbos, a escada, a tabela de atos, os contratos) | `docs/pipeline.md` § "The worker" | ✅ | seção escrita em `30bc8cd` e mantida pelos F e R (`42d1a56`, `8add018`, `328087f`, `6bc1755`, `7747f6b`, `756fed3`, `7fde4ed`); nesta fase `d15222e`: o diretório da campanha (achado 1 da r4), a célula rc do `budget`, "before any `.sdd/config.sh` is read" e dois limites declarados |
| `bin/sdd-worker` (`effective_level`, `cmd_budget`, `config_key`) | `config/schema.md` | ✅ | linhas `ON_ESCALATION_CMD` e `BUDGET_MISSION_USD` em `30bc8cd`, `328087f`, `7747f6b`, `756fed3`, `7fde4ed`; nesta fase `d15222e` ("before any `.sdd/config.sh` is read") |
| `bin/sdd-worker` e `commands/sdd-worker.md` (o programa novo e o comando) | `README.md` | ✅ | linha de uso e parágrafo em `30bc8cd`; nesta fase `d15222e`: o `sdd-worker` no arranjo de symlink (deriva 1 da QA) e o índice de docs com `commands/` e os templates novos |
| `bin/sdd-worker` (campanha, lote, delegação, nível, worker da campanha) | `CONTEXT.md` | ✅ | cinco verbetes em `30bc8cd`, o digest em `42d1a56`; nesta fase `d15222e`: o pager vazio "no `.sdd/config.sh` de algum checkout do repo" |
| `docs/adr/0022-the-worker-is-a-session-orchestrator.md` | `docs/adr/0022-the-worker-is-a-session-orchestrator.md` | ✅ | corpo em `d7373e0`; nesta fase `d15222e`: §3 (digest), §4 (qual checkout) e dois limites em Consequences |
| `commands/sdd-worker.md` | `commands/sdd-worker.md` | ✅ | § "`review`", linha 143: o "no such key" sem antecedente e a linha de 190 colunas (r2 e r3); `commands/` está fora do `writes:` do `sdd-docs`; o texto proposto abaixo foi aplicado pela sessão interativa em `48b6bc3` |
| `commands/sdd-plan.md` | `commands/sdd-plan.md` | ✅ | a exceção do worker (ADR 0022 §7) escrita em `30bc8cd`; a âncora `commands/sdd-plan.md:174` do `TODO.md` acompanhou no mesmo commit |
| `templates/delegation.md` | `templates/delegation.md` | ✅ | `bdfa30e` e os R; nesta fase `d15222e`: a dica do `budget_mission_usd:`, "antes de ler qualquer `.sdd/config.sh`" e o parágrafo da linha órfã reescrito (r3) |
| `templates/campaign.md` e `templates/missao.md` | `templates/campaign.md` | ✅ | `bdfa30e` e `42d1a56`; conferidos contra o `lots_table` e o `fm_value`, sem deriva; `check-templates.sh` → 117 ok, as três `worker templates:` dentro |
| `tests/check-worker.sh` e a fiação da suíte (`run-all.sh`, `check-pipefail.sh`, `check-checkpoint.sh`, `check-health.sh`, `check-lang.sh`, `check-mutation.sh`, `check-templates.sh`) | `CLAUDE.md` | ✅ | `d15222e`: § "TDD aqui dentro" com dezessete sensores e "Dezesseis dos dezessete rodam no `TEST_CMD`" (pendência 3 da r1) |
| `tests/check-worker.sh`, `bin/sdd-worker` e `commands/sdd-worker.md` (componentes do agente) | `.claude/rules/anatomia-do-agente.md` | ✅ | seções 1, 4 ("dezesseis sensores", r1), 5, 6 e 7 (pendência 5 do `00-missao.md`); `.claude/` é recusado à sessão headless e saiu do `writes:` (ADR 0013); o texto proposto abaixo foi aplicado pela sessão interativa em `48b6bc3`, com uma frase do § 4 corrigida para dizer o que o `pr-ready` faz |
| `tests/fixtures/codex-review-state.txt` | — | n/a | fixture copiada do PR 409 em `26adfe4`, com a proveniência (comando e data) no comentário do probe que a lê em `tests/check-worker.sh`; nenhum documento descreve fixtures de sensor |
| `docs/superpowers/campaigns/20261117-zerar-as-issues/` | `docs/superpowers/campaigns/20261117-zerar-as-issues/delegation.md` | ✅ | `3fe5d3e` e os R; nesta fase `d15222e`: o passo 1 diz todo checkout do repo (achado 2 da r4) e a dica do `budget_mission_usd:` (r3); o Check do I11 segue `1 83` |
| `docs/superpowers/specs/2026-09-23-a-gaveta-do-kit.md` | `docs/superpowers/specs/2026-09-23-a-gaveta-do-kit.md` | ✅ | F6 "em construção por decisão do dono" no índice e na seção, em `3fe5d3e` |
| `docs/superpowers/specs/2026-09-22-o-worker-roadmap-design.md` | `docs/superpowers/specs/2026-09-22-o-worker-roadmap-design.md` | ✅ | nota no topo (D1, D2 e D5 revisados, o tick de lado) em `30bc8cd` |
| `docs/superpowers/specs/2026-10-09-o-worker-caderno-de-campo.md` § 4 | `docs/superpowers/specs/2026-10-09-o-worker-caderno-de-campo.md` | ✅ | as quatro perguntas respondidas pela ADR 0022, em `3fe5d3e` |
| a corrida desta missão (segunda medida do `00-missao.md`) | caderno de campo § 3 | n/a | o § 3 manda escrever a linha da missão "depois do merge", e quatro das oito colunas só o humano preenche (PLAN, worker?, ambiente à mão, toques); os fatos medidos até a REVIEW r4 estão no `KAIZEN_LOG.md` (`d15222e`) para quem escrever a linha |
| `TODO.md` (três âncoras deslocadas pelo diff) | `TODO.md` | ✅ | `templates/missao.md:43` em `bdfa30e`, `tests/run-all.sh:294` em `f7f99ea`, `commands/sdd-plan.md:174` em `30bc8cd`; `--anchors` → `83 measured, 0 off target`; nesta fase `d15222e`: a `RECURRED` do item do `READ_EXTRA` |
| a missão inteira (K8: `kaizen_log:` vazio no frontmatter) | `KAIZEN_LOG.md` | ✅ | `d15222e`: entrada nova sob `## 2026-11-18`, que cita `20261117-o-worker-orquestrador` e traz o antes e o depois medidos |
| `docs/handoffs/20261117-o-worker-orquestrador/` | — | n/a | artefatos da própria missão (plano, handoffs, rodadas, checkpoint); nenhum documento vivo os descreve |

## Texto proposto
<!-- sdd:proposed -->

### `commands/sdd-worker.md`

Em `commands/sdd-worker.md`, seção "### `review`", troque a linha 143, que tem 190 colunas e cujo "such
key" passou a ler `gate:` como antecedente depois da frase do R2 (r2 e r3):

```md
`pr-ready` refuses a round whose rationale or `gate:` is still a fill-in of `templates/review.md`. The rounds the runner's REVIEW phase writes carry no such key, so `pr-ready` waits for this
```

pelas duas linhas:

```md
`pr-ready` refuses a round whose rationale or `gate:` is still a fill-in of `templates/review.md`.
The rounds the runner's REVIEW phase writes carry no `reviewed_head:`, so `pr-ready` waits for this
```

A linha seguinte ("one. Fix what the round finds and review again, …") não muda. Depois de aplicar, rode
`bash tests/check-worker.sh` e confira as três linhas `command:` (o probe lê o arquivo).

### `.claude/rules/anatomia-do-agente.md`

Cinco trechos, um por seção; todos acrescentam, menos o da § 4, que troca.

**§ 1 (System prompt), "Onde mora hoje.", no fim do parágrafo:**

> Desde `20261117-o-worker-orquestrador` ([ADR 0022](../../docs/adr/0022-the-worker-is-a-session-orchestrator.md))
> há um prompt fora dos chapéus: `commands/sdd-worker.md`, o laço de uma sessão **interativa** que
> orquestra uma campanha. Ele segue a mesma régua: os juízos que decidem um ato (a delegação vale, o
> ato cabe no nível, o PR está pronto neste sha) não são frase do comando, são verbos do
> `bin/sdd-worker`, que respondem por artefato, com sensor (`tests/check-worker.sh`) e mutantes
> `mut_WORKER_*`.

**§ 4 (Mecanismos de verificação), "Onde mora hoje.", troque** "**dezesseis** sensores em
`tests/run-all.sh` (o décimo sexto é `check-coordination.sh`)" **por:**

> **dezessete** sensores em `tests/run-all.sh` (o décimo sétimo é `check-worker.sh`, desde
> `20261117-o-worker-orquestrador`)

**e acrescente, no fim do mesmo parágrafo:**

> Desde `20261117-o-worker-orquestrador` (ADR 0022 §5) o merge delegado também é gate por artefato,
> fora do runner: `sdd-worker pr-ready` responde `ready <sha>` só com os cinco itens verdadeiros no
> mesmo sha (a rodada mais nova da missão com A em todo critério e `reviewed_head:` nesse head, o
> recibo `codex-review-state:v1` do Codex `completed` nesse sha e sem achado aberto, nenhum thread
> aberto, `MERGEABLE`, o `HEAD` local), e nomeia o primeiro que falha. A tabela de notas dele é mais
> estrita que a do `gate_REVIEW` de propósito: nenhuma tolerância de prosa.

**§ 5 (Memória), "Onde mora hoje.", no fim do parágrafo:**

> Desde `20261117-o-worker-orquestrador` (ADR 0022) a delegação de uma campanha tem rota e dono:
> deixou de ser palavra dita numa sessão (que valia "nesta sessão" e, na 5a do `dotp-remake`, foi
> marcada "usada e esgotada" à mão numa memória do agente) e é o `delegation.md` versionado no
> repo-alvo, assinado pelo dono e relido antes de todo ato. O que a sessão orquestradora fez mora no
> `journal.md` da campanha (uma linha por evento, append-only, hora de `date`), e a sessão nova
> retoma por `sdd-worker level` e `next`, sem memória.

**§ 6 (Sandboxes), "Dívida declarada.", logo depois de** "dentro dele `health`, `preflight` e
`install` rodam por `./bin/sdd`.":

> Desde a ADR 0022 §7, sob o worker da campanha, a missão do kit roda também por `sdd run` **no
> worktree ligado** dela, pelo `sdd` do PATH (o checkout principal, que a missão não edita); a
> partir do checkout principal continua proibido. A primeira corrida medida,
> `20261117-o-worker-orquestrador`, fez 24 sessões até a REVIEW r4 sem nenhuma `kit-touched`,
> `hat-crossed`, `foreign-commit` nem `session-died`.

**§ 7 (Hooks), "Onde mora hoje.", no fim do parágrafo:**

> Desde `20261117-o-worker-orquestrador` (ADR 0022) a campanha tem a sua porta humana com artefato:
> a assinatura da delegação (`sdd-worker delegate` mostra as seis chaves e o teto de cada lote,
> pergunta, só `y` assina, e sai 66 sem escrever nada quando não lê resposta, o contrato do
> `sdd approve`). A delegação tem fim (`expires:`), dois tetos em dólar e cinco níveis cumulativos
> (`assisted` < `pr` < `plan` < `merge` < `full`); toda falha dela vale `assisted`, e acima de
> `assisted` também vale o `ON_ESCALATION_CMD` vazio no `.sdd/config.sh` de qualquer checkout do
> repo. As paradas do worker (sem recibo do Codex 60 min depois do pedido, nota abaixo de A depois de
> 3 rodadas, conflito no merge fora do `TODO.md` e da catraca, e os dois tetos) chamam o mesmo pager.

**§ 7, "Dívida declarada.", no fim do parágrafo:**

> Da delegação: a assinatura prova uma resposta no stdin, não uma pessoa (o limite do
> `sdd approve`); o gasto da sessão orquestradora e dos subagentes fica fora dos dois tetos; sob
> `full` o `sdd approve` grava `humano-…`, e a trilha é o diário da campanha; e num alvo cujo
> `.sdd/config.sh` fixa o `BUDGET_MISSION_USD` acima do teto assinado, ou deixa o
> `ON_ESCALATION_CMD` vazio, o worker só falha fechado, porque fazer a delegação valer ali pede
> mexer na precedência de config do `bin/sdd`.

## Achados do `TODO_FILE` conferidos nesta missão

- **Nenhum item novo nesta missão.** O diff do `TODO.md` contra o merge-base `7ea43e3` só tinha três âncoras
  deslocadas (`templates/missao.md:41` → `:43`, `tests/run-all.sh:292` → `:294`, `commands/sdd-plan.md:162`
  → `:174`), cada uma no commit que a moveu; `--anchors` → `83 measured, 0 off target`. As r1 a r4 e a QA
  não registraram achado no backlog: as derivas de prosa vieram para esta fase, e as decisões, para as
  pendências.
- **`RECURRED` acrescentada** (`d15222e`) ao item "O `sdd run` paga a REVIEW sem avisar que o `READ_EXTRA`
  não cobre o `codereview`" (`TODO.md:103`, `sk_entry`): o `.sdd/config.sh` do kit não tem `READ_EXTRA`, e o
  `pipeline.log` desta missão grava 6 `Read` negados nas `references/` do `codereview` (1 na r2, 3 na r3, 2
  na r4). É a primeira volta do item, de outro projeto que o do descoberto-por; o `--check` aceita a linha
  (`83 finding(s), … every anchor on target`), e a catraca (`todo-findings 83`) não se move.
- **Forma do arquivo:** `tests/check-todo.sh --check TODO.md` → `83 finding(s), all within 8 lines, carrying
  anchor + date, every anchor on target`, antes e depois do commit desta fase. Nenhum item desta missão foi
  refutado nem decidido, então nada foi para `<!-- sdd:decided -->`.
- **Não registrado, de propósito:** os 8 `Write` negados em `/tmp` (rascunho de sabotagem e de probe, EXEC,
  QA e REVIEW) custaram um contorno pelo `Bash` cada, sem fail-open e sem consumidor fora da suíte; pela
  régua D15 do `CLAUDE.md` fica como fato no `KAIZEN_LOG.md`, não como achado.

## Boot da próxima fase

A PR lê, nesta ordem: o TL;DR deste arquivo, a tabela acima e o `## Texto proposto`. O corpo do PR tem de
nomear cada documento `⛔` numa linha com `⛔` (o `gate_PR` confere): `commands/sdd-worker.md` e
`.claude/rules/anatomia-do-agente.md`, com o texto proposto para o humano aplicar. Levar também as
pendências abaixo, e a parada conhecida do `gate_PR` do kit (rc 2 por falta do carimbo de mutação lê-se
"pronto para revisão", pela regra do dono).

## Pendências / Decisions for a Human

- **Aplicar as duas linhas `⛔`** — a sessão headless não escreve em `.claude/`, e `commands/` está fora do
  `writes:` da DOCS — texto exato em `## Texto proposto`.
- **O conjunto largo do R3 e do R5** (pendência 2 do `40-review-r4.md`): o worker executa o `.sdd/config.sh`
  de todo checkout do repo, e um pager fora do commit pede uma linha em cada um dos 9 checkouts do kit
  (`git worktree list --porcelain` → 9). Agora é limite declarado na ADR 0022 e no `docs/pipeline.md`; a
  escolha entre ele, o conjunto estreito, um config local não rastreado no runner ou a rota do ambiente é
  do dono.
- **Assinar a delegação e configurar o pager do kit** (pendências 1 e 2 do `00-missao.md`), depois do
  merge; o passo 1 da delegação do kit diz agora o que o `level` lê.
- **A linha da missão no caderno de campo (§ 3)**, depois do merge, com as colunas que só o humano tem; os
  números da corrida estão na entrada do `KAIZEN_LOG.md`.
- **Sincronizar o espelho de issues** depois do último merge do dia (pendência 3 do `00-missao.md`): a
  `RECURRED` desta fase muda o corpo de um item já espelhado.

## Riscos e não-feitos

- A suíte inteira rodou no `1eafd8c`, verde (acima); o carimbo de mutação (`./bin/sdd health`) não roda
  nesta missão, pela regra do dono (pendência 6 do `00-missao.md`).
- O texto proposto para a rule e para o comando é prosa que nenhum gate julga: o `gate_DOCS` prova que
  ele nomeia o documento, não que está certo. Quem aplica o julga.
- O `20-handoff-exec.md` e as rodadas não foram reescritos: são registro, e a r4 conferiu a conta de
  mutantes dele (41).
- Não existe `CHANGELOG.md` neste repo; nada a atualizar ali.

## Achados fora de escopo

- Nenhum novo. A reincidência medida desta missão entrou como `RECURRED` no item já aberto (acima).
