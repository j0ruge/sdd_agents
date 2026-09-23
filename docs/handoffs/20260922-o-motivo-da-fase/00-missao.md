---
missao: 20260922-o-motivo-da-fase
titulo: o runner diz por que escolheu a fase, lê a célula de commit como o humano a lê, e para a linha quando a sessão não tem trabalho em vez de comprar a próxima
data: 2026-09-22
versao: n/a — JIRA_ENABLED=false
branch: feat/o-motivo-da-fase
aprovacao: humano-2026-09-22
adr: docs/adr/0010-o-motivo-da-fase.md
ddd: n/a
---

# Missão — o motivo da fase

> Escrito pelo `sdd-planner` com o humano presente (grill de 2026-09-22, respostas repassadas
> verbatim pela sessão coordenadora a partir do AskUserQuestion). É a única fonte da **intenção**;
> o `01-plano.md` é a fonte do **como**.
>
> ⚠️ **Execução INTERATIVA** (Opus + `superpowers:executing-plans`), **nunca `sdd run` no kit** —
> memória do projeto: o `claude -p` aninhado herda o socket do harness e morre, e o kit se
> sabotaria editando o `bin/sdd` que o executa.

## Problema (Gemba)

Um incidente, três issues abertas no mesmo minuto (#54, #55, #56 de `j0ruge/sdd_agents`). Na missão
`20260921-amep-backend-0-1-0` do `lighthouse_project` (kit em `ea39868`), o runner abriu sessões EXEC
**sem nenhum trabalho**. Cada uma não achava linha `pending`, fazia um commit no-op
(`docs(checkpoint): registra sessão EXEC sem incremento pendente`) e devolvia a bola. Foram US$ 1,94
em duas sessões (`93cc8e56…` 56 s US$ 0,978; `dd62e7f9…` 41 s US$ 0,964) antes de um humano matar a
terceira à mão. Sem essa intervenção, o laço só parava no `BUDGET_MISSION_USD`. A cadeia causal foi
medida em `147add7`:

1. **#55 — a célula com crase.** O executor escreveu `` | done | `19c2c89` | `` e as outras 27
   linhas estavam nuas. `checkpoint_rows()` (`bin/sdd:434`) apara espaço (`gsub` em `bin/sdd:457`),
   mas não crase. O `gate_EXEC` passa `` `19c2c89` `` ao `git cat-file -e` (`bin/sdd:941`) e responde
   *"points at commit '`19c2c89`', which does not exist"* (`bin/sdd:942`). No markdown renderizado a
   célula fica **idêntica** com ou sem crase. `agents/sdd-executor.md:109` diz só "the short hash".
2. **#56 — o motivo morre num subshell.** `cmd_run` deriva a fase com `phase="$(current_phase)"`
   (`bin/sdd:6556`), e o `GATE_WHY` morre junto com o subshell. O `cmd_retry` faz o mesmo
   (`bin/sdd:7024`). O journal grava só `rc=0` (`bin/sdd:3704`), que se lê como sucesso. O
   `cmd_status` contorna chamando `"gate_$next" || true` direto (`bin/sdd:5314`). O mesmo subshell
   explica o `TODO.md:705`: o cache do `run_check_cmd` (`bin/sdd:645`) marca **zero** acertos num
   `sdd run` inteiro.
3. **Elo que nenhuma issue nomeia, provavelmente a raiz: a sessão não sabe por que foi aberta.** O
   `boot_prompt()` (`bin/sdd:2116`) não carrega o motivo. O executor procura "the first `pending`"
   (`agents/sdd-executor.md:34`), não acha nenhuma e não tem instrução para esse caso.
4. **#54 — o no-op compra a volta seguinte.** A guarda `no-progress` (`bin/sdd:6984-6990`) só dispara
   com `moved2=false`. `state_fingerprint()` (`bin/sdd:3753`) lê HEAD, então um commit no-op dá
   `moved=true`, e o ramo "the session moved forward — carrying on" compra outra volta. É a classe
   **"gate insatisfazível"** do princípio 1 do `CLAUDE.md`: "o disco se mexeu" lido como progresso.

## Métrica

Fatos binários, cada um com sensor na suíte (`tests/run-all.sh`):

- **Replay do incidente (célula com crase, stub que faz commit no-op):** `sdd run` abre **0** sessões
  EXEC a mais por causa da célula. A crase é lida como o SHA, o `gate_EXEC` passa e a fase derivada
  avança. **Antes:** ≥ 2 sessões pagas, sem teto até o `BUDGET_MISSION_USD`.
- **Variante irrecuperável (célula com SHA que não existe):** `sdd run` sai com **rc 3**, uma linha
  `kind: "no-work"` no ledger e **0** sessões abertas. **Antes:** laço.
- **Motivo no journal:** toda fase derivada escreve uma linha `PHASE <FASE> reason="…"` no
  `pipeline.log` antes de abrir a sessão. **Antes:** 0 linhas.
- **Motivo no boot:** `sdd boot <missão> <FASE>` imprime o motivo da fase. **Antes:** ausente.
- **Censo de portas:** `grep -cE '^ +if no_work_escalation "\$phase"; then' bin/sdd` → **3**, cada
  porta com um probe em `tests/check-autonomy.sh` e um mutante no catálogo.
- **O cache passa a acertar:** o sensor-contador do `TODO.md:320` afirma que o número de execuções de
  `TEST_CMD` por volta do `cmd_run` não cresce com o número de fases pendentes.

## Resultado esperado

O runner **diz** por que escolheu cada fase. Diz no journal, que o humano vigia, e no prompt de boot,
que a sessão lê. Uma célula de commit com crase é lida como o SHA que ela carrega, e uma célula que
não é SHA recebe uma mensagem própria. Quando o motivo da fase é um defeito de célula do checkpoint,
ou quando a mesma fase volta com o mesmo motivo sem citar log, o runner **para a linha** com rc 3 e
`kind: "no-work"`, antes de pagar a próxima sessão. O executor que abre sem nenhuma linha `pending`
lê o motivo e age: conserta a suíte ou o handoff, reformata a célula, ou declara `blocked`. Ele nunca
faz commit no-op.

## Fora de escopo

- **#50** (crase no `adr_link`): mesma classe, outra função. Escolha explícita do humano, fica na issue.
- **`sdd kaizen`** (`bin/sdd:8755-8805`): tem o próprio laço `no-progress` e não ganha a guarda
  nova. O limite é **declarado** no comentário da função e no `docs/pipeline.md`.
- **Validação da célula na escrita** (camada 2 da #55): o runner não tem ponto de escrita. Quem
  escreve a célula é o agente. A camada vira texto do agente mais a mensagem do gate (decisão 5).
- **Yokoten** da crase para outros leitores de tabela (`gate_REVIEW`, `gate_DOCS` e o `adr_link` da
  #50) fica para missão futura. Achado registrado no `TODO.md` na fase de DOCS se for confirmado,
  pela régua D15.
- **`cmd_status`, `cmd_phase` e `cmd_why`** continuam com `$(current_phase)`. Só `cmd_run` e
  `cmd_retry` passam à função publicadora (decisão 6).

## Gate PLAN-AUTO

Preenchido pelo `sdd-planner` **com evidência**. Todos ✅ → `aprovacao: auto` e o pipeline segue
sozinho. Qualquer ✗ → `aprovacao` fica vazio e o runner para pedindo aprovação humana explícita.

⚠️ **Estado anterior à aprovação:** `aprovacao:` foi deixado **vazio** por instrução explícita da
sessão coordenadora, e o humano o fechou com `sdd approve 20260922-o-motivo-da-fase`
(`aprovacao: humano-2026-09-22` no frontmatter, commit `6a1bcec`). Este plano nunca é executado
por `sdd run`, só interativamente.

| # | Critério | Status | Evidência |
|---|---|---|---|
| a | Grill sem perguntas abertas não endereçadas (🚩 vazia ou itens deferidos com dono) | ✅ | 9 perguntas (Q1–Q9) respondidas pelo humano em 2026-09-22 → "Decisões do grill" 1–9; a única nuance (decisão 4 × `is_escalation`) está em "Pendências para o humano", com leitura verificada e sem bloquear |
| b | Checklist kaizen 100% ✅ e checklist DDD 100% ✅ ou `n/a` justificado | ✅ | K1–K8 abaixo; DDD `n/a` justificado |
| c | Plano passa no teste de autocontenção (sessão nova só com 00/01/checkpoint executa) | ✅ | I1 relido como sessão nova: arquivo, função, linha (`bin/sdd:457`, `:941`), asserção exata, fixture (`tests/check-gates.sh`) e receita de mutante estão no `01-plano.md` |
| d | Todo incremento do `checkpoint.md` tem Check executável (comando → esperado) | ✅ | 8 de 8 incrementos; Checks em herestring ancorados em `^  ok    `, sem `\|` cru; `tests/check-checkpoint.sh` verde sobre o arquivo |
| e | `versao:` confirmada pelo humano (ou `JIRA_ENABLED=false`) | ✅ | `JIRA_ENABLED=false` (`.sdd/config.sh`) |
| f | `adr:` é uma decisão — um caminho, ou o literal `none` (alocado por `sdd adr new`) | ✅ | humano decidiu SIM (Q8); alocado por `sdd adr new --slug o-motivo-da-fase` |

## Checklist kaizen (`kaizen-software`)

| # | Item | Status | Nota |
|---|---|---|---|
| K1 | Gemba — fui ver onde o trabalho acontece | ✅ | issues #54/#55/#56 lidas; `bin/sdd` lido em `147add7` nos sítios citados; `TODO.md:320`/`:705`; `docs/pipeline.md:987` (enum `kind`) |
| K2 | Problema declarado com métrica | ✅ | seis fatos binários, cada um com sensor |
| K3 | Desperdícios identificados e cortados | ✅ | o desperdício é a sessão paga sem trabalho (espera e superprocessamento); a TEST_CMD re-rodada por volta (`TODO.md:705`) sai de brinde na decisão 6 |
| K4 | Fatiamento incremental, cada fatia verificável | ✅ | 8 incrementos, cada um com Red em uma frase |
| K5 | Check por artefato (rótulo ≠ artefato) | ✅ | Checks leem a linha `ok` do sensor, o ledger e o `pipeline.log`, nunca "rc=0" |
| K6 | Jidoka — o que para a linha está definido | ✅ | `kind: "no-work"`, rc 3, três portas; sensor vermelho para a execução do incremento |
| K7 | SDCA — a melhoria vira padrão (doc/rule/teste) | ✅ | poka-yoke primeiro (leitura tolerante + guarda no runner), depois texto: agente, template, `docs/pipeline.md`, anatomia §3/§7, ADR |
| K8 | Registro no KAIZEN_LOG | ✅ | I8 escreve a entrada com antes/depois medidos (US$ 1,94 e ≥ 2 sessões → 0 sessões) |

## Checklist DDD (`ddd`) — condicional

`n/a — sem toque de domínio`: é uma mudança de mecânica interna do runner bash (derivação de fase,
leitura de tabela, guarda de laço). Não há aggregate, bounded context nem entidade de negócio. O
único contrato entre módulos que muda é a coluna `kind` do ledger, e ele é tratado como enum
documentado (`docs/pipeline.md:987`), com a regra de paridade entre leitores (decisão 4).

## Decisões do grill (não re-litigar)

Todas tomadas **pelo humano** em 2026-09-22.

1. **O motivo da fase entra no `boot_prompt()` de TODA fase**, numa linha só. Uma definição, custo
   de teste mínimo, e toda fase ganha o diagnóstico de graça.
2. **Executor sem nenhuma `pending`:** lê o motivo no boot e age conforme o caso.
   - Motivo que nomeia a suíte vermelha ou o handoff ausente: conserta.
   - Motivo que nomeia uma célula do checkpoint: conserta só se o conserto for **reformatação**
     (crase, espaço). Qualquer outro caso vira `blocked`, com o motivo.
   - **Nunca** faz commit no-op. O commit no-op é o que comprava a volta.
3. **Forma da guarda: (b) + (a) estreita.**
   - **(b)** recusa a sessão **antes de abri-la** quando o motivo do gate pertence à classe
     **célula ilegível**: `bin/sdd:939` (`done` sem commit), `:942` (commit inexistente), `:951`
     (fora da história de HEAD), `:958` (status inválido) e a mensagem nova "não é SHA" da decisão 5.
   - **(a) estreita** para a linha quando o mesmo **passo** (`phase_step` — o sub-passo da QA, a
     fase em todo o resto) volta com o **mesmo** motivo duas vezes seguidas, **excluindo** motivos
     que citam log (suíte vermelha). O texto original dizia "a mesma fase"; a chave virou o passo
     por decisão humana durante a execução (ver `checkpoint-notas.md` e o D27 do `CONTEXT.md`). Uma sessão que conserta metade
     de uma suíte vermelha produz o mesmo texto e não pode ser parada.
4. **Kind novo no ledger: `no-work`**, e não `no-progress`, que afirma "duas sessões sem mexer no
   disco". O kind entra pela definição única de cada programa e ganha uma asserção **diferencial**
   de paridade entre os leitores.
5. **#55 em três camadas.**
   - Tirar a crase em `checkpoint_rows`, o **único** leitor: conserta todos os consumidores.
   - Uma mensagem distinta do `gate_EXEC` para célula que não tem forma de SHA hexadecimal.
   - Texto do agente e do template.
   O runner **não tem ponto de escrita** da célula, porque quem escreve é o agente, e isso é dito
   por escrito.
6. **#56: uma função chamada direto, nunca `$( )`, que publica a fase e o `GATE_WHY` em globais**,
   usada no `cmd_run` e no `cmd_retry`. Mais a linha `PHASE <X> reason="…"` no journal. **Paga** o
   sensor-contador do `TODO.md:320`. Os itens `TODO.md:320` e `:705` são apagados depois que o PR
   mergear (regra do `CLAUDE.md`: fechado é apagado, provado por `git merge-base --is-ancestor`).
7. **Três portas:** primeira passada do `cmd_run`, retry inline e `cmd_retry`. Cada porta leva um
   probe e um mutante, e há mutantes também para a mensagem do gate e para a limpeza da crase.
   `sdd kaizen` fica fora, declarado.
8. **ADR: sim.** A missão redefine o que o runner conta como progresso. Alocado com `sdd adr new`,
   nunca com número inventado.
9. **Slug `20260922-o-motivo-da-fase`, branch `feat/o-motivo-da-fase`.**

## Pendências para o humano

- **Leitura da decisão 4, verificada e sem bloquear a execução.** Nos dois programas jq que
  agregam o ledger, `is_escalation` é definido sobre `.event`, e não sobre `.kind`: `bin/sdd:7492`
  (`cmd_autonomy`) e `bin/sdd:7982` (`kaizen_series`), ambos
  `.event == "blocked" or .event == "degraded"`. O `docs/pipeline.md:987` confirma que a coluna
  `kind` é um "enum documentado de cauda aberta" que os leitores agrupam dinamicamente. Logo:
  - `no-work` **entra pela definição única sem editá-la**, porque viaja em `event: "blocked"` via
    `autonomy_blocked_row`;
  - o contrato que muda é a tabela `kind` (`docs/pipeline.md:987` e `:56`) e a lista do
    `ON_ESCALATION_CMD` (`config/schema.md:174`), no mesmo commit do código;
  - a asserção diferencial prova que os dois leitores contam a linha `no-work` igual.
  Se o humano quis dizer "criar um predicado por kind", isso é outra missão.
- **Interação entre as decisões 2 e 3(b).** Com a guarda (b), a sessão EXEC nunca abre quando o
  motivo é de célula, então a regra "reformatar a célula" do executor vira segunda camada. Ela só é
  alcançada quando a sessão abre por outro motivo e encontra a célula. É o desenho, dito para não
  parecer código morto.
