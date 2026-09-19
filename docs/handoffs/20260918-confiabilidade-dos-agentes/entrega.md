# Handoff — confiabilidade dos agentes

## Estado da entrega

A implementação das duas etapas está no checkout
`/home/joruge/repos/sdd_agents_reliability`, branch
`fix/confiabilidade-dos-agentes`, baseada em
`1c9146d18d2bb73ada7283d5b9e70214249cf397`.

A Task 1 e a Task 2 receberam revisões parciais, incluindo o primeiro conserto de SIGINT.
A revisão integral de `6c5e6f7` encontrou três Important adicionais (F1–F3), corrigidos em
`14b09a7`, `b76dfb5` e `f11bf27`. A suíte completa em `f11bf27` terminou rc 0, `suite green`,
coordenação 148/148, com runtime imutável durante a execução. A revisão F1 confirmou um complemento de fronteira de `--spec`, corrigido em `d12ace4`.
O suplemento tem GREEN focado 154/154 e suíte completa rc 0, `suite green`, sobre seu snapshot
congelado `d12ace4`. A re-revisão final aprovou F1/F2/F3, sem novos achados. Somente a
certificação comportamental integral e seu carimbo permanecem pendentes; esta entrega não está declarada concluída.

O plano aprovado está preservado, byte a byte, em
[`plano-aprovado.md`](plano-aprovado.md). O diretório não contém `00-missao.md` nem
`01-plano.md`, para não introduzir uma missão executável.

## Correções exigidas pela revisão integral

O parecer sobre `6c5e6f7` reproduziu: `adr new --repo` sem admissão do destino; hashes Git
filtrados ocultando divergência de bytes; SIGINT que não chegava ao filho foreground do worker.
Os testes observaram REDs por essas propriedades antes de corrigi-las. Os GREENs focados
fecharam os regimes medidos, e a revisão dos deltas aprovou os três achados como endereçados.
A suíte final passou; os aceites ainda aguardam a certificação comportamental integral e o carimbo.

Durante a primeira suíte congelada, inspeção de `--spec` revelou uma interação adicional:
caminhos `../` e diretórios symlink podiam escrever fora do destino, e um alias interno absoluto
era recusado indevidamente. O revisor confirmou o caso. O complemento canonicaliza o arquivo
existente, recusa spec externo antes de config/reserva/escrita e preserva aliases internos
relativos e absolutos. Os dois checkouts e o caller ficam sem efeitos no caso recusado.
Não foi alterado runtime durante a primeira suíte; a mudança posterior exigiu nova suíte.

## Commits de implementação

| Commit | Resultado |
|---|---|
| `7b0c2df` | Recusa plano ou missão ausente/divergente antes do checkout e revalida os dois artefatos depois da troca. |
| `46a288e` | Trata somente zero numérico como orçamento desabilitado; tetos positivos abaixo de US$ 1 passam a valer. |
| `9089493` | Persiste a escalada antes do hook e limita a notificação sem substituir o retorno original. |
| `c4ecb31` | Adiciona posse exclusiva por checkout físico, diagnóstico do proprietário, reentrada autenticada e supervisão dos descendentes. |
| `b7e012e` | Restaura a entrega cooperativa de `SIGINT` ao worker antes da escalada para `KILL`. |
| `14b09a7` | Compara os quatro hashes crus sem clean filters/EOL e distingue divergência pré-checkout de drift posterior. |
| `b76dfb5` | Compartilha o parser ADR entre admissão e dispatch, protege `--repo` e usa a config do destino. |
| `f11bf27` | Sinaliza a família ativa por pidfds, incluindo foreground, setsid e filhos criados por outra thread; verifica a capacidade antes de config. |
| `d12ace4` | Resolve o spec fisicamente dentro do checkout admitido, recusa escape por `../`/symlink e preserva aliases internos. |

As revisões usaram os intervalos `1c9146d..9089493` (Task 1 aprovada),
`9089493..c4ecb31` (Task 2 com um achado Important sobre `SIGINT`) e
`c4ecb31..b7e012e` (conserto re-revisado, todos os achados endereçados). A revisão integral de
`1c9146d..6c5e6f7` encontrou F1/F2/F3; a re-revisão focada de `6c5e6f7..f11bf27` mais o
suplemento `f11bf27..d12ace4` marcou os três **ADDRESSED**, sem quebra nova Critical,
Important ou Minor. Não há correção ou outra revisão ampla pendente.

O commit que contém este handoff, a cópia do plano e a entrada do `KAIZEN_LOG.md` é somente de
documentação. Não altera a chave de conteúdo da certificação, formada por `bin/`, `tests/`,
`templates/` e `config/`.

