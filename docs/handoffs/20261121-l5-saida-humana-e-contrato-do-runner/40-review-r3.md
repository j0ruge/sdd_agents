---
missao: 20261121-l5-saida-humana-e-contrato-do-runner
fase: REVIEW
rodada: 3
status: done
sessao: 01a216b4-2021-7153-bf83-c44fe3dfdedd
data: 2026-11-26 04:34
gate: "tests/run-all.sh em e919a145222897a75c7074cd7ff0465dc14160c3: rc 0, suite green, 21 etapas, 2486 linhas ok, 0 linhas FAIL, 1181 s. REVIEW não fecha: R5 pending e platô em Code Quality (Zen), Error Handling e Test Coverage, todos B. Na entrada, só checkpoint-notas.md com 259 inserções preexistentes, fora do commit."
reviewed_head: e919a145222897a75c7074cd7ff0465dc14160c3
---

# Review — rodada r3 — L5 — saída humana e contrato do runner

## TL;DR

O delta corrige a mudança de caminho do kit em uma só passagem. Dois defeitos confirmados viram um lote R5. Uma falha de escrita deixa a próxima tentativa sem a referência da instalação anterior e dois links locais sob a mesma raiz bastam para substituir um comando que o kit não criou. As notas da r2 não subiram. Nenhum código foi alterado.

## Nota da rodada

`codereview:codereview base=86b48881f08fde1063a7c66fcc66a79e1264866d` sobre `fix/l5-saida-humana-e-contrato-do-runner`, com base de integração `origin/main` e HEAD revisado `e919a145222897a75c7074cd7ff0465dc14160c3`. Três commits e oito caminhos no inventário do delta (+260/−25). A análise de código foi inline em `bin/sdd` e `tests/check-preflight.sh`. A verificação de prosa cobriu 22 unidades em `TODO.md`, `20-handoff-exec.md`, `checkpoint.md` e `docs/plan-only.md`; a r2 serviu de histórico. A primeira coleta automática de unidades incluiu o blob commitado das notas e emitiu intervalos e identificadores que já estavam no boot. Corrigi o filtro e a coleta usada pelo verificador excluiu esse caminho. O arquivo de trabalho das notas não foi aberto para leitura. O [handoff da QA](30-handoff-qa.md) já confirma instalação inicial, idempotência, recusa de opção, alocação e fechamento, mas não migração interrompida nem links locais com uma raiz comum.

### Detecção de credenciais

| Estado | Ocorrências | Evidência |
|---|---|---|
| PASS | 0 | Regex e Gitleaks, sem erros, em sete arquivos e 246 linhas adicionadas. O caminho das notas foi excluído do diff enviado à varredura. |

### Qualidade, tipos, erros e impacto

A captura de `readlink` preserva quebras de linha finais com sentinela, passa argumentos entre aspas e exige consulta bem-sucedida ao índice antes de considerar o link não rastreado. O problema é a origem inferida: o mesmo link do planner que serve de testemunha é substituído antes de terminar a etapa de comandos, e a correspondência lexical não demonstra quem criou a dupla local. Os dois casos ocorreram em chamadas sequenciais, sem concorrência, sem rede e sem destruir o conteúdo original do arquivo local. O delta acrescenta comandos locais de leitura por destino existente, sem nova varredura de árvore. Não houve benchmark de produção.

### Cobertura de testes

| Superfície | Evidência | O que falta medir |
|---|---|---|
| `bin/sdd` → `tests/check-preflight.sh` | Check R4 → `1 1 1` na suíte desta rodada. O fixture independente também confirmou `rc 0` e os dois links no kit novo na migração direta. | Repetição após falha de escrita e preservação de um comando local sob a mesma raiz de um planner local. |
| Os controles novos de `tests/check-preflight.sh` | Os probes comparam destino, leitura e índice, não só mensagens. Os retestes do R4 distinguem link local com LF final, link rastreado com o destino esperado e par de links relativos. | Os casos confirmados abaixo não são variantes desses controles. |

`tests/run-all.sh` em `e919a145222897a75c7074cd7ff0465dc14160c3` → rc 0, suite green, 21 etapas, 2486 linhas ok, 0 linhas FAIL, 1181 s. Log em `/tmp/sdd-l5-review-r3.VTdOwc/suite.log` e status em `/tmp/sdd-l5-review-r3.VTdOwc/suite.rc`. Não houve app, PR ou JIRA reais e o catálogo integral de mutação não foi executado.

### Sincronismo da documentação

