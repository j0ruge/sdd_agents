---
missao: 20260815-ledger-sem-ponto-cego
titulo: o ledger e o Jidoka param de mentir — três pontos cegos fechados antes de a série encher
data: 2026-08-15
versao:
branch: missao/20260815-ledger-sem-ponto-cego
aprovacao: humano-2026-08-16
ddd: n/a
---

# Missão — o ledger e o Jidoka param de mentir

> Nascida pelo laço kaizen (`sdd kaizen`), a partir do veredito `05-verdict.md` ao lado e da
> triagem do `TODO.md`. `aprovacao:` vazia por contrato: o kaizen não aprova o próprio plano.

## Problema (Gemba)

O veredito ao lado registrou que a série está vazia: nenhuma missão rodou sob o kit do I13.3.
Isso torna **agora** o único momento barato para consertar o instrumento — toda linha escrita a
partir daqui é histórico, e histórico com ponto cego não se corrige retroativamente.

Três defeitos, os três verificados nesta sessão no `bin/sdd` do `HEAD` `90f9ce9`:

**1. O Jidoka do incremento `blocked` depende de uma corrida** — `bin/sdd:1497`:

```bash
if [ "$phase" = "EXEC" ] && printf '%s\n' "$ckstatus" | grep -qx "blocked"; then
```

O arquivo roda com `set -o pipefail`. Quando o `grep -qx` **acha**, ele sai e fecha o pipe; o
`printf` morre de SIGPIPE e o pipeline devolve **141**, então o `if` lê "não há blocked"
**havendo** blocked. O comentário logo acima (`bin/sdd:1490-1495`) descreve exatamente este modo
de falha e afirma que a correção foi feita — "the status goes into a variable BEFORE the grep".
A variável existe (`ckstatus`, `bin/sdd:1496`), mas o **pipe continua lá**: a correção tirou o
`checkpoint_rows | cut` de dentro do pipeline e deixou o `printf`. Hoje só não morde porque
`$ckstatus` cabe no buffer de 64 KB do pipe. O comentário promete uma garantia que a linha
seguinte não entrega, e o preço da falha é o pior do kit: a linha **não** para quando devia, e o
runner queima o `phase_budget` inteiro contra a parede que ele já sabia estar lá.
Segunda ocorrência viva da mesma família em `bin/sdd:1084` (probe do `sdd preflight`).

**2. A degradação `PUBLISH_ON_REVIEW_BLOCKED=draft` não escreve linha nenhuma** —
`bin/sdd:1519-1522`:

```bash
if [ "$phase" = "REVIEW" ] && [ "$PUBLISH_ON_REVIEW_BLOCKED" = "draft" ]; then
  warn "PUBLISH_ON_REVIEW_BLOCKED=draft — moving on to PR in draft mode"
  force_phase="PR"; continue
fi
pipeline_log_line ...          # :1523 — nunca alcançado neste ramo
autonomy_blocked_row ...       # :1524 — nunca alcançado neste ramo
```

O `continue` salta **antes** do diário e antes do escritor do ledger. O kit estourou o orçamento
de REVIEW e se degradou sozinho para um PR em draft — o evento de autonomia mais interessante
que uma missão pode produzir — e a série registra apenas uma sequência de sessões de REVIEW com
`gate: fail` seguida de uma fase PR, sem nenhum sinal do porquê. O juiz lê a série; este evento
é invisível para ele.

**3. Os dois instrumentos sobre o mesmo ledger discordam do eixo** — `bin/sdd:1698` contra
`bin/sdd:1760`. A série agrupa escaladas **dentro** do grupo de `kit_sha`
(`$ok | map(select(.kit_sha == $shas[-1])) | group_summary`, `bin/sdd:1774`), portanto está
correta. O `sdd autonomy` faz `group_by(.kind)` sobre o **arquivo inteiro**, sem filtro de
`kit_dirty` e sem eixo de versão. Um humano lendo a tabela do `sdd autonomy` ao lado do veredito
verá contagens de escalada diferentes para o mesmo período, sem nada explicando a divergência —
e a versão do kit é justamente o eixo que o ledger existe para medir.

## Métrica

