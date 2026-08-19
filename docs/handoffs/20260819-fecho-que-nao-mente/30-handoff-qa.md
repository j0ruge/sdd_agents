---
missao: 20260819-fecho-que-nao-mente
fase: QA
status: done
sessao: 9237fec0-dd30-4523-bd7c-2f92b6ef3d65
data: 2026-08-19 16:48
gate: "Projeto SEM interface (`E2E_CMD=\"\"`, sem `APP_URL`): as jornadas foram andadas no terminal por esta sessão. (1) `./bin/sdd health` sobre a árvore limpa de `1a96054`, 30 min, rc 0 → `ok mutation: score: 110 caught, 0 known gap(s), of 110`, `ok TEST_CMD runs the suite (tests/run-all.sh)`, `ok mutation stamp written`, `ok kit healthy` — é o FECHO da métrica do `00-missao.md` (`caught == of`, `N = 110 >= 108`, partida 104). Log em `/tmp/qa-health.log`. (2) `tests/run-all.sh --list` → 14 linhas, todas passos, nenhuma `(linter absent — skipped)`, rc 0. (3) `./bin/sdd status 20260819-fecho-que-nao-mente` → 4/4 incrementos `done`, EXEC verde. (4) `./bin/sdd why 20260819-fecho-que-nao-mente PR` → `missing 50-pr.md`, o requisito do carimbo é o ÚLTIMO da fila e por isso só fala na fase PR. (5) `tests/run-all.sh` → `suite green`, rc 0, 1m22s, 562 asserções, com as quatro da métrica presentes ancoradas em `^  ok    `. Carimbo gravado e conferido igual à chave de conteúdo: `0575d68c35e92748ceab5f671c8e102d`."
---

# Handoff — QA — O caminho que certifica o fecho de uma missão para de afirmar o que não mediu

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

Cinco jornadas andadas no terminal (não há navegador neste projeto); **a métrica da missão fechou**
— `score: 110 caught, 0 known gap(s), of 110`, `kit healthy`. Dez achados confirmados: **três
viraram incremento de fix** (`F1`/`F2`/`F3`, todos defeitos DENTRO do diff desta missão, todos da
classe que a missão existe para acabar), **sete viraram item do `TODO.md`**, e **nenhum** exige
julgamento humano. A próxima fase é EXEC, não REVIEW: há incremento `pending`.

## Estado do repo

- **Branch:** `fix/fecho-que-nao-mente` — sem upstream; nada empurrado (é da fase PR).
- **Último commit:** o desta fase (`docs(qa)`), sobre `1a96054`.
- **Working tree:** limpo.
- **Suíte:** `tests/run-all.sh` → **verde**, rc 0, **1m22s**, 562 asserções `ok`.
- **E2E:** `E2E_CMD=""` — o kit não tem interface. `n/a` por configuração, não por omissão; por
  isso a evidência da jornada mora no `gate:` acima, que é o que o `gate_QA` mede
  (`bin/sdd:460-465`).
- **Catálogo de mutação:** rodado ponta a ponta NESTA sessão, 30 min, `110 caught of 110`.
  ⚠️ O carimbo que ele gravou **já está velho**: o commit desta fase mexe em
  `tests/health-baseline.txt`. Ver "Riscos".

## O que foi feito

Esta fase não conserta produção (contrato do `sdd-qa`): ela anda jornada, converte achado em
sensor, e devolve o bug sanável como incremento.

- **A métrica da missão foi fechada.** `./bin/sdd health` levou 30 min e respondeu
  `score: 110 caught, 0 known gap(s), of 110` + `kit healthy`. ⚠️ A rodada que o EXEC disparou em
  background **tinha morrido** — `/tmp/sdd-health-final.log` tem só o cabeçalho, sem linha
  `score:`. O risco que o handoff do EXEC declarou ("não foi visto verde ponta a ponta") era real,
  e foi pago aqui.
- **Três incrementos de fix** no `checkpoint.md`, com reprodução, mutante sugerido e a jornada que
  cada um tem de re-andar. Detalhe nas notas do checkpoint e na seção "Incrementos de fix (QA)".
