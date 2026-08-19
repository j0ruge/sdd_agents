---
missao: 20260818-lote-facil
fase: DOCS
data: 2026-08-19
status: blocked
gate: "A documentação está sincronizada — checklist de drift com 21 linhas, uma por área que o diff tocou, nenhum `✗`, dezesseis `✅` com hash e cinco `n/a` justificados (`cc09edf`, `167944b`, `c706721`), mais a entrada do `KAIZEN_LOG.md` com antes/depois medido. **Mas a missão não pode seguir para o PR: a suíte está VERMELHA no HEAD.** `tests/run-all.sh` → rc 1, `score: 100 caught, 0 known gap(s), of 101`, com `mut_LEDGER_repo_root_cdpath_leak` sobrevivendo — o fallback pré-2.31 que `75c9d2a` acrescentou **repara a sabotagem** do mutante, que só troca o caminho rápido. Reproduzido em sandbox com o `sed` provado antes: sã e mutante dão saída byte a byte idêntica no `check-autonomy.sh`, rc 0 nas duas. Asserção virou decoração. Registrado no `TODO.md` com a reprodução; a linha para aqui (Jidoka). Some-se a isso a r2 do REVIEW, que terminou `blocked` com quatro critérios abaixo de A."
---

# Documentação — 20260818-lote-facil

> Escrito depois do código final e antes do PR. A pergunta não é "o que seria bom escrever",
> é **"que documento passou a descrever um mundo que não existe mais?"**. Documentação que mente
> custa confiança toda vez que alguém a segue e se queima.

## ⚠️ Jidoka — a linha para aqui, e não é por documentação

A sincronia de documentação desta fase está **feita** e o checklist abaixo passa. O que impede o
PR é outra coisa, medida nesta sessão:

**`tests/run-all.sh` responde rc 1 no HEAD**, com `score: 100 caught, 0 known gap(s), of 101`.
O sobrevivente é `mut_LEDGER_repo_root_cdpath_leak` (`tests/check-mutation.sh:363`).

O mecanismo, reproduzido e não suposto: o mutante substitui **apenas o caminho rápido** de
`ledger_repo_root` pela grafia antiga sem guarda de `CDPATH`. Desde `75c9d2a` — o conserto HIGH
da r2, que está certo — a guarda de forma esvazia o valor envenenado e o **fallback pré-2.31 o
resolve corretamente** com `CDPATH=''`. O conserto repara a sabotagem, e a asserção que guardava
a classe deixou de medir.

Reprodução em sandbox, com o `sed` do próprio catálogo e o piso do probe pago antes de qualquer
conclusão (md5 do `bin/sdd` mudou, `bash -n` limpo):

| | `check-autonomy.sh` | rc |
|---|---|---|
| cópia sã | 3 asserções `cdpath:` verdes | 0 |
| cópia com o mutante aplicado | as MESMAS 3 verdes, saída **byte a byte** idêntica | 0 |

Onde a suíte estava verde pela última vez: `gate-exec-test-002459.log` (00:24), com
`101 caught of 101` — **antes** de `75c9d2a` (00:48). Nenhuma suíte completa rodou depois dele
até agora.

Isto **não** foi consertado nesta sessão de propósito. Não é deriva de documentação, é asserção
morta no catálogo, e o conserto certo é uma decisão de desenho (sabotar as duas grafias no mesmo
mutante, ou dividir em duas entradas) que pertence a quem é dono do catálogo. Está no `TODO.md`
com a reprodução, e a catraca foi movida junto.

## TL;DR

O diff tem 30 arquivos e ~4.100 linhas acrescentadas, e a maior parte dele é **sensor** — código
que não tem documento correspondente por construção. O que de fato derivou foram **três convenções
do `CLAUDE.md`** (as duas famílias que a missão varreu passaram a ter regra própria, e uma delas
mudou de "conserte esta função" para "um scanner cobra o repo inteiro"), **uma rubrica que ficou
numericamente errada** (o auto-teste dizia quatro sensores e são cinco), **duas afirmações de
comando** no `README.md` e no `CONTEXT.md`, e **um estado novo do operador** que ninguém tinha
escrito — o `warn` do git anterior a 2.31.

