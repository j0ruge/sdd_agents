---
missao: 20260815-ledger-sem-ponto-cego
fase: QA
status: done
sessao: cf674fc8-85f5-4655-8858-6ef9316fc272
data: 2026-08-16 01:20
gate: "Sem interface (`E2E_CMD` vazio em `.sdd/config.sh:7`, sem `APP_URL`, `docs/qa/` inexistente): a evidência da jornada é esta, e não um relatório datado. Três jornadas de CLI andadas à mão num repo-fixture próprio (`/tmp/qa-walk`, `SDD_STATE_DIR` isolado, stub de `claude` que marca o disco quando é chamado), cada uma rodada DUAS vezes — no `bin/sdd` de `HEAD` e no de `fdf8708` (pré-missão) — porque jornada que não fica vermelha sobre o bug não mede nada. **J1 Jidoka** `sdd run` com incremento `blocked` no topo de um checkpoint de 1,1 MB: HEAD → `rc 3`, `The line stopped on purpose`, **0** chamadas ao stub; `fdf8708` → `rc 3` mas **2** sessões queimadas e **0** ocorrências de `The line stopped on purpose` (escalou por orçamento, não por Jidoka). **J2 degradação** `sdd run` com `REVIEW_MAX_ITER=1` + `PUBLISH_ON_REVIEW_BLOCKED=draft` e stub que move o disco uma vez: HEAD → journal `DEGRADED  REVIEW  PUBLISH_ON_REVIEW_BLOCKED=draft, PR in draft mode` + **1** linha `event:\"degraded\" kind:\"review-to-draft\"`, run segue para PR; `fdf8708` → **0** linhas `DEGRADED` no journal e **0** linhas `degraded` no ledger (o evento era invisível). **J3 dois leitores** ledger de 10 linhas com escaladas em dois `kit_sha`, uma de kit sujo e uma de sha nulo: HEAD → `sdd autonomy` imprime `aaaaaaa budget-exhausted: 1 / aaaaaaa increment-blocked: 1 / bbbbbbb budget-exhausted: 1 / bbbbbbb review-to-draft: 1`, `(2 non-comparable row(s) excluded)`, e bate campo a campo com `.latest.escalations` de `sdd kaizen --series` (`excluded.unrecognized: 0`); `fdf8708` → `budget-exhausted: 4` sem eixo nenhum e `(1 unrecognized row(s) excluded)` — a linha `review-to-draft` que o próprio runner escreveu. `TEST_CMD` (`./tests/run-all.sh`) → rc 0, `suite green`, `score: 28 caught, 0 known gap(s), of 28`, 56,71 s. Achado confirmado na J2 sob stub que move o disco a cada sessão: 1 degradação → **3** linhas `degraded` (métrica 3 do `00-missao.md` exige exatamente uma) → vira o incremento `F1`, `pending` no `checkpoint.md`."
---

# Handoff — QA — o ledger e o Jidoka param de mentir

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

3 jornadas de CLI andadas (não há navegador neste repo), cada uma contra o runner de hoje **e** o
de antes da missão: as três ficaram vermelhas sobre o bug e verdes depois — os três consertos
entregam o que prometem. 1 achado confirmado, e ele é da própria missão: uma degradação escreve
**3** linhas `degraded` quando o run gira, contra a "exatamente uma" da métrica 3 → virou o
incremento **`F1`** (`pending`). 0 itens para julgamento humano novos. 2 achados fora de escopo no
`TODO.md`. Suíte verde, 28/28.

## Estado do repo

- **Branch:** `missao/20260815-ledger-sem-ponto-cego` — nunca empurrada; `origin` não conhece este
  trabalho.
- **Último commit:** `4c087f3` `chore(checkpoint): I3 done em e9a74aa, e o handoff de EXEC fecha a missão`
  (mais o commit que fecha esta sessão de QA).
- **Working tree:** limpo. Nenhuma linha de produção tocada por esta sessão — QA não conserta.
- **Suíte:** `./tests/run-all.sh` → **verde**, `score: 28 caught, 0 known gap(s), of 28`,
  `KNOWN_GAPS` vazio, **56,71 s**.
