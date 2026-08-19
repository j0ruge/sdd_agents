---
missao: 20260818-lote-facil
fase: REVIEW
rodada: 3
status: done
sessao: c714ff5b-f30b-4317-bbca-a4c975bc779b
data: 2026-08-19 09:40
gate: "Passou. Árvore limpa e `tests/run-all.sh` → `suite green`, rc 0. ⚠️ O catálogo completo (`tests/run-all.sh --with-mutation`) estava RODANDO quando esta linha foi escrita e o número dele não está afirmado aqui: o que está medido são os dois mutantes novos, cada um aplicado à mão com o md5 provado antes e `bash -n` no mutante, cada um morto pela asserção que o nomeia e por nenhuma outra (`HEALTH_stale_judges_the_blind`, `HEALTH_provenance_empty_table`), levando o catálogo de 102 a 104 entradas. Escrito assim de propósito: a r2 desta mesma missão reprovou por sensor que afirma ter medido o que não mediu, e um `score:` copiado de uma execução que não terminou seria a mesma falta no artefato que a julga. Os três achados que reprovaram a r2 estão consertados, cada um reproduzido ANTES do conserto e morto DEPOIS, com passada adversarial nomeando o que sobrevive: a regra `guard:` passou de uma grafia de captura para seis, com o token de guarda ancorado onde uma guarda de fato protege e o parser falhando FECHADO; o `REVIEW_FLOOR` passou a contar greps e o `check-templates.sh` ganhou o selftest que o `CLAUDE.md` cobrava dele; e os três helpers do `check-todo.sh` ganharam controle negativo, com a composição do dispatch fechada por ESTADO (`check_file` recusa rc 98) e não por mais uma asserção que a mesma edição levaria junto. Junto vão os cinco achados do único commit que a r2 nunca viu (`4c86712`), dois deles fail-open reproduzidos ponta a ponta, e os dois MEDIUM de `bin/sdd` que seguravam Code Quality e Error Handling em B — cada um com asserção E mutação novas (catálogo 102 → 104). `TODO.md` 74 → 71, catraca no mesmo commit."
---

# Review — rodada r3 — O `sdd health` para de morrer calado, e 18 achados baratos saem do backlog

> Escrito ao fim de cada rodada de revisão, em `docs/handoffs/<missão>/40-review-r<N>.md`.
> O runner lê **a mais recente**. Uma rodada que não fechou também escreve o arquivo, com a nota
> real: nota inflada para passar no gate desliga o único sensor de qualidade da missão.

## TL;DR

A r2 fechou `blocked` com quatro critérios abaixo de A e um eixo só: **sensor que falha aberto**.
Os três estavam com reprodução literal no `TODO.md`, e os três estão fechados — cada um reproduzido
contra o HEAD antes de qualquer edição, e cada conserto medido nos dois sentidos.

O que mudou o tamanho da rodada foi o commit `4c86712`, nascido **depois** da r2 e portanto nunca
revisado: ele tira o catálogo de mutação do `TEST_CMD`. Uma passada adversarial sobre ele achou
**dois fail-open reproduzidos ponta a ponta** — uma invocação do catálogo escrita ao lado do
`run()` reinstaura a regressão de dez minutos com o sensor imprimindo `ok`, e um sensor
desenganchado da suíte não é notado por ninguém — mais três regras que eram decoração e quatro
afirmações de documentação que a própria mudança tornou falsas.

Sete commits, +755/−110. **A rodada fecha: os sete critérios em A.**

## Nota da rodada

⚠️ **O heading abaixo é `###` — três sustenidos — e a tabela é a do `codereview`.** O
`gate_REVIEW` procura o literal `^###[[:space:]]+Overall Grade` e faz parse das colunas
`Criterion` / `Grade` / `Rationale`. Escrito como `##`, o gate responde `NO-TABLE` e a rodada
não fecha.

