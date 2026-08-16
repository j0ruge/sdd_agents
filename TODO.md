# TODO — `sdd_agents`

Achados que **não cabem na missão atual**, registrados por qualquer agente ou humano
(kaizen princípio 10: oportunidade registrada, nunca desvio de escopo, nunca achado perdido).

Formato:

```md
- [ ] <o quê> — `arquivo:linha` — <por que importa> — descoberto por `<agente>` na missão `<slug>` (YYYY-MM-DD)
```

Achados sobre **repos-alvo** vão para o `TODO.md` daquele repo. Este arquivo é só sobre o kit.

## Aberto

> **Ciclo de vida.** Um item cujo corpo traz **RESOLVIDO por `<hash>`** já está fechado: fica
> aqui, com a caixa ainda desmarcada, só até o PR da missão que o fechou ser mergeado — é dali
> que o PR cita a evidência. **Depois do merge ele é apagado**, não arquivado: a memória durável
> é o `git log -S`, o `KAIZEN_LOG.md` e os handoffs, e cada item já cita o hash que o fecha.
> Ler a caixa sem ler o corpo dá falso positivo; o corpo é a fonte da verdade.
>
> **Uma convenção só.** `- [x]` e `[FEITO em <hash>]` no título **não** existem mais neste
> arquivo — fechado é apagado, e caixa marcada era invisível para a triagem do kaizen, que
> procura `RESOLVIDO por`. Apagar prova por artefato: `git merge-base --is-ancestor <hash> main`
> antes de remover, nunca o rótulo do PR.
>
> **Teto de tamanho.** Um item cabe em ~6 linhas: o quê + `arquivo:linha` + por que importa +
> direção + quem descobriu. A análise longa mora no handoff da missão citada. `tests/check-todo.sh`
> mede a forma e o teto.

### Sensores que faltam

- [ ] **O `sdd preflight` não prova que a sessão headless executa `TEST_CMD`** — `bin/sdd:646` —
  a causa original (falta de `--allowedTools`) foi corrigida em `2083680` e provada pela sessão
  EXEC `357b401`, mas nada impede a regressão silenciosa: o preflight só valida que o `claude -p`
  responde, não que ele **roda comando**. Sem isso, a fase EXEC volta a ser insatisfazível por
  construção sem nenhum sensor gritar. Direção: probe headless real que execute `TEST_CMD`.
  — descoberto por `sdd-executor` na missão `20260814-dry-run-completo` (2026-08-14)

- [ ] **Sensor pulado por `SDD_MUTANT` vira ponto cego sem aviso** — `tests/run-all.sh:41,48` —
  dois sensores são pulados dentro do mutante com a justificativa "não é gate, nunca pontua". É
  aposta que vence sozinha: no I3 o `check-preflight.sh` ganhou asserção de comportamento do
  runner, e a linha que o pulava virou a escondedora da única sensora de `RUN_install_no_guard`.
  O sintoma chega como "mutação não capturada", e o conserto tentador é `KNOWN_GAPS`. Direção:
  reprovar guarda de `SDD_MUTANT` em arquivo que invoca `bin/sdd`.
  — descoberto por `sdd-executor` na missão `20260816-runner-sem-dividas` (2026-08-16)

- [ ] **`check-autonomy.sh` é vermelho intermitente por colisão de nome de log** — `bin/sdd:935` —
  o log de fase é `<FASE>-$(date +%Y%m%d-%H%M%S).json`, resolução de **1 segundo**, e o repo-fixture
  do teste versiona `.sdd/logs/` (o `git add -A` do stub o commita; só `sdd install` põe o caminho
  no `.gitignore`). Duas fases no mesmo segundo — trivial com stub — reescrevem arquivo rastreado e
  a asserção final "clean tree" reprova sem relação com o que se mediu. Reproduzido 2× em ~15 runs.
  Direção: `%N` no nome, ou o fixture ignorar `.sdd/logs/`.
  — descoberto por `sdd-executor` na missão `20260816-runner-sem-dividas` (2026-08-16)

