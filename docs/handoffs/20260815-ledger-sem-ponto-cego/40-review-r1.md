---
missao: 20260815-ledger-sem-ponto-cego
fase: REVIEW
rodada: r1
status: done
data: 2026-08-16 03:10
gate: "`./tests/run-all.sh` → rc 0, `suite green`, `score: 30 caught, 0 known gap(s), of 30` (66,4 s); `shellcheck -S warning bin/sdd` limpo; `bash -n bin/sdd` rc 0; `./bin/sdd health` verde nos 5 checks (suíte, mutação 30/30, mutação por gate, proveniência dos 3 fixtures, catraca de dívida sem item novo). Pré-scan determinístico de segredos sobre o diff da missão → `{\"findings\":[],\"scanners\":[\"regex\"],\"errors\":[]}`. 1 achado HIGH e 1 MEDIUM consertados nesta sessão (`e764cd2`), 1 LOW consertado junto, 1 LOW registrado no `TODO.md`, 11 suspeitas refutadas com evidência. Árvore limpa. Todos os critérios em Grade A."
---

# Review — rodada r1 — o ledger e o Jidoka param de mentir

> Rodada única. Não há `40-review-r0`; esta é a primeira e, pelo estado do gate, a última.
> Revisão e conserto na mesma sessão, como o contrato da fase exige.

## TL;DR

O diff entrega o que a missão prometeu — os três pontos cegos originais fecharam e o `F1` fechou o
quarto. A revisão achou **um quinto**, da mesma família e criado pela própria missão: o I2 ensinou
`degraded` aos dois filtros de admissão do ledger e **esqueceu a rubrica de rótulo do juiz**. Pior,
a decisão de esquecer estava defendida por uma asserção que não podia falhar — a **quinta
vacuidade** desta missão, e a primeira que congelava a decisão errada em vez de só deixar de medir.

Consertado nesta sessão em `e764cd2`, com Red observado antes do Green, asserção diferencial e
mutante próprio. Régua de mutação **29 → 30**.

## Como a rodada foi conduzida

Diff da missão: `git diff fdf8708...HEAD` — 12 arquivos, +1063/−61, produção 100% em `bin/sdd` e
`tests/`. A revisão rodou em três frentes independentes e depois cruzou os resultados:

1. **Leitura própria** do diff de `bin/sdd`, do `checkpoint.md` (as quatro lições de vacuidade) e
   do `30-handoff-qa.md`, com reprodução em ledgers de fixture em `/tmp` e `SDD_STATE_DIR`
   descartável — nunca o ledger real de `~/.sdd/`.
2. **Verificador de corretude do runner**, com instrução de reproduzir por comando e de reportar
   suspeita refutada como saída válida.
3. **Verificador de vacuidade dos sensores**, com uma pergunta só: *onde uma asserção verde deste
   diff está medindo o fixture em vez do código?* — a lente que o próprio `20-handoff-exec.md`
   pediu para a revisão.

O achado principal saiu **duas vezes de forma independente** (leitura própria e frente 2), o que é
o motivo de ele ter virado conserto e não discussão.

## Achados

### R1 — HIGH — `phase_label` não foi ensinado sobre `degraded` — **CONSERTADO** (`e764cd2`)

`bin/sdd:1801` (antes do conserto):

```jq
def phase_label:
  if (map(select(.event == "blocked")) | length) > 0
```

O I2 ensinou o evento novo ao `select` de admissão da série, ao mapa `escalations` e ao
`is_escalation` do `cmd_autonomy` — e deixou a rubrica de rótulo de fora **de propósito**. A
justificativa aparece em três lugares (`01-plano.md:139-140`, `docs/pipeline.md` e a própria
asserção do teste): *"as sessões de REVIEW de um run degradado já saem com `gate: fail`, então o
grupo já lê `refez`; ensinar contaria o mesmo fato duas vezes"*.

**A justificativa é falsa em duas frentes.**

