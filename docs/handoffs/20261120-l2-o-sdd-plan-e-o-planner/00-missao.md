---
missao: 20261120-l2-o-sdd-plan-e-o-planner
titulo: Quinze regras do /sdd-plan e do planner ganham texto e asserção, e o --red ganha --list e --only
data: 2026-11-20
versao:
branch: fix/l2-o-sdd-plan-e-o-planner
aprovacao: humano-2026-11-20
adr: none
ddd: n/a
qa:
kaizen_log:
campaign: 20261117-zerar-as-issues
lot: L2
---

# Missão — L2: o `/sdd-plan` e o planner

> Escrito pelo `sdd-planner` com o humano presente. É a única fonte da **intenção**; o `01-plano.md`
> é a fonte do **como**. Toda sessão headless começa lendo estes dois.

## Problema (Gemba)

O `TODO.md` do kit tem 91 achados abertos em `336640e` (`bash tests/check-todo.sh --count TODO.md`
→ `91`), e a campanha `20261117-zerar-as-issues` os reparte em lotes. Este é o **L2**: os 14 que
falam do `/sdd-plan` (`commands/sdd-plan.md`, o que a sessão que faz o relay segue) e do
`sdd-planner` (`agents/sdd-planner.md`). Todos nasceram num `/sdd-plan` real, em repo-alvo
(`dotp-remake`, `magic_tutor`, `lighthouse_project`, `ui24_agent`), e em cada um foi o relay, por
conta própria, que segurou o dano: nenhum tem regra escrita nem sensor.

Os 14, com o título exato do item (é a chave do espelho de issues, **nunca** se muda), a âncora
medida em `336640e` e o incremento que o fecha. O número é o da fila da campanha:

| # | Título do item no `TODO.md` | Âncora | Incremento |
|---|---|---|---|
| 1 | A mitigação de risco que cita um sensor não prova que ele cobre o alvo | `templates/plano.md:41` | I4 |
| 2 | O `/sdd-plan` não diz o que fazer quando a sessão do relay cai no meio do grill | `commands/sdd-plan.md:116` | I2 |
| 3 | Commit do relay no meio do grill muda o HEAD que o planner mediu, e só o worktree é vigiado | `commands/sdd-plan.md:101` | I1 |
| 4 | O aceite do `/sdd-plan` mede de novo os Checks, nunca os fatos do contexto verificado | `commands/sdd-plan.md:174` | I3 |
| 5 | Sob `aprovacao: auto` o `/sdd-plan` deixa a missão sem commit na base e cala o passo seguinte | `commands/sdd-plan.md:238` | I3 |
| 6 | O planner marca o `- answer:` de pergunta que o humano não viu, e sob `auto` o gate já lê aprovado | `agents/sdd-planner.md:52` | I2 |
| 7 | O `/sdd-plan` só manda para worktree no checkout do kit, não com outra missão em voo no alvo | `commands/sdd-plan.md:30` | I1 |
| 8 | Com o passo 2 pulado, o `/sdd-plan` não olha o branch antes de o planner ler o repo | `commands/sdd-plan.md:56` | I1 |
| 9 | O relay não prevê que o job em background do planner repete a pergunta já feita | `commands/sdd-plan.md:131` | I2 |
| 10 | O aceite do `/sdd-plan` só olha três caminhos no `git status` | `commands/sdd-plan.md:227` | I3 |
| 11 | O `/sdd-plan` delega ao planner sem olhar a árvore do alvo nem as missões que já existem | `commands/sdd-plan.md:15` | I1 |
| 12 | O plano que executa fora do `sdd run` promete o gate do EXEC sem o `20-handoff-exec.md` | `bin/sdd:1541` | I4 |
| 13 | O `/sdd-plan` não diz o que fazer com respostas do grill delegadas por escrito | `commands/sdd-plan.md:213` | I2 |
| 14 | O `--red` do aceite pode rodar ao lado da run de outra missão na mesma máquina, sem aviso | `tests/check-checkpoint.sh:1616` | I5 |

O que cada um custou está no corpo do item (`grep -n -F '<título>' TODO.md`).

Há um **15º item**, sem linha no `TODO.md` (decisão 1), medido pelo relay em 2026-11-20:

