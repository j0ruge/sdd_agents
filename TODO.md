# TODO — `sdd_agents`

Achados que **não cabem na missão atual**, registrados por qualquer agente ou humano
(kaizen princípio 10: oportunidade registrada, nunca desvio de escopo, nunca achado perdido).

Formato:

```md
- [ ] <o quê> — `arquivo:linha` — <por que importa> — descoberto por `<agente>` na missão `<slug>` (YYYY-MM-DD)
```

Achados sobre **repos-alvo** vão para o `TODO.md` daquele repo. Este arquivo é só sobre o kit.

## Aberto

- [ ] **BLOQUEANTE — a sessão de fase headless não tem permissão para rodar `TEST_CMD`** —
  `bin/sdd:491-499` — `run_phase()` invoca `claude -p … --permission-mode "$PERMISSION_MODE"`
  (`acceptEdits`) sem `--allowedTools`; `acceptEdits` auto-aprova **edição de arquivo**, não
  `Bash`. Na prática a sessão EXEC só consegue ler (`git`, `ls`, `cat`, `Read`): `tests/run-all.sh`,
  `bash -n bin/sdd` e até `bash -c 'echo hello'` são negados com "This command requires approval".
  **`git add` também é negado** (só o `git` de leitura passa), então a sessão não consegue nem
  commitar — e `gate_EXEC` exige hash real no `git log`. A fase EXEC é, hoje, insatisfazível por
  construção: o agente não roda a suíte na abertura, não vê o Red, não verifica o Green e não
  produz o artefato que o gate cobra. Vale igual para QA/REVIEW, cujos gates também rodam
  `TEST_CMD`, e para PR, que precisa de `git push`/`gh`. Direção: passar `--allowedTools` em
  `run_phase()` cobrindo `TEST_CMD`/`E2E_CMD`/`LINT_CMD` e o `git` de escrita (ou fazer
  `sdd install` escrever `permissions.allow` no `.claude/settings.json` do alvo). Sensor durável: um check no `sdd preflight` que dispara uma sessão headless real e
  afirma que ela **consegue executar** `TEST_CMD` — hoje o preflight só valida `claude -p`
  respondendo (`bin/sdd:646`), o que não cobre este modo de falha. — descoberto por `sdd-executor`
  na missão `20260814-dry-run-completo` (2026-08-14)
  **Atualização (2026-08-14):** a **causa** foi corrigida por `2083680` (`--allowedTools` em
  `run_phase()` + `ALLOWED_TOOLS` no config) e a sessão EXEC `357b401` provou o conserto — rodou
  `tests/run-all.sh`, viu o Red, viu o Green e commitou. Deixa de ser BLOQUEANTE. **Continua
  aberto pelo que falta: o sensor durável.** Não há nada que impeça a regressão silenciosa —
  o `sdd preflight` ainda não afirma que uma sessão headless de fato executa `TEST_CMD`.
- [ ] Incremento `blocked` no checkpoint deveria escalar na hora, não gastar o orçamento de
  sessões — `bin/sdd:276` + `bin/sdd:830-844` — `gate_EXEC` já sabe dizer "Jidoka: a linha para",
  mas `cmd_run` só distingue gate-insatisfeito de gate-insatisfeito-e-sem-progresso; como a
  sessão que marca `blocked` mexe no `checkpoint.md`, o `state_fingerprint` muda e o runner
  entende "a sessão avançou — seguindo", rebootando EXEC até estourar `phase_budget` (aqui,
  4 sessões). `blocked` é decisão deliberada de parar a linha: deveria dar `return 3` imediato.
  — descoberto por `sdd-executor` na missão `20260814-dry-run-completo` (2026-08-14)
- [ ] **`gate_QA` com `status: done` é insatisfazível em projeto sem interface** — `bin/sdd:303`
  + `bin/sdd:444` — `qa_substep` manda projeto sem `E2E_CMD`/`APP_URL` direto para `QA:close`,
  pulando as skills `qa-report`/`qa-execution` que são as donas de `docs/qa/` — logo a árvore
  nunca existe. Mas `gate_QA`, quando o status **não** é `skipped`, exige a Âncora 1: um
  relatório datado em `$QA_DOCS_PATH/reports/` marcado `closed`. Resultado: num projeto sem
  browser mas **com** mudança user-visible (o kit é o próprio caso — a jornada é `sdd` no
  terminal), o `sdd-qa` não tem status que seja ao mesmo tempo honesto e satisfazível:
  `skipped` mente (o diff chega ao usuário e a QA achou bug de verdade andando a jornada),
  `done` bate na Âncora 1 e reprova para sempre, `blocked` reprova por definição. A QA roda,
  encontra defeito real, e mesmo assim não consegue fechar o gate. Direção possível (é **decisão
  de contrato**, não conserto mecânico — por isso não virou incremento de fix): quando
  `qa_substep` = `close` por ausência de interface, `gate_QA` aceitar como Âncora 1 alternativa
  o próprio `30-handoff-qa.md` com `status: done` + campo `gate:` preenchido, já que ali está a
  evidência da jornada andada. Sensor durável junto: caso em `tests/check-gates.sh` afirmando
  que um projeto sem interface, com handoff `done`, passa no `gate_QA`. — descoberto por
  `sdd-qa` na missão `20260814-dry-run-completo` (2026-08-14)
