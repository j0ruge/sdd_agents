---
missao: 20261121-l3-gates-do-fim-da-linha
titulo: Os gates do fim da linha leem o head que conferem, o blocked para a linha, e o PR leva o que os handoffs dizem
data: 2026-11-21
versao:
branch: fix/l3-gates-do-fim-da-linha
aprovacao: humano-2026-11-21
adr: docs/adr/0024-the-end-of-line-gates-read-the-head-they-check.md
ddd: n/a
qa:
kaizen_log:
campaign: 20261117-zerar-as-issues
lot: L3
---

# Missão — L3: gates do fim da linha

> Escrito pelo `sdd-planner` com o humano presente. É a única fonte da **intenção**; o `01-plano.md`
> é a fonte do **como**. Toda sessão headless começa lendo estes dois.

## Problema (Gemba)

O `TODO.md` do kit tem 106 achados abertos em `6198b68` (`bash tests/check-todo.sh --count TODO.md`
→ `106`), e a campanha `20261117-zerar-as-issues` os reparte em lotes. Este é o **L3**: os 13 que
falam do fim da linha, isto é, dos gates de EXEC, QA, REVIEW, DOCS e PR do `bin/sdd` e do que o
`sdd-publisher` escreve no PR. Cada linha abaixo foi lida no `TODO.md` e conferida no código em
`6198b68`; o número é a ordem do item na seção `### L3` do `campaign.md`.

| # | Item (título no `TODO.md`) | Onde mora hoje | Incremento |
|---|---|---|---|
| 1 | O `gate_PR` só prova que o PR existe, não que o head dele é o que a missão fechou | `gate_PR` pede ao `gh` só `--json url` | I3 |
| 2 | ◆ O registro do PR nasce depois do push e fica fora do sha verificado | passos 2 e 5 de `agents/sdd-publisher.md` | I3 |
| 3 | O `gate:` cita saídas que a pasta de evidência da fase não guarda | linha `gate:` de `templates/handoff.md` e de `templates/review.md` | I8 |
| 4 | ◆ A REVIEW aprovada não vê o código que entrou depois dela | `gate_REVIEW` e `review_head_ok` | I4 |
| 5 | Numa worktree sem o `.venv`, o gate do EXEC lê o `TEST_CMD` que não rodou como suíte vermelha | `run_check_cmd` e os quatro sítios de `TEST_CMD failed` | I1 |
| 6 | O `gate_PR` não lê o `status: blocked` do `50-pr.md`, e o runner compra outra sessão do publisher | `gate_PR`, `gate_REVIEW`, o comentário do `GATE_HANDOFF_BLOCKED` | I2 |
| 7 | O publisher bloqueado manda o humano fazer `git rebase`, e o rebase tira os hashes dos handoffs da história | parágrafo "Conflict with the base" do publisher | I2 |
| 8 | A linha `kit:` do handoff não tem quem a transporte | publisher, `templates/pr-body.md`, `gate_PR` | I7 |
| 9 | ◆ O "Como verificar" do PR copia o `$SDD_HOME` do `TEST_CMD`, e o comando falha fora do runner | bullet "how to verify" do publisher | I7 |
| 10 | O motivo do gate_QA não diz se o caso e2e vermelho já caiu antes | braço `up` do e2e vermelho no `gate_QA` | I6 |
| 11 | ◆ O K8 lê o branch em que se está, e diz "the mission branch" | bloco K8 do `gate_DOCS` | I5 |
| 12 | ◆ O corpo do PR copia pendência do plano que a revisão já fechou | bullet "decisions for a human" do publisher | I7 |
| 13 | O `gh pr edit` que o publisher e o `gate_PR` mandam usar não edita o corpo no `gh` 2.45 | publisher, o motivo dos `⛔` no `gate_PR`, `docs/pipeline.md` | I3 |

O que a gemba mediu, além do que os itens já dizem:

- **O `gate_PR` não compara head nenhum.** A única pergunta ao `gh` é
  `gh pr view "$url" --json url --jq .url`. O `50-pr.md` das missões do kit é commitado depois do
  push (`cec8c9b` no L2, `ad32508` no L1b), então a cabeça do PR é um commit que o passo 2 do
  publisher não conferiu.
