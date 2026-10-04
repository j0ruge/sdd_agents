---
missao: 20261003-lote-3-a-catraca-desce
data: 2026-10-03
---

# Plano — Lote 3: a catraca desce

> **Teste de autocontenção:** uma sessão nova, sem nenhuma memória da conversa que gerou este
> plano, lendo apenas `00-missao.md` + `01-plano.md` + `checkpoint.md`, consegue executar?
> Se a resposta for "só se souber X", **X vai escrito aqui**.

**Como esta missão é executada (decisão 6).** Interativa, por UMA sessão do Claude Code no checkout
`/home/joruge/repos/sdd_agents`, incremento a incremento, na ordem do `checkpoint.md`. **Nunca**
`sdd run`. Cada incremento segue a ordem:
1. Red observado pelo motivo certo;
2. conserto;
3. sabotagem do conserto;
4. sensores;
5. re-âncora do `TODO.md`;
6. o commit do incremento: um por item de conserto; as saídas de um mesmo I1, I2 ou I3 vão num
   commit só, pelo precedente `7ee1c3e`, a varredura D15 que tirou 5 itens num commit;
7. por último, o padrão da casa (medido em `20261002-onde-o-comando-do-humano-escreve`): um commit
   SEPARADO `chore(checkpoint): I<n> done (<hash>)` com a linha do `checkpoint.md` (Status `done`,
   hash curto nu do commit do passo 6 na célula Commit) e uma nota em `checkpoint-notas.md` (append,
   `>>`).

**Antes do I1 (passo 0).** Este plano fechou o gate com `aprovacao: auto`. Nesse caso o
`sdd approve` responde `plan … is already approved — nothing to do` (`cmd_approve`, `bin/sdd`):
não troca de branch nem commita nada. E esta missão não usa `sdd run`, que faria o checkout. Então,
à mão, a partir da `main` atualizada (`git switch main && git pull --ff-only`):
1. `git switch -c fix/lote-3-a-catraca-desce`;
2. `git add docs/handoffs/20261003-lote-3-a-catraca-desce/`;
3. commit `docs(plan): plano e checkpoint de 20261003-lote-3-a-catraca-desce`.

Se a `main` andou desde `5d55571`, os números de linha deste plano deslocam: ache pelo símbolo. A
catraca de partida é a da `main` nova; se mudou, ajuste os Checks do I1–I3 e diga isso numa nota.

## Contexto verificado (não re-descobrir)

Tudo abaixo foi medido em 2026-10-03 sobre `main` = `5d55571`, árvore limpa. Os números de linha
envelhecem a cada commit: ache pelo **símbolo** citado, nunca só pelo número.

### Estado e números de partida

- `bash tests/check-todo.sh` → `  ok    57 finding(s), all within 8 lines, carrying anchor + date,
  every anchor on target`. A catraca: `tests/health-baseline.txt:26` = `todo-findings 57`. Ela
  mora fora do `TEST_CMD` (só o `sdd health` a cobra), mas **toda** remoção ou acréscimo de item
  move a linha no **mesmo commit** (CLAUDE.md, princípio 5).
- **N**, em todo este plano: os achados que nascem durante a leva (decisão 5). N ≥ 1, porque o
  `kaizen_reminder` já nasceu no planejamento (I14). Na branch, a catraca termina em 35 + N; depois
  do merge, em 22 + N.
- Espelho: 57 issues `todo` abertas em `j0ruge/sdd_agents`, mapeadas por título; o re-sync é passo
  pós-merge, nunca desta branch.
- Carimbo de mutação **válido** na `main` (`sdd health` verde, 580/580, `edd14ad2…`, 39 min).
  Chave = conteúdo rastreado de `bin tests templates config` menos `tests/health-baseline.txt`
  (`bin/sdd:2044-2045`, `MUTATION_STAMP_PATHS`/`MUTATION_STAMP_EXCLUDE`). `agents/`, `commands/`,
  `docs/`, `CLAUDE.md`, `CONTEXT.md`, `TODO.md` e `.claude/` **não** mexem na chave. `agents/`
  está em `KIT_BEHAVIOR_PATHS` (`bin/sdd:3584`, cunha `kit_rev`), o que não importa aqui.
- O catálogo tem **580** mutantes (`grep -cE '^mut_[A-Za-z0-9_]+\(\)' tests/check-mutation.sh`).
  Esta leva acrescenta **12** (2 em cada um dos I11 a I16) e reancora 1
  (`RUN_review_scope_handoff_dir_verbatim`, no I11): 580 → **592**. Nenhum mira `tests/`, porque
  `apply_mutant` (`tests/check-mutation.sh`, ~:5878) só sabota `bin/`.

### Mecânica da casa que todo incremento usa

- **Suíte:** `bash tests/run-all.sh` → última linha `suite green` (rc 0), ~5 min. Rode-a inteira
  depois do I3, do I10, do I16 e no I20. Entre elas, rode antes de cada commit o(s) sensor(es) que
  o incremento toca, mais `bash tests/check-todo.sh`, `bash tests/check-lang.sh` e
  `bash tests/check-pipefail.sh` sempre que `tests/` ou `bin/` mudarem.
- **Mutante novo** = função `mut_<SLUG>() { sed -i '…' "$1"; }` em `tests/check-mutation.sh`
  (modelo: `mut_QA_handoff_status_enum_open`, `:567`, sed com endereço de faixa
  `/^gate_QA() {/,/^}/` e âncora em CÓDIGO, nunca em número de linha) **mais** o `<SLUG>` no array
  `CATALOG=(` (`:5245`). Prove com `tests/check-mutation.sh --only <SLUG> <sensor>`: o sensor é
  **nome nu** (`check-gates.sh`); com caminho (`tests/check-gates.sh`) o comando sai rc 2. A linha
  verde é `  ok    <SLUG> — check-gates.sh dies (rc 1)` (~75 s contra `check-gates.sh`, que roda em
  ~72 s com prazo de 600 s). Depois rode `tests/check-mutation.sh --anchors` (segundos): todo
  mutante tem de **aplicar**.
- **Sensor que a mutação não alcança** (tudo em `tests/`, mais `check-todo`, `check-checkpoint`,
  `check-templates`, `check-lang`, `check-pipefail`, `check-hat`): a regra nova ganha probe no
  `selftest()` e o executor faz a **passada de sabotagem**. Degrade a regra (as sabotagens estão
  listadas em cada incremento) e exija o selftest vermelho em cada uma. Primeiro prove que a
  sabotagem **aplicou**: probe que não mudou o arquivo conclui em falso. Ajudante: o
  `~/.claude/plans/2026-10-03-helpers/sab.sh <nome> <arquivo> '<perl-expr>' <sensor>`, que clona o
  kit, aplica um `perl -0pi -e`, morre alto se nada mudou e roda o sensor.
