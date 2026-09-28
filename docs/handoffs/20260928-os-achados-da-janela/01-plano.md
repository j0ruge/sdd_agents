---
missao: 20260928-os-achados-da-janela
data: 2026-09-28
---

# Plano — os achados da janela do juiz

> **Teste de autocontenção:** uma sessão nova, sem nenhuma memória da conversa que gerou este
> plano, lendo apenas `00-missao.md` + `01-plano.md` + `checkpoint.md`, consegue executar?
> Se a resposta for "só se souber X", **X vai escrito aqui**.

## Contexto verificado (não re-descobrir)

Tudo abaixo foi lido ou rodado em 2026-09-28 sobre `038a314`, onde o `bin/sdd` é byte a byte o de
`4fd0f31`. **Número de linha envelhece**: cada incremento que mexe no `bin/sdd` desloca os de baixo.
Ancore no símbolo (`grep -n '^nome()' bin/sdd`) e use o número só como ponto de partida.

**Onde e como a missão roda**

- Branch `fix/os-achados-da-janela`, nascida da `main` **depois** do merge do PR só de docs da
  `kaizen/o-veredito-da-janela-do-juiz`. Esse PR leva o veredito, este plano e a ADR 0013. Com
  `JIRA_ENABLED=false`, o `ensure_mission_branch` faz checkout da branch ou a cria da branch corrente.
- `TEST_CMD` = `bash tests/run-all.sh`: **verde em `038a314`, 234 s**. Ele roda 15 dos 16 sensores
  (o `check-mutation.sh` só por `--anchors`). `bash tests/check-mutation.sh --anchors` levou segundos
  e aplicou os **422** mutantes.
- Todo sensor imprime `  ok    <asserção>` na **stdout** e `  FAIL  <asserção>` na **stderr**, com o
  mesmo texto: `pass() { printf '  ok    %s\n' "$1"; }` em `tests/check-gates.sh:33`,
  `check-dry-run.sh:37`, `check-preflight.sh:40`, `check-autonomy.sh:35` e `check-hat.sh:44`.
  O `tests/check-coordination.sh` é Python embutido e imprime `print("  ok    " + name)` (`:75`).
  Os Checks do `checkpoint.md` descartam a stderr (`2>/dev/null`) e ancoram em `^  ok    `. O
  `tests/check-checkpoint.sh` recusa pipe cru na célula e, quando a célula faz `2>&1` com `grep`,
  exige a âncora em **todo** `grep`.
- Sob `SDD_MUTANT` o sensor para no primeiro `fail()`; fora do mutante, roda tudo. Asserção nova
  se escreve com `assert_eq "<nome>" "<esperado>" "<obtido>"`. Em `check-gates.sh` também existem
  `assert_phase` (roda `sdd phase`), `assert_why` e `assert_why_absent` (rodam `sdd why <m> <FASE>`),
  nas linhas 45-82.

**A armadilha que custa a suíte em todo incremento de código**

- O `TODO.md` tem **41** itens ancorados em `bin/sdd:<linha>`. O `tests/check-todo.sh` (na suíte)
  exige que a crase da cabeça do item (o `<símbolo>`) esteja a **até 10 linhas** da linha citada.
  Inserir 20 linhas em `qa_substep` desloca todo item ancorado abaixo, e a suíte fica vermelha no
  `check-todo.sh`, não no seu teste. **Depois de cada mudança no `bin/sdd`**, rode
  `bash tests/check-todo.sh --check TODO.md`. Para cada item que ele acusar, troque só o número da
  âncora pela linha onde o símbolo está agora (`grep -n` do símbolo), **no mesmo commit**. O
  `TODO.md` e o `tests/health-baseline.txt` estão no `writes:` de todo chapéu (`HAT_WRITES_BASE`,
  `bin/sdd:1948`).
- Idem para o catálogo: mutantes ancorados em texto do `bin/sdd` perto do que muda. `sed` que
  passa a não casar deixa o mutante inaplicável, e o `--anchors` reprova. Rode
  `bash tests/check-mutation.sh --anchors` antes de cada commit de código. Os mais próximos são
  `mut_QA_status_line_start` (`tests/check-mutation.sh:454`), `mut_QA_matrix_pending` (`:471`),
  `mut_QA_e2e_red_never_probed` (`:581`), `mut_QA_app_down_on_unknown` (`:596`),
  `mut_QA_probe_ignores_e2e_rc` (`:610`), `mut_QA_hostport_no_default_port` (`:625`) e
  `mut_DOCS_alignment_colon_blind` (`:357`).
