---
missao: 20260901-o-revisor-so-acha
fase: QA
status: done
sessao: 20d349be-732d-4333-849a-9b607ff4a946
data: 2026-09-01 19:45
gate: "sem interface (`E2E_CMD` e `APP_URL` vazios): 9 jornadas caminhadas no terminal. `tests/run-all.sh` → 855 asserções `ok`, última linha `suite green`, rc 0 (105 s). `./bin/sdd preflight` → `preflight ok`, 0 vermelhos, `7 kit agent(s) checked`. `./bin/sdd autonomy --all-repos --by-mission` → 16 células `review loop US$ X (N%)`; a janela 2 lê `25 · 29 · 57`. O laço de `20260831-a-rodada-que-andou` foi **recomputado à mão** por `jq` sobre o ledger cru → `loop US$ 66.34115 / total US$ 132.57396 = 50%`, idêntico ao que o instrumento imprime. `./bin/sdd run … --phase REVIEW --dry-run` → o prompt diz `you do NOT fix the code` e `R<n> increment`, e **não** contém `review and fix, INSIDE`. `./bin/sdd phase` → `QA`; `./bin/sdd status` → `next phase: QA`. `diff -q` dos 7 espelhos `agents/` × `.claude/agents/` → vazio. Registry `docs/qa/bugs/` sem nenhum `Status: open`. Resultado: **4 defeitos confirmados** (cada um reproduzido com o vermelho medido antes de virar linha) → **4 incrementos `F1`–`F4` `pending`** no checkpoint; 3 hipóteses levantadas e **refutadas com evidência**; `tests/check-checkpoint.sh` verde sobre as quatro linhas novas."
---

# Handoff — QA — O revisor só acha

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

9 jornadas caminhadas no terminal (o kit não tem interface: `E2E_CMD` vazio, e esta é a única
sessão da fase). **4 defeitos confirmados → 4 incrementos `F1`–`F4` `pending`**; 0 spec nova, porque
não há superfície e2e e todo defeito achado mora na suíte `TEST_CMD`. Três dos quatro estão **dentro
do diff da missão** — o I2 mudou o contrato em cinco lugares e o `README.md` é o sexto; e o pior
deles (`F1`) faz o `templates/review.md` mandar a rodada registrar o que corrigiu, empurrando a
REVIEW de volta a consertar in-session, que é o que a missão existe para apagar. O `F2` é um
**fail-open medido nos dois sentidos**. Levantei outras 3 hipóteses e refutei as 3 com evidência.

## Estado do repo

- **Branch:** `feat/o-revisor-so-acha` — 10 commits à frente de `main` (`35863d9`), sem push.
- **Último commit:** `148f693` `docs(qa): 9 jornadas de linha de comando…` (o commit desta fase que
  acompanha o checkpoint vem a seguir).
- **Working tree:** limpo. Esta fase escreve **só** este handoff e o `checkpoint.md`; nenhum arquivo
  de produção foi tocado — QA não conserta.
- **Suíte:** `tests/run-all.sh` → **verde**, 855 asserções `ok`, `suite green`, rc 0 (105 s).
- **E2E:** `E2E_CMD=""` — o kit não tem interface. Não rodou por não existir, e **não** foi criada
  spec nenhuma: a caminhada é de linha de comando, e o defeito que ela acha mora na suíte
  `TEST_CMD`, nunca num `<E2E_DIR>` que este repo não tem. Os quatro `F<n>` levam sensor de
  regressão nessa suíte.

## O que foi feito

QA não commita código. O que esta sessão produziu são as jornadas, os defeitos que elas expuseram e
os incrementos de conserto — o commit é deste handoff e do `checkpoint.md`.

| # | Jornada (comando) | Observado |
|---|---|---|
| J1 | `./bin/sdd autonomy --by-mission` | 16 missões; o sufixo `· review loop US$ X (N%)` aparece só onde houve REVIEW. `20260901-o-revisor-so-acha` **não** imprime célula — o comportamento que `bin/sdd:5085` promete |
| J2 | `./bin/sdd autonomy --all-repos --by-mission` | 16 células `review loop`; a janela 2 (`sales_quote`) lê **25 · 29 · 57** — mediana 29%, máximo 57% |
| J3 | recomputação **independente** do laço, por `jq` sobre o ledger cru | `first REVIEW index = 5`, `loop = US$ 66.34115`, `total = US$ 132.57396`, `share = 50%` — idêntico ao impresso e ao US$ 66,34 que o `00-missao.md` cita para o PR #33 |
| J4 | `jq 'has("turns")'` sobre as 201 linhas do ledger | `194 session has_turns=false`, `7 blocked has_turns=false` — ver refutação **R3** |
| J5 | `./bin/sdd run … --phase REVIEW --dry-run` + leitura do contrato nos 6 lugares | prompt correto; **mas** `templates/review.md` e `README.md` o contradizem → `F1` e `F3` |
| J6 | `diff -q agents/*.md .claude/agents/*.md` | 7 de 7 idênticos — os espelhos estão em dia |
| J7 | `./bin/sdd preflight` | `preflight ok`, 0 vermelhos, `7 kit agent(s) checked` |
| J8 | `./bin/sdd phase` e `./bin/sdd status` | `QA`; `next phase: QA — missing 30-handoff-qa.md`, I1–I4 `✓` com hash |
| J9 | `tests/run-all.sh` + sabotagem dirigida aos sensores novos | 855 `ok`, `suite green` — **mas** `check-templates.sh` continua verde com o heading antigo → `F2` |

