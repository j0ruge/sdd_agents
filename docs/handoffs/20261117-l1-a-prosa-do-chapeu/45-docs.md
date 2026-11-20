---
missao: 20261117-l1-a-prosa-do-chapeu
fase: DOCS
status: done
sessao: a0d226c2
data: 2026-11-19 21:35
gate: "docs em `36ede1c` (KAIZEN_LOG.md e a F6 da gaveta); `tests/check-todo.sh --check TODO.md` → `103 finding(s), all within 8 lines, carrying anchor + date, every anchor on target`; `bash tests/check-hat.sh` → 119 linhas ok; `tests/check-templates.sh` → 121 linhas ok"
---

# Handoff — DOCS — L1: a prosa do chapéu e dos docs

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

A missão é quase toda documentação: os docs que ela tocou (cinco chapéus, README, `failure-modes.md`,
`finding-prs.md`, as duas sementes do `TODO.md`, a ajuda do `sdd why`) foram consertados pelo EXEC, cada um
no commit do seu incremento, e não há deriva entre eles e o código. Esta fase escreveu a entrada do
`KAIZEN_LOG.md` (o `kaizen_log:` está vazio: a entrada é devida) e atualizou a linha F6 da gaveta do kit,
que dizia que o L1 ainda ia rodar, as duas em `36ede1c`. Uma linha `⛔`: a lição do teto da chamada `Bash`
voltou três vezes nesta missão, e o lugar de uma regra para toda fase é o `turn_rule` do `boot_prompt()` em
`bin/sdd`, fora do `writes:` desta fase e da decisão 1 da missão; o texto proposto está abaixo.
Nenhum item novo no `TODO.md`.

## Estado do repo

- **Branch:** `fix/l1-a-prosa-do-chapeu`, no worktree `/home/joruge/repos/sdd_agents-l1`, merge-base `cc8509a`
  com a `origin/main`; sem push nesta fase.
- **Último commit:** o deste `45-docs.md`, sobre `36ede1c` (os docs).
- **Working tree:** limpo depois do commit.
- **Suíte:** não rodada inteira nesta fase (o diff da fase é só `KAIZEN_LOG.md`, `docs/` e este handoff,
  nenhum lido por sensor de comportamento); a última verde é a da r2 (rc 0, 0 `FAIL`). O `gate_DOCS` não a
  roda.

## O que foi feito

- `36ede1c` — entrada nova no topo do `KAIZEN_LOG.md`: antes (14 itens sem sensor, 0 `RESOLVED by`) e
  depois (16 asserções, 14 `RESOLVED by`), a corrida do piloto lida do `pipeline.log` (13 sessões,
  US$ 17,82, nenhuma parada, 0 `DENIED`) e a lição reincidente do teto do `Bash`.
- `36ede1c` — a linha F6 de `docs/superpowers/specs/2026-09-23-a-gaveta-do-kit.md`: a delegação assinada, o
  L1 rodado, e o próximo passo (PR, merge e chore do L1, depois o lote seguinte). É a regra do `CLAUDE.md`:
  frente que anda atualiza o índice no mesmo commit.

## Drift checklist

