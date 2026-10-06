---
missao: 20261006-lote-5-o-que-o-lote-4-deixou
data: 2026-10-06
---

# Plano — Lote 5: o que o lote 4 deixou

> **Teste de autocontenção:** uma sessão nova, sem nenhuma memória da conversa que gerou este
> plano, lendo apenas `00-missao.md` + `01-plano.md` + `checkpoint.md`, consegue executar?
> Se a resposta for "só se souber X", **X vai escrito aqui**.

## Passo 0 — antes do I1 (não é incremento)

⚠️ **Esta missão mora num worktree ligado, e é aí que ela é executada** (decisão 2, ADR 0016 §2):

```
/home/joruge/repos/sdd_agents-lote-5     ← AQUI: branch fix/lote-5-o-que-o-lote-4-deixou
/home/joruge/repos/sdd_agents            ← checkout principal: fica na `main`, NUNCA tocado
```

O `sdd` do `PATH` é o checkout **principal** (`readlink -f ~/.hermes/bin/sdd` →
`/home/joruge/repos/sdd_agents/bin/sdd`), e todo `sdd run` de repo-alvo executa o código de lá. Por
isso, quatro regras valem para a missão inteira:

1. **Toda sessão trabalha com `cwd` no worktree** e roda o runner como **`./bin/sdd`**, nunca como
   `sdd` nu. O `sdd` nu executa o código da `main`, não o desta branch, e o `SDD_HOME` dele é o
   checkout principal.
2. **Nada é escrito, commitado, `checkout`-ado nem `stash`-ado em `/home/joruge/repos/sdd_agents`.**
   Um arquivo não rastreado ali faz o `sdd run` de um alvo em voo parar como `kit-touched`
   (reproduzido; ADR 0016 §2).
3. **Os ajudantes de `~/.claude/plans/2026-10-03-helpers/` têm o checkout principal fixo no código:**
   `ROOT=/home/joruge/repos/sdd_agents` em `remap.py`, `xref.py`, `sab.sh`, `sab.py` e
   `trymut.sh`, e o caminho do lote 3 em `cpdone.py` e `chk.py`. Rodados como estão, o `remap.py`
   e o `xref.py --fix` **reescreveriam o `TODO.md` do checkout principal**, e o `sab.sh` sabotaria
   um clone **sem** as mudanças desta branch. Copie-os para o scratchpad, troque `ROOT`/`D`/`CP`
   para o worktree e para esta missão, e só então use. Sem os ajudantes, todo passo se faz à mão
   (§ Mecânica da casa).
4. **O hook de limpeza de sandboxes** mora em `.claude/settings.local.json`, que NÃO é rastreado e
   por isso existe só no checkout principal. Medido: o `.claude/` do worktree tem `agents/`, `rules/`
   e `settings.json`, e nada mais. Numa sessão aberta com `cwd` no worktree, conte com o hook
   ausente e apague seus clones de rascunho no fim. Numa sessão aberta do checkout principal, todo
   comando cujo texto contém `git commit` apaga os diretórios de UM nível abaixo do scratchpad que
   tenham `bin/sdd`. Por isso, clone de rascunho fica dois níveis abaixo (`scratchpad/<x>/kit`).

O que o relay já fez, antes do I1, com o humano presente:

- criou o worktree (`git worktree add --detach … origin/main`, depois
  `git switch -c fix/lote-5-o-que-o-lote-4-deixou`);
- commitou o plano: esta pasta, a ADR 0016 (`docs/adr/0016-the-mission-checkpoint-and-the-kit-worktree.md`),
  o `TODO.md` com o #235 e o item do `sdd kaizen`, e `tests/health-baseline.txt` → `todo-findings 13`;
- rodou `./bin/sdd approve` depois da pergunta YES/NO ao humano.

Confira antes do I1. Todo comando daqui em diante roda com o ambiente de § Mecânica
(`mkdir -p /tmp/l5-exec`, depois `env -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE -u CLAUDECODE
TMPDIR=/tmp/l5-exec …`):

1. `pwd -P` → `/home/joruge/repos/sdd_agents-lote-5`; `git branch --show-current` →
   `fix/lote-5-o-que-o-lote-4-deixou`; `git status --short` → vazio.
2. `git -C /home/joruge/repos/sdd_agents branch --show-current` → `main` (só leitura).
3. `bash tests/check-todo.sh` → `  ok    13 finding(s), all within 8 lines, carrying anchor + date,
   every anchor on target`.
4. `./bin/sdd why 20261006-lote-5-o-que-o-lote-4-deixou PLAN` → `plan approved (humano-…)`.

Se o passo 4 disser que o plano não está aprovado, **pare** e peça ao humano: a aprovação é dele, e
nenhuma sessão escreve `aprovacao:` à mão.

**O fluxo de cada incremento** é o padrão da casa, o mesmo dos lotes 1–4:

1. Red observado pelo motivo certo: o Check da tabela rodado **antes** do conserto, com a saída
   anotada; depois o probe novo escrito e a linha `FAIL` dele vista no código de antes.
2. Conserto.
3. Sabotagem do conserto: `--only` no mutante novo **e** nos mutantes vizinhos da mesma função, ou
   a passada de sabotagem do selftest quando a regra mora em `tests/`.
4. Sensores tocados inteiros, `shellcheck -S warning` nos arquivos tocados, `bash -n bin/sdd` e, se
   `bin/` mudou, `tests/check-mutation.sh --anchors`.
