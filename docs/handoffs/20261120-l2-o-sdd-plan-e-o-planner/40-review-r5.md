---
missao: 20261120-l2-o-sdd-plan-e-o-planner
fase: REVIEW
rodada: 5
status: done
sessao: 723ca6a1-33c8-4c2b-b659-719fb963a190
data: 2026-11-21 03:19
gate: "tests/run-all.sh rc=0 (suite green, 2238 linhas ok, 0 FAIL, 926 mutantes aplicam) sobre 5eb96d2; sdd review-base → base=f524f9d (delta, a r4 como lista dos achados abertos)"
reviewed_head: 5eb96d2d795f5627183106a7608d739d149d6ec1
---

# Review — rodada r5 — o pós-merge do L2 (PR #457), delta sobre a r4

## TL;DR

Rodada **delta** do worker, `/codereview:codereview base=f524f9d`, sobre 5 commits: o `af6d490` (a
própria r4) e os quatro consertos `99da90c`, `1bd7cd1`, `65c4643` e `5eb96d2`, em 9 arquivos com
+199/−15 linhas. Os 7 achados da r4 e o P2 do Codex (thread `4650983491`) estão fechados como
escritos. No `cmd_approve`, o `branch:` placeholder não troca de branch, avisa no branch base e
commita a pasta e o `adr:`. A asserção nova do `check-hat.sh` dá FAIL sobre o texto do `706fe3b` e
PASS no head. Os seis custos de REVIEW e as três razões do `KAIZEN_LOG.md` batem com o ledger, o
`is-ancestor` dá 1, 1 e 0, e o `cmp` do espelho do planner dá rc 0. A metade do achado 7 que fala
do `templates/plano.md` foi refutada: a linha-modelo já pede o comando ao lado de cada âncora, e não
uma âncora para cada fato. Saíram três LOW novos. O principal é a frase nova "The TICKET phase cuts
the mission branch from there". A skill `ticket` corta da base atualizada (`checkout`, `pull`,
`checkout -b`), então o plano commitado fora do `DEFAULT_BRANCH` não chega ao branch da missão nem
fica na árvore. Reproduzi isso num repositório de rascunho. Nenhum está num verbo de confiança.
Nenhum `R<n>`. Nota: A em todos os critérios.

## Nota da rodada

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | A | O único código do delta é a asserção do `check-hat.sh`: três `grep -qF` por herestring, com a frase de antes recusada por `!`, e o comentário diz por que ela mudou (`bash -n` e `shellcheck -S warning` limpos). |
| Type Safety | A | Não se aplica a bash nem a prosa; o delta não muda nenhuma variável, chave de config ou contrato tipado. |
| Error Handling | A | O ramo novo do `/sdd-plan` segue o caminho do `cmd_approve` (`ensure_mission_branch` volta 0 com o `branch:` vazio, `bin/sdd:6482-6483`), e o que sobra é prosa do relay, que falha alto (árvore suja ou plano ausente), nunca calada. |
| Security | A | O scan de segredos (regex + gitleaks) deu 0 achados em 9 arquivos e 199 linhas, com `errors: []`; o delta não leva valor de frontmatter a comando nenhum. |
| Performance | A | Duas buscas `grep -qF` a mais num sensor que já roda em segundos (`check-hat.sh`, 143 ok); nada mais roda a mais. |
| Test Coverage | A | A asserção nova reprova o mundo que importa: FAIL sobre o texto do `706fe3b`, FAIL com a frase velha somada ao texto novo, PASS no head, e o `check-hat.sh` dá rc 0 com 0 FAIL. |
| Documentation | A | Os 7 achados da r4 e o do Codex fecham no texto. Sobram três LOW de prosa, a frase sobre de onde a TICKET corta, o destino do "resto" no ramo placeholder e o mecanismo do `KAIZEN_LOG.md`, que pela régua vão a um lote sem segurar a nota. |
| **Overall** | **A** | Nenhum CRITICAL ou HIGH e nenhum MEDIUM num verbo de confiança; os números conferem no ledger e os sensores avulsos estão verdes neste head. |

