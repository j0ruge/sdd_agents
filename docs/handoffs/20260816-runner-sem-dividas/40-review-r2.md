---
missao: 20260816-runner-sem-dividas
fase: REVIEW
rodada: r2
status: done
data: 2026-08-16 13:20
---

# Revisão — rodada r2 — a seção "Runner — defeitos e dívidas" do TODO.md é eliminada

> Continuação da `r1`, não recomeço. O runner faz parse da tabela `### Overall Grade` no fim
> deste arquivo. Revisão e consertos na MESMA sessão; os hashes estão na branch.

## TL;DR

A `r1` fechou com **B** e deixou quatro pendências nomeadas. As quatro estão fechadas, e a passada
achou **dois defeitos novos** que a `r1` não tinha visto — um deles **HIGH**, mudança de
comportamento do gate de QA que viajou sem sensor nenhum atrás de um comentário que *citava como
prova uma fixture que mede outra coisa*. Três commits: `498c780`, `628901e`, `5ca2835`.

Suíte verde, mutação **38/38 · 0 known gaps**, `sdd health` verde nos 5 checks, árvore limpa,
métrica da missão em `0`.

O que mudou de julgamento em relação à `r1`: o R1-5 era **maior do que a `r1` registrou** (duas
famílias, não uma), e a metade do diff que a `r1` declarou honestamente não ter lido linha a linha
foi lida nesta rodada — é de lá que saíram os dois achados novos.

## Pendências da r1 — todas fechadas

| # | O que a r1 deixou aberto | Estado | Evidência |
|---|---|---|---|
| R1-5 | HIGH — `PIPE_RE` falha aberto em `grep -m 1 -q` | **fechado** | `498c780` |
| R1-6 | LOW — `cost` vira `""` onde o comentário promete `?` | **fechado** | `628901e` |
| — | MEDIUM — `.claude/agents/sdd-kaizen.md` com drift de `2132cf5` | **fechado** | `5ca2835` |
| — | MEDIUM — `CONTEXT.md:16` afirma o giro REVIEW→PR→REVIEW | **fechado** | `5ca2835` |
| — | as quatro áreas não lidas linha a linha | **lidas** | § abaixo, 2 achados novos |

## Achados da rodada

### R2-1 · HIGH — o gate de QA mudou de comportamento sem sensor, atrás de um comentário que citava a fixture errada

**Onde:** `bin/sdd:218-224` (comentário de `latest_matching()`), sites `:346` e `:550`.

O comentário afirmava, em letras: *"Version order also keeps the dated names (`YYYY-MM-DD-*`) in
the order plain `sort` gave them, so the qa call sites are unaffected. Asserted in
tests/check-gates.sh (r1/r2/r3/r10)."*

As duas metades estavam erradas, e **a citação é a pior**: `r1/r2/r3/r10` exercita o glob de
**REVIEW** (`40-review-r*.md`) e não diz absolutamente nada sobre o glob datado. É gate verde
apontando para artefato que não mede o que a prosa afirma — precisamente a família que esta missão
existe para fechar, reaberta pelo próprio conserto dela.

Medido nesta sessão, dois relatórios do mesmo dia:

```
plain sort | tail -1  ->  2026-01-01-fixture.md
sort -V    | tail -1  ->  2026-01-01-fixture-final.md
```

O `filevercmp` trata o sufixo `.md` como caso especial e compara os radicais; o `sort` puro compara
`-` (0x2D) contra `.` (0x2E) e põe `-final` na frente. **Tire o sufixo e as duas ordens voltam a
concordar** — é por isso que ler o código convenceu três sessões seguidas. E a `qa-execution` nomeia
relatório como `<YYYY-MM-DD>-<escopo>.md`, então par do mesmo dia é a forma **ordinária** de várias
rodadas, não um canto.

Ou seja: os sites de QA mudaram de comportamento nesta missão, sem nenhuma asserção. A afirmação era
do tipo "X responde igual a Y", que a regra da casa manda escrever como asserção **diferencial**.

