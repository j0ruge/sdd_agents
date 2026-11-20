---
campaign: 20261117-zerar-as-issues
title: Os 83 itens abertos do TODO.md do kit fecham, um lote por missão, e o backlog chega a zero
date: 2026-11-18
harness: claude
plan_model: fable
exec_model: opus
---

# Campanha — Zerar as issues do kit

> Escrita pela missão `20261117-o-worker-orquestrador` (I11), com a fila decidida pelo dono no grill
> de 2026-11-17 (decisões 7 e 8 do `00-missao.md` dela). É a **fila**: o `bin/sdd-worker` lê a
> tabela abaixo para saber qual lote vem agora, e nunca a reescreve. A **permissão** de agir sobre
> ela mora no `delegation.md` ao lado, que nasce sem assinatura: até o dono preenchê-lo e assiná-lo,
> o worker responde `assisted` e não faz nada sozinho.
>
> Cada item é o título de um item aberto do `TODO.md` do kit, copiado de `git show 5221477:TODO.md`.
> O detalhe (a âncora, o porquê, a direção) continua no `TODO.md`, que é a fonte: a campanha só
> ordena. O item sai do `TODO.md` pelo ciclo de sempre (`RESOLVED by <hash>`, apagado depois do
> merge), e a missão de cada lote declara `campaign: 20261117-zerar-as-issues` e `lot: L<n>` no
> frontmatter do seu `00-missao.md`: é por elas que o worker acha a missão de um lote.

## Lotes

> Na ordem da fila: o `next` percorre a tabela de cima para baixo e para no primeiro lote que não
> está mergeado. Os L6a a L6k têm teto `plan`: qualquer que seja o nível assinado, o worker planeja
> a missão de cada um e nunca a aprova nem a mergeia sozinho.

| Lot | Título | Ceiling | Itens |
|---|---|---|---|
| L1 | Prosa de chapéu e docs (piloto) | - | 14 |
| L1b | A rodada delta | - | 1 |
| L2 | O `/sdd-plan` e o planner | - | 14 |
| L3 | Gates do fim da linha | - | 13 |
| L4 | Preflight, health e sensores | - | 14 |
| L5 | Saída humana e contrato do runner | - | 17 |
| L6a | O carimbo tudo ou nada | plan | 1 |
| L6b | A prosa da DOCS sem revisão | plan | 1 |
| L6c | O plano que manda editar em `.claude/` | plan | 1 |
| L6d | O veredito da QA depois de um R<n> | plan | 1 |
| L6e | O platô da REVIEW que lê só as letras | plan | 1 |
| L6f | A QA sem interface que para em `BLOCKED` | plan | 1 |
| L6g | A guarda do kit e o merge só de docs | plan | 1 |
| L6h | O chapéu sem MCP | plan | 1 |
| L6i | O remédio do `qa: skipped` refutado | plan | 1 |
| L6j | O incremento de quase 1 h sem `Monitor` | plan | 1 |
| L6k | O LOW que não move a nota | plan | 1 |

### L1 — Prosa de chapéu e docs (piloto)

> **O piloto do worker sobre o kit.** É a primeira missão do kit rodada sob o worker, por `sdd run`
> no worktree ligado da missão (ADR 0022 §7), nunca a partir do checkout principal. O que acontecer
> nela vai para o caderno do worker, tenha chegado ao merge ou parado.

- [ ] O planner chama a base de `main`, e o alvo pode ter outra
- [ ] O `sdd-executor` lançado como subagente fecha o último incremento e volta sem o `20-handoff-exec.md`
- [ ] A DOCS deixa a lição reincidente só no `KAIZEN_LOG.md`
- [ ] O 3º caso do §0 do QA está só no caminho com interface, e o sem interface chega a ele igual
- [ ] O README chama o repositório de privado, e ele é público
- [ ] O vigia do `sdd run` destacado casa com a própria shell, e o kit não diz como esperar o fim
- [ ] A devolução do planner ao relay não tem regra de idioma
- [ ] O revisor tem de esperar o comando no mesmo turno, sem o `Monitor`, e o harness barra o `sleep`
- [ ] A sonda do revisor fora do repo vai por `Write`, que o `acceptEdits` nega, e filtro sem teste sai rc 0
- [ ] Uma medida no título de um item troca a chave do espelho a cada medição
- [ ] A Check de um item novo no `TODO_FILE` fixa o título e obriga a duplicar
- [ ] A ajuda do `sdd why` não diz que a fase EXEC roda a suíte inteira
- [ ] A receita de merge dos PRs de achado não conta os threads de revisão abertos no head
- [ ] A sabotagem devolve o mutante com `mv`, e o build incremental mede o binário do mutante

### L1b — A rodada delta