Binária e verificável, três asserções:

1. `tests/run-all.sh` verde com o catálogo de mutação em **28/28** (hoje 25/25 — régua
   deslocada +2 pelo review pré-merge do I13.3, ver nota de 2026-08-16 no `checkpoint.md`;
   re-medido verde em 2026-08-16), com as três mutações novas provando que cada conserto tem
   sensor que morre quando sabotado.
2. Um `checkpoint.md` com status `blocked` e corpo **maior que 64 KB** faz o Jidoka disparar
   (`rc 3`); hoje o mesmo fixture é a condição que expõe a corrida do `pipefail`.
3. Uma degradação `PUBLISH_ON_REVIEW_BLOCKED=draft` produz **exatamente uma** linha nova no
   ledger, e `sdd kaizen --series` a atribui ao `kit_sha` corrente sem inflar
   `excluded.unrecognized`.

## Resultado esperado

O ledger passa a registrar todo evento de autonomia que o runner produz, inclusive a
auto-degradação — que hoje some. O Jidoka do incremento `blocked` para de depender do tamanho do
checkpoint e passa a parar a linha sempre que deve. Os dois leitores do ledger — o `sdd autonomy`
(humano) e o `sdd kaizen --series` (juiz) — passam a contar escaladas sobre o mesmo eixo de
`kit_sha`, e por isso a concordar.

A partir desta missão, as linhas que a série acumula descrevem o que de fato aconteceu. Como o
veredito ao lado registra `latest: null`, nenhuma linha histórica precisa ser reinterpretada:
o conserto chega antes do dado.

## Fora de escopo

- **Renomear o contrato PT-BR** (`aprovacao`/`versao`/`titulo`, `00-missao.md`/`01-plano.md`,
  117 referências) — missão própria pelo tamanho; permanece no `TODO.md`.
- **`templates/` multi-idioma** — depende da renomeação acima; permanece no `TODO.md`.
- **Default de `SDD_MUTATION_JOBS`** — a suíte mediu **37,4 s** no default nesta sessão, contra o
  alvo "<30 s" que a D7 do `CONTEXT.md` fixou para o I13.3. É decisão do humano (`nproc` é
  GNU-only) e esta missão **piora** o número em três mutantes. Registrado no `TODO.md` com a
  medição; não consertado aqui.
- **`latest_matching` com `sort` lexicográfico** (`bin/sdd:224`, quebra a partir da 10ª rodada) —
  família diferente (ancoragem de gate). O `gate_KAIZEN` já contorna casando por conteúdo.
  Permanece no `TODO.md`.
- **Sensor durável do preflight headless executar `TEST_CMD`** — o maior item aberto do
  `TODO.md`, mas exige sessão paga dentro da suíte; missão própria.

## Gate PLAN-AUTO

Preenchido pelo laço kaizen **com evidência**. `aprovacao:` fica **vazia** por contrato
(pré-I13.4): o kaizen não aprova o próprio plano, e o `gate_KAIZEN` (`bin/sdd:1846`) reprova se
ela vier preenchida. A tabela abaixo existe para o humano decidir, não para liberar o pipeline.

| # | Critério | Status | Evidência |
|---|---|---|---|
| a | Grill sem perguntas abertas não endereçadas (🚩 vazia ou itens deferidos com dono) | ✗ | Não houve grill: plano nascido headless do laço kaizen (ADR 0002). As 🚩 abertas do `CONTEXT.md` foram conferidas — a "sessão kaizen ganha linha própria no ledger?" já está respondida no código (`bin/sdd:1768`, `.phase == "KAIZEN"` vira `$meta` e é contada em `excluded.meta`); a de `docs/adr/` na `surface()` segue aberta e fora deste escopo. Por isso a aprovação humana é o gate |
| b | Checklist kaizen 100% ✅ e checklist DDD 100% ✅ ou `n/a` justificado | ✅ | Tabela K1–K8 abaixo; DDD `n/a` justificado |
| c | Plano passa no teste de autocontenção (sessão nova só com 00/01/checkpoint executa) | ✅ | Todo `arquivo:linha` do `01-plano.md` foi aberto nesta sessão; o trecho de código de cada defeito está citado verbatim no plano, não por referência |
| d | Todo incremento do `checkpoint.md` tem Check executável (comando → esperado) | ✅ | 3 incrementos, 3 Checks, todos comando → resultado esperado |
| e | `versao:` confirmada pelo humano (ou `JIRA_ENABLED=false`) | ✅ | `JIRA_ENABLED=false` em `.sdd/config.sh:28`; `versao:` vazia satisfaz o critério |

