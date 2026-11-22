---
missao: 20261121-l4-preflight-health-e-sensores
fase: REVIEW
rodada: 3
status: done
sessao: worker-r3
data: 2026-11-22 09:31
gate: "tests/run-all.sh em e0b17e5 → rc 0 (09:12 → 09:28), 'suite green', 0 linhas '^  FAIL', 2336 linhas '^  ok    ', 'anchors: all 986 mutants still apply and leave valid code'; sdd review-base → full (o merge 84cdd5a entrou depois da r2), rodada inteira; árvore limpa (git status --short vazio) antes do commit da rodada"
reviewed_head: e0b17e57cfa08c3d255a35f736dbc1c212a548a6
---

# Review — rodada r3 — L4: preflight, health e sensores

## TL;DR

Rodada inteira (`base=52ab245`, 42 arquivos) com o foco no que ninguém revisou depois da r2: os docs vivos
(`8a36baa`), o `45-docs.md`, o merge `67d69db` do `TODO.md` e da gaveta, o merge limpo `84cdd5a` e o texto
`⛔` aplicado à rule (`e0b17e5`). Nenhum CRITICAL, HIGH nem MEDIUM. Três LOW de prosa, todos para o lote
de prosa, nenhum `R<n>`. Os seis LOW da r1 (#7–#12) e o LOW da r2 seguem como limite declarado. Nota A,
salvo `Documentation` em B por uma definição velha do `CONTEXT.md`.
A skill `/codereview:codereview` não rodou com os agentes por arquivo: o código do `bin/sdd` que a r1 e a r2
leram até `74d35db` não foi relido linha a linha, só o `phase_skills_check` e as três portas dele.

## Nota da rodada

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | A | O `phase_skills_check` é uma definição para o preflight, o `run` e o `retry`, o `die` está no shell de quem chama (nunca em `$( )`) e `unset -f _skill_stop` não deixa a função nested vazar. |
| Type Safety | A | Em bash não há tipos; `bash -n bin/sdd` e `shellcheck -S warning bin/sdd tests/*.sh` saem limpos neste head. |
| Error Handling | A | A parada do lançamento só dispara em `broken` e `uncovered` sob `run` sem `--dry-run`, e `missing` e `unreachable` ficam aviso nas duas vozes, como o cabeçalho diz. |
| Security | A | Os dois merges só trazem prosa e catraca, o `readlink -f` do `phase_skills_check` tem fallback e nada novo alarga permissão de leitura ou escrita. |
| Performance | A | O `phase_skills_check` roda uma vez por lançamento, antes de gate e sessão, e não repete a busca do preflight dentro do laço de fases. |
| Test Coverage | A | `check-mutation.sh --anchors` diz que os 986 mutantes ainda se aplicam (contra 954 no merge-base) e os sensores de prosa (`check-todo.sh --check` e `--anchors`: 86, 0 fora do alvo; `check-lang.sh`, `check-adr.sh`, `check-templates.sh`) passam. |
| Documentation | B | O texto `⛔` da rule bate com o "Texto proposto" e os números do `KAIZEN_LOG.md` e do censo conferem pelo comando, mas o `CONTEXT.md:19` ainda diz "em quatro sítios" para a `hat_crossed_escalation` (são seis) e a linha F6 da gaveta diz "PR a abrir" com o #464 aberto. |
| **Overall** | **A** | Nenhum achado de comportamento, e os três LOW são prosa que o `TODO_FILE` ou o chore de pós-merge recolhem. |

## Achados da rodada

| # | Severidade | Achado | Onde |
|---|---|---|---|
| 1 | LOW | O verbete "Fronteira do chapéu" do `CONTEXT.md` diz que a `hat_crossed_escalation` tem "quatro sítios". A missão a levou a seis (`grep -nE 'if hat_crossed_escalation "\$phase"; then return 3' bin/sdd` acha as portas em 10811, 10925, 11135, 12943, 12969 e 13670), e a rule, o `CLAUDE.md` e o `pipeline.md` já dizem seis. O `45-docs.md` marcou o `CONTEXT.md` como n/a, mas a linha é verbete de domínio e o número mudou. Prosa: vai para o lote de prosa. | `CONTEXT.md:19` |
| 2 | LOW | A linha F6 da gaveta, escrita na DOCS, termina o L4 em "PR a abrir"; o PR #464 está aberto (`gh pr view 464` → `OPEN`, head `fba3aed`). O chore de pós-merge reescreve a linha de qualquer modo. | `docs/superpowers/specs/2026-09-23-a-gaveta-do-kit.md:21` |
| 3 | LOW | O comentário do `kit_guard` diz que o `kit-touched` para a linha "through hat_crossed_escalation's four doors". A porta tem seis, embora o `kit_guard_check` continue com quatro (`grep -cE '^ *kit_guard_check "' bin/sdd` → 4), então a frase mistura as duas contagens. Só comentário. | `bin/sdd:4585` |

Carregados das rodadas anteriores, sem mudança, e não contados de novo: r1 #7 a #12 e o LOW da r2 (o
`hat_guard_check` da porta do retry do `cmd_kaizen` sem mutante próprio, que o `check-kaizen.sh` pega).

## Incrementos de conserto (R<n>)

Nenhum nesta rodada. Os três achados são LOW de prosa e, pela régua do dono, vão listados para um lote só.

## O que virou incremento

Nada nesta rodada. Os achados da rodada anterior seguem assim:

- r2 #1 (mutante da porta do retry do `cmd_kaizen`): limite medido, sem `R<n>`, sem mudança nesta rodada.
- r1 #7 a #12: limite declarado, sem mudança.

## O que foi refutado

- Hipótese: o texto `⛔` aplicado em `e0b17e5` difere do "Texto proposto" do `45-docs.md`. Refutada: os
  quatro trechos (§2, §4, §6, §7) estão na rule com as mesmas frases, e o `git show e0b17e5` só acrescenta
  essas linhas.
- Hipótese: o merge `67d69db` perdeu itens do `TODO.md` de um dos lados. Refutada: os 29 títulos de item da
  `origin/main` (`52ab245`) estão no head, sem sobra nem falta; o diff restante é `RESOLVED by` e âncora
  deslocada, e `check-todo.sh --check` dá `86 finding(s)` e `--anchors` `86 measured, 0 off target`, igual
  ao `todo-findings 86` da catraca.
- Hipótese: os números novos do `KAIZEN_LOG.md` estão inventados. Refutada, um a um: `grep -c '^mut_'` →
  954 em `86e16c0` e 986 no head; a EXEC do L3 tem 10 sessões, US$ 27,32 e 30 819 s, a do L4 14, US$ 34,51 e
  28 733 s (`jq` no `~/.sdd/autonomy-log.jsonl`); até a REVIEW r2 são 17 sessões e US$ 41,97; a razão da
  rodada delta é 1,625/4,586 = 0,35 (0,39 no L3).
- Hipótese: o censo do `CLAUDE.md` (15 portas, 17 com comentário) está errado. Refutada:
  `grep -cE '^ +if [a-z_]+_escalation "\$phase"; then' bin/sdd` → 15 e `grep -cF 'escalation "$phase"'` → 17.
- Hipótese: o `sdd-kaizen.md` espelhado difere do chapéu. Refutada: `cmp .claude/agents/sdd-kaizen.md
  agents/sdd-kaizen.md` → rc 0.

## Achados fora de escopo

Nenhum vai para o `TODO.md`. Os três LOW são prosa, sem fail-open nem consumidor fora da suíte (D15), e o
#1 e o #2 cabem no mesmo commit do chore de pós-merge.

## Pendências / Decisions for a Human

Nenhuma.
