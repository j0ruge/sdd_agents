---
missao: 20261120-l2-o-sdd-plan-e-o-planner
fase: QA
status: done
sessao: 8db79c6e-baa1-41bc-b866-329850d255c5
data: 2026-11-20 21:26
gate: "sem interface, jornada no terminal: env com EFFORT_EXEC=xhigh e CLAUDE_EFFORT=medium herdados → tests/run-all.sh (21:13 → 21:22) rc 0, 'suite green', 0 linhas '^  FAIL', 2231 '^  ok    '; Checks do checkpoint rodados da célula: I1 '1 1 1 1', I2 '1 1 1 1 0', I3 '1 1 1 1 0', I4 '1 1 1 1 1 0', I5 '1 1', I6 '15' (célula diz 14; o 15º é o RESOLVED by do I7), I7 '1 1'; cmp agents/sdd-planner.md .claude/agents/sdd-planner.md → 0, diff do frontmatter contra origin/main = só '+model: fable'; --red num repo mktemp com 2 linhas pending: --list lista I1/I2, '2 pending Check(s) listed, none run', made.txt não criado; --only I1 → '1 of 2 pending Check(s) run, each red at HEAD; 1 not run — a partial measure', só I1 rodou; sem modo → '2 pending Check(s), every one red at HEAD'; --only I9 → FAIL nomeando I9, rc 1; passo 1 do /sdd-plan: git status --porcelain vazio, branch fix/l2-o-sdd-plan-e-o-planner, ls docs/handoffs 46 pastas, sdd status --no-gates <missão> imprime CHECKOUT-OWNER do run em curso, sem nome recusa com 'missing mission name', pgrep -af '[b]in/sdd run' acha o run; check-todo.sh --check TODO.md rc 0 '103 finding(s)', 14 de 14 títulos presentes uma vez cada, todos com RESOLVED by"
---

# Handoff — QA — L2: o `/sdd-plan` e o planner

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

Seis jornadas no terminal (suíte, os sete Checks, o espelho, o `--red`, a leitura do checkout do
`/sdd-plan` e o `TODO.md`), todas verdes no ambiente herdado com `EFFORT_EXEC=xhigh` exportado.
Zero achados confirmados: nenhuma spec, nenhum `F<n>`, nada para o humano decidir. A única diferença
é de rótulo: o Check do I6 responde `15` e a célula diz `14`, pelo motivo que o EXEC já escreveu.

## Estado do repo

- **Branch:** `fix/l2-o-sdd-plan-e-o-planner`, 16 commits à frente do `origin` (ainda sem push, que é do PR)
- **Último commit antes desta fase:** `975de35` `chore(checkpoint): I7 done (d48f7c9) e o 20-handoff-exec.md da volta do gate`
- **Working tree:** limpa antes deste handoff
- **Suíte:** `tests/run-all.sh` → verde, rc 0, 2231 `ok`, 0 `FAIL` (21:13 → 21:22, com `EFFORT_EXEC=xhigh` e `CLAUDE_EFFORT=medium` no ambiente)
- **E2E:** `E2E_CMD` vazio, porque o kit não tem interface. A jornada foi percorrida no terminal (campo `gate:`)

## O que foi feito

Nenhum commit de código nesta fase. A QA mediu e não mexeu em nada:

- jornada 1: `env | grep -E '^(EFFORT_|CLAUDE_EFFORT)'` → `EFFORT_EXEC=xhigh`, `CLAUDE_EFFORT=medium`; suíte verde nesse ambiente, que é o que o `gate_EXEC` lê. O conserto do I7 (`d48f7c9`) se confirma fora da sessão que o fez.
- jornada 2: os sete Checks, lidos da célula do `checkpoint.md` e rodados como estão escritos, imprimem o esperado. O do I6 é a exceção já explicada (`15`).
- jornada 3: espelho idêntico (`cmp` → 0), e no frontmatter do chapéu o diff contra `origin/main` é só `+model: fable`.
- jornada 4: o `--red` num repositório descartável. O `--list` não executa nada (o Check da I1 faria `touch made.txt`, e o arquivo não apareceu). O `--only I1` executa só a I1 e diz que a medida é parcial, e sem modo executa as duas. Um id inexistente (`--only I9`) é recusado pelo nome, com rc 1, antes de qualquer Check rodar.
- jornada 5: os quatro comandos do passo 1 do `commands/sdd-plan.md` respondem neste worktree. O `sdd status --no-gates` sem nome recusa, como o texto avisa, e com nome imprime a linha `CHECKOUT-OWNER` do run em curso, que é a saída "outro comando segura o checkout" que o passo descreve.
- jornada 6: `check-todo.sh --check TODO.md` rc 0 (103 achados). Os 14 títulos da tabela do `00-missao.md` aparecem uma vez cada, e cada um tem `RESOLVED by <hash>` no corpo.

## Artefatos

| Arquivo | O que contém |
|---|---|
| `docs/handoffs/20261120-l2-o-sdd-plan-e-o-planner/30-handoff-qa.md` | este handoff; a evidência da jornada está no `gate:` |

Nenhuma spec e nenhum bug registrado, porque nenhum achado foi confirmado. O `docs/qa/` do kit não foi tocado.

## Boot da próxima fase

REVIEW, sobre `git diff origin/main...HEAD`. O que a QA viu e o revisor precisa saber:

- A suíte está verde **com** `EFFORT_*` exportado. As notas do I1 ao I6 falam em "2 FAIL de ambiente", mas isso é história, fechada pelo `d48f7c9`.
- A célula Check do I6 diz `→ 14` e o comando responde `15`. Não é defeito de produto: o I7 acrescentou o 15º `RESOLVED by` da branch. Uma célula `done` com o esperado envelhecido é o tipo de coisa que o revisor pode querer corrigir ou aceitar. A QA não mexeu nela.
- O que o usuário toca está todo em prosa (`commands/sdd-plan.md`, `agents/sdd-planner.md`, `templates/plano.md`, `docs/plan-only.md`) e nos dois modos novos do `--red`. Nenhuma linha de `bin/sdd` nem de `bin/sdd-worker` mudou.
- A QA não testou uma sessão real de `/sdd-plan` com o planner em `model: fable`, porque isso pede humano na sala (ver "Riscos").

## Pendências / Decisions for a Human

- Nenhuma.

## Riscos e não-feitos

- Não rodei um `/sdd-plan` interativo de verdade. Que o harness respeite o `model: fable` do frontmatter quando o relay delega, e que as frases novas mudem o comportamento do relay, só uma sessão com humano mede. As asserções provam o texto, não o comportamento do modelo.
- O caminho de "corrida viva antes do `--red`" (item 14) é uma frase do aceite, não uma recusa do sensor. Confirmei que o `pgrep` que ela cita acha um run vivo, mas o `--red` em si não recusa nada.

## Achados fora de escopo

- Nenhum.
