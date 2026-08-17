# KAIZEN_LOG — `sdd_agents`

Registro de melhorias com **antes/depois medido**. Sem número, não entra.

---

## 2026-08-17 — O juiz para de parecer quebrado quando o kit é o próprio alvo (missão `20260817-eixo-do-juiz`)

**Problema (Gemba):** o `sdd kaizen` julga a mudança anterior do kit e dá à luz a missão seguinte.
O julgamento estava **morto na água**, medido no ledger real em 2026-08-16:

```
latest    kit_sha 818b800 · 1 sessão · fase PR   · US$ 1,48
previous  kit_sha 4126b50 · 1 sessão · fase DOCS · US$ 7,31
guard     missions_after_change 1 · sessions 1 · sufficient false
```

`latest` e `previous` eram **a mesma missão**, duas fases consecutivas. Comparar isso não media kit
nenhum: media que publicar é mais barato que documentar. A causa é estrutural, não um bug —
`autonomy_kit_stamp` carimba `kit_sha` = `HEAD` do kit no instante de cada linha, e a fase EXEC
commita no `bin/sdd` **entre** sessões: 24 shas distintos no ledger, todos com exatamente 1 sessão,
nenhum com 2. E o humano lia só `sufficient: false`, indistinguível de "faltam missões" — a leitura
que convida a afrouxar o piso. Mais três defeitos adjacentes na mesma vizinhança: `--all-repos` não
existia (o ledger é global **para** comparar projetos e nenhum leitor conseguia mais), worktree
partia a identidade do repo (`--show-toplevel` é por worktree, e o kit recomenda worktree), e linha
sem `repo` contava como local em **todo** repo — 3 delas bastavam para virar `sufficient: true`
sobre o nada.

**Contramedida:** um ADR **primeiro** (0003: evidência de veredito vem de repo-alvo real; o eixo não
muda; o piso `>= 3` não afrouxa) e quatro incrementos que fazem o runner **dizer** isso —
`guard.degenerate_axis` citando o ADR na saída, `--all-repos` explícito ligando o predicado único
que os três leitores compartilham, identidade de repo derivada do `.git` **comum** no escritor e nos
leitores, e `excluded.no_repo` como quinto balde. A régua não foi tocada em ponto nenhum: a resposta
ao "a série nunca enche" foi explicar, não baixar o piso.

| | Antes (`96a9bf1` = `main`) | Depois (`5056709`) |
|---|---|---|
| `sufficient: false` no repo do kit | número pelado — "faltam missões" e "este eixo não funciona aqui" liam igual | **`degenerate_axis: true`** + frase impressa citando **ADR 0003** |
| Pergunta entre projetos (a razão de o ledger ser global) | **inacessível** — nenhum dos três leitores | `--all-repos` nos dois comandos, um predicado; `other_repo` **11 → 0**, 57 linhas → 68 |
| Missão rodada em `git worktree add` | `repo` por worktree ⇒ série **vazia** no checkout principal, em silêncio | worktree do mesmo repo **é** o mesmo repo (escritor e leitores por `ledger_repo_root`) |
| 3 linhas de sessão sem `repo` | `sufficient: true` — a guarda dizendo "já dá para julgar" sobre o nada | `excluded.no_repo: 3`, `sufficient` **permanece** `false` |
| Baldes de `excluded` (nos dois produtores da shape) | 4 | **5** |
| Ledger com uma linha ilegível | `gate_KAIZEN` lia string vazia como "ainda não julgado" e **gastava uma sessão opus** | morre antes da sessão, rc 1, com o remédio nomeado |
| ADRs | 2 | **3** |
| Score de mutação | 55 caught, 0 gap, of 55 | **70 caught, 0 gap, of 70** |
| Asserções de sensor numa passada verde (`grep -c '^  ok    '`) | 435 | **509** |

⚠️ **A linha das asserções não é comparável com a da entrada anterior, e o motivo é o
instrumento.** Aquela entrada registrou **490** para um `main` que é código-idêntico ao desta
(`git diff c821ade..96a9bf1 -- tests/ bin/sdd` é **vazio**: só docs mudaram entre os dois), e este
`main` mede **435**. Não caiu nada: `490` é a contagem de `^  ok`, que soma às asserções de sensor as
**55** linhas `  ok   ` de **três** espaços que o `sdd install` e outros comandos do runner imprimem
dentro dos fixtures. A âncora certa é `^  ok    ` com **quatro** espaços — a mesma que o
`templates/checkpoint.md` e a `CLAUDE.md` obrigam nos Checks, e pelo mesmo motivo: a forma solta
responde "a linha existe", nunca "a asserção passou". Os dois lados desta linha foram medidos com a
âncora de quatro espaços, em passadas sequenciais, `main` num worktree descartável. Fica registrado
em vez de silenciosamente corrigido, e virou item do `TODO.md`: uma linha do `KAIZEN_LOG` cujo
instrumento não está fixado é a "número que se move sem nada explicando por quê" que este arquivo
cataloga desde a missão do ledger — só que aplicada a ele mesmo. A série 408 → 457 → 490 das entradas
anteriores **não** foi reescrita: recontar tree antigo custa uma suíte por entrada e o degrau já está
nomeado aqui, com o comando que o distingue.

⚠️ **`missions` não subiu no ledger real sob `--all-repos`, e isso não é a flag falhando.** O sha
corrente tem uma missão só — é exatamente o eixo degenerado que o I2 acabara de expor. Quem mede a
subida é o fixture de dois repos do sensor, com as duas saídas comparadas **entre si**. Uma métrica
que só pode ser observada onde o defeito que a missão descreve não está presente precisa dizer isso
em voz alta, ou o próximo leitor conclui que a flag não funciona.

### A métrica planejada dizia 55 → 60; o real foi 70

Um mutante por incremento previa 60. Vieram dez extras, e nenhum é escopo que vazou — são defeitos
que a missão só podia descobrir **depois de existir**, cada um medido no caminho que o achou:

| Origem | O que provaram |
|---|---|
| Os 5 incrementos planejados | o previsto: um por fatia |
| Fix da QA (`c5c9a9f`) | a flag chegava ao gate e **não** ao prompt do juiz: duas séries, dois `latest`, e a fase virava **insatisfazível** — não "número errado". Duas sessões opus compravam uma linha `blocked` |
| REVIEW r2 (`913cb3f`, `d0a3b59`) | a primeira grafia da identidade tomava o **pai** do `.git` e fundia submódulos irmãos e bares vizinhos numa identidade só, em silêncio; e `CDPATH` colapsava **todos** os repos da máquina numa identidade, alcançável por variável de ambiente |
| REVIEW r3 (`3ef0753`, `b03d2f8`) | duas HIGH **dentro do campo que esta missão criou**: a janela contava SESSÕES onde o piso conta MISSÕES (uma retentativa bastava para calar o sensor), e a ordem-de-arquivo da janela **não tinha probe** — `sort` deixava os dois sensores verdes porque toda fixture usava shas cuja ordem lexical coincidia com a de arquivo |

A leitura kaizen é a mesma que a missão anterior registrou e que se confirmou de novo: métrica de
catálogo é **previsão, não meta**. Cravar 60 e parar ali teria transformado dez achados reais em
dívida — dois deles fail-open, e um deles um fail-open sobre a propriedade central do conserto da
rodada **anterior**. O número que vale é `0 known gap(s)`, que se manteve nas dez entradas.

### O conserto trocou a unidade, e cinco documentos ficaram na unidade velha

O achado desta fase DOCS, e o mais barato de repetir: o F1 da r3 trocou a unidade do
`degenerate_axis` de **sessões** para **missões** — porque é `missions_with_session` que o piso
conta, e duas sessões da mesma missão deixavam o piso igualmente insatisfazível enquanto calavam o
campo. O código mudou, com comentário medido. A prosa não: **cinco** dos sete lugares que descrevem
o schema seguiam dizendo "exactly one session" horas depois, incluindo `docs/adr/0003` — o único que
o runner **cita na saída** — e `agents/sdd-kaizen.md`, a folha que o próprio juiz segue.

| | Antes (`5056709`) | Depois (esta fase) |
|---|---|---|
| Lugares que descrevem o schema da série | 6 conhecidos (`docs/failure-modes.md` fora do inventário) | **7**, nomeados no item do `TODO.md` |
| Deles com a unidade certa do `degenerate_axis` | **2 de 7** (`bin/sdd`, `CONTEXT.md` — que não citava unidade) | **7 de 7** |
| Vezes que o item "schema sem sensor de drift" cobrou preço | 5 | **6** |

A r3 fechou em Grade A afirmando "os seis lugares dizem a mesma coisa", e estava de boa-fé: ela
consertou o sexto que a r2 deixara velho. O que nenhuma rodada podia ver é que o **próprio conserto
dela** criou drift novo em cinco — mudar unidade é mudar contrato, e contrato quebrado em N lugares
é o modo de falha mais caro deste kit, escrito na `CLAUDE.md` desde a primeira missão. A conclusão
não é "revisar melhor": é que **este repo não tem sensor de drift entre os campos do `jq` e a prosa
que os promete**, e enquanto não tiver, a conta volta. Sexta cobrança, com âncora e direção no
`TODO.md`.

### O que ficou sabido, e não foi consertado

- **A quinta métrica do `00-missao.md` não foi cumprida, e isso é registro, não omissão.** O plano
  previa 5 itens do `TODO.md` com `RESOLVIDO por <hash>`; são **4**. O quinto — o lembrete
  pós-pipeline que manda o humano a um comando que enxerga números diferentes — **não é fechado por
  `--all-repos`**: o lembrete só é chamado de `cmd_run`, e `sdd run` não tem a flag. Estampá-lo
  seria rótulo sem artefato, exatamente o que o kit existe para proibir. O item segue aberto com o
  motivo escrito nele, e fechá-lo exige responder se o juiz pode pesar linha de outro projeto —
  possível **ADR 0004**, e é ele que destrava o I13.4.
- **Um marcador de fechamento estava invisível para a triagem.** O `RESOLVIDO por` do item do eixo
  degenerado tinha quebra de linha entre as duas palavras, e a triagem do kaizen grepa a frase
  inteira: item fechado que a próxima sessão leria como aberto. Reencapado nesta fase. A lição é a
  de sempre nesta casa — convenção lida por `grep` precisa de sensor, e esta não tem.
- **O `sdd kaizen` recusa rodar de um worktree do próprio kit** pela mesma pergunta por worktree que
  o ledger acabou de deixar de fazer, noutra porta (`bin/sdd:2735`). Está no `TODO.md`, achado pela
  EXEC do I4 — a classe fechada num sítio e viva no vizinho.
- **A `CLAUDE.md` afirma que `grep -l selftest tests/` devolve cinco, e devolve seis.** Já estava
  errado antes desta missão (medido nos dois lados), então virou item em vez de conserto por
  decreto: a contagem é a **evidência** de uma regra sobre rubrica, e evidência errada convida a
  próxima sessão a corrigir para o lado errado.