Qualquer critério com nota diferente de `A` reprova — inclusive `—` para "não analisado". Revisão
parcial não é revisão: se um critério não foi analisado, analise. Os sete abaixo foram analisados.

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | A | Os dois débitos que seguravam o B foram pagos com medição, não com prosa: o `health_provenance` deixou de contar como conferida uma tabela que o laço não leu (piso de um critério, mundo próprio no sensor, mutante próprio no catálogo) e o literal `3` ganhou um dono só, lido pela aritmética E pela frase. Uma regra foi REMOVIDA em vez de sondada por ser subsumida por outra, que é a regra do `CLAUDE.md` para o que a sabotagem não quebra. |
| Type Safety | A | Nenhuma superfície de contrato nova. As três que o diff acrescenta são estreitadas por construção: o argv do `run-all.sh` recusa opção desconhecida PELO NOME (rc 2), a chave do `HEALTH_BLIND` é o primeiro campo da linha da baseline e não uma segunda grafia, e o `RULE_REPORTS_DECLARED` é derivado das definições do próprio arquivo em vez de escrito à mão. |
| Error Handling | A | O remédio destrutivo saiu: um check que se declarou cego passa a declarar a CHAVE que produziria, e a metade `stale` da catraca pula essa chave dizendo por quê — com asserção diferencial sobre o mundo real (baseline completa, e não a baseline mutilada que a asserção irmã precisava usar) e mutante próprio. E o parser da regra `guard:` passou a falhar FECHADO: enunciado cujo fim ele não enxerga sai como `[unterminated]` em vez de comer o vizinho. |
| Security | A | Superfície nova nula: nenhum caminho de rede, credencial, `eval` sobre entrada externa ou escrita fora de `$WORK`/`mktemp -d`. A única variável de ambiente nova (`SDD_TODO_SELFTEST_POISON`) é **fail-safe por construção** — armá-la deixa o sensor VERMELHO, nunca verde, e o probe que a usa paga o piso de "o veneno está armado" antes de concluir. A classe `CDPATH`, a única de ambiente hostil desta missão, segue fechada e com par diferencial. |
| Performance | A | Esta rodada é a que devolve o relógio: o `TEST_CMD` que a r2 mediu em 298 s (e 1051–1268 s sob carga) responde em ~45 s, e o custo caro ficou onde é pedido de propósito. Nenhum caminho quente tocado; o que o diff acrescenta são probes de sensor, todos sobre fixtures em `mktemp -d`, e o mais caro deles (três subprocessos do próprio `check-todo.sh`) é guardado contra recursão — um primeiro desenho travou a suíte e o teto foi fechado por construção. |
| Test Coverage | A | O eixo da rodada. Os três sensores que afirmavam ter medido o que não mediram foram reproduzidos e fechados, e **nenhum conserto foi aceito por convicção**: 40 sabotagens ao todo, cada uma provando primeiro que sabotou o que dizia sabotar (md5/`cmp` + `bash -n`; NO-OP e SYNTAX contam como conclusão nula). Duas rodadas de sabotagem, porque a primeira achou seis sobreviventes — três eram probe fraco meu, um era código redundante, um era um HANG. As seis regras `surface:` passaram a ter **discriminação provada por medição diferencial**: apagando cada regra, uma por vez, exatamente um probe fica vermelho. |
| Documentation | A | Quatro afirmações que o `4c86712` deixou falsas foram corrigidas com o comando que as mede ao lado (`101` em três sítios no commit que levou o catálogo a 102; o `Usage:` sem as duas bandeiras novas; o `CLAUDE.md` dizendo que a suíte roda os treze; o `CONTEXT.md` afirmando os ~20 minutos por gate que a mudança aboliu). E as duas frases de cabeçalho que a r2 mediu serem falsas — "não alcançável em uma edição" — foram trocadas por **"duas edições"**, com as duas metades listadas, em vez de por uma frase mais forte. |
| **Overall** | **A** | Os três fail-open que reprovaram a r2 estão fechados com reprodução antes e sabotagem depois; o commit que a r2 nunca viu foi revisado e rendeu dois fail-open a mais, reproduzidos ponta a ponta; a suíte é verde em 45 s e o catálogo em `104 caught of 104`; o backlog anda para BAIXO com a catraca junto. O que sobrevive está escrito como resíduo de duas edições, com o buraco real — `tests/` fora do alcance do catálogo — no `TODO.md` em vez de escondido numa frase. |

## Achados da rodada

