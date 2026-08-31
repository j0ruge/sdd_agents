---
missao: 20260831-a-rodada-que-andou
fase: QA
status: done
sessao: d84cff95-7eab-4da3-b925-5f46f843ced6
data: 2026-08-31 13:25
gate: "Projeto SEM interface (`E2E_CMD=\"\"` e nenhum `APP_URL` no `.sdd/config.sh`) — a evidência da jornada percorrida é este campo. **Cinco jornadas de linha de comando caminhadas nesta sessão**, todas rc 0: (1) `./bin/sdd autonomy --all-repos` → tabela de 121 versões; `d89ea43`/`e9a3681`/`353b4b1` em `1 advanced · 0 churned · 0% waste` e `bf001fe` inalterada em `23 session(s) · 21 advanced · 2 churned · 0 idle · 8% waste · 3 mission(s) · US$ 175.96`, que é a métrica (1) reescrita, letra por letra. (2) `./bin/sdd autonomy` (local) → `124 counted`, mais `68 row(s) excluded: born in another repo` declarados FORA do cabeçalho. (3) `./bin/sdd autonomy --all-repos --by-mission` → 14 missões, esta em `4 session(s) · 3 advanced · 1 churned · 2 launch(es) · 1 intervention note(s)`, batendo com o único `- intervention:` do checkpoint. (4) `./bin/sdd kaizen --series` → `excluded.unrecognized: 0` (ponto crítico 3 do handoff de EXEC), `guard.sufficient false` numa janela recém-aberta. (5) `./bin/sdd status 20260831-a-rodada-que-andou` → `✓ EXEC 4 increment(s) done`, `next phase: QA`. **Aritmética dos cinco baldes fechada por medição independente, nos dois escopos:** global `173 + 15 + 4 + 0 + 0 = 192` e local `116 + 7 + 1 + 0 + 0 = 124`, ambos iguais ao total do cabeçalho — nenhuma linha some. **Métrica (1) re-medida por diff e não por prosa:** `bin/sdd` da base (`bf001fe`) contra o da árvore, sobre o MESMO ledger, movem exatamente três fatias e nada mais (nem custo, nem contagem de missão), com piso de 121 linhas de tabela nos dois lados. **Métrica (2) verificada com o leitor real, não só na suíte:** ledger de fixture com o laço QA-reprova→EXEC→`gate_pass`, `SDD_STATE_DIR` apontado para ele — a fase QA lê `leve` COM a linha `gate_pass` e `refez` SEM ela, que é exatamente o prometido (o `refez` deixa de ser afirmado, a célula não vira `ok` falso). A frase nova do leitor humano (`1 gate(s) closed without a session`) aparece só no mundo que tem a linha. `TEST_CMD` (`tests/run-all.sh`) → `suite green`, **826 asserções `ok`, 0 FAIL, rc 0**; os quatro Checks do checkpoint re-rodados um a um, `1` cada. Árvore limpa. **Nenhum bug confirmado ⇒ nenhum incremento `F<n>` e nenhuma spec nova.**"
---

# Handoff — QA — A rodada que andou

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

Cinco jornadas de linha de comando caminhadas, zero achados confirmados, zero bugs sanáveis ⇒
nenhum incremento `F<n>` e nenhuma spec nova. As duas métricas foram **re-medidas por esta sessão**
em vez de aceitas do handoff de EXEC: a (1) por diff dos dois `bin/sdd` sobre o mesmo ledger real
(exatamente três fatias se movem), a (2) por um ledger de fixture com a linha `gate_pass` (a QA lê
`leve` com ela e `refez` sem ela). A REVIEW é a próxima e é ela quem produz a **primeira linha real
de REVIEW com os três campos novos** — o único pedaço do escritor que o ledger de produção ainda
não exercitou.

## Estado do repo

- **Branch:** `feat/a-rodada-que-andou` — 6 commits à frente de `main` (`bf001fe`), nunca empurrada.
- **Último commit:** `48ae925` `docs(missao): o catálogo fecha em 211 de 211, com carimbo` (mais o
  commit desta fase, que acrescenta só este handoff e uma nota ao checkpoint).
- **Working tree:** limpo. Esta fase **não tocou em código**: `bin/`, `tests/`, `templates/` e
  `config/` saem intocados, então o carimbo de mutação `829412c3ad9101d48b6c492b9cf42520` continua
  válido ao entrar na REVIEW.