- **A REVIEW só confere até o commit da rodada.** O `review_head_ok` (ADR 0023) lê o intervalo entre
  o `reviewed_head:` e o commit que adicionou a rodada; do commit da rodada até o `HEAD` ninguém lê.
- **O `blocked` da rodada nunca teve regra.** `templates/review.md` declara
  `status: <done | blocked>` e o chapéu do revisor não diz quando escrever `blocked`. Das 55 rodadas
  em disco, 2 escreveram `blocked` (r1 e r2 de `20260818-lote-facil`), e as duas eram rodadas com
  achados em que a linha tinha de seguir.
- **O log de e2e vermelho do Playwright tem um bloco próprio.** Depois da linha `  N failed` vêm as
  linhas `    [chromium] › e2e/arquivo.spec.ts:121:7 › título`, até o contador seguinte. O log
  verde também imprime `arquivo:linha` (em linhas `  ✓`), então só o bloco diz "caiu". Medido em
  212 logs `gate-qa-e2e` do `sales_quote`, 19 com o bloco.
- **O `gh` desta máquina é o 2.85.0**, e nele `gh api 'repos/{owner}/{repo}/pulls/456'` resolve os
  dois marcadores pelo repositório do diretório (medido: imprimiu `456` e o sha do head). O item 13
  foi medido no 2.45; o PATCH da REST serve aos dois.

O grill desta missão foi respondido sob delegação escrita: as 12 respostas chegaram pelo relay, na
opção recomendada, e o dono não viu nenhuma na hora. Está dito em cada decisão e na pendência 3.

## Métrica

Binária, lida de comando, no head da branch `fix/l3-gates-do-fim-da-linha`:

1. As **30 asserções** novas saem verdes, cada uma com o prefixo `  ok    ` na stdout do seu sensor:
   16 em `tests/check-gates.sh`, 2 em `tests/check-autonomy.sh`, 8 em `tests/check-hat.sh` e 4 em
   `tests/check-templates.sh`. As frases estão, uma a uma, no `01-plano.md` e nos Checks do
   `checkpoint.md`.
2. Os **16 mutantes** novos estão no catálogo (`tests/check-mutation.sh`), cada um pego pelo sensor
   que o plano nomeia (`tests/check-mutation.sh --only <slug> <sensor>` → rc 0), e
   `bash tests/check-mutation.sh --anchors` sai rc 0.
3. `tests/run-all.sh` verde.
4. Os 13 itens da tabela acima carregam `RESOLVED by <hash>`, com o hash do incremento que consertou
   cada um, e os títulos seguem byte a byte iguais.
5. Os dois chapéus editados estão iguais ao espelho: `cmp -s agents/sdd-publisher.md
   .claude/agents/sdd-publisher.md` e `cmp -s agents/sdd-reviewer.md .claude/agents/sdd-reviewer.md`
   respondem rc 0.

A catraca **não** desce nesta missão: os 13 itens continuam contados até o chore de depois do merge
os apagar. O número de `todo-findings` em `tests/health-baseline.txt` é o que a base trouxer
(106 em `6198b68`; o chore do L2 o leva a 90 antes de a corrida começar, pendência 2).

**Segunda medida, que não é critério de aceite: custo e tempo ao lado do L2.** O L3 é a primeira
corrida depois do teste de effort, com a EXEC de volta a `medium` (o padrão do `.sdd/config.sh`). A
entrada do `KAIZEN_LOG.md` que a fase DOCS deve traz, por sessão de EXEC, os minutos e o US$ desta
corrida ao lado dos do L2 (EXEC em `xhigh`) e do L1 (EXEC em `medium`), com a ressalva de que o L3
é código de gate com mutante e os outros dois foram prosa com asserção. De onde sai cada número
está no `01-plano.md`.

## Resultado esperado

O fim da linha passa a ler o que afirma. O `gate_PR` compara o head do PR com o head da missão e
confere que a verificação do publisher cobre esse head; o `gate_REVIEW` reabre a fase quando código
entra depois da rodada aprovada; o K8 mede o branch que a missão declara, de onde quer que seja
lido. O `status: blocked` de um `50-pr.md` ou de uma rodada para a linha na sessão que o escreveu,
sem comprar a seguinte, e a saída de um conflito com a base passa a ser `git merge`, nunca `rebase`. Um `TEST_CMD`
que nem rodou deixa de ser lido como suíte vermelha, e o e2e vermelho diz se o caso já tinha caído
antes. O corpo do PR leva as linhas `kit:` dos handoffs (com o gate conferindo a contagem), um
"Como verificar" que roda na shell de quem lê, e a pendência já respondida junto da resposta. O
corpo se edita pela REST, que funciona em todo `gh`. Cada regra tem uma asserção, e cada gate
mudado tem um mutante.

