# Pipeline — máquina de estados e gates

Como o `sdd` decide o que rodar, e o que cada fase precisa entregar para a próxima.

## A ideia central: não existe arquivo de estado

A fase corrente é **derivada** dos artefatos em disco. `sdd run <missão>` percorre os gates na
ordem canônica e executa **a primeira fase cujo gate não está satisfeito**.

Três consequências que valem o design inteiro:

1. **Resume de graça.** Sessão morreu por rede, OOM ou estouro de janela? `sdd run` de novo
   continua do ponto exato — não há estado para reconciliar.
2. **Impossível o estado mentir.** Não existe arquivo dizendo "fase QA concluída" que possa
   discordar do disco. O disco é a fase.
3. **O loop QA⇄EXEC sai sozinho.** Quando o `sdd-qa` escreve incrementos de fix no
   `checkpoint.md`, o gate de EXEC volta a reprovar, e como EXEC vem antes de QA na ordem, a
   próxima volta do laço cai nele. Nenhum código de laço foi escrito para isso.

E a regra que sustenta tudo: **sucesso nunca é a resposta do modelo.** Todo gate é reavaliado
pelo runner — rodando os testes, conferindo hash no `git log`, lendo o relatório, chamando o
`gh`. O texto que a sessão devolve não satisfaz gate nenhum.

## Ordem canônica

```
PLAN → TICKET → EXEC ⇄ QA → REVIEW → DOCS → PR → (merge: humano)
```

## Os gates

### PLAN — o único que o runner não executa

O planejamento é interativo por design: é a participação humana. O runner só verifica e instrui.

**Passa quando:** existem `00-missao.md`, `01-plano.md` e `checkpoint.md`; o frontmatter da
missão traz `aprovacao: auto` ou `aprovacao: humano-<data>`; com `JIRA_ENABLED=true`, `versao:`
está preenchida; e o `checkpoint.md` tem ao menos uma linha parseável.

**PLAN-AUTO:** `aprovacao: auto` significa que o `sdd-planner` fechou os cinco critérios (grill
sem pendência, checklists, autocontenção, Check por incremento, versão) **com evidência**. O
grill bem feito é a aprovação — o humano esteve presente. Qualquer critério aberto e o planner
deixa `aprovacao` vazio, e o runner para pedindo aprovação explícita.

### TICKET — pulado quando não há JIRA

**Passa quando:** `JIRA_ENABLED=false` (skip registrado), ou existe `10-ticket.md` com `issue:`
**e** `sprint:` no frontmatter.

Exigir `sprint:` é deliberado: card criado no backlog é trabalho invisível para o time. A skill
`ticket` cria já na sprint ativa e confirma que saiu do backlog.

### EXEC — uma sessão por incremento

**Passa quando:** toda linha do `checkpoint.md` está `done`; cada `done` tem um hash que existe
de verdade no `git log`; `TEST_CMD` sai 0; e `20-handoff-exec.md` existe.

**Jidoka:** qualquer incremento `blocked` escala **na hora** — sem retentativa, sem consumir o
orçamento de sessões da fase. O executor marca `blocked` quando a suíte está vermelha por causa
de um incremento anterior. O motivo está nas "Notas de execução" do checkpoint.

**Progresso ≠ gate.** Enquanto sobram incrementos, o gate reprovar é o caso **normal**. O runner
distingue os dois por impressão digital do estado (HEAD + artefatos + hash do checkpoint): mudou
⇒ a sessão avançou, segue; não mudou ⇒ a sessão não fez nada, ganha uma retentativa com o motivo
do gate no prompt e, se ainda assim não mover, vira `BLOCKED`.

### QA — três sub-passos, uma fase

A fase são **três sessões**, e o sub-passo corrente é **derivado dos artefatos** (`qa_substep`),
nunca de um contador:

| Sub-passo | Quem dirige | Quando | Entrega |
|---|---|---|---|
| `QA:plan` | skill `/qa-report` (sem agente do kit) | não há charter em `<QA_DOCS_PATH>/charters/` | charters, personas, jornadas |
| `QA:exec` | skill `/qa-execution` (sem agente do kit) | há charter, mas nenhum relatório `closed` | relatório datado + registry de bugs |
| `QA:close` | agente `sdd-qa` | relatório `closed` — ou projeto sem interface | specs e2e, incrementos de fix, `30-handoff-qa.md` |

