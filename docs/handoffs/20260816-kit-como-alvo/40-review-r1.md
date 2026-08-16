---
missao: 20260816-kit-como-alvo
fase: REVIEW
rodada: r1
status: continua
sessao: 76c0b67a-637e-4760-92e5-88b7f7c5395a
data: 2026-08-16 20:10
gate: "NÃO fecha em r1. `tests/run-all.sh` verde (rc 0, `score: 44 caught, 0 known gap(s), of 44`), `sdd health` verde, os 5 Checks do checkpoint em `0`/`1`/`1`/`1`/`01`, secrets pre-scan 0 achados, as 7 cópias de `.claude/agents/` byte-idênticas. Cinco achados de documentação foram consertados e commitados; **dois HIGH em `tests/check-entrypoint.sh` continuam abertos** (fail-open na asserção de forma e no `probe()`), reproduzidos com sabotagem. A rodada r2 os fecha."
---

# Revisão — rodada 1 — quando o kit é o próprio alvo

> Rodada 1 de no máximo `REVIEW_MAX_ITER=3`. **Não fecha.** A tabela `### Overall Grade` abaixo
> traz a nota real, não a nota que faria o gate passar.

## Como esta rodada foi conduzida

Diff da missão: `git diff main...HEAD` — 23 arquivos, +2701/−78, 21 commits sobre `8ca54b8`.
A revisão rodou o `codereview` com quatro passadas adversariais paralelas (runner, os dois
sensores novos, os sensores modificados, sincronia de documentação) e reconferiu tudo o que
elas afirmaram. O relatório da QA (`30-handoff-qa.md`) estava em mãos: nada que a QA já cobriu
com o `F1` foi recontado como achado.

**Medições de partida, todas rodadas nesta sessão contra `041e171`:**

| O que | Resultado |
|---|---|
| `bash tests/run-all.sh` | verde, rc `0`, `score: 44 caught, 0 known gap(s), of 44` |
| `bash bin/sdd health` | `kit healthy` — 8 gates com mutação, 3 fixtures com proveniência, 6 dívidas, nenhuma nova |
| Checks I1/I2/I3/I4/F1 | `0` · `1` · `1` · `1` · `01` (no HEAD do plano: `127` · `0` · `0` · `0` · `00`) |
| Secrets pre-scan (regex catalog) | `{"findings":[],"scanners":["regex"],"errors":[]}` |
| `cmp` de `agents/*.md` × `.claude/agents/` | 7/7 idênticos — o `cmp -s` do I3 não reprova nesta branch |
| `bash tests/check-todo.sh` | verde, 63 achados, todos dentro de 8 linhas com âncora e data |
| `bash bin/sdd status` | `next phase: REVIEW`, 5/5 incrementos lidos com hash |

A métrica do `00-missao.md` está **cumprida**, número a número. O que segue não a contesta:
contesta a qualidade de dois sensores que a missão criou.

## Achados consertados nesta rodada

⚠️ **Corrigido pela r2:** esta linha dizia "todos commitados em `<hash-r1>`" e o placeholder nunca
foi substituído — porque a r1 **não commitou nada**. A r2 encontrou os cinco consertos na árvore
suja (`git status` com 8 arquivos modificados e este relatório sem rastrear) e os commitou junto
com os seus. A afirmação era exatamente a família de defeito que esta missão existe para matar:
um rótulo ("commitado") sobre um artefato que não existia. Os cinco consertos abaixo são reais e
estão medidos; só a atribuição de commit estava errada.