## Fora de escopo

- **Os outros 93 itens** do `TODO.md` (L4 em diante).
- **A prosa que a DOCS escreve depois da REVIEW.** É o lote L6b, com `◆` próprio. O `gate_REVIEW`
  deste lote deixa de fora, de propósito, os caminhos do `writes:` da DOCS (decisão 3).
- **A resolução de um merge da base depois da rodada.** O `sdd-worker pr-ready` já a lê; o
  `gate_REVIEW` não conta commit de merge (decisão 3).
- **`bin/sdd-worker` e `commands/`.** Nenhuma linha.
- **Apagar os 13 itens, descer a catraca e sincronizar o espelho de issues.** É o chore de depois
  do merge, em PR próprio.
- **`.claude/rules/` e o `CLAUDE.md`.** A sessão headless não edita `.claude/`; a seção da rule
  `anatomia-do-agente.md` que este lote desatualiza (§4, verificação) vira linha `⛔` com texto
  proposto na fase DOCS.
- **`./bin/sdd health`.** O carimbo de mutação não roda nesta missão (regra do dono: só com a
  catraca zerada). Os mutantes novos são provados um a um com `--only`.
- **O enum positivo do `status:` da rodada de REVIEW.** O `gate_REVIEW` aprende só o `blocked`;
  uma rodada com outro valor (`continua`, em 1 das 55 em disco) segue lida como hoje. Limite
  declarado no comentário do gate.
- **Parser de e2e para outro runner além do Playwright.** Log sem o bloco `N failed` deixa o motivo
  como hoje (decisão 12).
- **A linha `EFFORT_EXEC` do `.sdd/config.sh`.** A EXEC roda em `medium`, e o plano não mexe nela.

## Gate PLAN-AUTO

Preenchido pelo `sdd-planner` **com evidência**. Todos ✅ → `aprovacao` fica vazio do mesmo jeito: o
humano lê o plano no passo de aceite do `/sdd-plan` e aprova com `sdd approve`. O `auto` só entra
quando o humano o pediu no grill, e aí o pipeline segue sozinho até o PR (ADR 0018 §3). Qualquer ✗ →
`aprovacao` fica vazio e o runner para pedindo aprovação humana explícita, nomeando o critério.

| # | Critério | Status | Evidência |
|---|---|---|---|
| a | Grill sem perguntas abertas não endereçadas (🚩 vazia ou itens deferidos com dono) | ✅ | 12 perguntas, 12 respostas marcadas nas Decisões, todas na recomendada e todas delegadas por escrito (o dono não as viu na hora: está dito em cada uma e na pendência 3); nenhuma aberta. Nove pendências, todas com dono |
| b | Checklist kaizen 100% ✅ e checklist DDD 100% ✅ ou `n/a` justificado | ✅ | K1 a K8 ✅ na seção abaixo; DDD `n/a` com a justificativa de uma linha |
| c | Plano passa no teste de autocontenção (sessão nova só com 00/01/checkpoint executa) | ✅ | Sessão nova, somente leitura: 4 pontos em que o plano não era executável como escrito (I1, I2, I4 e I6), 2 contradições e 9 lacunas, todas corrigidas (nota abaixo da tabela) |
| d | Todo incremento do `checkpoint.md` tem Check executável (comando → esperado), vermelho no HEAD pelo `tests/check-checkpoint.sh --red` do kit | ✅ | 9 incrementos; `tests/check-checkpoint.sh --check` → `9 row(s), 8 under the anchor rule, none blind`, rc 0; `--red` → `9 pending Check(s), every one red at HEAD`, rc 0, em 2026-11-21 (02:23 a 02:44), sobre `6198b68`. A célula do I4 mudou depois (um mutante a menos) e foi medida de novo sozinha: `--red … --only I4` → `I4 is red at HEAD (prints '0 0 0 0 0', wants '1 1 1 3 0')`, rc 0 |
| e | `versao:` confirmada pelo humano (ou `JIRA_ENABLED=false`) | ✅ | `JIRA_ENABLED=false` (`grep -n '^JIRA_ENABLED' .sdd/config.sh`) |
| f | `adr:` é uma decisão — um caminho, ou o literal `none` (alocado por `sdd adr new`) | ✅ | `docs/adr/0024-the-end-of-line-gates-read-the-head-they-check.md`, alocada por `sdd adr new`, com o corpo escrito (emenda a 0023). O comando e a saída do `sdd adr check` estão na nota abaixo |

