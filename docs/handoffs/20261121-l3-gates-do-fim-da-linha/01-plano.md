---
missao: 20261121-l3-gates-do-fim-da-linha
data: 2026-11-21
---

# Plano — L3: gates do fim da linha

> **Teste de autocontenção:** uma sessão nova, sem nenhuma memória da conversa que gerou este
> plano, lendo apenas `00-missao.md` + `01-plano.md` + `checkpoint.md`, consegue executar?
> Se a resposta for "só se souber X", **X vai escrito aqui**.

## Contexto verificado (não re-descobrir)

Medido em 2026-11-21, no commit `6198b68`, no worktree `/home/joruge/repos/sdd_agents-l3`. **A base
vai ter andado quando você ler isto** (pendência 1 do `00-missao.md`: a `main` com o chore do L2
entra neste branch antes da corrida). Todo número de linha abaixo é pista, nunca instrução: ache
cada trecho pelo `grep` do nome da função ou da frase que o incremento dá. Ao lado de cada contagem
está o comando que a mediu.

**Onde você está e com que `sdd`**

- A missão roda num **worktree ligado** do kit. O `sdd` do PATH é o do checkout principal
  (`/home/joruge/repos/sdd_agents`), com o runner e os chapéus de **antes** deste lote: é ele que
  julga os gates desta corrida. O `./bin/sdd` é o deste worktree, com o que você escreveu. **Nunca
  escreva, commite ou entre no checkout principal**: a guarda de kit de toda corrida da máquina
  compara o `HEAD` e o `git status` dele.
- Quem espelha um chapéu é **`./bin/sdd install --force`**, com o `./` (o do PATH copiaria de volta
  o chapéu velho). `.claude/agents/` é rastreado (`git ls-files .claude/agents` → 8 arquivos), então
  o espelho entra no mesmo commit do chapéu. Nunca `cp`, nunca `Edit`/`Write` em `.claude/`: a
  sessão headless leva negativa. Se o comando responder `CHECKOUT-BUSY` (rc 75), não contorne:
  anote o comando, o rc e a saída nas notas, marque `blocked` e pare.
- Config (`grep -n '^JIRA_ENABLED\|^TEST_CMD\|^HANDOFF_DIR\|^OUTPUT_LANG\|^DEFAULT_BRANCH\|^TODO_FILE\|^ADR_' .sdd/config.sh`):
  `DEFAULT_BRANCH="main"`, `TEST_CMD="tests/run-all.sh"`, `HANDOFF_DIR="docs/handoffs"`,
  `TODO_FILE="TODO.md"`, `JIRA_ENABLED=false`, `OUTPUT_LANG="pt-BR"`, `ADR_CHECK="block"`,
  `ADR_DIR="docs/adr"`. A linha `EFFORT_EXEC="${EFFORT_EXEC:-medium}"` não é sua: não mexa nela.
- A ADR desta missão já existe, com o corpo escrito pelo planner:
  `docs/adr/0024-the-end-of-line-gates-read-the-head-they-check.md` (`proposed`; o `sdd approve` a
  vira `accepted`). Ela é a fonte do desenho dos incrementos I3, I4 e I5. Não a reescreva; se um
  incremento divergir dela, pare e anote.

**A suíte e os sensores**

- `TEST_CMD` é `tests/run-all.sh` (8 a 15 min). O `gate_EXEC` a roda a cada volta. A chamada `Bash`
  do harness para de esperar aos 120 s por padrão e 600 s no máximo: rode a suíte com o `timeout` da
  chamada em 600000 ms, ou destacada com a saída num arquivo.
- Tempos e contagens em `6198b68`, cada sensor sozinho, com outra suíte rodando na máquina
  (`grep -c '^  ok    '` na stdout): `bash tests/check-gates.sh` → rc 0, 129 s, 515 linhas;
  `bash tests/check-autonomy.sh` → rc 0, 213 s, 503 linhas; `bash tests/check-hat.sh` → rc 0, 4 s,
  142 linhas; `bash tests/check-templates.sh` → rc 0, 1 s, 123 linhas. Use o sensor sozinho para o
  Red e o Green; a suíte inteira fica para antes do commit. Nenhum Check depende dessas contagens.
- **`tests/check-gates.sh` é um script só, linear, sobre um repositório de fixture** (`$FIX`, missão
  `$MISSION`, pasta `$MDIR`). Cada bloco deixa o fixture no estado que o bloco seguinte herda, e diz
  isso num comentário ("Back to the state the DOCS section inherits…"). Bloco novo entra **depois**
  do bloco vizinho do mesmo gate e **devolve o fixture ao estado em que o achou**. Os ajudantes
  (`grep -n '^assert_[a-z_]*()\|^pass()\|^fail()' tests/check-gates.sh`): `pass "<frase>"` imprime
  `  ok    <frase>` na stdout; `fail "<frase>" "<esperado>" "<obtido>"` imprime `  FAIL  <frase>` na
  stderr; `assert_eq "<frase>" "<esperado>" "<obtido>"`; `assert_phase "<frase>" "<FASE|DONE>"`;
  `assert_why "<frase>" "<FASE>" "<regex>"`. O motivo de um gate sai de
  `( cd "$FIX" && "$SDD" why "$MISSION" <FASE> 2>&1 )`, e a fase derivada de `"$SDD" phase "$MISSION"`.
- **Os blocos vizinhos, pelo `grep` que os acha:**
  - EXEC e a suíte vermelha: `grep -n 'TEST_CMD="false"' tests/check-gates.sh`;
  - a rodada de REVIEW com `reviewed_head:`: `grep -n '^write_r12()' tests/check-gates.sh` (o
    ajudante escreve uma rodada r12 nova a cada mundo, porque o `review_head_ok` lê o commit que
    **adicionou** a rodada);
  - o K8: `grep -n '^k8_world()\|^k8_base_log()\|^k8_with_new()' tests/check-gates.sh`;
  - o e2e vermelho do `gate_QA`: `grep -n 'gate-qa-e2e\|APP_URL=' tests/check-gates.sh`;
  - o `gate_PR`: `grep -n 'gate_PR asks .gh. whether the PR is real' tests/check-gates.sh`.
- **O `gh` dos sensores é um stub**, e nenhum teste toca a rede. Os que respondem ao `gate_PR`
  (`grep -n 'stub/gh' tests/check-gates.sh tests/check-kaizen.sh`): dois em `tests/check-gates.sh`
  (o do comentário `Answers the one question gate_PR asks` e o que também responde
  `--json state,body`, com arquivos de controle em `$FIX/.sdd/logs/pr-state`, `pr-body` e
  `pr-body-fails`) e `gh_stub_confirms_pr` em `tests/check-kaizen.sh`. Os três respondem a qualquer
  `gh pr view` imprimindo o terceiro argumento (a url). O I3 muda a primeira pergunta do `gate_PR`,
  então **os três mudam no commit do I3**. Os outros stubs (`cmd_close`, que só imprime o estado;
  os de `tests/check-worker.sh` e de `tests/check-preflight.sh`) não respondem ao `gate_PR` e ficam.
- **A escalada do `blocked` é provada em `tests/check-autonomy.sh`**, pelo molde do par da TICKET:
  `grep -n '^blocked_shape()\|ticket declares blocked' tests/check-autonomy.sh`. O par roda
  `"$SDD" run "$MISSION"`, lê o rc, as sessões gastas e a linha `blocked` do ledger, e compara com
  um mundo "ordinário" que ainda gasta as sessões dele.
- **`tests/check-hat.sh`:** `pass`/`fail` levam **um** argumento. As famílias são funções
  `*_probes()` chamadas numa lista no fim do arquivo (`grep -n '_probes$' tests/check-hat.sh`);
  família nova entra nessa lista. A do publisher é `publisher_stamp_probes`
  (`grep -n '^publisher_stamp_probes()' tests/check-hat.sh`), que já lê seções do chapéu com
  `awk '/^### 2\. /{on=1; next} /^### /{on=0} on' "$pub"`. Leia o literal com
  `grep -qF '<literal>' <<< "$sec"`: sempre herestring, nunca `printf … | grep -q` (o arquivo roda
  sob `pipefail`).
- **`tests/check-templates.sh`:** `check <arquivo> <regex> <descrição>` imprime
  `  ok    <arquivo>: <descrição>` (`grep -n '^check()' tests/check-templates.sh`). As asserções do
  `review.md` são contadas contra o piso `REVIEW_FLOOR=26` (`grep -n 'REVIEW_FLOOR=' tests/check-templates.sh`):
  asserção nova de `review.md` sobe o piso no mesmo commit. É o único sensor em que um literal em
  português pode morar (`tests/check-lang.sh` cobra inglês no resto de `tests/`, em `bin/`, em
  `agents/` e em `docs/` fora de `docs/handoffs/`, `docs/qa/` e `docs/superpowers/`).
