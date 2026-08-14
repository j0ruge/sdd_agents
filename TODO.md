# TODO — `sdd_agents`

Achados que **não cabem na missão atual**, registrados por qualquer agente ou humano
(kaizen princípio 10: oportunidade registrada, nunca desvio de escopo, nunca achado perdido).

Formato:

```md
- [ ] <o quê> — `arquivo:linha` — <por que importa> — descoberto por `<agente>` na missão `<slug>` (YYYY-MM-DD)
```

Achados sobre **repos-alvo** vão para o `TODO.md` daquele repo. Este arquivo é só sobre o kit.

## Aberto

- [ ] Confirmar comportamento de `claude -p` com slash command literal (`/qa-report`, `/goal`) em
  headless — `agents/sdd-qa.md`, `agents/sdd-reviewer.md` — as skills `qa-report`/`qa-execution`
  têm `disable-model-invocation: true`, então o boot depende do slash pegar; fallback é
  `--append-system-prompt-file`. — descoberto por `humano` no planejamento (2026-08-14)
- [ ] Multi-missão concorrente exigiria `git worktree` por missão — hoje é 1 missão por branch por
  vez (YAGNI declarado no plano). Reavaliar se aparecer demanda real. — descoberto por `humano` no
  planejamento (2026-08-14)
- [ ] Destilar handoffs/KAIZEN_LOG para o vault Obsidian continua manual/editorial. Avaliar um
  `sdd digest` que gere o rascunho. — descoberto por `humano` no planejamento (2026-08-14)

## Feito

- [x] Re-link do shim quebrado do `agent-browser` (I0) — resolvido em 2026-08-14, com sensor
  permanente no `sdd preflight`.
