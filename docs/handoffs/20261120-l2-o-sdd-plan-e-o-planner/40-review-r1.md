---
missao: 20261120-l2-o-sdd-plan-e-o-planner
fase: REVIEW
rodada: 1
status: done
sessao: 58311357-d02e-44d1-8bb6-b6f84d94a078
data: 2026-11-20 21:57
gate: tests/run-all.sh rc 0 (2231 ok, 0 FAIL, suite green) no head 2fc48ac; secrets pre-scan com regex e gitleaks, 0 achados; a rodada escreve só o 40-review-r1.md, o checkpoint, as notas, o TODO.md e a catraca
reviewed_head: 2fc48acce1fd53da89c9bec0d3c3568d07b39d3c
---

# Review — rodada r1 — L2: o `/sdd-plan` e o planner

## TL;DR

Rodada inteira sobre `079bc39...2fc48ac`: 20 arquivos, dos quais 6 de sensor (`tests/`) e 4 de prosa
do kit. Foram 3 revisores por arquivo (sonnet) mais a leitura cruzada. Saíram 7 achados LOW e nenhum
MEDIUM ou pior. Um deles foi reproduzido como fail-open do `--red --only`: uma lista de ids com quebra
de linha roda 0 Checks e sai 0 com `ok`. Esse vira o R1. Dois de prosa foram para o `TODO.md`, e quatro
foram refutados ou deixados de fora com o motivo escrito. A suíte está verde, e as métricas 1, 3 e 4 da
missão foram conferidas.

## Nota da rodada

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | A | A gramática do --red mora numa função só (red_args), o probe_on é irmão do probe e os pisos subiram com os probes contados (412 → 443, 9 → 10). |
| Type Safety | A | Não se aplica a bash; nada de novo sem guarda de `set -u`, e as listas usam a forma guardada de expansão. |
| Error Handling | B | O --red --only valida só a primeira linha da lista de ids e roda a lista inteira: uma lista com quebra de linha mede 0 Checks e sai 0 com o prefixo ok (reproduzido, vira o R1). |
| Security | A | O pre-scan de segredos (regex e gitleaks) não achou nada, e o READ_EXTRA novo é só leitura, sobre o diretório do plugin codereview. |
| Performance | A | Só sensores e prosa; a limpeza de EFFORT_* por compgen custa um laço sobre poucas variáveis. |
| Test Coverage | A | São 19 asserções novas verdes, 31 probes novos no selftest e 21 de 21 sabotagens mortas no I5. A lista com espaço em branco é a lacuna do R1. |
| Documentation | B | O fallback do pgrep no passo 1 do /sdd-plan casa a corrida de qualquer repo, e o plan-only.md promete uma ordem do gate_EXEC que não é a do bin/sdd; os dois foram para o TODO.md. |
| **Overall** | **B** | A suíte está verde e as métricas da missão batem. Sobra um fail-open barato num sensor (R1), mais duas imprecisões de prosa registradas no backlog. |

## Achados da rodada

| # | Severidade | Achado | Onde |
|---|---|---|---|
| 1 | LOW | `--red --only $'I1\nI2'`: o `IFS=, read -ra` valida só `I1`, e o laço de execução casa contra `",$ids,"` inteiro, então k = 0. A saída é `ok … 0 of 2 pending Check(s) run … a partial measure`, rc 0: um verde vazio vindo do sensor que existe para medir vermelho. Reproduzido numa cópia em `mktemp -d`. | `tests/check-checkpoint.sh:1661` (`red_one`), `:1747` (`red_args`) |
| 2 | LOW | Sem pasta de missão, o passo 1 cai no `pgrep -af '[b]in/sdd run'`, que casa todo `sdd run` da máquina. Já a saída fala de "a live `sdd run` of this repository". Falha para o lado seguro: corta um worktree a mais. | `commands/sdd-plan.md:31` |
| 3 | LOW | O `docs/plan-only.md` diz "reads, in this order" e junta num item duas checagens que o `gate_EXEC` roda em pontos diferentes (o hash de cada `done` e a recusa de `pending`). Também põe o `blocked` depois delas. | `docs/plan-only.md:98` |
| 4 | LOW | "A question asked twice is one question" pressupõe que o humano já respondeu; não diz o que fazer com a repetição que chega com a primeira pergunta ainda aberta. | `commands/sdd-plan.md:197` |
| 5 | LOW | A contagem das marcas de resposta compara o `M` com as respostas entregues, número que um relay retomado não carrega; não diz se a resposta delegada conta. | `commands/sdd-plan.md:204` |
| 6 | LOW | A asserção `comando que mediu` de `check-templates.sh` procura a frase no arquivo inteiro, não na seção do contexto verificado. | `tests/check-templates.sh:489` |
| 7 | LOW | O `agents/sdd-planner.md:164` e o `docs/pipeline.md:178` descrevem o `--red <checkpoint>` sem os modos `--list` e `--only`. | `agents/sdd-planner.md:164` |

