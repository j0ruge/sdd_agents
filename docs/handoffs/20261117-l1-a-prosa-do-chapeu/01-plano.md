---
missao: 20261117-l1-a-prosa-do-chapeu
data: 2026-11-17
---

# Plano — L1: a prosa do chapéu e dos docs

> **Teste de autocontenção:** uma sessão nova, sem nenhuma memória da conversa que gerou este
> plano, lendo apenas `00-missao.md` + `01-plano.md` + `checkpoint.md`, consegue executar?
> Se a resposta for "só se souber X", **X vai escrito aqui**.

## Contexto verificado (não re-descobrir)

Medido em 2026-11-17, no commit `7ea43e3`, no worktree `/home/joruge/repos/sdd_agents-l1`. **A base
vai ter andado quando você ler isto** (decisão 7): todo número de linha abaixo é pista, nunca
instrução. Ache cada trecho pelo `grep` que o incremento dá.

**Onde você está e com que `sdd`**

- A missão roda num **worktree ligado** do kit. O `sdd` do PATH é o do checkout principal
  (`/home/joruge/repos/sdd_agents`), com os chapéus de **antes** deste lote. O `./bin/sdd` é o deste
  worktree. **Nunca escreva, commite ou entre no checkout principal**: a guarda de kit de toda
  corrida da máquina compara o `HEAD` e o `git status` dele.
- Quem espelha um chapéu é **`./bin/sdd install --force`**, com o `./` (o `sdd install --force` do
  PATH copiaria de volta os chapéus velhos do checkout principal). `.claude/agents/` é
  **rastreado** neste repo (`git ls-files .claude/agents` lista os oito), então o espelho entra no
  mesmo commit do chapéu. Nunca `cp`, nunca `Edit`/`Write` em `.claude/`: a sessão headless leva
  negativa. `./bin/sdd install` sem `--force` só mostra o estado; em `7ea43e3` responde
  `ok   agent sdd-<nome>.md identical` para os oito e não escreve nada. Com `--force`, a única
  coisa que ele reescreve são os chapéus diferentes (`ok   agent <nome> updated (--force)`); a
  config, o `TODO.md` e o resto saem `preserved`/`already`.
- `./bin/sdd install --force` passa pela admissão do checkout, que a corrida segura. A reentrada de
  um descendente da própria corrida é desenhada, e **nunca foi medida com o `./bin/sdd` de um
  worktree sob o `sdd` do PATH**. Se ele responder `CHECKOUT-BUSY` (rc 75), não contorne: anote o
  comando, o rc e a saída em `checkpoint-notas.md`, marque o incremento `blocked` e pare. É medida
  do piloto, não defeito seu.
- O frontmatter dos chapéus (`disallowedTools:`, `permissionsDeny:`, `writes:`, `mcp:`) **não é
  tocado**: o runner o lê do checkout principal, e o corpo, do espelho do worktree.

**A suíte e os sensores**

- `TEST_CMD` é `tests/run-all.sh` (8 a 11 min). O `gate_EXEC` a roda a cada volta.
- `bash tests/check-hat.sh` roda sozinho em 5 s e imprime 105 linhas `  ok    ` em `7ea43e3`;
  `bash tests/check-templates.sh` em menos de 1 s, 114 linhas. Use-os para o Red e o Green; a suíte
  inteira fica para antes do commit.
- Em `tests/check-hat.sh`: `pass "<frase>"` imprime `  ok    <frase>` na stdout, `fail "<frase>"`
  imprime `  FAIL  <frase>` na stderr e soma em `fails`. As famílias são funções `*_probes()`
  chamadas numa lista no fim do arquivo, **antes** da linha `selftest || exit $?`
  (`grep -n '_probes$' tests/check-hat.sh`). Uma família nova entra nessa lista. O molde de leitura
  por seção é o de `planner_agent_probes`:
  `sec="$(awk '/^## 4\. /{s=1; next} s && /^## /{s=0} s' "$agent")"`, depois `grep -qF '<literal>' <<< "$sec"`.
  Sempre herestring, nunca `printf … | grep -q` (o arquivo roda sob `pipefail`).
- **Toda frase que uma asserção lê cabe numa linha física do markdown.** O `grep -qF` lê linha a
  linha: um literal partido por quebra de linha nunca casa. Os chapéus não têm limite de coluna (a
  linha mais longa do `agents/sdd-executor.md` tem 216), então deixe a linha passar de 100 antes de
  partir um literal.
- **Duas asserções que já existem leem frases que este lote muda**, e ficam vermelhas se você
  trocar a frase sem trocar o literal no mesmo commit:
  - em `hat_promise_probes`, o literal
    ``'Naming the base branch itself (`main`) is a decision too, and passes, unless'`` (item A, I1);
  - em `executor_agent_probes`, o literal `'mv <file>.bak <file>'` (item E, I2).
- `tests/check-lang.sh` cobra inglês em `agents/`, `docs/`, `README.md`, `bin/sdd` e `tests/`. Um
  literal em português dentro de `tests/check-hat.sh` reprova a suíte; por isso a asserção do item
  M mora em `tests/check-templates.sh`, que é exceção documentada do sensor.
