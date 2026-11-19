---
missao: 20261117-o-worker-orquestrador
data: 2026-11-17
---

# Plano — O worker orquestrador

> **Teste de autocontenção:** uma sessão nova, sem nenhuma memória da conversa que gerou este
> plano, lendo apenas `00-missao.md` + `01-plano.md` + `checkpoint.md`, consegue executar?
> Se a resposta for "só se souber X", **X vai escrito aqui**.

## Contexto verificado (não re-descobrir)

Tudo abaixo foi medido em 2026-11-17, no worktree `/home/joruge/repos/sdd_agents-worker`, branch
`feat/o-worker-orquestrador`, cortada de `origin/main` em `5221477`.

### Onde você está e o que não pode tocar

- **Você roda num worktree ligado do próprio kit.** O `sdd` do PATH (`/home/joruge/.hermes/bin/sdd`)
  resolve para `/home/joruge/repos/sdd_agents/bin/sdd`, o checkout **principal**. É esse `bin/sdd`
  que está executando esta missão. **Nunca escreva, commite ou rode `git` com efeito no checkout
  principal** (`/home/joruge/repos/sdd_agents`): a guarda de kit para a linha com `KIT-TOUCHED`.
  Todo comando seu roda a partir da raiz do worktree. Arquivo de rascunho vai para `mktemp -d`.
- **Esta missão não edita `bin/sdd` nem `agents/*.md`.** O programa novo é `bin/sdd-worker`. Se um
  incremento parecer pedir mudança em `bin/sdd` ou num chapéu, pare e registre nas notas: não é
  escopo. Sem tocar `agents/`, o espelho `.claude/agents/` não precisa de `sdd install --force`.
- **`.claude/` é intocável em sessão headless.** `Edit` e `Write` ali são recusados, e contornar
  pelo `Bash` para a linha como `hat-crossed`. A rule `.claude/rules/anatomia-do-agente.md` recebe
  texto proposto pela fase DOCS (linha ⛔), nunca por um incremento.
- **`Edit` exige `Read` prévio** em `claude -p`. Leia o arquivo antes de editar.
- Config do kit (`.sdd/config.sh`): `TEST_CMD="tests/run-all.sh"`, `HANDOFF_DIR="docs/handoffs"`,
  `TODO_FILE="TODO.md"`, `DEFAULT_BRANCH="main"`, `OUTPUT_LANG="pt-BR"`, `JIRA_ENABLED=false`,
  `ADR_CHECK="block"`, `ADR_DIR="docs/adr"`. Não há `ON_ESCALATION_CMD` nem `BUDGET_MISSION_USD` no
  arquivo: valem os defaults do `config/starter.conf` (`ON_ESCALATION_CMD=""` na linha 105,
  `BUDGET_MISSION_USD=150` na linha 100).
- O kit **não instala** arquivo de `commands/` em lugar nenhum (nem o `sdd-plan.md`): não há espelho
  a sincronizar para `commands/sdd-worker.md`.

### Idioma e nomes (regra do `CLAUDE.md`, cobrada por `tests/check-lang.sh`)

- **Inglês:** `bin/sdd-worker` (código, comentários, mensagens), `commands/sdd-worker.md`,
  `tests/check-worker.sh`, `docs/pipeline.md`, `README.md`, `config/schema.md`, `docs/adr/*.md`,
  nomes de arquivo, chaves de frontmatter novas, nomes de nível e de ato.
- **pt-BR:** `templates/*.md` (prosa), `docs/superpowers/**`, `CONTEXT.md`, `TODO.md`,
  `KAIZEN_LOG.md`, mensagens de commit, os handoffs desta missão.
- `tests/check-lang.sh:67` (`SURFACE_SPECS`) lista a superfície; `bin/sdd-worker` entra nela.
  `tests/check-lang.sh:73` (`LANG_DECLARED=(docs/handoffs/ docs/qa/ docs/superpowers/)`) lista as
  subárvores em pt-BR. **A campanha do kit mora em `docs/superpowers/campaigns/`**, que já está
  declarada: assim `LANG_DECLARED` não muda, e o `bin/sdd` (`health --release`, linha 5, que deixa
  fora as mesmas três subárvores) também não.

### Onde um sensor novo entra (a suíte nomeia cada lugar esquecido em vermelho)

`tests/check-worker.sh` é o décimo sétimo sensor. Os lugares, com a âncora de hoje:

1. `tests/run-all.sh:383` é a última linha `run "<título>" "$ROOT/tests/check-….sh"`; a do sensor
   novo vem depois dela, com o título `the worker answers from artifacts`.
2. `tests/run-all.sh:176` (`step_timeout`): passo sem linha na tabela é recusado. Use `120`.
3. `tests/run-all.sh:255` (`LINT_FLOOR=20`): sobe para 22 (o sensor e `bin/sdd-worker`), e
   `lint_surface` (linha 257) ganha `"$ROOT/bin/sdd-worker"` na lista inicial de arquivos.
4. `tests/check-pipefail.sh`: a superfície é `ls -1 bin/sdd bin/sdd-link-agents tests/*.sh` (linha
   459) e ganha `bin/sdd-worker`; o piso é **19** (`-lt 19` na linha 968, e o mesmo número na
   mensagem da 969) e sobe para **21**; o fixture do selftest (linha 898-899) cria os mesmos
   arquivos no piso, e ganha `bin/sdd-worker` e mais um `tests/check-<n>.sh`. Os três sobem juntos,
   ou três probes falham com `surface shrank`.