**Nota do critério c.** Uma sessão nova (subagente sem contexto, somente leitura), só com os três
arquivos, a ADR e o repo, conferiu o plano em 2026-11-21. Refez os comandos baratos do "Contexto
verificado" (config, contagens do `TODO.md`, `REVIEW_FLOOR`, os 926 `mut_`, os três stubs de `gh`,
os `status:` das rodadas e dos `50-pr.md`), todos com a saída registrada, e conferiu que as 30
frases estão byte a byte nos Checks. Achou quatro pontos em que o plano não era executável como
escrito, todos corrigidos:

- **I2:** o plano dizia zero sessões no `blocked`; as duas portas ficam depois do `run_phase`, e o
  par do molde mede uma sessão contra duas.
- **I1:** o plano dizia que o `no_work_check` pararia a repetição; ele ignora motivo que cita um
  log. O motivo do 126/127 deixou de citar o log.
- **I4:** o mutante do `--no-merges` não podia ser pego, porque o `diff-tree` não imprime caminho
  para um commit de merge. A regra e o mutante saíram (16 mutantes, e não 17), e a ADR 0024 foi
  corrigida no mesmo passo.
- **I6:** o fixture acumula logs de e2e, e a contagem `2 of the last 3` não sairia. O plano manda
  limpar só esses logs e avaliar uma vez.

Também corrigidas: duas contradições (as sessões do I2 e a frase "nenhum incremento mexe em dois
gates") e nove lacunas (o fixture no branch base no I4, a fase forçada no I2, a
`mission_branch_declared` que já existe, o `review_check` e o piso, o prefixo dos motivos do
`gate_REVIEW`, entre outras). Foi leitura com verificação, não execução, e as correções **não
passaram por uma segunda sessão**.

**Nota do critério f.** `./bin/sdd adr check --mission 20261121-l3-gates-do-fim-da-linha --phase plan`
→ `ok    docs/handoffs/20261121-l3-gates-do-fim-da-linha/00-missao.md: adr: docs/adr/0024-the-end-of-line-gates-read-the-head-they-check.md — and that ADR points back`, rc 0.

## Checklist kaizen (`kaizen-software`)

> O K8 desta tabela é prosa: quem dispensa a entrada do KAIZEN_LOG.md é só o literal kaizen_log: skipped no frontmatter, decidido com o humano no grill.

