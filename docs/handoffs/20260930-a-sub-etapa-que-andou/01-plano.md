---
missao: 20260930-a-sub-etapa-que-andou
data: 2026-09-30
---

# Plano — o sub-passo da QA que andou

> **Teste de autocontenção:** uma sessão nova, sem nenhuma memória da conversa que gerou este
> plano, lendo apenas `00-missao.md` + `01-plano.md` + `checkpoint.md`, consegue executar?
> Se a resposta for "só se souber X", **X vai escrito aqui**.

## Contexto verificado (não re-descobrir)

Tudo abaixo foi lido nesta sessão (2026-09-30, `main` = `6323c6f`). Número de linha envelhece:
ancore pelo nome da função.

- A rubrica é **uma** definição para os dois leitores — `ledger_outcome_defs()` (`bin/sdd:3290`),
  um `printf` de `jq` incluído por `cmd_autonomy` e por `kaizen_series`. Hoje:
  `def outcome: if .gate == "pass" then "advanced" elif (.pending_before != null and .pending_after != null and .pending_after < .pending_before and .moved != false) then "advanced" elif (.rounds_before != null and .rounds_after > .rounds_before and .moved != false) then "advanced" elif .moved == true then "churned" else "idle" end;`
  Os comentários acima dela (`bin/sdd:3085-3289`) contam a história dos dois braços e das guardas de
  não-nulo — **leia-os antes de escrever o terceiro**; a guarda `!= null` é estrutural (`null < 2` é
  verdadeiro em jq).
- O histórico do EXEC e do REVIEW se recupera em `def historic_progress` e `def historic_rounds`,
  na mesma função: `reduce` por `(repo, missão)` com memória `.seen[$k]`. O caminho recuperado é
  **contado na tela** do `sdd autonomy` (linhas `(48 EXEC row(s) older than the pending fields read
  their progress from gate_why)` e `(19 REVIEW row(s) …)`).
- A linha de sessão do ledger é escrita por `autonomy_session_row()` (`bin/sdd:4039`), com o campo
  `step` vindo de `LAST_PHASE_STEP` (publicado por `run_phase`, `bin/sdd:4437`). Chamadores:
  `cmd_run` primeira passada (`bin/sdd:7839`), retry inline (`bin/sdd:7970`), `cmd_retry`
  (`bin/sdd:8175`) e as duas do `cmd_kaizen` (`:9886`, `:9907`). A primeira passada captura os
  pares EXEC/REVIEW em locais **com guarda de fase** (`if [ "$phase" = "EXEC" ]`) — o comentário em
  `bin/sdd:7825-7837` explica por quê; a QA nova segue a mesma forma.
- `qa_substep()` (`bin/sdd:2228`) devolve `plan`, `exec` ou `close`; `phase_step QA` devolve
  `QA:<sub-passo>`. Não seta global nenhum, então `$(phase_step QA)` depois do gate é seguro.
- `gate_QA()` (`bin/sdd:1295`) reprova na primeira linha com `missing 30-handoff-qa.md` (`:1299`) —
  por isso o `gate_why` **não** distingue um `QA:exec` que fechou o relatório de um que não fechou.
- Ledger real (`~/.sdd/autonomy-log.jsonl`): `step` existe em toda linha QA desde 2026-08-16;
  `jq -r 'select(.phase=="QA" and .event=="session") | .step' | sort | uniq -c` → `59 QA:close`,
  `3 QA:exec`, nenhum `QA:plan`. Os três `QA:exec` são das três missões da janela 2, todos
  `gate: fail`, `moved: true`, e a próxima linha QA de cada missão tem `step: "QA:close"`.
- `sdd autonomy --all-repos --by-mission` hoje imprime, entre outras:
  `sales_quote/20260929-aviso-diretoria-por-email  21 session(s) · 18 advanced · 3 churned · 0 idle · 3 launch(es) …`,
  `sales_quote/20260930-justificativa-pedido-alcada  20 session(s) · 16 advanced · 4 churned · 0 idle …`,
  `sales_quote/20260930-e2e-local-diz-por-que-caiu  15 session(s) · 13 advanced · 2 churned · 0 idle …`.
