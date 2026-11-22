---
missao: 20261121-l4-preflight-health-e-sensores
fase: REVIEW
rodada: 1
status: done
sessao: 60f06522-055e-4a9c-8521-5b58c1e555f1
data: 2026-11-22 01:36
gate: "tests/run-all.sh em 74d35dbdcb2fa2a6dce27b9cfa1aa21f5e6d9959 → rc 0, suite green, 2331 linhas ok, 0 FAIL (grep -cE '^  FAIL'), anchors: all 985 mutants still apply; árvore limpa antes da rodada (git status --short vazio); varredura de segredos do codereview sobre 86e16c0...HEAD: 0 achados (regex + gitleaks, 25 arquivos, 3000 linhas)"
reviewed_head: 74d35dbdcb2fa2a6dce27b9cfa1aa21f5e6d9959
---

# Review — rodada r1 — L4: preflight, health e sensores

## TL;DR

Rodada inteira sobre `86e16c0...74d35db` (25 arquivos, +3000/−203): `/codereview:codereview` com três
agentes por arquivo (o `bin/sdd`; `check-preflight`/`check-dry-run`/`isolate-git`; os outros sensores,
o catálogo e os templates). Nenhum CRITICAL e nenhum HIGH. Seis LOW baratos e reproduzíveis viraram
**um** `R1` de lote. Três achados foram refutados com evidência e seis LOW ficaram como limite aceito.
A suíte está verde. A nota é B em Error Handling e Test Coverage, e o `R1` fecha os dois.

