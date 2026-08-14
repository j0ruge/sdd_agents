---
missao: 20260814-dry-run-completo
fase: QA
status: blocked
sessao: b1598d39-a0db-457e-8409-70d227395f9b
data: 2026-08-14 03:30
gate: "`gate_QA` REPROVA de propósito. 1 jornada andada (`sdd run <m> --dry-run`) em 4 estados de borda; 1 achado confirmado → `BUG-dryrun-pipelinelog`; sensor `tests/check-dry-run.sh` commitado **vermelho** (3 asserções novas falham com o bug presente, a 4ª — guarda de exit 3 — passa); `tests/run-all.sh` → exit 1. Bug sanável virou `F1` no checkpoint: o runner devolve a bola ao EXEC (`sdd phase` → `EXEC`, `1 de 2 incremento(s) ainda por executar`)."
---

# Handoff — QA — dry-run mostra o pipeline inteiro

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

Andei a única jornada que este repo tem — `sdd run <missão> --dry-run` — em 4 estados de borda e
achei **1 bug confirmado**: com um incremento `blocked`, a projeção **escreve no disco**
(`pipeline.log` da missão) um evento `BLOCKED` que nunca aconteceu. Virou sensor commitado e
vermelho + incremento `F1` para o executor. **Não corrigi produção.** A próxima fase é EXEC, não
REVIEW. Um segundo achado, estrutural, **trava o fechamento da QA neste repo** e precisa de
decisão humana — leia "Pendências" antes de rodar a próxima QA.

## Estado do repo

- **Branch:** `missao/20260814-dry-run-completo` — local, sem remoto; push é da fase PR.
- **Último commit:** `476a6e0` `test(qa): sensor do achado — dry-run escreve no diario da missao (F1)`
- **Working tree:** limpo depois do commit desta sessão.
- **Suíte:** `tests/run-all.sh` → **vermelho**, exit 1, 3 asserções falhando — **de propósito**.
  É o Red do `F1`, não uma regressão: as 98 asserções pré-existentes continuam verdes e as 3
  novas falham exatamente pelo defeito descrito abaixo. Jidoka: o sensor vermelho para a linha.
- **E2E:** `E2E_CMD` vazio no `.sdd/config.sh` — o kit é bash + markdown, não há navegador. Não
  rodou por não existir. A jornada deste repo é alguém digitar `sdd` no terminal.

## Como a QA rodou aqui (leia antes de estranhar a ausência de `docs/qa/`)

Não existe árvore `docs/qa/` neste repo e **isso está certo**: `qa_substep` (`bin/sdd:444`) manda
projeto sem `E2E_CMD` e sem `APP_URL` direto para o sub-passo `close`, pulando as skills
`qa-report`/`qa-execution` — bootstrapar jornadas de browser num projeto sem browser é a
burocracia que o `skipped` existe para evitar (commit `73e594e`). Consequência: **não havia
sessão em persona antes desta**, então a jornada fui eu que andei, e o registro dela é este
handoff — não há relatório datado em `reports/` nem `bugs/<id>.md` para apontar.

`status: skipped` **não** era resposta legítima aqui. O diff é user-visible: `sdd run --dry-run` é
um comando que o usuário roda e lê, e sua saída mudou nesta missão. Andar a jornada não foi
formalidade — encontrou defeito real.

## Jornada andada

`sdd run <missão> --dry-run` — "o que acontece se eu rodar isto?" — nos 4 estados de borda que o
`20-handoff-exec.md` listou como não-assertados:

| # | Estado | Esperado | Obtido | Veredito |
|---|---|---|---|---|
| J1 | missão real, parada em `QA:close` | projeta QA→REVIEW→DOCS→PR com agente e modelo | exatamente isso; repo real seguiu limpo | ✅ |
| J2 | missão parada em PLAN | instrução interativa, exit 2, nada projetado, disco intacto | exit 2, árvore e `git status` idênticos | ✅ |
| J3 | missão com incremento `blocked` | escala exit 3 **sem tocar no disco** | exit 3 ✅ **mas criou `pipeline.log`** | ❌ **achado** |
| J4 | missão "completa" + `--phase` | uma fase só / `pipeline completo` | `--phase` ok; o fixture "completo" não fechou por **erro meu de fixture** (hash `abc1234` inexistente reprova `gate_EXEC`), não por bug do runner | ✅ (descartado) |

J4 está registrado porque um falso positivo descartado também é resultado de QA — e para a
próxima sessão não re-investigar.