| # | Item | Status | Nota |
|---|---|---|---|
| K1 | Gemba — fui ver onde o trabalho acontece | ✅ | Os 13 itens lidos no `TODO.md`; `gate_PR`, `gate_REVIEW`, `review_head_ok`, o K8 do `gate_DOCS`, `run_check_cmd`, o braço do e2e do `gate_QA` e o contrato do `GATE_HANDOFF_BLOCKED` lidos no `bin/sdd`; o publisher, `templates/pr-body.md`, `templates/handoff.md` e `templates/review.md` lidos inteiros; os `status:` das 55 rodadas e dos 21 `50-pr.md` em disco contados; 212 logs reais de e2e amostrados; os stubs de `gh` dos sensores listados; o PATCH da REST medido no `gh` 2.85 |
| K2 | Problema declarado com métrica | ✅ | Cinco fatos binários na seção Métrica, cada um com comando |
| K3 | Desperdícios identificados e cortados | ✅ | Cortados: rodar a suíte duas vezes na fase PR (a régua do `verified_head:` dispensa); um gate sobre a seção "Como verificar", cujo título muda com o idioma; uma pasta de evidência de contrato; a regra do `gate:` no `turn_rule` de toda fase; reabrir a REVIEW pela prosa da DOCS (uma rodada a mais em toda missão, e a escolha do L6b tomada aqui); treze incrementos (quatro suítes a mais) |
| K4 | Fatiamento incremental, cada fatia verificável | ✅ | Nove incrementos, um por costura do código, cada item inteiro num só, cada um com Check vermelho no HEAD (critério d). Cada leitura nova de um gate fecha num commit só, com o mutante dela. O que não tem remédio: são 9 voltas da suíte inteira pelo `gate_EXEC` |
| K5 | Check por artefato (rótulo ≠ artefato) | ✅ | Todo Check lê a saída de um sensor ancorada em `^  ok    `, a presença do slug do mutante no catálogo, o `cmp` do espelho, ou a contagem de `RESOLVED by` contra o merge-base. O mutante só conta depois de `--only` responder rc 0, anotado nas notas |
| K6 | Jidoka — o que para a linha está definido | ✅ | Suíte vermelha de incremento anterior = `blocked`; mutante novo que `--only` não pega = o incremento não fecha (a asserção não mede); asserção antiga que ficar vermelha = conserta no mesmo commit; âncora do `TODO.md` fora do alvo = re-ancora no mesmo commit; `./bin/sdd install --force` que responder outra coisa que não `updated`/`identical` = `blocked` com a saída nas notas |
| K7 | SDCA — a melhoria vira padrão (doc/rule/teste) | ✅ | Poka-yoke onde coube: seis leituras novas viram recusa de gate com mutante (head do PR, `verified_head:`, código depois da rodada, `blocked` em dois gates, contagem das linhas `kit:`). O que é prosa de chapéu e de template (itens 3, 7, 9 e 12) fica no degrau da asserção por seção, e a razão de não haver gate está nas decisões 4 e 10. `docs/pipeline.md` e a ADR 0024 mudam no commit do gate |
| K8 | Registro no KAIZEN_LOG | ✅ | `kaizen_log:` vazio (decisão 8): a fase DOCS deve a entrada, com o antes e o depois do lote e o custo por sessão de EXEC ao lado do L2 e do L1 |

## Checklist DDD (`ddd`) — condicional

> Acionado **só** quando a missão toca modelagem de domínio/arquitetura (aggregates, bounded
> contexts, eventos, entidades novas, contratos entre módulos). Missão mecânica/visual/trivial →
> marque `n/a — sem toque de domínio` com uma linha de justificativa. Em dúvida, acione.

`n/a — sem toque de domínio: o lote acrescenta leituras a cinco gates que já existem e frases a dois chapéus e três templates; a única chave nova de artefato (verified_head: no 50-pr.md) repete a forma do reviewed_head: da ADR 0023, e o trade-off dela está na ADR 0024.`

## Decisões do grill (não re-litigar)

> **Como este grill foi respondido.** As 12 respostas chegaram pelo relay em 2026-11-21, como
> "respostas delegadas por escrito pelo dono (sob o `/sdd-worker` full, grill pela recomendada)". O
> dono **não viu** nenhuma das perguntas na hora. Cada decisão repete isso, e as que tocam uma regra
> dele ou um `◆` da campanha estão na pendência 3, para o corpo do PR.

1. **Missão `20261121-l3-gates-do-fim-da-linha`, branch `fix/l3-gates-do-fim-da-linha`.** Porquê:
   repete o título do lote na campanha e o prefixo `fix/` das missões de conserto do kit. Resposta
   delegada por escrito ao worker, não vista pelo dono na hora.
   - answer: (recommended)
2. **◆ Item 2 (e a forma do item 1): o `50-pr.md` entra no PR e grava o sha verificado.** O commit
   do registro toca só a pasta da missão e é empurrado. O arquivo ganha `verified_head:`, o sha em
   que o passo 2 do publisher rodou. O `gate_PR` passa a exigir o `headRefOid` do PR igual ao head
   da missão, e só a pasta da missão mudada entre `verified_head:` e esse head. Registro sem a chave
   passa, como as rodadas antigas sem `reviewed_head:`; PR `MERGED` não é lido. Porquê: fecha os
   dois itens com a régua da ADR 0023, sem pagar uma segunda suíte. Recusadas: rodar o passo 2 de
   novo na cabeça final (uma suíte a mais, e o registro dela seria outro commit sem verificação) e
   deixar o `50-pr.md` fora do PR (a fase deixa de ser derivável em outra máquina). Resposta
   delegada por escrito ao worker, não vista pelo dono na hora.
   - answer: (recommended)