5. Re-âncora do `TODO.md` (o `check-todo.sh` está no `TEST_CMD` e reprova âncora deslocada).
6. O commit do incremento, um por item. O I7 tem três (#228, #227 e os resíduos da decisão 11a), e o
   I8 tem dois (#229 e #230).
7. Por último, um commit SEPARADO `chore(checkpoint): I<n> done (<hash>)`, com a linha do
   `checkpoint.md` (Status `done` e o hash curto nu do commit do passo 6) e uma nota appendada ao
   `checkpoint-notas.md` (`>>`, nunca reescrever). A nota diz o Red medido, os desvios e as
   sabotagens.

**A anatomia do agente muda no MESMO commit do incremento que toca o componente** (regra do
`CLAUDE.md`, "Os sete componentes de um agente têm rule própria"). A edição é interativa, porque
sessão headless não escreve em `.claude/rules/anatomia-do-agente.md`.

| Incremento | Seção da anatomia |
|---|---|
| I1 | §6: a suíte, o catálogo e cada sensor limpam as variáveis de repositório do git (`tests/isolate-git.sh`) |
| I4 | §4 "Onde mora hoje": a âncora 3 do `gate_QA` lê a decisão escrita do bug `deferred` |
| I5 | §4 "Dívida declarada": a linha das Âncoras 1/2 cita a 0015 §3 e a 0016 §1 |
| I6 | §6: a guarda do kit compara a árvore suja por caminho e conteúdo, e diz o que mudou |
| I7 | §7: a nota `intervention:` só existe com sessão (`--phase`, `retry`, `--budget-override`); o remédio da parada no carimbo distingue o carimbo impossível |
| I8 | §5: o `status_unrecorded` cala sem `session` desta máquina; §7: o `ok` do `note-manual` lê `CHECKPOINT_NOTE` |
| I9 | §1: o `turn_rule` ganha o processo em background; §6: o supervisor nomeia quem segura o checkout |
| I10 | §6: a missão do kit mora num worktree ligado (texto proposto no I10) |

O I2 e o I3 não tocam a anatomia. O I11 só confere.

## Contexto verificado (não re-descobrir)

Tudo abaixo foi medido em 2026-10-06 sobre `origin/main` = `89df2e5`, pelo planner e por seis grupos
de protótipo, cada um num clone próprio. Os números de linha envelhecem a cada commit: ache pelo
**símbolo** citado, nunca só pelo número.

### Estado e números de partida

- `bash tests/check-todo.sh` → `  ok    13 finding(s), all within 8 lines, carrying anchor + date,
  every anchor on target`, medido no worktree com o #235 e com o item do `sdd kaizen` (decisão 11b).
  Na `main` são 11, com `todo-findings 11`. O commit do plano leva `tests/health-baseline.txt` →
  `todo-findings 13`.
- Espelho: 13 issues abertas com label `todo` (#223–#230 e #232–#235, mais a do `sdd kaizen`, criada
  pelo relay antes do commit do plano).
  - O título de um item **não muda**, porque a chave da issue é o hash do título: renomear cria uma
    issue nova.
  - O item do `sdd kaizen` **não** é consertado nesta missão.
- **N**, em todo este plano, são os achados que nascem durante a leva. A catraca:
  - fica em 13 + N na branch, porque os 12 `RESOLVED by` só saem no chore pós-merge;
  - vai a 1 + N depois do chore.
- Catálogo: **619** mutantes (`grep -cE '^mut_[A-Za-z0-9_]+\(\)' tests/check-mutation.sh`), array
  `CATALOG=(` em `tests/check-mutation.sh:5645`.
- Carimbo: `.sdd/logs/mutation-stamp` do checkout principal = `48b46919333241943e5bf58a73f330de`
  (`619 caught of 619`), válido para a `main`. O worktree não tem `.sdd/logs/` nem `.sdd/cache/`
  (ambos ignorados). O `gate_PR` desta missão exige um `./bin/sdd health` verde **no worktree**
  depois do último commit de código.
- Chave do carimbo: `bin/sdd:2147` `readonly MUTATION_STAMP_PATHS=(bin tests templates config agents)`
  menos `tests/health-baseline.txt`. Identidade de comportamento: `bin/sdd:3717`
  `readonly KIT_BEHAVIOR_PATHS=(bin agents templates config)`. `commands/` está fora das duas.
- 16 sensores (`ls tests/check-*.sh`). `bin/sdd` tem 11 414 linhas e `bin/sdd-coordination.py`, 520.
- Espelho dos agentes: os 8 `agents/*.md` são byte a byte iguais aos de `.claude/agents/`.
- `~/.claude/commands/sdd-plan.md` é symlink para `/home/joruge/repos/sdd_agents/commands/sdd-plan.md`
  (o checkout principal). A mudança do I10 só chega ao `/sdd-plan` do humano **depois do merge**.
- `ADR_CHECK="block"` (`.sdd/config.sh:32`). `./bin/sdd adr check` → rc 0 com a 0016 alocada:
  `ok    ADR_CHECK=block, 16 ADR(s) in docs/adr`.
- Imagens Docker `bash:4.0` … `bash:4.4` existem nesta máquina (`docker images`).

### Mecânica da casa que todo incremento usa

- **Ambiente de todo comando:** `env -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE -u CLAUDECODE
  TMPDIR=/tmp/l5-exec`, com o diretório criado antes (`mkdir -p /tmp/l5-exec`).
  - Sem o `env -u GIT_*`, os fixtures dos sensores escrevem no repo de quem os chama. É o próprio
    #226, e até o I1 pousar a suíte não se protege sozinha.
  - O `TMPDIR` tem de ser curto: com um `TMPDIR` de ~100 caracteres (o do harness, ou o do
    scratchpad), uma asserção do kit-guard em `check-autonomy.sh` reprova. Isso está declarado
    no sensor desde `0c0e13a`.
  - O nome não pode começar com `sdd-`, porque o hook de limpeza do checkout principal apaga
    `/tmp/sdd-*` com mais de 10 min.
- **Suíte:** `bash tests/run-all.sh` → última linha `suite green` (rc 0), ~5 min.
  - Rode-a inteira depois do I3, do I6, do I9 e no I11.
  - Entre elas, antes de cada commit, rode os sensores que o incremento toca, mais
    `bash tests/check-todo.sh`, `bash tests/check-lang.sh` e `bash tests/check-pipefail.sh` sempre
    que `tests/` ou `bin/` mudarem.
- **Mutante novo** = função `mut_<SLUG>() { sed -i '…' "$1"; }` em `tests/check-mutation.sh`,
  **mais** o `<SLUG>` no array `CATALOG=(`.
  - O sed usa faixa `/^<função>() {/,/^}/` e âncora em CÓDIGO, nunca em número de linha. O modelo
    é `mut_RUN_kit_touched_silent`.
  - `apply_mutant` só sabota `bin/`. O `$1` é a cópia do `bin/sdd`, e um mutante do helper Python
    escreve em `"${1%/*}/sdd-coordination.py"`; o modelo são os mutantes perto de
    `tests/check-mutation.sh:5457`.
  - Prove com `tests/check-mutation.sh --only <SLUG> <sensor>`. O sensor vai como **nome nu**
    (`check-gates.sh`); com caminho, o comando sai rc 2. A linha verde é
    `  ok    <SLUG> — check-gates.sh dies (rc 1)`.
  - Depois rode `tests/check-mutation.sh --anchors` (segundos): todo mutante tem de **aplicar**.
  - Mexeu numa guarda? Rode `--only` nos mutantes **vizinhos** da mesma função, listados em cada
    incremento. O `79b6f93` cegou dois assim.
  - Mexeu num sensor? `tests/check-mutation.sh --touched <rev> --list` lista os mutantes que ele
    matou na última rodada (é dica).
- **Sensor que a mutação não alcança** (tudo em `tests/`, mais probe de texto de chapéu, comando e
  template): a regra nova ganha probe no `selftest()` ou na lista de topo do sensor, e o executor faz
  a **passada de sabotagem**.
  - Degrade a regra (as sabotagens estão listadas em cada incremento) e exija o sensor vermelho em
    cada uma.
  - Antes, prove que a sabotagem **aplicou**: probe que não mudou o arquivo conclui em falso.
  - Faça a sabotagem numa cópia: `cp -a` do worktree para `scratchpad/<x>/kit` (dois níveis abaixo
    do scratchpad), `sed`/`perl` lá, e rode o sensor lá.
- **Âncoras do `TODO.md` deslocam a cada commit que move linhas** em `bin/sdd` ou `tests/*.sh`, e o
  `check-todo.sh` está no `TEST_CMD`. Antes de cada commit:
  - `bash tests/check-todo.sh --anchors TODO.md` lista as âncoras e diz "nearest X is at line N"
    para as que saíram do alcance. Desde o lote 4 a dica nomeia o **símbolo designado** (o slot
    `` (`<símbolo>`) ``): re-ancore pela dica, editando o número no `TODO.md`;
  - confira pelo conteúdo: `git show HEAD:<arquivo> | sed -n '<N>p'` (aqui o pipe é de shell, não
    de Check);
  - os ajudantes `remap.py`/`xref.py` só depois de trocados para o worktree (Passo 0, regra 3).
- **Shell é zsh:**
  - nunca use `path` como nome de variável;
  - escreva `"${r}:arquivo"`, nunca `$r:arquivo`;
  - `echo ====` falha (ponha aspas);
  - não há `/dev/tcp`;
  - envolva laços e pipelines em `bash -c '…'`.
- **Espelho dos agentes:** `agents/sdd-*.md` → `.claude/agents/` só por `./bin/sdd install --force`
  rodado **no worktree** (o `SDD_HOME` dele é o worktree). Nunca `cp`, nunca Edit. O
  `./bin/sdd preflight` reprova `agent <nome> stale`. Rode-o no MESMO incremento que mexe num chapéu.
- **`shellcheck -S warning`** nos arquivos tocados antes de cada commit em `bin/` ou `tests/`, e
  `python3 -I -S -c 'import ast,sys; ast.parse(open(sys.argv[1]).read())' bin/sdd-coordination.py`
  quando o helper mudar.
- **Idioma:**
  - `bin/`, `agents/`, `commands/`, `docs/` (fora de `docs/handoffs/`, `docs/qa/` e
    `docs/superpowers/`), `README.md`, `config/schema.md`, `config/starter.conf` e `tests/` são
    superfície **inglesa**;
  - `TODO.md`, `CONTEXT.md`, `CLAUDE.md`, `KAIZEN_LOG.md`, `templates/`, `.claude/rules/` e os
    handoffs falam pt-BR;
  - o slug `20261006-lote-5-o-que-o-lote-4-deixou` não tem stopword do `check-lang`, então pode ser
    citado em comentário de `tests/` e `bin/`.
- **Checks** (`templates/checkpoint.md`, cobrados por `tests/check-checkpoint.sh`, que escaneia
  ESTE checkpoint também):
  - célula com `2>&1` e `grep` exige **todo** `grep` ancorado em `^  ok    `, e as contagens de
    arquivo nas células mistas usam `awk`;
  - nunca `|` cru, nem `||`;
  - forma estrita `` `cmd` → `esperado` ``;
  - o `run-all.sh` imprime `suite green` sem o prefixo ok, então se lê pelo rc.
- **Formato do `TODO.md`:**
  - **Item aberto:** teto de 8 linhas físicas e 120 caracteres por linha.
  - **Conserto por commit:** o corpo ganha ` RESOLVED by <hash>` no I11, e o item só sai no chore
    pós-merge (`templates/todo.pt-BR.md` § Ciclo de vida).
  - **Achado novo:** item com âncora, slot de símbolo e data, e a catraca
    (`tests/health-baseline.txt`) +1 no MESMO commit.
- **Commits:** `<tipo>(<escopo>): <o quê>`, com o porquê no corpo, um por item, com o trailer da
  sessão.

### Fatos que atravessam incrementos

- **De onde vêm os números.** Cada seção de incremento foi prototipada e provada por um designer,
  num clone próprio de `89df2e5` (grupos A–F do planejamento). As linhas citadas são as de `89df2e5`.
  Depois que os incrementos anteriores pousarem, ache pelo **símbolo** e meça de novo. Os textos
  exatos (código, asserções, prosa decidida) valem como estão.
- **Os protótipos são só acelerador opcional.** Cópia persistente em
  `~/.claude/plans/2026-10-06-lote-5-protos/` (fora do repo, não versionada):

  | Grupo | Itens | Arquivo |
  |---|---|---|
  | A | #226 (I1), #235 (I10) | `226b.patch`, `235.patch` |
  | B | #224 (I2), #223 (I3) | `B-224-223.patch` (os hunks do #223 são o `red_norm`, o bloco `declare -f` e +1 no piso) |
  | C | #232 (I4), #225 (I5) | `232.patch`, `225.patch` |
  | D | #233 (I6), #228 + #227 (I7) | `233.patch`, `227-228.patch` |
  | E | #229 + #230 (I8), #234 (I9) | `229.patch`, `230.patch`, `234.patch` |
  | F | resíduos da #227 (I7) | `F-delta.patch`, que aplica **sobre** o `227-228.patch` |

  O plano é a fonte. Cada patch é o protótipo de **um** grupo sobre `89df2e5` e pode não aplicar sobre
  os incrementos anteriores. O I1 acrescenta uma linha `source` no topo de todo sensor, e isso move o
  contexto dos hunks de todos os outros patches.
- **Pontos de contato entre incrementos de grupos diferentes,** cada um provado só sobre `89df2e5`:
  - `tests/check-gates.sh`: I2, I4, I5, I7 e I8;
  - `tests/check-autonomy.sh`: I6, I7 e I8;
  - o array `CATALOG=(` de `tests/check-mutation.sh`: todo incremento de runner;
  - `checkpoint_note_intervention`: o I7 move as chamadas e o I8 publica `CHECKPOINT_NOTE` dentro do
    helper. O contrato que os dois respeitam é "global publicado e `return 0` em todo caminho";
  - `hat_status_lines`: o I6 acrescenta o argumento de raiz, e o guarda do chapéu continua a chamá-la
    sem argumento;
  - o topo de todo `tests/check-*.sh`: o I1.

  Rode o sensor inteiro do ponto de contato, não só a asserção nova.
- **Âncoras do `TODO.md` que os incrementos deslocam de propósito:**
  - o item da #227 ancora em `bin/sdd:8198` (`checkpoint_note_intervention`), a chamada que o I7
    **tira** dali. Re-ancore na chamada nova, a que fica antes de `before="$(state_fingerprint)"`;
  - o item da #235 ancora em `commands/sdd-plan.md:15` (`HANDOFF_DIR`), que o passo novo do I10
    empurra para baixo;
  - num protótipo, a suíte inteira saiu vermelha só no `check-todo.sh`: as âncoras das linhas 49, 76,
    85, 93 e 100 do `TODO.md` saíram do alvo. A re-âncora é parte de todo commit (§ Mecânica).
- **Os Checks com contagem absoluta** valem no commit do próprio incremento. Os de catraca são só os
  do I11.
- **Catálogo:** 619 → cerca de 656 (4 + 5 + 3 + 4 + 11 + 6 + 4), com os mutantes novos listados em cada incremento. O número sai
  de `grep -cE '^mut_[A-Za-z0-9_]+\(\)' tests/check-mutation.sh` e do `--anchors`, nunca daqui.
- **Mudança de comportamento a declarar no PR:**
  - I4: um bug `deferred` sem a seção de decisão bloqueia a QA;
  - I6: um kit sujo que é editado durante a fase de um alvo para a linha;
  - I7: a nota `intervention:` do `--phase`, do `retry` e do `--budget-override` só existe quando a
    volta abre sessão;
  - I9: o supervisor imprime uma linha a mais no stderr.

## Arquitetura da mudança

Seis frentes. Nenhuma cria daemon, banco ou servidor (princípio 6). Três mudam um contrato entre
módulos (DDD D5): o gênero `deferred` do bug de QA, a nota `- intervention:` do `--phase` e a posse
do relatório de QA na ponta da base. As outras apertam guardas e sensores que já existem.

| Frente | Incrementos | Arquivos | Contrato / ADR |
|---|---|---|---|
| Ambiente da suíte | I1 | `tests/isolate-git.sh` (novo, uma definição), `tests/run-all.sh`, `tests/check-mutation.sh`, os 16 `tests/check-*.sh` (uma linha `source` cada), `tests/check-health.sh` (probes) | nenhum |
| Leitores do checkpoint | I2, I3 | `bin/sdd` (`checkpoint_rows`), `tests/check-checkpoint.sh` (`rows_of`, `red_norm`) | nenhum: a forma da tabela não muda, só deixa de sumir em silêncio |
| Gate de QA | I4, I5 | `bin/sdd` (`gate_QA` âncora 3, `tip_add_carries_mission`), `agents/sdd-qa.md` §5.1 (+ espelho), `docs/pipeline.md` | gênero `deferred` exige a decisão escrita (ADR 0009, cumprida); ADR 0016 §1 (emenda a 0015 §3) |
| Guarda do kit | I6 | `bin/sdd` (`kit_guard_arm`, `kit_guard_check`) | nenhum: o motivo do `kit-touched` ganha conteúdo, o `kind` não muda |
| Portas humanas do runner | I7, I8 | `bin/sdd` (`cmd_run`, `gate_PR`, `status_unrecorded`, `checkpoint_note_intervention`, `cmd_note_manual`), `templates/checkpoint-notas.md`, `docs/pipeline.md` | a nota `intervention:` do `--phase` só existe com sessão (decisão 6) |
| Coordenação e regra do turno | I9 | `bin/sdd-coordination.py` (`wait_family`), `bin/sdd` (`turn_rule` em `boot_prompt`) | nenhum: o stderr do supervisor ganha uma linha |
| Onde a missão do kit mora | I10 | `commands/sdd-plan.md`, `.claude/rules/anatomia-do-agente.md` §6 | ADR 0016 §2 |

## Incrementos

A tabela executável vive em `checkpoint.md`. Aqui fica o **porquê** de cada fatia. A ordem:

1. **I1, o ambiente da suíte (#226):** é o único item com efeito destrutivo medido. Até ele pousar,
   todo comando roda com `env -u GIT_*` (§ Mecânica).
2. **I2 e I3, os leitores do checkpoint:** o `--red` do I3 é a ferramenta que o planner usa no PLAN.
3. **I4 a I6, os três sensores do runner que falham abertos.**
4. **I7 a I9, as portas humanas e a coordenação.**
5. **I10, o `/sdd-plan` (#235):** muda o comando que o humano usa no próximo planejamento.
6. **I11, o fecho.**

Cada seção traz o Red medido no protótipo sobre `89df2e5`, o conserto, os mutantes e o que muda no
mesmo commit. Os números de linha são de `89df2e5`: ache pelo símbolo.

### I1 — #226: a suíte, o catálogo e cada sensor limpam o repositório que um chamador movido a git lhes entrega

**O quê:** um arquivo único, `tests/isolate-git.sh`, limpa as variáveis de repositório que o próprio
git lista e recusa um git que não nomeia `GIT_DIR`. Ele é carregado por `source` em 17 lugares: o
`tests/run-all.sh` e os 16 `tests/check-*.sh`. Como o `check-mutation.sh` é um deles, o `--only` e o
`--touched` também ficam cobertos. A decisão 10 explica por que são todos.

**Por que não basta o `run-all.sh`** (medido pelo grupo A):
- **O incidente de 2026-10-05 entrou por `check-mutation.sh --only`,** que roda o sensor direto
  (`bash "$1/tests/${3:-$ONLY_SENSOR}"`, perto de `tests/check-mutation.sh:6688`) e nunca passa pelo
  `run-all.sh`. O `touched_selftest()` (`:354`, tags em `:364-366`) roda em todo modo e cria as tags
  `base` e `hat` do incidente.
- **Reprodução:** `GIT_DIR=$isca/.git tests/check-mutation.sh --only NO_SUCH_SLUG check-hat.sh` → rc 2,
  e a isca fica com `refs/tags/base`, `refs/tags/hat` e `main` movido.
- **Quem exporta `GIT_DIR`** (git 2.43): no worktree **principal**, só `GIT_PREFIX`; num worktree
  **ligado**, `bisect run`, `rebase --exec`, os hooks pre-commit e pre-push e um alias `!` exportam
  `GIT_DIR` absoluto. Esta missão mora num worktree ligado.
- **Sensor rodado sozinho sob `GIT_DIR` de uma isca:** em `89df2e5`, 12 dos 16 moviam a isca. O pior
  caso é o `check-autonomy.sh` sob o `.git` **principal**: o `git init --separate-git-dir` (perto de
  `tests/check-autonomy.sh:4517`) troca o `.git` por um gitfile que aponta para um temporário que o
  trap apaga, e o repo se perde.
- **A forma do incidente:** um único `bash tests/check-hat.sh` sob o `GIT_DIR` de um worktree ligado
  gravou `core.bare = true` e `user.email` na config comum.

**Onde:**
- `tests/isolate-git.sh` (novo);
- `tests/run-all.sh` (`SDD_TEST_STATE` em `:33-35`; a linha `source` fica logo abaixo do `set … pipefail`);
- os 16 `tests/check-*.sh` (uma linha cada, logo abaixo do `set … pipefail`);
- `tests/check-health.sh` (os probes, no bloco `surface:` depois do probe de interrupt, perto de
  `:1659`; o mundo `FAILFAST` em `:1418`; o cabeçalho ganha o item 20);
- os pisos `LINT_FLOOR` (`tests/run-all.sh`) e o de superfície do `tests/check-pipefail.sh`, mais o
  fixture do selftest dele.

**O arquivo novo** (47 linhas no protótipo, inglês):
- O cabeçalho diz o porquê, as medições e por que são "todos os sensores".
- A lista vem de `git rev-parse --local-env-vars`: 15 nomes no git 2.43, entre eles
  `GIT_CONFIG_PARAMETERS`, que o alias `!` exporta. Lista derivada vence lista escrita à mão.
- **Ficam fora, de propósito:**
  - `GIT_REFLOG_ACTION` (o `check-autonomy.sh` o usa para rotular sessão);
  - `GIT_CEILING_DIRECTORIES` (o `check-lang` e o `check-checkpoint` o exportam para um filho);
  - `GIT_AUTHOR_*`, `GIT_COMMITTER_*` e `GIT_CONFIG_GLOBAL` (dizem como escrever, nunca onde).
- Uma lista que não nomeia `GIT_DIR` é recusada com `exit 1`, e a mensagem contém `named no GIT_DIR`.
- O trabalho fica numa função `_sdd_isolate_git` com array local, desfeita com `unset -f`. Medido: não
  sobra variável nem função no shell que a carrega.
- A **1ª linha** é `# shellcheck shell=bash`. O arquivo é carregado com `source` e não leva shebang, e
  sem essa diretiva o `shellcheck -S warning` reporta o SC2148, que tem severidade error.

O miolo é o do protótipo:
```bash
mapfile -t GIT_REPO_ENV < <(git rev-parse --local-env-vars 2>/dev/null)
case " ${GIT_REPO_ENV[*]-} " in
  *" GIT_DIR "*) unset "${GIT_REPO_ENV[@]}" ;;
  *) echo "…: 'git rev-parse --local-env-vars' named no GIT_DIR — cannot clear …" >&2; exit 1 ;;
esac
```
Dentro da função, com `local -a` no lugar do global.

**A linha nos 17 arquivos** é exatamente `. "$(dirname "${BASH_SOURCE[0]}")/isolate-git.sh"`. Ela vai
logo abaixo do **primeiro** `set … pipefail`, que nos 17 arquivos está na coluna 0, e assim vem antes
de qualquer `cd`, `ROOT` ou `git`. ⚠️ O `check-adr.sh` (`:210`, `:812`) e o `check-dry-run.sh`
(`:17`, `:203`) têm um segundo `set -uo pipefail` na coluna 0, dentro de heredoc; nesses, a linha vai
só abaixo do primeiro. Medida funcionando:
- de qualquer cwd;
- na sandbox do catálogo, que copia `tests/`;
- nos sensores que se reinvocam por `SELF_PATH`.

**Como (TDD):** quatro asserções no `check-health.sh`, família `surface:`, rodadas só **fora** de
mutante (nenhum mutante alcança `tests/`).
1. **`surface: the suite clears the repository a git-driven caller hands it`.** Usa uma cópia do mundo
   `FAILFAST` (o `run-all.sh` real com sensores stub). O stub do `check-templates.sh` faz o que um
   fixture faz: `init`, `config`, `add`, `commit` e `tag`, num temporário próprio.
   - O veneno é `GIT_DIR` + `GIT_INDEX_FILE` na isca. **Nunca** `GIT_WORK_TREE`: com ele, o selftest
     do catálogo morre antes de taguear, e a isca intacta seria falso verde.
   - **Testemunha:** a linha `fixture-tagged` prova que o stub tagueou o repo DELE.
   - **"Intacta"** compara a saída de `gitenv_print <isca>` antes e depois. Ela lê `.git/config`,
     `.git/HEAD`, toda ref (`git --git-dir=<isca>/.git for-each-ref --format='%(refname) %(objectname)'`)
     e o `cksum` do `.git/index`. A isca nasce com um commit e uma tag, e é construída por
     `gitenv_bait` num subshell que faz `unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE`.
   - **Mudo:** atrás de um `git` falso no PATH que responde `--local-env-vars` vazio, o `run-all.sh
     --list` tem de sair rc 1 com `named no GIT_DIR`, e nenhum passo pode rodar.
   - **Armado:** o stub, rodado sozinho, TEM de mover a isca, senão `broken` (rc 90).
2. **`surface: the catalogue clears the repository a git-driven caller hands it`.** É
   `tests/check-mutation.sh --only NO_SUCH_SLUG_GITENV` sob o veneno: rc 2, recusando o slug depois
   dos selftests (`^  ok    touched: `), com a isca intacta, mais o mesmo mudo.
3. **`surface: a sensor run alone clears the repository a git-driven caller hands it`.** É o
   `tests/check-hat.sh` real, sozinho, sob o veneno: rc 0, a linha `ok    N hat(s) declare…` e a isca
   intacta. Custa de 2 a 5 s. Foi escolhido porque em `89df2e5` ele gravava `user.email` na isca e saía
   0.
4. **`surface: every sensor sources tests/isolate-git.sh before its first git`.**
   - O `gitenv_census` lê o `run-all.sh` e cada `check-*.sh`. **A regra é: o `source` é sempre
     exigido, e, quando o arquivo tem `git`, vem antes da primeira linha com `git`.** O protótipo faz
     isso com um awk por arquivo, e `GITENV_SOURCE` é a linha `source` exata:
     ```
     $0 == want && !src { src = NR }
     !first && $0 !~ /^[[:space:]]*#/ && $0 ~ /(^|[^[:alnum:]_.\/-])git([^[:alnum:]_-]|$)/ { first = NR }
     END { print (src ? src : 0), (first ? first : 0) }
     ```
     - `src` 0 conta como faltando.
     - `first` 0 (nenhum `git`) passa.
     - Nos demais casos, `src < first` é exigido.
     - ⚠️ A classe antes de `git` exclui `-`, `.` e `/`. É isso que impede a própria linha `source`
       (`…/isolate-git.sh`) de contar como "primeiro git". Se você mudar a regex, prove que a linha do
       `source` não casa, senão todo arquivo reprova.
     - `run-all.sh`, `check-entrypoint.sh` e `check-pipefail.sh` não têm `git` fora de comentário, e
       continuam exigindo o `source`.
   - Os resultados saem em globais (`GITENV_SEEN`, `GITENV_MISSING`): a função é chamada, nunca
     capturada por `$( )`.
   - Piso `GITENV_FLOOR=17`.
   - O vermelho nomeia cada arquivo que falta ou que carrega tarde.
   - **Controle negativo,** num mundo sintético de 5 arquivos. Cada um é escrito com
     `printf '%s\n' '#!/usr/bin/env bash' 'set -uo pipefail' …`:
     - `run-all.sh` e `check-good.sh` têm o `source` antes de `git -C "$box" log`;
     - `check-nogit.sh` tem o `source` e nenhum `git`;
     - `check-late.sh` tem `( cd "$box" && git init -q )` **antes** do `source`;
     - `check-none.sh` tem `git init -q "$box"` e nenhum `source`.

     O censo tem de nomear exatamente `check-late.sh check-none.sh`, com `GITENV_SEEN` = 5. Senão,
     rc 90.
   - ⚠️ Não copie o `tests/` real para o controle. Em `89df2e5`, isso dá `SENSOR-BROKEN` em vez de
     `FAIL`, ou seja, vermelho pelo motivo errado.

**Os mundos stub do `check-health.sh` que copiam o `run-all.sh` precisam copiar o `isolate-git.sh`
também,** senão todo probe `surface:` morre na 1ª linha do `run-all`:
- no `SURF`, logo depois de `mkdir -p "$SURF/tests"`;
- no `FAILFAST`, logo depois do `cp` do `run-all.sh`.

O mundo `FIX` copia o `check-mutation.sh` mas nunca o executa, e não precisa.

**Red medido** com o `check-health.sh` novo sobre o código de `89df2e5` (rc 1):
```
  FAIL  surface: the suite clears … — got: bait MOVED, … mute git: rc 0
  FAIL  surface: the catalogue clears … — got: rc 2, bait MOVED, selftest line: 1, mute git: rc 2
  FAIL  surface: a sensor run alone clears … — got: rc 0, bait MOVED
  FAIL  surface: every sensor sources tests/isolate-git.sh before its first git — got: missing or too late in: run-all.sh check-adr.sh … check-todo.sh
```

**Verde medido:**
- `check-health.sh` rc 0, em cerca de 35 s;
- o censo dos 16 sensores, rodados sozinhos sob o veneno: **0 de 16** movem a isca (eram 12), e todos
  saem rc 0;
- o `check-autonomy` sob o `.git` principal preserva o diretório;
- a suíte inteira sob o veneno: `suite green` e a isca intacta, em cerca de 7 min.

**Mutantes:** nenhum possível, porque o conserto mora em `tests/` e o `apply_mutant` só sabota `bin/`.
Re-prove por `--only`, a primeira vez pela sandbox depois da mudança:
- `RUN_entrypoint_unguarded` (`check-entrypoint.sh`);
- `HEALTH_ratchet_one_way` e `HEALTH_suite_without_mutation` (`check-health.sh`);
- `BOOT_notes_not_inlined` e `HEALTH_with_mutation_refused` (`check-hat.sh`).

Rode também `--anchors`.

**Passada de sabotagem:** no protótipo, 8 de 9 ficaram vermelhas pelo motivo certo.

| Sabotagem | Resultado |
|---|---|
| um sensor sem o `source` (`check-kaizen`) | `FAIL missing or too late in: check-kaizen.sh` |
| `check-hat` sem o `source` | `FAIL` no estático e no "sensor run alone" |
| o `source` do `check-gates` movido para baixo da 1ª linha de código com `git` | `FAIL` nomeando `check-gates.sh` |
| glob estreitado (`check-a*.sh`) | `SENSOR-BROKEN` |
| ordem ignorada | `SENSOR-BROKEN` |
| `isolate-git.sh` sem `unset` | `FAIL` em suite, catalogue e alone |
| a recusa amolecida | `FAIL` em suite e catalogue |
| `unset GIT_DIR` só | `FAIL` em suite, catalogue e alone |

A 9ª sabotagem, `GITENV_FLOOR=0` sozinho, **sobrevive**. É o par de duas edições, como o
`LINT_FLOOR`, e fica declarado no comentário do piso.

⚠️ Ponha a linha sabotada abaixo de **código** com `git`, não de um comentário. A 1ª tentativa do
protótipo deu um falso sobrevivente assim.

**Check:**
`` `o=$(bash tests/check-health.sh 2>&1); grep -c -e '^  ok    surface: .* clears the repository a git-driven caller hands it' -e '^  ok    surface: every sensor sources tests/isolate-git.sh before its first git' <<< "$o"` → `4` ``.
Medido: 0 antes e 4 depois. O `--red` no limpo respondeu `prints '0', wants '4'`.

**Sensor durável:** as quatro asserções `surface:` e o censo estático.

**No mesmo commit:**
- **Os pisos que o arquivo novo move,** porque ele é um `tests/*.sh` que não é sensor:
  - `LINT_FLOOR` vai de 19 para 20. O comentário de histórico ganha uma linha;
  - o piso de superfície do `check-pipefail.sh` vai de 18 para 19, nas duas ocorrências do literal;
  - o laço do fixture `full` do selftest dele vai de 16 para 17 arquivos (o "quinto lugar" do
    `CLAUDE.md`).

  Não mudam: o `CALIBRATE_FLOOR` (continuam 16 sensores com prefixo `ok`), o `run-all --list` (19
  passos) e o `step_timeout`.
- **`CLAUDE.md`, § "'Entra lá' são quatro lugares":**
  - sensor novo ganha mais dois deveres: a linha `source` abaixo do `set … pipefail`, que o censo
    cobra vermelho, e o piso `GITENV_FLOOR` do `check-health.sh`, mais um piso anti-vacuidade escrito
    à mão, com o mesmo limite declarado;
  - um arquivo `tests/*.sh` que não é sensor move o `LINT_FLOOR`, o piso do `check-pipefail` e o
    fixture dele, e mais nada.
- **Anatomia §6:** uma frase.
  > Desde #226 a suíte, o catálogo e todo `tests/check-*.sh` carregam `tests/isolate-git.sh` — uma definição, lista de `git rev-parse --local-env-vars` — antes do primeiro `git`; medido, sensor sozinho sob `GIT_DIR` de uma isca: 12 de 16 a moviam em `89df2e5` (o `check-autonomy` trocava o `.git` inteiro por um gitfile para um temporário apagado), 0 de 16 depois. O censo mora no `check-health.sh` (`surface: every sensor sources …`).
- **O cabeçalho do `check-health.sh`** ganha o item 20.

⚠️ **Não edite o `run-all.sh` enquanto uma suíte roda a partir dele.** O bash lê o arquivo por
offset, e a corrida se corrompe.

⚠️ **O `isolate-git.sh` só entra na chave do carimbo depois do `git add`.**

**Reversível por:** reverter o commit.

### I2 — #224: a linha `|`-led com menos de cinco células deixa de sumir dos dois leitores do checkpoint

**O quê:** no GFM, `| I2 | slice | pending |` é linha de tabela, e as células que faltam saem vazias.
Hoje o `checkpoint_rows` (`bin/sdd:554`, `if (n < 6) next` em `:587`) e o `rows_of`
(`tests/check-checkpoint.sh:209`, `if (NF < 6) next` em `:216`) descartam essa linha em silêncio. O
`pending` some do `checkpoint_tally`, e o `gate_EXEC` passa.

Depois do conserto:
- o **runner** lê a linha como o GFM a renderiza: as células que faltam ficam vazias, o Status lido
  vem vazio, e o `gate_EXEC` a recusa **nomeando o ID**;
- o **sensor** (`--check` e `--red`) recusa a linha com uma frase própria.

O desenho é o do `c71913c` para a linha sem `|` inicial. O runner a lê como o GFM renderiza: devolve o
pipe (`tbl && /\|/ && !/^[ \t]*\|/ { $0 = "|" $0 }`), e o estado `tbl` zera na linha em branco. Só o
sensor recusa pelo nome (`row $id has no leading '|'`).

**A regra vale só dentro de tabela cujo CABEÇALHO (a 1ª linha do bloco) tem cinco células,** porque o
GFM conta as colunas pelo cabeçalho. Medição de campo, sobre 100 checkpoints de 11 repos desta máquina:
- 35 linhas `|`-led curtas, **todas** em tabelas estreitas (cabeçalho com menos de 5 células), em 4
  checkpoints: `ansible-jrc/20260924-kb-clone-upgrade-v26-09` (10) e, no `sales_quote`,
  `20260825-frete-cif-fob` (5), `20260914-destino-cif-e-coleta-fob` (7) e
  `20260915-aprovacao-sem-logistica` (13);
- 0 linhas curtas dentro de tabela de 5 colunas;
- 0 linhas curtas sem `|` inicial.

Recusar toda linha curta quebraria esses 4 checkpoints reais.

**Como (TDD):**
- **`tests/check-gates.sh`,** logo depois do bloco do pipeless (a linha do
  `mv … checkpoint.pipeless.bak`, `:514`). O fixture põe `| I2 | slice two, three cells | pending |`
  abaixo da linha `done`.
  - Piso: `fixture: a pending row with three cells sits right below the done row`.
  - `a pending row with fewer than five cells keeps the phase in EXEC` → `EXEC`. Red: `got: QA`.
  - `the row with fewer than five cells is refused by name`, pelo regex `increment I2 has no Status`.
    Red: `got: EXEC: 1 increment(s) done, suite green, handoff written`.
  - Controles, verdes antes e depois: `a narrow table below the checkpoint's is no increment` → `QA`,
    e `prose glued to the table that quotes a pipe is no increment` → `QA`.
- **`selftest()` de `tests/check-checkpoint.sh`:**
  - `probe 'a row with fewer than five cells is caught, not skipped' 1 'row I2 has fewer than five cells'`.
    Red: `SENSOR-BROKEN: … wanted rc 1, got 0`.
  - o controle `probe 'a narrow table below the checkpoint is no row of it' 0 'narrow.md: 1 row(s)'`;
  - `pass 'rule: a row with fewer than five cells is refused by name, a narrow table is not'`, guardado
    por `short_f0`;
  - no grupo do `--red`,
    `probe 'a pending row with fewer than five cells is refused by --red, never skipped' 1 'row I2 has fewer than five cells'`.
    Red: `wanted rc 1, got 0`;
  - o `PROBE_FLOOR` (`:620`) vai de 60 para 63.
- **Em `89df2e5` o sensor também fica calado:** o `--check` dá
  `ok short.md: 1 row(s), 0 under the anchor rule, none blind` com rc 0, e o `--red` dá
  `ok … 1 pending Check(s), every one red at HEAD`.

**Conserto:**
- **`checkpoint_rows`:** a flag `bare` (`{ bare = (tbl && /\|/ && !/^[ \t]*\|/) } bare { $0 = "|" $0 }`)
  e `first = !tbl`. Depois do rejoin, `if (first) wide = (n >= 6)` e
  `if (n < 6) { if (!wide || bare) next; for (i = n + 1; i <= 6; i++) f[i] = "" }`.
- **`gate_EXEC`** (`:1305`): braço novo `'')` antes do `*)` (`:1359`), com `GATE_EXEC_CELL=1` e
  `GATE_WHY="increment $id has no Status — an empty cell, or a row with fewer than five cells (GFM renders the missing ones empty): write all five, ID | Title | Check | Status | Commit"`.
  - Antes saía `invalid status ''`, um status que ninguém escreveu.
  - Com `GATE_EXEC_CELL=1`, a linha para como `no-work` antes de abrir sessão.
- **`rows_of`:** `if (!tbl) wide = (NF >= 6)` e `if (NF < 6 && (!wide || bare)) next`.
- **`scan_file`** (`:237`): ramo `if [ "$nf" -lt 6 ]` com
  `fail "$label: row $id has fewer than five cells — GFM renders the missing ones empty, so the runner reads no Status in it; write all five"`.
- **`red_one`** (`:556`): ramo `-lt 6` com
  `fail "$label: row $id has fewer than five cells — --red refuses the row a reader of six fields would skip; run --check first"`.

⚠️ **A linha curta SEM `|` inicial continua fora, nos dois leitores.** O `build_tree` do fixture cola
o `pipe_banner` (prosa com `|` dentro de code span) sem linha em branco abaixo da tabela, e ler essa
linha derrubou `a full clean tree passes`.
- Limite declarado nos comentários: `I2 | slice | pending` colado à tabela ainda some.
- Fica dentro da direção literal do item ("linha `|`-led"), e há 0 casos reais medidos.

⚠️ **Apóstrofo em comentário dentro do programa `awk` quebra o bash:** `a table's` fecha a aspa
simples e dá `erro de sintaxe … wide`.

**Efeito colateral, sem probe:** `| I2 | t | chk | pending` (quatro células, sem `|` final) antes
sumia. Agora é lida como `pending`, que é o que o GFM renderiza.

**Mutantes** (depois de `mut_EXEC_pipeless_reads_past_the_table` em `:520`; no `CATALOG`, depois de
`:5712`):
- `EXEC_short_row_skipped`:
  `sed -i '/^checkpoint_rows()/,/^}/ s@if (n < 6) { if (!wide || bare) next; @if (n < 6) { next; @' "$1"`.
- `EXEC_short_row_reads_narrow_table`:
  `sed -i '/^checkpoint_rows()/,/^}/ s@if (first) wide = (n >= 6)@if (first) wide = 1@' "$1"`.
- `EXEC_short_row_reads_glued_prose`:
  `sed -i '/^checkpoint_rows()/,/^}/ s@if (!wide || bare) next;@if (!wide) next;@' "$1"`.
- `GATE_EXEC_empty_status_unnamed`:
  `sed -i "/^gate_EXEC() {/,/^}/ s@^      '') GATE_EXEC_CELL=1\$@      __never__) GATE_EXEC_CELL=1@" "$1"`.

Vizinhos a re-provar:
- contra `check-gates.sh`:
  - `EXEC_escaped_pipe_blind`, `EXEC_rows_blind_to_review_increments`, `EXEC_alignment_colon_blind`;
  - `GATE_EXEC_backtick_kept`, `EXEC_checkpoint_split_collapses`, `GATE_EXEC_not_a_sha_silent`,
    `EXEC_orphan_commit`;
  - `EXEC_pipeless_row_skipped` e `EXEC_pipeless_reads_past_the_table`, re-provados sobre o código
    final, porque a linha do pipe que eles sabotam virou `bare { … }`;
- contra `check-autonomy.sh`: `EXEC_cell_marker_never_armed`.

**Passada de sabotagem do sensor** (o catálogo não alcança o `check-checkpoint.sh`). Todas ficaram
vermelhas no protótipo:
| Sabotagem | rc |
|---|---|
| `rows_of` volta a pular a linha curta | 90 |
| `wide = 1` | 90 |
| ler a linha curta sem `|` inicial | 90 |
| ramo `-lt 6` do `scan_file` desligado | 91 |
| o mesmo ramo sem o `V_COLS++` | 90 |
| ramo do `red_one` desligado | 91 |
| o mesmo ramo sem o `bad++` | 90 |
| um probe apagado | 92 |

**Check:**
`` `o=$(bash tests/check-checkpoint.sh --selftest 2>&1; bash tests/check-gates.sh 2>&1); grep -c -e '^  ok    rule: a row with fewer than five cells is refused by name' -e '^  ok    the row with fewer than five cells is refused by name' <<< "$o"` → `2` ``.
Medido: 0 antes, 2 depois.

**Sensor durável:** os probes de `check-gates.sh` e do `selftest()`, e os quatro mutantes.

**No mesmo commit:** nada em `CLAUDE.md`, `docs/pipeline.md`, `config/schema.md`, agentes ou anatomia.
O `c71913c`, do mesmo desenho, não tocou nenhum deles.

**Reversível por:** reverter o commit.

### I3 — #223: o `red_norm` guarda o array vazio, como o resto do kit

**O quê:** `printf '%s' ${w[@]+"${w[*]}"}` no `red_norm` (`tests/check-checkpoint.sh:533`, o `printf`
em `:537`), com um comentário de 2 linhas que cita a #223 e o idioma do `check-todo.sh` (o comentário
perto de `tests/check-todo.sh:2160`). Vem junto uma asserção no `selftest()` que lê
`declare -f red_norm` (decisão 7).

**O protótipo refutou em parte a premissa do item: o sensor não aborta, o veredito sobrevive.** O
`--red` real rodou dentro do container. As imagens `bash:4.x` são alpine 3.22 com busybox; o git falta,
mas `apk add git` resolve. A fixture tem o Check mudo `` `true` → `1` ``:

| bash | stderr a mais | veredito | rc |
|---|---|---|---|
| 4.0 | `/kit/tests/check-checkpoint.sh: line 537: w[*]: unbound variable` | `FAIL … I1 printed nothing (rc 0)` | 1 |
| 4.3 | a mesma `unbound variable` | o mesmo `FAIL` | 1 |
| 4.4 | nenhum | o mesmo `FAIL` | 1 |

Por que o veredito sobrevive:
- o `red_norm` só é chamado dentro de `$(…)`;
- o erro mata o subshell, mas o pai segue, porque não roda com `-e`;
- o `got` vazio cai justamente no ramo "printed nothing".

O defeito real é ruído no stderr, mais um risco latente: uma futura chamada fora de substituição de
comando abortaria o sensor. A decisão 7 continua de pé, porque o conserto é barato e fecha o risco.
O `RESOLVED by` do item, no I11, diz o que foi medido. O título do item não muda: é a chave da issue.

**Como (TDD):** a asserção entra no `selftest()`, depois da linha
`rule: a Check already green at HEAD is refused by --red`. Fica fora daquele grupo, para não mudar o
"(N probe(s))" dele.
- Verde: `pass 'red_norm guards its empty array, which bash 4.0-4.3 call unbound under set -u'`.
- Red, rc 90:
  `SENSOR-BROKEN: red_norm expands its array unguarded — bash 4.0-4.3 call an empty one unbound under set -u`.
- O `PROBE_FLOOR` vai de 63 para 64.

**Prova efêmera (decisão 7):** rode da raiz do worktree, antes e depois do conserto, e anote o
resultado na nota do incremento. Medido: `1` antes, `0` depois. Precisa de rede para o `apk add`.
```
docker run --rm -v "$PWD":/kit:ro bash:4.3 sh -c 'apk add --no-cache git >/dev/null 2>&1; mkdir -p /tmp/r/docs/handoffs/m && cd /tmp/r && git init -q . && printf "| ID | Incremento | Check (comando → esperado) | Status | Commit |\n|---|---|---|---|---|\n| I1 | slice | \`true\` → \`1\` | pending | — |\n" > docs/handoffs/m/checkpoint.md && bash /kit/tests/check-checkpoint.sh --red docs/handoffs/m/checkpoint.md 2>&1 | grep -c "unbound variable"'
```

**Mutante:** nenhum. O catálogo só sabota `bin/`, e o `run-all.sh` deixa este sensor fora sob
`SDD_MUTANT`. Quem cobre é a asserção mais a sabotagem: tirar a guarda dá rc 90.

**Check:**
`` `o=$(bash tests/check-checkpoint.sh --selftest 2>&1); grep -c '^  ok    red_norm guards its empty array' <<< "$o"` → `1` ``.
Medido: 0 antes, 1 depois.

**Sensor durável:** a asserção do `selftest()`.

**No mesmo commit:** nada além do sensor. O `tested_paths`, o outro `read -ra` do arquivo, não é
afetado: usa `${#w[@]}`, que o 4.3 aceita com o array vazio (medido).

**Reversível por:** reverter o commit.

### I4 — #232: `Closable by: deferred` só vale com a decisão escrita no corpo do bug

**O quê:** a âncora 3 do `gate_QA` passa a conferir o que a ADR 0009 § Decision e o
`agents/sdd-qa.md` §5.1 já exigem. Um bug `deferred` só conta como `deferred` se o corpo tiver uma
seção de decisão **fora de cerca de código**. Sem ela, o bug conta como `agent`: soma em `openbugs`
e bloqueia, e o motivo diz por quê.

**Onde:**
- `bin/sdd`:
  - função nova `bug_decision_recorded <arquivo>`, logo antes de `gate_QA` (`:1462`);
  - o braço `deferred` do laço da âncora 3, onde está o `grep … deferred` (`:1618`);
  - o `GATE_WHY` de bloqueio (`:1639`).
- `tests/check-gates.sh`: `write_genre_bug` (`:748`) e o bloco `deferred` (`:979-1060`).
- `tests/check-mutation.sh`: os mutantes `QA_bug_genre_deferred_*` (`:949-972`).

**Como (TDD):**
1. **A fixture muda primeiro, e é ela que revela o defeito.** O `write_genre_bug` ganha um 2º
   argumento opcional, o corpo, e nasce a constante
   `GENRE_DECIDED=$'\n## Decision\n\n2026-01-02, the repo owner: mission 20260201-other pays for this fix.'`.
   - Hoje a fixture escreve `deferred` **sem** seção de decisão, e a asserção existente "deferred
     passes and the reason names the bug" passa assim: ela codifica o defeito.
   - Passam a carregar `GENRE_DECIDED` todos os fixtures `deferred` que já existem: o diferencial
     `deferred`×`human`, o N>1 (`BUG-…-genre-two`), o `NOIF_BUG` e os três quase-acertos
     (`deferredly`, cercado, acima).
   - ⚠️ **Medido:** sem a decisão no mundo `deferredly`, o conserto **cega** o
     `QA_bug_genre_deferred_prefix` (o `--only` deu NOT caught). O ramo `deferred` sem decisão
     bloqueia por conta própria.
2. **Quatro mundos novos,** logo depois de "a 'deferred' quote ABOVE…":
   - **W1, diferencial com e sem a seção:**
     `deferred with no '## Decision' section counts as agent: it blocks, and the reason names it` →
     `REVIEW|QA|named:1`. O termo `named` conta
     `with no '## Decision' section in the body count as agent: BUG-20260102-genre` no `sdd why`.
     Red medido: `got: REVIEW|REVIEW|named:0`.
   - **W2, o til:**
     `the pt-BR decision headings count: the tilde spelling with a date, and '## Decisao', both pass`
     → `REVIEW|REVIEW`. O acento vai em octal (`printf '## Decis\303\243o \342\200\224 2026-08-26'`),
     porque o `check-lang` reprova acento em `tests/`. É controle: já passa antes.
   - **W3, seção dentro de cerca não conta:**
     `a '## Decision' heading inside a fence is not the decision: the bug blocks` → `REVIEW|QA`.
     Red: `REVIEW|REVIEW`.
   - **W4, o plural:**
     `a '## Decisions for a Human' heading is a pending question, not the decision: the bug blocks` →
     `REVIEW|QA`. Red: `REVIEW|REVIEW`. É a decisão de desenho aceita pelo humano: esse título é
     pergunta pendente, e nenhum bug dos alvos o usa (0 ocorrências medidas).

**Conserto:**
```bash
bug_decision_recorded() {
  awk '
    /^[[:space:]]*(```|~~~)/ { infence = !infence; next }
    infence { next }
    /^## Decis/ && !/^## Decisions/ { found = 1; exit }
    END { exit !found }
  ' "$1"
}
```
- **O prefixo ASCII `## Decis`** casa `## Decision`, `## Decisao`, `## Decisão`, `## Decisão — data`,
  `## Decisão (…)` e `## Decisão humana — data`. O `mawk` é byte-oriented, então o casamento é pelo
  prefixo, como o `## Notas de execu` do `checkpoint_note_intervention`.
- **A variável se chama `infence`, e não `fenced`, de propósito.** O `mut_QA_bug_genre_fenced` faz
  `s|{ fenced = !fenced; next }|…|` **sem faixa de função** e sabotaria os dois leitores ao mesmo
  tempo.
- **No braço `deferred`,** antes de `deferred=$((deferred + 1))`, entra
  `if ! bug_decision_recorded "$bugfile"; then` com `openbugs+1`, `undecided+1`, o nome acrescentado a
  `undecided_names` e `continue`. As linhas do `grep … deferred` e do `deferred_names` ficam byte a
  byte iguais, porque são âncoras de mutantes.
- **O `GATE_WHY` de bloqueio ganha o sufixo**
  `; $undecided of them marked 'Closable by: deferred' with no '## Decision' section in the body count as agent: $undecided_names`.
  O trecho `with Status: open in the registry` fica intacto, porque duas asserções o leem.
- **Dono do artefato** (princípio 1 do `CLAUDE.md`): a seção é escrita pelo humano, ou pela sessão
  que registra a decisão dele. Sem ela, o bug é `agent` e o laço F<n> o fecha. O gate continua
  satisfazível.

**Mutantes** (depois de `QA_bug_genre_deferred_join`, mais o `CATALOG`). Na faixa
`/^gate_QA() {/,/^}/`:
- `QA_bug_deferred_undecided` → `s|^      if ! bug_decision_recorded "\$bugfile"; then$|      if false; then|`.
  Morre no W1.
- `QA_bug_deferred_undecided_unnamed` → `s|^    if \[ "\$undecided" -gt 0 \]; then$|    if false; then|`.
  Morre pelo `named` do W1.

Na faixa `/^bug_decision_recorded() {/,/^}/`:
- `QA_bug_deferred_decision_fenced` → `s|{ infence = !infence; next }|{ next }|`. Morre no W3.
- `QA_bug_deferred_decision_plural` → `s|/^## Decis/ \&\& !/^## Decisions/|/^## Decis/|`. Morre no W4.
- `QA_bug_deferred_decision_english_only` → `s|/^## Decis/ \&\& |/^## Decision/ \&\& |`. Morre no W2.

Vizinhos re-provados com `--only … check-gates.sh`, todos pegos no protótipo:
- `QA_bug_genre_prefix`, `_deferred_prefix` (depois do conserto do fixture) e `_deferred_blocks`;
- `_deferred_join`, `_deferred_unseen_no_interface` e `_fenced`;
- `_ignored`, `_anywhere`, `_outside_header` e `_header_unbounded`.

**Check:** `` `o=$(bash tests/check-gates.sh 2>&1); grep -c '^  ok    .*## Decision' <<< "$o"` → `3` ``.
Medido: 0 antes e 3 depois. Casam o W1, o W3 e o W4; o W2 não tem o texto.

**Sensor durável:** os quatro mundos em `check-gates.sh` e os cinco mutantes.

**No mesmo commit:**
- **`agents/sdd-qa.md` §5.1, bullet `deferred` (`:133-138`):** o gate lê a seção (prefixo `## Decis…`
  fora de cerca; `## Decisions for a Human` não conta), e sem ela o bug bloqueia e é nomeado. Depois,
  `./bin/sdd install --force` e `./bin/sdd preflight`.
- **`docs/pipeline.md`:** o bullet da âncora 3 (`:289-297`) e o parágrafo do `deferred` (`:313-331`).
- **`CONTEXT.md`:** o verbete "Gênero do bug" (`:41`).
- **O `sdd install` NÃO passa a semear cabeçalho de decisão no template de bug.** Hoje 0 de 11
  `docs/qa/templates/bug.md` locais o têm. Se passasse, todo bug nasceria "decidido": fail-open por
  construção.

**Fora:** `config/schema.md` e ADR (a 0009 já decidiu). Nenhum bug `deferred` aberto dos alvos fica sem
a seção: medido em `sales_quote` (17 títulos), em `lighthouse_project` (`## Decisao`, o único
`deferred` aberto) e em `estimates-os_mcp`. Não há migração.

**Reversível por:** reverter o commit.

### I5 — #225: o relatório da ponta da base exige um checkpoint que a missão já teve (ADR 0016 §1)

**O quê:** em `tip_add_carries_mission` (`bin/sdd:933`), depois da regra da ADR 0015 §3 (o commit que
adicionou o relatório move `checkpoint.md` ou `checkpoint-notas.md` da missão), entra a regra nova.
Todo arquivo de progresso que esse commit (`$add`) moveu tem de ficar como um blob que algum commit
**da missão** (`rev-list HEAD --not <mission_base_refs>`) escreveu no mesmo caminho. Se não ficar, o
relatório "is not one this branch added".

**Onde:**
- `bin/sdd`: `mission_base_refs` (`:896`), `tip_add_carries_mission` (`:933`, chamado de dentro de
  `mission_qa_report` em `:1052`) e `mission_qa_report` (`:1002`, chamado em `:1511` e `:2535`, dentro
  do `gate_QA` e do `qa_substep`).
- `tests/check-gates.sh`: os mundos novos entram depois do (i) (`:1341`; o (h) está em `:1287`).
- `tests/check-mutation.sh`: os mutantes `tip` (`:854-867`).

**Como (TDD):** três mundos.
- **(j) o intruso.** Na `main`, um commit de outra missão adiciona o relatório dela, mexe no próprio
  dir e acrescenta uma linha ao `checkpoint.md` **desta** missão. A missão traz o relatório com
  `git checkout main -- <relatório>`.
  - Piso: `the intruder commit adds its report and moves this mission's checkpoint.md` →
    `checkpoint.md `.
  - Asserção:
    `qa_refused "another mission's report whose squash also edited this mission's checkpoint is not the mission's"`.
  - Red medido: `expected: QA|1  got: REVIEW|0`.
- **(k) controle.** O squash da própria missão, lido depois de a branch mover o checkpoint de novo
  com uma nota pós-merge:
  `the mission's own squash still counts after the branch moved its checkpoint again` → `REVIEW`.
- **(l) o restaurador.** Outra missão devolve o checkpoint ao blob de antes do fork. São **dois**
  commits na `main`, porque para um commit da base **mover** o checkpoint de volta ao blob do fork,
  outro antes dele tem de tê-lo mudado:
  1. `printf '<!-- edited by another mission -->\n' >> "$MDIR/checkpoint.md"`, depois `git add -A` e
     o commit "another mission edits this mission's checkpoint";
  2. `git checkout "$(git merge-base main missao/qa-report-owner)" -- "docs/handoffs/$MISSION/checkpoint.md"`,
     mais um relatório novo (`2026-01-18-fixture-restorer.md`, no molde dos outros fixtures de
     relatório), `git add -A` e o commit "another mission (squash) that writes this checkpoint back
     to the fork's version".

  Depois, a branch da missão traz o relatório com `git checkout main -- <relatório>`.
  - Piso: `fork-blob/checkpoint.md `. É a palavra `fork-blob/` quando
    `git rev-parse "HEAD:docs/handoffs/$MISSION/checkpoint.md"` é igual ao mesmo caminho no
    merge-base, seguida dos nomes que `git diff-tree --no-commit-id -r --name-only HEAD --
    "docs/handoffs/$MISSION/"` imprime, sem o prefixo do diretório.
  - Asserção:
    `qa_refused "a checkpoint blob from before the fork does not vouch for another mission's report"`.
  - Também é Red antes.

Seguem verdes o (h) ("a report from the base tip counts only when the commit that added it carries
this mission dir") e os mundos (b′)/(c′) de `8a8d85d`/`b9ef201`.

O merge commit nunca alcança este caminho. Com HEAD igual à ponta, o range é vazio e cai no fallback;
com HEAD à frente, o merge-base já contém o relatório.

**Conserto:** dentro de `tip_add_carries_mission`.
- Os `local` do topo da função passam a ser
  `local path="$1" c add meta p blob ranged=""`, mais
  `local cp="$HANDOFF_DIR/$MISSION/checkpoint.md" cn="$HANDOFF_DIR/$MISSION/checkpoint-notas.md"` e
  `local -A mine=()`. Isso vem antes do `shift`, e todos são `local` por causa do `set -u`.
- ⚠️ **Nunca repita o par literal nas linhas novas.** Os mutantes `QA_report_tip_any_mission` e
  `QA_report_tip_any_file_of_mission` reescrevem o par literal da linha da regra 0015 §3 **dentro da
  mesma faixa** `/^tip_add_carries_mission() {/,/^}/`. Uma segunda cópia literal nas linhas novas seria
  alargada junto, e os dois ficariam cegos. Medido: com o literal, NOT caught.
- **Onde mora:** dentro do `for c in "$@"` da função, **depois** da linha da regra 0015 §3 (o
  `[ -n "$(git … diff-tree … "$add" -- …checkpoint.md …checkpoint-notas.md)" ] || return 1`). O
  `"$@"` ali são os base refs, que sobram depois do `shift`.
- **Conjunto de blobs da missão,** lido uma vez e sob demanda, com a guarda `if [ -z "$ranged" ]; then
  ranged=1; … fi` em volta do laço abaixo. Só paga quem tem relatório na ponta:
  ```bash
  while IFS=$'\t' read -r meta p; do
    meta="${meta% *}"; blob="${meta##* }"
    if [ -n "$p" ]; then mine["$blob $p"]=1; fi
  done < <(git -C "$REPO_ROOT" rev-list HEAD --not "$@" -- "$cp" "$cn" 2>/dev/null \
             | git -C "$REPO_ROOT" diff-tree --stdin --root --no-commit-id -r --raw -- "$cp" "$cn" 2>/dev/null || true)
  ```
  O blob sai sem offset fixo, então funciona também com sha256.
- **Por ponta que tem o caminho:**
  ```bash
  while IFS=$'\t' read -r meta p; do
    [ -n "$p" ] || continue
    meta="${meta% *}"; blob="${meta##* }"
    [ -n "${mine["$blob $p"]+x}" ] || return 1
  done < <(git -C "$REPO_ROOT" diff-tree --root --no-commit-id -r --raw "$add" -- "$cp" "$cn" 2>/dev/null || true)
  ```
- **Comentários:** o "DECLARED, fail open" nos cabeçalhos de `tip_add_carries_mission` e de
  `mission_qa_report` vira o resíduo novo.
  - **Falha aberto** quando outra missão escreve este checkpoint byte a byte igual a uma versão que a
    branch commitou.
  - **Falha fechado** quando o blob do squash veio de um merge commit da branch (resolução de conflito)
    ou de uma edição na forja nunca buscada. Essa parada é visível e nomeia o arquivo.

**Custo medido** (fixture mínima, 1 base ref): missão em voo, 10 → 10 processos `git`; missão
squash-mergeada lida da branch, 13 → 16 processos, cerca de +5 ms por `mission_qa_report`.

**Mutantes** (depois de `QA_report_tip_refused_outright`, na faixa `/^tip_add_carries_mission() {/,/^}/`):
- `QA_report_tip_blob_unchecked` → `s@\[ -n "\${mine\["\$blob \$p"\]+x}" \] || return 1@:@`. Morre no (j).
- `QA_report_tip_blob_newest_only` → `s|rev-list HEAD --not "\$@" --|rev-list -n 1 HEAD --not "$@" --|`.
  Morre no (k).
- `QA_report_tip_blob_whole_history` → `s|rev-list HEAD --not "\$@" --|rev-list HEAD --|`. Morre no (l).

⚠️ Nos dois últimos, o delimitador é `|` e nunca `@`, porque o texto casado contém `"$@"`. A 1ª versão
deu `CATALOGUE-BROKEN rc 90`.

Vizinhos: os 30 `QA_report_*` existentes, re-provados com `--only … check-gates.sh`. Todos foram
pegos no protótipo. A lista sai de `grep -oE '^mut_QA_report_[A-Za-z0-9_]+' tests/check-mutation.sh`.
- **Obrigatórios,** porque a faixa é a mesma: os 3 `QA_report_tip_*` (`tip_any_mission`,
  `tip_any_file_of_mission` e `tip_refused_outright`), mais `log_base_blind` e `tree_base_blind`, que
  o `52de46e` cegou e o `b9ef201` consertou.
- **Os outros 25, se houver tempo.** Cada `--only … check-gates.sh` custa cerca de uma rodada do
  `check-gates.sh` (cerca de 90 s ocioso), então os 30 em série passam de 40 min. O carimbo do `sdd
  health` cobre o catálogo inteiro de qualquer forma.

**Check:**
`` `o=$(bash tests/check-gates.sh 2>&1); grep -c '^  ok    another mission.s report whose squash also edited this mission.s checkpoint is not' <<< "$o"` → `1` ``.
Mede 0 antes e 1 depois. O `.` no lugar do apóstrofo deixa a célula sem aspa aninhada.

**Sensor durável:** os mundos (j), (k) e (l) e os três mutantes.

**No mesmo commit:**
- **A ADR 0016 §1** já traz, desde o planejamento, os números do protótipo (o Red do (j), os controles,
  o custo e a premissa medida no `sales_quote`). Confira se o conserto que pousou bate com o texto da
  Decision (os commits da missão são `rev-list HEAD --not <mission_base_refs>`) e ajuste o número que
  mudar, nunca a decisão.
- **`docs/pipeline.md:271-272`:** ainda diz "Declared residue (`TODO.md`): a report another mission
  added upstream … counts", desatualizado desde o lote 4. Reescreva com o resíduo novo.
- **`CONTEXT.md:48`,** verbete "Relatório da missão": tem o mesmo "Resíduo no TODO.md".
- **Anatomia §4, "Dívida declarada":** a linha das Âncoras 1/2 passa a citar a 0015 §3 e a 0016 §1.

**Reversível por:** reverter o commit; a ADR 0016 §1 volta a descrever um plano.

### I6 — #233: a guarda do kit vê o kit já sujo editado de novo, e o BLOCKED diz o que mudou

**O quê:** o carimbo da guarda é `sha|dirty`, então com o kit já sujo uma edição durante a fase
passa calada (dirty→dirty no mesmo sha). A guarda passa a comparar também a **árvore suja por caminho
e conteúdo**, e o motivo do `kit-touched` passa a dizer o que mudou: commits e caminhos.

**Onde:**
- `bin/sdd`:
  - `autonomy_kit_stamp` (`:3738`), `KIT_GUARD_BEFORE=` (`:3805`) e `kit_guard_arm` (`:3812`);
  - `kit_guard_check` (`:3836`), com a frase do `KIT_TOUCHED_WHY` em `:3864`;
  - `hat_status_lines` (`:4074`);
  - `hat_crossed_escalation` (`:4160`), que imprime `BLOCKED in $phase — $why` sem corte, enquanto o
    ledger corta o `gate_why` em 200.
- As 4 portas não mudam: `cmd_run` (`:8523/:8527` e `:8671`), `cmd_retry` (`:8906/:8910`) e
  `cmd_close` (`:11294/:11359`).
- `tests/check-autonomy.sh`: o bloco kit-guard (regimes 1–7).

**Como (TDD):**
- **Reprodução do relay:** kit limpo + `??` → rc 3; controle → rc 0; kit sujo + outra escrita → rc 0
  e 0 linhas.
- **O protótipo acrescentou** o mesmo `??` editado de novo e o mesmo ` M TODO.md` editado de novo. Os
  dois davam rc 0 e 0 linhas.
- **Regime 1b,** depois da asserção do regime 1:
  `kit-guard: the BLOCKED line names the commit the kit gained during the phase`.
  - Lê o stderr, porque o ledger corta em 200.
  - Red: `expected: 1 got: 0`.
- **Regime 2b,** depois do controle:
  `kit-guard: a kit already dirty and edited again stops the line and names the path, and left alone it is silent`.
  - É diferencial. O mesmo kit pré-sujo (`TODO.md` já ` M`) roda duas sessões: uma reedita o MESMO
    arquivo, a outra é benigna.
  - A testemunha `same:1` prova que os dois carimbos `sha|dirty` são iguais.
  - O controle benigno também termina em rc 3, mas por `no-progress`; por isso a asserção lê o `kind`.
  - Red:
    `expected: sessions:1 lines:1 rc:3 kind:kit-touched same:1 named:1|sessions:2 lines:0 rc:3 kind:no-progress same:0 named:0`,
    `got: sessions:2 lines:0 rc:3 kind:no-progress same:0 named:0|<igual>`.

**Conserto:**
- **`hat_status_lines [root]`** passa a aceitar a raiz (default `REPO_ROOT`). É um parser só para os
  dois guardas.
- **Novo `kit_guard_tree`,** que publica `KIT_GUARD_TREE`: uma linha `XY path<TAB>md5` por caminho sujo
  do `SDD_HOME`.
  - Um `md5sum` só (`xargs -0`).
  - O `awk` usa `ENVIRON`, `index` e `substr`, por causa do `mawk`.
  - Caminho sem arquivo regular vira `-`.
  - Num kit que não é checkout git, a árvore fica vazia e a guarda segue calada.
  - Leitura com `GIT_OPTIONAL_LOCKS=0`.
- **Novo `kit_guard_changes`,** que publica `KIT_GUARD_CHANGES`: caminhos novos, `(content changed)` e
  `(no longer dirty)`.
- **`kit_guard_arm`** guarda também `KIT_GUARD_TREE_BEFORE`.
- **`kit_guard_check`** faz
  `[ "$tree_after" = "$KIT_GUARD_TREE_BEFORE" ] && [ "$kit_after" = "$KIT_GUARD_BEFORE" ] && return 0`.
  - A árvore vem **primeiro** de propósito: a âncora do `mut_RUN_kit_touched_blind` continua sendo
    sufixo da linha.
  - O motivo ganha
    `— what changed: commits: <git log --format='%h %s' --max-count=5 before..after>; paths: …`, com a
    captura guardada (`|| commits=""`).
  - O acréscimo fica numa linha própria, depois da frase:
    `KIT_TOUCHED_WHY="${KIT_TOUCHED_WHY:+$KIT_TOUCHED_WHY${what:+ — what changed: $what}}"`. Assim
    ficam intactas as âncoras de `kit_touched_silent` (`^  KIT_TOUCHED_WHY="the kit at `) e de
    `accuses_session` (`parallel"$`).
  - O re-arm também atualiza a árvore.
  - A linha `KIT-TOUCHED` do journal fica como está.
- **Nenhum global é lido por `$( )`.**
- **Limites declarados no comentário:** um arquivo grande e não ignorado é lido duas vezes por fase;
  um nome com `\` ou quebra de linha fica sem digest.
- **Rejeitado:** `git stash create`, porque escreve objetos no repo do kit.
- **Custo medido:** 3 ms por amostra com o kit limpo e 31 ms com 61 entradas sujas. É o mesmo que o
  `autonomy_kit_stamp` já paga (6 ms e 31 ms), duas amostras por sessão.
- **Trade-off aceito pelo humano:** quem mantém o kit sujo e salva um arquivo durante a fase de um
  alvo passa a parar a linha.

**Mutantes** (depois de `mut_RUN_kit_guard_arms_projection`, mais o `CATALOG`; todos morrem em
`check-autonomy.sh`):
- `RUN_kit_guard_tree_blind`:
  `sed -i '/^kit_guard_check() {/,/^}/ s|^  \[ "$tree_after" = "$KIT_GUARD_TREE_BEFORE" \] \&\& |  [ true ] \&\& |'`.
- `RUN_kit_guard_tree_no_content`:
  `sed -i '/^kit_guard_tree() {/,/^}/ s|print $0 "\\t" ((p in h) ? h\[p\] : "-")|print $0 "\\t-"|'`.
- `RUN_kit_guard_tree_unarmed`, na faixa de `kit_guard_arm`:
  `s|^  KIT_GUARD_TREE_BEFORE="$KIT_GUARD_TREE"$|  KIT_GUARD_TREE_BEFORE=""|`.
- `RUN_kit_touched_says_nothing_changed`, na faixa de `kit_guard_check`:
  `{ /^  KIT_TOUCHED_WHY="${KIT_TOUCHED_WHY:+/d; }`.

O re-arm da árvore fica sem mutante, declarado: depois da parada, nenhuma segunda checagem é
alcançável.

Vizinhos re-provados no protótipo, todos `dies (rc 1)`:
- contra `check-autonomy.sh`: `RUN_kit_touched_silent`, `RUN_kit_touched_accuses_session`,
  `RUN_kit_touched_remedy_generic`, `RUN_kit_touched_blind`, `RUN_kit_guard_cries_wolf`,
  `RUN_close_unguarded`, `RUN_kit_guard_arms_projection`, `RUN_kit_guard_reads_rev` e
  `RUN_hat_status_not_nul`;
- contra `check-gates.sh`: `RUN_hat_guard_ignores_prior_dirt`.

**Check:**
`` `o=$(bash tests/check-autonomy.sh 2>&1); grep -c -e '^  ok    kit-guard: a kit already dirty and edited again' -e '^  ok    kit-guard: the BLOCKED line names the commit' <<< "$o"` → `2` ``.
Mede 0 antes e 2 depois.

**Sensor durável:** os regimes 1b e 2b e os quatro mutantes.

**No mesmo commit:**
- **`docs/pipeline.md`:**
  - em `## The kit guard` (`:746-748`), diga que a guarda amostra a árvore por caminho e conteúdo, e
    que o motivo traz o "what changed";
  - na tabela de campos, a linha `kit_sha` (`:1211`, "compares, together with kit_dirty").
- **Anatomia §6:** a frase de `kit_guard_arm`/`kit_guard_check`.

**Reversível por:** reverter o commit.

### I7 — #228 + #227 (+ decisão 11a): a parada no carimbo dá o remédio que funciona, e a nota `intervention:` só existe com sessão

São três commits, nesta ordem: **#228, #227, resíduos (11a)**.
- O #228 cria o `stale_stop_out` logo depois da 1ª asserção do mundo 4b do `check-gates.sh`. O probe
  do #227 vem depois dele e reatribui `stamp_out`.
- O #227 e o #228 tocam o `cmd_run` em trechos disjuntos: `:8198`, o topo do laço e `:8502`, contra
  `:8293`.
- A re-âncora de `RUN_intervention_unwritten_on_phase` vai no commit do #227.

#### Commit 1 — #228: a parada no carimbo distingue o carimbo impossível

**O quê:** quando a única recusa do `gate_PR` é o carimbo, o `cmd_run` (bloco `if [ "$phase" = "PR" ]`,
`:8293`) imprime a ordem "wait for every review bot … run './bin/sdd health' once". Quando o carimbo
é **impossível**, essa ordem engana: nenhum `sdd health` carimba aquela árvore. É o ramo `[ -z "$key" ]`
mais `mutation_stamp_why` do `gate_PR` (`:2403`).
- O marcador novo `GATE_PR_STAMP_IMPOSSIBLE` é zerado na entrada do `gate_PR`, como o
  `GATE_PR_STAMP_WHY` (`:2319`). Recebe `$MUTATION_STAMP_WHY_KIND` naquele ramo.
- No `cmd_run`, as duas linhas `dim` da ordem viram um `if`. A frase de antes ("The PR is open and
  every other requirement of its gate is met. No session can write") fica igual, e o bloco é:
  ```bash
          if [ -n "$GATE_PR_STAMP_IMPOSSIBLE" ]; then
            dim "  the stamp, and no './bin/sdd health' can stamp this tree as it stands ($GATE_PR_STAMP_IMPOSSIBLE):"
            dim "  fix what the reason above names first, then run './bin/sdd health' once, then"
            dim "  'sdd run $MISSION' again."
          else
            dim "  the stamp. The order: wait for every review bot on the PR, fix their findings in one"
            dim "  batch, run './bin/sdd health' once, then 'sdd run $MISSION' again."
          fi
  ```
  Ponha acima dele um comentário dizendo que os dois remédios saem do marcador, nunca da frase.
- Os kinds alcançáveis pelo `cmd_run` são `missing`, `deleted`, `untracked` e `unreadable`. O
  `not-git` não é alcançável, porque o `REPO_ROOT` já é um repo git.

**Como (TDD):** o mundo 4b do `check-gates.sh` (`stamp_out`, perto de `:2902`) guarda
`stale_stop_out="$stamp_out"` logo depois da 1ª asserção. Depois, no mundo 9, o PARTIAL ROOT (perto de
`check-gates.sh:2981`, onde falta `config/`), um bloco novo roda o `sdd run` e compara as duas saídas.
⚠️ Já existe um "9b." em `:5501`, noutra seção, então dê ao bloco novo um rótulo que não colida. A
asserção é
`run stops at an impossible stamp with the remedy that can work, and a stale stamp keeps the review-bot order`.
O texto do mundo impossível ainda contém `run './bin/sdd health' once`. Por isso a asserção conta
"wait for every review bot" e "fix what the reason above names first", nunca a frase do health.
Red: `expected: stale:1:0|impossible:2|0|0|1  got: stale:1:0|impossible:2|0|1|0`.

**Mutantes:**
- `PR_stamp_impossible_unmarked`: `{ /^        GATE_PR_STAMP_IMPOSSIBLE="\$MUTATION_STAMP_WHY_KIND"$/d; }`
  na faixa do `gate_PR`;
- `RUN_stamp_remedy_always_impossible`: `s@if \[ -n "\$GATE_PR_STAMP_IMPOSSIBLE" \]; then@if true; then@`
  na faixa do `cmd_run`;
- vizinhos: `RUN_stamp_stop_missing` e `PR_stamp_marker_always`.

**No mesmo commit:**
- `docs/pipeline.md` (`:492`, o parágrafo "The stamp is not headless");
- `docs/failure-modes.md` (`:877-890`, o "fourth state");
- anatomia §7, na frase "o `sdd run` nomeia a ordem e o `./bin/sdd health`".

#### Commit 2 — #227: a nota do `--phase` só com sessão (decisão 6)

**O quê:**
- Em `:8198`, a nota sai, e entra `local cli_phase="$force_phase" cli_lap=""`.
- No topo do laço, depois do `config_reload`, entra `cli_lap="$cli_phase"; cli_phase=""`. É de uso
  único: a volta que o próprio runner força (o salto draft, `:8460`) já o encontra vazio.
- Logo acima de `before="$(state_fingerprint)"` (`:8502`), e portanto antes de
  `kit_guard_arm`/`hat_guard_arm`, entra este bloco, **em três linhas**. A chamada fica sozinha na
  linha, com 6 espaços, porque é a âncora do mutante:
  ```bash
      if [ -n "$cli_lap" ]; then
        checkpoint_note_intervention "sdd run --phase $cli_lap (the starting phase was forced from the CLI)" "$cli_lap"
      fi
  ```
- O retry inline é a mesma volta e não escreve outra nota.
- Ajuste o comentário L4 que hoje explica por que a nota mora antes do laço.

**Como (TDD):**
- `check-autonomy.sh`, depois de "…--dry-run writes none…":
  `sdd run --phase PLAN stops before any session and writes no note`. Red:
  `expected: rc:2 notes:2 clean got: rc:2 notes:3 clean`.
- `check-gates.sh`, mundo 4b, depois da 1ª asserção:
  `run --phase PR stops at the stamp and writes no intervention note`. Red:
  `expected: 2|0|1|+0 got: 2|0|1|+1`.
- `check-autonomy.sh`, no bloco do salto draft:
  `the draft jump is the runner's hand: its forced PR lap writes no intervention note`. Vale `+0` antes
  e depois, e existe para matar o mutante `RUN_intervention_on_runner_forced_lap`.
- A metade EXEC do par diferencial já existe e continua verde:
  `sdd run --phase writes a second note, committed alone` (`check-autonomy.sh:578`).

**Mutantes:**
- `RUN_intervention_unwritten_on_phase` ganha âncora nova:
  `sed -i '/^cmd_run() {/,/^}/ s|^      checkpoint_note_intervention "sdd run --phase $cli_lap (the starting phase was forced from the CLI)" "$cli_lap"$|      :|'`
- `RUN_intervention_before_the_stop`: devolve a nota ao topo da volta. Troca
  `^    cli_lap="$cli_phase"; cli_phase=""$` por
  `    cli_lap="$cli_phase"; cli_phase=""; [ -n "$cli_lap" ] \&\& checkpoint_note_intervention "sdd run --phase $cli_lap (the starting phase was forced from the CLI)" "$cli_lap"; cli_lap=""`.
  Morre em `check-autonomy.sh` e em `check-gates.sh`.
- `RUN_intervention_on_runner_forced_lap`: `s|^    cli_lap="$cli_phase"; cli_phase=""$|    cli_lap="$force_phase"; cli_phase=""|`.
- Vizinhos: `RUN_intervention_unwritten_on_retry` e `RUN_intervention_written_on_dry_run`.

#### Commit 3 — decisão 11a: o `sdd retry` e o `--budget-override` seguem a mesma regra

**O quê:**
- **`cmd_retry`** (`:8851`): a ordem passa a ser `no_work` → `mission_budget_blown` → a nota do
  retry → `budget_override_note_write` → `before=`.
  - Hoje a nota do retry (`:8891`) vem antes do teto (`:8893`), e um `sdd retry` parado pelo teto
    grava e commita a nota.
  - A linha da nota fica com texto e indentação idênticos, para o mutante antigo continuar ancorando.
- **`--budget-override`:**
  - O `mission_budget_blown` (`:5193`, nota em `:5209`) deixa de escrever. Ele **publica**
    `BUDGET_OVERRIDE_NOTE="sdd $AUTONOMY_INVOCATION --budget-override (US\$ … )"`.
  - O global novo, `BUDGET_OVERRIDE_NOTE=""`, fica ao lado de `BUDGET_OVERRIDE_NOTED=0` (`:3112`). Tem
    um setter só, atrás do one-shot, e um consumidor só, que o zera.
  - ⚠️ **De propósito, ele NÃO é zerado na entrada do setter**, ao contrário dos outros marcadores do
    arquivo. A volta PR do salto draft chama o `mission_budget_blown` de novo antes da sessão, e um
    reset ali perderia a nota. O mundo NW6D prova isso, e o mutante `reset_on_entry` morre nele.
    Escreva isso no comentário do global.
  - O `warn` ao humano continua **imediato**. Ele diz um fato que acabou de acontecer, o teto cruzado
    e levantado. Quem o `sdd autonomy` conta é a nota, e ela espera a sessão.
  - O one-shot continua por processo: uma nota por `sdd run`.
- **Writer novo `budget_override_note_write <fase>`:** escreve a nota pendente e zera o global. É
  **chamado**, nunca lido por `$( )`.
  - No `cmd_run`, entra logo depois da nota do `--phase`, antes de `before=` e dos dois arms.
  - No `cmd_retry`, entra no lugar descrito acima.
- **Mudança de comportamento a declarar no PR:** a fase da nota da override passa a ser a da **sessão
  comprada**. No salto draft ela diz PR, onde hoje dizia REVIEW. É a consequência direta da decisão
  11a.
- O cabeçalho de `checkpoint_note_intervention` ganha um parágrafo "WHEN": o runner escreve a nota só
  onde a porta compra a sessão.

**Como (TDD):** tudo em `check-autonomy.sh`.
- **Ajudantes NOVOS** (não existem em `89df2e5`; os que existem são `notes`, `nnotes` e `ck_clean`).
  Os dois primeiros leem o `$MDIR` inteiro, checkpoint e notas:
  ```bash
  mdir_notes() { grep -RhcE '^[[:space:]]*-[[:space:]]*intervention:' "$MDIR" 2>/dev/null | awk '{s += $1} END {print s + 0}'; }
  mdir_count() { grep -RhcF "$1" "$MDIR" 2>/dev/null | awk '{s += $1} END {print s + 0}'; }
  nw_budget() { mkdir -p "$1/.sdd/logs/$MISSION"
    printf '2026-01-01T10:00:00-03:00  EXEC  agent=sdd-executor  model=opus  session=nw  rc=0  dur=1s  cost_usd=5  log=/dev/null\n' \
      > "$1/.sdd/logs/$MISSION/pipeline.log"; }
  nw_notes() { cat "$1/docs/handoffs/$MISSION"/*.md | grep -c '^- intervention: sdd run --budget-override' || true; }
  ```
  - O `nw_budget` funciona porque o `nowork_world` não declara `BUDGET_MISSION_USD` e o `.sdd/logs/` é
    ignorado pelo git. É a mesma ideia do teste do teto perto de `check-autonomy.sh:621`.
  - O `|| true` mora no sensor, nunca numa célula do checkpoint.
  - `retry:+1` conta `mdir_count 'intervention: sdd retry (the phase'`, e `override:1` conta
    `mdir_count 'intervention: sdd retry --budget-override'`.
- **No bloco do teto da missão** (`== the mission ceiling stops the line… ==`, perto de `:610`):
  - `sdd retry stopped by the mission ceiling writes no intervention note and commits nothing` →
    `notes:+0 head:same`. Red: `got: notes:+1 head:moved`;
  - controle: `sdd retry --budget-override buys its session and writes the retry note and the override note`
    → `session:1 notes:+2 retry:+1 override:1`.
- **No bloco no-work, depois da "door 3".** O teto vem do ambiente (`BUDGET_MISSION_USD=1`) mais um
  journal com `cost_usd=5`, gravado pelo `nw_budget`.
  - NW6B, célula ilegível: `--budget-override on a lap that stops before any session writes no note` →
    `rc:3 kind:no-work stub:0 notes:0 head:same`. Red: `notes:1 head:moved`.
  - NW6C, linha `pending` e `--max-phases 1`:
    `--budget-override on a lap that opens a session writes exactly one note` → `stub:1 notes:1`. É o
    par diferencial do NW6B.
  - NW6D: `--budget-override lifted on the draft jump's REVIEW lap is written above the PR session it bought`
    → `sessions:PR,PR notes:1 on-pr:1`. Red: `on-pr:0`. O mundo:
    ```bash
    nowork_world "$NW6D" "done" '{sha}' 1
    ( cd "$NW6D" || exit 1
      printf -- '---\nfase: QA\nstatus: skipped\n---\n' > "docs/handoffs/$MISSION/30-handoff-qa.md"
      printf 'round one\n' > "docs/handoffs/$MISSION/40-review-r1.md"
      printf 'REVIEW_MAX_ITER=1\nPUBLISH_ON_REVIEW_BLOCKED="draft"\n' >> .sdd/config.sh
      git add -A && git commit -qm "chore: a mission out of review rounds" ) >/dev/null 2>&1
    nowork_stub "$NW6D" nothing
    nw_budget "$NW6D"
    ```
    - A volta REVIEW levanta o teto e sai pelo `continue` do salto draft, sem sessão.
    - A volta PR forçada chama o `mission_budget_blown` de novo e abre a sessão que a override
      comprou.
    - O stub `nothing` não move nada, então a volta PR também compra o retry inline: `PR,PR`, com uma
      nota só, prova que o retry é a mesma volta.
    - O `on-pr` conta `^- intervention: sdd run --budget-override .* — PR — ` nos `.md` da missão.
  - NW10B, gêmeo do mundo QA de duas sessões (o NW10, perto de `:7091`):
    `--budget-override over two sessions of one run writes one note, not one per session` →
    `stub:2 notes:1`. O stub é reaproveitado com `sed -i "s|$NW10|$NW10B|g" "$OUTSIDE/stub/claude"`,
    e o mundo nasce com `NW_E2E="true"` em volta do `nowork_world`, como o NW10.

**Mutantes** (todos morrem em `check-autonomy.sh`):
- `RUN_intervention_retry_before_the_ceiling`: devolve a nota do retry para cima do teto.
  ```
  sed -i '/^cmd_retry() {/,/^}/ { /^  checkpoint_note_intervention "sdd retry (the phase was relaunched from the CLI with a fresh session)" "\$phase"$/d; s|^  if mission_budget_blown "\$phase"; then return 3; fi$|  checkpoint_note_intervention "sdd retry (the phase was relaunched from the CLI with a fresh session)" "$phase"\n&|; }' "$1"
  ```
- `RUN_budget_override_noted_at_the_lift`: na faixa do `mission_budget_blown`, troca
  `^      BUDGET_OVERRIDE_NOTE="\(.*\)"$` por `      checkpoint_note_intervention "\1" "$phase"`.
- `RUN_budget_override_unwritten_on_run`: no `cmd_run`, troca `^    budget_override_note_write "$phase"$`
  por `    :`.
- `RUN_budget_override_unwritten_on_retry`: no `cmd_retry`, troca `^  budget_override_note_write "$phase"$`
  por `  :`.
- `RUN_budget_override_note_kept`: no `budget_override_note_write`, apaga `^  BUDGET_OVERRIDE_NOTE=""$`.
- `RUN_budget_override_not_one_shot`: no `mission_budget_blown`, apaga `^      BUDGET_OVERRIDE_NOTED=1$`.
- `RUN_budget_override_note_reset_on_entry`: no `mission_budget_blown`, acrescenta
  `BUDGET_OVERRIDE_NOTE=""` depois de `^  local phase="$1" spent ceiling="$BUDGET_MISSION_USD"$`.
- Re-ancorado: `RUN_mission_budget_override_unnoted` passa a
  `sed -i '/^mission_budget_blown() {/,/^}/ s|^      BUDGET_OVERRIDE_NOTE="sdd $AUTONOMY_INVOCATION --budget-override .*$|      :|' "$1"`.
- Vizinhos (11):
  - `RUN_intervention_unwritten_on_retry`, `RUN_intervention_written_on_dry_run` e
    `RUN_intervention_unwritten_on_phase`;
  - `RUN_intervention_before_the_stop` e `RUN_intervention_on_runner_forced_lap`;
  - `RUN_mission_budget_ignored`, `RUN_mission_budget_ignored_on_retry`,
    `RUN_mission_budget_zero_is_a_ceiling`, `RUN_mission_budget_fractional_disabled` e
    `RUN_mission_budget_stops_projection`;
  - `RETRY_no_work_blind`.

Todo `sed` acima usa a faixa `/^<função>() {/,/^}/` da função citada. No protótipo, o `--anchors`
deu `all 630 mutants still apply`. A soma: 619, mais os 4 do `227-228.patch` (2 do #228 e 2 do
#227), mais os 7 do F.

⚠️ **O `&` na SUBSTITUIÇÃO do `sed` é o texto casado.**
- Quem quer o texto casado escreve `&`, como no `\n&` do `RUN_intervention_retry_before_the_ceiling`.
- Quem quer um `&` literal escreve `\&`, como no `\&\&` do `RUN_intervention_before_the_stop`.
- No padrão, `&` é literal.
- Medido no planejamento: gerado via Python, `'\\&'` vira `\&`, que é `&` literal. Confira o arquivo
  gerado, não a string Python.

**Check do incremento** (os três commits; um `ok` por asserção nova):
`` `a=$(bash tests/check-autonomy.sh 2>&1); b=$(bash tests/check-gates.sh 2>&1); grep -c -e '^  ok    run stops at an impossible stamp with the remedy that can work' -e '^  ok    sdd run --phase PLAN stops before any session and writes no note' -e '^  ok    the draft jump is the runner' -e '^  ok    run --phase PR stops at the stamp and writes no intervention note' -e '^  ok    sdd retry stopped by the mission ceiling writes no intervention note' -e '^  ok    sdd retry --budget-override buys its session' -e '^  ok    --budget-override on a lap that stops before any session writes no note' -e '^  ok    --budget-override on a lap that opens a session writes exactly one note' -e '^  ok    --budget-override lifted on the draft jump' -e '^  ok    --budget-override over two sessions of one run writes one note' <<< "$a"$'\n'"$b"` → `10` ``

Medidos separadamente: o #228 dá 0 → 1, o #227 dá 0 → 3 e os resíduos dão 0 → 6.

**Sensor durável:** os probes acima e os 11 mutantes novos (2 + 2 + 7), mais 2 re-ancorados.

**No mesmo commit de cada parte:**
- **`templates/checkpoint-notas.md`** (`:35-36`, commits 2 e 3): "…quando é ele quem recebe a mão do
  humano — `sdd run --phase X`, `sdd retry`, `--budget-override` — **e só na volta que abre sessão
  (uma volta parada antes dela, por PLAN, carimbo, teto ou no-work, não grava nota)**, e a commita
  sozinha…". O `check-templates.sh` só cobra o marcador `intervention:`, não esta frase.
- **`docs/pipeline.md`:**
  - `:976-978` (o teto): "…the runner writes the `- intervention:` note itself, once per run, right
    above the session the override buys — a lap the REVIEW ceiling or the no-work guard stops after
    the lift writes none, and `sdd retry` writes its own note only below the ceiling";
  - `:1375-1377` (notas narrativas): "— only on a lap that opens a session".
- **`config/schema.md:256`** (`BUDGET_MISSION_USD`): "the first time the override lifts something
  **and a session is then opened**".
- **Anatomia §7,** na Regra: a linha `- intervention:` é escrita pelo runner **só onde a porta compra a
  sessão**. Em "Onde mora hoje", cite o par `BUDGET_OVERRIDE_NOTE`/`budget_override_note_write`.

**Reversível por:** reverter os três commits, na ordem inversa.

### I8 — #229 + #230: a página do `sdd status` cala sobre missão de outra máquina, e o `ok` do `note-manual` diz só o que aconteceu

São dois commits, com o **#229 primeiro**.

**#229, o quê:** `status_unrecorded` (`bin/sdd:6844`) deixa de sugerir `sdd note-manual` quando o
ledger desta máquina não tem **nenhuma linha `session`** daquela missão (repo e missão).
- **É um desvio medido da direção do item, e o humano o aceitou.** O item dizia "nenhuma linha".
  Medido: com "qualquer linha", a linha `manual` que a própria dica manda gravar reabre a pergunta
  para toda outra fase.
- Pelo mesmo motivo, uma escalada de um `sdd run` desta máquina que não abriu sessão também não conta.
- **Limite declarado no comentário:** uma missão feita inteira à mão nesta máquina também cala.

**#229, como (TDD):** probe em `tests/check-gates.sh`, logo depois de "a manual row of the phase takes
it off the page" (`:5633`). Asserção:
`a mission with no session in this machine's ledger ran elsewhere, and the page asks nothing`.
- **O mundo:** o ledger do fixture sem as linhas da missão, mais três linhas que um teste frouxo
  contaria:
  - uma linha de outra missão neste repo;
  - uma `session` desta missão vinda de outro checkout;
  - uma `manual` desta missão aqui.
- A contagem de `✓` testemunha que os gates responderam igual nos dois mundos.
- **Red:** `expected: rows:manual:1 hints:2>0 green:7`, `got: rows:manual:1 hints:2>3 green:7`.
  EXEC, REVIEW e DOCS eram sugeridos em falso.

**#229, conserto:**
- O `jq` ganha `| (.phase // empty), (select(.event == "session") | "+")`, mais
  `grep -qxF + <<< "$seen" || return 0`.
- O filtro `and (.event == "session" or .event == "manual"))` fica intacto: é a âncora do
  `mut_STATUS_manual_row_ignored`.
- Uma falha do `jq` agora cala, em vez de sugerir tudo.

**#229, mutantes** (na faixa `/^status_unrecorded() {/,/^}/`):
- `STATUS_elsewhere_asked` → `{ /^  grep -qxF + <<< "\$seen" || return 0$/d }`.
- `STATUS_presence_counts_manual` →
  `s@| (.phase // empty), (select(.event == "session") | "+")@| (.phase // empty), "+"@`.
- Vizinho: `STATUS_manual_row_ignored`.

**#230, o quê:** o `checkpoint_note_intervention` (`bin/sdd:468`) publica o que fez em
`CHECKPOINT_NOTE`: `none`, `failed`, `uncommitted` ou `committed`, e vazio na projeção.
- É setter único: zera o global na entrada, e há um `CHECKPOINT_NOTE=""` no topo por causa do
  `set -u`.
- Continua com `return 0` em TODO caminho, a restrição do CodeRabbit no PR #222.
- O `cmd_note_manual` (`:11086`) lê `noted="$CHECKPOINT_NOTE"` **antes** do `autonomy_manual_row`, e
  um `case` monta o `ok`.
- **Decisão aceita:** sem `checkpoint.md`, o `note-manual` ainda grava a linha `manual` do ledger, e o
  `ok` diz `a manual row in the ledger, and no note — <missão> has no checkpoint.md`.
- Os outros chamadores do helper (`--phase`, `retry`, `--budget-override`) não leem o global, então
  não mudam de comportamento.
- O contrato com o I7 é este: global publicado mais `return 0`.

**#230, como (TDD):** probe em `tests/check-autonomy.sh`, logo depois da asserção do detached HEAD
(`:5976`). Asserção:
`note-manual's ok says what the note writer did, and the manual row is written in every case`.
- O `nm_bare_says` roda em 4 mundos `kitguard_world`: sem checkpoint, `mv` recusado (reaproveita o
  shim `MV_SHIM` do probe do retry), checkpoint sujo e normal.
- **O `nm_bare_says` é NOVO** (em `89df2e5` existem `nm_says`, `kitguard_world` e `MV_SHIM`). Ele recebe
  `<dir> <reason ERE> [PATH prefix]`:
  - roda `"$SDD" note-manual "$MISSION" PR` no dir, com
    `PATH="${3:+$3:}$PATH" MV_SHIM_DIR="$MV_SHIM" MV_SHIM_REAL="$(command -v mv)"`;
  - imprime `rc:… claimed:… said:… row:… commits:+…`. `claimed` conta
    `the note in the checkpoint`, `said` conta `ok .*recorded as done by hand: <ERE>`, `row` é a fase
    das linhas `manual` do ledger, e `commits` é o delta de `git rev-list --count HEAD`;
  - termina zerando o `$LEDGER`.
- **Os quatro motivos (ERE),** um por mundo:
  - sem checkpoint (o mundo faz `git rm` do `checkpoint.md` e commita):
    `a manual row in the ledger, and no note — [^ ]+ has no checkpoint\.md$`;
  - `mv` recusado: `a manual row in the ledger, and no note — it could not be written`, mais a
    testemunha `fired` do shim;
  - sujo (uma linha `| I2 | edited by hand | … |` acrescentada ao checkpoint):
    `the note in the checkpoint, NOT committed`;
  - normal: `the note in the checkpoint, a manual row in the ledger$`.
- **O `ok` do `cmd_note_manual`** passa a ser `ok "phase $phase of $MISSION recorded as done by hand: $note"`,
  e o `$note` sai do `case` sobre `CHECKPOINT_NOTE`. O esperado inteiro da asserção é
  `rc:0 claimed:0 said:1 row:PR commits:+0|rc:0 claimed:0 said:1 row:PR commits:+0 fired|rc:0 claimed:1 said:1 row:PR commits:+0|rc:0 claimed:1 said:1 row:PR commits:+1`.
- O termo `said` é o motivo próprio de cada mundo.
- **Red:** `got: rc:0 claimed:1 said:0 …` nos três primeiros mundos.

**#230, mutantes** (os quatro slugs entram no `CATALOG` logo depois de `RUN_manual_row_missing`, para
os hunks não se fundirem):
- `RUN_manual_ok_unread` → `s@^  noted="\$CHECKPOINT_NOTE"$@  noted=committed@`.
- `RUN_ck_note_none_unpublished` →
  `s@\[ -f "\$ck" \] || { CHECKPOINT_NOTE=none; return 0; }@[ -f "$ck" ] || return 0@`.
- `RUN_ck_note_failed_unpublished`: apaga `^    CHECKPOINT_NOTE=failed$`.
- `RUN_ck_note_committed_unpublished`: apaga `^    CHECKPOINT_NOTE=committed$`.

Vizinhos: `RUN_intervention_claims_unwritten_note`, `RUN_intervention_written_on_dry_run` e
`RUN_manual_row_missing`. Ficam sem mutante, declarados:
- o reset na entrada (uma chamada por processo);
- o `uncommitted` vindo de um commit que falha;
- o braço `*` do `case`.

**Check (os dois numa célula):**
`` `a=$(bash tests/check-gates.sh 2>&1); b=$(bash tests/check-autonomy.sh 2>&1); grep -c -e '^  ok    a mission with no session in this machine.s ledger ran elsewhere, and the page asks nothing$' -e '^  ok    note-manual.s ok says what the note writer did, and the manual row is written in every case$' <<< "$a"$'\n'"$b"` → `2` ``.
Mede 0 antes e 2 depois.

**No mesmo commit:**
- **Anatomia §5:** o `status_unrecorded` cala sem `session` desta máquina, e vem o limite "feita
  inteira à mão".
- **Anatomia §7:** o `ok` do `note-manual` lê `CHECKPOINT_NOTE`.
- **`docs/pipeline.md`:** a dica do `sdd status`, se o texto disser que vale para toda fase verde
  (procure `note-manual`).

**Reversível por:** reverter cada commit.

### I9 — #234: o supervisor diz por quem espera, e o `turn_rule` avisa toda fase

**O quê:**
- **No helper:** quando o worker sai por conta própria e ainda há descendentes vivos, o supervisor
  imprime **uma vez**, no stderr e 1 s depois, o pid e a cmdline de cada um. Diz também que o comando
  espera por eles e que o checkout segue preso.
- **No `turn_rule`:** uma frase nova, para todas as fases (decisão 8).

**Onde:**
- `bin/sdd-coordination.py`: `wait_family`, com o `waitpid` em `:337`; `bounded_hook`; `supervise`,
  com a chamada em `:441`.
- `bin/sdd`: o `turn_rule` em `boot_prompt` (`:2998`).
- `tests/check-coordination.sh`: o gancho do fixture perto de `COORD_FDCOUNT` (`:120`), e o probe
  depois de `check("error recovers"…)` (`:913`).
- `tests/check-dry-run.sh`: o laço do `turn_rule` (`:421-437`).

**Como (TDD):**
- **Probe do print** (`check-coordination.sh`):
  `a process the worker leaves behind is named once, with its pid and command line`.
  - É diferencial, contra a mesma chamada sem nada deixado para trás.
  - O config do fixture ganha o gancho `COORD_LEAVE`/`COORD_LEAVE_PID`.
  - Red: `FAIL … pids=['…'] left='PLAN\n' quiet='PLAN\n'`.
- **Probe do hook calado:** `a hook's straggler is waited for in silence: the hook names nothing`.
  Chama o `bounded_hook` direto, via import.
- **Probe por fase** (`check-dry-run.sh`):
  `every projected phase is told a background process holds the run, and one it did not start is not its own`.
  Red: `expected: 5 5 5`, `got: 5 0 0`.

**Conserto no helper:**
- Novos `STRAGGLER_GRACE = 1`, `descendants()` e `name_stragglers()`, em ASCII e só com a stdlib já
  importada (funciona sob `python3 -I -S`).
- `wait_family` ganha `announce=None`:
  - quando o worker é colhido por saída própria (`worker_done_first`), arma
    `named_at = now + STRAGGLER_GRACE`;
  - no tique, se nenhum sinal chegou, nomeia uma vez e zera `named_at`.
- Só o `supervise` passa `announce=value['command']`. O `bounded_hook` não nomeia, porque o prazo de
  5+1 s já limita a família dele.
- A lista é só leitura de `/proc`. Quem libera o lock continua sendo só o `ECHILD`.
- Saída medida com `(nohup sleep 2.5 &)` no config e `sdd phase`:
  ```
  sdd phase: done, but 1 process it left running holds the checkout; this command waits for it, and the checkout stays held, until it exits:
    pid 42335: sleep 2.5
  ```

**Conserto no `turn_rule`** (decisão 8): acrescente ao texto, depois da frase atual:

> A process you start in the background (`nohup … &`) joins the pipeline's family: `sdd run` does not
> finish, and the checkout stays held, until it dies. Never stop or restart a process you did not
> start — the app under test is the human's; a restart, or another environment, goes to the handoff.
> What you started for your own check, stop before you end the turn.

**Mutantes:**
- `COORD_stragglers_unnamed`: o `supervise` volta a `wait_family(child, signals)`.
- `COORD_stragglers_named_every_tick`: apaga `^                named_at = None$`, o termo `count == 1`
  da asserção.
- `COORD_hook_names_stragglers`: acrescenta `announce='hook'` no `bounded_hook`.
- `RUN_turn_rule_background_dropped`: um `sed` na faixa de `boot_prompt` que apaga o parágrafo e
  mantém a aspa de fechamento. Morre em `check-dry-run.sh`.

Os três `COORD_*` escrevem em `"${1%/*}/sdd-coordination.py"`, no molde de `:5457`. Vizinhos
re-provados: `COORD_reaped_pidfd_kept`, `COORD_select_pidfd`, `COORD_wait_worker_only`,
`COORD_no_subreaper` e `RUN_turn_rule_dropped`.

Ficam sem probe, declarados: o valor do grace e a escolha de não nomear quando chegou um sinal.

**Check:**
`` `a=$(bash tests/check-dry-run.sh 2>&1); b=$(bash tests/check-coordination.sh 2>&1); grep -c -e '^  ok    every projected phase is told a background process holds the run' -e '^  ok    a process the worker leaves behind is named once' -e '^  ok    a hook.s straggler is waited for in silence' <<< "$a"$'\n'"$b"` → `3` ``.
Mede 0 antes e 3 depois.

**Custo:** cerca de 3,7 s de `sleep` mais duas chamadas da CLI no `check-coordination.sh`. O piso de
154 checks não muda; hoje são 192.

**No mesmo commit:**
- **Anatomia §1:** o `turn_rule` ganha o parágrafo do processo em background.
- **Anatomia §6:**
  - no parágrafo "Posse desde 2026-09-18": o supervisor diz por quem espera (`name_stragglers`, uma
    vez, 1 s depois; o hook não nomeia);
  - no "Limite da posse": o descendente de longa duração passa a ser nomeado.
- **`docs/pipeline.md`** (perto de `:53-57`): a frase da nomeação, e que o hook não nomeia.
- **`agents/sdd-ticket.md:80` fica como está.** Tem uma cópia antiga e curta da regra do turno, mas é
  lembrete e não diverge.

**Reversível por:** reverter o commit.

### I10 — #235: o `/sdd-plan` no próprio kit escreve e executa a missão num worktree ligado (ADR 0016 §2)

**O quê:** o `commands/sdd-plan.md` ganha o passo 2 de "## Before anything else". Os antigos 2 e 3
viram 3 e 4, e a referência "step 2/step 3" do "## Then" (`:42`) vira "step 3/step 4".

**Onde:**
- `commands/sdd-plan.md` (`:13`, `:15`, `:42`);
- `tests/check-hat.sh`: a função nova `command_worktree_probes`, depois de `command_approval_probes`
  (`:306`), chamada na lista de topo (`:512`).

**Texto do passo** (inglês, porque `commands/*.md` é superfície):
```
2. **If this checkout is the kit that `sdd` runs from, move to a linked worktree before writing
   anything.** Resolve `sdd="$(readlink -f "$(command -v sdd)")"` and compare it with the root from
   step 1: when it lies under that root (`case "$sdd" in "$root"/*)` — the slash keeps a sibling
   such as `<root>-lote-5` out), every `sdd run` of every other repository on this machine executes
   this checkout, and its kit guard compares this checkout's `HEAD` and `git status --porcelain`
   before and after each phase. One untracked `00-missao.md` written here while a target's EXEC
   runs stops that run with `KIT-TOUCHED` (rc 3); a linked worktree, dirty or with commits, moves
   neither. So, before writing any artifact:
   - create the worktree beside this checkout, on the branch the mission will declare in
     `branch:`, cut from the remote's `DEFAULT_BRANCH` — `git fetch`, then
     `git worktree add ../<repo>-<slug> -b <branch> origin/<DEFAULT_BRANCH>` — or reuse it, when
     it already exists on that branch. Never `git pull` here to freshen the base: a fetch moves no
     `HEAD`, a pull moves the very one the kit guard compares;
   - take the worktree as the repository root for every step below: the config, `HANDOFF_DIR`,
     the artifacts, `sdd why` and `sdd approve` all run from there, and this checkout stays on
     `DEFAULT_BRANCH`, clean;
   - tell the human, in one line, the worktree's path and branch, and that the mission is
     executed there too — interactively, never by a `sdd run` from this checkout.

   When `sdd` is not on the PATH, or resolves outside this root, skip this step: no run of another
   repository executes this checkout.
```
O "## Then" também ganha: "the repository root it writes under (the worktree, when step 2 moved
you)".

⚠️ Dentro do worktree, `health`, `preflight` e `install` rodam por `./bin/sdd`. O `sdd` do PATH tem
`SDD_HOME` = checkout principal (`_resolve_self`, `bin/sdd:59`) e instalaria os `agents/` **de lá**.
Diga isso numa frase do passo, ou no "## Then". Se o texto mudar, o probe e a sabotagem mudam juntos.

**Como (TDD):** o `command_worktree_probes()` lê a seção "## Before anything else", não o arquivo
inteiro, e exige 7 trechos:
1. `readlink -f "$(command -v sdd)"`;
2. `case "$sdd" in "$root"/*)`;
3. "before writing any artifact";
4. `git worktree add ../<repo>-<slug>`;
5. "take the worktree as the repository root for every step below";
6. "tell the human";
7. "resolves outside this root, skip this step".

Asserção:
`command: /sdd-plan moves a mission of the kit sdd runs from into a linked worktree before writing it`.
Red: `FAIL  command: /sdd-plan no longer moves a mission of the kit sdd runs from into a linked worktree before writing it (…)`.

**Passada de sabotagem** (o catálogo nunca muta `commands/*.md`). No protótipo, 9 de 9 ficaram
vermelhos:
- D1: o passo removido;
- D2: o passo movido para o "Then";
- D3: sem a detecção;
- D4: sem a barra (`"$root"*`);
- D5: "after writing";
- D6: sem a troca de raiz;
- D7: sem a linha ao humano;
- D8: `git checkout -b` no lugar do worktree;
- D9: a cláusula de "skip" invertida. Ela sobreviveu à 1ª versão do probe, e a 7ª verificação nasceu
  para pegá-la.

**Check:**
`` `o=$(bash tests/check-hat.sh 2>&1); grep -c '^  ok    command: /sdd-plan moves a mission of the kit sdd runs from into a linked worktree before writing it' <<< "$o"` → `1` ``.
Mede 0 antes e 1 depois.

**Sensor durável:** a função de probe no `check-hat.sh`.

**No mesmo commit:**
- **Anatomia §6:** troque o trecho "Sem worktree nem container: … não um `git worktree add` no laço."
  por este texto, ajustado ao que o I1 entregou:
  > Sem container, e sem worktree **no laço**: o `sdd run` roda no checkout do humano, e isolar a fase num `git worktree add` dentro do `cmd_run` pede desenho próprio (Y2 do `CONTEXT.md`). A identidade do repo deixou de ser o obstáculo — o ledger lê o `.git` comum desde `c514e36`, e worktree do mesmo repo é o mesmo repo. A exceção é a **missão do próprio kit**, desde o lote 5 (#235, ADR 0016 §2): o `sdd` do PATH é o checkout principal do kit, e o `kit_guard_check` de todo `sdd run` de alvo compara o `HEAD` e o `status --porcelain` dele, então um `00-missao.md` não rastreado gravado ali durante o EXEC de um alvo para aquela corrida com `KIT-TOUCHED`. Por isso o `/sdd-plan` (passo 2 de *Before anything else*) escreve a missão do kit num worktree ligado, e a sessão **interativa** a executa lá — nunca um `sdd run` a partir do checkout principal. Medido: worktree sujo e com commit deixa o carimbo do principal em `89df2e5|false`; o mesmo arquivo no principal, `|true`. É posse do checkout, não isolamento de filesystem. ⚠️ Dentro de um worktree ligado, `git bisect run`, `git rebase --exec`, os hooks `pre-commit`/`pre-push` e um alias `!` exportam `GIT_DIR` absoluto; a suíte, o catálogo e cada sensor o limpam desde #226 (`tests/isolate-git.sh`).
- **`CONTEXT.md` Y2 (opcional):** uma nota de que "missão do kit em worktree, interativa" não é o Y2,
  que trata de concorrência no runner.
- **`agents/sdd-planner.md` NÃO muda:** o comando entrega a raiz ao planner, então a definição é uma
  só.

**Reversível por:** reverter o commit.

### I11 — Fecho: `RESOLVED by`, a ADR aceita, glossário, drift, KAIZEN_LOG, handoff da EXEC e a suíte inteira

**O quê**, nesta ordem:
1. **`RESOLVED by <hash>` nos 12 itens consertados** do `TODO.md`: #223–#230 e #232–#235. Cada hash
   é o do commit do conserto, e não o do `chore(checkpoint)`. O 13º item (o `sdd kaizen` no checkout
   principal) **fica aberto**: ele nasceu no planejamento e não é desta leva.
   - Teto de 8 linhas e de 120 caracteres por linha. Se não couber, enxugue o corpo, nunca o título.
   - Na #223, o corpo passa a dizer o que foi medido: ruído no stderr mais risco latente, e não o
     aborto que o item afirmava (I3).
2. **ADR 0016:** `Status` → `accepted (—, <data>)`. A ADR 0015 ganha, no cabeçalho,
   `- **Amended by**: 0016 (§3: the checkpoint left by the base commit that added the report must be a blob the mission's branch already had)`.
3. **`CONTEXT.md`:** os verbetes "Gênero do bug" (I4) e "Relatório da missão" (I5), se ainda não
   mudaram no incremento, e um verbete curto **"Missão do kit em worktree"** (ADR 0016 §2), ou a nota
   no Y2.
4. **Drift:** procure no `docs/pipeline.md`, no `docs/failure-modes.md` e no `CLAUDE.md` frase que
   descreva o comportamento antigo:
   - `intervention`, `budget-override` e `retry` (I7);
   - `kit_dirty` e `KIT-TOUCHED` (I6);
   - `deferred` (I4);
   - `waitpid` e `ECHILD` (I9);
   - `GIT_DIR` (I1).
   
   O `CLAUDE.md` § "Entra lá são quatro lugares" só muda se o I1 tiver mexido num piso (o I1 diz).
5. **`KAIZEN_LOG.md`:** uma entrada `## <data> — Lote 5: o que o lote 4 deixou`, no formato das
   anteriores.
   - **Antes:** 12 abertos, seis sensores falhando abertos, a nota `intervention:` contada sem sessão,
     e a missão do kit no checkout que os alvos executam.
   - **Depois:** 12 `RESOLVED by`, o catálogo com N novos mutantes e o número do `--anchors`.
   - **O que travou:** as decisões do grill e os desvios medidos (#229, #223).
6. **`docs/handoffs/20261006-lote-5-o-que-o-lote-4-deixou/20-handoff-exec.md`,** a partir do template
   da fase EXEC (`templates/`), com TL;DR de até 20 linhas.
7. **A suíte inteira** (`bash tests/run-all.sh` → `suite green`) e `./bin/sdd adr check` → rc 0.

**Check:**
`` `a=$(awk '/<!-- sdd:open -->/{o=1} /<!-- sdd:decided -->/{o=0} o && /RESOLVED by/{n++} END{print n+0}' TODO.md); b=$(awk '/^## .* — Lote 5: o que o lote 4 deixou/{c++} END{print c+0}' KAIZEN_LOG.md); c=$(awk '/Amended by.*0016/{n++} END{print n+0}' docs/adr/0015-the-stamp-is-not-headless.md); d=$(awk '/^- [*][*]Status[*][*]: accepted/{n++} END{print n+0}' docs/adr/0016-the-mission-checkpoint-and-the-kit-worktree.md); f=$(awk 'END{print (NR>0)}' docs/handoffs/20261006-lote-5-o-que-o-lote-4-deixou/20-handoff-exec.md 2>/dev/null); echo "$a $b $c $d ${f:-0}"` → `12 1 1 1 1` ``

**Reversível por:** reverter os commits do fecho.

### I12 — o `/sdd-plan` commita o que o `sdd approve` deixa, e o relay segura a mensagem que não é resposta

**Origem:** entrou depois da aprovação, por pedido do humano na retro da sessão de planejamento
("Investiga E melhore", 2026-10-06). Já está **feito**: `5df5176`, executado pela sessão do relay antes
do I1. Não tem item no `TODO.md`, porque foi consertado antes de ser registrado, então o I11 não lhe
deve `RESOLVED by`.

**Medido:**
- O `cmd_approve` commita `paths=( "$mission_rel" )` mais o arquivo do `adr:`, e mais nada. O
  `HAT_WRITES_BASE` (`bin/sdd`, `'$TODO_FILE, tests/health-baseline.txt'`) abre esses dois caminhos a
  todo chapéu, o planner incluído. Depois do `sdd approve` deste lote, `git status --short` deu
  ` M TODO.md` (#235 e #236), com a catraca ainda em 11. Foi commitado à mão em `9e7400b`. Os lotes 3
  e 4, que saíram `auto`, commitaram o plano à mão (`0e5a208`, `6c628be`).
- O planner termina todo turno com uma pergunta (`agents/sdd-planner.md`, parágrafo do relay). Uma
  mensagem do relay só com o número da #235 o retomou, e ele reenviou as perguntas 4 e 5 com a
  recomendada da 5 trocada (de "§1 + §2" para "só §1"), depois de o humano já ter respondido à
  primeira versão.

**O quê** (`commands/sdd-plan.md`, inglês):
- "## Relaying the grill to the human": a resposta nomeia a opção pelo texto, nunca pela posição.
  Bullet novo, "Nothing else resumes the planner while a question is pending": a mensagem que não
  responde nada espera e vai junto com a próxima resposta.
- "## When the artifacts exist": o passo 2 e o YES do passo 3 seguem para o passo 4 novo, "What
  `sdd approve` does not commit":
  - `git status --porcelain -- <HANDOFF_DIR>/<mission> <TODO_FILE> tests/health-baseline.txt`;
  - na branch da missão, commit por caminho (nunca `-a`), com os achados num commit próprio que move
    a linha `todo-findings` da catraca no mesmo diff;
  - fora dela, nenhum commit, e os caminhos são nomeados ao humano.
- `tests/check-hat.sh`: `command_relay_probes`, depois de `command_approval_probes`, chamada na lista
  de topo. Lê as duas seções, não o arquivo inteiro.

**Passada de sabotagem:** 6 de 6 vermelhos:
1. o título do passo 4;
2. os dois caminhos dentro do `git status`;
3. `todo-findings`;
4. "commit nothing";
5. "by the option's text, never by its position";
6. "Nothing else resumes the planner…".

A 1ª versão do probe aceitava `tests/health-baseline.txt` em qualquer lugar da seção, onde ele
aparece três vezes, e sobreviveu à remoção do caminho de dentro do `git status`. O probe passou a
exigir os dois caminhos no próprio comando.

**Check:**
`` `o=$(bash tests/check-hat.sh 2>&1); grep -c -e '^  ok    command: /sdd-plan commits what sdd approve leaves behind' -e '^  ok    command: /sdd-plan holds a relay message until the next answer' <<< "$o"` → `2` ``.
Mede 0 antes (os dois `FAIL`) e 2 depois. A suíte inteira ficou verde no commit: 351 s, e as âncoras
dos 619 mutantes aplicam.

**Interação com o I10:** o I10 acrescenta `command_worktree_probes` no mesmo ponto do
`check-hat.sh` e na mesma lista de topo. Os números de linha que ele cita (`:306`, `:512`) andaram com
o I12, então ancore pelos nomes das funções. O I10 renumera "## Before anything else", e o I12 não
toca essa seção. A anatomia e o `CONTEXT.md` não mudam: é prosa do comando e o probe dela.

**Reversível por:** reverter `5df5176`.

## Depois do checkpoint (sem incremento; decisão 9)

1. **Push e PR** contra `main`, a partir do worktree. O corpo do PR leva:
   - a evidência de cada incremento;
   - as mudanças de comportamento de § Fatos que atravessam incrementos;
   - a ordem do carimbo;
   - o saldo "13 → 1 + N", porque o 13º item fica aberto.
2. **Esperar TODOS os bots.** O Codex chama-se por `@codex review`. O CodeRabbit se pausa sozinho
   depois de muitos commits e volta com `@coderabbitai review`.
3. **Consertar numa leva só.** Achado novo que não cabe passa pela régua D15 e vai ao `TODO.md`, com a
   catraca +1.
4. **Um `./bin/sdd health` no worktree,** depois do último commit de código, nesta ordem:
   - copie o mapa: `mkdir -p .sdd/cache && cp /home/joruge/repos/sdd_agents/.sdd/cache/mutation-killers.tsv .sdd/cache/`;
   - lance desanexado: `os.setsid()`, `SIG_DFL` em HUP/INT/QUIT/PIPE, env sem `CLAUDE*` nem `GIT_*`,
     `TMPDIR=/tmp`, log em arquivo;
   - vigie pelo PID (`kill -0`) e pela chave em `.sdd/logs/mutation-stamp`.
   
   Leva de 40 a 80 min. Não commite nada durante a corrida, porque a catraca é contada no começo e
   comparada no fim.
5. **Merge pelo humano.**
6. **Chore pós-merge:** apagar os 12 itens com `RESOLVED by` (`todo_rm.py`, com o caminho trocado para
   a `main`) e levar a catraca de 13 a 1 + N. Depois, re-sync do espelho de issues:
   `todo-to-github-issues --apply`, fechar à mão como not-planned o que couber, e
   `--apply --close-orphans` depois do chore.
7. **Remover o worktree:** `git worktree remove /home/joruge/repos/sdd_agents-lote-5`.

## Riscos e não-feitos

| Risco | Probabilidade | Mitigação |
|---|---|---|
| Um `sdd run` de alvo em voo para como `kit-touched` porque algo escreveu no checkout principal | baixa com o worktree | Passo 0, regras 1–3; conferir `git -C /home/joruge/repos/sdd_agents status --porcelain` → vazio antes de cada commit |
| Ajudante com `ROOT` fixo reescreve o `TODO.md` do checkout principal | média, se usado sem trocar | Passo 0, regra 3 |
| Mutante de um incremento fica cego pelo conserto de outro (o `79b6f93` e o `52de46e` cegaram 4) | média | `--only` nos vizinhos de cada seção; `--anchors` antes de cada commit |
| A linha `source` do I1 move o contexto dos hunks e os patches dos outros grupos não aplicam | alta | O plano é a fonte; aplique à mão pelo símbolo |
| Um `TMPDIR` longo faz uma asserção do kit-guard reprovar em falso | alta, se esquecido | `TMPDIR=/tmp/l5-exec` (§ Mecânica) |
| Um protótipo mata processo de outro por padrão de nome (aconteceu no planejamento) | baixa | Mate só pelo seu PID |
| A máquina disputada (load 27–62 medido no planejamento) dobra o tempo da suíte e do `health` | alta | Rodar a suíte inteira só nos pontos do § Mecânica |

**Não-feitos, declarados:**
- a linha curta sem `|` inicial colada à tabela (I2);
- o re-arm da árvore da guarda sem mutante (I6);
- o valor do grace do supervisor sem probe (I9);
- o `sdd kaizen` no checkout principal, que fica no `TODO.md` (decisão 11b).

## Verificação end-to-end

Com os 11 incrementos `done`, a métrica do `00-missao.md` se prova assim:

1. `bash tests/check-todo.sh` → `  ok    13 finding(s), all within 8 lines, carrying anchor + date, every anchor on target`.
   - `tests/health-baseline.txt` → `todo-findings 13`.
   - Contam 12 itens com `RESOLVED by` na seção aberta (o Check do I11), cada hash ancestral do topo:
     `git merge-base --is-ancestor <hash> HEAD` para cada um.
2. `./bin/sdd adr check` → rc 0, com `ok    ADR_CHECK=block, 16 ADR(s) in docs/adr` e a 0016 aceita.
3. `bash tests/run-all.sh` → `suite green`, e a última linha do `--anchors` diz quantos mutantes ainda
   aplicam (619 + os novos).
4. `bash tests/check-checkpoint.sh --check docs/handoffs/20261006-lote-5-o-que-o-lote-4-deixou/checkpoint.md` → rc 0.
5. `git -C /home/joruge/repos/sdd_agents status --porcelain` → vazio, e
   `git -C /home/joruge/repos/sdd_agents branch --show-current` → `main`. Durante a missão inteira, o
   checkout principal não foi tocado.
6. Depois dos bots, um `./bin/sdd health` verde no worktree, com o carimbo válido para o `gate_PR`.