- O rótulo (`def phase_label`, `bin/sdd:9302`) lê `outcome`, então o braço novo também move `leve`
  → `ok` onde a única sessão não-`advanced` de uma fase QA era o `QA:exec`.
- `.sdd/config.sh`: `JIRA_ENABLED=false`, `ADR_CHECK="warn"`, `OUTPUT_LANG="pt-BR"`.
- A catraca do backlog está em `tests/health-baseline.txt` (`todo-findings 90` depois do commit do
  veredito); a contagem sai de `bash tests/check-todo.sh --count TODO.md`.
- Precedentes de forma (copie o estilo, não o texto): `docs/handoffs/20260829-o-incremento-que-andou/`
  e `docs/handoffs/20260831-a-rodada-que-andou/`.

## Arquitetura da mudança

```
run_phase (QA:exec) ──► gate_QA ──► $(phase_step QA) = step_after ──► autonomy_session_row
                                                                         │ step, step_after
ledger_outcome_defs: outcome ganha o braço do sub-passo  ◄───────────────┘
                     historic_steps (novo) preenche step_after de linha antiga pelo step da próxima
```

Um campo novo (`step_after`) só em linha QA (null nas outras fases, como os pares EXEC/REVIEW), um
braço novo na rubrica, um `def` novo de recuperação, uma linha nova de contagem na tela. Os dois
leitores herdam tudo porque incluem a mesma função.

## Incrementos

### I1 — o escritor: a linha QA carrega `step_after`

**O quê:** depois do `gate_QA`, nos chamadores do `autonomy_session_row` que gravam fase QA, derivar
`$(phase_step QA)` e passá-lo como campo `step_after`; null em toda fase que não é QA (guarda de
fase, como `exec_after`/`review_after`). Também o `pending_before`/`pending_after` na linha QA
(foto antes do `run_phase`, contagem depois), para o I3.
**Onde:** `bin/sdd` (`autonomy_session_row`, os três chamadores do `cmd_run`/`cmd_retry`);
`docs/pipeline.md` § *Field reference* no mesmo commit (contrato de artefato).
**Como (TDD):** asserção nova em `tests/check-autonomy.sh` — `a QA row carries the step the session
left behind` — num fixture em que a sessão stub fecha o relatório; vermelha antes (campo ausente).
Mais `a non-QA row carries step_after as null`.
**Check:** ver `checkpoint.md`.
**Sensor durável:** as duas asserções + um mutante `mut_RUN_qa_step_after_missing` no catálogo.
**Reversível por:** `git revert` do commit; o campo é aditivo, leitor antigo o ignora.

### I2 — o leitor: o braço do sub-passo

**O quê:** `def step_rank` (`plan`=0, `exec`=1, `close`=2, desconhecido = null) e o braço
`elif (.step_after != null and (.step_after | step_rank) != null and (.step | step_rank) != null and (.step_after | step_rank) > (.step | step_rank) and .moved != false) then "advanced"`,
**antes** do braço `.moved == true`. Escrito positivamente: sub-passo desconhecido não conta.
Comentário no estilo dos braços vizinhos, com a medida desta missão (7 de 9 `churned` na QA).
**Onde:** `bin/sdd` (`ledger_outcome_defs`); `agents/sdd-kaizen.md` (parágrafo do `advanced`) no
mesmo commit.
**Como (TDD):** em `tests/check-kaizen.sh`, um par **diferencial** — `a QA sub-step that advanced
reads advanced` e `the same QA row with no sub-step advance reads churned` (a mesma linha QA, com
`step_after` posterior e com `step_after` igual).
**Check:** ver `checkpoint.md`.
**Sensor durável:** o par diferencial + `mut_KAIZEN_qa_step_arm_blind` (braço apagado) e
`mut_KAIZEN_qa_step_rank_inverted` (`>` virando `>=`).
**Reversível por:** revert; a régua volta à de 2026-08-31.

