---
missao: 20260818-lote-facil
fase: EXEC
status: done
sessao: 3fbe987e-2fb6-4c8d-99c3-9669d1654f4a
data: 2026-08-18 23:59
gate: "tests/run-all.sh → suite green, rc 0 · score: 98 caught, 0 known gap(s), of 98 (era 81) · 42 finding(s) · ./bin/sdd health → kit healthy, rc 0, nos cinco (suíte, mutação 98, 8 gates com mutação, proveniência 3/3, ratchet 7 débitos conhecidos, nenhum novo) · shellcheck -S warning bin/sdd tests/*.sh limpo · checkpoint 5/5 done, hashes 4f11624 aa95b2e 4f6aa8b f21df55 eff77b1, todos conferidos por `git merge-base --is-ancestor <hash> HEAD` · os 5 Checks rodados literais: 4 · 3 · 9 · 5 · 5"
---

# Handoff — EXEC — o `sdd health` para de morrer calado, e 18 achados baratos saem do backlog

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

Os 5 incrementos estão `done`. O `sdd health` deixou de morrer calado nos **cinco** sítios da
família (o plano previa quatro), a classe do `cd` relativo saiu de **dezenove** sítios (o plano
previa quatorze), três números que o humano lê pararam de contar a grandeza errada, cinco caminhos
sem asserção ganharam asserção **e** mutação, e cinco regras de sensor ganharam probe — mais o
`templates/review.md`, que faltava. Catálogo **81 → 98**, `0 known gap(s)`, suíte verde,
`TODO.md` **56 → 42**. A próxima fase é **QA**.

> ⚠️ **Este handoff foi escrito na sessão do I5**, a última das cinco (uma por incremento). O que
> cada uma mediu está nas Notas de execução do `checkpoint.md` — é lá, e não aqui, que mora o
> detalhe por incremento.

## Estado do repo

- **Branch:** `chore/lote-facil` — **nunca empurrada**; `origin` não conhece esta branch.
- **Último commit:** `eff77b1` `test(sensores): cinco regras de sensor ganham probe, e o review
  ganha template` (mais o commit de checkpoint/handoff que fecha esta sessão).
- **Working tree:** limpo.
- **Suíte:** `tests/run-all.sh` → **verde**, rc 0. Treze sensores + lint + dry-runs;
  `score: 98 caught, 0 known gap(s), of 98` — eram 81 no começo da missão.
- **E2E:** `E2E_CMD` é vazio no `.sdd/config.sh` deste repo — não existe jornada de navegador. O
  equivalente aqui são os comandos da seção "Boot da próxima fase".
- **`sdd health`:** `kit healthy`, rc 0, `ratchet: 7 known debt(s), none new`.

## O que foi feito

- `4f11624` — **I1, a família do aborto calado.** `out="$(cmd)"` sob `set -euo pipefail` matava o
  `cmd_health` na atribuição e o `health_bad` da linha seguinte era código morto. Quatro sítios
  previstos, **cinco** encontrados: o quinto era o `health_ratchet` terminando numa cadeia
  `[…] && […] && ok …`, que devolvia o status do primeiro teste falho — catraca que ACHAVA algo
  matava o comando uma linha antes do próprio veredito. 4 asserções `abort:` + 5 mutações.
- `aa95b2e` — **I2, a família do `cd` relativo.** 19 sítios, não 14: três linhas `SELF`/`SELF_PATH`
  que o item do backlog não contava, e **dois em `bin/sdd`** (`_resolve_self`, que resolve o
  `SDD_HOME` `readonly` de onde saem todo template e agente) — defeito vivo no runner e ausente do
  backlog. O `ledger_repo_root` ficou menor: `git rev-parse --path-format=absolute --git-common-dir`
  dispensa os dois `cd`, o `pwd -P` e a guarda. 1 probe `cdpath:` novo, 3 mutantes reancorados.
- `4f6aa8b` — **I3, saída humana do runner.** `BLOCKED in <FASE> — N sessions` contava voltas do
  laço; as exclusões do `sdd autonomy` saíam com linha em branco entre cada duas; o
  `kaizen_axis_note` repetia o piso que o `guard_floor` do `jq` já dono. 3 asserções `output:` +
  **5** mutações (duas regras ficariam sem probe com uma por defeito). O piso ganhou dono em bash
  (`KAIZEN_GUARD_FLOOR`), alimentando `jq` e `printf`, porque o produtor da série vazia não roda
  o programa jq.
- `f21df55` — **I4, cinco caminhos sem asserção.** O incremento **não muda uma linha do `bin/sdd`**:
  os caminhos já estavam corretos, faltava medida. 5 asserções `covered:` + **7** mutações (duas
  famílias têm duas guardas cada). O conteúdo das duas skills novas é DERIVADO do `check-gates.sh`
  e conferido contra as skills instaladas, nunca escrito de memória.
- `eff77b1` — **I5, regras de sensor e o template que faltava.** Regra 3 do `check-pipefail.sh`
  (`grep -m<N>` sem quiet, com a única violação viva convertida no mesmo commit), `pipe_rule()` no
  `check-checkpoint.sh`, `last_sep` do `check-todo.sh` pulando separador dentro de code span, a
  caixa que cai na linha seguinte ao marcador recusada pelo nome, e `templates/review.md` — com a
  tabela copiada da fonte do skill `codereview`, não de memória. 5 asserções `rule:`.

## Artefatos

