# Notas de execução — O worker e os verbos dele

> **Append-only.** Uma linha por evento; nunca reescreva o arquivo, nunca o releia inteiro.
>
> Este arquivo nasceu em `20260904-a-dieta-de-contexto`, separado do `checkpoint.md` por medição:
> as notas eram **69% daquele arquivo** (67 166 B de 97 865 B em `20260901-o-revisor-so-acha`), e
> aquele arquivo era **44,7% de tudo que a missão releu** — 160 leituras, 1 114 571 B. Enquanto
> tabela e notas dividiam o arquivo havia um piso mecânico: em sessão headless o `Edit` exige um
> `Read` prévio, então toda sessão que atualizasse a tabela pagava o arquivo inteiro. Separadas,
> escrever nota é `>>` e custa **zero leitura**.
>
> O prompt de boot **inlina as últimas 10 notas** (`BOOT_NOTES_TAIL` no `bin/sdd`) e manda
> explicitamente **não abrir este arquivo**. Se você precisa de uma nota mais antiga, ela é
> história — e história se lê no `git log`, não no boot de toda sessão.

## Notas de execução

> Uma linha por evento relevante: bloqueio, decisão tomada, desvio do plano com justificativa.
> É o que a próxima sessão lê para não repetir um erro que já custou caro.


> **Toda vez que um humano precisou entrar na linha** — um `sdd retry`, um conserto à mão, um
> `BLOCKED` assumido — sai uma linha com o marcador `intervention:`. É a **narrativa** do que o
> humano fez. O **número** de intervenções o `sdd autonomy --by-mission` lê do ledger, em
> `launch(es)` (`run_id` distintos — cada `sdd run`/`sdd retry`), e imprime estas notas ao lado
> como `intervention note(s)`. Medido em 2026-08-28: a missão de três lançamentos tinha zero
> notas — o contador não pode depender de alguém lembrar de escrever; a narrativa, sim, e é a
> única fonte que diz o que o humano *fez*.
>
> ⚠️ O marcador é **inglês e minúsculo**, como `pending`/`done`/`blocked`: é contrato, não prosa.
> O texto depois dos dois-pontos vai no idioma do `OUTPUT_LANG`, como o resto deste arquivo.
> Só conta quando abre a linha — `intervention` no meio de uma frase é prosa e não é contado.
>
> Desde 2026-09-03 o **runner escreve a linha sozinho** quando é ele quem recebe a mão do humano —
> `sdd run --phase X`, `sdd retry`, `--budget-override` — **e só na volta que abre sessão** (uma
> volta parada antes dela, por PLAN, carimbo, teto ou no-work, não grava nota), e a commita sozinha,
> na hora, para a árvore chegar limpa ao gate da fase seguinte. A linha escrita à mão continua valendo para o que
> o runner não vê: conserto manual, `BLOCKED` assumido. Fase feita à mão tem comando:
> `sdd note-manual <missão> <FASE>` escreve a nota e a linha `manual` do ledger, que não gradua
> nada — escrita só aqui, a fase não existe para o ledger. `sdd approve` não
> escreve nenhuma: aprovar o plano é o gate humano desenhado, não uma entrada na linha. A nota
> diz o que o runner **sabe** ("forçada pela CLI"), nunca quem estava na CLI: outro agente com
> shell entra pela mesma porta, e o runner não distingue — medido em 2026-09-03.
>
> O exemplo abaixo mora **dentro** desta citação de propósito: o `>` quebra o casamento com
> `^[[:space:]]*-`, e sem ele o exemplo era contado verbatim — todo checkpoint recém-instanciado
> nascia devendo uma intervenção fantasma ao instrumento que mede autonomia. Copie a forma para
> fora da citação ao registrar uma intervenção de verdade.
>
> - intervention: <o que o humano teve de fazer> — <fase> — <custo, se houver>