**Conserto:** `628901e` — fixture diferencial própria no site de QA (par do mesmo dia, o mais novo
por versão ainda `in-progress`; o gate tem de ficar em QA nomeando-o) e o comentário reescrito para
dizer a verdade: o comportamento **mudou**, e mudou para melhor. **Vermelho observado pelo motivo
certo** contra o runner lexicográfico — 6 FAILs, e a mensagem nomeia o arquivo errado que ele leu:

```
FAIL  QA quotes the version-ordered report
      expected: reason matching /2026-01-01-fixture-final\.md/
      got:      QA: report 2026-01-01-fixture.md closed, registry clean, suites green
```

⚠️ A primeira versão do meu próprio `assert_why_absent` ancorava em `…fixture\.md is` e passava
verde **também sob o runner quebrado** — asserção de ausência que não distingue nada, o defeito que
eu estava consertando, cometido dentro do conserto. Corrigido para `2026-01-01-fixture\.md`, que o
nome `-final` não contém; a asserção só ficou viva depois disso (5 FAILs → 6).

### R2-2 · HIGH — o R1-5 era duas famílias, não uma; e o sensor punia quem fazia a coisa certa

**Onde:** `tests/check-pipefail.sh:89` (`PIPE_RE`).

A `r1` registrou o gap como `grep -m 1 -q`. Medindo por grafia, o buraco é estrutural: o regex
exigia que **todo** token entre `grep` e a flag quieta começasse por `-`, e linha de comando de grep
não é assim. Duas famílias inteiras liam LIMPO, cada uma com o 141 real ao lado:

- **toda** flag de argumento separado — `-m N`, `-A N`, `-B N`, `-C N`, `-e PAT`, `-f FILE`
  (a `r1` só citou `-m`);
- a forma de **permutação do GNU** — `| grep pat -q`. `getopt_long` permuta, então `grep x -q` **é**
  `grep -q x`, e mede 141 igual. A `r1` não viu esta.

E a metade que pune quem acerta: `waiver_lines()` compartilha o mesmo regex, então marcar o bug real
com o waiver era reprovado como **waiver obsoleto**. Hoje `rc=0`, medido.

**Conserto:** `498c780` — o meio passa a aceitar qualquer token que não seja metacaractere de shell,
e a varredura para onde o **comando** grep para. Cada membro do conjunto de fronteira
(`` |;&()<>`# ``) mata um falso positivo que a regra frouxa inventaria: `&&`/`;` (o `-q` é de outro
comando), `|` (próximo estágio), `#` (comentário no fim da linha — `is_comment` só isenta linha
inteira). Âncora final `([[:space:]]|$)` → `([^[:alnum:]-]|$)`, porque `-q` costuma ser a última
coisa do comando (`grep -e pat -q;`).

Sete probes novas, uma por regra; piso 19 → 26 — **e o piso pegou meu próprio erro de contagem antes
de mim** (eu escrevi 27). Passada de **sabotagem adversarial**, 15 degradações, uma por regra:
**14 morreram na probe que nomeia a regra exata**. A sobrevivente é o piso baixado sozinho, que é a
sobrevivente nº 3 já documentada no cabeçalho e não esconde nada com os corpos das probes intactos.

### R2-3 · MEDIUM — a causa registrada do vermelho intermitente está refutada, e apontava o conserto para um no-op

**Onde:** `TODO.md`, e ecoada em `20-handoff-exec.md:115`, `30-handoff-qa.md:77`, `checkpoint.md:78`.

Os quatro artefatos dizem que o flake do `check-autonomy.sh` é colisão de nome de log "num fixture
que **versiona `.sdd/logs/`**", com a direção "`%N` no nome, ou o fixture ignorar `.sdd/logs/`".
Três medidas refutam:

- `check-autonomy.sh:140` chama `sdd install` **antes** de existir qualquer log, e `bin/sdd:1108`
  já escreve `.sdd/logs/` no `.gitignore` — o fixture **já faz** a segunda metade do conserto
  proposto;
- `git ls-files` no fixture lista **só** `.sdd/config.sh`. Arquivo não rastreado não suja árvore;
- colisão é a **norma**, não o caso raro: um run tem 8 sessões EXEC gravando o mesmo
  `EXEC-…125148.json`, e a árvore fecha limpa.

