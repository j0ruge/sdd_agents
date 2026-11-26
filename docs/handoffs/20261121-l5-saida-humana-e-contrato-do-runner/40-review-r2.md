---
missao: 20261121-l5-saida-humana-e-contrato-do-runner
fase: REVIEW
rodada: 2
status: done
sessao: 01a2166f-258b-7d53-8198-0886c2d62f4d
data: 2026-11-26 03:11
gate: "tests/run-all.sh em 86b48881f08fde1063a7c66fcc66a79e1264866d: rc 0, suite green, 21 etapas, 2481 linhas ok, 0 FAIL, 736 s. REVIEW não fecha: R4 pending; Code Quality (Zen), Error Handling e Test Coverage em B. Type Safety subiu de B para A após os commits do EXEC. Na entrada, só checkpoint-notas.md tinha 259 inserções preexistentes, excluídas do commit."
reviewed_head: 86b48881f08fde1063a7c66fcc66a79e1264866d
---

# Review — rodada r2 — L5 — saída humana e contrato do runner

## TL;DR

A rodada delta confirmou os controles de R1–R3 e dois casos residuais. O instalador deixa um link criado pelo próprio kit inutilizável depois de uma mudança de caminho, o que vira R4. O caminho de worktree com quebra de linha no fallback do Git antigo foi registrado como recorrência no backlog. Nenhum código foi alterado.

## Nota da rodada

`codereview:codereview base=267be6bd0728cbf96dfb5b572b557ed4ccba458f` na branch `fix/l5-saida-humana-e-contrato-do-runner`. O delta tem sete commits e 14 caminhos no inventário. O histórico de notas ficou fora do conteúdo lido. Foram analisados os cinco scripts alterados (`bin/sdd` e quatro sensores). A verificação de prosa leu 28 unidades alteradas em seis arquivos. A linha do baseline foi conferida como dado de máquina, e a r1 foi lida apenas como fonte dos achados anteriores. Os controles de QA em `30-handoff-qa.md` já cobrem instalação, alocação por ref, projeção e as duas provas do fechamento.

### Detecção de credenciais

| Estado | Ocorrências | Evidência |
|---|---|---|
| PASS | 0 | Regex e Gitleaks, sem erros, em 13 arquivos e 367 linhas adicionadas. O arquivo de notas ficou fora da entrada. |

### Qualidade, tipos, erros e impacto

O R1 preserva arquivos locais divergentes e suas entradas no índice, mas aplica o mesmo critério a links do kit. O R2 volta a enxergar caminhos comuns no Git sem `-z`. O caminho com LF é um limite real e declarado do fallback, distinto da reserva concorrente. O R3 rejeita valores malformados e abreviações que não identificam um único objeto commit. O fechamento só lista e o delta não acrescenta chamadas de rede. Não foi medido um novo custo de produção. O tratamento novo do fechamento consulta o banco de objetos por hash e o fallback do alocador só roda quando a primeira leitura do Git falha.

### Cobertura de testes

| Superfície | Evidência rodada | Lacuna confirmada |
|---|---|---|
| `link-agents` | `check-preflight.sh` deu R1 → `1 1`, conferindo bytes, índice, instalação quando o destino falta e idempotência. | Os controles não mudam o caminho de um kit que já gerou links. |
| Alocação ADR | `check-adr.sh` deu R2 → `1 1`. O probe extra comparou Git normal com stub de recusa de `-z` e controlou espaço e barra invertida. | O fallback não lê o caminho inteiro quando contém LF. |
| Fechamento e EXEC forçado | `check-todo.sh --selftest` e `check-gates.sh` deram R3 → `1 1 1 1`. Há controles de base e PR `MERGED`, de ref homônima, de objeto tag e da TICKET normal. | O probe extra com dois objetos no mesmo prefixo confirmou que a listagem omite essa resolução. |

`tests/run-all.sh` → rc 0, suite green, 21 etapas, 2481 linhas ok, 0 FAIL, 736 s. A saída está em `/tmp/sdd-l5-review-r2.om3C4c/suite.log`. As contagens de R1–R3 vieram das linhas `ok` ancoradas desses sensores na suíte. O relatório não repete o catálogo de mutação completo e não houve app, PR ou JIRA real.

### Sincronismo da documentação

