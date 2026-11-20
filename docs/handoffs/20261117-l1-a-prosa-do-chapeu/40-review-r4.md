---
missao: 20261117-l1-a-prosa-do-chapeu
fase: REVIEW
rodada: 4
status: done
sessao: subagente do worker (rodada do chore de pós-merge, PR #447)
data: 2026-11-20 01:54
gate: tests/run-all.sh rc 0 em 90b5906, "suite green", 0 linhas ^  FAIL, 2186 linhas ^  ok; check-todo 91; árvore limpa; diff a0b6fdb..90b5906
reviewed_head: 90b5906e27851b174535b3a5915d887bb859fce4
---

# Review — rodada r4 — L1: o chore de pós-merge (PR #447)

## TL;DR

Rodada sobre `a0b6fdb..90b5906`, o chore de pós-merge do L1: 14 itens `RESOLVED by` apagados (8 hashes, todos ancestrais
de `origin/main`), 1 item novo (`turn_rule`), a catraca 104 → 91, a receita de espera do revisor com `<rcfile>`, duas
frases no `failure-modes.md`, duas asserções no `check-hat.sh`, o fecho no `KAIZEN_LOG.md` e na F6, e o diário da campanha.
Os LOW 1 a 4 da r3 e os três Minor do CodeRabbit no `4fc4ddd` fecharam. Quatro achados, todos LOW de prosa, para um
lote; nenhum incremento R, nenhuma pendência humana. Nota: A em todo critério (Régua A: LOW não segura critério).

## Nota da rodada

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | A | A receita separa a saída do status numa frase por ideia, o espelho é igual à fonte (cmp rc 0) e os 14 blocos saíram inteiros, sem mover outra linha do TODO.md. |
| Type Safety | A | n/a: bash e markdown; shellcheck -S warning limpo no tests/check-hat.sh. |
| Error Handling | A | A espera por [ -s <rcfile> ] fecha as duas saídas erradas da grafia antiga (linha rc= na saída, última linha sem newline), e o escritor morto continua lido por kill -0 com o rcfile vazio. |
| Security | A | Pré-varredura de segredos (regex + gitleaks) limpa nas 131 linhas acrescentadas dos 11 arquivos; o permissionsDeny do revisor não mudou e não nega o rm -f novo. |
| Performance | A | Duas asserções grep -F sobre seções já extraídas; o check-hat.sh roda em segundos e imprime 123 linhas ok. |
| Test Coverage | A | Cada literal das duas asserções ocorre uma vez no arquivo e dentro da seção que ela lê (sdd-reviewer.md:156-157, failure-modes.md:817 e :820), então a frase apagada fica vermelha; check-todo responde 91, igual à catraca. |
| Documentation | A | As somas do KAIZEN_LOG e da F6 conferem com o pipeline.log sob LC_ALL=C, e os shas e horas do diário conferem com o git; sobram quatro LOW de prosa para um lote. |
| **Overall** | **A** | Chore de prosa, catraca e duas asserções sem achado acima de LOW, com a suíte verde no head (rc 0, 0 FAIL). |

## Achados da rodada

| # | Severidade | Achado | Onde |
|---|---|---|---|
| 1 | LOW | O item novo põe "no L1" o `sdd why … EXEC` cortado aos 2 min, e o corte foi no `magic_tutor`; no L1 ele voltou como o item N | `TODO.md:781` |
| 2 | LOW | O fecho diz que os 5 LOW da r3 foram para o chore, e o chore fechou 4; o 5º (opcional) não foi aplicado nem recusado por escrito | `KAIZEN_LOG.md:47`, `docs/superpowers/campaigns/20261117-zerar-as-issues/handoff-L1.md:28` |
| 3 | LOW | A receita de espera não diz onde ficam `<output>` e `<rcfile>`; arquivo não rastreado no repo, fora do `writes:` do revisor, para a linha como `hat-crossed` | `agents/sdd-reviewer.md:156` (e o espelho), `docs/handoffs/20261117-l1-a-prosa-do-chapeu/45-docs.md:89` |
| 4 | LOW | A corrida forçada morta antes do fim da 1ª sessão pode escrever linha própria (`LEFTOVER`), e o texto diz que não escreve | `docs/failure-modes.md:816-819` |

Detalhe, com evidência e conserto proposto (esta rodada não aplica nenhum):

1. **Evidência:** o `00-missao.md:53` da missão diz "o `sdd why … EXEC` do `magic_tutor` foi cortado aos 2 min do
   Bash", e o commit `c02da26` (item N) diz o mesmo. O `45-docs.md` conta o item N entre as três voltas ("o item N, a
   suíte do executor no I6 e no I9, e o R1 da r1"); o item novo trocou "o item N" pelo evento, e o evento passou a ler
   como ocorrido no L1. **Conserto:** "o item N (o `sdd why … EXEC` do `magic_tutor`, cortado aos 2 min)", ou "voltou
   três vezes no L1 e nos itens dele", dentro dos 120 caracteres.
2. **Evidência:** o LOW 5 da r3 (`agents/sdd-docs.md:61-64`, a frase que supõe a lição reincidente no `CLAUDE.md`)
   tinha conserto marcado como opcional. O `c105407` não toca `agents/sdd-docs.md`, e nem ele nem o `handoff-L1.md`
   dizem que o 5º ficou. **Conserto:** "os LOW 1 a 4 da r3 (o 5º, opcional, fica como limite de escopo)" nos dois
   lugares, ou aplicar a frase sugerida na r3.
3. **Evidência:** o `writes:` do `sdd-reviewer` é `$HANDOFF_DIR/$MISSION/**`, e o `hat_status_lines`
   (`bin/sdd:4678`) lê a árvore com `--untracked-files=all`, então um `<rcfile>` ou um `<output>` gravado na raiz do
   alvo é caminho fora do `writes:`. A lacuna já existia com o `<output>` da grafia antiga; a receita nova soma um
   segundo arquivo. O mesmo chapéu já diz, para a cópia de reprodução, que ela "lives outside the repo"
   (`agents/sdd-reviewer.md:88-89`). Não reproduzido numa sessão real. **Conserto:** "both files outside the repo
   (a `mktemp -d`)" logo abaixo da receita, e o mesmo no texto `⛔` do `45-docs.md`.
4. **Evidência:** o `run_phase` escreve `LEFTOVER <fase>` antes de abrir a sessão nova quando há sobra
   (`bin/sdd:5568`), e o ramo forçado do `cmd_run` (`bin/sdd:9735`) chega a ele. A ressalva "unless it had to switch
   branch" (`bin/sdd:6543`) fica presa à corrida derivada pela sintaxe da frase. O remédio do parágrafo ("compare the
   line's time with the launch") cobre o caso, então é forma, não comportamento. **Conserto (opcional):** "writes no
   line of its own, unless it had to switch branch or found leftovers (`LEFTOVER`), and neither does …".

Conferido inline (uma só peça de código, `tests/check-hat.sh`; o resto é prosa):

- **Os 14 itens apagados:** cada bloco removido tem `RESOLVED by` (`2b01f33` ×3, `596627b` ×3, `abe5808` ×2,
  `b51657d` ×2, `40c836b`, `781fe39`, `bc8710f`, `c02da26`), e os 8 hashes respondem `git merge-base --is-ancestor
  <hash> origin/main` rc 0. Nenhuma linha não vazia foi removida fora desses blocos, e as 11 linhas em branco
  removidas são 14 menos as 3 que separavam itens colados. Nenhum token `RESOLVED by <hash>` sobra no arquivo.
- **O item novo:** âncora `bin/sdd:3375` com `turn_rule` (a linha é `turn_rule="Never end the turn…`), 7 linhas,
  a maior com 115 bytes, `descoberto por` por último, título sem número que muda, na seção "Sem seção — chegaram
  depois da última classificação". `bash tests/check-todo.sh --check TODO.md` → `91 finding(s)`, rc 0, igual à
  catraca (104 − 14 + 1). A seção `### Idioma` ficou vazia, como a `### Comentário e registro` já estava; o
  template deixa as categorias livres.
- **A receita do revisor:** `cmp agents/sdd-reviewer.md .claude/agents/sdd-reviewer.md` rc 0. O `rm -f` antes do
  lançamento impede um `<rcfile>` velho de encerrar a espera nova; o subshell grava o status antes de sair, então
  "morto e `<rcfile>` vazio" só acontece com o processo morto antes do fim do comando. O texto `⛔` do `45-docs.md`
  usa a mesma grafia.
- **O `failure-modes.md` contra o `bin/sdd`:** o ramo forçado (`bin/sdd:9735`) não chama o `pipeline_log_line …
  PHASE`, que só o ramo derivado escreve (`bin/sdd:9749`); o aviso `the pipeline journal at … cannot be written`
  existe (`bin/sdd:3630`), sai uma vez por journal e a corrida segue (`return 0`).
- **As asserções do `check-hat.sh`:** `bash tests/check-hat.sh` rc 0, 123 `ok`, 0 `FAIL`; as duas linhas novas em
  `ok`. A trocada exige `until [ -s <rcfile> ]` e `echo "$?" > <rcfile>` e recusa `until grep -q "^rc="` na seção
  `sdie` (`### Two ways this session dies`, linhas 143-181); a nova exige `forced with \`--phase\`` e `cannot be
  written` na seção `sec` (a do `sdd run` que sumiu). `shellcheck -S warning` limpo.
- **Os números do fecho:** sob `LC_ALL=C awk` sobre o `pipeline.log` do L1 (`~/repos/sdd_agents-l1`), 15 sessões e
  US$ 20,22 no total, 13 e US$ 17,82 até a REVIEW r2 (21:17), DOCS US$ 1,95 e PR US$ 0,45; a última linha é `PHASE
  PR` com o motivo do carimbo (rc 2). O `KAIZEN_LOG.md`, a F6 e o `handoff-L1.md` dizem isso. A nota datada do
  `45-docs.md` (16 + 3 = 19, + 1 = 20 asserções) confere com o `729fbf6` e o `c105407`.
- **O diário e o handoff do lote:** `ce96b6c` (16:00:17), `e5ceb46` (18:27), `729fbf6` (22:51), `4fc4ddd` (23:13),
  `91a7524` (merge do #446, 23:50:45, pais `cc8509a` e `4fc4ddd`), `a0b6fdb` (merge do #445, 01:31:11) e `604cca4`
  (01:31:26) conferem com as linhas que os citam. O `delegation.md` diz `level: full`, `lots: L1 L1b`,
  `expires: 2026-11-26 18:00` e `signed: … ce7d609fb257`, como o diário. O diff não toca `campaign.md` nem
  `delegation.md`, e o `bin/sdd-worker` não lê o `journal.md`.
- **Sensores rápidos:** `check-lang.sh` rc 0 (0 de 71 caminhos na allowlist), `check-templates.sh` rc 0 (121 `ok`).
- **Código morto:** o diff não acrescenta nem órfã símbolo nenhum (só muda corpos de duas funções de probe).

## Incrementos de conserto (R<n>)

Nenhum incremento nesta rodada. Os quatro achados são LOW de prosa e vão num lote só, pela sessão orquestradora
(Régua A, regra 1).

## O que virou incremento

Nada nesta rodada. Os achados da r3 e do CodeRabbit no `4fc4ddd`:

- LOW 1 da r3 (a corrida forçada por `--phase`) — fechado em `c105407` — `docs/failure-modes.md:816-819` e a
  asserção `doc: failure-modes.md says a run forced with --phase…` em `ok`.
- LOW 2 da r3 (o checklist sem o `729fbf6`) — fechado em `c105407` — nota datada em `45-docs.md:72-76`.
- LOW 3 da r3 (o PR dado como pendente) — fechado em `c105407` — F6 e o fecho do `KAIZEN_LOG.md` citam o merge
  `91a7524`.
- LOW 4 da r3 (as 13 sessões "até a DOCS") — fechado em `c105407` — a F6 diz "13 sessões e US$ 17,82 até a REVIEW
  r2, 15 e US$ 20,22 com a DOCS e a PR".
- LOW 5 da r3 (opcional, `agents/sdd-docs.md:61-64`) — não aplicado; é o achado 2 desta rodada.
- Os três Minor do CodeRabbit no `4fc4ddd` (a espera do revisor e o texto `⛔` com arquivo de status próprio, a
  ressalva do journal no `failure-modes.md`) — fechados em `c105407` — as duas asserções acima em `ok`.

## O que foi refutado

Nada.

## Achados fora de escopo

Nenhum.

## Pendências / Decisions for a Human

Nenhuma.