- Forma de um mutante: `mut_<NOME>() { sed -i '<s|âncora exata|troca|>' "$1"; }`, mais o
  `<NOME>` numa linha própria (dois espaços de recuo) dentro de `CATALOG=(` (`tests/check-mutation.sh:4385`).
  Um mutante que **não** muda o arquivo é reprovado pelo `--anchors`. O `sed` ancora em **código**,
  nunca em número de linha (CLAUDE.md: "o probe de sabotagem prova primeiro que sabotou o que dizia
  sabotar").
- `bin/sdd` roda sob `set -euo pipefail`. Captura que pode dar rc ≠ 0 (git, grep, find) leva
  `|| true`, `|| rc=$?` ou `if x="$(…)"; then`. Filtro sobre texto vai por herestring (`<<<`),
  nunca por `printf … | grep -q`.
- Função cujo resultado é um **caminho** pode ser lida por `$(…)`. Função que publica global
  (`GATE_*`) é **chamada**, nunca substituída.

**Achado 4: o relatório de QA (I2)**

- `latest_matching()` fica em `bin/sdd:770`: `ls -1d $pattern | sort -V | tail -1 || true`.
- `report_closed()` fica em `bin/sdd:1867` e é a definição única de "relatório fechado".
- `qa_substep()` fica em `bin/sdd:1873-1884`. Sem `E2E_CMD` e sem `APP_URL`, responde `close`. Sem
  charter, responde `plan`. Depois vem `report="$(latest_matching "$qa/reports/*.md")"`; se o
  relatório não estiver fechado, `exec`, senão `close`.
- `gate_QA()` começa em `bin/sdd:1126`. A Âncora 1 fica em `:1161`
  (`report="$(latest_matching "$REPO_ROOT/$QA_DOCS_PATH/reports/*.md")"` e
  `[ -n "$report" ] || { GATE_WHY="no report in $QA_DOCS_PATH/reports/"; return 1; }`), seguida de
  `report_closed` e da Âncora 2 (`Pending`) sobre o **mesmo** arquivo. O `$report` é relido depois,
  em `if [ -n "${report:-}" ]` (perto de `:1318`), para nomear os bugs `deferred`: mantenha o nome
  da variável.
- **O charter não muda** (decisão 3). O `latest_matching "$qa/charters/*.md"` do `qa_substep` só
  responde "a árvore existe", porque os charters se chamam `CH-<slug>.md`, sem data, e são
  duráveis por contrato da skill.
- Fixtures: o QA do `tests/check-gates.sh` (linhas 557-604) roda **na base** (`branch: main`, repo
  criado com `git init -q -b main` em `:102`, `DEFAULT_BRANCH="main"` em `:111`), com relatório em
  `docs/qa/reports/2026-01-01-fixture.md` e handoff `30-handoff-qa.md` presente. O sub-passo
  aparece no `tests/check-dry-run.sh:460-496` por `sdd run <m> --dry-run --phase QA` e pelo helper
  `projected` (`:51`), que imprime `QA:exec=<none>`, `QA:close=sdd-qa` etc. O `--dry-run` **não**
  troca de branch (`ensure_mission_branch` retorna em `DRY_RUN`, `bin/sdd:4653`), e `sdd phase` e
  `sdd why` também não. O teste faz o checkout da branch de missão à mão.
- A Âncora 1 só é alcançada **depois** do `30-handoff-qa.md` existir: sem ele, o gate reprova antes
  com `missing 30-handoff-qa.md`.

**Achado 3: o app na `APP_URL` (I3)**

- `app_probe()` fica em `bin/sdd:657` e usa connect TCP por `/dev/tcp`, com
  `timeout "$APP_PROBE_TIMEOUT"`. `readonly APP_PROBE_TIMEOUT=3` fica em `bin/sdd:28` (constante, não
  chave). A saída é `<estado>|<label>`, com os estados `up`, `down` e `unknown`. Ele é unilateral: a
  dúvida vira `unknown`, e `unknown` nunca escala.
- Chamadores: `gate_QA` (`bin/sdd:1293`, só **depois** de o `E2E_CMD` voltar vermelho) e o
  preflight (`bin/sdd:4861`).
  - No `gate_QA`, o `case` tem `down)`, que arma `GATE_APP_DOWN=1`, e `up)`. O `*)` tem de continuar
    o **último** braço ("the arm that has to catch a state nobody has invented yet").
  - No preflight: `up)` faz `ok "something is listening at $app_label (APP_URL)"`. `down)` faz
    `_fail` com `E2E_CMD` e `warn` sem ele. `*)` faz `warn`.
- Default das chaves em `load_config`: `: "${E2E_CMD:=}"; : "${E2E_DIR:=e2e}"; : "${APP_URL:=}"`
  (`bin/sdd:150`). A tabela está em `config/schema.md:57` (linha do `APP_URL`) e o starter em
  `config/starter.conf:25`. O `sdd health` cobra que toda chave documentada tenha default no
  `load_config` e vice-versa (checks 4 e 6, `tests/check-health.sh:184`).
- `curl 8.5.0` está na máquina, e o `bin/sdd` **não** usa `curl` hoje. Os dois produtos usam
  `APP_URL="http://localhost:5173"` e têm `E2E_CMD` (`~/repos/lighthouse_project/.sdd/config.sh:21,25`
  e `~/repos/sales_quote/.sdd/config.sh:49,72`).
- Fixtures de app: `tests/check-preflight.sh:688-790` e `tests/check-gates.sh:954-1045`, cada um com
  um `port_is_free` próprio que acha porta livre. Nenhum sobe HTTP hoje. O mundo `wrong` precisa de
  um servidor de verdade: `python3 -m http.server <porta> --bind 127.0.0.1 --directory <dir>` em
  background, com `index.html` de outro `<title>`, espera até responder e `kill` no fim (ou em
  `trap`). O `python3` do PATH desta máquina é o `/usr/bin/python3` 3.12.3.

**Achado 6: a DOCS e o `.claude/rules/` (I4)**

- `agents/sdd-docs.md:9` é
  `writes: "$HANDOFF_DIR/$MISSION/**, README.md, CLAUDE.md, CONTEXT.md, PRODUCT.md, CHANGELOG.md, KAIZEN_LOG.md, .claude/rules/**, docs/**, $ADR_DIR/**, config/schema.md, config/starter.conf, templates/**, agents/**, .claude/agents/**"`.
  Nele, as regras do checklist (`:84-88`) dizem "no `✗` may be left".
- A guarda lê o chapéu **da fonte do kit**: `hat_field() { frontmatter "$SDD_HOME/agents/$1.md" "$2"; }`
  (`bin/sdd:1950`), por `hat_writes` (`:2099`). O espelho `.claude/agents/sdd-*.md` é cópia
  idêntica da fonte (`cmp` dos oito deu igual) e é o que o harness carrega como prompt. Mexeu em
  `agents/*.md`? Sincronize com **`./bin/sdd install --force`**, pelo Bash, no mesmo commit. Nunca
  `cp`, nunca `Edit` em `.claude/`: o headless nega esse caminho, e o `sdd preflight` fica vermelho
  com `agent <nome> stale`.
- `gate_DOCS()` vai de `bin/sdd:1560` a `:1614`. Um `awk` acha a coluna `Status` da tabela e
  imprime toda célula que não seja `✅`, `n/a` ou `N/A`. Com qualquer uma impressa, reprova com
  `45-docs.md has N area(s) pending…`. Senão, `GATE_WHY="drift checklist complete"` (`:1612`). Não
  existe `blocked` no gate da DOCS.
- Testes da DOCS em `tests/check-gates.sh:1728-1750` (`printf` de um `45-docs.md` com a tabela,
  mais `assert_phase`). O regime do chapéu fica em `tests/check-autonomy.sh:5010-5060`:
  `hat_stub <caminho> commit|leave`, `hat_rows`, `hat_reset`, e o exemplo
  `"$SDD" run "$MISSION" --phase REVIEW` seguido de `assert_eq … "3 hat-crossed" "$rc $(hat_rows)"`.
- `agents/sdd-publisher.md:57-74` (§ 4) monta o corpo do PR, e a seção "decisions for a human" fica
  na `:67`. `templates/pr-body.md:34` é `## Pendências (Decisions for a Human)`. O
  `tests/check-templates.sh` lê os headings: acrescente linhas, nunca renomeie heading.
- `config/schema.md:102` e `docs/pipeline.md:767` citam `.claude/rules/**` como exemplo de exceção
  do `HAT_WRITES_EXTRA`.

**Achado 7: o `sdd close` (I5)**

- `close_return_home()` vai de `bin/sdd:9877` a `:9893`. Sai calado sem `DEFAULT_BRANCH`, sem nome
  de branch ou **já na base**. Com árvore suja: `warn "staying on …"`. Depois
  `git checkout "$DEFAULT_BRANCH"`; se falhar, `warn "could not return…"`; senão
  `ok "back on '…' — the mission branch is merged and spent"`. O comentário acima fixa **warn,
  nunca die**.
- Chamado em `bin/sdd:9937` (issue já Done, sem sessão) e `:10061` (depois da sessão). Os dois
  ficam abaixo de `[ "$JIRA_ENABLED" = "true" ] || { info "… nothing to close"; return 0; }`: no
  kit, que tem Jira desligado, o `sdd close` nunca chega lá.
- O fixture fica em `tests/check-gates.sh:3665-3990`, bloco "sdd close: the artifact decides":
  - stubs de `acli` e `gh`, `JIRA_ENABLED=true` via `sed`, e o helper `close_run "<veredito acli…>" <rc da sessão>`, que publica `CLOSE_OUT` e `CLOSE_RC_OUT` (chamado, nunca `$( )`);
  - os regimes 8c/8d/8e (`:3946-3990`) cobrem a volta para a base num fixture **sem remoto**, e são o controle do caso "sem upstream";
  - `CLOSE_HOME` é lido da config do fixture (`:3944`).
- `grep -n "merged and spent" tests/*.sh` sai vazio: a mensagem do `ok` não tem asserção.

**Achado 8: o Python recusado (I6)**

- Do lado bash:
  - `readonly COORDINATION_PYTHON=(python3 -I -S)` fica em `bin/sdd:9718`, com uma definição para quatro sítios;
  - em `coordination_enter`, `command -v python3 >/dev/null 2>&1 || die "CHECKOUT-UNAVAILABLE: coordinated commands require Python 3 and Linux procfs"` fica em `:9753-9754`;
  - quando o helper falha, o `main` só devolve o rc, sem acrescentar texto.
- Do lado do helper (`bin/sdd-coordination.py`):
  - `:16-17` faz `sys.exit('CHECKOUT-UNAVAILABLE: Python 3.9+ is required')`;
  - `pidfd_capability()` (`:104-116`) chama `os.pidfd_open` e `signal.pidfd_send_signal` e exige `/proc/<pid>/task/<tid>/children`. Um `os` sem `pidfd_open` levanta `AttributeError`;
  - o `except (OSError, ValueError, AttributeError)` do `__main__` (`:430-437`) imprime a lista inteira de requisitos mais o erro cru.
- Sensor: `tests/check-coordination.sh:295-317`.
  - Monta um `python3` stub em `stubs/`, com shebang `#!/usr/bin/python3`, que faz `del os.pidfd_open` no mundo `missing` (e `open`, `send` e `children` nos outros três), e roda `run(repo, "phase", …)`.
  - O `run()` (`:88-92`) junta stderr em stdout, com `timeout=8`.
  - As asserções existentes são `unavailable pidfd refuses before config: <mundo>` e `help survives unavailable pidfd: <mundo>`.
  - ⚠️ No stub, `sys.executable` é `/usr/bin/python3`, e não o stub. Por isso a asserção nova lê o caminho que o **`PATH`** resolveu (o `command -v python3` do bash, ou `shutil.which('python3')` no helper, que dão a mesma resposta), nunca o `sys.executable`.
- `docs/failure-modes.md:27` é o verbete **CHECKOUT-UNAVAILABLE**.

**Backlog, registro e documentação**

- `bash tests/check-todo.sh --count TODO.md` → `83`.
- `tests/health-baseline.txt` termina em `todo-findings 83`.
- `grep -n 'RESOLVED by' TODO.md` → só a linha 693, que está na seção decidida.
- Seções `###` da parte aberta do `TODO.md`: `Sensores que faltam` (`:24`), `Contrato e configuração`
  (`:373`) e `Saída humana e cosmética` (`:470`).
- O item do achado 4 é o **primeiro** de "Sensores que faltam" (`:26-32`,
  `gate_QA aceita relatório de QA de OUTRA missão`). A penúltima linha dele é
  `  relatório com o slug da missão ou com a janela de datas dela.`
- `KAIZEN_LOG.md` vai do mais novo para o mais antigo, com heading `## YYYY-MM-DD — <título>`. O
  topo hoje é `## 2026-09-28 — O veredito da janela do juiz: …` (`:7`).
- `docs/pipeline.md` tem estas seções que mudam:
  - QA em três sub-passos: `:228-250`;
  - DOCS: `:400`;
  - `sdd close`: `:535-560`;
  - a célula do `app-down` na tabela da coluna `kind`: `:1104`.
- ADR 0013 (`docs/adr/0013-o-relatorio-da-missao-e-o-texto-proposto.md`):
  - alocada nesta sessão, `Status: proposed`, em **inglês**. O `tests/check-lang.sh` varre `docs/adr/*.md` como superfície do kit;
  - o piso de superfície do `check-lang.sh` é `if [ "$n_surface" -lt 51 ]`, e a superfície real, com a ADR 0013, é **55** (`ok 0 of 55 surface path(s)`). O I7 sobe o piso para 55.
- `.claude/rules/anatomia-do-agente.md` § 4 ("Dívida declarada") traz "As Âncoras 1 e 2 do
  `gate_QA` foram satisfeitas por relatório de **outra** missão (achado `kit:` … aberto)", que o I2
  fecha.
  - ⚠️ É caminho `.claude/`: uma sessão headless leva negativa no `Edit`. **Não contorne pelo Bash**
    (é o próprio achado 6). O I7 edita se a ferramenta deixar; se for negado, escreve o texto
    proposto no handoff de EXEC para o humano aplicar.
- Gaveta: `docs/superpowers/specs/2026-09-23-a-gaveta-do-kit.md`, linha da frente F3 no índice (`:18`
  em diante).
- O `sdd health` (catálogo inteiro, ~18 min) roda **uma vez**, depois do último commit de código
  e depois dos revisores. O `gate_PR` exige o carimbo, e ele é chaveado em `bin/ tests/ templates/ config/`.

## Arquitetura da mudança

- **Seis consertos independentes e um fechamento.** Nenhum `event` ou `kind` novo no ledger e nenhuma
  porta nova de escalada. O censo de portas do `CLAUDE.md` (5 definições, 13 portas, 4 da guarda
  de kit) não muda.
- **Um contrato fica mais estrito.** A Âncora 1 do `gate_QA` e o `qa_substep` passam a ler uma função
  só (`mission_qa_report`), com recuo para a resposta de hoje quando o range é vazio.
- **Um contrato ganha um estado.** O `app_probe` ganha `wrong`, lido pelos dois chamadores. O `wrong`
  do `gate_QA` arma o `GATE_APP_DOWN` que já existe.
- **Um contrato entre fases muda.** A DOCS deixa de escrever `.claude/rules/`. O `⛔` com texto
  proposto passa no `gate_DOCS` em voz alta, e o PR o carrega.
- **Duas mensagens passam a dizer a verdade.** O `sdd close` faz o fast-forward, e o
  `CHECKOUT-UNAVAILABLE` diz o que caiu.
- **Contrato em três lugares no mesmo commit** (CLAUDE.md): código, `docs/pipeline.md` e
  `config/schema.md` quando há chave, o agente afetado, o template afetado. Cada incremento fecha a
  própria documentação. O I7 só faz o registro transversal: backlog, KAIZEN_LOG, ADR aceita, piso de
  idioma, anatomia, `CONTEXT.md` e gaveta.

## Incrementos

A tabela executável vive em `checkpoint.md` (é ela que o runner lê). Aqui fica o **porquê** de
cada fatia — o detalhe que não cabe numa célula.

### I1 — registrar os achados 1, 2 e 5; catraca 83 → 86

**O quê:** inserir três itens na seção aberta do `TODO.md`, com o texto abaixo, **verbatim**. Ele
foi validado num clone local em 2026-09-28: `ok 86 finding(s), all within 8 lines, carrying anchor +
date, every anchor on target`. Depois, trocar `todo-findings 83` por `todo-findings 86` no
`tests/health-baseline.txt`, no mesmo commit.
- O item do achado 2 entra no **fim** de `### Sensores que faltam`, logo antes da linha
  `### Contrato e configuração`, seguido de uma linha em branco.
- Os itens dos achados 1 e 5 entram no **fim** de `### Contrato e configuração`, logo antes de
  `### Saída humana e cosmética`, nesta ordem, cada um seguido de linha em branco.
- Antes de escrever, confira duplicata: `grep -n 'GATE_EXEC_CELL\|gate_TICKET\|openbugs' TODO.md`
  (em 038a314, nenhum item aberto sobre esses três).
- Os achados 3, 4, 6, 7 e 8 **não** ganham item: esta missão os conserta. O achado 4 já tem item e
  recebe o `RESOLVED by` no I7.

Achado 2, no fim de "Sensores que faltam":

```md
- [ ] **`gate_TICKET` não confere no Jira a issue que o chapéu diz que ele confirma** — `bin/sdd:871`
  (`gate_TICKET`) — o `agents/sdd-ticket.md:18` promete que o runner confirma a issue por `acli`,
  mas o gate só lê `issue:` e `sprint:` do frontmatter do `10-ticket.md`. Uma issue duplicada (LH-5
  no lugar da LH-4) passa verde, e a LH-4 só se defendeu com um Check próprio no I1. Fail-open: o
  chapéu afirma uma medição que ninguém faz. Direção: o gate chama o `acli` (a issue existe e está
  no sprint ativo), ou o chapéu deixa de prometer.
  — descoberto por `sdd-planner` na missão `20260927-idioma-da-spa-pelo-idp` (2026-09-27)
```

Achados 1 e 5, no fim de "Contrato e configuração":

```md
- [ ] **O checkpoint não tem grafia para incremento cujo produto não é commit** — `bin/sdd:1044`
  (`GATE_EXEC_CELL`) — o `gate_EXEC` exige 7 a 64 dígitos hex na célula Commit, e o
  `templates/checkpoint.md` não diz o que escrever quando o incremento é e-mail enviado, config no
  IdP ou issue adotada. Na LH-3 o I5 foi o e-mail aos diretores, e o `sdd status` da missão aponta
  EXEC para sempre. Direção: uma grafia do kit para evidência fora do git que o gate aceite com o
  Check verde, ou a regra de que todo incremento deixa um commit de registro.
  — descoberto por `sessão coordenadora` na missão `20260922-email-mvp-diretores` (2026-09-27)

- [ ] **A Âncora 3 do `gate_QA` bloqueia a missão com bug aberto de OUTRA missão** —
  `bin/sdd:1265` (`openbugs`) — o laço conta todo bug `Status: open` do registry que não é `human`
  nem `deferred`, sem perguntar de qual missão ele é. Na LH-4 o `BUG-20260922-area-sem-edicao-de-nome`
  segurou a âncora: o `sdd-qa` não podia consertá-lo (fora do escopo) nem adiá-lo (`deferred` é
  decisão humana), e a linha parou até o humano adiar (`b816069` no alvo). Direção: missão própria,
  com ADR que supere a alternativa (A) da ADR 0006, mantida pela 0009 (contar só o bug da missão).
  — descoberto por `sdd-qa` na missão `20260927-idioma-da-spa-pelo-idp` (2026-09-27)
```

**Onde:** `TODO.md` e `tests/health-baseline.txt`.
**Como (TDD):** o Check responde `83/10/misplaced/0` antes e `86/11/placed/1` depois. As duas
respostas foram medidas em 2026-09-28: a primeira no repo, a segunda num clone com os três itens
inseridos. O `11` exige que a catraca seja **trocada**, não acrescentada: uma linha
`todo-findings`, e ela é 86. O `placed` exige a posição: o achado 2 antes de
`### Contrato e configuração`, os achados 1 e 5 nessa ordem depois dele e antes de
`### Saída humana e cosmética`.
**Check:** ver `checkpoint.md`.
**Sensor durável:** `tests/check-todo.sh` (forma, âncora e teto de 8 linhas, na suíte) e a catraca
`todo-findings` do `sdd health`.
**Reversível por:** `git revert` do commit.

### I2 — a QA só fecha com o relatório da própria missão (achado 4)

**O quê:** uma função nova, `mission_qa_report`, logo abaixo de `latest_matching`. Ela imprime o
caminho **absoluto** do relatório mais novo de `$REPO_ROOT/$QA_DOCS_PATH/reports/` que pertence à
missão, ou vazio (decisão 2):
1. `base` = `git -C "$REPO_ROOT" merge-base "$DEFAULT_BRANCH" HEAD`, com a captura guardada
   (`|| true`).
2. **Range vazio**: `base` vazio (a `DEFAULT_BRANCH` não existe localmente, ou não há histórico em
   comum) ou `base` igual a `git rev-parse HEAD`. Nesse caso devolve
   `latest_matching "$REPO_ROOT/$QA_DOCS_PATH/reports/*.md"`, a resposta de hoje, byte a byte.
3. Senão, os candidatos são duas listas somadas:
   - os caminhos de `git -C "$REPO_ROOT" -c core.quotePath=false log --diff-filter=A --name-only --format= "$base"..HEAD -- "$QA_DOCS_PATH/reports/"`;
   - os de `git -C "$REPO_ROOT" -c core.quotePath=false status --porcelain -uall -- "$QA_DOCS_PATH/reports/"`, só as linhas que começam por `??` ou por `A`.

   O **`-uall`** é obrigatório: sem ele, um diretório não rastreado aparece como o diretório, não
   como os arquivos. Só entra `*.md` que ainda exista no disco.
4. Devolve o mais novo dos candidatos pela **mesma** ordem `sort -V` do `latest_matching`, com o
   caminho absoluto.

Os dois leitores passam a chamá-la:
- **`qa_substep`**: troca `report="$(latest_matching "$qa/reports/*.md")"` por
  `report="$(mission_qa_report)"`. Com relatório vazio, `report_closed` falha e o sub-passo responde
  `exec`, que é o que se quer. O charter fica como está (decisão 3).
- **Âncora 1 do `gate_QA`**: troca o `latest_matching` pela função e mantém a variável `report`.
  - Árvore **sem** nenhum relatório: segue `no report in $QA_DOCS_PATH/reports/`.
  - Há relatórios, mas nenhum da missão: `GATE_WHY="no report of this mission in $QA_DOCS_PATH/reports/ — the newest, <basename>, was added before the mission branch (merge-base <sha curto>)"`.
  - O resto (`report_closed`, Âncora 2) segue sobre o arquivo escolhido.

O comentário da função declara:
- o resíduo: missão cuja `branch:` é a base, e `DEFAULT_BRANCH` que não existe localmente, ambos com range vazio;
- por que só `A` e não `M`: uma missão que edita o relatório de outra não vira dona dele;
- por que o charter fica fora.

**Onde:**
- `bin/sdd` (função nova, `qa_substep`, Âncora 1 do `gate_QA`);
- `tests/check-gates.sh` e `tests/check-dry-run.sh`;
- `tests/check-mutation.sh`;
- `docs/pipeline.md` (`:246`, a linha "with an interface … the most recent report" passa a dizer "the most recent report **the mission branch added**", com o recuo);
- `agents/sdd-qa.md:30` e `:46` (a linha da tabela, "dated report `**Status:** closed` in `reports/`", e a leitura do "most recent dated report"): dizer "da missão". Ressincronize o espelho com `./bin/sdd install --force`.

**Como (TDD):** as asserções vêm primeiro e ficam vermelhas antes da função existir.
- `tests/check-gates.sh`, logo depois do bloco de QA (`:604`):
  - **Mundo A.** Commita o fixture na base com um relatório `closed`, sem `Pending`, e o
    `30-handoff-qa.md` com `status: done`. Faz `git checkout -q -b missao/qa-report-owner` e um
    commit qualquer na branch.
  - Asserção `QA gate refuses a closed report added before the mission branch` sobre
    `sdd why "$MISSION" QA`: o motivo casa `before the mission branch`, e a fase é QA. Hoje passa.
  - **Mundo B.** Commita na branch um relatório novo `closed`
    (`docs/qa/reports/2026-01-02-fixture-mine.md`).
  - Asserção `QA gate accepts the closed report the mission branch added`: o motivo **não** diz
    `before the mission branch`, e o gate de QA passa (controle).
  - Volte à base e desfaça (`git checkout -q main`, `git branch -D …`) para os blocos seguintes
    acharem o fixture como antes.
- `tests/check-dry-run.sh`, logo depois do bloco `:478-496`:
  - Mesmo mundo A, com `E2E_CMD="true"`, charter e relatório `closed` commitados na base e checkout
    de uma branch de missão com um commit.
  - Asserção `a report from before the mission branch does not close the QA sub-step`:
    `projected` responde `QA:exec=<none>`. Hoje responde `QA:close=sdd-qa`.
- Os asserts atuais de QA (na base) ficam verdes sem mudança: é o recuo provado.

**Check:** ver `checkpoint.md`.
**Sensor durável:** as três asserções, mais estes mutantes no catálogo:
- `mut_QA_report_not_mission_bound`: a Âncora 1 volta ao `latest_matching`.
- `mut_QA_substep_report_not_mission_bound`: o `qa_substep` volta ao `latest_matching`.
- `mut_QA_report_counts_modified`: `--diff-filter=A` vira `--diff-filter=AM`.
- `mut_QA_report_no_fallback`: o recuo some.
  - Cuidado: sem o recuo, os asserts de QA na base ficam vermelhos. Esse é o assassino esperado.
    Confira que ele morre pelo motivo certo.

Um por leitor e um por metade do critério. Se algum sobreviver, a asserção que falta é escrita,
nunca o mutante apagado.
**Reversível por:** `git revert`. Volta o fail-open documentado no `TODO.md`.

### I3 — `APP_EXPECT`: o app que responde mas não é este produto (achado 3)

**O quê:**
- **Chave nova `APP_EXPECT`**, vazia por default (decisão 7):
  - `: "${APP_EXPECT:=}"` junto do `APP_URL` no `load_config`;
  - uma linha na tabela do `config/schema.md`, abaixo do `APP_URL`: texto literal procurado no corpo de um `GET` à `APP_URL`; opcional; vazio = só TCP;
  - `APP_EXPECT=""` no `config/starter.conf`, abaixo do `APP_URL`, com comentário curto (ex.: "o `<title>` do SPA, quando outro produto pode ocupar a mesma porta").
- **No `app_probe`, depois do connect `up`,** e só com `APP_EXPECT` não vazio:
  - `body="$(curl -sS --max-time "$APP_PROBE_TIMEOUT" "$url" 2>/dev/null)" || rc=$?`, sem `-f`: uma página 404 do outro produto também identifica.
  - `curl` ausente (`command -v curl`) ou rc ≠ 0 ⇒ `unknown|<label>: APP_EXPECT not checked (<motivo>)`.
  - Corpo com o texto (`grep -qF -- "$APP_EXPECT" <<< "$body"`) ⇒ `up|<label>`.
  - Sem o texto ⇒ `wrong|<label>`.
  - O probe continua unilateral: só `wrong` é novo, e ele só nasce com a chave declarada e o connect `up`.
- **Preflight**: braço `wrong)` antes do `*)`.
  - Com `E2E_CMD`: `_fail "something answers at <label> (APP_URL) but its page does not contain APP_EXPECT '<x>' — another product on this port? Stop it, or fix APP_URL/APP_EXPECT"`.
  - Sem `E2E_CMD`: `warn` com o mesmo texto.
- **`gate_QA`**: braço `wrong)` **antes** do `*)`. Arma `GATE_APP_DOWN=1` (a mesma escalada, sem
  porta nova) com
  `GATE_WHY="E2E_CMD failed ($E2E_CMD) and the app at $label is not this product (APP_EXPECT '$APP_EXPECT' not in the page) — no session can fix that. See $e2e_log"`.
- **Docs no mesmo commit:**
  - `docs/pipeline.md:1104`, na célula do `app-down`: "or answered without `APP_EXPECT`";
  - o parágrafo do preflight/`APP_URL` do `docs/pipeline.md`, se houver (`grep -n 'something is listening' docs/pipeline.md`);
  - `config/schema.md`.

**Onde:** `bin/sdd` (`load_config`, `app_probe`, `gate_QA`, `cmd_preflight`), `config/schema.md`,
`config/starter.conf`, `docs/pipeline.md`, `tests/check-preflight.sh`, `tests/check-gates.sh`,
`tests/check-mutation.sh`.

**Como (TDD):**
- **Em `tests/check-preflight.sh`**, no bloco `:688-790`, suba um `python3 -m http.server` numa porta
  livre (`port_is_free`), servindo um `index.html` com `<title>Other Product</title>`, e use
  `APP_URL=http://127.0.0.1:<porta>`. Asserções:
  - `a page without APP_EXPECT fails the preflight when E2E_CMD is set`: `APP_EXPECT="Fixture Product"` com `E2E_CMD` setado; o preflight sai ≠ 0 e a saída nomeia `APP_EXPECT`.
  - `an empty APP_EXPECT keeps the TCP-only probe`: `APP_EXPECT` vazio; `something is listening` e nenhum `APP_EXPECT` na saída.
  - `without curl, APP_EXPECT reads unknown and never refuses`: `PATH` sem `curl`, com a mesma técnica de PATH limitado dos outros probes do arquivo; preflight sem `_fail` do app e com `not checked`.
- **Em `tests/check-gates.sh`**, junto dos mundos de app (`:954-1045`), com e2e vermelho
  (`E2E_CMD="false"`), o mesmo servidor e `APP_EXPECT` ausente da página. Asserção
  `QA gate names the wrong app at APP_URL when the e2e is red`: `assert_why` casa `is not this product`.
- Mate o servidor no fim de cada bloco. Um servidor órfão segura a porta para o sensor seguinte.

**Check:** ver `checkpoint.md`.
**Sensor durável:** as quatro asserções, mais estes mutantes:
- `mut_APP_expect_ignored`: o `wrong` nunca nasce.
- `mut_QA_wrong_app_not_armed`: o braço `wrong` do `gate_QA` não arma o marcador.
**Reversível por:** `git revert`. Chave vazia já é hoje byte a byte.

### I4 — a DOCS propõe o que o harness recusa (achado 6)

**O quê (decisão 6):**
1. **`agents/sdd-docs.md`**:
   - tirar `.claude/rules/**` do `writes:` (manter `.claude/agents/**`);
   - no corpo, acrescentar a regra: "A path the harness refuses (`Edit`/`Write` denied, e.g.
     `.claude/rules/`) is a boundary, never an obstacle. Do not route around it through Bash
     (`python`, `sed`, redirection, `tee`, `cp`). Mark the row `⛔`, and write the exact text to apply
     under a section whose next line is `<!-- sdd:proposed -->`. The publisher carries it into the PR,
     and the human applies it there." Escrever em inglês, como o resto do chapéu;
   - nas regras do checklist, trocar "no `✗` may be left" por "no `✗` may be left; `⛔` only with its
     proposed text".
   - Depois, `./bin/sdd install --force` para o espelho.