- `tests/check-templates.sh` compara o **esqueleto** das duas sementes linha a linha (`todo_shape`:
  headings, marcadores, cercas e as duas linhas de exemplo). Prosa nova dentro de um parágrafo
  `> ` que já existe não mexe no esqueleto; o que entra numa semente entra na outra, no mesmo lugar.
- Antes de cada commit que toca `bin/` ou `tests/`: `shellcheck -S warning <arquivos tocados>`. O
  lint só roda na suíte inteira, e um aviso descoberto tarde custa um commit a mais.

**O `TODO.md`**

- O título de um item (o texto entre `**`) é a **chave do espelho de issues** (skill
  `todo-to-github-issues`): renomear cria uma issue nova e deixa a antiga órfã. **Nunca mude um
  título.** Os 14 estão na tabela do `00-missao.md`.
- A âncora de cada item é medida: `` `arquivo:linha` (`símbolo`) ``, e o símbolo tem de ocorrer no
  arquivo a até 10 linhas da linha. Antes de **todo** commit: `bash tests/check-todo.sh --anchors TODO.md`
  → `0 off target`. Âncora que saiu do alvo se conserta no mesmo commit, mudando o número da linha
  (e o símbolo, quando ele deixou de existir), nunca o título.
- **Três consertos apagam o símbolo do próprio item**, e o incremento troca o símbolo no mesmo
  commit: item E (`mv <file>.bak <file>` → `cp <file>.bak <file>`), item J (`PRIVATE` →
  `git clone`), item K (`grep 'bin/sdd run'` → `[b]in/sdd run`). O item I mantém `third case` porque
  a frase nova continua dizendo "third case".
- Itens de **outros lotes** ancorados nos arquivos que este lote edita (linha do `- [ ]` no
  `TODO.md` de `7ea43e3` → âncora), que podem sair do alvo quando o texto cresce:
  `agents/sdd-planner.md` 260→`:52`; `agents/sdd-executor.md` 574→`:7`; `agents/sdd-reviewer.md`
  193→`:62`, 591→`:95`; `agents/sdd-docs.md` 724→`:49`, 735→`:104`; `agents/sdd-qa.md` 268→`:11`,
  392→`:79`; `templates/todo.pt-BR.md` 157→`:33`; e, abaixo do `sdd why` no `bin/sdd`, os itens
  ancorados em `:12436`, `:12471` e `:12729`.
- `RESOLVED by <hash>` vai no fim da última linha do corpo, **antes** do `— descoberto por` (ou
  dentro da linha `Fonte:` antes dele); nunca numa linha própria, nunca depois do descoberto-por,
  nunca na linha `RECURRED`; nenhuma linha passa de 120 colunas e o item não passa de 8 linhas
  (`templates/todo.pt-BR.md`, "Onde vai o `RESOLVED by`"). Sem espaço, encurte o corpo. O item
  **fica** no arquivo e a catraca (`tests/health-baseline.txt`) **não muda** nesta missão.

**Fatos por item, já conferidos**

- A: a frase está no `## 8. ` do `agents/sdd-planner.md` (`grep -n 'Naming the base branch itself' agents/sdd-planner.md`).
  O gate que recusa o par é `k8_base_refusal` no `bin/sdd`, que compara `branch:` com `$DEFAULT_BRANCH`.
- B: o `## 1. ` do planner não cita `OUTPUT_LANG` nenhuma vez (contagem 0), e o `## Language` cobre
  só "the three artifacts". O parágrafo do relay começa em `When you run as a subagent you cannot reach the human`.
- C: a regra da `RECURRED` está no `## 2. ` (`gains an entry on the item's`); as regras de Check, no
  `## 4. `, no bullet `**an executable Check**`, cujo último aviso começa em
  `**Write a Check by the PRESENCE of what the increment adds.**`.
- D: o `## 5. ` do executor não cita `20-handoff-exec.md` e o `## 7. ` não cita o handoff (0 e 0).
- E: a única ocorrência de `mv <file>.bak <file>` em `agents/`, `commands/`, `docs/` e `templates/`
  é a do parágrafo `**What an earlier session left is read before anything else.**`, no `## 2. ` do
  executor. A subseção `### Every sabotage run has a ceiling` fala do restore sem nomear o comando.
- F: o parágrafo é `**Never end your turn with a command still running.**`, na subseção
  `### Two ways this session dies, both measured, both avoidable`. O laço medido no `dotp-remake`:
  `timeout 590 bash -c 'until /usr/bin/grep -q "^rc=" <saída>; do sleep 5; done'` (o `sleep` dentro
  do `bash -c` não é barrado; o teto de 590 s fica abaixo dos 10 min do Bash).
- G: a frase é `Reproduce before you conclude.`, no fim do `## 3. ` do revisor. O `Write` fora do
  repo é negado de propósito pelo modo de permissão; o heredoc pelo Bash grava.
- H: a tabela do `## 3. ` da DOCS tem a linha `` | `KAIZEN_LOG.md` | ``; a regra da linha `⛔` com
  texto proposto está no `## 5. ` (`<!-- sdd:proposed -->`).
