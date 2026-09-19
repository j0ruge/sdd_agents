# Executar melhorias de confiabilidade no `sdd_agents`

## 1. Pedido, autorização e contexto

Execute este plano no repositório `/home/joruge/repos/sdd_agents`.

O usuário solicitou uma análise dos seus agentes autônomos de desenvolvimento, identificação de falhas e implementação das melhorias. A análise inicial terminou, este plano foi aprovado e a execução foi expressamente autorizada. **Não é necessário pedir novamente autorização para implementar e testar.**

A sessão anterior permaneceu em modo de planejamento; **nenhuma correção foi implementada**. Foram realizadas leituras, execução da suíte e reproduções em fixtures temporárias.

Decisões tomadas pelo usuário:

- Priorizar **confiabilidade**, preservando o pipeline atual.
- Entregar em **duas etapas**: primeiro três correções pontuais; depois exclusão mútua.
- Trabalhar em **checkout separado, baseado no HEAD analisado**, preservando o checkout original.
- Quando o checkout estiver ocupado, **recusar imediatamente e informar o proprietário**, sem fila de espera.

O projeto é um kit Bash e Markdown com oito agentes. O runner encadeia sessões headless de `claude -p`:

`PLAN → TICKET → EXEC ⇄ QA → REVIEW ⇄ EXEC → DOCS → PR`

O estado técnico é derivado dos artefatos da missão. Gates verificam testes, commits, checkpoint, handoffs e PR. O humano participa do planejamento e do merge. Existem controle de orçamento, guardas de ferramentas e caminhos, ledger de autonomia e catálogo de mutação.

## 2. Estado verificado e preparação

Estado confirmado em 18/09/2026:

- HEAD: `1c9146d18d2bb73ada7283d5b9e70214249cf397`.
- Branch: `feat/a-excecao-do-chapeu-e-o-genero-diferido`.
- Única alteração indicada por `git status --short`: `?? AGENTS.md`.
- A configuração deste projeto usa `DEFAULT_BRANCH="main"`. Não havia `develop` nas referências locais ou remotas disponíveis.
- A suíte `bash tests/run-all.sh` terminou com `suite green` fora do sandbox.
- A primeira execução restrita apresentou falhas decorrentes de sockets locais bloqueados e escrita proibida em `/var/tmp`; não atribuir essas falhas ao código.

Antes de editar:

1. Ler as instruções do `AGENTS.md` original, o `CLAUDE.md` e a rule de anatomia do agente.
2. Conferir novamente o estado do checkout, preservando mudanças posteriores à análise.
3. Criar um worktree separado, por exemplo em `/home/joruge/repos/sdd_agents_reliability`, com branch `fix/confiabilidade-dos-agentes`, baseada no SHA acima. Se o destino já existir, inspecioná-lo antes de reutilizar.
4. Usar o runner desse novo checkout durante os testes.
5. Não adicionar, remover ou sobrescrever o `AGENTS.md` não versionado do checkout original.

Convenções relevantes:

- Superfície do kit, código, comentários e testes em inglês.
- Artefatos desta missão em português, conforme `OUTPUT_LANG=pt-BR`.
- TDD: escrever o Check e a regressão antes da correção.
- Alterações pequenas; nenhuma refatoração geral do runner.
- Preservar a última linha protegida de entrada de `bin/sdd`.
- Atualizar documentação junto das alterações de comportamento.
- Se agentes forem alterados, sincronizar os espelhos pelo comando `sdd install --force`.
- Registrar achados fora de escopo conforme a régua de admissão e o formato do `TODO.md`.

Evidências opcionais da sessão anterior, caso ainda existam:

- Suíte: `/tmp/sdd-audit-suite-unrestricted-20260918.log`.
- Fixtures: `/tmp/sdd-audit-probes-845fwrdg`.

Os testes novos devem reproduzir os problemas independentemente desses arquivos temporários.

## 3. Etapa 1 — Corrigir três falhas reproduzidas

### Integridade do plano na troca de branch

