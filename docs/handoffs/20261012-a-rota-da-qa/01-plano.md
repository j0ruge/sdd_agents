---
missao: 20261012-a-rota-da-qa
data: 2026-10-12
---

# Plano — a rota da QA

> **Teste de autocontenção:** uma sessão nova, sem nenhuma memória da conversa que gerou este
> plano, lendo apenas `00-missao.md` + `01-plano.md` + `checkpoint.md`, consegue executar?
> Se a resposta for "só se souber X", **X vai escrito aqui**.
>
> ⚠️ Missão do **kit**: executa-se de forma **interativa num worktree ligado** (ADR 0016 §2), nunca
> por `sdd run` a partir do checkout principal, para onde o `sdd` do PATH resolve e que os `sdd run`
> dos alvos executam. Dentro do worktree, `health`, `preflight` e `install` rodam por `./bin/sdd`.

## Contexto verificado (não re-descobrir)

Tudo abaixo foi lido nesta sessão, sobre `4f16a6d` (a `main` do kit em 2026-10-12).

**O roteamento da QA (`bin/sdd`)**

- `qa_substep` — `bin/sdd:2672-2683`. Sem interface (`E2E_CMD` e `APP_URL` vazios) devolve `close`
  (`:2678`); sem charter, `plan` (`:2679`); sem relatório **da missão** fechado, `exec` (`:2681`);
  senão `close` (`:2682`). Nada nele lê o `00-missao.md` nem o checkpoint.
- `report_closed` — `bin/sdd:2666`; `mission_qa_report` — `bin/sdd:1067` (o relatório **mais novo**
  que a branch da missão adicionou, por `sort -V`; cabeçalho em `:1011-1066`).
- `gate_QA` — `bin/sdd:1598`. `status: skipped` passa em `:1606` **antes** de qualquer âncora, com ou
  sem interface; `blocked` arma `GATE_HANDOFF_BLOCKED` em `:1612-1615`; Âncora 1 em `:1647`; Âncora 3
  (bug `agent` aberto barra) a partir de `:1676`, laço em `:1733`. **Nada no gate muda nesta missão.**
- `phase_slash` — `bin/sdd:2923` (`QA:exec` → `/qa-execution $QA_DOCS_PATH`); `phase_task` —
  `bin/sdd:2931`, texto do `QA:exec` em `:2935`.
- ⚠️ O comentário de `:2651-2654` e o de `:2915-2917` dizem que `qa-report`/`qa-execution` carregam
  `disable-model-invocation`. As duas skills instaladas declaram hoje
  `disable-model-invocation: false` (`grep -m1 disable-model-invocation ~/.claude/skills/qa-*/SKILL.md`).
  É por isso que a sessão `sdd-qa` conseguiu chamar a `qa-execution` pela ferramenta `Skill`.
- `step_rank` — `bin/sdd:3851`: `QA:plan` 0 < `QA:exec` 1 < `QA:close` 2. Reteste por `exec` mantém os
  braços do `outcome`: a sessão de reteste vai `exec → close` (`advanced`), e o `close` que escreveu
  `F<n>` já é `advanced` pelo braço `pending_after > pending_before`.
- ⚠️ `bin/sdd:8955-8956`: `step_after="$(phase_step QA)"` é seguro **só** porque o `qa_substep` não
  atribui global (o comentário diz isso). O código novo lê arquivo e git, e **não pode** passar a
  publicar global — a substituição de comando jogaria a atribuição fora (`CLAUDE.md`, família do
  subshell).
- `no_work_check` — `bin/sdd:9182`: forma (a), o mesmo **passo** com o mesmo motivo em duas voltas,
  para a linha como `no-work` antes da sessão. É o freio de um reteste que não produz relatório novo.
- `frontmatter` — `bin/sdd:337`; `checkpoint_rows` — `bin/sdd:569`; `MISSION_DIR` é o que o
  `gate_QA` já usa (`:1601`). `plan_approves_itself` — `:1146`.

**Os sensores**

- `tests/check-dry-run.sh:479-538` — o bloco "QA sub-step derived from the artifacts". Forma do
  fixture: `sed -i 's|^E2E_CMD=""|E2E_CMD="true"|' .sdd/config.sh`, charter em
  `docs/qa/charters/`, relatório em `docs/qa/reports/` com
  `- **Started:** … · **Status:** closed <!-- in-progress | closed -->`, e a projeção lida por
  `projected` (imprime `QA:<passo>=<chapéu>`). O bloco da posse do relatório (`:522-538`) mostra
  como cortar uma branch de missão com commit dentro do fixture e voltar. Medido nesta sessão: o
  sensor sozinho roda em ~5 s, **72** linhas `ok`, rc 0.
