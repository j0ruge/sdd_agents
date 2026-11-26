---
missao: 20261121-l5-saida-humana-e-contrato-do-runner
fase: REVIEW
rodada: 1
status: done
sessao: 01a215cf-afb6-7260-996a-1e6ccd3edb87
data: 2026-11-26 00:34
gate: "tests/run-all.sh em 267be6bd0728cbf96dfb5b572b557ed4ccba458f: rc 0, suite green, 21 etapas, 2473 linhas ok, 0 FAIL, 1170 s. Gate REVIEW não fecha: há três incrementos pending e critérios abaixo de A. Antes da edição, somente checkpoint-notas.md estava sujo, com 259 inserções preexistentes excluídas do commit."
reviewed_head: 267be6bd0728cbf96dfb5b572b557ed4ccba458f
---

# Review — rodada r1 — L5 — saída humana e contrato do runner

## TL;DR

A revisão integral confirmou sete achados. Dois problemas de alto impacto ganham incrementos próprios e três correções de escopo pequeno vão juntas ao EXEC.
A corrida dupla de ADR e a lacuna na ajuda ficam no backlog. A REVIEW não altera código.

## Nota da rodada

Diff de `origin/main...HEAD` com base `60ec5718ac4931aa02e00c3e8e6027cd98600d6c` e HEAD `267be6bd0728cbf96dfb5b572b557ed4ccba458f`, incluindo 13 scripts de produção e sensores e a documentação da missão. Os seis espelhos de chapéu foram comparados com as fontes. O arquivo de notas não foi aberto e os logs das reproduções são de fixtures descartáveis em `/tmp/sdd-l5-probes.kjiKkm/`.

- Código da CLI: `bin/sdd`, `bin/sdd-link-agents` e `bin/sdd-worker`.
- Sensores em `tests/`: `check-adr.sh`, `check-coordination.sh`, `check-gates.sh`, `check-hat.sh`, `check-kaizen.sh`, `check-mutation.sh`, `check-preflight.sh`, `check-templates.sh`, `check-todo.sh` e `check-worker.sh`.
- Documentação: README, backlog, os guias `docs/{failure-modes,pipeline,plan-only}.md` e o ADR 0025. Os arquivos de agentes `sdd-{docs,executor,kaizen,planner,publisher,reviewer}.md` foram lidos com seus seis espelhos por comparação. As mudanças em `commands/sdd-{plan,worker}.md` e `templates/{checkpoint,missao,pr-body,todo,todo.pt-BR}.md` também entraram na revisão.
- Handoffs: missão, plano, aceite, checkpoint e entregas do EXEC e da QA. O histórico append-only não entrou.

### Detecção de credenciais

| Estado | Ocorrências | Evidência |
|---|---|---|
| PASS | 0 | Regex e Gitleaks sem erros sobre 44 arquivos e 3001 linhas adicionadas, excluído o histórico de notas. |

### Qualidade e impacto

O runner reutiliza o parser do backlog e conserva os controles negativos de merge e de QA. Os defeitos se concentram nas decisões em que uma leitura incompleta ou ambígua é tomada como suficiente, e na substituição de comandos locais sem verificar que são cópias do kit. Não houve alteração de esquema ou interface gráfica. As duas provas de resolução e o pós-merge seguem leitores locais, sem custo novo de rede além do `gh pr view` já usado no fechamento. A leitura de refs usa o custo de referência medido no plano, cerca de 0,44 s para 158 refs, sem alegação de novo benchmark.

### Cobertura de testes

| Superfície | Sensores que a exercitam | Limite visto nesta rodada |
|---|---|---|
| Runner e fechamento | `check-gates.sh`, `check-kaizen.sh`, `check-coordination.sh`, `check-adr.sh`, `check-preflight.sh` | Fixtures aprovadas não cobriam Git sem `-z`, dados locais conflitantes, referência Git ambígua ou fase forçada. |
| Entradas link-agents e worker | `check-preflight.sh` e `check-worker.sh` | Cobrem caminhos vazios e idempotência, além de consulta sem alteração do índice, mas não os comandos locais distintos. |
| Sensores de contrato e documentação | `check-todo.sh`, `check-hat.sh`, `check-templates.sh` e âncoras do catálogo | O parser tem controle de seção decidida e bloco cercado, mas perdia um segundo valor malformado. O catálogo completo de mutação não foi executado, conforme o escopo. |

