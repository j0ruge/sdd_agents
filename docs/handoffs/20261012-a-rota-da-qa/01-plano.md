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
- **`.claude/rules/anatomia-do-agente.md`** é editado em I1, I3, I4, I8, I9 e I11 (regra do
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
- A linha K8 do template é `| K8 | Registro no KAIZEN_LOG | <✅/✗> | |` (`templates/missao.md:60`):
  o status é o 3º campo da tabela. O `awk` desta máquina é o `mawk`, orientado a byte: comparar a
  célula aparada com `✅` por igualdade funciona; classe negada com multibyte, não.

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

## Arquitetura da mudança

```
qa_substep (com interface)                                   gate_QA (os dois caminhos)
  ├─ sem interface                       → close              ├─ skipped → passa ("declares status: skipped")   (I1)
  ├─ 00-missao.md: qa: skipped (literal) → close   (I1)       ├─ blocked → para a linha
  ├─ sem charter                         → plan               ├─ ≠ done  → recusa
  ├─ sem relatório da missão fechado     → exec               ├─ F<n> done sem commit do handoff depois → recusa  (I4)
  ├─ F<n> done sem commit no relatório da missão depois → exec (I3)  └─ … âncoras de hoje
  └─ senão                               → close

qa_fix_ahead_of <caminho>  — UMA definição, DOIS leitores (I3 no qa_substep, I4 no gate_QA)
gate_DOCS: K8 ✅ no 00-missao.md ⇒ commit no KAIZEN_LOG.md na branch da missão   (I9)
boot_prompt/turn_rule: "todo carimbo sai de date"                                 (I8)
/sdd-plan + sdd-planner: o aceite renderiza, refaz --check/--red, conta as recomendadas (I6, I7)
```

- **O `skipped` não muda gate nenhum.** O `gate_QA` já aceita `skipped` com interface. O que faltava
  era a rota até a sessão que escreve o artefato (a metade do princípio 1 que pergunta quem pode
  escrever o que o gate exige). A chave é **literal e positiva**: só `qa: skipped` exato desvia, e
  qualquer outra grafia é a rota de hoje (frouxidão pularia QA de verdade, falha aberta).
- **O reteste e o frescor são a mesma pergunta**: "existe `F<n>` `done` sem um commit, depois dele,
  no caminho X?". X = o relatório da missão (o arquivo que o `mission_qa_report` escolhe, o mesmo
  que a Âncora 1 lê) decide a sub-etapa, e X = `$HANDOFF_DIR/$MISSION/30-handoff-qa.md` decide o gate. Uma definição, como o `report_closed`
  (o cabeçalho dele, `:2656-2660`, conta o que custou ter a âncora duplicada). O ciclo F vira
  `close` → EXEC → `exec` (reteste, move o `Status:`) → `close` (reescreve o handoff) → passa.
  Sem interface: `close` → EXEC → `close` (caminha de novo e reescreve). ⚠️ Ali o `qa_substep`
  devolve `close` antes de ler relatório (`:2678`), **de propósito**: o caminhante é o próprio
  `sdd-qa`, e o reteste é a caminhada do `close`. A pergunta do I3 só existe com interface; quem faz
  o `close` rodar de novo depois do F, nos dois caminhos, é o frescor do I4 (o CodeRabbit leu a
  ausência como lacuna no PR #247; não é).
- **A âncora do K8 lê dois artefatos**: a linha K8 do plano e o `KAIZEN_LOG.md` de cada merge-base e
  de HEAD, em que as linhas que citam o id da missão têm de crescer (D15). A identidade da entrada é
  o estado que faltava às três regras anteriores (D7, D13, D14), e cada uma deixou passar um caso
  num diff que não sabia qual entrada procurava. Ela não lê o `45-docs.md`, que é rótulo; o que
  conta é a entrada que ficou, citando a missão, quem quer que a tenha escrito (a DOCS ou um incremento do EXEC, como o I11
  desta missão). Range vazio (missão na base, já
  mergeada, sem base resolvida) → a resposta de hoje, como o `mission_qa_report`.
- **O aceite e o planner são prosa**, e o sensor é o `check-hat.sh`. O `gate_PLAN` não muda: `auto`
  e `humano-YYYY-MM-DD` continuam válidos.

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
- O helper `qa_fix_ahead_of <caminho relativo à raiz>`, perto do `report_closed` (`bin/sdd:2666`).
  Para cada linha de `checkpoint_rows` com ID `^F[0-9]+$`, status `done` e commit não vazio, se
  `git -C "$REPO_ROOT" rev-list -1 --no-merges --ancestry-path "$c..HEAD" -- "$1"` for vazio,
  imprime `<ID> <commit>` e para. Senão, não imprime nada.
  - Não atribui global (é lido por `$( )`).
  - Captura com `|| true`.
  - Commit que não resolve é pulado; é inalcançável numa corrida derivada, porque o `gate_EXEC` vem antes.
  - O comentário do cabeçalho diz "uma definição, dois leitores" e cita a ADR 0018 §2.
- No `qa_substep`, depois do `report_closed`, sobre o relatório que ele já leu (`report`, `:2680`):
  `[ -z "$(qa_fix_ahead_of "${report#"$REPO_ROOT"/}")" ] || { printf 'exec\n'; return 0; }`.
  Nunca o diretório `reports/` inteiro: ver o Contexto verificado (a posse).
- Os comentários de `:2650-2655` e `:2913-2921` deixam de afirmar `disable-model-invocation` e
  dizem o que o kit sabe:
  - o slash é a rota do runner, qualquer que seja a flag;
  - medido em 2026-10-12, as duas skills declaram `false`, e o `sdd-qa` as chamou pela ferramenta
    `Skill` cinco vezes;
  - a rota existe para isso não ser preciso.
- `phase_task` do `QA:exec` (`:2935`): o texto cobre também o reteste dos bugs consertados, por
  exemplo `walk the journeys in persona and write the dated report + the bug registry; after a fix
  increment, retest the fixed bugs and move their Status`.
- `agents/sdd-qa.md` § 4 (`:97-103`): depois de um `F<n>` feito, o runner devolve a QA à
  `qa-execution` (`QA:exec`), que reteste e move o `Status:`, e depois a esta sessão, para reescrever
  o handoff (§ 6). **Esta sessão nunca invoca as skills `qa-*`, nem pela ferramenta `Skill`.** Um
  probe no `check-hat.sh` lê a frase (`hat: sdd-qa leaves the retest to the runner`), com passada de
  sabotagem nas notas.
- `docs/pipeline.md` § QA: a linha `QA:exec` da tabela ganha "or a done `F<n>` has no report commit
  after it". `.claude/rules/anatomia-do-agente.md` § 4: uma frase.
- `./bin/sdd install --force`.

**Onde:** `bin/sdd`, `agents/sdd-qa.md`, `docs/pipeline.md`, a anatomia, `tests/check-dry-run.sh`,
`tests/check-hat.sh`, `tests/check-mutation.sh`.

**Como (TDD):** um mundo novo no `check-dry-run.sh`, no bloco de QA, depois do mundo da posse do
relatório (`:522-538`) e **antes** da limpeza dele. No fixture em `main` o range é vazio e o
`mission_qa_report` lê o mais novo. Passos, em ordem:
1. Com `E2E_CMD="true"` e charter presente, escreva um relatório `closed` e commite-o
   (`git add docs/qa && git commit -qm …`). Faça um commit vazio de conserto
   (`git commit -q --allow-empty -m "fix: F1"`) e guarde o hash curto `h`.
2. Acrescente ao `$MDIR/checkpoint.md` a linha `| F1 | the fix | \`true\` → 0 | pending | — |`.
   Afirme `QA:close=sdd-qa` com o nome `a pending fix increment does not reopen the walk`.
3. Troque a linha para `done` com `$h`. Afirme `QA:exec=<none>` com o nome
   `a fix increment done after the closed report sends QA back to exec for the retest`. Hoje isso é
   vermelho: projeta `QA:close=sdd-qa`.
4. O mundo do merge: corte uma branch do commit **anterior** ao F, acrescente nela um relatório com
   nome que ordena **depois** do da missão (em `main`, com range vazio, ele vira a escolha do
   `mission_qa_report`), volte e faça `git merge --no-ff`. Afirme que ainda é `QA:exec=<none>`, com o
   nome `a report a merge brings in after the fix is not the retest`.
5. Acrescente uma linha ao relatório escolhido e commite. Afirme `QA:close=sdd-qa` com o nome
   `a report committed after the fix closes the retest`.
6. O mundo da posse (CodeRabbit, PR #247): corte uma branch de missão a partir deste ponto (molde
   `:522-538`, porque com range vazio não há posse a medir). Nela, commite um relatório **novo** e
   `closed` (o da missão), um commit de conserto com o `F1` `done` no hash dele, e depois, num commit
   comum, uma linha acrescentada a um relatório **da base** (de outra missão: editar não dá posse).
   Afirme `QA:exec=<none>`, com o nome `another mission's report touched after the fix is not the
   retest`. Volte à `main` e apague a branch.
7. Restaure tudo byte a byte: o checkpoint com `git checkout -- "$MDIR/checkpoint.md"`, a história
   com `git reset -q <sha guardado antes do mundo>` (mixed, como o bloco vizinho, porque o config
   modificado é do bloco seguinte), a branch apagada, e `docs/qa/` removido.

Mutantes (cada um provado por `--only <slug> check-dry-run.sh`):
- `QA_substep_retest_ignored` apaga a linha nova do `qa_substep`;
- `QA_fix_ahead_any_order` troca `--ancestry-path "$c..HEAD"` por `HEAD`, e o passo 3 o pega,
  porque há commit de relatório antes do F;
- `QA_fix_ahead_counts_merges` tira o `--no-merges`, e o passo 4 o pega;
- `QA_fix_ahead_reads_the_directory` troca o `${report#…}` do `qa_substep` por
  `$QA_DOCS_PATH/reports/`, e o passo 6 o pega.

**Check:** `o=$(bash tests/check-dry-run.sh 2>&1); grep -c '^  ok    a fix increment done after the closed report sends QA back to exec for the retest' <<< "$o"` → `1`
**Sensor durável:** as cinco asserções no `check-dry-run.sh`, os quatro mutantes, o probe do
`check-hat.sh`, e o `no_work_check` como freio de um reteste que não produz commit.
**Reversível por:** reverter o commit. O `sdd-qa` volta a improvisar como hoje.

### I4 — o frescor do handoff de QA

**O quê:**
- No `gate_QA`, logo depois do enum positivo (`bin/sdd:1621-1624`) e **antes** da divisão de
  caminho (`:1633`), para valer nos dois:
  `ahead="$(qa_fix_ahead_of "${h#"$REPO_ROOT"/}")"`, onde `h` é o caminho absoluto já definido em
  `:1601`. Confira que o `REPO_ROOT` é prefixo de `h`; se não for, use `$HANDOFF_DIR/$MISSION/30-handoff-qa.md`.
  Com `ahead` não vazio, o `GATE_WHY` passa a ser
  `30-handoff-qa.md has no commit after ${ahead%% *} (${ahead#* }) — the sdd-qa close rewrites it once the fix is retested`
  e o gate devolve 1.
- O comentário nomeia o dono, que é o `sdd-qa` (§ 6 "Commit everything"), e diz como ele é
  alcançado: com interface, pelo `close` que o `qa_substep` dá depois do commit de relatório do
  reteste; sem interface, de imediato. Diz também por que o `skipped` e o `blocked` ficam fora: os
  dois retornam antes.
- `agents/sdd-qa.md` § 6: o handoff é reescrito e commitado depois de cada `F<n>` feito, e o gate
  recusa um handoff mais velho que o último conserto.
- `docs/pipeline.md` § QA "Passes when": a condição nova. Anatomia § 4: uma frase.
- **A âncora do `TODO.md`.** O item `bin/sdd:1800` (`gate-qa-e2e`) desce com as linhas novas. O I1
  já o empurra 2 linhas (medido no teste de autocontenção: fica em `:1802`, dentro da janela de 10),
  e o I4 soma as dele. Rode `bash tests/check-todo.sh --anchors TODO.md`; se sair do alvo, troque o
  número pela linha atual do `run_check_cmd "$E2E_CMD" "gate-qa-e2e"` **no mesmo commit**.
- **O fixture do `check-autonomy.sh:1715-1775`.** A sessão 2 do stub (EXEC) fecha o F1 e o bug, e a
  asserção espera `QA EXEC REVIEW DOCS`. Com o frescor, a QA reabre. Escolha uma das duas
  correções e anote qual no `checkpoint-notas.md`:
  - a sessão 2 do stub também reescreve e commita o `30-handoff-qa.md` depois do `F1 is done`;
  - a sequência esperada ganha a QA de novo.

  O que o fixture mede ("o `gate_pass_rows` perguntado de novo com o veredito de QA nos livros")
  tem de continuar medido.

**Onde:** `bin/sdd` (`gate_QA`), `agents/sdd-qa.md`, `docs/pipeline.md`, a anatomia, `TODO.md`
(talvez), `tests/check-gates.sh`, `tests/check-autonomy.sh`, `tests/check-mutation.sh`.

**Como (TDD):** quatro asserções no `check-gates.sh`, com o prefixo exato `freshness: `.
- Com interface, em `:1969`, onde a QA passa, numa sequência:
  1. commite o handoff; faça um commit de conserto e acrescente ao checkpoint `| F1 | … | done | <h> |`
     (commitado, porque o `gate_EXEC` exige o hash na história);
  2. `freshness: with an interface, a handoff committed before a done F<n> holds QA and names the
     fix`: `sdd phase` dá `QA`, e o `sdd why QA` contém `30-handoff-qa.md has no commit after F1`;
  3. reescreva o handoff e commite; `freshness: the handoff committed after the fix lets QA pass`
     dá `REVIEW`;
  4. `freshness: a pending F<n> demands nothing of the handoff`, com o F em `pending` antes do
     commit do conserto. ⚠️ Com um `pending`, a fase é EXEC; leia então só o `sdd why QA` e exija a
     **ausência** de `has no commit after`.
- Sem interface, em `:2016`: `freshness: without an interface, the same handoff holds QA too`.

Restaure o fixture (o checkpoint e a história) para o bloco seguinte. Mutante
`QA_handoff_freshness_ignored`, que neutraliza o `if` novo; prove com `--only
QA_handoff_freshness_ignored check-gates.sh` (~2 min).

**Check:** `o=$(bash tests/check-gates.sh 2>&1); grep -c '^  ok    freshness: ' <<< "$o"` → `4`
**Sensor durável:** as quatro asserções e o mutante. O `check-autonomy.sh` passa a medir a corrida
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
   velha do L4.
2. **Renderizar o plano**, no formato de um plano `superpowers:writing-plans`:
   - cabeçalho com **Goal**, **Architecture** e **Tech Stack**;
   - as restrições globais: escopo, fora de escopo, as decisões do grill;
   - cada incremento como `### Task <ID>`, com **Files:**, passos `- [ ]` (comando e resultado
     esperado) e o Check;
   - a tabela PLAN-AUTO e as pendências;
   - a contagem das decisões: `N (recommended) of M`.

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
  answers`: exige `(recommended)` e a frase que cobre o caso todo ✅;
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
  - **§ 1, a marca da decisão.** Cada decisão do grill no `00-missao.md` termina com
    `(recommended)` quando o humano escolheu a opção marcada como recomendada, ou com
    `(other: <o texto da opção escolhida>)` quando escolheu outra. O aceite conta as marcas
    (ADR 0018 §3).
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
- `templates/missao.md`, `## Decisões do grill`: o placeholder passa a
  `1. <decisão + porquê em uma linha> (recommended | other: <a opção escolhida>)`.
- `tests/check-hat.sh`:
  - `planner_agent_probes` (`:392`) ganha três pares, cada um lendo a **sua** seção (§ 1, § 2, § 6):
    - `hat: the planner marks each grill decision (recommended) or (other)`;
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
- O `turn_rule` (`bin/sdd:3146-3152`) ganha, numa linha física própria antes do fecho das aspas:
  `` Every timestamp you write (a data: or atualizado: field, a note) comes from \`date '+%Y-%m-%d
  %H:%M'\` run in the same batch of commands, never from a log you read or from memory. `` (as crases
  escapadas, como as vizinhas).
- O comentário acima cita o L4: `10-ticket.md` às 12:10 com a sessão às 17:03, e `45-docs.md` às
  18:10 com a sessão às 18:02.
- Anatomia § 1: uma frase.

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
  1. Leia o status da linha K8 do `$MISSION_DIR/00-missao.md`:
     `awk -F'|' '$2 ~ /^[[:space:]]*K8[[:space:]]*$/ { s = $4; gsub(/^[[:space:]]+|[[:space:]]+$/, "", s); print s; exit }'`.
  2. Só com o literal `✅` (admissão **positiva**), monte `nots` por `mission_base_refs`. Sem base
     que resolva, ou com range vazio (`git rev-list -n 1 HEAD --not …` vazio), fica a resposta de
     hoje, o molde do `mission_qa_report` (`:1080-1084`).
  3. Senão, conte a **identidade** da entrada (D15): o id da missão. Para **cada** merge-base `b`
     de HEAD com as bases (o `bases` do molde do `mission_qa_report`, `:1069-1074`), o número de
     linhas do `KAIZEN_LOG.md` que citam `$MISSION` (`grep -cF -- "$MISSION"`, string fixa) tem de
     **crescer** de `b` até HEAD. Leia os dois lados do git, nunca da árvore:
     `blob="$(git -C "$REPO_ROOT" show "$b:KAIZEN_LOG.md" 2>/dev/null || true)"` e o mesmo com
     `HEAD:`, e conte por herestring (`grep -cF -- "$MISSION" <<< "$blob" || true`), nunca com
     `git show … | grep`, que sob `pipefail` morre quando o arquivo não existe na base. Exigir todas
     as merge-bases é a direção que falha fechada. Na falta, o `GATE_WHY` é
     `00-missao.md checks K8 (a KAIZEN_LOG entry) and the mission branch adds no entry that cites $MISSION to KAIZEN_LOG.md — write the entry, citing the mission, with the before and after the plan names, or uncheck K8 with the human`.
     **Por que contar e não "ausente na base":** o `KAIZEN_LOG.md` da `main` já cita esta missão (a
     entrada do veredito aponta para `docs/handoffs/20261012-a-rota-da-qa/05-verdict.md`), e toda
     missão nascida do kaizen nasce assim; "ausente na base" reprovaria a entrada dela para sempre.
     **Medido** num repo descartável, com a base já citando a missão uma vez:
     - nada acrescentado → reprova (1→1);
     - uma linha trocada → reprova (1→1);
     - um cabeçalho antigo renomeado → reprova (1→1);
     - uma entrada nova que não cita a missão → reprova (1→1);
     - uma entrada nova que cita a missão → passa (1→2);
     - essa entrada revertida → reprova (1→1).

     As regras recusadas, e o que cada uma deixava passar: "algum commit tocou o arquivo" (D7),
     uma entrada revertida; "linhas acrescentadas" (D13), a troca de uma linha; "um `+## `
     acrescentado" (D14), o renome de um cabeçalho; "adições menos remoções > 0", nada disso, mas
     reprovaria a missão que escreve a entrada e enxuga o log, sem saída honesta para o dono.
     Resíduos declarados no comentário:
     - acrescentar uma citação da missão a uma entrada antiga passa;
     - uma faxina que apaga uma linha antiga que já citava a missão e escreve a entrada com uma só
       linha citando-a reprova (raro; falha fechada);
     - a conta é por linha, então citar a missão duas vezes na mesma linha conta uma;
     - o "cada merge-base" não tem mundo próprio no fixture, porque pede duas bases divergentes.
  4. O comentário nomeia o dono: o `sdd-docs`, com `KAIZEN_LOG.md` no `writes:`.
- `agents/sdd-docs.md` § 3, linha `KAIZEN_LOG.md`: atualize quando a missão mede um antes/depois
  **ou quando o K8 do `00-missao.md` está ✅**, e o gate cobra. `n/a` só com K8 que não esteja ✅.
  A entrada **cita o id da missão** (`<YYYYMMDD>-<slug>`) no corpo: é a linha que o gate conta.
- `docs/pipeline.md` § DOCS: a condição nova. Anatomia § 4: uma frase.
- `./bin/sdd install --force`.

**Onde:** `bin/sdd` (`gate_DOCS`), `agents/sdd-docs.md`, `docs/pipeline.md`, a anatomia,
`tests/check-gates.sh`, `tests/check-hat.sh`, `tests/check-mutation.sh`.
**Como (TDD):** no bloco da DOCS do `check-gates.sh`, logo depois de `:2753` (`assert_phase "drift
checklist complete" "PR"`, o primeiro ponto em que a DOCS passa), corte uma branch de missão (molde `:1318-1326`) e escreva no `$MDIR/00-missao.md` uma linha
`| K8 | Registro no KAIZEN_LOG | ✅ | |`. Antes de cortar a branch, a `main` do fixture ganha um
`KAIZEN_LOG.md` cuja entrada antiga já cita `$MISSION` (por exemplo `Veredito em
\`docs/handoffs/$MISSION/05-verdict.md\``), a forma de toda missão nascida do kaizen. Sete asserções
com o prefixo exato `kaizen-log: `, nesta ordem, cada mundo um commit na branch:
1. `kaizen-log: a base that already cites the mission is not the entry`: nada acrescentado, a fase
   é `DOCS`, e o motivo contém `adds no entry that cites`;
2. `kaizen-log: a one-line edit with no new entry keeps DOCS blocked`: uma linha trocada numa
   entrada antiga;
3. `kaizen-log: renaming an old heading is not a new entry`: o `## ` antigo renomeado (o mundo do
   Codex na 4ª rodada do PR #247);
4. `kaizen-log: a new entry that does not cite the mission keeps DOCS blocked`: um `## ` novo cujo
   corpo não cita a missão;
5. `kaizen-log: a new entry that cites the mission lets DOCS pass`: um `## ` novo cujo corpo cita
   `$MISSION`;
6. `kaizen-log: an entry written and then reverted in the mission branch holds DOCS`: depois de
   `git revert --no-edit HEAD` (sem `-q`, que o git 2.43 não aceita);
7. `kaizen-log: K8 unchecked demands nothing`: com `✗` no lugar de `✅`, e o revert no lugar, a fase
   segue.

As asserções 1, 2, 3, 4 e 6 deixam a fase em `DOCS`, com o motivo da regra; a 5ª e a 7ª deixam a
fase seguir para `PR`.

Volte à `main` e restaure o fixture. Um probe em `hat_promise_probes` lê o `sdd-docs.md` § 3: exige
`K8` na linha do `KAIZEN_LOG.md` e a instrução de citar o id da missão, e imprime `hat: the docs hat
reads K8 of the plan before it marks KAIZEN_LOG`. Três mutantes, provados por `--only <slug>
check-gates.sh`:
- `DOCS_k8_ignored` neutraliza o `if` novo, e a asserção 1 o pega;
- `DOCS_k8_presence_is_enough` compara a conta de HEAD com 0 em vez da conta da base, e a asserção
  1 o pega (a base já cita a missão);
- `DOCS_k8_any_new_heading` conta linhas `## ` no lugar de linhas que citam `$MISSION`, e a
  asserção 4 o pega.
**Check:** `a=$(bash tests/check-gates.sh 2>&1); b=$(bash tests/check-hat.sh 2>&1); x=$(grep -c '^  ok    kaizen-log: ' <<< "$a"); y=$(grep -c '^  ok    hat: the docs hat reads K8 of the plan' <<< "$b"); echo "$x $y"` → `7 1`
**Sensor durável:** as sete asserções, o probe e os três mutantes.
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

### I11 — fecho

**O quê:**
- `CONTEXT.md`: um verbete "Rota da QA", com as duas perguntas novas do `qa_substep`, o helper com
  dois leitores, o frescor, e por que o `skipped` não mudou gate nenhum. O verbete "Janela de
  medição" registra o congelamento da D11: o kit congela no merge do lote 7, e a janela abre no
  primeiro carimbo de alvo depois dele.
- `.claude/rules/anatomia-do-agente.md` § 7 (o aceite renderizado, `aprovacao:` vazio sob
  `/sdd-plan`, a contagem). ⚠️ `.claude/` é caminho sensível: em sessão interativa o harness pode
  pedir permissão; nunca contorne por Bash.
- A gaveta (`docs/superpowers/specs/2026-09-23-a-gaveta-do-kit.md`): a linha F3 e o § F3 "Hoje"
  registram o congelamento da D11 (o molde é o do lote 6, `54e2f18`), e a F6 registra que a C2 do
  caderno tem a resposta do D2.
- ADR 0018: `Status: accepted`.
- `./bin/sdd install --force`, `./bin/sdd adr check` (rc 0), e
  `env -u CLAUDECODE ./bin/sdd preflight` sem `agent … stale`.
- A entrada `## <data> — Lote 7: a rota da QA e o aceite que lê o plano` no `KAIZEN_LOG.md`:
  - a entrada **cita o id da missão** (`20261012-a-rota-da-qa`), que é a linha que a âncora do I9
    conta (D15);
  - **antes**, o veredito ao lado: 3 de 5 missões com QA à mão, 3 de 5 intervenções, reteste
    improvisado em duas missões (cinco vezes), dois carimbos com até 5 h de erro, a entrada do
    `KAIZEN_LOG` escrita à mão;
  - **depois**, M1–M6 medidos (as linhas `ok` dos Checks);
  - **M7**, declarada como a medida da próxima janela.
- O `20-handoff-exec.md` da missão, pelo `templates/handoff.md`.
- `tests/run-all.sh` inteiro verde, e `tests/check-mutation.sh --anchors` → `all N mutants still
  apply`.

**Onde:** os arquivos acima.
**Check:** `a=$(grep -c -E '^## .*Lote 7: a rota da QA' KAIZEN_LOG.md); b=$(grep -c -E '^- [*][*]Status[*][*]: accepted' docs/adr/0018-the-qa-route-and-the-read-plan.md); f=$(awk 'END{print (NR>0)}' docs/handoffs/20261012-a-rota-da-qa/20-handoff-exec.md 2>/dev/null); echo "$a $b ${f:-0}"` → `1 1 1`
**Sensor durável:** não se aplica, é registro. A suíte inteira e o `--anchors` são a verificação.
**Reversível por:** reverter o commit.

## Medição do vermelho

Rodado pelo planner em 2026-10-13 às 08:12, a partir de `/home/joruge/repos/sdd_agents-kaizen` (branch
`kaizen/20261012`, head `1b03ec5` mais a D15), sobre o checkpoint **final**. É a quarta medição: as
anteriores (2026-10-12 20:53, 2026-10-13 05:02 e 07:53) foram refeitas porque o Check do I9 mudou,
de `3 1` para `4 1` (D13), para `5 1` (D14) e para `7 1` (D15).

O `--red` levou 7 min 48 s (08:12:47 → 08:20:35): três Checks rodam o `check-gates.sh`, de ~95 s.

```text
$ bash tests/check-checkpoint.sh --check docs/handoffs/20261012-a-rota-da-qa/checkpoint.md
  ok    checkpoint.md: 11 row(s), 9 under the anchor rule, none blind
(rc 0)
$ bash tests/check-checkpoint.sh --red docs/handoffs/20261012-a-rota-da-qa/checkpoint.md
  ok    checkpoint.md: I1 is red at HEAD (prints '0 0', wants '1 1')
  ok    checkpoint.md: I2 is red at HEAD (prints '0 0', wants '1 1')
  ok    checkpoint.md: I3 is red at HEAD (prints '0', wants '1')
  ok    checkpoint.md: I4 is red at HEAD (prints '0', wants '4')
  ok    checkpoint.md: I5 is red at HEAD (prints '0', wants '1')
  ok    checkpoint.md: I6 is red at HEAD (prints '0', wants '3')
  ok    checkpoint.md: I7 is red at HEAD (prints '0', wants '4')
  ok    checkpoint.md: I8 is red at HEAD (prints '0', wants '1')
  ok    checkpoint.md: I9 is red at HEAD (prints '0 0', wants '7 1')
  ok    checkpoint.md: I10 is red at HEAD (prints '0', wants '2')
  ok    checkpoint.md: I11 is red at HEAD (prints '0 0 0', wants '1 1 1')
  ok    checkpoint.md: 11 pending Check(s), every one red at HEAD
(rc 0)
```

**Como ler:** o vermelho de todos vem da presença do que o incremento acrescenta (uma asserção
nomeada, um probe, uma frase, uma entrada); nenhum Check é de ausência. Os pares `x y` do I1, I2 e
I9 juntam dois sensores com `echo`, e cada número é uma contagem ancorada em `^  ok    `. O `--red`
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
| O K8 ✅ de missões antigas em voo passa a cobrar a entrada na DOCS | média | a DOCS a escreve (o dono existe); com range vazio, nada muda |
| `qa_substep` ou `qa_fix_ahead_of` passando a atribuir global | baixa | proibido no plano; o `step_after` do `check-autonomy.sh` segue valendo |
| Probe de prosa que passa sem a frase (sensor que mente) | média | passada de sabotagem de cada frase, registrada nas notas |
| O carimbo de mutação rodado antes da rodada dos bots | média | ordem do `CLAUDE.md`: PR aberto, todos os bots, uma leva de consertos, `./bin/sdd health` uma vez |

Não-feitos, por escolha: o (e), no `TODO.md`; encolher o grill (D8); uma chave de aprovação (D4);
baixar o modelo do `QA:close`.

## Verificação end-to-end

- `tests/run-all.sh` verde, com as asserções novas de `check-dry-run.sh`, `check-gates.sh`,
  `check-hat.sh` e `check-templates.sh`.
- Os Checks de I1–I11 dão o esperado da tabela; M1–M6 do `00-missao.md` são as linhas `ok` deles.
- `tests/check-mutation.sh --only <slug> <sensor>.sh` (nome nu) pega cada um dos onze mutantes novos
  (`QA_substep_skipped_ignored`, `QA_substep_skipped_loose`, `QA_substep_retest_ignored`,
  `QA_fix_ahead_any_order`, `QA_fix_ahead_counts_merges`, `QA_fix_ahead_reads_the_directory`,
  `QA_handoff_freshness_ignored`,
  `RUN_turn_rule_no_clock`, `DOCS_k8_ignored`, `DOCS_k8_presence_is_enough`, `DOCS_k8_any_new_heading`), e o `--anchors` diz `all N mutants still apply`.
- `./bin/sdd adr check` → rc 0; `env -u CLAUDECODE ./bin/sdd preflight` sem `agent … stale`.
- `./bin/sdd health` depois da rodada dos bots → `score: N caught of N`, `kit healthy`, carimbo
  escrito.
- M7 fica para o próximo `sdd kaizen`.
