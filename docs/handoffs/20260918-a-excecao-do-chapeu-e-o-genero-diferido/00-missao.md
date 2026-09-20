---
missao: 20260918-a-excecao-do-chapeu-e-o-genero-diferido
titulo: o repo-alvo declara a exceção do chapéu por caminho, e um bug decidido fica visível sem bloquear
data: 2026-09-18
versao: n/a — JIRA_ENABLED=false neste repo
branch: feat/a-excecao-do-chapeu-e-o-genero-diferido
aprovacao: humano-2026-09-18
adr: docs/adr/0009-the-genre-gains-deferred-and-hats-gain-project-exceptions.md
ddd: n/a
---

# Missão — a exceção do chapéu e o gênero diferido

> Escrita a partir do plano `~/.claude/plans/2026-09-18-a-excecao-do-chapeu-e-o-genero-diferido.md`,
> aprovado no grill de 2026-09-18 com o humano presente. Esta é a **T2**, segunda missão nascida dos
> achados de `ACHADOS-20260917-sales-quote.md`. A **T1** (`20260918-a-sessao-morreu-e-o-gate-levou-a-culpa`,
> PR #46) fechou os quatro achados em que o kit **mentia** sobre o que aconteceu.

## Problema (Gemba)

Duas famílias, medidas no `sales_quote` em 2026-09-17/18:

**O chapéu para trabalho certo.** Três ocorrências, dois chapéus. Uma sessão de QA de 759 s /
**US$ 11,32** parou em `BLOCKED` por tocar `.github/workflows/e2e-staging.yml` — a regra do próprio
alvo *obriga* a rever o piso de casos ao acrescentar spec. Uma DOCS de 916 s / **US$ 6,24** parou
por 18 linhas certas em `.claude/napkin.md`, onde o `CLAUDE.md` do alvo manda pôr gotcha. Uma
terceira parou por 30 linhas certas em `PRODUCT.md` — e essa foi consertada com **remendo literal**
(`796e334`: `PRODUCT.md` entrou no `writes:` de todo projeto que usa o kit), que é exatamente a
lista que cresce um nome por projeto. `DESIGN.md`, irmã das duas, ainda bloqueia.

**O gênero é binário e o bug decidido some.** Na SQ-129 o humano decidiu quatro bugs (commit
`383df146`, seção `## Decisão` no corpo de cada arquivo) e **não podia** trocar `Closable by:` para
`agent` — os quatro voltariam a travar o `gate_QA` da missão em voo — nem deixar `human`, que os
torna invisíveis ao laço para sempre. Inventou convenção no rodapé e a troca virou o incremento
`I6` da SQ-130: passo manual que alguém tem de lembrar.

**E o campo não existe até alguém marcá-lo.** `grep -rn Closable ~/.claude/skills/qa-*` → **0**; o
template local do alvo (`docs/qa/templates/bug.md:3`) também não tem o campo. Em repo-alvo novo a
Âncora 3 inteira roda em regime "ausente ⇒ bloqueia" até alguém descobrir por quê.

Âncoras de código lidas em `a96923d`: `load_config` (`bin/sdd:102`, `ADR_DIR` em `:174`),
`HAT_WRITES_BASE` (`:1713`), `hat_expand` (`:1733`), `hat_writes` (`:1749`), `hat_path_allowed`
(`:2787`), `hat_guard_check` (`:2801`, mensagem em `:2835`), `adr_dir_ok` (`:5703`), `gate_QA`
Âncora 3 (`:1030-1106`), `cmd_install` (`:3691`), `cmd_preflight` (`:3933`).

## Métrica

Quatro binárias, todas por comando (§ Verificação do `01-plano.md`):

1. Fixture do hat que toca `.github/workflows/e2e-staging.yml`: sem `HAT_WRITES_EXTRA` →
   `3|hat-crossed`; com a chave → `0`, nenhuma linha `blocked`. E `"sdd-qa: ../x"` → `die` citando `..`.
2. Quatro regimes do gênero: `deferred` segue **e** o `gate_why` nomeia o bug; `agent` e ausente
   bloqueiam; `human` segue sem nome.
3. Template sem campo: `preflight` vermelho com remédio; `install --force` insere; segundo
   `--force` é no-op (`md5sum` igual).
4. `sdd adr check --mission 20260918-a-excecao-do-chapeu-e-o-genero-diferido` limpo;
   `docs/adr/0009-*` existe; `0006` diz `Amended by: 0009`.

## Resultado esperado

O repo-alvo declara a exceção do chapéu **por caminho**, numa chave só (`HAT_WRITES_EXTRA`), com
guarda no molde do `adr_dir_ok` — literal, relativo, sem `..`, sem metacaractere exceto o sufixo
`/**`. Um bug que o humano decidiu e que esta missão não paga fica **visível sem bloquear**
(`Closable by: deferred`, terceiro valor no mesmo campo, com os nomes impressos no `GATE_WHY` de
sucesso). O campo nasce no template **antes** do primeiro bug, semeado pelo `sdd install --force` e
cobrado pelo `sdd preflight`. Tudo por poka-yoke — chave validada no `load_config`, âncora com
mutante, `preflight` vermelho —, nunca por frase de prompt.

## Fora de escopo

| Item | Destino | Motivo |
|---|---|---|
| #6 fase manual no ledger | **T3** | 6º `event`, dois leitores, soma de baldes, `comparable_row` — pergunta de desenho própria |
| #7 teto não conhece missão reaberta | **T3** | precisa definir "reaberta" antes de codar |
| obs (T5) `Test Coverage = A` sem caso negativo | **T3** | toca `agents/sdd-reviewer.md` + âncora nova no `gate_REVIEW`; maior risco de gate insatisfazível |
| citação **não cercada** acima do campo (`TODO.md:71`) | fica | limite declarado na ADR 0006; fora do tema |
| drift de comentário de código (metade do item `:647`) | item próprio ou fica | decisão de leitura no I7 |
| `DESIGN.md` no `writes:` | nada | ninguém mediu; a chave do I6 existe exatamente para isso |

## Gate PLAN-AUTO

| # | Critério | Status | Evidência |
|---|---|---|---|
| a | Grill sem perguntas abertas não endereçadas | ✅ | § Decisões (G1–G5), plano de 2026-09-18 |
| b | Checklist kaizen 100% ✅ e checklist DDD `n/a` justificado | ✅ | abaixo |
| c | Plano passa no teste de autocontenção | ✅ | `01-plano.md` carrega os 8 incrementos com âncora de código |
| d | Todo incremento do `checkpoint.md` tem Check executável | ✅ | 8 de 8 |
| e | `versao:` confirmada (ou `JIRA_ENABLED=false`) | ✅ | `JIRA_ENABLED=false` neste repo |
| f | `adr:` é uma decisão | ✅ | `docs/adr/0009-*`, alocado por `sdd adr new` no I0 |

## Checklist kaizen (`kaizen-software`)

| # | Item | Status | Nota |
|---|---|---|---|
| K1 | Gemba — fui ver onde o trabalho acontece | ✅ | 10 funções lidas com âncora, 4 sensores mapeados, skill e alvo medidos no dia |
| K2 | Problema declarado com métrica | ✅ | § Métrica — quatro binárias por comando |
| K3 | Desperdícios identificados e cortados | ✅ | defeito (linha parada em trabalho certo), espera (humano chamado por 18 linhas corretas), retrabalho (trocar gênero à mão) |
| K4 | Fatiamento incremental, cada fatia verificável | ✅ | 8 incrementos, cada um com Check |
| K5 | Check por artefato (rótulo ≠ artefato) | ✅ | fixture, mutante, `md5sum`, rc |
| K6 | Jidoka — o que para a linha está definido | ✅ | a chave **alarga** permissão ⇒ probe de sabotagem obrigatório antes do merge |
| K7 | SDCA — a melhoria vira padrão | ✅ | ADR 0009, D26 no `CONTEXT.md`, `docs/failure-modes.md`, rule § 6 |
| K8 | Registro no KAIZEN_LOG | ✅ | I7 |

## Checklist DDD (`ddd`) — condicional

`n/a — sem toque de domínio: a missão acrescenta uma chave de config, um valor de enum e um passo
de seed; nenhum aggregate, bounded context ou contrato entre módulos muda.`

## Decisões do grill (não re-litigar)

1. **G1 — duas missões, não uma.** T2 = #4 + #10 + #3 (#2 fecha pelo #3); T3 = #6, #7, T5. Uma só
   teria 4 temas e 3 desenhos abertos.
2. **G2 — `Closable by: deferred`**, terceiro valor no MESMO campo, mesmo extrator, um mutante. A
   âncora pula como pula `human`; o `GATE_WHY` **lista os deferred por nome**. Recusados:
   `agent@<missão>` (slug errado falha aberto; obrigaria a planejar a pagadora antes de diferir) e
   campo separado `Decided:`/`Owner:` (segundo extrator cuja toda frouxidão falha aberta).
3. **G3 — `HAT_WRITES_EXTRA`**, UMA chave, por chapéu e caminho. Recusados: uma chave por chapéu
   (8 chaves no `schema.md`) e arquivo `.sdd/hats/*.writes` (segundo lugar de config).
4. **G4 — `sdd install` semeia + `sdd preflight` cobra**, diff-first como os espelhos. Recusados:
   só o preflight (repo novo paga uma volta antes de alguém ler) e o `sdd-qa` semear (frase de
   prompt, sessão paga, depende de a QA vir antes do primeiro bug).
5. **#2 fecha pelo #3 sem reabrir a ADR 0006:** ela é **emendada** (terceiro valor no enum que ela
   criou), não contrariada. A direção óbvia — contar só a procedência da missão corrente — segue
   recusada pelo argumento dela: *"trades a loop for silent debt"*.

## Pendências para o humano

- **I6 é passo do humano, depois do merge:** escrever `HAT_WRITES_EXTRA` no `.sdd/config.sh` do
  `sales_quote` e rodar `sdd install --force` lá. O plano escreve o diff; ninguém o aplica por ele.
- **Copilot está sem cota** desde o PR #46 — conte com uma revisão a menos.
