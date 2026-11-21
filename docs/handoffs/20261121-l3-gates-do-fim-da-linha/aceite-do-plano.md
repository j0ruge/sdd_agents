# Aceite do plano — L3: gates do fim da linha

> Extrato que o dono leria antes do `sdd approve` (ato `approve` do `commands/sdd-worker.md`). Escrito pela
> sessão orquestradora em 2026-11-21, sobre `6198b68`. A fonte é o `00-missao.md` e o `01-plano.md` ao lado, e
> este arquivo não os substitui. A ordem do dono em vigor ("o worker assina, aprova e mergeia", sob a delegação
> `full` assinada em 2026-11-20 19:55) vale como o `YES` do aceite, depois da medida e deste extrato. O
> `allows approve` respondeu `allowed approve at full`. O planner rodou em Fable, com `model: fable` passado na
> chamada.

**Goal:** os gates do fim da linha leem o head que conferem, o `status: blocked` para a linha, e o PR leva o que
os handoffs dizem: os 13 itens do L3 fecham, cada um com asserção, e cada gate mudado com o seu mutante.

**Architecture:** nenhum gate novo e nenhuma fase nova.
- Cinco gates que já existem aprendem a ler o que afirmam: `gate_EXEC` e `run_check_cmd` (o rc 126/127),
  `gate_PR` (head, `verified_head:`, `blocked`, linhas `kit:`), `gate_REVIEW` (`blocked` e código posterior à
  rodada), o K8 do `gate_DOCS` (o `branch:` declarado) e `gate_QA` (o histórico do caso e2e vermelho).
- Há uma função nova, `mission_tip`.
- Ganham as regras que os gates não cobram: dois chapéus (`sdd-publisher`, `sdd-reviewer`) e três templates
  (`review.md`, `pr-body.md`, `handoff.md`).
- A ADR 0024 nova emenda a 0023.

**Tech Stack:** bash (`bin/sdd`, sensores em `tests/`), markdown (chapéus, templates, `docs/pipeline.md`). São 30
asserções e 16 mutantes novos. A catraca não se move nesta missão.

## Restrições

- **Escopo:** os 13 itens do L3.
- **Fora do escopo:**
  - os outros itens do `TODO.md`;
  - a prosa da DOCS depois da REVIEW (L6b);
  - a resolução de um merge da base (fica com o `pr-ready`);
  - `bin/sdd-worker` e `commands/`;
  - apagar os 13 itens e descer a catraca (chore pós-merge);
  - `.claude/rules/` e o `CLAUDE.md` (a anatomia § 4 vira `⛔` na DOCS);
  - `sdd health`;
  - a linha `EFFORT_EXEC`.
- **Grill:** `12 (recommended) of 12`, as **12 delegadas** por escrito ao worker e não vistas pelo dono na hora.
  - As decisões: 1 (o id e o branch), 2 ◆ (o `50-pr.md` entra no PR com o `verified_head:`), 3 ◆ (o gate reabre
    a REVIEW pelo que nenhum chapéu posterior escreve), 4 ◆ (o "Como verificar" vira regra de chapéu e
    template), 5 ◆ (o K8 mede o `branch:` declarado), 6 ◆ (a pendência respondida vai com a resposta), 7 (a ADR
    0024), 8 (`kaizen_log:` vazio), 9 (nove incrementos), 10 (a regra do `gate:` no template), 11 (os dois gates
    armam o `blocked`, com o contrato dele) e 12 (o bloco `N failed` do Playwright).
  - Tocam regra do dono, e vão ao corpo do PR: os cinco ◆ (2 a 6) e as decisões 3, 7, 11 e 12.
