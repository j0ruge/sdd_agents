---
missao: 20260816-kit-como-alvo
fase: EXEC
status: done
sessao: 03340b61-5ce2-41a2-a503-e0e5a5af7249
data: 2026-08-16 19:10
gate: "`bash tests/run-all.sh` → `suite green`, rc `0`, `score: 44 caught, 0 known gap(s), of 44`; `sdd health` → `kit healthy` (suíte verde · mutação 44/44 · 8 gates com mutação · 3 fixtures com proveniência · 6 dívidas conhecidas, nenhuma nova). Os 5 Checks do checkpoint, rodados contra este HEAD: I1 `0`; I2/I3/I4 `1` cada, agora **ancorados em `^  ok    `** (antes do F1 devolviam `1` também com a asserção vermelha — medido pela QA); F1 `01`, isto é rc `0` da suíte MAIS a asserção `no checkpoint Check reads a red assertion as green` tendo rodado E passado (`grep -c '^  ok    no checkpoint Check reads a red assertion as green'` na saída → `1`). No HEAD do plano os quatro primeiros eram `127`, `0`, `0`, `0` e o F1 era `00`."
---

# Handoff — EXEC — quando o kit é o próprio alvo, quatro instrumentos param de afirmar o que nunca mediram

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

Cinco incrementos `done`, um commit de código cada. Os quatro instrumentos que afirmavam ter
medido algo passaram a medir — entry point guardado, leitores do ledger filtrando por repo,
preflight comparando bytes, aviso de branch base nas três portas — e o **quinto**, achado pela QA,
era o Check desta própria tabela: ele devolvia `1` com a asserção vermelha. O `F1` o ancorou em
`^  ok    `, ensinou a regra ao template e ao `sdd-planner`, e criou
`tests/check-checkpoint.sh` para medi-la em todo checkpoint do repo. Suíte verde, mutação
**44/44 (100%)** (o F1 não acrescenta mutante: mede markdown, e sabotagem do `bin/sdd` não o
mataria). Nenhuma degradação foi declarada. A próxima fase é **REVIEW** — a QA já fechou.

## Estado do repo

- **Branch:** `missao/20260816-kit-como-alvo` — local, sem `origin` ainda (push é da fase PR).
- **Último commit:** `a91b65d` `chore(todo): item do Check cego carimbado com a evidência`
  (o commit de código do F1 é `a981fd9`)
- **Working tree:** limpo.
- **Suíte:** `tests/run-all.sh` → **verde**, rc `0`. **12** sensores (os dez de sempre mais o
  `check-entrypoint.sh` do I1 e o `check-checkpoint.sh` do F1) + lint
  (`shellcheck -S warning bin/sdd tests/*.sh`) + `bash -n` + dry-runs. Mutação:
  `score: 44 caught, 0 known gap(s), of 44`.
- **E2E:** `E2E_CMD=""` no `.sdd/config.sh` — **o kit não tem interface**. Não rodou porque não
  existe, e isso não é uma omissão: é o regime "projeto sem interface" que a fase QA já trata
  (ver § Boot da próxima fase).

## O que foi feito

- `bb373b5` — **I1: o entry point deixa de poder cair de volta em si mesmo.** `main "$@"` era a
  última linha nua do `bin/sdd`; ao retornar dela o bash volta a ler o arquivo pelo offset salvo, e
  a fase EXEC edita o `bin/sdd` DURANTE o `sdd run` que a executa. Virou `{ main "$@"; exit $?; }`.
  Sensor novo `tests/check-entrypoint.sh`, **diferencial** (duas cópias de um script de brinquedo
  que crescem in-place, guardada × não-guardada, execuções contadas e comparadas entre si).
