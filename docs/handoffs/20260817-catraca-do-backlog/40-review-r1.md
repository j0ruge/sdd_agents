---
missao: 20260817-catraca-do-backlog
fase: REVIEW
rodada: r1
status: done
data: 2026-08-17
---

# Review — r1 — a catraca do backlog

> Rodada de revisão de código sobre o diff completo da missão (`git diff main...HEAD`, 15 arquivos,
> +1903/−47). Revisão **e** conserto na mesma sessão. O QA entregou 7 jornadas caminhadas e **0
> achados**, e disse por escrito que nenhuma leitura crítica de código tinha sido feita — os 485
> novos de `tests/check-health.sh` e os 166 de `tests/check-mutation.sh` chegaram aqui virgens.
> É esse o buraco que esta rodada preenche.

## Como foi rodada

Seis passadas em paralelo sobre o diff, cada uma com a rubrica da casa como régua (falha aberta,
rc compartilhado, vacuidade, `pipefail`, subshell que come global, `mawk` byte-orientado,
`CDPATH`), mais o pre-scan determinístico de segredos. Toda passada foi instruída a **confirmar por
reprodução** antes de concluir, e a rotular `CONFIRMED` × `PLAUSIBLE`. Os achados abaixo que dizem
CONFIRMED foram reproduzidos, não deduzidos.

**11 achados** vieram das passadas. **7 viraram conserto** nesta sessão, **3 viraram item do
`TODO.md`** e **4 foram refutados com evidência** (a soma passa de 11 porque dois achados tinham
metade procedente e metade refutada).

## Achados que viraram conserto

### R1 — [HIGH] A ordem de versões do `sdd autonomy` lê a POPULAÇÃO errada, e ainda discorda do juiz

`bin/sdd:2538`. O I3 consertou o `group_by` lexicográfico e o comentário passou a afirmar paridade
com o `kaizen_series` — *"Same spelling on purpose, in both programs"*. A afirmação é falsa: o
`kaizen_series` lê a primeira aparição sobre **toda linha `on_axis`** (`bin/sdd:2799`), sessão ou
escalada, e o `cmd_autonomy` lia sobre `is_session and comparable`. Uma versão cuja primeira linha
`on_axis` é uma escalada já existe para a série quando a tabela nunca ouviu falar dela.

**Reproduzido**, não lido: ledger com `blocked(aaaaaaa)`, `session(bbbbbbb)`, `session(aaaaaaa)`
nesta ordem → `sdd autonomy` põe `aaaaaaa` na última linha e `sdd kaizen --series` responde
`.latest.kit_sha = bbbbbbb`. As duas janelas respondem "qual é a versão mais recente?" diferente
sobre o mesmo arquivo — exatamente a divergência que o I3 existe para fechar, um caso mais estreito
sobrevivendo ao conserto.

**Conserto:** `$order` passa a ser lido de `map(select(on_axis))`, a mesma população do juiz.
`comparable` implica `on_axis` pela própria definição (`bin/sdd:2497`), então todo grupo da tabela
tem lugar na lista — não há `index` nulo possível.

**Teste:** `tests/check-autonomy.sh`, asserção `output: the table orders versions off the judge's
population, escalations included` — diferencial contra o juiz, com a escalada em **primeiro** lugar
porque é a única colocação em que as duas populações discordam, e com piso de 2 linhas de tabela
(um leitor que perdesse metade da tabela concordaria com o juiz por não ter mais o que discordar).
Nasceu **vermelha**: sabotagem de uma linha (`on_axis` → `is_session and comparable`), verificada
mudando **exatamente uma linha** por `diff` antes de qualquer conclusão, e a asserção reprovou.
Verde depois. O `esc_row()` do fixture copia campo a campo o que `autonomy_escalation_row`
(`bin/sdd:1078`) escreve — não foi escrito de memória.

⚠️ É a **sexta** asserção `output:`, então o Check do I3 no `checkpoint.md` passou de `5` para `6`.

### R2 — [MEDIUM] `mut_HEALTH_provenance_blind` sabotava DUAS linhas, não uma

`tests/check-mutation.sh:871`. `if [ "$line" = "$fix" ]; then checked` é byte a byte a mesma linha
no ramo do `qa-execution` (`bin/sdd:1833`) e no do `qa-report` (`:1844`), e o `sed` sem faixa
alcançava os dois. Duas consequências, e a segunda é a cara: a entrada quebra a disciplina
"uma mutação, uma linha" deste arquivo, e **impede para sempre** que o ramo do `qa-execution` ganhe
mutação própria — a dele já estaria sendo morta por esta.

