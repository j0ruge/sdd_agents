---
missao: 20261117-l1-a-prosa-do-chapeu
fase: REVIEW
rodada: 3
status: done
sessao: subagente do worker (rodada delta do ato review)
data: 2026-11-19 23:12
gate: tests/run-all.sh rc 0 em 729fbf6, "suite green", 0 linhas ^  FAIL, 2185 linhas ^  ok, 904 mutantes aplicáveis; árvore limpa; delta 3f7ad8c..729fbf6
reviewed_head: 729fbf667417db854af3602d88ed58c0fa2bab75
---

# Review — rodada r3 — L1: a prosa do chapéu e dos docs

## TL;DR

Rodada delta sobre `3f7ad8c..729fbf6`: a DOCS (`KAIZEN_LOG.md`, linha F6 da gaveta, `45-docs.md`), o `50-pr.md` e o
`729fbf6`, que conserta os seis achados do CodeRabbit no PR #446 (dois chapéus e espelhos, `docs/failure-modes.md`,
três asserções no `tests/check-hat.sh`, o texto ⛔ do `45-docs.md`). Os seis fecharam como escritos. Cinco achados,
todos LOW de prosa, para um lote da sessão orquestradora; nenhum incremento R novo, nenhuma pendência humana.
Nota: A em todo critério (Régua A: LOW não segura critério abaixo de A).

## Nota da rodada

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | A | Os três parágrafos novos dizem uma coisa cada e os dois chapéus editados são iguais ao espelho (cmp rc 0 em sdd-docs e sdd-reviewer). |
| Type Safety | A | n/a: bash e markdown; shellcheck -S warning limpo no tests/check-hat.sh. |
| Error Handling | A | A receita de espera ganhou a saída para o escritor que morreu (kill -0 sem linha rc= encerra como falha), e kill não está no permissionsDeny do revisor. |
| Security | A | Pré-varredura de segredos (regex + gitleaks) limpa nas 317 linhas acrescentadas dos 12 arquivos. |
| Performance | A | Três asserções grep -F sobre seções já extraídas; o check-hat.sh roda em segundos e imprime 122 linhas ok. |
| Test Coverage | A | Três asserções novas com Red registrado no checkpoint-notas.md (3 FAIL antes da prosa) e as três em ok nesta rodada, 0 FAIL no sensor. |
| Documentation | A | Os seis achados do CodeRabbit fecharam como escritos e o verificador conferiu as somas do KAIZEN_LOG.md contra o pipeline.log; sobram cinco LOW de prosa para um lote. |
| **Overall** | **A** | Delta de prosa e três asserções sem achado acima de LOW, com a suíte verde no head (rc 0, 0 FAIL). |

## Achados da rodada

| # | Severidade | Achado | Onde |
|---|---|---|---|
| 1 | LOW | O limite da linha velha do `pipeline.log` nomeia só a corrida morta antes da derivação; a corrida forçada por `--phase`, que o mesmo parágrafo usa de exemplo, nunca escreve linha `PHASE` | `docs/failure-modes.md:814-817` |
| 2 | LOW | O checklist do `45-docs.md` não registra o `729fbf6`, que mudou três documentos dele e acrescentou três asserções | `docs/handoffs/20261117-l1-a-prosa-do-chapeu/45-docs.md:51`, `:52`, `:60`, `:64` |
| 3 | LOW | A F6 da gaveta e o KAIZEN_LOG dão "o PR" como pendente, e o PR #446 já está aberto | `docs/superpowers/specs/2026-09-23-a-gaveta-do-kit.md:21`, `KAIZEN_LOG.md:42` |
| 4 | LOW | "até a DOCS: 13 sessões, US$ 17,82" lê-se como incluindo a DOCS, e as 13 sessões param na REVIEW r2 | `docs/superpowers/specs/2026-09-23-a-gaveta-do-kit.md:21` |
| 5 | LOW | A frase nova do sdd-docs supõe que a regra reincidente mora no `CLAUDE.md`, e o kit roteia lição para sensor ou verbete do `CONTEXT.md` | `agents/sdd-docs.md:61-64` (e o espelho) |

Detalhe, com evidência e conserto proposto (esta rodada não aplica nenhum):

1. **Evidência:** no `bin/sdd`, o ramo forçado do `cmd_run` (`elif [ -n "$force_phase" ]`, linha 9735) pula o
   `pipeline_log_line … PHASE` (linha 9749), que só o ramo derivado escreve. A primeira linha própria da corrida
   forçada é a linha da sessão, escrita quando a sessão acaba (linha 5698), ou a `LEFTOVER` (linha 5568) quando há
   sobra. Uma corrida `sdd run --phase EXEC` morta no meio da sessão deixa então a última linha de uma corrida
   anterior, e o texto só nomeia a corrida "killed before it derived its first phase". O remédio do parágrafo
   ("compare the line's time with the launch") cobre o caso, então é forma, não comportamento.
   **Conserto:** acrescentar "or a run started with `--phase`, which derives nothing and writes its first line
   only when its first session ends".
2. **Evidência:** as linhas 51 (`agents/sdd-reviewer.md`, "frases em `b51657d` e `772540c`"), 52
   (`agents/sdd-docs.md`, "frase em `781fe39`") e 60 (`docs/failure-modes.md`, "`596627b`") citam só commits de
   antes do `729fbf6`, que mudou os três documentos. A linha 64 diz "16 asserções", e com as três do `729fbf6` são
   19 (o `check-hat.sh` imprime 122 `ok` contra os 119 do KAIZEN_LOG, que é medida datada da DOCS e está certa).
   **Conserto:** somar `729fbf6` às três linhas e trocar "16" por "19" na linha 64, ou uma nota datada abaixo da
   tabela.
