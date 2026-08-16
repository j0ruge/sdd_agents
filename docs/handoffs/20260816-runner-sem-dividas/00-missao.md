---
missao: 20260816-runner-sem-dividas
titulo: a seção "Runner — defeitos e dívidas" do TODO.md é eliminada por triagem e conserto
data: 2026-08-16
versao:
branch: missao/20260816-runner-sem-dividas
aprovacao: humano-2026-08-16
ddd: n/a
---

# Missão — a seção "Runner — defeitos e dívidas" do TODO.md é eliminada

> Prova de fogo: o kit trabalha no próprio backlog, sozinho. Intenção escrita pelo humano com o
> assistente da sessão; o `01-plano.md` (fonte do **como**) é da fase PLAN — primeira missão em
> que o `sdd-planner` é exercitado de verdade, o que por si já anda um item do TODO.

## Problema (Gemba)

A seção **"Runner — defeitos e dívidas"** do `TODO.md` tem 11 itens. Âncoras re-verificadas em
`7045e0f` nesta sessão — os números de linha do TODO **driftaram** (o `bin/sdd` mudou desde as
descobertas), e a posição atual de cada alvo é:

1. `printf | grep -q` sob `pipefail` na suíte — `tests/check-gates.sh:53` e
   `tests/check-dry-run.sh:144,163,171,199,251` (confirmados os seis).
2. Lint não cobre `tests/*.sh` — `tests/run-all.sh:32` linta só `bin/sdd`; o SC2318 de
   `tests/check-mutation.sh` (`local slug="$1" box="$WORK/$slug"`) reproduziu **nesta sessão**.
3. `latest_matching` ordena lexicograficamente — `bin/sdd:219-224` (`sort | tail -1`); o
   comentário em `:1334` até cita o defeito como "the bug the runner's latest_matching() still
   has".
4. `bad_rows` escrito e nunca lido — `bin/sdd:276,300`.
5. ⚠️ **`gate_DOCS` já lê a coluna Status** — `bin/sdd:422-450` implementa exatamente a
   `Direção` do item, com comentário descrevendo o conserto. O item parece **obsoleto**: a
   triagem deve fechar por artefato (hash em `main`) em vez de re-implementar. Conferir também se
   os outros 10 não têm a mesma sorte antes de tocar em qualquer um.
6. `${var:0:200}` promete corte por caractere sem fixar locale — `bin/sdd:821,827,850`.
7. `sdd install` diz "config criada" sobre arquivo vazio — `bin/sdd:1015` (`sed … > "$CONFIG_FILE"`
   sem guarda de existência do `starter.conf`).
8. Auto-degradação em laço REVIEW→PR→REVIEW — `bin/sdd:1554-1566` (`force_phase="PR"`); o F1
   fechou só a metade de registro.
9. Duas definições de comparabilidade no mesmo `jq` — `bin/sdd:1735` (`comparable`) vs `:1742`
   (`on_axis`).
10. Missão só-escalada conta para `guard.sufficient` — `bin/sdd:1854` (piso conta `missions`, não
    missões com sessão comparável).
11. Sessão de fase é ponto cego enquanto roda — `bin/sdd:897` (`--output-format json` emite blob
    único no fim; log fica 0 bytes por ~10 min).

Cada item carrega a análise da descoberta no `TODO.md` (teto de 8 linhas) e no handoff da missão
que o descobriu. O custo de deixá-los: 3 é gate verde apontando para artefato obsoleto quando
`*_MAX_ITER` passar de 9; 7 é rótulo sobre não-artefato dentro do instalador; 1 é a assinatura da
casa — a mesma família que manteve o Jidoka mentindo por duas missões.

## Métrica

- **Zero itens abertos** na seção "Runner — defeitos e dívidas" do `TODO.md` ao final — cada um
  **consertado** (com sensor quando a Direção pede) ou **fechado por obsolescência** citando o
  hash que já o resolveu (`git merge-base --is-ancestor <hash> main`), ou **explicitamente
  devolvido ao TODO** com justificativa do planner (corte de escopo é permitido, silêncio não).
- `tests/run-all.sh` verde com score de mutação ≥ 30/30 (asserção nova que a Direção de um item
  exigir entra com sabotagem, pela regra da casa).
