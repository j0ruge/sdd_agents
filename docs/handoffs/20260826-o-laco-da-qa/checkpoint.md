---
missao: 20260826-o-laco-da-qa
atualizado: 2026-08-26 16:12
---

# Checkpoint — a fase QA para de girar em bug que ninguém pode fechar

> **Este arquivo é lido por máquina.** O runner faz parse da tabela abaixo para decidir a
> próxima fase. Não mude as colunas, não mude os tokens de status, não quebre linhas dentro de
> uma célula. Detalhe narrativo vai no `01-plano.md`, não aqui.
>
> Atualizar o checkpoint é o **último ato** de cada incremento — depois do commit, nunca antes.
> Status válidos: `pending` · `doing` · `done` · `blocked`.

| ID | Incremento | Check (comando → esperado) | Status | Commit |
|---|---|---|---|---|
| I1 | o arquivo de bug declara quem pode fechá-lo | `grep -c 'Closable by:' docs/qa/templates/bug.md` → `1` (o comentário de enum na forma dos outros campos está descrito no 01-plano.md, I1) | done | 525b216 |
| I2 | a Âncora 3 distingue gênero, e o desconhecido barra | `o=$(bash tests/check-gates.sh 2>&1); grep -c '^  ok    ' <<< "$o"` → 3 a mais que antes; e a asserção **diferencial** (gênero humano passa × gênero agente reprova, saídas comparadas entre si) entre os `ok` | done | 0a0f760 |
| I3 | `status: blocked` escala na primeira sessão | `o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    ' <<< "$o"` → 1 a mais; o regime novo prova **uma** sessão e rc 3, onde hoje são duas | done | 4c9b080 |
| I4 | o contrato do `sdd-qa` para de mentir | depois de `./bin/sdd install --force`: `cmp -s agents/sdd-qa.md .claude/agents/sdd-qa.md; echo espelho=$?` → `espelho=0` (byte a byte, medido), e `grep -c 'do not block the pipeline' agents/sdd-qa.md` → `0` | done | cf43bb3 |

## Notas de execução

> Uma linha por evento relevante: bloqueio, decisão tomada, desvio do plano com justificativa.
> É o que a próxima sessão lê para não repetir um erro que já custou caro.

