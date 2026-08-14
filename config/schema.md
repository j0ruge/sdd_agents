# Schema de `.sdd/config.sh`

O arquivo é **bash puro** — o runner faz `source` nele. Sem lógica: só atribuições.
Criado por `sdd install` a partir de [`examples/sales_quote.conf`](examples/sales_quote.conf).

Regra: se uma chave obrigatória estiver vazia, `sdd preflight` falha **antes** de gastar sessão.

## Identidade do projeto

| Chave | Obrigatória | Default | O que é |
|---|---|---|---|
| `PROJECT_NAME` | sim | — | Nome curto do repo-alvo. Aparece nos logs e no corpo do PR. |
| `DEFAULT_BRANCH` | sim | — | Branch **base das PRs**. ⚠️ Nem sempre é `main`: no `sales_quote` o fluxo é `develop → staging → main`, então é `develop`. Confira `git symbolic-ref refs/remotes/origin/HEAD` em vez de supor. |

## Comandos de verificação (os sensores do runner)

Todos rodam com cwd na raiz do repo-alvo. O runner só olha o **exit code**.

| Chave | Obrigatória | Default | O que é |
|---|---|---|---|
| `TEST_CMD` | sim | — | Suíte unit/integration. É o gate de EXEC e parte do gate de REVIEW. Deve ser rápida o bastante para rodar a cada incremento. |
| `E2E_CMD` | não | vazio | Suíte end-to-end. Vazio ⇒ o gate de QA ignora e2e (projeto sem UI). |
| `E2E_DIR` | não | `e2e` | Onde o `sdd-qa` commita specs novas. |
| `LINT_CMD` | não | vazio | Roda no gate de REVIEW quando definido. |
| `BUILD_CMD` | não | vazio | Roda no gate de REVIEW quando definido. |

## Aplicação rodando (fase QA)

| Chave | Obrigatória | Default | O que é |
|---|---|---|---|
| `APP_URL` | só com `E2E_CMD` | vazio | URL que o `agent-browser` abre nas sessões exploratórias. |
| `DEV_UP_CMD` | não | vazio | Sobe o ambiente antes do QA (ex.: `docker compose up -d`). Vazio ⇒ o runner assume que já está de pé e avisa se `APP_URL` não responder. |
| `DEV_READY_CMD` | não | vazio | Comando que retorna 0 quando a app está pronta (ex.: `curl -sf $APP_URL`). O runner faz poll por até `DEV_READY_TIMEOUT` segundos. |
| `DEV_READY_TIMEOUT` | não | `90` | Segundos de espera pelo `DEV_READY_CMD`. |

## Caminhos de artefato

| Chave | Obrigatória | Default | O que é |
|---|---|---|---|
| `HANDOFF_DIR` | não | `docs/handoffs` | Raiz do estado durável. Cada missão vira `<HANDOFF_DIR>/<YYYYMMDD>-<slug>/`. **Commitado.** |
| `QA_DOCS_PATH` | não | `docs/qa` | Onde as skills `qa-report`/`qa-execution` escrevem. O runner não escreve aqui — as skills são as donas. |
| `TODO_FILE` | não | `TODO.md` | Destino dos achados fora de escopo. |

## Modelos por fase

Opus por default nas fases de julgamento; Sonnet onde Opus é desperdício — **exceção explícita,
nunca silenciosa** (kaizen K3). Valores: qualquer alias aceito por `claude --model`.

| Chave | Default | Por quê |
|---|---|---|
| `MODEL_EXEC` | `opus` | TDD e decisão de implementação. |
| `MODEL_QA` | `opus` | Julgamento exploratório é a parte cara do QA. |
| `MODEL_REVIEW` | `opus` | A skill `codereview` roteia internamente por severidade. |
| `MODEL_DOCS` | `opus` | Escrever doc que não mente exige modelo. |
| `MODEL_PUBLISH` | `sonnet` | Montar corpo de PR a partir de handoffs prontos é mecânico. |
| `MODEL_TICKET` | `sonnet` | Chamar `acli` com campos já decididos é mecânico. |

## Limites e política

| Chave | Default | O que é |
|---|---|---|
| `QA_MAX_ITER` | `3` | Voltas no loop QA⇄EXEC antes de `BLOCKED`. Protege contra "fix quebra outra jornada" infinito. |
| `REVIEW_MAX_ITER` | `3` | Sessões de review no total antes de `BLOCKED`. |
| `EXEC_MAX_RETRY` | `1` | Retentativas por incremento antes de `BLOCKED`. |
| `BUDGET_PER_PHASE_USD` | `15` | Vai em `--max-budget-usd` por sessão. Teto de dano, não orçamento. |
| `PUBLISH_ON_REVIEW_BLOCKED` | `off` | `draft` ⇒ review estourado abre PR **draft** com a grade atual e as pendências, em vez de parar seco. |
| `PERMISSION_MODE` | `acceptEdits` | Teto. `bypassPermissions` **nunca** é default do kit. |

## JIRA

| Chave | Default | O que é |
|---|---|---|
| `JIRA_ENABLED` | `false` | `true` ⇒ a fase TICKET roda (`/ticket open`) e `sdd close` fecha a issue pós-merge. Exige `.jira-project` no repo-alvo (lido pela skill `ticket`). |

Quando `JIRA_ENABLED=true`, `00-missao.md` **precisa** ter `versao:` preenchida — o rótulo de
versão é decisão humana, nunca headless. O gate PLAN-AUTO (critério `e`) verifica isso.

## Exemplo mínimo (projeto sem UI e sem JIRA)

```bash
PROJECT_NAME="meu-lib"
DEFAULT_BRANCH="main"
TEST_CMD="pytest -q"
JIRA_ENABLED=false
```

Tudo o mais cai no default. O gate de QA vira `qa: skipped` automaticamente quando não há
`E2E_CMD` e o diff não toca nada user-visible.
