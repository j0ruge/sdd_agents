---
missao: 20261121-l5-saida-humana-e-contrato-do-runner
fase: EXEC
status: done
sessao: 01a2167b-75b7-7110-a482-a1a50796b614
data: 2026-11-26 03:53
gate: "tests/run-all.sh na árvore gravada em b23f936 → rc 0, suite green, 21 etapas, 2486 linhas ok e zero FAIL. Check R4 → 1 1 1."
---

# Handoff — EXEC — L5: saída humana e contrato do runner

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

O R4 fechou o último incremento. A reinstalação recupera os links de comando do kit antigo, mesmo quebrados,
e preserva rascunhos e links locais. A suíte ficou verde. A próxima REVIEW retesta o delta da r2.

## Estado do repo

- **Branch:** `fix/l5-saida-humana-e-contrato-do-runner`, sem upstream configurado. A referência local `origin/main` é ancestral do branch.
- **Último commit de entrega:** `b23f936` — recuperação dos links de comandos do R4.
- **Working tree:** as 259 inserções preexistentes em `checkpoint-notas.md` foram preservadas fora dos commits.
- **Suíte:** `tests/run-all.sh` na árvore gravada em `b23f936` → rc 0, `suite green`, 21 etapas, 2486 linhas `ok` e zero `FAIL`. O Check R4 passou de `0 0 1` para `1 1 1`.
- **E2E:** `E2E_CMD=""`. A QA original percorreu a CLI. As regressões das revisões foram retestadas em Git de rascunho, sem app, PR ou JIRA reais.

## O que foi feito

### Conserto da REVIEW r2

- `b23f936` (R4) — Ao reinstalar, o `link-agents` usa o destino absoluto do agente `sdd-planner.md`
  anterior para reconhecer e restaurar links de comandos do kit fora do índice. O fixture usa duas
  instalações e mede destino, leitura e preservação dos rascunhos, dos links locais e do índice.
  Onze mutantes caíram em cópia descartável com grupo próprio, teto de 90 s e 1 GiB.

### Consertos da REVIEW r1

- `21482a2` (R1) — O instalador preserva comandos locais conflitantes e ainda liga os comandos ausentes.
- `4376e32` (R2) — Se Git recusar a saída NUL, o alocador lê a saída alternativa e respeita ADRs ainda não commitados em outros worktrees.
- `234b734` (R3) — O analisador omite itens com qualquer valor de resolução malformado. As duas provas do `close` usam objetos commit e não refs homônimas. O `run` avisa na base antes de pular a atribuição de branch ao forçar EXEC.

### Entrega original

- `436b1f2` (I1) — O alocador de ADR lê refs locais e remotos e o disco dos worktrees, e nomeia a origem do máximo.
- `8718ccf` (I2) — O instalador de links liga comandos, e o preflight avisa onde instalar o `/sdd-plan`.
- `03091ed` (I3) — A ajuda do `sdd run` mostra como soltar a corrida e onde acompanhar seu progresso.
- `012044b` (I4) — As consultas de estado do runner e do worker deixam de reescrever o índice.
- `f7709e3` (I5) — Um argumento de missão iniciado por hífen é recusado em vez de casar por substring.
- `0fe8217` (I6) — A receita do `sdd kaizen` recusado cria o worktree sem rastrear a base.
- `1f8b722` (I7) — A recusa por checkout ocupado aponta para `sdd status --no-gates`.
- `51203f0` (I8) — Com QA fechada e app fora, o status indica restaurar o app e preserva o estado da fase.
- `70c956f` (I9) — O fim da corrida, o status e o template de PR nomeiam o `sdd close` pós-merge.
- `5348c7d` (I10) — Os templates registram as duas provas de resolução, e o sensor lista os hashes do backlog.
- `891712d` (I11) — O `sdd close` lista apenas achados com resolução comprovada, sem apagar itens.
- `e30971f` (I12) — O `sdd close` identifica linhas que ainda dão o PR mergeado como aberto.
- `f27e0f8` (I13) — O aviso de commit na base não aparece em run ou retry se a TICKET ainda vai cortar o branch.
- `ca5260b` (I14) — O lembrete do `sdd kaizen` informa o backlog e o teto de uma sessão.
- `0c457ab` (I15) — O `sdd install` troca somente a semente intocada de outro idioma, e o preflight indica a saída.
- `3faad6c` (I16) — A prosa da regra de âncora e do teto de largura passou a dizer o que os sensores medem.
- `dfd5f25` (I17) — As citações do ADR identificam o kit para não colidir com a numeração do alvo.
- `a033008` (I18) — Os 17 achados receberam o hash do incremento que os resolveu, sem baixar a catraca.

## Artefatos