- I: a frase é `There is a third case, on the **with interface** path`, no fim do `## 0. ` do QA; a
  confirmação mora no `## 2. Does the diff have no user-visible change?`.
- J: `grep -n 'PRIVATE' README.md` → uma linha, `# git clone https://github.com/j0ruge/sdd_agents.git   # PRIVATE repository`.
- K: a seção é ``## The `sdd run` process itself disappeared`` do `docs/failure-modes.md`. Na máquina
  do dono, `pgrep -af '[b]in/sdd run'` lista **duas** linhas por corrida (um wrapper do PATH e o
  `bin/sdd` de verdade); as duas são líderes de sessão. A linha de fim é
  `✓ pipeline complete — only the merge is left (the one human gate)` (`grep -n 'pipeline complete' bin/sdd`),
  impressa na saída do `sdd run`. `tail --pid=<pid> -f /dev/null` (GNU) espera um PID sem `pgrep`.
- L: os passos 6 e 7 estão na lista numerada que termina em `--match-head-commit`
  (`grep -n 'Wait for the checks' docs/finding-prs.md`). A consulta abaixo foi rodada contra o PR 391
  em 2026-11-17 e respondeu `head 6967588 threads 7 more false unresolved: 0`:

  ```bash
  gh api graphql -F owner=<owner> -F repo=<repo> -F pr=<PR> -f query='query($owner:String!,$repo:String!,$pr:Int!){repository(owner:$owner,name:$repo){pullRequest(number:$pr){headRefOid reviewThreads(first:100){totalCount pageInfo{hasNextPage} nodes{isResolved}}}}}' --jq '.data.repository.pullRequest | "head \(.headRefOid[0:7]) threads \(.reviewThreads.totalCount) more \(.reviewThreads.pageInfo.hasNextPage) unresolved: \([.reviewThreads.nodes[] | select(.isResolved | not)] | length)"'
  ```

  `more true` quer dizer mais de 100 threads: a contagem não vale e o merge não sai.
- M: o parágrafo é `**Open finding**` em `templates/todo.md` e `**Achado aberto**` em
  `templates/todo.pt-BR.md`, seguido da cerca com o exemplo `- [ ] **<title>**`.
- N: o texto de ajuda mora em `cmd_help` (`grep -n "sdd why <mission>" bin/sdd`), sob `FOR SCRIPTS`.
  `cmd_why` chama `"gate_$ph"`, e o `TEST_CMD` é rodado por `gate_EXEC`, `gate_QA` (que roda também
  o `E2E_CMD`) e `gate_REVIEW`, e por nenhum outro gate (`grep -n 'run_check_cmd "\$TEST_CMD"' bin/sdd`).
  Sem `PHASE`, o `sdd why` deriva a fase, e a derivação roda os gates. O molde é a entrada do
  `sdd boot` na mesma ajuda (`so the gates run`). `./bin/sdd help` imprime a ajuda sem config.

## Arquitetura da mudança

Nada de arquitetura: frases novas em nove arquivos de prosa, duas linhas num texto de ajuda, e 15
asserções (uma por item, e o item M com uma por semente) em dois sensores que já estão na suíte. Nenhum sensor novo, nenhuma linha nova no
`tests/run-all.sh`, nenhum piso para mover.

```text
agents/sdd-planner.md   agents/sdd-executor.md   agents/sdd-reviewer.md
agents/sdd-docs.md      agents/sdd-qa.md                 → espelho em .claude/agents/ (install --force)
README.md   docs/failure-modes.md   docs/finding-prs.md
templates/todo.md   templates/todo.pt-BR.md
bin/sdd                 (só o texto de cmd_help)
tests/check-hat.sh      13 asserções novas, 2 literais antigos trocados
tests/check-templates.sh 2 asserções novas
TODO.md                 âncoras re-medidas a cada commit; 14 RESOLVED by no I9
```

A prosa dos chapéus e dos docs é inglês; a de `templates/todo.pt-BR.md`, do `TODO.md` e desta pasta
é pt-BR. Mensagens de commit em pt-BR, `<tipo>(<escopo>): <o quê>`, com o porquê no corpo.

## Incrementos

A tabela executável vive em `checkpoint.md` (é ela que o runner lê). Aqui fica o **porquê** de
cada fatia — o detalhe que não cabe numa célula.

**Em todos os incrementos, nesta ordem:**

1. **Red:** escreva a asserção no sensor e veja-a vermelha (`bash tests/check-hat.sh 2>&1` mostra
   `  FAIL  <frase>`). A frase do `pass` é a que este plano dá, byte a byte: o Check do
   `checkpoint.md` a lê.
2. **Green:** escreva a prosa. Os literais que a asserção lê são os que este plano dá; o resto da
   redação é seu, no tom do chapéu, curta, sem repetir o que o chapéu já diz.
3. Releia o parágrafo inteiro em volta da frase nova e todo lugar do mesmo arquivo que repete a
   afirmação.
4. Para chapéu: `./bin/sdd install --force`, depois `git status --short` (só o chapéu, o espelho
   dele, o sensor e, se uma âncora andou, o `TODO.md`).
