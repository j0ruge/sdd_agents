# KAIZEN_LOG — `sdd_agents`

Registro de melhorias com **antes/depois medido**. Sem número, não entra.

---

## 2026-08-14 — Nascimento do kit

**Problema (Gemba):** o fluxo de desenvolvimento documentado em
`obsidian/01 Projects/Sales Quote JRC/Fluxo-Desenvolvimento-Template-Prompt-QA.md` funciona, mas
exige **~6 intervenções manuais** depois do planejamento (`/clear` 2x, troca manual de modelo,
invocar QA, invocar review, push/PR) e sessões longas estouram a janela de contexto no meio da
execução — obrigando a recomeçar com estado só na cabeça do humano.

**Métrica-alvo:** 1 missão pequena atravessa do plano aprovado até **PR aberto** com
**0 intervenções humanas** e **0 estouros de contexto**.

| | Antes | Depois (alvo, medido no piloto SQ-94) |
|---|---|---|
| Intervenções humanas pós-plano | ~6 | 0 |
| Estouros de contexto por missão | frequente em missões médias | 0 (sessão por fase/incremento) |
| Gate de qualidade | rótulo ("está pronto") | artefato (teste, spec, grade, PR) |
| Achado fora de escopo | perdido ou vira desvio | entrada no `TODO.md` |

**Contramedida:** 6 agentes especializados + runner `bin/sdd` que encadeia sessões headless por
fase e por incremento, com gates por artefato e handoffs em disco.

**Desperdícios cortados no planejamento (K3):** claude-mem (injeção não curada gasta janela),
daemon/UI/banco de estado (estado derivado dos artefatos basta), Opus no publisher (tarefa
mecânica → Sonnet).

**Status:** implementação em curso (incrementos I0–I12 do plano). Resultado medido entra aqui
quando o piloto I11 fechar.

---

## 2026-08-14 — Shim quebrado do `agent-browser` (I0)

**Problema:** `~/.nvm/versions/node/v22.22.3/bin/agent-browser` era symlink para
`~/.hermes/hermes-agent/node_modules/...`, caminho inexistente — o binário `agent-browser`
simplesmente não existia no PATH (`command not found`), o que derrubaria a fase QA em silêncio.

**Contramedida:** re-link para o pacote são em `lib/node_modules/agent-browser/bin/agent-browser.js`.

**Sensor:** `agent-browser --version` entrou no `sdd preflight` — o ambiente passa a ser
verificado antes de cada missão, não descoberto no meio da fase QA.

| | Antes | Depois |
|---|---|---|
| `agent-browser --version` | `command not found` | `agent-browser 0.27.0` |
| Descoberta da quebra | no meio da fase QA | no preflight, antes de gastar sessão |

---

## 2026-08-14 — A fase headless não conseguia executar comando nenhum

> Missão `20260814-dry-run-completo`. O achado de maior valor da missão **não foi o que ela ia
> entregar** — foi o defeito estrutural que ela expôs no kit ao ser a primeira a rodar headless
> de verdade. Por isso a missão-fixture existe.

**Problema (Gemba):** `run_phase()` montava `claude -p … --permission-mode acceptEdits` **sem**
`--allowedTools`. `acceptEdits` auto-aprova **edição de arquivo**, não `Bash`. Na prática a sessão
de fase só conseguia ler: `tests/run-all.sh`, `bash -n bin/sdd` e até `bash -c 'echo hello'`
voltavam "This command requires approval". **`git add` também era negado.** O `sdd-executor` não
rodava a suíte na abertura, não via o Red, não verificava o Green e não conseguia commitar — e
`gate_EXEC` exige hash real no `git log`. **A fase EXEC era insatisfazível por construção**, e o
mesmo valia para QA/REVIEW (que rodam `TEST_CMD`) e PR (que precisa de `git push`/`gh`).

O modo de falha era do tipo mais caro: silencioso. Nada no runner acusava; a sessão simplesmente
não produzia artefato, e o gate reprovava com "1 de N incrementos ainda por executar" para sempre.

**Contramedida:** `ALLOWED_TOOLS` (default `Bash`) no `.sdd/config.sh`, passado como
`--allowedTools` em `run_phase()` — commit `2083680`.