## Nota da rodada

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | A | O `phase_skills_check` é uma definição só para o preflight, o run e o retry, e quem tem efeito em global é chamado, nunca lido por `$( )`. O código novo usa herestring, `CDPATH=''` e capturas guardadas. |
| Type Safety | A | Não se aplica a bash. As formas de JSON que o jq lê (`hook_response`, `.skills` da `init`, `tool_result`) conferem com um stream real desta missão (`EXEC-20261121-221807`). |
| Error Handling | B | Dois sentinelas de falha dão o motivo errado: um `git status` que falha é dito "não versionado", e um jq que falha é dito "o modelo repetiu o marcador" (R1 #1 e #2). |
| Security | A | Varredura de segredos limpa. O `test_cmd_stragglers` nomeia só pid e `comm`, nunca argumentos, e há asserção para isso com `exec -a`. |
| Performance | A | O custo novo é limitado: a busca em `/proc/*/environ` roda uma vez por preflight e lê só arquivos legíveis, o laço de revisões do preâmbulo percorre o `git log` de um template só, e o `mapfile` troca um pipe por uma lista. |
| Test Coverage | B | Os 31 mutantes aplicam e foram pegos. Mesmo assim, quatro asserções podem passar vazias ou sem o probe da regra: os mundos wt/det, o `fails_of` vazio, o CRLF da regra 7 e o `hat_guard_check` do `cmd_kaizen` sem mutante (R1 #3 a #6). |
| Documentation | B | `failure-modes.md`, `config/schema.md` e os templates acompanham o código. O censo do `CLAUDE.md` (13 → 15 portas) e a §6 da rule estão defasados, e isso já é linha ⛔ da DOCS (pendência 3). |
| **Overall** | **B** | Lote correto e bem medido, sem achado funcional grave. Seis LOW de sentinela e de cobertura vão num `R1` de lote, e a r2 re-avalia. |

## Achados da rodada

| # | Severidade | Achado | Onde |
|---|---|---|---|
| 1 | LOW | Quando o `git status` falha, o sentinela `?? (git status failed)` começa com `?? `. O `grep -qv '^?? '` lê isso como "todos não versionados", e o preflight manda listar a falha no `info/exclude`. | `bin/sdd` (bloco `_pf_dirty` do `cmd_preflight`) |
| 2 | LOW | Quando o jq falha sobre o stream da sonda, `probe_ran` cai em `none` (`\|\| probe_ran=none`). Se a resposta tiver o marcador, o `_fail` diz que o modelo o repetiu sem rodar nada, e a falha real é do leitor. | `bin/sdd` (o `probe_ran` do `cmd_preflight`) |
| 3 | LOW | Os mundos `wt` e `det` da asserção "says nothing" do `kit_stale_check` são montados com `>/dev/null 2>&1` e sem testemunha. Um `worktree add` ou um `checkout --detach` que falhe deixa o mundo calado pelo motivo errado (sem diretório, ou um nível igual ao `level`), e a asserção passa vazia. | `tests/check-preflight.sh` (mundos `KS/wt`, `KS/det`) |
| 4 | LOW | O `fails_of` devolve vazio quando a linha `N check(s) failed` falta. Com os dois lados vazios, `$(( - ))` é erro de sintaxe, e o sensor (sem `-e`) pula o `assert_eq` sem `ok` nem `FAIL`. | `tests/check-preflight.sh:414,432` |
| 5 | LOW | O `sub(/\r$/, "")` do `frontmatter_updated` não tem probe. Sem ele, o `atualizado:` de um checkpoint com CRLF deixa de casar o `CLOCK_RE`, e uma hora no futuro passa calada (falha aberta). | `tests/check-checkpoint.sh:1395` |
| 6 | LOW | Os três mutantes `KAIZEN_hat_guard_*` sabotam as duas portas e o `hat_guard_arm`. Nenhum tira um dos dois `hat_guard_check` do `cmd_kaizen`, que é o setter do marcador. O sensor o pega, mas o catálogo não prova isso. | `tests/check-mutation.sh:3053-3060`, `bin/sdd` (`cmd_kaizen`) |
| 7 | LOW | O `SDD_SKILLS_ROOT` vazio do `isolate-git.sh` não tem sensor nem mutante. | `tests/isolate-git.sh` |
| 8 | LOW | A regra 7 só pega a hora futura até o relógio alcançá-la, e o cabeçalho não diz isso. | `tests/check-checkpoint.sh` (cabeçalho da regra 7) |
| 9 | LOW | O `pr_scan` conta crase por linha física: um code span quebrado em duas linhas dá falso positivo (falha fechada), e `pr #N` minúsculo não é lido. Nenhum dos dois está nos limites declarados. | `tests/check-todo.sh` (`pr_scan`) |
| 10 | LOW | O `judge_base_probes` confere a frase da §7 do chapéu, não o `HAT_WRITES_BASE` do runner. | `tests/check-hat.sh` (`judge_base_probes`) |
| 11 | LOW | O `intr_tree_kill` com `pgrep -P … \|\| true` deixa filhos vivos sem aviso quando não há `pgrep`. | `tests/check-health.sh` (`intr_tree_kill`) |
| 12 | LOW | O probe da projeção do `cmd_kaizen` mede a ordem do `hat_guard_check`, não um arme. O comentário diz outra coisa. | `tests/check-kaizen.sh` |

## Incrementos de conserto (R<n>)

| R<n> | Achado | Check escrito no checkpoint |
|---|---|---|
| R1 | Achados #1–#6 da r1, em lote | `o=$(bash tests/check-preflight.sh 2>&1); c=$(bash tests/check-checkpoint.sh 2>&1); echo "$(grep -c '^  ok    preflight says git status failed, and never that the dirty paths are untracked, when git status fails' <<< "$o") $(grep -c '^  ok    preflight says the stream of the Bash probe could not be read when jq fails on it, and never that the model repeated the marker' <<< "$o") $(grep -c '^  ok    the silent worlds of kit_stale_check are a linked worktree and a detached HEAD, measured before their silence is read' <<< "$o") $(grep -c '^  ok    the hooks block reads both failure counts it subtracts' <<< "$o") $(grep -c '^  ok    rule: an atualizado later than the clock is refused in a checkpoint with CRLF line ends' <<< "$c") $(grep -c '^mut_KAIZEN_hat_guard_check_dropped() {' tests/check-mutation.sh)"` → `1 1 1 1 1 1` |

## O que virou incremento

- #1: o `git status` que falha ganha mensagem própria, e o sentinela deixa de começar com `?? `. Virou `R1`, e a primeira asserção exige que o preflight diga a falha e nunca o texto do `info/exclude`.
- #2: a falha do jq vira um terceiro valor (`error`, por exemplo), com motivo próprio ("o stream não pôde ser lido"). Virou `R1`, e a asserção exige esse motivo e a ausência da frase "repeated the text".
- #3: cada mundo calado ganha testemunha medida antes do silêncio: o `wt` com `--git-dir` diferente do `--git-common-dir`, e o `det` sem `symbolic-ref`. Virou `R1`.
- #4: o `fails_of` usa o `failed_count` que já existe, ou um default `${x:-0}` com asserção de que os dois lados foram lidos. Virou `R1`.
- #5: o probe CRLF entra no selftest da regra 7 (`PROBE_FLOOR` sobe junto). Virou `R1`.
- #6: um `mut_KAIZEN_hat_guard_check_dropped` que tira o `hat_guard_check` da primeira porta do `cmd_kaizen`, pego por `--only KAIZEN_hat_guard_check_dropped tests/check-kaizen.sh` antes do commit (anotado nas notas). Virou `R1`.

## O que foi refutado

- **O censo do `CLAUDE.md` defasado (13 → 15 portas, "QUATRO portas")**, levantado como MEDIUM pelo agente do `bin/sdd`, não vira `R<n>`. A sessão headless não edita o `CLAUDE.md` (fora de escopo do `00-missao.md`), e a pendência 3 já entrega o texto à DOCS como linha ⛔. Medido: `grep -cE '^ +if [a-z_]+_escalation "\$phase"; then' bin/sdd` → 15.
- **O `hook_response` sem `exit_code` dispararia o aviso em todo hook saudável.** O stream real `EXEC-20261121-221807-94dc94dc.stream.jsonl` traz `"exit_code":0,"outcome":"success"` em todo `hook_response`, então o mundo do achado não existe no harness medido (2.1.327).
- **O git < 2.31 ecoa `--path-format=absolute` no `repo_is_linked_worktree` e no `kit_stale_check`.** Segui os dois casos à mão. No checkout principal, os dois lados ecoam a mesma opção e o mesmo `.git`, e a resposta é "principal". No worktree ligado, o `--git-dir` é absoluto e diferente do comum, e a resposta é "ligado". O próprio agente não achou defeito demonstrado.
- **O "pipe race" do item 12 sem mutante.** O mutante existe: `mut_PRE_read_rules_cover_stream_read` (`tests/check-mutation.sh:2964`), que devolve o `while read` sobre o stream, está listado no catálogo.

## Achados fora de escopo

Nenhum vai para o `TODO.md`. Os LOW #7 a #12 não passam na régua de admissão D15: nenhum faz um
sensor afirmar o que não mede sobre o produto, e nenhum tem consumidor fora da suíte do kit. O #9
falha fechado, o #11 deixa processo e não um veredito errado, e o #7 fica vermelho, alto, na máquina
com o plugin. São dívida a declarar no cabeçalho de cada sensor na próxima vez que alguém o tocar,
não backlog.

## Pendências / Decisions for a Human

Nenhuma.