5. `shellcheck -S warning tests/check-hat.sh` (ou o arquivo de `tests/`/`bin/` que você tocou),
   `bash tests/check-todo.sh --anchors TODO.md` → `0 off target`, e a suíte `tests/run-all.sh`.
6. **Um commit** com tudo; depois o checkpoint, como último ato.

Nenhuma frase de asserção leva apóstrofo nem crase: o Check a lê entre aspas simples. Dois
**literais** do I6 levam apóstrofo (`pgrep -af '[b]in/sdd run` e `grep 'bin/sdd run'`): no sensor,
escreva-os entre aspas duplas (`grep -qF "pgrep -af '[b]in/sdd run"`), nunca entre aspas simples.

As asserções de chapéu não são alcançadas pelo catálogo de mutação nem pelo `selftest` do
`tests/check-hat.sh`: o Red observado no passo 1 é a prova de que cada uma consegue ficar vermelha.
Anote em `checkpoint-notas.md` uma linha por asserção: `<ID> red: <frase> → FAIL antes da prosa`.

### I1 — o planner: a base pelo `DEFAULT_BRANCH`, a devolução no idioma, a Check que aceita `RECURRED`

**O quê:** três frases em `agents/sdd-planner.md` (itens A, B e C).
- **A**, no `## 8. `: a frase `Naming the base branch itself (`main`) is a decision too, and passes, unless`
  passa a ser ``Naming the base branch itself (the `DEFAULT_BRANCH` of the target) is a decision too, and passes, unless``,
  numa linha só. O literal `` itself (`main`) `` some do arquivo.
- **B**, em dois lugares. No `## Language`, uma frase que estende a regra às devoluções, contendo
  o literal `every hand-back to the relay`: a pergunta do grill, as opções e o aviso de trabalho
  longo vão no `OUTPUT_LANG` do alvo, qualquer que seja o idioma do prompt de delegação, porque o
  relay repassa o texto literal e traduzir é parafrasear. No `## 1. `, no parágrafo
  `When you run as a subagent`, uma oração curta que cita `` `OUTPUT_LANG` `` e aponta o `## Language`.
- **C**, no `## 4. `, um aviso `⚠️` novo no fim do bullet `**an executable Check**`, depois do aviso
  `**Write a Check by the PRESENCE of what the increment adds.**`: a Check de um incremento que
  registra um achado novo no `TODO_FILE` não fixa o título do item novo; o planner lê os abertos
  antes de escrevê-la (literal `read the open items`), e ela aceita também a entrada `RECURRED`
  num item aberto equivalente (literais `RECURRED` e `an equivalent open item`), porque um item
  igual pode nascer entre o plano e a execução e a regra da `RECURRED` proíbe a duplicata.
**Onde:** `agents/sdd-planner.md`, `.claude/agents/sdd-planner.md` (pelo install),
`tests/check-hat.sh` (`planner_agent_probes`, e o literal antigo em `hat_promise_probes`), `TODO.md`
se uma âncora andar.
**Como (TDD):** três asserções no fim de `planner_agent_probes`, lidas por seção:
- `hat: the planner names the base branch by DEFAULT_BRANCH of the target, never by the literal main`
  — o `## 8. ` contém ``itself (the `DEFAULT_BRANCH` of the target) is a decision too, and passes, unless``
  e o arquivo não contém `` itself (`main`) ``;
- `hat: the planner writes every hand-back to the relay in OUTPUT_LANG` — o `## Language` contém
  `every hand-back to the relay` e o `## 1. ` contém `OUTPUT_LANG`;
- `hat: a planner Check for a new TODO_FILE item also accepts a RECURRED entry on an equivalent open item`
  — o `## 4. ` contém `an equivalent open item`, `RECURRED` e `read the open items`.

No mesmo commit, em `hat_promise_probes`, o literal antigo da frase A vira o novo.
**Check:** ver `checkpoint.md` (três asserções verdes e o espelho igual: `1 1 1 0`; hoje `0 0 0 0`).
**Sensor durável:** as três asserções, na suíte.
**Reversível por:** `git revert` do commit (chapéu, espelho e sensor voltam juntos).

### I2 — o executor: o handoff no mesmo incremento, e o mutante restaurado com `cp`

**O quê:** itens D e E em `agents/sdd-executor.md`.
- **D**, em dois lugares. No fim do `## 5. `: quando a sua atualização não deixa nenhuma linha
  `pending`, o `## 6` faz parte deste mesmo incremento (literal `part of this same increment`), e
  o incremento não está fechado sem o `20-handoff-exec.md` commitado, rode você pelo `sdd run` ou
  como subagente de um relay (fora do runner nenhum gate acusa a falta). No `## 7. `: a resposta
  final diz se o handoff foi escrito (literal ``whether `20-handoff-exec.md` was written``).
