# Aceite do plano — L2: o `/sdd-plan` e o planner

> Extrato que o dono leria antes do `sdd approve` (ato `approve` do `commands/sdd-worker.md`).
> Escrito pela sessão orquestradora em 2026-11-20, sobre `336640e`. A fonte é o `00-missao.md` e o
> `01-plano.md` ao lado; este arquivo não os substitui. O dono deu o sim ao `approve` por escrito
> nesta sessão ("O worker pode aprovar"), antes de o plano existir; vale como o `YES` do aceite
> depois da medida e deste extrato (passo 3 do `/sdd-plan`, "An approval given before the plan").
> O planner rodou em Fable (`claude-fable-5-2`, conferido no transcrito do subagente).

**Goal:** o relay do `/sdd-plan` e o `sdd-planner` passam a ter regra escrita, cada uma com uma
asserção, para os 14 itens do L2 e para o 15º, medido hoje: o chapéu declara `model: fable`.

**Architecture:** nada muda no runner (`bin/sdd`, `bin/sdd-worker`: nenhuma linha). Prosa nova em
`commands/sdd-plan.md`, `agents/sdd-planner.md` (+ espelho por `./bin/sdd install --force`),
`templates/plano.md` e `docs/plan-only.md`; o `--red` do `tests/check-checkpoint.sh` ganha
`--list` e `--only <ids>`, com última linha parcial distinta da medida inteira.

**Tech Stack:** markdown (comando, chapéu, template, doc) e bash (`tests/check-checkpoint.sh`,
`tests/check-hat.sh`, `tests/check-templates.sh`). `adr: none`.

## Restrições

- **Escopo:** os 14 itens do L2 e o 15º (o modelo do planner). Fora: os outros 77 itens, apagar os
  14 e descer a catraca (chore pós-merge), o espelho de issues, `bin/`, `commands/sdd-worker.md`,
  um token novo de resposta, `.claude/rules/` e `CLAUDE.md` (viram `⛔` na DOCS), `sdd health`.
- **Grill:** `10 (recommended) of 10`, todas delegadas por escrito ao worker e não vistas pelo dono
  na hora. `◆`: decisões 3, 4 e 5. Tocam regra do dono: 1, 5, 6 e 7 (pendência 3, corpo do PR).
- **Ordem com o L1b:** o `sdd run` só depois do merge do L1b e de `git merge origin/main` aqui, com
  `--check` e `--red` de novo (pendência 2). Em comum com ele: `tests/check-hat.sh` e `TODO.md`.
- **Teste de effort:** EXEC em `xhigh` (o L1 rodou em `medium`); DOCS em `medium`. O relay troca a
  linha para `EFFORT_EXEC="${EFFORT_EXEC:-medium}"` num commit próprio antes da corrida e lança com
  `EFFORT_EXEC=xhigh` (pendência 10). A métrica compara tempo e custo por sessão com o L1 e o worker.

## Tarefas

### Task I1 — antes de delegar (itens 11, 8, 7, 3)
**Files:** `commands/sdd-plan.md` (`## Before anything else`, `## Then`), `tests/check-hat.sh`
- [ ] Família `command_before_probes`, quatro asserções vermelhas.
- [ ] Prosa: a leitura do checkout (status, branch, missões, corrida viva) e as três saídas; a vigia
  que não para pelo `HEAD` que a corrida move; o commit do relay no meio do grill.
- **Check:** linha I1 do `checkpoint.md` → `1 1 1 1` (antes `0 0 0 0`)

### Task I2 — o grill dos dois lados (itens 2, 9, 6, 13)
**Files:** `commands/sdd-plan.md` (relay e aceite), `agents/sdd-planner.md` § 1 (+ espelho), `tests/check-hat.sh`
- [ ] Família `command_grill_probes`, quatro asserções vermelhas.
- [ ] Prosa: a sessão do relay que cai, a pergunta repetida pelo job em background, a marca só
  depois da resposta (contada a cada devolução), a resposta delegada por escrito (decisão 5).
