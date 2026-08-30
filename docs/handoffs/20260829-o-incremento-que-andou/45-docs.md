---
missao: 20260829-o-incremento-que-andou
fase: DOCS
status: done
sessao: 5ddbe5c1-0285-48f0-b3e0-4c04b7109625
data: 2026-08-30 09:40
gate: "`docs/handoffs/20260829-o-incremento-que-andou/45-docs.md` existe, contém a palavra `drift` e a coluna `Status` da tabela de drift não tem uma célula pendente — **22 linhas, 15 `✅` e 7 `n/a`**, contadas pelo próprio `awk` do gate e não à mão, cada `✅` com o hash do commit que atualizou o documento e cada `n/a` com a razão concreta. `tests/run-all.sh` → rc 0, `suite green`, **700** `ok`, 0 FAIL (mesmo número da entrada da fase: nenhuma edição desta sessão tocou código). `tests/check-lang.sh` → rc 0 (as duas entradas novas de `docs/` são inglês, como manda a superfície do kit) e `tests/check-todo.sh` → rc 0, `85 finding(s), all within 8 lines and carrying anchor + date`, que é exatamente a catraca congelada em `tests/health-baseline.txt`. Árvore limpa, 2 commits novos: `ea8bfef`, `fe9fe75`. ⚠️ Carimbo de mutação **não** foi re-emitido aqui e não precisava: nenhum dos dois commits toca `bin/ tests/ templates/ config/`, então a chave do carimbo é a mesma que a r1 do REVIEW deixou inválida — quem re-emite continua sendo o `sdd health` do `sdd-publisher`."
---

# Documentação — o incremento que andou

> Escrito depois do código final e antes do PR. O gate desta fase é a tabela abaixo: **toda** área
> tocada pelo diff tem linha, `✅` exige hash e `n/a` exige justificativa concreta.

## TL;DR

O diff toca 17 arquivos (+2412/−63) e a maior parte da documentação viva **já tinha sido
atualizada dentro da missão** — o I5 existe exatamente para isso (`3d697c6`), e a r1 do REVIEW
consertou quatro defeitos de exatidão que o I5 deixou (`d40d570`). Esta sessão achou **três**
coisas que sobraram e uma que faltava, todas medidas:

1. o `KAIZEN_LOG.md` citava o número de controle **duas vezes com dois valores** (`19 de 68` na
   tabela, `14 de 63` treze linhas abaixo) e carregava duas contagens envelhecidas por `354e1c8`,
   que entrou **depois** de a r1 as ter corrigido;
2. o parágrafo **"Progress ≠ gate"** do `docs/pipeline.md` — que nomeia o problema desta missão —
   não mencionava os campos que o resolvem;
3. o `docs/failure-modes.md` estava calado sobre a régua ter mudado **duas vezes em dois dias**,
   que é o arquivo do humano com um sintoma na mão.

Dois commits: `ea8bfef` e `fe9fe75`. Suíte 700 `ok`, árvore limpa, catraca do backlog em 85 e
batendo com o baseline.

## Drift checklist