Dois achados fora de escopo foram para o `TODO.md`, com a catraca movida no mesmo commit
(72 → 74).

⚠️ **Esta missão também não fecha em Grade A.** A r2 do REVIEW terminou `blocked`, com quatro
critérios abaixo de A e três achados de sensor que falha aberto confirmados e reproduzidos. A fase
DOCS foi entrada por decisão de fora do laço (`sdd run --phase DOCS`); o gate do REVIEW nunca
passou, e o ledger registra as quatro sessões com `gate: "fail"`. Nota inflada para passar no gate
desliga o único sensor de qualidade da missão, e o mesmo vale para um PR que finja que a rodada
fechou.

## Checklist de drift

| Área tocada pelo diff | Documento correspondente | Status | Evidência |
|---|---|---|---|
| `bin/sdd` — `cmd_health`, a família do aborto calado (16 capturas na região) | `CLAUDE.md` § "Ao mexer no runner" — regra nova de captura sob `set -e` | ✅ | `cc09edf` |
| `bin/sdd` — `cmd_health`, o que o operador passa a ver | `README.md`, parágrafo do `sdd health` | ✅ | `cc09edf` — "says its verdict out loud and the run carries on" |
| `bin/sdd` — `ledger_repo_root`, `--path-format=absolute` + fallback pré-2.31 | `CLAUDE.md` § "Ao mexer no runner" — "recusar a forma é metade do conserto" | ✅ | `cc09edf` |
| `bin/sdd` — `ledger_repo_root`, como a identidade do repo é resolvida | `CONTEXT.md`, verbete "Ledger de autonomia" | ✅ | `cc09edf` |
| `bin/sdd` — `cmd_preflight`, sonda nova de `rev-parse --path-format` | `README.md` (escopo do preflight) e `docs/failure-modes.md` (seção nova) | ✅ | `cc09edf` |
| `bin/sdd` — `_resolve_self` e a classe do `cd` relativo em 19 sítios | `CLAUDE.md` § TDD, parágrafo do `CDPATH` — deixou de ser conserto de função e virou scanner | ✅ | `cc09edf` |
| `bin/sdd` — `KAIZEN_GUARD_FLOOR` e a chave `floor` da série | `docs/pipeline.md` § "The kaizen loop" | ✅ | `4f6aa8b` — contrato de artefato, atualizado no mesmo commit da mudança |
| `bin/sdd` — as 3 saídas humanas erradas (`BLOCKED … session(s)`, exclusões, `kaizen_axis_note`) | — | n/a | os três consertos fizeram o runner passar a **dizer o que o documento já dizia**: `docs/failure-modes.md` sempre falou em "sessions", e o `pipeline.md` sempre teve um dono só para o piso. Nada a corrigir na prosa |
| `tests/check-health.sh` — regra `guard:` e as 4 asserções `abort:` | `CLAUDE.md` § "Ao mexer no runner" | ✅ | `cc09edf` — com o limite de hoje (uma grafia de captura) nomeado e apontando para o `TODO.md` |
| `tests/check-pipefail.sh` — RULE 2 (`cdpath:`) e RULE 3 (`grep -m<N>`) | `CLAUDE.md` § TDD, parágrafos do `CDPATH` e do `pipefail` | ✅ | `cc09edf` |
| `tests/check-templates.sh` — contrato do `templates/review.md`, `REVIEW_FLOOR` | `CLAUDE.md` § TDD, rubrica do auto-teste (dizia **quatro** sensores nas duas situações; são **cinco**) | ✅ | `cc09edf` |
| `templates/review.md` (novo) | `README.md` (tabela de documentação) e `docs/pipeline.md` § REVIEW | ✅ | `8812a9c` no README; `cc09edf` no pipeline |
| `agents/sdd-reviewer.md` + espelho `.claude/agents/` | o próprio agente, sincronizado por `sdd install --force` | ✅ | `eff77b1` — regra do `CLAUDE.md`, nunca `cp`; espelho conferido byte a byte nesta sessão |
| `tests/check-autonomy.sh` — par diferencial pré-2.31, `cdpath:`, `output:` | `docs/failure-modes.md`, seção nova do git velho (é o sensor que ela cita) | ✅ | `cc09edf` |
| `tests/check-todo.sh`, `check-checkpoint.sh`, `check-kaizen.sh`, `check-gates.sh`, `check-dry-run.sh`, `check-entrypoint.sh`, `check-lang.sh`, `check-preflight.sh`, `run-all.sh` | — | n/a | asserção e piso internos de sensor. Nenhum documento descreve asserção individual, e a **classe** (auto-teste, sabotagem adversarial, piso contra vacuidade) já está no `CLAUDE.md` e foi atualizada onde mudou. Documentar cada probe seria o inverso da disclosure progressiva |
| `tests/check-mutation.sh` — catálogo 81 → 101, 3 mutantes reancorados | `TODO.md`, "Sensores que faltam" | ✅ | `167944b` — a regra "gate novo entra com mutação" não mudou, mas **uma entrada do catálogo parou de medir** e isso é achado, não prosa |
| `tests/check-mutation.sh` — o relógio que o catálogo maior arrasta | `CONTEXT.md` 🚩 D7 e `KAIZEN_LOG.md` | ✅ | `c706721` — par medido no protocolo (1268,31 s na base contra 1051,60 s no HEAD); o alvo não está a 4,9× e sim a ~35× |
| `tests/health-baseline.txt` — `todo-findings` movido em toda fase | `CLAUDE.md` princípio 5 e `README.md` (`sdd health` congela a contagem) | n/a | o mecanismo da catraca não mudou; mudou o número, que é exatamente o que ela existe para fazer aparecer num diff com autor. As duas linhas desta sessão (72 → 74) estão em `cc09edf` e `167944b` |
| `TODO.md` — 18 achados fechados, 36 nascidos | `CLAUDE.md` princípio 5 (formato do item) e o cabeçalho do próprio `TODO.md` | n/a | formato e ciclo de vida inalterados. As entradas da missão foram **conferidas** uma a uma — seção abaixo |
| `docs/handoffs/20260818-lote-facil/*` | — | n/a | artefato de missão, não documentação viva do repo. É o registro que os documentos acima citam quando precisam de profundidade |
| A missão como um todo — antes/depois medido | `KAIZEN_LOG.md` | ✅ | `167944b` (entrada `2026-08-19`, tabela de números, custo real e a suíte vermelha declarada) e `c706721` (a linha do relógio) |

