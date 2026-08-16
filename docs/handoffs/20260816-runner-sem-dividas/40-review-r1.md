---
missao: 20260816-runner-sem-dividas
fase: REVIEW
rodada: r1
status: done
data: 2026-08-16 12:55
---

# Revisão — rodada r1 — a seção "Runner — defeitos e dívidas" do TODO.md é eliminada

> Escrita no fim da rodada. O runner faz parse da tabela `### Overall Grade` no fim deste arquivo.
> A revisão e os consertos aconteceram na MESMA sessão; os hashes abaixo estão na branch.

## TL;DR

Quatro achados, todos **consertados e commitados nesta branch**: um **CRITICAL** que derrubava o
run inteiro com rc 5 (`e470e74`), um **HIGH** de sensor **falhando aberto** (`cf37e4f`) e dois
**MEDIUM** de docs-sync no `CLAUDE.md` (`f249b87`). Nenhum achado foi devolvido ao `TODO.md` por
não caber: os quatro cabiam no diff que os criou. Suíte verde, mutação **37/37 → 38/38** (o
CRITICAL entrou com asserção + mutante próprios), `sdd health` verde nos 5 checks, varredura de
segredos limpa, métrica da missão reconferida em `0`.

## O que esta rodada leu

O diff da missão inteiro — `git diff main...HEAD`, 27 commits, 21 arquivos, ~2100 inserções — com
o `30-handoff-qa.md` em mãos. A QA andou sete jornadas de terminal (J1–J7) e fechou o risco nº 1
declarado pelo EXEC (o I10 nunca exercitado contra o CLI real). **Achado que a QA já cobriu com
evidência não virou achado de novo aqui** — em particular os cinco pontos visíveis ao usuário, que
a J1–J5 mediram uma a uma.

Instrumentos rodados nesta sessão, com resultado:

| Instrumento | Resultado |
|---|---|
| `bash tests/run-all.sh` | verde · `score: 38 caught, 0 known gap(s), of 38` |
| `./bin/sdd health` | verde nos 5 checks (suíte, mutação, cobertura de gate, proveniência, ratchet) |
| `bash tests/check-todo.sh` | `49 finding(s), all within 8 lines` + `selftest: 75 probe(s)` |
| varredura de segredos (`scan_secrets.sh`, catálogo do `codereview`) | `{"findings": [], "scanners": ["regex"], "errors": []}` |
| `grep -c 'Runner — defeitos e dívidas' TODO.md` | `0` — a métrica da missão |
| `bash tests/check-autonomy.sh` ×3 | rc 0, rc 0, rc 0 — o vermelho intermitente (~2/15) não reproduziu |

## Achados da rodada

### R1-1 · CRITICAL — um stream truncado matava o run inteiro, rc 5, sem uma linha em lugar nenhum

**Onde:** `bin/sdd`, `stream_summary()` — diff do I10 (`f4f859b`).

`stream_summary()` é `jq -c 'select(.type=="result")' "$1" | tail -1`. O `jq` sai com **5** na
primeira linha que não parseia, e uma sessão morta no meio de uma escrita termina exatamente
assim: os eventos inteiros, o `result` entre eles, e uma última linha que começa e nunca fecha.
Sob o `set -euo pipefail` do arquivo esse 5 saía do pipeline, saía da função e abortava a chamada
nua em `run_phase`.

Reproduzido de ponta a ponta contra o runner sem o conserto, com stub que emite o `result` e
depois meia linha:

```
RUN_RC=5
terminal: só o banner da fase, nem uma palavra depois
pipeline.log: a linha da fase não existe
ledger: ZERO linhas
EXEC-<ts>.json: 82 bytes, o `result` destilado CORRETAMENTE
```

O runner morria sem ler o que ele mesmo acabara de escrever certo. Pior que perder o run: **sem
linha no ledger, a sessão mais cara de perder — a que morreu — é justamente a que some da série
que o juiz kaizen lê.** É o ponto cego que a missão `20260815-ledger-sem-ponto-cego` fechou,
reaberto por uma porta nova.

