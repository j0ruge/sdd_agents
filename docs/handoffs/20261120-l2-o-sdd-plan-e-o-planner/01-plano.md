---
missao: 20261120-l2-o-sdd-plan-e-o-planner
data: 2026-11-20
---

# Plano — L2: o `/sdd-plan` e o planner

> **Teste de autocontenção:** uma sessão nova, sem nenhuma memória da conversa que gerou este
> plano, lendo apenas `00-missao.md` + `01-plano.md` + `checkpoint.md`, consegue executar?
> Se a resposta for "só se souber X", **X vai escrito aqui**.

## Contexto verificado (não re-descobrir)

Medido em 2026-11-20, no commit `336640e`, no worktree `/home/joruge/repos/sdd_agents-l2`. **A base
vai ter andado quando você ler isto** (pendência 2 do `00-missao.md`: a `main` com o L1b entra neste
branch antes da corrida). Todo número de linha abaixo é pista, nunca instrução: ache cada trecho
pelo `grep` da frase que o incremento dá. Ao lado de cada contagem está o comando que a mediu.

**Onde você está e com que `sdd`**

- A missão roda num **worktree ligado** do kit. O `sdd` do PATH é o do checkout principal
  (`/home/joruge/repos/sdd_agents`), com o chapéu de **antes** deste lote. O `./bin/sdd` é o deste
  worktree. **Nunca escreva, commite ou entre no checkout principal**: a guarda de kit de toda
  corrida da máquina compara o `HEAD` e o `git status` dele.
- Quem espelha o chapéu é **`./bin/sdd install --force`**, com o `./` (o do PATH copiaria de volta
  o chapéu velho do checkout principal). `.claude/agents/` é **rastreado** neste repo
  (`git ls-files .claude/agents` lista 8 arquivos), então o espelho entra no mesmo commit do chapéu.
  Nunca `cp`, nunca `Edit`/`Write` em `.claude/`: a sessão headless leva negativa. No L1, dentro de
  uma corrida, ele respondeu `updated`, sem `CHECKOUT-BUSY` (notas do I3 ao I5 de
  `docs/handoffs/20261117-l1-a-prosa-do-chapeu/checkpoint-notas.md`). Se responder `CHECKOUT-BUSY`
  (rc 75), não contorne: anote o comando, o rc e a saída nas notas, marque `blocked` e pare.
- O `commands/sdd-plan.md` **não tem espelho**: o harness o carrega por um link em
  `~/.claude/commands/` para o checkout principal (`ls -la ~/.claude/commands` → `sdd-plan.md ->
  /home/joruge/repos/sdd_agents/commands/sdd-plan.md`). O que você editar aqui só vale depois do
  merge. A última linha do arquivo é `$ARGUMENTS` e continua sendo a última.
- Config deste worktree (`grep -n 'JIRA_ENABLED\|^TEST_CMD\|^HANDOFF_DIR\|^OUTPUT_LANG\|^DEFAULT_BRANCH\|^TODO_FILE' .sdd/config.sh`):
  `DEFAULT_BRANCH="main"`, `TEST_CMD="tests/run-all.sh"`, `HANDOFF_DIR="docs/handoffs"`,
  `TODO_FILE="TODO.md"`, `JIRA_ENABLED=false`, `OUTPUT_LANG="pt-BR"`.

**O que já está no branch quando a corrida começa, e não é seu**

- Além dos commits do plano, o branch traz um commit do relay no `.sdd/config.sh`: a linha
  `EFFORT_EXEC="medium"` vira `EFFORT_EXEC="${EFFORT_EXEC:-medium}"`, e a corrida é lançada com
  `EFFORT_EXEC=xhigh` no ambiente (pendência 10 do `00-missao.md`). Em `336640e` a linha ainda é a
  antiga (`grep -n 'EFFORT_' .sdd/config.sh` → `EFFORT_EXEC="medium"` e `EFFORT_DOCS="medium"`).
  Não é incremento: não o desfaça, não o estenda, e a REVIEW não o conta como fora do escopo.
- Pode haver também um commit do relay com o `TODO.md` e o `tests/health-baseline.txt` (o achado do
  planner, pendência 9), e o merge da `origin/main` (pendência 2).