- **Ordem com o chore do L2 (#457):** o `sdd run` só depois do merge dele e de `git merge origin/main` aqui, com
  `--anchors`, `--check` e `--red` de novo (pendência 1).
- **Effort:** a EXEC em `medium` (o padrão do `.sdd/config.sh`), lançada sem `EFFORT_*` e sem o `CLAUDE_EFFORT`
  do ambiente.

## Tarefas

Cada uma traz asserção vermelha antes, implementação, verde, mutante provado com `--only`, lint, a suíte e o
commit. O Check de cada linha está no `checkpoint.md`.

### Task I1 — o `TEST_CMD` que não rodou não é suíte vermelha (item 5)
**Files:** `bin/sdd` (`run_check_cmd`, `gate_EXEC`, `gate_QA`, `gate_REVIEW`), `tests/check-gates.sh`, `tests/check-mutation.sh`, `docs/pipeline.md`
### Task I2 — o `blocked` para a linha, e a saída do conflito é `git merge` (itens 6 e 7)
**Files:** `bin/sdd` (`gate_PR`, `gate_REVIEW`, o comentário do `GATE_HANDOFF_BLOCKED`), `agents/sdd-publisher.md`, `agents/sdd-reviewer.md` e espelhos, `templates/review.md`, sensores, mutantes
### Task I3 — o `gate_PR` lê o head, o registro grava o sha verificado, e o corpo se edita pela REST (itens 1, 2 e 13)
**Files:** `bin/sdd` (`mission_tip`, `gate_PR`), `agents/sdd-publisher.md` e espelho, sensores, mutantes, `docs/pipeline.md`
### Task I4 — código commitado depois da rodada reabre a REVIEW (item 4)
**Files:** `bin/sdd` (`gate_REVIEW`), `agents/sdd-reviewer.md` e espelho, sensores, mutantes
### Task I5 — o K8 mede o branch que a missão declara (item 11)
**Files:** `bin/sdd` (bloco K8 do `gate_DOCS`), `tests/check-gates.sh`, mutante
### Task I6 — o e2e vermelho diz se o caso já caiu antes (item 10)
**Files:** `bin/sdd` (braço `up` do e2e no `gate_QA`), `tests/check-gates.sh` (fixture copiado de log real), mutante
### Task I7 — o corpo do PR leva o que os handoffs dizem (itens 8, 9 e 12)
**Files:** `bin/sdd` (`gate_PR`, as linhas `kit:`), `agents/sdd-publisher.md` e espelho, `templates/pr-body.md`, sensores, mutante
### Task I8 — o `gate:` só cita o que se pode refazer ou abrir (item 3)
**Files:** `templates/handoff.md`, `templates/review.md`, `tests/check-templates.sh`
### Task I9 — fecho
**Files:** `TODO.md` (`RESOLVED by` nos 13 itens)

## PLAN-AUTO

Os seis critérios estão ✅:
- **a:** o grill fechou com 12 respostas;
- **b:** kaizen K1–K8 ✅, DDD `n/a`;
- **c:** a sessão nova somente leitura achou 4 pontos, corrigidos sem segunda passada;
- **d:** 9 Checks vermelhos;
- **e:** `JIRA_ENABLED=false`;
- **f:** `adr:` aponta a ADR 0024 `proposed`, e `sdd adr check --phase plan` dá rc 0.

`aprovacao:` está vazio, por regra.

## A medida de novo, pelo relay

- `sdd why 20261121-l3-gates-do-fim-da-linha PLAN` → pede o `sdd approve`.
- `tests/check-checkpoint.sh --check …/checkpoint.md` → `ok    checkpoint.md: 9 row(s), 8 under the anchor rule, none blind`.
- `tests/check-checkpoint.sh --red …/checkpoint.md --list` → os 9 Checks listados, nenhum rodado. Nenhum `sdd run`
  vivo na máquina (`pgrep -af '[b]in/sdd run'`).
- `tests/check-checkpoint.sh --red …/checkpoint.md` → `ok    checkpoint.md: 9 pending Check(s), every one red at HEAD`, rc 0, de 02:48:46 a 03:09:20. Cada Red é igual ao "Antes" do plano: `0 0 0`, `0 0 0 0 0 0 0 0 0 0`, `0 0 0 0 0 0 0 0`, `0 0 0 0 0`, `0 0 0`, `0 0 0`, `0 0 0 0 0 0 0 0`, `0 0`, `0`.
- Amostra do contexto verificado, 4 comandos, todos iguais ao plano:
  - `git ls-files .claude/agents` → 8;
  - o `grep` da config → as 8 chaves com os valores do plano;
  - os blocos vizinhos do `check-gates.sh` (`TEST_CMD="false"`, `^write_r12()`, `^k8_world()`, `gate_PR asks`) →
    todos presentes;
  - `grep -n 'stub/gh'` → 4 stubs escritos no `check-gates.sh`, dos quais os 2 das linhas 3660 e 3682 respondem
    ao `gate_PR`, como o plano diz.
- Leitor D22 → `12 (recommended) of 12`.
