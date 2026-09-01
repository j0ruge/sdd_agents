---
missao: 20260901-o-revisor-so-acha
atualizado: 2026-09-01 23:05
---

# Checkpoint — O revisor só acha

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
| I1 | o ledger carrega `turns`, e `sdd autonomy --by-mission` imprime o laço de revisão | `bash -n bin/sdd; o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    a session row carries the turns the session spent' <<< "$o"; grep -c '^  ok    the review loop counts REVIEW and the EXEC sessions after it, never the EXEC before' <<< "$o"` → `1` e `1` | done | 88432ee |
| I2 | o contrato: o revisor só acha, achado vira incremento R — agente, executor, templates, prompt e `docs/pipeline.md` no mesmo commit | `o=$(bash tests/check-gates.sh 2>&1); grep -c '^  ok    a review graded B with a pending R1 hands the ball to EXEC' <<< "$o"; o2=$(bash tests/check-dry-run.sh 2>&1); grep -c '^  ok    the REVIEW boot prompt sends findings to R increments and never fixes in-session' <<< "$o2"; diff -q agents/sdd-reviewer.md .claude/agents/sdd-reviewer.md; echo rc=$?` → `1`, `1` e `rc=0` | done | 03187e8 |
| I3 | a guarda de aviso `REVIEW-EDITED-CODE`: sessão REVIEW que editou código fora do diretório da missão é registrada no `pipeline.log` | `o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    a REVIEW session that edited code outside the mission directory is logged REVIEW-EDITED-CODE' <<< "$o"; grep -c '^  ok    a REVIEW session that only wrote the round and the checkpoint is not flagged' <<< "$o"` → `1` e `1` | done | c8c8ec7 |
| I4 | docs: schema, failure-modes, `CONTEXT.md`, `KAIZEN_LOG.md` (antes), e `docs/graphify.md` entra na superfície do `check-lang` | `o=$(grep -l 'o-revisor-so-acha' KAIZEN_LOG.md CONTEXT.md docs/pipeline.md config/schema.md docs/failure-modes.md); wc -l <<< "$o"; s=$(sed -n '/^surface()/,/^}/p' tests/check-lang.sh); grep -c 'docs/graphify.md' <<< "$s"; bash tests/check-lang.sh >/dev/null 2>/dev/null; echo rc=$?` → `5`, `1` e `rc=0` | pending | — |

## Notas de execução

> Uma linha por evento relevante: bloqueio, decisão tomada, desvio do plano com justificativa.
> É o que a próxima sessão lê para não repetir um erro que já custou caro.

