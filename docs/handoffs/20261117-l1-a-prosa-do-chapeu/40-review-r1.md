---
missao: 20261117-l1-a-prosa-do-chapeu
fase: REVIEW
rodada: 1
status: done
sessao: a49db9b3-b7c5-424a-8526-ebb9b9c9cd17
data: 2026-11-19 20:34
gate: tests/run-all.sh rc 0 em 8d245aa (20:18 → 20:34, 16 min), "suite green", 0 linhas ^  FAIL, 904 mutantes aplicáveis; árvore limpa ao abrir; esta rodada commita só o 40-review-r1.md, o checkpoint.md e uma linha do checkpoint-notas.md
---

# Review — rodada r1 — L1: a prosa do chapéu e dos docs

## TL;DR

Revisado o diff `ce96b6c..8d245aa`: 5 chapéus, 3 docs do operador, 2 sementes do `TODO.md`, a ajuda do
`sdd why` e as 15 asserções novas. Um achado MEDIUM, reproduzido: a receita de espera do item F, rodada
como está escrita, cai no prazo padrão de 120 s do Bash e vai para segundo plano, que é a armadilha que
ela existe para evitar. Virou `R1`. Nada refutado, nada para o `TODO.md`, nenhuma pendência humana.
Nota: B em Code Quality, o resto A.

## Nota da rodada

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | B | A receita de espera do item F não funciona como escrita: sem o parâmetro timeout da chamada Bash, o laço é movido para segundo plano aos 120 s (achado #1, reproduzido). |
| Type Safety | A | n/a: bash e markdown, sem tipos; shellcheck -S warning limpo nos dois sensores tocados. |
| Error Handling | A | As sondas novas usam herestring e captura guardada (o sdd help sai com or-true); nenhum pipe para grep -q sob pipefail. |
| Security | A | Pré-varredura de segredos (regex + gitleaks) limpa em 484 linhas acrescentadas; o README só perde o rótulo PRIVATE. |
| Performance | A | 15 asserções por awk/grep sobre arquivos pequenos e uma chamada do sdd help; nenhum custo mensurável na suíte. |
| Test Coverage | A | 15 asserções, uma por item e duas para o M, cada uma lida por seção e com a frase antiga recusada onde havia; Red registrado no checkpoint-notas.md. |
| Documentation | A | A ajuda do sdd why confere com o cmd_why e os gates (TEST_CMD em EXEC/QA/REVIEW, E2E_CMD na QA); a consulta de threads roda contra o PR 391 e responde. |
| **Overall** | **B** | Um MEDIUM funcional na entrega do item F; o resto da missão está correto e medido. |

## Achados da rodada

| # | Severidade | Achado | Onde |
|---|---|---|---|
| 1 | MEDIUM | A receita nova do revisor diz "under a ceiling below the 10 min of a Bash call", mas 10 min é o **teto** da chamada Bash, não o padrão: sem `timeout: 600000` na chamada, o padrão é 120 000 ms, e o `timeout 590 bash -c 'until …'` é movido para segundo plano aos 120 s ("Command did not complete within its 120s timeout and was moved to the background"). É exatamente a resposta "running in background" que o parágrafo de cima chama de morte da sessão. Reproduzido nesta rodada às 20:19:45, esperando a própria suíte com a receita literal; refeito com `timeout: 600000`, o laço segurou 590 s em primeiro plano e saiu rc 124, e a segunda volta leu `rc=0`. | `agents/sdd-reviewer.md:153` |

## Incrementos de conserto (R<n>)

| R<n> | Achado | Check escrito no checkpoint |
|---|---|---|
| R1 | Achado #1: a receita de espera do revisor manda subir o timeout da própria chamada Bash para 600000 ms | `o=$(bash tests/check-hat.sh 2>&1); cmp -s agents/sdd-reviewer.md .claude/agents/sdd-reviewer.md; c=$?; echo "$(grep -c '^  ok    hat: the reviewer runs the wait loop in a Bash call whose own timeout is raised to 600000 ms' <<< "$o") $c"` → `1 0` |

## O que virou incremento

- Achado #1 — virou `R1` — a seção "Two ways this session dies" do `agents/sdd-reviewer.md` diz que a
  chamada Bash do laço leva o parâmetro `timeout` em 600000 ms (o padrão de 120 s a manda para segundo
  plano), a asserção nova do `tests/check-hat.sh` lê isso na seção e fica `ok`, e o espelho em
  `.claude/agents/` é igual (`./bin/sdd install --force`).

## O que foi refutado

- Hipótese: o laço `until grep -q "^rc="` pararia cedo se a saída da suíte tivesse uma linha começando
  com `rc=`. Refutada nesta suíte: `grep -c '^rc='` na saída parcial deu 0, e os três `printf 'rc=…'`
  dos sensores (`check-health.sh:2224`, `check-autonomy.sh:5774`, `check-gates.sh:4457`) vão para
  capturas internas; a saída completa terminou com uma única linha `rc=0`, a que o laço escreveu.
- Hipótese: a ajuda nova do `sdd why` exagera, e `DOCS`/`PR` também rodariam a suíte. Refutada: o
  `cmd_why` chama só `gate_$ph`, e `run_check_cmd` aparece só em `gate_EXEC`, `gate_QA` (TEST_CMD e
  E2E_CMD) e `gate_REVIEW`; sem PHASE ele deriva pelo `current_phase`, como a ajuda diz.

## Achados fora de escopo

Nenhum.

## Pendências / Decisions for a Human

Nenhuma.