- **E2E:** `E2E_CMD` vazio — repo de bash + markdown, sem jornada de navegador. As jornadas são de
  linha de comando e foram andadas à mão; a evidência está no `gate:` acima.

## O que foi feito

Nenhum commit de produção — o trabalho desta fase é medir e instrumentar.

- (este commit) — `checkpoint.md`: incremento **`F1`** `pending` + 6 notas de execução com o
  número medido e a direção sugerida; `TODO.md`: 1 achado novo e 1 entrada narrowed;
  `30-handoff-qa.md`.

### Como as jornadas foram andadas

Um repo-fixture **próprio**, montado do zero em `/tmp/qa-walk` — deliberadamente **não** o fixture
da suíte. Sensor e teste com o mesmo autor compartilham a mesma suposição, e este repo já pagou
três bugs de gate por isso (`CLAUDE.md`, seção "TDD aqui dentro"). `SDD_STATE_DIR` apontado para
um diretório descartável, para que nenhuma jornada escrevesse no ledger real de `~/.sdd/`.

O stub de `claude` **marca o disco a cada chamada**, então "não gastou sessão" vira contagem e não
impressão. As jornadas rodaram duas vezes cada, contra `HEAD` e contra `fdf8708` (o `bin/sdd`
imediatamente anterior à missão, extraído por `git show`).

## Artefatos

| Arquivo | O que contém |
|---|---|
| `docs/handoffs/20260815-ledger-sem-ponto-cego/30-handoff-qa.md` | Este handoff; o `gate:` carrega a evidência das 3 jornadas (é ele que o runner mede nesta fase) |
| `docs/handoffs/20260815-ledger-sem-ponto-cego/checkpoint.md` | O incremento `F1` `pending` e as notas que dizem de qual jornada ele nasceu, o número medido e por que é I2 e não escopo novo |
| `TODO.md` | 1 achado novo (posição × tamanho no fixture do Jidoka) e a entrada da auto-degradação repetida narrowed para a metade que sobra |

**Nenhum spec e2e novo:** este repo não tem `E2E_DIR` nem `E2E_CMD`, e o achado não é de jornada de
navegador. Pelo critério de "onde o defeito mora, não onde foi achado", o sensor do `F1` é um teste
da suíte `TEST_CMD` (`tests/check-autonomy.sh` + mutante em `tests/check-mutation.sh`), e é isso que
o Check do `F1` exige.

## Boot da próxima fase

A próxima fase é **EXEC**, não REVIEW: há um incremento `pending` no `checkpoint.md`, e
`current_phase()` (`bin/sdd:476`) devolve a primeira fase cujo gate não fecha — `gate_EXEC` vem
antes de `gate_QA`. Esse é o laço QA⇄EXEC funcionando, não um erro de roteamento.

**Leia primeiro:** as 6 notas de `F1` no `checkpoint.md` — elas têm o número medido, a razão de
escopo e a direção sugerida. Depois `tests/check-autonomy.sh:331-400` (o bloco da degradação) e
`bin/sdd:1536-1548` (o ramo `draft`).

**Como reproduzir o defeito em ~40 s**, sem tocar no ledger real: repo-fixture com PLAN/TICKET/EXEC/QA
satisfeitos, `.sdd/config.sh` com `REVIEW_MAX_ITER=1` e `PUBLISH_ON_REVIEW_BLOCKED="draft"`,
`SDD_STATE_DIR` num diretório descartável, e um stub de `claude` que **commita algo a cada
chamada** (o fingerprint é `HEAD` + lista do dir da missão + md5 do checkpoint, `bin/sdd:965` — um
`git commit` sem nada a commitar não move nada, e o run morre por `no-progress` antes de chegar ao
ramo). Sequência esperada de fases: `REVIEW PR PR`, com o aviso `moving on to PR in draft mode`
impresso 3 vezes.

⚠️ **O sensor do `F1` tem de rodar no regime de repetição.** O fixture de hoje usa um stub que move
o disco **na primeira chamada só**, e por isso a asserção `"the degradation wrote exactly one row"`
(`tests/check-autonomy.sh:390`) fica verde afirmando uma propriedade que o fixture garante, não o
código. Sob o stub que move sempre, a mesma asserção lê 3. Se o sensor novo nascer no fixture
antigo, ele troca uma vacuidade por outra — e esta seria a **terceira** desta missão, depois do
`rc 3` compartilhado do I1 e do ramo `draft` nunca alcançado do I2.

