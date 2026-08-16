---
missao: 20260815-ledger-sem-ponto-cego
data: 2026-08-15
---

# Plano — o ledger e o Jidoka param de mentir

> **Teste de autocontenção:** uma sessão nova, sem nenhuma memória da conversa que gerou este
> plano, lendo apenas `00-missao.md` + `01-plano.md` + `checkpoint.md`, consegue executar?
> Se a resposta for "só se souber X", **X vai escrito aqui**.

## Contexto verificado (não re-descobrir)

Tudo abaixo foi aberto ou executado na sessão kaizen de 2026-08-15, sobre o `HEAD`
`90f9ce91aa8f784b3e1c94208c81b6fcca817afa`. Onde há número, ele foi medido; onde há código, ele
está citado verbatim.

- **Baseline da suíte:** `./tests/run-all.sh` → `suite green`, `score: 23 caught, 0 known gap(s),
  of 23`, em **37,4 s** (`time`, default de `SDD_MUTATION_JOBS`). O alvo "<30 s" da D7 do
  `CONTEXT.md` **já está estourado antes desta missão** — não é regressão dela.
- **As duas ocorrências vivas de `printf | grep -q`** — `grep -n "printf.*|.*grep -q" bin/sdd`:
  - `bin/sdd:1084` — `if printf '%s' "$probe" | grep -q 'sdd-preflight-ok'; then`
  - `bin/sdd:1497` — `if [ "$phase" = "EXEC" ] && printf '%s\n' "$ckstatus" | grep -qx "blocked"; then`
  - `bin/sdd:1174` é apenas o comentário de aviso da convenção, não uma ocorrência.
- **O comentário que promete mais do que a linha entrega:** `bin/sdd:1490-1495` explica o SIGPIPE
  e afirma "The status goes into a variable BEFORE the `grep`". A variável está em `bin/sdd:1496`
  (`local ckstatus; ckstatus="$(checkpoint_rows | cut -f4)"`), mas `bin/sdd:1497` mantém o pipe.
- **A forma correta já é usada em outro ponto do repo:** herestring (`grep -qx "blocked" <<< "$ckstatus"`).
  A convenção está no `CLAUDE.md` (seção "TDD aqui dentro", primeiro ⚠️).
- **O salto da degradação** — `bin/sdd:1519-1522`: `force_phase="PR"; continue` executa **antes**
  de `pipeline_log_line` (`bin/sdd:1523`) e de `autonomy_blocked_row` (`bin/sdd:1524`).
- **Assinaturas dos escritores do ledger:**
  - `bin/sdd:772` — `autonomy_append()  # <one json object, already built>`
  - `bin/sdd:809` — `autonomy_blocked_row() # <kind> <phase> <gate_why>`
  - `bin/sdd:833` — `autonomy_session_row() # <phase> <attempt> <auto_retry> <moved> <gate> <gate_why>`
  - Os dois últimos chamam `autonomy_kit_stamp` **por chamada, nunca por `$( )`** (`bin/sdd:811`,
    `bin/sdd:836`) — a lição do subshell registrada no `CLAUDE.md`. Um escritor novo tem de fazer igual.
- **O filtro que define o que a série reconhece** — `bin/sdd:1766-1767`:
  ```
  ($raw | map(select(type == "object" and .v == 1
                     and (.event == "session" or .event == "blocked")))) as $all
  ```
  e `bin/sdd:1770`: `(($raw | length) - ($all | length)) as $unrec`. **Consequência direta:** um
  `event` novo que não entre nesse `select` é contado como `unrecognized` e some da série.
- **A série já agrupa escalada por `kit_sha`** — `bin/sdd:1774` fatia
  `$ok | map(select(.kit_sha == $shas[-1])) | group_summary`, e o `group_by(.kind)` de
  `bin/sdd:1760` roda **dentro** dessa fatia. A série está correta; não mexer nela por causa do I3.