2. **`gate_DOCS`**: o `awk` passa a separar as células `⛔` das pendentes.
   - Se sobrar pendente que não é `⛔`, é o motivo de hoje.
   - Se houver `⛔` e o arquivo **não** tiver a linha `<!-- sdd:proposed -->`: `GATE_WHY="45-docs.md has N ⛔ row(s) with no proposed text — a ⛔ needs the text to apply under a section marked <!-- sdd:proposed -->"` e reprova.
   - Com o marcador, passa em voz alta: `GATE_WHY="drift checklist complete — N ⛔ row(s) wait for a human to apply the proposed text in the PR: <docs das linhas, separados por vírgula>"`. A coluna do documento é a segunda da tabela.
   - Sem `⛔`, `drift checklist complete`, como hoje.
3. **`agents/sdd-publisher.md` § 4**: em "decisions for a human", acrescentar "every `⛔` row of
   `45-docs.md`, with its proposed text quoted, as a checklist item the human applies before the
   merge". Depois, `./bin/sdd install --force`.
4. **`templates/pr-body.md`**, sob `## Pendências (Decisions for a Human)`: uma linha-exemplo para o
   `⛔` da DOCS, sem mexer em heading.
5. **Docs no mesmo commit**:
   - `docs/pipeline.md` § DOCS (`:400`): o `⛔` e o marcador;
   - `config/schema.md:102` e `docs/pipeline.md:767`: dizer que o chapéu não declara mais `.claude/rules/**`, porque o headless o recusa; que devolvê-lo por `HAT_WRITES_EXTRA` reabre o contorno; e que isso é decisão do projeto.

