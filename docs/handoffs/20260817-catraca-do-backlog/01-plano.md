---
missao: 20260817-catraca-do-backlog
data: 2026-08-17
---

# Plano — a catraca do backlog

> **Teste de autocontenção:** uma sessão nova, sem nenhuma memória da conversa que gerou este
> plano, lendo apenas `00-missao.md` + `01-plano.md` + `checkpoint.md`, consegue executar?
> Se a resposta for "só se souber X", **X vai escrito aqui**.

## Contexto verificado (não re-descobrir)

Tudo abaixo foi medido no HEAD `6d68dfc` durante o planejamento, com o comando ao lado.

**Estado de partida**

- `sdd health` verde: `suite green`, `mutation: score: 70 caught, 0 known gap(s), of 70`,
  `all 8 gates have a mutation`, `provenance: all 3 fixtures`, `ratchet: 6 known debt(s), none new`.
- `tests/check-todo.sh` imprime `  ok    68 finding(s), all within 8 lines and carrying anchor + date`
  e `  ok    selftest: 75 probe(s), …`.
- Catálogo: **70** definições `^mut_…() {` e **70** entradas no array `CATALOG=(` (`tests/check-mutation.sh:840`).
- `.sdd/config.sh`: `JIRA_ENABLED=false` (a fase TICKET é pulada), `TEST_CMD="tests/run-all.sh"`,
  `BUDGET_PER_PHASE_USD=25`, `OUTPUT_LANG="pt-BR"`.

**O mecanismo que a catraca reusa — não construir nada novo**

- `health_finding "<linha>"` (`bin/sdd:1693`) acumula em `HEALTH_FINDINGS`. É assim que
  `key-without-doc`, `cmd-not-in-help` e `var-never-read` entram (`:1752`, `:1767`, `:1780`).
- `health_ratchet` (`bin/sdd:1858`) compara `HEALTH_FINDINGS` com `tests/health-baseline.txt` nos
  **dois sentidos**: achado fora da baseline reprova, linha da baseline que deixou de ser achado
  reprova. Formato da baseline: `<check-id> <target>   # <dono>`; comentários e linhas vazias são
  descartados por `grep -vE '^[[:space:]]*(#|$)'` + `sed 's/[[:space:]]*#.*//'`.
- Consequência que dispensa código: quando a contagem cai de 68 para 58, o achado emitido vira
  `todo-findings 58` (fora da baseline) **e** a linha `todo-findings 68` fica órfã (baseline velha).
  Duas reprovações, a mesma edição. É a bidirecionalidade de graça.
- `cmd_health` (`bin/sdd:1702`) **já** captura `out="$( cd "$kit" && tests/run-all.sh 2>&1 )"` no
  check 1 e **já** faz `grep -m1 '^score: ' <<< "$out"` no check 2, com o comentário explicando por
  que linha ausente reprova ("would go blind and pass in silence"). A linha do `check-todo.sh` está
  nessa mesma `$out`. Copie o padrão inteiro, comentário incluído.

**O buraco que o I1 fecha**

- **Nenhum sensor executa `cmd_health`.** `grep -l 'sdd health' tests/*.sh` devolve
  `check-autonomy.sh` e `check-mutation.sh`, e nos dois é **comentário**
  (`check-autonomy.sh:1474`, `check-mutation.sh:97`). Verificado nesta sessão.
- ⚠️ **Recursão.** `cmd_health` roda `tests/run-all.sh` do `$SDD_HOME`. Um sensor que chame
  `sdd health` apontando para o kit real entra em laço (`run-all` → `check-health` → `sdd health` →
  `run-all`). O fixture **tem** de trazer um `tests/run-all.sh` stub que imprime as linhas canônicas
  (`score: …` e `  ok    N finding(s) …`) e sai 0.
- ⚠️ **O fixture copia o `bin/sdd` do `$ROOT`, nunca uma cópia congelada.** É essa cópia que faz a
  sabotagem do catálogo chegar ao sensor; um `bin/sdd` embutido no fixture torna toda mutação
  `mut_HEALTH_*` invisível e o catálogo passaria a creditar proteção inexistente.
- ⚠️ **`check-health.sh` não entra na guarda de `SDD_MUTANT`** do `tests/run-all.sh`. Três sensores
  são pulados dentro do mutante (`:103`, `:112`, `:119`); este não pode ser, porque existe
  exatamente para morrer com `mut_HEALTH_*`.

**Âncoras do cluster 1, re-derivadas — as do `TODO.md` estão ~870 linhas defasadas**

| defeito | `TODO.md` diz | real no HEAD |
|---|---|---|
| `US$ 2` sem casas | `bin/sdd:1617` | **2491** |
| `die` com a mesma mensagem para dois defeitos | `:1583` e `:1626` | **2363** e **2503** |
| bloco "no data" duplicado literalmente | `:1603-1605` e `:1620-1622` | **2357** e **2388** |
| tabela ordenando versão lexicograficamente | `:1848` | **2480** (contra `kaizen_series` em **2664**) |
| duas linhas em branco | `:1649-1652` | **2494-2499** |