## Comportamentos resultantes

- Uma branch existente só é usada quando `00-missao.md` e `01-plano.md` são byte-idênticos antes
  e depois do checkout, sem normalização por clean filter ou EOL. Checkpoint, notas e handoffs continuam podendo divergir.
- `BUDGET_MISSION_USD=0` e representações numericamente equivalentes desabilitam o teto; qualquer
  valor positivo, inclusive `0.50`, é comparado ao gasto acumulado.
- O evento bloqueante entra no ledger antes do `ON_ESCALATION_CMD`. O hook e sua árvore inteira
  recebem o orçamento único de cinco segundos mais um segundo de encerramento forçado.
- Um único supervisor mantém o `flock` do checkout físico enquanto worker ou descendentes ainda
  podem escrever. Um concorrente recebe imediatamente rc 75 e `CHECKOUT-BUSY`, com diagnóstico
  do proprietário e sem efeitos de missão.
- `adr new --repo` admite o destino físico e lê sua config. `--spec` precisa resolver um
  arquivo físico interno ao destino; aliases internos são normalizados, externos recusados. Symlinks do mesmo checkout disputam a mesma posse;
  worktrees independentes não. Consultas sem
  gates continuam disponíveis, e auxiliares autorizados reentram somente após validar lock,
  ancestralidade e identidade dos processos.
- Conclusão, erro, `SIGINT`, `SIGTERM`, `SIGKILL`, órfãos, `setsid` e double-fork mantêm a posse até
  o último descendente terminar; a recuperação acontece depois do reap. O conserto de `SIGINT`
  permite ao worker e aos filhos com handler explícito executar limpeza cooperativa durante a graça.
  A seleção confere starttime/ancestralidade e sinaliza handles pidfd; a varredura não decide a
  liberação do lock.

## Evidência medida

| Momento | Evidência |
|---|---|
| Base `1c9146d` | `bash tests/run-all.sh` rc 0, `suite green`; 15 sensores e 346 entradas de catálogo. |
| Task 1 em `9089493` | Suíte completa rc 0, `suite green`; catálogo com 353 entradas. |
| Task 2 em `c4ecb31` | Suíte completa rc 0, `suite green`; coordenação 104/104. A edição final da raiz de `health` ocorreu durante essa suíte e recebeu depois um `check-health.sh` focado verde; não é um snapshot imutável de todos os arquivos durante toda a execução. |
| Revisão e conserto em `b7e012e` | RED definitivo 106/110 e GREEN 110/110 no sensor de coordenação; mutante `COORD_worker_ignores_sigint` reproduziu as mesmas quatro falhas. Sintaxe, idioma, lint focado e `git diff --check` ficaram verdes. |
| Correções F1–F3 | F1/F3:118/130 no RED; pidfd:129/136; filho de outra thread:144/148. GREEN final focado:coordenação148/148, gates verde, ADR69 probes e autonomia verde. Seis mutantes novos e o mutante anterior de SIGINT detectados pelos motivos corretos. |
| Complemento F1 em `d12ace4` | RED 148/154 e GREEN 154/154, ADR 69 probes. Dois mutantes de escape/canonicalização aplicados e detectados; suíte final rc 0, `suite green`, coordenação 154/154, runtime imutável. Log `/tmp/sdd-final-spec-suite.log`. |
| Censo atual | 16 scripts `tests/check-*.sh`; 373 definições e 373 entradas únicas no catálogo. |
| Suíte congelada em `f11bf27` | `bash tests/run-all.sh` rc0, `suite green`, coordenação148/148; runtime imutável durante toda a execução. Log `/tmp/sdd-final-fixes-suite.log`. |
| Re-revisão final | F1/F2/F3 ADDRESSED em `d12ace4`, sem novos achados. |
| Precheck do catálogo | 373/373 alterações reais e sintaxe válidas, rc 0, `/tmp/sdd-final-spec-anchor-check.log`; isto não é detecção comportamental. |
| Certificação final | **Pendente.** Executar os 373 mutantes sobre o conteúdo final, emitir o carimbo e conferir sua chave. |

As regressões observam retorno, mensagem e efeitos laterais: branch, intervenção, sessão,
checkpoint, journal, hook, quantidade de linhas e manutenção da posse. As fixtures de coordenação
usam barreiras determinísticas, limites de tempo e CLIs simuladas com resolução fail-closed.

## Decisões do controlador e custos