- `tests/check-mutation.sh:797` — `mut_QA_substep_report_not_mission_bound`, o molde dos mutantes
  novos do `qa_substep`.
- `tests/check-checkpoint.sh --check` e `--red` sobre o `checkpoint.md` desta pasta, rodados nesta
  sessão: `7 row(s), 2 under the anchor rule, none blind` (rc 0) e
  `7 pending Check(s), every one red at HEAD` (rc 0).

**Os contratos de prosa**

- `agents/sdd-qa.md` § 2 (`:53-63`) promete `status: skipped` para diff que não chega ao usuário;
  § 3 (`:65-79`) manda ver o spec novo falhar com o bug presente e não diz nada sobre o bug que
  nenhum agente fecha; § 4 (`:81-103`) diz que o laço "repeats until no agent-closable bug is left
  `open`" (`:98`); a regra inegociável (`:232-234`) tira o `Status:` do chapéu.
- `templates/missao.md` — frontmatter sem chave de QA. `templates/todo.pt-BR.md:32-36` e
  `templates/todo.md:32-36` (§ Ciclo de vida / Lifecycle) mandam o corpo ganhar `RESOLVED by <hash>` e
  não dizem onde no item que já está no teto de 8 linhas (`tests/check-todo.sh`, cap 8, e o
  `WIDTH_CAP=120` de `:211`).
- `KIT_BEHAVIOR_PATHS` = `bin agents templates config`: esta missão cunha uma versão de
  comportamento nova, o que é esperado — ela muda o que uma fase de alvo executa.

**O que a janela mediu (veredito ao lado, `05-verdict.md`)**

- 3 linhas `manual` de QA no ledger (`sdd note-manual`), uma por missão sem QA, e o `pipeline.log`
  delas com o ritual de dois lançamentos (TICKET; depois EXEC → PR). Os três `30-handoff-qa.md` têm
  `sessao: manual` e `status: skipped por decisão do humano no grill`.
- A improvisação do reteste: `30-handoff-qa.md` da `20261005-mascaras-ncm-e-painel` (r2, r3, r4) e da
  `20261009-o-que-some-calado` (commit do alvo `254475a4`, relatório `…-sq156-substituida-por-r2.md`).
  Pelo `sort -V`, o nome `…-por-r2.md` vem **depois** de `…-por.md`, então o `mission_qa_report` o
  escolhe como o mais novo.
- O idioma do spec de bug `human`: `test.fail()` chamado depois das pré-condições
  (`20261011-detalhe-e-lista-dizem-a-verdade`, `30-handoff-qa.md`, achados fora de escopo).
- O `RESOLVED by` no fim da linha `Fonte:` passa no `check-todo.sh --check --baseline HEAD` do alvo
  e é lido pelo `todo_issues.py` (`RESOLVED_RE`, `search`); numa linha própria, um item de 8 linhas
  vira `line 8: 9 content lines, cap is 8` (`20261011-a-catraca-ganha-folga`, `20-handoff-exec.md`).

## Arquitetura da mudança

Um ponto de decisão, o `qa_substep`, ganha duas perguntas — e o resto do pipeline já sabe
responder ao que elas devolvem:

```
qa_substep (com interface)
  ├─ o 00-missao.md declara `qa: skipped`?          ──sim──▶ close   (I2: sdd-qa confere e escreve skipped, ou blocked)
  ├─ sem charter                                    ────────▶ plan
  ├─ sem relatório da missão fechado                ────────▶ exec
  ├─ F<n> done depois do último commit do relatório ────────▶ exec    (I4: a qa-execution reanda e move o Status:)
  └─ senão                                          ────────▶ close
```

- **Nenhum gate muda.** O `gate_QA` já aceita `skipped` com interface (`:1606`) e já barra bug
  `agent` aberto (Âncora 3). O que faltava era a rota até a sessão que escreve cada artefato — a
  metade do princípio 1 que pergunta *quem pode escrever o que o gate exige*.
- **Posição das perguntas.** A do `skipped` vem antes do charter (um projeto pode não ter charter
  nenhum e mesmo assim pular a QA) e depois do ramo sem interface (lá a resposta já é `close`). A do
  reteste vem depois do `report_closed`, porque só faz sentido sobre um relatório fechado.
