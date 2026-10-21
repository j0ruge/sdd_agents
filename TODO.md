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

### Sensores que faltam

- [ ] **O `sdd preflight` não mede a forma do `TODO_FILE`, e nada avisa o alvo sem o opt-in** —
  `bin/sdd:6521` (`preflight-test`) — a forma só é medida quando o `TEST_CMD` do alvo inclui o
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

- [ ] **Nada avisa que o clone do kit está velho ou fora da `main`** — `bin/sdd:4115` (`autonomy_kit_stamp`) —
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

- [ ] **A prosa que a DOCS escreve depois da REVIEW não passa por revisão nenhuma** — `bin/sdd:2712` (`PHASES`) —
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

### Contrato e configuração

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
- [ ] **O platô da REVIEW lê só as letras, e pararia um laço que converge** — `agents/sdd-reviewer.md:62`
  (`Overall Grade`) — "as mesmas letras da rodada anterior" é platô, mas não separa o achado que a rodada
  não fechou do material que entrou entre as rodadas sem ser `R<n>`, nem da classe que a varredura pulou. No
  `lighthouse_project` a REVIEW ficou em B de r3 a r6, cada rodada com um achado real e menor, fechado pelo
  `R<n>` seguinte sem defeito novo; 4 dos 7 da r6 vieram de um bump commitado entre r5 e r6. A regra teria
  parado na r4; a r7, com só o `R7` entre as rodadas, deu A em tudo. Direção: só `R<n>` entra entre rodadas,
  o boot da rodada lista o commit que não fecha `R<n>`, e o platô compara a classe do achado, não só a letra.
  — descoberto por `sdd-reviewer` na missão `20261013-amep-alignment-review` (2026-10-14)
- [ ] **`sdd install --help` instala o kit, e `sdd link-agents --help` liga os agentes** — `bin/sdd:5911`
  (`--force`) — o `cmd_install` só compara o 1º argumento com `--force`, e o `cmd_link_agents` (`:11444`)
  não lê nenhum: o `--help` depois do subcomando executa. Num repo de rascunho, o 1º gravou `.sdd/config.sh`,
  `docs/handoffs/`, `TODO.md` e os agentes; o 2º, 8 symlinks e o `.gitignore`. O `main()` (`:11595`) só trata
  `--help` na 1ª posição; `run`, `retry`, `status` e `health` recusam opção desconhecida. Direção: todo
  subcomando recusa opção desconhecida e lê `-h/--help` como a própria ajuda, com um caso por efeito colateral.
  — descoberto por `sessão coordenadora` no `lighthouse_project`, ao ler o uso do `link-agents` (2026-10-16)

- [ ] **O remédio do `sdd kaizen` recusado ensina a mesma receita sem `--no-track`** — `bin/sdd:11422`
  (`shared_why`) — o motivo manda `worktree add ../<repo>-kaizen -b kaizen/<YYYYMMDD> origin/<branch>`, e a
  branch do juiz nasce rastreando a `main` (git 2.43, medido em repo de rascunho); o `docs/failure-modes.md:624`
  e o `docs/pipeline.md:1477` citam o motivo literal. Gêmeo do item acima, que a leva conserta só no
  `/sdd-plan` porque o `bin/` está congelado até o veredito. Direção: `--no-track` no motivo e nas duas citações.
  — descoberto pelo `sdd-planner` na missão `20261015-lote-8-a-leva-que-nao-parte-a-janela` (2026-10-15)

- [ ] **O planner chama a base de `main`, e o alvo pode ter outra** — `agents/sdd-planner.md:260`
  (`kaizen_log:`) — a exceção do `branch:` diz "naming the base branch itself (`main`)", e o `k8_base_refusal`
  (`bin/sdd:2183`) compara com o `$DEFAULT_BRANCH`. No `sales_quote`, cuja base é a `develop`, o planner pode deixar
  `kaizen_log` sem `skipped` numa missão na base, e quem recusa é o `gate_PLAN` (ou o `gate_DOCS` de um `--phase`
  forçado): falha fechada, mas o consumidor está fora da suíte do kit (D15). Direção: a frase nomeia o
  `DEFAULT_BRANCH` do alvo, e não o literal `main`.
  — descoberto pelo Codex no yokoten `JRC-Brasil/sales_quote#484`, sobre a cópia do `bad6168` (2026-10-15)

