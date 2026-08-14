---
missao: 20260814-dry-run-completo
fase: QA
status: done
sessao: QA-20260814-033947
data: 2026-08-14 03:48
gate: "`tests/run-all.sh` → exit 0 · 118 asserções ok, 0 falhas. 5 jornadas andadas contra o CLI (J1 estado corrente → exit 0 projetando QA:close→REVIEW→DOCS→PR; J2 PLAN → exit 2, 0 fases, árvore intacta; J3 blocked → exit 3 com `pipeline.log` md5 idêntico — o achado da volta 1 CURADO; J4 `--phase REVIEW` → 1 fase; J5 pipeline completo → exit 0, `pipeline completo — falta só o merge`, a jornada que a volta 1 deixou inconclusiva). Registry sem bug aberto: `BUG-dryrun-pipelinelog` fechado por `f1c9f3f`, 0 `F<n>` novo. Sensor ampliado e validado por mutação: 3 mutações em `bin/sdd`, todas pegas. `E2E_CMD` vazio — sem navegador, o sensor da jornada é `TEST_CMD`."
---

# Handoff — QA — dry-run mostra o pipeline inteiro

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.
>
> **Duas voltas de QA.** Este handoff cobre as duas: a **1ª** (que achou o `BUG-dryrun-pipelinelog`,
> abriu o `F1` e fechou `blocked`) e a **2ª** (que re-andou as jornadas, confirmou a cura e fechou
> `done`). O registro da 1ª está preservado no fim, porque é a origem do `F1`.

## TL;DR

Re-andei as 5 jornadas do CLI: **o achado da volta 1 está curado** (J3 — a projeção não escreve
mais no diário da missão) e nenhum bug novo apareceu, então **nenhum `F<n>` novo**. Achei um
defeito de **sensor**, não de produção: `53cf63a` moveu o `pipeline.log` e deixou uma asserção
apontando para o caminho velho — decoração provada por mutação. Corrigi o sensor e cobri o
caminho **real** do diário, que nada exercitava. Suíte 118 verdes. Próxima fase é **REVIEW**.

## Estado do repo

- **Branch:** `missao/20260814-dry-run-completo` — local, sem remoto; push é da fase PR.
- **Último commit:** o desta sessão (sensor + checkpoint + TODO + este handoff).
- **Working tree:** limpo depois do commit.
- **Suíte:** `tests/run-all.sh` → **verde**, exit 0, **118 asserções ok / 0 falhas** (eram 104 ao
  fim do EXEC; `53cf63a` somou 8 e esta sessão somou 6).
- **E2E:** `E2E_CMD` vazio no `.sdd/config.sh` — o kit é bash + markdown, não há navegador. Não
  rodou por não existir. A jornada deste repo é alguém digitar `sdd` no terminal.

## Por que não há spec Playwright (e onde o sensor foi parar)

O contrato do `sdd-qa` manda achado confirmado de jornada virar spec e2e commitado. Aqui não há
`E2E_DIR` nem `E2E_CMD`: **o defeito vive no bash do runner, que é o domínio do `TEST_CMD`**. O
critério do próprio contrato é *onde o defeito mora*, não onde foi encontrado — então o sensor
desta jornada é `tests/check-dry-run.sh`, que roda em todo `tests/run-all.sh`. Mesma decisão da
volta 1, mantida.

Também não existe árvore `docs/qa/`, e isso está certo: `qa_substep` (`bin/sdd:463`) manda
projeto sem `E2E_CMD` e sem `APP_URL` direto ao sub-passo `close`, pulando as skills
`qa-report`/`qa-execution` que são as donas dessa árvore. Não houve sessão em persona antes desta:
a jornada fui eu que andei, e o registro dela é este handoff.

## Jornadas andadas (volta 2)

| # | Estado | Esperado | Obtido | Veredito |
|---|---|---|---|---|
| J1 | missão real, parada em `QA:close` | projeta as pendentes com agente e modelo | exit 0; `QA:close`→`REVIEW`→`DOCS`→`PR`, agentes e modelos corretos | ✅ |
| J2 | missão parada em PLAN | instrução interativa, exit 2, nada projetado, disco intacto | exit 2, **0** blocos projetados, árvore md5 idêntica | ✅ |
| J3 | missão com incremento `blocked` | escala exit 3 **sem tocar no disco** | exit 3, `pipeline.log` md5 **idêntico**, árvore idêntica | ✅ **curado** |
| J4 | `--phase REVIEW` + `--dry-run` | uma fase só | exit 0, exatamente 1 bloco | ✅ |
| J5 | missão completa (todos os gates ✅) | `pipeline completo` | exit 0, `pipeline completo — falta só o merge`, com a URL do PR | ✅ **novo** |

