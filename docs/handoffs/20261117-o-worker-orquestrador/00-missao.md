---
missao: 20261117-o-worker-orquestrador
titulo: O dono delega uma campanha inteira a um worker que planeja, roda, revisa e mergeia sozinho, dentro de um nível de autonomia assinado
data: 2026-11-17
versao:
branch: feat/o-worker-orquestrador
aprovacao: humano-2026-11-17
adr: docs/adr/0022-the-worker-is-a-session-orchestrator.md
ddd: aplicado
qa:
kaizen_log:
---

# Missão — O worker orquestrador

> Escrito pelo `sdd-planner` com o humano presente. É a única fonte da **intenção**; o `01-plano.md`
> é a fonte do **como**. Toda sessão headless começa lendo estes dois.

## Problema (Gemba)

O dono já delegou três vezes uma cadeia inteira de missões a uma sessão do Claude Code, no
`dotp-remake` (5a, 5b e o Plano 7, de 2026-11-15 a 2026-11-17): planner no Fable, recomendadas
aceitas, `sdd approve`, `sdd run` no worktree da missão, PR, `/codereview` até A, Codex no head,
merge, pós-merge em PR próprio. Funcionou sem código novo no kit, e o registro está em
`docs/superpowers/specs/2026-11-16-o-worker-merge-delegado.md` (fatos M1 a M29). O que o kit tem
hoje para isso, medido em 2026-11-17 no commit `5221477`:

- **Nada.** `ls bin/` devolve `sdd`, `sdd-coordination.py` e `sdd-link-agents`; `ls commands/`
  devolve só `sdd-plan.md`. Do roadmap W1 a W7 (`docs/superpowers/specs/2026-09-22-o-worker-roadmap-design.md`)
  só o W1 está no código. A gaveta (`docs/superpowers/specs/2026-09-23-a-gaveta-do-kit.md`, F6) diz
  "estacionado por decisão humana".
- **A delegação é palavra dita numa sessão.** Vale "nesta sessão": a cadeia do Plano 7 gastou quase
  todo o contexto de uma, e a sessão nova precisou de um SIM do dono às 08:23 (M26). Na noite da 5a
  ela foi gravada numa memória do agente e marcada "usada e esgotada" à mão (§1 do caderno).
- **Os juízos que decidem um merge são leitura do modelo, e já erraram.** Recibo do Codex casado
  pela hora em vez do sha (M13); vigia com `pgrep -f` que casou consigo mesmo (M23); bot sem cota
  lido como "revisou" (M1); verificador que leu 20 de 21 unidades (M24).
- **O roadmap de setembro proíbe o que rodou.** D1: "o worker nunca planeja". D2: "nunca o repo do
  kit". D5: "merge segue humano; até o merge só com ADR". A ADR não existe.
- **O backlog do kit não desce.** `tests/check-todo.sh` responde `ok    83 finding(s)`; o espelho no
  GitHub tem 76 issues abertas e o plano somente-leitura do `todo_issues.py` responde
  `create=7 update=0 ok=76 orphans=0`. Nenhum dos 83 itens carrega a marca `RESOLVED by`.

## Métrica

Binária, lida de comando, no head da branch `feat/o-worker-orquestrador`:

1. `tests/check-worker.sh` existe, roda na suíte (`tests/run-all.sh` verde) e prova, sobre fixture,
   que `bin/sdd-worker` responde o certo em cada um dos cinco níveis de autonomia: para cada nível,
   quais atos são permitidos e quais voltam ao dono.
2. Delegação ausente, vencida, sem assinatura ou ilegível responde `assisted` (o worker não age
   sozinho), com o motivo na saída.
3. `bin/sdd-worker pr-ready` só responde rc 0 com os cinco itens da régua verdadeiros no mesmo sha,
   e cada item sabotado na fixture o faz responder rc 1 nomeando o item.
4. A campanha do kit existe em `docs/superpowers/campaigns/20261117-zerar-as-issues/`, com os 83 itens em seis
   lotes e a delegação **sem assinatura**: `bin/sdd-worker level docs/superpowers/campaigns/20261117-zerar-as-issues`
   responde `assisted`.

A meta 83 → 0 do `TODO.md` **não** é métrica desta missão: é da campanha que ela deixa pronta.