A quinta merece detalhe porque o sintoma não está onde parece: as quatro strings de exclusão
(`:2496` a `:2499`) já começam com `\n`, e o `,` do `jq` entre saídas também insere quebra. Sem
escaladas e com linha não reconhecida, as duas somam e sobra a linha em branco.

**Regras da casa que mordem nesta missão**

- `tests/check-checkpoint.sh` varre **todo** `docs/handoffs/*/checkpoint.md`: célula de Check não
  pode ter `|` (nem `\|`), e Check que faz `2>&1` **e** `grep` tem de ancorar em `^  ok    ` —
  quatro espaços, com o `^`.
- ⚠️ Sensor imprime `  ok    ` com **quatro** espaços; o runner (`ok` de `bin/sdd`) imprime
  `  ok   ` com **três**. O `KAIZEN_LOG.md` já registrou um degrau fantasma por confundir os dois.
  Nenhum Check deste plano lê saída do runner.
- Sensor novo leva **passada de sabotagem adversarial** antes de ser considerado pronto: degrade
  cada regra para uma versão mais frouxa e exija vermelho em cada uma. `check-health.sh` **não**
  leva `selftest()`: a mutação o alcança (ela sabota o `bin/sdd`, e o sensor tem de morrer).
- Asserção sobre "X responde diferente de Y" é escrita **diferencial**: dois fixtures, saídas
  comparadas entre si. Vale para as duas mensagens de `die` do I3 e para os dois ramos da catraca.
- `printf … | grep -q` devolve 141 sob `pipefail`. Use herestring.

## Arquitetura da mudança

Três superfícies, nenhuma nova:

1. **`bin/sdd`** — `cmd_health` ganha um check; `cmd_autonomy` tem cinco defeitos de saída
   corrigidos. Nenhuma função nova além de um helper local para o bloco "no data".
2. **`tests/`** — nasce `check-health.sh` (o primeiro sensor sobre `cmd_health`);
   `check-autonomy.sh` ganha cinco asserções; `check-mutation.sh` ganha sete entradas;
   `health-baseline.txt` ganha a linha da contagem e um cabeçalho que admite a classe;
   `run-all.sh` passa a invocar o sensor novo.
3. **Documento** — `CLAUDE.md` e o cabeçalho do `TODO.md` recebem a política, com `doc_rule`
   cobrando os dois, na forma que `check-checkpoint.sh` já usa.

O fluxo da catraca, ponta a ponta: `check-todo.sh` conta e imprime → `run-all.sh` agrega na stdout
→ `cmd_health` captura essa stdout uma vez (check 1) → o check novo extrai o número dela →
`health_finding` acumula → `health_ratchet` compara com a baseline nos dois sentidos.

**A contagem nunca é recalculada.** É um contrato entre dois arquivos, exatamente como a linha
`score:`: `tests/check-todo.sh` escreve, `bin/sdd` lê. O comentário no ponto de leitura tem de
dizer isso, porque mudar a frase de um lado só cega o outro em silêncio.

## Incrementos

A tabela executável vive em `checkpoint.md` (é ela que o runner lê). Aqui fica o **porquê** de
cada fatia — o detalhe que não cabe numa célula.

### I1 — `tests/check-health.sh`, o primeiro sensor sobre `cmd_health`

**O quê:** um sensor que monta um kit-fixture, roda `bin/sdd health` contra ele e prova que as
checagens do comando **discriminam** — hoje ninguém sabota nada ali.
**Onde:** `tests/check-health.sh` (novo), `tests/run-all.sh`, `tests/check-mutation.sh`
**Como (TDD):** o sensor primeiro, vermelho porque o arquivo não existe (medido: `0`). Cinco
asserções, e a ordem importa — a quinta é piso, não enfeite:

1. `the ratchet fails on a finding outside the baseline`
2. `the ratchet fails on a stale baseline line`
3. `the two ratchet failures accuse different things` — **diferencial**: os dois fixtures acima,
   saídas comparadas entre si. Sem ela, uma catraca que reprovasse tudo com a mesma frase passaria.
4. `provenance fails when an installed skill is missing`
5. `the green fixture reaches kit healthy` — **piso contra vacuidade**. Sem ele, todas as quatro
   acima são satisfeitas por um fixture que reprova por motivo alheio, e o sensor afirma ter medido
   o que não mediu.

