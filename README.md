# sdd_agents

Kit de **agentes autônomos de desenvolvimento**: do plano aprovado ao **PR aberto**, sem intervenção humana no meio.

O humano participa de duas coisas: **planejar** e **fazer merge**. O resto (execução TDD, QA, review, documentação, PR) roda em sessões headless encadeadas pelo runner `bin/sdd`.

## Como funciona (30 segundos)

```
[você] ──aprova plano──▶ sdd-planner ──▶ bin/sdd run <missão>
                                             │
             TICKET → EXEC → QA ⇄ EXEC → REVIEW → DOCS → PR
                                             │
                                        [você] ──▶ merge
```

Cada fase é uma **sessão nova** do `claude -p` (anti-estouro de contexto). O estado vive em disco,
em `docs/handoffs/<missão>/` do repo-alvo. Não há arquivo de estado: o runner **deriva** a fase
atual dos artefatos e roda a primeira cujo gate não está satisfeito — morreu no meio, `sdd run`
de novo continua do ponto exato.

**Sucesso nunca é a resposta do modelo.** Cada gate é reavaliado pelo runner (roda os testes,
faz grep no checkpoint, olha o `git log`). Rótulo ≠ artefato.

## Instalação num repo-alvo

```bash
git clone https://github.com/j0ruge/sdd_agents ~/repos/sdd_agents
export PATH="$HOME/repos/sdd_agents/bin:$PATH"     # ou ln -s .../bin/sdd ~/.local/bin/sdd

cd ~/repos/meu-projeto
sdd install            # cria .sdd/config.sh e copia .claude/agents/sdd-*.md
$EDITOR .sdd/config.sh # ajuste TEST_CMD, E2E_CMD, APP_URL, JIRA_ENABLED...
sdd preflight          # sensor de ambiente: claude, gh, agent-browser, plugins, tree limpo
```

`sdd install` é idempotente: rodar de novo mostra o diff dos agentes em vez de sobrescrever.

## Uso

```bash
sdd run <missão>       # executa a partir do primeiro gate não satisfeito, até o PR
sdd status <missão>    # onde está, o que falta, por que travou
sdd retry <missão>     # re-tenta a fase corrente com sessão nova
sdd close <missão>     # pós-merge: fecha a issue do JIRA
sdd run <missão> --dry-run   # imprime os prompts de boot sem gastar token
```

A missão nasce no planejamento (`sdd-planner`, interativo, com você presente) e é identificada
pelo diretório `docs/handoffs/<YYYYMMDD>-<slug>/`.

## Documentação

| Onde | O que tem |
|---|---|
| [`docs/pipeline.md`](docs/pipeline.md) | máquina de estados, gates por fase, o que cada agente lê e escreve |
| [`docs/failure-modes.md`](docs/failure-modes.md) | o que quebra, como o kit reage, como destravar |
| [`config/schema.md`](config/schema.md) | cada chave de `.sdd/config.sh`, com default e porquê |
| [`agents/`](agents/) | os 6 agentes (markdown aberto — portável para outros harnesses) |
| [`templates/`](templates/) | missão, plano, handoff, checkpoint, corpo do PR |
| [`CLAUDE.md`](CLAUDE.md) | convenções para quem (humano ou agente) mexe **neste** kit |
| [`KAIZEN_LOG.md`](KAIZEN_LOG.md) | histórico de melhorias com antes/depois medido |
| [`TODO.md`](TODO.md) | achados sobre o próprio kit, registrados por qualquer agente |

## Os 6 agentes

| Agente | Fase | Modelo | Entrega |
|---|---|---|---|
| `sdd-planner` | plano | Fable (interativo) | `00-missao.md`, `01-plano.md`, `checkpoint.md` |
| `sdd-executor` | execução TDD, 1 sessão por incremento | Opus | commits + `checkpoint.md` atualizado |
| `sdd-qa` | QA exploratório + specs Playwright | Opus | `docs/qa/`, specs e2e, `30-handoff-qa.md` |
| `sdd-reviewer` | code review até Grade A | Opus | `40-review-r<N>.md` + correções |
| `sdd-docs` | documentação viva | Opus | docs do alvo sincronizados + `45-docs.md` |
| `sdd-publisher` | push + PR | Sonnet | PR aberto + `50-pr.md` |

## Requisitos

`claude` CLI autenticado · `gh` autenticado · `bash` 4+ · `git` · `uuidgen` (util-linux) ·
`jq` · `agent-browser` (só para a fase QA de projetos com UI).