5. `tests/check-checkpoint.sh:1526` (`CALIBRATE_FLOOR=16`): sobe para 17.
6. `tests/check-health.sh:1950` (`GITENV_FLOOR=17`): sobe para 18. A linha
   `. "$(dirname "${BASH_SOURCE[0]}")/isolate-git.sh"` vem logo abaixo do `set -uo pipefail` do
   sensor novo, como em `tests/check-adr.sh:210-211`. **O sensor usa `set -uo pipefail`, sem `-e`**
   (o `fail()` conta e segue); `bin/sdd-worker` usa `set -euo pipefail`.
7. O censo de `tests/check-health.sh` (`CENSUS_FLOOR=9`, linha 2163) anda pela suíte sozinho: o
   `fail()` do sensor novo tem de parar no primeiro vermelho sob `SDD_MUTANT`. Copie a forma de
   `tests/check-adr.sh:230-232` (`fail() { PROBES=…; …; [ -z "${SDD_MUTANT:-}" ] || exit 1; }`). O
   número 9 é piso e **não se mexe**, a menos que a suíte o nomeie em vermelho.
8. `tests/check-lang.sh:67`: `bin/sdd-worker` em `SURFACE_SPECS`.
9. O catálogo: cada mutante é uma função `mut_<SLUG>() { sed -i '…' "<arquivo>"; }` em
   `tests/check-mutation.sh`, e o slug (sem o `mut_`) entra no array `CATALOG=(`, que vai da linha
   6853 à 7667. Acrescente os slugs novos **no fim**, antes do `)`; a ordem não importa. O `"$1"`
   da função é a cópia de `bin/sdd`; um mutante de outro programa de `bin/` usa `"${1%/*}/<nome>"`,
   como `mut_COORD_environment_only` (linha 6523) faz com `sdd-coordination.py`. Os desta missão
   usam `"${1%/*}/sdd-worker"` e o prefixo `mut_WORKER_`.

Modelo de sensor: `tests/check-adr.sh` (cabeçalho com as regras numeradas, `ok()`/`fail()`,
fixtures em `mktemp -d`). Toda linha verde é `  ok    <asserção>` na stdout (dois espaços, `ok`,
quatro espaços) e toda vermelha é `  FAIL  <asserção>` na stderr.

**Prova de um mutante, antes do commit:** `tests/check-mutation.sh --only <SLUG> check-worker.sh`
(segundos). O sensor é **só o nome do arquivo**: com `tests/` na frente o comando recusa com rc 2
(`tests/check-mutation.sh:8194`). É dica, não carimbo. O `./bin/sdd health` **não** roda nesta
missão.

### Armadilhas de bash desta casa (nenhuma é pega por `bash -n`)

- `x="$(cmd)"` sob `set -e` mata o processo se `cmd` devolve não-zero: guarde com `|| rc=$?` ou
  `if out="$(…)"; then`.
- Nunca `printf … | grep -q` (devolve 141 quando acha). Use herestring: `grep -q x <<< "$v"`.
- `cd` com operando relativo dentro de `$(…)` leva `CDPATH=''`. Cobrado pelo `check-pipefail.sh`.
- O `awk` é o `mawk`, orientado a byte: classe negada só com ASCII; separador literal por
  `index()`/`substr()`.
- Função lida como `x="$(f)"` roda em subshell: atribuição a global morre ali.
- Nenhum comentário `#` dentro de bloco continuado por `\`.
- A última linha de `bin/sdd-worker` é `{ main "$@"; exit $?; }`, pela mesma razão do `bin/sdd`.
- Antes de cada commit em `bin/` ou `tests/`: `shellcheck -S warning <arquivos tocados>`.
- Um hook do checkout limpa sandboxes a cada commit: não deixe fixture fora de `mktemp -d`.
- Sabotagem manual de `tests/` roda sem `SDD_MUTANT` no ambiente, e o probe prova primeiro que
  sabotou o que dizia sabotar (ancore em código, nunca em número de linha).

### Âncoras do `TODO.md`

O `TODO.md` ancora itens em `` `arquivo:N` (`símbolo`) ``, e quase todo arquivo que esta missão
edita é ancorado por algum item. Dois deslocamentos são certos: `templates/missao.md:41` (o item
da linha 406 do `TODO.md`) anda duas linhas no I1, e `tests/run-all.sh:292` (o item da linha 653)
anda no I2. **Regra para todo incremento, antes do commit:** `tests/check-todo.sh --anchors TODO.md`
tem de dizer `0 off target` (hoje diz `83 measured, 0 off target`). Se não disser, corrija só o
número `N` da âncora no `TODO.md`, no mesmo commit, e não mexa em mais nada do item. A catraca
(`tests/health-baseline.txt`, `todo-findings 83`) não muda: nenhum item entra ou sai.

### O que os verbos leem de fora (formatos reais)

- **Ledger:** `${SDD_STATE_DIR:-$HOME/.sdd}/autonomy-log.jsonl` (`bin/sdd:3666`), uma linha JSON por
  evento. As chaves que interessam: `mission` (o id) e `cost_usd` (número; linhas de sessão e de
  `close` o carregam, as outras trazem `null`).
- **Recibo do Codex:** um comentário de issue do usuário `chatgpt-codex-connector[bot]` cujo corpo
  começa com `<!-- codex-pull-request-review-summary -->` e traz, na linha seguinte, o estado de
  máquina. Copiado do PR 409 deste repo (`gh api repos/j0ruge/sdd_agents/issues/409/comments`):
  `<!-- codex-review-state:v1 {"code_review":{"commit_sha":"a0bf8e9d8f09a88c8997bbf8356fca7a1d5ed6cd","has_any_findings":false,"has_unresolved_findings":false,"status":"completed"},"security_review":{"commit_sha":null,"has_any_findings":null,"has_unresolved_findings":null,"status":null}} -->`.
  **A fixture do sensor é copiada dessa fonte.** Não a escreva de memória.
- **Bot que não revisou:** no mesmo PR, `gh api repos/j0ruge/sdd_agents/pulls/409/reviews` devolve
  uma review `COMMENTED` do `copilot-pull-request-reviewer[bot]` cujo corpo diz "Copilot was unable
  to review this pull request because the user who requested the review has insufficient remaining
  quota". O `pr-ready` **não lê review de bot nenhum além do estado do Codex**: é por isso que cota
  esgotada não bloqueia nem conta como revisão.
- **PR:** `gh pr view <n> --json headRefOid,mergeable,state` devolve, para um PR aberto e limpo,
  `"mergeable":"MERGEABLE"` e `"state":"OPEN"`; para o PR 409, já mergeado, devolve
  `"mergeable":"UNKNOWN"` e `"state":"MERGED"`.
- **Threads:** `gh api graphql -f query='query{repository(owner:"<o>",name:"<r>"){pullRequest(number:<n>){reviewThreads(first:100){nodes{isResolved}}}}}'`.
- **Dono e nome do repo:** `gh repo view --json nameWithOwner -q .nameWithOwner`.
- **Todo `gh` roda com o cwd na raiz do repo** (o `gh` infere o repositório do remote). No sensor
  ele é um stub: um script num diretório posto na frente do PATH, como em
  `tests/check-gates.sh:3406` (`cat > "$FIX/.stub/gh" <<'STUB'`). A fixture não precisa de remote.
- **Tabela de notas:** `templates/review.md:54` tem o heading literal `### Overall Grade` e uma
  tabela com as colunas `Criterion`, `Grade`, `Rationale`. A fixture do sensor copia essa tabela.
