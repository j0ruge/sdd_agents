# Notas de execução — as reincidentes primeiro (lote 1 de zerar a catraca)

> **Append-only.** Uma linha por evento; nunca reescreva o arquivo, nunca o releia inteiro.
> Escrever nota é `>>`. Esta missão é executada fora do `sdd run`, então nenhum boot inlina
> estas notas: a sessão que retoma lê as últimas 10 com `tail`.

## Notas de execução

> Uma linha por evento relevante: bloqueio, decisão tomada, desvio do plano com justificativa.
> Intervenção humana na linha usa o marcador `intervention:` abrindo a linha, fora desta citação.

- 2026-11-12 02:36 · `PLAN` · base `a48cf3c`; `check-todo.sh --count TODO.md` 86, 13 itens com `RECURRED` (25 voltas), `--anchors` 0 fora do alvo; três das voltas (`sdd_agents/20261112`) são do grill desta missão e estão no `TODO.md` do worktree.
- 2026-11-12 02:36 · `PLAN` · sensores cronometrados em paralelo em `a48cf3c`: templates 1 s, todo 5 s, hat 5 s, dry-run 11 s, adr 12 s, preflight 115 s, gates 153 s; todos rc 0.
- 2026-11-12 02:48 · `PLAN` · suíte rápida em `a48cf3c`: `bash tests/run-all.sh` rc 0 em 583 s, `anchors: all 792 mutants still apply and leave valid code`.
- 2026-11-12 02:48 · `PLAN` · `tests/check-checkpoint.sh --check` rc 0 (`15 row(s), 14 under the anchor rule, none blind`); `--red` rc 0: I1–I6 e I8, I10–I14 `prints '0', wants '1'`; I7 e I9 `prints '0 0', wants '1 1'`; I15 `prints '0', wants '13'`; `15 pending Check(s), every one red at HEAD`.
- 2026-11-12 02:48 · `PLAN` · teste de autocontenção: um agente novo leu só `00-missao.md`, `01-plano.md` e `checkpoint.md` e descreveu o I1 do primeiro ato ao commit do checkpoint; as 16 asserções do plano batem byte a byte com as células do Check; as lacunas que ele listou (primeiro ato, tempo da suíte, definições do I8, `coordination_enter`, forma do `log=`, handoff do I15) foram escritas no plano.
- 2026-11-12 02:48 · `PLAN` · `sdd health` fora desta missão por ordem do humano (decisão 6): a missão fecha sem carimbo de mutação.
- 2026-11-12 08:07 · `EXEC` · primeiro ato: branch `fix/as-reincidentes-primeiro`, árvore limpa, `aprovacao: humano-2026-11-12`, pasta commitada, 13 `RECURRED`; checkout principal em `a48cf3cc923a3cc9aea11771ee5ee0e3e649c431` com `status --porcelain` vazio. Execução pelo `superpowers:executing-plans` + TDD, sessão interativa.
- 2026-11-12 08:23 · `I1` · suíte rápida verde em `60042c9` (645 s, num clone de rascunho do worktree; o lint pula porque o `shellcheck` não está instalado nesta máquina, e o `bash -n` o substitui por commit); sete âncoras do `TODO.md` reancoradas no mesmo commit.
