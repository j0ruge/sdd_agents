---
verdict: indeterminado
kit_sha_judged: bf001fe
date: 2026-08-31
---

# Veredito — `bf001fe`, o primeiro com a guarda satisfeita

> Fonte da verdade: `"$SDD_HOME/bin/sdd" kaizen --series`, lido no início desta sessão. Todo número
> abaixo sai de lá e é citado como veio. A leitura da D12 sai de
> `sdd autonomy --all-repos --by-mission`, citada com o comando ao lado, porque a série não a
> carrega (ela agrupa por `kit_sha` e contaria duas vezes a missão que atravessa duas versões).

## O que foi julgado

`bf001fe` é o merge do PR #32, e a mudança lógica é **um commit só**: `bc18adc`,
`docs(janela): a janela 2 abre o eixo — D18–D20 e o handoff autocontido`. O `git log --oneline -20`
mostra os dois lado a lado e o corpo de `bc18adc` diz o que ele prometia: registrar as decisões
D18, D19 e D20 e **abrir a janela de medição 2**. Ele mexeu em `CONTEXT.md` e em dois arquivos de
`docs/superpowers/specs/` — 199 inserções, **nenhuma linha de código**. O próprio commit declara a
consequência: *"Só docs e CONTEXT.md: a chave do carimbo não muda, a catraca não se move."*

Julgar mudança sem código é julgar uma aposta de processo, e a aposta era nominal: a D19 escolheu
`0408639` como eixo e disse que o sha do merge deste commit **é** o eixo. É esse eixo que a série
agora mede.

## A fatia `latest` (`bf001fe`)

**Composição — e ela vem antes de tudo.** Um repositório só:

| repo | missions | missions_with_session |
|---|---|---|
| `/home/joruge/repos/sales_quote` | 3 | 3 |

As duas somas fecham contra a guarda: `sum(missions) = 3 = missions_after_change` e
`sum(missions_with_session) = 3`, que é o número em que o piso morde. É a composição que a ADR 0003
pede — **evidência de repo-alvo de verdade**, não fixture, não clone descartável, não caminho sob
`/tmp`. Nenhuma linha da fatia nasceu no repo que constrói o kit.

Os números da fatia:

- `sessions: 23`, `outcomes: {advanced: 21, churned: 2, idle: 0}`
- `advance_rate: 0.91`, `moved_rate: 1` — **toda** sessão escreveu no disco
- `labels: {ok: 16, leve: 1, refez: 1}` — 18 células, que são exatamente 3 missões × 6 fases
- `escalations: {}` — **vazio**. Nenhum `blocked`, nenhum `degraded`. Em particular **nenhum
  `review-to-draft`**: o kit não baixou a própria régua nenhuma vez nesta janela, que é a coisa
  mais interessante que a série sabe dizer quando acontece, e aqui ela diz que não aconteceu
- `cost_usd: 175.96`

**A guarda, pela primeira vez na história do kit:**

```
missions_after_change: 3 · missions_with_session: 3 · sessions: 23
floor: 3 · sufficient: true · degenerate_axis: false
```

Isto nunca tinha acontecido. O corpo de `bc18adc` registra o ponto de partida — *"Nenhum `kit_sha`
da história chegou a 2"* —, e três `sdd kaizen` anteriores responderam `indeterminado` **por
construção**, não por prudência. A aposta da D19 era exatamente esta: congelar o kit num sha e
deixar três missões reais caírem em cima. Ela pagou.

**`excluded` está limpo nos cinco baldes:** `non_comparable: 15`, `unrecognized: 0`, `meta: 3`,
`other_repo: 0`, `no_repo: 0`. O `other_repo: 0` é o que a ADR 0005 exige — desde ela nada no ledger
é estrangeiro ao juiz, e um valor não-zero ali seria bug de kit, não recorte. O `no_repo: 0` importa
mais: é o balde que esvazia série sozinho, e ele está vazio. Os `meta: 3` são as sessões de kaizen
que o juiz nunca deixa inflarem a própria guarda (D10). Vale registrar o contraste com um achado
aberto: `sdd autonomy --all-repos --by-mission` ainda lista `clone/20260901-jornada-qa` e
`clone/20260903-placeholder`, missões de fixture vivas no ledger real (item aberto no `TODO.md`,
descoberto em `20260829-o-incremento-que-andou`) — e **nenhuma delas alcançou esta fatia**. A
contaminação existe e não chegou aqui.