**Onde:** `agents/sdd-docs.md`, `agents/sdd-publisher.md`, `.claude/agents/` (pelo
`install --force`), `bin/sdd` (`gate_DOCS`), `templates/pr-body.md`, `docs/pipeline.md`,
`config/schema.md`, `tests/check-gates.sh`, `tests/check-autonomy.sh`, `tests/check-mutation.sh`.

**Como (TDD):**
- **Em `tests/check-gates.sh`**, junto dos testes da DOCS (`:1728-1750`), no mesmo molde de `printf`
  do `45-docs.md`:
  - `DOCS gate passes a ⛔ row that carries proposed text, and names it`: tabela com uma linha `✅` e uma `⛔` com Doc `.claude/rules/x.md`, mais `## Texto proposto` + `<!-- sdd:proposed -->` + texto. `assert_why … DOCS 'wait for a human.*\.claude/rules/x\.md'`, e a fase passa da DOCS.
  - `DOCS gate refuses a ⛔ row without the proposed-text marker`: a mesma tabela sem a seção; a fase fica em DOCS e o motivo casa `no proposed text`.
  - Hoje as duas ficam em DOCS com `pending`: a primeira é vermelha antes.
- **Em `tests/check-autonomy.sh`**, no regime do chapéu (`:5010-5060`):
  - fazer `hat_reset`, `hat_stub ".claude/rules/zz-probe.md" commit` e `"$SDD" run "$MISSION" --phase DOCS`;
  - asserção `hat: a DOCS session that writes .claude/rules/ stops the line`: `assert_eq … "3 hat-crossed" "$rc $(hat_rows)"`. Hoje o caminho está no `writes:`, e o kind **não** é `hat-crossed`;
  - desfazer como os vizinhos (`git -C "$FIX" reset -q --hard HEAD~1; git -C "$FIX" clean -qfd`).