- 2026-09-01 18:30 · `PLAN` · plano nascido do grill com o humano presente (5 perguntas, 5 decisões); commit do grill já em disco (graphify + `CONTEXT.md` D22/D23). Ordem obrigatória: I1 → I2 → I3 → I4.
- 2026-09-01 · `I1` · `88432ee`. Desvio justificado do plano: o stub do bloco `== session rows ==` não podia só ganhar `"num_turns": 7` — ele saía 1 **sem escrever stream nenhum**, e `run_phase` lê o turno do mesmo `result` destilado de onde lê o custo. O stub passou a responder com a amostra capturada **menos o dinheiro e mais o turno** (derivada por `jq` do `STREAM_SAMPLE`, nunca colada — regra de proveniência), o que mantém `unknown cost is null, not a string` medindo o mundo que o nome dela diz. `7` e não o `1` da captura de propósito: `attempt` também vale 1 na primeira linha, e um escritor que carimbasse a constante passaria por coincidência.
- 2026-09-01 · `I1` · a asserção `an escalation row carries no turns` já nascia **verde** (o campo não existia em lugar nenhum) — é guarda, não Red, e o plano a pediu assim. O Red observado foram as outras duas, pelo motivo certo: `1 7 0 null` (piso do mundo armado, campo ausente) e `1 none 1 none` (a linha `rl1` imprime, sem a célula).
- 2026-09-01 · `I1` · confirmação independente no ledger real: `20260831-a-rodada-que-andou` lê `review loop US$ 66.34 (50%)`, exatamente o número que o `00-missao.md` cita para o PR #33 — o instrumento reproduz à mão o que o gemba mediu. `sdd autonomy --all-repos --by-mission` imprime 16 células.
- 2026-09-01 · `I2` · `03187e8`. Red observado nas três asserções novas, cada uma pelo motivo certo: a do dry-run reprovou por "no mention of an R<n> increment" (o prompt ainda dizia `review and fix, INSIDE`); a do template, por `missing section 'Incrementos de conserto'`; a do `check-gates.sh` foi medida numa cópia **sem** a linha `R1` do fixture (`grep -v` da linha do `printf`) — respondeu `REVIEW` em vez de `EXEC`, e no mesmo probe a guarda `fixture: the R1 row really closed` morreu alto, provando que ela não conclui sobre um fixture que não foi montado.
- 2026-09-01 · `I2` · desvio justificado do plano: o item (5) pedia também *"a linha `REVIEW` da tabela de fases (`:128` vizinhança) diz findings → R<n>"*. **Essa tabela não existe** — o que está em `docs/pipeline.md:124-128` é a tabela dos três sub-passos da QA, e não há tabela de fases com agente no arquivo. O contrato foi escrito por inteiro no `§ REVIEW` (laço, o que a sessão commita, r1 em B como rodada saudável, gate declarado inalterado) e na frase do laço em `:204`.
- 2026-09-01 · `I2` · o mutante `mut_RUN_review_fixes_inline` nasceu ancorado na **indentação** do arm (`^    REVIEW)   printf`) e foi reescrito para a faixa da função (`/^phase_task()/,/^}/`): `phase_agent` e `phase_model` têm um `REVIEW)` cada, um deles a uma tecla de distância, e um padrão de espaços que derivasse sabotaria o arm errado parecendo aplicado. Provado numa cópia da árvore inteira — `cmp` acusa diferença, `bash -n` compila, e `check-dry-run.sh` fica vermelho em **uma** asserção, a nomeada.
- 2026-09-01 · `I2` · o `tests/check-lang.sh` reprovou `agents/sdd-reviewer.md` numa linha só: a palavra `Pendências` citada como nome de seção do template. A superfície do agente é inglês, então a citação passou a ser a metade inglesa do heading ("Decisions for a Human"). As outras citações de heading PT-BR (`## Incrementos de conserto`, `O que virou incremento`) o dicionário não pega e ficaram — são contrato de template.
- 2026-09-01 · `I2` · piso do `check-templates.sh` recontado 23 → 24 no mesmo diff que acrescenta a regra (piso que fica para trás continua passando descrevendo superfície menor). Catálogo de mutação: 220 → 221, e as duas contagens (definições e `CATALOG=(`) batem.
- 2026-09-01 · `I3` · `c8c8ec7`. Red observado nas duas asserções de aviso pelo motivo certo — `sessions:1 lines:0 warns:0 phase: n: files:` e `retried:1 lines:0 files:`: o piso de cada regime (a sessão rodou; o retry realmente disparou) já estava verde e só a saída da guarda faltava. O controle negativo nasceu **verde**, como o plano pediu: é guarda contra ruído, não Red.
- 2026-09-01 · `I3` · **desvio do plano com número atrás: entrou uma quarta asserção.** O plano pediu três, e a passada de sabotagem mostrou que com elas apagar a chamada do `cmd_retry` deixava a suíte inteira verde (`door1=1 control=1 retry=1 fails=0`) — porta cuja remoção nenhuma asserção percebe, o que o `CLAUDE.md § 5` proíbe em tantas palavras. A asserção `sdd retry is another door that opens a REVIEW session, and it is guarded too` foi escrita no instante em que isso foi medido. Sabotando uma porta por vez numa cópia da árvore, cada uma das três agora derruba só a sua; derrubar o braço `"$HANDOFF_DIR/$MISSION"/*` da allowlist derruba as quatro, que é o que prova que a allowlist é medida.
- 2026-09-01 · `I3` · o `shellcheck` do `run-all.sh` reprovou SC2034 (`RS3_ERR appears unused`). Consertado **usando** a captura (o regime do retry inline passou a exigir `warns:1`) e não apagando-a: o aviso na stderr é metade do que a guarda promete, e um regime que só lê o `pipeline.log` não a mede.
- 2026-09-01 · `I3` · o termo `warns:` lê prosa que **só** existe no `warn` (`the reviewer finds and the executor fixes`), nunca o texto compartilhado com a linha do journal. Um `grep 'outside the mission directory'` responderia o mesmo número lendo o arquivo errado — a mesma classe do `^  ok    ` que este checkpoint já declara no cabeçalho.
- 2026-09-01 · `I3` · a guarda **não** ganhou early-return de `DRY_RUN`. A projeção alcança a função (a chamada fica acima do ramo `DRY_RUN` do `cmd_run`, ao lado da do irmão) e é silenciosa por construção: `run_phase` volta antes de abrir sessão, então os dois heads são o mesmo commit. Diferente do `kit_guard_arm`, nada aqui é alcançado de nenhum outro lugar durante uma projeção, logo não há aviso a herdar. O cabeçalho **declara** qual mundo não foi construído, em vez de afirmar que ele não existe — a cicatriz de `d4deb35`/`7cbc8e2`.
- 2026-09-01 · `I3` · catálogo de mutação 221 → 222 (`mut_RUN_review_scope_blind`), definições e `CATALOG=(` batendo em 222; suíte rápida 845 → 855 asserções. O carimbo segue morto até a fase DOCS.
- 2026-09-01 · `I1` · o carimbo de mutação (`.sdd/logs/mutation-stamp`) está **morto** a partir deste commit: `bin/ tests/` mudaram. Quem re-emite é a fase DOCS, depois do último commit de código (`01-plano.md § Para a fase DOCS`). Catálogo passa de 218 para 220 mutantes; a suíte rápida vai a 845 asserções.