- **O `sdd autonomy` NÃO agrupa por `kit_sha`** — `bin/sdd:1698`:
  `| map("  \(.[0].kind): \(length)") | join("\n") | select(length > 0) | "\nescalations\n" + .`,
  alimentado por um `group_by(.kind)` sobre o arquivo inteiro. Sessões, ali, já são agrupadas por
  `kit_sha` (`bin/sdd:1635` na numeração do `TODO.md`) — só o bloco de escaladas ficou de fora.
- **Como o rótulo é derivado** — `phase_label`, `bin/sdd:1737-1745`: `refez` quando há
  `event == "blocked"`, ou sessão com `invocation == "retry"`, ou a última sessão com
  `.gate != "pass"`. **Importante para o I2:** numa degradação as sessões de REVIEW já saem com
  `gate: "fail"`, então o rótulo `refez` já acontece hoje — o I2 **não** precisa mexer em
  `phase_label`, e mexer seria contar o mesmo fato duas vezes.
- **O catálogo de mutação** — `tests/check-mutation.sh:176-200`, 23 entradas, `KNOWN_GAPS=()`
  vazio (`tests/check-mutation.sh:205`). Nenhuma delas cobre `pipefail`, degradação ou o eixo do
  `cmd_autonomy`.
- **O parser do checkpoint proíbe `|` dentro de célula** — `bin/sdd:171-182` faz
  `awk -F'|'` e exige `NF >= 6`. Check com pipe dentro quebra a tabela; use `&&` ou dois comandos.
- **Config deste repo:** `.sdd/config.sh:10` `HANDOFF_DIR="docs/handoffs"`, `:28`
  `JIRA_ENABLED=false`, `:34` `OUTPUT_LANG="pt-BR"`.

## Arquitetura da mudança

Três consertos independentes, todos em `bin/sdd` + `tests/`. Nenhum toca agente, template ou
contrato de artefato. A ordem I1 → I2 → I3 é por risco crescente: I1 é substituição de forma
sintática; I2 acrescenta vocabulário ao ledger e por isso encosta na série; I3 é reescrita de um
filtro `jq` de saída humana.

```
ledger (~/.sdd/autonomy-log.jsonl)
   ▲                    ▲                          ▲
   │ escreve            │ escreve                  │ NÃO escreve hoje  ← I2
autonomy_session_row  autonomy_blocked_row     (ramo draft, bin/sdd:1521)
   │
   └─ lido por ──┬── sdd kaizen --series  (juiz)  → eixo kit_sha ✔ correto
                 └── sdd autonomy         (humano) → escaladas sem eixo ✘  ← I3

Jidoka do incremento `blocked` (bin/sdd:1497) → depende do buffer do pipe ✘  ← I1
```

## Incrementos

A tabela executável vive em `checkpoint.md` (é ela que o runner lê). Aqui fica o **porquê** de
cada fatia — o detalhe que não cabe numa célula.

### I1 — o Jidoka do `blocked` para de depender do tamanho do checkpoint

**O quê:** trocar as duas ocorrências de `printf … | grep -q` por herestring.
- `bin/sdd:1497` → `if [ "$phase" = "EXEC" ] && grep -qx "blocked" <<< "$ckstatus"; then`
- `bin/sdd:1084` → `if grep -q 'sdd-preflight-ok' <<< "$probe"; then`

Ajustar o comentário de `bin/sdd:1490-1495` para descrever o que a linha passa a fazer: hoje ele
afirma uma garantia que o pipe não entrega, e comentário que mente é a mesma classe de defeito
que a missão está fechando.

**Onde:** `bin/sdd:1084`, `bin/sdd:1490-1497`; `tests/check-autonomy.sh` (ou
`tests/check-gates.sh`, onde já houver fixture de missão com checkpoint); `tests/check-mutation.sh`.

**Como (TDD):** primeiro a asserção. Montar um `checkpoint.md` de fixture com um incremento
`blocked` **e** volume suficiente para estourar o buffer de 64 KB do pipe — o caminho barato é
muitas linhas de tabela `pending` antes da linha `blocked`, já que `ckstatus` recebe uma linha de
status por linha de tabela (`checkpoint_rows | cut -f4`). Afirmar que `sdd run <missão>` devolve
**rc 3** e imprime a mensagem de Jidoka. **Essa asserção tem de ficar vermelha no `bin/sdd` de
hoje** — é ela que prova que a corrida existe. Só então aplicar o herestring e vê-la verde.

