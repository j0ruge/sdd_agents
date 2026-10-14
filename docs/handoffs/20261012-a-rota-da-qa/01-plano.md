---
missao: 20261012-a-rota-da-qa
data: 2026-10-12
---

# Plano — o lote 7: a rota da QA e o aceite que lê o plano

> **Teste de autocontenção:** uma sessão nova, sem nenhuma memória da conversa que gerou este
> plano, lendo apenas `00-missao.md` + `01-plano.md` + `checkpoint.md`, consegue executar?
> Se a resposta for "só se souber X", **X vai escrito aqui**.
>
> ⚠️ Missão do **kit**: executa-se de forma **interativa num worktree ligado** (ADR 0016 §2), nunca
> por `sdd run` a partir do checkout principal (`/home/joruge/repos/sdd_agents`), para onde o `sdd`
> do PATH resolve e que todo `sdd run` de alvo executa. Dentro do worktree, `health`, `preflight` e
> `install` rodam por `./bin/sdd`.

## Contexto verificado (não re-descobrir)

Lido nesta sessão, sobre `4f16a6d` (a `main` do kit em 2026-10-12) mais o commit do veredito
`e2238cf` da branch `kaizen/20261012`. Os números de linha são da base: **cada incremento mexe em
`bin/sdd`, então releia o número antes de editar** (o símbolo entre parênteses não muda).

**Como trabalhar aqui (o que custou caro antes)**

- **Onde.** Depois do merge do PR de docs: `git -C /home/joruge/repos/sdd_agents fetch`, depois
  `git -C /home/joruge/repos/sdd_agents worktree add ../sdd_agents-lote-7 -b fix/lote-7-a-rota-da-qa
  origin/main`, e então `sdd approve 20261012-a-rota-da-qa` **de dentro** de
  `/home/joruge/repos/sdd_agents-lote-7`. Todo o trabalho acontece lá. Nunca `git pull` no checkout
  principal: a guarda de kit compara o `HEAD` dele.
- **A suíte** é `tests/run-all.sh` (o `TEST_CMD`, ~10 min; no lote 6, 582 s e 1927 linhas `ok`).
  Cada incremento roda só os sensores que toca, e a suíte inteira roda antes do PR.
- **Antes de cada commit em `bin/` ou `tests/`:** `bash -n bin/sdd` e `shellcheck -S warning` nos
  arquivos tocados (o lint só roda na suíte inteira, e o SC1010 do lote 3 custou um commit).
- **Mexeu num `agents/*.md`?** Rode `./bin/sdd install --force` no worktree (sincroniza o espelho
  `.claude/agents/`), nunca `cp` nem Edit no espelho.
- **Mutante novo:** a função `mut_<slug>()` em `tests/check-mutation.sh` (molde em `:780-800`) **e**
  o slug, sem `mut_`, na lista `CATALOG=(` (`:6026`). O sensor reprova mutante definido e não
  listado (`:7000-7020`). Prove com `tests/check-mutation.sh --only <slug> <sensor>.sh`, com o
  **nome nu** do sensor (`check-dry-run.sh`, nunca `tests/check-dry-run.sh`: o caminho dá rc 2,
  medido no teste de autocontenção). É dica e não veredito, e rode `tests/check-mutation.sh --anchors` depois de toda edição em
  `bin/sdd` (segundos; recusa mutante cuja âncora apodreceu).
- **`.claude/rules/anatomia-do-agente.md`** é editado em I1, I3, I4, I8, I9 e I13 (regra do
  `CLAUDE.md`: mudança no runner atualiza a seção da anatomia no mesmo commit). `.claude/` é caminho
  sensível: o harness pode pedir permissão; nunca contorne por Bash. A frase nova entra no fim do
  parágrafo "Onde mora hoje" da seção, depois da última frase que começa por "Desde".
- **Superfície do kit é inglês** (`bin/`, `agents/`, `commands/`, `tests/`, `docs/adr/`, `docs/*.md`):
  rode `bash tests/check-lang.sh` em **todo** incremento que toca superfície. Ele reprova letra acentuada e as stopwords de `tests/check-lang.sh:128`
  (`outra`, `para`, `quando`, `sem`…), **inclusive dentro de crases**. Foi por isso que os
  marcadores da D8 viraram `(recommended)`/`(other: …)`. O artefato de missão, o `TODO.md`,
  `CONTEXT.md`, `KAIZEN_LOG.md`, `templates/` e `docs/superpowers/` são pt-BR.
- **Sensor que lê prosa** (`agents/*.md`, `commands/*.md`) é o `tests/check-hat.sh`. O catálogo de
  mutação nunca muta markdown, então a prova de cada probe nova é uma passada de sabotagem manual:
  apague a frase e veja o probe ficar vermelho, restaure e veja verde. O registro vai numa linha do
  `checkpoint-notas.md`, por exemplo `- 2026-10-13 10:42 · abc1234 · I5: sabotagem do probe do
  test.fail() — sem a frase 'after the preconditions' vermelho, restaurada verde`. Função de probe nova entra na **lista** de chamadas
  do fim do arquivo (`census_probes` … `release_probes`, `tests/check-hat.sh:627-637`), senão não roda.
- **Família do subshell:** `qa_substep` é lido por `$(phase_step QA)` (`bin/sdd:8955-8957`, com o
  comentário "qa_substep sets no global"). O helper novo do I3 também é lido por `$( )`: **nenhum
  dos dois atribui global**. Captura que pode sair não-zero leva `|| true` (`set -euo pipefail`).
  `grep -q` sobre variável é herestring (`<<< "$x"`), nunca `printf | grep -q`.
- **Commit:** `<tipo>(<escopo>): <o quê>` em pt-BR, com o porquê no corpo e as linhas de atribuição
  da sessão. Um incremento, um ou poucos commits. O **último ato** de cada incremento é a linha do
  `checkpoint.md` (`done` + hash curto nu, sem crase; o `atualizado:` do frontmatter com a hora de
  `date '+%Y-%m-%d %H:%M'`) e uma nota anexada com `>>` ao `checkpoint-notas.md`, no formato de
  `templates/checkpoint-notas.md`: `- <YYYY-MM-DD HH:MM> · <hash ou —> · <o que aconteceu>`. Os dois
  vão num commit `docs(missao): I<n> feito` logo depois do commit do incremento, para a sessão
  seguinte começar de árvore limpa (a forma que o teste de autocontenção escolheu, e que o lote 6 usou).

**A rota da QA (`bin/sdd`)**

- `qa_substep` — `bin/sdd:2672-2683`: sem interface (`E2E_CMD` e `APP_URL` vazios) → `close`
  (`:2678`); sem charter → `plan` (`:2679`); sem relatório **da missão** fechado → `exec` (`:2681`);
  senão `close` (`:2682`). Hoje não lê `00-missao.md` nem checkpoint.
- `report_closed` — `:2666`; `mission_qa_report` — `:1067` (cabeçalho `:1011-1066`: com range vazio,
  isto é, HEAD na base ou já mergeada, devolve `latest_matching`, a resposta de antes);
  `mission_base_refs` — `:929`.
- `frontmatter <arquivo> <chave>` — `:337`: arquivo ausente ou chave ausente → vazio; tira espaços
  e uma aspa nas pontas; **não** tira comentário (`skipped # x` volta inteiro).
- `MISSION_DIR` — definido em `:324` (resolução da missão) e `:11061` (kaizen). `qa_substep` só
  roda com missão resolvida.
- `checkpoint_rows` — `:569`: imprime `ID`, `Incremento`, `Check`, `Status` e `Commit` separados
  por `$CK_SEP`, com a crase tirada da coluna Commit. O `gate_EXEC` lê assim:
  `while IFS="$CK_SEP" read -r id _ _ status commit` (`:1389`). O `gate_EXEC` já exige, de toda
  linha `done`, um commit de 7 a 64 hex que **existe e é ancestral de HEAD** (`:1401-1418`). Como
  ele vem antes do `gate_QA` na derivação, um `F<n>` `done` que o helper do I3 lê sempre resolve.
- `gate_QA` — `:1598`. `skipped` passa em `:1606`, antes de tudo, com a mensagem
  `qa: skipped (diff has no user-visible change)`; `blocked` arma `GATE_HANDOFF_BLOCKED`
  (`:1612-1615`); enum positivo (`:1621-1624`: o que não é `done` reprova); divisão de caminho em
  `:1633` (sem interface: lê o `gate:` do handoff); Âncora 1 (`:1645`); Âncora 3 (registro sem bug
  `agent` aberto, `:1676` em diante); e2e em `:1800` (`run_check_cmd "$E2E_CMD" "gate-qa-e2e"`).
- Os comentários que mentem: `:2650-2655` (cabeçalho da sub-etapa) e `:2913-2921` (`phase_slash`)
  dizem que as skills `qa-*` "carry `disable-model-invocation`". Hoje as duas declaram `false`
  (`grep -m1 disable-model-invocation ~/.claude/skills/qa-*/SKILL.md`).
- `phase_task` — `:2931`, texto do `QA:exec` em `:2935`. `phase_slash` — `:2923`
  (`QA:exec` → `/qa-execution $QA_DOCS_PATH`).
- `phase_budget` — `:5563-5566`: QA tem `QA_MAX_ITER * 3` sessões ("3 sub-steps per round"). Um
  ciclo F com a rota nova custa 2 sessões (`exec` + `close`), dentro da conta.
- `no_work_check` — `:9182`: forma (a), o mesmo passo com o mesmo motivo em duas voltas, para a
  linha como `no-work` antes da sessão. É o freio de um reteste ou de um `close` que não move nada.
- **A condição de descendência, prototipada num repo descartável (git 2.43.0):**
  `git rev-list -1 --no-merges --ancestry-path "<F>..HEAD" -- <caminho>` vazio ⇔ nenhum commit
  **depois** do F tocou `<caminho>`. Sem `--no-merges`, o merge de uma base que trouxe o relatório
  de outra missão contava como reteste (medido: o merge apareceu); com ele, não. Um commit do
  reteste depois do F aparece.