As duas skills são as **donas** de `docs/qa/`; o `sdd-qa` não reescreve o que elas produziram.
Projeto **sem interface** (sem `E2E_CMD` e sem `APP_URL`) vai direto a `QA:close`: bootstrapar
jornada de browser num projeto sem browser é a burocracia que o `skipped` existe para evitar.

**Passa quando:** existe `30-handoff-qa.md` e (`status: skipped` **ou** todas as condições):

- **a evidência da jornada andada**, que tem duas formas conforme o projeto:
  - **com interface** (`E2E_CMD` ou `APP_URL` definido) — o relatório mais recente em
    `<QA_DOCS_PATH>/reports/` está `**Status:** closed` e nenhuma linha da matriz de sessões
    continua `Pending`;
  - **sem interface** (nem `E2E_CMD` nem `APP_URL`) — o campo `gate:` do próprio
    `30-handoff-qa.md` está preenchido. Aqui as skills `qa-report`/`qa-execution` nunca rodaram,
    então a árvore `docs/qa/` não existe: cobrar o relatório datado delas seria exigir um
    artefato que ninguém produz, e o gate ficaria insatisfazível justamente no caso em que a QA
    fez o trabalho e **achou** coisa;
- nenhum arquivo em `<QA_DOCS_PATH>/bugs/` tem `**Status:** open` (vale nos dois casos);
- `TEST_CMD` sai 0 e `E2E_CMD` sai 0 (quando definido).

`wont-fix` e `invalid` **não** bloqueiam: são decisão humana registrada, não defeito pendente.

`qa: skipped` é resposta legítima e prevista: diff sem mudança user-visible (refactor, tipos,
build, docs) não tem jornada para andar. Inventar jornada para "ter QA" é desperdício.

### REVIEW — Grade A em todos os critérios

**Passa quando:** o `40-review-r<N>.md` mais recente traz a seção `### Overall Grade` com **A em
toda linha**; `TEST_CMD` sai 0; e o working tree está limpo.

Um critério com `—` (não analisado) também reprova: review parcial não é review.

O laço revisar→corrigir→re-revisar acontece **dentro** da sessão. Se ela termina sem fechar, o
runner abre uma sessão nova continuando, até `REVIEW_MAX_ITER` no total. Estourou →
`BLOCKED`, ou PR draft se `PUBLISH_ON_REVIEW_BLOCKED=draft`.

### DOCS — checklist de drift

**Passa quando:** existe `45-docs.md` com o checklist de drift e **nenhum item pendente** (`✗`,
`TODO`, `<preencher>`). Cada área tocada pelo diff tem `✅` com hash de commit ou `n/a` com
justificativa concreta.

### PR — confirmado pelo `gh`, não pelo arquivo

**Passa quando:** existe `50-pr.md` com `pr_url:` **e** `gh pr view <url>` confirma que o PR
existe. Arquivo que afirma um PR inexistente reprova — e é bom que reprove.

## Dry-run — a projeção

`sdd run <missão> --dry-run` responde *"o que acontece se eu rodar isto?"* antes de gastar token.
Ele percorre a ordem canônica e imprime **todas** as fases cujo gate está insatisfeito, cada uma
com modelo, agente, session-id, o comando `claude` completo e o prompt de boot.

**Projeta o presente, não simula o futuro.** A projeção lista os gates insatisfeitos **hoje**. Ela
não tenta adivinhar que a fase EXEC satisfaria o próprio gate e destravaria a QA. É uma escolha
deliberada: informação honesta vale mais do que informação completa e potencialmente errada — e
uma simulação de pipeline que erra é pior do que não ter simulação.

Por isso a projeção **não** pode usar `current_phase()`. Como o dry-run não muda nada no disco, o
gate insatisfeito continua insatisfeito e `current_phase()` devolveria a mesma fase para sempre —
laço infinito. Ela avança por um cursor próprio sobre a lista `$PHASES` (`next_pending_phase()`).

Três casos em que a projeção para cedo, e é para parar mesmo:

| Situação | O que sai | Exit |
|---|---|---|
| `PLAN` pendente | a instrução interativa para o humano; nenhuma fase projetada | 2 |
| incremento `blocked` no checkpoint | o Jidoka, com o motivo; nenhuma fase projetada | 3 |
| `--phase <FASE>` | só a fase pedida — `--phase` força, não projeta | 0 |

