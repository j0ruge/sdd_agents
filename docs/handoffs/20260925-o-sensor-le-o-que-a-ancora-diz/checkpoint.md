---
missao: 20260925-o-sensor-le-o-que-a-ancora-diz
atualizado: 2026-09-25 01:10
---

# Checkpoint — o sensor lê o que a âncora diz

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
| I1 | regra 5 recusa linha física acima de 120 caracteres (não bytes) | `o=$(bash tests/check-todo.sh 2>&1); grep -c '^  ok    rule: a physical line of the open section holds at most 120 characters' <<< "$o"` → `1` | done | 7bf0773 |
| I2 | selftest vermelho em toda sabotagem do #70 (a, c, d, b1, b2; b4/b5 declarados) | `o=$(bash tests/check-todo.sh 2>&1); grep -c '^  ok    rule: the selftest goes red under every sabotage issue 70 listed' <<< "$o"` → `1` | done | b517d10 |
| I3 | config_read_key nos sete sítios: config que não parseia é dito (#116) | `o=$(bash tests/check-health.sh 2>&1); grep -c '^  ok    a kit config that does not parse is reported as not parsing, never as a missing TEST_CMD' <<< "$o"` → `1` | done | 932a1ba |
| I4 | predicado único recusa --list com TAB ou entre aspas (#118) | `o=$(bash tests/check-preflight.sh 2>&1); grep -c '^  ok    a TAB or a quoted --list is refused like a spaced one' <<< "$o"` → `1` | done | 2b5f492 |
| I5 | preflight greenfield: runner sem manifesto na raiz vira warn, só nesse caso (#53) | `o=$(bash tests/check-preflight.sh 2>&1); grep -c '^  ok    a runner without its manifest at the root is a warn, not a fail' <<< "$o"` → `1` | done | bc624f9 |
| I6 | check-templates imprime ok de 4 espaços por pass(); calibrate() cobre 9 sensores (#151) | `o=$(bash tests/check-checkpoint.sh 2>&1); grep -c '^  ok    the ok anchor is the prefix the suite.s sensors actually print (9 sensor(s))' <<< "$o"` → `1` | done | eb0ee9e |
| I7 | regra da âncora (símbolo a até 10 linhas, repo do arquivo checado) no modo --anchors, com selftest | `o=$(bash tests/check-todo.sh 2>&1); grep -c '^  ok    rule: an anchor names a file of the checked repo and sits within 10 lines of a symbol the item cites' <<< "$o"` → `1` | done | fb6fb78 |
| I8 | re-ancorar os itens do TODO.md que apontam o bin/sdd (conteúdo velho junto) | `o=$(bash tests/check-todo.sh --anchors TODO.md bin/sdd 2>&1); grep -c '^  ok    anchors: [1-9][0-9]* measured, 0 off target' <<< "$o"` → `1` | done | 19806c5 |
| I9 | re-ancorar o resto e reescrever os itens velhos (91, 229, 494, 515, 524 e outros) | `o=$(bash tests/check-todo.sh --anchors TODO.md 2>&1); grep -c '^  ok    anchors: [1-9][0-9]* measured, 0 off target' <<< "$o"` → `1` | done | 6904942 |
| I10 | regra da âncora no lint padrão e no --check; formato do item em templates/todo*.md; stub do check-health | `o=$(bash tests/check-todo.sh 2>&1); grep -c '^  ok    [0-9]* finding(s), all within 8 lines, carrying anchor + date, every anchor on target' <<< "$o"` → `1` | done | a8a65db |
| I11 | RESOLVED by nos 7 itens, fusão do :665 no :523, achado do stub do adr, catraca, KAIZEN_LOG | `b=$(grep -o '^todo-findings [0-9]*' tests/health-baseline.txt); c=$(bash tests/check-todo.sh --count TODO.md); grep -c "^todo-findings $c\$" <<< "$b"; grep -c 'RESOLVED by [0-9a-f]\{7,\}' TODO.md` → `1` e `7` | pending | — |

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
