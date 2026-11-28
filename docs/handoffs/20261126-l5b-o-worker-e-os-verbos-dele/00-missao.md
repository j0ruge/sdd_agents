---
missao: 20261126-l5b-o-worker-e-os-verbos-dele
titulo: O worker planeja o próximo lote durante a execução e só avança com evidência da campanha
 data: 2026-11-26
versao:
branch: fix/l5b-o-worker-e-os-verbos-dele
aprovacao: humano-2026-11-26
adr: docs/adr/0027-worker-campaign-evidence.md
ddd: aplicado
qa:
kaizen_log:
campaign: 20261117-zerar-as-issues
lot: L5b
---

# Missão — O worker e os verbos dele

## Problema (Gemba)

A seção L5b da campanha contém 18 itens. Cada título tem uma correspondência aberta no `TODO.md` de `b75951e` e uma issue `OPEN` na consulta ao GitHub feita pelo relay. O mapa individual está no plano. Há ainda uma lacuna no pedido do dono: `next` já imprime `ahead plan` para o lote seguinte, mas essa saída também ocorre antes do lançamento. No procedimento de `run`, a sessão guarda o PID e passa à espera. O teste existente verifica a sugestão impressa. Falta demonstrar o disparo do planner entre a confirmação do início da execução e a espera pelo runner.

O checkout primário contém os termos Codex atualizados. A cópia versionada da campanha neste worktree ainda diz Claude. A L5 tem alterações concorrentes no runner, no worker, nos sensores e no ciclo de resolução do TODO. O SHA de trabalho desta missão ainda não contém o head da L5 observado no planejamento.

## Métrica

- Os 18 pares TODO/issue têm disposição individual com evidência na base integrada e, quando há correção, commit e teste identificáveis.
- Em uma campanha com pedido escrito, um `run` confirmado dispara exatamente um PLAN do sucessor elegível, no worktree dele, antes da espera. Retomar durante o grill mantém um único planner. Sem pedido, permissão, orçamento ou sucessor, o número de lançamentos automáticos é zero.
- O plano antecipado só pode seguir para aprovação e execução após o merge do predecessor, a revalidação e os atos autorizados. Uma campanha de teste percorre a fila até `done` e para no primeiro impedimento real.
- Um gasto de missão removida continua na soma quando o ledger o identifica. Um PR com suíte de outro SHA, pedido de alteração vigente ou achado pendente não recebe `ready`.

## Resultado esperado

O dono pode deixar a campanha seguir pela fila assinada e retomar a sessão sem duplicar planejamento nem perder a causa de uma parada. O worker identifica quem executa, quanto pode ser gasto e que evidência sustenta cada merge. O responsável pelo ato `review` publica a suíte no SHA testado e registra o tratamento dos achados. A L5b entrega e testa esse comportamento. A execução dos lotes seguintes pertence ao orquestrador da campanha.

## Fora de escopo

Implementar ou publicar a L5, planejar o conteúdo de L5c ou L6, alterar a assinatura vigente, mudar o piso global de Git, criar um daemon de campanha ou usar uma segunda execução para ganhar paralelismo. O item do `curso-ddd` sobre política por lote continua no backlog: aqui a ausência de pedido expresso conserva a sugestão. A campanha prossegue sem executar `sdd health` nem gerar o carimbo de mutação do kit.

## Gate PLAN-AUTO

| # | Critério | Status | Evidência |
|---|---|---|---|
| a | Grill sem perguntas abertas não endereçadas | ✅ | Decisões abaixo. A integração da L5 e a alocação da ADR têm responsável e momento definidos. |
| b | Checklist kaizen e DDD | ✅ | K1–K8 e D1–D6 abaixo, com o antes medido e o depois a colher na execução. |
| c | Autocontenção | ✅ | O plano identifica os dois checkouts, a base, a fonte da delegação, o bloqueio pré-aprovação, as issues, o primeiro teste e os critérios de reversão. |
| d | Check executável e vermelho no HEAD por incremento | ✗ | O `--check` do kit leu o checkpoint em memória: `14 row(s), 14 under the anchor rule, none blind`, rc 0. O `--red` executaria sensores que criam fixtures. Falta medi-lo no checkout autorizado e na base que incorporar a L5. |
| e | Versão confirmada ou Jira desligado | ✅ | `.sdd/config.sh` declara `JIRA_ENABLED=false`. |
| f | ADR decidida e alocada | ✅ | ADR 0027 alocada e proposta. Revalidar na base integrada antes da aprovação. `ADR_CHECK=block`. |