3. **◆ Item 4: o gate reabre a REVIEW, medindo só o que nenhum chapéu posterior escreve.** O
   `gate_REVIEW` recusa quando um commit da missão posterior ao da rodada, que não é merge, toca
   caminho fora do `writes:` da REVIEW e do `writes:` da DOCS. O motivo nomeia o commit e o caminho,
   e a rodada nova é delta (ADR 0023). Passam como hoje a rodada sem `reviewed_head:` e a missão já
   mergeada (intervalo vazio). Limites declarados: a prosa da DOCS fica para o L6b, e a resolução de
   um merge da base fica com o `pr-ready`. Uma correção de gemba, sem pergunta nova: o gate não
   precisa de uma regra para pular o commit de merge, porque a leitura por commit não imprime
   caminho para ele, e o que o merge trouxe da base sai do intervalo pela própria base. Porquê: o dono do artefato é o `sdd-reviewer`, então o
   gate é satisfazível, e as 2 intervenções medidas no lighthouse viram volta derivada. Recusadas:
   só nomear no motivo (rótulo que ninguém é obrigado a ler) e reabrir por qualquer caminho fora da
   pasta da missão (toda missão pagaria uma rodada depois da DOCS). Resposta delegada por escrito ao
   worker, não vista pelo dono na hora.
   - answer: (recommended)
4. **◆ Item 9: regra no chapéu e no template, com asserção, sem gate novo.** O "how to verify" só
   leva comando que a shell do leitor roda. Quando o `TEST_CMD` cita variável do runner
   (`$SDD_HOME`, `$TODO_FILE`, `$DEFAULT_BRANCH`), a linha do gate vira `sdd preflight`, com uma
   frase dizendo que ele roda o `TEST_CMD` no ambiente do runner; os comandos próprios do projeto
   seguem literais. Porquê: é a rota que o `config/schema.md` já documenta, e um gate sobre uma
   seção cujo título muda com o idioma falharia aberto ou recusaria um PR do kit que cita
   `$SDD_HOME` em prosa. Resposta delegada por escrito ao worker, não vista pelo dono na hora.
   - answer: (recommended)
5. **◆ Item 11: o K8 mede o `branch:` declarado, e o intervalo é vazio quando ele não existe mais.**
   Com o `HEAD` fora do `branch:`, o K8 mede a ponta desse branch (local, senão `origin/<branch>`)
   contra a base. Branch já contido na base, ou apagado depois do merge, dá intervalo vazio e passa,
   como hoje no branch base. Com o `HEAD` no `branch:`, nada muda. O motivo nomeia o branch lido.
   Porquê: junta as duas direções do item, cada uma no caso em que é verdadeira, e a missão não
   mergeada lida de outro branch continua cobrada. Resposta delegada por escrito ao worker, não
   vista pelo dono na hora.
   - answer: (recommended)
6. **◆ Item 12: a pendência respondida vai junto da resposta, nunca some.** O publisher confere cada
   pendência do `00-missao.md` contra os handoffs posteriores; a que um handoff responde sai marcada
   `[x]`, com a resposta em uma linha e o arquivo que a deu, e as outras seguem `[ ]`. Chapéu e
   `templates/pr-body.md` mudam no mesmo commit, com asserção. Porquê: julgar "respondida" é juízo
   de um chapéu mecânico, e um erro dele fica visível no PR em vez de apagar uma decisão do dono.
   Resposta delegada por escrito ao worker, não vista pelo dono na hora.
   - answer: (recommended)
7. **Uma ADR nova, a 0024, alocada por `sdd adr new`, que emenda a 0023.** Diz que os gates do fim
   da linha leem o head que conferem: as três leituras (decisões 2, 3 e 5), a exclusão do `writes:`
   da DOCS com o L6b como dono do resto, e as alternativas recusadas. Porquê: reabrir a REVIEW por
   artefato é caro de reverter, e "por que a DOCS fica de fora?" é a pergunta que um leitor fará em
   seis meses. Resposta delegada por escrito ao worker, não vista pelo dono na hora.
   - answer: (recommended)
