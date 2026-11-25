# Aceite do plano — L4: preflight, health e sensores

> Extrato que o dono leria antes do `sdd approve` (ato `approve` do `commands/sdd-worker.md`). A sessão
> orquestradora o escreveu em 2026-11-21, sobre `a0004df`. A fonte é o `00-missao.md` e o `01-plano.md` ao lado, e
> este arquivo não os substitui.
>
> A ordem do dono em vigor vale como o `YES` do aceite, depois da medida e deste extrato: "o worker assina, aprova
> e mergeia", sob a delegação `full` assinada em 2026-11-20 19:55. O `allows approve` respondeu
> `allowed approve at full`. O planner rodou em Fable, com `model: fable` passado na chamada.

**Goal:** os 15 itens do L4 fecham, cada um com asserção e com o mutante que a prova:
- o `sdd preflight` deixa de afirmar o que não mediu;
- o `sdd run` e o `sdd retry` param antes da sessão que o harness vai negar;
- quatro sensores recusam o que deixavam passar.

**Architecture:** nenhuma arquitetura nova. São quinze consertos em quatro lugares.
- **`cmd_preflight`:** lê o que já tem em mãos.
  - Na sonda do `Bash`: o `tool_result`, os hooks e o `.skills` da `init`.
  - No `TODO_FILE`: a forma, pelo `check-todo.sh`, e o preâmbulo, pelo git do kit.
  - Os caminhos da árvore suja.
  - A marca no ambiente do `TEST_CMD`.
- **O lançamento do `sdd run` e do `sdd retry`:**
  - as skills das fases, que param a corrida (decisão 3);
  - o clone do kit, que só avisa.
- **`cmd_kaizen`:** ganha a guarda do chapéu nas duas sessões (decisão 7).
- **Três sensores:** `check-checkpoint.sh` (o relógio), `check-todo.sh` (o `PR #N`) e `check-health.sh` (a sonda de
  interrupção). Além deles, `tests/isolate-git.sh` passa a fixar a raiz das skills (decisão 9).

**Tech Stack:** bash (`bin/sdd`, sensores em `tests/`) e markdown (`sdd-kaizen`, templates do `TODO.md`,
`docs/failure-modes.md`, `config/schema.md`). São 41 frases de asserção e 31 mutantes novos. A catraca não se move
nesta missão.

## Restrições

- **Escopo:** os 15 itens da tabela do `00-missao.md`.
- **Fora do escopo:**
  - o catálogo inteiro e o carimbo;
  - `tests/health-baseline.txt`;
  - `CLAUDE.md` e `.claude/rules/`, que vão em linhas `⛔` na DOCS;
  - a parada da skill no `sdd close` e no `sdd kaizen`;
  - a duração dos hooks;
  - o `issue #N` de outro repositório.
- **Grill:** `9 (recommended) of 9`, as **9 delegadas** por escrito ao worker, sem que o dono as visse na hora.
  - As decisões: 1 (o id e o branch), 2 ◆ (a forma do `TODO_FILE` só avisa), 3 ◆ (uma busca de skills, o `sdd run`
    e o `sdd retry` param com `die`), 4 ◆ (o preâmbulo contra as revisões do template), 5 (o `PR #N` sem rastro),
    6 (os hooks e o `.skills` pelo stream da sonda), 7 (a guarda do chapéu no juiz), 8 (`adr: none`) e 9
    (`isolate-git.sh` fixa a raiz das skills).
  - Vão ao corpo do PR para o aceite do dono:
    - os três ◆ (decisões 2 a 4) e as decisões 5 a 9;
    - os três mecanismos decididos sem pergunta (itens 3, 2 e 5).
  - A decisão 3 muda o comportamento de todo alvo. O alvo sem `codereview` no `READ_EXTRA` para no primeiro
    `sdd run` (pendência 4, yokoten).
- **Ordem com o L3 (#458):** o `sdd run` só começa depois do merge dele. Antes, entram `git merge origin/main` aqui,
  `--anchors`, `--check` e `--red` de novo, e `./bin/sdd preflight` (pendência 1).
- **Effort:** a EXEC roda em `medium`, o padrão do `.sdd/config.sh`. É lançada sem `EFFORT_*` e sem o
  `CLAUDE_EFFORT` do ambiente.

## Tarefas

Cada tarefa traz a asserção vermelha antes, a implementação, o verde, o mutante provado com `--only`, o lint, a
suíte e o commit. O Check de cada linha está no `checkpoint.md`.

### I1 — o preflight sem ruído de pipe, e a árvore suja com os caminhos (itens 12 e 11)
### I2 — a sonda do `Bash` dá `ok` pelo comando rodado (item 6)
### I3 — os hooks que toda fase carrega, e a skill pelo `.skills` da `init` (item 15)
### I4 — o preflight mede a forma do `TODO_FILE` (item 1, decisão 2)
### I5 — o preâmbulo do `TODO_FILE` contra as revisões do template (item 10, decisão 4)
### I6 — o `sdd run` para antes da sessão que será negada (item 7, decisões 3 e 9)
### I7 — o `TEST_CMD` que deixa processo vivo, e a suíte sem o linter (itens 3 e 13)
### I8 — o clone velho do kit, e o worktree sem o espelho dos chapéus (itens 2 e 14)
### I9 — o juiz passa pela guarda do chapéu (item 4, decisão 7)
### I10 — o `atualizado:` no futuro é recusado (item 5)
### I11 — a sonda de interrupção lê o grupo depois que a suíte roda (item 8)
### I12 — o `PR #N` sem rastro no histórico (item 9, decisão 5)
### I13 — fecho (`RESOLVED by` nos 15 itens)

## PLAN-AUTO

Os seis critérios estão ✅:
- **a:** o grill fechou com 9 respostas;
- **b:** o checklist kaizen K1–K8 está ✅, e o DDD é `n/a`;
- **c:** o teste de autocontenção foi lido incremento a incremento;
- **d:** são 13 Checks vermelhos;
- **e:** `JIRA_ENABLED=false`;
- **f:** `adr: none`.

`aprovacao:` está vazio, por regra.

## A medida de novo, pelo relay

- `tests/check-checkpoint.sh --check …/checkpoint.md` → `ok    checkpoint.md: 13 row(s), 12 under the anchor rule, none blind`.
- `tests/check-checkpoint.sh --red …/checkpoint.md --list` → os 13 Checks listados, nenhum rodado.
- A corrida do L3 tinha terminado às 15:23, com `sdd run rc=2`, e `pgrep -af '[b]in/sdd run'` não achou nenhuma
  outra viva.
- `tests/check-checkpoint.sh --red …/checkpoint.md` → `ok    checkpoint.md: 13 pending Check(s), every one red at HEAD`, rc 0, de 15:25:13 a 15:33:54, sem `sdd run` vivo. Cada Red é igual ao "O vermelho medido" do plano: `0 0`, `0 0 0`, `0 0 0 0`, `0 0 0`, `0 0 0 0`, `0 0 0 0 0 0`, `0 0 0`, `0 0 0 0 0 0`, `0 0 0 0 0 0` (I9, que quer `1 1 1 1 1 0`), `0`, `0`, `0 0 0`, `0` (I13, que quer `15`).
- Leitor D22 → `9 (recommended) of 9`.
