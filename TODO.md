# TODO — `sdd_agents`

Achados que **não cabem na missão atual**, registrados por qualquer agente ou humano
(kaizen princípio 10: oportunidade registrada, nunca desvio de escopo, nunca achado perdido).
Formato, esqueleto e ciclo de vida: [`templates/todo.pt-BR.md`](templates/todo.pt-BR.md) — a
semente que o `sdd install` grava nos repos-alvo, uma variante por `OUTPUT_LANG`, com a forma
medida por `tests/check-todo.sh`. Os planos estacionados do kit moram na gaveta,
[`docs/superpowers/specs/2026-09-23-a-gaveta-do-kit.md`](docs/superpowers/specs/2026-09-23-a-gaveta-do-kit.md).

Achados sobre **repos-alvo** vão para o `TODO.md` daquele repo. Este arquivo é só sobre o kit.

> **Catraca do volume — crescer é permitido, crescer calado não.** Quantos itens este arquivo
> carrega é o achado `todo-findings <N>` do `sdd health`, congelado em `tests/health-baseline.txt`.
> Reprova nos **dois** sentidos: número que subiu sem registro, e baseline que ficou para trás
> depois de uma faxina. Quem acrescenta item aqui **e** move a linha da baseline no mesmo commit
> está certo — o número tem dono e aparece no diff. Quem só acrescenta descobre no `sdd health`.
> Ela mora lá e não no `TEST_CMD` porque um teto dentro da suíte reprovaria toda missão em voo.
> ⚠️ A contagem sai de `tests/check-todo.sh`, nunca de um `grep -c '^- \[ \]'`, que não sabe
> onde a seção aberta termina.

## Aberto
<!-- sdd:open -->

### Prioridade — resolver logo

- [ ] **O `sdd health` refaz o catálogo inteiro mesmo com o carimbo valendo para o conteúdo** — `bin/sdd:7347`
  (`--with-mutation`) — o carimbo prova o verde sobre `bin/ tests/ templates/ config/ agents/`, mas só o
  `gate_PR` o cobra: o `cmd_health` não o consulta e roda os 775 mutantes sempre, até num diff só de `TODO.md`
  e catraca. O mapa dos matadores some com a worktree, e nenhum checkout do kit nesta máquina o tinha: o
  `sdd health` deste achado ia em 464 de 775 logs (8 ainda rodando) após 5 h 13 min. Direção: a chave igual à
  do carimbo pula o catálogo e roda a suíte rápida e a catraca; o mapa e o carimbo voltam ao checkout principal
  sem passo manual. Prioridade do dono.
  — descoberto pelo relay da sessão coordenadora da 3.5b do `dotp-remake` (2026-10-25)

### Sensores que faltam

- [ ] **O `sdd preflight` não mede a forma do `TODO_FILE`, e nada avisa o alvo sem o opt-in** —
  `bin/sdd:6813` (`preflight-test`) — a forma só é medida quando o `TEST_CMD` do alvo inclui o
  `check-todo.sh` (o opt-in de `config/schema.md`); o do `sales_quote` não incluía, e o `TODO.md` dele
  divergiu calado até 206 violações, achadas só quando o espelho de issues recusou. Direção: o
  `sdd preflight` roda `check-todo.sh --check "$TODO_FILE" --allow-empty` sozinho, ou avisa. Fonte:
  `docs/superpowers/specs/2026-10-09-o-worker-caderno-de-campo.md` (C8) — descoberto na faxina das
  issues do `sales_quote` (2026-10-09)

- [ ] **A mitigação de risco que cita um sensor não prova que ele cobre o alvo** — `templates/plano.md:41`
  (`Mitigação`) — o plano da LH-5 do `lighthouse_project` mitigou "a troca de assinatura do port espalha
  pelas fixtures de teste" com "o compilador lista"; o `tsc --noEmit` do backend exclui `__tests__` e saiu
  rc 0 com testes ainda na assinatura velha. Executor que confia no verde deixa chamador quebrado, que o
  Vitest (sem checagem de tipo) só pega se tropeçar em runtime. Direção: o planner roda no PLAN, contra o
  que ela protege, o sensor que uma mitigação nomeia, como o `--red` já faz com os Checks.
  — descoberto por `retrofit-watch` na missão `20261013-amep-alignment-review` (2026-10-13)

- [ ] **Nada avisa que o clone do kit está velho ou fora da `main`** — `bin/sdd:4116` (`autonomy_kit_stamp`) —
  o runner grava o SHA e a sujeira do `SDD_HOME` no journal, mas nada os compara com o upstream, e as seis
  linhas do `sdd health --release` também não. No `ui24_agent`, o `~/repos/sdd_agents` estava numa branch
  já mergeada, 382 commits atrás da `main`, e todo alvo rodou o kit velho sem saber. Direção: avisar uma
  vez por processo quando o `SDD_HOME` não está na branch padrão do remoto do próprio kit (o `origin/HEAD`
  dele, nunca o `DEFAULT_BRANCH` do alvo: `develop` no `sales_quote`) ou está atrás do upstream já buscado.
  — descoberto por `retrofit-watch` na sessão do `ui24_agent` que planejou a S9 (2026-10-17)

- [ ] **O `sdd preflight` diz "preflight ok" com um `TEST_CMD` que deixa servidor vivo** — `bin/sdd-coordination.py:359`
  (`left running`) — o aviso do supervisor só sai depois do "ok", e todo comando que roda o `TEST_CMD` fora
  de um `sdd run` repete a espera. No `dotp-remake` (.NET) o `dotnet build` deixou 7 nós do MSBuild e o
  `VBCSCompiler`: o preflight ficou preso em "8 processes it left running hold the checkout" até um
  `dotnet build-server shutdown`; com `--disable-build-servers` nenhum sobra. Direção: o probe do `TEST_CMD`
  avisa nomeando o descendente que sobrou, e o failure-modes lista as flags de toolchain.
  — descoberto por `sdd preflight` na instalação do kit no `dotp-remake` (2026-10-19)

- [ ] **A prosa que a DOCS escreve depois da REVIEW não passa por revisão nenhuma** — `bin/sdd:2713` (`PHASES`) —
  a ordem é `REVIEW DOCS PR`: o `gate_REVIEW` aceita B na prosa (`REVIEW_PROSE_MIN_GRADE`), o achado de prosa vai
  ao `TODO_FILE` e quem reescreve a prosa é a DOCS, cujo gate lê a checklist, não a prosa. Na 3.2a do `dotp-remake`
  uma r2 extra do `/codereview:codereview` achou 1 MEDIUM na prosa da DOCS (`3044b3c`): o ponteiro novo diz que
  toda condição do filtro está na linha do `Add`, e faltava o `FE_NUM_COLOURS` (consertado em `3a57106`).
  Direção: a REVIEW revê o diff da DOCS antes do PR, ou o corpo do PR diz que essa prosa ninguém revisou.
  Fonte: PR `j0ruge/dotp-remake#10`, Evidências (r2 e r3) — descoberto por `/codereview:codereview` (r2) na
  missão `20261019-plano-3-2-a-magicas-de-uma-vez` (2026-10-19)

- [ ] **O `writes:` do `sdd-kaizen` não é cobrado: o `cmd_kaizen` não passa pela guarda do chapéu** —
  `agents/sdd-kaizen.md:11` (`writes:`) — o chapéu declara `$HANDOFF_DIR/**, KAIZEN_LOG.md`, somado como em todo
  chapéu ao `HAT_WRITES_BASE` (`$TODO_FILE` e a catraca), mas o `cmd_kaizen` não chama o `hat_guard_check`: uma
  escrita do juiz fora disso passa sem parada. O chapéu também não diz que a base inclui o `TODO.md`: o juiz de
  2026-10-20 leu o `writes:` ao pé da letra e levou os achados ao plano nascido; o de 2026-10-12 os commitou no
  `TODO.md`, como a base permite. Direção: o `cmd_kaizen` passa pela guarda, com probe, e o chapéu nomeia a base.
  — descoberto por `sdd-kaizen` na missão `20261020-a-sessao-le-o-que-o-boot-manda` (2026-10-20)

- [ ] **O `atualizado:` do checkpoint aceita hora inventada, até no futuro** — `tests/check-checkpoint.sh:1560`
  (`check_one`) — a regra "todo carimbo sai do `date`" só está no `boot_prompt` (`bin/sdd:3365`), que a sessão
  interativa não lê, e o `--check` não olha o campo. Na peça C do `lighthouse_project`, as rodadas do `/codereview`
  gravaram 15:30, 17:10, 18:00 e 18:40 em commits das 12:43 às 12:52 (`-0300`, autor igual a commit), e o
  `--check` passou. Direção: o `--check` reprova `atualizado:` posterior ao relógio, com probe.
  — descoberto por `retrofit-watch` na missão `20261020-amep-anexo-na-demanda` do `lighthouse_project` (2026-10-21)

