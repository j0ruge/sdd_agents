# Handoff — depois do #170: o E6 e a próxima escolha de frente (2026-09-25)

> Continuação autocontida do
> [handoff da entrega do P2(b)](2026-09-25-o-sensor-para-no-primeiro-fail-handoff.md), que está
> encerrado. Leia este arquivo; o outro é histórico.

## Estado em 2026-09-25, 22:25

- **PR #170 mergeado** em `main` = **`31dfd43`** ("Merge pull request #170", merge commit, como os
  anteriores). O P2(b) da F1 está fechado.
- **Carimbo de mutação válido na `main`:** `1240f67f…`, 406 de 406. A chave é o conteúdo de
  `bin/ tests/ templates/ config/`, e ele é o mesmo de `e8283e6`, onde o health nº 3 rodou.
- **`sdd health` custa ~18 min** (três rodadas: 18:56, 18:14, 18:24), contra 37 min 42 s antes. Daqui
  em diante o ganho vem de baratear o mutante (F1-P1/P4), não de reordenar: os 406 mutantes somam
  12 031 s (~12,5 min em 16 vagas), e o resto são ~3,5 min de suíte rápida.
- **`TODO.md`:** 82 achados ↔ **82** issues abertas com a label `todo` desde o re-sync de 2026-09-26
  (E6, abaixo). A **#144**, que saiu do arquivo no #170, está fechada.
- **Este branch** (`docs/depois-do-170`) leva só este handoff e a linha da F1 na gaveta, pelo
  **PR #171**, que se mergeia só com o ok do humano. Nada nele toca a chave do carimbo.

## E6 — o que faltava do #170: **FEITO em 2026-09-26**

Não refaça nenhum dos três passos; o que sobra é a escolha da seção seguinte.

1. **Espelho de issues re-sincronizado** com a skill `todo-to-github-issues`. O plano deu `update=14`
   além da órfã: os 14 eram só número de linha de âncora que o #170 re-apontou no `TODO.md`
   (conferido com `--dump` contra o corpo vivo, dígitos normalizados, 14 de 14). A **#144** fechou como
   `completed`, citando `b874141` (o conserto) e `82572b2` (a saída do arquivo, pelo #170). O plano
   voltou `create=0 update=0 orphans=0`.
2. **Branch `perf/sensor-para-no-primeiro-fail` apagado**, no remoto e o local (a ponta `b2741d3` está
   na `main`).
3. **PR #171 aberto** deste branch, com o `stamp-check` em `STAMP VALID` antes (sem health: a chave do
   carimbo não muda). Revisores: CodeRabbit e Codex acharam o mesmo ponto (este bloco dizia que o E6
   estava por fazer), consertado no próprio PR; o Copilot não revisou, sem cota.

## Depois do E6 — a escolha é do humano

A recomendação da gaveta
([`2026-09-23-a-gaveta-do-kit.md`](../specs/2026-09-23-a-gaveta-do-kit.md), fim do arquivo) segue
valendo, e o item 1 dela está feito:

- **Item 2: decidir se o kit congela** para a janela do juiz (F3). Tudo o que muda a `main` encalha a
  janela. Se congelar, os itens 3–5 esperam o veredito. **Pergunte antes de propor trabalho de kit.**
- **Item 3, se não congelar:** um PR "de carona", que carimba uma vez só. Nele entram o F1-P3
  (varredura das probes sensíveis a tempo sob carga, pré-requisito de qualquer paralelismo a mais), a
  F2 (ADR 0010 para `accepted`, 2 itens do `TODO.md`), a F4 (lacunas de portabilidade) e as issues
  pequenas entre #50, #52 e #53. Planeje com `/sdd-plan` ou brainstorm, nunca direto no código.

## Pendências sem rota de `TODO.md` (régua D15), anotadas para quem mexer ali

- **`/tmp/sdd-coordination-*/repo/.git`** sobra em cada health. É o mutante `COORD_pidfd_unchecked`:
  ele mata o `check-coordination.sh` por **exceção** (sem linha FAIL), e o `rmtree(work)` do `finally`
  corre contra o supervisor, que ainda escreve. Isso é anterior ao #170: em 6 rodadas de cada, a `main`
  (`8f2f2a9`) vazou 2 vezes e o branch 1.
- **`/tmp/sdd-ck-*`** sobram ~150 por health, e também são anteriores (`bin/sdd:440`; 158 no health do
  #168).

## Regras operacionais que continuam valendo

- Suíte e health **só** pelo lançador (`SIG_DFL`, sem `CLAUDE*`, sessão nova), nunca como tarefa de
  fundo do Bash tool. O texto do `health-launch.py` e do `stamp-check.sh` está no
  [plano do P2(b)](2026-09-25-o-sensor-para-no-primeiro-fail.md), "Antes de começar", passo B.
  Recrie os dois no scratchpad da sessão.
- **Nunca commite com um `sdd health` rodando**: o hook de commit apaga `/tmp/sdd-*` com mais de 10 min.
- PR do kit: abrir → esperar **todos** os revisores (o Codex só vem com `@codex review`; o Copilot
  está sem cota) → uma leva de consertos → carimbar **uma vez** → merge com o ok do humano.

## Prompt para depois do `/clear`

```text
Siga o handoff docs/superpowers/plans/2026-09-25-depois-do-170-handoff.md. O E6 está feito
(espelho 82 ↔ 82, #144 fechada, branch apagado, PR #171); não refaça nada dele. Se o #171 ainda
estiver aberto, me peça o merge. Depois me pergunte se o kit congela para a janela do juiz
(item 2 da recomendação da gaveta) antes de propor qualquer trabalho de kit.
```