- **Suíte:** `tests/run-all.sh` → **verde**, 826 asserções `ok`, 0 FAIL, rc 0, ~100 s.
- **E2E:** `E2E_CMD=""` e nenhum `APP_URL` — este repo é um script bash e seis markdowns. Não
  rodou porque não existe, e o `gate_QA` já sabe disso (`bin/sdd:861`): sem interface ele lê o
  campo `gate:` deste arquivo, e não o relatório datado das skills.

## O que foi feito

> **Nenhum commit de código, e isso é o resultado e não uma omissão.** O `sdd-qa` não conserta
> produção: bug sanável viraria `F<n>` no checkpoint. Não houve.

**As cinco jornadas, e o que cada uma devolveu:**

| # | Jornada | O que observei |
|---|---|---|
| 1 | `./bin/sdd autonomy --all-repos` | 121 versões. As três fatias da métrica em `1 advanced · 0 churned · 0% waste`; `bf001fe` inerte, como a métrica reescrita manda |
| 2 | `./bin/sdd autonomy` (local) | `124 counted` + `68 born in another repo`, estes declarados **fora** do cabeçalho — 124 + 68 = 192 |
| 3 | `./bin/sdd autonomy --all-repos --by-mission` | 14 missões; esta com `1 intervention note(s)`, batendo com o único `- intervention:` do checkpoint |
| 4 | `./bin/sdd kaizen --series` | `excluded.unrecognized: 0`; `guard.sufficient false` — janela recém-aberta, não julgável ainda |
| 5 | `./bin/sdd status 20260831-a-rodada-que-andou` | `✓ EXEC 4 increment(s) done`; `next phase: QA` |

**Os três pontos que o handoff de EXEC mandou olhar com olho crítico, um a um:**

1. **A frase nova do leitor humano.** No ledger real ela **não sai**, porque há `0` linhas
   `gate_pass` — o esperado, não uma falha. Como isso torna o I4 invisível em produção, construí o
   mundo em que ela existe (`SDD_STATE_DIR` para um ledger de fixture com o laço
   QA-reprova → EXEC → `gate_pass` → REVIEW) e a li na tela:
   `(1 gate(s) closed without a session — the pipeline moved on for free, recorded rather than
   inferred)`. Com a mesma linha removida por `grep -v`, a frase some e as contagens de sessão
   ficam idênticas (`3 session(s) · 2 advanced · 1 churned` dos dois lados) — a linha nova não
   contamina a aritmética.
2. **A aritmética dos cinco baldes**, medida contra o `jq` e não lida da tela, **nos dois escopos**:
   global `173 comparáveis + 15 não-comparáveis + 4 escalações + 0 fechamentos + 0 não-reconhecidas
   = 192`, igual ao `192 row(s)` do cabeçalho; local `116 + 7 + 1 + 0 + 0 = 124`, igual ao
   `124 counted`. Confirmei também de onde vem o `15` da frase (12 sessões + 3 escalações sujas):
   ela diz `row(s)`, não `session(s)`, e está certa.
3. **`excluded.unrecognized`.** `0` no ledger real **e** `0` no fixture que de fato contém a linha
   `gate_pass` — que é o teste que importa, porque foi exatamente aí que o defeito medido durante o
   I4 aparecia (`1`, o juiz acusando bug do próprio kit).

**As duas métricas, re-medidas por esta sessão:**

- **Métrica (1), por diff e não por prosa.** `git show bf001fe:bin/sdd` contra o `bin/sdd` da
  árvore, sobre o **mesmo** ledger real: movem-se exatamente `d89ea43`, `e9a3681` e `353b4b1`, cada
  uma de `0 advanced · 1 churned · 100% waste` para `1 advanced · 0 churned · 0% waste`. Nenhuma
  outra linha, nenhum custo, nenhuma contagem de missão. `bf001fe` não aparece no diff — inalterada,
  como a métrica reescrita prevê. Com piso: os dois leitores imprimem 121 linhas de tabela, então
  nenhum dos dois estava quebrado quando concluí.
- **Métrica (2), no leitor real e não só na suíte.** Sobre o fixture, a fase QA que fechou sem
  gastar sessão lê **`leve` com a linha `gate_pass` e `refez` sem ela**. É letra por letra o que o
  `00-missao.md` § Métrica (2) promete — e o que ele proíbe (prometer `ok`) não aconteceu: a sessão
  sobrevivente continua `churned` por conta própria e a cascata pousa em `leve`.