Há uma segunda medida, que não é critério de aceite e é registro obrigatório: esta missão é o
**primeiro `sdd run` de uma missão do kit num worktree ligado** (decisão 6). O que acontecer nessa
corrida vai para o caderno do worker, tenha ela chegado ao PR ou parado.

## Resultado esperado

O kit ganha um programa novo, `bin/sdd-worker`, com seis verbos que respondem por artefato às
perguntas que hoje são juízo do modelo (a delegação vale? este ato cabe no nível? qual é o próximo
passo? o teto estourou? este PR está "tudo ok" neste sha?), e um comando de sessão,
`commands/sdd-worker.md`, que diz à sessão orquestradora o laço e as regras para atravessar uma
noite sem gastar a própria janela de contexto. A delegação deixa de ser palavra: é um arquivo por
campanha, versionado no repo-alvo, com nível, alcance, prazo e dois tetos, assinado pelo dono por
um comando que mostra o que está sendo concedido e pergunta. O roadmap de setembro tem D1, D2 e D5 revisados por ADR, a gaveta mostra a F6 em construção, e
a campanha que zera as issues do kit está escrita e esperando a assinatura do dono.

## Fora de escopo

- **Executar a campanha.** Nenhum lote das 83 é consertado aqui. O L1 é o primeiro ato do worker
  depois do merge e da assinatura.
- **Codex como harness** (Astra planeja, Sol executa). O artefato da campanha declara harness e
  modelos; o `run_phase` continua abrindo só `claude -p`. Missão seguinte (decisão 4).
- **O tick de systemd, o clone dedicado e o operador de ambiente** (W2 a W6 do roadmap). O worker
  desta missão é uma sessão; W4 (`ENV_UP_CMD`) continua sendo o que falta para alvo com interface.
- **`aprovacao: delegated-…` como valor novo do contrato.** O `sdd approve` não muda: sob `full` o
  worker o chama e a trilha fica no diário da campanha. Vai para as pendências.
- **Sincronizar o espelho de issues** (7 itens sem issue). É passo de depois do merge, pela skill
  `todo-to-github-issues`.
- **Os verbos que agem.** `bin/sdd-worker` só responde e assina; quem lança `sdd run`, abre PR e
  mergeia é a sessão, pelos comandos que já existem.

## Gate PLAN-AUTO

Preenchido pelo `sdd-planner` **com evidência**. Todos ✅ → `aprovacao` fica vazio do mesmo jeito: o
humano lê o plano no passo de aceite do `/sdd-plan` e aprova com `sdd approve`. O `auto` só entra
quando o humano o pediu no grill, e aí o pipeline segue sozinho até o PR (ADR 0018 §3). Qualquer ✗ →
`aprovacao` fica vazio e o runner para pedindo aprovação humana explícita, nomeando o critério.

| # | Critério | Status | Evidência |
|---|---|---|---|
| a | Grill sem perguntas abertas não endereçadas (🚩 vazia ou itens deferidos com dono) | ✅ | 11 perguntas, 13 respostas marcadas nas Decisões (a 5 tem duas; a 12 veio fora das opções); nenhuma aberta. Seis itens deferidos, todos com dono, em "Pendências para o humano" |
| b | Checklist kaizen 100% ✅ e checklist DDD 100% ✅ ou `n/a` justificado | ✅ | K1 a K8 ✅ e D1 a D6 ✅, nas duas seções abaixo |
| c | Plano passa no teste de autocontenção (sessão nova só com 00/01/checkpoint executa) | ✅ | Uma sessão nova (subagente sem contexto), só com os três arquivos e leitura do repo, percorreu o I1 e o I2 conferindo cada fato: 7 fatos errados, 12 lacunas e 8 contradições achados, todos corrigidos no plano (entre eles o `check()` que tornava o Check do I1 impossível). Foi leitura com verificação, não execução: nenhum incremento foi rodado de verdade |
| d | Todo incremento do `checkpoint.md` tem Check executável (comando → esperado), vermelho no HEAD pelo `tests/check-checkpoint.sh --red` do kit | ✅ | 11 incrementos; `tests/check-checkpoint.sh --check` → `11 row(s), 10 under the anchor rule, none blind`; `--red` → `11 pending Check(s), every one red at HEAD`, rc 0, em 2026-11-17 17:05 |
| e | `versao:` confirmada pelo humano (ou `JIRA_ENABLED=false`) | ✅ | `JIRA_ENABLED=false` em `.sdd/config.sh` |
| f | `adr:` é uma decisão — um caminho, ou o literal `none` (alocado por `sdd adr new`) | ✅ | `docs/adr/0022-the-worker-is-a-session-orchestrator.md`, alocada por `sdd adr new`, corpo escrito; `sdd adr check --mission … --phase plan` → `and that ADR points back` |