- 2026-11-26 21:01 · `I1` · TDD em cópia descartável do HEAD: o sensor falhou quando o orçamento mostrou 0 missões e o next voltou a propor PLAN para L1. Com a correção, o sensor passou, inclusive com uma quebra de linha no fim do caminho e saída parcial do Git (rc 17). Na árvore da missão, tests/run-all.sh passou antes e depois (89 → 90 sondas do worker), e o Check imprimiu 1. As 100 âncoras do TODO passaram.
- 2026-11-26 21:37 · `I2` · No HEAD anterior, o filho do config recebeu o padrão de US$ 150 e os lotes com e sem teto concederam permissão no instante do vencimento (Check 0). Com a correção, o filho recebeu US$ 40, os dois lotes concederam um minuto antes e recusaram no vencimento (Check 1). tests/run-all.sh passou antes e depois, com 90 e 91 sondas do worker.
- 2026-11-26 22:17 · `I3` · No código anterior, o orçamento atribuiu US$ 58,00 depois da remoção dos worktrees e não parou no teto de US$ 107,00 (Check 0). Com a correção, reteve US$ 107,00 e parou no teto (Check 1), sem duplicar eventos nem atribuir registros legados sem evidência. Os testes também confirmaram os lançamentos e as sessões Codex, o `close` pago e a separação das estimativas. `tests/run-all.sh` passou antes e depois, com 91 sondas do worker.
- 2026-11-26 23:10 · `I4` · No HEAD anterior, o Codex parou sem identificar o teto assinado (Check 0), e o Claude delegado abriu outra sessão após a releitura. Com a correção, US$ 100 e zero não abriram outra sessão sob teto de US$ 60. Em Codex, a redução para US$ 40 exigiu nova invocação, config limpo no preflight e saldo. O Check deu 1 e `tests/run-all.sh` passou no worktree antes e depois. As 100 âncoras do TODO e as 1.015 do catálogo passaram.
- 2026-11-26 23:51 · `I5` · No código anterior, a segunda consulta trocou a linha enviada ao pager e o runner não publicou diagnósticos distintos para os dois tetos (Check 0). Com a correção, uma consulta alimentou diário e pager, os dois tetos foram classificados sem novo aviso e o ledger manteve `budget-exhausted`. Evidência ilegível ou ambígua ficou indeterminada. O Check deu 1 e `tests/run-all.sh` passou antes e depois, com 91 e 92 sondas do worker.
- 2026-11-27 00:28 · `I6` · Em cópia do HEAD anterior, 30 forks esconderam o PR próprio aberto ou mergeado e `next` sugeriu `run` mesmo na falha de uma página ou diante de uma lista truncada (Check 0). Com a correção, o PR aberto levou a `review`, o mergeado avançou a fila e só a ausência confirmada levou a `run`. A falha intermediária e o limite de 1.000 retornaram rc 3 sem ato (Check 1). `tests/run-all.sh` passou antes e depois, com 92 e 93 sondas do worker.
- 2026-11-27 01:15 · `I7` · A sonda falhou com as rodadas fora do commit (Check 0). No head limpo, separou B, A-, linha recuada, critério ausente e árvore suja (Check 1). Em cópia descartável, o mutante antigo só trocou a recusa por um erro de Git. O corrigido devolveu ready para um não ancestral (rc 0), e a sonda o pegou sem perder a recusa de um head não buscado. O sandbox interno não iniciou por erro no diretório do socket. O controle ficou verde e o catálogo pegou o mutante isolado no sandbox da sessão. tests/run-all.sh passou antes e depois, com 93 e 94 sondas do worker.
- 2026-11-27 01:36 · `I7` · Bloqueado na suíte de base do I8. `tests/run-all.sh` terminou com rc 1 e uma etapa vermelha. `tests/check-todo.sh --check` aceitou os 100 itens de `f7b8071` e recusou o `TODO.md` de `297a101`: as duas linhas avulsas `RESOLVED by f7b8071` nos itens #424 e #425 tiram a data da última linha e levam o segundo item a 9 linhas. Corrigir a posição dos marcadores no corpo dos itens e repetir a suíte antes de retomar. I8 segue pendente.
- 2026-11-27 02:31 · `I7` · Corrigida a posição dos dois marcadores de resolução de #424 e #425 no TODO. O check de formato passou e `--resolved TODO.md` confirmou os dois hashes. `sdd-codex --sandbox-check` validou as 94 sondas e o mutante `WORKER_range_ancestry_unchecked`: controle verde, mutante detectado. I7 voltou a concluído em `f7b8071`, com I8 pendente.
- 2026-11-27 03:30 · `I8` · No código anterior, `pr-ready` dava `ready` sem status ou com sucesso de outro SHA (Check 0). Com a correção, o `gh` falso confirmou a publicação de `pending` e do resultado no SHA testado, a recusa depois de trocar o head e a parada quando a escrita falha. O Check deu 1. `tests/run-all.sh` passou antes e depois (94 → 95 sondas do worker), com 100 âncoras no TODO e 1.016 no catálogo. Os mutantes `WORKER_local_ci_ignored` e `WORKER_blind_limit_dropped` foram detectados com os controles verdes.
- 2026-11-27 04:11 · `I9` · No HEAD anterior, o Check deu 0: o merge aceitava achado no corpo e pedido de alteração sem comentário em linha. O Check deu 1 com paginação completa, validação da disposição no head e resposta verificada antes de resolver thread de bot. Uma edição posterior invalidou a disposição, e a retomada não duplicou a resposta. tests/run-all.sh passou antes e depois, com 95 sondas do worker, 100 âncoras do TODO e 1.016 no catálogo. O GitHub foi simulado.
- 2026-11-27 04:52 · `I10` · No código anterior, trocar uma resposta ou uma identidade sem mudar a contagem ainda dava ready (Check 0). O ato pr publicou as escolhas materializadas e pr-ready recusou conteúdo divergente ou ilegível. No mesmo PR, o novo SHA exigiu novo aceite e o orçamento foi revalidado antes do merge com --match-head-commit (Check 1). tests/run-all.sh passou antes e depois (95 → 96 sondas do worker), com 100 âncoras do TODO e 1.017 no catálogo. O mutante WORKER_grill_body_unchecked foi detectado com o controle verde. O GitHub foi simulado.
- 2026-11-27 08:51 · `I11` · Em projeção de `bb76687`, a sonda detectou a integração da base antes de medir o delta (Check 0). No rascunho recuperado, ela também detectou a seleção de rodada com checkout sujo. Com a correção, o PR mergeável conservou o delta sem fetch nem merge. O conflito usou a base do PR e a nova leitura no head publicado conservou `full` quando indicado. Falha de fetch, HEAD alterado e evidência ilegível não abriram rodada (Check 1). `tests/run-all.sh` passou antes e depois, com 97 sondas do worker, 100 âncoras do TODO e 1.017 âncoras do catálogo. Os quatro arquivos iniciais pertenciam ao I11. O GitHub foi simulado.
- 2026-11-27 09:35 · `I12` · No procedimento anterior faltavam a rota da fila assinada e a retomada do PR de acompanhamento (Check 0). O Check deu 1 com os termos antigos válidos até a integração da proposta assinada. A retomada achou o PR existente pelo branch e recusou resultado ilegível, ambíguo, fechado ou redirecionado. O journal registra o merge antes da abertura e a revisão fica pendente antes de next. tests/run-all.sh passou antes e depois (97 → 98 sondas do worker), com 100 âncoras do TODO e 1.017 do catálogo. O GitHub foi simulado.
- 2026-11-27 10:17 · `I13` · No bloco anterior, o sdd falso registrou run sem preflight, inclusive em casos de recusa (Check 0). Com a correção, o pré-voo usou o worktree e o engine da missão. Falha, ausência de evidência da suíte no kit com Codex e mudança do config na retomada não produziram PID. O sucesso lançou uma vez com o teto validado pelo orçamento (Check 1). tests/run-all.sh passou antes e depois (98 → 99 sondas do worker), com 100 âncoras do TODO e 1.017 no catálogo. Nenhuma campanha real foi lançada.
- 2026-11-27 10:58 · `I14` · No procedimento anterior faltava a rota executável antes da espera (Check 0). A fixture confirmou um só relay no worktree reservado, retomada antes de `00-missao.md`, zero disparos sem pedido, dono, permissão, orçamento ou sucessor e avanço até `done` após validar o merge, a base e o plano (Check 1). `tests/run-all.sh` passou antes e depois (99 → 100 sondas do worker), com 100 âncoras do TODO e 1017 no catálogo. Não houve lançamento real.
- 2026-11-27 11:24 · `F1` · BUG-01 do handoff de QA. Na corrida entre duas retomadas, o relay foi iniciado uma vez, mas a retomada que estava no orçamento recusou a reserva já válida. A regressão CLI ficou vermelha.
- 2026-11-27 11:24 · `F2` · BUG-02 do handoff de QA. A sonda I11 publicou OK após abortar 13 cenários com kit: unbound variable. A regressão exige carregar o bloco e reexecutar a jornada de revisão.
- 2026-11-27 12:30 · `F1` · No código anterior, a retomada detida no orçamento recusava a reserva concorrente e o Check deu 0. Em `5ac9b42`, o Check deu 1 com a trilha `start, wait, status, wait`. A sonda incorporada ao worker confirmou também a recusa de branch sem reserva e checkout divergente. A jornada simulada percorreu três lotes até `done`. `tests/run-all.sh` passou antes e depois (100 → 101 sondas do worker), com 100 âncoras no TODO e 1.017 no catálogo. Nenhum relay real foi iniciado.
- 2026-11-27 13:13 · `F2` · Em `b40040c`, o Check deu 0 e a suíte publicou falso verde apesar de 13 erros de carregamento. Em `9837b00`, a sonda selecionou `review_scope`, executou os 13 cenários e rejeitou tanto o carregamento interrompido com saída 0 quanto a rodada `full` indevida. Os Checks F1 e F2 deram 1. `tests/run-all.sh` passou antes e depois, com 21 etapas, 101 sondas do worker, 100 âncoras no TODO e 1.017 no catálogo. O GitHub foi simulado.
- 2026-11-27 13:56 · `QA` · F1 (5ac9b42) e F2 (9837b00) retestados em ada1e29. Os dois Checks deram 1 e tests/run-all.sh passou em 21 etapas. Planejamento e retomada, parada e revisão/merge passaram nas fixtures. Nenhum achado novo nem decisão humana em aberto.
- 2026-11-27 14:33 · `R1` · REVIEW r1, achado #1. A publicação ficou verde com zero execuções e o consumidor retornou ready no mesmo SHA.
- 2026-11-27 14:33 · `R2` · REVIEW r1, achado #2. O relay recebeu o lote, mas o prompt não identificou a fila que só existia no primário.
- 2026-11-27 14:33 · `R3` · REVIEW r1, achado #3. O relay iniciou mesmo com a seção do pedido ausente ou retirada durante o orçamento.
- 2026-11-27 14:33 · `R4` · REVIEW r1, achados #4 e #5. Aprovação informativa bloqueou o PR e metadados ilegíveis produziram vereditos divergentes.
- 2026-11-27 15:12 · `R1` · R1 sabotage: retorno ao bloco original → sonda vermelha: local ci refuses success without a completed test command
- 2026-11-27 15:12 · `R1` · R1 sabotage: sem execução isolada do TEST_CMD → sonda vermelha: local ci refuses success without a completed test command
- 2026-11-27 15:12 · `R1` · R1 sabotage: rc da suíte substituído por zero → sonda vermelha: merge requires local ci on the tested head
- 2026-11-27 15:12 · `R1` · R1 sabotage: rc escrito na saída comum → sonda vermelha: merge requires local ci on the tested head
- 2026-11-27 15:12 · `R1` · R1 sabotage: canal do rc ligado à saída comum → sonda vermelha: merge requires local ci on the tested head
- 2026-11-27 15:12 · `R1` · R1 sabotage: saída do comando descartada → sonda vermelha: local ci refuses success without a completed test command
- 2026-11-27 15:12 · `R1` · R1 sabotage: entrada do chamador chega à suíte → sonda vermelha: local ci refuses success without a completed test command
- 2026-11-27 15:12 · `R1` · R1 sabotage: saída do chamador não reservada → sonda vermelha: merge requires local ci on the tested head
- 2026-11-27 15:12 · `R1` · R1 sabotage: recibo vazio aceito → sonda vermelha: local ci refuses success without a completed test command
- 2026-11-27 15:12 · `R1` · R1 sabotage: condição do subshell invertida → sonda vermelha: merge requires local ci on the tested head
- 2026-11-27 15:12 · `R1` · R1 sabotage: config herda canal do recibo → sonda vermelha: local ci refuses success without a completed test command
- 2026-11-27 15:12 · `R1` · R1 sabotage: suíte herda canal do recibo → sonda vermelha: local ci refuses success without a completed test command
- 2026-11-27 15:12 · `R1` · R1 sabotage: diagnóstico incompleto ocultado → sonda vermelha: local ci refuses success without a completed test command
- 2026-11-27 15:12 · `R1` · R1 sabotage: recusa incompleta convertida em sucesso → sonda vermelha: local ci refuses success without a completed test command
- 2026-11-27 15:12 · `R1` · Em `f04609e`, o config saía com zero sem executar a suíte, mas publicava sucesso e liberava o mesmo SHA. Em `297f072`, esse caso conservou `pending` e bloqueou `pr-ready`. As execuções reais da fixture publicaram falha ou sucesso, uma vez cada. O Check deu 1 e `tests/run-all.sh` passou antes e depois em 21 etapas (101 → 102 sondas do worker, 100 âncoras no TODO e 1017 no catálogo). Duas âncoras do TODO acompanharam as linhas deslocadas. As 14 sabotagens usaram grupo próprio, teto de 45 s e 256 MiB por processo. A estrutura sintática foi revertida em bloco e a prosa foi conferida no procedimento e no pipeline. GitHub simulado.
- 2026-11-27 15:51 · `R2` · R2 sabotage: instrução de leitura removida → sonda vermelha: ahead planner receives the canonical queue outside its base (L2)
- 2026-11-27 15:51 · `R2` · R2 sabotage: caminho canônico trocado por relativo → sonda vermelha: ahead planner receives the canonical queue outside its base (L2)
- 2026-11-27 15:51 · `R2` · R2 sabotage: lote fixado em L2 → sonda vermelha: ahead planner receives the canonical queue outside its base (L3)
- 2026-11-27 15:51 · `R2` · Em `37ace76`, a jornada chegou ao primeiro turno de L2 sem apontar para a fila. Em `a83df3e`, o relay real com adaptador falso entregou o caminho absoluto e o lote para L2 e L3, sem cópia da fila nos checkouts reservados. A retomada de L2 devolveu a mesma pergunta sem novo turno. O Check deu 1. `tests/run-all.sh` ficou verde antes e depois em 21 etapas (102 → 103 sondas do worker e 1017 âncoras do catálogo). Os três mutantes rodaram em grupo próprio, com teto de 60 s e 256 MiB por processo, e o controle passou sob os mesmos tetos antes e após a restauração. Procedimento e pipeline conferidos. Sem chamadas reais ao Codex ou ao GitHub.
- 2026-11-27 16:33 · `R3` · R3 sabotage: indentação de código tratada como título → ahead planning refuses stale owner request references
- 2026-11-27 16:33 · `R3` · R3 sabotage: estado inicial da cerca indevidamente ativo → ahead planning refuses stale owner request references
- 2026-11-27 16:33 · `R3` · R3 sabotage: detecção de abertura de cerca desligada → ahead planning refuses stale owner request references
- 2026-11-27 16:33 · `R3` · R3 sabotage: abertura de cerca reduzida a três marcas → ahead planning refuses stale owner request references
- 2026-11-27 16:33 · `R3` · R3 sabotage: fechamento com delimitador de outro tipo aceito → ahead planning refuses stale owner request references
- 2026-11-27 16:33 · `R3` · R3 sabotage: fechamento de cerca com sufixo aceito → ahead planning refuses stale owner request references
- 2026-11-27 16:33 · `R3` · R3 sabotage: cerca válida não fecha → ahead planning refuses stale owner request references
- 2026-11-27 16:33 · `R3` · R3 sabotage: título em exemplo cercado incluído → ahead planning refuses stale owner request references
- 2026-11-27 16:33 · `R3` · R3 sabotage: normalização de título ignora caixa → ahead planning refuses stale owner request references
- 2026-11-27 16:33 · `R3` · R3 sabotage: normalização mantém marcadores finais → ahead planning refuses stale owner request references
- 2026-11-27 16:33 · `R3` · R3 sabotage: normalização mantém pontuação → ahead planning refuses stale owner request references
- 2026-11-27 16:33 · `R3` · R3 sabotage: normalização mantém espaços → ahead planning refuses stale owner request references
- 2026-11-27 16:33 · `R3` · R3 sabotage: inventário de títulos descartado → ahead planning refuses stale owner request references
- 2026-11-27 16:33 · `R3` · R3 sabotage: referência HTTPS válida descartada → ahead planning refuses stale owner request references
- 2026-11-27 16:33 · `R3` · R3 sabotage: caminho e fragmento não separados → ahead planning refuses stale owner request references
- 2026-11-27 16:33 · `R3` · R3 sabotage: caminho relativo aceito → ahead planning refuses stale owner request references
- 2026-11-27 16:33 · `R3` · R3 sabotage: arquivo inexistente tratado como candidato à leitura → ahead planning refuses stale owner request references
- 2026-11-27 16:33 · `R3` · R3 sabotage: leitura da fonte suprimida → ahead planning refuses stale owner request references
- 2026-11-27 16:33 · `R3` · R3 sabotage: arquivo vazio aceito → ahead planning refuses stale owner request references
- 2026-11-27 16:33 · `R3` · R3 sabotage: fragmento vazio aceito → ahead planning refuses stale owner request references
- 2026-11-27 16:33 · `R3` · R3 sabotage: fragmento ausente deixa de impedir despacho → ahead planning refuses stale owner request references
- 2026-11-27 16:33 · `R3` · R3 sabotage: título duplicado aceito → ahead planning refuses stale owner request references
- 2026-11-27 16:33 · `R3` · R3 sabotage: referência a arquivo inteiro recusada → concurrent resume reuses the validated reservation
- 2026-11-27 16:33 · `R3` · R3 sabotage: conteúdo da fonte omitido da releitura → ahead planning refuses stale owner request references
- 2026-11-27 16:33 · `R3` · R3 sabotage: recibo publica conteúdo em vez de só a referência → ahead planning refuses stale owner request references
- 2026-11-27 16:33 · `R3` · R3 sabotage: releitura final suprimida → ahead planning refuses stale owner request references
- 2026-11-27 16:33 · `R3` · R3 sabotage: recusa por mudança perde o diagnóstico → ahead planning refuses stale owner request references
- 2026-11-27 16:33 · `R3` · R3 sabotage: validação antiga por existência de arquivo restaurada → ahead planning refuses stale owner request references
- 2026-11-27 16:33 · `R3` · Em `7ba4bc9`, o fragmento vencido abriu um turno no relay. Em `9b0e168`, fonte ausente, fragmento vencido ou fonte alterada na consulta de orçamento produziram zero turnos e preservaram a espera e o rc 3 com diagnóstico do predecessor. Referências íntegras abriram um turno cada nos controles locais e HTTPS simulados. O Check deu 1 e `tests/run-all.sh` ficou verde antes e depois em 21 etapas (103 → 104 sondas do worker, 100 âncoras do TODO e 1017 no catálogo). As 28 sabotagens rodaram em grupo próprio, com teto de 35 s e 256 MiB por processo. Os controles passaram sob os mesmos limites antes e após a restauração. Procedimento e pipeline conferidos. Sem chamadas reais ao Codex ou ao GitHub.
- 2026-11-27 17:18 · `R4` · R4 sabotage: recolocada a lista antiga sem aprovações curtas → plain human approvals do not hide actionable findings
- 2026-11-27 17:18 · `R4` · R4 sabotage: aprovação simples em inglês removida → plain human approvals do not hide actionable findings
- 2026-11-27 17:18 · `R4` · R4 sabotage: aprovação simples no feminino removida → plain human approvals do not hide actionable findings
- 2026-11-27 17:18 · `R4` · R4 sabotage: âncora final removida e corpo acionável aceito → plain human approvals do not hide actionable findings
- 2026-11-27 17:18 · `R4` · R4 sabotage: recolocada a dispensa de validação em qualquer thread resolvida → review findings and readiness reject malformed resolved threads
- 2026-11-27 17:18 · `R4` · R4 sabotage: campo comments nulo confundido com campo ausente → review findings and readiness reject malformed resolved threads
- 2026-11-27 17:18 · `R4` · R4 sabotage: thread resolvida sem comments recusada → review findings and readiness reject malformed resolved threads
- 2026-11-27 17:18 · `R4` · R4 sabotage: ausência de comments aceita em thread aberta → review findings and readiness reject malformed resolved threads
- 2026-11-27 17:18 · `R4` · Em `4d360e7`, `Aprovado.` bloqueou um PR pronto e `comments: 17` deixou o mesmo SHA pronto apesar do erro no inventário. Em `4d5bdb4`, o inventário e a prontidão distinguem aprovação informativa, corpo acionável e pedido vigente, preservam a thread resolvida válida e recusam metadados inválidos com rc 3. O Check deu 1. `tests/run-all.sh` ficou verde antes e depois em 21 etapas (104 → 106 sondas do worker, 100 âncoras do TODO e 1.017 no catálogo). As oito sabotagens das duas linhas de produto foram detectadas em grupos próprios, com teto de 12 s e 256 MiB por processo. Os controles sob os mesmos limites passaram antes e depois. As demais mudanças são as sondas e a documentação, conferida nos dois pontos de uso. Sem chamadas reais ao GitHub ou ao Codex.
- 2026-11-27 17:53 · `R5` · REVIEW r2 confirmou que dois títulos Markdown válidos abriam um turno com o despachante de `7ba4bc9` e zero em `65862f3`, sem alterar a espera nem o rc 3 do predecessor. O achado da r2 voltou ao EXEC com regressão e nova caminhada.
- 2026-11-27 18:28 · `R5` · R5 sabotage: estado inicial já dentro de comentário → plain (rc 1)
- 2026-11-27 18:28 · `R5` · R5 sabotage: primeira linha ignorada na varredura → plain (rc 1)
- 2026-11-27 18:28 · `R5` · R5 sabotage: abertura de comentário dentro de cerca aceita → comment-in-fence (rc 1)
- 2026-11-27 18:28 · `R5` · R5 sabotage: estado não continua na linha seguinte → closed-comment (rc 1)
- 2026-11-27 18:28 · `R5` · R5 sabotage: comentário indentado como código aceito → indented-comment (rc 1)
- 2026-11-27 18:28 · `R5` · R5 sabotage: estado de comentário sempre fechado → commented-heading (rc 1)
- 2026-11-27 18:28 · `R5` · R5 sabotage: fechamento de comentário na mesma linha ignorado → same-line-comment (rc 1)
- 2026-11-27 18:28 · `R5` · R5 sabotage: linha interna de comentário chega ao leitor de cerca → closed-comment (rc 1)
- 2026-11-27 18:28 · `R5` · R5 sabotage: título indentado como código aceito pelo padrão → r3 (rc 1)
- 2026-11-27 18:28 · `R5` · R5 sabotage: linha sem marcação encerra a varredura → ordinary (rc 1)
- 2026-11-27 18:28 · `R5` · R5 sabotage: grupo de título atribuído ao marcador → plain (rc 1)
- 2026-11-27 18:28 · `R5` · R5 sabotage: cerca de crases aceita informação inválida → backtick-info (rc 1)
- 2026-11-27 18:28 · `R5` · R5 sabotage: restrição de crases aplicada à cerca de tils → tilde-info (rc 1)
- 2026-11-27 18:28 · `R5` · R5 sabotage: abertura inválida cai na atribuição da cerca → backtick-info (rc 1)
- 2026-11-27 18:28 · `R5` · R5 sabotage: iterador anterior que não observa comentários recolocado → closed-comment (rc 1)
- 2026-11-27 18:28 · `R5` · Em `b38b74e`, os dois prefixos descritos na REVIEW r2 deixaram somente a espera, e títulos ocultos em comentários abriram turno. Em `ebeda0b`, os dez cenários passaram com um turno antes da espera para títulos visíveis e zero para títulos ocultos. A espera foi única e manteve `rc=3`, `phase-ceiling` e o diagnóstico original. O Check imprimiu 1. `tests/run-all.sh` ficou verde antes e depois em 21 etapas, com 106 → 107 sondas do worker, 101 âncoras do TODO e 1.017 do catálogo. As 15 sabotagens foram detectadas com grupo próprio, teto de 12 s e 256 MiB por processo, e os controles sob os mesmos limites passaram antes e depois. Sem chamadas reais ao GitHub ou ao Codex.
2026-11-27 19:01 · `R6` · REVIEW r3, achado #1 HIGH. Em 7ebeb5a, uma marca de comentário em cerca de lista suprimiu o despacho com título único e abriu um turno com dois títulos iguais. A base 65862f3 acertou os dois. A espera preservou rc=3, phase-ceiling e o diagnóstico original. R6 pending.
- 2026-11-27 19:28 · `R6` · R6 sabotage: estado inicial começa com cerca aberta → plain (rc 1)
- 2026-11-27 19:28 · `R6` · R6 sabotage: estado inicial inventa um parágrafo → ordered-list-fence (rc 1)
- 2026-11-27 19:28 · `R6` · R6 sabotage: varredura para depois da primeira quebra de linha → list-fenced-comment-marker (rc 1)
- 2026-11-27 19:28 · `R6` · R6 sabotage: tabulação de continuação não ocupa coluna → tabbed-list-fence (rc 1)
- 2026-11-27 19:28 · `R6` · R6 sabotage: linha em branco encerra a cerca da lista → list-content-after-blank (rc 1)
- 2026-11-27 19:28 · `R6` · R6 sabotage: continuação não exige a margem do item → list-fenced-comment-marker (rc 1)
- 2026-11-27 19:28 · `R6` · R6 sabotage: fechamento interno é lido na coluna externa → list-closed-fence (rc 1)
- 2026-11-27 19:28 · `R6` · R6 sabotage: cerca continua depois que o item termina → list-fenced-comment-marker (rc 1)
- 2026-11-27 19:28 · `R6` · R6 sabotage: comentário fechado não encerra o parágrafo → ordered-after-comment (rc 1)
- 2026-11-27 19:28 · `R6` · R6 sabotage: guarda anterior do leitor recolocada antes da expressão nova → list-fenced-comment-marker (rc 1)
- 2026-11-27 19:28 · `R6` · R6 sabotage: expressão aceita somente a cerca sem marcador de lista → list-fenced-comment-marker (rc 1)
- 2026-11-27 19:28 · `R6` · R6 sabotage: código indentado é confundido com parágrafo → ordered-after-code (rc 1)
- 2026-11-27 19:28 · `R6` · R6 sabotage: texto anterior perde o estado de parágrafo → ordered-cannot-interrupt (rc 1)
- 2026-11-27 19:28 · `R6` · R6 sabotage: desempacotamento anterior recolocado sem registrar o marcador da lista → list-fenced-comment-marker (rc 1)
- 2026-11-27 19:28 · `R6` · R6 sabotage: falsa abertura de crases não é marcada como texto → ordered-after-invalid-fence (rc 1)
- 2026-11-27 19:28 · `R6` · R6 sabotage: qualquer número pode interromper o parágrafo → ordered-cannot-interrupt (rc 1)
- 2026-11-27 19:28 · `R6` · R6 sabotage: nem o primeiro número pode interromper o parágrafo → ordered-can-interrupt (rc 1)
- 2026-11-27 19:28 · `R6` · R6 sabotage: marcador que não pode interromper o parágrafo entra na cerca → ordered-cannot-interrupt (rc 1)
- 2026-11-27 19:28 · `R6` · R6 sabotage: atribuição anterior da cerca recolocada sem a margem → list-fenced-comment-marker (rc 1)
- 2026-11-27 19:28 · `R6` · R6 sabotage: a condição anterior aceita marcador de lista como fechamento → root-list-not-closer (rc 1)
- 2026-11-27 19:28 · `R6` · R6 sabotage: título não encerra o parágrafo anterior → ordered-after-heading (rc 1)
- 2026-11-27 19:28 · `R6` · Em 7ca1379, título único após a cerca da lista deixou só a espera, e dois títulos iguais abriram turno. Em 9551b6e3, o único título abriu um turno antes da espera e títulos duplicados não abriram. Os 16 cenários de R6 e os 10 de R5 passaram. A espera permaneceu única com rc=3, phase-ceiling e o diagnóstico original. O Check imprimiu 1. tests/run-all.sh ficou verde antes e depois em 21 etapas, com 107 → 108 sondas do worker, 101 âncoras do TODO e 1.017 do catálogo. As sabotagens foram executadas em cópia descartável, com grupo próprio, teto de 12 s e 256 MiB por processo; os controles passaram antes e depois. Sem chamadas reais ao GitHub ou ao Codex.
- intervention: sdd run --phase REVIEW (the starting phase was forced from the CLI) — REVIEW — 2026-11-27 19:43 · written by the runner
- 2026-11-27 20:03 · `R7` · REVIEW r4, achado #1. A falsa cerca em HTML bruto inverte o despacho em três casos na fixture e mantém a espera original. R6 confirmado em 9551b6e3. R7 pending.
- 2026-11-27 20:44 · `R7` · R7 sabotage: leitor de HTML não é aplicado → html-before-unique (rc 1)
- 2026-11-27 20:44 · `R7` · R7 sabotage: abertura de HTML aceita recuo de código → html-inside-indented-code (rc 1)
- 2026-11-27 20:44 · `R7` · R7 sabotage: linha sem abertura HTML é ocultada → plain (rc 1)
- 2026-11-27 20:44 · `R7` · R7 sabotage: recuo válido não é removido na abertura → html-indented-opener (rc 1)
- 2026-11-27 20:44 · `R7` · R7 sabotage: nenhuma regra de abertura é percorrida → html-processing (rc 1)
- 2026-11-27 20:44 · `R7` · R7 sabotage: bloco de script perde o terminador próprio → html-script (rc 1)
- 2026-11-27 20:44 · `R7` · R7 sabotage: linha vazia encerra script antes da tag final → html-script-before-close-hidden (rc 1)
- 2026-11-27 20:44 · `R7` · R7 sabotage: abertura de comentário não é reconhecida → html-before-comment (rc 1)
- 2026-11-27 20:44 · `R7` · R7 sabotage: instrução de processamento não abre bloco → html-processing (rc 1)
- 2026-11-27 20:44 · `R7` · R7 sabotage: declaração não abre bloco → html-declaration (rc 1)
- 2026-11-27 20:44 · `R7` · R7 sabotage: CDATA não abre bloco → html-cdata (rc 1)
- 2026-11-27 20:44 · `R7` · R7 sabotage: elemento de bloco é interpretado como tag genérica → html-heading-before-blank (rc 1)
- 2026-11-27 20:44 · `R7` · R7 sabotage: prefixo de tag personalizada passa por elemento de bloco → html-custom-prefix-is-not-block-tag (rc 1)
- 2026-11-27 20:44 · `R7` · R7 sabotage: linha só com espaços não encerra bloco → html-heading-after-space-blank (rc 1)
- 2026-11-27 20:44 · `R7` · R7 sabotage: nenhum abridor tem efeito → html-heading-before-blank (rc 1)
- 2026-11-27 20:44 · `R7` · R7 sabotage: abridor reconhecido não publica terminador → html-before-duplicate (rc 1)
- 2026-11-27 20:44 · `R7` · R7 sabotage: tag genérica interrompe parágrafo → html-inline-custom-tag (rc 1)
- 2026-11-27 20:44 · `R7` · R7 sabotage: tag seguida por texto inicia bloco → html-tag-followed-by-text (rc 1)
- 2026-11-27 20:44 · `R7` · R7 sabotage: atributo minúsculo descaracteriza tag completa → html-custom-tag (rc 1)
- 2026-11-27 20:44 · `R7` · R7 sabotage: tag de fechamento completa é ignorada → html-custom-end-tag (rc 1)
- 2026-11-27 20:44 · `R7` · R7 sabotage: tag genérica completa não publica terminador → html-custom-tag (rc 1)
- 2026-11-27 20:44 · `R7` · R7 sabotage: documento começa como bloco HTML → plain (rc 1)
- 2026-11-27 20:44 · `R7` · R7 sabotage: HTML tem precedência sobre uma cerca já aberta → html-inside-fence (rc 1)
- 2026-11-27 20:44 · `R7` · R7 sabotage: estado do bloco não é mantido entre linhas → html-before-comment (rc 1)
- 2026-11-27 20:44 · `R7` · R7 sabotage: estado do parágrafo não chega ao leitor → html-inline-custom-tag (rc 1)
- 2026-11-27 20:44 · `R7` · R7 sabotage: todo conteúdo encerra o bloco → html-before-unique (rc 1)
- 2026-11-27 20:44 · `R7` · R7 sabotage: terminador não limpa o estado do bloco → html-before-unique (rc 1)
- 2026-11-27 20:44 · `R7` · R7 sabotage: leitor anterior recolocado integralmente → html-before-unique (rc 1)
- 2026-11-27 20:44 · `R7` · R7 sabotage: expectativa da fixture invertida em html-before-unique → html-before-unique (rc 1)
- 2026-11-27 20:44 · `R7` · R7 sabotage: expectativa da fixture invertida em html-before-duplicate → html-before-duplicate (rc 1)
- 2026-11-27 20:44 · `R7` · R7 sabotage: expectativa da fixture invertida em html-before-comment → html-before-comment (rc 1)
- 2026-11-27 20:44 · `R7` · R7 sabotage: expectativa da fixture invertida em html-heading-before-blank → html-heading-before-blank (rc 1)
- 2026-11-27 20:44 · `R7` · R7 sabotage: expectativa da fixture invertida em html-indented-opener → html-indented-opener (rc 1)
- 2026-11-27 20:44 · `R7` · R7 sabotage: expectativa da fixture invertida em html-heading-after-space-blank → html-heading-after-space-blank (rc 1)
- 2026-11-27 20:44 · `R7` · R7 sabotage: expectativa da fixture invertida em html-inside-fence → html-inside-fence (rc 1)
- 2026-11-27 20:44 · `R7` · R7 sabotage: expectativa da fixture invertida em html-inside-indented-code → html-inside-indented-code (rc 1)
- 2026-11-27 20:44 · `R7` · R7 sabotage: expectativa da fixture invertida em html-before-ordered-fence → html-before-ordered-fence (rc 1)
- 2026-11-27 20:44 · `R7` · R7 sabotage: expectativa da fixture invertida em html-custom-tag → html-custom-tag (rc 1)
- 2026-11-27 20:44 · `R7` · R7 sabotage: expectativa da fixture invertida em html-custom-end-tag → html-custom-end-tag (rc 1)
- 2026-11-27 20:44 · `R7` · R7 sabotage: expectativa da fixture invertida em html-inline-custom-tag → html-inline-custom-tag (rc 1)
- 2026-11-27 20:44 · `R7` · R7 sabotage: expectativa da fixture invertida em html-custom-prefix-is-not-block-tag → html-custom-prefix-is-not-block-tag (rc 1)
- 2026-11-27 20:44 · `R7` · R7 sabotage: expectativa da fixture invertida em html-tag-followed-by-text → html-tag-followed-by-text (rc 1)
- 2026-11-27 20:44 · `R7` · R7 sabotage: expectativa da fixture invertida em html-script → html-script (rc 1)
- 2026-11-27 20:44 · `R7` · R7 sabotage: expectativa da fixture invertida em html-script-before-close-hidden → html-script-before-close-hidden (rc 1)
- 2026-11-27 20:44 · `R7` · R7 sabotage: expectativa da fixture invertida em html-processing → html-processing (rc 1)
- 2026-11-27 20:44 · `R7` · R7 sabotage: expectativa da fixture invertida em html-declaration → html-declaration (rc 1)
- 2026-11-27 20:44 · `R7` · R7 sabotage: expectativa da fixture invertida em html-cdata → html-cdata (rc 1)
- 2026-11-27 20:44 · `R7` · R7 sabotage: separador após bloco removido da fixture → html-before-unique (rc 1)
- 2026-11-27 20:44 · `R7` · R7 sabotage: título duplicado trocado na fixture → html-before-duplicate (rc 1)
- 2026-11-27 20:44 · `R7` · R7 sabotage: estado da sonda anterior não é limpo → marcador verde do Check R7
- 2026-11-27 20:44 · `R7` · R7 sabotage: primeira linha do laço omite o título único → inventário dos 19 cenários
- 2026-11-27 20:44 · `R7` · R7 sabotage: linha do laço omite o recuo válido → inventário dos 19 cenários
- 2026-11-27 20:44 · `R7` · R7 sabotage: linha do laço omite a linha vazia com espaços → inventário dos 19 cenários
- 2026-11-27 20:44 · `R7` · R7 sabotage: linha do laço omite a tag personalizada → inventário dos 19 cenários
- 2026-11-27 20:44 · `R7` · R7 sabotage: última linha do laço omite o script → inventário dos 19 cenários
- 2026-11-27 20:44 · `R7` · R7 sabotage: retorno da fixture é interpretado ao contrário → marcador verde do Check R7
- 2026-11-27 20:44 · `R7` · R7 sabotage: mensagem da fixture não é acumulada → diagnóstico vermelho do Check R7
- 2026-11-27 20:44 · `R7` · R7 sabotage: agregado vermelho pode imprimir sucesso → marcador verde do Check R7
- 2026-11-27 20:44 · `R7` · R7 sabotage: marcador de sucesso é trocado → marcador verde do Check R7
- 2026-11-27 20:44 · `R7` · R7 sabotage: ramo de falha também roda com todos os casos verdes → marcador verde do Check R7
- 2026-11-27 20:44 · `R7` · R7 sabotage: marcador de falha é trocado → diagnóstico vermelho do Check R7
- 2026-11-27 20:44 · `R7` · R7 sabotage: diagnóstico deixa de explicar o contrato → diagnóstico vermelho do Check R7
- 2026-11-27 20:44 · `R7` · R7 sabotage: fechamento do ramo interno removido → sintaxe do bloco R7
- 2026-11-27 20:44 · `R7` · R7 sabotage: fechamento do laço removido → sintaxe do bloco R7
- 2026-11-27 20:44 · `R7` · R7 sabotage: fechamento do ramo de veredito removido → sintaxe do bloco R7
- 2026-11-27 20:44 · `R7` · Em 4b886900, os três casos da revisão inverteram o despacho. Em 9d53509f, o título visível único iniciou um turno antes da espera, e título duplicado ou comentado manteve só a espera. Nos três casos ela ficou única, com rc=3, phase-ceiling e o diagnóstico original. Os 19 cenários de R7, os controles R5/R6 e a reserva única passaram. O Check imprimiu 1. tests/run-all.sh ficou verde antes e depois, em 21 etapas, com 108 → 109 sondas do worker. As 28 sabotagens do leitor e as 37 dos sensores foram detectadas em cópias descartáveis, com grupo próprio, teto de 12 s e 256 MiB por processo. Os controles passaram nos mesmos limites antes e depois. As duas atribuições antigas a in_comment, recolocadas sozinhas, seriam inertes porque a variável deixou de ser lida. O leitor anterior inteiro voltou a reprovar. A etapa Codex registrou 3 skipped. Sem chamadas reais ao GitHub ou ao Codex.
- intervention: sdd run --phase REVIEW (the starting phase was forced from the CLI) — REVIEW — 2026-11-27 21:06 · written by the runner
- 2026-11-27 21:26 · `R8` · Achado #1 da REVIEW r5. Ao sair de um item de lista, o HTML bruto oculta o título seguinte. As três regressões falharam em 0c4cd137 e passaram em 13103d36. Os três casos de R7 fizeram o inverso. R8 fica pending.
- 2026-11-27 22:04 · `R8` · R8 sabotage: degrada a raiz da pilha de recuos → html-list-end-unique
- 2026-11-27 22:04 · `R8` · R8 sabotage: rastreia itens também dentro de cerca → html-root-after-fenced-list
- 2026-11-27 22:04 · `R8` · R8 sabotage: abandona só um nível de lista por linha → html-root-after-list
- 2026-11-27 22:04 · `R8` · R8 sabotage: trata linha vazia como saída do item → html-list-after-blank
- 2026-11-27 22:04 · `R8` · R8 sabotage: não retira da pilha o item encerrado → teto de 12 s
- 2026-11-27 22:04 · `R8` · R8 sabotage: deixa o HTML ativo ao sair do item → html-list-end-unique
- 2026-11-27 22:04 · `R8` · R8 sabotage: usa margem absoluta para reconhecer HTML → html-list-indented-script
- 2026-11-27 22:04 · `R8` · R8 sabotage: identifica item falso dentro de HTML → html-root-contains-fake-list
- 2026-11-27 22:04 · `R8` · R8 sabotage: deixa de reconhecer marcadores de itens → html-list-end-unique
- 2026-11-27 22:04 · `R8` · R8 sabotage: permite lista numerada diferente de 1 interromper parágrafo → html-list-ordered-cannot-interrupt
- 2026-11-27 22:04 · `R8` · R8 sabotage: nega item numerado 1 após parágrafo → html-list-ordered-can-interrupt
- 2026-11-27 22:04 · `R8` · R8 sabotage: trata quebra temática como marcador de lista → html-root-after-thematic-break
- 2026-11-27 22:04 · `R8` · R8 sabotage: não registra o recuo do novo item → html-list-end-unique
- 2026-11-27 22:04 · `R8` · R8 sabotage: deixa marcador na linha inicial do HTML → html-list-start-custom-tag
- 2026-11-27 22:04 · `R8` · R8 sabotage: herda parágrafo anterior ao abrir item novo → html-list-start-custom-tag
- 2026-11-27 22:04 · `R8` · R8 sabotage: recoloca a chamada antiga sem a margem relativa → html-list-indented-script
- 2026-11-27 22:04 · `R8` · R8 sabotage: retira o HTML comum às quatro fixtures da revisão → html-list-end-unique
- 2026-11-27 22:04 · `R8` · R8 sabotage: inverte a expectativa de despacho de html-list-end-unique → html-list-end-unique
- 2026-11-27 22:04 · `R8` · R8 sabotage: inverte a expectativa de despacho de html-list-end-duplicate → html-list-end-duplicate
- 2026-11-27 22:04 · `R8` · R8 sabotage: inverte a expectativa de despacho de html-list-end-script → html-list-end-script
- 2026-11-27 22:04 · `R8` · R8 sabotage: inverte a expectativa de despacho de html-list-still-inside → html-list-still-inside
- 2026-11-27 22:04 · `R8` · R8 sabotage: inverte a expectativa de despacho de html-list-ordered-dedent → html-list-ordered-dedent
- 2026-11-27 22:04 · `R8` · R8 sabotage: inverte a expectativa de despacho de html-list-after-blank → html-list-after-blank
- 2026-11-27 22:04 · `R8` · R8 sabotage: inverte a expectativa de despacho de html-list-indented-script → html-list-indented-script
- 2026-11-27 22:04 · `R8` · R8 sabotage: inverte a expectativa de despacho de html-list-start-custom-tag → html-list-start-custom-tag
- 2026-11-27 22:04 · `R8` · R8 sabotage: inverte a expectativa de despacho de html-list-ordered-cannot-interrupt → html-list-ordered-cannot-interrupt
- 2026-11-27 22:04 · `R8` · R8 sabotage: inverte a expectativa de despacho de html-list-ordered-can-interrupt → html-list-ordered-can-interrupt
- 2026-11-27 22:04 · `R8` · R8 sabotage: inverte a expectativa de despacho de html-root-after-list → html-root-after-list
- 2026-11-27 22:04 · `R8` · R8 sabotage: inverte a expectativa de despacho de html-nested-list-dedent → html-nested-list-dedent
- 2026-11-27 22:04 · `R8` · R8 sabotage: inverte a expectativa de despacho de html-root-after-thematic-break → html-root-after-thematic-break
- 2026-11-27 22:04 · `R8` · R8 sabotage: inverte a expectativa de despacho de html-root-after-fenced-list → html-root-after-fenced-list
- 2026-11-27 22:04 · `R8` · R8 sabotage: inverte a expectativa de despacho de html-root-contains-fake-list → html-root-contains-fake-list
- 2026-11-27 22:04 · `R8` · R8 sabotage: retira linha do sensor `got=` → marcador verde do Check R8
- 2026-11-27 22:04 · `R8` · R8 sabotage: retira linha do sensor `for markup_case in html-list-end-unique html-list-end-duplicate html` → sintaxe ou execução do Check R8
- 2026-11-27 22:04 · `R8` · R8 sabotage: retira linha do sensor `html-list-ordered-dedent html-list-after-blank html-list-indented-sc` → censo dos casos do Check R8
- 2026-11-27 22:04 · `R8` · R8 sabotage: retira linha do sensor `html-list-ordered-cannot-interrupt html-list-ordered-can-interrupt h` → censo dos casos do Check R8
- 2026-11-27 22:04 · `R8` · R8 sabotage: retira linha do sensor `html-nested-list-dedent html-root-after-thematic-break html-root-aft` → censo dos casos do Check R8
- 2026-11-27 22:04 · `R8` · R8 sabotage: retira linha do sensor `html-root-contains-fake-list; do` → sintaxe ou execução do Check R8
- 2026-11-27 22:04 · `R8` · R8 sabotage: retira linha do sensor `if ! result="$(python3 "$ROOT/tests/check-worker-ahead.py" "$ROOT" -` → sintaxe ou execução do Check R8
- 2026-11-27 22:04 · `R8` · R8 sabotage: retira linha do sensor `got="${got:+$got$'\n'}$markup_case: $result"` → sintaxe ou execução do Check R8
- 2026-11-27 22:04 · `R8` · R8 sabotage: retira linha do sensor `fi` → sintaxe ou execução do Check R8
- 2026-11-27 22:04 · `R8` · R8 sabotage: retira linha do sensor `done` → sintaxe ou execução do Check R8
- 2026-11-27 22:04 · `R8` · R8 sabotage: retira linha do sensor `if [ -z "$got" ]; then` → sintaxe ou execução do Check R8
- 2026-11-27 22:04 · `R8` · R8 sabotage: retira linha do sensor `pass 'owner request bounds raw html by its list item'` → sintaxe ou execução do Check R8
- 2026-11-27 22:04 · `R8` · R8 sabotage: retira linha do sensor `else` → marcador verde do Check R8
- 2026-11-27 22:04 · `R8` · R8 sabotage: retira linha do sensor `fail 'owner request bounds raw html by its list item' \` → sintaxe ou execução do Check R8
- 2026-11-27 22:04 · `R8` · R8 sabotage: retira linha do sensor `'one turn before wait only for a unique visible heading, with the sa` → sintaxe ou execução do Check R8
- 2026-11-27 22:04 · `R8` · R8 sabotage: retira linha do sensor `fi` → sintaxe ou execução do Check R8
- 2026-11-27 22:04 · `R8` · R8 sabotage: troca o marcador literal de sucesso → marcador verde do Check R8
- 2026-11-27 22:04 · `R8` · R8 sabotage: troca o marcador literal de falha → diagnóstico vermelho do Check R8
- 2026-11-27 22:04 · `R8` · Em 0c4cd137, os três casos da REVIEW r5 inverteram o despacho e o Check agregado reprovou sozinho. Em 1a50dd42, um título visível único inicia um turno antes da espera. Título duplicado ou ainda oculto mantém só a espera. Todos preservaram a espera única, rc=3, phase-ceiling e o diagnóstico original. Passaram os 15 cenários de R8, os controles R5–R7 e a reserva única. O Check imprimiu 1. tests/run-all.sh ficou verde antes e depois, em 21 etapas, com 109 → 110 sondas do worker e 3 casos skipped na etapa Codex. As 16 sabotagens do leitor e as 34 dos sensores foram detectadas em cópias descartáveis. Os controles passaram antes e depois com 256 MiB por processo, grupo próprio e teto de 12 s por sonda, ou 40 s para a jornada de reserva. O cabeçalho do bloco R8 é comentário e não muda a execução. Sem chamadas reais ao GitHub ou ao Codex.
- intervention: sdd run --phase REVIEW (the starting phase was forced from the CLI) — REVIEW — 2026-11-27 22:23 · written by the runner
- 2026-11-27 22:41 · `R9` · REVIEW r6 confirmou o R8 em 1a50dd42. Com os dois marcadores na mesma linha e HTML interno, 61398c9a inverte o despacho em relação a 0c4cd137, com a mesma espera e o mesmo veredito. R9 pending. A lacuna do registro das sabotagens ficou no backlog.
- 2026-11-27 23:14 · `R9` · R9 sabotage: reader-revert, troca while por if na leitura de marcadores → Check R9, rc=1, saída `AssertionError: ('compact-nested-unique', ['start', 'wait'], ['wait'])`
- 2026-11-27 23:14 · `R9` · R9 sabotage: fixture-L178, retira compact = "- - <script>\n    <div>\n  " → Check R9, rc=1, saída `NameError: name 'compact' is not defined`
- 2026-11-27 23:14 · `R9` · R9 sabotage: fixture-L179, retira expanded = "- Outer item\n  - <script>\n    <div>\n  " → Check R9, rc=1, saída `NameError: name 'expanded' is not defined`
- 2026-11-27 23:14 · `R9` · R9 sabotage: fixture-L242, retira "compact-nested-unique": (compact + instruction, True), → Check R9, rc=1, saída `KeyError: 'compact-nested-unique'`
- 2026-11-27 23:14 · `R9` · R9 sabotage: fixture-L243, retira "compact-nested-duplicate": (instruction + "\n" + compact + instruction, False), → Check R9, rc=1, saída `KeyError: 'compact-nested-duplicate'`
- 2026-11-27 23:14 · `R9` · R9 sabotage: fixture-L244, retira "compact-nested-closed": (compact[:-2] + "    </script>\n  " + instruction, True), → Check R9, rc=1, saída `KeyError: 'compact-nested-closed'`
- 2026-11-27 23:14 · `R9` · R9 sabotage: fixture-L245, retira "compact-nested-still-inside": (compact + "  " + instruction, False), → Check R9, rc=1, saída `KeyError: 'compact-nested-still-inside'`
- 2026-11-27 23:14 · `R9` · R9 sabotage: fixture-L246, retira "expanded-nested-unique": (expanded + instruction, True), → Check R9, rc=1, saída `KeyError: 'expanded-nested-unique'`
- 2026-11-27 23:14 · `R9` · R9 sabotage: fixture-L247, retira "expanded-nested-duplicate": (instruction + "\n" + expanded + instruction, False), → Check R9, rc=1, saída `KeyError: 'expanded-nested-duplicate'`
- 2026-11-27 23:14 · `R9` · R9 sabotage: shell-L9, retira got= → Check R9, rc=1, saída `r9-block.sh: line 15: got: unbound variable`
- 2026-11-27 23:14 · `R9` · R9 sabotage: shell-L10, retira for markup_case in compact-nested-unique compact-nested-duplicate compact-nested-closed compact-nested-still-inside \ → Check R9, rc=2, saída `r9-block.sh: line 10: syntax error near unexpected token `do'`
- 2026-11-27 23:14 · `R9` · R9 sabotage: shell-L11, retira expanded-nested-unique expanded-nested-duplicate; do → Check R9, rc=2, saída `r9-block.sh: line 11: syntax error near unexpected token `then'`
- 2026-11-27 23:14 · `R9` · R9 sabotage: shell-L12, retira if ! result="$(python3 "$ROOT/tests/check-worker-ahead.py" "$ROOT" --preceding-markup "$markup_case" 2>&1)"; then → Check R9, rc=2, saída `r9-block.sh: line 13: syntax error near unexpected token `fi'`
- 2026-11-27 23:14 · `R9` · R9 sabotage: shell-L13, retira got="${got:+$got$'\n'}$markup_case: $result" → controle vermelho do Check R9, rc=2, saída `r9-block.sh: line 13: syntax error near unexpected token `fi'`
- 2026-11-27 23:14 · `R9` · R9 sabotage: shell-L14, retira fi → Check R9, rc=2, saída `r9-block.sh: line 14: syntax error near unexpected token `done'`
- 2026-11-27 23:14 · `R9` · R9 sabotage: shell-L15, retira done → Check R9, rc=2, saída `r9-block.sh: line 24: syntax error: unexpected end of file`
- 2026-11-27 23:14 · `R9` · R9 sabotage: shell-L16, retira if [ -z "$got" ]; then → Check R9, rc=2, saída `r9-block.sh: line 17: syntax error near unexpected token `else'`
- 2026-11-27 23:14 · `R9` · R9 sabotage: shell-L17, retira pass 'owner request bounds raw html by its compact nested list item' → Check R9, rc=2, saída `r9-block.sh: line 17: syntax error near unexpected token `else'`
- 2026-11-27 23:14 · `R9` · R9 sabotage: shell-L18, retira else → Check R9, rc=1, saída `  FAIL  owner request bounds raw html by its compact nested list item`
- 2026-11-27 23:14 · `R9` · R9 sabotage: shell-L19, retira fail 'owner request bounds raw html by its compact nested list item' \ → controle vermelho do Check R9, rc=127, saída `r9-block.sh: line 19: one turn before wait only for a unique visible heading, with the same runner verdict: command not found`
- 2026-11-27 23:14 · `R9` · R9 sabotage: shell-L20, retira 'one turn before wait only for a unique visible heading, with the same runner verdict' "$got" → controle vermelho do Check R9, rc=2, saída `r9-block.sh: line 24: syntax error: unexpected end of file`
- 2026-11-27 23:14 · `R9` · R9 sabotage: shell-L21, retira fi → Check R9, rc=2, saída `r9-block.sh: line 24: syntax error: unexpected end of file`
- 2026-11-27 23:14 · `R9` · R9 sabotage: shell-pass-mark, troca pass 'owner request → Check R9, rc=0, saída `  ok    changed owner request bounds raw html by its compact nested list item`
- 2026-11-27 23:14 · `R9` · R9 sabotage: shell-fail-mark, troca fail 'owner request → controle vermelho do Check R9, rc=1, saída `  FAIL  changed owner request bounds raw html by its compact nested list item`
- 2026-11-27 23:14 · `R9` · R9 sabotage: shell-fail-message, troca 'one turn before wait → controle vermelho do Check R9, rc=1, saída `         expected: wrong expectation only for a unique visible heading, with the same runner verdict`
- 2026-11-27 23:14 · `R9` · O reset de `got` é necessário no bloco isolado sob `set -u`. Na suíte completa, a ausência do reset só propaga uma falha anterior já registrada por R8. O cabeçalho do bloco é comentário, sem efeito de execução. A releitura de `commands/sdd-worker.md` e `docs/pipeline.md` confirmou o mesmo limite para HTML bruto.
- 2026-11-27 23:14 · `R9` · Em 61398c9a falharam `compact-nested-unique`, `compact-nested-duplicate` e `compact-nested-closed` pela ordem do despacho. Em 0d33f0d0, passaram os seis casos, R5–R8 e a reserva única. `start, wait` só para título visível único. Todos mantiveram uma espera, rc=3, phase-ceiling e o diagnóstico original. Check R9 → 1. tests/run-all.sh → rc 0, 21 etapas, 110 → 111 sondas do worker e 3 casos skipped do Codex. Controles isolados antes e depois verdes com 25 s e 256 MiB por processo em grupo próprio. A reversão da linha do leitor e as 24 sabotagens dos sensores foram detectadas pelos resultados registrados acima. Sem chamadas reais ao GitHub ou Codex.
- intervention: sdd run --phase REVIEW (the starting phase was forced from the CLI) — REVIEW — 2026-11-27 23:32 · written by the runner
- 2026-11-27 23:50 · `R10` · REVIEW r7, achado 1. Confirmada inversão do despacho em parágrafo após HTML do item compacto. R10 aberto.
- 2026-11-27 23:50 · `R11` · REVIEW r7, achado 2. Confirmada revarredura quadrática dos hífens antes da espera. R11 aberto.
- 2026-11-28 00:22 · `R10` · R10 sabotage: leitor: repõe recuo absoluto → Check R10 vermelho (rc=1, AssertionError: ('compact-paragraph-unique', ['start', 'wait'], ['wait'])).
- 2026-11-28 00:22 · `R10` · R10 sabotage: leitor: ignora recuo → Check R10 vermelho (rc=1, AssertionError: ('compact-html-after-indented-code', ['wait'], ['start', 'wait'])).
- 2026-11-28 00:22 · `R10` · R10 sabotage: leitor: ignora a linha em branco → Check R10 vermelho (rc=1, AssertionError: ('compact-html-after-blank', ['wait'], ['start', 'wait'])).
- 2026-11-28 00:22 · `R10` · R10 sabotage: fixture L180: retira paragraph = "10. - <script>\n    Text\n<sample-box>\n" → Check R10 vermelho (rc=1, FAIL  owner request preserves paragraph after compact nested html).
- 2026-11-28 00:22 · `R10` · R10 sabotage: fixture L249: inverte despacho esperado → Check R10 vermelho (rc=1, AssertionError: ('compact-paragraph-unique', ['wait'], ['start', 'wait'])).
- 2026-11-28 00:22 · `R10` · R10 sabotage: fixture L250: inverte despacho esperado → Check R10 vermelho (rc=1, AssertionError: ('compact-paragraph-duplicate', ['start', 'wait'], ['wait'])).
- 2026-11-28 00:22 · `R10` · R10 sabotage: fixture L251: inverte despacho esperado → Check R10 vermelho (rc=1, AssertionError: ('compact-html-after-blank', ['start', 'wait'], ['wait'])).
- 2026-11-28 00:22 · `R10` · R10 sabotage: fixture L252: retira "compact-html-after-indented-code": ("10. - <script></script>\n\n          Code\n<sample-box>\n" → Check R10 vermelho (rc=1, FAIL  owner request preserves paragraph after compact nested html).
- 2026-11-28 00:22 · `R10` · R10 sabotage: fixture L253: inverte despacho esperado → Check R10 vermelho (rc=1, AssertionError: ('compact-html-after-indented-code', ['start', 'wait'], ['wait'])).
- 2026-11-28 00:22 · `R10` · R10 sabotage: shell L11: retira got= → Check R10 vermelho (rc=1, r10-block.sh: line 17: got: unbound variable).
- 2026-11-28 00:22 · `R10` · R10 sabotage: shell L12: retira for markup_case in compact-paragraph-unique compact-paragraph-duplicate \ → Check R10 vermelho (rc=2, r10-block.sh: line 12: syntax error near unexpected token `do').
- 2026-11-28 00:22 · `R10` · R10 sabotage: shell L13: retira compact-html-after-blank compact-html-after-indented-code; do → Check R10 vermelho (rc=2, r10-block.sh: line 13: syntax error near unexpected token `then').
- 2026-11-28 00:22 · `R10` · R10 sabotage: shell L14: retira if ! result="$(python3 "$ROOT/tests/check-worker-ahead.py" "$ROOT" --preceding-markup "$markup_case" 2>&1)"; then → Check R10 vermelho (rc=2, r10-block.sh: line 15: syntax error near unexpected token `fi').
- 2026-11-28 00:22 · `R10` · R10 sabotage: shell L15: retira got="${got:+$got$'\n'}$markup_case: $result" → Check R10 vermelho (rc=2, r10-block.sh: line 15: syntax error near unexpected token `fi').
- 2026-11-28 00:22 · `R10` · R10 sabotage: shell L16: retira fi → Check R10 vermelho (rc=2, r10-block.sh: line 16: syntax error near unexpected token `done').
- 2026-11-28 00:22 · `R10` · R10 sabotage: shell L17: retira done → Check R10 vermelho (rc=2, r10-block.sh: line 25: syntax error: unexpected end of file).
- 2026-11-28 00:22 · `R10` · R10 sabotage: shell L18: retira if [ -z "$got" ]; then → Check R10 vermelho (rc=2, ok    owner request preserves paragraph after compact nested html).
- 2026-11-28 00:22 · `R10` · R10 sabotage: shell L19: altera pass 'owner request preserves paragraph after compact nested html' → Check R10 vermelho (rc=0, ok    wrong request preserves paragraph after compact nested html).
- 2026-11-28 00:22 · `R10` · R10 sabotage: shell L20: retira else → Check R10 vermelho (rc=1, ok    owner request preserves paragraph after compact nested html).
- 2026-11-28 00:22 · `R10` · R10 sabotage: shell L21: altera fail 'owner request preserves paragraph after compact nested html' \ → controle negativo diverge da falha esperada (rc=0, ok    owner request preserves paragraph after compact nested html).
- 2026-11-28 00:22 · `R10` · R10 sabotage: shell L22: altera 'one turn before wait for a unique visible heading, with the same runner verdict' "$got" → controle negativo diverge da falha esperada (rc=1, AssertionError: ('compact-paragraph-unique', ['start', 'wait'], ['wait'])).
- 2026-11-28 00:22 · `R10` · R10 sabotage: shell L23: retira fi → Check R10 vermelho (rc=2, r10-block.sh: line 25: syntax error: unexpected end of file).
- 2026-11-28 00:22 · `R10` · As 22 sabotagens rodaram em grupo próprio, com teto de 25 s e 256 MiB por processo. Os controles anterior e restaurado ficaram verdes. O cabeçalho e a linha em branco do sensor são apenas formatação. A releitura do procedimento público e do pipeline confirmou o mesmo limite de parágrafo e as 103 âncoras do TODO ficaram no alvo.
- 2026-11-28 00:22 · `R10` · Em fda9359e, o caso único deu apenas espera e o duplicado disparou antes dela. Na árvore de 6402cbd8, só o título único dispara antes da espera. Duplicado, linha em branco com espaços e código indentado não disparam. As quatro entradas mantêm uma espera, rc=3, phase-ceiling e o diagnóstico original. R8, R9 e a reserva única passaram. Check R10 → 1. tests/run-all.sh → rc 0, 21 etapas, 111 → 112 sondas do worker e 3 casos skipped do Codex. A reprodução usou somente fixtures locais. R11 segue pending.
- 2026-11-28 01:04 · `R11` · R11 sabotage: sdd-worker-ahead L83: retira list_item = re.compile(r" {0,3}([-+*]|[0-9]{1,9}[.)]) {1,4}(?=\S)") → Check R11 vermelho em compact-scale-thematic-in-item (NameError: name \'list_item\' is not defined).
- 2026-11-28 01:04 · `R11` · R11 sabotage: sdd-worker-ahead L84: retira thematic = re.compile(r" *(?:-(?: *-){2,}|\*(?: *\*){2,}) *") → Check R11 vermelho em compact-scale-thematic-in-item (NameError: name \'thematic\' is not defined).
- 2026-11-28 01:04 · `R11` · R11 sabotage: sdd-worker-ahead L98: retira indent = len(line) - len(line.lstrip(" ")) if line.strip() else list_indents[-1] → Check R11 vermelho em compact-scale-thematic-in-item (NameError: name \'indent\' is not defined).
- 2026-11-28 01:04 · `R11` · R11 sabotage: sdd-worker-ahead L99: retira while list_indents[-1] > indent: → Check R11 ou regressão vermelha (rc=1, AssertionError: ('compact-scale-thematic-in-item', '  File "/tmp/worker-ahead-s2m3ghi2/kit/bin/sdd-worker-ahead", line 99\n    list_indents.pop()\nIndentationError: unexpected indent\nLookahead stopped; retain its diagnostic and collect the original runner result.\n')).
- 2026-11-28 01:04 · `R11` · R11 sabotage: sdd-worker-ahead L antiga 96: repõe while line.strip() and not line.startswith(" " * list_indents[-1]): → Check R11 ou regressão vermelha (rc=1, AssertionError: ('compact-scale-thematic-in-item', '  File "/tmp/worker-ahead-1tuo2dfr/kit/bin/sdd-worker-ahead", line 99\n    indent = len(line) - len(line.lstrip(" ")) if line.strip() else list_indents[-1]\n    ^\nIndentationError: expected an indented block after \'while\' statement on line 98\nLookahead stopped; retain its diagnostic and collect the original runner result.\n')).
- 2026-11-28 01:04 · `R11` · R11 sabotage: sdd-worker-ahead L102: retira offset, previous_marker = list_indents[-1], "" → Check R11 vermelho em compact-scale-thematic-in-item (UnboundLocalError: cannot access local variable \'offset\' where it is not associated with a value).
- 2026-11-28 01:04 · `R11` · R11 sabotage: sdd-worker-ahead L104: retira while not html_end and (item := list_item.match(line, offset)) and ( → Check R11 ou regressão vermelha (rc=1, AssertionError: ('compact-scale-thematic-in-item', '  File "/tmp/worker-ahead-5pl6kery/kit/bin/sdd-worker-ahead", line 104\n    not in_paragraph or not item[1][0].isdigit() or int(item[1][:-1]) == 1\nIndentationError: unexpected indent\nLookahead stopped; retain its diagnostic and collect the original runner result.\n')).
- 2026-11-28 01:04 · `R11` · R11 sabotage: sdd-worker-ahead L antiga 99: repõe html_line = line[list_indents[-1]:] → mutante equivalente. A atribuição recolocada não é lida antes de ser sobrescrita no fim do laço.
- 2026-11-28 01:04 · `R11` · R11 sabotage: sdd-worker-ahead L antiga 100: repõe while not html_end and (item := re.match(r" {0,3}([-+*]|[0-9]{1,9}[.)]) {1,4}(?=\S)", html_line)) and ( → Check R11 ou regressão vermelha (rc=1, AssertionError: ('compact-scale-thematic-in-item', '  File "/tmp/worker-ahead-flvweatn/kit/bin/sdd-worker-ahead", line 103\n    while not html_end and (item := re.match(r" {0,3}([-+*]|[0-9]{1,9}[.)]) {1,4}(?=\\S)", html_line)) and (\n                                                                                                          ^\nSyntaxError: \'(\' was never closed\nLookahead stopped; retain its diagnostic and collect the original runner result.\n')).
- 2026-11-28 01:04 · `R11` · R11 sabotage: sdd-worker-ahead L106: retira ) and not (item[1] != previous_marker and thematic.fullmatch(line, offset)): → Check R11 ou regressão vermelha (rc=1, AssertionError: ('compact-scale-thematic-in-item', '  File "/tmp/worker-ahead-lkigs7fj/kit/bin/sdd-worker-ahead", line 104\n    while not html_end and (item := list_item.match(line, offset)) and (\n                                                                       ^\nSyntaxError: \'(\' was never closed\nLookahead stopped; retain its diagnostic and collect the original runner result.\n')).
- 2026-11-28 01:04 · `R11` · R11 sabotage: sdd-worker-ahead L107: altera offset, previous_marker = item.end(), item[1] → Check R11 ou regressão vermelha (rc=1, AssertionError: ('+ ', 4018015, 16036015)).
- 2026-11-28 01:04 · `R11` · R11 sabotage: sdd-worker-ahead L108: retira list_indents.append(offset) → Check R11 ou regressão vermelha (rc=1, AssertionError: ('compact-scale-thematic-in-item', ['wait'], ['start', 'wait'])).
- 2026-11-28 01:04 · `R11` · R11 sabotage: sdd-worker-ahead L antiga 102: repõe ) and not re.fullmatch(r" *(?:-(?: *-){2,}|\*(?: *\*){2,}) *", html_line): → Check R11 ou regressão vermelha (rc=1, AssertionError: ('compact-scale-thematic-in-item', '  File "/tmp/worker-ahead-y2lem_tf/kit/bin/sdd-worker-ahead", line 107\n    ) and not (item[1] != previous_marker and thematic.fullmatch(line, offset)):\n    ^\nSyntaxError: unmatched \')\'\nLookahead stopped; retain its diagnostic and collect the original runner result.\n')).
- 2026-11-28 01:04 · `R11` · R11 sabotage: sdd-worker-ahead L antiga 103: repõe list_indents.append(list_indents[-1] + item.end()) → a inserção é redundante. Como substituição do append novo, deixou compact-nested-unique vermelho, só wait.
- 2026-11-28 01:04 · `R11` · R11 sabotage: sdd-worker-ahead L antiga 104: repõe html_line = html_line[item.end():] → Check R11 vermelho em compact-scale-thematic-in-item (UnboundLocalError: cannot access local variable \'html_line\' where it is not associated with a value).
- 2026-11-28 01:04 · `R11` · R11 sabotage: sdd-worker-ahead L110: retira html_line = line[offset:] → Check R11 vermelho em compact-scale-thematic-in-item (NameError: name \'html_line\' is not defined. Did you mean: \'html_end\'?).
- 2026-11-28 01:04 · `R11` · R11 sabotage: check-worker-ahead.py L7: retira import runpy → Check R11 ou regressão vermelha (rc=1, NameError: name 'runpy' is not defined. Did you forget to import 'runpy'?).
- 2026-11-28 01:04 · `R11` · R11 sabotage: check-worker-ahead.py L13: retira from types import SimpleNamespace → Check R11 ou regressão vermelha (rc=1, NameError: name 'SimpleNamespace' is not defined).
- 2026-11-28 01:04 · `R11` · R11 sabotage: check-worker-ahead.py L32: retira def compact_scan_work(marker): → Check R11 ou regressão vermelha (rc=1, NameError: name 'marker' is not defined).
- 2026-11-28 01:04 · `R11` · R11 sabotage: check-worker-ahead.py L33: retira scan = runpy.run_path(str(root / "bin/sdd-worker-ahead"))["local_anchors"] → Check R11 ou regressão vermelha (rc=1, NameError: name 'scan' is not defined).
- 2026-11-28 01:04 · `R11` · R11 sabotage: check-worker-ahead.py L35: retira def measure(n): → Check R11 ou regressão vermelha (rc=1, IndentationError: unexpected indent).
- 2026-11-28 01:04 · `R11` · R11 sabotage: check-worker-ahead.py L36: retira work = 0 → Check R11 ou regressão vermelha (rc=1, SyntaxError: no binding for nonlocal 'work' found).
- 2026-11-28 01:04 · `R11` · R11 sabotage: check-worker-ahead.py L38: retira def counted(fullmatch, line, pos=0): → Check R11 ou regressão vermelha (rc=1, IndentationError: unexpected indent).
- 2026-11-28 01:04 · `R11` · R11 sabotage: check-worker-ahead.py L39: retira nonlocal work → Check R11 ou regressão vermelha (rc=1, UnboundLocalError: cannot access local variable 'work' where it is not associated with a value).
- 2026-11-28 01:04 · `R11` · R11 sabotage: check-worker-ahead.py L40: retira work += len(line) - pos → Check R11 ou regressão vermelha (rc=1, AssertionError: ('+ ', 0, 0)).
- 2026-11-28 01:04 · `R11` · R11 sabotage: check-worker-ahead.py L41: retira return fullmatch(line, pos) → Check R11 ou regressão vermelha (rc=1).
- 2026-11-28 01:04 · `R11` · R11 sabotage: check-worker-ahead.py L43: retira def compiled(pattern): → Check R11 ou regressão vermelha (rc=1, NameError: name 'compiled' is not defined. Did you mean: 'compile'?).
- 2026-11-28 01:04 · `R11` · R11 sabotage: check-worker-ahead.py L44: retira regex = re.compile(pattern) → Check R11 ou regressão vermelha (rc=1, NameError: name 'regex' is not defined).
- 2026-11-28 01:04 · `R11` · R11 sabotage: check-worker-ahead.py L45: retira return SimpleNamespace(match=regex.match, fullmatch=lambda *args: counted(regex.fullmatch, *args)) → Check R11 ou regressão vermelha (rc=1, AttributeError: 'NoneType' object has no attribute 'match').
- 2026-11-28 01:04 · `R11` · R11 sabotage: check-worker-ahead.py L47: retira scan.__globals__["re"] = SimpleNamespace( → Check R11 ou regressão vermelha (rc=1, SyntaxError: unmatched ')').
- 2026-11-28 01:04 · `R11` · R11 sabotage: check-worker-ahead.py L48: retira match=re.match, search=re.search, sub=re.sub, compile=compiled, → Check R11 ou regressão vermelha (rc=1, AttributeError: 'types.SimpleNamespace' object has no attribute 'compile').
- 2026-11-28 01:04 · `R11` · R11 sabotage: check-worker-ahead.py L49: retira fullmatch=lambda pattern, line: counted(re.compile(pattern).fullmatch, line), → Check R11 ou regressão vermelha (rc=1, AttributeError: 'types.SimpleNamespace' object has no attribute 'fullmatch').
- 2026-11-28 01:04 · `R11` · R11 sabotage: check-worker-ahead.py L50: retira ) → Check R11 ou regressão vermelha (rc=1, SyntaxError: '(' was never closed).
- 2026-11-28 01:04 · `R11` · R11 sabotage: check-worker-ahead.py L51: retira assert scan(marker * n + "<script>\n\n# Owner request\n") == ["owner-request"] → Check R11 ou regressão vermelha (rc=1, AssertionError: ('+ ', 0, 0)).
- 2026-11-28 01:04 · `R11` · R11 sabotage: check-worker-ahead.py L52: retira return work → Check R11 ou regressão vermelha (rc=1, TypeError: '<' not supported between instances of 'int' and 'NoneType').
- 2026-11-28 01:04 · `R11` · R11 sabotage: check-worker-ahead.py L54: retira small, large = measure(2000), measure(4000) → Check R11 ou regressão vermelha (rc=1, NameError: name 'small' is not defined. Did you mean: 'call'?).
- 2026-11-28 01:04 · `R11` · R11 sabotage: check-worker-ahead.py L55: altera assert 0 < small and large <= 3 * small, (marker, small, large) → Check R11 ou regressão vermelha (rc=1, AssertionError: ('+ ', 4023, 8023)).
- 2026-11-28 01:04 · `R11` · R11 sabotage: check-worker-ahead.py L282: retira "compact-scale-hyphens": ("- " * 4000 + "<script>\n\n" + instruction, True), → Check R11 ou regressão vermelha (rc=1, KeyError: 'compact-scale-hyphens').
- 2026-11-28 01:04 · `R11` · R11 sabotage: check-worker-ahead.py L283: retira "compact-scale-pluses": ("+ " * 4000 + "<script>\n\n" + instruction, True), → Check R11 ou regressão vermelha (rc=1, KeyError: 'compact-scale-pluses').
- 2026-11-28 01:04 · `R11` · R11 sabotage: check-worker-ahead.py L284: retira "compact-scale-thematic": ("* " * 4000 + "\n  <script>\n" + instruction, False), → Check R11 ou regressão vermelha (rc=1, KeyError: 'compact-scale-thematic').
- 2026-11-28 01:04 · `R11` · R11 sabotage: check-worker-ahead.py L285: retira "compact-scale-thematic-in-item": ("+ - - -\n    <script>\n  " + instruction, False), → Check R11 ou regressão vermelha (rc=1, KeyError: 'compact-scale-thematic-in-item').
- 2026-11-28 01:04 · `R11` · R11 sabotage: check-worker-ahead.py L296: retira if markup_case in ("compact-scale-hyphens", "compact-scale-pluses"): → Check R11 ou regressão vermelha (rc=1, IndentationError: unexpected indent).
- 2026-11-28 01:04 · `R11` · R11 sabotage: check-worker-ahead.py L297: retira compact_scan_work(content[:2]) → Check R11 ou regressão vermelha (rc=1, IndentationError: expected an indented block after 'if' statement on line 296).
- 2026-11-28 01:04 · `R11` · R11 sabotage: check-worker.sh L6504: retira got= → Check R11 vermelho (rc=1) ao iniciar com a saída da sonda anterior.
- 2026-11-28 01:04 · `R11` · R11 sabotage: check-worker.sh L6505: retira for markup_case in compact-scale-hyphens compact-scale-pluses compact-scale-thematic compact-scale-thematic-in-item; do → Check R11 ou regressão vermelha (rc=2, bloco R11: line 9: syntax error near unexpected token `done').
- 2026-11-28 01:04 · `R11` · R11 sabotage: check-worker.sh L6506: retira if ! result="$(python3 "$ROOT/tests/check-worker-ahead.py" "$ROOT" --preceding-markup "$markup_case" 2>&1)"; then → Check R11 ou regressão vermelha (rc=2, bloco R11: line 8: syntax error near unexpected token `fi').
- 2026-11-28 01:04 · `R11` · R11 sabotage: check-worker.sh L6507: retira got="${got:+$got$'\n'}$markup_case: $result" → Check R11 ou regressão vermelha (rc=2, bloco R11: line 8: syntax error near unexpected token `fi').
- 2026-11-28 01:04 · `R11` · R11 sabotage: check-worker.sh L6508: retira fi → Check R11 ou regressão vermelha (rc=2, bloco R11: line 9: syntax error near unexpected token `done').
- 2026-11-28 01:04 · `R11` · R11 sabotage: check-worker.sh L6509: retira done → Check R11 ou regressão vermelha (rc=2, bloco R11: line 16: syntax error: unexpected end of file).
- 2026-11-28 01:04 · `R11` · R11 sabotage: check-worker.sh L6510: retira if [ -z "$got" ]; then → Check R11 ou regressão vermelha (rc=2, bloco R11: line 12: syntax error near unexpected token `else').
- 2026-11-28 01:04 · `R11` · R11 sabotage: check-worker.sh L6511: troca o marcador verde → Check R11 ou regressão vermelha (rc=0).
- 2026-11-28 01:04 · `R11` · R11 sabotage: check-worker.sh L6512: retira else → Check R11 ou regressão vermelha (rc=1).
- 2026-11-28 01:04 · `R11` · R11 sabotage: check-worker.sh L6513: retira fail 'owner request bounds compact list scan before wait' \ → controle negativo divergiu (rc=127, bloco R11: line 14: bounded scan work and unchanged dispatch, wait and runner verdict: command not found).
- 2026-11-28 01:04 · `R11` · R11 sabotage: check-worker.sh L6514: retira 'bounded scan work and unchanged dispatch, wait and runner verdict' "$got" → Check R11 ou regressão vermelha (rc=2, bloco R11: line 16: syntax error: unexpected end of file).
- 2026-11-28 01:04 · `R11` · R11 sabotage: check-worker.sh L6515: retira fi → Check R11 ou regressão vermelha (rc=2, bloco R11: line 16: syntax error: unexpected end of file).
- 2026-11-28 01:04 · `R11` · R11 sabotage: ignora separador temático mesmo quando a sequência muda de marcador → compact-scale-thematic-in-item vermelho (start indevido antes de wait).
- 2026-11-28 01:04 · `R11` · Os controles antes e depois das sabotagens ficaram verdes, com grupo próprio, teto de 25 s e limite de 256 MiB por processo. Linhas em branco e comentários não alteram o sensor. O procedimento público e o pipeline descrevem o mesmo limite.
- 2026-11-28 01:04 · `R11` · Em fda9359e e 2a7d8917, dobrar de 2.000 para 4.000 marcadores elevou o contador de 4.018.015 para 16.036.015. Em 20664af1, o mesmo ensaio deu 4.023 e 8.023. As quatro fixtures preservaram o despacho, uma espera e o veredito local. R8, R9, R10, a reserva única e a retomada concorrente passaram.
- 2026-11-28 01:04 · `R11` · Ao fim da suíte inicial, a branch continha o commit vazio 3a988471, com a mesma árvore de 2a7d8917. Mantive-o e comparei o diff final com a cópia isolada usada na suíte.
- 2026-11-28 01:04 · `R11` · A primeira execução na cópia sob /tmp recusou o controle externo da sonda de ledger. A repetição usou SDD_MUTATION_FIXTURE_ROOT no checkout da missão, como o sensor prevê, sem alterar a sonda.
- 2026-11-28 01:04 · `R11` · Check R11 → 1. tests/run-all.sh → rc 0, 21 etapas, 112 → 113 sondas do worker e 3 casos skipped do Codex. As 103 âncoras do TODO ficaram no alvo. Nenhum GitHub nem Codex real foi acionado.
- intervention: sdd run --phase REVIEW (the starting phase was forced from the CLI) — REVIEW — 2026-11-28 01:21 · written by the runner
- 2026-11-28 01:39 · `R12` · REVIEW r8, achado #1. Separador temático após HTML de lista não abre parágrafo. O head conta título oculto e inverte o despacho em dois casos. Os controles, R10, R11 e a suíte passaram.
- 2026-11-28 02:31 · `R12` · Base 3731d796: tests/run-all.sh → rc 0. Na fixture pública, hidden disparou antes da espera e duplicate só esperou. visible e root-duplicate ficaram verdes. Todos preservaram uma espera, stderr vazio e o veredito phase-ceiling.
- 2026-11-28 02:31 · `R12` · R12 sabotage: sdd-worker-ahead L84: remove sublinhados da expressão temática → AssertionError: ('thematic-after-html-underscores', ['wait'], ['start', 'wait']) (rc=1)
- 2026-11-28 02:31 · `R12` · R12 sabotage: sdd-worker-ahead L120: restaura a leitura do separador como texto → AssertionError: ('thematic-after-html-hidden', ['wait'], ['start', 'wait']) (rc=1)
- 2026-11-28 02:31 · `R12` · R12 sabotage: check-worker-ahead.py L209: retira thematic = "10. - <script></script>\n\n    ***\n<sample-box>\n" → NameError: name 'thematic' is not defined (rc=1)
- 2026-11-28 02:31 · `R12` · R12 sabotage: check-worker-ahead.py L287: retira "thematic-after-html-hidden": (thematic + instruction, False), → KeyError: 'thematic-after-html-hidden' (rc=1)
- 2026-11-28 02:31 · `R12` · R12 sabotage: check-worker-ahead.py L288: retira "thematic-after-html-visible": (thematic + "\n" + instruction, True), → KeyError: 'thematic-after-html-visible' (rc=1)
- 2026-11-28 02:31 · `R12` · R12 sabotage: check-worker-ahead.py L289: retira "thematic-after-html-duplicate": (instruction + "\n" + thematic + instruction, True), → KeyError: 'thematic-after-html-duplicate' (rc=1)
- 2026-11-28 02:31 · `R12` · R12 sabotage: check-worker-ahead.py L290: retira "thematic-after-html-root-duplicate": (instruction + "\n" + thematic + "\n" + instruction, False), → KeyError: 'thematic-after-html-root-duplicate' (rc=1)
- 2026-11-28 02:31 · `R12` · R12 sabotage: check-worker-ahead.py L291: retira "thematic-after-html-hyphens": (thematic.replace("***", "- - -") + instruction, False), → KeyError: 'thematic-after-html-hyphens' (rc=1)
- 2026-11-28 02:31 · `R12` · R12 sabotage: check-worker-ahead.py L292: retira "thematic-after-html-in-item": ("10. ***\n<sample-box>\n" + instruction, False), → KeyError: 'thematic-after-html-in-item' (rc=1)
- 2026-11-28 02:31 · `R12` · R12 sabotage: check-worker-ahead.py L293: retira "thematic-after-html-underscores": (thematic.replace("***", "_ _ _") + instruction, False), → KeyError: 'thematic-after-html-underscores' (rc=1)
- 2026-11-28 02:31 · `R12` · R12 sabotage: check-worker.sh L6518: retira thematic_failures= → bloco R12: line 18: thematic_failures: unbound variable (rc=1)
- 2026-11-28 02:31 · `R12` · R12 sabotage: check-worker.sh L6519: retira for markup_case in thematic-after-html-{hidden,visible,duplicate,root-duplicate,hyphens,underscores,in-item}; do → bloco R12: line 14: markup_case: unbound variable (rc=1)
- 2026-11-28 02:31 · `R12` · R12 sabotage: check-worker.sh L6520: retira if ! result="$(python3 "$ROOT/tests/check-worker-ahead.py" "$ROOT" --preceding-markup "$markup_case" 2>&1)"; then → bloco R12: line 16: syntax error near unexpected token `fi' (rc=2)
- 2026-11-28 02:31 · `R12` · R12 sabotage: check-worker.sh L6521: retira thematic_failures="${thematic_failures:+$thematic_failures$'\n'}$markup_case: $result" → bloco R12: line 16: syntax error near unexpected token `fi' (rc=2)
- 2026-11-28 02:31 · `R12` · R12 sabotage: check-worker.sh L6522: retira fi → bloco R12: line 17: syntax error near unexpected token `done' (rc=2)
- 2026-11-28 02:31 · `R12` · R12 sabotage: check-worker.sh L6523: retira done → bloco R12: line 27: syntax error: unexpected end of file (rc=2)
- 2026-11-28 02:31 · `R12` · R12 sabotage: check-worker.sh L6524: retira if [ -z "$thematic_failures" ]; then → bloco R12: line 20: syntax error near unexpected token `else' (rc=2)
- 2026-11-28 02:31 · `R12` · R12 sabotage: check-worker.sh L6525: retira pass 'owner request treats thematic breaks as paragraph boundaries before html' → bloco R12: line 20: syntax error near unexpected token `else' (rc=2)
- 2026-11-28 02:31 · `R12` · R12 sabotage: check-worker.sh L6526: retira else → Check R12 sem a saída exigida no controle verde (rc=1)
- 2026-11-28 02:31 · `R12` · R12 sabotage: check-worker.sh L6527: retira fail 'owner request treats thematic breaks as paragraph boundaries before html' → bloco R12: line 22: one turn before wait only for a unique visible heading, with the same runner verdict: command not found (rc=0)
- 2026-11-28 02:31 · `R12` · R12 sabotage: check-worker.sh L6528: retira 'one turn before wait only for a unique visible heading, with the same runner verdict' "$thematic_failures" → bloco R12: line 27: syntax error: unexpected end of file (rc=2)
- 2026-11-28 02:31 · `R12` · R12 sabotage: check-worker.sh L6529: retira fi → bloco R12: line 27: syntax error: unexpected end of file (rc=2)
- 2026-11-28 02:31 · `R12` · R12 sabotage: sdd-worker-ahead L120: confere o separador antes do marcador do item → AssertionError: ('thematic-after-html-in-item', ['wait'], ['start', 'wait']) (rc=1)
- 2026-11-28 02:31 · `R12` · Os controles verde e negativo passaram antes e depois das 23 sabotagens em cópia isolada, com grupo próprio, teto de 25 s e 256 MiB por processo. Linhas em branco e comentários não alteram o sensor. O procedimento público e o pipeline descrevem o mesmo limite de parágrafo.
- 2026-11-28 02:31 · `R12` · A primeira repetição da suíte passou no worker e reprovou três âncoras de TODO.md deslocadas pela quebra de linha em commands/sdd-worker.md. A correção conservou as linhas do procedimento e o reteste confirmou as 103 âncoras.
- 2026-11-28 02:31 · `R12` · Check R12 → 1. SDD_MUTATION_FIXTURE_ROOT no checkout da missão, tests/run-all.sh → rc 0, 21 etapas, 114 sondas do worker e 3 casos skipped do Codex. R10, R11, reserva única e retomada concorrente verdes. Nenhum GitHub ou planner Codex real foi acionado no reteste.
- intervention: sdd run --phase REVIEW (the starting phase was forced from the CLI) — REVIEW — 2026-11-28 02:49 · written by the runner
- 2026-11-28 03:06 · `R12` · REVIEW r9: cinco asserções vermelhas no blob anterior e sete casos verdes no head, com o veredito do runner preservado. Check R12 → 1. Suíte verde em 21 etapas, 114 sondas do worker e 3 casos skipped do Codex. Nota A em todos os critérios, sem novo incremento.