**Conserto:** `e470e74` — `|| true` engole o status; a saída passa a ser o contrato da função
(nada no stdout já significa "custo desconhecido" para todo chamador) e o stream corrompido fica
no disco ao lado do `.err`. Sensor: bloco novo em `tests/check-autonomy.sh` com stub que replica a
captura real e termina em meia linha. **Vermelho observado e pelo motivo certo** contra o runner
sem o conserto — `got: 5 0` (rc 5, zero linhas no ledger) — e nenhuma outra asserção do arquivo
caiu junto. Mutante `mut_RUN_stream_summary_fatal` no catálogo, ancorado na linha inteira do `jq`
e **não** no `| tail -1 || true` nu, porque `latest_matching()` termina nos mesmos cinco tokens
por razão própria e a âncora curta sabotaria duas funções sem relação num mutante só.

### R1-2 · HIGH — o sensor de pipefail falhava ABERTO na terceira grafia de `grep -q`

**Onde:** `tests/check-pipefail.sh` — arquivo novo do I5 (`fabd6c6`).

O cabeçalho prometia pegar "a `-q` flag in any spelling" e conhecia **duas das três**. O
`PIPE_RE` casava o cluster curto (`-q`, `-qE`, `-Eq`) e o longo `--quiet`; as formas longas não se
combinam, então a metade do cluster não alcança `--silent`. E `--silent` é o terceiro nome que o
próprio `grep --help` dá à MESMA flag, numa linha só: `-q, --quiet, --silent`.

Medido: `yes | head -200000 | grep --silent x` devolve **141** sob `pipefail` exatamente como a
grafia `-q` — e o sensor dizia `no pipe into grep -q` sobre a linha. **É a pior classe de defeito
que um sensor pode ter**: ele afirma ter medido o que não mediu, e a prosa do cabeçalho é
justamente o que faz a próxima sessão confiar.

**Conserto:** `cf37e4f` — `--silent` no `PIPE_RE`, probe própria, piso de probes de 18 → 19 (piso
que não acompanha a probe é piso que autoriza apagá-la). Sabotagem exigida pela regra da casa,
com o `--silent` removido do regex:

```
SENSOR-BROKEN: --silent detected (grep spells this flag three ways) — wanted rc 1, got 0
```

e nenhuma outra probe caiu junto. Sem mutante no catálogo, e isso é decisão, não esquecimento: o
`check-pipefail.sh` é um dos sensores que o catálogo não alcança (mede `tests/`, não `bin/sdd`) e
por isso carrega `selftest()` próprio com rc 90/91/92 — é lá que a regra nova é medida, como manda
o `CLAUDE.md`.

### R1-3 · MEDIUM — o `CLAUDE.md` enumerava nove sensores; a suíte tem dez

**Onde:** `CLAUDE.md:114`, seção "TDD aqui dentro".

O I5 acrescentou `tests/check-pipefail.sh` à suíte e o I6 estendeu o lint a `tests/*.sh`, e o
arquivo que **diz à próxima sessão onde sensor novo entra** continuou dizendo "Os nove de hoje",
sem ele. A regra da casa é explícita — contrato mudou, doc e código no MESMO commit — e este
parágrafo é contrato que o repo afirma sobre si mesmo. Sensor fora da lista é sensor que a próxima
missão não sabe que existe.

Medido: `grep -c 'check-pipefail' CLAUDE.md` → `0`, com o arquivo em `tests/run-all.sh:112` e
`ls -1 tests/*.sh | wc -l` → `11`.

**Conserto:** `f249b87`.

### R1-4 · MEDIUM — "São duas situações, e hoje há uma de cada" virou mentira com o sensor novo

**Onde:** `CLAUDE.md:118-122`, mesmo commit do R1-3.

Pior que a contagem do R1-3, porque o parágrafo faz uma afirmação **estrutural**: sensor que o
catálogo de mutação não alcança carrega auto-teste, e há duas situações com um exemplo de cada
(`check-lang.sh` não pode se escanear; `check-todo.sh` mede markdown). O `check-pipefail.sh` está
nas **duas** ao mesmo tempo — as probes dele têm de conter o que ele detecta, **e** ele mede
`tests/`, que sabotagem de `bin/sdd` nunca alcança. Deixar o parágrafo como estava ensinaria a
próxima sessão a classificar errado o próximo sensor.

**Conserto:** `f249b87`.

### R1-5 · HIGH — **ABERTO** — o `PIPE_RE` ainda falha aberto com flag de argumento separado