A atualização do ADR descreve o limite do fallback por linhas e a prova por objeto. O guia PLAN-only descreve corretamente a preservação de arquivos locais, mas a receita de recriar links ainda depende de R4 no cenário medido. O guia do pipeline confirma a exceção no salto de TICKET. A descrição parcial de `sdd close` em `sdd help` continua como prosa já registrada no backlog pela r1.

### Código morto e limpeza

A varredura do delta não encontrou símbolos introduzidos ou órfãos sem uso. As funções novas dos testes têm chamadores nos próprios blocos e o `oid` passou a alimentar as duas provas. A varredura não usou indexador nem procurou código morto preexistente.

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | B | A guarda de preservação confunde um link gerado pelo kit com um comando escrito no alvo e impede a reinstalação. |
| Type Safety | A | A listagem exige um único objeto commit e rejeitou tanto dois objetos com o mesmo prefixo quanto um hash lateral com ref homônima. |
| Error Handling | B | A recusa de saída NUL já tem fallback para caminhos comuns, mas um link sem arquivo ainda recebe sucesso e encaminhamento para um comando indisponível. |
| Security | A | A varredura não apontou credenciais e os argumentos de prova são hashes validados, separados de nomes de refs. |
| Performance | A | O segundo formato é solicitado somente na falha do primeiro e a conferência de cada resolução é local, sem consulta remota nova. |
| Test Coverage | B | Os sensores de R1–R3 cobrem as regressões originais nos casos exercitados, mas não detectam o link órfão gerado pelo kit. |
| Documentation | B | O guia ainda promete recriar links num comando e a ajuda do fechamento mantém a lacuna de prosa registrada pela r1. |
| **Overall** | **B** | Os três consertos avançaram em commits independentes e a prova de tipo chegou a A. Um achado funcional ainda precisa passar pelo EXEC. |

## Achados da rodada

| # | Severidade | Achado | Onde |
|---|---|---|---|
| 1 | MEDIUM | `sdd link-agents` deixa o link que o kit instalou apontando para uma cópia antiga ou inexistente e ainda orienta rodar `/sdd-plan`. | `bin/sdd:13540` |
| 2 | LOW | Sem `-z`, um LF no nome de outro worktree pode esconder um ADR não commitado da alocação. É um limite do formato antigo, do mesmo tipo que o já registrado para o worker. | `bin/sdd:9750` |

1. No fixture, o runner anterior criou o link real de `sdd-plan.md` para a instalação anterior. Com a cópia antiga ainda legível, mas de conteúdo diferente, o HEAD retornou 0, preservou o destino antigo e avisou `preserving local command`. Ao mover a instalação anterior, retornou 0 de novo, preservou o link quebrado e imprimiu `Next: $ /sdd-plan`. Um controle com o runner da base e o kit disponível apontou o link para a cópia correta, legível, também com rc 0. A reprodução está em `/tmp/sdd-l5-review-r2.om3C4c/check-link-relocated.sh`.
2. No Git 2.43.0, criei worktrees com espaço, barra invertida e LF no caminho, com ADRs não rastreados 0017, 0022 e 0025, respectivamente. `sdd adr new --slug review --dry-run` propôs 0026. Com um stub que devolve 129 só para `worktree list --porcelain -z`, propôs 0023 com rc 0. Retirando só o ADR do worktree com LF, ambos propuseram 0023. O `--porcelain` real dividiu o nome que continha LF em duas linhas, sem codificá-lo entre aspas. Não rodei um binário histórico de Git. O caso já tem limite declarado no ADR e a correção geral deve tratar os dois consumidores, sem tentar inferir caminhos de um formato ambíguo.

## Incrementos de conserto (R<n>)

| R<n> | Achado | Check escrito no checkpoint |
|---|---|---|
| R4 | Achado 1 da r2 — restaurar links do kit depois de mudar o caminho da instalação | `p=$(bash tests/check-preflight.sh 2>&1); echo "$(grep -c '^  ok    link-agents refreshes a command link from a previous kit installation$' <<< "$p") $(grep -c '^  ok    link-agents restores a dangling kit command link after relocation$' <<< "$p") $(grep -c '^  ok    link-agents preserves conflicting tracked edits and untracked local commands$' <<< "$p")"` → `1 1 1` |

## O que virou incremento