| Arquivo | O que contém |
|---|---|
| [`checkpoint.md`](checkpoint.md) | 22 linhas `done`, cada uma com o Check e o hash alcançável. |
| [Guia PLAN-only](../../plan-only.md#why-the-agents-are-symlinks) | Como reinstalar após mover o kit e quais links ficam intactos. |
| [`01-plano.md`](01-plano.md) | Em “Verificação end-to-end”, os comandos para rechecagem e a jornada de QA. |
| [`TODO.md`](../../../TODO.md) | Em `a033008`, `bash tests/check-todo.sh --check TODO.md` e `--anchors` passaram com 92 âncoras e zero fora do alvo. O Check I18 foi de `0` em `b5a6d57` para `17` em `a033008`, contra o merge-base `60ec571`. `bash tests/check-todo.sh --resolved TODO.md` mostrou os 17 títulos com seus hashes exatos mais os dois registros da base. |
| [ADR 0025](../../adr/0025-ids-across-refs-and-the-second-proof-of-a-resolution.md) | Origem dos IDs e segunda prova de resolução. `./bin/sdd adr check --mission 20261121-l5-saida-humana-e-contrato-do-runner --phase plan` passou em `a033008`. |

## Boot da próxima fase

Leia o achado 1 de [`40-review-r2.md`](40-review-r2.md) e o R4 de [`checkpoint.md`](checkpoint.md).
Rode `bash tests/check-preflight.sh`. O fixture cria os links com a CLI da instalação anterior
em dois alvos temporários, roda a CLI nova com a instalação antiga legível em um alvo e move
a instalação antiga antes de rodá-la no outro. Confira o caminho novo em `readlink` e a leitura
de `/sdd-plan`. Os rascunhos e os links locais ou rastreados ficam intactos, inclusive no índice.
O fixture não precisa de app nem de instalação real. A QA em disco segue fechada. A próxima
REVIEW parte do `reviewed_head` da r2, `86b48881f08fde1063a7c66fcc66a79e1264866d`.

### Retestes da REVIEW r1

Para o reteste de QA da rodada r1, leia os achados 1 a 5 de [`40-review-r1.md`](40-review-r1.md) e
as linhas R1 a R3 de [`checkpoint.md`](checkpoint.md). Rode `bash tests/check-preflight.sh` para
a preservação dos comandos locais, `bash tests/check-adr.sh` para o Git sem `-z` e
`bash tests/check-todo.sh --selftest` e `bash tests/check-gates.sh` para o Check R3.
No `close`, confirme que um valor inválido impede a listagem do item inteiro e que refs
homônimas não provam ancestralidade. Os controles abreviados válidos devem aparecer tanto pela
base quanto pelo head do PR `MERGED`. Compare o aviso do `run --phase EXEC --dry-run` na base
com a projeção normal de TICKET. Os sensores montam seus próprios repositórios e stubs.

### Jornada original de QA

Leia `00-missao.md`, `01-plano.md` (seção “Verificação end-to-end”) e `checkpoint.md`.
Rode `tests/run-all.sh` e refaça o Check I18. No fechamento, os 28 mutantes nomeados no plano
estavam catalogados e `bash tests/check-mutation.sh --anchors` passou com 1017 âncoras válidas. Compare também os seis
espelhos em `.claude/agents/` com `agents/`.

Num Git de rascunho, fora deste worktree e com home e estado descartáveis, use os binários pelo
caminho absoluto deste checkout. Rode `sdd install` com idioma vazio e repita após ajustar
`OUTPUT_LANG="pt-BR"`. Confira a troca da semente intocada e a preservação de um TODO editado.
Rode `sdd-link-agents` e confira os links de `sdd-plan.md` e `sdd-worker.md`, inclusive na repetição.
`sdd why -l` deve recusar a opção mesmo com missão de nome parecido. Leia a forma destacada em
`sdd help`, sem disparar uma corrida em segundo plano. Em dois branches com números distintos de ADR,
`sdd adr new --slug x --dry-run` deve propor o próximo ID após o maior.

Para a saída do runner, siga os controles de `tests/check-gates.sh` e `tests/check-kaizen.sh`.
Compare QA fechada com app fora e respondendo, fim da corrida com e sem JIRA, e o `sdd close` em
árvore limpa com merge confirmado e sem prova de merge. O `close` só lista e não edita o backlog.
Use fixtures para merge e JIRA, sem abrir, fechar ou mesclar PRs reais.

## Pendências / Decisions for a Human

- Confirmar no PR as escolhas feitas por delegação e, separadamente, a segunda prova do `RESOLVED by` sob squash. Ver pendências 2 e 4 de `00-missao.md`.
- O dono decide as alterações marcadas com `⛔` que a DOCS proporá em `CLAUDE.md` e na regra da anatomia.
- Decidir se o `sdd run` deve evitar abrir uma sessão de QA antes de escalar um app fora do ar. Este lote corrigiu só a orientação do `sdd status`.
- Deixar o yokoten, o retrofit de `todo-to-github-issues` e a remoção dos 17 itens para depois do merge.

## Riscos e não-feitos

- Sem o link anterior do agente `sdd-planner.md`, a origem não pode ser confirmada e o comando
  permanece intacto com aviso. Isso inclui uma tentativa anterior que já migrou o agente, mas
  deixou o comando apontado para a instalação anterior.
- Não foram rodados o catálogo inteiro de mutação nem o carimbo. Não houve mudança na catraca, limpeza pós-merge ou instalação em alvos reais.
- Sob squash, a listagem do `sdd close` só usa o head do PR confirmado da própria missão como segunda prova. O alocador de ADR não vê branches que só existem em outra máquina.
- O registro das medidas e do custo em `KAIZEN_LOG.md` é da fase DOCS.
- As edições preexistentes de `checkpoint-notas.md` continuam locais. Cada fechamento incluiu somente as notas novas do próprio incremento.

## Achados fora de escopo

Nenhum achado novo fora de escopo no R4. O fallback do Git antigo com quebra de linha no caminho
de worktree segue no [backlog](../../../TODO.md), conforme a REVIEW r2. As pendências sobre alocação concorrente de ADR e ajuda do `close` continuam no backlog, conforme a REVIEW r1. Os achados já registrados durante o EXEC seguem em
[`TODO.md`](../../../TODO.md), na subseção “Sensores que faltam”. Incluem a intermitência do probe
do processo residual, os guias ausentes na cópia do catálogo e a preparação do fixture de fast-forward.