- **Este arquivo não fixa os instrumentos das próprias linhas**, e a linha das asserções já pagou por
  isso (⚠️ acima). Item aberto com direção: nomear o comando ao lado do número, do jeito que a linha
  do score já faz de graça ao citar `score:`.

**Custo:** 10 sessões, **US$ 105,48** até o fim da REVIEW — 3 rodadas de review (US$ 69,03, 65% do
total) sobre 5 incrementos + 1 fix de QA. O preço das rodadas é o preço de achar duas HIGH e uma
CRITICAL **antes** do merge, num campo que a missão acabara de criar.

---

## 2026-08-17 — As portas entre humano e runner ganham dono (missão `20260816-portas-do-humano`)

**Problema (Gemba):** quatro pontos onde humano e runner se tocam estavam sem instrumento, os
quatro conferidos com `arquivo:linha` antes de virar incremento:

- **aprovar um plano era editar frontmatter à mão.** Destravar o `gate_PLAN` exigia digitar
  `aprovacao: humano-YYYY-MM-DD` no formato exato que o gate grepa — sem ver o que se aprovava, sem
  data automática, sem commit. Convida a errar o formato ou a delegar à sessão, que é justamente
  quem não pode decidir;
- **ninguém lia o campo `branch:`.** Ele só existia no `templates/missao.md`. No piloto SQ-97 isso
  custou cinco fases commitando na branch de outro PR — 16 commits, ~US$ 45 de `rebase --onto` —, e
  o primeiro passo repetiu em 2026-08-16 com o humano trocando de branch à mão;
- **`sdd retry` commitava na base em silêncio.** Era a quarta porta que commita e a única sem
  `warn_if_on_base_branch`;
- **plano nascido do `sdd kaizen` podia se auto-aprovar.** O `gate_PLAN` aceitava `auto` sem olhar
  a origem, e "o laço nunca aprova o próprio plano" vivia só na prosa de dois agentes.

A fase QA achou os dois defeitos que existem **entre** os incrementos, onde nenhum sensor de
incremento podia enxergar: o remédio que o gate novo nomeia (`sdd approve`) lia `auto` como "já
aprovado" e desistia — recusa e remédio formando um laço infinito, nunca "às vezes" —, e o próprio
`sdd approve` nasceu sendo a **quinta** porta que commita, em silêncio, na mesma missão que fechou
o silêncio da quarta.

**Contramedida:** quatro incrementos e dois fixes, todos com **uma definição por regra** onde havia
leitura repetida — `plan_approves_itself()` para o `gate_PLAN` e o `cmd_approve` (o defeito ERA dois
pontos lendo a mesma regra e discordando), `ensure_mission_branch()` para o `cmd_run` e o
`cmd_retry`, `warn_if_on_base_branch` para as cinco portas. `sdd approve` imprime o plano inteiro,
pergunta `[y/N]`, escreve com `frontmatter_write` (só dentro do bloco entre os dois primeiros `---`)
e commita **um** arquivo. Falha de checkout mata alto, com a mensagem do git: adivinhar por cima de
uma árvore que o git recusou é como se perde o trabalho de outra pessoa.

| | Antes (`c2c8e73` = `main`) | Depois (`c821ade`) |
|---|---|---|
| Aprovar um plano | editar o frontmatter à mão, no formato que o gate grepa | **`sdd approve <missão>`** — imprime, pergunta `[y/N]`, escreve `humano-<data>`, commita 1 arquivo |
| Campo `branch:` do plano | decorativo: nenhuma linha do runner o lia | **lido antes do primeiro gate** de `sdd run` e `sdd retry` — checkout, ou `-b` a partir da atual |
| Portas que commitam avisando a branch base | 3 de 4 | **5 de 5** |
| `aprovacao: auto` em plano kaizen-born | aceito pelo gate | **recusado**, nomeando `sdd approve` como saída |
| Score de mutação | 44 caught, 0 gap, of 44 | **55 caught, 0 gap, of 55** |
| Asserções `ok` numa passada verde | 457 | **490** |
| Suíte, mesma máquina, duas passadas por lado | 1:45,74 / 1:47,49 | **2:27,10 / 2:27,59** (+39%) |
| Os 4 itens da métrica no `TODO.md` | abertos | **RESOLVIDO por** `96a1f68`, `b3b8c2f`, `3ffa586`, `2510c3c` |

Os tempos foram medidos nesta máquina, `main` num worktree descartável contra o HEAD noutro, os
quatro **em sequência e sem nada mais rodando**, suíte verde nos quatro. O **+39% é catálogo, não
desperdício** — 11 mutantes novos são 11 suítes inteiras a mais —, mas o alvo `<30 s` da D7 está
agora **4,9× distante**: a decisão de subir o alvo ou aposentá-lo por escrito segue no `TODO.md`, e
a pergunta aberta do `CONTEXT.md` recebeu a terceira medição consecutiva que a confirma.

⚠️ **A primeira tentativa desta medição produziu números inventados, e o sintoma foi ela discordar
de si mesma.** Rodadas feitas enquanto outra suíte rodava deram `main` 3:12,87 e HEAD 4:18,70 — e
uma terceira, do MESMO HEAD, 2:25,87: mais rápida que o "antes", o que é impossível se o número
mede o que diz medir. Duas suítes concorrentes, cada uma com pool de 8, disputando a mesma máquina
(`load average` 24). Refeitas em sequência, as duas passadas de cada lado ficam dentro de 2 s uma
da outra, e o `main` bate em **1:45,74** contra os **1:45,17** que a missão anterior registrou para
o mesmo commit — é essa reprodutibilidade, não a plausibilidade do número, que separa medição de
palpite. Tempo de relógio medido sob carga alheia não é medição: é a mesma classe do "vermelho pelo
motivo errado" que este arquivo cataloga desde a missão do ledger.

### A métrica planejada dizia 44 → 48; o real foi 44 → 55

O plano previu **um mutante por incremento**. Vieram onze, e os sete extras não são escopo que
vazou — são defeitos que a missão só podia descobrir depois de existir, cada um medido no caminho
que o achou:

| Origem | Mutantes | O que provaram |
|---|---|---|
| Os 4 incrementos planejados | `RUN_approve_writes_auto`, `RUN_branch_switch_dead`, `RETRY_base_branch_warn_dead`, `PLAN_kaizen_born_blind` | o previsto: um por fatia |
| Fixes da QA (`5c3d118`, `88ae514`) | `RUN_approve_bails_on_kaizen_born`, `APPROVE_base_branch_warn_dead` | os dois defeitos **entre** incrementos |
| Rodada de REVIEW em voo (`1cc6c34`) | `RUN_branch_option_name`, `PLAN_remedy_unnamed` | o gate que não nomeia o remédio, e o nome de branch parecendo opção |
| Resgate da árvore suja (`7f9e660`) | `RUN_branch_orphan_blind` | cinco asserções de branch concordando sobre uma propriedade que nenhuma podia ver |
| Fecho da REVIEW r1 (`ad0c89d`) | `RUN_branch_order_swap`, `FRONTMATTER_write_unscoped` | dois **fail-open**: a suíte inteira verde com o defeito dentro |

A leitura kaizen: uma métrica de catálogo é previsão, não meta. Cravar 48 e parar ali teria
transformado sete achados reais em dívida — e dois deles eram fail-open, o modo em que um
instrumento afirma ter medido o que não mediu. O número que vale é `0 known gap(s)`, que se manteve
em todas as onze entradas.

### O que ficou sabido, e não foi consertado

A métrica do `00-missao.md` diz "a classe SQ-97 morre" sem ressalva, e a ressalva é real: com
`JIRA_ENABLED=true` a branch nasce na fase TICKET e mora no `10-ticket.md`, que ninguém copia para
o campo que o runner lê. A classe morre **no caminho sem JIRA** — o único que esta missão andou.
Está no `TODO.md` com direção, no glossário do `CONTEXT.md` e na seção nova do `docs/pipeline.md`:
registrado em três lugares em vez de corrigido por decreto num.

## 2026-08-16 — Quatro instrumentos param de afirmar o que nunca mediram (missão `20260816-kit-como-alvo`)

**Problema (Gemba):** o kit foi desenhado para rodar em repo-alvo e passou a rodar em si mesmo.
Nesse regime — e **só** nele — quatro instrumentos afirmavam ter medido algo que nunca mediram, os
quatro verificados com âncora e comando antes de virar incremento:

- o ledger é global e **nenhum** dos três leitores filtrava por repo, com o campo `repo` já escrito
  e ninguém lendo: um `sdd run` de fixture com sandbox em `/tmp` pôs 3 linhas no ledger de produção
  e o juiz passou a ler `66% waste · 2 mission(s)` onde o verdadeiro era `0% · 1` — a **fonte da
  verdade do juiz**, contaminável por qualquer teste;
- o preflight comparava a **existência** do agente instalado e então imprimia `N kit agent(s)
  checked` por cima — rótulo sobre uma comparação que nunca aconteceu, e o harness carrega a cópia;
- `main "$@"` era a última linha sem guarda, num runner cuja fase EXEC o edita **em voo** (10× na
  missão anterior). Reproduzido: edição in-place faz o bash reexecutar o entry point, com rc `0`;
- o aviso "você está na branch base" morava só no preflight, enquanto `sdd run` e `sdd kaizen`
  abrem sessão que commita — e o kaizen escreve veredito + três artefatos onde você estiver.

A fase QA achou o **quinto** da mesma família, e era o instrumento com que a própria missão se
media: o Check do checkpoint grepava o texto solto da asserção sobre `2>&1`, e `fail()` imprime o
mesmo texto que `pass()` — o comando devolvia `1` com a asserção **vermelha**.

**Contramedida:** quatro consertos dentro do contrato existente, com **predicado único por
programa** onde havia repetição — `ledger_row_is_local()` para os três leitores,
`warn_if_on_base_branch()` para as três portas — e o mutante sabotando a **definição**, nunca uma
chamada: é o que prova que os três passam mesmo por ela (medido: derrubar uma chamada mata um
sensor e deixa os outros verdes). Mais o incremento `F1`, nascido da QA: os Checks ancoram em
`^  ok    `, `templates/checkpoint.md` e o `sdd-planner` ensinam a regra, e `tests/check-checkpoint.sh`
a mede em **todo** checkpoint do repo.

| | Antes (`df18c88` = `main`) | Depois (`bb5333f`) |
|---|---|---|
| Os 4 Checks da métrica | `127` · `0` · `0` · `0` | **`0` · `1` · `1` · `1`** |
| Instrumentos conhecidos que afirmam sem medir | 4 (+1 achado pela QA) | **0** |
| Score de mutação | 40 caught, 0 gap, of 40 | **44 caught, 0 gap, of 44** |
| Sensores da suíte | 10 | **12** (`check-entrypoint.sh`, `check-checkpoint.sh`) |
| Asserções `ok` numa passada verde | 408 | **457** |
| Suíte, mesma máquina e mesma sessão | 1:17,62 | 1:45,17 (**+35%**) |
| Achados no `TODO.md` | 52 | **65** (+13 novos, 4 fechados com hash) |
| `sdd health` | verde | **verde**, 8 gates com mutação |