- **Check:** linha I2 → `1 1 1 1 0` (o último é o `cmp` do espelho; antes `0 0 0 0 0`)

### Task I3 — o aceite (itens 4, 5, 10)
**Files:** `commands/sdd-plan.md` (`## When the artifacts exist`), `agents/sdd-planner.md` § 2, `templates/plano.md`, `tests/check-hat.sh`, `tests/check-templates.sh`
- [ ] Três asserções no `check-hat.sh` e uma no `check-templates.sh`, vermelhas.
- [ ] Prosa: comando ao lado de cada fato e a amostra no aceite (decisão 3); o ramo `auto` do
  passo 4 (decisão 4); o `git status` inteiro.
- **Check:** linha I3 → `1 1 1 1 0` (antes `0 0 0 0 0`)

### Task I4 — o planner e o modelo (itens 1, 12, 15)
**Files:** `agents/sdd-planner.md` (frontmatter, §§ 2 e 4) e espelho, `commands/sdd-plan.md` (`## Then`), `templates/plano.md`, `docs/plan-only.md`, sensores
- [ ] Quatro asserções no `check-hat.sh` e uma no `check-templates.sh`, vermelhas.
- [ ] Prosa: o sensor que a mitigação nomeia é rodado; o passo do `20-handoff-exec.md` em plano
  executado fora do `sdd run` e a seção da volta no `plan-only.md`; `model: fable` no chapéu e a
  frase de passar o `plan_model:` no `/sdd-plan`.
- **Check:** linha I4 → `1 1 1 1 1 0` (antes `0 0 0 0 0 0`)

### Task I5 — o `--red` (item 14)
**Files:** `tests/check-checkpoint.sh` (`case`, `red_one`, cabeçalho, `selftest`), `commands/sdd-plan.md`, `tests/check-hat.sh`
- [ ] Probes no `selftest` vermelhos; passada de sabotagem obrigatória (sensor fora do catálogo).
- [ ] `--red --list` (lista sem rodar) e `--red --only <ids>` (última linha parcial distinta); o
  aceite roda `pgrep -af '[b]in/sdd run'` antes do `--red`.
- **Check:** linha I5 → `1 1` (antes `0 0`)

### Task I6 — fecho
**Files:** `TODO.md`, `20-handoff-exec.md`
- [ ] `RESOLVED by <hash>` nos 14 itens, cada um com o hash do incremento que o fechou.
- **Check:** linha I6 → `14` (antes `0`)

## PLAN-AUTO

Os seis critérios ✅ (a: grill fechado; b: kaizen K1–K8 ✅, DDD `n/a`; c: sessão nova somente
leitura, 0 fatos errados em ~25 comandos, lacunas corrigidas; d: 6 Checks vermelhos; e:
`JIRA_ENABLED=false`; f: `adr: none`, `sdd adr check` rc 0). `aprovacao:` vazio, por regra.

## A medida de novo, pelo relay

- `./bin/sdd why 20261120-l2-o-sdd-plan-e-o-planner PLAN` → pede o `sdd approve`.
- `tests/check-checkpoint.sh --check …/checkpoint.md` → `ok    checkpoint.md: 6 row(s), 5 under the anchor rule, none blind`.
- `tests/check-checkpoint.sh --red …/checkpoint.md` → `ok    checkpoint.md: 6 pending Check(s), every one red at HEAD`, rc 0, cada Red igual ao "Antes" do plano (`0 0 0 0`, `0 0 0 0 0`, `0 0 0 0 0`, `0 0 0 0 0 0`, `0 0`, `0`).
- Leitor D22 → `10 (recommended) of 10`.
- Corrida viva na máquina durante o `--red`: o `sdd run` do L1b, em outro worktree; o `--red` do
  L2 roda só `check-hat.sh`, `check-templates.sh` e o selftest do `check-checkpoint.sh`.
