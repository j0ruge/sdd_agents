---
missao: 20260816-portas-do-humano
titulo: As quatro portas entre humano e runner ganham dono — aprovar tem comando, a branch declarada é honrada
data: 2026-08-16
versao:
branch: missao/20260816-portas-do-humano
aprovacao: auto
ddd: n/a
---

# Missão — as portas de controle do humano

> Escrito pelo `sdd-planner` com o humano presente. É a única fonte da **intenção**; o `01-plano.md`
> é a fonte do **como**. Toda sessão headless começa lendo estes dois.

## Problema (Gemba)

Quatro pontos onde humano e runner se tocam estão sem instrumento, todos verificados no código:

- **Aprovar plano é editar frontmatter à mão.** Não existe `cmd_approve` no dispatch
  (`bin/sdd:2433-2449`); destravar a fase PLAN exige digitar `aprovacao: humano-YYYY-MM-DD` no
  formato exato que `gate_PLAN` grepa (`bin/sdd:262-266`). Convida a errar o formato ou a delegar
  à sessão — justamente quem não pode decidir.
- **Ninguém confere nem faz checkout da branch declarada.** Nada no runner lê o campo `branch:`
  do frontmatter (só existe em `templates/missao.md:6`). No piloto SQ-97, cinco fases commitaram
  na branch errada — 16 commits sobre PR alheio, ~US$ 45 de `rebase --onto` — e o passo inicial
  repetiu em 2026-08-16: plano declarando `missao/20260816-kit-como-alvo`, humano trocando à mão.
- **`sdd retry` é a quarta porta que commita sem aviso de branch base.** `cmd_retry`
  (`bin/sdd:1856-1877`) não chama `warn_if_on_base_branch`; as outras três portas chamam
  (`bin/sdd:1361`, `:1667`, `:2309`). `sdd retry` na `main` commita na `main` em silêncio.
- **Plano kaizen-born pode se auto-aprovar.** `agents/sdd-planner.md` §6 licencia
  `aprovacao: auto` com PLAN-AUTO toda ✅ ("the human was present"), premissa falsa para plano
  nascido do `sdd kaizen` — e `gate_PLAN` aceita `auto` sem olhar a origem, apesar de
  `agents/sdd-kaizen.md` §6 mandar nascer com `aprovacao:` **vazio, sempre**.

## Métrica

- `sdd approve <missão>` fecha o `gate_PLAN` num fixture **sem** edição manual de frontmatter —
  binário, medido por asserção em `tests/check-gates.sh`.
- A classe SQ-97 morre: fixture prova que o runner troca para a branch declarada (existente) e a
  cria da atual (inexistente) — binário.
- Catálogo de mutação **44 → 48**, `0 known gaps`, medido pela linha `score:` do
  `tests/run-all.sh`.
- Os 4 itens correspondentes do `TODO.md` ganham `RESOLVIDO por <hash>`.

## Resultado esperado

O humano aprova um plano com um comando que mostra o que está aprovando (título, PLAN-AUTO,
incrementos, pendências) e grava data + commit sozinho. O runner honra o campo `branch:` do
plano: troca se existe, cria da atual se não existe, não faz nada no placeholder — e commitar na
branch errada deixa de ser um modo de falha silencioso, em todas as quatro portas que abrem
sessão. Plano nascido do kaizen só anda com aprovação humana explícita, agora imposto por gate e
não só por prosa.

## Fora de escopo

- **Eixo do juiz / I13.4** (guarda insatisfazível, `--all-repos`, worktree, linha sem `repo`) —
  exige grill próprio com ADR; segue no `TODO.md`.
- **Budget por fase** (`BUDGET_PER_PHASE_USD` granular) — segue no `TODO.md`.
- **5 chaves fantasma do `config/schema.md`** e renomeação PT-BR do contrato — seguem no `TODO.md`.

## Gate PLAN-AUTO

