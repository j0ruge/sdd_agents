# A gaveta do kit — tudo o que está planejado e parado, num lugar só (2026-09-23)

> **Por que este arquivo existe.** Até hoje os planos parados do kit moravam fora do repo:
> em `~/.claude/plans/` (sem versionamento) e num branch local nunca empurrado
> (`docs/worker-roadmap`, com o spec do worker). Uma troca de máquina ou uma limpeza do `$HOME`
> os levaria. Regra daqui em diante: **plano de kit mora em `docs/superpowers/specs/`**, e este
> índice é atualizado no mesmo commit em que uma frente anda, fecha ou nasce.
>
> O estado de cada frente foi levantado em 2026-09-23 a partir de artefato (commit na `main`, PR
> mergeado, issue fechada), não do título do plano. Onde há número, a fonte está ao lado.

## Índice

| # | Frente | Estado | Próximo passo | Espera por |
|---|---|---|---|---|
| F1 | Custo do catálogo de mutação | PR #59 mergeado (`d0ac22d`); P2(a) feito em 2026-09-25 (assassino primeiro, amostra 389 → 171 s, `sdd health` 1h27 → ~38–40 min); P2(b) **FEITO**, PR #170 mergeado (`31dfd43`; o sensor para no primeiro FAIL, [spec](2026-09-25-o-sensor-para-no-primeiro-fail-design.md), amostra 1328,7 → 571 s, `sdd health` 37 min 42 s → **~18 min**, carimbo 406/406 válido na `main`); P1, P3, P4 abertos | E6 do #170 **feito** em 2026-09-26 (espelho 82 ↔ 82, #144 fechada, PR #171; [handoff](../plans/2026-09-25-depois-do-170-handoff.md)). O P3 **ficou fora** da carona (`20260926-a-carona-antes-do-congelamento`, decisão 6 do grill): é pré-requisito do próximo aumento de paralelismo, que não acontece com o kit congelado | o fim da janela 4 (F3) |
| F2 | Faxina pós-#57 | **fechada** pela missão `20260926-a-carona-antes-do-congelamento` (I7; o yokoten da crase no I1) | nada | — |
| F3 | T3 e a janela do juiz | janela 1 **fechada**: veredito `melhorou` sobre `4fd0f31` (PR #175, `3d350ed`). Dos 8 achados, 5 foram consertados na missão `20260928-os-achados-da-janela` (3, 4, 6, 7 e 8; PR #176) e 3 foram para o `TODO.md` (1, 2 e 5). Janela 2 **fechada sem veredito** em 2026-09-30: `indeterminado` sobre `6323c6f`, porque o PR #184 (só `TODO.md` + catraca) cunhou um `kit_sha` novo e deixou as 3 missões de `5b98087` em `previous` (`window_missions_stranded: 3`); o achado está no `TODO.md`. Janela 3 (aberta no merge do PR #185, missão `20260930-a-sub-etapa-que-andou`) **abandonada por decisão humana em 2026-10-01, sem veredito**: o kit descongela para a missão `20261001-a-janela-nao-se-parte` (ADR 0014), que conserta a causa — o eixo passa a agrupar pelo último commit de comportamento (`kit_rev`, de `bin agents templates config`) e a chave do carimbo deixa a catraca de fora, então um PR só de `TODO.md` deixa de partir a janela e de matar o carimbo. **A janela 4 abre no primeiro carimbo de alvo após o merge desta missão** | merge de `20261001-a-janela-nao-se-parte` → 3 missões de alvo com sessão sobre a mesma versão de comportamento → `sdd kaizen`; a T3 se desfez em 2026-10-04 (§ F3) | a missão `20261001-a-janela-nao-se-parte` |
| F4 | Portabilidade para outros repos | sem pendência de código: lacunas 2 e 3 **consertadas** na missão `20260926-a-carona-antes-do-congelamento` (I5, I6), 4 e 5 no `TODO.md` (I7), 6 declarada no ADR 0007 | a prova num 2º alvo, que conta para a próxima janela do juiz | nada desde o veredito (F3, PR #175) |
| F5 | Issues avulsas #50–#53 | #53 fechada; #50, #51 e #52 consertadas na missão `20260926-a-carona-antes-do-congelamento` (I1–I4) | as três fecham com o merge do PR | — |
| F6 | O worker (W1–W7) | estacionada por decisão | nada, até os fluxos atuais rodarem limpos | **decisão humana** |
| F7 | Plano Astra, fases 2–7 | não iniciada | nada; vem depois do worker | F6 |
| F8 | O plano mede contra a base, não contra os incrementos anteriores | nota de 2026-10-05, da execução do lote 4; sem missão | uma frase no `sdd-planner` (§ F8) | a próxima missão de kit depois do lote 4 |

Fechados, para ninguém reabrir: o laço do fingerprint (#54–#56 → missão
`20260922-o-motivo-da-fase`, PR #57, merge `2258e53`); o fluxo `develop → staging → main` com o
`sdd close` voltando para `develop` (`147add7` no kit; ADR 0003 no `lighthouse_project`); T1 (PR #46);
T2 (PR #47, com o I6 no PR #174 do `sales_quote`); o número do ADR (PR #45); a fase 1 do Astra, "um
checkout, um dono de execução" (PR #48, merge `589a7bc`), que também é o W1 do worker; o effort por
fase, `EFFORT_<FASE>` e `--effort` (PR #166, merge `c81dd46`), que nunca esteve aqui como frente.

---

## F1 — O custo do catálogo de mutação

> Nasceu no PR #59 (`perf/catalogo-para-no-primeiro-vermelho`, mergeado em `d0ac22d`). Todo número
> foi medido em 2026-09-23 com o comando ou a amostra citada; estimativa está marcada como tal.

**De onde se partiu.** O `sdd health` sobre o catálogo de 389 mutantes levou **3h05** (`589a7bc`,
23:57 → 03:02) e **3h23** (`54af87e`, 10:23 → 13:47). O "meia hora" que esteve escrito no `e1d0c49`
e no `CLAUDE.md` nunca foi medido. A conta é `mutantes × suíte comportamental ÷ jobs`, e os três
termos pioraram:
- a suíte rodava inteira com o mutante já pego;
- o teto de jobs era 8, sem medição por trás;
- o PR #48 levou a suíte comportamental de **117 s para 251 s**, porque uma chamada coordenada do
  `bin/sdd` passou de **35 para 126 ms** (`sdd install` ×20).

Decomposição de uma chamada coordenada: o bash lê o `bin/sdd` (~15 ms, duas vezes), sobem 2
processos Python (~22 ms cada: o `enter` e o `check` do worker), e há 4× `git rev-parse` antes do
trabalho de fato.

**O que entrou no PR #59.**

| alavanca | medido |
|---|---|
| Sob `SDD_MUTANT`, a suíte para no primeiro sensor vermelho | amostra fixa de 40 mutantes: mediana 226 → 133 s, 40/40 pegos antes e depois |
| Teto de jobs de 8 para 16 | mesma amostra: 133 → 160 s por mutante, catálogo projetado ~1h58 → ~1h06 |
| Helper com `python3 -I -S` e supervisor acordado pelo pidfd | 158 → 147 ms por chamada coordenada (`sdd install` ×60, versões alternadas) |
| Primeiro carimbo real, com a máquina livre | 1h24 (17:39 → 19:03), vermelho 391/392 por um probe cego sob carga, depois consertado |
| Carimbo final do #59 (`b4d2c3e`) | **1h21** (19:46 → 21:08), verde 392/392, com ~30 min disputando CPU com um `vitest` de outro projeto (load 46) |

**Próximas alavancas, em ordem de custo-benefício.**

- **P1. Dispensar o 2º Python do worker** (~30 ms por chamada coordenada). O worker relê o
  `bin/sdd` e sobe um Python (`check`) só para provar que é o worker legítimo. Direção: o
  supervisor entrega ao worker um FD do próprio flock; o worker o verifica (`/proc/self/fdinfo`,
  mesmo inode do lock) e fecha **antes do primeiro fork**, para nenhum descendente herdar a prova.
  Pede **ADR**, porque mexe na autorização de reentrada ("ambiente sozinho não autoriza"). Check
  antes: `copied owner environment is not authorization` e `forged environment is not
  authorization` continuam recusando o impostor, e um probe novo recusa o descendente sem o FD no
  caso `pipeline`. Saiu do `TODO.md` como decidido em 2026-10-03
  (`20261003-lote-3-a-catraca-desce`): o plano mora aqui.
- **P2. Catálogo mais barato por estrutura**, a maior alavanca que resta sem trocar linguagem.
  - **(a) Mutante → sensor alvo. FEITO em 2026-09-25**, derivado dos logs e não dos comentários
    (274 dos 406 mutantes não nomeiam sensor): o catálogo grava em `.sdd/cache/mutation-killers.tsv`
    o passo que matou cada mutante, e na rodada seguinte `SDD_MUTANT_FIRST` o roda primeiro. Numa
    amostra fixa de 40 mutantes de `583b3c3`, com 16 jobs: relógio **389 → 171 s**, soma
    **4 828 → 1 959 s**, 0 de 40 vereditos diferentes. A 1ª rodada aprende o mapa e custa como antes (1h27); no
    catálogo inteiro, as duas seguintes levaram 40 min 07 s e 37 min 42 s, 406 de 406. O texto original do plano: cada mutante roda primeiro o sensor que o comentário dele
    nomeia. Se ele morre, a suíte morreria também, então um subconjunto vermelho prova o veredito.
    Se fica verde, cai para a suíte inteira antes de declarar sobrevivente. Nenhum veredito muda.
    O custo é anotar os 392 mutantes; dá para derivar dos logs de uma corrida completa, que mostram
    o primeiro sensor vermelho de cada um.
  - **(b) Parar no primeiro assert vermelho dentro do sensor** sob `SDD_MUTANT`. **FEITO em
    2026-09-25** no **PR #170**, mergeado em `31dfd43`: `sdd health` 37 min 42 s → **18 min 14 s** (nº 2, o mais longo
    primeiro, carimbou 406/406 em `f5f6aba`; o nº 1, ainda na ordem do catálogo, 18 min 56 s).
    [`spec`](2026-09-25-o-sensor-para-no-primeiro-fail-design.md) ·
    [`handoff`](../plans/2026-09-25-o-sensor-para-no-primeiro-fail-handoff.md). Medido na mesma
    amostra: soma do passo assassino 1328,7 → 570,9 / 570,5 / 574,0 s (−57%).
    Amostra de 24 mutantes: o 1º FAIL sai na metade do sensor (1328,7 → 624,4 s, −53%). Vem
    junto: o controle em paralelo com o pool e o mais longo primeiro. Meta: health ≤ 20 min.
- **P3. Probes sensíveis a tempo sob carga.** Os 16 jobs expuseram um probe que distinguia o
  mutante contando sinais. Sinais comuns se fundem quando o processo não é escalonado a tempo, e
  o `mut_COORD_hook_relay_signaled` sobreviveu ao primeiro carimbo do #59. Falta varrer os sensores
  com prazo ou contagem de sinais sob carga artificial (`yes` × 28) e trocar cada discriminador
  frágil por uma leitura direta, como foi feito com o relay. É pré-requisito de qualquer aumento
  futuro de paralelismo, e o mais barato desta lista.
- **P4. Helper de coordenação em Go** (opcional, pede ADR). São 400 linhas isoladas e específicas
  de Linux (pidfd, prctl, flock), que Go faz bem. Troca os ~45 ms dos dois Pythons por ~2 ms.
  Estimativa, não medida: suíte ~20% menor, catálogo de ~1h24 para ~1h05. O custo é trazer uma
  etapa de build e um binário por arquitetura para um kit que hoje instala copiando arquivos
  (princípio 6 do `CLAUDE.md`). Decidir **depois** do P1: se o P1 eliminar o `check`, sobra um
  Python só.
- **P5. Reescrever o runner em Go ou Rust — não recomendado.** Um binário compilado sobe em
  ~1–2 ms (estimativa: 10× a 30× por chamada), mas os 392 mutantes são `sed` sobre bash e teriam de
  ser refeitos. Em linguagem compilada cada mutante exige recompilar: em Go, ~1–2 s; em **Rust**,
  de dezenas de segundos a minutos, o que deixaria o catálogo mais lento que hoje. São ~9 300 linhas
  de runner e ~15 mil de testes, e o valor do kit está nos sensores. Só se reabre se o kit virar
  produto distribuído.

**Como medir o depois.**
- Tempo de parede do `sdd health`, do início ao `kit healthy`, com a máquina livre (load < 5). Um
  `vitest` de outro projeto, com ~20 workers relançados a cada poucos segundos, levou o load a 46
  durante o segundo carimbo do #59.
- Suíte comportamental: soma dos sensores com `SDD_MUTANT=1`, sensor por sensor.
- Custo por chamada: `sdd install` ×60, alternando a versão antiga e a nova.
- ⚠️ O carimbo é o **último** passo de qualquer PR desta frente, depois de todos os revisores e das
  pré-checagens baratas: `--anchors` sempre, e o P3 quando a mudança mexer em carga.

## F2 — Faxina pós-#57

> **Fechada** pela missão `20260926-a-carona-antes-do-congelamento`: as ADRs 0010 e 0011 estão `accepted` (I7), o item "A economia de
> `current_phase()`" saiu pago por `3245bfd` (o outro já tinha saído em `f43788f`), e o yokoten da
> crase foi consertado no I1, com probes e mutantes, em vez de registrado.

Prevista no próprio plano da missão (`docs/handoffs/20260922-o-motivo-da-fase/00-missao.md`, l.161):
- `docs/adr/0010-o-motivo-da-fase.md` ainda diz `Status: proposed`; deve ir para `accepted`.
- Os dois itens do `TODO.md` sobre o memo do `run_check_cmd` ("A economia de
  `current_phase()`/`next_pending_phase()` depende da memoização" e "O memo do `run_check_cmd` marca
  ZERO acertos") foram fechados pela missão e ainda estão lá. Apagar exige provar pelo artefato
  (`git merge-base --is-ancestor`).
- O "yokoten da crase" para `gate_REVIEW` e `gate_DOCS` não foi registrado. Registrar ou não é
  decisão humana, porque mexe na catraca.

Mexe em `TODO.md` e `tests/health-baseline.txt`, então invalida o carimbo. Deve ir de carona no
próximo PR do kit que já precise carimbar.

## F3 — T3 e a janela do juiz

**A T3** era a terceira missão de kit nascida de `ACHADOS-20260917-sales-quote.md` (a T1 foi o #46
e a T2 o #47), e **se desfez em 2026-10-04**: dos três itens que ela juntava, nenhum sobrou para ela.
- **#6 — fase feita à mão não pode ser registrada.** Sai pelos I17–I19 da missão
  `20261004-lote-4-a-catraca-zera`: `sdd note-manual <missão> <fase>`, com o 6º `event` do ledger
  (`manual`, que não pontua). O ACHADOS o chamava de "o mais caro dos nove".
- **#7 — o teto de orçamento não conhece "missão reaberta".** Decidido em 2026-10-03, na seção
  decidida do `TODO.md`: a porta humana para gastar mais é `--budget-override`, com a nota
  `intervention:` que o runner escreve.
- **Observação "T5" — `Test Coverage = A` não implica caso negativo.** Decidida como limite em
  2026-10-04, na seção decidida do `TODO.md`: a nota de revisão é rótulo (anatomia §4). A parte
  barata e real — o executor sabota a linha nova de um `R<n>` — é o I3 da mesma missão.

As três perguntas de desenho que as fontes listavam para o humano — o 6º `event`, a definição de
"reaberta" e a âncora de sabotagem no `gate_REVIEW` — estão respondidas: a primeira no grill do lote
4, as outras duas por decisão escrita. A âncora no `gate_REVIEW` **não** foi construída: o risco de
gate insatisfazível (princípio 1) que a recusava continua de pé.

**A janela do juiz** (estado de 2026-09-23, **histórico**; o de hoje está logo abaixo). Para o
`sdd kaizen` emitir veredito são necessárias **3 missões de alvo com sessão sobre o mesmo
`kit_sha`**, com um único harness na fatia. Toda mudança na `main` do kit encalha a janela. Em
2026-09-23 ela estava zerada: a única missão de alvo sobre `ea39868` foi a do
`lighthouse_project` (46 sessões, ~US$ 196), e a `main` andou depois disso (`147add7`, #57, #48,
#58, #59). Ordem registrada na memória (2026-09-21): planejar a T3 → congelar o kit → 3 missões de
alvo → `sdd kaizen`, este do terminal do humano, numa branch `kaizen/…` (~US$ 5 por veredito, teto
de US$ 15). A memória de 2026-09-20 dizia o contrário ("NÃO planejar a T3 ainda"), e a linha mais
nova prevalece. ⚠️ **Congelar o kit é decisão humana e trava tudo o que está acima.**

**Hoje (2026-09-29).** A ordem que valeu foi outra: o kit congelou no merge da carona (`4fd0f31`),
as 3 missões de alvo rodaram sobre ele, e o `sdd kaizen` deu `melhorou` (PR #175, `3d350ed`). A
janela está **fechada**. Dos 8 achados dela, 5 estão na missão `20260928-os-achados-da-janela` e
3 no `TODO.md`. A missão foi mergeada (PR #176), e a **janela 2** abriu com o kit congelado de
novo (linha F3). A janela 2 fechou sem veredito: um PR só de `TODO.md` partiu a fatia. A
**janela 3** abriu no merge do PR #185 e foi **abandonada por decisão humana em 2026-10-01, sem
veredito**: em vez de congelar de novo sob a regra "nenhum commit, nem de `TODO.md`", o humano
preferiu consertar a causa (missão `20261001-a-janela-nao-se-parte`, ADR 0014). A **janela 4** abre
no primeiro carimbo de alvo após o merge dessa missão; a T3 vem **depois** do veredito dela.

## F4 — Portabilidade para outros repos

Fontes, transcritas aqui porque não eram versionadas:
`~/.claude/plans/analsie-o-estado-atual-rippling-kettle.md` (2026-09-11) e
`~/.claude/plans/2026-09-07-handoff-janela-4-fechada-e-portabilidade.md`.

**A prova já aconteceu, sem ter sido planejada como prova.** O `lighthouse_project` rodou headless
a missão `20260921-amep-backend-0-1-0` sobre o kit `ea39868`: 46 sessões, US$ 195,99, escaladas
`budget-exhausted` ×6, `increment-blocked` ×2 e `hat-crossed` ×1. O PR #1 foi mergeado em `develop`
(`e218c0a`) e o close registrado em 2026-09-22.

**Lacunas ainda abertas, e fora do `TODO.md`** (numeração da fonte):
2. **Sem Jira, ninguém preenche `branch:`, e o pipeline commita onde o humano estiver.**
   `ensure_mission_branch` lê `branch:` do `00-missao.md`; vazio ou placeholder ⇒ não cria branch,
   só o `warn` do `warn_if_on_base_branch`. Com `JIRA_ENABLED=false`, que é o default de repo
   novo, a fase TICKET (que escrevia o campo) é pulada. É o único gap que corrompe a `main` de um
   repo novo por omissão. **Consertada** no I5 da missão `20260926-a-carona-antes-do-congelamento`:
   com o Jira desligado o `gate_PLAN` recusa `branch:` vazio ou placeholder e nomeia o remédio; o
   planner decide o nome com o humano.
3. **O `sdd install` adivinha o `TEST_CMD` pelo primeiro manifesto.** `package.json` ⇒ `npm test`,
   que no `erp_api` é Vitest em watch mode e travaria o `gate_EXEC`. Direção: detectar
   `"test": "vitest"` sem `run` e recusar, ou nomear `test:run`. **Consertada** no I6 da missão
   `20260926-a-carona-antes-do-congelamento` pela raiz: o `run_check_cmd` (gates, `E2E_CMD` e
   preflight) roda o comando com o stdin em `/dev/null`, e o vitest sem TTY não entra em watch.
4. **O tier PLAN-only não tem sensor dedicado.** O `sdd install --force` faz `cp` sobre o symlink
   de `bin/sdd-link-agents` e escreve no kit através do link. O install não é sessão e não passa
   pela guarda de kit. **Registrada no `TODO.md`** (I7 da carona).
5. **A prosa dos chapéus ainda é do `sales_quote`.** `agents/sdd-docs.md` cita `packages/x/...`;
   `sdd-docs.md` e `sdd-reviewer.md` mandam ler `KAIZEN_LOG.md`, `CHANGELOG.md` e `CONTEXT.md`, que
   nenhum gate exige. É ruído de prompt, não falha. **Registrada no `TODO.md`** (I7 da carona).
6. **A dependência do `~/.claude` do humano** (`--setting-sources`, `KIT_THIRD_PARTY_SKILLS`) já é
   limite declarado na linha 2 do ADR 0007.

A etapa 1 (`install` + `preflight`) custa zero; uma missão completa custa US$ 50–150. Os candidatos
originais (`erp_api`, `warehouse_explorer_api`) nunca receberam missão headless. A issue #53
pertence a esta frente.

## F5 — Issues abertas (j0ruge/sdd_agents)

São quatro, todas abertas em 2026-09-22 a partir da missão do `lighthouse_project`:
- **#50** — o `adr_link` aceita `**Spec**:` e recusa `**Spec:**`, e a mensagem aponta o lugar
  errado. Avulsa. **Consertada** no I1 da missão `20260926-a-carona-antes-do-congelamento`: as duas
  grafias e o caminho entre crases passam, o valor que não é caminho diz "not a path", e o yokoten
  leva a mesma leitura à nota do `gate_REVIEW` e ao Status do `gate_DOCS`; fecha com o merge do PR.
- **#51** — o sensor de fronteira de escrita culpa o chapéu por um commit concorrente feito de fora
  da sessão. É da mesma classe do item "a linha `kit-touched` afirma atribuição que ninguém mediu";
  o #48 declara que "coordena entradas do kit, não edição externa". **Consertada** no I3 e no I4 da
  mesma missão (ADR 0012): toda sessão roda com o rótulo `GIT_REFLOG_ACTION=sdd:<passo>:<sid8>`, e um
  commit sem ele fora do `writes:` para a linha como `foreign-commit`, com o commit nomeado. O item
  do `kit-touched` continua aberto no `TODO.md`.
- **#52** — o `sdd approve` sai 0 com "not approved" quando não há TTY. Liga-se ao W3 (F6) e ao
  item do `TODO.md` sobre o `sdd approve`. **Consertada** no I2 da mesma missão: sem nenhum
  caractere no stdin o comando sai 66 e não escreve nada; `n` e Enter seguem rc 0.
- **#53** — o preflight reprova `TEST_CMD` em missão greenfield cujo I1 cria o manifesto. Liga-se
  a F4. **Fechada** pela missão `20260925-o-sensor-le-o-que-a-ancora-diz` (`bc624f9`, `warn` estreito
  quando o manifesto do runner não existe na raiz); a issue fecha com o merge do PR.

## F6 — O worker (W1–W7)

Spec completo neste repo: `docs/superpowers/specs/2026-09-22-o-worker-roadmap-design.md` (trazido
do branch local `docs/worker-roadmap`, commit `8722dc1`, que nunca tinha sido empurrado). É um
`bin/sdd-worker tick --once`, disparado por systemd timer, que leva uma missão **aprovada em disco**
até o PR com os bots tratados.

- **W1 — um checkout, um dono:** entregue pelo PR #48 (`coordination_enter`, `flock`).
- **W2 — identidade do repo no ledger vinda do remote**, não do caminho.
- **W3 — missão entregue como branch empurrada:** `sdd approve` consertado, `TRACKER=jira|github|none`,
  TICKET adotando o cartão existente.
- **W4 — `ENV_UP_CMD`/`ENV_DOWN_CMD`** executados pelo runner.
- **W5 — `tick --dry-run`:** "rodaria X no repo Y porque Z".
- **W6 — tick real,** com timer, lock da máquina e teto diário.
- **W7 — bots do PR:** no máximo uma leva de consertos, depois escala.

**Estacionado por decisão humana (2026-09-22):** só se volta ao roadmap quando os fluxos atuais
rodarem até o fim sem problemas, e na volta começa pelo W2 via `/sdd-plan`. Dentro dele, cada degrau
só executa sozinho depois de o anterior ter sensor, e o worker só executa depois de o W5 mostrar o
que faria.

## F7 — Plano Astra, fases 2–7

Fonte (versionada no vault do Obsidian):
`obsidian/03 Resources/IA e Agentes/sdd-agents-team-harness-raft.md`. A fase 1 foi o PR #48. As
fases 2–4 e 6 ficam **depois** do worker; a 5 é o W5–W6.
- **2 — Identidade e tarefa mínimas:** `config/team.schema.json`, `templates/task.json` e
  `bin/sdd-team`, opt-in.
- **3 — Handoff com destinatário e aceite:** `from_agent`, `to_agent`, `task_id`, `thread_id`.
- **4 — Memória e revisão rastreáveis:** `producer_agent_id` e `reviewer_agent_id`, recusando
  autor igual ao revisor ou revisão obsoleta.
- **5 — Agenda supervisionada por política:** `sdd-team tick --once`, que virou o W5–W6.
- **6 — Canal externo e bastidores:** `bin/sdd-bridge`, envelopes e teste de canário.
- **7 — Otimização comparável:** provavelmente coberta em boa parte pelo PR #43 (`5e3c427`,
  `154f58f`, `477cb9a`); conferir e atualizar a nota.
- Sem número na nota: "hook de skills e retrospectiva pós-tarefa" e a validação pedida ao Fable em
  2026-09-09, sem parecer encontrado.

---

## F8 — O plano mede contra a base, não contra os incrementos anteriores

Nota da execução de `20261004-lote-4-a-catraca-zera` (2026-10-05), guardada aqui por decisão humana
e **fora** do `TODO.md`: o lint do `TODO.md` já reprova o caso caro, então pela régua D15 não é
fail-open. O plano mediu cada incremento contra o commit base (`fe9441d`), e três incrementos
encontraram o disco que os anteriores deixaram:
- **I14:** o plano dizia que a âncora `agents/sdd-publisher.md:41` "continua no alvo (medido)"; o
  `check-todo.sh` reprovou (`off target — nearest ./bin/sdd health is at line 71`), porque o I5
  tinha designado `./bin/sdd health` nesse item e o I14 tirou o símbolo do parágrafo;
- **I11:** o conserto apaga `kit_root`, o símbolo que o I5 designou no item do `kaizen_reminder`, e o
  plano dizia "nenhuma âncora em `bin/sdd`";
- **I9:** a prosa do `config/schema.md` citava "110 herdadas", medidas antes de o I5 mudar a regra
  (o número real passou a 209 e 127).

A seção "Âncoras do TODO.md que o incremento desloca" conta só **deslocamento de linha**. Desde o
símbolo designado (ADR 0015 §2), editar o símbolo derruba a âncora tanto quanto deslocá-la. Direção:
uma frase no § 4 do `sdd-planner` — para cada incremento, `grep` dos símbolos designados do
`TODO.md` contra o diff previsto, e número escrito em prosa que um incremento anterior muda é
re-medido no estado depois dele. Nas três vezes, a execução decidiu na hora e registrou nas notas do
checkpoint daquela missão.

---

## Ordem sugerida

**O que as fontes já decidem:** o worker só volta com os fluxos limpos (F6); as fases 2–4 e 6 do
Astra vêm depois do worker (F7); a T3 vem depois do veredito da janela (F3 — a ordem de
2026-09-21, com a T3 antes do congelamento, foi superada pela carona); o `sdd kaizen` roda do
terminal do humano; e qualquer PR do kit segue abrir → todos os revisores → uma leva de consertos
→ carimbo **uma vez** → merge.

**Recomendação desta sessão, marcada como tal:**
1. ~~Terminar o #59~~ — mergeado em `d0ac22d`, carimbo 392/392.
2. ~~Decidir se o kit congela agora~~ — **feito**: congelou no merge da carona (`4fd0f31`), e a
   janela fechou com `melhorou` (PR #175). O texto de 2026-09-23 segue como histórico:
   **Decidir se o kit congela agora** para a janela do juiz. Tudo o que vem abaixo muda a `main` e
   encalha a janela; se congelar, os itens 3–5 esperam o veredito. Respondido em 2026-09-26: "não
   ainda — PR de carona" (item 3); a pergunta volta ao humano no fechamento da carona.
3. ~~Um PR de kit "de carona", que carimba uma vez só~~ — **feito** pela missão `20260926-a-carona-antes-do-congelamento`: F2, F4
   (lacunas 2 e 3 consertadas, 4 e 5 registradas) e as issues #50, #51 e #52 (a #53 já estava
   fechada). O F1-P3 ficou fora por decisão do grill.
4. ~~A T3 com as três decisões humanas~~ — desfeita em 2026-10-04: os três itens saíram pela missão
   `20261004-lote-4-a-catraca-zera` ou por decisão escrita (§ F3).
5. F1-P1 com ADR; depois decidir o F1-P4.
6. F6 e F7, quando os fluxos rodarem limpos.
