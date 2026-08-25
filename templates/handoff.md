---
missao: <YYYYMMDD>-<slug>
fase: <EXEC | QA | REVIEW | DOCS | PR | TICKET>
status: <done | blocked | skipped>
sessao: <uuid da sessão que produziu este handoff — serve para --resume>
data: <YYYY-MM-DD HH:MM>
gate: <a evidência de que o gate desta fase passou — comando + saída resumida, não adjetivo>
---

# Handoff — <fase> — <título da missão>

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

<No máximo 5 linhas. O que mudou, se passou, o que a próxima fase precisa fazer primeiro.>

## Estado do repo

- **Branch:** `<nome>` — <em sync com origin? divergiu?>
- **Último commit:** `<hash>` `<assunto>`
- **Working tree:** <limpo | sujo com o quê>
- **Suíte:** `<TEST_CMD>` → <verde/vermelho, nº de testes>
- **E2E:** `<E2E_CMD>` → <verde/vermelho/não rodou e por quê>

## O que foi feito

<Lista com hash de commit por item. Sem hash, não foi feito.>

- `<hash>` — <o quê e por quê>

## Artefatos

| Arquivo | O que contém |
|---|---|
| `<caminho>` | <uma linha> |

## Boot da próxima fase

<O que a próxima sessão deve ler primeiro e por onde começar. Concreto: caminhos e comando,
não "continue de onde parei".>

## Pendências / Decisions for a Human

> Só julgamento humano genuíno (política de UX, decisão de produto, pagamento real, acesso
> externo). **Não bloqueiam o pipeline** — viram seção do PR. Bug sanável não entra aqui: vira
> incremento de fix no `checkpoint.md`.

- <pendência — por que precisa de humano — onde ver>

## Riscos e não-feitos

- <o que ficou de fora, o que pode quebrar, o que não foi verificado — dito explicitamente>

## Achados fora de escopo

> Dois destinos, e a diferença já custou uma `main` vermelha (`2d28d13`).
>
> **Achado sobre o repo-alvo:** registrado no `TODO.md` dele; aqui fica só o ponteiro, para o PR
> conseguir citar.
>
> **Achado sobre o kit** (runner, agente, template), numa missão cujo repo NÃO é o kit: a sessão
> não escreve, não commita e não entra no repositório do kit. A linha **completa** do achado mora
> aqui, marcada `kit:`, e quem a transporta é um humano ou a triagem do `sdd kaizen`. Ponteiro para
> um arquivo que ninguém escreveu é achado perdido.
>
> O exemplo abaixo mora **dentro** desta citação pelo mesmo motivo que o `- intervention:` do
> `checkpoint.md` (`cd49351`): exemplo que abre a linha com `-` é contado verbatim por quem vier
> varrer os handoffs atrás de `kit:`, e todo handoff nasceria devendo um achado fantasma. Copie a
> forma para fora da citação ao registrar um achado de verdade.
>
> - kit: <o quê> — <arquivo:linha do kit> — <por que importa>

- <o quê> → `TODO.md` (<seção>)