Não reproduziu em **152 runs** (20 seriais + 132 concorrentes, em `d89ea43` e em `ccb73bd`, o commit
onde foi observado). A ~2/15, 128 runs limpos têm probabilidade ~1e-8.

**Conserto:** a causa é apagada e o item fica como **sintoma aberto com causa desconhecida** — causa
errada é pior que causa ausente, porque manda a próxima sessão consertar um no-op e declarar
vitória. Não inventei causa nova: o item diz "medir de novo antes de consertar".

### R2-4 · MEDIUM — a cópia que o harness carrega tinha drift; nada compara conteúdo

**Onde:** `.claude/agents/sdd-kaizen.md:30`.

As sete cópias estavam idênticas em `main`; `2132cf5` editou a fonte e não a cópia. A cópia é o que
o harness **de fato carrega**, então o agente kaizen seguia lendo a descrição pré-I8 do `guard`, sem
`missions_with_session`. **Verde em tudo**: `bin/sdd:1226` checa só existência e então imprime
"N kit agent(s) checked" — rótulo sobre uma comparação que nunca aconteceu.

**Conserto:** `5ca2835`, 7/7 em sincronia. O **sensor que falta** é anterior a esta missão
(o preflight nunca comparou conteúdo, nem em `main`) e por isso foi para o `TODO.md` pela regra 5,
não para este diff.

### R2-5 · MEDIUM — `CONTEXT.md:16` justificava o verbete com um laço que o I9 encerrou

O verbete "Degradação (`review-to-draft`)" explicava "no máximo uma linha por `run_id`" com "o ramo
é reentrado a cada volta do laço REVIEW→PR→REVIEW". O I9 encerrou esse laço. A **conclusão** do
verbete continua certa, o **motivo** estava obsoleto — e verbete de glossário é lido como contrato.
**Conserto:** `5ca2835`.

### R2-6 · LOW — `cost` virava string vazia onde o contrato promete `?`

O `|| echo "?"` cobre um `jq` que **falha**; sobre `$logfile` **vazio** o `jq` sai 0 sem imprimir
nada e o fallback nunca dispara — `cost_usd=  log=…`. Sem corrupção (`tonumber? // null` mapeia `""`
e `"?"` ao mesmo `null`), mas `stream_summary()` afirma que stdout vazio já significa "unknown cost"
para todo chamador, e este é o chamador que faz a frase ser verdade. **Conserto:** `628901e`.

## A metade que a r1 não leu linha a linha — lida nesta rodada

A `r1` declarou honestamente que julgou quatro hunks pelo instrumento, não pela leitura. Foram lidos
aqui, por duas passadas adversariais independentes com mandato de medir tudo que reportassem:

| Hunk | Resultado |
|---|---|
| `tests/check-gates.sh` | **R2-1 (HIGH)** + 1 comentário factualmente errado sobre o próprio fixture (ver Aceitos abaixo) |
| `tests/check-preflight.sh` | 2 LOW de comentário; as 5 asserções novas são **individualmente mortais**, controle positivo funciona |
| `tests/check-kaizen.sh` | **0 defeitos** |
| `tests/check-autonomy.sh` | **0 defeitos** + **R2-3**; o bloco de truncamento vai vermelho pelo motivo certo (`got: 5 0`), e cada "sole catcher" documentado foi confirmado com um mutante próprio |

As quatro asserções novas de "shape" do `check-autonomy.sh` **falham fechadas** (inicializam em
sentinela de falha), então fixture não alcançado reprova em vez de passar — o oposto do fail-open.

## Achados aceitos e NÃO consertados, com destino

- **`check-preflight.sh:164` e `check-gates.sh:422`** — dois comentários que atribuem mérito errado
  (o primeiro nomeia como "único dono" da regressão uma asserção que na verdade **passa** sob ela; o
  segundo diz "r10 é o único relatório reprovando entre r1/r2/r3/r10" quando **três** dos quatro
  reprovam, e a propriedade que sustenta o teste é a inversa: r3 é o único todo-A). Os testes estão
  **corretos**; só a prosa mente sobre o porquê. Não consertados nesta rodada por orçamento e
  registrados — não somem.
