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

**Passa quando:** existe `30-handoff-qa.md` e (`status: skipped` **ou** todas as condições):

- o relatório mais recente em `<QA_DOCS_PATH>/reports/` está `**Status:** closed`;
- nenhuma linha da matriz de sessões continua `Pending`;
- nenhum arquivo em `<QA_DOCS_PATH>/bugs/` tem `**Status:** open`;
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

## Depois do PR

O **merge é humano** e é o único gate humano incondicional do pipeline. As "Decisions for a
Human" acumuladas pelas fases chegam como seção do PR: elas informam a decisão de merge, sem
nunca terem travado a automação.

Pós-merge, `sdd close <missão>` fecha a issue do JIRA com resumo automático.

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

Cada sessão vira uma linha em `<missão>/pipeline.log` (fase, agente, modelo, session-id, exit
code, duração, custo em USD) e um JSON completo em `.sdd/logs/<missão>/`. `--max-budget-usd` por
sessão é teto de dano, não orçamento.