### I3 — o laço QA⇄EXEC em linha nova

**O quê:** braço `elif (.phase == "QA" and .pending_before != null and .pending_after != null and .pending_after > .pending_before and .moved != false) then "advanced"` — o `close` que escreveu `F<n>`.
Escopado à fase por construção: no EXEC, `pending` subindo seria o oposto de progresso.
**Onde:** `bin/sdd` (`ledger_outcome_defs`).
**Como (TDD):** fixture em que a sessão QA stub acrescenta uma linha `F1 … pending`; asserção
`a QA close that wrote fix increments is the designed loop`, vermelha antes; e a diferencial
`an EXEC row whose pending grew is still churn` (a mesma linha com `phase: "EXEC"`).
**Check:** ver `checkpoint.md`.
**Sensor durável:** as asserções + `mut_KAIZEN_qa_fix_loop_unscoped` (tirar o `.phase == "QA"`).
**Reversível por:** revert do commit deste incremento, independente do I2.

### I4 — o histórico: `step_after` recuperado pela próxima linha

**O quê:** `def historic_steps`: para linha QA de sessão **sem** `step_after`, preencher com o `step`
da **próxima** linha QA de sessão da mesma `(repo, missão)` e marcar `steps_source: "next_row"`;
última linha da missão fica sem. Encadeado onde os outros dois `historic_*` são aplicados nos dois
leitores. Linha de tela nova no `sdd autonomy`: `(<N> QA row(s) older than step_after read their
sub-step from the next row)`.
**Onde:** `bin/sdd` (`ledger_outcome_defs` e os dois sítios que aplicam `historic_progress`).
**Como (TDD):** fixture histórico com `QA:exec` → `QA:close` (avança), `QA:exec` → `QA:exec`
(não avança) e duas missões de mesmo slug em repos diferentes (a chave tem `repo` — é a classe do
item aberto sobre a metade `repo` da chave do EXEC; aqui ela nasce com probe).
**Check:** ver `checkpoint.md` — inclui a métrica sobre o ledger real.
**Sensor durável:** as asserções + `mut_KAIZEN_historic_steps_key_slug_only`.
**Jidoka:** antes de commitar, salvar `sdd autonomy --all-repos --by-mission` de antes e de depois e
`diff`; se mudar alguma linha além das três missões da métrica, **pare** (`blocked`) e escreva o
diff no checkpoint-notas — é o braço lendo mais do que devia.
**Reversível por:** revert.

### I5 — docs e registro

**O quê:** `CONTEXT.md` D16, **quarta emenda** (o braço do sub-passo, com o número medido no I4);
verbete *Churn* atualizado; `KAIZEN_LOG.md` com o antes/depois das três missões; `docs/pipeline.md`
§ *The kaizen loop* onde diz o que `advanced` significa. O `docs/failure-modes.md` se citar a régua.
**Onde:** os arquivos acima.
**Como (TDD):** o Check grepa a frase âncora nova em cada arquivo.
**Sensor durável:** `check-lang.sh` cobre `docs/pipeline.md` e `agents/` (inglês); `CONTEXT.md` e
`KAIZEN_LOG.md` são pt-BR por `OUTPUT_LANG`.
**Reversível por:** revert.

### I6 — varredura D15: cinco itens saem do backlog

**O quê:** pela régua de admissão, quatro itens abertos do `TODO.md` não são fail-open nem têm
consumidor fora da suíte, e um quinto foi resolvido fora do kit; cada um sai para o lugar nomeado
abaixo, e a catraca desce 90 → 85 no
mesmo commit.
**Onde / Check:** ver a seção seguinte e `checkpoint.md`.
**Reversível por:** revert.

## Itens que saem do backlog pela régua D15 (destino de cada um)