| # | Sev. | Onde | Achado | Conserto |
|---|---|---|---|---|
| 1 | CRITICAL | `docs/pipeline.md:373-374` | O documento afirmava `P` e `¬P` com 94 linhas de distância: `:279` ensina "the file is global; the READING is per repo" e `:374` continuava dizendo que a série é "readable from any repo since the ledger is global". Medido: fora de repo git a série volta **vazia** com `other_repo: 31` | a frase passou a dizer "about the repo it runs in — the file is global, the reading is not" |
| 2 | HIGH | `agents/sdd-kaizen.md:33` | A shape do `excluded` é descrita em dois lugares; só `docs/pipeline.md` aprendeu o quarto balde. O agente é **o juiz**, e `:35` o manda citar exatamente essa enumeração — `other_repo` é o único balde capaz de esvaziar a série sozinho | a enumeração virou quatro baldes, com a instrução explícita de citar `other_repo`; cópia em `.claude/agents/` sincronizada por `sdd install --force` |
| 3 | MEDIUM | `README.md:60` | `sdd autonomy` descrito como "from the global ledger" enquanto o `USAGE` do próprio runner (`bin/sdd:2405`) já dizia "for THIS repo". Nada no `sdd health` compara README com `--help` | README alinhado ao `USAGE` |
| 4 | MEDIUM | `agents/sdd-planner.md` | O planner ensinava a regra do âncora `^  ok    ` mas **não** a regra do `\|` — e é ele quem escreve o checkpoint. A regra do pipe custou uma missão inteira (`TODO.md`, `2897a94`) | o banner do `\|` entrou no planner, no mesmo texto do `templates/checkpoint.md`; cópia sincronizada |
| 5 | LOW | `CLAUDE.md:120-125` | "hoje há quatro sensores" na rubrica de auto-teste é verdade para a rubrica, mas `grep -l selftest tests/` devolve **cinco**: o `check-entrypoint.sh` carrega um por escolha própria. Lido como inventário, o número mente | ⚠️ acrescentado separando rubrica de inventário; linha 116 re-quebrada na convenção do arquivo |

## Achados que NÃO fecharam — por que esta rodada não é Grade A

Os dois vieram da passada de sabotagem adversarial sobre `tests/check-entrypoint.sh` (24
degradações isoladas + 5 combinações). Os dois são **fail-open**, que o `CLAUDE.md` nomeia como
o pior modo possível num sensor, e os dois foram **reproduzidos**, não deduzidos.

**R1-A · HIGH · `tests/check-entrypoint.sh:124` — a igualdade afrouxada para substring passa verde.**
Trocar `[ "$got" != "$GUARDED_FORM" ]` por um `case "$got" in *"$GUARDED_FORM"*)` deixa os três
`ok` no lugar. E não é afrouxamento inócuo: um script cuja última linha executável é
`note='{ main "$@"; exit $?; }'` **cai de volta em si mesmo** e passa a ser aceito (`--check` rc 0
contra rc 1 no original). O cabeçalho do sensor, em `:53`, lista "a igualdade afrouxada para
substring" entre as sabotagens que morreram — morre só a direção oposta (`$GUARDED_FORM` contendo
`$got`), porque todo fixture não-guardado dos probes é **mais curto** que a guarda e nenhum
consegue contê-la. Falta o probe: arquivo cuja última linha executável *contém* a forma sem *ser*
a forma, esperando rc 1. **A afirmação do cabeçalho precisa ser corrigida junto** — sensor que
declara ter medido o que não mediu é exatamente a família que esta missão existe para matar.

**R1-B · HIGH · `tests/check-entrypoint.sh:216-219` — o selftest imprime `SENSOR-BROKEN` e sai 0.**
Apagar a contabilidade do ramo de rc divergente (`FAILS=$((FAILS+1)); fail_rc 91`) fica latente
sozinho; combinado com `check_file` sempre `return 0` o sensor **grita e passa**: duas linhas
`SENSOR-BROKEN: … wanted rc 1, got 0` na stderr e rc `0`. Como `tests/run-all.sh:22` lê **só o
rc**, isso é verde na suíte. A testemunha de `:288` não ajuda — o filho foi mesmo lançado 10×. O
comentário de `:304` afirma "two independent paths from 'a probe failed' to 'the selftest fails'";
os dois caminhos são a jusante da **mesma** linha `FAILS=$((FAILS+1))`, e apagá-la remove os dois.
É a lição do `check-todo.sh` ("o selftest tem de exercitar o CAMINHO") um nível acima: nada probe
o caminho de **reporte** do próprio `probe()`.

Ambos entram na rodada r2 com probe — não com remendo. Os MEDIUM/LOW da mesma passada
(sem probe no ramo `guarded -ne 1`; cada asserção de topo removível com um `true`; `SELF_PATH`
com nome fixo em vez de `${BASH_SOURCE[0]}`; ausência de `trap` de limpeza; os falsos positivos
`C`, `G`, `I`, `J` não documentados no cabeçalho) são da mesma vizinhança e serão avaliados
juntos: a regra da casa é que remendo de sintoma vira o próximo sintoma.

