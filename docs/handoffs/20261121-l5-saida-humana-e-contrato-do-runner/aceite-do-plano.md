# Aceite do plano — L5: saída humana e contrato do runner

> Extrato que o dono leria antes do `sdd approve` (ato `approve` do `commands/sdd-worker.md`). A sessão
> orquestradora o escreveu em 2026-11-21, sobre `86e16c0`. A fonte é o `00-missao.md` e o `01-plano.md` ao lado, e
> este arquivo não os substitui.
>
> A ordem do dono em vigor vale como o `YES` do aceite, depois da medida e deste extrato: "o worker assina, aprova
> e mergeia", sob a delegação `full` assinada até 2026-11-26 18:00. O `allows approve` respondeu
> `allowed approve at full`. O planner rodou em Fable, com `model: fable` passado na chamada.

**Goal:** os 17 itens do L5 fecham, cada um com asserção e com o mutante que a prova:
- o runner diz ao humano o passo seguinte que vale (a ajuda, o `CHECKOUT-BUSY`, o `sdd status`, o fim da corrida);
- o `sdd close` lista o que o merge fechou, sem apagar nada;
- o `sdd adr new`, o `sdd-link-agents` e o `sdd install` deixam de depender de alguém lembrar.

**Architecture:** nenhuma arquitetura nova. São dezessete consertos em cinco lugares.
- **A saída do runner** (`bin/sdd`): a ajuda (I3), o `CHECKOUT-BUSY` (I7), o rodapé do `sdd status` (I8, I9), o fim
  do `sdd run` (I9), o aviso da base (I13), o lembrete do juiz (I14), o remédio do `sdd kaizen` (I6) e a recusa do
  argumento com hífen (I5).
- **O `sdd close`:** ganha duas listas depois do fast-forward (I11, I12). A leitura dos itens resolvidos é o modo
  novo `check-todo.sh --resolved` (I10), e o `bin/sdd` não ganha um segundo parser do `TODO.md`.
- **Três contratos:** o `adr_next_id` lê o disco, os refs e os outros worktrees (I1); o `cmd_link_agents` liga também
  `commands/sdd-*.md` (I2); o `cmd_install` troca a semente intocada de outro idioma (I15). O `cmd_preflight` ganha
  dois avisos (I2, I15).
- **Duas leituras de `git status`** com `GIT_OPTIONAL_LOCKS=0` (I4).
- **A prosa:** os dois templates do `TODO.md` (I10, I16), o `templates/checkpoint.md` e dois chapéus (I16), as 11
  citações de ADR (I17), o `templates/pr-body.md` (I9) e o `agents/sdd-kaizen.md` (I10).

**Tech Stack:** bash (`bin/sdd`, sensores em `tests/`) e markdown. São 46 frases de asserção e 28 mutantes novos. A
catraca não se move nesta missão. ADR nova: `docs/adr/0025-ids-across-refs-and-the-second-proof-of-a-resolution.md`,
que emenda a 0008.

## Restrições

- **Escopo:** os 17 itens da tabela do `00-missao.md`.
- **Fora do escopo:**
  - o catálogo inteiro e o carimbo;
  - `tests/health-baseline.txt`;
  - `CLAUDE.md` e `.claude/rules/`, que vão em linhas `⛔` na DOCS;
  - um `sdd run --detach` e um `--after <n>` no `sdd adr new`;
  - apagar itens resolvidos pelo `sdd close`, que só lista;
  - a skill `todo-to-github-issues` (outro repositório);
  - a metade do item 10 que é do `sdd run` (pendência 5).