- **Sete achados** no `TODO.md`, catraca `todo-findings` movida de **76 para 83** no mesmo commit,
  como o `CLAUDE.md` exige.

## Artefatos

| Arquivo | O que contém |
|---|---|
| `docs/handoffs/20260819-fecho-que-nao-mente/30-handoff-qa.md` | Este handoff; o `gate:` carrega a evidência das cinco jornadas. |
| `docs/handoffs/20260819-fecho-que-nao-mente/checkpoint.md` | `F1`/`F2`/`F3` `pending` + 6 notas novas com as reproduções verbatim. |
| `TODO.md` | Sete achados novos, três em § Sensores que faltam e quatro em § Contrato e configuração. |
| `tests/health-baseline.txt` | `todo-findings` 76 → 83. |

## Boot da próxima fase

**A próxima fase é EXEC, não REVIEW.** O `checkpoint.md` tem três incrementos `pending`, então o
`gate_EXEC` reprova e o runner re-deriva EXEC — é o laço QA⇄EXEC funcionando, com `QA_MAX_ITER=3`.

Ordem sugerida e **não** arbitrária: **F1 → F3 → F2**. O `F1` é o único que faz um instrumento
afirmar verde sobre nada, e enquanto ele estiver de pé qualquer carimbo novo vale menos do que diz.

Para quem pegar qualquer um dos três:

```
bash tests/check-health.sh      # F1
bash tests/check-gates.sh       # F2 e F3
./bin/sdd health                # 20 a 50 min — o fecho, e o carimbo do gate_PR
```

⚠️ **Rode `./bin/sdd health` depois do ÚLTIMO commit de código, nunca antes.** O carimbo chaveia no
conteúdo de `bin/ tests/ templates/ config/`; os três fixes tocam os dois primeiros. `CLAUDE.md`,
`docs/` e `TODO.md` não invalidam — mas `tests/health-baseline.txt` **invalida**, e é onde a
catraca do backlog mora (achado registrado, § Contrato e configuração).

Se o `gate_PR` reprovar com `no green mutation catalogue for this content`, o I4 está funcionando.

**Para a REVIEW, quando chegar a vez dela:** os três `F` são exatamente o material de uma rodada de
review, já reproduzidos; o que esta fase **não** fez foi a passada adversarial de sabotagem sobre
as asserções que ainda não existem (elas nascem com os fixes). Os candidatos que investiguei e
**descartei com motivo** estão na última nota do `checkpoint.md` — não vale re-persegui-los.

## Pendências / Decisions for a Human

> Só julgamento humano genuíno. **Não bloqueiam o pipeline.**

Nenhuma nova nasceu nesta fase — os dez achados têm causa técnica clara e nenhum depende de decisão
de produto. As três que já existiam continuam de pé e seguem para o PR:

- **A convenção do `RESOLVIDO por` × a catraca do backlog.** Esta missão segue o cabeçalho escrito
  do `TODO.md`; a missão passada apagou na hora (`6136d39`). — `TODO.md`, § Contrato e configuração.
- **CI rodando `tests/run-all.sh --with-mutation`.** Decisão de custo. Esta sessão mediu o número
  que falta para decidir: **30 min** por rodada, 110 mutantes. — `00-missao.md` § Fora de escopo.
- **As três decisões de desenho que nasceram sem humano** (carimbo em vez de CI; escopo por
  artefato; chave no conteúdo). ⚠️ O `F2` é uma consequência medida da terceira e **não** a
  revoga — só exige que escritor e leitor concordem na árvore. — `00-missao.md` § Decisões do grill.

## Riscos e não-feitos

- **O carimbo ganho nesta sessão morre no commit desta sessão, e isso é esperado.** Bumpar
  `tests/health-baseline.txt` de 76 para 83 invalida `0575d68c35e92748ceab5f671c8e102d`. Era
  inevitável em qualquer ordem: os três fixes tocam `bin/` e `tests/` de todo jeito. O que isto
  revela — que cumprir o princípio 5 custa uma rodada de catálogo — virou achado.