## Entradas do `TODO.md` conferidas nesta missão

O `tests/check-todo.sh` já cobra forma (âncora + data + teto de 8 linhas) e responde
`74 finding(s)` verde. O que ele **não** cobra é se o item diz por que importa e para onde ir —
essa parte foi lida à mão.

**36 entradas nasceram nesta missão**, todas bem formadas: `o quê` em negrito, `arquivo:linha`,
o mecanismo, o que foi **medido**, uma direção e o rodapé `descoberto por <agente> na missão
<slug> (data)`.

| Autor | Entradas | Observação |
|---|---|---|
| `sdd-reviewer` | 29 | as três primeiras de "Sensores que faltam" são as que **reprovaram** a r2 — sensor que falha aberto, cada uma com a reprodução literal |
| `sdd-executor` | 4 | limites declarados das regras novas (`cdpath:` sobre operando variável, RULE 3 com dois greps na linha) e o conflito entre `RESOLVIDO por` e a catraca |
| `sdd-qa` | 1 | a contabilidade do `sdd autonomy` não fechar na tela — decisão entre dois contratos, por isso não virou fix |
| `sdd-docs` | 2 | acrescentadas nesta sessão (abaixo) |

**Nenhuma precisou ser completada.** Duas foram conferidas contra o código de hoje por serem as
mais fáceis de envelhecer — a do `REVIEW_FLOOR` (`tests/check-templates.sh:113`) e a da regra
`guard:` (`tests/check-health.sh:761`): as duas âncoras ainda apontam para o que o corpo descreve.

⚠️ Uma classe **já registrada** não foi duplicada: a r2 do REVIEW anotou que âncoras criadas por
esta própria missão apodreceram dentro dela (`d62b40e` empurrou 125 linhas e o commit seguinte,
`1272690`, "com âncora re-derivada" no título, passou ao lado de duas). O achado existe; repeti-lo
é o desperdício que a catraca existe para impedir.

