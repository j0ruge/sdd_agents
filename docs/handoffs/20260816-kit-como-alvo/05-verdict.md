---
verdict: indeterminado
kit_sha_judged: dd80cb9
date: 2026-08-16
---

# Veredito — a série achou dois grupos, mas eles são a mesma missão

> Segunda volta do laço kaizen. O julgamento abaixo cita **exclusivamente** a saída de
> `sdd kaizen --series` (ADR 0001: o runner deriva os números, este artefato os interpreta).
> Nada aqui foi recalculado a partir do `~/.sdd/autonomy-log.jsonl`.

## A série, verbatim

```json
{
  "v": 1,
  "latest":   { "kit_sha": "dd80cb9", "missions": 1, "missions_with_session": 1, "sessions": 1,
                "moved_rate": 1, "labels": {"ok": 1, "leve": 0, "refez": 0},
                "escalations": {}, "cost_usd": 1.54,
                "detail": [{"mission": "20260816-runner-sem-dividas", "phase": "PR",
                            "label": "ok", "sessions": 1}] },
  "previous": { "kit_sha": "c187983", "missions": 1, "missions_with_session": 1, "sessions": 1,
                "moved_rate": 1, "labels": {"ok": 1, "leve": 0, "refez": 0},
                "escalations": {}, "cost_usd": 10.40,
                "detail": [{"mission": "20260816-runner-sem-dividas", "phase": "DOCS",
                            "label": "ok", "sessions": 1}] },
  "guard": { "missions_after_change": 1, "missions_with_session": 1, "sessions": 1,
             "sufficient": false },
  "excluded": { "non_comparable": 0, "unrecognized": 0, "meta": 1 }
}
```

## Por que `indeterminado`

`guard.sufficient` é **`false`**. A regra não admite julgamento: guarda insuficiente ⇒ o veredito
**é** `indeterminado`. A guarda pertence ao runner e este artefato não a sobrepõe.

E, ao contrário da primeira volta, agora dá para dizer o que falta com precisão. Os três números
da guarda são **`1`, `1` e `1`**: uma missão depois da mudança, uma com sessão, uma sessão. A
guarda pede 3 missões distintas com sessão comparável no grupo mais novo. Falta observação, não
interpretação.

`kit_sha_judged` é `dd80cb9`, verbatim de `latest.kit_sha` — é por esse campo que o `gate_KAIZEN`
encontra este arquivo (`bin/sdd:2088`, `.latest.kit_sha // "none"`), por conteúdo e nunca por
"arquivo mais novo".

## O que os dois grupos realmente são (a metade que é minha)

O eixo da série é o `kit_sha` cru (D4). O que cada sha **significa** vem do `git log`, e aqui ele
desmonta a leitura ingênua:

| sha | assunto do commit | fase que a série viu |
|---|---|---|
| `dd80cb9` | `docs(pr): PR #3 aberto — o handoff da fase PR fecha a missão` | PR |
| `c187983` | `docs(docs): a checklist de drift fecha a fase — 29 áreas, nenhum pendente` | DOCS |

Os dois são commits **de dentro da mesma missão**, `20260816-runner-sem-dividas`, mergeada em
`6ddeb4c`. Não são duas versões do kit: são dois artefatos de handoff de uma única mudança
lógica, e o que os separa (`dd80cb9`) é um markdown de PR — algo que não tem como mover autonomia
em nenhuma direção.

Portanto **não há antes/depois para comparar**. `latest` e `previous` diferem em `phase`, não em
kit. Ler `moved_rate: 1` dos dois lados como "estável" seria verdade vazia, e ler
`cost_usd: 10.40 → 1.54` como "o custo caiu 85%" seria falso: são os custos das fases DOCS e PR
de uma mesma missão, não um custo por versão. Nenhum dos dois números entra no veredito como
tendência.

## O que os números dizem, apesar disso

Duas coisas valem registro, porque são fato mesmo sem grupo comparável:

- **`escalations: {}` dos dois lados.** Zero `increment-blocked` e — o que mais importa — zero
  `review-to-draft`. A missão julgada não parou a linha e, sobretudo, **não passou pelo ramo em
  que o runner baixa a própria régua** para publicar em draft. Rótulos `ok: 1` com `refez: 0` nos
  dois grupos são coerentes com isso: nada aqui é um `ok` comprado degradando o critério.
- **`excluded.meta: 1`.** É a sessão do próprio laço kaizen da volta anterior, excluída do eixo
  como a D10 mandou. O juiz não viu a própria sessão inflar a guarda do próprio veredito, e o
  contador prova que a exclusão aconteceu em vez de apenas ser prometida. `non_comparable: 0` e
  `unrecognized: 0` fecham o quadro: nenhuma linha suja, nenhuma linha mal formada. A guarda é
  `false` por escassez de dado, não por dado descartado.

## O achado desta volta: o eixo degenera quando o kit é o alvo

A série acaba de produzir, sozinha, a segunda observação independente de um item que já estava
catalogado (`TODO.md`, "A guarda do juiz é insatisfazível quando o kit desenvolve a si mesmo"):
**dois grupos de `kit_sha`, um com exatamente uma sessão cada, nenhum com duas.**

A causa é estrutural. `autonomy_kit_stamp` carimba o `HEAD` do kit no instante de **cada linha**,
e no repo do kit as fases commitam entre as sessões — inclusive fases que só escrevem markdown.
Cada sessão cai num sha diferente, então `missions_with_session` de um grupo tende a `1` e a
guarda de 3 é insatisfazível por construção. Não é bug em repo-alvo, onde o kit não muda durante
a missão; é o eixo degenerando exatamente no repo que o desenvolve.

Isso **não** é motivo para `piorou`, e a distinção importa: nada regrediu. O instrumento não
está errado, está respondendo com precisão a uma pergunta que, aqui dentro, não tem resposta —
e a D5 já diz que `indeterminado` não para a linha. Registro-o como achado, e a decisão de qual
pergunta o juiz deve responder (rodar missão em alvo real, ou carimbar o sha uma vez por missão)
continua sendo do humano, com ADR: o item segue vivo no `TODO.md` e **não** virou incremento da
missão nascida ao lado.

## O que faria a próxima volta ser conclusiva

Enquanto o eixo for o `HEAD` a cada linha e o alvo for o próprio kit, nenhuma volta será
conclusiva — `indeterminado` é o teto. Duas saídas, ambas fora do escopo desta missão:

1. rodar missões em **repo-alvo real**, onde o `kit_sha` fica parado durante a missão inteira e
   três missões caem no mesmo grupo naturalmente;
2. mudar o eixo para **um carimbo por missão**, o que muda a pergunta que o juiz responde e por
   isso pede decisão humana e ADR.

Até lá o laço segue valendo pelo outro lado: a triagem e o plano. É para lá que esta sessão vai,
e a missão nascida ataca a família de defeitos que esta própria volta ilustra — instrumentos que
afirmam ter medido o que não mediram quando o kit é o seu próprio alvo.
