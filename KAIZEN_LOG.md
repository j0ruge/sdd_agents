# KAIZEN_LOG — `sdd_agents`

Registro de melhorias com **antes/depois medido**. Sem número, não entra.

---

## 2026-08-28 — O ledger passa a dizer o que a sessão fez, não só se ela escreveu (missão `20260828-instrumento-honesto`)

**Problema (Gemba):** a pergunta do dono do kit é *"está maduro para projeto real?"*, e o
instrumento que deveria respondê-la respondia errado — **na direção que lisonjeia o kit**. `stalled`
estava definido como `moved == false`: "a sessão não escreveu nada", que não é "a fase não avançou".
Censo das 145 sessões do ledger real, antes de qualquer edição: 64 `pass/true`, **68 `fail/true`**
(escreveu algo, o gate reprovou, o runner comprou outra sessão — **invisíveis**), 13 `fail/false`
(`stalled`). Sobre `20260827-condicoes-pagamento-mesmo-cliente`, que o handoff descreve como
*"~8 resgates humanos"*: `6 session(s) · 0 stalled · ? intervention(s)` — três `run_id` distintos
na mesma missão, e `?` porque a contagem da D16 lia linhas `- intervention:` de um checkpoint que
ninguém escreveu (0, 1 e 0 notas nas três missões do piloto). O juiz lia `ok` para o EXEC de
`frete-cif-fob`: 7 sessões, 5 reprovações, cada uma commitando algo.

**Contramedida:** uma definição de "o que a sessão fez" (`ledger_outcome_defs`, jq impresso),
costurada nos dois leitores como `ledger_row_is_local` já era, com paridade provada por asserção
diferencial; `launch(es)` (= `run_id` distintos) como o número da D12, sobre **todas** as sessões
locais da missão; `reopened` pela definição "fase abaixo de outra cujo gate já passou"; a cláusula
de churn na rubrica (`leve`). Nenhum campo novo na linha, `v` continua 1, zero migração — as 145
linhas se releem com a régua nova. D16 emendada no `CONTEXT.md`; achado do `sdd close` no
`TODO.md`. Spec em `docs/superpowers/specs/2026-08-28-instrumento-honesto-design.md`.

| | Antes (régua `moved`) | Depois (régua `gate` + `moved`) |
|---|---|---|
| `condicoes-pagamento` (SQ-111), por missão | `6 session(s) · 0 stalled · ? intervention(s) · US$ 68.87` | `6 session(s) · 5 advanced · 1 churned · 0 idle · 3 launch(es) · 1 reopened · US$ 68.87` |
| `frete-cif-fob` · EXEC, no juiz | `ok` | `leve` — aplicando a rubrica à mão às 7 sessões (5 `fail`, 0 escaladas, 0 `sdd retry`, 0 `auto_retry`, 0 `moved:false`, último gate `pass` → `ok` antes, `leve` depois), como o handoff §5 já diz; a série (`sdd kaizen --series`) só expõe as duas últimas versões do kit e essa fase fica fora da janela |
| `25d4e1c` (latest), série | `moved_rate: 1, labels: {ok:5, leve:0, refez:1}` | `outcomes: {advanced:5, churned:1, idle:0}, advance_rate: 0.83`; `labels` **não** muda — o único grupo com reprovação nesta fatia já lia `refez` pela última sessão |
| `lote-facil` | `9 session(s)` | `4 launch(es) · 2 reopened` — bate com a contagem à mão de `20260828-o-gate-sabe-que-o-app-caiu-handoff.md` §9 |
| `?` na tabela por missão (`--all-repos`) | **5** missões (`grep -c '?' before-by-mission.txt`: `jornada-qa`, `placeholder`, `cif-forma-pagamento`, `frete-cif-fob`, `condicoes-pagamento`) | **0** |
| `waste` da versão mais recente do kit (`25d4e1c`) | **0%** (`idle`/`stalled` sozinho — a régua antiga) | **16%** (`churned + idle` = 1 + 0 sobre 6 sessões — a régua mudou, não a sessão) |
| asserções de `tests/run-all.sh` | **637** | **666** (663 ao fechar a execução; a revisão final acrescentou os dois fixtures de query e fragment sem path, e `efa10c9` já havia somado uma) |
| `tests/check-autonomy.sh` / `check-kaizen.sh` | **202** / **137** | **223** / **143** |
| catálogo de mutação | 166 de 166 | **179** de 179 (173 ao fechar a execução; a revisão final acrescentou um mutante por strip do parser de URL, o do braço IPv6, o do userinfo e o da guarda das notas) |
| achados abertos no `TODO.md` | 77 | 78 (o `sdd close`) |
| 145 sessões, todos os repos — tabela de versão do instrumento (`sdd autonomy --all-repos`, soma sobre as sessões **comparáveis**, 133 de 145) | `8 stalled` | `64 advanced · 61 churned · 8 idle` |

⚠️ **A linha "145 sessões" mede duas populações, e nenhuma célula acima mistura as duas.** A
tabela de versão do próprio instrumento só soma as sessões **comparáveis** — 133 das 145, excluindo
kit sujo e `sha`/`moved` nulos — e é dela que saem os `8 stalled` / `64 advanced · 61 churned ·
8 idle` acima. O censo do §2 da spec, sobre as **145** linhas do ledger real (comparáveis **e**
não comparáveis), lê `13 fail/false · 68 fail/true · 64 pass/true` — a mesma leitura que abre esta
entrada, em **Problema**. As duas contagens são medições corretas de populações diferentes; a
tabela nunca soma 145 porque ela, por desenho, não é o censo.

**Sete mutantes entram, cada um com o assassino nomeado:** `AUTONOMY_outcome_reads_moved_only` (o
histograma exato de `check-autonomy.sh` — a paridade sozinha NÃO o pega, porque os dois leitores
erram juntos), `KAIZEN_outcome_inlined_old` (a paridade — é o que prova que ela é medida e não
afirmada), `KAIZEN_churn_reads_ok`, `AUTONOMY_waste_idle_only`, `AUTONOMY_launches_counts_rows`,
`AUTONOMY_reopened_ignores_gate`, `AUTONOMY_reopened_comparable_only`.

⚠️ **O que ISTO NÃO PROVA.** `launches` subconta por construção (piso, não teto). `pass/false` é
classificado `advanced` sem fixture. A mudança da rubrica não é emenda da ADR 0001: é o caso que
ela desenhou — régua mecânica é código, datada no histórico. E o `sdd close` continua fora do
ledger — achado, não conserto.

---

## 2026-08-26 — A ADR 0005 sai do papel, e o teto de fase passa a contar sessões (`60fe724`…`ee6404e`)

**Problema (Gemba):** dois defeitos independentes, ambos medidos e nenhum deles visível de dentro.

O primeiro: a [ADR 0003](docs/adr/0003-judge-axis-evidence-from-target-repos.md) decidiu, em
2026-08-17, que a evidência de veredito vem de **repo-alvo de verdade** — no repo que CONSTRÓI o
kit toda sessão commita e a seguinte cai num `kit_sha` novo, então o eixo degenera por construção.
Ela ficou **carta morta por nove dias** porque nunca disse *como o juiz LÊ* essas linhas: o
`kaizen_series` filtrava por repo, `sdd kaizen` só roda no repo do kit, e o filtro deixava o juiz
olhando exatamente para o único repo que a 0003 declarara inservível. Medido na `main`, sobre o
ledger real: `excluded.other_repo: 38`. Na primeira missão de repo-alvo de verdade
(`20260825-frete-cif-fob`) eram **21 linhas comparáveis e US$ 144,88** que a leitura padrão do juiz
não via — e três missões planejadas sobre um sha congelado que teriam respondido `indeterminado`
para sempre. O próprio runner dizia isso na última linha da corrida, e ninguém tinha o que fazer
com o aviso.