- **`sdd approve`** sai com 66 e não escreve nada quando não lê nenhum caractere no stdin
  (`bin/sdd:9319`); `n` e Enter saem 0. O `delegate` copia esse contrato: **aceita pipe**, não exige
  TTY.
- `tests/fixtures/` já existe (três arquivos).

### Vocabulário

"Worker" já existe em `docs/pipeline.md:54-79` com outro sentido: o processo Bash que o supervisor
da coordenação de checkout vigia. O verbete novo do `CONTEXT.md` (que tem o heading
`## Glossário` na linha 7) separa os dois: **worker da campanha** (a sessão orquestradora e o
`bin/sdd-worker`) e **worker da coordenação** (o processo).

## Arquitetura da mudança

Dois arquivos novos de programa, três templates tocados, um sensor, e documentação.

```
commands/sdd-worker.md   prosa: o laço que a sessão segue (inglês)
bin/sdd-worker           bash: seis verbos, só leitura, menos `delegate` (inglês)
templates/campaign.md    a fila de lotes de uma campanha (pt-BR, chaves em inglês)
templates/delegation.md  a delegação de uma campanha
templates/missao.md      ganha duas chaves opcionais: campaign:, lot:
tests/check-worker.sh    o sensor, com mutantes mut_WORKER_* no catálogo
docs/superpowers/campaigns/20261117-zerar-as-issues/   a campanha do kit, sem assinatura
```

### O diretório de uma campanha

Um diretório qualquer do repo-alvo (a convenção para alvos é `docs/campaigns/<YYYYMMDD>-<slug>/`;
a do kit é `docs/superpowers/campaigns/<YYYYMMDD>-<slug>/`), com `campaign.md`, `delegation.md` e,
quando o worker começa, `journal.md` (uma linha por evento, append-only, hora tirada de `date`).
**Todo verbo, menos o `pr-ready`, recebe esse diretório como primeiro argumento.** Não há chave de
config para ele. A raiz do repo sai de `git -C <dir> rev-parse --show-toplevel`; `HANDOFF_DIR` e
`ON_ESCALATION_CMD` saem do `.sdd/config.sh` dessa raiz, lidos num subshell
(`( set +eu; . "$cfg"; printf '%s' "${KEY-}" )`), por UMA função; `HANDOFF_DIR` ausente vale
`docs/handoffs`.

### `campaign.md` (contrato)

Frontmatter: `campaign:` (o id, igual ao nome do diretório), `title:`, `date:`, `harness:`
(`claude`), `plan_model:` (`fable`), `exec_model:` (`opus`). Corpo: o heading `## Lotes` seguido de
uma tabela `| Lot | Título | Ceiling | Itens |`, uma linha por lote, na ordem da fila. `Lot` é
`L<n>`. `Ceiling` é `-` ou o nome de um nível. `Itens` é a contagem. Depois, um `### L<n>` por
lote, com os itens como `- [ ] <título>`; item cuja escolha fica com o planner leva `◆ ` logo
depois do `- [ ] `.

### `delegation.md` (contrato)

Frontmatter, e só ele é lido:

```
campaign: <id>
level: <assisted | pr | plan | merge | full>
lots: <all, ou L1 L2 … separados por espaço>
expires: <YYYY-MM-DD HH:MM, hora local>
budget_mission_usd: <número>
budget_campaign_usd: <número>
signed:
```

- O valor de uma chave é o texto depois do primeiro `: `, sem os espaços do fim. Sem aspas.
- **Legível** quer dizer: as seis primeiras chaves presentes e não vazias, `level` na escada,
  `expires` casando `^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}$`, e os dois tetos casando
  `^[0-9]+(\.[0-9]+)?$`. Um placeholder `<…>` do template é, portanto, ilegível.
- `signed:` vazio é delegação sem assinatura. O `delegate` grava
  `signed: <YYYY-MM-DD HH:MM> <digest>`: a hora da assinatura e os 12 primeiros hex do `sha256sum`
  das seis primeiras linhas, na ordem acima, cada uma escrita como `chave: valor` e um `\n`. UMA
  função calcula o digest para os dois leitores (`delegate` e `level`).
