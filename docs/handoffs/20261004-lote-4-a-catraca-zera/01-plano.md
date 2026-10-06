---
missao: 20261004-lote-4-a-catraca-zera
data: 2026-10-04
---

# Plano — Lote 4: a catraca zera

> **Teste de autocontenção:** uma sessão nova, sem nenhuma memória da conversa que gerou este
> plano, lendo apenas `00-missao.md` + `01-plano.md` + `checkpoint.md`, consegue executar?
> Se a resposta for "só se souber X", **X vai escrito aqui**.

## Passo 0 — antes do I1 (não é incremento)

A missão foi escrita com o checkout do humano parado na branch `fix/lote-3-a-catraca-desce`, já
mergeada. Lá o `TODO.md` ainda tem 36 itens, os da `main` de antes do chore. Os arquivos da missão e
a ADR 0015 estão **não rastreados** nesse checkout. A branch da missão tem de nascer de
`origin/main` = `fe9441d`, que tem o chore #220 (catraca 23). Nascer da branch do lote 3 traria o
`TODO.md` com 36 itens.

1. `git fetch origin && git status --short` deve mostrar só os dois caminhos não rastreados:
   `?? docs/adr/0015-the-stamp-is-not-headless.md` e
   `?? docs/handoffs/20261004-lote-4-a-catraca-zera/`.
2. `git switch -c fix/lote-4-a-catraca-zera origin/main`. Os não rastreados vão junto, porque
   nenhum dos dois existe na `main`.
3. `git add docs/adr/0015-the-stamp-is-not-headless.md docs/handoffs/20261004-lote-4-a-catraca-zera/`
   e um commit `docs(plan): missão 20261004-lote-4-a-catraca-zera e a ADR 0015`, com o porquê no
   corpo e o trailer da sessão.
4. Confira: `bash tests/check-todo.sh` → `  ok    23 finding(s) …`;
   `./bin/sdd why 20261004-lote-4-a-catraca-zera PLAN` → `plan approved …`.

`sdd approve` **não** é o caminho aqui. Com `aprovacao: auto` ele não tem o que aprovar. Rodado da
branch do lote 3, o `ensure_mission_branch` cortaria a branch nova **dali**, e não da `main`.

Se a `aprovacao:` estiver **vazia** quando você chegar aqui (o PLAN-AUTO fechou com algum ✗), faça
os passos 1 a 3 e então rode `sdd approve 20261004-lote-4-a-catraca-zera` **já na branch da missão**.
Aí ele não corta branch nenhuma, só grava `humano-<data>` e commita.

**O fluxo de cada incremento** é o padrão da casa, que os lotes 1–3 usaram:

1. Red observado pelo motivo certo, com o Check da tabela rodado **antes** do conserto e a saída
   anotada.
2. Conserto.
3. Sabotagem do conserto: `--only` no mutante, ou a passada de sabotagem do selftest.
4. Sensores tocados, `shellcheck -S warning` e, se `bin/` mudou, `--anchors`.
5. Re-âncora do `TODO.md`.
6. O commit do incremento: um por item de conserto. As saídas de um mesmo I1, I2 ou I4 vão num
   commit só.
7. Por último, um commit SEPARADO `chore(checkpoint): I<n> done (<hash>)`, com a linha do
   `checkpoint.md` (Status `done` e o hash curto nu do commit do passo 6) e uma nota appendada ao
   `checkpoint-notas.md` (`>>`, nunca reescrever). A nota diz o Red medido, os desvios e as
   sabotagens.

**A anatomia do agente muda no MESMO commit do incremento que toca o componente** (regra do
`CLAUDE.md`, "Os sete componentes de um agente têm rule própria"). A edição é interativa:
`.claude/rules/anatomia-do-agente.md`, que sessão headless não escreve.

| Incremento | Seção da anatomia |
|---|---|
| I7 | §4: o `--red` é ferramenta do planner, não gate |
| I10 | §4/§5: o repo do kit passa a `ADR_CHECK=block` |
| I12 | §4: a chave do carimbo inclui `agents/` |
| I13 | §7: o `sdd run` para no carimbo com rc 2, sem sessão |
| I15 | §5: `runner_sha` no ledger |
| I16 | §6: o config relido por volta, com a foto do ambiente |
| I18 | §7: a porta humana `sdd note-manual`, que o designer já previu |
| I19 | §5: a dica do `sdd status` |

O I24 só confere.

## Contexto verificado (não re-descobrir)

Tudo abaixo foi medido em 2026-10-04 sobre `origin/main` = `fe9441d`, árvore limpa, por quatro
verificadores e cinco designers, cada um num clone próprio. Os números de linha envelhecem a cada
commit: ache pelo **símbolo** citado, nunca só pelo número.

### Estado e números de partida

- `bash tests/check-todo.sh` → `  ok    23 finding(s), all within 8 lines, carrying anchor + date,
  every anchor on target`; `tests/health-baseline.txt` → `todo-findings 23`.
- Os 23 itens são os 22 DEC de `docs/handoffs/20261003-lote-3-a-catraca-desce/triagem-57.md` mais o
  `kaizen_reminder`, nascido no lote 3.
- **N**, em todo este plano, são os achados que nascem durante a leva. A catraca:
  - na branch: 23 → 16 + N ao fim do I4, porque as 7 saídas decididas saem na hora;
  - depois do chore pós-merge: 0 + N, porque os 16 `RESOLVED by` só saem então.
- Suíte: `env -u CLAUDECODE TMPDIR=/tmp bash tests/run-all.sh` → rc 0, `suite green`, 306 s, 1790
  linhas `^  ok `. O último passo imprime `anchors: all 593 mutants still apply and leave valid code`.
  - ⚠️ Com um `TMPDIR` de ~100 caracteres (o do harness), uma asserção do kit-guard em
    `check-autonomy.sh` reprova; está declarado no sensor desde `0c0e13a`. Rode a suíte com
    `TMPDIR=/tmp`.
- Catálogo: **593** mutantes (`grep -cE '^mut_[A-Za-z0-9_]+\(\)' tests/check-mutation.sh`).
- Carimbo **inválido**: o `.sdd/logs/mutation-stamp` diz `edd14ad2…` (a `main` antiga), e o #219
  entrou sem carimbo por decisão do humano. O `gate_PR` desta missão exige um `sdd health` verde
  depois do último commit de código.
- Chave do carimbo: `bin/sdd:2095` `readonly MUTATION_STAMP_PATHS=(bin tests templates config)`,
  menos `:2096` `tests/health-baseline.txt` (ADR 0014). A identidade de comportamento é
  `bin/sdd:3638` `readonly KIT_BEHAVIOR_PATHS=(bin agents templates config)`.
- `bash tests/check-lang.sh` → `  ok    0 of 56 surface path(s) still in the allowlist, 0 new`.
  - ⚠️ Com a ADR 0015 commitada no passo 0, a contagem passa a `0 of 57`: o glob `docs/adr/*.md`
    a lê. Medido com o arquivo presente.
- Espelho dos agentes: os 8 `agents/*.md` são byte a byte iguais aos de `.claude/agents/` (`cmp -s`).
- Janela do juiz: `sdd kaizen --series` → `guard: missions_after_change 1, floor 3,
  window_broken true`.
- `ADR_CHECK="warn"` (`.sdd/config.sh:30`). `./bin/sdd adr check` → rc 0,
  `info  14 mission(s) have no decided 'adr:'`.

### Mecânica da casa que todo incremento usa

- **Suíte:** `env -u CLAUDECODE TMPDIR=/tmp bash tests/run-all.sh` → última linha `suite green`
  (rc 0), ~5 min.
  - Rode-a inteira depois do I4, do I10, do I16, do I20 e no I24.
  - Entre elas, antes de cada commit, rode os sensores que o incremento toca, mais
    `bash tests/check-todo.sh`, `bash tests/check-lang.sh` e `bash tests/check-pipefail.sh` sempre
    que `tests/` ou `bin/` mudarem.
- **Mutante novo** = função `mut_<SLUG>() { sed -i '…' "$1"; }` em `tests/check-mutation.sh`,
  **mais** o `<SLUG>` no array `CATALOG=(` (`:5491`).
  - Modelo: `mut_QA_handoff_status_enum_open` (`:717`): sed com faixa `/^gate_QA() {/,/^}/` e âncora
    em CÓDIGO, nunca em número de linha.
  - `apply_mutant` (`:6137`) só sabota `bin/`.
  - Prove com `tests/check-mutation.sh --only <SLUG> <sensor>`. O sensor vai como **nome nu**
    (`check-gates.sh`); com caminho, o comando sai rc 2. A linha verde é
    `  ok    <SLUG> — check-gates.sh dies (rc 1)`.
  - Depois rode `tests/check-mutation.sh --anchors` (segundos): todo mutante tem de **aplicar**.
  - Mexeu num sensor? `tests/check-mutation.sh --touched <rev> --list` lista os mutantes que ele
    matou na última rodada (é dica).
- **Sensor que a mutação não alcança** (tudo em `tests/`, mais probe de texto de chapéu e de
  template): a regra nova ganha probe no `selftest()`, e o executor faz a **passada de sabotagem**.
  - Degrade a regra (as sabotagens estão listadas em cada incremento) e exija o selftest vermelho
    em cada uma.
  - Antes, prove que a sabotagem **aplicou**: probe que não mudou o arquivo conclui em falso.
  - Ajudante: `~/.claude/plans/2026-10-03-helpers/sab.sh <nome> <arquivo> '<perl-expr>' <sensor>`.
    Ele clona o kit com as mudanças não commitadas, aplica um `perl -0pi -e`, morre alto se nada
    mudou e roda o sensor.
- **Âncoras do `TODO.md` deslocam a cada commit que move linhas** em `bin/sdd` ou `tests/*.sh`, e o
  `check-todo.sh` está no `TEST_CMD`. Antes de cada commit:
  - `bash tests/check-todo.sh --anchors TODO.md` lista as âncoras e diz "nearest X is at line N"
    para as que saíram do alcance;
  - `~/.claude/plans/2026-10-03-helpers/remap.py <rev-anterior>` reescreve a 1ª âncora de cada
    item, e `~/.claude/plans/2026-10-03-helpers/xref.py HEAD --fix` realoca as demais pelo conteúdo;
    rode SEMPRE os dois;
  - confira pelo conteúdo: `git show HEAD:<arquivo> | sed -n '<N>p'` (aqui o pipe é de shell, não
    de Check).
  - ⚠️ Desde o I5 a âncora mede o **símbolo designado** (o slot `` (`<símbolo>`) ``), e a dica
    "nearest" passa a nomear esse símbolo: re-ancore pela dica.
- **Hook do repo** (`.claude/settings.local.json`, PostToolUse no Bash). Todo comando cujo TEXTO
  contém `git commit` apaga:
  - os diretórios do scratchpad de UM nível que tenham `bin/sdd`. Medido no planejamento: um export
    sumiu assim;
  - os `/tmp/sdd-*` com mais de 10 min.

  Clone de rascunho mora **dois níveis** abaixo do scratchpad (`scratchpad/x/kit`). Nunca commite
  com um `sdd health` rodando.
- **Shell é zsh:**
  - nunca use `path` como nome de variável;
  - escreva `"${r}:arquivo"`, nunca `$r:arquivo`;
  - `echo ====` falha (ponha aspas);
  - não há `/dev/tcp`;
  - envolva laços e pipelines em `bash -c '…'`.
- **Espelho dos agentes:** `agents/sdd-*.md` → `.claude/agents/` só por `./bin/sdd install --force`
  (nunca `cp`, nunca Edit). O `sdd preflight` reprova `agent <nome> stale`. Rode-o no MESMO
  incremento que mexe num chapéu.
- **`shellcheck -S warning`** nos arquivos tocados antes de cada commit em `bin/` ou `tests/`.
  Medido no lote 3: o SC1010 do I7 só apareceu na suíte inteira e custou um commit a mais.
- **Idioma:**
  - `bin/`, `agents/`, `docs/` (fora de `docs/handoffs/`, `docs/qa/` e `docs/superpowers/`),
    `README.md`, `config/schema.md`, `config/starter.conf` e `tests/` são superfície **inglesa**;
  - `TODO.md`, `CONTEXT.md`, `CLAUDE.md`, `KAIZEN_LOG.md`, `templates/` e os handoffs falam pt-BR;
  - o slug `20261004-lote-4-a-catraca-zera` não tem stopword do `check-lang`, então pode ser citado
    em comentário de `tests/`.
- **Checks** (`templates/checkpoint.md`, cobrados por `tests/check-checkpoint.sh`, que escaneia
  ESTE checkpoint também):
  - célula com `2>&1` e `grep` exige **todo** `grep` ancorado em `^  ok    `, e as contagens de
    arquivo nas células mistas usam `awk`;
  - nunca `|` cru, nem `||`;
  - forma estrita `` `cmd` → `esperado` ``;
  - o `run-all.sh` imprime `suite green` sem o prefixo ok, então se lê pelo rc.
- **Formato do `TODO.md`:**
  - **Item aberto:** teto de 8 linhas físicas e 120 caracteres por linha.
  - **Registro decidido:** UMA linha física:
    `- **<título sem *>** — <o quê e porquê> — `<evidência>` (YYYY-MM-DD)`.
  - **Conserto por commit:** o corpo ganha ` RESOLVED by <hash>` no I24, e o item só sai no chore
    pós-merge (`templates/todo.pt-BR.md` § Ciclo de vida).
  - **Saída por decisão:** remove o item **e** move a catraca no MESMO commit.
- **Commits:** `<tipo>(<escopo>): <o quê>`, com o porquê no corpo, um por item, com o trailer da
  sessão.

### Fatos que atravessam incrementos

- **De onde vêm os números de linha.** Cada seção de incremento foi desenhada e provada por um
  designer, num clone próprio de `fe9441d`, às vezes com o "passo 0" ou com os incrementos anteriores
  simulados. As linhas citadas são as **daquele** protótipo. Depois que os incrementos anteriores
  pousarem, ache pelo **símbolo** e re-meça. Os textos exatos (código, prosa, linhas decididas)
  valem como estão.
- **Protótipos, só como acelerador opcional.** Ficam no scratchpad do planejamento, que pode ter
  sumido:
  `S=/tmp/claude-1001/-home-joruge-repos-sdd-agents/b11f78c4-8c0b-49aa-87ee-b43a6c23a66c/scratchpad`.

  | Designer | Incrementos | Onde |
  |---|---|---|
  | A | I1–I4, I9, I10 | `$S/design-A/patches2/` |
  | B | I5, I23 | `$S/design-B/I5.patch`, `$S/design-B/I23.patch` |
  | C | I7, I8, I21, I22 | `$S/design-C/patches/` |
  | D | I11–I16 | `$S/design-D/final-all.patch` |
  | E | I17–I20 | `$S/design-E/patches/` |
  | planner | I6 | `$S/I6.patch` |

  O plano é a fonte. O patch é o protótipo de **um** designer sobre `fe9441d` e pode não aplicar
  sobre os incrementos anteriores.
- **Catálogo:** 593 → **612**, com 19 mutantes novos:

  | Incremento | Novos |
  |---|---|
  | I11 | 1 |
  | I12 | 1 |
  | I13 | 2 |
  | I15 | 2 |
  | I16 | 3 |
  | I17 | 4 |
  | I18 | 2 |
  | I19 | 1 |
  | I20 | 2 |
  | I23 | 1 |

  Quatro são re-ancorados: `KAIZEN_reminder_wrong_repo` no I11, e `LEDGER_gate_pass_unrecognized`,
  `LEDGER_gate_pass_not_admitted` e `KAIZEN_close_not_admitted` no I17. Nenhum mira `tests/`.
- **Mutante de um incremento pode perder a âncora num incremento seguinte**, quando o texto que o
  `sed` casa muda. Antes de cada commit, `tests/check-mutation.sh --anchors` diz quem não aplica
  mais. Re-ancore no MESMO commit e re-prove com `--only`.
- **Pontos de contato entre incrementos de designers diferentes**, cada um provado só sobre
  `fe9441d`:
  - ledger: I15 (`runner_sha` em `autonomy_append`) × I17/I18 (o evento `manual` e o construtor
    `autonomy_phase_fact_row`);
  - `gate_PR`: I13 (marcador `GATE_PR_STAMP_WHY`) × I20 (`mission_qa_report`, que o `gate_PR` também
    consome);
  - lista de topo do `tests/check-hat.sh`: I2, I3, I4, I6 e I14 acrescentam probes;
  - `tests/check-templates.sh`: I1, I2 e I8;
  - `tests/check-autonomy.sh`: I15, I16, I17 e I18;
  - `tests/check-gates.sh`: I12, I13, I19 e I20;
  - o array `CATALOG=(`, que todo incremento de runner estende.

  Rode o sensor inteiro do ponto de contato, não só a asserção nova.
- **As listas de âncoras abaixo e as de cada seção foram medidas antes do I1 e do I5.** O #130
  (`docs/pipeline.md:1028`) sai no I1, e a âncora dele deixa de importar. O #129 e o #108 são
  re-designados no I5. Quando uma seção e o I5 discordarem, vale a dica do
  `bash tests/check-todo.sh --anchors TODO.md` no momento.
- **Âncoras do `TODO.md` que os designers mediram deslocando:**
  - `bin/sdd:2092`, `:4315`, `:9623` e `:10156`;
  - `agents/sdd-executor.md:76`;
  - `agents/sdd-publisher.md:42`, que vai à mão para a linha nova no I14;
  - `docs/pipeline.md:1028`, que o I8 e o I13 tiram do alvo;
  - `tests/check-lang.sh:52` e `:180`, que vão à mão no I21;
  - as secundárias `tests/check-autonomy.sh:6493` e `tests/check-mutation.sh:6104`, que o `remap.py`
    marca `NOT-REWRITTEN` e o `xref.py HEAD --fix` resolve.

  ⚠️ O `remap.py` e o `xref.py` têm `ROOT=/home/joruge/repos/sdd_agents` fixo. Rodados no checkout
  da missão, estão certos; num clone, reescreveriam o repo real. O `sab.sh` também tem `ROOT` fixo, mas
  só **lê** dele: clona e sabota a cópia.
- **Ajudantes fora do repo** em `~/.claude/plans/2026-10-03-helpers/`: `remap.py`, `xref.py`,
  `sab.sh`, `todo_rm.py` e `resolved.py`. Existem nesta máquina e não são versionados. Cada passo que
  os usa dá para fazer à mão, sem o ajudante: re-âncora pelo `--anchors`, remoção e `RESOLVED by` por
  edição do `TODO.md`, e sabotagem com `cp` + `sed` numa cópia.
- **A partir do I5 todo item aberto precisa do slot** `` (`<símbolo>`) `` logo depois da âncora.
  Achado nascido na leva também precisa, ou o `TEST_CMD` reprova.
- **Os Checks com contagem absoluta** (`19/17/16 finding(s)`, `todo-findings N`) valem no commit do
  próprio incremento e deixam de valer quando o seguinte move a catraca. Esse é o regime previsto.
  Um N > 0 antes do I4 desloca os números: some N.
- **Achados laterais já embutidos nos incrementos:**
  - I4 também conserta a 2ª promessa falsa do chapéu do TICKET (`agents/sdd-ticket.md:58`, "an issue
    created in the backlog does not pass"; o gate só exige `sprint:` não vazio, `bin/sdd:1131`);
  - I11 conserta o 3º comentário podre do `188ca87`, no heredoc de `tests/check-gates.sh:2711`;
  - I5 revela e migra 2 âncoras podres que a regra antiga deixava passar (`bin/sdd:4315` do #129 e
    `tests/check-lang.sh:180` do #108).
- **Mudança de comportamento a declarar no PR** (I16): a volta 1 do `sdd run` passa a ler o config da
  branch da missão. O `load_config` original roda antes do `ensure_mission_branch`.
- **`~/.claude/commands/sdd-plan.md` é symlink para `commands/sdd-plan.md` deste checkout.** O I6 e o
  I21 mudam o `/sdd-plan` do humano na hora.

## Arquitetura da mudança

Cinco frentes. Nenhuma cria daemon, banco ou servidor (princípio 6). Duas mudam contrato entre
módulos: o evento `manual` do ledger e o campo `runner_sha`. As outras apertam guardas e sensores que
já existem.

| Frente | Incrementos | Arquivos | Contrato / ADR |
|---|---|---|---|
| Saídas sem código e promessas de chapéu | I1–I4, I6 | `TODO.md`, `CONTEXT.md` (Y7, Y8), `templates/checkpoint.md`, `agents/sdd-{executor,planner,ticket,docs}.md` (+ espelho), `commands/sdd-plan.md`, gaveta, cabeçalho do `check-templates.sh`, comentário do `gate_TICKET` | nenhum contrato novo; o enum de status do checkpoint **não** muda (decisão 2) |
| Sensores do plano e do backlog | I5, I7–I10 | `tests/check-todo.sh` (símbolo designado), `templates/todo*.md`, `tests/check-checkpoint.sh` (`--red`), `agents/sdd-planner.md`, `templates/missao.md`, `config/starter.conf`, `config/schema.md`, `docs/adr/0003\|0004\|0006`, 14 `00-missao.md` antigos, `.sdd/config.sh` | ADR 0015 §2 (emenda a 0011); `ADR_CHECK=block` |
| Runner: carimbo, fase PR, ledger, config | I11–I16 | `bin/sdd` (`kaizen_reminder`, `MUTATION_STAMP_PATHS`, `gate_PR`/`cmd_run`, `autonomy_append`, `load_config` no laço), `agents/sdd-publisher.md`, `docs/pipeline.md`, `docs/failure-modes.md`, `config/schema.md` | ADR 0015 §1 (emenda a 0004 e 0014); campo aditivo `runner_sha` |
| Runner: fase feita à mão e posse do relatório | I17–I20 | `bin/sdd` (`cmd_autonomy`, `kaizen_series`, `cmd_note_manual`, `cmd_status`, `mission_qa_report`), `docs/pipeline.md` | evento `manual` (DDD D4/D5); ADR 0015 §3 (emenda a 0013) |
| Régua de idioma e schema da série | I21–I23 | `tests/check-lang.sh` (censo), `docs/plan-only.md`, `commands/sdd-plan.md`, `CLAUDE.md` § Idioma, pisos de `run-all.sh`/`check-pipefail.sh`/`check-checkpoint.sh`, `tests/check-kaizen.sh`, `docs/pipeline.md` (bloco `sdd:series-fields`), `sandbox()` | ADR 0015 §4 |

```
ledger de autonomia (~/.sdd/autonomy-log.jsonl)
  escritores: run_phase ──┐                      leitores (uma definição de evento por programa):
  gate_pass ──────────────┼── autonomy_append ──►  cmd_autonomy  (visão humana: vê o `manual`)
  sdd note-manual (I18) ──┘   + runner_sha (I15)   kaizen_series (juiz: admite o `manual`, não pontua)
                                                   cmd_status    (I19: sugere note-manual)
```

A ordem dentro do #153 é **leitores (I17) → escritor (I18) → dica (I19)**. Assim nenhum commit da
leva deixa o escritor emitir um evento que um leitor ainda chamaria de `unrecognized` (DDD D3-v;
`docs/pipeline.md`, que pede os dois leitores no mesmo commit do evento novo).

## Incrementos

A tabela executável vive em `checkpoint.md`. Aqui fica o **porquê** de cada fatia. A ordem é:

1. primeiro as saídas sem código e as promessas dos chapéus (I1–I4), que encolhem o `TODO.md`;
2. depois a regra da âncora (I5), para que toda re-âncora seguinte já siga a dica certa, e o
   `/sdd-plan` com a pergunta YES/NO (I6, decisão 7);
3. depois os sensores do plano e do alvo (I7–I10);
4. depois o runner (I11–I20);
5. depois a régua de idioma e o schema da série (I21–I23);
6. por fim o fecho (I24).

### I1 — Saídas por decisão escrita: #88, #130, #155, #109 (catraca 23 → 19)

**O quê:** quatro itens saem da seção aberta do `TODO.md` sem código:
- **#88** (`.sdd/logs/` não tem poda…) → linha **Y7** na tabela "Decisões adiadas por YAGNI" do `CONTEXT.md`
  (logo depois da Y6).
- **#130** (35% do `docs/pipeline.md`…) → registro decidido.
- **#155** (`Test Coverage` = A do revisor…) → registro decidido + a gaveta § F3 atualizada (a T3 se desfaz).
- **#109** (Nenhum instrumento mede prosa de CONTRATO…) → registro decidido + LIMITE declarado no cabeçalho
  do `tests/check-templates.sh`.
- `tests/health-baseline.txt`: `todo-findings 23` → `todo-findings 19`, no mesmo commit.

**Onde:** `TODO.md` (seção aberta: os 4 itens, por título; seção `<!-- sdd:decided -->`: 3 linhas no fim);
`CONTEXT.md` (tabela Y, depois de `| Y6 |`, `CONTEXT.md:94`); `tests/check-templates.sh` (cabeçalho, logo
antes de `# Usage: tests/check-templates.sh`, `:39` em fe9441d); `docs/superpowers/specs/2026-09-23-a-gaveta-do-kit.md`
(§ F3 `:137-150`, linha F3 do índice `:18`, item 4 da "Ordem sugerida" `:286-287`); `tests/health-baseline.txt`.

**Como (TDD):** o Check vem primeiro e é vermelho em fe9441d+passo 0 → `0 0 0 20 0 0` (medido). Remoção dos
itens: `python3 ~/.claude/plans/2026-10-03-helpers/todo_rm.py TODO.md '`.sdd/logs/` não tem poda' '35% do `docs/pipeline.md`' '`Test Coverage` = A do revisor' 'Nenhum instrumento mede prosa de CONTRATO'`
(o helper só mexe no arquivo que recebe; medido: apaga 51-57, 152-158, 221-227, 91-98). Textos exatos:

Linha **Y7** do `CONTEXT.md` (uma linha física, depois da Y6):
```
| Y7 | **Poda de `.sdd/logs/`** — cada sessão deixa três arquivos ali, e o `.stream.jsonl` é a sessão inteira; nada apaga nada. Medido em 2026-10-04: kit 400 MB (26 missões), `sales_quote` 385 MB (22), `lighthouse_project` 42 MB (3) — ~15 MB por missão —, o maior stream com 11,8 MB (o `gzip` o reduz 3,25×), e 148 GB livres no disco (84% usado). É gitignored, local, e é o que o humano abre para entender uma sessão: reter N ou comprimir seria apagar a evidência antes de alguém pedir. | O primeiro de três eventos: um repo passar de **2 GB** em `.sdd/logs/`, o disco ficar com **menos de 10% livre**, ou alguém **apagar logs à mão** para abrir espaço. | achado de `sdd-executor` em `20260816-runner-sem-dividas`; saiu do `TODO.md` pela régua D15 em `20261004-lote-4-a-catraca-zera` (2026-10-04) |
```

Três registros decididos (no fim do arquivo, uma linha física cada):
```
- **35% do docs/pipeline.md seria um subsistema só, e cresceria a cada missão do ledger** — decidido, sem refator: as seções do ledger e do juiz são 525 de 1562 linhas (33,6%), estáveis em 33–34% desde 2026-09-29 depois do pico de 48% em 2026-08-31, e nenhum boot_prompt lê o pipeline.md, então nenhuma fase paga o índice inteiro; reabre se a fatia passar de 40% ou se um boot passar a ler o arquivo — `docs/pipeline.md:1038` (2026-10-04)
- **Test Coverage = A do revisor implicaria que os casos negativos existem** — decidido como limite: a nota de revisão é rótulo que o próprio modelo escreve, e a anatomia §4 o declara; a parte barata e real, o executor sabotar a linha nova de um R<n>, é o I3 de 20261004-lote-4-a-catraca-zera; reabre quando um segundo P1 escapar de um Test Coverage = A numa missão headless — `.claude/rules/anatomia-do-agente.md:94` (2026-10-04)
- **Nenhum instrumento mediria prosa de CONTRATO fora de templates/** — decidido: a fase DOCS é a dona dessa prosa (a checklist de drift do 45-docs.md percorre o diff inteiro da missão), o config/schema.md já é medido contra o load_config pelo sdd health, a tabela de agentes do README bate 8 = 8, e os drifts registrados foram pegos antes do merge; o limite está no cabeçalho do sensor; reabre quando um drift de contrato escapar para a main — `tests/check-templates.sh:39` (2026-10-04)
```

Limite no cabeçalho do `tests/check-templates.sh` (entra logo antes de `# Usage:`, e fica na linha 39 — é o
ponteiro do registro acima):
```
# ⚠️ DECLARED LIMIT (D15), moved here from TODO.md in 20261004-lote-4-a-catraca-zera: nothing in
# the suite reads CONTRACT prose outside templates/. refute() reads templates/ only, and
# check-lang.sh reads README.md and the docs/ surface for LANGUAGE and nothing else. The owner of
# that prose is the DOCS phase: its drift checklist (45-docs.md) walks the whole mission diff, and
# gate_DOCS refuses a row still pending. Measured not to fail open on 2026-10-04: the agent table
# of README.md names the 8 hats agents/ carries; config/schema.md is held against load_config()
# by `sdd health` (check 5, key-without-doc and doc-without-key); and the drifts on record were
# caught before the merge — 20260901-o-revisor-so-acha changed the reviewer contract in seven
# places, a QA journey caught the sixth and only the DOCS phase the seventh. Reopens when a
# contract drift reaches main.
#
```

Gaveta § F3 — substitui o bloco de `**A T3** é a terceira missão…` até `…âncora de sabotagem no `gate_REVIEW`.`
(exclusive o parágrafo `**A janela do juiz**`) por:
```
**A T3** era a terceira missão de kit nascida de `ACHADOS-20260917-sales-quote.md` (a T1 foi o #46
e a T2 o #47), e **se desfez em 2026-10-04**: dos três itens que ela juntava, nenhum sobrou para ela.
- **#6 — fase feita à mão não pode ser registrada.** Sai pelos I17–I19 da missão
  `20261004-lote-4-a-catraca-zera`: `sdd note-manual <missão> <fase>`, com o 6º `event` do ledger
  (`manual`, que não pontua). O ACHADOS o chamava de "o mais caro dos nove".
- **#7 — o teto de orçamento não conhece "missão reaberta".** Decidido em 2026-10-03, na seção
  decidida do `TODO.md`: a porta humana para gastar mais é `--budget-override`, com a nota
  `intervention:` que o runner escreve.
- **Observação "T5" — `Test Coverage = A` não implica caso negativo.** Decidida como limite em
  2026-10-04, na seção decidida do `TODO.md`: a nota de revisão é rótulo (anatomia §4). A parte
  barata e real — o executor sabota a linha nova de um `R<n>` — é o I3 da mesma missão.

As três perguntas de desenho que as fontes listavam para o humano — o 6º `event`, a definição de
"reaberta" e a âncora de sabotagem no `gate_REVIEW` — estão respondidas: a primeira no grill do lote
4, as outras duas por decisão escrita. A âncora no `gate_REVIEW` **não** foi construída: o risco de
gate insatisfazível (princípio 1) que a recusava continua de pé.
```
E, pela regra "frente que anda atualiza o índice no mesmo commit" (decisão minha, além do § F3 pedido): na linha
F3 do índice, `→ `sdd kaizen`; a T3 vem depois do veredito |` vira `→ `sdd kaizen`; a T3 se desfez em 2026-10-04 (§ F3) |`;
e o item 4 da "Ordem sugerida" (`4. A T3 com as três decisões humanas, … vem antes).`, duas linhas) vira:
```
4. ~~A T3 com as três decisões humanas~~ — desfeita em 2026-10-04: os três itens saíram pela missão
   `20261004-lote-4-a-catraca-zera` ou por decisão escrita (§ F3).
```
(A frase histórica de `:271-272`, "O que as fontes já decidem", fica como está.)

Verde provado no protótipo (`662d662`): Check → `1 1 1 23 1 2`; `bash tests/check-todo.sh` →
`  ok    19 finding(s), all within 8 lines, carrying anchor + date, every anchor on target`;
`tests/check-templates.sh` rc 0; `tests/check-lang.sh` → `  ok    0 of 57 surface path(s) still in the allowlist, 0 new`.

**Sabotagens/mutantes:** nenhum mutante (só texto). O sensor que segura as quatro saídas é o `check-todo.sh`
(forma do registro decidido, contagem 19) mais a catraca do `sdd health` (`todo-findings 19`).

**Check:** `o=$(bash tests/check-todo.sh 2>&1); a=$(grep -c '^  ok    19 finding(s)' <<< "$o"); b=$(awk '/^todo-findings 19$/{c++} END{print c+0}' tests/health-baseline.txt); c=$(awk '/^. Y7 /{c++} END{print c+0}' CONTEXT.md); d=$(awk '/<!-- sdd:decided -->/{d=1;next} d && /^- [*][*]/{c++} END{print c+0}' TODO.md); e=$(awk '/DECLARED LIMIT [(]D15[)], moved here from TODO.md in 20261004-lote-4-a-catraca-zera/{c++} END{print c+0}' tests/check-templates.sh); f=$(awk '/se desfez em 2026-10-04/{c++} END{print c+0}' docs/superpowers/specs/2026-09-23-a-gaveta-do-kit.md); echo "$a $b $c $d $e $f"` → `1 1 1 23 1 2`
(antes, medido em fe9441d + passo 0: `0 0 0 20 0 0`). O `f` = 2 porque a frase está no corpo do § F3 e na linha F3 do índice.

**Sensor durável:** `tests/check-todo.sh` (a forma das 3 linhas decididas e a contagem) + catraca
`todo-findings 19` do `sdd health`.

**Saída do item:** #88 → YAGNI **Y7** (linha acima); #130, #155, #109 → decididos (linhas acima). Catraca 23 → 19.

**Âncoras do TODO.md que o incremento desloca:** nenhuma (nenhum item aberto ancora em `tests/check-templates.sh`,
`CONTEXT.md` ou na gaveta). `bash tests/check-todo.sh --anchors TODO.md` → `  ok    anchors: 19 measured, 0 off target`.

**Reversível por:** `git revert` do commit.

### I2 — #180 + #218: o checkpoint ganha a regra do commit de registro; o token de espera fica adiado (catraca 19 → 17)

**O quê:** decisão escrita em três lugares + dois sensores de texto:
1. **Ato fora do git deixa um commit de registro**: e-mail enviado, página da KB, config no IdP, issue
   adotada → o executor grava `docs/handoffs/<missão>/record-<ID>.md` (o que foi feito, URL/ID que prova, data),
   commita, e o hash vai na célula Commit (o `gate_EXEC` já exige 7–64 hex, `bin/sdd:1284`).
2. **Passo pós-merge ou de janela externa não é incremento**: vai para `## Pendências para o humano` do
   `00-missao.md` (`templates/missao.md:74`) ou para a missão seguinte. Na tabela vira `pending` eterno ou
   `blocked` que para a linha (`bin/sdd:1339`).
3. Linha legada que o executor encontrar: `blocked` + nota + parar (Jidoka), nunca `pending` nem palavra na célula.
- #180 → registro decidido; #218 → YAGNI **Y8**. Casos legados **não** são migrados (handoff fechado não se
  reescreve) — está dito no registro.
- ⚠️ Nome do arquivo de evidência em inglês (`record-<ID>.md`): nome de arquivo é contrato (CLAUDE.md § Idioma).
  Não casa `[1-9][0-9]-*.md` (`mission_latest_handoff`, `bin/sdd:2817`) nem `40-review-r*.md`.
- ⚠️ A superfície inglesa **não pode** citar o heading `## Pendências para o humano`: o `check-lang.sh` acusa
  `para` (stopword, `tests/check-lang.sh:62`) e letra acentuada **mesmo dentro de crase** (medido: 2 FAIL,
  `agents/sdd-executor.md:65` e `agents/sdd-planner.md:110`). Os agentes dizem "the open questions for the
  human in `00-missao.md` (the last section of its template)" — é como o próprio `check-templates.sh:335` descreve
  a seção.

**Onde:** `templates/checkpoint.md` (bloco novo antes de `> Atualizar o checkpoint é o **último ato**`, `:35`);
`tests/check-templates.sh` (2 `check` depois do `refute checkpoint.md 'checkpoints deste repo'`, `:367-368`);
`agents/sdd-planner.md` (§ 4, bullet novo depois de "the size of one session", `:101-103`); `agents/sdd-executor.md`
(§ 2, parágrafo novo depois de "Jidoka, not a heroic session." `:60`; § 5, bullet novo depois do bullet `Commit`
`:140-141`); `tests/check-hat.sh` (`executor_agent_probes`, `:245`); `.claude/agents/` via
`env -u CLAUDECODE ./bin/sdd install --force`; `TODO.md`, `CONTEXT.md`, `tests/health-baseline.txt`.

**Como (TDD):** Red primeiro, medido em fe9441d (e de novo depois do I1): Check → `0 0 0 0 0 0 0 same`. As duas
asserções novas do `check-templates.sh` e o probe do `check-hat.sh` entram antes do texto e ficam vermelhos
(`FAIL checkpoint.md: missing an act outside git commits a record …`). Textos exatos:

`templates/checkpoint.md` (dentro do blockquote, antes de "Atualizar o checkpoint é o **último ato**"; a linha
do roteamento é UMA linha física, porque a regex a lê inteira):
```
> ⚠️ **Ato fora do git deixa um commit de registro.** O `gate_EXEC` lê 7 a 64 dígitos hex na
> célula Commit e nada mais. Quando o produto do incremento não é código — e-mail enviado, página da
> KB publicada, config no IdP, issue adotada —, o executor grava a evidência num arquivo da pasta da
> missão (`record-<ID>.md`: o que foi feito, a URL ou o ID que o prova, a data) e commita esse
> arquivo; o hash dele vai na célula. Palavra na célula é rótulo, e o gate a recusa.
>
> ⚠️ **Passo depois do merge ou numa janela externa não é incremento.** O merge do humano, um
> yokoten nos repos-alvo, um smoke que exige a mesa livre: na tabela, cada um vira um `pending` que
> nunca fecha ou um `blocked` que para a linha inteira.
> O passo vai para `## Pendências para o humano` do `00-missao.md`, ou para a missão seguinte.
>
```

`tests/check-templates.sh`, depois do `refute checkpoint.md 'checkpoints deste repo' …`:
```bash
# The Commit cell is 7–64 hex digits and nothing else (gate_EXEC), so the act that happens OUTSIDE
# git still needs a commit to point at — the record of it (issue 180). Measured before the rule:
# the I5 of lighthouse_project's 20260922-email-mvp-diretores wrote `KB (sem commit de código)` in
# the cell, and its `sdd status` points at EXEC for good. The step after the merge or inside an
# external window has no row at all (issue 218): 20260918-a-excecao-do-chapeu-e-o-genero-diferido
# kept its yokoten `pending` forever. Both assertions pin the rule in full, with the routing — a
# template that kept the bold title and lost where the step goes would teach half of it.
check checkpoint.md '\*\*Ato fora do git deixa um commit de registro\.\*\*' \
  "an act outside git commits a record"
check checkpoint.md 'O passo vai para `## Pendências para o humano` do `00-missao\.md`' \
  "a step after the merge or in an external window leaves the table"
```
(o `check-templates.sh` é exceção declarada do `check-lang.sh`; o português do comentário é dado.)

`agents/sdd-planner.md`, § 4, novo bullet depois de "…the slice is too big.":
```
- **a commit as its product.** `gate_EXEC` reads 7–64 hex digits in the Commit cell and nothing
  else. An increment whose act happens outside git — an e-mail sent, a KB page published, an IdP
  setting — still commits a RECORD: an evidence file in the mission folder (`record-<ID>.md`: what
  was done, the URL or ID that proves it, the date), and its hash goes in the cell. A step that can
  only happen **after the merge** or **inside an external window** — the human's merge, a yokoten in
  the target repos, a live smoke that needs the desk idle — is not an increment: it goes to the
  open questions for the human in `00-missao.md` (the last section of its template), or to the next
  mission. In the table it would be a `pending` that never closes, or a `blocked` that stops the
  whole line.
```

`agents/sdd-executor.md`, § 2, depois de "`blocked` with the reason in the notes: Jidoka, not a heroic session.":
```

**A row you cannot close by yourself** — a step that only happens after the merge, or inside an
external window (a live smoke that needs the desk idle, a yokoten in the target repos) — is not an
increment, and the plan should not have one. If it does, mark it `blocked`, write in the notes that
it belongs in the open questions for the human of `00-missao.md` (the last section of its
template) or in the next mission, and stop: left `pending`, it keeps EXEC open forever, and a word
in its Commit cell is a label the gate refuses.
```
e § 5, depois do bullet `Commit` → the bare short hash…:
```
- an act **outside git** — an e-mail sent, a KB page published, an IdP setting — still ends in a
  commit: write the evidence to `docs/handoffs/<mission>/record-<ID>.md` (what was done, the URL or
  ID that proves it, the date), commit it, and that hash goes in the cell
```

`tests/check-hat.sh`, no fim de `executor_agent_probes` (antes do `}`):
```bash
  # Issue 180: gate_EXEC reads 7–64 hex digits in the Commit cell, so an act outside git (an e-mail,
  # a KB page) needs a RECORD commit to point at; issue 218: a step after the merge or inside an
  # external window is not a row the executor can close. Both halves, because the planner is told
  # the same and the executor is who meets the legacy row the planner wrote before the rule.
  if grep -qF 'record-<ID>.md' "$ex" && grep -qF 'open questions for the human' "$ex"; then
    pass "hat: the executor commits a record for an act outside git, and hands a step it cannot close to the human"
  else fail "hat: sdd-executor no longer says how an act outside git reaches the Commit cell, or where a step it cannot close goes"; fi