- [ ] **O `sdd install` adota a branch atual como base quando falta `origin/HEAD`** — `bin/sdd:5927`
  (`--show-current`) — sem `refs/remotes/origin/HEAD` o install grava a branch em que está, e instalar numa
  branch de trabalho é o caso comum: saiu `DEFAULT_BRANCH="plano-3-2"` no `dotp-remake` e `"chore/sdd-install"`
  no `magic_tutor` (este com `origin/main` no clone), sob o "Detected from origin/HEAD" do `config/starter.conf`;
  o "confirm it" da saída foi a única defesa. Direção: tentar `git ls-remote --symref origin HEAD` e um
  `origin/main`/`origin/master` existente antes da branch atual, e dizer que ela é palpite quando for ela.
  — descoberto por `retrofit-watch` no `dotp-remake` (2026-10-19) e no `magic_tutor` (2026-10-20)

- [ ] **A primeira instalação semeia o `TODO.md` em inglês, qualquer que seja o idioma** — `bin/sdd:5993`
  (`inst_lang`) — o install lê o `OUTPUT_LANG` da config que acabou de gerar do `starter.conf`, onde ele vem
  vazio, e cai no `templates/todo.md` (`:5877`). Ajustar o idioma depois não troca a semente: no `dotp-remake`
  (`pt-BR`) foi preciso apagar o `TODO.md` intocado e rodar o `sdd install` de novo. Direção: um `--lang` no
  install, ou a saída nomear o reinstall quando o `TODO_FILE` ainda é a semente de outro idioma.
  — descoberto por `retrofit-watch` na instalação do kit no `dotp-remake` (2026-10-19)

- [ ] **Nada instala nem confere o `/sdd-plan` que o `link-agents` manda rodar** — `bin/sdd:11681`
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
  — descoberto pelo relay do `/sdd-plan` na 3.2 do `dotp-remake` (2026-10-19) e por `retrofit-watch` no
  `magic_tutor` (2026-10-20)
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
- [ ] **A guarda do kit para a corrida do alvo por um merge só de docs no checkout do kit** — `bin/sdd:4348`
  (`kit_guard_check`) — compara o par cru (HEAD e sujeira) e não lê o rótulo `sdd:` do reflog (anatomia §6). No
  lighthouse o operador puxou o #246 e o #254 (só `docs/`, `TODO.md` e catraca) para o checkout principal do kit
  com a corrida viva: `kit-touched` 2×, 2 células `refez` e 2 das 6 intervenções da missão; o reflog dizia
  `merge origin/main: Fast-forward`, sem rótulo. Direção: com ADR, só o HEAD movido por entrada do reflog sem o
  rótulo da sessão (alheia, como esse fast-forward) e que não toca `bin agents templates config` vira aviso no
  journal; a sujeira não commitada, que não deixa reflog, e o resto continuam parando a linha.
  — descoberto por `sdd-kaizen` na missão `20261014-amep-entrada-em-dois-niveis` (2026-10-20)
