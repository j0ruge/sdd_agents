---
missao: 20261026-health-pula-catalogo
titulo: o `sdd health` pula o catálogo de mutação quando a chave do conteúdo já foi medida verde, e o carimbo e o mapa dos matadores passam a morar no `git-common-dir`, onde toda worktree do kit os lê e nenhum `git worktree remove` os apaga
data: 2026-10-26
versao:
branch: fix/health-pula-catalogo
aprovacao: humano-2026-10-26
adr: docs/adr/0021-the-stamp-lives-in-the-common-dir.md
ddd: n/a
qa:
kaizen_log:
---

# Missão — o `sdd health` pula o catálogo com a chave já medida

> Escrito pelo `sdd-planner` com o humano presente (relay do `/sdd-plan`, 2026-10-25 22:00 → 2026-10-26
> 00:20). É a única fonte da **intenção**; o `01-plano.md` é a fonte do **como**. Toda sessão começa
> lendo estes dois.
>
> ⚠️ **Missão do próprio kit: executada INTERATIVA, na worktree ligada
> `/home/pc_admin/repos/sdd_agents-health-pula-catalogo`, nunca por `sdd run` a partir do checkout
> principal** (ADR 0016 §2, `commands/sdd-plan.md` passo 2). Todo comando roda como
> `cd /home/pc_admin/repos/sdd_agents-health-pula-catalogo && …`; rascunho e medição vão para caminho
> absoluto fora do checkout principal (`/home/pc_admin/.wt/plan-health-pula-catalogo/` ou um `mktemp -d`),
> nunca para caminho relativo. Dentro da worktree, `health`, `preflight` e `install` rodam como
> `./bin/sdd`. O checkout principal `/home/pc_admin/repos/sdd_agents` é o kit que o `sdd` do PATH executa
> para os alvos: nada se escreve nele.

## Problema (Gemba)

O `sdd health` roda os 775 mutantes do catálogo **sempre**, mesmo quando a chave do carimbo já foi medida
verde: `cmd_health` (`bin/sdd:7258`) lê a chave antes (`:7304`) e chama `tests/run-all.sh --with-mutation`
sem condição (`:7313`). Só o `gate_PR` (`bin/sdd:2672–2706`) e a linha 6 do `--release` (`bin/sdd:7249`)
comparam chave e carimbo. Medido em 2026-10-25: **10 h 58 min**, 775/775 caught, sem mapa dos matadores,
para o PR #327 — um diff só de `TODO.md` e catraca, ambos fora da chave.

O pulo sozinho não bastaria, porque o carimbo e o mapa moram em diretórios ignorados **por checkout**
(`.sdd/logs/mutation-stamp`, `bin/sdd:2451`; `.sdd/cache/mutation-killers.tsv`,
`tests/check-mutation.sh:7550`; ADR 0016, Consequências), e o trabalho do kit é feito numa worktree por
missão (ADR 0016 §2), que nasce sem os dois e os perde no `git worktree remove`:

- dos **10** checkouts do kit nesta máquina (`git worktree list`, 2026-10-25), só o principal tem
  carimbo — `b04da602`, escrito às 21:17, **velho**: a chave da `main` é `05dc39fc` desde o #321 — e só
  ele tem o mapa (775 linhas; esta worktree recebeu uma cópia, ADR 0016);
- a chave medida pelo #327 é a da ponta da branch do #315, de 4 dias antes (`git diff --quiet` nas cinco
  pastas da chave: ponta do #315 = merge do #315 = base do #327 = merge do #327). A worktree do #327
  nasceu sem `.sdd/logs/`, então nem um pulo pelo carimbo local teria disparado ali;
- **34 de 40** commits de primeiro pai da `main` não movem a chave (`git diff --quiet P M -- bin tests
  templates config agents ':(exclude)tests/health-baseline.txt'`): em quase toda missão de `TODO.md` o
  catálogo é uma medida repetida;
- a volta do mapa e do carimbo ao checkout principal é passo **manual**, escrito em
  `docs/failure-modes.md:1104` e repetido ao humano pelo `/sdd-plan` (`commands/sdd-plan.md:49–54`,
  probe em `tests/check-hat.sh:581–593`).