8. **`kaizen_log:` fica vazio: a fase DOCS deve a entrada no `KAIZEN_LOG.md`,** com o antes e o
   depois do lote e o custo da corrida em `medium` ao lado do L2 em `xhigh`. Porquê: é a medida que
   confirma ou refuta a volta ao `medium`, e só existe se for registrada. Resposta delegada por
   escrito ao worker, não vista pelo dono na hora.
   - answer: (recommended)
9. **Nove incrementos, um por costura, cada item inteiro num só.** I1 o rc 127 do `TEST_CMD` (item
   5); I2 o `blocked` e o `git merge` (itens 6 e 7); I3 o head do PR, o `verified_head:` e a REST
   (itens 1, 2 e 13); I4 a REVIEW que reabre (item 4); I5 o K8 (item 11); I6 o histórico do e2e
   (item 10); I7 o corpo do PR (itens 8, 9 e 12); I8 o `gate:` (item 3); I9 o fecho. Porquê: cada
   leitura nova de um gate fecha com o mutante dela num commit só. Uma correção
   de gemba, sem pergunta nova: o `docs/pipeline.md` muda no commit de cada gate, e não no I9, porque
   o `CLAUDE.md` cobra o contrato no mesmo commit; e a rule da anatomia não entra no I9, porque a
   sessão headless não edita `.claude/` (vira `⛔` na DOCS). O I9 fica com as linhas `RESOLVED by`.
   Resposta delegada por escrito ao worker, não vista pelo dono na hora.
   - answer: (recommended)
10. **Item 3: regra no template, com asserção no `tests/check-templates.sh`.** Toda medida citada no
    `gate:` traz o comando inteiro e o sha em que rodou, para ser refeita; o `gate:` só diz "saídas
    em `<caminho>`" quando o arquivo está lá; medida sem um dos dois sai do `gate:`. Entra nos dois
    templates que têm o campo (`handoff.md` e `review.md`). Porquê: todo handoff nasce do template,
    a regra fica numa definição só, e não cria contrato de artefato novo. Resposta delegada por
    escrito ao worker, não vista pelo dono na hora.
    - answer: (recommended)
11. **Item 6: os dois gates armam, e o contrato passa a dizer o que `blocked` significa na rodada.**
    O `gate_PR` arma o `GATE_HANDOFF_BLOCKED` antes de ler o `pr_url`, e o `gate_REVIEW` arma na
    rodada mais nova. `templates/review.md` e o chapéu do revisor ganham a regra no mesmo commit:
    `blocked` é a rodada que não pôde ser feita ou que espera decisão humana; rodada com achados é
    `done` com a nota real. Um mutante por setter, e o comentário do marcador re-deriva o contrato
    para os dois. Porquê: é a direção do item, o token passa a valer o mesmo nos quatro gates, e a
    regra escrita coincide com o que 53 das 55 rodadas já fazem. Resposta delegada por escrito ao
    worker, não vista pelo dono na hora.
    - answer: (recommended)
12. **Item 10: o gate lê o bloco `N failed` do Playwright.** A chave é `arquivo:linha`; a contagem
    é em quantos dos 50 logs `gate-qa-e2e` anteriores do repo, de qualquer missão, o mesmo caso está
    no bloco de falhas. Log sem o bloco deixa o motivo como hoje, com o limite declarado no
    comentário, e o fixture é copiado de um log real, com a proveniência. Porquê: é o único formato
    com evidência em disco, conta só falhas e falha fechado no formato desconhecido. Resposta
    delegada por escrito ao worker, não vista pelo dono na hora.
    - answer: (recommended)

Consequências das doze, sem pergunta própria:

- Os itens 5, 7, 8 e 13 seguem a direção escrita no próprio item, sem bifurcação.
- **Item 5:** o rc 126 (arquivo sem permissão de execução) entra no mesmo braço do 127, porque nos
  dois a suíte não começou.
- **Item 6, além da decisão 11:** o `status:` do `50-pr.md` é lido positivamente quando presente
  (`done` ou `blocked`; outro valor é recusado pelo nome), e ausente passa, como os registros e os
  fixtures antigos. Os 21 `50-pr.md` em disco dizem `done`.
- **Item 8:** o gate conta as linhas `- kit:` dos handoffs da missão fora de citação e de cerca, e
  exige ao menos o mesmo número de linhas `- kit:` no corpo do PR. O corpo só é pedido ao `gh`
  quando há `⛔` ou `kit:` a procurar, e o de um PR `MERGED` não é lido.