- **E**, em dois lugares. No parágrafo `**What an earlier session left is read before anything else.**`,
  o comando `mv <file>.bak <file>` vira `cp <file>.bak <file> && rm <file>.bak`. Na subseção
  `### Every sabotage run has a ceiling`, uma frase: o restore é por `cp`, nunca por `mv`, porque o
  `mv` devolve ao arquivo o mtime de antes do build do mutante (literal `keeps the old mtime`), um
  build incremental (MSBuild, make) não recompila, e a medida sem mutante de depois roda contra o
  binário do último mutante; ela tem de recompilar. O literal `mv <file>.bak <file>` some do arquivo.
**Onde:** `agents/sdd-executor.md`, `.claude/agents/sdd-executor.md`, `tests/check-hat.sh`
(`executor_agent_probes`), e o `TODO.md`: o símbolo do item E passa de `` (`mv <file>.bak <file>`) ``
para `` (`cp <file>.bak <file>`) ``, com a linha re-medida.
**Como (TDD):** duas asserções no fim de `executor_agent_probes`:
- `hat: the executor writes 20-handoff-exec.md in the increment that leaves no row pending, and its answer says whether it did`
  — o `## 5. ` contém `part of this same increment` e `20-handoff-exec.md`; o `## 7. ` contém
  ``whether `20-handoff-exec.md` was written``;
- `hat: the executor restores a mutant with cp and rm, so an incremental build sees a new mtime`
  — o arquivo contém `cp <file>.bak <file> && rm <file>.bak` e `keeps the old mtime`, e não contém
  `mv <file>.bak <file>`.

No mesmo commit, na asserção que já existe (`puts back only a mutant its .bak confirms`), o literal
`'mv <file>.bak <file>'` vira `'cp <file>.bak <file> && rm <file>.bak'`, e o comentário acima dela
que diz "by `mv`" passa a dizer "by `cp`".
**Check:** ver `checkpoint.md` (`1 1 0`; hoje `0 0 0`).
**Sensor durável:** as duas asserções.
**Reversível por:** `git revert`.

⚠️ O espelho deste chapéu é o que as sessões EXEC seguintes desta mesma corrida carregam. É
esperado: do I3 em diante o executor já roda com as duas frases novas.

### I3 — o revisor: esperar sem `Monitor`, e a sonda fora do repo

**O quê:** itens F e G em `agents/sdd-reviewer.md`.
- **F**, no parágrafo `**Never end your turn with a command still running.**`: este chapéu não tem
  `Monitor` nem `ScheduleWakeup`, e o harness barra um `sleep` longo em primeiro plano
  ("Blocked: … use Monitor"). A espera é um laço em primeiro plano com teto abaixo dos 10 min do
  Bash, numa linha de código só, que a asserção lê:
  `timeout 590 bash -c 'until grep -q "^rc=" <output>; do sleep 5; done'`. O comando lento grava a
  saída num arquivo e termina com uma linha `rc=<n>`; se o `timeout` estourar, rode o laço de novo
  no mesmo turno. O frontmatter não muda.
- **G**, logo depois de `Reproduce before you conclude.`: a cópia descartável de uma reprodução
  mora fora do repo e é gravada por heredoc pelo Bash (literal `heredoc`), porque o `Write` fora do
  repo volta negado de propósito; e um filtro de teste que não casa com teste nenhum é falha, não
  verde (literal `matches no test`): confira a contagem de testes rodados antes de ler o rc.
**Onde:** `agents/sdd-reviewer.md`, `.claude/agents/sdd-reviewer.md`, `tests/check-hat.sh` (família
nova `reviewer_agent_probes`, com um comentário de três a seis linhas dizendo de onde vêm os dois
itens, e a chamada na lista do fim do arquivo, logo depois de `planner_agent_probes`).
**Como (TDD):** duas asserções:
- `hat: the reviewer waits for a slow command in the foreground, under a ceiling below the Bash limit`
  — o bloco da subseção `### Two ways this session dies` contém
  `timeout 590 bash -c 'until grep -q "^rc=" <output>; do sleep 5; done'` e `Monitor`;
- `hat: the reviewer writes a probe outside the repo by heredoc, and a test filter that matches nothing is a failure`
  — o `## 3. ` contém `heredoc` e `matches no test`.
**Check:** ver `checkpoint.md` (`1 1 0`; hoje `0 0 0`).
**Sensor durável:** as duas asserções.
**Reversível por:** `git revert`.

### I4 — a DOCS: a lição reincidente ganha destino

**O quê:** item H em `agents/sdd-docs.md`, no `## 3. `, junto do parágrafo sobre a entrada do
`KAIZEN_LOG.md`: quando a própria entrada chama a lição de reincidente (literal `recurrent`:
"terceira vez", "de novo", a mesma falha de uma missão anterior), ela não fica só no log. Ou vira
uma linha `⛔` com o texto proposto para `.claude/rules/` ou `CLAUDE.md`, pela regra do `## 5`
(literal `` `⛔` row with its proposed text ``), ou a entrada escreve o motivo de não virar regra
(literal `the reason it does not become a rule`).
**Onde:** `agents/sdd-docs.md`, `.claude/agents/sdd-docs.md`, `tests/check-hat.sh` (família nova
`docs_agent_probes`, chamada depois de `reviewer_agent_probes`).
**Como (TDD):** uma asserção:
- `hat: the docs phase turns a lesson its own log calls recurrent into a proposed rule, or writes why not`
  — o `## 3. ` contém `recurrent`, `` `⛔` row with its proposed text `` e
  `the reason it does not become a rule`.
