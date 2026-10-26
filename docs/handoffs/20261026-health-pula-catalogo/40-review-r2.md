---
missao: 20261026-health-pula-catalogo
fase: REVIEW
rodada: 2
status: done
sessao: 4b9c28f8-7152-4e88-aae7-0bf05f85f18c
data: 2026-10-26 10:40
gate: A rodada fecha: A nos seis critérios com sensor, B em Documentation e Overall (REVIEW_PROSE_CRITERIA, piso B), e nenhum R<n> aberto. Contra a r1, as letras são as mesmas. O laço para porque chegou ao critério de parada, não por platô, e o movimento entre as rodadas é o R1, fechado em `96fd555`, o commit de conserto do sdd-executor (os quatro Checks em `1 1 1 1`). TEST_CMD `tests/run-all.sh` no HEAD `093a02b`, rodado pelo relay → rc 0, 539 s, 2059 `ok`, 0 `FAIL`, `62 finding(s)` e `anchors: all 792 mutants still apply` (`/home/pc_admin/.wt/plan-health-pula-catalogo/sdd/suite-093a02b.log`; `suite-093a02b.rc` → `rc=0 secs=539`). O log traz uma vez cada as duas asserções novas do R1. Pré-scan de segredos da r2, `scan_secrets.sh` (regex), sobre 6 arquivos e 384 linhas acrescentadas → 0 achados e 0 erros (`secrets-prescan-r2.json`). `/codereview` 2.27.11 sobre `9a7ee1b...093a02b` (4 commits): 3 agentes por arquivo e a varredura de código morto, todos sonnet. `check-checkpoint.sh --check` → rc 0, e a tabela não tem linha pending. Depois do commit desta rodada, `git diff --name-only 093a02b HEAD` lista só a pasta da missão e `git status --porcelain` sai vazio
---

# Review — rodada r2 — o `sdd health` pula o catálogo com a chave já medida

> Escrito ao fim de cada rodada de revisão, em `docs/handoffs/<missão>/40-review-r<N>.md`.
> O runner lê **a mais recente**. Uma rodada que não fechou também escreve o arquivo, com a nota
> real: nota inflada para passar no gate desliga o único sensor de qualidade da missão.

## TL;DR

A r2 revisou `9a7ee1b...093a02b` (o R1 e o relatório da r1) com 3 agentes e a varredura, e o scan de segredos passou. **Fecha em B, sem `R<n>`.**
O R1 da r1 está fechado em `96fd555`: Checks `1 1 1 1`, 483 ok no `check-gates.sh`, e os dois sensores do R1 sem achado.
São 5 achados, todos de prosa: 3 MEDIUM no `20-handoff-exec.md`, nascidos da própria seção do R1, e 2 LOW. Pelo §3,
prosa nunca vira `R<n>`. O boot abaixo leva o estado de agora. A suíte do `093a02b` saiu verde (rc 0, 2059 ok, 0 FAIL).
Próxima: a **DOCS**. O boot abaixo leva a lista dela, o estado depois do merge e o chore pós-merge, que antes estavam na r1.

## Nota da rodada

A tabela abaixo é a do `codereview-r2.md` (`/home/pc_admin/.wt/plan-health-pula-catalogo/sdd/`), **verbatim** nas
notas e nos motivos. Como na r1, só o heading muda: o relatório da skill escreveu `## Overall Grade`, e o contrato
(`agents/sdd-reviewer.md` §4) pede `###`.

