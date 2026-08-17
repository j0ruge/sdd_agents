---
missao: 20260817-eixo-do-juiz
atualizado: 2026-08-17 12:10
---

# Checkpoint — o eixo do juiz

> **Este arquivo é lido por máquina.** O runner faz parse da tabela abaixo para decidir a
> próxima fase. Não mude as colunas, não mude os tokens de status, não quebre linhas dentro de
> uma célula. Detalhe narrativo vai no `01-plano.md`, não aqui.
>
> ⚠️ **Nada de `|` na célula do Check — nem escapado como `\|`.** O parser é `awk -F'|'` cru e
> não conhece o escape do GFM: a célula vira duas, o Status lido passa a ser um pedaço do
> comando e o Commit passa a ser `pending`. O `gate_EXEC` reprova por "invalid status" e o
> `sdd status` imprime algo de aparência saudável — custou uma missão inteira até alguém olhar.
> Check que precisaria de pipe vira herestring: `` o=$(cmd 2>&1); grep -c 'x' <<< "$o" ``.
>
> ⚠️ **Check que lê a saída de um sensor ancora em `^  ok    ` — quatro espaços, com o `^`.**
> Todo sensor da suíte imprime `  ok    <asserção>` na **stdout** e `  FAIL  <asserção>` na
> **stderr**, com o *mesmo* `<asserção>`. Um Check que faz `2>&1` e grepa o texto solto devolve o
> mesmo número com a asserção verde e com ela vermelha: ele responde "a asserção existe", nunca
> "a asserção passou". Custou uma missão inteira, achado só na fase QA. A forma certa:
> `` o=$(bash tests/check-x.sh 2>&1); grep -c '^  ok    <asserção>' <<< "$o" `` → `1`.
> O sensor é `tests/check-checkpoint.sh`.
>
> Atualizar o checkpoint é o **último ato** de cada incremento — depois do commit, nunca antes.
> Status válidos: `pending` · `doing` · `done` · `blocked`.

| ID | Incremento | Check (comando → esperado) | Status | Commit |
|---|---|---|---|---|
| I1 | ADR 0003: a pergunta que o juiz responde | `o=$(bash tests/check-kaizen.sh 2>&1); grep -c '^  ok    adr 0003' <<< "$o"` → `2` | done | 3547a83 |
| I2 | o runner explica o `indeterminado` estrutural | `o=$(bash tests/check-kaizen.sh 2>&1); grep -c '^  ok    degenerate axis' <<< "$o"` → `2` | done | abac043 |
| I3 | `--all-repos` nos três leitores | `o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    all-repos' <<< "$o"` → `2` | done | d62f08c |
| I4 | identidade de repo sobrevive a worktree | `o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    worktree' <<< "$o"` → `2` | done | c514e36 |
| I5 | linha sem `repo` ganha balde próprio | `o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    no-repo' <<< "$o"` → `2` | pending | — |

## Notas de execução

> Uma linha por evento relevante: bloqueio, decisão tomada, desvio do plano com justificativa.
> É o que a próxima sessão lê para não repetir um erro que já custou caro.

- 2026-08-17 00:20 · `PLAN` · os 5 Checks rodados contra o HEAD: todos `0` (vermelhos), com
  `tests/check-kaizen.sh` e `tests/check-autonomy.sh` rc `0` (verdes) — nenhum Check nasce verde.
- 2026-08-17 00:20 · `PLAN` · os prefixos de asserção são **contrato** com os Checks: `adr 0003`,
  `degenerate axis`, `all-repos`, `worktree`, `no-repo`. Nomear exatamente assim.
- 2026-08-17 00:20 · `PLAN` · **o I1 é um ADR e vem primeiro** — não é "documentação depois". O I2
  cita o número `0003` no código, e a segunda asserção do I1 cobra essa citação.
- 2026-08-17 00:20 · `PLAN` · baseline da mutação nesta branch: **55**; alvo ao fim da missão: 60,
  uma mutação por incremento.
- 2026-08-17 00:20 · `PLAN` · `excluded` e `guard` têm **dois** produtores da mesma shape (o
  programa `jq` e o literal do ledger vazio em `bin/sdd:2382`): campo novo entra nos dois no mesmo
  commit, senão `tests/check-kaizen.sh` reprova comparando-os como conjuntos de chave.
- 2026-08-17 · `EXEC I1` · suíte verde antes de começar, `score: 55`; ao fim, **56**, `sdd health`
  verde nos cinco. As 2 asserções nasceram **vermelhas** (rc 1, contagem 0) e ficaram verdes só
  depois do ADR + da citação.