**Check:** ver `checkpoint.md` (`1 0`; hoje `0 0`).
**Sensor durável:** a asserção.
**Reversível por:** `git revert`.

### I5 — a QA: o `qa: skipped` confirma nos dois caminhos

**O quê:** item I em `agents/sdd-qa.md`, no fim do `## 0. `: a frase
`There is a third case, on the **with interface** path` passa a dizer que o terceiro caso vale nos
dois caminhos (literal `There is a third case, on **both** paths`). Com `qa: skipped` no frontmatter
do `00-missao.md` o runner manda a fase direto a esta sessão; no caminho com interface, sem
`qa-report` nem `qa-execution` antes; no caminho sem interface, a linha "Who walks the journey: you"
da tabela **não** vale para este caso. Nos dois o trabalho é confirmar a declaração contra o diff
real (`## 2`), nunca percorrer (o literal `never to walk` continua na frase).
**Onde:** `agents/sdd-qa.md`, `.claude/agents/sdd-qa.md`, `tests/check-hat.sh` (família nova
`qa_agent_probes`, chamada depois de `docs_agent_probes`).
**Como (TDD):** uma asserção:
- `hat: the qa hat sends a declared qa: skipped to the confirmation of section 2 on both paths`
  — o `## 0. ` contém `There is a third case, on **both** paths` e `never to walk`, e não contém
  `on the **with interface** path: the plan declares`.

O literal da negação está inteiro numa linha da frase de hoje (`grep -n 'third case' agents/sdd-qa.md`),
e por isso a asserção nasce vermelha pelos dois lados: falta a frase nova e sobra a antiga.
**Check:** ver `checkpoint.md` (`1 0`; hoje `0 0`).
**Sensor durável:** a asserção.
**Reversível por:** `git revert`.

### I6 — os docs do operador: o README, o `sdd run` destacado e os threads abertos

**O quê:** itens J, K e L.
- **J**, `README.md`: a linha do clone perde o comentário e fica exatamente
  `# git clone https://github.com/j0ruge/sdd_agents.git`. Nada entra no lugar (decisão 5).
- **K**, `docs/failure-modes.md`, seção ``## The `sdd run` process itself disappeared``. No
  **Symptom**, o `ps … | grep 'bin/sdd run'` (que acha o próprio `grep`) vira
  `pgrep -af '[b]in/sdd run'`, com meia frase dizendo por que os colchetes (o padrão não casa com a
  linha de comando de quem procura). No **What you do**, depois do `setsid nohup`, como saber que
  acabou: ache o PID com `pgrep -af '[b]in/sdd run <mission>'` (um wrapper do PATH aparece como
  segunda linha), espere por ele com `tail --pid=<pid> -f /dev/null`, e leia o fim na saída
  redirecionada da corrida: a linha `✓ pipeline complete` é o fim bom; sem ela, a última linha do
  `.sdd/logs/<mission>/pipeline.log` diz onde parou. Nunca `pgrep -f 'sdd run <mission>'` num laço
  de espera: o padrão está no argv da shell que espera.
- **L**, `docs/finding-prs.md`, passo 7 da receita: antes do `gh pr merge`, a contagem de threads de
  revisão abertos no head tem de responder `unresolved: 0`, com o comando do "Contexto verificado"
  (item L) ao lado, numa cerca de código, e a nota de que `mergeable_state` limpo e check verde de
  um bot não leem threads (o PR 391 tinha um Major aberto com os dois verdes) e de que `more true`
  invalida a contagem.
**Onde:** `README.md`, `docs/failure-modes.md`, `docs/finding-prs.md`, `tests/check-hat.sh` (família
nova `doc_operator_probes`, chamada depois de `doc_finding_prs_probes`), e o `TODO.md`: o símbolo
do item J passa a `` (`git clone`) `` e o do item K a `` (`[b]in/sdd run`) ``, com as linhas re-medidas.
**Como (TDD):** três asserções:
- `doc: the README shows the clone line without calling the repository private` —
  `grep -qxF '# git clone https://github.com/j0ruge/sdd_agents.git' README.md` e nenhum `PRIVATE`
  no arquivo;
- `doc: failure-modes.md finds a detached sdd run without matching the watcher, and says how to wait for its end`
  — a seção (do heading até o próximo `## `) contém `pgrep -af '[b]in/sdd run`, `tail --pid=` e
  `pipeline complete`, e não contém `grep 'bin/sdd run'`;
- `doc: the finding-PR recipe merges only with zero unresolved review threads on the head, with the command beside it`
  — `docs/finding-prs.md` contém `reviewThreads`, `isResolved` e `unresolved: 0`.

A asserção antiga de `doc_finding_prs_probes` não muda.
**Check:** ver `checkpoint.md` (`1 1 1`; hoje `0 0 0`).
**Sensor durável:** as três asserções.
**Reversível por:** `git revert`.