```

`TODO.md`: `todo_rm.py TODO.md 'O checkpoint não tem grafia para incremento' 'Incremento que espera uma janela externa'`
e o registro decidido (fim do arquivo; o ponteiro `:35` é a linha do "Ato fora do git" no template):
```
- **O checkpoint não teria grafia para incremento cujo produto não é commit** — decidido: a grafia é o commit de registro — o ato fora do git (e-mail, página da KB, config no IdP) deixa na pasta da missão um record-<ID>.md com o que foi feito, a URL ou o ID e a data, e o hash dele vai na célula Commit que o gate_EXEC já lê; passo pós-merge ou de janela externa sai da tabela para as Pendências para o humano do 00-missao.md ou para a missão seguinte (o token de espera é o Y8 do CONTEXT.md); os casos medidos (o I5 da LH-3, KB sem commit; o I6 de 20260918-a-excecao-do-chapeu-e-o-genero-diferido, pending eterno; os I1–I3 de 20260825-cif-forma-pagamento no sales_quote, blocked eterno) não são migrados, porque handoff fechado não se reescreve — `templates/checkpoint.md:35` (2026-10-04)
```
`CONTEXT.md`, linha **Y8** depois da Y7:
```
| Y8 | **Um status de espera por evento externo** — um token `waiting`, com motivo, para o incremento que depende de uma janela fora do pipeline (a mesa sem uso, uma aprovação de terceiro) e que, ao contrário do `blocked`, não pararia as fases seguintes. Desde `20261004-lote-4-a-catraca-zera` o passo pós-merge ou de janela externa sai da tabela (`templates/checkpoint.md`), e o único caso medido — o I11 da S8 do `ui24_agent`, um smoke ao vivo cuja pré-condição falhou — foi uma janela só. Um quinto token mexe no enum do `gate_EXEC`, no `checkpoint_tally`, no Jidoka do `cmd_run` e na marca do `sdd status` de uma vez. | Uma **janela externa recorrente atravessar duas ou mais missões**: o mesmo passo esperando o mesmo evento em missões seguidas, que é quando "ir para a missão seguinte" vira adiamento sem fim. | achado da sessão interativa em `20261003-fase8-s8-dinamica-eq-restantes` (`ui24_agent`); saiu do `TODO.md` pela régua D15 em `20261004-lote-4-a-catraca-zera` (2026-10-04) |
```
(Os quatro leitores do enum citados existem: `checkpoint_tally` `bin/sdd:611`, enum `:1306`, marca do status
`:6719`, Jidoka do `cmd_run` `:8109`.) Catraca `todo-findings 19` → `17`. Espelho: `env -u CLAUDECODE ./bin/sdd install --force`
(medido: `agent sdd-executor.md updated (--force)`, `agent sdd-planner.md updated (--force)`).

Verde no protótipo (`2e5d2c5`): Check → `1 1 1 1 1 1 1 same`; `check-templates.sh`, `check-hat.sh`, `check-lang.sh` rc 0.

**Sabotagens/mutantes:** sem mutante (texto). Passada de sabotagem (`$S/design-A/sab-i2.sh`), cada uma provada
aplicada (md5 antes ≠ depois) e com o sensor vermelho nomeando a regra:
- S1 apagar a linha "Ato fora do git…" do template → `check-templates.sh` rc 92, `missing an act outside git commits a record`;
- S2 "deixa um commit de registro" → "deixa um registro" → rc 92, mesma asserção;
- S3 apagar a linha do roteamento → rc 92, `missing a step after the merge or in an external window leaves the table`;
- S4 apagar a linha com `record-<ID>.md` do executor → `check-hat.sh` rc 1, `sdd-executor no longer says how an act outside git…`;
- S5 apagar a linha "open questions for the human of" do executor → rc 1, mesmo FAIL.
(O `check-templates.sh` sai 92 e não 1 nesses casos porque o controle de ponta a ponta do selftest roda sobre os
templates reais; o FAIL nomeado é o do `check()`.)

**Check:** `o=$(bash tests/check-templates.sh 2>&1); a=$(grep -c '^  ok    checkpoint.md: an act outside git commits a record' <<< "$o"); b=$(grep -c '^  ok    checkpoint.md: a step after the merge or in an external window leaves the table' <<< "$o"); h=$(bash tests/check-hat.sh 2>&1); c=$(grep -c '^  ok    hat: the executor commits a record for an act outside git' <<< "$h"); t=$(bash tests/check-todo.sh 2>&1); d=$(grep -c '^  ok    17 finding(s)' <<< "$t"); e=$(awk '/^todo-findings 17$/{c++} END{print c+0}' tests/health-baseline.txt); f=$(awk '/^. Y8 /{c++} END{print c+0}' CONTEXT.md); g=$(awk '/commits a RECORD/{c++} END{print c+0}' agents/sdd-planner.md); cmp -s agents/sdd-executor.md .claude/agents/sdd-executor.md && cmp -s agents/sdd-planner.md .claude/agents/sdd-planner.md && m=same; echo "$a $b $c $d $e $f $g ${m:-diff}"` → `1 1 1 1 1 1 1 same`
(antes, medido em fe9441d e depois do I1: `0 0 0 0 0 0 0 same`).

**Sensor durável:** `check-templates.sh` (2 asserções sobre `templates/checkpoint.md`) e `check-hat.sh`
(probe de texto do executor). O catálogo não alcança nenhum dos dois (markdown); o limite está declarado no
comentário acima de `executor_agent_probes` (estendido no I3).

**Saída do item:** #180 → decidido (linha acima); #218 → YAGNI **Y8** (linha acima). Catraca 19 → 17.

**Âncoras do TODO.md que o incremento desloca:** `agents/sdd-executor.md:76` (#194, `Watch it fail`): o
parágrafo novo da § 2 empurra 7 linhas, `Watch it fail` vai para **:83**. O lint segue verde (distância 7 ≤ 10;
medido `  ok    anchors: 17 measured, 0 off target`), mas a âncora deve ser re-ancorada para `:83` no commit
(remap). As âncoras de #180 (`bin/sdd:1198`) e #218 (`bin/sdd:1339`) saem com os itens.

**Reversível por:** `git revert` do commit (+ `./bin/sdd install --force` para o espelho voltar).

### I3 — #194: o executor sabota a linha nova de um `R<n>`

**O quê:** a § 3 "Execute in TDD" do `agents/sdd-executor.md` ganha o passo 3 **Sabotage — only in an `R<n>`**
(Refactor vira 4, Commit vira 5): depois do Green de um incremento `R<n>`, degradar cada linha que o conserto
acrescentou, uma de cada vez (cópia do arquivo, devolvida depois de cada rodada), ver um probe ficar vermelho em
cada uma; linha cuja degradação deixa tudo verde = conserto sem sensor → escrever o probe ou dizer nas notas por
que não existe; anotar uma linha por sabotagem no `checkpoint-notas.md`; num `R<n>` de prosa, reler o parágrafo
inteiro da frase corrigida e todo lugar que repete a afirmação. Probe de texto no `check-hat.sh`.

**Onde:** `agents/sdd-executor.md` § 3 (passos `2. **Green**`…`4. **Commit**`, `:78-82` em fe9441d; depois do
I2, `:85-89`); `tests/check-hat.sh` `executor_agent_probes` (`:245`) e o comentário acima dela (termina em `:244`);
`.claude/agents/sdd-executor.md` via `./bin/sdd install --force`.

**Como (TDD):** Red medido em fe9441d: `grep -ci sabot agents/sdd-executor.md` → `0`; Check → `0 0 same`. O probe
entra primeiro e fica vermelho (`FAIL hat: sdd-executor lost the sabotage step…`). Texto exato (substitui os
passos 3 e 4 atuais):
```
3. **Sabotage — only in an `R<n>`.** The Red of a review increment proves the finding, not the
   fix: the fix can remove the symptom and open a fail-open beside it while the probe stays green.
   So after the Green, degrade **each line the fix added**, one at a time — keep a copy of the
   file and put it back after each run — and watch a probe go red for every one. A line whose
   degradation leaves every probe green is a fix with no sensor: write the probe, or say in the
   notes why none can exist. Append one line per sabotage to `checkpoint-notas.md`
   (`R<n> sabotage: <what was degraded> → <which probe went red>`). An `R<n>` of **prose** has no
   line to degrade: re-read the whole paragraph around the corrected sentence, and every place that
   repeats the claim, before the commit — five of the eight repeats measured were prose.
4. **Refactor** — only when there is real duplication, and with the suite green throughout.
5. **Commit** — message `<type>(<scope>): <what>` with the **why** in the body. One increment =
   one commit (or a few, cohesive ones).
```
Probe, no fim de `executor_agent_probes` (lê o passo como BLOCO, do heading numerado até o próximo; o escopo
`R<n>` é exigido NA LINHA DO HEADING):
```bash
  # Issue 194: the Red of an R<n> proves the finding, not the fix, and at least eight findings of
  # four missions were opened by the fix of the round before (3 code in this kit, 5 prose in
  # sales_quote). The step is read as a BLOCK, from its numbered heading to the next one, and each
  # of its three parts has to be inside it: the R<n> scope ON THE HEADING (the block names R<n>
  # again in its prose sentence, so a block-wide grep answered for a step that lost its scope —
  # sabotage measured), the sabotage note in checkpoint-notas.md (a name the file also uses in its
  # section 5, so a whole-file grep would answer for a step that lost it), and the re-read of the
  # whole paragraph for an R<n> of prose.
  local sab
  sab="$(awk '/^[0-9]+\. \*\*Sabotage/ { on = 1; print; next } on && /^[0-9]+\. \*\*/ { on = 0 } on' "$ex")"
  if grep -qF 'only in an `R<n>`' <<< "${sab%%$'\n'*}" && grep -qF 'checkpoint-notas.md' <<< "$sab" \
     && grep -qF 'whole paragraph' <<< "$sab"; then
    pass "hat: the executor sabotages the new line of an R<n>, notes it, and re-reads the paragraph of a prose fix"
  else fail "hat: sdd-executor lost the sabotage step of an R<n> (its scope, its note in checkpoint-notas.md, or the prose re-read)"; fi