O [guia PLAN-only](../../plan-only.md#why-the-agents-are-symlinks) dá a condição correta para a migração em uma passagem, mas a recomendação de rodar de novo perde a referência necessária após a primeira falha. O [handoff do EXEC](20-handoff-exec.md) já cita uma tentativa anterior como limite. O fixture mostra que o próprio binário revisado produz esse estado. O guia e o handoff também apresentam a preservação de links locais sem distinguir o caso da raiz coincidente. É o efeito dos achados de código abaixo, sem incremento de prosa separado.

### Código morto e limpeza

A varredura inline do delta não encontrou função ou variável nova sem uso, nem referência órfã. `previous_planner` e `indexed` alimentam a guarda e os dois novos helpers do sensor são chamados pelo fixture. A revisão não usou indexador nem procurou código morto preexistente. Um `git grep -n -F` pelo sufixo antigo do aviso, `(differs from the kit)`, encontrou apenas o controle que exige sua ausência em `tests/check-preflight.sh:3147`.

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | B | O instalador ainda mistura evidência de origem com estado mutável e classifica incorretamente um comando local e dois links gerados pelo kit em casos reproduzidos. |
| Type Safety | A | Os destinos são comparados como strings integrais, com sentinela para preservar LF final, e o resultado da consulta ao índice só é aceito quando ela tem sucesso. |
| Error Handling | B | Uma falha de escrita pode apagar a evidência necessária para a próxima tentativa, que retorna sucesso com o plano indisponível. |
| Security | A | Nenhuma credencial nova foi detectada. A substituição local indevida é uma regressão de integridade no alvo, sem escrita no destino do link no cenário medido. |
| Performance | A | As leituras adicionais são locais e limitadas aos links existentes dos comandos do kit, sem chamada remota ou varredura nova. |
| Test Coverage | B | As migrações limpas e a preservação nos cenários cobertos passam, mas o sensor ainda não mede a tentativa interrompida nem o par local com raiz comum. |
| Documentation | B | O guia orienta repetir a instalação sem explicar o limite de retomada que o binário pode criar e não distingue o par local com raiz comum. |
| **Overall** | **B** | O conserto b23f936 avançou na migração direta, mas os dois casos residuais mantêm os critérios da r2 no mesmo patamar. |

## Achados da rodada

| # | Severidade | Achado | Onde |
|---|---|---|---|
| 1 | MEDIUM | Uma falha de escrita na migração torna a nova tentativa incapaz de restaurar links gerados pelo kit, mesmo após remover a causa da falha. | `bin/sdd:13530`, `bin/sdd:13545` |
| 2 | MEDIUM | Duas referências locais não rastreadas com a mesma raiz são confundidas com uma instalação do kit. O comando local, com conteúdo diferente, é substituído sem aviso. | `bin/sdd:13543`, `bin/sdd:13546` |

**Reprodução dos dois casos.** `bash /tmp/sdd-l5-review-r3.VTdOwc/check-link-boundaries.sh` → rc 0 com todas as asserções de diagnóstico. A base `86b48881f08fde1063a7c66fcc66a79e1264866d` e o HEAD revisado forneceram os dois binários. O fixture criou repositórios descartáveis, sem afetar um alvo real.

1. A CLI da base ligou planner, plan e worker em dois alvos e a instalação antiga foi movida. No controle direto, a CLI revisada retornou 0, ligou ambos os comandos à instalação nova e o plano ficou legível. No segundo alvo, `chmod a-w .claude/commands` fez `ln` falhar com `Permission denied` e rc 1. O planner já apontava para o kit novo, mas os comandos ainda apontavam para o antigo. Restaurada a escrita, o segundo `link-agents` deu rc 0, avisou que preservava os dois comandos e imprimiu `Next: $ /sdd-plan` com o plano ainda quebrado. Não é preciso repetir o defeito da primeira versão do R4: a tentativa parcial deste binário já basta.
2. Em dois alvos limpos sem regra de instalação no `.gitignore`, liguei manualmente `sdd-planner.md` e `sdd-plan.md` a `local/agents/` e `local/commands/` da mesma árvore, que não era um kit. Confirmei o índice vazio para o comando e que seu conteúdo local diferia do kit. A base preservou o destino e avisou com rc 0. O HEAD trocou o destino para o kit ativo, sem o aviso de preservação e com rc 0. O arquivo local continuou no disco, mas deixou de ser o comando que a CLI expõe.

## Incrementos de conserto (R<n>)

| R<n> | Achado | Check escrito no checkpoint |
|---|---|---|
| R5 | Achados 1 e 2 da r3 — retomar a migração de links sem substituir comandos locais | `p=$(bash tests/check-preflight.sh 2>&1); echo "$(grep -c '^  ok    link-agents retries a kit relocation after a failed command symlink update$' <<< "$p") $(grep -c '^  ok    link-agents preserves a local command symlink that shares a root with a local planner$' <<< "$p")"` → `1 1` |

## O que virou incremento

Linha exata acrescentada ao [checkpoint](checkpoint.md):

| R5 | Achados 1 e 2 da r3 — retomar a migração de links sem substituir comandos locais | `p=$(bash tests/check-preflight.sh 2>&1); echo "$(grep -c '^  ok    link-agents retries a kit relocation after a failed command symlink update$' <<< "$p") $(grep -c '^  ok    link-agents preserves a local command symlink that shares a root with a local planner$' <<< "$p")"` → `1 1` | pending | — |

- R5 agrupa os dois achados porque ambos exigem distinguir um link gerado pelo kit de um link local e manter essa distinção durante a migração. No primeiro probe, armar e conferir a falha inicial antes de restaurar a escrita e exigir os destinos novos e o plano legível na retomada. No segundo, exigir que o destino e o conteúdo locais permaneçam, sem alterar o índice, e que a saída nomeie a preservação. Manter verdes os controles de migração direta, link rastreado, link relativo e rascunhos do R1/R4. O Check novo imprime `0 0` com o sensor atual, e o vermelho funcional já foi observado no fixture independente.
- R4, achado 1 da r2, foi fechado pelo EXEC em `b23f936` para as duas instalações em uma passagem. A suíte desta rodada mediu `1 1 1` no Check gravado e o fixture independente confirmou a mudança direta. Os novos cenários explicam por que o fechamento de R4 não basta para liberar a revisão.

## O que foi refutado

- **Resultado da suíte anterior sem evidência.** O verificador só tinha a QA original como fonte de saída. O log do EXEC `/tmp/sdd-r4-green.3Fep4R` contém 21 etapas, 2486 linhas `ok`, zero `FAIL` e o encerramento `suite green`. A suíte desta rodada foi executada separadamente e seu resultado está no gate acima.
- **O Check do checkpoint dependeria da afirmação do EXEC.** A célula é um comando com um resultado esperado. Contar as três frases ancoradas no log `/tmp/sdd-r4-red.kZrlBf` dá `0 0 1`; no log `/tmp/sdd-r4-green.3Fep4R`, dá `1 1 1`. A rodada mediu novamente `1 1 1` no HEAD. Não se exige anexar um log histórico ao checkpoint para tornar o Check executável.
- **Os onze mutantes teriam sido apenas declarados.** `/tmp/sdd-r4-sabotage-results.6Aixdg` contém 11 linhas de mutante com rc 1 e falha nomeada, mais controles/restaurações com rc 0 e sete probes. A duração e o teto de memória não são comprovados por esse resumo. Não foram usados para a nota desta rodada.
- **A guarda aceitaria qualquer destino com conteúdo igual ou removeria um link rastreado do kit anterior.** Os controles do sensor mantêm o link local com LF no destino e bytes idênticos, o link relativo e o link rastreado com a entrada do índice intacta. O achado 2 é mais estreito: o par local é absoluto, não rastreado e passa pela igualdade de raiz.

## Achados fora de escopo

Nenhum achado novo para o [backlog](../../../TODO.md). Permanecem lá, sem nova ocorrência medida nesta rodada, o fallback do Git antigo com LF no caminho de worktree, a reserva concorrente de ADR e a lacuna de prosa na ajuda do fechamento.

## Pendências / Decisions for a Human

O gate da rodada não fecha. As letras são as mesmas da r2, inclusive em Code Quality (Zen), Error Handling e Test Coverage. Há avanço funcional comprovado em `b23f936`, mas o platô da nota pede decisão humana sobre nova rodada após o R5. O incremento está registrado para o EXEC e esta revisão não o implementa. As demais pendências de [00-missao.md](00-missao.md#pendências-para-o-humano) seguem iguais.

## Boot da próxima fase

Se o fluxo seguir para EXEC, começar pelo R5 do [checkpoint](checkpoint.md) e pelas duas reproduções acima. Criar o vermelho em `tests/check-preflight.sh` antes de modificar o instalador e preservar o resultado de R1/R4. Para nova REVIEW, a base delta é o `reviewed_head` deste relatório. Na entrada só `checkpoint-notas.md` estava modificado, com 259 inserções preexistentes que ficaram fora do commit. Foi acrescentada apenas a nota desta rodada.

### Ações recomendadas

- **CRITICAL** — nenhuma.
- **HIGH** — nenhuma.
- **MEDIUM/LOW** — fechar R5 mantendo a recuperação de links reconhecíveis após falha parcial e a preservação de comandos locais.
- **Prosa** — nenhuma correção independente dos achados funcionais. A lacuna conhecida da ajuda já está no backlog.
- **Fora de escopo** — nenhum caso novo cortado pelo verificador.

_Pegada de custo — codereview 2.30.2 instalada, comparada com a 2.27.38 pedida no boot. Dois arquivos de código analisados por região, sem agente por arquivo, varredura de código morto inline e um verificador gpt-6.1-terra (22 unidades, 35 chamadas reportadas). Sem custo monetário medido._