### I7 — as duas sementes do `TODO.md`: número que muda não vai no título

**O quê:** item M. Uma frase em cada semente, no mesmo lugar: dentro do parágrafo
`**Open finding**` de `templates/todo.md` e `**Achado aberto**` de `templates/todo.pt-BR.md`, antes
da cerca do exemplo. Em inglês, contendo `A number that changes goes in the body, never in the title`;
em português, contendo `Número que muda vai no corpo, nunca no título`. Cada uma com o porquê em
meia frase: o título é a chave do espelho de issues, e uma medida nele troca a chave a cada medição.
Cada literal inteiro numa linha `> ` de até 100 colunas.
**Onde:** `templates/todo.md`, `templates/todo.pt-BR.md`, `tests/check-templates.sh`, e o `TODO.md`
se a âncora `templates/todo.pt-BR.md:33` (outro lote) ou a `:17` (item M) sair do alvo.
**Como (TDD):** duas chamadas de `check` em `tests/check-templates.sh`, logo depois da linha
``check todo.pt-BR.md '^## ' "the pt-BR variant this repo's OUTPUT_LANG seeds from"`` e **antes** de
`REVIEW_MARK="$CHECKS_RUN"` (o piso `REVIEW_FLOOR` conta a partir dali e não pode se mover):

```bash
check todo.md       'A number that changes goes in the body, never in the title' "a number that changes goes in the body, never in the title"
check todo.pt-BR.md 'vai no corpo, nunca no t'                                    "a number that changes goes in the body, never in the title"
```

O `check` imprime `  ok    <arquivo>: <descrição>`. A regex da variante pt-BR para antes do `í` de
propósito: é ASCII puro. Depois, `bash tests/check-templates.sh` inteiro verde: as linhas
`the same skeleton as todo.md, line for line` e `passes the shape sensor with zero findings` das
duas sementes continuam `ok`.
**Check:** ver `checkpoint.md` (`2`; hoje `0`).
**Sensor durável:** as duas asserções. O `TODO.md` deste repo não copia o formato (o cabeçalho dele
aponta o template), então nada mais muda.
**Reversível por:** `git revert`.

### I8 — a ajuda do `sdd why` diz que o gate roda a suíte

**O quê:** item N, a exceção nomeada (decisão 1). Em `cmd_help` do `bin/sdd`, a entrada
`sdd why <mission> [PHASE]  print why that phase's gate did not pass` ganha linhas de continuação,
no molde da entrada do `sdd boot` (mesma coluna de recuo, até 100 colunas): o gate **roda**, e para
EXEC, QA ou REVIEW, ou sem `PHASE` (que deriva a fase), isso é o `TEST_CMD` inteiro (e o `E2E_CMD`
na QA); um corte por tempo não é um gate reprovado. Uma das linhas contém o literal
`EXEC, QA or REVIEW` e outra (ou a mesma) contém `TEST_CMD`.
**Só o texto.** Nenhuma função, nenhum gate, nenhum mutante novo: uma linha de ajuda não é gate, e
a asserção lê a saída do programa.
**Onde:** `bin/sdd` (só dentro de `cmd_help`), `tests/check-hat.sh` (família nova `help_probes`,
chamada depois de `boot_probes`), e o `TODO.md` se as âncoras `bin/sdd:12436`, `:12471`, `:12729`
ou a do próprio item N (`:12361`, símbolo `sdd why`) saírem do alvo.
**Como (TDD):** uma asserção, sobre a saída de `"$ROOT/bin/sdd" help`, guardada numa variável
(`out="$("$ROOT/bin/sdd" help 2>&1)" || true`) e lida por herestring. O bloco da entrada é a linha
que começa por `  sdd why ` mais as linhas de continuação seguintes (as que começam por 20 ou mais
espaços), extraído com `awk`:
- `help: sdd why says its gate runs TEST_CMD for EXEC, QA or REVIEW, as sdd boot does` — o bloco
  contém `TEST_CMD` e `EXEC, QA or REVIEW`.

O README e o `docs/pipeline.md` que citarem o `sdd why` são deriva da fase DOCS, não deste incremento.
**Check:** ver `checkpoint.md` (`1`; hoje `0`).
**Sensor durável:** a asserção. `tests/check-mutation.sh --anchors` roda na suíte e acusa se a
edição quebrar a âncora de algum mutante.
**Reversível por:** `git revert`.

### I9 — o fecho: `RESOLVED by` nos 14 itens