## Checklist kaizen (`kaizen-software`)

| # | Item | Status | Nota |
|---|---|---|---|
| K1 | Gemba — fui ver onde o trabalho acontece | ✅ | Os três defeitos lidos no `bin/sdd` do `HEAD` `90f9ce9`; série e `~/.sdd/` inspecionados |
| K2 | Problema declarado com métrica | ✅ | Mutação 25→28, Jidoka com checkpoint >64 KB, 1 linha de ledger na degradação |
| K3 | Desperdícios identificados e cortados | ✅ | Um item da triagem já estava resolvido no código sem marca no `TODO.md` (`4ec9752`); planejá-lo de novo seria retrabalho. Anotado, não replanejado |
| K4 | Fatiamento incremental, cada fatia verificável | ✅ | I1/I2/I3 independentes; cada um commita com sua mutação |
| K5 | Check por artefato (rótulo ≠ artefato) | ✅ | Os três Checks rodam comando e leem saída; nenhum aceita "o agente disse que fez" |
| K6 | Jidoka — o que para a linha está definido | ✅ | I1 **é** o Jidoka. Se a asserção do checkpoint >64 KB não ficar vermelha antes do conserto, o incremento vai a `blocked`: sem Red observado não há prova de que o sensor mede |
| K7 | SDCA — a melhoria vira padrão (doc/rule/teste) | ✅ | 3 mutações no catálogo + a convenção do herestring já está no `CLAUDE.md`; I2 documenta o vocabulário novo em `docs/pipeline.md` |
| K8 | Registro no KAIZEN_LOG | ✅ | Fase DOCS, com o antes/depois de mutação e do tempo de suíte |

## Checklist DDD (`ddd`) — condicional

`n/a — sem toque de domínio: a mudança é no runner bash e no formato de uma linha JSONL; não há
aggregate, bounded context nem contrato entre módulos envolvido.`

## Decisões do grill (não re-litigar)

1. **O eixo do lote é o ledger, não o `TODO.md` inteiro.** Os três itens escolhidos compartilham
   uma causa: o instrumento que o laço kaizen lê ainda não conta a verdade toda. Itens de valor
   comparável mas de outra família (preflight headless, contrato PT-BR) ficaram fora **de
   propósito** — lote coeso fecha; lote grande atrasa a primeira volta produtiva da série.
2. **Consertar agora, não depois da série encher.** `latest: null` significa que nenhum dado
   histórico será reinterpretado. Depois de 3 missões, o mesmo conserto exigiria decidir o que
   fazer com linhas já escritas sob o ponto cego.
3. **I3 entra apesar de ser só a visão humana.** A série já está correta (`bin/sdd:1774`), então
   o juiz não é afetado. Entra porque dois instrumentos sobre o mesmo ledger que discordam
   corroem a confiança no instrumento — e o laço inteiro depende dessa confiança.

## Pendências para o humano

- **Vocabulário do evento de degradação (I2).** O plano propõe `event: "degraded"` com
  `kind: "review-to-draft"`, mantendo `event: "blocked"` reservado para run que de fato para. A
  alternativa é reusar `event: "blocked"` com um `kind` novo — mais barata (herda o eixo de
  `kit_sha` e a agregação sem tocar na série), porém registra como "parou" um run que
  **continuou**. O plano escolhe a primeira e explica o custo em `01-plano.md`; se o humano
  preferir a segunda, é trocar o valor de um campo e a asserção correspondente.
- **Alvo de tempo da suíte.** Medido 37,4 s no default contra o "<30 s" da D7. Esta missão soma
  três mutantes. Subir `SDD_MUTATION_JOBS`, subir o alvo, ou aceitar — decisão registrada no
  `TODO.md`, não tomada aqui.
