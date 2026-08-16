---
missao: 20260816-kit-como-alvo
fase: REVIEW
rodada: r2
status: done
sessao: b5301b40-92a4-4f13-902c-a44a46de5a1a
data: 2026-08-16 21:40
gate: "FECHA em r2, todos os critérios em A. `bash tests/run-all.sh` verde (rc `0`, `score: 44 caught, 0 known gap(s), of 44`), `bash bin/sdd health` → `kit healthy`, os 5 Checks do checkpoint em `0`/`1`/`1`/`1`/`01`, `bash tests/check-todo.sh` verde com 64 achados, árvore limpa. Os dois HIGH abertos pela r1 (`R1-A` e `R1-B`, fail-open no `tests/check-entrypoint.sh`) foram reproduzidos, consertados com probe e commitados em `cbca483`; um terceiro fail-open da mesma família (a composição de topo) foi achado nesta rodada e fechado junto. Passada adversarial de 25 degradações: 20 morrem no sensor, 3 são não-regras ou floors nomeados, e as 2 que são fail-open de verdade foram MEDIDAS como cobertas pelo catálogo de mutação (suíte `43 caught of 44` + rc 1 com a composição neutralizada, contra 44/44 intacta). A r1 alegava ter commitado cinco consertos de documentação e não commitou nenhum: encontrados na árvore suja e commitados em `5e3551e`, com a alegação falsa corrigida no texto da r1."
---

# Revisão — rodada 2 — quando o kit é o próprio alvo

> Rodada 2 de no máximo `REVIEW_MAX_ITER=3`. **Fecha.** A tabela `### Overall Grade` abaixo traz a
> nota real: os três fail-open estão fechados com probe, e cada afirmação desta página tem um
> comando por trás.

## O que esta rodada recebeu

A r1 deixou dois HIGH abertos e uma armadilha que ela mesma não viu. Nesta ordem:

**A árvore estava suja.** `git status` abriu a sessão com 8 arquivos modificados e o
`40-review-r1.md` sem rastrear, enquanto o relatório da r1 dizia, literalmente, *"Todos commitados
em `<hash-r1>`"* — o placeholder nunca substituído. Os cinco consertos eram reais e continuam
válidos; a **atribuição de commit** era um rótulo sobre um artefato que não existia, que é a
família de defeito que esta missão inteira existe para matar. Corrigido nos dois lados: os cinco
consertos foram commitados em `5e3551e` e a linha da r1 ganhou o ⚠️ com o motivo.

Nada da r1 foi aceito de palavra. Os dois HIGH foram **reproduzidos** antes de consertados, e a
r2 achou um terceiro da mesma família que a r1 tinha listado como "consider".

## Os três fail-open, e por que são um só defeito

Os três têm a mesma forma, e é por isso que foram consertados juntos em vez de remendados um a um
— a regra da casa é que sintoma consertado individualmente vira o próximo sintoma:

> **os probes mediam o PARSER; o caminho de "existe defeito" até "a suíte fica vermelha" não tinha
> probe nenhum.**

É a lição do `check-todo.sh` ("o selftest tem de exercitar o CAMINHO") uma camada acima — num
sensor que **esta missão criou** exatamente para matar instrumentos que afirmam o que não mediram.

### R2-1 (era `R1-A`) · HIGH · a igualdade afrouxada para substring passava verde

Reproduzido: trocar `[ "$got" != "$GUARDED_FORM" ]` por um `case ... in *"$GUARDED_FORM"*)` deixa
os **10 probes verdes** (`--selftest` rc 0). E não é afrouxamento inócuo — medido lado a lado:

| arquivo cuja última linha executável é | sensor sabotado | sensor original |
|---|---|---|
| `note='{ main "$@"; exit $?; }'` | `--check` rc **0** | `--check` rc **1** |

Um arquivo que *contém* a guarda, não *é* a guarda, e cai de volta em si mesmo — aceito. A causa é
que todo fixture não-guardado dos probes é **mais curto** que a guarda, então nenhum consegue
contê-la: só a direção oposta morria. ⚠️ E o cabeçalho do sensor **afirmava** que essa sabotagem
morria, o que o punha na mesma família que ele existe para denunciar.

**Conserto:** probes 11 e 12, carregando a forma como prefixo estrito (`{ … } &`, que é a
perigosa: `&` põe o grupo em background e o pai volta ao read loop) e como sufixo estrito
(`true && { … }`). Nenhuma direção do afrouxamento sobrevive — as quatro (contains, prefix,
suffix, reverse-contains) morrem em rc 91. O caso `note='…'` **não** virou um terceiro probe: o
probe 11 já mata toda sabotagem que ele mataria, e probe que sabotagem nenhuma precisa é
decoração, pela regra do próprio kit.