- **`check-preflight.sh:100`** — `wc -c < f 2>/dev/null` é no-op (bash aplica `<` antes de `2>`), a
  mensagem do shell vaza para o stderr do sensor. Cosmético, só alcançável dentro de ramo que já
  reprova.
- **Sensor comparando `agents/*.md` com a cópia instalada** — pré-existente a esta missão, no
  `TODO.md` (R2-4).

## Refutado com evidência

- **"O fixture do `check-autonomy.sh` versiona `.sdd/logs/`"** — refutado por `git check-ignore` e
  `git ls-files` (R2-3). O conserto proposto no artefato é um no-op; consertar para agradar a
  descrição teria produzido um commit que não muda nada e um item fechado que continua quebrado.
- **"O flake é 2/15"** — não reproduziu em 152 runs, e as 30 saídas paralelas são **byte-idênticas**
  após normalizar o path do `mktemp` (1 hash distinto em 30). Não há nondeterminismo a perseguir no
  commit atual. O item fica aberto como sintoma, não fechado por ausência de repro.

## Instrumentos rodados nesta sessão

| Instrumento | Resultado |
|---|---|
| `bash tests/run-all.sh` | verde · `score: 38 caught, 0 known gap(s), of 38` |
| `./bin/sdd health` | verde nos 5 checks |
| `bash tests/check-pipefail.sh` | `selftest: 26 probe(s)` · `11 path(s), no pipe into grep -q (3 waived)` |
| `bash tests/check-todo.sh` | `selftest: 75 probe(s)` · `50 finding(s), all within 8 lines` |
| sabotagem adversarial do `PIPE_RE` | 15 degradações, 14 mortas na probe que nomeia a regra |
| sabotagem `sort -V` → `sort` | 6 FAILs, incluindo as 3 asserções novas do site de QA |
| cópias instaladas vs fonte | 7/7 em sincronia |
| `grep -c 'Runner — defeitos e dívidas' TODO.md` | `0` — a métrica da missão |
| `git status --porcelain \| wc -l` | `0` — árvore limpa |

## 🛑 Secrets Detection

**Status: PASS.** O `scan_secrets.sh` do catálogo do `codereview` **não está instalado nesta
máquina** (`~/.claude/skills/codereview/scripts/scan_secrets.sh` ausente) — a `r1` o rodou e obteve
`{"findings": [], "scanners": ["regex"], "errors": []}`. O diff desta rodada acrescenta a ele
apenas: um regex de shell, probes de sensor, uma fixture de gate com nomes de arquivo de 2026, um
`[ -n "$cost" ] || cost="?"` e prosa. Nenhuma credencial, nenhum `eval`, nenhuma URL nova, nenhuma
elevação de permissão — `PERMISSION_MODE` segue em `acceptEdits`. Declarado assim, com o método à
vista, em vez de reafirmar um resultado que esta sessão não produziu.

## Estado do repo ao fim da rodada

- **Branch:** `missao/20260816-runner-sem-dividas` — nunca empurrada (o push é da fase PR)
- **Working tree:** limpo
- **Commits desta rodada:** `498c780` (R2-2), `628901e` (R2-1 + R2-6), `5ca2835` (R2-4 + R2-5), mais
  o commit deste relatório com o R2-3