- [ ] **`grep -m<N>` é a mesma corrida do `grep -q`, e nenhum sensor a vê** —
  `tests/check-dry-run.sh:202` — `-m1` também sai no primeiro casamento e mata o escritor com
  SIGPIPE, então sob `pipefail` o pipeline devolve 141 igual. A ocorrência de hoje é inofensiva
  (está no ramo de `fail`, capturada em substituição, não em condição), mas o
  `tests/check-pipefail.sh` do I5 declara a lacuna em vez de fechá-la. Direção: estender a regex
  para o par `-m`/`--max-count` e converter as ocorrências no mesmo commit.
  — descoberto por `sdd-executor` na missão `20260816-runner-sem-dividas` (2026-08-16)

- [ ] **O gate PLAN-AUTO aceita Check que já nasce verde** — `bin/sdd:1901` (critério `d` em
  `templates/missao.md`) — ele cobra "Check executável (comando → esperado)", não "Check que
  reprova o HEAD de hoje". Medido: o Check do I1 desta missão era `grep -c 'gate_DOCS reprova'
  TODO.md` → `0`, mas o título no `TODO.md` traz crases (`` `gate_DOCS` reprova ``), então o
  comando já devolvia `0` **antes** da remoção — verde por construção, exatamente o que a casa
  proíbe em teste. Direção: o planner roda cada Check contra o HEAD e registra o vermelho.
  — descoberto por `sdd-executor` na missão `20260816-runner-sem-dividas` (2026-08-16)

- [ ] **Check de ausência (`grep -c X` → `0`) reprova o conserto que precisa citar o defeito** —
  `docs/handoffs/20260816-runner-sem-dividas/checkpoint.md:20` — o comentário honesto que
  **desmente** a promessa "CHARACTER slice" precisa nomeá-la, e o Check literal deu `1`, não `0`.
  Distinto do item acima: rodar o Check contra o HEAD dá vermelho de verdade e a armadilha fica.
  Direção: Check de ausência mira o código, nunca a prosa. — descoberto por `sdd-executor` na
  missão `20260816-runner-sem-dividas` (2026-08-16)

- [ ] **A asserção "dry-run não toca no disco" promete mais do que entrega** —
  `tests/check-dry-run.sh:116` — ela roda sobre fixture parado em EXEC, cujo gate reprova antes de
  chegar ao `TEST_CMD`. Num fixture que alcance `gate_REVIEW`, o dry-run escreve
  `.sdd/logs/<missão>/gate-*-test-*.log` (reconfirmado no repo real, volta 2 da QA). Não é bug —
  é comportamento aceito e gitignored —, mas o nome garante mais que o teste. Direção: renomear
  para "não toca nos artefatos da missão" ou exercitar também num fixture que chegue ao REVIEW.
  — descoberto por `sdd-qa` na missão `20260814-dry-run-completo` (2026-08-14)

- [ ] **Nenhum gate confere se a missão ainda está na branch que ela declarou** — todos os
  `gate_*` + `templates/missao.md` (campo `branch:`) — medido no piloto SQ-97: o checkout mudou
  entre `QA:plan` e `QA:exec` e **cinco fases commitaram na branch errada** com todos os gates
  verdes (16 commits sobre um PR alheio); quem pegou foi o `sdd-publisher`, no fim da linha, a
  ~US$ 45 de `rebase --onto`. Direção: comparar `git branch --show-current` com o campo no início
  de cada fase; tolerar `<criada pela fase TICKET>` antes do TICKET. Sensor em `check-gates.sh`.
  — descoberto por `sdd-publisher` e por `humano` no piloto SQ-97 (2026-08-14)

- [ ] **A regra da âncora é satisfeita por código inline no título** — `tests/check-todo.sh` (regra
  3) — ela pede crase não-vazia antes do último ` — `, e o título entra nesse trecho: medido, **45
  dos 46 itens passariam com o `file:line` apagado**. Apertar exige teste de forma que os dados
  reais não sustentam (`git worktree` e `KAIZEN_LOG` são âncoras legítimas). Não esconde achado
  fechado — para isso servem a regra 2 e a lista-branca. — descoberto por `revisao-adversarial`
  na 8ª rodada de revisão do sensor (2026-08-16)

- [ ] **A regra da cauda quebra com travessão dentro das crases de atribuição** —
  `tests/check-todo.sh` (`last_sep`) — o corte é no último ` — ` e não conhece code span, então
  `— por \`x\` na missão \`a — b\` (data)` reporta "the last field names no `<agent>`" num item
  bem formado. Direção: mascarar code spans antes de cortar. — descoberto por
  `revisao-adversarial` na 8ª rodada de revisão do sensor (2026-08-16)