- `R4` (#1) exige dois controles da CLI. Um liga o comando a uma instalação mais nova quando a antiga ainda existe e o outro recupera o link quebrado depois que a antiga foi movida. O teste deve criar os links pela CLI, confirmar o alvo com `readlink` e a leitura do comando, e manter verdes os controles de preservação dos rascunhos e do índice do R1. Não tratar um link local sem origem comprovada como substituível.
- R1 da r1, em `21482a2`. O reteste confirma que arquivos locais divergentes e o índice ficam intactos e que destinos ausentes são ligados. O cenário de mudança de instalação é o achado novo, não uma volta ao comportamento que apagava rascunhos.
- R2 da r1, em `4376e32`. O sensor vê a falha NUL seguida da chamada por linhas e confirma a proposta 0018 quando o outro worktree tem 0017 no disco. O LF residual está no backlog, separado do caso comum que antes falhava.
- R3 da r1, em `234b734`. Os quatro Checks da r1 passaram. Em um Git descartável, gerei dois commits com o mesmo prefixo de sete dígitos. `sdd close` listou uma vez o hash completo ancestral, não listou o prefixo ambíguo nem o hash completo lateral com uma ref homônima, com rc 0.

## O que foi refutado

- **Toda pontuação rejeitada após o hash seria regressão de um formato válido.** Um TODO de fixture passou em `--check` com quatro itens. Na base, `--resolved` e `sdd close` aceitaram o hash nu e os três sufixos (`.`, `)` e `-invalid`). No HEAD as duas saídas mantiveram o hash nu e omitiram os outros, todas com rc 0. O lint mede a forma do item, não a validade da resolução. A regra do template, já explicitada no plano, põe o valor hexadecimal nu no fim do corpo ou separado da atribuição. Nenhum token pontuado desse tipo foi encontrado no backlog atual. Não há evidência de perda de um formato contratado. O controle está em `/tmp/sdd-l5-review-r2.om3C4c/check-close.sh`.
- **A perda de worktrees se estenderia a caracteres escapados em geral.** No Git testado, espaço e barra invertida não foram escapados nem perdidos no fallback. O caso confirmado é mais estreito, com LF literal dividindo o registro.
- **Os Checks R1–R3 seriam declarações sem evidência.** As células são comandos com resultados esperados. Os hashes de conserto são alcançáveis e a execução independente dos quatro sensores desta rodada verificou os oito resultados. A nota de execução de R3 traz a comparação anterior e posterior. A medição concorrente citada no backlog também tem saídas de fixture preservadas na r1, com os dois arquivos reservados sob o mesmo número.

## Achados fora de escopo

- #2 foi registrado no [backlog](../../../TODO.md) como recorrência do item sobre leitura de `worktree list` por linhas. O consumidor novo é a alocação de ADR no fallback, não o `checkouts_of` do worker. A contagem de achados abertos não muda.
- Os achados 6 e 7 da r1 continuam no backlog. Esta rodada não reviu a reserva concorrente nem reabriu a prosa da ajuda.

## Pendências / Decisions for a Human

Nenhuma decisão nova para R4. As pendências do [00-missao.md](00-missao.md#pendências-para-o-humano) não mudaram.

## Boot da próxima fase

EXEC deve começar pela linha R4 do [checkpoint](checkpoint.md) e pelo fixture de duas instalações descrito nesta rodada, mantendo os controles de preservação do R1. A próxima revisão parte do `reviewed_head` desta rodada. Na entrada, somente `checkpoint-notas.md` estava sujo, com 259 inserções preexistentes que permanecem fora do commit. A nova nota foi acrescentada sem abrir o arquivo.

### Ações recomendadas

- **CRITICAL** — nenhuma.
- **HIGH** — nenhuma.
- **MEDIUM/LOW** — corrigir R4 em TDD e preservar os rascunhos do alvo. Tratar o formato antigo de worktrees no backlog.
- **Prosa** — a descrição parcial da ajuda do fechamento já está no backlog.
- **Fora de escopo** — nenhum caso adicional cortado pelo verificador.

_Pegada de custo — codereview 2.30.2 instalada, após comparar com a cópia 2.27.38 pedida no boot. Três tarefas por arquivo ou grupo, um verificador e uma varredura, em gpt-6.1-terra. Os agentes por arquivo reportaram dois arquivos lidos por inteiro e de três a nove chamadas. O verificador reportou 29 unidades e 15 chamadas, incluindo a linha de baseline roteada de volta como dado. Sem custo monetário medido nesta rodada._
