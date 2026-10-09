---
missao: 20261008-lote-6-as-quatro-que-faltam
titulo: o lote 6 fecha as quatro issues abertas do kit (#238, #239, #236, #240) e o F8 da gaveta, cada uma com um sensor que fica vermelho no defeito — e o `sdd kaizen` deixa de escrever no checkout que os `sdd run` dos alvos executam
data: 2026-10-08
versao: n/a (JIRA_ENABLED=false)
branch: fix/lote-6-as-quatro-que-faltam
aprovacao: humano-2026-10-08
adr: docs/adr/0017-kaizen-refuses-the-checkout-the-targets-run.md
ddd: aplicado
---

# Missão — Lote 6: as quatro que faltam

> Escrito pelo `sdd-planner` com o humano presente, via a sessão coordenadora (o relay do
> `/sdd-plan`), que repassou seis perguntas de grill em 2026-10-08. É a única fonte da **intenção**;
> o `01-plano.md` é a fonte do **como**. Toda sessão que executar esta missão começa lendo estes
> dois, mais o `checkpoint.md`.

## Problema (Gemba)

O lote 5 (`fc32329`, PR #243) deixou quatro achados abertos no `TODO.md`, espelhados nas issues
#236, #238, #239 e #240 (label `todo`; catraca `todo-findings` 4). A gaveta do kit
(`docs/superpowers/specs/2026-09-23-a-gaveta-do-kit.md` § F8) guarda um quinto, fora do `TODO.md`
por decisão humana. Tudo abaixo foi medido no worktree `/home/joruge/repos/sdd_agents-lote-6`, HEAD
`fc32329`, em 2026-10-08.

- **#238 — o censo do `GIT_DIR` não vê o git chamado por caminho nem por variável.** A regex do
  `gitenv_census` (`tests/check-health.sh:1741`, função em `:1733`) é
  `(^|[^[:alnum:]_.\/-])git([^[:alnum:]_-]|$)`: a classe da esquerda exclui `/`, então
  `/usr/bin/git init` antes do `source` do `tests/isolate-git.sh` não conta, e `"$GIT" init` não
  contém a palavra. Falha aberta **sem caso hoje**: nos 17 pontos de entrada (`run-all.sh` e os 16
  `check-*.sh`), a única linha que não é comentário acima do `source` é o `set … pipefail` (medido).
- **#239 — a cerca dos dois leitores de bug fecha em qualquer marcador.** `bug_decision_recorded`
  (`bin/sdd:1558`, cerca em `:1560`) e o extrator do gênero do `gate_QA` (`bin/sdd:1708`) alternam
  o estado em qualquer linha `(```|~~~)`. No CommonMark só o mesmo caractere, com comprimento ≥ ao da
  abertura e nada depois, fecha a cerca. Um `## Decision` datado de exemplo, depois de um `~~~`
  dentro de crases, conta como a decisão humana (falha aberta, sem caso real; Codex no PR #237). O
  terceiro leitor de cerca do runner, o do `gate_DOCS` (`bin/sdd:2194–2210`), **já é** CommonMark
  desde o PR #176 e tem três mutantes (`DOCS_fence_closes_on_*`): os dois leitores de bug nasceram
  depois e copiaram a forma frouxa. O defeito é a deriva entre cópias. Yokoten medido: os outros
  leitores de cerca do kit (`tests/check-todo.sh:561`, que recusa qualquer cerca sem alternar, e
  `tests/check-templates.sh:475`, que lê forma) não são da classe.
- **#240 — a guarda de kit passa o kit sujo inteiro por variável de ambiente.** `kit_guard_tree`
  (`bin/sdd:3984`) entrega digests, bits e links ao `awk` por `KG_SUMS`/`KG_EXECS`/`KG_LINKS`
  (`:4017`), e `kit_guard_changes` (`:4047`) entrega a árvore anterior por `KG_BEFORE`. Uma variável
  aceita no máximo **131 063 B** de valor (medido: 131 064 dá `Argument list too long`). Reproduzido
  sobre as funções extraídas do `bin/sdd`: um kit com **1800** caminhos não rastreados de 60 bytes
  faz o `kit_guard_tree` sair **rc 126** (`Argument list too long`), e o `sdd run` do alvo morre no
  `kit_guard_arm`, antes da sessão; com 801 caminhos, rc 0. O mesmo canal parte um nome com `\n`:
  `hat_status_lines` (`bin/sdd:4357`) lê `-z` e imprime `\n`, e a árvore de um kit com
  `notes<LF>draft.md` sujo sai `?? notes<TAB>-` + `draft.md<TAB>-`, **igual** antes e depois de
  uma edição nele (reproduzido): a guarda não vê. Yokoten medido: os outros sete `ENVIRON[...]` do
  runner carregam valor curto (uma chave, um valor de frontmatter, uma nota), não a árvore.
- **#236 — o `sdd kaizen` escreve e commita onde os alvos executam.** O `cmd_kaizen`
  (`bin/sdd:10917`) compara a identidade do kit pelo diretório git comum (`:10970–10977`, issue
  121), então um worktree ligado do kit **já** passa. Nada recusa o checkout para onde o `sdd` do
  PATH resolve (`readlink -f "$(command -v sdd)"` → `/home/joruge/repos/sdd_agents/bin/sdd`): ali
  ele só avisa (`warn_if_on_base_branch`), e a sessão KAIZEN escreve o veredito e o plano e commita.
  Com um `sdd run` de alvo em voo, a guarda de kit para o alvo com `KIT-TOUCHED`, o mesmo vetor
  da ADR 0016 §2 (que decidiu a missão do kit e deixou o `sdd kaizen` de fora, decisão 11b do lote 5).
  Lido no código, não reproduzido ponta a ponta.
- **F8 — o plano mede contra a base, não contra o disco dos incrementos anteriores.** A frase não
  está no `agents/sdd-planner.md` (medido). Esta missão é um caso vivo: os quatro símbolos que as
  âncoras do `TODO.md` designam (`gitenv_census`, `bug_decision_recorded`, `KG_SUMS`, `cmd_kaizen`)
  são exatamente os que os consertos editam ou deslocam, e o `tests/check-todo.sh` (no `TEST_CMD`)
  reprova âncora aberta fora do alvo, `RESOLVED by` incluído.

## Métrica

Fato binário, cada um por comando (o detalhe e o "antes" de cada Check estão no `01-plano.md`):

1. Os seis Checks do `checkpoint.md` (I1–I6) leem as linhas `^  ok    ` novas dos sensores, e cada
   asserção nova é vista **vermelha pelo motivo certo** antes do conserto.
2. Antes → depois, medidos pelos regimes novos:
   - kit com milhares de caminhos sujos: o `sdd run` do alvo morre antes da sessão → a sessão abre,
     a edição no kit para a linha e o kit deixado em paz fica calado;
   - nome sujo com `\n` editado durante a fase do alvo: calado → `kit-touched`, com o nome dito;
   - `sdd kaizen` no checkout que o `sdd` do PATH executa: abre a sessão → recusa (rc 1) antes dela,
     nomeando o `git worktree add`; do worktree ligado, admitido;
   - bug `deferred` cujo exemplo cercado por crases traz `~~~` e um `## Decision` datado: passa a QA →
     barra; o mesmo no extrator do gênero.
3. O I7 fecha com `4 1 1 1 1`: quatro `RESOLVED by` na seção aberta do `TODO.md`, a entrada
   `— Lote 6: as quatro que faltam` no `KAIZEN_LOG.md`, a ADR 0017 `accepted`, a ADR 0016 com
   `Amended by` 0017 e o `20-handoff-exec.md` escrito.
4. `./bin/sdd adr check --mission 20261008-lote-6-as-quatro-que-faltam --phase plan` → rc 0.
5. `tests/run-all.sh` verde no topo da branch, `catalogue anchors: every mutant still applies`, e
   um carimbo do `./bin/sdd health` depois de todos os revisores.
6. Catraca `todo-findings`: 4 na branch (os 4 com `RESOLVED by`) + N nascidos na leva → N depois do
   chore pós-merge.

## Resultado esperado

O backlog aberto do kit vai a zero no chore pós-merge (mais o que esta leva registrar). O censo do
`GIT_DIR` vê o git chamado por caminho ou por `$GIT`. Os três leitores de cerca do runner leem
**uma** definição CommonMark (`FENCE_AWK`), e um exemplo cercado não vira mais decisão nem gênero.
A guarda de kit aguenta milhares de caminhos sujos e vê o nome com `\n`. O `sdd kaizen` recusa o
checkout que os alvos executam e manda para o worktree ligado (ADR 0017). O `sdd-planner` passa a
medir cada incremento contra o disco que os anteriores deixam. Depois do merge, o kit **congela**
até o veredito da próxima janela do juiz.

## Fora de escopo

- **O `\n` no nome dentro da guarda do chapéu** (decisão 5). O resíduo continua declarado em
  `bin/sdd:4205–4211`, nas duas metades (o `git diff --name-only` aspeia o nome; o status o parte).
  A guarda do chapéu continua lendo `hat_status_lines` no modo `\n`.
- **O runner criar worktree** — nem no `sdd kaizen` (decisão 1, ADR 0017) nem no laço do `sdd run`
  (ADR 0016 §2, anatomia §6). O `sdd kaizen` recusa e nomeia o comando; quem cria é o humano.
- **As outras sutilezas do CommonMark** que nenhum leitor de hoje precisou: indentação de 4+ espaços
  (bloco indentado, não cerca) e crase dentro da info string. Ficam declaradas no comentário do
  `FENCE_AWK`, como já estavam no `gate_DOCS`.
- **O congelamento em si** (decisão 6) acontece no merge, fora da tabela: é pendência do humano.
- **Achado nascido no meio da leva:** passa pela régua D15 e vai ao `TODO.md` com catraca +1 no
  mesmo commit. Não é consertado aqui. Defeito criado pela própria leva se conserta nela.

## Gate PLAN-AUTO

Preenchido pelo `sdd-planner` **com evidência**. Todos ✅ → `aprovacao: auto` e o pipeline segue
sozinho. Qualquer ✗ → `aprovacao` fica vazio e o runner para pedindo aprovação humana explícita.

⚠️ `aprovacao:` fica **vazia** de propósito, qualquer que seja o resultado desta tabela. A missão é
executada interativamente no worktree, e quem fecha o gate é o humano: o relay pergunta YES/NO e
roda `sdd approve` (decisão 7 do lote 4, `commands/sdd-plan.md` § When the artifacts exist).

| # | Critério | Status | Evidência |
|---|---|---|---|
| a | Grill sem perguntas abertas não endereçadas (🚩 vazia ou itens deferidos com dono) | ✅ | O humano respondeu, via relay, às 6 perguntas (§ Decisões do grill, 1–6). Nenhuma 🚩 aberta. As pendências têm dono, o humano (§ Pendências): o momento do health, o merge, o chore, o re-sync, o congelamento, o yokoten, a remoção do worktree. As decisões de desenho do planner (§ Decisões do planner) estão marcadas como tais, com o porquê. |
| b | Checklist kaizen 100% ✅ e checklist DDD 100% ✅ ou `n/a` justificado | ✅ | K1–K8 todos ✅ (tabela abaixo). DDD acionado (um contrato de CLI e uma definição compartilhada por três leitores), D1–D6 ✅. |
| c | Plano passa no teste de autocontenção (sessão nova só com 00/01/checkpoint executa) | ✅ | Um subagente sem memória leu só os 3 arquivos e o código do worktree, sem rodar nada que escreve, e simulou I1, I2, I3 e I5. Veredito: "yes, with caveats". Ele conferiu 46 fatos citados: 37 bateram e 9 tinham linha deslocada ou descrição imprecisa (a regex do censo em `:1741`, o controle em `:1828–1841`, o awk do `gate_DOCS` em `:2198–2212`, o fim do `kit_guard_tree` em `:4033` e do `kit_guard_changes` em `:4064`, a faixa dos 15 mutantes em `:4120–4207`, a recusa de identidade em `:10970–10977`, o `$FIX` = `$OUTSIDE/fix`, o heading do pipeline em `:1431`), todos corrigidos. As 12 ressalvas foram fechadas no plano: (1) a linha do `check-gitdir.sh` que faz cada afrouxamento do censo nomeá-la; (2) os comentários do mundo de 5; (3) três mundos positivos de cerca fechada, porque a cerca que nunca fecha sobrevivia (Check do I2 4 → 7); (4) apóstrofo proibido no `FENCE_AWK`; (5) os vizinhos sem faixa do extrator; (6) o `kaizen_reminder`, que apontava para o checkout recusado (P6); (7) o texto do remédio alinhado com a ADR; (8) o `SDD_STATE_DIR` novo e o `loud_stub` antes, porque o `$OUTSIDE/state` daria Red falso; (9) o mundo sem `sdd` no PATH (Check do I3 5 → 6, +1 mutante) e o ramo do `readlink` declarado; (10) o bulk do 2k estourando os quatro canais (1000 executáveis + 700 symlinks de ~200 B); (11) o `mapfile -d ''` do I6; (12) a Métrica 3 com cinco termos e o corpo do #240 reescrito para o `RESOLVED by` caber. |
| d | Todo incremento do `checkpoint.md` tem Check executável (comando → esperado), vermelho no HEAD pelo `tests/check-checkpoint.sh --red` do kit | ✅ | 7 de 7 linhas na forma estrita. `tests/check-checkpoint.sh --check <este checkpoint>` → `7 row(s), 6 under the anchor rule, none blind`, rc 0. `--red` no worktree (HEAD `fc32329` + o plano, 12:28–12:39, 612 s) → `7 pending Check(s), every one red at HEAD`, rc 0. Os antes: I1 `0`/`1`, I2 `0`/`7`, I3 `0`/`6`, I4 `0`/`1`, I5 `0`/`1`, I6 `0`/`1`, I7 `0 0 0 0 0`/`4 1 1 1 1`. Uma primeira medição (11:33–11:43, 605 s) deu os mesmos antes com o I2 esperando `4` e o I3 `5`. Os esperados subiram depois do teste de autocontenção (critério c), e o `--red` rodou de novo. |
| e | `versao:` confirmada pelo humano (ou `JIRA_ENABLED=false`) | ✅ | `JIRA_ENABLED=false` (`.sdd/config.sh`), `versao: n/a`. |
| f | `adr:` é uma decisão — um caminho, ou o literal `none` (alocado por `sdd adr new`) | ✅ | `adr: docs/adr/0017-kaizen-refuses-the-checkout-the-targets-run.md`, alocada por `./bin/sdd adr new` do worktree (decisão 1). O corpo, em inglês (P4), traz o contexto medido, a decisão, quatro alternativas descartadas e as consequências, com dois limites declarados; `tests/check-lang.sh` passa sobre ela. `./bin/sdd adr check --mission 20261008-lote-6-as-quatro-que-faltam --phase plan` → `ok … and that ADR points back`, rc 0. |

## Checklist kaizen (`kaizen-software`)

| # | Item | Status | Nota |
|---|---|---|---|
| K1 | Gemba — fui ver onde o trabalho acontece | ✅ | As quatro âncoras conferidas no código do worktree (`fc32329`). **#240 reproduzida** sobre as funções extraídas do `bin/sdd` (1800 caminhos → rc 126; 801 → rc 0; o nome com `\n` dá a mesma árvore antes e depois da edição), e o limite por variável medido isolado (131 063 B). **#238** medida nos 17 pontos de entrada (só o `set` acima do `source`). **#239**: o terceiro leitor, o do `gate_DOCS`, já é CommonMark, o que mudou a direção (uma definição, decisão 3). **#236** lida no código; o worktree ligado já é admitido hoje (probe `kit-repo guard: a linked worktree of the kit…` do `check-kaizen.sh`). Yokoten medido para #239 (os outros leitores de cerca não alternam) e para #240 (os outros `ENVIRON` são curtos). Suíte verde no HEAD do worktree antes de planejar. |
| K2 | Problema declarado com métrica | ✅ | § Métrica: seis Checks por presença da linha `ok`, quatro antes/depois medidos pelos regimes, o `4 1 1 1` do I7, `adr check` rc 0, suíte e carimbo, catraca. Tudo por comando. |
| K3 | Desperdícios identificados e cortados | ✅ | **Espera:** um PR, um carimbo, uma rodada de revisão para as quatro (decisão 2); o mapa de assassinos de 676 já copiado para o `.sdd/cache/` do worktree (a 1ª corrida não custa 2×). **Superprocessamento recusado:** o runner criar worktree (decisão 1); o `\n` na guarda do chapéu (decisão 5); um segundo parser de `git status -z` (decisão 5); três cópias da cerca (decisão 3). **Defeito:** reprodução antes do plano, e os mutantes que cada incremento reancora estão listados por nome. |
| K4 | Fatiamento incremental, cada fatia verificável | ✅ | Sete incrementos de uma sessão cada, um item por incremento, a #240 em duas fatias (transporte, depois nome) e por último (decisão 2). Cada Check tem o "antes" medido pelo `--red` e anotado na seção do incremento. |
| K5 | Check por artefato (rótulo ≠ artefato) | ✅ | Os Checks I1–I6 leem a linha `^  ok    ` do sensor por herestring; o I7 lê os arquivos por `awk`. `tests/check-checkpoint.sh --check` e `--red` sobre este checkpoint estão no critério d. Mutantes provados com `--only`; a regra do I1 (em `tests/`, fora do alcance do catálogo) e a do I4 (em `agents/`) são provadas por passada de sabotagem anotada. |
| K6 | Jidoka — o que para a linha está definido | ✅ | Sensor vermelho para o commit. Âncora do `TODO.md` fora do alvo para o commit (`check-todo.sh` no `TEST_CMD`), e cada incremento diz quais âncoras desloca. Mutante que não aplica mais para o commit (`--anchors` na suíte rápida). No produto: a guarda de kit passa a parar a linha onde morria (I5) ou calava (I6), e o `sdd kaizen` para antes da sessão (I3). |
| K7 | SDCA — a melhoria vira padrão (doc/rule/teste) | ✅ | Todo conserto entra com probe durável e, em `bin/`, com mutante. A cerca vira uma definição (poka-yoke contra a próxima cópia frouxa). A regra do `sdd kaizen` vira recusa do runner (não frase), mais a ADR 0017 e a anatomia §6. O F8 vira frase do chapéu **com** probe no `check-hat.sh` (decisão 4). |
| K8 | Registro no KAIZEN_LOG | ✅ | Planejado no I7: o Check exige a entrada `— Lote 6: as quatro que faltam` no `KAIZEN_LOG.md`. |

## Checklist DDD (`ddd`) — condicional

Acionado, e não `n/a`. A leva muda o contrato de um comando com o humano (`sdd kaizen`) e funde três
cópias de uma regra numa definição publicada a três leitores. Nenhum evento novo entra no ledger e
nenhuma entidade nova aparece.

| # | Item | Status | Nota |
|---|---|---|---|
| D1 | Linguagem ubíqua nomeada | ✅ | **Checkout que os alvos executam:** o checkout para onde o `sdd` do PATH resolve (ADR 0016 §2, ADR 0017). **Cerca CommonMark:** abre em 3+ crases ou tis, fecha só com o mesmo caractere, comprimento ≥ e nada depois (`FENCE_AWK`). **Árvore suja do kit:** um registro por caminho, com o nome **codificado** quando ele traz `\`, LF ou CR (I6). O verbete da janela de medição do `CONTEXT.md` muda no I3. |
| D2 | Fronteira do contexto | ✅ | A cerca é lida só dentro do runner (os três leitores do `bin/sdd`); os sensores de markdown (`check-todo.sh`, `check-templates.sh`) têm a regra deles, de propósito. A árvore do kit é escrita e lida só por `kit_guard_tree`/`kit_guard_changes`/`kit_guard_check`; a guarda do chapéu continua no modo `\n` do mesmo parser. O `sdd kaizen` lê o PATH só para decidir se recusa. |
| D3 | Invariante | ✅ | (i) Um exemplo dentro de uma cerca nunca vira decisão nem gênero, qualquer que seja o marcador que ele traga. (ii) Uma edição no kit durante a fase de um alvo nunca passa calada nem mata o `sdd run`, qualquer que seja o tamanho da sujeira ou o nome do caminho. (iii) Nenhuma sessão KAIZEN abre no checkout que os alvos executam. |
| D4 | Eventos | ✅ | Nenhum evento novo no ledger e nenhum `kind` novo: a recusa do `sdd kaizen` é `die` antes da sessão (sem linha de ledger, como a recusa de identidade que já existe ao lado). |
| D5 | Contrato entre módulos | ✅ | `sdd kaizen`: o README, o `docs/pipeline.md` § The kaizen loop, o `docs/failure-modes.md`, o `CONTEXT.md` (verbete da janela), o lembrete de fim de corrida (`kaizen_reminder`, P6) e a anatomia §6 mudam no mesmo commit do I3. `FENCE_AWK`: os três leitores mudam no mesmo commit do I2, e os mutantes de condição passam a sabotar a definição única. `hat_status_lines -z`: um parser, dois modos; o chapéu não muda de modo (I6). F8: o `agents/sdd-planner.md` e o espelho `.claude/agents/` no mesmo commit, por `./bin/sdd install --force` (I4). |
| D6 | Decisão registrada | ✅ | ADR 0017 (`sdd kaizen` recusa o checkout que os alvos executam; emenda a 0016 §2). As outras três são consertos na direção já escrita nas issues e decidida no grill (decisões 3 e 5), sem trade-off arquitetural novo. |

## Decisões do grill (não re-litigar)

1. **#236: o `sdd kaizen` recusa rodar no checkout que o `sdd` do PATH executa, e nomeia o worktree.**
   O teste é o do passo 2 do `/sdd-plan`: `readlink -f "$(command -v sdd)"` dentro do `REPO_ROOT`.
   A mensagem traz o `git worktree add`. O `--series` continua livre (só leitura). ADR 0017 curta,
   que emenda a 0016 §2, mais um probe no `check-kaizen.sh` e um mutante. — Porquê: é o menor
   conserto que fecha o vetor, e o worktree ligado já é admitido hoje (issue 121). Criar o worktree
   mexeria na posse do checkout e trocaria o `REPO_ROOT` no meio do comando, o que a ADR 0016 diz
   pedir desenho próprio. (humano, "A, recusar e nomear (Recomendado)", 2026-10-08)
2. **#240 entra neste lote, como as últimas fatias.** Um PR, um carimbo e uma rodada de revisão para
   as quatro; os incrementos da #240 vêm por último e se revertem sozinhos. — Porquê: a direção já
   foi fechada na retro de 2026-10-07, e a falha de hoje é fechada (sem gasto), o que não justifica
   pagar um segundo carimbo (~1 h) e uma segunda espera dos bots. (humano, "A, no lote, por último
   (Recomendado)", 2026-10-08)
3. **#239: um fragmento `FENCE_AWK` usado pelos três leitores de cerca do runner** (os dois de bug e
   o do `gate_DOCS`). Os mutantes de condição do `gate_DOCS` são reancorados no fragmento; cada leitor
   mantém um mutante de chamada próprio; os testes ganham os mundos "til dentro de crases" e "fecho
   mais curto" nos dois leitores de bug. — Porquê: o defeito da #239 **é** a deriva entre cópias
   (o `gate_DOCS` foi consertado no PR #176, e os leitores de bug nasceram depois com a forma
   frouxa); uma definição fecha a causa. (humano, "A, um fragmento FENCE_AWK (Recomendado)",
   2026-10-08)
4. **O F8 da gaveta entra como incremento pequeno, com probe `hat:` no `check-hat.sh` segurando a
   frase.** — Porquê: a lição foi paga duas vezes (lote 4, e o planejamento deste lote), e o custo
   marginal neste PR é quase zero; frase sem probe a próxima edição apaga calada. (humano, "A, entra
   com probe no check-hat (Recomendado)", 2026-10-08)
5. **#240: o conserto do `\n` vale só para a guarda de kit; o parser continua um só, com um modo
   NUL.** O `hat_status_lines` ganha uma saída `-z`, a dobra do ORIG_PATH continua num lugar só, o
   `kit_guard_tree` lê essa saída, e a guarda do chapéu continua no modo `\n` com o resíduo
   declarado. — Porquê: fecha a issue inteira sem abrir uma segunda frente nas quatro portas do
   chapéu; um parser NUL próprio seria a deriva que a decisão 3 recusa. (humano, "A, só kit; parser
   único com modo NUL (Recomendado)", 2026-10-08)
6. **Congelar o kit no merge deste lote, até o veredito do juiz.** Achado novo vai só ao `TODO.md`
   (que desde a ADR 0014 não parte a janela), e a frente seguinte da gaveta (F1-P1 com ADR) espera.
   — Porquê: o backlog zerado é o momento mais barato de congelar; o último veredito é de 2026-09-28
   (`melhorou` sobre `4fd0f31`, PR #175), e a série de hoje tem a última fatia em `94123a4` com 1
   missão e `window_broken: true` (`./bin/sdd kaizen --series`). (humano, "A, congelar no merge
   (Recomendado)", 2026-10-08)

## Decisões do planner (de desenho, com o porquê; o humano pode revê-las no YES/NO)

- **P1 — o `--dry-run` do `sdd kaizen` não recusa no checkout dos alvos: avisa e projeta.** A
  projeção não abre sessão nem escreve, e o `CONTEXT.md` (verbete da janela de medição) recomenda o
  `sdd kaizen --dry-run` como a espiada read-only durante a janela, que a decisão 6 abre. Recusar a
  projeção obrigaria um worktree para espiar. O aviso diz a mesma frase da recusa, então a projeção
  continua dizendo o que a corrida real faria. ⚠️ No turno das decisões 5 e 6 o planner disse ao relay
  que o `--dry-run` também recusaria; a medição do `CONTEXT.md` mudou isso.
  Confirmada pelo humano depois do resumo do plano. (humano, "A, avisar e projetar (Recomendado)",
  2026-10-08)
- **P2 — o que conta como git no censo (#238):** um caminho terminado em `/git` (`/usr/bin/git`,
  `"$ROOT/bin/git"`) e a variável `GIT` exata (`$GIT`, `${GIT}`, `"$GIT"`). `$GIT_DIR` e afins
  **não** contam. Variável de nome arbitrário (`"$g"`) é indecidível numa regex de linha e fica como
  limite declarado no comentário do censo, como o operando variável do `cd` na RULE 2 do
  `check-pipefail.sh`.
- **P3 — a #240 em duas fatias:** I5 tira o canal do ambiente (o Red é o `sdd run` que morre), I6
  leva o nome inteiro até o `awk` e o codifica na árvore publicada (o Red é a edição calada). Os dois
  Reds são diferentes, e o I5 sozinho já fecha a falha alta.
- **P4 — a ADR 0017 em inglês.** O `tests/check-lang.sh` lê `docs/adr/` como superfície inglesa, e
  as ADRs 0015 e 0016 são inglesas; o desencontro com o stub do `sdd adr new` é limite declarado na
  seção decidida do `TODO.md`.
- **P6 — o lembrete de fim de corrida muda junto (#236).** O `kaizen_reminder` (`bin/sdd:10695`)
  diz "run 'sdd kaizen' in the kit repo ($SDD_HOME)" nas duas frases, e de um alvo o `$SDD_HOME` é
  justamente o checkout que o I3 passa a recusar. As duas frases passam a mandar rodar o juiz de um
  worktree ligado do kit, mantendo o trecho "run 'sdd kaizen' in the kit repo" que a asserção de
  `tests/check-kaizen.sh:1243` lê; a asserção ganha o termo "linked worktree". Achado pelo teste de
  autocontenção, não pelo grill: é consequência direta da decisão 1, e por isso entra sem pergunta.
- **P5 — nomes:** missão `20261008-lote-6-as-quatro-que-faltam`, branch
  `fix/lote-6-as-quatro-que-faltam`, cortada de `origin/main` = `fc32329` pelo relay antes do grill.
  O escopo não mudou no grill (as quatro entraram), então o nome continua servindo.

## Pendências para o humano

- **O momento do `sdd health`:** uma vez, depois de **todos** os revisores e da leva única de
  consertos, no worktree (`./bin/sdd health`, lançado pelo
  `~/.claude/plans/2026-10-03-helpers/health-launch.py`; ~56 min para 676 mutantes com carga 1,3).
  Antes do carimbo, conferir o status `CodeRabbit` do HEAD (`Review rate limited` = não revisou).
- **Merge do PR** e, depois dele, o chore pós-merge: apagar os 4 itens `RESOLVED by` com
  `todo_rm.py` (cada hash provado por `git merge-base --is-ancestor` contra `origin/main`), catraca
  4 + N → N, e o re-sync do espelho de issues da `main` (`todo-to-github-issues`, `--apply
  --close-orphans`): #236, #238, #239 e #240 fecham.
- **Congelar o kit no merge (decisão 6).** A janela seguinte abre no primeiro carimbo de alvo depois
  do merge; nada em `bin agents templates config` até o veredito; o `sdd kaizen` roda de um
  worktree ligado (ADR 0017). A gaveta (§ F3 e índice) registra o congelamento no I7.
- **Yokoten no sales_quote:** o `agents/sdd-planner.md` muda (I4). `sdd install --force` numa
  branch `chore/kit-<sha>` e PR para a `develop`. O sales_quote#417 (`chore/kit-fc32329`, só o
  `sdd-executor.md`) ainda está aberto: o PR novo traz os dois chapéus e o **substitui** (fechar o
  #417 apontando para ele). Os outros alvos usam symlink e seguem sozinhos.
- **Remover o worktree depois do merge**, pelo verbete "`sdd health` in the main checkout is slow
  again after a kit mission" de `docs/failure-modes.md`: o mapa de assassinos volta por união, o
  carimbo volta se a linha 6 do `./bin/sdd health --release` do principal estiver vermelha, os logs
  com `cp -Rn`; só então `git worktree remove /home/joruge/repos/sdd_agents-lote-6`.
