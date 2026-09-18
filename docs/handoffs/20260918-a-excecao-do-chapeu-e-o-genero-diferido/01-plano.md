---
missao: 20260918-a-excecao-do-chapeu-e-o-genero-diferido
data: 2026-09-18
---

# Plano — a exceção do chapéu e o gênero diferido

> **Teste de autocontenção:** este arquivo é a versão curta do plano aprovado em
> `~/.claude/plans/2026-09-18-a-excecao-do-chapeu-e-o-genero-diferido.md`. Tudo que uma sessão nova
> precisa saber está aqui e no `00-missao.md`.
>
> ⚠️ **Nunca `sdd run` no repo do kit.** Esta missão é executada **interativa com Opus**, com TDD
> por incremento: o probe entra **antes** do código e é observado RED; probe que passa de primeira é
> sabotado até ficar vermelho ou removido.

## Contexto verificado (não re-descobrir)

Lido em `a96923d`, com âncora:

- `load_config` — `bin/sdd:102`; `: "${ADR_DIR:=docs/adr}"` em `:174` é o **precedente** de chave com guarda
- `HAT_WRITES_BASE` — `:1713`, `'$TODO_FILE, tests/health-baseline.txt'`
- `hat_expand` — `:1733`; substituições **quotadas** (patsub_replacement do bash 5.2)
- `hat_writes` — `:1749`, `hat_expand "$HAT_WRITES_BASE, $own"` — **é aqui que a chave nova soma**
- `hat_path_allowed` — `:2787`; `case "$f" in $g)` — a lista expandida é **glob de shell**, por isso
  `*` numa chave vira escalada (CWE-863, PR #45)
- `hat_guard_check` — `:2801`, lê `hat_writes "$step"` em `:2816`; mensagem em `:2835` — **não nomeia remédio**
- `adr_dir_ok` — `:5703`: a guarda-modelo. Relativo, sem `..`, componentes literais
  (`''|.|..` + allowlist `*[!A-Za-z0-9._-]*`), escrita POSITIVAMENTE
- `gate_QA` Âncora 3 — `:1030-1106`: extrator `awk` (pula cercados, primeira linha em forma de
  campo) + `grep -qE '^\-[[:space:]]+\*\*Closable by:\*\*[[:space:]]+human([[:space:]]|$)'` em `:1092`.
  ⚠️ A substring `with Status: open in the registry` do `GATE_WHY` de **recusa** (`:1105`) é
  **load-bearing**: duas asserções do `check-gates.sh` a leem (`:486` e o diferencial em `:535`).
  O `GATE_WHY` de **sucesso** é `:1148`
- `cmd_install` — `:3691`; escreve só `.sdd/` e `.claude/agents/`; UX: mostra diff, `--force` adota
- `cmd_preflight` — `:3933`; o check `agent <nome> stale` em `:4203` é o molde do check novo
- `phase_hat` — a tabela passo → chapéu: os oito nomes válidos (`sdd-executor`, `sdd-qa`,
  `sdd-reviewer`, `sdd-docs`, `sdd-publisher`, `sdd-ticket`, `sdd-kaizen`, `sdd-planner`)

Sensores que a missão estende:

- `tests/check-gates.sh:516-550` — o par do gênero (`human` × `agent`, um arquivo reescrito) com
  `genre_reasons=same`. O regime `deferred` entra ao lado
- `tests/check-autonomy.sh:4838-4929` — a fronteira do chapéu. O par da chave entra ao lado
- `tests/check-preflight.sh:107` — fixture de repo-alvo com `sdd install` como controle positivo
- `tests/check-hat.sh:42` — `PLACEHOLDERS='HANDOFF_DIR|MISSION|TODO_FILE|QA_DOCS_PATH|E2E_DIR|ADR_DIR'`
  (R2). ⚠️ A chave nova **não** é placeholder — o `writes:` dos `agents/*.md` não muda
- `tests/check-mutation.sh` — `QA_bug_genre_{ignored,prefix,anywhere,fenced}` (`:239-282`),
  `RUN_hat_{guard_blind,door1_missing,door2_missing,retry_door_missing,close_door_missing}`
  (`:1175-1196`). Catálogo na base: **332 caught of 332**

Proveniência da skill: `~/.claude/skills/qa-report/assets/bug-template.md:3` é
`- **Status:** open <!-- open | fixed | verified | wont-fix | invalid -->` — a âncora abaixo da qual
o campo entra. A skill escreve bugs a partir de `<qa-docs-path>/templates/bug.md` (seed:
`assets/bug-template.md`) — **esse é o ponto de extensão**.

Alvo (`~/repos/sales_quote`, 2026-09-18): 6 bugs com `Closable by:` (5 `agent`, 1 `human`), **1**
`open`; `E2E_DIR="e2e"`, `QA_DOCS_PATH="docs/qa"`; `.github/workflows/e2e-staging.yml`,
`.claude/napkin.md` e `PRODUCT.md` existem; `docs/qa/templates/bug.md:3` é a linha `Status:`.

## Arquitetura da mudança

Duas mudanças independentes que compartilham o princípio *"o dado certo existe e o instrumento não
sabe lê-lo"*:

**A exceção do chapéu.** A fronteira do chapéu é hoje constante do **kit** (`writes:` no
`agents/*.md`). A obrigação que a cruza é do **projeto**. `HAT_WRITES_EXTRA` é a variável do
projeto, somada em `hat_writes` **por chapéu**, com guarda `hat_extra_path_ok` no molde do
`adr_dir_ok` — literal, relativo, sem `..`, sem metacaractere **exceto** o sufixo `/**`. Como a
chave **alarga permissão** e o valor vira glob de shell em `hat_path_allowed`, a guarda é a parte
que não pode falhar aberta.

**O gênero diferido.** `Closable by:` ganha um terceiro valor no **mesmo campo**, lido pelo **mesmo
extrator** — a alternação `(human|deferred)` herda as três blindagens (campo, palavra inteira, fora
de cercado) por construção. O que muda além disso é **visibilidade**: o `GATE_WHY` de sucesso
**nomeia** os deferred, que é a resposta à objeção da ADR 0006 (*"envelhece fora de vista"*).

**O seed.** `sdd install` já escreve fora do `.sdd/`; passa a semear a linha do campo em
`$QA_DOCS_PATH/templates/bug.md` (diff-first, `--force` adota, idempotente, recusa sem âncora), e o
`sdd preflight` cobra.

## Incrementos

A tabela executável vive em `checkpoint.md`. Aqui fica o **porquê** de cada fatia.

### I0 — A missão existe para o kit

Diretório da missão a partir dos templates, branch `feat/a-excecao-do-chapeu-e-o-genero-diferido`
de `main` (`a96923d`), e `sdd adr new` alocando o `docs/adr/0009-*` — **yokoten** da missão
anterior: a primeira decisão real a passar pela maquinaria que ela construiu.

⚠️ Para registro e não para refazer: a T1 **não criou** o diretório
`docs/handoffs/20260918-a-sessao-morreu-e-o-gate-levou-a-culpa/`. Existe para o git e para o
`KAIZEN_LOG.md`; não existe para o `sdd adr check --mission` nem para o ledger.

### I1 — `HAT_WRITES_EXTRA` entra pelo `load_config`, com guarda

Gramática: `hat: path[, path]; hat: path` — `;` separa chapéus, `:` separa chapéu de lista, `,`
separa caminhos. Chapéu precisa existir como `agents/<hat>.md` no `$SDD_HOME`, senão `die`. Cada
caminho passa por **`hat_extra_path_ok`**, ao lado de `adr_dir_ok`, mesma forma, com **uma** cláusula
a mais: o último componente pode ser exatamente `**`.

⚠️ `own` vazio significa *"escreve em qualquer lugar"* (`sdd-executor`) — a chave **não** deve
estreitar isso: com `own` vazio, `hat_writes` continua vazio, e a entrada para esse chapéu é aceita
e ignorada (o `preflight` avisa, I2).

### I2 — O par da fronteira, e a mensagem nomeia o remédio

Par **diferencial** no `check-autonomy.sh`: mesma sessão, um stub que comete um arquivo fora do
`writes:` do `sdd-qa`; duas corridas cuja única diferença é a linha `HAT_WRITES_EXTRA` no
`.sdd/config.sh` → `3|hat-crossed` sem a chave, `0|nada` com ela. Segundo par: a chave apontando
para **outro** chapéu não salva a QA — prova que a soma é por chapéu, não global.

A mensagem do `hat_guard_check` passa a nomear o remédio, porque o operador das três ocorrências não
tinha como saber que a exceção existe.

⚠️ Cada mutante provado num arquivo copiado **antes** de entrar no catálogo: `diff` não-vazio,
`bash -n` ok, suíte vermelha com exatamente a asserção esperada — o rito que pegou o mutante
apodrecido na r1 do PR #46.

### I3 — `deferred` na Âncora 3, visível por nome

O `grep` vira `(human|deferred)`; o laço passa a **contar** os deferred e a guardar os nomes
(`${f##*/}`, parameter expansion — nunca `$( )`). O `GATE_WHY` de sucesso ganha
`N deferred (visible, not blocking): BUG-a, BUG-b`. A substring load-bearing do `GATE_WHY` de
recusa **não muda**.

`agents/sdd-qa.md § 5.1`: **`deferred`** só quando o corpo do bug carrega a decisão humana (seção
`## Decisão`/`## Decision`, data, quem) e o handoff a cita; *"não vamos fazer agora"* sem decisão
gravada é `agent`. Ninguém ganha `Status:`.

O par do `check-gates.sh` vira **quatro regimes** no mesmo arquivo reescrito, com asserção
diferencial: `deferred` e `human` têm o mesmo veredito e `why` **diferente**.

### I4 — `sdd install` semeia o campo; `sdd preflight` cobra

Diff-first como os espelhos. Insere `- **Closable by:** agent <!-- agent | human | deferred -->`
imediatamente após a primeira linha `^- \*\*Status:\*\*`. Idempotente. **Recusa** (sem tocar o
arquivo) se a âncora não existe. Template ausente ⇒ `ok … (no QA docs tree yet)` e o `preflight`
não cobra.

### I5 — O contrato: ADR 0009, D26, docs

ADR 0009 com as alternativas recusadas; `0006` ganha **uma linha** `Amended by: 0009` (não se
reescreve ADR aceita); D26 no `CONTEXT.md`; `docs/pipeline.md` § *The review scope guard* e § QA;
verbete novo em `docs/failure-modes.md`; `.claude/rules/anatomia-do-agente.md` § 6 no **mesmo
commit** que o código do I1, pela regra da rule.

### I6 — Yokoten no alvo (passo do humano, depois do merge)

```bash
# ~/repos/sales_quote/.sdd/config.sh — as duas exceções medidas, por caminho
HAT_WRITES_EXTRA="sdd-qa: .github/workflows/e2e-staging.yml; sdd-docs: .claude/napkin.md"
# docs/qa/templates/bug.md — o sdd install --force insere abaixo de Status:
# - **Closable by:** agent <!-- agent | human | deferred -->
```

⚠️ Conferir a corrida antes de tocar o alvo: `ps -eo pid,etime,cmd | grep 'bin/sdd run'`.
`DESIGN.md` **não** entra na chave: ninguém o mediu ainda; entra no dia em que bloquear.

### I7 — Fecha: `TODO.md`, `ACHADOS`, `KAIZEN_LOG.md`

`RESOLVIDO por <hash>` em quatro itens do `TODO.md`. Fechado sai do arquivo **no chore pós-merge**
(precedente #39), então a catraca **não move** nesta missão.

## Verificação ponta a ponta

Quatro perguntas binárias — § Métrica do `00-missao.md`. Depois, **na ordem que economiza a hora**
(o catálogo com 332 mutantes leva **~55 min**):

```
tests/run-all.sh                      # os 15 sensores, verde
env -u CLAUDECODE ./bin/sdd preflight # de dentro do Claude Code precisa do env -u
git commit …                          # ÚLTIMO commit de código (I1–I5)
# → TODO.md / ACHADOS / KAIZEN_LOG (I7) — só a baseline invalida o carimbo, e ela não move aqui
gh pr create …                        # abre o PR — é o que COMEÇA os revisores
# → esperar os revisores; consertar numa LEVA só
# → ⚠️ conserto que MOVE uma linha ancorada por mutante apodrece o mutante: re-provar cada sed
./bin/sdd health --with-mutation      # carimba UMA vez, depois do último toque em bin/ tests/ templates/ config/
# → merge; chore pós-merge tira os 4 RESOLVIDO e move a catraca
```

⚠️ `sdd health` sem flag **já roda o catálogo**. Nunca como "check rápido".
⚠️ O `until pgrep -f 'bin/sdd health'` **casa consigo mesmo** — use `pgrep -f '[b]in/sdd health'`.

### QA — limite honesto

O kit não tem interface; as skills `qa-report`/`qa-execution` não se aplicam a um CLI. A QA desta
missão é a **jornada de CLI** dos quatro comandos acima rodados de verdade contra o fixture, com a
evidência no campo `gate:` do handoff — e o **I6 no alvo real** é a QA que a T1 não teve.