### R2-2 (era `R1-B`) · HIGH · o `probe()` grita `SENSOR-BROKEN` e sai `0`

Reproduzido, e é o mais grave dos três. Apagar `FAILS=$((FAILS + 1)); fail_rc 91` do ramo de rc
divergente é **latente sozinho** (com o parser sadio nenhum probe diverge) e **fail-open** ao lado
de qualquer segundo defeito. Com `check_file` sempre `return 0`, a saída medida foi:

```
SENSOR-BROKEN: a bare `main "$@"` is refused — wanted rc 1, got 0
SENSOR-BROKEN: the guard followed by another command is not a guard — wanted rc 1, got 0
SENSOR-BROKEN: a file with no executable line is not silently guarded — wanted rc 1, got 0
SENSOR-BROKEN: braces without the exit are not the guard — wanted rc 1, got 0
SENSOR-BROKEN: a safe-but-different spelling is refused — wanted rc 1, got 0
  ok    selftest: 10 probe(s), the entry-point parser measures what it claims
SELFTEST RC=0
```

Cinco gritos na stderr, o `ok` por cima deles, e rc `0` — que é o que `tests/run-all.sh:22` lê.

**Conserto:** `harness_selfcheck()`, que dirige o `probe()` com expectativa deliberadamente errada
e exige que a falha tenha sido **contabilizada**, não só impressa. Um braço por sítio de
contabilidade (o ramo de rc e o ramo de texto), então sabotar qualquer um dos dois morre sozinho.

⚠️ **Um comentário mentiroso foi consertado junto.** O `:304` afirmava "two independent paths from
'a probe failed' to 'the selftest fails'" — e os dois eram a jusante da **mesma** linha. Agora o
texto diz a verdade: são independentes contra a sabotagem de *um* dos sítios (`fail_rc` sem o
contador, ou o contador sem `fail_rc`); apagar os **dois** é uma edição só, e é o que o
`harness_selfcheck` existe para pegar.

### R2-3 · HIGH · achado nesta rodada — a composição de topo não tinha probe

A r1 listou "cada asserção de topo removível com um `true`" como "consider". É HIGH, e reproduzido:
apagar `differential || exit $?` das três linhas de topo deixa **tudo verde** e o arquivo sai `0`
sem nunca ter rodado o diferencial.

**Conserto:** as três chamadas viraram uma **lista** — o que um probe consegue contar — dirigida
por `stage()`, mais `probe_composition`, que roda o arquivo INTEIRO com um estágio forçado a
falhar (`SDD_EP_FORCE_FAIL`) e exige rc 93 de volta, um por estágio.

⚠️ **A primeira versão deste conserto tinha um buraco, achado pela sabotagem e não por raciocínio:**
`probe_composition` mora **dentro** do `selftest`, então quando o nome que cai da lista é
`selftest` os próprios probes somem junto — sobreviveu como um rc 0 limpo. Foi preciso um estado
que não morasse em estágio nenhum: o contador de `stage()`, lido **depois** do laço. Os dois se
cobrem em coisas diferentes e nenhum é redundante — o contador pega "a lista encurtou", o
`probe_composition` pega "a lista tem três nomes e um deles não é o estágio" (medido: trocar
`differential` por `true` mata só o segundo).

## A passada adversarial — 25 degradações, e o que sobra

O critério de pronto de sensor novo, no `CLAUDE.md`, é a sabotagem adversarial, não o verde. Cada
regra degradada isoladamente, com `bash -n` e âncora conferidos para não confundir mutante inválido
com regra fraca:

| Grupo | Degradações | Resultado |
|---|---|---|
| Parser (`entry_line`, `check_file`) | 9 — comment skip, blank skip, ltrim, sem newline final, FIRST em vez de LAST, anti-vacuidade, e as 4 direções da igualdade | **9 morrem** (rc 91) |
| Reporte (`probe`, harness, witness) | 4 — contabilidade do ramo de rc, do ramo de texto, corpo do `probe()` neutralizado, `harness_selfcheck` nunca chamado | **4 morrem** (rc 92) |
| Composição | 4 — cada um dos três nomes apagado, e um nome trocado por um inerte | **4 morrem** (rc 92) |
| **Total que morre no sensor** | | **20 de 25** |

