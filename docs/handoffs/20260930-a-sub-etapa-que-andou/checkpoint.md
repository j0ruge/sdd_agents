---
missao: 20260930-a-sub-etapa-que-andou
atualizado: 2026-10-01 01:49
---

# Checkpoint — o sub-passo da QA que andou

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
| I1 | o escritor: a linha QA carrega `step_after` (e `pending_*`) | `o=$(bash tests/check-autonomy.sh 2>&1); grep -c -e '^  ok    a QA row carries the step the session left behind' -e '^  ok    a non-QA row carries step_after as null' <<< "$o"` → `2` | done | 74996fa |
| I2 | o leitor: o braço do sub-passo na rubrica | `o=$(bash tests/check-kaizen.sh 2>&1); grep -c -e '^  ok    a QA sub-step that advanced reads advanced' -e '^  ok    the same QA row with no sub-step advance reads churned' <<< "$o"` → `2` | done | c8d156b |
| I3 | o laço QA⇄EXEC em linha nova | `o=$(bash tests/check-autonomy.sh 2>&1); grep -c -e '^  ok    a QA close that wrote fix increments is the designed loop' -e '^  ok    an EXEC row whose pending grew is still churn' <<< "$o"` → `2` | done | ec4ecf0 |
| I4 | o histórico: `step_after` recuperado pela próxima linha QA | `o=$(./bin/sdd autonomy --all-repos --by-mission 2>/dev/null); grep -c -e '20260929-aviso-diretoria-por-email  21 session(s) · 19 advanced · 2 churned · 0 idle' -e '20260930-e2e-local-diz-por-que-caiu  15 session(s) · 14 advanced · 1 churned · 0 idle' -e '20260930-justificativa-pedido-alcada  20 session(s) · 17 advanced · 3 churned · 0 idle' -e 'QA row(s) older than step_after' <<< "$o"` → `4` | done | 163cd94 |
| I5 | docs e registro (D16 4ª emenda, Churn, KAIZEN_LOG, pipeline) | `grep -l 'step_after' CONTEXT.md KAIZEN_LOG.md docs/pipeline.md agents/sdd-kaizen.md > /tmp/i5.txt; wc -l < /tmp/i5.txt` → `4` | done | 4c0e079 |
| I6 | varredura D15: cinco itens saem do backlog | `bash tests/check-todo.sh --count TODO.md` → `85` | done | 7ee1c3e |

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
