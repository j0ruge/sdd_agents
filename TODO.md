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
- [ ] Incremento `blocked` no checkpoint deveria escalar na hora, não gastar o orçamento de
  sessões — `bin/sdd:276` + `bin/sdd:830-844` — `gate_EXEC` já sabe dizer "Jidoka: a linha para",
  mas `cmd_run` só distingue gate-insatisfeito de gate-insatisfeito-e-sem-progresso; como a
  sessão que marca `blocked` mexe no `checkpoint.md`, o `state_fingerprint` muda e o runner
  entende "a sessão avançou — seguindo", rebootando EXEC até estourar `phase_budget` (aqui,
  4 sessões). `blocked` é decisão deliberada de parar a linha: deveria dar `return 3` imediato.
  — descoberto por `sdd-executor` na missão `20260814-dry-run-completo` (2026-08-14)
- [ ] Confirmar comportamento de `claude -p` com slash command literal (`/qa-report`, `/goal`) em
  headless — `agents/sdd-qa.md`, `agents/sdd-reviewer.md` — as skills `qa-report`/`qa-execution`
  têm `disable-model-invocation: true`, então o boot depende do slash pegar; fallback é
  `--append-system-prompt`. — descoberto por `humano` no planejamento (2026-08-14)
- [ ] Multi-missão concorrente exigiria `git worktree` por missão — hoje é 1 missão por branch por
  vez (YAGNI declarado no plano). Reavaliar se aparecer demanda real. — descoberto por `humano` no
  planejamento (2026-08-14)
- [ ] Destilar handoffs/KAIZEN_LOG para o vault Obsidian continua manual/editorial. Avaliar um
  `sdd digest` que gere o rascunho. — descoberto por `humano` no planejamento (2026-08-14)

## Feito

- [x] Re-link do shim quebrado do `agent-browser` (I0) — resolvido em 2026-08-14, com sensor
  permanente no `sdd preflight`.
- [x] `claude -p --agent <nome>` funciona headless — verificado em 2026-08-14 num repo-fixture:
  a sessão encarnou o `sdd-executor` e recitou a primeira instrução do arquivo do agente. O
  fallback `--append-system-prompt` fica sem uso. `--setting-sources user,project,local` é
  passado explicitamente pelo runner para garantir que `.claude/agents/` do alvo carregue.