Os dois tempos foram medidos nesta máquina e nesta sessão, `main` num worktree descartável contra o
HEAD, suíte verde dos dois lados. O **+35% é catálogo, não desperdício** — 4 mutantes novos são 4
suítes inteiras a mais. Mas o alvo `<30 s` da D7 está agora **3,5× distante** e ninguém o defende:
subir o alvo ou aposentá-lo por escrito é decisão do humano, e o item vive no `TODO.md`.

### O sensor criado para caçar fail-open nasceu com três

A lição cara não é nenhum dos quatro consertos — é que `tests/check-entrypoint.sh`, escrito
**nesta** missão exatamente para matar instrumentos que afirmam o que não mediram, passou pela r1
com três fail-open dentro, e todos os três eram a mesma propriedade faltando:

> os probes mediam o **parser**; o caminho de "existe defeito" até "a suíte fica vermelha" não
> tinha probe nenhum.

Medido, não deduzido: com `check_file` sempre devolvendo `0`, o arquivo imprimia cinco
`SENSOR-BROKEN:` na stderr, o `ok` por cima deles e **rc 0** — que é o que `tests/run-all.sh` lê. E
apagar as três chamadas de topo deixava tudo verde sem rodar o diferencial. O conserto foi a
propriedade, não os sintomas: contabilidade de falha com sítio próprio (`harness_selfcheck`) e as
chamadas de topo viradas **lista**, porque lista é o que um probe consegue contar.

| Passada adversarial do sensor novo | r1 | r2 |
|---|---|---|
| Degradações aplicadas | — | 25 |
| Morrem no próprio sensor | — | **20** |
| Fail-open reproduzidos e abertos | 3 | **0** |
| Survivors nomeados no cabeçalho | — | 5 (2 medidos como cobertos pelo catálogo) |

⚠️ E a regra que fecha: **a última linha de um sensor é a linha sobre a qual ele não consegue
asseverar.** Os dois survivors que são fail-open de verdade foram provados pelo catálogo de
mutação **nos dois sentidos** — sensor íntegro `44 caught of 44` rc 0, composição neutralizada
`43 caught` + rc 1 —, nunca por uma esperança escrita no comentário.

**O segundo achado, no `check-checkpoint.sh`:** fixture derivado da regra **afrouxa junto com ela**.
Abrir o âncora de `^  ok    ` para `ok` deixava o selftest verde, porque os probes constroem os
fixtures a partir do próprio valor sob teste. A saída não foi mais um probe e sim uma **testemunha
independente** — `calibrate()`, que deriva o prefixo das linhas `pass()` dos sensores reais e o
compara com o âncora. 44 degradações em 4 rodadas, 4 sobreviventes, os 4 viraram probe.

**Sensores duráveis:** `tests/check-entrypoint.sh` e `tests/check-checkpoint.sh`, permanentes no
`run-all.sh`, mais 4 mutantes no catálogo (`RUN_entrypoint_unguarded`, `RUN_ledger_no_repo_filter`,
`PRE_agent_presence_only`, `RUN_base_branch_warn_dead`), todos sabotando a **definição**. Os quatro
Checks foram observados vermelhos no `df18c88` antes de qualquer implementação — `127`/`0`/`0`/`0`.

**Padronizado em** (confirmado abrindo cada arquivo): `docs/pipeline.md` (§ "The autonomy ledger"
ganha "the file is global; the READING is per repo" com as três consequências; `repo` vira o campo
que os leitores filtram; `excluded` com os quatro baldes nos dois produtores da mesma shape),
`README.md` (preflight byte a byte; `sdd autonomy` "for THIS repo"), `CLAUDE.md` (doze sensores,
quatro com auto-teste; a regra do âncora `^  ok    `; a passada de sabotagem cobrindo as três
camadas), `templates/checkpoint.md` + `agents/sdd-planner.md` (as duas regras da célula do Check),
`agents/sdd-kaizen.md` (citar `other_repo` como os outros baldes), `CONTEXT.md` (verbetes "Ledger
de autonomia" e "Série", e o novo número do alvo `<30 s`) e `docs/failure-modes.md` (dois modos
novos: agente `stale` no preflight, série vazia por leitura em outro repo).

---

## 2026-08-16 — O kit trabalha no próprio backlog (missão `20260816-runner-sem-dividas`)

**Prova de fogo:** primeira missão em que o `sdd-planner` é exercitado de verdade e o kit anda
sozinho da aprovação do plano ao PR. O alvo era a seção **"Runner — defeitos e dívidas"** do
`TODO.md` — 11 itens acumulados, cada um uma dívida conhecida do `bin/sdd`.

| | Antes (`7045e0f`) | Depois (fecho da REVIEW r2) |
|---|---|---|
| Itens na seção "Runner — defeitos e dívidas" | 11 | **0** — a seção não existe mais |
| Score de mutação | 30 caught, 0 gap, of 30 | **38 caught, 0 gap, of 38** |
| Sensores da suíte | 9 | **10** (`check-pipefail.sh` nasce) |
| Lint | só `bin/sdd` | **`bin/sdd` + `tests/*.sh`** (12 caminhos, piso `LINT_FLOOR`) |
| `SC2318` reais vivos na suíte | 1 (invisível ao lint) | **0** — e o lint agora o veria |
| Log de fase enquanto a sessão roda | **0 bytes por ~10 min** | `.stream.jsonl` vivo, `tail -f`-ável |
| Suíte no default, mesma máquina e sessão | 33,95 s | 44,55 s (**+31%**) |
| `sdd health` | verde nos 5 checks, ratchet 6 | **idêntico** |
| Âncoras `arquivo:linha` erradas no `TODO.md` | 15, em 11 itens | **0** (medido e corrigido na fase DOCS) |

Os dois tempos foram medidos nesta máquina e nesta sessão, `7045e0f` num worktree descartável
contra o `HEAD`, suíte verde dos dois lados. O **+31% é catálogo, não desperdício**: os 8 mutantes
novos são 8 suítes inteiras a mais, e o alvo `<30 s` segue como item próprio em "Custo e escala".
Cortar mutação para recuperar relógio é o que o I13.2 existe para proibir.

### O achado que se repetiu três vezes: o item descrevia o sintoma barato

A lição cara desta missão não é nenhum dos 11 consertos — é que **o texto do achado subestimou o
dano em três dos onze**, e só a asserção escrita para medi-lo revelou o tamanho real:

- **I3 (`sdd install`)** — o item dizia que o defeito era o rótulo `ok` sobre um arquivo vazio. Sob
  `set -e` o `sed` já matava a primeira rodada; o dano real é o `.sdd/config.sh` de **0 byte** que
  sobra, porque o `sdd install` **seguinte** o encontra e imprime `ok … already exists (preserved)`
  com rc 0 — o repo-alvo segue sem `TEST_CMD` e nenhum gate reclama.
- **I9 (giro pós-degradação)** — o item falava em desperdício de voltas. Medido: o run terminava
  escalando `budget-exhausted` na fase **PR**, que nunca esteve acima do orçamento, por um teto que
  REVIEW estourou três voltas antes. Ledger, `sdd autonomy` e o juiz herdavam a **culpa trocada**.
- **I2 (`sort -V`)** — o comentário afirmava que os sites de QA eram indiferentes à ordenação e
  citava como prova uma fixture que exercita **outro glob**. As duas metades eram falsas: entre dois
  relatórios do mesmo dia, `sort` e `sort -V` escolhem arquivos diferentes, e nomear relatório como
  `<data>-<escopo>.md` é o caso ordinário, não o canto.

Regra que sai daí: **o item do `TODO.md` é hipótese, não medição.** Quem for consertá-lo mede o dano
antes de escolher o conserto — três vezes aqui o dano real estava numa camada acima do sintoma
registrado, e duas delas o conserto "óbvio" teria sido um no-op declarado vitorioso.

### O arnês de sabotagem errou três vezes, e sempre para o lado verde

A passada de sabotagem adversarial é a regra da casa, e nesta missão ela cobrou o próprio preço: em
I6, I7 e I10 o **arnês** estava quebrado e produzia vereditos que eram dele, não da sabotagem —
range de `sed` terminado em `/^$/` cortando o relatório do `shellcheck`; sandbox copiando só
`bin`+`tests`, forma em que o `check-autonomy.sh` fica vermelho por conta própria; `/proc/self/fd/1`
resolvendo para o pipe da substituição em vez do arquivo do runner. Nos três casos o sintoma foi o
mesmo — **verde (ou vermelho) pelo motivo errado** — e a correção idêntica: julgar pelo **nome da
asserção que cai**, nunca pelo `rc`, e rodar o controle positivo antes de acreditar em qualquer
morte. É o espelho exato da regra que a casa já tinha para testes, aplicada ao instrumento que mede
os testes.

Duas regras menores confirmadas pelo uso: sabotagem que **não consegue** quebrar uma regra é
detector de duplicata (o I5 e o I10 colapsaram um par cada), e quando o conserto muda o número que a
testemunha anti-vacuidade lê, **a testemunha muda de grandeza, não de constante** (I9).

### Triagem antes de conserto, fechamento por artefato

Dos 11 itens, **1 já estava resolvido** — o do `gate_DOCS`, fechado por `0f50fad`, provado ancestral
de `main` com `git merge-base --is-ancestor` e apagado sem uma linha de código. Os outros 10 foram
re-verificados um a um contra o `HEAD` e **todos seguiam vivos**; nenhum incremento virou no-op. O
plano previa esse risco e ele não se materializou além do primeiro caso.

**Padronizado em** (confirmado abrindo cada arquivo): `CLAUDE.md` § "TDD aqui dentro" (dez sensores,
três com auto-teste; o lint cobre `tests/`), `config/schema.md` (`PUBLISH_ON_REVIEW_BLOCKED` — o PR
draft tem **uma** chance), `docs/pipeline.md` (os dois arquivos de log por sessão; `kind` sem o giro;
`missions_with_session` na lista de campos do grupo **e** na guarda), `docs/failure-modes.md` (como
ler um ledger antigo com `budget-exhausted` em PR; o novo modo de falha do `sdd install` sem
`starter.conf`, com a arqueologia do config de 0 byte), `CONTEXT.md` (verbetes "Degradação" e
"Guarda das 3 missões", e o número do alvo `<30 s`), `agents/sdd-kaizen.md` + a cópia em
`.claude/agents/` (shape do `guard`).

## 2026-08-16 — A mutação para de pagar por barreira e por constante

A suíte inteira roda a cada avaliação de gate (`TEST_CMD`), então cada segundo dela é pago
dezenas de vezes por missão. Dois desperdícios no `tests/check-mutation.sh`, os dois de
escalonamento e nenhum de medição:

1. **`JOBS=4` constante** — a máquina tem 20 núcleos; uma de 2 seria oversubscrita pela mesma
   constante. Agora o default deriva: `min(núcleos, 8)`, piso 1, detecção em cadeia
   (`nproc` → `getconf` → `sysctl` → 4) por comportamento, o padrão do preflight. Env explícito
   vence sempre; lixo no env é recusado por nome (`0` chegava ao `i % JOBS` como divisão por
   zero, `08` estourava a aritmética como octal).
2. **Barreira a cada leva** (`[ i % JOBS -eq 0 ] && wait`) — cada leva custava o mutante mais
   lento dela com os slots já livres parados. Agora é pool (`wait -n`, bash 4.3+, com fallback
   **declarado** para a barreira onde não houver).

| | Antes (`90841cf`) | Depois |
|---|---|---|
| Suíte no default, mediana de 3, mesma sessão | 54,13 s (53,60 / 54,13 / 54,58) | **32,87 s** (32,26 / 32,87 / 32,99) — **−39%** |
| Score | 30 caught, 0 gap, of 30 | **idêntico** (paralelismo mexe no relógio, nunca no veredito) |
| `SDD_MUTATION_JOBS=4` explícito | levas de 4 | **pool de 4** — o override segue mandando |
| Alvo D7 (< 30 s) | estourado (54 s) | **ainda estourado** (32,9 s) — o item no `TODO.md` encolhe, não fecha |

A resolução do JOBS não é alcançável pelo catálogo (mora no harness, não no `bin/sdd`), então
carrega selftest próprio — e a passada de sabotagem adversarial fez o que sempre faz: das 7
sabotagens, 1 sobreviveu **duas vezes**. Primeiro porque o probe só lia o rc, que é compartilhado
entre recusa nomeada e recusa por acidente (`[ abc -ge 1 ]` erra sozinho); exigir o texto do ramo
certo não bastou, porque os **dois** ramos de validação emitiam o mesmo texto — eram redundantes
entre si. A saída foi a que o CLAUDE.md manda: remover a regra redundante, não escrever probe
para ela. A validação virou UMA regra, e as 7 sabotagens morrem.

## 2026-08-16 — O arquivo de achados para de crescer (5S no `TODO.md`)

**Problema medido:** o `TODO.md` chegou a **861 linhas / 75.331 bytes**, e o custo não era só de
leitura humana — o prompt de boot da fase KAIZEN (`bin/sdd:655`) manda a sessão paga de triagem
**ler o arquivo inteiro**. Duas causas, ambas de processo e não de conteúdo. (1) O contrato
mandava o item com `RESOLVIDO por <hash>` descer para "Feito" depois do merge do PR que o cita, e
ninguém executava a descida: **14 itens fechados** ocupavam a seção Aberto, incluindo cinco numa
**segunda convenção de fechamento não documentada** (`- [x]` com `[FEITO em <hash>]` no título) —
invisível para a triagem do kaizen, que procura `RESOLVIDO por` no corpo. (2) O formato prescrevia
uma linha por achado desde sempre; a prática eram corpos de até 31 linhas com análise completa,
reproduções e blocos "Atualização (data)" — profundidade que já existe no handoff que cada item
cita.

| | Antes (`fc304bf`) | Depois (`c5f5beb`, fecho do 5S) |
|---|---|---|
| Linhas / bytes do `TODO.md` | 861 / 75.331 | **362 / 26.566** (−58% / −65%) |
| Itens fechados parados na seção Aberto | 14 | **0** |
| Convenções de fechamento | 2 (uma não documentada) | **1** |
| Mediana / máximo de linhas por item | 10 / 31 | **6 / 8** |
| Itens no arquivo | 64 | **45** (14 resolvidos + 4 de "Feito" apagados, 2 fusões, 1 split) |
| Sensor sustentando a forma | 0 | **1** (`check-todo.sh`, 20 probes de selftest) |
| Suíte no default | 66,02 s | 67,08 s (o sensor custa **23 ms**; o resto é ruído de carga) |

Todas as linhas medidas na mesma máquina e na mesma sessão, `fc304bf` num worktree descartável
contra o `HEAD`, `./tests/run-all.sh` verde nos dois lados (mutação 30/30).

**A causa raiz não era o tamanho, era não haver dono do apagar.** A regra existia — em um lugar
só, um blockquote no meio do próprio arquivo — e dependia de alguém lembrar dela depois de um
merge, que é exatamente o momento em que a atenção está no PR seguinte. Por isso o conserto tem
duas metades, e a segunda é a que importa: a regra mudou de "desce para Feito" para **"é
apagado"** (a memória durável já existe em `git log -S`, `KAIZEN_LOG.md` e nos handoffs, e o item
cita o hash que o fecha), e a **triagem do `sdd-kaizen` virou o gatilho recorrente** — ela já lia
o arquivo corpo a corpo para não replanejar o que está fechado; agora também confere
`git merge-base --is-ancestor <hash> main` e lista os resolvidos a apagar no plano nascido. Sem
gatilho, um sweep manual seria pico isolado; com ele, o arquivo encolhe a cada volta do laço.

**Apagar prova por artefato, nunca por rótulo.** Os 14 hashes foram confirmados ancestrais de
`main` antes de qualquer remoção, e os identificadores ficaram anotados no corpo do commit
`c0193a7` — a rede de segurança mais barata que existe, e que só serve se for escrita antes.

**Padronizado em** (confirmado abrindo cada arquivo): `CLAUDE.md` § princípio 5 (teto de ~6
linhas, fechado é apagado, `- [x]` proibido), `agents/sdd-kaizen.md` § 5 e o espelho
`.claude/agents/sdd-kaizen.md`, `CONTEXT.md` (glossário "Triagem kaizen"), `.claude/napkin.md`
(itens 1 e 5), o cabeçalho do próprio `TODO.md` e o `CLAUDE.md` § "TDD aqui dentro" — onde a lista
de sensores voltou a bater com o disco (5 listados, 9 reais) e a regra do auto-teste passou de
"sensor que se auto-exclui" para "sensor que o catálogo de mutação não alcança", que é a
formulação que cobre os dois casos de hoje.

**O que o sensor ensinou sobre si mesmo.** Duas decisões saíram diferentes do plano, as duas por
medição e não por gosto. A primeira: todas as regras do `check-todo.sh` são **estruturais**
(pontuação, crase, data `(YYYY-MM-DD)`), nunca uma palavra em português — um sensor amarrado a
"descoberto por" quebraria num repo-alvo com `OUTPUT_LANG="en"` e alargaria o buraco de cobertura
que o próprio `TODO.md` registra contra a `surface()` do `check-lang`. Com isso o arquivo novo
**não** precisou de entrada na `lang-allowlist` nem de exclusão da superfície, ao contrário do que
o plano previa. A segunda: o `check-lang` reprovou a primeira versão deste sensor por **duas
citações em português nos meus próprios comentários** — o sensor de idioma pegou o autor do
sensor de forma, que é o laço funcionando.

⚠️ **O alvo de 300 linhas não foi atingido: foram 362 no fecho.** As sete seções `###` custaram
~46 linhas e ficaram porque agrupar por natureza (sensores, contrato, runner, saída humana,
comentário, custo, YAGNI) é o que torna dezenas de itens navegáveis. Registrado como número, não
como sucesso.

⚠️ **Toda linha desta tabela é medida NO COMMIT que o cabeçalho nomeia, não "hoje".** O `TODO.md`
é arquivo vivo: um achado novo entra e o número sobe no mesmo dia — como aconteceu horas depois
deste fecho. Três correções seguidas desta entrada tiveram a mesma causa raiz (medir num commit e
rotular outro), então a âncora agora está no cabeçalho e a prosa fala no passado.

⚠️ **A primeira versão desta tabela trazia "Achados abertos 47 → 46", e os dois números estavam
errados** — corrigidos para 64 → 45 pela revisão de código. Duas causas somadas, e as duas
instrutivas. A primeira: o "antes" foi medido no commit do próprio sweep (`c0193a7`), não no
`fc304bf` que o cabeçalho da tabela promete — baseline errada sob rótulo certo. A segunda: o
contador era um `grep -cE '^- \[[ x]\] '` que conta também o exemplo de formato dentro do bloco
cercado do cabeçalho do `TODO.md`, então inflava **os dois** lados em um. O mesmo `grep` estava no
`check-todo.sh` recém-escrito, ao lado de um parser awk que pula cercas corretamente — dois
mecanismos respondendo à mesma pergunta, que é a família de defeito que este repo já pagou três
vezes (os dois leitores do ledger, as duas definições de comparabilidade, e agora o contador).
Consertado com um parser só em dois modos (`lint`/`count`) e um probe fim-a-fim que reprova se a
contagem reportada divergir da que o parser vê.