**Check:** `o=$(bash tests/check-health.sh 2>&1); grep -c '^  ok    the ratchet fails on a stale baseline line' <<< "$o"` → `1` (medido no HEAD: `0`)
**Sensor durável:** o próprio arquivo, mais `mut_HEALTH_ratchet_one_way` (apaga o laço de baseline
órfã — a asserção 2 morre, a 1 sobrevive, e é o par que prova que a 3 mede) e
`mut_HEALTH_provenance_blind` (proveniência sempre passa). Entram no `CATALOG` no mesmo commit.
**Reversível por:** apagar o arquivo, a linha do `run-all.sh` e as duas entradas do catálogo.

### I2 — a catraca da contagem

**O quê:** `cmd_health` ganha o check que extrai `N` de `^  ok    ([0-9]+) finding\(s\)` na `$out`
já capturada no check 1 e chama `health_finding "todo-findings $N"`; linha ausente é `health_bad`,
com o mesmo comentário do check do `score:`. `tests/health-baseline.txt` ganha `todo-findings 68`.
**Onde:** `bin/sdd` (`cmd_health`), `tests/health-baseline.txt`, `tests/check-health.sh`,
`tests/check-mutation.sh`
**Como (TDD):** duas asserções novas no sensor do I1, escritas antes do check:
`a baseline off by one fails both ways` (fixture com contagem 68 e baseline 67 → rc 1 **e** as duas
mensagens presentes) e `the count check dies when the suite prints no finding count` (stub que
omite a linha).
**Check:** `o=$(bash tests/check-health.sh 2>&1); grep -c '^  ok    a baseline off by one fails both ways' <<< "$o"` → `1` (medido no HEAD: `0`)
**Sensor durável:** `mut_HEALTH_todo_count_blind` — apaga a chamada de `health_finding`.
⚠️ Note que a mutação é pega pelo ramo **de baseline órfã**, não pelo de achado novo: sem emissão,
a linha da baseline fica sem par. Isso é correto e vale registrar no comentário da entrada, para a
próxima sessão não "consertar" a mutação achando que ela mira o ramo errado.
**Reversível por:** remover o bloco do check e a linha da baseline; a baseline sem o par volta a
ficar consistente sozinha.

### I3 — os cinco defeitos de saída do `cmd_autonomy`

**O quê:** as cinco correções cosméticas, com as âncoras da tabela acima (não as do `TODO.md`).
`printf` com duas casas em `:2491`; duas mensagens distintas nos `die` de `:2363` e `:2503`; helper
local para o bloco `warn`+`dim`+`return 1` repetido em `:2357` e `:2388`; ordem da tabela alinhada
com a de `kaizen_series` em `:2480`; e a linha em branco sobrando em `:2494-2499`.
**Onde:** `bin/sdd` (`cmd_autonomy`), `tests/check-autonomy.sh`
**Como (TDD):** cinco asserções novas em `tests/check-autonomy.sh`, todas prefixadas `output:` para
serem contáveis. A das duas mensagens de `die` é **diferencial** — dois fixtures (JSON inválido e
JSON válido de shape errada), saídas comparadas entre si —, porque uma asserção que só procure o
texto de uma delas continua verde depois de a outra ser reescrita para dizer a mesma coisa.
**Check:** `o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    output:' <<< "$o"` → `5` (medido no HEAD: `0`)
**Sensor durável:** as cinco asserções em `check-autonomy.sh`, que já roda no `run-all.sh`.
**Reversível por:** cada correção é independente; reverter uma não afeta as outras quatro.

### I4 — as mutações que faltam no catálogo

**O quê:** quatro entradas novas, **depois de re-derivar** — três dos quatro itens podem estar
parcial ou totalmente vencidos, e fechar por evidência é resultado legítimo:

- ⚠️ `mut_RUN_moved_never_true` **já existe**. O item pede mutação para a asserção
  `sdd retry that changed the disk records moved:true` (`tests/check-autonomy.sh:208`) e pode já
  estar coberto. Confira antes de escrever.
- ⚠️ Existem **quatro** `mut_RUN_degraded_*` (`row_dropped`, `repeats`, `label_blind`, `spins`)
  contra um item que pede mutação para "três das quatro metades" (`bin/sdd` — o `select` da série,
  `pipeline_log_line`, e o `is_escalation` do `cmd_autonomy`). Mapeie mutação × ponto antes de
  concluir que falta alguma.
- O call site de `ensure_mission_branch` no `cmd_retry` não tem entrada: existe
  `mut_RUN_branch_switch_dead` para o `cmd_run` e `mut_RETRY_base_branch_warn_dead` para outra
  coisa. Alvo: `mut_RETRY_branch_switch_dead`.
- `cmd_kaizen`: `kaizen_reminder` e o ramo idempotente "already judged" têm asserção em
  `tests/check-kaizen.sh` sem sabotagem que prove que elas medem algo.