- [ ] **A sonda do `Bash` do `sdd preflight` dá `ok` pela resposta, nunca pelo comando rodado** — `bin/sdd:6567`
  (`sdd-preflight-ok`) — o braço `ok` só faz `grep` do marcador no `result`, e o marcador está literal no prompt:
  um modelo que repita o texto sem chamar o `Bash` fica verde, e sem linha `init` o `ok` ainda afirma "Bash in the
  tool list". O fixture prova: o stub A do `tests/check-preflight.sh` responde sem `tool_use` e a sonda diz `ok`.
  Direção: ler o artefato, como a sonda dos templates desde o R6 (o `tool_result` do `Bash` com o marcador).
  — descoberto na varredura do R6 da missão `20261020-a-sessao-le-o-que-o-boot-manda` (2026-10-21)

- [ ] **A sessão que morre junto com o runner some do journal, e a sobra dela não aparece no `sdd status`** —
  `bin/sdd:5620` (`pipeline_log_line`) — a linha da sessão só sai no fim; com o host travado, o `pipeline.log` acaba no
  `PHASE` e o `<FASE>-…-<sid>.stream.jsonl` fica sem linha (medido no `dotp-remake`: a `7e4567fd`, 10 entradas sem
  commit). O `sdd status --no-gates` (`:7832`) não lê a árvore; o completo roda o `gate_EXEC`, que só a olha com todo
  incremento `done` e o `TEST_CMD` vermelho (`:1515`): com um `pending`, o run seguinte abre outra sessão sobre a sobra,
  sem aviso no boot. Hipótese, não medida: morrer no meio da sabotagem de um `R<n>` (`agents/sdd-executor.md:88`) deixa
  a linha degradada para a próxima commitar. Direção: status e boot citam o stream órfão e a árvore suja.
  — descoberto por `retrofit-watch` na missão `20261023-plano-3-4-b-ate-o-fim-do-turno` (2026-10-24)

- [ ] **O `sdd run` paga a REVIEW sem avisar que o `READ_EXTRA` não cobre o `codereview`** — `bin/sdd:6951`
  (`sk_entry`) — o aviso com a entrada a acrescentar só sai no `sdd preflight`, que é opcional: o `sdd run` não o
  repete e abre a REVIEW assim mesmo. No `magic_tutor`, as três últimas missões tiveram Reads negados nas
  `references/` do `codereview` (5, 2 e 3 no `pipeline.log`). Na `20261024-dica-na-hora`, 3 dos 5 agentes da
  Fase B pararam sem revisar, numa REVIEW de US$ 5,61. Com a entrada (`j0ruge/magic_tutor#104`), um subagente
  headless lê a reference. Direção: o `sdd run` faz a mesma busca de skills, sem sessão, e avisa ou para.
  — descoberto por `sessão coordenadora` na missão `20261024-dica-na-hora` do `magic_tutor` (2026-10-25)

### Contrato e configuração

- [ ] **O plano manda o EXEC editar em `.claude/`, o `claude -p` recusa, e a sessão contorna pelo Bash** —
  `config/schema.md:145` (`claude -p`) — no I6 da missão `20261020-narracao-com-dicas` do `magic_tutor`
  (`49d2c89`) o "Onde" listava `.claude/skills/revisar-partida/`; o `Edit` foi recusado e o executor trocou o
  texto por um script Python via Bash, a rota que o `schema.md:144-148` fecha ao `sdd-docs` em `.claude/rules/**`.
  O planner aceitou o I6 sem aviso, e o `check-checkpoint.sh --check`/`--red` não olham caminhos. Direção: o
  planner (ou o `--check`) avisa o incremento EXEC que toca `.claude/`, e o executor deixa o texto proposto ao
  humano no PR, como o `sdd-docs`. Fonte: `20-handoff-exec.md:167` da missão.
  — descoberto por `retrofit-watch` no `magic_tutor` (2026-10-20)

- [ ] **O ciclo de vida do `RESOLVED by` não sobrevive a squash merge** — `templates/todo.pt-BR.md:33`
  (`merge-base --is-ancestor`) — o hash do branch nunca vira ancestral da base num repo que faz
  squash, e o item fica preso para sempre; no `sales_quote` os PRs #405 e #406 entraram por squash e
  quatro itens com `RESOLVED by` não saíam. Direção: aceitar como prova também o merge do PR que
  carregou o hash, ou declarar que o ciclo exige merge commit. Fonte:
  `docs/superpowers/specs/2026-10-09-o-worker-caderno-de-campo.md` (C7) — descoberto na triagem
  das issues do `sales_quote` (2026-10-09)
- [ ] **A prosa congelada diz a regra 2 e o teto de largura mais estritos que os sensores** —
  `templates/checkpoint.md:27` (`check-x.sh`) — desde o lote 8 a regra 2 lê a variável e aceita `'^ *✓ '`,
  e o teto isenta a linha que só carrega a âncora; o template e o `agents/sdd-planner.md:111` ainda dizem só
  `^  ok    `, e o `templates/todo.pt-BR.md:24`, o `templates/todo.md:24` e o `agents/sdd-executor.md:127`,
  "nenhuma linha passa de 120". Não falha aberta, mas a saída só aparece na mensagem de FAIL. Direção: as
  cinco frases dizem a regra nova quando o congelamento cair.
  Lote 9 (`20261016-lote-9-o-papel-de-cada-palavra`): toda mescla, só o padrão deve âncora (getopt_long), par de zeros.
  — descoberto pelo `sdd-planner` na missão `20261015-lote-8-a-leva-que-nao-parte-a-janela` (2026-10-15)
- [ ] **O veredito da QA não é revalidado depois de um R<n>** — `docs/pipeline.md:99` (`R<n>`) — o REVIEW
  vem depois da QA e um `R<n>` muda o código sem reabri-la: o reteste do lote 7 só lê `F<n>`, e o `skipped`
  que o `sdd-qa` conferiu no diff não é reconferido (Codex no PR #247, 14ª rodada; 22 de 64 missões reais
  tiveram `R<n>`). Falha aberta, com consumidor fora da suíte do kit (D15). Direção: amarrar o veredito
  ao commit que a QA viu e decidir, com custo medido, o que um `R<n>` reabre (um reteste custou US$ 7,19).
  Fonte: `docs/handoffs/20261012-a-rota-da-qa/00-missao.md` — D21 do grill, registrado pelo `sdd-planner` (2026-10-14)
- [ ] **O registro do PR nasce depois do push e fica fora do sha verificado** — `agents/sdd-publisher.md:83`
  (`50-pr.md`) — o passo 2 roda o `TEST_CMD` antes do push e o passo 5 escreve o `50-pr.md` depois, sem dizer
  se ele entra no PR: commitado, move a cabeça do PR para um sha que nenhuma verificação viu (no alvo sem
  Actions, o `local/ci` publicado no sha anterior deixa de cobrir a cabeça); fora do commit, suja a árvore. No
  `lighthouse_project` o `sdd-publisher` o deixou fora, e a sessão coordenadora o commitou (`fe5f1ae`), rodou o
  gate de novo e republicou o `local/ci`. Direção: o contrato diz onde o registro mora e, se ele entra no PR,
  que a verificação do passo 2 corre de novo na cabeça final.
  — descoberto por `sessão coordenadora` na missão `20261013-amep-alignment-review` (2026-10-14)
- [ ] **O `gate:` cita saídas que a pasta de evidência da fase não guarda** — `templates/handoff.md:7` (`gate:`)
  — o template pede "comando + saída resumida" e não diz onde fica a saída inteira. Na DOCS da 3.5b do
  `dotp-remake`, o `gate:` do `45-docs.md` cita os três modos do `check-todo.sh` e um `grep -c 'RESOLVED by'`,
  medidos no `d343861`, e fecha com "Saídas em ~/.wt/docs-3-5b/"; a pasta não tem nenhum dos quatro (o
  `measure.sh` dela não os roda). O `/codereview` lê a pasta como a evidência da fase e mediu de novo no
  `34aa349` (mesmos valores). Direção: cada medida citada salva a saída onde o `gate:` diz, ou o `gate:` a exclui.
  — descoberto pelo relay do `sdd run` na missão `20261024-plano-3-5-b-auras-e-equipamento` (2026-10-25)
