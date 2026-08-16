---
missao: 20260816-kit-como-alvo
fase: QA
status: done
sessao: 4efebde8-eea3-4753-a633-11eb25d5f29a
data: 2026-08-16 18:20
gate: "Projeto SEM interface (`E2E_CMD` vazio, sem `APP_URL`): as quatro jornadas de CLI foram caminhadas nesta sessão, cada uma como diferencial contra o runner de `df18c88`. (1) `SDD_STATE_DIR=<fixture> sdd autonomy` num ledger de dois repos → antes `2783b8e  3 session(s) · 2 stalled · 66% waste · 2 mission(s) · US$ 10.08`; depois `1 session(s) · 0 stalled · 0% waste · 1 mission(s) · US$ 3.36` mais `(2 row(s) excluded: born in another repo)` — é literalmente o defeito citado no `00-missao.md` deixando de ser reproduzível. `kaizen --series` fora de repo git: `warn` + série vazia, `sufficient:false`, `other_repo:9`. (2) `sdd preflight` com um byte alterado em `.claude/agents/sdd-qa.md` → `fail  agent sdd-qa.md stale — ... Run 'sdd install --force'`; no repo real, `ok   7 kit agent(s) checked`. (3) `sdd run 20260816-kit-como-alvo --dry-run` na branch base, runner da missão → `warn  you are on the base branch (main)` na **stderr sozinha**, `rc=0`; com o runner de `main`, nenhuma ocorrência, `rc=0`. `sdd kaizen` (claude stubado, ledger isolado) avisa antes da sessão. (4) `bin/sdd` real com um fragmento acrescentado depois do entry point → guardado executa o fragmento **0×**, a forma nua (sem chaves e sem `exit`) executa **1×** com `rc=0`. Suíte: `bash tests/run-all.sh` → `suite green`, rc `0`, `score: 44 caught, 0 known gap(s), of 44`. 1 achado confirmado (`BUG-qa-01`) virou o incremento `F1`, `pending` no checkpoint."
---

# Handoff — QA — quando o kit é o próprio alvo, quatro instrumentos param de afirmar o que nunca mediram

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

Quatro jornadas de CLI caminhadas, todas as quatro passam — e cada uma foi medida **contra o
runner de antes**, não contra a minha expectativa. 1 achado confirmado: o Check do próprio
`checkpoint.md` devolve `1` com a asserção **vermelha**, isto é, o quinto instrumento da família
que esta missão existe para matar estava dentro da métrica dela. Virou `F1` (`pending`) — a bola
volta ao `sdd-executor`. Nenhum sensor foi commitado por mim: vermelho no `run-all.sh` trancaria
`gate_QA`, que roda `TEST_CMD`.

## Estado do repo

- **Branch:** `missao/20260816-kit-como-alvo` — local, sem `origin` (o push é da fase PR).
- **Último commit:** `31c2e43` `docs(handoff): EXEC concluído — 4/4 incrementos, mutação 44/44`
- **Working tree:** limpo antes desta sessão; agora com `checkpoint.md` (linha `F1` + 4 notas) e
  este handoff, commitados ao fim dela.
- **Suíte:** `tests/run-all.sh` → **verde**, rc `0`, `score: 44 caught, 0 known gap(s), of 44`.
- **E2E:** `E2E_CMD=""` — **o kit não tem interface**. Não foi omissão: é o regime sem interface,
  e a prova das jornadas é o `gate:` deste arquivo (`gate_QA` mede exatamente esse campo).
  A árvore `docs/qa/` **não existe e não foi criada** — ela pertence às skills
  `qa-report`/`qa-execution`, que não rodam neste regime.

## O que foi feito

Nenhum commit de código: a QA não conserta produção. O que esta sessão produziu foi **medição**,
mais um incremento de fix e este handoff.

- *(sem hash)* — **Quatro jornadas caminhadas**, cada uma como diferencial contra `df18c88`.
  O detalhe está no `gate:` acima, número a número.
- *(sem hash)* — **`BUG-qa-01` confirmado e reproduzido** — ver "Achado confirmado" abaixo.
- `<hash do commit desta sessão>` — `F1` acrescentado ao `checkpoint.md` (`pending`), com quatro
  notas de execução registrando a medição, a forma do Check e por que o sensor não veio comigo.

