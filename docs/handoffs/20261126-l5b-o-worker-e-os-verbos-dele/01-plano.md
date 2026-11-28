---
missao: 20261126-l5b-o-worker-e-os-verbos-dele
data: 2026-11-26
---

# Plano — O worker e os verbos dele

## Contexto verificado (não re-descobrir)

Comandos relativos partem de `/home/joruge/.codex/worktrees/879b/sdd_agents`. O checkout primário é `/home/joruge/repos/sdd_agents`. A campanha autorizadora fica em `docs/superpowers/campaigns/20261117-zerar-as-issues` **do primário**. O worktree da L5 é `/home/joruge/repos/sdd_agents-l5`.

| Medição | Resultado observado |
|---|---|
| `git branch --show-current` e `git rev-parse --short HEAD` | `plan/l5b-provisorio`, `b75951e`. `git rev-parse --short origin/main` também deu `b75951e`. |
| `git rev-parse --short fix/l5-saida-humana-e-contrato-do-runner` e `git merge-base HEAD fix/l5-saida-humana-e-contrato-do-runner` | Head local da L5 `ed5bb47`. Ancestral comum `a6fff8e9993aac14a80bd9c9bfb244e0c2478743`. `git merge-base --is-ancestor fix/l5-saida-humana-e-contrato-do-runner origin/main` saiu 1. |
| `rg -n '^### L5b|^### L5c|^\| L5b ' docs/superpowers/campaigns/20261117-zerar-as-issues/campaign.md` | Linha 38, lote L5b com 18 itens e teto `-`. Seção L5b na 153, próxima seção na 180. Os títulos coincidem com a seção lida no primário. |
| `head -10 /home/joruge/repos/sdd_agents/docs/superpowers/campaigns/20261117-zerar-as-issues/{campaign,delegation}.md` | `codex`, `gpt-6.2-astra`, `gpt-6.2-sol`, `full`, `all`, validade `2026-11-28 18:00`, US$ 60 por missão, US$ 500 por campanha, `allow_unknown_cost: true`, assinatura `2026-11-26 16:57 755b8f93b2d8`. São valores lidos, não uma concessão válida para um ato futuro. O `level` neste sandbox retornou `assisted — unread` porque não pôde criar a cópia temporária dos termos. |
| `rg -n 'ahead plan|Wait on that PID|PHASE_ENGINE=codex sdd preflight|bring the base in' commands/sdd-worker.md` | Linhas 80, 196, 206 e 243. Já há instrução de preflight para Codex. O procedimento geral espera pelo PID e o ato `review` incorpora a base antes de consultar o delta. |
| `rg -n 'ahead plan' bin/sdd-worker tests/check-worker.sh` | `bin/sdd-worker:1305` produz a segunda linha. Os casos em `tests/check-worker.sh:1634` e `:1641` medem a saída para `run` e `review`. |
| `rg -n 'planner already exists|sdd-codex-planner|flock|coordination.py' bin/sdd-plan-codex` | O relay registra a sessão no Git dir do worktree, usa lock por missão, recusa segundo `start` e coordena `finish`. Isso protege um worktree já escolhido. Antes de `finish`, `next` ainda pode encontrar o lote sem `00-missao.md`. |
| `rg -n 'codex_config_unchanged|config_reload$' bin/sdd` | O laço Codex verifica a impressão digital do arquivo na linha 10678 e volta a verificá-la antes de uma tentativa na 11133. O outro caminho chama `config_reload`. A mudança de config em Codex já interrompe a invocação. |
| `rg -n 'CODEX_PHASE_MODEL' config/schema.md` | Linha 254, EXEC Codex usa Sol `medium`, QA e REVIEW usam Sol `xhigh`. `rg -n '^phase_(model|effort)\(' bin/sdd` localiza a seleção em 3165 e 3184. |
| `git diff --stat HEAD...fix/l5-saida-humana-e-contrato-do-runner -- bin/sdd-worker bin/sdd tests/check-worker.sh tests/check-mutation.sh TODO.md` | Os cinco arquivos têm mudanças na L5. `git diff -U0 HEAD...fix/l5-saida-humana-e-contrato-do-runner -- bin/sdd-worker` mostra `GIT_OPTIONAL_LOCKS=0` na leitura de `dirty` do `pr-ready`. Preservar a propriedade ao mexer nas sondas. |
| `git diff --name-only HEAD...fix/l5-saida-humana-e-contrato-do-runner` | Entre as demais superfícies compartilhadas estão `commands/sdd-worker.md`, `config/schema.md`, `docs/pipeline.md`, `docs/failure-modes.md`, `docs/finding-prs.md`, `templates/pr-body.md`, templates do TODO, `tests/check-coordination.sh`, `tests/check-preflight.sh`, `tests/check-todo.sh`, `tests/health-baseline.txt`, `README.md` e `KAIZEN_LOG.md`. |

