---
missao: 20261117-o-worker-orquestrador
fase: REVIEW
rodada: 3
status: done
sessao: 3fc5924d-1d80-4519-9b70-8e6f7dcd60d6
data: 2026-11-18 08:51
gate: tests/run-all.sh no 218df08 verde (rc 0, 2139 ok, 0 FAIL, 12 min 56 s, anchors 852 de 852 aplicam); tests/check-worker.sh 44 ok e 0 FAIL; Checks do R3 e do R4 verdes (1 0 e 1 1 0); os seis mutantes novos (WORKER_worktree_root_only, WORKER_worktree_file_misnamed, WORKER_pipe_cut_raw, WORKER_pipe_grades_cut_raw, WORKER_pipe_parity_lost, WORKER_zero_signed_unchecked) mortos pelo sensor (--only); árvore limpa ao abrir; segredos (regex e gitleaks) sem achado; nota B, um achado MEDIUM reproduzido de ponta a ponta, que virou R5; PLATÔ contra a r2: Error Handling e Test Coverage seguem em B pela mesma classe (o config lido no checkout da campanha, e não no do worktree onde o sdd run roda), agora no pager; r3 é a última de REVIEW_MAX_ITER=3
---

# Review — rodada r3 — O worker orquestrador

> Escrito ao fim de cada rodada de revisão, em `docs/handoffs/<missão>/40-review-r<N>.md`.
> O runner lê **a mais recente**. Uma rodada que não fechou também escreve o arquivo, com a nota
> real: nota inflada para passar no gate desliga o único sensor de qualidade da missão.

## TL;DR

Revisados os consertos da r2 (`c021f95..218df08`: `7747f6b` do R3 e `756fed3` do R4) contra o `bin/sdd-worker` inteiro e o runner; os três achados da r2 estão fechados, com Checks verdes e seis mutantes mortos.
Um achado novo, MEDIUM, reproduzido de ponta a ponta com o runner desta branch: o `level` confere o pager no `.sdd/config.sh` do checkout da campanha, e o `sdd run` no worktree da missão escala rc 3 sem avisar ninguém. Virou `R5`.
É a mesma classe do HIGH da r2 (o R3 fechou o `budget`, o `level` ficou), então as letras não andaram: Error Handling e Test Coverage em B, Documentation em B. Platô, e esta é a última rodada de `REVIEW_MAX_ITER=3`.
Seis LOW de prosa vão para a DOCS. Nada foi consertado aqui.

## Nota da rodada

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | A | Os consertos mantêm uma definição por fato: o `cells()` do `GRADE_ROW_AWK` serve aos dois leitores da tabela, o `budget` reusa o `checkouts_of` do `campaign_mission_dirs`, nenhum símbolo novo ficou sem leitor e o `shellcheck -S warning` passa limpo. |
| Type Safety | A | O teto assinado zero passou a ser recusado antes do uso, e o teto lido de cada config segue por `tonumber` e pela comparação com o assinado antes de virar teto. |
| Error Handling | B | A regra `no pager` lê só o config do checkout da campanha, e o runner no worktree da missão lê o dele: com o pager só no primeiro, o `level` responde `pr` e o `increment-blocked` do runner para a linha sem aviso, enquanto o comando diz que o rc 3 já foi avisado pelo runner (achado 1). |
| Security | A | Os dois LOW da r2 fecharam: a tabela de notas é cortada como o `gate_REVIEW` a corta, provado em oito linhas contra o split lido do próprio `bin/sdd`, e o teto zero para nomeando a delegação; a varredura de segredos não acha nada. |
| Performance | A | Um subshell de `config_key` por checkout e dois `awk` por rodada; o sensor roda em segundos e a suíte ficou em 12 min 56 s. |
| Test Coverage | B | 44 linhas ok, 39 mutantes `mut_WORKER_*` e os seis novos mortos por `--only`, mas o probe do pager (R9) monta o pager e a campanha no mesmo checkout, o regime que esconde o achado 1. |
| Documentation | B | A prosa do R3 e do R4 está certa no que afirma do `budget`, com seis derivas LOW de forma (abaixo, para a DOCS); a do pager ainda diz o config do repo da campanha, que é o achado 1. |
| **Overall** | **B** | Consertos da r2 sólidos e medidos; o pager ainda é conferido no checkout errado, reproduzido de ponta a ponta e entregue ao executor como R5. |

## Achados da rodada

> Um item por achado, com severidade e âncora em `arquivo:linha`. O achado que precisa de conserto
> aparece de novo na seção seguinte, como incremento `R<n>` — nunca com hash: quem conserta é o
> executor, na sessão de depois. O que foi refutado vai para `## O que foi refutado`, com evidência.