- **A condição do reteste é posição no git, nunca data:** `c_rep` = `git -C "$REPO_ROOT" log -1
  --format=%H -- "$report"`; reteste quando alguma linha `F<n>` com status `done` tem commit `c` tal
  que `c != c_rep` e `git merge-base --is-ancestor "$c_rep" "$c"`. Relatório sem commit (não
  rastreado), commit de `F` que não resolve, ou nenhuma linha `F` → a resposta de hoje (`close`).
- **A chave é literal e positiva:** `[ "$(frontmatter "$MISSION_DIR/00-missao.md" qa)" = skipped ]`.
  Qualquer outro valor — vazio, o placeholder do template, `Skipped`, `skipped # …` — é a rota de
  hoje. Frouxidão aqui pularia QA de verdade: falha aberta.
- **Trade-off arquitetural ⇒ ADR (I1).** Mudar quem decide o `skipped` (de uma sessão depois do diff
  para o plano aprovado, conferido por uma sessão) e dar ao runner uma rota que hoje é improviso são
  decisões com alternativas recusadas. O `00-missao.md` § Decisões lista as alternativas com o custo
  de cada uma; o humano escolhe, a ADR registra, e os incrementos seguintes seguem a escolha.

## Incrementos

A tabela executável vive em `checkpoint.md` (é ela que o runner lê). Aqui fica o **porquê** de
cada fatia — o detalhe que não cabe numa célula.

### I1 — alocar a ADR da rota da QA

**O quê:** com o humano na sala, `./bin/sdd adr new --slug the-qa-route --spec
docs/handoffs/20261012-a-rota-da-qa/00-missao.md`; o humano escolhe entre as alternativas das
decisões 1 e 2 do `00-missao.md` e escreve a ADR (em inglês: `docs/adr/` é superfície do kit, D9).
O `sdd adr new` reescreve o `adr:` deste `00-missao.md` com o caminho.
**Onde:** `docs/adr/00NN-the-qa-route.md`, `00-missao.md` (campo `adr:`).
**Como (TDD):** o Check abaixo é vermelho hoje (0 arquivos); `./bin/sdd adr check` com rc 0 depois.
**Check:** `o=$(ls docs/adr); grep -c -e 'the-qa-route' <<< "$o"` → `1`
**Sensor durável:** `sdd adr check` (os dois lados do vínculo), cobrado pelo `gate_PLAN` sob
`ADR_CHECK=block`.
**Reversível por:** apagar o arquivo e voltar `adr: none` — só antes de qualquer outro incremento.
⚠️ Se o humano escolher uma alternativa que não a recomendada, reescreva **no mesmo commit da ADR**
o Check do incremento afetado (I2 com a alternativa (b); I4 com a alternativa do § 4) e anote o
porquê no `checkpoint-notas.md`.

### I2 — a rota do `skipped`

**O quê:** no `qa_substep`, depois do ramo sem interface e antes do charter, `close` quando o
`00-missao.md` declara `qa: skipped` (literal). Comentário no sítio nomeando o **dono** do artefato
que o gate vai exigir (o `sdd-qa`, que escreve o `30-handoff-qa.md`) — a segunda metade do princípio 1.
**Onde:** `bin/sdd` (`qa_substep`), `tests/check-dry-run.sh` (bloco `:487-538`),
`tests/check-mutation.sh` (mutante novo no molde de `:797`).
**Como (TDD):** no bloco de QA do `check-dry-run.sh`, com `E2E_CMD="true"` e um charter presente,
escrever `qa: skipped` no frontmatter do `00-missao.md` do fixture e afirmar `QA:close=sdd-qa` com o
nome exato `a plan that declares qa: skipped goes straight to QA:close with an interface` — vermelho
hoje (projeta `QA:exec=<none>`). Controle no mesmo bloco: `qa: Skipped` (grafia errada) volta a
projetar a rota de hoje. Restaurar o frontmatter byte a byte antes do bloco seguinte (o fixture
depende de árvore limpa, `:477`). Mutante: o ramo novo apagado ⇒ o sensor morre; provar com
`tests/check-mutation.sh --only <slug> tests/check-dry-run.sh`.
**Check:** `o=$(bash tests/check-dry-run.sh 2>&1); grep -c '^  ok    a plan that declares qa: skipped goes straight to QA:close with an interface' <<< "$o"` → `1`
**Sensor durável:** a asserção e o controle no `check-dry-run.sh`, mais o mutante no catálogo.
**Reversível por:** reverter o commit; nenhum artefato em disco depende dele.