| Área tocada pelo diff | Documento correspondente | Status | Evidência |
|---|---|---|---|
| `agents/sdd-planner.md` (itens A, B, C) | `agents/sdd-planner.md` | ✅ | o chapéu é o doc; frases em `2b01f33`, asserções em `tests/check-hat.sh` |
| `agents/sdd-executor.md` (itens D, E) | `agents/sdd-executor.md` | ✅ | frases em `abe5808` |
| `agents/sdd-reviewer.md` (itens F, G e o R1) | `agents/sdd-reviewer.md` | ✅ | frases em `b51657d` e `772540c` |
| `agents/sdd-docs.md` (item H) | `agents/sdd-docs.md` | ✅ | frase em `781fe39` |
| `agents/sdd-qa.md` (item I) | `agents/sdd-qa.md` | ✅ | frase em `40c836b` |
| `agents/sdd-qa.md` (o `qa: skipped` nos dois caminhos) | `docs/pipeline.md` | n/a | a seção "`qa: skipped`" descreve a rota do `qa_substep` e quem declara; o conserto muda só a frase do chapéu sobre o caminho sem interface, e nada no parágrafo do pipeline afirma o contrário |
| `.claude/agents/*.md` (os cinco espelhos) | — | n/a | cópia gerada por `sdd install --force`; `cmp -s` rc 0 nos cinco (métrica 4 da missão, conferida no I1 a I5 e no R1) |
| `README.md` (item J) | `README.md` | ✅ | o comentário `# PRIVATE repository` saiu em `596627b` |
| `bin/sdd`, `cmd_help` (item N) | `bin/sdd` | ✅ | a ajuda do `sdd why` é o doc; texto em `c02da26` |
| `bin/sdd`, `cmd_help` (item N) | `README.md` | n/a | a linha 84 (`sdd why … start any diagnosis here`) é índice de uso; o custo do comando mora na ajuda, que o README não repete para nenhum verbo |
| `bin/sdd`, `boot_prompt()` (a lição reincidente do teto do `Bash`) | `bin/sdd` | ⛔ | função `boot_prompt()`, variável `turn_rule`; texto proposto abaixo |
| `docs/failure-modes.md` (item K) | `docs/failure-modes.md` | ✅ | `[b]in/sdd run` e a espera pelo PID em `596627b` |
| `docs/finding-prs.md` (item L) | `docs/finding-prs.md` | ✅ | merge só com zero threads abertos no head, com o comando, em `596627b` |
| `templates/todo.md` e `templates/todo.pt-BR.md` (item M) | `templates/todo.md` | ✅ | as duas sementes em `bc8710f`; o `CLAUDE.md` (princípio 5) só roteia para o template e não muda |
| `TODO.md` (14 `RESOLVED by` e âncoras re-apontadas) | `TODO.md` | ✅ | `c27e8c7` e as âncoras de cada incremento; `--check` e `--anchors` → 103, 0 fora do alvo |
| `tests/check-hat.sh` e `tests/check-templates.sh` (16 asserções) | `CLAUDE.md` | n/a | nenhum sensor novo: a lista "Os dezessete" e o `ls tests/check-*.sh` continuam iguais |
| `.sdd/config.sh` (`EFFORT_EXEC`, `EFFORT_DOCS`) | `config/schema.md` | n/a | as chaves já estão documentadas (`EFFORT_EXEC`, linha 269 do schema); o diff só fixa o valor deste repo para o piloto |
| os chapéus (a prosa de cinco deles) | `.claude/rules/anatomia-do-agente.md` | n/a | nenhum componente mudou: o frontmatter (`disallowedTools:`, `writes:`, `mcp:`) está intacto e o `Monitor` segue vetado nos sete; a receita de espera do revisor é prosa do chapéu, não ferramenta |
| a missão inteira (antes e depois medidos, `kaizen_log:` vazio) | `KAIZEN_LOG.md` | ✅ | entrada `## 2026-11-19 — O L1, …` em `36ede1c`, citando `20261117-l1-a-prosa-do-chapeu` |
| a frente F6 (o piloto rodou) | `docs/superpowers/specs/2026-09-23-a-gaveta-do-kit.md` | ✅ | linha F6 em `36ede1c` |
| nenhum termo de domínio novo | `CONTEXT.md` | n/a | as frases novas usam termos que o glossário já tem (`RECURRED`, `DEFAULT_BRANCH`, `qa: skipped`) |
| `docs/handoffs/20261117-l1-a-prosa-do-chapeu/*` | — | n/a | artefatos da própria missão |

## Texto proposto
<!-- sdd:proposed -->

### `bin/sdd`