**Conserto:** endereçada por faixa (`/# registry bug: the Status line/,/# codereview grade table/`),
que é o único ramo com fixture hoje. Verificado: muda **exatamente uma linha** (1844, contada por
`diff`) e continua matando `tests/check-health.sh` pela asserção que o comentário nomeia
(`provenance fails when the fixture diverges from an installed skill`), não por rc compartilhado.

### R3 — [HIGH] `CLAUDE.md` ainda diz "Os doze de hoje" com treze sensores na suíte

`CLAUDE.md:132`. A frase imediatamente anterior é *"Sensor novo entra lá"*, e a lista é o
inventário canônico que a próxima sessão lê. A missão acrescentou o décimo terceiro sensor,
`check-health.sh`, e editou o `CLAUDE.md` no mesmo commit — sem tocar na lista. Medido: `ls
tests/check-*.sh | wc -l` → 13; sensores invocados pelo `run-all.sh` → 13; nomes na lista → 12.
**Conserto:** "Os treze de hoje", com `check-health.sh` no fim.

### R4 — [MEDIUM] `README.md` afirma da baseline exatamente o que esta missão provou falso

`README.md:88`. O parágrafo do `sdd health` dizia *"Known debt lives frozen in
`tests/health-baseline.txt`, each line owned by a `TODO.md` entry"* — a redação **antiga** do
cabeçalho da baseline, que o I5 reescreveu de propósito para admitir que uma linha
(`todo-findings`) não tem entrada dona: a dona é o arquivo. E o parágrafo não mencionava a catraca
do backlog, que é o título da missão. O README é o primeiro documento que qualquer um abre.
**Conserto:** o parágrafo passa a nomear o `todo-findings <N>` e a dizer a verdade sobre a posse.

### R5 — [HIGH] Duas âncoras do próprio `TODO.md` foram deslocadas por este diff e não acompanharam

`TODO.md:432` e `:434` citavam `bin/sdd:1829` e `:1856`; os alvos reais são `:1854` e `:1882` — as
25 linhas do bloco novo do check 3 entraram entre a escrita do item e o HEAD. O item irmão logo
abaixo (`:442`) já cita os números certos, então o arquivo se contradizia sozinho. Confirmado por
inspeção: `:1829` hoje é uma linha sem relação. **Conserto:** as duas âncoras corrigidas. A mesma
frase afirmava que "os checks 4-6, a proveniência e a catraca nunca rodam" — o `find` mora
**dentro** da proveniência, então os checks 4-7 já rodaram; a frase foi corrigida junto.

### R6 — [HIGH] Um comentário do `check-autonomy.sh` aponta para o número de check errado

`tests/check-autonomy.sh:1598` dizia *"sdd health check 5 fails on a subcommand missing from the
help"*. Este diff renumerou os checks do `cmd_health` (3→4 … 7→8) e o "subcommand missing from
--help" virou o **6**. O comentário é a única coisa que liga a asserção ao ponto do runner que ela
espelha. **Conserto:** `check 6`.

### R7 — [LOW] O `${FIX:?}` do sensor novo não cobre o caminho que ele foi escrito para cobrir

`tests/check-health.sh:62`. `WORK="$(mktemp -d …)"` sem checar rc; o arquivo não tem `set -e`. Com
`mktemp` falhando, `WORK` fica vazio e `FIX="$WORK/kit"` vira **`/kit`** — string não-vazia, então
`rm -rf "${FIX:?}/home"` do `reset_home()` passa pela guarda e roda de verdade. A guarda testa o
sintoma e não a causa. **Conserto:** `|| exit 90` com `SENSOR-BROKEN` no ponto da atribuição (antes
de `broken()` existir, por isso o rc literal).

## Achados que viraram item do `TODO.md`

Nenhum foi descartado; os três estão no `TODO.md` com âncora, porquê e direção. **A contagem foi de
73 para 76 e a baseline (`tests/health-baseline.txt`) moveu no mesmo commit** — que é esta missão
sendo cobrada pela catraca que ela própria instalou, pelo caminho que o QA mediu na jornada J4.