## Checklist kaizen (`kaizen-software`)

> O K8 desta tabela é prosa: quem dispensa a entrada do KAIZEN_LOG.md é só o literal kaizen_log: skipped no frontmatter, decidido com o humano no grill.

| # | Item | Status | Nota |
|---|---|---|---|
| K1 | Gemba — fui ver onde o trabalho acontece | ✅ | Os quatro cadernos do worker lidos; `bin/`, `commands/`, `tests/run-all.sh` e os pisos medidos; o recibo real do Codex lido da API do PR 409; os 83 itens do `TODO.md` varridos um a um |
| K2 | Problema declarado com métrica | ✅ | Quatro fatos binários na seção Métrica, cada um com comando |
| K3 | Desperdícios identificados e cortados | ✅ | Cortados: o tick de systemd, o clone dedicado, o Codex como harness, a chave de config para o diretório da campanha (os verbos recebem o caminho), verbos que agem, e o valor novo de `aprovacao:` |
| K4 | Fatiamento incremental, cada fatia verificável | ✅ | Onze incrementos, um verbo ou um artefato por incremento, cada um com Check vermelho no HEAD (critério d) |
| K5 | Check por artefato (rótulo ≠ artefato) | ✅ | Todo Check lê a saída de `tests/check-worker.sh` ancorada em `^  ok    `, ou um arquivo, ou o rc de um verbo sobre o repo |
| K6 | Jidoka — o que para a linha está definido | ✅ | As paradas do worker estão na decisão 9 e 10; a parada desta missão (a corrida morrer pelo arranjo) está na decisão 12 |
| K7 | SDCA — a melhoria vira padrão (doc/rule/teste) | ✅ | Poka-yoke primeiro: o sensor `tests/check-worker.sh` com mutantes no catálogo; depois o comando e os templates; a rule `anatomia-do-agente.md` recebe texto proposto pela DOCS (linha ⛔) |
| K8 | Registro no KAIZEN_LOG | ✅ | `kaizen_log:` vazio: a fase DOCS deve a entrada, com o antes e o depois medidos (0 → 6 verbos; delegação por palavra → por arquivo) |

## Checklist DDD (`ddd`) — condicional

Acionado: a missão cria quatro conceitos (campanha, lote, delegação, nível de autonomia) e uma
fronteira entre dois programas. Revisão de linguagem e de fronteira, sem código.

| # | Item | Status | Nota |
|---|---|---|---|
| D1 | Linguagem ubíqua: cada termo novo tem um sentido só e um verbete | ✅ | `grep -n -i 'campanha' CONTEXT.md` volta vazio: os quatro termos são novos e ganham verbete no I10. "Worker" passa a designar a sessão orquestradora; o tick do roadmap de setembro fica nomeado "tick" |
| D2 | Termo que mudou de sentido está declarado | ✅ | "Worker" já nomeia, em `docs/pipeline.md:54-79`, o processo Bash da coordenação de checkout: o verbete novo separa "worker da campanha" de "worker da coordenação". "Assistido" não é o nível `pr`: é um quinto degrau, abaixo (decisão 5). "Aprovação" continua sendo o `sdd approve`; o ato do dono sobre a delegação se chama "assinatura", para os dois não se confundirem |
| D3 | Fronteira entre contextos: quem é dono de quê | ✅ | O runner (`bin/sdd`) é dono de UMA missão: fases, gates, ledger. O worker é dono da campanha: fila de lotes, delegação, régua do merge. O worker lê artefatos do runner (frontmatter da missão, ledger) e nunca escreve neles |
| D4 | Invariante de cada conceito escrita uma vez | ✅ | Nível efetivo = o menor entre o assinado e o teto do lote; delegação inválida por qualquer motivo = `assisted`. Uma definição da escada e uma da tabela de atos, em `bin/sdd-worker` |
| D5 | Identidade: como um lote acha a sua missão | ✅ | Pelo artefato, não por tabela de estado: o `00-missao.md` da missão declara `campaign:` e `lot:` no frontmatter (chaves opcionais novas) |
| D6 | Integração: o que atravessa a fronteira e em que formato | ✅ | Quatro leituras, todas de formato já existente: frontmatter do `00-missao.md`, linhas do ledger (`mission`, `cost_usd`), JSON do `gh`, e o comentário `codex-review-state:v1` do Codex |