- `level: assisted` pode ser assinado (não concede nada).

### O relógio

UMA função `now` devolve `date '+%Y-%m-%d %H:%M'`. Ela honra a variável `SDD_WORKER_NOW` **só
quando o valor é posterior ao relógio real** (comparação de texto, mesmo formato): a costura serve
para o sensor adiantar o tempo e ver uma delegação vencer, e nunca para ressuscitar uma vencida.

### Os seis verbos

Uso errado, verbo desconhecido ou diretório que não existe: uso na stderr e rc 2. O motivo de uma
resposta vem depois de ` — `.

| Verbo | Stdout | rc |
|---|---|---|
| `delegate <dir>` | as seis linhas `chave: valor`; depois `signed <arquivo> — commit it: git add <arquivo> && git commit -m "…"` ou `not signed — <motivo>` | 0 assinou, ou a resposta não foi `y`; 1 delegação ilegível ou já vencida; 66 nenhum caractere no stdin |
| `level <dir> [--lot L<n>]` | `level <nome> — <motivo>` | 0 |
| `allows <dir> <ato> [--lot L<n>]` | `allowed <ato> at <nível>` ou `ask <ato> needs <mínimo>, effective <nível> — <motivo>` | 0 permitido; 1 volta ao dono |
| `budget <dir>` | `campaign US$ <gasto> of <teto> — <n> mission(s); mission cap US$ <teto>` | 0 abaixo do teto; 1 no teto, acima dele, ou delegação ilegível (`no ceiling — illegible`) |
| `next <dir>` | `<ato> <lote> <missão ou -> — <motivo>`, e uma segunda linha `ahead plan <lote>` quando cabe | 0; 1 quando a linha é `stop …`; 3 quando o `gh` não respondeu |
| `pr-ready <dir-da-missão> <pr>` | `ready <sha completo>` ou `not-ready <item>: <motivo>` | 0 pronto; 1 não pronto; 3 o `gh` não respondeu |

O `delegate` escreve a pergunta (`Sign this delegation? [y/N] `) na **stderr** e lê UMA linha do
stdin. Não lê o `.sdd/config.sh` e não commita. Valores em dólar saem com duas casas
(`LC_ALL=C printf '%.2f'`).

**A escada** é uma definição: `assisted pr plan merge full`, nessa ordem. Nome fora dela não é
nível. **A tabela de atos** é outra definição, positiva (o ato é permitido porque um nível o nomeia):

| Ato | Nível mínimo |
|---|---|
| `run`, `pr`, `review` | `pr` |
| `plan` | `plan` |
| `merge`, `postmerge` | `merge` |
| `approve` | `full` |

Ato fora da tabela é rc 2, nunca "permitido".

**Nível efetivo** (`level`), nesta ordem, o primeiro motivo que casar decide:
1. sem `delegation.md` → `assisted — no delegation`;
2. delegação ilegível (definição acima) → `assisted — illegible`;
3. `signed:` vazio → `assisted — unsigned`;
4. o digest gravado difere do recalculado → `assisted — edited after signing`;
5. `expires` menor ou igual a `now` (comparação de texto) → `assisted — expired`;
6. nível acima de `assisted` e `ON_ESCALATION_CMD` vazio → `assisted — no pager`;
7. com `--lot`: lote fora de `lots:` (e `lots:` não é `all`) → `assisted — lot not covered`;
8. com `--lot`: o `Ceiling` do lote em `campaign.md` é um nível mais baixo que o assinado → esse
   nível, `— capped by the lot`. O teto nunca sobe o nível.
9. senão, o nível assinado, `— signed until <expires>`.

**`budget`** soma, com `jq` (nunca `awk`: sob pt-BR o `mawk` lê `1.99` como 1), o `cost_usd` das
linhas do ledger cujo `mission` é uma missão da campanha: as pastas de `<raiz>/<HANDOFF_DIR>/*/`
cujo `00-missao.md` declara `campaign: <id>`. Ledger ausente é gasto 0.

**`next`** percorre os lotes na ordem da tabela e para no primeiro que não está mergeado. A missão
de um lote é a pasta cujo `00-missao.md` declara `campaign: <id>` e `lot: <L>`; a branch é o
`branch:` do mesmo frontmatter; os PRs saem de
`gh pr list --head <branch> --state all --json number,state`.
- nenhuma missão → `plan <L> -`;
- missão com `aprovacao:` vazio → `approve <L> <missão>`;
- aprovada e nenhum PR → `run <L> <missão>`;
- algum PR `MERGED` → lote feito, segue; todos os lotes feitos → `done - -`;
- senão, algum PR `OPEN` → `review <L> <missão>`;
- senão (só PR `CLOSED`) → `stop <L> <missão> — pull request closed without merge`, rc 1.
Quando o ato é `run` ou `review` e o lote seguinte não tem missão, a segunda linha é
`ahead plan <L+1>`. Se o `gh` falha, rc 3 e nenhuma linha de ato: "não consegui ler" nunca vira
"não há PR", que mandaria rodar de novo.

**`pr-ready`** lê o head do PR (`headRefOid`) e exige os cinco, nomeando o primeiro que falha:
1. `review`: o `40-review-r<N>.md` de maior N do diretório da missão tem `reviewed_head: <sha>` no
   frontmatter; toda célula `Grade` sob `### Overall Grade` é exatamente `A`; e
   `git diff --name-only <reviewed_head> <head>` só lista caminhos sob o diretório da missão;
2. `codex`: dos comentários de `gh api --paginate repos/<o>/<r>/issues/<pr>/comments`, o último que
   traz `codex-review-state:v1` tem `code_review.commit_sha` igual ao head, `status` igual a
   `completed` e `has_unresolved_findings` igual a `false`;