**A lição mais cara da sessão: selftest verde prova as regras que têm probe, e só essas.** Depois
de a auto-revisão desta sessão dar Grade A ao sensor, uma leitura **adversarial independente**
achou **17 defeitos** — 2 CRITICAL, 5 HIGH, todos com reprodução. Os dois piores eram da mesma
espécie e a pior que existe num sensor: **falhar aberto**. Um `TODO.md` existente mas ilegível
fazia o `awk` imprimir nada, e contagem vazia num teste numérico é erro de sintaxe do `[` (rc 2)
que, sem `set -e`, cai fora do `if` — o run terminava em `ok 0 finding(s)`, rc 0. E uma única
cerca ``` sem fechamento travava o latch do parser e pulava **todas** as regras até o fim do
arquivo, também verde. Nos dois casos o sensor dizia "medi e está limpo" sobre o que não mediu.

| | Auto | 1ª | 2ª | 3ª | 4ª | 5ª | 6ª | 7ª | 8ª | 9ª | 10ª | 11ª | 12ª |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Defeitos achados | 0 | 17 | 9 | 11 | 11 | 11 | 11 | 10 | 5 | 3 | 5 | 7 | **3** |
| Herdados de rodadas anteriores | — | 17 | 2 | 3 | 5 | 4 | 5 | 5 | 3 | 0 | 1 | 6 | **3** |
| Probes do selftest | 14 | 20 | 30 | 37 | 45 | 49 | 48 | 58 | 63 | 67 | 69 | 75 | **75** |
| Linhas do parser `awk` † | 47 | 62 | 71 | 84 | 107 | 107 | 75 | 82 | 79 | 74 | 126 | 132 | **132** |
| Estado de cerca no parser | sim | sim | sim | sim | sim | sim | não | não | sim | não | não | não | **não** |

Procedência das três colunas novas, porque metade delas é derivada e não medida. **Probes** e
**linhas** saem do commit de cada rodada (`e339baf`, `0552110`; a 12ª não commitou conserto, então
repete a 11ª). **Defeitos** e **herdados** das rodadas 10 e 11 são contados do corpo do commit —
os relatórios daquelas rodadas não foram persistidos, e é por isso que o da 12ª está em
[`docs/handoffs/20260816-todo-enxuto/`](docs/handoffs/20260816-todo-enxuto/r12-caixa-partida.md).

† A linha de tamanho do parser serve à **tendência, não à comparação coluna a coluna**: as colunas
Auto–9ª foram medidas ao longo da sessão e não reproduzem do commit sob nenhuma definição única
(o programa `awk` entre aspas casa a 7ª; o bloco `todo_awk()` inteiro casa a 5ª e a 6ª; as demais,
nenhuma das duas). As colunas 10ª–12ª usam o bloco `todo_awk()` inteiro, que é o número maior — o
salto de 74 para 126 é mudança de régua, não crescimento do parser.

**O número que mais ensina não é nenhum defeito: é que cada rodada achou um defeito criado pela
anterior — três vezes seguidas.** A 1ª consertou a âncora com uma classe negada de travessão, e a
2ª mostrou que sob mawk isso nega *bytes*. A 2ª partiu a regra de cerca em duas, e a 3ª mostrou
que isso criou um latch de mão única. A 3ª acrescentou a regra de sub-item marcado, e a 4ª mostrou
que ela acusava amostras de código — contradizendo o comentário três linhas acima, no mesmo commit.

**A 4ª rodada achou a causa comum das três** — o parser não tinha estado para "dentro do bloco de
código de um item" — e acrescentou esse estado. Fechou quatro defeitos e a 5ª rodada achou mais
quatro **dentro do estado novo**: uma `- [x]` em coluna 0 entre a abertura e o fechamento do bloco
sumia com o run verde, um span inline abria bloco fantasma, e as formas `+ [x]` / `1. [x]` /
indentada seguiam invisíveis.

**O que finalmente quebrou o ciclo foi apagar a feature, não consertá-la.** O estado saiu inteiro:
nenhum dos 46 achados carrega bloco de código e o teto de ~6 linhas não deixa caber, então item
simplesmente **não pode** carregar cerca — uma linha no lugar de uma máquina de estado, falhando
fechado e nomeando a causa raiz. Junto, caixa marcada virou regra **por linha** em vez de por
item, que é o que finalmente cobriu todas as formas que o GitHub renderiza marcadas. O parser
`awk` encolheu para 107 linhas e a família de defeitos foi embora com o estado que a hospedava.

**A 6ª rodada mostrou que nem isso bastava**, e o diagnóstico final é mais amplo: **este arquivo
tinha virado um parser CommonMark escrito em awk.** Cerca de 4 espaços que o CommonMark chama de
bloco de código, fechador com info string, delimitador `1)`, tab no lugar do espaço, blockquote —
uma enumeração exaustiva de 117.649 documentos de 6 linhas achou 24 fail-opens, **100% deles na
lógica de cerca**. Markdown é genuinamente difícil, e cada rodada acertava um caso de borda
criando outro.

Então o rastreamento de cerca saiu inteiro. A seção de achados não tem cerca nenhuma — a única do
arquivo é o exemplo de formato, no cabeçalho —, então o parser **pula o cabeçalho** e **proíbe
cerca depois dele**. Não sobrou estado para dessincronizar. Parser de **107 → 75 linhas**, e a
regra da caixa marcada, agora independente de cerca, cobre as dez formas que o GitHub renderiza
marcadas em vez das cinco de que eu tinha partido.

**As duas lições, e nenhuma é sobre bash.** A primeira: YAGNI não é só sobre o que custa escrever,
é sobre o que custa *manter correto* — cinco rodadas foram gastas defendendo bloco de código
dentro de item, que nenhum dos achados usa e que o teto de ~6 linhas já proíbe. A segunda, mais
geral: **um sensor deve RECUSAR o que não sabe interpretar com segurança, não adivinhar.** Ser
mais estrito que o formato de entrada é uma decisão de projeto legítima e barata; tentar
interpretar tudo é o que custou seis gerações de defeito.

**A linha da tabela que mais ensina é "estado de cerca no parser".** Ele saiu na 6ª rodada e a 7ª
e a 8ª não acharam nada nessa família. Aí eu o reintroduzi na 8ª — limitado ao cabeçalho, "seguro
por construção" — e a 9ª achou nele exatamente o mesmo fail-open de sempre: uma cerca solta fazia
o arquivo inteiro renderizar como código com o run reportando "ok". A guarda que eu tinha escrito
para pegar isso era código morto inalcançável. **Terceira vez aprendendo a mesma coisa.** O
substituto não tem estado: uma contagem de paridade calculada fora do awk, que não pode
dessincronizar porque não lembra de nada.

**E a curva de convergência é o número que mais mudou de sinal:** achados herdados de rodadas
anteriores foram 17 → 2 → 3 → 5 → 4 → 5 → 5 → 3 → 0 → 1 → 6 → **3**. O zero da 9ª parecia fechar o
argumento — enquanto o conserto era remendo o herdado não caía, e ele só foi a zero depois que a
estrutura virou lista-branca sem estado. O laço não converge por esforço, converge por
simplificação; isso continua verdade. **Mas o zero não se sustentou**, e é essa a parte nova: ele
media a ausência dos defeitos que aquela rodada sabia procurar, não a ausência de defeitos.

As três rodadas seguintes mostraram o quê. A **10ª** derrubou a contagem de paridade que a 9ª
tinha escrito — quarta e última tentativa de modelar cerca, e a quarta a falhar dos dois lados
(silêncio com marcadores mistos, vermelho em três formas legítimas). A **11ª** achou a regressão
que a 10ª criou — um predicado alargado de "abre com placeholder" para "contém `<`", que escondia
288 das 18.720 formas de item no cabeçalho — mais seis regras que a varredura de mutação mostrou
sem probe, uma delas falhando aberta. E a **12ª** não achou **nada** criado pela 11ª, e ainda
assim achou três defeitos, todos herdados. Um deles é uma classe nova de fail-open que atravessou
as onze rodadas anteriores intacta: uma caixa marcada que cai na linha **seguinte** ao marcador
ainda é renderizada marcada pelo GFM, e a regra 2, que é por linha, não a vê.

Duas consequências para o processo viraram três. **Revisão adversarial é laço, não etapa**: o
critério de parada não pode ser "consertei os achados". E **quando três rodadas seguidas acham
defeitos na mesma vizinhança, o defeito não é nenhum deles — é a estrutura que os hospeda**; a
saída é parar de remendar e perguntar que estado está faltando. A terceira é da 12ª: **"uma rodada
que não acha nada" também não é critério de parada** — é só evidência sobre o que aquela rodada
sabia atacar. A 12ª usou um oráculo que nenhuma anterior tinha usado (um parser CommonMark de
verdade, para comparar o veredito do sensor com o que o GitHub renderiza) e por isso viu o que
onze leituras não viram. O que faz uma rodada valer não é o esforço nem o número dela — é ela
trazer um instrumento que as anteriores não tinham.

**A segunda rodada achou um defeito que a primeira rodada CRIOU, e essa é a parte que ensina.** O
conserto da âncora usava `sub(/ — [^—]*$/, ...)`, e o `awk` desta máquina é o **mawk 1.3.4**, que é
orientado a byte em qualquer locale: `[^—]` não nega o caractere, nega os bytes `{0xE2,0x80,0x94}`.
Como toda a faixa U+2000..U+2FFF começa com `0xE2`, bastava uma aspa curva na cauda do item —
`the team’s mission` — para o `sub()` falhar, o `head` continuar o item inteiro e a regra degradar
de volta para "crase em qualquer lugar", que a própria atribuição satisfaz. **Falhando aberto em
pontuação corriqueira**, com todos os 30 probes verdes, porque todo probe era ASCII puro. Vale como
regra geral e está no `CLAUDE.md`: classe negada só com ASCII; separador literal se procura com
`index()`/`substr()`.

O padrão por trás dos 17: toda regra que **nenhum probe distinguia** podia ser degradada sem que
nada notasse — a régua da data virava "qualquer parêntese", a do título virava "`**` em qualquer
lugar", a da âncora virava "crase em qualquer lugar" (satisfeita pela própria atribuição). O
selftest ficava verde nas três. Sabotagem adversarial é o que encontra a regra sem probe; o
selftest é o que impede que ela volte. **São instrumentos diferentes e um não substitui o outro** —
que é a mesma relação entre a suíte e o `check-mutation.sh` que o I13.2 já tinha registrado, um
nível abaixo. Duas regras, aliás, eram decoração pura e foram **removidas** em vez de ganharem
probe: o `/^#/` virou redundante quando a regra de coluna 0 entrou, e o piso de 20 itens punia
exatamente o encolhimento que o sensor existe para causar.

---

## 2026-08-16 — O ledger e o Jidoka param de mentir (missão `20260815-ledger-sem-ponto-cego`)

**Problema medido:** a primeira missão **planejada pelo próprio kit** (Marco 2) atacou o
instrumento que o laço kaizen lê, enquanto a série ainda estava vazia (`latest: null`) — o único
momento em que consertar não obriga a reinterpretar histórico. Três pontos cegos verificados no
`bin/sdd` de `fdf8708`: (1) o Jidoka do incremento `blocked` decidia por `printf | grep -qx` sob
`pipefail`, então **silenciava** em checkpoint grande e o runner queimava o `phase_budget` inteiro
contra a parede que já conhecia; (2) a auto-degradação `PUBLISH_ON_REVIEW_BLOCKED=draft` — o evento
de autonomia mais interessante que uma missão produz — dava `continue` antes do diário e do ledger
e **não escrevia linha nenhuma**; (3) `sdd autonomy` (humano) e `sdd kaizen --series` (juiz)
contavam escalada em eixos diferentes e podiam reportar números diferentes para o mesmo período.

| | Antes (`fdf8708`) | Depois (`fba1afa`) |
|---|---|---|
| Jidoka do `blocked` com checkpoint de 20000 linhas | **não dispara** (silencia sempre a partir de ~5000 linhas de `ckstatus`; 10/10 medido) | dispara, `rc 3` pelo ramo certo |
| Linhas no ledger quando o runner se auto-degrada | **0** | **1 por `run_id`** (medido no re-walk: ramo entrado 3×, registro 1×) |
| Leitores que agrupam escalada por `kit_sha` | 1 de 2 (só a série) | **2 de 2**, com asserção que compara dado com dado |
| Consumidores do enum de escalada que enxergam o mesmo conjunto | 2 de 3 (`phase_label` ficou cego) | **3 de 3**, por um `is_escalation` único por programa |
| Mutações no catálogo | 25 (score 100%) | **30** (score 100%, `KNOWN_GAPS` vazio) |
| Chamadas de asserção em `tests/*.sh` | 219 | **260** |
| Suíte no default (`SDD_MUTATION_JOBS=4`) | 47,9 s | **66,3 s** |

Todas as linhas medidas na fase DOCS, mesma máquina e mesma sessão: `fdf8708` num worktree
descartável contra o `HEAD` da missão, `./tests/run-all.sh` verde nos dois lados.

