---
missao: 20261121-l5-saida-humana-e-contrato-do-runner
fase: EXEC
status: done
sessao: 01a218bd-1fab-7773-820a-205f8c92cbf0
data: 2026-11-26 14:17
gate: "tests/run-all.sh na árvore de 2defd63 → rc 0, suite green, 21 etapas, 2498 linhas ok, zero FAIL, 884 s. Check R8 → 1 1. Controles R7 → 1 1 e R6 → 1 1 1."
---

# Handoff — EXEC — L5: saída humana e contrato do runner

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

O R8 reduz cada sequência de linhas vazias a uma fronteira de parágrafo.
O leitor e o `sdd close` devolvem a mesma prova com uma ou um milhão de
linhas vazias, dentro de 10 s, sem editar o backlog. A suíte passou.
A QA em disco segue fechada e a próxima REVIEW retesta o delta da r6.

## Estado do repo

- **Branch:** `fix/l5-saida-humana-e-contrato-do-runner`, sem upstream configurado. A referência local `origin/main` é ancestral do branch.
- **Último commit de entrega:** `2defd63` — limita o acúmulo de linhas vazias do backlog.
- **Working tree:** a entrada tinha apenas 262 inserções locais em `checkpoint-notas.md`. Foram preservadas fora dos commits.
- **Suíte:** `tests/run-all.sh` na árvore de `2defd63` → rc 0, suite green, 21 etapas, 2498 linhas ok, zero FAIL, 884 s. O Check R8 passou de `0 0` a `1 1`.
- **E2E:** `E2E_CMD=""`. A QA original percorreu a CLI. O R8 usou Git descartável, sem app, PR ou JIRA reais.

## O que foi feito

### Conserto da REVIEW r6

- `2defd63` (R8) — O leitor guarda só um separador por sequência de linhas vazias.
  Quebras simples continuam no mesmo parágrafo. Os dois sensores comparam a
  prova exata (linha, hash e título), verificam os bytes do backlog e limitam as
  chamadas da entrada longa a 10 s. Antes da correção, ambas venceram pelo
  prazo (rc 124). A lista real permaneceu idêntica, com 21 registros.
  As sabotagens foram executadas em cópia isolada, com grupo próprio,
  prazo de 60 s e 1 GiB por processo. Base `c69f676` → rc 0, 21 etapas e 2496 linhas ok.

### Conserto da REVIEW r5

- `a3518ea` (R7) — O leitor mantém quebras simples no mesmo parágrafo, mas não pareia
  crases nem monta um registro através de uma linha em branco. A lista conserva o título,
  a linha e a prova de ancestralidade da base, omite o exemplo e mantém o backlog byte a byte.
  Os dois sensores reproduziram a troca antes da correção. Nove sabotagens no leitor
  caíram em cópia descartável, em grupo próprio, com teto de 60 s e 1 GiB por processo.

### Consertos da REVIEW r4

- `0426916` (R6) — O leitor de resoluções mascara trechos de código em linha sem juntar
  o texto dos dois lados do trecho. Mantém os registros reais e rejeita os malformados
  fora do código. O alocador lê os modos das entradas imediatas das refs e mantém
  apenas arquivos regulares, incluindo executáveis. O fixture comprova a proposta 0009
  e a origem `refs/heads/other`, apesar de árvore e link com números superiores.
  Os três sensores deram vermelho antes das mudanças. 20 sabotagens caíram em
  cópia descartável, em grupos próprios, com teto de tempo e 1 GiB por processo.

### Consertos da REVIEW r3