## Achados da rodada

### Os achados abertos da r4 e o do Codex

| # | Origem | Fechado? | Evidência |
|---|---|---|---|
| 1 | r4, MEDIUM (prosa) | sim, `99da90c` | `commands/sdd-plan.md:352-356`: o ramo `auto` com o `branch:` vazio ou placeholder não troca de branch, commita a pasta e o arquivo do `adr:` onde está, avisa quando é o `DEFAULT_BRANCH` e diz que o próximo passo é `sdd run <mission>`. O `cmd_approve` faz o mesmo. O `mission_branch_declared` transforma `<…>` em vazio (`bin/sdd:6474`). O `ensure_mission_branch` volta 0 com vazio (`:6483`). O `warn_if_on_base_branch` roda quando não há troca (`:9301`). O commit leva `paths=( "$mission_rel" )` mais o `adr:` quando ele é um caminho dentro do checkout (`:9356-9380`). Resíduo: os LOW 8 e 9. |
| 2 | r4, LOW | sim, `65c4643` | `KAIZEN_LOG.md:40-46` traz a tabela com os controles. No ledger (`LC_ALL=C jq`, `session`/`REVIEW`): L1 2,111748 e 1,2979624 (`cc8509a`), L1b 2,2362726 e 2,1598792 (`336640e`), L2 3,7977288 e 1,3628686 (`079bc39`). As razões são 0,6146, 0,9658 e 0,3589. `rounds_before` 0→1 e 1→2 em cada par. `git merge-base --is-ancestor 079bc39 <runner_sha>` dá rc 1, 1 e 0. Resíduo: o LOW 10. |
| 3 | r4, LOW | sim, `65c4643` | `KAIZEN_LOG.md:28-31` diz que a medida é por item porque foi o "por item" que o critério fixou antes do resultado. O critério fala em "custo por item maior" (`:15-17`), e o 2,6× por sessão está em `:100`. |
| 4 | r4, LOW | sim, `65c4643` | O `CONTEXT.md:47` ganha o caso do `git status` que não diz se a rodada está commitada, e o "nasce no L2" vira 0,36 contra 0,61 e 0,97. A anatomia § 3 (`:156`) faz o mesmo. Fora de `docs/handoffs/`, `grep -rnE 'é do L2\|nasce no L2\|deixou para o L2'` não acha nada. |
| 5 | r4, LOW | sim, `5eb96d2` | `journal.md:82` registra a correção numa linha nova, e o diff do intervalo só acrescenta linhas (+5/−0, a de 02:29 fica intacta). O `4190438` muda a linha do L5b de 16 para 18 e acrescenta o item do `budget-exhausted`. |
| 6 | CodeRabbit, MEDIUM (prosa) | sim, `99da90c` | É o mesmo ramo do #1. A pasta e a ADR entram num commit antes da TICKET, e a TICKET corta o branch dela do `DEFAULT_BRANCH` com esse commit dentro: `1 0` no rascunho abaixo, o caso QUO-155 da skill. Resíduo: o LOW 8, quando o relay não está na base. |
| 7 | CodeRabbit, LOW | sim, `1bd7cd1` | `agents/sdd-planner.md:105-107` pede o `file:line` só para o fato que vem de um lugar no código, e o comando sempre. O `cmp agents/sdd-planner.md .claude/agents/sdd-planner.md` dá rc 0, e o espelho é rastreado. A metade do `templates/plano.md:19` foi refutada (seção abaixo). |
| Codex P2 | `af6d490`, thread `4650983491` | sim, `99da90c` | O mesmo do #1: com `auto`, `JIRA_ENABLED=true` e o placeholder, o ramo commita a pasta e o `adr:` no branch atual, avisa na base e nomeia o `sdd run`. |

