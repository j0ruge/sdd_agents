---
missao: 20260826-o-laco-da-qa
data: 2026-08-26
---

# Plano — a fase QA para de girar em bug que ninguém pode fechar

> **Teste de autocontenção:** uma sessão nova, sem nenhuma memória da conversa que gerou este
> plano, lendo apenas `00-missao.md` + `01-plano.md` + `checkpoint.md`, consegue executar?
>
> Rodado ao fechar o plano. **Seis** coisas entraram por causa dele, marcadas **[autocontenção]**:
> quem é o dono da linha `Status:`, o registry do próprio kit estar limpo, os quatro lugares onde
> um sensor novo se registra, a ordem obrigatória do `sdd health`, a regra do `sdd install --force`
> e a forma da asserção diferencial.

## Contexto verificado (não re-descobrir)

**As duas engrenagens, com âncora lida no arquivo:**

- `bin/sdd:598-604` — Âncora 3: `grep -rlE '^\-[[:space:]]+\*\*Status:\*\*[[:space:]]+open'` sobre
  `$REPO_ROOT/$QA_DOCS_PATH/bugs/`, contando arquivos. Roda **depois** do if/else de interface,
  portanto vale para os dois tipos de projeto, e **antes** do `TEST_CMD`/`E2E_CMD` — com bug
  `open`, o gate nunca chega às suítes.
- `bin/sdd:3464-3486` — o laço: `moved2` é amostrado ANTES do gate (a ordem é decisão documentada
  no comentário); `gate_rc2 != 0` + `moved2=true` ⇒ `continue`. Só `moved2=false` duas vezes
  dispara `return 3`.
- `bin/sdd:1602` — o token já existe com o sentido certo: *"blocked — the line stopped; the runner
  returns 3 and a human has to act."*
- `bin/sdd:564` — `status: blocked` no handoff já reprova o gate; o que falta é escalar em vez de
  girar.

**[autocontenção] Quem pode escrever a linha `Status:` do registry — leia antes de "consertar" pelo
caminho errado:**

- `agents/sdd-qa.md:142` — *"The `docs/qa/` tree belongs to the skills — you read and complement,
  **you do not rewrite**."* É regra **não-negociável** do agente.
- `agents/sdd-qa.md:139` — os statuses são *"owned by the `qa-report`/`qa-execution` skills"*.
- `agents/sdd-executor.md` — `grep -c 'qa/bugs\|Status:'` devolve **1**, a linha `:30`, sobre o
  `checkpoint.md`. O executor não conhece o registry.

⚠️ **Não tente resolver dando ao `sdd-qa` o poder de escrever `Status:`.** Foi considerado e
recusado (decisão 4 do grill): quebraria a regra acima, e a decisão de `wont-fix` num bug P1 é
humana. A missão que motivou esta teve **dois** P1 entre os quatro.

**[autocontenção] O registry do PRÓPRIO kit está limpo, então ele não bloqueia esta missão:**
`ls docs/qa/bugs/*.md` → 6 arquivos; `grep -h '^- \*\*Status:\*\*' docs/qa/bugs/*.md` → 5
`verified`, 1 `fixed`, **0 `open`**. Ou seja: o regime que esta missão conserta **não é
reproduzível pelo registry real do kit** — os testes têm de construir o registry num fixture.

**[autocontenção] O kit é "projeto sem interface":** `.sdd/config.sh` traz `E2E_CMD=""` e não
define `APP_URL`, então `gate_QA` toma o ramo `[ -z "$E2E_CMD" ] && [ -z "$APP_URL" ]` e lê a
evidência do campo `gate:` do handoff. **A Âncora 3 roda nos dois ramos** — é depois do if/else.

**Onde os sensores moram:**

- `tests/check-gates.sh` — regimes de gate. `QA_DOCS_PATH="docs/qa"` já é montado no fixture
  (linha 113); a seção do QA começa na linha 445.
- `tests/check-mutation.sh` — o catálogo. Mutantes do QA existentes: `mut_QA_status_line_start`
  (205), `mut_QA_status_enum_loose` (211), `mut_QA_bug_enum_loose` (218), `mut_QA_matrix_pending`
  (222), `mut_QA_bug_open` (226). Copie a forma do `mut_QA_bug_open`.
- `docs/qa/templates/bug.md` — o formato do arquivo de bug, onde o campo de gênero entra.