| # | Achado | Por que não coube aqui |
|---|---|---|
| T1 | Duas das três comparações de `health_provenance` não têm fixture nem mutação (`bin/sdd:1829` e `:1850`) | É extensão de escopo: pede um par match/divergência para cada, e a do codereview é um laço `awk` de forma diferente. O R2 tornou o buraco explícito em vez de deixá-lo coberto por acidente |
| T2 | Os 14 `ROOT="$(cd …)"` de `tests/` não levam `CDPATH=''` (reproduzido) | **Pré-existente e sistêmico** — os 14 arquivos, não o novo. Consertar só o desta missão deixaria 13 iguais e daria a impressão de resolvido |
| T3 | `def usd` erra o dólar inteiro com entrada negativa; perde um centavo em `1.005` | O escritor do ledger nunca produz `cost_usd` negativo: é guarda para um mundo que não acontece, e o fixture dela só um teste consegue montar. Decisão, não conserto óbvio |

## Achados refutados, com evidência

- **"A checagem do `score:` morre calada sob `set -e`" (MEDIUM).** Procedente como defeito, **não**
  como achado desta rodada: já é item **aberto** do `TODO.md:439`, com a âncora certa (`bin/sdd:1721`)
  e a direção certa (`|| true`). O check **novo** já nasce com `|| true` justamente por causa dele.
  Registrar de novo seria a inflação que esta missão combate.
- **"O `health_bad "suite red"` é código morto" (MEDIUM).** Idem: `TODO.md:431`, pré-existente em
  `main`, verificado por `git show main:TODO.md`. Este diff não piorou nem melhorou.
- **"O piso `-ge 2` do `calibrate()` tem folga: o kit real emite 7" (LOW).** **Refutado.** Apertar
  o piso para 7 é reintroduzir o defeito que o cabeçalho do arquivo (linhas 50-56) descreve:
  a baseline do fixture é **calibrada** e não escrita à mão exatamente para que uma deriva legítima
  do `config/schema.md` não deixe a suíte vermelha — e a suíte é o `TEST_CMD`, logo isso reprovaria
  `gate_EXEC`/`QA`/`REVIEW` de toda missão em voo, que é o que a decisão 1 do plano proíbe. Um piso
  que conta 7 é uma recontagem disfarçada de piso.
- **"A linha em branco entre duas exclusões consecutivas continua lá" (LOW).** Confirmado como
  fato, refutado como achado: é item **aberto** (`TODO.md:518`), registrado pelo próprio EXEC, e o
  handoff de QA já o separa da regressão. O `empty` do I3 mirava a linha em branco **dupla** (a que
  a contagem zero produzia) e a removeu.
- **"`mut_KAIZEN_already_judged_spends` ancora numa faixa `+4`" (LOW).** **Refutado como
  falha-aberta.** `return "$out_rc"` aparece 6× no `cmd_kaizen`, e a faixa é o que evita colapsar
  os seis num mutante só. O `+4` é frágil, mas o `run_mutant()` faz `cmp -s` antes de rodar a suíte
  e grita `CATALOGUE-BROKEN` rc 90 num no-op: a rot de âncora é **alta e detectada**, nunca um
  ponto creditado em silêncio. Fragilidade de manutenção, não defeito de medição.
- **"O `reduce`+`index` é O(n·k)" (LOW).** **Refutado como achado deste diff:** o padrão é o
  `shas_in_file_order` que já existia (`bin/sdd:2668`); o diff usa a mesma grafia de propósito, que
  é a única coisa que impede os dois programas de divergirem de novo.

## Prova de que os consertos medem alguma coisa

| Conserto | Como foi provado |
|---|---|
| R1 | Asserção nova **vermelha** sob sabotagem de 1 linha (contada por `diff`), verde com o conserto. O probe morre alto se a edição não mudar o arquivo |
| R2 | Mutação re-verificada: muda **exatamente 1** linha (1844) e o `check-health.sh` reprova pela asserção 4, nomeada no comentário |
| R3–R6 | Contagem/âncora medidas por comando (`ls tests/check-*.sh` → 13; `bin/sdd:1854`/`:1882` inspecionados; `# --- 6. subcommand missing from --help` no fonte) |
| R7 | Mecânica reproduzida: `WORK=""; FIX="$WORK/kit"` → `/kit`, e `: "${FIX:?}"` **não** dispara |
| T1–T3 | `tests/check-todo.sh` → `76 finding(s), all within 8 lines and carrying anchor + date`; baseline movida no mesmo commit |

## Evidência final