**O achado que vale mais que os três consertos: cinco asserções vácuas numa missão só.** Cada uma
passava por causa do **regime do fixture**, não da propriedade que o nome prometia — o `rc 3` do I1
era compartilhado com o esgotamento de orçamento; o ramo `draft` do I2 nunca era alcançado; a
cardinalidade do `F1` era garantida pelo stub que movia o disco uma vez só. A quinta, achada na
revisão, é de outra espécie: `"nothing had to be taught to phase_label"` **afirmava a decisão
errada** — e por causa dela a única missão em que o runner baixou a própria régua lia `ok` para o
juiz assim que um `sdd run` posterior passasse no gate de REVIEW.

| | Antes | Depois |
|---|---|---|
| Asserções vácuas conhecidas nesta missão | 5 (4 achadas em execução, 1 na revisão) | 0 |
| Técnica contra vacuidade registrada como convenção | nenhuma | 3 perguntas no `CLAUDE.md` § "TDD aqui dentro" |
| Asserção **diferencial** (dois fixtures comparados entre si) | 0 | 1 (`degraded` vs `blocked`, `tests/check-kaizen.sh`) |
| Testemunha de **regime** (conta quantas vezes o ramo foi entrado) | 0 | 1 (`tests/check-autonomy.sh`, exige ≥2) |

**Sensor durável:** as 5 mutações novas (`RUN_jidoka_pipefail`, `RUN_degraded_row_dropped`,
`RUN_escalations_no_axis`, `RUN_degraded_repeats`, `RUN_degraded_label_blind`) — cada conserto tem
um mutante que o mata, e `sdd health` reprova gate sem mutação. Red observado antes de cada Green.

**Custo dito como custo:** o critério (4) da D7 ("suíte < 30 s no default") continua não atingido e
esta missão **piora** o número de propósito — 5 mutantes a mais, cada um rodando a suíte inteira
numa cópia, e o fixture mais caro abrindo mais sessões de stub desde o `F1`. Cortar mutação para
ganhar tempo violaria o princípio que motivou o I13.2. As três saídas (subir o alvo, subir
`SDD_MUTATION_JOBS`, aceitar) estão no `TODO.md` com a medição, como decisão do humano.

---

## 2026-08-15 — I13.3: o laço fecha — o kit julga a própria mudança e planeja a próxima

**Problema medido:** o kit detectava 5× mais do que fechava (20 achados / 4 fechados na missão
medida do I13.1) porque ninguém julgava a mudança anterior nem planejava a próxima — detecção
sem fechamento é inventário. O I13.3 constrói o juiz híbrido (ADR 0001) e o planejador headless
com Jidoka (ADR 0002): `sdd kaizen --series` (série determinística), `gate_KAIZEN` (veredito
achado por conteúdo, plano nascido com `aprovacao:` vazio), `piorou` ⇒ exit 3, o 7º agente
`sdd-kaizen`, e o lembrete pós-pipeline (D6/D8).

| | Antes (I13.3.0, `302b9b8`) | Depois (fecho + review, mesma máquina e sessão) |
|---|---|---|
| Mutações no catálogo | 20 (score 100%) | **25** (score 100%, `KNOWN_GAPS` vazio) |
| Gates com mutação cobrada pelo `sdd health` | 7 | **8** (`gate_KAIZEN` incluso) |
| Asserções de sensor do laço kaizen | 0 | **67** (`tests/check-kaizen.sh`) |
| Piso da superfície do `check-lang` | 26 caminhos | **31** (ADRs + sensor + 2× agente) |
| Suíte no default (`SDD_MUTATION_JOBS=4`) | 26,0 s (1 rodada) | 38,0 s no fecho (mediana de 3); **52,1 s** pós-review (mediana de 3, 25 mutantes) |
| Suíte com `SDD_MUTATION_JOBS=10` | — | 27,3 s (23 mutantes, no fecho) |
| Missões do kit planejadas pelo próprio kit | 0 | **1** (`20260815-ledger-sem-ponto-cego`) |

**A primeira volta real** (Check de fecho, D7): sessão `a0e24b4e`, opus, **618 s**,
**US$ 3,36**, rc 0. Com o ledger real vazio (medido: `~/.sdd/` sem o arquivo), o veredito saiu
`indeterminado` com `kit_sha_judged: none`, citando a série verbatim e respeitando a guarda;
a triagem real do `TODO.md` achou 1 item já resolvido sem marca (`4ec9752`) e recalibrou outro
pela metade; a missão nascida tem 3 incrementos com Check executável e passou o `gate_KAIZEN`
com `aprovacao:` vazio — **o plano espera o humano** (Marco 2: o gate funcionando). O ledger
real ganhou 1 linha KAIZEN (`kit_dirty: false`, `gate: pass`), que a própria série exclui como
`meta`. Idempotência provada: o segundo `sdd kaizen` respondeu "already judged" sem gastar
sessão. O frontmatter do veredito real virou o fixture do gate no sensor (proveniência
`c2dd298`), fechando o risco "gate e fixture do mesmo autor".

**Critério D7 não atingido, dito como não atingido:** a meta "(4) suíte < 30 s no default"
falhou — 38,0 s. O custo cresce com o catálogo (13,98 s/16 mutantes → 22,34/19 → 38,0/23), que
é exatamente o que deve crescer; a triagem do agente registrou o estouro no `TODO.md` com as
três saídas conhecidas (subir o alvo, subir o default, aceitar o custo) — decisão do humano.

**Review pré-merge (2026-08-16), medido dos dois lados:** o `/codereview` sobre o diff da
branch achou **9 achados (2 HIGH, 2 MEDIUM, 5 LOW)** que 51 asserções e 23 mutações não viam —
os dois HIGH da mesma família de sempre, rótulo confiado sem verificação: (1) `gate_KAIZEN`
aceitava `melhorou`/`piorou` sem cruzar com `guard.sufficient` da própria série e sem validar o
enum; (2) o retry genérico ("fix exactly that") podia instruir uma sessão a **apagar uma
`aprovacao:` preenchida pelo humano**. A rodada de verificação (r2) confirmou os 9 fixes e achou
o **10º**: faltava o mesmo bailout depois da retentativa — aprovação escrita pelo retry virava
escalada `no-progress` espúria. Correções: o gate cruza guarda e enum, aprovação preenchida faz
bailout **antes** de qualquer sessão nos três pontos (`auto` para a linha com rc 3; valor humano
⇒ "done, sdd run", rc 0), e as mutações 24 e 25 (`KAIZEN_guard_ignored`,
`KAIZEN_approved_bailout_dead`) provam por sabotagem que as 16 asserções novas medem. Custo do
review na suíte: 38,0 s → **52,1 s** (mediana de 3) — 2 mutantes a mais e um sensor mais pesado
rodando dentro de cada um dos 26 sandboxes; entra na mesma conta do estouro já registrado no
`TODO.md`.

**Problema medido:** o `/codereview` sobre o merge `6f2b59e` achou dois defeitos que a suíte de 19
mutações e 63 asserções não via, e os dois são da mesma família — **guarda que lê como medida e
não é**.

1. `AUTONOMY_SHA_WARNED` prometia, no próprio comentário, "one-shot per process so it does not
   repeat on every row". Não repetia por linha: repetia **sempre**. `autonomy_kit_stamp` só era
   lida como `stamp="$(autonomy_kit_stamp)"`, então o corpo inteiro — inclusive
   `AUTONOMY_SHA_WARNED=1` — rodava num **subshell** que morria com a substituição de comando. O
   flag voltava a `0` a cada chamada e o ramo `[ "$AUTONOMY_SHA_WARNED" = "1" ]` era inalcançável.
   Reproduzido isolado: **5 avisos em 5 chamadas, flag final `0`**. O gêmeo `AUTONOMY_WARNED`
   (jq ausente) funciona — `autonomy_have_jq` é chamada direto —, e foi a assimetria que entregou
   o defeito.
2. `tests/check-autonomy.sh` apontava `SDD_STATE_DIR` para **dentro da árvore git do fixture**,
   exatamente a configuração que o design do ledger declara proibida e que `check-gates.sh` e
   `check-dry-run.sh` evitam de propósito, cada uma com o comentário explicando por quê. O stub que
   commita roda `git add -A`: o ledger entrava **rastreado e commitado no repo sob teste**.

**Antes → depois**

| | antes | depois |
|---|---|---|
| avisos "kit sem `.git`" por `sdd run` de 3 linhas | 3 (um por linha) | 1 |
| mutação | 19/19 | 20/20 |
| asserções em `check-autonomy.sh` | 63 | 68 |
| instrumentos rastreados pelo repo sob teste | 2 (`state/autonomy-log.jsonl`, `.stub/claude`) | 0 |
| caminhos sujos na árvore do fixture ao fim | 6 | 0 |
| suíte | 24,54s (mediana de 3, `HEAD` em worktree) | 23,26s (mediana de 3) |

**Sobre o tempo:** neutro, e de propósito. O 20º mutante cabe na 5ª leva de 4 que já existia
(`SDD_MUTATION_JOBS=4`), então não há leva nova para pagar. A linha da suíte foi **remedida dos dois
lados hoje**, na mesma sessão, em vez de comparar com os 22,34s que o log registra para o I13.1: a
máquina não está no mesmo estado, e comparar contra número guardado teria transformado ruído de
ambiente em regressão inventada.

**O conserto ataca a causa, não o sintoma:** `autonomy_kit_stamp` publica `AUTONOMY_KIT_STAMP` como
global em vez de imprimir — o mesmo padrão que `run_phase` já usa para `LAST_PHASE_*`, e pelo mesmo
motivo. Some o subshell, e a guarda que o comentário descreve passa a existir de fato.

**O sensor que faltava, e o que ele achou sozinho:** a asserção nova precisa de um kit **sem
`.git`** para alcançar o ramo (o kit real é um checkout), então `check-autonomy.sh` copia
`bin/ templates/ config/` — o mesmo conjunto do `sandbox()` da mutação — para fora do repo sob
teste e conta os avisos de um `sdd run` que escreve 3 linhas. A mutação `RUN_autonomy_sha_warn_repeats`
prova que a asserção mede: sabotar o flag para `0` mata a suíte. E a asserção genérica de higiene
("a árvore do repo sob teste termina limpa") pegou, na primeira execução, um instrumento que
ninguém tinha listado: o próprio stub `claude`, que morava em `$FIX/.stub` e vinha sendo commitado
junto. Foi para fora também.

**Onde a linha ficou:** o marcador `.moved-once` **continua dentro** do repo sob teste. Ele é o
produto de trabalho simulado da sessão — é o que faz `state_fingerprint` andar —, não instrumento.
Instrumento (ledger, stub, fixtures do leitor, cópia do kit) fica fora; trabalho fica dentro.

---

## 2026-08-15 — O runner passou a observar a si mesmo (I13.1)

**Problema medido:** o kit tinha 6 fases por missão e **zero** observabilidade sobre a própria
autonomia. A pergunta "a última mudança melhorou ou piorou?" só tinha resposta por memória
humana, e o piloto SQ-97 já mostrara que memória humana perde o dado: as 6 sessões foram
reconstruídas à mão, depois, a partir de logs.

