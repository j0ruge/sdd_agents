---
missao: 20260818-lote-facil
data: 2026-08-18
---

# Plano — O `sdd health` para de morrer calado, e 18 achados baratos saem do backlog

> **Teste de autocontenção:** uma sessão nova, sem nenhuma memória da conversa que gerou este
> plano, lendo só `00-missao.md` + `01-plano.md` + `checkpoint.md`, consegue executar. Todas as
> âncoras abaixo foram **re-derivadas em 2026-08-18 contra `9207b4d`**; 8 das 18 estavam podres e a
> defasagem está anotada em cada uma.

## Contexto verificado (não re-descobrir)

- `main` está em `9207b4d` (merge do PR #11). `tests/check-todo.sh` → **56 finding(s)**;
  `tests/health-baseline.txt` → `todo-findings 56`; `score: 81 caught, 0 known gap(s), of 81`;
  `./bin/sdd health` → `kit healthy`.
- **A suíte leva ~3m30s** e todo gate a roda. `sdd phase` e `sdd why` bloqueiam por esse tempo.
- ⚠️ **Nunca contar achados com `grep -c '^- \[ \]' TODO.md`** — responde **um a mais**, engolindo
  a linha de exemplo do bloco cercado no cabeçalho. A contagem sai de `tests/check-todo.sh`, e é
  dela que a catraca do `sdd health` se alimenta.
- **Toda fase que mexe no `TODO.md` move `todo-findings` no mesmo commit.** A catraca reprova nos
  **dois** sentidos: `finding outside the baseline` e `stale baseline`.
- `JIRA_ENABLED=false` → a fase TICKET é pulada. `BUDGET_PER_PHASE_USD=40` neste repo (o default do
  kit segue 15). `OUTPUT_LANG="pt-BR"`, mas **a superfície do kit é inglês**: código, comentário,
  nome de asserção e prosa em `bin/ tests/ docs/ config/ agents/ README` nascem em inglês, e
  `tests/check-lang.sh` cobra com catraca bidirecional.
- `set -euo pipefail` está em `bin/sdd:14`. É a causa raiz do I1.
- **`SDD_HOME` é `readonly`** (`bin/sdd:47`) e resolvido do caminho do próprio script: não dá para
  apontá-lo por variável de ambiente. Para sondar `cmd_health` fora do repo, **copie o kit** e
  invoque a cópia (foi assim que as 4 sondas do I1 foram medidas).
- ⚠️ **`printf … | grep -q` devolve 141 sob `pipefail`** quando o grep ACHA (SIGPIPE). Use
  herestring (`<<< "$var"`). Mesma família: `grep -m1`.
- ⚠️ **O `awk` desta máquina é `mawk`, orientado a BYTE.** Classe negada com caractere multibyte
  (`[^—]`) nega os bytes dele, não o caractere. Para separador literal use `index()`/`substr()`.
- **Prefixos de asserção já em uso** (a contagem de partida de cada Check depende disto):
  `cdpath:` = **2** (ambas em `tests/check-autonomy.sh`, sobre `ledger_repo_root`), `output:` = **6**
  (em `tests/check-autonomy.sh`). `abort:`, `covered:` e `rule:` estão **livres** (0 ocorrências).
- **A saída dos mutantes é suprimida** — cada mutante imprime uma linha só (`ok  <NOME> — the suite
  dies (rc 1)`), então contar prefixo sobre a saída de `tests/run-all.sh` não infla.

## Arquitetura da mudança

Nada de mecanismo novo. Cada incremento é uma família de defeitos **do mesmo mecanismo**, consertada
de uma vez, com a asserção morando num sensor que **já existe**:

| incremento | mecanismo | sensor que recebe a asserção |
|---|---|---|
| I1 | atribuição de substituição de comando sob `set -e` | `tests/check-health.sh` |
| I2 | `cd` com operando relativo sem `CDPATH=''` | `tests/check-pipefail.sh` + `tests/check-autonomy.sh` |
| I3 | número impresso ao humano que conta a grandeza errada | `tests/check-autonomy.sh` |
| I4 | caminho de código sem asserção (logo sem mutação possível) | `check-health` / `check-autonomy` / `check-kaizen` / `check-gates` |
| I5 | regra de sensor sem probe, e o template que falta | `check-pipefail` / `check-checkpoint` / `check-todo` / `check-templates` |

**Regra transversal, válida nos cinco:** asserção nova entra **com mutação** em
`tests/check-mutation.sh` — `sdd health` reprova gate sem mutação, e sabotar a asserção e exigir
que a suíte morra é o que distingue asserção viva de decoração.

**Regra transversal 2:** o probe de sabotagem **prova primeiro que sabotou o que dizia sabotar**.
Ancore em CÓDIGO, nunca em número de linha, e faça o probe morrer alto quando o trecho que ele
esperava mudar não mudou. Conclusão de probe vazio não vale, nem quando aponta para o lado certo
por acaso.

## Incrementos

A tabela executável vive em `checkpoint.md` (é ela que o runner lê). Aqui fica o **porquê**.

### I1 — a família do aborto calado (3 itens do `TODO.md`, 4 sítios)

**O quê:** `out="$(cmd)"` sob `set -euo pipefail` mata o script **na atribuição** quando `cmd`
devolve não-zero; o `health_bad` da linha seguinte vira código morto. Quatro sítios, todos em
`cmd_health`.

**Onde e o que foi medido** (sondas executadas em 2026-08-18 com o runner real, kit copiado,
controle verde `kit healthy` / rc 0 antes de cada uma):

| sítio | linha (re-derivada) | âncora do `TODO.md` | sonda | o que se vê hoje |
|---|---|---|---|---|
| suíte vermelha | `bin/sdd:1708` | dizia `:1588` ⚠️ **podre, ~120 linhas** | `run-all.sh` que sai 1 | só o cabeçalho, rc 1 |
| linha `score:` ausente | `bin/sdd:1721` | `:1721` ✅ | suíte verde e muda sobre o score | `ok suite green`, rc 1 |
| `~/.claude/plugins/cache` ausente | `bin/sdd:1854` | `:1854` ✅ | `HOME` vazio | morre após o check de gates, rc 1 |
| baseline sem linha viva | `bin/sdd:1882` (a atribuição `known=`) | `:1882` ✅ | baseline só com comentários | morre após a proveniência, rc 1 |

**Como (TDD):** a asserção **primeiro**, no `tests/check-health.sh` — que nasceu no PR #7 com
fixture hermético e é o primeiro sensor da suíte que executa `cmd_health`. Cada sítio ganha um par
**diferencial**: com o defeito presente a saída tem `N` linhas e nunca contém o texto do
`health_bad`; com o conserto ela contém o texto **e** os checks seguintes continuam aparecendo.
Rodar as 4 asserções antes do conserto e exigir vermelho.

⚠️ O sítio da suíte vermelha é o que mais importa e o mais fácil de "provar" mal: `rc 1` sozinho
**não** discrimina, porque o `health_bad` também termina em rc 1. A asserção tem de exigir as duas
coisas — o texto `suite red` presente **e** um check posterior presente. Sem a segunda metade ela
passa igual com o defeito.

**Conserto:** `|| rc=$?` ou `if out="$(…)"; then`, como o check da contagem do `TODO.md` (check 3)
já faz — há um exemplo pronto no mesmo arquivo.

**Sensor durável:** 4 asserções em `tests/check-health.sh` prefixadas `abort:` + 4 entradas
`mut_HEALTH_*` em `tests/check-mutation.sh` (o arquivo já tem `mut_HEALTH_ratchet_one_way`,
`mut_HEALTH_provenance_blind` e `mut_HEALTH_todo_count_blind` como modelo de forma).

**Check:** `o=$(bash tests/check-health.sh 2>&1); grep -c '^  ok    abort: ' <<< "$o"` → `4`
(medido **0** contra o HEAD).

**Reversível por:** reverter o commit do I1 — os 4 sítios são independentes entre si.

### I2 — a família do `cd` relativo (2 itens)

**O quê:** `cd` com operando que não começa por `/`, `.` ou `..` é procurado no `$CDPATH`; quando
acha por lá, o bash **imprime o diretório resolvido na stdout**, direto para dentro da substituição
de comando.

**Onde:**
- **`tests/`, 14 arquivos** — `ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"`, operando
  relativo. Confirmado hoje: **14 ocorrências**, uma por arquivo, incluindo
  `tests/check-health.sh:61`. Com `CDPATH` setado, `ROOT` vira o diretório errado **duplicado em
  duas linhas**. Exposto na invocação manual; via `run-all.sh` o caminho é absoluto.
- **`bin/sdd:894` (`ledger_repo_root`)** — âncora ✅ correta. Aqui o conserto **remove código**:
  `git rev-parse --path-format=absolute --git-common-dir` (2.31+, aqui 2.43) dispensa os dois `cd`,
  o `pwd -P` e a guarda de `CDPATH`. Não é conserto de bug — o código de hoje está correto e medido;
  é remover a classe inteira.

**Como (TDD):** probe no `tests/check-pipefail.sh` (que já varre essa superfície) exigindo
`CDPATH=''` nos 14. ⚠️ **O par diferencial carrega piso provando que o veneno está ARMADO** no
shell antes de concluir qualquer coisa — regra de ambiente sem veneno armado é decoração, e essa
regra já custou uma CRITICAL neste repo.

⚠️ **Os 2 `cdpath:` que já existem em `tests/check-autonomy.sh` têm de continuar verdes** depois da
troca do `ledger_repo_root`. São eles que provam que dois repos continuam dois e que `CDPATH=.` não
mete um `\n` no campo `repo`. Reancorar os **dois mutantes existentes** (`LEDGER_repo_root_cdpath_leak`
e o irmão) para o código novo — mutante apontando para código que sumiu passa a não medir nada.

**Sensor durável:** 1 probe novo em `tests/check-pipefail.sh` (prefixo `cdpath:`) + os 2 existentes
preservados + mutantes reancorados.

**Check:** `o=$(bash tests/run-all.sh 2>&1); grep -c '^  ok    cdpath: ' <<< "$o"` → `3`
(medido **2** contra o HEAD).

**Reversível por:** o `sed` dos 14 é mecânico; a troca do `ledger_repo_root` é um commit próprio.

### I3 — saída humana do runner (3 itens)

**O quê:** três números/frases impressos ao humano que descrevem a grandeza errada.

| item | linha (re-derivada) | âncora do `TODO.md` | defeito |
|---|---|---|---|
| `BLOCKED in <FASE> — N sessions` | `bin/sdd:2205` | dizia `:1626` ⚠️ **podre, ~579 linhas** | conta **voltas do laço** (`attempts[$phase]`), não sessões; medido, imprime `3 sessions` com 1 sessão no ledger — e é a última linha que o humano lê |
| exclusões do `sdd autonomy` | `bin/sdd:2580-2583` | dizia `:2557-2560` ⚠️ podre, ~23 | as 4 strings abrem com `\n` cada uma, então 3 exclusões saem com linha em branco entre cada duas. O PR #7 tirou a **dupla**; esta é a que sobrou |
| `kaizen_axis_note` | `bin/sdd:3004` (fn) / `:3018` (a frase) | dizia `:2924` vs `:2928` ⚠️ podre, ~80 | o comentário jura não repetir o piso e o `dim` imprime "The floor of 3 missions" duas linhas abaixo; o dono do número é o `guard_floor` do `jq` |

**Como (TDD):** asserções prefixadas `output:` em `tests/check-autonomy.sh` — o padrão e a contagem
foram criados no PR #7 e há **6** delas hoje para copiar a forma. A de exclusões é a mais fácil de
escrever mal: exija **o parágrafo único**, contando linhas em branco, não só a presença do texto.

**Sensor durável:** 3 asserções `output:` + mutação para cada.

**Check:** `o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    output: ' <<< "$o"` → `9`
(medido **6** contra o HEAD).

### I4 — asserções e fixtures com receita já nomeada (5 itens)

Cinco caminhos que hoje **não têm asserção nenhuma** — e por isso não podem ter mutação. A receita
de cada um veio do corpo do próprio achado; nenhuma precisa ser inventada.

| item | linha (re-derivada) | âncora do `TODO.md` | receita literal |
|---|---|---|---|
| `die` de artefato faltando do `sdd approve` | `bin/sdd:1987` (dentro de `cmd_approve`, que abre em `:1979`) | dizia `:1842` ⚠️ **podre, ~145** | um **sexto** fixture só com `00-missao.md`, nomeado **fora dos prefixos contados**. Hoje os 5 fixtures carregam sempre os 3 artefatos, então trocar o `die` por `return 0` deixa a suíte verde e o comando passa a aprovar missão sem plano |
| fallback `"?"` de `cost_usd` | `bin/sdd:1294` | dizia `:852` ⚠️ **podre, ~442** | stub que emita `{"other_field": 1}`, afirmando `cost_usd == null` no ledger. Todo stub de hoje escreve log **vazio**, então o campo chega `""` e nunca exercita o `"?"` |
| `--max-phases` nunca exercitado | `bin/sdd:2104` (parse) e `:2281` (a mensagem "reached") | dizia `:1489-1498` ⚠️ **podre, ~615** | caso com `--max-phases 1` afirmando **uma** linha de ledger **e** a mensagem "reached". O gate roda e escreve a linha ANTES de checar o limite, de propósito |
| `moved` do `cmd_kaizen` | `bin/sdd:3120` | dizia `:3103` ⚠️ podre, ~17 | a asserção primeiro, a entrada do catálogo depois. As duas cópias irmãs (`cmd_run` em `:2275`, `cmd_retry` em `:2360`) **já têm** mutação — copiar a forma delas |
| 2 de 3 comparações de `health_provenance` | `bin/sdd:1829` (qa-execution) e `:1854` (codereview — `:1850` é o comentário que o encabeça) | `:1829` ✅, `:1850` ✅ (aponta o bloco certo) | par **match/divergência** para cada, como a asserção 4 do `check-health.sh` já faz |

⚠️ **O último é o mais pesado e o mais exposto.** As duas ficam permanentemente no ramo "skipped"
porque o fixture só instala o template de `qa-report` — nada mede se ainda discriminam. A do
codereview é a mais arriscada: é um laço `awk` de forma diferente das outras duas, e **nenhuma
`mut_HEALTH_*` a alcança** hoje.

⚠️ **Fixture que imita saída de skill de terceiro é COPIADO da fonte**, com o caminho no comentário
de proveniência — nunca escrito de memória. Três bugs de gate nasceram de fixture imaginado: gate e
fixture com o mesmo autor e a mesma suposição fazem a suíte verde *confirmar* a suposição em vez de
medi-la. `sdd health` confere a proveniência contra as skills instaladas.

**Sensor durável:** 5 asserções prefixadas `covered:` + 5 mutações.

**Check:** `o=$(bash tests/run-all.sh 2>&1); grep -c '^  ok    covered: ' <<< "$o"` → `5`
(medido **0** contra o HEAD).

### I5 — regras de sensor e o template que falta (5 itens)

| item | onde (re-derivado) | o quê |
|---|---|---|
| `grep -m<N>` sem flag quiet | `tests/check-pipefail.sh`, limites declarados em `:36-48` | estender a regex ao par `-m`/`--max-count` **e converter as ocorrências no mesmo commit** — sensor que chega com violação não convertida chega vermelho. O próprio cabeçalho declara a lacuna e diz que ela está no `TODO.md`; a fronteira é de uma tecla: `grep -m 1 -q x` JÁ é medido, `grep -m 1 x` não |
| `pipe_rule()` faltando | `tests/check-checkpoint.sh:239` e `:241` (as 2 chamadas de `doc_rule`, que abre em `:192`) | gêmeo do `doc_rule` existente, com probe: hoje apagar o banner do `\|` de `templates/checkpoint.md` **e** do `sdd-planner` deixa o sensor **verde** |
| `last_sep` não conhece code span | `tests/check-todo.sh:138` (com `head_of` em `:147`, `tail_of` em `:148`) | mascarar code spans antes de cortar no último ` — `, senão item bem formado com travessão dentro de crases é reportado como malformado. ⚠️ Aqui mora a armadilha do `mawk`: classe negada com multibyte não funciona |
| `templates/review.md` não existe | `templates/` tem 5 arquivos: `checkpoint` `handoff` `missao` `plano` `pr-body` | o `40-review-r<N>.md` é o **único** artefato com gate e sem template, e o `gate_REVIEW` o lê por regex literal `^###[[:space:]]+Overall Grade` (`bin/sdd:409`). Duas rodadas independentes já escreveram `##` e levaram `NO-TABLE`. Criar o template **e** a linha em `tests/check-templates.sh` |
| caixa marcada na linha SEGUINTE | `tests/check-todo.sh`, regra 2 | ⚠️ **o patch e os repros já existem** em `docs/handoffs/20260816-todo-enxuto/r12-caixa-partida.md`. **Conferir que ainda aplicam antes de usar** — o sensor mudou desde então |

**Sensor durável:** 5 asserções prefixadas `rule:` + mutações onde o catálogo alcança.

⚠️ **`check-pipefail.sh`, `check-todo.sh` e `check-checkpoint.sh` carregam `selftest()` próprio**
porque o catálogo de mutação não os alcança (medem markdown/`tests/`, não o `bin/sdd`). Regra nova
neles entra **com probe no selftest**, e o selftest tem de exercitar o **caminho** (parser →
contabilidade da falha → composição), não só a função.

⚠️ **Passada de sabotagem adversarial antes de considerar pronto:** degrade cada regra nova para
uma versão mais frouxa e exija o selftest **vermelho** em cada uma. O que passar é regra sem probe.
No `check-todo.sh` isso achou 17 defeitos depois de a auto-revisão ter dado Grade A, dois deles
**falhando abertos**.

**Check:** `o=$(bash tests/run-all.sh 2>&1); grep -c '^  ok    rule: ' <<< "$o"` → `5`
(medido **0** contra o HEAD).

## Riscos e não-feitos

| Risco | Probabilidade | Mitigação |
|---|---|---|
| A re-derivação achar mais trabalho do que os 18 itens preveem | **alta** — no PR #7 os dois pontos marcados como "talvez já coberto" estavam ambos descobertos | Achado novo vai para o `TODO.md` com a baseline movida no mesmo commit; **não** desviar o escopo do incremento |
| Asserção nova nascer verde (não medir nada) | alta, é a falha assinatura desta casa | Os 5 Checks já foram medidos vermelhos contra o HEAD (Notas do `checkpoint.md`). Cada asserção nova exige o par diferencial, e o I1 exige texto **e** continuação |
| `check-autonomy.sh` vermelho intermitente | baixa — não reproduziu em 152 runs | Ruído conhecido: registrar nas Notas e seguir. **Não** investigar (decisão 6 do `00-missao.md`) |
| Mutante reancorado no I2 parar de medir | média | O par diferencial dos 2 `cdpath:` existentes tem de continuar verde, e o catálogo tem de continuar em `0 known gap(s)` |
| A suíte passar do teto de tempo | alta (já ~7× o alvo da D7) | É consequência aceita e declarada; a decisão de régua é do humano e está no `TODO.md`. Registrar o número no `KAIZEN_LOG` |
| REVIEW estourar o teto de US$ 40 | média — já chegou a 23,13 numa rodada | `REVIEW_MAX_ITER=3`; se estourar, o runner escala e o humano decide |

## Verificação end-to-end

Com os 5 incrementos `done`:

1. `o=$(bash tests/check-health.sh 2>&1); grep -c '^  ok    abort: ' <<< "$o"` → `4`
2. `o=$(bash tests/run-all.sh 2>&1); grep -c '^  ok    cdpath: ' <<< "$o"` → `3`
3. `o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    output: ' <<< "$o"` → `9`
4. `o=$(bash tests/run-all.sh 2>&1); grep -c '^  ok    covered: ' <<< "$o"` → `5`
5. `o=$(bash tests/run-all.sh 2>&1); grep -c '^  ok    rule: ' <<< "$o"` → `5`
6. `bash tests/check-todo.sh` → `38 finding(s)` e `grep '^todo-findings' tests/health-baseline.txt`
   → `todo-findings 38`
7. `bash tests/run-all.sh` → `suite green`, com `score:` **acima de 81** e `0 known gap(s)`
8. `./bin/sdd health` → `kit healthy`
9. **A prova da família I1** — a que mais importa: com a suíte propositalmente vermelha,
   `./bin/sdd health` **imprime `suite red` e segue** para os checks restantes. Hoje morre na
   atribuição: uma linha de saída, rc 1, e os quatro checks seguintes nunca rodam.
10. `git status --porcelain` vazio.
