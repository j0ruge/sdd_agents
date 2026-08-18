# Handoff — os itens baratos do `TODO.md` (2026-08-17)

> **Não é uma missão.** É o material para planejar uma, e o Lote 0 para fazer à mão antes dela.
> Arquivo solto de propósito: missão é diretório em `docs/handoffs/<slug>/`, e este não deve ser
> confundido com uma. Escrito para uma sessão que **não tem nenhum contexto** desta conversa.

## Estado medido

`main` em `e676dbe` (2026-08-17, depois dos PRs #7, #8 e #9):

```
tests/check-todo.sh   →  ok  66 finding(s)
health-baseline.txt   →  todo-findings 66
tests/check-mutation  →  score: 81 caught, 0 known gap(s), of 81
./bin/sdd health      →  kit healthy · ratchet: 7 known debt(s), none new
tests/run-all.sh      →  suite green, ~3m30s
```

⚠️ **Nunca conte itens com `grep -c '^- \[ \]' TODO.md`** — responde **67**, porque engole a linha
de exemplo do bloco cercado no cabeçalho. A contagem sai do `tests/check-todo.sh`, e é dela que a
catraca do `sdd health` se alimenta.

Meta deste trabalho: **66 → 38**.

## O critério de "fácil", e por que ele precisa estar escrito

O handoff da triagem anterior (`docs/handoffs/triagem-todo-20260817.md`) chamou cinco itens de
"mesma forma: acrescentar entrada no catálogo". Um deles (`cmd_health` sem sensor) exigiu um sensor
inteiro antes — ~40% da missão. Outro previa "um item = uma mutação", e a re-derivação produziu
**oito** mutações para quatro itens. Estimativa de custo feita por leitura do título erra.

Um item só entra nos lotes abaixo se satisfaz os quatro:

- **(a)** o corpo já traz o defeito **localizado e reproduzido** ("medido", "reproduzido", "provado
  por probe") — não uma suspeita;
- **(b)** a direção nomeada é one-liner ou adição mecânica;
- **(c)** já existe sensor onde a asserção vai morar — não precisa criar instrumento novo;
- **(d)** não pede decisão humana.

**A alavanca de custo é agrupar por mecanismo.** Fechar três itens da mesma família custa quase o
mesmo que fechar um; fechar três itens de famílias diferentes custa três vezes.

## Decisões já tomadas (não re-litigar)

1. **O trabalho é dividido em dois lotes.** Documento/comentário vai à mão em sessão com humano; o
   código vai pela missão. Motivo: um dos itens de documento é **insatisfazível** em sessão
   headless — o harness barra `.claude/` como caminho sensível, e duas fases DOCS já falharam nele.
2. **Três itens fecham por decisão registrada, sem código** (ver Lote 0). O motivo de cada um vai
   para o `KAIZEN_LOG.md` **antes** de o item sair do `TODO.md`: item aberto não tem memória
   durável em nenhum outro lugar, e foi esse o argumento que recusou a política de expiração.

## Lote 0 — à mão, com humano presente (10 itens, 66 → 56)

Nenhum toca lógica.

| item | arquivo | conserto |
|---|---|---|
| rubrica do auto-teste conta cinco, `grep` devolve seis | `CLAUDE.md:163` | contar a propriedade (`grep -l '^selftest()'`) ou citar os nomes |
| regra manda sincronizar `.claude/agents/` e não diz como | `CLAUDE.md` §"Ao mexer nos agentes" | dizer que quem resolve é `sdd install --force` |
| `KAIZEN_LOG` não fixa o instrumento das próprias linhas | `KAIZEN_LOG.md:261` | nomear o comando ao lado do número, como a linha `score:` já faz |
| comentário do Jidoka descreve a grandeza errada | `tests/check-gates.sh:229-232` | dizer "linhas **depois** da `blocked`", não tamanho do checkpoint |
| `after2` mudou de posição sem registro da decisão | `bin/sdd:1533-1537` | comentário registrando a decisão — só comentário |
| "contexto não é gargalo" nunca foi escrito | `docs/pipeline.md`, `config/schema.md` | registrar 184k–289k tokens de pico, zero compactações, e que `--autocompact` é alavanca disponível e não usada |
| `.claude/napkin.md` afirma catraca vencida | `.claude/napkin.md:18` | ⚠️ **decisão antes**: o napkin entra na superfície que o DOCS mantém, ou sai do versionamento? Só depois corrigir "~33s / mutação 30/30" para ~3m30s / 81 |

**Mais os três que fecham por decisão:**

- **regra da âncora do `check-todo.sh` satisfeita por código inline** — apertar exige forma que os
  dados reais não sustentam (`git worktree` e `KAIZEN_LOG` são âncoras legítimas);
- **corte UTF-8 de `${var:0:200}` sem asserção** — o próprio item diz que pode não valer o fixture,
  e o risco degrada (U+FFFD) em vez de quebrar alto;
- **`def usd` com entrada negativa** (`bin/sdd:2516`) — inalcançável: nenhum escritor do ledger
  produz `cost_usd` negativo.

⚠️ **A catraca cobra este lote.** Ao passar de 66 para 56, o `sdd health` reprova nos **dois**
sentidos (`finding outside the baseline` **e** `stale baseline`) até `todo-findings` descer para 56
no **mesmo commit**. Isso é o desenho, não um defeito.

Forma: branch + PR, como as varreduras anteriores (`e0230fa` + `bb81349`).

## A missão — 18 itens em 5 incrementos (56 → 38)

Slug sugerido: `<YYYYMMDD>-lote-facil`, com a data do dia em que a missão for planejada.

### I1 — a família do aborto calado (3 itens)

`out="$(cmd)"` sob `set -e` mata o script **na atribuição** quando `cmd` devolve não-zero, e o
`health_bad` da linha seguinte vira código morto. Três ocorrências, todas no `cmd_health`:

- `bin/sdd:1588` — suíte vermelha: exatamente o caso que o comando existe para relatar;
- `bin/sdd:1721` — a checagem do `score:`, escrita para impedir cegueira, e cega;
- `bin/sdd:1854` e `:1882` — `find` em `~/.claude/plugins/cache` ausente, e baseline sem linha viva.

Conserto: `|| true` / `|| rc=$?`, como o check da contagem (check 3) já faz. **A asserção tem
casa**: `tests/check-health.sh` nasceu no PR #7 com fixture hermético e é o primeiro sensor que
executa `cmd_health`. Cada conserto entra com asserção diferencial e entrada `mut_HEALTH_*`.

É o incremento de maior valor do lote: é esta família que faz o `sdd health` mentir.

### I2 — a família do `cd` relativo (2 itens)

- **`tests/check-health.sh:61` e os 13 irmãos** — `ROOT="$(cd … )"` com operando relativo sem
  `CDPATH=''`. Com `CDPATH` setado o `cd` resolve pelo path de busca e **imprime o destino na
  stdout**, então `ROOT` vira o diretório errado, duplicado em duas linhas. Reproduzido. Probe no
  `tests/check-pipefail.sh`, que já varre essa superfície.
- **`bin/sdd:894` (`ledger_repo_root`)** — `git rev-parse --path-format=absolute --git-common-dir`
  (2.31+, aqui 2.43) dispensa os dois `cd`, o `pwd -P` e a guarda de `CDPATH`. **Remove código.**
  Reancorar os dois mutantes existentes.

⚠️ Regra da casa: o probe de sabotagem prova **primeiro** que sabotou o que dizia sabotar, e o par
diferencial carrega piso provando que o veneno (`CDPATH`) está **armado** no shell — regra de
ambiente sem veneno armado é decoração.

### I3 — saída humana do runner (3 itens)

- `bin/sdd:1626` — `BLOCKED in <FASE> — N sessions` conta **voltas do laço**, não sessões; medido,
  imprime `3 sessions` com 1 sessão no ledger, e é a última linha que o humano lê;
- `bin/sdd:2557-2560` — as quatro strings de exclusão abrem com `\n` cada uma, então três exclusões
  saem com linha em branco entre cada duas (o PR #7 tirou a **dupla**; esta é a que sobrou);
- `bin/sdd:2924` vs `:2928` — `kaizen_axis_note` diz no comentário que não repete o piso e imprime
  "The floor of 3 missions" duas linhas abaixo; o dono do número é `guard_floor` do `jq`.

Asserções prefixadas `output:` em `tests/check-autonomy.sh` — o padrão e a contagem foram criados
no PR #7, e o Check do incremento é `grep -c '^  ok    output:'` sobre a saída do sensor.

### I4 — asserções e fixtures com receita já nomeada (5 itens)

| item | receita literal, do corpo do próprio item |
|---|---|
| `die` de artefato faltando do `sdd approve` (`bin/sdd:1842`) | um sexto fixture só com `00-missao.md`, nomeado fora dos prefixos contados |
| fallback `"?"` de `cost_usd` (`bin/sdd:852`) | stub que emita `{"other_field": 1}`, afirmando `cost_usd == null` no ledger |
| `--max-phases` nunca exercitado (`bin/sdd:1489-1498`) | caso com `--max-phases 1` afirmando uma linha de ledger e a mensagem "reached" |
| `moved` do `cmd_kaizen` sem asserção (`bin/sdd:3103`) | a asserção primeiro, a entrada do catálogo depois — as duas cópias irmãs já têm mutação |
| duas de três comparações de `health_provenance` (`bin/sdd:1829`, `:1850`) | par match/divergência para cada, como a asserção 4 do `check-health.sh` já faz |

O último é o mais pesado: as duas ficam permanentemente no ramo "skipped" porque o fixture só
instala o template de `qa-report`. A do codereview é a mais exposta — é um laço `awk` de forma
diferente das outras duas.

### I5 — regras de sensor e o template que falta (5 itens)

- `tests/check-pipefail.sh` — estender a regex ao par `-m`/`--max-count` (`grep -m1` é a mesma
  corrida de SIGPIPE do `grep -q`, devolve 141) **e converter as ocorrências no mesmo commit**;
- `tests/check-checkpoint.sh:239-241` — `pipe_rule()` gêmeo do `doc_rule` existente, com probe:
  hoje apagar o banner do `|` de `templates/checkpoint.md` e do `sdd-planner` deixa o sensor verde;
- `tests/check-todo.sh` (`last_sep`) — mascarar code spans antes de cortar no último ` — `, senão
  um item bem formado com travessão dentro de crases é reportado como malformado;
- `templates/review.md` — o `40-review-r<N>.md` é o único artefato **com gate e sem template**, e o
  `gate_REVIEW` lê `^###[[:space:]]+Overall Grade` por regex literal (`bin/sdd:409`); duas rodadas
  independentes já escreveram `##` e levaram `NO-TABLE`. Mais a linha em `tests/check-templates.sh`;
- caixa marcada na linha **seguinte** ao marcador (`tests/check-todo.sh`, regra 2) — ⚠️ **o patch e
  os repros já existem** em `docs/handoffs/20260816-todo-enxuto/r12-caixa-partida.md`. Conferir que
  ainda aplicam antes de usar.

## O que NÃO entra, e por quê

Para ninguém gastar sessão reavaliando:

- **Investigação de verdade** — `gate_EXEC` rederivando por árvore suja (redesenho de gate);
  `check-autonomy.sh` vermelho intermitente (não reproduziu em 152 runs; o corpo manda "medir de
  novo antes de consertar"); preflight que prove execução de `TEST_CMD` (probe headless real, custa
  dinheiro); `check-todo.sh` re-derivar âncoras semanticamente.
- **Decisão humana antes de qualquer código** — as 5 chaves fantasma do `config/schema.md`;
  `E2E_DIR`; TICKET recebendo agente **e** slash; `CHANGELOG.md`; o lembrete pós-pipeline (pede
  ADR 0004); o alvo da D7; o multiplicador do harness de mutação; teto por fase granular.
- **Refator grande** — split do `docs/pipeline.md` (o corpo diz explicitamente "merece a sua
  missão"); contrato PT-BR em 5 pontos; `templates/` multi-idioma.
- **Adiados por YAGNI (3)** — são decisões de não-fazer, não dívida. Ficam onde estão.

## Contexto operacional (não re-descobrir)

- **Custo esperado da missão: ~US$ 70–90.** O PR #7 fez 5 incrementos por **US$ 80,04** em 11
  sessões / ~4h35. Perfil por fase: EXEC 40,32 · QA 7,48 · **REVIEW 23,13** · DOCS 7,10 · PR 2,01.
- **`BUDGET_PER_PHASE_USD` deste repo é 40** desde 2026-08-17 (era 25; a REVIEW chegou a 23,13 e
  uma r2 teria morrido por dinheiro). O default do kit segue **15** e governa repos-alvo.
- **A suíte leva ~3m30s** e todo gate a roda; `sdd phase` e `sdd why` bloqueiam por esse tempo.
- **Âncoras apodrecem.** No PR #7 as do cluster cosmético estavam ~870 linhas defasadas.
  **Re-derivar antes de implementar, sempre.**
- **Re-derivação costuma achar MAIS trabalho, não menos.** No PR #7 os dois pontos marcados como
  "talvez já esteja coberto" estavam ambos descobertos, provados por probe.
- **Toda fase que mexe no `TODO.md` move `todo-findings` no mesmo commit.** A regra está no
  `CLAUDE.md` e no cabeçalho do `TODO.md`; os agentes a encontram sozinhos.
- **`JIRA_ENABLED=false`** — a fase TICKET é pulada.
- **`sdd approve <missão>` existe** e é o único caminho que grava `aprovacao: humano-<data>`.
  Nunca preencher o campo à mão.
- **Rodar os Checks contra o HEAD e registrar o vermelho nas Notas** antes de aprovar: o `TODO.md`
  traz um achado aberto sobre o gate PLAN-AUTO aceitar Check que já nasce verde.

## Sequência

1. Lote 0 à mão (branch + PR), com a decisão do napkin resolvida no caminho. Baseline para 56.
2. Escrever `docs/handoffs/<YYYYMMDD>-lote-facil/` — `00-missao.md`, `01-plano.md`, `checkpoint.md`.
3. `./bin/sdd approve <YYYYMMDD>-lote-facil`
4. `./bin/sdd run <YYYYMMDD>-lote-facil`
5. Varredura pós-merge: apagar os itens com `RESOLVIDO por`, cada um provado por
   `git merge-base --is-ancestor <hash> main`, e baixar a baseline no mesmo commit.

## Verificação final

1. `bash tests/check-todo.sh` → `ok    38 finding(s), all within 8 lines and carrying anchor + date`
2. `grep '^todo-findings' tests/health-baseline.txt` → `todo-findings 38`
3. `./bin/sdd health` → `kit healthy`, `score: <N> caught, 0 known gap(s), of <N>` com `N > 81`
4. `tests/run-all.sh` → `suite green`
5. **A prova da família I1**, a que mais importa: com a suíte propositalmente vermelha,
   `./bin/sdd health` tem de **imprimir `suite red` e seguir** para os checks restantes. Hoje ele
   morre na atribuição — uma linha de saída, rc 1, e os quatro checks seguintes nunca rodam.
6. `git status --porcelain` vazio.