3. **Evidência (do verificador):** o `50-pr.md:10` diz "PR #446 aberto contra `main`", e o `pipeline.log` tem a
   sessão de PR às 22:07; a linha F6 foi escrita às 21:35. **Conserto:** "PR #446 aberto, aguarda a revisão e o
   merge" na coluna de próximo passo da F6 e no "O que fica para medir" do KAIZEN_LOG.
4. **Evidência (do verificador):** o `pipeline.log` tem 10 EXEC, 1 QA e 2 REVIEW, que somam US$ 17,82 e acabam às
   21:17; a DOCS (US$ 1,95, 21:36) e o PR (US$ 0,45, 22:07) ficam fora. O `KAIZEN_LOG.md:28` delimita a janela
   certo ("16:00 → 21:17"). **Conserto:** "até a REVIEW r2 (13 sessões de EXEC, QA e REVIEW, US$ 17,82)".
5. **Evidência (do verificador):** a rule `anatomia-do-agente.md` §5 diz "lição → sensor ou verbete do
   `CONTEXT.md`, nunca parágrafo novo no `CLAUDE.md`". A frase do chapéu está certa sobre o `writes:` e o
   `gate_DOCS` (`bin/sdd:2388`), e o chapéu serve a todo alvo, então é limite de escopo, não contradição.
   **Conserto (opcional):** "where the repo's own `CLAUDE.md` names another route for lessons, follow it".

Rodada de verificação: um verificador leu os 11 arquivos de prosa do delta (25 das 28 unidades; as 3 que não
leu estão nos espelhos `.claude/agents/`, iguais byte a byte às fontes que ele leu, `cmp` rc 0). O
`tests/check-hat.sh` foi revisado inline: as três asserções leem as variáveis da seção certa (`sdie`, `s3`, `sec`,
definidas nas linhas 701, 736 e 943). Varredura de código morto: o delta não acrescenta nem órfã símbolo nenhum.
A grafia antiga `[b]in/sdd run` seguida direto da missão só sobrevive no `01-plano.md` da própria missão,
que é histórico.

## Incrementos de conserto (R<n>)

Nenhum incremento nesta rodada. Os cinco achados são LOW de prosa e vão num lote só, pela sessão
orquestradora (Régua A, regra 1).

## O que virou incremento

Nada nesta rodada. A r2 não deixou achado aberto.

## Os seis achados do CodeRabbit no head bb7023d

1. **Major, sdd-docs §3, a lição para o `CLAUDE.md` pela rota ⛔: fechado.** Conferido: o `gate_DOCS` recusa ⛔
   sobre documento do `writes:` do chapéu (`bin/sdd:2383-2388`, "a ⛔ is for a path the hat may not write"), e o
   `CLAUDE.md` está nesse `writes:` (`agents/sdd-docs.md:10`). O texto em `agents/sdd-docs.md:61-64` agora manda
   escrever no `CLAUDE.md` e marcar ✅ com o hash, e deixa o ⛔ para `.claude/rules/` e `bin/sdd`, fora do
   `writes:`. Isso concorda com o § 5 do mesmo chapéu (linha 114). Asserção `hat: the docs phase writes a
   recurrent lesson for CLAUDE.md itself…` em `ok`.
2. **Minor, sdd-reviewer, espera portátil entre harnesses: fechado.** `agents/sdd-reviewer.md:160-162`: "Run the
   wait in a foreground call whose own time limit is at least 10 min. In Claude Code that is a Bash call whose
   `timeout` parameter is raised to its ceiling". O espelho foi sincronizado (`cmp` rc 0). Asserção `hat: the
   reviewer's wait reads in any harness…` em `ok`.
3. **Minor, sdd-reviewer, vivacidade de quem escreve `rc=`: fechado.** `agents/sdd-reviewer.md:156` guarda o PID
   (`echo "pid=$!"`), e as linhas 164-167 esperam de novo só com `kill -0` vivo. Com o processo morto e sem
   `rc=`, a espera para e a rodada é dada como falha. `kill` não está no `permissionsDeny` do revisor.
4. **Minor, failure-modes, opções antes da missão: fechado.** `docs/failure-modes.md:810` usa `pgrep -af
   '[b]in/sdd run .*` seguido da missão, e o `cmd_run` aceita opções em qualquer ordem (`bin/sdd:9642-9651`). A
   forma entre colchetes segue sem casar com a própria linha de comando. Asserção `doc: failure-modes.md finds
   a detached sdd run with options before the mission…` em `ok`.
5. **Minor, failure-modes, a última linha do journal pode ser de outra corrida: fechado.**
   `docs/failure-modes.md:814-817` diz que a linha só vale "if that line is this run's" e manda comparar a
   hora com o lançamento. A exceção da troca de branch confere com a linha `BRANCH` (`bin/sdd:6543`), escrita
   antes da derivação. O caso da corrida forçada fica como o achado LOW 1.
6. **Minor, 45-docs, repetir a espera: fechado.** O texto proposto em `45-docs.md:83-88` guarda o PID e repete a
   espera enquanto o comando vive. Com o comando morto e sem `rc=`, ele dá a corrida como falha em vez de esperar
   de novo.

## O que foi refutado

Nada.

## Achados fora de escopo

Nenhum.

## Pendências / Decisions for a Human

Nenhuma.
