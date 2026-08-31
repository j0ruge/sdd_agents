---
missao: 20260831-a-rodada-que-andou
fase: DOCS
status: done
sessao: 191f3852-b112-45c3-87cf-22a62602c54a
data: 2026-08-31 18:55
gate: "`docs/handoffs/20260831-a-rodada-que-andou/45-docs.md` existe, contém a palavra `drift` e a coluna `Status` da tabela de drift não tem célula pendente — **26 linhas, 19 `✅` e 7 `n/a`**, contadas pelo **próprio `awk` do gate** rodado sobre o arquivo e não à mão, cada `✅` com o hash do commit que atualizou o documento e cada `n/a` com a razão concreta. `tests/run-all.sh` → rc 0, `suite green`, **842** `ok`, 0 FAIL, rodado no estado final da árvore (depois dos seis commits desta fase). `tests/check-todo.sh` → `92 finding(s), all within 8 lines and carrying anchor + date`, exatamente a catraca congelada em `tests/health-baseline.txt`; `tests/check-lang.sh` → rc 0, `0 of 40 surface path(s) still in the allowlist, 0 new` (as duas edições em `docs/` são inglês, como manda a superfície do kit). Espelho dos agentes conferido: `diff` dos **7** contra `.claude/agents/` sem nenhum stale. ✅ **CARIMBO DE MUTAÇÃO RE-EMITIDO NESTA FASE**, que era a pendência que a r2 deixou: `./bin/sdd health` → `ok suite green`, `ok mutation: score: 218 caught, 0 known gap(s), of 218`, `ok mutation stamp written — gate_PR can see that THIS content ran green`, `ok all 8 gates have a mutation in the catalogue`, `ok provenance: all 3 fixtures match the installed skills`, `ok ratchet: 1 known debt(s), none new`, `ok kit healthy` (rc 0, carimbo `2d0cb366383f035bad57e31a7d4c52c8`, ~21 min). Rodado **depois** do último commit de código e re-conferido idêntico depois da suíte final — nenhum dos seis commits desta fase toca `bin/ tests/ templates/ config/`, então o carimbo entra válido no `gate_PR`. Árvore limpa."
---

# Documentação — a rodada que andou

> Escrito depois do código final e antes do PR. O gate desta fase é a tabela abaixo: **toda** área
> tocada pelo diff tem linha, `✅` exige hash e `n/a` exige justificativa concreta.

## TL;DR

O diff toca **19** arquivos (+3694/−65, `git diff --shortstat bf001fe..HEAD` medido depois dos seis
commits desta fase; 20 com este próprio handoff) e a documentação de contrato **já vinha sendo
escrita dentro da missão** — `docs/pipeline.md` entrou em **sete** commits da missão, e **seis**
deles carregam `bin/sdd` no mesmo diff, que é a regra do `CLAUDE.md` para mudança de contrato de
artefato (o sétimo, `5f2b511`, é a tabela de campos aprendendo a terceira forma). Esta sessão achou **oito** derivas que sobraram,
todas medidas, e nenhuma delas no lugar onde a missão estava olhando:

1. o verbete **Escalada** do `CONTEXT.md` definia escalada como *"qualquer linha do ledger que não
   gastou sessão"* — falso desde o I4, e é a grafia **perigosa**: o próximo agente poria o
   `gate_pass` dentro do `is_escalation`, que é a decisão que a missão tomou ao contrário;
2. mais três verbetes da mesma raiz (**Ledger de autonomia**, **Churn**, **Série**);
3. o bullet do `refez` no `docs/pipeline.md` ainda dizia, verbatim, a cláusula 3 **antiga** — a
   frase que esta missão existe para consertar, sobrevivendo no resumo enquanto o parágrafo logo
   acima explicava o conserto;
4. a frase de paridade dos dois leitores nomeava `comparable_row` como população comum, e
   `comparable_row` é exatamente o predicado que ficou **de fora** depois de `c4a114e`;