O segundo: `attempts["$phase"]` sobe **uma vez por volta do laço**, antes do primeiro `run_phase`
daquela volta, e o retry **dentro** da volta abre uma segunda sessão sem encostar no contador. O
teto lia `attempts`, então um orçamento de N comprava até 2N sessões: o `QA_MAX_ITER * 3` = 9 da QA
era um teto de **18**. O `config/schema.md` prometia sessões (*"the phase session cap is
QA_MAX_ITER × 3"*) desde que a chave nasceu — a prosa estava certa e o código contava outra coisa.
Na `20260825-frete-cif-fob` o teto **funcionou** (9 voltas, exatamente o limite) e 3 dessas voltas
compraram retry: 12 sessões, US$ 11,27. A fase não estava descontrolada; o medidor lia a unidade
errada.

**Contramedida:** as três partes da [ADR 0005](docs/adr/0005-judge-reads-every-repo-with-visible-composition.md)
e o conserto do teto.

1. **O juiz lê todos os repos** (`28af7ea`). `LEDGER_ALL_REPOS=1` no topo do `cmd_kaizen`, uma vez,
   para o processo inteiro — `--series`, `gate_KAIZEN`, `kaizen_axis_note` e o bloco novo de
   composição leem UMA fatia. `--all-repos` continua aceito e vira **no-op** ali; no `sdd autonomy`
   ele decide tudo, porque a pergunta daquele comando é mesmo "quanto ESTE projeto custou".
2. **A série publica a composição da fatia** (`0a84833`), derivada sobre as linhas que a **guarda
   admite** — sessões E escaladas — e nunca sobre `event: session`: três dos sete repos do ledger
   real só contribuem escalada, e o primeiro rascunho da ADR, que contou sessões, respondeu "quatro
   repos" sobre sete e ficou escrito lá dentro dizendo isso de si mesmo. É o que torna a parte 1
   segura: contaminação vira coisa que se **vê**, e não coisa que o runner adivinha.
3. **O runner recusa o ledger real para checkout sob `$TMPDIR`** (`60fe724`). Cinco dos sete repos
   do ledger real são fixture e os cinco moram sob `/tmp`; os cinco vieram de corridas **manuais**
   que esqueceram `SDD_STATE_DIR`, nunca da suíte, que exporta a variável desde sempre. O mecanismo
   existia e funcionava — o que vazou, vazou por disciplina, e por isso virou instrumento.
4. **O teto conta sessões** (`ee6404e`). Passa a ler `sessions[$phase]`, o contador que o laço já
   mantinha nos DOIS sítios de sessão e que a manchete de `BLOCKED` já lia. `attempts` continua
   dono do campo `attempt` do ledger, então nenhuma linha muda de forma.

| | Antes (`606643f`) | Depois (`ee6404e`) |
|---|---|---|
| `excluded.other_repo` na leitura padrão do juiz (ledger real) | **38** | **0** |
| composição da fatia do eixo | não existia | `[{repo, missions, missions_with_session}]`, em `latest` e em `previous`, impressa também no terminal |
| repo com só escalada numa versão do kit | invisível em qualquer contagem por sessão | aparece na composição, com `missions_with_session: 0` |
| `sdd run` de checkout sob `/tmp` sem `SDD_STATE_DIR` | escreve no `~/.sdd` real, calado | `die`, rc 1, nenhuma linha escrita |
| `sdd run` de checkout **fora** dos dois raízes temporárias | escreve | escreve — inalterado, e é o controle que separa "recusa fixture" de "recusa" |
| teto da fase EXEC no fixture do sensor (orçamento 4) | **8** sessões | **4** sessões, mesma escalada `budget-exhausted` |
| teto de sessões da QA com `QA_MAX_ITER=3` | até **18** | **9** (limite superior 10: o teto é testado uma vez por volta) |
| asserções de `tests/run-all.sh` | 592 | **606** |
| `tests/check-autonomy.sh` | 189 `ok` | **197** |
| `tests/check-kaizen.sh` | 131 `ok` | **137** |
| catálogo de mutação | 154 de 154 | **158** de 158 |
| relógio da suíte | 48,5 s | 51,1 s |
| achados abertos no `TODO.md` | 74 | 74 |

**Cinco mutantes entram e um sai.** Entram `LEDGER_tmp_repo_allowed`,
`KAIZEN_composition_session_unit`, `KAIZEN_composition_unprinted`,
`KAIZEN_series_default_per_repo` e `RUN_qa_ceiling_counts_laps`. Sai
`KAIZEN_prompt_series_unflagged`, e a razão é a régua desta casa e não conveniência: ele ancorava na
maquinaria `ledger_flags`, que propagava a flag da invocação para a linha de comando escrita no
prompt do agente. Com **uma** leitura, o gate e o prompt não conseguem cair em séries diferentes —
o defeito que ele reproduzia é inalcançável por construção, e re-ancorado ele **sobreviveria**
medindo nada. Quem ocupa o lugar é o `KAIZEN_series_default_per_repo`, pego por cinco asserções em
dois sensores.

**Duas seções de sensor afirmavam a decisão ANTIGA e foram reescritas, não apagadas.** Uma seção
removida é uma propriedade que ninguém mede: a `== series: the ledger is global, the readers are
not ==` do `check-kaizen.sh` passou a cobrar que o juiz responda **a mesma série byte a byte** de
qualquer um dos dois repos **e** que o `sdd autonomy` sobre o mesmo arquivo continue filtrando —
dois comandos, duas respostas, um ledger, comparados um com o outro. O par `all-repos` do
`check-autonomy.sh` passou a cobrar que a flag **não mova nada** na série do juiz, com o controle de
que ela ainda move a tabela do humano.

⚠️ **O que ISTO NÃO PROVA.** O conserto do teto nunca correu contra missão de verdade — a prova é a
próxima missão de repo-alvo. E a composição só ganha valor quando a fatia tiver mais de um repo:
hoje, no ledger real, `latest` é uma missão de um repo só, que é exatamente o eixo degenerado que a
ADR 0003 descreve. O número que motivou a parte 1 (US$ 400 de evidência que o juiz não contava)
volta a ser mensurável na reabertura da janela, não aqui.

---

## 2026-08-26 — A fase QA para de girar em bug que ninguém tinha permissão de fechar (missão `20260826-o-laco-da-qa`)

**Problema (Gemba):** a primeira missão de repo-alvo de verdade (`20260825-frete-cif-fob`, no
`sales_quote`) custou US$ 144,88 em 23 sessões, e a **fase QA sozinha** levou US$ 73,32 em 12
sessões — mais que EXEC + REVIEW + DOCS + PR + TICKET somados (US$ 71,56 em 11). **Sete daquelas
doze estavam num laço que nenhuma delas podia vencer**, e as duas engrenagens eram contrato, não
código.

A primeira: a Âncora 3 do `gate_QA` exigia zero `Status: open` no registry, e a linha `Status:` é
das skills `qa-report`/`qa-execution`. O `sdd-executor` não sabe que o registry existe
(`grep -c 'qa/bugs\|Status:' agents/sdd-executor.md` → **1**, e é sobre o `checkpoint.md`); o
`sdd-qa` é proibido por regra não-negociável. Para bug **sanável** o ciclo fecha pelo `F<n>`; para
bug que espera **decisão de produto** não havia caminho nenhum — e a âncora barrava por ele do
mesmo jeito, enquanto o `§ 5` do `agents/sdd-qa.md` prometia por escrito que ele *"does not block
the pipeline"*. A promessa era falsa e o gate era a prova.

A segunda: "moveu o disco" era lido como progresso. Só **duas** sessões seguidas sem mexer no disco
disparavam `BLOCKED … no-progress`. Numa fase insatisfazível, todo achado honesto virava commit e
**todo commit comprava a volta seguinte** — as instruções *"não commite"* das iterações 3, 4 e 6
foram todas desobedecidas, **com razão**, porque cada uma achou algo real.

**Contramedida:** o campo `- **Closable by:** <agent | human>` no arquivo de bug, que a âncora
passa a ler, mais a escalada imediata do handoff que declara `status: blocked` — token que já
significava exatamente isso desde sempre (`bin/sdd:1602`), e que só faltava ser obedecido na
primeira sessão em vez de na segunda. **Nenhum agente ganhou permissão de escrever `Status:`**: o
gênero é a única linha do arquivo que é do agente, e é justamente porque o `Status:` continua sendo
das skills que o gênero precisou existir.

| | Antes (`main`, `6e82acb`) | Depois (`4ec3850`) |
|---|---|---|
| bug `open` que espera decisão de produto | barra o `gate_QA` **para sempre** — ninguém no pipeline pode fechá-lo | passa marcado `Closable by: human`; segue `open`, no registry e no PR |
| bug `open` sanável por agente | barra | barra — inalterado, e é o ponto: para ele o ciclo `F<n>` fecha |
| bug `open` **sem** o campo | barra | barra — fail-safe deliberado, para o registry legado inteiro |
| sessões que um handoff `status: blocked` custa até escalar | **2** | **1** |
| `sdd run --max-phases 1` sobre handoff `blocked` | rc **0**, sem linha de ledger e sem `pipeline.log` | rc **3**, `kind: handoff-blocked` no ledger + `BLOCKED` no journal |
| valores do enum `kind` do ledger | 4 | **5** |
| asserções de `tests/run-all.sh` | 577 | **592** |
| `tests/check-gates.sh` | 129 `ok` | **139** |
| `tests/check-autonomy.sh` | 184 `ok` | **189** |
| catálogo de mutação | 148 de 148 | **154** de 154 |
| achados abertos no `TODO.md` | 72 | **74** |

⚠️ **O antes/depois que MOTIVOU a missão não está nesta tabela, e não pode estar.** O número que
importa — quanto custa a fase QA de uma missão de repo-alvo — só reaparece na próxima missão de
repo-alvo; a missão inteira rodou no kit, cujo registry está limpo (6 arquivos, 5 `verified`, 1
`fixed`, **0 `open`**), então o regime consertado nem sequer é reproduzível fora de fixture. O que a
tabela mede é a **condição** que produzia o laço, uma linha por regime, e é o que dá para medir hoje
sem inventar número.

**Três defeitos que a própria missão criou e as suas fases pegaram**, o que é a razão de esta
entrada existir e não só a contramedida:

- **A QA achou dois no que a EXEC tinha acabado de escrever.** O gênero casava por **prefixo**
  (`humano` — a grafia pt-BR, num repo que declara `OUTPUT_LANG=pt-BR` — lia como `human` e deixava
  de barrar) e casava em **qualquer linha** do arquivo (um bug cujo campo dizia `agent` parava de
  barrar no instante em que o corpo CITAVA a linha humana — e o `§ 5.1` imprime essa linha exata
  para o agente copiar, então o primeiro alvo provável era um bug arquivado SOBRE o campo). Os dois
  respondiam `registry clean`.
- **A QA achou o terceiro no conserto da segunda engrenagem**: com uma porta só, o marcador
  sobrevivia à **volta** em vez de ao gate, e a escalada saía `{phase: EXEC, kind: handoff-blocked}`
  sobre um `20-handoff-exec.md` que dizia `done` — alcançado pelo pipeline obedecendo as próprias
  instruções, porque o `§ 4` manda a QA responder bug sanável com uma linha `F<n> pending`, e linha
  pendente é exatamente o que manda a volta seguinte para a EXEC.
- **A REVIEW achou o quarto no teto**: a porta nova estava ABAIXO do `--max-phases`, então
  `sdd run --max-phases 1` sobre um handoff `blocked` pagava a sessão e devolvia **0**, calado. As
  duas Jidokas irmãs sempre estiveram acima do teto; esta nasceu abaixo, e o resultado era o laço
  que a missão existe para apagar, vestindo um rc verde.

**A lição de processo, e ela é a régua e não a anedota:** *verificável por comando* é metade do
princípio 1. A outra metade é **quem, dentro do pipeline, pode escrever o artefato que o gate
exige** — se a resposta é "ninguém", o gate não para a linha, faz ela girar. Está escrita no
`CLAUDE.md`, com o verbete "Gate insatisfazível" no `CONTEXT.md` e a decisão (com as duas
alternativas recusadas, uma delas por dado: dos quatro `wont-fix` que desbloquearam a missão 1,
**dois eram P1**) no [ADR 0006](docs/adr/0006-qa-anchor-reads-genre-blocked-handoff-stops-the-line.md).

⚠️ **Correção de um número que dois handoffs desta missão registraram errado:** o `40-review-r1.md`
dá 581 asserções *"quando a missão começou"*. 581 é a medição da QA, tirada **depois** do I1–I4. A
base real é **577**, medida nesta fase num worktree de `main` (`git worktree add`, `./tests/run-all.sh`
→ rc 0). Os 592 de hoje são +15 sobre a base, não +11.

---

## 2026-08-25 — O fecho, a guarda do kit e a régua da própria revisão (missão `20260825-a-regua-vale-para-o-kit`)

**Problema (Gemba):** o piloto M2 devolveu três defeitos que nenhum instrumento tinha visto.
`sdd close` imprimiu `ok SQ-108 closed` sobre uma issue em "Em andamento" — lia o `rc` da sessão, e
esse `rc` é COMPARTILHADO entre a sessão que fecha e a que apenas **pede confirmação**. O stub
`- intervention:` do `templates/checkpoint.md` casava o contador do `sdd autonomy`, então toda
missão nascia devendo uma intervenção fantasma. E uma sessão de EXEC cujo alvo era outro repo
commitou um achado de kit direto na `main` daqui (`2d28d13`), deixando a suíte vermelha fora de
qualquer revisão.

**Contramedida:** um sensor por defeito, e o `sdd close` deixou de ser "consertado" para ser
reprojetado — a pergunta que verifica virou o **pré-cheque**, antes da sessão. Verdito inalcançável
não é motivo para gastar orçamento primeiro e só então admitir que nunca se poderia ter checado.

**A parte que a revisão pagou, e é a razão desta entrada:** a primeira rodada deste trabalho
declarou dois "consertos" que não eram. O `--dry-run` foi **deliberadamente** desarmado do
`kit_guard_check` com o argumento de que *"nenhuma sabotagem de uma guarda de DRY_RUN poderia fazer
um probe ficar vermelho"* — e o probe existe, tem quatro linhas, e fica vermelho. E o pré-cheque do
`sdd close` verificava `command -v`, que não enxerga auth expirada — que é exatamente o mundo cujo
fixture a mesma missão tinha capturado.

| | Antes da revisão | Depois |
|---|---|---|
| Avisos de ledger numa projeção (kit como cópia simples) | 1 — sobre linhas que a projeção nunca escreve | 0, e o par diferencial exige 1 na corrida real |
| Sessão paga gasta com auth expirada | 1 por invocação | 0 — recusa antes, e diz o comando para conferir à mão |
| Sessão paga gasta sobre issue já `Done` | 1 | 0 — uma chamada de acli e o veredito |
| Portas que abrem sessão e ficam de fora da guarda do kit | 1 (`sdd close`) | 0 — quatro portas, quatro probes |
| Regimes `close:` | 6 | 10, e um deles fixa o pré-cheque ABAIXO do gate do JIRA |
| Regime de controle da guarda sem piso anti-vacuidade | 1 (verde com a corrida apagada) | 0 |
| Mutantes da família close/kit-guard | 3 | 8 |

**Como as duas frestas apareceram:** sabotagem, e não leitura. Levantar o pré-cheque para cima do
gate do `JIRA_ENABLED` deixava a suíte inteira verde enquanto `sdd close` passava a morrer com
`rc 1` em todo repo sem JIRA e sem acli. Apagar a construção do mundo de controle da guarda **e a
corrida inteira** deixava a asserção "a sessão que não mexe no kit não é acusada de nada" dizendo
`ok`. As duas hoje ficam vermelhas.

**Contramedida de processo:** a régua que o kit aplica ao repo-alvo passou a valer para o kit —
comentário que afirma que uma regra é indispensável, ou que nenhuma sabotagem a alcança, vale
exatamente o que vale o probe ao lado dele. Dívida declarada continua sendo limite: a quarta
fixture de terceiro (`tests/fixtures/acli-*.json`) não tem sensor de drift, e isso está escrito no
cabeçalho do `health_provenance` em vez de calado.

**Efeito colateral honesto, não escondido:** `cd49351` corrige a intervenção fantasma para as
missões NOVAS. As antigas continuam com o stub no checkpoint, então o `sdd autonomy --by-mission`
tem um degrau de −1 entre antes e depois — comparável dentro de cada lado, não entre eles. Não
alcança o veredito automático: `kaizen_series` não lê intervenções, só `cmd_autonomy` as imprime.

---

## 2026-08-24 — O log que o runner manda ler é o log que ele apaga

**Problema (Gemba):** o nome do arquivo de log carregava tempo com resolução de segundo e mais
nada, então a segunda sessão de uma fase caía no caminho da primeira. Retentar é justamente o que
põe duas sessões no mesmo segundo — o runner retenta sozinho quando a sessão não moveu o disco —,
e a fase que mais custa é a que mais retenta. O journal registrava as duas sessões, com dois ids,
apontando para UM arquivo: é assim que a perda é provável em vez de suspeita
(`BUG-20260821-session-log-overwritten-in-the-same-second`, Data-Loss/P0).

A família tinha **três** sítios e não um. O `run_check_cmd` — dono do log que o `GATE_WHY` manda o
operador ler — era pior: carregava a hora **sem data**, então dois dias no mesmo horário colidiam
também. Consertar um sítio não fecharia a classe.

**Contramedida:** o nome passa a nomear a INVOCAÇÃO. Em `run_phase`, `${sid:0:8}` — e `$sid`, nunca
`${resume_sid:-$sid}`: duas retentativas de uma mesma sessão retomada compartilham `resume_sid` e
voltariam a colidir. Em `run_check_cmd`, `mktemp` e não um contador, porque TODO leitor pega a fase
como `"$(current_phase)"` e substituição de comando é subshell: o incremento morre com o fork e o
pai reusa o número. O sensor CONGELA o relógio para exatamente os dois formatos de que um nome de
log é feito, com piso provando que o veneno está armado — a colisão passa a ser o regime em que a
asserção roda toda vez, em vez de uma corrida que ela normalmente perde.

| | Antes (`ba1653c`) | Depois (`7395c78`) |
|---|---|---|
| duas sessões de uma fase no mesmo segundo | **1** transcript em disco, 2 linhas de journal apontando para ele | **2** transcripts, cada linha apontando para o seu |
| execuções do `TEST_CMD` num `sdd run` × arquivos de log | 4 × **1** | 4 × **4** |
| bugs `open` em `docs/qa/bugs/` | 1 de 6 (trancava o `gate_QA` deste repo) | **0** de 6 |
| catálogo de mutação | 129 de 129 | **138** de 138 |
| achados abertos no `TODO.md` | 75 | **74** (D15 tirou 2, o memo do `run_check_cmd` acrescentou 1) |

⚠️ **O `sdd health` cobrou o preço que ele existe para cobrar, na mesma missão.** A primeira
passada respondeu `score: 136 caught, 0 known gap(s), of 138` — e os dois faltantes **não** eram
sobreviventes: eram `did not apply`. O I6 partiu o parágrafo de exclusão do `sdd autonomy` em duas
metades e o array deixou de terminar em colchete, apodrecendo a âncora de
`mut_AUTONOMY_exclusions_split` e `_glued`. Duas mutações que não sabotavam nada, com cara de
cobertura. É a mesma classe do `103 caught of 104` que ficou dias na `main` entre os PRs #12 e #13,
e desta vez foi pega antes do PR — que é exatamente o que o carimbo de `c962e2e` comprou.

---

## 2026-08-19 — Os quatro instrumentos que certificam o fecho de uma missão param de afirmar o que não mediram

**Problema (Gemba):** quatro instrumentos decidem se uma missão do kit fechou, e **três deles
falharam abertos** quando a sessão de planejamento os sondou um por um contra a `main` em
`7957a85` — afirmaram ter medido o que não mediram. Nenhum é hipótese; os três foram reproduzidos
no terminal, e o quarto tem instância na história do repo:

- `sdd health` exigia `0 known gap` e **nunca** comparava `caught` com `of`, então
  `score: 103 caught, 0 known gap(s), of 104` — um catálogo com sobrevivente vivo — imprimia `ok`,
  na linha que o operador lê no comando que virou o dono único do catálogo;
- `gate_REVIEW` lia a coluna `Grade` e nunca a `Rationale`: `A` em toda linha com `PREENCHER` em
  toda justificativa comprava o selo. Instância viva no próprio repo —
  `docs/handoffs/20260818-lote-facil/40-review-r1.md:8` registra, no campo `gate:`, que a r1
  deixou `PREENCHER` nas sete;
- `tests/run-all.sh --list` imprimia uma linha que não é passo e saía 0 tendo rodado nada: um
  `TEST_CMD` com `--list` faria **todo gate do runner** passar na hora, com log plausível;
- e **nada automático rodava o catálogo** desde que ele virou opt-in. A conta chegou entre os PRs
  #12 e #13: `f6ecf73` apodreceu a âncora de `mut_HEALTH_grade_table_blind`, os gates rodaram a
  suíte rápida, responderam verde, e a `main` carregou `103 caught of 104` por dias — até alguém
  digitar o comando.

Os quatro são o mesmo mecanismo, e é o que este repo mais paga: **rótulo aceito no lugar de
artefato**, dentro dos próprios instrumentos que existem para recusar rótulo.

**Contramedida:** três apertos locais e um desenho. O `sdd health` compara os dois números do mesmo
`score:` e ganha piso de tamanho (catálogo esvaziado não certifica nada); o `--list` imprime só
passos e um `TEST_CMD` que o carregue é recusado; o `awk` do `gate_REVIEW` passa a ler `f[4]` e a
recusar placeholder — na tabela e no campo `gate:` do frontmatter. O quarto troca rótulo por
artefato: `sdd health` **carimba** o conteúdo que mediu, `gate_PR` **exige** o carimbo. O gate não
roda o catálogo — foi isso que `4c86712` desfez —, ele pede o recibo. Desenho e alternativas
descartadas em [`docs/adr/0004`](docs/adr/0004-mutation-catalogue-owner-stamp-not-ci.md).

| | Antes (`7957a85`) | Depois (`3407fe3`) |
|---|---|---|
| `sdd health` sobre `score: 103 caught, 0 known gap(s), of 104` | `ok` | `health_bad`, nomeando os dois números |
| `sdd health` sobre `score: 0 caught, 0 known gap(s), of 0` | `ok` — **e gravava carimbo** | `health_bad`, pesando o `of N` contra as definições `mut_*()` em disco |
| `gate_REVIEW` sobre `A` em toda linha + `PREENCHER` em toda `Rationale` | **passa** | recusa, nomeando o critério ofensor |
| `tests/run-all.sh --list` com um `PATH` sem `shellcheck` | 1 linha da saída não é passo | toda linha é passo (o aviso foi para a stderr) |
| `TEST_CMD="tests/run-all.sh --list"` | aceito | recusado pelo `sdd health` |
| quem cobra o catálogo de mutação | ninguém automático | `gate_PR`, pelo carimbo, como último requisito |
| catálogo | **104** mutantes | **118**, `score: 118 caught, 0 known gap(s), of 118` |
| gates com mutação no catálogo | 8 de 8 | 8 de 8 (mantido; 14 mutantes novos) |
| `TEST_CMD` | 1m24s | **1m41s** (+20%), 487 asserções `ok`, rc 0 |
| catraca `todo-findings` | 72 | **89** |
| achados fechados com `RESOLVIDO por <hash>` | — | **4** (`7a6653b`, `2f71646`, `9fa5b0b`, `c962e2e`) |

**O que a missão descobriu sobre si mesma, e é o número que mais vale:** a fase QA andou as
jornadas que os quatro incrementos criaram e achou **três defeitos dentro do próprio diff**, todos
da classe que a missão existe para acabar — um piso que fazia o `sdd health` carimbar sobre um
catálogo vazio (`score: 0 caught … of 0` respondia `ok`), um carimbo escrito numa árvore e cobrado
noutra (`gate_PR` insatisfazível **para sempre** em worktree), e um selo de rodada que uma tecla
vencia (`TODO:` com dois-pontos não era `TODO`). A r1 do REVIEW achou mais sete, **um deles criado
pela própria rodada**. Sete incrementos, não quatro. O laço QA⇄EXEC pagou por si.

⚠️ **O relógio subiu 20% e nenhuma asserção foi cortada.** A tabela de riscos do plano previa
converter em achado um `TEST_CMD` acima de ~60 s; o limiar já estava vencido **antes** da missão
começar, então media a coisa errada e foi registrado como tal em vez de virar corte. Quase todo o
delta está em invocações reais de `sdd health` e `sdd phase` dentro dos fixtures — asserção
diferencial que anda o CLI de verdade custa relógio, e é exatamente por isso que ela mede.

**Custo:** 9 sessões pagas até o fim da REVIEW, **US$ 113,57**
(`jq` sobre `.sdd/logs/20260819-fecho-que-nao-mente/*.json`). A rodada completa do catálogo levou
**20 min** para 118 mutantes nesta máquina, contra 30 min para 110 medidos na fase QA — cresceu o
catálogo e caiu o relógio, e a diferença é contenção de CPU, não melhoria. Nenhum dos dois números
serve como estimativa de runner de CI, que segue sendo decisão do humano.

---

## 2026-08-19 — A mutação sai do `TEST_CMD`, e a fase REVIEW volta a caber numa sessão

**Problema (Gemba):** a entrada abaixo mede a suíte em **17 a 21 minutos** e chama a decisão sobre
o alvo "<30 s" da D7 de pendência do humano. Ela deixou de ser cosmética no mesmo dia: **três
sessões de REVIEW seguidas morreram encerrando o turno com as palavras *"waiting for the suite"***.
Numa sessão headless `claude -p`, terminar o turno **é** terminar a sessão — o agente dispara a
suíte, a ferramenta devolve "rodando em background", ele diz "aguardando", e não há quem o acorde.
As três tinham feito o trabalho analítico e morreram antes de commitar: **US$ 104 de revisão que
não compraram revisão**. Observado num gate real: `tests/run-all.sh` segurando a árvore por
**10m39s** depois de a fase que o pediu já ter terminado. A causa é estrutural e está no código —
`tests/check-mutation.sh:1401` verifica **cada** mutante rodando a suíte inteira numa sandbox.

**Contramedida:** o catálogo passa a ser **opt-in** (`tests/run-all.sh --with-mutation`) e ganha um
dono único: o `sdd health`, que é o comando escrito para perguntar se o kit ainda mede o que diz
medir. **Nada foi afrouxado** — as 102 asserções continuam todas, e todas continuam sendo cobradas.
Muda **quem** cobra e **quando**. O precedente já estava escrito no `CLAUDE.md`, com o mesmo
argumento, para a catraca do backlog.

| | Antes | Depois |
|---|---|---|
| `TEST_CMD` — o que todo gate roda | a suíte completa | **44,3 s**, `suite green`, rc 0 |
| suíte completa, agora só no `sdd health` | — | **298 s** (4m58), rc 0 |
| quem cobra o catálogo | todo gate, toda fase, toda missão | `sdd health`, uma vez |
| catálogo | `100 caught of 101` — **VERMELHO** | `102 caught, 0 known gap(s), of 102` — **verde** |
| asserções `surface:` | 0 | **2**, com 3 probes adversariais e 1 mutação |

⚠️ **O relógio, com as condições ao lado — e elas não batem.** A entrada abaixo mediu a mesma suíte
completa em **1051,60 s e 1268,31 s**; as três medições desta seção deram **298–306 s**. É 3,4×, e
a diferença é a máquina: aquelas foram tiradas com sessões do pipeline rodando, estas com a máquina
parada. Nenhum dos dois números está errado e nenhum foi apagado — a nota abaixo já avisava que
esse par oscila ~2× sob carga, e este é o terceiro ponto confirmando que **o número da suíte não é
uma constante, é uma função da carga**. O que muda de verdade não é o relógio da suíte cheia: é que
o **caminho crítico** (todo gate de toda fase) deixou de contê-la.

**O vermelho da entrada abaixo está fechado, e o conserto foi a lição 3 dela.** O
`mut_LEDGER_repo_root_cdpath_leak` sabotava só o caminho rápido, e o fallback pré-2.31 — que
carrega o próprio `CDPATH=''` — reparava a sabotagem. Agora ele sabota **as duas grafias**, porque
a propriedade defendida ("nenhum `cd` desta função lê `CDPATH`") tem dois sítios. Provado nos dois
sentidos em sandbox fiel: controle rc 0, mutante rc 1 matando **as duas** asserções `cdpath:`.

**A lacuna que este movimento abre, dita em voz alta:** este repo não tem `.github/workflows/`, então
o catálogo passa a rodar **só quando alguém digita `sdd health`**. Não é hipótese — aconteceu dentro
desta própria sessão: a suíte rápida respondeu `suite green` rc 0 enquanto o catálogo estava
vermelho, e só o `sdd health` viu. Está no `TODO.md` com a direção (CI, ou `gate_PR` chamando
`sdd health` uma vez por missão).

**A lição, escrita para não renascer:** **um instrumento que não cabe na paciência de quem o roda
deixa de ser instrumento.** O alvo "<30 s" da D7 parecia higiene e era um requisito de
funcionamento: passado certo limite, a suíte não fica "lenta" — ela torna uma fase inteira
**insatisfazível**, e o modo de falha não se parece com lentidão, se parece com um agente
desistindo. O sintoma custou US$ 104 e três sessões antes de alguém perguntar quanto tempo a suíte
levava. Instrumento tem orçamento de tempo como tem orçamento de dinheiro, e ele se mede.

---

## 2026-08-19 — O `sdd health` para de morrer calado, duas classes somem do repo, e o lote barato prova que barato não é

**Problema (Gemba):** o comando que existe para responder *"o kit ainda mede o que diz medir?"*
**morria na atribuição** e não dizia nada. `cmd_health` capturava saída com `out="$(cmd)"` sob
`set -euo pipefail`, então qualquer `cmd` com rc≠0 matava o script uma linha antes do `health_bad`
que existia para relatar — e para `grep`/`find`/pipeline com `pipefail`, "rc≠0" é só "não achou
nada". Quatro sondas com o runner real (kit copiado, controle verde antes de cada sabotagem)
mostraram o pior caso: **com a suíte vermelha, `sdd health` imprimia uma linha de cabeçalho e saía
rc 1**, e os quatro checks seguintes nunca rodavam. A suíte vermelha é exatamente o caso que ele
existe para relatar. Junto vinham 17 outros achados do backlog barato, agrupados **por mecanismo**.

**Contramedida:** cinco incrementos, cada um varrendo uma família inteira com a asserção morando
num sensor que já existia — e a regra transversal de que asserção nova entra **com mutação**.

| | Antes (`9207b4d` = `main`) | Depois (HEAD `chore/lote-facil`) |
|---|---|---|
| `sdd health` com a suíte vermelha | **uma linha, rc 1**; checks 2–5 nunca rodam | diz `suite red` **e segue** — os 4 modos de falha ditos em voz alta |
| Capturas desguardadas na região do `sdd health` | 5 conhecidas — e 11 que ninguém tinha visto | **0 de 16 censuradas**, com a regra `guard:` enumerando a região inteira |
| `cd` relativo sem `CDPATH=''` | consertado em 1 função; **19 sítios vivos** no repo | **0**, com scanner durável (RULE 2 do `check-pipefail.sh`) |
| `ledger_repo_root` | 2 `cd` + `pwd -P` + guarda de `CDPATH` | caminho rápido sem `cd` (`--path-format=absolute`), grafia antiga como fallback pré-2.31 |
| Artefato com gate e **sem** template | 1 — o `40-review-r<N>.md` | **0** — `templates/review.md`, 23 asserções derivadas do próprio `gate_REVIEW` |
| Asserções `abort:` / `cdpath:` / `output:` / `covered:` / `rule:` / `guard:` | 0 / 2 / 6 / 0 / 0 / 0 | **4 / 4 / 9 / 5 / 5 / 1** |
| Catálogo de mutação | `score: 81 caught, 0 known gap(s), of 81` — **verde** | `score: 100 caught, 0 known gap(s), of 101` — **VERMELHA** (abaixo) |
| Achados abertos no `TODO.md` | 56 | **74** — 18 fechados, 36 nascidos, catraca movida em todo commit |
| `sdd preflight` em git < 2.31 | não olhava | `warn` com o remédio certo; o kit responde correto pelo fallback |
| `tests/run-all.sh` — mesma máquina, em sequência, nada mais rodando | **1268,31 s** (21m08s) | **1051,60 s** (17m32s) — mais rápido com 20 mutantes A MAIS |

⚠️ **O relógio: um par não é tendência, e o que vale é o absoluto.** O `CONTEXT.md` já registra que
esse mesmo par oscilou ~2× entre passadas dos MESMOS commits sob carga, então "ficou 17% mais
rápido" não é conclusão que este número sustente. O que ele sustenta é a ordem de grandeza, e ela
é sólida nos dois lados: a suíte leva **17 a 21 minutos**, ou seja **~35×** o alvo "<30 s" da D7 —
não os 4,9× que o `CONTEXT.md` dizia nem os "~3m30s" que o `01-plano.md` desta missão registrou
como contexto verificado, que estavam **6× errados**. Como todo gate roda a suíte, `sdd phase` e
`sdd why` bloqueiam por ~20 minutos. A decisão de subir o alvo ou aposentá-lo continua do humano.

**O número que reprova, e ele fica aqui porque medir só o que deu certo é o oposto de kaizen:**
a suíte está **vermelha no HEAD**. `mut_LEDGER_repo_root_cdpath_leak` sobrevive — ele sabota
apenas o **caminho rápido**, e o fallback que o conserto da r2 (`75c9d2a`) acrescentou **repara a
sabotagem**: a guarda de forma esvazia o valor envenenado e o fallback resolve a identidade certa
com `CDPATH=''`. Reproduzido em sandbox com o `sed` provado antes de qualquer conclusão: sã e
mutante dão saída **byte a byte idêntica** no `check-autonomy.sh`, rc 0 nas duas. A asserção virou
decoração — o modo de falha que o catálogo existe para pegar, e ele pegou. **Três medições
independentes**, não uma: duas suítes completas (rc 1, `100 of 101`, sempre o MESMO sobrevivente) e
o par diferencial em sandbox. Registrado no `TODO.md` com a reprodução; a linha para aqui.

> **FECHADO** pela entrada de cima, no mesmo dia e na mesma branch: o mutante passou a sabotar as
> duas grafias e o catálogo voltou a `102 caught, 0 known gap(s), of 102`, rc 0. O parágrafo acima
> fica como está — ele é o registro de que o instrumento pegou a si mesmo, e apagá-lo trocaria a
> prova pelo resultado.

**Custo:** **US$ 176,48** em 11 sessões de fase (5 EXEC + 1 re-entrada + 1 QA + 4 REVIEW), contra
US$ 48–88 das seis missões anteriores do kit sobre si mesmo. **Duas a três vezes mais caro**, e o
motivo é medido: 4 sessões de REVIEW a ~US$ 34 cada, porque o diff que a revisão tinha de ler era
de 28 arquivos e +3.566 linhas.

**As três lições, escritas para não renascerem:**

1. **Probe por sítio prova os sítios que têm probe.** O I1 fechou cinco capturas uma a uma e
   declarou a família varrida; a r2 achou **onze** ainda vivas no mesmo comando, três reproduzidas
   ponta a ponta. A saída não foi um sexto probe — foi **enumerar a região**, que é o que torna a
   classe irreinstaurável: quem escrever uma captura pelada ali reprova na linha que escreveu.
   Vale igual para o `cd` relativo: o item do backlog contava 14 sítios e havia 19.
2. **A re-derivação acha MAIS trabalho, não menos, e o plano tem de contar com isso.** As 18
   âncoras foram re-derivadas no planejamento (8 estavam podres, a pior por ~615 linhas) e mesmo
   assim **cada incremento achou sítio extra**: I1 fechou 5 e não 4, I2 fechou 19 e não 14, I3
   precisou de 5 mutações e não 3, I4 de 7 e não 5. Alvo de backlog escrito como número absoluto
   (56 → 38) é frágil por construção: o lote fechou seus 18 exatamente como prometido e o arquivo
   terminou em 74, porque os instrumentos da própria missão acharam 36 coisas novas — 29 delas numa
   rodada de revisão só. O que o plano previu certo foi o **risco**; o que ele escreveu errado foi
   a **métrica**.
3. **Conserto que restaura um caminho antigo tem de restaurar a mutação junto.** A r2 estava certa
   em trazer a grafia velha de volta como fallback — devolver vazio era um segundo defeito com a
   roupa do primeiro, e matava o ledger em git 2.25/2.30. O que faltou foi perguntar **o que o
   caminho novo tornou inobservável**: com o fallback consertando a sabotagem, o mutante que
   guardava a classe deixou de medir. Caminho de código que só roda num ambiente que a máquina de
   teste não tem precisa da mutação sabotando **as duas grafias**, ou de duas entradas.

---

## 2026-08-18 — O Lote 0 do backlog barato: dez itens saem, e três deles por decisão, não por código

**Problema (Gemba):** a triagem de 2026-08-17 (`docs/handoffs/lote-facil-20260817.md`) separou dos
66 achados abertos os que satisfazem quatro critérios ao mesmo tempo — defeito já **localizado e
reproduzido**, direção mecânica, sensor já existente onde a asserção vai morar, e nenhuma decisão
humana pendente. Dez deles não tocam lógica nenhuma: são prosa, comentário e registro.

Um era **insatisfazível em sessão headless**: o `.claude/napkin.md` é lido toda sessão, afirmava
uma catraca vencida (`~33s` e `mutação 30/30` contra os `~3m30s` e `81/81` reais) e **nenhuma fase
consegue editá-lo** — o harness barra `.claude/` como caminho sensível, e duas fases DOCS já
queimaram sessão descobrindo isso. Runbook que afirma um score menor do que o real convida a
próxima sessão a aceitar o menor. Por isso este lote foi feito à mão, com humano presente, **antes**
de a missão do lote grande ser planejada.

**Contramedida:** sete itens fecharam por conserto e três por **decisão registrada aqui**. Item
aberto não tem memória durável em nenhum outro lugar — apagá-lo sem escrever o motivo é exatamente
como o mesmo achado renasce daqui a três missões, e foi esse o argumento que já recusou uma
política de expiração automática para o `TODO.md`.

| | Antes (`48fa034` = `main`) | Depois |
|---|---|---|
| Achados abertos no `TODO.md` | 66 | **56** |
| `todo-findings` em `tests/health-baseline.txt` | 66 | **56**, movido no mesmo commit |
| Itens fechados por conserto / por decisão registrada | — | **7 / 3** |
| `.claude/napkin.md` | versionado, com número vencido e ineditável por qualquer fase | **fora do versionamento** — runbook local, por máquina |
| A rubrica do auto-teste do `CLAUDE.md` | `grep -l selftest tests/` responde **6** para uma frase que afirma **cinco** | `grep -l '^selftest()' tests/*` → **5**, com o sexto (`jobs_selftest()`, do escalonador) nomeado |
| `KAIZEN_LOG.md:261` — asserções `ok` | `490`, a contagem solta `^  ok` | **435**, pela âncora de 4 espaços, com o comando escrito ao lado |
| Como sincronizar `.claude/agents/` | dito só na mensagem de falha do preflight | **na regra**, com `sdd install --force` nomeado |
| "Contexto não é gargalo" | fé — medido no piloto SQ-97 e nunca escrito | **registrado** em `docs/pipeline.md` e `config/schema.md`: picos de 184k–289k tokens, **zero compactações**, `--autocompact` como alavanca disponível e não usada |
| Âncoras podres re-derivadas antes de editar | — | **2 de 7** — `bin/sdd:1533`→`:2301` (~768 linhas de defasagem) e `check-gates.sh:229`→`:265` |

**As três decisões, escritas para não renascerem:**

1. **A regra da âncora do `check-todo.sh` é satisfeita por código inline no título — fica como
   está.** Apertá-la exige uma forma que os dados reais não sustentam: `git worktree` e
   `KAIZEN_LOG` são âncoras legítimas e não têm `arquivo:linha`. Medido no achado original, **45
   dos 46 itens passariam com o `file:line` apagado** — mas o custo de discriminar é reescrever a
   âncora de todos num formato que boa parte dos casos recusa. O que de fato importa (achado
   fechado escondido no arquivo) já é coberto pela regra 2 e pela lista-branca. Reabrir só se
   aparecer um caso real de âncora inventada passando despercebida.
2. **O corte UTF-8 de `${var:0:200}` (`bin/sdd:756,777`) segue sem asserção.** O risco **degrada
   em vez de quebrar alto**: no jq 1.7 o byte inválido vira U+FFFD e sobrevive. Alcançar um
   `gate_why` longo e multibyte pelo caminho real exige fixture com ID de incremento gigante, e o
   próprio achado já dizia que pode não valer o custo. Reabrir se esse corte passar a alimentar
   algo que quebre alto em vez de degradar.
3. **O `def usd` com entrada negativa (`bin/sdd:2524`) é inalcançável hoje.** `round` e `floor` de
   fato não fecham — `-1.5` sai `-2.50`, `-0.005` sai `-1.99` —, mas **nenhum escritor do ledger
   produz `cost_usd` negativo**. Guardar contra um mundo que o escritor não produz custa um fixture
   que só um teste consegue montar, para proteger uma linha ilegível no caso em que alguém edite o
   ledger à mão. Reabrir no dia em que um custo negativo tiver origem legítima (estorno, crédito).

**Custo:** 1 sessão com humano, **zero sessões de fase** — nenhum `sdd run`, nenhum gate, nenhum
token de agente. É o argumento do lote: item barato fechado à mão não paga o pedágio de uma missão,
e o que sobra para a missão são só os 18 itens que precisam de código e sensor.

⚠️ **A catraca cobra este lote nos dois sentidos, e isso é o desenho.** Ao passar de 66 para 56 o
`sdd health` reprova por `finding outside the baseline` **e** por `stale baseline` até
`todo-findings` descer para 56 no **mesmo commit**.

## 2026-08-17 — O backlog para de crescer calado, e o `sdd health` ganha o primeiro sensor da sua vida (missão `20260817-catraca-do-backlog`)

**Problema (Gemba):** a triagem de 2026-08-17 comparou `git show 8ca54b8:TODO.md` contra o HEAD e
achou o kit registrando dívida ~1,8× mais rápido do que a fecha:

| | itens | linhas |
|---|---|---|
| início da sessão (`8ca54b8`) | 56 | 449 |
| HEAD daquele dia (`6d68dfc`) | **68** | 544 |

**16 itens foram fechados e apagados** com prova por `git merge-base` (5 do PR #4, 7 do #5, 4 do
#6) e o arquivo mesmo assim cresceu, porque **29 nasceram**. Duas missões completas, 24 sessões,
US$ 234,07 — e **nenhum instrumento dizia**: `tests/check-todo.sh` mede forma, âncora, data e teto
de 8 linhas com 75 probes, e passa verde em 68 itens exatamente como passaria em 680.

O lugar certo para a catraca era o `sdd health`, e ele tinha um buraco próprio: **nenhum sensor da
suíte executava `cmd_health`**. Os dois hits de `grep -l 'sdd health' tests/` eram comentário. O
comando que existe para responder "o kit ainda mede o que diz medir?" era o único do runner sobre
o qual ninguém perguntava a mesma coisa — e já tinha mordido: duas checagens dele nasceram com a
lógica invertida pelo `pipefail` e foram pegas à mão, não por sensor.

**Contramedida:** zero mecanismo novo. `cmd_health` extrai o número da linha que o `check-todo.sh`
já imprime na stdout da suíte que ele **já** captura, chama `health_finding "todo-findings $N"`, e
o `health_ratchet` que já existia faz o resto **nos dois sentidos**. A catraca mora no `sdd health`
e **não** no `TEST_CMD`, de propósito: um teto dentro da suíte reprovaria `gate_EXEC`/`QA`/`REVIEW`
de toda missão em voo, inclusive a que acabou de registrar o achado. Antes disso, o sensor que
faltava — sem ele a catraca nova nasceria como código não medido, que é a falha aberta que esta
casa proíbe.

| | Antes (`6d68dfc` = merge-base de `main`) | Depois (`8535a3a`) |
|---|---|---|
| Sensores da suíte que executam `cmd_health` | **0** — os 2 hits em `tests/` eram comentário | **1** (`tests/check-health.sh`, 8 asserções + 6 probes de regra de documento) |
| Contagem de achados abertos do `TODO.md` | medida a cada suíte, **nunca congelada**: 56 → 68 em duas missões sem nada dizendo | congelada como `todo-findings 76`, catraca mordendo nos dois sentidos |
| Checks numerados do `cmd_health` | 7 | **8** |
| Dívidas conhecidas na baseline | 6 | **7** |
| Score de mutação | 70 caught, 0 gap, of 70 | **81 caught, 0 gap, of 81** |
| Sensores na suíte | 12 | **13** |
| Asserções de sensor numa passada verde (`grep -c '^  ok    '`) | 509 | **534** |
| Suíte, passadas sequenciais na mesma máquina quieta | 155,97 s | **210,81 s** |
| `sdd autonomy`, coluna de dinheiro | `US$ 2` e `US$ 1.5` — casas variáveis | `US$ 2.00`: **0** células fora de duas casas |
| `sdd autonomy`, ordem das versões | lexicográfica, **e discordando do juiz** sobre qual é a mais recente | ordem de primeira aparição na população do juiz (`on_axis`) |
| `sdd autonomy`, recusa de ledger ilegível | **uma** frase para dois defeitos distintos | duas (`malformed row` × `unreadable row … valid JSON but not an object`) |
| `sdd autonomy`, bloco "no data" | duplicado byte a byte em dois pontos | um helper, uma voz (`autonomy_no_data`) |
| Achados fechados com hash no corpo | — | **10**, os 10 verificados ancestrais de HEAD |

**A catraca cobrou a própria missão, três vezes, e é esse o resultado.** A contagem foi de 68 para
**76**: o EXEC registrou 4 achados novos (dois abortos calados do `sdd health` com o fixture
hermético, um terceiro na checagem do `score:`, um `moved` sem asserção), a REVIEW r1 registrou 3 e
a fase DOCS 0. Cada um deles moveu a baseline **no mesmo commit** — que é a regra funcionando, sem
exceção para a sessão que a escreveu. Os 10 itens fechados **continuam contando**: eles saem na
varredura pós-merge, provados por `git merge-base --is-ancestor <hash> main`, e é lá que a catraca
cobra a baseline de novo. O número que este arquivo registra é o real medido, nunca o desejado.

**⚠️ A linha das asserções vale 509 → 534, e não 490 → 589.** É a mesma armadilha de instrumento
que a entrada anterior catalogou, e ela reapareceu **dentro desta missão**: o `40-review-r1.md`
registrou "589 asserções `ok` (eram 533 no fim do EXEC)" comparando `grep -c '^  ok'` com a âncora
de **quatro** espaços. `589 − 534 = 55`, exatamente as linhas `  ok   ` de **três** espaços que o
runner imprime dentro dos fixtures. Os dois lados desta tabela foram medidos com a âncora de quatro
espaços, em passadas sequenciais, `main` num worktree descartável — e o handoff da r1 ficou
anotado em vez de reescrito. O item que pede o comando ao lado do número segue aberto.

**⚠️ E o custo do sensor novo também estava medido no instrumento errado.** O EXEC registrou a
suíte indo de 2m34s para **7m15s** e concluiu contenção super-linear. Não reproduz: em máquina
quieta e passadas sequenciais o par é **155,97 s → 210,81 s** (+55 s), já com 11 mutações a mais no
mesmo diff. O mecanismo é real — sensor novo é **multiplicador**, roda uma vez por mutante —, mas o
número que decide o alvo da D7 é este, e o item do `TODO.md` foi corrigido em vez de duplicado.

**O que ficou sabido e não foi consertado:** quatro abortos calados da mesma família dentro do
`sdd health` (`find` em diretório ausente, baseline sem linha viva, a checagem do `score:` e a
suíte vermelha imprimindo só o cabeçalho) — todos com âncora e direção no `TODO.md`, nenhum
alcançável pelo escopo desta missão, e todos achados **pelo fixture hermético do sensor novo**, que
é o argumento do I1 se pagando na primeira volta.

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

### O conserto trocou a unidade, e a fonte da verdade driftou de si mesma

O achado desta fase DOCS, e o mais barato de repetir: o F1 da r3 trocou a unidade do
`degenerate_axis` de **sessões** para **missões** — porque é `missions_with_session` que o piso
conta, e duas sessões da mesma missão deixavam o piso igualmente insatisfazível enquanto calavam o
campo. O `jq` mudou, com comentário medido. Tudo o que o **enuncia**, não: **oito** dos dez lugares
seguiam dizendo "exactly one session" horas depois — e quatro deles estão dentro do `bin/sdd`. O
comentário duas linhas **acima** do predicado dizia sessões, e o `warn` que o humano lê imprimia "the
recent kit versions each bought exactly one session" enquanto o código ao lado contava missões.

| | Antes (`5056709`) | Depois (esta fase) |
|---|---|---|
| Lugares que enunciam a unidade do eixo | 6 conhecidos | **10** nomeados: `docs/failure-modes.md` estava fora do inventário, e contar `bin/sdd` como **um** era grosseiro — ele a enuncia em três comentários e na frase que imprime |
| Deles com a unidade certa | **1 de 10** (só o `jq`; o `CONTEXT.md` não enunciava nenhuma) | **10 de 10** |
| Vezes que o item "schema sem sensor de drift" cobrou preço | 5 | **6** |

A r3 fechou em Grade A afirmando "os seis lugares dizem a mesma coisa", e estava de boa-fé: ela
consertou o sexto que a r2 deixara velho. O que nenhuma rodada podia ver é que o **próprio conserto
dela** criou drift novo em oito — mudar unidade é mudar contrato, e contrato quebrado em N lugares
é o modo de falha mais caro deste kit, escrito na `CLAUDE.md` desde a primeira missão. Duas leituras
que valem mais que "revisar melhor":

- **um arquivo não é um lugar.** "O código é a fonte da verdade" some quando o mesmo arquivo carrega
  cinco enunciados da mesma regra — o predicado, três comentários que o explicam e a frase que imprime.
  Foi um comentário mentiroso a **um `sed -n` de distância** do predicado que sobreviveu a três
  rodadas de review, e a frase impressa é a única das nove vozes que o humano lê;
- **âncora podre pagou por si.** Os dois drifts de dentro do runner apareceram porque uma âncora
  `bin/sdd:2735` do `TODO.md` estava velha e caiu **no comentário errado**. Seguir uma âncora até o
  lugar errado achou o que a leitura dirigida não achou.

E a conclusão estrutural é a mesma de sempre: **este repo não tem sensor de drift entre os campos do
`jq` e o que os promete**, e enquanto não tiver, a conta volta. Sexta cobrança, com as dez âncoras e
a direção no `TODO.md`.

### O que ficou sabido, e não foi consertado

- **A quinta métrica do `00-missao.md` não foi cumprida, e isso é registro, não omissão.** O plano
  previa 5 itens do `TODO.md` com `RESOLVIDO por <hash>`; são **4**. O quinto — o lembrete
  pós-pipeline que manda o humano a um comando que enxerga números diferentes — **não é fechado por
  `--all-repos`**: o lembrete só é chamado de `cmd_run`, e `sdd run` não tem a flag. Estampá-lo
  seria rótulo sem artefato, exatamente o que o kit existe para proibir. O item segue aberto com o
  motivo escrito nele, e fechá-lo exige responder se o juiz pode pesar linha de outro projeto —
  possível **ADR 0004**, e é ele que destrava o I13.4.
  - *Nota corretiva (2026-08-21, missão `20260820-missao-porteira`):* o número **0004** foi
    consumido depois disto pela decisão do carimbo de mutação
    ([`docs/adr/0004`](docs/adr/0004-mutation-catalogue-owner-stamp-not-ci.md)). A ADR do eixo do
    juiz segue **adiada, sem número**, para depois do piloto — o registro acima fica como está,
    porque é histórico.
- **Um marcador de fechamento estava invisível para a triagem.** O `RESOLVIDO por` do item do eixo
  degenerado tinha quebra de linha entre as duas palavras, e a triagem do kaizen grepa a frase
  inteira: item fechado que a próxima sessão leria como aberto. Reencapado nesta fase. A lição é a
  de sempre nesta casa — convenção lida por `grep` precisa de sensor, e esta não tem.
- **O `sdd kaizen` recusa rodar de um worktree do próprio kit** pela mesma pergunta por worktree que
  o ledger acabou de deixar de fazer, noutra porta (`bin/sdd:2735`). Está no `TODO.md`, achado pela
  EXEC do I4 — a classe fechada num sítio e viva no vizinho.
- **O `TODO.md` aceita duplicata, e a fase DOCS provou isso contra si mesma.** Abri um item sobre a
  contagem de `selftest` da `CLAUDE.md` (cinco escritos, seis medidos) e ele **já estava lá**, aberto
  pela fase DOCS da missão anterior um dia antes. O `tests/check-todo.sh` mede forma, âncora, data e
  teto — nunca duplicata —, então as duas teriam ficado verdes lado a lado, cada uma parecendo
  confirmar a outra. Retirado. A conduta cabe numa linha e não precisa de sensor: **grepar o tema
  antes de abrir item.**
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
| Asserções `ok` numa passada verde — `grep -c '^  ok    '` na saída de `tests/run-all.sh` | 457 (⚠️ instrumento não registrado) | **435** |
| Suíte, mesma máquina, duas passadas por lado | 1:45,74 / 1:47,49 | **2:27,10 / 2:27,59** (+39%) |
| Os 4 itens da métrica no `TODO.md` | abertos | **RESOLVIDO por** `96a1f68`, `b3b8c2f`, `3ffa586`, `2510c3c` |

⚠️ **A linha das asserções foi corrigida em 2026-08-18: dizia `490`, mede `435`.** `490` saiu da
contagem solta `^  ok`, que soma 55 linhas de **três** espaços impressas pelo runner *dentro* dos
fixtures; a grandeza desta casa é a âncora de **quatro** (`grep -c '^  ok    '`), a mesma que o
`templates/checkpoint.md` exige dos Checks. O tree é o mesmo — `git diff c821ade..96a9bf1 --
tests/ bin/sdd` é vazio —, então o degrau era do instrumento, não do trabalho. O offset é
**estrutural e estável**: medido de novo em 2026-08-18, num tree bem diferente (81 mutantes contra
55), a passada verde dá `589` solto contra `534` na âncora — **os mesmos 55 de diferença**, o que
confirma o `490 → 435` por medição independente em vez de por afirmação. O `457` do "Antes"
vem da entrada de `20260816-kit-como-alvo` e **não foi re-medido**: a série `408 → 457` não é
comparável com o `435` desta linha. É exatamente por isso que toda linha nova deste arquivo nomeia
o comando ao lado do número, como a do `score:` já fazia de graça.

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