> Nasceu depois da campanha, pedido do dono em 2026-11-19 no `/sdd-plan` da leva de aceleração
> (grill, pergunta 2): um lote próprio logo depois do L1, para o `next` achá-lo na fila sem dar o
> L2 por feito. Entrou na tabela antes da assinatura, porque uma linha nova depois dela muda o
> digest e a delegação inteira volta a valer `assisted`.

- [ ] A rodada de revisão relê a missão inteira, porque o chapéu não passa `base=` à skill

### L2 — O `/sdd-plan` e o planner

- [ ] A mitigação de risco que cita um sensor não prova que ele cobre o alvo
- [ ] O `/sdd-plan` não diz o que fazer quando a sessão do relay cai no meio do grill
- [ ] Commit do relay no meio do grill muda o HEAD que o planner mediu, e só o worktree é vigiado
- [ ] ◆ O aceite do `/sdd-plan` mede de novo os Checks, nunca os fatos do contexto verificado
- [ ] ◆ Sob `aprovacao: auto` o `/sdd-plan` deixa a missão sem commit na base e cala o passo seguinte
- [ ] O planner marca o `- answer:` de pergunta que o humano não viu, e sob `auto` o gate já lê aprovado
- [ ] O `/sdd-plan` só manda para worktree no checkout do kit, não com outra missão em voo no alvo
- [ ] Com o passo 2 pulado, o `/sdd-plan` não olha o branch antes de o planner ler o repo
- [ ] O relay não prevê que o job em background do planner repete a pergunta já feita
- [ ] O aceite do `/sdd-plan` só olha três caminhos no `git status`
- [ ] O `/sdd-plan` delega ao planner sem olhar a árvore do alvo nem as missões que já existem
- [ ] O plano que executa fora do `sdd run` promete o gate do EXEC sem o `20-handoff-exec.md`
- [ ] ◆ O `/sdd-plan` não diz o que fazer com respostas do grill delegadas por escrito
- [ ] O `--red` do aceite pode rodar ao lado da run de outra missão na mesma máquina, sem aviso

### L3 — Gates do fim da linha

- [ ] O `gate_PR` só prova que o PR existe, não que o head dele é o que a missão fechou
- [ ] ◆ O registro do PR nasce depois do push e fica fora do sha verificado
- [ ] O `gate:` cita saídas que a pasta de evidência da fase não guarda
- [ ] ◆ A REVIEW aprovada não vê o código que entrou depois dela
- [ ] Numa worktree sem o `.venv`, o gate do EXEC lê o `TEST_CMD` que não rodou como suíte vermelha
- [ ] O `gate_PR` não lê o `status: blocked` do `50-pr.md`, e o runner compra outra sessão do publisher
- [ ] O publisher bloqueado manda o humano fazer `git rebase`, e o rebase tira os hashes dos handoffs da história
- [ ] A linha `kit:` do handoff não tem quem a transporte
- [ ] ◆ O "Como verificar" do PR copia o `$SDD_HOME` do `TEST_CMD`, e o comando falha fora do runner
- [ ] O motivo do gate_QA não diz se o caso e2e vermelho já caiu antes
- [ ] ◆ O K8 lê o branch em que se está, e diz "the mission branch"
- [ ] ◆ O corpo do PR copia pendência do plano que a revisão já fechou
- [ ] O `gh pr edit` que o publisher e o `gate_PR` mandam usar não edita o corpo no `gh` 2.45

### L4 — Preflight, health e sensores

- [ ] ◆ O `sdd preflight` não mede a forma do `TODO_FILE`, e nada avisa o alvo sem o opt-in
- [ ] Nada avisa que o clone do kit está velho ou fora da `main`
- [ ] O `sdd preflight` diz "preflight ok" com um `TEST_CMD` que deixa servidor vivo
- [ ] O `writes:` do `sdd-kaizen` não é cobrado: o `cmd_kaizen` não passa pela guarda do chapéu
- [ ] O `atualizado:` do checkpoint aceita hora inventada, até no futuro
- [ ] A sonda do `Bash` do `sdd preflight` dá `ok` pela resposta, nunca pelo comando rodado
- [ ] ◆ O `sdd run` paga a REVIEW sem avisar que o `READ_EXTRA` não cobre o `codereview`
- [ ] A sonda de interrupção do `check-health.sh` mede o grupo antes do `setsid`, e a suíte cai sem defeito
- [ ] `PR #N` de outro repositório passa pelo `check-todo.sh` e vira link errado na issue
- [ ] ◆ O cabeçalho do `TODO.md` semeado pelo `install` não acompanha o template
- [ ] O `sdd preflight` reprova a árvore suja sem dizer os caminhos, nem que eram só não versionados
- [ ] O `sdd preflight` imprime "printf: erro de escrita: Pipe quebrado" com a `READ_EXTRA` preenchida
- [ ] O lint da suíte se pula sem o `shellcheck`, e a `main` já tem 4 avisos que ele reprova
- [ ] O `sdd run` num worktree do alvo manda `install --force`, e o que falta é o `link-agents`