- **Toda frase que uma asserção lê cabe numa linha física do arquivo lido.** O `grep -qF` lê linha
  a linha: um literal partido por quebra de linha nunca casa. Deixe a linha passar de 100 colunas
  antes de partir um literal.
- **Mutante novo são duas coisas** em `tests/check-mutation.sh`: a função `mut_<slug>() { … }`, que
  aplica um `sed -i` em `"$1"` (a cópia do `bin/sdd`), endereçado à função alvo
  (`sed -i '/^gate_PR()/,/^}/ s|…|…|' "$1"`), e o `<slug>` na lista do catálogo
  (`grep -n '^  PR_no_artifact$' tests/check-mutation.sh` mostra a lista). Prove cada um antes do
  commit: `bash tests/check-mutation.sh --only <slug> tests/check-gates.sh` → rc 0 (pego). O
  `--anchors` (`bash tests/check-mutation.sh --anchors`, segundos) roda na suíte e reprova o mutante
  que não se aplica. **Mutante que `--only` não pega significa que a asserção não mede**: conserte a
  asserção, nunca o mutante. O catálogo inteiro (`./bin/sdd health`) **não roda** nesta missão.
- Antes de cada commit em `bin/` ou `tests/`: `shellcheck -S warning` nos arquivos tocados e
  `bash -n bin/sdd`.

**Armadilhas do `bin/sdd` que este lote pisa**

- O arquivo roda sob `set -euo pipefail`: `x="$(cmd)"` mata o processo na atribuição quando `cmd`
  devolve não-zero (e para `grep` e `git`, não-zero é só "não achou"). Toda captura nova leva
  `|| true`, `|| rc=$?` ou `if x="$(…)"; then`.
- Função lida como `x="$(f)"` roda num subshell: atribuição a global dentro dela morre. Função que
  **publica** global (`GATE_WHY`, `GATE_HANDOFF_BLOCKED`, `LAST_CHECK_LOG`) é **chamada**, nunca
  substituída. Função que só imprime (`mission_tip`, abaixo) pode ser lida por `$( )`.
- `printf … | grep -q` devolve 141 sob `pipefail` quando o grep acha: use herestring.
- O `awk` é o `mawk`, orientado a byte: classe negada só com ASCII; para literal use `index()`.
- Comentário `#` dentro de um bloco continuado por `\` quebra o comando em silêncio.
- Todo gate se chama `gate_<FASE>`, devolve 0/1 e escreve o motivo em `GATE_WHY`. **Gate novo ou
  mudado nomeia, no comentário, o dono do artefato que ele exige** (princípio 1 do `CLAUDE.md`):
  cada incremento abaixo diz quem é.
- Leitores que já existem e você reusa (`grep -n '^<nome>()' bin/sdd`): `frontmatter <arquivo> <chave>`,
  `frontmatter_has <arquivo> <chave>`, `latest_matching <glob>`, `mission_base_refs` (os commits da
  base, um por linha), `hat_writes <FASE>` e `hat_path_allowed <caminho> <globs>`,
  `docs_checklist_rows <45-docs.md>`, `mission_id <missão>`, `mission_branch_declared` (a definição
  única de "o `branch:` está vazio ou é o `<…>` do template"), e a variável `FENCE_AWK` (a função
  `fence_line` e a variável `fence`, para pular cercas de código num `awk`).

**O contrato muda em três lugares no mesmo commit**

- Mudou o que um gate lê? `docs/pipeline.md` muda no mesmo commit, na seção do gate
  (`grep -n '^### ' docs/pipeline.md`: `### EXEC`, `### QA`, `### REVIEW`, `### DOCS`, `### PR`), em
  inglês. Mudou um chapéu? O espelho entra junto. Mudou um template? O sensor dele entra junto.
- `.claude/rules/anatomia-do-agente.md` e o `CLAUDE.md` **não** são seus: a sessão headless não
  edita `.claude/`, e a fase DOCS propõe o texto numa linha `⛔`.

**O `TODO.md`**

- `bash tests/check-todo.sh --count TODO.md` → `106` em `6198b68`; `tests/health-baseline.txt` diz
  `todo-findings 106`. Depois do merge da base os dois dizem outro número (pendência 2 do
  `00-missao.md`). **Não toque em `tests/health-baseline.txt`.**
- O título de um item (o texto entre `**`) é a chave do espelho de issues: **nunca mude um título.**
  Os 13 estão na tabela do `00-missao.md`.
- A âncora de cada item é medida: `` `arquivo:linha` (`símbolo`) ``, e o símbolo tem de ocorrer no
  arquivo a até 10 linhas da linha. Antes de **todo** commit:
  `bash tests/check-todo.sh --anchors TODO.md` → `0 off target` (em `6198b68`:
  `anchors: 106 measured, 0 off target`). Âncora que saiu do alvo se conserta no mesmo commit,
  mudando o número da linha (ou o símbolo, quando o conserto o apagou), nunca o título.
- O `bin/sdd` é o arquivo mais ancorado do `TODO.md` (`grep -c '`bin/sdd:[0-9]' TODO.md` → `56` linhas
  que citam uma linha dele, entre âncoras e corpo): toda linha que você
  acrescentar ao runner desloca as âncoras abaixo dela. I1 a I7 editam o `bin/sdd`.
- Âncoras em outros arquivos que este lote edita (linha do `TODO.md` em `6198b68` → âncora):
  - `agents/sdd-publisher.md`: 191→`:48` (`status: blocked`, item de **outro lote**), 405→`:48`
    (`Conflict`), 558→`:59` (`how to verify`), 620→`:62` (`decisions for a human`), 432→`:69`
    (`TODO_FILE`), 258→`:83` (`50-pr.md`), 704→`:83` (`gh pr edit`). I2, I3 e I7 editam o chapéu.
  - `agents/sdd-reviewer.md`: 273→`:68` (`Overall Grade`) e 686→`:106` (`MEDIUM/LOW, cheap`), os
    dois de **outros lotes**. I2 e I4 editam o chapéu.
  - `templates/handoff.md`: 266→`:7` (`gate:`). O I8 edita o template.
  - `tests/check-mutation.sh`: 208→`:7178` (`mut_WORKER_range_ancestry_unchecked`, outro lote).
    Mutante novo escrito acima dessa linha a desloca.
  - `docs/pipeline.md`: 252→`:99` (`R<n>`, outro lote). As seções dos gates ficam abaixo dela.
- **Dois símbolos somem com o conserto, e o plano diz o que fazer com cada um:**
  - item 13, `gh pr edit` em `agents/sdd-publisher.md`: o chapéu **continua citando** o comando, na
    frase que o proíbe (I3), então o símbolo fica;
  - item 11, `rev-list -n 1 HEAD` em `bin/sdd`: o I5 troca o `HEAD` pela ponta da missão. No mesmo
    commit, troque o símbolo da âncora desse item para `mission_tip` e o número para a linha do K8
    que o chama.
- `RESOLVED by <hash>` vai no fim da última linha do corpo, **antes** do `— descoberto por` (ou do
  `Fonte:`), nunca numa linha própria, nunca na linha `RECURRED`; nenhum item passa de 8 linhas
  (`bash tests/check-todo.sh --check TODO.md` → rc 0). É o I9 que as escreve.

**Para a fase DOCS**

- A entrada do `KAIZEN_LOG.md` cita o id inteiro `20261121-l3-gates-do-fim-da-linha` sob um título
  `## ` novo. Ela traz o antes e o depois do lote (30 asserções e 16 mutantes novos; a contagem de
  `^mut_` em `tests/check-mutation.sh` antes e depois, por `grep -c '^mut_'`: 926 em `6198b68`) e a
  tabela por sessão de EXEC ao lado do L2 e do L1: minutos (`dur_s`) e US$ (`cost_usd`) das linhas
  `"event":"session"` com `"phase":"EXEC"` em `~/.sdd/autonomy-log.jsonl`, por missão
  (`20261117-l1-a-prosa-do-chapeu`, `20261120-l2-o-sdd-plan-e-o-planner` e esta). Some com `jq`, ou
  com `LC_ALL=C awk` (sob pt-BR o `mawk` lê `1.99` como 1). Diga a ressalva: o L3 é código de gate
  com mutante, e os outros dois foram prosa com asserção; a comparação não isola o effort.
