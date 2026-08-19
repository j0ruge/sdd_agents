---
missao: 20260818-lote-facil
atualizado: 2026-08-18 23:59
---

# Checkpoint — O `sdd health` para de morrer calado, e 18 achados baratos saem do backlog

> **Este arquivo é lido por máquina.** O runner faz parse da tabela abaixo para decidir a próxima
> fase. Não mude as colunas, não mude os tokens de status, não quebre linhas dentro de uma célula.
> Detalhe narrativo vai no `01-plano.md`, não aqui.
>
> ⚠️ **Nada de `|` na célula do Check — nem escapado como `\|`.** O parser é `awk -F'|'` cru.
> Check que precisaria de pipe vira herestring, como os cinco abaixo já fazem.
>
> ⚠️ **Check que lê saída de sensor ancora em `^  ok    ` — quatro espaços, com o `^`.** Grepar o
> texto solto devolve o mesmo número com a asserção verde e com ela vermelha.
>
> Atualizar o checkpoint é o **último ato** de cada incremento — depois do commit, nunca antes.
> Status válidos: `pending` · `doing` · `done` · `blocked`.

| ID | Incremento | Check (comando → esperado) | Status | Commit |
|---|---|---|---|---|
| I1 | A família do aborto calado — 4 sítios do `cmd_health` | `o=$(bash tests/check-health.sh 2>&1); grep -c '^  ok    abort: ' <<< "$o"` → `4` | done | 4f11624 |
| I2 | A família do `cd` relativo — 14 em `tests/` mais o `ledger_repo_root` | `o=$(bash tests/run-all.sh 2>&1); grep -c '^  ok    cdpath: ' <<< "$o"` → `3` | done | aa95b2e |
| I3 | Saída humana do runner — 3 números que contam a grandeza errada | `o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    output: ' <<< "$o"` → `9` | done | 4f6aa8b |
| I4 | Cinco caminhos sem asserção ganham asserção e mutação | `o=$(bash tests/run-all.sh 2>&1); grep -c '^  ok    covered: ' <<< "$o"` → `5` | done | f21df55 |
| I5 | Regras de sensor e o `templates/review.md` que falta | `o=$(bash tests/run-all.sh 2>&1); grep -c '^  ok    rule: ' <<< "$o"` → `5` | pending | — |

## Notas de execução

> Uma linha por evento relevante: bloqueio, decisão tomada, desvio do plano com justificativa.
> É o que a próxima sessão lê para não repetir um erro que já custou caro.

- 2026-08-18 08:09 · `planejamento` · **Os 5 Checks foram executados contra o HEAD (`9207b4d`) e
  registrados VERMELHOS**, para nenhum nascer verde: `abort:` deu **0** (alvo 4), `cdpath:` deu
  **2** (alvo 3), `output:` deu **6** (alvo 9), `covered:` deu **0** (alvo 5), `rule:` deu **0**
  (alvo 5). O `TODO.md` traz achado aberto sobre o gate PLAN-AUTO aceitar Check que já nasce verde.
- 2026-08-18 08:09 · `planejamento` · ⚠️ `cdpath:` e `output:` **não partem de zero**: já existem 2
  e 6 asserções desses prefixos em `tests/check-autonomy.sh`. As existentes têm de continuar verdes
  — no I2 elas são justamente as que provam que a troca do `ledger_repo_root` não regrediu nada.
- 2026-08-18 08:09 · `planejamento` · **A família do I1 foi reproduzida, não suposta.** Quatro
  sondas com o runner real num kit copiado (`SDD_HOME` é `readonly`, então não dá para apontá-lo
  por env), com controle verde `kit healthy` / rc 0 antes de cada sabotagem. Resultado: suíte
  vermelha → só o cabeçalho; `score:` ausente → morre após `suite green`; `plugins/cache` ausente →
  morre após o check de gates; baseline sem linha viva → morre após a proveniência. Sempre rc 1,
  sempre calado.
- 2026-08-18 08:09 · `planejamento` · **8 das 18 âncoras do `TODO.md` estavam podres** e foram
  re-derivadas contra `9207b4d`; a pior por **~615 linhas** (`--max-phases`, dizia `:1489-1498`,
  está em `:2104`/`:2281`). As linhas do `01-plano.md` são as boas — não confiar nas do `TODO.md`.