### L5 — Saída humana e contrato do runner

- [ ] ◆ O ciclo de vida do `RESOLVED by` não sobrevive a squash merge
- [ ] A prosa congelada diz a regra 2 e o teto de largura mais estritos que os sensores
- [ ] O remédio do `sdd kaizen` recusado ensina a mesma receita sem `--no-track`
- [ ] ◆ A primeira instalação semeia o `TODO.md` em inglês, qualquer que seja o idioma
- [ ] ◆ Nada instala nem confere o `/sdd-plan` que o `link-agents` manda rodar
- [ ] Num subcomando, `-l` escolhe a missão que tem `-l` no nome, e `--help` vira "mission not found"
- [ ] A citação "ADR 0018" do kit colide com o ADR 0018 do alvo
- [ ] O `PR #N aberto` que a fase PR escreve no roadmap e no `KAIZEN_LOG.md` envelhece no merge
- [ ] O `sdd status --no-gates` roda o `git status` sem `GIT_OPTIONAL_LOCKS=0` sobre a run em voo
- [ ] O `sdd status` manda `sdd run` com o app fora do ar, e a fase fechada volta a pendente
- [ ] O fim da corrida diz que só falta o merge, e o `sdd close` some
- [ ] ◆ O pós-merge não lista o `RESOLVED by` que já pode sair
- [ ] O `sdd run` diz que commita na base quando a TICKET vai cortar o branch antes
- [ ] ◆ A ajuda do `sdd run` não diz como soltá-lo da sessão que o dispara
- [ ] O lembrete do `sdd kaizen` não vê o backlog nem diz o custo
- [ ] O `CHECKOUT-BUSY` do `sdd status` não aponta o `--no-gates`, que lê o disco com a run em voo
- [ ] ◆ O `sdd adr new` dá a uma branch o número que outra branch sem merge já usa

### L6a a L6k — Desenho, um lote por item

> Itens de desenho, com teto `plan`: as escolhas deles não são tomadas por um grill sem o dono. Um
> lote por item, e uma missão por lote (decisão do dono na r5 da missão
> `20261117-o-worker-orquestrador`): o `next` acha a missão de um lote pelo `lot:` e dá o lote por
> feito no merge dela, então um lote de onze itens fecharia no primeiro merge, com dez abertos.
>
> A decisão 8 vale para os sete `◆` daqui como para os outros: sob delegação, o grill segue a opção
> recomendada pelo planner, e o corpo do PR lista a escolha para o aceite do dono. O que segura a
> escolha é o teto `plan`: o worker planeja, e o dono lê e aprova cada plano (`sdd approve`) antes
> de o EXEC começar, e mergeia ele mesmo.

#### L6a — O carimbo tudo ou nada

- [ ] O carimbo é tudo ou nada: uma linha de prosa em `agents/` refaz o catálogo inteiro

#### L6b — A prosa da DOCS sem revisão

- [ ] ◆ A prosa que a DOCS escreve depois da REVIEW não passa por revisão nenhuma

#### L6c — O plano que manda editar em `.claude/`

- [ ] ◆ O plano manda o EXEC editar em `.claude/`, o `claude -p` recusa, e a sessão contorna pelo Bash

#### L6d — O veredito da QA depois de um R<n>

- [ ] ◆ O veredito da QA não é revalidado depois de um R<n>

#### L6e — O platô da REVIEW que lê só as letras

- [ ] O platô da REVIEW lê só as letras, e pararia um laço que converge

#### L6f — A QA sem interface que para em `BLOCKED`

- [ ] ◆ Num repo sem interface, a QA para em `BLOCKED` ao seguir a própria instrução de escrever o teste do achado

#### L6g — A guarda do kit e o merge só de docs

- [ ] ◆ A guarda do kit para a corrida do alvo por um merge só de docs no checkout do kit

#### L6h — O chapéu sem MCP

- [ ] O chapéu não pode declarar MCP, e o executor fica sem o REA

#### L6i — O remédio do `qa: skipped` refutado

- [ ] ◆ O remédio do `qa: skipped` refutado apaga, com o handoff, os achados fora de escopo dele

#### L6j — O incremento de quase 1 h sem `Monitor`

- [ ] Um incremento que roda por quase 1 h não cabe no `sdd-executor`, que não tem `Monitor`

#### L6k — O LOW que não move a nota

- [ ] ◆ O revisor não tem destino para o LOW que não move a nota