### Os 4 defeitos confirmados (→ `F1`–`F4` no `checkpoint.md`)

Cada um foi **reproduzido com o vermelho medido antes de virar linha**. A proveniência detalhada
está nas notas de execução do `checkpoint.md`; nenhum veio do registry, que não foi tocado.

| ID | Defeito | Onde | Como foi reproduzido |
|---|---|---|---|
| `F1` | o template manda a rodada registrar o conserto que ela não faz mais: `:19` pede "o que foi corrigido" no TL;DR e `:64-65` mandam o achado que virou correção reaparecer "na seção seguinte, com hash" — a seção seguinte começa com **"Esta rodada não conserta."** e não tem coluna de hash | `templates/review.md:19,64-65` | `grep -c 'virou correção'` → `1` e `grep -c 'o que foi corrigido'` → `1`, ambos devendo ser `0` |
| `F2` | **fail-open:** `check-templates.sh:129` casa `'^## Incrementos de fix'`, que serve ao heading **antigo** tão bem quanto ao novo, enquanto o rótulo jura pinar `'Incrementos de fix (QA e REVIEW)'` | `tests/check-templates.sh:129` | revertido o heading do template para `(QA)` → o sensor responde **rc=0**. O irmão em `:217-220` faz certo e diz por quê |
| `F3` | o contrato que o I2 mudou em cinco lugares tem um **sexto**: `` `sdd-reviewer` … `40-review-r<N>.md` + fixes `` — o revisor não entrega mais fixes | `README.md:152` | `grep -c 'sdd-reviewer.*fixes' README.md` → `1`. `README.md` está na `surface()` do `check-lang.sh`, isto é, é arquivo que o kit **afirma** manter em dia |
| `F4` | a allowlist da guarda casa um **glob** contra a saída de `git diff`, e `HANDOFF_DIR` nunca é normalizado: uma barra final faz a guarda gritar em **toda rodada saudável**. Junto, o braço `tests/health-baseline.txt`, que o comentário escopa "in the kit's own repo" sem condição no código | `bin/sdd:2250` e `:2252` | com `HANDOFF_DIR="docs/handoffs/"` o próprio `40-review-r1.md` da rodada é marcado `FLAG`; `grep -c 'HANDOFF_DIR%/' bin/sdd` → `0` |

### As três hipóteses que levantei e refutei

Estão aqui porque a rodada seguinte não deve gastar dinheiro reabrindo-as.

- **R1 — "uma linha de escalada com `phase: REVIEW` desloca a fronteira do laço."** **Refutada:**
  `bin/sdd:5041` monta `$mgroups` com `map(select(is_session and comparable))`, e escalada não é
  `is_session`. Confirmado no ledger real: as 7 linhas `blocked` carregam `phase` (`EXEC`×6, `QA`×1)
  e nenhuma entra na conta.