Na árvore revisada, `tests/run-all.sh` terminou com rc 0, suite green, 21 etapas, 2473 linhas `ok` e 0 `FAIL`. A saída está em `/tmp/sdd-l5-review-full.lgZr7T/suite.log`. A primeira tentativa, sob um limite externo de 590 s, foi interrompida no preflight com rc 124 e nenhuma asserção FAIL emitida. A recontagem das asserções dos Checks I1–I17 na saída da suíte mediu 46 padrões, 46 contagens no alvo. I18 retornou 17 e o catálogo tem as 28 funções e as 28 entradas previstas. Os controles da suíte separam ancestral da base de ancestral do head de PR `MERGED` e verificam os dois braços do JIRA. Nos probes independentes, o item com dois commits foi omitido sem PR e listado com uma prova pela base e outra pelo head quando o stub respondeu MERGED. OPEN retornou rc 1 sem lista. O pós-merge preservou os bytes do backlog com `cmp`. O controle de status distingue a impossibilidade de revalidar a e2e de uma QA ainda fechada no disco, e o controle de fim da corrida cita `sdd close`.

### Sincronismo da documentação

O [ADR 0025](../../adr/0025-ids-across-refs-and-the-second-proof-of-a-resolution.md), os templates do backlog e o guia do pipeline descrevem as provas na ordem que o código usa. README e o guia PLAN-only descrevem os atalhos de instalação e a ajuda do `run` foi conferida. A entrada do `close` na própria ajuda ainda omite o caminho sem JIRA, em contraste com o guia e com a jornada verificada pela QA.

### Código morto e limpeza

A varredura de símbolos introduzidos ou órfãos no diff não encontrou candidatos confirmados. Usou busca de referências, sem ferramenta de indexação especializada. Código morto preexistente não foi varrido.

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | B | O link de comandos estende a substituição a arquivos locais distintos sem verificar a origem ou preservar os bytes. |
| Type Safety | B | O leitor de resoluções perde valores malformados e passa abreviações a uma interface Git que também aceita nomes de refs. |
| Error Handling | B | O alocador cala diante de uma opção não suportada e publica um número que ignora um worktree acessível. |
| Security | A | A varredura de segredos não apontou ocorrência e as provas usam refs e ancestrais, sem executar o conteúdo do backlog. |
| Performance | A | Não houve gargalo reproduzido no escopo. O alocador lê uma árvore por ref e mantém a referência de custo do plano. |
| Test Coverage | B | A suíte cobre os casos nominais, mas os probes de perda local, compatibilidade e prova incorreta estão vermelhos no HEAD. |
| Documentation | B | A ajuda do fechamento descreve só o caminho com JIRA, embora o guia e o runner documentem a volta à base sem JIRA. |
| **Overall** | **B** | Duas regressões de alto impacto e três correções pontuais ainda exigem TDD. A rodada não aprova o merge. |

## Achados da rodada

| # | Severidade | Achado | Onde |
|---|---|---|---|
| 1 | HIGH | `sdd-link-agents` toma o lugar de comandos locais e perde edições sem gravar, inclusive em arquivo nunca rastreado. | `bin/sdd:13541`, `bin/sdd:13549` |
| 2 | HIGH | No intervalo suportado de Git anterior a 2.36, um ADR só no disco de outro worktree deixa de contar. | `bin/sdd:9749` |
| 3 | MEDIUM | Um registro `RESOLVED by` inválido é descartado quando há também um válido, e o item pode aparecer como pronto para remoção. | `tests/check-todo.sh:526` |
| 4 | MEDIUM | A prova aceita o nome de uma ref que coincide com uma abreviação e conclui que o commit está na base mesmo quando o objeto correto não está. | `bin/sdd:13957`, `bin/sdd:13960` |
| 5 | MEDIUM | `sdd run --phase EXEC` pode contornar a TICKET e ainda perder o aviso de commit direto na base. | `bin/sdd:10721` |
| 6 | MEDIUM | Duas alocações simultâneas reservam o mesmo número em worktrees distintos. | `bin/sdd:9910` |
| 7 | LOW | A linha de `sdd close` em `sdd help` diz apenas que fecha o JIRA. | `bin/sdd:13429` |

