---
missao: 20261002-onde-o-comando-do-humano-escreve
fase: DOCS
status: done
sessao: n/a (sessão headless do sdd-docs lançada pelo sdd run)
data: 2026-10-02
gate: tests/check-todo.sh → "ok    88 finding(s) … every anchor on target"; tests/check-lang.sh → "0 of 56 surface path(s) still in the allowlist, 0 new"; tests/check-templates.sh → "template contract intact"; docs em 54c6c56
---

# Handoff — DOCS — Onde o comando do humano escreve

## TL;DR

Oito documentos descreviam o mundo de antes da missão. O `sdd approve` "commitava só o
`00-missao.md`" e ficava onde o humano estava. O `sdd close` sem JIRA "não fazia nada". O
`install --force` escrevia através de link. A suíte não tinha prazo. Tudo foi consertado em
`54c6c56`: `README.md`, `docs/pipeline.md`, `CONTEXT.md`, `CLAUDE.md`, `docs/failure-modes.md`
(verbete novo `timed out after N s` / `TIMED-OUT`), `agents/sdd-planner.md` § 8 com o espelho
sincronizado por `sdd install --force`, o placeholder de `branch:` em `templates/missao.md` e a
entrada medida no `KAIZEN_LOG.md`. A `.claude/rules/anatomia-do-agente.md` (§ 4 e § 7) ficou como
`⛔`, com o texto proposto abaixo. ⚠️ `templates/` está na chave do carimbo, então o `sdd health` do
humano roda **depois** deste commit.

## Estado do repo

- **Branch:** `feat/onde-o-comando-do-humano-escreve`, local e sem push.
- **Último commit:** o commit desta fase, sobre `54c6c56`.
- **Working tree:** limpo depois do commit.
- **Suíte:** sensores de prosa verdes (`check-todo`, `check-lang`, `check-templates`, `check-checkpoint`).

## O que foi feito

- `54c6c56`: a sincronização dos documentos listados na tabela abaixo. O commit também remapeia
  três âncoras do `TODO.md` que as edições deslocaram (`README.md:154→157`, `docs/pipeline.md:525→529`
  e `:1003→1008`) e acrescenta a linha `Fonte:` que faltava no achado do `adr_declare`.

## Drift checklist