- `d99a7fc` — **I2: o ledger é global, os leitores deixam de ser.** Predicado único
  `ledger_row_is_local`, usado por `cmd_autonomy`, `kaizen_series` e o lembrete pós-pipeline. O
  campo `repo` já era escrito e ninguém o lia — um `sdd run` de fixture em `/tmp` movia os números
  que o juiz cita. Asserções diferenciais em `check-kaizen.sh` e `check-autonomy.sh` (um ledger de
  dois repos, lido de dois repos, saídas comparadas entre si). `docs/pipeline.md` e `sdd help`
  aprenderam o filtro no mesmo commit.
- `ab64d2e` — **I3: a frase "N kit agent(s) checked" volta a ser verdade.** O preflight comparava
  a *existência* da cópia em `.claude/agents/`; agora compara bytes (`cmp -s`), com duas falhas em
  palavras diferentes — ausente (`not installed`) e divergente (`stale`). Asserção diferencial de
  contagem em `check-preflight.sh`: a mesma árvore lida duas vezes, um byte de diferença,
  `N check(s) failed` exatamente +1.
- `daa8687` — **I4: o aviso de branch base alcança as três portas que commitam.**
  `warn_if_on_base_branch()`, uma definição chamada por `cmd_preflight`, `cmd_run` e `cmd_kaizen`.
  Continua `warn` e nunca `die`. Três asserções diferenciais (mesma árvore, um checkout de
  distância) em `check-gates.sh`, `check-kaizen.sh` e `check-preflight.sh`; a do `check-gates.sh`
  lê a **stderr sozinha**, para medir presença e severidade de uma vez.

- `a981fd9` — **F1: o Check do checkpoint para de ler asserção vermelha como verde.** Achado e
  reproduzido pela fase QA (`BUG-qa-01`): `pass()` escreve `  ok    <texto>` na stdout, `fail()`
  escreve `  FAIL  <texto>` na stderr com o **mesmo** texto, e os Checks de I2/I3/I4 capturavam
  `2>&1` e grepavam o texto solto — `1` nos dois casos. Os três passaram a ancorar em
  `^  ok    `; `templates/checkpoint.md` e `agents/sdd-planner.md` ensinam a regra; e
  `tests/check-checkpoint.sh` (novo) a mede em todo checkpoint do repo, com `selftest()` de 22
  probes, rc 90/91/92 e quatro pisos anti-vacuidade. `CLAUDE.md` aprendeu no mesmo commit.
  Acompanha `a91b65d`, que carimba `RESOLVIDO por a981fd9` no item do `TODO.md`.

Os commits de checkpoint que os acompanham: `4f6181c`, `815e8bb`, `27bdeae`, `82dbb0d` e o desta
sessão.

## Artefatos

| Arquivo | O que contém |
|---|---|
| `docs/handoffs/20260816-kit-como-alvo/00-missao.md` | intenção, métrica e o gate PLAN-AUTO com evidência |
| `docs/handoffs/20260816-kit-como-alvo/01-plano.md` | contexto verificado, os 4 incrementos e os riscos |
| `docs/handoffs/20260816-kit-como-alvo/checkpoint.md` | tabela 4/4 `done` + **21 notas de execução** — é onde mora o detalhe caro |
| `bin/sdd` | entry point guardado, `ledger_row_is_local`, `cmp -s` do preflight, `warn_if_on_base_branch` |
| `tests/check-entrypoint.sh` | sensor novo (I1), diferencial, com auto-teste de forma |
| `tests/check-checkpoint.sh` | sensor novo (F1), mede a coluna Check de todo checkpoint; `--selftest`, `--check`, `--scan`, `--calibrate` |
| `templates/checkpoint.md` · `agents/sdd-planner.md` | a regra do âncora `^  ok    `, para a missão que ainda não nasceu |
| `tests/check-gates.sh` · `check-kaizen.sh` · `check-preflight.sh` · `check-autonomy.sh` | asserções novas de I2/I3/I4 |
| `tests/check-mutation.sh` | 4 mutantes novos: `RUN_entrypoint_unguarded`, `RUN_ledger_no_repo_filter`, `PRE_agent_presence_only`, `RUN_base_branch_warn_dead` |

## Boot da próxima fase