- **O caminho que o reteste lê é o relatório DA MISSÃO, nunca o diretório** (achado do CodeRabbit no
  PR #247, conferido): `--no-merges` tira o merge, mas um commit comum da branch, depois do F, que
  edita o relatório de outra missão (ou o copia da base) tocaria `$QA_DOCS_PATH/reports/` e
  responderia `close` sem reteste nenhum, falha aberta. O `mission_qa_report` (`:1067`) já é a
  definição de posse (ADR 0013, 0015 §3, 0016 §1): editar relatório da base nunca dá posse, e o
  `qa_substep` já tem o arquivo em `report` (`:2680`). O preço declarado: um reteste que escreve um
  arquivo novo cujo nome ordena **antes** do atual deixa a sub-etapa em `exec`, e o `no_work_check`
  para a 2ª volta igual (falha fechada e alta). O `qa-execution` continua o relatório existente ao
  retomar e só abre arquivo novo numa corrida nova, datado (`references/status-and-reporting.md:69`
  da skill).

**O `gate_DOCS` (`bin/sdd:2131-2248`)**

- Exige o `45-docs.md` commitado (`:2136-2143`), a palavra `drift`, e a coluna Status do checklist
  sem pendente (`:2183-2190`, contagem no motivo). Depois vem o bloco `⛔` (`:2211`) e os dois
  `return 0`. **A âncora do K8 entra entre `:2190` e `:2211`**, para valer nos dois retornos.
- O `KAIZEN_LOG.md` mora na raiz, sem chave de config (`bin/sdd:3205` só o cita). Ele está no
  `writes:` do `sdd-docs` (`agents/sdd-docs.md:10`), então a âncora tem dono.
- **A leitura do bloco (D16), medida em 2026-10-13 no git 2.43.0:**
  `git diff-tree -p --no-color --no-ext-diff -U1000000 <b> HEAD -- KAIZEN_LOG.md` devolve o arquivo
  de HEAD inteiro num hunk só (`1` linha `@@ `; 20 linhas de corpo para um arquivo de 20), cada linha
  com o prefixo ` `, `+` ou `-`. Arquivo inalterado → saída vazia (0 bytes); arquivo novo na branch →
  `@@ -0,0 +1,N @@` e tudo `+`. Com `-c diff.external=/bin/false -c color.ui=always -c
  color.diff=always`, ou com `GIT_EXTERNAL_DIFF=/bin/false`, a saída é a mesma: 1 hunk, 0 bytes ESC.
  Sobre o `KAIZEN_LOG.md` desta branch (3259 linhas, a missão citada 1 vez, na entrada do veredito)
  o `awk` do I9 leva 15–40 ms por merge-base.
- As entradas do `KAIZEN_LOG.md` abrem por `## YYYY-MM-DD — <título>` no kit (53 `## `) e no
  `sales_quote` (71 `## `, um deles a seção `## Onde cada coisa mora`, que não é entrada). Nenhum dos
  dois tem `## ` dentro de cerca de código hoje. A entrada do L4 escrita à mão (`acb708b9` do
  `sales_quote`) **não** cita o id da missão; por isso o `sdd-docs.md` passa a mandar citar.
- **O leitor da chave do K8 (D23)** é o `frontmatter <arquivo> <chave>` (`bin/sdd:337`), o mesmo
  do `qa: skipped` do I1, e a presença é o `frontmatter_has` (`bin/sdd:371`), que pergunta pelo
  próprio `frontmatter` com o sentinela `FRONTMATTER_ABSENT`. Ele só lê o bloco entre a primeira
  linha, se ela for exatamente `---`, e o `---` seguinte; a primeira ocorrência da chave vence;
  apara espaço e tab nas pontas do valor e uma aspa de cada lado; não apara `\r` nem comentário.
  **Medido em 2026-10-14** com as duas funções extraídas do `bin/sdd`, sobre treze grafias:
  dispensam `kaizen_log: skipped`, `skipped` com espaço ou tab no fim e `"skipped"`; cobram
  `Skipped`, a chave vazia (presente, valor vazio), o placeholder do template (presente),
  `skipped # nada a medir`, `skipped` + `\r`, uma `kaizen_log: no` antes de uma `kaizen_log:
  skipped`, a chave ausente e a chave no corpo (as duas ausentes para o `frontmatter_has`), e um
  arquivo CRLF inteiro (a primeira linha é `---\r`, então nenhuma chave é lida).
- Os ids de missão (o nome do diretório; o runner não valida o formato, `resolve_mission`,
  `bin/sdd:307`) são todos `^[0-9]{8}-[a-z0-9-]+$`: 64 de 64 diretórios com `00-missao.md` em cinco
  repos (o kit 28, `sales_quote` 31, `lighthouse_project` 3, `ansible-jrc` 1,
  `digital_service_report_frontend` 1), medido em 2026-10-13. Nenhum par em que um id contém outro
  hoje. Os dois diretórios pontuados do `sales_quote` (`20260916-release-notes-0.8.0`, `…-0.8.1`)
  não são missões (não têm `00-missao.md`).
- ⚠️ `mawk` 1.3.4: `substr(s, 0, 1)` devolve o **primeiro** caractere de `s`, não `""`; `substr`
  além do fim devolve `""`; `index(s, "")` devolve 1 (medido nesta sessão). É a armadilha da
  fronteira do id no I9.
- **A linha K8 real e a chave** (censo de 2026-10-13, refeito para o `✗` e a chave em 2026-10-14,
  os 64 `00-missao.md` dos cinco repos): 59 têm uma linha K8, todas com `✅` (56) ou `⏳` (3,
  do `sales_quote`, com a nota "Fase DOCS"); **nenhuma diz `✗`**, e **nenhuma tem `kaizen_log`** no
  frontmatter. Logo, a D23 não muda a resposta de nenhuma missão real: todas prometiam pela D19 e
  prometem pela D23. Nenhum arquivo de `tests/` cita `K8` ou `kaizen_log`
  (`grep -rn 'K8\|kaizen_log' tests/` vazio).
- **O parser de referência da 16ª rodada:** `markdown-it-py` 3.0.0 (`/usr/lib/python3/dist-packages`),
  pelo `python3 -I`, com `MarkdownIt("commonmark").enable("table")` (o preset `gfm-like` exige o
  `linkify-it`, que não está instalado). Não é o `cmark-gfm` do GitHub; é o que mediu os 13 mundos
  da asserção 19 do I9.
- O `00-missao.md` do fixture do `check-gates.sh` (`:144-151`) é só frontmatter mais `# Mission`,
  sem seção nenhuma, e diz `branch: main`, que o molde de branch de missão (`:1318-1326`) não muda.
  O `assert_phase` (`:47-51`) resolve a fase por `sdd phase "$MISSION"`, então passa pelo
  `resolve_mission`.
- ⚠️ **Locale e o `=~` do bash 5.2.21:** sob `LC_ALL=pt_BR.UTF-8` (o locale desta máquina; nem o
  runner nem a suíte fixam `LC_ALL`), `[[ 20260101-fixtureé =~ ^[0-9]{8}-[a-z0-9-]+$ ]]` **casa**: a
  faixa `[a-z]` alcança o `é`. Sob `C.UTF-8`, não. A classe **enumerada**
  (`[abcdefghijklmnopqrstuvwxyz0123456789-]`) responde igual nos dois. Locales instalados que armam
  esse veneno: `pt_BR.utf8` e `pt_PT.utf8` (`locale -a`). O glob `*[!a-z0-9-]*` não tem o problema
  porque `globasciiranges` está `on`, mas o `=~` não lê essa opção.
- O `resolve_mission` (`bin/sdd:307-325`) toma o argumento **literal** quando ele nomeia um
  diretório: `sdd run "/<missão>"` dá `MISSION=/<missão>` e `MISSION_DIR=<base>//<missão>`. O probe
  "a leading slash in the mission argument does not make the approved plan look missing"
  (`tests/check-gates.sh:4658-4671`) depende disso e é o único mundo que mantém vivo o mutante
  `RUN_branch_double_slash`: canonicalizar o `MISSION` faria esse mutante sobreviver. O
  `resolve_mission` tem 11 chamadores. O `cmd_kaizen` (`:11060`) não passa por ele e cunha
  `$(date +%Y%m%d)-kaizen`, que cabe na gramática. Os ids que os testes passam à CLI
  (`20260101-fixture`, `20260102-approve`, … 19 ao todo) cabem; os nomes fora dela (`m1`, `h1`,
  `x`) são strings de ledger ou diretórios lidos pelo `autonomy --by-mission`, que nunca chama o
  `resolve_mission`.

**O `boot_prompt` (`bin/sdd:3078`)**

- `turn_rule` — `:3145-3152`, uma string só entre aspas duplas, com crases escapadas (`\``), lida
  por todas as fases. O `tests/check-dry-run.sh:422-452` conta, fase a fase, as frases dela
  (`turn_phases`, `turn_hits`, `bg_hits`, `own_hits`) e compara aos pares (`"5 5"`, `"5 5 5"`).

**Os sensores**

- `tests/check-dry-run.sh` — ~5 s, 72 linhas `ok`, rc 0. O fixture da missão é commitado em `:119-134`
  (`00-missao.md` com `aprovacao: auto`, `branch: main`). O bloco "QA sub-step derived from the
  artifacts" (`:479-538`) põe `E2E_CMD="true"` por `sed` (`:487`), cria charter e relatório
  (`:508-511`), e mostra em `:522-538` como cortar uma branch de missão e voltar
  (`git reset -q HEAD~1`, `rm -rf docs/qa/...`). As asserções de árvore limpa adiante dependem de
  restaurar tudo byte a byte.
- `tests/check-gates.sh` — **~95 s**, 439 linhas `ok`, rc 0. Fixture em `main` = `DEFAULT_BRANCH`,
  ou seja, range da missão vazio (cabeçalho do bloco `:1307-1318`). `assert_phase`, `assert_why` e
  `assert_why_absent` estão em `:45-82` e leem `sdd phase` e `sdd why`. ⚠️ O `assert_phase` imprime
  `  ok    <nome> → <fase>`, com a fase no fim; o `assert_why` imprime o nome exato. Por isso os
  Checks do I4 e do I9 contam por **prefixo** (`freshness: `, `kaizen-log: `). Pontos de inserção, com a
  QA passando: `:1969` (com interface, "the fixture is back where the next block starts" → REVIEW)
  e `:2016` (sem interface, "back to 'done' with evidence"). O bloco do `skipped` fica em
  `:2043-2047`; o da DOCS começa em `:2727`; o molde de branch de missão é o de `:1318-1326`.
- `tests/check-hat.sh` — ~2 s, 74 `ok`. Probes de prosa: `hat_promise_probes` (`:305`, lê
  `agents/sdd-ticket.md` e `sdd-docs.md`), `command_approval_probes` (`:321`, lê a seção
  `## When the artifacts exist` do `commands/sdd-plan.md` e **exige hoje** as frases
  `first show the human what they are approving`, `AskUserQuestion`, a linha `- **YES** … sdd approve
  <mission>`, a linha `- **NO**` e `Only the human's answer to that question approves`),
  `command_relay_probes` (`:349`, seção `## Relaying the grill to the human`: exige
  `by the option's text, never by its position` e `Nothing else resumes the planner while a question
  is pending`), e `planner_agent_probes` (`:392`, lê só a § 4 do planner). **Mantenha essas frases**
  ou mude o probe no mesmo commit.
- `tests/check-checkpoint.sh` lê frases literais da § 4 do `agents/sdd-planner.md` (`:442-460`): a
  regra da âncora, a do pipe e o `--red`. Nenhum incremento desta missão mexe na § 4.
- `tests/check-templates.sh` — <1 s; a lista de chaves do frontmatter da missão é
  `for k in missao titulo data versao branch aprovacao ddd adr` (`:336`), e cada uma imprime
  `  ok    missao.md: frontmatter key '<k>'`.
- `tests/check-autonomy.sh:1715-1775` — um fixture com stub de `claude` em que a sessão de QA cria
  `F1`, a de EXEC o fecha **e fecha o bug**, e a corrida segue `QA EXEC REVIEW DOCS` "sem a QA
  abrir uma segunda sessão" (asserção em `:1775`). **O frescor do I4 muda isso:** com um
  `F1` `done` depois do `30-handoff-qa.md`, o `gate_QA` reprova e a QA abre de novo. O I4 ajusta
  esse fixture (ver o I4).

**Os contratos de prosa**

- `agents/sdd-qa.md`: § 0 (`:20-40`, os dois contratos), § 2 (`:53-63`, o `skipped`), § 3 (`:65-79`,
  o spec que falha com o bug), § 4 (`:81-103`, o `F<n>` e o laço, "repeats until no agent-closable
  bug is left `open`" em `:98`), § 6 (`:180-198`, o handoff, "Commit everything"), e a regra
  inegociável que tira o `Status:` do chapéu (`:232-236`).
- `agents/sdd-planner.md`: § 1 (`:35-54`, o grill e o relay), § 2 (`:56-66`, gemba), § 6
  (`:149-205`, "All ✅ → `aprovacao: auto`" em `:162`), regra inegociável em `:251`.
- `commands/sdd-plan.md`: `## Relaying the grill to the human` (`:78-105`, "Long work" em `:99`),
  `## When the artifacts exist` (`:107-148`, passo 3 em `:111-123`, aviso final em `:143-146`).
- `agents/sdd-docs.md` § 3 (`:42-55`): a linha `KAIZEN_LOG.md` diz "the mission measures a
  before/after" / "there is no number to show".
- `docs/pipeline.md` § "QA — three sub-steps, one phase" (`:243-360`; a tabela em `:248-252`, o
  `skipped` em `:354`).
- `templates/todo.pt-BR.md:32-36` e `templates/todo.md:32-36` (§ Ciclo de vida / Lifecycle). O
  esqueleto do item termina na linha `Fonte: … — descoberto por <agente> … (YYYY-MM-DD)`
  (`:17`), que o `check-todo.sh` exige como **último campo**. **Medido nesta sessão** sobre um item do
  `TODO.md`: `RESOLVED by` no fim dessa linha → `the last field names no <agent>`; numa linha
  própria → `last line carries no (YYYY-MM-DD)` (e num item de 8 linhas, `9 content lines, cap is 8`);
  no fim da última linha do **corpo** → `ok` (é a forma do lote 6, `54e2f18`); dentro da linha
  `Fonte:`, antes do `— descoberto por` → `ok`. O "anexado à `Fonte:` passa" do L2 do alvo vale só
  para item antigo sem descoberto-por.
- **A marca da D22 (15ª rodada do PR #247, medida em 2026-10-14 no `mawk` 1.3.4).** Na forma de
  antes, a varredura literal da seção de decisões deste `00-missao.md` dava 17 `(recommended)` e 3
  `(other:` para 21 decisões e 23 respostas: a prosa que explica os tokens contava junto, e das 21
  primeiras marcas 14 eram o token exato, 3 levavam nota dentro dos parênteses e 4 se partiam em
  duas linhas. O leitor do I6 conta só a linha inteira dentro da seção. Num mundo descartável não
  contam: a prosa com `(recommended)` no meio, a marca `(recommended; nota)`, a `- answer:` sem
  recuo, a `(other: )x`, os dois formatos de placeholder e uma linha `- answer:` de outra seção;
  contam a `   - answer: (other: x)`, a recuada com 4 espaços e a `(other: …)` com parênteses
  dentro. A mesma resposta sob o `mawk` em `C` e em `pt_BR.UTF-8` e sob o `busybox awk` (não há
  `gawk` nesta máquina). O template de hoje e o template com o placeholder novo do I7 dão
  `0 (recommended) of 0`. O número desta missão sai do comando, nunca deste plano; o da 15ª rodada
  está na nota dela, no `checkpoint-notas.md`.

## Arquitetura da mudança

```
qa_substep (com interface)                                   gate_QA (os dois caminhos)
  ├─ sem interface                       → close              ├─ skipped → passa ("declares status: skipped")   (I1)
  ├─ 00-missao.md: qa: skipped (literal) → close   (I1)       ├─ blocked → para a linha
  ├─ sem charter                         → plan               ├─ ≠ done  → recusa
  ├─ sem relatório da missão fechado     → exec               ├─ F<n> done e handoff não reescrito depois → recusa  (I4)
  ├─ F<n> done e relatório da missão não reescrito depois → exec (I3)  └─ … âncoras de hoje
  └─ senão                               → close

qa_fix_ahead_of <caminho>  — UMA definição, DOIS leitores (I3 no qa_substep, I4 no gate_QA)
gate_DOCS: frontmatter sem kaizen_log: skipped ⇒ entrada nova no KAIZEN_LOG.md        (I9)
gate_PLAN: branch: = base e kaizen_log: presente sem skipped → recusa (e gate_DOCS de reforço) (I12)
resolve_mission: id fora de ^[0-9]{8}-[a-z0-9-]+$ → recusa, em todo comando      (I11)
boot_prompt/turn_rule: "todo carimbo sai de date"                                 (I8)
/sdd-plan + sdd-planner: o aceite renderiza, refaz --check/--red, conta as recomendadas (I6, I7)
```

- **O `skipped` não muda gate nenhum.** O `gate_QA` já aceita `skipped` com interface. O que faltava
  era a rota até a sessão que escreve o artefato (a metade do princípio 1 que pergunta quem pode
  escrever o que o gate exige). A chave é **literal e positiva**: só `qa: skipped` exato desvia, e
  qualquer outra grafia é a rota de hoje (frouxidão pularia QA de verdade, falha aberta).
- **O reteste e o frescor são a mesma pergunta**: "existe `F<n>` `done` depois do qual o caminho X
  não foi reescrito?", e reescrito é: os bytes de X em `HEAD` são novos (nenhuma versão de X até o
  conserto) **e** o primeiro commit depois do conserto que os carrega não é um merge (o I3 diz por
  quê, medido). Só `F<n>` conta: um `R<n>` do REVIEW não reabre a QA (D21, limite declarado e
  achado no `TODO.md`). X = o relatório da missão (o arquivo que o `mission_qa_report` escolhe, o mesmo
  que a Âncora 1 lê) decide a sub-etapa, e X = `$HANDOFF_DIR/$MISSION/30-handoff-qa.md` decide o gate. Uma definição, como o `report_closed`
  (o cabeçalho dele, `:2656-2660`, conta o que custou ter a âncora duplicada). O ciclo F vira
  `close` → EXEC → `exec` (reteste, move o `Status:`) → `close` (reescreve o handoff) → passa.
  Sem interface: `close` → EXEC → `close` (caminha de novo e reescreve). ⚠️ Ali o `qa_substep`
  devolve `close` antes de ler relatório (`:2678`), **de propósito**: o caminhante é o próprio
  `sdd-qa`, e o reteste é a caminhada do `close`. A pergunta do I3 só existe com interface; quem faz
  o `close` rodar de novo depois do F, nos dois caminhos, é o frescor do I4 (o CodeRabbit leu a
  ausência como lacuna no PR #247; não é).
- **A âncora do K8 lê dois artefatos**: a chave `kaizen_log` do frontmatter do plano (D23) e o diff
  do `KAIZEN_LOG.md` de cada
  merge-base até HEAD, em que tem de haver um bloco `## ` cujo título e uma linha citando o id da
  missão são novos (D16). A entrada é a unidade (o título, D14) com a identidade (o id, D15), no
  mesmo bloco: a D14 media a unidade sem a identidade, a D15 a identidade sem a unidade, e cada
  metade deixou passar um caso que a outra fechava (a D7 e a D13 não mediam nenhuma das duas). Ela
  não lê o `45-docs.md`, que é rótulo; o que
  conta é a entrada que ficou, citando a missão, quem quer que a tenha escrito (a DOCS ou um incremento do EXEC, como o I13
  desta missão). Range vazio (missão na base, já
  mergeada, sem base resolvida) → a resposta de hoje, como o `mission_qa_report`.
- **As três entradas da âncora têm estrutura** (D16, D17, D23): a entrada do `KAIZEN_LOG.md` é um
  bloco (D16); o id da missão é uma gramática que o runner confere no `resolve_mission` (D17, I11),
  e é ela que torna exata a fronteira do `cites_id`; a promessa do plano é uma chave literal do
  frontmatter, lida pelo `frontmatter` que o runner já tem (D23, que substituiu a D19). Até a 7ª
  rodada do PR #247, só a primeira tinha estrutura; as outras duas eram regra sobre texto cru, e
  cada rodada achou o caso que o texto cru deixava passar. A D19 deu estrutura à promessa lendo a
  tabela, e a 16ª rodada mostrou que ler Markdown aos pedaços não fecha: o "não" saiu do Markdown.
- **A missão na base não promete o K8** (D20, I12): na base não há range para ler a entrada, então
  o `gate_PLAN` recusa `branch:` igual à `DEFAULT_BRANCH` quando o frontmatter tem `kaizen_log:` sem
  `skipped` (a promessa escrita, D23), e o `gate_DOCS` recusa o mesmo como reforço para o `--phase`
  forçado.
- **O aceite e o planner são prosa**, e o sensor é o `check-hat.sh`. O `gate_PLAN` muda só pelo I12:
  `auto` e `humano-YYYY-MM-DD` continuam válidos.

## Incrementos

A tabela executável vive em `checkpoint.md` (é ela que o runner lê). Aqui fica o **porquê** de
cada fatia — o detalhe que não cabe numa célula.

### I1 — a rota do `skipped` declarado, e o motivo que diz o que leu

**O quê:**
- No `qa_substep`, logo depois da linha sem interface (`bin/sdd:2678`):
  `if [ "$(frontmatter "$MISSION_DIR/00-missao.md" qa)" = skipped ]; then printf 'close\n'; return 0; fi`.
  O comentário nomeia o dono do artefato que o gate vai exigir (o `sdd-qa`, que escreve o
  `30-handoff-qa.md` e confere o diff, ADR 0018 §1) e diz por que é literal.
- No `gate_QA` (`:1606`), o motivo passa a `30-handoff-qa.md declares status: skipped`.

**Onde:** `bin/sdd` (`qa_substep`, `gate_QA`), `tests/check-dry-run.sh`, `tests/check-gates.sh`,
`tests/check-mutation.sh`, `.claude/rules/anatomia-do-agente.md` § 4 (uma frase: a sub-etapa lê o
`qa: skipped` do plano). `bash tests/check-lang.sh` verde: os comentários novos são superfície.

**Como (TDD):**
- `check-dry-run.sh`, no bloco de QA, logo depois do mundo do relatório `in-progress` (`:516-520`,
  que projeta `QA:exec=<none>` com charter e sem relatório fechado): insira `qa: skipped` no
  frontmatter do `$MDIR/00-missao.md` (`sed -i 's/^aprovacao: auto$/&\nqa: skipped/'`) e afirme
  `QA:close=sdd-qa` com o nome exato `a plan that declares qa: skipped goes straight to QA:close with
  an interface`. Vermelho hoje: projeta `QA:exec=<none>`.
- No mesmo lugar, o controle: `qa: Skipped` volta a projetar `QA:exec=<none>`, com o nome
  `a misspelt qa: Skipped keeps the route of today`.
- Restaure com `git checkout -q -- "$MDIR/00-missao.md"` (o arquivo é commitado no fixture, `:134`).
- `check-gates.sh`, no bloco `:2043-2047`, entre o `printf … status: skipped` e o `mv`: um
  `assert_why "the skipped reason names the handoff that declares it" "QA" "30-handoff-qa.md declares
  status: skipped"` e um `assert_why_absent "the skipped reason no longer claims a property of the
  diff" "QA" "user-visible"`.
- Mutantes (com `--only <slug> check-dry-run.sh`):
  - `QA_substep_skipped_ignored` apaga a linha nova (âncora no texto `qa)" = skipped`);
  - `QA_substep_skipped_loose` troca `= skipped ]` por `!= "" ]`, e quem o pega é o controle.

**Check:** `a=$(bash tests/check-dry-run.sh 2>&1); b=$(bash tests/check-gates.sh 2>&1); x=$(grep -c '^  ok    a plan that declares qa: skipped goes straight to QA:close with an interface' <<< "$a"); y=$(grep -c '^  ok    the skipped reason names the handoff that declares it' <<< "$b"); echo "$x $y"` → `1 1`
**Sensor durável:** as asserções e o controle no `check-dry-run.sh` e no `check-gates.sh`, mais os
dois mutantes no catálogo.
**Reversível por:** reverter o commit; nenhum artefato em disco depende dele.

### I2 — o contrato da chave `qa:`

**O quê:** o contrato nos lugares que o leem, no mesmo commit:
- `templates/missao.md`: a linha `qa:` no frontmatter, depois de `ddd:`, com o placeholder
  `<vazio, ou skipped quando o grill decide que o diff não chega ao usuário — só o literal skipped
  desvia a rota da QA; a justificativa vai nas Decisões do grill>`. O placeholder não é o literal,
  então um plano que o copia segue a rota de hoje.
- `tests/check-templates.sh:336`: `qa` entra na lista de chaves.
- `agents/sdd-qa.md`:
  - § 0: um parágrafo sobre o terceiro caso. Com interface e o plano declarando `qa: skipped`, o
    runner manda direto a esta sessão, sem `qa-report`/`qa-execution`.
  - § 2: um parágrafo que comece por **"When the plan declares `qa: skipped`"**:
    1. leia a justificativa no `00-missao.md`;
    2. compare com o diff real (`git diff <base>...HEAD --stat` e os arquivos);
    3. nada visível ao usuário → `status: skipped`, citando a decisão do plano e os arquivos;
    4. algo visível → `status: blocked`, nomeando os arquivos e o remédio inteiro: tirar o
       `qa: skipped` do `00-missao.md` **e apagar este handoff** (`git rm` do `30-handoff-qa.md`),
       commitar, e `sdd run`. Achado do Codex no PR #247, conferido: o `gate_QA` relê um handoff
       `blocked` deixado no lugar e arma o `GATE_HANDOFF_BLOCKED` (`bin/sdd:1612-1615`); como a
       escalada só é lida **depois** da sessão (`bin/sdd:8989-8990`), cada `sdd run` paga uma sessão
       (`QA:plan`, depois `QA:exec`) e para de novo, e só o 3º lançamento chega ao `close` que
       reescreve. Sem o handoff, o gate diz `missing 30-handoff-qa.md`, não escala, e a corrida
       segue `plan` → `exec` → `close` num lançamento só.

    Sob a declaração, nunca caminhe, nunca crie `docs/qa/`, nunca escreva `done`.
- `agents/sdd-planner.md` § 1: quando o grill decide que a QA não se aplica num projeto com
  interface, o planner escreve `qa: skipped` e a justificativa nas decisões.
- `docs/pipeline.md` § QA: na tabela (`:252`), o `QA:close` ganha "or the plan declares
  `qa: skipped`", e o parágrafo do `skipped` (`:354`) diz quem declara e quem confere.
- `tests/check-hat.sh`: um probe novo dentro de `hat_promise_probes` (`:305`), que lê a § 2 do
  `sdd-qa.md` por seção (`awk '/^## 2\. /{s=1; next} s && /^## /{s=0} s'`, o molde do
  `planner_agent_probes`). Ele exige o literal `the plan declares` + `qa: skipped`, `status:
  blocked` e o remédio (`git rm`) e imprime `hat: sdd-qa confirms a declared qa: skipped against the diff`. Passada de
  sabotagem de cada frase no `checkpoint-notas.md`.
- `./bin/sdd install --force`.

**Onde:** os seis arquivos acima.
**Como (TDD):** a chave no `check-templates.sh` e o probe no `check-hat.sh` primeiro, ambos
vermelhos; depois a prosa. `bash tests/check-lang.sh` verde (o `sdd-qa.md` e o `sdd-planner.md` são
superfície inglesa; o template é pt-BR).
**Check:** `a=$(bash tests/check-templates.sh 2>&1); b=$(bash tests/check-hat.sh 2>&1); x=$(grep -c "^  ok    missao.md: frontmatter key 'qa'" <<< "$a"); y=$(grep -c '^  ok    hat: sdd-qa confirms a declared qa: skipped against the diff' <<< "$b"); echo "$x $y"` → `1 1`
**Sensor durável:** a chave no `check-templates.sh` e o probe no `check-hat.sh`. O comportamento é
medido pelo I1.
**Reversível por:** reverter o commit.

### I3 — a rota do reteste

**O quê:**
- O helper `qa_fix_ahead_of <caminho relativo à raiz>`, perto do `report_closed` (`bin/sdd:2666`),
  e o seu predicado `qa_rewritten_after <conserto> <caminho>`, os dois lidos por `$( )` ou como
  condição, sem tocar global:

  ```bash
  qa_rewritten_after() {
    local c="$1" p="$2" h x rest
    h="$(git -C "$REPO_ROOT" rev-parse -q --verify "HEAD:$p" 2>/dev/null || true)"
    [ -n "$h" ] || return 1
    while read -r x; do
      [ "$(git -C "$REPO_ROOT" rev-parse -q --verify "$x:$p" 2>/dev/null || true)" = "$h" ] && return 1
    done < <(git -C "$REPO_ROOT" rev-list --full-history "$c" -- "$p" 2>/dev/null || true)
    while read -r x rest; do
      [ "$(git -C "$REPO_ROOT" rev-parse -q --verify "$x:$p" 2>/dev/null || true)" = "$h" ] || continue
      [ "$(wc -w <<< "$rest")" -eq 1 ]; return
    done < <(git -C "$REPO_ROOT" rev-list --reverse --topo-order --ancestry-path --parents "$c..HEAD" 2>/dev/null || true)
    return 1
  }
  ```

  Para cada linha de `checkpoint_rows` com ID `^F[0-9]+$`, status `done` e commit não vazio que
  resolve, o `qa_fix_ahead_of` imprime `<ID> <commit>` e para quando `qa_rewritten_after` falha.
  Senão, não imprime nada. **Reescrito depois do conserto** são duas coisas ao mesmo tempo:
  - **os bytes são novos.** O blob do caminho em `HEAD` não é nenhuma versão que o caminho teve
    até o conserto (`rev-list --full-history` do conserto, inclusive ele);
  - **quem os escreveu não foi um merge.** O primeiro commit depois do conserto, na ordem
    topológica e no caminho de ancestralidade, que carrega aquele blob tem um pai só.

  É o estado que faltava (12ª rodada, a segunda seguida neste helper): a origem dos bytes que `HEAD`
  tem. As duas metades da 10ª rodada (um commit sem merge tocou o caminho; o blob mudou) eram proxies
  dela. Codex, na 12ª rodada: depois do conserto, um merge leva o arquivo de A a B, uma edição comum
  o leva a C, e o revert dela o devolve a B. As duas metades viam um commit sem merge e um blob
  diferente do conserto, e liam reescrito; a única mudança que sobrou veio do merge.
  **Medido** (protótipo, git 2.43.0), em 12 mundos:
  - a regra da 10ª rodada falha aberto em 2: o do Codex, e uma versão de antes do conserto
    restaurada depois dele;
  - "sem merge que tocou o caminho" (no lugar do primeiro portador) cobra a mais em 2: um merge
    seguido de uma reescrita honesta, e uma reescrita feita numa branch cortada depois do conserto e
    mergeada de volta;
  - esta dá a resposta esperada nos 12, inclusive reescrever, reverter e reescrever de novo.

  Resíduos declarados no comentário:
  - uma reescrita honesta que reproduz byte a byte uma versão anterior ao conserto lê como não
    reescrita (falha fechada: mais um reteste);
  - o custo é um `rev-parse` por commit que tocou o caminho até o conserto, mais um por commit da
    missão depois dele, poucos numa missão.
  **O que a reescrita prova, e o que não prova** (CodeRabbit, 11ª rodada, que pedia "evidência
  explícita de reteste"): ela prova que o dono do arquivo escreveu nele depois do conserto, e é o
  artefato mais forte que existe para "o reteste rodou". O **resultado** do reteste já tem artefato
  próprio: o `Status:` do bug no registro, que nenhum agente do kit escreve (só as skills de QA; o
  comentário da Âncora 3, `bin/sdd:1676-1685`) e que a Âncora 3 do `gate_QA` já exige fora de
  `open` para todo bug `Closable by: agent`. Uma edição só de formatação depois do conserto falha
  fechado: no relatório, a sub-etapa vai ao `close`, e a Âncora 3 recusa enquanto o bug não se
  mexeu, então a linha para pelo `no_work_check` quando o mesmo passo volta com o mesmo motivo; no
  handoff, o gate só passa com a Âncora 3 satisfeita, isto é, com o reteste feito. O que a prosa
  do handoff diz é rótulo que o modelo escreve, e a REVIEW o lê (princípio 1 do `CLAUDE.md`).
  Exigir no texto do relatório uma citação do `F<n>` seria esse rótulo, e a skill de terceiro que
  escreve o relatório não conhece o id do `F<n>`.
  **Limite declarado (D21):** o helper só lê `F<n>`. Um `R<n>` do REVIEW, que vem depois da QA, muda
  o código sem reabrir o reteste; é o comportamento do kit de antes desta missão, e o achado está no
  `TODO.md`. O comentário do helper diz isso.
  - Não atribui global (é lido por `$( )`).
  - Captura com `|| true`.
  - Commit que não resolve é pulado; é inalcançável numa corrida derivada, porque o `gate_EXEC` vem antes.
  - O comentário do cabeçalho diz "uma definição, dois leitores" e cita a ADR 0018 §2.
- No `qa_substep`, depois do `report_closed`, sobre o relatório que ele já leu (`report`, `:2680`):
  `[ -z "$(qa_fix_ahead_of "${report#"$REPO_ROOT"/}")" ] || { printf 'exec\n'; return 0; }`.
  Nunca o diretório `reports/` inteiro: ver o Contexto verificado (a posse).
- Os três comentários que afirmam `disable-model-invocation` das skills de QA deixam de afirmar:
  o do `qa_substep` (`:2650-2655`), o de antes do `ticket` (`:2913-2921`) e o do boot (`:2977-2979`,
  "the QA skills carry disable-model-invocation, so there is no other route"). Eles passam a dizer o
  que o kit sabe, **sem escrever o nome da flag** (chame-a "the skill's invocation flag"):
  - o slash é a rota do runner, qualquer que seja a flag;
  - medido em 2026-10-12, as duas skills a declaram `false`, e o `sdd-qa` as chamou pela ferramenta
    `Skill` cinco vezes;
  - a rota existe para isso não ser preciso.
  O comentário do `ticket` (`:2920`, "the `ticket` skill has no `disable-model-invocation`") está
  certo e fica: depois do I3, `grep -c 'disable-model-invocation' bin/sdd` dá `1`, e essa linha fala
  do `ticket` (hoje dá `4`: `:2652`, `:2916`, `:2920`, `:2978`). O Check cobra a contagem, e a conta
  com `awk`, não com `grep`: a regra 2 do `tests/check-checkpoint.sh` vale por célula (o item (e) do
  `TODO.md`), e um segundo `grep` na célula que tem `2>&1` reprova mesmo lendo um arquivo.
- `phase_task` do `QA:exec` (`:2935`): o texto cobre também o reteste dos bugs consertados, por
  exemplo `walk the journeys in persona and write the dated report + the bug registry; after a fix
  increment, retest the fixed bugs and move their Status`. A frase `retest the fixed bugs` é
  literal: o passo 3 a lê no boot projetado.
- `agents/sdd-qa.md` § 4 (`:97-103`): depois de um `F<n>` feito, o runner devolve a QA à
  `qa-execution` (`QA:exec`), que reteste e move o `Status:`, e depois a esta sessão, para reescrever
  o handoff (§ 6). **Esta sessão nunca invoca as skills `qa-*`, nem pela ferramenta `Skill`.** Um
  probe no `check-hat.sh` lê a frase (`hat: sdd-qa leaves the retest to the runner`), com passada de
  sabotagem nas notas.
- `docs/pipeline.md` § QA: a linha `QA:exec` da tabela ganha "or the mission's report was not
  rewritten after a done `F<n>`". `.claude/rules/anatomia-do-agente.md` § 4: uma frase.
- `./bin/sdd install --force`.

**Onde:** `bin/sdd`, `agents/sdd-qa.md`, `docs/pipeline.md`, a anatomia, `tests/check-dry-run.sh`,
`tests/check-hat.sh`, `tests/check-mutation.sh`.

**Como (TDD):** um mundo novo no `check-dry-run.sh`, no bloco de QA, depois do mundo da posse do
relatório (`:522-538`) e **antes** da limpeza dele. No fixture em `main` o range é vazio e o
`mission_qa_report` lê o mais novo. Passos, em ordem:
1. Com `E2E_CMD="true"` e charter presente, escreva um relatório `open` e commite; troque-o para
   `closed` e commite de novo (`git add docs/qa && git commit -qm …`), e guarde o hash do primeiro
   commit, `o`. Faça um commit vazio de conserto (`git commit -q --allow-empty -m "fix: F1"`) e
   guarde o hash curto `h`.
2. Acrescente ao `$MDIR/checkpoint.md` a linha `| F1 | the fix | \`true\` → 0 | pending | — |`.
   Afirme `QA:close=sdd-qa` com o nome `a pending fix increment does not reopen the walk`.
3. Troque a linha para `done` com `$h`. Afirme `QA:exec=<none>` com o nome
   `a fix increment done after the closed report sends QA back to exec for the retest`. Hoje isso é
   vermelho: projeta `QA:close=sdd-qa`. Na mesma projeção, leia o bloco de boot do `QA` com a
   função `prompt_of` do `check-dry-run.sh` (sobre a saída desta projeção) e afirme, com o nome
   `the retest boot tells the session to retest the fixed bugs`, que ele contém
   `retest the fixed bugs` (a tarefa nova do `QA:exec`). Um bloco vazio reprova, como no bloco
   `review_prompt` logo abaixo da função, que recusa ler o nada.
4. O mundo da versão antiga: `git checkout "$o" -- <relatório>` e commite (a versão `open`, de antes
   do conserto, volta depois dele). Afirme `QA:exec=<none>` com o nome
   `a pre-fix version restored after the fix is not the retest`. Depois, `git revert --no-edit HEAD`.
5. O mundo do merge: corte uma branch do commit **anterior** ao F, acrescente nela um relatório com
   nome que ordena **depois** do da missão (em `main`, com range vazio, ele vira a escolha do
   `mission_qa_report`), volte e faça `git merge --no-ff`. Afirme que ainda é `QA:exec=<none>`, com o
   nome `a report a merge brings in after the fix is not the retest`. **Guarde a branch**: o passo 8
   volta a ela.
6. Acrescente uma linha ao relatório escolhido e commite. Afirme `QA:close=sdd-qa` com o nome
   `a report committed after the fix closes the retest`.
7. O mundo do revert (Codex, PR #247, 10ª rodada): `git revert --no-edit HEAD` desfaz o commit do
   passo 6, e o relatório volta byte a byte ao estado do conserto. Afirme `QA:exec=<none>` com o
   nome `a report edit reverted after the fix is not the retest`.
8. O mundo do merge com revert (Codex, PR #247, 12ª rodada): na branch do passo 5 (cortada antes do
   F), troque o conteúdo do relatório escolhido por uma linha `B` e commite; na `main`,
   `git merge --no-ff` dela (o relatório chega a `B` pelo merge); acrescente uma linha ao relatório e
   commite; `git revert --no-edit HEAD`. Afirme `QA:exec=<none>` com o nome
   `a report a merge changed after the fix is not the retest, even after an edit and its revert`.
9. O mundo da posse (CodeRabbit, PR #247): corte uma branch de missão a partir deste ponto (molde
   `:522-538`, porque com range vazio não há posse a medir). Nela, commite um relatório **novo** e
   `closed` (o da missão), um commit de conserto com o `F1` `done` no hash dele, e depois, num commit
   comum, uma linha acrescentada a um relatório **da base** (de outra missão: editar não dá posse).
   Afirme `QA:exec=<none>`, com o nome `another mission's report touched after the fix is not the
   retest`. Volte à `main` e apague a branch.
10. Restaure tudo byte a byte: o checkpoint com `git checkout -- "$MDIR/checkpoint.md"`, a história
    com `git reset -q <sha guardado antes do mundo>` (mixed, como o bloco vizinho, porque o config
    modificado é do bloco seguinte), as branches apagadas, e `docs/qa/` removido.

Mutantes (cada um provado por `--only <slug> check-dry-run.sh`), cada um sabotado no protótipo:
- `QA_substep_retest_ignored` apaga a linha nova do `qa_substep` → o passo 3;
- `QA_fix_ahead_any_order` troca `--ancestry-path --parents "$c..HEAD"` por `--parents HEAD` na
  segunda varredura → os passos 5 e 8;
- `QA_fix_ahead_counts_merges` troca `[ "$(wc -w <<< "$rest")" -eq 1 ]; return` por `return 0` (o
  merge conta como quem escreveu) → os passos 5 e 8;
- `QA_fix_ahead_old_content_ok` apaga o primeiro laço (o dos bytes novos) → os passos 4 e 7;
- `QA_fix_ahead_any_carrier` troca `[ "$(wc -w <<< "$rest")" -eq 1 ]; return` por
  `[ "$(wc -w <<< "$rest")" -eq 1 ] || continue; return 0` (pula o merge e aceita um portador
  posterior) → só o passo 8;
- `QA_fix_ahead_reads_the_directory` troca o `${report#…}` do `qa_substep` por
  `$QA_DOCS_PATH/reports/` → o passo 9.

**Check:** `o=$(bash tests/check-dry-run.sh 2>&1); h=$(bash tests/check-hat.sh 2>&1); a=$(grep -c '^  ok    a fix increment done after the closed report sends QA back to exec for the retest' <<< "$o"); c=$(grep -c '^  ok    the retest boot tells the session to retest the fixed bugs' <<< "$o"); d=$(grep -c '^  ok    hat: sdd-qa leaves the retest to the runner' <<< "$h"); b=$(awk '/disable-model-invocation/ { n++ } END { print n + 0 }' bin/sdd); echo "$a $c $d $b"` → `1 1 1 1`
O Check lê os três contratos que o I3 escreve (a rota no `qa_substep`, a tarefa do `QA:exec`, a
frase do `sdd-qa.md` § 4) e a contagem dos comentários do `bin/sdd` (CodeRabbit, 10ª rodada).
**Sensor durável:** as nove asserções no `check-dry-run.sh`, os seis mutantes, o probe do
`check-hat.sh`, e o `no_work_check` como freio de um reteste que não produz commit.
**Reversível por:** reverter o commit. O `sdd-qa` volta a improvisar como hoje.

### I4 — o frescor do handoff de QA

**O quê:**
- No `gate_QA`, logo depois do enum positivo (`bin/sdd:1621-1624`) e **antes** da divisão de
  caminho (`:1633`), para valer nos dois:
  `ahead="$(qa_fix_ahead_of "${h#"$REPO_ROOT"/}")"`, onde `h` é o caminho absoluto já definido em
  `:1601`. Confira que o `REPO_ROOT` é prefixo de `h`; se não for, use `$HANDOFF_DIR/$MISSION/30-handoff-qa.md`.
  Com `ahead` não vazio, o `GATE_WHY` passa a ser
  `30-handoff-qa.md was not rewritten after ${ahead%% *} (${ahead#* }) — the sdd-qa close rewrites it once the fix is retested`
  e o gate devolve 1.
- O comentário nomeia o dono, que é o `sdd-qa` (§ 6 "Commit everything"), e diz como ele é
  alcançado: com interface, pelo `close` que o `qa_substep` dá depois do commit de relatório do
  reteste; sem interface, de imediato. Diz também por que o `skipped` e o `blocked` ficam fora: os
  dois retornam antes. E declara o limite da D21: o frescor só olha `F<n>`, então um `R<n>` do
  REVIEW depois da QA não pede o handoff de novo, e um `skipped` não é reconferido contra o diff que
  o `R<n>` mudou (o achado está no `TODO.md`).
- `agents/sdd-qa.md` § 6: o handoff é reescrito e commitado depois de cada `F<n>` feito, e o gate
  recusa um handoff mais velho que o último conserto.
- `docs/pipeline.md` § QA "Passes when": a condição nova. Anatomia § 4: uma frase.
- **A âncora do `TODO.md`.** O item `bin/sdd:1800` (`gate-qa-e2e`) desce com as linhas que o I1 e
  o I4 acrescentam acima dele. Confira com `bash tests/check-todo.sh --anchors TODO.md` **depois do
  I4**, nunca por um número escrito aqui; se sair do alvo, troque o número pela linha atual do
  `run_check_cmd "$E2E_CMD" "gate-qa-e2e"` **no mesmo commit**.
- **O fixture do `check-autonomy.sh:1715-1775`.** A sessão 2 do stub (EXEC) fecha o F1 e o bug, e a
  asserção espera `QA EXEC REVIEW DOCS`. Com o frescor, a QA reabre. Escolha uma das duas
  correções e anote qual no `checkpoint-notas.md`:
  - a sessão 2 do stub também reescreve e commita o `30-handoff-qa.md` depois do `F1 is done`;
  - a sequência esperada ganha a QA de novo.

  O que o fixture mede ("o `gate_pass_rows` perguntado de novo com o veredito de QA nos livros")
  tem de continuar medido.

**Onde:** `bin/sdd` (`gate_QA`), `agents/sdd-qa.md`, `docs/pipeline.md`, a anatomia, `TODO.md`
(talvez), `tests/check-gates.sh`, `tests/check-autonomy.sh`, `tests/check-mutation.sh`.

**Como (TDD):** cinco asserções no `check-gates.sh`, com o prefixo exato `freshness: `.
- Com interface, em `:1969`, onde a QA passa, numa sequência:
  1. commite o handoff; faça um commit de conserto e acrescente ao checkpoint `| F1 | … | done | <h> |`
     (commitado, porque o `gate_EXEC` exige o hash na história);
  2. `freshness: with an interface, a handoff committed before a done F<n> holds QA and names the
     fix`: `sdd phase` dá `QA`, e o `sdd why QA` contém `30-handoff-qa.md was not rewritten after F1`
     (o motivo diz "não reescrito", e não "sem commit": depois de um revert há commit e o handoff é o
     de antes);
  3. reescreva o handoff e commite; `freshness: the handoff committed after the fix lets QA pass`
     dá `REVIEW`;
  4. `freshness: a handoff rewrite reverted after the fix holds QA again` (Codex, 10ª rodada):
     `git revert --no-edit HEAD` desfaz o passo 3, e `sdd phase` dá `QA` de novo (o passo 5 lê só o
     motivo de um `F` pendente, e não depende do handoff);
  5. `freshness: a pending F<n> demands nothing of the handoff`, com o F em `pending` antes do
     commit do conserto. ⚠️ Com um `pending`, a fase é EXEC; leia então só o `sdd why QA` e exija a
     **ausência** de `was not rewritten after`.
- Sem interface, em `:2016`: `freshness: without an interface, the same handoff holds QA too`.

Restaure o fixture (o checkpoint e a história) para o bloco seguinte. Mutante
`QA_handoff_freshness_ignored`, que neutraliza o `if` novo; prove com `--only
QA_handoff_freshness_ignored check-gates.sh` (~2 min).

**Check:** `o=$(bash tests/check-gates.sh 2>&1); grep -c '^  ok    freshness: ' <<< "$o"` → `5`
**Sensor durável:** as cinco asserções e o mutante (o `QA_fix_ahead_old_content_ok` do I3 também
cai no passo 4). O `check-autonomy.sh` passa a medir a corrida
com o frescor.
**Reversível por:** reverter o commit, junto com o I3, porque o reteste sem frescor deixa o handoff
mentindo.

### I5 — o spec do bug que nenhum agente fecha

**O quê:** `agents/sdd-qa.md` § 3 ganha o caso do bug `Closable by: human` ou `deferred`. O spec
existe, reproduz o achado, e chama `test.fail()` **depois das pré-condições**: o vermelho fica nelas,
de modo que um setup quebrado continua reprovando; o spec passa enquanto o bug existe e reprova
quando o conserto entra, que é o dia de tirar o marcador. `test.fixme()` e `test.skip()` não rodam e
são decoração. Sem isso, o spec vermelho derruba o `E2E_CMD` do `gate_QA` e gasta o `QA_MAX_ITER`
num bug que ninguém aqui pode fechar (o `kit:` do L3, `30-handoff-qa.md:99` de
`20261011-detalhe-e-lista-dizem-a-verdade` no `sales_quote`). Um probe no `check-hat.sh` lê a § 3:
exige `test.fail()` e `after the preconditions` e imprime `hat: sdd-qa writes the spec of a bug no
agent closes with test.fail() after its preconditions`. Passada de sabotagem nas notas.
`./bin/sdd install --force`.
**Onde:** `agents/sdd-qa.md`, `tests/check-hat.sh`.
**Como (TDD):** o probe primeiro (vermelho), depois a prosa; `bash tests/check-lang.sh` verde.
**Check:** `o=$(bash tests/check-hat.sh 2>&1); grep -c '^  ok    hat: sdd-qa writes the spec of a bug no agent closes with test.fail' <<< "$o"` → `1`
**Sensor durável:** o probe. O idioma é do Playwright do alvo, e o kit não roda e2e de alvo; a
semântica do `test.fail()` é a medida no L3.
**Reversível por:** reverter o commit.

### I6 — o aceite lê o plano

**O quê:** `commands/sdd-plan.md`, seção `## When the artifacts exist`, passo 3 reescrito. Antes da
pergunta, nesta ordem:
1. **Medir de novo.** Rode `tests/check-checkpoint.sh --check <checkpoint>` e `--red <checkpoint>`
   pelo caminho do kit (`~/repos/sdd_agents/tests/…` num alvo; `tests/…` no worktree do kit), a
   partir da raiz, e mostre as linhas. Um `FAIL`, ou uma linha `is red at HEAD (prints …)` diferente
   da que o plano registra, volta ao planner antes da pergunta. Foi esse passo que pegou a medição
   velha do L4. O `--red` custa o que os Checks custam (o deste plano levou 9 min 47 s), e a
   ferramenta Bash corta em 2 min por padrão e em 10 no máximo: rode-o **em background** e espere a
   linha final `<n> pending Check(s), every one red at HEAD`. Uma corrida sem essa linha (cortada,
   morta, sem saída) conta como **não medida** e volta ao planner, como um `FAIL`.
2. **Renderizar o plano**, no formato de um plano `superpowers:writing-plans`:
   - cabeçalho com **Goal**, **Architecture** e **Tech Stack**;
   - as restrições globais: escopo, fora de escopo, as decisões do grill;
   - cada incremento como `### Task <ID>`, com **Files:**, passos `- [ ]` (comando e resultado
     esperado) e o Check;
   - a tabela PLAN-AUTO e as pendências;
   - a contagem das respostas do grill, `N (recommended) of M`, que sai do **leitor da D22**,
     escrito literal na seção num bloco `bash` (é ele que o probe lê):

     ```bash
     awk '/^## / { s = /^## Decis[^ ]* do grill/ } s && /^ +- answer: \((recommended|other: .+)\)$/ { m++; if (/^ +- answer: \(recommended\)$/) n++ } END { print n + 0 " (recommended) of " m + 0 }' <HANDOFF_DIR>/<mission>/00-missao.md
     ```

     `M` é o número de linhas inteiras `- answer: (recommended)` ou `- answer: (other: …)` dentro da
     seção de decisões do grill; `N`, as `(recommended)` entre elas. Nada fora dessas linhas conta:
     a prosa que cita o token, uma nota dentro dos parênteses, uma marca partida em duas linhas, uma
     linha `- answer:` sem recuo (fecharia a lista numerada), o placeholder do template e qualquer
     outra seção. A seção é aberta por `^## Decis[^ ]* do grill`, em ASCII, porque o
     `check-lang.sh` reprova o `õ` do título dentro do `commands/` (medido num clone: o título
     escrito no `commands/sdd-plan.md` dá `FAIL  Portuguese outside the allowlist`, o leitor acima
     não dá `FAIL` nenhum). Logo abaixo do bloco, a seção diz os dois limites: uma linha
     `- answer:` dentro de cerca de código na seção de decisões conta, e uma marca com espaço ou
     `\r` no fim não conta (a resposta some do `M`).

   Mantenha a frase `first show the human what they are approving`.
3. **Perguntar.** A pergunta YES/NO nomeia cada critério PLAN-AUTO ✗, ou diz que todos estão ✅ e a
   aprovação é do humano; nomeia também a branch onde a sessão está. Ficam o `AskUserQuestion`, as
   linhas `- **YES** … sdd approve <mission>` e `- **NO**`, e `Only the human's answer to that
   question approves`.

O aviso final (`:143-146`) passa a proibir **prosa** de aprovação em `aprovacao:`. O gate aceita só
`auto`, que o planner escreve quando o humano o pede no grill, ou `humano-YYYY-MM-DD`, que vem do
`sdd approve`. O aviso diz que proíbe prosa, nunca o `auto`, e conta que, repassado ao planner como
"nunca escreva `aprovacao:`", ele suprimiu um `auto` (L2).

**Onde:** `commands/sdd-plan.md`, `tests/check-hat.sh` (`command_approval_probes`, `:321`).
**Como (TDD):** três pares `pass`/`fail` novos em `command_approval_probes`, lendo a mesma seção, com
os nomes exatos:
- `command: /sdd-plan renders the plan and re-runs --check and --red before the YES or NO`: exige
  `check-checkpoint.sh --check`, `--red`, `Goal`, `Architecture`, `Tech Stack` e `**Files:**`;
- `command: /sdd-plan names every unmet criterion, or says all are met, and counts the recommended
  answers`: exige a frase que cobre o caso todo ✅ e o leitor da D22 literal, por `grep -qF` de três
  pedaços na seção: `/^## Decis[^ ]* do grill/`, `/^ +- answer: \((recommended|other: .+)\)$/` e
  `" (recommended) of "`. Um `(recommended)` solto na prosa não o satisfaz; a sabotagem tira o `^`
  ou o `$` da regex da linha, e troca a âncora da seção por `/^## /`, e o probe fica vermelho em
  cada uma;
- `command: /sdd-plan forbids approval prose in aprovacao, never auto`: exige a frase nova do aviso.

Vermelhos antes da prosa. Passada de sabotagem de cada frase nas notas. O par antigo
(`asks the human YES or NO before it runs sdd approve`) continua verde.
**Check:** `o=$(bash tests/check-hat.sh 2>&1); grep -c -e '^  ok    command: /sdd-plan renders the plan' -e '^  ok    command: /sdd-plan names every unmet criterion' -e '^  ok    command: /sdd-plan forbids approval prose' <<< "$o"` → `3`
**Sensor durável:** os três probes. O `commands/` fica fora da chave do carimbo e do catálogo; o
probe é o sensor inteiro, como o de `command_approval_probes` declara.
**Reversível por:** reverter o commit.

### I7 — o planner

**O quê:**
- `agents/sdd-planner.md`:
  - **§ 1, a marca de cada resposta (D8 na forma da D22).** Logo depois do parágrafo "Record the
    decisions in `00-missao.md`", um parágrafo novo, com estas frases (o probe lê os quatro
    pedaços em itálico; o itálico é só deste plano, o arquivo leva o texto sem ele):
    "**Mark each answer.** Every answer the human gives becomes its own line at the end of its
    decision in `00-missao.md`, indented under it: *`- answer: (recommended)`* when they chose the
    option you marked recommended, *`- answer: (other: <the option they chose>)`* when they chose
    another. *One line per answer*: a question asked twice (a confirmation, a reopened decision)
    gets two lines. A note *never goes inside the parentheses*; it goes in the decision's prose.
    The acceptance step of `/sdd-plan` counts only these whole lines inside the decisions section,
    so no count of answers is written by hand anywhere in the plan (ADR 0018 §3)."
  - **§ 1, a reestimativa (i).** O aviso de trabalho longo leva uma estimativa. O planner roda
    `date` ao começar, e ao chegar a 2× a estimativa para no próximo ponto seguro e devolve uma
    linha: o que fez, o que falta, a nova estimativa. Medido no L4: 30 min estimados, ~2h55 reais.
  - **§ 2, as regras de nome do alvo (g).** Antes de dar nome a qualquer coisa, o planner lê as
    regras de nome e de idioma do `CLAUDE.md` e das `.claude/rules/` do alvo: identificadores, nome
    de arquivo, convenção de teste. Todo arquivo e símbolo novo do plano segue essas regras, e o
    teste de autocontenção (§ 5) confere cada um. Medido no L3: arquivo novo em português contra o
    `<CRITICAL>` do alvo, pego só por um bot depois do PR.
  - **§ 6.** "All ✅ → `aprovacao: auto`" passa a "All ✅ → leave `aprovacao:` empty: the human
    reads the plan in the acceptance step and approves with `sdd approve`; write `auto` only when
    the human asked for it in the grill" (ADR 0018 §3). A exceção do kaizen fica como está, e a
    regra inegociável de `:251` acompanha.
- `commands/sdd-plan.md`, seção `## Relaying the grill to the human`, bullet "Long work" (`:99`): a
  mesma reestimativa a 2×, vista do lado do relay.
- `templates/missao.md`, `## Decisões do grill`: o placeholder `1. <decisão + porquê em uma linha>`
  ganha a linha de baixo, e fica:

  ```text
  1. <decisão + porquê em uma linha>
     - answer: <(recommended), ou (other: <a opção escolhida>); uma linha por resposta>
  ```

  O `<` logo depois de `answer: ` faz o leitor da D22 não contar o placeholder (medido: um
  `00-missao.md` recém-copiado do template dá `0 (recommended) of 0`). Na lista numerada, a linha
  `- answer:` recua 3 espaços sob `1.` a `9.` e 4 sob `10.` em diante, senão o GFM fecha a lista;
  o leitor aceita qualquer recuo (`^ +`).
- `tests/check-hat.sh`:
  - `planner_agent_probes` (`:392`) ganha três pares, cada um lendo a **sua** seção (§ 1, § 2, § 6):
    - `hat: the planner marks each grill decision (recommended) or (other)`: o nome fica (o Check
      conta por ele), e o probe exige na § 1, por `grep -qF`, os quatro pedaços em itálico acima:
      `- answer: (recommended)`, `- answer: (other: <the option they chose>)`,
      `One line per answer` e `never goes inside the parentheses`; a sabotagem tira cada um;
    - `hat: the planner reads the naming rules of the target before it names a file`;
    - `hat: the planner leaves aprovacao empty under /sdd-plan unless the human asks for auto`.
  - `command_relay_probes` (`:349`) ganha `command: /sdd-plan re-estimates long work that runs past
    twice the estimate`.
- `./bin/sdd install --force`.

**Onde:** `agents/sdd-planner.md`, `commands/sdd-plan.md`, `templates/missao.md`, `tests/check-hat.sh`.
**Como (TDD):** os quatro probes primeiro, vermelhos; depois a prosa. **Não toque a § 4 do
planner**, cujas frases o `check-checkpoint.sh` lê. `bash tests/check-templates.sh` e
`bash tests/check-lang.sh` verdes. Passada de sabotagem nas notas.
**Check:** `o=$(bash tests/check-hat.sh 2>&1); grep -c -e '^  ok    hat: the planner marks each grill decision' -e '^  ok    hat: the planner leaves aprovacao empty' -e '^  ok    hat: the planner reads the naming rules' -e '^  ok    command: /sdd-plan re-estimates long work' <<< "$o"` → `4`
**Sensor durável:** os quatro probes.
**Reversível por:** reverter o commit.

### I8 — o carimbo de hora sai de `date`

**O quê:**
- O `turn_rule` (`bin/sdd:3146-3152`) ganha uma linha física própria, inserida **antes** da última
  linha da string (`What you started for your own check, stop before you end the turn."`). O `"` de
  fecho continua nessa última linha, que o mutante não toca: o `RUN_turn_rule_no_clock` apaga só a
  linha nova, e a string continua válida. A linha nova é esta, inteira numa linha física (o probe a
  lê por `grep`, e frase partida em duas linhas não casa), com as crases escapadas como as vizinhas:

  ```text
  Every timestamp you write (a data: or atualizado: field, a note) comes from \`date '+%Y-%m-%d %H:%M'\` run in the same batch of commands, never from a log you read or from memory.
  ```
- O comentário acima cita o L4: `10-ticket.md` às 12:10 com a sessão às 17:03, e `45-docs.md` às
  18:10 com a sessão às 18:02.
- Anatomia § 1: uma frase. ⚠️ `.claude/` é caminho sensível: em sessão interativa o harness pode
  pedir permissão; nunca contorne por Bash.

**Onde:** `bin/sdd` (`boot_prompt`), `tests/check-dry-run.sh` (`:422-452`), `tests/check-mutation.sh`,
`.claude/rules/anatomia-do-agente.md` § 1.
**Como (TDD):** no laço de `:433`, um contador `date_hits` com
`grep -q 'comes from .date' <<< "$ph_prompt"` e a asserção
`assert_eq "every projected phase is told that a timestamp it writes comes from date" "5 5"
"$turn_phases $date_hits"`. Vermelha antes (`5 0`). Mutante `RUN_turn_rule_no_clock`, que apaga a
linha física nova (âncora no texto `never from a log you read`); a string continua válida. Prove com
`--only RUN_turn_rule_no_clock check-dry-run.sh`.
**Check:** `o=$(bash tests/check-dry-run.sh 2>&1); grep -c '^  ok    every projected phase is told that a timestamp it writes comes from date' <<< "$o"` → `1`
**Sensor durável:** a asserção por fase e o mutante.
**Reversível por:** reverter o commit.

### I9 — o K8 do plano contra a DOCS

**O quê:**
- No `gate_DOCS`, entre a checagem de pendentes (`bin/sdd:2183-2190`) e o bloco `⛔` (`:2211`):
  1. Pergunte ao frontmatter se o plano dispensa a entrada (D23). O leitor é o `frontmatter`
     (`bin/sdd:337`), o mesmo que o I1 usa para o `qa: skipped`, e a condição abre o bloco do K8:

     ```bash
     if [ "$(frontmatter "$MISSION_DIR/00-missao.md" kaizen_log)" != skipped ]; then
       # passos 2 e 3; o I12 põe a recusa da base como a primeira linha daqui
     fi
     ```

     **Só a chave diz "não"** (D23). Com o literal `kaizen_log: skipped` no frontmatter, o gate
     segue sem ler o `KAIZEN_LOG.md`; com qualquer outra coisa, cobra a entrada. A linha K8 do
     checklist é prosa para o humano e não é lida: o `✗` dela, sozinho, não dispensa nada. A régua é
     a do leitor, medida nesta sessão sobre o `frontmatter` real (Contexto verificado): `skipped`,
     `skipped` com espaço ou tab no fim e `"skipped"` dispensam; `Skipped`, a chave vazia, o
     placeholder do template, `skipped # nota`, `skipped` seguido de `\r`, a chave ausente, a chave
     no corpo (depois do segundo `---`), uma segunda `kaizen_log:` depois de uma primeira com outro
     valor e um arquivo com fim de linha CRLF (a primeira linha deixa de ser `---`) cobram. O
     comentário nomeia o dono da chave, o `sdd-planner` com o humano na sala, e diz por que ela é
     literal: o "não" é o único lado que falha aberto, como no `qa: skipped` da D2. Uma linha só,
     lida por `$( )`, sem global.

     **Por que o "não" saiu do Markdown** (D23, 16ª rodada do PR #247). O leitor da D19 decidia o
     "não" sobre o texto cru, imitando o Markdown aos pedaços (cerca, título, tabela, delimitadora),
     e cada forma que ele não imitava virava um "não" falso: foi o achado das rodadas 7, 8, 10, 11,
     12, 13 e 16. **Medido** na 16ª com um parser CommonMark de verdade (`markdown-it-py` 3.0.0, o
     preset `commonmark` mais a regra de tabela GFM, por `python3 -I`), nos 13 mundos da asserção 19
     abaixo: o leitor da D19 dizia `no` em 9 onde o parser não renderiza a linha `✗` do template
     como tabela, ou renderiza outro K8 `✅` (a tabela recuada 4 espaços ou por tab, dentro de
     `<!-- -->`, logo depois de `<details>`, continuada depois de `> Nota:`, dentro de um
     `- <!--`, e a linha `✗` real com outra tabela de `**K8**`, de `` `K8` `` ou citada por `>`).
     O conserto que o Codex pediu, o recuo de 0 a 3 espaços sem tab, fechava 2 dos 9. O estado que
     faltava é a estrutura que o Markdown renderiza, e um `awk` que lê byte não a tem; a chave
     literal tira a pergunta do Markdown e usa um leitor exato que já existe. **Raio:** 0 das 64
     missões reais têm uma linha K8 com `✗` ou a chave `kaizen_log` (medido nesta sessão), e nenhum
     arquivo de `tests/` cita `K8` ou `kaizen_log`. Todo fixture lia `none` na D19 e lê "sem a
     chave" agora, e as duas respostas cobram, então o raio medido da D19 vale igual: com ela
     aplicada numa cópia do kit, os seis sensores que criam missões (`check-gates`,
     `check-autonomy`, `check-dry-run`, `check-adr`, `check-kaizen`, `check-coordination`) deram as
     mesmas contagens de `ok` e `FAIL` da cópia sem mudança (439/0, 495/2, 72/0, 81/0, 227/3,
     193/0; os 2 e os 3 `FAIL` são do ambiente da cópia e aparecem nas duas).

     Recusados (D23): ficar no Markdown com o "não" desligado por toda forma que o leitor não
     modela (o recuo, uma abertura de bloco HTML, um `K8` fora da linha do template, o cabeçalho
     sem linha em branco antes), que eram quatro regras novas e um fechamento por enumeração do
     CommonMark sem renderizador no runner; e só o conserto do recuo, com os outros 7 mundos no
     `TODO.md`, que deixava o leitor falhando aberto em mundos medidos. A D19 (só a linha do
     template com `✗` diz "não") e o leitor `k8_promise` saem do plano.
  2. Dentro do `if`, monte `nots` por `mission_base_refs` (o I12 põe, antes disso, a recusa da
     missão cuja `branch:` é a base e cuja chave está presente sem `skipped`). Sem base que
     resolva, ou com range vazio (`git rev-list -n 1 HEAD --not …` vazio), fica a resposta de hoje,
     o molde do `mission_qa_report` (`:1080-1084`).
  3. Com range, ainda dentro do `if`, procure a **entrada** (D16): um bloco do `KAIZEN_LOG.md` cujo
     título e uma linha que
     cita a missão são, os dois, novos na branch. Para **cada** merge-base `b` de HEAD com as bases
     (o `bases` do molde do `mission_qa_report`, `:1069-1074`), leia o diff com o arquivo inteiro de
     contexto, pela plumbing, numa variável:
     `patch="$(git -C "$REPO_ROOT" diff-tree -p --no-color --no-ext-diff -U1000000 "$b" HEAD -- KAIZEN_LOG.md 2>/dev/null || true)"`,
     e entregue-o por herestring (nunca `git … | awk`, a família do `pipefail` do `CLAUDE.md`) a um
     `awk` que reusa a `FENCE_AWK` (`bin/sdd:1550`, a mesma cerca CommonMark dos outros leitores de
     título) e recebe a missão por `ENVIRON` (o I11 troca o `"$MISSION"` abaixo por
     `"$(mission_id "$MISSION")"`, o id sem as barras do argumento), como `bin/sdd:414` e `:1529` (`-v` interpretaria
     barra invertida):

     ```bash
     SDD_K8_MISSION="$MISSION" awk "$FENCE_AWK"'
       function cites_id(s, m,   p, i) {
         s = " " s
         while ((i = index(substr(s, p + 1), m)) > 0) {
           p += i
           if (substr(s, p - 1, 1) !~ /[A-Za-z0-9_-]/ && substr(s, p + length(m), 1) !~ /[A-Za-z0-9_-]/) return 1
         }
         return 0
       }
       BEGIN { m = ENVIRON["SDD_K8_MISSION"] }
       { t = substr($0, 1, 1) }
       t != " " && t != "+" { next }
       { l = substr($0, 2); fence_line(l) }
       !fence && l ~ /^## / { hnew = (t == "+") }
       t == "+" && hnew && cites_id(l, m) { found = 1 }
       END { exit !found }
     ' <<< "$patch"
     ```

     O que cada linha decide, e cada decisão tem mutante (abaixo): só as linhas de HEAD (` ` e `+`)
     entram, e as `-` (só da base) ficam fora, senão um `-## ` apagado entre o título novo e a
     citação nova partiria o bloco; um `## ` fora de cerca abre bloco, e `hnew` é **reatribuído** em
     todo título, novo ou de contexto, senão o "novo" de uma entrada vazaria para a seguinte; a
     citação só conta se a própria linha é `+` e o título do bloco é `+` (um título que cita a missão
     conta como a linha); antes do primeiro `## ` nada conta. O cabeçalho do
     patch não tem regra própria, e não precisa: `diff`, `index`, `---` e `@@` não começam por ` `
     nem `+`, e o `+++ b/KAIZEN_LOG.md` passa pelo filtro mas não abre bloco nem cita a missão (o
     caminho é literal e `hnew` começa em 0). Medido: a variante com um `!body` que pula o cabeçalho
     até o primeiro `@@ ` responde igual em todos os mundos, então ficou fora.

     **Citar é o id inteiro** (`cites_id`, 6ª rodada do PR #247): uma ocorrência de `m` na linha só
     conta quando o byte antes e o byte depois dela ficam fora de `[A-Za-z0-9_-]`, a classe de todo
     id que o runner aceita desde o I11 (D17: `^[0-9]{8}-[a-z0-9-]+$` conferido no
     `resolve_mission`). `$MISSION-extra`, `${MISSION}s`,
     `${MISSION}_old`, `revisita-$MISSION` e `docs/handoffs/$MISSION-extra/` **não** citam a
     missão; `` `$MISSION` ``, `docs/handoffs/$MISSION/…`, `($MISSION)`, `$MISSION.`, o id entre
     espaços, colado num travessão, no fim ou no começo da linha citam. O id é procurado **literal**
     (`index`, string fixa) e o laço anda até a última ocorrência, porque um id mais longo antes da
     citação, na mesma linha, não pode escondê-la. ⚠️ O `s = " " s` é a armadilha do `mawk`
     (Contexto verificado): sem ele, `substr(s, 0, 1)` devolve o primeiro dígito do próprio id, e um
     id na coluna 1 é recusado (falha fechada). Do lado direito não precisa: `substr` além do fim
     devolve `""`. A classe é ASCII, a regra do `CLAUDE.md` para o `mawk`. Recusados: exigir o
     caminho do handoff (`$HANDOFF_DIR/$MISSION/`), que troca o contrato da D15/D16 (citar o id),
     recusaria a forma com crase que o I13 e o `sdd-docs` usam e, sem a `/` final, tem o mesmo furo;
     uma regex montada com o id, que dá a um metacaractere de id futuro o poder de mudar o que casa; e
     normalizar a linha trocando por espaço todo byte fora da classe, que deixa de casar um id que
     tenha um desses bytes (gate insatisfazível para aquela missão), salvo normalizando o id também,
     regra que nenhum mundo do fixture observa.

     Faltando em qualquer merge-base (a direção que falha fechada), o `GATE_WHY` é
     `00-missao.md does not declare kaizen_log: skipped in its frontmatter (the K8 row of the checklist is prose and dispenses nothing) and the mission branch adds no KAIZEN_LOG.md entry of its own — a '## ' heading new in the branch whose block has a new line citing $MISSION as a whole id (a longer id that contains it does not count); write the entry, citing the mission, with the before and after the plan names, or declare kaizen_log: skipped with the human`.
     **Por que o bloco** (D16): o `KAIZEN_LOG.md` da `main` já cita esta missão (a entrada do
     veredito aponta para `docs/handoffs/20261012-a-rota-da-qa/05-verdict.md`), como o de toda
     missão nascida do kaizen, então "ausente na base" reprovaria a entrada dela para sempre; e a
     conta da D15 crescia sem entrada nova. **Medido** num repo descartável (git 2.43.0), com a base
     já citando a missão, cada mundo um commit sobre o início da branch, D15 × D16:

     | Mundo | D15 (contar) | D16 (bloco) |
     |---|---|---|
     | nada acrescentado | reprova | reprova |
     | uma linha trocada numa entrada antiga | reprova | reprova |
     | o `## ` da entrada antiga (que cita a missão) renomeado | reprova | reprova |
     | mais uma linha citando a missão na entrada antiga (Codex, 5ª rodada) | **passa** | reprova |
     | a linha que cita a missão duas vezes partida em duas (Codex, 5ª rodada) | **passa** | reprova |
     | entrada nova sem citar a missão, mais uma citação somada à entrada antiga abaixo | **passa** | reprova |
     | um `## ` dentro de cerca, com uma citação, na entrada antiga | **passa** | reprova |
     | entrada nova citando a missão | passa | passa |
     | entrada nova citando a missão, com faxina de uma linha antiga | passa | passa |
     | entrada nova citando a missão só no título | passa | passa |
     | entrada nova cuja linha de citação é igual a uma linha antiga | passa | passa |
     | entrada nova escrita por cima de um `## ` antigo apagado (o diff põe o `-## ` entre o título novo e a citação nova) | passa | passa |
     | a entrada nova revertida | reprova | reprova |

     **Medido na 6ª rodada** (o mesmo protótipo, git 2.43.0, `mawk` 1.3.4): os treze mundos acima
     dão a mesma fase com o `cites_id`, e os de colisão separam a citação solta da inteira:

     | Mundo | D16 com `index(l, m)` solto | D16 com `cites_id` |
     |---|---|---|
     | entrada nova citando só `$MISSION-extra` (Codex, 6ª rodada) | **passa** | reprova |
     | entrada nova citando só `revisita-$MISSION` | **passa** | reprova |
     | entrada nova citando só `${MISSION}s` | **passa** | reprova |
     | entrada nova citando só `${MISSION}_old` | **passa** | reprova |
     | entrada nova citando só `docs/handoffs/$MISSION-extra/05-verdict.md` | **passa** | reprova |
     | entrada nova citando o id entre crases, num caminho (`/`), entre parênteses, antes de `.`, entre espaços, colado num travessão, no fim e no começo da linha (oito mundos) | passa | passa |
     | as três colisões e, depois delas na mesma linha, `docs/handoffs/$MISSION/01-plano.md` | passa | passa |

     As regras recusadas, e o que cada uma deixava passar: "algum commit tocou o arquivo" (D7), uma
     entrada revertida; "linhas acrescentadas" (D13), a troca de uma linha; "um `+## `
     acrescentado" (D14), o renome de um cabeçalho; "as linhas que citam a missão crescem" (D15), as
     quatro linhas em negrito acima; a citação como substring (`grep -cF` na D15, `index` na D16
     até a 5ª rodada), as cinco linhas em negrito da segunda tabela; "adições menos remoções > 0", nada disso, mas reprovaria a
     missão que escreve a entrada e enxuga o log, sem saída honesta para o dono; um marcador
     `<!-- sdd:kaizen <missão> -->`, rótulo que o modelo escreve, e escrito numa entrada antiga
     passaria num mundo que se distingue (sem título novo).
     Resíduos declarados no comentário:
     - renomear um `## ` antigo e acrescentar uma citação da missão embaixo dele passa. **Não é
       regra frouxa:** o gêmeo honesto (apagar a entrada velha e escrever uma nova que reaproveita
       o texto), construído à parte sobre a mesma base, deixa o `KAIZEN_LOG.md` **idêntico byte a
       byte** (medido, `cmp`), e ele tem de passar. Nenhum leitor de base e HEAD separa os dois;
     - um log cujas entradas não abrem por `## ` reprova com K8 ✅ até o humano decidir; o motivo
       diz o que falta;
     - não medido: uma linha da entrada nova igual byte a byte a uma linha **apagada** noutro ponto
       do log pode sair do diff como contexto, e a entrada reprova (falha fechada);
     - o `-U1000000` limita o contexto a um milhão de linhas (o log tem 3259);
     - o "cada merge-base" não tem mundo próprio no fixture, porque pede duas bases divergentes;
     - um id vazio cita toda linha: no `mawk`, `index(s, "")` vale 1 (Contexto verificado), e o
       laço do `cites_id` acaba aceitando a primeira linha nova. É inalcançável, e o comentário do
       `cites_id` o declara assim: o `resolve_mission` morre com nome vazio (`missing mission
       name`), e desde o I11 com qualquer id fora da gramática, que exige ao menos um caractere
       depois do hífen;
     - a fronteira do id conta um byte ≥ 0x80 e o `.` como fronteira (o `mawk` lê byte; o id no fim
       da frase é forma honesta). Isso só é exato porque o id não pode conter nenhum dos dois: até
       a 6ª rodada era convenção (o CodeRabbit, na 7ª, mostrou a missão `foo` satisfeita por
       `` `foo.bar` `` e `` `fooé` ``, medido com este `cites_id`); desde o I11 é a gramática que o
       `resolve_mission` confere em todo comando (D17). Sobra: um id da gramática seguido de `.` ou de
       letra acentuada conta como citado (`<id>.md` é o caso honesto), e nenhum outro id pode ser
       esse texto.
  4. O comentário nomeia o dono: o `sdd-docs`, com `KAIZEN_LOG.md` no `writes:`.
- `agents/sdd-docs.md` § 3, linha `KAIZEN_LOG.md`: atualize quando a missão mede um antes/depois
  **ou quando o frontmatter do `00-missao.md` não declara `kaizen_log: skipped`** (D23), e o gate
  cobra. `n/a` só com `kaizen_log: skipped`; a linha K8 do checklist não decide nada.
  A entrada **abre com o seu próprio `## `** e **cita o id da missão** (`<YYYYMMDD>-<slug>`) numa
  linha dela, inteiro (um id mais longo que o contém, como `<id>-r2`, não conta); citar a missão
  numa entrada que já existe não conta.
- `templates/missao.md`, o contrato da chave (D23), no mesmo commit:
  - no frontmatter, logo depois do `qa:` do I2, a linha
    `kaizen_log: <vazio, ou skipped quando o K8 é ✗ com o humano — só o literal skipped dispensa a entrada do KAIZEN_LOG.md>`.
    O placeholder não é o literal, então um plano que o copia promete a entrada (medido: o
    `frontmatter` devolve o placeholder inteiro, e o `frontmatter_has` diz que a chave existe, que
    é o que o I12 lê);
  - em `## Checklist kaizen`, entre o título e a tabela, uma linha em branco e
    `> O K8 desta tabela é prosa: quem dispensa a entrada do KAIZEN_LOG.md é só o literal kaizen_log: skipped no frontmatter, decidido com o humano no grill.`
    seguida de outra linha em branco. A tabela não muda.
- `tests/check-templates.sh:336`: `kaizen_log` entra na lista de chaves, depois do `qa` do I2, e
  imprime `missao.md: frontmatter key 'kaizen_log'`.
- `docs/pipeline.md` § DOCS: a condição nova. Anatomia § 4: uma frase.
- `./bin/sdd install --force`.

**Onde:** `bin/sdd` (`gate_DOCS`), `agents/sdd-docs.md`, `templates/missao.md`, `docs/pipeline.md`,
a anatomia, `tests/check-gates.sh`, `tests/check-hat.sh`, `tests/check-templates.sh`,
`tests/check-mutation.sh`.
**Como (TDD):** no bloco da DOCS do `check-gates.sh`, logo depois de `:2753` (`assert_phase "drift
checklist complete" "PR"`, o primeiro ponto em que a DOCS passa). Antes de cortar a branch, a `main`
do fixture ganha um `KAIZEN_LOG.md` com uma entrada antiga que já cita `$MISSION`, a forma de toda
missão nascida do kaizen, **duas vezes na mesma linha** (o mundo 5 precisa) e com uma linha que não
cita (os mundos 2 e 4 a usam):

```text
# KAIZEN_LOG

---

## 2026-01-01 — O veredito

Veredito em `docs/handoffs/$MISSION/05-verdict.md`; plano em `docs/handoffs/$MISSION/01-plano.md`.
Outra linha do veredito.

---
```

Corte uma branch de missão (molde `:1318-1326`). No `$MDIR/00-missao.md` (que hoje não tem seção
nenhuma, Contexto verificado), troque `branch: main` pelo nome dessa branch e acrescente a seção do
checklist, como o template a escreve (a linha K8 é prosa; nenhuma `kaizen_log:` no frontmatter):

```text

## Checklist kaizen (`kaizen-software`)

| # | Item | Status | Nota |
|---|---|---|---|
| K8 | Registro no KAIZEN_LOG | ✅ | |
```

⚠️ **Troque o `branch:`.** O fixture diz `branch: main` (`:144-151`), e o molde de branch de
missão não o muda. Com o I12 no lugar, uma missão que diz `branch: main` e tem a chave presente sem
`skipped` é recusada pela base **antes** da âncora: os mundos 14, 15 e 18 abaixo dariam `DOCS` pelo
motivo errado, e a sabotagem da âncora não os mudaria. Medido no protótipo: com `branch: main`, o
motivo desses três é o `names the base branch` do I12. (O plano da D19 tinha a mesma colisão, maior:
todo mundo com o checklist `✅` dizia `yes`, e com `branch: main` os mundos que esperam `PR`, como o
8 e o 10, dariam `DOCS` depois do I12; nenhum protótipo anterior tinha o `branch:` no fixture.)

Commite e guarde `k8_start="$(git rev-parse HEAD)"`. Dezenove asserções com o prefixo exato
`kaizen-log: `, nesta ordem. Os mundos 1–10 e 13–19 são **independentes**: cada um é um commit
sobre `k8_start` e volta com `git reset -q --hard "$k8_start"` (o molde de `:1349`); os 11–12 são
uma sequência, e o 13 começa com esse reset. Os mundos 1–12 mexem só no `KAIZEN_LOG.md`, e os
13–19 só no `00-missao.md`, com o `KAIZEN_LOG.md` de `k8_start` (nenhuma entrada nova: cobrar dá
`DOCS`, dispensar dá `PR`). ⚠️ Não os acumule: o mundo 3 (renome) seguido do 4 (citação na mesma
entrada) é o resíduo declarado, e a fase passaria. Os dezenove mundos, com estes textos e esta base,
foram rodados no protótipo contra a regra e contra cada mutante (a fase esperada em todos;
2026-10-14, 16ª rodada).
1. `kaizen-log: a base that already cites the mission is not the entry`: nada acrescentado → `DOCS`.
   Junto, um `assert_why` **sem** o prefixo (não entra na conta do Check), `K8 names the missing
   KAIZEN_LOG entry`, com a regex `adds no KAIZEN_LOG.md entry of its own`;
2. `kaizen-log: a one-line edit with no new entry keeps DOCS blocked`: `Outra linha do veredito.`
   reescrita → `DOCS`;
3. `kaizen-log: renaming an old heading is not a new entry`: o `## 2026-01-01 — O veredito`
   renomeado (o mundo do Codex na 4ª rodada) → `DOCS`;
4. `kaizen-log: another line citing the mission in an old entry is not a new entry`: uma linha nova
   `` Ver também `$MISSION`. `` depois de `Outra linha do veredito.` (Codex, 5ª rodada) → `DOCS`;
5. `kaizen-log: splitting an old line that cites the mission twice is not a new entry`: a linha das
   duas citações partida no `; ` (Codex, 5ª rodada) → `DOCS`;
6. `kaizen-log: a new entry that does not cite the mission keeps DOCS blocked`: um `## 2026-01-02 —
   Lote` novo, acima da entrada antiga e sem citar a missão, **mais** a linha `` Ver também
   `$MISSION`. `` somada à entrada antiga abaixo dele → `DOCS`;
7. `kaizen-log: a heading inside a code fence is not an entry`: a entrada antiga ganha, depois de
   `Outra linha do veredito.`, um bloco cercado por três crases com `## 2026-01-02 — exemplo` e
   `` Ver `$MISSION`. `` dentro → `DOCS`;
8. `kaizen-log: a new entry written over a deleted old heading lets DOCS pass`: `## 2026-01-02 —
   Lote` e uma linha em branco **acima** do primeiro `---`, a linha `## 2026-01-01 — O veredito` e a
   linha em branco seguinte apagadas, e `` Missão `$MISSION`: antes 1, depois 2. `` depois de
   `Outra linha do veredito.` → `PR`. O diff de contexto inteiro sai ` # KAIZEN_LOG`, ` `, `----`,
   `+## 2026-01-02 — Lote`, ` `, `-## 2026-01-01 — O veredito`, `+---`, …, `+Missão …` (medido): o
   `-## ` cai entre o título novo e a citação nova;
9. `kaizen-log: a new entry citing only longer ids that contain the mission keeps DOCS blocked`: um
   `## 2026-01-02 — Lote` novo, logo abaixo do primeiro `---`, com a linha
   `` Ver `$MISSION-extra`, `${MISSION}s` e `revisita-$MISSION`. `` (o mundo do Codex na 6ª rodada,
   mais um vizinho letra à direita e um vizinho `-` à esquerda: cada sabotagem da fronteira precisa
   de um deles) → `DOCS`;
10. `kaizen-log: the same entry citing the mission itself after the longer ids lets DOCS pass`: o
    mundo 9 com `; plano em docs/handoffs/$MISSION/01-plano.md` antes do ponto final → `PR`. É o
    gêmeo diferencial do 9: só a citação inteira os separa, e ela vem **depois** das três colisões
    na mesma linha;
11. `kaizen-log: a new entry that cites the mission lets DOCS pass`: `## 2026-01-02 — Lote` novo, logo
    abaixo do primeiro `---`, com `$MISSION: antes 1, depois 2.` no corpo → `PR`. O id fica **na
    coluna 1 e sem crase**: é o mundo da armadilha do `mawk` (`substr(s, 0, 1)`). O I11 acrescenta
    aqui, com o mundo no lugar, uma asserção sua (`mission-id: `, fora da conta deste Check);
12. `kaizen-log: an entry written and then reverted in the mission branch holds DOCS`: sobre o 11,
    `git revert --no-edit HEAD` (sem `-q`, que o git 2.43 não aceita) → `DOCS`;
13. `kaizen-log: kaizen_log: skipped in the frontmatter dispenses the entry`: de volta a `k8_start`,
    a linha `kaizen_log: skipped` logo abaixo do `branch:` e a linha K8 do checklist com `✗` no lugar
    do `✅` → `PR`. É o gêmeo diferencial do primeiro mundo da asserção 19 (a mesma linha `✗`, sem a
    chave): só a chave os separa;
14. `kaizen-log: a misspelt kaizen_log: Skipped demands the entry`: `kaizen_log: Skipped` → `DOCS`;
15. `kaizen-log: an empty kaizen_log demands the entry`: `kaizen_log:` sem valor → `DOCS` (a chave
    existe, o valor é vazio: o `frontmatter` devolve vazio para os dois casos, e os dois cobram);
16. `kaizen-log: kaizen_log: skipped in the body is not the frontmatter`: a linha `kaizen_log: skipped`
    depois do `# Mission`, fora do frontmatter → `DOCS`;
17. `kaizen-log: a trailing space after skipped is trimmed like any frontmatter value`:
    `kaizen_log: skipped ` (um espaço no fim) → `PR`. É a régua do leitor, a mesma do `qa:`;
18. `kaizen-log: a trailing carriage return after skipped demands the entry`: `kaizen_log: skipped`
    seguido de `\r` (`printf 'kaizen_log: skipped\r\n'`) → `DOCS`. O `frontmatter` apara espaço e
    tab, não o `\r`;
19. `kaizen-log: no Markdown form of K8 in the checklist dispenses the entry without the key`: um
    `assert_eq` só, sobre um laço de 13 mundos. Cada um parte de `k8_start` (sem a chave), edita só o
    `00-missao.md`, commita, lê `"$SDD" phase "$MISSION"` e volta com o reset. O laço conta os
    mundos construídos (cada construtor confere por `grep -qF` que a sua linha marcante entrou, ou
    não conta) e os que deram `DOCS`, e guarda o nome dos que não deram:
    `assert_eq "kaizen-log: no Markdown form of K8 in the checklist dispenses the entry without the key" "13 13 -" "$built $docs ${missed:--}"`.
    Nas receitas abaixo, "apague a real" é apagar a linha `| K8 | Registro no KAIZEN_LOG | ✅ | |`
    (antes de acrescentar qualquer linha, que pode ser igual a ela), "a real com `✗`" é trocar o
    `✅` dela por `✗`, e **T** são as três linhas `| # | Item | Status | Nota |`,
    `|---|---|---|---|` e `| K8 | Registro no KAIZEN_LOG | ✗ | |`. Cada "acrescente" vai para o
    fim do arquivo, e a primeira linha acrescentada é sempre uma linha em branco:
    1. `template-x`: a real com `✗`;
    2. `indent-3`: apague a real; acrescente `Exemplo:`, uma linha em branco e T, cada linha
       recuada 3 espaços;
    3. `indent-4`: o mesmo, com 4 espaços;
    4. `indent-tab`: o mesmo, com um tab;
    5. `para-glued`: apague a real; acrescente `Exemplo:` e T, sem linha em branco entre eles;
    6. `list-table`: apague a real; acrescente `- item`, uma linha em branco e T recuada 2 espaços;
    7. `html-comment`: apague a real; acrescente `Exemplo:`, uma linha em branco, `<!--`, T e `-->`;
    8. `html-details`: apague a real; acrescente `<details>`, T e `</details>`;
    9. `lazy-quote`: apague a real; acrescente `> Nota:` e T, sem linha em branco;
    10. `list-html`: apague a real; acrescente `- <!--`, T recuada 2 espaços e `  -->`;
    11. `bold-k8`: a real com `✗`; acrescente o cabeçalho, a delimitadora e
        `| **K8** | exemplo | ✅ | |`;
    12. `code-k8`: o mesmo, com `` | `K8` | exemplo | ✅ | | ``;
    13. `quote-k8`: a real com `✗`; acrescente `> | # | Item | Status | Nota |`,
        `> |---|---|---|---|` e `> | K8 | exemplo | ✅ | |`.

    Os 13 são os da 16ª rodada (D23). Num parser CommonMark de verdade (`markdown-it-py` 3.0.0,
    Contexto verificado), os mundos 1, 2, 5 e 6 renderizam a linha `✗` do template numa tabela, e
    os outros nove não a renderizam ou renderizam outro K8 `✅`; o leitor da D19 dizia `no` nos 13.
    Sem a chave, todos cobram, e o laço afirma isso: a tabela do checklist não decide mais nada.

Volte à `main` e restaure o fixture. Um probe em `hat_promise_probes` lê o `sdd-docs.md` § 3: exige
`kaizen_log: skipped` na linha do `KAIZEN_LOG.md`, a instrução de abrir a entrada com o seu próprio
`## ` e a de citar o id da missão, e imprime
`hat: the docs hat reads kaizen_log of the plan before it marks KAIZEN_LOG`. Treze mutantes,
provados por `--only <slug> check-gates.sh`, sabotados no protótipo sobre a base deste fixture, e
cada um mudou a fase exatamente nos mundos indicados:
- `DOCS_k8_ignored` neutraliza o `if` novo → mundos 1–7, 9, 12, 14, 15, 16, 18 e 19;
- `DOCS_k8_presence_is_enough` troca `"$b"` pela árvore vazia
  (`4b825dc642cb6eb9a060e54bf8d69288fbee4904`) no `diff-tree`, e toda linha vira nova → mundos 1–7,
  9, 12, 14, 15, 16, 18 e 19;
- `DOCS_k8_reads_deleted_lines` deixa as linhas `-` entrarem (`t != " " && t != "+" && t != "-"
  { next }`) → só o mundo 8;
- `DOCS_k8_heading_not_new` tira `hnew &&` da condição da citação → mundos 4–7;
- `DOCS_k8_cite_not_new` tira `t == "+" &&` da condição da citação → só o mundo 3;
- `DOCS_k8_block_not_reset` troca a reatribuição por `!fence && l ~ /^## / && t == "+" { hnew = 1 }`
  → só o mundo 6;
- `DOCS_k8_fence_blind` tira `!fence &&` do teste de título → só o mundo 7;
- `DOCS_k8_cite_no_left_boundary` apaga `substr(s, p - 1, 1) !~ /[A-Za-z0-9_-]/ && ` do `cites_id`
  → só o mundo 9 (o `revisita-$MISSION`);
- `DOCS_k8_cite_no_right_boundary` apaga ` && substr(s, p + length(m), 1) !~ /[A-Za-z0-9_-]/` →
  só o mundo 9 (o `$MISSION-extra` e o `${MISSION}s`);
- `DOCS_k8_cite_first_only` troca o `while ((i` por `if ((i`, e só a primeira ocorrência conta →
  só o mundo 10;
- `DOCS_k8_cite_unpadded` apaga a linha `s = " " s` → só o mundo 11 (e a asserção do I11 no mesmo
  mundo);
- `DOCS_k8_key_ignored` troca `!= skipped ]; then` por `!= skipped ] || true; then`, e a chave
  nunca dispensa → mundos 13 e 17;
- `DOCS_k8_key_loose` troca `!= skipped ]; then` por `= "" ]; then`, e qualquer valor não vazio
  dispensa (o molde do `QA_substep_skipped_loose`) → mundos 14 e 18.
Os mundos 15, 16 e 17 seguram a régua do leitor e não têm mutante próprio, como o I1. Medido no
protótipo: trocar o teste do valor por `frontmatter_has` (a chave presente dispensa) faz o 15 dar
`PR` (e o 14 e o 18); trocar o `frontmatter` por um `sed` no arquivo inteiro faz o 16 dar `PR` e o
17 dar `DOCS`. A classe do `cites_id` não tem mutante próprio, e o mundo 9 é
o que a segura: no protótipo, a classe reduzida a `[-]` e a classe sem o `-` deixaram o mundo 9 em
`PR` (por isso ele leva um vizinho letra e um vizinho `-`); a classe alargada com `.` e `/` (aperto,
falha fechada) deixou o 10 em `DOCS`.
**Check:** `a=$(bash tests/check-gates.sh 2>&1); b=$(bash tests/check-hat.sh 2>&1); c=$(bash tests/check-templates.sh 2>&1); x=$(grep -c '^  ok    kaizen-log: ' <<< "$a"); y=$(grep -c '^  ok    hat: the docs hat reads kaizen_log of the plan' <<< "$b"); z=$(grep -c "^  ok    missao.md: frontmatter key 'kaizen_log'" <<< "$c"); echo "$x $y $z"` → `19 1 1`
**Sensor durável:** as dezenove asserções, o `assert_why`, a chave no `check-templates.sh`, o probe e os treze mutantes.
**Reversível por:** reverter o commit.

### I10 — onde vai o `RESOLVED by` num item no teto

**O quê:** `templates/todo.pt-BR.md` e `templates/todo.md`, § Ciclo de vida / Lifecycle (`:32-36`),
logo depois de "o corpo ganha `RESOLVED by <hash>`".
- **pt-BR.** O token vai no fim da última linha do corpo, ou dentro da linha `Fonte:` antes do
  `— descoberto por`; **nunca numa linha própria**, que num item no teto vira a 9ª linha
  (`9 content lines, cap is 8`), nem depois do descoberto-por, que tem de ser o último campo. Sem
  espaço nos 120 caracteres, encurte o corpo.
- **Inglês.** A mesma regra, com **"never on a line of its own"** e `Source:` / `found by`.

As quatro posições foram medidas nesta sessão (Contexto verificado).
**Onde:** os dois templates.
**Como (TDD):** o Check é 0 hoje. Depois, `bash tests/check-templates.sh` (o `todo_shape` compara o
esqueleto das variantes; prosa é livre) e `bash tests/check-todo.sh --check TODO.md` verdes.
**Check:** `o=$(cat templates/todo.pt-BR.md templates/todo.md); grep -c -e 'nunca numa linha própria' -e 'never on a line of its own' <<< "$o"` → `2`
**Sensor durável:** o `check-todo.sh` já reprova as duas posições erradas e aceita as duas certas
(medido); a frase diz qual passa. O Check é de presença porque é o texto que se acrescenta.
**Reversível por:** reverter o commit.

### I11 — a gramática do id da missão (D17)

**O quê:** o id da missão deixa de ser convenção e vira fato do runner. É o que torna exata a
fronteira do `cites_id` do I9: o CodeRabbit (PR #247, 7ª rodada) mostrou, e o protótipo mediu com o
`cites_id` do plano, que a missão `foo` era satisfeita por uma entrada citando só `` `foo.bar` `` ou
`` `fooé` ``.
- `bin/sdd`, junto de `resolve_mission` (`:306-325`):
  - `MISSION_ID_RE='^[0123456789]{8}-[abcdefghijklmnopqrstuvwxyz0123456789-]+$'`, uma definição. O
    comentário diz a gramática legível (`^[0-9]{8}-[a-z0-9-]+$`: oito dígitos, hífen, e o slug em
    letras ASCII minúsculas, dígitos e hífens) e por que a classe é **enumerada**: sob
    `pt_BR.UTF-8` o `=~` do bash 5.2 faz `[a-z]` casar `é` (Contexto verificado).
  - `mission_id <nome>`: imprime o nome sem as `/` das pontas (dois laços `while` de `${id#/}` e
    `${id%/}`). É lida como `$( )` e não toca global nenhuma.
  - Em `resolve_mission`, depois de `MISSION` resolvido nos dois ramos e antes de `MISSION_DIR`:
    `[[ "$(mission_id "$MISSION")" =~ $MISSION_ID_RE ]] || die "mission '$MISSION' is not <YYYYMMDD>-<slug> (^[0-9]{8}-[a-z0-9-]+\$: eight digits, a hyphen, then lower-case ASCII letters, digits and hyphens) — rename $HANDOFF_DIR/$MISSION"`.
    O `MISSION` continua **literal**: o `/<missão>` é o mundo que mantém vivo o
    `RUN_branch_double_slash` (Contexto verificado), então a checagem lê o id sem barras e não
    reescreve nada.
  - No `gate_DOCS`, a âncora do I9 passa `SDD_K8_MISSION="$(mission_id "$MISSION")"`, e o
    `cites_id` procura o id, nunca o argumento com barra.
  - O `cmd_kaizen` não muda: ele não chama o `resolve_mission` e cunha um id da gramática.
- `agents/sdd-planner.md` (a tabela dos quatro arquivos, que diz `docs/handoffs/<YYYYMMDD>-<slug>/`)
  e `commands/sdd-plan.md` (onde o `<slug>` aparece): uma frase em cada, com o literal
  `^[0-9]{8}-[a-z0-9-]+$`, dizendo que o runner recusa qualquer outro nome de missão.
- `docs/pipeline.md`: a mesma frase onde o pipeline nomeia o diretório da missão.
- `./bin/sdd install --force` (mudou um `agents/*.md`).

**Onde:** `bin/sdd`, `agents/sdd-planner.md`, `commands/sdd-plan.md`, `docs/pipeline.md`,
`tests/check-gates.sh`, `tests/check-hat.sh`, `tests/check-mutation.sh`.
**Como (TDD):** cinco asserções com o prefixo exato `mission-id: ` no `check-gates.sh`. As quatro
primeiras ficam logo depois de `assert_eq "a misspelt status option is refused, never read as a
mission name"` (`:5926-5929`), cada uma com o seu diretório criado em `$FIX/docs/handoffs/` e
apagado depois:
1. `mission-id: an id with a dot is refused by name`: `mkdir` de `$MISSION.v2`;
   `"$SDD" status "$MISSION.v2" --no-gates` sai com rc ≠ 0 e a saída tem
   `is not <YYYYMMDD>-<slug>` (`grep -F`);
2. `mission-id: an id with a non-ASCII letter is refused where [a-z] reaches it`: `mkdir` de
   `${MISSION}é`. Antes de concluir, prove que o veneno está **armado**: percorra `locale -a` e
   escolha o primeiro locale `L` em que `LC_ALL=$L bash -c '[[ é =~ ^[a-z]$ ]]'` sai 0 (aqui,
   `pt_BR.utf8`); rode `LC_ALL="$L" "$SDD" status "${MISSION}é" --no-gates` e exija a mesma recusa.
   Sem locale que arme, rode a recusa no locale corrente e diga no texto do `ok` que o veneno não
   armou (limite declarado, a régua dos pares do `CDPATH` do `CLAUDE.md`);
3. `mission-id: an id with a prefix before the date is refused`: `mkdir` de `sq$MISSION`, a mesma
   recusa;
4. `mission-id: a slash after the mission argument still resolves`:
   `"$SDD" status "$MISSION/" --no-gates` sai com rc 0 e nomeia `$MISSION`.

A quinta fica no bloco do I9, logo depois do mundo 11 (a entrada nova citando a missão), com o
mundo no lugar:
5. `mission-id: a slash before the mission argument still finds the K8 entry`:
   `assert_eq "mission-id: a slash before the mission argument still finds the K8 entry" PR "$(cd "$FIX" && "$SDD" phase "/$MISSION" 2>&1)"`.
   Vermelha antes do I11: com o `MISSION` cru, o `cites_id` procura `/$MISSION` e a fase fica em
   `DOCS`. Medido nas duas metades: sem a âncora do K8, `phase "/$MISSION"` e `phase "$MISSION/"`
   dão `PR` como `phase "$MISSION"` no fixture real do `check-gates.sh` (uma cópia do kit com um
   probe depois de `:2753`, 130 s, 0 FAIL), então nenhum outro gate tropeça na barra; no protótipo,
   o `cites_id` com `/$MISSION` dá `DOCS`.

O probe que já existe para o `/<missão>` (`run "/$PM"`, `:4663`) continua verde. Um probe em
`hat_promise_probes` do `check-hat.sh` lê o `agents/sdd-planner.md` e o `commands/sdd-plan.md`,
exige o literal `^[0-9]{8}-[a-z0-9-]+$` nos dois, e imprime
`hat: the planner names the mission id grammar`. Três mutantes, provados por
`--only <slug> check-gates.sh`:
- `RUN_mission_id_unchecked` apaga a linha `[[ … =~ $MISSION_ID_RE ]] || die …` → asserções 1, 2 e 3;
- `RUN_mission_id_slashes_kept` apaga os dois laços de `mission_id` → asserções 4 e 5, e o probe do
  `run "/$PM"`;
- `DOCS_k8_mission_arg_raw` troca `"$(mission_id "$MISSION")"` por `"$MISSION"` na âncora do K8 →
  só a asserção 5.
Sabotagem medida no protótipo e sem mutante no catálogo: a regex com faixas (`[0-9]`, `[a-z]`) deixa
passar o `é` da asserção 2 sob o locale armado; sem o `^`, passa o `sq…` da 3; sem o `$`, e com o
`.` na classe, passa o `.v2` da 1.
**Check:** `a=$(bash tests/check-gates.sh 2>&1); b=$(bash tests/check-hat.sh 2>&1); x=$(grep -c '^  ok    mission-id: ' <<< "$a"); y=$(grep -c '^  ok    hat: the planner names the mission id grammar' <<< "$b"); echo "$x $y"` → `5 1`
**Sensor durável:** as cinco asserções, o probe e os três mutantes.
**Reversível por:** reverter o commit.

### I12 — a missão na base não promete o K8 (D20, adaptada pela D23)

**O quê:** uma missão cuja `branch:` é a base commita na base, e o range da âncora do K8 fica vazio
por construção, o mesmo vazio de uma missão mergeada (Codex, PR #247, 11ª rodada). A recusa mora
onde o humano está, como a do `adr:`. Desde a D23 ela lê a chave, não a tabela.
- `bin/sdd`, logo acima do `gate_DOCS`, uma definição com dois leitores:

  ```bash
  k8_base_refusal() {
    local m="$MISSION_DIR/00-missao.md"
    [ "$(frontmatter "$m" branch)" = "$DEFAULT_BRANCH" ] || return 0
    frontmatter_has "$m" kaizen_log || return 0
    [ "$(frontmatter "$m" kaizen_log)" != skipped ] || return 0
    printf '%s\n' "00-missao.md names the base branch ($DEFAULT_BRANCH) in branch: and carries kaizen_log: without skipped, so it promises a KAIZEN_LOG entry: on the base branch there is no range to read the entry in — give the mission its own branch, or write kaizen_log: skipped with the human"
  }
  ```

  Ela é lida por `$( )` e não toca global. O `frontmatter_has` (`bin/sdd:371`) é a pergunta "a
  chave existe?", feita pelo próprio `frontmatter` com um sentinela, então os dois leitores nunca
  discordam.
- No `gate_PLAN`, depois do `adr_gate_verdict plan || return 1` (`:1208`) e antes de contar as
  linhas do checkpoint: `why="$(k8_base_refusal)"; [ -z "$why" ] || { GATE_WHY="$why"; return 1; }`.
  O comentário nomeia o dono: o `sdd-planner`, com o humano na sala.
- No `gate_DOCS`, como a primeira linha dentro do `if` do I9 (antes do `mission_base_refs`), a mesma
  linha: é o reforço para o `--phase` forçado, que pula a derivação e com ela o `gate_PLAN` (o mesmo
  argumento da D17).
- O comentário declara o resíduo. Na base, só a chave **presente** sem `skipped` é recusada (vazia,
  o placeholder do template, `Skipped`, `skipped # nota`, com `\r`): um plano sem a chave passa, e a
  sua entrada não é lida, porque não há range e não há promessa escrita. É o `none` da D20 com
  outro leitor: todo plano escrito pelo template novo carrega a chave, e os fixtures e as missões
  anteriores não. 0 de 64 missões reais têm a chave (Contexto verificado).
- `agents/sdd-planner.md`:
  - § 3, junto do K8 do checklist kaizen: "K8 ✗ is decided with the human and written as
    `kaizen_log: skipped` in the frontmatter of `00-missao.md`; the K8 row alone dispenses nothing,
    and without the key `gate_DOCS` demands a `KAIZEN_LOG.md` entry citing the mission."
  - § 8, no item "a real branch name" (`:225-230`), a frase sobre nomear a base passa a dizer:
    "Naming the base branch itself (`main`) is a decision too, and passes, unless `00-missao.md`
    carries `kaizen_log:` with anything but `skipped` (the template ships it): on the base branch
    there is no range to read the KAIZEN_LOG entry in, so `gate_PLAN` refuses that pair; write
    `kaizen_log: skipped` with the human, or give the mission its own branch."
- `docs/pipeline.md` § PLAN, "Passes when" (`:147`): a mesma condição, numa frase.
- `./bin/sdd install --force` (mudou um `agents/*.md`).

**Por que a chave presente, e não toda missão sem `skipped`** (D20, reaberta pela medição dos
fixtures, e adaptada pela D23): a primeira forma da D20 recusava toda missão na base que não
dispensasse a entrada. **Medido** (com o leitor da D19) numa cópia do kit (repositório git), contra
a mesma cópia sem mudança, nos seis sensores que criam missões:

| Sensor | Base (ok / FAIL) | D20 contra toda promessa | D20 só contra a promessa escrita |
|---|---|---|---|
| `check-gates` | 439 / 0 | 231 / 208 | 439 / 0 |
| `check-autonomy` | 495 / 2 | 296 / 201 | 495 / 2 |
| `check-dry-run` | 72 / 0 | 38 / 34 | 72 / 0 |
| `check-adr` | 81 / 0 | 74 / 7 | 81 / 0 |
| `check-kaizen` | 227 / 3 | 219 / 11 | 227 / 3 |
| `check-coordination` | 193 / 0 | 167 / 0 (rc 1) | 193 / 0 |

A primeira forma recusou 556 vezes no `gate_PLAN` e 41 no `gate_DOCS`, em 12 missões de fixture
(seis no `check-gates`, duas no `check-adr`, uma em cada um dos outros), todas na `main` com
`branch: main` e sem checklist. Os 2 e os 3 `FAIL` da base são do ambiente da cópia e aparecem nas
três colunas. Com a D23 o conjunto é o mesmo: nenhum fixture tem a chave nem uma linha K8
(`grep -rn 'K8\|kaizen_log' tests/` vazio, nesta sessão), então "sem a chave" recusa exatamente as
12 que "sem `✗`" recusava, e "só a chave presente" não recusa nenhuma, como "só o `yes`". Recusados:
a primeira forma, com a chave nos 12 fixtures, que acoplaria a suíte inteira ao K8; e tirar os
fixtures da base, que é o mundo em que o `ensure_mission_branch` não faz nada.

**Onde:** `bin/sdd` (`gate_PLAN`, `gate_DOCS`), `agents/sdd-planner.md`, `docs/pipeline.md`,
`tests/check-gates.sh`, `tests/check-hat.sh`, `tests/check-mutation.sh`.
**Como (TDD):** três asserções com o prefixo exato `base-branch: ` no `check-gates.sh`, logo depois
de `assert_phase "drift checklist complete" "PR"` (`:2753`) e **antes** do bloco do I9, que corta a
branch de missão. Nesse ponto o fixture está na `main`, com `branch: main`, `DEFAULT_BRANCH="main"`
e sem a chave, e passa: é o resíduo declarado, que o resto da suíte já exercita.
1. Acrescente ao frontmatter do `$MDIR/00-missao.md`, sem commitar, a linha `kaizen_log:` sem valor,
   logo abaixo do `branch: main`:
   `base-branch: a mission on the base branch that promises the KAIZEN_LOG entry is held at PLAN` →
   `PLAN`;
2. `base-branch: a forced DOCS on that mission is refused too`: `assert_why` com a fase `DOCS` e a
   regex `names the base branch` (o `sdd why <missão> DOCS` lê o `gate_DOCS` direto, sem derivar,
   que é o caminho do `--phase` forçado);
3. troque a linha por `kaizen_log: skipped`: `base-branch: the same mission with kaizen_log: skipped
   goes on` → `PR`.
Restaure com `git checkout -- "$MDIR/00-missao.md"`. Um probe em `hat_promise_probes` do
`check-hat.sh` exige, no `agents/sdd-planner.md`, `kaizen_log: skipped` na § 3 e na frase da § 8
sobre nomear a base, e imprime `hat: the planner knows a mission on the base branch cannot promise
K8` (o nome fica: a promessa do K8 é a entrada). Três mutantes, provados por
`--only <slug> check-gates.sh`:
- `PLAN_base_branch_k8_ignored` apaga a linha do `k8_base_refusal` no `gate_PLAN` → a asserção 1;
- `DOCS_base_branch_k8_ignored` apaga a do `gate_DOCS` → a asserção 2;
- `PLAN_base_branch_refuses_silence` apaga a linha `frontmatter_has "$m" kaizen_log || return 0`, e
  a missão sem a chave passa a ser recusada → a suíte inteira (a primeira forma da D20, medida
  acima).
Medido no protótipo, com a função extraída deste plano e o `frontmatter`/`frontmatter_has` reais:
na base, a chave vazia, `Skipped`, o placeholder e `skipped` com `\r` recusam; `skipped`, a chave
ausente e a chave no corpo passam; numa branch própria, nada recusa; e o mutante
`refuses_silence` recusa a chave ausente.
**Check:** `a=$(bash tests/check-gates.sh 2>&1); b=$(bash tests/check-hat.sh 2>&1); x=$(grep -c '^  ok    base-branch: ' <<< "$a"); y=$(grep -c '^  ok    hat: the planner knows a mission on the base branch cannot promise K8' <<< "$b"); echo "$x $y"` → `3 1`
**Sensor durável:** as três asserções, o probe e os três mutantes.
**Reversível por:** reverter o commit.

### I13 — fecho

**O quê:**
- `CONTEXT.md`: um verbete "Rota da QA" (a linha da tabela abre com `| **Rota da QA** |`, o formato
  dos verbetes), com as duas perguntas novas do `qa_substep`, o helper com
  dois leitores, o frescor, e por que o `skipped` não mudou gate nenhum. O verbete "Janela de
  medição" registra o congelamento da D11: o kit congela no merge do lote 7, e a janela abre no
  primeiro carimbo de alvo depois dele.
- `.claude/rules/anatomia-do-agente.md` § 7 (o aceite renderizado, `aprovacao:` vazio sob
  `/sdd-plan`, a contagem das linhas `- answer:` pelo leitor da D22, escrita com o token literal
  `(recommended)`, como no `N (recommended) of M` do aceite). ⚠️ `.claude/` é caminho sensível: em sessão interativa o harness pode
  pedir permissão; nunca contorne por Bash.
- A gaveta (`docs/superpowers/specs/2026-09-23-a-gaveta-do-kit.md`): a linha F3 e o § F3 "Hoje"
  registram o congelamento da D11 com a frase **O kit congelou no merge do lote 7** (o molde é o do
  lote 6, `54e2f18`, que escreveu "O kit congelou no merge do lote 6"), e a F6 registra que a C2 do
  caderno tem a resposta do D2.
- ADR 0018: `Status: accepted`.
- `./bin/sdd install --force`, `./bin/sdd adr check` (rc 0), e
  `env -u CLAUDECODE ./bin/sdd preflight` sem `agent … stale`.
- A entrada `## <data> — Lote 7: a rota da QA e o aceite que lê o plano` no `KAIZEN_LOG.md`:
  - a entrada abre com o seu próprio `## ` e **cita o id da missão** (`20261012-a-rota-da-qa`) numa
    linha dela, que é o bloco que a âncora do I9 procura (D16);
  - **antes**, o veredito ao lado: 3 de 5 missões com QA à mão, 3 de 5 intervenções, reteste
    improvisado em duas missões (cinco vezes), dois carimbos com até 5 h de erro, a entrada do
    `KAIZEN_LOG` escrita à mão;
  - **depois**, M1–M6, M8 e M9 medidos (as linhas `ok` dos Checks);
  - **M7**, declarada como a medida da próxima janela.
- O `20-handoff-exec.md` da missão, pelo `templates/handoff.md`, com a verificação citando a
  última linha de cada comando de fecho: `tests/run-all.sh` inteiro verde,
  `tests/check-mutation.sh --anchors` (`all N mutants still apply`), `./bin/sdd adr check` (rc 0),
  `env -u CLAUDECODE ./bin/sdd preflight` sem `agent … stale`, e o `./bin/sdd install --force`.

**Onde:** os arquivos acima.
**Check:** `a=$(grep -c -E '^## .*Lote 7: a rota da QA' KAIZEN_LOG.md); b=$(grep -c -E '^- [*][*]Status[*][*]: accepted' docs/adr/0018-the-qa-route-and-the-read-plan.md); c=$(awk '/^. [*][*]Rota da QA[*][*]/ { n = 1 } END { print n + 0 }' CONTEXT.md); d=$(awk '/\(recommended\)/ { n = 1 } END { print n + 0 }' .claude/rules/anatomia-do-agente.md); e=$(awk '/O kit congelou no merge do lote 7/ { n = 1 } END { print n + 0 }' docs/superpowers/specs/2026-09-23-a-gaveta-do-kit.md); f=$(awk '/mutants still apply/ { n = 1 } END { print n + 0 }' docs/handoffs/20261012-a-rota-da-qa/20-handoff-exec.md 2>/dev/null); echo "$a $b $c $d $e ${f:-0}"` → `1 1 1 1 1 1`
O Check lê os resultados que deixam artefato (CodeRabbit, 12ª rodada): a entrada do `KAIZEN_LOG`, a
ADR aceita, o verbete do `CONTEXT.md`, o `(recommended)` da anatomia, a frase da gaveta e, no
handoff, a linha do `--anchors`. Três resultados não têm Check que nasça vermelho, e por isso são
declarados no handoff: o `install --force` (o espelho `.claude/agents/` é rastreado, e cada
incremento que muda um chapéu já roda o `install --force`, então no HEAD ele já está em dia), o
`preflight` sem `agent … stale` (pelo mesmo motivo) e o `adr check` com rc 0 (verde hoje). O verbete
"Janela de medição" já existe no `CONTEXT.md`, e a frase nova dele não tem forma fixa; o "Hoje" da
gaveta e a frase da linha F3 a cobrem.
**Sensor durável:** não se aplica, é registro. A suíte inteira e o `--anchors` são a verificação.
**Reversível por:** reverter o commit.

## Medição do vermelho

Rodado pelo planner em 2026-10-14 às 12:23, a partir de `/home/joruge/repos/sdd_agents-kaizen` (branch
`kaizen/20261012`, head `c01c24a` mais o conserto da 16ª rodada), sobre o checkpoint **final**, em
background e lido até a linha final. É a 14ª medição: as anteriores (2026-10-12 20:53, 2026-10-13
05:02, 07:53, 08:12, 09:59, 11:53, 14:10, 14:38, 17:42, 18:16, 20:03, 20:37 e 21:41) foram refeitas
porque um Check mudou. O do I9 foi de `3 1` a `31 1` em onze passos (D13, D14, D15, D16, a fronteira
do id, D18, a fronteira do título, a linha GFM, D19, a delimitadora, o estado da tabela por bloco) e,
na 16ª rodada, a `19 1 1`: a D23 tirou os mundos da tabela, juntou os 13 mundos de Markdown numa
asserção só e acrescentou a chave do template no `check-templates.sh`. A D17 trouxe o I11, a D20
trouxe o I12, e o fecho virou I13. O do I3 foi de `1` a `1 1` (9ª rodada) e a `1 1 1 1` (10ª); o do I4 de `4` a `5`
(10ª); o do I13 de `1 1 1` a `1 1 1 1 1 1` (12ª).

O `--check` e o `--red` levaram 11 min 20 s (12:23:56 → 12:35:16); a 13ª medição levou 8 min 41 s.
Cinco Checks rodam o `check-gates.sh` (I1, I4, I9, I11 e I12), um depois do outro: o `--red` não
paraleliza nem corta por tempo (`tests/check-checkpoint.sh:612`), então o total é a soma das
corridas. O tempo de uma corrida do `check-gates.sh` varia com a carga desta máquina: ~95 s no
Contexto verificado, 144 s numa corrida isolada medida às 22:51 de 2026-10-13; nos 680 s desta
medição, cada uma das cinco ficou perto dos ~130 s.

```text
$ bash tests/check-checkpoint.sh --check docs/handoffs/20261012-a-rota-da-qa/checkpoint.md
  ok    checkpoint.md: 13 row(s), 11 under the anchor rule, none blind
(rc 0)
$ bash tests/check-checkpoint.sh --red docs/handoffs/20261012-a-rota-da-qa/checkpoint.md
  ok    checkpoint.md: I1 is red at HEAD (prints '0 0', wants '1 1')
  ok    checkpoint.md: I2 is red at HEAD (prints '0 0', wants '1 1')
  ok    checkpoint.md: I3 is red at HEAD (prints '0 0 0 4', wants '1 1 1 1')
  ok    checkpoint.md: I4 is red at HEAD (prints '0', wants '5')
  ok    checkpoint.md: I5 is red at HEAD (prints '0', wants '1')
  ok    checkpoint.md: I6 is red at HEAD (prints '0', wants '3')
  ok    checkpoint.md: I7 is red at HEAD (prints '0', wants '4')
  ok    checkpoint.md: I8 is red at HEAD (prints '0', wants '1')
  ok    checkpoint.md: I9 is red at HEAD (prints '0 0 0', wants '19 1 1')
  ok    checkpoint.md: I10 is red at HEAD (prints '0', wants '2')
  ok    checkpoint.md: I11 is red at HEAD (prints '0 0', wants '5 1')
  ok    checkpoint.md: I12 is red at HEAD (prints '0 0', wants '3 1')
  ok    checkpoint.md: I13 is red at HEAD (prints '0 0 0 0 0 0', wants '1 1 1 1 1 1')
  ok    checkpoint.md: 13 pending Check(s), every one red at HEAD
(rc 0)
```

**Como ler:** o vermelho de todos vem da presença do que o incremento acrescenta (uma asserção
nomeada, um probe, uma frase, uma entrada); nenhum Check é de ausência. Os pares `x y` do I1, I2,
I11 e I12, e o trio `x y z` do I9, juntam sensores com `echo`, e cada número é uma contagem ancorada
em `^  ok    `. O
quarteto do I3 junta três contagens ancoradas (duas do `check-dry-run.sh`, uma do `check-hat.sh`) e
a contagem de `disable-model-invocation` no `bin/sdd`, que desce de `4` para `1` (só o comentário
do `ticket` fica). O `--red`
prova que nada nasce verde, não que fica verde pelo motivo certo: isso é o TDD de cada incremento e o
mutante que o acompanha.

⚠️ **Se um Check mudar depois desta medição, rode o `--red` de novo e troque o bloco acima**: foi a
medição velha que o aceite do L4 pegou (item (h)).

## Riscos e não-feitos

| Risco | Probabilidade | Mitigação |
|---|---|---|
| O frescor (I4) reabre a QA de missões de alvo em voo que já fecharam um F com o handoff antigo: uma sessão `close` a mais (US$ 1,2–6) | média | é o preço da verdade do handoff (D3); a sessão reescreve e segue; declarado na ADR 0018 |
| O `check-autonomy.sh:1715-1775` muda de significado no I4 | alta | o I4 o ajusta e anota qual das duas correções escolheu; a propriedade que ele mede continua medida |
| O reteste custa uma sessão a mais que a improvisação | alta | é o trade-off do D3 contra a dependência de uma flag de terceiro |
| A âncora `bin/sdd:1800` do `TODO.md` sai do alvo no I4 | alta | o I4 roda `check-todo.sh --anchors` e reancora no mesmo commit |
| `qa: skipped` declarado e o EXEC tocou a tela | média | Jidoka desenhado: o `sdd-qa` escreve `blocked`, `handoff-blocked` para a linha (rc 3), o humano tira a chave **e apaga o handoff bloqueado** (senão paga mais duas sessões e duas escaladas) |
| O reteste escreve um relatório novo cujo nome ordena antes do atual | baixa | a sub-etapa fica em `exec`; o `no_work_check` para a 2ª volta igual (falha fechada); o `qa-execution` continua o relatório existente ao retomar |
| Um handoff ou relatório reescrito e não commitado | baixa | falha fechada: a volta seguinte pede de novo, e o `no_work_check` para a linha na repetição |
| Toda missão em voo sem `kaizen_log: skipped` passa a ter a entrada cobrada na DOCS (D23), com K8 `✅`, `⏳` ou `✗` na tabela | média | 0 de 64 missões reais dizem `✗` ou têm a chave, então nenhuma muda de resposta; a DOCS escreve a entrada (o dono existe), ou o humano declara `kaizen_log: skipped`; com range vazio, nada muda |
| O `resolve_mission` passa a recusar id fora de `^[0-9]{8}-[a-z0-9-]+$` em todo comando (D17); o kit é público, e um alvo de outra máquina com um nome fora da gramática para em `sdd status` | baixa | medido: 64 de 64 ids reais e os 19 ids de teste cabem; o motivo nomeia a gramática e o diretório a renomear; a entrada do `KAIZEN_LOG.md` do I13 registra a mudança (M8) |
| Um plano que escreve `✗` na linha K8 e esquece a chave tem a entrada cobrada (D23) | baixa | falha fechada e satisfazível: a DOCS escreve a entrada, ou o humano declara a chave; o `sdd-planner` § 3 manda escrever os dois juntos, e o template traz a chave no frontmatter e a frase no checklist |
| Na base, um plano sem a chave `kaizen_log` não é recusado nem cobrado (o resíduo da D20, com o leitor da D23) | baixa | todo plano escrito pelo template novo carrega a chave; 0 de 64 missões reais a têm; declarado no comentário do `k8_base_refusal`; a chave presente sem `skipped` é recusada no PLAN |
| `qa_substep` ou `qa_fix_ahead_of` passando a atribuir global | baixa | proibido no plano; o `step_after` do `check-autonomy.sh` segue valendo |
| Probe de prosa que passa sem a frase (sensor que mente) | média | passada de sabotagem de cada frase, registrada nas notas |
| O carimbo de mutação rodado antes da rodada dos bots | média | ordem do `CLAUDE.md`: PR aberto, todos os bots, uma leva de consertos, `./bin/sdd health` uma vez |

Não-feitos, por escolha: o (e), no `TODO.md`; encolher o grill (D8); uma chave de aprovação (D4);
baixar o modelo do `QA:close`.

## Verificação end-to-end

- `tests/run-all.sh` verde, com as asserções novas de `check-dry-run.sh`, `check-gates.sh`,
  `check-hat.sh` e `check-templates.sh` (as chaves `qa` e `kaizen_log`).
- Os Checks de I1–I13 dão o esperado da tabela; M1–M6, M8 e M9 do `00-missao.md` são as linhas `ok` deles.
- `tests/check-mutation.sh --only <slug> <sensor>.sh` (nome nu) pega cada um dos vinte e nove mutantes novos
  (`QA_substep_skipped_ignored`, `QA_substep_skipped_loose`, `QA_substep_retest_ignored`,
  `QA_fix_ahead_any_order`, `QA_fix_ahead_counts_merges`, `QA_fix_ahead_reads_the_directory`,
  `QA_fix_ahead_old_content_ok`, `QA_fix_ahead_any_carrier`, `QA_handoff_freshness_ignored`,
  `RUN_turn_rule_no_clock`,
  `DOCS_k8_ignored`, `DOCS_k8_presence_is_enough`, `DOCS_k8_reads_deleted_lines`,
  `DOCS_k8_heading_not_new`, `DOCS_k8_cite_not_new`, `DOCS_k8_block_not_reset`,
  `DOCS_k8_fence_blind`, `DOCS_k8_cite_no_left_boundary`, `DOCS_k8_cite_no_right_boundary`,
  `DOCS_k8_cite_first_only`, `DOCS_k8_cite_unpadded`, `DOCS_k8_key_ignored`, `DOCS_k8_key_loose`,
  `RUN_mission_id_unchecked`,
  `RUN_mission_id_slashes_kept`, `DOCS_k8_mission_arg_raw`, `PLAN_base_branch_k8_ignored`,
  `DOCS_base_branch_k8_ignored`, `PLAN_base_branch_refuses_silence`), e o `--anchors` diz `all N mutants
  still apply`.
- `./bin/sdd adr check` → rc 0; `env -u CLAUDECODE ./bin/sdd preflight` sem `agent … stale`.
- `./bin/sdd health` depois da rodada dos bots → `score: N caught of N`, `kit healthy`, carimbo
  escrito.
- M7 fica para o próximo `sdd kaizen`.
