---
missao: 20261121-l5-saida-humana-e-contrato-do-runner
fase: REVIEW
rodada: 10
status: done
sessao: 01a219a8-2253-7273-b253-27073799cb0a
data: 2026-11-26 19:18
gate: "PHASE_ENGINE=codex /home/joruge/repos/sdd_agents/bin/sdd preflight no worktree L5 em aa2443f6ac2688ab126d5cbf8826588d29a83f00 deu rc 0, TEST_CMD ran green (tests/run-all.sh) e preflight ok. A suíte registrou 2.501 linhas ok, zero FAIL, suite green e R3 1 1 1 1. Árvore limpa. Log do TEST_CMD em .sdd/logs/_geral/preflight-test-20261126-190142-WLGP3O.log."
reviewed_head: aa2443f6ac2688ab126d5cbf8826588d29a83f00
---

# Review — rodada r10 — L5 — saída humana e contrato do runner

## TL;DR

A R10 cobre o hash SHA-256 completo, a exclusão de exemplos de código na leitura
de resoluções, a recuperação de QA com o comando completo, os avisos de commit
na base e a prova de squash após buscar o head. Os contraexemplos do leitor
foram reexecutados em `aa2e13b` e tiveram a saída esperada. O commit `aa2443f`
alinha também o guia de recuperação de QA. O preflight Codex passou em `aa2443f` com
2.501 linhas `ok` e zero `FAIL`. Os oito critérios ficaram em A.

## Nota da rodada

**Escopo.** `sdd review-base 20261121-l5-saida-humana-e-contrato-do-runner` devolveu
`base=a5260b9fb9d9b0626ace109ef4d43c1a512a179c`, SHA revisado na [R9](40-review-r9.md).
O delta integral até `aa2443f6ac2688ab126d5cbf8826588d29a83f00` tem dez caminhos,
252 adições e 49 exclusões. `a5260b9..99bc093` registra somente `40-review-r9.md` e
`50-pr.md`. `99bc093..542ef33` corrige a leitura de SHA-256. `542ef33..aa2443f`
tem oito caminhos (+125 / −44), incluindo o runner, os sensores e os guias.
`git diff --check` passou no intervalo integral. A árvore estava limpa no SHA revisado.

### Segredos

| Estado | Ferramentas | Arquivos | Linhas adicionadas | Achados | Erros |
|---|---|---|---|---|---|
| PASS | regex, gitleaks | 10 | 252 | 0 | 0 |

Pré-varredura de `git -P diff a5260b9fb9d9b0626ace109ef4d43c1a512a179c aa2443f6ac2688ab126d5cbf8826588d29a83f00 --unified=0`.

### Cobertura e integridade

| Superfície | Resultado |
|---|---|
| SHA-256 | A evidência focada de `542ef33` cobre 40 e 64 dígitos válidos e 65 rejeitados, inclusive em item com outro hash válido. A jornada em Git `--object-format=sha256` confirmou a listagem de 64 dígitos com `in main`. O leitor em `aa2e13b` conserva o limite 7–64 e `close_list_resolved` continua exigindo objeto `commit` único e ancestralidade. |
| Blocos Markdown | Em `a4aeb04`, o leitor ainda emitia um hash dentro de código indentado logo após uma cerca, juntava `RESOLVED by` e o hash separados por uma cerca e aceitava um item em H2 sem marcador cujo primeiro conteúdo era uma cerca. A saída em `aa2e13b` é vazia nos três casos. A fixture mantém os casos positivos de prova real após código e prova real após cerca. O selftest no código equivalente de `aa2e13b` teve 267 probes verdes. |
| Jornada do fechamento no SHA revisado | Em um repo Git SHA-256 descartável, o log de `sdd close 20261126-sha256` em `aa2443f` tem uma única resolução, `TODO.md:9` com o SHA-256 completo e a prova `in main`. A fixture tem exemplos de preâmbulo em cerca, seção sem marcador, código indentado logo após cerca e prova partida por um bloco. O fechamento preservou a árvore. Evidência em `/var/tmp/sdd-l5-final-close.0AoLJQ/close.log`. |
| QA | `sdd status` agora dá `sdd status <missão>` depois de sugerir o restabelecimento do app. A asserção compara o comando completo. O controle anterior falhou nessa asserção. O guia de falhas inclui o argumento da missão nas duas rotas. |
| Aviso de base | O `run` derivado e sem override omite o aviso enquanto TICKET ainda vai criar a branch. `retry`, TICKET forçada e override o conservam, pois a nota de intervenção pode ser gravada enquanto o checkout ainda está na base. A asserção que o checkpoint R3 lê preservou o título exato, e TICKET forçada e override têm oráculos próprios. |
| Prova em clone fresco | O cenário descartável confirmou que `git fetch origin refs/pull/17/head` materializa o head e que `FETCH_HEAD` coincide com a referência do PR. O guia verifica o mesmo head antes de testar a ancestralidade e deixa a criação da branch do chore para depois do último `sdd close`. |
| Sintaxe e escopo | `bash -n` passou em `bin/sdd`, `tests/check-todo.sh`, `tests/check-gates.sh` e `tests/check-mutation.sh`. Os alvos dos mutantes de aviso acompanham as linhas alteradas. O sensor do checkpoint aceitou 26 linhas e 25 checks sob a regra de âncora, todos medidos. |
| Suíte do SHA revisado | `PHASE_ENGINE=codex /home/joruge/repos/sdd_agents/bin/sdd preflight` no worktree L5 em `aa2443f` deu rc 0, `TEST_CMD ran green (tests/run-all.sh)` e `preflight ok`. O log da suíte tem 2.501 linhas `ok`, zero `FAIL`, `suite green`, 267 probes do TODO e os quatro marcadores de R3 em `1 1 1 1`. Os 100 achados têm todas as âncoras no alvo, as 1.017 âncoras de mutação são válidas e os 26 ADRs foram aceitos. A árvore estava limpa ao término. |