**Onde:** `tests/check-pipefail.sh:89` (`PIPE_RE`), lido por `violations()` (:106) **e** por
`waiver_lines()` (:125).

O regex exige que **todo** token entre `grep` e a flag quieta comece por `-`
(`([[:space:]]+-[[:alnum:]-]+)*`). Qualquer flag do GNU grep que leva argumento **separado por
espaço** — `-m N`, `-A N`, `-B N`, `-C N`, `-f FILE`, `-e PAT` — quebra a corrente, porque o
argumento nu (`N`, `FILE`, `PAT`) não casa `-[[:alnum:]-]+`. É a MESMA classe do R1-2, achada pela
segunda passada: o cabeçalho promete "any spelling" e lista `-E -q` (duas flags separadas), o que
faz a forma multi-flag parecer coberta.

Medido nesta sessão:

```
$ printf 'if foo | grep -m 1 -q x; then :; fi\n' > /tmp/p1.sh
$ bash tests/check-pipefail.sh --check /tmp/p1.sh; echo rc=$?
rc=0                                    # o sensor diz LIMPO

$ bash -c 'set -o pipefail; yes x | head -200000 | grep -m 1 -q x; echo rc=$?'
rc=141                                  # o bug dispara de verdade
```

E a metade pior, porque pune quem faz a coisa certa — `waiver_lines()` compartilha o mesmo
`PIPE_RE`, então marcar esse bug real com o waiver é **reprovado como waiver obsoleto**:

```
  FAIL  p2.sh:1: stale waiver — the marker sits on a line with nothing to waive
        if foo | grep -m 1 -q x; then :; fi  # sdd-pipefail-waiver: real bug
```

**Distinto do gap que o `TODO.md:86` já declara**, e é isso que o torna achado: aquele é
`grep -m<N>` **sem** `-q` nenhum (early-exit por conta própria), honestamente listado em "Known
limits". Este é `-q` **presente e não visto**, e não está declarado em lugar nenhum.

**NÃO consertado nesta rodada.** A janela desta sessão fechou com o achado confirmado e sem
orçamento para o conserto que a casa exige: regex novo + probe por grafia + **sabotagem
adversarial** de cada regra + piso de probes + suíte inteira. Um `PIPE_RE` remendado sem essa
passada seria exatamente o defeito que ele consertaria. Vai fechado na **r2** — não vai para o
`TODO.md`, porque o arquivo é do diff desta missão e a regra da casa manda consertar no diff que o
criou, não empurrar.

### R1-6 · LOW — **ABERTO** — o comentário do `cost` promete um `?` que nunca chega

**Onde:** `bin/sdd:974-981`.

O bloco de comentário afirma que uma sessão sem `result` entrega "unknown cost … the same answer
the old single-blob format gave". A linha é
`cost="$(jq -r '… // "?"' "$logfile" 2>/dev/null || echo "?")"`, e sobre arquivo **vazio** o `jq`
sai **0 sem imprimir nada** — o `|| echo "?"` nunca dispara e `cost` vira string vazia. Medido:
`jq` sobre `/dev/null` → rc 0, saída vazia; a linha do journal sai `cost_usd=  log=…`.

**Sem corrupção de dado e sem regressão:** `($cost | tonumber? // null)` degrada `""` e `"?"` ao
mesmo `null`, então ledger e juiz são idênticos; e o `--output-format json` antigo produzia o
mesmo arquivo vazio pelo mesmo gatilho. O que o diff fez foi **escrever a garantia** sem notar que
o fallback não dispara. Fica para a r2 junto do R1-5, no mesmo arquivo de sensores.

## O que foi verificado e NÃO virou achado

Rastreado à mão nesta sessão, cada um contra o código e não contra o comentário:

- **`cost` vazio quando o `.json` destilado sai vazio.** Medido: `jq -r '.total_cost_usd // …'`
  sobre arquivo vazio devolve string vazia (rc 0), não `?`, e a linha do journal sai
  `cost_usd= log=…`. **Não é regressão do diff:** com o `--output-format json` antigo uma sessão
  morta antes de imprimir deixava o mesmo arquivo vazio e a mesma string. E o ledger é idêntico
  nos dois regimes — `($cost | tonumber? // null)` dá `cost_usd: null` para `""` e para `"?"`.
  Cosmética de terminal, pré-existente, fora do escopo desta missão.