3. `threads`: nenhum `isResolved: false`;
4. `mergeable`: `state` `OPEN` e `mergeable` `MERGEABLE`;
5. `head`: o `HEAD` local do checkout é o mesmo sha.

A linha `ready <sha>` é o valor que o chamador passa a `gh pr merge --merge --match-head-commit`.
O método (merge commit, nunca squash) é do comando que mergeia, não do verbo: é a metade do quinto
item da régua da decisão 9 que o `pr-ready` não tem como ler, e ela fica escrita no
`commands/sdd-worker.md`.

**O `reviewed_head:` é do worker, de propósito.** As rodadas que a fase REVIEW do `sdd run` escreve
não trazem essa chave, e esta missão não muda `templates/review.md` nem o `sdd-reviewer`. Logo,
depois de uma corrida, `pr-ready` responde `not-ready review: the newest round names no head` até a
sessão do worker fazer a sua própria rodada sobre o head e gravá-la com a chave. É o que o caderno
mediu (M5): a régua do dono é mais alta que a do pipeline, e a rodada do worker é quem a aplica.

## Incrementos

A tabela executável vive em `checkpoint.md`. Aqui fica o porquê de cada fatia. Em todos: TDD (o
probe do sensor vem primeiro e fica vermelho), `shellcheck -S warning` nos arquivos tocados,
`tests/check-todo.sh --anchors TODO.md` antes do commit, e **um commit por incremento**, com a
convenção `<tipo>(<escopo>): <o quê>`, em pt-BR, com o porquê no corpo.

**As frases de asserção abaixo são contrato com o `checkpoint.md`:** o sensor imprime cada uma
exatamente como está escrita, numa linha, com o prefixo `  ok    `, e não imprime outra linha com
o mesmo prefixo de família (`delegate: `, `level: `, …). Probe a mais se dobra dentro de uma delas.

### I1 — os templates da campanha e da delegação

**O quê:** `templates/campaign.md` e `templates/delegation.md` novos, pelo contrato acima, com a
prosa de instrução em pt-BR e `<…>` nos valores, menos `signed:`, que nasce vazio.
`templates/missao.md` ganha duas linhas no frontmatter, logo abaixo de `kaizen_log:`:
`campaign: <vazio, ou o id da campanha a que esta missão pertence>` e
`lot: <vazio, ou o lote dela na campanha: L<n>>`.
**Onde:** `templates/campaign.md`, `templates/delegation.md`, `templates/missao.md`,
`tests/check-templates.sh`, e o `TODO.md` (a âncora `templates/missao.md:41` vira `:43`).
**Como (TDD):** um bloco próprio em `tests/check-templates.sh`, **antes** da linha
`REVIEW_MARK="$CHECKS_RUN"` (linha 516), para o `REVIEW_FLOOR` não se mover. **Não use `check()`:**
ele imprime `  ok    <arquivo>: <descrição>`, e o Check deste incremento ancora em
`^  ok    worker templates: `. Cada asserção é um grupo de `grep -qE` sobre `"$T/<arquivo>"`
seguido de UM `pass "<frase>"` (linha 76) quando todos casam, ou de uma linha `  FAIL  <frase>` na
stderr e da contagem de falha que o arquivo já usa; some 1 em `CHECKS_RUN` por asserção.
- `worker templates: campaign.md carries the lots table and the harness and model keys`
- `worker templates: delegation.md carries level, lots, expires, both ceilings and an empty signed`
- `worker templates: missao.md offers the optional campaign and lot keys`
**Check:** ver `checkpoint.md`.
**Sensor durável:** as três asserções, na suíte.
**Reversível por:** `git revert` do commit; nada lê os templates ainda.

### I2 — o programa e o sensor, ligados na suíte

**O quê:** `bin/sdd-worker` (executável; `set -euo pipefail`; o uso; o despacho, com os seis verbos
nomeados e cada um ainda respondendo `not implemented` na stderr e rc 2: nenhum verbo funciona
neste incremento) e `tests/check-worker.sh`, ligado em todos os lugares da seção "Onde um sensor
novo entra".
**Onde:** `bin/sdd-worker`, `tests/check-worker.sh`, `tests/run-all.sh`, `tests/check-pipefail.sh`,
`tests/check-checkpoint.sh`, `tests/check-health.sh`, `tests/check-lang.sh`,
`tests/check-mutation.sh`, e o `TODO.md` se uma âncora andar.
**Como (TDD):** o sensor nasce com uma asserção, e a suíte inteira (`tests/run-all.sh`) fica verde
com o passo novo. Cada lugar esquecido aparece em vermelho com nome: siga-os um a um.
- `usage: no verb and an unknown verb print the usage and leave rc 2`
Um mutante: `WORKER_unknown_verb_accepted` (o ramo do verbo desconhecido sai 0).
**Check:** ver `checkpoint.md`.
**Sensor durável:** o passo `the worker answers from artifacts` na suíte, e o mutante.
**Reversível por:** `git revert`; os pisos voltam juntos.

### I3 — `delegate`

**O quê:** o verbo `delegate`, a função única de leitura de frontmatter, a de "legível" e a do
digest.
**Onde:** `bin/sdd-worker`, `tests/check-worker.sh`, `tests/check-mutation.sh`.
**Como (TDD):** a fixture é um repo git em `mktemp -d`, com `.sdd/config.sh` contendo
`HANDOFF_DIR="docs/handoffs"` e `ON_ESCALATION_CMD="true"`, e um diretório de campanha feito dos
templates do I1 com valores reais. O sensor responde por pipe (`printf 'y\n'`, `printf 'n\n'`,
`< /dev/null`).
- `delegate: an answer of y signs with a digest of the other fields`
- `delegate: no answer on stdin leaves rc 66 and writes nothing`
- `delegate: n, an expired instant, an undefined level and a missing ceiling sign nothing`
Dois mutantes: `WORKER_delegate_signs_without_answer` e `WORKER_delegate_signs_expired`.
**Check:** ver `checkpoint.md`.
**Sensor durável:** as três asserções e os dois mutantes.
**Reversível por:** `git revert`.