- 2026-08-26 13:06 · `PLAN` · plano fechado com o humano presente. A raiz é maior que os dois achados diziam: `agents/sdd-qa.md:142` **proíbe** qualquer agente de escrever `Status:` — o dono é a skill. Por isso bug de gênero humano é insatisfazível por construção, e por isso a opção C (gênero) e não a B (dar o poder ao agente).
- 2026-08-26 13:06 · `PLAN` · ⚠️ o registry do PRÓPRIO kit está limpo (6 bugs, 0 `open`), então o regime que esta missão conserta **não é reproduzível** pelo registry real — os testes constroem o registry em fixture.
- 2026-08-26 15:40 · `EXEC` · I1 `done` em `525b216`. Baseline antes de tocar em nada: `tests/run-all.sh` → `suite green`, rc 0. Red observado antes da edição: `grep -c 'Closable by:' docs/qa/templates/bug.md` → `0`; depois → `1`. Suíte depois: `suite green`, rc 0, 656 asserções, 0 FAIL.
- 2026-08-26 15:40 · `EXEC` · ⚠️ **Leia antes de escrever a âncora do I2.** A forma escolhida foi `- **Closable by:** agent <!-- agent | human -->`, a mesma do `Status:` — valor **colado** ao nome do campo, enum no comentário. Motivo medido: os arquivos reais do registry **preservam** o comentário de enum (`grep -h '^- \*\*Status:\*\*' docs/qa/bugs/*.md` → 6 de 6 com a legenda), então a palavra `human` vai existir em **todo** arquivo de bug, dentro do comentário. Uma âncora `.*human` falha aberta e desliga a Âncora 3 para o registry inteiro — que é exatamente a armadilha já registrada em `bin/sdd:587-588` para o `closed`. Ancore em `^\-[[:space:]]+\*\*Closable by:\*\*[[:space:]]+human`; medido contra o template novo, que responde `0`.
- 2026-08-26 15:40 · `EXEC` · Desvio de forma com justificativa: o `01-plano.md` grafa o valor como `<agent | human>`; foi implementado como o default concreto `agent`. A assimetria é contrato — marcar `human` exige procedência citada em `arquivo:linha` (I4), e `agent` é o que vale até alguém provar o contrário. Os dois fecham igual sob âncora estrita (arquivo não triado barra, decisão 3 do grill); o default concreto ganha por simetria com o campo irmão que a Âncora 3 já lê.
- 2026-08-26 15:40 · `EXEC` · Para a fase `DOCS` (drift desta missão, não é achado fora de escopo): `docs/qa/README.md:109-113` descreve a Âncora 3 como "counts files … matching `- **Status:** open` and refuses the phase while any exist", que o I2 torna falso. O mesmo parágrafo já cita `bin/sdd:485-491`, e hoje esse trecho é prosa do `gate_TICKET` — a Âncora 3 está em `bin/sdd:598`. Re-ancorar junto com a reescrita.
- 2026-08-26 17:05 · `EXEC` · I2 `done` em `0a0f760`. Baseline antes de tocar em nada: `tests/run-all.sh` → `suite green`, rc 0, 656 asserções. Depois: `suite green`, rc 0, **659** asserções, 0 FAIL. `check-gates.sh`: **129 → 132** `ok`, exatamente os 3 do Check.
- 2026-08-26 17:05 · `EXEC` · Red observado antes da implementação e **pelo motivo certo**, não só vermelho: o diferencial respondeu `QA|QA|same` (esperado `REVIEW|QA|differ`) e o par de marcadores respondeu `1|1` (esperado `0|1`) — ou seja, o regime humano barrava exatamente como o de agente, que é o defeito. A terceira asserção (fail-safe, campo ausente) já passava no vermelho, de propósito: ela não mede o defeito, mede o conserto não ir longe demais.
- 2026-08-26 17:05 · `EXEC` · ⚠️ **Lição do mutante, para quem escrever o do I3.** A primeira forma do `mut_QA_bug_genre_ignored` ancorava em `.*Closable by.*human.*` e teria casado **duas linhas de comentário** do `bin/sdd` além da linha de código — comentário que carrega as mesmas palavras da regra que descreve. Um mutante que reescreve só comentário **aplica** (passa da guarda `cmp -s`, rc 90) e não sabota nada: entraria no catálogo certificando uma proteção que ninguém mede, que é a classe já registrada em `mut_LEDGER_repo_root_cdpath_leak`. A âncora final é a linha de CÓDIGO inteira (`^    if grep -qE .*Closable by.*then continue; fi$`). Verificado à mão numa sandbox antes de commitar: aplica em exatamente 1 linha, `bash -n` verde, e `check-gates.sh` morre com `QA|QA|same`.
- 2026-08-26 17:05 · `EXEC` · Para o I3 — o que já está lido no arquivo, para não re-descobrir: `bin/sdd:564` publica `GATE_WHY="30-handoff-qa.md has status: blocked"` quando o handoff declara `blocked`, e é o **único** ponto do `gate_QA` que usa a palavra. O risco previsto no `01-plano.md` (*"a saída antecipada escapa por outro `GATE_WHY` que contenha a palavra"*) é real para os outros gates, que têm cada um a sua frase — confira antes de ancorar em prosa e, se não houver token estável, crie um, como o plano manda.
- 2026-08-26 15:35 · `EXEC` · I3 `done` em `4c9b080`. Baseline antes de tocar em nada: `tests/run-all.sh` → `suite green`, rc 0, 580 `ok`; `check-autonomy.sh` → rc 0, **184**. Depois: `suite green`, rc 0, **581** `ok`; `check-autonomy.sh` → rc 0, **185**, exatamente o 1 a mais do Check.
- 2026-08-26 15:35 · `EXEC` · Red observado antes da implementação e **pelo motivo certo**: as duas metades do diferencial responderam `3|2|blocked|no-progress · 3|2|blocked|no-progress` — ou seja, o handoff `blocked` girava idêntico a uma reprovação ordinária, que é o defeito. A segunda metade já passava no vermelho, de propósito: ela não mede o defeito, mede o conserto não ir largo demais.
- 2026-08-26 15:35 · `EXEC` · Desvio do plano com justificativa: o `01-plano.md` põe a saída nova *"antes do teste de `moved2`"*; foi implementada antes do teste de **`moved`**, na primeira volta. A Métrica 4 (*"sai 3 na primeira sessão"*) só fecha aí — um ramo antes de `moved2` já custou a sessão de retry. O ponto de amostragem de `moved2` **não** foi movido, que é o que o plano de fato proíbe.
- 2026-08-26 15:35 · `EXEC` · ⚠️ **Marcador, não prosa.** O ramo lê o global `GATE_HANDOFF_BLOCKED` (forma do `GATE_EXEC_DIRTY`, `bin/sdd:493`) e nunca um substring de `GATE_WHY` — a palavra "blocked" também aparece na linha de Jidoka do `gate_EXEC` (`:534`), e era esse o risco nomeado no `01-plano.md`. O contrato está escrito acima do global: quem ensinar o token a um **segundo** gate reseta o marcador na **entrada daquele gate**, nunca no call site, porque `current_phase` percorre todos os gates em ordem e um marcador esquecido escalaria a fase errada.
- 2026-08-26 15:35 · `EXEC` · Passada de sabotagem adversarial rodada nos **dois** sentidos, em sandbox, porque uma metade sozinha do diferencial é decoração: ramo neutralizado (`if false`) → a 1ª metade responde `3|2|…|no-progress`; ramo largo demais (`if true`) → a 2ª responde `3|1|…|handoff-blocked` e mais 5 asserções antigas morrem junto. O mutante `RUN_blocked_not_escalated` foi verificado pelo critério do próprio catálogo: controle `SDD_MUTANT=1 run-all.sh` rc **0**, mutante rc **1** com **1** FAIL.
- 2026-08-26 15:35 · `EXEC` · **Para o I4 e para quem for carimbar:** `MUTATION_STAMP_PATHS=(bin tests templates config)` (`bin/sdd:880`) — `agents/` **não** está na chave, então o I4 (que edita `agents/sdd-qa.md` + `sdd install --force`) **não** invalida o carimbo. Logo `4c9b080` é o último commit de código que invalida, e `./bin/sdd health --with-mutation` pode rodar de agora em diante. ⚠️ `tests/health-baseline.txt` **invalida** (está sob `tests/`), então registrar achado no `TODO.md` depois do carimbo o mata — a colisão já está no `TODO.md` do kit.
- 2026-08-26 15:52 · `EXEC` · I4 `done` em `cf43bb3`. Baseline antes de tocar em nada: `tests/run-all.sh` → `suite green`, rc 0; `./bin/sdd preflight` → `preflight ok`. Depois: `suite green`, rc 0, **581** `ok`, 0 FAIL; `preflight ok` com `7 kit agent(s) checked` e working tree limpo. **Com isto não sobra linha `pending` na tabela** — o `20-handoff-exec.md` foi escrito e a fase EXEC fecha.
- 2026-08-26 15:52 · `EXEC` · Red observado antes da edição: `grep -c 'do not block the pipeline' agents/sdd-qa.md` → **1** (esperado `0`); depois → `0`. A outra metade do Check (`cmp -s` fonte × espelho) já respondia `espelho=0` no vermelho, de propósito: ela não mede o defeito, mede o conserto não esquecer o `install --force`. Que ela **não é constante** foi medido, e não suposto: `git show 1fa833f:.claude/agents/sdd-qa.md` reconstrói o espelho no estado "fonte editada, install ainda não rodado", e `cmp -s` contra a fonte de hoje responde `espelho=1`. A primeira redação desta nota afirmava a medição na ordem cronológica sem tê-la feito — foi refeita pelo método acima antes de virar asserção.
- 2026-08-26 15:52 · `EXEC` · Além das duas edições do plano (o `§ 5` e o dever de marcar), entrou uma terceira, pequena e da mesma família: `agent`/`human` foi acrescentado à lista de contrato da seção `Language`. Motivo — este repo declara `OUTPUT_LANG=pt-BR`, o `§ 5.1` manda o agente **escrever** o gênero, e gênero traduzido é gênero que a Âncora 3 não lê; o que ela não lê, conta como ausente, que barra.
- 2026-08-26 15:52 · `EXEC` · ⚠️ **Desvio de escopo deliberado, com justificativa medida — leia antes de chamar de fuga de escopo.** O `§ 5.1` empurrou a regra não-negociável de `agents/sdd-qa.md:142` para `:172`, e **três comentários vivos** citavam a 142 pelo número: `bin/sdd` (2×) e `tests/check-gates.sh` (1×). Hoje a linha 142 cai no meio do `§ 6`. Foram reancorados no **mesmo commit** — é o que o `CLAUDE.md` manda para contrato quebrado em mais de um lugar — e no **heading** (`"Rules that are not negotiable"`) em vez do número, que é o que impede a próxima podridão. Não virou item de `TODO.md` pela régua do D15 (não é fail-open, não tem consumidor fora do kit) e porque a varredura `grep -n '\.md:[0-9]' bin/sdd tests/*.sh agents/*.md` mostrou que **todo anchor restante é PROVENANCE de skill de terceiro**, apontando para fora do repo, onde a forma é deliberada. Custo incremental do desvio: **zero** — o carimbo de mutação já estava inválido desde `525b216`, então tocar `bin/` e `tests/` não comprou volta nenhuma.
- 2026-08-26 15:52 · `EXEC` · ⚠️ **Correção da nota do I3:** ela diz que `4c9b080` é o último commit de código que invalida o carimbo. Deixou de ser verdade pelo item acima — o último é **`cf43bb3`**, e é depois dele que o `sdd health --with-mutation` rodou. O que continua valendo: `agents/` não está em `MUTATION_STAMP_PATHS` (`bin/sdd:880`), então a edição do agente sozinha **não** invalidaria. Carimbo tirado e verde: `kit healthy`, `mutation: score: 150 caught, 0 known gap(s), of 150`, `all 8 gates have a mutation in the catalogue`, `ratchet: 1 known debt(s), none new`. Os dois mutantes desta missão estão registrados na lista do catálogo, e não só definidos — `QA_bug_genre_ignored` (`tests/check-mutation.sh:1814`) e `RUN_blocked_not_escalated` (`:1849`), conferidos por `grep` porque "está no arquivo" e "está na lista" são coisas diferentes.
- 2026-08-26 13:06 · `PLAN` · ⚠️ `sdd health --with-mutation` roda **depois do último commit de código** (a chave do carimbo é o conteúdo de `bin/ tests/ templates/ config/`). Medido nesta máquina em 2026-08-25: 12min32s.