### Os dois achados que esta sessão registrou

1. **A suíte está vermelha: `mut_LEDGER_repo_root_cdpath_leak` virou decoração** —
   `tests/check-mutation.sh:363`. Medido e reproduzido acima. É o que para a linha.

2. **`REVIEW_MAX_ITER` conta por invocação de `sdd run`, não "in total"** — `config/schema.md:65`
   vs `bin/sdd:2297`. O `local -A attempts=()` nasce dentro de `cmd_run`, então cada `sdd run`
   recomeça o contador. Medido nesta missão: **4 sessões de REVIEW** (~US$ 107) em 3 invocações,
   `attempt` chegando a 2 no ledger, **nenhum** `BLOCKED` e **nenhum** `degraded` — e é justamente
   o `BLOCKED in REVIEW` que `docs/failure-modes.md` descreve como sintoma. Vale para os três
   tetos (`QA_MAX_ITER`, `REVIEW_MAX_ITER`, `EXEC_MAX_RETRY`). Fora de escopo por construção: é
   redesenho de contagem de fase, não deriva de documentação desta missão.

## O que foi deliberadamente NÃO escrito

- **Nada sobre asserção individual de sensor.** São dezenas nesta missão. O índice roteia; a
  profundidade mora no cabeçalho de cada `tests/check-*.sh`, que é onde quem edita o sensor está
  olhando. `CLAUDE.md` que cresce toda missão vira documento que ninguém lê e que estoura a janela
  da próxima sessão — e doc que estoura a janela é doc quebrado.
- **Nenhum ADR.** A missão não tomou nem reverteu decisão arquitetural: os cinco incrementos são
  varredura de classe com sensor. As decisões que continuam pendentes (alvo da D7, as 5 chaves
  fantasma, `--all-repos` no lembrete) já estão no `TODO.md` e no `CONTEXT.md`, e são do humano.
- **Nenhuma regra inventada.** Três convenções entraram no `CLAUDE.md` porque **mudaram** — cada
  uma com o commit da mudança e o sensor que a cobra. Regra escrita por agente sem mudança
  correspondente é dívida que o próximo agente obedece sem questionar.
- **Nenhuma reforma do `docs/pipeline.md`.** Ele tem 42 KB e o item "merece a sua missão" já está
  no `TODO.md`; refatorar documento de outra pessoa no meio desta missão é desvio de escopo.
- **Nenhum conserto de código.** Ver o Jidoka acima: a asserção morta é achado registrado, não
  linha do diff desta fase.

## Pendências para o humano

Em ordem de bloqueio:

1. **A suíte está vermelha no HEAD** (Jidoka acima). Nada deve ir para PR antes disso fechar. O
   conserto é de uma entrada do catálogo e a direção está escrita; a escolha entre "sabotar as
   duas grafias" e "dividir em dois mutantes" é de quem retomar.
2. **A rodada de revisão não fechou.** Três achados de sensor que falha aberto seguem abertos, com
   reprodução. Decidir entre uma r3 e mergear com a dívida registrada é do humano — e o corpo do
   PR tem de mostrar a nota real.
3. **O alvo "<30 s" da D7** segue estourado, e a ordem de grandeza que o `CONTEXT.md` afirmava
   estava errada. Par medido no protocolo nesta sessão (mesma máquina, em sequência, nada mais
   rodando): **1268,31 s na base contra 1051,60 s no HEAD**. O delta é ruído conhecido — o mesmo
   par já oscilou ~2× entre passadas dos mesmos commits —, mas o absoluto é sólido: a suíte leva
   **17 a 21 minutos**, ou **~35×** o alvo, e não os 4,9× registrados. Como todo gate roda a
   suíte, `sdd phase` e `sdd why` bloqueiam por ~20 minutos. Subir o alvo ou aposentá-lo por
   escrito continua sendo decisão do humano.
4. **`LINT_CMD` preenchido e não lido pelo runner** — uma das 5 chaves fantasma do
   `config/schema.md`.