**O caminho datado do I3, conferido linha a linha.** A frase da tela diz
`19 REVIEW row(s) older than the round fields read their round from gate_why`. Reproduzi a regra
exata de `historic_rounds` contra o ledger: das 25 linhas de REVIEW, **24 são anotadas** (22 pela
forma `40-review-r<N>.md` e 2 pela forma `no 40-review-r<N>.md`) e **1 escapa** — a de
`TEST_CMD failed`, que é uma das duas recusas que o handoff de EXEC declarou irrecuperáveis. Das 24,
cinco saem depois como não-comparáveis (kit sujo, todas nomeadas), sobrando **19**. O número da tela
é honesto e é contado **depois** da comparabilidade, como o irmão do EXEC passou a ser em `7a34766`.

## Artefatos

| Arquivo | O que contém |
|---|---|
| `docs/handoffs/20260831-a-rodada-que-andou/30-handoff-qa.md` | Este arquivo; o `gate:` carrega a evidência das cinco jornadas (caminho sem interface) |
| `docs/handoffs/20260831-a-rodada-que-andou/checkpoint.md` | Uma nota de QA nova; a tabela de incrementos **não mudou** — 4 de 4 `done`, nenhum `F<n>` |
| `docs/qa/` | **Lido, não escrito.** A árvore é das skills `qa-report`/`qa-execution`; nenhum bug está `open` (4 `verified`, 1 `fixed`, 1 `verified`), então a Âncora 3 do `gate_QA` está satisfeita sem eu tocar em nada |

## Boot da próxima fase

A REVIEW é a próxima. **Leia este handoff, depois o `20-handoff-exec.md`, depois as notas de
execução do `checkpoint.md`** — é lá que moram as 18 linhas de sabotagem medida que sustentam os
consertos.

**O que esta sessão de QA sabe e a REVIEW precisa:**

1. **A REVIEW é quem produz a primeira linha real de REVIEW com os três campos novos.** Hoje o
   ledger tem **exatamente uma** linha com `rounds_*`, e é a de **EXEC** desta missão, com os três
   em `null` — a guarda de fase funcionando. O escritor de REVIEW está provado na suíte e **não**
   no ledger de produção. Depois da sua sessão, confirme com uma linha:
   `jq -c 'select(.phase=="REVIEW" and .rounds_before!=null)' ~/.sdd/autonomy-log.jsonl | tail -1`
   — se vier vazia, o escritor não disparou no caminho real e isso é achado de verdade.
2. **O carimbo de mutação (`829412c3ad9101d48b6c492b9cf42520`) está válido e a QA não o matou.**
   A REVIEW conserta dentro da própria sessão, então é **quase certo** que ela o mate. Quem tem de
   rodar `./bin/sdd health --with-mutation` (20–50 min) é a última fase que commitar em
   `bin/ tests/ templates/ config/` antes do `gate_PR` — na prática, a DOCS. ⚠️ E
   `tests/health-baseline.txt` está dentro da chave: **registrar achado no `TODO.md` mata o
   carimbo.**
3. **`./bin/sdd health` roda o catálogo mesmo SEM `--with-mutation`** (~15–30 min). Não é "check
   rápido". Se você só quer saber se a suíte passa, é `tests/run-all.sh`, ~100 s.
4. **Uma assimetria medida entre os dois programas, que não é bug e que você vai encontrar se
   olhar:** ver "Riscos e não-feitos" abaixo. Está reproduzida com comando para você poder
   discordar com evidência, em vez de re-descobrir do zero.

## Pendências / Decisions for a Human

> Só julgamento humano genuíno (política de UX, decisão de produto, pagamento real, acesso
> externo). **Não bloqueiam o pipeline** — viram seção do PR. Bug sanável não entra aqui: vira
> incremento de fix no `checkpoint.md`.

**Nenhuma nova nesta fase.** As três que existem já foram decididas e estão registradas — repito-as
aqui só como ponteiro, porque o PR as cita:

- **A régua mudou no meio da janela de medição, de propósito** (grill de 2026-08-31, decisão 1).
  Quem citar os números da janela 2 depois desta missão tem de dizer com qual `bin/sdd` os leu. O
  aviso está no `05-verdict.md`. Esta sessão **confirmou o tamanho da mudança**: três fatias, e só.
