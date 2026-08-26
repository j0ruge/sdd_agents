---
missao: 20260826-o-laco-da-qa
atualizado: 2026-08-26 15:40
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
| I2 | a Âncora 3 distingue gênero, e o desconhecido barra | `o=$(bash tests/check-gates.sh 2>&1); grep -c '^  ok    ' <<< "$o"` → 3 a mais que antes; e a asserção **diferencial** (gênero humano passa × gênero agente reprova, saídas comparadas entre si) entre os `ok` | pending | — |
| I3 | `status: blocked` escala na primeira sessão | `o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    ' <<< "$o"` → 1 a mais; o regime novo prova **uma** sessão e rc 3, onde hoje são duas | pending | — |
| I4 | o contrato do `sdd-qa` para de mentir | depois de `./bin/sdd install --force`: `cmp -s agents/sdd-qa.md .claude/agents/sdd-qa.md; echo espelho=$?` → `espelho=0` (byte a byte, medido), e `grep -c 'do not block the pipeline' agents/sdd-qa.md` → `0` | pending | — |

## Notas de execução

> Uma linha por evento relevante: bloqueio, decisão tomada, desvio do plano com justificativa.
> É o que a próxima sessão lê para não repetir um erro que já custou caro.

- 2026-08-26 13:06 · `PLAN` · plano fechado com o humano presente. A raiz é maior que os dois achados diziam: `agents/sdd-qa.md:142` **proíbe** qualquer agente de escrever `Status:` — o dono é a skill. Por isso bug de gênero humano é insatisfazível por construção, e por isso a opção C (gênero) e não a B (dar o poder ao agente).
- 2026-08-26 13:06 · `PLAN` · ⚠️ o registry do PRÓPRIO kit está limpo (6 bugs, 0 `open`), então o regime que esta missão conserta **não é reproduzível** pelo registry real — os testes constroem o registry em fixture.
- 2026-08-26 15:40 · `EXEC` · I1 `done` em `525b216`. Baseline antes de tocar em nada: `tests/run-all.sh` → `suite green`, rc 0. Red observado antes da edição: `grep -c 'Closable by:' docs/qa/templates/bug.md` → `0`; depois → `1`. Suíte depois: `suite green`, rc 0, 656 asserções, 0 FAIL.
- 2026-08-26 15:40 · `EXEC` · ⚠️ **Leia antes de escrever a âncora do I2.** A forma escolhida foi `- **Closable by:** agent <!-- agent | human -->`, a mesma do `Status:` — valor **colado** ao nome do campo, enum no comentário. Motivo medido: os arquivos reais do registry **preservam** o comentário de enum (`grep -h '^- \*\*Status:\*\*' docs/qa/bugs/*.md` → 6 de 6 com a legenda), então a palavra `human` vai existir em **todo** arquivo de bug, dentro do comentário. Uma âncora `.*human` falha aberta e desliga a Âncora 3 para o registry inteiro — que é exatamente a armadilha já registrada em `bin/sdd:587-588` para o `closed`. Ancore em `^\-[[:space:]]+\*\*Closable by:\*\*[[:space:]]+human`; medido contra o template novo, que responde `0`.
- 2026-08-26 15:40 · `EXEC` · Desvio de forma com justificativa: o `01-plano.md` grafa o valor como `<agent | human>`; foi implementado como o default concreto `agent`. A assimetria é contrato — marcar `human` exige procedência citada em `arquivo:linha` (I4), e `agent` é o que vale até alguém provar o contrário. Os dois fecham igual sob âncora estrita (arquivo não triado barra, decisão 3 do grill); o default concreto ganha por simetria com o campo irmão que a Âncora 3 já lê.
- 2026-08-26 15:40 · `EXEC` · Para a fase `DOCS` (drift desta missão, não é achado fora de escopo): `docs/qa/README.md:109-113` descreve a Âncora 3 como "counts files … matching `- **Status:** open` and refuses the phase while any exist", que o I2 torna falso. O mesmo parágrafo já cita `bin/sdd:485-491`, e hoje esse trecho é prosa do `gate_TICKET` — a Âncora 3 está em `bin/sdd:598`. Re-ancorar junto com a reescrita.
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
