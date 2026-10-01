---
missao: 20260930-a-sub-etapa-que-andou
fase: EXEC
status: done
sessao: abf197ce-fc03-4ab8-a609-a64f5bd09c0c
data: 2026-10-01 01:49
gate: "tests/run-all.sh → suite green (19 passos, 1652 linhas `ok`, 0 FAIL; anchors: all 513 mutants still apply); checkpoint I1–I6 done com hash; `sdd autonomy --all-repos --by-mission` → as 3 linhas da métrica + a linha `QA row(s) older than step_after` (grep -c → 4); `check-todo.sh --count TODO.md` → 85"
---

# Handoff — EXEC — o sub-passo da QA que andou

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

Os seis incrementos estão `done`. A linha QA do ledger agora carrega `step_after` e a foto de
`pending`; a rubrica de outcome ganhou o braço do sub-passo (QA que andou de sub-passo = `advanced`)
e o laço QA⇄EXEC (QA que escreveu fix = laço projetado, não churn). O histórico recupera o
`step_after` pela próxima linha QA. As três missões da métrica leem 19·2, 14·1 e 17·3. A varredura D15
tirou cinco itens do backlog (90 → 85). Suíte verde. A próxima fase (QA) mede a CLI `sdd autonomy`.

## Estado do repo

- **Branch:** `kaizen/a-sub-etapa-que-andou` — local, sem push (o push é da fase PR)
- **Último commit:** o commit do checkpoint e deste handoff, logo após `7ee1c3e` `chore(todo): varredura D15 — cinco itens saem do backlog (90 → 85)`
- **Working tree:** limpo depois do commit deste handoff
- **Suíte:** `tests/run-all.sh` → verde, 19 passos, 1652 asserções `ok`, catálogo com 513 âncoras válidas
- **E2E:** não se aplica (o kit não tem `E2E_CMD`; a superfície é CLI)

## O que foi feito

- `74996fa` — I1: o escritor. A linha QA do ledger carrega `step_after` nas três portas (1ª passada
  do `cmd_run`, retry inline, `cmd_retry`); linha que não é QA leva `null`. Um probe e um mutante por porta.
- `c8d156b` — I2: o leitor. `step_rank` e o braço do sub-passo em `ledger_outcome_defs`: sub-passo
  que avançou lê `advanced`; a mesma linha sem avanço lê `churned`.
- `ec4ecf0` — I3: o laço QA⇄EXEC. A linha QA fotografa `pending_before`/`pending_after`; QA que
  escreveu fix é o laço projetado, e EXEC cujo `pending` cresceu continua sendo churn.
- `163cd94` — I4: o histórico. Linha QA antiga sem a chave recupera `step_after` pela próxima linha
  QA da mesma (repo, missão), e o rodapé conta `(N QA row(s) older than step_after …)`.
- `4c0e079` — I5: docs. 4ª emenda da D16, verbete Churn, `docs/pipeline.md`, `KAIZEN_LOG.md` (com
  antes/depois medido) e `docs/failure-modes.md`.
- `7ee1c3e` — I6: varredura D15. Cinco itens saíram do `TODO.md`: dois para o cabeçalho dos
  sensores (`check-health.sh`, `check-autonomy.sh`), um porque já estava declarado, um para a seção
  decidida (resolvido fora do kit: `retrofit-watch` 0.2.0) e um para a Y4 do `CONTEXT.md`. A catraca
  desceu 90 → 85 no mesmo commit.

## Artefatos

| Arquivo | O que contém |
|---|---|
| `bin/sdd` | escritor (`step_after`, `pending_*` na linha QA) e leitor (`step_rank`, `historic_steps`, braços novos em `ledger_outcome_defs`) |
| `tests/check-autonomy.sh`, `tests/check-kaizen.sh` | os probes do escritor e da rubrica |
| `tests/check-mutation.sh` | catálogo 495 → 513 mutantes |
| `CONTEXT.md`, `KAIZEN_LOG.md`, `docs/pipeline.md`, `agents/sdd-kaizen.md` | a régua nova documentada |
| `TODO.md`, `tests/health-baseline.txt` | backlog 90 → 85 |

## Boot da próxima fase

QA sobre a CLI, sem navegador e sem app. O que o usuário vê mudou em dois lugares:

1. **`sdd autonomy`** (todas as formas: padrão, `--all-repos`, `--by-mission`): uma linha QA cujo
   sub-passo andou passa a contar como `advanced`; uma QA que escreveu incrementos de fix deixa de
   ser `churned`. No rodapé entra a frase `(N QA row(s) older than step_after …)`.
   Jornada: `./bin/sdd autonomy --all-repos --by-mission` → as três missões da métrica
   (`20260929-aviso-diretoria-por-email` 21·19·2·0, `20260930-e2e-local-diz-por-que-caiu`
   15·14·1·0, `20260930-justificativa-pedido-alcada` 20·17·3·0). Nenhuma outra missão mudou de
   número (medido no I4 com um diff antes × depois).
2. **O ledger** (`autonomy_log_path`): a linha `session` de fase QA ganhou `step_after`,
   `pending_before` e `pending_after`; as outras fases levam `step_after: null`, e
   `pending_*` só existem em EXEC e QA.

A régua mudou em 2026-09-30, então números de janelas anteriores mudam sob o leitor novo. Isso é
o objetivo da missão e está declarado no `KAIZEN_LOG.md`. A fatia `5b98087` foi de 44·9 para 47·6.
Ambiente: nenhum; `sdd autonomy` só lê o ledger em `~/.sdd/` (ou `SDD_STATE_DIR`).

## Pendências / Decisions for a Human

- Nenhuma nova nesta fase.

## Riscos e não-feitos

- `check-coordination.sh` ficou vermelho **uma vez** no pré-check do I6: o
  `subprocess.TimeoutExpired` de 8 s em `sdd run 20260101-one`, logo depois de `signal recovers: 15`.
  Rodado sozinho em seguida: 186 passed, 0 failed, e a suíte inteira pós-I6 ficou verde. Não vai
  para o `TODO.md`: falha fechada, sem consumidor fora da suíte (régua D15). Se reaparecer, vira medição.
- A frase do rodapé e os braços novos foram medidos contra o ledger real desta máquina. Ledger de
  outra máquina com linhas QA truncadas à mão não foi exercitado (limite já declarado no
  `check-autonomy.sh`).
- `sdd health` não rodou nesta fase: o carimbo de mutação é da fase PR, depois do último commit de código.

## Achados fora de escopo

- Nenhum novo nesta fase. O único candidato (o vermelho de timing do `check-coordination.sh`)
  ficou fora do `TODO.md` pela régua D15; está nos riscos acima e nas notas de execução.
