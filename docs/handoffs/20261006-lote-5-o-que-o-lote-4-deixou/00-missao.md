---
missao: 20261006-lote-5-o-que-o-lote-4-deixou
titulo: o lote 5 fecha os 12 achados abertos do kit — 8 nascidos do próprio lote 4, 3 da missão de máscaras do sales_quote e 1 do planejamento deste lote — cada um com sensor que mede o que afirma, e a missão do kit passa a ser escrita e executada num worktree ligado
data: 2026-10-06
versao: n/a (JIRA_ENABLED=false)
branch: fix/lote-5-o-que-o-lote-4-deixou
aprovacao: humano-2026-10-06
adr: docs/adr/0016-the-mission-checkpoint-and-the-kit-worktree.md
ddd: aplicado
---

# Missão — Lote 5: o que o lote 4 deixou

> Escrito pelo `sdd-planner` com o humano presente, via a sessão coordenadora (o relay do
> `/sdd-plan`), que repassou dez perguntas de grill em 2026-10-06. É a única fonte da **intenção**;
> o `01-plano.md` é a fonte do **como**. Toda sessão que executar esta missão começa lendo estes
> dois, mais o `checkpoint.md`.

## Problema (Gemba)

Depois do lote 4 (PR #222, merge `94123a4`) e do chore pós-merge (PR #231, `89df2e5`), o `TODO.md`
do kit tinha **11 achados abertos** e o espelho tinha 11 issues com label `todo` (#223–#230,
#232–#234). O planejamento deste lote achou mais dois, e os dois entraram no `TODO.md` do worktree
desta missão:
- o 12º, #235, que esta missão conserta;
- no grill, o 13º, o `sdd kaizen` no checkout principal, que fica fora (decisão 11b).

Medido: `bash tests/check-todo.sh` → `  ok    13 finding(s), all within 8 lines, carrying anchor + date,
every anchor on target`. Os 12 da missão têm direção registrada, e nenhum é "decidir": todos saem
por conserto com sensor. Origem:

- **8 nasceram do próprio lote 4** (#223–#230): a revisão final, os bots do PR #222 e o carimbo.
  Consertar 16 itens fez nascer 8, uma taxa de cerca de 0,5 achado por conserto.
- **3 nasceram da missão `20261005-mascaras-ncm-e-painel` do `sales_quote`** (#232, #233, #234).
- **1 nasceu deste planejamento** (#235), reproduzido pelo relay numa cópia isolada.

O que foi reproduzido ou lido no código (detalhe e âncoras no `01-plano.md` § Contexto verificado):

1. **Seis sensores falham abertos** (seção "Sensores que faltam"):
   - #226: a suíte herda `GIT_DIR` de quem a chama. Sob `git bisect run`, os fixtures do
     `check-gates.sh` reinicializaram o kit real como bare, gravaram `[user] Fixture` e criaram
     tags (2026-10-05 21:17, reparado à mão). É o único dos 12 com efeito destrutivo medido.
   - #224: uma linha `|`-led com menos de cinco células some do `checkpoint_rows` e do `rows_of`.
     O `pending` dela não é contado e o `gate_EXEC` pode passar.
   - #223: o `red_norm` aborta sob `set -u` em bash ≤ 4.3. Reproduzido no Docker: `bash:4.0` e
     `bash:4.3` dão rc 1, `bash:4.4` dá rc 0, e `BASH_COMPAT=4.3` no bash 5.2 não reproduz.
   - #232: `Closable by: deferred` passa no `gate_QA` sem a seção de decisão que a ADR 0009 exige.
   - #225: a ADR 0015 §3 declara um mundo fail-open: o relatório de outra missão conta se o commit
     que o trouxe também editar o checkpoint desta.
   - #233: a guarda do kit é cega a um kit já sujo que é editado de novo. Regime C da reprodução:
     kit sujo antes, mais outra escrita, dá rc 0 e 0 linhas.
2. **Um contrato conta o que não aconteceu (#227).** `sdd run --phase PR` grava e commita a nota
   `- intervention:` antes do laço, e só depois para no carimbo com rc 2, sem sessão. O
   `sdd autonomy --by-mission` conta a nota. A porta do PLAN faz o mesmo.
3. **Quatro saídas humanas dizem mais do que o runner sabe:**
   - #228: a parada no carimbo manda rodar o `sdd health` mesmo quando o carimbo é impossível.
   - #229: a página do `sdd status` pergunta "feita à mão?" sobre missão rodada noutra máquina.
   - #230: o `ok` do `sdd note-manual` afirma uma nota que não foi escrita.
   - #234: um servidor deixado pela fase segura o `sdd run` mudo depois do veredito. No caso
     medido, a QA matou o backend do humano e o relançou como filho dela, com `nohup … &`.
4. **O `/sdd-plan` no próprio kit grava no checkout que os `sdd run` dos alvos executam (#235).**
   `readlink -f ~/.hermes/bin/sdd` → `/home/joruge/repos/sdd_agents/bin/sdd`, e
   `~/.claude/commands/sdd-plan.md` é symlink para o mesmo checkout. Reproduzido numa cópia: com o
   kit limpo, um `00-missao.md` não rastreado gravado durante o EXEC de um alvo dá rc 3 e
   `KIT-TOUCHED` (`|false` → `|true`); o controle dá rc 0. Um worktree ligado, sujo ou com
   commits, não move o carimbo do checkout principal (medido: `89df2e5|false` antes e depois).
   No lote 4, o checkout principal ficou cerca de 26 h numa branch de missão, e todo `sdd run` de
   alvo nesse intervalo executou o `bin/sdd` meio editado.

## Métrica

Fatos binários, todos verificáveis por comando (detalhe no `01-plano.md` § Verificação end-to-end):

1. **Os 12 achados carregam `RESOLVED by <hash>`** na seção aberta do `TODO.md` ao fim da branch.
   Cada hash é ancestral do topo, e cada um teve o Red observado pelo motivo certo e ganhou um
   sensor durável. Mudança em `bin/` entra com mutante no `CATALOG`, provado com `--only`.
2. **A catraca fica em 13 durante toda a branch.** O commit do plano leva no mesmo diff:
   - o `TODO.md` com o #235 e com o 13º item, nascido no grill (o `sdd kaizen` no checkout
     principal, decisão 11b), que **fica aberto**;
   - `tests/health-baseline.txt` → `todo-findings 13`.

   Achado que nascer no meio da leva soma +1 no próprio commit (régua D15).
3. **A ADR 0016 está escrita e ligada:** `Amends: 0015`, e a 0015 ganha `Amended by: 0016`.
   `./bin/sdd adr check` → rc 0 sob `ADR_CHECK=block`.
4. **Suíte verde** (`bash tests/run-all.sh` → `suite green`) e **um** `sdd health` verde depois da
   revisão dos bots. Ele dá o carimbo válido para o `gate_PR`.
5. **A anatomia §6 e o `/sdd-plan` dizem a regra do worktree.** O probe `command:` do
   `check-hat.sh` está verde.
6. **Depois do merge** (fora da branch, pelo humano): o chore apaga os 12 e a catraca vai a
   **1 + N**, porque o item do `sdd kaizen` fica. O espelho de issues é re-sincronizado. Saldo
   declarado no PR: "13 → 1 + N nascidos".

## Resultado esperado

Toda a dívida antiga do backlog do kit sai. Fica só o item do `sdd kaizen`, nascido no grill e
deixado para uma missão própria, mais o que nascer nesta leva, cada um com dono e número. Os seis
sensores que falhavam abertos passam a medir o que afirmam:
- a suíte não escreve mais no repo de quem a chama;
- nenhuma linha da tabela some dos leitores;
- `deferred` exige a decisão escrita;
- o relatório da base exige o checkpoint da missão;
- a guarda do kit vê o kit já sujo.

A nota de intervenção só existe quando houve sessão. As quatro saídas humanas dizem só o que
aconteceu. A missão do kit é escrita e executada num worktree ligado, e o checkout que os alvos
executam fica na `main`.

## Fora de escopo

- **Yokoten nos repos-alvo** (`sales_quote`, `lighthouse_project`): o espelho `.claude/agents/`,
  quando algum chapéu mudar, e a frase nova do `turn_rule`, que chega sozinha porque o runner é o
  mesmo binário. É passo do humano, listado em § Pendências.
- **Retrofit da skill `todo-to-github-issues`** (o `SKILL.md:124` descreve a âncora antiga): é
  pendência herdada do lote 4 e mora no marketplace, fora do kit.
- **Worktree dentro do laço do `sdd run`.** A anatomia §6 continua dizendo que fechar isso "pede
  desenho próprio". A decisão desta missão (ADR 0016 §2) vale para a missão do kit escrita e
  executada **interativamente**, nunca para o runner criar worktree por conta própria.
- **Varredura de classe dos arrays vazios sob `set -u`** (`check-pipefail.sh`). Ela foi recusada
  no grill (decisão 7): saber se o array pode estar vazio é indecidível linha a linha. O único
  sítio vivo medido é o `red_norm`.
- **O `sdd kaizen` no checkout principal** (decisão 11b). É o mesmo vetor da #235, mas pede
  decidir o que o comando faz: recusar, ou criar o worktree. Por isso vira item próprio no `TODO.md`
  e no espelho de issues, e fica aberto depois do chore.
- **Achado nascido no meio da leva:** passa pela régua D15 e vai ao `TODO.md` com catraca +1 no
  mesmo commit. Não é consertado aqui. Defeito criado pela própria leva se conserta nela.

## Gate PLAN-AUTO

Preenchido pelo `sdd-planner` **com evidência**. Todos ✅ → `aprovacao: auto` e o pipeline segue
sozinho. Qualquer ✗ → `aprovacao` fica vazio e o runner para pedindo aprovação humana explícita.

⚠️ `aprovacao:` fica **vazia** de propósito, qualquer que seja o resultado desta tabela. A missão é
executada interativamente, e quem fecha o gate é o humano: o relay pergunta YES/NO e roda
`sdd approve` (decisão 7 do lote 4, `commands/sdd-plan.md` § When the artifacts exist).

| # | Critério | Status | Evidência |
|---|---|---|---|
| a | Grill sem perguntas abertas não endereçadas (🚩 vazia ou itens deferidos com dono) | ✅ | O humano respondeu, via relay, às 10 perguntas e aceitou as 4 decisões de desenho dos protótipos (§ Decisões do grill, 1–12). A missão não abriu 🚩. As pendências têm dono, o humano: o momento do health; o merge, o chore e o re-sync; a remoção do worktree; o yokoten; congelar o kit; o desenho do item do `sdd kaizen`. A mudança de comportamento do I7 (a nota do `--budget-override` passa a carregar a fase da sessão comprada) decorre da decisão 11a e vai declarada no PR. |
| b | Checklist kaizen 100% ✅ e checklist DDD 100% ✅ ou `n/a` justificado | ✅ | K1–K8 todos ✅, com evidência na tabela abaixo. DDD acionado (três contratos entre módulos), com D1–D6 ✅. |
| c | Plano passa no teste de autocontenção (sessão nova só com 00/01/checkpoint executa) | ✅ | Um subagente sem memória leu só os 3 arquivos e o código do worktree (sem o scratchpad nem os patches) e simulou I1, I5 e I7. Veredito: "sim, com ressalvas". Ele conferiu ~45 fatos citados: bateram todos, menos 3 (o chamador de `mission_qa_report`, a "falta de faixa" de dois mutantes e o placeholder já removido da ADR), e os 3 foram corrigidos no texto. As ressalvas foram fechadas no plano: (1) a regra do censo do I1 (o `source` sempre exigido, a regex que não casa a própria linha, o controle sintético), o segundo `set … pipefail` em heredoc, a diretiva `# shellcheck shell=bash` e o que "isca intacta" compara; (2) a receita do mundo (l) do I5, onde mora a carga preguiçosa e os `local`; (3) no I7, os ajudantes novos (`mdir_notes`, `mdir_count`, `nw_budget`, `nw_notes`) e o `nm_bare_says` do I8 definidos, o sed que faltava, o texto inteiro do remédio, o mundo NW6D, o rótulo do bloco do mundo 9, o `if` em três linhas e o aviso do `&` corrigido; (4) as contradições de contagem (11 × 12 de 16, 4 do D, o Check do I11 alinhado com o plano); (5) o ambiente no Passo 0. |
| d | Todo incremento do `checkpoint.md` tem Check executável (comando → esperado), vermelho no HEAD pelo `tests/check-checkpoint.sh --red` do kit | ✅ | 11 de 11 linhas na forma estrita. `tests/check-checkpoint.sh --check <este checkpoint>` → `11 row(s), 10 under the anchor rule, none blind`, rc 0. `--red` no worktree (HEAD `89df2e5` + o plano, 03:00–03:15) → `11 pending Check(s), every one red at HEAD`; o antes de cada um bate com o da seção do incremento (I1 `0`/`4`, I2 `0`/`2`, I3 `0`/`1`, I4 `0`/`3`, I5 `0`/`1`, I6 `0`/`2`, I7 `0`/`10`, I8 `0`/`2`, I9 `0`/`3`, I10 `0`/`1`). O Check do I11 perdeu depois um termo constante (o placeholder da ADR, já zerado) e foi re-medido à mão: `0 0 0 0 0`, contra o esperado `12 1 1 1 1`. Cada Check foi medido também no protótipo: 0 antes, o esperado depois. |
| e | `versao:` confirmada pelo humano (ou `JIRA_ENABLED=false`) | ✅ | `JIRA_ENABLED=false` (`.sdd/config.sh`), `versao: n/a`. |
| f | `adr:` é uma decisão — um caminho, ou o literal `none` (alocado por `sdd adr new`) | ✅ | `adr: docs/adr/0016-the-mission-checkpoint-and-the-kit-worktree.md`, alocada por `./bin/sdd adr new` do worktree (decisão 5). O corpo traz a §1 (posse do relatório, com os números do protótipo C e as descartadas) e a §2 (missão do kit em worktree, com a reprodução e a medição do carimbo). `./bin/sdd adr check --mission 20261006-lote-5-o-que-o-lote-4-deixou --phase plan` → `ok … and that ADR points back`, rc 0. |

## Checklist kaizen (`kaizen-software`)

| # | Item | Status | Nota |
|---|---|---|---|
| K1 | Gemba — fui ver onde o trabalho acontece | ✅ | Seis protótipos (A–F), cada um num clone de `89df2e5`, reproduziram os 12 defeitos com o probe escrito e a linha `FAIL` vista antes do conserto, e mediram o verde depois. **Duas premissas mudaram com a medição:** a #223 não aborta o sensor (o veredito sobrevive; o defeito é ruído e risco latente), e a #226 não se conserta só no `run-all.sh` (o incidente entrou por `check-mutation.sh --only`). **Uma direção foi corrigida pela medição:** a da #229 (só a linha `session` conta). Campo medido nos alvos: 35 linhas curtas em tabelas estreitas reais (#224), 17 títulos de decisão no `sales_quote` (#232), 21 logs com `nohup` (#234), e 9 de 9 commits de relatório com blob da própria missão (#225). |
| K2 | Problema declarado com métrica | ✅ | 12 `RESOLVED by` com sensor; catraca 13 na branch e 1 + N depois do chore; ADR 0016 ligada e `adr check` rc 0; suíte verde e um carimbo. Tudo por comando (§ Métrica). |
| K3 | Desperdícios identificados e cortados | ✅ | **Espera:** o worktree tira a escrita do kit do caminho dos `sdd run` dos alvos; um `sdd health` só, depois dos bots; o mapa de assassinos copiado (evita a 1ª corrida a 2×). **Superprocessamento recusado:** a varredura de classe do `set -u` (indecidível linha a linha), o probe condicional em Docker, a linha curta sem `\|` inicial (0 casos reais), o `git stash create` na guarda (escreve objetos no kit) e a nomeação de processos no hook (o prazo já o limita). **Defeito:** protótipos antes do plano; mutantes vizinhos provados. |
| K4 | Fatiamento incremental, cada fatia verificável | ✅ | 11 incrementos de uma sessão cada: um item por incremento, ou dois itens da mesma função (I7, I8). O I1 vem primeiro porque é o único destrutivo. Cada Check tem o "antes" medido na seção do incremento. |
| K5 | Check por artefato (rótulo ≠ artefato) | ✅ | Os Checks leem a linha `^  ok    ` do sensor por herestring, ou o arquivo por `awk`. `tests/check-checkpoint.sh --check` e `--red` sobre este checkpoint estão no critério d. Mutantes provados com `--only`; regras em `tests/` provadas por passada de sabotagem. |
| K6 | Jidoka — o que para a linha está definido | ✅ | Um sensor vermelho para o commit. Uma âncora do `TODO.md` deslocada para o commit (`check-todo.sh` no `TEST_CMD`). Um mutante que não aplica mais para o commit (`--anchors`). Um defeito criado pela leva se conserta nela. O próprio produto também para a linha no ponto certo: a guarda do kit vê o kit sujo (I6), e a `deferred` sem decisão bloqueia (I4). |
| K7 | SDCA — a melhoria vira padrão (doc/rule/teste) | ✅ | Todo conserto entra com probe durável, e com mutante quando mexe em `bin/`. A regra do worktree vira passo do `/sdd-plan` com probe, mais a ADR 0016 §2 e a anatomia §6. O `isolate-git.sh` é uma definição única com probe estático. Os verbetes do `CONTEXT.md` e o drift de `docs/` mudam no I11. |
| K8 | Registro no KAIZEN_LOG | ✅ | Planejado no I11: o Check exige a entrada `— Lote 5: o que o lote 4 deixou` no `KAIZEN_LOG.md`. |

## Checklist DDD (`ddd`) — condicional

Acionado, e não `n/a`. A leva muda três contratos publicados entre módulos. Nenhum evento novo entra
no ledger e nenhuma entidade nova aparece.

| # | Item | Status | Nota |
|---|---|---|---|
| D1 | Linguagem ubíqua nomeada | ✅ | **Decisão escrita do bug:** a seção `## Decis…` fora de cerca, que dá valor ao gênero `deferred`. **Checkpoint que a missão já teve:** o blob de progresso que um commit da branch da missão escreveu no mesmo caminho. **Árvore suja do kit:** caminho mais conteúdo, que a guarda compara. **Missão do kit em worktree:** ADR 0016 §2. Os termos entram no `CONTEXT.md` no I4, no I5 e no I11. |
| D2 | Fronteira do contexto | ✅ | O gênero do bug é escrito pelo chapéu `sdd-qa` e pelas skills de QA, e lido só pelo `gate_QA` (âncora 3). A posse do relatório fica dentro de `mission_qa_report`/`tip_add_carries_mission`, e os dois chamadores dela (`gate_QA` e `qa_substep`, `bin/sdd:1511` e `:2535`) não mudam. A nota `intervention:` é escrita pelo runner e contada pelo `sdd autonomy --by-mission`. O ledger não muda de forma. |
| D3 | Invariante | ✅ | (i) Um bug `deferred` sem decisão escrita nunca deixa a QA passar. (ii) O relatório de outra missão nunca conta como desta, nem quando ela edita este checkpoint (com o resíduo byte a byte declarado). (iii) Toda nota `intervention:` escrita pelo runner corresponde a uma sessão aberta pela mesma porta. (iv) Uma edição no kit durante a fase de um alvo nunca passa calada, mesmo com o kit já sujo. |
| D4 | Eventos | ✅ | Nenhum evento novo no ledger, e o enum de `kind` não muda (o `kit-touched` ganha conteúdo no motivo, não um `kind` novo). A nota `intervention:` é narrativa do checkpoint, não evento do ledger (`templates/checkpoint-notas.md`). |
| D5 | Contrato entre módulos | ✅ | Gênero: o `agents/sdd-qa.md` §5.1 e o `docs/pipeline.md` mudam no mesmo commit do gate (I4), e o espelho `.claude/agents/` sincroniza por `./bin/sdd install --force`. A nota: o `templates/checkpoint-notas.md` e o `docs/pipeline.md` mudam no mesmo commit do I7. O relatório: o `docs/pipeline.md` e o `CONTEXT.md` no I5. Mudança de contrato em três lugares no mesmo commit (regra do `CLAUDE.md`) [Evans Reference: Published Language]. |
| D6 | Decisão registrada | ✅ | ADR 0016 (§1 posse do relatório, emenda a 0015 §3; §2 missão do kit em worktree). O gênero `deferred` exigindo a decisão cumpre a ADR 0009, que já decidiu, e por isso não tem ADR nova. A nota só com sessão é a direção registrada no item #227, decidida no grill (decisão 6). |

## Decisões do grill (não re-litigar)

1. **Escopo: as 11 issues abertas, numa missão só, em cerca de 10 incrementos por subsistema.** O
   I1 é a #226. A #227 e a #228 dividem um incremento, a #229 e a #230 dividem outro, cada um dos
   demais tem o seu, e o último fecha a missão. — Porquê: é a régua "zerar em levas" dos lotes 3 e
   4. Custa um `sdd health` só, e os itens são independentes, então um incremento travado não segura
   os outros. (humano, "11 numa missão (Recomendado)", 2026-10-06)
2. **Logística: a missão é escrita e executada num worktree ligado,
   `/home/joruge/repos/sdd_agents-lote-5`, na branch `fix/lote-5-o-que-o-lote-4-deixou`, cortada de
   `origin/main` (`89df2e5`).** O checkout principal fica na `main`. — Porquê: o `sdd` do PATH é o
   checkout principal, então gravar ou editar ali dispara `kit-touched` nos `sdd run` dos alvos e
   faz esses runs executarem código não revisado. O worktree não move o carimbo da guarda
   (medido). (humano, "Worktree ligado (Recomendado)", 2026-10-06)
3. **O achado do `/sdd-plan` entra no lote como incremento pequeno (#235).** O `commands/sdd-plan.md`
   ganha o passo: quando o repo planejado é o kit de onde o `sdd` roda, a missão é escrita e
   executada num worktree ligado. O probe é uma linha `command:` no `check-hat.sh`. A catraca vai de
   11 para 12 no commit do plano, e o item sai `RESOLVED by` na própria missão. A issue #235 foi
   criada pelo relay a pedido do humano ("nos podemos colocar como issue no github e depois
   syncronizar com o TODO.md"). O título do item não muda mais, porque a chave do espelho é o hash
   do título. — Porquê: custou o planejamento desta missão, e a direção estrutural é barata. Há
   precedente na decisão 8 do lote 4. (humano, "Entra, incremento pequeno (Recomendado)", 2026-10-06)
4. **Nomes:** missão `20261006-lote-5-o-que-o-lote-4-deixou`, branch
   `fix/lote-5-o-que-o-lote-4-deixou`. — Porquê: 8 dos 12 nasceram do lote 4, e a forma
   `lote-N-<frase>` é a dos lotes 3 e 4. (humano, "o-que-o-lote-4-deixou (Recomendado)", 2026-10-06)
5. **ADR 0016, nova, alocada por `sdd adr new`, com duas seções.**
   - **§1:** fecha o fail-open declarado da 0015 §3 (#225). O checkpoint deixado pelo commit da
     base que adicionou o relatório tem de ser um blob que a branch da missão já teve.
     `Amends: 0015`, e a 0015 ganha `Amended by: 0016`.
   - **§2:** missão do kit é escrita e executada num worktree ligado (#235), com o porquê medido.
     Corrige a anatomia §6, que hoje diz "sem worktree".
   
   — Porquê: muda o texto da decisão de uma ADR aceita, e o padrão de emenda da casa é a ADR nova.
   Além disso, a §2 responde ao "por que no worktree?" de um leitor futuro. (humano, "ADR 0016,
   §1 + §2 (Recomendado)", 2026-10-06)
6. **#227: a nota `- intervention:` do `--phase` só é escrita quando a volta forçada pela CLI abre
   sessão.**
   - Um local de uso único guarda o valor da CLI antes do laço.
   - A nota é escrita logo antes de `before="$(state_fingerprint)"`, ainda antes de `kit_guard_arm`
     e `hat_guard_arm`, e nunca nas voltas que o próprio runner força.
   - Par diferencial em `check-autonomy.sh`: `--phase PR` com só o carimbo faltando dá 0 notas, e
     `--phase EXEC` que abre sessão dá 1. Cada metade tem seu mutante.
   
   — Porquê: a nota passa a dizer o que aconteceu, e o `--by-mission` deixa de contar intervenção
   numa corrida vazia. (humano, "Nota só se abrir sessão (Recomendado)", 2026-10-06)
7. **#223: o conserto é `${w[@]+"${w[*]}"}` no `red_norm`, com uma asserção no próprio
   `check-checkpoint.sh` que lê `declare -f red_norm` e exige o idioma guardado.** O vermelho e o
   verde comportamentais ficam medidos no Docker `bash:4.3` como prova efêmera, registrada nas
   notas. — Porquê: a suíte roda bash 5.2 e `BASH_COMPAT` não reproduz. A asserção é barata e mata
   o mutante que tira a guarda. A regra de classe no `check-pipefail.sh` foi recusada (falsos
   positivos), e o probe condicional em Docker também (some em máquina sem Docker). (humano,
   "Conserto + asserção (Recomendado)", 2026-10-06)
8. **#234: uma frase no `turn_rule` de `boot_prompt()`, valendo para todas as fases, mais o print do
   supervisor.**
   - A frase: processo em background entra na família do pipeline, e o `sdd run` não termina e o
     checkout fica preso até ele morrer. Não pare nem relance processo que você não subiu: o app
     sob teste é do humano, e restart ou outro ambiente vai para o handoff. O que você subiu para a
     própria checagem, pare antes de encerrar o turno.
   - O probe é por fase, no `check-dry-run.sh`.
   - O worker colhido com descendentes vivos faz o supervisor imprimir uma vez o pid e a cmdline de
     cada um.
   
   — Porquê: a regra vale para toda fase (15 QA e 3 EXEC entre os logs medidos com `nohup`), e o
   lugar dela é o `boot_prompt()` (anatomia §1). (humano, "No turn_rule, toda fase (Recomendado)",
   2026-10-06)
9. **Herdado dos lotes 3 e 4, e não re-perguntado:**
   - execução **interativa**, nunca `sdd run` no próprio kit;
   - gate novo ou regra nova entra com mutante provado por `--only`;
   - depois de mexer numa guarda, `--only` nos mutantes vizinhos da mesma função;
   - fechamento: PR → **todos** os bots → conserto numa leva → **um** `./bin/sdd health` → merge →
     chore pós-merge → re-sync do espelho.

   — Porquê: é o modo provado três vezes, e o relay o trouxe como regra já decidida.
10. **#226, defesa em profundidade.** Um arquivo único, `tests/isolate-git.sh` (que não é `check-*`
    e entra no lint pelo glob), limpa as variáveis de repositório que o próprio git lista
    (`git rev-parse --local-env-vars`) e recusa um git que não nomeie `GIT_DIR`. Ele é carregado com
    `source` pelo `run-all.sh`, pelo `check-mutation.sh` e pelos sensores, e um probe estático cobra
    isso.
    - O humano escolheu "todo `check-*.sh` que faz `git init`". O plano lê o predicado como **todos
      os 16 sensores**. Medido: `check-coordination.sh` move a isca com 0 ocorrências de `git init`,
      e `check-checkpoint.sh` tem 3 e fica intacto. Por isso, o grep de `git init` erraria nos dois
      sentidos.

    — Porquê: o incidente medido entrou por `check-mutation.sh --only`, que nunca passa pelo
    `run-all.sh`. Rodados sozinhos, 12 de 16 sensores escreviam no repo do `GIT_DIR` herdado (11 com só o `run-all.sh` e o catálogo consertados), e o
    `check-autonomy.sh` sozinho pode perder um repo (`git init --separate-git-dir`). Esta missão muda
    o trabalho do kit para o worktree ligado, onde hooks, `bisect run` e `rebase --exec` exportam
    `GIT_DIR`. (humano, "Defesa em profundidade (Recomendado)", 2026-10-06)
11. **Dois resíduos que os protótipos acharam fora dos 12:**
    - **(a) a forma da #227 nas portas vizinhas entra no I7,** na direção da decisão 6, com um par de
      probes e um mutante por porta. A nota do `sdd retry` hoje é escrita antes do teto da missão. A
      nota do `--budget-override` pode vir antes de uma parada sem sessão;
    - **(b) o `sdd kaizen` no checkout principal** (o mesmo vetor da #235) vai ao `TODO.md` como
      achado novo, catraca 12 → 13, no commit do plano. O humano pediu a issue antes do commit,
      como no #235. O título fica definitivo.

    — Porquê: o (a) é a mesma linha de código nas portas vizinhas. O (b) pede decidir o que o comando
    faz, e isso é desenho próprio. (humano, "(a) no I7, (b) ao TODO (Recomendado)", 2026-10-06)
12. **Quatro decisões de desenho que os protótipos tomaram, aceitas como estão:**
    - **#232:** um título `## Decisions for a Human` NÃO conta como decisão, porque é pergunta
      pendente;
    - **#229:** a presença que vale é só a linha `session` daquela missão nesta máquina. Com
      "qualquer linha", a linha `manual` que a própria dica manda gravar reabriria a pergunta;
    - **#230:** sem `checkpoint.md`, o `note-manual` ainda grava a linha `manual`, e o `ok` diz
      "and no note";
    - **#233:** a guarda guarda um md5 por caminho sujo. Custa 3 ms com o kit limpo e 31 ms com 61
      entradas. Em troca, quem edita um kit já sujo durante a fase de um alvo para a linha.

    (humano, "Seguir com as quatro", 2026-10-06)

## Pendências para o humano

- **O momento do `sdd health`:** depois de todos os bots, uma vez (decisão 9), no worktree. Antes
  dele, copiar o mapa de assassinos: `cp /home/joruge/repos/sdd_agents/.sdd/cache/mutation-killers.tsv
  /home/joruge/repos/sdd_agents-lote-5/.sdd/cache/`. O `.sdd/cache/` é ignorado e não vem com o
  worktree; sem o mapa, a primeira rodada custa cerca de 2×.
- **Merge do PR** e, depois dele, o chore pós-merge (`todo_rm.py` nos 12; a catraca vai a 1 + N) e
  o re-sync do espelho de issues.
- **Desenhar o próximo passo do item do `sdd kaizen` no checkout principal** (decisão 11b), numa
  missão própria.
- **Remover o worktree depois do merge:** `git worktree remove /home/joruge/repos/sdd_agents-lote-5`.
- **Yokoten nos repos-alvo:** re-sincronizar os espelhos `.claude/agents/` se algum chapéu mudar
  (lista no PR). A frase do `turn_rule` e a regra do `deferred` chegam pelo binário. Nenhum bug
  `deferred` aberto dos alvos fica sem a seção de decisão hoje (medido).
- **Congelar ou não o kit para a janela do juiz depois do merge:** esta leva muda `bin/` e cunha um
  `kit_rev` novo.