Os 5 que sobrevivem estão **nomeados no cabeçalho**, em três grupos, por aquilo que de fato limita
cada um — porque survivor que ninguém escreveu é indistinguível de survivor que ninguém procurou:

1. **Não são regra** (o rc não muda, não há o que pegar): apagar o `break` do laço — o
   first-failure-wins já fixou o veredito, o `break` só decide quanto roda depois disso; e apagar
   a linha `FAILS -ne 0 → SELFTEST_RC=92`, que é a redundância **deliberada** descrita no próprio
   sítio (o `fail_rc 91` continua carregando a falha para fora).
2. **Floors e cross-checks**, que não escondem nada enquanto os corpos que eles amparam estão
   inteiros: baixar qualquer dos dois pisos de probe, apagar o piso de estágio, desligar o witness.
3. **Fail-open de verdade, e fechado uma camada fora** — a propagação de rc da composição e o ramo
   real do `stage()`. Nenhum dos dois é alcançável de dentro: **a última linha de um sensor é a
   linha sobre a qual ele não consegue asseverar.** Isto **não** foi deduzido, foi medido nos dois
   sentidos:

   | `bin/sdd` sabotado por `mut_RUN_entrypoint_unguarded` + | suíte |
   |---|---|
   | sensor intacto | `score: 44 caught, of 44` · rc **0** |
   | composição neutralizada | `FAIL RUN_entrypoint_unguarded is NOT caught` · `43 caught, of 44` · rc **1** |

   O rc 0 do sensor neutralizado é exatamente o que o driver de mutação converte em "NOT caught".
   A cobertura externa é real, não uma esperança escrita no comentário.

## Consertos menores da mesma vizinhança

- `SELF_PATH` passou a sair de `${BASH_SOURCE[0]}` em vez de um nome fixo: os probes reinvocam
  **este** arquivo, e uma cópia rodando com outro nome tem de sondar a si mesma.
- `trap` de limpeza para os temp dirs, que até aqui só saíam pelos caminhos normais.
- Duas linhas re-quebradas na largura do repo: a r1 **alegou** ter reajustado `CLAUDE.md:117` e o
  deixou com **160** caracteres, e `docs/pipeline.md:374` com 115. As demais linhas de 101–105 são
  norma preexistente do repo e não foram tocadas.

## Achados verificados e refutados nesta rodada

Levantados pela leitura independente do diff do `bin/sdd` (167 linhas) e **derrubados com comando**
— nenhum virou "conserto para agradar a crítica":

- **"`warn_if_on_base_branch` faz `cd "$REPO_ROOT"` e pode rodar com `REPO_ROOT` vazio em
  `cmd_run`"** — não pode, e não morde de todo jeito. `REPO_ROOT=""` é inicializado em
  `bin/sdd:71` (logo `set -u` não dispara), `cmd_run` chama `load_config` na sua 14ª linha e o
  aviso está na 32ª, e mesmo no caso vazio `bash -c 'set -uo pipefail; cd ""'` devolve rc `0` sem
  sair do diretório. Três medições, nenhuma sustenta o achado.
- **"o `total` do `cmd_autonomy` agora roda dois `jq` antes da checagem de ledger malformado"** —
  verdade, mas **não é regressão**: a forma `total="$(jq -s 'length' "$file")"` já tinha a mesma
  exposição antes desta missão, e o `die "malformed row"` que a cobre continua onde estava. Achado
  preexistente, fora do diff — não entra como achado da missão nem inventa dívida nova.
- **"os dois `survivors` de composição significam que o conserto não fecha"** — refutado pela
  tabela diferencial acima: os dois são pegos pelo catálogo, medido nos dois sentidos.

Os cinco refutados pela r1 (o rc do `{ main "$@"; exit $?; }`, o filtro cegando o juiz, o `_fail`
multilinha do preflight, o `--arg repo` faltando num splice, a âncora do mutante novo) foram
relidos e **continuam refutados**; não foram re-medidos porque a r1 os mediu com comando e a
evidência está no `40-review-r1.md`.

## Registrado no `TODO.md`, fora do diff

Dois achados novos desta rodada, reais e não consertados aqui porque os dois pedem desenho próprio
— não remendo:

- **Os dois ramos de diagnóstico do `differential()` não têm probe** (`tests/check-entrypoint.sh:234`).
  Hoje o que os limita é o par de contagens ser IMPRESSO na linha `ok` ("2 vs 1"), então uma
  comparação neutralizada lê "1 vs 1" na saída da suíte em vez de silêncio. Direção anotada: um
  gancho como o `SDD_EP_FORCE_FAIL` da composição, com um probe por ramo.