| # | O defeito | Onde | Incremento |
|---|---|---|---|
| 15 | O chapéu diz "Runs on Fable" e nada transporta o modelo: o subagente herda o da sessão que o chama | `agents/sdd-planner.md:6` (frontmatter sem `model:`), `commands/sdd-plan.md` (seção `## Then`) | I4 |

A evidência do 15: `grep -n '^model:' agents/*.md` não imprime nada; o `commands/sdd-worker.md`
(ato `plan`) diz "with the planner on the campaign's `plan_model:`", e o `campaign.md` declara
`plan_model: fable`, sem nada que leve isso à chamada. O relay leu nos transcritos que o planner do
L1b (2026-11-19 17:37) rodou em `claude-opus-5-5` (`pickedEffortModel` no `.meta.json` do subagente,
212 mensagens), e a primeira tentativa do planner deste L2 também (16 mensagens), até ele a parar e
relançar com `model: fable` na chamada. Esses dois números são do relay; o planner não os reconferiu.

O grill desta missão é, ele mesmo, um caso dos itens 6 e 13: as 10 respostas chegaram ao planner
pelo relay, delegadas por escrito pelo dono ao worker ("grill pela recomendada"), e nenhuma foi
vista por ele na hora. Estão marcadas `(recommended)` com essa nota em cada decisão.

## Métrica

Binária, lida de comando, no head da branch `fix/l2-o-sdd-plan-e-o-planner`:

1. As **19 asserções** novas saem verdes, cada uma com o prefixo `  ok    ` na stdout do seu
   sensor: 16 em `tests/check-hat.sh`, 2 em `tests/check-templates.sh` e 1 linha `rule:` no
   selftest do `tests/check-checkpoint.sh`. É uma por item, e os itens 1, 4, 12 e 14 levam duas
   (as frases estão, uma a uma, no `01-plano.md` e nos Checks do `checkpoint.md`).
2. `tests/run-all.sh` verde.
3. Os 14 itens da primeira tabela carregam `RESOLVED by <hash>`, com o hash do incremento que
   consertou cada um, e os títulos seguem byte a byte iguais.
4. O chapéu editado está igual ao espelho: `cmp -s agents/sdd-planner.md .claude/agents/sdd-planner.md`
   responde rc 0.
5. `tests/check-checkpoint.sh --red <checkpoint> --list` não roda Check nenhum, e
   `--red <checkpoint> --only <ids>` nunca imprime `every one red at HEAD` (provado pelos probes do
   selftest, que a linha `rule:` do item 1 desta lista resume).

A catraca **não** desce nesta missão. O `todo-findings` de `tests/health-baseline.txt` fica em 92:
os 91 da base mais o achado fora de escopo que o planner registrou (pendência 9). Quem apaga os 14
itens e desce o número é o chore de depois do merge.

**Segunda medida, pedida pelo dono em 2026-11-20, que não é critério de aceite: custo e tempo, lado
a lado com o L1.** O EXEC desta missão roda em `xhigh` e o do L1 rodou em `medium`: é o teste de uma
variável sobre o mesmo gênero de trabalho (prosa de comando e de chapéu com asserção), na mesma
semana e com a mesma suíte. O DOCS fica em `medium`, como no L1. A entrada do `KAIZEN_LOG.md` que a
fase DOCS deve traz as medidas das três corridas:

| Medida | De onde sai | L1 (EXEC em `medium`) | L2 (EXEC em `xhigh`) | Worker (EXEC em `xhigh`) |
|---|---|---|---|---|
| Relógio da corrida, do lançamento ao `sdd run rc=` | `.sdd/logs/<missão>/pipeline.log` | 16:00 → 22:22 de 2026-11-19 (6 h 22 min) | a medir | 2026-11-17 18:06 → 2026-11-18 10:50 (16 h 44 min) |
| Sessões e custo da corrida | linhas `session` do ledger (`~/.sdd/autonomy-log.jsonl`) | 15 sessões, US$ 20,22 | a medir | 26 sessões, US$ 127,77 |
| Minutos por sessão de EXEC | `dur_s` das linhas `session` de EXEC | 22,8 min, em 10 sessões | a medir | 40,7 min, em 18 sessões (12 h 13 min) |
| US$ por sessão de EXEC | `cost_usd` das mesmas linhas | US$ 1,32 (US$ 13,21 no total) | a medir | US$ 4,83 (US$ 87,03 no total) |
| Rodadas de REVIEW e incrementos | os `40-review-r<N>.md` e as linhas do checkpoint | 9 I e 1 R; r1 B → R1 → r2 A | a medir | 11 I e 22 R; 4 sessões de REVIEW no runner, 70 min |
| Do PR aberto ao merge | `gh pr view` (criado e mergeado) | a DOCS mede | fecha depois do merge, no diário da campanha | cerca de 27 h (2026-11-18 10:50 → 2026-11-19 13:53) |