Primeira: `phase_label` devolve **um rótulo**, nunca uma contagem — acrescentar uma disjunção não
pode contar nada duas vezes. Segunda, e essa é a que morde: a rubrica agrupa por
`(mission, phase)` sobre a **fatia inteira de `kit_sha`**, nunca por run. Basta um `sdd run`
posterior — `attempts` é `local` de `cmd_run` e nasce zerado a cada invocação — passar no gate de
REVIEW para `(map(select(.event == "session")) | last | .gate)` virar `"pass"`, e a única missão em
que o runner baixou a própria régua passa a ler `ok`.

Reproduzido, ledger de 4 linhas, mesmo `kit_sha`, duas invocações:

```
com event:"degraded"  → labels {"ok":2,"leve":0,"refez":0}   detail REVIEW: ok
com event:"blocked"   → labels {"ok":1,"leve":0,"refez":1}   detail REVIEW: refez
```

O mesmo evento estrutural, com o rótulo trocado, produz números diferentes no juiz. A frente 2
reproduziu uma variante ainda pior (com uma sessão `moved:false` no grupo o rótulo cai para `leve`,
não para `ok`) — dois caminhos, mesmo defeito.

**Por que é HIGH e não MEDIUM.** `labels` é um dos números que `agents/sdd-kaizen.md:30,58` manda o
juiz **citar** no veredito. Um run em que o runner se auto-degradou lendo `ok` é literalmente o
título desta missão: o instrumento mentindo. `blocked` está na cláusula desde sempre justamente
por isso — escalada **sobrevive** à sessão que a provocou —, e `degraded` é escalada.

**Conserto.** Um `is_escalation` só por programa, espelhando o que o `cmd_autonomy` já fazia, usado
nos três pontos (rubrica, mapa `escalations`, filtro de admissão). Escrever o par à mão em três
lugares foi exatamente como eles divergiram; a duplicação era a causa, não o sintoma.

### R2 — MEDIUM — a asserção que defendia R1 era a **quinta vacuidade** — **CONSERTADA** (`e764cd2`)

`tests/check-kaizen.sh` (antes do conserto):

```bash
# phase_label is deliberately NOT taught about `degraded`: ... Teaching it would count the
# same fact twice.
assert_eq "the label was already refez, so nothing had to be taught to phase_label" "refez" \
  "$(field '.latest.detail[] | select(.phase == "REVIEW") | .label')"
```

O fixture tem **uma** sessão de REVIEW, com `gate: fail`. A asserção fica verde com o conserto e
sem ele — ela mede o regime do fixture, não a propriedade. É a quinta vacuidade da missão, depois
do `rc 3` compartilhado do I1, do ramo `draft` nunca alcançado do I2, da cardinalidade garantida
pelo stub do `F1` e da necessidade de provar o regime dentro do próprio `F1`.

E é a mais cara das cinco, por um motivo novo: as quatro anteriores **deixavam de medir**; esta
**afirmava a decisão errada**. Um leitor futuro encontraria uma asserção verde chamada "nothing had
to be taught to phase_label" e concluiria que a questão estava resolvida.

**Conserto.** A asserção antiga foi mantida — ela é verdadeira — mas renomeada para dizer o que de
fato mede (*"inside the degraded run the failing session alone already reads refez"*), com o
comentário explicando por que isso **não** é evidência de que a rubrica pode ficar cega. Ao lado
dela entrou o bloco que mede a rubrica, e cuja asserção central é **diferencial**:

```bash
assert_eq "an escalation is an escalation: degraded labels exactly as blocked does" \
  "$blocked_labels" "$(jq -c '.latest.labels' <<< "$SERIES_OUT")"
```

Os dois lados vêm de ledgers diferentes (`degraded` e `blocked`, mesmas 4 linhas quanto ao resto),
então nenhum regime de fixture a satisfaz por acidente: se os dois eventos voltarem a responder
diferente, ela reprova — qualquer que seja o lado que se mexeu.