> **Toda vez que um humano precisou entrar na linha** — um `sdd retry`, um conserto à mão, um
> `BLOCKED` assumido — sai uma linha com o marcador `intervention:`. É o que o
> `sdd autonomy --by-mission` conta, e é a metade que o custo sozinho não mostra: US$ baixo não
> distingue "rodou barato" de "rodou barato porque um humano fez metade".
>
> ⚠️ O marcador é **inglês e minúsculo**, como `pending`/`done`/`blocked`: é contrato, não prosa.
> O texto depois dos dois-pontos vai no idioma do `OUTPUT_LANG`, como o resto deste arquivo.
> Só conta quando abre a linha — `intervention` no meio de uma frase é prosa e não é contado.
>
> O exemplo abaixo mora **dentro** desta citação de propósito: o `>` quebra o casamento com
> `^[[:space:]]*-`, e sem ele o exemplo era contado verbatim — todo checkpoint recém-instanciado
> nascia devendo uma intervenção fantasma ao instrumento que mede autonomia. Copie a forma para
> fora da citação ao registrar uma intervenção de verdade.
>
> - intervention: <o que o humano teve de fazer> — <fase> — <custo, se houver>

## Incrementos de fix (QA)

> Escritos pelo `sdd-qa` quando um bug sanável é reprovado. Entram na mesma tabela acima com ID
> `F<n>`, e o Check obrigatoriamente inclui **regression test passa** + **re-walk da jornada
> impactada verde**. Bug que exige julgamento humano NÃO vira fix — vai para
> "Decisions for a Human" no handoff de QA.