A terceira coluna é a missão `20261117-o-worker-orquestrador` (PR #414), a que "levou mais de um
dia" na fala do dono; o EXEC dela rodou em `xhigh` (`effort=settings` no `pipeline.log`). A sessão
de EXEC do L1 teve 20,8 turnos em média. Todos os números do L1 e do worker vieram do relay nesta
data; o planner não os reconferiu no ledger, e a DOCS os reconfere antes de escrevê-los.

Duas ressalvas que a entrada repete:

- **A comparação que isola o effort é a do L2 contra o L1**: mesmo gênero de trabalho (prosa com
  asserção), mesma semana, mesma suíte. O worker foi código novo (um programa, um sensor e
  mutantes) e entra para mostrar onde o tempo foi: o laço de revisão (22 R, e 27 h do PR ao merge).
- Cada `gate_EXEC` roda a suíte inteira, e a suíte cresce com o tempo; e os lotes não têm o mesmo
  número de incrementos (9 no L1, 6 no L2). Por isso a medida é **por sessão**, nunca o total.

## Resultado esperado

O relay de um `/sdd-plan` passa a ter regra escrita para o que hoje decide sozinho: lê a árvore, o
branch e as missões em disco antes de delegar, vai para worktree quando outra corrida segura o
checkout, sabe retomar o mesmo planner quando a própria sessão cai, não pergunta duas vezes ao
humano a pergunta que um job repetiu, conta as marcas de resposta a cada devolução, e só responde
pelo humano sob uma ordem escrita dele, com a recomendada. No aceite, roda de novo uma amostra dos
comandos do contexto verificado, olha o `git status` inteiro, sabe o que fazer sob `auto`, e
procura corrida viva na máquina antes do `--red`. O planner grava o comando ao lado de cada
contagem, roda o sensor que uma mitigação nomeia, marca só a resposta que recebeu, escreve o passo
do `20-handoff-exec.md` em plano que roda fora do `sdd run`, e declara o próprio modelo no
frontmatter. O `--red` ganha um modo que lista sem rodar e um que roda só os Checks nomeados, com
uma última linha que não se confunde com a medida inteira. Cada regra tem uma asserção que fica
vermelha se ela sumir.

## Fora de escopo

- **Os outros 77 itens** do `TODO.md` (L3 em diante) e o achado novo das skills do grill (pendência 9).
- **Apagar os 14 itens e descer a catraca.** É o chore de depois do merge, em PR próprio.
- **Sincronizar o espelho de issues.** Passo de depois do merge, pela skill `todo-to-github-issues`.
- **`bin/sdd` e `bin/sdd-worker`.** Nenhuma linha. O `sdd approve` não passa a aceitar `auto`
  (decisão 4), nenhum gate muda, nenhum mutante novo.
- **`commands/sdd-worker.md`.** O ato `plan` já diz o que a decisão 5 diz, e o L1b edita esse
  arquivo; a frase do modelo entra no `/sdd-plan`, que o ato `plan` chama.
- **Um token novo de resposta** (`- answer: (delegated)`). O leitor D22 fica como está (decisão 5).
- **O resto do frontmatter do chapéu** (`disallowedTools:`, `permissionsDeny:`, `writes:`, `mcp:`).
  Só entra a chave `model:`.
- **`.claude/rules/` e o `CLAUDE.md`.** Regra que mudar vira linha `⛔` com texto proposto na fase DOCS.
- **`./bin/sdd health`.** O carimbo de mutação não roda nesta missão (regra do dono: só com a
  catraca zerada).
- **Medir que o `model: fable` do chapéu faz o subagente abrir em Fable.** Pede sessão nova depois
  do merge; é a pendência 4.

## Gate PLAN-AUTO

Preenchido pelo `sdd-planner` **com evidência**. Todos ✅ → `aprovacao` fica vazio do mesmo jeito: o
humano lê o plano no passo de aceite do `/sdd-plan` e aprova com `sdd approve`. O `auto` só entra
quando o humano o pediu no grill, e aí o pipeline segue sozinho até o PR (ADR 0018 §3). Qualquer ✗ →
`aprovacao` fica vazio e o runner para pedindo aprovação humana explícita, nomeando o critério.

| # | Critério | Status | Evidência |
|---|---|---|---|
| a | Grill sem perguntas abertas não endereçadas (🚩 vazia ou itens deferidos com dono) | ✅ | 10 perguntas, 10 respostas marcadas nas Decisões, todas na recomendada e todas delegadas por escrito (o dono não as viu na hora: está dito em cada uma e na pendência 3); nenhuma aberta. Dez pendências, todas com dono |
| b | Checklist kaizen 100% ✅ e checklist DDD 100% ✅ ou `n/a` justificado | ✅ | K1 a K8 ✅ na seção abaixo; DDD `n/a` com a justificativa de uma linha |
| c | Plano passa no teste de autocontenção (sessão nova só com 00/01/checkpoint executa) | ✅ | Sessão nova, somente leitura: 0 fatos errados em cerca de 25 comandos refeitos, 1 contradição, 1 imprecisão e 11 lacunas, todas corrigidas (nota abaixo da tabela) |
| d | Todo incremento do `checkpoint.md` tem Check executável (comando → esperado), vermelho no HEAD pelo `tests/check-checkpoint.sh --red` do kit | ✅ | 6 incrementos; `tests/check-checkpoint.sh --check` → `6 row(s), 5 under the anchor rule, none blind`, rc 0; `--red` → `6 pending Check(s), every one red at HEAD`, rc 0, em 2026-11-20, sobre `336640e` |
| e | `versao:` confirmada pelo humano (ou `JIRA_ENABLED=false`) | ✅ | `JIRA_ENABLED=false` (lido pelo relay do `.sdd/config.sh` do worktree) |
| f | `adr:` é uma decisão — um caminho, ou o literal `none` (alocado por `sdd adr new`) | ✅ | `adr: none`: frases num comando e num chapéu, uma chave de frontmatter e dois modos de uma ferramenta do planner; nenhum trade-off arquitetural. O comando e a saída do `sdd adr check` estão na nota abaixo |

**Nota do critério c.** Uma sessão nova (subagente sem contexto, somente leitura), só com os três
arquivos e o repo, conferiu o plano em 2026-11-20: rodou de novo cerca de 25 comandos do "Contexto
verificado", todos com a saída que o plano registra; conferiu que as 19 frases de asserção das
tabelas do plano estão byte a byte nos Checks do `checkpoint.md` e que nenhuma asserção de hoje do
`check-hat.sh` contradiz um literal novo. Achou 1 contradição (um placeholder nesta nota), 1
imprecisão (o I5 dizia que um terceiro argumento do `--red` hoje dá rc 96; ele é ignorado) e 11
lacunas do tipo "só se soubesse X": sete no contrato do `--list` e do `--only`, as aspas dos
literais, a ordem da leitura do passo 1 contra o passo 3, o texto do passo 2 do aceite e o Red
escrito com a suíte em curso. Todas foram corrigidas no plano. Foi leitura com verificação, não
execução: I1, I2, I3 e I5 a fundo, I4 e I6 por amostra; a suíte inteira com a chave `model:` só
roda no I4, e o `--red` do critério d foi medido pelo planner, não por essa sessão.

**Nota do critério f.** `./bin/sdd adr check --mission 20261120-l2-o-sdd-plan-e-o-planner --phase plan`
→ `ok    20261120-l2-o-sdd-plan-e-o-planner: adr: none — the mission declares no architectural decision`, rc 0.

## Checklist kaizen (`kaizen-software`)

> O K8 desta tabela é prosa: quem dispensa a entrada do KAIZEN_LOG.md é só o literal kaizen_log: skipped no frontmatter, decidido com o humano no grill.

| # | Item | Status | Nota |
|---|---|---|---|
| K1 | Gemba — fui ver onde o trabalho acontece | ✅ | Os 14 itens lidos no `TODO.md`; o `commands/sdd-plan.md` e o chapéu lidos inteiros; os literais que as asserções de hoje leem do comando listados (`tests/check-hat.sh`), para o lote não os quebrar; `red_one`, `probe()` e os pisos do `check-checkpoint.sh` lidos; `sdd status --no-gates` rodado no worktree de uma corrida viva; o `model: fable` provado numa cópia contra `check-hat.sh` e `check-health.sh` |
| K2 | Problema declarado com métrica | ✅ | Cinco fatos binários na seção Métrica, cada um com comando |
| K3 | Desperdícios identificados e cortados | ✅ | Cortados: mudar o `sdd approve` (código, mutantes e conflito com o L1b por um caso medido); um token `(delegated)` (template, leitor e sensor); um incremento por item (16 suítes); tocar o `commands/sdd-worker.md`; renumerar os passos do "Before anything else" (quatro lugares citam "step 2") |
| K4 | Fatiamento incremental, cada fatia verificável | ✅ | Seis incrementos por momento do `/sdd-plan`, cada um com Check vermelho no HEAD (critério d). Cada item fecha inteiro num commit. O que não tem remédio: são 6 voltas da suíte inteira pelo `gate_EXEC` |
| K5 | Check por artefato (rótulo ≠ artefato) | ✅ | Todo Check lê a saída de um sensor ancorada em `^  ok    `, o `cmp` do espelho, ou a contagem de `RESOLVED by` contra o merge-base |
| K6 | Jidoka — o que para a linha está definido | ✅ | Suíte vermelha de incremento anterior = `blocked`; `./bin/sdd install --force` que responder outra coisa que não `updated`/`identical` = `blocked` com a saída nas notas; asserção antiga do `check-hat.sh` que ficar vermelha = conserta no mesmo commit, nunca segue; âncora do `TODO.md` fora do alvo = conserta no mesmo commit |
| K7 | SDCA — a melhoria vira padrão (doc/rule/teste) | ✅ | Dois degraus. Poka-yoke onde coube: a chave `model:` que o harness lê, e a última linha parcial do `--red --only`, que não casa com a frase que o aceite procura. No resto o degrau que cabe em prosa de comando é a asserção por seção (16 no `check-hat.sh`). Fronteira de verdade para os itens 5 e 6 (o `sdd approve` aceitar `auto`, o runner contar as marcas) é código, e ficou fora por decisão |
| K8 | Registro no KAIZEN_LOG | ✅ | `kaizen_log:` vazio (decisão 10): a fase DOCS deve a entrada, com o antes e o depois medidos e a tabela de custo e tempo da seção Métrica, ao lado do L1 |

## Checklist DDD (`ddd`) — condicional

> Acionado **só** quando a missão toca modelagem de domínio/arquitetura (aggregates, bounded
> contexts, eventos, entidades novas, contratos entre módulos). Missão mecânica/visual/trivial →
> marque `n/a — sem toque de domínio` com uma linha de justificativa. Em dúvida, acione.

`n/a — sem toque de domínio: o lote acrescenta frases a um comando, a um chapéu, a um doc e a um template, uma chave de frontmatter e dois modos a um sensor; nenhum conceito, contrato de artefato ou fronteira entre programas muda.`

## Decisões do grill (não re-litigar)

> **Como este grill foi respondido.** As 10 respostas chegaram pelo relay em 2026-11-20, como
> "respostas delegadas pelo dono (sob o `/sdd-worker` full, grill pela recomendada)". O dono **não
> viu** nenhuma das perguntas na hora. Cada decisão repete isso, e as que tocam uma regra dele ou
> um `◆` da campanha estão na pendência 3, para o corpo do PR.

1. **O achado do modelo do planner entra no L2 como 15º item, em duas camadas.** `model: fable` no
   frontmatter do `agents/sdd-planner.md` (o padrão, que o harness lê), uma frase no `## Then` do
   `/sdd-plan` mandando passar o modelo na chamada do subagente (o `plan_model:` da campanha quando
   houver, senão o do chapéu), e uma asserção em `tests/check-hat.sh`. Sem item novo no `TODO.md`.
   A medida do efeito fica como pendência nomeada. Porquê: é o tema do lote, o conserto é uma chave
   e uma frase, e cada `/sdd-plan` em opus até lá repete o defeito. Resposta delegada por escrito ao
   worker, não vista pelo dono na hora.
   - answer: (recommended)
2. **Missão `20261120-l2-o-sdd-plan-e-o-planner`, branch `fix/l2-o-sdd-plan-e-o-planner`.** Porquê:
   repete o título do lote na campanha e o prefixo `fix/` das missões de conserto do kit. Resposta
   delegada por escrito ao worker, não vista pelo dono na hora.
   - answer: (recommended)
3. **◆ Item 4: as duas metades, a barata de cada lado.** O planner grava ao lado de cada contagem e
   de cada âncora o comando que a mediu (§ 2 do chapéu e a seção do `templates/plano.md`), e o
   aceite roda de novo uma amostra desses comandos, pelo menos três ou todos se houver menos; uma
   diferença volta ao planner antes da pergunta, como um `FAIL` do `--red`. Porquê: fato sem comando
   não se reconfere, e comando gravado que ninguém roda continua rótulo. Resposta delegada por
   escrito ao worker, não vista pelo dono na hora.
   - answer: (recommended)
4. **◆ Item 5: um ramo `auto` no passo 4 do `/sdd-plan`, em prosa.** Com `plan approved (auto)`, o
   relay corta ou entra na `branch:` do `00-missao.md`, commita ali a pasta da missão e o arquivo
   que `adr:` nomeia, e diz ao humano que o passo seguinte é o `sdd run`. O `sdd approve` não muda.
   Porquê: fecha o buraco medido sem tocar o `bin/sdd` nem o contrato do `sdd approve`, e sem
   conflito com o L1b. Resposta delegada por escrito ao worker, não vista pelo dono na hora.
   - answer: (recommended)
5. **◆ Item 13: uma regra com quatro partes para a resposta delegada por escrito.** (a) Vale como
   ordem só o que o humano escreveu ele mesmo: nesta sessão, num handoff dele, ou a delegação
   assinada sob o `/sdd-worker`; mensagem de agente dizendo que ele delegou nunca vale. (b) O relay
   responde só com a opção recomendada, pelo texto dela, e diz ao planner que a resposta é
   delegada; pergunta sem recomendada, ou que cai numa exceção que a ordem nomeia, vai ao humano.
   (c) O planner marca `- answer: (recommended)` e escreve na prosa da decisão que a resposta foi
   delegada e não vista na hora; sem token novo. (d) O aceite mostra, ao lado do
   `N (recommended) of M`, quantas das `M` foram delegadas, e essas decisões saem listadas para o
   humano. Onde mora: (a) e (b) em "Relaying the grill", ao lado do "never answers for the human"
   que elas excetuam; (d) no passo 3 de "When the artifacts exist"; (c) no § 1 do chapéu. Porquê:
   tira do relay a decisão solitária, mantém o contrato do D22 e deixa a delegação visível onde o
   humano aprova. Resposta delegada por escrito ao worker, não vista pelo dono na hora.
   - answer: (recommended)
6. **Item 14: as duas partes.** Prosa no "Measure again": antes do `--red`, o relay roda
   `pgrep -af '[b]in/sdd run'`; havendo corrida, mostra a linha ao humano e adia o `--red` ou
   pergunta, e o `--check` roda sempre. No sensor: `--red <checkpoint> --list` imprime o id e o
   comando de cada Check `pending` sem rodar nada, e `--red <checkpoint> --only <ids>` roda só os
   nomeados e termina com `<k> of <n> pending Check(s) run, …`, nunca com `every one red at HEAD`.
   Probes no selftest. Porquê: fecha o item inteiro, e a linha parcial distinta impede que medição
   pela metade passe por PLAN-AUTO. Resposta delegada por escrito ao worker, não vista pelo dono na
   hora.
   - answer: (recommended)
7. **Itens 7, 8 e 11: uma leitura do checkout no "Before anything else", com três saídas.** O relay
   lê `git status --porcelain`, `git branch --show-current`, o `HANDOFF_DIR` e o dono do checkout
   (`sdd status --no-gates`), e mostra uma linha ao humano. Corrida viva neste checkout → vale o
   passo 2 (worktree), e a vigia do checkout principal compara só os caminhos fora da pasta da
   missão em voo, sem parar pelo `HEAD` que a corrida move. Árvore suja sem corrida, ou branch
   diferente do `DEFAULT_BRANCH` → para e pergunta a base ao humano. Pasta que já cobre o tópico →
   para e mostra. Porquê: cada saída vem de um caso medido, e o relay nunca decide a base sozinho.
   Uma correção de gemba, sem pergunta nova: o `sdd status --no-gates` exige o nome de uma missão
   (medido: sem ele, `error: missing mission name`), então a leitura usa uma pasta de missão que já
   existe no `HANDOFF_DIR`, e o `pgrep` quando não há nenhuma. Resposta delegada por escrito ao
   worker, não vista pelo dono na hora.
   - answer: (recommended)
8. **Item 12: o planner escreve o passo do handoff só quando o grill decide execução fora do
   `sdd run`, e o `docs/plan-only.md` ganha a seção da volta.** No § 4 do chapéu: plano executado
   por sessão sem o `sdd-executor` leva, no fim do último incremento, o passo de escrever o
   `20-handoff-exec.md`, e não promete o gate do EXEC sem ele. No doc: o que o `gate_EXEC` lê.
   Porquê: sob o `sdd run` o executor já escreve o arquivo, e o passo duplicado faria dois donos
   para um artefato. Resposta delegada por escrito ao worker, não vista pelo dono na hora.
   - answer: (recommended)
9. **Seis incrementos, por momento do `/sdd-plan`, cada item inteiro num só.** I1 antes de delegar
   (7, 8, 11, 3), I2 o grill dos dois lados (2, 9, 6, 13), I3 o aceite (4, 5, 10), I4 o planner e o
   modelo (1, 12, 15), I5 o `--red` (14), I6 o fecho. Porquê: cada item fecha num commit só, com o
   comando e o chapéu coerentes entre si, e são 6 suítes em vez de 9 ou 16. Resposta delegada por
   escrito ao worker, não vista pelo dono na hora.
   - answer: (recommended)
10. **`kaizen_log:` fica vazio: a fase DOCS deve a entrada no `KAIZEN_LOG.md`,** com o antes e o
    depois e o custo da corrida ao lado do do L1. Porquê: é a segunda corrida do worker sobre o
    kit, e a comparação com o piloto só existe se as duas forem registradas. Resposta delegada por
    escrito ao worker, não vista pelo dono na hora.
    - answer: (recommended)

Consequências das dez, sem pergunta própria:

- Os itens 1, 2, 3, 6, 9 e 10 seguem a direção escrita no próprio item, sem bifurcação. O relay
  mostrou essa lista ao pedir a pergunta 9.
- O item 9 se concilia com a regra que já existe ("toda pergunta sem resposta volta inteira em toda
  devolução"): a pergunta volta, **igual e marcada como repetição**, e o relay não a leva ao humano
  de novo.
- A numeração dos passos do "Before anything else" não muda: a leitura da decisão 7 entra no passo
  1, porque `commands/sdd-worker.md`, o `CLAUDE.md` e a rule da anatomia citam "step 2".
- `adr: none`, `ddd: n/a`, `qa:` vazio (o kit não tem interface: o `sdd-qa` é a única sessão da
  fase e percorre a jornada no terminal, descrita em "Verificação end-to-end" do plano),
  `aprovacao:` vazio (a aprovação é o ato `approve` do worker, por `sdd approve`).
- Trazer a base é ato de quem lança a corrida (pendência 2), como no L1, e o plano é ancorado em
  seção e frase, nunca em número de linha.

## Pendências para o humano

1. **A delegação com o L2 em `lots:` precisa estar na `main` do checkout da campanha antes do
   `run`.** Medido pelo planner em `336640e`:
   `./bin/sdd-worker allows docs/superpowers/campaigns/20261117-zerar-as-issues plan --lot L2`
   → `ask plan needs plan, effective assisted — lot not covered: L2 is not in lots: L1 L1b`, rc 1.
   O relay informou que o dono assinou uma delegação nova às 08:59 de 2026-11-20 (`lots: all`), num
   branch que chega à `main` por PR, e que o checkout principal só é atualizado depois de a corrida
   do L1b terminar. O planner não viu esse arquivo, e este plano não supõe que ele já vale. O
   `approve` deste plano é ato do worker, com o sim que o dono deu ao relay.
2. **Trazer a base antes do `sdd run`, e só depois do merge do L1b.** Este plano foi escrito sobre
   `336640e`, com o L1b (`20261119-l1b-a-rodada-delta`) em voo. O L1b edita `tests/check-hat.sh`
   (uma família nova na lista do fim), `commands/sdd-worker.md` e `bin/sdd`, entre outros; o L2 só
   divide com ele o `tests/check-hat.sh` e o `TODO.md`. Quem lança a corrida, no worktree da missão:
   `git fetch origin && git merge origin/main`, depois `bash tests/check-todo.sh --anchors TODO.md`
   (`0 off target`), `bash tests/check-hat.sh` (rc 0) e de novo
   `tests/check-checkpoint.sh --check` e `--red` no checkpoint. Conflito fora de `TODO.md` e de
   `tests/health-baseline.txt` volta ao dono.
3. **Aceitar as escolhas feitas sob delegação**, que o corpo do PR lista. Os três `◆` da campanha:
   decisões 3 (item 4), 4 (item 5) e 5 (item 13). As que tocam uma regra do dono: a 1 (uma chave
   nova no frontmatter de um chapéu, e o lote com 15 itens em vez de 14), a 5 (quando o relay
   responde pelo humano), a 6 (dois modos novos numa ferramenta que o `CLAUDE.md` descreve) e a 7
   (quando o `/sdd-plan` para e pergunta a base).
4. **Medir o modelo do planner no primeiro `/sdd-plan` depois do merge**, em sessão nova: o
   `pickedEffortModel` do `.meta.json` do subagente tem de dizer Fable sem o relay passar o modelo
   à mão. Se disser outro, o item 15 reabre como achado no `TODO.md`. Nenhuma asserção deste lote
   prova isso: elas provam o arquivo.
5. **As regras novas só valem depois do merge.** O `/sdd-plan` que o harness carrega é um link para
   o checkout principal (`~/.claude/commands/sdd-plan.md` → `…/sdd_agents/commands/sdd-plan.md`), e
   o chapéu do planner vem de lá também.
6. **O chore de depois do merge:** apagar os 14 itens provados por
   `git merge-base --is-ancestor <hash> origin/main`, descer `todo-findings` e sincronizar o espelho
   de issues (`docs/finding-prs.md`; skill `todo-to-github-issues`). O PR desta missão mergeia por
   **merge commit**, nunca squash, ou os 14 hashes não chegam à `main`.
7. **O carimbo de mutação não roda.** Com o PR aberto e só o carimbo faltando, o `sdd run` sai com
   rc 2 e pede `./bin/sdd health`: lê-se como "PR pronto para revisão".
8. **`sdd preflight` pelo `sdd` do PATH, neste worktree, responde `agent … stale` depois do I2.**
   Ele compara o espelho do worktree com o chapéu do checkout principal, que ainda é o de antes. É
   esperado até o merge; neste worktree o preflight que vale é `./bin/sdd preflight`.
9. **Um achado fora de escopo espera commit.** O planner registrou no `TODO.md` do worktree o item
   "O planner manda chamar duas skills que a sessão pode não listar" e moveu `todo-findings` de 91
   para 92 em `tests/health-baseline.txt`. Os dois arquivos estão modificados e sem commit: o passo
   4 do aceite do `/sdd-plan` os commita na branch da missão, num commit próprio.
10. **Um commit do relay entra no branch antes da corrida, fora dos incrementos.** Por ordem do
    dono, o relay troca no `.sdd/config.sh` deste branch a linha `EFFORT_EXEC="medium"` por
    `EFFORT_EXEC="${EFFORT_EXEC:-medium}"` e lança o `sdd run` com `EFFORT_EXEC=xhigh` no ambiente.
    O padrão continua `medium`, e cada corrida escolhe o seu. Não é incremento, não tem Check, e a
    REVIEW não o conta como mudança fora do escopo: é a variável do teste da segunda medida.
