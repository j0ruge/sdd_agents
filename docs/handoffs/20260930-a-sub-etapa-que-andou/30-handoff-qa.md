---
missao: 20260930-a-sub-etapa-que-andou
fase: QA
status: done
sessao: sessão headless QA:close do runner (uuid no log JSON em .sdd/logs/)
data: 2026-10-01 02:00
gate: "sem interface, jornada percorrida no terminal sobre 7e08c1d. (1) ./bin/sdd autonomy --all-repos --by-mission imprime aviso-diretoria-por-email 21·19·2·0, e2e-local-diz-por-que-caiu 15·14·1·0 e justificativa-pedido-alcada 20·17·3·0, mais o rodapé (28 QA row(s) older than step_after read their sub-step from the next row). (2) diff com main (git archive em /tmp) nas três formas: --by-mission muda só essas 3 linhas e o rodapé; --all-repos muda só a fatia 5b98087 (44·9 16% → 47·6 11%) e o rodapé; a forma padrão muda só o rodapé (1 QA row). (3) ledger vazio (SDD_STATE_DIR=mktemp): warn no data, rc=1, igual na main. (4) tests/run-all.sh → suite green, rc=0, 1652 ok, catálogo 513 âncoras aplicam, em 4m31s. Achados: 0"
---

# Handoff — QA — o sub-passo da QA que andou

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

QA sem interface (`E2E_CMD` e `APP_URL` vazios), percorrida no terminal: 4 jornadas da CLI
`sdd autonomy` (`--by-mission`, `--all-repos`, padrão, ledger vazio), cada uma comparada com a `main`.
Os números da métrica batem e nenhuma linha fora das previstas mudou. **0 achados**: nenhuma spec,
nenhum `F<n>`, nada para o humano decidir. Suíte verde (1652 `ok`, rc 0). Ressalva: o escritor
novo (`step_after`/`pending_*` na linha QA) ainda não gravou nenhuma linha real, porque o `sdd run`
desta missão subiu antes do I1. Ele só foi provado pelos probes.

## Estado do repo

- **Branch:** `kaizen/a-sub-etapa-que-andou`, local, sem push (o push é da fase PR)
- **Último commit antes deste handoff:** `7e08c1d` `chore(checkpoint): I6 done em 7ee1c3e e handoff de EXEC`
- **Working tree:** limpo, exceto por este handoff e pela nota de execução
- **Suíte:** `tests/run-all.sh` → `suite green`, rc 0, 1652 linhas `ok`, `anchors: all 513 mutants still apply`
- **E2E:** não se aplica: `E2E_CMD` vazio, o kit é uma CLI bash

## O que foi feito

Não houve commit de código: a QA não conserta código de produção, e não houve achado.

- Jornada 1: `./bin/sdd autonomy --all-repos --by-mission` sobre o ledger real. As três missões
  da métrica leem `21·19·2·0`, `15·14·1·0` e `20·17·3·0`, e o rodapé diz
  `(28 QA row(s) older than step_after read their sub-step from the next row)`.
- Jornada 2: diferencial antes × depois. A `main` foi extraída por `git archive` em `/tmp` e cada
  forma rodou com os dois binários sobre o mesmo ledger.
  - `--by-mission`: mudam só as três linhas da métrica (18·3 → 19·2, 13·2 → 14·1, 16·4 → 17·3) e
    entra o rodapé.
  - `--all-repos`: muda só a fatia `5b98087` (`44 advanced · 9 churned · 16% waste` →
    `47 advanced · 6 churned · 11% waste`) e entra o rodapé.
  - forma padrão (repo do kit): nenhum número muda, só entra o rodapé com `1 QA row(s)`.
- Jornada 3, borda: com o ledger vazio (`SDD_STATE_DIR` num `mktemp -d`), a saída é
  `warn  no data … ` com rc 1, igual à da `main`. Não houve regressão.
- Jornada 4, o escritor: as seis asserções que os Checks nomeiam estão `ok` na suíte completa
  (`a QA row carries the step the session left behind`, `a non-QA row carries step_after as null`,
  `a QA sub-step that advanced reads advanced`, `the same QA row with no sub-step advance reads churned`,
  `a QA close that wrote fix increments is the designed loop`, `an EXEC row whose pending grew is still churn`).
- `bash tests/check-todo.sh --count TODO.md` → `85`, que é a catraca do I6.

## Artefatos

| Arquivo | O que contém |
|---|---|
| `docs/handoffs/20260930-a-sub-etapa-que-andou/30-handoff-qa.md` | este handoff, com a evidência da jornada no `gate:` |
| `docs/handoffs/20260930-a-sub-etapa-que-andou/checkpoint-notas.md` | uma linha acrescentada (`QA`) |

Nenhuma spec nova (o kit não tem `E2E_DIR`), nenhum bug registrado. Não houve achado, então nenhum
teste novo entrou no `TEST_CMD`. A árvore `docs/qa/` do kit foi posta ali por humano e **não foi
tocada**: esta missão não adicionou relatório, e no caminho sem interface o gate não o exige.

## Boot da próxima fase

REVIEW. O que a QA viu e o revisor precisa saber:

1. **A métrica bate e o diferencial está limpo** nas três formas do `sdd autonomy` (ver "O que foi
   feito"). Para reproduzir:
   `git archive main | tar -x -C /tmp/b && diff <(/tmp/b/bin/sdd autonomy --all-repos --by-mission 2>&1) <(./bin/sdd autonomy --all-repos --by-mission 2>&1)`.
2. **O escritor não foi visto em produção.** As 7 linhas desta missão no ledger (`KAIZEN` + 6 `EXEC`)
   **não têm** a chave `step_after` (`has("step_after") == false`), que é a forma do escritor
   antigo. A causa: o `sdd run` em curso (PID 3973284) subiu às ~00:06, antes de `74996fa` (I1,
   00:22), e o `{ main "$@"; exit $?; }` mantém o bash no código que leu na partida. A linha da
   própria QA também vai sair no formato antigo. Hoje a prova do escritor são os probes de
   `check-autonomy.sh` (três portas, um mutante por porta). Vale olhar o escritor com atenção na
   revisão.
3. O rodapé da forma padrão (`1 QA row(s)`) aparece sem mudar nenhum número. É coerente, porque a
   linha recuperada já lia `advanced` por outro braço, mas é o único ponto em que o rodapé fala de
   uma recuperação sem efeito visível.

## Pendências / Decisions for a Human

- Nenhuma nova. A pendência da missão continua aberta no `00-missao.md`: refazer a janela 2 ou
  abrir a próxima depois desta missão, porque a régua de `outcome` mudou.

## Riscos e não-feitos

- O escritor ainda não gravou nenhuma linha real com `step_after`, `pending_before` e
  `pending_after` (ver Boot, item 2). A primeira prova em produção será a primeira fase QA de uma
  missão lançada sobre um kit que contenha `74996fa`.
- O laço QA⇄EXEC (quinto braço) não tem nenhuma linha real que o exerça: só linhas novas o
  alcançam, como o plano declarou.
- `sdd kaizen --series` não foi percorrido diretamente. A paridade com `autonomy --all-repos` é
  medida pelo `check-kaizen.sh`, que está verde.

## Achados fora de escopo

Nenhum.