- [ ] **O formato de achado vale para os repos-alvo, mas o sensor só guarda o arquivo do kit** —
  `tests/check-todo.sh` vs `CLAUDE.md` (princípio 5) — a regra de formato e o ciclo "fechado é
  apagado" são prescritos para o `TODO.md` de **qualquer** repo, e os agentes escrevem nos dois;
  o sensor mora na suíte do kit e nunca é instalado. Um alvo acumula o mesmo inchaço sem nada
  medindo. Direção: `sdd install` copiar o sensor (ou uma versão dele) e o `starter.conf` sugerir
  incluí-lo no `TEST_CMD`. ⚠️ As regras já são estruturais e language-neutral de propósito, então
  ele roda num alvo `OUTPUT_LANG="en"` sem mudança. — descoberto por `humano` revisando o sensor
  novo (2026-08-16)

- [ ] **Caixa marcada na linha SEGUINTE ao marcador escapa da regra 2** — `tests/check-todo.sh`
  (regra 2) — a regra é por linha e exige marcador e `[x]` juntos; o GFM marca a caixa quando o
  primeiro bloco do item é um parágrafo abrindo com `[x] `, e a linha do marcador pode sumir do
  AST (marcador vazio, ou link-reference definition). Achado fechado renderiza marcado com rc 0
  num arquivo de aparência saudável, contra o que o cabeçalho do sensor afirma (linhas 67-69,
  179). Patch e repros: [handoff](docs/handoffs/20260816-todo-enxuto/r12-caixa-partida.md).
  — descoberto por `revisao-adversarial` na 12ª rodada de revisão do sensor (2026-08-16)

- [ ] **`cmd_health` é o único comando do runner sem sensor** — `bin/sdd` (`cmd_health`,
  `health_proveniencia`, `health_catraca`) — o catálogo cobre os gates e o diário, e o próprio
  health cobra mutação por gate, mas ninguém sabota as checagens dele. Já mordeu: duas nasceram
  com a lógica invertida pelo `pipefail` e foram pegas à mão, não por sensor. Direção: mutações
  `mut_HEALTH_*` (catraca que não reprova achado novo, proveniência que passa com skill ausente).
  — descoberto por `humano` na missão `20260814-i13.2-mutacao-health` (2026-08-14)

- [ ] **A suíte não exercita `--max-phases`, e ele custa uma avaliação de gate a mais** —
  `bin/sdd:1489-1498` vs `:1369` — o gate roda e escreve a linha do ledger **antes** de checar o
  limite, de propósito (a última fase projetada ainda ganha registro), mas o `TEST_CMD` extra na
  última iteração nunca foi medido: a flag não aparece em nenhum dos três sensores de runner.
  Direção: caso com `--max-phases 1` afirmando uma linha de ledger e a mensagem "reached".
  — descoberto por `sdd-reviewer` na missão `20260815-i13.1-autonomy-log` (2026-08-15)