- **Grill:** `10 (recommended) of 10`, em 9 decisões (a 5 perguntada duas vezes). Todas foram **delegadas** por
  escrito ao worker, sem que o dono as visse na hora.
  - Os seis ◆: 2 (o `adr new` lê refs e worktrees), 3 (o `link-agents` liga os comandos), 4 (a ajuda mostra a
    forma destacada), 5 (duas provas para um `RESOLVED by` sair), 6 (o `sdd close` só lista) e 7 (o `install` troca
    a semente intocada).
  - As outras: 1 (o id e o branch), 8 (uma ADR que emenda a 0008) e 9 (`kaizen_log:` vazio). Os mecanismos do
    planner, decididos sem pergunta, são os itens 10 a 18. Tudo vai ao corpo do PR para o aceite do dono.
  - **⚠️ A decisão 5 contradiz o `CLAUDE.md:152`** ("provado por `git merge-base --is-ancestor`, nunca pelo rótulo do
    PR"). A segunda prova é escrita como dois comandos: o `is-ancestor` no head do PR e o `MERGED` lido do `gh`. A
    frase do dono só muda por linha `⛔` da DOCS, e o PR a destaca. Se o dono recusar, revertem-se o I10 e o braço
    do head do PR no I11.
- **Ordem com o L4:** o `sdd run` só começa depois do merge do L4. Antes, entram `git merge origin/main` aqui,
  `--anchors`, `--check` e `--red` de novo (pendência 1). O I15 daqui e o I5 do L4 tocam o mesmo braço do
  `cmd_install`.
- **Effort:** a EXEC roda em `medium`, o padrão do `.sdd/config.sh`. É lançada sem `EFFORT_*` e sem o `CLAUDE_EFFORT`
  do ambiente.

## Tarefas

Cada tarefa traz a asserção vermelha antes, a implementação, o verde, o mutante provado com `--only`, o lint, a
suíte e o commit. O Check de cada linha está no `checkpoint.md`. Os quatro reincidentes abrem a ordem (I1 a I4).

### I1 — o `sdd adr new` lê os números de todo ref e de todo worktree (item 17, decisão 2)
### I2 — o `link-agents` liga os comandos do kit, e o preflight avisa a falta do `/sdd-plan` (item 5, decisão 3)
### I3 — a ajuda do `sdd run` mostra a forma destacada e onde ler o progresso (item 14, decisão 4)
### I4 — o `git status` de leitura não reescreve o índice (item 9)
### I5 — o argumento de missão que começa com hífen é recusado (item 6)
### I6 — o remédio do `sdd kaizen` recusado leva `--no-track` (item 3)
### I7 — o `CHECKOUT-BUSY` aponta o `sdd status --no-gates` (item 16)
### I8 — o `sdd status` com o app fora do ar manda subir o app (item 10)
### I9 — o fim da corrida, o `sdd status` e o corpo do PR nomeiam o `sdd close` (item 11)
### I10 — o ciclo de vida diz as duas provas, e o `check-todo.sh` lista os resolvidos (item 1, decisão 5)
### I11 — o `sdd close` lista os `RESOLVED by` que já podem sair (item 12, decisão 6)
### I12 — o `sdd close` lista as linhas que ainda dão o PR mergeado como aberto (item 8)
### I13 — o `sdd run` não grita que commita na base quando a TICKET vai cortar o branch (item 13)
### I14 — o lembrete do `sdd kaizen` diz o backlog e o custo (item 15)
### I15 — o `sdd install` troca a semente intocada de outro idioma (item 4, decisão 7)
### I16 — a prosa diz a regra 2 e o teto de largura como os sensores medem (item 2)
### I17 — a citação de ADR do kit nomeia o kit (item 7)
### I18 — fecho (`RESOLVED by` nos 17 itens)

## PLAN-AUTO

Os seis critérios estão ✅:
- **a:** o grill fechou com 10 respostas em 9 decisões;
- **b:** o checklist kaizen K1–K8 está ✅, e o DDD é `n/a`;
- **c:** o teste de autocontenção foi lido incremento a incremento;
- **d:** são 18 Checks vermelhos;
- **e:** `JIRA_ENABLED=false`;
- **f:** `adr:` é a 0025, alocada por `sdd adr new`, e o `sdd adr check --phase plan` respondeu rc 0.

`aprovacao:` está vazio, por regra.

## A medida de novo, pelo relay

- `tests/check-checkpoint.sh --check …/checkpoint.md` → `ok    checkpoint.md: 18 row(s), 17 under the anchor rule, none blind`, rc 0 (18:50).
- `tests/check-checkpoint.sh --red …/checkpoint.md` → `ok    checkpoint.md: 18 pending Check(s), every one red at HEAD`,
  rc 0, 0 FAIL, de 18:49:50 a 19:10:43, em `nice -n 19` ao lado do `sdd run` do L4 (outro worktree). Cada Red é igual
  ao "O vermelho medido" do plano: I1 `0 0 0 0`, I2 `0 0 0 0 0`, I3 a I5 `0 0`, I6 `0 0` (quer `1 2`), I7 `0`, I8 e
  I9 `0 0 0`, I10 e I11 `0 0 0 0`, I12 a I14 `0 0`, I15 e I16 `0 0 0 0`, I17 `0 0` e I18 `0` (quer `17`).
- O `sdd run` do L5 **não** sai deste aceite: espera o merge do L4, a `main` neste branch e a medida de novo
  (pendência 1).