## Achado confirmado — `BUG-dryrun-pipelinelog`

**O quê:** `sdd run <m> --dry-run`, numa missão com incremento `blocked`, grava
`docs/handoffs/<m>/pipeline.log` com a linha
`<timestamp>  BLOCKED  EXEC  incremento marcado blocked pelo executor`.

**Por que é bug:** o `00-missao.md` desta missão define, em "Resultado esperado", que "nada é
executado e **nada no disco muda**". Uma projeção é comando de leitura — é o que o usuário roda
justamente para não mexer em nada. Aqui ela mente na trilha de auditoria: registra como
acontecido um evento que só foi projetado.

**Causa (verificada, não suposta):** em `cmd_run` o Jidoka de `blocked` (`bin/sdd:947`) chama
`pipeline_log_line` e dá `return 3` **antes** de o fluxo alcançar o bloco `DRY_RUN`. Confirmei que
é o único `pipeline_log_line` alcançável em dry-run: o de `run_phase` (`bin/sdd:618`) está atrás
da guarda `DRY_RUN` da própria função; os de orçamento estourado (`963`) e de duas-sessões-sem-
progresso (`1014`) exigem `attempts > budget` / uma `run_phase` real, e a projeção visita cada
fase uma única vez.

**Blast radius maior do que parece:** o `sdd install` só põe `.sdd/logs/` no `.gitignore` do alvo
(`bin/sdd:706-712`), então em repo-alvo recém instalado esse `pipeline.log` fica **untracked** e
suja o `git status` — e tree sujo reprova `gate_REVIEW` (`bin/sdd:361`) e o `sdd preflight`
(`bin/sdd:814`). Ou seja: um comando de projeção pode derrubar o gate de outra fase. Este repo não
sente porque o `.gitignore` dele ganhou `*.log` à mão, fora do install; o piloto `sales_quote`
sentiria. (A decisão "`pipeline.log` é efêmero ou durável?" é maior que esta missão → `TODO.md`.)

**Sensor (Red observado antes de qualquer conserto):** `tests/check-dry-run.sh` — seção nova
"projeção não escreve no diário da missão (incremento blocked)". Com o bug presente:

```
  ok    dry-run de missão blocked escala com exit 3        ← guarda de regressão, já passava
  FALHA projeção blocked não cria pipeline.log
  FALHA árvore idêntica antes e depois (caminho blocked)
  FALHA working tree continua limpo (caminho blocked)
```

Sensor que passa com o bug presente é decoração, não sensor — estas três falham. Entrou no
`tests/check-dry-run.sh` porque é a mesma jornada que o sensor já protege (um sensor por jornada);
não virou spec Playwright porque não há navegador, e o defeito vive no bash do runner, que é o
domínio do `TEST_CMD`.

## O que foi feito

- `476a6e0` — **sensor do achado (Red do `F1`) + `F1` no checkpoint + 3 entradas no `TODO.md`.**
  Nenhuma linha de `bin/sdd` foi tocada: **QA não corrige produção**.
- *(commit seguinte)* — este handoff.

## Artefatos

| Arquivo | O que contém |
|---|---|
| `tests/check-dry-run.sh` | Seção nova (4 asserções) — o sensor durável do achado, hoje vermelho |
| `docs/handoffs/20260814-dry-run-completo/checkpoint.md` | `F1` na tabela de fix + nota de execução com a origem do bug |
| `docs/handoffs/20260814-dry-run-completo/30-handoff-qa.md` | Este handoff — o registro da jornada, no lugar do `docs/qa/` que não existe |
| `TODO.md` | 3 achados fora de escopo (ver seção final) |

## Boot da próxima fase

A próxima fase é **EXEC**, não REVIEW — `sdd phase 20260814-dry-run-completo` → `EXEC`,
`1 de 2 incremento(s) ainda por executar`. O runner faz isso sozinho; é o loop QA⇄EXEC.

Para o `sdd-executor` que pegar o `F1`:

- O Red **já está escrito e commitado**. Não escreva teste novo: rode `tests/check-dry-run.sh`,
  veja as 3 falhas, conserte `bin/sdd`, veja verde. É TDD com o Red herdado.
- O conserto mora em `bin/sdd:947`. A pergunta de design é *o que* o dry-run deve fazer no
  caminho `blocked`: continuar escalando com exit 3 (o sensor **exige** isso — é asserção
  explícita) porém **sem** o `pipeline_log_line`. Guardar a chamada atrás de
  `[ "$DRY_RUN" != "1" ]` é o caminho óbvio; qualquer outro que satisfaça as 4 asserções serve.
