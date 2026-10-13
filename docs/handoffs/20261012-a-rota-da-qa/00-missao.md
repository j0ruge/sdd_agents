---
missao: 20261012-a-rota-da-qa
titulo: a QA que o grill dispensou e o reteste depois de um F<n> passam a ter rota no runner, o handoff de QA fica em dia, e o aceite do /sdd-plan mostra o plano que o humano aprova
data: 2026-10-12
versao:
branch: fix/lote-7-a-rota-da-qa
aprovacao:
adr: docs/adr/0018-the-qa-route-and-the-read-plan.md
ddd: n/a
---

# Missão — o lote 7: a rota da QA e o aceite que lê o plano

> Nascida do laço `sdd kaizen` (2026-10-12, veredito `melhorou` sobre `0270727` em `05-verdict.md`)
> e **replanejada com o humano** em 18 perguntas (D1–D18; da 13ª à 18ª vieram das rodadas de revisão
> do PR #247), conduzidas pelo `sdd-planner` com relay.
> `aprovacao:` fica vazio por regra (plano nascido do kaizen nunca é `auto`, `gate_PLAN`) e porque o
> D4 manda: o humano aprova com `sdd approve` depois de ler o plano na tela.
>
> ⚠️ Missão do **kit**: executa-se de forma **interativa num worktree ligado** cortado da
> `origin/main` depois do merge do PR de docs (D10, ADR 0016 §2), nunca por `sdd run` a partir do
> checkout principal.

## Problema (Gemba)

Três famílias de lacuna, medidas na janela do lote 6 (cinco missões do `sales_quote` sobre
`0270727`) e na campanha L0–L4, com o caderno de campo do worker
(`docs/superpowers/specs/2026-10-09-o-worker-caderno-de-campo.md`, PR #246) como testemunha.

**1. A QA não tem rota para o que o grill decidiu nem para o reteste.**
- **O `skipped` decidido no grill não tem caminho headless.** Com `APP_URL` ou `E2E_CMD`
  preenchidos, o `qa_substep` (`bin/sdd:2672-2683`) devolve `plan` sem charter e `exec` sem relatório
  da missão fechado, e só depois `close`, a única sub-etapa cujo chapéu escreve `status: skipped`.
  3 das 5 missões decidiram `skipped` no grill e fizeram o ritual à mão: `sdd run` até o TICKET,
  `30-handoff-qa.md` escrito pelo operador, `sdd note-manual … QA` (linhas `manual` de 2026-10-11
  09:19 e 15:22 e de 2026-10-12 17:03), e um segundo `sdd run`. Esse segundo lançamento foi **a**
  intervenção de cada uma: 3 das 5 da fatia. A rota existiu por acidente até o `121a696` (ADR 0013,
  2026-09-28): em 2026-09-24 duas missões do alvo chegaram ao `sdd-qa`, que escreveu `skipped` em
  45 s e 86 s, por US$ 1,54 e US$ 1,64.
- **Depois de um `F<n>`, nada reanda a jornada.** Com o relatório da missão `closed`, a sub-etapa
  vai direto ao `close`, e a Âncora 3 do `gate_QA` segue contando o bug consertado. A saída usada
  foi a sessão `sdd-qa` chamar a skill `qa-execution` pela ferramenta `Skill`: r2, r3 e r4 da
  `20261005-mascaras-ncm-e-painel` e a `20261009-o-que-some-calado` (US$ 7,19, 1144 s). Isso só
  funciona porque as duas skills declaram `disable-model-invocation: false`
  (`grep -m1 disable-model-invocation ~/.claude/skills/qa-*/SKILL.md`), e os comentários do runner
  dizem o contrário (`bin/sdd:2651-2654`, `:2915-2917`).
- **O handoff de QA mente depois de um conserto.** Nenhum gate exige o `30-handoff-qa.md` escrito
  depois do último `F<n>`. Com a rota do reteste ele ficaria o de antes, dizendo que o F está
  pendente, e é esse o arquivo que a DOCS e o corpo do PR leem. No caminho sem interface já é assim
  hoje.
- **A mensagem do `skipped` afirma o que o runner não mediu** (`bin/sdd:1606`:
  `qa: skipped (diff has no user-visible change)`). Item (d) da fila do operador.
- **O spec do bug que nenhum agente fecha não tem idioma** (`agents/sdd-qa.md` § 3). O spec vermelho
  derruba o `E2E_CMD`, e a saída usada no L3 foi um `test.fail()` chamado depois das pré-condições.
  Item (f), `kit:` de `20261011-detalhe-e-lista-dizem-a-verdade`.

**2. O aceite do `/sdd-plan` não mostra o que o humano aprova.**
- O planner §6 (`agents/sdd-planner.md:162`) manda `auto` com tudo ✅. Do L0 ao L4 o humano quis ler
  antes, e o relay mandou deixar vazio. No L2, repassar o aviso "Never write `aprovacao:` by hand",
  que proíbe **prosa** no campo, suprimiu o `auto`: item (a).
- O passo 3 do aceite mostra só caminhos e uma linha por incremento, e pergunta pelo "critério ✗",
  sem cobrir tudo ✅ com o campo vazio: item (b). O humano pediu (2026-10-11) o plano renderizado no
  formato de um plano do superpowers antes do YES/NO.
- O aceite não roda o `--red` de novo. No L4 foi o **passo** do aceite (o relay rodando `--red`
  antes de mostrar o plano) que achou a "Medição do vermelho" desatualizada: `prints '4 0 0 1 0 2
  0', wants '4 0 0 1 6 0 5'` contra os seis campos que o plano registrava. Item (h).
- O aviso de trabalho longo não pede reestimativa: 30 min estimados, ~2h55 reais no L4, e o humano
  perguntou no meio se estava tudo certo. Item (i).
- O planner do L3 nomeou arquivos em português contra o `<CRITICAL>` do `CLAUDE.md:233` do alvo, e
  só o Codex pegou, depois do PR. Item (g).
- Na sessão do grill (2026-10-12), o humano escolheu a opção recomendada em 16 de 16 perguntas (8 no
  grill do L4, 8 neste até a D8), e nenhum artefato registra isso. É a amostra histórica que motivou
  a D8; a contagem desta missão hoje está na D8 e nas pendências.

**3. Dois chapéus headless escrevem artefato que mente.**
- **Carimbo de hora inventado.** No L4 o `10-ticket.md` diz `data: 2026-10-12 12:10` com a sessão
  TICKET às 17:02:48–17:03:29, e o `45-docs.md` diz `18:10` com a sessão DOCS às 18:02:39–18:03:15
  (`pipeline.log` do alvo). Nenhum chapéu nem o `boot_prompt` diz que a hora sai de `date`. Item (j).
- **O K8 do plano contra a DOCS.** No L4 o K8 estava ✅ e atribuía a entrada do `KAIZEN_LOG` à DOCS
  (`00-missao.md:161` do alvo); o `45-docs.md:22` marcou `n/a`, e o operador escreveu a entrada à
  mão depois do PR (`acb708b9`). O `gate_DOCS` (`bin/sdd:2131`) não lê o `00-missao.md`. Item (k).

E um avulso: **o template do `TODO.md` não diz onde vai o `RESOLVED by`** num item no teto de 8
linhas (`templates/todo.pt-BR.md:32-36`). Item (c). O plano nascido dizia "no fim da linha
`Fonte:`", e isso **reprova** no `check-todo.sh` de hoje (medido nesta sessão: `the last field
names no <agent>`).

## Métrica

Todas binárias, lidas nas linhas `ok` de sensor da suíte:

- **M1:** com interface, charter presente, nenhum relatório da missão e `qa: skipped` no
  `00-missao.md` → `sdd run --dry-run --phase QA` projeta `QA:close=sdd-qa`. Hoje: `QA:exec=<none>`.
- **M2:** relatório da missão fechado e um `F<n>` `done` sem commit nesse relatório depois dele → projeta
  `QA:exec=<none>`. Hoje: `QA:close=sdd-qa`.
- **M3:** `30-handoff-qa.md` commitado antes de um `F<n>` `done` → o `gate_QA` reprova nomeando o F,
  nos dois caminhos. Hoje passa.
- **M4:** K8 ✅ ou ⏳ no checklist do `00-missao.md` (também com uma linha K8 de exemplo `✗` antes
  da real, duas linhas K8 no checklist, o título do checklist renomeado, um título só parecido com
  o do checklist, como `## Checklist kaizenx`) e nenhuma entrada nova da
  missão no `KAIZEN_LOG.md` (nada, uma
  linha trocada, um cabeçalho renomeado, mais uma linha citando a missão numa entrada antiga, uma
  linha que cita a missão duas vezes partida em duas, uma entrada nova que não cita a missão, uma
  entrada nova que só cita ids mais longos que contêm o da missão, um `## ` dentro de cerca de
  código, uma entrada revertida) → o `gate_DOCS` reprova. Hoje passa.
- **M5:** o prompt de boot de toda fase projetada diz que o carimbo de hora sai de `date` (5 de 5).
  Hoje 0 de 5.
- **M6:** o `check-hat.sh` lê no `/sdd-plan` e no `sdd-planner.md` o aceite renderizado, o
  `--check`/`--red` refeito, a contagem `(recommended)`/`(other: …)`, a reestimativa a 2× e as
  regras de nome do alvo; lê no `sdd-qa.md` a conferência do `qa: skipped` e o `test.fail()`; lê no
  `sdd-docs.md` a leitura do K8. Hoje nenhuma dessas linhas existe.
- **M7 (uso real, próxima janela do juiz, não desta missão):** nenhuma linha `manual` de QA no ledger
  em missão com `qa: skipped`; nenhuma sessão `sdd-qa` chamando a ferramenta `Skill`; nenhum
  `data:` de handoff fora da janela da sessão; a contagem de recomendadas legível por `grep` nos
  `00-missao.md`.
- **M8:** um diretório de missão fora de `^[0-9]{8}-[a-z0-9-]+$` (com `.`, com letra acentuada sob
  um locale em que `[a-z]` a alcança, com prefixo antes da data) → `sdd status` o recusa nomeando a
  gramática; o mesmo id com `/` nas pontas do argumento segue resolvendo. Hoje aceita qualquer nome.

## Resultado esperado

O humano decide no grill que a QA não se aplica, o plano declara `qa: skipped`, e o `sdd run` vai do
TICKET ao PR num lançamento só: o `sdd-qa` confere o diff e escreve `skipped`, ou para a linha com
`blocked`. Depois de um `F<n>` feito, o runner devolve a QA à `qa-execution`, que reteste, e o
`close` reescreve o handoff, porque o gate não aceita um handoff mais velho que o conserto. O aceite
do `/sdd-plan` mostra o plano inteiro, roda `--check`/`--red` na hora e conta as recomendadas antes
do YES/NO. Toda fase carimba a hora pelo relógio, e a DOCS não marca `n/a` uma entrada que o plano
prometeu.

## Fora de escopo

- **(e) a regra 2 do `check-checkpoint.sh` por célula:** vai ao `TODO.md` neste PR de docs (catraca
  2 → 3). A forma canônica separa `2>&1` e `grep` por `;`, então uma regra por segmento ficaria cega
  nela, e o conserto pede seguir a variável (D1).
- **O `WIDTH_CAP` e o histórico do e2e no `GATE_WHY`:** já estão no `TODO.md`, pelo commit do veredito.
- **Encolher o grill** (o planner decidir sozinho o técnico): recusado nesta missão (D8). Primeiro se
  mede, pelo `(recommended)`/`(other: …)`.
- **Uma chave de config para o modelo de aprovação** e um gate que recuse `auto`: recusados (D4).
- **O C10 do caderno** (pendência de operador num handoff `done` não para a linha), o **C7**
  (`RESOLVED by` sob squash) e um sensor de nomes no `TEST_CMD` do alvo: não estão na fila deste
  lote; o último é do alvo, não do kit.
- **Baixar o modelo do `QA:close`** para o `skipped`: sem medida de custo além das duas sessões de
  2026-09-24.

## Gate PLAN-AUTO

Preenchido pelo `sdd-planner` **com evidência**. `aprovacao` fica vazio de qualquer forma: plano
nascido do kaizen nunca é `auto`, e o D4 manda o humano ler e aprovar.

| # | Critério | Status | Evidência |
|---|---|---|---|
| a | Grill sem perguntas abertas não endereçadas (🚩 vazia ou itens deferidos com dono) | ✅ | 18 perguntas, 18 respostas do humano (D1–D18; da 13ª à 16ª vieram da 2ª à 5ª rodada dos bots do PR #247, a 17ª e a 18ª da 7ª), mais a confirmação do "nos dois caminhos" da D3; a 6ª rodada refinou a D16 sem pergunta nova (o conserto cabe no contrato decidido, ver a D16); nenhuma pendente |
| b | Checklist kaizen 100% ✅ e checklist DDD 100% ✅ ou `n/a` justificado | ✅ | seções abaixo; DDD `n/a` justificado |
| c | Plano passa no teste de autocontenção (sessão nova só com 00/01/checkpoint executa) | ✅ | real, em 2026-10-12 21:01–21:12: um subagente novo, lendo só os três arquivos, executou o I1 inteiro num clone descartável (Check `1 1`, os dois mutantes pegos por `--only`, `--anchors` 689); os três "só se souber X" que ele achou (a sintaxe do `--only`, o formato e o commit da nota, a âncora do `TODO.md` que o I1 já move) estão escritos no `01-plano.md` |
| d | Todo incremento do `checkpoint.md` tem Check executável (comando → esperado), vermelho no HEAD pelo `tests/check-checkpoint.sh --red` do kit | ✅ | 12 de 12; `--check` e `--red` rodados nesta sessão, saída final no `01-plano.md` § Medição do vermelho |
| e | `versao:` confirmada pelo humano (ou `JIRA_ENABLED=false`) | ✅ | `JIRA_ENABLED=false` (`.sdd/config.sh`) |
| f | `adr:` é uma decisão — um caminho, ou o literal `none` (alocado por `sdd adr new`) | ✅ | `docs/adr/0018-the-qa-route-and-the-read-plan.md`, alocada por `./bin/sdd adr new` nesta sessão e com o corpo escrito (D9); `./bin/sdd adr check --mission 20261012-a-rota-da-qa --phase plan` → rc 0 |

## Checklist kaizen (`kaizen-software`)

| # | Item | Status | Nota |
|---|---|---|---|
| K1 | Gemba — fui ver onde o trabalho acontece | ✅ | `qa_substep`, `gate_QA`, `gate_DOCS`, `turn_rule` e os sensores lidos com `arquivo:linha`; `pipeline.log`, handoffs e ledger do alvo; a condição de descendência prototipada num repo descartável (git 2.43.0); as duas posições do `RESOLVED by` medidas no `check-todo.sh` |
| K2 | Problema declarado com métrica | ✅ | 3 de 5 missões com QA à mão; 5 retestes improvisados; dois carimbos errados em até 5 h; M1–M7 |
| K3 | Desperdícios identificados e cortados | ✅ | o segundo lançamento por missão sem QA; a sessão de caminhada paga para chegar ao `skipped`; o reteste que depende de uma flag de terceiro; a entrada do `KAIZEN_LOG` escrita à mão depois do PR |
| K4 | Fatiamento incremental, cada fatia verificável | ✅ | 12 incrementos, cada um com uma regra e o seu sensor |
| K5 | Check por artefato (rótulo ≠ artefato) | ✅ | todo Check lê linhas `^  ok    ` de `check-dry-run.sh`, `check-gates.sh`, `check-hat.sh` ou `check-templates.sh`, menos o do I10 (presença no template) e o do I12 (registro) |
| K6 | Jidoka — o que para a linha está definido | ✅ | `qa: skipped` com diff visível → `blocked` (`handoff-blocked`); handoff mais velho que o F → `gate_QA` reprova; reteste que não muda nada → `no_work_check` forma (a); K8 ✅/⏳ sem entrada → `gate_DOCS` reprova; id de missão fora da gramática → todo comando recusa |
| K7 | SDCA — a melhoria vira padrão (doc/rule/teste) | ✅ | asserções novas em quatro sensores, mutantes no catálogo, ADR 0018, `docs/pipeline.md`, `CONTEXT.md`, anatomia |
| K8 | Registro no KAIZEN_LOG | ✅ | o I12 escreve a entrada `Lote 7: a rota da QA e o aceite que lê o plano`; antes = o veredito ao lado, depois = M1–M6 e M8 medidos |

## Checklist DDD (`ddd`) — condicional

`n/a — sem toque de domínio: muda o roteamento de uma fase do runner, uma âncora de dois gates, uma frase do boot e a prosa de quatro chapéus; nenhum modelo de domínio.`

## Decisões do grill (não re-litigar)

> Cada decisão leva `(recommended)` quando o humano escolheu a opção marcada como recomendada, e
> `(other: …)` quando escolheu outra. É o dado da D8, e o aceite mostra a contagem.

1. **D1 — escopo: o lote inteiro** (recommended). Núcleo QA (`skipped`, reteste, (d), (f)) + aceite e
   relay do `/sdd-plan` ((a), (b), (h), (i), (g) e o plano renderizado) + (j) + (k) + (c). O (e) vai
   ao `TODO.md`. Porquê: uma janela do juiz mede o lote, um carimbo o cobre, e a fila espera desde o L0.
2. **D2 — quem decide o `skipped` com interface: o plano declara, o `sdd-qa` confere** (recommended).
   `qa: skipped` literal no frontmatter do `00-missao.md`; o `qa_substep` devolve `close`; o `sdd-qa`
   compara com o diff e escreve `skipped` ou `blocked`. Com `blocked`, o remédio é tirar a chave **e
   apagar o handoff bloqueado** (achado do Codex no PR #247: só tirar a chave paga mais duas sessões
   e duas escaladas antes do `close`). Porquê: um lançamento, ~US$ 1,6, e o único
   olhar independente do chapéu que escreveu o código. Qualquer outra grafia é a rota de hoje
   (frouxidão pularia QA de verdade).
3. **D3 — a rota do reteste: `exec` no runner e o frescor do handoff, nos dois caminhos**
   (recommended; "nos dois caminhos" confirmado numa segunda pergunta do relay). Porquê: o reteste
   deixa de depender da flag da skill, e o handoff que vai ao PR diz a verdade; custa uma sessão
   `sdd-qa` a mais por ciclo F.
4. **D4 — sob `/sdd-plan` o humano sempre lê e aprova** (recommended). O planner só escreve `auto`
   quando o humano pede no grill; o aceite renderiza o plano no formato superpowers e pergunta
   YES/NO nomeando os ✗ ou "todos ✅"; o aviso final proíbe prosa no campo. Porquê: vira contrato o
   que o humano fez em cinco missões por instrução do relay.
5. **D5 — (h), (i) e (g) como prosa** no `commands/sdd-plan.md` e no `agents/sdd-planner.md`
   (recommended). Porquê: é o passo que pegou o (h) no L4, virado regra escrita; o `commands/` fica
   fora da chave do carimbo.
6. **D6 — o carimbo de hora: uma frase no `turn_rule` do `boot_prompt`, para toda fase**
   (recommended). Porquê: é o lugar que a anatomia §1 dá à regra de toda fase, e chega aos sete
   chapéus de uma vez.
7. **D7 — o K8 contra a DOCS: uma âncora nova no `gate_DOCS`, mais a prosa** (recommended; o que a
   âncora lê foi refinado pela D13). Com K8 ✅,
   a branch da missão tem de ter tocado o `KAIZEN_LOG.md`, quem quer que tenha escrito a entrada.
   Porquê: o gate lê dois artefatos, e o dono (`sdd-docs`, que tem o arquivo no `writes:`) existe.
8. **D8 — o D4 fica, o grill não muda neste lote, e passa a se medir** (recommended). Cada decisão
   leva `(recommended)` ou `(other: …)`, e o aceite mostra a contagem. Hoje são 18 de 18 nesta missão
   (D1–D18). Porquê, na amostra que havia quando a D8 foi decidida: 16 de 16 é compatível
   com recomendação boa e com ancoragem, e só o dado separa as duas. ⚠️ O texto aprovado dizia
   `(recomendada)`/`(outra: …)`; os tokens viraram inglês porque marcador é contrato (`CLAUDE.md`,
   "o contrato é sempre inglês") e porque `outra` é stopword do `tests/check-lang.sh`, que reprovaria
   o `sdd-planner.md` e o `/sdd-plan` (superfície inglesa). Confirmado pelo humano na D12.
9. **D9 — uma ADR do lote, a 0018,** com §1 D2, §2 D3 e §3 D4/D8 (recommended). Porquê: o precedente
   dos lotes 4 e 5.
10. **D10 — a branch: o precedente** (recommended). Este PR de docs sai da `kaizen/20261012`, com
    veredito, plano, ADR e `TODO.md`; depois do merge, `fix/lote-7-a-rota-da-qa` num worktree novo
    cortado da `origin/main`, com o `sdd approve` e a execução interativa lá. Porquê: o veredito
    descongela o kit sem esperar a execução, e o PR de código não mistura julgamento com código.
11. **D11 — o kit congela no merge do lote 7** (recommended). Nada em `bin agents templates config`
    até o veredito; a janela abre no primeiro carimbo de alvo depois do merge; o `sdd kaizen` roda de
    um worktree ligado (ADR 0017); o I12 escreve o congelamento na gaveta (F3) e no verbete Janela de
    medição do `CONTEXT.md`. Porquê: a próxima janela julga este lote, e o caderno do worker precisa
    de dados de uma versão só (C1: "o worker precisa de um kit fixo").
12. **D12 — os tokens da D8 em inglês: `(recommended)`/`(other: …)`** (recommended). Porquê: marcador
    é contrato, e o contrato é inglês; nenhuma exceção nova no `check-lang.sh`.
13. **D13 — a âncora do K8 lê o saldo da branch** (recommended; o que conta no saldo foi refinado pela D14). Com K8 ✅, o `git diff --numstat`
    de cada merge-base de HEAD com as bases até HEAD tem de acrescentar linhas ao `KAIZEN_LOG.md`;
    uma entrada escrita e depois revertida ou apagada reprova (4ª asserção e um 2º mutante). Refina
    a D7, que lia "tocou o arquivo". Porquê: fecha o caso do Codex (PR #247, 2ª rodada) sem contrato
    novo; resíduo declarado, uma edição alheia que acrescenta linhas passa. Recusados: um marcador
    com o título da entrada na nota do K8 (contrato novo, e missão em voo reprovaria) e manter o toque
    declarando o limite (fail-open, que a régua de admissão do `CLAUDE.md` não admite como limite).
14. **D14 — no saldo, a entrada é um cabeçalho `## ` acrescentado** (recommended; substituída pela
    D15). O diff de cada
    merge-base até HEAD tem de ter uma linha `+## ` no `KAIZEN_LOG.md`: a troca de uma linha (`1 1`)
    e o revert reprovam; entrada nova com faxina passa (5ª asserção e um 3º mutante). Porquê: lê a
    estrutura do artefato (o kit e o alvo abrem cada entrada com `## YYYY-MM-DD — <título>`) e não
    pune a faxina. Recusado: adições menos remoções > 0 (CodeRabbit, PR #247), que deixaria sem saída
    honesta a missão que escreve a entrada e enxuga o log. Resíduos declarados: renomear um cabeçalho
    antigo passa; um log cujas entradas não abrem com `## ` reprova até o humano decidir.
15. **D15 — a identidade da entrada é o id da missão, contado** (recommended; a contagem foi amarrada
    ao bloco da entrada pela D16). Com K8 ✅, as linhas
    do `KAIZEN_LOG.md` que citam `$MISSION` têm de crescer de cada merge-base até HEAD; o `sdd-docs`
    cumpre citando a missão no corpo da entrada. Refina a D13 e a D14: o saldo continua, e o que se
    conta nele deixa de ser linha ou cabeçalho e passa a ser a citação da missão. **Por que o laço
    parou aqui:** três rodadas seguidas do PR #247 acharam um defeito na mesma âncora, cada conserto
    abrindo o seguinte (tocou → saldo de linhas → cabeçalho acrescentado → renome). A regra do
    `CLAUDE.md` ("a revisão é laço") manda, na segunda vez, perguntar que estado falta: era a
    identidade da entrada, que nenhum diff sabe sem saber qual entrada procura. Contar, e não
    "ausente na base", porque a base desta missão, e de toda missão nascida do kaizen, já cita a
    missão (a entrada do veredito). Recusados: o título na nota do K8 (contrato novo, missão em voo
    reprova até editarem o plano) e contar cabeçalhos (outro remendo sem identidade). Resíduos
    declarados: citar a missão numa entrada antiga passa; apagar uma citação antiga da mesma missão
    e escrever a entrada com uma só reprova (raro, falha fechada).
16. **D16 — a entrada é um bloco: título `## ` novo e linha citando a missão nova, no mesmo bloco**
    (recommended). Com K8 ✅, o diff de **cada** merge-base até HEAD no `KAIZEN_LOG.md`, lido com
    contexto inteiro, tem de ter um bloco (de um `## ` fora de cerca de código ao seguinte) cujo
    título é linha **acrescentada** e que tem uma linha **acrescentada** citando `$MISSION`. Amarra
    a D14 (a unidade, o título) e a D15 (a identidade, o id) ao mesmo bloco: cada uma media metade
    da entrada, e o Codex (PR #247, 5ª rodada) mostrou o furo da metade da D15 — mais uma linha
    citando a missão na entrada antiga do veredito, ou uma linha com duas citações partida em duas,
    faziam a conta crescer sem entrada nova. Porquê: medido num repo descartável, reprova os sete
    mundos negativos (os dois do Codex, a entrada nova sem citação com uma citação somada a uma
    entrada antiga, e um `## ` dentro de cerca, além de nada, troca de linha e renome), passa os
    cinco honestos (entrada nova, entrada com faxina, citação só no título, linha de citação igual
    a uma antiga, entrada escrita por cima de um `## ` antigo apagado), e cada um dos sete mutantes
    muda a fase só nos mundos que lhe cabem. O resíduo — renomear um `## `
    antigo e acrescentar uma citação embaixo dele passa — deixou de ser fail-open: o mundo honesto
    gêmeo (apagar a entrada velha e escrever uma nova que reaproveita o texto, construído à parte)
    deixa o `KAIZEN_LOG.md` **idêntico byte a byte** sobre a mesma base, e ele tem de passar (a
    recusa da D14 à regra que punia a faxina). Nenhum leitor de base e HEAD separa os dois.
    Recusados: um marcador `<!-- sdd:kaizen <missão> -->` escrito pelo `sdd-docs` (rótulo que o
    modelo escreve, e escrevê-lo numa entrada antiga passa num mundo que se distingue, sem título
    novo: fail-open de novo) e manter a D15 mandando os mundos ao `TODO.md` (o lote sairia com um
    gate sabidamente frouxo). Preço: volta a exigir entradas abertas por `## ` (o kit e o
    `sales_quote` as abrem assim; um log de outro formato reprova até o humano decidir, e o motivo
    diz isso), e o I9 vai a treze asserções e onze mutantes (onze e sete antes da 6ª rodada; vinte e
    dezessete com a D18 refinada na 8ª).
    **Refinada na 6ª rodada** (Codex, PR #247, `a85e6ff`), sem pergunta nova ao humano: "citar a
    missão" é citar o id **inteiro**, com o byte antes e o depois fora de `[A-Za-z0-9_-]`. A citação
    era substring desde a D15 (`grep -cF`), e a D16 a herdou (`index`): uma entrada nova citando só
    `<id>-extra` passava. Não houve pergunta porque não sobrou escolha dentro do decidido: exigir o
    caminho do handoff trocaria o contrato da D15/D16 (citar o id) e, sem a `/` final, tem o mesmo
    furo; "as duas" é a fronteira, porque o caminho já passa por ela. Medido no protótipo: os treze
    mundos da D16 dão a mesma fase, cinco mundos de colisão passam a reprovar, oito formas honestas
    de citar continuam passando, e cada sabotagem da fronteira muda a fase de um mundo do fixture
    (detalhe no I9). Não é o laço da D13–D16: aquelas rodadas mediam **qual é a entrada**; esta mede
    **o que é citar o id**, eixo que a D15 abriu sem fronteira.
17. **D17 — a gramática do id da missão vira fato do runner: o `resolve_mission` recusa um id fora de
    `^[0-9]{8}-[a-z0-9-]+$`, e o planner e o `/sdd-plan` passam a dizer a gramática** (recommended).
    Um incremento novo, o I11 (o fecho vira I12). Porquê: o CodeRabbit (PR #247, 7ª rodada, sobre o
    resíduo que a D16 refinada declarou) mostrou que a fronteira do `cites_id` só é exata para um id
    sem `.` e sem letra acentuada, e isso era convenção: a missão `foo` era satisfeita por
    `` `foo.bar` `` e `` `fooé` `` (medido). O `resolve_mission` é a única porta por onde todo
    `MISSION` passa, inclusive o `--phase` forçado, que pula o `gate_PLAN`. Medido: 64 de 64 ids reais
    e os 19 ids que os testes passam à CLI cabem. A classe é enumerada, porque sob `pt_BR.UTF-8` o
    `=~` do bash faz `[a-z]` casar `é`, e a checagem lê o id sem as barras do argumento, porque o
    `/<missão>` sustenta o `RUN_branch_double_slash`. Amplia o D1 com uma regra de runner fora do K8.
    Recusados: a recusa no `gate_PLAN` (o `--phase` forçado a pula) e manter o resíduo declarado com
    a gramática no `TODO.md` (o lote sairia com uma falha aberta conhecida). Preço: o kit é público, e
    um id fora da gramática noutra máquina para em todo comando, com o motivo nomeando a gramática.
18. **D18 — o leitor do status K8: votam as linhas K8 da seção `## Checklist kaizen`, fora de cerca,
    e um `✅` ou `⏳` basta para cobrar a entrada; se a seção não tiver K8, vota o arquivo**
    (recommended). Refina a D7, que cobrava "com K8 ✅" pela primeira linha K8 do arquivo. Porquê: o
    Codex (PR #247, 7ª rodada) mostrou que um exemplo `| K8 | … | ✗ |` antes do checklist real
    escondia o `✅`. Medido em 15 mundos: o leitor de antes falha aberto em 5 (um deles o `⏳`) e
    fechado em 4; este é exato nos 15. O pedido literal do Codex (a primeira linha da seção, e recusar a ambiguidade)
    ainda falhava aberto em 3 mundos, e recusar seria um gate que o `sdd-docs`, dono da entrada, não
    satisfaz (ele não escreve o `00-missao.md`); no voto, a ambiguidade cai do lado que o dono
    consegue satisfazer. O `⏳` entra porque 3 das 59 missões reais com K8 o escrevem com a nota
    "Fase DOCS", exatamente a promessa que a âncora existe para cobrar, e duas delas não têm a
    entrada citando o id. Recusados: todo K8 do arquivo votando sem estado de seção (cobra uma entrada
    não prometida quando um exemplo `✅` precede o `✗` real) e o `✅` sozinho (deixa o `⏳` sem
    cobrança). O I9 vai a dezenove asserções e dezesseis mutantes.
    **Refinada na 8ª rodada** (CodeRabbit, PR #247, `a3d7b90`), sem pergunta nova ao humano: a seção
    é a do título `## Checklist kaizen` seguido de espaço ou fim de linha. O teste do título casava
    também `## Checklist kaizenx`, e uma seção quase igual com um `✗` calava o voto do arquivo, um
    passo aquém do que a D18 decidiu ("a seção `## Checklist kaizen`"). Não houve pergunta porque o
    conserto só alcança a decisão já tomada. Medido no `mawk` 1.3.4: o título do template, o nu, o
    com `\r` e o com tab abrem a seção; `kaizenx` e `kaizen-software` não. Em 16 mundos de status, o
    leitor de antes falha aberto em 6 e fechado em 4, e este é exato nos 16. O I9 vai a vinte
    asserções e dezessete mutantes.
    **A revisão é laço, e aqui a pergunta foi que estado faltava.** A âncora tem três entradas: a
    promessa do plano, a entrada do log e o id. Da 2ª à 6ª rodada só a entrada ganhou estrutura (o
    bloco da D16); a promessa era a primeira linha K8 do arquivo e o id era convenção, as duas regra
    sobre texto cru. A D17 e a D18 dão estrutura às duas que faltavam: o id é uma gramática que o
    runner confere, e a promessa é a linha lida na seção do checklist.

## Pendências para o humano

- **O PR de docs** (D10): da `kaizen/20261012`, com o `05-verdict.md`, estes quatro artefatos, a ADR
  0018 (`proposed`), o `TODO.md` e a catraca (`todo-findings 3`). No mesmo PR, a linha F3 da gaveta
  (`docs/superpowers/specs/2026-09-23-a-gaveta-do-kit.md`) registra a janela do lote 6 fechada pelo
  veredito: frente que fecha atualiza o índice no mesmo commit (`CLAUDE.md`).
- **Depois do merge:** `git fetch`, `git worktree add ../sdd_agents-lote-7 -b fix/lote-7-a-rota-da-qa
  origin/main`, e de lá `sdd approve 20261012-a-rota-da-qa` e a execução interativa, incremento por
  incremento. O `sdd approve` faz checkout da `branch:` e a cria a partir da atual quando não existe.
- **Carimbo de mutação:** `./bin/sdd health` uma vez, no worktree, depois do último commit de código
  **e** da rodada de todos os bots do PR (ADR 0015 §1). São 687 mutantes hoje e 715 depois dos vinte e oito
  deste lote (689 medidos depois do I1 no teste de autocontenção): ~40 a 60 min.
- **Yokoten nos alvos:** mudam `agents/sdd-qa.md`, `sdd-planner.md` e `sdd-docs.md`. No
  `sales_quote`, `sdd install --force` numa branch `chore/kit-<sha>` e PR para a `develop`; os alvos
  com symlink seguem sozinhos.
- **O congelamento (D11):** no merge do PR de código deste lote. Até o veredito, nada em
  `bin agents templates config`; o achado de kit que nascer nos alvos vai ao handoff (`kit:`) e espera.
- **O caderno de campo do worker** (PR #246): anotar que, sob o `/sdd-plan`, o humano escolheu a
  recomendada em toda pergunta com opção marcada: 8 de 8 no grill do L4 e 18 de 18 nesta missão
  (D1–D18, da 13ª à 18ª nas rodadas de revisão do PR #247), e que daqui em diante a contagem sai do
  `00-missao.md`.
- **Remover o worktree** depois do merge, pelo verbete "`sdd health` in the main checkout is slow
  again after a kit mission" de `docs/failure-modes.md`.