**[autocontenção] Sensor novo entra em QUATRO lugares, e o quarto arrasta um quinto** — está no
`CLAUDE.md`, e custou uma missão descobrir: a linha `run` do `tests/run-all.sh`, o `LINT_FLOOR` do
mesmo arquivo, o piso de superfície do `tests/check-pipefail.sh` e o do `tests/check-lang.sh`; o
quinto é o fixture do selftest do `check-pipefail.sh`, construído exatamente no piso.
**Esta missão não cria sensor novo** — acrescenta regimes a sensores existentes —, então os quatro
lugares não se movem. Está escrito aqui para que ninguém os mova "por precaução".

**[autocontenção] A ordem do `sdd health --with-mutation` custa 20-50 min quando se erra:** a chave
do carimbo é o conteúdo de `bin/ tests/ templates/ config/`. Rode **depois do último commit de
código**. `CLAUDE.md`, `CONTEXT.md`, `docs/` e `TODO.md` **não** invalidam;
`tests/health-baseline.txt` **invalida**. Medido em 2026-08-25: 12min32s nesta máquina.

**[autocontenção] Mexeu em `agents/*.md`? O espelho é sincronizado por `sdd install --force`, nunca
por `cp` nem por Edit.** O harness carrega a cópia em `.claude/agents/` e trata `.claude/` como
caminho sensível: em sessão headless as ferramentas levam negativa e a fase parece travada, com o
`sdd preflight` vermelho em `agent <nome> stale` (`bin/sdd:1649`). Duas fases DOCS já queimaram
sessão aqui.

## Arquitetura da mudança

Um campo novo no arquivo de bug; o gate passa a lê-lo; o laço passa a escalar.

```
docs/qa/templates/bug.md
  + - **Closable by:** <agent | human>          (I1)
              │
              ▼
bin/sdd  gate_QA Âncora 3 (:598-604)             (I2)
  conta `Status: open` COM `Closable by: agent`
  ausente ⇒ conta (fail-safe)
              │
bin/sdd  run_phase laço (:3464-3486)             (I3)
  gate reprovou por "status: blocked" ⇒ return 3 já na 1ª
              │
agents/sdd-qa.md § 5                             (I4)
  a frase "do not block the pipeline" vira verdade,
  e o agente ganha o dever de MARCAR o gênero
  (nunca de escrever `Status:`)
```

## Incrementos

### I1 — o arquivo de bug passa a declarar quem pode fechá-lo

**O quê:** campo `- **Closable by:** <agent | human>` no template, com o comentário de enum na
mesma forma dos outros campos (`<!-- agent | human -->`).
**Onde:** `docs/qa/templates/bug.md`
**Como (TDD):** não há sensor de template para `docs/qa/` hoje — o `check-templates.sh` mede
`templates/`, não este. O Check é a asserção do I2 falhando antes e passando depois; este
incremento sozinho é formato.
**Sensor durável:** o regime do I2, que lê o campo. Um template sem leitor não tem o que provar.
**Reversível por:** `git revert`; nenhum código lê o campo até o I2.

### I2 — a Âncora 3 distingue gênero, e o desconhecido barra

**O quê:** contar como bloqueante só o bug que é `Status: open` **e** `Closable by: agent`, ou que
não traz o campo. `Closable by: human` deixa de barrar.
**Onde:** `bin/sdd`, `gate_QA` (`:598-604`)
**Como (TDD):** três regimes novos em `tests/check-gates.sh`, escritos antes:
1. registry com 1 bug `open` + `Closable by: human` → gate **passa**
2. registry com 1 bug `open` + `Closable by: agent` → gate **reprova**
3. registry com 1 bug `open` **sem** o campo → gate **reprova** (fail-safe)

⚠️ **A asserção do regime 1 é diferencial**, e o `CLAUDE.md` explica por quê: "o gate passou" é
compartilhado com todo regime saudável, então sozinho ele não distingue nada. Compare as saídas de
1 e 2 entre si e exija que **difiram**, mais a ausência do marcador do outro ramo.
**Check:** ver `checkpoint.md` I2
**Sensor durável:** os três regimes + um mutante novo no catálogo — `mut_QA_bug_genre_ignored`,
que faz a Âncora 3 voltar a contar qualquer `open`. Copie a forma de `mut_QA_bug_open` (`:226`).
**Reversível por:** `git revert`; o campo do I1 fica sem leitor, inerte.

### I3 — `status: blocked` escala na primeira sessão