- 2026-08-18 08:09 · `planejamento` · ⚠️ `rc 1` sozinho **não** discrimina o defeito do I1: o
  `health_bad` também termina em rc 1. A asserção precisa exigir o texto do ramo certo **e** a
  presença de um check posterior. Sem a segunda metade ela passa igual com o defeito.
- 2026-08-18 08:09 · `planejamento` · O `check-autonomy.sh` é vermelho intermitente de causa
  desconhecida (não reproduziu em 152 runs). Se aparecer: registrar aqui e seguir. **Não**
  investigar — decisão 6 do `00-missao.md`.
- 2026-08-18 · `I1` · **A família tinha CINCO sítios, não quatro** — o quinto apareceu na sonda de
  re-derivação, antes de escrever asserção: `health_ratchet` terminava numa cadeia
  `[ … ] && [ … ] && ok …`, que devolve o status do primeiro teste que falha. Catraca que ACHOU
  algo devolvia 1 e o `set -e` matava o `cmd_health` uma linha antes do próprio veredito — o
  achado saía impresso e o `N check(s) failed` nunca. Bate no caminho que **funciona**, e as 7
  asserções que já existiam não notaram porque liam só `rc != 0`, que o `return 1` do fim do
  `cmd_health` também produz.
- 2026-08-18 · `I1` · **Decisão: o quinto sítio entrou no incremento, não no `TODO.md`.** A quarta
  asserção (`baseline sem linha viva`) é a única sem check posterior para exigir — a catraca É o
  último —, então a metade "e o run segue" dela só pode ser o veredito final. Sem consertar o
  `health_ratchet` a asserção ficaria em `rc != 0` + frase, que as Notas do planejamento já
  declaram insuficiente. Mesmo mecanismo, mesmo comando, mesma sessão: consertar era o mínimo para
  o Check do próprio incremento ser honesto. Ganhou entrada própria no catálogo
  (`mut_HEALTH_ratchet_eats_verdict`), então são **5** mutações novas e não 4.
- 2026-08-18 · `I1` · Cada mutação nova foi verificada **individualmente** antes da suíte cheia:
  aplica (o `cmp -s` do harness não a rejeita), continua bash válido, e é pega pela asserção
  escrita para ela — uma a uma, sem cruzar. A quinta precisou de duas substituições, porque tirar
  o `if` sem tirar o `fi` deixa o mutante inválido (rc 91 é falha de harness, não captura), e um
  `true` no lugar do `fi` fixaria o retorno em 0 e desfaria o próprio defeito.