A asserção do `check-hat.sh:1053-1059` foi conferida numa cópia em scratchpad, sobre a seção
`## When the artifacts exist` extraída como o sensor a extrai. Sobre o `git show 706fe3b:commands/sdd-plan.md`
dá FAIL, assim como sobre o `f524f9d`, cujo texto é idêntico (`cmp`). No head dá PASS. Com o texto
novo mais a frase velha ("switch to nothing and follow **Anywhere else**") dá FAIL. No worktree, o
`bash tests/check-hat.sh` dá rc 0, 143 linhas `ok`, 0 `FAIL` e a linha `ok    command: /sdd-plan
under auto cuts no branch … as sdd approve does`.

### Achados novos

| # | Severidade | Achado | Onde |
|---|---|---|---|
| 8 | LOW | A frase nova "The TICKET phase cuts the mission branch from there" só é verdade quando "there" é o `DEFAULT_BRANCH`. A sessão TICKET usa a skill `ticket`, que corta da base atualizada: `git checkout ${BASE_BRANCH}`, `git pull origin ${BASE_BRANCH}`, `git checkout -b …` (`~/.claude/skills/ticket/references/start.md:136-139`). O `:146-150` da skill nomeia o caso de propósito: "a fase PLAN de uma missão `sdd` comita na base antes de a branch nascer" (QUO-155, `2 0`). Reproduzi num repositório de rascunho. Com o plano commitado num branch `provisional`, a sequência do A8 deixa o `01-plano.md` fora do branch novo e fora da árvore, e o commit só existe no `provisional`. Com o plano na `develop`, o arquivo chega e a medida é `1	0`. O texto trata o `DEFAULT_BRANCH` como o caso que merece aviso, quando é o único de onde a TICKET leva o plano. Fora da base, que é o branch de outra missão ou o provisório de um worktree, o plano não chega ao branch da missão, e a TICKET perde a pasta da árvore no `checkout`. Falha alto, e o caso é estreito, porque a rota do worktree renomeia o branch e escreve o `branch:`. Direção: dizer que a TICKET corta do `DEFAULT_BRANCH` depois de um `pull`, então o plano só viaja commitado nele, e que fora dele o relay nomeia o caso ao humano antes do `sdd run`. A paridade com o `sdd approve` é a mesma (fora de escopo, abaixo). | `commands/sdd-plan.md:352-355` |
| 9 | LOW | O parágrafo de cima manda o arquivo de que o plano depende "on the mission branch with the rest, by the bullet that applies below" (`:343-345`). Os achados do `TODO_FILE` e a catraca também têm de chegar a um commit. O ramo do placeholder commita só a pasta e o `adr:`. Ao contrário do ramo do `branch:` nomeado ("then follow **On the mission branch** for the rest", `:358`), ele não diz para onde vai o resto. Também não pode herdar o **Anywhere else** (`:369`), cujo porquê ("lands … where the mission does not run") deixa de valer na base, de onde a TICKET corta. Direção: o resto entra onde o relay está, pela mesma regra do plano: o arquivo citado no commit do plano e o achado num commit próprio com a catraca. | `commands/sdd-plan.md:343-345`, contra `:352-358` e `:369` |
| 10 | LOW | "a r2 sai mais barata quando a r1 deixou um conserto só" explica o L1, mas a linha seguinte da mesma tabela a refuta. O L1b também deixou um conserto só (o `checkpoint.md` dele tem um `R1` e nenhum outro) e ficou em 0,97. O veredito do effort, logo acima, diz que os três lotes tiveram 1 `R<n>`. Direção: tirar o mecanismo, ou dizer que o L1b, também com um conserto, não caiu. | `KAIZEN_LOG.md:48` |

## Incrementos de conserto (R<n>)

Nenhum. Pela régua A, só um CRITICAL ou HIGH, ou um MEDIUM reproduzido num verbo de confiança, abre
`R<n>`. Os achados 8 a 10 são LOW de prosa em texto que o delta escreveu, e vão **num lote**, ao
chore pós-merge do L3 ou a este, antes do merge, se a sessão orquestradora preferir. A cerimônia é
a de prosa:

