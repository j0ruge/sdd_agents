---
verdict: indeterminado
kit_sha_judged: 6323c6f
date: 2026-09-30
---

# Veredito — `6323c6f`, a janela 2 partida por um chore de backlog

Todos os números abaixo saem de `sdd kaizen --series`, lido uma vez nesta sessão com a linha que o
prompt de boot entregou. A contagem de intervenções (D12/D16) não está na série: sai de
`sdd autonomy --all-repos --by-mission` e vai citada onde aparece.

## A resposta curta

**`indeterminado`, porque a guarda diz `sufficient: false` com `why: ["floor"]`.** A fatia julgada
tem `missions_with_session: 1` contra `floor: 3`. `degenerate_axis` é `false`: o eixo funciona e
esperar ajudaria — mas, como explico abaixo, esperar sobre `6323c6f` não é o que a janela queria
medir.

## Que mudança está sendo julgada

`latest` = `6323c6f` (merge do PR #184), `previous` = `5b98087` (merge do PR #183, que **abriu a
janela 2** com o kit congelado — linha F3 da gaveta). `git log --oneline 5b98087..6323c6f` mostra
dois commits que formam uma mudança lógica só: `450afee chore(todo): registra dois achados da missão
SQ-152 e a reincidência do approve; catraca vai a 89` e o seu merge. `git show --stat 6323c6f`:
`TODO.md` (+18) e `tests/health-baseline.txt` (1 linha, a catraca 87 → 89). **Nenhuma linha de
`bin/`, `agents/`, `templates/` ou `config/` mudou.** Do ponto de vista do que uma fase de alvo
executa, `6323c6f` é comportamentalmente idêntico a `5b98087`.

Por isso este veredito não julga mudança de comportamento nenhuma: julga um eixo que se moveu sem
que o kit mudasse. Isso não autoriza ler as duas fatias como uma só — a série agrupa por `kit_sha`
cru (D4, ADR 0003), a guarda é do runner, e somar as fatias à mão seria recalcular a série.

## A composição

`latest.composition`: `/home/joruge/repos/sales_quote`, 1 missão (1 com sessão).
`previous.composition`: `/home/joruge/repos/sales_quote`, 3 missões (3 com sessão). As somas
fecham contra a guarda: 1 = `missions_after_change`, 1 = `missions_with_session`. Repo-alvo real,
nenhum clone descartável nem fixture sob `/tmp` — a evidência que a ADR 0003 pede. A única missão
de `latest` é `20260930-e2e-local-diz-por-que-caiu`, e ela é a **mesma** missão que fecha a
`previous`: TICKET, EXEC, QA e REVIEW caíram em `5b98087`; QA, DOCS e PR em `6323c6f`. O chore foi
mergeado (21:54) com a missão em voo, entre duas fases — o que explica por que nenhuma escalada
`kit-touched` foi escrita: a guarda de kit vigia a janela de uma sessão, não o intervalo entre fases.

## A janela está partida, e o campo diz

`guard.window_broken: true`, `guard.window_missions_stranded: 3`. As três missões gastas desde o
último veredito (`aviso-diretoria-por-email`, `justificativa-pedido-alcada` e
`e2e-local-diz-por-que-caiu`) deixaram evidência em `5b98087`, versão que não é a julgada. A janela
2 era exatamente essas três missões sobre `5b98087`; o chore que registrou achados da terceira
moveu o `latest` e as deixou em `previous`, onde a série as mostra mas nenhum veredito as gradua.
Não veta (o veto aqui é o piso), mas encolhe: a fatia julgada tem **1** missão e **3** sessões.

Lida sozinha, a `previous` alcançaria o piso — `missions_with_session: 3` —, e é por isso que a
ruptura custa caro: US$ 110,18 de evidência (`previous.cost_usd`) em harness único (`2.1.283` nas
duas fatias, `guard.harness` idem) ficaram sem veredito. A causa não é descuido de uma pessoa, é
uma colisão de regras: o princípio 5 manda registrar o achado no `TODO.md`, a catraca manda mover a
baseline no mesmo commit, e o congelamento manda não commitar na `main`. Registrei a colisão no
`TODO.md` (seção aberta, último item), com a direção.

## Os números, `previous` → `latest`