- 2026-08-18 · `I1` · **`TODO.md` 56 → 54**, com `todo-findings 54` na baseline no mesmo commit:
  saíram os 3 itens da família (os que apontavam `:1588`, `:1854`/`:1882` e `:1721`) e entrou 1
  achado novo — o ciclo de vida do `RESOLVIDO por` (cabeçalho do `TODO.md`, linha 16) e a catraca
  do backlog não cabem juntos, porque `check-todo.sh` conta `- [ ]` e não conhece o marcador, de
  modo que `todo-findings` não pode descer na missão que consertou. Seguido o precedente de uma
  missão atrás (`6136d39`, PR #11): apagar na hora. Isso muda a aritmética do alvo 38 do
  `00-missao.md` para 38 + achados novos, exatamente como a tabela de riscos do plano previu.
- 2026-08-18 · `I1` · Evidência do gate: `tests/run-all.sh` → `suite green`, rc 0, com
  `score: 86 caught, 0 known gap(s), of 86` (era 81) e `54 finding(s)`. `./bin/sdd health` →
  `kit healthy`, rc 0. O Check do incremento: `4`, medido `0` contra o HEAD antes do conserto.

- 2026-08-18 · `I2` · **A família tinha DEZENOVE sítios, não 14** — e a re-derivação achou mais
  trabalho, como o plano previu. Três a mais em `tests/` (as linhas `SELF`/`SELF_PATH` de
  `check-todo.sh`, `check-checkpoint.sh` e `check-entrypoint.sh`: mesma forma, e o item do TODO só
  contava a linha `ROOT=` de cada arquivo) e **dois em `bin/sdd`**, no `_resolve_self`, que resolve
  o `SDD_HOME`. Esse é defeito vivo no runner e não estava no backlog: `SDD_HOME` é `readonly` e
  dele saem todo template, agente e starter config. Medido com veneno armado — com `CDPATH`
  apontando para um diretório que tenha um `bin`, a forma antiga devolvia `/poison` em DUAS linhas.
- 2026-08-18 · `I2` · **Decisão: os 5 sítios extras entraram no incremento, não no `TODO.md`.**
  Mesma classe, mesmo mecanismo, mesmo sensor, mesma sessão — e a métrica da missão é a classe
  sumir do repo, não ficar consertada em 14 dos 19 lugares. Mesmo precedente do quinto sítio do I1.
- 2026-08-18 · `I2` · **TRÊS mutantes perderam a âncora, não os 2 que o plano previa.** A reescrita
  do `ledger_repo_root` apagou as linhas em que `_toplevel` e `_common_parent` ancoravam; o
  `_cdpath_leak` era pior, porque **seguia aplicando** — o `sed` dele era global sobre
  `CDPATH='' cd` e passaria a sabotar o `_resolve_self`, medindo outra coisa com o nome do ledger.
  Os três foram reancorados e verificados um a um, sem cruzar: aplica, continua bash válido, e é
  pego pela asserção escrita para ele. O `_cdpath_leak` reintroduz a grafia antiga sem guarda,
  então com ambiente limpo se comporta igual à função sã, e é pego por EXATAMENTE as duas
  asserções `cdpath:` do `check-autonomy.sh` e por mais nada, com o piso do veneno seguindo verde.
- 2026-08-18 · `I2` · ⚠️ **A primeira passada de sabotagem concluiu 11 vezes em falso.** Copiava o
  sensor para um tmpdir cru, o `ROOT` resolvia fora de qualquer árvore, o `SELF_PATH` não existia e
  as 11 degradações "morriam" em rc 127 no primeiro probe — resultado uniforme, convincente e sem
  significado nenhum. É exatamente a armadilha que o `CLAUDE.md` já descreve. Refeita com controle
  no arquivo são, âncora literal com contagem exigida em 1, e recusa de ler rodada cuja âncora não
  casou: 9 das 11 morrem no probe que nomeia a regra exata. As 2 sobreviventes são o harness
  testando a si mesmo, e a equivalência com o `probe()` que já existia foi **medida** por asserção
  diferencial (mesma forma de edição em cada um, os dois sobrevivem), nunca afirmada.
- 2026-08-18 · `I2` · Duas regras sem probe caíram na mesma passada: as grafias `CDPATH=""` e
  `CDPATH=` saíram (nenhuma sabotagem as quebrava sem quebrar a canônica — regra irredutível é
  redundante, e o `CLAUDE.md` manda remover, não probar), e a linha `ok cdpath:` do `scan_surface`
  ganhou probe, porque apagá-la deixava o selftest verde e o Check da missão caindo de 3 para 2 em
  silêncio.
- 2026-08-18 · `I2` · **`TODO.md` 54 → 53**, com `todo-findings 53` na baseline no mesmo commit:
  saem os 2 itens da família e entra 1 achado novo — a regra `cdpath:` certifica como limpo o `cd`
  de operando **variável**, que é indecidível num scanner de linha e é justamente a forma da
  CRITICAL de `20260817-eixo-do-juiz`. Limite declarado no cabeçalho do sensor e no backlog, no
  mesmo precedente do `grep -m<N>` que a regra 1 já carrega.
- 2026-08-18 · `I2` · Desvio do plano, deliberado: **um commit só** em vez de separar a troca do
  `ledger_repo_root`. As duas metades tocam `bin/sdd` no mesmo arquivo, então dividir exigiria
  staging parcial de hunk em sessão headless — risco maior que o ganho de granularidade de revert.
- 2026-08-18 · `I2` · Evidência do gate: `tests/run-all.sh` → `suite green`, rc 0, com
  `score: 86 caught, 0 known gap(s), of 86` e `53 finding(s)`. `./bin/sdd health` → `kit healthy`,
  rc 0. `shellcheck -S warning bin/sdd tests/*.sh` limpo. O Check do incremento: `3`, medido `2`
  contra o HEAD antes da asserção.

- 2026-08-18 · `I3` · ⚠️ **A primeira asserção nasceu vermelha pelo MOTIVO ERRADO, e quase passou
  assim.** O padrão citava a grafia pós-conserto (`session(s)`), então contra o runner velho — que
  escrevia `sessions` — não casava nada e a asserção lia `0/0`. Vermelho convincente, significado
  nenhum: do jeito que estava, uma troca de plural sem tocar no número teria sido lida como
  conserto. Reescrita para casar o NÚMERO e ignorar a grafia (`session[^ ]*`), reprovou `0/2` — as
  duas vozes erradas, que é o defeito. É a regra do `CLAUDE.md` sobre red pelo motivo certo,
  cobrada dentro da própria sessão que a estava aplicando.
- 2026-08-18 · `I3` · ⚠️ **Segundo fail-open, no termo que prova que a frase do piso não guarda
  literal.** Escrito como `grep` sobre o arquivo inteiro, ele reprovou na PRÓPRIA documentação (o
  comentário acima da frase cita o defeito que descreve) — e o modo caro é o outro lado: renomeada
  a função, o `grep` continuaria respondendo "nenhum literal" sobre um corpo que nunca abriu. Passou
  a ler só as linhas de impressão de `kaizen_axis_note` e a carregar denominador (`0/4`), então 0
  linhas lidas reprova em vez de passar no vazio.
- 2026-08-18 · `I3` · **Cinco mutações e não três.** Uma por defeito é o mínimo do plano, mas duas
  regras das asserções novas ficariam sem probe nenhum: o parágrafo de exclusão **colado na tabela**
  (o `mut_..._split` deixa a linha em branco de cima intacta, e a asserção D5 vizinha conta brancos
  CONSECUTIVOS, então nada mais a veria) e a **série que deixa de publicar** `.guard.floor`. Ambas
  são o over-correction que uma mão consertando o defeito alcança primeiro. Custo medido: ~1 onda a
  mais no pool de 8. Cada um dos cinco foi verificado sozinho — aplica, segue bash válido, morre na
  asserção escrita para ele e em nenhuma outra.
- 2026-08-18 · `I3` · **Decisão: o piso ganhou dono em bash (`KAIZEN_GUARD_FLOOR`), não em jq.** O
  `TODO.md` mandava "interpolar o `guard_floor` da série", mas o produtor da série VAZIA é um
  `printf` que não tem entrada para rodar o programa jq — publicar o campo só no jq teria criado um
  `"floor":3` escrito à mão ao lado, que é o defeito de novo. A constante alimenta o jq por
  `--argjson` e o `printf` por expansão; `check-kaizen.sh` já compara os dois conjuntos de chaves,
  e a mutação `KAIZEN_guard_floor_unpublished` morre nos dois sensores.
- 2026-08-18 · `I3` · `docs/pipeline.md:513` entrou no MESMO commit, não no `TODO.md`: a chave
  `floor` é contrato de artefato (a série é lida pelo agente `sdd-kaizen`), e o `CLAUDE.md` manda
  atualizar `templates/`, `docs/pipeline.md` e o agente afetado junto com a mudança.
- 2026-08-18 · `I3` · **`TODO.md` 53 → 50**, com `todo-findings 50` na baseline no mesmo commit:
  saem os 3 itens da família e **nenhum achado novo nasceu** — o primeiro incremento desta missão em
  que a re-derivação não achou trabalho extra. As três âncoras do plano estavam defasadas de novo
  (`:2205`→`:2246`, `:2580-2583`→`:2621-2624`, `:3004`→`:3045`), mas o defeito era o descrito.
- 2026-08-18 · `I3` · Evidência do gate: `tests/run-all.sh` → `suite green`, rc 0, com
  `score: 91 caught, 0 known gap(s), of 91` (era 86) e `50 finding(s)`. `./bin/sdd health` →
  `kit healthy`, rc 0. `shellcheck -S warning bin/sdd tests/*.sh` limpo. O Check do incremento:
  `9`, medido `6` contra o HEAD antes das asserções.

- 2026-08-18 · `I4` · **O incremento não muda uma linha do `bin/sdd`, e isso é a forma dele.** Os
  cinco caminhos já estavam corretos; o que faltava era medida. Por isso o "vermelho primeiro" aqui
  não é um defeito consertado — é a asserção morrendo contra o runner SABOTADO, uma sabotagem por
  vez, verificada antes de a suíte cheia rodar: aplica (o `cmp -s` do harness não rejeita), segue
  bash válido, e morre na asserção escrita para ela e em nenhuma outra do mesmo arquivo.
- 2026-08-18 · `I4` · **Sete mutações e não cinco.** Duas das cinco famílias têm DUAS guardas cada,
  e uma mutação por família deixaria a outra metade sem probe: o custo desconhecido tem o braço
  `// "?"` do jq (resposta sem dinheiro) **e** o braço `[ -n "$cost" ]` (resposta sem `result`
  nenhum, sumário vazio — que o `|| echo "?"` ao lado NÃO cobre), e a proveniência tem a comparação
  do `qa-execution` **e** o laço `awk` do codereview, que é de forma diferente das outras duas.
- 2026-08-18 · `I4` · ⚠️ **A receita literal do plano para o custo mirava a SEGUNDA guarda, não a
  primeira.** Um stub que emita `{"other_field": 1}` não tem `type == "result"`, então o
  `stream_summary` filtra tudo e o sumário sai VAZIO — que é exatamente o caminho do
  `[ -n "$cost" ]`. As duas estavam descobertas; ambas ganharam mundo. Registrado porque a receita
  do backlog parecia apontar para o `// "?"` e aponta para a outra.
- 2026-08-18 · `I4` · **Uma asserção `covered:` por item, não uma por sítio** — o Check conta
  exatamente 5 linhas `^  ok    covered: `. A da proveniência é uma conjunção sobre QUATRO mundos
  (match/divergência para cada uma das duas skills) e a do custo sobre dois, cada uma carregando o
  piso do próprio mundo ao lado do veredito: que a amostra sem custo é mesmo um `result` sem
  dinheiro, e que o sumário do segundo mundo é mesmo vazio. Sem esses termos o mundo pode deixar de
  ser o mundo que a asserção nomeia e nada diria.
- 2026-08-18 · `I4` · **O conteúdo das duas skills novas é DERIVADO do `check-gates.sh`**, nunca
  escrito de memória: a linha `- **Started:**` normalizada como o `bin/sdd` a normaliza, e a tabela
  de notas copiada inteira do fixture. Template imaginado é o defeito que o `health_provenance`
  existe para pegar — escrevê-lo aqui faria este sensor confirmar a suposição em vez de medi-la.
  Conferido contra as skills instaladas nesta máquina (`qa-execution/assets/report-template.md` e
  `codereview/1.17.1/…/references/report-template.md:163-172`): a linha e o conjunto de critérios
  batem.
- 2026-08-18 · `I4` · **As cinco âncoras do plano estavam defasadas de novo**, desta vez por obra da
  própria missão (I1–I3 editaram o `bin/sdd`): `:1987`→`:2028` (o `die` do approve), `:1294`→`:1302`
  e `:1303` (as duas guardas do custo), `:2104`/`:2281`→`:2145`/`:2329` (`--max-phases`),
  `:3120`→`:3198` (`moved` do `cmd_kaizen`), `:1829`/`:1854`→`:1854`/`:1883-1894` (proveniência).
  O defeito era o descrito em todas.
- 2026-08-18 · `I4` · ⚠️ **A primeira caixa de sabotagem concluiu em falso e disse por quê.** O
  `sandbox()` do `check-mutation.sh` copia `docs/adr` e a caixa montada à mão não copiava: o
  `check-kaizen.sh` reprovou em `adr 0003 exists…` junto com a asserção sob teste, e "duas
  asserções morreram" teria virado uma alegação errada sobre qual delas mede o mutante. Refeita com
  `docs/adr` presente, sobra UMA. É a regra do `CLAUDE.md` sobre o probe provar primeiro que
  sabotou o que dizia sabotar, cobrada dentro da sessão que a estava aplicando.
- 2026-08-18 · `I4` · **`TODO.md` 50 → 45**, com `todo-findings 45` na baseline no mesmo commit:
  saem os 5 itens da família e **nenhum achado novo nasceu** — segundo incremento seguido em que a
  re-derivação não achou trabalho extra.
- 2026-08-18 · `I4` · Evidência do gate: `tests/run-all.sh` → `suite green`, rc 0, com
  `score: 98 caught, 0 known gap(s), of 98` (era 91) e `45 finding(s)`. `./bin/sdd health` →
  `kit healthy`, rc 0, `ratchet: 7 known debt(s), none new`. `shellcheck -S warning bin/sdd
  tests/*.sh` limpo. O Check do incremento: `5`, medido `0` contra o HEAD antes das asserções.

## Incrementos de fix (QA)

> Escritos pelo `sdd-qa` quando um bug sanável é reprovado. Entram na mesma tabela acima com ID
> `F<n>`, e o Check obrigatoriamente inclui **regression test passa** + **re-walk da jornada
> impactada verde**. Bug que exige julgamento humano NÃO vira fix — vai para "Decisions for a
> Human" no handoff de QA.