- **Âncoras do `TODO.md` deslocam a cada commit que move linhas** em `bin/sdd` ou `tests/*.sh`:
  ~50 itens abertos ancoram em arquivos que esta leva edita. `check-todo.sh` está no `TEST_CMD`, e
  uma âncora fora de alcance o deixa vermelho. Antes de cada commit:
  - `bash tests/check-todo.sh --anchors TODO.md` lista as âncoras e imprime "nearest X is at line
    N" para as que saíram do alcance. Reancore para essa linha no mesmo commit.
  - O alcance é de 10 linhas, e várias âncoras têm só 2 de folga:
    - `tests/run-all.sh:374` (#169);
    - `tests/check-mutation.sh:5940` (#192);
    - `tests/check-checkpoint.sh:174` (#211);
    - `tests/check-todo.sh:293` (#77, que sai no I3).
  - Ajudantes: `~/.claude/plans/2026-10-03-helpers/remap.py <rev-anterior>` reescreve a 1ª âncora
    de cada item. `xref.py HEAD --fix` realoca as demais pelo conteúdo; rode SEMPRE os dois, porque
    o `remap.py` sozinho perde as secundárias.
  - Confira pelo conteúdo: `git show HEAD:<arquivo> | sed -n '<N>p'`. Aqui o pipe é de shell, não
    de Check.
- **Hook do repo** (`.claude/settings.local.json`, PostToolUse no Bash). Todo comando Bash cujo
  TEXTO contém `git commit` apaga:
  - os diretórios `scratchpad/*/` (um nível) que tenham `bin/sdd`;
  - os `/tmp/sdd-*` com mais de 10 min.

  Clone de rascunho mora **dois níveis** abaixo do scratchpad (`scratchpad/x/sub/kit`). Nunca
  commite com um `sdd health` rodando.
- **Shell é zsh:**
  - nunca use `path` como nome de variável (é amarrada ao `PATH`);
  - escreva `"${r}:arquivo"`, nunca `$r:arquivo` (o `:t` é comido);
  - `echo ====` falha;
  - não há `/dev/tcp`;
  - antes de concluir que um arquivo não existe, prove que o diretório-pai existe.
- **Espelho dos agentes:** `agents/sdd-*.md` → `.claude/agents/` só por `./bin/sdd install --force`
  (nunca `cp`, nunca Edit). Hoje os 8 são byte a byte iguais (`cmp -s`). O `sdd preflight` reprova
  `agent <nome> stale`.
- **Idioma:**
  - `bin/`, `agents/`, `docs/`, `README.md`, `config/schema.md`, `config/starter.conf` e `tests/`
    são superfície **inglesa**. Quem cobra é o `tests/check-lang.sh` (`  ok    0 of 56 surface
    path(s) still in the allowlist, 0 new`).
  - `TODO.md`, `CONTEXT.md`, `CLAUDE.md`, `KAIZEN_LOG.md`, `templates/` e os handoffs falam pt-BR.
  - O slug `20261003-lote-3-a-catraca-desce` não tem stopword do `check-lang`, então pode ser
    citado em comentário de `tests/` (o I3 o usa).
- **Checks** (`templates/checkpoint.md`, cobrado por `tests/check-checkpoint.sh`, que escaneia ESTE
  checkpoint também):
  - Célula com `2>&1` e `grep` exige **todo** `grep` ancorado em `^  ok    `
    (`count_occ 'grep'` contra as âncoras, `scan_file` ~:176). Por isso as contagens de arquivo nas
    células mistas usam `awk`.
  - Nunca `|` cru, nem `||`.
  - O `run-all.sh` imprime `suite green` sem o prefixo ok (`:394`), então se lê pelo rc.
- **Formato do `TODO.md`:**
  - **Item aberto:** teto de 8 linhas físicas e 120 caracteres por linha. Âncora `arquivo:linha`
    com um símbolo da cabeça a até 10 linhas.
  - **Registro decidido:** UMA linha física (`tests/check-todo.sh` ~:484-512):
    `- **<título sem *>** — <o quê e porquê> — `<evidência>` (YYYY-MM-DD)`. Sem caixa, com um code
    span depois do título, terminando na data.
  - **Conserto por commit:** o corpo ganha ` RESOLVED by <hash>`, e o item só sai no chore
    pós-merge (`templates/todo.pt-BR.md` § Ciclo de vida).
- **Commits** `<tipo>(<escopo>): <o quê>` com o porquê no corpo, um por item, com o trailer da
  sessão. Exemplos: `fix(runner)`, `test(checkpoint)`, `chore(todo)`, `docs(plan)`.

### Fatos por item (o detalhe de cada um está no incremento)

- **#138 refutado:** `git show 148f693:bin/sdd | sed -n '1621p'` → `finding that does not fit this
  mission goes to $TODO_FILE, never to the diff.`; `.sdd/config.sh:11` `TODO_FILE="TODO.md"`.
- **#187 refutado:**
  - `coordination_enter` (~`bin/sdd:10598`) só deixa `status --no-gates` entrar sem trava;
  - `cmd_status` (`:6567`) avalia todo gate;
  - a trava é `fcntl.LOCK_EX | fcntl.LOCK_NB` (`bin/sdd-coordination.py:504`), que não enfileira.
- **#214:** as linhas KAIZEN são `$meta` e saem do eixo nos dois leitores (`bin/sdd:9943-9944`,
  `:9210-9212`). O que o humano lê é `bad "BLOCKED in KAIZEN — two sessions without satisfying the
  gate: $GATE_WHY"` (~`:10420`).
- **#181:** `docs/adr/0009-the-genre-gains-deferred-and-hats-gain-project-exceptions.md` ~:77-83
  mantém recusada a alternativa (A) da 0006.
- **#102:** o selftest do `check-lang` afirma de propósito que slug em prosa é pego (`exit 95`,
  `tests/check-lang.sh:130-144`). A isenção de linha `Spec:`/`ADR:` é `ADR_LINK_LINE` (~:82-84).
- **#152:** `f7bcf10` (`feat(install): seed Closable by: in the qa bug template, and make
  preflight ask`). O `agents/sdd-qa.md:98-100` manda marcar.
- **#74:** `tests/check-checkpoint.sh:45-47` ("What it deliberately does NOT measure: whether the
  expected value beside the arrow is the right one…").
- **#122:** `agents/sdd-docs.md:49` — a linha do `CHANGELOG.md` só vale quando "the mission ships
  something user-visible".
- **#154:** `mission_budget_blown` (`bin/sdd:5031`) soma o journal inteiro. A porta é
  `--budget-override` + a nota `intervention:` (anatomia §7).
- **#101:** 30 rodadas `40-review-r*.md` no disco e 6 sem `gate:`, todas de
  `20260816-runner-sem-dividas`, `20260817-catraca-do-backlog` e `20260817-eixo-do-juiz`. O
  comentário `bin/sdd:1773` ainda diz "6 of the 14 rounds".
- **#128:** `bin/sdd:4670` `mkdir -p "$(dirname "$logfile")"` sem guarda; irmãos em `:10901` e `:807`.
- **#93:** `docs/handoffs/20260816-runner-sem-dividas/checkpoint.md:20`.
- **#143:**
  - `step_timeout` em `tests/run-all.sh:168`, regra "8 times the step's idle time measured on
    2026-10-02, with a floor of 60 s";
  - D7 em `CONTEXT.md:58`, cujo critério (4) é "suíte < 30s no default";
  - o 🚩 do D7 em `CONTEXT.md:96-119`, que termina em "o item vivo mora no `TODO.md`".
- **#123/#124:**
  - `CONTEXT.md` § "Decisões adiadas por YAGNI" (~:79), tabela `| Adiada | O quê | Reabre quando |
    Origem |`, último Y4 em ~:92;
  - um 🚩 já adia os dois "até existir um alvo anglófono" (~:126-128, bullet "O contrato PT-BR em
    cinco pontos e o `templates/` single-language ficam adiados…");
  - `CLAUDE.md:38-40` diz "estão no `TODO.md`";
  - contagem de 2026-10-03, `grep -rFo <termo> bin templates agents tests config | wc -l`:
    `aprovacao` 167, `versao` 40, `titulo` 25, `00-missao.md` 251, `01-plano.md` 113;
  - os 10 repos com `.sdd/config.sh` em `~/repos` declaram `OUTPUT_LANG="pt-BR"`.
- **#158:** anatomia §6 `.claude/rules/anatomia-do-agente.md:220-221` ("O custo que sobra, ~30 ms
  do 2º Python do worker em toda chamada coordenada, está no `TODO.md`."). Gaveta
  `docs/superpowers/specs/2026-09-23-a-gaveta-do-kit.md:63` (P1) e `:70` ("Já está no `TODO.md`
  …").
- **#66, #77, #90, #125, #140** (cabeçalhos):
  - `tests/check-health.sh:1-50`: header numerado, com entradas "⚠️ DECLARED LIMIT (D15)" em `:34`
    e `:40`; o `health_run` em ~:341 fixa o `cd`;
  - `tests/check-todo.sh:119-149`: bloco "Declared debt, admitted here instead of into the backlog";
    o comentário do `tail_of` em ~:355-367 diz "Filed in TODO.md with this differential";
  - `tests/run-all.sh:303-306`: o guard do check-todo diz que o sandbox nunca copia `TODO.md`, o
    que é FALSO, porque `sandbox()` em `tests/check-mutation.sh` faz `cp "$ROOT/CLAUDE.md"
    "$ROOT/TODO.md" "$1/"`;
  - `tests/check-pipefail.sh:255-262`: "NOT MEASURED (1)" afirma "It is not a fail-open because it
    is measured OUT OF BAND";
  - `tests/check-lang.sh:47-49`: "— recorded in TODO.md, not done here."

## Arquitetura da mudança

Três tipos de mudança, nesta ordem:

1. **Saídas sem código (I1–I3).** 22 itens deixam a seção aberta: 15 viram registro decidido, 2
   viram linha YAGNI no `CONTEXT.md` e 5 viram limite declarado no cabeçalho do sensor. A catraca
   desce no mesmo commit de cada grupo. Só o I3 toca `tests/`, onde estão os cabeçalhos.
2. **O `/sdd-plan` (I4).** `commands/sdd-plan.md` e `agents/sdd-planner.md` (+ espelho). Prosa, fora
   da chave do carimbo.
3. **Os 13 consertos (I5–I19).** Um item por incremento, menos o #217 e o #192, que pedem dois
   cada. Ordem:
   - primeiro os sensores de checkpoint e de todo (I5–I10, tudo em `tests/` e `templates/`);
   - depois o runner (I11–I16, `bin/sdd` + mutantes);
   - por último o catálogo (I17–I19).

   Dentro do `check-checkpoint.sh`, a ordem #113 → #211 → #216 importa, porque o `PROBE_FLOOR`
   sobe 30 → 32 → 36 → 39.
4. **Fecho (I20).** `RESOLVED by` nos 13 itens, entrada no `KAIZEN_LOG.md`, `20-handoff-exec.md`,
   suíte inteira e `--anchors`.

Depois do I20 vem o fluxo da decisão 6 (§ Depois do checkpoint), que não tem incremento.

## Saídas sem código (I1–I3) — o destino de cada uma (decisão 4)

Texto exato de cada registro decidido. Todos são UMA linha física, vão para o fim da seção
`<!-- sdd:decided -->` e levam a data da decisão. Apague o item aberto correspondente no mesmo
commit; localize-o pelo título, citado em cada linha.

**I1 — 13 decididos sem documento acoplado** (catraca 57 → 44). Apague estes 13 itens abertos;
cada um se acha pelo começo do título:

| # | item aberto — o título começa com |
|---|---|
| 138 | Refutação de handoff cita evidência que não existe |
| 187 | `sdd status` travou mais de 2 min segurando a trava do checkout |
| 214 | O `cmd_kaizen` escala `no-progress` depois de um retry que moveu o disco |
| 181 | A Âncora 3 do `gate_QA` bloqueia a missão com bug aberto de OUTRA missão |
| 102 | Slug de missão em pt-BR não pode ser citado na superfície inglesa |
| 152 | Nenhuma das skills `qa-report`/`qa-execution` conhece o campo `Closable by:` |
| 137 | O `rows=13` do `gate:` da QA não sai do extrator do `gate_REVIEW` |
| 74 | Nada mede se o esperado de um Check do checkpoint ainda reproduz |
| 122 | O kit não tem `CHANGELOG.md`, e a fase DOCS cobra um |
| 154 | O teto de orçamento não conhece "missão reaberta" |
| 101 | O `gate:` do frontmatter só é cobrado quando existe, e 6 das 14 rodadas não o têm |
| 128 | `run_phase` cria o diretório de log da sessão sem guarda nenhuma |
| 93 | Check de ausência (`grep -c X` → `0`) reprova o conserto que precisa citar o defeito |

E acrescente estas 13 linhas, **verbatim**, ao fim da seção `<!-- sdd:decided -->`, na ordem:

```text
- **A refutação R2 do handoff de QA citaria evidência que não existe** — refutado: o prompt renderizado nomeava o arquivo, porque o boot_prompt expande `$TODO_FILE` para TODO.md; o item conferiu a fonte, não o prompt — `148f693:bin/sdd:1621` (2026-10-03)
- **O sdd status travaria mais de 2 min segurando a trava do checkout** — refutado: sem `--no-gates` o status avalia todo gate sob a trava, TEST_CMD e E2E_CMD incluídos, e a trava é não-bloqueante, então quem chega depois recebe CHECKOUT-BUSY com o dono; a leitura sem trava é `sdd status --no-gates` — `bin/sdd-coordination.py:504` (2026-10-03)
- **O cmd_kaizen escalaria no-progress como fricção no rubric depois de um retry que moveu** — decidido: o código escala sem olhar o moved2, mas as linhas KAIZEN são `$meta` e ficam fora do eixo do juiz nos dois leitores; o humano lê "two sessions without satisfying the gate", que é verdade — `bin/sdd:9943` (2026-10-03)
- **A Âncora 3 do gate_QA bloquearia a missão com bug aberto de OUTRA missão** — decidido por desenho: a ADR 0009 mantém recusada a alternativa (A) da 0006, porque contar só o bug da missão troca o laço por dívida calada; a saída humana é `deferred` — `docs/adr/0009-the-genre-gains-deferred-and-hats-gain-project-exceptions.md` (2026-10-03)
- **Slug de missão em pt-BR não poderia ser citado na superfície inglesa** — decidido: o selftest do check-lang afirma de propósito que slug em prosa é pego (exit 95); slug se cita numa linha `Spec:`/`ADR:` ou sem stopword — `tests/check-lang.sh:130` (2026-10-03)
- **As skills qa-report e qa-execution não conhecem o campo Closable by** — decidido: o lado do kit fechou (o sdd install semeia o campo, o sdd preflight reprova sem ele, o sdd-qa marca); ensinar a skill de terceiro é retrofit no marketplace, não item do kit — `f7bcf10` (2026-10-03)
- **O rows=13 do gate: da QA de 20260818-lote-facil não sai do extrator** — decidido: o número citado não reproduz (o extrator dá 8, o próprio item o mediu) e a conclusão da J6 segue certa; handoff de fase encerrada não se reescreve — `docs/handoffs/20260818-lote-facil/30-handoff-qa.md:7` (2026-10-03)
- **Nada mediria se o esperado de um Check do checkpoint ainda reproduz** — limite declarado: o cabeçalho do sensor diz que ele não mede o valor ao lado da seta, de propósito; rodar os Checks custaria a suíte por célula — `tests/check-checkpoint.sh:45` (2026-10-03)
- **O kit não tem CHANGELOG.md, e a fase DOCS cobraria um** — decidido: a linha do CHANGELOG na DOCS é condicional (só quando a missão entrega algo visível) e nenhum gate a cobra; o registro do kit é KAIZEN_LOG.md, handoffs, git log e corpo do PR — `agents/sdd-docs.md:49` (2026-10-03)
- **O teto de orçamento não conhece "missão reaberta"** — decidido: a porta humana para gastar mais é `--budget-override` com a nota intervention: que o runner escreve (anatomia §7) — `bin/sdd:5031` (2026-10-03)
- **O gate: do frontmatter da revisão só é cobrado quando existe** — decidido, sem conserto: as 6 rodadas sem o campo (de 30) são de 2026-08-16/17, anteriores a ele, e as 24 seguintes o trazem — `bin/sdd:1773` (2026-10-03)
- **run_phase cria o diretório de log da sessão sem guarda** — decidido, sem conserto: a falha é alta e fechada (rc 1 antes de abrir sessão, zero gasto) e nunca foi observada — `bin/sdd:4670` (2026-10-03)
- **Check de ausência reprovaria o conserto que precisa citar o defeito** — decidido: falha fechada, um caso em 2026-08-16; a regra de redação de Check do planner vem com o achado do Check que nasce verde, na leva 4 — `docs/handoffs/20260816-runner-sem-dividas/checkpoint.md:20` (2026-10-03)
```

Os títulos dos registros vêm sem `*` (a regra é `^- \*\*[^*]+\*\* — `) e, quase todos, sem crase.
O code span que a regra exige é o da evidência, no fim.

Também no I1, troque "6 of the 14" por "6 of the 30" nos TRÊS sítios que repetem a contagem:
- o comentário `bin/sdd:1773`;
- o comentário `tests/check-gates.sh:2053`;
- `docs/pipeline.md:408`.

São edições no lugar, sem linha nova, e tornam verdadeiro o que o registro do #101 cita. Não é
conserto do item. Confira com `grep -rn '6 of the 14' bin tests docs/pipeline.md` → nada (os handoffs antigos em `docs/handoffs/` são história e ficam como estão).

**I2 — 4 saídas com documento acoplado** (catraca 44 → 40):

- **#143 → decidido** + `CONTEXT.md`:
  - **Linha D7 (`:58`).** Troque `(4) suíte < 30s no default.` por: `(4) ~~suíte < 30s no
    default~~ → cada passo da suíte dentro do prazo do `step_timeout` (`tests/run-all.sh`; 8× o
    tempo ocioso medido, piso 60 s) — emendado em 2026-10-03 por `20261003-lote-3-a-catraca-desce`
    (decisão 4): o alvo de 30 s ficou ~10× para trás, e o prazo por passo é o orçamento que a suíte
    de fato cobra.`
  - **🚩.** Apague o bullet inteiro do 🚩 que começa com `- **O critério (4) da D7` (~:96-119),
    até a linha antes do próximo `- **`.
  - **Registro:** a 1ª linha do bloco "Registros do I2" abaixo.
- **#123 e #124 → YAGNI** no `CONTEXT.md` + `CLAUDE.md`:
  - **Tabela YAGNI.** Acrescente, depois do Y4:
    - `| Y5 | **O contrato de artefato em PT-BR** — três chaves de frontmatter (`aprovacao`,
      `versao`, `titulo`) e dois nomes de artefato (`00-missao.md`, `01-plano.md`) são o único
      português obrigatório para um alvo anglófono; em 2026-10-03, 232 + 364 ocorrências em `bin
      templates agents tests config` (`grep -rFo <termo> … | wc -l`). | Aparecer o **primeiro
      repo-alvo com `OUTPUT_LANG` diferente de `pt-BR`** (os 10 alvos locais são pt-BR em
      2026-10-03). Renomear pede uma janela que aceite os dois nomes: missão em voo quebra. |
      decisão 4 do grill de `20261003-lote-3-a-catraca-desce`; saiu do `TODO.md` pela régua D15
      (2026-10-03) |`
    - `| Y6 | **`templates/` em um idioma só** — os templates moram em cópia única PT-BR e o
      `sdd-planner` os lê de `$SDD_HOME`; um alvo com `OUTPUT_LANG="en"` recebe prompt certo e
      template em português. Precedente: `templates/todo.<lang>.md`. | O mesmo evento do Y5. | idem
      Y5 |`

    Cada linha da tabela é UMA linha física, porque é tabela markdown.
  - **🚩.** Apague o bullet `- **O contrato PT-BR em cinco pontos e o `templates/` single-language
    ficam adiados…` (3 linhas): ele virou Y5/Y6.
  - **`CLAUDE.md:38-40`.** Troque `estão no `TODO.md`, e renomeá-los quebra missão em voo.` por
    `estão adiados por YAGNI no `CONTEXT.md` (Y5) até o primeiro alvo não-pt-BR, e renomeá-los
    quebra missão em voo.`
  - **Apague** os dois itens abertos ("O contrato de artefato ainda é PT-BR em cinco pontos" e
    "`templates/` é single-language"). YAGNI não ganha registro decidido: o destino é a tabela.
- **#158 → decidido** + anatomia + gaveta:
  - **`.claude/rules/anatomia-do-agente.md:220-221`.** Troque `O custo que sobra, ~30 ms do 2º
    Python do worker em toda chamada coordenada, está no `TODO.md`.` por `O custo que sobra, ~30 ms
    do 2º Python do worker em toda chamada coordenada, é limite declarado: não chega ao humano, e o
    conserto (provar o worker por FD herdado, com ADR) mora na gaveta, F1 P1.`

    Esta edição em `.claude/` só é possível porque a execução é interativa (decisão 6).
  - **Gaveta `:70`.** Troque `Já está no `TODO.md` ("O 2º Python do worker custa ~30 ms").` por
    `Saiu do `TODO.md` como decidido em 2026-10-03 (`20261003-lote-3-a-catraca-desce`): o plano mora
    aqui.`
  - **Registro:** a 2ª linha do bloco abaixo.

Registros do I2, **verbatim**, ao fim da seção decidida, apagando os itens abertos "A suíte segue
acima do alvo "<30 s" da D7…" e "O 2º Python do worker custa ~30 ms…":

```text
- **A suíte segue acima do alvo "<30 s" da D7** — decidido: o critério (4) da D7 passa a ser o prazo por passo do step_timeout (8× o tempo ocioso, piso 60 s), que já é o orçamento medido e cobrado; o 🚩 do CONTEXT.md fecha — `tests/run-all.sh:168` (2026-10-03)
- **O 2º Python do worker custa ~30 ms em toda chamada coordenada** — decidido: 30 ms por chamada não chega ao humano; provar o worker por FD herdado pede ADR e fica na gaveta, F1 P1 — `docs/superpowers/specs/2026-09-23-a-gaveta-do-kit.md:63` (2026-10-03)
```

**I3 — 5 cabeçalhos de sensor** (catraca 40 → 35). Prosa **inglesa**. Cada entrada nova traz o
slug, que é o que o Check conta: `⚠️ DECLARED LIMIT (D15), moved here from TODO.md in
20261003-lote-3-a-catraca-desce:` seguido do limite. Apague os 5 itens abertos.

- **#66 → `tests/check-health.sh`**, uma entrada nova no header, perto das de `:34` e `:40`. O
  limite: nenhuma regra recusa a PRÓXIMA invocação de `sdd health` de um fixture que esqueça de
  fixar o `cd` (o `health_run` fixa, e o comentário dele explica por quê). Medido sem falhar aberto
  hoje:
  - toda invocação fixa o `cd`; confira com `grep -n 'sdd" health' tests/*.sh` e escreva o número
    medido;
  - desde o #112, um run que vagueia para o catálogo real morre no prazo do passo
    (`tests/run-all.sh`, `step_timeout`), vermelho e nomeado; dentro de mutante é rc 124 (TIMED-OUT,
    inconclusivo), nunca "pego".
- **#77 → `tests/check-todo.sh`**, no bloco "Declared debt" (`:119-149`): o limite do `tail_of`.
  - **O limite:** um span de enfeite mais adiante no rabo satisfaz a presença e não nomeia agente
    algum.
  - **Por que fica:** falha só em cosmética (a linha ok não afirma agente), e a prática já aceita
    atribuição que não é agente: 4 itens vivos têm rabo de sessão ou de triagem.
  - Troque, no comentário do `tail_of` (~:355-367), `Filed in TODO.md with this differential` por
    `Declared in this sensor's header (Declared debt), with this differential`.
  - ⚠️ A âncora `tests/check-todo.sh:293` do próprio #77 some com ele. Mas `tests/check-todo.sh:65`
    (#217) e `:2005` (#191) deslocam com as linhas novas do header: reancore.
- **#90 → `tests/run-all.sh`**, junto dos guards de `SDD_MUTANT` (~:274-307).
  - **O limite:** um sensor guardado fora do mutante é ponto cego do catálogo para o que só ele
    pegaria. Medido sem falhar aberto hoje: nenhum dos 4 guardados (`check-lang`, `check-pipefail`,
    `check-todo`, `check-checkpoint`) invoca `bin/sdd` como runner (confira com `grep -n 'bin/sdd'`
    nos quatro; o único caso é um heredoc de probe no `check-pipefail`), e um mutante que só eles
    matariam sai como sobrevivente NOMEADO, nunca como passe (`KNOWN_GAPS=()` vazio, catraca nos
    dois sentidos).
  - **Conserte também a frase falsa** do guard do `check-todo` ("the mutation sandbox copies bin/
    tests/ templates/ config/, never TODO.md"). O `sandbox()` copia `CLAUDE.md` e `TODO.md`.
    Re-derive o motivo verdadeiro e escreva só o que medir: o `sandbox()` copia só `docs/adr` de
    `docs/`, e não copia o `README.md`; o `TODO.md` ancora em `README.md:158` (#109) e em
    `docs/pipeline.md:1022` (#130). Isso, mais "it tests no gate", é o motivo.
- **#125 → `tests/check-pipefail.sh`**, no comentário do `CD_RE` (NOT MEASURED (1), ~:255-262).
  - Estreite "It is not a fail-open because it is measured OUT OF BAND" para "safe by population
    today": as capturas `$( cd "$VAR"` do `bin/sdd` usam todas uma variável absoluta (`$REPO_ROOT`,
    `$kit`, `$SDD_HOME`). Meça com `grep -cE '\$\( *cd "\$' bin/sdd` e escreva o número.
  - O par em runtime do `check-autonomy.sh` cobre só o `ledger_repo_root`.
  - A frase "moved here from TODO.md" vai na mesma entrada.
- **#140 → `tests/check-lang.sh:47-49`**: troque `— recorded in TODO.md, not done here.` por uma
  frase de limite declarado. Nenhum dos dois arquivos é fail-open: a exclusão é explícita, listada
  aqui e no `CLAUDE.md` § Idioma, e nenhum consumidor fora do kit lê a prosa deles. Inclua a marca
  com o slug.

## Incrementos

A tabela executável vive em `checkpoint.md`. Aqui fica o **porquê** e o detalhe. Comum a todo
incremento de código:
- **Red primeiro**, observado com o valor de HEAD citado;
- conserto mínimo;
- sabotagem (mutante provado com `--only` ou passada de sabotagem do selftest);
- sensores tocados verdes;
- re-âncora do `TODO.md`;
- commit, checkpoint e nota.

### I1 — 13 saídas decididas (sem documento acoplado)

**O quê:** os 13 registros da tabela do I1, a remoção dos 13 itens abertos, catraca 57 → 44 e a
correção "6 of the 30" no comentário `bin/sdd:1773`.
**Onde:** `TODO.md`, `tests/health-baseline.txt`, `bin/sdd` (comentário, no lugar).
**Como:** nada a testar antes. O Red é o Check devolvendo `0 5 0` em HEAD.
**Check:** ver `checkpoint.md` → `1 18 1`, isto é, o ok de 44 achados, 18 registros decididos
(5 + 13) e a catraca em 44.
**Sensor durável:** `tests/check-todo.sh` (forma de cada registro e contagem) e a catraca do
`sdd health`.
**Reversível por:** `git revert`.

### I2 — 4 saídas com documento acoplado (#143, #123, #124, #158)

**O quê:** o descrito na seção I2 acima; catraca 44 → 40.
**Onde:** `TODO.md`, `tests/health-baseline.txt`, `CONTEXT.md`, `CLAUDE.md`,
`.claude/rules/anatomia-do-agente.md`, `docs/superpowers/specs/2026-09-23-a-gaveta-do-kit.md`.
**Check:** → `1 2 0 0`: o ok de 40 achados, Y5 e Y6 presentes, o 🚩 do D7 ausente, a anatomia sem
"está no `TODO.md`" para o 2º Python.
**Sensor durável:** `check-todo.sh`. A regra 12 do `check-health.sh` lê `CLAUDE.md`: não toque na
política da catraca.
**Reversível por:** `git revert`.

### I3 — 5 limites declarados nos cabeçalhos (#66, #77, #90, #125, #140)

**O quê:** o descrito na seção I3 acima; catraca 40 → 35; suíte inteira verde ao fim.
**Onde:** `tests/check-health.sh`, `tests/check-todo.sh`, `tests/run-all.sh`,
`tests/check-pipefail.sh`, `tests/check-lang.sh`, `TODO.md`, `tests/health-baseline.txt`.
**Armadilha:** comentário `#` **dentro** de bloco continuado por `\` quebra o comando sem o
`bash -n` acusar. Escreva os cabeçalhos fora de blocos assim. No `check-lang.sh`, as palavras
portuguesas do dicionário estão no próprio arquivo, e a prosa nova é inglesa.
**Check:** → `1 5`: o ok de 35 achados e os 5 cabeçalhos com o slug.
**Sensor durável:** os cinco sensores seguem verdes (suíte inteira).
**Reversível por:** `git revert`.

### I4 — O `/sdd-plan` ensina o repasse e o aviso de trabalho longo (decisões 3 e 10)

**O quê:** o `commands/sdd-plan.md` (fonte; `~/.claude/commands/sdd-plan.md` é symlink para ele)
ganha, depois da seção `## Then`, a seção `## Relaying the grill to the human`, em inglês, com:

1. **O porquê.** O planner roda como subagente; subagente não tem ferramenta para perguntar ao
   humano e, neste harness, roda em segundo plano. Quem rodou o `/sdd-plan` é o relay: nunca
   responde pelo humano, nunca parafraseia.
2. **O lado do planner.** Encerrar cada turno (o hand-back) com UMA pergunta do grill (duas só se
   independentes), no `OUTPUT_LANG`, com 2–4 opções concretas, a recomendada primeiro e marcada, um
   porquê de uma linha por opção, e a evidência que o humano precisa acima, concisa.
3. **O lado do relay.** Perguntar ao humano com a ferramenta de pergunta do harness (opções
   verbatim, recomendada primeiro) e devolver a resposta VERBATIM ao MESMO planner, continuando o
   agente (ex.: `SendMessage` ao id dele; uma chamada nova de `Agent` começa do zero e perde o
   grill). Repassar também qualquer fala do humano no meio do grill.
4. **Um bullet que começa exatamente com `- **Long work between two questions:**`.** Antes de um
   trabalho longo entre duas perguntas (ex.: prototipar consertos com subagentes paralelos), o
   planner devolve primeiro um aviso de UMA linha com o que vai fazer e a estimativa de tempo; o
   relay o mostra ao humano e só então o planner começa. Evidência: no grill de
   `20261003-lote-3-a-catraca-desce` o planner ficou ~45 min sem sinal entre a 7ª e a 8ª pergunta,
   e o humano perguntou se seguia trabalhando.
5. **Aprovação.** Mensagem de agente nunca é aprovação do humano: o `aprovacao:` fecha pelo gate
   PLAN-AUTO ou por `sdd approve`.

E o `agents/sdd-planner.md` ganha, no fim da seção `## 1. Brainstorm and grill (with the human)`
(`:35`), um parágrafo em inglês que contém a frase exata `the session that delegated you is the
relay`. Ele resume os pontos 2 e 4 (encerrar com uma pergunta; aviso de uma linha antes de trabalho
longo) e o 5. Depois, `./bin/sdd install --force` para o espelho.
**Como (TDD):** o Red é o Check em HEAD → `0 0 0 1 same`.
**Check:** → `1 1 1 1 same`:
- a seção existe;
- o bullet do trabalho longo existe;
- a frase do chapéu existe;
- o `check-checkpoint.sh` segue dizendo `the planner agent teaches the ok-anchor rule` (o
  `doc_rule`/`pipe_rule` em `tests/check-checkpoint.sh:291,298` leem o chapéu);
- o espelho está byte a byte igual.

**Sensor durável:** nenhum novo, de propósito. Medir prosa de contrato fora de `templates/` é a
decisão do #109, que fica para a leva 4 (`00-missao.md` § Fora de escopo). O Check segura a entrega,
e o `check-lang.sh` segura o idioma do chapéu.
**Reversível por:** `git revert` + `./bin/sdd install --force`.

### I5 — #113 resíduo: o `calibrate()` enxerga os 16 sensores

**O quê:** `calibrate()` (`tests/check-checkpoint.sh` ~:320-348, `CALIBRATE_FLOOR=9` em ~:319)
casa hoje só linhas `pass() { printf '` (~:325) e conta LINHAS, então vê 9 de 16 sensores. Todos
os 16 imprimem `  ok    ` com 4 espaços, mas noutras formas:
- `pass() { PROBES=…; printf` no `check-adr`;
- `pass()  {` no `check-mutation`;
- `printf` inline no `entrypoint`, `lang`, `pipefail` e `todo`;
- `print("  ok    "` em Python no `coordination`;
- `echo "  ok    "` no `lang`.

A metade dos 3 espaços do item já foi consertada em `eb0ee9e` (#151, ancestral do HEAD).
**Como (TDD):**
1. **Red.** Uma árvore de piso com um `check-x.sh` contendo `echo "  ok   inline"` (3 espaços) dá
   rc 0 em HEAD; tem de dar rc 1 com `disagree about the ok prefix`.
2. **Desenho.**
   - Casar, por arquivo, qualquer linha que contenha `$sq$ok␠` ou `$dq$ok␠`, com
     `sq="'" dq='"' ok='  ok'`. ⚠️ As agulhas saem de VARIÁVEIS: um literal `'  ok "` no `case`
     casa a si mesmo e reporta o próprio `check-checkpoint.sh`.
   - `rest="${line#*["$sq$dq"]"$ok"}"; sp="${rest%%[! ]*}"; p="  ok$sp"`.
   - Lembrar o 1º arquivo que deu cada prefixo, para a mensagem.
   - Contar ARQUIVOS, com `CALIBRATE_FLOOR=16`.
   - Atualizar o item 4 do header (~:42-43) e o comentário velho em `tests/check-templates.sh:59-62`.
   - Fixtures na forma `%s  ok` + `"'"` (como :641/:644).
3. **Probes +2** (`PROBE_FLOOR` 30 → 32):
   - A: o `echo` de 3 espaços numa árvore de piso → rc 1 `disagree`.
   - B: uma árvore só com `printf '  ok    x'` inline → rc 0 `the prefix the suite`.
   - E o `calthin` passa a 2 arquivos × `CALIBRATE_FLOOR` linhas, para que contar linhas falhe.

**Sabotagem obrigatória:**
- voltar a casar só `pass()` → A e B vermelhos;
- tirar o `"` do casamento → A;
- contar linhas → `calthin`.

Sobrevivente declarado: baixar `CALIBRATE_FLOOR`, porque os fixtures escalam com ele (o mesmo de
`eb0ee9e`).
**Check:** ok `the ok anchor is the prefix the suite's sensors actually print (16 sensor(s))` → `1`
(HEAD: `(9 sensor(s))`).
**Reversível por:** `git revert`.

### I6 — #211: Check com `test -f` num caminho que o `.gitignore` ignora

**O quê:** `scan_file` (`tests/check-checkpoint.sh` ~:176-203) tem só as regras 1 (cinco colunas)
e 2 (`2>&1` + grep ancorado); nada em `tests/` chama `git check-ignore`. Medido:
- `git check-ignore -q` dá rc 0 num caminho ignorado (mesmo inexistente), rc 1 num rastreado e
  rc 128 fora de repo.
- Testemunha real: `~/repos/lighthouse_project/docs/handoffs/20260921-amep-backend-0-1-0/checkpoint.md`,
  linha I13 (`test -f docs/qa/state.csv`, ignorado por `.gitignore:24`). É o único caso em 51
  checkpoints; o kit tem 0.

**Como (TDD):**
1. **Red.** `--check` num repo git cujo checkpoint roda `test -f docs/qa/reports/s8-review.md`
   com `*-review.md` ignorado devolve rc 0 e `none blind` em HEAD.
2. **Desenho.**
   - Globais `N_PATHS` e `V_IGNORED`, no `reset_counters`.
   - Em `scan_file`, uma vez por arquivo: `top="$(git -C "$(dirname -- "$path")" rev-parse
     --show-toplevel 2>/dev/null)"`. Use `git -C`, nunca `cd` (CDPATH).
   - Depois da regra 1, para cada `p` de `tested_paths "$chk"`: `if src="$(git -C "$top"
     check-ignore -v -- "$p")"` → `fail "<label>: the Check of <id> tests '<p>', which the
     repository ignores (<src>:<n>:<pattern>) — green over a file git never receives, red on a
     fresh clone"`, com `${src%%$'\t'*}`.
   - `tested_paths`, definida DEPOIS de `scan_file`:
     - `read -ra` nas palavras;
     - quando a palavra é `test` ou `[` (tirada a crase ou o `(` inicial) e a seguinte é `-e`,
       `-f` ou `-s`, toma a próxima;
     - tira `` ` ``, `;`, `)` e aspas do fim;
     - pula vazio, `]`, `/…`, `~…` e o que tiver `$ * ? [ { < >` ou crase.
   - `V_IGNORED` entra na soma do `check_one` (~:358), no rc do `scan` e no total (~:305).
3. **Limites declarados** no header "Known limits" (decisão 9):
   - um Check que afirma a AUSÊNCIA de um caminho ignorado (`test -f x; echo $?` → `1`) é falso
     positivo (0 casos hoje);
   - o `check-ignore` também lê `~/.config/git/ignore`, que existe nesta máquina, então o veredito
     depende da máquina, como o próprio `git add`.
4. **Probes +4** (`PROBE_FLOOR` 32 → 36), com um repo de fixture (`git -C "$box/ign" init -q`,
   `printf '*-review.md\n' > .gitignore`):
   1. `probe 'a Check that tests an ignored path is caught' 1 'which the repository ignores' …`;
   2. o mesmo repo com `test -f docs/qa/r1-report.md` → rc 0 `none blind`;
   3. a forma `[ -f docs/b-review.md ]` → rc 1;
   4. a ligação do `--scan` (copiando :673-677): `build_tree` + `git init` + `.gitignore` na raiz +
      uma linha a mais em m4 → rc 1.

   Use um caminho que o kit NÃO ignora; o kit ignora `*.log`, `docs/qa/state.csv` e `graphify-out/`.

**Sabotagem obrigatória:**
- `tested_paths` vazio → P1 e P4;
- `check-ignore` invertido → P2;
- só a forma `test` → P3;
- `V_IGNORED` fora do `scan` ou do `check_one` → P4 ou P1;
- resolver pelo cwd e não pelo diretório do checkpoint → P1 (o kit não ignora `*-review.md`).

**Check:** `--selftest` verde e a descrição do probe 1 presente → `1`.
**Reversível por:** `git revert`.

### I7 — #216: `done` abaixo de `blocked` reprova (decisão 9)

**O quê:** `rows_of` (~:156-167) calcula `status` mas imprime só `NF, id, chk`, e não há regra de
ordem. O runner para em qualquer `blocked` (`cmd_run`, `increment-blocked`, rc 3; o remédio é
voltar a linha a `pending`), então um `done` abaixo de `blocked` só nasce fora do runner. Há 0
casos em 51 checkpoints, logo a regra entra verde.
**Como (TDD):**
1. **Red.** Um fixture de duas linhas (I11 `blocked`, depois I12 `done`) devolve rc 0 `none blind`
   em HEAD.
2. **Desenho.**
   - `rows_of` imprime `NF, id, (status==""?"-":status), chk`. O `-` é OBRIGATÓRIO: tab é IFS, e
     uma célula vazia colapsaria e jogaria o `chk` no `st`.
   - `scan_file` lê `read -r nf id st chk`. No 1º `blocked`, guarda `bid`. Num `done` com `bid` →
     `fail "<label>: <id> is done below <bid>, which is blocked — the runner stops the line at a
     blocked row, so <id> was closed past the stop and its Check may certify what <bid> never
     proved"`.
   - `V_ORDER` entra no `check_one`, no `scan` e no total. O texto `none blind` fica como está.
   - O `cp_row` (~:409-411) ganha um 4º argumento opcional `${4-done}`.
3. **Probes +3** (`PROBE_FLOOR` 36 → 39):
   - `probe 'a done below a blocked row is caught' 1 'is done below I1, which is blocked' …`;
   - `done` acima de `blocked` → rc 0;
   - `--scan` com uma linha de m4 `blocked` e depois `done` → rc 1.

**Sabotagem obrigatória:**
- regra removida → P1;
- ordem ignorada ("qualquer done havendo blocked") → P2;
- `V_ORDER` fora do `scan` → P3;
- fora do `check_one` → P1.

**Check:** `--selftest` verde e a descrição do probe presente → `1`.
**Reversível por:** `git revert`.

### I8 — #212: o template do checkpoint cita o sensor pela forma `--check` do kit

**O quê:**
- **O defeito.** `templates/checkpoint.md:18-19` diz "`tests/check-checkpoint.sh` recusa as duas
  formas / nos checkpoints deste repo", e `:33` diz "O sensor é `tests/check-checkpoint.sh`". No
  alvo o caminho não existe: o `sales_quote` tem 13 checkpoints com esse texto e nenhum arquivo.
- **Leitores do template**, nenhum dos quais lê as linhas 18-19 ou 33:
  - `doc_rule`: `^  ok    ` (:27) e `2>&1` (:18/:32);
  - `pipe_rule`: `awk -F'|'` (:12) e `\|` (:15);
  - `tests/check-templates.sh` (~:348-368): cabeçalho da tabela, `pending`, `` `done` ``,
    `` `blocked` ``, `checkpoint-notas\.md` e `## Incrementos de fix (QA e REVIEW)`.
- **Novo texto do template.**
  - **:18-19:** `` `tests/check-checkpoint.sh --check <checkpoint>` do kit recusa as duas formas em
    qualquer checkpoint ``.
  - **:33:** `` O sensor é o `tests/check-checkpoint.sh --check <este checkpoint>` do kit (pelo
    caminho do kit) ``.
  - Preserve os literais `^  ok    `, `2>&1`, `awk -F'|'` e `\|`.
- **`tests/check-templates.sh`**, depois do `check` de `checkpoint-notas`, ganha:
  - `check checkpoint.md 'tests/check-checkpoint\.sh --check' "the checkpoint sensor cited in its
    --check form, the one a target repo can run"`;
  - `refute checkpoint.md 'checkpoints deste repo' "the claim that the sensor reads only this
    repo's checkpoints"`.

  O padrão em português é DADO, permitido neste arquivo; as descrições ficam em inglês. O
  `REVIEW_FLOOR=26` conta só o bloco de review, então não muda.
- **No mesmo incremento, a linha do planner da #211/#216.** Em `agents/sdd-planner.md` § 4 (depois
  de ~:85), uma frase inglesa: "run the kit's `tests/check-checkpoint.sh --check <checkpoint>` by
  the kit's path; it refuses a blind anchor, a pipe, a `done` below `blocked`, and a `test -f` on an
  ignored path." Depois, `./bin/sdd install --force`.

**Como (TDD):**
1. **Red.** Com o `check` novo e o template antigo, o `check-templates.sh` sai **rc 92**
   (SENSOR-BROKEN): o controle ponta a ponta fica vermelho, com `FAIL checkpoint.md: missing the
   checkpoint sensor cited…`.
2. Depois da reescrita, rc 0.

**Sabotagem:** rode a regra nova contra o template de HEAD com
`SDD_TEMPLATES_DIR=<cópia com git show HEAD:templates/checkpoint.md>`; tem de falhar.
**Check:** → `1 1 same`: o ok do `check-templates`, a frase no chapéu e o espelho igual.
**Reversível por:** `git revert` + `./bin/sdd install --force`.

### I9 — #217a: `check-todo.sh --check <arquivo> --baseline <ref>` (o diff chaveado)

**O quê:**
- **Hoje.**
  - O `--check` aceita só `${3-}` = `--allow-empty` (`tests/check-todo.sh` ~:2128-2132,
    `$# -le 3` ~:2133).
  - Toda violação tem a forma `  line N: <msg>` (awk ~:316-571; âncoras ~:2051-2090).
  - O `check_file` coleta em ~:1957-1963, e o `anchor_base` está em ~:2012.
  - rc 88 está livre (lista ~:176-184).
  - `RULES_FLOOR=9` (~:634); o piso de probes é o literal `-lt 156` (~:1874), com 165 reais.
  - O `TODO.md` do `~/repos/ui24-agent` (hífen) dá 10 violações hoje.
- **Desenho.**
  - `collect_violations <arquivo> <cap>` publica `VIOLATIONS` (lint + `anchor_scan`; CHAMADA,
    nunca `$( )`) e é reusada pelo `check_file`.
  - A chave é a mensagem (o texto depois de `line N: `) + `\x1f` + o texto da linha N (`mapfile -t
    L`, guarda N<1). Compara como multiconjunto, com `declare -A`.
  - A cópia da ref sai de `git -C top show "${ref}:${rel}"` para um `mktemp`, com
    `rel=$(git -C dir rev-parse --show-prefix)$(basename f)`.
  - Ref sem o arquivo, ou cópia sem marcador → baseline vazia, e toda violação é nova (falha
    fechada).
  - Ref que não é commit (`rev-parse --verify "${ref}^{commit}"`), ou arquivo fora de repo → **rc
    88**. `--baseline` sem argumento → rc 96.
  - As flags são lidas em laço (`--allow-empty`, `--baseline <ref>`); o resto → 96. O
    `check-templates` chama `--check "$v" --allow-empty` e tem de seguir funcionando.
  - Edite a linha de uso no lugar, em :65, que é a âncora do próprio #217.
  - Funções novas depois de `anchors_file` (~:2111).
- **Saídas.**
  - ok: `<basename>: 0 new shape violation(s) against <ref> (<M> inherited)`;
  - FAIL: `<basename>: <N> new shape violation(s) against <ref> (<M> inherited):` + as linhas novas;
  - linha de regra: `rule: a --baseline run fails only on what the ref did not have (<n>
    probe(s))`.
- **Probes 1–6**, num bloco de regra novo depois de ~:1859; `rule_end 6`, `RULES_FLOOR` 10, piso
  156 → 162.
  - **Fixture:** `git init`, `src/code.sh` com um símbolo na linha 20, e um TODO com um item sem
    data. Commit na forma da casa `git -c user.email=… -c user.name=… -c commit.gpgsign=false
    commit …` (`tests/check-gates.sh:1119`), tag `base`, e uma tag anterior `notodo` sem
    `TODO.md`. Rode cada probe de `cd /`.
  - **Os probes:**
    1. linhas deslocadas (um item bom inserido acima) → rc 0 `0 new … (1 inherited)`;
    2. um item sem data acrescentado → rc 1 `1 new`;
    3. conserta uma violação e introduz outra → `1 new`;
    4. `notodo` → todas novas;
    5. ref ruim → 88;
    6. ref ausente → 96.

**Sabotagem obrigatória:**
- chave com o número da linha → P1;
- diff por contagem → P3;
- sempre 0 novas → P2;
- arquivo ausente lido como limpo → P4;
- ref ruim caindo em baseline vazia → P5.

**Check:** ok `rule: a --baseline run fails only on what the ref did not have (6 probe(s))` → `1`.
**Reversível por:** `git revert`.

### I10 — #217b: a âncora da cópia da ref resolve contra o repo real

**O quê:**
- **A armadilha que o item mediu.** A cópia num diretório temporário resolve as âncoras pela raiz
  ERRADA. Medido no ui24: cópia no scratchpad 16 contra 10 reais.
- **O conserto.** `ANCHOR_BASE_OVERRIDE="$top"` só durante a coleta da cópia da ref. O
  `anchor_base` o devolve primeiro. Inicialize-o com `''` no script, para o ambiente não injetá-lo.
- **Limite declarado.** Movimento de código na mesma branch que apodrece a âncora de um item antigo
  conta como herdado; o `--check` simples ainda o reporta.
- **Probe 7.** O fixture ganha um item com âncora fora do alvo (`src/code.sh:35`), e a violação
  herdada segue herdada. Sem o override, ele dá `2 new … (1 inherited)` (medido). `rule_end 7`,
  piso 163.
- **Testemunha fora do repo**, para o PR e não para o Check:
  `bash tests/check-todo.sh --check ~/repos/ui24-agent/TODO.md --baseline HEAD` →
  `0 new … (10 inherited)`.

**Sabotagem:** sem o override → P7.
**Check:** ok `rule: a --baseline run fails only on what the ref did not have (7 probe(s))` → `1`.
**Reversível por:** `git revert`.

### I11 — #127: as chaves de caminho do config são normalizadas e validadas no `load_config`

**O quê:**
- **Hoje.**
  - `load_config` (`bin/sdd` ~:141-279): defaults em ~:153-154, `HAT_WRITES_EXTRA` validado em
    ~:253-271, `[ -n "$PROJECT_NAME" ]` em ~:273.
  - `hat_expand` (~:2501-2514) troca `$TODO_FILE` CRU no `writes:` do chapéu; o `HANDOFF_DIR` só
    perde a `/` final.
  - `hat_path_allowed` (~:3950) casa com `case "$f" in $g)` sem aspas.
  - Medido: `./TODO.md` não casa `TODO.md` (o `hat-crossed` é falso e para a linha do alvo), e
    `TODO_FILE='*'` casa `bin/sdd`, o que alarga a fronteira de TODO chapéu (fail-open).
- **Desenho (A, decisão 9).**
  - No `load_config`, logo antes de :273, um laço sobre `TODO_FILE HANDOFF_DIR QA_DOCS_PATH E2E_DIR`:
    - tira o `./` inicial repetidamente e a `/` final;
    - `adr_dir_ok "$_pv" || die "$_pk='<cru>' is not a literal path inside the repo …"`; o die
      NOMEIA a chave;
    - devolve com `printf -v "$_pk" '%s' "$_pv"`.
  - `adr_dir_ok` (~:7361): componentes `[A-Za-z0-9._-]`, sem `.`, `..`, componente vazio nem caminho
    absoluto. NÃO o renomeie: os mutantes de `tests/check-mutation.sh` ~:4952 e ~:4980 ancoram no
    nome.
  - Valide AQUI, nunca no ponto de uso. O `hat_writes` é lido em `$(…)`, então um `die` lá morreria
    no subshell e devolveria a lista vazia, que é a grafia de "escreve em qualquer lugar".
- **Consequência obrigatória.** Tire os trims redundantes do `hat_expand` (o laço `hd`, e o `%/` de
  `QA_DOCS_PATH` e `E2E_DIR`; mantenha `${ADR_DIR%/}`). Com eles no lugar,
  `RUN_review_scope_handoff_dir_verbatim` (`tests/check-mutation.sh` ~:4746) NÃO é pego.
- **Reancore esse mutante** para `sed -i '/^load_config() {/,/^}/ s@^    while \[
  "\${_pv%/}" != "\$_pv" \]; do _pv="\${_pv%/}"; done$@    :@' "$1"`. Ele passa a ser pego pelo
  `check-autonomy.sh`.
- **`&` deixa de valer** em chave de caminho. Os 10 alvos locais usam `TODO.md`, `docs/handoffs`,
  `docs/qa` e `e2e`. O fixture `TODO_FILE="R&D/TODO.md"` de `tests/check-dry-run.sh:196-203` é
  reescrito como chamada direta de `hat_expand` por `source` de arquivo, no padrão de
  `tests/check-adr.sh:991-1011` (`bash -c` com source falha em `_resolve_self`). O
  `mut_RUN_hat_expand_unquoted` tem de seguir pego pelo `check-dry-run.sh`.
- **Fora, declarado:**
  - `ADR_DIR` (o `adr_mode` já guarda);
  - `SPEC_DIR` (pode ser vazio);
  - o `$MISSION` cru no `hat_expand`;
  - os leitores por `config_read_key` (`cmd_install` ~:5153-5156, autonomy ~:9012), que usam as
    chaves como caminho de FS.
- **Docs:** `config/schema.md:38` e `:83-85` ganham a gramática (o `:223` lista os placeholders).

**Como (TDD):** estender o bloco `HAT_WRITES_EXTRA` de `tests/check-gates.sh` (~:5345-5473;
`hwx_set` ~:5368, `hwx_probe` ~:5374, `hwx_writes` ~:5454). Modelo: `assert_eq "an absolute path is
refused" "died|1" "$( hwx_probe '"sdd-qa: /etc/passwd"' '/etc/passwd' )"`. Asserções:
- `path key <KEY>: ./<x> is normalized before it becomes a writes: glob`, uma por chave. HEAD:
  `bare:0 dotted:1`.
- As quatro recusas, cada uma com o NOME da chave como agulha:
  - `path key TODO_FILE: a glob is refused by name`;
  - `path key HANDOFF_DIR: a climb out with .. is refused by name`;
  - `path key QA_DOCS_PATH: a metacharacter is refused by name`;
  - `path key E2E_DIR: an absolute path is refused by name`.

  HEAD: `lived|0`. O `HANDOFF_DIR=../handoffs` já morre em HEAD por OUTRO motivo (`resolve_mission`),
  e por isso a agulha é o nome da chave.
- A classe é `[A-Z0-9_]` (com `[A-Z_]` some o `E2E_DIR`).

**Mutantes:**
- `RUN_config_path_keys_raw`: `sed -i '/^load_config() {/,/^}/ s|^    printf -v "\$_pk"
  .%s. "\$_pv"$|    :|' "$1"`;
- `RUN_config_path_keys_unvalidated`: `sed -i '/^load_config() {/,/^}/ s|^    adr_dir_ok
  "\$_pv" \\$|    true \\|' "$1"`.

Os dois são pegos pelo `check-gates.sh`. As âncoras pressupõem as linhas exatamente nessas formas:
se a sua grafia diferir, ajuste a âncora e prove com `--only`.
**Check:** contagem de ok `path key …` → `8`.
**Reversível por:** `git revert`.

### I12 — #115: `gate_REVIEW` olha só a rodada; `gate_DOCS` recusa o próprio `45-docs.md` sujo (decisão 8)

**O quê:**
- **Hoje.**
  - `gate_REVIEW` (`bin/sdd` ~:1645) recusa com `if [ -n "$(cd "$REPO_ROOT" && git status
    --porcelain)" ]; then` (~:1811) e `GATE_WHY="working tree dirty after the review — the round
    and its R<n> rows must be committed"` (~:1821). As palavras ANTES do travessão são carregadas
    (`historic_rounds`, `docs/pipeline.md`, `check-autonomy`): fique com o texto verbatim.
  - `derive_phase` (~:2309) anda os gates em ordem.
  - A parada por árvore suja da EXEC (~:1333) só dispara com a suíte VERMELHA: com a suíte verde, a
    sujeira atravessa EXEC e QA e cai no REVIEW.
  - `gate_DOCS` (~:1890) confere só que o `45-docs.md` existe (`[ -f "$d" ]`, ~:1892) e a tabela.
  - O chapéu DOCS commita: `agents/sdd-docs.md:115` "Commit everything".
  - `MISSION_DIR` é absoluto (`$base/$MISSION`, ~:305).
- **Desenho.**
  - **`gate_REVIEW`.** A linha vira `if [ -n "$(cd "$REPO_ROOT" && git status --porcelain
    --untracked-files=all -- "$MISSION_DIR/40-review-r*.md" "$MISSION_DIR/checkpoint.md"
    "$MISSION_DIR/checkpoint-notas.md")" ]; then`, numa linha só. Conferido: o pathspec de git lista
    arquivos não rastreados dentro de diretório não rastreado. O comentário (~:1812-1820) é
    atualizado.
  - **`gate_DOCS`.** Logo depois do `[ -f "$d" ]`, entram:
    ```bash
    if [ -n "$(cd "$REPO_ROOT" && git status --porcelain --untracked-files=all -- "$d")" ]; then
      GATE_WHY="45-docs.md is not committed — a DOCS session that died leaves it on disk; the DOCS phase runs again and commits it with the docs it describes"; return 1
    fi
    ```
  - **Resíduo declarado** (decisão 8), no comentário do `gate_DOCS` como DECLARED LIMIT: uma DOCS
    que commitou o `45-docs.md` mas deixou outro documento sujo chega ao PR com a árvore suja.
- **Contrato e prosa** que ficam falsos e mudam no mesmo commit. Regra: escreva o que passou a
  valer, com o escopo novo nomeado, e nunca apague o fato que ainda vale.
  - `docs/pipeline.md:979-980` e `:1041-1042` ("a dirty tree fails gate_REVIEW") → "a dirty round
    report, `checkpoint.md` or `checkpoint-notas.md` fails gate_REVIEW; an uncommitted `45-docs.md`
    fails gate_DOCS".
  - `agents/sdd-reviewer.md:244-245` ("the gate requires a clean tree") → "the gate requires the
    round's own files committed: `40-review-r<N>.md`, `checkpoint.md`, `checkpoint-notas.md`", com
    `./bin/sdd install --force`.
  - `tests/check-gates.sh:2796`, comentário do mundo 11: "an untracked file it does NOT ignore would
    make the tree dirty and send the mission back to REVIEW". Re-derive o que o arquivo não
    ignorado faria hoje e escreva só isso: ele já não volta ao REVIEW, porque está fora do escopo.
  - `tests/check-gates.sh:3282`: "a plan approved with 01-plano.md and checkpoint.md left as `??` is
    a plan the next gate_REVIEW refuses as a dirty tree". Continua verdade para o `checkpoint.md`
    (está no escopo) e deixa de ser para o `01-plano.md`. Ajuste a frase sem afrouxar a asserção do
    `sdd approve`.
  - `tests/check-dry-run.sh:585`: "a dirty tree fails `gate_REVIEW` and `sdd preflight`". Um
    `pipeline.log` não rastreado continua reprovando o `sdd preflight`; o `gate_REVIEW` não o vê
    mais. Diga isso.
  - `docs/graphify.md:50`: a mesma frase, mesmo ajuste.
  - Os comentários do `bin/sdd` (~:1812-1820 e o do `gate_DOCS`).
  - Confira que não sobrou outro sítio com `grep -rn 'dirty tree fails\|send the mission back to
    REVIEW\|refuses as a dirty tree' bin tests docs agents`.

**Como (TDD)**, em `tests/check-gates.sh`:
- **REVIEW.** Logo antes de `assert_phase "last review all Grade A, suite green, clean tree" "DOCS"`
  (~:1833), em quatro mundos, cada um desfeito antes do próximo:
  1. **Sujeira de fase posterior.**
     `mkdir -p docs/guide && : > docs/guide/new.md; printf '# Docs\n' > "$MDIR/45-docs.md"`, ambos
     não rastreados (o `45-docs.md` incompleto mantém a DOCS como fase derivada). Asserções:
     - `assert_phase "a dirty tree a later phase left does not send the mission back to REVIEW"
       "DOCS"` (HEAD: REVIEW);
     - `assert_why_absent "and the reason REVIEW gives is not the dirty-tree refusal" "REVIEW"
       "working tree dirty after the review"`.

     Desfaz: `rm -rf docs/guide "$MDIR/45-docs.md"`.
  2. **`checkpoint.md` da rodada sujo.** `printf '\n' >> "$MDIR/checkpoint.md"`. Asserções:
     - `assert_phase "a dirty checkpoint.md the review left still holds REVIEW" "REVIEW"`;
     - `assert_why "and the reason REVIEW gives is the dirty-tree refusal" "REVIEW" "working tree
       dirty after the review"`.

     Desfaz: `git checkout -- "$MDIR/checkpoint.md"`.
  3. **`checkpoint-notas.md` não rastreado.** `printf -- '- nota\n' > "$MDIR/checkpoint-notas.md"`
     (o fixture não tem esse arquivo). Asserção: `assert_phase "a dirty checkpoint-notas.md the
     review appended still holds REVIEW" "REVIEW"`.

     Desfaz: `rm -f "$MDIR/checkpoint-notas.md"`.
  4. Depois dos três, a asserção original de ~:1833 (`… clean tree" "DOCS"`) tem de seguir verde.
     Ela é o controle de que o fixture voltou limpo.

  O mundo 2 é o que mata o mutante `REVIEW_dirty_unscoped` pelo lado certo: sem ele, um escopo vazio
  também passaria no mundo 1.
- **DOCS.** No bloco DOCS (~:2255-2258), entre o `printf` do `45-docs.md` COMPLETO e o `git add -A
  && git commit -qm "chore: docs"`:
  - `assert_phase "an uncommitted 45-docs.md holds DOCS, it does not ride to PR" "DOCS"`;
  - `assert_why "DOCS names the uncommitted 45-docs.md" "DOCS" "45-docs.md is not committed"`.

  Em HEAD essa asserção dá REVIEW. Só com a metade do REVIEW daria **PR**, que é o buraco que a
  decisão 8 fecha. Com as duas, DOCS. O `assert_phase` acrescenta ` → <FASE>` à linha ok.

**Mutantes:**
- `REVIEW_dirty_unscoped`: `sed -i '/^gate_REVIEW() {/,/^}/ s|git status --porcelain
  --untracked-files=all -- .*)" \]; then$|git status --porcelain)" ]; then|' "$1"`;
- `DOCS_uncommitted_passes`: `sed -i '/^gate_DOCS() {/,/^}/ s|^  if \[ -n "\$(cd
  "\$REPO_ROOT" \&\& git status --porcelain --untracked-files=all -- "\$d")" \]; then$|  if false;
  then|' "$1"`.

Os dois são pegos pelo `check-gates.sh`. Prove as âncoras com `grep -cF` (1 sítio cada) e com
`--only`.
**Check:** → `1 1`.
**Reversível por:** `git revert`.

### I13 — #63: o gênero do bug é lido do bloco do `Status:`

**O quê:**
- **Hoje.** O awk da Âncora 3 do `gate_QA` (`bin/sdd` ~:1526-1530) pula cercas e imprime a 1ª
  linha com forma de campo fora de uma. O limite declarado está em ~:1512-1517. Reproduzido: prosa
  nua `- **Closable by:** human` acima de um campo real `agent` é lida como `human` (fail-open).
- **Desenho (i, decisão 9).** O gênero é a 1ª `Closable by:` depois da 1ª `Status:` não cercada,
  no mesmo bloco contíguo de `- **X:**`:
  ```
  !/^-[[:space:]]+[*][*][^*]+:[*][*]/ { if (inheader) exit }
  /^[[:space:]]*(```|~~~)/ { fenced = !fenced; next }   # keep VERBATIM: QA_bug_genre_fenced anchors on it
  fenced { next }
  /^-[[:space:]]+[*][*]Status:[*][*]/ { inheader = 1 }
  inheader && /^-[[:space:]]+[*][*]Closable by:[*][*]/ { print; exit }
  ```
  Campo antes do `Status` = ausente = bloqueia (falha segura). `[^*]` é ASCII, seguro no mawk.
- **Contrato** no mesmo commit:
  - `agents/sdd-qa.md:157-160` (+ `./bin/sdd install --force`);
  - `docs/adr/0006-qa-anchor-reads-genre-blocked-handoff-stops-the-line.md:112-115`, o resíduo
    declarado, que agora fecha;
  - `CONTEXT.md:35` ("Resíduo declarado");
  - opcional `docs/pipeline.md:286-290`;
  - os comentários do `bin/sdd` (o limite de ~:1512-1517 sai).

**Como (TDD)**, em `tests/check-gates.sh`. Harness: `write_genre_bug` ~:727, controle `genre_exact`
~:778, regime quote-ABOVE ~:825-834. Modelo: `assert_eq "the genre is the file's OWN field: a quote
ABOVE it does not become the genre" "REVIEW|QA" "$genre_exact|$genre_quoted_above"`.
- **A1** `the genre is read from the Status block: an unfenced quote above the header does not
  become the genre` (prosa nua `human` acima de `Status` + `agent`).
- **A2** `the genre is read from the Status block: a field-shaped line in a later block does not
  become the genre` (cabeçalho legado sem o campo e, mais abaixo, uma linha `human` sem cerca).
- Em HEAD as duas dão `REVIEW|REVIEW`.
- **A3, OBRIGATÓRIO:** `a whole header quoted inside a fence above the real one does not become the
  genre` (verde em HEAD). Sem ele, o mutante existente `QA_bug_genre_fenced` SOBREVIVE ao conserto
  (medido).

**Mutantes:**
- `QA_bug_genre_outside_header`: `s|^      inheader && /^-|      /^-|` (morto pelo A1);
- `QA_bug_genre_header_unbounded`: `s|{ if (inheader) exit }|{ }|` (morto pelo A2).

Cada âncora casa só a linha de código (`grep -cF` → 1). Nunca cite essas strings em comentário.
**Check:** → `2 1`.
**Reversível por:** `git revert`.

### I14 — #121: a porta do `sdd kaizen` aceita um worktree do kit; o irmão vira achado

**O quê:**
- **Hoje.** `cmd_kaizen` (`bin/sdd` ~:10265); o `--series` volta antes da porta (~:10306). A porta
  compara `kit_root="$( cd "$SDD_HOME" && git rev-parse --show-toplevel …)"` (~:10311) com
  `$REPO_ROOT` em ~:10318-10319 (`[ "$kit_root" = "$REPO_ROOT" ] \ || die "…run it in the kit
  repo…"`). Reproduzido: o `bin/sdd` do checkout principal, rodado de um worktree do kit, morre.
- **Conserto (só a porta).** Mantenha `kit_root` para a recusa de não-checkout (~:10316) e troque
  :10318-10319 por:
  ```bash
  local kit_id here_id
  kit_id="$( REPO_ROOT="$SDD_HOME" ledger_repo_root )"; here_id="$( ledger_repo_root )"
  [ -n "$kit_id" ] && [ "$kit_id" = "$here_id" ] \
    || die "sdd kaizen plans the KIT's next mission — run it in the kit repo ($SDD_HOME)"
  ```
  - `ledger_repo_root` (~:3130) lê `${REPO_ROOT:-$PWD}` e não tem globais.
  - Precedente: `kit_id="$( REPO_ROOT="$kit" ledger_repo_root 2>/dev/null )"` em `health_release`
    (~:5912).
  - Doc opcional: `docs/pipeline.md:1068`.
- **O irmão vira achado novo (decisão 5).** O `kaizen_reminder` (~:10066-10068) tem o mesmo
  defeito, reproduzido: do worktree, o `sdd` do checkout principal imprime a frase de repo-alvo
  ("N mission(s) of this repo … The kaizen judge counts them…") no lugar da frase do kit.
  - Registre no `TODO.md`, seção "Comentário e registro" ou "Contrato e configuração": um item de
    ≤ 8 linhas, título com `kaizen_reminder`, âncora `bin/sdd:<linha da comparação>`
    (`kaizen_reminder`), data 2026-10-03, atribuição "descoberto pelo `sdd-planner` na missão
    `20261003-lote-3-a-catraca-desce`".
  - Direção: o mesmo `ledger_repo_root` dos dois lados. Ao consertar, reancore o mutante
    `mut_KAIZEN_reminder_wrong_repo` (~:3376), que ancora nessa linha.
  - Catraca 35 → 36 no MESMO commit.
  - O `kit_guard_check` (~:3722-3726) usa a mesma grafia, mas NÃO é defeito: o carimbo é de
    checkout, e trocá-lo desarmaria a guarda. Não mexa.

**Como (TDD):** na seção `== kit-repo guard ==` de `tests/check-kaizen.sh` (~:1824-1847,
`$KSDD`/`$FIX`, um checkout git real que funciona dentro de mutante), antes de ~:1849:
- `git -C "$FIX" worktree add -q -b kaizen/worktree-fixture "$KWT"`, e `kz_door <cwd>` →
  `"<rc> <refused|admitted>"` sobre `"$KSDD" kaizen --dry-run`.
- Asserções:
  - `kit-repo guard: a linked worktree of the kit answers like the main checkout`, diferencial:
    `$(kz_door "$FIX")` contra `$(kz_door "$KWT")`; HEAD `0 admitted` contra `1 refused`;
  - `kit-repo guard: and the worktree is admitted, not refused`.
- Depois, `git worktree remove --force` + `branch -D`: a asserção de higiene do fim exige o
  fixture limpo. Use `${r#* }`, nunca `| cut`.

**Mutantes** (junto de `mut_KAIZEN_reminder_wrong_repo`):
- `KAIZEN_kit_door_per_worktree`: `sed -i 's@^  \[ -n "\$kit_id" \] && \[ "\$kit_id" = "\$here_id" \] \\$@  [ "$kit_root" = "$REPO_ROOT" ] \\@' "$1"` (morto pelo probe novo);
- `KAIZEN_kit_door_open`: a mesma âncora → `  true \\`, morto pela asserção existente "sdd kaizen
  refuses to run outside the kit repo (rc 1)". Hoje a porta não tem mutante.

**Check:** → `2 1 1 1`:
- as 2 asserções `kit-repo guard:`;
- 1 item aberto com `kaizen_reminder` no título;
- o `check-todo` diz `36 finding(s)`;
- a catraca diz `todo-findings 36`.

Se outro achado nasceu antes do I14, some-o ao 36 nas duas posições e diga isso na nota.
**Reversível por:** `git revert`.

### I15 — #213: a série recusa linha não-objeto e campo ilegível com frase e arquivo

**O quê:**
- **Hoje.**
  - `kaizen_series` (`bin/sdd` ~:9554). Em ~:9564 ele já recusa JSON imparseável com `warn` +
    `return 1`, nunca `die`, porque é lida por `$( )`.
  - O jq grande começa em ~:9586 e lê `< "$file"` em ~:10027, sem capturar o stderr. É o último
    comando da função, então o rc 5 do jq vira o rc do processo.
  - Reproduzido: uma linha objeto com `"cost_usd":"4.0"` dá rc 5 e `jq: error (at <stdin>:2)`, sem
    nome de arquivo. Uma linha array dá rc 0 e `excluded.unrecognized:1`, o que contradiz
    `docs/pipeline.md:1062`.
  - Os cinco consumidores já tratam rc≠0: `kaizen_reminder` (~:10050), `gate_KAIZEN` (~:10125, que
    vira UNREADABLE → `die` no `cmd_kaizen`, sem sessão), ~:10221, ~:10250 e o `--series`
    (~:10306).
- **Conserto.** Espelha `5236206` (o #206 no `cmd_autonomy`, PR #208); leia `git show 5236206`.
  1. Depois do bloco `ledger_parses` (~:9564-9567):
     ```bash
     if [ -s "$file" ] && ! jq -e -s 'all(type == "object")' "$file" >/dev/null 2>&1; then
       warn "unreadable row in $file — a row is valid JSON but not an object; find the writer that produced it"; return 1; fi
     ```
     Mantenha a forma `if`: uma linha `  jq -e -s … \` casaria a âncora de
     `AUTONOMY_shape_not_asked`.
  2. Antes do jq de ~:9586: `local jq_rc=0 jq_err; jq_err="$(mktemp "${TMPDIR:-/tmp}/sdd-kaizen-jq-XXXXXX")" || { warn "kaizen: could not create a temporary file"; return 1; }`.
  3. Em ~:10027, `  ' < "$file" 2>"$jq_err" || jq_rc=$?`. Se rc≠0:
     - `why="$(head -c 400 "$jq_err" | tr '\n' ' ')"`;
     - `rm -f "$jq_err"`;
     - `warn "unreadable row in $file — a row has a field jq could not read: ${why:-jq said nothing (rc $jq_rc)}"; return 1`.

     Remova o temporário também no caminho de sucesso.
  - Medido no ledger real (412 KB): saída byte-idêntica, e a checagem de forma custa 7 ms.
  - `docs/pipeline.md:1062` passa a ser verdade. `docs/failure-modes.md:308-313` ganha as duas
    frases novas.

**Como (TDD):** em `tests/check-kaizen.sh`, antes de `# the two windows over one file` (~:2081),
depois do par corrupt-ledger. Modelo, ~:2063: `assert_eq "corrupt ledger: refused as UNREADABLE, …"
"1 unreadable no-pending-claim no-session" "$( o="$( cd "$FIX" && SDD_STATE_DIR=… "$KSDD" kaizen
2>&1 )"; r=$?; printf … )"`. O `cmd_kaizen` força `LEDGER_ALL_REPOS=1`. Copie o `FIELD_ROW` do
`check-autonomy.sh` (commit 5236206). A saída é o stderr como `"<rc> <named|unnamed> <shape|no-shape>
<jq-words|no-jq-words>"`:
- `series: a field jq cannot read is refused with rc 1, naming the file, quoting jq` →
  `1 named no-shape jq-words` (HEAD `5 unnamed no-shape jq-words`);
- `series: a row that is not an object is refused with rc 1, naming the file, as a shape refusal`
  → `1 named shape no-jq-words` (HEAD `0 unnamed no-shape no-jq-words`).

Sem apóstrofo no texto da asserção.

**Mutantes** (junto de `mut_KAIZEN_series_rc_dropped`):
- `KAIZEN_series_shape_not_asked`: `sed -i "s@^  if \[ -s \"\$file\" \] && ! jq -e -s 'all(type == \"object\")' \"\$file\" >/dev/null 2>&1; then\$@  if false; then@" "$1"`;
- `KAIZEN_series_jq_stderr_swallowed`: `sed -i "s@^  ' < \"\$file\" 2>\"\$jq_err\" @  ' < \"\$file\" 2>/dev/null @" "$1"`.

Os dois são pegos por `--only … check-kaizen.sh`. Os `AUTONOMY_*` irmãos seguem casando só o
próprio sítio.
**Check:** → `2`.
**Reversível por:** `git revert`.

### I16 — #87: o preflight cobra as chaves de dinheiro da linha `result`

**O quê:**
- **Hoje.**
  - O probe do preflight (`bin/sdd` ~:5506-5537) abre UMA sessão real `claude -p …
    --output-format stream-json` (~:5513) e lê só a linha init (`.tools`, ~:5518) e o `.result`
    (~:5519).
  - Os leitores que ficam cegos se a chave mudar:
    - `run_phase` (~:4708 `.total_cost_usd // .cost_usd // "?"`, ~:4719 `.num_turns // ""`);
    - `sdd census` (~:8862 `.total_cost_usd // 0`, sem fallback);
    - `sdd close` (~:10969-10970);
    - `mission_cost_usd` (~:5026), que soma só `cost_usd=[0-9.]+`.

    Com a chave renomeada, o `BUDGET_MISSION_USD` fica cego.
  - O CLI real (2.1.286) ainda emite as duas chaves numéricas.
- **Conserto (estrito, decisão 9).** Ponha `probe_result` no `local` de ~:5508. Depois do `fi` de
  ~:5537, ainda dentro de `if command -v claude`:
  ```bash
  probe_result="$( jq -c 'select(.type == "result")' <<< "$probe_stream" 2>/dev/null | tail -1 )" || probe_result=""
  if [ -n "$probe_result" ]; then
    if jq -e '(.total_cost_usd | type) == "number" and (.num_turns | type) == "number"' <<< "$probe_result" >/dev/null 2>&1; then
      ok "the session's result line carries a numeric total_cost_usd and num_turns"
    else _fail "the session's result line has no numeric total_cost_usd or num_turns — … Keys it got: $(jq -r 'keys | join(" ")' <<< "$probe_result" 2>/dev/null | head -c 300)"; fi
  fi
  ```
  Reusa a MESMA sessão, então custa US$ 0. Um stub morto não dá linha result, e por isso não há
  segunda falha. Doc: `docs/pipeline.md:941-944` ("reading two artifacts" → três).

**Como (TDD):** em `tests/check-preflight.sh`, antes de ~:327 ("Back to the dead stub").
- **O que já existe.**
  - O stub em ~:291-296 é captura verbatim do CLI 2.1.263 (`result-real.jsonl` traz
    `"total_cost_usd":0.0083415`, `"num_turns":1`).
  - `jq -c '.result = "sdd-preflight-ok"' … > result-ok.jsonl` (~:298).
  - O Stub A (~:302-305) faz `cat "$FIX/.stub/init-with-bash.jsonl" "$FIX/.stub/result-ok.jsonl"`.
  - `out_hat_ok="$( "$SDD" preflight 2>&1 )"` (~:306).
  - Modelo, ~:307: `assert_has "a session with Bash in its tool list passes the probe, under the
    executor hat" "headless session under the sdd-executor hat executes commands" "$out_hat_ok"`.
- **Asserções.**
  - Controle positivo sobre `$out_hat_ok`: `a result line with a numeric total_cost_usd and
    num_turns passes the money probe`.
  - Variantes DERIVADAS por jq, nunca digitadas: `.cost_total_usd = .total_cost_usd |
    del(.total_cost_usd)` e `del(.num_turns)`. Elas dão `a result line with the cost key renamed is
    named by preflight` e `a result line without num_turns is named by preflight`, mais um
    `assert_lacks` da linha saudável.
  - Em HEAD, as três positivas FALHAM.

O `check-preflight` roda dentro de mutante (`run-all.sh` ~:347, prazo 240 s; leva ~24 s com a
mudança).
**Mutantes** (junto de `mut_PREFLIGHT_bash_in_init_unchecked`):
- `PREFLIGHT_money_keys_unchecked`: a linha `if jq -e '(.total_cost_usd | type) == "number" and
  (.num_turns | type) == "number"' <<< "$probe_result" >/dev/null 2>&1; then` → `if true; then`;
- `PREFLIGHT_num_turns_unchecked`: tira ` and (.num_turns | type) == "number"`. Só o probe de
  `num_turns` o mata.

**Check:** → `3`.
**Reversível por:** `git revert`.

### I17 — #169: um controle por assassino distinto do mapa, com ele na frente

**O quê:**
- **Hoje.**
  - O mapa `.sdd/cache/mutation-killers.tsv` (gitignored, local) tem `<slug>\t<passo>\t<segundos>`
    em 580 linhas. Exemplo real: `HEALTH_stamp_window_blind	gate state machine	91`. Ele nomeia 10
    assassinos distintos, todos passos de `SDD_MUTANT=1 tests/run-all.sh --list`.
  - Escrito só pelo catálogo inteiro (`tests/check-mutation.sh` ~:6263-6274), lido por
    `load_killer_map` (~:129-137).
  - `run_control` (~:6075-6079) roda `SDD_MUTANT=1 …/run-all.sh` SEM `SDD_MUTANT_FIRST` (e não
    limpa um herdado).
  - `run_mutant` (~:5913) roda com `SDD_MUTANT_FIRST="${KILLER[$slug]}"`. O caminho principal é
    `run_pool "$WORK" run_control run_mutant "${ORDER[@]}"` (~:6204), com veredito em ~:6219.
  - O `--only` em modo suíte tem o mesmo ponto cego (`run_control &` ~:6122).
  - Canal real de efeito de ordem: um `SDD_STATE_DIR` compartilhado por todos os passos
    (`run-all.sh` ~:32-35).
  - Nenhum `mut_*` alcança `tests/`, então a prova é selftest + sabotagem.
  - Os selftests existentes (`order_selftest`, `pool_selftest`) rodam em TODA invocação, inclusive
    `--anchors` (~:258-265), e são silenciosos.
- **Desenho (decisão 9), sem lacuna.** Conferido no código: `run_pool <dir> <control-fn>
  <mutant-fn> <slug...>` (~:188) lança o controle como job 0 e para de lançar quando `control_red
  "$dir"` acha um rc ≠ 0 em `$dir/control.rc`. `control_verdict` fica em ~:157, `pool_selftest` em
  ~:219 (stubs `st_*`, `local JOBS=2 d=…`), e o `run_control` em ~:6075 escreve `$WORK/control.rc`.
  O caminho principal faz `sandbox "$WORK/control"` (~:6190), `load_killer_map` (~:6192), o
  `run_pool "$WORK" run_control run_mutant "${ORDER[@]}"` (~:6204) e imprime `pass "the kit copy is
  green with no sabotage"` (~:6220). O `run-all.sh:382` trata `SDD_MUTANT_FIRST` VAZIO como a ordem
  usual.
  1. **`control_red <dir>`** (~:149) passa a ler TODO `"$1"/control*.rc`, e não só o
     `control.rc`: qualquer arquivo existente com rc não vazio e ≠ 0 → verdadeiro. Nenhum slug do
     `CATALOG` começa por `control` (conferido), então o glob não pega rc de mutante.
  2. **`controls_verdict <dir>`**, nova, ao lado do `control_verdict` (que fica como está, porque o
     `--only` e o `pool_selftest` o usam):
     - chama o `control_verdict` primeiro;
     - depois, para k = 1..`${#FIRSTS[@]}`, exige `"$1/control-first-$k.rc"` = `0`;
     - vermelho ou ausente → imprime `HARNESS-BROKEN: the copy is not green with '<FIRSTS[k-1]>' run
       first (control-first-<k> rc <rc|none>)` e retorna 1.
  3. **Logo depois do `run_mutant`** (~:5902-5930), e portanto ANTES da chamada do selftest em
     ~:5996, definir:
     - `run_first_control <k>`, que faz `local box="$WORK/control-first-$1" rc=0`;
       `[ -d "$box" ] || sandbox "$box"`; `SDD_MUTANT=1 SDD_MUTANT_FIRST="${FIRSTS[$1-1]}"
       "$box/tests/run-all.sh" > "$WORK/control-first-$1.log" 2>&1 || rc=$?`;
       `echo "$rc" > "$WORK/control-first-$1.rc"`.

       O selftest dirige uma caixa stub pré-criando `"$WORK/control-first-<k>/tests/run-all.sh"`
       sob um `local WORK=<dir do selftest>`, por escopo dinâmico. Como a caixa já existe, o
       `sandbox` não roda.
     - `run_job <slug>`, que faz `case "$1" in @first:*) run_first_control "${1#@first:}" ;; *)
       run_mutant "$1" ;; esac`;
     - `distinct_killers`, que faz `printf '%s\n' "${KILLER[@]}" | LC_ALL=C sort -u | sed '/^$/d'`.
       É função para que o selftest a meça.
  4. **`run_control`** (~:6075) passa a rodar com `SDD_MUTANT=1 SDD_MUTANT_FIRST="${CONTROL_FIRST:-}"`.
     O caminho principal deixa `CONTROL_FIRST` vazio, o que dá a ordem usual explícita e sem herdar
     do ambiente. O `--only` em modo suíte faz `CONTROL_FIRST="${KILLER[$ONLY_SLUG]:-}"` antes do
     `run_control &` (~:6122); o mapa já foi carregado em ~:6120.
  5. **Caminho principal.**
     - Depois do `load_killer_map`, `mapfile -t FIRSTS < <(distinct_killers)` (mapa vazio → 0
       controles a mais).
     - Os pseudo-jobs vão à frente: `ORDER=($(for k in "${!FIRSTS[@]}"; do printf '@first:%d ' $((k
       + 1)); done) "${ORDER[@]}")`.
     - O `run_pool "$WORK" run_control run_job "${ORDER[@]}"`, e o fallback sem `wait -n` (~:6206-6216)
       também chama `run_job`.
     - Os pseudo-jobs CONTAM no `POOL_LAUNCHED`. Isso é correto (ocupam slot), e os probes "≤ JOBS"
       do `pool_selftest` não mudam, porque usam stubs.
     - Na pontuação, o laço que lê `$WORK/<slug>.rc` itera o `CATALOG`, nunca o `ORDER`, então os
       pseudo-jobs não pontuam. Confira isso.
     - O `if why="$(control_verdict "$WORK")"` (~:6219) vira `controls_verdict`, e o `pass` passa a
       dizer `the kit copy is green with no sabotage, in the usual order and with each of the
       ${#FIRSTS[@]} killer(s) of the map first`.
  6. **`controls_selftest`**, definida junto ao `pool_selftest` e CHAMADA logo depois do `pass` de
     membership (~:5996), porque o `pass()` só existe a partir de ~:5834. Com `local WORK="$WORK/controls-selftest"
     JOBS=2`, `FIRSTS=(stepA stepB)`, `st_control_green` escrevendo `0` em `$WORK/control.rc`, e
     duas caixas stub cujo `run-all.sh` grava `$SDD_MUTANT_FIRST` em `$WORK/env-<k>` e sai 0 (ou 1
     num mundo):
     - (a) tudo verde → `controls_verdict` 0, `env-1`=`stepA`, `env-2`=`stepB`;
     - (b) a caixa 2 sai 1 → `controls_verdict` ≠ 0 com `stepB` na frase, e um `run_pool` com 8
       mutantes stub lança ≤ JOBS;
     - (c) o rc da caixa 1 apagado → refuse (ausente não é verde);
     - (d) com `KILLER=([x]=stepB [y]=stepA [z]=stepB)`, `distinct_killers` dá exatamente `stepA
       stepB`. Depois, `KILLER=()` e `SECS=()`, como o `order_selftest` faz.

     Ela restaura `FIRSTS=()` no fim. Se passar, imprime `pass "controls: one control per distinct
     killer of the map, that killer first — a red or missing one refuses the score (selftest)"`; se
     falhar, `fail` + `exit 1`, como os outros selftests.
  7. **Comentários.** Atualize `tests/run-all.sh:94` ("no sensor asserts it (TODO.md)") e
     `tests/check-mutation.sh:5944` ("measured, not asserted"). Custo: ≤ +2,5 min num `sdd health`
     de ~40–50 min.
- **Não sondável, declarar:** as linhas do caminho principal que prepõem os pseudo-jobs e chamam o
  `controls_verdict`. A prova é o próximo `sdd health` imprimir `ok    the kit copy is green with no
  sabotage, in the usual order and with each of the N killer(s) of the map first`.

**Sabotagem obrigatória** (o selftest fica vermelho em cada uma):
- `distinct_killers` → `return 0`, ou `sort -u` → `sort` → (d);
- `controls_verdict` lendo só o `control.rc` → (b) e (c);
- rc ausente lido como verde → (c);
- `run_first_control` sem o `SDD_MUTANT_FIRST=` → (a), pelo `env-<k>`;
- `control_red` sem o glob → (b), com `POOL_LAUNCHED > JOBS`.

**Antes do PR (medição, não Check):** rode os 10 controles com o assassino na frente num clone, em
paralelo: `SDD_MUTANT=1 SDD_MUTANT_FIRST="$k" tests/run-all.sh` para cada `k` de
`cut -f2 .sdd/cache/mutation-killers.tsv | sort -u` (5–8 min). A medição 13/13 verde é de
2026-09-25. Um vermelho hoje é dependência de ordem real, deixaria o `sdd health` HARNESS-BROKEN e
para a linha (§ Riscos).
**Check:** ok `controls: one control per distinct killer of the map` no `--anchors` → `1` (~5 s;
prazo do passo 60 s).
**Reversível por:** `git revert`.

### I18 — #192a: `--touched <rev>` seleciona os mutantes que os sensores tocados mataram

**O quê:**
- **Hoje.**
  - `--only <slug> <sensor>` (`tests/check-mutation.sh` ~:6101-6173) prova UM mutante; `only_sensor`
    está aninhado (~:6134) e lê os globais `ONLY_SENSOR`/`ONLY_DEADLINE`.
  - A junção passo → arquivo existe uma vez: `census_join`/`census_file_of` em
    `tests/check-health.sh` ~:1729-1738, sondada em ~:1812.
  - O `check-health.sh` já faz `source` de `killer_of`/`rc_verdict` do `check-mutation.sh` (~:1463,
    ~:1686), com guarda de função curta e fechada.
  - A regra 4 (`check-health.sh` ~:1247-1256) exige exatamente 2 invocações do `check-mutation.sh`
    no `run-all.sh`: o `--touched` NUNCA entra no `run-all.sh`.
  - Protótipo:
    - `89d8e62~1..89d8e62` (tocou gates e health) → 218 mutantes, `HEALTH_stamp_window_blind`
      incluído, ~15 min a 16 jobs;
    - `6ad41f7` (só `tests/check-hat.sh`) → 14 mutantes, 19 s.
- **Desenho (decisão 9).**
  - Mova `census_join`/`census_file_of` para o `check-mutation.sh`, e o `check-health.sh` os
    importa por `source` com a guarda curta-e-fechada existente.
  - `touched_select <rev>`: `git -C "$ROOT" diff --name-only <rev> -- tests/` (uma revisão verbatim;
    inclui a árvore de trabalho quando é uma revisão só) → arquivos de sensor → os slugs cujo
    assassino junta a eles.
  - **Desconhecidos:**
    - sem mapa → **rc 2**, dizendo que o `sdd health` o escreve; nunca "0 selecionados" + rc 0;
    - caminho de `tests/` que não é sensor de mutante (`run-all.sh`, `check-mutation.sh`, fixtures,
      sensores guardados) → nomeado como "o catálogo responde";
    - assassinos sem junção e slugs fora do mapa → contagens com o remédio `--only`;
    - revisão irresolúvel → rc 2.
  - `SDD_KILLERS_FILE` sobrescreve o mapa (precedente: `SDD_MUTATION_JOBS`, `SDD_ONLY_DEADLINE`).
  - O fixture versionado é `tests/fixtures/killers-touched.tsv`: dois slugs reais do `check-hat` e um
    de `check-gates` que NÃO pode ser selecionado num diff só de hat. Fixtures são DADOS.
  - `--touched <rev> --list` imprime a seleção.
  - Selftest num repo git de fixture + mapa de fixture, chamado onde roda em todo modo (como o I17),
    imprimindo `ok    touched: the diff selects the mutants its sensors killed (selftest)`.

**Sabotagem obrigatória:**
- diff de `rev..HEAD` em vez da árvore;
- junção removida (tudo selecionado);
- sem mapa → rc 0;
- caminho não mapeado não reportado;
- slug de gates selecionado num diff só de hat.

**Check:** ok `touched: the diff selects the mutants its sensors killed` no `--anchors` → `1`.
**Reversível por:** `git revert`.

### I19 — #192b: o caminho de execução do `--touched`, o veredito e a dica

**O quê (decisão 9: S, só dica):**
- **Execução.**
  - Para cada mutante selecionado, roda SÓ o sensor assassino, pelo `only_sensor` içado e
    parametrizado (o `--only` tem de seguir byte a byte igual em comportamento), no `run_pool`
    existente.
  - O controle de cada sensor tocado roda sozinho na cópia sem sabotagem.
  - Imprime, antes de rodar, a estimativa (soma dos segundos do mapa ÷ `JOBS`).
- **Veredito:** `  ok    touched: <k> of <n> selected mutant(s) still caught by their killer`. Um
  "perdido" imprime o comando `--only <slug>` para escalar. O `--touched` não reescreve o mapa e
  não imprime `score:`.
- **Documentação.**
  - No usage do `check-mutation.sh` (~:12-18 e o `USAGE` de ~:39).
  - No `CLAUDE.md` § TDD aqui dentro, ao lado do `--only`, como **dica**: rode antes de commitar
    mudança em sensor. É dica, não gate: o `sdd-executor.md` NÃO muda (decisão 9).

**Sabotagem:** "perdido" lido como pego; a seleção ignorada (roda tudo).
**Check:** `SDD_KILLERS_FILE=tests/fixtures/killers-touched.tsv tests/check-mutation.sh --touched
6ad41f7~1..6ad41f7` imprime o ok `touched: 2 of 2 selected mutant(s) still caught by their
killer` → `1` (~10 s).
**Reversível por:** `git revert`.

### I20 — Fecho: `RESOLVED by`, KAIZEN_LOG, handoff da EXEC e a suíte inteira

**O quê:**
1. **`chore(todo)`.** Os 13 itens consertados ganham ` RESOLVED by <hash>`, com o hash do
   incremento na célula Commit do `checkpoint.md`. Item no teto de 8 linhas recebe o token no fim
   de uma linha do corpo com folga (≤ 120 caracteres); o #212 já está no teto. O #113 cita também
   `eb0ee9e` para a metade dos 3 espaços. A catraca NÃO desce aqui: desce no chore pós-merge.
2. **`KAIZEN_LOG.md`.** Uma entrada com o antes e o depois medidos:
   - catraca 57 → 35 + N na branch (36 com N = 1) → 22 + N depois do merge (23 com N = 1);
   - 13 consertos, dos quais 5 fail-open, com o número de mutantes novos;
   - 22 saídas sem código;
   - o achado nascido.

   Cite o slug da missão.
3. **`20-handoff-exec.md`.** Do `templates/handoff.md`, com o `## TL;DR` de no máximo 20 linhas
   que o `handoff_tldr_ok` cobra. É o artefato da fase EXEC, e com ele `./bin/sdd why <missão>
   EXEC` lê a fase honesta.
4. **Prova.** `bash tests/run-all.sh` → rc 0, `tests/check-mutation.sh --anchors` → todos aplicam,
   e `bash tests/check-todo.sh` → `every anchor on target`.

**Check:** → `0 1 13 20 1`:
- a suíte dá rc 0;
- a contagem do `check-todo` é igual à da catraca;
- 13 `RESOLVED by` na seção aberta;
- 20 registros decididos (5 + 13 + 2);
- o slug está no `KAIZEN_LOG.md`.

**Reversível por:** `git revert`.

## Depois do checkpoint (decisão 6 — sem incremento)

1. `git push -u origin fix/lote-3-a-catraca-desce`, e um PR contra a `main` com:
   - o saldo "57 → 22 + N nascidos";
   - a lista dos 13 `RESOLVED by` e das 22 saídas;
   - a testemunha do I10 (ui24) e a medição dos 10 controles do I17.

   O repo é **público**, mas o Actions não entra: a verificação é local (`CLAUDE.md` global).
2. **Esperar TODOS os bots.** CodeRabbit (1 revisão por hora); Copilot (sem cota); Codex. Consertar
   numa leva só. Achado de bot é hipótese até medir.
3. **`./bin/sdd health` UMA vez**, depois do último commit de código e com os bots respondidos
   (~40–50 min; 39 min na última rodada, com 580 mutantes). O humano dispara, com o lançador desanexado. Ele carimba, e o `gate_PR` exige o
   carimbo. Rodada que só mexe em prosa não pede outro.
4. **Merge pelo humano.**
5. **Chore pós-merge**, numa branch `chore/todo-pos-merge-lote-3`:
   - apaga os 13 itens, provando cada um com `git merge-base --is-ancestor <hash> origin/main`;
   - catraca 35 + N → 22 + N;
   - PR e merge.
6. **Re-sync do espelho, na `main` atualizada.** `S=~/.claude/skills/todo-to-github-issues/scripts/todo_issues.py`;
   `python3 $S` (plano) → `--apply --limit 1` (canário) → `--apply` → `--apply --close-orphans`.
   - Os 13 consertados fecham como `fixed by <hash>`.
   - As 22 saídas aparecem como `SKIP`: feche cada uma à mão com `gh issue close N -R
     j0ruge/sdd_agents --reason "not planned" --comment "<destino: decidido / cabeçalho de <sensor> /
     CONTEXT.md Y5-Y6>"`.
   - Os nascidos viram CREATE.
   - Conte: `gh issue list -R j0ruge/sdd_agents --label todo --state open --limit 200 --json number
     --jq length` = a catraca.

## Riscos e não-feitos

| Risco | Probabilidade | Mitigação |
|---|---|---|
| Âncora do `TODO.md` deslocada deixa o `check-todo.sh` (no `TEST_CMD`) vermelho | alta — medido nos protótipos: o I11 sozinho desloca 10 | `check-todo.sh --anchors` + `remap.py` + `xref.py --fix` antes de TODO commit |
| Um dos 10 controles do I17 fica vermelho (dependência de ordem real) | baixa (13/13 em 2026-09-25) | Jidoka: para a linha, investiga o passo; se não couber na leva, registra o achado (decisão 5) e o I17 não entra até o health ficar verde |
| Conserto que abre fail-open ao lado (o #194 descreve a classe) | média | passada de sabotagem/`--only` em todo incremento; o defeito criado pela leva se conserta nela (decisão 5) |
| O I11 recusa uma chave de config de alvo real | baixa — os 10 alvos usam valores simples | o `die` nomeia a chave e o valor cru; o schema documenta a gramática |
| Revisão dos bots pede consertos em `bin/`/`tests/` depois do health | média | health só depois de todos os bots (passo 3) |
| A sessão perde o fio entre incrementos | média | checkpoint + notas são a trilha; cada incremento fecha com commit |
| O `sdd health` some no meio (kill, fechar terminal) | baixa | lançador desanexado; o carimbo só nasce verde |

**Não-feitos deliberados:**
- os 22 DEC (leva 4);
- consertar o `kaizen_reminder`, que é só registrado;
- sensor para prosa de contrato do `commands/` (#109, leva 4);
- `CHANGELOG.md` (decidido, #122).

## Verificação end-to-end

1. **No topo da branch**, depois do I20:
   - `bash tests/run-all.sh` → `suite green` (rc 0);
   - `tests/check-mutation.sh --anchors` → todos os mutantes aplicam (580 + os novos);
   - `bash tests/check-todo.sh` → `<35 + N> finding(s) … every anchor on target` (36 com N = 1);
   - `awk '/^todo-findings /{print $2}' tests/health-baseline.txt` → o mesmo número.
2. **As 22 saídas.** Nenhum dos 22 títulos está na seção aberta. Confira cada um com `awk` entre os
   marcadores: há 20 registros decididos, `Y5` e `Y6` no `CONTEXT.md`, e os 5 cabeçalhos com o slug.
3. **Os 13.** `RESOLVED by` em cada um, com `git merge-base --is-ancestor <hash> HEAD` verdadeiro.
4. **O `/sdd-plan`.** A seção do repasse e o bullet do trabalho longo estão no `commands/sdd-plan.md`;
   a frase do relay está no chapéu; o espelho está byte a byte igual.
5. **Depois do health.** `sdd health` verde, carimbo válido; `./bin/sdd why
   20261003-lote-3-a-catraca-desce PR` sem a recusa do carimbo.
6. **Depois do merge e do chore.** Catraca 22 + N (23 com N = 1) e espelho de issues igual à
   catraca.
