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