| Área tocada pelo diff | Documento correspondente | Status | Evidência |
|---|---|---|---|
| `bin/sdd` — `autonomy_session_row()`, os três campos novos na linha do ledger | `docs/pipeline.md` § the autonomy ledger, três linhas novas na tabela de campos | ✅ | escritas em `4571faf`, no mesmo commit do código; coluna "Absent when" corrigida em `d40d570` |
| `bin/sdd` — `cmd_run()` / `cmd_retry()`, a **foto** de `pending_before` antes do `run_phase` | `docs/pipeline.md`, célula `pending_before` (a foto, e por que depois da sessão a pergunta é irrespondível) | ✅ | `4571faf`; o fallback do retry inline entrou na célula em `d40d570`, depois do conserto `06c0e5b` |
| `bin/sdd` — `GATE_EXEC_PENDING` / `_TOTAL` e `gate_EXEC()`, que publica o par **após** a validação | `docs/pipeline.md`, célula `pending_after` (o veredito, e as duas recusas que o deixam nulo) | ✅ | `4571faf`; a segunda recusa (Jidoka do `blocked`) entrou em `99da6d8`, no mesmo commit do conserto F1 |
| `bin/sdd` — `checkpoint_rows()` / `checkpoint_tally()`, a contagem única de status do runner | `docs/pipeline.md` § EXEC (a condição de passagem do gate) | ✅ | `ea8bfef` — o que muda **fora** do runner é "bloquear não é fechar", e isso está escrito na célula `pending_after` por `99da6d8`; a função em si é interna |
| `bin/sdd` — `ledger_outcome_defs()`, o braço `pending_after < pending_before` do `def outcome` | `docs/pipeline.md`, célula `moved`; `CONTEXT.md`, verbete **Churn** | ✅ | `3d697c6` nos dois arquivos, com o antes/depois medido e a guarda de não-nulo explicada |
| `bin/sdd` — `historic_progress`, o caminho datado das 53 linhas antigas | `docs/pipeline.md`, célula `pending_before` (as três regras, o `progress_source` e o sinal de apagamento) | ✅ | `3d697c6`, corrigido em `d40d570` quando a medição desmentiu a razão do `== null` |
| `bin/sdd` — `cmd_autonomy()`, a frase de divulgação do caminho datado | `docs/pipeline.md`, célula `pending_before` (`(N EXEC row(s) …)` citada literalmente) | ✅ | `3d697c6` |
| `bin/sdd` — `kaizen_series()`, a rubrica de rótulo e o `advance_rate` | `docs/pipeline.md` § the judge's series (`leve` e `advance_rate` reescritos, com o exemplo trabalhado de `frete-cif-fob`) | ✅ | `3d697c6` |
| `bin/sdd` — `USAGE`, duas linhas novas no `sdd autonomy --help` | `README.md` § Usage | n/a | o `README.md` **nomeia** os três baldes e nunca definiu nenhum deles, então nenhuma frase dele envelheceu; a régua é profundidade e mora em `docs/pipeline.md`, para onde o arquivo já roteia — pôr a definição no índice é o que a disclosure progressiva proíbe |
| `bin/sdd` — `ledger_row_is_local()`, `autonomy_degraded_row()` | — | n/a | os dois aparecem só como cabeçalho de hunk: o que mudou nessas vizinhanças é comentário do `ledger_outcome_defs` e a declaração dos globais, cobertos pelas linhas acima |
| `agents/sdd-kaizen.md` + espelho `.claude/agents/` | o próprio arquivo (é o prompt do juiz, e o juiz é quem lê o número) | ✅ | `7cc0210` e `3d697c6`; espelho conferido nesta sessão — `diff` de **todos** os 8 agentes contra `.claude/agents/` não acusa nenhum stale |
| `CONTEXT.md` — verbete **Churn** | `CONTEXT.md` | ✅ | `3d697c6` — a definição passou a ser "escreveu e **não fez o incremento andar**", com os dois números do antes/depois e o limite declarado |
| `CONTEXT.md` — decisão **D16** (com que instrumento se lê a D12) | `CONTEXT.md` | ✅ | `3d697c6` — segunda emenda, datada, dizendo que o `advanced · churned · idle` só responde à D12 por causa dos três campos |
| `KAIZEN_LOG.md` — a missão mede antes/depois | `KAIZEN_LOG.md` | ✅ | entrada em `3d697c6`, números re-medidos em `d40d570`, e **reconciliada nesta sessão** em `ea8bfef`: `19 de 68` num lugar só, asserções `699 → 700`, `check-autonomy 253 → 254`, e os três mutantes posteriores ao I5 nomeados para o `195` da tabela fechar com a lista |
| `docs/pipeline.md` § EXEC — o parágrafo "Progress ≠ gate" | `docs/pipeline.md` | ✅ | `ea8bfef` — a impressão digital continua dona da decisão de retry; o que ela não distingue é "escreveu" de "fechou o incremento", e agora o parágrafo diz onde isso passou a ser dito |
| `docs/failure-modes.md` — a régua mudou duas vezes em dois dias | `docs/failure-modes.md` | ✅ | `fe9fe75` — modo de falha novo, criado por esta missão: número na tela contra número congelado em prosa. Roteia, não duplica |
| `TODO.md` — 8 achados novos da r1, 1 resolvido apagado | `TODO.md` + `tests/health-baseline.txt` | ✅ | `ebe9702` (78 → 77), `d77f2ae` e `354e1c8` (77 → 85), catraca movida em diff com autor nos dois sentidos; conferidos nesta sessão (seção abaixo) |
| `tests/check-autonomy.sh`, `check-kaizen.sh`, `check-mutation.sh` | `CLAUDE.md` § TDD aqui dentro (a lista dos treze sensores e os quatro lugares de sensor novo) | n/a | nenhum sensor **novo** nasceu: os três já estão na lista, no `LINT_FLOOR` e nos dois pisos de superfície. Sensor que cresce em asserção não move nenhuma dessas contagens |
| `bin/sdd` — nenhuma convenção do kit mudou | `CLAUDE.md` | n/a | SDCA: escrever regra que a convenção não mudou é dívida que o próximo agente obedece sem questionar. As três contagens que o arquivo publica seguem exatas — `grep -cE '^[a-z_]+_escalation\(\) \{'` → 2, as portas delas → 4, `kit_guard_check` → 4 — e `grep -l '^selftest()' tests/*` segue 6. ⚠️ A tentação era escrever "`checkpoint_tally` é a contagem única de status": o achado #9 da r1 mede que **ainda não é** (`IFS read` colapsa tabs, `awk -F'\t'` não), então a regra seria falsa no dia em que fosse escrita |
| `config/schema.md`, `config/starter.conf` | — | n/a | nenhuma chave de config nasceu, mudou de default ou de significado; `load_config()` não foi tocado |
| `templates/*` | — | n/a | nenhum contrato de artefato mudou: o `checkpoint.md` segue com as mesmas colunas e os mesmos tokens de status, e nenhum gate passou a ler um heading novo |
| `docs/adr/*` | — | n/a | nenhuma decisão arquitetural foi tomada nem revertida. A régua nova **implementa** a ADR 0001 (a parte mecânica é código, datada no histórico) em vez de mudá-la, e a única decisão de arquitetura que a missão levantou — trocar as duas regras especiais do caminho histórico por um invariante — foi deliberadamente **não** tomada e está no `TODO.md` com o protótipo já medido, para o humano |