5. o `docs/failure-modes.md` dizia que a régua mudou *"duas vezes em dois dias"* — são três em
   quatro, e a terceira é esta missão;
6. o `KAIZEN_LOG.md` não tinha a entrada (métrica (3), a única que a missão ainda devia);
7. o `CLAUDE.md` não tinha a cláusula que a HIGH #1 da r2 pagou;
8. as **cinco** âncoras que esta missão registrou no `TODO.md` apodreceram **dentro** da própria
   missão — commits posteriores ao registro deslocaram o `bin/sdd`.

Seis commits: `e935a32`, `e9bfc17`, `5a6b305`, `6af1a49`, `8d85460`, `1343db5`. Catraca do backlog
em 92 e batendo com o baseline; nenhum achado novo nasceu nesta fase.

## Drift checklist

| Área tocada pelo diff | Documento correspondente | Status | Evidência |
|---|---|---|---|
| `bin/sdd` — `autonomy_session_row()`, os três campos `rounds_*` na linha do ledger | `docs/pipeline.md` § the autonomy ledger, três linhas novas na tabela de campos | ✅ | `99f65bf`, no mesmo commit do código — mudança de contrato de artefato entra nos três lugares de uma vez |
| `bin/sdd` — `cmd_run()`/`cmd_retry()`, a **foto** de `rounds_before` antes do `run_phase` | `docs/pipeline.md`, célula `rounds_before` (a foto, e o ⚠️ de que ela sai de FORA da guarda `[ -z "$force_phase" ]`) | ✅ | `99f65bf` |
| `bin/sdd` — `GATE_REVIEW_ROUNDS`/`GATE_REVIEW_MAX` e a publicação no `gate_REVIEW()` | `docs/pipeline.md`, células `rounds_after` e `rounds_max` (a assimetria deliberada com `pending_after`, e por que `rounds_max` não é enfeite) | ✅ | `99f65bf` |
| `bin/sdd` — `ledger_outcome_defs()`, o braço da rodada no `def outcome` | `docs/pipeline.md` célula `moved`; `CONTEXT.md` verbete **Churn** | ✅ | `60d2c88` no `pipeline.md`; verbete em `e935a32`, com o antes/depois medido por diff dos dois binários e a guarda de não-nulo explicada |
| `bin/sdd` — `def historic_rounds`, o caminho datado das 19 linhas anteriores ao esquema | `docs/pipeline.md`, célula `rounds_before` (as regras, o `rounds_source` e o sinal de apagamento) | ✅ | `c7c2e2e` |
| `bin/sdd` — `cmd_autonomy()`, a frase de divulgação nova e a do EXEC religada sobre `comparable` | `docs/pipeline.md`; `TODO.md` (o item da frase, fechado) | ✅ | `c7c2e2e` e `7a34766` — a frase do EXEC caiu de 53 para 51 no ledger real, que é o número que a tabela mostra |
| `bin/sdd` — `autonomy_gate_pass_row()` e `gate_pass_rows()`, a **terceira forma de linha** | `docs/pipeline.md` § three row shapes + o enum de `event` (declarado fechado, logo mudança de contrato); `CONTEXT.md` verbete novo **Fechamento de gate gravado** | ✅ | `715da79` e `5f2b511`; verbete em `e935a32`, com a condição estreita e os dois limites |
| `bin/sdd` — `def phase_label`, a cláusula 3 do `refez` | `docs/pipeline.md` — o bloco de profundidade **e** o bullet do `refez` | ✅ | bloco em `715da79`/`d17aca6`; **o bullet só nesta fase**, `1343db5` — ele ainda dizia "the phase's last SESSION still failing its gate", a régua que a missão substituiu |
| `bin/sdd` — `shas_in_file_order`, o eixo do juiz (HIGH #1/#2 da r2) | `CLAUDE.md` § enum lido em mais de um ponto (cláusula nova); `docs/pipeline.md` § the judge's series | ✅ | `e9bfc17` e `1343db5` — a frase do `pipeline.md` afirmava paridade por um predicado que nenhum dos dois leitores usa para ordenar, e o resíduo tem achado ABERTO que ela agora cita |
| `bin/sdd` — `group_summary`, o filtro do `$detail` que impede a célula fantasma | `docs/pipeline.md` (a closure MODIFICA célula, nunca é sujeito de uma) | ✅ | `dfe4d63` |
| `bin/sdd` — `is_unrecognized`, `is_escalation` e `comparable_row` aprendendo o evento | `CONTEXT.md` verbete **Escalada** | ✅ | `e935a32` — a definição *"qualquer linha que não gastou sessão"* era falsa E perigosa: levava o próximo agente a pôr o `gate_pass` no `is_escalation` |
| `bin/sdd` — `missions:` e `composition:` derivados de `$rows`, que agora traz a terceira forma | `CONTEXT.md` verbete **Série** | ✅ | `e935a32` — o ⚠️ cita a assimetria com o `detail` e aponta para o achado aberto (`bin/sdd:5374`) em vez de calar |
| `bin/sdd` — `ledger_row_is_local()`, `app_down_escalation()`, `autonomy_escalation_row()` | — | n/a | aparecem só como cabeçalho de hunk: o que muda nessas vizinhanças é comentário e a declaração de globais, já cobertos pelas linhas acima |
| `bin/sdd` — superfície de comando | `README.md` § Usage | n/a | `git diff bf001fe..HEAD -- bin/sdd \| grep -c USAGE` → **0**. Nenhum comando, flag ou linha de `--help` nasceu ou mudou; nada sobre instalar, rodar ou usar envelheceu. A régua dos baldes é profundidade e já mora em `docs/pipeline.md`, para onde o README roteia — escrevê-la no índice é o que a disclosure progressiva proíbe |
| `tests/check-autonomy.sh`, `tests/check-kaizen.sh` — +63 asserções (779 → 842) | `CLAUDE.md` § TDD aqui dentro (a lista dos treze sensores, o `LINT_FLOOR` e os dois pisos de superfície) | n/a | nenhum sensor **novo** nasceu: os dois já estão nos quatro lugares que "entra lá" significa. Sensor que cresce em asserção não move nenhuma dessas contagens, e as quatro que o `CLAUDE.md` publica foram re-medidas nesta sessão e seguem exatas (2, 4, 4, 6) |
| `tests/check-mutation.sh` — catálogo 195 → 218 (+23 mutantes) | o carimbo de `sdd health`, que o `gate_PR` exige | ✅ | re-emitido nesta fase, depois do último commit de código; saída no `gate:` do frontmatter. O catálogo é opt-in fora do `TEST_CMD` desde `4c86712`, e quem o cobra é o carimbo |
| `tests/health-baseline.txt` — `todo-findings 87 → 92` | catraca; `CONTEXT.md` verbete **Catraca** | ✅ | `7c0a92a` e `d4886e6`, o número movido em diff com autor nos dois sentidos. O verbete descreve o **mecanismo** e nunca um número, então nada nele envelheceu |
| `CONTEXT.md` — D11 confirmada pelo humano, 🚩 removida | `CONTEXT.md` | ✅ | `311fe41`, no commit do próprio grill |
| `TODO.md` — 5 achados novos, 3 marcados `RESOLVIDO por`, 1 fechado pelo I3 | `TODO.md` + `tests/health-baseline.txt` | ✅ | `7a34766`, `7c0a92a`, `2534712`, `d4886e6`; conferidos um a um nesta sessão (seção abaixo) e as **oito** âncoras consertadas em `8d85460` |
| `KAIZEN_LOG.md` — a missão mede antes/depois (métrica (3), K8) | `KAIZEN_LOG.md` | ✅ | `6af1a49` — os dois comandos e as duas saídas verbatim, o `diff` inteiro dos cinco hunks, e o que a medição **não** prova |
| `docs/failure-modes.md` — a régua mudou de novo | `docs/failure-modes.md` | ✅ | `5a6b305` — de "duas vezes em dois dias" para três em quatro, mais a armadilha nova do `N row(s)` do cabeçalho, que agora conta três formas de linha |
| `docs/handoffs/20260831-*` — `00-missao.md` e `01-plano.md` reescritos no ponto de corte da métrica | os próprios artefatos da missão | ✅ | `5eb6de7` e `e320d21`, **antes** de a linha andar — alvo corrigido com a medição na mesa, nunca depois de saber o resultado |
| `agents/*.md` e o espelho `.claude/agents/` | — | n/a | zero arquivos de agente no diff (`git diff --name-only \| grep -c '^agents/'` → 0). Espelho conferido mesmo assim nesta sessão: `diff` dos **7** contra `.claude/agents/` não acusa nenhum stale |
| `config/schema.md`, `config/starter.conf` | — | n/a | nenhuma chave de config nasceu, mudou de default ou de significado; `load_config()` não foi tocado |
| `templates/*` | — | n/a | nenhum contrato de artefato mudou: o `checkpoint.md` segue com as mesmas colunas e tokens de status, e nenhum gate passou a ler um heading novo |
| `docs/adr/*` | — | n/a | nenhuma ADR nasceu, e a decisão que a missão **tomou** foi registrada como **D21** no `CONTEXT.md`, pelo mesmo critério que a D11 (sua irmã exata: "evento novo ou reusar um existente?") já usava. Enquanto for forma de linha do ledger, o contrato mora em `docs/pipeline.md`; se o evento ganhar consumidor fora do runner, vira ADR — está dito na própria D21 |

## Achados desta missão conferidos no `TODO.md`

`tests/check-todo.sh` responde `92 finding(s), all within 8 lines and carrying anchor + date`, e a
catraca `todo-findings` congelada em `tests/health-baseline.txt` também é **92** — as duas leituras
batem, que é a única forma de o número ter se movido em diff com autor.

Os **cinco** que esta missão registrou foram lidos um a um. Os cinco carregam as quatro partes (o
quê + `arquivo:linha` + por que importa + quem descobriu, em que missão, em que data), e nenhum
precisou ser completado no texto — mas **todos os cinco tinham a âncora podre**, e isso sim foi
consertado:

| Achado | Âncora, antes → depois | Fecha por qual metade da régua D15 |
|---|---|---|
| `reopened` é cego à closure — a resposta depende de a fase ter CUSTADO dinheiro | `4849` → **`4860`** (mais `4942`→`4954` e `4949`→`4962`) | consumidor fora da suíte — é o juiz, e o número muda com a linha gravada |
| A guarda de fase da foto de REVIEW no `cmd_retry` não tem probe | `4568` → **`4587`** | fail-open — suíte verde com a guarda removida; `RESOLVIDO por 594ef07` |
| A porta de `gate_failed` do retry inline não tem probe | `4509` → **`4528`** | fail-open — e o comentário jurava cobertura; `RESOLVIDO por 594ef07` |
| `$order` e `comparable_row` divergem sobre a linha `gate_pass` | `4899` → **`4929`** | consumidor fora da suíte — os dois leitores nomeiam `latest` invertido, medido |
| Missão que só tem `gate_pass` numa fatia entra em `missions` sem produzir célula | `5318` → **`5374`** (mais `:5368` acrescentada para o filtro do `$detail`) | consumidor fora da suíte — `guard.missions_after_change` e o `composition` da ADR 0005 deixam de reconciliar com o `detail` ao lado |

⚠️ **A podridão de âncora aconteceu DENTRO da missão, em horas, e não entre missões.** Os cinco
itens foram registrados corretamente e commits **posteriores** ao registro deslocaram o `bin/sdd`.
É a família do achado já aberto *"22 das 33 âncoras do `TODO.md` apontam para a linha errada"*, que
segue aberto com a direção — consertar as da própria missão é trabalho desta fase, consertar a
classe é missão própria. Cada âncora nova foi verificada com `sed -n '<n>p' bin/sdd` e pousa no seu
assunto.

⚠️ **Os dois "não-registrados" da r2 continuam fora, e a razão se sustenta.** O achado #6
(`historic_progress` não limpa a memória numa closure) é **inconstruível por ordem de escrita** — o
caminho datado só anota linha com `pending_before` nulo, o que quer dizer "escrita antes de
2026-08-29", e o `gate_pass` nasceu em 2026-08-31. Virou comentário no `bin/sdd` com o mundo
nomeado, que é o que a D15 pede de dívida declarada. O achado #9 (a guarda `sessions[$ph] > 0`) foi
**refutado duas vezes**, e a recusa é textual: o comentário já declara verbatim que a redundância
não tem probe. Registrar qualquer um dos dois mataria o carimbo de mutação por um item que a régua
de admissão recusa.

## O que NÃO foi escrito, e por quê

- **`README.md`.** Zero linhas de `USAGE` no diff. Nada sobre instalar, rodar ou usar mudou, e o
  README nomeia os baldes sem nunca ter definido nenhum — a definição é profundidade e já mora no
  `docs/pipeline.md`, para onde ele roteia.
- **Uma ADR.** A pergunta desta missão ("evento novo no ledger, ou inferir o fechamento?") é a
  irmã exata da D11, que foi resolvida sem ADR e continua sem. O contrato do evento vive na tabela
  de campos do `docs/pipeline.md`, que é onde um leitor procura; uma ADR duplicaria a decisão num
  terceiro lugar e criaria a chance de os dois discordarem. A D21 diz isso sobre si mesma, e diz o
  gatilho que a promoveria: consumidor fora do runner.
- **Proposta de split de arquivo longo.** O `docs/pipeline.md` está em **876** linhas e o
  `CLAUDE.md` em **460** (`wc -l`, medido nesta sessão), e nenhum dos dois foi refatorado aqui: dividir documento de terceiro no meio de uma missão
  é exatamente o que a disclosure progressiva manda **não** fazer. As entradas desta fase roteiam
  para profundidade que já existia em vez de duplicá-la — o verbete novo do `CONTEXT.md` termina
  apontando para o `pipeline.md`, e o bullet do `refez` aponta para o bloco duas seções acima.
- **Um achado novo no `TODO.md`.** As oito derivas que esta fase achou foram **consertadas** nela,
  não registradas: são drift de documentação da própria missão, que é literalmente o trabalho desta
  fase. Registrar no backlog o que se está encarregado de consertar transforma a fase num contador
  de si mesma — e, aqui, mataria o carimbo de mutação de graça (`tests/health-baseline.txt` mora
  dentro da chave).

## Riscos e não-feitos

- **O `gate_DOCS` não roda `TEST_CMD`.** Ele lê a coluna `Status` da tabela acima e mais nada, então
  a suíte verde citada no frontmatter foi rodada por esta sessão à mão. Nenhuma edição desta fase
  toca `bin/`, `tests/`, `templates/` ou `config/` — o que é também o que mantém o carimbo válido.
- **O carimbo de mutação foi re-emitido nesta fase, e ele é frágil na ordem.** A chave é o conteúdo
  de `bin/ tests/ templates/ config/`. Nenhum commit desta fase os toca, mas **qualquer** achado
  novo registrado daqui até o PR move `tests/health-baseline.txt` e mata o carimbo de novo, custando
  20 a 50 min. É a colisão já registrada no `TODO.md`.
- **A métrica (2) continua provada só por fixture.** Há `0` linhas `gate_pass` no ledger real; o
  evento nasce nesta missão e povoa da próxima corrida em diante. A DOCS não re-mediu a métrica (1)
  do zero por prosa — ela foi **re-rodada** nesta sessão (os dois binários contra o mesmo ledger), e
  o resultado ficou mais rico que o do EXEC: **quatro** fatias se movem, não três, porque a r1 do
  REVIEW desta própria missão (`080f503`, US$ 37,10) entrou no ledger no meio da missão.
- **Não conferi documentação de repo-alvo nenhum.** A missão é do kit sobre si mesmo; nenhum arquivo
  fora deste repositório foi lido ou escrito.
- **A frase de paridade do `pipeline.md` foi corrigida, não resolvida.** Os dois leitores concordam
  hoje sobre a ORDEM, e `comparable_row` continua admitindo a closure. O achado está aberto e a
  frase agora o cita; o conserto é código e não coube aqui.

## Boot da próxima fase

`sdd-publisher`, fase PR. Ler, nesta ordem:

1. `docs/handoffs/20260831-a-rodada-que-andou/00-missao.md` § Métrica — os três alvos, e em especial
   o ⚠️ da métrica (1), que foi **reescrita** no meio da missão depois de a previsão original ser
   falsificada. O corpo do PR tem de contar essa história, não escondê-la;
2. `40-review-r2.md` — a tabela Overall Grade (todos `A`), os nove achados e o que foi **refutado**;
3. este arquivo — a tabela de drift e a seção de achados conferidos;
4. `KAIZEN_LOG.md`, entrada de 2026-08-31 — é dela que sai o antes/depois medido do corpo do PR,
   com os dois comandos e as duas saídas já verbatim.

⚠️ **O carimbo de mutação está VÁLIDO na entrada desta fase** — foi re-emitido aqui, depois do
último commit de código. Diferente do handoff de `20260829`, o `sdd health` **não** precisa ser o
primeiro comando do publisher. O que ele não pode fazer é commitar em `bin/`, `tests/`,
`templates/` ou `config/` antes do `gate_PR`; se isso acontecer, re-carimbar custa 20 a 50 min.

⚠️ **`sdd approve 20260831-a-rodada-que-andou` segue sendo o único destravamento do plano
kaizen-born** — contrato do `gate_PLAN`, e não pendência desta fase nem da próxima.

## Pendências / Decisions for a Human

> Herdadas da r2 do REVIEW e do grill, repetidas aqui porque é este handoff que o corpo do PR cita.

- **A régua mudou pela terceira vez em quatro dias, e dentro de uma janela de medição.** Quem citar
  rótulo ou contagem de versão depois desta missão tem de dizer com qual `bin/sdd` leu. Está escrito
  no `05-verdict.md`, no `docs/failure-modes.md` (atualizado nesta fase) e no `KAIZEN_LOG.md`.
  A decisão de mudar no meio da janela foi tomada no grill (decisão 1) e não é re-litigável aqui.
- **O destino do alvo "suíte < 30 s" da D7 continua na mesa**, e o número piorou de propósito: 842
  asserções e 218 mutantes. A decisão (subir o alvo × aposentá-lo) foi direcionada à triagem do
  próximo `sdd kaizen` pelo grill (decisão 6). Não se corta mutação para ganhar relógio.
- **A missão do custo do REVIEW passa a ter instrumento em que confiar.** Era o que a D19 parou
  "para depois do veredito": a fase consome 41% do gasto da janela 2, e até esta missão o número
  incluía o laço desenhado como desperdício. Cortar o custo continua **fora de escopo** aqui.

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

**Nenhum, e a conta é deliberada.** Este repo **é** o kit, então achado de kit iria para o `TODO.md`
daqui. As oito derivas que esta fase encontrou foram **consertadas** nela (seis commits) em vez de
registradas, pelo argumento da seção "O que NÃO foi escrito". A catraca `todo-findings` fica onde a
r2 do REVIEW a deixou (**92**), sem movimento nesta fase — que é também o que mantém vivo o carimbo
de mutação re-emitido aqui.
