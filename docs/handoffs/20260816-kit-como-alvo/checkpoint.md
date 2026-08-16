---
missao: 20260816-kit-como-alvo
atualizado: 2026-08-16 19:05
---

# Checkpoint — quando o kit é o próprio alvo, quatro instrumentos param de afirmar o que nunca mediram

> **Este arquivo é lido por máquina.** O runner faz parse da tabela abaixo para decidir a
> próxima fase. Não mude as colunas, não mude os tokens de status, não quebre linhas dentro de
> uma célula. Detalhe narrativo vai no `01-plano.md`, não aqui.
>
> Atualizar o checkpoint é o **último ato** de cada incremento — depois do commit, nunca antes.
> Status válidos: `pending` · `doing` · `done` · `blocked`.

| ID | Incremento | Check (comando → esperado) | Status | Commit |
|---|---|---|---|---|
| I1 | entry point com guarda + sensor diferencial | `bash tests/check-entrypoint.sh >/dev/null 2>&1; echo $?` → `0` | done | bb373b5 |
| I2 | os três leitores do ledger filtram por repo | `o=$(bash tests/check-kaizen.sh 2>&1); grep -c '^  ok    a row from another repo never enters the series' <<< "$o"` → `1` | done | d99a7fc |
| I3 | preflight compara conteúdo do agente, não presença | `o=$(bash tests/check-preflight.sh 2>&1); grep -c '^  ok    a drifted agent copy fails the preflight' <<< "$o"` → `1` | done | ab64d2e |
| I4 | aviso de branch base alcança run e kaizen | `o=$(bash tests/check-gates.sh 2>&1); grep -c '^  ok    the base branch warning reaches sdd run' <<< "$o"` → `1` | done | daa8687 |
| F1 | os Checks de I2/I3/I4 param de ler asserção vermelha como verde (âncora `^  ok    `), e o template + o `sdd-planner` aprendem a regra | `l=$(mktemp); bash tests/run-all.sh >"$l" 2>&1; rc=$?; a=$(grep -c '^  ok    no checkpoint Check reads a red assertion as green' "$l"); printf '%s%s\n' "$rc" "$a"` → `01` | done | a981fd9 |

## Notas de execução

> Uma linha por evento relevante: bloqueio, decisão tomada, desvio do plano com justificativa.
> É o que a próxima sessão lê para não repetir um erro que já custou caro.

- 2026-08-16 00:00 · `plano` · Os 4 Checks foram rodados contra o HEAD `df18c88` na sessão que
  escreveu este plano e deram **`127`, `0`, `0`, `0`** — todos vermelhos pelo motivo certo
  (sensor ausente / asserção ausente), nenhum verde por construção. Se algum já estiver verde
  quando você começar, **pare e descubra por quê** antes de implementar.
- 2026-08-16 15:08 · `humano` · **Os Checks de I2/I3/I4 não usam pipe, e isso é obrigatório — não
  "simplifique" de volta.** Dois motivos independentes, os dois medidos hoje. (1) `checkpoint_rows`
  (`bin/sdd:174`) faz `awk -F'|'` cru e não conhece `\|`, o escape de pipe do GFM: com pipe na
  célula as três linhas davam `NF=8` contra `NF=7` da limpa, o `gate_EXEC` reprovava com "invalid
  status" e o `sdd status` imprimia `pending` na coluna Commit. Está no `TODO.md` (`2897a94`).
  (2) A primeira reescrita tentada — process substitution `grep -c '…' <(cmd)` — foi descartada,
  mas o motivo **não vale para você**: no shell interativo daquela sessão o `grep` era uma função
  do snapshot apontando para ugrep 7.5.0, que não imprime o `0` com `<(...)`. Dentro de `bash -c`,
  como o sensor roda, o `grep` é GNU 3.11 e imprime. Herestring ficou porque não depende de qual
  `grep` atende e é a forma que o `CLAUDE.md` já prescreve (SIGPIPE sob `pipefail`). ⚠️ O runner
  usa `grep` 40× e a suíte em 11 arquivos: se algum dia um Check parecer mentir, confira **em que
  shell** você o rodou antes de acusar o sensor.
  Re-medido em herestring contra o HEAD: `127`, `0`, `0`, `0` — os mesmos
  quatro números que o plano declara, então a evidência do critério (d) segue válida.