### I4 — `level`

**O quê:** o verbo `level`, com os nove passos de "Nível efetivo", a escada numa definição só, e a
função `now` com a costura `SDD_WORKER_NOW`.
**Onde:** os mesmos três arquivos.
**Como (TDD):** as fixtures assinam com o `delegate` do I3, nunca com digest escrito à mão. A
delegação vencida se faz assinando uma com `expires` no futuro e chamando `level` com
`SDD_WORKER_NOW` posterior a ela. O probe da costura prova também o outro lado: um
`SDD_WORKER_NOW` no passado não muda a resposta.
- `level: a signed delegation answers its own level, for each of the five`
- `level: absent, illegible, unsigned and expired each answer assisted and say why`
- `level: a delegation edited after signing answers assisted`
- `level: a name outside the ladder is not a level`
- `level: above assisted with no pager answers assisted`
- `level: the lot ceiling lowers the level and never raises it, and an uncovered lot is assisted`
Três mutantes: `WORKER_level_ignores_expiry`, `WORKER_level_ignores_digest`,
`WORKER_level_ceiling_raises`.
**Check:** ver `checkpoint.md`.
**Sensor durável:** as seis asserções e os três mutantes.
**Reversível por:** `git revert`.

### I5 — `allows`

**O quê:** o verbo `allows`, sobre a tabela de atos, uma definição, escrita positivamente.
**Onde:** os mesmos três arquivos.
**Como (TDD):** a asserção da matriz percorre 5 níveis × 7 atos e compara com a tabela deste plano.
- `allows: the five levels by the seven acts answer the table, 35 of 35`
- `allows: an act outside the table leaves rc 2 and is never allowed`
- `allows: a broken delegation asks the owner for every act`
- `allows: the lot ceiling stops approve on a capped lot under full`
Três mutantes: `WORKER_allows_unknown_act`, `WORKER_allows_merge_at_plan`,
`WORKER_allows_ignores_lot`.
**Check:** ver `checkpoint.md`.
**Sensor durável:** as quatro asserções e os três mutantes.
**Reversível por:** `git revert`.

### I6 — `budget`

**O quê:** o verbo `budget`.
**Onde:** os mesmos três arquivos.
**Como (TDD):** o sensor aponta `SDD_STATE_DIR` para a fixture e **nunca** lê o ledger real. A
fixture tem duas missões da campanha e uma de fora, com custos conhecidos.
- `budget: the sum counts the campaign's missions and no other`
- `budget: at the ceiling or above it the verb leaves rc 1`
- `budget: a missing ledger is zero spent, and the mission cap is printed`
Dois mutantes: `WORKER_budget_counts_every_mission`, `WORKER_budget_never_stops`.
**Check:** ver `checkpoint.md`.
**Sensor durável:** as três asserções e os dois mutantes.
**Reversível por:** `git revert`.

### I7 — `next`

**O quê:** o verbo `next`, derivado da fila, das missões em disco e do `gh` (stub no sensor).
**Onde:** os mesmos três arquivos.
**Como (TDD):** uma fixture por estado de lote. O stub do `gh` responde por `--head <branch>`.
- `next: a lot with no mission is planned, and one with an empty approval is approved`
- `next: an approved mission with no pull request is run, and an open one is reviewed`
- `next: a merged lot is skipped, and a campaign with every lot merged is done`
- `next: while a lot runs, the next lot with no mission is planned ahead`
- `next: a gh that does not answer leaves rc 3, and a pull request closed without merge stops`
Três mutantes: `WORKER_next_gh_failure_reads_no_pr`, `WORKER_next_skips_approval`,
`WORKER_next_ignores_merged`.
**Check:** ver `checkpoint.md`.
**Sensor durável:** as cinco asserções e os três mutantes.
**Reversível por:** `git revert`.

### I8 — `pr-ready`

**O quê:** o verbo `pr-ready`, os cinco itens, cada um nomeado quando falha.
**Onde:** os mesmos três arquivos, mais `tests/fixtures/codex-review-state.txt`.
**Como (TDD):** a fixture é um repo git com dois commits e uma pasta de missão com um
`40-review-r2.md` cuja tabela é copiada de `templates/review.md`. O corpo do comentário do Codex é
copiado do PR 409 (comando na seção "O que os verbos leem de fora"), guardado em
`tests/fixtures/codex-review-state.txt`; o sensor troca o sha pelo head da fixture ao montar a
resposta do stub. A proveniência (o comando e a data) vai num comentário ao lado do probe que lê o
arquivo. Uma fixture boa responde `ready <sha>`; cada asserção sabota UM item.
- `pr-ready: all five true at one sha answers ready with the full sha`
- `pr-ready: a grade below A, a round that names no head, and code after the reviewed head each fail review`
- `pr-ready: a receipt for another sha, an unfinished one and an unresolved finding each fail codex`
- `pr-ready: one open thread fails threads`
- `pr-ready: a conflicting or closed pull request fails mergeable`
- `pr-ready: a local HEAD that is not the pull request head fails head`
- `pr-ready: a gh that does not answer leaves rc 3 and never ready`
Cinco mutantes, um por item: `WORKER_ready_grade_b_passes`, `WORKER_ready_codex_any_sha`,
`WORKER_ready_threads_unread`, `WORKER_ready_unmergeable_passes`, `WORKER_ready_head_unchecked`.
**Check:** ver `checkpoint.md`.
**Sensor durável:** as sete asserções e os cinco mutantes.
**Reversível por:** `git revert`.

