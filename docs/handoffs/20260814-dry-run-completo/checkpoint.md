---
missao: 20260814-dry-run-completo
atualizado: 2026-08-14 04:20
---

# Checkpoint — dry-run mostra o pipeline inteiro

> **Este arquivo é lido por máquina.** O runner faz parse da tabela abaixo. Não mude as colunas,
> não mude os tokens de status, não quebre linhas dentro de uma célula.
>
> Atualizar o checkpoint é o **último ato** do incremento — depois do commit, nunca antes.
> Status válidos: `pending` · `doing` · `done` · `blocked`.

| ID | Incremento | Check (comando → esperado) | Status | Commit |
|---|---|---|---|---|
| I1 | dry-run projeta todas as fases pendentes | `tests/run-all.sh` → exit 0 (com check-dry-run.sh incluído) | done | 357b401 |

## Notas de execução

- 2026-08-14 03:05 · — · missão-fixture do incremento I6 do plano do kit: plano escrito à mão
  para exercitar a fase EXEC headless pela primeira vez.
- 2026-08-14 03:40 · — · **I1 → `blocked`. Jidoka: a sessão EXEC headless não consegue executar
  o sensor.** Nenhuma linha de I1 foi escrita — nem o `tests/check-dry-run.sh` (Red), nem a
  mudança em `bin/sdd` (Green). Motivo: nesta sessão **toda** execução de comando não-leitura
  é negada com "This command requires approval". Negados: `tests/run-all.sh`,
  `bash tests/run-all.sh`, `./tests/run-all.sh`, `tests/check-gates.sh`, `bash -n bin/sdd`,
  `bash -c 'echo hello'`, `sh -c 'echo probe-sh'`, `rtk proxy "tests/run-all.sh"` (este último
  também com o sandbox desabilitado). Permitidos: só leitura — `git`, `ls`, `cat` e o tool
  `Read`. Causa raiz em `bin/sdd:491-499`: `run_phase()` monta
  `claude -p … --permission-mode "$PERMISSION_MODE"` (= `acceptEdits`) **sem `--allowedTools`**,
  e não há allowlist cobrindo os comandos do kit em `--setting-sources user,project,local`.
  `acceptEdits` auto-aprova edição de arquivo, **não** `Bash`. **`git add` também é negado** —
  só o `git` de leitura (`status`, `log`, `rev-parse`) passa —, então a sessão não consegue nem
  commitar: `gate_EXEC` exige hash real no `git log` e é, hoje, insatisfazível por construção.
  Este commit de escalação também não pôde ser feito; as edições ficam **no working tree**, sem
  commit, para o humano inspecionar (`git status`). Consequência: o `sdd-executor`
  não consegue cumprir o próprio contrato — não roda `TEST_CMD` na abertura, não vê o Red, não
  verifica o Green. Seguir teria significado commitar bash não executado e marcar `done` — que
  é exatamente o "rótulo, não artefato" que o kit proíbe. Registrado no `TODO.md` (achado sobre
  o kit) com a direção de correção e o sensor durável proposto (`sdd preflight` afirmando que
  uma sessão headless consegue de fato rodar `TEST_CMD`). **Escalação para o humano: I1 continua
  intacto e volta a `pending` assim que a permissão for corrigida.**
- 2026-08-14 04:20 · `357b401` · **I1 → `done`.** O impedimento acima foi resolvido por
  `2083680` (`ALLOWED_TOOLS` + `--allowedTools` em `run_phase`): esta sessão headless rodou
  `TEST_CMD`, viu o Red, viu o Green e commitou — nada disso era possível na sessão anterior.
  TDD cumprido: `tests/check-dry-run.sh` foi escrito primeiro e falhou pelo motivo certo
  (projetou só `EXEC=sdd-executor`, faltando QA/REVIEW/DOCS/PR); só então `bin/sdd` mudou.
- 2026-08-14 04:20 · `357b401` · Decisão de implementação (dentro do plano; registrada por ser
  exatamente a armadilha que o plano previu): a projeção usa um cursor próprio `dry_next` mais a
  função nova `next_pending_phase()`, e **nunca** re-chama `current_phase()`. O segundo cursor
  foi necessário porque reaproveitar `force_phase` colidiria com `--phase <FASE>`, que deve
  continuar imprimindo uma fase só — há asserção explícita disso no sensor.
