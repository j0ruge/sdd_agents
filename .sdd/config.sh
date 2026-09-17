# .sdd/config.sh — sdd_agents (o kit desenvolvido por ele mesmo)
PROJECT_NAME="sdd_agents"
DEFAULT_BRANCH="main"

# A suíte do kit: bash -n + shellcheck + contrato dos templates + máquina de estados.
TEST_CMD="tests/run-all.sh"
E2E_CMD=""

HANDOFF_DIR="docs/handoffs"
QA_DOCS_PATH="docs/qa"
TODO_FILE="TODO.md"

# O kit adota o proprio mecanismo em duas etapas, na missao 20260917-o-numero-do-adr-nao-e-prosa:
# `warn` enquanto o ADR 0008 ainda nao existe, `block` no I9, depois de ele nascer do comando.
# Etapa 2 concluida: o ADR 0008 existe, `sdd adr check` responde rc 0 sobre o repo inteiro, e o
# gate de PLAN passa a cobrar `adr:` de toda missao nova deste repo.
ADR_CHECK="block"
ADR_DIR="docs/adr"

MODEL_EXEC="opus"
MODEL_QA="opus"
MODEL_REVIEW="opus"
MODEL_DOCS="opus"
MODEL_PUBLISH="sonnet"
MODEL_TICKET="sonnet"

QA_MAX_ITER=3
REVIEW_MAX_ITER=3
EXEC_MAX_RETRY=1
BUDGET_PER_PHASE_USD=40
PERMISSION_MODE="acceptEdits"

# O kit ainda nao existe como projeto no JIRA — a fase TICKET e exercitada no piloto sales_quote.
JIRA_ENABLED=false

# acceptEdits nao libera Bash — sem isto a fase EXEC e insatisfazivel (ver KAIZEN_LOG).
ALLOWED_TOOLS="Bash"

# Os artefatos deste repo sao PT-BR; a superficie do kit e ingles. Ver CLAUDE.md, secao Idioma.
OUTPUT_LANG="pt-BR"

# Words that must not appear on the kit surface — sdd health --release, line 5 (ADR 0007)
RELEASE_FORBIDDEN_WORDS="sales_quote SQ- JRC jrcbrasil"