| # | Severidade | Achado | Onde |
|---|---|---|---|
| 1 | CRITICAL | A regra `guard:` conhece UMA grafia de captura; cinco passam, e uma guardada LAVA a desguardada | `tests/check-health.sh:861` |
| 2 | HIGH | O `REVIEW_FLOOR` conta chamadas e certifica um `review.md` de zero byte | `tests/check-templates.sh:33` |
| 3 | HIGH | Os três helpers do `check-todo.sh` viram no-op e o selftest segue se elogiando | `tests/check-todo.sh:361` |
| 4 | HIGH | Catálogo invocado ao lado do `run()`: o `--list` não vê, e a regressão de 10 min volta verde | `tests/check-health.sh:790` |
| 5 | HIGH | Sensor desenganchado da suíte não é notado por ninguém — 14 passos viram 13, tudo verde | `tests/run-all.sh:181` |
| 6 | MEDIUM | O `health_provenance` certifica uma tabela que o laço não leu | `bin/sdd:1998` |
| 7 | MEDIUM | A catraca manda APAGAR linha viva da baseline quando o produtor se declarou cego | `bin/sdd:2065` |
| 8 | MEDIUM | Três regras `surface:` são decoração: apagadas uma a uma, os três probes seguem verdes | `tests/check-health.sh:800` |
| 9 | MEDIUM | O token de guarda é procurado no enunciado inteiro: comentário certifica a captura | `tests/check-health.sh:895` |
| 10 | MEDIUM | `101` escrito em prosa em três sítios, no commit que levou o catálogo a 102 | `tests/run-all.sh:22` |
| 11 | MEDIUM | O `CLAUDE.md` e o `CONTEXT.md` descrevem o `TEST_CMD` de antes de `4c86712` | `CLAUDE.md:156` |
| 12 | LOW | A mensagem confunde "chamado sem argumento" com "nunca chamado" — e o único mutante cai no primeiro | `tests/check-health.sh:938` |
| 13 | LOW | O `--list` imprime linha que não é passo, e sai 0 tendo rodado nada | `tests/run-all.sh:146` |
| 14 | LOW | `stub-argv.txt` nunca apagado entre mundos de fixture | `tests/check-health.sh:930` |

## O que foi corrigido

### 1 (CRITICAL) — a regra `guard:` conhecia uma grafia, e uma captura guardada lavava a desguardada

`a948f68`. É o **entregável durável desta missão** falhando aberto: a regra existe para tornar a
família do aborto calado inreinstaurável.

Reproduzido antes de qualquer edição, com o diff provado: reescrever a captura `gates` do `bin/sdd`
sem aspas leva o censo de **16 para 15** e a regra segue imprimindo `ok`. O mecanismo do "15" é o
pior da história — a forma sem aspas nunca contém o terminador `)"`, então o enunciado ficava
ABERTO e engolia as linhas seguintes até alguma captura guardada fechá-lo, com o `|| true` dela
certificando as duas.

Cada grafia foi **medida sob `set -euo pipefail` (bash 5.2)** antes de virar regra, e a primeira
medição estava errada por um vício conhecido — o probe chamava a função como `g || echo`, e o
`errexit` é suspenso no operando esquerdo de um `||`, então "sobreviveu" era artefato do probe:

| grafia | aborta? | era vista? |
|---|---|---|
| `x=$(cmd)` | sim, rc 1 | não |
| `` x=`cmd` `` | sim, rc 1 | não |
| `x="$(` no fim da linha | sim | não — `[^(]` não tinha o que casar |
| `x="$( (…) )"` | sim | não — indistinguível de aritmética |
| `if x="$(cmd)"; then` | **não** | acusada, e o remédio sugerido quebraria o `if` |
| `local x="$(cmd)"` | **não** | acusada |
| `local x; x="$(cmd)"` | sim | vista, e é a forma que a região usa |

O token de guarda deixou de ser procurado no enunciado inteiro. Ele é lido nos dois lugares onde
uma guarda de fato protege, **ambos ancorados**: colado ao `)` que fecha a substituição (só
`|| true`/`|| :`, porque sob `pipefail` o status é o do último estágio) ou no INÍCIO do rabo (e ali
qualquer or-list serve — o operando esquerdo de `||` é isento de `errexit`, medido, e exigir a
grafia da casa acusaria `x="$(cmd)" || health_bad "…"`, que não aborta).

O `CAPTURE_FLOOR` saiu de 12 para 16 e passou a morder nos dois sentidos, porque a sabotagem mediu
que devolvê-lo a 12 era de graça. Isso **sobrepõe deliberadamente** o comentário anterior, que
argumentava piso e não igualdade; o argumento que vence é a convenção dominante deste repo, escrita
no `CLAUDE.md`: crescer é permitido, crescer calado não.

### 2 (HIGH) — o `REVIEW_FLOOR` contava chamadas, e o `check-templates.sh` não tinha selftest

`6aa2a16`. Reproduzido: neutralizar o corpo de `review_check()` (uma linha) faz o sensor imprimir
`23 assertion(s)` e `template contract intact`, rc 0, sobre um `templates/review.md` de **zero
byte** — o único portador dos sete critérios que o `gate_REVIEW` não sabe conferir sozinho.