- Cuidado com o irmão: `bin/sdd:963` e `bin/sdd:1014` têm o mesmo `pipeline_log_line` de
  escalação. Verifiquei que **não** são alcançáveis em dry-run hoje, então não estão no sensor —
  mas se você refatorar para uma guarda única, melhor ainda.

Para o `sdd-qa` da próxima volta (depois que o `F1` fechar): **leia "Pendências" abaixo antes de
escolher o `status:` do handoff.** Escrever `done` sem resolver aquilo faz a QA girar até estourar
o `QA_MAX_ITER` e sair 3.

## Pendências / Decisions for a Human

> Só julgamento humano genuíno. **Não bloqueiam o pipeline** — viram seção do PR. Bug sanável não
> entra aqui: vira incremento de fix no `checkpoint.md`.

- **`gate_QA` não tem status honesto e satisfazível para projeto sem interface.** Este é o caso
  do próprio kit. `qa_substep` (`bin/sdd:444`) pula as skills donas de `docs/qa/`, então a árvore
  nunca existe; mas `gate_QA` (`bin/sdd:303`), para qualquer status que não seja `skipped`, exige
  um relatório datado em `docs/qa/reports/` marcado `closed`. Os três status disponíveis:
  `skipped` **mente** (o diff chega ao usuário e a QA achou bug real andando a jornada), `done`
  bate na Âncora 1 e reprova para sempre, `blocked` reprova por definição. A QA roda, encontra
  defeito, e mesmo assim não fecha o gate.
  **Por que é decisão humana e não `F<n>`:** mudar o que `gate_QA` aceita como evidência é
  alterar o **contrato** do kit — a mesma classe de decisão que criou a Âncora 1. Não é conserto
  mecânico e não é escopo desta missão (que é sobre a projeção do dry-run).
  Direção sugerida, registrada em `TODO.md`: quando `qa_substep` = `close` por ausência de
  interface, aceitar como Âncora 1 alternativa o próprio `30-handoff-qa.md` com `status: done` e
  `gate:` preenchido. **Onde ver:** `TODO.md` (Aberto, 1ª entrada).
  **Efeito prático nesta missão:** mesmo com o `F1` fechado e a suíte verde, a fase QA não
  fechará sozinha até isto ser decidido. Escolhi `status: blocked` por ser o único honesto hoje.

## Riscos e não-feitos

- **Commitei a suíte vermelha de propósito.** É o Red do `F1` e o mecanismo previsto (sensor
  vermelho para a linha), mas significa que qualquer gate que rode `TEST_CMD` — `gate_EXEC`,
  `gate_QA`, `gate_REVIEW` — reprova até o `F1` fechar. Se o `F1` for abandonado, a branch fica
  travada; reverter o sensor seria desligar o único instrumento que prova o defeito.
- **Não corrigi `bin/sdd`** — por regra, não por falta de diagnóstico: a causa e a linha estão
  acima e o conserto é de poucas linhas.
- **J4 (missão completa) não foi validado de verdade.** Meu fixture usou um hash inventado e
  reprovou no `gate_EXEC` por isso. Não vi bug ali, mas também **não posso afirmar** que
  `pipeline completo` imprime certo — não há asserção automatizada e minha caminhada foi
  inconclusiva. Candidato a sensor futuro.
- **Só uma jornada existe neste repo**, então a cobertura de QA aqui é estreita por natureza. Num
  repo-alvo com browser, esta fase teria charters e sessões em persona antes de mim.
- **Não medi o custo do dry-run em repo grande.** Os gates rodam `TEST_CMD` de verdade durante a
  projeção (aceito pelo plano); no kit são ~2s, no `sales_quote` pode não ser.

## Achados fora de escopo

> Registrados no `TODO.md` do `sdd_agents` (são melhorias do kit). Aqui fica só o ponteiro.

- `gate_QA` insatisfazível em projeto sem interface → `TODO.md` (Aberto) — também em "Pendências".
- `sdd install` não ignora o `pipeline.log` das missões; efêmero ou durável? → `TODO.md` (Aberto).
- A asserção "dry-run não toca no disco" é mais fraca do que parece — só vale em fixture que não
  alcança um gate que roda `TEST_CMD` → `TODO.md` (Aberto).