Pontos que a QA deixou para o revisor:

- O Check do I6 responde `15`, e a célula diz `14`. O 15º é o `RESOLVED by d48f7c9` que o I7 acrescentou, e a nota do I7 já diz isso. O gate não re-roda o Check de linha `done`, e o `df7b55e` fechou os 14 que o I6 prometia. Conferi por `git diff 079bc39...HEAD -- TODO.md`: são 15 `RESOLVED by`, 14 com os hashes do I1 ao I5 e 1 com o do I7, todos ancestrais do `HEAD`. Aceito como está.
- O `bin/sdd` e o `bin/sdd-worker` não mudaram, e o `.sdd/config.sh` só ganhou o `EFFORT_EXEC` vindo do ambiente e o `READ_EXTRA` da skill `codereview`.

## Incrementos de conserto (R<n>)

| R<n> | Achado | Check escrito no checkpoint |
|---|---|---|
| R1 | achado #1 da r1 | `bash tests/check-checkpoint.sh --red docs/handoffs/20261120-l2-o-sdd-plan-e-o-planner/checkpoint.md --only $'R1\nR1' >/dev/null 2>&1; echo $?` → `96` |

Hoje o Check responde `0`, medido neste head com a linha R1 já `pending`.

## O que virou incremento

- Achado #1: virou o `R1`, um só e não um lote, porque é o único achado com conserto em código desta rodada. Para fechar, a lista de ids com espaço em branco ou quebra de linha tem de ser recusada pelo `red_args` com rc 96 antes de qualquer Check rodar, e o selftest precisa de um probe que fique vermelho sem a recusa. O piso `PROBE_FLOOR` sobe junto.

## O que foi refutado

- Achado #6: a forma do achado é real, mas não é defeito desta missão. Toda chamada `check plano.md '<frase>'` do `check-templates.sh` lê o arquivo inteiro: é a régua do sensor desde antes da missão, e as duas linhas novas seguem a mesma régua. Escopar por seção seria mudar o sensor inteiro, e não há fail-open, porque a asserção afirma "o template diz a frase" e mede isso.
- Achado #7: nada no diff torna falso o texto antigo. O `--red <checkpoint>` sem modo continua sendo o modo inteiro (`red_args`, `case "$#" in 1|2`), e quem lê o `--list`/`--only` é o aceite do `/sdd-plan`, que os documenta na `:271`. Não é deriva.
- Achados #4 e #5: deixados fora do backlog pela régua D15. Não são fail-open, e não há consumidor medido que tenha caído neles. O #4 junta dois eventos raros: o job do planner tem de terminar com a pergunta ainda aberta no relay, e o relay segura a pergunta aberta de qualquer forma. No #5, o relay retomado relê as marcas do `00-missao.md` no primeiro hand-back. Se um dos dois voltar medido, entra no `TODO.md`.

## Achados fora de escopo

- Achado #2: registrado no `TODO.md` como "Sem pasta de missão, o passo 1 do `/sdd-plan` lê corrida de qualquer repo como dona do checkout" (2026-11-20).
- Achado #3: registrado no `TODO.md` como "O `docs/plan-only.md` diz a ordem do `gate_EXEC` e a lista não segue a ordem do gate" (2026-11-20).
- A catraca `tests/health-baseline.txt` foi de 103 para 105. Conferi com `tests/check-todo.sh --check TODO.md` (105 itens, rc 0) e com `--anchors` (0 fora do alvo).

## Pendências / Decisions for a Human

Nenhuma.