> **Toda vez que um humano precisou entrar na linha** — um `sdd retry`, um conserto à mão, um
> `BLOCKED` assumido — sai uma linha com o marcador `intervention:`. É a **narrativa** do que o
> humano fez. O **número** de intervenções o `sdd autonomy --by-mission` lê do ledger, em
> `launch(es)` (`run_id` distintos — cada `sdd run`/`sdd retry`), e imprime estas notas ao lado
> como `intervention note(s)`. Medido em 2026-08-28: a missão de três lançamentos tinha zero
> notas — o contador não pode depender de alguém lembrar de escrever; a narrativa, sim, e é a
> única fonte que diz o que o humano *fez*.
>
> ⚠️ O marcador é **inglês e minúsculo**, como `pending`/`done`/`blocked`: é contrato, não prosa.
> O texto depois dos dois-pontos vai no idioma do `OUTPUT_LANG`, como o resto deste arquivo.
> Só conta quando abre a linha — `intervention` no meio de uma frase é prosa e não é contado.
>
> O exemplo abaixo mora **dentro** desta citação de propósito: o `>` quebra o casamento com
> `^[[:space:]]*-`, e sem ele o exemplo era contado verbatim — todo checkpoint recém-instanciado
> nascia devendo uma intervenção fantasma ao instrumento que mede autonomia. Copie a forma para
> fora da citação ao registrar uma intervenção de verdade.
>
> - intervention: <o que o humano teve de fazer> — <fase> — <custo, se houver>

## Incrementos de fix (QA)

> Escritos pelo `sdd-qa` quando um bug sanável é reprovado. Entram na mesma tabela acima com ID
> `F<n>`, e o Check obrigatoriamente inclui **regression test passa** + **re-walk da jornada
> impactada verde**. Bug que exige julgamento humano NÃO vira fix — vai para
> "Decisions for a Human" no handoff de QA.
>
> ⚠️ **Nesta missão a fase REVIEW passa a fazer o mesmo** (é o objeto do I2): achado a consertar
> entra na tabela acima com ID `R<n>`, escrito pelo `sdd-reviewer`, e o `sdd-executor` o pega como
> qualquer linha `pending` — a REVIEW desta própria missão é a primeira a rodar nesse contrato.