```
E a última frase do comentário acima de `executor_agent_probes` ("…and that limit is declared here rather than
left silent.") ganha a continuação:
```
# declared here rather than left silent. It covers every probe of this function, the two text
# probes of the executor added in 20261004-lote-4-a-catraca-zera included: each was proved by a
# sabotage pass over agents/sdd-executor.md, recorded in that mission's plan, not by the catalogue.
```
Verde no protótipo (`a803111`): Check → `1 1 same`; `shellcheck -S warning tests/check-hat.sh` limpo; `check-lang` ok.

**Sabotagens/mutantes:** sem mutante (o catálogo não alcança `agents/*.md`). Passada (`$S/design-A/sab-i3.sh`),
cada uma aplicada e vermelha (`check-hat.sh` rc 1, `FAIL hat: sdd-executor lost the sabotage step…`):
- S1 apagar o passo inteiro (`/^3\. \*\*Sabotage/,/five of the eight repeats/d`);
- S2 tirar o escopo: heading vira `3. **Sabotage.**` e a nota vira `` `sabotage: `` — **na 1ª versão do probe esta
  SOBREVIVEU** (o bloco cita `R<n>` de novo na frase da prosa); o probe passou a exigir `only in an `R<n>`` na
  linha do heading, e agora morre;
- S3 apagar a linha com `checkpoint-notas.md` do passo;
- S4 "re-read the whole paragraph around the corrected sentence" → "re-read the corrected sentence";
- S5 desnumerar o passo (`3. **Sabotage` → `   **Sabotage`).

**Check:** `o=$(bash tests/check-hat.sh 2>&1); a=$(grep -c '^  ok    hat: the executor sabotages the new line of an R<n>' <<< "$o"); b=$(awk '/^[0-9][.] [*][*]Sabotage/{c++} END{print c+0}' agents/sdd-executor.md); cmp -s agents/sdd-executor.md .claude/agents/sdd-executor.md && m=same; echo "$a $b ${m:-diff}"` → `1 1 same`
(antes, medido em fe9441d: `0 0 same`).

**Sensor durável:** probe de texto `hat: the executor sabotages the new line of an R<n>…` em `executor_agent_probes`.

**Saída do item:** `RESOLVED by <hash>` no I24 (conserto). Catraca não muda aqui.

**Âncoras do TODO.md que o incremento desloca:** nenhuma nova. A âncora do próprio #194
(`agents/sdd-executor.md:76`, já deslocada para `:83` pelo I2) continua em `Watch it fail` (`:83`), porque o
passo novo entra **depois** dela. `--anchors` → `  ok    anchors: 17 measured, 0 off target`.

**Reversível por:** `git revert` (+ `./bin/sdd install --force`).

### I4 — #178 + #135: duas promessas de chapéu (catraca 17 → 16)

**O quê:**
- **#178:** `agents/sdd-ticket.md` para de prometer o `acli`. O parágrafo de `:19-20` ("The runner confirms the
  issue **through `acli`**…") vira o que o gate faz; e o parágrafo "The gate requires `issue:` **and** `sprint:` —
  an issue created in the backlog does not pass." (`:58-60`) — **uma segunda promessa da mesma família, achada pelo
  probe** (o gate só checa que `sprint:` não é vazio, `bin/sdd:1131`) — também é reescrito. O `gate_TICKET` ganha o
  LIMITE declarado num comentário. Probe no `check-hat.sh` que REFUTA a promessa e afirma a verdade.
- **#135:** `agents/sdd-docs.md`, depois do parágrafo do `⛔` ("A path the harness refuses is a boundary…"), ganha
  o parágrafo "A comment in the code belongs to the code…". Probe no mesmo bloco. Item → decidido.
- `bin/sdd` muda **só em comentário** → sem mutante; `bash -n`, `shellcheck -S warning bin/sdd`, `--anchors`.

**Onde:** `agents/sdd-ticket.md` (`:19-20` e `:58-60`); `agents/sdd-docs.md` (depois de `:102`, "…would be
too."); `bin/sdd` `gate_TICKET` (`:1105`), comentário antes de `local issue; issue="$(frontmatter "$t" issue)"`
(`:1129`); `tests/check-hat.sh` (função nova `hat_promise_probes` antes de `# --- sdd census:` `:255`, e a
chamada na lista do fim, entre `executor_agent_probes` e `boot_probes`, `:420-421`); espelho; `TODO.md`,
`tests/health-baseline.txt`.

**Como (TDD):** Red medido em fe9441d (e depois do I3): Check → `0 0 0 0 0 same`. Probe primeiro. Na 1ª versão a
refutação `(runner|gate)[^.]*acli` pegou também a linha de evidência `gate: "acli confirms issue <KEY>-123 in
sprint <id>"` do exemplo do `10-ticket.md` (`:53`) — que é o read-back da própria skill, legítimo; a regex final
exige o runner ou o gate como **sujeito** (`the runner|the gate|gate_TICKET`). Textos exatos:

`agents/sdd-ticket.md`, no lugar de `:19-20`:
```
The runner reads your file, and only your file: `gate_TICKET` takes `issue:` and `sprint:` from
the frontmatter of `10-ticket.md` and never asks Jira. So those two lines carry what the `ticket`
skill read back — the key it created and the sprint it verified the card in —, never a value you
expect. An issue the skill could not confirm in the active sprint is `status: blocked`, not a
`sprint:` filled in by hand.
```
e no lugar das duas primeiras linhas de `:58-60` (a terceira, `` `00-missao.md` to declare the **same** branch.``, fica):
```
The gate requires `issue:` **and** `sprint:`, and it cannot see Jira: a `sprint:` is your record
that the skill verified the card left the backlog, so write it only from that read-back. A card in
the backlog is invisible work for the team. When you fill `branch:` in, the gate also requires
```

`agents/sdd-docs.md`, parágrafo novo depois de "…and `` `a.md`, section X `` would be too.":
```

**A comment in the code belongs to the code, not to you.** A drifted comment in a file your
`writes:` does not cover (`bin/`, `src/`, `tests/`) is the same boundary: never edit it. Mark the
row `⛔` with the proposed text, naming the file and the function in Evidence, or — when the fix is
not worth a new run of the mutation catalogue — record it in the `TODO_FILE`. The REVIEW phase
sends such a finding to an `R<n>` batch for EXEC; when one already carries it, the row is `n/a`
with that `R<n>`.
```
(É coerente com o gate: `⛔` só é recusado em documento que o `writes:` da DOCS cobre fora de `.claude/` —
`agents/sdd-docs.md:99-100` —, e `bin/`, `src/`, `tests/` não estão nele.)

`bin/sdd`, dentro do `gate_TICKET`, imediatamente antes de `local issue; issue="$(frontmatter "$t" issue)"`:
```bash
  # ⚠️ DECLARED LIMIT (D15), since 20261004-lote-4-a-catraca-zera: this gate never asks Jira. It
  # reads `issue:` and `sprint:` from 10-ticket.md, the ticket skill's read-back written down by
  # sdd-ticket, and proves the record exists and is whole. The hat used to promise a confirmation
  # "through acli" that nothing made (issue 178). Making it would cost a Jira round trip on every
  # evaluation of this gate — one per `sdd phase`, two per `sdd status` — and would NOT have caught
  # the case that raised the finding: the TICKET of LH-4 recorded LH-5, a duplicate that WAS in the
  # active sprint, so acli answers yes for it too.
```

`tests/check-hat.sh`, função nova antes de `# --- sdd census: the instrument reads the logs, never memory ---`:
```bash
# One hat promised a measurement nobody makes, and another was silent where its boundary needed a
# sentence; the next session reads a hat's promise as a fact and its silence as permission. Asserted
# HERE because neither half lives in bin/sdd, so the catalogue cannot reach it — the same limit as
# executor_agent_probes, declared the same way; the sabotage pass that proves each probe is in the
# plan of 20261004-lote-4-a-catraca-zera.
#   - issue 178: sdd-ticket said the runner confirms the issue "through acli"; gate_TICKET reads
#     10-ticket.md and never asks Jira (its own comment says why). Refuted on the sentence that
#     makes the runner or the gate the subject of acli — the hat legitimately names `acli
#     --from-json`, the skill's tool, and the `gate:` evidence key of 10-ticket.md carries the
#     skill's own read-back — and asserted on what the gate does, so dropping both passes nothing.
#   - issue 135: a drifted code comment has an owner — R<n>, a proposed-text row, or the TODO file —
#     and it is never the DOCS phase's own edit, which hat_guard_check would stop as hat-crossed.
hat_promise_probes() {
  local tk="$ROOT/agents/sdd-ticket.md" dc="$ROOT/agents/sdd-docs.md"
  if grep -qiE '(the runner|the gate|gate_TICKET)[^.]*acli' "$tk" || ! grep -qF 'never asks Jira' "$tk"; then
    fail "hat: sdd-ticket promises a Jira check the gate does not make, or no longer says that gate_TICKET reads only 10-ticket.md"
  else pass "hat: the ticket hat promises no Jira check the gate does not make"; fi
  if grep -qF 'A comment in the code belongs to the code' "$dc" && grep -qE 'R<n>.*batch' "$dc"; then
    pass "hat: the docs hat leaves a code comment to the code's own phase (R<n>, a proposed-text row, or the TODO file)"
  else fail "hat: sdd-docs no longer says who owns a drifted code comment"; fi
}
```
e a chamada `hat_promise_probes` na lista do fim (`census_probes` / `executor_agent_probes` / **`hat_promise_probes`** / `boot_probes` / `release_probes`).

`TODO.md`: `todo_rm.py TODO.md 'Drift de comentário em código não tem dono'` e o registro decidido (o ponteiro
`:104` é a linha do parágrafo novo em `agents/sdd-docs.md`):
```
- **Drift de comentário em código não teria dono: nem a DOCS nem a EXEC** — decidido: comentário de código é do código — a REVIEW o manda para um lote R<n> da EXEC, a DOCS marca ⛔ com o texto proposto (o bin/sdd fica fora do writes: dela, e o gate só recusa ⛔ em documento que ela pode escrever), ou ele vai para o TODO_FILE quando o carimbo não compensa; o caminho estreito "a DOCS edita só hunk de comentário" falharia aberto, porque o bin/sdd tem 6 heredocs e # dentro de string, awk e jq; 0 hat-crossed por código em 15 sessões DOCS desde 2026-09-12 — `agents/sdd-docs.md:104` (2026-10-04)
```
Catraca 17 → 16. #178 **fica aberto** até o I24 (`RESOLVED by`). Espelho: `./bin/sdd install --force` (medido:
`agent sdd-docs.md updated`, `agent sdd-ticket.md updated`).

Verde no protótipo (`1796175`): Check → `1 1 1 1 1 same`; `bash -n bin/sdd`, `shellcheck -S warning bin/sdd tests/check-hat.sh`
limpos; `tests/check-mutation.sh --anchors` → `  ok    anchors: all 593 mutants still apply and leave valid code`
(4,7 s); `check-lang` ok.

**Sabotagens/mutantes:** sem mutante (o diff do `bin/sdd` é comentário; o probe lê `agents/`). Passada
(`$S/design-A/sab-i4.sh`), todas aplicadas e vermelhas em `check-hat.sh` rc 1:
- S1 reinserir "The runner confirms the issue **through `acli`**, not through your file." → `sdd-ticket promises a Jira check…`;
- S2 "and never asks Jira" → "and checks it" → idem;
- S3 acrescentar "The gate checks the sprint through acli." → idem;
- S4 apagar o parágrafo "A comment in the code belongs…" → `sdd-docs no longer says who owns a drifted code comment`;
- S5 "sends such a finding to an `R<n>` batch for EXEC" → "sends such a finding to EXEC" → idem.

**Check:** `o=$(bash tests/check-hat.sh 2>&1); a=$(grep -c '^  ok    hat: the ticket hat promises no Jira check the gate does not make' <<< "$o"); b=$(grep -c '^  ok    hat: the docs hat leaves a code comment to the code' <<< "$o"); c=$(awk '/DECLARED LIMIT [(]D15[)].*this gate never asks Jira/{c++} END{print c+0}' bin/sdd); t=$(bash tests/check-todo.sh 2>&1); d=$(grep -c '^  ok    16 finding(s)' <<< "$t"); e=$(awk '/^todo-findings 16$/{c++} END{print c+0}' tests/health-baseline.txt); cmp -s agents/sdd-ticket.md .claude/agents/sdd-ticket.md && cmp -s agents/sdd-docs.md .claude/agents/sdd-docs.md && m=same; echo "$a $b $c $d $e ${m:-diff}"` → `1 1 1 1 1 same`
(antes, medido em fe9441d e depois do I3: `0 0 0 0 0 same`).

**Sensor durável:** `hat_promise_probes` (dois probes de texto, um que refuta a promessa e afirma a verdade, outro
que exige o dono do comentário) + o LIMITE no comentário do `gate_TICKET`.

**Saída do item:** #178 → `RESOLVED by <hash>` no I24. #135 → decidido (linha acima). Catraca 17 → 16.
Yokoten (Pendências para o humano): `sales_quote` e `lighthouse_project` têm cópia do `sdd-ticket.md` em
`.claude/agents/` com a promessa antiga — `sdd install --force` lá, pelo humano.

**Âncoras do TODO.md que o incremento desloca:** o comentário entra no `bin/sdd` em `:1129` (+7 linhas). Ficam
+7 as âncoras abertas depois disso: `bin/sdd:2092` (#67) → `:2099`; `bin/sdd:4315` (#129) → `:4322`;
`bin/sdd:9623` (#98, `kaizen_series`) → `:9630`; `bin/sdd:10156` (MEC, `kaizen_reminder`) → `:10163`. Antes do
ponto (intactas): `bin/sdd:1102` (#178), `bin/sdd:894` (#179), `bin/sdd:147`. Medido: `--anchors` →
`  ok    anchors: 16 measured, 0 off target` (todas a ≤ 10 linhas), mas re-ancorar pelo remap no commit.
`agents/sdd-docs.md:9` (#135) sai com o item. `agents/sdd-ticket.md:18` é a 2ª âncora do #178 (não medida): a
promessa estava em `:19`, que passa a ser "The runner reads your file, and only your file:" — continua o lugar certo.

**Reversível por:** `git revert` (+ `./bin/sdd install --force`).

### I5 — A âncora mede só o símbolo que ela designa (#191)

**O quê:** a regra da âncora (ADR 0011, decisões 1 e 2) passa a medir **um** símbolo, o
designado por posição: a crase aberta por `(` logo depois da âncora — `` `path:N` (`símbolo`) ``,
o slot que `templates/todo.md:16` já mostra. Ele fica **obrigatório** em todo item aberto, é a
**única** crase medida (as outras do item, título incluído, deixam de contar) e é a que a dica
`nearest` nomeia. Mínimo de 4 caracteres e alcance de 10 linhas ficam (o mínimo agora vale para o
designado). Mensagens novas, uma por causa:
- `anchor `X` designates no symbol — write `X` (`<symbol>`), the span the line holds`
- `anchor `X` designates `abc`, shorter than 4 characters — it occurs near any line`
- `anchor `X` — the designated symbol `S` does not occur in <path>` (substitui `no backticked symbol of the item occurs in`)
- `anchor `X` is off target — nearest `S` is at line L` (mesma forma de hoje; `S` agora é sempre o designado)

O `TODO.md` do kit migra **no mesmo commit** (16 itens no início do I5, **9 sem o slot**; detalhe na
tabela abaixo). `templates/todo.md` e `templates/todo.pt-BR.md` dizem que o slot é obrigatório.
Os `agents/` **não mudam**: `sdd-executor.md:104,111-113`, `sdd-qa.md:203,209-210` e
`sdd-docs.md:60-61` já descrevem `<symbol>` como a crase entre parênteses a até 10 linhas — o texto
deles passa a ser verdade, sem `sdd install --force` e sem mexer na chave do carimbo.
Emenda: ADR 0015 §2 emenda as decisões **1 e 2** da ADR 0011 (a 1 dizia "pelo menos uma crase da
cabeça", a 2 "um símbolo citado").

**Onde:** `tests/check-todo.sh` — awk `spans()` (`:315`) e sua chamada em `flush()` (`:346`);
`anchor_scan()` (`:2107`, o laço de símbolos a partir de `syms=()` em `:2153`); comentário do
`ANCHOR_REACH` (`:2078-2081`); cabeçalho (`:33-40` e `:112-119`); selftest — fixtures genéricas
(`:713`, `:792`, `:974`, `:1270`, `:1646`, `:1706` `long_item`, `:1751`), bloco da âncora
(`:1785` … `rule_end 19` em `:1870`), bloco do `--baseline` (`:1872` … `rule_end 7` em `:1927`),
`RULES_FLOOR=10` (`:645`), piso de probes `-lt 163` (`:1942`). `TODO.md` (seção aberta).
`templates/todo.md` e `templates/todo.pt-BR.md` (parágrafo "The anchor is measured" / "A âncora é
medida", `:20-23`).

**Como (TDD):**

1. *Probes primeiro.* No selftest, um bloco novo logo depois do `rule_end` da âncora (que passa a
   ser `rule_end 17 'an anchor names a file of the checked repo and its designated symbol sits within 10 lines'`),
   no mesmo repo-fixture `$ar` (`frobnicate_widget` na linha 20, `# filler line N` no resto):

   ```bash
   rule_begin
   anchor_item noslot.md '`src/code.sh:20` — calls `frobnicate_widget`'
   anchors_says 1 'anchor `src/code.sh:20` designates no symbol' \
     "an anchor without the (symbol) slot is refused, even with the symbol right on its line" "$ar/noslot.md"
   # The witness first: the decoy must sit ON the anchored line, or the probe below proves nothing.
   PROBES=$((PROBES + 1))
   [ "$(sed -n 31p "$ar/src/code.sh")" = '# filler line 31' ] || { FAILS=$((FAILS + 1)); fail_rc 92
     printf '  SELFTEST FAIL  the decoy `filler line` is not on line 31 of the fixture\n' >&2; }
   anchor_item decoy.md '`src/code.sh:31` (`frobnicate_widget`) — cites `filler line`'
   anchors_says 1 'anchor `src/code.sh:31` is off target — nearest `frobnicate_widget` is at line 20' \
     "a span that occurs near the line no longer answers for the designated one, and the hint names it" "$ar/decoy.md"
   anchor_item later.md '`src/code.sh:20` — calls it (`frobnicate_widget`)'
   anchors_says 1 'anchor `src/code.sh:20` designates no symbol' \
     "a parenthesised span is the slot only right after the anchor" "$ar/later.md"
   printf '## Open\n<!-- sdd:open -->\n\n- [ ] **Slot on the next line** — `src/code.sh:20`\n  (`frobnicate_widget`) — why. — by `x` (2026-08-16)\n' > "$ar/wrapped.md"
   anchors_says 0 '1 measured, 0 off target' "the slot may wrap to the continuation line" "$ar/wrapped.md"
   anchor_item short.md '`src/code.sh:20` (`fro`) — calls it'
   anchors_says 1 'anchor `src/code.sh:20` designates `fro`, shorter than 4 characters' \
     "a 3-character designated symbol does not count" "$ar/short.md"
   rule_end 6 'an anchor designates one symbol, and only that symbol is measured'
   ```

   Cobre o pedido: (a) designado longe → reprova e a dica nomeia o designado (`decoy`, e o `off.md`
   antigo com slot); (b) item sem slot reprova (`noslot`, `later`); (c) span ubíquo perto não salva
   mais (`decoy`: `filler line` está NA linha 31 e não responde por ele). No bloco do `--baseline`,
   antes do `rule_end` (que vai a `rule_end 8`), o caso dos alvos — item antigo sem slot é herdado,
   item novo sem slot é novo, e o antigo **desce** de linha (é o que pega uma chave que carregue o
   número da linha):

   ```bash
   local legacy='- [ ] **Legacy finding** — `src/code.sh:20` — calls `frobnicate_widget` — by `x` (2026-10-03)'
   bl_todo "$legacy"; bl_commit legacy
   bl_todo '- [ ] **New finding** — `src/code.sh:20` — calls `frobnicate_widget` — by `x` (2026-10-04)' "$legacy"
   baseline_says 1 'TODO.md: 1 new shape violation(s) against legacy (1 inherited)' \
     "an old item without the slot is inherited, a new one is not" --baseline legacy
   ```

   `RULES_FLOOR=10` → `11`; piso de probes `163` → `168` (probes reais 172 → 177; a folga de 9 fica).
   As probes antigas do bloco da âncora ganham o slot para continuar medindo o que mediam:
   `ok`, `off`, `nofile`, `whole`, `glob`, `kitonly`, `climb`, `symlink`, `titlepath`, `nomark`
   viram `` `<âncora>` (`<símbolo>`) — calls it ``; `nosym` vira `` `src/code.sh:20` (`unheard_of_symbol`) ``
   e espera `anchor `src/code.sh:20` — the designated symbol `unheard_of_symbol` does not occur in src/code.sh`;
   o `short` muda para o bloco novo; o `titlesym` ("a symbol cited in the title still counts") **sai**
   (afirmava o contrário da regra nova; o `noslot` cobre a recusa). Bloco da âncora: 19 → 17 probes.
   As fixtures genéricas que passam pelo `--check` e ancoram arquivo real da caixa ganham o slot:
   `` `bin/sdd:42` — `bsym` matters `` → `` `bin/sdd:42` (`bsym`) — matters `` (2×, `:713` e `:792`),
   `` `f.sh:1` — `fsym`. — `` → `` `f.sh:1` (`fsym`) — fine. — `` (3×), `` `bin/sdd:%s` — `bsym` matters. ``
   → `` `bin/sdd:%s` (`bsym`) — matters. `` (o `counted.md`), e o `long_item`
   `` **Accented `xsym`** — `x.sh:1` — `` → `` **Accent** — `x.sh:1` (`xsym`) — `` (mesma largura:
   o fixture é calibrado em 120/121 caracteres). As do `--baseline` (`undated`, `good`, `Second
   undated` 2×, `Off target`) ganham `(`frobnicate_widget`) — calls it`.

2. *Red, medido* (probes novas sobre a regra de `fe9441d`, i.e. a sabotagem S1 abaixo):
   `bash tests/check-todo.sh --selftest` → rc 91, e as linhas
   ```
   SELFTEST FAIL  a symbol the file does not carry is refused — expected rc 1 and "anchor `src/code.sh:20` — the designated symbol …
   SELFTEST FAIL  an anchor without the (symbol) slot is refused, even with the symbol right on its line — …
   SELFTEST FAIL  a span that occurs near the line no longer answers for the designated one, and the hint names it — …
   SELFTEST FAIL  a parenthesised span is the slot only right after the anchor — …
   SELFTEST FAIL  a 3-character designated symbol does not count — …
   SELFTEST FAIL  an old item without the slot is inherited, a new one is not — …
   SELFTEST FAIL  8 rule line(s) reported, expected 11 — either a rule_end call site
   ```
   E a fixture do verificador C (`$S/verif-C/fx191`, `f.sh:12` com `SPECIFIC_THING` na linha 70 e
   `gate_common` a cada 5 linhas): em `fe9441d` `--anchors` → `  ok    anchors: 1 measured, 0 off target`.

3. *Conserto.* No awk, `spans()` marca com `\035` a crase cuja única separação da anterior é
   branco e `(` (sem parâmetro: título e resto são marcados igual; o título nunca está na posição
   seguinte à âncora). ⚠️ Comentário dentro do programa awk: **sem apóstrofo** (fecha a aspa simples
   do shell).
   ```awk
   function spans(text,   out, rest, p, q, gap, sp) {
     out = ""; rest = text
     while ((p = index(rest, "`")) > 0) {
       gap = substr(rest, 1, p - 1)
       rest = substr(rest, p + 1)
       if ((q = index(rest, "`")) == 0) break
       sp = substr(rest, 1, q - 1)
       if (gap ~ /^[ \t]*\($/) sp = "\035" sp
       out = out "\t" sp
       rest = substr(rest, q + 1)
     }
     return out
   }
   ```
   (Só o `(` de abertura é lido; o `)` de fechamento não — exigi-lo era regra sem probe que a
   distinguisse, e `(`x`, `y`)` designar `x` é inofensivo.) No `anchor_scan()`, a âncora é achada
   **por índice** (`for i in ${sp_list[@]+"${!sp_list[@]}"}; do sp="${sp_list[i]#$'\035'}"` …
   `anchor="$sp"; ai="$i"`), e o laço `syms=()`/`bestsym` inteiro (`:2153-2173`) vira:
   ```bash
   sym=''
   case "${sp_list[ai + 1]-}" in $'\035'?*) sym="${sp_list[ai + 1]#$'\035'}" ;; esac
   if [ -z "$sym" ]; then
     ANCHOR_VIOLATIONS+="  line $start: anchor \`$anchor\` designates no symbol — write \`$anchor\` (\`<symbol>\`), the span the line holds"$'\n'
     continue
   fi
   if [ "${#sym}" -lt "$ANCHOR_SYMBOL_MIN" ]; then
     ANCHOR_VIOLATIONS+="  line $start: anchor \`$anchor\` designates \`$sym\`, shorter than $ANCHOR_SYMBOL_MIN characters — it occurs near any line"$'\n'
     continue
   fi
   best=''
   hits="$(grep -nF -- "$sym" "$base/$path" 2>/dev/null | cut -d: -f1)" || hits=''
   for hit in $hits; do
     if [ "$n" -le 1 ]; then best=0; break; fi
     dist=$((hit > n ? hit - n : n - hit))
     if [ -z "$best" ] || [ "$dist" -lt "$(( best > n ? best - n : n - best ))" ]; then best="$hit"; fi
   done
   if [ -z "$best" ]; then
     ANCHOR_VIOLATIONS+="  line $start: anchor \`$anchor\` — the designated symbol \`$sym\` does not occur in $path"$'\n'
   elif [ "$n" -gt 1 ] && [ $(( best > n ? best - n : n - best )) -gt "$ANCHOR_REACH" ]; then
     ANCHOR_VIOLATIONS+="  line $start: anchor \`$anchor\` is off target — nearest \`$sym\` is at line $best"$'\n'
   fi
   ```
   O `local` perde `bestsym` e o array `syms`, ganha `ai i`. Cabeçalho: a frase da regra (`:35-37`)
   passa a dizer "the span right after it, in parentheses — the DESIGNATED symbol, 4+ characters …
   It is the only span measured (ADR 0015 §2)"; o limite declarado (`:115-117`, "a symbol that
   occurs everywhere …") vira "the designated symbol is the AUTHOR's choice — designate one that
   occurs everywhere and the distance is satisfied near almost any line; the 4-character minimum
   narrows it, nothing here closes it. A target's items written before the slot are each one
   violation, which `--baseline <ref>` reads as inherited". Comentário do `ANCHOR_REACH`: "the
   designated symbol"/"the shortest span that may be designated".
   Templates (EN, e o equivalente pt-BR "o `<símbolo>` entre parênteses logo depois dele é
   **obrigatório**: uma crase de 4+ caracteres … É a única crase medida, e a que o relatório de
   âncora fora do alvo nomeia"): "the `<symbol>` in parentheses right after it is **mandatory**: a
   code span of 4+ characters that occurs in that file within 10 lines of the line — anywhere in it
   for `:1` or no line. It is the only span measured, and the one an off-target report names."
   (`check-templates.sh` segue verde: a prosa é livre, o esqueleto não muda, os dois passam no
   `--check --allow-empty`.)

4. *Migração do `TODO.md` do kit, no mesmo commit.* Procedimento (vale qualquer que seja o estado
   deixado por I1–I4): `bash tests/check-todo.sh` lista cada item; `designates no symbol` → escreva
   o slot com um símbolo **da linha ancorada** (ou a ≤ 10 linhas); `is off target — nearest `S``
   → confira se `S` é mesmo o alvo antes de seguir a dica. Medido sobre `786f0fe` (16 itens, 9 sem
   slot, 11 violações):

   | Item | Antes | Depois | Por quê |
   |---|---|---|---|
   | #191 (este) | `tests/check-todo.sh:2081` (`ANCHOR_REACH`) | `:2122` (`ANCHOR_REACH`) | o próprio I5 empurra a linha (+41; confira pelo `nearest`) |
   | #67 carimbo | `bin/sdd:2092` | `bin/sdd:2095` (`MUTATION_STAMP_PATHS`) | 2092 é comentário; o array está em 2095 |
   | #92 Check verde | `templates/missao.md:45` | `templates/missao.md:45` (`Check executável`) | na linha |
   | #95 alvos | `tests/check-todo.sh` | `tests/check-todo.sh` (`--allow-empty`) | âncora de arquivo inteiro |
   | #108 piso | `tests/check-lang.sh:180` | `tests/check-lang.sh:203` (`n_surface`) | 180 é o comentário do piso, 23 linhas acima dele; passava por `docs/adr/*.md` em 183 |
   | MEC reminder | `bin/sdd:10156` (`kaizen_reminder`) | `bin/sdd:10156` (`kit_root`) | o designado antigo está a 25 linhas (def. em 10131): o slot designava a função, não a linha |
   | #129 ledger | `bin/sdd:4315` | `bin/sdd:4423` (`autonomy_session_row`) | **podre**: 4315 é o preâmbulo de `autonomy_gate_pass_row`; passava por `TEST_CMD` (73 ocorrências) em 4318; a âncora nasceu (`bd71f48`) no `turns:` da linha de sessão |
   | #134 ADRs | `docs/adr/0001-…-verdict.md:1` | idem (`Status`) | arquivo inteiro |
   | #141 surface | `tests/check-lang.sh:52` | idem (`surface`) | na linha |
   | #142 publisher | `agents/sdd-publisher.md:41` | idem (`./bin/sdd health`) | a 1 linha |
   | #153 manual | `agents/sdd-publisher.md:1` | idem (`sdd-publisher`) | arquivo inteiro |

   Os 7 que já tinham slot e seguem no alvo: `agents/sdd-executor.md:76` (`Watch it fail`),
   `bin/sdd:9623` (`kaizen_series`), `bin/sdd:1102` (`gate_TICKET`, d=3), `bin/sdd:894`
   (`path_in_commits`, d=2), `agents/sdd-publisher.md:42` (`./bin/sdd health`) e os dois acima.
   Dois itens estouram a forma com o slot e são re-quebrados dentro de 120 caracteres/8 linhas sem
   mudar uma palavra: #67 (passava de 8 linhas) e #129 (linha de 123 caracteres). Depois:
   `bash tests/check-todo.sh` → `ok    16 finding(s) … every anchor on target`; `--anchors TODO.md`
   → `ok    anchors: 16 measured, 0 off target`; `--count` → `16` (catraca não se move).

5. *Verde, provado no protótipo:* `bash tests/check-todo.sh` → 11 linhas `ok    rule:`,
   `ok    selftest: 177 probe(s)`, `ok    16 finding(s), …`, rc 0 (2,2 s). fx191 →
   `FAIL  line 6: anchor `f.sh:12` is off target — nearest `SPECIFIC_THING` is at line 70` /
   `FAIL  anchors: 1 measured, 1 off target`, rc 1. `check-templates.sh`, `check-lang.sh`
   (`0 of 56`), `check-pipefail.sh` verdes; `shellcheck -S warning tests/check-todo.sh` limpo.

*Alcance: recomendo NÃO juntar reach 2 — fica 10.* Números (protótipo, `$S/design-B/meas/`):
- chance de uma âncora de linha **podre** (linha qualquer do arquivo) passar, média dos 13 itens de
  linha do kit: regra de `fe9441d` (qualquer crase, alcance 10) **26,1%** (máx. 78,7%,
  `check-lang.sh:52`); designado, alcance 10 **12,7%**; designado, alcance 2 **4,3%**
  (`coverage_old.py`, `coverage.py`);
- custo do alcance 2: sobre os 28 merges de `583b3c3..fe9441d`, âncoras cuja linha andou mais que
  o alcance — 315 (>10) contra 337 (>2), **+22 re-ancoragens (+7%)** (`shift_churn.py`);
- hoje, alcance 2 reprova 1 item a mais no kit (`bin/sdd:1102` `gate_TICKET`, d=3) e 4 slots a mais
  nos alvos (sq 2 → 5, lh 0 → 1; `verif-C/designated.py`);
- o que o alcance 2 pega a mais é deriva de ≤ 10 linhas de um símbolo que o autor escolheu — o
  leitor cai a ≤ 10 linhas do que o item nomeia, não em outro código. E ele muda o sentido do slot
  ("a função do achado" → "uma crase da própria linha"): o caso `kaizen_reminder` mostra que o
  autor designa a função. Os dois casos podres vivos (#109, #180) e os dois revelados pela migração
  (#108, #129) caem já com o designado no alcance 10. Reabre se um item com slot passar verde
  apontando para outro código a ≤ 10 linhas do seu designado. (Para a ADR 0015 §2, alternativa
  medida e recusada.)

*Efeito nos alvos (risco a declarar no plano):* `--baseline <ref>` do lote 3 já trata o slot
ausente como violação **herdada** — a chave é mensagem + texto da linha, e a cópia do ref é medida
com o sensor novo. Medido com o sensor do protótipo, `--check ~/repos/<alvo>/TODO.md --allow-empty`
(sem baseline) → `--baseline HEAD`:

| Alvo | hoje (fe9441d) | depois do I5 | sem slot | `--baseline HEAD` |
|---|---|---|---|---|
| sales_quote | rc 1, 110 | rc 1, 209 | 175 | `0 new … (209 inherited)` |
| lighthouse_project | rc 1, 110 | rc 1, 127 | 29 | `0 new … (127 inherited)` |
| ui24-agent | rc 1, 10 | rc 1, 16 | 9 | `0 new … (16 inherited)` |
| warehouse_explorer_api | rc 1, 5 | rc 1, 14 | 13 | `0 new … (14 inherited)` |
| LouvorFlow | rc 1, 5 | rc 1, 6 | 5 | `0 new … (6 inherited)` |
| digital_service_report_api | rc 1, 3 | rc 1, 8 | 5 | `0 new … (8 inherited)` |
| digital_service_report_frontend | rc 1, 3 | rc 1, 17 | 14 | `0 new … (17 inherited)` |
| validade_bateria_estoque | rc 1, 1 | rc 1, 4 | 4 | `0 new … (4 inherited)` |
| erp_api (0 itens) | rc 0 | rc 0 | 0 | `0 new … (0 inherited)` |

Nenhum alvo muda de veredito: os 8 com itens **já** reprovam o `--check` puro hoje. A skill
`todo-to-github-issues` chama `--check <arquivo> --allow-empty` **sem** `--baseline`
(`scripts/todo_issues.py:199`, `scripts/todo_format.py:386` e `:505`), então ela já recusa (rc 4)
espelhar esses 8 hoje; o `--audit` passa a listar +254 violações "designates no symbol" (sem ação
própria em `ACTIONS`, cai na mensagem crua), e a tabela do `SKILL.md:124` descreve a regra antiga
("nenhum símbolo `entre crases` do item perto da linha") — retrofit da skill no marketplace, fora
do kit (mesma decisão do registro "As skills qa-report e qa-execution não conhecem o campo Closable
by"). O caminho seguro dos alvos é o `--baseline origin/$DEFAULT_BRANCH` que o incremento do #95
sugere no `TEST_CMD`. Depois do merge, o re-sync das issues do kit mostra `update` nos 11 itens
migrados (o corpo mudou) — esperado. A partir do I5, todo item aberto **novo** desta missão leva o
slot, ou o `TEST_CMD` reprova.

**Sabotagens/mutantes:** o catálogo não alcança `tests/` (`apply_mutant` só sabota `bin/`):
sabotagens do selftest, cada uma aplicada numa cópia (prova de aplicação: o script morre se o
trecho não existe) e rodada com `--selftest` — **8 de 8 vermelhas** (`$S/design-B/meas/sabotage191.py`):

| # | Degradação | Morre em |
|---|---|---|
| S1 | volta à regra de `fe9441d` (qualquer crase ≥ 4 do item, título incluído) | `a symbol the file does not carry…`, `noslot`, `decoy`, `later`, `short`, `legacy` (rc 91) |
| S2 | item sem slot é pulado em vez de reprovado | `an anchor without the (symbol) slot is refused…` |
| S3 | designado = próxima crase, com ou sem `(` | idem |
| S4 | veredito pelo designado, dica pela crase mais próxima do item | `a span that occurs near the line no longer answers… and the hint names it` |
| S5 | adjacência frouxa no awk (`gap ~ /\($/`) | `a parenthesised span is the slot only right after the anchor` |
| S6 | mínimo de 4 caracteres não vale para o designado | `a 3-character designated symbol does not count` |
| S7 | slot só na mesma linha física (`gap ~ /^ ?\($/`) | `the slot may wrap to the continuation line` |
| S8 | a mensagem do slot ausente carrega o número da linha (chave do `--baseline` muda) | `an old item without the slot is inherited, a new one is not` |

S8 sobreviveu na primeira versão da probe (o item herdado ficava na mesma linha); a probe passou a
pôr o item novo **acima** do antigo. Mutantes novos: 0.

**Check:** `o=$(bash tests/check-todo.sh 2>&1); grep -c -e '^  ok    rule: an anchor designates one symbol, and only that symbol is measured' -e '^  ok    [0-9]* finding(s), all within 8 lines, carrying anchor + date, every anchor on target' <<< "$o"` → `2`
(antes, medido em `fe9441d` e em `786f0fe`: `1` — só a linha dos achados; com a regra e **sem** a
migração: `1` — a regra sem os 11 itens migrados reprova o `TODO.md`. Aceito por
`tests/check-checkpoint.sh --check`.)

**Sensor durável:** o bloco `rule: an anchor designates one symbol, and only that symbol is
measured` (6 probes) + a probe `legacy` do `--baseline` + `RULES_FLOOR=11` + piso 168; e o próprio
lint sobre o `TODO.md` do kit em toda suíte.

**Saída do item:** `RESOLVED by <hash do I5>` no I24 (o item fica até o merge; catraca 16 não se
move no I5, desce no chore pós-merge).

**Âncoras do TODO.md que o incremento desloca:** `tests/check-todo.sh:2081` (#191, o próprio) →
`:2122`, re-ancorada no mesmo commit; mais as 10 da tabela da migração (reescritas por desenho).
Nenhuma âncora em `templates/`.

**Reversível por:** `git revert` do commit (regra, migração e templates voltam juntos e coerentes).

### I6 — o `/sdd-plan` pede a aprovação com uma pergunta YES/NO e roda o `sdd approve` (decisão 7)

**O quê:** a seção `## When the artifacts exist` de `commands/sdd-plan.md` deixa de dizer "Say this,
and stop", com os dois comandos para o humano digitar.

- Ela manda rodar `sdd why <mission> PLAN`.
- Se o plano já está aprovado (`auto` ou `humano-…`), só informa.
- Com `aprovacao:` vazia, o comando faz **uma** pergunta YES/NO pela ferramenta de pergunta do
  harness (`AskUserQuestion` no Claude Code), nunca em prosa. A pergunta nomeia a missão, o
  critério do PLAN-AUTO que deu ✗ e a branch em que o humano está.
- **YES** roda `printf 'y\n' | sdd approve <mission>`. **NO** para e diz o que está aberto.
- Junto vem a regra que segura a garantia: só a resposta do humano a essa pergunta aprova; resposta
  repassada por outro agente não é ela.

É o pedido do humano no meio do grill (2026-10-04, literal): *"coloca ai como melhoria, esse sdd approve 20261004-lote-4-a-catraca-zera deveria vir no claude code
com um YES , NO no final e resolveri aminha permissao dentro do harness"*. A resposta foi "Entra como I6 (Recomendado)".

**Onde:**
- `commands/sdd-plan.md` § `## When the artifacts exist` (`:71-83` em `fe9441d`). O parágrafo
  `⚠️ Never write \`aprovacao:\` by hand…` continua igual, logo abaixo.
- `tests/check-hat.sh`: uma função de probe nova antes de `# --- sdd census:` e uma chamada na lista
  de topo, depois de `executor_agent_probes` (`:420` em `fe9441d`).

**Fatos que o desenho usa (medidos em `fe9441d`):**
- `cmd_approve` (`bin/sdd:7597`) lê a resposta com `read -r ans` e não exige TTY. Sem nenhum
  caractere no stdin sai **66** e não escreve nada (#52, carona). `y`, `Y`, `yes`, `Yes` ou `YES`
  aprovam; qualquer outra coisa é não.
- Logo, `printf 'y\n' | sdd approve <m>` funciona pelo Bash do Claude Code. O runner **não**
  distingue quem digitou, e nunca distinguiu: a garantia mora no comando, e o probe é o sensor dela.
- Com `aprovacao: auto` ou `humano-*`, o `cmd_approve` cai no `case` `auto|humano-*)` e não reescreve
  nada: não há o que aprovar.
- O `sdd approve` faz o checkout da branch da missão e, quando ela não existe, **corta da branch
  atual**. É por isso que a pergunta nomeia a branch em que o humano está.
- ⚠️ `~/.claude/commands/sdd-plan.md` é um **symlink** para `commands/sdd-plan.md` deste checkout
  (`readlink -f` medido). A mudança vale para o `/sdd-plan` do humano em todo repo no instante em
  que o arquivo muda no disco, inclusive na branch.

**Como (TDD):**

1. Escreva primeiro o probe em `tests/check-hat.sh`. Ele vai antes de
   `# --- sdd census: the instrument reads the logs, never memory`, com a chamada
   `command_approval_probes` na lista de topo, logo depois de `executor_agent_probes`:

   ```bash
   # --- /sdd-plan: the approval is the human's answer to a YES/NO question -------------------------
   # The human asked for it in the grill of 20261004-lote-4-a-catraca-zera: approving a plan used to
   # mean reading "sdd approve <mission>" off the screen and typing it. `sdd approve` reads its `y`
   # from stdin and cannot tell who typed it, so the guarantee lives in the command's prose, and this
   # probe is the whole sensor for it: the catalogue sabotages bin/sdd, never commands/*.md. It reads
   # the section, not the file, so a rule moved out of "When the artifacts exist" is a rule lost.
   command_approval_probes() {
     local cmd="$ROOT/commands/sdd-plan.md" sec
     sec="$(awk '/^## When the artifacts exist/{s=1; next} s && /^## /{s=0} s' "$cmd")"
     if grep -q 'AskUserQuestion' <<< "$sec" \
        && grep -qE '^ *- \*\*YES\*\* .*sdd approve <mission>' <<< "$sec" \
        && grep -qE '^ *- \*\*NO\*\*' <<< "$sec" \
        && grep -qF "Only the human's answer to that question approves" <<< "$sec"; then
       pass "command: /sdd-plan asks the human YES or NO before it runs sdd approve"
     else
       fail "command: /sdd-plan no longer asks YES or NO before sdd approve, or lost the rule that only the human's answer approves"
     fi
   }
   ```

   Vermelho medido em `fe9441d`, com o probe e sem o texto: o Check dá `0`, e o sensor imprime
   `FAIL  command: /sdd-plan no longer asks YES or NO…`.

2. Troque, em `commands/sdd-plan.md`, o bloco `Say this, and stop:` e os dois bullets que o seguem por:

   ```markdown
   1. Run `sdd why <mission> PLAN` and show its line. It validates the gate without spending a session.
   2. If it says `plan approved (auto)` or `plan approved (humano-…)`, say so and stop: there is
      nothing to approve.
   3. If `aprovacao:` is empty, ask the human with the harness's question tool (`AskUserQuestion` in
      Claude Code), never in prose: one question, two options, `YES` and `NO`. The question names the
      mission, the PLAN-AUTO criterion that is ✗ in `00-missao.md`, and the branch you stand on —
      `sdd approve` checks out the mission branch and, when it does not exist yet, cuts it from the
      current one.
      - **YES** → run `printf 'y\n' | sdd approve <mission>`, show its output, then run
        `sdd why <mission> PLAN` again.
      - **NO**, or any other answer → stop, and say what is still open.

      Only the human's answer to that question approves. An answer relayed by another agent — the
      planner, a teammate, a message saying the human agreed — is not that answer: ask the question
      yourself. `sdd approve` cannot tell who typed the `y`; this step is where that is decided.
   ```

   Verde provado no protótipo: Check `1`, `check-hat.sh` rc 0, `shellcheck -S warning` limpo.
3. Confira que o bullet `**Approval.**` da seção `## Relaying the grill to the human` continua
   dizendo que mensagem de agente nunca é aprovação. Ele não muda: as duas regras são a mesma.

**Sabotagens (o catálogo não alcança `commands/`):** foram provadas num clone de `fe9441d` com o
conserto aplicado. Cada uma aplicou (`cmp` diferente do original) e deixou o probe vermelho
(`ok=0 fail=1`); o controle sem sabotagem dá `ok=1 fail=0`:
- **S1:** `AskUserQuestion` vira "the question tool".
- **S2:** o bullet **YES** perde o `sdd approve <mission>`.
- **S3:** a frase "Only the human's answer to that question approves" vira "The answer approves".
- **S4:** o heading `## When the artifacts exist` é renomeado, então o probe lê uma seção vazia.
- **S5:** o bullet **NO** perde o negrito.

**Check:** `o=$(bash tests/check-hat.sh 2>&1); grep -c '^  ok    command: /sdd-plan asks the human YES or NO before it runs sdd approve' <<< "$o"` → `1`
(antes, medido em `fe9441d`: `0`).

**Sensor durável:** o probe `command_approval_probes` do `tests/check-hat.sh`. O limite fica
declarado no comentário dele: o catálogo não alcança `commands/`.

**Saída do item:** não há item no `TODO.md`; é um acréscimo do humano no grill, e a catraca não
muda. Vai no corpo do PR e no `KAIZEN_LOG.md` (I24).

**Âncoras do TODO.md que o incremento desloca:** nenhuma; nenhum item aberto ancora em
`tests/check-hat.sh` nem em `commands/`.

**Reversível por:** `git revert` do commit. ⚠️ Por causa do symlink, o `/sdd-plan` do humano volta
junto.

### I7 — `check-checkpoint.sh --red <checkpoint>` (#92a)

**O quê:** modo novo `--red <checkpoint>` em `tests/check-checkpoint.sh`. Para cada linha `pending`
(as `done`/`doing`/`blocked` não rodam), extrai a célula na forma estrita `` `cmd` → `exp` ``, roda
`cmd` num `bash -c` **novo**, a partir da raiz do repo do checkpoint (`git -C <dir do checkpoint>
rev-parse --show-toplevel`, a mesma resolução da regra 5), stdin fechado, stderr descartado, e compara
a stdout com o esperado, os dois normalizados (toda sequência de brancos, `\n` incluso, vira um espaço;
pontas aparadas). Recusa (rc 1, uma mensagem por causa): **já verde** (`<ID> is already green at HEAD`),
**fora da forma estrita** (sem code span; crase sobrando em qualquer metade = dois pares ou prosa depois
da seta; esperado vazio), **mudo** (stdout vazia, qualquer rc: `<ID> printed nothing (rc N)`), e linha
partida por `|` (`splits into N column(s)`). Vermelho imprime `  ok    <arq>: <ID> is red at HEAD
(prints '<got>', wants '<exp>')` — é o "antes" que o plano escreve. rc: 0 todas vermelhas · 1 alguma
recusa · 93 nenhuma `pending` (vácuo) · 94 checkpoint ilegível · 95 fora de work tree git. Fica FORA do
`run-all.sh` e do runner (o decidido `tests/check-checkpoint.sh:45` continua de pé: a suíte não roda
Check). Decisões de desenho, com o porquê:
- `bash -c` e nunca `eval`: mesmo dentro de `$(…)` um `eval` herda o `set -uo pipefail` e as funções do
  sensor, e `printf … | grep -q` responde diferente sob `pipefail` (probe próprio).
- **Mudo é recusado com qualquer rc** — é a resposta ao "rc 127 com esperado `0`": um comando que nem
  foi achado (127) e um `test -f x && echo yes` que rodou e disse não são indistinguíveis por stdout
  vazia, e o plano exige o "antes" literal — vazio não se escreve. O planner reescreve como
  `test -f x; echo $?`. Medido: 0 de 44 Checks históricos do kit rodados pelo verificador A eram mudos.
- **Limite declarado** (cabeçalho): `--red` prova "não verde", nunca "vermelho pelo motivo certo":
  `cmd; echo $?` imprimindo `127` é vermelho para ele — o 127 vai escrito no plano, onde a pessoa lê.
- **Limite declarado, medido no I0 e no I6 de `20260918-…` em `79dd4df`:** o esperado é comparado com a
  stdout INTEIRA (`sdd adr check …; echo rc=$?` → `rc=0` imprime também a linha ok, e o `--red` lê
  vermelho o que a pessoa lia verde); e Check que lê FORA do repo (`~/repos/sales_quote/…`) mede o
  mundo de hoje, não o do HEAD (o I6 dá verde em 2026-10 e era vermelho no dia do plano).
- Segurança: o modo executa célula escrita por modelo → ferramenta do planner com o humano, nunca
  gate; dito no cabeçalho e no chapéu. `gate_PLAN` (`bin/sdd:1047`) não roda nada e não passa a rodar.

**Onde:** `tests/check-checkpoint.sh` — funções `red_norm`/`red_cell`/`red_one` logo depois de
`check_one()` (:445); probes no `selftest()` antes do `rm -rf "$box"` (:844); `PROBE_FLOOR=40` (:473) →
54; ramo `--red)` no `case` final, depois de `--calibrate)` (:870); cabeçalho: parágrafo novo depois de
"What it deliberately does NOT measure" (:54-57, inserido DEPOIS da :45, que é âncora de decidido e
fica igual — medido), linha de uso no bloco `Usage` (:64-73), `93`/`95` na tabela de rc (:119-124).

**Como (TDD):**
1. Probes primeiro (14, um por regra, cada recusa lendo a frase da SUA causa; rc 1 é compartilhado):
   fixture = repo git em `$box/red` com `rootmark` (= `here`) na raiz; uma linha por probe:

   | célula (status) | rc | texto exigido |
   |---|---|---|
   | `` `echo 1` → `1` `` (pending) | 1 | `I1 is already green at HEAD` |
   | `` `echo 0` → `1` `` | 0 | `I1 is red at HEAD (prints '0', wants '1')` |
   | `` `bash tests/run-all.sh` → verde `` | 1 | `outside the strict form` |
   | `echo 1 → 1` (sem crase) | 1 | `outside the strict form` |
   | `` `echo 1` → `0`; `echo 2` → `0` `` | 1 | `outside the strict form` |
   | `` `echo 1` → `` `` (esperado vazio) | 1 | `outside the strict form` |
   | `` `echo 1` → `1` `` `'done'` + `` `echo 0` → `1` `` pending | 0 | `1 pending Check(s), every one red at HEAD` |
   | `` `false` → `0` `` | 1 | `I1 printed nothing (rc 1)` |
   | `` `shopt -qo pipefail; echo $?` → `0` `` | 0 | `I1 is red at HEAD (prints '1', wants '0')` |
   | `` `cat rootmark` → `there` `` | 0 | `prints 'here'` |
   | `` `echo 1; echo 2` → `1 2` `` | 1 | `I1 is already green at HEAD` |
   | `` `echo 1; echo noise >&2` → `1` `` | 1 | `I1 is already green at HEAD` |
   | só `` `echo 1` → `1` `` `'done'` | 93 | `has no pending row` |
   | checkpoint em dir sem git, `GIT_CEILING_DIRECTORIES="$box" probe …` | 95 | `not inside a git work tree` |

   Depois do grupo: `[ "$FAILS" -eq "$red_f0" ] && pass "rule: a Check already green at HEAD is refused
   by --red ($((PROBES - red_p0)) probe(s))"` (red_p0/red_f0 = `$PROBES`/`$FAILS` antes do grupo).
   ⚠️ `done` como argumento solto dá **SC1010** no shellcheck — escreva `'done'` (medido).
   **Vermelho medido** (probes sobre o sensor de `fe9441d`): `--selftest` rc 90, 14 linhas
   `SENSOR-BROKEN`, a primeira `a Check already green at HEAD is refused — wanted rc 1, got 96`, e
   `  FAIL  unknown option: --red (see the usage header)`.
2. Código (protótipo, verde):

```bash
red_norm() {
  local s="${1//$'\n'/ }" w
  s="${s//$'\t'/ }"
  read -ra w <<< "$s"
  printf '%s' "${w[*]}"
}

# rc 1 for any other shape, one guard per way out, each with its probe; an empty COMMAND needs no
# guard of its own — it prints nothing, and the silent rule in red_one refuses it.
red_cell() {
  local c="$1" bt='`' sep='` → `'
  RED_CMD=''; RED_EXP=''
  case "$c" in "$bt"*"$sep"*"$bt") ;; *) return 1 ;; esac
  RED_CMD="${c#"$bt"}"; RED_CMD="${RED_CMD%%"$sep"*}"
  RED_EXP="${c#*"$sep"}"; RED_EXP="${RED_EXP%"$bt"}"
  case "$RED_CMD$RED_EXP" in *"$bt"*) return 1 ;; esac
  [ -n "$RED_EXP" ]
}

red_one() { # red_one <checkpoint> — 0 every pending Check is red at HEAD; 1 one is not; 93/94/95
  local path="${1-}" label top rows nf id st chk out rc got want n=0 bad=0
  if [ -z "$path" ] || [ ! -r "$path" ]; then fail "checkpoint not readable: ${path:-<none>}"; return 94; fi
  label="$(basename -- "$path")"
  top="$(git -C "$(dirname -- "$path")" rev-parse --show-toplevel 2>/dev/null)" || top=''
  if [ -z "$top" ]; then
    fail "$label is not inside a git work tree — --red runs each Check from the root of the checkpoint's repository, and there is none"
    return 95
  fi
  rows="$(rows_of "$path")"
  while IFS=$'\t' read -r nf id st chk; do
    [ -n "$nf" ] || continue
    if [ "$nf" -ne 7 ]; then
      fail "$label: row $id splits into $((nf - 2)) column(s) — --red cannot tell its Status from its Check; run --check first"
      bad=$((bad + 1)); continue
    fi
    [ "$st" = pending ] || continue
    n=$((n + 1))
    if ! red_cell "$chk"; then
      fail "$label: $id has a Check outside the strict form \`command\` → \`expected\` — --red cannot run it, so nothing says it is red"
      bad=$((bad + 1)); continue
    fi
    out="$(CDPATH='' cd -- "$top" && bash -c "$RED_CMD" 2>/dev/null < /dev/null)"; rc=$?
    got="$(red_norm "$out")"; want="$(red_norm "$RED_EXP")"
    if [ -z "$got" ]; then
      fail "$label: $id printed nothing (rc $rc) — a Check has to print a value before the work exists, or its red cannot be written down as the before"
      bad=$((bad + 1))
    elif [ "$got" = "$want" ]; then
      fail "$label: $id is already green at HEAD — its Check prints '$got' before the increment exists, so it cannot tell done from not done"
      bad=$((bad + 1))
    else
      pass "$label: $id is red at HEAD (prints '$got', wants '$want')"
    fi
  done <<< "$rows"
  if [ "$n" -eq 0 ]; then fail "$label has no pending row — --red measured nothing"; return 93; fi
  [ "$bad" -eq 0 ] || return 1
  pass "$label: $n pending Check(s), every one red at HEAD"
  return 0
}
```
   e no `case`: `--red)      red_one "${2-}"; exit $? ;;`. Verde: `--selftest` rc 0, `ok    rule: a
   Check already green at HEAD is refused by --red (14 probe(s))`; sensor inteiro ~2,2 s; `shellcheck
   -S warning` limpo; `check-lang`/`check-pipefail` verdes sobre o arquivo novo.
3. **Prova no mundo real:** o `--red` do protótipo sobre o checkpoint de
   `20260918-a-excecao-do-chapeu-e-o-genero-diferido` no commit do plano (`79dd4df`, worktree): I0–I5
   `red at HEAD`, **I7 `already green at HEAD — its Check prints '1'`** (o caso real do gemba) e I6 idem
   (lê `~/repos/sales_quote`, limite declarado), rc 1, **68 s** para 8 linhas (dois `check-gates`, um
   `check-autonomy`, um `check-preflight`).

**Sabotagens/mutantes:** sem mutante (o catálogo só sabota `bin/`). Passada de sabotagem do selftest
(`$S/design-C/sab7.sh`, cada uma aplicada a uma cópia, `cmp` provando que mudou, `--selftest` exigido
vermelho): **12 de 12 pegas, rc 90** — inverter a comparação; aceitar célula sem code span; tirar a guarda
de crase (dois pares); tirar a guarda de esperado vazio; rodar linhas `done`; `eval` no lugar de
`bash -c`; tirar a regra do mudo; `2>&1` na execução; tirar a normalização; rodar do cwd; tirar o vácuo
(93); tirar o rc 95. **1 sobrevivente declarada:** a guarda `[ "$FAILS" -eq "$red_f0" ] &&` da linha
`ok rule:` — sozinha não muda nada observável (com algum probe quebrado o rc do selftest já é 90, e o
Check lê o rc). Diga isso no comentário ao lado.

**Check:** `o=$(bash tests/check-checkpoint.sh 2>&1); r=$?; a=$(grep -c '^  ok    rule: a Check already green at HEAD is refused by --red' <<< "$o"); echo "$r $a"` → `0 1`   (antes, medido em fe9441d e em 1e56a6d: `0 0`)

**Sensor durável:** os 14 probes do `--red` no `selftest()` (rodam no `run-all.sh` a cada gate) + a linha
`ok rule:`; `PROBE_FLOOR` justo (54 no I7; o I8 leva a 57) — medido com o piso a +1: `only 54 probe(s)
ran`.

**Saída do item:** #92 (`O gate PLAN-AUTO aceita Check que já nasce verde`) → `RESOLVED by <hash I7>,
<hash I8>` no I24; sai na faxina pós-merge (catraca −1 lá, não aqui). O decidido "Nada mediria se o
esperado de um Check do checkpoint ainda reproduz" (`tests/check-checkpoint.sh:45`) continua verdadeiro
(a suíte não roda Check) e a :45 não se move — nada a mudar.

**Âncoras do TODO.md que o incremento desloca:** nenhuma (medido: `anchors: 23 measured, 0 off target`;
a :45 do decidido conferida igual por `diff`).

**Reversível por:** `git revert` do commit (um arquivo).

### I8 — o planner mede o vermelho; critério `d` e a regra de redação do #93 (#92b, #93)

**O quê:**
- `agents/sdd-planner.md` § 4, logo depois do parágrafo do `--check` (texto exato, inglês):

```markdown
  ⚠️ **Then measure the red: `tests/check-checkpoint.sh --red <checkpoint>`, by the kit's path,
  before closing PLAN-AUTO.** It runs the Check of every `pending` row from the root of the repo
  and refuses one that is **already green at HEAD** — a Check that passes before its increment
  exists cannot tell done from not done. It also refuses a cell outside the strict form
  `` `command` → `expected` `` (one pair per cell: join several values with `echo "$a $b"`) and a
  Check that prints nothing (`test -f x && echo yes` has no before; write `test -f x; echo $?`).
  The expected is the Check's **whole** stdout: send the rest to `/dev/null`, or `--red` reads red
  a Check a person would read green.
  Its line `<ID> is red at HEAD (prints '…', wants '…')` is the before the plan writes beside each
  Check. It executes what you wrote, so read the cells first; it is your tool, never a gate. And it
  costs what the Checks cost: a Check that runs the whole suite runs it here too.
  ⚠️ **Write a Check by the PRESENCE of what the increment adds.** A Check of absence
  (`grep -c X` → `0`) is born green when X never matched the way you thought, and it fails the fix
  that has to cite the defect in a comment or a changelog line. When the increment removes
  something, anchor on what only the fix adds, or on context only the defect has.
```
  e na tabela do § 6: `| d | every increment has an executable Check, red at HEAD (`--red` above) |`.
- `templates/missao.md` linha `d`: `| d | Todo incremento do `checkpoint.md` tem Check executável
  (comando → esperado), vermelho no HEAD pelo `tests/check-checkpoint.sh --red` do kit | <✅/✗> |
  <contagem; o rc do `--red`> |`. O `check-templates.sh` só cobra `^\| d \|` (laço da :336) — medido.
- `docs/pipeline.md` § **PLAN-AUTO** (:157-160): "the five criteria (… a Check per increment, the
  version)" está velho desde o `adr:` (são seis) → "closed the six criteria (grill with nothing open,
  checklists, self-containment, a Check per increment that is red at HEAD, the version, the `adr:`
  decision) **with evidence**. The red is measured by the kit's `tests/check-checkpoint.sh --red
  <checkpoint>`, which the planner runs and no gate does: it executes each pending Check from the
  repo root and refuses one already green, one outside the strict form `` `command` → `expected` ``,
  and one that prints nothing." (regra do contrato em três lugares: template + pipeline + agente).
- `commands/sdd-plan.md`: **sem mudança** — não descreve os critérios do PLAN-AUTO (só cita
  `aprovacao:` na :69); quem fecha é o planner.
- Sensores: `tests/check-templates.sh`, depois do laço `for c in a b c d e f` (:336-338):
  `check missao.md '^\| d \|.*tests/check-checkpoint\.sh --red' "PLAN-AUTO criterion d cites the --red run"`
  (com comentário de 3 linhas). `tests/check-checkpoint.sh`: `RED_DOC='check-checkpoint.sh --red'` ao
  lado do `PIPE_DOC_FLOOR=2` (:317); em `scan()`, depois da linha ok do pipe-ban (:385-389):

```bash
  if grep -qF -- "$RED_DOC" "$root/agents/sdd-planner.md" 2>/dev/null; then
    pass "the planner agent teaches the --red run before PLAN-AUTO"
  else
    fail "agents/sdd-planner.md never states the --red run (wanted the literal '$RED_DOC') — the next plan closes PLAN-AUTO over Checks nobody ran at HEAD"
    rc=1
  fi
```
  `build_tree()` (:547-549) acrescenta ao planner do fixture
  `printf 'Before PLAN-AUTO, run the kit'"'"'s tests/check-checkpoint.sh --red <checkpoint>.\n'`; e 3
  probes antes de `# ── the calibration` (:727): `strip_lit … "$RED_DOC"` → rc 1 `never states the
  --red run`; quase-acerto escrito À MÃO (nunca derivado do `RED_DOC`, lição do #71):
  `sed -i 's/check-checkpoint[.]sh --red /check-checkpoint.sh --check /'` → rc 1; e
  `sed -i 's/tests[/]check-checkpoint[.]sh --red /the --red mode on /'` → rc 1. `PROBE_FLOOR` 54 → 57.
- Espelho: `./bin/sdd install --force` (mexe só em `.claude/agents/sdd-planner.md` — medido).
- **TODO.md:** a mudança no `docs/pipeline.md` empurra +4 linhas e tira do alvo a âncora do #130
  (`docs/pipeline.md:1028` → `FAIL line 152: … off target — nearest The autonomy ledger is at line
  1042`, medido). Se o #130 ainda estiver aberto quando o I8 rodar, re-ancorar `:1028` → `:1032` no
  mesmo commit (medido: `anchors: 23 measured, 0 off target`). Se o incremento que decide o #130
  vier antes, não há o que fazer.

**Onde:** `agents/sdd-planner.md` (§ 4 :94-96; § 6 :127), `.claude/agents/sdd-planner.md` (espelho),
`templates/missao.md` (:45), `docs/pipeline.md` (:157-160), `tests/check-templates.sh` (:336-338),
`tests/check-checkpoint.sh` (`PIPE_DOC_FLOOR` :317, `scan()` :385-389, `build_tree()` :547-549, antes de
:727, `PROBE_FLOOR`), `TODO.md` (#130, :152) se aplicável.

**Como (TDD):** sensores primeiro (linha do check-templates + bloco `RED_DOC` + `build_tree` + 3 probes).
**Vermelho medido** com o chapéu e o template de `fe9441d`: `check-checkpoint.sh` rc 1 com `  FAIL
agents/sdd-planner.md never states the --red run (wanted the literal 'check-checkpoint.sh --red') — …`;
`check-templates.sh` rc 92 (o filho ponta a ponta do selftest lê o template real) com `  FAIL missao.md:
missing PLAN-AUTO criterion d cites the --red run (regex: ^\| d \|.*tests/check-checkpoint\.sh --red)`.
Depois os textos → verde; `sdd install --force`; `check-hat.sh` rc 0, `check-lang.sh` `0 of 58`.

**Sabotagens/mutantes:** sem mutante. Selftest (`$S/design-C/sab8.sh`): **4 de 4 pegas, rc 90** — o
`grep` do `RED_DOC` trocado por `true`; `RED_DOC` encurtado para `check-checkpoint.sh` (pego pelo
quase-acerto `--check`); encurtado para `--red` (pego pelo quase-acerto sem script); `rc=1` removido do
ramo de falha. A linha nova do `check-templates.sh` herda o limite das irmãs (apagar um `check` some com
a asserção; o Check da missão é quem lê) — o mesmo molde do I8 do lote 3.

**Check:** `o=$(bash tests/check-checkpoint.sh 2>&1); a=$(grep -c '^  ok    the planner agent teaches the --red run before PLAN-AUTO' <<< "$o"); t=$(bash tests/check-templates.sh 2>&1); b=$(grep -c '^  ok    missao.md: PLAN-AUTO criterion d cites the --red run' <<< "$t"); cmp -s agents/sdd-planner.md .claude/agents/sdd-planner.md && m=same; echo "$a $b ${m:-diff}"` → `1 1 same`   (antes, medido em fe9441d e em 1e56a6d: `0 0 same`)

**Sensor durável:** `ok    the planner agent teaches the --red run before PLAN-AUTO` (check-checkpoint,
com 3 probes e 2 quase-acertos) e `ok    missao.md: PLAN-AUTO criterion d cites the --red run`
(check-templates); o `sdd preflight` cobra o espelho (`agent sdd-planner stale`).

**Saída do item:** #92 → `RESOLVED by <hash I7>, <hash I8>` no I24 (ver I7). #93 já está na seção
decidida ("Check de ausência reprovaria o conserto…") e a promessa dela ("a regra de redação … vem …
na leva 4") se cumpre aqui; **opcional** no I24: trocar a evidência dessa linha por
`agents/sdd-planner.md` — ela não reabre, não move catraca.

**Âncoras do TODO.md que o incremento desloca:** #130 `docs/pipeline.md:1028` (+4, medido) — ver acima.
`templates/missao.md:45` do #92 continua a linha `d` (texto muda, linha não) — medido no alvo.

**Reversível por:** `git revert` do commit + `./bin/sdd install --force` (o espelho volta junto).

### I9 — #95: o `starter.conf` sugere o lint do `TODO.md` no `TEST_CMD` do alvo

**O quê:** sugestão opt-in, comentada, no `config/starter.conf` (o que o `sdd install` grava no alvo) e um
parágrafo no `config/schema.md` com os limites; probe no `tests/check-preflight.sh` que roda a sugestão **lida do
starter** como `TEST_CMD` real, via `sdd preflight` (que avalia o `TEST_CMD` pelo mesmo `run_check_cmd` dos
gates), em três mundos: limpo (verde) / achado novo (vermelho) / mesmo achado já na base (verde).
⚠️ **Desvio medido da sugestão do relay: a linha leva `--allow-empty`.** Sem ele, um repo recém-instalado (o
`TODO.md` semeado tem 0 achados) fica VERMELHO pelo piso: `check-todo.sh --check TODO.md --baseline origin/main`
→ `FAIL  no items parsed from TODO.md`, rc 94 (medido num repo de fixture) — `TEST_CMD` vermelho por construção
= gate de EXEC insatisfazível no primeiro dia. Com `--allow-empty` o piso vai a 0 e nada mais muda.
⚠️ Aspas **simples** no valor: o runner expande `$SDD_HOME`, `$TODO_FILE` e `$DEFAULT_BRANCH` no `eval` do
`run_check_cmd` (`bin/sdd:832`, `( cd "$REPO_ROOT" && eval "$cmd" )`), onde as três variáveis do shell (não
exportadas; `SDD_HOME` em `bin/sdd:68`) são visíveis. Fora do runner: `bash "/tests/check-todo.sh"` → rc 127
(medido).

**Onde:** `config/starter.conf` (depois do comentário de 2 linhas do `TEST_CMD`, `:19-20`); `config/schema.md`
(parágrafo novo antes de `## Running application (QA phase)`, `:53`); `tests/check-preflight.sh` (bloco novo logo
depois do `mv .sdd/config.sh.bak .sdd/config.sh` que fecha a seção do `DEFAULT_BRANCH`, `:713`: ali o fixture já
tem o `origin` bare com `main` empurrado e **sem** `TODO.md` — baseline vazio).

**Como (TDD):** Red primeiro, e pelo motivo certo: com o probe e sem a linha no starter →
`FAIL  the TODO.md lint the starter suggests runs as a TEST_CMD` / `expected: a line '#   TEST_CMD='<your suite> && …' in config/starter.conf` / `got: no such line`, rc 1 (medido).
Check em fe9441d → `0 0 0`. Textos exatos:

`config/starter.conf`, depois de `                                    # lint and build go INSIDE it — the runner reads no other sensor`:
```
# Opt-in: lint TODO.md with the kit's own sensor on every gate that runs the suite, failing only on
# what the base branch did not already have. Append it to your suite inside SINGLE quotes — the
# runner expands $SDD_HOME, $TODO_FILE and $DEFAULT_BRANCH when it runs the command; typed outside
# the runner the line fails loudly (rc 127). Limits in config/schema.md.
#   TEST_CMD='<your suite> && bash "$SDD_HOME/tests/check-todo.sh" --check "$TODO_FILE" --allow-empty --baseline "origin/$DEFAULT_BRANCH"'
```
(a última linha é o contrato que o probe lê: `^#   TEST_CMD='<your suite> && (.*)'$`.)

`config/schema.md`, antes de `## Running application (QA phase)`:
```
**Opt-in: the `TODO.md` lint inside `TEST_CMD`.** The findings file has a shape
(`templates/todo.md`) and the kit's sensor measures it, but nothing runs that sensor in a target's
suite, so an item with no anchor or no date goes unnoticed for missions. `config/starter.conf`
suggests appending
`bash "$SDD_HOME/tests/check-todo.sh" --check "$TODO_FILE" --allow-empty --baseline "origin/$DEFAULT_BRANCH"`
to the suite, inside **single** quotes, so the runner expands the three variables when it runs the
command (`$SDD_HOME` is the runner's own variable, visible to the command it evaluates). `--baseline`
fails only on what the base branch did not already have: on 2026-10-04 `sales_quote` and
`lighthouse_project` carried 110 inherited violations each and both answered `0 new`. `--allow-empty`
keeps a freshly installed repo, whose `TODO.md` has no finding yet, from failing on the empty file.
Declared limits:

- the line works where the runner runs `TEST_CMD` — `gate_EXEC`, `gate_QA`, `gate_REVIEW` and
  `sdd preflight`. Typed outside the runner, `$SDD_HOME` is empty and the line fails loudly (rc 127,
  no such file), never silently green;
- the DOCS and PR phases do not run `TEST_CMD`, so a finding written there is measured by the next
  gate that does, or by nobody if none follows;
- `origin/<base>` is read as last fetched: a stale ref can read as new a violation the base gained
  after the fetch — red, the closed direction — and a ref the repo does not have is refused (rc 88).

```

`tests/check-preflight.sh`, bloco novo (depois do `mv .sdd/config.sh.bak .sdd/config.sh` da seção do DEFAULT_BRANCH):
```bash

# --- the TODO.md lint the starter suggests, run as a TEST_CMD (issue 95) -----
# config/starter.conf suggests appending the kit's own check-todo.sh to a target's TEST_CMD, with
# --baseline so a repo carrying inherited debt is not red on day one. The suggestion is a COMMENT,
# so no gate reads it, and the only proof that it works is running it the way the runner would:
# through `sdd preflight`, which evaluates TEST_CMD with run_check_cmd like every gate does. The
# spelling is READ from the starter, never retyped here — a probe with its own copy would agree
# with a suggestion it never ran. Three worlds, one file apart: the seeded TODO.md with no finding
# (green — and only because of --allow-empty: without it the floor of an empty file is rc 94);
# one malformed finding the base does not have (red); the same finding once origin/main carries it
# (green again — inherited, which is the whole point of --baseline). `origin` is the bare repo the
# DEFAULT_BRANCH block above pushed main to, without TODO.md: an empty baseline.
echo "== the starter's TODO.md lint, run as a TEST_CMD =="
cp .sdd/config.sh .sdd/config.sh.bak
cp TODO.md "$PROBE/TODO.md.bak"
todo_lint="$(sed -n "s/^#   TEST_CMD='<your suite> && \(.*\)'\$/\1/p" "$ROOT/config/starter.conf")"
todo_lint_case() { # todo_lint_case → "green" | "red" | "neither"
  local o; o="$( "$SDD" preflight 2>&1 )"
  if grep -qF 'TEST_CMD ran green' <<< "$o"; then printf green
  elif grep -qF 'TEST_CMD FAILED' <<< "$o"; then printf red
  else printf neither; fi
}
if [ -z "$todo_lint" ]; then
  fail "the TODO.md lint the starter suggests runs as a TEST_CMD" \
    "a line '#   TEST_CMD='<your suite> && …' in config/starter.conf" "no such line"
else
  { grep -v '^TEST_CMD=' .sdd/config.sh; printf "TEST_CMD='\"%s\" && %s'\n" "$PROBE/suite-green.sh" "$todo_lint"; } \
    > .sdd/config.sh.tmp && mv .sdd/config.sh.tmp .sdd/config.sh
  w_clean="$(todo_lint_case)"
  # Into the OPEN section, under its marker: appended at the end of the seed it would land below
  # the decided marker and be measured as a malformed record instead of a finding.
  sed -i '/^<!-- sdd:open -->$/a - [ ] **a finding with no anchor and no date**' TODO.md
  w_new="$(todo_lint_case)"
  git add TODO.md && git commit -qm "the base gains the finding" && git push -q origin main
  w_inherited="$(todo_lint_case)"
  assert_eq "the TODO.md lint the starter suggests runs as a TEST_CMD: green when clean, red on a new finding, green once the base has it" \
    "green / red / green" "$w_clean / $w_new / $w_inherited"
  git reset -q --hard HEAD~1 && git push -q -f origin main
fi
cp "$PROBE/TODO.md.bak" TODO.md
mv .sdd/config.sh.bak .sdd/config.sh
```
(o `reset --hard HEAD~1` só desfaz o commit do próprio bloco; o `.sdd/` e o `TODO.md` semeado são não
rastreados no fixture, então o backup devolve o mundo como estava para as seções seguintes — `seed_lang` etc.)

Verde no protótipo (`c5f5d9c`): `check-preflight.sh` rc 0, 136 `ok` (eram 135), nova linha
`  ok    the TODO.md lint the starter suggests runs as a TEST_CMD: green when clean, red on a new finding, green once the base has it`;
tempo do sensor 27,6 s → 27,1 s (sem custo mensurável); `shellcheck` limpo; `check-lang` ok.

**Sabotagens/mutantes:** sem mutante (o diff é `config/` + `tests/`; nenhum comportamento do `bin/sdd` mudou).
Passada (`$S/design-A/sab-i9.sh`) no texto do starter, todas aplicadas e vermelhas (`check-preflight.sh` rc 1):
- S1 tirar `--allow-empty` → `got: red / red / green` (o limpo cai no piso, rc 94);
- S2 tirar `--baseline "origin/$DEFAULT_BRANCH"` → `got: green / red / red` (o herdado não é perdoado);
- S3 `$SDD_HOME` → `$KIT_HOME` → `got: red / red / red` (rc 127);
- S4 `"$TODO_FILE"` → `"$TODO_FIL"` → `got: red / red / red`.

**Check:** `o=$(bash tests/check-preflight.sh 2>&1); a=$(grep -c '^  ok    the TODO.md lint the starter suggests runs as a TEST_CMD' <<< "$o"); b=$(awk '/check-todo[.]sh. --check/{c++} END{print c+0}' config/starter.conf); c=$(awk '/Opt-in: the .TODO[.]md. lint inside .TEST_CMD./{c++} END{print c+0}' config/schema.md); echo "$a $b $c"` → `1 1 1`
(antes, medido em fe9441d: `0 0 0`).

**Sensor durável:** a asserção diferencial de três mundos no `check-preflight.sh` (que lê a grafia do starter).

**Saída do item:** `RESOLVED by <hash>` no I24. Yokoten nos alvos = Pendência para o humano: anexar a linha ao
`TEST_CMD` de `sales_quote` e `lighthouse_project` (medido 2026-10-04: `0 new (110 inherited)` nos dois, com
`--allow-empty --baseline origin/develop`). ⚠️ `ui24-agent` **ainda não**: o checkout está em
`chore/todo-esqueleto` (`d112b65`) e o `origin/main` dele não tem o marcador `<!-- sdd:open -->` → baseline vazio
→ `10 new shape violation(s) against origin/main (0 inherited)`; e ele não tem `.sdd/config.sh` nesse checkout.
O yokoten lá espera o merge do esqueleto.

**Âncoras do TODO.md que o incremento desloca:** nenhuma (nenhum item ancora em `config/` nem em `check-preflight.sh`).
⚠️ Vem depois do I5–I8 (símbolo designado); se o I5 mudar a forma da âncora, as contagens "0 new" dos alvos
continuam valendo (o `--baseline` aplica o mesmo sensor aos dois lados), mas isso **não foi provado** pós-I5.

**Reversível por:** `git revert` do commit.

### I10 — #134: as ADRs antigas ganham dono e o repo passa a `ADR_CHECK=block`

**O quê:** (mapeamento confirmado pelo humano)
- `Spec: docs/handoffs/<missão>/00-missao.md` nas ADRs **0003** (→ `20260817-eixo-do-juiz`), **0004**
  (→ `20260819-fecho-que-nao-mente`), **0006** (→ `20260826-o-laco-da-qa`), no dialeto do kit (como a 0009):
  linha em branco + `Spec: …` logo depois da linha `Date: …`.
- `adr: docs/adr/<arquivo>` no frontmatter dessas 3 missões; `adr: none` nas outras 11 (`20260814-dry-run-completo`,
  `20260815-ledger-sem-ponto-cego`, `20260816-kit-como-alvo`, `20260816-portas-do-humano`,
  `20260816-runner-sem-dividas`, `20260817-catraca-do-backlog`, `20260818-lote-facil`,
  `20260829-o-incremento-que-andou`, `20260831-a-rodada-que-andou`, `20260901-o-revisor-so-acha`,
  `20260911-o-juiz-nao-mente-sobre-a-janela`). A chave entra como última linha do frontmatter (antes do `---`
  de fechamento); nenhuma das 14 tinha `adr:`.
- `.sdd/config.sh`: `ADR_CHECK="warn"` → `ADR_CHECK="block"` e o comentário `:13-29` reescrito (premissa refutada
  para 3 de 7 + o LIMITE das 0001/0002/0005/0007).
- **Onde declarar o limite das 4 ADRs sem `Spec:`** (proposta): no próprio comentário do `.sdd/config.sh`, que é
  onde mora a decisão do `ADR_CHECK` deste repo. Não é limite do sensor: o `sdd adr check` lê o vínculo a partir
  da missão, e ADR que nenhuma missão declara não é cobrada (medido: hoje as 7 sem `Spec:` não geram linha
  nenhuma). Escrever `Spec: none` nelas seria pior: o valor tem de ser caminho (`bin/sdd:7003`).

**Onde:** `docs/adr/0003-judge-axis-evidence-from-target-repos.md:3`, `docs/adr/0004-mutation-catalogue-owner-stamp-not-ci.md:3`,
`docs/adr/0006-qa-anchor-reads-genre-blocked-handoff-stops-the-line.md:3` (depois da linha `Date:`); os 14
`docs/handoffs/<missão>/00-missao.md` (frontmatter); `.sdd/config.sh:13-30`.

**Como (TDD):** Red medido em fe9441d + passo 0: Check → `1 0 0` (a linha `14 mission(s) have no decided 'adr:'`
existe; `ADR_CHECK=warn, 15 ADR(s)`; nenhuma das três tem `Spec:`). Edição mecânica (o protótipo usou um laço
Python: para cada missão, `adr: <valor>` inserido antes do 2º `---`; para cada ADR mapeada, `['', 'Spec: …']`
inserido depois da linha `Date: `). Resultado das ADRs:
```
# 0003 — The judge axis: verdict evidence comes from target repos, never from the kit itself

Date: 2026-08-17 · Status: accepted

Spec: docs/handoffs/20260817-eixo-do-juiz/00-missao.md

Amended by: 0014 (part 1 superseded: the axis groups by the last behaviour commit, `kit_rev`)
```
(idem 0004 com `20260819-fecho-que-nao-mente`, 0006 com `20260826-o-laco-da-qa`). Comentário novo do
`.sdd/config.sh` (substitui de `# O kit adota o proprio mecanismo em etapas` até `ADR_CHECK="warn"`; ASCII, como o atual):
```bash
# O kit adota o proprio mecanismo em etapas, na missao 20260917-o-numero-do-adr-nao-e-prosa,
# seguindo o caminho que o README.md prescreve para qualquer repo-alvo: off, warn, ETAPA 3 (fix ou
# declare), block. O I9 daquela missao pulou a etapa 3 e foi direto para `block` -- e a revisao
# pre-PR mediu o preco: as 14 missoes anteriores deste repo nao tinham chave `adr:`, entao TODAS
# voltaram a derivar PLAN (diferencial, mesma missao e mesmo disco: `off` da EXEC, `block` da
# PLAN). Por isso o repo ficou em `warn` ate a etapa 3.
#
# A etapa 3 aconteceu no I10 de 20261004-lote-4-a-catraca-zera, com o mapeamento confirmado pelo
# humano. A premissa de 2026-09-17 -- "nenhum commit liga as ADRs 0001-0007 a uma missao" -- caiu
# para tres das sete: a 0003 nasceu de 20260817-eixo-do-juiz, a 0004 de
# 20260819-fecho-que-nao-mente e a 0006 de 20260826-o-laco-da-qa. Cada uma ganhou a linha `Spec:`,
# e a missao, o `adr:` apontando de volta. As outras onze missoes declaram `adr: none`. Medido:
# `sdd adr check` -> nenhuma missao sem `adr:` decidido, rc 0 sob `block`.
#
# LIMITE declarado: as ADRs 0001, 0002, 0005 e 0007 seguem sem `Spec:`. Nenhuma nasceu de uma
# pasta de missao -- 0001 e 0002 do grill do I13.3, 0005 de um PR so de docs (#24), 0007 da spec
# da fronteira do chapeu em docs/superpowers/ --, e o `sdd adr check` le o vinculo a partir da
# missao: ADR que nenhuma missao declara nao e cobrada. Escrever `Spec:` nelas seria inventar a
# origem, o rotulo sem artefato que o principio 1 recusa.
ADR_CHECK="block"
```
Verde no protótipo (`5c79c02`): `env -u CLAUDECODE ./bin/sdd adr check` → rc 0, `  ok    ADR_CHECK=block, 15 ADR(s) in docs/adr`,
`  info  14 mission(s) declare 'adr: none' — a decision, written down`, sem a linha `have no decided`, e a missão
do lote 4 `adr: docs/adr/0015-the-stamp-is-not-headless.md — and that ADR points back`; Check → `0 1 3`;
`bash -n .sdd/config.sh` ok; `tests/check-adr.sh` rc 0 (`adr traceability: 79 probes`, 10 s); `check-lang`
`0 of 57` (as linhas `Spec:` com slug pt-BR são isentas pela regra do `ADR_LINK_LINE`).

**Sabotagens/mutantes:** nada disso está na chave do carimbo (`docs/`, `.sdd/`) e nada é código. O sensor é o
próprio `sdd adr check` sob `block` (o gate de PLAN/EXEC deste repo passa a recusar missão sem `adr:` decidido).
Contraprova dos dois lados já está no Check (`have no decided` 1 → 0 e `ADR_CHECK=block` 0 → 1).

**Check:** `o=$(env -u CLAUDECODE ./bin/sdd adr check 2>/dev/null); a=$(grep -c 'have no decided' <<< "$o"); b=$(grep -c '^  ok    ADR_CHECK=block, ' <<< "$o"); c=$(awk '/^Spec: docs[/]handoffs[/]/{c++} END{print c+0}' docs/adr/0003-judge-axis-evidence-from-target-repos.md docs/adr/0004-mutation-catalogue-owner-stamp-not-ci.md docs/adr/0006-qa-anchor-reads-genre-blocked-handoff-stops-the-line.md); echo "$a $b $c"` → `0 1 3`
(antes, medido em fe9441d + passo 0: `1 0 0`).

**Sensor durável:** `sdd adr check` + `adr_gate_verdict` sob `ADR_CHECK=block` (gates PLAN e EXEC deste repo).

**Saída do item:** `RESOLVED by <hash>` no I24 (é conserto, não decisão). Catraca não muda aqui.

**Âncoras do TODO.md que o incremento desloca:** nenhuma (a âncora do #134 é `docs/adr/0001-…md:1`, arquivo
inteiro, e a 0001 não é tocada).

**Reversível por:** `git revert` do commit (volta a `warn` e tira as 14 chaves e as 3 linhas `Spec:`).

### I11 — MEC: o `kaizen_reminder` responde com a frase do kit num worktree do kit (item "O `kaizen_reminder` diz a frase de repo-alvo…")

**O quê:** `kaizen_reminder` passa a decidir "estou no kit?" com `ledger_repo_root` dos dois lados
(o common dir do git, igual em todo worktree do mesmo repo), espelhando a porta do `sdd kaizen`
consertada em `188ca87` (#121). Hoje compara o `--show-toplevel` de `$SDD_HOME` com `$REPO_ROOT`,
que é por worktree: rodado de um worktree do kit, o `sdd` imprime a frase de repo-alvo ("N
mission(s) of this repo … The kaizen judge counts them"). No mesmo commit: os 3 comentários podres
que dizem que a porta do `cmd_kaizen` "carries a live worktree bug" (dois em `bin/sdd`, um no
fixture de `tests/check-gates.sh` — o terceiro não estava na lista do brief, achado por grep). O
`kit_guard_check` (`bin/sdd:3757`, a comparação de toplevel em `:3776-3780`) fica como está
(decisão do `188ca87`).
**Onde:** `bin/sdd` — `kaizen_reminder` (`:10131`; troca em `:10154-10156`), comentário acima de
`has_mutation_catalogue` (`:2120-2121`), comentário do carimbo dentro de `gate_PR` (`:2307-2309`);
`tests/check-kaizen.sh` (logo depois de `assert_eq "pointing at sdd kaizen"`, `:1234-1235`);
`tests/check-mutation.sh` — `mut_KAIZEN_reminder_wrong_repo` (`:3591`) e `CATALOG=(` (`:5916`);
`tests/check-gates.sh` — heredoc do catálogo-dublê (`:2709-2711`).
**Como (TDD):**
1. Probe primeiro, em `tests/check-kaizen.sh`, logo depois das duas linhas de
   `assert_eq "pointing at sdd kaizen" …` (o fixture `$FIX` já é o kit e o ledger já tem 3 missões
   sobre `aaa1111` sem veredito):
   ```bash

   # A linked WORKTREE of the kit is still the kit, and has to get the kit's sentence (TODO.md, the
   # kaizen_reminder item). kaizen_reminder compared `git rev-parse --show-toplevel` of $SDD_HOME with
   # $REPO_ROOT — two toplevels, which differ by construction in a worktree — so a run finished in a
   # worktree of the kit was told it was a target repo. The sibling door (cmd_kaizen, issue 121) was
   # fixed in 188ca87 by asking ledger_repo_root on both sides; this pins the reminder to the same
   # question. Differential pair: the kit sentence present AND the target-repo sentence absent, so a
   # mutant that forced either branch is caught by the same fixture. main moves into the worktree so
   # ensure_mission_branch has nothing to switch; the ledger is a copy, so the run below it is unmoved.
   cp -r "$SDD_STATE_DIR" "$OUTSIDE/state-wt"
   git -C "$FIX" checkout -q -b reminder/park
   RWT="$OUTSIDE/kit-worktree-reminder"
   git -C "$FIX" worktree add -q "$RWT" main
   out_wt="$( cd "$RWT" && SDD_STATE_DIR="$OUTSIDE/state-wt" "$KSDD" run 20260102-donemission 2>&1 )" || true
   assert_eq "reminder: a linked worktree of the kit answers with the kit sentence" "yes" \
     "$(grep -q 'for the next kit mission plan' <<< "$out_wt" && echo yes || echo no)"
   assert_eq "reminder: and not with the target-repo sentence" "no" \
     "$(grep -q 'The kaizen judge counts them' <<< "$out_wt" && echo yes || echo no)"
   git -C "$FIX" worktree remove --force "$RWT"
   git -C "$FIX" checkout -q main
   git -C "$FIX" branch -q -D reminder/park
   ```
2. Vermelho pelo motivo certo, medido em `fe9441d` + só o probe (15 s):
   `FAIL  reminder: a linked worktree of the kit answers with the kit sentence` e
   `FAIL  reminder: and not with the target-repo sentence`, rc 1 — a linha impressa foi a de alvo:
   `autonomy series: 3 mission(s) of this repo on kit aaa1111 are in the ledger. The kaizen judge counts them (ADR 0005) — run 'sdd kaizen' in the kit repo (…/fix).`
3. Conserto em `kaizen_reminder` (3 linhas por 3 — nenhuma linha de `bin/sdd` se desloca):
   ```bash
   local kit_id here_id
   kit_id="$( REPO_ROOT="$SDD_HOME" ledger_repo_root )"; here_id="$( ledger_repo_root )"
   if [ -n "$kit_id" ] && [ "$kit_id" = "$here_id" ]; then
   ```
   (no lugar de `local kit_root` / `kit_root="$( cd "$SDD_HOME" && git rev-parse --show-toplevel 2>/dev/null || true )"` /
   `if [ -n "$kit_root" ] && [ "$kit_root" = "$REPO_ROOT" ]; then`). `ledger_repo_root` sempre
   retorna 0 (`|| return 0`), então a captura sob `set -e` é segura — a mesma grafia de
   `cmd_kaizen` (`:10411`).
4. Comentários podres, reescritos com a MESMA contagem de linhas:
   - `bin/sdd:2120-2121` → `# Scoped by ARTIFACT and never by the identity of the repository, for the reason gate_PR records`
     / `# below: the stamp describes a catalogue, so the question is whether one is HERE.`
   - `bin/sdd:2307-2309` (as 3 linhas a partir de `# repository. A target repo has no tests/check-mutation.sh…`) →
     ```
       # repository. A target repo has no tests/check-mutation.sh, so nothing about it changes; and the
       # stamp describes a catalogue, so a second clone or a worktree that carries one is a tree it is
       # about (the identity door, cmd_kaizen, stopped misreading a worktree in 188ca87, issue 121).
     ```
   - `tests/check-gates.sh:2710-2711` (heredoc `CAT`) → `# chosen over the identity of the repository because the stamp describes a catalogue, wherever one`
     / `# is.`
   - Conferir: `grep -c 'live worktree bug' bin/sdd tests/check-gates.sh` → 0 e 0.
5. Verde: `check-kaizen.sh` rc 0, as duas asserções `ok`.
**Sabotagens/mutantes:** re-âncora de `mut_KAIZEN_reminder_wrong_repo` (a âncora antiga deixa de
aplicar — `CATALOGUE-BROKEN … (rc 90)`, medido pelo verificador):
```bash
mut_KAIZEN_reminder_wrong_repo() {
  sed -i '/^kaizen_reminder()/,/^}/ s@if \[ -n "\$kit_id" \] && \[ "\$kit_id" = "\$here_id" \]; then@if true; then@' "$1"
}
# The reminder goes back to comparing TOPLEVELS, the spelling 188ca87 removed from the kaizen door
# and left here: a linked worktree of the kit has a toplevel of its own, so a run finished in one is
# told it stands in a target repo. Caught by the differential pair `reminder: a linked worktree of
# the kit answers with the kit sentence` / `and not with the target-repo sentence` in check-kaizen.sh.
mut_KAIZEN_reminder_per_worktree() {
  sed -i '/^kaizen_reminder()/,/^}/ s@kit_id="\$( REPO_ROOT="\$SDD_HOME" ledger_repo_root )"; here_id="\$( ledger_repo_root )"@kit_id="$( git -C "$SDD_HOME" rev-parse --show-toplevel )"; here_id="$REPO_ROOT"@' "$1"
}
```
+ `KAIZEN_reminder_per_worktree` no `CATALOG=(` logo depois de `KAIZEN_reminder_wrong_repo`.
Provado: `tests/check-mutation.sh --only KAIZEN_reminder_per_worktree check-kaizen.sh` →
`  ok    KAIZEN_reminder_per_worktree — check-kaizen.sh dies (rc 1)` (17,3 s);
`--only KAIZEN_reminder_wrong_repo check-kaizen.sh` → `dies (rc 1)` (17,3 s); `--anchors` →
`all 594 mutants still apply` (4,5 s). Os dois FAIL do vermelho em `fe9441d` foram exatamente o par
diferencial, então o mutante `per_worktree` (que restaura a grafia de toplevel) morre por ele.
**Check:** `o=$(bash tests/check-kaizen.sh 2>&1); grep -c '^  ok    reminder: a linked worktree of the kit answers with the kit sentence' <<< "$o"` → `1`   (antes, medido em fe9441d: `0`)
**Sensor durável:** o par `reminder: a linked worktree…` / `reminder: and not with the target-repo
sentence` em `check-kaizen.sh`; `mut_KAIZEN_reminder_per_worktree` (novo) e
`mut_KAIZEN_reminder_wrong_repo` (re-ancorado).
**Saída do item:** `RESOLVED by <hash do I11>` no I24; catraca move no chore pós-merge (−1).
**Âncoras do TODO.md que o incremento desloca:** nenhuma em `bin/sdd` (contagem de linhas
preservada); `tests/check-mutation.sh:6104` (2º span do item #67, citação) +6. Medido: no commit do
I11, `bash tests/check-todo.sh` segue `23 finding(s) … every anchor on target`. A âncora do próprio
item (`bin/sdd:10156`) passa a cair na linha `kit_id=…`, ainda dentro de `kaizen_reminder`.
**Reversível por:** `git revert` do commit.

`| I11 | MEC: kaizen_reminder num worktree do kit | `o=$(bash tests/check-kaizen.sh 2>&1); grep -c '^  ok    reminder: a linked worktree of the kit answers with the kit sentence' <<< "$o"` → `1` | pending | — |`

### I12 — #67: `agents/` entra na chave do carimbo

**O quê:** `readonly MUTATION_STAMP_PATHS=(bin tests templates config agents)`. O runner lê todo
chapéu de `agents/<hat>.md` (`hat_field`, `bin/sdd:2534`), e `check-hat.sh`, `check-autonomy.sh`
e `check-kaizen.sh` copiam o `agents/` real para os fixtures — o veredito do catálogo é função
dele, e hoje uma edição só em `agents/` não move a chave. `CLAUDE.md`, `TODO.md`, `docs/adr` e
`docs/pipeline.md` (copiado pela `sandbox()` a partir do I23 — fato do designer B) ficam FORA,
declarados no comentário. Quem mais lê o array: `MUTATION_STAMP_PATHSPEC` (`:2100`, construído dele,
nada a mudar), `mutation_stamp_missing` (`:2192`, passa a exigir `agents/` — por isso dois fixtures
mudam) e as mensagens de `mutation_stamp_why`/`cmd_health` (`${MUTATION_STAMP_PATHS[*]}`, mudam
sozinhas). A ordem no array não muda a chave (`git ls-files` ordena; `sort -zu` de novo), só a ordem
na mensagem de "missing".
**Onde:** `bin/sdd` — comentário `:2077-2084`, array `:2095`, comentário de `mutation_stamp_key`
`:2167`, comentário de `mutation_stamp_missing` `:2189`; `tests/check-gates.sh` — mundo 3
(`:2736-2742`), novo mundo 11b depois de `rm -f "$FIX/tests/debug.log"` (`:2878`), `TREE_KIT`
(`:2948-2954`), comentários `:2542-2544`, `:2611`, `:2621`, `:2819`, nome da asserção `:2834`,
`:2974`; `tests/check-health.sh` — `build_fixture` (`:191-197`) e comentário `:227`;
`tests/check-mutation.sh` — comentários `:1241-1243` e `:6315`, mutante novo e `CATALOG=(`
(`:5683`); prosa viva listada abaixo.
**Como (TDD):**
1. Fixture primeiro (ainda verde em `fe9441d`, `agents/` não é medido): no mundo 3 de
   `check-gates.sh`, o fixture-kit ganha `agents/`:
   ```bash
   # All FIVE measured paths, each holding a file: mutation_stamp_key refuses a root missing any one of
   # them (ADR 0014, increment I3; agents/ since ADR 0015 §1), so a fixture with only bin/ and tests/
   # would never be stamped and every world below would be measuring that refusal instead of what it
   # names. A file in each, and not an empty directory, because git does not track an empty directory.
   mkdir -p "$FIX/templates" "$FIX/config" "$FIX/agents"
   printf 'fixture template\n' > "$FIX/templates/fixture.md"
   printf 'fixture config\n' > "$FIX/config/fixture.conf"
   printf -- '---\nname: fixture-hat\n---\n# A hat\n' > "$FIX/agents/fixture-hat.md"
   ```
2. Probe (mundo 11b), logo depois de `rm -f "$FIX/tests/debug.log"`:
   ```bash

   # 11b. AGENTS — a commit touching only agents/ moves the key (#67; ADR 0015 §1). The runner reads
   #      every hat out of agents/<hat>.md (hat_field: `writes:`, `disallowedTools:`, `mcp:`), and
   #      check-hat.sh, check-autonomy.sh and check-kaizen.sh copy the real agents/ into their
   #      fixtures, so the catalogue's verdict is a function of it. The key used to read only bin/,
   #      tests/, templates/ and config/, and a stamp written before a hat edit stayed valid over
   #      content no catalogue had run against. Stamped again first and read back as DONE, so the PR
   #      afterwards is about the commit and never about a stamp that was not there.
   i4_verdict 0 "$I4_SCORE_GREEN"; i4_health
   agents_before="$( cd "$FIX" && "$SDD" phase "$MISSION" 2>&1 )"
   printf 'one more line of the hat, after the stamp\n' >> "$FIX/agents/fixture-hat.md"
   git add -A && git commit -qm "chore: only agents/ moves" >/dev/null
   assert_eq "stamp-key: a commit touching only agents/ moves the key" "DONE|PR" \
     "$agents_before|$( cd "$FIX" && "$SDD" phase "$MISSION" 2>&1 )"
   ```
3. Vermelho pelo motivo certo (`fe9441d` + fixture + probe, 72 s):
   `FAIL  stamp-key: a commit touching only agents/ moves the key` / `expected: DONE|PR` /
   `got:      DONE|DONE`, rc 1 — o único FAIL.
4. Conserto em `bin/sdd`: o array e o comentário (8 linhas por 8 — nenhuma linha se desloca):
   ```bash
   # FIVE, and the boundary is declared rather than assumed. The mutants edit bin/sdd; their fate is
   # decided by the assertions in tests/ and what those read: templates/, config/ and agents/ (the
   # runner reads each hat out of agents/<hat>.md, and three sensors copy the real agents/ into their
   # fixtures; agents/ joined in ADR 0015 §1, #67, at 0 extra `sdd health` runs in the last 30 merges).
   # sandbox() in tests/check-mutation.sh also copies CLAUDE.md, TODO.md, docs/adr, docs/pipeline.md:
   # OUT on purpose. Their readers work apart from any behaviour mutant (the ADR 0003 shape, the policy
   # rule of check-health.sh, the series-key block of check-kaizen.sh), and the DOCS phase edits them
   # on the way to the PR, so keying on them would throw the stamp away 14 more times in 30 merges.
   ```
   e `readonly MUTATION_STAMP_PATHS=(bin tests templates config agents)`. ⚠️ `docs/pipeline.md` só
   entra na `sandbox()` no I23 (designer B); o comentário já o nomeia — se o I23 cair, tire-o daqui.
   Comentários de uma linha: `:2167` `ANY ONE of the four paths` → `ANY ONE of the paths`; `:2189`
   `(empty ⇒ all four are there)` → `(empty ⇒ all of them are there)`.
5. Fixtures que PRECISAM de `agents/` depois do conserto (medido — sem eles o carimbo vira "agents/
   missing" e os mundos medem a recusa):
   - `check-health.sh` `build_fixture`: `mkdir -p "$FIX/bin" "$FIX/tests" "$FIX/config" "$FIX/templates" "$FIX/agents"`
     + `printf 'fixture hat\n' > "$FIX/agents/fixture-hat.md"`, comentário "templates/ and agents/
     too … any of its five measured paths (ADR 0014, increment I3; agents/ since ADR 0015 §1)".
     Medido sem eles: 3+ FAIL em `check-health.sh`, todos com `nothing was stamped: agents/ missing at …`.
   - `check-gates.sh` `TREE_KIT`: `mkdir -p … "$TREE_KIT/config" \` / `  "$TREE_KIT/agents" "$TREE_KIT/.sdd/logs"`
     + `printf 'installed hat\n' > "$TREE_KIT/agents/fixture-hat.md"`, comentário "The five measured paths".
6. Prosa dos testes que diz "four" (troque por "five"/"the paths"): `check-gates.sh:2542-2544`
   (vira "Six more worlds … AGENTS (11b) … the five paths … agents/ since ADR 0015 §1"), `:2611`,
   `:2621`, `:2819` ("one of the five measured paths is gone and the other four are all there"),
   `:2974`; nome da asserção `:2834` → `stamp-key: a root missing one of the measured paths is never stamped`
   (sem número, para não envelhecer); `check-health.sh:227`; `check-mutation.sh:1241-1243`
   ("five … the four that remain … the all-absent case") e `:6315` ("OUTSIDE the directories of
   mutation_stamp_key").
7. Prosa viva que diz a chave (mesmo commit — contrato): `README.md:166` e `:173`
   (`` `bin/ tests/ templates/ config/` `` → `` `bin/ tests/ templates/ config/ agents/` ``);
   `docs/failure-modes.md:877-878` ("four paths" ×2 → "five"), `:889`, `:897` ("four paths" →
   "five"), `:925` e **`:948`, o one-liner que o `CLAUDE.md` manda rodar antes de re-carimbar**:
   `git ls-files -z -c -- bin tests templates config agents ':(exclude)tests/health-baseline.txt' \`
   (medido: com `agents` o one-liner dá o mesmo md5 que `mutation_stamp_key`; sem, mente);
   `docs/pipeline.md:471-472` (`agents/` e "one of the five paths"); `CLAUDE.md:313`
   (`` `bin/ tests/ templates/ config/ agents/` ``); `CONTEXT.md:28`, verbete "Carimbo de mutação"
   (`` `bin/ tests/ templates/ config/ agents/` (`MUTATION_STAMP_PATHS`; `agents/` desde a ADR 0015 §1) `` e
   "os cinco são obrigatórios"). `.claude/rules/anatomia-do-agente.md`: grep não acha a lista —
   nada a mudar. **Fora, de propósito:** `docs/adr/0004` (`:40`) e `docs/adr/0014` (`:34`, `:38`,
   `:62-64`) são decisão datada — quem as emenda é a ADR 0015 §1 (planner); `docs/qa/**` e
   `docs/superpowers/**` são registros históricos (o `docs/qa/README.md:86` é da árvore das skills
   de QA, não da DOCS); `agents/sdd-publisher.md:43` é reescrito pelo I14.
8. Verde: `check-gates.sh` rc 0 (o mundo 11b `ok`, e `gate_PR: the mutation stamp is demanded only
   where the catalogue lives` continua `ok`), `check-health.sh` rc 0 (26 s).
**Sabotagens/mutantes:**
```bash
# agents/ falls out of the key again (#67; ADR 0015 §1): a commit that edits only a hat leaves the
# stamp valid over content the catalogue never ran against, though the runner reads every hat out of
# agents/<hat>.md. Caught by `stamp-key: a commit touching only agents/ moves the key` (world 11b of
# check-gates.sh), the only world that edits agents/ alone.
mut_PR_stamp_key_ignores_agents() {
  sed -i 's@^readonly MUTATION_STAMP_PATHS=(bin tests templates config agents)$@readonly MUTATION_STAMP_PATHS=(bin tests templates config)@' "$1"
}
```
(antes de `mut_PR_stamp_key_keeps_baseline`) + `PR_stamp_key_ignores_agents` no `CATALOG=(` depois
de `PR_stamp_key_keeps_baseline`. Provado: `--only PR_stamp_key_ignores_agents check-gates.sh` →
`  ok    PR_stamp_key_ignores_agents — check-gates.sh dies (rc 1)` (79,2 s); `--anchors` → `all
595 mutants`. Âncora em CÓDIGO (a linha inteira do array, sem faixa: é top level).
**Check:** `o=$(bash tests/check-gates.sh 2>&1); grep -c '^  ok    stamp-key: a commit touching only agents/ moves the key' <<< "$o"` → `1`   (antes, medido em fe9441d: `0`)
**Sensor durável:** mundo 11b de `check-gates.sh` + `mut_PR_stamp_key_ignores_agents`; os fixtures
de `check-gates.sh`/`check-health.sh` passam a exigir os cinco caminhos.
**Saída do item:** `RESOLVED by <hash do I12>` no I24 (item "O carimbo de mutação cobre 4 dos 8
caminhos que a sandbox do catálogo copia"); catraca −1 no chore pós-merge. ADR 0015 §1 registra a
emenda a 0004 §2 e 0014 §4 ("four directories" → cinco; `CLAUDE.md`, `TODO.md`, `docs/adr`,
`docs/pipeline.md` fora, com o porquê e o custo medido: 0 vs 14 `sdd health` a mais em 30 merges).
**Âncoras do TODO.md que o incremento desloca:** nenhuma em `bin/sdd` (contagem preservada);
`tests/check-mutation.sh:6104` (2º span do próprio #67) +8.
**Reversível por:** `git revert` do commit; o carimbo do `sdd health` seguinte volta a ignorar
`agents/` sozinho.

`| I12 | #67: agents/ na chave do carimbo | `o=$(bash tests/check-gates.sh 2>&1); grep -c '^  ok    stamp-key: a commit touching only agents/ moves the key' <<< "$o"` → `1` | pending | — |`

### I13 — #142+#198a: o `sdd run` para no carimbo em vez de abrir sessão

**O quê:** o `gate_PR` não muda de veredito. Ele passa a PUBLICAR, num marcador global
`GATE_PR_STAMP_WHY` (vazio = desarmado; armado = a frase da recusa), o caso "o carimbo é a ÚNICA
recusa": zera na entrada, arma ao lado das duas recusas do carimbo (`no mutation stamp is possible…`
e `no green mutation catalogue…`), que só um gate que passou por `50-pr.md`, `pr_url`, `gh pr view`
e os `⛔` alcança. O `cmd_run`, logo abaixo da parada do PLAN, numa volta de fase `PR` (derivada,
forçada ou projetada) CHAMA `gate_PR || true` e, com o marcador armado, sai com **rc 2 sem abrir
sessão**, nomeando `sdd health` e a ordem.
**rc 2 e não escalada (decidido e conferido):** o único `return 2` do `cmd_run` hoje é o PLAN
(`bin/sdd:8093`: "the PLAN phase is not headless" — mão humana por desenho). Escalada é rc 3 +
linha `blocked` no ledger + `ON_ESCALATION_CMD`: contaria como fricção do kit no juiz (D12/D16) um
passo que é humano por desenho. O carimbo é a mesma classe do PLAN: sem linha de ledger, sem pager,
sem nota `intervention:`. O `--dry-run` projeta a parada: o bloco fica ACIMA do ramo de dry-run,
como o PLAN, e devolve o mesmo rc 2 (provado por asserção própria). Efeito colateral declarado: o
salto `PUBLISH_ON_REVIEW_BLOCKED=draft` (força PR) também para em rc 2 quando o PR está aberto e só
falta o carimbo — só existe no kit, e é o mesmo passo humano.
**Onde:** `bin/sdd` — novo global acima de `gate_PR` (`:2254`), reset na entrada, arme em `:2334`
e `:2339`; `cmd_run` (`:7971`) logo depois do bloco do PLAN (`:8085-8094`); `tests/check-gates.sh`
— mundo 4b, depois de `i4_why "stale stamp" …` (`:2766`); `tests/check-mutation.sh`;
`docs/pipeline.md` (depois de `:485`); `docs/failure-modes.md` (`:884-886`).
**Como (TDD):**
1. Probe primeiro — mundo 4b de `check-gates.sh` (catálogo presente, PR "vivo" pelo stub de `gh`,
   carimbo velho desde o mundo 4; o stub de `claude` conta sessões em `.stub/sessions`):
   ```bash

   # 4b. THE STAMP IS NOT HEADLESS (#142, #198; ADR 0015 §1). The PR is open, every other requirement
   #     is met and only the stamp is stale: `sdd run` stops with rc 2 and opens NO session — the
   #     claude stub counts them —, naming the command and the order. Differential, so neither half
   #     can pass by accident: with 50-pr.md carrying no pr_url the stamp is NOT the only refusal, and
   #     the same run must buy the publisher's session and say nothing about the stamp. Own assertions,
   #     outside the i4 tally, which is named for the scope of the demand.
   stamp_s0="$(stub_sessions)"
   stamp_out="$( cd "$FIX" && "$SDD" run "$MISSION" 2>&1 )"; stamp_rc=$?
   stamp_s1="$(stub_sessions)"
   assert_eq "run stops at the stamp: rc 2, no session, the stop names './bin/sdd health'" "2|0|1|1" \
     "$stamp_rc|$(( stamp_s1 - stamp_s0 ))|$(grep -c 'the stamp is not headless' <<< "$stamp_out")|$(grep -c "run './bin/sdd health' once" <<< "$stamp_out")"
   # The projection stops where the run would — the stop sits above the dry-run branch, like PLAN's.
   stamp_s0="$(stub_sessions)"
   stamp_out="$( cd "$FIX" && "$SDD" run --dry-run "$MISSION" 2>&1 )"; stamp_rc=$?
   stamp_s1="$(stub_sessions)"
   assert_eq "run stops at the stamp under --dry-run too: rc 2, no session" "2|0|1" \
     "$stamp_rc|$(( stamp_s1 - stamp_s0 ))|$(grep -c 'the stamp is not headless' <<< "$stamp_out")"
   cp "$MDIR/50-pr.md" "$SDD_STATE_FIX/50-pr-before-stamp-stop.md"
   printf -- '---\nfase: PR\n---\n# PR\n' > "$MDIR/50-pr.md"
   git add -A && git commit -qm "chore: 50-pr.md loses its pr_url" >/dev/null
   stamp_s0="$(stub_sessions)"
   stamp_out="$( cd "$FIX" && "$SDD" run "$MISSION" 2>&1 )"; stamp_rc=$?
   stamp_s1="$(stub_sessions)"
   assert_eq "run stops at the stamp only when the stamp is the only refusal" "yes|0" \
     "$( [ "$stamp_s1" -gt "$stamp_s0" ] && echo yes || echo no )|$(grep -c 'the stamp is not headless' <<< "$stamp_out")"
   cp "$SDD_STATE_FIX/50-pr-before-stamp-stop.md" "$MDIR/50-pr.md"
   git add -A && git commit -qm "chore: 50-pr.md gets its pr_url back" >/dev/null
   ```
   O commit de `50-pr.md` move o HEAD e nenhum byte medido, então os mundos 5+ seguem iguais
   (medido: `check-gates.sh` rc 0 com o bloco).
2. Vermelho pelo motivo certo (I12 aplicado, sem o runner do I13, 72 s):
   `FAIL  run stops at the stamp: rc 2, no session, the stop names './bin/sdd health'` /
   `expected: 2|0|1|1` / `got:      3|1|0|0` — o runner comprou a sessão de publisher (o stub sai
   97) e escalou com rc 3. A metade diferencial passou (`ok`), como deve: hoje toda volta de PR abre
   sessão. (A asserção de `--dry-run` foi acrescentada depois desta medição; em `fe9441d` ela não
   existe — o Check abaixo conta 1, só a guarda.)
3. Conserto em `bin/sdd`. Acima de `gate_PR() {`:
   ```bash
   # The refusal of gate_PR when the STAMP is all that is missing — the PR is open and every other
   # requirement above the stamp is met — PUBLISHED for cmd_run, which stops on it with rc 2 instead of
   # opening a publisher session (ADR 0015 §1; #142, #198). No session can write the stamp: `sdd health`
   # runs for twenty to fifty minutes, a headless session ends with its turn, and the order that makes
   # one run enough (every review bot, one batch of fixes, then the stamp) is the human's. A MARKER and
   # not a grep of GATE_WHY, for the reason GATE_APP_DOWN gives: GATE_WHY is prose.
   #
   # CONTRACT, re-derived and not inherited: reset at the ENTRY of gate_PR, its only setter, and armed
   # beside the two stamp refusals at the bottom, which only a gate that got past every other check
   # reaches. Read once, by cmd_run, right after a gate_PR it CALLED in the same lap — never through
   # `$( )`, where the assignment dies with the subshell (next_pending_phase is such a caller).
   # ⚠️ NO PROBE for the reset, declared: every lap that finds the marker armed returns 2 and every
   # `sdd run` is a new process, so no world reaches a gate_PR call over a marker left armed.
   GATE_PR_STAMP_WHY=""

   gate_PR() {
     GATE_PR_STAMP_WHY=""
   ```
   e `GATE_PR_STAMP_WHY="$GATE_WHY"` como linha nova logo antes de cada um dos dois `return 1` do
   carimbo (depois de `GATE_WHY="no mutation stamp is possible…"` e de
   `GATE_WHY="no green mutation catalogue…"`). No `cmd_run`, logo depois do `fi` do bloco do PLAN:
   ```bash

       # The STAMP is not headless either (ADR 0015 §1; #142, #198), and the stop is PLAN's: rc 2, no
       # session, no ledger row, no hook — a designed hand-off to the human, not an escalation. With
       # the PR open and only the stamp missing, a publisher session can do nothing that satisfies
       # gate_PR: it used to run `sdd health` itself, end its turn waiting for it (which ends a
       # headless session), and stamp before the review bots had spoken, so their first code fix threw
       # the stamp away. Measured: 19 PR sessions of the kit, US$ 39,13, 4,6 h. gate_PR is CALLED here
       # on every PR lap — derived, forced or projected — because only a call in this shell publishes
       # the marker; on a derived lap it repeats derive_phase's call, one `gh pr view` more. Above the
       # dry-run branch, like PLAN, so the projection stops where the run would. ⚠️ Declared limit:
       # `sdd retry PR` is the human's hand on the phase and has no such door.
       if [ "$phase" = "PR" ]; then
         gate_PR || true
         if [ -n "$GATE_PR_STAMP_WHY" ]; then
           info ""
           warn "the PR phase is waiting for the mutation stamp, and the stamp is not headless: $GATE_PR_STAMP_WHY"
           dim "  The PR is open and every other requirement of its gate is met. No session can write"
           dim "  the stamp. The order: wait for every review bot on the PR, fix their findings in one"
           dim "  batch, run './bin/sdd health' once, then 'sdd run $MISSION' again."
           return 2
         fi
       fi
   ```
   Por que CHAMAR o gate em vez de ler o marcador do `derive_phase`: no cursor de dry-run a fase vem
   de `next_pending_phase`, que roda os gates dentro de `$( )` (`bin/sdd:8338`) e perde o global; sob
   `--phase PR` nenhum gate rodou na volta. A chamada custa um `gh pr view` a mais por volta de PR.
   No-work: a porta 1 restaura `GATE_WHY="$CURRENT_PHASE_WHY"` antes de comparar, então a chamada
   extra não a afeta.
4. Verde: `check-gates.sh` rc 0, as três asserções `run stops at the stamp…` `ok` e a guarda
   `  ok    gate_PR: the mutation stamp is demanded only where the catalogue lives` continua 1.
5. Prosa: `docs/pipeline.md`, novo parágrafo depois de "…is [ADR 0004](adr/0004-…)." (`:485`):
   "**The stamp is not headless** (ADR 0015 §1). When the PR is open and the stamp is the only thing
   `gate_PR` misses, `sdd run` stops with **rc 2** and opens no session — PLAN's stop, not an
   escalation: no ledger row, no pager. No session can write the stamp, and the order that makes one
   `sdd health` enough is the human's: every review bot on the PR, their fixes in one batch,
   `./bin/sdd health` once, then `sdd run <mission>` again. The publisher no longer runs it; the PR
   body carries that order. `gate_PR` publishes the case as a marker (`GATE_PR_STAMP_WHY`) so the
   runner never reads it out of the prose. `sdd retry PR` has no such stop — it is the human's hand."
   `docs/failure-modes.md:886`, ao fim do parágrafo "How the kit reacts": "With the PR open and the
   stamp the only thing missing, `sdd run` itself stops with rc 2 and opens no session (`the stamp is
   not headless`): the publisher never runs `sdd health` (ADR 0015 §1)."
**Sabotagens/mutantes:** dois, um por metade do par diferencial:
```bash
# The stamp stop goes away (#142, #198; ADR 0015 §1): with the PR open and only the stamp missing,
# `sdd run` buys a publisher session that cannot write the stamp. Caught by `run stops at the stamp:
# rc 2, no session, the stop names './bin/sdd health'` (world 4b of check-gates.sh).
mut_RUN_stamp_stop_missing() {
  sed -i '/^cmd_run() {/,/^}/ s@if \[ -n "\$GATE_PR_STAMP_WHY" \]; then@if false; then@' "$1"
}
# gate_PR arms the stamp marker on ENTRY instead of beside the stamp refusals, so `sdd run` stops "at
# the stamp" over a PR that is not even open — the half of world 4b that a missing stop cannot reach.
# Caught by `run stops at the stamp only when the stamp is the only refusal` in check-gates.sh.
mut_PR_stamp_marker_always() {
  sed -i '/^gate_PR() {/,/^}/ s@^  GATE_PR_STAMP_WHY=""$@  GATE_PR_STAMP_WHY="armed on entry"@' "$1"
}
```
+ `RUN_stamp_stop_missing` e `PR_stamp_marker_always` no `CATALOG=(` (no protótipo, depois de
`PR_stamp_key_ignores_agents`). Provados: `--only RUN_stamp_stop_missing check-gates.sh` →
`dies (rc 1)` (86,4 s); `--only PR_stamp_marker_always check-gates.sh` → `dies (rc 1)` (84,4 s).
Rodando `check-gates.sh` inteiro sob `PR_stamp_marker_always` (sem `SDD_MUTANT`), o PRIMEIRO FAIL é
a metade diferencial (`expected: yes|0` / `got: no|1`); outro FAIL depois, em
`the warning does not change the rc of sdd run` (`main=2 feature=2`) — o mutante também quebra
projeções de outros mundos. Não provado por probe: o reset na entrada (declarado no comentário).
**Check:** `o=$(bash tests/check-gates.sh 2>&1); grep -c -e '^  ok    run stops at the stamp' -e '^  ok    gate_PR: the mutation stamp is demanded only where the catalogue lives' <<< "$o"` → `4`   (antes, medido em fe9441d: `1` — só a guarda)
**Sensor durável:** mundo 4b (três asserções: parada, parada sob `--dry-run`, diferencial) + a
guarda do i4; `mut_RUN_stamp_stop_missing`, `mut_PR_stamp_marker_always`.
**Saída do item:** com o I14, `RESOLVED by <hash I13> <hash I14>` nos dois itens ("O
`sdd-publisher` não consegue esperar o `sdd health`…" e "O carimbo da fase PR é medido antes da
revisão dos bots…") no I24; catraca −2 no chore pós-merge. A direção escrita no #142 ("o runner
roda `sdd health` antes de abrir a sessão") foi RECUSADA pelo humano (ADR 0015 §1: o carimbo não é
headless) — diga isso no texto do RESOLVED.
**Âncoras do TODO.md que o incremento desloca:** `bin/sdd` +18 depois de `:2339` e +40 depois de
`:8095` → `bin/sdd:4315` (#129) +18; `bin/sdd:9623` (item "O schema da série não tem sensor de
drift…") +40; `bin/sdd:10156` (MEC) +40; `docs/pipeline.md:1028` (item "35% do docs/pipeline.md…")
+8 e `:1379` (2º span, citação, não reescrito) +8. Rode `remap.py <rev do I12>` e `xref.py HEAD --fix`.
**Reversível por:** `git revert` do commit (o runner volta a abrir sessão de publisher).

`| I13 | #142+#198a: o sdd run para no carimbo | `o=$(bash tests/check-gates.sh 2>&1); grep -c -e '^  ok    run stops at the stamp' -e '^  ok    gate_PR: the mutation stamp is demanded only where the catalogue lives' <<< "$o"` → `4` | pending | — |`

### I14 — #142+#198b: o publisher para de rodar o `sdd health`

**Decisão de corte:** incremento próprio, logo depois do I13 (mesma sessão se couber): arquivo,
sensor e regra de prova diferentes (chapéu + `check-hat.sh`, sem mutante — o catálogo só sabota
`bin/`), e o I13 sozinho já é um commit de runner com mutante.
**O quê:** `agents/sdd-publisher.md` deixa de mandar rodar `./bin/sdd health` dentro da sessão
headless e deixa de listar o carimbo entre as condições de parar ANTES do push (com o item lá, o
publisher pararia antes de o PR existir e a parada do I13 nunca seria alcançada). O corpo do PR
passa a carregar a ordem (bots → consertos numa leva → `./bin/sdd health` → `sdd run`).
**Onde:** `agents/sdd-publisher.md` — seção "2. Check before pushing" (`:29-47`) e a lista do corpo
do PR (depois de `- **out-of-scope findings**`, `:74`); `.claude/agents/sdd-publisher.md` (espelho,
por `./bin/sdd install --force`); `tests/check-hat.sh` — nova função depois de
`executor_agent_probes` (`:245-256`) e uma linha na lista de chamadas (`:420`).
**Como (TDD):**
1. Probe primeiro em `tests/check-hat.sh`, antes de `# --- sdd census` (`:255`):
   ```bash
   # --- the publisher and the mutation stamp (#142, #198; ADR 0015 §1) ------------------------------
   # The stamp is not headless. `sdd health` runs for twenty to fifty minutes; the publisher was told to
   # run it inside its session, started it in the background and ended its turn waiting (a headless
   # session that ends its turn has ended: US$ 1,46 for nothing), and when it did wait it stamped
   # before the review bots had spoken (#196: health at 18:13, CodeRabbit at 18:27 with a finding in
   # bin/sdd, the next run cut at 123 of 542 mutants). Since ADR 0015 the runner stops with rc 2 once
   # the PR is open and the stamp is all its gate misses, so the publisher only opens the PR. Three
   # probes, because each failure is its own: the order to run it is back; a stamp item is back in the
   # pre-push list, which makes the publisher stop BEFORE the PR exists and the runner's stop is never
   # reached; the PR body no longer carries the order the human follows. The catalogue reaches none of
   # them — it sabotages bin/sdd and this lives in agents/*.md — so these probes are the whole sensor.
   publisher_stamp_probes() {
     local pub="$ROOT/agents/sdd-publisher.md" pre
     if grep -qE 'run `\./bin/sdd health`' "$pub"; then fail "hat: the publisher is told to run ./bin/sdd health — the stamp is not headless"
     else pass "hat: the publisher never runs the stamp — it is not headless"; fi
     pre="$(awk '/^### 2\. /{on=1; next} /^### /{on=0} on' "$pub")"
     if [ -z "$pre" ]; then fail "hat: the publisher's pre-push section (### 2.) was not found — the probe would read nothing"
     elif grep -qiE '^- .*(stamp|check-mutation)' <<< "$pre"; then fail "hat: a stamp item is back in the publisher's pre-push list — it would stop before the PR exists"
     else pass "hat: and the stamp is no reason for the publisher to stop before the PR is open"; fi
     if grep -qE 'review bot.*one batch.*\./bin/sdd health.*sdd run' "$pub"; then pass "hat: and the PR body carries the order: bots, one batch of fixes, the stamp, sdd run"
     else fail "hat: the publisher's PR body lost the order before the merge"; fi
   }
   ```
   e `publisher_stamp_probes` na lista de chamadas, entre `executor_agent_probes` e `boot_probes`.
2. Vermelho pelo motivo certo (probe sobre o chapéu de `fe9441d`): rc 1, os TRÊS FAIL —
   `the publisher is told to run ./bin/sdd health`, `a stamp item is back in the publisher's
   pre-push list`, `the publisher's PR body lost the order before the merge`. (O número do
   verificador, `grep -c "run \`./bin/sdd health\`" agents/sdd-publisher.md` 1 → 0, é o mesmo fato
   que o primeiro probe mede.)
3. Conserto no chapéu. Seção 2: o último item da lista vira `- the current branch is **not** `DEFAULT_BRANCH`.`
   (ponto final), o item do carimbo (`- **in a repo that owns `tests/check-mutation.sh`** — the
   mutation stamp. Ask the runner …`, 4 linhas) sai, e o parágrafo "The stamp is the one exception
   to that last line …" (7 linhas) vira:
   ```markdown
   **The mutation stamp is not on that list, and it is not yours** (ADR 0015 §1). In a repo that owns
   `tests/check-mutation.sh` the PR gate also demands a stamp that only `sdd health` writes, and you
   never start it: it takes twenty to fifty minutes, a headless session that ends its turn waiting on
   it is a session that ended, and a stamp taken before the review bots have spoken is thrown away by
   their first fix to the code. Push and open the PR whatever the stamp says: once the PR is open and
   the stamp is all its gate misses, the runner stops on its own with rc 2 and hands it to the human.
   ```
   Na lista do corpo do PR, depois de `- **out-of-scope findings** — …`:
   ```markdown
   - **the order before the merge** — only in a repo that owns `tests/check-mutation.sh`, as this line:
     `> Before the merge: every review bot → their fixes in one batch → ./bin/sdd health → sdd run <mission>`
   ```
   Depois: `./bin/sdd install --force` (nunca `cp`/Edit em `.claude/`); conferir
   `cmp agents/sdd-publisher.md .claude/agents/sdd-publisher.md` → igual (medido: `--force` mudou só
   esse espelho).
4. Verde: `check-hat.sh` rc 0, os três `ok`.
**Sabotagens/mutantes:** sem mutante (markdown). Passada de sabotagem do probe, cada uma aplicada
(conferida) e cada uma deixou `check-hat.sh` rc 1 com o FAIL nomeado — provado no clone:
- S1: reacrescentar `The stamp: run `./bin/sdd health` (twenty to fifty minutes) and let it finish.`
  ao fim do chapéu → `FAIL  hat: the publisher is told to run ./bin/sdd health` (1).
- S2: reinserir o item `- **in a repo that owns `tests/check-mutation.sh`** — the mutation stamp.` na
  lista da seção 2 → `FAIL  hat: a stamp item is back in the publisher's pre-push list` (1).
- S3: apagar a linha `> Before the merge: …` → `FAIL  hat: the publisher's PR body lost the order` (1).
- S4: inverter a ordem (`> Before the merge: ./bin/sdd health → every review bot → …`; aplicada: 1
  linha) → `FAIL  hat: the publisher's PR body lost the order` (1).
- S5: renomear o heading `### 2. Check before pushing` → `### Two — check before pushing` (o probe
  2 leria seção vazia e passaria) → `FAIL  hat: the publisher's pre-push section (### 2.) was not
  found` (1). É o piso contra vacuidade do probe 2.
**Check:** `o=$(bash tests/check-hat.sh 2>&1); grep -c -e '^  ok    hat: the publisher never runs the stamp' -e '^  ok    hat: and the stamp is no reason for the publisher' -e '^  ok    hat: and the PR body carries the order' <<< "$o"` → `3`   (antes, medido em fe9441d: `0`)
**Sensor durável:** `publisher_stamp_probes` em `check-hat.sh` (três probes + piso); o
`sdd preflight` reprova `agent sdd-publisher stale` se o espelho não for sincronizado.
**Saída do item:** ver I13 (`RESOLVED by <I13> <I14>` nos dois itens, no I24).
**Âncoras do TODO.md que o incremento desloca:** as dos próprios itens: `agents/sdd-publisher.md:41`
(#142) cai dentro do parágrafo reescrito e continua no alvo (medido); `agents/sdd-publisher.md:42`
(#198, cita `./bin/sdd health`) sai do alvo — `check-todo.sh` acusa `nearest ./bin/sdd health is at
line 71`. **Reancore à mão no mesmo commit:** `` `agents/sdd-publisher.md:42` `` →
`` `agents/sdd-publisher.md:71` `` (a linha da ordem; confira o número com
`grep -n 'Before the merge' agents/sdd-publisher.md`). Sem isso o `TEST_CMD` fica vermelho.
**Reversível por:** `git revert` + `./bin/sdd install --force`.

`| I14 | #142+#198b: o publisher não roda o health | `o=$(bash tests/check-hat.sh 2>&1); grep -c -e '^  ok    hat: the publisher never runs the stamp' -e '^  ok    hat: and the stamp is no reason for the publisher' -e '^  ok    hat: and the PR body carries the order' <<< "$o"` → `3` | pending | — |`

### I15 — #129a: cada linha do ledger carrega o retrato do runner que a escreveu

**O quê:** campo ADITIVO `runner_sha` em toda linha do ledger = o HEAD curto do kit no LANÇAMENTO do
processo (`AUTONOMY_RUNNER_SHA`, tirado uma vez, em top level). O `kit_sha` continua lido do disco
por `autonomy_kit_stamp` na hora de montar a linha; os dois diferem exatamente quando os commits do
próprio run moveram o kit (as missões do kit: 22 de 35 `sdd run` carimbaram mais de um `kit_sha`).
A PRIMEIRA linha em que diferem avisa uma vez no terminal (`warn`) e escreve UMA linha `RUNNER` no
`pipeline.log`. O campo entra na PORTA ÚNICA (`autonomy_append`), não nos quatro construtores
(`:4236` escalada, `:4324` gate_pass, `:4375` close, `:4426` sessão): escritor novo nasce com ele.
Leitores não mudam (nenhum agrupa por ele; quem for ler usa `has("runner_sha")`). A série
(`sdd kaizen --series`) não carrega linhas cruas — medido sobre o ledger real: só agregados
(`latest.*`, `guard.*`, …) —, então o campo não aparece nela e o bloco `<!-- sdd:series-fields -->`
do I23 não precisa nomeá-lo.
**Onde:** `bin/sdd` — globais logo depois de `AUTONOMY_SHA_WARNED=0` (`:3149`); `autonomy_append`
(`:4154`, depois da guarda de linha vazia `:4166`, e o `printf` de `:4199`);
`tests/check-autonomy.sh` — regime 3 do kit-guard (`:5775-5786`); `tests/check-mutation.sh`;
`docs/pipeline.md` (tabela de campos, depois da linha `kit_rev_dirty`, `:1194`).
**Por que em top level e não em `main`/`cmd_run`:** bash executa a linha enquanto lê o arquivo,
antes de `main`; a forma `{ main "$@"; exit $?; }` (`:11126`) impede a releitura, então o valor é
o do código em execução. Junto dos globais `AUTONOMY_*` (e não logo depois de `SDD_HOME`, `:69`)
para não deslocar as âncoras do `TODO.md` em `:147`…`:1339`. Custo: um `git rev-parse` (~1,2 ms)
por invocação do `sdd`.
**Como (TDD):**
1. Probe primeiro, no regime 3 (a missão do PRÓPRIO kit cujo stub commita no kit — o mundo do
   #129). Uma linha ANTES do run, logo depois de `kitguard_stub "$FAKEKIT"`:
   ```bash
   # The kit HEAD this run is LAUNCHED from — read before the run, for the runner_sha probe below.
   KG3_LAUNCH="$(git -C "$FAKEKIT" rev-parse --short HEAD)"
   ```
   e, depois do `assert_eq "kit-guard: a mission whose own repo IS the kit is left alone …"`:
   ```bash
   # 3b. THE RUNNER THAT WROTE THE ROW (#129; the item "a session writes the ledger with the bin/sdd it
   #     had in MEMORY"). This is the kit's own mission, and its session commits into the kit: every
   #     row born after that commit reads kit_sha off the disk and names a version this process never
   #     ran — measured, 22 of 35 `sdd run` of the kit stamped more than one kit_sha. Each row carries
   #     runner_sha, the HEAD the process was launched from, beside it. Four terms, so no fixture
   #     regime satisfies it by accident: every row names the launch (runner), at least one row names
   #     the moved disk (moved — the witness that the kit really changed under the run, without which
   #     "runner == launch" is a constant), the rows say so where a human reads (journal: one RUNNER
   #     line, not one per row), and a row count floor (rows).
   KG3_RUNNERS="$(jq -r -s 'map(.runner_sha // "absent") | unique | join(",")' "$LEDGER" 2>/dev/null)"
   KG3_MOVED="$(jq -r -s --arg l "$KG3_LAUNCH" 'map(select(.kit_sha != null and .kit_sha != $l)) | length' "$LEDGER" 2>/dev/null)"
   assert_eq "ledger: every row carries the launch-time runner, beside a kit_sha read off the moved disk" \
     "runner:$KG3_LAUNCH moved:yes journal:1 rows:yes" \
     "runner:$KG3_RUNNERS moved:$([ "${KG3_MOVED:-0}" -ge 1 ] && echo yes || echo no) journal:$(grep -c '  RUNNER  ' <<< "$KG3_LOG") rows:$([ "$(nrows)" -ge 1 ] && echo yes || echo no)"
   ```
2. Vermelho pelo motivo certo (`fe9441d` + I11–I14 + probe, 90 s): o único FAIL novo,
   `expected: runner:3535dcf moved:yes journal:1 rows:yes` / `got: runner:absent moved:yes journal:0 rows:yes`
   — a testemunha `moved:yes` prova que o kit andou sob o run, e o campo não existe.
3. Conserto. Logo depois de `AUTONOMY_SHA_WARNED=0`:
   ```bash
   # One-shot per process: the first row whose kit_sha differs from AUTONOMY_RUNNER_SHA says so, once.
   AUTONOMY_RUNNER_NOTED=0
   # The kit HEAD this PROCESS was launched from (#129), taken once, at top level — bash runs this line
   # while it reads the file, before main — and `{ main "$@"; exit $?; }` keeps it from reading the
   # file again, so whatever a session commits into the kit later, this is the runner executing. Every
   # ledger row carries it as `runner_sha` beside the `kit_sha` autonomy_kit_stamp reads off the disk
   # (autonomy_append). Empty when the kit is not a git checkout.
   AUTONOMY_RUNNER_SHA="$( git -C "$SDD_HOME" rev-parse --short HEAD 2>/dev/null || true )"
   readonly AUTONOMY_RUNNER_SHA
   ```
   Em `autonomy_append`, logo depois da guarda `[ -n "${1:-}" ] || { warn "autonomy ledger row came out empty …"; return 0; }`:
   ```bash
     # `runner_sha` (#129) is added HERE, at the door every row goes through, and not in the four
     # builders: a writer added tomorrow is born carrying it. It is the HEAD the process was LAUNCHED
     # from, while `kit_sha` is read off the disk when the row is built — the two differ exactly when
     # the run's own commits moved the kit (22 of 35 `sdd run` of the kit, measured), and the first
     # such row says so on the terminal and in the journal, once. A jq failure keeps the row as built:
     # without the field it reads as "not measured" (`has("runner_sha")`), never as a wrong value.
     local row disk=""
     row="$( jq -c --arg r "$AUTONOMY_RUNNER_SHA" '. + {runner_sha: (if $r == "" then null else $r end)}' <<< "$1" 2>/dev/null )" || row=""
     [ -n "$row" ] || row="$1"
     disk="$( jq -r '.kit_sha // empty' <<< "$row" 2>/dev/null )" || disk=""
     if [ "$AUTONOMY_RUNNER_NOTED" = 0 ] && [ -n "$AUTONOMY_RUNNER_SHA" ] && [ -n "$disk" ] \
        && [ "$disk" != "$AUTONOMY_RUNNER_SHA" ]; then
       AUTONOMY_RUNNER_NOTED=1
       warn "the kit's HEAD moved under this run: launched from $AUTONOMY_RUNNER_SHA, now $disk — ledger rows carry both (runner_sha, kit_sha)"
       pipeline_log_line "$(date -Iseconds)  RUNNER  launched from kit $AUTONOMY_RUNNER_SHA, the kit's HEAD is now $disk — rows carry runner_sha"
     fi
   ```
   e o `printf '%s\n' "$1" 2>/dev/null >> "$file"` vira `printf '%s\n' "$row" 2>/dev/null >> "$file"`.
   (`pipeline_log_line` já é no-op sob `DRY_RUN` e com `PIPELINE_LOG` vazio; `autonomy_append` é
   chamada, nunca substituída, então o flag one-shot vale. Nada de `#` dentro do bloco `\`-continuado.)
4. `docs/pipeline.md`, linha nova na tabela de campos, logo depois da linha `kit_rev_dirty`
   (texto exato do protótipo):
   ```markdown
   | `runner_sha` | string \| `null` | absent on rows written before #129 | Short SHA of the kit's HEAD when the **process** that wrote the row was launched (`AUTONOMY_RUNNER_SHA`, taken once, at top level beside the other `AUTONOMY_*` globals, before `main` runs) — the runner actually executing, because `{ main "$@"; exit $?; }` keeps bash from reading the file again. `kit_sha` is read off the disk when the row is built, so in a run whose own commits move the kit (the kit's own missions: 22 of 35 `sdd run` of the kit stamped more than one `kit_sha`) it names a version the process never ran; `runner_sha` names the one it did. The first row of a run where the two differ also writes one `RUNNER` line in `pipeline.log` and warns once. Added at the ledger's one door (`autonomy_append`), so every writer carries it. `null` when `$SDD_HOME` is not a git checkout. A record, not an axis: no reader groups by it, and a reader that does tests `has("runner_sha")`. Launch-time dirt is not recorded (`kit_dirty` is the row's). |
   ```
5. Verde: `check-autonomy.sh` rc 0 (90 s).
**Sabotagens/mutantes:**
```bash
# runner_sha reads the DISK again (#129): the field says the HEAD the row was written at, which is
# kit_sha under another name — the run that moved the kit under itself is back to naming a version
# it never ran. Caught by `ledger: every row carries the launch-time runner, beside a kit_sha read off
# the moved disk` (kit-guard regime 3b of check-autonomy.sh), whose runner term then lists two shas.
mut_LEDGER_runner_sha_reads_disk() {
  sed -i '/^autonomy_append() {/,/^}/ s@--arg r "\$AUTONOMY_RUNNER_SHA"@--arg r "$(git -C "$SDD_HOME" rev-parse --short HEAD 2>/dev/null)"@' "$1"
}
# The kit moved under the run and the journal says nothing: the rows carry both shas, and the human
# watching `tail -F` is not told. Same assertion, its journal term.
mut_LEDGER_runner_moved_silent() {
  sed -i '/^autonomy_append() {/,/^}/ s@^    pipeline_log_line "\$(date -Iseconds)  RUNNER  @    : "$(date -Iseconds)  RUNNER  @' "$1"
}
```
(logo depois de `mut_LEDGER_progress_not_written`, `:4098`) + os dois slugs no `CATALOG=(` depois de
`LEDGER_progress_not_written` (`:5964`). Provados: `--only LEDGER_runner_sha_reads_disk
check-autonomy.sh` → `dies (rc 1)` (99,4 s); `--only LEDGER_runner_moved_silent check-autonomy.sh` →
`dies (rc 1)` (91,2 s). `check-autonomy.sh` inteiro sob `reads_disk` (sem `SDD_MUTANT`): o ÚNICO
FAIL é o 3b (`got: runner:733c7ac` ≠ launch `afb27fd`) — nenhuma outra asserção compara linhas
inteiras do ledger.
**Check:** `o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    ledger: every row carries the launch-time runner' <<< "$o"` → `1`   (antes, medido em fe9441d: `0`)
**Sensor durável:** asserção 3b em `check-autonomy.sh`; `mut_LEDGER_runner_sha_reads_disk`,
`mut_LEDGER_runner_moved_silent`; a linha `runner_sha` da tabela de `docs/pipeline.md`.
**Saída do item:** metade do item "Uma sessão escreve o ledger com o `bin/sdd` que tinha em
MEMÓRIA…" — `RESOLVED by <I15> <I16>` no I24 (o item tem as duas metades); catraca −1 no chore.
**Âncoras do TODO.md que o incremento desloca:** `bin/sdd` +9 depois de `:3149` e +16 depois de
`:4166` → `bin/sdd:4315` (o próprio #129) +25, `bin/sdd:9623` +25, `bin/sdd:10156` +25; nenhuma
antes de `:3149`. `tests/check-autonomy.sh:6493` (2º span do item "A regra da âncora…", citação)
+16; `docs/pipeline.md:1379` (citação) +1.
**Reversível por:** `git revert` (linhas já escritas com o campo ficam; o ledger é append-only e os
leitores ignoram o campo).

`| I15 | #129a: runner_sha em toda linha do ledger | `o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    ledger: every row carries the launch-time runner' <<< "$o"` → `1` | pending | — |`

### I16 — #129b: o config é relido no topo de cada volta

**O quê:** `cmd_run` relê `.sdd/config.sh` no topo de CADA volta do `while :` (`config_reload`).
Antes de re-sourçar, toda chave que `health_default_keys` enumera (45 hoje) volta ao que o AMBIENTE
dizia no lançamento — `unset` quando não dizia nada —, então uma chave apagada do arquivo volta ao
default e uma chave exportada (`BUDGET_MISSION_USD=0 sdd run …`, `ON_ESCALATION_CMD=… sdd run …`)
NÃO se perde na volta 2. Falha FECHADA: config que não carrega/valida é o `die` do `load_config`,
antes de a volta abrir sessão. Re-exec entre voltas: RECUSADO (o runner não revisado da missão
julgaria a própria REVIEW).
**Achado do desenho (não estava no brief):** `unset` puro das chaves de `health_default_keys`
apagaria toda chave vinda do ambiente — mudança de comportamento silenciosa na volta 2 (testes e
humanos passam chaves por prefixo de env). Medido: nenhuma chave de config é atribuída em top level
antes de `load_config` (grep dos 45 nomes como `^KEY=` → 0), então "setada antes do primeiro
`load_config`" = "veio do ambiente": `config_env_snapshot` guarda essas, e o reload as restaura. A
terceira metade do probe e o terceiro mutante medem isso.
**Onde:** `bin/sdd` — duas funções novas e dois globais logo ACIMA de `cmd_run() {` (`:7971`;
acima e não junto de `load_config`, `:141`, para não deslocar as âncoras do `TODO.md` em
`:147`…`:4315`); `cmd_run`: `config_env_snapshot` antes do `load_config` (`:7985`) e
`config_reload` como primeira linha do `while :; do` (`:8045`); `tests/check-autonomy.sh` (novo bloco
3c, depois do 3b do I15, antes de `# 4. THE INLINE RETRY`); `tests/check-mutation.sh`;
`config/schema.md` (depois de `:4`).
**Como (TDD):**
1. Probe primeiro, bloco 3c em `check-autonomy.sh` (usa `kitguard_world`/`kitguard_reset`/
   `KIT_SESSION_COUNT`/`STREAM_SAMPLE`, todos já definidos ali):
   ```bash
   # 3c. THE CONFIG IS RE-READ AT THE TOP OF EVERY LAP (#129; SQ-141: four EXEC sessions, US$ 5,93,
   #     against a TEST_CMD already fixed on disk — the run had sourced .sdd/config.sh once, before its
   #     loop). The first session closes I1 and, meanwhile, the human edits the config and commits it;
   #     nothing after that moves the disk, so the run ends on an escalation (rc 3) and the pager runs
   #     — AFTER a reload. Three properties, three terms: the next lap's gate runs
   #     the EDITED TEST_CMD (the gate right after the edit still runs the lap's own, `launch` — also
   #     the floor that the gate was reached at all); a key DELETED from the file goes back to its
   #     default instead of surviving from the last read (the file's ON_ESCALATION_CMD is gone, so its
   #     hook must not run); and a key the ENVIRONMENT supplied survives the reload (an exported
   #     ON_ESCALATION_CMD the file never sets still pages). Each command appends its own word to a file
   #     outside the repo, so the answer is what RAN, never what the config says.
   echo "== config: the run re-reads .sdd/config.sh at the top of every lap =="
   CFG_MARKS="$OUTSIDE/config-reload-marks"
   cfg_world() {   # cfg_world <dir> <extra config line or ""> — a target at EXEC, I1 pending
     kitguard_reset
     kitguard_world "$1" "$ROOT"
     sed -i "s|^TEST_CMD=.*|TEST_CMD='echo launch >> $CFG_MARKS'|" "$1/.sdd/config.sh"
     [ -z "$2" ] || printf '%s\n' "$2" >> "$1/.sdd/config.sh"
     git -C "$1" commit -qam "chore: the config the run is launched with"
     cat > "$OUTSIDE/stub/claude" <<STUB
   #!/usr/bin/env bash
   n=\$(( \$(cat "$KIT_SESSION_COUNT" 2>/dev/null || echo 0) + 1 ))
   printf '%s\n' "\$n" > "$KIT_SESSION_COUNT"
   if [ "\$n" -eq 1 ]; then
     sed -i -e "s|^TEST_CMD=.*|TEST_CMD='echo edited >> $CFG_MARKS'|" -e '/^ON_ESCALATION_CMD=/d' "$1/.sdd/config.sh"
     h=\$(git -C "$1" rev-parse --short HEAD)
     sed -i "/^| I1 /s/| pending | — |/| done | \$h |/" "$1/docs/handoffs/$MISSION/checkpoint.md"
     git -C "$1" add -A
     git -C "$1" commit -qm "feat: I1 — and the human edits the config meanwhile"
   fi
   cat "$STREAM_SAMPLE"
   exit 0
   STUB
     chmod +x "$OUTSIDE/stub/claude"
   }
   : > "$CFG_MARKS"
   cfg_world "$OUTSIDE/config-reload-file" "ON_ESCALATION_CMD='echo file-hook >> $CFG_MARKS'"
   ( cd "$OUTSIDE/config-reload-file" && "$SDD" run "$MISSION" >/dev/null 2>&1 ) || true
   CFG_FILE_MARKS="$(cat "$CFG_MARKS")"
   : > "$CFG_MARKS"
   cfg_world "$OUTSIDE/config-reload-env" ""
   ( cd "$OUTSIDE/config-reload-env" && ON_ESCALATION_CMD="echo env-hook >> $CFG_MARKS" "$SDD" run "$MISSION" >/dev/null 2>&1 ) || true
   CFG_ENV_MARKS="$(cat "$CFG_MARKS")"
   cfg_has() { if grep -qx "$2" <<< "$1"; then printf yes; else printf no; fi; }
   assert_eq "config: the next lap runs the edited TEST_CMD, drops a key deleted from the file, keeps one the environment set" \
     "launch:yes edited:yes deleted-hook:no env-hook:yes" \
     "launch:$(cfg_has "$CFG_FILE_MARKS" launch) edited:$(cfg_has "$CFG_FILE_MARKS" edited) deleted-hook:$(cfg_has "$CFG_FILE_MARKS" file-hook) env-hook:$(cfg_has "$CFG_ENV_MARKS" env-hook)"
   ```
   (Atenção ao heredoc `<<STUB` não citado: `\$` escapa o que o stub resolve na hora; `$1`,
   `$CFG_MARKS`, `$MISSION`, `$KIT_SESSION_COUNT`, `$STREAM_SAMPLE` expandem na escrita. A linha
   `#!/usr/bin/env bash` e o `STUB` de fecho ficam na coluna 0.) Por que funciona: `gate_EXEC` só
   roda `TEST_CMD` com zero `pending` (`bin/sdd:1346` em fe9441d, depois do `return 1` de `pending` em `:1344`); o gate logo
   após a sessão 1 roda o `launch`; a volta 2 deriva com o config relido; o memo de
   `run_check_cmd` (`:807`) é por STRING de comando, então o comando novo sempre roda.
2. Vermelho pelo motivo certo (`fe9441d` + I11–I15, só o probe, 90 s):
   `expected: launch:yes edited:yes deleted-hook:no env-hook:yes` /
   `got:      launch:yes edited:no deleted-hook:yes env-hook:yes` — a volta 2 rodou o `TEST_CMD` de
   lançamento e o hook apagado do arquivo ainda disparou; `env-hook:yes` mostra que hoje o ambiente
   já é honrado (o que o conserto não pode quebrar).
3. Conserto — acima de `cmd_run() {`:
   ```bash
   # The keys load_config defaults, and the subset the ENVIRONMENT supplied when the command started —
   # both taken once by config_env_snapshot, read by config_reload at the top of every lap (#129).
   CONFIG_RELOAD_KEYS=()
   declare -A CONFIG_ENV_VALUES=()

   # config_env_snapshot — CALLED, never substituted, before the first load_config of a command that
   # will reload. No config key is assigned before load_config, so a key that is set here was exported
   # by the caller (`BUDGET_MISSION_USD=0 sdd run …`); its value is kept for config_reload. The key list
   # is health_default_keys, the same reader `sdd health` checks the schema with — one definition of
   # "the keys load_config defaults". It reads bin/sdd on disk, which here is the launched file.
   config_env_snapshot() {
     local k
     mapfile -t CONFIG_RELOAD_KEYS < <(health_default_keys)
     for k in "${CONFIG_RELOAD_KEYS[@]}"; do
       if [ -n "${!k+x}" ]; then CONFIG_ENV_VALUES[$k]="${!k}"; fi
     done
     return 0
   }

   # config_reload — .sdd/config.sh re-read at the top of every lap of cmd_run (#129). It used to be
   # sourced once, before the loop: measured on SQ-141, four EXEC sessions (US$ 5,93) against a gate
   # whose TEST_CMD had already been fixed on disk. Every key load_config defaults goes back to what the
   # environment said at launch — unset when it said nothing — before the file is sourced again, so a
   # key deleted from the file does not survive from the last read, and one the caller exported is not
   # lost on lap two. It fails CLOSED, before the lap opens a session: a config that no longer parses,
   # evaluates or validates is load_config's own `die`, the sentence the human gets at launch.
   # Re-executing bin/sdd between laps was refused: the mission's own unreviewed runner would judge its
   # own REVIEW. ⚠️ DECLARED LIMITS: what cmd_run derived from the config BEFORE its loop keeps the
   # launch value (the mission branch off DEFAULT_BRANCH, MISSION_DIR off HANDOFF_DIR); an edit made
   # DURING a session reaches the gate of the NEXT lap, not the gate right after that session nor its
   # inline retry; `sdd retry`, `sdd close` and `sdd kaizen` read the config once, as before.
   config_reload() {
     local k
     for k in "${CONFIG_RELOAD_KEYS[@]}"; do
       if [ -n "${CONFIG_ENV_VALUES[$k]+x}" ]; then printf -v "$k" '%s' "${CONFIG_ENV_VALUES[$k]}"
       else unset "$k"; fi
     done
     load_config
   }

   ```
   No `cmd_run`: `config_env_snapshot` numa linha nova logo antes do `load_config` (`:7985`); e, como
   primeiras linhas do `while :; do` (`:8045`):
   ```bash
       # The config is re-read on every lap, before anything of the lap reads it (#129, config_reload).
       config_reload
   ```
   (O `return 0` final do snapshot importa: sem ele, o `[ -n … ]` falso da última chave vira o rc da
   função e o `set -e` derruba o `cmd_run`.)
4. `config/schema.md`, parágrafo novo depois de "Created by `sdd install` from …" (`:4`):
   "`sdd run` reads it again **at the top of every lap**, before the lap derives its phase: a value
   fixed on disk mid-run (a `TEST_CMD` that was wrong) is the one the next lap's gate runs, a key
   deleted from the file goes back to its default, and a key exported in the environment of the
   `sdd run` keeps that value. A file that no longer loads stops the run before the lap opens a
   session, with the message it would give at launch. An edit made during a session reaches the gate
   of the **next** lap, not the gate right after that session; what the run derived before its first
   lap (the mission branch, the mission directory) keeps the launch value; `sdd retry`, `sdd close`
   and `sdd kaizen` read the file once." (`check-lang.sh` verde com ele; `check-health.sh` verde.)
5. Verde: `check-autonomy.sh` rc 0.
**Efeito colateral a declarar no PR:** `load_config` roda hoje ANTES de `ensure_mission_branch`
(`bin/sdd:7985` × `:8005`); com o reload, a volta 1 lê o config da branch da MISSÃO (depois do
checkout), não o da branch em que o humano estava. É o config onde os gates rodam — mais certo —,
mas é mudança: um config quebrado só na branch da missão agora para o run na volta 1.
**Sabotagens/mutantes:** um por propriedade:
```bash
# The config is read once again, before the loop (#129): a TEST_CMD fixed on disk mid-run is never
# the one the next lap's gate runs, which is SQ-141's four EXEC sessions. Caught by `config: the next
# lap runs the edited TEST_CMD, …` (block 3c of the kit-guard regimes in check-autonomy.sh).
mut_RUN_config_not_reloaded() {
  sed -i '/^cmd_run() {/,/^}/ s@^    config_reload$@    :@' "$1"
}
# The reload forgets to unset: a key deleted from the file survives from the previous read. Same
# assertion, its `deleted-hook` term — the file's ON_ESCALATION_CMD pages after it was deleted.
mut_RUN_config_reload_keeps_deleted() {
  sed -i '/^config_reload() {/,/^}/ s@^    else unset "\$k"; fi$@    fi@' "$1"
}
# The reload forgets the environment: a key the caller exported is unset on lap two. Same assertion,
# its `env-hook` term — the exported ON_ESCALATION_CMD no longer pages.
mut_RUN_config_reload_drops_env() {
  sed -i '/^config_reload() {/,/^}/ s@if \[ -n "\${CONFIG_ENV_VALUES\[\$k\]+x}" \]; then@if false; then@' "$1"
}
```
+ os três slugs no `CATALOG=(`. Provados (`--only <slug> check-autonomy.sh`): `RUN_config_not_reloaded`
`dies (rc 1)` 89,7 s; `RUN_config_reload_keeps_deleted` `dies (rc 1)` 91,7 s;
`RUN_config_reload_drops_env` `dies (rc 1)` 90,3 s. Depois da mudança de colocação (funções movidas
para cima de `cmd_run`), `--anchors` → `all 602 mutants still apply` — as âncoras são por nome de
função, não por posição. Não provado: que o `die` de um config quebrado no meio do run é o mesmo
`die` do lançamento (é o mesmo código, chamado de novo; não há probe de config que quebra na volta 2).
**Check:** `o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    config: the next lap runs the edited TEST_CMD' <<< "$o"` → `1`   (antes, medido em fe9441d: `0`)
**Sensor durável:** bloco 3c de `check-autonomy.sh`; os três mutantes `RUN_config_*`; o parágrafo
do `config/schema.md`.
**Saída do item:** segunda metade do item #129 — `RESOLVED by <I15> <I16>` no I24; catraca −1 no
chore (o item é um só).
**Âncoras do TODO.md que o incremento desloca:** `bin/sdd` +40 antes de `cmd_run` e +3 dentro dele →
`bin/sdd:9623` +43 e `bin/sdd:10156` +43; nada antes de `:7971`. `tests/check-autonomy.sh:6493`
(citação) +48. Rode `remap.py <rev do I15>` e `xref.py HEAD --fix`.
**Reversível por:** `git revert` do commit.

`| I16 | #129b: o config relido no topo de cada volta | `o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    config: the next lap runs the edited TEST_CMD' <<< "$o"` → `1` | pending | — |`

### I17 — os dois leitores aprendem o evento `manual` (#153)

**O quê:** o `cmd_autonomy` e o `kaizen_series` ganham, cada um, UMA definição `def is_manual: .event == "manual";`
ao lado do `is_close`. No `cmd_autonomy`: `is_unrecognized` passa a `(is_session or is_escalation or is_gate_pass or is_close or is_manual) | not`;
um **oitavo balde** `| (map(select(is_manual)) | length) as $manuals` logo abaixo do `$closes`; e uma linha no parágrafo `$inside`,
**antes** da linha do `$stray`:
`, (if $manuals > 0 then "  (\($manuals) phase(s) recorded as done by hand: \`sdd note-manual\` wrote the row — a manual phase grades nothing)" else empty end)`;
a frase do `$stray` passa a terminar em `session/blocked/degraded/gate_pass/close/manual)`. No `kaizen_series`: a admissão do `$all`
passa a `(.event == "session" or is_escalation or is_gate_pass or is_close or is_manual)`. Nenhum outro predicado muda.
⚠️ Os dois programas jq são strings de shell entre aspas simples: **nenhum apóstrofo** nos comentários novos (`bash -n` acusa, longe da linha).
`docs/pipeline.md` § "Field reference", no mesmo commit (contrato de artefato): "There are **four row shapes**" → cinco, com a frase da
`manual` (mesma forma da gate closure, escrita por `sdd note-manual`, não gradua nada); a linha `event` do enum ganha `\| manual`;
"over **seven** buckets" → **eight**, com "**phase done by hand**" na lista; nas colunas "Absent when" que nomeiam `event:"gate_pass"`
(`turns` :1211, `session_error` :1216, `gate_why` :1225 e `kind` :1188) acrescentar `event:"manual"`. Os comentários de `bin/sdd`
que contam baldes ("ALL SEVEN terms", `cmd_autonomy`) passam a oito. `tests/check-autonomy.sh`: o cabeçalho de `assert_bucket_sum`
("SEVEN buckets") passa a oito.

**Onde:** `bin/sdd` — `cmd_autonomy` (`def is_close` :9174, `def is_unrecognized` :9175, `as $closes` :9358, linha do `$stray` :9547);
`kaizen_series` (`def is_close` :9691, admissão `as $all` :10023); `tests/check-autonomy.sh` (`assert_bucket_sum` :100, bloco do
`closerow` termina em :3508); `tests/check-kaizen.sh` (bloco do close :2372–2436, `echo "== hygiene =="` :2438);
`tests/check-mutation.sh` (`mut_LEDGER_gate_pass_unrecognized` :4698, `mut_LEDGER_gate_pass_not_admitted` :4765,
`mut_KAIZEN_close_not_admitted` :4782, `CATALOG=(` :5491); `docs/pipeline.md` (:1164, :1187, :1188, :1211, :1216, :1225, :1233).

**Como (TDD):** primeiro os probes, com o runner de `fe9441d`:
1. `check-autonomy.sh`, logo depois de `assert_bucket_sum "… (a close row)" "$out_close"`: bloco
   `== reader: a phase done by hand lands in a bucket of its own ==` com dois ledgers por `localize` — `manualoff` (uma sessão
   EXEC de `m22`, kit `mmm1111`, US$ 1.0) e `manualon` (a mesma + a linha
   `{"v":1,"ts":"2026-09-12T10:05:00-03:00","event":"manual","run_id":"m2","invocation":"note-manual","kit_sha":"mmm1111","kit_dirty":false,"kit_rev":null,"kit_rev_dirty":null,"project":"p1","repo":"/p1","mission":"m22","phase":"PR"}`).
   Quatro asserções: piso `"the fixture really does put a manual row in the header total"` = `1 2`;
   `"the human reader names the manual row and never calls it unrecognized"` = `1 0` (`num_before … 'phase\(s\) recorded as done by hand'` e `grep -c unrecognized`);
   **diferencial** `"a manual row moves no graded number: each page with it is the page without it"` — as duas visões (`autonomy` e
   `autonomy --by-mission`), comparando `grep -v -e 'row(s)'` da página sem a linha com `grep -v -e 'row(s)' -e 'recorded as done by hand'`
   da página com ela (a substituição de comando come a linha em branco que o parágrafo abre — medido);
   e `assert_bucket_sum "the buckets still sum to the header total (a manual row)" "$out_mon"`. `assert_bucket_sum` ganha o termo
   `manuals="$(num_before "$out" 'phase\(s\) recorded as done by hand')"; manuals="${manuals:-0}"` e o soma.
2. `check-kaizen.sh`, antes de `echo "== hygiene =="`: bloco `== series: a manual row is recognized and mints nothing ==`, cópia
   do bloco do close (mesmo `close_base`, mesmos regimes): `manual_row() { printf '{"v":1,…,"event":"manual","run_id":"c4","invocation":"note-manual","kit_sha":"%s",…,"mission":"%s","phase":"%s"}\n' "$1" "$2" "$3"; }`;
   regime `manualin` = `close_base` + `manual_row ccc0001 m61 PR` + `manual_row ccc0001 m60 REVIEW` (a segunda divide a célula
   `(m60, REVIEW)` com uma sessão — onde um `phase_label` que aprendesse o evento mexeria); `manualaway` = `close_base` +
   `manual_row ccc0002 m61 PR`. Três asserções: `"guard: a manual row mints no version, no mission and no cell"` (a série inteira dos
   dois regimes igual à `CLOSEOFF_OUT` duas vezes), o piso `"floor: that manual differential is not vacuous — one version, one mission, two cells"` = `ccc0001 1 2 6`,
   e `"guard: a manual row is recognized, never counted as unrecognized"` = `0 0 0 0`.
   ⚠️ **Medido:** comparar com `jq -S .` reprova um runner correto — a linha em `(m60, REVIEW)` entra no grupo e o `cost_usd`
   ausente soma 0, e o jq imprime `4` onde a entrada dizia `4.0`. A comparação é por valor:
   `numeric() { jq -S 'walk(if type == "number" then . + 0 else . end)' <<< "$1"; }` dos dois lados.

Vermelho medido (testes novos + `bin/sdd` de `fe9441d`): check-autonomy `FAIL the human reader names the manual row and never calls it unrecognized — expected: 1 0 — got:  1`
(a linha cai no `$stray`); check-kaizen `FAIL guard: a manual row mints no version…` e `FAIL guard: a manual row is recognized… — expected: 0 0 0 0 — got: 2 0 1 0`.
O diferencial do check-autonomy e o `assert_bucket_sum` **passam** no vermelho (a linha `unrecognized` também tem `row(s)` e o balde
`$stray` fecha a soma) — por isso o Check lê a asserção nominal, não o diferencial. Verde no protótipo: check-autonomy 470 ok / 0 FAIL,
check-kaizen 217 ok / 0 FAIL (no commit sequencial I17: rc 0 nos dois).

**Sabotagens/mutantes:** 4 novos (perto de `mut_KAIZEN_close_not_admitted`, `CATALOG` junto):
- `mut_AUTONOMY_manual_unrecognized() { sed -i 's@ or is_close or is_manual) | not;@ or is_close) | not;@' "$1"; }` → `--only … check-autonomy.sh`: `ok AUTONOMY_manual_unrecognized — check-autonomy.sh dies (rc 1)`, 100 s (morre em "names the manual row" e no `assert_bucket_sum`, que conta a linha duas vezes);
- `mut_KAIZEN_manual_not_admitted() { sed -i 's@or is_gate_pass or is_close or is_manual)))) as \$all@or is_gate_pass or is_close)))) as $all@' "$1"; }` → check-kaizen dies, 30 s (diferencial + "recognized");
- `mut_KAIZEN_manual_mints_version() { sed -i 's@def shas_in_file_order: map(select(.event == "session" or is_escalation))@def shas_in_file_order: map(select(.event == "session" or is_escalation or is_manual))@' "$1"; }` → check-kaizen dies, 30 s (regime `manualaway`);
- `mut_KAIZEN_manual_counts_mission() { sed -i 's@def graded_row: .event == "session" or is_escalation;@def graded_row: .event == "session" or is_escalation or is_manual;@' "$1"; }` → check-kaizen dies, 30 s (regime `manualin`: diferencial + piso).

**3 re-ancorados** (o texto que eles casam ganha ` or is_manual`; a intenção de cada um fica):
`mut_LEDGER_gate_pass_unrecognized` → padrão `def is_unrecognized: (is_session or is_escalation or is_gate_pass or is_close or is_manual) | not;` (alvo inalterado `(is_session or is_escalation) | not;`);
`mut_LEDGER_gate_pass_not_admitted` → padrão `and (.event == "session" or is_escalation or is_gate_pass or is_close or is_manual)` (alvo inalterado);
`mut_KAIZEN_close_not_admitted` → padrão idem, alvo `and (.event == "session" or is_escalation or is_gate_pass or is_manual)` (tira só o `is_close`).
Os três provados com `--only`: `LEDGER_gate_pass_unrecognized — check-autonomy.sh dies`, `LEDGER_gate_pass_not_admitted — check-kaizen.sh dies`,
`KAIZEN_close_not_admitted — check-kaizen.sh dies`. `--anchors` no commit I17: `all 597 mutants still apply`.

**Check:** `o=$(env -u CLAUDECODE TMPDIR=/tmp bash tests/check-kaizen.sh 2>&1; env -u CLAUDECODE TMPDIR=/tmp bash tests/check-autonomy.sh 2>&1); grep -c -e '^  ok    guard: a manual row mints no version' -e '^  ok    the human reader names the manual row' <<< "$o"` → `2`   (antes, medido em fe9441d: `0`; no topo do protótipo: `2`)

**Sensor durável:** o diferencial de série em `check-kaizen.sh` (2 regimes) + a asserção nominal e o diferencial de página em
`check-autonomy.sh` + o oitavo termo do `assert_bucket_sum` + 4 mutantes.

**Saída do item:** o item #153 sai no I24 com ` RESOLVED by <hash do I18>` (o writer é o que fecha a lacuna; I17 é pré-requisito).
Catraca: nenhum efeito no incremento (sai no chore pós-merge).

**Âncoras do TODO.md que o incremento desloca:** nenhuma (medido: `check-todo.sh --check TODO.md` → `23 finding(s) … every anchor on target` no commit I17 sobre `fe9441d`).

**Reversível por:** `git revert` do commit (nenhuma linha `manual` existe ainda em ledger real; o writer nasce no I18).

| I17 | os dois leitores aprendem o evento `manual` | `o=$(env -u CLAUDECODE TMPDIR=/tmp bash tests/check-kaizen.sh 2>&1; env -u CLAUDECODE TMPDIR=/tmp bash tests/check-autonomy.sh 2>&1); grep -c -e '^  ok    guard: a manual row mints no version' -e '^  ok    the human reader names the manual row' <<< "$o"` → `2` | pending | — |

### I18 — `sdd note-manual` escreve a nota e a linha `manual` (#153)

**O quê:**
1. **Construtor único das duas linhas-fato sem sessão.** `autonomy_gate_pass_row` vira
   `autonomy_gate_pass_row() { autonomy_phase_fact_row "gate_pass" "$1"; }`, nasce
   `autonomy_manual_row() { autonomy_phase_fact_row "manual" "$1"; }`, e o corpo atual vira `autonomy_phase_fact_row <event> <phase>`
   com duas mudanças: `--arg ts "$(date -Iseconds)" --arg event "$1" --arg phase "$2"` e `'{v: 1, ts: $ts, event: $event,` (o resto
   igual — mesmos 13 campos). Nenhum mutante ancora dentro desse corpo (conferido: `grep -n 'gate_pass_row\|event: "gate_pass"' tests/check-mutation.sh`
   só acha `mut_RUN_gate_pass_*`, ancorados nos chamadores).
2. **O comando**, definido logo **antes** do comentário `# Post-merge: closes the JIRA issue` (fora da região do `sdd health`):
```bash
cmd_note_manual() {
  [ $# -eq 2 ] || die "usage: sdd note-manual <mission> <PHASE>"
  load_config
  resolve_mission "$1"
  local phase="$2" p known=0
  for p in $PHASES; do [ "$p" = PLAN ] || [ "$p" != "$phase" ] || known=1; done
  [ "$known" = 1 ] || die "note-manual: '$phase' is not a phase a session runs — one of: ${PHASES#PLAN }"
  AUTONOMY_RUN_ID="$(uuidgen)"
  AUTONOMY_INVOCATION="note-manual"
  ensure_mission_branch
  checkpoint_note_intervention "sdd note-manual (the phase was recorded from the CLI as done by hand)" "$phase"
  autonomy_manual_row "$phase"
  ok "phase $phase of $MISSION recorded as done by hand: the note in the checkpoint, a manual row in the ledger"
}
```
   Não roda gate (nem `TEST_CMD`) e não afirma veredito; a nota diz o que o runner sabe ("recorded from the CLI"), nunca quem digitou.
   `ensure_mission_branch` antes de escrever, como `cmd_approve` e `cmd_retry` (a nota commita na branch da missão).
3. **Despachante** (`main`): `note-manual) cmd_note_manual "$@" ;;` depois do `close)`.
4. **Admissão** (`coordination_enter`): `boot|note-manual|install|preflight|health|approve|phase|why|link-agents) : ;;` — ⚠️ o nome entra
   **logo depois de `boot|`**, não no fim: `mut_COORD_linker_unlocked` casa o texto `install|preflight|health|approve|phase|why|link-agents)`,
   e `…link-agents|note-manual)` quebraria a âncora dele. Fora do braço, o comando cairia no `*)` e seria admitido **sem lock** (comita sob um `sdd run`).
5. **`cmd_help`**: depois de `sdd close <mission> …`, duas linhas: `sdd note-manual <mission> <PHASE>` / `record a phase done BY HAND: an intervention note in the checkpoint (committed alone) and a \`manual\` row in the ledger, which grades nothing`.
6. **Prosa no mesmo commit:** `docs/pipeline.md` :27 (lista de comandos com lock) ganha `note-manual`; a linha `invocation` (:1190) ganha
   `note-manual` ("four values for five writers"); `README.md` (bloco de comandos, depois de `sdd close` :82) ganha a linha do comando;
   `CONTEXT.md` ganha o verbete **"Fase feita à mão gravada (`manual`)"** depois do `close` (:20) — a sexta forma de linha, o comando, os
   campos da tabela acima, "não gradua nada", o porquê (#153, 20260916-destino-frete-cif) — e o verbete "Ledger de autonomia" (:11)
   passa de "quatro formas de linha" à contagem atual; `templates/checkpoint-notas.md` :38 ("fase feita à mão") passa a mandar usar
   `sdd note-manual <missão> <FASE>`, que escreve a nota e a linha do ledger; `.claude/rules/anatomia-do-agente.md` §7 "Onde mora hoje"
   (:232, a lista das portas em que o runner escreve a `- intervention:`) ganha `note-manual` — a rule manda atualizar o componente no
   mesmo commit (componente 7, hooks humanos).

**Onde:** `bin/sdd` — `autonomy_gate_pass_row` (:4321, jq :4334–4341), `checkpoint_note_intervention` (:468, só chamado),
`cmd_help` (`sdd close` :10539), `coordination_enter` (braço :10704), `main` (`close)` :10779), comentário de `cmd_close` (:10840);
`tests/check-autonomy.sh` (depois de `assert_eq "sdd run --phase --dry-run writes none…"` :575–576 e do `: > "$LEDGER"` seguinte);
`tests/check-coordination.sh` (lista do `busy` :663–668); `tests/check-mutation.sh`; `docs/pipeline.md`, `README.md`, `CONTEXT.md`,
`templates/checkpoint-notas.md`, `.claude/rules/anatomia-do-agente.md`.

**Como (TDD):** primeiro os probes:
1. `check-autonomy.sh`, bloco `== sdd note-manual records a phase done by hand ==` depois do bloco do `--phase` (usa `notes`, `ck_clean`,
   `nrows`, `rows` que já existem lá; a missão do fixture está em `branch: main`, sem `checkpoint-notas.md` nesse ponto):
   `"sdd note-manual writes one note committed alone and one manual row for the phase"` = `rc:0 notes:+1 clean rows:1 manual:PR`;
   `"the manual note names the command, the phase and the date, in the form the template shows"` = `1` (regex
   `^- intervention: sdd note-manual .* — PR — [0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2} · written by the runner$` no `checkpoint.md`);
   `"the manual row carries the mission, its own run and the kit stamp, and no session field"` = `$MISSION note-manual true true false`
   (`has("rc") or has("cost_usd") or has("moved") or has("kind") or has("gate_why")` é o último termo);
   `"note-manual refuses PLAN and an unknown phase and writes nothing"` = `1 1 rows:1 notes:+1` (`PLAN` e `PUBLISH`); termina com `: > "$LEDGER"`.
2. `check-coordination.sh`: `("note-manual", "20260101-one", "PR"),` na lista do `busy`.

Vermelho medido (testes novos + runner de `fe9441d`): `FAIL sdd note-manual writes one note… expected: rc:0 notes:+1 clean rows:1 manual:PR — got: rc:1 notes:+0 clean rows:0 manual:`,
mais os três seguintes; check-coordination `FAIL busy: note-manual 20260101-one PR: rc=1 error: unknown command: note-manual`.
Verde: no commit sequencial I18, check-autonomy rc 0 (88 s), check-coordination rc 0 (30 s); manual numa fixture de rascunho:
commit `chore(checkpoint): intervention — sdd note-manual (…) — PR`, árvore limpa, e a linha
`{"v":1,…,"event":"manual","run_id":"8710a901-…","invocation":"note-manual","kit_sha":…,"kit_rev":…,"project":"fixture","repo":"…","mission":"20260101-fixture","phase":"PR"}`;
`PLAN`/`FOO`/sem fase → rc 1 sem escrever.

**Sabotagens/mutantes:** 2 novos —
`mut_RUN_manual_row_missing() { sed -i '/^cmd_note_manual() {/,/^}/ s@^  autonomy_manual_row "\$phase"$@  :@' "$1"; }` →
`ok RUN_manual_row_missing — check-autonomy.sh dies (rc 1)`, 100 s (morre em "writes one note … one manual row", "carries the mission", "refuses PLAN");
`mut_COORD_note_manual_unlocked() { sed -i 's@    boot|note-manual|install|@    boot|install|@' "$1"; }` →
`ok COORD_note_manual_unlocked — check-coordination.sh dies (rc 1)`, 40 s (morre em `busy: note-manual` **e** em `refusal has no effects` — sem lock o comando escreveu a nota no repo de teste).

**Check:** `o=$(env -u CLAUDECODE TMPDIR=/tmp bash tests/check-autonomy.sh 2>&1; env -u CLAUDECODE TMPDIR=/tmp bash tests/check-coordination.sh 2>&1); grep -c -e '^  ok    sdd note-manual writes one note committed alone' -e '^  ok    busy: note-manual' <<< "$o"` → `2`   (antes, medido em fe9441d: `0`; no topo: `2`)

**Sensor durável:** o grupo de 4 asserções do writer em `check-autonomy.sh`, o `busy` em `check-coordination.sh`, 2 mutantes.

**Saída do item:** #153 recebe ` RESOLVED by <hash deste commit>` no I24 (é o commit que fecha a lacuna medida); sai da seção aberta no
chore pós-merge, com a catraca `todo-findings` descendo 1.

**Âncoras do TODO.md que o incremento desloca:** medido aplicando sobre o I17: `bin/sdd:9623` (TODO.md linha 74, `kaizen_series`) fica
fora do alvo (`nearest kaizen_series is at line 9644`). `remap.py <rev do I17>` + `xref.py HEAD --fix` re-ancoram.

**Reversível por:** `git revert` do commit; linhas `manual` já escritas no ledger real continuam reconhecidas (os leitores do I17 ficam).

| I18 | `sdd note-manual` escreve a nota e a linha `manual` | `o=$(env -u CLAUDECODE TMPDIR=/tmp bash tests/check-autonomy.sh 2>&1; env -u CLAUDECODE TMPDIR=/tmp bash tests/check-coordination.sh 2>&1); grep -c -e '^  ok    sdd note-manual writes one note committed alone' -e '^  ok    busy: note-manual' <<< "$o"` → `2` | pending | — |

### I19 — o `sdd status` sugere o `note-manual` (#153)

**O quê:** a página completa do `sdd status` lista, depois dos incrementos, as fases **verdes** que o ledger desta máquina não tem
nenhuma linha `session` nem `manual` desta missão, cada uma com o comando que a registra. Função nova `status_unrecorded`, definida
**abaixo** de `status_increments` (⚠️ abaixo do `cmd_status`: `tests/check-health.sh` fecha a região do `sdd health` no texto
`cmd_status() {`, e uma função acima dele arrasta captura para a região e mexe numa catraca):
```bash
status_unrecorded() {
  local file seen ph out=""
  autonomy_have_jq || return 0
  file="$(autonomy_log_path)"
  [ -f "$file" ] || return 0
  seen="$(jq -rR --arg repo "$(ledger_repo_root)" --arg m "$MISSION" \
            'fromjson? | select(type == "object" and .repo == $repo and .mission == $m
                                and (.event == "session" or .event == "manual")) | .phase // empty' \
            "$file" 2>/dev/null)" || seen=""
  for ph in "$@"; do
    [ "$ph" != PLAN ] || continue
    [ "$ph" != TICKET ] || [ "$JIRA_ENABLED" = "true" ] || continue
    grep -qxF "$ph" <<< "$seen" && continue
    out+="$(printf '    %-7s %ssdd note-manual %s %s%s' "$ph" "$C_DIM" "$MISSION" "$ph" "$C_RESET")"$'\n'
  done
  [ -n "$out" ] || return 0
  info ""
  info "  green with no session and no manual row in this machine's ledger — done by hand?"
  printf '%s' "$out"
}
```
No `cmd_status` (ramo completo): `local -a green=()`; no laço, `if "gate_$ph"; then state=…; green+=("$ph"); else …`; e depois de
`status_increments`: `status_unrecorded ${green[@]+"${green[@]}"}`. O ramo `--no-gates` **não** ganha a dica.

**Desvio declarado (o humano aceitou "o sdd status sugere"):** o enunciado diz "quando uma fase tem **handoff**"; o protótipo usa
"quando o **gate** da fase está verde". Três razões medidas: (a) o kit não tem tabela fase → handoff (PR é `50-pr.md`, REVIEW é
`40-review-r*.md`, TICKET pode não ter arquivo) e criar uma seria uma segunda definição do que é "fase feita"; o gate é a definição do
kit; (b) a página completa **já** avaliou todo gate, então o custo extra é uma passada de `jq` — **9 ms** sobre o ledger real
(`~/.sdd/autonomy-log.jsonl`, 608 linhas, 421 KB, medido com `time jq … | sort -u`); (c) o `--no-gates` promete "no gate was evaluated
— this is the disk, not a verdict" e não sabe qual fase está feita, então dica ali seria veredito na página que jura não dar um.
Exclusões: PLAN (é do humano por desenho, nunca tem sessão) e TICKET com `JIRA_ENABLED != true` (o gate pula a fase — sem a exclusão
todo alvo sem Jira, inclusive o kit, receberia a dica para sempre). `fromjson?` para uma linha malformada custar só ela.
**Limite declarado:** o ledger é por máquina — missão rodada em outra máquina aparece aqui como "feita à mão?" (a frase diz "this
machine's ledger"); e a frase é pergunta, não acusação.

**Onde:** `bin/sdd` — `cmd_status` (:6636; laço dos gates :6681–6686, `status_increments` :6689), `status_increments` (:6711);
`tests/check-gates.sh` (bloco `== sdd status --no-gates ==` :5364, depois de `assert_eq "a misspelt status option is refused…"` :5417–5418).

**Como (TDD):** o probe usa o mundo que o `check-gates.sh` já tem em :5391 (`FULL_OUT`): medido, nesse ponto PLAN, TICKET (pulada),
EXEC, QA, REVIEW e DOCS estão verdes, PR vermelho, e o ledger da fixture tem sessões de EXEC e REVIEW desta missão e nenhuma de QA/DOCS.
Bloco novo depois da asserção do `--no-gate`:
`hint_of() { grep -c "sdd note-manual $MISSION $2\$" <<< "$1"; }`; `unrec_repo` copiado de uma linha de sessão do próprio ledger
(`jq -rn --arg m "$MISSION" 'first(inputs | select(.event == "session" and .mission == $m) | .repo)'` — sem `| head`);
`"the full page names the green phases with no session of the mission, and no other"` = `QA:1 DOCS:1 EXEC:0 REVIEW:0 PLAN:0 TICKET:0 PR:0 no-gates:0`;
depois o **diferencial**: backup do ledger, `jq -cn` acrescenta uma linha `manual` de QA (forma do `autonomy_manual_row`, `repo` = `unrec_repo`),
`UNREC_OUT="$( "$SDD" status "$MISSION" 2>&1 )"`, restaura o ledger, e
`"a manual row of the phase takes it off the page, and only it"` = `repo:1 QA:1>0 DOCS:1>1`.
Vermelho medido (testes novos + runner de `fe9441d`): `got: QA:0 DOCS:0 …` e `got: repo:1 QA:0>0 DOCS:0>0`. Verde: check-gates 393 ok / 0 FAIL;
a página real (capturada do fixture):
```
  increments:
    ✓ I1   slice one                                      98fcd92

  green with no session and no manual row in this machine's ledger — done by hand?
    QA      sdd note-manual 20260101-fixture QA
    DOCS    sdd note-manual 20260101-fixture DOCS
```
As asserções existentes do `--no-gates` (`calls:0`/`calls:1` do `TEST_CMD`) seguem verdes: a dica não roda gate.

**Sabotagens/mutantes:** 1 novo —
`mut_STATUS_manual_row_ignored() { sed -i '/^status_unrecorded() {/,/^}/ s@and (.event == "session" or .event == "manual"))@and (.event == "session"))@' "$1"; }` →
`ok STATUS_manual_row_ignored — check-gates.sh dies (rc 1)`, 100 s (morre só em "a manual row of the phase takes it off the page").
A metade "presença" (dica some inteira) é a de `fe9441d`, medida vermelha acima.

**Check:** `o=$(env -u CLAUDECODE TMPDIR=/tmp bash tests/check-gates.sh 2>&1); grep -c -e '^  ok    the full page names the green phases with no session' -e '^  ok    a manual row of the phase takes it off the page' <<< "$o"` → `2`   (antes, medido em fe9441d: `0`; no topo: `2`)

**Sensor durável:** as duas asserções do `check-gates.sh` (presença por fase, com os cinco "não" nomeados, e o diferencial com/sem a linha) + 1 mutante.

**Saída do item:** coberto pelo `RESOLVED by` do I18 (a dica é a parte "o status sugere" da mesma decisão); nenhum efeito próprio na catraca.

**Âncoras do TODO.md que o incremento desloca:** medido sobre o I18: `bin/sdd:10156` (TODO.md linha 117) fica fora do alvo
(`nearest $SDD_HOME is at line 10185`); `bin/sdd:9623` continua deslocada se o I18 não a re-ancorou. `remap.py` + `xref.py --fix`.

**Reversível por:** `git revert` do commit.

| I19 | o `sdd status` sugere o `note-manual` | `o=$(env -u CLAUDECODE TMPDIR=/tmp bash tests/check-gates.sh 2>&1); grep -c -e '^  ok    the full page names the green phases with no session' -e '^  ok    a manual row of the phase takes it off the page' <<< "$o"` → `2` | pending | — |

### I20 — o relatório na ponta da base pergunta quem o adicionou (#179)

**O quê:** uma função nova logo depois de `path_in_commits`, e **uma** linha no laço final do `mission_qa_report`:
```bash
tip_add_carries_mission() {
  local path="$1" c add
  shift
  for c in "$@"; do
    git -C "$REPO_ROOT" cat-file -e "$c:$path" 2>/dev/null || continue
    add=""
    IFS= read -r -d '' add < <(git -C "$REPO_ROOT" rev-list --topo-order "$c" -- "$path" 2>/dev/null \
        | git -C "$REPO_ROOT" diff-tree --stdin --root -r -z --diff-filter=A --name-only -- "$path" 2>/dev/null) || true
    [ -n "$add" ] || return 1
    [ -n "$(git -C "$REPO_ROOT" diff-tree --root --no-commit-id -r --name-only "$add" -- "$HANDOFF_DIR/$MISSION/" 2>/dev/null)" ] || return 1
  done
  return 0
}
```
e, no `for p in ${owned[@]+…}` do fim do `mission_qa_report`, depois do `[ "$REPO_ROOT/$p" -ef "$dir/${p##*/}" ] || continue`:
`    tip_add_carries_mission "$p" "${nots[@]}" || continue` (`nots` nunca é vazio ali: `bases` só é não-vazio quando `nots` é).
Um só ponto de corte cobre os dois braços (commits e árvore — o `checkout main -- f` só **staged** também é recusado) e não toca
nenhum texto que os 27 mutantes `mut_QA_report_*` casam (`grep -c "^mut_QA_report_" tests/check-mutation.sh` → 27). Semântica: o caminho já precisa ser novo para todo merge-base (inalterado);
**se** uma ponta das refs da base (`mission_base_refs`: base local, upstream, `origin/<base>`) também o tem, o commit mais novo daquela
ponta que o **adicionou** (plumbing: `rev-list --topo-order | diff-tree --stdin -z --diff-filter=A`; `--root` para um add no commit raiz;
plumbing porque o `log.showSignature` alcança o porcelana — o mundo (h) assinado do check-gates já paga isso) tem de tocar
`$HANDOFF_DIR/$MISSION/`. Squash da própria missão → toca (o checkpoint muda a cada incremento) → conta. Relatório de outra missão
trazido da ponta → o commit carrega o diretório de outra missão ou nenhum → não conta. Determinístico, sem relógio. Custo: um
`cat-file -e` por ref da base por relatório candidato; `rev-list`+`diff-tree` só quando o caminho está numa ponta.
Pathspec medido: `docs/handoffs/M/`, `docs/handoffs//M/`, `./docs/handoffs/M/` e `./docs/handoffs//M/` respondem igual (o git normaliza;
`HANDOFF_DIR` com barra final, que o check-gates :4142 exercita, não muda nada).
O comentário do `mission_qa_report` (:950–953, "And the check is against the MERGE-BASE tree, not the base's tip … Checking the tip
too would refuse a squash-merged mission its own report") é reescrito para a regra nova, citando `tip_add_carries_mission` e ADR 0015 §3.

**Onde:** `bin/sdd` — `path_in_commits` (:897), comentário de `mission_qa_report` (:950–953), laço final do `mission_qa_report`
(:1005–1009); `tests/check-gates.sh` — depois de `sed -i '/2026-01-12-fixture-ignored/d' "$FIX/.git/info/exclude"` (:1244), como o
mundo **(h)** da lista "(a)…(g)" do `qa_refused` (:1140); `tests/check-mutation.sh` (perto de `mut_QA_report_no_fallback` :834).

**Como (TDD):** o bloco (h) entra primeiro (o texto completo, do protótipo, está logo abaixo do resumo):
- salva `qa_tip_main="$(git rev-parse main)"`; em `main`, cria `docs/handoffs/20260102-other/checkpoint-notas.md` e o relatório
  **fechado** `docs/qa/reports/2026-01-13-fixture-other.md` (cabeçalho da proveniência `~/.claude/skills/qa-execution/assets/report-template.md:6`,
  como os vizinhos), commit `"another mission (squash)"`; volta para `missao/qa-report-owner`; `git checkout main -- docs/qa/reports/2026-01-13-fixture-other.md`;
  `qa_refused "another mission's report staged from the base tip is not the mission's"`; commit; guarda o piso
  (`tip/new` = está na ponta de `main` e ausente do merge-base) e `qa_tip_other="$(… phase …)"`; `git reset -q --hard HEAD~1`;
  `git branch -q -f main "$qa_tip_main"`;
- o **controle**: `printf 'own squash\n' >> "$MDIR/checkpoint-notas.md"` + relatório fechado `2026-01-14-fixture-own.md`, commit na
  branch; em `main`, `git merge -q --squash missao/qa-report-owner` + commit `"the mission (squash)"`; volta à branch; piso `tip/new`;
  `qa_tip_own="$(… phase …)"`; reset da branch e de `main` como acima;
- `assert_eq "both reports sit at the base tip and are new to the merge-base, so the worlds ask the tip question" "tip/new tip/new" …`;
- ⭐ **diferencial** `assert_eq "a report from the base tip counts only when the commit that added it carries this mission dir" "QA|REVIEW" "$qa_tip_other|$qa_tip_own"`
  (recusar toda ponta passa a 1ª metade e reprova a 2ª; não perguntar nada passa a 2ª e reprova a 1ª). ⚠️ Nome sem apóstrofo: o Check o cita entre aspas simples.


Bloco (h) completo, como prototipado sobre `fe9441d` (entra no `tests/check-gates.sh` no ponto indicado em **Onde**):

```bash
# (h) A report that landed on the base AFTER the fork, brought from the base tip: new to the
#     merge-base, so it counted (the residue ADR 0013 declared; reproduced in a scratch repo by the
#     lote-4 gemba). The question is structural since ADR 0015 §3: the base commit that ADDED the
#     path carries THIS mission's handoff dir? Another mission's squash carries ITS own dir, and
#     the mission's own squash, read from its branch after a fetch, carries this one — the world
#     right below is the control, and the two differ in nothing else.
qa_tip_main="$(git rev-parse main)"
git checkout -q main
mkdir -p "$FIX/docs/handoffs/20260102-other"
printf 'other mission\n' > "$FIX/docs/handoffs/20260102-other/checkpoint-notas.md"
cat > "$FIX/docs/qa/reports/2026-01-13-fixture-other.md" <<'EOF'
# QA Run Report — 2026-01-13 — another mission, squash-merged after the fork
- **Started:** 2026-01-13T10:00:00Z · **Status:** closed <!-- in-progress | closed -->
| # | Charter | Status |
|---|---|---|
| 1 | CH-one | Pass |
EOF
git add -A && git commit -qm "another mission (squash)" >/dev/null
git checkout -q missao/qa-report-owner
git checkout main -- docs/qa/reports/2026-01-13-fixture-other.md
qa_refused "another mission's report staged from the base tip is not the mission's"
git commit -qm "chore: the mission brings another mission's report from the base tip" >/dev/null
qa_tip_other_floor="$(git cat-file -e main:docs/qa/reports/2026-01-13-fixture-other.md && echo tip)/$(git cat-file -e "$(git merge-base HEAD main):docs/qa/reports/2026-01-13-fixture-other.md" 2>/dev/null && echo base || echo new)"
qa_tip_other="$( cd "$FIX" && "$SDD" phase "$MISSION" 2>&1 )"
git reset -q --hard HEAD~1
git branch -q -f main "$qa_tip_main"
# The control: THIS mission's own report, squash-merged into the base and read from the branch.
# The squash carries the mission's handoff dir, as every squash of a mission does (its checkpoint
# moves with every increment; 9 of 9 sdd-mission reports on sales_quote's develop, 2026-10-04).
printf 'own squash\n' >> "$MDIR/checkpoint-notas.md"
cat > "$FIX/docs/qa/reports/2026-01-14-fixture-own.md" <<'EOF'
# QA Run Report — 2026-01-14 — the mission's own, squash-merged
- **Started:** 2026-01-14T10:00:00Z · **Status:** closed <!-- in-progress | closed -->
| # | Charter | Status |
|---|---|---|
| 1 | CH-one | Pass |
EOF
git add -A && git commit -qm "chore: the mission's own report" >/dev/null
git checkout -q main
git merge -q --squash missao/qa-report-owner >/dev/null
git commit -qm "the mission (squash)" >/dev/null
git checkout -q missao/qa-report-owner
qa_tip_own_floor="$(git cat-file -e main:docs/qa/reports/2026-01-14-fixture-own.md && echo tip)/$(git cat-file -e "$(git merge-base HEAD main):docs/qa/reports/2026-01-14-fixture-own.md" 2>/dev/null && echo base || echo new)"
qa_tip_own="$( cd "$FIX" && "$SDD" phase "$MISSION" 2>&1 )"
git reset -q --hard HEAD~1
git branch -q -f main "$qa_tip_main"
# FLOOR: both reports sit at the base tip AND are new to the merge-base, or neither world asks the
# question the rule is about.
assert_eq "both reports sit at the base tip and are new to the merge-base, so the worlds ask the tip question" \
  "tip/new tip/new" "$qa_tip_other_floor $qa_tip_own_floor"
# ⭐ DIFFERENTIAL: one shape, one question apart. Refusing every report at the tip passes the first
# half and fails the second; asking nothing passes the second and fails the first.
assert_eq "a report brought from the base tip counts only when its base commit carries this mission's dir" \
  "QA|REVIEW" "$qa_tip_other|$qa_tip_own"
```

Vermelho medido (runner de `fe9441d`): `FAIL another mission's report staged from the base tip is not the mission's — expected: QA|1 — got: REVIEW|0`
e `FAIL a report … carries this mission dir — expected: QA|REVIEW — got: REVIEW|REVIEW` (o piso passa: os dois mundos perguntam a coisa certa).
Verde: check-gates 391 ok / 0 FAIL só com o I20; 393 com I19+I20.
**Realidade medida** (`$S/design-E/w/realadds.sh ~/repos/sales_quote origin/develop`, a mesma plumbing do protótipo): dos 21 relatórios
na ponta de `develop`, **9** foram adicionados por um commit que toca um diretório de missão sdd (`20260814-sq94…`, `20260908-…`,
`20260914-…` ×2, `20260915-…`, `20260928-painel-gerencial`, `20260929-…`, `20260930-…` ×2) — **todos squash (1 pai), cada um tocando
exatamente o próprio diretório**; **0** tocam o diretório de outra missão. Merge do `sales_quote` desde 2026-08-01: 110 commits do
GitHub na primeira-pai, **85 squash, 25 merge, 0 rebase**; o `lighthouse_project` e o kit mergeiam por merge commit (faixa vazia
depois do merge → o recuo de sempre, a função nova nem roda). Os três repos **permitem** rebase-merge (`gh api repos/<o>/<r>` →
`allow_rebase_merge: true`), então o resíduo abaixo é alcançável, só não usado.

**Sabotagens/mutantes:** 2 novos —
`mut_QA_report_tip_any_mission() { sed -i '/^tip_add_carries_mission() {/,/^}/ s@-- "\$HANDOFF_DIR/\$MISSION/" 2>/dev/null@-- "$HANDOFF_DIR/" 2>/dev/null@' "$1"; }` →
`ok QA_report_tip_any_mission — check-gates.sh dies (rc 1)`, 77 s (morre no `qa_refused` staged e no diferencial: o squash da outra
missão carrega o diretório **dela**, por isso a fixture o cria — sem ele este mutante sobreviveria);
`mut_QA_report_tip_refused_outright() { sed -i '/^tip_add_carries_mission() {/,/^}/ s@^    add=""$@    return 1@' "$1"; }` →
`ok QA_report_tip_refused_outright — check-gates.sh dies (rc 1)`, 78 s (morre só no diferencial: `got: QA|QA` — é a forma que a ADR
0013 recusou). "Tirar a chamada" é o próprio `fe9441d`, medido vermelho acima. `--anchors`: `all 602 mutants still apply`.

**Check:** `o=$(env -u CLAUDECODE TMPDIR=/tmp bash tests/check-gates.sh 2>&1); grep -c '^  ok    a report from the base tip counts only when the commit that added it carries this mission dir' <<< "$o"` → `1`   (antes, medido em fe9441d: `0`; no topo: `1`)

**Sensor durável:** o mundo (h) do `check-gates.sh` (piso + `qa_refused` staged + diferencial) e 2 mutantes, um por direção.

**Saída do item:** #179 recebe ` RESOLVED by <hash deste commit>` no I24 (sai da seção aberta no chore pós-merge, catraca −1). A
"Direção" do item ("distinguir pelo blob na ponta") fica **refutada** na ADR 0015 §3, não no TODO.md.

**Âncoras do TODO.md que o incremento desloca:** medido sobre o I19: `bin/sdd:2092` (linha 42, `sandbox()` → 2105), `bin/sdd:1102`
(linha 99, `gate_TICKET` → 1133), `bin/sdd:4315` (linha 125, `.sdd/config.sh` → 4304), além das que I18/I19 já deslocaram se não
re-ancoradas. A âncora do próprio #179 (`bin/sdd:894`, `path_in_commits` está em :897) continua dentro dos 10 linhas e é podre de
nascença — o I24 a apaga com o item. `remap.py` + `xref.py --fix`.

**Reversível por:** `git revert` do commit (volta ao fail-open declarado da ADR 0013; nenhum dado em disco muda).

### I21 — a régua de idioma lê `docs/` por censo, e o piso vira derivado (#141, #108a)

**O quê:** em `tests/check-lang.sh`:
- **uma** lista da superfície, lida por `surface()` e pelo piso:
  `SURFACE_SPECS=(bin/sdd bin/sdd-link-agents bin/sdd-coordination.py 'agents/sdd-*.md'
  '.claude/agents/sdd-*.md' 'docs/*.md' 'docs/adr/*.md' README.md config/schema.md
  config/starter.conf 'tests/*.sh' tests/health-baseline.txt tests/lang-allowlist.txt)` — `docs/*.md`
  por glob no lugar de `docs/pipeline.md docs/failure-modes.md docs/graphify.md`;
- `LANG_DECLARED=(docs/handoffs/ docs/qa/ docs/superpowers/)` — as mesmas três do `health --release`
  (`bin/sdd:6045-6047`, comentário + `grep -rlF … docs/*.md docs/adr …`); as duas listas respondem
  perguntas diferentes e nada afirma paridade entre elas: **declarado** no comentário;
- `surface <root>` itera `SURFACE_SPECS` com `compgen -G` (builtin), num `( CDPATH='' cd -- "$root" … )`,
  e mantém a exclusão `grep -vxF` dos dois arquivos-dado;
- `census <root>`: (1) **piso derivado**: todo padrão de `SURFACE_SPECS` casa ≥ 1 arquivo, senão
  `  FAIL  surface pattern <p> matches nothing — did something move?` rc 93; (2) **censo**: todo
  `git -C <root> ls-files -- 'docs/*.md'` (o `*` do pathspec do git atravessa `/`: é `docs/**/*.md`) está
  na superfície ou sob `LANG_DECLARED`, senão `  FAIL  census: <f> is tracked but on no surface and under
  no declared subtree (…)` e **rc 97** (novo); censo que não acha nenhum doc na superfície = rc 93 (vácuo,
  "is <root> a git checkout?"). Verde: `  ok    census: every tracked docs/**/*.md is on the surface or under
  a declared subtree (19 on the surface, 306 declared)` (medido no protótipo). `census` **publica**
  `SURFACE_FILES` (global, chamada, nunca `$(…)`) e o laço da varredura lê `files="$SURFACE_FILES"`:
  apagar a chamada deixa a varredura lendo variável não definida sob `set -u` → vermelho alto (medido:
  rc 1), e não uma varredura sem censo;
- modo `--census <root>` (sem selftest; o que o selftest dirige), com guarda de diretório (`cd ""` cairia
  no cwd): `[ -n "${2-}" ] && [ -d "$2" ] || { …needs a directory; exit 96; }`; qualquer outra opção →
  rc 96; `SELF_PATH="$ROOT/tests/$(basename "${BASH_SOURCE[0]}")"`; usage e tabela de rc no cabeçalho;
- o bloco do piso (`:176-207`, os 30 linhas de histórico do `-lt 56`) sai e vira 3 linhas: "The floor is
  DERIVED (ADR 0015 §4) … `census "$ROOT" || exit $?` / `files="$SURFACE_FILES"`". ⚠️ A comparação
  numérica `-lt 56` sai, mas a **atribuição** `n_surface="$(grep -c . <<< "$files")"` **fica**. O
  `printf` final (`  ok    %d of %d surface path(s)…`) a usa sob `set -u`, e o I5 a designa como
  símbolo do #108. Sem ela o sensor sai rc 1 com variável não definida. O protótipo do designer C a
  mantém, logo depois do comentário "The floor is DERIVED".
- grafia exata, que o Check lê: `SURFACE_SPECS=(` no começo da linha, sem `readonly` na frente (o
  `awk '/^SURFACE_SPECS=/,/[)]$/'` do Check depende disso).
- o comentário da :24-25 passa a listar `docs/handoffs/`, `docs/qa/` e `docs/superpowers/`.

Fora do sensor:
- `docs/plan-only.md`: **traduzir** o bloco (recomendado) — **não** mover para `config/examples/`.
  Porquê: o kit é público e o bloco é o que um adotante cola; `config/examples/` hoje só tem
  `sales_quote.conf` (config de UM repo nomeado, em pt-BR), e mover mandaria o leitor de um doc inglês
  para um arquivo português; `templates/` está fora por `bin/sdd:2918`. Texto exato que substitui da
  :123 ao fim:

~~~markdown
Pointer, not recipe — the recipe is this file. Write it in the target's `OUTPUT_LANG`; the
English version is below, and the file names and the `aprovacao:` key stay as they are, because
they are contract:

```markdown
## Mission planning (the `sdd` kit)

Large missions are planned before any code is written, and the plan becomes three artifacts in
`docs/handoffs/<YYYYMMDD-slug>/`: `00-missao.md` (the intent), `01-plano.md` (the how,
self-contained) and `checkpoint.md` (the increment table, **read by a machine**).

- Start a mission: `/sdd-plan` — an interactive session, with brainstorm and grill.
- Validate the plan without spending a session: `sdd why <mission> PLAN`.
- Approve: `sdd approve <mission>` — **never** edit `aprovacao:` by hand.

The kit lives in `~/repos/sdd_agents`, and the full recipe is its
[`docs/plan-only.md`](file:///home/joruge/repos/sdd_agents/docs/plan-only.md). The agents in
`.claude/agents/sdd-*.md` are symlinks into the kit and are **not** versioned: in a fresh clone,
run `sdd install && sdd-link-agents`.
```
~~~
  e a :15 vira `observation, **measured on `sales_quote`, in its mission of 2026-09-08
  (`docs/handoffs/20260908-…` there)**:` (sem o slug em prosa; decidido "Slug de missão em pt-BR…").
- `CLAUDE.md` § Idioma, texto exato (pt-BR):
  - :21-27 → "**A superfície do kit é inglês:** `bin/sdd`, `agents/`, `docs/` (fora as três subárvores de
    conteúdo do parágrafo seguinte), `README.md`, `config/schema.md`, `config/starter.conf`, `tests/`. Vale
    para prosa, comentários, mensagens ao usuário, nomes de teste e identificadores locais. O sensor é
    `tests/check-lang.sh`, com catraca bidirecional em `tests/lang-allowlist.txt`: arquivo sujo fora da
    lista reprova, arquivo já limpo dentro dela também. Desde a ADR 0015 §4 a parte de `docs/` é
    **censo**, não lista: `docs/*.md` entra por glob, todo `docs/**/*.md` rastreado tem de estar na
    superfície ou numa subárvore declarada (doc fora das duas reprova com rc 97), e o piso deixou de ser
    número escrito à mão. Duas exceções, …" (o resto igual);
  - :32-34 → "Aqui a chave é `pt-BR`, e é por isso que `TODO.md`, `KAIZEN_LOG.md`, este arquivo,
    `docs/handoffs/`, `docs/qa/`, `docs/superpowers/`, `templates/` e `config/examples/` continuam em
    português — não são exceção, são conteúdo no idioma declarado. As três subárvores de `docs/` são o
    `LANG_DECLARED` do sensor, as mesmas que o `health --release` deixa fora da sua linha 5."
