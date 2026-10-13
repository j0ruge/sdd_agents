---
verdict: melhorou
kit_sha_judged: 0270727
date: 2026-10-12
---

# Veredito — os lotes 5 e 6, sobre `0270727`

Todos os números abaixo saem de `sdd kaizen --series`, lido uma vez nesta sessão com a linha que o
prompt de boot entregou (`"/home/joruge/repos/sdd_agents/bin/sdd" kaizen --series`). A contagem de
intervenções (D12/D16) não está na série: sai de `sdd autonomy --all-repos --by-mission` e vai
citada onde aparece. Os fatos que nenhum dos dois comandos imprime (as linhas `manual` e o motivo de
cada escalada) foram lidos linha a linha no ledger e nos handoffs do alvo, e vão marcados como tal.
Nenhum número da série foi recalculado.

## A resposta curta

**`melhorou`**, com três limites que reduzem o quanto do ganho se atribui ao kit, sem inverter a
direção de nenhum número: a fatia `previous` é uma missão só e metade das sessões dela; o harness
mudou entre as fatias (2.1.289 → 2.1.291); e **três das cinco missões da `latest` fizeram a QA à
mão**, por uma lacuna do kit que esta janela mediu e que vira a missão nascida nesta pasta.

## Que mudança está sendo julgada