### I9 — o comando da sessão

**O quê:** `commands/sdd-worker.md`, em inglês, com frontmatter `description:` como o do
`commands/sdd-plan.md`. É prosa para uma sessão interativa seguir. Conteúdo obrigatório:
1. **Antes de tudo:** recebe o diretório da campanha; roda `sdd-worker level`; em `assisted`
   propõe cada ato e espera o dono; nunca age com `sdd run` de outra missão vivo no mesmo checkout.
2. **O laço:** `sdd-worker budget` → `sdd-worker next` → `sdd-worker allows <dir> <ato> --lot <L>`
   → o ato → uma linha no `journal.md` (hora de `date`) → de novo. Cada um dos sete atos aparece
   com a sua chamada literal `sdd-worker allows <dir> <ato>` numa linha.
3. **Os atos:** `plan` é o `/sdd-plan` com o planner no modelo de `plan_model`, e sob delegação o
   relay responde o grill com a recomendada e lista no PR as respostas que tocam regra do dono;
   `approve` remede `--check` e `--red`, grava o extrato do plano em arquivo e chama `sdd approve`;
   `run` lança `sdd run` no worktree da missão, isolado (`setsid nohup env -u CLAUDECODE … sdd run`),
   com `BUDGET_MISSION_USD` do `budget`, e espera pelo PID, nunca por `pgrep -f`; `review` traz a
   base (`git merge origin/<base>`), roda a suíte, faz a rodada de revisão e grava
   `40-review-r<N>.md` com `reviewed_head:`, pede `@codex review` sempre e espera o recibo;
   `merge` é `sdd-worker pr-ready` e depois `gh pr merge --merge --match-head-commit <sha>`, sempre
   merge commit; `postmerge` é um PR próprio, nunca push na base, feito antes do `next` seguinte.
4. **As cinco paradas:** as três da decisão 9 e as duas do teto (decisão 10), cada uma chamando o
   `ON_ESCALATION_CMD` e gravando no diário.
5. **O que nunca entra:** apagar branch ou worktree, push na base, aceite visual, mover o checkout
   principal do kit com corrida viva.
6. **Contexto:** uma linha por evento; relatório, plano e revisão vão para arquivo e o subagente
   devolve só o veredito; handoff em arquivo a cada lote fechado; a sessão nova retoma por
   `level` e `next`, sem memória.
7. **Missão do kit:** roda no worktree ligado da missão, e o rc 2 do `sdd run` com o PR aberto e só
   o carimbo faltando se lê como "pronto para revisão".
**Onde:** `commands/sdd-worker.md`, `tests/check-worker.sh`.
**Como (TDD):** os probes leem o arquivo; cada frase que um probe lê cabe numa linha do markdown.
- `command: it names every verb of bin/sdd-worker`
- `command: each of the seven acts is preceded by its allows call`
- `command: the five stops, the never list and the context rules are written`
**Check:** ver `checkpoint.md`.
**Sensor durável:** as três asserções; `tests/check-lang.sh` cobra o idioma.
**Reversível por:** `git revert`.

### I10 — a documentação e o vocabulário

**O quê:**
- `docs/pipeline.md`: uma seção nova `## The worker`, depois de `## The kaizen loop`: os seis
  verbos, a escada, a tabela de atos, os contratos dos dois arquivos, o `reviewed_head:`, a
  costura `SDD_WORKER_NOW`, os limites declarados da ADR 0022.
- `README.md`: uma linha na lista de comandos e um parágrafo curto apontando para a seção.
- `config/schema.md`: uma nota de que `ON_ESCALATION_CMD` vazio rebaixa toda delegação a
  `assisted`, e de que o worker passa o teto da missão por `BUDGET_MISSION_USD`.
- `CONTEXT.md`, sob `## Glossário`: verbetes "Campanha", "Lote", "Delegação", "Nível de autonomia"
  e "Worker da campanha" (este último separando-o do "worker da coordenação").
- `commands/sdd-plan.md:50`: a frase "interactively, never by a `sdd run` from this checkout"
  ganha a exceção escrita: sob o worker, a missão do kit roda por `sdd run` **no worktree**
  (ADR 0022 §7); a partir do checkout principal continua proibido.
- `docs/superpowers/specs/2026-09-22-o-worker-roadmap-design.md`: uma nota no topo dizendo que D1,
  D2 e D5 foram revisados pela ADR 0022 e que a forma A (tick) ficou de lado, sem reescrever o
  resto.
**Onde:** os seis arquivos acima, `tests/check-worker.sh`, e o `TODO.md` se uma âncora andar.
**Como (TDD):** uma asserção que lê os quatro primeiros.
- `docs: pipeline.md, README.md, schema.md and CONTEXT.md name the worker, its verbs and its five levels`
**Check:** ver `checkpoint.md`.
**Sensor durável:** a asserção. O resto da deriva de docs é do `gate_DOCS`.
**Reversível por:** `git revert`.

### I11 — a campanha do kit e a gaveta

**O quê:**
- `docs/superpowers/campaigns/20261117-zerar-as-issues/campaign.md`, a partir de
  `templates/campaign.md`: `harness: claude`, `plan_model: fable`, `exec_model: opus`, a tabela de
  seis lotes e os 83 itens. O título de cada item é o texto entre `**` do item do `TODO.md` **em
  `5221477`**: leia com `git show 5221477:TODO.md` e use os números de linha abaixo, que são desse
  commit.
