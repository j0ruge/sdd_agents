---
missao: <YYYYMMDD>-<slug>
fase: REVIEW
rodada: <N — 1, 2, 3…; o arquivo se chama 40-review-r<N>.md>
status: <done | blocked>
sessao: <uuid da sessão que produziu esta rodada — serve para --resume>
data: <YYYY-MM-DD HH:MM>
gate: <a evidência de que o gate desta rodada passou — TEST_CMD resumido e árvore limpa, não adjetivo>
---

# Review — rodada r<N> — <título da missão>

> Escrito ao fim de cada rodada de revisão, em `docs/handoffs/<missão>/40-review-r<N>.md`.
> O runner lê **a mais recente**. Uma rodada que não fechou também escreve o arquivo, com a nota
> real: nota inflada para passar no gate desliga o único sensor de qualidade da missão.

## TL;DR

<No máximo 5 linhas. O que foi revisado, quantos achados, o que foi corrigido, o que sobrou.>

## Nota da rodada

⚠️ **O heading abaixo é `###` — três sustenidos — e a tabela é a do `codereview`.** O
`gate_REVIEW` procura o literal `^###[[:space:]]+Overall Grade` e faz parse das colunas
`Criterion` / `Grade` / `Rationale`. Escrito como `##`, o gate responde `NO-TABLE` e a rodada
não fecha — duas sessões independentes já derivaram esse erro, e este template existe por causa
delas. Não renomeie as colunas, não traduza os critérios: eles são contrato do skill, inglês em
qualquer repo.

Qualquer critério com nota diferente de `A` reprova — inclusive `—` para "não analisado". Revisão
parcial não é revisão: se um critério não foi analisado, analise.

⚠️ **A coluna `Rationale` também é lida, e placeholder nela reprova.** Célula vazia, célula
inteira entre `<` e `>` (é assim que os `<…>` abaixo vêm), célula que é só pontuação (`-`, `?`,
`...`, `…`) ou uma das palavras de preenchimento `PREENCHER` / `TODO` / `TBD` / `FIXME` / `XXX` /
`WIP` / `FILL ME`: o gate nomeia o critério e recusa a rodada. As palavras são comparadas como
**palavra**, não como grafia — `TODO:` e `TBD.` são a mesma coisa que as peladas, e foi por uma
tecla dessas que o selo já foi comprado. O `A` é comprado pela frase, não pela letra: a r1 de
`20260818-lote-facil` deixou `PREENCHER` nas sete justificativas e teria sido certificada.
Pontuação sozinha nunca é a ofensa — frase real que termina em ponto é frase real —, e `clean`,
`n/a` e `—` **não** são placeholder: são as justificativas curtas do próprio `codereview` e querem
dizer "medido, nada a dizer".

A mesma recusa vale para o campo `gate:` do frontmatter, a outra metade do selo: preencha com a
evidência real da rodada, nunca com o `<…>` que este template entrega. Ausente ele é deixado em
paz — há rodadas mais velhas que o campo —, mas **presente** reprova por qualquer placeholder,
inclusive o campo escrito e deixado em branco.

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | <A> | <por quê, em uma frase> |
| Type Safety | <A> | <…> |
| Error Handling | <A> | <…> |
| Security | <A> | <…> |
| Performance | <A> | <…> |
| Test Coverage | <A> | <…> |
| Documentation | <A> | <…> |
| **Overall** | **<A>** | <…> |

## Achados da rodada

> Um item por achado, com severidade e âncora em `arquivo:linha`. O achado que virou correção
> aparece de novo na seção seguinte, com hash; o que foi refutado, na de baixo, com evidência.

| # | Severidade | Achado | Onde |
|---|---|---|---|
| 1 | <CRITICAL \| HIGH \| MEDIUM \| LOW> | <o quê> | `<arquivo:linha>` |

## O que foi corrigido

> Um hash por item. Correção sem hash é rótulo — o gate exige árvore limpa, então tudo que foi
> corrigido está commitado.

- <achado> — corrigido em `<hash>` — <como se prova que fechou>

## O que foi refutado

> Achado que você acredita estar errado **não** se resolve mudando o código para agradá-lo.
> Verifique; se estiver errado, registre aqui o porquê, com evidência. Concordar
> performaticamente com uma crítica equivocada é pior que o achado original.

- <achado> — refutado porque <evidência medida, não opinião>

## Achados fora de escopo

> O que não cabe nesta missão vai para o `TODO_FILE`, nunca para o diff. Uma linha por item, no
> formato do repo, e a referência aqui.

- <achado> — registrado no `TODO.md` (<data>)

## Pendências / Decisions for a Human

> O que exige julgamento humano: trade-off de arquitetura, quebra de contrato, decisão de produto.
> Se não houver, escreva `Nenhuma.` — a seção vazia é ambígua.