| | `previous` (`5b98087`) | `latest` (`6323c6f`) |
|---|---|---|
| missões / com sessão | 3 / 3 | 1 / 1 |
| sessões | 53 | 3 |
| `outcomes` (advanced · churned · idle) | 44 · 9 · 0 | 3 · 0 · 0 |
| `advance_rate` | 0,83 | 1 |
| `moved_rate` | 1 | 1 |
| rótulos (ok · leve · refez) | 10 · 4 · 2 | 3 · 0 · 0 |
| escaladas | `hat-crossed: 1` | nenhuma |
| custo | US$ 110,18 | US$ 8,53 |

A `latest` é 3 sessões de cauda (QA US$ 1,11, DOCS US$ 5,81, PR US$ 1,61), todas `advanced` e `ok`.
Ela não diz nada sobre o kit: são as fases baratas de uma missão cuja parte cara ficou na outra
fatia. `advance_rate` 1 contra 0,83 é a comparação de uma cauda com três missões inteiras, não de
duas versões.

`excluded`: `non_comparable` 25, `unrecognized` 0, `meta` 6, `other_repo` 0 (como deve, desde a ADR
0005), `no_repo` 0. Nada encolheu a série sem nome.

Intervenções (`sdd autonomy --all-repos --by-mission`, *launches − 1*): `aviso-diretoria-por-email`
3 launches → 2; `justificativa-pedido-alcada` 2 → 1; `e2e-local-diz-por-que-caiu` 2 → 1. Quatro em
três missões, nenhuma sem mão humana — contra 2 em 3 da janela 1. Não é veredito (não há guarda
que o autorize); é o número que a próxima janela vai querer comparar.

## O que a `previous` ensina mesmo sem veredito — e vira o plano

Os `leve` da `previous` não merecem um dar de ombros. Pela régua de `20260829-o-incremento-que-andou`,
`leve` é sessão que escreveu e não fechou incremento, sessão que não escreveu, ou retry automático
em laço. Aqui é a primeira: **7 das 9 sessões `churned` da `previous` são da fase QA** (`detail`:
QA de `aviso` 1 · 3 · 0, de `e2e-local` 1 · 2 · 0, de `justificativa` 3 · 2 · 0). Lendo o
`gate_why` de cada linha (interpretação, não contagem): as três primeiras sessões de QA, uma por
missão, têm `step: "QA:exec"` e reprovam com `missing 30-handoff-qa.md` — é o sub-passo
`qa-execution` fechando o relatório, e o `gate_QA` testa o handoff na **primeira** linha
(`bin/sdd:1299`), então todo sub-passo anterior ao `close` reprova por desenho. Uma quarta é o
laço QA⇄EXEC desenhado (`2 bug(s) with Status: open … they become fix increments`). As três
restantes são o E2E vermelho com o app respondendo — fricção real de ambiente, que é justamente o
assunto da missão `e2e-local-diz-por-que-caiu` no alvo.

Ou seja: a rubrica de `outcome` (`ledger_outcome_defs`, `bin/sdd:3291`) tem braço de progresso para
o EXEC (`pending_*`, desde 2026-08-29) e para o REVIEW (`rounds_*`, desde 2026-08-31) e nenhum para
os sub-passos da QA. O instrumento conta o laço desenhado da QA como desperdício — a mesma classe
que as duas missões anteriores fecharam, uma fase adiante. É um sensor afirmando medir o que não
mede (régua D15), e o consumidor é o juiz e o humano que lê `sdd autonomy`. É a missão que nasce
aqui.

Os dois `refez` da `previous` são REVIEW. O de `justificativa` tem escalada `hat-crossed` atrás
(a única da fatia). O de `e2e-local` não tem escalada nem retry: sai do terceiro braço da rubrica
(`bin/sdd:9305`), cuja última linha na fatia é a r2 reprovando — o resto da fase seguiu em
`6323c6f`, então a própria partição da janela é a leitura mais provável desse rótulo.

## O que o humano decide

1. Se a janela 2 é refeita (congelar `6323c6f` ou o sha que vier e rodar mais três missões) ou se
   o kit descongela e a próxima janela abre depois da missão nascida aqui — que muda a régua de
   `outcome` e, portanto, mudaria os números de qualquer janela lida antes dela.
2. Aprovar (ou não) o plano em `00-missao.md` desta pasta: `aprovacao:` está vazio por regra.