**Red observado, e pelo motivo certo:** 3 asserções vermelhas, todas no bloco novo, e a antiga
verde — o que é a prova de que ela era vácua.

**Sensor durável:** `mut_RUN_degraded_label_blind`, que devolve `phase_label` a `blocked` sozinho e
deixa o escritor e o filtro de admissão intactos. Âncora conferida: casa exatamente **uma** linha.
Não colide com `RUN_refez_dropped` (que sabota o valor `"refez"`) nem com
`RUN_degraded_row_dropped` (que sabota a existência da linha). Régua **29 → 30**.

### R3 — LOW — comentário que aponta para uma função que não existe mais — **CONSERTADO** (`e764cd2`)

`bin/sdd:850`: `# "${6:0:200}" is a CHARACTER slice, same reason as autonomy_blocked_row's
"${3:0:200}" above.` Depois do refactor do I2, `autonomy_blocked_row` é um wrapper de uma linha sem
fatia nenhuma; a explicação mora em `autonomy_escalation_row`, em `"${4:0:200}"`. Quem seguisse o
ponteiro caía num wrapper mudo. Corrigido para o alvo real — é a mesma classe de defeito que o I1
desta missão consertou (comentário prometendo o que a linha não entrega), e sai barato.

### R4 — LOW — missão só de escalada satisfaz `guard.sufficient` — **`TODO.md`** (fora de escopo)

`bin/sdd:1846`: `missions_after_change` conta `$rows | map(.mission) | unique | length` sobre todas
as linhas admitidas, escaladas incluídas. Reproduzido: três missões contendo **apenas** uma linha
`blocked` devolvem `{"missions_after_change":3,"sufficient":true}` com `sessions: 0` e
`moved_rate: null` — o juiz é liberado a dar veredito sobre uma versão do kit da qual não observou
sessão nenhuma.

**Não é regressão desta missão:** `blocked` já tinha a propriedade antes do diff (uma missão que
morre no Jidoka de `increment-blocked` não gasta sessão), e `degraded` apenas a herda pelo mesmo
filtro. Por isso foi para o `TODO.md` com a medição e a direção, e não para o diff — princípio 5 do
`CLAUDE.md`.

## Suspeitas refutadas (com evidência)

Receber crítica com rigor vale nos dois sentidos: o que foi levantado e **não** se sustentou está
aqui, com o que foi rodado. Mudar código para agradar uma crítica errada é pior que o achado.