- **O destino do alvo "suíte < 30 s" da D7** ficou para a triagem do próximo `sdd kaizen`, com o
  número na mesa (15 mutantes novos nesta missão; suíte rápida em ~100 s, catálogo em 211).
- **`sdd approve 20260831-a-rodada-que-andou`** segue sendo o único destravamento do plano
  kaizen-born — não é pendência desta fase, é o contrato do `gate_PLAN`.

Nenhum bug foi marcado `Closable by: human` porque **nenhum bug novo foi aberto**.

## Riscos e não-feitos

- **Uma assimetria real entre o leitor e o juiz, medida, declarada no código, e que decidi NÃO
  registrar como achado.** Uma linha `gate_pass` escrita com o kit **sujo** é contada pelo leitor
  (`sdd autonomy` imprime `1 gate(s) closed without a session`) e **excluída** pelo juiz
  (`kaizen --series` devolve `non_comparable: 1` e a QA volta a ler `refez`). Reprodução:
  `sed 's/"kit_dirty":false/"kit_dirty":true/'` na linha `gate_pass` do fixture e rodar os dois
  leitores. **Por que não é bug:** o balde `$closed` é *incondicional* de propósito e o comentário
  em `bin/sdd:4904` diz o porquê — ele existe para que a soma FECHE, e um balde de contabilidade
  que filtrasse deixaria a linha sair do total sem sair em lugar nenhum, que é
  "`unrecognized` com o alarme desligado". O juiz filtra porque o trabalho dele é medir sobre o
  eixo `kit_sha`. Cada tela é honesta sobre a própria população, e o juiz **declara** a exclusão.
  Pela régua D15 não entra no `TODO.md`: não é fail-open (a frase do leitor é verdadeira para uma
  linha suja — o gate fechou mesmo sem sessão) e o humano tem o `non_comparable: 1` na tela ao lado
  explicando a diferença. ⚠️ Registro explicitamente que **a decisão foi pela régua e não pelo
  carimbo**: preservar o carimbo de mutação é consequência, não motivo. Se a REVIEW discordar, o
  comando de reprodução está aqui.
- **O escritor do I1 no caminho de REVIEW não foi exercitado em produção** — só na suíte. É o item
  1 do boot acima, e a própria fase REVIEW o fecha.
- **O I4 é inerte no ledger real** (`0` linhas `gate_pass`) e povoa da próxima corrida em diante.
  Tudo o que afirmo sobre ele nesta fase foi medido em fixture pelo leitor real, nunca inferido.
- **O limite declarado do I4 continua de pé e eu não consegui falsificá-lo:** a fase cuja sessão foi
  paga na corrida *N* e cujo gate fecha de graça na corrida *N+1* não gera linha, porque `sessions`
  morre com o processo. Não construí esse mundo — ele exige duas corridas reais —, e digo isso em
  vez de dizer que ele não existe.
- **Não caminhei `sdd run`, `sdd retry` nem `sdd health --with-mutation`.** Os dois primeiros
  gastam sessão paga; o terceiro é do `gate_PR` e custa 20–50 min. O `sdd health` sem flag foi
  disparado e ainda rodava ao fim desta sessão — não é evidência deste gate e não está no `gate:`.
- **A árvore `docs/qa/` não foi tocada.** Ela é das skills `qa-report`/`qa-execution`, que nunca
  rodaram neste repo (projeto sem interface). Li os 6 arquivos de `bugs/` para conferir a Âncora 3
  do `gate_QA` — nenhum `open` — e não escrevi nada. Árvore que não criei não é árvore que eu possa
  apagar (`9f84cbc`).

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

**Nenhum, e a ausência é medida e não preguiça.** O repo desta missão **é** o kit, então um achado
iria para o `TODO.md` daqui e mataria o carimbo de mutação através de
`tests/health-baseline.txt` — motivo pelo qual a decisão de não registrar precisa ser defensável
sozinha, e é: a única coisa que encontrei fora do caminho feliz é a assimetria leitor × juiz da
seção acima, que reprova nas duas portas da régua D15 (não é fail-open, e é declarada no código com
o argumento). Está escrita nos "Riscos" com o comando de reprodução, que é onde o `CLAUDE.md` manda
pôr dívida declarada.