## Achados desta missão conferidos no `TODO.md`

O `check-todo.sh` responde `85 finding(s), all within 8 lines and carrying anchor + date` e a
catraca `todo-findings` congelada em `tests/health-baseline.txt` também é 85 — as duas leituras
batem, que é a única forma de o número ter se movido em diff com autor.

Os **oito** que esta missão registrou foram lidos um a um, e os oito carregam as quatro partes
(o quê + `arquivo:linha` + por que importa + quem descobriu, em que missão, em que data). Nenhum
precisou ser completado:

| Achado | Âncora | Fecha por qual metade da régua D15 |
|---|---|---|
| `gate_EXEC` valida por uma leitura e conta por outra | `bin/sdd:786` | fail-open — diferencial mede `MAIN rc=1` contra `HEAD rc=0`, o gate passa onde recusava |
| a inferência de `M` com a memória vazia | `bin/sdd:1896` | fail-open na direção da lisonja, com a direção prototipada e medida (0 de 158 linhas mudam) |
| o ledger global contaminado por missões de fixture | `~/.sdd/autonomy-log.jsonl` | consumidor fora da suíte — o juiz, a D12 e todo número que o kit publica sobre si |
| a frase de divulgação conta linhas que nenhum balde mostra | `bin/sdd:4535` | fail-open brando, e a frase é o **sinal de apagamento** do caminho datado |
| a regra `doing` do `tally` sem probe | `bin/sdd:328` | fail-open — degradada, o `gate_EXEC` fecha a fase por cima de um incremento em voo com a suíte verde |
| duas das cinco portas `phase = EXEC` sem probe | `bin/sdd:4291` | fail-open — a suíte fica verde com a porta removida |
| a metade `repo` da chave de memória sem probe | `bin/sdd:1918` | fail-open — mesma classe do `ledger_repo_root`/`CDPATH` que já custou uma CRITICAL |
| a guarda `phase == "EXEC"` do caminho histórico sem probe | `bin/sdd:1918` | fail-open na direção da lisonja |

