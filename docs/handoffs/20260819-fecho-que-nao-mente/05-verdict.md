---
verdict: indeterminado
kit_sha_judged: ce76188
date: 2026-08-19
---

# Veredito — o eixo é degenerado, e desta vez o runner diz isso com todas as letras

> Volta do laço kaizen. O julgamento abaixo cita **exclusivamente** a saída de
> `sdd kaizen --series` (ADR 0001: o runner deriva os números, este artefato os interpreta).
> Nada aqui foi recalculado a partir do `~/.sdd/autonomy-log.jsonl` — recalcular seria violação
> de contrato, inclusive se eu achasse a série errada; nesse caso o lugar do achado é o `TODO.md`.

## A série, verbatim

```json
{
  "v": 1,
  "latest":   { "kit_sha": "ce76188", "missions": 1, "missions_with_session": 1, "sessions": 1,
                "moved_rate": 1, "labels": {"ok": 1, "leve": 0, "refez": 0},
                "escalations": {}, "cost_usd": 3.41,
                "detail": [{"repo": "/home/joruge/repos/sdd_agents",
                            "mission": "20260818-lote-facil", "phase": "PR",
                            "label": "ok", "sessions": 1, "cost_usd": 3.4078052999999997}] },
  "previous": { "kit_sha": "535a989", "missions": 1, "missions_with_session": 1, "sessions": 1,
                "moved_rate": 1, "labels": {"ok": 1, "leve": 0, "refez": 0},
                "escalations": {}, "cost_usd": 33.68,
                "detail": [{"repo": "/home/joruge/repos/sdd_agents",
                            "mission": "20260818-lote-facil", "phase": "REVIEW",
                            "label": "ok", "sessions": 1, "cost_usd": 33.68004024999998}] },
  "guard": { "missions_after_change": 1, "missions_with_session": 1, "sessions": 1,
             "floor": 3, "sufficient": false, "degenerate_axis": true },
  "excluded": { "non_comparable": 7, "unrecognized": 0, "meta": 2,
                "other_repo": 11, "no_repo": 0 }
}
```

## Por que `indeterminado` — e por que **não** é "faltam missões"

`guard.sufficient` é **`false`**, e a regra não admite julgamento: guarda insuficiente ⇒ o veredito
**é** `indeterminado`. A guarda pertence ao runner e este artefato não a sobrepõe.

O que muda em relação às voltas anteriores é o segundo campo. `degenerate_axis` é **`true`**: as
três últimas versões do kit no recorte compraram exatamente **uma missão** cada, e **nenhuma**
versão do histórico inteiro jamais alcançou o piso de `3`. Isso não é escassez temporária, é
estrutural — é o repo que **constrói** o kit, onde cada sessão commita e a próxima aterrissa num
sha novo. Escrever aqui "mais algumas missões e saberemos" seria falso: esperar nunca funciona
neste eixo. A decisão está registrada e não se re-litiga —
[ADR 0003](../../adr/0003-judge-axis-evidence-from-target-repos.md), que fixa as três partes:
o eixo continua `kit_sha`, o piso continua `3`, e aqui dentro `indeterminado` é a resposta
**correta**, não um defeito.

`kit_sha_judged` é `ce76188`, verbatim de `latest.kit_sha` — é por esse campo que o `gate_KAIZEN`
encontra este arquivo (`bin/sdd:3153`, `.latest.kit_sha // "none"`), por conteúdo e nunca por
"arquivo mais novo".

## A metade que é minha: o que estes dois shas significam

O eixo da série é o `kit_sha` cru (D4). O que cada sha **é** vem do `git log` do checkout:

| sha | assunto do commit | fase que a série viu | custo |
|---|---|---|---|
| `ce76188` | `docs(pr): PR #12 aberto, com o gate confirmado via gh pr view` | PR | US$ 3,41 |
| `535a989` | `docs(review): a linha Overall repetia o score que a linha gate acabara de recusar` | REVIEW | US$ 33,68 |

Os dois são commits **de dentro da mesma missão**, `20260818-lote-facil` — e o `detail` da série
diz isso sozinho, em `repo` e `mission` idênticos dos dois lados. Não são duas versões do kit: são
dois artefatos de handoff de uma única mudança lógica, e o que os separa é um markdown de PR.

