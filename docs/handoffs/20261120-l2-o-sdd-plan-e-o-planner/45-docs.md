---
missao: 20261120-l2-o-sdd-plan-e-o-planner
fase: DOCS
status: done
sessao: 11ad6bdb
data: 2026-11-20 23:09
gate: "docs em `0da9417` (pipeline.md e plan-only.md), `07f581e` (KAIZEN_LOG.md e o RESOLVED by do item do plan-only.md) e `22d8caf` (a F6 da gaveta); `tests/check-todo.sh --check TODO.md` → `105 finding(s), all within 8 lines, carrying anchor + date, every anchor on target`; `bash tests/check-hat.sh` → rc 0, 140 linhas ok, 0 FAIL; `tests/check-lang.sh` → `0 of 72 surface path(s) still in the allowlist, 0 new`"
---

# Documentação — L2: o `/sdd-plan` e o planner

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

Quase toda a missão é documentação (o comando `/sdd-plan`, o chapéu do planner, o `templates/plano.md`
e o `docs/plan-only.md`), escrita pelo EXEC no commit de cada incremento. Esta fase acertou o que
ficou para trás: o `docs/pipeline.md` passa a descrever o `--red --list`/`--only` e o `model: fable`
do planner, e o `docs/plan-only.md` segue a ordem do `gate_EXEC` (o achado de prosa da r1, agora com
`RESOLVED by 0da9417`). Escreveu a entrada do `KAIZEN_LOG.md`, devida porque o `kaizen_log:` está
vazio, com a tabela de custo e tempo do L2 ao lado do L1 e do worker: o EXEC em `xhigh` custou 1,66×
o tempo e 2,6× o dinheiro por sessão do L1. Atualizou a linha F6 da gaveta. Não há linha `⛔` e não
há item novo no `TODO.md`.

## Estado do repo