Em `bin/sdd`, função `boot_prompt()`, no fim do texto da variável `turn_rule` (depois de "What you started
for your own check, stop before you end the turn."), acrescente:

> A Bash call stops waiting at its own `timeout`: 120 000 ms by default, 600 000 ms at most, and past it the
> command moves to the background. A command that may pass 2 min goes in a call whose `timeout` parameter
> is raised to 600000; one that may pass 10 min (the whole `TEST_CMD`, a `sdd why` of EXEC, QA or REVIEW)
> runs detached as `( <command>; echo "rc=$?" ) > <file> 2>&1 &`, keeping its `$!` as `<pid>`, and the
> session waits on that file in the foreground with
> `timeout 590 bash -c 'until grep -q "^rc=" <file>; do sleep 5; done'` in a call with `timeout: 600000`.
> When that wait times out and `kill -0 <pid>` says the command is still alive, the session runs the same
> wait again, in this same turn; when it is gone and the file has no `rc=` line, the command died, and the
> session reports it as failed instead of waiting again.

Porquê: nesta missão o teto voltou três vezes (o item N, a suíte do executor no I6 e no I9, e o R1 da r1), e a
regra só existe hoje no chapéu do revisor (R1) e na ajuda do `sdd why` (item N). O `turn_rule` fala a toda
fase. Mudar o `boot_prompt()` pede a asserção no `tests/check-dry-run.sh` (que lê o prompt) no mesmo commit;
é trabalho de EXEC de outro lote, por isso fica como texto proposto e não como edição desta fase.

## Achados do `TODO_FILE` conferidos nesta missão

- **Nenhum item novo nesta missão.** O diff do `TODO.md` contra `cc8509a` tem só os 14 `RESOLVED by`
  (`c27e8c7`), as âncoras re-apontadas no commit que as moveu (I6 e I8) e quatro linhas requebradas para
  caber em 120 colunas e 8 linhas (I9). A QA e as r1 e r2 não registraram achado.
- **Os 14 itens resolvidos** (A a N da tabela do `00-missao.md`) seguem na seção `<!-- sdd:open -->` com o
  `RESOLVED by <hash>`, títulos byte a byte iguais: é o contrato. Quem os apaga é o chore de depois do merge,
  provado por `git merge-base --is-ancestor`.
- **Forma do arquivo:** `tests/check-todo.sh --check TODO.md` → `103 finding(s), all within 8 lines, carrying
  anchor + date, every anchor on target`. Nenhum item foi refutado nem decidido; nada foi para
  `<!-- sdd:decided -->`.
- **Não registrado como item, de propósito:** a lição do teto do `Bash` não ganha item (a catraca subiria, e o
  `tests/health-baseline.txt` está fora do `writes:` desta fase); ela tem rota pela linha `⛔` acima, que o
  PR leva ao dono.

## Boot da próxima fase

A PR lê, nesta ordem: o TL;DR deste arquivo, a tabela acima e o `## Texto proposto`. O corpo do PR tem de
nomear cada documento `⛔` numa linha com `⛔` (o `gate_PR` confere): `bin/sdd`, com o texto proposto para o
`turn_rule` do `boot_prompt()`. O corpo lista também as quatro escolhas da decisão 5 do `00-missao.md` (J, K,
E, H) para o aceite do dono, e o merge é por **merge commit**, nunca squash (os 14 hashes têm de chegar à
`main`). A parada conhecida do `gate_PR` do kit (rc 2 por falta do carimbo de mutação) lê-se "PR pronto
para revisão", pela regra do dono.

## Pendências / Decisions for a Human

- **Decidir a linha `⛔` de `bin/sdd`**: aplicar o texto proposto ao `turn_rule` num lote seguinte (com a
  asserção no `tests/check-dry-run.sh`) ou recusá-lo.
- **O chore de depois do merge** (pendência 4 do `00-missao.md`): apagar os 14 itens, descer `todo-findings`
  e sincronizar o espelho de issues.
- **A linha da missão no caderno de campo do worker**, com as colunas que só o humano tem; os números da
  corrida estão na entrada do `KAIZEN_LOG.md`.

## Riscos e não-feitos

- A suíte inteira não rodou nesta fase: o diff dela não toca nada que um sensor de comportamento lê. O
  carimbo de mutação não roda nesta missão (pendência 5 do `00-missao.md`).
- O custo da corrida conta só as sessões de fase do `pipeline.log` (13); o gasto da sessão orquestradora do
  worker fica fora, como a ADR 0022 declara, e esta sessão de DOCS ainda não tem linha no log.
- O texto proposto é prosa que nenhum gate julga; quem o aplica o julga.
- Não existe `CHANGELOG.md` neste repo; nada a atualizar ali.

## Achados fora de escopo

- Nenhum novo. A reincidência medida desta missão foi para a linha `⛔` (acima).