- [ ] `sdd install` não ignora o `pipeline.log` das missões — `bin/sdd:706-712` — o install só
  acrescenta `.sdd/logs/` ao `.gitignore` do alvo. O `pipeline_log_line` (`bin/sdd:557`) escreve
  em `$HANDOFF_DIR/<missão>/pipeline.log`, que fica **untracked** em qualquer repo-alvo recém
  instalado e suja o `git status`. Tree sujo reprova `gate_REVIEW` (`bin/sdd:361`) e o
  `sdd preflight` (`bin/sdd:814`) — ou seja, o próprio diário do runner pode derrubar o gate de
  outra fase. Este repo não sente porque o `.gitignore` dele ganhou `*.log` à mão, fora do
  install; o piloto `sales_quote` vai sentir. Decidir se o `pipeline.log` é efêmero (entra no
  ignore do install) ou durável (é commitado como os handoffs) — hoje ele é as duas coisas
  dependendo do repo. — descoberto por `sdd-qa` na missão `20260814-dry-run-completo` (2026-08-14)
- [ ] A asserção "dry-run não toca no disco" é mais fraca do que parece —
  `tests/check-dry-run.sh:116` — ela vale sobre um fixture parado em EXEC, cujo `gate_EXEC`
  reprova por incremento pendente **antes** de chegar a rodar `TEST_CMD`. Num fixture que
  alcança um gate que roda a suíte (`gate_REVIEW`, por exemplo), o dry-run escreve
  `.sdd/logs/<missão>/gate-review-test-*.log` — verificado à mão nesta sessão. É subproduto de
  comportamento **aceito** pelo plano ("gates rodando `TEST_CMD` no dry-run é aceitável") e é
  gitignored, então não é bug; mas a asserção sugere uma garantia mais forte do que a que existe.
  Vale renomear para "não toca nos artefatos da missão" ou passar a exercitá-la também num
  fixture que chegue a `gate_REVIEW`. — descoberto por `sdd-qa` na missão
  `20260814-dry-run-completo` (2026-08-14)
- [ ] O `sdd-planner` ainda não foi exercitado numa missão real — as missões planejadas até aqui
  tiveram plano escrito à mão. Primeira missão planejada por ele deve conferir se o gate PLAN-AUTO
  é preenchido com evidência de verdade. — descoberto por `humano` na implementação (2026-08-14)
- [ ] Multi-missão concorrente exigiria `git worktree` por missão — hoje é 1 missão por branch por
  vez (YAGNI declarado no plano). Reavaliar se aparecer demanda real. — descoberto por `humano` no
  planejamento (2026-08-14)
- [ ] Destilar handoffs/KAIZEN_LOG para o vault Obsidian continua manual/editorial. Avaliar um
  `sdd digest` que gere o rascunho. — descoberto por `humano` no planejamento (2026-08-14)

## Feito

- [x] Re-link do shim quebrado do `agent-browser` (I0) — resolvido em 2026-08-14, com sensor
  permanente no `sdd preflight`.
- [x] **Boot por slash literal funciona headless** — verificado em 2026-08-14: `claude -p
  "/qa-report docs/qa …"` carrega as instruções da skill mesmo com `disable-model-invocation:
  true` (a sessão citou o Step 1 dela de volta). O fallback `--append-system-prompt` fica sem uso.
  A fase QA passou a ser três sessões — `/qa-report`, `/qa-execution`, `sdd-qa` — com o sub-passo
  **derivado dos artefatos** (`qa_substep`), não de um contador.
- [x] **`/goal` NÃO existe neste ambiente** — verificado em 2026-08-14 (`~/.claude/commands/`
  vazio, nada no cache de plugins). O padrão `/goal /codereview:codereview até Grade A` do
  template do usuário não é reproduzível headless; o `sdd-reviewer` conduz o laço por instrução
  própria, que era o fallback previsto no plano.
- [x] `claude -p --agent <nome>` funciona headless — verificado em 2026-08-14 num repo-fixture:
  a sessão encarnou o `sdd-executor` e recitou a primeira instrução do arquivo do agente. O
  fallback `--append-system-prompt` fica sem uso. `--setting-sources user,project,local` é
  passado explicitamente pelo runner para garantir que `.claude/agents/` do alvo carregue.