**Antes → depois**

| | antes | depois |
|---|---|---|
| linhas de série histórica | 0 | 1 por sessão + 1 por escalada |
| sessões de retry medidas | 0 (rodavam sem `state_fingerprint`) | todas |
| mutação | 16/16 | 19/19 |
| suíte | 13,98s (mediana de 3, merge-base pré-I13.1) | 22,34s (mediana de 3) |
| pontos de escrita com guarda própria | 3 (diário) | 6, todos por uma função só |

**O que mudou de verdade:** o gate passou a ser avaliado **uma vez** por sessão em vez de até
quatro vezes nos ramos do `cmd_run` — menos `TEST_CMD` rodando por fase, e a linha do ledger
nasce depois do gate porque carrega o resultado dele.

**O ramo `moved="true"` não tinha sensor nenhum, e o revisor da Task 2 mediu isso:** até esta
task, todo stub `claude` do repositório era morto (`rc 1`) ou nunca chegava a rodar (dry-run) —
nenhuma sessão de teste jamais mudou o disco de verdade, então a atribuição
`[ "$before" != "$after" ] && moved="true"` podia virar um `true` (no-op) sem que a suíte
notasse. Isso importa porque `moved` é o numerador do desperdício que `sdd autonomy` relata: uma
regressão ali tanto escala BLOCKED em fases que estavam progredindo de verdade quanto registra
toda sessão como desperdício, com a suíte verde. `tests/check-autonomy.sh` ganhou um stub com
marcador em ARQUIVO — o stub é um processo novo a cada invocação, então uma variável de shell não
sobrevive entre chamadas — que commita de verdade na primeira invocação e nada faz depois. A
mutação `RUN_moved_never_true` prova que o sensor pega o mesmo no-op que o revisor tinha usado à
mão: catálogo 16 → 19, as duas do brief (`RUN_autonomy_ignores_dry_run`,
`RUN_autonomy_null_moved_as_zero`) mais esta.

**Custo da suíte, sem disfarce:** de ~14,0s (merge-base `c8bb535`, pré-I13.1, medido nesta
mesma máquina) para ~22,3s — acima do alvo de ≤15s do plano. A maior parte do aumento é o
catálogo de mutação: 19 mutantes contra 16, cada um rodando a suíte inteira num sandbox isolado
(`SDD_MUTATION_JOBS=4` por padrão, e a máquina tem 20 núcleos — paralelismo é uma alavanca não
usada). Decisão sobre subir o alvo do plano ou o `SDD_MUTATION_JOBS` default é humana; registrada
em `TODO.md` com o número medido, como o próprio plano manda.

**O que não mudou de propósito:** nenhum score. O runner grava fato; quem julga é o `sdd-kaizen`
do I13.3, que nasce com série histórica em vez de opinião.

---

## 2026-08-15 — Idioma era convenção, virou configuração (I13.5)

**Problema (Gemba):** o kit era utilizável só por quem lê português, embora nada no mecanismo
dependesse disso — **1.517 linhas acentuadas em 24 arquivos** da superfície (runner, agentes,
docs, README, config, testes), medidas por comando antes de começar. E não havia alavanca nenhuma
para um repo-alvo pedir artefatos noutro idioma.

### 5 Porquês

- **Sintoma:** o kit fala um idioma só, e não é escolha de ninguém — é herança.
1. Por quê? Toda a prosa foi escrita em PT-BR.
2. Por quê? O `CLAUDE.md` mandava: "PT-BR em tudo que é lido por humano".
3. Por quê? A regra nasceu quando o único leitor humano era o autor e o único repo-alvo era
   brasileiro — na época, uma simplificação correta.
4. Por quê? A regra não separou **duas audiências**: quem usa o kit (superfície) e quem lê os
   artefatos de uma missão (o time do repo-alvo). Uma regra só para as duas obriga a escolher um
   idioma para ambas.
5. Por quê (**causa raiz de processo**)? **Idioma foi tratado como convenção, não como
   configuração.** Convenção não tem chave, não tem default e não tem sensor — então não havia
   onde declarar o idioma, nem o que percebesse a regra sendo violada.

**Contramedida (as duas metades, uma não fecha a causa sem a outra):** `OUTPUT_LANG` dá à
audiência 2 uma chave, injetada pelo `boot_prompt()` em toda fase; `tests/check-lang.sh` dá à
audiência 1 um sensor. Traduzir sem a chave só trocaria a prisão de idioma; a chave sem o sensor
apodreceria no primeiro commit em português.

| | Antes (medido) | Depois (medido) |
|---|---|---|
| Linhas acentuadas na superfície | **1.517** em 24 arquivos | **0** |
| Arquivos da superfície com prosa PT-BR | 24 de 24 | 0 de 24 (2 exceções documentadas: contrato e dicionário) |
| Sensor que reprova PT-BR novo | **nenhum** | `check-lang.sh` na suíte, com catraca bidirecional e auto-teste |
| Chave para o idioma dos artefatos | **nenhuma** | `OUTPUT_LANG`, default vazio = comportamento idêntico |
| Mutações no catálogo | 15 | **16** (`RUN_ignores_output_lang`) |
| Catraca de tradução | — | 24 → **0** entradas |
| Tempo da suíte | 12,81s | ~14,0s (mediana de 3; o `check-lang` custa ~1,2s) |
| `sdd health` | rc 0, 6 dívidas | rc 0, **as mesmas 6** — nenhuma dívida nova |

**O sensor pegou três coisas que eu não teria pego**, e as três valem mais do que a tradução:

1. **Ele reprovou a si mesmo.** O dicionário de stopwords e os probes do auto-teste *são*
   português — escaneá-lo é acusar o detector de conter aquilo que detecta. Virou exclusão
   documentada, com o `selftest()` (rc 90/91/92) e um piso de caminhos (rc 93) como guarda no
   lugar do grep.
2. **Ele reprovou o `check-templates.sh`**, cujas regexes são os headings de `templates/` — ou
   seja, contrato de conteúdo em `OUTPUT_LANG`. Segunda exclusão, mesma categoria: português como
   **dado**, não como prosa. O custo (prosa PT-BR poderia entrar nesses dois arquivos sem ninguém
   ver) está escrito no arquivo e virou entrada de `TODO.md` com a direção que devolve a cobertura.
3. **Ele achou um bug nele mesmo:** `[\x{00C0}-\x{00FF}]` inclui `×` (00D7) e `÷` (00F7), que não
   são letras, e reprovou `QA_MAX_ITER × 3` no `schema.md` como se fosse português. A tentação era
   reescrever o doc até o detector calar — **enfraquecer o conteúdo para agradar um instrumento
   quebrado**. O conserto foi a classe, e o probe de inglês do auto-teste passou a carregar `×` e
   `÷`: sabotar a classe de volta agora reprova com rc 92.

**Correção de fato:** a entrada do `TODO.md` que originou esta missão afirmava que "o contrato já
é inglês". Medido: **não é** — sobraram 3 chaves de frontmatter (`aprovacao`, `versao`, `titulo`,
45 referências) e 2 nomes de artefato (`00-missao.md`, `01-plano.md`, 72 referências). Ficaram
fora de propósito, porque renomeá-las quebra missão em voo e toda instalação existente. Entrada
nova aberta.

**Não reivindicado:** "o kit agora é usável por quem não fala português". É métrica retardatária —
só o primeiro usuário estrangeiro mede. Revisar em missões futuras.

**Padronizado em:** `CLAUDE.md`, seção "Idioma" (três audiências: superfície inglesa com sensor,
artefato em `OUTPUT_LANG`, contrato inglês) e seção "TDD aqui dentro" (sensor que se auto-exclui
carrega auto-teste). Confirmado abrindo o arquivo depois de escrever.

**Custo:** 6 commits, 27 arquivos, +2.584/−2.196 linhas. Fecha 3 entradas do `TODO.md`, abre 3.

---

## 2026-08-14 — O sensor do sensor: a suíte verde não provava nada (I13.2)

**Problema (Gemba):** três bugs de gate da **mesma família** atravessaram a suíte verde e só
apareceram em uso real, cada um custando sessão paga — âncora de `**Status:**` no início da
linha (~US$ 15/volta), a mesma âncora duplicada em dois lugares divergindo ao ser corrigida num
só (~US$ 15/volta), e o parser da grade parando em `###` quando a seção seguinte é `##`
(~US$ 10). Somou-se a isso uma asserção que virou decoração ao mudar de caminho num refactor e
seguiu imprimindo `ok` por **vacuidade**.

### 5 Porquês

- **Sintoma:** o gate reprovava relatório correto (ou aceitava errado) e a suíte não acusava.
1. Por quê? A âncora do gate não casava com o texto que a skill realmente emite.
2. Por quê? O fixture usava um formato **escrito de memória**, não o emitido.
3. Por quê? Nada obrigava a copiar da fonte — gate e fixture têm o mesmo autor e nasceram da
   mesma suposição.
4. Por quê? Fixture e gate concordarem entre si é indistinguível de estarem certos: a suíte
   verde **confirma** a suposição em vez de medi-la.
5. Por quê (**causa raiz de processo**)? **Não existia sensor do sensor** — nada exigia que a
   suíte ficasse vermelha quando o runner é sabotado, então asserção vazia passa verde sempre.

**Contramedida (as duas metades, uma não fecha a causa sem a outra):** `tests/check-mutation.sh`
com 15 sabotagens catalogadas — mede se a asserção é viva; e fixtures **copiados da fonte** com
comentário de proveniência — mede se a suposição é a certa. Só mutação provaria que o gate mede
o formato imaginado com rigor.

| | Antes | Depois (medido) |
|---|---|---|
| Sabotagens do runner que a suíte pega | **0 de 0** (não havia catálogo) | **15 de 15 (100%)** |
| Lacunas reveladas pelo catálogo | — | 2 encontradas, 2 fechadas |
| Gates com mutação | 0 de 7 | **7 de 7**, cobrado pelo `sdd health` |
| Sensor do kit em 1 comando | nenhum | `sdd health` → exit 0 |
| Dívida de drift medida e congelada | não medida | 6 itens, cada um com dono no `TODO.md` |
| Tempo da suíte | 3,7s | 12,2s (mutantes em levas de 4) |
| Entradas do `TODO.md` | 25 abertas | 23 fechadas + 3 novas = 26 |

**As duas lacunas que o catálogo revelou** (nenhuma delas visível antes de existir mutação):
o fixture roda `TEST_CMD="true"`, que não pode falhar — então um gate que descartasse o rc da
suíte passava despercebido; e o fixture de bug do registry não tinha a legenda do enum
(`<!-- open | fixed | verified | wont-fix | invalid -->`), então afrouxar o grep para
`Status.*open` sobrevivia verde, bloqueando um `wont-fix` que é decisão humana.