| Item do `TODO.md` (título) | Por que não é achado | Vai para |
|---|---|---|
| **O `stub-argv.txt` do `check-health.sh` nunca é apagado entre mundos de fixture** | o próprio item mede "hoje não reproduz fail-open"; o consumidor é só a suíte | cabeçalho de `tests/check-health.sh`, limites declarados |
| **Dois resíduos de sensor que precisam de DUAS edições, e nenhum tem testemunha externa** | o item diz que estão declarados nos cabeçalhos: dívida honesta, não fail-open | já está em `tests/check-todo.sh` e `tests/check-templates.sh` — confira o cabeçalho e apague o item |
| **`check-autonomy.sh` é vermelho intermitente, causa desconhecida** | causa refutada, 152 runs sem reproduzir; sem consumidor fora da suíte | cabeçalho de `tests/check-autonomy.sh` ("observado uma vez, não reproduzido em 152 runs; medir antes de consertar") |
| **O laço de melhoria da sessão interativa não enxerga o kit** | resolvido fora do kit, sem commit deste repo que o feche: o `retrofit-watch` 0.2.0 (`j0ruge/skills`, `960e47b`, 2026-10-01) reconhece `/sdd-*`, subagente `sdd-*` e o CLI `sdd`, e manda a lição para este `TODO.md` | uma linha em `<!-- sdd:decided -->` ("resolvido fora do kit: retrofit-watch 0.2.0, `j0ruge/skills@960e47b`"), e o item sai da seção aberta — incluído pelo humano na aprovação |
| **`sdd adr check` só fala texto + rc; não existe `--json`** | sem consumidor, e o próprio item diz "quando houver consumidor" | `CONTEXT.md`, tabela *Decisões adiadas por YAGNI*, linha Y4 com o evento que reabre |

## Resolvidos a apagar

Nenhum: `grep -n 'RESOLVED by' TODO.md` responde só a linha da seção decidida (a regra do ciclo de
vida), nenhuma na seção aberta.

## Riscos e não-feitos

| Risco | Probabilidade | Mitigação |
|---|---|---|
| A foto de `pending` antes da QA exigir mover a captura do `exec_before` (hoje só EXEC) e tocar a guarda de fase dos três chamadores | média | o I3 é independente: se a foto pedir decisão, marque o I3 `blocked` com a razão e siga para o I4 |
| A linha de tela nova quebrar asserções que contam as linhas de rodapé do `sdd autonomy` | média | rodar `check-autonomy.sh` inteiro no I4; ajustar as asserções de rodapé no mesmo commit |
| O braço do sub-passo lisonjear: `QA:exec` que avançou mas cujo relatório o gate depois recusa | baixa | o avanço é do **sub-passo** (o relatório fechou); a recusa seguinte é do `close`, lida na linha dele |
| Números de janelas anteriores mudarem sob o leitor novo | certa | é o objetivo; declarar no `KAIZEN_LOG.md` e no veredito seguinte que a régua mudou em 2026-09-30 |
| Não verificado nesta sessão: se `cmd_retry` grava QA com `step` correto | média | o I1 cobre o `cmd_retry` com a mesma asserção |
| O esperado `85` do I6 supõe que nenhum achado novo entre no `TODO.md` durante a missão | média | quem registrar achado move a baseline e corrige o esperado do Check do I6 no mesmo commit, dizendo o porquê na nota |

## Verificação end-to-end

Com os seis incrementos `done`:

```bash
o=$(./bin/sdd autonomy --all-repos --by-mission 2>/dev/null)
grep -c '20260929-aviso-diretoria-por-email  21 session(s) · 19 advanced · 2 churned · 0 idle' <<< "$o"   # → 1
grep -c '20260930-e2e-local-diz-por-que-caiu  15 session(s) · 14 advanced · 1 churned · 0 idle' <<< "$o"  # → 1
grep -c '20260930-justificativa-pedido-alcada  20 session(s) · 17 advanced · 3 churned · 0 idle' <<< "$o" # → 1
grep -c 'QA row(s) older than step_after' <<< "$o"                                                        # → 1
bash tests/run-all.sh                                                                                      # → verde
bash tests/check-mutation.sh --anchors                                                                     # → verde
```
