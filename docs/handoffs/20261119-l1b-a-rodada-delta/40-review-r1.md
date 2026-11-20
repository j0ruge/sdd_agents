---
missao: 20261119-l1b-a-rodada-delta
fase: REVIEW
rodada: 1
status: done
sessao: 2bc8c92e-82fc-4787-9bd7-92a6830416a3
data: 2026-11-20 12:19
gate: "tests/run-all.sh rc=0 (suite green, 2203 linhas ok, 0 FAIL) sobre a6f1817; árvore limpa antes do commit da rodada; scan de segredos 0 achados (regex + gitleaks, 18 arquivos); sdd review-base da missão → full — no earlier round"
reviewed_head: a6f1817c1f90ffea8a9edcf28148ba72b05c315f
---

# Review — rodada r1 — L1b: a rodada delta

## TL;DR

Rodada **inteira** (a primeira; o prompt veio do runner do PATH, sem linha de delta), sobre
`334e0d0..a6f1817`: 18 arquivos, 532 linhas. Um achado MEDIUM reproduzido: o `review_head_ok` lê o
**último** commit que tocou a rodada, não o que a criou, e uma fase posterior que edite o arquivo da
rodada junto com código reprova o `gate_REVIEW` já verde. Virou o `R1`. Dois LOW sem rota (abaixo).
Nota: B em Error Handling; o resto A.

## Nota da rodada

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | A | Uma definição do juízo (`review_base_line`) lida pelo verbo e pelo prompt; código novo no fim do `bin/sdd`, sem deslocar âncoras; `shellcheck -S warning` limpo. |
| Type Safety | A | Bash com toda captura guardada (o `or true` e o `if !` de sempre), sha validado por regex e por `rev-parse --verify ^{commit}` antes de qualquer uso. |
| Error Handling | B | O `review_head_ok` toma como "commit da rodada" o último commit que tocou o arquivo (`git log -1`), e um commit posterior que edite a rodada e código fora do `writes:` do revisor reprova o gate verde — reproduzido, vira R1. |
| Security | A | Scan de segredos limpo (regex + gitleaks); nenhum valor do frontmatter chega a um comando sem passar pela regex hex. |
| Performance | A | Os cinco testes de git rodam antes do `TEST_CMD` no gate, e o verbo não roda gate nem suíte. |
| Test Coverage | A | Cinco mundos do verbo, cinco do gate, um do prompt delta, um do prompt inteiro e dez mutantes provados por `--only`; o mundo que falta é o do R1. |
| Documentation | A | `docs/pipeline.md`, o chapéu (espelho idêntico), o `commands/sdd-worker.md` e a ADR 0023 (accepted) dizem o mesmo contrato; só o handoff de EXEC erra uma frase sobre o lock (LOW #3). |
| **Overall** | **B** | Mecanismo correto nos mundos que a ADR nomeia; um caminho fail-closed reproduzido no gate, barato de fechar. |

## Achados da rodada

| # | Severidade | Achado | Onde |
|---|---|---|---|
| 1 | MEDIUM | `review_head_ok` usa `git log -1 --format=%H -- "$round"` como o commit da rodada: é o último que tocou o arquivo. O chapéu `sdd-docs` tem `writes:` sobre `$HANDOFF_DIR/$MISSION/**` e sobre `README.md`, `docs/**` etc.; um commit de DOCS que corrija o `40-review-rN.md` e um doc no mesmo diff faz `git diff <reviewed_head> <esse commit>` listar o doc, fora do `hat_writes REVIEW`, e o `gate_REVIEW` (reavaliado pelo `current_phase` em toda derivação) reprova a rodada já verde, devolvendo a missão à REVIEW por uma rodada nova inteira. Reproduzido num repo descartável: `last-touch: b8cae1c`, `added-by: 7b623d8`; o diff até o primeiro lista `README.md`, até o segundo só a rodada. O comentário da função e a ADR dizem "o commit da rodada", que é o que a adicionou (`--diff-filter=A`). | `bin/sdd` (`review_head_ok`, linha do `rc_commit`) |
| 2 | LOW | A resolução do sha (regex hex + `rev-parse -q --verify ^{commit}`) e o teste de ancestralidade estão escritos duas vezes, em `review_base_line` e em `review_head_ok`. | `bin/sdd` (as duas funções) |
| 3 | LOW | O `20-handoff-exec.md` diz que o `sdd review-base` "pega o lock do checkout"; o código e o comentário do `cmd_review_base` dizem o contrário (o braço `*)` do `coordination_enter` o admite sem lock), e o `check-coordination.sh` asserta `query stays available: review-base …`. | `docs/handoffs/20261119-l1b-a-rodada-delta/20-handoff-exec.md` (seção "O que foi feito", I1) |

## Incrementos de conserto (R<n>)

| R<n> | Achado | Check escrito no checkpoint |
|---|---|---|
| R1 | achado #1 da r1 | `o=$(bash tests/check-gates.sh 2>&1); grep -c '^  ok    gate_REVIEW: reviewed_head reads the commit that added the round, not a later one that touched it' <<< "$o"` → `1` |

## O que virou incremento

- Achado #1 — virou `R1` — o Check exige uma asserção nova no `tests/check-gates.sh`: uma rodada
  com `reviewed_head:` certo, commitada, e depois um commit que toca a rodada **e** um arquivo fora
  do `writes:` do revisor; o gate continua passando (`assert_phase … DOCS`). O conserto esperado é o
  `rc_commit` sair do commit que adicionou a rodada (`git log --diff-filter=A -1 --format=%H`), e o
  mundo "código entre o `reviewed_head` e a rodada" (já asserido) segue vermelho. Um mutante novo que
  volte ao `git log -1` tem de morrer contra o `check-gates.sh`.

## O que foi refutado

- **Achado #2 não virou incremento**, por custo e não por desacordo: as duas cópias diferem no que
  fazem com a recusa (uma imprime `full — …` para o prompt, a outra publica `GATE_WHY` para o gate),
  e unificar mexe nas âncoras de nove mutantes (`mut_RUN_review_base_*`, `mut_REVIEW_head_*`) para
  ganhar cinco linhas. Sem consumidor fora da suíte e sem fail-open, pela régua D15 não é achado de
  backlog; fica registrado aqui.
- **Achado #3 não virou incremento**: é prosa de um handoff de fase fechada, que nenhum gate nem
  sessão futura lê como contrato (o contrato vivo — comentário do código, `docs/pipeline.md`
  "without running a gate or the suite" — está certo). Pela tabela do chapéu, prosa só iria ao
  `TODO_FILE`, e um item para corrigir uma frase de handoff histórico não tem consumidor (D15).
- **"O rebase faz a REVIEW já verde reprovar" (mundo `not an ancestor`)** — não é defeito: é a
  decisão 4/10 da missão, escrita na ADR 0023, e o prazo dela é uma rodada nova, que grava o head
  novo. O caminho foi conferido por probe (`gate_REVIEW: reviewed_head the HEAD does not carry is
  refused`, commit órfão), que é o ponto que a QA deixou para esta rodada olhar.
- **"Um merge da `main` depois da rodada verde reprova o gate"** — refutado: o `rc_commit` é anterior
  ao merge e o `reviewed_head` segue ancestral; o merge só torna inteira a rodada **seguinte**
  (`review_base_line`, regra 5), como a decisão 5 manda.

## Achados fora de escopo

- Nenhum novo. A ordem do ato `review` do worker (merge da base antes de cada rodada, o que torna a
  rodada inteira sempre que a `main` andou) já está declarada fora de escopo no `00-missao.md`.

## Pendências / Decisions for a Human

Nenhuma.