**Código principal:** `ensure_mission_branch()`.

**Falha reproduzida:** duas branches contêm a mesma missão e o mesmo campo `branch:`, mas versões diferentes de `01-plano.md`. O comando parte da versão atualizada, troca de branch e abre a sessão com o plano antigo.

**Implementação:**

- Comparar os bytes de `00-missao.md` e `01-plano.md` com os da branch de destino antes do checkout.
- Ausência ou divergência deve impedir a troca de branch, a escrita de intervenção e a abertura de sessão.
- Revalidar os dois arquivos após o checkout, antes de continuar.
- Informar claramente os arquivos divergentes e as branches envolvidas.
- Preservar os comportamentos existentes para branch ausente, placeholder, branch atual e criação de branch nova.
- Não exigir igualdade de checkpoint, notas ou handoffs: eles representam progresso que pode diferir entre branches.

**Aceite:** plano antigo recusado antes de qualquer sessão; plano idêntico aceito; retomada com progresso diferente continua funcionando.

### Orçamento positivo menor que US$ 1

**Código principal:** `mission_budget_blown()`.

**Falha reproduzida:** `BUDGET_MISSION_USD=0.50`, com US$ 1,00 já registrado no journal, ainda permite outra sessão. A regra atual `0|0.*` desabilita indevidamente todo teto iniciado por `0.`.

**Implementação:**

- Usar comparação numérica para reconhecer zero.
- Somente zero desabilita o teto, incluindo representações equivalentes.
- Qualquer valor positivo deve ser comparado com o gasto acumulado.
- Preservar validação existente, `--budget-override`, registro de intervenção e comportamento da projeção.

**Aceite:** cobrir zero, zero decimal, teto fracionário e inteiro; gasto abaixo, igual e acima do teto; `run`, `retry`, override e dry-run. A execução recusada não pode abrir sessão.

### Registro durável antes da notificação

**Código principal:** `autonomy_blocked_row()` e `escalation_hook()`.

**Falha reproduzida:** durante o hook, o ledger ainda não contém o evento; ele só aparece depois que o hook retorna. Um hook travado impede esse registro.

**Implementação:**

- Gravar o evento no ledger antes de chamar `ON_ESCALATION_CMD`.
- Limitar o hook a cinco segundos, com encerramento forçado após mais um segundo.
- Preservar stdin fechado, variáveis de contexto e ausência de execução no dry-run.
- Falha ou timeout gera aviso e preserva o retorno original da escalada.
- Preservar o diagnóstico existente para falha de escrita no ledger; não anunciar persistência que não aconteceu.
- Se faltar a ferramenta necessária ao timeout, avisar e não executar o hook sem limite.

**Aceite:** o hook consegue ler o evento correspondente; hook que falha ou trava não impede a parada; não há duplicação de eventos nem notificações em projeções.

## 4. Etapa 2 — Um checkout, um dono de execução

**Falha reproduzida:** duas invocações simultâneas de `sdd run` chegaram à abertura de sessão no mesmo checkout. Atualmente não há lock de execução.

### Posse e admissão

- Implementar exclusão mútua com `flock`, por checkout físico.
- Caminhos por symlink para o mesmo checkout compartilham a identidade; worktrees independentes recebem locks distintos.
- Centralizar a política de admissão, evitando guardas divergentes espalhadas pelos comandos.
- Adquirir a posse antes de trocar branch, escrever artefatos, executar gates com efeitos ou abrir sessões.
- Cobrir `run`, `retry`, `close`, `kaizen` com execução, `approve`, `install`, `adr new` e `preflight`.
- Cobrir também comandos que executam gates ou certificam conteúdo, incluindo `status` completo, `phase`, `why` e `health`.
- No `health`, proteger o checkout efetivamente medido, que pode diferir do diretório de onde o comando foi chamado.
- Incluir a entrada alternativa `sdd-link-agents`, pois ela altera índice Git, agentes instalados e `.gitignore`.

### Contrato quando ocupado