`previous.kit_sha` = `94123a4` (merge do PR #222, lote 4; `kit_shas_raw` = `89df2e5`, o chore #231)
e `latest.kit_sha` = `0270727` (merge do PR #244, lote 6; `kit_shas_raw` = `4f16a6d`, o chore #245).
`git log --first-parent 94123a4..4f16a6d -- bin agents templates config` mostra **três** versões de
comportamento no intervalo:

- `b411239` (#237, lote 5): `bin/sdd` +406, `bin/sdd-coordination.py`, `agents/sdd-qa.md`,
  `templates/checkpoint-notas.md` — seis sensores que falhavam abertos (a linha curta da tabela, o
  `deferred` sem decisão escrita, o relatório de outra missão, o kit já sujo editado de novo, o
  `red_norm`, a suíte herdando `GIT_DIR`), a nota `intervention:` só na volta que compra sessão, e a
  missão do kit escrita num worktree ligado (ADR 0016 §2);
- `fc32329` (#243): só `agents/sdd-executor.md` — a sabotagem do `R<n>` depois do refactor;
- `0270727` (#244, lote 6): `bin/sdd` +145/−68 e `agents/sdd-planner.md` — o censo do `GIT_DIR`, os
  leitores de bug com uma cerca só (`FENCE_AWK`), a árvore do kit fora do ambiente na guarda de kit,
  e o `sdd kaizen` recusando o checkout que os alvos executam (ADR 0017).

`b411239` e `fc32329` não compraram nenhuma linha comparável: a última sessão do alvo antes delas é
de 2026-10-06 e a seguinte já cai em `0270727`. Para o juiz, as três são **uma** mudança lógica — o
lote congelado no merge do lote 6 (`CONTEXT.md`, verbete *Janela de medição*) —, e é o lote que eu
julgo, não um sha. Os chores #241, #242 e #245 não tocaram caminho de comportamento e não partem nada.

## A composição

`latest.composition`: `/home/joruge/repos/sales_quote`, 5 missões, 5 com sessão.
`previous.composition`: `/home/joruge/repos/sales_quote`, 1 missão, 1 com sessão. As somas fecham
contra a guarda: 5 = `missions_after_change` e 5 = `missions_with_session`. Repo-alvo real, nenhum
clone descartável nem fixture sob `/tmp` — a evidência que a ADR 0003 pede.

O mesmo repo dos dois lados, mas **não a mesma mistura de trabalho**. A `previous` é uma missão de
produto (`20261005-mascaras-ncm-e-painel`) com QA de verdade em vários ciclos. A `latest` mistura
uma missão de backend com QA real e bug achado (`20261009-o-que-some-calado`), uma de tela com QA
real (`20261011-detalhe-e-lista-dizem-a-verdade`) e três em que o humano decidiu no grill que a QA
não se aplicava (`o-backlog-volta-a-medir`, `a-catraca-ganha-folga`, `o-rascunho-que-entra-cru`). As
missões baratas pesam na média, e o veredito leva isso em conta.

## A guarda

`missions_after_change: 5`, `missions_with_session: 5`, `sessions: 66`, `floor: 3`,
**`sufficient: true`**, `why: []`, `harness: ["2.1.291"]`, `degenerate_axis: false`.

- `why` vazio: nem `floor`, nem `harness_mixed`. A fatia julgada rodou inteira em 2.1.291. ⚠️ A
  `previous` rodou em **2.1.289**: dentro de cada fatia a máquina ficou parada, entre as fatias não.
  A guarda não mede isso (ela olha a mistura **dentro** da fatia julgada), então digo eu: parte da
  diferença abaixo pode ser do harness. Não tenho número que a descarte.
- **`window_broken: true`, `window_missions_stranded: 3`.** Três missões gastas desde o último
  veredito (2026-09-30) deixaram evidência numa versão que não é `0270727`. A série não as nomeia;
  o `--by-mission` lista exatamente três missões nesse intervalo fora da fatia — as duas do kit
  rodadas por `sdd run` (`20260930-a-sub-etapa-que-andou`, `20261002-onde-o-comando-do-humano-escreve`)
  e a `20261005-mascaras-ncm-e-painel`, cujas 22 sessões se dividem entre `c71913c` e `94123a4` (só 11
  delas estão na `previous`). Não é veto: a fatia julgada continua respondível. Encolhe a
  comparação, e é por isso que a `previous` é fina — uma missão, e metade dela.

`excluded`: `non_comparable: 25`, `unrecognized: 0`, `meta: 7`, `other_repo: 0`, `no_repo: 0`.
`other_repo: 0` é o esperado desde a ADR 0005; `no_repo: 0` diz que nada sem projeto esvaziou a série.

## O antes e o depois

| | `previous` = `94123a4` | `latest` = `0270727` |
|---|---|---|
| missões (com sessão) | 1 (1) | 5 (5) |
| sessões | 11 | 66 |
| `outcomes` | 10 advanced · 1 churned · 0 idle | **65 advanced** · 1 churned · 0 idle |
| `advance_rate` | 0,91 | **0,98** |
| `moved_rate` | 1 | 1 |
| rótulos | 3 ok · 1 leve · 1 refez | **25 ok** · 0 leve · 2 refez |
| escaladas | `kit-touched: 1` | `handoff-blocked: 1` · `hat-crossed: 1` |
| custo | US$ 55,23 | US$ 192,06 |
| `harness` | 2.1.289 | 2.1.291 |

A régua do `advanced` é a mesma nas duas fatias: ambas são posteriores a
`20260930-a-sub-etapa-que-andou`, o braço mais novo do yardstick. Nenhuma comparação aqui atravessa
troca de régua.

Intervenções, de `sdd autonomy --all-repos --by-mission` (*intervenções = launches − 1*, D16):

- `previous`: `20261005-mascaras-ncm-e-painel` — **a comparação por missão não está disponível**
  (corrigido na revisão do PR #247, achado do Codex). O comando dá 6 launches → 5 intervenções, mas
  conta a missão inteira, as 22 sessões, e 11 delas são de `c71913c`, fora da fatia julgada. Lido no
  ledger por `kit_rev`, a fatia `94123a4` tem 11 sessões em 3 lançamentos (`b99c1125`, `3e9a06eb`,
  `f7175adc`), e os três relançam uma missão aberta em `c71913c`: 2 intervenções pela régua D16
  dentro da fatia, 3 contando a volta que a abriu. Meia missão não dá taxa por missão. A fase TICKET
  gravada à mão (linha `manual` de 2026-10-05) também é de `c71913c`.
- `latest`: `o-que-some-calado` 3 → 2; `o-backlog-volta-a-medir` 2 → 1; `a-catraca-ganha-folga` 2 → 1;
  `detalhe-e-lista-dizem-a-verdade` 1 → 0; `o-rascunho-que-entra-cru` 2 → 1. **5 intervenções em 5
  missões**, mais três fases QA gravadas à mão (abaixo).

## Por que isto é `melhorou`

1. **O que as sessões fizeram melhorou.** `advance_rate` 0,91 → 0,98 sobre seis vezes mais sessões;
   `churned` fica em 1 com 55 sessões a mais; `moved_rate` e `idle` ficam no melhor valor possível.
   O único `churned` da `latest` é, pela ordem dos fatos, a sessão de QA de `o-que-some-calado` que
   escreveu o `30-handoff-qa.md` com `status: blocked` (commit do alvo `ecb3df0b` às 00:11:30,
   escalada às 00:11:58) — a sessão que parou a linha honestamente, não uma que girou.
2. **Os rótulos seguem.** `ok` em 3 de 5 células → 25 de 27; o `leve` some. O `refez` sobe de 1 para
   2 em número e cai em proporção (1 de 5 → 2 de 27), e as duas são da mesma missão e são paradas boas
   (abaixo).
3. **A espécie de parada que o kit causava a si mesmo sumiu.** Na `previous`, a escalada é
   `kit-touched`: o lote 4 era escrito no checkout principal do kit enquanto o alvo rodava, e a
   `mascaras-ncm-e-painel` parou **quatro** vezes por isso (três em `c71913c`, uma em `94123a4`,
   lidas no ledger). Na `latest`, zero. A ADR 0016 §2 (missão do kit num worktree ligado) e a ADR
   0017 (o `sdd kaizen` recusando o checkout dos alvos) são exatamente a mudança que tira essa causa,
   e são parte do lote julgado — é a parcela do ganho que eu atribuo ao kit sem hesitar. Com uma
   ressalva honesta: o congelamento também ajudou, e a série não separa os dois.
4. **Custo.** O total sobe porque a fatia tem quatro missões a mais. Por sessão cai (US$ 55,23 / 11 ≈
   5,02 → 192,06 / 66 ≈ 2,91) e por missão cai (≈ 55,23 → ≈ 38,41) — divisões dos números da série,
   não recálculo do ledger. A queda vem em boa parte da mistura: três missões não pagaram QA nenhuma.
5. **Intervenções: sem antes e depois por missão.** A `previous` é meia missão (acima): na fatia
   julgada, 2 a 3 relançamentos em 11 sessões, um número que não entra como antes/depois deste
   veredito. Na `latest`, 5 intervenções em 5 missões, uma delas inteira sem mão humana, e **três são
   o mesmo ritual** causado por uma lacuna do kit (seção seguinte); as outras duas são as duas
   paradas boas. O `5 → 1` que estava aqui somava os lançamentos das duas versões da `previous`
   (corrigido na revisão do PR #247). O veredito não se apoiava nele: os itens 1 a 3 decidem.

## Os dois `refez` — paradas boas

As duas escaladas são de `20261009-o-que-some-calado`, e as duas pararam a linha antes do dano:

- **QA `handoff-blocked`** (motivo no ledger: `30-handoff-qa.md has status: blocked`). O reteste do F1
  passou e o registro ficou sem bug `agent` aberto; o `E2E_CMD` caiu num caso por **ambiente do
  operador** — o `.env.local` do frontend declarava `ERP_API_*` e o Vite lia `JRC_API_*`, então o proxy
  respondia 401. Nenhuma sessão podia consertar aquilo. Jidoka bom: `refez` no rótulo, a alternativa
  era um verde falso.
- **DOCS `hat-crossed`** (`the DOCS session (sdd-docs) touched 1 path(s) outside its writes:
  .claude/rules/techspec.md`). A fronteira fez o que promete, e o humano usou a porta desenhada para
  isso (ADR 0009): `HAT_WRITES_EXTRA` ganhou `sdd-docs: .claude/rules/techspec.md` no
  `.sdd/config.sh` do alvo (commit `1a71aad5`, 2026-10-10 19:18). As quatro missões seguintes
  editaram o mesmo arquivo na DOCS sem parada nenhuma. Uma parada, uma decisão humana, zero
  recorrência — o laço da exceção de projeto funcionando como desenhado.

## O que a série não vê — e vira o plano

A série gradua 27 células na `latest`, e **três fases QA não são célula nenhuma**: `o-backlog-volta-a-medir`,
`a-catraca-ganha-folga` e `o-rascunho-que-entra-cru` gravaram a QA com `sdd note-manual` (linhas
`manual` de 2026-10-11 09:19, 2026-10-11 15:22 e 2026-10-12 17:03, lidas no ledger). Os três
`30-handoff-qa.md` dizem `sessao: manual` e `status: skipped por decisão do humano no grill`. O
`pipeline.log` das três mostra o mesmo ritual: `sdd run` só até o TICKET, o handoff de QA escrito à
mão, `sdd note-manual`, e um **segundo** `sdd run` para EXEC → PR. Esse segundo lançamento é **a**
intervenção de cada uma delas — 3 das 5 intervenções da fatia.

A causa está no kit, medida no código: com `APP_URL` ou `E2E_CMD` preenchidos, o `qa_substep`
(`bin/sdd:2672`) só devolve `close` depois de um relatório **da missão** fechado; antes disso manda
para `plan` (`/qa-report`) ou `exec` (`/qa-execution`), que exigem navegador e stack. O
`agents/sdd-qa.md` § 2 promete que `status: skipped` é resposta legítima para diff que não chega ao
usuário — e, no caminho com interface, nenhuma sessão alcança essa promessa sem antes pagar a
caminhada. É a classe do princípio 1: promessa que o código não alcança. O humano a contornou à mão
três vezes nesta janela, e o achado `kit:` que a descreve está no handoff do planner da
`o-backlog-volta-a-medir` desde 2026-10-11.

A mesma janela mediu a segunda metade do problema. Depois de um `F<n>` feito, o relatório da missão
já está `closed`, o `qa_substep` vai direto ao `close`, e nenhuma sessão dona do `Status:` do bug
volta a rodar — a Âncora 3 do `gate_QA` segue contando o bug consertado. A sessão `sdd-qa` chamou a
skill `qa-execution` pela ferramenta `Skill`, o que nenhum contrato descreve: três vezes na
`mascaras-ncm-e-painel` (r2, r3, r4 — e na r3 foi o reteste que achou o F5) e de novo na
`o-que-some-calado`. Funciona hoje porque as duas skills instaladas declaram
`disable-model-invocation: false`, ao contrário do que o comentário do runner afirma
(`bin/sdd:2651`). Se a skill voltar a recusar invocação pelo modelo, toda missão com `F` gira o
`QA:close` até o `QA_MAX_ITER`.

As duas metades são o mesmo ponto do runner, e por isso viram **uma** missão: `00-missao.md` nesta pasta.

## Limites deste `melhorou`, ditos em vez de calados

- `previous` fina: **uma** missão, com **11** das suas 22 sessões; as outras estão em `c71913c`. Por
  isso a contagem de intervenções da `previous` não tem leitura por missão: o `--by-mission` conta a
  missão inteira (corrigido na revisão do PR #247).
- Harness diferente entre as fatias (2.1.289 × 2.1.291), que a guarda não mede.
- Mistura diferente: três missões da `latest` sem QA, por decisão humana e à mão.
- `window_missions_stranded: 3`.

Nenhum desses limites inverte a direção de nenhum número; todos reduzem o quanto dela se pode
atribuir ao kit. O que atribuo com segurança é o fim do `kit-touched` e das intervenções que ele
causava. O resto é coerente com o kit ter melhorado, sem prova de que foi ele.

## Uma leitura lateral: a régua da D22

O `--by-mission` imprime a parcela do laço de revisão de cada missão da `latest`: 24%, 42%, 38%,
29% e 43% — mediana 38%, máximo 43%, contra o alvo da D22 (mediana ≤ 25%, máximo ≤ 50%). O máximo
cabe e a mediana não. A mistura empurra o número para cima: nas três missões sem QA o denominador
não tem QA nenhuma. Não é o objeto deste veredito — o lote julgado não mexeu no laço de revisão —,
mas fica registrado para a próxima janela, que terá missões com QA headless se o plano abaixo pousar.

## O que isto autoriza

O veredito fecha a janela do lote 6: o kit pode descongelar depois do merge desta branch (passo
humano). A triagem do `TODO.md` achou **zero** itens abertos e **zero** resolvidos a apagar; os
candidatos vieram dos **seis** achados `kit:` dos handoffs da janela, que a triagem do `sdd kaizen`
transporta: os dois acima são o núcleo da missão, dois entram nela como incrementos pequenos, e dois
vão para o `TODO.md` (catraca 0 → 2). O destino de cada um está no `01-plano.md`.
