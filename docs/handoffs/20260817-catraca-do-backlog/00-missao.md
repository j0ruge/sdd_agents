---
missao: 20260817-catraca-do-backlog
titulo: O backlog do kit ganha uma catraca que reprova crescimento silencioso, e o comando que a hospeda ganha o primeiro sensor da sua vida
data: 2026-08-17
versao:
branch: missao/20260817-catraca-do-backlog
aprovacao: humano-2026-08-17
ddd: n/a
---

# Missão — a catraca do backlog

> Escrito pelo `sdd-planner` com o humano presente. É a única fonte da **intenção**; o `01-plano.md`
> é a fonte do **como**. Toda sessão headless começa lendo estes dois.

## Problema (Gemba)

Medido na triagem de 2026-08-17 ([handoff](../triagem-todo-20260817.md)), `git show 8ca54b8:TODO.md`
contra o HEAD:

| | itens | linhas |
|---|---|---|
| início da sessão (`8ca54b8`) | 56 | 449 |
| HEAD (`6d68dfc`) | **68** | 544 |

**16 itens foram fechados e apagados** com prova por `git merge-base` (5 do PR #4, 7 do #5, 4 do
#6). Ainda assim o arquivo cresceu, porque **29 nasceram**. Duas missões completas, 24 sessões,
US$ 234,07 — e o backlog terminou maior do que começou. O kit registra dívida ~1,8× mais rápido do
que a fecha, e **nenhum instrumento mede isso**: `tests/check-todo.sh` mede forma, âncora, data e
teto de 8 linhas com 75 probes, e passa verde em 68 itens exatamente como passaria em 680.

Não há critério de admissão. O único filtro é "cabe em 8 linhas", e nada distingue "a suíte tem um
ponto cego que deixa passar bug real" de "`sdd autonomy` imprime duas linhas em branco".

O lugar certo para a catraca é o `sdd health`, e ele tem um buraco próprio, verificado nesta
sessão: **nenhum sensor da suíte executa `cmd_health`**. Os dois hits de `grep -l 'sdd health'
tests/` são comentários (`check-autonomy.sh:1474`, `check-mutation.sh:97`). O comando que existe
para responder "o kit ainda mede o que diz medir?" é o único do runner sobre o qual ninguém
pergunta a mesma coisa — e já mordeu: duas checagens dele nasceram com a lógica invertida pelo
`pipefail` e foram pegas à mão, não por sensor.

## Métrica

Todas verificáveis por comando, contra o estado medido hoje (`sdd health` verde, score 70/70,
catraca com 6 dívidas conhecidas, `check-todo.sh` reportando 68 achados):

1. `sdd health` emite `todo-findings <N>` como achado da catraca, e uma baseline errada por 1
   reprova **nos dois sentidos** (`finding outside the baseline` **e** `stale baseline`) — provado
   por probe, não por leitura.
2. `tests/check-health.sh` existe, executa `cmd_health` e morre quando `bin/sdd` é sabotado.
   Hoje: **0** sensores executam `cmd_health`.
3. O catálogo de mutação vai de **70** para **77** entradas, com `0 known gap(s)`.
4. **10 achados** do `TODO.md` fecham com hash citado no corpo.

## Resultado esperado

O `sdd health` passa a responder uma pergunta que hoje ninguém faz: o backlog cresceu desde a
última vez que alguém olhou? Crescer continua permitido — missão descobre coisa, e o princípio 5
não muda —, mas passa a ser **deliberado**: a contagem vira linha da baseline, e a catraca
bidirecional que já existe reprova tanto o número que subiu sem registro quanto a baseline que
ficou para trás depois de uma faxina. Nenhum agente ganha regra nova; o que muda é que o número
tem dono e aparece no diff.

Junto vem o sensor que faltava para o próprio `cmd_health`, sem o qual a catraca nova seria código
não medido — a família que este repo chama de falha aberta.

E o `sdd autonomy` para de imprimir `US$ 2` onde quer dizer `US$ 2.00`, de matar dois defeitos
distintos com a mesma frase e de ordenar versões lexicograficamente.

## Fora de escopo

- **Cluster 3 do handoff (9 itens, família "asserção que falha aberta")** — é a mais perigosa e a
  que menos cabe em lote: cada uma falha aberta por um motivo diferente, então são 9 investigações,
  não um incremento. Fica no `TODO.md`, e a catraca desta missão é o que impede o grupo de crescer
  em silêncio enquanto espera.
- **Clusters 4 e 5, e o eixo de i18n** — permanecem no `TODO.md`. O cluster 5 (contrato prometido e
  não cumprido) precisa de quatro decisões humanas antes de virar código; nenhuma foi tomada aqui.
- **`tests/check-todo.sh` não é tocado.** Contar só itens sem `RESOLVIDO por` seria mais honesto —
  item resolvido está pago, só não varrido —, mas mexe num parser que custou 12 rodadas de revisão
  adversarial, e hoje há **zero** itens resolvidos no arquivo (os 2 hits de `grep -c 'RESOLVIDO
  por' TODO.md` são a prosa do cabeçalho, linhas 16 e 24). A contagem cai na varredura pós-merge, e
  é lá que a catraca cobra a baseline.
- **Severidade na admissão, teto por seção e política de expiração** — as três saídas alternativas
  do handoff foram recusadas no grill, com o porquê nas Decisões abaixo.

## Gate PLAN-AUTO

Preenchido pelo `sdd-planner` **com evidência**. Todos ✅ → `aprovacao: auto` e o pipeline segue
sozinho. Qualquer ✗ → `aprovacao` fica vazio e o runner para pedindo aprovação humana explícita.

| # | Critério | Status | Evidência |
|---|---|---|---|
| a | Grill sem perguntas abertas não endereçadas (🚩 vazia ou itens deferidos com dono) | ✅ | 3 perguntas, 3 respostas; os deferidos têm dono declarado em "Fora de escopo" |
| b | Checklist kaizen 100% ✅ e checklist DDD 100% ✅ ou `n/a` justificado | ✅ | seções abaixo |
| c | Plano passa no teste de autocontenção (sessão nova só com 00/01/checkpoint executa) | ✅ | âncoras re-derivadas e números medidos no `01-plano.md`, seção "Contexto verificado" |
| d | Todo incremento do `checkpoint.md` tem Check executável (comando → esperado) | ✅ | 5 de 5; os 5 rodados contra o HEAD e **os 5 vermelhos** — registro no `01-plano.md` |
| e | `versao:` confirmada pelo humano (ou `JIRA_ENABLED=false`) | ✅ | `n/a` — `.sdd/config.sh` traz `JIRA_ENABLED=false` |

⚠️ **Os cinco critérios fecham e mesmo assim `aprovacao` fica vazio, por escolha do humano no
grill.** Não é critério em aberto: é a rota explícita, e ela é mais forte que `auto` — quem grava
`humano-<data>` é `sdd approve 20260817-catraca-do-backlog`, o único caminho que imprime o que está
sendo aprovado, pergunta `[y/N]` e commita o arquivo sozinho.

## Checklist kaizen (`kaizen-software`)

| # | Item | Status | Nota |
|---|---|---|---|
| K1 | Gemba — fui ver onde o trabalho acontece | ✅ | 68 achados lidos item a item; `sdd health` rodado; 5 âncoras re-derivadas |
| K2 | Problema declarado com métrica | ✅ | 56→68 itens, 16 fechados, 29 nascidos, 70/70 no catálogo |
| K3 | Desperdícios identificados e cortados | ✅ | zero mecanismo novo: a catraca reusa `health_finding` + `health_ratchet` |
| K4 | Fatiamento incremental, cada fatia verificável | ✅ | 5 incrementos, cada um com Check próprio |
| K5 | Check por artefato (rótulo ≠ artefato) | ✅ | nenhum Check lê rótulo; todos leem saída de sensor ou contagem de arquivo |
| K6 | Jidoka — o que para a linha está definido | ✅ | a catraca reprova `sdd health`, **fora** do `TEST_CMD`, para não travar missão em voo |
| K7 | SDCA — a melhoria vira padrão (doc/rule/teste) | ✅ | I5 escreve a política no `CLAUDE.md` e no cabeçalho do `TODO.md`, com `doc_rule` cobrando |
| K8 | Registro no KAIZEN_LOG | ✅ | antes/depois: 70→77 mutações, 0→1 sensores sobre `cmd_health`, 68→N com dono |

## Checklist DDD (`ddd`) — condicional

`n/a — sem toque de domínio: a missão mexe em sensores, catálogo de mutação e saída humana de dois
comandos do runner; nenhum aggregate, evento ou contrato entre módulos é criado ou movido.`

## Decisões do grill (não re-litigar)

1. **A catraca mora no `sdd health`, não no `check-todo.sh`.** `tests/run-all.sh:130` invoca o
   `check-todo.sh`, e `run-all.sh` **é** o `TEST_CMD` deste repo — um teto ali reprovaria
   `gate_EXEC`/`QA`/`REVIEW` de qualquer missão em voo por volume de backlog, inclusive a que
   acabou de registrar o item que estourou. O `TODO.md` já registra o custo desse modo: fase que
   morre com a árvore suja faz o runner rederivar EXEC a ~US$ 25 a volta. `sdd health` não é
   chamado por nenhum gate — ele **chama** a suíte.
2. **Congelamento, não teto.** A catraca é a mesma que já existe: divergência reprova para cima e
   para baixo. Crescer é permitido e deve aparecer no diff; o que fica proibido é crescer calado.
   Um teto ("só pode descer") é a decisão 1 com outro nome — missão que legitimamente acha 3 itens
   não conseguiria fechar.
3. **Um número, o total do arquivo.** Uma linha por seção é o único desenho que enxerga a
   concentração (57% numa seção só), mas seção nova nasce em 0 e é rota de fuga — precisaria do
   próprio piso contra vacuidade, um segundo instrumento para um diagnóstico que o humano lê quando
   quiser. O problema medido é volume e taxa, e um número mede os dois.
4. **Severidade na admissão foi recusada.** Quem classificaria é quem descobre: é rótulo, não
   artefato, e o princípio 1 do repo recusa exatamente isso. Acrescentaria campo ao formato
   (`check-todo.sh` + 7 agentes + `CLAUDE.md`) sem forçar fechamento nenhum — o número continuaria
   subindo, só que ordenado.
5. **Política de expiração foi recusada.** Item **aberto** não tem memória durável em lugar nenhum:
   `git log -S`, `KAIZEN_LOG.md` e handoffs só guardam o que fechou. Expirar é perder o achado, não
   arquivá-lo.
6. **O número vem do `check-todo.sh`, nunca de um `grep -c` novo.** Medido: `grep -c '^- \[ \]'
   TODO.md` devolve **69** contra 68 reais — a 69ª é a linha de exemplo do formato, dentro do bloco
   cercado do cabeçalho. O `check-todo.sh` pula blocos cercados de propósito, e foi um estado que o
   parser precisou aprender numa rodada inteira de revisão. Reimplementar a contagem reintroduz o
   erro que o sensor existe para resolver.
7. **`tests/check-health.sh` entra antes da catraca, não depois.** O handoff classificou os cinco
   itens do cluster 2 como "mesma forma: acrescentar entrada no catálogo". É falso para o do
   `cmd_health`: não existe mutação para um comando que nenhum sensor executa — a sabotagem
   passaria despercebida e o catálogo creditaria proteção inexistente. Sem esse sensor, a catraca
   nova nasceria como código não medido.

## Pendências para o humano

- **A linha da catraca não tem dono no formato que a baseline exige.** O cabeçalho da
  `tests/health-baseline.txt` diz que toda linha precisa do item do `TODO.md` que a paga; a
  contagem total não tem um item, tem o arquivo inteiro. O I5 ajusta o cabeçalho para admitir a
  classe em vez de inventar um dono falso. Se você preferir outra saída, é decisão sua — não
  bloqueia o pipeline.
- **Três itens do cluster 2 podem estar parcial ou totalmente vencidos**, e o I4 re-deriva antes de
  implementar: já existem quatro `mut_RUN_degraded_*` no catálogo contra um item que pede mutação
  para "três das quatro metades", e existe `mut_RUN_moved_never_true` contra um item que pede
  mutação para a asserção do `moved`. Item que se prove já coberto fecha por evidência, não por
  código — e a métrica 3 (70→77) cai junto, o que é resultado honesto, não desvio.