| Arquivo | O que contém |
|---|---|
| `docs/handoffs/20260818-lote-facil/00-missao.md` | a intenção, as 3 métricas e o que ficou fora |
| `docs/handoffs/20260818-lote-facil/01-plano.md` | o como, o contexto já verificado, as âncoras re-derivadas |
| `docs/handoffs/20260818-lote-facil/checkpoint.md` | a tabela 5/5 `done` e **as Notas de execução** — o detalhe por incremento mora lá |
| `templates/review.md` | o template novo do `40-review-r<N>.md`, com o `### Overall Grade` no nível que o `gate_REVIEW` lê |
| `TODO.md` + `tests/health-baseline.txt` | 42 achados abertos, catraca movida junto em cada commit |

## Boot da próxima fase

A próxima é **QA**. Este repo **não tem interface**: `E2E_CMD` é vazio e não existe jornada de
navegador, então as skills `qa-report`/`qa-execution` não têm o que percorrer. A jornada aqui é a
linha de comando do runner, e é ela que a QA deve andar.

Leia, nesta ordem: `00-missao.md` (as 3 métricas), as **Notas de execução** do `checkpoint.md`
(onde cada incremento registrou o que mediu e onde errou primeiro), e este handoff.

Ambiente: nada a subir. `cd` no repo e:

```sh
bash tests/run-all.sh          # ~4 min — treze sensores, lint, dry-runs, 98 mutantes
./bin/sdd health               # os cinco checks do kit sobre si mesmo
./bin/sdd status 20260818-lote-facil
```

**O que ficou visível para quem usa o kit**, e portanto é o que a QA deve exercitar:

1. **`sdd health` com a suíte vermelha.** É a prova que mais importa da missão e a única que não é
   um sensor da suíte. Sabote a suíte de propósito (num **kit copiado** — `SDD_HOME` é `readonly`
   e não se aponta por env) e confirme que ele **imprime `suite red` e SEGUE** para os checks
   seguintes, em vez de imprimir uma linha e sair rc 1. Os outros três sítios: suíte verde e muda
   sobre `score:`, `~/.claude/plugins/cache` ausente (`HOME` vazio), baseline só com comentários.
2. **Saída humana do runner** — `sdd why` sobre uma missão bloqueada (a contagem de sessões),
   `sdd autonomy` com três exclusões (parágrafo único, sem linha em branco entre elas) e
   `sdd kaizen` com menos de três missões no eixo (o piso citado uma vez só).
3. **`sdd install` / `sdd preflight`** — o `_resolve_self` mudou, e dele sai o `SDD_HOME` de onde
   vêm templates e agentes. Vale rodar com `CDPATH` sujo no ambiente.
4. **`templates/review.md`** — novo. A fase REVIEW é a primeira que vai usá-lo de verdade.

## Pendências / Decisions for a Human

- **O alvo "<30 s" da D7 segue estourado e esta missão o piorou.** O catálogo foi de 81 para 98
  mutantes e cada um roda a suíte inteira; a suíte está em ~4 min. A decisão — subir o alvo,
  aposentá-lo, ou rodar por mutante só o sensor que o alcança — é do humano e está no `TODO.md`,
  seção "Custo e escala".
- **O `LINT_CMD` está preenchido no `.sdd/config.sh` deste repo e o runner não o lê em lugar
  nenhum.** É uma das 5 chaves fantasma do `config/schema.md`, declaradas fora de escopo no
  `00-missao.md` por exigirem decisão humana antes de qualquer código.

## Riscos e não-feitos

- **O alvo do `00-missao.md` era 38 achados; o real é 42.** Não é desvio: a métrica 3 dizia
  "38 + achados novos", e a tabela de riscos do plano previu que a re-derivação acharia mais
  trabalho. Nasceram 4 achados durante a missão (1 no I1, 1 no I2, 2 no I5), todos com a baseline
  movida no mesmo commit. Fecharam-se 18, como planejado.
- **Três sobreviventes da passada adversarial do I5, nomeados nos cabeçalhos dos sensores:** baixar
  um piso (`rule_end`, `RULES_FLOOR`, `REVIEW_FLOOR`) enquanto o que ele conta continua lá. Nenhum
  é alcançável numa edição só, e as cinco sabotagens pareadas que apagam o que cada piso conta
  morreram todas.
- **`tests/check-templates.sh` não tem `selftest()` e o catálogo de mutação não o alcança** — ele
  mede `templates/`, e o catálogo sabota o `bin/sdd`. Regex quebrada ali reporta "template contract
  intact" para sempre sobre 60 asserções, inclusive as do `40-review-r<N>.md`. Registrado no
  `TODO.md`; **não** consertado aqui porque é sensor novo, não regra barata.
- **O `check-autonomy.sh` vermelho intermitente não apareceu** em nenhuma das cinco sessões. Segue
  não reproduzido e fora de escopo por decisão 6 do `00-missao.md`.
- **A regra 3 do `check-pipefail.sh` não separa dois greps na mesma linha.** Limite declarado no
  cabeçalho do sensor e no `TODO.md`; nenhuma instância no kit hoje.
- **Nada foi empurrado, nenhum PR foi aberto, nada foi mergeado** — isso é de outra fase.

## Achados fora de escopo

> Registrados no `TODO.md` deste repo (é o kit). Aqui fica só o ponteiro, para o PR conseguir citar.

- O ciclo de vida do `RESOLVIDO por` e a catraca do backlog não cabem juntos → `TODO.md`
  (Contrato e configuração) — descoberto no I1.
- A regra `cdpath:` certifica como limpo o `cd` de operando **variável**, que é justamente a forma
  da CRITICAL de `20260817-eixo-do-juiz` → `TODO.md` (Sensores que faltam) — descoberto no I2.
- O `check-templates.sh` sem auto-teste e fora do alcance do catálogo → `TODO.md`
  (Sensores que faltam) — descoberto no I5.
- O limite declarado da regra 3 (linha com dois greps recebe a mensagem apontando o comando
  errado) → `TODO.md` (Sensores que faltam) — descoberto no I5.