⚠️ Se a asserção **não** ficar vermelha antes do conserto, o incremento vai a `blocked` e a linha
para: significa que o fixture não alcançou o regime de falha (não estourou o buffer) e a asserção
ainda não mede nada. Aumentar o fixture, não relaxar a asserção — asserção que não pode falhar é
exatamente a decoração que o `KAIZEN_LOG.md` registra como dívida.

**Check:** `./tests/run-all.sh` → `suite green` e `score: 24 caught, 0 known gap(s), of 24`
**Sensor durável:** mutação `RUN_jidoka_pipefail` no catálogo, revertendo o herestring para
`printf '%s\n' "$ckstatus" | grep -qx "blocked"` — a suíte tem de morrer.
**Reversível por:** `git revert` do commit; nenhuma mudança de contrato.

### I2 — a auto-degradação passa a existir no ledger

**O quê:** antes do `force_phase="PR"; continue` de `bin/sdd:1521`, escrever o diário e uma linha
de ledger. Vocabulário proposto: `event: "degraded"`, `kind: "review-to-draft"`, com os mesmos
campos comuns das outras linhas (`v`, `mission`, `phase`, `kit_sha`, `kit_dirty`, `ts`, `gate_why`).

**Por que `event` novo e não `event: "blocked"`:** `blocked` significa "a linha parou" e o runner
`return 3`. Aqui o run **continua** para PR. Reusar `blocked` seria mais barato — herdaria o eixo
de `kit_sha` e a agregação da série sem tocar em `jq` nenhum —, mas gravaria rótulo falso, e o
ledger existe para gravar fato. O custo dessa escolha é o próximo parágrafo, e está declarado nas
"Pendências para o humano" do `00-missao.md`: se o humano preferir a opção barata, é trocar o
valor do campo e a asserção.

**A consequência que NÃO pode ser esquecida:** `bin/sdd:1766-1767` só reconhece
`.event == "session" or .event == "blocked"`. Um `event: "degraded"` que não entre nesse `select`
é contado em `excluded.unrecognized` (`bin/sdd:1770`) e desaparece da série — trocando um ponto
cego por outro. Então o incremento **tem** de incluir: (a) `degraded` no `select` de
`bin/sdd:1767`; (b) as linhas `degraded` somadas ao mapa `escalations` do `group_summary`
(`bin/sdd:1760`), que já roda dentro da fatia de `kit_sha` e por isso entrega o eixo de graça.
**Não mexer em `phase_label`** — as sessões de REVIEW já saem com `gate: "fail"` e o rótulo
`refez` já sai correto; somar `degraded` ali contaria o mesmo fato duas vezes.

**Onde:** `bin/sdd:1519-1524` (o ramo), o escritor novo ao lado de `autonomy_blocked_row`
(`bin/sdd:809`), `bin/sdd:1760` e `bin/sdd:1767` (a série); `tests/check-autonomy.sh`;
`tests/check-mutation.sh`; `docs/pipeline.md` § "The autonomy ledger" (a tabela de campos).

**Como (TDD):** asserção primeiro em `tests/check-autonomy.sh` — fixture com
`PUBLISH_ON_REVIEW_BLOCKED=draft` e REVIEW estourando o orçamento; afirmar (1) exatamente **uma**
linha nova no ledger, com `event == "degraded"`; (2) `sdd kaizen --series` com
`excluded.unrecognized == 0` e a escalada aparecendo no `escalations` do grupo do `kit_sha`
corrente. Ambas vermelhas hoje: a primeira porque nada é escrito, a segunda porque, escrevendo
sem tocar no `select`, a linha viraria `unrecognized`.

⚠️ O escritor novo chama `autonomy_kit_stamp` **como comando**, nunca como `$( )` —
`bin/sdd:811` e `bin/sdd:836` documentam por quê (a guarda one-shot morre no subshell).

