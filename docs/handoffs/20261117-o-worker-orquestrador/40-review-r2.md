---
missao: 20261117-o-worker-orquestrador
fase: REVIEW
rodada: 2
status: done
sessao: 3b453744-a314-4fa9-9b24-cc229a62e012
data: 2026-11-18 06:43
gate: tests/run-all.sh no afb7f92 verde (rc 0, 2136 ok, 0 FAIL, 13 min 55 s, anchors 846 de 846 aplicam); tests/check-worker.sh 41 ok e 0 FAIL; Checks do R1 e do R2 verdes (1 0 e 1 1 1 0); mutantes WORKER_cap_file_unread, WORKER_rationale_unread e WORKER_shown_terms_unchecked mortos pelo sensor (--only); árvore limpa ao abrir; segredos (regex e gitleaks) sem achado; nota B, três achados reproduzidos, que viraram R3 e R4
---

# Review — rodada r2 — O worker orquestrador

> Escrito ao fim de cada rodada de revisão, em `docs/handoffs/<missão>/40-review-r<N>.md`.
> O runner lê **a mais recente**. Uma rodada que não fechou também escreve o arquivo, com a nota
> real: nota inflada para passar no gate desliga o único sensor de qualidade da missão.

## TL;DR

Revisados os consertos da r1 (`398cdaf..afb7f92`: `328087f` do R1 e `6bc1755` do R2) contra o `bin/sdd-worker` inteiro e o runner.
Os quatro achados da r1 estão fechados e provados pelos Checks e por mutantes mortos.
Três achados novos reproduzidos em cópias `mktemp -d`: 1 HIGH (o `budget` lê o `.sdd/config.sh` do checkout da campanha, e o `sdd run` lê o do worktree da missão: o teto assinado de 40 passa, e o runner real aplica 150) e 2 LOW.
O HIGH virou `R3`; os dois LOW, o lote `R4`. Nada foi consertado aqui.
Nota B em Error Handling e Test Coverage, e B em Documentation; Security subiu para A. As letras sobem: o laço anda.

## Nota da rodada

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | A | Uma definição por fato mantida nos consertos (termos assinados por `terms_digest`, leitor de config único com o ambiente do runner), a cópia da regra de placeholder declarada e segura por um diferencial contra a do runner, e nenhuma função morta. |
| Type Safety | A | Toda fronteira continua validada antes do uso, e o teto lido do config passa por `tonumber` e pela comparação com o assinado antes de virar teto. |
| Error Handling | B | O `budget` falha fechado no checkout da campanha, mas confere o config errado: o worktree da missão, que é o que o `sdd run` lê, pode fixar 150 sem aviso (achado 1); e a parada do teto assinado zero nomeia um arquivo que não fixa nada (achado 3). |
| Security | A | Os dois buracos da r1 na régua e na assinatura fecharam; sobra um LOW estreito, a justificativa-placeholder com pipe escapado que o runner recusa e o `pr-ready` aceita (achado 2). |
| Performance | A | O `pr-ready` ganhou dois `awk` pequenos por rodada, o sensor roda em segundos e a suíte ficou no tempo de sempre (13 min 55 s). |
| Test Coverage | B | 41 linhas ok e 33 mutantes `mut_WORKER_*`, mas o probe do teto (R37) monta a campanha e o config sempre no mesmo checkout, o regime que esconde o achado 1, e nenhum probe cobre o pipe escapado nem o teto assinado zero. |
| Documentation | B | A prosa nova afirma que o `budget` lê o config como o runner o lê, o que é falso para o worktree da missão; o `commands/sdd-worker.md:136` perdeu o antecedente de "no such key"; seguem as derivas que a r1 deixou para a DOCS. |
| **Overall** | **B** | Consertos da r1 sólidos e medidos, com o teto por missão ainda furado no worktree da missão e dois buracos menores, todos reproduzidos e entregues ao executor como R3 e R4. |