- **Item 1:** "o head da missão" é o `HEAD` quando o checkout está no `branch:`, e a ponta do
  `branch:` quando não está: uma definição só, que o K8 da decisão 5 também lê.
- `ddd: n/a`, `qa:` vazio (o kit não tem interface: o `sdd-qa` é a única sessão da fase e percorre a
  jornada no terminal, descrita em "Verificação end-to-end" do plano), `aprovacao:` vazio (a
  aprovação é o ato `approve` do worker, por `sdd approve`).
- O plano é ancorado em função e frase, nunca em número de linha.

## Pendências para o humano

1. **Trazer a base antes do `sdd run`, e só depois do merge do chore do L2.** Este plano foi escrito
   sobre `6198b68`, com o chore pós-merge do L2 em curso em outro worktree. Segundo o relay (o
   planner não viu o diff), ele apaga 16 itens do `TODO.md` (catraca 106 → 90) e mexe no
   `campaign.md`, no `KAIZEN_LOG.md`, em `commands/sdd-plan.md`, em `templates/plano.md` e em alguns
   sensores. Quem lança a corrida, no worktree da missão: `git fetch origin && git merge
   origin/main`, depois `bash tests/check-todo.sh --anchors TODO.md` (`0 off target`) e de novo
   `tests/check-checkpoint.sh --check` e `--red` no checkpoint. Conflito fora de `TODO.md` e de
   `tests/health-baseline.txt` volta ao dono.
2. **A catraca do plano é a da base.** Onde este plano diz 106, leia o que
   `bash tests/check-todo.sh --count TODO.md` disser depois do merge da pendência 1.
3. **Aceitar as escolhas feitas sob delegação**, que o corpo do PR lista. Os cinco `◆` da campanha:
   decisões 2 (item 2), 3 (item 4), 4 (item 9), 5 (item 11) e 6 (item 12). As que tocam uma regra do
   dono: a 3 (o `gate_REVIEW` passa a abrir rodada sozinho, contada no `REVIEW_MAX_ITER`), a 7 (uma
   ADR nova que emenda a 0023), a 11 (o `blocked` de uma rodada passa a parar a linha com rc 3 e a
   chamar o pager) e a 12 (o `gate_QA` passa a ler um formato de um runner de teste).
4. **O efeito da decisão 2 no fluxo dos bots de PR.** Depois de um conserto de código empurrado com
   o PR aberto, o `gate_REVIEW` pede uma rodada delta (decisão 3) e o `gate_PR` pede ao publisher
   que rode o passo 2 de novo e regrave o `verified_head:`. É uma sessão de Sonnet e uma suíte por
   leva de consertos. No kit, o `sdd run` só chega ao rc 2 do carimbo depois disso.
5. **As regras novas só valem depois do merge.** O `sdd` do PATH é o checkout principal: os gates
   que julgam a corrida deste lote são os de antes dele. A primeira missão medida pelos gates novos
   é a seguinte.
6. **O chore de depois do merge:** apagar os 13 itens provados por
   `git merge-base --is-ancestor <hash> origin/main`, descer `todo-findings` e sincronizar o espelho
   de issues (`docs/finding-prs.md`; skill `todo-to-github-issues`). O PR desta missão mergeia por
   **merge commit**, nunca squash, ou os 13 hashes não chegam à `main`.
7. **O carimbo de mutação não roda.** Com o PR aberto e só o carimbo faltando, o `sdd run` sai com
   rc 2 e pede `./bin/sdd health`: lê-se como "PR pronto para revisão".
8. **`sdd preflight` pelo `sdd` do PATH, neste worktree, responde `agent … stale` depois do I2.**
   Ele compara o espelho do worktree com o chapéu do checkout principal, que ainda é o de antes. É
   esperado até o merge; neste worktree o preflight que vale é `./bin/sdd preflight`.
9. **A rule da anatomia fica desatualizada até o dono aplicar o `⛔`.** A §4
   (`.claude/rules/anatomia-do-agente.md`) descreve o `gate_REVIEW`, o `gate_PR` e o K8 de antes; a
   fase DOCS propõe o texto, e só o dono o escreve.