## A fatia `previous` (`25029d5`) — e por que o veredito não é `melhorou`

| repo | missions | missions_with_session |
|---|---|---|
| `/home/joruge/repos/sdd_agents` | 1 | 1 |

Uma sessão. Uma. A fase PR da missão `20260829-o-incremento-que-andou`, rótulo `ok`,
`advance_rate: 1`, `moved_rate: 1`, `escalations: {}`, **US$ 2,07** — no repo do **kit**, não num
alvo.

Comparar `0.91` contra `1.00` aqui não é comparar duas medidas: é comparar 23 sessões de trabalho
real em `sales_quote` contra uma sessão de publisher no repositório que constrói o kit. Populações
diferentes, repositórios diferentes, tamanhos diferentes por duas ordens de grandeza no custo
(US$ 175,96 contra US$ 2,07). Um `piorou` lido de `1.00 → 0.91` sobre `n = 1` seria ruído promovido
a veredito; um `melhorou` seria atribuir 21 sessões `advanced` a uma edição de `CONTEXT.md`.

A D18 previu esta frase e a autorizou por escrito: *"O token do veredito é do juiz: `indeterminado`
é admissível, porque a fatia `previous` será só-kit (uma sessão) e um `melhorou`/`piorou` honesto
exige uma segunda janela."*

⚠️ **Este `indeterminado` é de um gênero diferente dos três anteriores, e a distinção é o resultado
da missão.** Os três antes dele diziam *"faltam missões"* — `guard.sufficient: false`, e nos piores
casos `degenerate_axis: true`, que é "esperar nunca funciona". Este diz **"a guarda está
satisfeita e a linha de base não é comparável"**. O primeiro é ausência de instrumento; o segundo é
o instrumento funcionando e apontando para uma base que ainda não existe. A base passa a existir na
janela 3, e ela existe *porque* esta fatia foi medida.

## O que os dois rótulos não-`ok` realmente dizem

16 de 18 células `ok`. As duas que sobram merecem uma frase cada, porque **nenhuma das duas é
fricção** — as duas são o instrumento.

**`leve` — REVIEW de `20260830-a-tela-que-mente-o-pagamento`** (2 sessões, `1 advanced · 1 churned`,
US$ 47,81). Pela rubrica de hoje, `leve` custa alguma coisa para ser ganho, e das três causas
possíveis esta é a do meio: uma sessão que **escreveu e não avançou**. Só que o REVIEW é um laço
**desenhado** — `REVIEW_MAX_ITER=3`, e as rodadas são derivadas do disco por
`review_rounds_on_disk()` (`bin/sdd:2512`), lendo os arquivos `40-review-r<N>.md`. Uma r1 que
aterrissa `40-review-r1.md` com achados reais e não alcança Grade A **avançou uma rodada** e o
ledger a lê como churn. É, letra por letra, o defeito que `20260829-o-incremento-que-andou`
consertou para o EXEC — o comentário em `bin/sdd:4924` diz *"`gate_EXEC` refuses once per increment
BY DESIGN"* — vivo uma fase adiante, na fase que custa mais.

**`refez` — QA de `20260830-o-rascunho-fantasma-do-mount`** (1 sessão, `0 advanced · 1 churned`,
US$ 11,40). `refez` é o sinal de fricção mais forte da rubrica, e aqui ele é falso. A rubrica
(`bin/sdd:4938`) carimba `refez` quando *"the phase's last session still failing its gate"*. Os
fatos da série e do `--by-mission` fecham num único relato possível: `escalations: {}` (a QA não
escalou), **1 lançamento** para a missão inteira (nenhum `sdd retry`, nenhum segundo `sdd run`), e
REVIEW, DOCS e PR **todos com sessão e todos `ok`** depois dela. Logo o `gate_QA` passou mais tarde,
**dentro do mesmo run e sem gastar sessão** — e uma passagem que não compra sessão não escreve
linha nenhuma no ledger. A rubrica pergunta "a última *sessão* passou?" quando quer dizer "a *fase*
fechou", e para uma fase que fechou de graça a resposta é `refez` para sempre. O achado já existe
aberto no `TODO.md` (`bin/sdd:1080`, *"gate que passa sem abrir sessão não gera evento nenhum"*),
registrado na missão `20260817-eixo-do-juiz`; o que esta janela acrescenta é o **consumidor**: não é
só o humano que acompanha que fica sem ver, é o juiz que carimba errado.