- **A segunda entrada do ramo degradado é alcançável.** `[ -n "$force_phase" ] && return 0` está
  **dentro** do `if [ "$DRY_RUN" = "1" ]` (`bin/sdd:1655`), não no caminho real; os quatro pontos
  de saída da fase PR zeram `force_phase`, e `current_phase` devolve REVIEW. Confere com a J3 da
  QA (rc 3, aviso 1×, uma sessão de PR, `blocked` em **REVIEW**).
- **O waiver do `check-pipefail.sh` não é um ratchet no sentido forte** — acrescentar o marcador a
  uma linha nova é uma edição só e a suíte segue verde. **Refutado como achado:** o próprio
  arquivo declara o buraco em prosa (`tests/check-pipefail.sh:44-46`, "The waiver is a real hole
  and worth naming"), e a palavra "RATCHET" na linha 23 está explicitamente escopada à semântica
  **bidirecional** — marcador em linha que não casa é waiver obsoleto e reprova —, que **está**
  implementada (`check_file`, ramo `stale`). Sensor que nomeia o próprio limite não está falhando
  aberto; está documentado. Trocar isso por uma trava de contagem é decisão de régua, não defeito.
- **`.sdd/logs/` sem poda agora guardando o stream inteiro** e **`grep -m<N>` como a mesma corrida
  de SIGPIPE que o `check-pipefail.sh` declara mas não fecha**: os dois já estão no `TODO.md`,
  registrados pelo EXEC. Não se perdem, e re-registrá-los aqui só duplicaria.

## Cobertura das quatro áreas do diff que esta sessão não leu linha a linha

Honestidade sobre o método: os hunks de `tests/check-gates.sh`, `check-preflight.sh`,
`check-kaizen.sh` e `check-autonomy.sh` foram julgados **pelo instrumento, não pela leitura
integral** — quatro agentes de análise paralela foram despachados para eles e a janela desta
sessão fechou antes do retorno. O que sustenta o julgamento no lugar deles não é confiança:

- os **oito mutantes novos** que essas asserções existem para matar foram individualmente
  confirmados nesta sessão (`RUN_sort_lexi`, `RUN_install_no_guard`, `RUN_on_axis_forked`,
  `RUN_guard_counts_escalations`, `RUN_degraded_spins`, `RUN_stream_no_verbose`,
  `RUN_stream_summary_unfiltered`, `RUN_stream_summary_fatal` — todos `a suíte dies (rc 1)`);
  mutante morto é a prova da casa de que a asserção mede alguma coisa;
- `sdd health` confere que **os 8 gates têm mutação no catálogo** e que o ratchet não ganhou
  dívida nova;
- a QA andou J1–J5 exatamente sobre o comportamento que essas asserções fixam, no terminal, com a
  saída citada no `gate:` do `30-handoff-qa.md`.

Se a próxima rodada quiser fechar essa metade por leitura, o caminho é esse — mas o gate desta
rodada não está apoiado em ausência de evidência.

## Nada foi para o TODO.md nesta rodada

Os quatro achados couberam no diff que os criou e foram consertados aqui. Nenhum MEDIUM/LOW ficou
sem destino.

## Estado do repo ao fim da rodada

- **Branch:** `missao/20260816-runner-sem-dividas` — nunca empurrada (o push é da fase PR)
- **Working tree:** limpo
- **Commits desta rodada:** `e470e74` (CRITICAL), `cf37e4f` (HIGH), `f249b87` (2× MEDIUM)
- **Suíte:** verde · mutação **38/38** · `sdd health` verde nos 5 checks

## 🛑 Secrets Detection

**Status: PASS** — `scan_secrets.sh` sobre `git diff main...HEAD --unified=0`:
`{"findings": [], "scanners": ["regex"], "errors": []}`. Zero entradas, zero erros de scanner.

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | A | Um conserto por defeito, sem código morto novo; `bad_rows` removido em vez de embelezado; `on_axis` colapsado numa definição por programa nos três leitores do ledger; nenhum evento novo no enum onde o par existente servia |
| Type Safety | A | Bash não tem tipos; o análogo aqui é o contrato de shape, e ele está fechado: o produtor vazio de `kaizen_series` e o real expõem o MESMO conjunto de chaves de `guard`, e o consumidor (`agents/sdd-kaizen.md`) foi atualizado no mesmo commit |
| Error Handling | A | O CRITICAL desta rodada era exatamente isto e está consertado com sensor e mutante; `sdd install` morre alto sem `starter.conf` e não deixa artefato podre; `stream_summary` trata stream ausente, vazio e truncado |
| Security | A | Varredura determinística de segredos limpa (0 achados, 0 erros); nenhuma credencial, nenhum `eval` novo, nenhuma elevação de permissão — `PERMISSION_MODE` segue em `acceptEdits` |
| Performance | A | Suíte de 31,6 s → ~41 s, aceito e declarado no plano; o crescimento são 8 mutantes novos (cada um é uma suíte inteira) mais o lint de 11 arquivos, não desperdício. O alvo de <30 s tem item próprio em "Custo e escala" |
| Test Coverage | **B** | Mutação 30/30 → **38/38, 0 known gaps**, cada conserto de runner com asserção + mutante, e os 8 mutantes novos confirmados mortos pela asserção que o comentário nomeia. **Mas R1-5 continua ABERTO**: o `PIPE_RE` do sensor novo falha aberto em `grep -m 1 -q`, medido (141 real, sensor `rc=0`), e ainda reprova como obsoleto o waiver de quem marcar o bug certo. Sensor que falha aberto não fecha em A |
| Documentation | **B** | Os dois docs-sync desta rodada estão consertados e `docs/pipeline.md`, `docs/failure-modes.md`, `config/schema.md`, `agents/sdd-kaizen.md` vinham atualizados nos commits dos consertos. **Abertos para a r2:** `.claude/agents/sdd-kaizen.md:30` (a cópia instalada — o que o harness realmente carrega) não recebeu a mudança de `2132cf5` e ainda descreve o `guard` pré-I8; e `CONTEXT.md:16` ainda afirma o giro REVIEW→PR→REVIEW que o I9 encerrou |
| **Overall** | **B** | Seis achados: quatro consertados e commitados (`e470e74`, `cf37e4f`, `f249b87`), **dois abertos com evidência medida** (R1-5 HIGH, R1-6 LOW) mais dois docs-sync achados na última passada. Base sólida — suíte verde, mutação 38/38, `sdd health` 5/5, segredos limpos, métrica em `0` — mas **o gate NÃO fecha nesta rodada**, e inflar a nota aqui desligaria o único sensor de qualidade da missão. A r2 fecha |

### Recommended Actions

**Must Fix (CRITICAL/HIGH)**

**R1-5 (HIGH, aberto)** — `PIPE_RE` falha aberto em `grep -m 1 -q`; fecha na r2 com probe por grafia + sabotagem adversarial. Os dois desta rodada — R1-1 (`e470e74`) e R1-2 (`cf37e4f`) — estão consertados,
com sensor e vermelho observado.

**Should Fix (MEDIUM)**

R1-3 e R1-4 consertados em `f249b87`. **Abertos para a r2:** `.claude/agents/sdd-kaizen.md:30` (cópia instalada, drift do `guard` do I8) e `CONTEXT.md:16` (giro REVIEW→PR→REVIEW que o I9 encerrou). R1-6 (LOW, aberto): o `cost` vira string vazia onde o comentário promete `?`.

**Consider Fixing (LOW / fora de escopo)**

- Fechar por leitura integral os hunks de `check-gates.sh` / `check-preflight.sh` /
  `check-kaizen.sh` / `check-autonomy.sh`, hoje sustentados pelo catálogo de mutação e pelas
  jornadas J1–J5 da QA.
- Os itens que o EXEC e a QA já registraram no `TODO.md` (poda de `.sdd/logs/`, `grep -m<N>` na
  mesma família de SIGPIPE, ledger global sem filtro por repo, `main "$@"` sem guarda). Já têm
  linha própria; **não** entram neste diff.

**Dead Code**

Nenhum introduzido. O diff **remove** código morto (`bad_rows`, `bin/sdd:276,300`) e todos os
`mut_*` novos estão no array `CATALOG` — `sdd health` reprovaria gate sem mutação no catálogo, e
está verde.