- 2026-08-16 00:00 · `plano` · O `bin/sdd` tem **2365** linhas neste HEAD. Âncoras do `TODO.md`
  citam offsets da época em que tinha 2324. `grep` pelo texto antes de editar por número.
- 2026-08-16 00:00 · `plano` · `run_mutant` devolve **rc 90** quando a sabotagem não altera o
  arquivo (`tests/check-mutation.sh:492`). Esse rc é "âncora apodreceu", não "mutação fraca".
- 2026-08-16 00:00 · `plano` · I1 tem Jidoka declarado: se a repro de reexecução não for
  determinística com ≥128 KB, **não commite repro flaky** — degrade para a asserção de forma,
  registre a degradação aqui e no handoff, e mantenha a mutação.
- 2026-08-16 · `I1` · **O Jidoka do I1 não precisou ser acionado, e o motivo interessa para I2-I4.**
  A repro do fall-through é determinística em *todos* os tamanhos medidos — 538 B, 4,5 KB, 20 KB,
  129 KB, 196 KB — sempre 2 entradas na versão sem guarda contra 1 na guardada (bash 5.2.21). O
  "≥128 KB" do plano era uma suposição sobre o buffer de leitura, e ela estava errada por excesso,
  não por falta: **nenhuma degradação foi declarada**. O enchimento ficou em ~128 KB mesmo assim,
  porque o tamanho em que um bash qualquer para de segurar o script inteiro é detalhe de
  implementação; o header do sensor registra os cinco números.