- [ ] **A economia de `current_phase()`/`next_pending_phase()` depende da memoização e ninguém
  conta** — `bin/sdd:475-492` vs `:193-210` — as duas reavaliam o gate de toda fase a cada
  chamada, e isso só é barato porque `run_check_cmd` cacheia por `$cmd`. Quem mexer em **quando**
  `invalidate_checks` roda reintroduz N execuções de `TEST_CMD` por projeção, em silêncio.
  Direção: `TEST_CMD` que incrementa contador em arquivo, afirmando que o número não cresce com
  o número de fases pendentes. — descoberto por `sdd-reviewer` na missão
  `20260815-i13.1-autonomy-log` (2026-08-15)

- [ ] **O fallback `"?"` de `cost_usd` nunca é exercitado** — `bin/sdd:852` vs `:794` — todo stub
  `claude` da suíte escreve log **vazio**, então o campo chega `""` ao `jq`, não a string `"?"`
  que o fallback produz quando o JSON é válido mas não traz custo. O caminho que o fallback
  existe para cobrir segue sem sensor. Direção: stub que emita `{"other_field": 1}` afirmando
  `cost_usd == null` no ledger. — descoberto por `sdd-reviewer` na missão
  `20260815-i13.1-autonomy-log` (2026-08-15)

- [ ] **O corte UTF-8 de `${var:0:200}` não tem asserção** — `bin/sdd:756,777` — a guarda natural
  seria uma mutação restaurando `head -c 200` (corte por byte), mas alcançar um `gate_why` longo
  e multibyte pelo caminho real exige fixture com ID de incremento gigante, e no jq 1.7 o byte
  inválido vira U+FFFD e sobrevive: o risco degrada em vez de quebrar alto. Pode não valer o
  custo do fixture. — descoberto por `sdd-reviewer` na missão `20260815-i13.1-autonomy-log`
  (2026-08-15)

