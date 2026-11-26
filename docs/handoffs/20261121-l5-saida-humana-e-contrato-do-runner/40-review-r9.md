---
missao: 20261121-l5-saida-humana-e-contrato-do-runner
fase: REVIEW
rodada: 9
status: done
sessao: 01a219a8-2253-7273-b253-27073799cb0a
data: 2026-11-26 18:17
gate: "PHASE_ENGINE=codex /home/joruge/repos/sdd_agents/bin/sdd preflight no worktree L5 em a5260b9fb9d9b0626ace109ef4d43c1a512a179c deu rc 0, TEST_CMD ran green (tests/run-all.sh) e preflight ok. A suíte registrou 2.498 linhas ok, zero FAIL e suite green. Árvore limpa. Log do TEST_CMD: .sdd/logs/_geral/preflight-test-20261126-180245-cl1VNs.log."
reviewed_head: a5260b9fb9d9b0626ace109ef4d43c1a512a179c
---

# Review — rodada r9 — L5 — saída humana e contrato do runner

## TL;DR

A revisão integral não encontrou regressão nova em `a5260b9`. Dois desvios de prosa
foram corrigidos nesse SHA. Os dois arquivos de convenção contêm os textos aceitos
pelo mantenedor. O checklist de DOCS está fechado e o K8 tem uma entrada própria.
O preflight no sandbox Codex passou no SHA revisado. Os oito critérios ficaram em A.

## Nota da rodada

**Escopo.** `git -P diff b75951e0e34d1376d565885ab0651e5b04aef350 a5260b9fb9d9b0626ace109ef4d43c1a512a179c`
contra `main`, base ancestral e segundo pai do merge `0eb53bc`. `sdd review-base` pediu
`full` porque o merge veio depois da R8. O diff tem 61 caminhos (+5.433 / −300), sendo
13 scripts Bash, 47 Markdown e a catraca. Os 17 caminhos que mudaram após `178bf75`
foram lidos no delta, incluindo os quatro ajustes de linha em `a5260b9`. O range
`178bf75..a5260b9` é vazio em `bin/`, `tests/`, `agents/`, `.claude/agents/` e `templates/`.
O merge não acrescentou resolução própria (`git show --remerge-diff 0eb53bc`). A evidência
da R8 foi reaproveitada somente onde os arquivos ficaram idênticos. O novo
`KAIZEN_LOG.md`, as convenções e os handoffs posteriores foram avaliados no SHA atual.

### Segredos

| Estado | Ferramentas | Arquivos | Linhas adicionadas | Achados | Erros |
|---|---|---|---|---|---|
| PASS | regex, gitleaks | 61 | 5.433 | 0 | 0 |

`git -P diff b75951e0e34d1376d565885ab0651e5b04aef350 a5260b9fb9d9b0626ace109ef4d43c1a512a179c --unified=0`
na entrada de `scan_secrets.sh` da skill `codereview`. `git diff --check` no mesmo
intervalo e `git --no-optional-locks status --porcelain=v1` não produziram saída.

### Cobertura, integridade e documentação