### I3 — o contrato da chave `qa:`

**O quê:** o contrato em todos os lugares no mesmo commit (regra do `CLAUDE.md`: contrato quebrado
em três lugares é o modo de falha mais caro do kit):
- `templates/missao.md`: a linha `qa:` no frontmatter, vazia por padrão, com o placeholder dizendo
  que só o literal `skipped` desvia a rota e que a justificativa vai nas Decisões do grill;
- `agents/sdd-qa.md` § 2: uma frase com **"the plan declares `qa: skipped`"** — o runner manda a
  sessão direto para cá; ela confere o diff real contra a justificativa do plano; nada visível ao
  usuário ⇒ `status: skipped` citando o plano e os arquivos; algo visível ⇒ `status: blocked`
  nomeando os arquivos (o humano tira a chave e roda de novo);
- `agents/sdd-planner.md` e `commands/sdd-plan.md`: quando o grill decide que a QA não se aplica, o
  planner escreve `qa: skipped` e a justificativa;
- `docs/pipeline.md` § QA: a rota nova.
Depois, `./bin/sdd install --force` sincroniza o espelho `.claude/agents/` deste repo.
**Onde:** os cinco arquivos acima.
**Como (TDD):** o Check abaixo lista os dois arquivos de contrato que carregam as duas grafias; é 0
hoje. Rode `bash tests/check-templates.sh` e `bash tests/check-lang.sh` (o `sdd-qa.md` é superfície
inglesa; o template é pt-BR).
**Check:** `o=$(grep -l -e '^qa:' -e 'plan declares .qa: skipped' templates/missao.md agents/sdd-qa.md); grep -c . <<< "$o"` → `2`
**Sensor durável:** a asserção do I2 mede o comportamento; a prosa é medida pelo `check-lang.sh`
(idioma) e pela fase DOCS (drift). Se o `check-templates.sh` passar a cobrar a chave a custo baixo,
melhor — senão, declare no cabeçalho dele que a chave é opcional e por isso não cobrada.
**Reversível por:** reverter o commit.

### I4 — a rota do reteste

**O quê:** no `qa_substep`, depois do `report_closed`, `exec` quando um `F<n>` `done` tem commit
posterior ao último commit que tocou o relatório da missão (a condição de "Arquitetura"). No mesmo
commit, os três lugares que descrevem a rota:
- `bin/sdd:2651-2654` e `:2915-2917`: o comentário deixa de afirmar `disable-model-invocation` e diz
  o que o kit sabe — o slash é a rota do runner, qualquer que seja a flag da skill;
- `phase_task` do `QA:exec` (`:2935`): o texto cobre também o reteste dos bugs consertados;
- `agents/sdd-qa.md` § 4 (`:97-103`): depois de um `F<n>` feito, o runner devolve a QA à
  `qa-execution`, que reanda e move o `Status:`; a sessão `sdd-qa` nunca chama a skill.
**Onde:** `bin/sdd`, `agents/sdd-qa.md`, `tests/check-dry-run.sh`, `tests/check-mutation.sh`.
**Como (TDD):** no bloco de QA do `check-dry-run.sh`, com o relatório da missão fechado e
commitado numa branch de missão (o molde de `:522-538`), acrescentar ao checkpoint do fixture uma
linha `F1 … done <hash>` cujo hash é um commit **posterior** ao do relatório, e afirmar
`QA:exec=<none>` com o nome exato `a fix increment done after the closed report sends QA back to exec
for the retest` — vermelho hoje (projeta `QA:close=sdd-qa`). Controles: um `F1` `done` **anterior**
ao relatório continua `close`; um `F1` `pending` continua `close`. Mutantes: a condição apagada, e
`--is-ancestor` trocado por "qualquer `F` done" — os dois mortos por `--only`.
**Check:** `o=$(bash tests/check-dry-run.sh 2>&1); grep -c '^  ok    a fix increment done after the closed report sends QA back to exec for the retest' <<< "$o"` → `1`
**Sensor durável:** as três asserções no `check-dry-run.sh`, os dois mutantes no catálogo, e o
`no_work_check` como freio de um reteste que não produz relatório novo.
**Reversível por:** reverter o commit; o `sdd-qa` volta a improvisar como hoje.

### I5 — o spec do bug que nenhum agente fecha