## Achado confirmado — `BUG-qa-01` → `F1`

**O Check do `checkpoint.md` não distingue asserção verde de vermelha.**

Reproduzido numa cópia sandbox do repo, com o filtro do I2 sabotado
(`ledger_row_is_local` devolvendo `true`, o defeito de volta):

| | asserção imprime | Check de I2 devolve |
|---|---|---|
| repo intacto | `  ok    a row from another repo never enters the series` | `1` |
| filtro sabotado | `  FAIL  a row from another repo never enters the series` | `1` |

Causa: `pass()` escreve `  ok    <texto>` na **stdout**, `fail()` escreve `  FAIL  <texto>` na
**stderr** — mesmo `<texto>` —, e o Check captura `2>&1` e grepa o texto solto. A `Métrica` do
`00-missao.md` promete "a asserção aparece **e passa**"; o comando só sabe dizer "aparece".
Vale para os Checks de **I2, I3 e I4** (mesma forma). O de I1 lê `rc` e não tem o problema.

Conserto (é o `F1`): ancorar em `^  ok    `, e — a parte SDCA, que é a direção que o
`sdd-executor` já havia registrado no `TODO.md` — ensinar a regra ao `templates/checkpoint.md`
e ao agente `sdd-planner`, para que missão nenhuma volte a nascer com Check cego.
Medido: `grep -c 'exemplo'` → `2` contra `grep -c '^  ok    exemplo'` → `1`.

**Por que o sensor não veio commitado por mim.** `gate_QA` roda `TEST_CMD` como âncora final,
então um sensor vermelho no `run-all.sh` reprovaria a própria fase QA e o laço nunca chegaria ao
executor. O par sensor-vermelho + conserto tem de nascer no **mesmo** incremento, em TDD — que é
como I1–I4 nasceram. O laço funciona sozinho: `current_phase` devolve a primeira fase com gate
insatisfeito, `EXEC` vem antes de `QA`, e a linha `F1` `pending` reprova `gate_EXEC`.

## Artefatos

| Arquivo | O que contém |
|---|---|
| `docs/handoffs/20260816-kit-como-alvo/30-handoff-qa.md` | este handoff; o `gate:` é a prova das 4 jornadas |
| `docs/handoffs/20260816-kit-como-alvo/checkpoint.md` | linha `F1` `pending` + 4 notas de execução da QA |
| `TODO.md` | o item do Check cego já estava lá (registrado pelo EXEC); `F1` é quem o resolve |

Nenhum arquivo novo em `tests/` e nenhum toque em `bin/sdd` — logo `LINT_FLOOR` e o piso de
superfície do `check-pipefail.sh` ficam como estão, e o catálogo de mutação segue em 44.

## Boot da próxima fase

**A próxima fase é EXEC, não REVIEW** — `F1` está `pending`, e é isso que o runner vê.

Para o `sdd-executor`:

1. Leia a seção "Achado confirmado" acima e as 4 notas `QA` do `checkpoint.md` — a reprodução
   está lá pronta, não a redescubra.
2. TDD, na ordem: **o sensor primeiro, e veja-o vermelho** com os três Checks como estão hoje.
   O texto da asserção é contrato (o Check de `F1` o grepa, literal):
   `no checkpoint Check reads a red assertion as green`.
3. Só então ancore os Checks de I2/I3/I4 em `^  ok    ` e ensine a regra ao
   `templates/checkpoint.md` (que já tem o bloco ⚠️ sobre a célula do Check) e ao `sdd-planner`.
4. ⚠️ **Nada de `|` na célula do Check** — a regra de 2026-08-16 15:08 no checkpoint continua
   valendo, e o parser é `awk -F'|'` cru.
5. ⚠️ Sensor que mede markdown não é alcançado pelo catálogo de mutação (é a situação do
   `check-todo.sh`): ele carrega `selftest()` com probes e rc próprio, mais piso anti-vacuidade,
   e passa por sabotagem adversarial antes de ser considerado pronto — `CLAUDE.md`, seção TDD.
6. `Métrica` do `00-missao.md`: os quatro Checks continuam sendo citados lá. Ancorá-los **fortalece**
   a métrica (ela já diz "e passa"); não a reescreva para caber no comando fraco.

**Como subir o ambiente:** não há ambiente. `bash tests/run-all.sh` (~4 min, a maior parte é
mutação) e `bash bin/sdd health`. Sem rede, sem token.