### Correspondência individual

O comando para recuperar cada âncora é `rg -nF -- '<título integral copiado da seção L5b, sem o ◆>' TODO.md`. O cruzamento local exato devolveu, na ordem da fila, as linhas abaixo. A fonte de número e estado foi a resposta do relay a `gh issue list --repo j0ruge/sdd_agents --state all --limit 1000 --json number,state,title` (320 issues). Todos os 18 pares estavam `OPEN`. A linha do TODO aponta para o problema e sua origem. Um número de PR citado no corpo do item é evidência histórica, não a issue desse item.

| Issue | Linha do TODO | Comportamento a verificar | Incremento |
|---|---:|---|---|
| #419 ◆ | 95 | Corpo da revisão, pedido de alteração sem inline e `local/ci` | I8–I9 |
| #420 | 104 | Quem responde e resolve thread com evidência | I9 |
| #421 | 147 | Gasto de missão fora da base e sem worktree | I3 |
| #424 | 173 | Mutação que realmente admite não ancestral | I7 |
| #425 | 181 | Nota reprovada pelo motivo correto em árvore limpa | I7 |
| #427 | 345 | Valor de lançamento exportado para filho do config | I2 |
| #428 | 353 | Validade relida no instante de conceder | I2 |
| #429 | 361 | Enumeração integral com separadores NUL | I1 |
| #430 | 370 | PR próprio além de página cheia de forks | I6 |
| #431 | 377 | Consentimento assistido vinculado ao SHA | I10 |
| #432 | 385 | PR de pós-merge e situação de sua revisão na retomada | I12 |
| #433 | 393 | Pager e journal recebem a linha original | I5 |
| #434 | 401 | Teto da missão após alteração do config | I4 |
| #448 ◆ | 534 | Entrada de lote fora da fila assinada | I12 |
| #473 | 543 | `review-base` e merge desnecessário da base | I11 |
| #474 | 552 | Corpo do PR contém as escolhas efetivas do grill | I10 |
| #477 | 584 | Preflight efetivo antes do lançamento | I13 |
| #478 | 591 | Esgotamento de fase distinguido do teto de missão | I5 |