⚠️ **Os três "não-feitos" que o EXEC deixou fora do `TODO.md` continuam fora, e conferi que a
razão se sustenta** (`20-handoff-exec.md` § Achados fora de escopo): o `N of M` como dado e não
contrato, a ausência de sensor para o aviso de "a régua mudou", e `pass/false` sem fixture. Os
três são **limites declarados** — os dois primeiros no cabeçalho do `historic_progress`
(`bin/sdd:1890-1918`), o terceiro na célula `moved` do `pipeline.md` e no verbete Churn —, nenhum
é fail-open e nenhum tem consumidor fora da suíte do kit, que é o que a D15 pede. O primeiro,
aliás, foi **refutado por sabotagem** na r1 do REVIEW: o limite como escrito superestimava o
risco, porque as 53 linhas são imutáveis e nenhuma linha nova nasce elegível ao caminho histórico
depois de `06c0e5b`.

## O que NÃO foi escrito, e por quê

- **`README.md`.** Nada sobre instalar, rodar ou usar mudou. O arquivo nomeia
  `advanced · churned · idle` e nunca definiu nenhum dos três — a definição é profundidade e já
  mora no `docs/pipeline.md`, para onde o README roteia. Escrever a régua no índice engorda o
  arquivo que o próximo agente carrega inteiro no contexto, que é o custo que a disclosure
  progressiva existe para não pagar.
- **`CLAUDE.md`.** Nenhuma convenção mudou. Ver a linha da tabela acima: a única frase tentadora
  seria falsa no dia em que fosse escrita, e o achado que mede isso já está no `TODO.md`.
- **Uma ADR.** A missão implementa a ADR 0001 em vez de mudá-la. A decisão que **mereceria** ADR —
  o invariante do "total feito" no lugar das duas regras especiais — foi deixada para o humano com
  o protótipo medido, e é o segundo item das Pendências abaixo.
- **Proposta de split de arquivo longo.** O `docs/pipeline.md` já passa de 800 linhas e o
  `CLAUDE.md` de 250, mas nenhum dos dois foi refatorado aqui: dividir documento de terceiro no
  meio de uma missão é exatamente o que a disclosure progressiva manda **não** fazer. As duas
  entradas novas somam 9 e 27 linhas, ambas roteando para profundidade que já existia.

## Pendências / Decisions for a Human

> Herdadas da r1 do REVIEW, repetidas aqui porque é este handoff que o corpo do PR cita.

- **Adotar o invariante do caminho histórico, ou declarar a inferência.** Sem memória,
  `historic_progress` devolve `pending_before := M`. Está certo na primeira linha de uma missão
  (14 linhas reais) e é fabricação depois de um `pass` (4) ou com `M` mudado (2). O invariante
  alternativo já está prototipado e medido — muda **0 de 158** linhas do ledger real —, e o que
  impede aplicá-lo numa revisão é que ele reescreve a decisão 3 do grill e derruba uma asserção
  existente. Missão própria, ou limite declarado no cabeçalho.
- **O ledger global que o kit usa para se julgar está contaminado por missões de fixture dos
  próprios testes.** Quatro dos seis grupos EXEC do número de controle desta missão são fixture.
  Não bloqueia (os números publicados foram re-derivados com o predicado escrito por extenso), mas
  é decisão de operação: limpar, separar o ledger de teste, ou recusar escrita fora de
  `SDD_STATE_DIR`.

## Riscos e não-feitos

- **O `45-docs.md` não roda `TEST_CMD` no gate.** O `gate_DOCS` lê a tabela de drift e mais nada,
  então a suíte verde citada no frontmatter foi rodada por esta sessão à mão, duas vezes (antes e
  depois das edições), e as duas responderam 700 — nenhuma edição desta fase toca código.