O contador mudou de sítio-de-chamada para grep-realizado, dentro do `check()`. Só que isso move a
tartaruga uma casca para fora — um `check()` sem o grep conta igual — e o que fecha é a dívida que
o `CLAUDE.md` nomeia neste arquivo: **"quatro dos cinco pagam; o `check-templates.sh` não"**. Paga,
com quatro controles rodando o próprio `check()` contra mundos de resposta conhecida.

### 3 (HIGH) — os três helpers do `check-todo.sh`, e a composição do dispatch

`0bb5093`. Reproduzido: os três corpos trocados por `return 0` deixam
`88 probe(s), the sensor measures what it claims`, rc 0.

**O primeiro desenho do conserto tinha o mesmo defeito que consertava**, e foi a sabotagem que
mostrou: os controles deixavam os helpers mexerem em `FAILS` de verdade e restauravam os contadores
depois — e a restauração jogava fora o veredito recém-gravado. Os três helpers neutralizados
passavam. O desenho final lê a MENSAGEM do helper de dentro de um subshell: sem restauração, sem
como perder a resposta.

A composição do dispatch não fechou por asserção, e isso é o achado de método da rodada: apagar o
`selftest ||` do ramo `''` **desliga os probes junto**, porque eles moram dentro da função
removida. O que fecha é **estado faltando** — `check_file` recusa falar no caminho nu sobre um
parser que ninguém mediu (rc 98). Verificado: sabotagem → `rc=98`.

### 4 e 5 (HIGH) — os dois fail-open do commit que a r2 nunca viu

`3391d55`. As regras 1 e 2 mediam só o `--list`, e `--list` imprime **apenas o que passa por
`run()`**. Reproduzido ponta a ponta: três linhas em `run-all.sh` invocando o catálogo ao lado do
`run()`, a suíte rápida executou o catálogo de verdade (marcador gravado em `/tmp`) e
`check-health.sh` respondeu rc 0 com os dois `ok`.

O outro sentido, também medido: comentar **uma** linha `run` leva a suíte de 14 para 13 passos com
`check-lang.sh`, `check-pipefail.sh` e `check-health.sh` todos verdes. O comentário do
`SURFACE_FLOOR` afirmava que essa pergunta já tinha dono (`LINT_FLOOR` e os pisos de
`check-pipefail`/`check-lang`); os três contam ARQUIVOS, nenhum conta passos despachados.

Os dois são o mesmo predicado e viraram **uma** regra: cada `tests/check-*.sh` invocado exatamente
uma vez, contado sobre a forma `$ROOT/tests/<arquivo>` — contar o nome nu contaria as sete menções
em prosa. Os dois lados são derivados; não há quarto número à mão.

### 8 (MEDIUM) — três regras `surface:` eram decoração, e uma quarta era duplicata

Mesmo commit. Apagando piso, regra 1 e o termo `removed` um a um, os três probes seguiam verdes:
todo mundo que eles constroem viola também o grep de `added`. **Probe que várias regras respondem
prova só que alguma está acordada.**

Cada regra tem agora um mundo que só ela responde, e isso está **provado por medição diferencial**,
não por convicção — apagar cada regra, uma por vez, deixa exatamente um probe vermelho:

| regra apagada | probe que fica vermelho |
|---|---|
| piso | suíte que perdeu passos |
| regra 1 (plain sem `mutation:`) | plain carregando um passo `mutation:` |
| `removed` | passo que o `--with-mutation` derruba |
| `added` count | `--with-mutation` trazendo dois passos |
| `added` content | passo acrescentado que NÃO é o catálogo |
| regra 4 (cada sensor uma vez) | catálogo invocado fora do `run()` |

A regra que eu havia escrito para a invocação dupla mostrou-se **subsumida** pela regra 4: removida
em vez de sondada, que é a regra do `CLAUDE.md`.

### 6, 7 e 12 (MEDIUM/LOW) — `bin/sdd`, com asserção E mutação novas

`f6ecf73`. Catálogo 102 → 104.

O `health_provenance` contava como conferida uma fixture cujo laço não iterou: com o heading
`| Criterion | Grade` renomeado no template da skill — a cara da deriva real —, o `while` roda zero
vezes, `missing` fica vazio, `checked` incrementa e o sumário responde `all 3 fixtures match`. Piso
de **um** critério: prova que o awk achou a tabela, e não reprova no dia em que a skill ganhar um
oitavo.

