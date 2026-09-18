# .sdd/config.sh — sdd_agents (o kit desenvolvido por ele mesmo)
PROJECT_NAME="sdd_agents"
DEFAULT_BRANCH="main"

# A suíte do kit: bash -n + shellcheck + contrato dos templates + máquina de estados.
TEST_CMD="tests/run-all.sh"
E2E_CMD=""

HANDOFF_DIR="docs/handoffs"
QA_DOCS_PATH="docs/qa"
TODO_FILE="TODO.md"

# O kit adota o proprio mecanismo em etapas, na missao 20260917-o-numero-do-adr-nao-e-prosa,
# seguindo o caminho que o README.md prescreve para qualquer repo-alvo: off, warn, ETAPA 3 (fix ou
# declare), block. O I9 pulou a etapa 3 e foi direto para `block` -- e a revisao pre-PR mediu o
# preco: as 14 missoes anteriores deste repo nao tem chave `adr:`, entao TODAS voltaram a derivar
# PLAN. Diferencial, mesma missao e mesmo disco: `off` da EXEC, `block` da PLAN. Isso e a classe
# "estado mente sobre o disco" que o principio 4 existe para eliminar, e era silenciosa -- o
# `sdd adr check` respondia rc 0 e o `sdd preflight`, "no finding", porque o contador juntava
# `adr: none` (decisao que o gate ACEITA) com ausente/TBD (o que ele RECUSA).
#
# Hoje o contador separa os dois, entao a etapa 3 tem instrumento: o numero de "no decided `adr:`"
# chegando a zero e o sinal de que este repo pode voltar para `block`. Ate la, `warn` -- que deriva
# a fase como sempre e deixa uma linha `degraded kind:adr-check` por corrida.
#
# Nao se escreveu `adr: none` nas 14 por decisao humana de 2026-09-17: as ADRs 0001-0007 nao tem
# linha `Spec:` e nenhum commit as liga a uma missao, entao declarar "esta missao nao decidiu nada
# de arquitetura" seria um rotulo que nenhum artefato sustenta -- exatamente o que o principio 1
# recusa. Mapear as sete e trabalho de humano, e e o que destrava `block`.
ADR_CHECK="warn"
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