- [ ] **A REVIEW aprovada não vê o código que entrou depois dela** — `bin/sdd:1924` (`gate_REVIEW`) — o gate lê
  a nota da última rodada e não compara o commit que ela revisou com o HEAD. No lighthouse o F5–F8 (emenda E1–E6)
  e o R3 (P2 do Codex no PR #29) entraram depois da r2 em A, e o humano forçou a r3 e a r4 com `--phase REVIEW`:
  2 das 6 intervenções da missão. É o espelho do D21, em que só `F<n>` reabre a QA. Direção: a rodada grava o
  commit revisado, e código commitado depois dele reabre a REVIEW ou é nomeado no motivo do gate.
  — descoberto por `sdd-kaizen` na missão `20261014-amep-entrada-em-dois-niveis` (2026-10-20)

### Saída humana e cosmética

- [ ] **O motivo do gate_QA não diz se o caso e2e vermelho já caiu antes** — `bin/sdd:1856` (`gate-qa-e2e`) —
  um caso intermitente anterior à missão devolve a fase ao `sdd-qa`, que gasta o começo descobrindo isso:
  no alvo, o `frete-ipi.spec.ts:319` já tinha caído duas vezes, com os logs de gate em disco. Direção: o
  `GATE_WHY` cita quantas vezes cada caso vermelho já caiu nos logs `gate-qa-e2e` anteriores.
  Fonte: `docs/handoffs/20261012-a-rota-da-qa/00-missao.md` — achado `kit:` do `sdd-qa` em
  `20261005-mascaras-ncm-e-painel`, transportado por `sdd-kaizen` (2026-10-12)

- [ ] **O `sdd status` manda `sdd run` com o app fora do ar, e a fase fechada volta a pendente** — `bin/sdd:7526`
  (`run: sdd run`) — com o `30-handoff-qa.md` em `done`, o `gate_QA` refaz a e2e ao vivo; app caído vira `· QA`,
  `next phase: QA` e `run: sdd run`, embora o motivo diga "no session can start it" (`:1849`). Esse `sdd run`
  compra uma sessão `QA:close` (opus no alvo) antes de escalar `app-down` (`tests/check-autonomy.sh:2528`), e cada
  leitura roda a e2e, que no `lighthouse_project` grava uma demanda e gasta um número da sequência. Direção: o
  status lê o `GATE_APP_DOWN` e diz "fechada, e2e não re-verificável agora: app fora", com o remédio da escalada.
  — descoberto por `sessão coordenadora` na missão `20261013-amep-alignment-review` (2026-10-14)

- [ ] **O `sdd status` fica calado enquanto o gate do EXEC roda o `TEST_CMD`** — `bin/sdd:7469` (`--no-gates`) —
  depois da linha do TICKET, nada sai durante a suíte do alvo: 1 min 57 s no `ui24_agent`, medido com
  `sdd status 20261003-fase8-s8-dinamica-eq-restantes > arquivo`. Num `timeout 60` a espera foi tomada por
  travamento, e o erro de missão ausente não cita o `--no-gates`, que lê só o disco. Direção: uma linha
  "rodando o TEST_CMD (<cmd>)…" antes do gate que a chama, e o `--no-gates` na mensagem de uso.
  — descoberto por `retrofit-watch` na sessão do `ui24_agent` que planejou a S9 (2026-10-17)

- [ ] **O fim da corrida diz que só falta o merge, e o `sdd close` some** — `bin/sdd:8998` (`pipeline complete`) —
  o `sdd run` e o `sdd status` (`:7341`) fecham com "only the merge is left", e nenhum template, chapéu ou comando
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
  corrigida à mão para "rodam na suíte local, `dotnet test`; o repositório não tem CI". Direção: o publisher
  só afirma CI com um workflow em `.github/workflows/`; sem ele, diz onde a suíte rodou: pelo `TEST_CMD`.
  — descoberto por `sessão coordenadora` na missão `20261019-plano-3-2-a-magicas-de-uma-vez` (2026-10-19)

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
- **O `sdd preflight` não provaria que a sessão headless executa comando** — refutado: `bin/sdd:5168` manda rodar `bash -c 'echo sdd-preflight-ok'` sob as flags do `run_phase` desde `2083680`, e sob o chapéu do executor desde 2026-09-06 (2026-09-25)
- **O `RESOLVED by` não deixa a catraca descer na missão que conserta** — decidido: o item fica até o merge e sai no chore pós-merge, `templates/todo.pt-BR.md` § Ciclo de vida (2026-09-25)
- **O stub do `sdd adr new` manda escrever em `OUTPUT_LANG`, e o `check-lang.sh` lê `docs/adr/` como inglês** — limite declarado pela D15, não achado: `bin/sdd:7030` (2026-09-25)
- **Aviso de merge durante a janela do juiz** — decidido fora: depois do conserto do eixo (I2) só mudança real do kit rompe a janela, e essa é ruptura legítima — `docs/adr/0014`, missão `20261001-a-janela-nao-se-parte` (2026-10-01)
- **A refutação R2 do handoff de QA citaria evidência que não existe** — refutado: o prompt renderizado nomeava o arquivo, porque o boot_prompt expande `$TODO_FILE` para TODO.md; o item conferiu a fonte, não o prompt — `148f693:bin/sdd:1621` (2026-10-03)
- **O sdd status travaria mais de 2 min segurando a trava do checkout** — refutado como defeito sem causa e como fila: sem `--no-gates` o status avalia todo gate sob a trava, TEST_CMD e E2E_CMD incluídos, e a segura enquanto eles rodam, sem prazo; a trava é não-bloqueante, então quem chega depois não enfileira, recebe CHECKOUT-BUSY com o dono; a leitura sem trava é `sdd status --no-gates` — `bin/sdd-coordination.py:504` (2026-10-03)
- **O cmd_kaizen escalaria no-progress como fricção no rubric depois de um retry que moveu** — decidido: o código escala sem olhar o moved2, mas as linhas KAIZEN são `$meta` e ficam fora do eixo do juiz nos dois leitores; o humano lê "two sessions without satisfying the gate", que é verdade — `bin/sdd:9943` (2026-10-03)
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
- **O 2º Python do worker custa ~30 ms em toda chamada coordenada** — decidido: 30 ms por chamada não chega ao humano; provar o worker por FD herdado pede ADR e fica na gaveta, F1 P1 — `docs/superpowers/specs/2026-09-23-a-gaveta-do-kit.md:63` (2026-10-03)
- **35% do docs/pipeline.md seria um subsistema só, e cresceria a cada missão do ledger** — decidido, sem refator: as seções do ledger e do juiz são 525 de 1562 linhas (33,6%), estáveis em 33–34% desde 2026-09-29 depois do pico de 48% em 2026-08-31, e nenhum boot_prompt lê o pipeline.md, então nenhuma fase paga o índice inteiro; reabre se a fatia passar de 40% ou se um boot passar a ler o arquivo — `docs/pipeline.md:1050` (2026-10-04)
- **Test Coverage = A do revisor implicaria que os casos negativos existem** — decidido como limite: a nota de revisão é rótulo que o próprio modelo escreve, e a anatomia §4 o declara; a parte barata e real, o executor sabotar a linha nova de um R<n>, é o I3 de 20261004-lote-4-a-catraca-zera; reabre quando um segundo P1 escapar de um Test Coverage = A numa missão headless — `.claude/rules/anatomia-do-agente.md:94` (2026-10-04)
- **Nenhum instrumento mediria prosa de CONTRATO fora de templates/** — decidido: a fase DOCS é a dona dessa prosa (a checklist de drift do 45-docs.md percorre o diff inteiro da missão), o config/schema.md já é medido contra o load_config pelo sdd health, a tabela de agentes do README bate 8 = 8, e os drifts registrados foram pegos antes do merge; o limite está no cabeçalho do sensor; reabre quando um drift de contrato escapar para a main — `tests/check-templates.sh:39` (2026-10-04)
- **O checkpoint não teria grafia para incremento cujo produto não é commit** — decidido: a grafia é o commit de registro — o ato fora do git (e-mail, página da KB, config no IdP) deixa na pasta da missão um record-<ID>.md com o que foi feito, a URL ou o ID e a data, e o hash dele vai na célula Commit que o gate_EXEC já lê; passo pós-merge ou de janela externa sai da tabela para as Pendências para o humano do 00-missao.md ou para a missão seguinte (o token de espera é o Y8 do CONTEXT.md); os casos medidos (o I5 da LH-3, KB sem commit; o I6 de 20260918-a-excecao-do-chapeu-e-o-genero-diferido, pending eterno; os I1–I3 de 20260825-cif-forma-pagamento no sales_quote, blocked eterno) não são migrados, porque handoff fechado não se reescreve — `templates/checkpoint.md:35` (2026-10-04)
- **Drift de comentário em código não teria dono: nem a DOCS nem a EXEC** — decidido: comentário de código é do código — a REVIEW o manda para um lote R<n> da EXEC, a DOCS marca ⛔ com o texto proposto (o bin/sdd fica fora do writes: dela, e o gate só recusa ⛔ em documento que ela pode escrever), ou ele vai para o TODO_FILE quando o carimbo não compensa; o caminho estreito "a DOCS edita só hunk de comentário" falharia aberto, porque o bin/sdd tem 6 heredocs e # dentro de string, awk e jq; 0 hat-crossed por código em 15 sessões DOCS desde 2026-09-12 — `agents/sdd-docs.md:104` (2026-10-04)
- **A entrada do índice na árvore do kit leva vírgula inicial (`@,100644:…`)** — decidido (D15): o mawk avalia o lado esquerdo de `ix[q] = (q in ix) ? … : e` antes do `in`, então toda entrada nasce com `,`; é representação interna, igual nas duas amostras que a guarda compara, e o motivo do `kit-touched` não a imprime — sem consumidor, não é achado — `bin/sdd:4003` (`kit_guard_tree`), revisão final de `20261008-lote-6-as-quatro-que-faltam` (2026-10-08)
- **`kit_checkout_targets_run` com `REPO_ROOT` vazio responderia "recusado"** — decidido (D15): inalcançável, a recusa de identidade do `cmd_kaizen` vem antes e o `load_config` sempre publica a raiz; reabre se a função ganhar outro chamador — `bin/sdd:10963` (`kit_checkout_targets_run`), revisão final de `20261008-lote-6-as-quatro-que-faltam` (2026-10-08)
- **A regra 2 do check-checkpoint deixa abertos os casos que só o runtime decide** — decidido sem conserto (decisão 1 do lote 10): um leitor de texto não decide o terceiro descritor, o alvo de runtime (`2>$f`), a grafia da stdout que o sistema resolve, a palavra que abre com expansão lida como operando, o `POSIXLY_CORRECT` ou outro grep, nem o nome que substitui o grep; a peça que mediria a Check em execução não tem dono (no PLAN a asserção ainda não existe, e gate não executa texto de modelo); 0 de 67 checkpoints escrevem uma dessas grafias, e o cabeçalho do sensor as declara; reabre quando uma Check real escrever uma delas — `docs/handoffs/20261016-lote-10-as-cinco-livres/00-missao.md` (2026-10-16)
- **A regra 2 aceita a âncora seguida de uma expansão no padrão** — decidido sem conserto (decisão 1 do lote 10), confirmando a decisão 8(a) do lote 9: o padrão `dq` ancora pelo prefixo literal antes da 1ª expansão, limite declarado no cabeçalho do sensor; recusá-lo deixaria vermelha a varredura do kit em 2 checkpoints fechados (a I10 de 20261002-onde-o-comando-do-humano-escreve e a I20 de 20261003-lote-3-a-catraca-desce, cuja expansão é uma contagem da catraca), e nenhum texto prova que a expansão não acrescenta padrão nem alternância; reabre quando uma Check real escrever, depois da âncora, uma expansão que possa trazê-los — `docs/handoffs/20261016-lote-10-as-cinco-livres/00-missao.md` (2026-10-16)
- **A menção `@codex review` no corpo do PR não pediria a revisão do Codex** — refutado: no PR `j0ruge/dotp-remake#11`, aberto às 22:34:17Z com a menção no corpo, o Codex abriu o Code Review de `d959395` 14 s depois ("Manual request" no resumo do bot), sem o aviso "create an environment" dos #9 e #10 — `j0ruge/dotp-remake#11` (2026-10-19)