| Superfície | Resultado |
|---|---|
| CLI Bash e sensores | `bash -n` aceitou `bin/sdd`, `bin/sdd-link-agents`, `bin/sdd-worker` e os 10 sensores Bash alterados. A inspeção cruzou os ramos de ADR, instalação/link, status, aviso da base, Kaizen e fechamento com os respectivos sensores. |
| Suíte do SHA revisado | `PHASE_ENGINE=codex /home/joruge/repos/sdd_agents/bin/sdd preflight` no worktree L5, `a5260b9`, rc 0, `TEST_CMD ran green (tests/run-all.sh)` e `preflight ok`. No log do TEST_CMD, 2.498 linhas `ok`, zero `FAIL` e marcador final `suite green`. O backlog tem 100 achados com todas as âncoras no alvo. A checagem de âncoras passou nos 1.017 mutantes aplicáveis, todos deixando código válido. ADR: 26, sem achado no preflight. Árvore limpa após a execução. |
| Evidência histórica | A [R8](40-review-r8.md) registrou 21 etapas, 2.498 linhas `ok`, zero `FAIL` e suíte verde em `178bf75`, com R8 `1 1`, R7 `1 1` e R6 `1 1 1`. A [QA](30-handoff-qa.md) registra as 46 asserções do plano e os 28 mutantes selecionados. Não é um novo catálogo completo. |
| Checkpoint e backlog | Conferidos 26 de 26 `done`. Os 17 títulos do Gemba aparecem individualmente no TODO com os hashes de I1–I17, todos ancestrais de `04376a7`. A checagem não usa a contagem global do I18. |
| Gate de DOCS | `45-docs.md` está commitado e tem 20 estados, 18 `✅` e 2 `n/a` justificados, sem `⛔` ou pendências. O K8 está ativo e o diff de `KAIZEN_LOG.md` tem cabeçalho novo mais a citação exata da missão no bloco novo tanto contra `main` (`60ec571`) quanto contra `origin/main` (`b75951e`). |
| Texto de política | Os quatro blocos transcritos no [45-docs](45-docs.md#texto-proposto-para-o-dono) coincidem literalmente com o texto dos dois arquivos em `4110b42`, aplicado após o aceite. A regra exige ancestralidade em cada hash. A segunda prova também exige estado `MERGED` para o mesmo head, não só o rótulo do PR. O `sdd close` limita essa prova ao PR da missão e ao head disponível localmente. |
| Registro de custo | O log EXEC confirma 27 sessões e 63.467 s, todas Codex `medium` com custo `?`, uma com rc 124. Os quocientes arredondados são 2.351 s por sessão e 3.733 s por item. A série não mede cobrança e não permite isolar a influência de effort. |

### Código morto

Varredura do que entrou no PR, sem varrer o estoque anterior. As novas funções de leitura
da semente, aviso da base, alocação de ADR e fechamento e as novas asserções têm
chamadores no diff. O delta posterior à R8 não altera funções nem sensores. Nenhum
órfão novo confirmado.

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | A | A segunda prova reutiliza o leitor de TODO e o fechamento apenas lista. Novos auxiliares e sensores têm chamadores. |
| Type Safety | A | Contratos de Bash, identificadores, hashes e status mantêm validação positiva nos caminhos revistos. |
| Error Handling | A | Provas inválidas ou sem objeto não autorizam listagem. Nos caminhos medidos, recusa e próximo passo têm saídas distintas. |
| Security | A | Pré-varredura exata com regex e gitleaks sem achados ou erros. Nenhuma ampliação de escrita em runtime decorrente do aceite de política. |
| Performance | A | Leitor e CLI equivalentes ao código medido no R8. O caso de um milhão de linhas vazias levou 0,53 s e 0,74 s, respectivamente, na reprodução registrada pela R7. |
| Test Coverage | A | O `TEST_CMD` passou no sandbox Codex em `a5260b9` com 2.498 linhas `ok` e zero `FAIL`. A checagem de 1.017 âncoras é distinta da evidência histórica dos 28 mutantes selecionados. |
| Documentation | A | O guia, as convenções aceitas, o checklist e o Kaizen descrevem as mesmas provas e limites. |
| **Overall** | **A** | As duas inconsistências de prosa fecharam em `a5260b9`. O preflight Codex passou nesse SHA e não ficou achado bloqueante no conteúdo revisado. |

## Achados da rodada

- **LOW, prosa pós-aceite, corrigido em `a5260b9`** — `KAIZEN_LOG.md:43–47` dizia que os
  dois textos ainda ficariam para o dono e `45-docs.md:53–55` mandava carregá-los como
  propostas. Ambos agora registram o aceite e a aplicação em `4110b42`.
- **Integridade do PR, etapa de publicação** — `50-pr.md` ainda guarda o `verified_head`
  histórico `ed5bb47`. As mudanças externas seguintes pertencem à revisão integral e
  exigem o novo selo de publicação. `gate_PR` rejeita o selo antigo em um PR aberto
  ao detectar arquivos fora da pasta (`bin/sdd:2962–3000`). Essa atualização já integra
  a rota PR e deve apontar para o SHA que o preflight efetivamente verificou.

## Incrementos de conserto (R<n>)

Nenhum. A correção foi só de prosa e não muda os 26 incrementos fechados.

## Achados fora de escopo

Sem novo item. Continuam declarados os limites da reserva simultânea de ADR entre
worktrees, da prova por head local e da limpeza do backlog em chore pós-merge.
Como limite não bloqueante, `tests/check-todo.sh:542` aceita 7 a 40 dígitos hexadecimais.
Um hash SHA-256 completo de 64 dígitos não entra na listagem automática, embora a prova
manual por ancestralidade continue válida. Não afeta o fluxo SHA-1 deste PR e não
remove item algum.

## Pendências / Decisions for a Human

Não há decisão nova nesta rodada. A segunda prova e os textos reservados foram aceitos.
O novo selo de publicação e o recibo Codex no head publicado ainda são etapas operacionais.

## Boot da próxima fase

Com o preflight Codex verde no SHA acima, grave o `verified_head` em `50-pr.md`.
O commit com o registro e esta rodada deve tocar apenas a pasta da missão para conservar
a validade da prova. No head publicado, o worker ainda exige o recibo do Codex, threads
resolvidos e os demais itens de `pr-ready` imediatamente antes do merge.

### Ações recomendadas

- **Must Fix (CRITICAL)** — nenhuma.
- **Should Fix (HIGH)** — nenhum achado de código. Resselar a publicação após o preflight.
- **Consider Fixing (MEDIUM/LOW)** — os desvios de prosa já foram corrigidos em `a5260b9`.

_Pegada de custo — codereview local 2.27.38, revisão estática Sol xhigh, varredura inline
do delta integral e sem agentes filhos. Custo monetário não aferido._