Preenchido pelo `sdd-planner` **com evidência**. Todos ✅ → `aprovacao: auto` e o pipeline segue
sozinho. Qualquer ✗ → `aprovacao` fica vazio e o runner para pedindo aprovação humana explícita.

| # | Critério | Status | Evidência |
|---|---|---|---|
| a | Grill sem perguntas abertas não endereçadas (🚩 vazia ou itens deferidos com dono) | ✅ | 2 perguntas respondidas (tema; semântica do approve); 🚩 vazia — decisões na seção abaixo |
| b | Checklist kaizen 100% ✅ e checklist DDD 100% ✅ ou `n/a` justificado | ✅ | seções abaixo |
| c | Plano passa no teste de autocontenção (sessão nova só com 00/01/checkpoint executa) | ✅ | "Contexto verificado" do `01-plano.md` carrega todo file:line e as armadilhas da casa |
| d | Todo incremento do `checkpoint.md` tem Check executável (comando → esperado) | ✅ | 4/4, todos rodados contra o HEAD em 2026-08-16 e **vermelhos** (contagem 0, sensor rc 0) |
| e | `versao:` confirmada pelo humano (ou `JIRA_ENABLED=false`) | ✅ | `JIRA_ENABLED=false` no kit |

## Checklist kaizen (`kaizen-software`)

| # | Item | Status | Nota |
|---|---|---|---|
| K1 | Gemba — fui ver onde o trabalho acontece | ✅ | todo fato do Problema tem `arquivo:linha` conferido nesta sessão |
| K2 | Problema declarado com métrica | ✅ | seção Métrica: 2 binários + score 44→48 |
| K3 | Desperdícios identificados e cortados | ✅ | US$ 45 de rebase (SQ-97), aprovação manual propensa a erro, retry silencioso |
| K4 | Fatiamento incremental, cada fatia verificável | ✅ | 4 incrementos, 1 sessão cada, Check próprio |
| K5 | Check por artefato (rótulo ≠ artefato) | ✅ | Checks contam asserções do sensor com âncora `^  ok    `, nunca texto solto |
| K6 | Jidoka — o que para a linha está definido | ✅ | checkout falhou ⇒ `die`; gate kaizen-born reprova; sensor vermelho para a suíte |
| K7 | SDCA — a melhoria vira padrão (doc/rule/teste) | ✅ | regra kaizen-born entra no gate + `sdd-planner.md` + `docs/pipeline.md` no mesmo commit |
| K8 | Registro no KAIZEN_LOG | ✅ | fica a cargo da fase DOCS, com o antes/depois da métrica |

## Checklist DDD (`ddd`) — condicional

`n/a — sem toque de domínio: runner bash + gates; nenhum aggregate, evento ou contrato entre
módulos novo — as mudanças são comando de CLI, função de guarda e ramo de gate.`

## Decisões do grill (não re-litigar)

1. **Tema A (portas de controle), não B (eixo do juiz)** — B exige ADR com o humano; encadeia
   como missão seguinte.
2. **`sdd approve` escreve E commita** (`chore(missao): plano <missão> aprovado pelo humano`) —
   espelha a convenção já usada 2× no histórico; `sdd run` continua decisão separada porque custa
   ~US$ 70.
3. **Checkout nunca em dry-run** — a garantia do dry-run é "nenhum artefato de missão tocado";
   trocar branch é mutação de estado.
4. **Falha de checkout mata alto** (`die` com o erro do git) — Jidoka, nunca adivinhar por cima
   de working tree que o git recusou.
5. **Marcador kaizen-born = `05-verdict.md` no diretório da missão** — verificado que existe na
   prática (`docs/handoffs/20260816-kit-como-alvo/05-verdict.md`). A regra entra no `gate_PLAN`,
   não só na prosa.
6. **A missão não encosta no comportamento da fase TICKET** — placeholder `<criada pela fase
   TICKET>` é no-op no checkout, como hoje.

## Pendências para o humano

<vazio>
