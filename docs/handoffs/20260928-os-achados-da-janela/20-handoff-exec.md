---
missao: 20260928-os-achados-da-janela
fase: EXEC
status: done
sessao: 4d26d92f-6c4b-403b-b867-8ff2bc9e2a51
data: 2026-09-28 19:05
gate: "bash tests/run-all.sh → suite green (rc 0, 240 s, 0 FAIL) sobre ec95baf (depois da revisão final); check-mutation.sh --anchors → all 440 mutants still apply; check-todo --check → 86 finding(s), every anchor on target; sdd adr check --mission … --phase exec → rc 0; os 7 Checks do checkpoint com o esperado (86/11/placed/1, 111/4, 1111/1, 1111/0/same, 111/1, 11, 1/1/1/1/1/86)"
---

# Handoff — EXEC — os achados da janela do juiz

## TL;DR

Os sete incrementos estão `done`, cada um com a suíte verde no próprio commit. Cinco achados foram
consertados: 4, relatório de QA da missão (`121a696`); 3, `APP_EXPECT` (`4423bb0`); 6, DOCS com
`⛔` e texto proposto (`1ffee16`); 7, o close faz fast-forward (`c320630`); 8, `CHECKOUT-UNAVAILABLE`
nomeado (`fbaf9a1`). Três foram registrados no `TODO.md` (1, 2 e 5; catraca 83 → 86, `48e89b7`).
O fechamento (`3ac59ee`) trouxe a ADR 0013 aceita, o KAIZEN_LOG, o `CONTEXT.md`, a anatomia e a
gaveta. A revisão final da branch (revisor de contexto novo) achou 3 Important, consertados em
`ec95baf`. O catálogo foi de 422 para 440 mutantes, e cada um novo morre pela asserção que o
nomeia. A missão rodou inline, sem `sdd run`. Falta o PR, os revisores dele e o `sdd health`.

## Estado do repo

- **Branch:** `fix/os-achados-da-janela`, **não empurrada**, nascida de `main` = `3d350ed`.
- **Último commit de código:** `3ac59ee` (o de prosa/sensor do I7); os commits `chore(missao)` só
  tocam o checkpoint e as notas.
- **Working tree:** limpo depois do commit deste handoff.
- **Suíte:** `bash tests/run-all.sh` → verde, 237 s.
- **E2E:** não se aplica (o kit não tem `E2E_CMD`).

## O que foi feito

- `48e89b7`: I1, três itens verbatim no `TODO.md` (achados 2, 1 e 5) e `todo-findings 86`.
- `121a696`: I2, `mission_qa_report` (o relatório que a branch adicionou, ou novo na árvore; recuo
  no range vazio), lido pela Âncora 1 do `gate_QA` e pelo `qa_substep`. Cinco mutantes.
- `4423bb0`: I3, chave `APP_EXPECT` e estado `wrong` no `app_probe`. O preflight falha com
  `E2E_CMD`; o `gate_QA` com e2e vermelho arma o `GATE_APP_DOWN`. Dois mutantes.
- `1ffee16`: I4, `.claude/rules/**` sai do `writes:` do `sdd-docs`. O `gate_DOCS` aceita `⛔` só com
  a proposta nomeando o documento, linha a linha, e passa em voz alta. O publisher e o template do
  PR levam o texto. Quatro mutantes.
- `c320630`: I5, `close_return_home` faz fetch e `merge --ff-only`. Nunca `die`; sem `timeout`,
  pula o fetch. Um mutante.
- `fbaf9a1`: I6, `Unavailable` com o requisito, o interpretador do PATH, o `sys.executable` e o
  remédio sondado. Um mutante.
- `3ac59ee`: I7, `RESOLVED by 121a696`, KAIZEN_LOG, ADR 0013 `accepted`, piso do `check-lang` em 55,
  `CONTEXT.md`, anatomia (§ 4 e § 6) e gaveta.