**REVIEW — a QA já fechou** (`30-handoff-qa.md`, 4 jornadas caminhadas, 1 achado confirmado que
virou o `F1` e está `done`). O `sdd status` confirma: `next phase: REVIEW`. Este é um projeto
SEM interface (`E2E_CMD=""`, nenhum `APP_URL`), então não existe `docs/qa/` e não deve ser criada.

⚠️ **O que o revisor precisa saber antes de abrir o diff do `F1`:** o sensor novo mede markdown,
então o **catálogo de mutação não o alcança** — é a mesma situação do `check-todo.sh`, e a regra do
`CLAUDE.md` é a que foi seguida (`selftest()` com probes e rc próprios, mais piso anti-vacuidade,
mais passada de sabotagem adversarial). As 44 degradações e os quatro sobreviventes que viraram
probe estão nas notas do `checkpoint.md`; o único sobrevivente final está nomeado no rodapé do
`selftest()`. Se você for propor uma regra a mais, a régua da casa vale: regra que a sabotagem
não consegue quebrar é redundante — remova, não escreva probe para ela.

**Como subir o ambiente:** não há ambiente. `cd` no repo e rode `bash tests/run-all.sh`
(~4 min, a maior parte é mutação) e `bash bin/sdd health`. Nada de rede, nada de token.
Para exercitar só o sensor do `F1`: `bash tests/check-checkpoint.sh` (~1 s) e
`bash tests/check-checkpoint.sh --selftest`.

⚠️ **`.claude/agents/` não é editável pela sessão headless** — `cp` e editor batem em permissão.
Se você mexer em `agents/*.md`, sincronize com `bash bin/sdd install --force`, ou o `sdd preflight`
reprova com `stale` (comportamento que o I3 criou de propósito).

**O que no diff é visível para quem usa** — as quatro jornadas de CLI que mudaram, em ordem de
risco:

1. **`sdd kaizen --series` e `sdd autonomy` passaram a filtrar por repo.** ⚠️ Mudança de contrato
   deliberada: **`--series` não funciona mais "de qualquer diretório"** — fora de um repositório
   git devolve a série vazia com `warn`. Série vazia é `sufficient:false` e só sustenta
   `indeterminado`, que é a direção segura. Quem tiver ledger com linhas de outro repo vai ver
   **menos** dados do que ontem: é correção, não regressão.
2. **`sdd preflight` pode reprovar onde antes passava.** Cópia em `.claude/agents/` divergente da
   fonte agora falha com `agent <nome> stale — run 'sdd install'`. Vale a pena caminhar: edite um
   byte de um `.claude/agents/*.md` e confira que a mensagem diz o conserto.
3. **`sdd run` e `sdd kaizen` avisam quando você está na branch base.** É `warn`, nunca `die` — o
   comando segue. A regressão cara aqui seria virar erro: confirme que o `rc` não mudou.
4. **`bin/sdd` sempre sai por `exit`.** Invisível em uso normal; só aparece se o arquivo crescer
   durante a própria execução.
5. **O Check de qualquer checkpoint agora é medido.** Célula que faz `2>&1` **e** grepa tem de
   ancorar em `^  ok    `; célula com `|` reprova. Vale para os checkpoints das missões antigas
   também — os 23 estão limpos hoje. Quem escreve missão nova encontra a regra no
   `templates/checkpoint.md` e no `sdd-planner`.

**Comece por:** `git log --oneline 8ca54b8..HEAD`, depois as **notas de execução** do
`checkpoint.md` — elas registram três desvios do plano e as sabotagens que ficaram verdes, e são
mais úteis que o diff.

## Pendências / Decisions for a Human

- **O eixo do juiz (`kit_sha` a cada linha) e a guarda das 3 missões.** Está no `TODO.md` e no
  `05-verdict.md`. Enquanto não for decidido, todo veredito neste repo é `indeterminado` por
  construção — duas voltas já terminaram assim. **Não bloqueia esta missão**, e esta missão não
  o resolve: ela conserta os instrumentos que alimentam o juiz, não a régua dele.
