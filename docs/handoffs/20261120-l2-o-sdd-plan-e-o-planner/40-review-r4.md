---
missao: 20261120-l2-o-sdd-plan-e-o-planner
fase: REVIEW
rodada: 4
status: done
sessao: 723ca6a1-33c8-4c2b-b659-719fb963a190
data: 2026-11-21 02:53
gate: "tests/run-all.sh rc=0 (suite green, 2238 linhas ok, 0 FAIL, 926 mutantes aplicam) sobre f524f9d; scan de segredos 0 achados (regex + gitleaks, 19 arquivos, 200 linhas, errors: []); sdd review-base → full — merge 6198b68 entered after 40-review-r3.md"
reviewed_head: f524f9d6d68c17b5bd1cfd37681455b12a7dbc8c
---

# Review — rodada r4 — o pós-merge do L2 (PR #457)

## TL;DR

Rodada do worker sobre o chore pós-merge (`chore/l2-pos-merge`, PR #457), **inteira** pelo
`sdd review-base` (`full — merge 6198b68 entered after 40-review-r3.md`, rodado de novo aqui), com
`/codereview:codereview base=6198b68`. O merge-base com a `origin/main` é o próprio `6198b68`, então
a rodada leu só o diff do chore: 18 commits, 19 arquivos, +200/−169. A fase B rodou inline (dois
arquivos de código, um deles só comentário). Os 6 LOW da r4 do L1b, o "fora do diff", os 6 achados
da r3 do L2 e o terceiro sensor do `EFFORT_*` estão fechados como escritos. Reproduzi aqui a
testemunha do índice num repo de rascunho, a guarda do `HOME` e os números do `KAIZEN_LOG.md` e do
`handoff-L2.md` no ledger. Os 16 itens apagados têm hash ancestral da `origin/main` (7 hashes, rc 0),
e nenhum item aberto sem `RESOLVED by` saiu. A catraca fica em 91 e as listas do `campaign.md`
batem com o `TODO.md`. Saíram um MEDIUM de prosa e quatro LOW. O MEDIUM: o conserto do achado 5 da
r3 não corta mais branch de um placeholder, mas manda o relay a "commit nothing", e o `sdd approve`
commita a pasta inteira no mesmo caso (bloco 3c do `check-gates.sh`). Nenhum fica num verbo de
confiança. Nenhum `R<n>`. Nota: A em todos os critérios.

## Nota da rodada

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | A | Os consertos de código têm uma linha cada, na definição que corrigem, com o porquê no comentário: a guarda `"${HOME:-}"` com `''` no braço da recusa, a limpeza por prefixo armada antes e o `env -u` na testemunha. |
| Type Safety | A | Não se aplica a bash; o `HOME` não definido deixou de ser uma variável não associada sob `set -u` (`[unset]`, rc 0, reproduzido). |
| Error Handling | A | O `source` do config sobrevive ao `HOME` vazio ou ausente, e o comentário do `review_head_ok` declara o nome que o git ainda põe entre aspas, que recusa a rodada pelo lado seguro. |
| Security | A | O scan de segredos (regex + gitleaks) deu 0 achados em 19 arquivos e 200 linhas, com `errors: []`; nada no diff leva valor de frontmatter a um comando. |
| Performance | A | Nada roda a mais além de um laço `compgen` no topo de um sensor e de duas corridas do `--red` sobre fixtures de duas linhas. |
| Test Coverage | A | Cada conserto de sensor tem o mundo vermelho reproduzido: a testemunha do índice (rascunho, abaixo), os 2 FAIL do `EFFORT_TICKET`, o piso 452 exato e a asserção do `check-hat.sh` que reprova o texto de antes. |
| Documentation | A | Os achados da r4 e da r3 estão fechados no texto. Sobram um MEDIUM de prosa (o destino do ramo `auto` com placeholder) e quatro LOW de registro, que a régua manda ao lote sem segurar a nota. |
| **Overall** | **A** | Nenhum CRITICAL ou HIGH, nem MEDIUM num verbo de confiança; os sensores avulsos estão verdes neste head e os números do registro conferem no ledger. |

## Achados da rodada

| # | Severidade | Achado | Onde |
|---|---|---|---|
| 1 | MEDIUM (prosa) | O `706fe3b` fecha o achado 5 da r3 como escrito: o ramo `auto` não corta mais branch de um `branch:` vazio ou placeholder. O destino que ele dá, porém, é o **Anywhere else**, que diz "commit nothing". Com o mesmo `branch:` placeholder, a porta que esse ramo substitui faz outra coisa. O `sdd approve` não troca de branch e **commita a pasta inteira da missão onde o humano está**, com o aviso de branch de base. Isso está no comentário do #156 no `cmd_approve`: o `01-plano.md` e o `checkpoint.md` em `??` deram ao `gate_REVIEW` seguinte uma árvore suja. E está no bloco 3c do `tests/check-gates.sh`, verde neste head: "sdd approve with a placeholder branch stays, warns and commits the whole directory". Com `auto`, `JIRA_ENABLED=true` e o placeholder, o relay que segue o texto deixa a pasta em `??`, e o `sdd preflight` reprova com `working tree dirty` (`bin/sdd:7165`). A TICKET commita só o `10-ticket.md` e o `00-missao.md` (`agents/sdd-ticket.md:66`), e o **Anywhere else** não diz que o próximo passo é `sdd run`. É o sintoma do item que o `96d1bc5` resolveu, num subcaso. A direção da r3 ("cair no Anywhere else") estava errada, e o chore a seguiu. Direção: com o `branch:` vazio ou placeholder, nada troca de branch. A pasta da missão e o arquivo do `adr:` são commitados onde o relay está, com o aviso de branch de base, como o `sdd approve` faz, e o próximo passo é `sdd run <missão>`. A asserção nova do `check-hat.sh` muda junto com o texto. | `commands/sdd-plan.md:349-352`, contra `:365-366` e `tests/check-gates.sh:4792-4834` |
| 2 | LOW | O item 2 da entrada nova compara a razão r2/r1 de 0,36 com o "antes 1,0 a 1,5", que vem da missão do worker (ADR 0023, linhas 26 a 28: código novo, 22 `R<n>`). O mesmo ledger tem os dois lotes da campanha anteriores ao delta. No L1, 1,30/2,11 = **0,61** (runner `cc8509a`); no L1b, 2,16/2,24 = **0,97** (runner `336640e`). Nenhum dos dois runners carrega o `079bc39`, o primeiro com delta: `git merge-base --is-ancestor 079bc39 <runner_sha>` → rc 1 nos dois, e rc 0 no do L2. Sem esses controles, a entrada atribui ao delta uma diferença que o L1, sem delta, já mostrava em parte. Direção: pôr os dois números ao lado do 0,36. | `KAIZEN_LOG.md:33-36` |
| 3 | LOW | O item 1 mede "US$ por item" (o total da EXEC sem o I7, dividido pelos 14 itens): 1,8×. A entrada do L2, logo abaixo, diz "por isso a medida é **por sessão**, nunca o total", e dá 2,6× por sessão, com o I7 dentro. São dois números para a mesma comparação em entradas vizinhas, sem frase que diga por que a métrica mudou. O veredito vale pelas duas, porque o critério é a contagem de `R<n>`. O "por item" foi o que o critério fixou antes do resultado (`effort-baseline.md` da sessão 823b8171), e a correção é dizer isso numa frase. | `KAIZEN_LOG.md:18-28`, contra `:87` e `:97` |
| 4 | LOW | O A3 levou o ramo "`git status` que não diz se a rodada está commitada" ao ADR 0023, ao `docs/pipeline.md` e à anatomia § 3. O verbete "Rodada delta" do `CONTEXT.md`, quarta cópia da mesma enumeração, ainda lista "Sem rodada anterior, rodada que o git não carrega, sem chave, chave errada ou um merge depois dela". Também diz "o número do depois nasce no L2", e a anatomia § 3, no mesmo parágrafo que o `544ff8c` editou, mantém "A medida em dinheiro (r≥2/r1, antes 1,0 a 1,5) é do L2". O número agora existe (0,36, `f524f9d`). Só prosa; a anatomia é texto do dono. | `CONTEXT.md:47`, `.claude/rules/anatomia-do-agente.md:156` |
| 5 | LOW | A última linha do diário (02:29) diz "as listas do campaign.md (L4 +1, L5b +1, L5c +2)" e "catraca 106 → 90". O commit que a acrescenta (`4190438`) põe **dois** itens no L5b (16 → 18), e vem depois do `ac24205` (o item do `budget-exhausted`, catraca 90 → 91). Nenhuma linha do diário registra o `ac24205`. O `handoff-L2.md` diz certo (91, os dois do L5b). Direção: acrescentar uma linha, sem editar a de 02:29 (o diário só cresce). | `docs/superpowers/campaigns/20261117-zerar-as-issues/journal.md:79` |

### Os bots no `f524f9d` (acrescentado pela sessão orquestradora, depois da rodada)

O Copilot não revisou (sem cota). O CodeRabbit deixou 2 achados, os dois de prosa que este chore escreveu, e os
dois vão ao mesmo lote dos cinco acima, para o chore do L3, pela régua A (nenhum toca um verbo de confiança):

| # | Severidade | Achado | Onde |
|---|---|---|---|
| 6 | MEDIUM (prosa) | O mesmo do achado 1, visto pelo lado do Jira: com `auto` e `JIRA_ENABLED=true`, o `branch:` vazio ou placeholder manda o relay ao **Anywhere else**, que não commita nada; a TICKET cria o branch e commita só o `10-ticket.md` e o `00-missao.md`, e o `01-plano.md` e a ADR ficam sem rastreio. O caminho do `branch:` nomeado commita a pasta e o `adr:`; este não. Direção: commitar o mesmo conjunto no branch que a TICKET cria, antes do EXEC. | `commands/sdd-plan.md:352` (thread do CodeRabbit `4650860715`) |
| 7 | LOW | A linha-modelo nova do contexto verificado (`81a3fda`) pede `file:line` para todo fato, e um fato que um comando prova sem linha de fonte (a árvore limpa, por `git status --short`) não tem âncora. Direção: exigir `file:line` só quando o fato vem de um lugar no código, e o comando sempre. | `agents/sdd-planner.md:106` e `templates/plano.md:19` (thread do CodeRabbit `4650860712`) |

## Incrementos de conserto (R<n>)

Nenhum. Pela régua A, só um CRITICAL ou HIGH, ou um MEDIUM reproduzido num verbo de confiança, abre
`R<n>`. O #1 é prosa do relay do `/sdd-plan`, e os #2 a #5 são LOW de registro. Os cinco vão **num
lote**, ao chore pós-merge do L3 ou a este, antes do merge, se a sessão orquestradora preferir. A
cerimônia é a de prosa:

- #1: `bash tests/check-hat.sh` → rc 0, com a asserção do placeholder lendo o texto novo. A
  testemunha da paridade é o bloco 3c do `bash tests/check-gates.sh`, que não muda;
- #2 a #5: `bash tests/check-lang.sh` → rc 0 e `bash tests/check-todo.sh --check TODO.md` → `91 finding(s)`.

## O que virou incremento

Nenhum `R<n>` nesta rodada. O que a rodada conferiu, achado por achado:

- **A1** (r4 do L1b, testemunha do índice): fechado em `41a1b24`. Reproduzi num repo de rascunho
  (git 2.43, `GIT_OPTIONAL_LOCKS=0` exportado). A consulta deixa o índice intacto; o `git status` cru
  com a variável exportada também não o reescreve, que era o vermelho falso. O `env -u` o reescreve:
  `query-untouched=y exported-plain-untouched=y env-u-rewrote=y`. A consulta roda com a variável
  apagada, então um kit que a largasse fica vermelho também sob a variável exportada.
- **A2**: fechado em `fbc5e53`, só comentário. Ele diz o que o `bin/sdd-worker:1239-1240` já diz
  (o nome entre aspas não casa glob e recusa pelo lado seguro). `bash -n` rc 0; `shellcheck -S
  warning bin/sdd` limpo.
- **A3**: fechado em `44357b8`. A ordem do ADR (sem rodada, `git status` que falha, não commitada,
  sem chave…) é a ordem do `review_base_line`, e "the second and third cases" são os dois que leem o
  `git status`. Resíduo no `CONTEXT.md` (achado #4).
- **A4**: fechado em `544ff8c` (texto do dono, abaixo).
- **A5**: `dc3194c`. **A6**: `ca6c1b6`, que muda o `TODO.md` e o `campaign.md` no mesmo commit.
  `sdd-worker level` → `level full — signed until 2026-11-26 18:00`.
- **A-fora**: a `Direção:` do item nomeia `bin/sdd-worker:1349`, que é o `git status` do `pr-ready`
  sem a variável.
- **B1**: `81a3fda`. A linha-modelo e o `agents/sdd-planner.md:105` pedem o comando ao lado da
  âncora, e o espelho está idêntico (`cmp` rc 0). **B2**: `7a1be46`. `env -u HOME bash -c 'set -u; .
  .sdd/config.sh; echo "[${READ_EXTRA-unset}]"'` → `[unset]` rc 0, com `HOME=` → `[unset]` e com o
  `HOME` desta máquina a entrada de sempre.
- **B3**: `fda517d`. O `probe_on` apaga a testemunha antes de cada corrida (`rm -f -- "$what"`),
  então o controle `ran` não vaza para o `notran` seguinte. O selftest dá rc 0 com
  `rule: --red --list … (40 probe(s))`.
- **B4**: `c807b6c`. **B6**: `f0a31cd`. `PROBE_FLOOR` é 447 no `00b8fad^` e 450 no `00b8fad` e no
  `6198b68`; `--count` dá 99 no `daf51f9` e 106 no `6198b68`.
- **B5**: `706fe3b` fecha o que a r3 escreveu, e o destino dele é o achado #1.
- **C** (o `sdd close` do `check-gates.sh` com o `EFFORT_TICKET` herdado): fechado em `069cb5e`. A
  variável é armada antes e limpa por prefixo (`compgen -v EFFORT_`), no molde do `d48f7c9`.
- **`f1d7253`**: os 7 hashes (`8a21366`, `9bea822`, `256e9d4`, `96d1bc5`, `972a482`, `d48f7c9`,
  `0da9417`) dão `merge-base --is-ancestor … origin/main` rc 0. São 16 `RESOLVED by <hash>` no
  `6198b68` e 0 no head. Os títulos que saíram são esses 16, mais o renomeado do A6; os que entraram
  são esse mesmo e o do `budget-exhausted`. `--count` dá 106 no base e 91 no head, e o
  `todo-findings 91` é igual.
- **`ac24205`**: a afirmação confere. `bin/sdd:6077` diz "Same ledger kind as the phase ceiling", o
  `:6121` (teto da missão) e o `:9972` (teto da fase) gravam os dois `budget-exhausted`, e só o
  primeiro escreve `mission budget: … against BUDGET_MISSION_USD`. O `commands/sdd-worker.md:178-179`
  e o `:272` leem o `kind` como o teto da missão. No ledger, a linha `blocked`/`PR`/`budget-exhausted`
  de 23:56:08 traz o `gate_why` "50-pr.md has no 'pr_url:'", com US$ 37,52 gastos até ali. A âncora
  `:178` aponta o literal da `:179`, dentro do `ANCHOR_REACH=10`.
- **`4190438`**: os 6 títulos novos ou mudados das listas são, letra por letra (`grep -xF`), títulos
  de item aberto. Toda lista do L3 ao L6 tem só itens abertos, e as contagens da tabela batem com as
  listas (L4 15, L5b 18, L5c 9). As afirmações do `handoff-L2.md` conferem no ledger: 15 sessões,
  22 022 s, US$ 38,03; EXEC US$ 27,89; PR US$ 1,22; r1 3,80 e r2 1,36. Conferem também no worktree
  do L3: o branch `fix/l3-gates-do-fim-da-linha`, 12 de 12 `- answer: (recommended)` e 5 `◆`.
- **`f524f9d`**: os números conferem no ledger (`LC_ALL=C jq`, linhas `session`). No L1, 10 sessões
  de EXEC, 13 697 s, US$ 13,21, ou 0,94 por item, e REVIEW 3,41. No L1b, 6 sessões, 12 841 s,
  US$ 11,29, e REVIEW 4,40. No L2, 7 sessões sem o `3672ea89` (2 710 s, US$ 3,85), 15 501 s,
  US$ 24,04, ou 1,72 por item, e REVIEW 5,16. A razão do L2 é 1,3629/3,7977 = 0,359. A r2 do L2 foi
  delta (runner `079bc39`). Os achados #2 e #3 tratam da leitura, não dos números.

## O que foi refutado

- **"Sobram 8 `RESOLVED by` no `TODO.md`"**: são menções em prosa (o cabeçalho, dois itens sobre o
  ciclo de vida, um decidido). `grep -cE 'RESOLVED by [0-9a-f]{7}' TODO.md` → 0.
- **"`toda consulta` exagera, porque sem rodada não há `git status`"**: a frase diz "o `git status`
  que toda consulta roda **para saber se a rodada está commitada**", o que pressupõe uma rodada. Lê
  como o código faz.
- **`shellcheck -S warning .sdd/config.sh`** dá SC2148 e SC2034 em toda atribuição. É a forma de um
  arquivo lido por `source`, igual no base, e o chore não acrescentou nenhum.
- **O `compgen -v EFFORT_` poderia apagar uma variável do próprio sensor**: ele roda no topo do
  `check-gates.sh`, antes de qualquer definição, e a limpeza é o que o comentário promete.

## Achados fora de escopo

- **8 itens abertos do `TODO.md` não estão em lote nenhum da campanha**, que promete o backlog a
  zero: os dois `failure-modes.md`, o leitor D22, o `pgrep` sem pasta (r1 do L2), o `--budget-override`
  fora do `--help`, a grafia do `⛔`, a run viva depois do PR e o teto que não soma a sessão morta.
  Isso já estava no `6198b68`: lá eram 14, o chore apagou 2 resolvidos e listou 4. A fila é do dono
  (o `campaign.md` diz que o worker nunca a reescreve), então vai às pendências, não ao `TODO.md`.

## Pendências / Decisions for a Human

- **O aceite do texto da `.claude/rules/anatomia-do-agente.md` § 3 (`544ff8c`)**, que vai no corpo
  do PR. A rodada o conferiu contra o `review_base_line`: a ordem dos casos inteiros é a do código,
  e o `git status` com `GIT_OPTIONAL_LOCKS=0` roda em toda consulta que acha uma rodada. Se o achado
  #4 entrar, a mesma frase ganha o 0,36 no lugar de "é do L2".
- **Os 8 itens fora da fila** (seção anterior): entram num lote, ou ficam declarados fora da
  campanha.
