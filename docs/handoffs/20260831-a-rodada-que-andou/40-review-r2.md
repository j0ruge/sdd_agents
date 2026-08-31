---
missao: 20260831-a-rodada-que-andou
fase: REVIEW
rodada: 2
status: done
sessao: f15ba486-81f2-4fec-bf7e-1e0f5093a9d6
data: 2026-08-31 17:05
gate: "`tests/run-all.sh` → `suite green`, **842 asserções `ok`, 0 FAIL, rc 0**, ~100 s, rodado depois de cada commit desta rodada e uma última vez em `d4886e6`. Árvore limpa (`git status --short` vazio). Os 4 mutantes novos medidos como o catálogo mede — sandbox fiel (`bin tests templates config agents CLAUDE.md TODO.md docs/adr`), **controle íntegro rc 0** e cada mutante rc 1 matando exatamente a asserção nomeada no seu cabeçalho; catálogo em `217 entradas / 217 funções`, sem órfão, e **varredura de âncora podre sobre os 217 contra o `bin/sdd` de hoje: `ok=217 noop=0 syntax=0`** — nem a r1 nem esta rodada apodreceram âncora nenhuma. Os dois mutantes que a r1 criou foram **re-medidos** depois do conserto do eixo (rc 1 nos dois, matando as mesmas asserções): o conserto desta rodada não deixou órfão o da r1. `./bin/sdd preflight` verde ponta a ponta, incluindo `7 kit agent(s) checked` e `working tree clean`. As duas HIGH reproduzidas ANTES do conserto em fixture de ledger real (`SDD_STATE_DIR`) e re-lidas depois: os dois ledgers passam a responder idêntico. Métrica (1) re-conferida no ledger real: `d89ea43`, `e9a3681` e `353b4b1` em `1 advanced · 0 churned · 0% waste`, `bf001fe` inalterada em `23 session(s) · 21 advanced · 2 churned · 0 idle · 8% waste · 3 mission(s) · US$ 175.96`. ⚠️ O carimbo de mutação segue MORTO — esta rodada commitou em `bin/`, `tests/` e `tests/health-baseline.txt`; quem re-carimba é a DOCS, antes do `gate_PR`."
---

# Review — rodada r2 — A rodada que andou

## TL;DR

A r1 fechou em `B` por Test Coverage, com duas portas do escritor do I4 sobrevivendo à sabotagem.
As duas foram fechadas nesta sessão com sabotagem **medida** (`594ef07`), e junto saiu um item
irmão de `20260829`. Depois disso a r2 atacou o ângulo que a r1 **não** tomou — os *outros*
consumidores do evento novo — e achou **duas HIGH da mesma raiz**: a r1 impediu a CÉLULA fantasma
e deixou passar a **VERSÃO** fantasma, no eixo em que o juiz inteiro se apoia. Corrigidas em
`c4a114e` com asserção diferencial. **Seis achados: três consertados, um no `TODO.md`, um como
limite declarado, um refutado.** Todos os critérios em `A`.

## Nota da rodada

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | A | A HIGH foi fechada por UMA definição (`shas_in_file_order`), não por dois remendos nos dois chamadores, e escrita positivamente (`session or escalation`) para que um quarto evento tenha de optar por cunhar versão em vez de cunhar por omissão. |
| Type Safety | A | Guardas de nulo re-verificadas contra jq 1.7 medido nos caminhos novos; a closure não carrega chave de sessão e nenhum leitor erra nela — `has("moved")` responde `false` e ambos os `comparable` testam `.event` antes, então o braço `has` nunca roda em linha que não poderia satisfazê-lo. |
| Error Handling | A | `set -euo pipefail` varrido nos sítios novos; o bloco `jq` é uma string shell de aspas simples e a única violação (uma apóstrofe minha) morreu alto em `bash -n`, não em silêncio — o limite passou a estar declarado no próprio comentário. |
| Security | A | Varredura determinística sobre o diff completo (`scan_secrets.sh`): `{"findings": [], "errors": []}`. Nenhuma entrada externa entra em shell; todo valor chega ao `jq` por `--arg`. |
| Performance | A | O conserto do eixo acrescenta um `select` a um `reduce` que já percorria a mesma lista — mesma ordem de grandeza, medido idêntico no ledger real (121 versões). Nenhum gate a mais roda. |
| Test Coverage | A | As duas portas que compraram o `B` da r1 fecharam com sabotagem medida sítio a sítio, e as outras duas da mesma função foram MEDIDAS inertes (suíte verde sabotada) e viraram limite declarado em vez de cobertura alegada. 9 asserções e 4 mutantes novos, cada mutante provado em sandbox com controle verde. |
| Documentation | A | A tabela de campos do contrato foi conferida chave a chave contra o construtor da linha `gate_pass` e está correta — a prosa acima dela define "on escalation rows" como cobrindo a closure e nomeia as duas exceções. Os dois limites novos entraram no comentário do código, com o mundo nomeado. |
| **Overall** | **A** | Duas HIGH da mesma raiz reproduzidas, consertadas por uma definição e presas por asserção diferencial; o laço fecha porque o que sobra está medido e declarado, não alegado. |