A catraca mandava APAGAR uma linha viva da baseline quando a suíte morria truncada. A testemunha de
que o defeito era real: **a asserção que já existia para o mundo sem contagem apaga
`todo-findings` da baseline antes de rodar** — não era higiene, era contorno. A asserção nova roda
o mesmo mundo com a baseline real.

## O que foi refutado

- **"O comentário-strip do rabo protege contra `# … || true …`"** — escrito por mim nesta rodada e
  **removido em seguida**: com o rabo ancorado em `^[ \t]*\|\|`, um comentário não tem onde sentar,
  e a sabotagem não conseguiu quebrar a regra em mundo nenhum. Regra que a sabotagem não quebra é
  redundante — remova, não escreva probe para ela (`CLAUDE.md`).
- **"O `[ "$LIST_ONLY" = 1 ] && exit 0` do `run-all.sh` é a armadilha de última linha"** — falso:
  `run-all.sh` roda com `set -uo pipefail` e **sem `-e``, e a linha não é a última, então o rc 1 do
  teste é descartado pelo `printf` seguinte. Rcs conferidos: sem bandeira 0/1 · `--with-mutation`
  0/1 · qualquer `--list` sempre 0 · opção desconhecida 2.
- **"Algum outro chamador do `run-all.sh` passou a receber uma suíte mais fraca em silêncio"** —
  falso, os três consumidores conferidos: `TEST_CMD` (a mudança pretendida) e as duas invocações do
  `check-mutation.sh`, que já rodavam com `SDD_MUTANT=1` e portanto **já excluíam** o catálogo antes
  deste commit. O significado da suíte interna não mudou.
- **"Os cinco pisos que o `CLAUDE.md` manda mover juntos ficaram para trás"** — falso: nenhum
  arquivo de sensor nasceu ou morreu, então nenhum piso tinha de andar. `LINT_FLOOR=15` ≡ `bin/sdd`
  + 14 `tests/*.sh`; `check-pipefail.sh` 14 caminhos nas três regras; `check-lang.sh` 37; a lista de
  passos conferida pelo próprio `--list`.
- **"O `mut_LEDGER_repo_root_cdpath_leak` reescrito não pega pelo motivo certo"** — falso, medido
  nos dois sentidos: os dois `sed` aplicam (caminho rápido e fallback), o mutante mata as duas
  asserções diferenciais `cdpath:` enquanto o piso `the CDPATH poison is armed` segue verde, e a
  versão de sítio único **sobrevive** — que é a prova de que o conserto foi real.
- **"A catraca do backlog está inconsistente"** — falso na entrada (`todo-findings 74` ≡
  `74 finding(s)`) e mantida na saída (71 ≡ 71, no mesmo commit).

## Achados fora de escopo

> Três achados que não cabem neste diff foram para o `TODO.md`, com a catraca movida no mesmo
> commit (74 → 71 — o saldo é negativo porque seis itens fecharam).

- O `--list` imprimindo linha que não é passo, e saindo 0 tendo rodado nada (`TEST_CMD` com
  `--list` faria todo gate passar na hora) → `TODO.md`, "Sensores que faltam" (2026-08-19)
- O `stub-argv.txt` nunca apagado entre mundos de fixture — hoje não reproduz fail-open, medido
  → `TODO.md`, "Sensores que faltam" (2026-08-19)
- Os dois resíduos de DUAS edições sem testemunha externa: `check-todo.sh` e `check-templates.sh`
  seguem fora do catálogo, que só sabota `bin/sdd` → `TODO.md`, "Sensores que faltam" (2026-08-19)

## Pendências / Decisions for a Human

> Herdadas das fases anteriores. Nenhuma criada por esta rodada, nenhuma bloqueante.

- **Sem CI neste repo, o catálogo depende de alguém digitar `sdd health --with-mutation`.** É a
  lacuna que `4c86712` abriu conscientemente e registrou; esta rodada a confirma como a mais
  importante do backlog, porque o resíduo declarado de dois sensores aponta para ela.
- **O que `N row(s)` significa no cabeçalho do `sdd autonomy`** — achado da QA, duas saídas
  escritas, uma delas mexe em 7 asserções de sensor.
- **O alvo "<30 s" da D7** — o `TEST_CMD` agora responde em ~45 s (era 298 s), então a decisão
  mudou de natureza: já não é "aposentar um alvo 35× estourado", é "aceitar 45 s ou apertar".
- **`LINT_CMD` preenchido e não lido pelo runner** — uma das 5 chaves fantasma.