**Check:** ver `checkpoint.md`.
**Sensor durável:** as três asserções, mais estes mutantes:
- `mut_DOCS_blocked_rows_pass_without_proposal`: a exigência do marcador some.
- `mut_DOCS_blocked_rows_unnamed`: o motivo deixa de nomear as linhas `⛔`.
- O corte no `writes:` é segurado pela asserção do `check-autonomy.sh`. O catálogo muta o `bin/`, não o `agents/`.
**Reversível por:** `git revert` e `./bin/sdd install --force`.

### I5 — o `sdd close` deixa a `DEFAULT_BRANCH` em dia (achado 7)

**O quê (decisão 5):** em `close_return_home`, depois de estar na `DEFAULT_BRANCH` com a árvore
limpa, **inclusive** quando já estava nela, porque hoje a função sai cedo nesse caso e ele passa a
também fazer o fast-forward:
1. Lê o upstream: `git -C "$REPO_ROOT" rev-parse --abbrev-ref "$DEFAULT_BRANCH@{upstream}"`, com a
   captura guardada. Sem upstream ⇒ `ok "back on '…'"` como hoje, mais "no upstream, nothing to
   fast-forward".
2. `GIT_TERMINAL_PROMPT=0 timeout 30 git -C "$REPO_ROOT" fetch --quiet <remoto> <branch>`, com
   remoto e branch tirados do upstream.
   - Se `timeout` não existir, roda sem ele.
   - Falha ⇒ `warn "back on '…', but could not fetch <upstream> — run 'git pull --ff-only' by hand. git said: …"`.
