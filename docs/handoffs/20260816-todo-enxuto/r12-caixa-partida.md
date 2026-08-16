# 12ª rodada — a caixa marcada que cai na linha seguinte ao marcador

Handoff do achado **D1** do `tests/check-todo.sh`, registrado no `TODO.md` (seção
"Sensores que faltam"). O item lá cabe em 7 linhas; a análise é esta.

Contexto: a revisão adversarial do sensor rodou doze vezes. As nove primeiras estão medidas no
`KAIZEN_LOG.md` (17, 9, 11, 11, 11, 11, 10, 5, 3 defeitos); a 10ª (`e339baf`) derrubou a quarta e
última tentativa de modelar cerca; a 11ª (`0552110`) achou a regressão que a 10ª criou. A 12ª
rodou depois do merge `011a0c8` e **não** foi rodada limpa.

## O defeito

A regra 2 (caixa marcada) é um regex **por linha** que exige marcador de lista e `[x]` na
**mesma linha-fonte**:

```awk
/^[ \t>]*([-*+]|[0-9]+[.)])[ \t]+\[[xX]\]([ \t]|$)/
```

O GFM não pede isso. Ele marca a caixa quando o **primeiro bloco renderizado** do item de lista é
um parágrafo que abre com `[x] ` — e o conteúdo da própria linha do marcador pode **sumir do
AST**, empurrando a caixa para a linha seguinte. Dois carregadores fazem isso:

1. **marcador vazio** — a linha é só `-`;
2. **link-reference definition** — `- [ref]: https://example.com` não emite nó nenhum, então o
   parágrafo continua sendo o primeiro filho do item.

O resultado é um achado fechado que **renderiza com a caixa marcada no GitHub enquanto o sensor
sai `rc 0`**. É pior que a lacuna de cerca declarada no cabeçalho: aquela se auto-denuncia (a
página inteira vira bloco de código), esta renderiza um arquivo de aparência perfeitamente
saudável.

Isso falsifica duas alegações do cabeçalho do próprio sensor:

- linhas 67-69 — *"the ticked-box rule never depended on fences, so no closed finding can hide"*;
- linha 179 — *"A ticked box is never legitimate anywhere here"*.

## Repros

Os dois abaixo foram **reproduzidos nesta sessão** contra o sensor mergeado, via a entrada
`--check` do próprio arquivo:

```md
# TODO                          |  # TODO
                                |
-                               |  - [ref]: https://example.com
  [x] **um achado fechado**     |    [x] **um achado fechado**
                                |
## Aberto                       |  ## Aberto
                                |
- [ ] **Um achado bem-formado** — `bin/sdd:42` — porque importa — descoberto por `x` na missão `y` (2026-08-16)
```

```
bash tests/check-todo.sh --check poison1.md  →  "ok  1 finding(s), ..."  rc=0
bash tests/check-todo.sh --check poison2.md  →  "ok  1 finding(s), ..."  rc=0
```

Confirmado estruturalmente pelo AST CommonMark (`cmark -aj`): nos dois casos o primeiro filho do
`item` é um `paragraph` cujo primeiro `text` é `[`, `x`, `]`, ` ` — **a mesma forma** do item
bem-formado logo abaixo, cujo parágrafo abre com `[`, ` `, `]`, ` `. É exatamente a pré-condição
que a extensão task-list do GFM usa.

## O conserto

`r12-caixa-partida.patch`, neste diretório. Duas regras acrescentadas **acima** do
`NR <= from { next }` — é o pulo do cabeçalho que deixava a primeira passar —, ambas no estilo
"recusar por nome" que o arquivo já usa para todo construto que ele se recusa a modelar:

```awk
/^[ \t>]*([-*+]|[0-9]+[.)])[ \t]*$/ && NR <= from { ... }   # marcador de lista pelado
/^[ \t>]*\[[ xX]\]([ \t]|$)/                     { ... }   # linha que abre com caixa pelada
```

Aplicar com `git apply docs/handoffs/20260816-todo-enxuto/r12-caixa-partida.patch` (verificado
com `git apply --check` contra `011a0c8`).

**Medido nesta sessão**, com o protótipo:

| | sensor mergeado | com o patch |
|---|---|---|
| `poison1.md` (marcador pelado) | `rc 0` — "ok 1 finding(s)" | **`rc 1`** — 2 violações |
| `poison2.md` (link-ref) | `rc 0` — "ok 1 finding(s)" | **`rc 1`** — 1 violação |
| selftest | 75 probes, verde | **75 probes, verde** |
| `TODO.md` real | 48 achados, `rc 0` | **48 achados, `rc 0`** |

O `TODO.md` real não tem nenhuma linha cujo primeiro conteúdo seja uma caixa pelada, então a
segunda regra não custa nada hoje.

## Relatado pela revisão, **não** re-medido aqui

Números do agente da 12ª rodada, úteis para quem for fechar o achado — trate como pista, não como
medida confirmada:

- um terceiro carregador, o mesmo formato **dentro** da seção de achados, entrando por dois
  caminhos da lista-branca: absorvido como continuação de item indentada, e aceito pelo
  `/^>/ { flush(); next }`, que é aceite em branco para qualquer linha de citação;
- varredura por posição no arquivo real (caixa renderizada **e** `rc 0`): `nested-linkref`
  218/385, `quote-linkref` 140/385, `linkref-split` 12/385, `split-marker` 8/385;
- com o patch: 0/385 nos quatro, 0 falso-positivo em 17 formas realistas e nos 48 itens reais;
- 97 mutantes aplicados, 72 mortos. Sobreviventes **sem probe e não-equivalentes**, os dois de
  baixa severidade: `cap-string-compare` (as duas probes de cap usam valores de um dígito, então
  nenhuma distingue comparação numérica de lexicográfica — um caso de dois dígitos resolveria) e
  `from-unanchored` (falha **fechada**; é drift entre comentário e probe, não buraco).

## Por que não foi consertado no merge

O merge `011a0c8` fechou o 5S do `TODO.md` e a entrada do sensor na suíte. O achado chegou depois,
e consertá-lo dentro do merge misturaria duas coisas. Vira incremento próprio — com o patch já
medido, é trabalho pequeno.
