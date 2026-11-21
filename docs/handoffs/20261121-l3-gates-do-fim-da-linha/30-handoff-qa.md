---
missao: 20261121-l3-gates-do-fim-da-linha
fase: QA
status: done
sessao: b4759780-c2f6-4017-90da-d087a468d5ad
data: 2026-11-21 12:08
gate: "Jornada de terminal (o kit não tem interface; E2E_CMD e APP_URL vazios), em b94ba77, pelo ./bin/sdd do worktree, sobre a missão mergeada 20261120-l2-o-sdd-plan-e-o-planner: `./bin/sdd why 20261120-l2-o-sdd-plan-e-o-planner DOCS` → `DOCS: drift checklist complete`, rc 0; `./bin/sdd why 20261120-l2-o-sdd-plan-e-o-planner PR` → `PR: no green mutation catalogue for this content — run 'sdd health' …`, rc 0, sem `is at`, `verified_head` nem `kit:` no motivo (PR #456 MERGED não é relido); `./bin/sdd review-base 20261120-l2-o-sdd-plan-e-o-planner` → `full — merge e422f8f entered after 40-review-r5.md`, rc 0. TEST_CMD `tests/run-all.sh` em b94ba77 → rc 0, `suite green`, `grep -cE '^  FAIL'` → 0, `anchors: all 942 mutants still apply and leave valid code`. `grep -cE` dos 16 mutantes do plano em tests/check-mutation.sh → 16; `cmp -s` de agents/sdd-publisher.md e agents/sdd-reviewer.md com .claude/agents/ → 0 e 0."
---

# Handoff — QA — L3: gates do fim da linha

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

Uma jornada percorrida no terminal (três comandos sobre a missão mergeada do L2), zero achados,
portanto zero specs e zero incrementos de conserto, nada para o humano. O lote não reabre missão
fechada: DOCS segue `complete`, o PR `MERGED` não tem head nem corpo relidos, e o `review-base`
responde rc 0. Suíte inteira verde em `b94ba77`. A REVIEW pode começar.

## Estado do repo

- **Branch:** `fix/l3-gates-do-fim-da-linha`, local (o push é da fase PR)
- **Último commit antes deste handoff:** `b94ba77` `chore(checkpoint): I9 done em e8d7f4b (a célula)`
- **Working tree:** limpo antes deste handoff
- **Suíte:** `tests/run-all.sh` → verde, rc 0, 0 `FAIL`, uns 16 min
- **E2E:** não se aplica: `E2E_CMD` vazio, o kit não tem navegador; a jornada é de terminal (`gate:`)

## O que foi feito

- (este commit): jornada de terminal do passo 5 do § Verificação end-to-end do `01-plano.md`, e os
  passos 1, 3 e 4 refeitos em `b94ba77` (saídas no `gate:`)

## Artefatos

| Arquivo | O que contém |
|---|---|
| `docs/handoffs/20261121-l3-gates-do-fim-da-linha/30-handoff-qa.md` | este handoff, com a evidência da jornada no `gate:` |

Sem spec nova nem bug registrado: a jornada não achou nada. O `docs/qa/` do kit não foi tocado.

## Boot da próxima fase

REVIEW. O diff é `git diff main...HEAD` no worktree `/home/joruge/repos/sdd_agents-l3`. O que a QA
viu: os cinco motivos novos de gate (I1, I3–I7) não aparecem numa missão mergeada, o que é o
comportamento prometido pelas regras de intervalo vazio (I3 PR `MERGED`, I4 missão na base, I5
branch apagado ou contido). A QA **não** exercitou os motivos novos em missão viva; quem os prova
são os 16 mutantes do `tests/check-mutation.sh`, todos aplicáveis (`--anchors` verde). Não rode
`./bin/sdd why … EXEC|QA|REVIEW` por curiosidade: cada um roda a suíte inteira.

## Pendências / Decisions for a Human

- Nenhuma.

## Riscos e não-feitos

- O catálogo de mutação inteiro (`./bin/sdd health`) não rodou, por decisão do plano; só o
  `--anchors` da suíte rápida. O carimbo é do `gate_PR`.
- A jornada leu só uma missão mergeada (a do L2); outra forma de missão fechada (branch apagado,
  PR fechado sem merge) é coberta pelas asserções dos incrementos, não pela jornada.

## Achados fora de escopo

- Nenhum.