### Código morto

`leading_columns` e `fence_delimiter` têm chamadores no parser. As mudanças nos
testes permanecem nos sensores existentes. A varredura do delta não encontrou órfãos.

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | A | O leitor mantém a precedência do marcador de um H2 real e a separação entre parágrafos ao pular cercas e código indentado. |
| Type Safety | A | O intervalo 7–64 do leitor combina com a exigência de um objeto Git `commit` único no consumidor. |
| Error Handling | A | Os três falsos positivos reproduzidos em `a4aeb04` deixam de emitir prova em `aa2e13b`. O operador recebe os avisos de base e o comando completo de recuperação. |
| Security | A | Regex e gitleaks passaram no delta. A decisão de fechamento continua baseada em objeto e ancestralidade. |
| Performance | A | O leitor preserva o separador acumulado uma vez por bloco e limita a contagem de colunas ao prefixo da linha. O teste de linhas vazias da R8 permanece. |
| Test Coverage | A | Os retestes focados cobrem os cenários positivos e negativos. O `TEST_CMD` no sandbox Codex deu 2.501 linhas `ok`, zero `FAIL` e R3 `1 1 1 1` em `aa2443f`. |
| Documentation | A | O pipeline e o Kaizen refletem o aviso na base, a recuperação de QA tem a missão nos comandos e o guia de squash preserva a ordem do chore. |
| **Overall** | **A** | Os achados do delta foram corrigidos e o preflight Codex passou no SHA revisado. |

## Achados da rodada

- **P2 `#4713470829`, corrigido em `542ef33`**. O leitor descartava o hash SHA-256 completo antes de chegar à prova de ancestralidade.
- **Parser e documentação, corrigidos em `80fed08`**. Os três contraexemplos envolvendo cercas e código indentado foram reproduzidos e passaram na fixture final. O guia agora lista as provas antes de criar a branch do chore e o pipeline descreve os avisos na base.
- **Oráculo e registro do Kaizen, corrigidos em `aa2e13b`**. O título do teste de EXEC forçado voltou a coincidir com o checkpoint R3. O Kaizen registra a exceção do `run` sem intervenção e o aviso nos casos que podem escrever a nota.

- **Guia de recuperação, corrigido em `aa2443f`**. O guia de falhas usa o argumento da missão em `sdd status` e `sdd run`.

## Incrementos de conserto (R<n>)

Os consertos desta revisão estão em `542ef33`, `a4aeb04`, `80fed08`, `aa2e13b` e `aa2443f`.

## Pendências / Decisions for a Human

A atualização do `verified_head` e o recibo Codex no head publicado são as próximas etapas da publicação.

## Boot da próxima fase

Com o preflight Codex verde, gravar o `verified_head` revisado em `50-pr.md` e publicar esta
rodada. Os commits posteriores ao SHA revisado devem ficar na pasta da missão para
preservar o vínculo entre a revisão e o head. O merge depende do recibo Codex no head
publicado, dos threads resolvidos e do `pr-ready`.

### Ações recomendadas

- **Must Fix (CRITICAL)** — nenhuma.
- **Should Fix (HIGH)** — nenhum achado de código em aberto.
- **Consider Fixing (MEDIUM/LOW)** — as correções da rodada estão descritas acima.

_Pegada de custo — codereview 2.27.38, revisão incremental Sol xhigh e varredura inline.
Custo monetário não aferido._
