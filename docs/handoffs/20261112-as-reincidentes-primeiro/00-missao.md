---
missao: 20261112-as-reincidentes-primeiro
titulo: Os 13 achados do kit que já voltaram pelo menos uma vez deixam de voltar
data: 2026-11-12
versao:
branch: fix/as-reincidentes-primeiro
aprovacao: humano-2026-11-12
adr: none
ddd: n/a
qa:
kaizen_log:
---

# Missão — as reincidentes primeiro (lote 1 de zerar a catraca)

> Escrito pelo `sdd-planner` com o humano presente. É a única fonte da **intenção**; o `01-plano.md`
> é a fonte do **como**. Toda sessão headless começa lendo estes dois.
>
> ⚠️ Esta missão **não roda por `sdd run`**. Quem a executa é uma sessão interativa nova, pelo
> superpowers (`superpowers:executing-plans` ou `superpowers:subagent-driven-development`), no
> worktree `/home/pc_admin/repos/sdd_agents-zerar-catraca`. A sessão começa pela seção "Como esta
> missão é executada" do `01-plano.md`.

## Problema (Gemba)

O `TODO.md` do kit tem 86 achados abertos (`tests/check-todo.sh --count TODO.md` → `86`, igual ao
`todo-findings 86` de `tests/health-baseline.txt:26`). O humano quer a catraca em zero, e mandou
começar pelos que **voltaram**: 13 itens abertos carregam a linha `RECURRED`, somando 25 voltas em
4 projetos (`dotp-remake`, `magic_tutor`, `warehouse_explorer_web`, `sdd_agents`).
A volta é o sinal mais forte de dor real que o arquivo tem (`CLAUDE.md`, princípio 5), e nenhum dos
13 tem conserto no código. Medido em 2026-11-12 sobre `a48cf3c`, mais as três voltas deste grill
(K, L e M), escritas no `TODO.md` do worktree:

| # | Voltas | Item (título no `TODO.md`) | Onde está o defeito |
|---|---|---|---|
| A | 10 | O `/sdd-plan` delega ao `sdd-planner` sem saída para o agente não registrado | `commands/sdd-plan.md` § Then |
| B | 3 | A pergunta que o planner devolve com tarefa sua ainda em segundo plano não chega ao relay | `commands/sdd-plan.md`, `agents/sdd-planner.md` |
| C | 2 | O `check-todo.sh` aceita o `#N` solto que quer dizer "item N" | `tests/check-todo.sh` (`lint_todo`) |
| D | 1 | O planner que não devolve com filho vivo só espera gastando chamadas | `agents/sdd-planner.md:7` (`disallowedTools`) |
| E | 1 | `sdd install --help` instala o kit, e `sdd link-agents --help` liga os agentes | `bin/sdd` (`cmd_install`, `cmd_link_agents`, `main`) |
| F | 1 | O `sdd install` adota a branch atual como base quando falta `origin/HEAD` | `bin/sdd` (`cmd_install`) |
| G | 1 | O `sdd approve` commita o ADR do `adr:` sem tirar o `proposed` | `bin/sdd` (`cmd_approve`) |
| H | 1 | A sessão que morre junto com o runner some do journal, e a sobra dela não aparece no `sdd status` | `bin/sdd` (`cmd_status`, `boot_prompt`) |
| I | 1 | O `sdd status` fica calado enquanto o gate do EXEC roda o `TEST_CMD` | `bin/sdd` (`cmd_status`, `resolve_mission`) |
| J | 1 | O corpo do PR promete CI para os sensores novos, e o alvo pode não ter CI | `templates/pr-body.md:26`, `agents/sdd-publisher.md:61` |
| K | 1 | O `/sdd-plan` não diz o que fazer com a aprovação dada antes do plano | `commands/sdd-plan.md` § When the artifacts exist |
| L | 1 | A fila de PRs de achado do kit não tem receita, e cada merge põe o seguinte em conflito | nenhum doc do kit tem a receita |
| M | 1 | O planner manda chamar a `grill-with-docs`, que o modelo não pode invocar | `agents/sdd-planner.md:41` |

Três dessas voltas aconteceram **no grill desta missão** (K, L e M, todas `sdd_agents/20261112`):
o humano aprovou antes do plano, os PRs 378, 380 e 383 conflitaram na catraca, e a skill
`grill-with-docs` não estava na lista desta sessão.

## Métrica

Fato binário, lido por comando na raiz do worktree depois do último incremento:

1. `grep -cE 'RESOLVED by [0-9a-f]{7,40}' TODO.md` → `13` (hoje `0`), cada hash sendo o commit do
   incremento que consertou o item;