**O quê:** quando o gate reprova **porque o handoff declara `blocked`**, sair 3 imediatamente, sem
passar pelo heurístico de `moved2`.
**Onde:** `bin/sdd`, o laço de `run_phase` (`:3464-3486`)
**Como (TDD):** regime novo em `tests/check-gates.sh` (ou `check-autonomy.sh`, onde os regimes de
escalada já moram): handoff com `status: blocked` ⇒ **uma** sessão, `rc 3`, e a linha de ledger com
`event: blocked`. Hoje o mesmo fixture consome duas.
⚠️ **Não mova o ponto de amostragem de `moved2`.** O comentário em `bin/sdd:3455-3462` documenta
que ele é amostrado ANTES do gate de propósito, e que mover isso quebra a propriedade em silêncio.
A saída nova é um ramo **antes** do teste de `moved2`, lendo `GATE_WHY`, nunca uma reordenação.
**Check:** ver `checkpoint.md` I3
**Sensor durável:** o regime novo + mutante `mut_RUN_blocked_not_escalated`.
**Reversível por:** `git revert`; volta a girar duas vezes antes de escalar.

### I4 — o contrato do `sdd-qa` para de mentir, e ganha o dever de marcar

**O quê:** duas edições em `agents/sdd-qa.md`:
1. o `§ 5` (`:96-101`) — a frase *"do not block the pipeline"* passa a ser verdadeira e **explica
   por quê** (a Âncora 3 lê `Closable by:`), em vez de afirmar sem mecanismo;
2. o agente ganha o dever de **marcar o gênero** ao triar um bug — e a proibição de escrever
   `Status:` é **repetida ali**, para que a leitura rápida não confunda as duas.
**Onde:** `agents/sdd-qa.md`, depois `./bin/sdd install --force` para sincronizar
`.claude/agents/sdd-qa.md`
**Como (TDD):** o Check é o `sdd preflight` verde (ele compara fonte e espelho) mais a ausência da
frase antiga.
**Check:** ver `checkpoint.md` I4
**Sensor durável:** o `sdd preflight` já compara os espelhos (`bin/sdd:1649`). A frase corrigida não
tem sensor próprio — **limite declarado**: é prosa de contrato, e a régua de admissão do D15 manda
declarar em vez de inventar probe.
**Reversível por:** `git revert` + `sdd install --force`.

## O que para a linha (Jidoka)

1. **Algum regime existente do `check-gates.sh` fica vermelho no I2.** A Âncora 3 mudou mais do que
   devia. Pare; o gênero desconhecido tem de continuar barrando.
2. **`sdd preflight` acusa `agent sdd-qa stale` depois do I4.** Você editou o espelho ou esqueceu o
   `install --force`. Não conserte com `cp`.
3. **O catálogo de mutação cai abaixo de `N caught of N`.** Um mutante novo não está sendo pego, ou
   um antigo perdeu a âncora por causa das suas edições. Reancore; não remova.

## Riscos e não-feitos

| Risco | Probabilidade | Mitigação |
|---|---|---|
| O campo novo faz o registry legado de um repo-alvo virar todo bloqueante | **Nenhuma** | Ausente ⇒ barra, que é o comportamento de hoje. O fail-safe é o de sempre |
| A saída antecipada do I3 escapa por outro `GATE_WHY` que contenha a palavra | Média | Ancore no token, não em substring de prosa. Se `gate_QA` não publicar um marcador estável, crie um |
| `sdd-qa` marca `human` para fugir do trabalho | Baixa | O I4 exige procedência citada em `arquivo:linha` para marcar `human`, que é a régua que a `it.7` da missão anterior usou para mover dois bugs e não mover quatro |
| A missão toca `bin/sdd` e mata o carimbo | Certa | Previsto: `sdd health --with-mutation` roda depois do último commit de código |

## Verificação end-to-end

Com os quatro `done`, os cinco fatos da Métrica:

1. `o=$(bash tests/check-gates.sh 2>&1); grep -c '^  ok    ' <<< "$o"` → maior que antes, com os 3 regimes novos
2. o regime diferencial do I2 verde (gênero humano passa, gênero agente reprova, ausente reprova)
3. `bash tests/check-gates.sh` e `bash tests/check-autonomy.sh` → rc 0
4. `./tests/run-all.sh` → `suite green`, rc 0
5. `./bin/sdd health --with-mutation` → `kit healthy`, `N caught of N`, `all N gates have a mutation in the catalogue`