| Area touched by the diff | Corresponding document | Status | Evidence |
|---|---|---|---|
| `bin/sdd` (`cmd_approve` chama `ensure_mission_branch` e commita o diretório da missão, #156) | `README.md` | ✅ | linha `sdd approve` da seção Usage, em `54c6c56` |
| `bin/sdd` (`cmd_approve`, #156) | `docs/pipeline.md` | ✅ | § PLAN ("`auto` is refused outright…") e § "The mission's branch" (o approve é o terceiro chamador), em `54c6c56` |
| `bin/sdd` (`cmd_approve`, #156) | `CONTEXT.md` | ✅ | verbete "Portas que commitam" e o trecho sobre os chamadores de `ensure_mission_branch` em "Janela de medição", em `54c6c56` |
| `bin/sdd` (`cmd_approve`, #156) | `agents/sdd-planner.md` | ✅ | § 8 Branch, em `54c6c56`; espelho `.claude/agents/sdd-planner.md` por `sdd install --force` no mesmo commit |
| `bin/sdd` (`cmd_approve`, #156) | `templates/missao.md` | ✅ | placeholder de `branch:` diz `sdd approve/run/retry`, em `54c6c56` |
| `bin/sdd` (`cmd_close` sem JIRA: conferência do PR acima da bifurcação e `close_return_home`, #182) | `docs/pipeline.md` | ✅ | tabela de recusas do `sdd close` reordenada e parágrafo "comes home with the merge", em `54c6c56` |
| `bin/sdd` (`cmd_close`, #182) | `README.md` | ✅ | comentário do `sdd close` na seção Usage, em `54c6c56` |
| `bin/sdd` (`cmd_install` não escreve através de link, #173) | `README.md` | ✅ | frase depois do parágrafo do `sdd-link-agents`, em `54c6c56` |
| `bin/sdd` (`cmd_install`, #173) | `docs/failure-modes.md` | ✅ | parágrafo "A symlinked agent is never written through" no verbete do diff do install, em `54c6c56` |
| `bin/sdd` (`frontmatter_write`: recusa symlink, `warn` no chmod, `ENVIRON`, #81) | — | n/a | a recusa é uma mensagem `die` autoexplicativa que nenhum doc descreve; o `frontmatter_write` não aparece em `README.md`, `docs/` nem `CONTEXT.md` (`grep -rn frontmatter_write docs README.md CONTEXT.md` vazio) |
| `bin/sdd` (`checkpoint_note_intervention`: `mktemp` só no ramo que o usa e aviso `intervention NOT written`, #193 e R1) | — | n/a | conserto interno do escritor da nota; a documentação da linha `- intervention:` (§ 7 da rule e `docs/pipeline.md`) descreve o conteúdo, não o temporário, e continua verdadeira |
| `tests/run-all.sh` (`step_timeout` e prazo por passo, #112) | `CLAUDE.md` | ✅ | aviso novo em § "TDD aqui dentro", em `54c6c56` |
| `tests/run-all.sh` (#112) | `docs/failure-modes.md` | ✅ | verbete novo "A suite step `timed out after N s`", em `54c6c56` |
| `tests/check-mutation.sh` (`rc_verdict`: 124 é `TIMED-OUT`, inconclusivo, #112) | `docs/failure-modes.md` | ✅ | mesmo verbete (sintoma `FAIL TIMED-OUT`), em `54c6c56` |
| `tests/check-mutation.sh` (veredito inconclusivo) | `.claude/rules/anatomia-do-agente.md` | ⛔ | § 4, parágrafo "Onde mora hoje"; texto em "Texto proposto" |
| `bin/sdd` (o approve como porta humana que troca de branch) | `.claude/rules/anatomia-do-agente.md` | ⛔ | § 7, parágrafo "Onde mora hoje"; texto em "Texto proposto" |
| `tests/check-autonomy.sh` (veneno do rótulo REVIEW armado pelo sensor, #186; probe do R1) | — | n/a | probes internos do sensor; nenhum doc descreve os mundos do `check-autonomy.sh`, e o cabeçalho do próprio sensor é a documentação |
| `tests/check-coordination.sh` (probe de sinal nasce com SIGINT ignorado, #157) | — | n/a | idem; o limite de sinais da rule § 6 continua verdadeiro e não fala da forma do probe |
| `tests/check-gates.sh`, `tests/check-health.sh`, `tests/check-preflight.sh` (probes das portas) | — | n/a | asserções novas, sem contrato que algum doc descreva; o número de sensores (16) não mudou |
| `tests/health-baseline.txt` (catraca 86 → 88) | — | n/a | a catraca é o próprio artefato; o `CLAUDE.md` descreve o mecanismo e manda ler o número do comando |
| `TODO.md` (8 `RESOLVED by`, 2 achados novos, âncoras remapeadas) | `TODO.md` | ✅ | achados conferidos abaixo; âncoras e `Fonte:` em `54c6c56` |
| `docs/handoffs/20261002-onde-o-comando-do-humano-escreve/**` | — | n/a | artefatos da própria missão, não documentação viva |
| missão inteira (antes/depois medido) | `KAIZEN_LOG.md` | ✅ | entrada "2026-10-02 — Onde o comando do humano escreve", em `54c6c56` |

## Texto proposto
<!-- sdd:proposed -->

Em `.claude/rules/anatomia-do-agente.md`, § 4 (Mecanismos de verificação), parágrafo "Onde mora
hoje", depois de "catálogo de mutação com carimbo no `sdd health`;", inserir:

> desde `20261002-onde-o-comando-do-humano-escreve` (#112) todo passo do `tests/run-all.sh` tem
> prazo (`step_timeout`, uma tabela; passo sem linha é recusado), e dentro de mutante o estouro sai
> com rc 124, que o `rc_verdict` do catálogo lê como `TIMED-OUT` — **inconclusivo**, nunca pego:
> máquina lenta não compra ponto que a sabotagem não ganhou;

Em `.claude/rules/anatomia-do-agente.md`, § 7 (Hooks), parágrafo "Onde mora hoje", trocar
"`aprovacao:` + `sdd approve` (gate PLAN);" por:

> `aprovacao:` + `sdd approve` (gate PLAN), que desde `20261002-onde-o-comando-do-humano-escreve`
> (#156) entra na branch do `branch:` depois do `y` (`ensure_mission_branch`, a mesma definição do
> `sdd run`) e commita o diretório da missão inteiro lá, nunca na base; o `sdd close` volta à base
> nos dois ramos (`close_return_home`), com ou sem JIRA;

## Achados do `TODO_FILE` conferidos nesta missão

`tests/check-todo.sh --check TODO.md` → `ok    88 finding(s), all within 8 lines, carrying anchor + date, every anchor on target`.

- **O `adr_declare` engole a falha do `chmod --reference`…** (`bin/sdd:7012`, `ADR_DECLARE_WHY`),
  do `sdd-planner`/I10: faltava a linha `Fonte:`. Completada com o § Fora de escopo do `00-missao.md`.
- **`sdd close` sem `50-pr.md` sai da branch da missão e diz que ela foi mergeada** (`bin/sdd:10690`),
  do `sdd-qa`: bem formado (âncora, porquê, `Direção:`, `Fonte:` no `30-handoff-qa.md`, autor e data).
- Os oito itens das issues da missão (#156, #182, #193, #81, #173, #186, #157, #112) carregam
  `RESOLVED by <hash>` (I10, `41d8837`). Ficam na seção aberta até o merge, porque a regra apaga o
  item só depois de `git merge-base --is-ancestor`. Nenhum achado foi refutado ou decidido nesta
  missão, então nada passou para `<!-- sdd:decided -->`.
- `README.md:157`, `docs/pipeline.md:529` e `:1008`: âncoras de três achados alheios deslocadas por
  esta fase e remapeadas.

## Boot da próxima fase

PR: abrir com o corpo levando as duas linhas `⛔` (`.claude/rules/anatomia-do-agente.md`, § 4 e § 7)
e o texto proposto acima. O carimbo do catálogo precisa do `sdd health` **depois** de `54c6c56`,
porque `templates/missao.md` mudou.

## Pendências / Decisions for a Human

- Aplicar o texto proposto na `.claude/rules/anatomia-do-agente.md` (o chapéu DOCS não escreve `.claude/rules/`).
- Rodar `./bin/sdd health` uma vez, depois da última rodada dos revisores do PR (métrica 7).

## Riscos e não-feitos

- O comentário de `cmd_approve` em `bin/sdd` é do I7, não da DOCS, e já foi reescrito lá.
- O `docs/plan-only.md` não foi tocado: ele descreve o `sdd-link-agents` e não o `install --force`, e continua verdadeiro.