- Nenhum item novo descoberto se perde: formato do arquivo de achados, medido por
  `tests/check-todo.sh`.

## Resultado esperado

O `bin/sdd` sem as dívidas conhecidas de runner: ordenação por versão onde hoje é lexicográfica,
instalador que morre alto em vez de mentir, suíte sem a família `printf | grep -q`, lint cobrindo
`tests/`, e as quatro dívidas de leitura do ledger (9, 10) e de observabilidade (11) resolvidas ou
re-registradas com decisão explícita. O `TODO.md` fica sem a seção — os achados sobreviventes, se
houver, migram para as seções que os descrevem melhor. Um PR aberto pelo kit fecha a missão.

## Fora de escopo

- Todo o resto do `TODO.md` — em particular a seção **"Adiados por YAGNI"** (instrução do humano:
  só quando inevitável) e as seções de sensores/contrato/idioma. Achado novo → entrada nova no
  `TODO.md`, nunca desvio.
- Renomeações de contrato PT-BR (`aprovacao`/`versao`/`titulo`, `00-missao.md`/`01-plano.md`) —
  têm item próprio em "Contrato e configuração".
- O alvo "<30 s" da suíte — item vivo em "Custo e escala", decisão de régua do humano.

## Gate PLAN-AUTO

Preenchido pelo `sdd-planner` **com evidência**. Todos ✅ → `aprovacao: auto` e o pipeline segue
sozinho. Qualquer ✗ → `aprovacao` fica vazio e o runner para pedindo aprovação humana explícita.

| # | Critério | Status | Evidência |
|---|---|---|---|
| a | Grill sem perguntas abertas não endereçadas (🚩 vazia ou itens deferidos com dono) | <✅/✗> | <onde ver> |
| b | Checklist kaizen 100% ✅ e checklist DDD 100% ✅ ou `n/a` justificado | <✅/✗> | <seção abaixo> |
| c | Plano passa no teste de autocontenção (sessão nova só com 00/01/checkpoint executa) | <✅/✗> | <como foi testado> |
| d | Todo incremento do `checkpoint.md` tem Check executável (comando → esperado) | <✅/✗> | <contagem> |
| e | `versao:` confirmada pelo humano (ou `JIRA_ENABLED=false`) | <✅/✗> | n/a — JIRA_ENABLED=false |

## Checklist kaizen (`kaizen-software`)

| # | Item | Status | Nota |
|---|---|---|---|
| K1 | Gemba — fui ver onde o trabalho acontece | <✅/✗> | âncoras re-verificadas em `7045e0f`; re-conferir no HEAD da branch |
| K2 | Problema declarado com métrica | <✅/✗> | |
| K3 | Desperdícios identificados e cortados | <✅/✗> | item 5 sugere triagem antes de conserto |
| K4 | Fatiamento incremental, cada fatia verificável | <✅/✗> | |
| K5 | Check por artefato (rótulo ≠ artefato) | <✅/✗> | |
| K6 | Jidoka — o que para a linha está definido | <✅/✗> | itens 1-2 tocam a suíte que os gates rodam |
| K7 | SDCA — a melhoria vira padrão (doc/rule/teste) | <✅/✗> | |
| K8 | Registro no KAIZEN_LOG | <✅/✗> | |

## Checklist DDD (`ddd`) — condicional

n/a — sem toque de domínio: dívidas de runner bash e de suíte; nenhum contrato entre módulos muda.

## Decisões do grill (não re-litigar)

1. Bloco escolhido: "Runner — defeitos e dívidas" — melhoria imediata, reduz risco de toda missão
   futura (decisão do humano, delegada e confirmada em 2026-08-16).
2. O kit trabalha sozinho; o humano e o assistente só observam e respondem a escalada — mão no
   meio contamina a medição da prova de fogo.
3. Triagem antes de conserto: item cuja Direção o código já implementa fecha por hash, nunca por
   re-implementação (o item 5 é o caso conhecido; procurar outros).
4. Corte de escopo pelo planner é aceito com justificativa; os cortados permanecem no `TODO.md`.

## Pendências para o humano

- Merge do PR ao final, como sempre.