- [ ] **Duas asserções do ledger não têm mutação catalogada** — `tests/check-autonomy.sh` ("the
  two session rows share one session id" e "sdd retry that changed the disk records moved:true")
  — a revisora verificou à mão que as duas discriminam (reverter `LAST_PHASE_SID` derruba a
  primeira; no-op no `moved` do `cmd_retry` derruba a segunda), mas nenhuma sabotagem está no
  catálogo. A regra "gate novo entra com mutação" é sobre gate, não sobre toda asserção nova.
  — descoberto por `/codereview` na missão `20260815-i13.1-autonomy-log` (2026-08-15)

- [ ] **A asserção "the retry carries its own moved" não falha pela propriedade que promete** —
  `tests/check-autonomy.sh:208` — no fixture, `moved` sai `false` com qualquer baseline: o retry
  só é alcançado quando `before == after`, então a asserção nunca observa um `moved:true` genuíno
  pelo caminho real. Ainda pega campo ausente ou `moved` sempre-`true`; só o nome discrimina mais
  do que ela. — descoberto por `/codereview` na missão `20260815-i13.1-autonomy-log` (2026-08-15)

- [ ] **`cmd_kaizen` tem partes sem mutação própria** — `bin/sdd` (`kaizen_reminder`, ramo
  "already judged" idempotente) — as 5 mutações do catálogo cobrem `gate_KAIZEN` cego, Jidoka
  morto, guarda ignorada, bailout de aprovação morto e a régua de rótulos; o lembrete e a
  idempotência têm asserções em `tests/check-kaizen.sh` sem sabotagem que prove que medem algo.
  — descoberto na execução do `i13.3-sdd-kaizen` (2026-08-15)

- [ ] **Três das quatro metades do evento `degraded` não têm mutação** — `bin/sdd:1796` (o
  `select` da série), `:1544` (`pipeline_log_line`) e `:1707` (`is_escalation` do `cmd_autonomy`)
  — o I2 entrou com uma mutação só porque o Check do incremento fixava o score, e sabotar várias
  âncoras num mutante derrubaria a detecção de "âncora apodreceu". As três foram sabotadas à mão
  e as três mataram a suíte, mas evidência de sessão não roda no CI. Vale um mutante para cada
  quando houver folga de régua. — descoberto por `sdd-executor` na missão
  `20260815-ledger-sem-ponto-cego` (2026-08-16)

### Contrato e configuração

- [ ] **`config/schema.md` promete cinco comportamentos que o runner não tem** —
  `config/schema.md:24-25,32-34` vs `bin/sdd:81-82` — `LINT_CMD`, `BUILD_CMD`, `DEV_UP_CMD`,
  `DEV_READY_CMD` e `DEV_READY_TIMEOUT` estão documentados como se o gate de REVIEW e a fase QA
  os usassem; nenhum é lido em lugar nenhum. Um `LINT_CMD` preenchido dá ao usuário um sensor que
  ele acha que tem — pior que não ter. Direção: implementar, ou marcar as chaves como reservadas.
  — descoberto por `sdd-reviewer` na missão `20260814-dry-run-completo` (2026-08-14)

- [ ] **`E2E_DIR` tem default no runner e é lida só pelo agente** — `bin/sdd:81` vs
  `agents/sdd-qa.md:44` — `: "${E2E_DIR:=e2e}"` é a única ocorrência no runner: nenhum gate ou
  prompt a consulta, e quem usa o valor é a prosa do `sdd-qa`. Mudar a chave **não muda onde as
  specs são commitadas**, e a coincidência entre default e convenção esconde isso. Direção: o
  runner passa `E2E_DIR` ao prompt da fase QA, ou a chave sai do schema. Congelada na catraca
  `tests/health-baseline.txt`. — descoberto por `sdd health` na missão
  `20260814-i13.2-mutacao-health` (2026-08-14)

- [ ] **A fase TICKET recebe agente E slash ao mesmo tempo** — `bin/sdd:491` + `:501` — o
  comentário do `phase_agent()` fixa o invariante ("dois system prompts disputando a sessão é
  ruído"), `QA:plan`/`QA:exec` respeitam e TICKET não: nasce com `--agent sdd-publisher` **e** o
  slash `/ticket open` prependado. É redundante — a skill `ticket` não tem
  `disable-model-invocation` e o `sdd-publisher` já invoca o slash sozinho. Não morde com
  `JIRA_ENABLED=false`. Direção: escolher um dos dois. — descoberto por `sdd-reviewer` na missão
  `20260814-dry-run-completo` (2026-08-14)

- [ ] **O kit não tem `CHANGELOG.md`, e a fase DOCS cobra um** — `agents/sdd-docs.md` (tabela "O
  que atualizar") — o registro durável aqui é `KAIZEN_LOG.md` + handoffs + corpo do PR, e nenhum
  é changelog por versão; há `SDD_VERSION="0.1.0"` em `bin/sdd:5` sem nada que o acompanhe. Toda
  missão cai num `n/a` honesto e repetido. Decidir: criar o arquivo com política amarrada ao
  `SDD_VERSION`, ou tirar a linha do agente. Vale para os repos-alvo também. — descoberto por
  `sdd-docs` na missão `20260814-dry-run-completo` (2026-08-14)

- [ ] **`BUDGET_PER_PHASE_USD` é global, mas o custo por fase não é** — `config/schema.md` +
  `run_phase` — teto único de US$ 15 calibrado por palpite. Medido: SQ-97 TICKET 2,56 · EXEC 7,37
  · QA:plan 6,90 · **QA:exec 14,84** · QA:close 9,08; missão do kit **REVIEW 14,76**. Fase a 1%
  do teto morre por dinheiro no meio do trabalho e o runner lê como "não avançou". Direção: teto
  por fase com o global de default, e gate que reprove com motivo explícito nesse caso.
  — descoberto por `humano` no piloto SQ-97 (2026-08-14)

- [ ] **O contrato de artefato ainda é PT-BR em cinco pontos** — chamadas de `frontmatter` em
  `bin/sdd`, `templates/missao.md`, `agents/*.md`, `tests/` — sobraram 3 chaves (`aprovacao`,
  `versao`, `titulo` — 45 refs) e 2 nomes de artefato (`00-missao.md`, `01-plano.md` — 72 refs).
  É o único português **obrigatório** para um repo-alvo anglófono, e `OUTPUT_LANG` não resolve
  contrato. Não há missão em voo que a renomeação quebre (PR #105 mergeado): o custo é tamanho,
  não risco. Direção: `approval`/`version`/`title` + `00-mission.md`/`01-plan.md`, com o runner
  aceitando os dois nomes por uma janela. — descoberto por `humano` na missão
  `20260815-i13.5-kit-em-ingles` (2026-08-15)

- [ ] **`templates/` é single-language** — `templates/*.md` — são conteúdo em `OUTPUT_LANG` mas
  moram no kit em cópia única PT-BR, e o `sdd install` nem os copia (o `sdd-planner` lê direto de
  `$SDD_HOME`). Um alvo com `OUTPUT_LANG="en"` recebe prompt certo e template em português. Não
  morde hoje porque todo alvo é PT-BR. Direção: `templates/<lang>/` com fallback, ou estrutura
  inglesa com prosa-guia que o agente reescreve — a segunda mexe no contrato que
  `check-templates.sh` mede, então vem depois da entrada acima. — descoberto por `humano` na
  missão `20260815-i13.5-kit-em-ingles` (2026-08-15)

### Runner — defeitos e dívidas

- [ ] **O runner se auto-degrada em laço, mesmo registrando uma vez só** — `bin/sdd:1546` —
  depois do `force_phase="PR"`, se a fase PR mexer no disco e não satisfizer o gate, o laço volta
  a REVIEW com o orçamento ainda estourado e o ramo `draft` dispara de novo. O `F1` fechou a
  metade de **registro** (uma linha por `run_id`); o que sobra é o giro REVIEW→PR→REVIEW até o
  `no-progress` do PR encerrar — medido: ramo entrado 3×, `warn` 3×, ledger 1×. — descoberto por
  `sdd-executor`, estreitado por `sdd-qa` na missão `20260815-ledger-sem-ponto-cego` (2026-08-16)

- [ ] **Missão que só produziu escalada conta para `guard.sufficient`** — `bin/sdd:1846` —
  `missions` conta `map(.mission) | unique` sobre **todas** as linhas admitidas, escaladas
  incluídas: três missões que escalaram sem gastar sessão devolvem `sufficient: true` com
  `sessions: 0`, e o juiz é liberado a julgar uma versão da qual não observou sessão nenhuma.
  Reproduzido em fixture na revisão r1; não é regressão (o `blocked` já tinha a propriedade).
  Direção: contar só missões com sessão comparável, ou expor `sessions` junto de `sufficient`.
  — descoberto por `sdd-reviewer` na missão `20260815-ledger-sem-ponto-cego` (2026-08-16)

- [ ] **A sessão de fase é um ponto cego enquanto roda** — `bin/sdd:897` — `--output-format json`
  emite um blob único no fim, então `.sdd/logs/<missão>/<FASE>-*.json` fica com **0 bytes**
  durante os ~10 min da sessão e não há como acompanhar o agente de dentro do kit (o transcript
  ao vivo existe fora dele, em `~/.claude/projects/<projeto>/<session-id>.jsonl`). Direção:
  `--output-format stream-json` com `tee` para um `.stream.jsonl` ao lado, preservando o resumo
  final que `run_phase` parseia. — descoberto por revisão `humano` acompanhando a missão
  `20260815-ledger-sem-ponto-cego` (2026-08-16)

### Saída humana e cosmética

- [ ] **`sdd autonomy` imprime `US$ 2` em vez de `US$ 2.00`** — `bin/sdd:1617` — o `jq` imprime
  número, não string formatada: um total de `2.0` vira `2` e derruba o alinhamento de uma tabela
  feita para ser lida rápido; um leitor apressado lê "sem casas calculadas". Direção: `printf` no
  lugar da interpolação. — descoberto por `sdd-reviewer` na missão `20260815-i13.1-autonomy-log`
  (2026-08-15)

- [ ] **`cmd_autonomy` usa a mesma mensagem de `die` para dois defeitos** — `bin/sdd:1583` e
  `:1626` — as duas escrevem `"malformed row … the ledger is not readable"`: uma cobre JSON
  inválido, a outra JSON válido de shape errada. As correções são distintas (editar a linha vs
  entender por que o produtor escreveu não-objeto) e quem lê não sabe qual aconteceu. Direção:
  duas mensagens, ou o detalhe do `jq` anexado. — descoberto por `sdd-reviewer` na missão
  `20260815-i13.1-autonomy-log` (2026-08-15)

- [ ] **`sdd autonomy` imprime duas linhas em branco em vez de uma** — `bin/sdd:1649-1652` —
  quando não há escaladas e há linha não reconhecida, sobra espaçamento entre o bloco "no
  comparable sessions" e a linha de exclusão. Cosmético, confirmado por reprodução: nenhuma
  contagem some. — descoberto por `/codereview` na missão `20260815-i13.1-autonomy-log`
  (2026-08-15)

- [ ] **`cmd_autonomy` repete o bloco "no data" literalmente** — `bin/sdd:1603-1605` e
  `:1620-1622` — as mesmas três linhas (`warn` + `dim` + `return 1`), palavra por palavra. As
  duas guardas são necessárias e checam coisas diferentes; a dívida é de manutenção: quem
  reescrever uma passa a ter duas vozes para a mesma recusa, e é essa mensagem que separa "ledger
  vazio" de "ledger corrompido". Direção: um helper local chamado dos dois pontos. — descoberto
  por `/codereview` na missão `20260815-i13.1-autonomy-log` (2026-08-15)

- [ ] **A tabela do `sdd autonomy` ordena versões lexicograficamente** — `bin/sdd:1725` faz
  `group_by(.kit_sha)` (o jq ordena pela chave) enquanto `kaizen_series` deriva
  `latest`/`previous` por primeira aparição no arquivo (`:1818`). Quem ler a última linha da
  tabela como "a versão mais recente" pode ler a errada. É ordem de saída humana, não contagem —
  o I3 alinhou o eixo, não a ordem. Família do `latest_matching`, já fechado. — descoberto por
  `sdd-executor` na missão `20260815-ledger-sem-ponto-cego` (2026-08-16)

### Comentário e registro

- [ ] **O que arma a corrida do Jidoka é a POSIÇÃO da linha `blocked`, não o tamanho do
  checkpoint** — `tests/check-gates.sh:229-232` — a grandeza real é quantos bytes sobram para o
  `printf` escrever **depois** do casamento do `grep`: com a linha no fim de um checkpoint de
  1,1 MB o runner pré-conserto parava certo; no começo, queimou 2 sessões. Hoje quem segura é o
  mutante `RUN_jidoka_pipefail`, então não há defeito vivo — é comentário impreciso sobre uma
  invariante não escrita. Direção: dizer "linhas DEPOIS da `blocked`". — descoberto por `sdd-qa`
  na missão `20260815-ledger-sem-ponto-cego` (2026-08-16)

- [ ] **`after2` passou a ser amostrado antes do gate do retry, sem registro da decisão** —
  `bin/sdd:1533-1537` — antes o `after` do retry era lido depois de avaliar o gate; agora é
  antes. Benigno e talvez mais honesto (`state_fingerprint` lê HEAD, listagem e md5 do
  checkpoint, e nenhum gate toca nos três), mas é mudança de comportamento em caminho raro que
  ninguém decidiu nem documentou. — descoberto por `/codereview` na missão
  `20260815-i13.1-autonomy-log` (2026-08-15)

- [ ] **Contexto não é gargalo hoje, e isso deveria estar escrito** — `docs/pipeline.md`,
  `config/schema.md` — medidas as 6 sessões do SQ-97: picos de 184k a **289k tokens**, **zero
  compactações** (`claude-opus-5`). O anti-estouro funciona por construção — sessão por fase
  mantém a mais pesada em 289k em vez de somar ~1,4M —, mas nunca foi medido nem documentado,
  então é fé e não evidência. Registrar os números e que `--autocompact` é alavanca disponível e
  hoje não usada. — descoberto por `humano` no piloto SQ-97 (2026-08-14)

- [ ] **O espelho `.claude/agents/sdd-kaizen.md` ficou atrás do fonte** —
  `.claude/agents/sdd-kaizen.md` contra `agents/sdd-kaizen.md:68` — a fase DOCS ensinou ao juiz o
  vocabulário `degraded`/`review-to-draft`, mas a sessão headless rodou com **escrita bloqueada
  sob `.claude/`** e uma fase KAIZEN **neste repo** lê o espelho, não o fonte. ⚠️ Vale para toda
  fase DOCS futura que toque em agente. — descoberto por `sdd-docs` na missão
  `20260815-ledger-sem-ponto-cego` (2026-08-16)
  **RESOLVIDO por `3030262`**: espelho re-copiado numa sessão sem o bloqueio, os 7 agentes
  conferidos par a par. — `humano` (2026-08-16)

### Idioma

- [ ] **Dois arquivos ficam fora do sensor de idioma** — `tests/check-lang.sh` (função
  `surface()`) — as exclusões são corretas e documentadas (em `check-templates.sh` as regexes
  PT-BR **são** o contrato dos templates; em `check-lang.sh` o dicionário precisa conter o que
  detecta), mas nesses dois arquivos prosa portuguesa passa despercebida. Direção: mover o
  contrato dos templates para `tests/template-contract.txt` (dados), deixando a lógica inglesa;
  sobra o `check-lang.sh`, irredutível e por isso com `selftest()`. — descoberto por
  `sdd health`/`check-lang` na missão `20260815-i13.5-kit-em-ingles` (2026-08-15)

### Custo e escala

- [ ] **A suíte segue acima do alvo "<30 s" da D7, mesmo depois do paralelismo** —
  `tests/run-all.sh` — a saída "subir o default" foi tomada e executada (pool + `min(núcleos, 8)`,
  ver KAIZEN_LOG de 2026-08-16): mediana 54,13 s → **32,87 s** na mesma sessão, score 30/30
  intacto. Restam as duas saídas de régua, ambas do humano: subir o alvo da D7 (o "≤15 s" do
  I13.1 já é história) ou aceitar os ~3 s de estouro, que crescem com o catálogo. — medido por
  `sdd-executor` e `humano` nas missões `20260815-ledger-sem-ponto-cego` e no kaizen do
  paralelismo (2026-08-16)

### Adiados por YAGNI

- [ ] **Espelho global de vereditos legível por máquina (JSONL em `~/.sdd/`)** — D3 do
  `CONTEXT.md` adiou até o I13.4 pedir: hoje o veredito vive só no handoff da missão nascida, e
  "vereditos ao longo do tempo" exige varrer `docs/handoffs/*/05-verdict.md`. Criar junto com a
  graduação, nunca antes. — registrado na execução do `i13.3-sdd-kaizen` (2026-08-15)

- [ ] **O `sdd-planner` ainda não foi exercitado numa missão real** — os planos até aqui foram
  escritos à mão ou pelo `sdd-kaizen`. A primeira missão planejada por ele deve conferir se o
  gate PLAN-AUTO é preenchido com evidência de verdade. — descoberto por `humano` na
  implementação (2026-08-14)

- [ ] **Multi-missão concorrente exigiria `git worktree` por missão** — hoje é 1 missão por
  branch por vez (YAGNI declarado no plano). Reavaliar se aparecer demanda real. — descoberto por
  `humano` no planejamento (2026-08-14)

- [ ] **Destilar handoffs/`KAIZEN_LOG` para o vault Obsidian continua manual** — avaliar um
  `sdd digest` que gere o rascunho. — descoberto por `humano` no planejamento (2026-08-14)
