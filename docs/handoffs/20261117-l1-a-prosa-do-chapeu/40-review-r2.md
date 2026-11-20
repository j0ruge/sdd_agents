---
missao: 20261117-l1-a-prosa-do-chapeu
fase: REVIEW
rodada: 2
status: done
sessao: 5a93a774-db3c-4d96-b59e-70922b4a699b
data: 2026-11-19 21:16
gate: tests/run-all.sh rc 0 em 3f7ad8c, "suite green", 0 linhas ^  FAIL, 2182 linhas ^  ok, 904 mutantes aplicáveis; Check do R1 → 1 0; árvore limpa ao abrir; esta rodada commita só o 40-review-r2.md e uma linha do checkpoint-notas.md
---

# Review — rodada r2 — L1: a prosa do chapéu e dos docs

## TL;DR

Rodada delta sobre `517eeac..3f7ad8c`: o `R1` (`772540c`) no chapéu do revisor e no espelho, a asserção
nova do `tests/check-hat.sh`, o handoff de EXEC e o checkpoint. O conserto fecha o achado #1 da r1, e a
asserção nova fica vermelha quando o parágrafo é apagado numa cópia. Zero achados, nenhum `R<n>` novo,
nada para o `TODO.md`, nenhuma pendência humana. Nota: A em todo critério (r1: B em Code Quality).

## Nota da rodada

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | A | O R1 (772540c) manda subir o timeout da chamada Bash para 600000 ms e repetir o laço com o mesmo parâmetro; a receita, rodada nesta sessão assim, leu o rc=0 em primeiro plano. |
| Type Safety | A | n/a: bash e markdown; shellcheck -S warning limpo no tests/check-hat.sh. |
| Error Handling | A | A asserção nova lê a seção por herestring, sem pipe para grep -q sob pipefail, e tem frase de fail própria. |
| Security | A | Pré-varredura de segredos (regex + gitleaks) limpa nas 39 linhas acrescentadas. |
| Performance | A | Dois grep -F sobre uma seção já extraída; a suíte segue verde no mesmo prazo. |
| Test Coverage | A | Asserção nova com Red registrado no checkpoint-notas.md e sabotagem medida nesta rodada: sem o parágrafo, ela falha. |
| Documentation | A | Os números do parágrafo conferem com a ferramenta Bash (padrão 120000 ms, teto 600000 ms); o espelho é igual à fonte (cmp rc 0). |
| **Overall** | **A** | O único achado da r1 fechou com commit do executor e sensor vivo; o delta não traz achado novo. |

## Achados da rodada

Nenhum. O delta tem 6 arquivos e 39 linhas acrescentadas; o único arquivo de código
(`tests/check-hat.sh`, +7) foi revisado na própria sessão, sem agentes por arquivo.

## Incrementos de conserto (R<n>)

Nenhum incremento novo nesta rodada.

## O que virou incremento

- Achado #1 da r1 (MEDIUM: a receita de espera ia para segundo plano aos 120 s) — fechado em `772540c`
  pelo `sdd-executor`. Como se prova:
  - Check do `R1` rodado nesta rodada: `1 0` (a asserção `hat: the reviewer runs the wait loop in a Bash
    call whose own timeout is raised to 600000 ms` em `ok` e o espelho igual à fonte).
  - Sabotagem numa cópia em `mktemp -d`: com o parágrafo novo trocado pela frase antiga, a lógica da
    asserção (`awk` da seção + os dois `grep -F`) respondeu `FAIL`; com o arquivo íntegro, `ok`.
  - Uso real: esta rodada esperou a suíte com o laço `timeout 590` numa chamada Bash de
    `timeout: 600000`. A espera passou dos 120 s sem ir para segundo plano e leu `rc=0`.

## O que foi refutado

Nada.

## Achados fora de escopo

Nenhum.

## Pendências / Decisions for a Human

Nenhuma.