- 2026-08-17 · `EXEC I1` · **a citação do ADR entrou no `bin/sdd` neste incremento**, não no I2: a
  segunda asserção do I1 cobra que o runner nomeie `ADR 0003`, então o I1 não fecharia sem ela. Ela
  é um comentário no programa `jq`, na linha do piso que o ADR governa. O I2 acrescenta a frase
  **impressa** ao humano — a mutação `KAIZEN_adr_0003_orphan` usa `sed …/g` justamente porque a
  citação passa a existir em mais de um sítio.
- 2026-08-17 · `EXEC I1` · **`docs/adr` entrou no `sandbox()` do `check-mutation.sh`.** Sem isso a
  asserção de forma do ADR morre dentro de todo mutante e o *control run* reprova com
  HARNESS-BROKEN — o comentário do próprio harness já avisava ("a future test reading agents/ or
  docs/"). Copia-se `docs/adr`, nunca `docs/`: os sensores que leem o resto (`check-todo.sh`,
  `check-checkpoint.sh`) são os que o `run-all.sh` guarda sob `SDD_MUTANT`.
- 2026-08-17 · `EXEC I1` · passada de sabotagem adversarial na asserção de forma: degradar o
  título, a linha de data/status e o heading `## Decision` deixa a contagem em **1** nos três
  casos — nenhuma das três regras é decoração. A asserção da citação é provada pelo catálogo.
- 2026-08-17 · `EXEC I2` · suíte verde antes (`score: 56`) e depois (**57**, `0 known gap(s)`),
  `sdd health` verde nos cinco. As 3 asserções nasceram **vermelhas** (rc 1, contagem 0).
- 2026-08-17 · `EXEC I2` · a terceira asserção (sha único ⇒ `false`) fica **fora** do prefixo
  `degenerate axis` de propósito: o Check conta `-c` e exige exatamente `2`. Cláusula nova que
  precise de probe entra com outro nome, nunca com o prefixo que o checkpoint conta.
- 2026-08-17 · `EXEC I2` · sabotagem adversarial, **seis** degrades, todos vermelhos na asserção
  certa: as duas cláusulas do predicado (`> 1` sha; uma sessão por sha), a citação do ADR na
  frase, a chamada de `kaizen_axis_note` em `cmd_kaizen` e a chave no literal do ledger vazio.
  Cada probe conferiu antes que o `sed` mudou o arquivo (`cmp -s`) — probe vazio não conclui.
- 2026-08-17 · `EXEC I2` · **`.claude/agents/` não é gravável por esta sessão**: o harness barra
  `cp` e Edit no caminho. Quem sincroniza é `./bin/sdd install --force`, e o `cmp -s` do
  preflight só fica verde depois disso. Vale para todo incremento que tocar `agents/*.md` — está
  no `TODO.md` (`b7d1c30`).
- 2026-08-17 · `EXEC I2` · métrica da missão medida no repo real: `sdd kaizen --series` devolve
  `guard.degenerate_axis: true` com `sufficient: false`, e `sdd kaizen --dry-run` imprime a
  explicação citando **ADR 0003**. O I3 herda a série já com a chave nova.
- 2026-08-17 · `EXEC I3` · suíte verde antes (`score: 57`) e depois (**58**, `0 known gap(s)`),
  `sdd health` verde nos cinco. As 2 asserções nasceram **vermelhas** (rc 1, contagem 0), falhando
  pelo motivo certo: `autonomy --all-repos` ignorava o argumento e `kaizen --series --all-repos`
  morria em "unknown kaizen option".
- 2026-08-17 · `EXEC I3` · métrica da missão medida no ledger REAL: `sdd autonomy` lê 49 linhas,
  `--all-repos` lê 60; na série, `excluded.other_repo` cai de **11** para **0**. `missions` não
  sobe no ledger real porque o sha corrente tem uma missão só — é o eixo degenerado que o I2
  expôs, não a flag; quem mede a subida é o fixture de dois repos do sensor.
- 2026-08-17 · `EXEC I3` · **os dois setters de `LEDGER_ALL_REPOS=1` são bytes idênticos**, então
  `sed` por linha não os distingue: dois probes de sabotagem "por site" mataram os dois de uma vez
  e quase concluíram falso. Refeitos por número de linha **com prova de que só 1 linha mudou** —
  aí sim, matar o de `cmd_autonomy` deixa a asserção do juiz verde (e vice-versa). É por isso que
  a mutação usa `sed …/g`: matar um site mediria meia flag.