## Checklist kaizen (`kaizen-software`)

| # | Item | Status | Nota |
|---|---|---|---|
| K1 | Gemba | ✅ | Conferidos fila, TODO, issues pelo relay, árvores Git, entrada do relay, laço e sensores. |
| K2 | Métrica | ✅ | Contar lançamentos, recibos por SHA e pares com evidência. |
| K3 | Desperdício | ✅ | Reutilizar `next`, o relay e sua retomada. Evitar segunda consulta para explicar uma parada e revisão inteira causada por merge desnecessário. |
| K4 | Fatiamento | ✅ | Catorze incrementos com testemunhas distintas. |
| K5 | Check por artefato | ✅ | Processo lançado, recibo do relay, ledger, SHA, status GitHub e resultado da suíte são observáveis. |
| K6 | Jidoka | ✅ | Falha de leitura, teto, delegação, preflight, ownership ou revalidação interrompe o ato correspondente. |
| K7 | SDCA | ✅ | Atualizar o procedimento que a skill carrega e os sensores já chamados pela suíte. |
| K8 | Registro | ✅ | DOCS registra em `KAIZEN_LOG.md` esta missão, o antes/depois observado e os comandos dos sensores. |

## Checklist DDD (`ddd`) — condicional

| # | Critério | Status | Aplicação |
|---|---|---|---|
| D1 | Vocabulário | ✅ | Campanha, lote, missão, delegação, ato e rodada mantêm o sentido da ADR 0022. |
| D2 | Mudança de sentido | ✅ | `ahead plan` continua uma sugestão derivada. O pedido escrito determina quando o orquestrador deve consumi-la. |
| D3 | Fronteiras | ✅ | O worker coordena a fila. O relay conduz o grill. O runner executa uma missão. O dono assina a delegação. |
| D4 | Invariantes | ✅ | Consultar a autoridade efetiva do ato e o orçamento antes de agir. Um checkout tem um dono de execução. |
| D5 | Identidade | ✅ | Repositório, campanha e lote identificam a intenção de planejar. Missão e worktree identificam o relay. PR e SHA identificam a evidência de merge. |
| D6 | Integração | ✅ | A segunda linha de `next`, o registro do relay, linhas compatíveis do ledger e dados do GitHub atravessam essas fronteiras. |

## Decisões do grill (não re-litigar)

