---
missao: 20260817-catraca-do-backlog
fase: DOCS
status: done
data: 2026-08-17
---

# Documentação — 20260817-catraca-do-backlog

> Uma linha por área que o diff tocou. `✅` carrega o hash do commit que atualizou o doc; `n/a`
> carrega justificativa concreta. Nenhum `✗` fica pendente.

## TL;DR

O diff fora de `docs/handoffs/` são **11 arquivos** (`6d68dfc..425985c`), e as fases anteriores já
tinham fechado quatro drifts de documento — a r1 da REVIEW achou o inventário de sensores do
`CLAUDE.md` parado em "os doze" (R3), o `README.md` afirmando da posse da baseline exatamente o que
o I5 tinha reescrito (R4), duas âncoras do `TODO.md` deslocadas pelo próprio diff (R5) e um número
de check errado num comentário (R6).

O que **sobrou para esta fase** foram quatro coisas que ninguém tinha olhado:

1. **`docs/failure-modes.md` não conhecia a única forma NOVA de o `sdd health` reprovar.** Ela vai
   disparar em toda missão que registrar um achado, com **duas** mensagens sobre o mesmo número, e
   o remédio (baseline no mesmo commit) não estava escrito em nenhum documento que o humano abra
   quando o comando reprova. Era o buraco mais caro: o catálogo de modos de falha existe para
   evitar exatamente o "o comando reprovou e eu não sei se quebrei alguma coisa".
2. **`CONTEXT.md` usava "catraca" em três documentos sem a definir**, e esta missão é *nomeada* pelo
   termo. O verbete nomeia as duas de hoje, separa catraca de **piso** e registra a classe nova de
   linha da baseline (a que congela propriedade do arquivo inteiro e nunca é paga).
3. **`CLAUDE.md` dizia "sensor novo entra lá" apontando para um lugar; são quatro** — e o quarto
   arrasta o fixture do selftest do `check-pipefail.sh`. É a mecânica que fez três probes desta
   própria missão falharem com `surface shrank` em vez de medir o que nomeiam.
4. **O invariante que o R1 consertou vivia só num comentário — e o comentário mentia.** A paridade
   entre `sdd autonomy` e `sdd kaizen --series` sobre "qual é a versão mais recente" foi escrita
   onde o contrato do ledger mora (`docs/pipeline.md`), mais o ⚠️ no parágrafo do `CLAUDE.md` que já
   cataloga a classe.

E **dois números medidos no instrumento errado**, os dois nascidos dentro desta missão: a r1
comparou 589 (`grep -c '^  ok'`) com 533 (âncora de quatro espaços) como se fossem a mesma régua, e
o item do multiplicador de suíte citava +281 s, que não reproduz em máquina quieta (+55 s). Os dois
lados do `KAIZEN_LOG.md` foram remedidos nesta fase, sequencialmente, `main` num worktree
descartável: **509 → 534**.

## Drift checklist

