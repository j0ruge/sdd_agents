---
missao: 20260826-o-laco-da-qa
titulo: a fase QA para de girar em bug que ninguém no pipeline tem permissão de fechar
data: 2026-08-26
versao:
branch: fix/o-laco-da-qa
aprovacao: humano-2026-08-26
ddd: n/a — sem toque de domínio: o kit é bash + markdown, e a mudança é em gate e contrato de agente
---

# Missão — a fase QA para de girar em bug que ninguém pode fechar

> Escrito pelo `sdd-planner` com o humano presente. É a única fonte da **intenção**; o `01-plano.md`
> é a fonte do **como**. Toda sessão headless começa lendo estes dois.

## Problema (Gemba)

**Medido na missão `20260825-frete-cif-fob` do `sales_quote`, em 2026-08-26.** A missão custou
US$ 144,88 em 23 sessões. A fase QA sozinha custou **US$ 73,32 em 12 sessões** — mais que todo o
resto do pipeline somado (EXEC + REVIEW + DOCS + PR + TICKET = US$ 71,56 em 11 sessões). Sete
daquelas doze sessões estavam num laço que **nenhuma delas podia vencer**.

O laço tem duas engrenagens, e nenhuma é bug de código — as duas são contrato que não fecha.

**Engrenagem 1: a Âncora 3 não tem dono.** `bin/sdd:598-604` exige zero `Status: open` na árvore
**inteira** do registry, sem relação com a missão corrente, e o `GATE_WHY` promete a saída:
*"they become fix increments (QA⇄EXEC loop)"*. A promessa é falsa para uma classe inteira de bug:

| quem | pode escrever `Status:`? | evidência |
|---|---|---|
| `sdd-executor` | **não sabe que o registry existe** | `grep -c 'qa/bugs\|Status:' agents/sdd-executor.md` → **1**, e é a linha `:30`, sobre o `checkpoint.md` |
| `sdd-qa` | **proibido por regra não-negociável** | `agents/sdd-qa.md:142` — *"the `docs/qa/` tree belongs to the skills — you read and complement, you do not rewrite"* |
| as skills `qa-report`/`qa-execution` | sim, são as donas | `agents/sdd-qa.md:139` |

Para um bug **sanável**, o ciclo fecha: QA acha → `F<n>` conserta → a skill verifica e escreve
`verified`. Para um bug que pede **decisão de produto**, não há caminho nenhum — e a Âncora 3
barra por ele do mesmo jeito. O `§ 5` do `agents/sdd-qa.md:96-101` afirma que esse item
*"do not block the pipeline"*. **É falso, e o `gate_QA:598` é a prova.**

**Engrenagem 2: "moveu o disco" é lido como progresso.** `bin/sdd:3464-3486` — sessão que reprova
o gate **e commita** faz o runner dizer *"carrying on"* e abrir mais uma volta. Só **duas** sessões
seguidas sem mover o disco disparam `BLOCKED … no-progress`, que é o único evento que convoca o
humano. Numa fase cujo gate ninguém pode satisfazer, todo achado legítimo vira um commit e **todo
commit compra a volta seguinte**. As sete rodadas registraram isso: as instruções *"não commite"*
das iterações 3, 4 e 6 foram todas desobedecidas — **com razão**, porque cada uma achou algo real.
O erro nunca esteve nas sessões.

## Métrica

Fatos binários, verificáveis por comando:

1. Um registry com um bug `open` de gênero humano **não** reprova o `gate_QA`. Regime novo em `tests/check-gates.sh`.
2. Um registry com um bug `open` de gênero agente **continua** reprovando. Mesmo arquivo, asserção diferencial contra o item 1.
3. Um bug `open` **sem** o campo de gênero continua reprovando (fail-safe para os arquivos que já existem).
4. `30-handoff-qa.md` com `status: blocked` faz o runner sair **3 na primeira sessão**, sem depender do heurístico de fingerprint. Hoje ele precisa de duas sessões paradas.
5. `./bin/sdd health --with-mutation` → `N caught of N` com os mutantes novos dentro, e `all N gates have a mutation in the catalogue`.

## Resultado esperado

A Âncora 3 passa a distinguir **gênero**: bug que pede decisão humana não barra o pipeline — que é
o que o `§ 5` do `agents/sdd-qa.md` já promete e o código não cumpria. Bug sanável continua
barrando e continua virando `F<n>`, porque para ele o ciclo fecha.

