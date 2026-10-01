---
missao: 20260930-a-sub-etapa-que-andou
fase: EXEC
status: done
sessao: abf197ce-fc03-4ab8-a609-a64f5bd09c0c
data: 2026-10-01 02:40
gate: "tests/run-all.sh → suite green (19 passos, 1654 linhas `ok`, 0 FAIL; anchors: all 515 mutants still apply); checkpoint I1–I6 e R1 done com hash; `check-kaizen.sh` → `ok    a QA row older than step_after is not recovered from the next row of another run`; `sdd autonomy --all-repos --by-mission` → as 3 linhas da métrica intactas + `(22 QA row(s) older than step_after …)` (grep -c → 4)"
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
**r1 do REVIEW:** o `R1` (`8a1b3a5`) restringiu a recuperação histórica à mesma corrida (`run_id`);
métrica intacta, rodapé 28 → 22 linhas recuperadas. Próxima fase: REVIEW r2.

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

## Rodada r1 do REVIEW — incrementos de conserto

- `8a1b3a5` — `R1` (achado #1 da r1, MEDIUM). O `historic_steps` recuperava o `step_after` de uma
  linha QA antiga a partir da próxima linha QA de **qualquer** corrida, creditando à sessão o avanço
  feito entre corridas (por exemplo, um humano que fechou o relatório). A memória guarda agora
  `{step, run_id}` e só recupera com `run_id` igual e não nulo; o limite que o comentário declarava
  ("só erra para o lado conservador") foi reescrito, e a régua D15 trocou a declaração por conserto.
  - Sensores: em `tests/check-kaizen.sh`, as missões de fixture `m84` (próxima linha de outra
    corrida → `1 advanced · 1 churned`) e `m85` (duas linhas sem `run_id` → idem); a paridade dos
    leitores subiu de `6 3 0` para `8 5 0`.
  - Mutantes `mut_KAIZEN_historic_steps_crosses_runs` e `mut_KAIZEN_historic_steps_null_run_is_a_run`,
    um por metade da guarda, medidos mortos numa cópia (catálogo 513 → 515).
  - Ledger real: diff do `--by-mission` antes × depois muda **uma** linha, o rodapé 28 → 22. As três
    linhas da métrica ficam intactas, como a r1 previu.
  - `CONTEXT.md` (D16) e `KAIZEN_LOG.md` atualizados; 22 âncoras do `TODO.md` remapeadas pelo diff.

**Boot do REVIEW r2:** o diff da rodada é `8a1b3a5` inteiro. O que olhar: a guarda nova em
`def historic_steps` (`bin/sdd`, em `ledger_outcome_defs`), o bloco `m80`–`m85` do `check-kaizen.sh`
e os dois mutantes novos. O achado #2 da r1 (fixture que herda `GIT_REFLOG_ACTION`) continua aberto
no `TODO.md`: dentro de uma sessão o `check-autonomy.sh` fica vermelho, e por isso esta sessão rodou
a suíte com `env -u GIT_REFLOG_ACTION`, que é o ambiente em que o gate a roda.

## Artefatos

| Arquivo | O que contém |
|---|---|
| `bin/sdd` | escritor (`step_after`, `pending_*` na linha QA) e leitor (`step_rank`, `historic_steps`, braços novos em `ledger_outcome_defs`) |
| `tests/check-autonomy.sh`, `tests/check-kaizen.sh` | os probes do escritor e da rubrica |
| `tests/check-mutation.sh` | catálogo 495 → 513 mutantes (515 depois do `R1`) |
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