## Achados da rodada

| # | Severidade | Achado | Onde |
|---|---|---|---|
| 1 | HIGH | Uma linha `gate_pass` **cunha uma versão** no eixo do juiz: `latest` passa a apontar para uma fatia com `sessions: 0`, `previous` desliza, e o `gate_KAIZEN` deriva dali o sha esperado — gate insatisfazível | `bin/sdd:5195`, `:5419` |
| 2 | HIGH | A mesma linha vira `guard.degenerate_axis` de `true` para `false` e emudece o `kaizen_axis_note` no único repo onde a frase dele é sempre verdadeira | `bin/sdd:5198`, `:5241` |
| 3 | MEDIUM | A guarda de fase da foto de REVIEW no `cmd_retry` sobrevive à sabotagem (herdado da r1, achado #6) | `bin/sdd:4575` |
| 4 | MEDIUM | A escrita de `gate_failed` no retry inline sobrevive à sabotagem, sob comentário que invoca "um probe por porta" (herdado da r1, achado #7) | `bin/sdd:4516` |
| 5 | MEDIUM | `reopened` é cego à closure: mesma história de pipeline responde `0` ou `1` conforme a fase ter CUSTADO dinheiro | `bin/sdd:4849` |
| 6 | LOW | `historic_progress` não limpa a memória numa closure — inconstruível por ordem de escrita | `bin/sdd:2050` |

## O que foi corrigido

- **#1 e #2 — a versão fantasma — corrigidos em `c4a114e`, uma definição para as duas.** A r1
  consertou a metade de baixo desta frase (o filtro `$detail` do `group_summary`, que impede a
  CÉLULA) e deixou a de cima: o `shas_in_file_order` rodava sobre `$ok`, e o `comparable_row`
  admite closure porque `.event != "session"` curto-circuita o braço `has("moved")`.
  **Reproduzido antes do conserto**, com UMA linha acrescentada a um ledger de fixture:
  `latest` `ccc3333` → `ddd4444` (`sessions: 0`), `previous` `bbb2222` → `ccc3333`,
  `labels` `{ok:1}` → `{ok:0}`, `degenerate_axis` `true` → `false`. **É o caso NORMAL do repo do
  kit**, por construção: aqui toda sessão commita, então o sha anda entre a fase cujo gate reprovou
  e a volta que a fecha de graça — a closure pousa num sha que sessão nenhuma tocou. O custo a
  jusante foi reproduzido junto: o `gate_KAIZEN` deriva o sha esperado de `latest.kit_sha`, logo um
  veredito já escrito deixa de satisfazer o gate e o `sdd kaizen` compra uma sessão opus para julgar
  uma fatia com **zero sessões** — gate insatisfazível, a classe que o princípio 1 do `CLAUDE.md`
  proíbe e que custou US$ 73,32 em `frete-cif-fob`. Sensor: bloco
  `a closure does not mint a version of its own`, com asserção **diferencial** (dois ledgers
  idênticos menos a linha, saídas comparadas uma com a outra) e piso contra vacuidade, mais
  `mut_LEDGER_gate_pass_mints_a_version` — medido em sandbox: âncora morde uma linha só, `bash -n`
  válido, rc 1, e a única asserção que morre é a diferencial.
- **#3 e #4 — as duas portas que compraram o `B` da r1 — corrigidos em `594ef07`.** O probe do
  `cmd_retry` mora onde o mundo já existe de graça (depois do bloco do `gate_pass`, com o arquivo de
  rodada e o checkpoint cheio no disco), que é o único estado em que a sabotagem é **alta**
  (`rounds_before: 1` numa linha DOCS) em vez de um `0` ambíguo. O do retry inline precisou do
  mundo que **todo fixture deste arquivo perdia**: um retry que PASSA seguido de mais uma volta —
  todos os outros terminam num retry que falha, onde a sabotagem é invisível. Três mutantes novos,
  cada um medido em sandbox com controle íntegro verde.
- **A metade EXEC do irmão de `20260829` fechou no mesmo commit** (`594ef07`): a foto ganhou probe
  e mutante próprios; a leitura pós-gate foi medida inerte e virou limite declarado.

## O que foi refutado

- **A tabela de campos do `docs/pipeline.md` NÃO está em deriva sobre a linha `gate_pass`, e eu
  quase registrei que estava.** A coluna "Absent when" diz apenas "on escalation rows" para
  `moved`, `rc`, `cost_usd`, `rounds_*` e mais dez chaves, enquanto o construtor
  (`autonomy_gate_pass_row`) escreve **onze** chaves e nenhuma delas. Parecia a mesma classe do
  achado #4 da r1. **Verificado antes de escrever:** a prosa imediatamente acima da tabela define o
  marcador — *"Escalation and gate-closure rows carry only the columns marked 'on escalation rows'
  in 'absent when'"* — e nomeia as duas exceções (`kind`, `gate_why`). O contrato está completo;
  quem estava errado era a leitura, não a tabela.
- **As duas outras guardas do `cmd_retry` (`review_after`/`exec_after`) NÃO são achado, e a razão
  foi medida e não suposta.** Sabotadas uma a uma, a suíte fica **verde**, enquanto as duas fotos a
  deixam **vermelha** — porque a função só chama `gate_"$phase"` da fase que retenta e o
  `current_phase()` roda os gates dentro de `$( )`, cujas atribuições morrem no subshell, deixando
  os dois globais na string vazia da declaração. Ficam porque decidem QUAL falha o próximo escritor
  recebe. Está escrito no comentário como *"o mundo que este fixture não constrói"*, e nunca como
  *"esse mundo não existe"* — a distinção que `d4deb35` errou e `7cbc8e2` teve de desfazer.
- **O `sdd health` NÃO foi rodado nesta sessão, e isso é decisão e não omissão.** O catálogo leva
  20–50 min e a chave do carimbo inclui `tests/health-baseline.txt`, que esta rodada mexeu: rodá-lo
  aqui produziria um carimbo que o próximo commit mataria. Quem carimba é a última fase que commita
  em `bin/ tests/ templates/ config/` antes do `gate_PR` — na prática a DOCS. Foi exatamente esse
  laço que matou três sessões de REVIEW com as palavras *"waiting for the suite"*.

## Achados fora de escopo

- **#5 — `reopened` cego à closure** — registrado no `TODO.md` (2026-08-31), `d4886e6`. Medido:
  mesma história de pipeline, `0 reopened` com a closure gravada como `gate_pass` e `1 reopened`
  com a MESMA closure comprada com sessão. **Não** consertado aqui de propósito: admitir closure em
  `$every_session` move junto o `history_extra`, que é número de tela, e conserto de raio maior no
  fim da rodada é como as cinco rodadas do `check-todo.sh` criaram, uma a uma, o defeito que a
  seguinte achou. Catraca do backlog `91` → `92`, no mesmo commit.
- **#6 — a memória do `historic_progress`** — **não** virou linha de backlog, e a régua D15 é o
  porquê: o mundo é **inconstruível por ordem de escrita** (o caminho datado só anota linha com
  `pending_before` nulo, o que desde 2026-08-29 quer dizer linha escrita antes daquela data, e o
  `gate_pass` nasceu em 2026-08-31). Dívida declarada é limite; virou comentário no `bin/sdd`, com
  o mundo nomeado, o número medido e a direção do conserto. Registrar seria apontar para um mundo
  que nada constrói.

## Pendências / Decisions for a Human

- **A missão se provou em produção nesta rodada, e o número é o argumento.** A linha de REVIEW da
  r1 — US$ 37,10, gate **reprovado** (Grade B) — é a primeira linha real com os três campos novos,
  e o leitor a lê como `1 advanced · 0 churned · 0% waste`. Antes desta missão essa mesma linha
  seria `100% waste`. É a métrica (1) medida sobre linha nova, e não só sobre o caminho datado.
- **O conserto das duas HIGH não mexe em nada no ledger real HOJE, e o piso diz por quê:** há
  **zero** linhas `gate_pass` em produção. Os dois `bin/sdd` respondem idêntico sobre o ledger real
  — o que torna essa checagem de regressão honesta e **vazia por construção**. É exatamente por isso
  que o defeito teria embarcado calado: ele só acorda na primeira fase que fechar de graça, e aí o
  eixo já estaria errado.
- **O carimbo de mutação está morto e a DOCS é quem re-carimba.** `./bin/sdd health --with-mutation`
  (20–50 min) roda **depois do último commit de código** e antes do `gate_PR`; o catálogo tem agora
  **217** mutantes. ⚠️ Registrar qualquer achado novo no `TODO.md` mata o carimbo de novo.
- **A régua mudou mais uma vez dentro da janela** (grill de 2026-08-31, decisão 1): o eixo de hoje
  não é o de `080f503`. Quem citar rótulo ou contagem de versão depois desta missão tem de dizer com
  qual `bin/sdd` leu — e o achado #1 significa que qualquer leitura de `latest`/`previous` feita
  entre `715da79` e `c4a114e`, num ledger que já contivesse uma closure, pode nomear a fatia errada.
- **A métrica (3) é da DOCS e continua em aberto — e os números dela não mudaram nesta rodada.**
  O `KAIZEN_LOG.md` ainda não tem a entrada desta missão; o `20-handoff-exec.md:110` e o
  `agents/sdd-docs.md:44` já atribuem isso à DOCS, então não é defeito. O que a r2 acrescenta é a
  garantia de que a DOCS **não precisa re-medir**: os dois `bin/sdd` (antes e depois do conserto do
  eixo) respondem **idêntico** sobre o ledger real, em `autonomy --all-repos` e em `kaizen --series`.
- **`sdd approve 20260831-a-rodada-que-andou`** segue sendo o único destravamento do plano
  kaizen-born — contrato do `gate_PLAN`, não pendência desta fase.
