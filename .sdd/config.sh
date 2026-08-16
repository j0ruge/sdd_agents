# .sdd/config.sh — sdd_agents (o kit desenvolvido por ele mesmo)
PROJECT_NAME="sdd_agents"
DEFAULT_BRANCH="main"

# A suíte do kit: bash -n + shellcheck + contrato dos templates + máquina de estados.
TEST_CMD="tests/run-all.sh"
E2E_CMD=""
LINT_CMD="shellcheck -S warning bin/sdd tests/*.sh"

HANDOFF_DIR="docs/handoffs"
QA_DOCS_PATH="docs/qa"
TODO_FILE="TODO.md"

MODEL_EXEC="opus"
MODEL_QA="opus"
MODEL_REVIEW="opus"
MODEL_DOCS="opus"
MODEL_PUBLISH="sonnet"
MODEL_TICKET="sonnet"

QA_MAX_ITER=3
REVIEW_MAX_ITER=3
EXEC_MAX_RETRY=1
BUDGET_PER_PHASE_USD=15
PERMISSION_MODE="acceptEdits"

# O kit ainda nao existe como projeto no JIRA — a fase TICKET e exercitada no piloto sales_quote.
JIRA_ENABLED=false

# acceptEdits nao libera Bash — sem isto a fase EXEC e insatisfazivel (ver KAIZEN_LOG).
ALLOWED_TOOLS="Bash"

# Os artefatos deste repo sao PT-BR; a superficie do kit e ingles. Ver CLAUDE.md, secao Idioma.
OUTPUT_LANG="pt-BR"