E `status: blocked` no handoff passa a ser escalonamento **imediato**: o token já significa
exatamente isso em `bin/sdd:1602` (*"the line stopped; the runner returns 3 and a human has to
act"*), e o runner deixa de exigir que uma fase insatisfazível prove sua insatisfazibilidade duas
vezes, ao preço de uma sessão cada.

**O que NÃO muda:** o piso de `QA_MAX_ITER`, o formato do `F<n>`, e a regra de que o `docs/qa/` é
das skills. Nenhum agente do kit ganha permissão de escrever `Status:`.

## Fora de escopo

- **Implementar a ADR 0005** (juiz lê todos os repos, composição visível, guarda de TMPDIR) — está
  decidida e mergeada em `6e82acb`, com `Implementation: NOT YET IN THE RUNNER` no cabeçalho. É a
  missão seguinte. Fica fora daqui porque toca outro subsistema (`kaizen_series`,
  `autonomy_kit_stamp`) e porque o preço desta missão é o que torna aquela pagável.
- **Fazer o `sdd-executor` conhecer o registry.** Com a opção C ele não precisa: bug de gênero
  humano deixa de barrar, e bug de gênero agente fecha pelo ciclo que já existe.
- **O CI vermelho do `sales_quote`.** 25 de 25 runs de `ci` falharam desde 2026-08-24, com
  `"steps": []` — infraestrutura, não código, e é outro repo.

## Gate PLAN-AUTO

| # | Critério | Status | Evidência |
|---|---|---|---|
| a | Grill sem perguntas abertas não endereçadas | ✅ | 1 decisão de desenho (a forma do conserto da Âncora 3), decidida pelo humano; ver "Decisões do grill" |
| b | Checklist kaizen 100% ✅ e DDD `n/a` justificado | ✅ | Tabela abaixo; DDD `n/a` no frontmatter, com justificativa |
| c | Plano passa no teste de autocontenção | ✅ | Ver `01-plano.md` § "Teste de autocontenção" — 6 itens foram acrescentados por causa dele |
| d | Todo incremento tem Check executável | ✅ | 4 de 4 no `checkpoint.md` |
| e | `versao:` confirmada pelo humano | ✅ | `n/a` — `.sdd/config.sh:27` traz `JIRA_ENABLED=false`, e o `gate_PLAN` só cobra `versao:` quando é `true` (`bin/sdd:442-444`) |

## Checklist kaizen (`kaizen-software`)

| # | Item | Status | Nota |
|---|---|---|---|
| K1 | Gemba — fui ver onde o trabalho acontece | ✅ | As 3 âncoras lidas no arquivo: `bin/sdd:1602`, `agents/sdd-executor.md` (grep = 1), `agents/sdd-qa.md:96-101` e `:142` |
| K2 | Problema declarado com métrica | ✅ | US$ 73,32 / 12 sessões / 7 no laço, do ledger; 5 fatos binários na Métrica |
| K3 | Desperdícios identificados e cortados | ✅ | Cortados: ensinar o registry ao executor (desnecessário sob C), e a ADR 0005 (outro subsistema) |
| K4 | Fatiamento incremental, cada fatia verificável | ✅ | 4 incrementos; I1 é formato, I2/I3 são runner, I4 é contrato de agente |
| K5 | Check por artefato (rótulo ≠ artefato) | ✅ | Os Checks leem `^  ok    ` dos sensores, e o I2 é **diferencial** (dois regimes comparados entre si) |
| K6 | Jidoka — o que para a linha está definido | ✅ | `01-plano.md` § "O que para a linha" |
| K7 | SDCA — a melhoria vira padrão | ✅ | I4 corrige a frase falsa do `§ 5`; o `CLAUDE.md` ganha a lição do gate insatisfazível na fase DOCS |
| K8 | Registro no KAIZEN_LOG | ✅ | Previsto na DOCS, com antes/depois: 12 sessões de QA numa missão → o que a próxima medir |

## Checklist DDD (`ddd`) — condicional

`n/a — sem toque de domínio`: o kit é bash + markdown; a mudança é em condição de gate e em texto
de contrato de agente. Não há agregado, contexto delimitado, evento nem entidade envolvidos.

## Decisões do grill (não re-litigar)

1. **A Âncora 3 distingue gênero (opção C), e não conta só bugs da missão (A) nem dá ao `sdd-qa` o poder de aplicar `wont-fix` (B).** O `§ 5` já promete o comportamento certo; o defeito é o código não cumprir. A e B mudariam a promessa para caber no código; C faz o inverso.
2. **B foi recusada por lição desta sessão:** os quatro `wont-fix` que desbloquearam a missão 1 foram decisão do humano, e **dois eram P1** (Data-Loss e Trust-Damage). Um agente com esse poder teria fechado os quatro sozinho.
3. **Bug sem o campo de gênero continua barrando** — fail-safe. Os arquivos que já existem não têm o campo, e um default permissivo desligaria a Âncora 3 para todo o registry legado de uma vez.
4. **Nenhum agente do kit ganha permissão de escrever `Status:`.** A regra do `agents/sdd-qa.md:142` fica de pé; ela é o que torna a opção C necessária, não um obstáculo a ela.
5. **A ADR 0005 fica para a missão seguinte**, por ordem com argumento: o valor dela só aparece depois de 3 missões de repo-alvo, e cada uma custa ~US$ 145 enquanto este laço existir.

## Pendências para o humano

Vazio.