**Check:** `./tests/run-all.sh` → `suite green` e `score: 25 caught, 0 known gap(s), of 25`
**Sensor durável:** mutação `RUN_degraded_row_dropped` (devolve o `continue` para antes do
escritor) e, se couber num mutante só, a variante que remove `degraded` do `select` da série.
**Reversível por:** `git revert`; o campo é aditivo — ledger antigo continua legível, porque a
série ignora o que não reconhece em vez de morrer.

### I3 — os dois leitores do ledger passam a concordar sobre o eixo

**O quê:** em `cmd_autonomy`, agrupar as escaladas por `(kit_sha, kind)` em vez de só por `kind`,
excluindo e contando as não-comparáveis (`kit_dirty == true` ou `kit_sha == null`) do mesmo jeito
que o bloco de sessões já faz.

**O que NÃO fazer:** mexer em `kaizen_series`. Ela já está correta (`bin/sdd:1774` fatia por
`kit_sha` antes do `group_by(.kind)`), e "consertar" os dois lados criaria a divergência que o
incremento existe para remover.

**Onde:** `bin/sdd:1698` e o `group_by` que o alimenta; `tests/check-autonomy.sh`.

**Como (TDD):** asserção primeiro — ledger de fixture com escaladas em **dois** `kit_sha`
diferentes e uma com `kit_dirty: true`; afirmar que a saída do `sdd autonomy` mostra as
escaladas sob a versão a que pertencem e que a suja é contada como excluída, não somada.

**Check:** `./tests/run-all.sh` → `suite green` e `score: 26 caught, 0 known gap(s), of 26`
**Sensor durável:** mutação `AUTONOMY_escalations_no_axis`, revertendo para o `group_by(.kind)`
global.
**Reversível por:** `git revert`; muda apenas formatação de saída humana.

## Riscos e não-feitos

| Risco | Probabilidade | Mitigação |
|---|---|---|
| O fixture do I1 não estoura o buffer de 64 KB e a asserção nasce verde (vácua) | alta | O incremento exige **ver o vermelho** antes do conserto; sem Red observado, vai a `blocked` (K6). Aumentar o fixture, nunca relaxar a asserção |
| `event: "degraded"` vira `unrecognized` e troca um ponto cego por outro | média | Asserção explícita de `excluded.unrecognized == 0` no Check do I2, além do `select` de `bin/sdd:1767` |
| A suíte passa dos 37,4 s de hoje com três mutantes novos | alta | Declarado e aceito: cortar mutação para ganhar tempo violaria o princípio que motivou o I13.2. O default de `SDD_MUTATION_JOBS` é decisão do humano, registrada no `TODO.md`. Medir e registrar o novo tempo no `KAIZEN_LOG.md` |
| Fixture do I1 grande deixa a suíte lenta | média | Gerar o checkpoint no `setup` do teste (laço `printf`), não versionar 64 KB de fixture no repo |
| O humano preferir `event: "blocked"` com `kind` novo | média | Escolha isolada num campo e numa asserção; o `00-missao.md` já registra a alternativa e seu custo |
| `sed -i` do catálogo de mutação casar linha errada depois do I1 mudar `bin/sdd:1497` | média | Rodar `tests/check-mutation.sh` isolado após cada incremento; `score` abaixo do esperado ou `produced no result` denuncia na hora |

## Verificação end-to-end

Com I1, I2 e I3 `done`:

1. `./tests/run-all.sh` → `suite green` com `score: 26 caught, 0 known gap(s), of 26`.
2. `bash -n bin/sdd` → sem saída (rc 0).
3. `grep -n "printf.*|.*grep -q" bin/sdd` → **nenhuma linha de código** (só o comentário de aviso
   em `bin/sdd:1174` pode casar).
4. `./bin/sdd kaizen --series` → JSON válido; num ledger que contenha uma degradação, a escalada
   aparece no `escalations` do grupo do `kit_sha` e `excluded.unrecognized` continua `0`.
5. Registrar no `KAIZEN_LOG.md` (fase DOCS) o antes/depois medido: mutação **23 → 26** e o tempo
   de suíte contra os **37,4 s** desta baseline — sem número não é kaizen, é opinião.
