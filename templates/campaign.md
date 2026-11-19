---
campaign: <YYYYMMDD>-<slug — igual ao nome do diretório desta campanha>
title: <uma linha — o que fica pronto quando a fila inteira estiver mergeada>
date: <YYYY-MM-DD>
harness: <claude — o harness que abre as sessões das missões da campanha>
plan_model: <fable — o melhor modelo para planejar no harness acima>
exec_model: <opus — o modelo que a campanha declara para o EXEC; quem decide é o MODEL_EXEC do .sdd/config.sh do worktree da missão>
---

# Campanha — <título>

> Escrito pelo `sdd-planner` com o dono presente, num diretório próprio do repo-alvo (a convenção é
> `docs/campaigns/<YYYYMMDD>-<slug>/`), ao lado do `delegation.md`. É a **fila**: o `bin/sdd-worker`
> lê a tabela abaixo para saber qual lote vem agora, e nunca a reescreve. A **permissão** de agir
> sobre ela mora no `delegation.md`, assinada pelo dono — este arquivo não concede nada.
>
> As chaves do frontmatter, os nomes de coluna da tabela e os tokens `L<n>` e de nível são contrato,
> em inglês ou como estão escritos: o verbo os lê por igualdade de texto.

## Lotes

> Uma linha por lote, **na ordem da fila**: o `next` percorre a tabela de cima para baixo e para no
> primeiro lote que não está mergeado. `Lot` é `L<n>`. `Ceiling` é `-` (sem teto) ou o nome de um
> nível da escada (`assisted`, `pr`, `plan`, `merge`, `full`): o nível efetivo do lote é o menor entre
> o assinado e esse teto, e o teto nunca sobe o nível. `Itens` é a contagem de itens da seção do lote.
> Nada de `|` cru numa célula. O `Lot` e o `Ceiling` de cada linha estão sob a assinatura do
> `delegation.md`: mudar um teto, ou pôr ou tirar um lote, depois de assinar faz a delegação valer
> `assisted` até ser assinada de novo. O título, a contagem e os itens ficam fora dela.

| Lot | Título | Ceiling | Itens |
|---|---|---|---|
| L1 | <o que o lote fecha, em uma linha> | - | <n> |
| L2 | <o lote cujas escolhas ficam com o dono> | plan | <n> |

### L1 — <título do lote>

> Um item por linha, como `- [ ] <título>`. Item cuja escolha fica com a recomendação do planner
> leva `◆ ` logo depois do `- [ ] `, e sai marcado no corpo do PR para o aceite do dono. Cada missão
> do lote declara `campaign:` e `lot:` no frontmatter do seu `00-missao.md`: é por elas que o worker
> acha a missão de um lote, nunca por uma tabela de estado.

- [ ] <título do item — o que o fecha>
- [ ] ◆ <título do item cuja escolha segue a recomendada do planner>

### L2 — <título do lote>

- [ ] <título do item>