**Onde:** `tests/check-mutation.sh`
**Como (TDD):** cada entrada nasce sabotando o alvo à mão e confirmando que a suíte morre **pela
asserção certa** — não por rc compartilhado. Entrada cuja sabotagem deixe tudo verde vira achado no
`TODO.md`, não entrada no catálogo.
**Check:** `grep -cE '^mut_[A-Za-z0-9_]+\(\) \{' tests/check-mutation.sh` → `77` (medido no HEAD: `70`)
⚠️ A aritmética é `70 + 2 (I1) + 1 (I2) + 4 (I4)`. Se a re-derivação fechar um item por evidência
em vez de por código, **recalcule o esperado e registre o novo número nas Notas de execução** — o
`77` é derivado, não sagrado.
**Sensor durável:** o próprio catálogo, cobrado por `sdd health` (`0 known gap(s)`).
**Reversível por:** remover as entradas do array `CATALOG` e as funções.

### I5 — a política escrita, e a baseline no número real

**O quê:** a regra da catraca escrita onde a próxima missão a encontra, mais a baseline ajustada ao
número que o arquivo realmente tem no fim da missão, mais `RESOLVIDO por <hash>` no corpo dos itens
fechados.
**Onde:** `CLAUDE.md`, `TODO.md` (cabeçalho), `tests/health-baseline.txt` (cabeçalho e valor),
`tests/check-health.sh`
**Como (TDD):** um `doc_rule` em `check-health.sh` — mesma forma que `check-checkpoint.sh` usa —
exigindo a regra nos dois documentos, escrito antes do texto. O cabeçalho da baseline hoje afirma
que **toda** linha tem um item do `TODO.md` como dono; a linha da contagem não tem, e o cabeçalho
passa a admitir a classe em vez de a linha ganhar um dono falso.
⚠️ Os itens fechados **não são apagados nesta missão**: recebem `RESOLVIDO por <hash>` e saem do
arquivo só depois do merge do PR, provado por `git merge-base --is-ancestor <hash> main`. Portanto
a contagem no fim da missão **não** cai para 58 — ela cai na varredura pós-merge, e é lá que a
catraca cobra a baseline de novo. Escreva na baseline o número real medido, não o desejado.
**Check:** `o=$(bash tests/check-health.sh 2>&1); grep -c '^  ok    the ratchet policy is written where the next mission meets it' <<< "$o"` → `1` (medido no HEAD: `0`)
**Sensor durável:** o `doc_rule`, que reprova o dia em que a regra sair de qualquer um dos dois
documentos.
**Reversível por:** remover o `doc_rule` e os dois parágrafos.

## Riscos e não-feitos

| Risco | Probabilidade | Mitigação |
|---|---|---|
| Recursão `run-all` → `check-health` → `sdd health` → `run-all` | alta se ignorada | fixture obrigatório com `run-all.sh` stub; o Check do I1 não termina se houver laço |
| Fixture com `bin/sdd` congelado torna toda `mut_HEALTH_*` invisível | média | o fixture copia `$ROOT/bin/sdd`; as duas mutações do I1 provam que a cópia é viva |
| A missão descobre itens novos e a catraca reprova no fim | **alta — é o desenho** | I5 mede o número real e ajusta a baseline; o crescimento aparece no diff, que é o objetivo |
| Um item do cluster 2 já está coberto e o `77` do I4 fica errado | média | o I4 manda re-derivar primeiro e recalcular o esperado nas Notas |
| `check-health.sh` deixa a suíte mais lenta (hoje ~33 s, alvo D7 de 30 s já estourado) | média | o fixture é stub, não roda suíte de verdade; se passar de ~2 s, vira achado no `TODO.md` |
| Correção cosmética do `cmd_autonomy` muda contagem sem querer | baixa | as cinco asserções `output:` do I3 rodam junto com as asserções de contagem que já existem |

**Não-feitos declarados:** cluster 3 (9 itens, falha aberta), cluster 4, cluster 5 (4 decisões
humanas pendentes), i18n, e qualquer mudança em `tests/check-todo.sh`.

## Verificação end-to-end

Com os cinco incrementos `done`, nesta ordem:

1. `tests/run-all.sh` → verde, com `score: 77 caught, 0 known gap(s), of 77`.
2. `./bin/sdd health` → `kit healthy`, e a linha da catraca passa a contar 7 dívidas conhecidas
   (as 6 de hoje mais `todo-findings`).
3. Edite `tests/health-baseline.txt` trocando o número da contagem por um valor errado por 1 e rode
   `./bin/sdd health` de novo: tem de reprovar com **as duas** mensagens (`finding outside the
   baseline` e `stale baseline`). Desfaça a edição. É esta a demonstração da métrica 1 — a
   bidirecionalidade medida no repo real, não só no fixture.
4. `grep -c 'RESOLVIDO por' TODO.md` → `12` (os 10 itens fechados mais as 2 ocorrências da prosa do
   cabeçalho, linhas 16 e 24).
