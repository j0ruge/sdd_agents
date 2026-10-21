---
missao: 20261020-a-sessao-le-o-que-o-boot-manda
atualizado: 2026-10-21 19:35
---

# Checkpoint — a sessão lê o que o boot manda ler

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
> `` o=$(cmd 2>&1); grep -c 'x' <<< "$o" ``, e o `tests/check-checkpoint.sh --check <checkpoint>` do
> kit recusa as duas formas em qualquer checkpoint.
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
> O sensor é o `tests/check-checkpoint.sh --check <este checkpoint>` do kit (pelo caminho do kit).
>
> ⚠️ **Ato fora do git deixa um commit de registro.** O `gate_EXEC` lê 7 a 64 dígitos hex na
> célula Commit e nada mais. Quando o produto do incremento não é código — e-mail enviado, página da
> KB publicada, config no IdP, issue adotada —, o executor grava a evidência num arquivo da pasta da
> missão (`record-<ID>.md`: o que foi feito, a URL ou o ID que o prova, a data) e commita esse
> arquivo; o hash dele vai na célula. Palavra na célula é rótulo, e o gate a recusa.
>
> ⚠️ **Passo depois do merge ou numa janela externa não é incremento.** O merge do humano, um
> yokoten nos repos-alvo, um smoke que exige a mesa livre: na tabela, cada um vira um `pending` que
> nunca fecha ou um `blocked` que para a linha inteira.
> O passo vai para `## Pendências para o humano` do `00-missao.md`, ou para a missão seguinte.
>
> Atualizar o checkpoint é o **último ato** de cada incremento — depois do commit, nunca antes.
> Status válidos: `pending` · `doing` · `done` · `blocked`.