- **O `40-review-r<N>.md` é o único artefato com gate e sem template** (`templates/`). Achado ao
  **rodar o parser do `gate_REVIEW` contra este arquivo** em vez de supor que ele passava: a
  resposta foi `NO-TABLE`, porque a seção tinha sido escrita como `## Overall Grade` e o gate exige
  `^###[[:space:]]+Overall Grade` (`bin/sdd:2196`). Corrigido nos dois relatórios — a r1 tinha o
  mesmo defeito e teria reprovado por "não há tabela" em vez de pela nota `C`, que é reprovar pelo
  motivo errado. O contrato está certo em toda parte que o declara (`agents/sdd-reviewer.md:57`,
  `docs/pipeline.md:124`, os fixtures do `check-gates.sh`); o que falta é o template que os outros
  cinco artefatos têm, e duas sessões independentes derivarem igual é a evidência de que falta.

Os cinco da r1 (lembrete pós-pipeline cego, `sdd retry` como quarta porta, worktree partindo a
identidade do repo, linha sem `repo` sendo "local" em todo repo, e o `doc_rule` que falta para a
regra do `|`) continuam no `TODO.md` — foram commitados em `5e3551e`, porque a r1 os escreveu e
não os commitou. `bash tests/check-todo.sh` → verde, **64 achados**, todos dentro de 8 linhas com
âncora e data.

## Medições desta rodada

Todas rodadas contra `cbca483`, depois dos consertos:

| O que | Resultado |
|---|---|
| `bash tests/run-all.sh` | verde, rc `0`, `score: 44 caught, 0 known gap(s), of 44` |
| `bash bin/sdd health` | `kit healthy` — 8 gates com mutação, 3 fixtures com proveniência, 6 dívidas, nenhuma nova |
| Checks I1/I2/I3/I4/F1 | `0` · `1` · `1` · `1` · `01` (no HEAD do plano: `127` · `0` · `0` · `0` · `00`) |
| `bash tests/check-todo.sh` | verde, 64 achados, selftest com 75 probes |
| `shellcheck -S warning` | limpo em `bin/sdd` e em `tests/*.sh` |
| Sabotagem adversarial do sensor | 25 degradações, 20 morrem, 5 nomeadas no cabeçalho |
| Cobertura externa dos 2 survivors | `44 caught` intacto × `43 caught` + rc 1 neutralizado |
| Parser do `gate_REVIEW` contra este arquivo | 8 linhas lidas, nenhuma `offending` |
| `git status --short` | limpo |

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | A | Uma definição por programa nos dois consertos do runner (`ledger_row_is_local`, `warn_if_on_base_branch`), e os mutantes sabotam a **definição** e não um call site — é isso que prova que os três leitores passam mesmo por ela. No sensor, os três fail-open foram fechados pela propriedade que faltava ("nada probe o caminho de reporte") e não sintoma a sintoma: as três chamadas de topo viraram uma lista porque lista é o que um probe consegue contar. Duas redundâncias foram **removidas** em vez de escritas (o probe `note='…'`, que nenhuma sabotagem exigia) e uma foi mantida com o motivo escrito. Comentários explicam o porquê; os dois que afirmavam algo falso foram corrigidos |
| Type Safety | A | Não há sistema de tipos; o equivalente é o contrato de shape, e ele está fechado: `excluded` ganhou o quarto balde nos **dois** produtores da mesma shape (o `jq` e o literal de ledger vazio, `bin/sdd:2036`), e `check-kaizen.sh` compara os dois como conjuntos de chave. No sensor, os rc são um enum documentado e disjunto (`0/1/90/91/92/93/94/96`), com o 93 novo reservado ao caminho interno e declarado como tal no cabeçalho. `shellcheck -S warning` limpo em `bin/sdd` e em `tests/*.sh`, incluindo o arquivo reescrito nesta rodada |
| Error Handling | A | Três silêncios nomeados à parte no `cmd_autonomy` (arquivo vazio · cwd sem repo · ledger de outro repo) em vez de um "no data" que mandaria o leitor caçar um runner que nunca escreveu; o que sai é **contado**, nunca sumido; linha que não sabe dizer de onde veio nunca é excluída, para não esconder corrupção; o preflight distingue "ausente" de "stale" porque são consertos diferentes. No sensor, o modo de falha que importa era o **fail-open**, e os três foram fechados: hoje toda falha de probe é contabilizada num sítio que tem probe próprio, e a composição não consegue mais devolver `0` tendo pulado um estágio. Verificado por reprodução, não por leitura |
| Security | A | Secrets pre-scan determinístico da r1 → 0 achados, 0 erros; o diff da r2 acrescenta só `tests/` e markdown, sem segredo, token ou credencial. O ledger segue em `$HOME` e fora do git, com o porquê reafirmado em `docs/pipeline.md` (o campo `repo` carrega caminho que identifica cliente). `PERMISSION_MODE` intocado, sem `bypassPermissions`. Nenhum `eval` novo; o único caminho de execução acrescentado é `"$SELF_PATH"` com argv fixo, e ele passou a derivar de `${BASH_SOURCE[0]}` em vez de um nome montado à mão. Os temp dirs saem por `mktemp -d` e agora também por `trap` |
| Performance | A | O predicado do ledger é emitido como **texto jq** e interpolado no programa, não avaliado por linha em bash — uma chamada de shell por linha forkaria por linha. O custo acrescentado pela r2 é 7 processos filhos curtos por execução do sensor (4 probes novos + 3 de composição, todos com os estágios stubados, sem escrever nenhum script de brinquedo); a suíte segue nos mesmos ~4 min, integralmente dominados pelos 44 mutantes. O estouro do alvo "<30 s" da D7 é escolha registrada no `01-plano.md` e no `TODO.md`, pendente de decisão humana — não um descuido desta rodada |
| Test Coverage | A | **É o critério que reprovava em r1, e o que mudou é medido.** 44/44 mutantes, 0 known gap. Os três fail-open do `check-entrypoint.sh` estão fechados **com probe**, não com remendo, e o conserto foi ele próprio submetido à sabotagem: 25 degradações, 20 morrem no sensor. Os 5 survivors estão nomeados no cabeçalho por grupo, e os 2 que são fail-open de fato foram **medidos** como cobertos pelo catálogo (`43 caught of 44` + rc 1 contra 44/44). A primeira versão do conserto tinha um buraco que só a sabotagem achou — prova de que a passada mede alguma coisa. O que ficou sem probe (os ramos de diagnóstico do `differential`) está no `TODO.md` com direção, não escondido |
| Documentation | A | Os cinco consertos de documentação da r1 estão de fato no repo agora (`5e3551e`), não só afirmados: `docs/pipeline.md` sem autocontradição, `agents/sdd-kaizen.md` com os quatro baldes, `README.md` alinhado ao `USAGE`, o planner ensinando as duas regras da célula do Check, `CLAUDE.md` separando rubrica de inventário. As 7 cópias em `.claude/agents/` byte-idênticas. Nesta rodada, **três afirmações falsas** foram corrigidas na fonte: o cabeçalho do sensor que dizia ter matado uma sabotagem que sobrevivia, o comentário dos "two independent paths" que eram um só, e a linha da r1 que dizia ter commitado o que não commitou. Nenhuma foi apagada — as três ficaram com o ⚠️ e o motivo, porque a forma do erro é o que ensina |
| **Overall** | **A** | Métrica do `00-missao.md` cumprida número a número; suíte, `sdd health` e os 5 Checks verdes; árvore limpa. Os dois HIGH que a r1 deixou abertos foram reproduzidos, consertados com probe e commitados, junto com um terceiro da mesma família que esta rodada achou e com os cinco consertos que a r1 alegou ter commitado e não commitou. O que sobra sem probe está nomeado no cabeçalho do sensor ou no `TODO.md`, com direção — nada foi fechado por afirmação |

## Recommended Actions

**Must fix:** nada. Os três HIGH estão fechados com probe e evidência.

**Registrado, fora de escopo (`TODO.md`):** os ramos de diagnóstico do `differential()` sem probe;
os cinco da r1 (lembrete pós-pipeline cego, `sdd retry` como quarta porta que commita, worktree
partindo a identidade do repo, linha sem `repo` lida como local, `doc_rule` faltando para a regra
do `|`); e os itens que o `00-missao.md` já declarava fora de escopo — o eixo do juiz com ADR e o
sensor de âncora podre do `check-todo.sh`.

**Nada a fazer:** os três refutados desta rodada e os cinco da r1, todos com evidência de comando.

**Para a fase DOCS:** o `KAIZEN_LOG.md` tem antes/depois medido de sobra — os 4 rc da métrica
(`127`/`0`/`0`/`0` → `0`/`1`/`1`/`1`), o catálogo de 40 → 44 a 100%, e o número desta rodada: um
sensor que passava com 3 fail-open reproduzidos hoje mata 20 de 25 degradações.
</content>
</invoke>
