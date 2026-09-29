---
missao: 20260928-os-achados-da-janela
atualizado: 2026-09-28 16:11
---

# Checkpoint — os achados da janela do juiz

> **Este arquivo é lido por máquina.** O runner faz parse da tabela abaixo para decidir a
> próxima fase. Não mude as colunas, não mude os tokens de status, não quebre linhas dentro de
> uma célula. Detalhe narrativo vai no `01-plano.md`, não aqui.
>
> ⚠️ **Nada de `|` cru na célula do Check.** A tabela é lida com `awk -F'|'`: um pipe cru parte a
> célula em duas, o Status lido passa a ser um pedaço do comando e o Commit passa a ser `pending`.
> O `gate_EXEC` reprova por "invalid status" e o `sdd status` imprime algo de aparência saudável —
> custou uma missão inteira até alguém olhar. O escape do GFM, `\|`, o runner **hoje entende**:
> `checkpoint_rows` remonta a célula por paridade de `\`, como o `gate_REVIEW` já fazia. Isso é
> rede de segurança, não licença — Check que precisaria de pipe continua virando herestring:
> `` o=$(cmd 2>&1); grep -c 'x' <<< "$o" ``, e o `tests/check-checkpoint.sh` recusa as duas formas
> nos checkpoints deste repo.
>
> ⚠️ **A célula Commit leva o hash curto NU, sem crase.** `` `abc1234` `` renderiza igual ao hash
> nu, mas é a célula que o runner lê: o `checkpoint_rows` hoje tira a crase dessa coluna, e uma
> célula que não tem forma de SHA reprova o `gate_EXEC` com motivo próprio e para a linha como
> `no-work` antes de abrir sessão. Custou duas sessões EXEC sem trabalho em
> `20260921-amep-backend-0-1-0`.
>
> ⚠️ **Check que lê a saída de um sensor ancora em `^  ok    ` — quatro espaços, com o `^`.**
> Todo sensor da suíte imprime `  ok    <asserção>` na **stdout** e `  FAIL  <asserção>` na
> **stderr**, com o *mesmo* `<asserção>`. Um Check que faz `2>&1` e grepa o texto solto devolve o
> mesmo número com a asserção verde e com ela vermelha: ele responde "a asserção existe", nunca
> "a asserção passou". Custou uma missão inteira, achado só na fase QA. A forma certa:
> `` o=$(bash tests/check-x.sh 2>&1); grep -c '^  ok    <asserção>' <<< "$o" `` → `1`.
> O sensor é `tests/check-checkpoint.sh`.
>
> Atualizar o checkpoint é o **último ato** de cada incremento — depois do commit, nunca antes.
> Status válidos: `pending` · `doing` · `done` · `blocked`.

| ID | Incremento | Check (comando → esperado) | Status | Commit |
|---|---|---|---|---|
| I1 | Registrar os achados 1, 2 e 5 no `TODO.md`; catraca 83 → 86 (87 desde a rodada 5 da revisão, que registrou mais um achado) | `o=$(bash tests/check-todo.sh --count TODO.md); b=$(grep -c '^todo-findings ' tests/health-baseline.txt); n=$(grep -c '^todo-findings 87$' tests/health-baseline.txt); p=$(awk '/^### Contrato e configura/{c=NR} /^### Saída humana/{h=NR} /confere no Jira a issue que o chapéu/{a=NR} /grafia para incremento cujo produto/{x=NR} /bug aberto de OUTRA missão/{e=NR} END{print (a && a<c && c<x && x<e && e<h) ? "placed" : "misplaced"}' TODO.md); c=$(bash tests/check-todo.sh --check TODO.md 2>/dev/null); d=$(grep -c '^  ok    87 finding' <<< "$c"); echo "$o/$b$n/$p/$d"` → `87/11/placed/1` | done | 48e89b7 |
| I2 | A QA só fecha com o relatório que a branch da missão adicionou (`mission_qa_report`, dois leitores, recuo no range vazio) | `o=$(bash tests/check-gates.sh 2>/dev/null); a=$(grep -c '^  ok    QA gate refuses a closed report added before the mission branch' <<< "$o"); b=$(grep -c '^  ok    QA gate accepts the closed report the mission branch added' <<< "$o"); p=$(bash tests/check-dry-run.sh 2>/dev/null); c=$(grep -c '^  ok    a report from before the mission branch does not close the QA sub-step' <<< "$p"); m=$(grep -c -e '^mut_QA_report_not_mission_bound()' -e '^mut_QA_substep_report_not_mission_bound()' -e '^mut_QA_report_counts_modified()' -e '^mut_QA_report_no_fallback()' tests/check-mutation.sh); echo "$a$b$c/$m"` → `111/4` | done | 121a696 |
| I3 | `APP_EXPECT` e o estado `wrong` do `app_probe`, lidos pelo preflight e pelo `gate_QA` | `o=$(bash tests/check-preflight.sh 2>/dev/null); a=$(grep -c '^  ok    a page without APP_EXPECT fails the preflight when E2E_CMD is set' <<< "$o"); b=$(grep -c '^  ok    an empty APP_EXPECT keeps the TCP-only probe' <<< "$o"); c=$(grep -c '^  ok    without curl, APP_EXPECT reads unknown and never refuses' <<< "$o"); g=$(bash tests/check-gates.sh 2>/dev/null); d=$(grep -c '^  ok    QA gate names the wrong app at APP_URL when the e2e is red' <<< "$g"); k=$(grep -c '^APP_EXPECT=' config/starter.conf); echo "$a$b$c$d/$k"` → `1111/1` | done | 4423bb0 |
| I4 | A DOCS propõe o que o harness recusa: `.claude/rules/**` sai do `writes:`, `⛔` com texto proposto passa nomeado, o PR o carrega | `o=$(bash tests/check-gates.sh 2>/dev/null); a=$(grep -c '^  ok    DOCS gate passes a ⛔ row that carries proposed text, and names it' <<< "$o"); b=$(grep -c '^  ok    DOCS gate refuses a ⛔ row without the proposed-text marker' <<< "$o"); d=$(grep -c '^  ok    DOCS gate refuses a ⛔ row whose document is absent from the proposed section' <<< "$o"); h=$(bash tests/check-autonomy.sh 2>/dev/null); c=$(grep -c '^  ok    hat: a DOCS session that writes .claude/rules/ stops the line' <<< "$h"); w=$(grep -c '^writes:.*claude/rules' agents/sdd-docs.md); s=$(cmp -s agents/sdd-docs.md .claude/agents/sdd-docs.md && echo same); echo "$a$b$d$c/$w/$s"` → `1111/0/same` | done | 1ffee16 |
| I5 | `sdd close` faz fetch + `merge --ff-only` na `DEFAULT_BRANCH` e avisa na falha | `o=$(bash tests/check-gates.sh 2>/dev/null); a=$(grep -c '^  ok    close: fast-forwards the default branch to its upstream' <<< "$o"); b=$(grep -c '^  ok    close: a diverged default branch is warned, never forced' <<< "$o"); c=$(grep -c '^  ok    close: already on the default branch it still fast-forwards' <<< "$o"); m=$(grep -c '^mut_CLOSE_no_fast_forward()' tests/check-mutation.sh); echo "$a$b$c/$m"` → `111/1` | done | c320630 |
| I6 | `CHECKOUT-UNAVAILABLE` nomeia o requisito, o interpretador e o remédio sondado | `o=$(bash tests/check-coordination.sh 2>/dev/null); a=$(grep -c '^  ok    unavailable names the failed requirement, the interpreter and the remedy' <<< "$o"); b=$(grep -c '^  ok    unavailable pidfd refuses before config: missing' <<< "$o"); echo "$a$b"` → `11` | done | fbaf9a1 |
| I7 | Fechamento: `RESOLVED by` no item do achado 4, KAIZEN_LOG, ADR 0013 aceita, piso do `check-lang` 55, `CONTEXT.md`, anatomia e gaveta | `r=$(grep -cE 'RESOLVED by [0-9a-f]{7,}' TODO.md); k=$(grep -cE '^## [0-9-]{10} — Os achados da janela' KAIZEN_LOG.md); s=$(grep -c '^- \*\*Status\*\*: accepted' docs/adr/0013-o-relatorio-da-missao-e-o-texto-proposto.md); l=$(bash tests/check-lang.sh 2>/dev/null); d=$(grep -c '^  ok    0 of 55 surface path' <<< "$l"); f=$(grep -c 'n_surface" -lt 55 ' tests/check-lang.sh); n=$(bash tests/check-todo.sh --count TODO.md); echo "$r/$k/$s/$d/$f/$n"` → `1/1/1/1/1/87` | done | 3ac59ee |

> **As notas de execução não moram aqui.** Elas ficam em `checkpoint-notas.md`, ao lado deste
> arquivo, append-only, e o prompt de boot inlina as últimas 10 — a sessão nunca abre aquele
> arquivo. Medido: as notas eram 69% deste arquivo, e este arquivo era 44,7% de tudo que a missão
> releu. Este aqui é a **tabela** que o runner parseia, e só ela.
>
> ⚠️ Missão começada **antes** de `20260904-a-dieta-de-contexto` mantém as notas dentro do próprio
> `checkpoint.md`: o runner detecta pela presença do arquivo irmão e não migra nada em voo.

## Incrementos de fix (QA e REVIEW)

> Duas fases escrevem na tabela acima depois do EXEC, pelo mesmo motivo e pela mesma rota: quem
> **acha** não conserta, e o `current_phase()` devolve a bola ao EXEC sozinho porque uma linha
> `pending` reprova o `gate_EXEC` antes de o gate da fase que a escreveu ser lido.
>
> **`F<n>` — `sdd-qa`**, quando um bug sanável é reprovado. O Check obrigatoriamente inclui
> **regression test passa** + **re-walk da jornada impactada verde**. Bug que exige julgamento
> humano NÃO vira fix — vai para "Decisions for a Human" no handoff de QA.
>
> **`R<n>` — `sdd-reviewer`**, um por achado CRITICAL/HIGH da rodada; os MEDIUM/LOW baratos entram
> num único `R<n>` de lote por rodada (`"achados #4–#7 da r1"`), com um Check por achado dentro da
> célula. Caro demais vai para o `TODO_FILE`; o que exige julgamento humano vai para as pendências
> do `40-review-r<N>.md`, sem `R<n>`. O detalhe de cada achado mora na rodada mais recente, e a nota
> dela é honesta: um `B` com incrementos escritos é a rodada saudável.