- 2026-08-14 · — · **QA abriu `F1`.** Origem: `BUG-dryrun-pipelinelog` (registrado no
  `30-handoff-qa.md`, não há árvore `docs/qa/` neste repo — projeto sem interface, `qa_substep`
  vai direto ao `sdd-qa`). Andando a jornada `sdd run <m> --dry-run` contra uma missão com
  incremento `blocked`, a projeção **escreve** `docs/handoffs/<m>/pipeline.log` com um evento
  `BLOCKED` que nunca aconteceu. Causa: em `cmd_run` o Jidoka de `blocked` chama
  `pipeline_log_line` e retorna 3 **antes** do bloco `DRY_RUN` — o único `pipeline_log_line`
  alcançável em dry-run (o de `run_phase` está atrás da guarda). Não conserte aqui: o sensor
  `tests/check-dry-run.sh` já está commitado **vermelho** (3 asserções), que é o Red do F1.
- 2026-08-14 · `f1c9f3f` · **F1 → `done`.** TDD com **Red herdado**: não escrevi teste novo — rodei
  `tests/run-all.sh` na abertura e vi as 3 asserções da QA falharem pelo motivo certo (101 verdes,
  exit 1); só então toquei `bin/sdd`. Depois: exit 0, 104 asserções, zero falhas. Re-walk do Check
  na missão real (I1 flipado para `blocked` e revertido): exit 3, `pipeline.log` com md5 idêntico,
  `git status` sem novidade.
- 2026-08-14 · `f1c9f3f` · Decisão de implementação: a guarda ficou **dentro** de
  `pipeline_log_line` (`bin/sdd:557`), não no chamador do Jidoka (`bin/sdd:947`) que o handoff de
  QA chamou de "caminho óbvio". Motivo: os caminhos de escalação que logam são três — checkpoint
  `blocked`, orçamento estourado, duas sessões sem progresso — e um quarto adicionado amanhã
  nasceria com o mesmo defeito. Guarda única torna "a projeção não escreve no diário" verdadeiro
  por construção. É a alternativa que o próprio `30-handoff-qa.md` apontou como melhor ("se você
  refatorar para uma guarda única, melhor ainda"), e satisfaz as 4 asserções do sensor.
- 2026-08-14 · `f1c9f3f` · Verificação extra, porque a guarda usa `[ … ] && return 0` sob
  `set -euo pipefail`: provei num probe descartável que com `DRY_RUN=0` a função **ainda escreve**
  e a execução segue após a chamada (o `set -e` não morde ali — o comando não é o último do
  `&&`-list). Sem isso, o conserto podia ter matado o diário real e a suíte seguiria verde, porque
  nenhum sensor exercita o caminho não-dry. Essa lacuna virou entrada no `TODO.md`.

- 2026-08-14 · — · **QA volta 2 — nenhum `F<n>` novo.** Re-andei as jornadas: J3 (o achado do
  `BUG-dryrun-pipelinelog`) está **curado** — `pipeline.log` com md5 idêntico antes e depois,
  árvore idêntica, exit 3 preservado. J1 (exit 0, projeta QA:close→REVIEW→DOCS→PR), J2 (PLAN,
  exit 2, nada projetado) e `--phase` (uma fase só) verdes. A jornada "pipeline completo", que a
  volta 1 deixou **inconclusiva** por erro de fixture (hash inventado), foi andada até o fim com
  `gh` stubado: exit 0 e `pipeline completo — falta só o merge`. Um achado de **sensor**, não de
  produção: `53cf63a` moveu o `pipeline.log` para `.sdd/logs/` e deixou a asserção
  `projeção blocked não cria pipeline.log` apontando para o caminho velho — provado por mutação
  que ela passava com o bug do F1 de volta. Corrigi o sensor (é teste, não produção) e cobri o
  caminho **real** do diário, que nenhum sensor exercitava. Suíte: 118 asserções, 0 falhas.

## Incrementos de fix (QA)

> Escritos pelo `sdd-qa` quando um bug sanável é reprovado, com ID `F<n>` e Check incluindo
> regression test + re-walk da jornada impactada.

| ID | Incremento | Check (comando → esperado) | Status | Commit |
|---|---|---|---|---|
| F1 | dry-run não escreve no `pipeline.log` no caminho `blocked` | `tests/run-all.sh` → exit 0 (as 3 asserções novas de `check-dry-run.sh` verdes) E re-walk: numa missão com incremento `blocked`, `sdd run <m> --dry-run` sai 3 e deixa `git status --porcelain` vazio | done | f1c9f3f |