| # | Severidade | Achado | Onde |
|---|---|---|---|
| 1 | MEDIUM | A regra 6 do nível efetivo (`no pager`) lê o `ON_ESCALATION_CMD` com `config_key "$root"`, só no `.sdd/config.sh` do checkout que guarda a campanha. O `sdd run` que o ato `run` lança no worktree da missão carrega o do worktree (`resolve_repo_root` e `CONFIG_FILE` em `bin/sdd:95-98`, o default de `bin/sdd:187`, o gancho de `bin/sdd:4989`). Reproduzido em cópia `mktemp -d`: config commitado com `ON_ESCALATION_CMD=""`, worktree `feat/m` cortado dali, o pager escrito só no checkout da campanha e não commitado (o comando de um pager costuma levar um tópico secreto), delegação `pr` assinada. O `level --lot L1` responde `level pr — signed until 2099-01-01 00:00`, o `allows run --lot L1` responde `allowed run at pr` e o `budget` sai rc 0. O `bin/sdd` desta branch, rodado no worktree como o comando o lança (`BUDGET_MISSION_USD=40 sdd run <m>`, sem sessão: um incremento `blocked`), sai rc 3 com `BLOCKED in EXEC … Jidoka` e o arquivo do pager não nasce. Controle: o mesmo worktree com a linha do pager no arquivo dele grava `PAGED increment-blocked`. O comando manda a sessão não avisar o rc 3 do runner ("an escalation the runner already paged", "that stop is not paged twice"), então ninguém avisa. A decisão 10 exige pager acima de `assisted` porque "uma noite sem ninguém olhando precisa de um aviso que chegue". É o mesmo erro do HIGH da r2, no outro valor de config que o worker confere. MEDIUM, e não HIGH: a linha para, o ledger grava a escalada e nenhum dólar ou merge escapa; o que se perde é o aviso | `bin/sdd-worker:320-323` (`effective_level`); `commands/sdd-worker.md:117-118` e `:177`; `config/schema.md:292`; `templates/delegation.md:33-34`; `docs/pipeline.md:1878-1879` |

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
| R5 | #1 | `o=$(bash tests/check-worker.sh 2>&1); a=$(grep -c '^  ok    pager: ' <<< "$o"); c=$(grep -c '^mut_WORKER_pager_' tests/check-mutation.sh); test "$c" -ge 1; echo "$a $?"` → `1 0` |

O Check foi rodado no `218df08` e é vermelho pelo motivo certo: `0 1`, porque a família `pager: `
não existe no sensor e nenhum mutante tem o prefixo `mut_WORKER_pager_`. O probe de hoje sobre o
pager é a linha `level: above assisted with no pager answers assisted`, da família `level: `, que
o Check do I4 conta: a família nova é nova de propósito, ou o I4 muda de conta.

## O que virou incremento

- #1, o pager do worktree da missão — virou `R5` — o `level` aplica a regra `no pager` ao
  `.sdd/config.sh` de todo checkout que o `checkouts_of` lista (o conjunto do `budget` desde o R3,
  uma definição para as duas perguntas), ou ao menos ao de todo checkout que guarda uma missão da
  campanha, e responde `assisted — no pager` nomeando o arquivo do worktree quando um deles deixa o
  `ON_ESCALATION_CMD` vazio. A escolha do conjunto é do executor, e o lado mais largo é o seguro.
  Fixture: o checkout da campanha com o pager e um worktree ligado cujo config o deixa vazio, mais o
  mundo inverso; controle: o pager nos dois, o nível assinado. A prosa muda no mesmo commit
  (`config/schema.md:292`, `templates/delegation.md:33-34`, `docs/pipeline.md:1878-1879` e o `run`
  do `commands/sdd-worker.md`). Frase sugerida:
  `pager: a mission worktree whose config leaves ON_ESCALATION_CMD empty lowers the level to assisted and names that file`.
- #1 da r2, o config do worktree da missão no `budget` — fechado em `7747f6b` — o Check do `R3`
  responde `1 0` no `218df08`; os mutantes `WORKER_worktree_root_only` e
  `WORKER_worktree_file_misnamed` morrem contra o sensor; o probe tem o worktree com missão, o sem
  missão (nome com barra invertida e espaço final) e o controle.
- #2 da r2, a justificativa-placeholder com pipe escapado — fechado em `756fed3` — família `pipe: `
  verde; `WORKER_pipe_cut_raw`, `WORKER_pipe_grades_cut_raw` e `WORKER_pipe_parity_lost` mortos; o
  probe lê o split do `gate_REVIEW` de dentro do `bin/sdd` e exige acordo em oito linhas, mais a
  linha sem pipe de fechamento, que o `pr-ready` recusa e o runner pula (o lado fechado).