- 2026-08-17 · `EXEC I3` · quatro degrades adversariais, todos vermelhos: flag no-op nos dois
  setters, predicado ignorando o global, e `--all-repos` derrubando toda linha. Nenhuma das duas
  asserções é decoração.
- 2026-08-17 · `EXEC I3` · a mutação chama-se `AUTONOMY_all_repos_ignored` como o plano manda —
  e o cabeçalho do catálogo prometia um "contrato de dois prefixos" (`<GATE>_` ou `RUN_`) que já
  era **falso antes deste commit**: `PRE_`, `RETRY_`, `APPROVE_` e `FRONTMATTER_` existem há
  missões. A frase foi corrigida no mesmo commit, pela convenção do comentário mentiroso — este
  incremento acrescentava o sexto prefixo e a tornaria mais falsa.
- 2026-08-17 · `EXEC I3` · o item correspondente do `TODO.md` ganhou `RESOLVIDO por d62f08c`
  (`e02319b`). **Os itens do I1 e do I2 ainda não têm o seu** — a varredura dos 5 itens que a
  "Verificação end-to-end" do plano cobra continua devendo, e é da fase DOCS.
- 2026-08-17 · `EXEC I4` · suíte verde antes (`score: 58`) e depois (**59**, `0 known gap(s)`),
  `sdd health` verde nos cinco. As 2 asserções nasceram **vermelhas** pelo motivo certo: `3 0`
  esperado contra `1 2` lido, e as duas leituras discordando (`1 2` × `2 1`).
- 2026-08-17 · `EXEC I4` · **o plano dizia "Onde: `bin/sdd:865-869`" e isso não bastava.** Os dois
  construtores de linha carimbavam `--arg repo "$REPO_ROOT"`, então consertar só o leitor deixaria
  escritor e leitor discordando — pior que o defeito. Os dois passaram a resolver `ledger_repo_root`.
  O próprio plano já previa a consequência ("mudar a identidade muda o valor gravado em `repo:`"),
  só não listou o sítio. Escritor e leitor com UMA identidade é o mesmo princípio do predicado único.
- 2026-08-17 · `EXEC I4` · **o short-circuit `if [ -n "$REPO_ROOT" ]` teve de sair**, ao contrário
  do que o plano sugeria ("`$REPO_ROOT` continua respeitado"): `$REPO_ROOT` É o worktree em que a
  sessão roda, então devolvê-lo direto reintroduz a resposta por worktree. Hoje ele é o diretório
  de **partida** da resolução — o probe D da sabotagem mede exatamente isso.
- 2026-08-17 · `EXEC I4` · o par diferencial é **assimétrico de propósito** (1 linha nascida no
  checkout principal, 2 no worktree): quebrado, os dois lados leem `1 2` e `2 1` — discordam, e
  nenhuma troca de lados os faz casar. Simétrico (1 e 1) a asserção diferencial passaria verde no
  código quebrado, porque `1 1` = `1 1`. As linhas vêm do **escritor real** (incremento `blocked`,
  rc 3, zero token); `repo` escrito à mão seria o teste concordando com a própria fórmula.
- 2026-08-17 · `EXEC I4` · sabotagem adversarial, quatro degrades, todos vermelhos e cada um com
  `cmp -s` provando que o `sed` mudou o arquivo: voltar ao toplevel (0/2), escritor com
  `$REPO_ROOT` (1/2), sem `pwd -P` (0/2), short-circuit de volta (1/2).
- 2026-08-17 · `EXEC I4` · a mutação sabota a **definição**, não os sítios de chamada: reverter só
  um lado deixaria escritor e leitor concordando na identidade velha, o par leria `3 0` dos dois
  lados e o mutante sobreviveria medindo nada.
- 2026-08-17 · `EXEC I4` · achado fora de escopo no `TODO.md` (`80cbea2`): `cmd_kaizen`
  (`bin/sdd:2735`) decide "estou no repo do kit?" com `--show-toplevel`, a **mesma** pergunta por
  worktree que o ledger acabou de deixar de fazer — de um worktree do kit o comando recusa rodar.

## Incrementos de fix (QA)

> Escritos pelo `sdd-qa` quando um bug sanável é reprovado. Entram na mesma tabela acima com ID
> `F<n>`, e o Check obrigatoriamente inclui **regression test passa** + **re-walk da jornada
> impactada verde**. Bug que exige julgamento humano NÃO vira fix — vai para
> "Decisions for a Human" no handoff de QA.