Somadas: **as duas únicas células não-`ok` da primeira janela suficiente da história do kit são
defeitos de medição, não de autonomia.** A leitura honesta de `21 advanced · 2 churned · 0 idle` é
que o kit atravessou três missões reais com fricção **próxima de zero** e um instrumento que ainda
não sabe dizer isso.

## Custo, e a semente que a D19 deixou marcada

Somando as células `cost_usd` do próprio `detail` (fecham nos US$ 175,96 publicados):

| fase | US$ | % |
|---|---|---|
| REVIEW | 72,39 | **41%** |
| EXEC | 39,95 | 23% |
| QA | 39,33 | 22% |
| DOCS | 12,51 | 7% |
| PR | 6,51 | 3,7% |
| TICKET | 5,26 | 3,0% |

A D19 parou a missão do custo do REVIEW com a semente medida em **39% de todo o gasto** e a
condição *"fica para depois do veredito"*. A janela que ela abriu re-mediu sozinha: **41%**, agora
sobre três missões de repo-alvo num só sha em vez de sobre o histórico inteiro. A semente não
apenas sobreviveu à medição — ela subiu.

## D12 — intervenções

Lido de `sdd autonomy --all-repos --by-mission`, pela regra *intervenções = lançamentos − 1*
(D16, emendada em 2026-08-28):

| missão | lançamentos | intervenções |
|---|---|---|
| `sales_quote/20260830-a-tela-que-mente-o-pagamento` | 1 | **0** |
| `sales_quote/20260830-o-rascunho-fantasma-do-mount` | 1 | **0** |
| `sales_quote/20260830-invariante-do-frete-no-agregado` | 3 | **2** |

**2 intervenções em 3 missões e 23 sessões.** Duas das três missões atravessaram TICKET → EXEC →
QA → REVIEW → DOCS → PR num único `sdd run`, sem o humano entrar na linha nenhuma vez — e uma delas
é justamente a que carrega o `refez` falso. Custo por missão: US$ 58,65.

## Veredito

**`indeterminado`** — e não por falta de missões.

A guarda está satisfeita (`sufficient: true`, `degenerate_axis: false`, 3 missões com sessão sobre
o piso de 3), a composição é 100% repo-alvo real, os cinco baldes de exclusão estão limpos e não
houve uma única escalada. O que falta é a **outra ponta da comparação**: `previous` é uma sessão de
US$ 2,07 no repo do kit, e nenhum `melhorou` ou `piorou` derivado dela seria honesto. A mudança
julgada também não tem mecanismo pelo qual pudesse mover autonomia — ela não tocou código.

O que `bf001fe` prometeu, ele entregou: **abriu o eixo**. Pela primeira vez existe um `kit_sha` com
evidência suficiente atrás dele, e a próxima mudança do kit é a primeira da história que nasce com
número atrás — que é a frase literal da D19. É isso que fecha a metade "o kit julga" do M2; a outra
metade é o humano decidir o plano nascido ao lado deste arquivo.

⚠️ **Aviso de régua para quem ler estes números depois.** Eles foram lidos sob a rubrica vigente em
2026-08-31, posterior a `20260829-o-incremento-que-andou`: `advanced` significa "o gate passou **ou**
o incremento andou". Números citados em handoffs anteriores a 2026-08-29 usam outra régua e não são
comparáveis a estes sem dizê-lo. E o plano nascido ao lado **mexe nesta mesma régua** para a fase
REVIEW: quando a janela 3 for lida, `leve` e `refez` não significarão mais exatamente o que
significam aqui, e o `KAIZEN_LOG.md` da missão nascida é o lugar onde o antes/depois fica medido.