- `TODO.md`: as duas âncoras caem dentro do trecho reescrito (o `remap.py` as marca para olho humano):
  #108 `tests/check-lang.sh:180` sai do alvo (medido: `FAIL line 83: anchor … off target — nearest
  docs/adr/*.md is at line 261`) → `tests/check-lang.sh:66` (linha do `SURFACE_SPECS` com
  `'docs/adr/*.md'`); #141 `tests/check-lang.sh:52` continua "no alvo" pela regra de `fe9441d` mas aponta
  para comentário → `tests/check-lang.sh:73` (`surface()`). Números do protótipo — recalcule com
  `grep -n "'docs/adr/\*.md'\|^surface() {" tests/check-lang.sh`. Medido depois: `anchors: 23 measured, 0
  off target`. (Se o #191 do designer B, símbolo designado, entrar antes, as duas âncoras já apontam
  para o símbolo — satisfazem a regra mais estrita.)

**Onde:** `tests/check-lang.sh` (cabeçalho :15-19, comentário :24-25, `surface()` :52-58, fim do
`selftest()` :150-157, bloco do piso :176-207), `docs/plan-only.md` (:15, :121-140), `CLAUDE.md` (:21-27,
:32-34), `TODO.md` (#108 :84, #141 :180).

**Como (TDD):**
1. Selftest do censo primeiro, em filho, sobre árvores-fixture que são checkouts git próprios
   (`GIT_CEILING_DIRECTORIES="$WORK"`), helper `census_says <rc> <texto> <árvore> <rótulo>` que sai **98**
   (rc novo de selftest) no desacordo; `census_tree` **deriva** um arquivo por padrão de `SURFACE_SPECS`
   (`${spec//\*/x}`, para não criar o "quinto lugar") **mais** `docs/a.md` escrito À MÃO (a testemunha
   independente, lição do `calibrate()`). Cinco probes + piso `CENSUS_PROBES -ge 5` + controle negativo:
   árvore inteira → 0; `docs/newtree/y.md` rastreado → 97 nomeando o arquivo; `docs/handoffs/m/n.md` +
   `docs/qa/z.md` + `docs/superpowers/s.md` → 0 com `3 declared)`; `docs/adr/` apagado → 93 `surface
   pattern docs/adr/*.md matches nothing`; sem `.git` → 93 `no tracked docs/*.md`; controle:
   `( census_says 0 'census: every tracked' "$c/stray" control ) 2>/dev/null` tem de FALHAR. Linha nova:
   `  ok    self-test: the census refuses a tracked doc outside the surface and every declared subtree (5
   probe(s))`.
2. Glob + censo → **vermelho pelo motivo certo, medido**: `check-lang.sh` rc 1, `  FAIL  Portuguese outside
   the allowlist: docs/plan-only.md` com as linhas 15, 126, 128, 129, 130 — o fail-open do #141 aparece.
3. Traduzir o bloco + reescrever a :15 → verde: `  ok    0 of 58 surface path(s) still in the allowlist, 0
   new` (56 + ADR 0015 do passo 0 + `docs/plan-only.md`). ~1,0 s por execução. `shellcheck` limpo;
   `check-pipefail` verde (`cdpath: 18 path(s) … empties CDPATH first`).

**Sabotagens/mutantes:** sem mutante (o `run-all.sh` pula o check-lang sob `SDD_MUTANT`, :300; o
catálogo não o alcança). Passada (`$S/design-C/sab21.sh`, cópia do sensor rodando sobre a árvore real):
**10 de 10 pegas pelo selftest (rc 98)** — censo que nunca recusa; `docs/` inteiro declarado; tirar
`docs/qa/`, `docs/handoffs/` ou `docs/superpowers/` da lista (três sabotagens); voltar a enumerar
`docs/pipeline.md docs/failure-modes.md docs/graphify.md`; tirar o piso por padrão; tirar o vácuo do
censo; `ls-files` não recursivo (`:(glob)docs/*.md`); `census_says` neutralizado (pego pelo controle
negativo). **+1 vermelho sem selftest:** apagar a chamada `census "$ROOT"` → rc 1 (`SURFACE_FILES` não
definida sob `set -u`). **1 sobrevivente declarada:** apagar o controle negativo sozinho (só importa junto
com neutralizar o `census_says`: duas edições). **Limite declarado no comentário do `census()`:** apagar
um padrão NÃO-docs do `SURFACE_SPECS` é diff na definição e nada recusa (o piso numérico recusava só
enquanto não tinha folga — 67 de 124 commits); doc não rastreado não conta.

**Acréscimo da decisão 8 — `commands/*.md` entra na régua, no mesmo commit:**
- `SURFACE_SPECS` ganha o padrão `'commands/*.md'`. Hoje ele casa um arquivo só, `commands/sdd-plan.md`,
  e o piso por padrão do censo já exige que case pelo menos um.
- As linhas 18–20 de `commands/sdd-plan.md` são a mensagem "verbatim" de quando falta o
  `.sdd/config.sh`, e estão em pt-BR. Elas viram:

  ```markdown
     > This repository has no `.sdd/config.sh` — the `sdd` kit is not installed here.
     > Run `sdd install && sdd-link-agents` and edit the config before planning.
     > Recipe: `~/repos/sdd_agents/docs/plan-only.md`
  ```
- `CLAUDE.md` § Idioma: a lista da superfície inglesa ("`bin/sdd`, `agents/`, `docs/`, `README.md`,
  `config/schema.md`, `config/starter.conf`, `tests/`") ganha `commands/`. **Funda** com o texto do
  designer C acima, que declara `docs/qa/` e `docs/superpowers/`: é UMA edição do mesmo parágrafo.
- Medido pelo designer C em `fe9441d`: só acrescentar o padrão, sem traduzir, deixa o `check-lang.sh`
  em rc 1 nessas linhas. O I6 já mexeu em outra seção do mesmo arquivo (`## When the artifacts exist`),
  sem conflito.
- ⚠️ O `~/.claude/commands/sdd-plan.md` do humano é symlink para este arquivo: a tradução vale na hora.
- O Check abaixo soma duas colunas ao do designer C:
  - `d` conta o padrão dentro de `SURFACE_SPECS`;
  - `e` conta a frase pt-BR que tem de sumir.

  Em `fe9441d` não existe `SURFACE_SPECS`, por isso o `d` dá 0 ali.

**Check:** `o=$(bash tests/check-lang.sh 2>&1); r=$?; a=$(grep -c '^  ok    census: every tracked docs/' <<< "$o"); b=$(grep -c '^  ok    self-test: the census refuses' <<< "$o"); c=$(grep -c '^  ok    0 of ' <<< "$o"); s=$(awk '/^SURFACE_SPECS=/,/[)]$/' tests/check-lang.sh); d=$(awk 'index($0, "commands/*.md"){n++} END{print n+0}' <<< "$s"); e=$(awk '/Este reposit/{n++} END{print n+0}' commands/sdd-plan.md); f=$(awk '/n_surface" -lt [0-9]/{n++} END{print n+0}' tests/check-lang.sh); echo "$r $a $b $c $d $e $f"` → `0 1 1 1 1 0 0`
(antes, medido em `fe9441d` + passo 0: `0 0 0 1 0 1 1`. As quatro primeiras colunas são as do designer C; `d` e `e` são a decisão 8; `f` cobra que a comparação numérica do piso saiu.)

**Sensor durável:** os 5 probes + controle negativo do censo (selftest, rc 98), a linha `ok census:` da
varredura real e o rc 97; o piso deixa de ser número.

**Saída do item:** #141 → `RESOLVED by <hash I21>` no I24; #108 → `RESOLVED by <hash I21>, <hash I22>` no
I24 (o check-lang derivado aqui, os outros três declarados no I22). Catraca: só na faxina pós-merge.

**Âncoras do TODO.md que o incremento desloca:** #108 e #141, à mão, no mesmo commit. O designer C
mediu sobre `fe9441d`: #108 de `:180` para `:66`, e #141 de `:52` para `:73`. ⚠️ Mas o I5 já terá
re-designado o #108 para o símbolo `n_surface` (`:203` em `fe9441d`); depois do I21, a âncora do #108
segue `n_surface` para onde ele estiver (`:307` no protótipo). Vale a dica do `check-todo.sh --anchors`
no momento, não o número desta seção. O decidido "Slug de missão…"
(`tests/check-lang.sh:130`) não é medido pelo `--anchors` e a linha muda de conteúdo: opcional no I24
apontá-lo para a linha nova do probe do `Spec:` (`grep -n 'Spec: docs/handoffs/20260917' tests/check-lang.sh`).

**Reversível por:** `git revert` do commit (sensor, doc, `CLAUDE.md` e âncoras voltam juntos).

### I22 — os outros pisos declaram o limite (#108b)

**O quê:** parágrafo `DECLARED LIMIT (ADR 0015 §4): this floor is anti-vacuity, not a tracker of the
surface.` ao lado de cada um dos três pisos, e o `CALIBRATE_FLOOR` entra na lista do `CLAUDE.md` no lugar
do piso do check-lang (que virou derivado no I21) — a lista continua com quatro lugares. Textos exatos:
- `tests/run-all.sh`, bloco do lint (:213-217) → "# The floor is the anti-vacuity guard, same reason as
  the one in check-pipefail.sh: a glob that stops matching, or a list someone narrows back to bin/sdd,
  leaves the linter reporting "clean" over files it never read — the failure mode where the sensor
  claims to have measured what it did not. The floor moves only on purpose, in a commit that says why.
  / # / # DECLARED LIMIT (ADR 0015 §4): this floor is anti-vacuity, not a tracker of the surface. It
  equals the real count only because the house moves it with every new sensor (CLAUDE.md, the four
  places a sensor enters); nothing measures that it did, so a sensor that lands without moving it
  leaves slack, and the floor goes on passing one file short. Measured: no lag in 105 commits. Its
  sibling in check-lang.sh lagged in 57 of 124 and was derived instead (census() there)." (sai o "14
  paths today", que já era falso — o real é 19); e em :237-241 "It tracks the real count on purpose" →
  "It is kept AT the real count on purpose … and the limit declared above."
- `tests/check-pipefail.sh`, `scan_surface()` (:955-956) → "# Explicit floor, same reason as LINT_FLOOR in
  run-all.sh: … clean by vacuity. / # DECLARED LIMIT (ADR 0015 §4): this floor is anti-vacuity, not a
  tracker of the surface — a sensor that lands without moving it leaves slack and it goes on passing;
  no lag in 105 commits, and the selftest fixture built at the floor is the fifth place CLAUDE.md
  names." (o resto do histórico do comentário fica).
- `tests/check-checkpoint.sh`, acima de `CALIBRATE_FLOOR=16` (:411): "# DECLARED LIMIT (ADR 0015 §4): this
  floor is anti-vacuity, not a tracker of the surface. It is 16 because 16 sensors print the ok prefix
  today, and a seventeenth that lands without moving it leaves one of slack; nothing measures that, so
  it is one of the places CLAUDE.md says every new sensor moves. No lag in 105 commits."
- `CLAUDE.md`, parágrafo "⚠️ **"Entra lá" são quatro lugares…**" (:336-343), até "O quinto lugar":
  "Medido ao acrescentar o `check-health.sh`, e refeito pela ADR 0015 §4: a linha `run` do
  `tests/run-all.sh`, o `LINT_FLOOR` do mesmo arquivo, o piso de superfície do `tests/check-pipefail.sh` e
  o `CALIBRATE_FLOOR` do `tests/check-checkpoint.sh` (os sensores que imprimem o prefixo ok). Os três pisos
  existem contra vacuidade — glob que para de casar deixa o laço sem nada para ler e o sensor reporta "0
  violações" — e **não rastreiam a superfície**: piso que ficou para trás continua **passando** enquanto
  descreve uma superfície menor do que a que lê, e nada o mede; é limite declarado no comentário de cada
  um (nenhum atrasou em 105 commits). O do `tests/check-lang.sh` saiu da lista: atrasou em 57 de 124
  commits e virou derivado (`census()` — cada padrão casa um arquivo, todo `docs/**/*.md` rastreado tem
  dono). O quinto lugar é o **fixture do selftest** do `check-pipefail.sh`, …" (resto igual; reflua as
  linhas — no protótipo a junção deixou uma linha longa e foi refluída).

**Onde:** `tests/run-all.sh` (:213-217, :237-241; `LINT_FLOOR=19` :243 não muda), `tests/check-pipefail.sh`
(`scan_surface()` :955-956; o `-lt 18` da :963 não muda), `tests/check-checkpoint.sh` (`CALIBRATE_FLOOR`
:411), `CLAUDE.md` (:336-343).

**Como (TDD):** só comentário e prosa; o Check vem primeiro (vermelho `0 0`, medido), depois os textos →
`3 1`. `shellcheck -S warning` nos três `.sh` limpo (cuidado: linha de comentário cuja 1ª palavra é o
nome do linter vira diretiva — aviso do próprio `run-all.sh`); `check-pipefail`/`check-checkpoint` rc 0.

**Sabotagens/mutantes:** nenhum — é declaração (D15): a dívida escrita é o entregável.

**Check:** `n=0; for f in tests/run-all.sh tests/check-pipefail.sh tests/check-checkpoint.sh; do s=$(awk '/anti-vacuity, not a tracker of the surface/{c++} END{print c+0}' "$f"); [ "$s" -gt 0 ] && n=$((n+1)); done; c=$(awk '/Entra lá. são quatro lugares/{p=1} p && /CALIBRATE_FLOOR/{c++} /quinto lugar é o/{p=0} END{print c+0}' CLAUDE.md); echo "$n $c"` → `3 1`   (antes, medido em fe9441d e em 1e56a6d: `0 0`)

**Sensor durável:** nenhum novo, de propósito (limite declarado, D15); o `CLAUDE.md` passa a mandar mover o
`CALIBRATE_FLOOR` com cada sensor novo.

**Saída do item:** #108 → `RESOLVED by <hash I21>, <hash I22>` no I24 (ver I21).

**Âncoras do TODO.md que o incremento desloca:** nenhuma aberta (medido: `0 off target`); o decidido
`tests/run-all.sh:168` fica igual (inserções depois da :213, conferido por `diff`).

**Reversível por:** `git revert` do commit.

### I23 — O schema da série ganha sensor de chave contra a prosa (#98)

**O quê:** um bloco marcado em `docs/pipeline.md`, entre `<!-- sdd:series-fields -->` e
`<!-- /sdd:series-fields -->`, nomeia como crase **cada chave** que `sdd kaizen --series` imprime,
em todo nível, e nada mais (inclui `label`, a única ausente do arquivo hoje). Uma seção nova no fim
do `tests/check-kaizen.sh` lê **só o bloco** e compara com as chaves de duas séries — a fixture
rica da primeira seção (as duas fatias, `detail`, `composition`, `escalations` com dois `kind`) e o
literal do ledger vazio — nos **dois sentidos**. Os filhos de `escalations` são `kind` (dado, não
esquema) e ficam fora. A sandbox do catálogo passa a copiar `docs/pipeline.md` (sem isso o controle
do `--only` reprova). Mutante novo `KAIZEN_series_key_renamed`. O drift de **unidade** (sessão →
missão, o caso que abriu o item) e de **nível** (chave que muda de objeto) ficam como limite
escrito no cabeçalho do sensor e no parágrafo do bloco.

**Onde:** `docs/pipeline.md` (`## The kaizen loop`, logo depois do parágrafo "The empty-ledger
branch prints the same key set with zeros…", `:1507-1508`); `tests/check-kaizen.sh` — cabeçalho
(antes de `# Usage:`, `:20`), primeira leitura da série (`SERIES_OUT=… kaizen --series …; rc=$?`,
`:161`), seção nova antes de `echo "== hygiene =="` (`:2438`); `tests/check-mutation.sh` —
`mut_KAIZEN_series_key_renamed` antes de `mut_KAIZEN_series_rc_dropped()` (`:1655`), slug no
`CATALOG=(` depois de `KAIZEN_composition_unprinted` (`:5885`), uma linha no fim de `sandbox()`
depois de `cp -r "$ROOT/docs/adr" "$1/docs/"` (`:6127`).