- **A régua de tempo da suíte** (`CONTEXT.md:43`, D7, alvo "<30 s"). Esta missão levou o catálogo
  de 40 para 44 mutantes, e **cada mutante é uma suíte inteira**. O estouro cresceu por escolha
  registrada (não cortar mutação para ganhar tempo); falta subir o alvo ou aceitar o estouro por
  escrito.
- **Confirmar a D11** (`event: "degraded"` próprio vs `blocked` com `kind` novo) — 🚩 aberta em
  `CONTEXT.md:41`, sem relação com esta missão.

## Riscos e não-feitos

- **`repo` é caminho absoluto e o filtro compara string.** Symlink, `/tmp` resolvido diferente ou
  repo movido não casam, e as linhas antigas desaparecem da série daquele repo. Medido antes de
  decidir: `jq -c 'select(has("repo")|not)' ~/.sdd/autonomy-log.jsonl | wc -l` → `0` em 26 linhas.
  Nenhum `realpath` foi inventado no meio do incremento, por decisão do plano.
- **O ramo de SUCESSO do preflight segue sem sensor.** A asserção que o plano previa — exigir a
  ausência de `N kit agent(s) checked` — era **vácua** e por isso não foi escrita: a linha só sai
  com `fails -eq 0`, e o fixture é offline (o probe do `claude` e o `gh auth status` já reprovam),
  então ela não aparece em run nenhum. Trocada por um diferencial de contagem. Está no `TODO.md`.
- **RESOLVIDO — os Checks de I2/I3/I4 devolviam `1` com a asserção VERMELHA.** Era o risco
  declarado por esta fase, virou `BUG-qa-01` na QA e o incremento `F1` o fechou (`a981fd9`).
  Fica registrado porque é a prova de que o laço EXEC → QA → EXEC funcionou sem intervenção.
- **O que o `check-checkpoint.sh` NÃO mede, declarado e não escondido:** Check que lê sensor **sem**
  `2>&1` (já correto hoje, mas correto pela redireção que omite, não pelo âncora — acrescente
  `2>&1` por conveniência amanhã e ele fica cego até este sensor o ver); `grep` com padrão vindo de
  variável, ou escrito `egrep`/`rg`; e se o texto ancorado corresponde a uma asserção que existe
  (um âncora para frase que ninguém imprime devolve `0` em vez de `1` — resposta errada, verde
  nenhum, que é a direção barata). O header do arquivo repete os três.
- **A suíte ficou mais lenta**: ~4 min, contra ~3 antes dos 4 mutantes novos. O `F1` acrescenta
  ~1 s (o sensor mede markdown e não entra no pool de mutação).
- **Nenhum teste roda em macOS.** Continua sendo o pressuposto do kit (GNU userland), agora medido
  pelo preflight mas nunca exercitado em CI.

## Achados fora de escopo

> Registrados no `TODO.md` deste repo (o kit é o alvo desta missão, então é o mesmo arquivo).
> Aqui fica só o ponteiro, para o PR conseguir citar.

- Check do checkpoint devolve `1` mesmo com a asserção vermelha → **RESOLVIDO por `a981fd9`**;
  o item segue no `TODO.md` com o carimbo até o PR que cita a evidência ser mergeado
- Ramo de sucesso do preflight (`N kit agent(s) checked`) sem sensor → `TODO.md` (Aberto)
- `checkpoint_rows` (`bin/sdd`) faz `awk -F'|'` cru e não conhece `\|` do GFM → `TODO.md` (Aberto)
- Sensor de âncora podre do `check-todo.sh` (15 âncoras erradas em 11 itens; esta missão produziu
  mais uma evidência: `bin/sdd:2324` aponta para um arquivo que já tem 2400+ linhas) → `TODO.md`
- Eixo do juiz / guarda das 3 missões → `TODO.md`, com o achado completo no `05-verdict.md`

**Nenhum destes entrou no diff.**
