# O worker — o merge delegado, como rodou na noite de 2026-11-16 (caderno)

> Companheiro do [roadmap do worker](2026-09-22-o-worker-roadmap-design.md) e do
> [caderno de campo](2026-10-09-o-worker-caderno-de-campo.md). Registra, a pedido do dono, o fluxo
> que rodou com ele ausente, no `dotp-remake` e no kit, do plano aprovado até o merge. O registro
> serve para o fluxo virar **opção** do kit quando o worker noturno sair do estacionamento. Hoje o
> D5 do roadmap para o worker no "pronto para merge" e recusa "até o merge" sem ADR. Este caderno é
> o insumo dessa ADR, não a decisão.
>
> Horários em BRT (UTC−3), lidos dos timestamps do GitHub.

## 1. A delegação

- **A palavra do dono**, em 2026-11-16 por volta de 01:45, antes de sair: *"depois de tudo ok, pode
  dar merge no meu lugar"*. Antes, na mesma noite, ele deu outra: *"quando fechar a parte um, já
  pode … planejar a entrega dois … pode usar no sdd-plan o Fable pra planejar e aceitar as opções
  recomendadas"*.
- **Alcance:** os PRs abertos naquela noite. Eram o da missão 5a (`dotp-remake` #32) e os dois PRs
  de achado do kit (#408 e #409). Entrava também o PR de docs do pós-merge da 5a (#33), se passasse
  pelo mesmo fluxo.
- **O que ficou fora:** `sdd approve`, `sdd run`, push direto na `main`, apagar branch ou worktree e
  o fast-forward do checkout principal. Nada disso foi proibido por escrito; a sessão leu a
  delegação pelo que ela dizia, e não por tudo o que ela não vetava. O pós-merge, que o dono
  costumava empurrar direto na `main`, virou o PR #33.
- **Registro:** a sessão gravou a delegação numa memória do agente, com o que conta como "tudo ok"
  em cada PR e a regra de parada. Depois do último merge, marcou-a **usada e esgotada**: ela não
  vale para PR novo. Sem essa marca, a sessão seguinte herdaria uma autorização vencida.

## 2. O fluxo, passo a passo (a 5a)

| # | Passo | Quem | Evidência |
|---|---|---|---|
| 1 | PLAN: o planner roda no Fable, e o grill aceita a opção recomendada em toda pergunta, pela autorização prévia do dono | sessão (o relay do `/sdd-plan`) | `8 (recommended) of 8` na 5b; `6 (recommended) of 6` na 6a |
| 2 | Aprovação: remedir `--check` e `--red`, mostrar o plano e a contagem do grill, e só então `sdd approve`, com a palavra do dono | dono | o `y` do `sdd approve` não diz quem o digitou; quem decide é a palavra do dono na sessão |
| 3 | `sdd run` no worktree da missão: EXEC → QA → REVIEW r1 → DOCS → PR | runner | a run começou às 21:51 de 11-15, e o PR #32 abriu às 02:56 (US$ 81,03 em 17 sessões) |
| 4 | Merge da `main` na branch da missão, que tinha andado durante a run. O conflito ficou só nas âncoras do `TODO.md`, resolvido à mão, e a suíte rodou de novo no tree mesclado | sessão | `41de7ef` |
| 5 | Consertar o que a r1 deixou abaixo da régua do dono: Documentation em B, e o dono exige A | sessão | `6457ffd`, `1441968` |
| 6 | `/codereview` só sobre o delta desde o último head revisado, sem o que veio da `main`, até nota A em todo critério | sessão | r2: 1 MEDIUM de prosa, consertado remedindo os números (§4, M6); r3: 2 LOW; r4: 0 achado, A no `df202f2` |
| 7 | Atualizar o corpo do PR com as rodadas | sessão | pelo `gh api -X PATCH`, porque o `gh pr edit` quebra com Projects classic |
| 8 | Bots no head final: `@codex review`, mais CodeRabbit e Copilot | sessão | ver a §4, M1 e M2 |
| 9 | Merge: `gh pr merge 32 --merge --match-head-commit <sha completo>` | sessão, pela delegação | `7724b3f`, às 04:14 |
| 10 | Pós-merge (roadmap, `TODO.md`, `KAIZEN_LOG.md`) num PR próprio, com rodada de `/codereview` (2 LOW consertados, verificação limpa) e Codex | sessão | #33, `fb68631`, às 04:21 |

**Os PRs do kit (#409 e #408)** seguiram a receita do `docs/finding-prs.md`: merge da `origin/main`,
recontar a catraca, as três medidas do `check-todo.sh`, push e bots. O merge foi o mesmo
`--merge --match-head-commit`, sem carimbo do `sdd health`, porque eram achados de missão de outro
repo. O #409 entrou às 03:26. O #408 precisou de outro merge da `main` depois disso (catraca
78 + 2 → 80) e entrou às 03:30.

## 3. "Tudo ok": o checklist que decidiu cada merge

Cada item foi lido de um artefato, nunca de memória:

1. O `/codereview` dá nota A em todo critério, Documentation inclusive, no head que vai ser
   mergeado. O piso B do `REVIEW_PROSE_CRITERIA` não basta para este dono.
2. O Codex deixa o resumo `Completed` ("Didn't find any major issues") com o sha curto do head
   atual (C11 do caderno de campo), e não há P1 nem P2 aberto.
3. O CodeRabbit não deixa thread aberto.
4. O `mergeable` está limpo e o head do PR é o sha revisado. O `--match-head-commit` fecha a janela
   entre conferir e mergear.
5. O merge é por merge commit, nunca squash (C7).
6. **Regra de parada:** com nota abaixo de A depois de 3 rodadas, ou um P1 do Codex sem conserto,
   aquele PR não é mergeado e o caso vai ao relatório. Nesta noite nenhum PR parou nela.

As pendências do corpo do PR ("Decisions for a Human") que o próprio PR declara não bloqueantes
ficaram abertas e não seguraram o merge. O aceite visual da 5a (a Métrica 5) o dono fechou antes de
sair, ao ver as capturas.

## 4. Fatos medidos na noite

| # | Fato | Evidência | Para a opção |
|---|---|---|---|
| M1 | **Bot que não revisou parece ter revisado.** O Copilot publicou review com estado `COMMENTED` no #32 e no #33, e o corpo dizia "unable to review … insufficient remaining quota". No `dotp-remake`, o CodeRabbit está no plano Free: só gera resumo e walkthrough, sem revisão linha a linha, e respondeu ao `@coderabbitai review` com "Review finished". Num PR do kit, ele bateu no limite por hora ("Review limit reached") e revisou 4 min depois. | `gh api repos/j0ruge/dotp-remake/pulls/32/reviews`; comentários do CodeRabbit no #32 | O W7 lê o **corpo**: cota, limite ou plano Free contam como "não revisou", uma lacuna declarada no PR, nunca como "limpo". Falta decidir se "não revisou" bloqueia. Nesta noite não bloqueou: bastaram o Codex limpo e o `/codereview` em A |
| M2 | **O Codex respondeu em minutos:** 2 min 42 s no #32 (06:26:01Z → 06:28:43Z) e 1 min 12 s no #33. No `sales_quote`, o C6 mediu um achado que chegou a 51 min. | `gh api repos/j0ruge/dotp-remake/issues/{32,33}/comments` | O timeout do W7 continua ≥ 60 min, para cobrir a cauda de 51 min do C6. Ele é o limite da espera, não o tempo típico: o recibo do head costuma vir em minutos |
| M3 | **A `main` anda durante a run.** A run da 5a levou cerca de 5 h, e nesse meio a `main` ganhou commits. O PR precisou de merge da `main`, com conflito, antes da revisão final. | `41de7ef` | O worker precisa do passo "trazer a `main` e rodar a suíte de novo" antes do merge. A re-revisão tem de saber deixar de fora o que veio da `main`, e a skill `codereview` não tem esse caminho (candidata a retro) |
| M4 | **Um merge invalida o PR seguinte.** O merge do #409 mudou a base do #408: novo merge da `main`, catraca recontada, push e bots de novo. | `8905bd0` | Uma fila de merges re-valida cada PR depois do merge anterior. Nunca mergear em lote |
| M5 | **A régua do REVIEW do pipeline é mais baixa que a do dono.** A r1 do pipeline deu Documentation B, que o `REVIEW_PROSE_CRITERIA` aceita, e o dono exige A. Foram 3 rodadas à mão (r2 a r4) depois do PR aberto. | `40-review-r1.md` a `40-review-r3.md` da 5a; o corpo do #32 | A régua do merge delegado é configuração do alvo, e o laço de rodadas tem teto (3) |
| M6 | **Consertar prosa pode exigir remedir.** O MEDIUM da r2 eram números citados sem a saída guardada. O conserto foi rodar de novo uma sonda descartável (13 de 2 397 paradas com bloqueio) e guardar a saída. | `record-r2-medidas.md` da 5a, `d45dbe1` | O worker precisa poder rodar uma sonda fora do `TEST_CMD` e guardar a evidência |
| M7 | **O pós-merge vira PR.** Sem push na `main`, o pós-merge (roadmap, `TODO.md`, `KAIZEN_LOG.md`) passou por PR próprio. A rodada do `/codereview` veio antes de abrir o PR; depois de aberto, o PR esperou só o Codex e ficou 2 min 29 s até o merge. | #33 (07:19:30Z → 07:21:59Z) | A opção nunca precisa de push na `main` |
| M8 | **Um grill sem o dono pode recomendar sobre evidência errada.** Na 6a, uma recomendação se apoiou num número errado: "o decodificador de TDX recusa 25,5 %", quando eram 28 de 9 176. O próprio planner achou o erro depois, e a confirmação voltou ao dono. | `00-missao.md` da 6a (`dotp-remake`) | Aceitar "as recomendadas" sem humano chega perto do D1 recusado. O approve tem de mostrar a evidência que mudou desde o grill |
| M9 | **A execução não viu as próprias capturas.** Na 5a, o `Read` da imagem que o EXEC gerou foi negado. A primeira carta desenhada passou pelo gate sem que ninguém olhasse, e o dono achou o visual feio na manhã seguinte. | journal da 5a | Aceite visual não é trabalho de worker: fica com o humano, como a Métrica 5 |


### A 5b, de dia (2026-11-16)

A delegação da §1 já estava esgotada. A 5b entrou por uma nova, dada em 2026-11-16 por volta de 07:40, com a run já em voo: *"vamos seguir o mesmo
fluxo da 5a na 5b e depois o mesmo na Entrega 2, planejamento com fable 5.2, escolhas recomendadas das perguntas, aprovacao,
execucao com o Opus ate o fim, pr, pr review e merge"*. A run lançada às 07:24 abriu o PR #35 do `dotp-remake` às 11:33: US$ 71,82 em 17 sessões, sem teto e sem rc 3. A `main` não andou,
então o M3 não se repetiu. Depois vieram as rodadas r3 a r5 à mão até A, a passada de três perfis de interface e o Codex limpo no
head. O merge saiu às 11:47 (`466b7f6`), e o pós-merge, no #36, às 12:26 (`e911d15`). Nenhuma decisão de merge precisou do dono.

| # | Fato | Evidência | Para a opção |
|---|---|---|---|
| M10 | **O aviso do fim da run chegou à sessão nova.** O handoff dizia que a sessão aberta depois do `/clear` não receberia o fim da tarefa de fundo da sessão antiga. Recebeu, às 11:33. | a notificação da tarefa de fundo do `sdd run`, na sessão nova | A espera própria (`pgrep` em laço) não depende do harness; com as duas, a falha de uma não cega o worker |
| M11 | **A DOCS escreve "sem PR" antes de o PR existir.** A DOCS roda antes da fase PR, e o roadmap e o `KAIZEN_LOG.md` saíram dizendo "sem PR". O PR aberto logo depois os contradisse. Na 5a, o pós-merge consertou o mesmo ("o PR não foi aberto"); na 5b, a r3 deu MEDIUM de comportamento. | r3 do #35 (`624eb7c`); `f389bf6` na 5a | Candidato a achado do kit: a DOCS não grava o estado do PR, ou a fase PR o atualiza |
| M12 | **As medidas "sem saída guardada" estavam nos logs do runner.** Dois LOW de comportamento fecharam lendo `.sdd/logs/<missão>/gate-*-test-*.log` e os `*.stream.jsonl` das sessões, locais e fora do git. Um número ("82 s") não estava em lugar nenhum e saiu do texto. | `7b68392`; corpo do #35 | O worker tem nos logs a evidência que o revisor pede, sem remedir; o handoff poderia citar o log |
| M13 | **A hora engana; o sha não.** A primeira espera pelo Codex filtrou por hora com `date -u -d '11:44:30'`, que lê a hora como UTC, e contou o recibo do head antigo. O C11 (o sha curto do head no recibo) pegou o erro. | recibos do Codex no #35 | O W7 casa o recibo pelo sha do head, nunca pela hora |
| M14 | **A revisão de interface por perfil é trabalho de worker.** UI Finish-Gate Reviewer, Game Designer e Level Designer leram as capturas da QA em paralelo, cerca de 2,5 min cada. Nenhum bloqueou; os três acharam o mesmo defeito no escopo, não bloqueante (o painel corta o `#id`), que foi ao `TODO.md`. | corpo do #35, "Passada dos perfis" | Vem antes do aceite visual e não o substitui (M9) |
| M15 | **O Codex nem sempre revisa o PR que abre.** No #36 não houve reação em 30 min depois de aberto. O `@codex review` explícito teve recibo em 2 min. No #33 da 5a, a revisão ao abrir veio em 1 min 12 s. | #36 (14:53:31Z aberto; pedido 15:24:26Z; recibo 15:26Z) | O W7 pede o `@codex review` sempre, sem esperar a revisão automática |

### O Plano 7 em cadeia (2026-11-16/17)

Na madrugada de 2026-11-17, por volta de 01:30, o dono delegou o Plano 7 inteiro numa frase: "quando terminar essa fase, coloca no
pr, depois merge e ja aprova as outras do 7, no que precisa planeja com o Fable, aceita as recomendacoes, depois da YES e executa,
vai assim em todos". Como a da 5b, ela inclui o `sdd approve`, que ficou fora na noite da 5a (§1). Ninguém interveio
durante as runs. Os sucessos:
- **A run da 7a correu sozinha por 7 h 42 min**, das 20:02 às 03:44: 12 incrementos e o I13 pedido pela REVIEW r1, depois QA, REVIEW
  r2 com A, DOCS e o PR #42 do `dotp-remake`. Foram US$ 101,88 em 18 sessões, sem bater no teto. A sabotagem matou todos os mutantes,
  menos um equivalente; no I7 foram 43 de 43.
- **Uma mensagem do dono levou a cadeia inteira**, com ele dormindo: o merge da 7a às 04:26 (`df76b50`), o pós-merge às 04:31 (#43),
  o approve e a run da 7b às 04:36, e a 7b2 planejada até as 05:55.
- **O grill sob delegação não parou a cadeia.** O relay respondeu as 10 perguntas da 7b2 com a recomendada. As duas que tocam regra
  ou visual do dono (uma fonte nova e um deslocamento de 47 px) viraram pendência do aceite no PR, marcadas com ◆.
- **Um planner parado foi retomado.** O planner da 7b ficou parado cerca de 8 h e voltou por `SendMessage`, com o id achado no
  transcript (`grep 'agentId:' <sessão>.jsonl`). Ele aplicou os ajustes dos perfis e mediu o `--red` em 7 min.

| # | Fato | Evidência | Para a opção |
|---|---|---|---|
| M16 | **A REVIEW do pipeline deu A, e os perfis acharam um defeito alto.** O foco cobria a pilha. O EXEC não chama `Agent`, então a passada de perfis sobre as capturas ficou com o worker. Confirma o M14, desta vez com um defeito real. | `8f71124`, `fc7d2a5` e `a368c94` no `dotp-remake`; relatórios dos perfis fora do git | A passada de perfis é um passo do worker antes do `/codereview`, não um opcional |
| M17 | **O merge da `main` depois da run gera conflitos de docs.** Caíram em `CLAUDE.md`, `KAIZEN_LOG.md`, roadmap e nas âncoras do `TODO.md`, que andam com as linhas do `CLAUDE.md`. O `check-todo` pegou as âncoras. | `5d7d9ac`; corpo do #42, "Merge da `main`" | Confirma o M3. O worker roda o `check-todo` e a suíte depois de cada merge da `main` |
| M18 | **Com a `main` mergeada, o diff desde o head da REVIEW traz texto de outra missão.** O `/codereview` precisou de escopo por caminho: 2 achados da r3 eram da 6a. | r3 no corpo do #42 | A re-revisão do worker recebe a lista de arquivos da missão, além do `base=` (o M3 já pedia isso à skill). O filtro tira só os arquivos que a `main` mudou sozinha. Num arquivo que as duas mudaram, como o `CLAUDE.md` ou o `TODO.md`, o texto da `main` continua no diff, e o revisor precisa ser avisado |
| M19 | **Os ⛔ da DOCS ficam para o worker aplicar,** e o `45-docs.md` e o `50-pr.md` envelhecem dizendo "⛔ aberto". O `50-pr.md` afirmou "suíte verde no `c6f70cd`" sem medida guardada. | `1c586ac`, `b217b4a` | O worker aplica o ⛔ e anota nos dois arquivos. Afirmação de suíte verde leva o log |
| M20 | **O dono mergeou uma missão no meio da cadeia**: a 6a, sem o `/codereview` do Claude. A `main` andou, e o PR da 7a precisou do merge dela antes da revisão. | #40 do `dotp-remake` (`cd10594`) | O worker confere a `main` antes de cada passo e não supõe que só ele a move |
| M21 | **O `sdd adr new` colidiu de novo.** A 7b2 precisou do 0029, porque o 0028 só existia na `plano-7-b`, sem merge. O contorno foi um arquivo vazio temporário. | kit #411, item 3 | A esteira de planos precisa de ADR reservado por branch |
| M22 | **O `--red` ao lado de outra run foi adiado por política.** O PLAN-AUTO d fica ✗ até o merge da missão anterior. A memória livre mínima medida foi 1 137 MB, com a 7a e o Codex rodando juntos. | kit #411, item 2; amostra `mem-run-7a.log` fora do git | A esteira precisa de um estado "remedir depois do merge" entre o plano pronto e o approve |
| M23 | **Um amostrador com `pgrep -f '<padrão>'` casou consigo mesmo** e nunca terminou: o padrão estava na própria linha de comando. | tarefa de fundo da sessão `9126c7a5` | A espera do worker usa pidfile, não `pgrep -f` |
| M24 | **Um verificador do `/codereview` leu 20 de 21 unidades.** Continuar o mesmo agente com `SendMessage` fechou a conta, mais barato que relançar. | r4 do #42, sessão `9126c7a5` | O worker confere a contagem de unidades e completa no mesmo agente |
| M25 | **Mostrar o plano inteiro a cada approve custa contexto.** Os planos têm de 900 a 1 170 linhas. O relay mostrou uma tabela extraída: objetivo, arquitetura e os incrementos com o Check. | render da 7b, sessão `9126c7a5` | O approve delegado mostra um extrato e grava o render em arquivo |
| M26 | **A cadeia gastou a maior parte do contexto de uma sessão.** A delegação vale "in this session" pela regra do `/sdd-plan`, então cada sessão nova pede um SIM. Nesta, ele veio às 08:23. | handoff `-2026-11-17-2`; sessão `89ae856a` | O worker precisa de handoff em marcos e de uma regra para a delegação que atravessa sessões |
| M27 | **O Codex revisou cada head em 2 a 12 min.** O CodeRabbit Free só resume, e o Copilot está sem cota. | #41 a #43 do `dotp-remake` | Confirma o M1 e o M15 |
| M28 | **Um agente Opus consertou a interface em cerca de 20 min**, com TDD, sabotagem, `--smoke-ui` e captura. O relay olhou a imagem antes de afirmar o conserto. | `FocusClearanceTests`; `8f71124` a `a368c94` | O conserto de defeito de perfil é delegável, e a captura é conferida por quem afirma |
| M29 | **A sessão principal gastou contexto onde não precisava**: o relatório inteiro do `/codereview` no chat, status a cada notificação, as 10 voltas do grill pelo relay, leituras grandes (o índice do `CLAUDE.md`, imagens) e o render do plano. | sessão `9126c7a5` | O orquestrador fala uma linha por evento; agentes devolvem veredito curto e gravam o detalhe em arquivo; relatório e plano vão para arquivo; o grill delegado fica com o planner; o fluxo do PR vai a um agente "pastor de PR". A skill `codereview` gravar o relatório em arquivo e imprimir só a nota é candidato a retro |

## 5. O que a opção precisaria decidir (perguntas, não decisões)

- **Onde se delega.** Nesta noite foi por palavra, para PRs nomeados e com prazo implícito
  ("hoje"). No kit, pode ser um campo do `00-missao.md` gravado pelo `sdd approve`, para o humano
  delegar no momento em que aprova, ou uma config do alvo. Delegação sem prazo nem alcance vira
  permissão permanente.
- **O que é "tudo ok" em cada alvo:** a régua do `/codereview`, quais bots contam, se bot sem cota
  bloqueia (M1) e o teto de rodadas (M5).
- **O merge da `main` na branch** antes do merge (M3): se é automático, com a suíte de novo, e o
  que fazer com conflito. Escalar sempre, ou só quando o conflito sai dos arquivos mecânicos, como
  as âncoras do `TODO.md`?
- **A ordem da fila** de merges (M4).
- **O que nunca entra:** apagar branch ou worktree, push na `main` e aceite visual (M9). O
  pós-merge entra como PR (M7).
- **O approve:** ficou fora na noite da 5a (§1). Desde a 5b o dono o delega, com a remedição e o
  render antes (M22, M25). Falta decidir se ele entra, e com que paradas.
- **A delegação entre sessões** (M26): se o SIM da sessão nova é o mecanismo, ou se a delegação
  fica gravada com alcance e prazo, como pede o primeiro item.
- **A trilha:** cada merge delegado deixa no PR o checklist da §3 preenchido com os shas, e a
  delegação fica marcada como esgotada depois do último merge, como a marca "usada e esgotada" da
  memória fez nesta noite.
