# Reincidência no TODO.md — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** um achado que volta ganha uma linha `RECURRED` medida no próprio item do `TODO.md`, e a issue espelhada
ganha a label `reincidente`.

**Architecture:**
- **O token.** `RECURRED` é o primeiro token que o sensor do kit parseia. A linha é a última do item, fica fora
  do teto e da largura, e a regra 4 passa a ler a linha de cima.
- **O espelho.** O `todo-to-github-issues` lê a linha, põe ou tira a label e classifica a mudança só de
  reincidência como um `UPDATE` sem leitura humana.
- **O `retrofit-watch`.** Ele passa a mandar somar uma entrada à linha, em vez de pular o achado ou duplicá-lo.

**Tech Stack:**
- o kit: bash e um único programa awk sob `LC_ALL=C`, com `gawk 5.2.1` e `mawk 1.3.4` presentes;
- as skills: Python ≥ 3.8 sem dependências e `unittest` no `retrofit-watch`.

**Spec:** `docs/superpowers/specs/2026-10-23-reincidencia-no-todo-design.md` (neste worktree do kit).

## Global Constraints

**Onde se escreve**
- **Parte 1:** no worktree `/home/pc_admin/repos/sdd_agents-reincidencia`, nunca no `~/repos/sdd_agents`, que é o
  checkout que o `sdd` do PATH executa. Dentro dele, o `sdd` roda como `./bin/sdd`.
- **Parte 2:** num worktree próprio de `~/repos/skills`, que é um checkout compartilhado com outras sessões.

**A gramática da linha**
- **Forma:** `  RECURRED <n>: <onde> (AAAA-MM-DD)[; <onde> (AAAA-MM-DD)]*`, com dois espaços de recuo.
- **O `<n>`:** decimal sem zero à esquerda, ≥ 1, igual ao número de entradas.
- **O `<onde>`:** casa `[A-Za-z0-9][A-Za-z0-9._/-]*`. É ASCII, sem espaço, sem `#` (que geraria `REF?` no
  espelho) e sem crase (que viraria âncora). Exemplos: `dotp-remake/3.4b`, `magic_tutor/pr25`.
- **Ordem e repetição:** as datas vão da mais velha para a mais nova, nenhum `<onde>` se repete e há no
  máximo uma linha por item.
- **Posição:** é a última linha física de conteúdo do item.
- **O que a linha conta:** só as voltas. A primeira ocorrência fica no "descoberto por" (decisão do dono).

**As isenções**
- A linha bem formada não conta no teto de 8 nem na largura de 120.
- A regra 4 (data na última linha) lê a linha anterior a ela.
- Uma linha que começa com `RECURRED` mas não casa a gramática não é isenta de nada.

**O espelho e o `retrofit-watch`**
- **A label:** `reincidente`, posta quando a linha existe e tirada quando ela sai.
- **Registro decidido:** um achado decidido que volta não ganha linha. Quem o achou avisa o dono (decisão do dono).

**Compatibilidade e escrita do sensor**
- **Compatível para trás:** um `TODO.md` sem `RECURRED` dá a mesma saída de hoje, no `--check`, no
  `--check --baseline`, no `--count` e no `--anchors`.
- **O programa awk:** sem `split`, `match`, `gensub` nem `{n}`, só `index()`, `substr()` e classes ASCII. Os
  comentários dentro dele não levam apóstrofo nem crase (`check-todo.sh:321-325`, `:424-425`, `:586`).

**Commits**
- **No kit:** em pt-BR, `<tipo>(<escopo>): <o quê>`, com os trailers de atribuição da sessão.
- **No repositório de skills:** sem `Co-Authored-By` e sem "Generated with Claude Code". É o `CLAUDE.md:288-295` de
  lá, que prevalece. Conferir com `git log -1 --format='%(trailers:key=Co-authored-by,valueonly)'`, que tem de sair
  vazio.

**Entrega**
- Cada parte vai em um PR, com o fluxo do dono: `/codereview:codereview` em rodadas até nota A → PR com
  `@codex review` → `/codereview:coderabbit-pr`.