1. A supervisão usa um helper local por invocação em Python 3, com
   `PR_SET_CHILD_SUBREAPER` no Linux. Bash com herança de descritor ou varredura de process group
   não cobre órfãos com `setsid` e double-fork. O custo aceito é uma dependência adicional de
   runtime e a restrição explícita a Linux nos comandos coordenados; consultas continuam
   disponíveis, e as capacidades são verificadas antes da admissão.
2. O hook de escalada e toda a sua árvore usam o modo limitado do mesmo subreaper. Um filho com
   `setsid` havia sobrevivido ao GNU timeout e mantido a escalada pendurada. O custo aceito é que
   hooks que iniciem trabalho em background também terão esse trabalho encerrado dentro dos
   mesmos cinco segundos mais um segundo; descendentes comuns do runner preservam a proteção de
   vida integral.

3. Na correção F3, pidfds fixam a identidade do destinatário, evitando fallback para PID
   reutilizável. O custo aprovado é Linux>=5.3 e syscalls pidfd disponíveis sob seccomp, além
   do Python3.9+ existente. API ausente ou syscall negada recusa antes de config/sessão;
   help continua disponível. A graça geral e o prazo único do hook foram preservados.

4. O complemento F1 recusa specs fisicamente externos ao checkout admitido, mesmo que fossem
   aceitos anteriormente por `--spec`. O operador deve manter o spec no checkout alvo. Essa
   fronteira substitui a alternativa de locks multi-raiz; aliases internos relativos e absolutos
   continuam aceitos e geram links a partir do caminho físico interno.

## Incidente de isolamento

Na primeira rodada RED de `tests/check-coordination.sh`, o fixture de `preflight` não continha
stubs globais e abriu uma sessão real do Claude no repositório temporário
`/tmp/sdd-coordination-2cd3bxyv/repo`. A sessão
`46a09dd8-d04d-477d-85e9-16898a5e18c5` ocorreu entre
`2026-09-18T23:54:22.951Z` e `2026-09-18T23:54:27.262Z`. O JSONL registra um único `tool_use`:
Bash com `bash -c 'echo sdd-preflight-ok'`. O preflight também alcançou o probe de leitura
`gh auth status`; o log contém `gh authenticated` truncado. Não há evidência de escrita em
serviços nem de missão de produção iniciada.

O custo é **desconhecido**: o stream do preflight ficou somente em memória e o JSONL não contém
`total_cost_usd`. Não se deve estimar nem afirmar custo zero. A evidência local permaneceu em
`/tmp/sdd-coordination-red.log` e no JSONL do harness; o cleanup apagou o fixture.

A fronteira foi fechada com PATH controlado, stubs explícitos de CLIs externas, limpeza de
`BASH_ENV`, `ENV` e funções Bash exportadas, hook vazio por padrão e guard de resolução antes de
qualquer chamada ao runner. O controle negativo remove cada stub e exige recusa sem fallback.
`bash tests/check-coordination.sh --check-isolation` ficou verde. Não houve outra chamada real
conhecida depois dessa correção.

## Limites e pendências

- A coordenação protege entradas do kit; não contém edição direta externa, adulteração da área do
  lock, interferência privilegiada nem morte do próprio supervisor.
- Linux 5.3+ com procfs, syscalls pidfd permitidas (inclusive seccomp) e Python 3.9+ são requisitos dos comandos coordenados.
- Processo em estado ininterruptível não pode ser morto por um prazo em userspace; a posse não é
  liberada antes do reap.
- Itens de backlog marcados como resolvidos continuam no `TODO.md` até o merge, conforme a regra
  de fechamento. Nenhum item foi removido nesta entrega.
- Não houve mudança de agente, missão de produção, push, publicação ou merge.
- A revisão integral e seus deltas estão aprovados, e a suíte final em `d12ace4` passou.
  A certificação comportamental dos 373 mutantes e seu carimbo permanecem pendentes; não há
  correção funcional aberta.

## Preenchimento após a certificação

Preencher este bloco somente com a saída real produzida pelo controlador, depois da revisão e de
eventuais consertos:

- **Revisão integral:** concluída com três Important; re-revisão aprovou F1/F2/F3 em `d12ace4`, sem novos achados.
- **Comando e rc da certificação:** pendente.
- **Suíte no snapshot certificado:** pendente.
- **Score de mutação:** pendente (`373` é o censo, não um resultado de detecção integral).
- **Carimbo e chave de conteúdo:** pendente.
- **Evidência bruta:** pendentes `/tmp/sdd-reliability-certification.json`,
  `/tmp/sdd-reliability-certification.log` e o diretório exclusivo de logs dos mutantes.
- **Pendências finais ou desvio da matriz:** pendente.