- `ec95baf`: revisão final. `app_probe` só lê `wrong` numa página 2xx (redirecionamento ou página de
  erro viram `unknown`). O remédio do Python aparece só para requisito de build. O `gate_DOCS` lê
  todas as seções marcadas, ignora `## ` dentro de bloco de código e exige que o documento seja um
  nome. Os resíduos do range (é do HEAD, não da missão) estão declarados. Stale e "achado" na
  superfície inglesa. Cinco mutantes.

## Artefatos

| Arquivo | O que contém |
|---|---|
| `docs/handoffs/20260928-os-achados-da-janela/checkpoint.md` | a tabela, com os 7 incrementos `done` |
| `docs/handoffs/20260928-os-achados-da-janela/checkpoint-notas.md` | um desvio por incremento, com o porquê |
| `docs/adr/0013-o-relatorio-da-missao-e-o-texto-proposto.md` | as duas decisões de contrato, agora `accepted` |

## Boot da próxima fase

Esta missão roda **interativa**, nunca por `sdd run` no próprio kit (handoff em
`~/.claude/plans/2026-09-28-handoff-executar-os-achados-da-janela.md`). O próximo passo é a revisão
da branch inteira (`git diff 3d350ed..HEAD`). Depois:

1. `/codereview:codereview` até Grade A.
2. Push e PR contra `main`, com status `local/ci` pela API de Statuses (o repo é público, mas a regra
   é a verificação local).
3. Esperar **todos** os revisores e consertar numa leva.
4. `./bin/sdd health` **uma vez**, depois do último commit de código. O `gate_PR` exige o carimbo.

O que o diff muda para quem usa o kit:

- a QA de missão em branch própria agora exige o relatório **dela**;
- `APP_EXPECT` é chave nova, vazia por default;
- a DOCS não escreve mais `.claude/rules/`;
- o `sdd close` anda a base;
- a recusa de coordenação diz qual Python caiu.

## Pendências / Decisions for a Human

- Depois do merge: `sdd install --force` no `sales_quote` e no `lighthouse_project`, para o espelho
  novo do `sdd-docs` e do `sdd-publisher` (o prompt só chega assim; a guarda do chapéu lê o kit e
  vale no merge). Também declarar `APP_EXPECT` no `.sdd/config.sh` de cada um: os dois usam a `:5173`.
- Depois do merge: apagar o item do achado 4 do `TODO.md` quando `121a696` for ancestral da `main`,
  e ressincronizar as issues (`/todo-to-github-issues`).

## Riscos e não-feitos

- **Mais estrito para quem já rodava QA em branch com relatório velho:** a fase passa a exigir o
  relatório da própria missão. É o custo pretendido (ADR 0013, Consequences). Continuam no resíduo
  declarado: a missão cuja `branch:` é a base, e a `DEFAULT_BRANCH` sem ref local.
- **Minors adiados da revisão final** (decisão do humano): relatório renomeado na branch e nome
  com espaço no `git status` (falham fechados, com motivo impreciso); a coluna do documento fixa em
  `$3`; o `sdd-docs` não nomeia o `sdd install --force` para os espelhos; o `start_page_server` não
  prova que o servidor na porta é o seu; `unavailable()` sob Python < 3.5; o close compara com o
  ref de rastreio, não com o `FETCH_HEAD`, em refspec fora do padrão.
- **Sem probe:** a linha sem prefixo no laço do `gate_DOCS` (nenhum ramo do awk a imprime hoje; o
  comentário declara isso) e o mundo "sem `timeout(1)`" do close.
- **O `sdd health` (catálogo inteiro) não rodou.** Cada mutante novo foi aplicado numa cópia e morto
  pela asserção certa, mas o carimbo de 435/435 é passo do PR.

## Achados fora de escopo

- Nenhum novo. Os achados 1, 2 e 5 foram para o `TODO.md` pelo I1: seções `Sensores que faltam` e
  `Contrato e configuração`.