- O merge só acontece com a confirmação do dono.
- A Parte 2 só abre depois que a Parte 1 está na `main` do kit.

## Review Focus

1. **O "descoberto por" quebrado em duas linhas num item no teto, com a `RECURRED` embaixo.** A regra 4 tem de
   achar a data na segunda linha do "descoberto por", e o item fica limpo. Teste no Task 1, passo 1, caso
   `recurred-wrapped-found-by`.
2. **A `RECURRED` posta embaixo de um registro decidido.** Ela é recusada pela regra que já existe ("a decided
   record is one line"), e não aceita como isenta. Teste no Task 1, caso `recurred-under-decided`.
3. **O token escrito de outro jeito (`Recurred 1:`, `REINCIDÊNCIA 1:`).** Ele é prosa comum. Num item de 8 linhas,
   dá `9 content lines, cap is 8`, sem isenção. Teste no Task 1, caso `recurred-wrong-case`.
4. **Um alvo com `--baseline` cujo item herdado acima do teto ganha a linha.** Não aparece violação nova, porque a
   linha não conta e a chave da violação herdada não muda. É o `TEST_CMD` do `magic_tutor`. Teste no Task 1,
   caso `recurred-baseline-inherited`.
5. **A linha sai do item, porque o achado foi reescrito.** O `UPDATE` tira a label `reincidente` da issue. Teste
   no Task 7, `label_edits` com a linha removida.

---

## Parte 1 — o kit (`/home/pc_admin/repos/sdd_agents-reincidencia`)

### Task 1: O sensor mede a linha `RECURRED`

**Files:**
- Modify: `tests/check-todo.sh`, nestes pontos:
  - a declaração ao lado do `WIDTH_CAP` (`:217-219`);
  - o `-v` que leva o token ao awk (`:310`);
  - a continuação de item (`:621`), o `flush()` (`:375-434`) e o bloco de largura (`:587-598`);
  - o cabeçalho "What it measures" (`:15-35`) e o bloco de dívida declarada D15 (`:134-172`), quando houver limite
    novo;
  - os pisos `RULES_FLOOR` (`:704`) e o de probes (`:2151`);
  - um grupo de probes novo no `selftest()`, no padrão de `:1791-1884`.

**Interfaces:**
- Produces:
  - **A declaração:** a linha `RECURRED_TOKEN="RECURRED"`, na coluna 0. O espelho a lê (Task 6), então a forma
    exata é contrato: `^RECURRED_TOKEN="([A-Z]+)"[ \t]*$`.
  - **A função awk `recurred_err(s)`.** Recebe a linha já sem o recuo. Devolve `""` quando ela é uma `RECURRED`
    bem formada, e a mensagem da violação quando não é. Uma linha que não começa com `RECURRED ` (o token e um
    espaço) devolve `"not-recurred"`.
  - **As mensagens.** São texto exato, porque os testes e o `--baseline` as usam como chave. Todas saem com o
    prefixo `"  line " start ": "`:
    - `RECURRED opens with "RECURRED <n>: "`, quando o `<n>` falta, tem zero à esquerda ou não é seguido de `: `;
    - `RECURRED says <n>, lists <m>`
    - `RECURRED entry <k> is not <where> (YYYY-MM-DD)`
    - `RECURRED dates go oldest first`
    - `RECURRED names <where> twice: one entry per project and mission`
    - `RECURRED is the item's last line`
    - `one RECURRED line per item`

- [ ] **Step 1: Escrever os probes vermelhos** num grupo `rule_begin`/`rule_end` novo (o 13º). Use o `assert_clean`
  e o `assert_says` com cap 8, o `with_decided` e um caso pelo caminho `bash "$SELF" --check`, como exige o
  `CLAUDE.md:392-395` do kit. Os casos, cada um com o nome no rótulo:
  - **Os casos limpos:**
    - `recurred-at-cap`: um item com 8 linhas de conteúdo e mais uma `RECURRED 1: magic_tutor (2026-10-20)` sai
      limpo;
    - `recurred-wide`: uma `RECURRED 6: …` de 200 caracteres sai limpa;
    - `recurred-wrapped-found-by`: um item no teto, com o "descoberto por" quebrado em duas linhas e a data na
      segunda, mais a `RECURRED`, sai limpo;
    - `recurred-check-path`: com `--check` num fixture ancorado (`bin/sdd:1` (`bsym`)) mais a `RECURRED`, a saída
      contém `ok    1 finding(s)`.
  - **Os casos que o sensor recusa:**
    - `recurred-count`: com `RECURRED 2: magic_tutor (2026-10-20)`, diz `RECURRED says 2, lists 1`;
    - `recurred-blank`: com `RECURRED 1: dotp remake (2026-10-19)`, diz `RECURRED entry 1 is not <where> (YYYY-MM-DD)`;
    - `recurred-hash`: com `RECURRED 1: magic_tutor#25 (2026-10-20)`, diz a mesma mensagem;
    - `recurred-bad-date`: com `RECURRED 1: magic_tutor (2026-13-40)`, diz a mesma mensagem;
    - `recurred-order`: com `RECURRED 2: a (2026-10-22); b (2026-10-20)`, diz `RECURRED dates go oldest first`;
    - `recurred-dup`: com `RECURRED 2: a (2026-10-20); a (2026-10-22)`, diz `RECURRED names a twice`;
    - `recurred-not-last`: com uma linha de corpo depois da `RECURRED`, diz `RECURRED is the item's last line`;
    - `recurred-two`: com duas linhas `RECURRED`, diz `one RECURRED line per item`;
    - `recurred-rule4`: com uma `RECURRED` válida e a linha de cima sem data, diz `last line carries no (YYYY-MM-DD)`.
      Esse fecha o fail-open de as datas da `RECURRED` satisfazerem a regra 4;
    - `recurred-prose-wide`: com `RECURRED often; see the handoff…` de 130 caracteres, diz
      `characters on one physical line` (sem isenção) e também `RECURRED opens with "RECURRED <n>: "`;
    - `recurred-wrong-case`: com `Recurred 1: magic_tutor (2026-10-20)` num item de 8 linhas, diz
      `9 content lines, cap is 8`;
    - `recurred-under-decided`: com uma `RECURRED` na linha de baixo de um registro decidido, diz
      `a decided record is one line`.
  - **O caso do `--baseline`:**
    - `recurred-baseline-inherited`: num repo git de fixture, o commit base tem um item de 9 linhas, e o seguinte
      acrescenta a `RECURRED` a ele. O `--check --baseline HEAD~1` dá `0 new shape violation(s)`.

- [ ] **Step 2: Rodar e ver vermelho.** Rode `bash tests/check-todo.sh --selftest`. Espera-se FAIL nos casos do
  passo 1, menos o `recurred-wrong-case` e o `recurred-under-decided`, que já passam hoje. Anote quais.

- [ ] **Step 3: Implementar.** Comece declarando o `RECURRED_TOKEN` e passando-o por `-v rtok`.
  - **No bloco de largura:** isente a linha cujo texto sem recuo dá `recurred_err(...) == ""`. Esse é o único
    caminho de isenção novo.
  - **Na continuação (`:621`):**
    - se a linha sem recuo começa com `rtok " "`, guarde-a, conte-a em `rseen++`, ponha `rlast = 1` e não
      incremente o `nlines`;
    - se for qualquer outra linha, ponha `rlast = 0` e atualize o `last`, que passa a ser a última linha que não é
      `RECURRED`.
  - **No `flush()`:**
    - `rseen > 1` dá `one RECURRED line per item`;
    - `rseen == 1 && !rlast` dá `RECURRED is the item's last line`;
    - se o `recurred_err` da linha guardada não for `""`, imprima a mensagem;
    - a regra 4 continua lendo o `last`.
  - **A data das entradas:** valide mês 01–12 e dia 01–31 por comparação de string, sem calendário.
  - **O cabeçalho:** descreva a regra 6 e as exceções que ela abre nas regras 4 e 5.
  - **Os pisos:** suba o `RULES_FLOOR` para 13 e o piso de probes para o número medido.

- [ ] **Step 4: Rodar e ver verde.** Rode `bash tests/check-todo.sh --selftest` e depois `bash tests/check-todo.sh`.
  Espera-se `ok` nos dois, com o `TODO.md` do kit inalterado (`ok    39 finding(s)`).

- [ ] **Step 5: Passada de sabotagem**, uma por mensagem (`CLAUDE.md:410-417` e `:434-441` do kit). Copie o sensor
  para o scratchpad, desligue uma condição de cada vez (as sete mensagens, a isenção de largura e o `last` da
  regra 4) e rode a cópia com `--selftest`. Cada sabotagem tem de ficar vermelha num probe que nomeia a regra.
  Registre no corpo do commit: a condição desligada → o probe que caiu.

- [ ] **Step 6: Rodar os sensores vizinhos.**
  - `shellcheck -S warning tests/check-todo.sh`;
  - `bash tests/check-templates.sh`;
  - `bash tests/check-preflight.sh`.

  Espera-se 0 aviso e `ok` nos dois `check-*`.

- [ ] **Step 7: Commit.** `feat(check-todo): a linha RECURRED, medida, fora do teto e da largura`.

### Task 2: O formato e a regra para quem escreve

**Files:**
- Modify:
  - **Os templates:** `templates/todo.md` e `templates/todo.pt-BR.md`, nas linhas `:13`, `:23-24` e `:36-37`
    (`:36` no pt-BR), mais um parágrafo novo depois de "Onde vai o `RESOLVED by`".
  - **Os sensores dos templates:** `tests/check-templates.sh:485`, com um `check "$vn" 'RECURRED' …` ao lado do
    do `RESOLVED by`.
  - **Os agentes:** `agents/sdd-executor.md:111-137`, `agents/sdd-qa.md:240-257`, `agents/sdd-reviewer.md:96-97`,
    `agents/sdd-docs.md:63-72` (a DOCS confere a forma da `RECURRED`) e `agents/sdd-kaizen.md:209-233`.
  - **Os prompts de boot:** `bin/sdd:3437-3438` e `:3462-3463`.
  - **A documentação:** `CLAUDE.md:78-84` (princípio 5) e `:146-151`, e `docs/pipeline.md:388-389`.
  - **As cópias:** `.claude/agents/*`, regeneradas por `./bin/sdd install --force`.

**Interfaces:**
- Consumes: a gramática e o token do Task 1.

- [ ] **Step 1: Escrever o vermelho.** Acrescente ao `tests/check-templates.sh` o
  `check "$vn" 'RECURRED' "the kit token for a finding seen again"`. Rode `bash tests/check-templates.sh` e
  espere FAIL nas duas variantes.

- [ ] **Step 2: Escrever o parágrafo nos dois templates**, com o mesmo conteúdo e cada um no seu idioma. Em pt-BR:
  > **Reincidência.** Achado que volta (outro projeto, missão ou sessão) ganha uma entrada, nunca um item novo: a
  > última linha do item vira `RECURRED <n>: <onde> (AAAA-MM-DD); …` (token do kit, igual em todo idioma), da
  > mais velha para a mais nova, uma entrada por projeto e missão, `<onde>` sem espaço (`dotp-remake/3.4b`). A
  > primeira ocorrência fica no descoberto-por, e o `<n>` conta as voltas. A linha não conta no teto nem na
  > largura, e o descoberto-por passa para a linha de cima. Achado que está nos decididos não ganha linha: avise
  > o humano, que decide se reabre.

  Ajuste também:
  - **A `:13`:** a atribuição fica na última linha, "ou na de cima da `RECURRED`".
  - **A `:36-37`:** "leia os decididos e os abertos: o que está nos decididos não volta, e o que está nos abertos
    ganha uma entrada na `RECURRED`".

- [ ] **Step 3: Pôr a regra em cada escritor**, numa frase que aponta o template e não repete a gramática:
  "achado que já está aberto ganha uma entrada na linha `RECURRED` do item (`templates/todo.md`)". A frase vai
  nos cinco agentes, nos dois prompts de boot, no princípio 5 do `CLAUDE.md` e no `docs/pipeline.md`.
  - Na DOCS (`sdd-docs.md` §4), a conferência de forma cita a `RECURRED`.
  - No KAIZEN (`sdd-kaizen.md`), a triagem não apaga a `RECURRED` de um item que continua aberto.

- [ ] **Step 4: Sincronizar e rodar.**
  - `./bin/sdd install --force`, depois `git diff --stat -- .claude/agents`. Espera-se só os agentes do passo 3.
  - `bash tests/check-templates.sh && bash tests/check-hat.sh && bash tests/check-todo.sh --check templates/todo.md --allow-empty && bash tests/check-todo.sh --check templates/todo.pt-BR.md --allow-empty`.
    Espera-se `ok` em todos.

- [ ] **Step 5: Commit.** `docs(contrato): a reincidência no formato do TODO.md e em cada escritor`. São o
  templates, o `pipeline.md` e os agentes no mesmo commit, como manda o `CLAUDE.md:202-203`.

### Task 3: ADR 0020 e o índice

**Files:**
- Create: `docs/adr/0020-<slug>.md`, por
  `./bin/sdd adr new --slug a-recurrence-line-in-findings --spec docs/superpowers/specs/2026-10-23-reincidencia-no-todo-design.md`.
- Modify:
  - o spec, onde o `--spec` grava o link de volta;
  - `docs/superpowers/specs/2026-09-23-a-gaveta-do-kit.md`, com a linha do spec e a do plano, no formato das
    vizinhas.

- [ ] **Step 1: Alocar o ADR.** Rode o `adr new` acima e confira com `ls docs/adr | tail -1`. Espera-se a `0020`.

- [ ] **Step 2: Escrever o ADR**, em inglês e na forma da 0011:
  - `Status`, `Spec`, e as seções `## Context` / `## Decision` / `## Alternatives discarded` / `## Consequences`.
  - **Context:** o item do `/sdd-plan` voltou duas vezes sem registro, e o "e por" é uma contagem que ninguém mede.
  - **Decision:** a gramática e as isenções dos Global Constraints.
  - **Alternatives discarded:**
    - subir o teto para todo o corpo, recusado pelo histórico das 861 linhas;
    - a contagem no título, que quebra a chave do espelho;
    - o "e por" em prosa;
    - um arquivo-razão separado.
  - **Consequences:** o primeiro token que o sensor parseia, a compatibilidade para trás e o espelho que exige o
    `RECURRED_TOKEN`.

- [ ] **Step 3: Atualizar o índice.** Acrescente o spec e o plano à gaveta. Rode `bash tests/run-all.sh` e espere
  verde.

- [ ] **Step 4: Commit.** `docs(adr): 0020, a linha de reincidência nos achados`.

### Task 4: Migrar as voltas escritas à mão no `TODO.md` do kit

**Files:**
- Modify: `TODO.md`, nas faixas `:153-159`, `:175-182` e `:295-302` (medidas na `1e49e30`; remeça antes).

- [ ] **Step 1: Reescrever os três itens.**
  - **`:153-159`:** o "descoberto por" termina em `` no `dotp-remake` (2026-10-19) ``. Entra a linha
    `RECURRED 1: magic_tutor (2026-10-20)`.
  - **`:175-182`:** o "descoberto por" fica com "na 3.2b do `dotp-remake` (2026-10-19)". Entra a linha
    `RECURRED 4: dotp-remake/3.2c (2026-10-19); magic_tutor (2026-10-20); dotp-remake/3.4a (2026-10-22); dotp-remake/3.4b (2026-10-23)`.
  - **`:295-302`:** o "descoberto por" termina na missão `20261019-plano-3-2-a-magicas-de-uma-vez` (2026-10-19).
    Entra a linha `RECURRED 1: magic_tutor/pr25 (2026-10-20)`. O "também sem `.github/workflows`" passa para o
    corpo, se couber, ou sai.
  - Cada item fica com no máximo 8 linhas de conteúdo, fora a `RECURRED`.

- [ ] **Step 2: Rodar os sensores.**
  - `bash tests/check-todo.sh --check TODO.md`: espera-se `ok    39 finding(s)`;
  - `bash tests/check-todo.sh --anchors TODO.md`: espera-se `0 off target`;
  - `grep -c '^todo-findings 39$' tests/health-baseline.txt`: espera-se `1`, ou seja, a catraca não muda.

- [ ] **Step 3: Commit, só com o `TODO.md`.** `chore(todo): as três voltas escritas à mão viram RECURRED`.

### Task 5: Entregar a Parte 1

- [ ] **Step 1: Rodar a suíte.** `bash tests/run-all.sh`, depois `./bin/sdd health`, depois do último commit de
  código, para o carimbo. Espera-se tudo verde e o carimbo gravado.
- [ ] **Step 2: Revisar.** `/codereview:codereview` em rodadas, com `base=origin/main`, até nota A.
- [ ] **Step 3: Abrir o PR.** Push da branch e PR contra a `main` do kit, com `@codex review`, depois
  `/codereview:coderabbit-pr`.
- [ ] **Step 4: Merge, só com a confirmação do dono.** Use
  `gh pr merge N --merge --match-head-commit <sha>`. Depois, no `~/repos/sdd_agents`, rode
  `git fetch && git merge --ff-only origin/main`, mas só sem nenhum `sdd run` em voo
  (`pgrep -af 'sdd run'` vazio).

---

## Parte 2 — as skills (`~/repos/skills`, depois do merge da Parte 1)

### Task 6: O espelho exige um kit que conheça a `RECURRED`

**Files:**
- Modify:
  - `plugins/todo-to-github-issues/skills/todo-to-github-issues/scripts/kit.py`, ao lado do `WIDTH_CAP_RE` (`:47`)
    e no `preflight` (`:93-105`);
  - o `SKILL.md` irmão, com a linha nova na tabela de requisitos (`:22-31`).
- Test: `scripts/test_todo_format.py`, no padrão do sensor falso de `:134-143`.

**Interfaces:**
- Consumes: a declaração `RECURRED_TOKEN="RECURRED"` do Task 1.
- Produces:
  - `RECURRED_TOKEN_RE = re.compile(r'^RECURRED_TOKEN="([A-Z]+)"[ \t]*$', re.M)`;
  - `recurred_token(root: str) -> str | None`.

- [ ] **Step 0: Abrir o worktree.** `git -C ~/repos/skills fetch` e depois
  `git -C ~/repos/skills worktree add ../skills-reincidencia --no-track -b feat/reincidencia origin/main`. Todo
  o resto da Parte 2 roda ali, com `SDD_HOME=~/repos/sdd_agents`, já avançado no Task 5.
- [ ] **Step 1: Escrever o teste vermelho.** Grave um sensor falso com `RECURRED_TOKEN="RECURRED"` e espere
  `recurred_token == "RECURRED"`. Com `# RECURRED_TOKEN="RECURRED"`, espere `None`. Rode
  `python3 scripts/test_todo_format.py`: espera-se FAIL (nome indefinido).
- [ ] **Step 2: Implementar.** No `preflight(need_kit=True)`, `None` acrescenta a falha
  `the kit at {root} predates the recurrence line (tests/check-todo.sh declares no RECURRED_TOKEN) —\n      update it: git -C {root} pull`,
  com o rc 3 de sempre. Acrescente à tabela do `SKILL.md` a linha
  ``| kit com `RECURRED_TOKEN` no sensor | espelho | kit anterior à linha de reincidência: `git -C "$SDD_HOME" pull` |``.
- [ ] **Step 3: Ver verde.** Rode `python3 scripts/test_todo_format.py`: espera-se 0 FAIL.
- [ ] **Step 4: Commit, sem trailers.** `feat(todo-to-github-issues): exige o kit com a linha RECURRED`.

### Task 7: O espelho lê a linha, põe a label e classifica o `UPDATE`

**Files:**
- Modify: `scripts/todo_issues.py`, nestes pontos:
  - o `Item` (`:69-80`) e o `parse` (`:120-184`);
  - o `render_body` (`:367-398`);
  - o `update_kind` (`:603-619`) e o plano (`:579-585`);
  - os labels do apply (`:795-811`) e o resumo (`:784`).
- Modify: `SKILL.md`, a tabela "Como ler o plano" (`:70-82`).
- Test: `scripts/test_todo_issues.py`.

**Interfaces:**
- Produces:
  - `Item.recurred: str | None`: a última linha do item sem recuo, quando começa com `RECURRED `. Ela fica fora do
    `rest` e entra no `digest` como campo próprio;
  - `LABEL_RECURRING = "reincidente"`;
  - `wanted_labels(it: Item) -> set[str]`, que dá `{"todo", section_label(it.section)}`, mais `LABEL_RECURRING`
    quando `it.recurred`;
  - `label_edits(it: Item, live: list[str]) -> tuple[list[str], list[str]]`, que devolve as labels a pôr e a
    tirar;
  - o `update_kind(...)`, que passa a devolver `"anchor" | "recurrence" | "labels" | "text"`.

- [ ] **Step 1: Escrever os testes vermelhos** com o `check(...)` do arquivo:
  - `check("RECURRED line only -> UPDATE (recurrence)", kind_after(with_recurred) == "recurrence")`;
  - `check("RECURRED plus body text -> UPDATE (text)", kind_after(with_recurred_and_text) == "text")`;
  - `check("RECURRED renders as its own paragraph", "\n\nRECURRED 1: magic_tutor (2026-10-20)" in render_body(it, ctx))`;
  - `check("item with RECURRED wants reincidente", LABEL_RECURRING in wanted_labels(it_rec))`;
  - `check("line removed -> label removed", label_edits(it_plain, ["todo", sec, "reincidente"]) == ([], ["reincidente"]))`;
  - `check("OK by hash but label missing -> UPDATE (labels)", <a linha do plano daquele item começa com "UPDATE (labels)">)`,
    montado com `as_issues(..., labels=("todo", sec))`;
  - `check("todo: prefixed cleanup keeps reincidente", "reincidente" not in label_edits(it_rec, ["todo", "todo: velha", "reincidente"])[1])`.

  O TODO.md real do teste é o do kit depois do Task 4, que tem `RECURRED`. Rode
  `python3 scripts/test_todo_issues.py ~/repos/sdd_agents/TODO.md`: espera-se FAIL nos sete.
- [ ] **Step 2: Implementar.**
  - **O `parse`:** separa a `RECURRED` antes de achatar as linhas.
  - **O `render_body`:** emite a linha como parágrafo próprio, depois do parágrafo `— …` da atribuição.
  - **O `update_kind`:** compara os `norm` sem a linha `RECURRED` antes de cair em `"text"`. Com hash igual e
    `label_edits` não vazio, o plano dá `UPDATE (labels)`.
  - **O apply:** usa o `label_edits`, tanto no `CREATE` quanto no `UPDATE`. O `ensure_labels` cria a
    `reincidente`, com cor `d93f0b` e a descrição "Achado que voltou (linha RECURRED do TODO.md)".
  - **O que fica igual:** o `written` continua `k == "text"`, porque o teste de `:350` exige a string literal.
  - **O resumo:** `update=N (anchor A, recurrence R, labels L)`.
  - **O `SKILL.md`:** duas linhas na tabela, `UPDATE (recurrence)` e `UPDATE (labels)`, ambas "`--apply` sem mais
    prova".
- [ ] **Step 3: Ver verde.** Rode `python3 scripts/test_todo_issues.py ~/repos/sdd_agents/TODO.md` e
  `python3 scripts/test_todo_format.py`: espera-se 0 FAIL nos dois.
- [ ] **Step 4: Ver o plano real, sem `--apply`.** Rode
  `python3 scripts/todo_issues.py --file ~/repos/sdd_agents/TODO.md --repo j0ruge/sdd_agents`. Espera-se: 3 linhas
  `UPDATE (recurrence)`, para os três itens do Task 4, e nenhuma `UPDATE (text)` nova.
- [ ] **Step 5: Commit, sem trailers.** `feat(todo-to-github-issues): a linha RECURRED vira a label reincidente`.

### Task 8: O `retrofit-watch` manda somar a volta

**Files:**
- Modify: `plugins/retrofit-watch/skills/retrofit-watch/scripts/retrofit_watch.py:527-538`, no ramo kit do
  `describe`.
- Modify: `references/criteria.md` §7 (`:109-130`).
- Test: `tests/test_retrofit_watch.py`, no caso de `:409-415`.

- [ ] **Step 1: Escrever o teste vermelho.** No caso kit, acrescente
  `self.assertIn("RECURRED", text)` e `self.assertIn("decididos", text)`. Rode
  `python3 tests/test_retrofit_watch.py`, a partir do diretório da skill: espera-se FAIL.
- [ ] **Step 2: Implementar.** No ramo kit, depois de "no formato e com a catraca do próprio kit", acrescente:
  "; se o achado já estiver aberto lá, some uma entrada à linha `RECURRED` dele (gramática no `templates/todo.md`
  do kit), em vez de criar outro; se estiver nos decididos, só avise o dono". No `criteria.md` §7, entra o passo
  "procure o achado nos abertos e nos decididos antes de escrever".