## Os itens marcados com ◆ (decisão 8)

Os 24 itens com `◆` deixam uma escolha em aberto. Sob delegação, o grill da missão segue a opção
recomendada pelo planner, e o corpo do PR lista cada um deles, com a escolha feita, para o aceite
do dono. Por lote: L1 nenhum, L2 3, L3 5, L4 3, L5 6, e 7 nos L6a a L6k (um em cada um dos L6b, L6c,
L6d, L6f, L6g, L6i e L6k), onde o teto `plan` faz o dono aprovar cada plano antes do EXEC.

## A régua do "tudo ok" (decisão 9)

O worker só mergeia (nível `merge` ou acima, e nunca nos L6a a L6k) com os cinco itens verdadeiros
no mesmo sha, lidos por `bin/sdd-worker pr-ready <dir-da-missão> <pr>`, que responde `ready <sha>`:

1. a rodada de revisão mais nova nomeia o head (`reviewed_head:`) e dá A em todo critério, cada A
   com uma justificativa que não é preenchimento, e o `gate:` dela traz a evidência;
2. o recibo do Codex (`codex-review-state:v1`) é desse sha, `completed`, sem achado aberto;
3. nenhum thread de revisão aberto;
4. o PR está `OPEN` e `MERGEABLE`;
5. o `HEAD` local é o head do PR, e o merge é `gh pr merge --merge --match-head-commit <sha>`:
   sempre merge commit, nunca squash.

O recibo do Codex é o item 2, e sem ele não há merge: o Codex que não responde é a parada
`no-receipt`. Qualquer outro bot sem cota conta como "não revisou": é declarado no corpo do PR e
não bloqueia.

## As paradas (decisões 9 e 10)

Cada parada chama o `ON_ESCALATION_CMD`, grava uma linha no `journal.md` desta campanha e devolve o
caso ao dono, com os nomes do `commands/sdd-worker.md`:

1. `no-receipt`: o Codex não deixou recibo no head 60 minutos depois do pedido explícito
   (`@codex review`);
2. `below-a`: um critério segue abaixo de A depois de 3 rodadas de revisão no mesmo PR;
3. `conflict`: o merge da `main` na branch dá conflito fora do `TODO.md` e da catraca
   (`tests/health-baseline.txt`);
4. `mission-ceiling`: o `sdd run` parou em `budget-exhausted`, a missão gastou o
   `budget_mission_usd`, que chega a ele como `BUDGET_MISSION_USD`; ou o `bin/sdd-worker budget`
   respondeu `no mission cap — …`, porque o `.sdd/config.sh` do checkout da campanha ou de um
   worktree de missão dela fixa essa chave acima do teto assinado, ou porque a delegação assina um
   `budget_mission_usd: 0`, que o runner lê como sem teto, ou um abaixo de `0.01`;
5. `campaign-ceiling`: `bin/sdd-worker budget` sai com rc 1 na linha `campaign US$ <gasto> of
   <teto>`, a campanha gastou o `budget_campaign_usd` que ele mediu; só nessa linha.

Uma linha que não mediu parada também para e avisa, com o nome do que o verbo imprimiu: o
`stop …` do `next` é `next-stop`, o `no ceiling — …` do `budget` (delegação ausente ou ilegível) é
`no-ceiling`, e o `no spend — …` (fora de um checkout, o `git worktree list` que falhou, o ledger
que não se lê) é `no-spend`. Nenhuma delas é `campaign-ceiling`: ninguém mediu gasto nenhum.

Uma linha `no room — …` do `budget` mediu gasto abaixo do teto, mas o que resta dele é menor que o
teto de missão assinado: o `run` seguinte passaria do teto da campanha, e a linha para antes de
qualquer ato, o merge incluso, com o nome `no-room`. Ela também não é `campaign-ceiling`, o gasto que
atingiu o teto; para seguir, o dono assina um teto de campanha maior ou um teto de missão de no
máximo o que resta.

Sem `ON_ESCALATION_CMD` no `.sdd/config.sh` de algum checkout do kit (o desta campanha ou o worktree
de uma missão, onde o `sdd run` roda e avisa), toda delegação acima de `assisted` vale `assisted`
(decisão 10): o aviso que chega ao dono é condição para o worker agir sozinho.

Não é parada: com o PR aberto e só o carimbo de mutação faltando, o `sdd run` de uma missão do kit
sai com rc 2 e pede `./bin/sdd health`. Pela regra do dono (PR de missão do kit mergeia sem
carimbo; o `sdd health` só roda com a catraca zerada), esse rc 2 se lê como o rc 0: o PR está
aberto, e o ato seguinte é o `pr` (a tabela `## The transitions` do `commands/sdd-worker.md`).