- **Branch:** `fix/l2-o-sdd-plan-e-o-planner`, no worktree `/home/joruge/repos/sdd_agents-l2`, com
  merge-base `079bc39` (PR #452) na `origin/main`; sem push nesta fase.
- **Último commit:** o deste `45-docs.md`, sobre `22d8caf`.
- **Working tree:** limpo depois do commit.
- **Suíte:** não rodou inteira nesta fase. O diff da fase é só prosa (`docs/`, `KAIZEN_LOG.md`,
  `TODO.md` e este handoff). Rodei os sensores que leem esses arquivos: `check-hat.sh` (lê o
  `plan-only.md`), `check-templates.sh`, `check-lang.sh` e `check-todo.sh`, todos rc 0. A última
  suíte verde é a da r2 (2231 `ok`, 0 `FAIL`).

## O que foi feito

- `0da9417`: no `docs/pipeline.md`, uma frase no parágrafo do PLAN-AUTO sobre os dois modos do
  `--red` (`--list` lista sem rodar; `--only` roda os nomeados e termina com uma linha parcial, nunca
  `every one red at HEAD`). Outra em "Models per phase" sobre o `model: fable` do chapéu e o modelo
  passado na chamada do subagente. No `docs/plan-only.md` (`## Going back to sdd run`), a lista
  "in this order" agora segue o `gate_EXEC` do `bin/sdd`: hash e status de cada linha, `blocked`,
  `pending`/`doing`, `TEST_CMD` e o handoff.
- `07f581e`: entrada `## 2026-11-20 — O L2: …` no topo do `KAIZEN_LOG.md`, com o antes (`079bc39`),
  o depois, a tabela das três corridas e as duas ressalvas do `00-missao.md`. Os números do L1 e do
  worker foram reconferidos no ledger e batem com os do relay. No mesmo commit, o `RESOLVED by 0da9417`
  no item do `plan-only.md` no `TODO.md`.
- `22d8caf`: linha F6 de `docs/superpowers/specs/2026-09-23-a-gaveta-do-kit.md`, com o L1b mergeado
  (#452) e o L2 rodado até a DOCS. É a regra do `CLAUDE.md`: frente que anda atualiza o índice no
  mesmo commit.

## Drift checklist

| Área tocada pelo diff | Documento correspondente | Status | Evidência |
|---|---|---|---|
| `commands/sdd-plan.md` (itens 2 a 5, 7 a 11, 13, 14 e a frase do modelo) | `commands/sdd-plan.md` | ✅ | o comando é o doc; frases em `256e9d4`, `9bea822`, `96d1bc5` e `972a482`, cada uma com asserção em `tests/check-hat.sh` |
| `agents/sdd-planner.md` (itens 1, 6, 12, 15) | `agents/sdd-planner.md` | ✅ | o chapéu é o doc; frases e `model: fable` em `9bea822` e `8a21366` |
| `agents/sdd-planner.md` (`model: fable`) | `docs/pipeline.md` | ✅ | "Models per phase" nomeia a chave e a chamada do subagente, em `0da9417` |
| `agents/sdd-planner.md` (`model: fable`) | `README.md` | n/a | a tabela dos chapéus já diz `Fable (interactive)` para o `sdd-planner`, e a chave nova só torna isso verdade |
| `.claude/agents/sdd-planner.md` | — | n/a | espelho gerado por `sdd install --force`; `cmp -s agents/sdd-planner.md .claude/agents/sdd-planner.md` → rc 0 (métrica 4) |
| `templates/plano.md` (item 1, o comando ao lado de cada contagem) | `templates/plano.md` | ✅ | o template é o doc; em `8a21366` (asserções em `tests/check-templates.sh`) |
| `docs/plan-only.md` (item 12, a volta ao `sdd run`) | `docs/plan-only.md` | ✅ | seção em `8a21366`; a ordem do `gate_EXEC` corrigida em `0da9417` |
| `tests/check-checkpoint.sh` (`--red --list` e `--only`, e o R1) | `docs/pipeline.md` | ✅ | parágrafo do PLAN-AUTO, em `0da9417` |
| `tests/check-checkpoint.sh` (`--red --list` e `--only`) | `CLAUDE.md` | n/a | o `CLAUDE.md` não descreve o `--red`; nenhum sensor novo, e a lista "Os dezessete" segue certa (`ls tests/check-*.sh`) |
| `tests/check-checkpoint.sh` (`--red --list` e `--only`) | `.claude/rules/anatomia-do-agente.md` | n/a | o § 4 diz que o `--red` roda cada Check `pending` e é ferramenta do planner, nunca gate; os modos novos não mudam nada disso, e a convenção não mudou |
| `tests/check-hat.sh` e `tests/check-templates.sh` (19 asserções) | `CLAUDE.md` | n/a | asserções em sensores que já existem; nenhum piso da regra dos "quatro lugares" muda |
| `tests/check-autonomy.sh` e `tests/check-dry-run.sh` (I7, limpam o `EFFORT_*` herdado) | — | n/a | conserto interno do fixture; os comentários no próprio código dizem o porquê, e nenhum doc descreve o ambiente desses sensores |
| `tests/health-baseline.txt` (`todo-findings` 98 → 105) | `CLAUDE.md` | n/a | a catraca sobe num diff com autor, o que o princípio 5 já prevê; desce no chore de pós-merge |
| `.sdd/config.sh` (`EFFORT_EXEC` do ambiente, `READ_EXTRA` do codereview) | `config/schema.md` | n/a | as duas chaves já estão documentadas; o diff só fixa os valores deste repo, com o porquê no comentário |
| `TODO.md` (15 `RESOLVED by`, 7 achados novos, âncoras) | `TODO.md` | ✅ | `df7b55e`, `748bea0` e `07f581e`; `--check` e `--anchors` → 105, 0 fora do alvo |
| a missão inteira (`kaizen_log:` vazio) | `KAIZEN_LOG.md` | ✅ | entrada `## 2026-11-20 — O L2: …` em `07f581e`, que cita `20261120-l2-o-sdd-plan-e-o-planner` |
| a frente F6 (o L2 rodou) | `docs/superpowers/specs/2026-09-23-a-gaveta-do-kit.md` | ✅ | linha F6 em `22d8caf` |
| nenhum termo de domínio novo | `CONTEXT.md` | n/a | a resposta delegada usa o token que já existe (`- answer: (recommended)`, decisão 5); nenhum termo entrou |
| `docs/handoffs/20261120-l2-o-sdd-plan-e-o-planner/*` | — | n/a | artefatos da própria missão |

## Achados do `TODO_FILE` conferidos nesta missão

- **Forma do arquivo:** `tests/check-todo.sh --check TODO.md` → `105 finding(s), all within 8 lines,
  carrying anchor + date, every anchor on target`. `--anchors` → `105 measured, 0 off target`.
- **Os 14 itens do lote** levam `RESOLVED by <hash>` com o hash do incremento (`df7b55e`), e os títulos
  estão byte a byte iguais. Seguem abertos até o chore de pós-merge.
- **Achados que a corrida registrou**, todos com título, âncora + símbolo, porquê, `Direção:`, fonte e
  data:
  - "O planner manda chamar duas skills que a sessão pode não listar" (`a30076d`, do planner, pendência 9);
  - "O harness recusa o `rm` cujo alvo é um `$(…)`", "O `sdd preflight` não olha os hooks…" e "O ato
    `run` do worker lança o `sdd run` sem rodar o `sdd preflight`" (`b91d13d`, do relay);
  - o `RECURRED 2` no item do `READ_EXTRA` que não cobre o codereview (`c83ad3d`): a volta entrou na
    linha `RECURRED` e não virou item novo, como manda a regra;
  - "Dois sensores leem o `EFFORT_*` do ambiente…" (`1c8de6a`, do executor no I1), com `RESOLVED by
    d48f7c9` (o I7);
  - os dois de prosa da r1 (`33c78db`). O do `docs/plan-only.md` foi consertado nesta fase
    (`RESOLVED by 0da9417`). O do `pgrep` do passo 1 do `/sdd-plan` continua aberto: `commands/` está
    fora do `writes:` desta fase, e o conserto (casar o pid com o repo) é de EXEC.
- Nenhum item foi refutado nem decidido, e nada foi para `<!-- sdd:decided -->`.

## Boot da próxima fase

A PR lê o TL;DR e a tabela acima. Não há linha `⛔`, então o corpo do PR não precisa nomear documento
`⛔`. O corpo lista as escolhas feitas sob delegação (pendência 3 do `00-missao.md`: os `◆` das decisões
3, 4 e 5, e as decisões 1, 5, 6 e 7). O merge é por **merge commit**, nunca squash, para os 15 hashes
chegarem à `main`. O rc 2 do `gate_PR` por falta do carimbo de mutação quer dizer "PR pronto para
revisão" (regra do dono: o carimbo só roda com a catraca zerada).

## Pendências / Decisions for a Human

- **O effort do EXEC dos lotes seguintes**, à luz da tabela do `KAIZEN_LOG.md`: houve um laço de
  revisão em cada corrida (uma volta de `R<n>`, duas rodadas), e o `xhigh` custou 1,66× o tempo e
  2,6× o dinheiro por sessão de EXEC.
- **O chore de pós-merge** (pendência 6): apagar os itens provados por `git merge-base --is-ancestor`,
  descer `todo-findings` e sincronizar o espelho de issues.
- **Medir o modelo do planner** no primeiro `/sdd-plan` depois do merge (pendência 4).

## Riscos e não-feitos

- A coluna do L2 na tabela conta as 11 sessões até a abertura da DOCS. A DOCS, a PR e o relógio total
  fecham no diário da campanha.
- A suíte inteira não rodou nesta fase (só prosa no diff); os sensores que leem os arquivos tocados
  rodaram.

## Achados fora de escopo

Nenhum novo nesta fase.