- [ ] **Step 3: Ver verde.** Rode `python3 tests/test_retrofit_watch.py`. Espera-se OK, inclusive o
  `assertLess(len(text), 900)` do pedido de skill (`:294`), que este ramo não toca.
- [ ] **Step 4: Commit, sem trailers.** `feat(retrofit-watch): a retro do kit soma a volta na linha RECURRED`.

### Task 9: Versões, README e entrega da Parte 2

- [ ] **Step 1: Subir as versões.**
  - **O `todo-to-github-issues` vai a 2.9.0**, nestes lugares:
    - o `plugin.json:7` e o `marketplace.json:947`;
    - o `SKILL.md` `metadata.version`, hoje em 2.8.0, que passa a 2.9.0 e acaba a divergência;
    - o `CHANGELOG.md` versionado, com `## [2.9.0] — <data>`, "Minor: …" e `### Added`;
    - o changelog da sessão;
    - o README, na `:165` e nos details de `:587-597`.
  - **O `retrofit-watch` vai a 0.4.0:** o `SKILL.md:8`, o `plugin.json:7`, o `marketplace.json:1050`, o
    `CHANGELOG.md` com `## [0.4.0] — <data>` e `### Changed`, e o README na `:157`.
- [ ] **Step 2: Validar.** Rode `python scripts/validate-versions.py`: espera-se 0 erro. Confira os trailers com
  `git log origin/main.. --format='%(trailers:key=Co-authored-by,valueonly)'`: espera-se saída vazia.
- [ ] **Step 3: Revisar e abrir o PR.** `/codereview:codereview` em rodadas até nota A, e PR contra a `main` de
  `j0ruge/skills`. Depois `@codex review` e `/codereview:coderabbit-pr`. O merge só sai com a confirmação do dono.
- [ ] **Step 4: Rodar o espelho no kit, só com o "pode" do dono, porque escreve no GitHub.** Com
  `S=` o `scripts/todo_issues.py` da 2.9.0 instalada, rode `python3 $S --file ~/repos/sdd_agents/TODO.md --apply`. Depois rode o plano de novo: espera-se
  `create=0 update=0` e `gh issue list -R j0ruge/sdd_agents --label reincidente` com 3 issues.