| | Antes | Depois |
|---|---|---|
| Comandos que a sessão de fase consegue executar | 0 (só leitura) | os de `ALLOWED_TOOLS` |
| Fase EXEC | insatisfazível por construção | `357b401` rodou a suíte, viu Red, viu Green, commitou |
| Sessões gastas contra a parede por incremento `blocked` | 4 (até estourar `phase_budget`) | 0 — escala na hora, `exit 3` |
| Detecção | no meio da 1ª missão headless | — (sensor de preflight ainda pendente, no `TODO.md`) |

**Jidoka na prática:** a primeira sessão EXEC **não** contornou o impedimento. Marcou o incremento
`blocked`, escreveu a causa raiz no checkpoint e escalou sem escrever uma linha de código. Seguir
teria significado commitar bash não executado e marcar `done` — o "rótulo, não artefato" que o kit
existe para proibir. A linha parou, o defeito apareceu, o kit ficou mais forte.

**O que ainda falta (registrado no `TODO.md`, não fechado aqui):** o sensor durável. Hoje nada
impede a regressão silenciosa — o `sdd preflight` valida que o `claude -p` responde, o que **não**
cobre este modo de falha. O preflight precisa disparar uma sessão headless real com as mesmas
flags e exigir que ela **execute** um comando.

---

## 2026-08-14 — `--dry-run` mostrava o pipeline pela metade (I1)

**Problema (Gemba):** `sdd run <missão> --dry-run` existe para responder *"o que vai acontecer se
eu rodar isto?"* antes de gastar token. Respondia pela metade: imprimia a **primeira** fase e dava
`return 0`. Numa missão recém-planejada, o usuário via `EXEC` e não ficava sabendo que depois
viriam QA, REVIEW, DOCS e PR — nem com que agente e modelo cada uma rodaria.

**Contramedida:** cursor próprio sobre a lista `$PHASES` (`next_pending_phase()`), nunca
re-chamando `current_phase()` — que travaria na mesma fase para sempre, já que o dry-run não muda
o disco. Commit `357b401`.

| | Antes | Depois |
|---|---|---|
| Fases nomeadas pelo dry-run (missão recém-planejada) | 1 (`EXEC`) | 5 (`EXEC`, `QA`, `REVIEW`, `DOCS`, `PR`) |
| Agente/modelo por fase visíveis antes de gastar token | só da 1ª | de todas |
| Sensores na suíte | 2 | 3 (`check-dry-run.sh`) |
| Asserções na suíte | 90 | 120 |

**Sensor durável:** `tests/check-dry-run.sh`, permanente em `tests/run-all.sh`. Observado vermelho
antes do verde: projetava só `EXEC=sdd-executor`, faltando QA/REVIEW/DOCS/PR.

**Efeito colateral honesto, não escondido:** projetar exige avaliar os gates, e três deles rodam
`TEST_CMD`. O dry-run escreve `.sdd/logs/<missão>/gate-*-test-<ts>.log` (gitignored, memoizado por
processo). O `--help` e o [`docs/pipeline.md`](docs/pipeline.md) dizem isso com todas as letras —
a frase fácil "o dry-run não mexe em nada" seria mentira.

---

## 2026-08-14 — Asserção que virou decoração (dívida de sensor)

**Problema:** quando `53cf63a` moveu o `pipeline.log` para `.sdd/logs/`, a asserção
`projeção blocked não cria pipeline.log` continuou apontando para o caminho velho — onde o runner
não escreve mais em circunstância nenhuma. Ela seguia imprimindo `ok` **por vacuidade**: com o bug
que ela guardava reintroduzido à mão, continuava verde. Uma asserção que não pode falhar não se
distingue, na saída da suíte, de uma que passa.

**Como apareceu:** teste de mutação **à mão** — sabotar o código e exigir que a suíte fique
vermelha. Três rodadas seguidas (QA volta 2 e REVIEW r1) usaram a técnica e acharam frestas.

| | Antes | Depois |
|---|---|---|
| Asserções vácuas conhecidas | 4 (1 na QA, 3 no review r1) | 0 |
| Frestas provadas por mutação, não por leitura | — | 6 |
| Asserções na suíte | 118 (fim da QA) | 120 (fim do review) |
| Teste de mutação | manual, por sorte | ainda manual — `tests/check-mutation.sh` está no `TODO.md` |

**Contramedida parcial, dita como parcial:** as frestas foram fechadas, mas a **classe** do
problema continua. Enquanto a mutação for manual, a próxima asserção decorativa só aparece por
sorte. `tests/check-mutation.sh` — o sensor do sensor — é o item de maior alavancagem no
`TODO.md`. Registrar como "resolvido" seria exatamente o rótulo-sem-artefato que o kit proíbe.