1. **Comandos locais.** Em targets iguais, gravei um `.claude/commands/sdd-plan.md`, editei seu conteúdo sem gravar e criei um `sdd-worker.md` nunca rastreado. Executei `sdd link-agents` em cada target. O runner da base retornou 0, preservou os dois arquivos por `cmp` e não preparou remoção no índice. O HEAD retornou 0, converteu os dois em links com `cmp` diferente e preparou a remoção de `sdd-plan.md`. O conteúdo nunca rastreado não tinha cópia no Git.
2. **Git suportado.** O README declara 2.31+ e as notas de versão de Git 2.36.0 (também em `/usr/share/doc/git/RelNotes/2.36.0.txt`) registram a introdução de `git worktree list --porcelain -z`. Com ADR 0017 não rastreado em outro worktree, `sdd adr new --slug fixture --dry-run` retornou `docs/adr/0018-fixture.md` e identificou o worktree no Git 2.43.0. Repeti com um stub que delega todos os demais comandos ao Git real e recusa só `worktree list --porcelain -z` com rc 129. A saída mudou para `docs/adr/0001-fixture.md`, rc 0 e stderr vazio. Não usei um binário histórico de Git.
3. **Valor malformado.** Validei com `bash tests/check-todo.sh --check TODO.md` um backlog de fixture com quatro itens. Num deles havia um hash ancestral da base e um segundo token com sufixo não hexadecimal. `--resolved` emitiu só o primeiro e `sdd close` anunciou o item como removível. O controle com segundo hash hexadecimal de um commit lateral não foi listado. Registros malformados não podem desaparecer e deixar a prova parecer completa.
4. **Objeto versus ref.** No mesmo fixture, com o hash abreviado de um commit lateral e uma branch homônima apontando para a base, `git merge-base --is-ancestor` retornou 1 para o hash completo e 0 para o abreviado, com aviso de ambiguidade. `sdd close` suprimiu o aviso e listou o item como `in main`. Remover só a ref homônima fez a CLI omitir o item. A prova precisa resolver o objeto do hash ou rejeitar valores ambíguos, tanto para a base quanto para o head verificado do PR.
5. **Fase forçada.** Em `main`, com JIRA ligado, branch ainda no placeholder e sem `10-ticket.md`, `sdd run 20261126-fixture --phase EXEC --dry-run` projetou EXEC tanto na base quanto no HEAD, com rc 0 e sem abrir sessão. No runner do merge-base, a saída teve um aviso `you are on the base branch`. No HEAD, zero. Forçar EXEC não passa pela derivação que chamaria TICKET.
6. **Concorrência.** Dois `sdd adr new` reais em worktrees de uma fixture, com uma barreira de teste no `mkdir` imediatamente após as duas leituras do máximo, retornaram 0 e criaram `0001-one.md` e `0001-two.md`. A leitura de outro worktree ajuda quando o primeiro arquivo já existe. Tornar a escolha atômica entre worktrees exige desenho próprio.
7. **Ajuda.** `bin/sdd help` emitiu só `sdd close <mission>        post-merge: close the JIRA issue` para o comando. A observação é de prosa, não um defeito novo na execução do fechamento.

## Incrementos de conserto (R<n>)

Nenhum conserto foi aplicado nesta rodada. As cinco correções de escopo da missão foram encaminhadas ao EXEC.

| R<n> | Achado | Check escrito no checkpoint |
|---|---|---|
| R1 | Achado #1 da r1 — preservar comandos locais conflitantes no link-agents | `p=$(bash tests/check-preflight.sh 2>&1); echo "$(grep -c '^  ok    link-agents preserves conflicting tracked edits and untracked local commands$' <<< "$p") $(grep -c '^  ok    link-agents still installs missing kit commands and is idempotent$' <<< "$p")"` → `1 1` |
| R2 | Achado #2 da r1 — ler ADRs de outros worktrees também no Git que não aceita -z | `a=$(bash tests/check-adr.sh 2>&1); echo "$(grep -c '^  ok    adr allocation falls back when git worktree list refuses NUL output$' <<< "$a") $(grep -c '^  ok    adr new names the other worktree and advances beyond its uncommitted id on older Git$' <<< "$a")"` → `1 1` |
| R3 | Achados #3–#5 da r1 — distinguir resolução não provada e avisar sobre EXEC forçado na base | `t=$(bash tests/check-todo.sh --selftest 2>&1); g=$(bash tests/check-gates.sh 2>&1); echo "$(grep -c '^  ok    rule: --resolved refuses a mixed valid and malformed resolution item' <<< "$t") $(grep -c '^  ok    sdd close omits a finding with any malformed resolution token$' <<< "$g") $(grep -c '^  ok    sdd close does not use a ref as proof for an abbreviated resolution hash$' <<< "$g") $(grep -c '^  ok    sdd run warns on the base before a forced EXEC even when TICKET is pending$' <<< "$g")"` → `1 1 1 1` |