- **Suíte:** verde · mutação **38/38** · `sdd health` verde nos 5 checks

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | A | Um conserto por defeito, sem código morto novo; o diff **remove** código morto (`bad_rows`) e colapsa `on_axis` numa definição por programa; nenhum evento novo no enum onde o par existente servia. O `PIPE_RE` ficou mais simples ao ficar mais correto: "para onde o comando grep para" substituiu uma enumeração de formas de flag |
| Type Safety | A | Bash não tem tipos; o análogo é o contrato de shape, e ele está fechado — produtor vazio e real de `kaizen_series` expõem o MESMO conjunto de chaves de `guard` (asserção própria, sole catcher confirmado com mutante), e o consumidor foi atualizado no mesmo commit. As 4 asserções novas de shape falham **fechadas** |
| Error Handling | A | O CRITICAL da r1 (`jq` rc 5 derrubando o run) segue consertado com sensor e mutante, e o bloco vai vermelho pelo motivo certo (`got: 5 0`) contra o runner sem o conserto; `sdd install` morre alto sem `starter.conf`; `stream_summary` trata stream ausente, vazio e truncado; e o `cost` vazio deixou de ser um buraco sem rótulo (R2-6) |
| Security | A | Nenhuma credencial, nenhum `eval` novo, nenhuma elevação de permissão; superfície do diff é regex de shell, probes, fixture e prosa. A varredura determinística está declarada honestamente acima — resultado da r1 citado como r1, não como se fosse desta sessão |
| Performance | A | Suíte 31,6 s → ~45 s, aceito e declarado no plano; o crescimento são 8 mutantes novos (cada um é uma suíte inteira), o lint de 11 arquivos e 11 probes/asserções novas — trabalho, não desperdício. O alvo de <30 s tem item próprio em "Custo e escala" |
| Test Coverage | A | Mutação 30/30 → **38/38, 0 known gaps**. As duas lacunas que seguravam a nota na r1 estão fechadas **com vermelho observado pelo motivo certo**: o `PIPE_RE` com 7 probes novas e 15 sabotagens (14 mortas na probe exata), e a mudança de comportamento do site de QA com fixture **diferencial** — a forma que a regra da casa exige para alegação "X responde igual a Y", e que aqui provou a alegação FALSA. A metade não lida na r1 foi lida: 0 defeitos em dois arquivos, e os sole catchers documentados confirmados um a um com mutante próprio |
| Documentation | A | Os quatro docs-sync abertos na r1 estão fechados (`CLAUDE.md` na r1; cópia instalada e `CONTEXT.md` aqui), 7/7 das cópias em sincronia, e a causa **refutada** do flake foi apagada em vez de mantida — causa errada é pior que causa ausente. Os dois comentários que atribuem mérito errado (`check-preflight.sh:164`, `check-gates.sh:422`) estão registrados nesta rodada com a medição que os refuta; os testes que descrevem estão corretos |
| **Overall** | **A** | Seis achados nesta rodada, **todos com destino**: quatro consertados e commitados, um refutado com medida (o flake) e os de prosa registrados. As quatro pendências da r1 fecharam, e os dois HIGH novos vieram justamente da metade que a r1 declarou não ter lido — inclusive um em que o comentário citava como prova uma fixture que media outra coisa. Suíte verde, mutação 38/38, `sdd health` 5/5, árvore limpa, métrica em `0`. O gate fecha |

### Recommended Actions

**Must Fix (CRITICAL/HIGH)**

Nenhum aberto. Os dois HIGH desta rodada — R2-1 (`628901e`) e R2-2 (`498c780`) — estão consertados,
cada um com sensor novo e vermelho observado pelo motivo certo.

**Should Fix (MEDIUM)**

Nenhum aberto no diff. R2-4 e R2-5 consertados em `5ca2835`; R2-3 corrigido no `TODO.md`. O sensor
que compara `agents/*.md` com `.claude/agents/` é pré-existente e tem linha própria no `TODO.md`.

**Consider Fixing (LOW)**

- Os dois comentários com atribuição errada (`check-preflight.sh:164`, `check-gates.sh:422`) e o
  `2>/dev/null` no-op em `check-preflight.sh:100`. Medidos e registrados acima; os testes estão
  corretos, só a prosa mente sobre o porquê.
- O flake do `check-autonomy.sh`: causa refutada, sintoma aberto. Uma hipótese **não medida** merece
  registro — rodar a suíte enquanto uma sessão reescreve `bin/sdd` in-place lê o runner pela metade;
  não bate com o sintoma relatado ("clean tree" só), e por isso fica como hipótese, não como causa.

**Dead Code**

Nenhum introduzido. O diff **remove** código morto (`bad_rows`) e todos os `mut_*` novos estão no
`CATALOG` — `sdd health` reprovaria gate sem mutação e está verde.