**Como (TDD):**

1. *Probe primeiro* (`tests/check-kaizen.sh`). Logo depois da linha `:161`:
   `SERIES_RICH="$SERIES_OUT"` (comentário: a série mais rica, relida pelo sensor de chave). Seção
   nova antes da higiene:
   ```bash
   echo "== series: every key is named in docs/pipeline.md, and the doc names no other =="
   # (comentário: issue 98; o bloco é o único lugar dos NOMES; lê só o bloco para sobreviver a um
   #  split; dois sentidos; filhos de `escalations` são kinds; LIMITE: nomes, não unidade nem nível;
   #  dono do bloco: quem muda o jq de kaizen_series, no mesmo commit)
   PIPELINE_DOC="$ROOT/docs/pipeline.md"
   SERIES_EMPTY="$( cd "$FIX" && SDD_STATE_DIR="$OUTSIDE/keys-empty" "$SDD" kaizen --series 2>/dev/null )"
   series_key_names() { # <series json> — every key name it prints, at every level, one per line
     jq -r '[paths | select(.[-1] | type == "string") | select(length < 2 or .[-2] != "escalations")
             | .[-1]] | unique | .[]' <<< "$1"
   }
   # The witness first: a fixture that lost a level would make the comparison below vacuous for it.
   assert_eq "the key sensor reads a series with both slices, a detail, a composition and an escalation" "true" \
     "$(jq -r '(.latest | type) == "object" and (.previous.detail | length) > 0
               and (.previous.composition | length) > 0 and (.previous.escalations | length) > 0' <<< "$SERIES_RICH")"
   assert_eq "docs/pipeline.md carries one series-fields block, opened and closed" "1 1" \
     "$(grep -c '^<!-- sdd:series-fields -->$' "$PIPELINE_DOC") $(grep -c '^<!-- /sdd:series-fields -->$' "$PIPELINE_DOC")"
   keys_printed="$( { series_key_names "$SERIES_RICH"; series_key_names "$SERIES_EMPTY"; } | LC_ALL=C sort -u )"
   keys_named="$(awk '/^<!-- sdd:series-fields -->$/ { on = 1; next } /^<!-- \/sdd:series-fields -->$/ { on = 0 } on' \
     "$PIPELINE_DOC" | grep -o '`[^`]*`' | tr -d '`' | LC_ALL=C sort -u)"
   assert_eq "every series key is named in docs/pipeline.md" "" \
     "$(LC_ALL=C comm -23 <(grep . <<< "$keys_printed") <(grep . <<< "$keys_named") | tr '\n' ' ')"
   assert_eq "and every name in that block is a key the series prints" "" \
     "$(LC_ALL=C comm -13 <(grep . <<< "$keys_printed") <(grep . <<< "$keys_named") | tr '\n' ' ')"
   ```
   (`grep .` e não `printf '%s\n'`: com um conjunto vazio o `printf` entrega uma linha em branco ao
   `comm`, e o sentido 2 reprovava o bloco ausente com `got: ' '` em vez de deixar a causa para a
   asserção do bloco — medido e consertado no protótipo.)
   Cabeçalho do sensor, antes de `# Usage:`: "DECLARED LIMIT (issue 98): the key sensor near the
   end holds the NAMES the series prints against the sdd:series-fields block of docs/pipeline.md,
   both ways. A key that keeps its name and changes its unit (sessions -> missions, the drift that
   opened the issue) or moves to another object of the series is not caught: names are measured
   here, meanings are not."

2. *Red, medido* (seção nova, doc de `fe9441d`, sem o bloco): `bash tests/check-kaizen.sh` → rc 1
   com `FAIL  docs/pipeline.md carries one series-fields block, opened and closed` (`got: 0 0`) e
   `FAIL  every series key is named in docs/pipeline.md` (`got:` as 41 chaves, de `advance_rate` a
   `window_missions_stranded`); o sentido 2 fica `ok` (bloco vazio não nomeia nada). Com o bloco e **sem**
   `label`: `FAIL  every series key is named in docs/pipeline.md` / `got: label` — o mesmo único
   achado do protótipo do verificador C (`grep -c '`label`' docs/pipeline.md` → `0` em `fe9441d`).
   Com um nome a mais no bloco (`bogus_key`): `FAIL  and every name in that block is a key the
   series prints` / `got: bogus_key`.

3. *Conserto: o bloco* (inglês; nenhuma crase no bloco que não seja chave — `null`, `kind`,
   `composition[]` ficam sem crase). Parágrafo antes, fora do bloco:
   ```markdown
   **Every key, in one place.** The block below names each key the series prints, at every level, and
   nothing else. `tests/check-kaizen.sh` reads this block — never the whole file, so it survives the
   section moving elsewhere — and compares it with the keys of a fixture series in both directions: a
   key renamed or added in the `jq` of `kaizen_series` without a word here, or a name here the series
   no longer prints, turns the suite red. It measures names only: a key that keeps its name and
   changes its unit or its meaning is not caught, and the sensor's comment says so.

   <!-- sdd:series-fields -->
   - top level: `v`, `latest`, `previous`, `guard`, `excluded`
   - `latest` and `previous`, each a slice or null: `kit_sha`, `kit_shas_raw`, `missions`,
     `missions_with_session`, `composition`, `sessions`, `harness`, `outcomes`, `advance_rate`,
     `moved_rate`, `labels`, `escalations`, `cost_usd`, `detail`
   - a `composition` entry: `repo`, `missions`, `missions_with_session`
   - a `detail` entry: `repo`, `mission`, `phase`, `label`, `sessions`, `outcomes`, `cost_usd`
   - `outcomes`, in a slice and in a `detail` entry: `advanced`, `churned`, `idle`
   - `labels`: `ok`, `leve`, `refez`
   - `escalations`: one key per escalation kind, holding its count — data, never a fixed name
   - `guard`: `missions_after_change`, `missions_with_session`, `sessions`, `floor`, `sufficient`,
     `why`, `harness`, `window_missions_stranded`, `window_broken`, `degenerate_axis`
   - `excluded`: `non_comparable`, `unrecognized`, `meta`, `other_repo`, `no_repo`
   <!-- /sdd:series-fields -->
   ```
   Se um incremento anterior (p.ex. o do #153, evento `manual`) tiver acrescentado chave à série, o
   próprio sensor diz qual falta (`got: <chave>`): acrescente-a ao bloco.

4. *Mutante* (`tests/check-mutation.sh`), com comentário dizendo que a chave do custo de um
   `detail` não tem outro leitor na suíte:
   ```bash
   mut_KAIZEN_series_key_renamed() {
     sed -i '/^kaizen_series() {/,/^}/ s/^                      cost_usd: (map(.cost_usd \/\/ 0) | add)})) as \$detail$/                      cost: (map(.cost_usd \/\/ 0) | add)})) as $detail/' "$1"
   }
   ```
   `KAIZEN_series_key_renamed` no `CATALOG=(`. **E na `sandbox()`**, depois do `cp -r docs/adr`:
   `cp "$ROOT/docs/pipeline.md" "$1/docs/"`, com comentário (um arquivo, não a árvore; lido
   qualquer que seja o mutante, nunca mutado, fora da chave do carimbo como `docs/adr`). Medido: sem
   essa linha o `--only` responde `FAIL  docs/pipeline.md carries one series-fields block, opened
   and closed` no **controle** (`grep: …/control/docs/pipeline.md: No such file`).

5. *Verde, provado no protótipo:* `bash tests/check-kaizen.sh` → 218 linhas `ok` (eram 214), rc 0,
   17 s; `tests/check-mutation.sh --only KAIZEN_series_key_renamed check-kaizen.sh` →
   `  ok    control: check-kaizen.sh is green on an unsabotaged copy` e
   `  ok    KAIZEN_series_key_renamed — check-kaizen.sh dies (rc 1)` (18 s; morre em
   `every series key is named in docs/pipeline.md` / `got: cost`); `--anchors` →
   `all 594 mutants still apply and leave valid code` (5 s); `check-lang.sh` → `0 of 56` (o bloco é
   inglês); `shellcheck -S warning` limpo nos dois arquivos de `tests/`.

**Sabotagens/mutantes:** mutante novo `KAIZEN_series_key_renamed` (o `detail[].cost_usd` vira
`cost`). Antes do sensor ele **sobrevivia**: medido em `786f0fe`, `check-kaizen.sh` rc 0 e
`check-autonomy.sh` rc 0 (89 s) — os únicos sensores que leem a série (`grep -ln 'kaizen --series\|kaizen_series' tests/*.sh`
→ esses dois e o catálogo). Depois: `--only` → `check-kaizen.sh dies (rc 1)`. O sentido inverso
(nome no bloco que a série não imprime) não tem mutante de `bin/` que o isole — é medido pela prova
do passo 2 (`bogus_key`) e pelas sabotagens do sensor, 4 de 4 vermelhas (`$S/design-B/meas/sab98.py`):
SB1 ler o arquivo inteiro em vez do bloco → `and every name in that block…`; SB2 tratar os `kind`
de `escalations` como chave → `every series key is named…`; SB3 só o literal vazio → `and every
name…`; SB4 só o nível de topo → `and every name…`.

**Check:** `o=$(bash tests/check-kaizen.sh 2>&1); grep -c -e '^  ok    every series key is named in docs/pipeline.md' -e '^  ok    and every name in that block is a key the series prints' <<< "$o"` → `2`
(antes, medido em `fe9441d` e em `125d737` (protótipo do I5): `0`. Aceito por
`tests/check-checkpoint.sh --check`.)

**Sensor durável:** as quatro asserções da seção nova do `check-kaizen.sh` (testemunha da
fixture, bloco único, os dois sentidos) + o mutante `KAIZEN_series_key_renamed` no catálogo.

**Saída do item:** `RESOLVED by <hash do I23>` no I24; catraca não se move no I23 (desce no chore).

**Âncoras do TODO.md que o incremento desloca:** nenhuma primária (`bin/sdd` não é tocado). Uma
secundária: `tests/check-mutation.sh:6104` (o `sandbox()`, citado no item #67 "O carimbo de
mutação cobre 4 dos 8…") desce +10 com o mutante inserido acima (`sandbox() {` em `:6114` no
protótipo) — o `remap.py` a reporta como `NOT-REWRITTEN` (span posterior): corrigir à mão se o
item #67 ainda estiver aberto. `docs/pipeline.md:1379` (secundária do #98) fica: o bloco entra
depois, em `:1509`.

**Reversível por:** `git revert` do commit (bloco, sensor, mutante e linha da sandbox juntos).

### I24 — Fecho: `RESOLVED by`, emendas da ADR, glossário, drift, KAIZEN_LOG, handoff da EXEC e a suíte inteira

**O quê:** sete passos, na ordem.

1. **`RESOLVED by <hash>` nos 16 itens consertados.** Cada item recebe o hash do commit (ou dos
   commits) do seu incremento, conferido com `git log --oneline`:

   | Item | Incremento(s) |
   |---|---|
   | #194 | I3 |
   | #178 | I4 |
   | #191 | I5 |
   | #92 | I7 e I8 |
   | #95 | I9 |
   | #134 | I10 |
   | `kaizen_reminder` | I11 |
   | #67 | I12 |
   | #142 e #198 | I13 e I14 |
   | #129 | I15 e I16 |
   | #153 | I17, I18 e I19 |
   | #179 | I20 |
   | #141 | I21 |
   | #108 | I21 e I22 |
   | #98 | I23 |

   - Ajudante: `python3 ~/.claude/plans/2026-10-03-helpers/resolved.py` (o cabeçalho dele diz o
     uso). Ele põe ` RESOLVED by <hashes>.` numa linha do corpo que ainda caiba em 120 caracteres.
   - Prove cada hash: `git merge-base --is-ancestor <hash> HEAD` → rc 0.
   - Os 7 itens decididos já saíram no I1, I2 e I4. Achado nascido na leva (N) **não** recebe
     `RESOLVED by`.
2. **Emendas da ADR**, cada uma no estilo do cabeçalho do próprio arquivo:
   - **0004** (linha `Date: … · Status: accepted`): acrescente uma linha
     `Amended by: 0015 (§1: the stamp is not headless — the operator stamps after the bots; agents/ joins the key)`,
     no molde da linha `Amended by:` da 0003.
   - **0011, 0013 e 0014** (bullets `- **Status**`): acrescente
     `- **Amended by**: 0015 (§N: …)`, com o parágrafo de cada uma: §2 na 0011, §3 na 0013 e §1 na
     0014, onde "four directories" vira cinco.
   - Na própria 0015, o `- **Status**: proposed (—, 2026-10-04)` vira `accepted (—, <data do fecho>)`.
     O `sdd adr check` só lê `Spec:`; o Status é para o leitor.
3. **Glossário (`CONTEXT.md`)**: um verbete curto, até 4 linhas, para cada termo do D1 do
   `00-missao.md`, na seção de verbetes, no molde dos que já existem:
   - commit de registro;
   - símbolo designado;
   - censo de superfície;
   - fase feita à mão (evento `manual`, `sdd note-manual`);
   - retrato de lançamento (`runner_sha`);
   - o carimbo não é headless.
4. **Varredura de drift**, só o que os incrementos não fecharam. Rode e corrija cada resto:
   - `grep -n 'bin/ tests/ templates/ config/' CLAUDE.md docs/*.md .claude/rules/*.md README.md`:
     onde a chave do carimbo é descrita, ela passa a incluir `agents/` (I12; `docs/failure-modes.md:948`
     já foi no I12).
   - `.claude/rules/anatomia-do-agente.md`: **confira** que cada incremento da tabela "A anatomia do
     agente muda no MESMO commit" (§ Passo 0) deixou a sua seção; corrija o que faltou.
   - `docs/pipeline.md`:
     - o enum de eventos do ledger com 6 (I17/I18);
     - o campo `runner_sha` (I15);
     - a fase PR, que para no carimbo (I13).
     O incremento que mexeu em cada ponto já devia ter mudado a prosa; aqui só se confere.
   - `README.md`: a lista de comandos ganha `sdd note-manual` e o `--red` do `check-checkpoint.sh`,
     se o README lista modos de sensor.
5. **`KAIZEN_LOG.md`**: entrada nova no topo, `## <AAAA-MM-DD> — Lote 4: a catraca zera`, no molde da
   entrada do lote 3, com **Problema**, uma tabela **Medição** (antes `fe9441d` × depois, topo da
   branch), **Contramedida**, **Achados nascidos na leva** e **Ainda não medido** (o `sdd health`).
   Antes, medidos no planejamento:

   | Fato | Antes |
   |---|---|
   | Catraca | 23 → 16 + N na branch → 0 + N depois do chore |
   | Catálogo | 593 → ~612 (conte com `grep -cE '^mut_[A-Za-z0-9_]+\(\)' tests/check-mutation.sh`) |
   | Suíte | 306 s, 1790 linhas `ok` |
   | Âncora podre que passa (modelo do I5) | 26,1% → 12,7% |
   | `run_id` do kit com mais de um `kit_sha` | 22 de 35 |
   | Linhas do ledger para fase feita à mão | 0 |
   | Sessões PR do kit esperando o health | US$ 39,13 e 4,6 h em 19 sessões |

   Todo número "depois" sai de comando rodado no topo da branch, nunca da cabeça.
6. **Handoff da EXEC**: `docs/handoffs/20261004-lote-4-a-catraca-zera/20-handoff-exec.md`, a partir
   de `templates/handoff.md`, no molde do `20-handoff-exec.md` do lote 3:
   - frontmatter com `gate:` medido;
   - TL;DR de até 20 linhas;
   - a lista de commits por incremento;
   - § Boot da próxima fase, que é o § "Depois do checkpoint" deste plano;
   - § Pendências.
7. **Suíte inteira e âncoras**:
   - `env -u CLAUDECODE TMPDIR=/tmp bash tests/run-all.sh` → `suite green`;
   - `tests/check-mutation.sh --anchors` → `all <N> mutants still apply`;
   - `bash tests/check-todo.sh` → `16 + N finding(s) … every anchor on target`, com
     `tests/health-baseline.txt` dizendo o mesmo número.

**Onde:** `TODO.md`, `docs/adr/0004-*.md`, `0011-*.md`, `0013-*.md`, `0014-*.md`, `0015-*.md`,
`CONTEXT.md`, `KAIZEN_LOG.md`, os arquivos da varredura de drift, e o
`20-handoff-exec.md`.

**Como (TDD):** o Check abaixo vem primeiro. No início da branch (passo 0 feito) ele dá `0 0 0 0 0`.

**Check:** `a=$(awk '/<!-- sdd:open -->/{o=1} /<!-- sdd:decided -->/{o=0} o && /RESOLVED by/{n++} END{print n+0}' TODO.md); b=$(awk '/^## .* — Lote 4: a catraca zera/{c++} END{print c+0}' KAIZEN_LOG.md); c=$(cat docs/adr/0004-*.md docs/adr/0011-*.md docs/adr/0013-*.md docs/adr/0014-*.md); d=$(awk '/Amended by.*0015/{n++} END{print n+0}' <<< "$c"); e=$(awk '/^- [*][*]Status[*][*]: accepted/{n++} END{print n+0}' docs/adr/0015-the-stamp-is-not-headless.md); f=$(awk 'END{print (NR>0)}' docs/handoffs/20261004-lote-4-a-catraca-zera/20-handoff-exec.md 2>/dev/null); echo "$a $b $d $e ${f:-0}"` → `16 1 4 1 1`

**Sensor durável:** os de cada incremento. Este só fecha a contabilidade: `check-todo.sh` (forma e
contagem), catraca do `sdd health`, e `sdd adr check` (vínculo da 0015).

**Saída do item:** os 16 com `RESOLVED by`. Eles só saem no chore pós-merge, que fica fora da branch.

**Âncoras do TODO.md que o incremento desloca:** nenhuma de código. O `resolved.py` só acrescenta
texto ao corpo do item, e o lint confere o teto de 8 linhas e de 120 caracteres.

**Reversível por:** `git revert` do commit.

## Depois do checkpoint (decisão 6 — sem incremento)

1. **Push e PR.** `git push -u origin fix/lote-4-a-catraca-zera` e um PR contra a `main`. O repo é
   **público**, mas o Actions não entra: a verificação é local (`CLAUDE.md` global). O corpo leva:
   - o saldo "23 → 0 + N nascidos";
   - a lista dos 16 `RESOLVED by` e das 7 saídas (Y7, Y8 e os 5 decididos);
   - a ADR 0015 e as quatro emendas;
   - o catálogo 593 → ~612;
   - as mudanças de comportamento: o `sdd run` para no carimbo com rc 2 (I13); a volta 1 lê o config
     da branch da missão (I16); o `/sdd-plan` pergunta YES/NO (I6); o slot de símbolo passa a ser
     obrigatório (I5);
   - o yokoten dos alvos (§ Pendências do `00-missao.md`).
2. **Esperar TODOS os bots** (CodeRabbit, Copilot, Codex) e consertar numa leva só. Achado de bot é
   hipótese até medir.
3. **`./bin/sdd health` UMA vez**, depois do último commit de código e com os bots respondidos.
   - Leva ~45–55 min com ~612 mutantes; foram 39 min com 580.
   - Quem dispara é o humano, com o lançador desanexado.
   - Ele carimba, e o `gate_PR` exige o carimbo. Rodada que só mexe em prosa fora da chave não pede
     outro.
   - ⚠️ Desde o I12 a chave inclui `agents/`.
4. **Merge pelo humano.**
5. **Chore pós-merge**, numa branch `chore/todo-pos-merge-lote-4`:
   - apaga os 16 itens, provando cada um com `git merge-base --is-ancestor <hash> origin/main`
     (ajudante `~/.claude/plans/2026-10-03-helpers/todo_rm.py`);
   - catraca 16 + N → 0 + N;
   - PR e merge.
6. **Re-sync do espelho de issues, na `main` atualizada.** Com
   `S=~/.claude/skills/todo-to-github-issues/scripts/todo_issues.py`, a sequência é: `python3 $S`
   (plano) → `--apply --limit 1` (canário) → `--apply` → `--apply --close-orphans`.
   - Os 16 consertados fecham como `fixed by <hash>`.
   - As 7 saídas fecham à mão: `gh issue close N -R j0ruge/sdd_agents --reason "not planned"
     --comment "<destino>"`. São #88 (Y7), #218 (Y8), #130, #155, #109, #180 e #135 (decididos).
   - Os nascidos viram CREATE.
   - Conte: `gh issue list -R j0ruge/sdd_agents --label todo --state open --limit 200 --json number
     --jq length` = a catraca.

## Riscos e não-feitos

| Risco | Probabilidade | Mitigação |
|---|---|---|
| Âncora do `TODO.md` deslocada deixa o `check-todo.sh` (no `TEST_CMD`) vermelho | alta — medido em todos os protótipos de runner | `check-todo.sh --anchors` + `remap.py <rev-anterior>` + `xref.py HEAD --fix` antes de TODO commit; desde o I5 a dica nomeia o símbolo certo |
| Dois incrementos de designers diferentes colidem num mesmo arquivo (ledger, `gate_PR`, `check-hat`, `check-gates`, `check-autonomy`, `CATALOG`) | média | o sensor inteiro do ponto de contato roda a cada commit; `--anchors` a cada commit em `bin/`; mutante cuja âncora mudou é re-ancorado e re-provado com `--only` no mesmo commit |
| O I5 deixa mais vermelho nos alvos que rodam `--check` sem `--baseline` (`sales_quote` 110 → 209 violações) | certa, mas sem mudar veredito (os 8 alvos com itens já reprovam hoje) | declarado no PR; a skill `todo-to-github-issues` (`SKILL.md:124`) descreve a regra antiga, e o retrofit dela é no marketplace, fora do kit (Pendências) |
| O `--red` (I7) recusa célula com vários pares `` `cmd` → `x`; `cmd2` → `y` `` | certa no primeiro plano de alvo (5 de 58 linhas do `sales_quote` estão na forma estrita) | falha fechada decidida; o chapéu do planner ensina a forma `echo "$a $b"` (I8) |
| Comportamento novo do I16 (a volta 1 lê o config da branch da missão) surpreende um alvo | baixa | declarado no PR e no `config/schema.md` |
| O reset do marcador `GATE_PR_STAMP_WHY` não tem probe (nenhum cenário o alcança) | baixa | declarado no comentário do gate (I13) |
| O `sdd retry PR` não para no carimbo | baixa | limite declarado (I13) |
| Config quebrado no meio do run morre pelo mesmo `die` do lançamento, sem probe próprio | baixa | é o mesmo código chamado de novo; declarado (I16) |
| A sessão perde o fio entre incrementos | média | checkpoint + `checkpoint-notas.md` são a trilha; cada incremento fecha com commit |
| O `sdd health` some no meio (kill, terminal fechado) | baixa | lançador desanexado; o carimbo só nasce verde |
| A revisão dos bots pede conserto em `bin/`/`tests/`/`agents/` depois do health | média | health só depois de todos os bots (passo 3) |
| O I6 e o I21 mudam o `/sdd-plan` do humano na hora (symlink) | certa | o texto novo é compatível: com `auto` ele só informa |

**Não-feitos deliberados:**
- migrar os checkpoints legados presos (fora de escopo);
- o token `waiting` (Y8);
- dividir o `docs/pipeline.md` (#130);
- o juiz pontuar a linha `manual` (rubrica nova, pediria ADR);
- o `sdd note-manual` escrever no `pipeline.log`;
- recusar o `note-manual` depois do merge (cai no resíduo declarado do `mission_qa_report`);
- yokoten nos alvos (humano);
- retrofit da skill `todo-to-github-issues` (marketplace).

## Verificação end-to-end

1. **No topo da branch**, depois do I24:
   - `env -u CLAUDECODE TMPDIR=/tmp bash tests/run-all.sh` → `suite green` (rc 0);
   - `tests/check-mutation.sh --anchors` → `all <~612> mutants still apply and leave valid code`;
   - `bash tests/check-todo.sh` → `<16 + N> finding(s) … every anchor on target`;
   - `awk '/^todo-findings /{print $2}' tests/health-baseline.txt` → o mesmo número.
2. **As 7 saídas.** Nenhum dos 7 títulos está na seção aberta. Há 5 registros decididos novos e as
   linhas `Y7` e `Y8` no `CONTEXT.md`.
3. **Os 16.** `RESOLVED by` em cada um, com `git merge-base --is-ancestor <hash> HEAD` verdadeiro.
   O Check do I24 dá `16 1 4 1 1`.
4. **ADR:**
   - `./bin/sdd adr check` → rc 0, `ADR_CHECK=block`, nenhuma missão sem `adr:` decidido;
   - a 0015 aparece com `and that ADR points back`;
   - as quatro emendadas trazem `Amended by: 0015`.
5. **Espelho:** `for f in agents/sdd-*.md; do cmp -s "$f" ".claude/agents/$(basename "$f")" || echo "$f"; done`
   → nada; `./bin/sdd preflight` sem `agent <nome> stale`.
6. **Depois do health:** `sdd health` verde, carimbo válido; `./bin/sdd why 20261004-lote-4-a-catraca-zera PR`
   sem a recusa do carimbo.
7. **Depois do merge e do chore:** catraca 0 + N, e espelho de issues igual à catraca.
