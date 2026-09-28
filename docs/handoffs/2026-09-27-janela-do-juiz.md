# Handoff — kit congelado em `4fd0f31`: as 3 missões de alvo da janela do juiz (1 feita, a 2ª rodando)

> Escrito em 2026-09-27, ao fechar a sessão que executou e mergeou a carona (PR #172), e atualizado
> no mesmo dia, depois da missão 1. Autocontido: uma sessão nova, lendo só este arquivo, sabe o
> estado, as regras da janela e o passo a passo.
> **Não fica na `main` do kit, de propósito:** o kit está congelado, e um arquivo ali viraria commit
> na `main`. A cópia de transporte vive na branch `handoff/janela-do-juiz`, lida com `git show`, sem
> checkout (ver "Rodar uma missão da janela em OUTRA máquina").

## Estado (medido em 2026-09-27)

- **Kit `sdd_agents`:** `main` = **`4fd0f31`** (merge do PR #172), árvore limpa, carimbo do
  `sdd health` **422 caught of 422** válido sobre esse conteúdo. `TODO.md` com 83 achados, espelhado
  em 83 issues com a label `todo` (a última é a #174).
- **Decisão humana (2026-09-27): o kit CONGELOU.** Nenhum commit nem merge na `main` do kit até o
  veredito do juiz — nem chore, nem `RESOLVED by`, nem ajuste de doc. O re-sync do espelho de issues
  só mexe no GitHub e continua permitido.
- **Harness:** `claude` **2.1.283** (Claude Code).
- **Série do juiz hoje** (`./bin/sdd kaizen --series | jq .guard`, rodado do kit): `latest` ainda é
  `5cb0101`, `window_broken: true`, `floor: 3`. A 1ª missão de alvo sobre `4fd0f31` abre a janela
  nova.

## Progresso da janela (atualizado em 2026-09-28 09:10)

**JANELA COMPLETA (2026-09-28 10:50): 3 de 3, `sufficient: true`, 35 sessões, harness 2.1.283.**
O próximo passo (veredito, descongelar, achados do kit) está em
`~/.claude/plans/2026-09-28-handoff-achados-do-kit.md`. A missão 3 (SQ-146) foi mergeada no #383
(`3d80ed5b`, com status `local/ci` publicado porque o CI do Actions estava barrado por cobrança) e
fechada pelo `sdd close` (`verified=true`, US$ 13,31 no total).

**Histórico:** A série mostra `latest=4fd0f31`,
`missions_with_session: 2`, `sessions: 28`, `harness: [2.1.283]` e `sufficient: false` (piso 3).
O `window_broken: true` não é veto (`agents/sdd-kaizen.md:98`): ele conta as 7 missões gastas sobre
outras versões do kit desde o último veredito.

**Missão 2 FECHADA (22:01):** o PR #382 foi mergeado pelo humano (`3279e722`). O `sdd close` deu
`verified=true`, e a SQ-145 está Done. O close custou US$ 0,85, e a missão toda US$ 18,66.
Depois do close, a `develop` local foi avançada à mão (fast-forward) para `3279e722` (ver achado 7).

**Missão 3, RODANDO desde 2026-09-28 08:31:** `20260928-ver-vira-olho-na-lista` (**SQ-146**), no
`sales_quote`, sobre a branch `SQ-146_ver_vira_olho_na_lista`. Na lista de cotações, o "Ver" em
texto vira o ícone de olho do Claude Design (`reference_docs/design/scripts/Lista.jsx`), e as três
ações ganham `title`. Editar e Excluir mantêm os ícones e as condições de exibição. O Duplicar ficou
de fora, como item do `TODO.md` do alvo.
- O plano foi feito pelo `sdd-planner` como subagente, com o grill repassado ao humano.
- A aprovação é `humano-2026-09-28`, e o `sdd approve` exigiu o contorno do achado 8.
- O disparo foi destacado (pid 136465), com saída em
  `/tmp/claude-1001/-home-joruge-repos-sdd-agents/34fc9e24-482c-4319-bec9-887709a265c1/scratchpad/sdd-run-sq-olho.out`.
- Até 09:02: TICKET → EXEC I1, I2 → QA (o achado 4 se repetiu) → REVIEW, com US$ 5,78 e zero paradas.
- **Pipeline COMPLETO às 09:54:** zero paradas, 7 sessões, US$ 12,54. A r1 deu A em tudo, e a DOCS repetiu o
  achado 6 (python3 pelo Bash em `.claude/rules/`). O publisher abriu o **PR JRC-Brasil/sales_quote#383**.
- Revisores: o Copilot não revisou (cota), e o Codex deixou 1 P2 real. O teste do alvo de 24px amostrava
  22px: um link quadrado de 23px passava, provado por sabotagem. O conserto foi interativo, em `7bea914d`,
  medindo o lado na `boundingBox`. A mesma fraqueza do `sq122` virou item no `TODO.md` do alvo, e a thread
  foi resolvida.
- ⚠️ **O CI está BARRADO por cobrança do GitHub Actions** ("recent account payments have failed or your
  spending limit needs to be increased"), com os 4 jobs sem iniciar, tanto em `eec04271` quanto em
  `7bea914d`. Quem resolve é o humano, em Billing & plans da organização JRC-Brasil.
- **Falta:** billing → CI verde → merge pelo humano → `sdd close 20260928-ver-vira-olho-na-lista` → fast-forward
  da `develop` local (achado 7) → conferir `missions_with_session: 3` e `sufficient: true`.

**Missão 2, parcial às 19:20:** SQ-145, branch `SQ-145_breadcrumb_numero_cotacao`. Custo de
US$ 12 em 73 min até a REVIEW (US$ 12,04 às 19:00). TICKET → EXEC I1, I2 → QA. O gate de e2e
reprovou por defeito LEGADO: o `sq133` falha localmente desde a SQ-143, porque o
`loginAsConsultor` exigia "Consultor" exato e a conta B do e2e agora mostra "Consultor · Diretoria".
A QA abriu o F1, a EXEC o fechou e a r1 achou o afrouxamento do viewer que veio de carona (R1).
A r2 deu A em tudo, e às 19:07 a linha entrou na DOCS. Zero paradas até ali.

**Missão 2, pipeline COMPLETO às 19:48:** zero paradas, 11 sessões, US$ 17,81 (DOCS foi a mais
cara, com US$ 4,38 em 1179 s). O publisher abriu o **PR JRC-Brasil/sales_quote#382** contra
`develop`, com o CI verde nos 4 jobs. Revisores: o Copilot não revisou (cota), o CodeRabbit não
atua neste repo, e o Codex deixou 1 achado P2, real: um refetch que falha deixava o SQN velho na
trilha enquanto a página dizia "não encontrada". O conserto foi feito interativamente em
`028ef9d7`, com teste vermelho antes do conserto, `TEST_CMD` verde (frontend 2003 → 2004), resposta
no fio e thread resolvida.
**Missão 2, no `sales_quote`, nesta máquina: `20260927-breadcrumb-numero-cotacao` (histórico do disparo).**
- Disparada destacada: `setsid nohup`, pid **916198**. A saída do terminal está em
  `/tmp/claude-1001/-home-joruge-repos-sdd-agents/87536c7f-4b4a-49a7-ad72-0b97f810cfee/scratchpad/sdd-run-sq-breadcrumb.out` (em `/tmp`, some no reboot); a fonte é o `pipeline.log`.
- Plano aprovado (`humano-2026-09-27`), `versao: 0.9.0`. O `branch:` é placeholder: a TICKET cria a
  branch. O teto da missão é US$ 150.
- **Antes do disparo:**
  - O preflight reprovava 5 chapéus defasados (`sdd-docs`, `sdd-executor`, `sdd-kaizen`,
    `sdd-planner`, `sdd-qa`). Foram sincronizados com `sdd install --force` num PR próprio,
    **JRC-Brasil/sales_quote#381**, mergeado em `2556b99a` com o CI verde.
  - A `develop` local, com os 2 commits do plano (`b9eaf732` aprovação, `6ec10e64` artefatos), foi
    rebaseada para cima do merge e **não foi empurrada**; a missão empurra a branch dela.
  - O preflight passou (`preflight ok`), com o kit em `4fd0f31` e o `claude` em 2.1.283.
  - **Troca de app na `:5173`:** o Lighthouse ocupava a porta. O `./dev.sh` do Lighthouse foi
    encerrado e o do `sales_quote` subiu destacado (log em `/tmp/claude-1001/-home-joruge-repos-sdd-agents/87536c7f-4b4a-49a7-ad72-0b97f810cfee/scratchpad/sales-quote-dev.log`):
    `:5173` = "JRC Sales Quote", `:3000/health` = 200, `erp_api :9998` = 200. **Não suba o
    Lighthouse de volta até a QA desta missão terminar.**
- **Acompanhar sem reavaliar gates:**
  `tail -F ~/repos/sales_quote/.sdd/logs/20260927-breadcrumb-numero-cotacao/pipeline.log` e
  `sdd status --no-gates 20260927-breadcrumb-numero-cotacao`. Não rode `sdd status` nem `sdd phase`
  sem `--no-gates` com a corrida viva: eles rodam o `TEST_CMD` e o `E2E_CMD` em paralelo com ela.
- **Se parar com rc 3:** `sdd why 20260927-breadcrumb-numero-cotacao`, leia o handoff que o runner
  nomear (seção "Decisions for a Human") e o verbete de `docs/failure-modes.md` do kit.
  O que destravou a LH-4 serve de mapa:
  - **Handoff `status: blocked`:** resolva a causa. Para forçar uma sessão nova da fase, apague o
    handoff (`git rm`), porque trocar o `status:` à mão pode deixar o gate passar sem sessão.
  - **`hat-crossed` num arquivo que as regras do repo obrigam:** declare `HAT_WRITES_EXTRA` no
    `.sdd/config.sh` do alvo.
  - **Item ⛔ da DOCS em `.claude/`:** aplique o texto proposto à mão e troque para ✅ com o hash.
  - Nunca commite no alvo com a corrida viva, ou a linha para com `foreign-commit`.
- **Depois do PR:** esperar todos os revisores, consertar numa leva, mergear e rodar
  `sdd close 20260927-breadcrumb-numero-cotacao` com o harness limpo (`unset` das `CLAUDE*`).
  Conferir com `./bin/sdd kaizen --series | jq '{latest: .latest.kit_sha, guard}'`:
  `missions_with_session` tem de ir a 2.
- A 3ª missão pode ser o ui24r, na outra máquina (seção "Rodar uma missão da janela em OUTRA
  máquina").

**Missão 1, no `lighthouse_project`:** `20260927-idioma-da-spa-pelo-idp` (LH-4), fechada.
- PR #12 mergeado (`5da3f65`) e `sdd close` com `verified=true`. Custou US$ 35,91.
- A linha parou 3 vezes, todas destravadas por humano: QA por ambiente, `hat-crossed` no `DESIGN.md`
  na DOCS, e `.claude/rules/` que a sessão headless não pode escrever.
- A LH-3 do e-mail foi fechada fora do pipeline (PR #11) e não conta para a janela.

**O que ficou preparado para as próximas missões:**
- `DISABLE_AUTOUPDATER=1` no `env` do `~/.claude/settings.json`.
- No lighthouse, o `.claude/agents/index.ts` está no `.git/info/exclude` e o `HAT_WRITES_EXTRA` vale
  `"sdd-docs: packages/frontend/DESIGN.md"`.
- O `sdd run` pode ser disparado de dentro do Claude Code com
  `bash -c 'unset $(compgen -e | grep ^CLAUDE); cd <alvo> && setsid nohup sdd run <missão> > <out> 2>&1 < /dev/null & disown'`.
  Funcionou 3 vezes.
- O monitor do log precisa de `LC_ALL=C mawk -W interactive`.
- **Antes de cada missão**, confira duas coisas que o preflight não confere direito:
  - se as cópias de chapéu do alvo batem com o kit (`cmp` contra `<kit>/agents/*.md`); o preflight
    reprova, mas só se você rodá-lo;
  - se o `<title>` servido na `APP_URL` é do produto certo. O preflight aceita qualquer app na porta,
    e `sales_quote` e `lighthouse_project` usam a mesma `:5173`.

**Achados `kit:` esperando o fim da janela** (detalhe na memória `sdd-agents-janela-juiz-missao-1-lighthouse`):
1. A célula Commit de um incremento fora do git.
2. O `gate_TICKET` só lê o frontmatter.
3. O preflight aceita app de outro produto na `APP_URL`.
4. O `qa_substep` escolhe `close` com o relatório de outra missão.
5. A âncora 3 conta bug legado de outra missão.
6. (missão 2, SQ-145) O harness nega `Edit` em `.claude/rules/` na sessão headless, e o `sdd-docs`
   declara `.claude/rules/**` no `writes:` sem dizer o que fazer com a negativa. A DOCS da SQ-145
   escreveu o `.claude/rules/techspec.md` com `python3` pelo Bash, contornando a proteção
   (stream `DOCS-20260927-190735-f56b8aca`). A da LH-4 parou com ⛔ e o humano aplicou à mão.
   O chapéu precisa de UMA regra: ⛔ com texto proposto ou permissão explícita.
7. (missão 2) O `sdd close` volta para a `DEFAULT_BRANCH` só com `git checkout`, sem fast-forward
   (`bin/sdd`, o bloco antes do `ok "back on '$DEFAULT_BRANCH'…"`). A `develop` local fica atrás do
   merge, e a árvore parece ter desfeito a missão. Se a próxima missão partir dali, a TICKET cria a
   branch sobre uma base velha. **Antes de cada missão:** `git fetch && git merge --ff-only
   origin/develop` no alvo.
8. (missão 3, 2026-09-28) O requisito documentado "Python 3.9+" (README, `docs/pipeline.md`,
   `docs/failure-modes.md` CHECKOUT-UNAVAILABLE) não basta. O `COORDINATION_PYTHON=(python3 -I -S)`
   usa o primeiro `python3` do `PATH`, que no terminal do humano é
   `~/.hermes/hermes-agent/venv/bin/python3`: CPython 3.11.15 do `uv` (python-build-standalone),
   com `HAVE_PIDFD_OPEN = None` e sem `os.pidfd_open`. Resultado: TODO comando coordenado para
   naquele terminal, embora o kernel e o `/usr/bin/python3` 3.12 aceitem pidfd.
   **Contorno:** `PATH="/usr/bin:$PATH" sdd approve …` (o approve não chama `claude` nem `node`).
   O `sdd run` sai desta sessão, onde `python3` já é `/usr/bin/python3`.
   **Sugestão do humano, a mensagem dizer a causa explícita:** a saída de hoje
   (`bin/sdd-coordination.py:433`) lista todos os requisitos genéricos, incluindo "Python 3.9+", e
   no fim cola o erro cru (`module 'os' has no attribute 'pidfd_open'`). Com um 3.11 na mão, isso
   leva ao diagnóstico errado. Ela deveria nomear o requisito que falhou, o interpretador
   (`sys.executable`, a versão e o fato de ter vindo do `PATH`) e o remédio. Exemplo: "o `python3`
   em `<caminho>` (3.11.15) foi compilado sem `os.pidfd_open`; 3.9+ não basta, precisa de um build
   com pidfd, como `/usr/bin/python3`". O mesmo vale para o `die` genérico em
   `bin/sdd:9754`.

## As regras da janela (o que faz ela valer ou encalhar)

1. **3 missões de alvo com sessão sobre o MESMO `kit_sha` (`4fd0f31`).** O `kit_sha` sai do `HEAD`
   do checkout do kit no momento em que a sessão roda. Então o `~/repos/sdd_agents` fica na `main`,
   em `4fd0f31`, **limpo**, durante as 3 missões: não troque de branch nele e não edite nada ali.
   Dois alvos (`lighthouse_project` e `warehouse_explorer_api`) usam symlinks para os chapéus do
   kit, então trocar a branch do kit muda o chapéu que eles vestem.
2. **Uma única versão do harness na fatia.** Uma fatia com duas versões do `claude` sai
   `harness_mixed` e o veredito fica `indeterminado`. Confira `claude --version` antes de cada
   missão e segure a auto-atualização do Claude Code durante a janela (por exemplo com
   `DISABLE_AUTOUPDATER=1` no ambiente). Se a versão mudar no meio, anote: a janela precisa recomeçar.
3. **Achado de kit durante as missões vai para o handoff da missão**, marcado `kit:`, e espera o fim
   da janela. Nunca um commit no kit (o runner para a linha com `kit-touched` se uma sessão tentar).

## Os candidatos a alvo (medido agora, nada foi tocado)

| Alvo | Jira | Chapéus em `.claude/agents/` | Estado do checkout | O que falta antes do `/sdd-plan` |
|---|---|---|---|---|
| `sales_quote` | ligado (SQ, board 51) | **cópias**, 5 defasadas (`sdd-docs`, `sdd-executor`, `sdd-kaizen`, `sdd-planner`, `sdd-qa`) | `develop` limpo (`4fdb70bb`) | `sdd install --force` no alvo e um PR só com o espelho, como os #140/#141 |
| `lighthouse_project` | ligado (`BUDGET_MISSION_USD=230`) | symlinks para o kit (atuais) | branch `LH-3_email-mvp-diretores`, `.claude/agents/` **não versionado** | decidir a branch base (`develop`?) e o que fazer com o `.claude/agents/` não versionado |
| `warehouse_explorer_api` | **desligado** | symlinks para o kit (atuais) | branch `chore/todo-esqueleto`, 2 arquivos sujos (`jest.config.js`, `package.json`) | resolver a sujeira; o plano **precisa** de `branch:` real (regra nova, ver abaixo) |
| `erp_api` | — | kit **não instalado** | `develop`, 4 arquivos sujos | `sdd install` + `sdd preflight` (custam zero); o `vitest` puro do `test` agora é seguro |

⚠️ Com os chapéus ligados por symlink, **nunca** rode `sdd install --force` de outro checkout do kit
(worktree, versão instalada) nesses alvos: um `cp` sobre o symlink escreve no kit (issue #173). O
`sdd` do `PATH` (`~/.hermes/bin/sdd`) resolve para `~/repos/sdd_agents/bin/sdd`, que é o certo.

## O que o kit `4fd0f31` faz de diferente do que as missões anteriores viram

- **Sem Jira, o plano precisa de `branch:` real.** `gate_PLAN` recusa `branch:` vazio ou o
  placeholder `<…>` quando `JIRA_ENABLED` não é `true`, e diz o remédio. Com Jira ligado nada muda
  (a TICKET cria a branch). Vale para o `warehouse_explorer_api`.
- **`sdd approve` sem resposta sai 66.** Rode o `sdd approve` num terminal de verdade; de dentro do
  Claude Code (stdin `/dev/null`) ele agora recusa com rc 66 em vez de fingir um "N".
- **`foreign-commit` é um `kind` novo de parada (rc 3).** Toda sessão grava o rótulo
  `sdd:<passo>:<sid8>` no reflog, e um commit **sem** esse rótulo feito no checkout enquanto uma fase
  roda, fora do `writes:` do chapéu, para a linha como `foreign-commit`, com o commit nomeado. Não
  commite no checkout do alvo enquanto um `sdd run` estiver rodando. O remédio está em
  `docs/failure-modes.md` → "The line stopped with `foreign-commit`".
- **O `TEST_CMD` roda com stdin em `/dev/null`**, nos gates, no `E2E_CMD` e no preflight: um test
  runner em modo watch não pendura mais o gate.
- **`**Spec:**` e caminho entre crases** passam no `sdd adr check`; nota e Status entre crases são
  lidos como o valor no `gate_REVIEW` e no `gate_DOCS`.

## Passo a passo da missão de alvo

1. **Nada rodando:** `ps -eo pid,etime,cmd | grep -E 'bin/sdd (run|retry|health)' | grep -v grep`
   tem de voltar vazio antes de tocar no alvo.
2. **Conferir a janela:** `git -C ~/repos/sdd_agents log --oneline -1` → `4fd0f31`, árvore limpa;
   `claude --version` → `2.1.283`.
3. **Preparar o alvo** (linha da tabela acima). No `sales_quote`: `sdd install` mostra o diff,
   `sdd install --force` adota, e o espelho vai num PR próprio contra `develop` antes da missão.
4. **Preflight:** `env -u CLAUDECODE sdd preflight` na raiz do alvo, que tem de terminar em
   `preflight ok`. O preflight abre uma sessão `claude` real, curta, para conferir o chapéu do
   executor.
5. **Planejar com o humano:** `/sdd-plan` no alvo (o `sdd-planner`, interativo). Com Jira ligado o
   plano leva `versao:`; com Jira desligado, `branch:` real.
6. **Aprovar:** `sdd approve <missão>` **no terminal do humano**.
7. **Rodar:** `sdd run <missão>` **no terminal do humano**, nunca como tarefa de fundo do Bash tool
   de uma sessão do Claude Code: o `claude -p` aninhado herda o socket do harness e morre. Se tiver
   de sair de dentro do Claude Code, use `setsid nohup` com `env -u CLAUDECODE -u CLAUDE_CODE_*`.
8. **Acompanhar:** `tail -F .sdd/logs/<missão>/pipeline.log` e `sdd status --no-gates <missão>`
   (este não reavalia gates nem roda o `TEST_CMD`). Em rc 3, `sdd why <missão>` e o verbete de
   `docs/failure-modes.md` do kit.
9. **Fechar:** merge do PR do alvo pelo humano, e depois `sdd close <missão>` (com Jira). O `sdd
   close` só carimba o fechamento se o ticket já estiver Done.
10. **Progresso da janela:** do kit, `./bin/sdd kaizen --series | jq '{latest: .latest.kit_sha,
    guard}'`. A janela está completa quando `latest` é `4fd0f31` e `guard.sufficient` é `true`
    (`missions_with_session` ≥ 3, um harness só).

## Rodar uma missão da janela em OUTRA máquina

O juiz lê o ledger `${SDD_STATE_DIR:-$HOME/.sdd}/autonomy-log.jsonl`, que é **um arquivo por máquina**
(`docs/pipeline.md`, "this ledger is one file per machine"). A missão 1 está no ledger da máquina onde
este handoff nasceu. Uma missão rodada em outra máquina só conta se as linhas dela forem trazidas para
o ledger onde o `sdd kaizen` vai rodar.

**Antes, na outra máquina:**
1. Kit em `4fd0f31` e limpo: `git -C <kit> fetch && git -C <kit> checkout main && git -C <kit> pull --ff-only`.
   `git -C <kit> log --oneline -1` tem de responder `4fd0f31`.
   ⚠️ **Nunca** faça checkout desta branch de handoff nesse checkout: o `kit_sha` sai do `HEAD`. Para
   ler este arquivo, use `git -C <kit> show origin/handoff/janela-do-juiz:docs/handoffs/2026-09-27-janela-do-juiz.md`.
2. O `sdd` do `PATH` resolve para `<kit>/bin/sdd`: confira com `readlink -f "$(command -v sdd)"`.
3. `claude --version` → **2.1.283**, a mesma versão da missão 1. Com outra versão, a fatia sai
   `harness_mixed` e o veredito fica `indeterminado`. Segure a atualização com
   `"env": {"DISABLE_AUTOUPDATER": "1"}` no `~/.claude/settings.json` daquela máquina.
4. No alvo, siga o passo a passo deste handoff: `sdd install`, `env -u CLAUDECODE sdd preflight`,
   `/sdd-plan`, `sdd approve` e `sdd run`.

**Depois do `sdd close`, trazer as linhas da missão para o ledger do juiz:**
```bash
# na outra máquina
jq -c 'select(.mission=="<missão>")' ~/.sdd/autonomy-log.jsonl > ledger-<missão>.jsonl
wc -l ledger-<missão>.jsonl        # sessões + escaladas + close

# na máquina do juiz (backup antes; o arquivo é append-only)
cp ~/.sdd/autonomy-log.jsonl ~/.sdd/autonomy-log.jsonl.bak-antes-de-<missão>
cat ledger-<missão>.jsonl >> ~/.sdd/autonomy-log.jsonl
./bin/sdd kaizen --series | jq '{latest: .latest.kit_sha, guard}'   # missions_with_session sobe 1
```
Antes de anexar, confira que todas as linhas têm `kit_sha: "4fd0f31"` e `harness: "2.1.283"`
(`jq -r '[.kit_sha, .harness] | @tsv' ledger-<missão>.jsonl | sort | uniq -c`). O `repo` delas carrega
o caminho da outra máquina; o juiz lê todos os repos (ADR 0005), então isso não as exclui.

## Depois das 3 missões

- **Com o veredito escrito, e só então:** tirar o `"DISABLE_AUTOUPDATER": "1"` do `env` do
  `~/.claude/settings.json`. O backup de antes da janela é `~/.claude/settings.json.bak-2026-09-27`,
  e o `env` só tem essa chave. Tirar antes quebra a regra de um harness só.

- `sdd kaizen` **no terminal do humano**, numa branch `kaizen/…` do kit (~US$ 5 por veredito, teto
  US$ 15). Ele escreve o veredito sobre `4fd0f31`. O merge dessa branch descongela o kit.
- **Decisão humana de 2026-09-28: os achados `kit:` desta janela (hoje 8) viram itens do `TODO.md`
  do kit e depois vão para o GitHub com `/todo-to-github-issues`.** Isso só acontece com o kit
  descongelado, porque um commit na `main` durante a janela mudaria o `kit_sha` das sessões. Ordem:
  1. Um item por achado, no formato do `templates/todo.pt-BR.md` (até ~6 linhas, âncora, sem
     duplicar item que já exista no `TODO.md`), conferidos por `bash tests/check-todo.sh`.
  2. A catraca do backlog se move, então `tests/health-baseline.txt` muda junto, num diff com autor.
  3. Abrir o PR, esperar os revisores, consertar tudo numa leva, rodar o `sdd health` UMA vez
     depois do último commit de código e mergear.
  4. Só depois do merge, rodar o `/todo-to-github-issues` a partir da `main`. O espelho lê o
     arquivo da `main`: rodado antes, criaria issues sem item no `TODO.md`.
- Ficam para depois do veredito: a T3 (três decisões humanas de desenho, via `/sdd-plan` no kit) e
  dois minors adiados da carona — a janela do reflog faz um `grep` por caminho (~4 ms por caminho,
  só pesa em diffs de milhares de arquivos) e o item do `--with-mutation` no `TODO.md` cita números
  de linha vizinhos dos certos.

## Onde está cada coisa

- Missão da carona: `~/repos/sdd_agents/docs/handoffs/20260926-a-carona-antes-do-congelamento/`
  (`00-missao.md`, `01-plano.md`, `checkpoint.md`, `checkpoint-notas.md`); ADR 0012
  (`docs/adr/0012-o-commit-tem-dono.md`); `KAIZEN_LOG.md` (entrada de 2026-09-26).
- Índice das frentes paradas do kit: `docs/superpowers/specs/2026-09-23-a-gaveta-do-kit.md`, onde a F3
  marca o congelamento a partir do merge da carona.
- Memória do projeto: `sdd-agents-kit-congelado-4fd0f31.md` e `sdd-agents-pr-de-carona.md`.