| # | Suspeita | Veredito | Evidência |
|---|---|---|---|
| 1 | Âncoras de mutação dos 4 mutantes novos podem ter apodrecido (`sed` casando 0 ou >1 linha) | **refutada** | Cada `sed` aplicado a uma cópia de `bin/sdd` do `HEAD`: 4/4 casam **exatamente uma** linha e produzem exatamente uma linha de diff |
| 2 | Os mutantes novos podem matar a suíte pelo motivo errado | **refutada** | Cada um rodado isolado: `RUN_jidoka_pipefail` mata só a asserção de checkpoint grande; `RUN_degraded_repeats` mata só as 4 de cardinalidade (lendo 3 onde exige 1); `RUN_degraded_row_dropped` mata as 9 de existência; `RUN_escalations_no_axis` mata só as 3 de eixo. Zero falhas colaterais |
| 3 | A normalização do carimbo (`jq '.kit_sha = "deadbee"'`) neutraliza as asserções seguintes | **refutada** | Acontece **depois** das 10 asserções de forma/cardinalidade sobre o ledger cru, e é o **último** uso de `$LEDGER` no arquivo. As asserções de leitor pós-normalização continuam vermelhas sob `RUN_degraded_row_dropped`, `RUN_degraded_repeats` e sob o `bin/sdd` de `fdf8708` |
| 4 | As 20000 linhas do fixture do Jidoka vazam para asserções posteriores do `check-gates.sh` | **refutada** | `mv "$MDIR/checkpoint.jidoka.bak"` restaura logo após as duas chamadas, sem leitura intermediária; o caminho Jidoka sai antes de qualquer `claude`, então nada é commitado no meio |
| 5 | O fixture de 20000 linhas pode não alcançar o regime de falha (asserção nasceria vácua) | **refutada** | Contra o `bin/sdd` de `fdf8708` a **segunda** `assert_jidoka` reprova e a primeira (checkpoint pequeno) passa; contra o `HEAD` as duas passam. O regime é real |
| 6 | `SERIES_OUT` reatribuído no bloco novo do `check-kaizen.sh` muda o que uma asserção posterior mede | **refutada** | O bloco seguinte reatribui `SERIES_OUT` antes de qualquer `field()`. Não há janela de leitura velha |
| 7 | A comparação entre os dois leitores é tautológica (mesmo dado dos dois lados) | **refutada** | São expressões `jq` genuinamente diferentes: `group_by(.kit_sha, .kind)` sobre o arquivo inteiro contra `group_by(.kind)` **depois** da fatia por `kit_sha`. Sabotando só o lado do leitor (`RUN_escalations_no_axis`) os dois lados divergem |
| 8 | `group_by(.kit_sha, .kind)` pode não agrupar pelo par no jq instalado | **refutada** | `jq-1.7`; teste direto devolve 3 grupos chaveados por `[a,b]`. Semântica padrão (`group_by(f)` é `map([f])`) |
| 9 | Os quatro baldes do `cmd_autonomy` podem deixar de somar o total com o evento novo | **refutada** | Ledger de 11 linhas cobrindo os 5 formatos (sessão comparável, suja, sha nulo, sem `moved`, escalada no eixo, escalada fora, formato irreconhecível): 2 + 5 + 2 + 2 = 11, igual ao cabeçalho |
| 10 | `on_axis` (`.kit_dirty != true`) vs `comparable` (`.kit_dirty == false`) divergem e quebram a soma | **refutada como defeito vivo** | `autonomy_kit_stamp` (`bin/sdd:751-767`) só produz `kit_dirty: null` junto com `kit_sha: null`, e o sha nulo já reprova nos dois lados — não alcançável pelo runner. Mesmo com linha editada à mão a soma dos baldes se mantém. Já registrado no `TODO.md` pelo EXEC, corretamente |
| 11 | A guarda `degraded_logged` pode vazar entre missões, morrer em subshell, ou faltar em `cmd_retry` | **refutada** | `cmd_run` tem um único ponto de chamada (`bin/sdd:2140`), nunca recursivo e nunca sob `$( )`; a guarda é `local` simples e sobrevive às voltas do laço. `cmd_retry` roda uma fase só e **não alcança** o ramo `draft` — a guarda não faz falta lá |
| 12 | Ledger antigo (pré-missão) pode ser lido diferente depois do campo novo | **refutada** | Linhas antigas sem `kit_sha`/`kit_dirty` classificam idêntico a linhas com `null` explícito nos dois leitores; o campo é aditivo e a série ignora o que não reconhece em vez de morrer |

Duas observações que **não** viraram achado, registradas para não se perderem: o `warn`
`moving on to PR in draft mode` sair uma vez por volta enquanto o diário registra uma vez é
**deliberado e correto** — o `warn` narra a volta (fato) e é a testemunha anti-vacuidade que
sobrevive à sabotagem dos dois escritores; e a primeira `assert_jidoka` (checkpoint pequeno) tem
sua contribuição de mutação subsumida pela segunda hoje, o que não é defeito e não pede ação.

## Segurança

Pré-scan determinístico de segredos sobre o diff completo da missão (catálogo de regex equivalente
ao do GitGuardian): `{"findings":[],"scanners":["regex"],"errors":[]}`. Sem credencial, token ou
chave — inclusive nos fixtures, onde os `kit_sha` são inventados (`aaaaaaa`, `bbbbbbb`, `deadbee`)
e não há segredo a vazar.