| Área tocada pelo diff | Documento correspondente | Status | Evidência |
|---|---|---|---|
| `bin/sdd` — check 3 novo do `cmd_health`: `todo-findings <N>` via `health_finding` | `CLAUDE.md` § princípio 5, `TODO.md` (cabeçalho) | ✅ | `ca017f9` — a política escrita nos dois documentos, e não é prosa solta: a asserção 8 do `tests/check-health.sh` é um `doc_rule` que reprova o dia em que ela sair de qualquer um dos dois. Reverificado nesta fase (`ok    the ratchet policy is written where the next mission meets it`) |
| `bin/sdd` — a mesma catraca, do lado de quem lê a saída do comando | `README.md` | ✅ | `cbe4159` (R4) — o parágrafo do `sdd health` repetia a redação **antiga** do cabeçalho da baseline ("each line owned by a `TODO.md` entry"), que o I5 tinha reescrito de propósito, e não mencionava a catraca que dá nome à missão |
| `bin/sdd` — a catraca como **conceito**, e a classe de linha cujo dono é o arquivo | `CONTEXT.md` § glossário | ✅ | `8535a3a` — verbete **Catraca**: as duas de hoje (`lang-allowlist.txt` e `health-baseline.txt`), a distinção catraca × piso (piso morde num sentido só, contra vacuidade) e a classe nova. O termo era usado em `CLAUDE.md`, `TODO.md` e nos sensores sem definição em lugar nenhum |
| `bin/sdd` — a única forma **nova** de o `sdd health` reprovar (duas mensagens, um edit) | `docs/failure-modes.md` | ✅ | `8535a3a` — seção nova com sintoma, causa, por que a catraca mora fora do `TEST_CMD` e o remédio; as mensagens transcritas do runner real, e o ⚠️ de que a contagem sai do `check-todo.sh` e nunca de um `grep -c` próprio |
| `bin/sdd` — renumeração dos checks do `cmd_health` (3→4 … 7→8) | comentário de `tests/check-autonomy.sh:1598` | ✅ | `cbe4159` (R6) — o comentário dizia `check 5` para o que virou `6`, e é a única coisa que liga a asserção ao ponto do runner que ela espelha. Fora do sensor **nenhum** documento numera os checks: `README.md` e `docs/pipeline.md` descrevem o que o comando responde, deliberadamente sem a numeração interna, que é o que impede esta deriva de ter seis cópias |
| `bin/sdd` — `cmd_autonomy`: a ordem das versões passa a ler a população do juiz (`on_axis`) | `docs/pipeline.md` § "The autonomy ledger", `CLAUDE.md` § runner, `CONTEXT.md` D4 | ✅ | `f69d28d` — o invariante escrito onde o contrato do ledger mora, mais o ⚠️ no parágrafo que já cataloga a classe (`is_escalation` escrito à mão em três lugares). ⚠️ O **D4 do `CONTEXT.md` já dizia** "agrupa por `kit_sha` na ordem do arquivo (como `cmd_autonomy` já faz)": a prosa estava certa e era o **código** que tinha driftado dela — conferido contra o `bin/sdd` do HEAD, nenhuma edição devida ali |
| `bin/sdd` — `cmd_autonomy`: dinheiro com duas casas, dois `die` distintos, `autonomy_no_data`, linha em branco dupla | — | n/a | são cinco defeitos da **saída humana**, não do contrato. Campo, shape, janela e os cinco baldes de `excluded` estão intocados, e é isso que `docs/pipeline.md` § "Field reference" e o verbete "Série" do `CONTEXT.md` descrevem — o que o ledger **grava**, nunca como a tabela é formatada. Nenhum documento transcreve a saída do comando, por decisão: seria uma cópia a driftar a cada ajuste cosmético |
| `tests/check-health.sh` (arquivo novo, 491 linhas) | `CLAUDE.md` § TDD (inventário de sensores) | ✅ | `cbe4159` (R3) — "Os doze de hoje" com treze na suíte, no mesmo commit em que a missão editou o `CLAUDE.md` sem tocar na lista. Medido: `ls tests/check-*.sh` → 13, sensores invocados pelo `run-all.sh` → 13 |
| `tests/run-all.sh` (`LINT_FLOOR` 14→15 e a linha `run`), `tests/check-lang.sh` (36→37), `tests/check-pipefail.sh` (13→14 e o fixture do selftest) | `CLAUDE.md` § TDD | ✅ | `8535a3a` — a regra "sensor novo entra na suíte" **não** mudou; o que faltava era a mecânica medida: são quatro lugares e o quarto arrasta um quinto. Os três pisos existem contra vacuidade, então piso atrasado continua **passando** enquanto descreve superfície menor do que a que lê — e o fixture do `check-pipefail.sh` é construído exatamente no piso, o que fez três probes falharem com `surface shrank` |
| `tests/check-mutation.sh` — catálogo 70 → 81 | `CLAUDE.md` § TDD | n/a | a regra "gate novo entra com mutação" não mudou, e o `CLAUDE.md` **deliberadamente** não fixa o número: "o número de hoje sai da linha `score:` do `run-all.sh`, e fixá-lo aqui era uma data de validade escrita à mão". O `KAIZEN_LOG.md` registra o degrau (`a31202d`), que é onde número medido mora |
| `tests/check-mutation.sh` — `sandbox()` passa a copiar `CLAUDE.md` e `TODO.md` | — | n/a | mecânica interna do harness, documentada no cabeçalho da própria entrada que a exigiu (`:1105`). Nenhum documento externo descreve o conteúdo do sandbox, e o controle do harness já grita `HARNESS-BROKEN` quando a cópia não fecha — foi ele que apontou a falta |
| `tests/health-baseline.txt` — cabeçalho admitindo a classe + `todo-findings 76` | `README.md`, `CONTEXT.md`, `docs/failure-modes.md` | ✅ | `cbe4159` (R4), `8535a3a` (verbete + modo de falha). O cabeçalho do arquivo é a fonte, e os três documentos que o parafraseavam foram reconferidos **contra ele**, não contra o que as fases anteriores afirmaram |
| `tests/check-autonomy.sh` — 6 asserções `output:` e a diferencial do R1 | — | n/a | nenhum documento descreve asserção individual, por decisão: o contrato dos **prefixos** vive no Check do `checkpoint.md` (que os conta com `grep -c`) e cada sensor documenta as próprias regras no cabeçalho. Doc externa aqui seria a sétima cópia a driftar |
| `TODO.md` — 10 itens fechados com hash, 8 nascidos na missão, 4 âncoras reancoradas | ele mesmo, e a triagem do `sdd kaizen` que o lê | ✅ | `ca017f9` (os 10 `RESOLVIDO por`), `cbe4159` (T1–T3 + baseline em 76), `a31202d` (dois itens com número vencido), `2d0280e` (as quatro âncoras) — detalhe na seção "Achados" abaixo |
| `KAIZEN_LOG.md` — a missão mede antes/depois (K8 do checklist kaizen) | ele mesmo | ✅ | `a31202d` — 13 linhas de antes/depois, **os dois lados medidos nesta fase** em passadas sequenciais (`main` num worktree descartável), nunca copiados de leitura anterior |
| `.claude/napkin.md` — runbook rastreado que afirma "~33s no default, mutação 30/30" | ele mesmo | n/a | **tentado nesta fase e barrado**: o harness recusa `.claude/` como caminho sensível, pela segunda fase DOCS seguida. Já é item aberto com a decisão humana nomeada (o napkin entra na superfície que o DOCS mantém, ou sai do versionamento); os números do **item** foram reancorados em `a31202d` para ~3m30s e 81/81 |
| `docs/handoffs/20260817-catraca-do-backlog/*` | — | n/a | artefatos da missão, não documentação viva: descrevem o que aconteceu numa data e não são lidos como instrução pela próxima sessão. ⚠️ **Uma exceção anotada, não reescrita:** o `40-review-r1.md` compara 589 com 533 como se fossem a mesma régua, e a fase PR copiaria isso para o corpo do PR — a anotação de instrumento entrou em `a31202d` |

