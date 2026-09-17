---
missao: 20260917-o-numero-do-adr-nao-e-prosa
atualizado: 2026-09-17 16:26
---

# Checkpoint — o número do ADR não é prosa

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
| I1 | Chaves `ADR_CHECK`/`ADR_DIR`, esqueleto `cmd_adr`, `adr)` no main, help, `tests/check-adr.sh` + 5 registros, kit `warn` | `o=$(bash tests/check-adr.sh 2>&1); grep -c '^  ok    ADR_CHECK=bogus is refused with rc 2' <<< "$o"` → `1` | done | `b026875` |
| I2 | `sdd adr check --mission` + 2 mutantes | `o=$(bash tests/check-adr.sh 2>&1); grep -c '^  ok    ADR whose Spec: points elsewhere fails' <<< "$o"` → `1` | done | `27156b0` |
| I3 | Escopo repo: `SPEC_DIR`, specs SpecKit, número solto, duplicata, stub não preenchido + 1 mutante | `o=$(bash tests/check-adr.sh 2>&1); grep -c '^  ok    a bare ADR 0042 in a spec with no file fails' <<< "$o"` → `1` | done | `34fadb3` |
| I4 | `sdd adr new` (max+1, O_EXCL, stub, `--spec`, `--dry-run`) + 1 mutante + ADR 0008 criado pelo comando + check-lang 46→47 | `./bin/sdd adr check --mission 20260917-o-numero-do-adr-nao-e-prosa; echo rc=$?` → `rc=0` | done | `004ed1d` |
| I5 | `adr_gate_verdict` em `gate_PLAN`/`gate_EXEC`, `adr:` no template + check-templates + 3 mutantes | `o=$(bash tests/check-adr.sh 2>&1); grep -c '^  ok    block: ADR file removed after approval makes EXEC refuse' <<< "$o"` → `1` | done | `3e6c4a8` |
| I6 | `warn` = uma linha `degraded kind:adr-check` por corrida + 1 mutante + enum em pipeline.md e CONTEXT.md | `o=$(bash tests/check-adr.sh 2>&1); grep -c '^  ok    warn: one degraded adr-check row per run, before the session' <<< "$o"` → `1` | done | `e79b5fd` |
| I7 | Preflight `adr check:`, `$ADR_DIR` em `hat_expand` e `PLACEHOLDERS`, chapéus planner/kaizen, `sdd install --force` | `o=$(bash tests/check-hat.sh selftest 2>&1); grep -c '^  ok    R2: \$ADR_DIR is a placeholder the runner expands' <<< "$o"` → `1` | done | `759187b` |
| I8 | Docs: README, pipeline (receitas CI/SpecKit), schema, rule anatomia §4/§5, CONTEXT verbete, KAIZEN_LOG, TODO (`--json`) + baseline 97→98 | `o=$(bash tests/check-todo.sh 2>&1); grep -c '^  ok    98 finding(s)' <<< "$o"` → `1` | pending | — |
| I9 | Kit `ADR_CHECK=block`; carimbo do `sdd health` | `./bin/sdd why 20260917-o-numero-do-adr-nao-e-prosa PLAN` → `plan approved` | pending | — |

> **As notas de execução não moram aqui.** Elas ficam em `checkpoint-notas.md`, ao lado deste
> arquivo, append-only, e o prompt de boot inlina as últimas 10 — a sessão nunca abre aquele
> arquivo. Medido: as notas eram 69% deste arquivo, e este arquivo era 44,7% de tudo que a missão
> releu. Este aqui é a **tabela** que o runner parseia, e só ela.

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