**O quê:** `agents/sdd-qa.md` § 3 ganha o caso do bug `Closable by: human` ou `deferred`: o spec
reproduz o achado com `test.fail()` chamado **depois** das pré-condições — o vermelho fica nelas, o
spec passa enquanto o bug existe e reprova quando o conserto entra. `test.fixme()`/`skip` são
decoração e não servem. Sem isso, o spec vermelho derruba o `E2E_CMD` do `gate_QA` e gasta o
`QA_MAX_ITER` num bug que nenhum agente pode fechar.
**Onde:** `agents/sdd-qa.md`; `./bin/sdd install --force` depois.
**Como (TDD):** o Check é 0 hoje; `bash tests/check-lang.sh` depois (superfície inglesa).
**Check:** `o=$(grep -l -F 'test.fail()' agents/sdd-qa.md); grep -c . <<< "$o"` → `1`
**Sensor durável:** só checagem de prosa — o idioma é do Playwright do alvo, e o kit não roda e2e
de alvo. Declarado aqui, e a fase DOCS confere o drift.
**Reversível por:** reverter o commit.

### I6 — onde vai o `RESOLVED by` no teto

**O quê:** `templates/todo.pt-BR.md` e `templates/todo.md`, § Ciclo de vida / Lifecycle: no item que
já está no teto de 8 linhas, o token vai **no fim da linha `Fonte:`** (`Source:` no inglês),
separado por ` — `, e a linha continua cabendo nos 120 caracteres. As grafias que o Check lê são
"fim da linha" seguido de `Fonte:` entre crases (pt-BR) e "end of the" seguido de `Source:` entre
crases e "line" (inglês) — o `.` do padrão casa a crase.
**Onde:** os dois templates.
**Como (TDD):** o Check é 0 hoje. Depois, `bash tests/check-templates.sh` e `bash tests/check-todo.sh`
(o selftest lê os templates) verdes.
**Check:** `o=$(cat templates/todo.pt-BR.md templates/todo.md); grep -c -e 'fim da linha .Fonte' -e 'end of the .Source' <<< "$o"` → `2`
**Sensor durável:** o `check-todo.sh` já reprova o item de 9 linhas e a linha acima de 120; a frase
diz a saída que passa nos dois.
**Reversível por:** reverter o commit.

### I7 — fecho

**O quê:** `docs/pipeline.md` (se o I3 não fechou tudo), verbete no `CONTEXT.md` (a rota da QA:
as duas perguntas novas do `qa_substep` e por que nenhum gate mudou), a seção § 4 da
`.claude/rules/anatomia-do-agente.md`, `./bin/sdd install --force` e a entrada do `KAIZEN_LOG.md`
com antes/depois: o antes é o veredito desta pasta (3 de 5 missões com QA à mão; 3 de 5
intervenções; reteste improvisado em duas missões), o depois são M1 e M2 medidos no fixture. A
`M4` fica declarada como a medida da próxima janela.
**Onde:** os arquivos acima.
**Check:** `grep -c -E '^## .*a rota da QA' KAIZEN_LOG.md` → `1`
**Sensor durável:** não se aplica — registro.
**Reversível por:** reverter o commit.

## Triagem do `TODO.md` e destino dos achados `kit:`

**Seção aberta do `TODO.md` em `4f16a6d`: zero itens** (`tests/check-todo.sh --count TODO.md` → `0`,
catraca `todo-findings 0`). Não houve o que triar ali. Os candidatos vieram dos **seis** achados `kit:`
dos handoffs da janela, que a triagem do `sdd kaizen` transporta (anatomia § 5):

| Achado `kit:` | Origem (alvo) | Destino |
|---|---|---|
| `skipped` do grill sem rota headless | `20261010-o-backlog-volta-a-medir`, `20-handoff-exec.md` | esta missão, I1–I3 |
| reteste depois de `F<n>` sem rota | `20261005-mascaras-ncm-e-painel` e `20261009-o-que-some-calado`, `30-handoff-qa.md` | esta missão, I1 e I4 |
| spec de bug `human`/`deferred` | `20261011-detalhe-e-lista-dizem-a-verdade`, `30-handoff-qa.md` | esta missão, I5 |
| `RESOLVED by` no teto de 8 linhas | `20261011-a-catraca-ganha-folga`, `00-missao.md` e `20-handoff-exec.md` | esta missão, I6 |
| `GATE_WHY` sem histórico de queda do caso e2e | `20261005-mascaras-ncm-e-painel`, `30-handoff-qa.md` | `TODO.md`, § Saída humana (`bin/sdd:1800`) |
| âncora de caminho longo e o `WIDTH_CAP` | `20261010-o-backlog-volta-a-medir`, `00-missao.md` | `TODO.md`, § Contrato (`tests/check-todo.sh:211`) |

