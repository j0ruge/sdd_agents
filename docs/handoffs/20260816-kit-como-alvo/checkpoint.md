---
missao: 20260816-kit-como-alvo
atualizado: 2026-08-16 18:05
---

# Checkpoint — quando o kit é o próprio alvo, quatro instrumentos param de afirmar o que nunca mediram

> **Este arquivo é lido por máquina.** O runner faz parse da tabela abaixo para decidir a
> próxima fase. Não mude as colunas, não mude os tokens de status, não quebre linhas dentro de
> uma célula. Detalhe narrativo vai no `01-plano.md`, não aqui.
>
> Atualizar o checkpoint é o **último ato** de cada incremento — depois do commit, nunca antes.
> Status válidos: `pending` · `doing` · `done` · `blocked`.

| ID | Incremento | Check (comando → esperado) | Status | Commit |
|---|---|---|---|---|
| I1 | entry point com guarda + sensor diferencial | `bash tests/check-entrypoint.sh >/dev/null 2>&1; echo $?` → `0` | done | bb373b5 |
| I2 | os três leitores do ledger filtram por repo | `o=$(bash tests/check-kaizen.sh 2>&1); grep -c 'a row from another repo never enters the series' <<< "$o"` → `1` | done | d99a7fc |
| I3 | preflight compara conteúdo do agente, não presença | `o=$(bash tests/check-preflight.sh 2>&1); grep -c 'a drifted agent copy fails the preflight' <<< "$o"` → `1` | pending | — |
| I4 | aviso de branch base alcança run e kaizen | `o=$(bash tests/check-gates.sh 2>&1); grep -c 'the base branch warning reaches sdd run' <<< "$o"` → `1` | pending | — |

## Notas de execução

> Uma linha por evento relevante: bloqueio, decisão tomada, desvio do plano com justificativa.
> É o que a próxima sessão lê para não repetir um erro que já custou caro.

- 2026-08-16 00:00 · `plano` · Os 4 Checks foram rodados contra o HEAD `df18c88` na sessão que
  escreveu este plano e deram **`127`, `0`, `0`, `0`** — todos vermelhos pelo motivo certo
  (sensor ausente / asserção ausente), nenhum verde por construção. Se algum já estiver verde
  quando você começar, **pare e descubra por quê** antes de implementar.
- 2026-08-16 15:08 · `humano` · **Os Checks de I2/I3/I4 não usam pipe, e isso é obrigatório — não
  "simplifique" de volta.** Dois motivos independentes, os dois medidos hoje. (1) `checkpoint_rows`
  (`bin/sdd:174`) faz `awk -F'|'` cru e não conhece `\|`, o escape de pipe do GFM: com pipe na
  célula as três linhas davam `NF=8` contra `NF=7` da limpa, o `gate_EXEC` reprovava com "invalid
  status" e o `sdd status` imprimia `pending` na coluna Commit. Está no `TODO.md` (`2897a94`).
  (2) A primeira reescrita tentada — process substitution `grep -c '…' <(cmd)` — foi descartada,
  mas o motivo **não vale para você**: no shell interativo daquela sessão o `grep` era uma função
  do snapshot apontando para ugrep 7.5.0, que não imprime o `0` com `<(...)`. Dentro de `bash -c`,
  como o sensor roda, o `grep` é GNU 3.11 e imprime. Herestring ficou porque não depende de qual
  `grep` atende e é a forma que o `CLAUDE.md` já prescreve (SIGPIPE sob `pipefail`). ⚠️ O runner
  usa `grep` 40× e a suíte em 11 arquivos: se algum dia um Check parecer mentir, confira **em que
  shell** você o rodou antes de acusar o sensor.
  Re-medido em herestring contra o HEAD: `127`, `0`, `0`, `0` — os mesmos
  quatro números que o plano declara, então a evidência do critério (d) segue válida.
- 2026-08-16 00:00 · `plano` · O `bin/sdd` tem **2365** linhas neste HEAD. Âncoras do `TODO.md`
  citam offsets da época em que tinha 2324. `grep` pelo texto antes de editar por número.