| ID | Incremento | Check (comando → esperado) | Status | Commit |
|---|---|---|---|---|
| I1 | Uma definição da regra de leitura dos templates, e toda fase a recebe | `o=$(bash tests/check-dry-run.sh 2>&1); grep -c '^  ok    every phase may read the kit templates, and only read them' <<< "$o"` → `1` | done | 7098b92 |
| I2 | O sdd close recebe a mesma regra | `o=$(bash tests/check-gates.sh 2>&1); grep -c '^  ok    close: the session may read the kit templates, and only read them' <<< "$o"` → `1` | done | 7e2353d |
| I3 | O preflight prova a regra do kit numa sessão isolada, e reprova quando ela não lê | `o=$(bash tests/check-preflight.sh 2>&1); a=$(grep -c '^  ok    preflight fails when the kit rule alone cannot read the templates' <<< "$o"); b=$(grep -c '^  ok    the template probe runs with no settings and carries the kit rule' <<< "$o"); echo "$a $b"` → `1 1` | done | 1608dae |
| I4 | Toda negativa do harness é nomeada no journal | `o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    every tool call the harness denied is named in the journal' <<< "$o"` → `1` | done | 42fbdb4 |
| I5 | READ_EXTRA: o projeto declara os diretórios das skills, só para leitura | `o=$(bash tests/check-dry-run.sh 2>&1); p=$(bash tests/check-gates.sh 2>&1); a=$(grep -c '^  ok    READ_EXTRA reaches every phase as a read-only rule, symlink resolved' <<< "$o"); b=$(grep -c '^  ok    READ_EXTRA that is not a literal absolute directory is refused, and the reason names it' <<< "$p"); echo "$a $b"` → `1 1` | done | 52f9fdf |
| I6 | O preflight avisa o que as fases não vão conseguir ler: a entrada que não existe e a skill que ninguém declarou | `o=$(bash tests/check-preflight.sh 2>&1); a=$(grep -c '^  ok    preflight warns about a READ_EXTRA directory that does not exist, and only about it' <<< "$o"); b=$(grep -c '^  ok    preflight names a skill it finds that READ_EXTRA does not declare, with the entry to add' <<< "$o"); echo "$a $b"` → `1 1` | done | e8fe91c |
| R1 | revisão final #1 — o aviso do preflight manda declarar a entrada já declarada quando só o alvo do symlink dela reprova na gramática | `o=$(bash tests/check-preflight.sh 2>&1); grep -c '^  ok    a declared skill whose symlink target the grammar refuses is named as such, never as undeclared' <<< "$o"` → `1` | done | f9f3b34 |
| R2 | revisão final lote #2 e #8 — o aviso da skill achada no cache de plugins nomeia o installed_plugins.json (o cache pode ter mais de uma cópia), e o comentário da sonda do Bash deixa de dizer que ela leva as flags inteiras do run_phase | `o=$(bash tests/check-preflight.sh 2>&1); a=$(grep -c '^  ok    a skill found in the plugin cache is warned with installed_plugins.json named, since the cache may hold more than one copy' <<< "$o"); b=$(grep -c 'minus the read rules (ADR 0019 §3)' bin/sdd); c=$(grep -c '^  ok    the copy installed_plugins.json records is the one held to the rules, and an unreadable registry falls back to the cache' <<< "$o"); echo "$a $b $c"` → `1 1 1` | done | 5f05cf4 |
| R3 | Codex P3 do #315 — a sonda isolada do preflight leva só as linhas do kit_read_rules no --allowedTools, nunca o ALLOWED_TOOLS base, que com um Read largo a deixava verde sobre uma regra vazia ou quebrada | `o=$(bash tests/check-preflight.sh 2>&1); grep -c '^  ok    the template probe carries only the kit read rules, never ALLOWED_TOOLS' <<< "$o"` → `1` | done | b96afd8 |
| R4 | Codex P2 da r2 do #315 — a sonda dos templates que sai sem init e sem result falha nomeada, em vez de calar e deixar o preflight verde sem medir a regra; a CLI morta continua sendo uma falha só, a da sonda do Bash | `o=$(bash tests/check-preflight.sh 2>&1); grep -c '^  ok    a template probe that emits no init and no result fails by name, and a dead CLI fails once' <<< "$o"` → `1` | done | 8c72cfb |
| R5 | Codex r3 do #315, lote #1 e #2 — o registro de plugins só conta a chave do próprio plugin da skill (como o health_provenance), e um caminho do kit que a gramática das regras recusa não ganha regra dos templates, com o preflight nomeando o caminho | `o=$(bash tests/check-preflight.sh 2>&1); a=$(grep -c '^  ok    a plugin skill is looked up in the registry only under its own plugin key, never another plugin' <<< "$o"); b=$(grep -c '^  ok    a kit path the read-rule grammar refuses gets no template rule, and preflight names it' <<< "$o"); echo "$a $b"` → `1 1` | done | 4426c94 |
| R6 | Codex P2 da r4 do #315 — o veredito da sonda dos templates dá nome uma vez ao desfecho do Read do template (negado, lido, deu erro, não tentou, sem sessão) e despacha por ele, com default que reprova; o Read que volta com erro e sem entrada em permission_denials reprova nomeado, em vez de cair no aviso de que a sessão não tentou ler | `o=$(bash tests/check-preflight.sh 2>&1); grep -c '^  ok    the template probe names the outcome of its Read once, and a Read that comes back with an error fails by name' <<< "$o"` → `1` | done | df5bdb6 |
| R7 | Codex P3 da r5 do #315 — a sonda dos templates leva no --allowedTools só as regras dos templates (a regra e a do alvo resolvido), de uma definição própria que o kit_read_rules compõe com as do READ_EXTRA; uma entrada do READ_EXTRA que cubra o kit, como $HOME, deixa de ler o template no lugar da regra que a sonda nomeia | `o=$(bash tests/check-preflight.sh 2>&1); grep -c '^  ok    the template probe carries the templates rule alone, never a READ_EXTRA rule that covers the kit' <<< "$o"` → `1` | done | 0b8c140 |
| R8 | CodeRabbit no #315, lote dos baratos — a lista de regras vazia chega ao claude por uma expansão que o set -u aceita no bash 4.0 a 4.3 (run_phase e sdd close); o Check do R2 lê também a asserção do registro; a entrada decidida da sonda do Bash deixa de dizer refutado; a anatomia nomeia o mutante do R3; o handoff qualifica a regra dos templates e o aviso do R1 | `o=$(bash tests/check-dry-run.sh 2>&1); a=$(grep -c '^  ok    every read-rule array reaches claude through an expansion that set -u accepts on bash 4.0 too' <<< "$o"); b=$(grep -cE '^. R2 .*installed_plugins\.json records' docs/handoffs/20261020-a-sessao-le-o-que-o-boot-manda/checkpoint.md); c=$(grep -c 'refutado: .bin/sdd:[0-9]*. manda rodar .bash -c' TODO.md); d=$(grep -c 'mut_PRE_template_probe_empty_unguarded' .claude/rules/anatomia-do-agente.md); echo "$a $b $c $d"` → `1 1 0 1` | done | 6b70968 |
| R9 | Codex r7 do #315, lote #1 e #2 — o preflight procura cada skill pela forma como a fase a chama (codereview:codereview na REVIEW; ticket, qa-report e qa-execution simples): com plugin, o registro na chave do plugin vem antes de qualquer diretório simples, e uma instalação registrada sem a skill é avisada como quebrada, nunca trocada por uma cópia do cache | `o=$(bash tests/check-preflight.sh 2>&1); a=$(grep -c '^  ok    a skill the phase invokes as plugin:skill is looked up in the plugin registry before any plain skills directory' <<< "$o"); b=$(grep -c '^  ok    a recorded plugin install that lacks the skill is warned as broken, never replaced by a cache copy' <<< "$o"); echo "$a $b"` → `1 1` | done | 8f94a3a |

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