Superfície nova auditada: todo valor que entra no ledger passa por `jq --arg` (sem injeção
possível); o diário usa `printf '%s\n' "$*"` (sem `eval`, sem expansão); o ledger continua fora do
repo, em `$HOME`, e uma asserção do `check-autonomy.sh` reprova se ele for parar dentro da árvore
sob teste. `gate_why` é fatiado por **caractere** (`"${4:0:200}"`), não por byte, o que impede meio
codepoint UTF-8 chegar ao `jq` e virar `--arg` vazio — registro que mente é pior que lacuna.

## Performance

O runner ficou **igual ou mais rápido**: o herestring elimina um `fork` + pipe por volta contra o
`printf`, e os filtros `jq` mantêm a mesma complexidade (uma passada por linha).

O número honesto é o da suíte de sensores: **37,4 s** de baseline (máquina descarregada) contra
**66,4 s** agora, com 30 mutantes — cada mutante roda a suíte inteira numa cópia, e o fixture caro
da degradação abre mais sessões de stub desde o `F1`. Minha rodada somou um mutante e nenhum tempo
mensurável (66,4 s contra 67,5 s medidos na abertura desta sessão, mesma máquina, ±10% de variação).

O alvo "<30 s" da D7 do `CONTEXT.md` **já estava estourado antes desta missão** e a decisão
(`SDD_MUTATION_JOBS`, `nproc` é GNU-only) é do humano, registrada no `TODO.md` com a medição.
Cortar mutação para ganhar tempo violaria o princípio que motivou o I13.2 — o custo foi comprado,
não sofrido.

## O que foi para o `TODO.md`

- Missão só de escalada satisfaz `guard.sufficient` com `sessions: 0` (R4), com a reprodução e a
  direção, marcada como herdada e não como regressão desta missão.

Os 6 achados que o EXEC e o QA já haviam registrado continuam lá e foram conferidos — nenhum
sumiu, e a catraca do `sdd health` confirma "6 known debt(s), none new".

## Verificação final

| Comando | Resultado |
|---|---|
| `./tests/run-all.sh` | rc 0 · `suite green` · `score: 30 caught, 0 known gap(s), of 30` · 66,4 s |
| `./bin/sdd health` | verde nos 5 checks (suíte, mutação 30/30, mutação por gate, proveniência dos 3 fixtures, catraca sem item novo) |
| `shellcheck -S warning bin/sdd` | limpo |
| `bash -n bin/sdd` | rc 0 |
| `grep -n "printf.*\|.*grep -q" bin/sdd` | só os dois comentários de convenção — nenhuma linha de código (critério 3 da verificação e2e do plano) |
| `git status --porcelain` | vazio — árvore limpa |