3. `git -C "$REPO_ROOT" merge --ff-only --quiet "@{upstream}"`.
   - Falha (divergida) ⇒ `warn "… has diverged from <upstream>; nothing was forced — reconcile by hand"`.
   - Sucesso ⇒ `ok "back on '…', fast-forwarded to <upstream> (<sha curto>)"`, ou "already up to date" quando nada mudou.

Nunca `die`: o comentário acima da função explica o porquê e ganha um parágrafo sobre o
fast-forward. `docs/pipeline.md:535-560` diz que o close traz o merge.

**Onde:** `bin/sdd` (`close_return_home`), `tests/check-gates.sh` (bloco do close, depois do 8e),
`tests/check-mutation.sh`, `docs/pipeline.md`.

**Como (TDD):** três mundos novos com um remoto bare **local**:
- **Preparação:**
  - `git init -q --bare "$FIX/../close-remote.git"` (ou em `mktemp -d`);
  - `git -C "$FIX" remote add origin <bare>` e `git -C "$FIX" push -q -u origin main`;
  - um clone auxiliar do bare faz um commit e dá `push` (a base remota anda um commit).
- **8f.** Na branch de missão limpa, `close_run "done" 0`. Asserção
  `close: fast-forwards the default branch to its upstream`: `git rev-parse main` é igual a
  `git rev-parse origin/main`, e a saída diz `fast-forwarded`.
