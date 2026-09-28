---
verdict: melhorou
kit_sha_judged: 4fd0f31
date: 2026-09-28
---

# Veredito — a janela do juiz, sobre `4fd0f31`

Todos os números abaixo saem de `sdd kaizen --series`, lido uma vez nesta sessão com a linha que o
prompt de boot entregou. A contagem de intervenções (D12/D16) não está na série: sai de
`sdd autonomy --all-repos --by-mission` e vai citada onde aparece.

## Que mudança está sendo julgada

O eixo é o `kit_sha` cru. `previous` = `5cb0101` (o `fix(install)` do TEST_CMD Node, 2026-09-24) e
`latest` = `4fd0f31` (merge do PR #172). Entre os dois, `git log --first-parent 5cb0101..4fd0f31`
mostra **seis merges**, que são uma mudança lógica só do ponto de vista do juiz — o lote que o
humano congelou para a janela:

- #167 — o sensor lê o que a âncora diz (`TEST_CMD` e âncora do `TODO.md` viram sensor, ADR 0011);
- #168 e #170 — o catálogo roda primeiro o assassino e o sensor para no primeiro FAIL (custo do
  `sdd health`; não mexe no que uma fase de alvo faz);
- #166 — effort por fase (`EFFORT_<FASE>`, effort herdado apagado do env);
- #171 — docs da gaveta;
- #172 — a carona: `foreign-commit` pelo reflog (#51, ADR 0012), `sdd approve` sem resposta sai 66
  (#52), link/nota de ADR lidos como escritos (#50), `gate_PLAN` exige branch sem Jira, `TEST_CMD`
  com stdin em `/dev/null`.

Julgo o lote, não um sha. Os 88 commits do intervalo não se deixam atribuir um a um por esta
série, e o veredito não finge o contrário.

## A composição — de que mistura estes números são feitos

`latest.composition`: `/home/joruge/repos/sales_quote` com 2 missões (2 com sessão) e
`/home/joruge/repos/lighthouse_project` com 1 (1 com sessão). As somas fecham contra a guarda:
2 + 1 = 3 = `missions_after_change`, e 2 + 1 = 3 = `missions_with_session`. `previous.composition`:
só `sales_quote`, 2 e 2.

Os dois são repos-alvo reais — nenhum clone descartável, nenhum fixture sob `/tmp` —, que é a
evidência que a ADR 0003 exige. A `latest` é a primeira fatia julgada com **dois produtos
diferentes**, o que a torna mais forte que a janela 4 (um repo só) e também menos comparável com a
`previous`: a missão do `lighthouse_project` custou mais que as duas do `sales_quote` juntas e
carregou as duas escaladas da fatia (abaixo). A comparação é de misturas diferentes, e o veredito
leva isso em conta.

## A guarda

`missions_after_change: 3`, `missions_with_session: 3`, `sessions: 35`, `floor: 3`,
**`sufficient: true`**, `why: []`, `harness: ["2.1.283"]`, `degenerate_axis: false`.

- `why` vazio: nem `floor` nem `harness_mixed`. A fatia `latest` rodou inteira num harness só
  (2.1.283, travado por `DISABLE_AUTOUPDATER` durante a janela). ⚠️ Mas a `previous` rodou em
  **2.1.282**: dentro de cada fatia a máquina ficou parada, **entre** as fatias não. O guard não
  mede isso (ele olha a mistura dentro da fatia julgada), e eu digo: parte da diferença abaixo pode
  ser do harness, não do kit. Um bump de patch é pouco provável de explicar 13 pontos de
  `advance_rate`, mas não tenho número que o descarte.
- **`window_broken: true`, `window_missions_stranded: 7`.** Sete missões da janela sob julgamento
  deixaram evidência numa versão do kit que **não** é `4fd0f31` — compradas e fora desta fatia. Não
  é veto (`agents/sdd-kaizen.md`): a fatia continua respondível, só é mais estreita do que o
  intervalo de 88 commits sugere. O veredito fala de **3 missões sobre o lote final**, não do efeito
  de cada merge intermediário, que as 7 missões encalhadas não deixam ler.

`excluded`: `non_comparable: 25`, `unrecognized: 0`, `meta: 5`, `other_repo: 0`, `no_repo: 0`.
`other_repo: 0` é o esperado desde a ADR 0005; `no_repo: 0` diz que nada sem projeto esvaziou a
série por baixo.

## O antes e o depois

| | `previous` = `5cb0101` | `latest` = `4fd0f31` |
|---|---|---|
| missões (com sessão) | 2 (2) | 3 (3) |
| sessões | 25 | 35 |
| `outcomes` | 19 advanced · 4 churned · **2 idle** | **31 advanced** · 4 churned · **0 idle** |
| `advance_rate` | 0,76 | **0,89** |
| `moved_rate` | 0,92 | **1,0** |
| rótulos | 8 ok · 1 leve · 2 refez | **15 ok** · 1 leve · 2 refez |
| escaladas | `no-progress: 1` · `no-work: 1` | `handoff-blocked: 1` · `hat-crossed: 1` |
| custo | US$ 52,07 | US$ 65,41 |
| `harness` | 2.1.282 | 2.1.283 |

Intervenções, de `sdd autonomy --all-repos --by-mission` (*intervenções = launches − 1*, D16):

- `previous`: `20260924-todo-no-esqueleto` 4 launches → 3; `20260924-transacao-honra-o-timeout`
  2 launches → 1. **4 intervenções em 2 missões.**
- `latest`: `20260927-idioma-da-spa-pelo-idp` 3 launches → 2; `20260927-breadcrumb-numero-cotacao`
  1 → 0; `20260928-ver-vira-olho-na-lista` 1 → 0. **2 intervenções em 3 missões**, e duas missões
  inteiras de ponta a ponta sem mão humana.

## Por que isto é `melhorou`

1. **O que as sessões fizeram melhorou em toda medida que a série dá.** `advance_rate` 0,76 → 0,89
   e `moved_rate` 0,92 → 1,0: nenhuma das 35 sessões deixou o disco como achou, e `idle` caiu de 2
   para 0. Os 4 `churned` ficaram 4, sobre 10 sessões a mais. A régua do `advanced` é a mesma nas
   duas fatias (as duas são posteriores a `20260829-o-incremento-que-andou`), então a comparação
   não esconde troca de régua.
2. **Os rótulos seguem.** `ok` sobe de 8 de 11 fases para 15 de 18; `refez` fica em 2 com uma fatia
   maior. Pelo `detail`: das 12 fases do `sales_quote`, 11 fecharam `ok` e uma QA `leve`; as duas
   `refez` são as duas paradas do `lighthouse_project` (item 3).
3. **As paradas mudaram de espécie, e na direção boa.** Na `previous`, as duas escaladas eram o
   runner parando porque a sessão **não andou** (`no-progress`, `no-work`) — desperdício. Na
   `latest`, as duas são paradas **deliberadas** de uma fronteira, ambas na mesma missão
   (`20260927-idioma-da-spa-pelo-idp`), e as duas pararam a linha antes do dano:
   - QA `handoff-blocked` (motivo no ledger: `30-handoff-qa.md has status: blocked`): a sessão de QA
     parou sem saída honesta — a Âncora 3 contava bug legado de outra missão (achado 5 do handoff
     da janela). É `refez` no rótulo e Jidoka bom na história: a alternativa era um verde falso;
   - DOCS `hat-crossed` (`touched 1 path(s) outside its writes: packages/frontend/DESIGN.md`): a
     fronteira do chapéu, nascida em `20260903-a-fronteira-do-chapeu`, fez o que promete. `refez`
     no rótulo, fronteira funcionando na história — com a ressalva de que a mesma família de fronteira
     (`.claude/rules/`) foi **contornada pelo Bash** nas duas missões do `sales_quote` (achado 6),
     que é defeito e está no plano abaixo.
4. **Custo.** O total sobe (US$ 52,07 → 65,41) porque a fatia tem uma missão e 10 sessões a mais.
   Por missão cai (≈ US$ 26 → ≈ 21,80) e por sessão cai (≈ US$ 2,08 → ≈ 1,87) — divisões dos
   números da série, não recálculo do ledger. O custo da janela ficou concentrado no
   `lighthouse_project` (≈ US$ 35,06 de 65,41 pela soma do `detail`), o repo novo, onde o `REVIEW`
   sozinho levou US$ 12,57.
5. **Duas das três missões não pediram humano nenhum**, e as intervenções caem de 4 em 2 missões
   para 2 em 3.

Os limites deste `melhorou`, ditos em vez de calados: é uma comparação de **misturas diferentes**
(um repo × dois), de **harnesses diferentes entre si** (2.1.282 × 2.1.283), sobre uma fatia que
deixou **7 missões encalhadas** fora, e sobre um lote de seis merges cujo efeito individual esta
série não separa. Nenhum desses limites inverte a direção de nenhum número; todos reduzem o quanto
dela se pode atribuir ao kit.

## O `leve` da fatia

`20260927-breadcrumb-numero-cotacao`, fase QA: 2 sessões, `0 advanced · 2 churned`. Das três
leituras de `leve` (escreveu sem mover incremento, não escreveu nada, retry automático no laço), a
série exclui a segunda (`moved_rate: 1`); entre a primeira e a terceira ela não decide, e eu não vou
adivinhar. O que está medido fora da série é que o `qa_substep` escolheu `close` com o relatório de
**outra missão** em `20260928-ver-vira-olho-na-lista` (achado 4) — o defeito que a primeira missão
do plano abaixo fecha. Se ele também explica este `leve`, a próxima janela dirá.

## O que isto autoriza

O veredito descongela o kit: a janela está julgada, e o `DISABLE_AUTOUPDATER` do
`~/.claude/settings.json` pode sair depois do merge desta branch (passo humano). Os oito achados
`kit:` medidos na janela viram a próxima missão — ver `00-missao.md` nesta mesma pasta.
