---
missao: 20261026-health-pula-catalogo
fase: DOCS
status: done
sessao: 4b9c28f8-7152-4e88-aae7-0bf05f85f18c
data: 2026-10-26 11:05
gate: docs em `ddb8b55` (ADRs), `3684fdd` (README, pipeline, failure-modes), `97306ce` (CLAUDE, CONTEXT), `e71d053` (QA) e `3f2d85a` (KAIZEN_LOG, K8). Sensores no HEAD `3f2d85a`, antes deste commit — `tests/check-lang.sh` rc 0 (`0 of 66 surface path(s) still in the allowlist, 0 new`); `tests/check-hat.sh` rc 0; `tests/check-adr.sh` rc 0 (`adr traceability: 79 probes`); `tests/check-health.sh` rc 0 (61 ok, 0 FAIL); `tests/check-todo.sh` rc 0 (`62 finding(s) … every anchor on target`) e `--anchors TODO.md` (`62 measured, 0 off target`); `./bin/sdd adr check --mission 20261026-health-pula-catalogo --phase plan` rc 0 (`and that ADR points back`). Uma linha `⛔`, no `tests/check-hat.sh`, com o texto proposto abaixo. Checkout principal em `cc993f7`, limpo e sem `.git/sdd-mutation`
---

# Handoff — DOCS — o `sdd health` pula o catálogo com a chave já medida

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

A doc do repo dizia o mundo de antes da missão em três frentes: o lugar velho, a regra velha de apagar e a volta
manual. Ela agora diz o que o código do `07bba49` faz. O carimbo é um conjunto de chaves em
`<git-common-dir>/sdd-mutation/stamps/<chave>`, e o mapa mora em `<git-common-dir>/sdd-mutation/killers.tsv`, com o
`.sdd/cache/` só de semente. O `sdd health` pula o catálogo sobre chave já medida, e o `--full` força. Só o veredito
do catálogo apaga uma chave, a linha 6 afirma só o que o carimbo prova, e nada volta à mão. A ADR 0021 saiu `accepted`,
com os números medidos e a semente declarada; a 0004, a 0007 e a 0016 ganharam a emenda. Há uma linha `⛔`: o
comentário "ten handoffs" do `tests/check-hat.sh`. Nada em `bin/ tests/ templates/ config/ agents/` mudou nesta fase,
então a chave do carimbo é a do `07bba49`.

## Estado do repo