2. os 15 Checks do `checkpoint.md` verdes: 14 leem uma asserção `^  ok    ` que o incremento
   acrescenta a um sensor da suíte, e o do I15 lê o `TODO.md`;
3. `bash tests/run-all.sh` → rc 0 (a suíte rápida, que inclui `check-mutation.sh --anchors`).

A catraca **não desce nesta missão**: continua `todo-findings 86` até o merge. Ela desce a 73 no
chore pós-merge, que apaga os 13 itens (registro decidido de 2026-09-25, "O `RESOLVED by` não deixa
a catraca descer na missão que conserta").

## Resultado esperado

Depois do merge e do chore, o `TODO.md` do kit tem 73 achados e nenhum com `RECURRED`. O
`/sdd-plan` diz o que fazer quando o agente não está registrado, quando o planner tem tarefa viva e
quando o humano aprova antes do plano; o planner pode usar o `Monitor` e chama skills que existem.
`sdd install --help` e `sdd link-agents --help` só imprimem ajuda, o install não grava uma branch de
trabalho como base, o `sdd approve` aceita o ADR que commita, e o `sdd status` fala durante a suíte
e mostra a sobra de uma sessão morta. O corpo do PR só promete CI onde há workflow. A fila de PRs
de achado tem receita escrita. Cada conserto tem asserção nova num sensor da suíte.

## Fora de escopo

- Os outros 73 achados abertos: cada lote seguinte ganha o seu `/sdd-plan`. Nada deles entra aqui,
  nem os vizinhos de arquivo sem `RECURRED`.
- `./bin/sdd health` com o catálogo de mutação e o carimbo: decisão 6. Roda uma vez, quando a
  série chegar a `todo-findings 0`.
- Apagar os 13 itens e mover a catraca para 73: chore pós-merge (Pendências).
- Trocar `grill-with-docs` em `KIT_THIRD_PARTY_SKILLS` (`bin/sdd:7175`): o item M pede só que o
  contrato nomeie as skills que o modelo invoca; a lista do preflight e do health fica como está.
- `sdd run`, QA, REVIEW e DOCS do runner: a missão é executada e publicada fora dele (decisão 5).
- Achado novo que aparecer na execução: vai para o `TODO.md` com a catraca movida no mesmo commit,
  ou para a `RECURRED` do item aberto equivalente; nunca vira incremento desta missão.

## Gate PLAN-AUTO

Preenchido pelo `sdd-planner` **com evidência**. Todos ✅ → `aprovacao` fica vazio do mesmo jeito: o
humano lê o plano no passo de aceite do `/sdd-plan` e aprova com `sdd approve`. O `auto` só entra
quando o humano o pediu no grill, e aí o pipeline segue sozinho até o PR (ADR 0018 §3). Qualquer ✗ →
`aprovacao` fica vazio e o runner para pedindo aprovação humana explícita, nomeando o critério.

| # | Critério | Status | Evidência |
|---|---|---|---|
| a | Grill sem perguntas abertas não endereçadas (🚩 vazia ou itens deferidos com dono) | ✅ | 3 respostas do humano e 3 ordens diretas dele nas decisões 1, 2, 5, 6 e 7; as demais foram delegadas por ele ("pode escolher o recomendado") e estão marcadas como delegadas; o que sobra tem dono em Pendências |
| b | Checklist kaizen 100% ✅ e checklist DDD 100% ✅ ou `n/a` justificado | ✅ | seções abaixo |
| c | Plano passa no teste de autocontenção (sessão nova só com 00/01/checkpoint executa) | ✅ | um agente novo, sem esta conversa, leu só os três arquivos e descreveu o I1 do primeiro ato ao commit do checkpoint, sem erro; as lacunas e contradições que ele listou (I1, I8, I9, I13, I15) foram escritas no `01-plano.md` (nota em `checkpoint-notas.md`) |
| d | Todo incremento do `checkpoint.md` tem Check executável (comando → esperado), vermelho no HEAD pelo `tests/check-checkpoint.sh --red` do kit | ✅ | 15 de 15; `--check` rc 0 e `--red` rc 0 (`15 pending Check(s), every one red at HEAD`), linhas em `checkpoint-notas.md` |
| e | `versao:` confirmada pelo humano (ou `JIRA_ENABLED=false`) | ✅ | `JIRA_ENABLED=false` em `.sdd/config.sh` |
| f | `adr:` é uma decisão — um caminho, ou o literal `none` (alocado por `sdd adr new`) | ✅ | `none`: 13 consertos locais, nenhum trade-off arquitetural; a decisão 6 é de processo, do humano, e tem prazo (a catraca em zero) |

## Checklist kaizen (`kaizen-software`)

> O K8 desta tabela é prosa: quem dispensa a entrada do KAIZEN_LOG.md é só o literal kaizen_log: skipped no frontmatter, decidido com o humano no grill.

| # | Item | Status | Nota |
|---|---|---|---|
| K1 | Gemba — fui ver onde o trabalho acontece | ✅ | os 13 itens lidos no `TODO.md`, e cada âncora aberta no código (`01-plano.md`, contexto verificado); 6 sensores e a suíte rodados e cronometrados em `a48cf3c` |
| K2 | Problema declarado com métrica | ✅ | 13 `RESOLVED by <hash>`, 15 Checks, suíte rc 0 |
| K3 | Desperdícios identificados e cortados | ✅ | sem `sdd health` por missão (decisão 6); item M só em prosa; receita da fila como doc, não script; ajuda num ponto só do `main()` em vez de um caso por subcomando |
| K4 | Fatiamento incremental, cada fatia verificável | ✅ | 15 incrementos, um item por incremento (o H em dois), prosa antes de sensor antes de runner |
| K5 | Check por artefato (rótulo ≠ artefato) | ✅ | cada Check lê a linha `^  ok    ` de um sensor; o I15 lê o `TODO.md` |
| K6 | Jidoka — o que para a linha está definido | ✅ | `01-plano.md` § Como esta missão é executada: suíte vermelha, âncora do `TODO.md` fora do alvo ou mutante que não se aplica param o incremento |
| K7 | SDCA — a melhoria vira padrão (doc/rule/teste) | ✅ | cada conserto entra com probe em sensor da suíte; os de `bin/sdd` com mutante no catálogo; a rule `anatomia-do-agente.md` no mesmo commit quando o componente muda |
| K8 | Registro no KAIZEN_LOG | ✅ | o I15 escreve a entrada, com antes e depois medidos |

## Checklist DDD (`ddd`) — condicional

`n/a — sem toque de domínio: 13 consertos de prosa de contrato, de sensor e de CLI do runner; nenhuma entidade, evento ou contrato entre módulos nasce ou muda de dono.`

## Decisões do grill (não re-litigar)

1. **O recorte são só as reincidentes.** Um incremento por item, e os outros achados ficam para
   lotes seguintes, cada um com o seu `/sdd-plan`. Porquê: cada incremento cabe numa sessão e a
   volta medida é o sinal mais forte de dor real.
   - answer: (recommended)
2. **O recorte vai a 12 com as duas voltas que o relay registrou neste grill** (itens K e L),
   escritas no `TODO.md` do worktree. Porquê: a regra do recorte é "tem `RECURRED`", e as duas
   voltas são desta sessão.
   - answer: (recommended)
3. **O recorte fecha em 13 com o item M** (`grill-with-docs`), cuja volta é do próprio planner
   neste grill. Decisão **delegada** pelo humano ("pode escolher o recomendado"); ele não viu a
   pergunta. Porquê: é a mesma situação da decisão 2, e o conserto é uma frase.
4. **Id `20261112-as-reincidentes-primeiro`, branch `fix/as-reincidentes-primeiro`.** Delegada.
   Porquê: os lotes anteriores do kit usaram `fix/…`, e o nome diz o recorte.
5. **A execução é fora do `sdd run`:** o humano dá `/clear` e uma sessão nova, com o Opus 5.5,
   executa pelo superpowers no worktree. Ordem direta do humano ("a execução usar o superpowers",
   "depois dar clear e executar com o Opus 5.5"). Consequência escrita no plano: nenhum gate do
   runner é chamado; o que substitui cada um está em `01-plano.md` § Como esta missão é executada.
6. **O `./bin/sdd health` só roda quando a catraca zerar.** Ordem direta do humano ("o sdd health
   só quando zerar a catraca"). Esta missão não tem incremento nem passo de carimbo. Consequências
   medidas no código, em `01-plano.md` § O que fica sem carimbo: o `gate_PR` exigiria o carimbo e
   não é chamado; a `main` carrega conteúdo que o catálogo não mediu até lá; a verificação por
   incremento é a suíte rápida, o `--anchors` e o `--only <slug>` de cada mutante novo.
7. **O aceite é "mede, mostra e aprova":** o relay roda `--check` e `--red`, mostra o plano e roda
   `sdd approve` sem nova pergunta, e só para se uma medida falhar. `aprovacao:` fica vazio até lá.
   Porquê: o pedido do humano ("depois aceitar o plano automaticamente") vale como o SIM, e o
   `sdd approve` é quem corta a branch e commita a pasta.
   - answer: (recommended)
8. **`aprovacao: auto` não é escrito.** Delegada ao planner pelo relay. Porquê: sob `auto` o gate
   leria aprovado um plano de que o humano só viu três perguntas, e ninguém commitaria a pasta
   (dois achados abertos do `TODO.md` descrevem exatamente isso).
9. **Só resposta que o humano deu a pergunta que viu ganha `- answer:`.** São três (decisões 1, 2
   e 7). As ordens diretas (5 e 6) e as delegadas ficam em prosa. Porquê: o leitor D22 do aceite
   conta escolhas do humano, e marcar pergunta não vista é o achado aberto "O planner marca o
   `- answer:` de pergunta que o humano não viu".
10. **O `RESOLVED by` dos 13 itens é escrito no último incremento (I15),** com o hash que o
    `checkpoint.md` guarda de cada um. Delegada. Porquê: um commit não cita o próprio hash, e 13
    commits de `TODO.md` intercalados moveriam âncoras 13 vezes.
11. **O I15 também escreve o `20-handoff-exec.md`,** de `templates/handoff.md`. Delegada. Porquê:
    com os incrementos `done`, o `gate_EXEC` reprova por "20-handoff-exec.md is missing"
    (`bin/sdd:1523`), e o `sdd status` da missão mentiria sobre o EXEC; é a direção do achado
    aberto "O plano que executa fora do `sdd run` promete o gate do EXEC sem o
    `20-handoff-exec.md`", que esta missão **não** fecha (não tem `RECURRED`), só não repete.
12. **Desenho de cada conserto, delegado, um por linha** (o detalhe está no `01-plano.md`):
    - A: a saída preferida é reabrir a sessão na raiz do alvo depois do `sdd install &&
      sdd-link-agents`; a reserva é um agente genérico que lê `agents/sdd-planner.md`, com os três
      vetos do `permissionsDeny` repetidos no briefing e o humano avisado em uma linha.
    - B e D são dois incrementos: B é regra de prosa nos dois arquivos; D tira o `Monitor` do
      `disallowedTools` do planner e manda esperar com ele.
    - E: `-h`/`--help` depois de qualquer subcomando é lido num ponto só, no `main()`, antes do
      despacho; `cmd_install` e `cmd_link_agents` passam a recusar opção desconhecida.
    - H são dois incrementos: o `sdd status` (as duas faces) e o `boot_prompt`.
    - L: a receita vira `docs/finding-prs.md`, em inglês (superfície do kit), sem script.
    - M: só a prosa do planner muda; `KIT_THIRD_PARTY_SKILLS` fica.
13. **Ordem: prosa (I1–I7), sensor (I8), runner (I9–I14), fecho (I15).** Delegada. Porquê: os
    baratos primeiro, e os que movem linhas do `bin/sdd` juntos, para reancorar o `TODO.md` em
    sequência.
14. **`qa:` vazio e `kaizen_log:` vazio.** Delegada. Porquê: o runner não roda a QA desta missão,
    então `skipped` não desviaria nada; e a entrada do `KAIZEN_LOG.md` é devida e o I15 a escreve.

## Pendências para o humano

- **Chore pós-merge:** apagar do `TODO.md` os 13 itens com `RESOLVED by` e mover a catraca para
  `todo-findings 73`, pela receita que o I6 escreve em `docs/finding-prs.md`, depois de
  `git merge-base --is-ancestor <hash> main` valer para cada hash. Com squash merge os hashes não
  entram na `main` (achado aberto "O ciclo de vida do `RESOLVED by` não sobrevive a squash
  merge"): prefira merge commit, ou prove pelo PR.
- **A `main` fica sem carimbo de mutação até a catraca zerar** (decisão 6). Enquanto isso,
  `./bin/sdd health --release` tem a linha 6 vermelha, e qualquer missão do kit que rode por
  `sdd run` para no `gate_PR` com rc 2 pedindo `./bin/sdd health`. Se uma dessas aparecer antes do
  zero, a decisão de carimbar mais cedo é sua.
- **O `Monitor` no planner (I3) não tem como ser provado na suíte:** o Check prova o frontmatter e
  a prosa. Que um subagente consiga chamá-lo se vê no próximo `/sdd-plan`; se não conseguir, o
  item D reabre com essa medida.
- **O `/sdd-plan` que a sua sessão carrega é uma cópia de `commands/sdd-plan.md`:** depois do
  merge, confira que ela acompanha o arquivo (achado aberto "Nada instala nem confere o
  `/sdd-plan` que o `link-agents` manda rodar").
- **Os lotes seguintes:** 73 achados, sem roteiro escrito. O recorte de cada um sai do seu grill.
- **Revisão:** o plano manda abrir o PR e esperar os bots antes do merge; não há REVIEW do runner.