## Achados aceitos e registrados no `TODO.md` (não entram no diff)

Quatro achados reais que **não cabem nesta missão** — mudam pergunta de desenho ou pedem sensor
próprio — e por isso viraram linha no `TODO.md`, nunca desapareceram:

1. **O lembrete pós-pipeline manda o humano a um comando cego** — `kaizen_reminder` roda com
   `REPO_ROOT` = repo-ALVO e conta as missões dele; o juiz roda no repo do KIT e, com o filtro,
   lê `latest: null`. Reproduzido em fixture: 3 missões viram "run 'sdd kaizen' in the kit repo",
   e lá a guarda é `0/0/0`.
2. **`sdd retry` é a quarta porta que commita e não avisa** — `cmd_retry` chama `run_phase` sem
   `warn_if_on_base_branch`, e o comentário da função declara "as três portas". Uma linha de
   conserto, mas call site sem asserção é justamente o defeito que as notas do I4 registraram;
   entra com a asserção diferencial junto.
3. **Worktree do git parte a identidade do repo** — `--show-toplevel` é por worktree, então
   missão rodada num worktree some da série lida do checkout principal.
4. **Linha sem `repo` é "local" em todo repo** — `is_unrecognized` olha `.event`, não `.repo`, e
   o comentário de `bin/sdd:785` afirma o contrário. 3 linhas assim bastaram, em fixture, para
   virar `guard.sufficient` para `true`. Hoje são 0 no ledger real.

E um quinto, de sensor: **a regra do `\|` não tem `doc_rule`** em `tests/check-checkpoint.sh` —
apagar o banner do template e do planner deixa o sensor verde.

## Achados refutados, com evidência

- **"O `{ main "$@"; exit $?; }` muda o código de saída"** — não muda. Sob `set -e` o shell sai
  com o status de `main` antes de `exit $?` rodar, e nos dois casos o rc é o mesmo: medido em
  `bash -c 'set -euo pipefail; main(){ return 7; }; …'` → `7` nas duas formas, e
  `help`/`version`/`bogus`/`autonomy` dando `0/0/1/1` no runner real e na cópia com a linha nua.
- **"O filtro por repo cega o juiz e isso é regressão não registrada"** — o efeito é real
  (`guard.sufficient` fica insatisfazível no repo do kit, onde cada incremento gera um `kit_sha`
  novo: 31 grupos de 1 sessão), mas **já está registrado**: `TODO.md` o carrega em dois itens (o
  eixo do juiz e "o juiz no repo do kit deixou de enxergar missão de repo-alvo"), e o
  `00-missao.md` o declara fora de escopo por exigir ADR. Não é achado novo desta rodada.
- **"O `_fail` multilinha do preflight quebra a contagem"** — não quebra. Medido ponta a ponta
  num fixture com `claude`/`gh` stubados: baseline `1 check(s) failed`, e depois de um byte
  alterado em `.claude/agents/sdd-kaizen.md`, `2 check(s) failed` — exatamente +1, com a mensagem
  de três linhas renderizada.
- **"O `--arg repo` pode faltar em algum splice do jq"** — não falta: os três sítios
  (`bin/sdd:1915`, `:1958`, `:2048`) passam `--arg repo "$repo"`, e `--arg` liga no escopo
  externo, visível dentro de um `def` de topo (confirmado em jq 1.7).
- **"O mutante novo do entry point pode ter âncora podre"** — não tem: o `sed` com delimitador
  `|` altera o arquivo (não é rc 90), o mutante passa no `bash -n` (não é rc 91) e mata a suíte
  pela asserção pretendida, e só por ela.

## Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | A | Uma definição por programa em ambos os casos (`ledger_row_is_local`, `warn_if_on_base_branch`), exatamente a regra que nasceu do par `blocked`/`degraded`; os mutantes sabotam a **definição** e não um call site, o que é o que prova que os três leitores passam mesmo por ela. Comentários explicam o porquê, não o quê. As cinco divergências de documentação achadas nesta rodada foram consertadas |
| Type Safety | A | Não há sistema de tipos; o equivalente é o contrato de shape, e ele está fechado: `excluded` ganhou o quarto balde nos **dois** produtores da mesma shape (jq e o literal do ledger vazio, `bin/sdd:2006`), e `check-kaizen.sh` compara os dois como conjuntos de chave — a metade que só existia para `guard` passou a existir para `excluded`. `shellcheck -S warning` limpo em `bin/sdd` e em `tests/*.sh` |
| Error Handling | A | Três silêncios nomeados à parte no `cmd_autonomy` (arquivo vazio · cwd sem repo · ledger de outro repo) em vez de um "no data" que mandaria o leitor caçar um runner que nunca escreveu; o que sai é **contado**, nunca sumido (`other_repo`); linha que não sabe dizer de onde veio nunca é excluída, para não esconder corrupção; o preflight distingue "ausente" de "stale" porque são consertos diferentes; o aviso de branch base continua `warn` e jamais `die`, com o `rc` afirmado nos dois ramos |
| Security | A | Secrets pre-scan determinístico (catálogo regex canônico) → 0 achados, 0 erros. Nenhum segredo, token ou credencial no diff. O ledger segue em `$HOME` e fora do git — `docs/pipeline.md` reafirma o porquê (o campo `repo` carrega caminho que identifica cliente). `PERMISSION_MODE` intocado, sem `bypassPermissions`. Nenhuma execução de string construída, nenhum `eval` novo |
| Performance | A | O predicado é emitido como **texto jq** e interpolado no programa, não avaliado por linha em bash — uma chamada de shell por linha do ledger forkaria por linha. A suíte foi de ~3 para ~4 min, integralmente por causa dos 4 mutantes novos (cada mutante é uma suíte inteira); é escolha registrada no `01-plano.md` e no `TODO.md`, com a régua de tempo pendente de decisão humana, não um descuido |
| Test Coverage | C | **É por aqui que a rodada não fecha.** A cobertura de comportamento é forte — 44/44 mutantes, 0 known gap, e as asserções novas são diferenciais que nenhum regime de fixture satisfaz por acidente (a sabotagem prova que desligar o filtro só num leitor mata só um sensor). Mas o `tests/check-entrypoint.sh` tem **dois fail-open reproduzidos** (R1-A e R1-B): a asserção de forma aceita um arquivo que cai de volta em si mesmo quando afrouxada para substring, e o `probe()` pode imprimir `SENSOR-BROKEN` e sair `0`, o que a suíte lê como verde. Um deles é afirmado como testado no cabeçalho do próprio sensor |
| Documentation | A | Depois dos consertos desta rodada: `docs/pipeline.md` sem autocontradição, `agents/sdd-kaizen.md` com os quatro baldes, `README.md` alinhado ao `USAGE`, o planner ensinando as **duas** regras da célula do Check, `CLAUDE.md` separando rubrica de inventário. As 7 cópias em `.claude/agents/` byte-idênticas — o que o próprio `cmp -s` desta missão passou a cobrar. Os 21 comentários de execução do `checkpoint.md` registram três desvios do plano com o motivo medido, incluindo uma asserção prevista que era **vácua** e por isso não foi escrita |
| **Overall** | **C** | Métrica da missão cumprida, suíte e `sdd health` verdes, cinco divergências de documentação consertadas e commitadas. Não fecha em A porque **dois HIGH de fail-open continuam abertos** num sensor que esta missão criou — e um sensor que afirma ter medido o que não mediu é literalmente a família de defeitos que esta missão existe para matar. Fechá-los em `r2` |

## Recommended Actions

**Must fix (r2):**
1. `tests/check-entrypoint.sh:124` — probe para "última linha executável **contém** a forma sem
   sê-la", esperando rc 1; corrigir a afirmação do cabeçalho em `:53`.
2. `tests/check-entrypoint.sh:216-219` — probe que dirige o `probe()` com expectativa
   deliberadamente errada e exige rc não-zero do selftest; separar de fato os dois caminhos que
   `:304` afirma serem independentes.

**Consider fixing (r2, mesma vizinhança — avaliar juntos, não remendar um a um):**
piso de composição (as três asserções rodaram); probe do ramo `guarded -ne 1`; `SELF_PATH` via
`${BASH_SOURCE[0]}`; `trap` de limpeza; falsos positivos `C`/`G`/`I`/`J` nomeados no cabeçalho.

**Registrado, fora de escopo:** os cinco itens do `TODO.md` listados acima.

**Nada a fazer:** os cinco achados refutados, com a evidência acima.