- [ ] **O platô da REVIEW lê só as letras, e pararia um laço que converge** — `agents/sdd-reviewer.md:62`
  (`Overall Grade`) — "as mesmas letras da rodada anterior" é platô, mas não separa o achado que a rodada
  não fechou do material que entrou entre as rodadas sem ser `R<n>`, nem da classe que a varredura pulou. No
  `lighthouse_project` a REVIEW ficou em B de r3 a r6, cada rodada com um achado real e menor, fechado pelo
  `R<n>` seguinte sem defeito novo; 4 dos 7 da r6 vieram de um bump commitado entre r5 e r6. A regra teria
  parado na r4; a r7, com só o `R7` entre as rodadas, deu A em tudo. Direção: só `R<n>` entra entre rodadas,
  o boot da rodada lista o commit que não fecha `R<n>`, e o platô compara a classe do achado, não só a letra.
  — descoberto por `sdd-reviewer` na missão `20261013-amep-alignment-review` (2026-10-14)
- [ ] **`sdd install --help` instala o kit, e `sdd link-agents --help` liga os agentes** — `bin/sdd:6073`
  (`--force`) — o `cmd_install` só compara o 1º argumento com `--force`, e o `cmd_link_agents` (`:11803`)
  não lê nenhum: o `--help` depois do subcomando executa. Num repo de rascunho, o 1º gravou `.sdd/config.sh`,
  `docs/handoffs/`, `TODO.md` e os agentes; o 2º, 8 symlinks e o `.gitignore`. O `main()` (`:11954`) só trata
  `--help` na 1ª posição; `run`, `retry`, `status` e `health` recusam opção desconhecida. Direção: todo
  subcomando recusa opção desconhecida e lê `-h/--help` como a própria ajuda, com um caso por efeito colateral.
  — descoberto por `sessão coordenadora` no `lighthouse_project`, ao ler o uso do `link-agents` (2026-10-16)

- [ ] **O remédio do `sdd kaizen` recusado ensina a mesma receita sem `--no-track`** — `bin/sdd:11841`
  (`shared_why`) — o motivo manda `worktree add ../<repo>-kaizen -b kaizen/<YYYYMMDD> origin/<branch>`, e a
  branch do juiz nasce rastreando a `main` (git 2.43, medido em repo de rascunho); o `docs/failure-modes.md:685`
  e o `docs/pipeline.md:1569` citam o motivo literal. Gêmeo do item acima, que a leva conserta só no
  `/sdd-plan` porque o `bin/` está congelado até o veredito. Direção: `--no-track` no motivo e nas duas citações.
  — descoberto pelo `sdd-planner` na missão `20261015-lote-8-a-leva-que-nao-parte-a-janela` (2026-10-15)

- [ ] **O planner chama a base de `main`, e o alvo pode ter outra** — `agents/sdd-planner.md:260`
  (`kaizen_log:`) — a exceção do `branch:` diz "naming the base branch itself (`main`)", e o `k8_base_refusal`
  (`bin/sdd:2201`) compara com o `$DEFAULT_BRANCH`. No `sales_quote`, cuja base é a `develop`, o planner pode deixar
  `kaizen_log` sem `skipped` numa missão na base, e quem recusa é o `gate_PLAN` (ou o `gate_DOCS` de um `--phase`
  forçado): falha fechada, mas o consumidor está fora da suíte do kit (D15). Direção: a frase nomeia o
  `DEFAULT_BRANCH` do alvo, e não o literal `main`.
  — descoberto pelo Codex no yokoten `JRC-Brasil/sales_quote#484`, sobre a cópia do `bad6168` (2026-10-15)

- [ ] **O `sdd install` adota a branch atual como base quando falta `origin/HEAD`** — `bin/sdd:6089`
  (`--show-current`) — sem `refs/remotes/origin/HEAD` o install grava a branch em que está, e instalar numa
  branch de trabalho é o caso comum: saiu `DEFAULT_BRANCH="plano-3-2"` no `dotp-remake` e `"chore/sdd-install"`
  no `magic_tutor` (este com `origin/main` no clone), sob o "Detected from origin/HEAD" do `config/starter.conf`;
  o "confirm it" da saída foi a única defesa. Direção: tentar `git ls-remote --symref origin HEAD` e um
  `origin/main`/`origin/master` existente antes da branch atual, e dizer que ela é palpite quando for ela.
  — descoberto por `retrofit-watch` no `dotp-remake` (2026-10-19)
  RECURRED 1: magic_tutor (2026-10-20)

- [ ] **A primeira instalação semeia o `TODO.md` em inglês, qualquer que seja o idioma** — `bin/sdd:6155`
  (`inst_lang`) — o install lê o `OUTPUT_LANG` da config que acabou de gerar do `starter.conf`, onde ele vem
  vazio, e cai no `templates/todo.md` (`:6103`). Ajustar o idioma depois não troca a semente: no `dotp-remake`
  (`pt-BR`) foi preciso apagar o `TODO.md` intocado e rodar o `sdd install` de novo. Direção: um `--lang` no
  install, ou a saída nomear o reinstall quando o `TODO_FILE` ainda é a semente de outro idioma.
  — descoberto por `retrofit-watch` na instalação do kit no `dotp-remake` (2026-10-19)

- [ ] **Nada instala nem confere o `/sdd-plan` que o `link-agents` manda rodar** — `bin/sdd:12100`
  (`/sdd-plan`) — a saída termina em "Next: $ /sdd-plan", mas o comando só existe onde alguém criou o link
  `~/.claude/commands/sdd-plan.md`, descrito só na ADR 0016 (máquina do operador); o README (`:45`) não o cita
  e o `sdd preflight` não o mede. Numa máquina nova o `~/.claude/commands` nem existia. Direção: o `link-agents`
  cria esse link, idempotente como os dos agentes, ou o README o põe nos passos de instalação.
  — descoberto por `retrofit-watch` na instalação do kit no `dotp-remake` (2026-10-19)

- [ ] **O `/sdd-plan` delega ao `sdd-planner` sem saída para o agente não registrado** — `commands/sdd-plan.md:75`
  (`sdd-planner`) — a lista de tipos de agente sai de quando a sessão abriu, e pode não ter o `sdd-planner`. No
  `dotp-remake` a sessão estava em `rea-projects/`, pai do alvo, e na 3.2b e na 3.2c o tipo faltou com o link já em
  `.claude/agents/`; no `magic_tutor` ela abriu antes do `sdd install` (`Agent type 'sdd-planner' not found`). Nos
  dois, um agente genérico mandado ler o `sdd-planner.md` como contrato conduziu o grill. Direção: o comando nomeia
  esse caminho de reserva, ou manda reabrir a sessão no alvo, depois do install.
  — descoberto pelo relay do `/sdd-plan` na 3.2b do `dotp-remake` (2026-10-19)
  RECURRED 6: dotp-remake/3.2c (2026-10-19); magic_tutor (2026-10-20); dotp-remake/3.4a (2026-10-22); dotp-remake/3.4b (2026-10-23); dotp-remake/3.5b (2026-10-24); sdd_agents/20261026-health-pula-catalogo (2026-10-26)
- [ ] **O `/sdd-plan` não diz o que fazer quando a sessão do relay cai no meio do grill** — `commands/sdd-plan.md:104`
  (`Relaying the grill`) — na 3.2c do `dotp-remake` a sessão caiu com uma pergunta pendente, e a chamada voltou "the
  session ended before this call's result was recorded, so its outcome is unknown". Na sessão nova, o `SendMessage` ao
  id do planner antigo voltou `Resuming agent`, e os artefatos saíram com as 10 decisões do grill intactas. Sem o passo
  escrito, o relay abre um planner novo e perde o grill, ou dá por respondida a pergunta de resultado desconhecido.
  Direção: o passo manda perguntar de novo o que estava pendente e retomar o mesmo agente pelo id.
  — descoberto pelo relay do `/sdd-plan` na missão `20261019-plano-3-2-c-perguntas-na-resolucao` (2026-10-20)
- [ ] **Commit do relay no meio do grill muda o HEAD que o planner mediu, e só o worktree é vigiado** —
  `commands/sdd-plan.md:89` (`rev-parse HEAD`) — na 3.2c do `dotp-remake` (sem worktree: o `sdd` fica fora do alvo) o
  dono pediu no grill uma linha no roadmap, e o relay commitou `b674421` na branch da missão depois de o planner medir
  a suíte em `d6d6cf8`. O relay mandou o HEAD novo junto da resposta seguinte, e o plano registrou a base certa. Sem
  isso, o plano cita uma base que não é o HEAD da aprovação. Direção: gravar `status` e `rev-parse` a cada hand-back
  vale também sem worktree, e o commit do relay vai ao planner com a resposta seguinte.
  — descoberto pelo relay do `/sdd-plan` na missão `20261019-plano-3-2-c-perguntas-na-resolucao` (2026-10-20)