- #3 da r2, o teto assinado zero — fechado em `756fed3` — família `zero: ` verde,
  `WORKER_zero_signed_unchecked` morto; a parada nomeia a delegação nos três mundos (`0`, `0.00`,
  config que não fixa a chave) e `0.5` segue sendo teto.

## O que foi refutado

- **O `HANDOFF_DIR` também é lido só no checkout da campanha** (`campaign_mission_dirs`), e um
  worktree cujo config o mudasse esconderia uma missão do `next` e o gasto dela do `budget`. Não
  levantado: pede mudar o `HANDOFF_DIR` no meio de uma campanha, o que move todos os handoffs do
  repo, e não construí esse mundo. Hipótese sem reprodução não vira `R<n>`.
- **O `|| true` do `checkouts_of` lê só a raiz quando o `git worktree list` falha**, e o R3 voltaria
  em silêncio. Não levantado: o `--porcelain` existe desde o git 2.7, e com uma raiz válida não achei
  falha que o produza; um worktree podado sai como `prunable` e o arquivo ausente dele não muda nada.
- **Uma linha de `BUDGET_MISSION_USD` escrita durante a corrida**, por uma sessão do lote ou pelo
  `git merge origin/<base>` do ato `review`, é relida pelo `config_reload` do runner a cada volta e
  o `budget` não a vê. Não reproduzido, e o conserto é o lado do runner que a r1 e a r2 já deixaram
  ao dono (pendência 3).
- **A afirmação do `20-handoff-exec.md:155`, "Os 33 mutantes foram provados um a um com `--only`",
  como comportamento falso.** Refutada quanto ao método: os seis mutantes do R3 e do R4 foram
  provados um a um com `--only` nesta rodada, e os seis morrem. A conta (33, onde hoje são 39) está
  velha, e isso é prosa, que vai para a DOCS.

## Achados fora de escopo

- Nenhum registrado no backlog nesta rodada. As derivas de forma abaixo são prosa desta missão e
  vão para a DOCS dela, como a r1 e a r2 fizeram com as suas: um item no `TODO.md` nasceria e
  morreria no mesmo PR.

## Pendências / Decisions for a Human

1. **Para a DOCS, prosa só, nenhum `R`** (todas LOW, de forma, achadas pelos agentes do `codereview`
   e conferidas no código): o `docs/pipeline.md:1931`, o `config/schema.md:290` e o
   `templates/delegation.md:47` dizem que o teto zero para "before any file is read", e o `budget`
   lê o `delegation.md` e o `campaign.md` antes; o certo é "before any `.sdd/config.sh` is read".
   A célula rc do `budget` no `docs/pipeline.md:1913` não cita o teto zero. A dica do frontmatter
   do `templates/delegation.md:6` (e a cópia no `delegation.md` da campanha do kit) ainda fala de um
   `.sdd/config.sh` só e não diz que zero para. O parágrafo do `templates/delegation.md:47-50` tem uma
   linha órfã e uma frase cujas três alternativas se leem presas a "antes de cortar os worktrees". O
   `20-handoff-exec.md:155` diz 33 mutantes onde são 39. E seguem as derivas da r2: o
   `commands/sdd-worker.md:140` (o "no such key" sem antecedente e a linha fora da largura) e as da r1.
2. **O laço chegou ao platô na última rodada.** As letras da r3 são as da r2 (Error Handling,
   Test Coverage e Documentation em B), e não por falta de conserto: o R3 e o R4 fecharam o que a r2
   achou. Foi a mesma classe num sítio irmão: o R3 consertou o `budget` e deixou o `level`. Depois
   que o executor fechar o R5, o runner não abre uma r4 (`REVIEW_MAX_ITER=3`). O dono decide se uma
   rodada a mais roda (`--phase REVIEW` com o teto erguido) ou se a régua dele no PR basta. Pedido
   ao executor do R5: procure as outras leituras de config do `bin/sdd-worker` que o runner também
   faz no worktree e feche a classe, não o sítio (`grep -n 'config_key' bin/sdd-worker`).
3. **O lado do runner** segue como a r1 e a r2 o deixaram: o R1, o R3 e o R5 só fazem o worker
   falhar fechado. Fazer a delegação valer num alvo cujo config fixa a chave, ou cuja sessão a
   reescreve no meio da corrida, pede mexer na precedência de config do `bin/sdd`. A decisão é do dono.