## Achados da rodada

> Um item por achado, com severidade e âncora em `arquivo:linha`. O achado que precisa de conserto
> aparece de novo na seção seguinte, como incremento `R<n>` — nunca com hash: quem conserta é o
> executor, na sessão de depois. O que foi refutado vai para `## O que foi refutado`, com evidência.

| # | Severidade | Achado | Onde |
|---|---|---|---|
| 1 | HIGH | O conserto do R1 confere o `.sdd/config.sh` do checkout que guarda a campanha (`repo_root "$dir"`), e o `sdd run` que o ato `run` lança no worktree da missão lê o do **worktree** (`bin/sdd:98`, `CONFIG_FILE="$REPO_ROOT/.sdd/config.sh"`, e o `source` de `bin/sdd:147`). Os dois divergem justamente no mundo que o remédio do template cria: o `templates/delegation.md` manda apagar a linha antes de assinar, e o worktree da missão, cortado de um commit que ainda a tem, continua com `BUDGET_MISSION_USD=150`. Reproduzido numa cópia: repo com a linha commitada, worktree `feat/m` cortado dali, a linha apagada só no checkout da campanha, delegação `pr` assinada com teto 40; `sdd-worker budget` responde `campaign US$ 0.00 of 100.00 — 0 mission(s); mission cap US$ 40.00`, rc 0, e o `bin/sdd` desta branch, rodado no worktree com `BUDGET_MISSION_USD=40 sdd run 20261118-m --dry-run`, imprime `mission budget: US$ 0.00 of 150 spent so far`. Com `0` no config do worktree, a missão roda sem teto. É a mesma consequência do HIGH da r1, num mundo que o conserto deixou aberto | `bin/sdd-worker:472-482` (`cmd_budget`); `commands/sdd-worker.md:98-103`; `docs/pipeline.md:1921-1926`; `config/schema.md:290`; `templates/delegation.md:36-44` |
| 2 | LOW | O `round_unjustified` corta a célula em todo `\|`, e o `gate_REVIEW` reemenda o `\|` antes de julgar. O comentário declara o limite como "the closed side", mas há um lado aberto: a justificativa `<por quê \| em uma frase>` é recusada pelo runner (`gate_REVIEW` desta branch, chamado sobre a rodada: `Security has Grade A with a placeholder Rationale (<por quê \| em uma frase>)`, rc 1) e aceita pelo `pr-ready`, porque o primeiro pedaço, `<por quê \`, não fecha o `>` e tem letra. É o inverso do que a ADR 0022 promete ("never the reverse"), na régua do merge sem humano. LOW porque pede um placeholder com pipe escapado, grafia que o próprio `templates/review.md` usa na tabela de achados | `bin/sdd-worker:682-701` (`round_unjustified` e o limite declarado), `bin/sdd-worker:776-781` |
| 3 | LOW | Um `budget_mission_usd: 0` assinado é legível, e para o runner zero é "sem teto". O `budget` para (rc 1, o lado certo), mas a mensagem acusa o arquivo errado e manda um remédio impossível: sem `.sdd/config.sh` nenhum, responde `no mission cap — <repo>/.sdd/config.sh sets BUDGET_MISSION_USD=0, which sdd run applies over the signed budget_mission_usd: 0; delete the line, or set it above 0 and at most that`. Reproduzido numa cópia sem `.sdd/` | `bin/sdd-worker:150-155` (`delegation_legible`), `bin/sdd-worker:476-482` |

## Incrementos de conserto (R<n>)

> **Esta rodada não conserta.** Cada achado que precisa de conserto vira uma linha `R<n>` na tabela
> de incrementos do `checkpoint.md`, e o `sdd-executor` a fecha em TDD, numa sessão de contexto
> próprio; a rodada seguinte re-avalia sem ter escrito o conserto. CRITICAL/HIGH → um `R<n>` cada;
> MEDIUM/LOW baratos → **um** `R<n>` de lote na rodada; caros → `TODO_FILE`; o que exige julgamento
> humano → seção de pendências, nunca `R<n>`; achado **só de prosa** (`Documentation` abaixo de A)
> → `TODO_FILE`, nunca `R<n>` — o gate tolera B ali, e foi esse laço que custou quatro rodadas.
>
> ⚠️ Nada de `|` cru na célula do Check — a tabela é lida com `awk -F'|'`. Herestring, como abaixo.

| R<n> | Achado | Check escrito no checkpoint |
|---|---|---|
| R3 | #1 | `o=$(bash tests/check-worker.sh 2>&1); a=$(grep -c '^  ok    worktree: ' <<< "$o"); c=$(grep -c '^mut_WORKER_worktree_' tests/check-mutation.sh); test "$c" -ge 1; echo "$a $?"` → `1 0` |
| R4 | #2 e #3 (lote) | `o=$(bash tests/check-worker.sh 2>&1); a=$(grep -c '^  ok    pipe: ' <<< "$o"); b=$(grep -c '^  ok    zero: ' <<< "$o"); p=$(grep -c '^mut_WORKER_pipe_' tests/check-mutation.sh); z=$(grep -c '^mut_WORKER_zero_' tests/check-mutation.sh); test "$p" -ge 1 && test "$z" -ge 1; echo "$a $b $?"` → `1 1 0` |

Os dois Checks foram rodados no `afb7f92` e são vermelhos pelo motivo certo: `R3` → `0 1` e `R4` →
`0 0 1`, porque nenhuma das três famílias (`worktree: `, `pipe: `, `zero: `) nem nenhum dos prefixos
de mutante existe hoje; nenhum colide com os 33 `mut_WORKER_*` nem com as 15 famílias atuais do
sensor (`usage`, os seis verbos, `seal`, `legible`, `cap`, `rationale`, `lot`, `shown`, `command`,
`docs`). As famílias são novas de propósito: nenhuma linha nova nas famílias antigas, ou os Checks
do I1 ao R2 mudam de conta.

## O que virou incremento

- #1, o config do worktree da missão — virou `R3` — o `budget` aplica a mesma regra do R1 ao
  `.sdd/config.sh` de **todo** checkout do repositório que o `checkouts_of` lista (o mesmo conjunto
  em que o `campaign_mission_dirs` acha as missões), ou ao menos ao de todo checkout que guarda uma
  missão da campanha, e sai rc 1 nomeando o arquivo do worktree e o valor quando um deles fixaria a
  chave acima do teto assinado, em zero, vazia ou fora de número. A escolha do conjunto é do
  executor, e o lado mais largo é o seguro. Fixture: o checkout da campanha sem a linha e um
  worktree ligado cujo config fixa `150` (o do starter); controle: o mesmo worktree sem a linha, rc
  0. A prosa que diz "o arquivo do repo" muda no mesmo commit (`config/schema.md:290`,
  `templates/delegation.md:36-44`, `docs/pipeline.md:1921-1926`, o `run` do
  `commands/sdd-worker.md`). Frase sugerida:
  `worktree: a mission worktree whose config sets BUDGET_MISSION_USD above the signed cap stops budget and names that file`.
- #2 e #3 — viraram o lote `R4`, um Check por achado na mesma célula:
  - `pipe: ` — a célula com `\|` deixa de abrir a régua: ou o leitor reemenda o `\|` como o
    `gate_REVIEW` faz (o `escaped_pipe` do `bin/sdd`), ou recusa toda linha da tabela de notas que
    traz um `\|`. O probe é o diferencial do R38 com células que carregam `\|` (a do achado e uma
    frase real com pipe escapado), e o comentário do limite declarado diz a verdade sobre o lado.
    Frase sugerida: `pipe: a fill-in rationale holding an escaped pipe fails review, as gate_REVIEW refuses it`.
  - `zero: ` — um teto por missão assinado zero nunca é passado como teto, e a parada nomeia a
    delegação, não um config que não fixa nada: ou o `delegation_legible` recusa o zero (para o
    runner zero é "sem teto"), ou a mensagem do `budget` distingue a origem do valor. Frase sugerida:
    `zero: a signed mission cap of zero stops budget naming the delegation, never a config that does not set it`.
- #1 da r1, o teto por missão que o config do alvo vence — fechado em `328087f` — o Check do `R1`
  responde `1 0` no `afb7f92`, e o mutante `WORKER_cap_file_unread` morre contra o sensor; o
  resíduo do worktree é o achado #1 desta rodada.
- #2 da r1, a justificativa e o `gate:` placeholder — fechado em `6bc1755` — família `rationale: `
  verde, mutante `WORKER_rationale_unread` morto; o diferencial lê o `PLACEHOLDER_AWK` do `bin/sdd`
  e o compara com a cópia sobre 25 mundos.
- #3 da r1, o `allows` sem `--lot` — fechado em `6bc1755` — família `lot: ` verde; o verificador
  da prosa não achou `allows` sem `--lot` em nenhum `.md` da superfície.
- #4 da r1, o `delegate` que assinava o arquivo da hora do `y` — fechado em `6bc1755` — família
  `shown: ` verde, mutante `WORKER_shown_terms_unchecked` morto.

## O que foi refutado

- **Um PR de fork com o nome da branch da missão desviaria o `next`.** Não levantado: o
  `gh pr list --head` filtra só pelo nome da branch (o `--help` do gh 2.85.0 diz que a forma
  `<owner>:<branch>` não é aceita), e o kit é público. Mas não reproduzi: o repo não tem nenhum PR
  entre repositórios (`isCrossRepository`, 0 de todos), e o efeito possível é só parar (`stop` por
  um PR fechado) ou apontar a revisão para outro número, onde o `pr-ready` falha no `review` ou no
  `head`. Nunca um merge de conteúdo alheio. Hipótese sem reprodução não vira `R<n>`.
- **A sessão do worker poderia assinar a própria delegação por pipe.** Refutado como achado: é
  limite declarado da ADR 0022 (Consequences: "The signature proves an answer on stdin, not a
  person: an agent with a shell passes, the same limit `sdd approve` has").
- **O `round_unjustified` lê o cabeçalho e as linhas de critério vazio diferente do runner.**
  Refutado: o cabeçalho tem a justificativa `Rationale`, que não é placeholder; uma linha de critério
  vazio o runner pula e o worker julga, e julgar é o lado fechado.

## Achados fora de escopo

- Nenhum registrado no backlog nesta rodada. O achado de forma do `commands/sdd-worker.md:136` é
  prosa desta missão e vai para a DOCS, abaixo, como a r1 fez com as derivas dela.

## Pendências / Decisions for a Human

1. **Para a DOCS, prosa só, nenhum `R`:** o `commands/sdd-worker.md:136`, onde "carry no such key"
   passou a ler `gate:` como antecedente depois da frase nova do R2 (a chave que falta às rodadas do
   runner é `reviewed_head:`), e a linha que passou da largura; mais as derivas que a r1 deixou
   (as três da QA, a frase da ADR 0022 §3, os "dezesseis" sensores do `CLAUDE.md:282` e `:293` e a
   linha ⛔ da `.claude/rules/anatomia-do-agente.md:179`).
2. **O lado do runner do teto por missão** segue como a r1 o deixou: o `R1` e o `R3` só fazem o
   worker falhar fechado; fazer a delegação valer num alvo cujo config fixa a chave pede mexer na
   precedência de config do `bin/sdd`, decisão do dono.
3. **O laço está na r2 de `REVIEW_MAX_ITER=3`.** A r3 é a última rodada de achado: o que ela achar
   e não fechar volta ao dono.