⚠️ **Não rode a suíte com `SDD_MUTANT` exportado no shell** — é o mecanismo anti-recursão do
`check-mutation.sh`, e exportá-la pula linter e mutação da suíte inteira.

## Pendências / Decisions for a Human

> Só julgamento humano genuíno. **Não bloqueiam o pipeline** — viram seção do PR.

Nenhuma **nova** nesta fase. As duas que já existiam seguem abertas e são do humano, não do
pipeline — repetidas aqui só para o PR conseguir citar:

- **Vocabulário do evento de degradação** — `event: "degraded"` + `kind: "review-to-draft"` foi o
  implementado; a alternativa barata era reusar `event: "blocked"` com um `kind` novo. Andando a
  J2 eu vi o argumento do plano se sustentar na prática: o run **continua** para PR e termina numa
  escalada `no-progress` **de outra fase**, então `blocked` gravaria "parou" para um run que foi
  adiante. Se o humano preferir a alternativa mesmo assim, é um valor de campo e as asserções.
  Ver `00-missao.md` § "Pendências para o humano" e `bin/sdd:840`.
- **Alvo de tempo da suíte** — a D7 do `CONTEXT.md` fixou "<30 s"; medi **56,71 s** nesta sessão
  (baseline da missão: 37,4 s em máquina descarregada; 59,4 s no fim do EXEC). O `F1` acrescenta um
  29º mutante e vai piorar o número de novo. Subir `SDD_MUTATION_JOBS`, subir o alvo, ou aceitar —
  registrado no `TODO.md`, não decidido aqui.

## Riscos e não-feitos

- **As jornadas rodaram com `claude` stubado, como toda evidência desta missão.** Nenhum `sdd run`
  real de ponta a ponta com sessão paga. É a mesma limitação que o maior item aberto do `TODO.md`
  descreve (o preflight headless nunca executa `TEST_CMD` de verdade) e não é regressão desta
  missão — mas significa que o que eu medi é o **runner**, não o comportamento dos agentes.
- **Não andei a jornada do `sdd kaizen` completo** (o juiz escrevendo veredito), só o
  `--series` que os dois leitores expõem. O `gate_KAIZEN` está fora do diff desta missão.
- **A J3 usou `kit_sha` inventados** (`aaaaaaa`/`bbbbbbb`) para forçar duas versões no mesmo
  ledger. A atribuição ao sha **real** foi verificada separadamente na J2, cujo ledger nasceu do
  runner e saiu carimbado com `4c087f3` nos dois leitores.
- **A divergência latente entre `comparable` (`.kit_dirty == false`) e `on_axis`/série
  (`.kit_dirty != true`) foi verificada, não apenas herdada do EXEC:** `autonomy_kit_stamp`
  (`bin/sdd:751-767`) só produz `kit_dirty: null` junto com `kit_sha: null`, e o sha nulo já
  reprova nos dois lados. Não é alcançável pelo runner — só por edição à mão. Continua no
  `TODO.md` como está, corretamente.
- **O `F1` fecha a metade de registro, não a de laço.** Depois dele o ledger dirá "degradou uma
  vez"; o runner vai continuar girando REVIEW→PR→REVIEW com o orçamento estourado até o
  `no-progress` do PR encerrar. São dois defeitos e o `TODO.md` agora diz qual deles sobra.

## Achados fora de escopo

> Registrados no `TODO.md`. Aqui fica só o ponteiro, para o PR conseguir citar.

- O que arma a corrida do Jidoka é a **posição** da linha `blocked`, não o tamanho do checkpoint —
  com ela no fim de um checkpoint de 1,1 MB o `bin/sdd` pré-conserto para **corretamente**. O
  fixture está certo por construção e o mutante `RUN_jidoka_pipefail` segura a invariante; é
  precisão de comentário, não defeito vivo → `TODO.md`
- Auto-degradação repetida no mesmo `sdd run`: a metade de **registro** virou `F1`; a de **laço**
  segue aberta e a entrada foi narrowed para dizer só isso → `TODO.md`