- #8 e #9: `bash tests/check-hat.sh` → rc 0. Se a frase da asserção do placeholder mudar, ela
  muda junto com o texto e continua recusando a frase do `706fe3b`;
- #10: `bash tests/check-lang.sh` → rc 0 e `bash tests/check-todo.sh --check TODO.md` → `91 finding(s)`
  (verdes neste head).

## O que foi refutado

- **A metade `templates/plano.md:19` do achado 7.** A linha-modelo é `- <fato> — `<comando que mediu>`
  → `<o que ele imprimiu>`, ao lado de toda contagem e de toda âncora `arquivo:linha``. Ela põe o
  comando ao lado de cada contagem e de cada âncora, e não pede uma âncora para cada fato. O fato
  sem linha de fonte, como a árvore limpa, cabe nela como está. O defeito estava na frase do agente
  ("a `file:line` too, never bare"), que o `1bd7cd1` trocou. O verificador da rodada leu a linha
  como ambígua, e ela vai a "fora de escopo" como forma.
- **"A anatomia § 3 rebatiza o 1,0 a 1,5 do worker de r2/r1, quando a ADR 0023 mediu r≥2/r1."** A
  r2/r1 do worker é 6,31/5,12 = 1,23 (ADR 0023, linhas 26 a 28), dentro do intervalo. A frase fica
  imprecisa, mas não falsa.
- **"O diário escreve 02:32 e 02:57 numa linha commitada às 03:02."** Os instantes são os dos
  eventos. O `ac24205`, o `4190438` e o `f524f9d` são de 02:31. O PR #457 foi criado em
  `2026-11-21T05:32:17Z` (02:32 local). O `af6d490` é de 02:56. As linhas entram em ordem
  cronológica, depois da de 02:29.

## Achados fora de escopo

- **O `sdd approve` com o `branch:` placeholder, fora do `DEFAULT_BRANCH`, commita onde a TICKET não
  corta** (`bin/sdd:9295-9302` e `:9374-9380`, que o delta não tocou). É o mesmo mecanismo do
  achado 8, no código: a skill `ticket` faz `checkout` da base, e o commit da aprovação fica no
  branch de onde o humano aprovou. O bloco 3c do `check-gates.sh` prova o "fica, avisa e commita",
  mas não onde a TICKET corta depois. Candidato ao `TODO.md` (régua A, regra 2), junto com o achado
  8 se o lote preferir consertar os dois juntos.
- **`templates/plano.md:19-20`** (forma, levantada pelo verificador): "ao lado de toda contagem e de
  toda âncora `arquivo:linha`" pode ser lida como se pedisse `arquivo:linha` a cada contagem. Pela
  leitura da seção anterior, ela não pede. Se o dono quiser a frase do agente também no template, é
  uma linha. A forma não conta na nota.

## Pendências / Decisions for a Human

- **O aceite do texto novo da `.claude/rules/anatomia-do-agente.md` § 3 (`65c4643`)**, que vai no
  corpo do PR. Conferido contra o `KAIZEN_LOG.md` de 2026-11-21: 0,36 no L2, 0,61 e 0,97 nos L1 e
  L1b, sem delta, e 1,0 a 1,5 na missão do worker. Os seis custos e o `is-ancestor` batem com o
  ledger. Se o achado 10 entrar, a frase da anatomia não muda, porque não carrega o mecanismo.
- **O verificador da rodada** (um agente `sonnet`) leu 38 unidades, contra 77 que recebeu. A falta
  está no `40-review-r4.md`, que eu passei comprimido numa linha só. Os achados abertos moram nos
  outros seis arquivos, cujas 19 unidades ele nomeou uma a uma, e cada achado foi fechado acima por
  reprodução própria. Não relancei, porque a r4 é o artefato da rodada anterior e não tem achado
  aberto. Se a sessão orquestradora quiser o contrato cheio, o relançamento é só sobre esse arquivo.
- **Os 8 itens fora da fila da campanha** (r4) seguem como estavam: o delta não os tocou.