- **8g.** Um commit local em `main` que o remoto não tem, depois um commit remoto novo, e o close.
  Asserção `close: a diverged default branch is warned, never forced`: o sha de `main` não muda, e
  a saída casa `diverged`.
- **8h.** O fixture já em `main`, atrás, e o close. Asserção
  `close: already on the default branch it still fast-forwards`.
- No fim, `git -C "$FIX" remote remove origin`, para os blocos seguintes (e os 8c/8d/8e, que são o
  controle sem upstream) acharem o fixture como antes.

**Check:** ver `checkpoint.md`.
**Sensor durável:** as três asserções, mais `mut_CLOSE_no_fast_forward` (apaga o `merge --ff-only`).
**Reversível por:** `git revert`. O close volta a só fazer checkout.

### I6 — o `CHECKOUT-UNAVAILABLE` diz o que caiu e em qual Python (achado 8)

**O quê (decisão 4):**
- **Em `bin/sdd-coordination.py`**, a recusa passa a nomear:
  - **o requisito que caiu**:
    - `os.pidfd_open is missing from this Python build` (`AttributeError` em `os.pidfd_open`);
    - `pidfd_send_signal is missing or denied`;
    - `os.pidfd_open was denied` (`PermissionError`/`OSError` do open);
    - `procfs has no task children enumeration` (a mensagem que já existe);
    - `Python 3.9+ is required`.
  - **o interpretador**: o que o `PATH` resolveu (`shutil.which('python3')`), o `sys.executable` e a
    versão (`platform.python_version()`).
  - **o remédio**, só quando se aplica: sonda `/usr/bin/python3` (existe, e o caminho que o `PATH`
    resolveu **não** é ele) com
    `subprocess.run(['/usr/bin/python3', '-I', '-S', '-c', 'import os, signal; os.pidfd_open; signal.pidfd_send_signal'], timeout=5)`.
    Com rc 0, acrescenta `/usr/bin/python3 has it: run PATH=/usr/bin:$PATH sdd <command>`. O runner
    **nunca** usa esse interpretador.
- O prefixo `CHECKOUT-UNAVAILABLE:` e o rc 1 não mudam: os probes existentes os leem.
- O `except` do `__main__` e a checagem de versão (`:16-17`) passam pela mesma função de mensagem.
- **No `bin/sdd`**, o `die` de "sem `python3`" (`:9754`) diz que nenhum `python3` foi achado no `PATH`
  e dá o mesmo remédio quando `/usr/bin/python3` existe.
- **`docs/failure-modes.md:27`**: o verbete ganha "the message names the failed requirement and the interpreter".

**Onde:** `bin/sdd-coordination.py`, `bin/sdd` (`coordination_enter`),
`tests/check-coordination.sh`, `tests/check-mutation.sh` (opcional, ver abaixo),
`docs/failure-modes.md`.