- 2026-08-16 · `I1` · **A âncora do `mut_RUN_entrypoint_unguarded` usa `|` como delimitador do
  `sed`, não o `@` que todos os outros 40 mutantes usam** — o texto ancorado contém `"$@"`, então
  um delimitador `@` fecha a expressão no meio do entry point e o `sed` morre com "unterminated
  `s' command". O sintoma seria **rc 90** ("a âncora apodreceu"), que é a leitura errada.
- 2026-08-16 · `I1` · Dois pisos anti-vacuidade que contam arquivos subiram junto com o sensor
  novo: `LINT_FLOOR` 12 → 13 (`tests/run-all.sh`) e o piso de superfície do `check-pipefail.sh`
  11 → 12, este último com a árvore-fixture do probe "a full clean surface passes" indo de 10 para
  11 arquivos. Nenhum dos dois reprovaria se ficasse parado — os dois passariam **descrevendo uma
  superfície menor do que a que leem**, que é a forma exata que esta missão está caçando. Se I2-I4
  acrescentarem arquivo em `tests/`, mexa nos dois de novo.
- 2026-08-16 · `I1` · **As âncoras de I2/I3/I4 no `01-plano.md` continuam válidas.** O I1 mexeu
  numa linha só do `bin/sdd`, a última, e acrescentou 7 linhas de comentário ali mesmo (2365 →
  2372). Tudo que I2-I4 citam — `:1283`, `:1294`, `:1817`, `:1937`, `:2039` — está *antes* desse
  ponto e não se deslocou. Ainda assim: `grep` pelo texto antes de editar por número.
- 2026-08-16 · `I1` · A passada de sabotagem adversarial do sensor novo matou 8 das 10 regras do
  parser. Das duas sobreviventes, "neutralizar o corpo do `probe()`" era buraco de **uma** edição
  (fazia as dez asserções passarem de uma vez) e foi fechado por uma testemunha que o próprio
  `--check` escreve. ⚠️ A primeira tentativa de fechá-lo — rodar `--check` direto num arquivo ruim
  — era **redundante** com os probes 1-10 e, por ser redundante, nenhuma sabotagem a deixava
  vermelha: foi removida em vez de ganhar probe, pela regra do `CLAUDE.md`. Os dois sobreviventes
  finais estão nomeados no header do sensor.

- 2026-08-16 · `I2` · **O risco "linhas antigas sem o campo `repo`" foi medido, não estimado:**
  `jq -c 'select(has("repo")|not)' ~/.sdd/autonomy-log.jsonl | wc -l` → `0` em 26 linhas, todas do
  kit. Mesmo assim a decisão foi tomada **por regra e não pelo dado**: linha que não sabe dizer de
  onde veio — não é objeto, ou é objeto sem `repo` — **nunca** é excluída pelo filtro. Ela segue
  chegando ao balde que a nomeia (`unrecognized`, ou a morte alta nomeando o arquivo) no repo em
  que você estiver. Esconder corrupção é a única coisa que um filtro não pode fazer, e isso é o
  que preserva os fixtures `stray` e `shape` do `check-autonomy.sh` intactos.
- 2026-08-16 · `I2` · **Contrato mudado, de propósito: `sdd kaizen --series` não é mais "any cwd".**
  O cabeçalho do `check-kaizen.sh` afirmava que a série tinha de funcionar de QUALQUER diretório;
  com a leitura por repo, ler de fora de um repositório git devolve a série vazia (com `warn`) —
  a direção segura, porque série vazia é `sufficient:false` e só sustenta `indeterminado`. O
  `sdd help` e o `docs/pipeline.md` aprenderam no mesmo commit; há asserção para o caso.
- 2026-08-16 · `I2` · **Todo fixture de ledger agora precisa nomear um repo REAL.** Os dois
  sensores ganharam um `localize()` que reescreve `"repo":"/p1"` para o caminho absoluto do repo
  sandbox, e as leituras da série saíram de `$OUTSIDE/anywhere` para dentro dele. ⚠️ Linha de
  fixture nova escrita com `cat >` em vez de `localize >` fica **invisível** para o leitor e o
  sensor passa medindo um ledger vazio. O caminho vem de `git rev-parse --show-toplevel`, nunca da
  string que o teste montou: TMPDIR pode ser symlink e o runner resolve exatamente assim.
- 2026-08-16 · `I2` · `excluded` tem **quatro** chaves agora (`other_repo` entrou) e o literal do
  ramo de ledger vazio (`bin/sdd:2006`) as carrega todas. A comparação de conjunto de chaves que
  só existia para `guard` passou a existir para `excluded` também — era metade do contrato entre os
  dois produtores da mesma shape, e estava sem sensor.
- 2026-08-16 · `I2` · **A sabotagem adversarial provou que as duas asserções não são redundantes:**
  desligar o filtro só em `kaizen_series` mata `check-kaizen.sh` e deixa `check-autonomy.sh` verde;
  desligar só em `cmd_autonomy` faz o inverso. É por isso que o mutante do catálogo sabota a
  **definição** e não uma chamada — só assim ele mede que os três leitores passam mesmo por ela.
- 2026-08-16 · `I2` · ⚠️ **O Check desta linha (e os de I3/I4) devolve `1` mesmo com a asserção
  VERMELHA:** `fail()` imprime o mesmo texto que `pass()`, e o Check captura `2>&1`. Quem prova
  "rodou E passou" é o `TEST_CMD` verde, não o Check. Não mudei o comando (o runner faz parse desta
  tabela e a métrica do `00-missao.md` o cita); está no `TODO.md` com a direção — grepar
  `'^  ok    <texto>'`.
- 2026-08-16 · `I2` · **Âncoras de I3/I4 re-derivadas depois deste incremento** (`bin/sdd` foi de
  2372 para 2449 linhas): o `[ -f ... ]` do preflight está em **`:1314`** (era `:1283`), o
  `ok "$n kit agent(s) checked"` em **`:1319`** e o aviso de branch base em **`:1325`** (era
  `:1294`). `grep` pelo texto antes de editar por número, sempre.
- 2026-08-16 · `I2` · Nenhum arquivo novo em `tests/` — os dois pisos que contam arquivos
  (`LINT_FLOOR` no `run-all.sh`, piso de superfície do `check-pipefail.sh`) ficam como estão.
  Catálogo de mutação: 41 → **42**, 0 known gap. `sdd health` verde.

- 2026-08-16 · `I3` · **A asserção que o plano previa era VÁCUA, e por isso não foi escrita.** O
  `01-plano.md` pedia "exija o texto certo **e a ausência** de `kit agent(s) checked`". Medido: essa
  linha só sai com `fails -eq 0` (`bin/sdd:1332`) e o fixture é offline — o probe do `claude` e o
  `gh auth status` já reprovam —, então ela **não aparece em run nenhum**, com o defeito inteiro no
  lugar. A ausência dela passaria verde sobre o `[ -f ]`. Trocada por um **diferencial de contagem**:
  a mesma árvore lida duas vezes, um byte de diferença, `N check(s) failed` exatamente +1. Desvio
  declarado do plano, na direção mais forte. O ramo de sucesso segue sem sensor — está no `TODO.md`.
- 2026-08-16 · `I3` · **`sandbox()` do `check-mutation.sh` passa a copiar `agents/`** — sem isso o
  fixture do `check-preflight.sh` instala zero agentes, não há cópia para divergir, e as asserções
  passariam **vazias em todos os 43 mutantes** enquanto o control seguia verde. ⚠️ O comentário do
  `tests/run-all.sh:141` afirmava o oposto ("o sandbox não copiar `agents/` não custa nada"): era
  verdade e deixou de ser no mesmo commit. Se um sensor novo ler um caminho do kit, confira o
  `sandbox()` antes de confiar no verde do mutante.
- 2026-08-16 · `I3` · Sabotagem adversarial: **16 degradações**, e cada uma das **sete** asserções de
  comportamento morre sozinha em pelo menos uma — mensagem sem a palavra `stale`; `warn` que não
  conta; os dois ramos trocando de texto; `else warn "stale"` nas cópias que casam. As duas
  restantes são **sanidade declarada como tal** no próprio arquivo (mesma rubrica de "preflight got
  as far as the tool checks", que também não é exclusiva), não asserções sem probe.
- 2026-08-16 · `I3` · Catálogo 42 → **43**, 100%, 0 known gap; `sdd health` verde. Nenhum arquivo
  novo em `tests/`, então `LINT_FLOOR` e o piso de superfície do `check-pipefail.sh` ficam como
  estão. `bin/sdd` foi de 2449 para **2462** linhas: o aviso de branch base do I4 está agora em
  **`:1338`** (era `:1325`). `grep` pelo texto antes de editar por número.

- 2026-08-16 · `I4` · **Duas sabotagens ficaram verdes e viraram sensor — as duas eram o call site
  que ninguém re-testa.** (1) Derrubar a chamada em `cmd_preflight` não matava nada: era o lugar
  ONDE O AVISO JÁ MORAVA, e por isso o único que a extração deixa sem cobertura nova. Fechado com
  o par diferencial em `check-preflight.sh`. (2) Degradar `warn` → `dim` passava verde nos três,
  porque todos capturavam `2>&1` e a mensagem continuava lá — sem severidade e fora da stderr. A
  asserção do `check-gates.sh` passou a ler a **stderr sozinha**, presença e severidade numa
  asserção só. ⚠️ Sensor que captura `2>&1` não distingue `warn` de `info`: se o que você mede é
  um aviso, separe os fluxos.
- 2026-08-16 · `I4` · **As três asserções não são redundantes, e a sabotagem é a prova:** derrubar
  a chamada em `cmd_run` deixa `check-kaizen.sh` e `check-preflight.sh` verdes; em `cmd_kaizen`, o
  inverso; em `cmd_preflight`, só o terceiro morre. É por isso que `mut_RUN_base_branch_warn_dead`
  esvazia a **definição** — só assim ele mede que as três portas passam mesmo por ela.
- 2026-08-16 · `I4` · A comparação byte-a-byte das duas leituras (`sdd run --dry-run` na base e
  fora dela) precisou de `no_uuid()`: o `run_phase` imprime um `session: <uuid>` novo por fase
  projetada. A substituição é ancorada na **forma** do UUID e não em `session:.*` — alargá-la
  apagaria também uma fase trocando de agente ou de modelo, que é metade do que a comparação mede.
- 2026-08-16 · `I4` · Nenhum arquivo novo em `tests/` — `LINT_FLOOR` e o piso de superfície do
  `check-pipefail.sh` ficam como estão. Catálogo 43 → **44**, 100%, 0 known gap; `sdd health`
  verde. Nenhum doc afirmava que o aviso era exclusivo do preflight (`grep -rn 'base branch'
  docs/ README.md agents/`), então não houve contrato a atualizar no mesmo commit.

- 2026-08-16 · `QA` · **`F1` nasce de `BUG-qa-01`: o Check desta tabela é o quinto instrumento da
  família que a missão foi caçar.** O EXEC já suspeitava (nota do I2) e registrou a direção no
  `TODO.md`; a fase QA **mediu**. Numa cópia sandbox, com o filtro do I2 sabotado
  (`ledger_row_is_local` devolvendo `true`), o Check de I2 devolveu **`1` com a asserção
  imprimindo `FAIL`** — o mesmo `1` que devolve com ela imprimindo `ok`. Causa: `pass()` escreve
  `  ok    <texto>` na **stdout** e `fail()` escreve `  FAIL  <texto>` na **stderr** com o mesmo
  `<texto>`, e o Check captura `2>&1` e grepa o texto solto. A `Métrica` do `00-missao.md` diz
  "a asserção aparece **e passa**"; o comando só sabe dizer "aparece". Conserto: ancorar em
  `^  ok    `. Medido: `grep -c 'exemplo'` → `2` contra `grep -c '^  ok    exemplo'` → `1`.
- 2026-08-16 · `QA` · **O Check de `F1` usa a própria forma que ele exige** — ancorado em
  `^  ok    ` — e por isso não pode mentir sobre si mesmo. Ele lê **duas** coisas: o `rc` do
  `tests/run-all.sh` (regressão verde **e** o re-walk das quatro jornadas, porque os sensores das
  quatro moram na suíte) e a asserção nova tendo rodado E passado. Hoje devolve `00`; com o
  conserto, `01`. ⚠️ `grep -c 'suite green'` **não** serve de testemunha do verde: a string aparece
  **3×** na saída da suíte (medido). Quem responde é o `rc`.
- 2026-08-16 · `QA` · ⚠️ **Sensor novo commitado vermelho trancaria a própria fase QA.** `gate_QA`
  (`bin/sdd`) roda `TEST_CMD` como âncora final, então o par sensor-vermelho + conserto tem de
  nascer no **mesmo** incremento, em TDD, pela mão do executor — foi por isso que a QA não escreveu
  o sensor por conta própria. O laço funciona porque `current_phase` devolve a primeira fase com
  gate insatisfeito e `EXEC` vem antes de `QA`: a linha `F1` `pending` reprova `gate_EXEC` e a bola
  volta para o `sdd-executor` sozinha.
- 2026-08-16 · `QA` · **O parser aceita `F1`:** `checkpoint_rows` (`bin/sdd`) descarta só `ID`,
  linha de traços e célula vazia — o prefixo do ID não é lido em lugar nenhum. E a célula do Check
  de `F1` **não tem pipe** (conferido), pela regra de 2026-08-16 15:08 acima.

- 2026-08-16 · `F1` · **O sensor novo (`tests/check-checkpoint.sh`) mede a regra em TODO checkpoint
  do repo, não só no desta missão** — 23 linhas em 5 arquivos, e o `templates/checkpoint.md` entra
  na varredura como qualquer outro. A regra é condicional e é isso que a torna barata: só se
  aplica à célula que faz `2>&1` **E** grepa. Hoje são 4 células (I2, I3, I4 e o próprio F1);
  nenhuma missão anterior tinha uma.
- 2026-08-16 · `F1` · ⚠️ **A pré-condição da regra é também o seu ponto cego, e por isso tem piso
  próprio.** Quebre o `2>&1` ou o `grep` da pré-condição e o arquivo passa verde sobre uma regra
  que nunca rodou — vacuidade, a forma exata que esta missão caça. `RULED_FLOOR=4` é o que impede;
  ele é o mais importante dos quatro pisos, e tem probe.
- 2026-08-16 · `F1` · **O achado mais caro da sabotagem adversarial: fixture derivado da regra
  afrouxa junto com ela.** Abrir `OK_ANCHOR` de `^  ok    ` para `ok` deixava o selftest **verde**,
  porque os probes constroem os seus fixtures a partir de `OK_ANCHOR` — regra e evidência se moviam
  em bloco. A saída não foi um probe a mais e sim uma **testemunha independente**: `calibrate()`
  deriva o prefixo das linhas `pass()` dos sensores reais e compara com o âncora. Se você escrever
  um sensor cujo fixture nasce do valor sob teste, ele tem esse buraco — procure a segunda fonte.
- 2026-08-16 · `F1` · **Dois sobreviventes eram o mesmo buraco: `--check` cobria a regra, `--scan`
  não.** Todas as violações de célula eram exercitadas só pelo modo `--check`, então `if true; then
  pass` em `scan()` — a fiação entre os contadores e o veredito — sobrevivia a tudo. Fechado com
  dois probes de `--scan` sobre a árvore completa. Regra medida num modo não é regra medida no modo
  que o `run-all.sh` chama.
- 2026-08-16 · `F1` · Sabotagem adversarial: **44 degradações em 4 rodadas**, 4 sobreviventes, os 4
  viraram probe. O único que resta é o par "esvaziar os corpos dos probes **e** baixar
  `PROBE_FLOOR`", e as três quase-falhas foram **medidas** em par com uma sabotagem real em vez de
  presumidas: neutralizar só o `rc` de `probe()` morre pela metade da mensagem (91), só a mensagem
  morre pelo `rc` (90), só o `fail_rc` morre pela contra-checagem de `FAILS` (92).
- 2026-08-16 · `F1` · **Arquivo novo em `tests/` ⇒ os dois pisos que contam arquivo subiram**, como
  a nota do I1 avisava: `LINT_FLOOR` 13 → 14 (`tests/run-all.sh`) e o piso de superfície do
  `check-pipefail.sh` 12 → 13, este com a árvore-fixture do probe "a full clean surface passes"
  indo de 11 para 12. Catálogo de mutação segue em **44** (o sensor mede markdown, e sabotagem do
  `bin/sdd` não o mataria — pendurá-lo no catálogo seria ponto pelo motivo errado). `sdd health`
  verde.
- 2026-08-16 · `F1` · ⚠️ **`.claude/agents/` não é editável por esta sessão** (permissão negada em
  `cp` e no editor). Quem sincronizou a cópia do `sdd-planner` foi o próprio runner:
  `bash bin/sdd install --force`. Depois do I3 a cópia velha reprova o `sdd preflight`, então isso
  **tem** de ser feito no mesmo commit — e o caminho que funciona é o comando do kit, não o `cp`.
- 2026-08-16 · `F1` · `CLAUDE.md` aprendeu no mesmo commit (regra do contrato em três lugares): a
  lista de sensores foi de "os dez" para **os doze** — ela também não tinha aprendido o
  `check-entrypoint.sh` do I1 —, e a rubrica "sensor que a mutação não alcança carrega auto-teste"
  passou de três para **quatro** sensores.

## Incrementos de fix (QA)

> Escritos pelo `sdd-qa` quando um bug sanável é reprovado. Entram na mesma tabela acima com ID
> `F<n>`, e o Check obrigatoriamente inclui **regression test passa** + **re-walk da jornada
> impactada verde**. Bug que exige julgamento humano NÃO vira fix — vai para
> "Decisions for a Human" no handoff de QA.