## Achados do `TODO.md` desta missão

**A aritmética fecha, e é ela o resultado da missão:** 68 → **76**. Cinco achados nasceram no EXEC
(dois abortos calados do `sdd health` achados pelo fixture hermético, o terceiro na checagem do
`score:`, o `moved` do `cmd_kaizen` sem asserção, e a linha em branco entre exclusões), três na
REVIEW r1 (T1, T2, T3) e **zero** nesta fase. Cada um moveu a baseline **no mesmo commit** — a
catraca cobrando a própria missão que a instalou, sem exceção para a sessão que a escreveu.

**Os 8 itens novos estão bem formados**, conferido por artefato e não por leitura: os oito trazem o
quê + `arquivo:linha` + por que importa + a direção + quem descobriu e quando, e
`tests/check-todo.sh` fecha em `76 finding(s), all within 8 lines and carrying anchor + date` com
os 75 probes do selftest verdes. **Nenhum precisou ser completado.**

**Os 10 fechados carregam `RESOLVIDO por <hash>` no corpo** e continuam contando — saem na varredura
pós-merge, provados por `git merge-base --is-ancestor`, e é lá que a catraca cobra a baseline de
novo. O QA verificou os 10 hashes um a um: 10 de 10 ancestrais de HEAD.

**Escrituração feita nesta fase — três correções, zero item novo:**

- **Quatro âncoras deslocadas** (`2d0280e`), mesma classe do R5 da r1 e uma delas o R5 não pegou:
  `CLAUDE.md:135` já valia **147** no fim da REVIEW, deslocada pelo próprio I5, e vale **163**
  depois desta fase. As outras três são desta fase: `KAIZEN_LOG.md:175` → `:261` (a inserção da
  entrada nova), `docs/pipeline.md:499` → `:501` e a proposta de split de `326-568` → `326-570`
  (149 + 96 = **245 de 570**). As quatro conferidas contra o **conteúdo que nomeiam**, uma a uma, e
  nunca pelo deslocamento aritmético;
- **o item do multiplicador de suíte citava +281 s** e isso não reproduz. Em máquina quieta e
  passadas sequenciais o par é **155,97 s → 210,81 s** (+55 s), já com 11 mutações a mais no mesmo
  diff. O mecanismo é real — sensor novo é multiplicador, roda uma vez por mutante —, mas o número
  que decide o alvo da D7 é este. Item corrigido, **não** duplicado: abrir "o item anterior mediu
  errado" seria a inflação que esta missão combate;