- A §4 de `.claude/rules/anatomia-do-agente.md` descreve o `gate_REVIEW`, o `gate_PR` e o K8 de
  antes: proponha o parágrafo novo numa linha `⛔`, citando a ADR 0024.
- `CONTEXT.md` e `docs/failure-modes.md`: veja se o `blocked` da rodada e o `TEST_CMD` que não
  rodou pedem verbete.

## Arquitetura da mudança

Nenhum gate novo e nenhuma fase nova. Cinco gates que já existem aprendem a ler o que afirmam, e
dois chapéus e três templates ganham as regras que os gates não conseguem cobrar.

| Arquivo | O que muda | Incremento |
|---|---|---|
| `bin/sdd` — `run_check_cmd`, `gate_EXEC`, `gate_QA`, `gate_REVIEW` | o rc do comando é publicado; um `TEST_CMD` que sai 126 ou 127 tem motivo próprio, numa definição só | I1 |
| `bin/sdd` — `gate_PR`, `gate_REVIEW`, o comentário do `GATE_HANDOFF_BLOCKED` | os dois gates armam o marcador no `status: blocked` | I2 |
| `bin/sdd` — `mission_tip` (nova), `gate_PR` | o head do PR contra o head da missão; o `verified_head:`; o PATCH da REST no motivo | I3 |
| `bin/sdd` — `gate_REVIEW` (função nova ao lado de `review_head_ok`) | código commitado depois da rodada reabre a fase | I4 |
| `bin/sdd` — bloco K8 do `gate_DOCS` | o intervalo sai de `mission_tip`, e o motivo nomeia o branch | I5 |
| `bin/sdd` — braço `up` do e2e vermelho no `gate_QA` | o histórico de cada caso vermelho | I6 |
| `bin/sdd` — `gate_PR` | a contagem das linhas `kit:` no corpo | I7 |
| `agents/sdd-publisher.md` + espelho | o `git merge` (I2); o `verified_head:`, o commit do registro e a REST (I3); as linhas `kit:`, o "how to verify" e a pendência respondida (I7) | I2, I3, I7 |
| `agents/sdd-reviewer.md` + espelho | o que `blocked` significa (I2); a frase da reabertura (I4) | I2, I4 |
| `templates/review.md` | `status:` (I2) e `gate:` (I8) | I2, I8 |
| `templates/pr-body.md` | as linhas `kit:`, a pendência respondida e a linha do `sdd preflight` | I7 |
| `templates/handoff.md` | `gate:` | I8 |
| `docs/pipeline.md` | a seção de cada gate, no commit do gate | I1 a I7 |
| `tests/check-gates.sh`, `tests/check-autonomy.sh`, `tests/check-hat.sh`, `tests/check-templates.sh`, `tests/check-kaizen.sh` (um stub) | as 30 asserções e os stubs de `gh` | todos |
| `tests/check-mutation.sh` | 16 mutantes | I1 a I7 |
| `TODO.md` | âncoras a cada commit, `RESOLVED by` no fecho | todos |

**O `gate_PR` depois do lote, na ordem em que ele pergunta** (cada passo recusa com `return 1`):

1. `50-pr.md` existe;
2. `status:` presente é `done` ou `blocked`; `blocked` arma o marcador (I2);
3. `pr_url:` existe;
4. **uma** chamada ao `gh`: `gh pr view "$url" --json url,state,headRefOid --jq '.url, .state, .headRefOid'`
   (I3). Sem url na resposta: o motivo de hoje (`gh does not confirm PR …`). Com url e sem um estado
   e um sha legíveis: motivo próprio (`could not read the head of PR …`);
5. estado `MERGED`: pula os passos 6, 7 e 8 (o `⛔` já fazia isso para o corpo);
6. `headRefOid` igual a `mission_tip` (I3); sem `mission_tip`, pula;
7. `verified_head:` presente é commit, ancestral do head, sem caminho fora da pasta da missão
   entre ele e o head (I3); ausente, passa;
8. o corpo, lido uma vez e só quando há `⛔` ou `kit:` a procurar: os `⛔` (como hoje) e a
   contagem das linhas `kit:` (I7);
9. o carimbo de mutação, **por último**, como hoje.

**`mission_tip`** (I3; segundo leitor no I5). Só imprime, então pode ser lida por `$( )`. Regras,
pela primeira que casar: o `branch:` do `00-missao.md` não declarado (pela `mission_branch_declared`,
que já existe: não reescreva a regra dela) → `git rev-parse HEAD`; `git branch --show-current` igual ao `branch:` → `git rev-parse HEAD`;
`refs/heads/<branch>` resolve → esse commit; `refs/remotes/origin/<branch>` resolve → esse commit;
senão → nada (linha vazia). Toda captura guardada.

## Incrementos

A tabela executável vive em `checkpoint.md` (é ela que o runner lê). Aqui fica o **porquê** de
cada fatia — o detalhe que não cabe numa célula.

**Em todo incremento, nesta ordem:** (1) escreva a asserção e veja-a vermelha no sensor sozinho,
pelo motivo certo; (2) implemente; (3) veja-a verde; (4) escreva o mutante e prove-o com `--only`
(anote nas notas `<slug> caught by <sensor>`); (5) `bash -n bin/sdd`, `shellcheck -S warning` nos
arquivos tocados, `bash tests/check-lang.sh`, `bash tests/check-todo.sh --anchors TODO.md`
(`0 off target`), e, se editou um chapéu, `./bin/sdd install --force` e o `cmp` do espelho; (6) a
suíte inteira; (7) o commit, com o porquê no corpo; (8) o checkpoint e a nota, como último ato. As
frases das asserções abaixo são **exatas**: os Checks do `checkpoint.md` as leem byte a byte.

### I1 — O `TEST_CMD` que não rodou não é suíte vermelha (item 5)

**O quê:** hoje `run_check_cmd` devolve o rc, e os quatro sítios escrevem `TEST_CMD failed (…)`
para qualquer não-zero (`grep -n 'TEST_CMD failed' bin/sdd` → dois no `gate_EXEC`, um no `gate_QA`,
um no `gate_REVIEW`, e mais comentários). Um `.venv/bin/python` que não existe sai rc 127 e é lido
como suíte reprovada. Depois:

- `run_check_cmd` publica o rc num global `LAST_CHECK_RC`, **nos dois caminhos** (o da execução e o
  do memo `_CHECK_RC`), ao lado do `LAST_CHECK_LOG`;
- uma definição só monta o motivo de um `TEST_CMD` não-zero, e os quatro sítios a usam. Com rc 126
  ou 127 o motivo é, em inglês:
  `TEST_CMD did not run (rc <rc>: <linha>) — the suite never started, so this is not a red suite; this tree misses what the command names (a worktree is born without ignored paths such as .venv or node_modules)`,
  sem o trecho `See <log>` (veja o aviso abaixo), onde `<linha>` é a última linha do log que casa `No such file or directory`, `not found` ou
  `Permission denied` (cortada em 200 bytes; sem linha assim, só `rc <rc>`). Com outro rc, o motivo
  de hoje, byte a byte. ⚠️ O motivo do 126/127 **não cita o log** (a linha citada já é a evidência):
  o `no_work_check` ignora todo motivo que casa `[Ss]ee <algo>.log` (`grep -n '^gate_why_cites_log()' bin/sdd`),
  porque o nome do log muda a cada execução; sem o log, o motivo é estável e a segunda volta sobre a
  mesma árvore para como `no-work`, antes de comprar outra sessão;