- Recusar imediatamente com retorno **75** e marcador **`CHECKOUT-BUSY`**.
- Informar checkout, processo proprietário, comando, missão e início.
- Não abrir sessão, alterar branch, escrever checkpoint ou executar hook de escalada.
- Não registrar a recusa como sessão ou bloqueio de missão: a execução não foi admitida.

### Metadados, consultas e reentrada

- Manter metadados operacionais fora dos arquivos versionados: checkout, proprietário, identidade do processo, início, comando, missão e identificador da execução.
- O lock do sistema operacional decide a posse; o arquivo de metadados serve para diagnóstico.
- Manter disponíveis consultas sem gates, como `status --no-gates`, `boot`, `census`, `autonomy`, `kaizen --series`, `adr check`, ajuda e versão.
- Exibir o proprietário ativo em `status --no-gates`.
- Projeções que executam `TEST_CMD` também precisam de exclusão.
- Permitir auxiliares legítimos chamados pela execução proprietária, como `sdd health`, `sdd install --force` e criação de ADR.
- Verificar ancestralidade e identidade do proprietário para essa reentrada; uma variável de ambiente isolada não constitui autorização.
- Recusar abertura recursiva de outro pipeline no mesmo checkout.
- Auxiliares não devem sobrescrever nem liberar a posse do processo externo.

### Recuperação e limites

- Supervisionar os processos da execução para manter exclusividade enquanto seus filhos ainda puderem escrever.
- Tratar conclusão normal, erro, sinais e morte do proprietário com filho ainda ativo.
- Recuperar automaticamente após o encerramento dos processos.
- Não apagar ou recriar o arquivo de lock durante uma disputa.
- Metadados antigos não podem causar bloqueio permanente nem autorizar dois proprietários.
- Verificar e documentar as dependências antes de sessões pagas.
- Preservar gates, guardas de ferramentas e caminhos e estado técnico derivado dos artefatos.

O lock coordena as entradas do kit. Ele não impede edições feitas diretamente por ferramentas externas e não substitui as permissões do sistema.

## 5. Testes, documentação e entrega

- Acrescentar as regressões da primeira etapa aos sensores existentes.
- Criar `tests/check-coordination.sh` com fixtures, sincronização determinística e processos concorrentes; usar limites de tempo para evitar testes pendurados.
- Cobrir disputa entre comandos diferentes, mesma missão e missões diferentes, symlinks, worktrees independentes, consultas durante execução, reentrada legítima e tentativas de bypass.
- Cobrir recuperação após conclusão, erro, sinais e queda com filho sobrevivente.
- Verificar ausência de efeitos na invocação recusada, além do retorno e da mensagem.
- Integrar o sensor à suíte, ao catálogo de mutação e aos pisos de cobertura pertinentes.
- Exigir que cada mutante altere realmente a propriedade que pretende sabotar e seja detectado pelo motivo correto.
- Executar sensores afetados e suíte completa em cada etapa.
- Rodar a certificação completa de mutação depois de estabilizar as alterações e eventuais correções da revisão. Atualizações posteriores que invalidem o carimbo exigem nova certificação.

Os testes devem usar CLIs simuladas e estado temporário isolado. Não executar `sdd preflight` real como smoke test: ele abre uma sessão paga. Não iniciar missões reais ou modificar Jira, PRs ou outros serviços para validar estas correções.

Atualizar documentação do pipeline, falhas operacionais, requisitos e anatomia do agente. Registrar evidências nos handoffs e resultados medidos no histórico de melhorias. Seguir a regra de fechamento de backlog do projeto, sem apagar antecipadamente itens cuja remoção depende do merge.

Entregar commits pequenos e separados por etapa. Ao terminar, informar:

- Checkout, branch e commits produzidos.
- Falhas corrigidas e comportamentos resultantes.
- Testes executados e resultado da certificação.
- Limitações ou pendências efetivamente encontradas.

Não incluir fila, agendamento, novos modelos, coordenação distribuída ou migração dos artefatos antigos. Não fazer push, publicação ou merge como parte desta entrega local.