**O quê:** cada um dos 14 itens da tabela do `00-missao.md` ganha `RESOLVED by <hash>`, com o hash
curto da coluna Commit do `checkpoint.md` do incremento que o consertou: A, B, C → I1; D, E → I2;
F, G → I3; H → I4; I → I5; J, K, L → I6; M → I7; N → I8. Ache cada item pelo título
(`grep -n -F '<título>' TODO.md`). Onde vai e os limites: "O `TODO.md`", no Contexto verificado.
Os títulos não mudam, os itens ficam, a catraca não muda.
Por ser o último incremento, o `§6` do seu chapéu vale: escreva e commite também o
`20-handoff-exec.md` (o que no diff chega ao usuário do kit: o texto do `sdd help`, o README e os
dois docs; os chapéus chegam às sessões das fases; a jornada da QA está em "Verificação end-to-end").
**Onde:** `TODO.md`, `docs/handoffs/20261117-l1-a-prosa-do-chapeu/20-handoff-exec.md`.
**Como (TDD):** rode o Check antes (`0`), escreva, rode depois (`14`). Em seguida
`bash tests/check-todo.sh --check TODO.md` rc 0 e `--anchors TODO.md` → `0 off target`.
**Check:** ver `checkpoint.md`. Ele conta os `RESOLVED by` que a branch **acrescenta** sobre a
`origin/main`, e não o total do arquivo, porque a base pode trazer itens resolvidos por outros.
**Sensor durável:** `tests/check-todo.sh` (a forma do `RESOLVED by`, o teto de 8 linhas e as 120
colunas), na suíte. A contagem de 14 é efêmera por natureza: o chore de depois do merge apaga os
itens.
**Reversível por:** `git revert`.

## Riscos e não-feitos

| Risco | Probabilidade | Mitigação |
|---|---|---|
| A base andou e um trecho não está onde o plano diz | certa | Todo incremento acha o trecho por `grep` de frase. Se a frase não existir mais, **não invente o lugar**: anote nas notas o `grep` vazio, marque `blocked` e pare |
| O merge da `origin/main` não foi feito antes da corrida | média | É a pendência 1 do `00-missao.md`. Sinal: `bash tests/check-todo.sh --count TODO.md` responde `83` (a `main` já tinha 85 em `380ffb0`). Não é do executor consertar: anote e siga, o merge acontece no ato de revisão |
| `./bin/sdd install --force` responde `CHECKOUT-BUSY` dentro da corrida | média | Nunca medido neste arranjo. Não contorne com `cp` nem com o `sdd` do PATH: notas, `blocked`, pare. O caso volta ao dono como medida do piloto |
| O espelho fica para trás (chapéu commitado sem o install) | média | O Check dos incrementos I1 a I5 inclui o `cmp` do espelho |
| Uma âncora do `TODO.md` sai do alvo | alta | `--anchors` antes de cada commit; três trocas de símbolo já estão nomeadas (itens E, J e K) |
| Uma asserção antiga fica vermelha porque lia a frase trocada | certa, duas vezes | As duas estão nomeadas no Contexto verificado e nos incrementos I1 e I2 |
| Literal partido por quebra de linha: a asserção nunca fica verde | média | Regra "cabe numa linha física"; o Green só vale com o sensor verde |
| Literal em português dentro de `tests/check-hat.sh` | baixa | `tests/check-lang.sh` reprova; a asserção do item M mora em `tests/check-templates.sh` |
| O `sdd preflight` do PATH acusa `agent … stale` neste worktree | certa | Esperado até o merge (pendência 6); o `sdd run` não morre por isso, só recusa chapéu **ausente** |
| O `gate_PR` sai com rc 2 por falta do carimbo de mutação | certa | Parada conhecida: "PR pronto para revisão". Ninguém roda `./bin/sdd health` nesta missão |
| A sessão quer escrever em `.claude/rules/` | baixa | Proibido; a DOCS deixa a linha `⛔` com o texto proposto |
| O chapéu do executor muda no meio da própria corrida (I2) | certa | Desenhado: o harness carrega o espelho. As frases novas só acrescentam, e o frontmatter não muda |

**Não-feitos:** os de "Fora de escopo" do `00-missao.md`. Em especial: nenhum mutante novo, nenhum
sensor novo, nenhuma mudança em gate, e o `Monitor` não volta ao revisor.

## Verificação end-to-end

Com os nove incrementos `done`, na raiz do worktree:

```bash
tests/run-all.sh                                                  # verde
o=$(bash tests/check-hat.sh 2>&1); grep -c '^  ok    ' <<< "$o"   # o número de antes mais 13
o=$(bash tests/check-templates.sh 2>&1); grep -c '^  ok    todo.*: a number that changes goes in the body, never in the title' <<< "$o"   # 2
for h in planner executor reviewer docs qa; do cmp -s agents/sdd-$h.md .claude/agents/sdd-$h.md; echo "$h $?"; done   # cinco linhas terminadas em 0
bash tests/check-todo.sh --anchors TODO.md                        # 0 off target
grep -cE 'RESOLVED by [0-9a-f]{7,40}' TODO.md                     # 14, mais os que a base trouxer
```

**A jornada da QA** (o kit não tem interface; o `sdd-qa` a percorre no terminal e descreve o que
viu no `gate:` do `30-handoff-qa.md`): `./bin/sdd help` e ler a entrada do `sdd why`;
`./bin/sdd install` e ler `agent sdd-<nome>.md identical` para os oito; abrir o README na linha do
clone; ler a seção do `sdd run` que sumiu no `docs/failure-modes.md` e rodar o
`pgrep -af '[b]in/sdd run'` que ela ensina; rodar a consulta de threads do `docs/finding-prs.md`
contra um PR real do repo e ler `unresolved:`.