- no `gate_EXEC`, o braço do 126/127 vem **antes** do braço da árvore suja e **não** arma o
  `GATE_EXEC_DIRTY`: a frase da árvore suja ("the uncommitted changes are what the suite is running
  against") seria falsa para uma suíte que nem começou. Diga isso no comentário.

O dono do que o motivo pede é o humano (a árvore é dele); o gate não exige artefato novo de
ninguém. O quinto sítio que o `grep` mostra, o `warn` do `sdd preflight` sobre o manifesto que
falta, não é gate e fica como está.
**Onde:** `bin/sdd`, `tests/check-gates.sh`, `tests/check-mutation.sh`, `docs/pipeline.md` (`### EXEC`).
**Como (TDD):** no bloco do EXEC de `tests/check-gates.sh`, troque o `TEST_CMD` do fixture por um
caminho relativo que não existe (`.venv/bin/python -m pytest`), leia `sdd why … EXEC` e exija
`did not run (rc 127`, o texto `No such file or directory`, **a ausência** de `TEST_CMD failed` e a
ausência de `.log` no motivo.
Um segundo mundo com um arquivo sem permissão de execução dá o 126. A segunda asserção lê o mesmo
de `sdd why … QA` e `sdd why … REVIEW`, cada um num bloco em que o gate **chega** à suíte: o da QA
depois das âncoras do relatório (`grep -n 'gate-qa-test\|qa_refused' tests/check-gates.sh`), o da
REVIEW com uma rodada nota A e `reviewed_head:` válido (o bloco de `write_r12`). Nenhum fixture de
gate usa hoje um comando que não existe como `TEST_CMD` (o vermelho deles é `false`, rc 1).
Hoje as duas são vermelhas: o motivo diz `TEST_CMD failed`. Devolva o `TEST_CMD` do fixture.

| Sensor | Frase exata |
|---|---|
| `check-gates.sh` | `gate_EXEC says the TEST_CMD did not run when it exits 126 or 127, and names what the tree misses` |
| `check-gates.sh` | `gate_QA and gate_REVIEW say the same of a TEST_CMD that did not run` |

Mutante: `RUN_test_cmd_not_run_reads_red` (o braço do 126/127 volta a escrever `TEST_CMD failed`).
**Check:** linha I1 → `1 1 1`. Antes: `0 0 0`.
**Sensor durável:** as duas asserções em `tests/check-gates.sh` e o mutante.
**Reversível por:** `git revert` do commit; nenhum artefato muda de forma.

### I2 — O `blocked` para a linha, e a saída do conflito é `git merge` (itens 6 e 7)

**O quê:**

- **`gate_PR`:** zera `GATE_HANDOFF_BLOCKED` na entrada. Logo depois de achar o arquivo, lê
  `status:`. `blocked` arma o marcador e recusa com
  `50-pr.md has status: blocked — if it stopped on a conflict with the base, merge the base into the mission branch ('git merge origin/<DEFAULT_BRANCH>') and never rebase: the checkpoint and the handoffs cite commit hashes that gate_EXEC looks up in the history of HEAD; then remove the status line of 50-pr.md and 'sdd run'`
  (com o valor de `DEFAULT_BRANCH`). `status:` presente com outro valor que não `done` é recusado
  pelo nome; ausente, segue como hoje. Tudo isso **antes** de ler o `pr_url`: o `50-pr.md`
  bloqueado não tem PR.
- **`gate_REVIEW`:** zera o marcador na entrada. Depois de resolver a rodada mais nova (`$last`) e
  antes de ler as notas, `status: blocked` arma o marcador e recusa com
  `<rodada>: status: blocked`, onde `<rodada>` é o basename do arquivo e **abre** o motivo (o
  `historic_rounds` lê o prefixo `^40-review-r[0-9]+\.md`; vale para todo motivo novo do
  `gate_REVIEW`, no I4 também). Outros valores seguem como hoje (limite declarado no comentário: o
  enum positivo da rodada fica fora, porque 1 das 55 rodadas em disco diz `continua`).
  ⚠️ O comentário no topo do `gate_REVIEW` diz "NO reset-on-entry" sobre **outro** global
  (`GATE_REVIEW_ROUNDS`); não o apague, e diga ao lado que o marcador do `blocked` tem a regra dele.
- **O comentário do `GATE_HANDOFF_BLOCKED`** (`grep -n '^GATE_HANDOFF_BLOCKED=0' bin/sdd`) diz
  "Two setters today". Passam a ser quatro, e ele **re-deriva** o contrato em vez de herdá-lo: a
  caminhada visita TICKET, QA, REVIEW e PR nessa ordem; gate que passa deixa o marcador em 0; gate
  que arma falha e a caminhada para ali; toda volta que o acha armado devolve 3. Confira lendo as
  duas portas de `handoff_blocked_escalation` no laço do `cmd_run`
  (`grep -cE '^ +if handoff_blocked_escalation "\$phase"; then' bin/sdd`) que nenhuma delas é pulada
  para REVIEW ou PR; se achar um caminho que sai da volta com o marcador armado, pare e anote.
- **Limite a declarar no comentário, sem conserto:** acima do teto de rodadas o `cmd_run` roda
  `gate_REVIEW || true` e não lê o marcador; a rodada `blocked` no teto termina em
  `budget-exhausted`, e sob `PUBLISH_ON_REVIEW_BLOCKED=draft` vira PR em rascunho com a nota real.
- **Donos:** o `sdd-publisher` escreve o `50-pr.md` e o `sdd-reviewer` escreve a rodada; quem tira
  o `blocked` é o humano, depois de agir. Diga isso no comentário de cada braço.
- **Publisher** (`### 3. Push`, parágrafo "Conflict with the base? Stop."): acrescente que o motivo
  escrito no `50-pr.md` nomeia a saída, `git merge origin/<DEFAULT_BRANCH>` feito pelo humano no
  branch da missão, e nunca `git rebase`, porque o checkpoint e os handoffs citam hashes. Mantenha a
  palavra `Conflict` e o literal `status: blocked` (âncoras de dois itens).
- **Revisor:** na seção `## 4. Write the round report`, uma frase:
  `` `status: blocked` is only for a round that could not be done or that waits for a human decision, never for a round that has findings: that one is `done`, with its real grades ``
  (numa linha física).
- **`templates/review.md`**, linha `status:`: passa a
  `status: <done | blocked — blocked só para a rodada que não pôde ser feita ou que espera decisão humana; rodada com achados é done, com a nota real>`.
  Confira antes que nenhuma regex de `tests/check-templates.sh` lê a linha antiga
  (`grep -n 'status' tests/check-templates.sh`). A asserção nova do `review.md` entra por
  `review_check`, dentro do trecho contado (entre `REVIEW_MARK` e o piso), e o `REVIEW_FLOOR` sobe
  de 26 para 27 neste commit.

**Onde:** `bin/sdd`, `agents/sdd-publisher.md`, `agents/sdd-reviewer.md` e os dois espelhos,
`templates/review.md`, `docs/pipeline.md` (`### REVIEW` e `### PR`), os quatro sensores e
`tests/check-mutation.sh`.
**Como (TDD):** em `tests/check-gates.sh`, um `50-pr.md` com `status: blocked` e sem `pr_url`: o
motivo traz `status: blocked`, `git merge origin/main` e `never rebase`, e **não** traz `pr_url`.
Uma rodada mais nova com `status: blocked`: o motivo traz o nome dela e `status: blocked`. Em
`tests/check-autonomy.sh`, pelo molde do par da TICKET: `sdd run` sobre cada um dos dois mundos
sai rc 3, com a linha `handoff-blocked` no ledger nomeando a fase certa (`PR`, `REVIEW`) e **uma
sessão** gasta, contra um mundo ordinário que gasta duas e termina em `no-progress` (a forma do par
da TICKET: `3|1|blocked|handoff-blocked · 3|2|blocked|no-progress`). As duas portas ficam **depois**
do `run_phase`, então a primeira sessão sempre roda: o que o marcador poupa é a segunda. Não
acrescente uma terceira porta. ⚠️ Aquele fixture está parado na QA: para chegar à REVIEW e ao PR,
force a fase (`"$SDD" run "$MISSION" --phase REVIEW`, `--phase PR`), conferindo que a volta forçada
passa pelas mesmas portas, ou monte os gates anteriores verdes; e mantenha menos rodadas em disco
que o `REVIEW_MAX_ITER`, ou a corrida termina em `budget-exhausted` antes de qualquer gate armar. Hoje: o `50-pr.md` bloqueado é
recusado por `no 'pr_url:'` e compra sessão; a rodada bloqueada com nota A passa.

| Sensor | Frase exata |
|---|---|
| `check-gates.sh` | `gate_PR arms the blocked marker on a 50-pr.md that declares status blocked, and names the merge of the base` |
| `check-gates.sh` | `gate_REVIEW arms the blocked marker on a round that declares status blocked` |
| `check-autonomy.sh` | `PR: status blocked in 50-pr.md escalates as handoff-blocked with no second publisher session` |
| `check-autonomy.sh` | `REVIEW: status blocked in the newest round escalates as handoff-blocked with no further round` |
| `check-hat.sh` | `hat: the publisher names the merge of the base as the way out of a conflict, never a rebase` |
| `check-hat.sh` | `hat: the reviewer writes status blocked only for a round that could not be done, never for one with findings` |
| `check-templates.sh` | `review.md: status blocked is the round that could not be done, never the round with findings` |

Mutantes: `RUN_pr_blocked_not_armed`, `RUN_review_blocked_not_armed` (cada setter volta a 0, no
molde de `mut_RUN_ticket_blocked_not_armed`). O sensor que os pega é `tests/check-autonomy.sh`.
**Check:** linha I2 → `1 1 1 1 1 1 1 2 0 0`. Antes: `0 0 0 0 0 0 0 0 0 0`.
**Sensor durável:** as sete asserções e os dois mutantes.
**Reversível por:** `git revert` do commit. O `PUBLISH_ON_REVIEW_BLOCKED=draft` não muda: as
asserções dele (`grep -n 'PUBLISH_ON_REVIEW_BLOCKED' tests/*.sh`) têm de seguir verdes.

### I3 — O `gate_PR` lê o head, o registro grava o sha verificado, e o corpo se edita pela REST (itens 1, 2 e 13)

**O quê:** os passos 4 a 7 da lista do `gate_PR` em "Arquitetura da mudança", e a ADR 0024,
decisões 1, 2 e 3.

- `mission_tip`, como descrita acima, escrita perto de `mission_base_refs`.
- A chamada única ao `gh` e os três desfechos (não confirma; confirma e não se lê o head; lido).
  Um sha "legível" é `^[0-9a-f]{40,64}$`, e um estado é `OPEN`, `CLOSED` ou `MERGED`.
- Head diferente: `PR <url> is at <sha curto>, and the mission is at <sha curto> — push the mission branch ('git push'); the PR must carry what the mission closed`.
- `verified_head:` presente e errado, três motivos, cada um nomeando `50-pr.md`: não é commit; o
  head não o carrega; `<caminho> changed between verified_head <sha curto> and the head — run the checks of step 2 again on the head and write the new sha`.
  O intervalo é listado com `git -c core.quotePath=false diff --name-only <verified> <tip>`, e
  "dentro da pasta da missão" é o prefixo `$HANDOFF_DIR/<missão>/`. Um `git diff` que falha recusa
  (falha fechada), como a regra 4 do `review_head_ok`.
- **Dono:** o `sdd-publisher`. Ele empurra, e regrava o `verified_head:` depois de rodar o passo 2
  de novo. Diga isso no comentário.
- A leitura do corpo fica como está (`--json state,body`): o estado é lido de novo ali, e a asserção
  de hoje sobre o PR `MERGED` e o braço do stub que a serve não mudam.
- `docs/pipeline.md`, seção `### PR`: a frase que hoje diz `gh pr edit` passa ao PATCH.
- **O motivo dos `⛔`** troca `edit its body ('gh pr edit')` por
  `edit its body ('gh api -X PATCH repos/{owner}/{repo}/pulls/<n> -F body=@<file>')`, com o número
  do PR tirado do fim da url. Medido no `gh` 2.85.0: `gh api 'repos/{owner}/{repo}/pulls/456' --jq .number`
  → `456` (o `gh` resolve os dois marcadores pelo repositório do diretório).
- **Publisher:**
  - `### 4.`, parágrafo "The PR already exists?": o corpo se troca com
    `gh api -X PATCH repos/{owner}/{repo}/pulls/<n> -F body=@<file>`, e a frase diz
    `` never `gh pr edit`, which fails on gh 2.45 and leaves the body as it was ``;
  - `### 5. Record it`: o frontmatter ganha
    `verified_head: <the git rev-parse HEAD on which step 2 ran, the full sha>`; o `gate:` de
    exemplo vira `gate: "gh pr view <url> --json headRefOid → <sha>, the head pushed"`; e o texto
    diz que o registro é commitado `in a commit that touches the mission directory alone` e que
    `git push` vem depois dele, para o head do PR ser o da missão. Diga também o caso da volta: PR
    aberto e código novo no head → rodar o passo 2 de novo, regravar o `verified_head:`, commitar e
    empurrar.
- **Os três stubs de `gh`** passam a responder à pergunta nova: url, estado (`OPEN` por padrão) e o
  head. Em `tests/check-gates.sh`, o head padrão do stub é o `git rev-parse HEAD` do fixture na
  hora da chamada, com um arquivo de controle (`$FIX/.sdd/logs/pr-head`) para fixar outro; o de
  `tests/check-kaizen.sh` responde o `HEAD` do repositório em que roda.

**Onde:** `bin/sdd`, `agents/sdd-publisher.md` e o espelho, `docs/pipeline.md` (`### PR`),
`tests/check-gates.sh`, `tests/check-kaizen.sh`, `tests/check-hat.sh`, `tests/check-mutation.sh`.
**Como (TDD):** no bloco do `gate_PR`, depois do bloco dos `⛔`: (a) `pr-head` com um sha que não
é o `HEAD` → recusa com os dois shas; (b) `verified_head:` igual a um commit antigo e um commit de
código depois dele → recusa nomeando o caminho; o mesmo com só um commit em `$MDIR` depois dele →
passa (o par diferencial); (c) sem `verified_head:` → passa; `pr-state` = `MERGED` com `pr-head`
errado → passa; (d) stub respondendo a url e lixo no lugar do estado e do sha → o motivo traz
`could not read the head` e **não** traz `is at`. Hoje (a), (b) e (d) passam verdes sem recusa.

| Sensor | Frase exata |
|---|---|
| `check-gates.sh` | `gate_PR refuses a pull request whose head is not the head of the mission, and names both` |
| `check-gates.sh` | `gate_PR refuses a verified_head that does not cover the head, and passes when only the mission folder changed after it` |
| `check-gates.sh` | `gate_PR passes a 50-pr.md with no verified_head, and does not read the head of a merged pull request` |
| `check-gates.sh` | `gate_PR says it could not read the head, never that the head differs` |
| `check-hat.sh` | `hat: the publisher records verified_head, commits 50-pr.md alone in the mission folder and pushes it` |
| `check-hat.sh` | `hat: the publisher and gate_PR edit the body of a pull request through the REST PATCH` |

A segunda asserção do chapéu lê o literal `gh api -X PATCH` no chapéu **e** no `bin/sdd`.
Mutantes: `PR_head_unread` (a comparação do head vira verdadeira), `PR_verified_head_unchecked`,
`PR_merged_head_read` (o `MERGED` deixa de pular), `PR_head_unreadable_passes`.
**Check:** linha I3 → `1 1 1 1 1 1 4 0`. Antes: `0 0 0 0 0 0 0 0`.
**Sensor durável:** as seis asserções e os quatro mutantes.
**Reversível por:** `git revert` do commit. Um `50-pr.md` já escrito com `verified_head:` continua
válido para o gate antigo, que não lê a chave.

### I4 — Código commitado depois da rodada reabre a REVIEW (item 4)

**O quê:** ADR 0024, decisão 4. Uma função nova ao lado de `review_head_ok`
(`review_later_code_ok <rodada>`), chamada pelo `gate_REVIEW` logo depois dela:

- sem `reviewed_head:` na rodada → passa (as rodadas antigas; e a rodada cujo `reviewed_head:` é
  inválido já foi recusada uma linha acima);
- o commit da rodada é o que a **adicionou** (a mesma leitura do `review_head_ok`:
  `git log -1 --diff-filter=A --format=%H -- <rodada>`, com `-c log.showSignature=false`); sem
  commit → passa (a recusa da árvore suja, abaixo, cobre a rodada não commitada);
- os commits lidos: `git rev-list <commit da rodada>..HEAD --not <mission_base_refs>`. Lista vazia
  → passa (é a missão já mergeada, e a que não andou). **Sem `--no-merges`:** o `diff-tree` abaixo,
  sem `-m`, não imprime caminho nenhum para um commit de merge (medido no git 2.43.0 pela sessão de
  autocontenção), e o que o merge trouxe da base sai pelo `--not`. Regra redundante não se escreve;
- para cada commit, os caminhos (`git -c core.quotePath=false diff-tree --no-commit-id --name-only -r <commit>`);
  o primeiro caminho que não cabe em `hat_writes REVIEW` nem em `hat_writes DOCS` recusa com
  `<rodada>: <caminho> changed in <sha curto>, committed after the round — code no later hat writes reopens REVIEW; the next round is a delta from the round's reviewed_head`;
- um `rev-list` ou `diff-tree` que falha recusa (falha fechada).

**Dono:** o `sdd-reviewer`, que escreve a rodada seguinte. Diga no comentário, e declare os dois
limites da ADR: o `writes:` da DOCS fica de fora (lote L6b da campanha), e a resolução de um merge
da base não é lida (o `sdd-worker pr-ready` a lê).
No chapéu do revisor, no parágrafo do `reviewed_head:` da seção 4, uma frase numa linha física:
`Code committed after the round reopens REVIEW: the gate reads the commits after the one that added the round, and a path outside what this hat and the DOCS hat write refuses it`.
**Onde:** `bin/sdd`, `agents/sdd-reviewer.md` e o espelho, `docs/pipeline.md` (`### REVIEW`),
`tests/check-gates.sh`, `tests/check-hat.sh`, `tests/check-mutation.sh`.
**Como (TDD):** ⚠️ o fixture de `tests/check-gates.sh` fica no `main`, que é o `DEFAULT_BRANCH`: ali
o intervalo `--not <base>` é sempre vazio e nenhum mundo fica vermelho. Corte um branch de missão
para estes mundos, como o bloco do K8 faz (`grep -n 'missao/k8-entry' tests/check-gates.sh`), e
volte ao `main` ao fim. **Não mova para esse branch** a asserção que já existe
`gate_REVIEW: reviewed_head reads the commit that added the round, not a later one that touched it`:
ela commita um arquivo de código depois da r12 e espera `DOCS`, e só passa por estar na base.
No branch de missão, com uma rodada r12 nota A cujo `reviewed_head:` é o `HEAD`: (a) um commit que toca um arquivo de código do fixture → a fase
derivada volta a `REVIEW` e o motivo traz o caminho e o sha curto; (b) quatro mundos que **passam**:
um commit só em `$MDIR` e em `README.md` (o `writes:` da DOCS); um merge da base (`git merge --no-ff main`,
com um commit de código novo no `main`), cujo código já está na base; a rodada sem
`reviewed_head:` seguida de um commit de código; e a missão com o `HEAD` já contido na base. Hoje
(a) passa sem recusa. ⚠️ O mundo (a) tem de ficar vermelho **pelo motivo certo**: exija o texto
`committed after the round` e a ausência dos motivos do `review_head_ok` (`changed between`).

| Sensor | Frase exata |
|---|---|
| `check-gates.sh` | `gate_REVIEW reopens the phase for code committed after the round, and names the commit and the path` |
| `check-gates.sh` | `gate_REVIEW passes later commits in what the REVIEW and DOCS hats write, a merge of the base, a merged mission and a round with no reviewed_head` |
| `check-hat.sh` | `hat: the reviewer is told that code committed after the round reopens REVIEW` |

Mutantes: `REVIEW_later_code_unread` (a função devolve 0 sempre), `REVIEW_later_docs_writes_counted`
(o `hat_writes DOCS` sai da conta), `REVIEW_later_merged_mission_refused` (o `--not <base>` some; o
mundo do merge da base e o da missão contida o pegam). Se um deles sobreviver, falta o mundo.
**Check:** linha I4 → `1 1 1 3 0`. Antes: `0 0 0 0 0`.
**Sensor durável:** as três asserções e os três mutantes.
**Reversível por:** `git revert` do commit; nenhuma rodada em disco muda.

### I5 — O K8 mede o branch que a missão declara (item 11)

**O quê:** ADR 0024, decisão 5. No bloco K8 do `gate_DOCS` (`grep -n 'k8_nots' bin/sdd`), o
intervalo, os merge-bases e o `diff-tree` passam a ler a ponta da missão no lugar de `HEAD`:
`tip="$(mission_tip)"` uma vez; `tip` vazio → o bloco inteiro é pulado (intervalo vazio, passa);
`git merge-base "$tip" "$k8_c"`, `git rev-list -n 1 "$tip" --not …`, `git diff-tree … "$k8_b" "$tip"`.
A recusa passa a dizer `the mission branch (<branch>) adds no KAIZEN_LOG.md entry of its own`, com
o nome do `branch:` (ou `HEAD` quando a chave está vazia). O resto da frase fica byte a byte: as
asserções de hoje a leem (`grep -n 'adds no KAIZEN_LOG' tests/*.sh`), e se alguma ler o trecho
`the mission branch adds no`, troque o literal dela no mesmo commit. O dono da entrada continua
sendo o `sdd-docs`. Re-ancore o item 11 do `TODO.md` (símbolo `mission_tip`, veja "O `TODO.md`").
**Onde:** `bin/sdd`, `docs/pipeline.md` (`### DOCS`), `tests/check-gates.sh`,
`tests/check-mutation.sh`, `TODO.md` (a âncora).
**Como (TDD):** com os ajudantes `k8_*`, num mundo em que o branch da missão **não** traz a
entrada: (a) saia para um branch posterior com um commit próprio que traz uma entrada citando a
missão → hoje passa (lê `HEAD`); depois recusa, e o motivo nomeia o branch declarado; o inverso
(branch da missão com a entrada, lido de um branch posterior sem commit de entrada) passa; (b)
apague o branch declarado, ou faça a base contê-lo, e leia de um branch posterior com commit
próprio → hoje recusa (`adds no KAIZEN_LOG.md entry`); depois passa. O fixture precisa de um
`branch:` real no `00-missao.md` do mundo; devolva-o ao fim. Os mundos novos moram **dentro** do
bloco do K8, antes da desmontagem dele (`git checkout -q main; git branch -q -D missao/k8-entry`).
A `mission_tip` muda a resposta onde o `HEAD` está fora de um `branch:` que ainda resolve: se uma
asserção antiga ficar vermelha (há um worktree destacado no bloco do carimbo, `grep -n 'worktree add' tests/check-gates.sh`),
leia o mundo dela antes de mexer no gate.

| Sensor | Frase exata |
|---|---|
| `check-gates.sh` | `K8 measures the branch the mission declares when HEAD is on another branch, and names it` |
| `check-gates.sh` | `K8 reads an empty range when the declared branch is gone or already in the base` |

Mutantes: `DOCS_k8_reads_head_off_branch` (o `tip` do K8 volta a `HEAD`),
`DOCS_k8_gone_branch_refused` (o `tip` vazio deixa de pular).
**Check:** linha I5 → `1 1 2`. Antes: `0 0 0`.
**Sensor durável:** as duas asserções e os dois mutantes.
**Reversível por:** `git revert` do commit.

### I6 — O e2e vermelho diz se o caso já caiu antes (item 10)

**O quê:** no `gate_QA`, no braço `up` do e2e vermelho (o motivo que começa
`E2E_CMD failed (…) with the app answering at`), acrescentar o histórico de cada caso vermelho. Só
nesse braço: nos outros dois o app está fora e todo caso cai.

- **Os casos vermelhos** são as linhas do bloco `N failed` do Playwright: da linha
  `^  <n> failed$` até a próxima linha `^  <n> <palavra>` (`flaky`, `skipped`, `passed`,
  `did not run`, `interrupted`), cada linha de caso tem a forma
  `    [<projeto>] › <arquivo>:<linha>:<coluna> › <título>`. A chave é `<arquivo>:<linha>`.
- **Os logs anteriores** são os `gate-qa-e2e-*.log` de `$REPO_ROOT/.sdd/logs/*/` (toda missão do
  repo), menos o log desta execução, ordenados pelo nome do arquivo (o nome traz data e hora), os
  50 mais novos.
- **O que se acrescenta ao motivo**, antes do `See <log>`: para cada caso (até 5; depois
  `and <m> more`), `<arquivo>:<linha> already failed in <k> of the last <n> e2e gate logs`, onde
  `<k>` conta os logs em cujo **bloco de falhas** a chave aparece. Com `<k>` igual a 0:
  `<arquivo>:<linha> never failed in the last <n> e2e gate logs`. Sem log anterior, ou sem o bloco
  no log desta execução: nada, e o motivo fica byte a byte o de hoje.
- Limite declarado no comentário: só o formato do Playwright é lido; o `<n>` é dos logs que esta
  máquina guarda.

**Proveniência do fixture** (regra do `CLAUDE.md`: fixture de saída de terceiro é copiado, não
escrito de memória). Copiado em 2026-11-21 de
`/home/joruge/repos/sales_quote/.sdd/logs/20260830-o-rascunho-fantasma-do-mount/gate-qa-e2e-20260830-172116-xrg0TF.log`
(o fim do log; a linha em branco antes do contador faz parte):

```

  1 failed
    [chromium] › e2e/sq113-copia-de-itens-persiste.spec.ts:121:7 › <título>
  88 passed (5.0m)
```

e, de um log verde
(`…/20261018-silencios-do-formulario-e-dos-dialogos/gate-qa-e2e-20261018-183347-pPGzue.log`), a
forma da linha de um caso que **passou**, que traz o mesmo `arquivo:linha` fora de qualquer bloco:

```
  ✓  172 [chromium] › e2e/sq98-vocabulario-do-pagamento.spec.ts:101:7 › <título>

  4 skipped
  168 passed (9.2m)
```

O `<título>` dos dois é texto em português no log real: no fixture, corte a linha depois do
segundo ` › ` e escreva `title` no lugar, dizendo isso no comentário de proveniência
(`tests/check-lang.sh` cobra inglês em `tests/`, e o parser não lê o título).
**Onde:** `bin/sdd`, `docs/pipeline.md` (`### QA`), `tests/check-gates.sh`, `tests/check-mutation.sh`.
**Como (TDD):** o braço `up` só é alcançado no mundo do servidor de página
(`grep -n '^start_page_server()\|with the app answering' tests/check-gates.sh`). ⚠️ Cada avaliação
do gate grava um `gate-qa-e2e-*.log` novo em `$FIX/.sdd/logs/$MISSION/`, e o script já fez mais de
cem antes desse mundo: **apague só os `gate-qa-e2e-*.log`** de `$FIX/.sdd/logs/*/` (o `pipeline.log`
mora na mesma pasta e outras asserções o leem), semeie os três logs, avalie o mundo vermelho **uma
vez** (`sdd why … QA`) e guarde a saída numa variável, porque a segunda avaliação já contaria o log
da primeira. "Ordenados pelo nome" é pelo basename, já que os logs vêm de pastas diferentes.
Nesse mundo, faça o `E2E_CMD` do fixture
imprimir o bloco vermelho e sair 1, e semeie em `$FIX/.sdd/logs/<outra-missão>/` três logs
`gate-qa-e2e-…log` com data anterior no nome: dois com o mesmo caso no bloco de falhas e um verde com o mesmo
`arquivo:linha` numa linha `✓`. O motivo tem de trazer `already failed in 2 of the last 3`. A
segunda asserção: com o `E2E_CMD` imprimindo um log sem o bloco, o motivo é byte a byte o de hoje;
e o log verde **não** entra na conta (o `2 of the last 3` acima já o prova; diga no nome do mundo).
Hoje o motivo não traz histórico nenhum. Apague os logs semeados ao fim.

| Sensor | Frase exata |
|---|---|
| `check-gates.sh` | `gate_QA says how often each red e2e case already failed in the earlier e2e gate logs` |
| `check-gates.sh` | `gate_QA adds nothing for a log with no failed block, and counts no case that passed` |

Mutantes: `QA_e2e_history_uncounted` (o histórico deixa de ser acrescentado),
`QA_e2e_history_counts_passed` (a conta lê o log inteiro, e não o bloco).
**Check:** linha I6 → `1 1 2`. Antes: `0 0 0`.
**Sensor durável:** as duas asserções e os dois mutantes.
**Reversível por:** `git revert` do commit; o motivo é prosa para o humano e para o `sdd-qa`, e
nenhum leitor o parseia (`grep -n 'with the app answering' tests/*.sh bin/sdd` mostra quem lê o
começo da frase, que não muda).

### I7 — O corpo do PR leva o que os handoffs dizem (itens 8, 9 e 12)

**O quê:**

- **`gate_PR`, as linhas `kit:`** (passo 8 da lista). Uma função nova conta as linhas dos handoffs
  da missão (`$MISSION_DIR/[0-9][0-9]-*.md`, menos `00-missao.md`, `01-plano.md` e `50-pr.md`) que
  casam `^[[:space:]]*- kit:` **fora de cerca** (`FENCE_AWK`); a linha de exemplo do template mora
  numa citação (`> - kit:`) e não casa. Com a conta maior que zero e o PR não `MERGED`, o corpo tem
  de trazer ao menos esse número de linhas `^[[:space:]]*- (\[[ xX]\] )?kit:`. Menos que isso:
  `PR <url> carries <k> of the <n> kit: line(s) of the handoffs — a finding about the kit travels in the PR body or is lost; copy each line whole and edit the body ('gh api -X PATCH …')`.
  O corpo é pedido ao `gh` **uma vez** para os `⛔` e os `kit:`, e nem uma vez sem nenhum dos dois;
  o corpo ilegível mantém o motivo próprio de hoje (`could not read the body of PR`), que passa a
  dizer `the ⛔ rows and the kit: lines are not checked`. Confira que as asserções de hoje sobre o
  corpo (`grep -n 'could not read the body\|does not carry the ⛔' tests/check-gates.sh`) seguem
  verdes, trocando o literal da que ler o trecho mudado.
  **Dono:** o `sdd-publisher`, que escreve o corpo.
- **Publisher, `### 4.`:**
  - bullet **how to verify**: `only what the reader's shell runs`; quando o `TEST_CMD` cita uma
    variável do runner (`$SDD_HOME`, `$TODO_FILE`, `$DEFAULT_BRANCH`), a linha do gate é
    `sdd preflight`, com a frase `it runs TEST_CMD in the runner's environment`; os comandos
    próprios do projeto seguem literais. Mantenha as palavras `how to verify` (âncora);
  - bullet **decisions for a human**: cada pergunta do `00-missao.md` é conferida contra os
    handoffs posteriores; a que um deles responde sai `- [x]`, com
    `the answer in one line and the file that gave it`, e nunca some; as outras seguem `- [ ]`.
    Mantenha as palavras `decisions for a human` (âncora);
  - bullet **out-of-scope findings**: além do que foi ao `TODO_FILE`, toda linha `- kit:` dos
    handoffs entra no corpo `whole, one line each`, porque `the runner counts them`. Mantenha o
    literal `TODO_FILE` (âncora).
- **`templates/pr-body.md`:** em "Como verificar", um comentário de preenchimento dizendo que o
  gate vai por `sdd preflight` quando o `TEST_CMD` usa variável do runner; em "Pendências", uma
  linha-modelo `- [x] <pendência do plano já respondida> — <a resposta em uma linha> (`<handoff>`)`;
  em "Achados fora de escopo", uma linha-modelo `- kit: <a linha completa do handoff>`. ⚠️ A
  linha-modelo `- kit:` do template não é contada pelo gate (ele lê os handoffs e o corpo do PR,
  nunca o template), mas confira que nenhum sensor varre `templates/` atrás de `kit:`
  (`grep -n 'kit:' tests/check-templates.sh`). A asserção do `pr-body.md` lê três literais em três
  linhas diferentes, e o `check` do sensor lê uma regex só: escreva-a à mão, com três `grep -qF` e
  um `pass`/`fail` que imprime a linha `  ok    pr-body.md: …` exata.

**Onde:** `bin/sdd`, `agents/sdd-publisher.md` e o espelho, `templates/pr-body.md`,
`docs/pipeline.md` (`### PR`), `tests/check-gates.sh`, `tests/check-hat.sh`,
`tests/check-templates.sh`, `tests/check-mutation.sh`.
**Como (TDD):** no bloco do `gate_PR`: um handoff do fixture (`45-docs.md` ou `20-handoff-exec.md`)
ganha duas linhas `- kit: …` de verdade, uma dentro de uma cerca e uma dentro de uma citação;
`pr-body` com uma linha `- kit:` → recusa com `carries 1 of the 2`; com duas → passa (a cerca e a
citação não contam: se contassem, pediria 4). Para a segunda asserção, o stub de `gh` grava cada
chamada num arquivo: com `⛔` e `kit:` juntos, **uma** leitura do corpo; sem nenhum, **zero**. Hoje
nada disso é lido.

| Sensor | Frase exata |
|---|---|
| `check-gates.sh` | `gate_PR refuses a body with fewer kit lines than the handoffs of the mission, and counts none in a quote or a fence` |
| `check-gates.sh` | `gate_PR reads the body once for the blocked rows and the kit lines, and not at all without either` |
| `check-hat.sh` | `hat: the publisher carries every kit line of the handoffs into the body of the pull request, whole` |
| `check-hat.sh` | `hat: the publisher writes in how to verify only what the shell of the reader runs, and sends a TEST_CMD with a runner variable to sdd preflight` |
| `check-hat.sh` | `hat: the publisher keeps a question of the plan that a later handoff answered, ticked and with the answer` |
| `check-templates.sh` | `pr-body.md: the body has a place for the kit lines, the answered question and the preflight line` |

Mutantes: `PR_kit_lines_uncounted` (a comparação vira verdadeira), `PR_kit_lines_counted_in_quote`
(a regex dos handoffs passa a aceitar `>` antes do `-`).
**Check:** linha I7 → `1 1 1 1 1 1 2 0`. Antes: `0 0 0 0 0 0 0 0`.
**Sensor durável:** as seis asserções e os dois mutantes.
**Reversível por:** `git revert` do commit.

### I8 — O `gate:` só cita o que se pode refazer ou abrir (item 3)

**O quê:** a linha `gate:` dos dois templates que têm o campo.

- `templates/handoff.md`:
  `gate: <a evidência de que o gate desta fase passou — cada medida com o comando inteiro e o sha em que rodou, para ser refeita; "saídas em <caminho>" só quando o arquivo está lá; medida sem um dos dois fica fora>`
- `templates/review.md`:
  `gate: <a evidência de que o gate desta rodada passou — TEST_CMD resumido e árvore limpa; cada medida com o comando inteiro e o sha em que rodou, para ser refeita; "saídas em <caminho>" só quando o arquivo está lá>`

Cada uma numa linha física. Antes de editar, liste quem lê essas linhas
(`grep -n 'gate' tests/check-templates.sh tests/check-gates.sh`): o `gate_REVIEW` recusa o `gate:`
que ainda é o placeholder `<…>` do template, e a linha nova continua sendo um placeholder entre
`<` e `>`; as regexes de `tests/check-templates.sh` que leem a linha antiga mudam no mesmo commit.
A asserção do `review.md` entra por `review_check`, no trecho contado, e o `REVIEW_FLOOR` sobe de
27 (o valor que o I2 deixou) para 28.
**Onde:** `templates/handoff.md`, `templates/review.md`, `tests/check-templates.sh`.
**Como (TDD):** duas chamadas `check`, com o literal `o comando inteiro e o sha em que rodou` na
linha que começa com `gate:` de cada template. Hoje as duas são vermelhas.

| Sensor | Frase exata |
|---|---|
| `check-templates.sh` | `handoff.md: the gate field cites a measure with its command and the sha it ran on, or the path that holds the output` |
| `check-templates.sh` | `review.md: the gate field cites a measure with its command and the sha it ran on, or the path that holds the output` |

Sem mutante: `tests/check-templates.sh` mede markdown, e o catálogo não o alcança; quem o mede é o
selftest dele, que continua verde.
**Check:** linha I8 → `1 1`. Antes: `0 0`.
**Sensor durável:** as duas asserções.
**Reversível por:** `git revert` do commit.

### I9 — Fecho

**O quê:** `RESOLVED by <hash>` nos 13 itens do `TODO.md`, cada um com o hash do incremento que o
fechou (a coluna Incremento da tabela do `00-missao.md` diz qual, e o hash sai da coluna Commit do
`checkpoint.md`), e o `20-handoff-exec.md`, que o chapéu do executor escreve no incremento que não
deixa linha `pending`. No `gate:` desse handoff, siga a regra do I8: cada medida com o comando e o
sha.
**Onde:** `TODO.md`, `docs/handoffs/20261121-l3-gates-do-fim-da-linha/20-handoff-exec.md`.
**Como (TDD):** o Check conta os `RESOLVED by` contra o `TODO.md` do merge-base com a
`origin/main`; antes ele imprime `0`. Depois: `bash tests/check-todo.sh --check TODO.md` (rc 0,
nenhum item acima de 8 linhas) e `--anchors` (`0 off target`). Não toque em
`tests/health-baseline.txt`.
**Check:** linha I9 → `13`. Antes: `0`.
**Sensor durável:** `tests/check-todo.sh` (forma e âncoras), que a suíte roda. A contagem em si é
checagem desta missão: o chore de depois do merge apaga os itens.
**Reversível por:** `git revert` do commit.

## Riscos e não-feitos

| Risco | Probabilidade | Mitigação |
|---|---|---|
| Um gate novo reabre missão já fechada (a página do `sdd status` de uma missão mergeada volta a `REVIEW`, `DOCS` ou `PR`) | média | Três regras de intervalo vazio, cada uma com asserção: PR `MERGED` não é lido (I3), missão na base passa na REVIEW (I4), branch apagado ou contido passa no K8 (I5). Medido antes, neste worktree, sobre a missão mergeada do L2: `./bin/sdd why 20261120-l2-o-sdd-plan-e-o-planner DOCS` → `DOCS: drift checklist complete`, rc 0. A QA repete esse comando depois do lote (Verificação end-to-end) |
| A pergunta nova do `gate_PR` quebra um sensor que estuba o `gh` | alta | Os três stubs estão nomeados no I3 e mudam no commit dele; a suíte inteira antes do commit pega o quarto, se existir |
| A REVIEW reaberta bate no `REVIEW_MAX_ITER` e a linha para | média | É o desenho (ADR 0024, Consequences): para como `BLOCKED` com o motivo escrito, e o humano força a rodada, como hoje |
| O `blocked` da rodada para uma linha saudável, porque o revisor o escreveu para uma rodada com achados | baixa | A regra entra no chapéu e no template no mesmo commit do gate (I2); o custo de um falso é um `sdd run` do humano |
| Um mutante novo não é pego, e a asserção é decoração | média | `--only <slug> <sensor>` antes de cada commit, anotado nas notas; mutante vivo = incremento não fecha |
| A base anda entre o plano e a corrida (o chore do L2) | certa | Pendência 1 do `00-missao.md`: merge da `origin/main`, `--anchors`, `--check` e `--red` de novo, antes do `sdd run` |
| O checkout atrás do remoto lê o PR como "head diferente" | baixa | Limite declarado na ADR 0024; o motivo traz os dois shas, e o remédio é `git pull` |
| O parser do e2e lê um formato que o Playwright mude | baixa | Falha fechada: sem o bloco, o motivo é o de hoje (I6, segunda asserção) |

**Não-feitos, por decisão:** o catálogo de mutação inteiro (`./bin/sdd health`); o enum positivo do
`status:` da rodada; a prosa da DOCS depois da REVIEW (L6b); a rule da anatomia (linha `⛔` na DOCS).

## Verificação end-to-end

Quando todos os incrementos estiverem `done`, no worktree da missão:

1. `tests/run-all.sh` → `suite green`, rc 0, e `grep -cE '^  FAIL' <saída>` → `0`.
2. As 30 frases, cada uma com `  ok    ` no seu sensor (os Checks I1 a I8 do `checkpoint.md`, todos
   com o valor esperado).
3. `grep -cE '^mut_(RUN_test_cmd_not_run_reads_red|RUN_pr_blocked_not_armed|RUN_review_blocked_not_armed|PR_head_unread|PR_verified_head_unchecked|PR_merged_head_read|PR_head_unreadable_passes|REVIEW_later_code_unread|REVIEW_later_docs_writes_counted|REVIEW_later_merged_mission_refused|DOCS_k8_reads_head_off_branch|DOCS_k8_gone_branch_refused|QA_e2e_history_uncounted|QA_e2e_history_counts_passed|PR_kit_lines_uncounted|PR_kit_lines_counted_in_quote)\(\)' tests/check-mutation.sh`
   → `16`, e `bash tests/check-mutation.sh --anchors` → rc 0.
4. `cmp -s agents/sdd-publisher.md .claude/agents/sdd-publisher.md; echo $?` → `0`, e o mesmo para
   `sdd-reviewer.md`.
5. **A jornada da QA, no terminal (o kit não tem interface), com o `./bin/sdd` deste worktree** e
   sobre uma missão real já mergeada, para provar que o lote não reabre o que está fechado:
   - `./bin/sdd why 20261120-l2-o-sdd-plan-e-o-planner DOCS` → `DOCS: drift checklist complete`,
     rc 0 (o mesmo de antes do lote, medido pelo planner);
   - `./bin/sdd why 20261120-l2-o-sdd-plan-e-o-planner PR` → o motivo do carimbo
     (`no green mutation catalogue for this content — run 'sdd health' …`), o mesmo de antes do
     lote: o PR #456 está `MERGED`, então nem o head nem o corpo são lidos, e nenhuma frase nova
     (`is at`, `verified_head`, `kit:`) aparece. Este comando fala com o GitHub pelo `gh`;
   - `./bin/sdd review-base 20261120-l2-o-sdd-plan-e-o-planner` → uma linha `base=…` ou `full …`,
     rc 0, como antes (o lote não toca `review_base_line`).
   Não rode `./bin/sdd why … EXEC`, `… QA` nem `… REVIEW` por curiosidade: cada um roda a suíte
   inteira e segura o checkout.