⚠️ **Armadilha que me custou uma jornada inteira:** para caminhar a jornada da branch base eu fiz
`git checkout main` — e isso troca o `bin/sdd` junto, então eu estava medindo o runner **de antes**
e li "o aviso sumiu" como defeito. Não era. Ao caminhar qualquer jornada num sandbox, confira
**qual versão do runner** está no disco antes de acusar o produto (`grep -c warn_if_on_base_branch
bin/sdd`, por exemplo). O jeito certo está no `gate:`: ficar na base e trazer só `bin/sdd` da
branch da missão.

## Pendências / Decisions for a Human

> Só julgamento humano genuíno. **Não bloqueiam o pipeline** — viram seção do PR.

- **O eixo do juiz (`kit_sha` a cada linha) e a guarda das 3 missões.** Pede ADR e decisão
  humana. Enquanto não for decidido, todo veredito neste repo é `indeterminado` por construção.
  Ver `05-verdict.md` e `TODO.md`. Esta missão conserta os instrumentos que alimentam o juiz —
  e agora, com o filtro por repo, eles alimentam números **deste** repo —, nunca a régua dele.
- **A régua de tempo da suíte** (`CONTEXT.md:43`, D7, alvo "<30 s"). A suíte está em ~4 min com
  44 mutantes. `F1` não acrescenta mutante, mas acrescenta um sensor. Falta subir o alvo ou
  aceitar o estouro por escrito.
- **Confirmar a D11** (`event: "degraded"` próprio vs `blocked` com `kind` novo) — 🚩 aberta em
  `CONTEXT.md:41`, sem relação com esta missão.

## Riscos e não-feitos

- **O ramo de SUCESSO do preflight segue sem sensor** — declarado pelo EXEC e confirmado por mim:
  a jornada real imprime `ok   7 kit agent(s) checked`, mas nenhum fixture chega lá (é offline, e
  o probe do `claude` e o `gh auth status` reprovam antes). Está no `TODO.md`.
- **`repo` é caminho absoluto e o filtro compara string.** Conferi que leitor e escritor derivam do
  **mesmo** `$REPO_ROOT` (`ledger_repo_root` devolve `$REPO_ROOT` quando setado; os dois
  construtores gravam `--arg repo "$REPO_ROOT"`), então não há divergência interna. O risco que
  sobra é externo — repo movido ou symlink resolvido diferente entre execuções — e não foi
  exercitado.
- **Não caminhei `sdd kaizen` até a sessão real** (custa dinheiro): stubei o `claude` e isolei o
  `SDD_STATE_DIR`. O que ficou provado é que o aviso sai **antes** da sessão, que é onde ele serve.
- **Não exercitei o caso de o ledger ter linha sem o campo `repo`** — o EXEC mediu `0` em 26 linhas
  e decidiu por regra (linha que não sabe dizer de onde veio nunca é excluída). Aceitei a decisão;
  não a re-medi.
- **macOS continua sem nenhuma execução.** Pressuposto GNU userland, agora medido pelo preflight,
  nunca exercitado em CI.

## Achados fora de escopo

> Registrados no `TODO.md` deste repo (o kit é o alvo desta missão, então é o mesmo arquivo).
> Aqui fica só o ponteiro, para o PR conseguir citar.

- Check do checkpoint devolve `1` com a asserção vermelha → `TODO.md` (Aberto) — **deixa de ser
  fora de escopo: virou `F1`.** Quando o executor fechar, ele carimba `RESOLVIDO por <hash>` no
  item, e a linha só sai do arquivo depois do merge do PR que cita a evidência.
- Ramo de sucesso do preflight (`N kit agent(s) checked`) sem sensor → `TODO.md` (Aberto)
- `checkpoint_rows` (`bin/sdd`) faz `awk -F'|'` cru e não conhece `\|` do GFM → `TODO.md` (Aberto)
- Sensor de âncora podre do `check-todo.sh` → `TODO.md` (Aberto)
- Eixo do juiz / guarda das 3 missões → `TODO.md`, achado completo no `05-verdict.md`

**Nenhum destes entrou no diff.** Nenhum item novo foi acrescentado ao `TODO.md` nesta fase: o
único achado da QA é sanável e virou incremento, que é onde ele pertence.