- **Nenhum spec e2e foi escrito, e é por construção**, não por omissão: `E2E_CMD=""`. Pela regra do
  `sdd-qa`, achado que não é de jornada de navegador vira asserção da suíte do `TEST_CMD` — e é
  isso que os Checks de `F1`/`F2`/`F3` cobram, cada um ancorado em `^  ok    ` numa asserção nova.
- **Os três `F` estão reproduzidos, mas nenhum está consertado nem tem sensor ainda.** Enquanto os
  Checks estiverem `pending`, as asserções que eles nomeiam **não existem** no repo: o nome é o
  contrato que o executor tem de honrar, exatamente como o `01-plano.md` fez com o I1–I4.
- **Não medi o `F2` ponta a ponta numa worktree de verdade.** A divergência
  `$SDD_HOME` × `$REPO_ROOT` está provada por leitura (`bin/sdd:2063` × `bin/sdd:712-715`) e o
  `README.md:30` documenta o instalador que a torna alcançável; montar a worktree, mexer no `PATH`
  e rodar o catálogo lá custaria mais 30 min e não mudaria o conserto. Declarado, não vendido como
  medido.
- **O `gate_REVIEW` e o `gate_QA` compartilham a regra de placeholder, e só um a tem.** O achado do
  `gate_QA` ficou no `TODO.md` e **não** virou `F`, porque o `gate_QA` não é um dos quatro
  instrumentos do `00-missao.md` — é fora de escopo por artefato, não por conveniência.
- **A suíte:** 1m22s nesta medição, contra 1m50s registrado pelo EXEC. A diferença é contenção de
  CPU, não melhoria: a medição do EXEC dividia os cores com o catálogo. Nada vai para o `TODO.md`.
- ⚠️ **Uma árvore `docs/qa/` inteira apareceu no meio desta fase e foi REMOVIDA.** Scaffold
  completo (`README.md`, `personas.md`, `templates/`, `journeys/` com mermaid citando esta missão)
  mais duas linhas acrescentadas ao `.gitignore`, nascidos entre 16:46 e 16:49 sem hook algum
  configurado. Neste projeto `E2E_CMD=""`, e o contrato do `sdd-qa` é explícito: sem interface a
  árvore `docs/qa/` **não existe e não se cria** — a evidência da jornada mora no `gate:` deste
  handoff. Estava untracked, então nada entrou no diff; o `.gitignore` foi revertido e a árvore
  apagada, e o `git status` fechou limpo. Quem vir isso reaparecer: apague de novo, não commite.
  Não virou item do `TODO.md` porque a origem está fora do kit (nenhum arquivo do repo a gera).

## Achados fora de escopo

> Registrados no `TODO.md` deste repo (é o kit). Aqui fica só o ponteiro, para o PR conseguir citar.

- O `gate_QA` compra o placeholder do próprio `templates/handoff.md` como evidência de jornada — o
  defeito do I3 vivo um gate adiante → `TODO.md` (§ Sensores que faltam).
- Colons de alinhamento GFM na linha separadora reprovam o `gate_REVIEW` com um motivo que não
  nomeia critério — anterior ao I3 → `TODO.md` (§ Sensores que faltam).
- O ramo de forma do `score:` não tem asserção nem mutante, e `grep -m1` lê a primeira linha
  quando a autoritativa é a última → `TODO.md` (§ Sensores que faltam).
- A catraca do backlog e o carimbo colidem em toda missão → `TODO.md` (§ Contrato e configuração).
- `TEST_CMD` com TAB antes de `--list` passa pela regra do `case`, e o `eval` entrega a flag →
  `TODO.md` (§ Contrato e configuração).
- Lixo ignorado pelo git dentro dos quatro diretórios move a chave do carimbo → `TODO.md`
  (§ Contrato e configuração).
- O exemplar do `agents/sdd-reviewer.md` é um artefato que o gate recusa nas oito linhas, e a
  âncora `templates/review.md:37-44` apodreceu no mesmo commit → `TODO.md` (§ Contrato e
  configuração).