## Decisões do grill (não re-litigar)

1. **O worker é um orquestrador que gerencia sozinho uma campanha:** planeja, aprova, roda o kit,
   abre o PR, faz a revisão do PR e mergeia, planeja a missão seguinte enquanto uma roda, e aguenta a
   noite toda sem gastar a própria janela de contexto, alimentado por um roadmap, como no
   `dotp-remake`. Porquê: é o único "worker" com três corridas medidas. Revisa D1, D2 e D5 do roadmap
   de setembro, e a forma deixa de ser o tick de systemd.
   - answer: (other: a esteira do PR 410 como opção do kit, com o worker definido como orquestrador que gerencia sozinho, planeja, aprova, roda, faz PR, revisão e merge, e planeja o seguinte enquanto um roda)
2. **A delegação é um artefato por campanha, versionado no repo-alvo, que o worker relê a cada
   passo.** Carrega nível, alcance (os lotes), prazo, dois tetos em dólar e a régua. Porquê: atravessa
   sessões sem SIM novo (M26), tem fim escrito e deixa trilha.
   - answer: (recommended)
3. **Comando de sessão mais um script fino de verbos determinísticos.** `commands/sdd-worker.md` diz
   o laço; `bin/sdd-worker`, fora do `bin/sdd`, responde por artefato. Porquê: tira do modelo os
   juízos que erraram (M1, M13, M23, M24), e cada verbo ganha sensor e mutante. Junto veio o
   requisito: a regra de modelo do worker é "o melhor modelo para planejar" (Claude Code: Fable
   planeja, Opus executa; Codex: Astra planeja, Sol executa).
   - answer: (recommended)
4. **Claude Code nesta missão; Codex é a missão seguinte.** O artefato da campanha declara harness,
   modelo de planejamento e modelo de execução, e `bin/sdd-worker` não cita harness. Porquê: o lado
   do Codex exige o `run_phase` abrir `codex exec`, mudança maior que o worker e nunca medida.
   - answer: (recommended)
5. **Cinco níveis cumulativos, declarados na delegação:** `assisted` < `pr` < `plan` < `merge` <
   `full`. Em `assisted` o worker propõe cada ato e espera o sim do dono; `pr` roda, abre o PR e
   trata os bots; `plan` acrescenta planejar a missão seguinte; `merge` acrescenta o merge e o
   pós-merge; `full` acrescenta o `sdd approve`. Delegação ausente, vencida, sem assinatura ou
   ilegível vale `assisted`. Porquê: a falha da delegação tem de significar "não faço nada sozinho".
   O dono descreveu a escada como indo "do assistido ao noturno completo", sendo o proposto o máximo.
   - answer: (recommended)
   - answer: (recommended)
6. **Missão do kit sob o worker roda por `sdd run` no worktree da missão, pelo `sdd` do PATH,
   lançado isolado, igual ao `dotp-remake`.** Porquê: o `sdd` do PATH é o checkout principal, um
   `bin/sdd` que a missão não edita. Nunca foi medido: o primeiro uso é piloto, com regra de parada.
   - answer: (recommended)
7. **A missão entrega o worker e a campanha do kit pronta para assinar.** O último incremento grava
   a campanha das issues do kit, com a fila decidida neste grill, e a delegação fica sem assinatura.
   Porquê: o fatiamento acontece com o dono na sala, e o worker estreia sobre um roadmap de verdade.
   - answer: (recommended)
8. **A fila é L1 a L6, nesta ordem, com duas regras.** Os 24 itens que deixam uma escolha em aberto
   seguem a recomendada do planner e saem marcados no corpo do PR para o aceite do dono. Os itens do
   L6 têm teto de autonomia `plan`, qualquer que seja o nível assinado. Porquê: os lotes mecânicos
   rodam a noite toda, e as decisões de desenho não são tomadas por um grill sem o dono (M8).
   - answer: (recommended)
