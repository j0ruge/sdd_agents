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

> Registrados no `TODO.md` do repo-alvo (ou do `sdd_agents`, se for melhoria do kit). Aqui fica
> só o ponteiro, para o PR conseguir citar.

- <o quê> → `TODO.md` (<seção>)