**Movimento (§2):** a r1 e a r2 têm as mesmas letras (seis A e dois B). Mesmas letras seriam um platô se a rodada não
tivesse fechado. Esta fechou: todo critério com sensor está em A, e os dois de prosa estão no piso B. O que andou
entre as rodadas tem commit de conserto, o `96fd555`, do `sdd-executor`, que fechou o R1. Os LOW de código da r1 (#3–#6)
não voltaram.

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | A | os dois sensores do R1 sem achado; código morto limpo |
| Type Safety | A | n/a (bash) — nada a apontar |
| Error Handling | A | a guarda nova falha alto (`SENSOR-BROKEN`); o 7b sem passagem calada |
| Security | A | Secrets PASS; nenhum achado |
| Performance | A | nada a apontar |
| Test Coverage | A | os quatro Checks do R1 em `1 1 1 1`; 13 sabotagens, 12 vermelhas e 1 equivalente declarada |
| Documentation | B | 3 MEDIUM de prosa no handoff do EXEC (#1–#3), nascidos da própria seção do R1 — carregados pelo `40-review-r2.md` |
| **Overall** | **B** | código e sensores em A; a nota cai só pela prosa do handoff, que esta rodada carrega e a DOCS lê |

## Achados da rodada

> Numeração do `codereview-r2.md`. Sobre os sensores do R1 (`tests/check-gates.sh` e `tests/check-health.sh`), os agentes não acharam nada. A guarda
> `i4_place` falha alto quando o fixture não resolve o common dir, e o mundo 7b não passa calado em nenhum modo de
> falha. O cabeçalho e o censo (11 + 2 = 13) conferem com o arquivo. Sobre o `40-review-r1.md` também não houve
> achado: ele é o retrato do `9a7ee1b`, como declara.

| # | Severidade | Achado | Onde | Destino |
|---|---|---|---|---|
| 1 | MEDIUM | A seção nova "REVIEW r1 — R1" contradiz o resto do mesmo arquivo: o frontmatter (`data`, `gate:` até `8328a7e`), o TL;DR ("Próximo: a QA de novo"), o *Estado do repo* (último commit de conteúdo `f98846d`; agora é `96fd555`), a tabela da suíte (até `8328a7e`) e o *Boot* (ainda o da QA) | `20-handoff-exec.md:5–7, 21, 139–146, 292–297` | prosa: o estado de agora vai no boot abaixo; o retrato datado fica com o dono, depois do PR |
| 2 | MEDIUM | As âncoras em `tests/check-gates.sh` (+41 linhas no `96fd555`) e em `tests/check-health.sh` (+4/5) ficaram defasadas no handoff | `20-handoff-exec.md:41, 231, 236, 345, 477, 479–480, 544, 562, 567, 570, 572` | prosa: as âncoras de agora vão no boot abaixo |
| 3 | MEDIUM | O item "o censo do `check-health.sh:85–86` não conta `./bin/sdd health` → chore pós-merge" descreve o defeito que o R1 #6 consertou (`96fd555`). Levado ao chore, viraria item duplicado de um defeito já fechado | `20-handoff-exec.md:479–480` | sai da lista do chore (abaixo) |
| 4 | LOW | A contagem da sabotagem do R1. As notas trazem 13 sabotagens de verdade: 12 vermelhas e 1 equivalente (o `--full` do 7b). A 14ª linha, o `esac` e a prosa, não é degradação. O handoff diz "14, treze vermelhas, a 14ª tirou o `--full`" | `20-handoff-exec.md:113–121` × `checkpoint-notas.md:99–112` | prosa: o número certo vai no boot abaixo |
| 5 | LOW | Os Checks #5 e #6 do R1 só provam que a string existe, e as faixas de linha da célula são as do `9a7ee1b` | `checkpoint.md:58` | aceito: é o veredito da r1 (Check de prosa de comentário); a célula está `done` e não se reescreve, e as âncoras de agora vão no boot |

**A recomendação da rodada para o fluxo do dono, depois do PR.** O `/codereview` do dono vai até A e lê o diff da
missão inteira. Para ele, o *Estado do repo*, o TL;DR e o *Boot* do `20-handoff-exec.md` deveriam virar um retrato
datado do fecho do EXEC. O jeito é tirar a afirmação, não acrescentar evidência, como a skill `codereview` recomenda em
*Docs this session wrote* ("recommend removing the claim"). Esta rodada não reescreve o `20-`.

### Onde o relatório do `/codereview` diverge do contrato, e o que fiz

- **O heading da nota:** o relatório escreveu `## Overall Grade`, e aqui vai `###`, como na r1.
- **A prosa (#1–#4) não vai para o `TODO_FILE`:** o §3 manda achado só de prosa para o `TODO_FILE`. Só que estes
  achados são da prosa do handoff desta missão, não do kit, e o `TODO.md` é o backlog do kit. Além disso, a M4 trava a
  catraca. O que o §3 proíbe, e que aqui não acontece, é o `R<n>`. O estado de agora vai no boot abaixo, e o retrato
  datado fica com o dono.

## Incrementos de conserto (R<n>)

> **Esta rodada não conserta.** Cada achado que precisa de conserto vira uma linha `R<n>` na tabela
> de incrementos do `checkpoint.md`, e o `sdd-executor` a fecha em TDD, numa sessão de contexto
> próprio; a rodada seguinte re-avalia sem ter escrito o conserto.

Nenhum `R<n>` nesta rodada. Os cinco achados são de prosa, e o §3 nunca transforma prosa em `R<n>`: a
`20260902-o-rascunho-legado-fala-cru` gastou quatro rodadas e ~US$ 133 nesse laço, com zero achado funcional. A tabela do
`checkpoint.md` não ganha linha e fica sem `pending`.

| R<n> | Achado | Check escrito no checkpoint |
|---|---|---|
| — | nenhum: os cinco achados da r2 são de prosa (§3) | nenhum Check novo; a tabela segue com I1–I5, F1, F2 e R1 `done` |

## O que virou incremento

- **O `R1` da r1 (achados #3–#6), fechado em `96fd555`** (checkpoint `500cdf7`, handoff `093a02b`). Ele se prova
  fechado de três jeitos:
  - **pelo log da suíte do `093a02b`, que eu li:** a linha `^  ok    stamp: the fixture resolves the git common dir before a world reads a stamp` aparece
    1 vez, e a `^  ok    stamp: a green catalogue after a removal stamps the key again` também 1 vez;
  - **pelos greps de arquivo, que eu rodei no `093a02b`:** `grep -c 'A LINKED WORKTREE (14)' tests/check-gates.sh` → `1` e
    `grep -c '13 sites' tests/check-health.sh` → `1`;
  - **pelo controle do EXEC:** `check-gates.sh` rc 0, 483 ok (481 + 2), 0 FAIL.

  Os quatro tinham dado `0 0 0 0` no `9a7ee1b`
  (`40-review-r1.md`). A guarda do #3 é o `i4_place` (`tests/check-gates.sh:3282`, o bloco `:3274–3288`). O mundo do #4 é
  o 7b (`:3515–3527`). O cabeçalho do #5 é a `:3163–3188`, e o censo do #6 é a `tests/check-health.sh:82–93`. O 7b usa o
  `i4_health`, então o R1 não abriu sítio novo, e a conta segue 13.
- **Nenhum achado da r2 virou incremento** (acima).

## O que foi refutado

Nenhum achado foi refutado nesta rodada. O #5 foi aceito, e não refutado: um Check de comentário prova que a frase
existe, e um conserto de comentário não tem como provar mais que isso. A r1 já tinha dado esse veredito.

## Achados fora de escopo

Nenhum item novo entrou no `TODO.md` (M4). A r2 não acrescenta achado do kit, e a lista do chore pós-merge, levada
adiante no boot abaixo, perde o item do censo (#3).

## Pendências / Decisions for a Human

- **O retrato datado do `20-handoff-exec.md`** (#1): é a recomendação para o fluxo do dono depois do PR, descrita acima.
- **Seguem com o dono, sem mudança desde a r1** (`20-handoff-exec.md` § *Pendências*):
  - a ressurreição pela semente (I3, `3e728d6`): declarar e deixar, a lápide `slug TAB TAB`, ou "semente só sem
    compartilhado";
  - a cópia do kit sem `.git` dentro de outro repositório, que resolve o `git-common-dir` do outro: guardar ou declarar;
  - o carimbo do operador, a M3 e o chore pós-merge, descritos abaixo.

## Boot da próxima fase

**Próxima: a DOCS.** A REVIEW fechou em B sem `R<n>`, e a tabela do `checkpoint.md` não tem linha `pending`: I1–I5, F1, F2
e R1 estão `done`. Valem as regras de sempre:

- todo comando como `cd /home/pc_admin/repos/sdd_agents-health-pula-catalogo && …`;
- nunca o `sdd` do PATH, que é o kit velho até o merge;
- nunca `./bin/sdd health`, `run` ou `status` na worktree, porque o `./bin/sdd health` da worktree é o carimbo do
  operador, depois dos bots;
- nunca `bash tests/check-mutation.sh` sem modo.

**Este boot substitui o da r1:** ele leva tudo o que aquele tinha, com os números medidos no `093a02b`. O
`20-handoff-exec.md` e o `30-handoff-qa.md` são retratos datados, com números de antes do merge e do R1, e não foram
reescritos. Onde eles divergem deste boot, vale este.

### O estado de agora (`093a02b`)

- **Commits:** o último commit de conteúdo é o **`96fd555`** (o R1, só `tests/check-gates.sh` e `tests/check-health.sh`).
  Depois dele vieram o `500cdf7` (checkpoint), o `093a02b` (handoff do EXEC) e o commit desta rodada, todos só na pasta
  da missão. Antes do R1, o último era o `f98846d` (F2), depois o merge `9a7ee1b` da `origin/main` `cc993f7` (PR #329).
- **A suíte:** `tests/run-all.sh` no `093a02b` → rc 0, 539 s, 2059 `ok`, 0 `FAIL`, `62 finding(s)` e `anchors: all 792
  mutants still apply` (`/home/pc_admin/.wt/plan-health-pula-catalogo/sdd/suite-093a02b.log`). A anterior, do `9a7ee1b`,
  deu 543 s e 2057 ok. As 2 de diferença são as asserções do R1.
- **A catraca é 62** (`tests/health-baseline.txt:26`), e o `TODO.md` não mudou desde o `9a7ee1b`. O merge do #329 trouxe
  um item da `main`, 8 linhas inseridas depois da `:116`. Onde os handoffs dizem "61", leia 62, e onde dizem "o chore
  leva de 61 a 59", leia **de 62 a 60**. A M4 segue: a missão não acrescenta item.
- **As linhas do `TODO.md` que andaram +8 com o merge:**
  - `RECURRED 7` `:225` → `:233`;
  - `KILLERS_FILE` `:503` → `:511`;
  - o título do 2º item da missão `:502` → `:510`, com o `RESOLVED by 4ae37c9` `:508` → `:516`;
  - o achado do squash `:128` → `:136`;
  - o `sdd approve` `:370` → `:378`;
  - `:533`, `:537` e `:556`, todas +8.

  O 1º item da missão não andou (`:26`, com o `RESOLVED by 6dbd63c` em `:32`). A célula do I5 cita `:502`, que hoje é
  `:510`, mas o Check dela conta pelo `awk`, não pela linha.
- **O checkout principal** `/home/pc_admin/repos/sdd_agents` está em **`cc993f7`**, com `status --porcelain` vazio e sem
  `.git/sdd-mutation`. O `bin/` dele é igual ao do `c114e36`, então o `sdd` do PATH (`~/.local/bin/sdd`) continua sendo o
  kit velho, com o risco que o `20-handoff-exec.md` § *A pendência do operador* descreve.
- **As âncoras de agora** (achado #2 da r2, medidas no `093a02b`):

  | Item | Antes | Agora |
  |---|---|---|
  | `write_stub_suite` | `check-health.sh:262` | `:266` |
  | `! grep -qF "$STAMPED"` da `skip: 1` | `:1098` | `:1102` |
  | `! grep -qF "$STAMPED"` da `skip: 3` | `:1139` | `:1143` |
  | o `./bin/sdd health` da `skip: 5` | `:1194` | `:1198` (o handoff e a nota do EXEC dizem `:1199`) |
  | `i4_write_suite` | `check-gates.sh:3288` | `:3310` |
  | `i4_health` | `:3250` | `:3257` |
  | `fixture_stamps` | `:3257` | `:3264` |
  | `fixture_stamped` | `:3266` | `:3273` |
  | o mundo 7 | `:3483–3488` | `:3505–3513` |
  | o comentário do mundo 9 ("never a leftover of world 8") | `:3548` | `:3588` |
  | o `./bin/sdd health` do mundo 14 | `:3684` | `:3724` |
  | o stub do `TREE_KIT` | `:3743–3748` | `:3784–3789` |
  | o comentário "The control file still says" | `:3787` | `:3828` |

  O `bin/sdd`, o `tests/check-mutation.sh` e a doc do repo não mudaram desde o `9a7ee1b`, então as âncoras deles seguem
  as da r1. A célula R1 do `checkpoint.md` cita as linhas do `9a7ee1b` (achado #5): é histórica e está `done`.
- **A sabotagem do R1** (achado #4): o certo é **13/12/1**, 13 degradações reais, 12 vermelhas e 1 equivalente (o
  `--full` do 7b), como dizem as notas (`checkpoint-notas.md:99–112`). A 14ª linha, o `esac` e a prosa, não é
  degradação. O R1 não entrou com mutante no `CATALOG`: não há um natural, porque a gravação não guarda estado entre
  rodadas (`20-handoff-exec.md` § *REVIEW r1 — R1*).
- **A célula F1** cita `bin/sdd:6482–6488`, que era a linha no `096c625`. Hoje o código está em `bin/sdd:6487–6497`. A
  célula é histórica.

### Para a fase DOCS

A lista vem do `01-plano.md` § *Para a fase DOCS*. O `20-handoff-exec.md` § *Para a fase DOCS* a amplia, e o
`30-handoff-qa.md` § *Para a fase DOCS* detalha as jornadas. Os três seguem valendo e trazem o porquê de cada linha;
somam-se a eles os achados #1, #7 e #8 da r1 e a emenda da ADR 0007. Nenhum destes arquivos mudou desde o `9a7ee1b`, então
as âncoras são as que a r1 conferiu:

- **O lugar velho, o pulo e o `--full`** (r1 #1). Os quatro arquivos abaixo precisam do lugar novo **e** do pulo e do
  `--full`:
  - `README.md:173–182`;
  - `CLAUDE.md:299`, o hábito `sdd health --with-mutation`, hoje sinônimo do padrão, com pulo;
  - `CLAUDE.md:311`, o mapa em `.sdd/cache/`;
  - `CONTEXT.md:32`, o verbete "Carimbo de mutação";
  - `docs/pipeline.md:528–545`.
- **`docs/failure-modes.md`** (r1 #1):
  - a receita da chave (`:1085–1086`) compara com `.sdd/logs/mutation-stamp`;
  - a seção `:1104–1150` ensina a união do mapa e a cópia do carimbo, e contradiz o `/sdd-plan` novo;
  - a `:1003` conta a regra velha ("the catalogue came back red, so the stamp was removed").
- **As jornadas** (r1 #1):
  - `docs/qa/journeys/J-health-verdict.md`: o fluxo do pulo e do `--full`, a recusa `--full --release` e o
    `true_end_state` reescrito pela decisão 3 (`:11`, `:24–25`, `:63`, `:66–68`, `:80`);
  - `J-certify-mission-close.md` (`:16`, `:18`, `:21`, `:63–64`);
  - `J-target-repo-ships.md`: a frase do carimbo e do mapa no aviso do git < 2.31 só sai onde há
    `tests/check-mutation.sh` (F1).
- **A emenda da ADR 0007, pedida pelo dono:** a linha 6 da tabela (`docs/adr/0007-…:28`: "suite, ratchet and mutation
  catalogue green for this content", com o critério "the mutation stamp matches the tree") ainda descreve o critério com
  a frase velha. A linha 6 do `--release` (`bin/sdd:7273`) agora diz "the mutation catalogue measured this content
  green, over a suite green in that same run (its key is stamped; --release re-runs nothing)".
- **As ADRs 0004 e 0021** (r1 #7): o `Amends` da 0021 e o ponteiro na 0004 (`:98–100`) só cobrem a metade "catálogo
  vermelho". A 0021 §4 (`:54–59`) inverte também a 2ª metade: a janela não grava nem apaga.
- **A ADR 0021, os números** (r1 #8): "four days older" (`:26–27`) e "written in 16 handoffs" (`:72–73`) precisam ser
  medidos e citados, ou tirados (a recontagem do agente achou 9 diretórios com `with-mutation`). Os comentários
  `bin/sdd:7314` ("sixteen handoffs") e `tests/check-hat.sh:785` ("ten handoffs") divergem do mesmo jeito.
- **A ADR 0021, o resto** (`20-handoff-exec.md`):
  - declarar a ressurreição pela semente na *Consequences*;
  - corrigir a `:62–63` ("and leaving when they have no killer, as before");
  - decidir o `proposed` junto da 0020 e do achado do `sdd approve` (`TODO.md:378`).
- **A ADR 0016** (`:121–123`): o corpo das Consequências ainda conta o passo velho. Só o cabeçalho "Amended by: 0021"
  marca a mudança.
- **Mais três itens:**
  - a transição: até o primeiro catálogo depois da branch, não há mapa compartilhado;
  - a anatomia (`.claude/rules/anatomia-do-agente.md` §6), se ela citar a cópia do mapa;
  - a entrada K8 do `KAIZEN_LOG.md`: 10 h 58 → o pulo, e a volta manual → nenhuma.

### Para o chore pós-merge

O chore roda da `main`, depois do merge, com a skill `todo-to-github-issues`. O `--fix --write` apaga os dois itens da missão
quando `6dbd63c`, `11fe1fe`, `4ae37c9` e `3e728d6` estiverem na `main`. O merge tem de ser merge commit
(`TODO.md:136`). A catraca vai de **62 a 60**. Entram também, como itens do kit:

- **O #10 da r1:** nenhum sensor durável prova que os três leitores chamam `load_killer_maps`
  (`tests/check-mutation.sh:432–434, 7918`). A direção é um mundo `--touched <rev> --list` com semente e sem
  compartilhado (~3 s), que cobre um leitor. O do catálogo só se prova no próprio catálogo.
- **Do `20-handoff-exec.md` § *Achados fora de escopo*:**
  - o `sed` de mutante que vira no-op e passa calado pelo `--anchors` (`tests/check-mutation.sh:7611`, `:7614`);
  - o "nearest" do `check-todo.sh --anchors`, que sugeriu a ocorrência errada;
  - o `load_killer_map` (`:152`), que lê `A<TAB><TAB>10` como passo `10`;
  - o comentário pré-existente "The control file still says `move-the-tree` from world 8", hoje em
    `tests/check-gates.sh:3828`;
  - o `TEST_CMD` (531–557 s) contra os 600 s do Bash de um subagente;
  - o `sessao:` de um relay interativo, que não tem fonte escrita.

  **O censo do `check-health.sh:85–86` saiu da lista** (achado #3 da r2): o R1 #6 o consertou no `96fd555`. O AUTO da
  skill `todo-to-github-issues` que quebra a `RECURRED` em 120 colunas vai para o `/retrofit-skill`, não para o
  `TODO.md`.
- **Do `30-handoff-qa.md` § *Achados fora de escopo*:**
  - o §4 do `agents/sdd-qa.md` contra o `check-checkpoint.sh --red` (`tests/check-checkpoint.sh:72–82`). O `--red`
    recusa toda célula `F<n>` escrita pelo contrato, e também a célula de vários pares do `R1`, cujo vermelho foi
    medido à mão;
  - a linha `FAIL` que sai duas vezes no `sdd health` com saída curta (`bin/sdd:7396–7397`), observada e sem defeito.