- [ ] **O aceite do `/sdd-plan` mede de novo os Checks, nunca os fatos do contexto verificado** —
  `commands/sdd-plan.md:150` (`Measure again`) — o passo roda `--check` e `--red`, e a contagem que o plano cita passa
  sem medida: "22 `MutableEvents.Add` em 12 arquivos" (`01-plano.md`, `00-missao.md` e ADR 0007 da 3.3a do
  `dotp-remake`) eram 10 arquivos, e o relay só pegou porque conferiu por amostra com `grep -rc`. Na 3.2c, dois fatos
  sem medida (a Lobotomy, a 701.8) chegaram ao EXEC. Direção: o aceite reconfere por amostra as contagens e âncoras do
  contexto, ou o planner grava ao lado de cada contagem o comando que a mediu.
  — descoberto pelo relay do `/sdd-plan` na missão `20261020-plano-3-3-a-motor-de-gatilhos` (2026-10-20)
- [ ] **Sob `aprovacao: auto` o `/sdd-plan` deixa a missão sem commit na base e cala o passo seguinte** —
  `commands/sdd-plan.md:201` (`Anywhere else`) — no `magic_tutor` o `sdd why` deu `plan approved (auto)` com a
  pasta da missão em `??` na `main`: sem `sdd approve` ninguém corta a branch nem commita, e o passo 4 só diz
  "commit nothing". O planner supôs que o `sdd run` levaria a pasta sem rastreio; o relay leu o
  `ensure_mission_branch`, cortou a branch e commitou à mão, e o `sdd preflight` deu "working tree clean". Direção:
  um ramo `auto` no passo 4 (cortar o `branch:` e commitar a pasta antes do `sdd run`), ou o `sdd approve` aceitar
  `auto` e fazer só isso.
  — descoberto pelo relay do `/sdd-plan` na missão `20261020-lote-de-consertos` do `magic_tutor` (2026-10-20)