**Como (TDD):** no laço dos quatro mundos (`tests/check-coordination.sh:305-317`), só para
`denied == "missing"`, uma asserção nova vermelha antes:
- nome: `unavailable names the failed requirement, the interpreter and the remedy`;
- exige na saída `pidfd_open`, o caminho do stub (`str(python_stub)`) e
  - `PATH=/usr/bin` **se** o `/usr/bin/python3` real tiver `os.pidfd_open` (o sensor mede isso ele mesmo, com o mesmo `subprocess`);
  - senão, a ausência de `PATH=/usr/bin`.
- Os quatro probes existentes continuam verdes sem mudança.

**Check:** ver `checkpoint.md`.
**Sensor durável:** a asserção nova. Um mutante (`mut_COORD_unavailable_generic`, que devolve a
mensagem genérica) é bem-vindo se o `sed` ancorar limpo no `.py`. O molde é
`mut_COORD_reaped_pidfd_kept` (`tests/check-mutation.sh:4372`), que muta `"${1%/*}/sdd-coordination.py"`.
**Reversível por:** `git revert`.

### I7 — fechamento: backlog, registro, ADR, idioma e anatomia

**O quê:**
1. **`TODO.md`**: no item `gate_QA aceita relatório de QA de OUTRA missão`, a linha
   `  relatório com o slug da missão ou com a janela de datas dela.` passa a terminar com
   ` RESOLVED by <sha curto do commit de código do I2>`. Validado no clone: continua
   `86 finding(s) … every anchor on target`. A catraca **não** desce: o item só sai depois do merge.
2. **`KAIZEN_LOG.md`**: entrada no topo, `## <data de hoje> — Os achados da janela: <subtítulo>`,
   com o antes/depois medido dos seis fatos da Métrica (asserção vermelha antes e verde depois,
   por incremento) e o custo da missão, se o ledger o der.
3. **ADR 0013**: `- **Status**: proposed` passa a `accepted (—, <data>)`. A seção `## Implementation`
   é conferida contra o que o I2 e o I4 fizeram, e corrigida no mesmo commit se divergiu.
4. **`tests/check-lang.sh`**: o piso `if [ "$n_surface" -lt 51 ]` passa a `55`, a superfície real
   com a ADR 0013. A mensagem `expected at least 51` passa a 55, e o comentário acima ganha uma
   linha dizendo que a ADR 0013 entrou em `20260928-os-achados-da-janela`. Antes, conte com
   `bash tests/check-lang.sh` (`0 of N surface path(s)`); se N não for 55, use N e ajuste o Check.
5. **`CONTEXT.md`**: os quatro termos da D1 do `00-missao.md` (relatório da missão, range vazio,
   app errado, texto proposto), no molde dos verbetes vizinhos.
6. **`.claude/rules/anatomia-do-agente.md`**:
   - § 4: a frase "As Âncoras 1 e 2 do `gate_QA` foram satisfeitas por relatório de **outra** missão (…; aberto)" vira "fechada em `20260928-os-achados-da-janela` (ADR 0013)";
   - § 6: uma linha sobre o `writes:` da DOCS sem `.claude/rules/**`.
   - ⚠️ Se o `Edit` for negado (headless), **não** contorne: escreva o texto exato em
     `20-handoff-exec.md`, na seção de pendências para o humano, e siga. O Check não depende disso.
7. **Gaveta** (`docs/superpowers/specs/2026-09-23-a-gaveta-do-kit.md`): na linha F3 do índice, "os
   8 achados da janela: 5 consertados nesta missão, 3 no `TODO.md`".

**Onde:** `TODO.md`, `KAIZEN_LOG.md`, `docs/adr/0013-…`, `tests/check-lang.sh`, `CONTEXT.md`,
`.claude/rules/anatomia-do-agente.md` (condicional), gaveta.
**Check:** ver `checkpoint.md`.
**Sensor durável:** `check-todo.sh` (forma do `RESOLVED by`), `check-lang.sh` (o piso novo) e
`sdd adr check` (o vínculo). O resto é prosa.
**Reversível por:** `git revert`.

## Riscos e não-feitos

| Risco | Probabilidade | Mitigação |
|---|---|---|
| Âncoras do `TODO.md` saem do alvo quando o `bin/sdd` cresce | **alta** (41 itens ancorados em linha) | `bash tests/check-todo.sh --check TODO.md` depois de cada mudança; re-ancorar no mesmo commit (ver "Contexto verificado") |
| Mutante existente deixa de aplicar (âncora de texto mudou) | média | `bash tests/check-mutation.sh --anchors` antes de cada commit de código; ajustar o `sed` do mutante, nunca apagá-lo |
| Servidor HTTP do fixture fica órfão e segura a porta | média | `trap` + `kill` no fim de cada bloco; porta escolhida por `port_is_free` |
| `git fetch` do close pendura sem rede | baixa | `GIT_TERMINAL_PROMPT=0` + `timeout 30`; aviso, nunca `die` |
| Skill de QA que não commita o relatório antes do gate | baixa | o critério aceita o arquivo novo na árvore (`??`/`A`) |
| `DEFAULT_BRANCH` sem ref local (só `origin/<b>`) cai no recuo e mantém o fail-open | baixa | declarado no comentário da função e na ADR 0013 |
| Sessão headless negada em `.claude/rules/anatomia-do-agente.md` | alta, se rodar por `sdd run` | I7 escreve o texto proposto no handoff; o Check não depende do arquivo |
| O PR do veredito não foi mergeado quando o `sdd run` começa | média | o `sdd run` cria a `fix/…` da branch corrente: rode da `main` atualizada (Pendência 1 do `00-missao.md`) |

**Não-feitos** (decisões do grill): achados 1, 2 e 5 (só registro); recuo automático de Python;
parada antes da sessão de QA; permissão do harness em `.claude/rules/`; charter amarrado à missão.

## Verificação end-to-end

1. `bash tests/run-all.sh`: verde.
2. Os sete Checks do `checkpoint.md` com o esperado.
3. `bash tests/check-mutation.sh --anchors`: todos os mutantes aplicáveis (422 + os novos).
4. `./bin/sdd adr check --mission 20260928-os-achados-da-janela --phase exec`: rc 0.
5. `bash tests/check-todo.sh --count TODO.md` → `86`; `tests/health-baseline.txt` com `todo-findings 86`.
6. `./bin/sdd health` **uma vez**, depois do último commit de código e dos revisores: `N caught of N`
   e o carimbo, que o `gate_PR` exige.