Um detalhe de vocabulário que confunde: a projeção imprime o **sub-passo** (`QA:close`), enquanto
`--phase` aceita o nome da **fase** (`QA`). Copiar `QA:close` para dentro de `--phase` não
funciona — o sub-passo é derivado dos artefatos, nunca escolhido na linha de comando.

### O que o dry-run mexe, e o que não

A frase fácil — "o dry-run não mexe em nada" — é falsa, e o `--help` não a usa. A garantia real é
mais estreita e é esta:

- **não gasta sessão:** nenhum `claude` é invocado;
- **não toca nos artefatos da missão:** nada é escrito em `docs/handoffs/<missão>/`;
- **não escreve no diário:** a guarda vive dentro do `pipeline_log_line()`, não nos chamadores.
  São três os caminhos que logam antes de qualquer sessão (checkpoint `blocked`, orçamento
  estourado, duas sessões sem progresso) e um quarto adicionado amanhã nasceria com o defeito de
  novo; guarda única torna "a projeção não escreve no diário" verdadeiro por construção;
- **mas os gates rodam de verdade:** para saber quais fases estão pendentes é preciso avaliar os
  gates, e `gate_EXEC`/`gate_QA`/`gate_REVIEW` rodam `TEST_CMD`. Isso escreve
  `.sdd/logs/<missão>/gate-*-test-<ts>.log` — gitignored, memoizado por processo em
  `run_check_cmd`, mas real. Quem espera custo zero em repo com suíte lenta precisa saber disto.

## Depois do PR

O **merge é humano** e é o único gate humano incondicional do pipeline. As "Decisions for a
Human" acumuladas pelas fases chegam como seção do PR: elas informam a decisão de merge, sem
nunca terem travado a automação.

Pós-merge, `sdd close <missão>` fecha a issue do JIRA com resumo automático (skill `/ticket
close`, modelo `MODEL_TICKET`). Ele se recusa a rodar fora do lugar certo, e cada recusa é
deliberada:

| Condição | O que acontece |
|---|---|
| `JIRA_ENABLED=false` | não é erro — informa "nada a fechar" e sai 0 |
| sem `issue:` no `10-ticket.md` | erro: a fase TICKET não rodou, não há o que fechar |
| `50-pr.md` com `pr_url:` cujo PR não está `MERGED` | erro: `sdd close` é **pós-merge**, e fechar a issue antes do merge é mentir para o board |

O `sdd close` é a única invocação do `claude` fora de `run_phase()` além do probe do
`sdd preflight` — as duas não rodam fase.

## Modelos por fase

Opus onde há julgamento (EXEC, QA, REVIEW, DOCS), Sonnet onde a tarefa é mecânica (PR, TICKET),
Fable no planejamento interativo. A exceção de custo é **explícita na config**, nunca silenciosa
— `MODEL_PUBLISH="sonnet"` está lá para ser lido e contestado.

## Permissões

O runner passa `--permission-mode acceptEdits` **e** `--allowedTools "$ALLOWED_TOOLS"` (default
`Bash`). As duas coisas são necessárias: `acceptEdits` auto-aprova edição de arquivo, mas **não**
`Bash` — sem a allowlist a sessão não roda a suíte nem consegue commitar, e a fase EXEC fica
insatisfazível por construção. `bypassPermissions` nunca é default do kit.

O `sdd preflight` prova isso disparando uma sessão headless real com as mesmas flags e exigindo
que ela **execute** um comando. "O claude responde" não cobre este modo de falha.

## Custos e logs

Cada sessão vira uma linha em `.sdd/logs/<missão>/pipeline.log` (fase, agente, modelo,
session-id, exit code, duração, custo em USD) e um JSON completo ao lado, no mesmo
`.sdd/logs/<missão>/`. O diário é **efêmero por contrato**: `.sdd/logs/` está no `.gitignore` que
o `sdd install` escreve, e o registro durável do que aconteceu são os handoffs commitados. Se ele
voltasse para dentro da árvore commitada sujaria o `git status` — e tree sujo reprova
`gate_REVIEW` e o `sdd preflight`. `--max-budget-usd` por sessão é teto de dano, não orçamento.
