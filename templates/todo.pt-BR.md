# TODO

Achados que **não cabem na missão atual** — registrados, nunca perdidos, nunca desvio de escopo.
Formato e ciclo de vida: `templates/todo.pt-BR.md` do kit sdd (uma variante por `OUTPUT_LANG`); a
forma é medida por `tests/check-todo.sh --check TODO.md --allow-empty`, do kit.

> **Esqueleto.** Dois `##`, nesta ordem, cada um seguido na linha de baixo pelo seu marcador:
> `<!-- sdd:open -->` para os achados, `<!-- sdd:decided -->` para o que não se reabre. O texto do
> heading é livre e segue o `OUTPUT_LANG`; o marcador nunca muda. Nenhum outro `##`. Dentro da
> seção aberta, as categorias `###` são livres (tema, quem destrava, "Bloqueia", "Decisão
> pendente"). Análise longa e roadmap moram em `docs/`; o item aponta com `Fonte:`.
>
> **Achado aberto** — cerca de 6 linhas (teto 8), caixa sempre vazia, atribuição na última linha:
>
> ```md
> - [ ] **<título>** — `<arquivo:linha>` — <por que importa>. Direção: <o que fazer>. Fonte: `<docs/…>`
>   — descoberto por `<agente>` na missão `<slug>` (YYYY-MM-DD)
> ```
>
> **Registro decidido** — uma linha física, sem caixa, apontando a evidência:
>
> ```md
> - **<título>** — <o que se decidiu e por quê> — `<ADR | handoff | teste>` (YYYY-MM-DD)
> ```
>
> **Ciclo de vida.** Consertado por commit: o corpo ganha `RESOLVED by <hash>` (token do kit, igual
> em todo idioma) e o item fica até `git merge-base --is-ancestor <hash> <DEFAULT_BRANCH>` valer;
> então é **apagado**, nunca marcado. Refutado, decidido, wont-fix ou risco aceito: não há o que
> commitar, então sai da seção aberta e vira registro decidido no mesmo commit. Duplicado é
> apagado, citando o sobrevivente. Antes de registrar, leia os decididos: o que está lá não volta.

## Aberto
<!-- sdd:open -->

## Decidido — não reabrir
<!-- sdd:decided -->