- `6ac31be` (R5) — O instalador atualiza os comandos antes de trocar o link do planner. Se uma
  escrita falhar, a próxima tentativa reconhece tanto os links que ficaram na raiz anterior
  quanto os que já apontam para o kit ativo. A regra de comandos em `.gitignore` e o runner
  na raiz antiga, se ainda existir, corroboram a origem. O índice continua protegido.
  O sensor mede a falha no segundo comando, a leitura de ambos após a retomada e a preservação
  do comando local com e sem regra no alvo. Treze mutantes caíram em cópia descartável,
  com grupo próprio, teto de 25 s e 1 GiB por processo. O mutante de catálogo
  `LINK_commands_unlinked` teve a âncora atualizada e caiu em `check-preflight.sh`.

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
| [REVIEW r6](40-review-r6.md) | Reprodução do custo do R8 e ponto de partida da próxima REVIEW delta. |
| [`checkpoint.md`](checkpoint.md) | 25 linhas `done`, cada uma com o Check e o hash alcançável. |
| [Guia PLAN-only](../../plan-only.md#why-the-agents-are-symlinks) | Como reinstalar após mover o kit e quais links ficam intactos. |
| [`01-plano.md`](01-plano.md) | Em “Verificação end-to-end”, os comandos para rechecagem e a jornada de QA. |
| [`TODO.md`](../../../TODO.md) | Em `a033008`, `bash tests/check-todo.sh --check TODO.md` e `--anchors` passaram com 92 âncoras e zero fora do alvo. O Check I18 foi de `0` em `b5a6d57` para `17` em `a033008`, contra o merge-base `60ec571`. `bash tests/check-todo.sh --resolved TODO.md` mostrou os 17 títulos com seus hashes exatos mais os dois registros da base. |
| [REVIEW r5](40-review-r5.md) | Reprodução do R7 e base do próximo delta. |
| [REVIEW r4](40-review-r4.md) | Reprodução dos achados e base do delta. |
| [ADR 0025](../../adr/0025-ids-across-refs-and-the-second-proof-of-a-resolution.md) | Origem dos IDs e segunda prova de resolução. `./bin/sdd adr check --mission 20261121-l5-saida-humana-e-contrato-do-runner --phase plan` passou em `a033008`. |

## Boot da próxima fase

Leia o achado 1 de [`40-review-r6.md`](40-review-r6.md) e a linha R8 de
[`checkpoint.md`](checkpoint.md). Rode `bash tests/check-todo.sh --selftest`
e `bash tests/check-gates.sh`. O leitor deve retornar o mesmo TSV e o
`sdd close` deve listar as mesmas provas com uma ou um milhão de linhas vazias,
sem editar o arquivo. Preserve os dois marcadores R7 e os três controles R6.
Não há app a subir. A QA segue fechada. A próxima REVIEW delta parte de
`2ab5f3469f61c2db62bbd83d4f86a7d804274c8b`, o `reviewed_head` da r6.

### Reteste da REVIEW r5

Leia o achado 1 de [`40-review-r5.md`](40-review-r5.md) e o R7 de
[`checkpoint.md`](checkpoint.md). Rode `bash tests/check-todo.sh --selftest` e
`bash tests/check-gates.sh`. Confira os títulos e as provas de ancestralidade do
`sdd close`, o backlog intacto e o controle que aceita quebras simples dentro do parágrafo.
Os sensores montam seus próprios repositórios, sem app a subir. A QA em disco segue
fechada. A próxima REVIEW delta parte de `1591328ec9e1558c413838e1f8540a2d7518a6cd`, o
`reviewed_head` da r5.

### Reteste da REVIEW r4

Leia os achados 1 e 2 de [`40-review-r4.md`](40-review-r4.md) e a linha R6 de
[`checkpoint.md`](checkpoint.md). Rode `bash tests/check-todo.sh --selftest`,
`bash tests/check-gates.sh` e `bash tests/check-adr.sh`. Confira que o consumidor lista a
prova real sem listar o exemplo com o mesmo hash e mantém o backlog byte a byte. No reteste
do ADR, o maior arquivo regular está só em outra ref, ao lado de entradas que não contam.
A QA em disco segue fechada. Uma nova REVIEW delta parte de
`956004b1576630dba29b2ba6e687bd0852294211`, o `reviewed_head` da r4.

### Reteste da REVIEW r3

Leia os achados 1 e 2 de [`40-review-r3.md`](40-review-r3.md) e o R5 de
[`checkpoint.md`](checkpoint.md). Rode `bash tests/check-preflight.sh`. O fixture move
uma cópia do kit, injeta uma falha na escrita do segundo comando e repete a instalação.
Confira os destinos e o conteúdo dos dois comandos e do planner. Em outro alvo, confirme
que um par local de links com a mesma raiz não basta para substituir o comando, mesmo após
o instalador acrescentar a regra ao `.gitignore`. Não é necessário subir app ou tocar
numa instalação real. A próxima REVIEW usa o `reviewed_head` da r3,
`e919a145222897a75c7074cd7ff0465dc14160c3`, como base do delta.

### Reteste da REVIEW r2

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

- Se uma versão anterior já trocou o link do planner antes de falhar, a referência à raiz
  anterior já foi perdida. O instalador não adivinha a origem e preserva o comando com aviso.
  Com a raiz antiga ausente, a recuperação depende da regra no alvo, dos destinos absolutos
  correspondentes e da ausência do comando no índice.
- Não foram rodados o catálogo inteiro de mutação nem o carimbo. Não houve mudança na catraca, limpeza pós-merge ou instalação em alvos reais.
- Sob squash, a listagem do `sdd close` só usa o head do PR confirmado da própria missão como segunda prova. O alocador de ADR não vê branches que só existem em outra máquina.
- O registro das medidas e do custo em `KAIZEN_LOG.md` é da fase DOCS.
- As edições preexistentes de `checkpoint-notas.md` continuam locais. Cada fechamento incluiu somente as notas novas do próprio incremento.

## Achados fora de escopo

Nenhum achado novo no R8. A contagem histórica de I18 segue no
[registro existente](../../../TODO.md). O R8 não altera esse Check nem o backlog.

Nenhum achado novo no R7. O exemplo antigo do `sdd close` no README e a contagem
histórica de I18 continuam nos dois registros abertos pela r5 em [`TODO.md`](../../../TODO.md).

Nenhum achado novo fora de escopo no R6 ou no R5. O fallback do Git antigo com quebra de linha no caminho
de worktree segue no [backlog](../../../TODO.md), conforme a REVIEW r2. As pendências sobre alocação concorrente de ADR e ajuda do `close` continuam no backlog, conforme a REVIEW r1. Os achados já registrados durante o EXEC seguem em
[`TODO.md`](../../../TODO.md), na subseção “Sensores que faltam”. Incluem a intermitência do probe
do processo residual, os guias ausentes na cópia do catálogo e a preparação do fixture de fast-forward.