"Só os mutantes novos" não serve: o destino de um mutante depende do `bin/sdd` inteiro e dos sensores
(o `103 caught of 104` entre os PRs #12 e #13, ADR 0004), e o `--touched` é dica, nunca veredito. O que a
missão aproveita é a confiança que o `gate_PR` **já** dá ao carimbo: chave igual ⇒ conteúdo medido igual.
O dono: "esperar 10hs para um teste de mutação não é aceitável".

A suíte rápida, que é o que o pulo passa a custar, foi medida nesta worktree em 2026-10-25 23:59 → 00:10:
`tests/run-all.sh` rc 0, **672 s**, 2046 linhas `ok`, 0 FAIL, máquina ociosa (8 núcleos, carga 0,04).

Achados do `TODO.md` que a missão fecha: o de prioridade (`TODO.md:26`, `bin/sdd:7311` (`--with-mutation`))
e o vizinho do mapa (`TODO.md:502`, `tests/check-mutation.sh:7550` (`KILLERS_FILE`)), absorvido pela
decisão 1.

## Métrica

- **M1 — o pulo (fato binário, sensor durável).** Com a chave no conjunto, o `sdd health` chama a suíte
  **sem** `--with-mutation`, termina com rc 0 e imprime a linha do pulo citando `--full`; com `--full`
  roda o catálogo. São as asserções `ok    skip: ` do `tests/check-health.sh`: **0 hoje, 5 depois** (I2).
- **M2 — o lugar compartilhado (fato binário, sensores duráveis).** A chave e o mapa que um checkout grava
  são lidos por uma worktree ligada do mesmo repositório — pelo pulo (`skip: a linked worktree skips…`,
  I2), pelo `gate_PR` (`stamp: gate_PR reads the key a linked worktree stamped…` do
  `tests/check-gates.sh`, 0 → 1, I1) e pelo catálogo (`killers: ` do `tests/check-mutation.sh --anchors`,
  0 → 1, I3); o `.sdd/logs/mutation-stamp` sozinho já não abre o `gate_PR` (mesma asserção do I1).
- **M3 — o número real (pós-merge, pendência do humano).** O primeiro `./bin/sdd health` no checkout
  principal depois do merge imprime a linha do pulo e termina em **≤ 20 min**, contra as **10 h 58** do
  #327. Vale quando nenhum outro PR moveu a chave entre o carimbo da missão e o merge.
- **M4 — sem regressão.** `tests/run-all.sh` verde no fim de cada incremento; a catraca `todo-findings`
  segue **61**; `bash tests/check-todo.sh --anchors TODO.md` → `0 off target` depois de cada incremento.

## Resultado esperado

O `sdd health` sobre um conteúdo cuja chave já foi medida verde roda só a suíte rápida (~11 min), a catraca
e as verificações estáticas, e diz que pulou o catálogo e que `--full` mede de novo. O carimbo vira um
conjunto de chaves medidas verdes em `<git-common-dir>/sdd-mutation/stamps/`, e o mapa dos matadores mora
em `<git-common-dir>/sdd-mutation/killers.tsv`; o checkout principal e toda worktree ligada leem e gravam o
mesmo lugar, então o `git worktree remove` não apaga nada que o catálogo mediu e o `/sdd-plan` deixa de
mandar o humano trazer mapa e carimbo de volta. Só o veredito do próprio catálogo apaga uma chave.

## Fora de escopo

- **Rodar só os mutantes novos, ou o `--touched` como veredito** — recusado pelo dono e pela ADR 0004 (o
  destino de um mutante depende do runner inteiro e dos sensores).
- **CI para o catálogo** — a ADR 0004 o descartou; segue decisão do humano.
- **Validade do carimbo por prazo ou por ambiente** (versão do bash, do shellcheck, do python): a chave só
  cobre conteúdo, e o `gate_PR` já confia nela sem prazo; o pulo herda exatamente essa confiança. Para
  desconfiar há o `--full` (decisão 2). Declarado na ADR.
- **Podar o conjunto de chaves** — cada chave é um arquivo de algumas dezenas de bytes; sem consumidor
  (régua D15), fica declarado.
- **Compartilhar entre clones ou máquinas** — o `git-common-dir` é de um clone só; outro clone mede de novo.
- **Duas rodadas do catálogo gravando o mapa no mesmo instante** — o `mv` é atômico e a união é lida na hora
  de gravar; perder uma linha numa corrida exata custa tempo, nunca veredito (o mapa é dica de ordem).
  Declarado.
- **`sdd run` criando worktree sozinho** — "needs its own design" (anatomia §6, ADR 0016 §2).
- **O incremento de quase 1 h fora do `sdd-executor`** (`TODO.md`, seção Custo e escala) — outro achado.
- **A documentação** (`docs/failure-modes.md`, `CLAUDE.md`, `CONTEXT.md`, `README.md`, `docs/pipeline.md`,
  as jornadas de `docs/qa/journeys/`, o `KAIZEN_LOG.md`) — é da fase DOCS; a lista está no `01-plano.md`.

## Gate PLAN-AUTO

Preenchido pelo `sdd-planner` **com evidência**. Todos ✅ → `aprovacao` fica vazio do mesmo jeito: o
humano lê o plano no passo de aceite do `/sdd-plan` e aprova com `sdd approve`. O `auto` só entra
quando o humano o pediu no grill, e aí o pipeline segue sozinho até o PR (ADR 0018 §3). Qualquer ✗ →
`aprovacao` fica vazio e o runner para pedindo aprovação humana explícita, nomeando o critério.

| # | Critério | Status | Evidência |
|---|---|---|---|
| a | Grill sem perguntas abertas não endereçadas (🚩 vazia ou itens deferidos com dono) | ✅ | 8 decisões, cada uma com a sua linha `- answer:`; o que ficou fora tem dono: o carimbo e a M3 com o humano (Pendências), a documentação com a fase DOCS (`01-plano.md` § Para a fase DOCS), o chore pós-merge do `TODO.md` com o humano |
| b | Checklist kaizen 100% ✅ e checklist DDD 100% ✅ ou `n/a` justificado | ✅ | K1–K8 ✅ abaixo; DDD `n/a` (artefatos de ferramenta do kit; o contrato entre `bin/sdd` e `check-mutation.sh` está na ADR 0021) |
| c | Plano passa no teste de autocontenção (sessão nova só com 00/01/checkpoint executa) | ✅ | o I1 nomeia a worktree e a regra do `cd`, as linhas de todo símbolo que lê ou edita, a grafia do `git-common-dir` e a prova dela, a receita da chave, a asserção que o Check lê, os mutantes e o `--only` que os prova, as âncoras do `TODO.md` e o `CAPTURE_FLOOR`; ver `01-plano.md` § Teste de autocontenção |
| d | Todo incremento do `checkpoint.md` tem Check executável (comando → esperado), vermelho no HEAD pelo `tests/check-checkpoint.sh --red` do kit | ✅ | 5 de 5 vermelhos no HEAD `c114e36` (I1 `0`→`1`, I2 `0`→`5`, I3 `0`→`1`, I4 `0`→`1`, I5 `0 0`→`2 0`); `tests/check-checkpoint.sh --check` rc 0 (`5 row(s), 4 under the anchor rule, none blind`) e `--red` rc 0 em 245 s |
| e | `versao:` confirmada pelo humano (ou `JIRA_ENABLED=false`) | ✅ | `JIRA_ENABLED=false` (`.sdd/config.sh` da worktree) |
| f | `adr:` é uma decisão — um caminho, ou o literal `none` (alocado por `sdd adr new`) | ✅ | `docs/adr/0021-the-stamp-lives-in-the-common-dir.md`, alocada por `./bin/sdd adr new` e com o corpo escrito (contexto medido, cinco decisões, sete descartadas); emenda 0004 e 0016, que ganharam o `Amended by`; `./bin/sdd adr check --mission 20261026-health-pula-catalogo --phase plan` → rc 0 |

## Checklist kaizen (`kaizen-software`)

> O K8 desta tabela é prosa: quem dispensa a entrada do KAIZEN_LOG.md é só o literal kaizen_log: skipped no frontmatter, decidido com o humano no grill.

| # | Item | Status | Nota |
|---|---|---|---|
| K1 | Gemba — fui ver onde o trabalho acontece | ✅ | `cmd_health`, `gate_PR`, a linha 6 do `--release`, os helpers da chave e o `KILLERS_FILE` lidos no HEAD; os 10 checkouts do kit varridos (chave, carimbo, mapa); a continuidade da chave do #315 ao #327 provada por `git diff --quiet`; 40 merges medidos; a suíte rápida rodada inteira (672 s) |
| K2 | Problema declarado com métrica | ✅ | M1–M4, cada uma com o número de antes (0 asserções; 10 h 58; 61 achados) |
| K3 | Desperdícios identificados e cortados | ✅ | retrabalho: o catálogo que re-mede conteúdo já medido (34 de 40 merges); espera: 10 h 58 por um diff de `TODO.md`; passo que depende de lembrar: a volta manual do mapa e do carimbo, trocada por poka-yoke (o lugar compartilhado torna o esquecimento impossível) em vez de mais uma regra escrita |
| K4 | Fatiamento incremental, cada fatia verificável | ✅ | 5 incrementos (decisão 7), cada Check vermelho no HEAD; o I1 não se parte porque a suíte ficaria vermelha entre as fatias |
| K5 | Check por artefato (rótulo ≠ artefato) | ✅ | toda Check lê a linha `ok` do sensor ancorada em `^  ok    `; o pulo é provado pelo argv que o stub da suíte gravou, nunca pelo texto do `bin/sdd` |
| K6 | Jidoka — o que para a linha está definido | ✅ | suíte rápida vermelha no pulo → `sdd health` rc 1 com as linhas FAIL (decisão 3); o `gate_PR` segue recusando sem chave; `tests/run-all.sh` no fim de cada incremento; `--anchors` do catálogo na suíte rápida |
| K7 | SDCA — a melhoria vira padrão (doc/rule/teste) | ✅ | asserções duráveis em `check-gates.sh`, `check-health.sh`, `check-mutation.sh` (selftest) e `check-hat.sh`; mutantes para cada regra nova de `bin/sdd`; ADR nova emendando 0004 e 0016; o `/sdd-plan` reescrito (I4) |
| K8 | Registro no KAIZEN_LOG | ✅ | entrada da fase DOCS citando o id da missão, com antes/depois (10 h 58 → pulo; volta manual → nenhuma) |

## Checklist DDD (`ddd`) — condicional

`n/a — sem toque de domínio`: o carimbo e o mapa são artefatos de ferramenta do próprio kit (um diretório
dentro do `git-common-dir`, um predicado em `bin/sdd`, um arquivo de dica de ordem). Nenhum aggregate,
contexto, evento de domínio ou entidade; o contrato entre os dois programas que o tocam (`bin/sdd` e
`tests/check-mutation.sh`) é decisão de arquitetura e vai na ADR.

## Decisões do grill (não re-litigar)

1. **O carimbo e o mapa moram no `git-common-dir`, que todas as worktrees compartilham.** O carimbo vira um
   conjunto de chaves já medidas verdes, um arquivo por chave, e um catálogo vermelho apaga a sua; o mapa é
   regravado por união. Resolve também o achado vizinho (`TODO.md:502`). Por quê: é a única opção que teria
   pulado o catálogo no #327 e que faz o carimbo e o mapa chegarem ao checkout principal sem passo manual
   nem ordem de remoção; ler das worktrees irmãs morre no `git worktree remove`, e o pulo pelo carimbo local
   não salvaria nenhuma worktree nova.
   - answer: (recommended)
2. **O `--with-mutation` continua sinônimo do padrão, e uma flag nova, `--full`, força o catálogo mesmo com
   a chave carimbada; a linha que anuncia o pulo cita o `--full`.** Verde regrava a chave, vermelho do
   catálogo a apaga. Por quê: o hábito escrito em 16 handoffs e no `CLAUDE.md:299` passa a ganhar o pulo;
   forçar fica explícito e nomeado; `rm` dentro de `.git/` não é remédio, e inverter o `--with-mutation`
   faria o hábito pagar as 11 h.
   - answer: (recommended)
3. **Só o veredito do catálogo sobre a chave a apaga** — censo divergente, gap, sobrevivente ou TIMED-OUT,
   numa rodada por chave nova ou por `--full`. Uma suíte rápida vermelha deixa o health vermelho (rc 1, com
   as linhas FAIL) mas não mexe na chave, no pulo e quando é o controle de uma rodada. Por quê: com a chave
   igual, o vermelho vem de fora dela (`TODO.md`, `docs/`) ou da máquina, e o `TEST_CMD` do `gate_REVIEW`
   (`bin/sdd:2088`) já o barra; um `TODO.md` torto numa worktree não pode custar o catálogo a todo checkout
   com o mesmo conteúdo.
   - answer: (recommended)
4. **O mapa compartilhado usa o legado local como semente, e o carimbo legado deixa de existir.** Ao ler, o
   `check-mutation.sh` junta o mapa do `git-common-dir` com o `.sdd/cache/mutation-killers.tsv` do checkout,
   se houver; onde os dois conhecem o mutante, vale o compartilhado; a gravação vai só para o compartilhado.
   Ninguém mais lê nem grava o `.sdd/logs/mutation-stamp`. Por quê: as 775 linhas do principal chegam ao
   compartilhado na primeira rodada sem passo manual, e o carimbo tem um lugar só, que é o que a decisão 3
   precisa.
   - answer: (recommended)
5. **A métrica: M1 e M2 como fatos binários nos sensores, M3 (≤ 20 min no checkout principal depois do
   merge) nas pendências do humano.** Por quê: M1 e M2 viram sensores duráveis; o número real depende do
   catálogo da missão, que é do operador depois dos bots (ADR 0015 §1), e como incremento seria um
   `pending` que nunca fecha; 20 min dá folga à suíte de 672 s numa máquina carregada.
   - answer: (recommended)
6. **O id é `20261026-health-pula-catalogo` e a branch `fix/health-pula-catalogo`.** Por quê: o mesmo slug
   da worktree, e `fix/` porque o produto é o conserto de dois achados registrados, como os lotes `fix/lote-*`.
   A branch provisória `plan/health-pula-catalogo` foi renomeada pelo planner (`git branch -m`) antes de ter
   upstream.
   - answer: (recommended)
7. **Cinco incrementos, nesta ordem: I1 o carimbo no `git-common-dir`; I2 o pulo (`--full` e a regra da
   decisão 3); I3 o mapa; I4 o `/sdd-plan` para de mandar trazer mapa e carimbo de volta; I5 o fecho
   (`RESOLVED by` nos dois achados, âncoras medidas de novo).** Por quê: o pulo depende do lugar novo, cada
   fatia tem um vermelho de uma frase e deixa a suíte verde; o I1 não se parte, porque a suíte ficaria
   vermelha entre a mudança do lugar e a migração dos fixtures do `check-gates.sh`.
   - answer: (recommended)
8. **`aprovacao:` fica vazio: o humano lê o plano no passo de aceite do `/sdd-plan` e aprova com
   `sdd approve`.** Por quê: a missão muda o que abre o `gate_PR` e estreita uma consequência da ADR 0004.
   - answer: (recommended)

Decididos pelo planner, derivados das oito acima e escritos no `01-plano.md` § Arquitetura (não
re-litigar): o lugar exato (`<git-common-dir>/sdd-mutation/stamps/<chave>` e
`<git-common-dir>/sdd-mutation/killers.tsv`, pelo precedente do `sdd-coordination.lock` na raiz do git
dir); gravar a chave só com o catálogo **todo** verde (suíte e score, como o `catalogue_green` de hoje);
a janela (chave que se moveu durante a rodada) não grava nem apaga nada; `--full` com `--release` é
recusado pelo nome; o pulo também recusa a janela.

## Pendências para o humano

- **O carimbo da missão, uma vez, depois dos bots** (ADR 0015 §1; `CLAUDE.md` "Depois do último commit de
  código"): `cd /home/pc_admin/repos/sdd_agents-health-pula-catalogo && ./bin/sdd health`, com o
  `bin/sdd` **da branch**, que já grava a chave em `/home/pc_admin/repos/sdd_agents/.git/sdd-mutation/` e
  lê o mapa de 775 linhas desta worktree como semente. A `main` está velha desde o #321, então este
  catálogo é pago de qualquer jeito (com o mapa, cerca de metade das 10 h 58).
- **M3, depois do merge:** no checkout principal, já avançado para o merge, `./bin/sdd health` → a linha do
  pulo e ≤ 20 min. Se outro PR mover a chave entre o carimbo e o merge, o catálogo roda (legítimo) e a M3
  se mede no próximo merge que não mova a chave.
- **Chore pós-merge do `TODO.md`:** apagar os dois itens com `RESOLVED by` quando o hash estiver na `main`
  (ciclo de vida do `templates/todo.pt-BR.md`) e sincronizar o espelho de issues.
- **O que o PLAN deixou fora de commit**, de propósito: a ADR `docs/adr/0021-the-stamp-lives-in-the-common-dir.md`
  (nova) e as linhas `Amended by: … 0021` das ADRs 0004 e 0016 — o `sdd approve` commita só a pasta da missão, então
  elas entram num commit próprio (`docs(adr): 0021 …`) logo depois dele, antes do I1.
- **A linha `RECURRED 6`** do achado "O `/sdd-plan` delega ao `sdd-planner` sem saída para o agente não
  registrado" (`TODO.md:225`, esta missão também rodou o planner como agente genérico) está na árvore da
  worktree, **sem commit**, por ordem do humano: entra no commit dos achados depois do `sdd approve`.
