---
missao: 20260814-dry-run-completo
data: 2026-08-14
---

# Plano — dry-run mostra o pipeline inteiro

## Contexto verificado (não re-descobrir)

- O runner é `bin/sdd`, bash puro, `set -euo pipefail`, exige bash 4+.
- `cmd_run()` tem o laço principal. Dentro dele, depois de `run_phase "$phase"`, existe:

  ```bash
  if [ "$DRY_RUN" = "1" ]; then
    [ -n "$force_phase" ] && return 0
    dim "  (dry-run: parando após imprimir a primeira fase)"
    return 0
  fi
  ```

  É esse `return 0` que trunca o dry-run na primeira fase.
- `run_phase()` já sabe imprimir tudo (cwd, modelo, agente, sessão, comando, prompt) quando
  `DRY_RUN=1`; ela **não** precisa mudar.
- `current_phase()` devolve a primeira fase cujo gate não passa. Com `DRY_RUN=1` nada muda no
  disco, então chamá-la de novo devolveria **a mesma fase para sempre** — um laço infinito.
  A projeção precisa percorrer a lista `$PHASES` diretamente, pulando os gates satisfeitos.
- `readonly PHASES="PLAN TICKET EXEC QA REVIEW DOCS PR"` — a ordem canônica.
- Gates são funções `gate_<FASE>`; retornam 0/1 e escrevem o motivo em `GATE_WHY`.
- `gate_EXEC`, `gate_QA` e `gate_REVIEW` rodam `TEST_CMD`. No dry-run isso é aceitável (a
  suíte do kit é rápida) e o resultado é memoizado por processo em `run_check_cmd`.
- A fase `PLAN` não é headless: quando pendente, `cmd_run` imprime a instrução para o humano
  e retorna 2.
- A suíte do kit é `tests/run-all.sh`, que chama `tests/check-templates.sh` e
  `tests/check-gates.sh`. Os testes usam `mktemp -d`, montam um repo-fixture com `git init` e
  afirmam com uma função `assert_*` que compara esperado × obtido e conta falhas.

## Arquitetura da mudança

Duas partes, nesta ordem (TDD):

1. **Sensor** — `tests/check-dry-run.sh`, no mesmo estilo de `tests/check-gates.sh`: monta um
   repo-fixture, instala o kit, planeja uma missão com um incremento pendente, roda
   `sdd run <m> --dry-run` capturando a saída e afirma que ela nomeia todas as fases
   pendentes. Entra em `tests/run-all.sh`.
2. **Implementação** — no bloco `DRY_RUN` de `cmd_run`, em vez de `return 0`, seguir para a
   próxima fase pendente da lista `$PHASES` (não via `current_phase`, que travaria no mesmo
   lugar). Quando a lista acabar, retornar 0.

## Incrementos

### I1 — dry-run projeta todas as fases pendentes

**O quê:** `sdd run <missão> --dry-run` passa a imprimir, em ordem, todas as fases cujo gate
está insatisfeito hoje — não apenas a primeira.

**Onde:** `tests/check-dry-run.sh` (novo), `tests/run-all.sh` (registra o sensor), `bin/sdd`
(bloco `DRY_RUN` dentro de `cmd_run`).

**Como (TDD):**

1. **Red** — escreva `tests/check-dry-run.sh` primeiro. O fixture: `git init`, `sdd install`,
   `.sdd/config.sh` com `TEST_CMD="true"` e `JIRA_ENABLED=false`, e uma missão em
   `docs/handoffs/20260101-fixture/` com `00-missao.md` (`aprovacao: auto`), `01-plano.md`
   vazio e um `checkpoint.md` com uma linha `pending`. Rode
   `sdd run 20260101-fixture --dry-run` e afirme que a saída contém, cada uma uma vez:
   `fase EXEC`, `fase QA`, `fase REVIEW`, `fase DOCS`, `fase PR`; e que o agente correto
   aparece em cada bloco (`sdd-executor`, `sdd-qa`, `sdd-reviewer`, `sdd-docs`,
   `sdd-publisher`). Afirme também que **nada** foi criado no disco pelo dry-run (o
   `git status` do fixture continua igual antes e depois). Rode: **deve falhar**, porque hoje
   só sai `fase EXEC`.
2. **Green** — no bloco `DRY_RUN` de `cmd_run`, troque o `return 0` por um avanço para a
   próxima fase pendente de `$PHASES`. Mantenha o comportamento de `--phase <FASE>`: com fase
   forçada, imprime só ela e retorna. Não mexa em `run_phase`.
3. Registre o sensor em `tests/run-all.sh`.

**Check:** `tests/check-dry-run.sh` → exit 0, **e** `tests/run-all.sh` → exit 0.

**Sensor durável:** `tests/check-dry-run.sh`, permanente na suíte do kit.

**Reversível por:** `git revert` do commit — o sensor e a implementação vão juntos.

## Riscos e não-feitos

| Risco | Probabilidade | Mitigação |
|---|---|---|
| Laço infinito ao projetar (dry-run não muda o disco, gate nunca passa) | alta se usar `current_phase` | percorrer `$PHASES` por índice, nunca re-consultar `current_phase` |
| Gates rodando `TEST_CMD` várias vezes no dry-run | baixa | `run_check_cmd` já memoiza por processo |
| Quebrar `--phase <FASE>` (que deve imprimir só a fase pedida) | média | asserção explícita no sensor |

## Verificação end-to-end

```bash
tests/run-all.sh     # → exit 0, com o sensor novo incluído
```

E, à mão, numa missão real: `sdd run <missão> --dry-run` lista EXEC → QA → REVIEW → DOCS → PR.