- **O carimbo de mutação segue inválido, por desenho.** A r1 do REVIEW mexeu em `bin/` e `tests/`;
  esta fase não mexeu em nenhum dos dois, então nada aqui piorou a situação e nada aqui a
  conserta. Quem re-emite é o `sdd health` do `sdd-publisher`, **depois** do último commit de
  código — e `tests/health-baseline.txt` está dentro da chave, o que é a colisão já registrada no
  `TODO.md`.
- **A frase de divulgação (`N EXEC row(s) …`) é citada literalmente no `pipeline.md`, e o achado
  #11 da r1 diz que o `N` dela não reconcilia com nenhum balde.** A célula documenta a frase como
  sinal de apagamento, que é o que ela é; o defeito é do número, não do contrato, e está no
  `TODO.md` com a direção. Não foi consertado aqui porque conserto de número é código.
- **Não conferi a documentação de repo-alvo nenhum.** A missão é do kit sobre si mesmo; nenhum
  arquivo fora deste repositório foi lido ou escrito.

## Boot da próxima fase

`sdd-publisher`, fase PR. Ler, nesta ordem:

1. `docs/handoffs/20260829-o-incremento-que-andou/00-missao.md` § Métrica — os quatro alvos, para
   o corpo do PR poder dizer qual bateu e qual **não** bateu (a segunda metade da métrica 3 não se
   confirmou, e o `KAIZEN_LOG.md` explica por quê com a medição ao lado);
2. `40-review-r1.md` — a tabela Overall Grade, os 11 achados e o que foi refutado;
3. este arquivo — a tabela de drift e as duas pendências para o humano;
4. `KAIZEN_LOG.md`, entrada de 2026-08-29 — é dela que sai o antes/depois medido do corpo do PR.

**Primeiro comando, e não é opcional:** `./bin/sdd health`. O carimbo de mutação está inválido
desde a r1 do REVIEW e o `gate_PR` o exige. Rodar **antes** de qualquer commit novo em
`bin/ tests/ templates/ config/` — inclusive `tests/health-baseline.txt`, que está dentro da
chave. Leva de 15 a 50 minutos; errar a ordem paga o tempo duas vezes.

## Achados fora de escopo

> Dois destinos, e a diferença já custou uma `main` vermelha (`2d28d13`).
>
> **Achado sobre o repo-alvo:** registrado no `TODO.md` dele; aqui fica só o ponteiro, para o PR
> conseguir citar.
>
> **Achado sobre o kit** (runner, agente, template), numa missão cujo repo NÃO é o kit: a sessão
> não escreve, não commita e não entra no repositório do kit. A linha **completa** do achado mora
> aqui, marcada `kit:`, e quem a transporta é um humano ou a triagem do `sdd kaizen`. Ponteiro para
> um arquivo que ninguém escreveu é achado perdido.
>
> O exemplo abaixo mora **dentro** desta citação pelo mesmo motivo que o `- intervention:` do
> `checkpoint.md` (`cd49351`): exemplo que abre a linha com `-` é contado verbatim por quem vier
> varrer os handoffs atrás de `kit:`, e todo handoff nasceria devendo um achado fantasma. Copie a
> forma para fora da citação ao registrar um achado de verdade.
>
> - kit: <o quê> — <arquivo:linha do kit> — <por que importa>

**Nenhum, e a conta é deliberada.** Este repo **é** o kit, então achado de kit iria para o
`TODO.md` daqui. Os três defeitos de exatidão que esta fase achou foram **consertados** nela
(`ea8bfef`, `fe9fe75`) em vez de registrados: são drift de documentação da própria missão, que é
literalmente o trabalho desta fase — registrar no backlog o que se está encarregado de consertar
seria transformar a fase num contador de si mesma. Nada mais foi encontrado, e a catraca
`todo-findings` fica onde a r1 do REVIEW a deixou (85), sem movimento nesta fase.