**Revalidação em 26/11.** O GitHub confirmou o merge de [#518](https://github.com/j0ruge/sdd_agents/pull/518) no commit `8a56249`, incluído em `origin/main`. O worktree foi avançado até esse SHA e preservou o rascunho e a ADR 0027. Os 18 números da matriz continuam abertos no GitHub e têm título correspondente no TODO atualizado. O diff nos verbos do worker traz a leitura do índice sem reescrita em `pr-ready`, e a instrução de lançamento continua distinta do disparo de planejamento antecipado de I14. O pré-voo Codex da rota atual permanece como controle de I13. A validação comportamental está no aceite. A branch de execução é `fix/l5b-o-worker-e-os-verbos-dele`.

## Arquitetura da mudança

**Bloqueio prévio à aprovação e ao EXEC.** O relay pode materializar os três arquivos agora. O orquestrador espera o merge real da L5 no repositório correto, identifica seu PR, head e merge commit pelo GitHub e atualiza `origin/main`. Confere que o merge commit pertence à base e integra a base somente neste worktree, preservando os arquivos de planejamento e a branch `plan/l5b-provisorio`. Não incorporar a branch em publicação como substituto do merge. Recalcular o diff, ler as regras efetivamente integradas da ADR 0025 e do TODO, rever as âncoras, a matriz das 18 issues, as superfícies compartilhadas e os checks. Registrar os SHAs e a disposição de cada item no aceite. Se algo já veio corrigido, provar pelo caminho público, retirar a duplicação e revisar a tabela. Se um conflito alcançar código, aplicar a parada `conflict` da campanha e devolver a decisão prevista na delegação.

O relay aloca a ADR com `sdd adr new --slug worker-campaign-evidence --spec docs/handoffs/20261126-l5b-o-worker-e-os-verbos-dele/00-missao.md`, escreve o corpo, vincula o caminho no frontmatter e confere `sdd adr check --mission 20261126-l5b-o-worker-e-os-verbos-dele --phase plan`. A proposta complementa a ADR 0022: (1) uma instrução escrita identificável dá ao orquestrador a responsabilidade de iniciar o plano assim que a execução do predecessor estiver confirmada, sob a delegação já existente; (2) o ato `review` produz a evidência `local/ci` e o tratamento rastreável dos achados que passam a compor a régua de merge. Manter no texto as alternativas discutidas, o custo de publicar um status por head e a compatibilidade das campanhas sem pedido. A L5 também toca o diretório de ADRs. O número vem do alocador.

Antes da aprovação medir, no worktree integrado, `tests/check-checkpoint.sh --check <checkpoint>` e `tests/check-checkpoint.sh --red <checkpoint>` pelo caminho do kit. Esperar a última linha do `--red`, sem disputar recursos com uma execução ativa. Todo check pendente precisa imprimir um antes diferente do esperado pelo motivo previsto. Uma falha do ambiente ou uma suíte que nem entrou nos casos invalida a medição. Colher também a saída integral dos sensores para distinguir contagem zero de erro de infraestrutura. Repetir a validação se a base mudar. Só depois, consultar novamente `budget` e `allows approve --mission`, registrar o aceite e usar `sdd approve` pelo gate regular. Repetir as consultas pertinentes no lançamento. Derivar a autorização sempre no checkout primário; nenhum agente assina.

**Fronteira de execução.** O `bin/sdd-worker` continua respondendo sobre orçamento, permissão, fila e prontidão. A sessão orquestradora dispara o ato e guarda a referência para retomá-lo. O relay usa Astra; o runner recebe `PHASE_ENGINE=codex`, `CODEX_PHASE_MODEL=gpt-6.2-sol` e o `BUDGET_MISSION_USD` obtido naquele lançamento. EXEC é Sol `medium`, QA e REVIEW são Sol `xhigh`. A rodada Codex do worker também usa Sol `xhigh`. A autorização para custo real indisponível só vale enquanto os termos assinados a concederem. Respeitar subtotais conhecidos, estimativas separadas, teto por missão, saldo da campanha e pager. Nenhuma nova chave de delegação para planejamento antecipado.

## Incrementos

Executar em ordem pelo `sdd run`, um commit de produto por incremento. O comando exato de cada Check está na linha homônima do `checkpoint.md`. A saída inteira esperada é `1`. O nome em inglês depois de `^  ok    ` identifica uma asserção de comportamento que só pode ser emitida quando todos os casos descritos para a linha passarem. Não imprimir sucesso pelo mero fato de o teste existir. Para cada fatia, escrever o caso, colher a falha pelo motivo previsto, aplicar a menor mudança e repetir, incluindo um controle positivo. A suíte integral deve também sair zero.

**Primeira sessão após o aceite.** Entrar no worktree acima e confirmar branch, SHA integrado e ausência de outro dono com `sdd status 20261126-l5b-o-worker-e-os-verbos-dele --no-gates`. Para I1, abrir `checkouts_of`, seus consumidores e o fixture de worktrees de `tests/check-worker.sh`. Criar no repositório descartável do sensor um worktree com quebra de linha no meio do nome, declarar ali a única missão do lote e exercitar `budget`, `level` e `next`. A falha inicial é perder essa missão ou seu pager. Adicionar o mundo em que Git produz parte da lista e falha, antes de trocar o leitor. Manter arquivos e configurações de teste dentro do fixture.

### I1 — Inventário de worktrees (#429)

Em `bin/sdd-worker`, consumir `git worktree list --porcelain -z` preservando os bytes do caminho e o rc do produtor. Evitar armazenar NUL em variável Bash. Incluir as leituras do primário por `codex-plan` e `codex-run` e seguir o caminho até o consumidor, inclusive espaços, quebra de linha e falha após saída parcial. Usar o requisito de capacidade somente nos atos dependentes. `README.md` e `docs/pipeline.md` explicam o diagnóstico. Sensor durável no `check-worker.sh`, I1 mede inventário completo e recusa sem concessão. Reverter o commit restaura o leitor anterior.

### I2 — Configuração e validade (#427, #428)

Em `config_key`, exportar no subshell o valor de lançamento fornecido antes de carregar o config. O mundo diferencial usa `bash -c` no config para ler o teto que o runner receberia. Em `effective_level`, conferir expiração de novo imediatamente antes de publicar qualquer nível acima de `assisted`. Usar o relógio controlado do fixture para vencer entre leitura do conjunto e decisão, sem `sleep`. O sensor I2 mede o valor no filho, o instante exato da expiração e uma concessão ainda válida. Reverter como unidade sem mudar o formato dos termos.

### I3 — Contabilizar a missão cujo worktree saiu (#421)

Em `bin/sdd`, identificar a campanha a partir do frontmatter da missão ao persistir os eventos de gasto e de lançamento relevantes, incluindo `session` e `close` onde houver cobrança. Em `cmd_budget`, unir atribuição explícita por repositório/campanha e a descoberta legada por missão, com uma contagem por evento. Preservar os recibos de PLAN Codex, lançamentos incompletos, custos desconhecidos e a separação de estimativas. Testar missão removida antes de chegar à base, missão ainda visível por ambos os caminhos, homônima em outro repo, linha anterior sem campanha e registro alheio. Declarar a limitação histórica: sem worktree, artefato ou campo que identifique uma linha antiga, não atribuir gasto por palpite. I3 mede o valor total e a decisão do teto via `budget`. Campo aditivo, reversão do leitor/escritor sem migração destrutiva do ledger.

### I4 — Proteger o teto entre sessões (#434)

Reusar a validação de teto já feita pelo worker e manter `codex_config_unchanged` antes da próxima sessão ou retry. No caminho delegado, configuração de US$ 100 ou `0` para teto assinado de US$ 60 produz parada com caminho e valores antes do despacho. O worker compara a configuração sob a verificação autorizada, sem tentar executar a alteração dentro da invocação interrompida. Para mudança restrita à redução para US$ 40, revalidar termos, orçamento e preflight e abrir nova invocação somente se ainda houver saldo. Se houver alteração adicional, procedência incerta ou repetição sem progresso, deixar a parada visível. Exercitar também o caminho delegado que relê o config; preservar a precedência de missões avulsas. Usar `tests/check-codex-runner.sh` com adaptador falso que registra invocações e teto efetivo. I4 mede zero sessões indevidas e a primeira sessão autorizada com o teto menor. Atualizar `config/schema.md` e a delegação modelo. Reverter o commit conserva a guarda anterior.

### I5 — Conservar o motivo da parada (#433, #478)

No procedimento `run` e nas paradas de `commands/sdd-worker.md`, capturar saída e rc no ato que decidiu parar, antes de esperar ou chamar o pager. Usar a mesma evidência no journal e em `SDD_GATE_WHY`. Para `budget-exhausted`, distinguir teto de fase e de missão pela evidência produzida pelo runner, mantendo compatibilidade com o ledger existente. Mensagem ilegível é causa indeterminada. Preservar a regra de não paginar duas vezes uma parada que o runner já notificou. Fixture faz a segunda leitura hipotética devolver valor diferente e verifica uma consulta real, a mesma linha nos dois destinos e os dois tetos corretamente classificados. I5 cobre o procedimento público com verbos e pager falsos. Reverter juntos produtor e consumo do diagnóstico.

### I6 — Encontrar o PR próprio entre forks (#430)

Em `pr_states`, consultar todas as páginas necessárias com filtro de repositório e branch corretos, ou declarar leitura incompleta se houver limite efetivo. Verificar erro de página intermediária. `next` só pode concluir ausência após leitura completa. Fixture do `gh` põe 30 PRs de fork antes do PR próprio e cobre PR próprio aberto, mergeado e inexistente. I6 mede o ato derivado e o retorno de leitura indisponível. Reverter o commit não altera dados persistidos.

### I7 — Tornar os probes discriminantes (#424, #425)

Em `tests/check-worker.sh`, usar `land` após editar a rodada nos casos de B, A−, linha recuada e critério ausente. Exigir a causa específica do leitor e usar um caso separado para `dirty`. Em `tests/check-mutation.sh`, `mut_WORKER_range_ancestry_unchecked` deve permitir efetivamente um não ancestral, conservando a falha operacional de Git. Provar que o sensor o mata por aceitar a ancestralidade inválida, sem depender de mera troca de texto. Executar também o controle verde e `tests/check-mutation.sh --only WORKER_range_ancestry_unchecked check-worker.sh` pelo `bin/sdd-codex --sandbox-check` conforme o contrato do kit. I7 mede mundos independentes; o relatório da mutação é evidência adicional. Preservar a leitura sem locks opcionais introduzida na L5. Reversão restrita aos testes e ao mutante.

### I8 — Publicar e ler `local/ci` (#419, primeira parte)

No ato `review`, terminar os commits da rodada, publicar o head, obter o SHA remoto e conferir a igualdade com a árvore limpa local. Rodar `TEST_CMD` nesse SHA e publicar o status `local/ci` nesse mesmo SHA, com resultado coerente e autoria do produtor esperado. Uma mudança posterior exige nova suíte e publicação. Falha de escrita ou permissão indisponível deixa diagnóstico e bloqueia o merge. Em `cmd_pr_ready`, exigir o status aplicável mais recente do contexto e do SHA corretos. Falta, pendência, falha e sucesso de outro SHA reprovam. Preservar recibo do Codex, oito critérios e demais gates. Ajustar `docs/pipeline.md`, probes e a antiga mutação que exigia documentar essa lacuna. I8 usa `gh` falso para observar escrita, leitura e mudança de head. Reverter produtor e gate juntos.

### I9 — Tratar corpo de revisão e threads (#419, conclusão; #420)

O ato `review` enumera revisões e threads com paginação. Distingue comentário informativo, achado acionável e pedido de alteração vigente, inclusive sem inline. Registra a disposição com ID ou URL da revisão, identificação do achado e commit/evidência verificável na rodada. Um novo achado ou edição relevante invalida a disposição antiga. Responder ao thread corrigido citando o commit, verificar o resultado e resolver apenas os threads de bot cujo achado foi tratado. Pedido vigente precisa de retirada, substituição ou tratamento autorizado no GitHub. Caso ambíguo ou humano fica pendente. `pr-ready` lê evidência completa e recusa pendência, resposta ilegível ou página faltante. I9 contrasta corpo com achado, corpo informativo, solicitação vigente/substituída e thread com/sem correção. Atualizar os limites antigos nos sensores e em `docs/pipeline.md`. Reverter ato e condição de merge juntos.

### I10 — Vincular escolhas e consentimento ao merge (#431, #474)

O ato `pr` escreve no corpo uma entrada identificável por decisão e resposta da missão materializada, incluindo as escolhas ◆. Em `pr-ready`, comparar conteúdo e identidade de cada resposta, preservando respostas repetidas em perguntas distintas, texto escapado e os formatos `recommended` e `other` já gravados. Contagem ou heading isolado não provam correspondência. No fluxo assistido, o sim só vale para a mesma campanha, lote, missão, PR, comando e SHA apresentado. Revalidar `budget`, `allows` e `ready <sha>` e usar `--match-head-commit`; se o head mudou, colher novo sim. I10 troca resposta mantendo a contagem e troca SHA mantendo o número do PR. Superfícies: `bin/sdd-worker`, `commands/sdd-worker.md`, `templates/pr-body.md` se necessário e `tests/check-worker.sh`. Reverter em conjunto a escrita e a leitura da seção.

### I11 — Preservar o delta elegível (#473)

No ato `review`, consultar o estado atual de mergeabilidade antes de incorporar a base. Em PR `MERGEABLE`, revisar o head real com `sdd review-base`; com conflito, seguir a rota de integração autorizada e medir de novo; estado desconhecido ou `gh` indisponível exige nova leitura. Conservar a rodada inteira quando `review-base` a pedir, os gates de integração e o `pr-ready` final sobre o mesmo head. Evitar mudar `review_base_line` se o procedimento resolver o caso. I11 usa shims para registrar a ordem, a ausência de merge desnecessário e o caminho de conflito. Reversão isolada no procedimento e seu sensor.

### I12 — Entrada na fila e retomada pós-merge (#448, #432)

Documentar e testar o procedimento que o worker executa. Para lote extra, preparar em checkout separado a posição, o teto e, quando restritivo, o campo `lots`. O dono vê os termos e assina. Publicar fila e delegação juntas pelo fluxo normal. Até a integração, consultar a fila vigente e conservar o lote ativo. Para `postmerge`, persistir primeiro o merge efetivo; quando o PR de acompanhamento existir, acrescentar número, link e estado de revisão. Uma queda entre os atos precisa permitir achar o PR já aberto ou abrir o único que falta. Terminar a revisão pendente antes de `next`, observando os gates existentes. I12 cobre termos antigos ainda válidos, termos alterados sem assinatura recusados, nova fila assinada, queda antes/depois da abertura e retomada sem PR duplicado. Reverter a mudança no procedimento; nunca desfazer registros reais do journal.

### I13 — Preflight no caminho real de lançamento (#477)

O procedimento já exige `PHASE_ENGINE=codex sdd preflight`. Reaproveitar essa rota e a skill instalada; consolidar o ponto de lançamento para que todo `run` faça o preflight no worktree e engine da missão antes de criar processo. Para o kit em Codex exigir rc 0 e `TEST_CMD ran green`. A suíte é o custo previsto. Se a integração mostrar que um caminho já cumpre tudo, acrescentar somente a comprovação que faltar. I13 usa executáveis falsos que registram cwd, engine, ordem e PID: preflight falho produz zero launches; sucesso produz um, com teto validado. Reverter sem duplicar preflight no runner e no orquestrador.

### I14 — Disparar e retomar o PLAN antecipado

Ligar a ação ao procedimento que realmente orquestra, em `commands/sdd-worker.md`, consumido por `skills/sdd-worker/SKILL.md`. Entre lançar o runner e esperar seu PID, confirmar que ele adquiriu o checkout para a missão esperada por meio da informação de ownership do runner. `next` anunciar `run` ou a existência de um PID isolado é insuficiente. Usar a segunda linha `ahead plan <lote>` somente para o sucessor indicado, com referência recuperável à instrução original do dono para aquela campanha no handoff. Para esta campanha, o pedido e as decisões 1 e 7 da missão fornecem essa referência. Handoff inexistente, ambíguo ou sem pedido identificável conserva a sugestão.

Antes do disparo reler orçamento e `allows ... plan --lot`; para Codex, usar o primário canônico e a guarda `codex-plan` que o relay aplica a cada turno. Reservar/reutilizar uma associação única de campanha, lote, missão e worktree antes de chamar `start`. Reaproveitar o registro e o lock do relay. Duas retomadas não podem escolher worktrees distintos para o mesmo lote: usar destino estável e criação exclusiva, identificar o dono de uma reserva existente e parar em caso de ambiguidade. Se o relay já existe, usar `status`, `recover` somente para turno interrompido, `answer` para a pergunta pendente e `finish` quando couber. Registrar o caminho antes que seja necessário retomar; se o runner estiver protegendo o primário, usar a retenção temporária de journal já prevista. Nunca escrever no checkout em execução. O planner adiantado termina em rascunho. A espera pelo PID original, seus erros e suas transições continuam sob responsabilidade da sessão. Ao retomar durante uma revisão, reconciliar o sucessor já iniciado com o mesmo procedimento.

**Forma mínima verificável:** colocar o trecho executável de despacho no caminho normal indicado pelo comando, usando os verbos e o relay existentes. Se o procedimento em Markdown não puder ser exercitado diretamente, extrair apenas esse trecho em auxiliar do orquestrador, chamado pela entrada normal e pelo teste. Um grep sobre a nova instrução ou outro teste apenas do texto de `next` não fecha I14. O sensor usa runner e relay falsos com trilha de chamadas: runner A ainda vivo → PLAN de B em checkout distinto → espera de A. Incluir duplicação concorrente, recuperação antes de `00-missao.md`, runner que morre antes de adquirir ownership, termo vencido, orçamento insuficiente, ausência de pedido e fim de fila. Após merge simulado de A, a aprovação de B só ocorre depois de revalidar base, plano e orçamento. Provar que a mesma regra conduz B ao único sucessor e termina em `done`. Reverter apenas a ligação automática mantém a rota manual existente.

**TODO e documentação em cada commit.** I1–I14 reancoram, no próprio commit que move o símbolo, todo item aberto afetado, inclusive de outros lotes. Usar a coluna de incremento da matriz para os 18 itens e procurar consumidores e âncoras vizinhas com `rg -nF -- '<símbolo>' TODO.md` antes de editar. Rodar `tests/check-todo.sh --anchors TODO.md` depois de cada fatia. Marcar resolução somente com evidência verificável pela regra que a L5 integrar. A remoção do item e o fechamento de issue seguem o ciclo pós-merge. Não baixar catraca para esconder achado ainda aberto. DOCS atualiza o procedimento público em inglês, a gaveta da frente do worker onde seu estado mudar e o Kaizen em português, com medidas reais.

## Riscos e não-feitos

| Risco | Probabilidade | Mitigação |
|---|---|---|
| A L5 ou uma correção recente já cobrir parte de uma issue ainda aberta | Alta | Reconciliar artefatos e comportamento na base integrada antes da aprovação. A medição de origem e a sobreposição estão no contexto acima. |
| Um relay iniciado ainda não ter missão materializada | Alta | A reserva do sucessor deve preceder o `start`. A prova concorrente de I14 está pendente; não aprovar com a identidade indefinida. |
| O token usado por `review` não conseguir publicar status ou resolver thread | Média | Validar as permissões do produtor no fluxo autorizado. Falha mantém o PR pendente com causa identificada. Fixtures não demonstram permissão real no GitHub. |
| Somar duas vezes ou esquecer histórico sem identidade comprovável | Média | Preservar linhas antigas, testar atribuição por ambos os caminhos e expor a parte histórica irrecuperável no handoff. |
| Medir vermelho por erro de ambiente ou exceder o orçamento da missão | Média | Ainda falta executar os sensores na base integrada. Exigir suíte que entrou nos casos, pré-voo verde e reconsulta de orçamento antes de atos e depois de esperas. Ao atingir limite, registrar a parada e o incremento pendente. |

## Verificação end-to-end

1. O relay materializa e valida o checkpoint. Antes de aprovar, o orquestrador registra merge da L5, base integrada, correspondência atualizada das issues, ADR alocada e `--red` de todas as linhas ainda pendentes. Uma mudança material volta ao planner. O `--check` executado neste planejamento em descritor de memória retornou `14 row(s), 14 under the anchor rule, none blind`, rc 0. O vermelho comportamental não foi executado neste sandbox.
2. No worktree integrado e autorizado, executar `PHASE_ENGINE=codex sdd preflight` e a suíte normal `tests/run-all.sh`. Recolher rc e resultados de `tests/check-worker.sh`, `tests/check-codex-runner.sh`, do controle/mutante I7 e dos checks individuais. Usar só o mutante solicitado. Não invocar `sdd health` como operação da campanha.
3. Em fixtures, percorrer a fila com pelo menos três lotes. Mostrar a ordem dos lançamentos, os checkouts, o único relay por sucessor, retomada no meio do grill, aprovação posterior à revalidação e parada em `done`. Repetir com orçamento negado e assinatura vencida. Em ambos, demonstrar zero lançamentos proibidos.
4. QA percorre as jornadas CLI de planejamento, parada e merge com Sol `xhigh`. REVIEW verifica orçamento histórico, evidência no head, ownership, termos assinados e resultados por SHA. O PR lista as decisões do grill e a disposição dos 18 itens. Os atos reais de publicação, revisão, merge e pós-merge continuam sujeitos às permissões e à régua da campanha.
