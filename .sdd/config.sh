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
# declare), block. O I9 daquela missao pulou a etapa 3 e foi direto para `block` -- e a revisao
# pre-PR mediu o preco: as 14 missoes anteriores deste repo nao tinham chave `adr:`, entao TODAS
# voltaram a derivar PLAN (diferencial, mesma missao e mesmo disco: `off` da EXEC, `block` da
# PLAN). Por isso o repo ficou em `warn` ate a etapa 3.
#
# A etapa 3 aconteceu no I10 de 20261004-lote-4-a-catraca-zera, com o mapeamento confirmado pelo
# humano. A premissa de 2026-09-17 -- "nenhum commit liga as ADRs 0001-0007 a uma missao" -- caiu
# para tres das sete: a 0003 nasceu de 20260817-eixo-do-juiz, a 0004 de
# 20260819-fecho-que-nao-mente e a 0006 de 20260826-o-laco-da-qa. Cada uma ganhou a linha `Spec:`,
# e a missao, o `adr:` apontando de volta. As outras onze missoes declaram `adr: none`. Medido:
# `sdd adr check` -> nenhuma missao sem `adr:` decidido, rc 0 sob `block`.
#
# LIMITE declarado: as ADRs 0001, 0002, 0005 e 0007 seguem sem `Spec:`. Nenhuma nasceu de uma
# pasta de missao -- 0001 e 0002 do grill do I13.3, 0005 de um PR so de docs (#24), 0007 da spec
# da fronteira do chapeu em docs/superpowers/ --, e o `sdd adr check` le o vinculo a partir da
# missao: ADR que nenhuma missao declara nao e cobrada. Escrever `Spec:` nelas seria inventar a
# origem, o rotulo sem artefato que o principio 1 recusa.
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