- **Para a fase DOCS:** a entrada do `KAIZEN_LOG.md` leva a tabela de custo e tempo da seção Métrica
  do `00-missao.md`, com a coluna do L2 medida: o relógio sai do `.sdd/logs/20261120-l2-o-sdd-plan-e-o-planner/pipeline.log`; os
  minutos e o US$ por sessão de EXEC, de `dur_s` e `cost_usd` das linhas `"event":"session"` com
  `"phase":"EXEC"` desta missão em `~/.sdd/autonomy-log.jsonl`. Some com `jq`, ou com
  `LC_ALL=C awk` (sob pt-BR o `mawk` lê `1.99` como 1). A sessão DOCS roda antes do fim da corrida,
  então ela escreve o que já existe (EXEC, QA e REVIEW) e diz que o relógio total fecha no diário
  da campanha. A tabela tem três colunas: o L1, este L2 e a missão `20261117-o-worker-orquestrador`
  (PR #414). Reconfira os números do L1 e do worker no mesmo ledger antes de copiá-los, e escreva
  as duas ressalvas da seção Métrica: quem isola o effort é o L2 contra o L1.

**A suíte e os sensores**

- `TEST_CMD` é `tests/run-all.sh` (8 a 15 min no L1, pelas notas dele). O `gate_EXEC` a roda a cada
  volta. A chamada `Bash` do harness para de esperar aos 120 s por padrão e 600 s no máximo: rode a
  suíte com o `timeout` da chamada em 600000 ms, ou destacada com a saída num arquivo.
- Tempos e contagens em `336640e`, cada sensor sozinho: `bash tests/check-hat.sh` → rc 0, 4 s, 123
  linhas `  ok    ` (`grep -c '^  ok    '` na stdout); `bash tests/check-templates.sh` → rc 0, 1 s;
  `bash tests/check-checkpoint.sh` → rc 0, 15 s, 19 linhas `  ok    `. Use-os para o Red e o Green;
  a suíte inteira fica para antes do commit. Depois do merge do L1b essas contagens mudam; nenhum
  Check deste plano depende delas.
- Em `tests/check-hat.sh`: `pass "<frase>"` imprime `  ok    <frase>` na stdout, `fail "<frase>"`
  imprime `  FAIL  <frase>` na stderr e soma em `fails`; os dois levam **um** argumento. As famílias
  são funções `*_probes()` chamadas numa lista no fim do arquivo (`grep -n '_probes$' tests/check-hat.sh`
  → 21 linhas em `336640e`, a última `release_stamps_probes`). Família nova entra nessa lista. O
  molde de leitura por seção, para o comando:
  `sec="$(awk '/^## Before anything else/{s=1; next} s && /^## /{s=0} s' "$cmd")"`, e para o chapéu:
  `s1="$(awk '/^## 1\. /{s=1; next} s && /^## /{s=0} s' "$agent")"`; depois
  `grep -qF '<literal>' <<< "$sec"`. Sempre herestring, nunca `printf … | grep -q` (o arquivo roda
  sob `pipefail`). Literal com crase vai entre aspas simples; o único literal deste plano com aspas
  simples dentro (`pgrep -af '[b]in/sdd run'`, no I5) vai entre aspas duplas; nenhum tem as duas.
  Nas tabelas de literais abaixo, o espaço encostado na crase dupla de uma célula é só do markdown,
  não do literal. O valor de uma chave de frontmatter sai de `fm_value "$agent" <chave>`, que
  devolve `$ABSENT` quando a chave não existe.
- **Toda frase que uma asserção lê cabe numa linha física do markdown.** O `grep -qF` lê linha a
  linha: um literal partido por quebra de linha nunca casa (custou um Red refeito no I8 do L1). O
  comando e o chapéu não têm limite de coluna: deixe a linha passar de 100 antes de partir um literal.
- **Asserções que já existem leem frases do `commands/sdd-plan.md` que este lote rodeia.** Elas
  ficam vermelhas se a frase sumir, e o conserto é manter a frase (ou trocar o literal no mesmo
  commit). As que ficam ao lado do que você vai escrever (`grep -n "grep -q" tests/check-hat.sh`,
  nas famílias `command_*`):
  - seção `## Before anything else`: `'resolves outside this root, skip this step'`,
    `'take the worktree as the repository root for every step below'`, `'before writing any artifact'`;
  - seção `## Then`: `'git -C <main checkout> status --porcelain'`,
    `'git -C <main checkout> rev-parse HEAD'`, `'at every hand-back'`,
    `'never delete or reset anything there yourself'`;
  - seção `## Relaying the grill to the human`: `"by the option's text, never by its position"`,
    `'Nothing else resumes the planner while a question is pending'`,
    `'ask the planner for the text before anything else'`;
  - seção `## When the artifacts exist`: `'check-checkpoint.sh --check <checkpoint>'`,
    ``'`--red <checkpoint>`'``, `'An approval given before the plan'`,
    `'What `sdd approve` does not commit'`, a regex
    `'git status --porcelain -- .*<TODO_FILE> tests/health-baseline\.txt'` e a regex
    `'^ *- \*\*Anywhere else\*\* .*commit nothing'`;
  - no § 1 do chapéu: `'- answer: (recommended)'`, `'One line per answer'`,
    `'never goes inside the parentheses'`, `'comes back whole'`, `'never as its number alone'`.
- O `tests/check-checkpoint.sh` também lê o chapéu: exige o literal `check-checkpoint.sh --red` e a
  regra da âncora no `agents/sdd-planner.md` (`grep -n 'RED_DOC=' tests/check-checkpoint.sh`). Você
  só acrescenta texto ao chapéu, então elas seguem verdes.
- `tests/check-lang.sh` cobra inglês em `agents/`, `commands/`, `docs/` (fora os conteúdos pt-BR),
  `bin/` e `tests/`. Um literal em português dentro de `tests/check-hat.sh` reprova a suíte; por
  isso as duas asserções do `templates/plano.md` (pt-BR) moram em `tests/check-templates.sh`, que é
  exceção documentada do sensor. Se o id desta missão, citado num comentário de `tests/`, for lido
  como português, cite "lot L2" sem o id. Rode `bash tests/check-lang.sh` antes de cada commit.
- Em `tests/check-templates.sh`, `check plano.md '<regex>' "<descrição>"` imprime
  `  ok    plano.md: <descrição>`; as sete linhas de hoje estão sob `echo "== templates/plano.md =="`
  (`grep -n 'check plano.md' tests/check-templates.sh` → 7 linhas).
- **Não escreva asserção Red com uma suíte em curso.** O `tests/check-health.sh` roda o
  `check-hat.sh` de verdade e o exige verde: no I3 do L1, asserções vermelhas escritas durante a
  suíte a reprovaram, e ela foi refeita. Veja o Red com o sensor sozinho, e só rode a suíte inteira
  com a prosa já escrita.
- Antes de cada commit que toca `tests/`: `shellcheck -S warning <arquivos tocados>`. O lint só
  roda na suíte inteira, e um aviso descoberto tarde custa um commit a mais.
- **Não há mutante neste lote** (nada em `bin/`), e `./bin/sdd health` não roda.

**O `TODO.md`**

- O título de um item (o texto entre `**`) é a **chave do espelho de issues** (skill
  `todo-to-github-issues`): renomear cria uma issue nova e deixa a antiga órfã. **Nunca mude um
  título.** Os 14 estão na tabela do `00-missao.md`.
- A âncora de cada item é medida: `` `arquivo:linha` (`símbolo`) ``, e o símbolo tem de ocorrer no
  arquivo a até 10 linhas da linha. Antes de **todo** commit: `bash tests/check-todo.sh --anchors TODO.md`
  → `0 off target` (em `336640e` mais o item novo do planner: `anchors: 92 measured, 0 off target`).
  Âncora que saiu do alvo se conserta no mesmo commit, mudando o número da linha, nunca o título.
- Os símbolos dos 14 itens **continuam existindo** depois do conserto (`Relaying the grill`,
  `rev-parse HEAD`, `Measure again`, `Anywhere else`, `Mark each answer`, `KIT-TOUCHED`,
  `skip this step`, `Nothing else resumes the planner`, `HAT_WRITES_BASE`, `show-toplevel`,
  `An approval given before the plan`, `red_one`, `Mitigação`, `20-handoff-exec.md`): nenhum
  incremento apaga um deles. Só as linhas andam.
- Âncoras por arquivo editado (linha do `TODO.md` em `336640e` → âncora), para saber o que cada
  incremento pode tirar do alvo (`grep -n 'commands/sdd-plan.md:\|agents/sdd-planner.md:\|tests/check-checkpoint.sh:\|templates/plano.md:' TODO.md`):
  - `commands/sdd-plan.md`: 463→`:15`, 371→`:30`, 414→`:56`, 311→`:101`, 303→`:116`, 423→`:131`,
    318→`:174`, 733→`:213`, 446→`:227`, 325→`:238`. Todo texto acrescentado desloca as de baixo:
    I1, I2, I3, I4 e I5 editam esse arquivo, e cada um re-ancora o que sair do alvo.
  - `agents/sdd-planner.md`: 333→`:52` (item 6) e, no fim do `TODO.md`, o item novo do planner em
    `:41` (`Skill(grilling)`). I2, I3 e I4 editam o chapéu; a chave `model:` do I4 entra **acima**
    das duas e as desloca uma linha.
  - `templates/plano.md`: 48→`:41` (item 1, `Mitigação`) e 764→`:41` (item de **outro lote**,
    `Riscos e não-feitos`). I3 e I4 editam o template.
  - `tests/check-checkpoint.sh`: 741→`:1616` (item 14, `red_one`), 148→`:1616` (item de **outro
    lote**, `red_one`) e 89→`:1560` (outro lote, `check_one`). O I5 edita o sensor.
- `RESOLVED by <hash>` vai no fim da última linha do corpo, **antes** do `— descoberto por`; nunca
  numa linha própria, nunca depois do descoberto-por, nunca na linha `RECURRED`; nenhuma linha
  passa de 120 colunas e o item não passa de 8 linhas (`templates/todo.pt-BR.md`, "Onde vai o
  `RESOLVED by`"). Sem espaço, encurte o corpo. O item **fica** no arquivo e a catraca
  (`tests/health-baseline.txt`, `todo-findings 92`) **não muda** nesta missão.

**Fatos por item, já conferidos**

- **Seções do comando** (`grep -n '^## ' commands/sdd-plan.md`): `## Before anything else` (passos
  numerados 1 a 4), `## Then`, `## Relaying the grill to the human` (bullets em negrito),
  `## When the artifacts exist` (passos 1 a 4, o 3 com sub-passos 1 a 3). **Não renumere os passos
  do "Before anything else"**: `commands/sdd-worker.md` ("its step 2"), o `CLAUDE.md` e a rule
  `.claude/rules/anatomia-do-agente.md` citam o passo 2.
- **Seções do chapéu** (`grep -n '^## ' agents/sdd-planner.md`): `## 1. Brainstorm and grill`,
  `## 2. Gemba before planning`, `## 4. Slice into increments with sensors`, `## 6. Close the
  PLAN-AUTO gate`, `## Language`. No § 1, o parágrafo `**Mark each answer.**` e o parágrafo que
  começa em `When you run as a subagent you cannot reach the human`. No § 4, o bullet
  `**a commit as its product.**`.
- Itens 11, 8 e 7: o "Before anything else" não roda `git status` do alvo, não cita
  `git branch --show-current` nem lista o `HANDOFF_DIR` (`grep -c 'git branch --show-current'
  commands/sdd-plan.md` → 1, e essa ocorrência está no passo 4 do aceite). O passo 2 termina na
  frase `When `sdd` is not on the PATH, or resolves outside this root, skip this step`.
- O dono de um checkout se lê sem trava por `sdd status --no-gates <missão>`, que **exige** um nome
  de missão (`./bin/sdd status --no-gates` → `error: missing mission name`). Qualquer missão do
  checkout serve: rodado no worktree de uma corrida viva com o nome de **outra** missão, imprimiu a
  linha `CHECKOUT-OWNER checkout=<caminho> owner=<pid> supervisor=<pid> command=run mission=<a que roda> started=<hora>`;
  rodado neste worktree, sem corrida, não imprimiu essa linha (`grep -c '^CHECKOUT-OWNER'` → 1 e 0).
- Corrida viva na máquina: `pgrep -af '[b]in/sdd run'` (a receita do `docs/failure-modes.md`, item K
  do L1). Com uma corrida viva ele listou três linhas nesta máquina: o wrapper do PATH, o
  `sdd-coordination.py enter` e o `bin/sdd run <missão>`.
- Item 3: a regra de gravar `status` e `rev-parse HEAD` a cada devolução está no bullet
  `**The working directory.**` do `## Then`, que só vale `When step 2 moved you`.
- Item 2: a mensagem do harness foi "the session ended before this call's result was recorded, so
  its outcome is unknown", e o `SendMessage` ao id do planner antigo voltou `Resuming agent` (corpo
  do item, 3.2c do `dotp-remake`). O comando hoje não manda dizer o id do planner a ninguém.
- Itens 6 e 13: o leitor D22 é o `awk` do passo 3.2 de "When the artifacts exist" e conta só as
  linhas inteiras `- answer: (recommended)` e `- answer: (other: …)` da seção de decisões. Sob
  `plan approved (auto)` o passo 2 manda ir direto ao passo 4, sem passar pelo leitor. O bullet
  `**The relay's side.**` não tem exceção para o "never answers for the human" do parágrafo de
  abertura da seção. O `commands/sdd-worker.md` (ato `plan`) já diz "Under delegation the relay
  answers the grill with the recommended option"; **não o edite**.
- Item 5: o `cmd_approve` sob `auto` sem `05-verdict.md` responde `plan <missão> is already approved
  (aprovacao: auto) — nothing to do` e sai (`grep -n 'is already approved' bin/sdd`), sem cortar
  branch nem commitar. O passo 4 do aceite tem dois bullets: `**On the mission branch**` e
  `**Anywhere else**`.
- Item 10: o passo 4 roda `git status --porcelain -- <HANDOFF_DIR>/<mission> <TODO_FILE> tests/health-baseline.txt`.
- Item 4: a seção `## Contexto verificado (não re-descobrir)` do `templates/plano.md` tem uma linha
  de exemplo, ``- <fato> — `arquivo:linha` / saída do comando``. O sub-passo **Measure again** do
  aceite roda só `--check` e `--red`.
- Item 1: a tabela de `## Riscos e não-feitos` do `templates/plano.md` tem a linha de exemplo
  `| <o quê> | <alta/média/baixa> | <o que fazemos se acontecer> |`.
- Item 12: o `gate_EXEC` (`grep -n '20-handoff-exec.md is missing' bin/sdd`) passa só com: toda
  linha da tabela `done` e com hash de commit que é ancestral do `HEAD`; nenhuma `blocked`; o
  `TEST_CMD` verde; o `20-handoff-exec.md` na pasta da missão; e o `## TL;DR` dele dentro do teto
  de linhas (`handoff_tldr_ok`, `HANDOFF_TLDR_MAX_LINES`; `grep -n 'HANDOFF_TLDR_MAX_LINES=' bin/sdd`
  dá o número). O molde do arquivo é `templates/handoff.md`. O chapéu do planner não cita
  `20-handoff-exec.md` (`grep -c '20-handoff-exec' agents/sdd-planner.md` → 0), e o
  `docs/plan-only.md` também não (→ 0). O `sdd why <missão> EXEC` roda a suíte inteira.
- Item 15: `grep -n '^model:' agents/*.md` não imprime nada. A ferramenta `Agent` do Claude Code
  2.1.327 aceita um modelo na chamada e o descreve como "Takes precedence over the agent
  definition's model frontmatter", então o harness lê `model:` no arquivo do agente. Numa cópia do
  repo em `336640e` com `model: fable` acrescentado ao chapéu e ao espelho,
  `bash tests/check-hat.sh` → rc 0 com as mesmas 123 linhas `  ok    `, e
  `bash tests/check-health.sh` → rc 0: nenhum sensor recusa a chave. **Não medido:** que o
  subagente abre em Fable por causa dela (pendência 4 do `00-missao.md`).
- Item 14, o sensor (`tests/check-checkpoint.sh`):
  - `red_one <checkpoint>` roda todo Check `pending` e termina com
    `pass "$label: $n pending Check(s), every one red at HEAD"`. Sem linha `pending`: rc 93.
  - O despacho é o `case "${1:-}"` do fim do arquivo: `--red) red_one "${2-}"; exit $? ;;`, e opção
    desconhecida sai com rc 96.
  - `probe <desc> <rc> <texto|-> <alvo> [modo]` chama `"$SELF_PATH" "$mode" "$target"`: hoje não
    passa um terceiro argumento ao sensor. Os probes do `--red` ficam no `selftest()`, depois do
    comentário `# ── --red: the Check run at HEAD`, com o fixture `cp_head`/`cp_row` num
    repositório `git init` próprio, e fecham na linha
    `rule_ok "a Check already green at HEAD is refused by --red ($((PROBES - red_p0)) probe(s))"`.
  - Pisos: `PROBE_FLOOR=412` e `RULE_FLOOR=9` (`grep -n 'PROBE_FLOOR=\|RULE_FLOOR=' tests/check-checkpoint.sh`).
    São apertados: probe novo sobe o primeiro para a contagem nova, linha `rule:` nova sobe o segundo.
  - O cabeçalho do arquivo tem a lista de `Usage:` e a de `Exit codes`; modo novo entra nas duas.

## Arquitetura da mudança

Nada muda no runner. O lote escreve em seis arquivos de produto e dois sensores:

| Arquivo | O que entra | Incrementos |
|---|---|---|
| `commands/sdd-plan.md` | regras do relay, em quatro seções | I1, I2, I3, I4, I5 |
| `agents/sdd-planner.md` (+ espelho) | regras do planner nos §§ 1, 2 e 4, e a chave `model:` | I2, I3, I4 |
| `templates/plano.md` | a forma "comando ao lado do fato" e a mitigação com sensor | I3, I4 |
| `docs/plan-only.md` | a seção da volta ao `sdd run` | I4 |
| `tests/check-checkpoint.sh` | `--red --list`, `--red --only`, probes | I5 |
| `tests/check-hat.sh` | 16 asserções, em famílias novas ou nas que já leem a seção | I1 a I5 |
| `tests/check-templates.sh` | 2 asserções do `plano.md` | I3, I4 |
| `TODO.md` | âncoras re-apontadas a cada commit, e `RESOLVED by` no fecho | todos |

A regra de redação vale para todos: cada regra nova diz **o que fazer**, na seção cujo leitor a
segue, e cita em uma frase o caso medido (o projeto e a missão estão no corpo do item do
`TODO.md`). Regra no comando é para o relay; regra no chapéu é para o planner; uma regra que obriga
os dois vai nos dois, e a asserção lê os dois.

## Incrementos

A tabela executável vive em `checkpoint.md` (é ela que o runner lê). Aqui fica o **porquê** de
cada fatia — o detalhe que não cabe numa célula.

Em todo incremento, na ordem: (1) escreva as asserções no sensor e veja cada uma `FAIL` (anote o
Red em `checkpoint-notas.md`); (2) escreva a prosa; (3) no I2, I3 e I4, `./bin/sdd install --force`;
(4) `bash tests/check-hat.sh`, `bash tests/check-lang.sh`, `bash tests/check-todo.sh --anchors TODO.md`
e o `shellcheck`; (5) a suíte inteira; (6) commit; (7) checkpoint. Os literais abaixo são os que a
asserção lê com `grep -qF`: escreva a frase da prosa de modo que cada um apareça inteiro numa linha.

### I1 — Antes de delegar (itens 11, 8, 7, 3)

**O quê:** o relay lê o checkout antes de qualquer escrita, e a leitura tem três saídas. A vigia
de `status` e `HEAD` a cada devolução passa a valer sem worktree.
**Onde:** `commands/sdd-plan.md` (seções `## Before anything else` e `## Then`),
`tests/check-hat.sh`, `TODO.md` (âncoras).
**Como (TDD):** uma família nova `command_before_probes` na lista do fim do `check-hat.sh`, com as
quatro asserções abaixo, vermelhas antes da prosa. Depois a prosa:

- No **passo 1** do "Before anything else", depois do parágrafo do `.sdd/config.sh`, um parágrafo
  em negrito de leitura. Ele usa `HANDOFF_DIR` e `DEFAULT_BRANCH`, que o passo 3 só lê e reporta
  depois: diga no parágrafo que os dois são lidos do config ali mesmo (o passo 3 continua como
  está). O relay roda `git status --porcelain`, `git branch --show-current`,
  `ls <HANDOFF_DIR>` e, havendo ali uma pasta de missão, `sdd status --no-gates <mission>` com o
  nome de qualquer uma delas (a linha `CHECKOUT-OWNER` diz que outro comando segura o checkout);
  sem pasta nenhuma, `pgrep -af '[b]in/sdd run'`. Mostra ao humano uma linha com o que leu. Três
  saídas:
  - outro comando segura o checkout → vale o passo 2 (worktree), mesmo fora do kit;
  - árvore suja sem comando segurando o checkout, ou branch diferente do `DEFAULT_BRANCH` → para e
    pergunta ao humano de que base a missão é cortada (seguir aqui, trocar de branch, ou worktree);
    nunca limpa, guarda em stash nem troca de branch sozinho;
  - uma pasta em `HANDOFF_DIR` que já cobre o tópico → para e mostra a pasta e o que o
    `sdd status --no-gates` diz dela.
- No **passo 2**, a frase final ganha a exceção: o passo não é pulado quando a leitura do passo 1
  achou outro comando segurando este checkout. Mantenha o literal
  `resolves outside this root, skip this step`. O corpo do passo 2 fala do kit (`./bin/sdd`, o
  mapa de assassinos, as ADRs 0021 e 0022): **não o generalize**. Acrescente um parágrafo curto no
  fim dele dizendo o que vale num alvo com corrida viva: o mesmo `git fetch` e o mesmo
  `git worktree add … --no-track -b <provisional> origin/<DEFAULT_BRANCH>`, o worktree como raiz de
  todos os passos seguintes, e uma linha ao humano com o caminho; o que é só do kit (os três
  comandos por `./bin/sdd`, o mapa e o carimbo) não se aplica.
- No `## Then`, no bullet `**The working directory.**`: quando o worktree nasceu por causa de uma
  corrida viva, a comparação do checkout principal a cada devolução olha só os caminhos fora da
  pasta da missão em voo, e não para pelo `HEAD` que a corrida move.
- No `## Then`, um bullet novo fora do "When step 2 moved you": sem worktree o relay grava os
  mesmos dois (`git status --porcelain` e `git rev-parse HEAD`) antes de delegar e a cada
  devolução; um commit que ele mesmo fez no meio do grill (um pedido do humano) vai ao planner
  junto da resposta seguinte, nunca numa mensagem solta (a regra "Nothing else resumes the planner").

Asserções (frase do `pass`, e os literais que ela exige):

| Item | Frase | Literais |
|---|---|---|
| 11 | `command: /sdd-plan reads the tree and the missions on disk before it delegates, and stops on a dirty tree or a topic already planned` | em "Before anything else": `ls <HANDOFF_DIR>`, `already covers the topic`, `A dirty tree with no command holding the checkout` |
| 8 | `command: /sdd-plan compares the current branch with DEFAULT_BRANCH before the planner reads the repository, and asks for the base when they differ` | em "Before anything else": `git branch --show-current`, `ask the human which base the mission is cut from` |
| 7 | `command: /sdd-plan moves to a worktree when another command holds the checkout, and watches only what that run cannot change` | em "Before anything else": `sdd status --no-gates <mission>`, `CHECKOUT-OWNER`; em "Then": `outside the directory of the mission in flight` |
| 3 | `command: /sdd-plan records status and HEAD at every hand-back without a worktree too, and sends its own commit to the planner with the next answer` | em "Then": `When step 2 did not move you, record the same two`, ``send the new `HEAD` to the planner with the next answer`` |

**Check:** o do `checkpoint.md`, linha I1 → `1 1 1 1`. Antes: `0 0 0 0`.
**Sensor durável:** as quatro asserções em `tests/check-hat.sh`, que a suíte roda.
**Reversível por:** `git revert` do commit (prosa e asserções saem juntas).

### I2 — O grill dos dois lados (itens 2, 9, 6, 13)

**O quê:** quatro regras em "Relaying the grill", três delas com a metade do planner no § 1.
**Onde:** `commands/sdd-plan.md` (`## Relaying the grill to the human` e o sub-passo 2 do passo 3
de `## When the artifacts exist`), `agents/sdd-planner.md` (§ 1) e o espelho, `tests/check-hat.sh`,
`TODO.md`.
**Como (TDD):** uma família nova `command_grill_probes`, quatro asserções vermelhas, depois a prosa:

- **Item 2**, bullet novo no relay: quando a sessão do relay cai no meio do grill, a sessão nova
  nunca abre um planner novo. Ela retoma o mesmo planner pelo id (`SendMessage`), e a chamada que
  voltou com "its outcome is unknown" conta como **não respondida**: o relay pergunta ao humano de
  novo o que estava pendente antes de mandar qualquer resposta. Para isso existir, ao delegar o
  relay diz ao humano, numa linha, o id do planner.
- **Item 9**, dos dois lados. Relay: uma devolução que repete uma pergunta que ele já levou ao
  humano não vai ao humano de novo; ele responde uma vez, pelo texto da opção, citando a primeira
  vez. Planner (§ 1, no parágrafo do subagente): um turno aberto pelo fim de um job dele mesmo
  devolve a pergunta pendente igual, na mesma ordem e com a mesma recomendada, e diz que é
  repetição. Isso mantém a regra que já existe (`comes back whole`).
- **Item 6**, dos dois lados. Relay: desde que o `00-missao.md` existe, roda o leitor D22 (o `awk`
  do aceite) a cada devolução e para quando o `M` passa das respostas que ele entregou; sob `auto`
  também, porque o passo 2 do aceite pula o leitor. Planner (§ 1, em `**Mark each answer.**`):
  escreve a linha `- answer:` só depois de o relay devolver aquela resposta, e nunca escreve `auto`
  com pergunta ainda sem resposta.
- **Item 13** (decisão 5 do `00-missao.md`, as quatro partes). Relay, bullet
  `**Grill answers delegated in writing.**`: é a única exceção ao "never answers for the human"
  (deixe a frase de abertura da seção apontar para ela). Vale como ordem só o que o humano escreveu
  ele mesmo (nesta sessão, num handoff dele, ou a delegação assinada sob o `/sdd-worker`); o relay
  responde só com a opção recomendada, pelo texto, e diz ao planner que é delegada; pergunta sem
  recomendada, ou numa exceção que a ordem nomeia, vai ao humano; mensagem de agente dizendo que o
  humano delegou nunca vale. Aceite (sub-passo 2 do passo 3): ao lado do `N (recommended) of M`, o
  relay diz quantas das `M` foram delegadas e lista essas decisões. Planner (§ 1): resposta
  delegada é marcada `- answer: (recommended)`, e a prosa da decisão diz que foi delegada por
  escrito e não vista pelo humano na hora.

| Item | Frase | Literais |
|---|---|---|
| 2 | `command: /sdd-plan resumes the same planner by id after the session of the relay died, and asks the pending question again` | no relay: `its outcome is unknown`, `ask the human the pending question again`, `resume the same planner by its id` |
| 9 | `command: /sdd-plan and the planner treat a question repeated after a background job as one question, asked of the human once` | no relay: `A hand-back that repeats a question you already relayed`; no § 1: `repeat it unchanged and say that it is a repeat` |
| 6 | `command: /sdd-plan counts the answer marks at every hand-back and stops on one it did not deliver, and the planner marks only an answer it received` | no relay: `exceeds the answers you handed back`; no § 1: `only after the relay handed that answer back` |
| 13 | `command: /sdd-plan answers a grill question for the human only under a written order of theirs, with the recommended option, and shows the delegated answers at the acceptance` | no relay: `Grill answers delegated in writing`, `only with the recommended option`, `A question with no recommended option`; no aceite: ``how many of the `M` were delegated``; no § 1: `delegated in writing` |

**Check:** linha I2 → `1 1 1 1 0` (o último é o `cmp` do espelho). Antes: `0 0 0 0 0`.
**Sensor durável:** as quatro asserções em `tests/check-hat.sh`.
**Reversível por:** `git revert` do commit, seguido de `./bin/sdd install --force`.

### I3 — O aceite (itens 4, 5, 10)

**O quê:** o aceite reconfere uma amostra do contexto verificado, sabe o que fazer sob `auto` e
olha o `git status` inteiro.
**Onde:** `commands/sdd-plan.md` (`## When the artifacts exist`), `agents/sdd-planner.md` (§ 2) e o
espelho, `templates/plano.md`, `tests/check-hat.sh`, `tests/check-templates.sh`, `TODO.md`.
**Como (TDD):** três asserções na família `command_approval_probes` (ou numa nova
`command_acceptance_probes`) e uma linha `check plano.md` no `check-templates.sh`, vermelhas antes:

- **Item 4** (decisão 3). Planner, § 2: ao lado de cada contagem e de cada âncora do contexto
  verificado vai o comando que a mediu. Template: a linha de exemplo da seção
  `## Contexto verificado` passa a mostrar a forma, com o texto `comando que mediu` (por exemplo
  ``- <fato> — `arquivo:linha`, ou `<comando que mediu>` → `<o que ele imprimiu>` ao lado de toda contagem``).
  Aceite, no sub-passo **Measure again**: o relay roda de novo uma amostra dos comandos que o
  contexto verificado grava, pelo menos três, ou todos quando há menos; uma saída diferente da que
  o plano registra volta ao planner antes da pergunta, como um `FAIL`.
- **Item 5** (decisão 4). No passo 4, um bullet `**Under `auto`**` **antes** dos dois que existem:
  com `plan approved (auto)` ninguém cortou a branch nem commitou. O relay entra na `branch:` do
  `00-missao.md` (`git switch -c <branch>`, ou `git switch <branch>` quando ela já existe), commita
  ali a pasta da missão e o arquivo que `adr:` nomeia, segue o bullet `On the mission branch` para
  o resto, e diz ao humano que o passo seguinte é `sdd run <mission>`. No passo 2, que cobre os dois
  valores, mantenha "there is nothing to approve" e acrescente uma oração: sob `auto` o passo 4
  ainda tem o que commitar. Nenhuma asserção lê essa frase. Mantenha o bullet
  `**Anywhere else**` com `commit nothing`.
- **Item 10**. No passo 4, depois do `git status` dos três caminhos: o relay roda também
  `git status --porcelain` sem caminho. O que aparecer fora dos três e for um arquivo de que o
  plano depende (o plano o cita como existente) é commitado na branch da missão; o resto é nomeado
  ao humano, sem commit e sem apagar. Mantenha a linha com os três caminhos.

| Item | Frase | Literais |
|---|---|---|
| 4 | `command: /sdd-plan re-runs a sample of the commands the verified context records, and the planner writes the command beside every count and anchor` | no aceite: `Re-run a sample of the commands the verified context records`, `at least three, or all of them when there are fewer`; no § 2: `beside every count and every anchor, the command that measured it` |
| 4 | `plano.md: the verified context records the command beside each measured fact` | regex do `check`: `comando que mediu` |
| 5 | `command: /sdd-plan cuts the mission branch and commits the mission under auto, and names sdd run as the next step` | no aceite: `git switch -c <branch>`, ``the next step is `sdd run <mission>` `` |
| 10 | `command: /sdd-plan reads the whole git status after the approval, and commits on the mission branch a file the plan depends on` | no aceite: ``Then run `git status --porcelain` with no path``, `a file the plan depends on` |

**Check:** linha I3 → `1 1 1 1 0`. Antes: `0 0 0 0 0`.
**Sensor durável:** três asserções em `tests/check-hat.sh` e uma em `tests/check-templates.sh`.
**Reversível por:** `git revert` do commit, seguido de `./bin/sdd install --force`.

### I4 — O planner e o modelo (itens 1, 12, 15)

**O quê:** o planner roda o sensor que uma mitigação nomeia, escreve o passo do handoff em plano
que roda fora do `sdd run`, e declara o modelo; o `/sdd-plan` passa o modelo ao delegar.
**Onde:** `agents/sdd-planner.md` (frontmatter, §§ 2 e 4) e o espelho, `commands/sdd-plan.md`
(`## Then`), `templates/plano.md`, `docs/plan-only.md`, `tests/check-hat.sh`,
`tests/check-templates.sh`, `TODO.md`.
**Como (TDD):** quatro asserções no `check-hat.sh` (duas `hat:` em `planner_agent_probes`, uma
`doc:` numa família nova `doc_plan_only_probes`, e a do modelo) e uma linha `check plano.md`:

- **Item 1**. Planner, § 2: uma mitigação que cita um sensor ("o compilador lista", "a suíte pega")
  só entra no plano depois de o planner rodar esse sensor, no PLAN, contra o que ela protege, e o
  comando e a saída vão ao lado da mitigação. Template: a célula de exemplo da coluna `Mitigação`
  ganha o texto `mitigação que cita um sensor` (por exemplo
  `<o que fazemos se acontecer; mitigação que cita um sensor traz o comando rodado contra o alvo e a saída>`).
- **Item 12** (decisão 8). Planner, § 4, junto do bullet `**a commit as its product.**`: quando o
  grill decide que o plano é executado fora do `sdd run` (uma sessão sem o `sdd-executor`), o
  último incremento termina escrevendo o `20-handoff-exec.md` a partir do `handoff.md` do diretório
  de templates, e o plano não promete o gate do EXEC sem ele; sob o `sdd run` o passo não entra,
  porque o executor já escreve o arquivo. Doc: uma seção nova `## Going back to `sdd run`` no
  `docs/plan-only.md`, depois de `## Per mission`, com o que o `gate_EXEC` lê (a lista do "Contexto
  verificado", item 12), a mensagem exata do gate quando falta o arquivo, e o `sdd why <mission> EXEC`
  para conferir, dizendo que ele roda a suíte inteira.
- **Item 15** (decisão 1). Frontmatter do chapéu: uma linha `model: fable`, logo acima de
  `disallowedTools:`. Nenhuma outra chave muda. Comando, `## Then`, no parágrafo que lista o que o
  relay entrega ao planner: o relay passa o modelo na chamada do subagente — o `plan_model:` da
  campanha quando o `/sdd-worker` o chamou, senão o `model:` do chapéu — porque sem isso o
  subagente herda o modelo da sessão.

| Item | Frase | Literais |
|---|---|---|
| 1 | `hat: the planner runs at PLAN the sensor a risk mitigation names, against what the mitigation protects` | no § 2: `A mitigation that names a sensor`, `against what it protects` |
| 1 | `plano.md: a mitigation that names a sensor carries the command run against its target` | regex do `check`: `mitigação que cita um sensor` |
| 12 | `hat: a plan executed outside sdd run ends its last increment by writing 20-handoff-exec.md, and promises no EXEC gate without it` | no § 4: ``executed outside `sdd run` ``, `20-handoff-exec.md`, `promises no EXEC gate without it` |
| 12 | `doc: plan-only.md says what gate_EXEC reads before a mission executed by hand goes back to sdd run` | no `docs/plan-only.md`: ``## Going back to `sdd run` ``, `every increment done and the suite green, but 20-handoff-exec.md is missing`, `sdd why <mission> EXEC` |
| 15 | `hat: the planner declares its model in the frontmatter, and /sdd-plan passes the model when it delegates` | `fm_value "$agent" model` igual a `fable`; em "Then": `plan_model:`, `as the model of the subagent call` |

**Check:** linha I4 → `1 1 1 1 1 0`. Antes: `0 0 0 0 0 0`.
**Sensor durável:** quatro asserções em `tests/check-hat.sh` e uma em `tests/check-templates.sh`.
A do modelo prova o **arquivo**, não que o harness abre o subagente em Fable (pendência 4).
**Reversível por:** `git revert` do commit, seguido de `./bin/sdd install --force`.

### I5 — O `--red` (item 14)

**O quê:** `--red` ganha dois modos, e o aceite procura corrida viva antes de rodá-lo.
**Onde:** `tests/check-checkpoint.sh` (o `case` do fim, `red_one`, o cabeçalho, o `selftest`),
`commands/sdd-plan.md` (sub-passo **Measure again**), `tests/check-hat.sh`, `TODO.md`.
**Como (TDD):** primeiro os probes no `selftest`, vermelhos (hoje o `case` chama
`red_one "${2-}"` e ignora o que vier depois do checkpoint, então todo modo novo roda tudo); depois
o código. O contrato dos modos, decidido aqui:

- `--red <checkpoint>`, só com esses dois argumentos, não muda em nada: mesma saída, mesmos rc.
- `--red <checkpoint> --list`: não executa Check nenhum. Para cada linha `pending` imprime na
  stdout, por `printf` e nunca por `pass` (não é veredito, e não pode sair com o prefixo `  ok    `),
  uma linha `  <id>  <comando>` (dois espaços, o id, dois espaços, o comando da célula). Termina com
  `pass "$label: $n pending Check(s) listed, none run"`, rc 0. As recusas de forma de hoje (linha
  sem `|`, menos de cinco células, célula fora da forma estrita) continuam recusas, rc 1; sem linha
  `pending`, rc 93.
- `--red <checkpoint> --only <id>[,<id>…]`: roda só os Checks nomeados, com as mesmas regras por
  Check (já verde, mudo e fora da forma reprovam, rc 1). Um id que não é linha `pending` reprova
  antes de rodar qualquer coisa, nomeando o id, rc 1. Lista vazia reprova com rc 96, e são o mesmo
  caso o quarto argumento ausente, `--only ""` e um id vazio na lista (`I1,`). Id repetido
  (`I1,I1`) conta uma vez em `k`. As recusas de forma da linha (sem `|`, menos de cinco células,
  colunas a mais) valem para toda linha, nomeada ou não, porque vêm antes de o Status ser lido; a
  da célula fora da forma estrita (`red_cell`) vale só para os Checks nomeados. Termina com
  `pass "$label: $k of $n pending Check(s) run, each red at HEAD; $((n - k)) not run — a partial measure"`,
  rc 0, **mesmo quando `k` é igual a `n`**: a frase `every one red at HEAD` pertence só ao modo
  inteiro, que é o que o aceite e o PLAN-AUTO leem.
- Nos dois modos, como no inteiro, a última linha **só** sai quando não houve recusa nenhuma; com
  recusa, o rc é 1 e ela não é impressa.
- Terceiro argumento que não é `--list` nem `--only`, `--list` com um quarto argumento, `--only`
  com um quinto, e os dois modos juntos: rc 96, como toda opção desconhecida. É a única mudança
  para quem hoje passa lixo depois do checkpoint (era ignorado).
- Cabeçalho: os dois modos entram em `Usage:`, e a nota "Run by the planner, never by run-all.sh"
  vale para eles.

Probes (no grupo do `--red` do `selftest`, com o mesmo fixture; `probe()` passa a aceitar
argumentos extras depois do modo, ou os probes novos chamam `"$SELF_PATH"` por um ajudante irmão.
O `probe()` de hoje só prova **presença** de um texto: os probes de ausência (`every one red at HEAD`
não aparece), de última linha e de "o arquivo não existe" pedem esse ajudante, e ele soma em
`PROBES` e em `FAILS` e chama `fail_rc` como o `probe()` faz, ou o piso não os conta):
o `--list` imprime o id e o comando; o `--list` **não roda** (o Check do fixture cria um arquivo, e
o probe exige que ele não exista depois); a última linha do `--list`; o `--only` roda o nomeado e
não roda o outro (mesma testemunha de arquivo); a última linha do `--only` traz `a partial measure`
e **não** traz `every one red at HEAD`, também com todos os ids nomeados; id que não é `pending`
(um desconhecido e um `done`) é recusado pelo nome; Check já verde nomeado no `--only` continua
recusado; lista vazia recusada; terceiro argumento desconhecido dá rc 96. Fecha com uma linha
`rule_ok` nova cujo texto começa por
`--red --list runs no Check, and --red --only never says every one`, seguida da contagem de
probes. Suba `PROBE_FLOOR` para a contagem nova e `RULE_FLOOR` de 9 para 10.

**Passada de sabotagem, obrigatória aqui** (é sensor que o catálogo não alcança): degrade cada
regra nova, uma por vez, numa **cópia** do arquivo — o `--list` passando a rodar, o `--only`
rodando todos, a última linha do `--only` voltando à frase inteira, a recusa do id desconhecido
virando silêncio — e exija o selftest vermelho em cada uma. Restaure com `cp <arquivo>.bak <arquivo>
&& rm <arquivo>.bak`. Anote nas notas o que morreu e o que sobreviveu; regra que sobrevive ganha
probe ou sai.

Prosa no comando, sub-passo **Measure again**: antes do `--red`, o relay roda
`pgrep -af '[b]in/sdd run'`. Havendo corrida viva na máquina, mostra a linha ao humano e adia o
`--red` até ela acabar, ou pergunta se roda assim mesmo; o `--check` roda sempre. O `--list` mostra
antes o que o `--red` vai executar (as janelas que os Checks abrem), e uma corrida com `--only`
nunca conta como medida: quem fecha o aceite é a linha do modo inteiro.

| Item | Frase | Literais |
|---|---|---|
| 14 | `rule: --red --list runs no Check, and --red --only never says every one` (começo da linha `rule_ok`) | é a saída do selftest |
| 14 | `command: /sdd-plan looks for a live sdd run before the --red of the acceptance, and never reads a partial --red as measured` | no aceite: `pgrep -af '[b]in/sdd run'`, ``postpone the `--red` ``, `never counts as measured` |

**Check:** linha I5 → `1 1`. Antes: `0 0`.
**Sensor durável:** os probes e a linha `rule:` do selftest do `check-checkpoint.sh`, que a suíte
roda, e uma asserção em `tests/check-hat.sh`.
**Reversível por:** `git revert` do commit; o modo inteiro do `--red` não muda, então nenhum
checkpoint existente depende dos modos novos.

### I6 — Fecho

**O quê:** `RESOLVED by <hash>` nos 14 itens do `TODO.md`, cada um com o hash do incremento que o
fechou (a tabela do `00-missao.md` diz qual), e o `20-handoff-exec.md`, que o chapéu do executor
escreve no incremento que não deixa linha `pending`.
**Onde:** `TODO.md`, `docs/handoffs/20261120-l2-o-sdd-plan-e-o-planner/20-handoff-exec.md`.
**Como (TDD):** o Check conta os `RESOLVED by` contra o `TODO.md` do merge-base com a
`origin/main`; antes ele imprime `0`. Os hashes saem da coluna Commit do `checkpoint.md`. O item 15
não tem linha no `TODO.md` e não entra na conta. Depois: `bash tests/check-todo.sh --check TODO.md`
(rc 0, 92 achados, nenhum acima de 8 linhas) e `--anchors` (`0 off target`). Não toque em
`tests/health-baseline.txt`.
**Check:** linha I6 → `14`. Antes: `0`.
**Sensor durável:** `tests/check-todo.sh` (forma e âncoras), que a suíte roda. A contagem em si é
checagem desta missão: o chore de depois do merge apaga os itens.
**Reversível por:** `git revert` do commit.

## Riscos e não-feitos

| Risco | Probabilidade | Mitigação |
|---|---|---|
| A `main` entra no branch antes do EXEC (com o L1b) e muda números de linha, contagens e a lista de famílias do `check-hat.sh` | alta | Os lugares estão nomeados por seção e frase. Quem lança roda `--check` e `--red` de novo depois do merge (pendência 2). Conflito esperado só no `TODO.md` e na catraca; fora deles, volta ao dono |
| Uma asserção antiga do `check-hat.sh` fica vermelha porque a prosa nova mexeu numa frase que ela lê | média | A lista dos literais vizinhos está no "Contexto verificado"; `bash tests/check-hat.sh` (4 s) antes de cada commit. Vermelha: restaure a frase, ou troque o literal no mesmo commit, e anote |
| Um literal de asserção partido por quebra de linha nunca casa | média | Regra escrita acima ("cabe numa linha física"); o Red de cada asserção é visto antes e o Green depois |
| O `model: fable` no frontmatter é recusado por algum sensor ou pelo harness de um alvo sem Fable | baixa (sensor) / não medida (harness) | Sensores: medido numa cópia, `check-hat.sh` rc 0 com 123 linhas e `check-health.sh` rc 0 (comandos no "Contexto verificado", item 15). Harness: a frase do `## Then` manda passar o modelo na chamada, que tem precedência sobre o frontmatter; o efeito é a pendência 4 |
| O `--only` vira atalho para fechar PLAN-AUTO com medição parcial | média | A última linha do `--only` nunca traz `every one red at HEAD`, com probe para `k` igual a `n`, e o aceite diz que ela não conta como medida |
| A leitura nova do passo 1 para `/sdd-plan` legítimos (árvore suja de propósito, branch de trabalho) | média | A saída é **perguntar** a base ao humano, nunca recusar: uma pergunta a mais, e o humano escolhe seguir |
| `./bin/sdd install --force` responde `CHECKOUT-BUSY` dentro da corrida | baixa | No L1 respondeu `updated` três vezes dentro da corrida (notas do L1). Se acontecer: `blocked`, com o comando e a saída nas notas |
| O id da missão num comentário de `tests/` é lido como português pelo `check-lang.sh` | baixa | `bash tests/check-lang.sh` antes de cada commit; se reprovar, citar "lot L2" sem o id |

Não-feitos, por decisão: `bin/sdd` e `bin/sdd-worker` (o `sdd approve` não aceita `auto`), o
`commands/sdd-worker.md`, um token `(delegated)`, o carimbo de mutação, e a medida do modelo em
sessão real.

## Verificação end-to-end

A QA desta missão é no terminal (o kit não tem interface). Com os seis incrementos `done`:

1. `bash tests/run-all.sh` → verde, rc 0.
2. As 19 asserções: os seis Checks do `checkpoint.md`, um a um, imprimem o esperado.
3. `cmp -s agents/sdd-planner.md .claude/agents/sdd-planner.md; echo $?` → `0`, e
   `sed -n 1,12p agents/sdd-planner.md` mostra `model: fable` com as outras quatro chaves intactas
   (`git diff origin/main -- agents/sdd-planner.md` no frontmatter: só a linha nova).
4. A jornada do `--red` num repositório descartável (`mktemp -d`, `git init`, um `checkpoint.md`
   com duas linhas `pending`, uma delas com um Check que cria um arquivo):
   `--red <cp> --list` lista as duas e o arquivo não nasce; `--red <cp> --only I1` roda só a I1 e
   termina em `1 of 2 pending Check(s) run`; `--red <cp>` roda as duas e termina em
   `2 pending Check(s), every one red at HEAD`.
5. A jornada da leitura do `/sdd-plan`, lida no arquivo: uma sessão que siga o passo 1 do "Before
   anything else" neste worktree roda os quatro comandos que ele nomeia e cada um responde
   (`sdd status --no-gates <missão>` com uma missão de `docs/handoffs`).
6. `bash tests/check-todo.sh --check TODO.md` → rc 0, e os 14 títulos da tabela do `00-missao.md`
   seguem no arquivo byte a byte (`grep -c -F '<título>' TODO.md` → 1 para cada um).