1. Question 8c5c30513c5c44c2b284fe2ecab9e63d
   - question: O \`next\` já emite \`ahead plan &lt;lote&gt;\`, mas o ato \`run\` manda aguardar o PID sem acionar o planner. O \`TODO.md\` também registra uma campanha cujo dono pediu que o próximo plano espere o merge. Qual regra o orquestrador deve aplicar ao receber \`ahead plan\`?&#10;&#10;A) Acionar o planner quando o dono tiver pedido planejamento antecipado para a campanha, como fez nesta. Sem orientação expressa, manter a linha como sugestão. Recomendo esta opção porque atende à fila atual e preserva o comportamento das demais campanhas.&#10;&#10;B) Acionar o planner por padrão em toda campanha com delegação para planejar. Para atender campanhas que precisam esperar o merge, incluir na L5b uma opção explícita por lote.&#10;&#10;Nas duas opções, o disparo ocorre após confirmar o início da execução, em worktree separado. Uma retomada reutiliza o plano já iniciado. A aprovação e a execução do lote seguinte dependem do merge do anterior, da revalidação contra a base e dos gates de delegação e orçamento.
   - answer: (other: A) Acionar o planner quando o dono tiver pedido planejamento antecipado para a campanha, como fez nesta. Sem orientação expressa, manter a linha como sugestão. Recomendo esta opção porque atende à fila atual e preserva o comportamento das demais campanhas.)

2. Question db1b32a5fc1f40d8a1a3efcc6f05cb22
   - question: Quem deve publicar o resultado da suíte que o \`pr-ready\` exige para liberar o merge?&#10;&#10;A) O ato \`review\` publica o status \`local/ci\` no SHA exato do PR que testou. Recomendo esta opção porque o \`review\` já roda a suíte e a campanha passa a ter um responsável por produzir a evidência. Se o head mudar, o novo SHA precisa de resultado próprio.&#10;&#10;B) O CI do repositório publica o resultado. O \`pr-ready\` exige um check obrigatório identificado pelo nome e pelo SHA. Essa opção exige configurar e verificar o produtor do check antes de ativar o gate.&#10;&#10;Em ambas as opções, um pedido de alteração ainda vigente bloqueia o merge mesmo sem comentário em linha. Um achado publicado só no corpo da revisão também exige que o ato \`review\` registre como foi tratado.
   - answer: (other: A) O ato \`review\` publica o status \`local/ci\` no SHA exato do PR que testou. Recomendo esta opção porque o \`review\` já roda a suíte e a campanha passa a ter um responsável por produzir a evidência. Se o head mudar, o novo SHA precisa de resultado próprio.)

3. Question fe88187ed00e43adb3e7b4a0c38c68d4
   - question: Quando o dono pedir uma missão fora da fila, como ela deve entrar no trabalho do worker?&#10;&#10;A) Incluir a missão como lote próprio. Recomendo preparar a mudança em um checkout separado, com a posição e o teto do novo lote explícitos. O dono assina os termos atualizados, e a fila e a delegação chegam à base no mesmo commit. Até lá, o worker segue a fila vigente. Isso preserva o lote em execução e dá ao novo lote orçamento e aprovações rastreáveis.&#10;&#10;B) Conduzir a missão separadamente, com autorização e orçamento próprios. A fila e a assinatura da campanha continuam valendo apenas para os lotes já registrados.
   - answer: (other: A) Incluir a missão como lote próprio. Recomendo preparar a mudança em um checkout separado, com a posição e o teto do novo lote explícitos. O dono assina os termos atualizados, e a fila e a delegação chegam à base no mesmo commit. Até lá, o worker segue a fila vigente. Isso preserva o lote em execução e dá ao novo lote orçamento e aprovações rastreáveis.)

4. Question 9b48d18ee9264843b8ecfe23e6062fb2
   - question: Se a delegação assina US$ 60 por missão e, durante a execução, o \`.sdd/config.sh\` passa a pedir US$ 100 ou \`0\` (sem teto), como o runner deve reagir antes de abrir a próxima sessão?&#10;&#10;A) Parar e informar o valor configurado, o teto assinado e o arquivo que precisa de correção. Recomendo esta opção porque aplica durante a execução a mesma regra que o \`worker budget\` já usa antes do lançamento. Uma redução válida, por exemplo para US$ 40, passa a valer imediatamente.&#10;&#10;B) Continuar com o teto de US$ 60 e registrar que a tentativa de aumento foi ignorada. Uma redução válida também passa a valer imediatamente.
   - answer: (other: A) Parar e informar o valor configurado, o teto assinado e o arquivo que precisa de correção. Recomendo esta opção porque aplica durante a execução a mesma regra que o \`worker budget\` já usa antes do lançamento. Uma redução válida, por exemplo para US$ 40, passa a valer imediatamente.)

5. Question 42faf6efcfbe4487a7192f178e0e2563
   - question: Conferi os 18 títulos da L5b no \`TODO.md\`. A consulta a \`api.github.com\` falhou neste sandbox, e o repositório local não traz os números e estados das issues correspondentes. Como prefere fechar essa conferência?&#10;&#10;A) O relay consulta o GitHub agora e devolve o número, o estado e o título de cada correspondência, indicando também os itens sem issue ou com correspondência ambígua. Recomendo esta opção para que o plano já identifique o que ainda precisa de trabalho. A consulta é somente leitura: \`gh issue list --repo j0ruge/sdd\_agents --state all --limit 1000 --json number,state,title\`.&#10;&#10;B) Entregar o plano com a coluna de issues marcada como pendente. Após o merge da L5, o orquestrador faz o cruzamento e ajusta os incrementos antes de aprovar ou executar a L5b.
   - answer: (other: A) O relay consulta o GitHub agora e devolve o número, o estado e o título de cada correspondência, indicando também os itens sem issue ou com correspondência ambígua. Recomendo esta opção para que o plano já identifique o que ainda precisa de trabalho. A consulta é somente leitura: \`gh issue list --repo j0ruge/sdd\_agents --state all --limit 1000 --json number,state,title\`.&#10;&#10;Consulta somente leitura: 320 issues retornadas. Cruzamento por título normalizado.&#10;&#10;- O \`pr-ready\` não lê o corpo de uma revisão, a \`CHANGES\_REQUESTED\` sem inline nem o \`local/ci\`: #419 OPEN — O \`pr-ready\` não lê o corpo de uma revisão, a \`CHANGES\_REQUESTED\` sem inline nem o \`local/ci\`&#10;- Nenhum ato do worker resolve os threads de review, e o item \`threads\` do \`pr-ready\` fica sem dono: #420 OPEN — Nenhum ato do worker resolve os threads de review, e o item \`threads\` do \`pr-ready\` fica sem dono&#10;- O \`budget\` esquece calado o gasto de uma missão que nunca chegou à base e cujo worktree saiu: #421 OPEN — O \`budget\` esquece calado o gasto de uma missão que nunca chegou à base e cujo worktree saiu&#10;- O mutante \`range\_ancestry\_unchecked\` só troca a mensagem, e o ancestral segue conferido: #424 OPEN — O mutante \`range\_ancestry\_unchecked\` só troca a mensagem, e o ancestral segue conferido&#10;- Os probes de nota do \`pr-ready\` passariam pelo item \`dirty\` com o leitor de nota frouxo: #425 OPEN — Os probes de nota do \`pr-ready\` passariam pelo item \`dirty\` com o leitor de nota frouxo&#10;- O \`config\_key\` do worker põe o valor do ambiente sem \`export\`, e o filho que o config abre lê vazio: #427 OPEN — O \`config\_key\` do worker põe o valor do ambiente sem \`export\`, e o filho que o config abre lê vazio&#10;- O \`effective\_level\` confere o \`expires:\` antes do conjunto e publica o nível depois dele: #428 OPEN — O \`effective\_level\` confere o \`expires:\` antes do conjunto e publica o nível depois dele&#10;- O \`checkouts\_of\` lê o \`worktree list\` sem \`-z\`, e o worktree com quebra de linha no caminho some: #429 OPEN — O \`checkouts\_of\` lê o \`worktree list\` sem \`-z\`, e o worktree com quebra de linha no caminho some&#10;- O \`pr\_states\` descarta o PR de fork depois de o \`gh pr list\` cortar a lista em 30: #430 OPEN — O \`pr\_states\` descarta o PR de fork depois de o \`gh pr list\` cortar a lista em 30&#10;- O yes do dono no passo 3 do laço do worker vale para o ato e não amarra o sha do merge: #431 OPEN — O yes do dono no passo 3 do laço do worker vale para o ato e não amarra o sha do merge&#10;- O \`postmerge\` manda a linha do journal nomear o PR do que sobra para a base, sem dizer o que ela leva: #432 OPEN — O \`postmerge\` manda a linha do journal nomear o PR do que sobra para a base, sem dizer o que ela leva&#10;- A parada do worker roda o \`budget\` de novo para montar o \`SDD\_GATE\_WHY\` do pager: #433 OPEN — A parada do worker roda o \`budget\` de novo para montar o \`SDD\_GATE\_WHY\` do pager&#10;- Uma edição do \`.sdd/config.sh\` durante a fase tira o teto de missão que a delegação assinou: #434 OPEN — Uma edição do \`.sdd/config.sh\` durante a fase tira o teto de missão que a delegação assinou&#10;- A missão pedida fora da fila da campanha não tem rota, e a linha nova derruba a delegação: #448 OPEN — A missão pedida fora da fila da campanha não tem rota, e a linha nova derruba a delegação&#10;- O ato \`review\` do worker mergeia a base antes da rodada, e o \`review-base\` dá \`full\` quando a \`main\` andou: #473 OPEN — O ato \`review\` do worker mergeia a base antes da rodada, e o \`review-base\` dá \`full\` quando a \`main\` andou&#10;- O merge delegado não confere que o corpo do PR lista as escolhas do grill: #474 OPEN — O merge delegado não confere que o corpo do PR lista as escolhas do grill&#10;- O ato \`run\` do worker lança o \`sdd run\` sem rodar o \`sdd preflight\`: #477 OPEN — O ato \`run\` do worker lança o \`sdd run\` sem rodar o \`sdd preflight\`&#10;- O worker lê o \`budget-exhausted\` como o teto da missão, e o runner grava o mesmo \`kind\` no teto da fase: #478 OPEN — O worker lê o \`budget-exhausted\` como o teto da missão, e o runner grava o mesmo \`kind\` no teto da fase)

6. Question 73315b70bb4b43888a392642172b924a
   - question: Para a #429, qual requisito de Git deve valer para os atos do worker que enumeram worktrees? Hoje o kit anuncia Git 2.31+, mas o worker lê a lista por linha. Um caminho com quebra de linha pode fazer uma missão desaparecer do cálculo de orçamento.&#10;&#10;A) Exigir \`git worktree list --porcelain -z\` apenas nos atos que precisam dessa lista. Recomendo esta opção porque o relay Codex já usa esse formato, que preserva o caminho inteiro. Se o Git não oferecer o recurso, o ato para antes de calcular gasto ou conceder permissão e informa o requisito. Os demais comandos mantêm a compatibilidade atual.&#10;&#10;B) Manter esses atos disponíveis também em Git 2.31–2.35. Isso inclui na L5b um segundo método de enumeração e testes que provem que ambos encontram as mesmas missões, inclusive em caminhos com quebra de linha.
   - answer: (other: A) Exigir \`git worktree list --porcelain -z\` apenas nos atos que precisam dessa lista. Recomendo esta opção porque o relay Codex já usa esse formato, que preserva o caminho inteiro. Se o Git não oferecer o recurso, o ato para antes de calcular gasto ou conceder permissão e informa o requisito. Os demais comandos mantêm a compatibilidade atual.)

7. Question c5f0ad29961443e387457881b8556e7f
   - question: Depois de uma troca de sessão, onde o orquestrador deve procurar o pedido de planejamento antecipado?&#10;&#10;A) Na instrução escrita do dono para a campanha, identificada no handoff de retomada. Recomendo esta opção porque permite usar o pedido já feito para \`20261117-zerar-as-issues\`. O handoff aponta para a instrução original. Sem ela, \`ahead plan\` continua como sugestão. Antes de cada disparo, o worker consulta novamente o orçamento e a permissão de \`plan\` para o lote.&#10;&#10;B) Em uma nova chave opcional da delegação, incluída no que o dono assina. A ausência da chave mantém a sugestão. Para ativar o disparo nesta campanha, o dono precisaria assinar novamente após a entrega da L5b.
   - answer: (other: A) Na instrução escrita do dono para a campanha, identificada no handoff de retomada. Recomendo esta opção porque permite usar o pedido já feito para \`20261117-zerar-as-issues\`. O handoff aponta para a instrução original. Sem ela, \`ahead plan\` continua como sugestão. Antes de cada disparo, o worker consulta novamente o orçamento e a permissão de \`plan\` para o lote.)

8. Question 7ea70c3e9c8a4a5d833d7e036764acfd
   - question: Encontrei uma restrição que afeta a decisão da #434. No modo Codex, o runner compara o arquivo \`.sdd/config.sh\` inteiro com o usado no lançamento. Qualquer alteração interrompe a execução antes de outra sessão, inclusive uma redução de US$ 60 para US$ 40. Como a L5b deve aplicar essa redução?&#10;&#10;A) Preservar a guarda atual. Recomendo que o worker reconheça a parada, refaça a verificação da delegação e do orçamento e retome a missão em uma nova invocação com o teto menor. Assim, nenhuma sessão adicional abre com o limite antigo. Um aumento acima do assinado ou o valor \`0\` continua exigindo correção.&#10;&#10;B) Permitir que a mesma invocação adote a redução. Isso amplia a L5b para criar e testar uma exceção que reconheça exclusivamente a diminuição do teto e continue recusando qualquer outra alteração no arquivo.
   - answer: (other: A) Preservar a guarda atual. Recomendo que o worker reconheça a parada, refaça a verificação da delegação e do orçamento e retome a missão em uma nova invocação com o teto menor. Assim, nenhuma sessão adicional abre com o limite antigo. Um aumento acima do assinado ou o valor \`0\` continua exigindo correção.)

## Pendências para o humano

Nenhuma escolha de produto em aberto. O relay mantém `aprovacao:` vazio, materializa o rascunho e devolve ao planner qualquer mudança de escopo revelada pela integração. O orquestrador cuida da revalidação e da aprovação regular quando houver autoridade vigente. Só o dono assina termos novos, se necessários. O PR deve permitir ao dono conferir as escolhas, inclusive os dois itens ◆, #419 e #448.
