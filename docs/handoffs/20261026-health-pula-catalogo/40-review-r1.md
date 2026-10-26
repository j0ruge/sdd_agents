---
missao: 20261026-health-pula-catalogo
fase: REVIEW
rodada: 1
status: done
sessao: 4b9c28f8-7152-4e88-aae7-0bf05f85f18c
data: 2026-10-26 10:05
gate: Overall B, com Documentation e Overall em B (REVIEW_PROSE_CRITERIA, piso B) e os outros seis critérios em A. Primeira rodada, então não há tabela anterior com que comparar, nem platô, nem regressão. A rodada não fecha porque o R1 está pending. TEST_CMD `tests/run-all.sh` no HEAD `9a7ee1b` (o merge da `origin/main` `cc993f7`, PR #329), rodado pelo relay → rc 0, 543 s, 2057 `ok`, 0 `FAIL`, `62 finding(s)` e `anchors: all 792 mutants still apply` (`/home/pc_admin/.wt/plan-health-pula-catalogo/sdd/suite-9a7ee1b.log`; `suite-9a7ee1b.rc` → `rc=0 secs=543`). Pré-scan de segredos `scan_secrets.sh` (regex) sobre 17 arquivos e 2806 linhas acrescentadas → 0 achados e 0 erros (`secrets-prescan.json`). `/codereview` 2.27.11 sobre `cc993f7...9a7ee1b` (34 commits): 11 agentes sonnet, 10 por arquivo mais a varredura B2. Os quatro Checks do R1 medidos no `9a7ee1b`, cada um como a célula o escreve, deram `0`, `0`, `0` e `0`. O controle no mesmo run, `check-gates.sh`, deu rc 0, 481 ok, 0 FAIL e o Check do I1 em `1`. `check-checkpoint.sh --check` → rc 0. Depois do commit desta rodada, `git diff --name-only 9a7ee1b HEAD` lista só a pasta da missão e `git status --porcelain` sai vazio
---

# Review — rodada r1 — o `sdd health` pula o catálogo com a chave já medida

> Escrito ao fim de cada rodada de revisão, em `docs/handoffs/<missão>/40-review-r<N>.md`.
> O runner lê **a mais recente**. Uma rodada que não fechou também escreve o arquivo, com a nota
> real: nota inflada para passar no gate desliga o único sensor de qualidade da missão.

## TL;DR

O `/codereview` 2.27.11 revisou `cc993f7...9a7ee1b` (17 arquivos, 34 commits) com 11 agentes, e o scan de segredos passou. Nota: **B**.
Os seis critérios com sensor fecham em A, e Documentation e Overall ficam em B, só pela prosa. Dos 10 achados, 2 são MEDIUM
de prosa e 8 são LOW, sem CRITICAL nem HIGH; 9 achados levantados pelos agentes foram refutados. Os LOW baratos #3–#6 viraram o `R1` de lote, com quatro Checks, todos
vermelhos no HEAD. #1, #7 e #8 vão para a DOCS, o #2 vira o estado de agora no boot abaixo, o #10 vai para o chore pós-merge e o #9 fica
registrado. Esta rodada não consertou nada. Próximos passos: o EXEC do `R1`, depois a r2.

## Nota da rodada

A tabela abaixo é a do `codereview-r1.md` (`/home/pc_admin/.wt/plan-health-pula-catalogo/sdd/`), **verbatim** nas
notas e nos motivos. A única mudança é o nível do heading: o relatório da skill escreveu `## Overall Grade`, e o
contrato (`agents/sdd-reviewer.md` §4) e o `gate_REVIEW` pedem `### Overall Grade`. Segui o contrato. É a primeira rodada, então não há
tabela anterior com que medir movimento.

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | A | 0 CRITICAL/HIGH/MEDIUM no código; 1 LOW de comentário (#5) |
| Type Safety | A | n/a (bash) — nenhuma conversão ou expansão insegura achada |
| Error Handling | A | 6.11 limpo no `bin/sdd`; capturas guardadas; o LOW #3 é do fixture, não do runner |
| Security | A | Secrets PASS; nenhum achado |
| Performance | A | o produto é o pulo (10 h 58 → suíte rápida ~9 min); nada a apontar |
| Test Coverage | A | 792 mutantes, as regras novas com mutante cada; dois LOW de cobertura (#4, #10) |
| Documentation | B | 2 MEDIUM de prosa: a doc do repo é a lista da DOCS (#1) e a prosa da missão andou com o merge (#2) |
| **Overall** | **B** | o código e os sensores fecham em A; a nota cai só pela prosa, que a DOCS e o boot desta rodada levam |

## Achados da rodada

> Numeração do `codereview-r1.md`. As âncoras são as do relatório, exceto onde eu as medi de novo no `9a7ee1b`
> (marcado "medido").

| # | Severidade | Achado | Onde | Destino |
|---|---|---|---|---|
| 1 | MEDIUM | A doc do repo ainda ensina o lugar velho (`.sdd/logs/mutation-stamp`, `.sdd/cache/`) e a volta manual do mapa e do carimbo que o `commands/sdd-plan.md` tirou; o `failure-modes.md:1104–1150` contradiz o comando novo | `README.md:173`, `CONTEXT.md:32`, `docs/failure-modes.md:1085–1086` e `:1104–1150`, `docs/pipeline.md:528`, `docs/adr/0016-…:121–123`, `docs/adr/0007-…:28`, as três jornadas | fase DOCS |
| 2 | MEDIUM | A prosa da missão ficou defasada pelo merge `9a7ee1b` (#329): catraca, linhas do `TODO.md`, o checkout principal, a suíte do merge e a célula F1. Nada factual sobre o código está errado | `20-handoff-exec.md:61, 63, 142, 157, 181, 189, 214, 237, 251, 396–398, 487`; `30-handoff-qa.md:29, ~265`; `checkpoint.md:56` | o estado de agora, no boot abaixo (prosa, nunca `R<n>`) |
| 3 | LOW | `fixture_stamped` responde "não carimbado" também quando `fixture_stamps` não resolve o common dir (git < 2.31, ou fixture fora de git): as metades `absent` dos mundos 8, 9, 12, 13 e 8b e o `tree_stamped "$TREE_PLAIN"` passam no vazio | `tests/check-gates.sh:3257–3266` (medido: `fixture_stamps` em `:3257`, `fixture_stamped` em `:3266`) | **R1** |
| 4 | LOW | O mundo 7 velho provava que a remoção "é um veredito revisável, não uma trava" (verde → sobrevivente → verde). O novo para no sobrevivente, e uma trava que impedisse regravar depois de uma remoção passaria | `tests/check-gates.sh:3466–3490` (o mundo 7 é `:3483–3488`, medido) | **R1** |
| 5 | LOW | O cabeçalho do bloco diz "Six more worlds follow the tally" e não lista o mundo 14 (A LINKED WORKTREE, `:3662`); a contagem e a lista discordam do corpo | `tests/check-gates.sh:3178–3182` | **R1** |
| 6 | LOW | O censo "11 sites by `grep -n 'sdd" health' tests/*.sh`" não vê a forma `./bin/sdd health`, nem a da asserção 21 nem a do mundo 14. O 11 só bate porque o grep é cego a ela | `tests/check-health.sh:85–86`; os sítios cegos são `tests/check-health.sh:1194` e `tests/check-gates.sh:3684` (medido; o relatório dizia `:3679`) | **R1** |
| 7 | LOW | A 0004 diz que o carimbo sai "when the catalogue comes back red **or when the tree moved while it ran**". A 0021 §4 inverte a 2ª metade, mas o `Amends` da 0021 e o ponteiro na 0004 só falam da 1ª | `docs/adr/0021-…:54–59` × `docs/adr/0004-…:98–100` | fase DOCS |
| 8 | LOW | "four days older" e "written in 16 handoffs" aparecem sem a medida salva na evidência do planner (a recontagem do agente achou 9 diretórios que citam `with-mutation`) | `docs/adr/0021-…:26–27`, `:72–73` | fase DOCS: medir e citar, ou tirar o número |
| 9 | LOW | As Pendências e o Gate PLAN-AUTO descrevem a árvore do tempo do plano. O `TODO.md:225` era a linha da `RECURRED`, não o título | `00-missao.md:112–113, 217–222` | só registro: o `00-missao.md` aprovado não é reescrito (regra do dono), e o `20-handoff-exec.md` já diz que a pendência é de antes do `approve` |
| 10 | LOW | Nenhum sensor durável prova que os três leitores chamam `load_killer_maps`. Está declarado no cabeçalho do selftest e custa tempo, nunca veredito (Minor adiado do I3) | `tests/check-mutation.sh:432–434, 7918` | chore pós-merge |

### O que a QA pediu à REVIEW

O `30-handoff-qa.md` § Boot deixou duas perguntas. A rodada não as transformou em achado, e eu não as medi:

- **Um mutante, um sensor** (o `mut_HEALTH_skip_needs_score` só morre no `check-health.sh`). O catálogo pede que o
  mutante morra, e ele morre. Um segundo matador seria redundância, não cobertura que falta. Nenhum agente o levantou.
- **A fidelidade dos stubs além do `score:`** (a contagem do `TODO.md`, as linhas `FAIL`, a cauda). Ninguém mediu, e
  esta rodada também não. Fica como risco aberto, com o mesmo texto da QA, para a r2 decidir se vale um agente.

### Onde o relatório do `/codereview` diverge do contrato, e o que fiz

- **O heading da nota:** o relatório escreveu `## Overall Grade`, e o contrato pede `###`. Aqui vai `###`.
- **A prosa do repo (#1, #7, #8) vai para a fase DOCS, não para o `TODO_FILE`:** o §3 manda achado só de prosa para o
  `TODO_FILE`. Só que esta prosa é a lista da fase DOCS desta mesma missão (`00-missao.md` § Fora de escopo: "é da fase
  DOCS"). Registrá-la como dívida no backlog duplicaria o que a fase seguinte já tem por escopo, e a M4 trava a
  catraca. Nenhum dos três é `R<n>`, que é o que o §3 proíbe.
- **O #10 vai para o chore pós-merge, não para o `TODO_FILE` agora:** ele é caro no sentido do §3. O sensor de ~3 s
  cobre um leitor só (`--touched`), e o leitor do catálogo só roda no catálogo, que leva horas. Pelo §3 ele iria para o
  `TODO_FILE`. A M4 (a missão não põe item no `TODO.md`; a catraca era 61 na base e é 62 depois do #329) o adia para o
  chore pós-merge, que é o mesmo `TODO.md`, logo depois do merge.
- **O Check do #6 diz `13 sites`, não `12 sites`.** O texto que recebi do relay pedia `grep -c '12 sites'`, mas o
  próprio achado nomeia **dois** sítios cegos, e a conta medida no `9a7ee1b` dá 13: os 11 de `'sdd" health'`, sem a
  linha do censo, mais `tests/check-gates.sh:3684` e `tests/check-health.sh:1194`. As outras linhas com
  `./bin/sdd health` são texto de asserção e comentário: `check-gates.sh:3441–3442`, `:3568`, `check-hat.sh:583`, `:651`, `:657` e
  `check-mutation.sh:1619`, `:1630`. Com `12`, o executor teria de escrever um número errado ou deixar o Check vermelho
  para sempre. Os dois textos dão `0` no HEAD, então nenhum dos dois é cego.

## Incrementos de conserto (R<n>)

> **Esta rodada não conserta.** Cada achado que precisa de conserto vira uma linha `R<n>` na tabela
> de incrementos do `checkpoint.md`, e o `sdd-executor` a fecha em TDD, numa sessão de contexto
> próprio; a rodada seguinte re-avalia sem ter escrito o conserto.

| R<n> | Achado | Check escrito no checkpoint |
|---|---|---|
| R1 | lote dos achados #3–#6 da r1 | `o=$(bash tests/check-gates.sh 2>&1); grep -c '^  ok    stamp: the fixture resolves the git common dir before a world reads a stamp' <<< "$o"` → `1` (#3); `o=$(bash tests/check-gates.sh 2>&1); grep -c '^  ok    stamp: a green catalogue after a removal stamps the key again' <<< "$o"` → `1` (#4); `grep -c 'A LINKED WORKTREE (14)' tests/check-gates.sh` → `1` (#5); `grep -c '13 sites' tests/check-health.sh` → `1` (#6) |

## O que virou incremento

- **#3 → `R1`.** Uma guarda no topo do bloco do carimbo para o bloco como `SENSOR-BROKEN` quando o
  `fixture_stamps "$FIX"` não resolve o common dir, como o `wt_dirty` do mundo 14 (`check-gates.sh:3675–3677`). Diferente
  das cinco guardas `SENSOR-BROKEN` de hoje, que só têm a metade `fail`, esta imprime o `ok` quando resolve, e é esse
  `ok` que o Check lê. Para fechar: `^  ok    stamp: the fixture resolves the git common dir before a world reads a
  stamp` → `1`.
- **#4 → `R1`.** Um mundo logo depois do 7 (`:3483–3488`): sobre a chave que o 7 tirou, um `--full` com a suíte verde e o
  score limpo grava a chave de novo. O mundo 7 já chama `i4_verdict 0 "$I4_SCORE_SURVIVOR"; i4_health --full`, então o
  novo cabe no mesmo `i4_health` (`:3250`) e não abre um sítio novo de `sdd health`. Isso importa para o #6. A asserção
  é própria, fora do tally, como as dos mundos 8b e 14. Para fechar: `^  ok    stamp: a green catalogue after a removal
  stamps the key again` → `1`. O executor decide se o mundo leva mutante (a trava "não regrava depois de remover"),
  pelo critério de sempre do catálogo.
- **#5 → `R1`.** O cabeçalho (`:3178–3182`) conta e lista o mundo 14 no formato dos outros, `PARTIAL ROOT (9), …`, e a
  contagem "Six more worlds" acompanha a lista. O Check lê a lista (`grep -c 'A LINKED WORKTREE (14)'` → `1`). A palavra
  da contagem fica com o executor, junto da lista.
- **#6 → `R1`.** O censo (`check-health.sh:85–86`) nomeia as duas grafias de bash, `"$X/bin/sdd" health` e
  `./bin/sdd health`, e a contagem medida: **13 no `9a7ee1b`**. O Check pede `13 sites` (`→ 1`). O driver Python do
  `check-coordination.sh` (`busy(…, "health")` e `run(…)`, com `cwd=repo` em `:93` e `:218`, mais o `"$COORD_SDD" health`
  aninhado da `:790`) é uma terceira forma, também presa ao `cwd`, e fica fora da conta. O comentário pode nomeá-la sem
  contá-la. Se o R1 abrir um sítio novo de bash, a conta muda, e o executor corrige o número e o Check juntos, com a
  medida na nota. Este item sai da lista de achados do kit do `20-handoff-exec.md` ("o censo … não conta a forma
  `./bin/sdd health`"), porque agora é do R1.
- **Vermelho no HEAD `9a7ee1b`**, cada Check rodado como a célula o escreve, da raiz da worktree: #3 → `0` (140 s),
  #4 → `0` (140 s), #5 → `0`, #6 → `0`; o texto do relay, `12 sites`, também → `0`. Controle no mesmo run do #3:
  `check-gates.sh` rc 0, 481 ok, 0 FAIL, e o Check do I1 em `1`. Os zeros são a asserção que falta, não um sensor
  morto.

## O que foi refutado

- **`tests/check-mutation.sh:444–447`, "fixture git sem isolar `GIT_*`":** o arquivo faz
  `. "$(dirname "${BASH_SOURCE[0]}")/isolate-git.sh"` na `:32`, e o `tests/isolate-git.sh:40` dá `unset` nas variáveis
  que o `git rev-parse --local-env-vars` lista (`GIT_DIR` e afins). Conferi no `9a7ee1b`. O agente não seguiu o `source`.
- **`TODO.md:32` e `:516`, "hashes do `RESOLVED by` em formatos diferentes":** a escolha foi medida. O 1º vai nu porque o
  Check do I5 o lê assim, e o 2º vai em crase porque o `MORE_HASH_RE` da skill `todo-to-github-issues` só o lê assim
  (`20-handoff-exec.md` § o I5).
- **`bin/sdd:7613–7616`, "o conjunto de chaves cresce sem limite":** está declarado na ADR 0021, nas Consequences
  (`:90`, "The set is never pruned"), e no `00-missao.md` § Fora de escopo ("Podar o conjunto de chaves").
- **`bin/sdd:7613–7625`, "duas causas na mesma mensagem":** o próprio agente conclui "None needed", porque o ramo
  `elif [ -z "$stamp_key" ]` nomeia a chave vazia.
- **`tests/check-gates.sh:3696` (`worktree remove … || true`) e `:3835` (`find … 2>/dev/null`):** são fixture temporário
  sob o trap, e o `cp -r` garante o diretório. O defeito é hipotético e não tem efeito observável.
- **`tests/check-mutation.sh:436–496`, "selftest de ~60 linhas, caminho fixo":** é chamado uma vez. É polimento.
- **As âncoras do `commands/sdd-plan.md` a −1 no `TODO.md`:** estão dentro da tolerância de 10, e o sensor diz
  `anchors: 62 measured, 0 off target`.
- **`30-handoff-qa.md:12`, o `gate:` longo:** não tem erro factual. É polimento.
- **B2, as escritas do arquivo velho em `check-hat.sh:809–816` e `check-gates.sh:3693–3697`:** são controles negativos
  vivos ("the old file alone opens nothing"), não código morto.

## Achados fora de escopo

Nenhum item novo entrou no `TODO.md` nesta rodada: pela M4, a missão não acrescenta item à catraca. O que é do kit
vai para o **chore pós-merge** (lista no boot abaixo).

## Pendências / Decisions for a Human

Nada novo desta rodada. Seguem com o dono, sem mudança, as perguntas e os passos que o `20-handoff-exec.md` §
*Pendências* descreve:

- **A ressurreição pela semente** (I3, `3e728d6`): declarar e deixar, a lápide `slug TAB TAB`, ou "semente só sem
  compartilhado".
- **A cópia do kit sem `.git` dentro de outro repositório**, que resolve o `git-common-dir` do outro: guardar ou declarar.
- **O carimbo do operador, a M3 e o chore pós-merge**, depois dos bots (estado de agora no boot abaixo).

## Boot da próxima fase

**Próxima: o EXEC do `R1`**, a única linha `pending` do `checkpoint.md`. Depois vem a **REVIEW r2**, que re-avalia sem ter
escrito o conserto, e depois a **DOCS**. Valem as regras de sempre: todo comando como
`cd /home/pc_admin/repos/sdd_agents-health-pula-catalogo && …`. Nunca o `sdd` do PATH, que é o kit velho até o merge.
Nunca `./bin/sdd health`, `run` ou `status` na worktree, porque o `./bin/sdd health` da worktree é o carimbo do
operador, depois dos bots. Nunca `bash tests/check-mutation.sh` sem modo. **A r2 leva este boot adiante**, com o estado
que ela medir: a DOCS lê o handoff mais novo, e depois da r2 ele deixa de ser este.

### Para o EXEC do `R1`

- Os quatro achados, as âncoras e o que cada Check exige estão em *O que virou incremento*, acima. Um commit para o
  lote está bem: são LOW, e nenhum precisa ser revertido sozinho.
- O #3 e o #4 são vermelhos de `tests/check-gates.sh` (~140–150 s cada run). O #5 e o #6 são greps de arquivo.
- O #6 conta **13** no `9a7ee1b`. Se o R1 abrir um sítio novo de bash, o número muda. Nesse caso, o executor mede, corrige
  o número no comentário e no Check, e registra a medida na nota.
- O conserto toca `tests/`, então as âncoras do `TODO.md` que caem em `tests/check-gates.sh` e `tests/check-health.sh`
  podem andar. Rode `bash tests/check-todo.sh --anchors TODO.md` (→ `0 off target`) e reancore pela skill, como no I5.

### O estado depois do merge (achado #2) — o estado de agora

O `20-handoff-exec.md` e o `30-handoff-qa.md` não foram reescritos. Os números deles são os de antes do `9a7ee1b`, e o
que vale é isto, medido no `9a7ee1b`:

- **A catraca é 62** (`tests/health-baseline.txt:26` → `todo-findings 62`; a suíte do merge diz `62 finding(s)`). O
  merge do #329 trouxe um item da `main` (`TODO.md` +8 linhas, inseridas depois da `:116`). Onde os handoffs dizem "61",
  leia 62; onde dizem "o chore leva de 61 a 59", leia **de 62 a 60**. A M4 segue: a missão não acrescenta item.
- **As linhas do `TODO.md` depois da `:116` andaram +8:** `RECURRED 7` `:225` → `:233`; `KILLERS_FILE` `:503` → `:511`;
  o 2º item da missão (título) `:502` → `:510`, com o `RESOLVED by 4ae37c9` `:508` → `:516`; o achado do squash
  (`RESOLVED by` não sobrevive a squash) `:128` → `:136`; o `sdd approve` `:370` → `:378`; `:533`, `:537` e `:556` idem
  (+8). O 1º item da missão não andou (`:26`, `RESOLVED by 6dbd63c` em `:32`). A célula do I5 cita `TODO.md:26` e `:502`:
  o `:502` hoje é `:510`, e o Check dela conta pelo `awk`, não pela linha, então segue `2 0`.
- **O checkout principal** `/home/pc_admin/repos/sdd_agents` está em **`cc993f7`**, não em `c114e36`. O `bin/` é o mesmo
  (`git diff --quiet c114e36 cc993f7 -- bin` → sem diferença), então o `sdd` do PATH (`~/.local/bin/sdd` →
  `/home/pc_admin/repos/sdd_agents/bin/sdd`) continua sendo o kit velho, com o mesmo risco que o `20-handoff-exec.md` §
  *A pendência do operador* descreve. `status --porcelain` está vazio, e não existe `.git/sdd-mutation`.
- **A suíte do merge:** `tests/run-all.sh` no `9a7ee1b` → rc 0, 543 s, 2057 `ok`, 0 `FAIL`, `anchors: all 792 mutants
  still apply` (`/home/pc_admin/.wt/plan-health-pula-catalogo/sdd/suite-9a7ee1b.log`). Ela não está em nenhuma tabela dos
  handoffs anteriores, cuja última linha é a do `8328a7e`.
- **A célula F1** do `checkpoint.md` cita `bin/sdd:6482–6488`, que era a linha no `096c625`. Hoje o `kit_fallback` e o
  `warn` estão em **`bin/sdd:6487–6497`**. A célula é histórica e já está `done`, então não se reescreve.
- A chave do carimbo não mudou com o merge: o `TODO.md` e a `tests/health-baseline.txt` ficam fora dela (`30-handoff-qa.md`
  § Boot).

### Para a fase DOCS

A lista é a do `01-plano.md` § *Para a fase DOCS*, ampliada pelo `20-handoff-exec.md` § *Para a fase DOCS* e
detalhada nas jornadas pelo `30-handoff-qa.md` § *Para a fase DOCS*. Os três seguem valendo e trazem o porquê de cada
linha. Mais o que esta rodada acrescenta. Âncoras conferidas no `9a7ee1b`, porque o merge não tocou nenhum destes
arquivos:

- **O lugar velho, o pulo e o `--full`** (#1): `README.md:173–182`; `CLAUDE.md:299` (o hábito
  `sdd health --with-mutation`, hoje sinônimo do padrão, com pulo) e `:311` (o mapa em `.sdd/cache/`); `CONTEXT.md:32`
  (o verbete "Carimbo de mutação"); `docs/pipeline.md:528–545`. Os quatro precisam do lugar novo **e** do pulo e do
  `--full`.
- **`docs/failure-modes.md`** (#1): a receita da chave (`:1085–1086`) compara com `.sdd/logs/mutation-stamp`; a seção
  `:1104–1150` ensina a união do mapa e a cópia do carimbo, e contradiz o `/sdd-plan` novo; a `:1003` conta a regra
  velha ("the catalogue came back red, so the stamp was removed").
- **As jornadas** (#1): `docs/qa/journeys/J-health-verdict.md`, com o fluxo do pulo e do `--full`, a recusa
  `--full --release` e o `true_end_state` reescrito pela decisão 3 (`:11`, `:24–25`, `:63`, `:66–68`, `:80`);
  `J-certify-mission-close.md` (`:16`, `:18`, `:21`, `:63–64`); `J-target-repo-ships.md`, onde a frase do carimbo e do
  mapa no aviso do git < 2.31 só sai onde há `tests/check-mutation.sh` (F1).
- **A emenda da ADR 0007, pedida pelo dono:** a linha 6 da tabela (`docs/adr/0007-…:28`: "suite, ratchet and mutation catalogue
  green for this content", com o critério "the mutation stamp matches the tree") ainda descreve o critério com a frase velha.
  A linha 6 do `--release` (`bin/sdd:7273`) agora diz "the mutation catalogue measured this content green, over a suite
  green in that same run (its key is stamped; --release re-runs nothing)" (`20-handoff-exec.md`, carona 3).
- **As ADRs 0004 e 0021** (#7): o `Amends` da 0021 e o ponteiro na 0004 (`:98–100`) cobrem só a metade "catálogo
  vermelho". A 0021 §4 (`:54–59`) também inverte a 2ª metade: a janela não grava nem apaga.
- **A ADR 0021, os números** (#8): "four days older" (`:26–27`) e "written in 16 handoffs" (`:72–73`) precisam ser
  medidos e citados, ou tirados (a recontagem do agente achou 9 diretórios com `with-mutation`). Os comentários
  `bin/sdd:7314` ("sixteen handoffs") e `tests/check-hat.sh:785` ("ten handoffs") divergem do mesmo jeito (Minor do I2).
- **A ADR 0021, o resto** (`20-handoff-exec.md`): declarar a ressurreição pela semente na *Consequences*, corrigir a
  `:62–63` ("and leaving when they have no killer, as before") e decidir o `proposed` (`- **Status**: proposed`) junto
  da 0020 e do achado do `sdd approve` (`TODO.md:378`).
- **A ADR 0016** (`:121–123`): o corpo das Consequências ainda conta o passo velho. Só o cabeçalho "Amended by: 0021"
  marca a mudança.
- **A transição** (até o primeiro catálogo depois da branch não há mapa compartilhado), a anatomia
  (`.claude/rules/anatomia-do-agente.md` §6, se citar a cópia do mapa) e a entrada K8 do `KAIZEN_LOG.md` (10 h 58 → o
  pulo; a volta manual → nenhuma).

### Para o chore pós-merge

Da `main`, depois do merge, com a skill `todo-to-github-issues`. O `--fix --write` apaga os dois itens da missão
quando `6dbd63c`, `11fe1fe`, `4ae37c9` e `3e728d6` estiverem na `main`, e o merge tem de ser merge commit
(`TODO.md:136`). A catraca vai de **62 a 60**. Entram também, como itens do kit:

- **#10 desta rodada:** nenhum sensor durável prova que os três leitores chamam `load_killer_maps`
  (`tests/check-mutation.sh:432–434, 7918`). A direção é um mundo `--touched <rev> --list` com semente e sem
  compartilhado (~3 s), que cobre um leitor; o do catálogo só se prova no catálogo.
- **Do `20-handoff-exec.md` § *Achados fora de escopo*:**
  - o `sed` de mutante que vira no-op e passa calado pelo `--anchors` (`tests/check-mutation.sh:7611`, `:7614`);
  - o "nearest" do `check-todo.sh --anchors`, que sugeriu a ocorrência errada;
  - o `load_killer_map` (`:152`), que lê `A<TAB><TAB>10` como passo `10`;
  - o comentário pré-existente `tests/check-gates.sh:3787`;
  - o `TEST_CMD` (531–557 s) contra os 600 s do Bash de um subagente;
  - o `sessao:` de um relay interativo, que não tem fonte escrita.

  O censo do `check-health.sh:85–86` **sai desta lista**, porque virou o #6 do `R1`. O AUTO da skill
  `todo-to-github-issues` que quebra a `RECURRED` em 120 colunas vai para o `/retrofit-skill`, não para o `TODO.md`.
- **Do `30-handoff-qa.md` § *Achados fora de escopo*:** o §4 do `agents/sdd-qa.md` contra o `check-checkpoint.sh --red`
  (`tests/check-checkpoint.sh:72–82`), que recusa toda célula `F<n>` escrita pelo contrato. Vale também para este `R1`:
  o `--red` recusa célula com mais de um par (cabeçalho do `tests/check-checkpoint.sh`), então o vermelho dos quatro
  Checks foi medido à mão. Mais a linha `FAIL`
  que sai duas vezes no `sdd health` com saída curta (`bin/sdd:7396–7397`, observado, sem defeito).