Portanto **não há antes/depois para comparar**, e três números precisam ser explicitamente
recusados como tendência:

- **`cost_usd: 33,68 → 3,41`** não é "o custo caiu 90%". É o custo da fase REVIEW contra o da fase
  PR da mesma missão — publicar sempre foi mais barato que revisar. Ler isso como economia seria
  inventar uma melhoria que ninguém fez.
- **`moved_rate: 1` dos dois lados** é verdade vazia: uma sessão em cada grupo, e as duas moveram
  o disco. Com `n=1` a taxa não distingue nada.
- **`labels: {ok: 1}` dos dois lados** diz o mesmo com outras palavras.

## O que os números dizem apesar disso

Três fatos valem registro, porque são fato mesmo sem grupo comparável:

- **`escalations: {}` nos dois grupos.** Zero `increment-blocked` e — o que mais importa — zero
  `review-to-draft`. A missão julgada **não** passou pelo ramo em que o runner baixa a própria
  régua para publicar em draft. Um kit que embarcou baixando o próprio critério é a coisa mais
  interessante que a série sabe contar, e aqui ela conta o contrário: não houve. Os rótulos
  `ok: 1` com `refez: 0` são coerentes com isso — nenhum `ok` comprado degradando critério.
- **`excluded.meta: 2`.** São as sessões do próprio laço kaizen, excluídas do eixo como a D10
  mandou. O juiz não viu a própria sessão inflar a guarda do próprio veredito, e o contador prova
  que a exclusão **aconteceu**, em vez de apenas ter sido prometida.
- **`excluded.other_repo: 11` e `no_repo: 0`.** O arquivo do ledger é global, esta leitura não é:
  onze linhas nasceram em outro projeto e ficaram de fora, nenhuma linha deixou de dizer de onde
  veio. `unrecognized: 0` fecha o quadro. A série não encolheu em silêncio — cada exclusão tem
  balde e número, que é exatamente o defeito que os contadores existem para pegar.
- **`excluded.non_comparable: 7`.** Sete linhas escritas com a árvore do kit suja. Neste repo isso
  é a norma durante o EXEC, e é mais uma leitura independente do mesmo eixo degenerado: a maior
  parte do trabalho real acontece justamente quando o carimbo não é comparável.

## O achado desta volta: o sha julgado não é a mudança mais recente do kit

`latest.kit_sha` é `ce76188`, e a `main` de hoje é `7957a85` — **seis commits à frente**. Entre os
dois estão as duas mudanças de kit mais consequentes da semana: `b36f8e2`
(`docs(agents): o revisor aprende quando parar o laço e como não morrer no meio dele`) e `77ec863`
(`fix(mutation): a âncora de HEALTH_grade_table_blind apodreceu e a main foi para vermelha`).
Nenhuma delas carrega linha de ledger, porque nenhuma nasceu dentro de um `sdd run`.

Isso é consequência direta do eixo, não defeito novo: o juiz julga o último sha que **tem linha**,
nunca a última mudança do kit. Vale escrever porque é a leitura que um humano faria errado ao
bater o olho — "o kit não mudou desde ce76188" é falso; o certo é "nada rodou sob os shas
seguintes". Não vira incremento: é mais uma instância do que a ADR 0003 já decidiu, e a saída dela
é evidência vinda de repo-alvo, nunca régua menor.

## Por que não é `piorou`

Nada regrediu. Não há escalada de nenhum tipo nos dois grupos, nenhum rótulo `refez`, nenhuma
degradação. `indeterminado` aqui é ausência de sinal, não sinal vermelho — e a **D5** é explícita:
só `piorou` para a linha. A sessão segue para a triagem e para o plano da próxima missão, que é o
outro lado do laço e o que ele de fato entrega neste repo.

## O que faria a próxima volta ser conclusiva

Nada que caiba aqui dentro. Enquanto o alvo for o próprio kit, `indeterminado` é o teto, e a
saída registrada na ADR 0003 é uma só: **missões rodadas em repo-alvo real**, onde o `kit_sha`
fica parado pela missão inteira e três missões caem no mesmo grupo naturalmente. Afrouxar o piso
porque "a série nunca enche" é olhar para o sintoma que a ADR explica.