- [ ] **A pergunta que o planner devolve com tarefa sua ainda em segundo plano não chega ao relay** —
  `commands/sdd-plan.md:132` (`Long work between two questions`) — no `magic_tutor`, a Q3, a Q4 e a Q7 foram o fim
  de turno do planner com subagentes ou um teste dele ainda rodando; o relay só recebeu a volta seguinte ("a Q7
  continua esperando a resposta do humano") e teve de pedir o texto duas vezes. Direção: o planner não encerra o
  turno com pergunta enquanto tem tarefa viva, e toda pergunta pendente volta inteira na devolução seguinte; o relay
  que lê o número de uma pergunta que não repassou pede o texto antes de tudo.
  — descoberto pelo relay do `/sdd-plan` na missão `20261024-narracao-e-mesa` do `magic_tutor` (2026-10-24)

- [ ] **O planner marca o `- answer:` de pergunta que o humano não viu, e sob `auto` o gate já lê aprovado** —
  `agents/sdd-planner.md:52` (`Mark each answer`) — no `magic_tutor`, a decisão 7 ("confirmadas em bloco") saiu
  `- answer: (recommended)` com `aprovacao: auto` antes de a Q7 chegar ao humano, e o `sdd status` leu
  `plan approved (auto)`; o relay pegou lendo o arquivo. O `gate_PLAN` não lê as respostas (ADR 0018), e sob `auto`
  o passo 2 de "When the artifacts exist" pula o leitor D22. Direção: o relay roda o D22 a cada devolução e para
  quando o `M` passa das respostas que entregou; o planner escreve `- answer:` e `auto` só depois da resposta.
  — descoberto pelo relay do `/sdd-plan` na missão `20261024-narracao-e-mesa` do `magic_tutor` (2026-10-24)

- [ ] **Num repo sem interface, a QA para em `BLOCKED` ao seguir a própria instrução de escrever o teste do achado** —
  `agents/sdd-qa.md:11` (`writes:`) — o § 3 manda o achado de lógica virar teste da suíte do `TEST_CMD` (linha 107),
  e o `writes:` não cobre a suíte. No `magic_tutor`, a `QA:close` da `20261024-mesa-e-escolhas` (1522 s, US$ 7,96)
  commitou o sensor vermelho do F1 em `tests/test_replays.py`: `touched 1 path(s) outside its writes`, rc 3; destravou
  com `HAT_WRITES_EXTRA="sdd-qa: tests/**"`, que todo repo sem interface repetiria (a lista que o `config/schema.md`
  diz que a chave substituiu). Direção: decidir de quem é o sensor do achado de lógica (a QA, com a suíte no
  `writes:`, ou o EXEC do `F<n>`) e alinhar o texto e o `writes:` do chapéu.
  — descoberto pelo `sdd run` da missão `20261024-mesa-e-escolhas` do `magic_tutor` (2026-10-24)
- [ ] **Num subcomando, `-l` escolhe a missão que tem `-l` no nome, e `--help` vira "mission not found"** —
  `bin/sdd:341` (`resolve_mission`) — o argumento casa por substring (`-name "*${want}*"`), e `close`, `approve`,
  `phase`, `why`, `boot` e `census` passam o `$1` cru (`run` e `retry` recusam `-*`). No `magic_tutor`,
  `sdd close --help` deu `mission '--help' not found`, e com as missões reais `-n` casa só a
  `20261020-narracao-com-dicas` e `-l` só a `20261020-lote-de-consertos`: com JIRA ligado, `sdd close -l`
  fecharia o ticket dela, que tem o PR mesclado. Direção: `-h`/`--help` num subcomando imprime o uso dele, e o
  `resolve_mission` recusa argumento que começa com `-`.
  — descoberto por `retrofit-watch` no `magic_tutor` (2026-10-20)
- [ ] **A guarda do kit para a corrida do alvo por um merge só de docs no checkout do kit** — `bin/sdd:4349`
  (`kit_guard_check`) — compara o par cru (HEAD e sujeira) e não lê o rótulo `sdd:` do reflog (anatomia §6). No
  lighthouse o operador puxou o #246 e o #254 (só `docs/`, `TODO.md` e catraca) para o checkout principal do kit
  com a corrida viva: `kit-touched` 2×, 2 células `refez` e 2 das 6 intervenções da missão; o reflog dizia
  `merge origin/main: Fast-forward`, sem rótulo. Direção: com ADR, só o HEAD movido por entrada do reflog sem o
  rótulo da sessão (alheia, como esse fast-forward) e que não toca `bin agents templates config` vira aviso no
  journal; a sujeira não commitada, que não deixa reflog, e o resto continuam parando a linha.
  — descoberto por `sdd-kaizen` na missão `20261014-amep-entrada-em-dois-niveis` (2026-10-20)
- [ ] **A REVIEW aprovada não vê o código que entrou depois dela** — `bin/sdd:1925` (`gate_REVIEW`) — o gate lê
  a nota da última rodada e não compara o commit que ela revisou com o HEAD. No lighthouse o F5–F8 (emenda E1–E6)
  e o R3 (P2 do Codex no PR #29) entraram depois da r2 em A, e o humano forçou a r3 e a r4 com `--phase REVIEW`:
  2 das 6 intervenções da missão. É o espelho do D21, em que só `F<n>` reabre a QA. Direção: a rodada grava o
  commit revisado, e código commitado depois dele reabre a REVIEW ou é nomeado no motivo do gate.
  — descoberto por `sdd-kaizen` na missão `20261014-amep-entrada-em-dois-niveis` (2026-10-20)
- [ ] **O `/sdd-plan` só manda para worktree no checkout do kit, não com outra missão em voo no alvo** —
  `commands/sdd-plan.md:30` (`KIT-TOUCHED`) — no `lighthouse_project` a M2 (`sdd run`, LH-8) rodava no checkout
  principal quando o humano pediu o plano da peça C. Pelo passo 2 o planner escreveria ali, e o `hat_guard_check`
  (`bin/sdd:4616`) acusaria o `00-missao.md` alheio na fase em curso (`HAT-CROSSED`); e a regra do relay de parar
  quando o `HEAD` do checkout muda dispara à toa, porque a corrida commita lá. O relay abriu um worktree e vigiou só
  o que não era da M2: o `pipeline.log` dela fechou sem `HAT-CROSSED` nem `FOREIGN-COMMIT`. Direção: o passo 2
  vale com `sdd run` vivo no alvo, e a checagem do relay nomeia o que a corrida pode mudar.
  — descoberto pelo relay do `/sdd-plan` na missão `20261020-amep-anexo-na-demanda` (2026-10-20)
- [ ] **Numa worktree sem o `.venv`, o gate do EXEC lê o `TEST_CMD` que não rodou como suíte vermelha** —
  `bin/sdd:1508` (`run_check_cmd`) — o `.venv` é ignorado pelo git, então a worktree nasce sem ele, e o
  `.venv/bin/python` relativo do `TEST_CMD` não existe. No `magic_tutor` (missão `20261021-dica-mais-rapida`,
  worktree `~/.wt/mt-19`) o log `gate-exec-test-20261021-195209-*.log` traz só `.venv/bin/python: No such file or
  directory` (rc 127), e o `GATE_WHY` dizia `TEST_CMD failed`, como se a suíte tivesse reprovado. O contorno foi um
  link `.venv` para o venv do checkout principal e a linha `.venv` no `.git/info/exclude`. Direção: o rc 127 ganha
  um `GATE_WHY` próprio ("o `TEST_CMD` nem rodou"), que nomeia o que faltou na árvore.
  — descoberto pelo relay da missão `20261021-dica-mais-rapida` do `magic_tutor` (2026-10-21)

- [ ] **O `sdd-executor` lançado como subagente fecha o último incremento e volta sem o `20-handoff-exec.md`** —
  `agents/sdd-executor.md:175` (`20-handoff-exec.md`) — o §6 manda escrever o handoff quando nenhuma linha fica
  `pending`. No `magic_tutor` (missão `20261021-dica-mais-rapida`), o relay lançou como subagente o executor do I11,
  o último: ele commitou o `I11 done` (`508c4c9`, 19:48) e devolveu o relatório sem o handoff, que só veio quando o
  relay pediu (`ae3cc8e`, 19:52). Pelo `sdd run`, o gate do EXEC acusa a falta; fora dele, nada acusa. Direção: o
  §5 avisa que, sem linha `pending`, o §6 faz parte do mesmo incremento, e o relatório final do executor diz se o
  handoff foi escrito.
  — descoberto pelo relay da missão `20261021-dica-mais-rapida` do `magic_tutor` (2026-10-21)

- [ ] **O chapéu não pode declarar MCP, e o executor fica sem o REA** — `bin/sdd:5461` (`--strict-mcp-config`) —
  toda fase roda sem servidor MCP, e um `mcp:` no chapéu para o runner ("carving those servers into a
  --mcp-config is not implemented"). No `dotp-remake`, ler o `DotP_D14.exe` pelo MCP `rea` só cabe no PLAN: na
  3.3d o planner levantou no REA o que o EXEC precisaria ler, e o dono pediu o REA também no `sdd run`. Direção:
  montar um `--mcp-config` com só os servidores que o chapéu declara, tirados da config do humano (o `rea` traz
  frida, gdb e adb: o recorte é a fronteira), e o `hat_init_facts` já compara o declarado com o visto.
  Fonte: grill da 3.3d do `dotp-remake` (2026-10-21) — descoberto por `sdd-plan` (relay) no `dotp-remake` (2026-10-21)

- [ ] **O `gate_PR` não lê o `status: blocked` do `50-pr.md`, e o runner compra outra sessão do publisher** —
  `bin/sdd:2614` (`gate_PR`) — só o `gate_TICKET` e o `gate_QA` armam o `GATE_HANDOFF_BLOCKED`. Na
  `20261024-dica-na-hora` do `magic_tutor`, o publisher parou num conflito com a base e commitou o `50-pr.md`
  com `status: blocked`. O commit contou como avanço ("carrying on"), e uma 2ª sessão (`e5ab0aaf`, US$ 0,12)
  reconferiu o mesmo conflito antes do `BLOCKED`. O `templates/review.md` também declara `blocked`, e o
  `gate_REVIEW` não o lê: lá, a sessão repetida seria a da REVIEW (não medido). Direção: os dois gates armam o
  marcador, pelo contrato escrito acima do `GATE_HANDOFF_BLOCKED`.
  — descoberto por `sessão coordenadora` na missão `20261024-dica-na-hora` do `magic_tutor` (2026-10-25)

- [ ] **O publisher bloqueado manda o humano fazer `git rebase`, e o rebase tira os hashes dos handoffs da história** —
  `agents/sdd-publisher.md:48` (`Conflict`) — o contrato manda parar no conflito com a base, sem dizer qual saída
  indicar, e na `20261024-dica-na-hora` do `magic_tutor` as duas sessões indicaram `git rebase origin/main`. O
  checkpoint e os handoffs citam hashes, e o `gate_EXEC` exige cada `Commit` na história do `HEAD`
  (`bin/sdd:1456`). Depois do rebase, o run seguinte para no EXEC (`no_work_check`, forma b), e o humano
  reescreve 9 células (pelo código, não medido). Lá, o merge da base destravou (`c6f043c`). Direção: o
  contrato passa a indicar `git merge origin/<base>`, e o `BLOCKED` do PR diz o mesmo sem depender da sessão.
  — descoberto por `sessão coordenadora` na missão `20261024-dica-na-hora` do `magic_tutor` (2026-10-25)

- [ ] **Com o passo 2 pulado, o `/sdd-plan` não olha o branch antes de o planner ler o repo** —
  `commands/sdd-plan.md:56` (`skip this step`)
  — com o kit fora do alvo, o branch atual só aparece na pergunta de aprovação, e o `sdd approve` corta dele a
  branch da missão. No `ui24_agent` o checkout estava em `retrofit-ui24-operator-mcp-vivo`, com a PR #83 aberta:
  o planner leria um checkout que não é a base, e a missão nasceria com commits de outra PR. Direção: no passo
  3, comparar `git branch --show-current` com o `DEFAULT_BRANCH` e, se divergir, perguntar a base ao humano
  antes de delegar.
  — descoberto por `retrofit-watch` no `ui24_agent`, missão `20261024-fase8-preamp-fisico` (2026-10-24)

- [ ] **O relay não prevê que o job em background do planner repete a pergunta já feita** —
  `commands/sdd-plan.md:119` (`Nothing else resumes the planner`)
  — a regra cobre a mensagem do relay que não responde nada, não o fim de um job que o próprio planner lançou. No
  grill do `ui24_agent` a suíte em background terminou depois da hand-back, e o planner devolveu a pergunta 1 de
  novo, com a resposta do humano já com o relay. Sem dano, porque a resposta nomeou a opção pelo texto. Direção:
  o relay responde uma vez e cita a primeira pergunta; o planner não fecha turno de job repetindo pergunta aberta.
  — descoberto por `retrofit-watch` no `ui24_agent`, missão `20261024-fase8-preamp-fisico` (2026-10-24)

- [ ] **O `sdd approve` commita o ADR do `adr:` sem tirar o `proposed`** — `bin/sdd:8604` (`proposed`) — o `sdd adr new`
  escreve `proposed`, e o `cmd_approve` (`:8835`) só põe o arquivo do `adr:` no commit da aprovação. O status final
  depende de quem escreveu o ADR: no `dotp-remake`, o 0011 nasceu `accepted` à mão (`02c19f5`) e o 0012 ficou
  `proposed` (`a81c28f`) até a REVIEW r1 da 3.4b achar e a DOCS mudar à mão. Direção: o `sdd approve` troca o
  `proposed` do ADR do `adr:` por `accepted` no mesmo commit, com probe.
  — descoberto por `sdd-reviewer` na missão `20261023-plano-3-4-b-ate-o-fim-do-turno` (2026-10-24)

- [ ] **A linha `kit:` do handoff não tem quem a transporte** — `agents/sdd-publisher.md:69` (`TODO_FILE`) — o
  `templates/handoff.md:63-65` manda o achado do kit numa missão de alvo morar no handoff, marcado `kit:`, levado por
  "um humano ou a triagem do `sdd kaizen`"; mas o publisher lê todo handoff (`:25`) e o contrato dele só chama de
  achado fora de escopo o que foi para o `TODO_FILE`, sem falar de `kit:`, e o `sdd-kaizen` só tria o `TODO.md` do kit
  (`agents/sdd-kaizen.md:209-211`). Na 3.4b do `dotp-remake`, o `kit:` do `45-docs.md:187` (o item "O `sdd approve`
  commita o ADR do `adr:` sem tirar o `proposed`") não chegou ao PR #19 nem a este arquivo até o relay ler o handoff.
  Direção: o publisher lista os `kit:` dos handoffs no PR, para o humano levar, e o `gate_PR` confere a contagem.
  — descoberto por `sessão coordenadora` na missão `20261023-plano-3-4-b-ate-o-fim-do-turno` (2026-10-24)

- [ ] **A DOCS deixa a lição reincidente só no `KAIZEN_LOG.md`** — `agents/sdd-docs.md:53` (`KAIZEN_LOG.md`) — a
  entrada traz o que se aprendeu, e nada manda cruzar a lição com o que já foi padronizado. Na 3.4b do `dotp-remake`
  ela mesma dizia "terceira vez em três fatias" (o estado novo sem os leitores antigos) e não virou linha ⛔ com texto
  proposto para `.claude/rules/`, que a DOCS só escreve como proposta. Só a rodada `/codereview` sobre a DOCS pegou
  (MEDIUM), e o relay padronizou à mão (`859acf9` no alvo). Direção: lição que o próprio log chama de reincidente vira
  linha ⛔ com texto proposto, ou leva o motivo escrito de não virar.
  — descoberto por `sessão coordenadora` na missão `20261023-plano-3-4-b-ate-o-fim-do-turno` (2026-10-24)

### Saída humana e cosmética

- [ ] **O "Como verificar" do PR copia o `$SDD_HOME` do `TEST_CMD`, e o comando falha fora do runner** —
  `agents/sdd-publisher.md:59` (`how to verify`) — o publisher monta "the commands, in order" pelos handoffs e
  troca `$TODO_FILE` e `$DEFAULT_BRANCH` pelo valor, mas deixa o `$SDD_HOME`, que só existe dentro do `sdd`
  (`bin/sdd:68`). No PR #72 do `magic_tutor`, a linha do `check-todo.sh` colada numa shell deu rc 127
  (`/tests/check-todo.sh`), e o `sdd preflight`, que roda o mesmo `TEST_CMD` com o ambiente do runner, deu ok.
  Direção: o "how to verify" manda rodar o gate por `sdd preflight`, ou só usa o que a shell do leitor tem.
  — descoberto por `retrofit-watch` no `magic_tutor` (2026-10-23)

- [ ] **O `sdd preflight` reprova a árvore suja sem dizer os caminhos, nem que eram só não versionados** —
  `bin/sdd:7042` (`git status --porcelain`) — no `magic_tutor` o preflight disse só "working tree dirty", e o
  porcelain tinha só `??`: 4 `partidas/*.md` que o app grava e o repo deixa fora do git de propósito (nomes de
  oponentes) e a `.claude/worktrees/` do harness. Foi preciso rodar o `git status` à mão e pôr os dois no
  `.git/info/exclude`. Direção: a falha lista os caminhos (até uns 10) e, quando todos são `??`, nomeia o
  `.git/info/exclude` como saída para dado do app fora do git.
  — descoberto por `retrofit-watch` no `magic_tutor` (2026-10-20)

- [ ] **O motivo do gate_QA não diz se o caso e2e vermelho já caiu antes** — `bin/sdd:1857` (`gate-qa-e2e`) —
  um caso intermitente anterior à missão devolve a fase ao `sdd-qa`, que gasta o começo descobrindo isso:
  no alvo, o `frete-ipi.spec.ts:319` já tinha caído duas vezes, com os logs de gate em disco. Direção: o
  `GATE_WHY` cita quantas vezes cada caso vermelho já caiu nos logs `gate-qa-e2e` anteriores.
  Fonte: `docs/handoffs/20261012-a-rota-da-qa/00-missao.md` — achado `kit:` do `sdd-qa` em
  `20261005-mascaras-ncm-e-painel`, transportado por `sdd-kaizen` (2026-10-12)

- [ ] **O `sdd status` manda `sdd run` com o app fora do ar, e a fase fechada volta a pendente** — `bin/sdd:7945`
  (`run: sdd run`) — com o `30-handoff-qa.md` em `done`, o `gate_QA` refaz a e2e ao vivo; app caído vira `· QA`,
  `next phase: QA` e `run: sdd run`, embora o motivo diga "no session can start it" (`:1867`). Esse `sdd run`
  compra uma sessão `QA:close` (opus no alvo) antes de escalar `app-down` (`tests/check-autonomy.sh:2557`), e cada
  leitura roda a e2e, que no `lighthouse_project` grava uma demanda e gasta um número da sequência. Direção: o
  status lê o `GATE_APP_DOWN` e diz "fechada, e2e não re-verificável agora: app fora", com o remédio da escalada.
  — descoberto por `sessão coordenadora` na missão `20261013-amep-alignment-review` (2026-10-14)

- [ ] **O `sdd status` fica calado enquanto o gate do EXEC roda o `TEST_CMD`** — `bin/sdd:7888` (`--no-gates`) —
  depois da linha do TICKET, nada sai durante a suíte do alvo: 1 min 57 s no `ui24_agent`, medido com
  `sdd status 20261003-fase8-s8-dinamica-eq-restantes > arquivo`. Num `timeout 60` a espera foi tomada por
  travamento, e o erro de missão ausente não cita o `--no-gates`, que lê só o disco. Direção: uma linha
  "rodando o TEST_CMD (<cmd>)…" antes do gate que a chama, e o `--no-gates` na mensagem de uso.
  — descoberto por `retrofit-watch` na sessão do `ui24_agent` que planejou a S9 (2026-10-17)

- [ ] **O fim da corrida diz que só falta o merge, e o `sdd close` some** — `bin/sdd:9417` (`pipeline complete`) —
  o `sdd run` e o `sdd status` (`:7700`) fecham com "only the merge is left", e nenhum template, chapéu ou comando
  cita o `sdd close <missão>` pós-merge (`docs/pipeline.md` § "After the PR"). Medido no `sales_quote`: os 7
  cartões da campanha (SQ-156 a SQ-162) seguiram "Em andamento" depois do merge, até o operador fechá-los à mão
  em 2026-10-18. Direção: com `JIRA_ENABLED=true`, a mensagem final e o corpo do PR nomeiam o `sdd close`.
  — descoberto por `sessão coordenadora` na missão `20261018-silencios-do-formulario-e-dos-dialogos` (2026-10-18)

- [ ] **O README chama o repositório de privado, e ele é público** — `README.md:45` (`PRIVATE`) — o
  comentário do `git clone` diz "PRIVATE repository", e `gh repo view j0ruge/sdd_agents` responde
  `"isPrivate": false`; quem instala pode concluir que precisa de acesso concedido ou de token. Direção: tirar
  o comentário, ou trocá-lo pelo que for verdade, com a data.
  — descoberto por `retrofit-watch` na instalação do kit no `dotp-remake` (2026-10-19)

- [ ] **O corpo do PR promete CI para os sensores novos, e o alvo pode não ter CI** — `templates/pr-body.md:26`
  (`Sensores novos`) — a frase "rodam no CI a partir deste PR" é fixa no template, o `agents/sdd-publisher.md:61`
  manda listar o que "start running in CI", e nada confere o alvo. O `dotp-remake` não tem `.github/workflows`
  (os checks dos PRs são só GitGuardian e CodeRabbit), e o corpo saiu com a frase no #10 e no #11 (3.2b),
  corrigida à mão para "rodam na suíte local, `dotnet test`; o repositório não tem CI". O `magic_tutor` também
  não tem `.github/workflows`. Direção: o publisher só afirma CI com um workflow em `.github/workflows/`; sem
  ele, diz onde a suíte rodou: pelo `TEST_CMD`.
  — descoberto por `sessão coordenadora` na missão `20261019-plano-3-2-a-magicas-de-uma-vez` (2026-10-19)
  RECURRED 1: magic_tutor/pr25 (2026-10-20)

- [ ] **O `sdd run` diz que commita na base quando a TICKET vai cortar o branch antes** — `bin/sdd:6314`
  (`warn_if_on_base_branch`) — compara só o branch atual com o `DEFAULT_BRANCH`. No `lighthouse_project` (LH-8,
  `JIRA_ENABLED=true`, `branch:` no placeholder) o `sdd run` de `develop` avisou "commits straight into it", e o
  `8f6b46f` da TICKET já nasceu no branch da missão: o `develop` local ficou no `e03583a` do approve, cujo aviso
  era verdadeiro. Aviso que grita lobo ensina a não ler. Direção: o `cmd_run` cala com `mission_branch_declared`
  vazio e a TICKET pendente, com caso nos dois lados.
  — descoberto pelo relay do `/sdd-plan` na missão `20261016-lighthouse-instala-object-storage` (2026-10-20)

- [ ] **O corpo do PR copia pendência do plano que a revisão já fechou** — `agents/sdd-publisher.md:62`
  (`decisions for a human`) — a união das perguntas abertas dos handoffs traz as do `00-missao.md`, escritas antes da
  corrida, sem conferir o desfecho. No PR #13 do `dotp-remake` (3.3a) saiu "Decidir sobre a diferença entre a nota B
  da REVIEW do kit e a nota A do Fluxo de entrega", e o `40-review-r1.md` deu A em todo critério; o relay corrigiu o
  corpo à mão. Direção: a pendência do plano que um handoff posterior responde sai, ou vai junto da resposta.
  — descoberto pelo relay do `sdd run` na missão `20261020-plano-3-3-a-motor-de-gatilhos` (2026-10-20)

- [ ] **O `sdd preflight` imprime "printf: erro de escrita: Pipe quebrado" com a `READ_EXTRA` preenchida** —
  `bin/sdd:5806` (`kit_read_rules`) — o `read_rules_cover` sai do `while` no 1º casamento e o produtor segue
  escrevendo num pipe sem leitor (`:5353`, `:5360`). No `lighthouse_project` foram 7 linhas antes do "third-party
  skills present", com veredito `ok`. As funções reais, extraídas, repetem o ruído sob SIGPIPE ignorado (como num
  pai Node) e calam com a ação padrão; quem o ignorava naquela corrida não foi achado. Erro de escrita num preflight
  verde se lê como falha. Direção: ler a lista inteira (`mapfile -t`) antes de casar, com caso sob `SIG_IGN`.
  — descoberto por `claude` no `lighthouse_project`, ao preencher a `READ_EXTRA` (2026-10-23)

- [ ] **A ajuda do `sdd run` não diz como soltá-lo da sessão que o dispara** — `bin/sdd:11969`
  (`sdd run <mission>`) — o run leva horas, e quem o dispara de uma sessão do Claude Code e vai dar `/clear` ou
  fechar o terminal precisa destacá-lo, sem saber onde ler o progresso depois. Na peça C do `lighthouse_project`
  funcionou `nohup setsid sdd run <m> > ~/.cache/<log> 2>&1 < /dev/null &`: o pai virou o PID 2140, fora da
  sessão, e a TICKET (LH-9) e a EXEC seguiram. Direção: a ajuda mostra essa forma e onde ler o log, ou um
  `--detach` que a faz e imprime o caminho do log.
  — descoberto por `retrofit-watch` na missão `20261020-amep-anexo-na-demanda` do `lighthouse_project` (2026-10-21)

### Comentário e registro

### Idioma

- [ ] **A devolução do planner ao relay não tem regra de idioma** — `agents/sdd-planner.md:273` (`OUTPUT_LANG`) —
  o `## Language` cobre só os três artefatos e o parágrafo do relay (`:67`) não fala de idioma; só a seção
  `## Relaying the grill to the human` do `commands/sdd-plan.md` pede a devolução "written in `OUTPUT_LANG`". No grill
  da 0.4.0 do `lighthouse_project` (`pt-BR`), a 1ª devolução veio inteira em inglês apesar do prompt de delegação em
  pt-BR, e outra abriu em inglês depois de um lembrete: o relay teria de traduzir, e traduzir é parafrasear. Causa não
  verificada. Direção: o `## Language` estende o `OUTPUT_LANG` às devoluções, com um caso que o meça.
  Fonte: `lighthouse_project/docs/handoffs/2026-10-14-planejar-0-4-0.md` — relay do `/sdd-plan` (2026-10-14)

### Custo e escala

- [ ] **O mapa de tempos do catálogo de mutação mora no checkout, e o worktree de cada branch roda sem ele** —
  `tests/check-mutation.sh:7576` (`KILLERS_FILE`) — o mapa (`.sdd/cache/`, fora do git) põe primeiro o passo que
  matou cada mutante e lança os mais longos antes (40 mutantes: 4796 s → 1959 s, no comentário do mapa). Ele é
  gravado no fim do catálogo, no `.sdd/cache/` daquele checkout, e o trabalho do kit roda num worktree por branch:
  em 2026-10-25, nenhum dos 8 checkouts do kit nesta máquina tinha o mapa, e o `sdd health` do
  `sdd_agents-gate-sem-saida` fez 299 de 775 mutantes em ~152 min (238 s cada, em média). Direção: o mapa mora
  no `git rev-parse --git-common-dir`, que os worktrees dividem, ou o `sdd health` avisa o custo de rodar sem ele.
  — descoberto por `sessão coordenadora` no `magic_tutor` (2026-10-25)

- [ ] **Um incremento que roda por quase 1 h não cabe no `sdd-executor`, que não tem `Monitor`** —
  `agents/sdd-executor.md:7` (`disallowedTools`) — a fronteira do chapéu
  (`docs/superpowers/specs/2026-09-03-a-fronteira-do-chapeu-design.md`) tira o `Monitor` e o `ScheduleWakeup` do
  executor, e o Bash em primeiro plano para em 10 min. No `magic_tutor` (missão `20261021-dica-mais-rapida`), o I8 a
  I10 eram a bancada real (7 rodadas do coach, de 45 min a 1 h em segundo plano), e a sessão do relay os rodou à mão
  ("rodados pela sessão do relay", `checkpoint-notas.md`). Direção: o `/sdd-plan` marca como do operador o
  incremento cujo comando passa de 10 min, com o comando e o critério no plano, e o runner não o entrega ao executor.
  — descoberto pelo relay da missão `20261021-dica-mais-rapida` do `magic_tutor` (2026-10-21)

### Sem seção — chegaram depois da última classificação

> ⚠️ Esta seção **chamava-se "Adiados por YAGNI"** e não guarda mais nenhum adiamento: os três que
> havia (espelho global de vereditos, multi-missão por `git worktree`, `sdd digest`) viraram Y1–Y3
> da tabela **Decisões adiadas por YAGNI** do [`CONTEXT.md`](CONTEXT.md), onde cada um nomeia o
> evento que o reabre — pela régua D15, ausência de consumidor é decisão adiada, não achado. Os
> itens abaixo são achados de verdade que foram apendados ao fim do arquivo e nunca classificados;
> quem mexer num deles o move para a seção a que ele pertence.

## Decidido — não reabrir
<!-- sdd:decided -->
- **O laço de melhoria da sessão interativa não enxergaria o kit** — resolvido fora do kit, sem commit deste repo: `retrofit-watch` 0.2.0 (`j0ruge/skills@960e47b`) reconhece `/sdd-*`, subagente `sdd-*` e o CLI `sdd` (2026-10-01)
- **O `RESOLVED by` não deixa a catraca descer na missão que conserta** — decidido: o item fica até o merge e sai no chore pós-merge, `templates/todo.pt-BR.md` § Ciclo de vida (2026-09-25)
- **O stub do `sdd adr new` manda escrever em `OUTPUT_LANG`, e o `check-lang.sh` lê `docs/adr/` como inglês** — limite declarado pela D15, não achado: `bin/sdd:7293` (2026-09-25)
- **Aviso de merge durante a janela do juiz** — decidido fora: depois do conserto do eixo (I2) só mudança real do kit rompe a janela, e essa é ruptura legítima — `docs/adr/0014`, missão `20261001-a-janela-nao-se-parte` (2026-10-01)
- **A refutação R2 do handoff de QA citaria evidência que não existe** — refutado: o prompt renderizado nomeava o arquivo, porque o boot_prompt expande `$TODO_FILE` para TODO.md; o item conferiu a fonte, não o prompt — `148f693:bin/sdd:1621` (2026-10-03)
- **O sdd status travaria mais de 2 min segurando a trava do checkout** — refutado como defeito sem causa e como fila: sem `--no-gates` o status avalia todo gate sob a trava, TEST_CMD e E2E_CMD incluídos, e a segura enquanto eles rodam, sem prazo; a trava é não-bloqueante, então quem chega depois não enfileira, recebe CHECKOUT-BUSY com o dono; a leitura sem trava é `sdd status --no-gates` — `bin/sdd-coordination.py:504` (2026-10-03)
- **O cmd_kaizen escalaria no-progress como fricção no rubric depois de um retry que moveu** — decidido: o código escala sem olhar o moved2, mas as linhas KAIZEN são `$meta` e ficam fora do eixo do juiz nos dois leitores; o humano lê "two sessions without satisfying the gate", que é verdade — `bin/sdd:10211` (2026-10-03)
- **A Âncora 3 do gate_QA bloquearia a missão com bug aberto de OUTRA missão** — decidido por desenho: a ADR 0009 mantém recusada a alternativa (A) da 0006, porque contar só o bug da missão troca o laço por dívida calada; a saída humana é `deferred` — `docs/adr/0009-the-genre-gains-deferred-and-hats-gain-project-exceptions.md` (2026-10-03)
- **Slug de missão em pt-BR não poderia ser citado na superfície inglesa** — decidido: o selftest do check-lang afirma de propósito que slug em prosa é pego (exit 95); slug se cita numa linha `Spec:`/`ADR:` ou sem stopword — `tests/check-lang.sh:195` (2026-10-03)
- **As skills qa-report e qa-execution não conhecem o campo Closable by** — decidido: o lado do kit fechou (o sdd install semeia o campo, o sdd preflight reprova sem ele, o sdd-qa marca); ensinar a skill de terceiro é retrofit no marketplace, não item do kit — `f7bcf10` (2026-10-03)
- **O rows=13 do gate: da QA de 20260818-lote-facil não sai do extrator** — decidido: o número citado não reproduz (o extrator dá 8, o próprio item o mediu) e a conclusão da J6 segue certa; handoff de fase encerrada não se reescreve — `docs/handoffs/20260818-lote-facil/30-handoff-qa.md:7` (2026-10-03)
- **Nada mediria se o esperado de um Check do checkpoint ainda reproduz** — limite declarado: o cabeçalho do sensor diz que ele não mede o valor ao lado da seta, de propósito; rodar os Checks custaria a suíte por célula — `tests/check-checkpoint.sh:45` (2026-10-03)
- **O kit não tem CHANGELOG.md, e a fase DOCS cobraria um** — decidido: a linha do CHANGELOG na DOCS é condicional (só quando a missão entrega algo visível) e nenhum gate a cobra; o registro do kit é KAIZEN_LOG.md, handoffs, git log e corpo do PR — `agents/sdd-docs.md:49` (2026-10-03)
- **O teto de orçamento não conhece "missão reaberta"** — decidido: a porta humana para gastar mais é `--budget-override` com a nota intervention: que o runner escreve (anatomia §7) — `bin/sdd:5031` (2026-10-03)
- **O gate: do frontmatter da revisão só é cobrado quando existe** — decidido, sem conserto: as 6 rodadas sem o campo (de 30) são de 2026-08-16/17, anteriores a ele, e as 24 seguintes o trazem — `bin/sdd:1773` (2026-10-03)
- **run_phase cria o diretório de log da sessão sem guarda** — decidido, sem conserto: a falha é alta e fechada (rc 1 antes de abrir sessão, zero gasto) e nunca foi observada — `bin/sdd:4670` (2026-10-03)
- **Check de ausência reprovaria o conserto que precisa citar o defeito** — decidido: falha fechada, um caso em 2026-08-16; a regra de redação de Check do planner vem com o achado do Check que nasce verde, na leva 4 — `docs/handoffs/20260816-runner-sem-dividas/checkpoint.md:20` (2026-10-03)
- **A suíte segue acima do alvo "<30 s" da D7** — decidido: o critério (4) da D7 passa a ser o prazo por passo do step_timeout (8× o tempo ocioso, piso 60 s), que já é o orçamento medido e cobrado; o 🚩 do CONTEXT.md fecha — `tests/run-all.sh:168` (2026-10-03)
- **O 2º Python do worker custa ~30 ms em toda chamada coordenada** — decidido: 30 ms por chamada não chega ao humano; provar o worker por FD herdado pede ADR e fica na gaveta, F1 P1 — `docs/superpowers/specs/2026-09-23-a-gaveta-do-kit.md:67` (2026-10-03)
- **35% do docs/pipeline.md seria um subsistema só, e cresceria a cada missão do ledger** — decidido, sem refator: as seções do ledger e do juiz são 525 de 1562 linhas (33,6%), estáveis em 33–34% desde 2026-09-29 depois do pico de 48% em 2026-08-31, e nenhum boot_prompt lê o pipeline.md, então nenhuma fase paga o índice inteiro; reabre se a fatia passar de 40% ou se um boot passar a ler o arquivo — `docs/pipeline.md:1091` (2026-10-04)
- **Test Coverage = A do revisor implicaria que os casos negativos existem** — decidido como limite: a nota de revisão é rótulo que o próprio modelo escreve, e a anatomia §4 o declara; a parte barata e real, o executor sabotar a linha nova de um R<n>, é o I3 de 20261004-lote-4-a-catraca-zera; reabre quando um segundo P1 escapar de um Test Coverage = A numa missão headless — `.claude/rules/anatomia-do-agente.md:126` (2026-10-04)
- **Nenhum instrumento mediria prosa de CONTRATO fora de templates/** — decidido: a fase DOCS é a dona dessa prosa (a checklist de drift do 45-docs.md percorre o diff inteiro da missão), o config/schema.md já é medido contra o load_config pelo sdd health, a tabela de agentes do README bate 8 = 8, e os drifts registrados foram pegos antes do merge; o limite está no cabeçalho do sensor; reabre quando um drift de contrato escapar para a main — `tests/check-templates.sh:39` (2026-10-04)
- **O checkpoint não teria grafia para incremento cujo produto não é commit** — decidido: a grafia é o commit de registro — o ato fora do git (e-mail, página da KB, config no IdP) deixa na pasta da missão um record-<ID>.md com o que foi feito, a URL ou o ID e a data, e o hash dele vai na célula Commit que o gate_EXEC já lê; passo pós-merge ou de janela externa sai da tabela para as Pendências para o humano do 00-missao.md ou para a missão seguinte (o token de espera é o Y8 do CONTEXT.md); os casos medidos (o I5 da LH-3, KB sem commit; o I6 de 20260918-a-excecao-do-chapeu-e-o-genero-diferido, pending eterno; os I1–I3 de 20260825-cif-forma-pagamento no sales_quote, blocked eterno) não são migrados, porque handoff fechado não se reescreve — `templates/checkpoint.md:35` (2026-10-04)
- **Drift de comentário em código não teria dono: nem a DOCS nem a EXEC** — decidido: comentário de código é do código — a REVIEW o manda para um lote R<n> da EXEC, a DOCS marca ⛔ com o texto proposto (o bin/sdd fica fora do writes: dela, e o gate só recusa ⛔ em documento que ela pode escrever), ou ele vai para o TODO_FILE quando o carimbo não compensa; o caminho estreito "a DOCS edita só hunk de comentário" falharia aberto, porque o bin/sdd tem 6 heredocs e # dentro de string, awk e jq; 0 hat-crossed por código em 15 sessões DOCS desde 2026-09-12 — `agents/sdd-docs.md:104` (2026-10-04)
- **A entrada do índice na árvore do kit leva vírgula inicial (`@,100644:…`)** — decidido (D15): o mawk avalia o lado esquerdo de `ix[q] = (q in ix) ? … : e` antes do `in`, então toda entrada nasce com `,`; é representação interna, igual nas duas amostras que a guarda compara, e o motivo do `kit-touched` não a imprime — sem consumidor, não é achado — `bin/sdd:4003` (`kit_guard_tree`), revisão final de `20261008-lote-6-as-quatro-que-faltam` (2026-10-08)
- **`kit_checkout_targets_run` com `REPO_ROOT` vazio responderia "recusado"** — decidido (D15): inalcançável, a recusa de identidade do `cmd_kaizen` vem antes e o `load_config` sempre publica a raiz; reabre se a função ganhar outro chamador — `bin/sdd:11231` (`kit_checkout_targets_run`), revisão final de `20261008-lote-6-as-quatro-que-faltam` (2026-10-08)
- **A regra 2 do check-checkpoint deixa abertos os casos que só o runtime decide** — decidido sem conserto (decisão 1 do lote 10): um leitor de texto não decide o terceiro descritor, o alvo de runtime (`2>$f`), a grafia da stdout que o sistema resolve, a palavra que abre com expansão lida como operando, o `POSIXLY_CORRECT` ou outro grep, nem o nome que substitui o grep; a peça que mediria a Check em execução não tem dono (no PLAN a asserção ainda não existe, e gate não executa texto de modelo); 0 de 67 checkpoints escrevem uma dessas grafias, e o cabeçalho do sensor as declara; reabre quando uma Check real escrever uma delas — `docs/handoffs/20261016-lote-10-as-cinco-livres/00-missao.md` (2026-10-16)
- **A regra 2 aceita a âncora seguida de uma expansão no padrão** — decidido sem conserto (decisão 1 do lote 10), confirmando a decisão 8(a) do lote 9: o padrão `dq` ancora pelo prefixo literal antes da 1ª expansão, limite declarado no cabeçalho do sensor; recusá-lo deixaria vermelha a varredura do kit em 2 checkpoints fechados (a I10 de 20261002-onde-o-comando-do-humano-escreve e a I20 de 20261003-lote-3-a-catraca-desce, cuja expansão é uma contagem da catraca), e nenhum texto prova que a expansão não acrescenta padrão nem alternância; reabre quando uma Check real escrever, depois da âncora, uma expansão que possa trazê-los — `docs/handoffs/20261016-lote-10-as-cinco-livres/00-missao.md` (2026-10-16)
- **A menção `@codex review` no corpo do PR não pediria a revisão do Codex** — refutado: no PR `j0ruge/dotp-remake#11`, aberto às 22:34:17Z com a menção no corpo, o Codex abriu o Code Review de `d959395` 14 s depois ("Manual request" no resumo do bot), sem o aviso "create an environment" dos #9 e #10 — `j0ruge/dotp-remake#11` (2026-10-19)