**J3 é a razão de existir desta volta** e está curado: o `f1c9f3f` guardou `pipeline_log_line`
inteira, não só o caminho que a volta 1 apontou.

**J5 fecha uma dívida da volta 1**, que a deu por inconclusiva ("não posso afirmar que
`pipeline completo` imprime certo") por erro de fixture — hash inventado reprovando `gate_EXEC`.
Montei o fixture com hash real e **stub de `gh`** no `PATH` (o `gate_PR` exige confirmação viva do
PR, que é o que tornava a jornada inandável offline). Os 7 gates passaram, `sdd phase` → `DONE`,
e a projeção imprimiu a mensagem certa sem tocar no disco. De quebra, isso validou
**end-to-end o contrato novo de `gate_QA`**: `jornada andada sem interface de browser (evidência
no handoff), suíte verde`.

## O achado desta volta — um sensor que virou decoração

**Não é bug de produção.** É defeito no instrumento, e por isso não virou `F<n>`: teste é meu
para consertar, produção não.

`53cf63a` moveu o diário de `docs/handoffs/<m>/pipeline.log` para `.sdd/logs/<m>/pipeline.log`
(decisão correta — na árvore commitada ele sujava o `git status` e derrubava `gate_REVIEW`). Mas
a asserção que era o Red do `F1` continuou apontando para o caminho velho:

```bash
assert_eq "projeção blocked não cria pipeline.log" "" \
  "$( [ -e "$MDIR/pipeline.log" ] && echo "pipeline.log criado" || true )"
```

O runner não escreve mais nesse caminho **em circunstância nenhuma**, então a asserção passou a
ser inviolável. Provei por mutação, reintroduzindo o bug do `F1` à mão: ela seguiu imprimindo
`ok`. Uma asserção que não pode falhar é indistinguível de uma que passa — o `ok` mentia.

O `F1` continuava protegido por acidente, pela asserção vizinha de árvore (`tree_snapshot` pega o
arquivo aparecendo). Mas `tree_snapshot` compara **nomes, não conteúdo**: numa missão que já rodou
de verdade, o `pipeline.log` já existe, e a projeção poderia **acrescentar** uma linha sem que
nenhuma asserção percebesse.

## O que ficou instrumentado

Duas coisas, em `tests/check-dry-run.sh`:

1. **A asserção do `F1` apontada para onde o runner escreve hoje**, e reforçada: além de "não
   cria", agora afirma **"não altera um `pipeline.log` preexistente"** (md5 antes × depois) — o
   furo que o `tree_snapshot` não cobria.
2. **Seção nova: "o caminho real (não-dry) ainda escreve no diário".** Todo sensor que existia
   afirmava que a projeção **não** escreve; nenhum afirmava que uma execução de verdade
   **escreve**. Inverter a guarda (`= "1"` → `!= "1"`) matava o diário da missão em silêncio com
   a suíte verde — o `sdd-executor` sinalizou isso e só conseguiu provar com um probe descartável,
   por achar que escrever de verdade exigiria uma `run_phase` (e portanto o `claude`). **Não
   exige:** o caminho de escalação `blocked` loga e retorna 3 **antes** de qualquer sessão. Dá
   para exercitar o caminho real sem gastar token nem rede.

**Validação por mutação — a prova de que os sensores mordem** (todas revertidas; `bin/sdd` intacto):

| Mutação em `bin/sdd` | O que simula | Resultado |
|---|---|---|
| guarda nunca dispara (`= "9"`) | o bug do `F1` de volta | **3 asserções vermelhas** |
| guarda invertida (`!= "1"`) | diário real morto, em silêncio | **4 asserções vermelhas** |
| `PIPELINE_LOG` de volta a `$MISSION_DIR` | diário sujando a árvore commitada | **4 asserções vermelhas** |

Antes desta sessão, a 2ª e a 3ª mutação **não eram pegas por nada**.

> A 1ª versão da minha própria seção nova dava `ok` sob a mutação B — porque a projeção
> (já rodada acima, e logando sob aquela mutação) tinha criado o arquivo, e o `[ -e ]` passava
> pelo motivo errado. Corrigido com um `rm -f` antes da execução real, o que torna a asserção
> causal em vez de circunstancial. Registro porque é exatamente o erro que este achado denuncia,
> e eu o cometi enquanto o consertava.

## O que foi feito

- `d161282` — sensor corrigido e ampliado (`tests/check-dry-run.sh`, +6 asserções),
  nota da volta 2 no `checkpoint.md`, 3 entradas do `TODO.md` fechadas e 1 nova aberta, e este
  handoff. **Nenhuma linha de `bin/sdd` foi tocada** — as mutações foram temporárias e revertidas
  (`git diff --name-only bin/sdd` vazio ao fim).

## Artefatos

| Arquivo | O que contém |
|---|---|
| `tests/check-dry-run.sh` | Asserção do `F1` apontada para o caminho real + seção nova do caminho não-dry (6 asserções) |
| `docs/handoffs/20260814-dry-run-completo/checkpoint.md` | Nota da volta 2: jornadas re-andadas, sem `F<n>` novo |
| `docs/handoffs/20260814-dry-run-completo/30-handoff-qa.md` | Este handoff — as duas voltas |
| `TODO.md` | 3 achados **fechados** (com quem fechou) + 1 novo (ausência de teste de mutação) |

## Boot da próxima fase

A próxima fase é **REVIEW** — `gate_QA` agora passa (`status: done` + `gate:` preenchido é a
âncora para projeto sem interface, contrato de `53cf63a`; registry sem bug aberto; suíte verde).
O loop QA⇄EXEC **terminou**: 1 bug achado, 1 fix (`F1`), 1 re-walk confirmando a cura.

Para o `sdd-reviewer`:

- **O diff desta missão tem três origens**, e a do meio é a que merece mais olhar: `357b401`
  (I1, o incremento planejado), `f1c9f3f` (F1, o fix do bug que a QA achou) e **`53cf63a`, que
  mudou *contrato* do kit** — `gate_QA` ganhou um caminho alternativo e o `pipeline.log` mudou de
  lugar. Contrato do kit alterado costuma exigir eco em `docs/pipeline.md`, `templates/` e nos
  agentes; **não verifiquei drift de documentação** — é da fase DOCS, mas se você quiser conferir
  cedo, é ali que eu olharia primeiro.
- **O que eu já provei, para você não refazer:** as 5 jornadas da tabela acima, e que os sensores
  do `pipeline_log_line` mordem nas 3 mutações. O que **não** provei está em "Riscos".
- **`bin/sdd` não foi tocado por mim.** Se `git diff` acusar mudança lá, não é minha.

## Pendências / Decisions for a Human

> Só julgamento humano genuíno. **Não bloqueiam o pipeline** — viram seção do PR.

**Nenhuma pendência aberta.** A única da volta 1 — `gate_QA` sem status honesto e satisfazível em
projeto sem interface — **foi decidida e implementada** por `53cf63a`, exatamente na direção que
o handoff anterior sugeriu: sem `E2E_CMD` e sem `APP_URL`, a âncora passa a ser o campo `gate:`
do próprio handoff. Andei a jornada e confirmei o efeito (J5, e o `sdd why <m> QA` desta missão).
É por isso que esta volta fecha `done` onde a anterior fechou `blocked`.

## Riscos e não-feitos

- **Não medi o custo do dry-run em repo grande.** Os gates rodam `TEST_CMD` de verdade durante a
  projeção (aceito pelo plano); no kit são ~2s, no piloto `sales_quote` pode não ser.
- **"Dry-run não toca no disco" continua mais fraco do que soa.** Reconfirmei no repo real: a
  projeção cria `.sdd/logs/<m>/gate-exec-test-<ts>.log` a cada invocação, porque os gates rodam a
  suíte. É gitignored e é comportamento aceito pelo plano — **não é bug** —, mas a árvore de
  arquivos muda, e a asserção do fixture só não pega isso porque aquele fixture reprova em
  `gate_EXEC` antes de chegar a rodar `TEST_CMD`. → `TODO.md`.
- **O fixture do J5 usa `gh` stubado.** Prova a lógica de "todos os gates satisfeitos → pipeline
  completo"; **não** prova a integração real com o GitHub. Isso só a fase PR exercita de verdade.
- **Não exercitei `sdd retry` nem `sdd close`**, que também tiveram o `PIPELINE_LOG` remapeado por
  `53cf63a`. Li o código (as três atribuições são idênticas) e o `pipeline_log_line` faz o próprio
  `mkdir -p`, então o risco é baixo — mas é leitura, não jornada andada.
- **Não reverifiquei os caminhos de escalação `963` (orçamento estourado) e `1014` (duas sessões
  sem progresso).** Continuam sem asserção própria; a guarda única do `f1c9f3f` os cobre por
  construção, o que é justamente o argumento a favor dela.
- **A cobertura de QA aqui é estreita por natureza** — este repo tem uma jornada só. Num repo-alvo
  com browser, esta fase teria charters e sessões em persona antes de mim.

## Achados fora de escopo

> Registrados no `TODO.md` do `sdd_agents` (são melhorias do kit). Aqui fica só o ponteiro.

- **Novo:** a suíte não tem teste de mutação, e por isso não percebe asserção que virou decoração
  — foi assim que o defeito desta volta passou despercebido por um commit inteiro. Direção:
  `tests/check-mutation.sh` afirmando que a suíte fica **vermelha** sob mutações conhecidas.
  → `TODO.md` (Aberto).
- **Fechados nesta volta** (mantidos no arquivo com quem os fechou, para o PR citar):
  `gate_QA` insatisfazível sem interface → resolvido por `53cf63a`; `pipeline.log` efêmero ou
  durável → decidido efêmero por `53cf63a`; caminho real de `pipeline_log_line` sem sensor →
  resolvido nesta sessão. → `TODO.md`.
- **Continua aberto:** a asserção "dry-run não toca no disco" promete mais do que entrega
  (`gate-*-test-*.log` escrito durante a projeção). → `TODO.md` (Aberto).

---

# Anexo — registro da volta 1 (2026-08-14 03:30, `status: blocked`)

> Preservado porque é a origem do `F1`. O que aqui está descrito como pendente **já foi
> resolvido** — veja o corpo acima.

Andei a jornada `sdd run <missão> --dry-run` em 4 estados de borda e achei **1 bug confirmado**:
com um incremento `blocked`, a projeção **escrevia no disco** (`pipeline.log` da missão) um evento
`BLOCKED` que nunca aconteceu.

**`BUG-dryrun-pipelinelog`** — o `00-missao.md` define, em "Resultado esperado", que "nada é
executado e nada no disco muda". Uma projeção é comando de leitura; ali ela mentia na trilha de
auditoria, registrando como acontecido um evento que só foi projetado. Causa verificada: em
`cmd_run` o Jidoka de `blocked` chamava `pipeline_log_line` e dava `return 3` **antes** do bloco
`DRY_RUN`. Blast radius: em repo-alvo recém instalado o arquivo ficava untracked e sujava o
`git status` — e tree sujo reprova `gate_REVIEW` e o `sdd preflight`, ou seja, um comando de
projeção derrubava o gate de outra fase.

Virou o `F1` no checkpoint e sensor commitado **vermelho** (`476a6e0`), com o Red observado antes
de qualquer conserto. O `sdd-executor` fechou em `f1c9f3f` com uma guarda única dentro de
`pipeline_log_line`, mais larga do que o apontado — decisão que o handoff da volta 1 já indicava
como preferível.

A volta 1 fechou `blocked` porque `gate_QA` não tinha, à época, status honesto **e** satisfazível
para projeto sem interface: `skipped` mentiria, `done` batia na Âncora 1 (relatório datado que
ninguém produz nesse caso) e `blocked` reprova por definição. Isso foi levado como decisão de
contrato para o humano — e resolvido em `53cf63a`.

Também da volta 1: **J4 (missão completa) ficou inconclusiva** por erro de fixture (hash
inventado reprovando `gate_EXEC`), registrado à época como candidato a sensor futuro. **Andada e
fechada na volta 2** (J5 acima).