- **R2 — "o `findings file` que o prompt manda commitar está fora da allowlist da guarda."**
  **Refutada:** o "findings file" é o `TODO_FILE` (`bin/sdd:2886` e `:2905`, "Out-of-scope findings
  from `sdd` missions"), que é o segundo braço da allowlist (`bin/sdd:2251`). Fica a observação de
  que a prosa é ambígua — "the findings file" pode ser lido como o próprio `40-review-r<N>.md` —,
  mas o prompt nomeia `TODO.md` explicitamente na frase final, então nada se perde.
- **R3 — "o campo `turns` não é escrito: 194 de 194 linhas de sessão respondem `has_turns=false`."**
  Era a mais grave, porque o campo é o instrumento do I1. **Refutada como defeito de código:**
  levantei o programa `jq` verbatim de `bin/sdd:2483-2502` e ele responde
  `{"event":"session","turns":7}` com o global preenchido e `{"event":"session","turns":null}` com
  ele vazio — a chave é emitida **incondicionalmente**. A causa é outra, e é real: as 4 linhas desta
  missão compartilham **um** `run_id` (`fe7f4add`), e esse processo `sdd run` foi lançado **antes**
  de `88432ee` (18:12:56) pousar o campo — ele carrega o `bin/sdd` pré-I1 em memória.

## Artefatos

| Arquivo | O que contém |
|---|---|
| `docs/handoffs/20260901-o-revisor-so-acha/30-handoff-qa.md` | este handoff: 9 jornadas, 4 defeitos confirmados, 3 refutações com evidência |
| `docs/handoffs/20260901-o-revisor-so-acha/checkpoint.md` | as linhas `F1`–`F4` `pending`, com Check executável, mais 5 notas de execução com a proveniência e o vermelho medido de cada uma |
| `docs/qa/` | **não tocado.** A árvore existe desde 2026-08-21/24 (um humano rodou `qa-report` à mão) e pertence às skills: li o registry e os relatórios, não escrevi nem apaguei nada |

## Boot da próxima fase

**Não é a REVIEW: é o EXEC.** Há 4 incrementos `pending` no `checkpoint.md`, então o runner devolve
a bola ao `sdd-executor` — é o laço QA⇄EXEC, com teto `QA_MAX_ITER=3`. Ordem sugerida **`F1` →
`F2` → `F3` → `F4`**: o `F1` é o mais urgente porque a REVIEW desta missão é a **primeira** a ler o
`templates/review.md`, e hoje ele a manda registrar o conserto que ela não deve mais fazer.

Para quem pegar os incrementos:

1. **Os quatro Checks já rodam e já estão vermelhos** — os valores estão nas notas do checkpoint.
   O `F2` é um Check **nos dois sentidos** (com o heading antigo o sensor tem de ficar `rc=1`; com o
   novo, `rc=0`): é a única forma de provar que a asserção deixou de falhar aberta.
2. **`F4` pede um probe novo** em `tests/check-autonomy.sh` com o nome exato que o Check ancora:
   `a trailing slash in HANDOFF_DIR does not turn a healthy round into a warning`. Piso de
   superfície e catálogo de mutação sobem junto, como manda o `CLAUDE.md`.
3. **Nenhum `2>&1` num Check que também tenha `grep` não-ancorado** — `tests/check-checkpoint.sh`
   reprova, e reprovou duas das minhas quatro linhas antes de eu corrigi-las. O idioma do repo é
   `>/dev/null 2>/dev/null` quando não se está lendo saída de sensor, como a linha `I4` já faz.

**Quando o laço fechar, a REVIEW precisa saber:**

- **A M2 desta missão NÃO pode ser lida do ledger.** O `00-missao.md` § Métrica 2 manda ler `turns`
  "na linha do ledger". As linhas desta missão **não terão `turns`** (R3): o processo que as escreve
  é anterior ao I1, e é o **mesmo processo** que escreve as linhas de QA, EXEC e REVIEW — o campo só
  nasce no ledger no **próximo** `sdd run`. A fonte que funciona é `.sdd/logs/<missão>/*.json`
  `.num_turns`, já medida para as quatro sessões de EXEC: **74, 80, 56, 53** (custos 7.18, 7.77,
  5.67, 4.65). Comando: `jq -r '.num_turns' .sdd/logs/20260901-o-revisor-so-acha/REVIEW-*.json`.
  **Ler `turns` do ledger e achar `null` não é o instrumento quebrado** — é este fato, e concluir o
  contrário custaria uma rodada.
- **O que a M3 pede que a REVIEW confira** (o EXEC pediu, e a QA não fez para não duplicar):
  `gate_REVIEW` inalterado (A em toda linha + `Rationale` com frase) e o diff de
  `agents/sdd-reviewer.md` sem remover regra de reprodução ou refutação.
- **Não rodar `./bin/sdd health`** (15–50 min; o carimbo é da DOCS, depois do último commit de
  código).
- **Cosmético:** o `checkpoint.md` desta missão tem o heading antigo `## Incrementos de fix (QA)`
  enquanto `templates/checkpoint.md:63` já diz `(QA e REVIEW)`. Não quebra gate — e é exatamente a
  cegueira que o `F2` conserta.

## Pendências / Decisions for a Human

> Só julgamento humano genuíno. **Não bloqueiam o pipeline** — viram seção do PR.

- **Nenhuma nova nesta fase.** As duas que o EXEC abriu seguem de pé: a coluna **Depois** do
  `KAIZEN_LOG.md` (preenchida pela DOCS, depois de a REVIEW rodar) e **quando abrir e fechar a
  janela 3** (no sha do merge desta missão, padrão D19).
- Nenhum bug foi marcado `Closable by: human`, porque **nenhum bug foi aberto no registry**: os
  quatro defeitos têm causa técnica clara e fecham pelo ciclo `F<n>`, que é a definição de
  `Closable by: agent`. O registry `docs/qa/bugs/` continua sem uma linha `Status: open`.

## Riscos e não-feitos

- **Um achado real que NÃO virou `F<n>`, porque a correção é uma decisão e não um conserto:** a
  fronteira do laço de revisão (`bin/sdd:5093`) é calculada sobre o subconjunto **comparable**
  (`:4909` — `.event == "session" and on_axis and has("moved")`). Se a r1 rodar com o kit sujo, a
  linha dela cai fora, `$fr` avança para a r2, e as sessões EXEC que fecharam os `R<n>` da r1 passam
  a ficar **abaixo** da fronteira — excluídas do `$loop`, que é exatamente o que a M1 existe para
  contar. No limite, se toda linha REVIEW de uma missão for não-comparável, a célula **desaparece**
  numa missão que comprovadamente laçou. Os limites declarados em `:5085-5090` cobrem o
  **denominador**, não a fronteira. Corrigir mexe no significado da M1 (mover a população, ou
  declarar o limite) — é para a REVIEW pesar com olhos independentes, não para a QA decidir.
- **A cobertura desta QA é de superfície de comando, não de laço completo.** O que **não** foi
  caminhado ponta a ponta é uma rodada REVIEW real escrevendo `R<n>` e um EXEC fechando-o — por
  construção: é a fase seguinte, e é ela o primeiro teste real do desenho.
- **A guarda `REVIEW-EDITED-CODE` foi verificada por leitura, pelas 4 asserções da suíte e pela
  reprodução do `F4`, não provocada em sessão real.** Provocá-la exigiria uma sessão REVIEW que
  commitasse código.
- **`turns` continua sem uma única leitura real em ledger** (R3). O primeiro valor verdadeiro
  aparece no próximo `sdd run`.
- **Não rodei `./bin/sdd health` nem o catálogo de mutação (222).** Opt-in, 15–50 min, e o carimbo é
  da DOCS depois do último commit de código — que agora são os quatro `F<n>`.
- **Não reabri o que o EXEC já declarou não-feito** (catálogo ponta a ponta, cegueira da guarda a
  `commit --amend`) — está em `20-handoff-exec.md § Riscos` e continua valendo.

## Achados fora de escopo

> ⚠️ **Nada foi escrito no `TODO.md` nesta fase, e é deliberado, pelo mesmo motivo que o EXEC
> declarou:** `tests/health-baseline.txt` (a catraca do backlog) está na chave do carimbo de
> mutação, então registrar achado aqui mataria o carimbo mais uma vez. Este repo **é** o kit, então
> o destino é o `TODO.md` daqui e nenhum item precisa da rota `kit:` — quem transporta, com a
> catraca no mesmo diff e **antes** do `./bin/sdd health`, é a fase DOCS.
>
> Os três achados que o EXEC deixou para a DOCS (`env-cleanup` do `run_phase`, `surface()`
> enumerado do `check-lang.sh`, e a **classe** "piso que fica para trás") continuam válidos e
> **não** são repetidos aqui: estão em `20-handoff-exec.md § Achados fora de escopo`. A DOCS deve
> transportar os de lá **e** os dois de baixo.

- Uma sessão do runner escreve suas linhas de ledger com o `bin/sdd` que tinha em **memória** ao ser
  lançada, não com o que está no disco no fim — `bin/sdd` (`autonomy_session_row`/`run_phase`) — a
  missão que ACRESCENTA um campo ao ledger é, por construção, a única que não o registra, então todo
  instrumento novo nasce com uma janela cega do tamanho da própria missão, e uma métrica que nomeie
  o ledger como fonte (a M2 deste `00-missao.md`) fica insatisfazível sem que nada esteja quebrado;
  candidato: o `sdd run` avisar quando `bin/sdd` mudou sob ele, ou a métrica citar `.sdd/logs/` como
  fonte no ciclo em que o campo nasce — descoberto por `sdd-qa` na missão
  `20260901-o-revisor-so-acha` (2026-09-01) → `TODO.md`
- A fronteira do laço de revisão é calculada sobre o subconjunto `comparable`, então uma rodada
  não-comparável esconde as sessões EXEC que ela mesma gerou — `bin/sdd:5093` — a M1 é a métrica
  primária desta missão e sub-reporta exatamente o que existe para contar, e no limite a célula
  some numa missão que laçou; os limites declarados em `:5085-5090` cobrem o denominador e não a
  fronteira — descoberto por `sdd-qa` na missão `20260901-o-revisor-so-acha` (2026-09-01) →
  `TODO.md`