- `docs/superpowers/campaigns/20261117-zerar-as-issues/delegation.md`, a partir do template:
  `campaign: 20261117-zerar-as-issues`, `level: assisted`, `lots: all`, `signed:` **vazio**, e os
  placeholders `<…>` do template em `expires:` e nos dois tetos, que o dono preenche. Não assine e
  não invente prazo nem teto.
- `docs/superpowers/specs/2026-09-23-a-gaveta-do-kit.md`: a linha da F6 no índice e a seção
  `## F6` passam de "estacionada por decisão" para **em construção por decisão do dono em
  2026-11-17**, com a ADR 0022 e esta missão; a frase "na volta começa pelo W2" sai.
- `docs/superpowers/specs/2026-10-09-o-worker-caderno-de-campo.md`, §4: uma linha dizendo que as
  quatro perguntas foram respondidas pela ADR 0022.

**A fila (decisão 8).** Linha do `- [ ]` em `5221477:TODO.md`; `◆` marca os 24 com escolha em aberto.

| Lot | Título | Ceiling | Linhas |
|---|---|---|---|
| L1 | Prosa de chapéu e docs (piloto) | `-` | 208 314 375 383 495 532 563 599 607 615 621 638 661 678 |
| L2 | O `/sdd-plan` e o planner | `-` | 48 230 237 244◆ 251◆ 259 297 349 358 398 414 629 687◆ 695 |
| L3 | Gates do fim da linha | `-` | 120 178◆ 186 291◆ 305 331 340 366 441◆ 457 487◆ 509◆ 645 |
| L4 | Preflight, health e sensores | `-` | 40◆ 56 64 81 89 96 103◆ 111 128 137◆ 449 516 653 669 |
| L5 | Saída humana e contrato do runner | `-` | 157◆ 164 201 216◆ 223◆ 275 406 422 430 464 472 479◆ 501 524◆ 541 550 703◆ |
| L6 | Desenho, uma missão por item ou par | `plan` | 29 72◆ 148◆ 172◆ 193 267◆ 283◆ 323 391◆ 573 591◆ |

Contagem por lote: 14, 14, 13, 14, 17, 11; soma 83. Os `◆` por lote: 0, 3, 5, 3, 6, 7; soma 24.

O corpo da campanha escreve também, em prosa curta: a régua (decisão 9), as paradas (decisões 9 e
10), a regra dos `◆` (decisão 8), e que o L1 é o piloto do worker sobre o kit.
**Onde:** os arquivos acima.
**Como (TDD):** o Check é o próprio `bin/sdd-worker level` sobre a campanha real, que responde
`level assisted — illegible` (os tetos ainda são placeholders).
**Check:** ver `checkpoint.md`.
**Sensor durável:** não cabe um sensor permanente sobre um documento datado, que a campanha vai
consumir. O que fica durável são os templates do I1 e o sensor dos verbos. O Check deste
incremento é efêmero por essa razão.
**Reversível por:** `git revert`.

## Riscos e não-feitos

| Risco | Probabilidade | Mitigação |
|---|---|---|
| O `sdd run` morre por causa do arranjo (kit como alvo, em worktree): sessão aninhada, guarda de kit, agente "stale", lock | média | É a medida da decisão 12. Não remende o arranjo dentro de um incremento: registre nas notas o comando, o rc e a última linha do `pipeline.log`, e pare. O caso volta ao dono e a construção segue interativa neste worktree |
| O `gate_PR` sai com rc 2 por falta do carimbo de mutação | certa | Parada conhecida, não é falha: lê-se como "PR pronto para revisão". Ninguém roda `./bin/sdd health` nesta missão |
| O checkout principal do kit anda durante a corrida | baixa | O relay não faz `git pull` lá com corrida viva. Se a guarda disparar `KIT-TOUCHED`, é ambiente, não é o arranjo |
| A fixture do recibo do Codex escrita de memória | média | A fonte e o comando estão na seção "O que os verbos leem de fora"; a proveniência vai no sensor |
| Uma âncora do `TODO.md` sai do alvo | alta | `tests/check-todo.sh --anchors TODO.md` antes de cada commit; a suíte também cobra. Dois deslocamentos já estão nomeados (I1 e I2) |
| O parser da tabela de notas diverge do `gate_REVIEW` | baixa | É divergência declarada (ADR 0022, Consequences): `pr-ready` é mais estrito de propósito |
| A sessão quer escrever a rule em `.claude/rules/` | média | Proibido aqui; a DOCS deixa a linha ⛔ com o texto proposto |
| `SDD_WORKER_NOW` usado para ressuscitar uma delegação vencida | baixa | A costura só adianta o relógio; o probe do I4 prova que um valor no passado não muda a resposta |

**Não-feitos:** os de "Fora de escopo" do `00-missao.md`. Em especial, nenhum verbo age, o `next`
não deriva o `postmerge`, e o `delegate` não commita o arquivo que assina.

## Verificação end-to-end

Com os onze incrementos `done`, na raiz do worktree:

```bash
tests/run-all.sh                                   # verde, com o passo "the worker answers from artifacts"
o=$(bash tests/check-worker.sh 2>&1); grep -c '^  ok    ' <<< "$o"   # 33 linhas das famílias deste plano, ou mais
bin/sdd-worker level docs/superpowers/campaigns/20261117-zerar-as-issues   # level assisted — illegible
grep -c '^- \[ \] ' docs/superpowers/campaigns/20261117-zerar-as-issues/campaign.md   # 83
grep -c '^mut_WORKER_' tests/check-mutation.sh                         # 19
tests/check-todo.sh --anchors TODO.md                                  # 0 off target
```

As 33: `usage` 1, `delegate` 3, `level` 6, `allows` 4, `budget` 3, `next` 5, `pr-ready` 7,
`command` 3, `docs` 1. Os 19 mutantes: 1, 2, 3, 3, 2, 3, 5, do I2 ao I8.