9. **A régua do "tudo ok" é a da §3 do caderno, lida por comando, com três paradas.** Os cinco
   itens: revisão com A em todo critério no head; Codex `completed` nesse sha, sem achado aberto;
   nenhum thread aberto; `mergeable` limpo; merge commit com `--match-head-commit`. Bot sem cota
   conta como "não revisou" e é declarado no PR, sem bloquear. Paradas: Codex sem recibo no head em
   60 minutos depois do pedido explícito; nota abaixo de A depois de 3 rodadas; conflito no merge da
   `main` fora de `TODO.md` e da catraca. Porquê: é a régua que decidiu oito merges sem erro.
   - answer: (recommended)
10. **Dois tetos na delegação e pager obrigatório acima de `assisted`.** Teto por missão, que o
    worker passa ao `sdd run` como `BUDGET_MISSION_USD`, e teto da campanha, somado do ledger. Com
    `ON_ESCALATION_CMD` vazio, uma delegação `pr` ou maior vale `assisted`. O gasto da sessão
    orquestradora e dos subagentes fica fora do teto, como limite declarado. Porquê: uma noite sem
    ninguém olhando precisa de fim em dólar e de um aviso que chegue.
    - answer: (recommended)
11. **Missão `20261117-o-worker-orquestrador`, branch `feat/o-worker-orquestrador`, ADR com slug
    `the-worker-is-a-session-orchestrator`.** Porquê: o nome diz a decisão central, e `feat/`
    separa construção de conserto.
    - answer: (recommended)
12. **Esta missão é executada por `sdd run`, não à mão.** Depois do aceite, a sessão do relay lança
    `sdd run 20261117-o-worker-orquestrador` no worktree `/home/joruge/repos/sdd_agents-worker`, pelo
    `sdd` do PATH, isolado (`setsid nohup` e `env -u CLAUDE*`), e conduz o resto (PR, bots, revisão).
    Ela é, portanto, o primeiro `sdd run` medido de uma missão do kit num worktree, antes do L1, e a
    regra de parada da decisão 6 vale para ela: se a corrida morrer **por causa do arranjo**, o caso
    volta ao dono e a construção segue interativa no mesmo worktree. Porquê: palavra do dono, dada
    fora das opções ("aguardo o plano, depois pode aprovar e rodar o sdd run"). Isto não é aprovação
    do plano. Uma primeira leitura do relay ("executada interativamente") foi corrigida por ele.
    - answer: (other: a sessão do relay lança o sdd run no worktree e conduz o PR, os bots e a revisão)

**Parada conhecida, que não é falha do arranjo:** o `gate_PR` do kit exige o carimbo de mutação.
Com o PR aberto e só o carimbo faltando, o `sdd run` sai com rc 2 e pede `./bin/sdd health`. Pela
decisão anterior do dono (PR de missão do kit mergeia sem carimbo; `sdd health` só com a catraca
zerada), esse rc 2 se lê como "PR pronto para a etapa de revisão".

## Pendências para o humano

1. **Assinar a delegação da campanha do kit**, depois do merge desta missão:
   `bin/sdd-worker delegate docs/superpowers/campaigns/20261117-zerar-as-issues`, num terminal, depois de
   preencher nível, prazo e os dois tetos no `delegation.md`.
2. **Configurar o pager do kit.** `ON_ESCALATION_CMD` está vazio no `.sdd/config.sh` deste repo, e
   sem ele qualquer nível assinado vale `assisted` (decisão 10). O comando é escolha sua.
3. **Sincronizar o espelho de issues** depois do último merge do dia, pela skill
   `todo-to-github-issues`: hoje o plano responde `create=7`.
4. **`aprovacao:` sob `full`.** O `sdd approve` grava `humano-YYYY-MM-DD` mesmo quando quem o chama é
   o worker, por delegação. A trilha fica no diário da campanha. Um valor próprio do contrato
   (`delegated-…`) mexe no `gate_PLAN`, nos templates e no `docs/pipeline.md`: decida se vira missão.
5. **A rule `.claude/rules/anatomia-do-agente.md`** (seções 1, 5 e 7) recebe texto proposto pela
   DOCS, como linha ⛔ no PR: a sessão headless não escreve em `.claude/`.
6. **O carimbo de mutação** (`./bin/sdd health`) não roda nesta missão, pela sua regra. Os mutantes
   novos são provados um a um por `tests/check-mutation.sh --only`, que é dica e não carimbo.