**Padronizado em:** `CLAUDE.md` (§ TDD aqui dentro) — fixture copiado da fonte, gate novo entra
com mutação, e o aviso do `pipefail`. Conferido no arquivo, não só afirmado aqui.
Também em `docs/pipeline.md` (§ Quem mede os gates) e `README.md` (§ Uso).

### Desperdícios evitados (cortes conscientes)

- **Superprocessamento:** nada de motor de mutação genérico (mutmut/stryker) — mutante gerado
  produz centenas de equivalentes e um score que ninguém sabe agir. O catálogo é escrito à mão:
  uma entrada por bug que aconteceu ou por gate que existe.
- **Superprodução:** sem `--json`, sem histórico de score em disco (violaria "sem arquivo de
  estado"), sem mutar `agents/*.md`. Cortada também a checagem `bash -n` do health — a suíte
  já a roda.
- **Espera:** mutantes em levas de 4. Seriais seriam ~55s; medido: 12,2s a suíte inteira.

### O que aprendemos

- **`printf | grep -q` com `pipefail` inverte a lógica.** O `grep -q` sai no primeiro match e
  fecha o pipe; o `printf` morre de SIGPIPE (141) e o `pipefail` propaga — **achou vira erro**.
  Pior: depende do TAMANHO da entrada (o buffer de 64 KB absorve as pequenas), então passa nos
  testes e falha no repo-alvo grande. Duas ocorrências pré-existentes ficaram registradas no
  `TODO.md`, uma delas no Jidoka do `blocked`. Use herestring.
- **Regex de detector também apodrece.** A primeira medição contou 5 variáveis nunca lidas
  porque a classe `[A-Z_]+` não casa o dígito de `E2E_DIR`; e contou `QA_MAX_ITER` como morta
  porque procurava `$K`, e ela vive em contexto aritmético (`$(( QA_MAX_ITER * 3 ))`). Sensor
  que erra para os dois lados treina a ignorar o sensor.
- **O harness precisa da própria rede.** Três filtros: corrida de **controle** (a cópia sem
  sabotagem tem que ficar verde, senão o placar dá 100% por vacuidade), `cmp` (mutação que não
  aplicou é âncora perdida — erro do catálogo, nunca ponto) e `bash -n`.
- **Check negativo em trabalho não commitado apaga trabalho.** O Check do `sdd health` usa
  `git checkout bin/sdd` para desfazer a sabotagem; rodado antes do commit, levou junto a
  implementação inteira. Commite primeiro, sabote depois.

---

## 2026-08-14 — Nascimento do kit

**Problema (Gemba):** o fluxo de desenvolvimento documentado em
`obsidian/01 Projects/Sales Quote JRC/Fluxo-Desenvolvimento-Template-Prompt-QA.md` funciona, mas
exige **~6 intervenções manuais** depois do planejamento (`/clear` 2x, troca manual de modelo,
invocar QA, invocar review, push/PR) e sessões longas estouram a janela de contexto no meio da
execução — obrigando a recomeçar com estado só na cabeça do humano.

**Métrica-alvo:** 1 missão pequena atravessa do plano aprovado até **PR aberto** com
**0 intervenções humanas** e **0 estouros de contexto**.

| | Antes | Depois (alvo, medido no piloto SQ-94) |
|---|---|---|
| Intervenções humanas pós-plano | ~6 | 0 |
| Estouros de contexto por missão | frequente em missões médias | 0 (sessão por fase/incremento) |
| Gate de qualidade | rótulo ("está pronto") | artefato (teste, spec, grade, PR) |
| Achado fora de escopo | perdido ou vira desvio | entrada no `TODO.md` |

**Contramedida:** 6 agentes especializados + runner `bin/sdd` que encadeia sessões headless por
fase e por incremento, com gates por artefato e handoffs em disco.

**Desperdícios cortados no planejamento (K3):** claude-mem (injeção não curada gasta janela),
daemon/UI/banco de estado (estado derivado dos artefatos basta), Opus no publisher (tarefa
mecânica → Sonnet).

**Status:** implementação em curso (incrementos I0–I12 do plano). Resultado medido entra aqui
quando o piloto I11 fechar.

---

## 2026-08-14 — Shim quebrado do `agent-browser` (I0)

**Problema:** `~/.nvm/versions/node/v22.22.3/bin/agent-browser` era symlink para
`~/.hermes/hermes-agent/node_modules/...`, caminho inexistente — o binário `agent-browser`
simplesmente não existia no PATH (`command not found`), o que derrubaria a fase QA em silêncio.

**Contramedida:** re-link para o pacote são em `lib/node_modules/agent-browser/bin/agent-browser.js`.

**Sensor:** `agent-browser --version` entrou no `sdd preflight` — o ambiente passa a ser
verificado antes de cada missão, não descoberto no meio da fase QA.

| | Antes | Depois |
|---|---|---|
| `agent-browser --version` | `command not found` | `agent-browser 0.27.0` |
| Descoberta da quebra | no meio da fase QA | no preflight, antes de gastar sessão |

---

## 2026-08-14 — A fase headless não conseguia executar comando nenhum

> Missão `20260814-dry-run-completo`. O achado de maior valor da missão **não foi o que ela ia
> entregar** — foi o defeito estrutural que ela expôs no kit ao ser a primeira a rodar headless
> de verdade. Por isso a missão-fixture existe.

**Problema (Gemba):** `run_phase()` montava `claude -p … --permission-mode acceptEdits` **sem**
`--allowedTools`. `acceptEdits` auto-aprova **edição de arquivo**, não `Bash`. Na prática a sessão
de fase só conseguia ler: `tests/run-all.sh`, `bash -n bin/sdd` e até `bash -c 'echo hello'`
voltavam "This command requires approval". **`git add` também era negado.** O `sdd-executor` não
rodava a suíte na abertura, não via o Red, não verificava o Green e não conseguia commitar — e
`gate_EXEC` exige hash real no `git log`. **A fase EXEC era insatisfazível por construção**, e o
mesmo valia para QA/REVIEW (que rodam `TEST_CMD`) e PR (que precisa de `git push`/`gh`).

O modo de falha era do tipo mais caro: silencioso. Nada no runner acusava; a sessão simplesmente
não produzia artefato, e o gate reprovava com "1 de N incrementos ainda por executar" para sempre.

**Contramedida:** `ALLOWED_TOOLS` (default `Bash`) no `.sdd/config.sh`, passado como
`--allowedTools` em `run_phase()` — commit `2083680`.

| | Antes | Depois |
|---|---|---|
| Comandos que a sessão de fase consegue executar | 0 (só leitura) | os de `ALLOWED_TOOLS` |
| Fase EXEC | insatisfazível por construção | `357b401` rodou a suíte, viu Red, viu Green, commitou |
| Sessões gastas contra a parede por incremento `blocked` | 4 (até estourar `phase_budget`) | 0 — escala na hora, `exit 3` |
| Detecção | no meio da 1ª missão headless | — (sensor de preflight ainda pendente, no `TODO.md`) |

**Jidoka na prática:** a primeira sessão EXEC **não** contornou o impedimento. Marcou o incremento
`blocked`, escreveu a causa raiz no checkpoint e escalou sem escrever uma linha de código. Seguir
teria significado commitar bash não executado e marcar `done` — o "rótulo, não artefato" que o kit
existe para proibir. A linha parou, o defeito apareceu, o kit ficou mais forte.

**O que ainda falta (registrado no `TODO.md`, não fechado aqui):** o sensor durável. Hoje nada
impede a regressão silenciosa — o `sdd preflight` valida que o `claude -p` responde, o que **não**
cobre este modo de falha. O preflight precisa disparar uma sessão headless real com as mesmas
flags e exigir que ela **execute** um comando.

---

## 2026-08-14 — `--dry-run` mostrava o pipeline pela metade (I1)

**Problema (Gemba):** `sdd run <missão> --dry-run` existe para responder *"o que vai acontecer se
eu rodar isto?"* antes de gastar token. Respondia pela metade: imprimia a **primeira** fase e dava
`return 0`. Numa missão recém-planejada, o usuário via `EXEC` e não ficava sabendo que depois
viriam QA, REVIEW, DOCS e PR — nem com que agente e modelo cada uma rodaria.

**Contramedida:** cursor próprio sobre a lista `$PHASES` (`next_pending_phase()`), nunca
re-chamando `current_phase()` — que travaria na mesma fase para sempre, já que o dry-run não muda
o disco. Commit `357b401`.

| | Antes | Depois |
|---|---|---|
| Fases nomeadas pelo dry-run (missão recém-planejada) | 1 (`EXEC`) | 5 (`EXEC`, `QA`, `REVIEW`, `DOCS`, `PR`) |
| Agente/modelo por fase visíveis antes de gastar token | só da 1ª | de todas |
| Sensores na suíte | 2 | 3 (`check-dry-run.sh`) |
| Asserções na suíte | 90 | 120 |

**Sensor durável:** `tests/check-dry-run.sh`, permanente em `tests/run-all.sh`. Observado vermelho
antes do verde: projetava só `EXEC=sdd-executor`, faltando QA/REVIEW/DOCS/PR.

**Efeito colateral honesto, não escondido:** projetar exige avaliar os gates, e três deles rodam
`TEST_CMD`. O dry-run escreve `.sdd/logs/<missão>/gate-*-test-<ts>.log` (gitignored, memoizado por
processo). O `--help` e o [`docs/pipeline.md`](docs/pipeline.md) dizem isso com todas as letras —
a frase fácil "o dry-run não mexe em nada" seria mentira.

---

## 2026-08-14 — Asserção que virou decoração (dívida de sensor)

**Problema:** quando `53cf63a` moveu o `pipeline.log` para `.sdd/logs/`, a asserção
`projeção blocked não cria pipeline.log` continuou apontando para o caminho velho — onde o runner
não escreve mais em circunstância nenhuma. Ela seguia imprimindo `ok` **por vacuidade**: com o bug
que ela guardava reintroduzido à mão, continuava verde. Uma asserção que não pode falhar não se
distingue, na saída da suíte, de uma que passa.

**Como apareceu:** teste de mutação **à mão** — sabotar o código e exigir que a suíte fique
vermelha. Três rodadas seguidas (QA volta 2 e REVIEW r1) usaram a técnica e acharam frestas.

| | Antes | Depois |
|---|---|---|
| Asserções vácuas conhecidas | 4 (1 na QA, 3 no review r1) | 0 |
| Frestas provadas por mutação, não por leitura | — | 6 |
| Asserções na suíte | 118 (fim da QA) | 120 (fim do review) |
| Teste de mutação | manual, por sorte | ainda manual — `tests/check-mutation.sh` está no `TODO.md` |

**Contramedida parcial, dita como parcial:** as frestas foram fechadas, mas a **classe** do
problema continua. Enquanto a mutação for manual, a próxima asserção decorativa só aparece por
sorte. `tests/check-mutation.sh` — o sensor do sensor — é o item de maior alavancagem no
`TODO.md`. Registrar como "resolvido" seria exatamente o rótulo-sem-artefato que o kit proíbe.