- 2026-08-16 00:00 · `plano` · `run_mutant` devolve **rc 90** quando a sabotagem não altera o
  arquivo (`tests/check-mutation.sh:492`). Esse rc é "âncora apodreceu", não "mutação fraca".
- 2026-08-16 00:00 · `plano` · I1 tem Jidoka declarado: se a repro de reexecução não for
  determinística com ≥128 KB, **não commite repro flaky** — degrade para a asserção de forma,
  registre a degradação aqui e no handoff, e mantenha a mutação.
- 2026-08-16 · `I1` · **O Jidoka do I1 não precisou ser acionado, e o motivo interessa para I2-I4.**
  A repro do fall-through é determinística em *todos* os tamanhos medidos — 538 B, 4,5 KB, 20 KB,
  129 KB, 196 KB — sempre 2 entradas na versão sem guarda contra 1 na guardada (bash 5.2.21). O
  "≥128 KB" do plano era uma suposição sobre o buffer de leitura, e ela estava errada por excesso,
  não por falta: **nenhuma degradação foi declarada**. O enchimento ficou em ~128 KB mesmo assim,
  porque o tamanho em que um bash qualquer para de segurar o script inteiro é detalhe de
  implementação; o header do sensor registra os cinco números.
- 2026-08-16 · `I1` · **A âncora do `mut_RUN_entrypoint_unguarded` usa `|` como delimitador do
  `sed`, não o `@` que todos os outros 40 mutantes usam** — o texto ancorado contém `"$@"`, então
  um delimitador `@` fecha a expressão no meio do entry point e o `sed` morre com "unterminated
  `s' command". O sintoma seria **rc 90** ("a âncora apodreceu"), que é a leitura errada.
- 2026-08-16 · `I1` · Dois pisos anti-vacuidade que contam arquivos subiram junto com o sensor
  novo: `LINT_FLOOR` 12 → 13 (`tests/run-all.sh`) e o piso de superfície do `check-pipefail.sh`
  11 → 12, este último com a árvore-fixture do probe "a full clean surface passes" indo de 10 para
  11 arquivos. Nenhum dos dois reprovaria se ficasse parado — os dois passariam **descrevendo uma
  superfície menor do que a que leem**, que é a forma exata que esta missão está caçando. Se I2-I4
  acrescentarem arquivo em `tests/`, mexa nos dois de novo.
- 2026-08-16 · `I1` · **As âncoras de I2/I3/I4 no `01-plano.md` continuam válidas.** O I1 mexeu
  numa linha só do `bin/sdd`, a última, e acrescentou 7 linhas de comentário ali mesmo (2365 →
  2372). Tudo que I2-I4 citam — `:1283`, `:1294`, `:1817`, `:1937`, `:2039` — está *antes* desse
  ponto e não se deslocou. Ainda assim: `grep` pelo texto antes de editar por número.
- 2026-08-16 · `I1` · A passada de sabotagem adversarial do sensor novo matou 8 das 10 regras do
  parser. Das duas sobreviventes, "neutralizar o corpo do `probe()`" era buraco de **uma** edição
  (fazia as dez asserções passarem de uma vez) e foi fechado por uma testemunha que o próprio
  `--check` escreve. ⚠️ A primeira tentativa de fechá-lo — rodar `--check` direto num arquivo ruim
  — era **redundante** com os probes 1-10 e, por ser redundante, nenhuma sabotagem a deixava
  vermelha: foi removida em vez de ganhar probe, pela regra do `CLAUDE.md`. Os dois sobreviventes
  finais estão nomeados no header do sensor.

- 2026-08-16 · `I2` · **O risco "linhas antigas sem o campo `repo`" foi medido, não estimado:**
  `jq -c 'select(has("repo")|not)' ~/.sdd/autonomy-log.jsonl | wc -l` → `0` em 26 linhas, todas do
  kit. Mesmo assim a decisão foi tomada **por regra e não pelo dado**: linha que não sabe dizer de
  onde veio — não é objeto, ou é objeto sem `repo` — **nunca** é excluída pelo filtro. Ela segue
  chegando ao balde que a nomeia (`unrecognized`, ou a morte alta nomeando o arquivo) no repo em
  que você estiver. Esconder corrupção é a única coisa que um filtro não pode fazer, e isso é o
  que preserva os fixtures `stray` e `shape` do `check-autonomy.sh` intactos.
- 2026-08-16 · `I2` · **Contrato mudado, de propósito: `sdd kaizen --series` não é mais "any cwd".**
  O cabeçalho do `check-kaizen.sh` afirmava que a série tinha de funcionar de QUALQUER diretório;
  com a leitura por repo, ler de fora de um repositório git devolve a série vazia (com `warn`) —
  a direção segura, porque série vazia é `sufficient:false` e só sustenta `indeterminado`. O
  `sdd help` e o `docs/pipeline.md` aprenderam no mesmo commit; há asserção para o caso.
- 2026-08-16 · `I2` · **Todo fixture de ledger agora precisa nomear um repo REAL.** Os dois
  sensores ganharam um `localize()` que reescreve `"repo":"/p1"` para o caminho absoluto do repo
  sandbox, e as leituras da série saíram de `$OUTSIDE/anywhere` para dentro dele. ⚠️ Linha de
  fixture nova escrita com `cat >` em vez de `localize >` fica **invisível** para o leitor e o
  sensor passa medindo um ledger vazio. O caminho vem de `git rev-parse --show-toplevel`, nunca da
  string que o teste montou: TMPDIR pode ser symlink e o runner resolve exatamente assim.
- 2026-08-16 · `I2` · `excluded` tem **quatro** chaves agora (`other_repo` entrou) e o literal do
  ramo de ledger vazio (`bin/sdd:2006`) as carrega todas. A comparação de conjunto de chaves que
  só existia para `guard` passou a existir para `excluded` também — era metade do contrato entre os
  dois produtores da mesma shape, e estava sem sensor.
- 2026-08-16 · `I2` · **A sabotagem adversarial provou que as duas asserções não são redundantes:**
  desligar o filtro só em `kaizen_series` mata `check-kaizen.sh` e deixa `check-autonomy.sh` verde;
  desligar só em `cmd_autonomy` faz o inverso. É por isso que o mutante do catálogo sabota a
  **definição** e não uma chamada — só assim ele mede que os três leitores passam mesmo por ela.
- 2026-08-16 · `I2` · ⚠️ **O Check desta linha (e os de I3/I4) devolve `1` mesmo com a asserção
  VERMELHA:** `fail()` imprime o mesmo texto que `pass()`, e o Check captura `2>&1`. Quem prova
  "rodou E passou" é o `TEST_CMD` verde, não o Check. Não mudei o comando (o runner faz parse desta
  tabela e a métrica do `00-missao.md` o cita); está no `TODO.md` com a direção — grepar
  `'^  ok    <texto>'`.
- 2026-08-16 · `I2` · **Âncoras de I3/I4 re-derivadas depois deste incremento** (`bin/sdd` foi de
  2372 para 2449 linhas): o `[ -f ... ]` do preflight está em **`:1314`** (era `:1283`), o
  `ok "$n kit agent(s) checked"` em **`:1319`** e o aviso de branch base em **`:1325`** (era
  `:1294`). `grep` pelo texto antes de editar por número, sempre.
- 2026-08-16 · `I2` · Nenhum arquivo novo em `tests/` — os dois pisos que contam arquivos
  (`LINT_FLOOR` no `run-all.sh`, piso de superfície do `check-pipefail.sh`) ficam como estão.
  Catálogo de mutação: 41 → **42**, 0 known gap. `sdd health` verde.

## Incrementos de fix (QA)

> Escritos pelo `sdd-qa` quando um bug sanável é reprovado. Entram na mesma tabela acima com ID
> `F<n>`, e o Check obrigatoriamente inclui **regression test passa** + **re-walk da jornada
> impactada verde**. Bug que exige julgamento humano NÃO vira fix — vai para
> "Decisions for a Human" no handoff de QA.
