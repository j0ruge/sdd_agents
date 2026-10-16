# Notas de execução — o lote 9: o papel de cada palavra

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

- 2026-10-16 08:13 · `PLAN` · Planejado pelo `sdd-planner` com o humano (relay do `/sdd-plan`, 02:39–08:13), 6 decisões, todas a recomendada, mais a instrução de consultar a `todo-to-github-issues` antes de editar o `TODO.md`. O gemba achou quatro membros novos da família do #270, todos dentro do modelo da decisão 2: a opção entre aspas (`'-v'`, `"-F"`), o `--fixed-regexp`, o `-z` com `.*` e o `-X fgrep`. E corrigiu uma suposição do grill: o argumento de opção entre aspas (`-m '1'`) nunca causou falso positivo, só os fail-opens.
- 2026-10-16 08:18 · `PLAN` · Decisão 8 (pergunta 7, a recomendada): as duas leituras do gemba valem — padrão recusado é o que começa por expansão, e a isenção do par de zeros exige topo, stdout não redirecionada, padrões literais e lista positiva de opções. Artefatos prontos para o aceite.
- 2026-10-16 09:04 · `PLAN` · Aprovado pelo humano (`a4eaa89`). Depois do aceite, o relay registrou um achado de `commands/` combinado com o humano no grill (o passo 2 do `/sdd-plan` pede a branch antes de o id existir), `6e20c92`, catraca 14 → 15, consultando antes a `todo-to-github-issues` (`--audit` auto=0 manual=0). Com ele o backlog vai de 15 para 12 no chore pós-merge, não de 14 para 11 como o `00-missao.md` diz; o Check do I5 lê a contagem do sensor e não muda.

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

- 2026-10-16 09:25 · `EXEC` · I1 feito (`61bc9e9`): `r2_merges` nos três sítios; grupo de 31 probes (M1–M13 e C1–C8 do plano, mais 10), `PROBE_FLOOR` 128 → 159, `RULE_FLOOR` 4 → 5. Red no HEAD pelo motivo certo: 13 mesclas saíam `0 under` com rc 0, o M13 dizia `0 under` em vez de `1 under`, e o `2>&10` era lido como mescla por substring; o M2 (`2>&1-`) e os controles já eram verdes. Medida nos alvos: **114 → 114** (`lighthouse_project` `b39ab0d`, `sales_quote` `a1ad4b74`), com a saída do `--check` idêntica byte a byte à do sensor da base. Varredura do kit igual (197 cells, 262 rows, 31 files). Check do I1 → `1`.
- 2026-10-16 09:25 · `EXEC` · I1, sabotagem: 34 degradações, cada uma ancorada em código com a contagem exata de ocorrências, aplicada numa cópia privada; todas vermelhas (rc 90/91/92). Cobriram os ramos do `r2_merges` (alvo 1, alvo indecidível, `<&` no laço e no pré-filtro, `&>` e `>&` no pré-filtro, `&>>` nas duas formas, `1>&`, a exceção do null nos dois sítios, o null por "contém" e por "começa por", cada terminador do null, o `0*` e o `([^0-9]|$)` do fd 1, o pulo de brancos, a classe de descritor, o fd 1 de qualquer descritor, o `&>` com dígito e o branco inicial), os três sítios de volta ao literal, e o `rule_ok` e um probe apagados. Na 1ª rodada sobreviveram duas, que viraram probes: o branco depois do `/dev/null` (o C8 só o via numa captura que nenhum grep lê) e o operador no índice 0 (o offset -1 do bash lê o último caractere). O "piso baixado" sozinho não fica vermelho por construção, porque o piso é um mínimo; o que ele guarda (probe ou `rule_ok` apagado) morre com rc 92.
- 2026-10-16 09:25 · `EXEC` · I1, fora da letra do plano: (1) `&>` e `&>>` mesclam para qualquer nome, dígito ou `-` inclusive (medido: `&>1` grava o arquivo `1`), com o probe `&>1`; ao pé da letra, o "alvo que não começa por dígito nem `-`" deixaria `&>1` falhando aberto. (2) Sem o teste "`2` não precedido de dígito": `12>&1` continua lido como mescla, como no HEAD (lado fechado). (3) `2>&10` deixou de ser mescla, pela regra do plano (alvo `1` com zeros à esquerda); é o terceiro descritor declarado no cabeçalho. (4) Os 10 probes além da tabela: `2<&$one`, `&>1`, `&>/dev/null.log`, `&> /dev/null`, `2>&10`, `3>&1`, o `/dev/null` antes de um branco, a captura silenciada no null, e o operador no índice 0 (dois). O C2 e o C3 do plano ganharam terminadores próprios (`&>>/dev/null&&` e a crase). As âncoras do `TODO.md` voltaram ao alvo, com a skill consultada antes (#269 `:725` `r2_merges`, #270 `:465`, #272 `:730`); o `--audit` deu `auto=0 manual=0`.