## O que virou incremento

- `R1` (#1) — repetir a jornada do instalador com arquivos locais distintos e controle com destinos ausentes. Asserir bytes dos rascunhos, índice, criação dos links restantes e idempotência.
- `R2` (#2) — reproduzir a recusa de `-z` com o probe antigo e reexecutar `sdd adr new` comprovando ID e origem. Manter a cobertura da leitura do Git atual.
- `R3` (#3–#5) — no parser e na CLI, preservar a distinção entre todos os hashes provados e um token inválido. Reandar `sdd close` com os controles da base e do PR, testar o abreviado ambíguo e reandar a projeção de EXEC forçada, comparando com a TICKET normal.
- Não há rodada anterior nem correções desta rodada para certificar.

## O que foi refutado

- **A exceção do chapéu do Kaizen seria uma omissão do I17.** A decisão 16 de [00-missao.md](00-missao.md#decisões-do-grill-não-re-litigar) e o I17 excluem expressamente `agents/sdd-kaizen.md`, que roda só no kit. `tests/check-hat.sh:1741` aplica esse recorte, e o controle negativo de citação em chapéu de fixture permanece. Não é o público-alvo da regra.
- **Todo erro de uma ref deveria abortar a alocação.** O ADR 0025 manda seguir quando uma ref individual não pode ser lida. Isso não abrange perder todos os worktrees por usar uma opção ausente no Git suportado, que foi confirmado como #2.
- **Deveria haver aviso quando o parser está ausente ou retorna erro.** O I11 especifica silêncio nesses casos. Isso não certifica itens incorretos: o chamador sai antes da listagem. A violação é quando o parser retorna rc 0 escondendo parte dos dados, como reproduzido em #3.
- **O fechamento já edita ou baixa a catraca dos resolvidos.** Os controles da QA e da suíte conferem os bytes do backlog. A reprodução independente aqui também terminou com `cmp` rc 0. O defeito é de recomendação, não de alteração automática.

## Achados fora de escopo

- #6, reserva concorrente entre worktrees, registrado no [backlog](../../../TODO.md) em 2026-11-26. O recorte do ADR 0025 é onde ler IDs já usados, não uma reserva transacional compartilhada entre processos.
- #7, descrição parcial de `sdd close` em `sdd help`, registrado no mesmo backlog. É uma mudança só de prosa.
- O backlog tinha 92 itens na entrada, com a catraca em 89 e três registros do EXEC já na árvore revisada. A nova leitura incorpora esses três e os dois registros desta rodada. Não foi feita a limpeza pós-merge dos 17 itens.

## Pendências / Decisions for a Human

Nenhuma decisão nova para executar `R1`–`R3`. Continuam as pendências já listadas em [00-missao.md](00-missao.md#pendências-para-o-humano), inclusive a atualização da regra de segunda prova pelo dono.

## Passagem ao EXEC

Leia os achados e as três linhas `pending` do [checkpoint](checkpoint.md). Comece pelo controle de bytes e do índice no instalador. A próxima REVIEW reavalia a partir do `reviewed_head` desta rodada. Não houve uso de PR, JIRA ou app real. A única mudança local preexistente foi `checkpoint-notas.md` com 259 inserções, que ficaram fora do commit. As notas novas foram somente acrescentadas. Um espaço final preexistente nas notas também ficou fora do commit.

### Ações recomendadas

- **CRITICAL** — nenhuma.
- **HIGH** — `R1` e `R2`, isolados no checkpoint.
- **MEDIUM/LOW** — `R3` e o registro de reserva compartilhada no backlog.
- **Prosa** — ajuste futuro da ajuda do fechamento no backlog.

_Pegada de custo: codereview 2.30.2 instalada, após comparar a cópia 2.27.38 indicada no boot. Sete tarefas por arquivo ou grupo, sem verificadores de delta, e uma varredura, em gpt-6.1-terra. As tarefas por arquivo reportaram 25 leituras integrais e de 2 a 19 chamadas por tarefa. Sem medição de custo da sessão neste relatório._
