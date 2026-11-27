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