- **o item do napkin citava 44,55 s e 38/38** como "o real", números de duas missões atrás. Passou
  a ~3m30s e 81/81, e ganhou a segunda tentativa barrada como fato.

⚠️ **A armadilha de instrumento reapareceu dentro da missão que mede instrumentos**, e vale a
próxima sessão saber: o `40-review-r1.md` registrou "**589** asserções `ok` (eram 533 no fim do
EXEC)". `589` é `grep -c '^  ok'`; `533` é a âncora de **quatro** espaços. A diferença é exatamente
**55**, as linhas `  ok   ` de três espaços que o runner imprime dentro dos fixtures — o mesmo
degrau fantasma que a fase DOCS anterior catalogou no `KAIZEN_LOG.md`, e que já é item aberto. Pela
âncora certa a r1 mede **534**, que é 533 + a asserção do R1: a aritmética esperada. Não virou item
novo (a classe já tem dono); virou anotação no handoff e a régua correta no `KAIZEN_LOG.md`.

## Disclosure progressiva

Nenhum índice cresceu para carregar profundidade.

- **`CLAUDE.md`** ganhou dois parágrafos, os dois **dentro de seções que já cataloguem a classe** —
  a mecânica dos quatro lugares na § TDD, logo abaixo da frase "Sensor novo entra lá" que ela
  corrige, e o ⚠️ da paridade no parágrafo do `is_escalation`, do qual é a segunda instância.
  Nenhuma seção nova: a alternativa era um documento que ninguém leria no momento em que escreve
  um sensor.
- **`CONTEXT.md`** ganhou **um** verbete, que é o formato do arquivo. Ele **roteia** — nomeia as
  duas catracas e manda a profundidade para o cabeçalho de cada arquivo, que é onde ela já mora e
  onde é lida por quem edita.
- **`docs/failure-modes.md`** ganhou uma seção no formato das outras 20 (sintoma → causa → como o
  kit reage → o que você faz). É o índice **certo** para essa profundidade: o `README.md` diz o que
  o comando responde, e o catálogo diz o que fazer quando ele reprova.
- **`docs/pipeline.md`** ganhou **uma cláusula** dentro do parênteses que já descrevia a ordem de
  primeira aparição — 2 linhas, no lugar onde a pergunta nasce.

⚠️ **A proposta de split segue registrada e não executada**, agora com o número remedido: "The
autonomy ledger" (149 linhas) + "The kaizen loop" (96) somam **245 de 570** do `docs/pipeline.md` —
43% do índice do pipeline para um subsistema só. Está no `TODO.md` como direção (`references/` para
o ledger + juiz, índice roteando), não como conserto: refatorar a estrutura de um doc alheio no meio
desta missão é o que a regra da fase proíbe.

## Estado ao fim da fase

- **Commits desta fase:** `8535a3a` (modo de falha novo + verbete **Catraca** + os quatro lugares de
  um sensor + escrituração do napkin), `a31202d` (`KAIZEN_LOG.md` + as duas correções de
  instrumento), `f69d28d` (a paridade dos dois leitores do ledger), `2d0280e` (as quatro âncoras),
  mais o commit deste handoff.
- **Suíte:** ✅ **verde com as edições de doc dentro**, medida nesta fase — `tests/run-all.sh` em
  `8535a3a` → rc 0, `suite green`, `score: 81 caught, 0 known gap(s), of 81`, **534** asserções pela
  âncora de quatro espaços, **210,81 s**; os commits seguintes desta fase são markdown e não movem
  contagem. Na árvore final, `./bin/sdd health` → rc 0 em **212,26 s** (a suíte roda dentro dele).
  `tests/check-lang.sh` verde nos dois sentidos
  (`0 of 37 surface path(s) still in the allowlist, 0 new`): a seção nova de `docs/failure-modes.md`
  e a cláusula do `docs/pipeline.md` são **inglês** (superfície do kit), e `CLAUDE.md`, `CONTEXT.md`,
  `TODO.md` e `KAIZEN_LOG.md` são `OUTPUT_LANG=pt-BR`.
- **`sdd health`** → rc 0, `kit healthy`, `ratchet: 7 known debt(s), none new` com `todo-findings 76`
  — a contagem **não se moveu nesta fase**, então a baseline ficou onde estava, que é o resultado
  correto para uma fase que só escriturou.
- **`agents/` intocado nesta missão**, logo nada a sincronizar em `.claude/agents/`; conferido por
  `git diff main...HEAD --stat`, que não lista nenhum arquivo de `agents/`.
- **Árvore limpa. Nada empurrado, nenhum PR aberto.** A fase PR é a próxima.