- `tests/run-all.sh` → **rc 0**, `suite green`, `score: 81 caught, 0 known gap(s), of 81`,
  **589** asserções `ok` (eram 533 no fim do EXEC).
- `shellcheck -S warning bin/sdd tests/*.sh` → limpo.
- `bash -n bin/sdd` → limpo.
- `./bin/sdd health` → **rc 0**, `kit healthy`, os 5 checks verdes,
  `ratchet: 7 known debt(s), none new` com `todo-findings 76`.
- Pre-scan determinístico de segredos sobre o diff completo → **0 achados**, 0 erros.
- Catálogo de mutação: **81 definições `mut_…`** × **81 entradas em `CATALOG`**, zero órfãs nos dois
  sentidos, zero duplicadas.
- Contrato da contagem, byte a byte nos três pontos: `tests/check-todo.sh` imprime
  `  ok    76 finding(s)…` → o regex `^  ok    [0-9]+ finding\(s\)` do `bin/sdd` casa →
  `tests/health-baseline.txt` congela `todo-findings 76`.
- Árvore limpa, consertos commitados.

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | A | Zero mecanismo novo: a catraca reusa `health_finding` + `health_ratchet`, e o único helper criado (`autonomy_no_data`) remove duplicação literal. A única violação de disciplina achada — a mutação de faixa larga do R2 — foi consertada. Comentários explicam o *porquê* medido, não o *o quê* |
| Type Safety | A | O análogo em bash é contrato de forma, e os três estão fechados: a contagem é um contrato byte-exato entre `check-todo.sh`, o regex do `bin/sdd` e a baseline; `comparable` implica `on_axis`, então o `index($s)` do R1 não pode devolver nulo; `esc_row()` copia campo a campo o escritor real |
| Error Handling | A | O check novo nasce com `|| true` contra a família de abortos calados, com o porquê no comentário; o `mktemp` ganhou guarda (R7); `broken()` sai 90 em vez de virar uma asserção vermelha entre oito verdes. Os dois abortos calados irmãos são pré-existentes, abertos no `TODO.md` e agora com âncora correta (R5) |
| Security | A | Pre-scan determinístico: 0 segredos. Fixtures herméticos (`HOME`, `SDD_STATE_DIR` e `TMPDIR` próprios, `trap` de limpeza); nada escreve no ledger real nem na árvore. A classe `CDPATH` foi reproduzida, é pré-existente nos 14 sensores e está registrada (T2) em vez de meio-consertada |
| Performance | A | O custo é **medido e declarado**, não silencioso: o sensor cabe em ~2 s sozinho, e o multiplicador do harness (uma vez por mutante) está no `TODO.md` com a decisão humana nomeada. Suíte em 3m30s nesta máquina, rc 0. Crescer é permitido; crescer calado não — que é a regra desta própria missão |
| Test Coverage | A | 589 asserções, 81/81 mutações com `0 known gap(s)`, e cada mutação nova verificada matando a suíte **pela asserção que o comentário nomeia**. A regressão do R1 nasceu vermelha por sabotagem de uma linha contada por `diff`. O único buraco conhecido (T1) está registrado e o R2 o tornou explícito em vez de mascarado |
| Documentation | A | Os quatro pontos de deriva que o diff criou foram fechados: inventário de sensores (R3), README sobre a posse da baseline (R4), âncoras do próprio `TODO.md` (R5) e o número de check no comentário do sensor (R6). O `01-plano.md` ganhou o ⚠️ que reconcilia o `77` estimado com o `81` real |
| **Overall** | **A** | 11 achados, 7 consertados com prova, 3 registrados com âncora, 4 refutados com evidência. Suíte verde, `kit healthy`, árvore limpa |

### Recommended Actions

**Must Fix (CRITICAL/HIGH)** — todos consertados nesta rodada:
- R1 · população da ordem de versões do `sdd autonomy` (com regressão diferencial)
- R3 · inventário de sensores do `CLAUDE.md`
- R5 · âncoras deslocadas do `TODO.md`
- R6 · número de check no comentário do `check-autonomy.sh`

**Should Fix (MEDIUM)** — consertados: R2 (mutação de faixa larga), R4 (README).

**Consider Fixing (LOW)** — R7 consertado; T1, T2 e T3 no `TODO.md` com âncora e direção.

**Para o humano** (herdado do EXEC e do QA, não bloqueia): a posse da linha `todo-findings` na
baseline, e o multiplicador do harness de mutação. As duas já estão no `TODO.md`.
