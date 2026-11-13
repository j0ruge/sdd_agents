---
missao: 20261112-as-reincidentes-primeiro
atualizado: 2026-11-12 21:27
---

# Checkpoint — as reincidentes primeiro (lote 1 de zerar a catraca)

> **Este arquivo é lido por máquina.** O runner faz parse da tabela abaixo para decidir a
> próxima fase. Não mude as colunas, não mude os tokens de status, não quebre linhas dentro de
> uma célula. Detalhe narrativo vai no `01-plano.md`, não aqui.
>
> ⚠️ **Nada de `|` cru na célula do Check**, e a célula Commit leva o hash curto **nu**, sem crase.
> Check que lê sensor ancora em `^  ok    ` (quatro espaços, com o `^`). Quem cobra é
> `tests/check-checkpoint.sh --check <este arquivo>`.
>
> Atualizar o checkpoint é o **último ato** de cada incremento — depois do commit, nunca antes.
> Status válidos: `pending` · `doing` · `done` · `blocked`.

| ID | Incremento | Check (comando → esperado) | Status | Commit |
|---|---|---|---|---|
| I1 | A: o /sdd-plan nomeia a saída quando o agente sdd-planner não está registrado | `o=$(bash tests/check-hat.sh 2>&1); grep -c '^  ok    command: /sdd-plan names the way out when the sdd-planner agent type is not registered' <<< "$o"` → `1` | done | 60042c9 |
| I2 | B: pergunta nenhuma fica atrás de tarefa viva em segundo plano | `o=$(bash tests/check-hat.sh 2>&1); grep -c '^  ok    command: /sdd-plan and the planner leave no question behind a live background task' <<< "$o"` → `1` | done | 01a20ae |
| I3 | D: o planner pode usar o Monitor e espera a tarefa viva com ele | `o=$(bash tests/check-hat.sh 2>&1); grep -c '^  ok    hat: the planner may use Monitor, and waits on a live task with it' <<< "$o"` → `1` | done | 6841138 |
| I4 | M: o planner chama as skills grilling e domain-modeling | `o=$(bash tests/check-hat.sh 2>&1); grep -c '^  ok    hat: the planner invokes the grilling and domain-modeling skills, which the model can call' <<< "$o"` → `1` | done | 4fb7109 |
| I5 | K: o /sdd-plan diz o que fazer com a aprovação dada antes do plano | `o=$(bash tests/check-hat.sh 2>&1); grep -c '^  ok    command: /sdd-plan says what an approval given before the plan still shows, and what stops it' <<< "$o"` → `1` | done | 11556b3 |
| I6 | L: a fila de PRs de achado ganha receita em docs/finding-prs.md | `o=$(bash tests/check-hat.sh 2>&1); grep -c '^  ok    doc: the queue of finding PRs has its recipe, and the TODO header points at it' <<< "$o"` → `1` | done | 92f87fc |
| I7 | J: o corpo do PR só promete CI onde há workflow | `a=$(bash tests/check-templates.sh 2>&1); b=$(bash tests/check-hat.sh 2>&1); echo "$(grep -c '^  ok    pr-body.md: the new-sensors line promises CI only as one of two fill-ins' <<< "$a") $(grep -c '^  ok    hat: the publisher claims CI only with a workflow on disk, and names TEST_CMD otherwise' <<< "$b")"` → `1 1` | done | 21f2278 |
| I8 | C: o check-todo.sh recusa o #N solto que nomeia um item | `o=$(bash tests/check-todo.sh 2>&1); grep -c '^  ok    rule: a bare #N that names an item is refused in a file that numbers its items' <<< "$o"` → `1` | done | 5cde830 |
| I9 | E: --help depois do subcomando só imprime a ajuda | `o=$(bash tests/check-preflight.sh 2>&1); echo "$(grep -c '^  ok    install --help prints the help and writes nothing' <<< "$o") $(grep -c '^  ok    link-agents --help prints the help and links nothing' <<< "$o")"` → `1 1` | done | c40c25a |
| I10 | F: o install não adota a branch de trabalho como base | `o=$(bash tests/check-preflight.sh 2>&1); grep -c '^  ok    install without origin/HEAD asks the remote, then an existing origin/main or origin/master, and calls the current branch a guess' <<< "$o"` → `1` | done | f93ed48 |
| I11 | G: o sdd approve aceita o ADR que commita | `o=$(bash tests/check-gates.sh 2>&1); grep -c '^  ok    sdd approve turns the proposed ADR that adr: names into accepted, in the approval commit' <<< "$o"` → `1` | done | 5e8da5e |
| I12 | I: o sdd status fala antes de rodar o TEST_CMD | `o=$(bash tests/check-gates.sh 2>&1); grep -c '^  ok    sdd status names the TEST_CMD before the gate that runs it, and a missing mission is told about --no-gates' <<< "$o"` → `1` | done | 39a3bac |
| I13 | H1: o sdd status mostra o stream órfão e a árvore suja | `o=$(bash tests/check-gates.sh 2>&1); grep -c '^  ok    sdd status names a stream no journal line closed and the paths left dirty, on both faces' <<< "$o"` → `1` | done | 1022cc8 |
| I14 | H2: o boot da fase cita a sobra da sessão morta | `o=$(bash tests/check-dry-run.sh 2>&1); grep -c '^  ok    the boot prompt names the orphan stream and the dirty tree a dead session left' <<< "$o"` → `1` | done | 59b5f96 |
| I15 | Fecho: RESOLVED by nos 13 itens, KAIZEN_LOG e 20-handoff-exec.md | `grep -cE 'RESOLVED by [0-9a-f]{7,40}' TODO.md` → `13` | done | 0985ff5 |
| R1 | Revisão final: sujeira sozinha não é sessão morta, e o boot devolve à fase o que é dela | `o=$(bash tests/check-dry-run.sh 2>&1); grep -c '^  ok    a dirty tree alone is told it was not clean, never that a session died' <<< "$o"` → `1` | done | 215fd54 |
| R2 | Revisão do PR #391 (CodeRabbit): o sdd approve não reescreve ADR fora do checkout | `o=$(bash tests/check-gates.sh 2>&1); grep -c '^  ok    sdd approve leaves an ADR that resolves outside the checkout as it is, says so, and commits the mission without it' <<< "$o"` → `1` | done | 820787e |
| R3 | Revisão do PR #391 (CodeRabbit e Codex): o --help vem antes da admissão do checkout | `a=$(bash tests/check-preflight.sh 2>&1); b=$(bash tests/check-gates.sh 2>&1); echo "$(grep -c '^  ok    --help prints the help outside a repository, for every subcommand whose admission resolves the root' <<< "$a") $(grep -c '^  ok    sdd run --help prints the usage while a live owner holds the checkout, never CHECKOUT-BUSY' <<< "$b")"` → `1 1` | done | 820787e |
| R4 | Revisão do PR #391 (CodeRabbit): sem workflow, o corpo do PR não afirma que não há CI | `o=$(bash tests/check-templates.sh 2>&1); grep -c '^  ok    pr-body.md: the new-sensors line promises CI only as one of two fill-ins, and never claims there is no CI' <<< "$o"` → `1` | done | 5ee401c |
| R5 | Codereview do branch: o lint do branch volta ao da base, e a volta do stub tem testemunha | `o=$(bash tests/check-dry-run.sh 2>&1); echo "$(grep -c '^  ok    the journal writes LEFTOVER before the session opened over a dead session' <<< "$o") $(grep -c 'lap-rc:0 sessions:1' tests/check-dry-run.sh)"` → `1 1` | done | 185919c |
| R6 | Codereview do branch: o stream da sessão morta se aposenta quando uma sessão posterior fecha | `o=$(bash tests/check-dry-run.sh 2>&1); grep -c '^  ok    a session that closed after the dead one retires its stream, and the dirt left is still told' <<< "$o"` → `1` | done | 3636961 |
| R7 | Codereview do branch: o executor lê a sobra de uma sessão anterior antes do TEST_CMD | `o=$(bash tests/check-hat.sh 2>&1); grep -c '^  ok    hat: the executor reads what an earlier session left before TEST_CMD' <<< "$o"` → `1` | done | 2e4b0b3 |
| R8 | Codereview do branch: os registros (KAIZEN_LOG, README, TODO.md) e o achado do lint, catraca 88 | `o=$(bash tests/check-todo.sh 2>&1); echo "$(grep -c '^  ok    88 finding(s), all within 8 lines' <<< "$o") $(grep -c '^todo-findings 88$' tests/health-baseline.txt) $(grep -c 'docs/finding-prs.md' README.md)"` → `1 1 1` | done | 3c0f2d8 |
| R9 | Re-revisão do PR #391 (CodeRabbit): o executor só põe de volta o mutante que o .bak confirma, e deixa o resto onde está | `o=$(bash tests/check-hat.sh 2>&1); grep -c '^  ok    hat: the executor puts back only a mutant its .bak confirms' <<< "$o"` → `1` | done | 3f3a57c |

> **As notas de execução não moram aqui.** Elas ficam em `checkpoint-notas.md`, ao lado deste
> arquivo, append-only.

## Incrementos de fix (QA e REVIEW)

> Esta missão não passa pela QA nem pela REVIEW do runner (decisão 5 do `00-missao.md`). Conserto
> pedido pela revisão do PR entra na tabela acima como `R<n>`, com Check próprio, pela mesma regra.