Pela régua D15, os seis têm consumidor fora da suíte do kit (o `sales_quote`), então todos são
admitidos. Os dois que não cabem na missão entraram no `TODO.md` no commit do veredito, com a
catraca `tests/health-baseline.txt` indo de `todo-findings 0` para `todo-findings 2` no mesmo diff;
`tests/check-todo.sh --check TODO.md` → `2 finding(s), … every anchor on target`.

### Itens que saem para o cabeçalho do sensor (D15)

Nenhum: a seção aberta estava vazia e nenhum dos seis achados é dívida sem consumidor.

### Resolvidos a apagar

Nenhum: não há `RESOLVED by <hash>` no `TODO.md` de `4f16a6d`.

## Riscos e não-feitos

| Risco | Probabilidade | Mitigação |
|---|---|---|
| A rota do reteste custa **uma sessão a mais** que a improvisação (a `o-que-some-calado` fez reteste e fecho numa sessão só: QA de 3 sessões, US$ 23,72) | alta | é o trade-off da decisão 2; o humano pesa no I1 contra a fragilidade medida (a improvisação depende de `disable-model-invocation: false`) |
| A sessão `QA:close` que escreve o `skipped` custa uma sessão opus por missão sem QA — **não medido** | média | comparar com o ritual de hoje (uma intervenção humana) na próxima janela; a alternativa (b) da decisão 1 é zero sessão |
| O reteste escreve o relatório com um nome que o `sort -V` põe **antes** do original: o `mission_qa_report` segue no antigo, a condição persiste e a QA volta a `exec` | baixa | falha fechada e alta: o `no_work_check` forma (a) para a linha na 2ª volta igual. O nome medido (`…-por-r2.md`) ordena depois. Se o humano preferir, a condição pode ler o commit mais novo entre **todos** os relatórios da missão — decidir no I1 |
| `qa: skipped` declarado e o EXEC acabou tocando a tela | média | Jidoka desenhado: o `sdd-qa` escreve `blocked`, `handoff-blocked` para a linha (rc 3), o humano tira a chave e relança |
| O `qa_substep` passar a publicar global quebra o `step_after` de `bin/sdd:8956` em silêncio | baixa | ler arquivo e git sem atribuir global; a asserção do `step_after` no `check-autonomy.sh` segue valendo |
| `MISSION_DIR` vazio em algum chamador fora do `cmd_run` (`sdd status`, `--dry-run`) | baixa | `frontmatter` sobre arquivo ausente devolve vazio, que é a rota de hoje — conferir no I2 com o `sdd status` de uma missão do fixture |
| A ADR escolher uma alternativa e os Checks de I2/I4 deixarem de medir a coisa certa | média | o I1 reescreve o Check afetado no mesmo commit da ADR, com nota |
| O carimbo de mutação (~60 min) rodado antes da rodada dos bots | média | ordem do `CLAUDE.md`: PR aberto, todos os bots, consertos numa leva, `./bin/sdd health` uma vez |

Não-feitos, por escolha: o `GATE_WHY` com histórico de queda e o `WIDTH_CAP` (no `TODO.md`); baixar o
modelo do `QA:close`; a fila (a)–(k) do humano, que mora fora do repo.

## Verificação end-to-end

- `tests/run-all.sh` verde (o `TEST_CMD` deste repo), com as asserções novas do `check-dry-run.sh`.
- `tests/check-mutation.sh --only <slug> tests/check-dry-run.sh` para cada mutante novo → pego; e o
  `--anchors` da suíte rápida → `all N mutants still apply`.
- M1 e M2 do `00-missao.md` lidos nas linhas `ok` do `check-dry-run.sh` (Checks de I2 e I4).
- `./bin/sdd adr check` → rc 0; `./bin/sdd preflight` sem `agent sdd-qa stale`.
- `./bin/sdd health` depois da rodada dos bots → `score: N caught … of N`, `kit healthy`, carimbo escrito.
- M4 fica para o próximo `sdd kaizen`: na janela seguinte, nenhuma linha `manual` de QA e nenhuma
  missão com o ritual de dois lançamentos.