Os quatro Checks do `checkpoint.md` seguem batendo com `3521b9a`, `6853796`, `e9a74aa` e `56b2365`,
todos ancestrais de `HEAD`. A régua subiu de 29 para 30 nesta rodada; os Checks dos incrementos
registram o número que **cada um** afirmou na sua época e continuam verdadeiros — o catálogo é
aditivo.

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | A | O refactor do I2 já havia matado 15 linhas de `jq` duplicadas entre os dois escritores; a rodada matou a duplicação que sobrava — o par `blocked or degraded` escrito à mão em três pontos do mesmo programa, que foi como eles divergiram. Um `is_escalation` por programa, igual dos dois lados. Comentários agora apontam para o alvo real (R3) |
| Type Safety | A | Bash não tem tipos; o contrato é o schema da linha JSONL, e ele está fechado: `event` e `kind` são enums documentados em `docs/pipeline.md`, e os **três** consumidores do enum (admissão, mapa de escaladas, rubrica de rótulo) enxergam o mesmo conjunto depois de R1 — antes eram dois de três. Fatia por caractere impede UTF-8 partido virar `--arg` vazio |
| Error Handling | A | Ledger malformado morre por `die` com rc 1, nunca vazando o rc do `jq`; `autonomy_have_jq` avisa uma vez e segue; `autonomy_append` recusa objeto vazio; `pipeline_log_line` não escreve em projeção; a guarda one-shot é setada **antes** dos escritores, então falha de escrita não vira laço. Linha irreconhecível é contada, não silenciada |
| Security | A | Pré-scan determinístico de segredos limpo (0 findings) sobre o diff inteiro. Todo valor do ledger passa por `jq --arg`, diário por `printf '%s\n'`, sem `eval`. O ledger vive em `$HOME`, nunca no repo, e há asserção que reprova se vazar para a árvore sob teste |
| Performance | A | Runner igual ou mais rápido (herestring troca `fork`+pipe por expansão; `jq` na mesma complexidade). A suíte custa 66,4 s contra 37,4 s de baseline — custo de sensor comprado deliberadamente, medido, e cuja decisão (`SDD_MUTATION_JOBS` × alvo da D7) está no `TODO.md` como julgamento humano. Esta rodada somou um mutante e nenhum tempo mensurável |
| Test Coverage | A | Mutação **30/30**, `KNOWN_GAPS` vazio: toda linha de produção da missão tem sensor que morre quando sabotada, incluindo as duas metades do evento novo (existência e cardinalidade) e agora a rubrica de rótulo. A quinta vacuidade foi fechada com asserção **diferencial** entre dois ledgers, que nenhum regime de fixture satisfaz por acidente. Red observado antes de cada Green |
| Documentation | A | `docs/pipeline.md` cobre o evento novo, as duas formas de linha, a cardinalidade por `run_id`, o eixo compartilhado e — acrescentado nesta rodada — a regra que R1 expôs: admitir a linha não basta, o evento novo tem de alcançar `phase_label`, porque a rubrica agrupa sobre a fatia e não por run. `TODO.md` carrega os 7 achados fora de escopo. `KAIZEN_LOG.md` é trabalho da fase DOCS, que vem depois desta |
| **Overall** | **A** | Os quatro pontos cegos originais fecharam com sensor cada um; o quinto — criado pela própria missão e defendido por uma asserção vácua — foi achado, reproduzido duas vezes de forma independente, consertado com Red antes do Green e ancorado num mutante próprio. 11 suspeitas refutadas com comando, não com opinião. Suíte e `sdd health` verdes, árvore limpa |

## Recommended Actions

**Must Fix (CRITICAL/HIGH)** — _nenhuma pendente._ R1 foi consertado nesta sessão (`e764cd2`).

**Should Fix (MEDIUM)** — _nenhuma pendente._ R2 foi consertado nesta sessão (`e764cd2`).

**Consider Fixing (LOW)**
- R4, no `TODO.md`: contar `guard.sufficient` sobre missões com pelo menos uma sessão comparável,
  ou expor `sessions` junto de `sufficient` para o `gate_KAIZEN` cruzar. Herdado, não desta missão.
- Os 6 itens que o EXEC e o QA registraram seguem no `TODO.md`, nenhum bloqueante.

**Para o humano decidir** (repetidas do `00-missao.md` e do `30-handoff-qa.md`, não bloqueiam)
- Vocabulário do evento (`degraded` + `review-to-draft` contra reusar `blocked`). Andando a
  revisão, o argumento do plano ficou **mais forte**, não menos: R1 é a prova de que os dois
  eventos precisam responder igual à rubrica **sem** serem o mesmo evento. Se o humano preferir a
  alternativa barata, é um valor de campo e as asserções — e o `is_escalation` compartilhado torna
  a troca de um ponto só.
- Alvo de tempo da suíte: 66,4 s contra os "<30 s" da D7. Subir `SDD_MUTATION_JOBS`, subir o alvo,
  ou aceitar.