- **Branch:** `fix/health-pula-catalogo`, na worktree ligada `/home/pc_admin/repos/sdd_agents-health-pula-catalogo`,
  sem push. A base é a `origin/main` `cc993f7` (PR #329), já mergeada na branch (`9a7ee1b`).
- **Último commit:** o deste `45-docs.md`, sobre `3f2d85a`.
- **Working tree:** limpa depois do commit.
- **Suíte:** não rodou inteira nesta fase (é do relay, sobre este HEAD). A do `093a02b` deu rc 0, 539 s, 2059 `ok`,
  0 `FAIL`. Rodaram os sensores que leem o que esta fase tocou (frontmatter, acima).
- **A chave:** `git diff --quiet 07bba49 HEAD -- bin tests templates config agents` → igual. Esta fase só escreveu
  `README.md`, `CLAUDE.md`, `CONTEXT.md`, `KAIZEN_LOG.md`, `docs/` e a pasta da missão.
- **E2E:** não se aplica (o kit não declara `E2E_CMD` nem `APP_URL`).

## O que foi feito

- `ddb8b55`, **as ADRs**:
  - **0021:** `proposed` → `accepted`. O `Amends` cobre as duas metades da regra de remoção da 0004 (r1 #7) e a linha
    6 da 0007. "Four days older" ganhou o commit e as datas (`981fd82`, 2026-10-21; o #327 em 2026-10-25), e "16
    handoffs" ganhou a medida (r1 #8). A §5 não diz mais "(and leaving when they have no killer, as before)". As
    Consequences declaram a ressurreição pela semente e a transição.
  - **0004:** o `Amended by` e duas notas no corpo (§1 e a Consequence de remoção).
  - **0007:** a linha 6, pedida pelo dono.
  - **0016:** uma nota na Consequence que mandava copiar o mapa.
- `3684fdd`, **a superfície inglesa**:
  - **`README.md`:** o conjunto, o pulo, o `--full` e a regra de apagar, mais a linha de uso `sdd health --full`.
  - **`docs/pipeline.md`:** o pulo em "Who measures the gates" e o requisito do `gate_PR` reescrito.
  - **`docs/failure-modes.md`:** os três estados da recusa e o tempo do catálogo medido no #327. A receita da chave
    aponta o diretório dos carimbos. O verbete "slow again after a kit mission" sem a união e sem a cópia. E o
    aviso do git < 2.31 com o escopo do F1.
- `97306ce`, **`CLAUDE.md` e `CONTEXT.md`:**
  - **`CLAUDE.md`:** o pulo e o `--full` ao lado do hábito (`:299`), e o mapa no common dir (`:311`).
  - **`CONTEXT.md`:** o verbete "Carimbo de mutação".
- `e71d053`, **o `docs/qa/`:**
  - **as jornadas:** `J-health-verdict`, `J-certify-mission-close` e a nota da `J-target-repo-ships`;
  - **o resto:** o `docs/qa/README.md` e o cenário `HLT-stamp-removed-on-red`.
- `3f2d85a`, **o `KAIZEN_LOG.md`:** a entrada K8.

## Drift checklist

| Area touched by the diff | Corresponding document | Status | Evidence |
|---|---|---|---|
| `bin/sdd` (`mutation_stamp_dir`, `mutation_stamp_valid`: o carimbo como conjunto, I1 `956bd24`) | `README.md` | ✅ | § "In the kit repo it is also a gate", em `3684fdd` |
| `bin/sdd` (o carimbo como conjunto, I1) | `docs/pipeline.md` | ✅ | § do `gate_PR`, "In a repo that owns a mutation catalogue…", reescrito em `3684fdd` |
| `bin/sdd` (o carimbo como conjunto, I1) | `CONTEXT.md` | ✅ | verbete "Carimbo de mutação", em `97306ce` |
| `bin/sdd` (o carimbo como conjunto, I1) | `docs/adr/0004-mutation-catalogue-owner-stamp-not-ci.md` | ✅ | nota no §1, em `ddb8b55` |
| `bin/sdd` (o carimbo como conjunto, I1) | `docs/qa/journeys/J-certify-mission-close.md` | ✅ | os nós E, F e G5, o `true_end_state` e o `crosses`, em `e71d053` |
| `bin/sdd` (`cmd_health`: o pulo, `--full`, `--with-mutation` sinônimo, `--full --release` recusado, I2 `6dbd63c`) | `README.md` | ✅ | o mesmo §, parágrafo "Over content whose key is already in the set…", e a linha de uso `sdd health --full`, em `3684fdd` |
| `bin/sdd` (o pulo, I2) | `docs/pipeline.md` | ✅ | § "Who measures the gates", a frase do pulo com a linha `catalogue skipped`, em `3684fdd` |
| `bin/sdd` (o pulo, I2) | `CLAUDE.md` | ✅ | o hábito `sdd health --with-mutation` (`:299`) ganha o pulo e o `--full`, em `97306ce` |
| `bin/sdd` (o pulo, I2) | `CONTEXT.md` | ✅ | o mesmo verbete, em `97306ce` |
| `bin/sdd` (o pulo, I2) | `docs/qa/journeys/J-health-verdict.md` | ✅ | o ramo S, os nós A2 e A3, os passos 2, 3 e 5, as notas, em `e71d053` |
| `bin/sdd` (o pulo, I2) | `docs/qa/README.md` | ✅ | § Entry points e a 1ª das duas cautelas, em `e71d053` |
| `bin/sdd` (check 2c: só o veredito do catálogo apaga, a janela não grava nem apaga, I2 `11fe1fe`, `291d9af`) | `docs/pipeline.md` | ✅ | o mesmo § do `gate_PR`, em `3684fdd` |
| `bin/sdd` (a regra de apagar, I2) | `docs/failure-modes.md` | ✅ | § "The `PR` gate refuses", os três estados, em `3684fdd` |
| `bin/sdd` (a regra de apagar, I2) | `docs/adr/0004-mutation-catalogue-owner-stamp-not-ci.md` | ✅ | o `Amended by` com a 2ª metade (r1 #7) e a nota na Consequence, em `ddb8b55` |
| `bin/sdd` (a regra de apagar, I2) | `docs/adr/0021-the-stamp-lives-in-the-common-dir.md` | ✅ | o `Amends` com as duas metades (r1 #7), em `ddb8b55` |
| `bin/sdd` (a regra de apagar, I2) | `docs/qa/journeys/J-health-verdict.md` | ✅ | o nó K2 e os seus três ramos, o K1, o `true_end_state` e os abandonos 1 e 3, em `e71d053` |
| `bin/sdd` (a regra de apagar, I2) | `docs/qa/scenarios/HLT-stamp-removed-on-red.md` | ✅ | `title`, `expected` e o corpo, em `e71d053` |
| `bin/sdd` (a regra de apagar, I2) | `README.md` | ✅ | "Only the catalogue's own verdict … takes a key away", em `3684fdd` |
| `bin/sdd` (`health_release`, linha 6, `291d9af`) | `docs/adr/0007-apt-for-another-repo-is-six-green-lines.md` | ✅ | a linha 6 da tabela, o parágrafo abaixo dela e o `Amended by`, em `ddb8b55` (emenda pedida pelo dono) |
| `bin/sdd` (`cmd_preflight`, o aviso do git < 2.31 com `has_mutation_catalogue`, F1 `c0adac8`) | `docs/failure-modes.md` | ✅ | § "`sdd preflight` warns: this git does not know `--path-format`", "How the kit reacts", em `3684fdd` |
| `bin/sdd` (o aviso do git < 2.31, F1) | `docs/qa/journeys/J-target-repo-ships.md` | ✅ | nota "Update (`20261026-health-pula-catalogo`, F1 `c0adac8`)", em `e71d053` |
| `bin/sdd` (o comentário do `--with-mutation` em `cmd_health`, "sixteen handoffs") | — | n/a | bate com a medida: `git grep -l 'sdd health --with-mutation' c114e36 -- docs/handoffs` lista 16 arquivos, de 5 missões, a mesma conta que a ADR 0021 cita agora (r1 #8) |
| `bin/sdd` (`cmd_help`, a linha `[--full]`) | — | n/a | a ajuda é o próprio documento (`bin/sdd:12030–12034`, a linha `[--full]` em `:12032`), e o `README.md` ganhou a linha de uso (acima) |
| `bin/sdd` (`git_common_dir_abs`, extraído do `ledger_repo_root`, I1 `b7667e4`) | — | n/a | refactor interno; nenhum doc nomeia a função, e o § path-format do `docs/failure-modes.md` descreve o fallback, que não mudou |
| `tests/check-mutation.sh` (`killers_paths`, `load_killer_maps`, `write_killer_map`: o mapa no common dir com a semente, I3 `4ae37c9`, `3e728d6`) | `CLAUDE.md` | ✅ | `:311`, o mapa em `<git-common-dir>/sdd-mutation/killers.tsv`, em `97306ce` |
| `tests/check-mutation.sh` (o mapa, I3) | `docs/failure-modes.md` | ✅ | § "`sdd health` in the main checkout is slow again after a kit mission", reescrito em `3684fdd` |
| `tests/check-mutation.sh` (o mapa, I3) | `docs/adr/0021-the-stamp-lives-in-the-common-dir.md` | ✅ | a §5 corrigida, e a ressurreição pela semente e a transição nas Consequences, em `ddb8b55` |
| `tests/check-mutation.sh` (o mapa, I3) | `docs/adr/0016-the-mission-checkpoint-and-the-kit-worktree.md` | ✅ | nota na 2ª Consequence, em `ddb8b55` |
| `tests/check-mutation.sh` (17 mutantes novos, catálogo 775 → 792) | — | n/a | nenhum doc vivo escreve o tamanho do catálogo: um grep por 775 e 792 em `README.md`, `CLAUDE.md`, `CONTEXT.md`, `docs/pipeline.md`, `docs/failure-modes.md` e na anatomia só acha números históricos; o `KAIZEN_LOG.md` registra o 775 → 792 em `3f2d85a` |
| `tests/check-hat.sh` (`release_probes`, o comentário "a habit written in ten handoffs", tocado pelo I2) | `tests/check-hat.sh` | ⛔ | função `release_probes`, o comentário antes da probe `health: --with-mutation is accepted as a synonym, not refused` (hoje `:785–787`); texto em "Texto proposto" (r1 #8) |
| `tests/check-gates.sh`, `tests/check-health.sh`, `tests/check-preflight.sh`, `tests/check-hat.sh` (as asserções dos Checks I1–I5, F1, F2 e R1) | — | n/a | asserções e mundos de fixture. O que elas provam está nos docs acima, e nenhum doc descreve os fixtures. O número de sensores não mudou: `ls tests/check-*.sh` dá 16 no HEAD e no `cc993f7` |
| `commands/sdd-plan.md` (passo 2: nada se copia e nada volta, I4) | `commands/sdd-plan.md` | ✅ | escrito pelo I4 em `20ea32e`, e segurado pela probe `command_worktree_return_probes` do `tests/check-hat.sh` |
| `commands/sdd-plan.md` (I4) | `docs/failure-modes.md` | ✅ | o verbete que o passo velho citava perdeu a receita da volta, em `3684fdd` |
| `TODO.md` (`RESOLVED by` nos dois achados, I5; `RECURRED 6` e `7`) | `TODO.md` | ✅ | `7e68e7d`, `f7f6cc2` e `19dbe32`; conferido abaixo, só leitura nesta fase |
| `docs/adr/0021-the-stamp-lives-in-the-common-dir.md` (nova, no PLAN) | `docs/adr/0021-the-stamp-lives-in-the-common-dir.md` | ✅ | `f4ac7fd`, alinhada ao código em `ddb8b55`; `./bin/sdd adr check --mission 20261026-health-pula-catalogo --phase plan` → `and that ADR points back` |
| `docs/adr/0004-mutation-catalogue-owner-stamp-not-ci.md` (o `Amended by` do PLAN, `73420e7`) | `docs/adr/0004-mutation-catalogue-owner-stamp-not-ci.md` | ✅ | ampliado em `ddb8b55` (acima) |
| `docs/adr/0016-the-mission-checkpoint-and-the-kit-worktree.md` (o `Amended by` do PLAN, `73420e7`) | `docs/adr/0016-the-mission-checkpoint-and-the-kit-worktree.md` | ✅ | a nota no corpo em `ddb8b55` (acima) |
| missão inteira (antes e depois medidos; `kaizen_log:` vazio no `00-missao.md`) | `KAIZEN_LOG.md` | ✅ | entrada "2026-10-26 — O `sdd health` pula o catálogo com a chave já medida", com o id da missão na linha **Missão:**, em `3f2d85a` |
| a cópia do mapa na worktree (o `/sdd-plan` velho) | `.claude/rules/anatomia-do-agente.md` | n/a | a anatomia não cita a cópia: um grep por `mapa`, `killer`, `mutation-killers` e `.sdd/cache` não acha linha sobre ela. O §6 diz que a missão do kit roda numa worktree com `./bin/sdd`, o que segue certo. O §4 (`:165`, "catálogo de mutação com carimbo no `sdd health`") também segue |
| termos (o conjunto de chaves, a semente, o pulo) | `CONTEXT.md` | ✅ | nenhum verbete novo. O carimbo já tinha o seu, reescrito em `97306ce`. A semente e o pulo moram dentro dele e na ADR 0021, como a 0016 e a 0017 entraram, citadas em verbetes que já existiam |
| `config/` | — | n/a | nenhuma chave de config nova: `--full` é flag de comando, não chave do `.sdd/config.sh` |
| `agents/`, `templates/` | — | n/a | um grep por `mutation-stamp`, `mutation-killers`, `with-mutation` e `killer map` em `agents/` e `templates/` não acha nada. O `agents/sdd-publisher.md:38` ("a stamp that only `sdd health` writes") segue certo, e nada ali mudou |
| `docs/handoffs/20261026-health-pula-catalogo/**` | — | n/a | artefatos da própria missão, não documentação viva |

## Texto proposto
<!-- sdd:proposed -->

O trecho é do `tests/check-hat.sh`, que o `writes:` do `sdd-docs` não cobre. **Aplicar antes do carimbo do
operador, ou recusar**: `tests/` está na chave, e aplicado depois do carimbo ele custa um catálogo inteiro. É só
comentário, e nenhuma probe lê o número. O `bin/sdd:7315` diz "sixteen handoffs", que bate com a medida, e este diz
"ten", que nem no `d47e756`, o commit que o escreveu, era a conta (13 arquivos ali).

Em `tests/check-hat.sh`, função `release_probes`, o comentário de três linhas antes da probe
`health: --with-mutation is accepted as a synonym, not refused` (hoje `:785–787`), trocar:

```bash
  # `sdd health --with-mutation` is a habit written in ten handoffs; the flag is a synonym of the
  # default (the catalogue, skipped over a key already measured; ADR 0021), so it is accepted and
  # never refused as an unknown option.
```

por:

```bash
  # `sdd health --with-mutation` is a habit written in sixteen handoffs and in CLAUDE.md (ADR 0021);
  # the flag is a synonym of the default (the catalogue, skipped over a key already measured), so it
  # is accepted and never refused as an unknown option.
```

## Achados do `TODO_FILE` conferidos nesta missão

`bash tests/check-todo.sh` → `ok    62 finding(s), all within 8 lines, carrying anchor + date, every anchor on target`;
`--anchors TODO.md` → `ok    anchors: 62 measured, 0 off target`. Só leitura: o `TODO.md` não mudou nesta fase (M4, e
ordem do relay), e não rodei `--fix` nem `--apply`.

- **Os dois que a missão fecha** estão bem formados e levam o `RESOLVED by` do I5 (`7e68e7d`):
  - "O `sdd health` refaz o catálogo inteiro mesmo com o carimbo valendo para o conteúdo" (`TODO.md:26`, âncora
    `bin/sdd:7371` (`--with-mutation`), com o `RESOLVED by 6dbd63c` e `` `11fe1fe` `` em `:32`);
  - "O mapa de tempos do catálogo de mutação mora no checkout…" (`TODO.md:510`, âncora `tests/check-mutation.sh:7818`
    (`KILLERS_FILE`), com o `RESOLVED by 4ae37c9` e `` `3e728d6` `` em `:516`).

  Os dois seguem na seção aberta, como o ciclo de vida manda: saem no chore pós-merge, quando os quatro hashes
  estiverem na `main`.
- **As duas reincidências** da missão são linhas `RECURRED` de um item que já existia, a forma que o §4 confere:
  - a `RECURRED 6`, do planner (`f7f6cc2`);
  - a `RECURRED 7`, do executor (`19dbe32`), hoje em `TODO.md:233`.
- **Nenhum achado novo entrou.** A M4 trava a catraca em 62, e os achados fora de escopo do EXEC, da QA e da REVIEW
  vão ao chore pós-merge, com a lista no `40-review-r2.md` § *Para o chore pós-merge*.
- **Nenhum foi refutado nem decidido** por esta missão, então nada passou para `<!-- sdd:decided -->`.

## Boot da próxima fase

**Próxima: PR.** A `gate_DOCS` lê este arquivo. As regras do lugar seguem as do `40-review-r2.md` § *Boot da próxima
fase*: nunca o `sdd` do PATH na worktree, e nunca `./bin/sdd health`, `run` ou `status` antes da hora do carimbo.

- **Leia primeiro:** este TL;DR, a linha `⛔` e o "Texto proposto".
- **O corpo do PR** leva:
  - a linha `⛔` do `tests/check-hat.sh` (o `gate_PR` confere que o documento aparece numa linha com `⛔`);
  - o antes e o depois do `KAIZEN_LOG.md`;
  - as Pendências abaixo, mais as do `40-review-r2.md`.
- **A ordem do dono:**
  1. `@codex review` e os bots, e os consertos numa leva;
  2. aplicar ou recusar o `⛔`;
  3. o carimbo do operador, uma vez: `cd /home/pc_admin/repos/sdd_agents-health-pula-catalogo && ./bin/sdd health`.
     O health tem de imprimir a linha `== killer map: 775 mutant(s) run their last killer first … ==`
     (`20-handoff-exec.md` § *A pendência do operador*);
  4. o merge, como merge commit;
  5. a M3 e o chore pós-merge.

## Pendências / Decisions for a Human

- **O `⛔` do `tests/check-hat.sh`:** aplicar antes do carimbo do operador, ou recusar. É comentário, e depois do
  carimbo custa um catálogo.
- **A ADR 0021 saiu `accepted` nesta fase.** Segui o precedente da 0016, da 0017 e da 0018, aceitas no fecho das suas
  missões (`6bc4b37`, `54e2f18`, `93bc43d`), sobre o plano que o dono aprovou (`aprovacao: humano-2026-10-26`). A
  **0020** segue `proposed`, e ela é de outra missão, então não a toquei. O achado do `sdd approve` que commita o ADR
  sem tirar o `proposed` (`TODO.md:378`) segue aberto.
- **Seguem com o dono, sem mudança desde a r2** (`40-review-r2.md` § *Pendências*):
  - **a ressurreição pela semente:** a ADR 0021 agora a declara, como o dono decidiu, e o comentário do
    `write_killer_map` já a declarava (`tests/check-mutation.sh:7827–7835`);
  - **a cópia do kit sem `.git` dentro de outro repositório:** guardar ou declarar. Não escrevi nada na doc sobre
    ela, porque declarar é uma das duas saídas, e a escolha é do dono;
  - **o carimbo do operador, a M3 e o chore pós-merge.**

## Riscos e não-feitos

- **A suíte inteira não rodou sobre estes commits.** Rodaram os sensores que leem o que a fase tocou: `check-lang`,
  `check-hat`, `check-adr`, `check-health`, `check-todo`, `--anchors` e `sdd adr check`. A suíte é do relay, sobre
  este HEAD.
- **Os fluxogramas mermaid das jornadas não passaram por um parser.** Os rótulos com `--`, `==`, `*` ou parênteses
  vão entre aspas, mas ninguém renderizou o diagrama. Nenhum sensor lê o `docs/qa/journeys/`.
- **Drift anterior à missão, que deixei como estava** porque nada nesta missão o tornou falso:
  - o "20-50 min" do catálogo no `docs/qa/personas.md:79`, nos cenários `HLT-stamp-window-refused` e
    `GATE-pr-refuses-stale-stamp` e nas charters `CH-catalogue-floor-under-garbage` e
    `CH-stamp-round-trip-from-a-worktree`;
  - o `tests/run-all.sh (~1m50s)` do `docs/qa/README.md`;
  - o "4 dos 8 caminhos" (#67) do verbete do carimbo no `CONTEXT.md`, que hoje são 5 com o `agents/`;
  - o "md5 of bin/ tests/ templates/ config/" do `GATE-pr-passes-on-fresh-stamp`.

  Corrigi só o que estava nas frases que reescrevi. Os planos e as specs datados do `docs/superpowers/` citam o
  `.sdd/logs/mutation-stamp`, e são registro datado, não doc viva.
- **O `CLAUDE.md` cresceu quatro linhas** (584 → 588), num índice já longo. A profundidade foi para a ADR 0021 e para
  o `CONTEXT.md`, e o `CLAUDE.md` só ganhou o ponteiro e a frase do pulo.
- **O sdd-docs também rodou como agente genérico** nesta missão, porque o tipo não estava registrado na sessão.
  Isso seria a 8ª ocorrência na linha `RECURRED 7` (`TODO.md:233`), que passaria a `RECURRED 8`. Não a escrevi, porque o `TODO.md` é só leitura nesta
  fase: fica para o relay e o chore.
