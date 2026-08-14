---
missao: 20260814-dry-run-completo
fase: EXEC
status: done
sessao: 6797ddb6-d68d-4c4e-85f4-83a4501db01a
data: 2026-08-14 04:55
gate: "`tests/run-all.sh` → exit 0 · 104 asserções ok, 0 falhas · saída final `suíte verde` · `sdd why <m> EXEC` → `2 incremento(s) done, suíte verde, handoff escrito`. As 3 asserções que a QA deixou vermelhas (`projeção blocked não cria pipeline.log`, `árvore idêntica antes e depois (caminho blocked)`, `working tree continua limpo (caminho blocked)`) estão verdes."
---

> **Duas passagens pelo EXEC.** Este handoff cobre as duas: a **1ª** (I1, commit `357b401`) e a
> **2ª** (F1, commit `f1c9f3f`), que veio depois de a QA achar um bug e devolver a bola — o loop
> QA⇄EXEC funcionando como projetado. O registro da 1ª passagem foi preservado inteiro; o da 2ª
> está marcado como tal.

# Handoff — EXEC — dry-run mostra o pipeline inteiro

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

`sdd run <missão> --dry-run` agora projeta **todas** as fases pendentes (EXEC → QA → REVIEW →
DOCS → PR), cada uma com agente, modelo e prompt de boot — antes imprimia só a primeira e
parava. Único incremento do plano (I1) feito em TDD no commit `357b401`; suíte verde.
Sensor novo `tests/check-dry-run.sh` entrou em `tests/run-all.sh` e roda daqui em diante.
Esta foi a **primeira execução headless bem-sucedida da fase EXEC** do kit.

**2ª passagem (F1, `f1c9f3f`):** a QA andou a jornada e achou que, no caminho `blocked`, a
projeção **escrevia** no `pipeline.log` da missão um evento que nunca aconteceu. Consertado com
guarda única dentro de `pipeline_log_line`. Suíte de volta ao verde (104 asserções). **Não
escrevi teste novo — o Red veio pronto da QA** e foi observado vermelho antes do conserto.

## Estado do repo

- **Branch:** `missao/20260814-dry-run-completo` — local, sem remoto configurado; push é da fase PR.
- **Último commit:** `f1c9f3f` `fix(runner): projecao do dry-run nao escreve no diario da missao (F1)`
  (a 1ª passagem terminou em `357b401`; entre as duas, a QA commitou `476a6e0` e `b1e99c8`)
- **Working tree:** sujo apenas com os artefatos desta fase (`checkpoint.md`, `TODO.md` e este
  handoff), commitados logo em seguida.
- **Suíte:** `tests/run-all.sh` → **verde**, exit 0, 104 asserções ok / 0 falhas. (Eram 98 na 1ª
  passagem; a QA somou 4 asserções em `check-dry-run.sh`, 3 delas vermelhas até o `f1c9f3f`, e
  outras 2 entraram com o `73e594e`.)
- **E2E:** `E2E_CMD` vazio no `.sdd/config.sh` — o kit é bash + markdown, não tem jornada de
  navegador. Não rodou por não existir.

## O que foi feito

### 2ª passagem — F1 (esta sessão)

- `f1c9f3f` — **F1: a projeção não escreve no diário da missão.** Um arquivo, uma guarda:
  `pipeline_log_line()` (`bin/sdd:557`) retorna cedo quando `DRY_RUN=1`. **Zero asserção nova** —
  e isso é o esperado: o sensor já estava escrito e commitado pela QA em `476a6e0`; o trabalho
  desta sessão era de produção, não de teste.

**Red herdado, observado antes do conserto** (a suíte foi rodada na abertura, como manda o
contrato): exit 1, 101 asserções verdes e exatamente as 3 da QA vermelhas —
`projeção blocked não cria pipeline.log`, `árvore idêntica antes e depois (caminho blocked)` e
`working tree continua limpo (caminho blocked)`. Depois do conserto: exit 0, 104 verdes.

**Onde a guarda ficou, e por que não onde a QA sugeriu.** O `30-handoff-qa.md` apontou
`bin/sdd:947` (o Jidoka de `blocked`) como "o caminho óbvio", e mencionou de passagem que uma
guarda única seria "melhor ainda". Fui pela guarda única: os caminhos de escalação que chamam
`pipeline_log_line` são **três** (`947` checkpoint `blocked`, `963` orçamento estourado, `1014`
duas sessões sem progresso), e a QA verificou que hoje só o primeiro é alcançável em dry-run.
"Hoje" é a palavra frágil: um quarto caminho adicionado amanhã nasceria com o mesmo defeito.
Com a guarda dentro da função, "a projeção não escreve no diário" passa a ser verdadeiro por
construção, e não por auditoria de alcançabilidade que precisa ser refeita a cada refactor.

**Verificação que o sensor não faz** (e que por isso virou `TODO.md`): a guarda usa
`[ "$DRY_RUN" = "1" ] && return 0` sob `set -euo pipefail`. Se o `set -e` mordesse ali, o
caminho **real** pararia de escrever no `pipeline.log` — e nenhum teste pegaria, porque escrever
de verdade exige uma `run_phase` real, que chamaria o `claude`. Provei num probe descartável que
com `DRY_RUN=0` a função ainda escreve e a execução segue após a chamada. Probe não é sensor;
a lacuna está registrada.

**Re-walk do Check, na missão real** (não só no fixture): I1 flipado para `blocked`,
`bin/sdd run 20260814-dry-run-completo --dry-run` → exit 3, `md5sum` do `pipeline.log` idêntico
antes e depois, `git status --porcelain` sem novidade; checkpoint revertido em seguida.

### 1ª passagem — I1

- `357b401` — **I1: dry-run projeta o pipeline inteiro.** Três arquivos, um commit:
  - `tests/check-dry-run.sh` (novo, o sensor — escrito **primeiro**, falhou primeiro): monta um
    repo-fixture em `mktemp -d`, instala o kit, cria uma missão parada em EXEC e roda
    `sdd run <m> --dry-run`. A asserção central compara a sequência
    `EXEC=sdd-executor / QA=sdd-qa / REVIEW=sdd-reviewer / DOCS=sdd-docs / PR=sdd-publisher`
    extraída da saída — uma asserção que cobre quatro coisas de uma vez: quais fases aparecem,
    em que ordem, quantas vezes cada uma, e qual agente foi anunciado em cada bloco. Mais três:
    fase com gate satisfeito (TICKET, com `JIRA_ENABLED=false`) **não** entra na projeção; a
    árvore de arquivos e o `git status` do fixture são idênticos antes e depois (dry-run não
    escreve nada); e `--phase QA` continua imprimindo uma fase só.
  - `bin/sdd` — função nova `next_pending_phase()` e, no bloco `DRY_RUN` de `cmd_run()`, o
    `return 0` virou avanço para a próxima fase pendente via o cursor `dry_next`.
  - `tests/run-all.sh` — registra o sensor como sub-suíte permanente.

**Red observado antes do Green** (não é formalidade — é a prova de que o sensor testa o que se
acha que testa): o teste falhou com `obtido: EXEC=sdd-executor`, faltando as outras quatro
fases. As demais asserções já passavam antes da mudança, o que as torna guardas de regressão
das três coisas que o plano mandou não quebrar.

## Artefatos

| Arquivo | O que contém |
|---|---|
| `tests/check-dry-run.sh` | Sensor durável da projeção do dry-run; roda em toda `tests/run-all.sh`. **Não foi tocado na 2ª passagem** — o Red do F1 é dele, escrito pela QA |
| `bin/sdd` | 1ª passagem: `next_pending_phase()` + cursor `dry_next` no bloco `DRY_RUN` de `cmd_run()`. 2ª: guarda `DRY_RUN` dentro de `pipeline_log_line()` (`:557`) |
| `tests/run-all.sh` | Sub-suíte "projeção do dry-run" registrada |
| `docs/handoffs/20260814-dry-run-completo/checkpoint.md` | I1 `done` / `357b401`, F1 `done` / `f1c9f3f` + notas de execução das duas passagens |
| `TODO.md` | 1 achado novo desta sessão (o caminho não-dry de `pipeline_log_line` não tem sensor) |

## Boot da próxima fase

A próxima fase é **QA** — confirmado por `sdd phase 20260814-dry-run-completo` → `QA`. É a
**2ª volta da QA** nesta missão (`QA_MAX_ITER=3`), então leia primeiro o que é novo:

- **O `F1` está fechado** (`f1c9f3f`). O que você reprovou na volta anterior — J3, a projeção
  escrevendo `pipeline.log` no caminho `blocked` — deve estar curado. **Re-ande o J3**: é a
  jornada impactada, e o re-walk é seu, não meu (o meu está registrado acima, mas quem julga a
  jornada é a QA). As 3 asserções que você deixou vermelhas estão verdes.
- **O conserto foi mais largo do que o seu sensor cobre.** Você guardou o caminho `947`; eu
  guardei a função. Os caminhos `963` (orçamento estourado) e `1014` (duas sessões sem
  progresso) também deixaram de logar em dry-run — você mesma verificou que não são alcançáveis
  na projeção hoje, então não há asserção sobre eles e **continua não havendo**. Se quiser
  fechar essa fresta, é sensor novo, não regressão.
- **A sua pendência de fechamento continua de pé e é o que vai travar esta volta.**
  `gate_QA` não tem status honesto e satisfazível para projeto sem interface — está descrito em
  `30-handoff-qa.md` ("Pendências") e no `TODO.md` (1ª entrada em "Aberto"). **Nada nesta sessão
  mexeu nisso**: não era `F<n>`, é decisão de contrato do kit, e o EXEC não altera contrato por
  conta própria. Se ninguém decidiu no intervalo, escolher `done` reprova na Âncora 1 e a QA
  gira até estourar o `QA_MAX_ITER` e sair 3. Vale reler aquilo **antes** de escolher o
  `status:`, como o seu próprio handoff avisou.

O restante segue valendo da 1ª passagem:

- **O diff é user-visible pela saída de um comando de CLI, não por tela.** Não há navegador,
  não há `APP_URL`, não há jornada de usuário em browser. `E2E_CMD` está vazio de propósito:
  a "jornada" deste repo é alguém digitar `sdd` no terminal e ler o que sai.
- **A jornada tocada é uma só:** `sdd run <missão> --dry-run` — "o que acontece se eu rodar
  isto?". Vale exercitá-la contra uma missão real e contra os estados de borda: missão parada
  em PLAN (deve imprimir a instrução interativa e sair 2, sem projetar nada — PLAN bloqueia
  todo o resto); missão com incremento `blocked` (deve escalar com exit 3, comportamento
  anterior preservado); missão completa (deve dizer "pipeline completo"); `--phase <FASE>`
  combinado com `--dry-run` (uma fase só).
- **Como subir o ambiente:** não há ambiente para subir. `cd` no repo e rodar
  `tests/run-all.sh` (exit 0) ou `bin/sdd run 20260814-dry-run-completo --dry-run`. O dry-run
  é seguro por construção — o próprio sensor afirma que ele não escreve nada no disco.
- **Comando de verificação manual usado nesta fase:**
  `bin/sdd run 20260814-dry-run-completo --dry-run` → lista EXEC, QA, REVIEW, DOCS, PR nesta
  ordem, com `sdd-executor`/`sdd-qa`/`sdd-reviewer`/`sdd-docs`/`sdd-publisher` e os modelos do
  `.sdd/config.sh` (`opus` nas quatro primeiras, `sonnet` na PR).
- **Ler primeiro:** `00-missao.md` (a métrica), o `checkpoint.md` inteiro **incluindo as notas
  de execução** — elas contam por que esta missão travou uma vez e o que a destravou.

## Pendências / Decisions for a Human

Nenhuma **criada por esta fase** — não há política de UX, decisão de produto, pagamento nem
acesso externo no que foi feito aqui.

Mas herdada e **ainda aberta**: `gate_QA` não tem status honesto e satisfazível para projeto sem
interface (`30-handoff-qa.md` → "Pendências"; `TODO.md` → "Aberto", 1ª entrada). Não é minha para
resolver — mudar o que o gate aceita como evidência é alterar contrato do kit —, mas é a razão
pela qual esta missão pode não fechar sozinha mesmo com a suíte verde. Registro aqui para que
não se perca entre um handoff e outro.

## Riscos e não-feitos

- **A projeção é do estado de HOJE e não simula o efeito das fases** — decisão do grill, não
  omissão (`00-missao.md`, "Fora de escopo"). Consequência prática que a QA vai ver: com um
  incremento pendente, o dry-run lista EXEC uma vez só, embora o runner real fosse rodar uma
  sessão EXEC por incremento. É informação honesta, não completa. Se isso incomodar na prática,
  vira missão nova, não conserto aqui.
- **Gates rodam de verdade durante a projeção**, inclusive os que chamam `TEST_CMD`
  (`gate_EXEC`, `gate_QA`, `gate_REVIEW`). No kit isso custa ~2s e `run_check_cmd` memoiza por
  processo; num repo-alvo com suíte lenta, o dry-run herda essa lentidão. Não medido em repo
  grande — o piloto `sales_quote` é onde isso aparece, se aparecer.
- **A borda PLAN + `--dry-run` não tem asserção automatizada.** É comportamento pré-existente e
  intocado (o `return 2` acontece antes do bloco `DRY_RUN`), mas a afirmação de que continua
  intacto é minha leitura do código, não um sensor. Candidato natural a charter da QA.
- Nenhum outro comando do runner foi tocado: `status`, `why`, `phase`, `retry` e `preflight`
  estão exatamente como estavam.

Da 2ª passagem (F1):

- **O caminho real de `pipeline_log_line` não tem sensor.** Todo teste que temos afirma que a
  projeção **não** escreve; nenhum afirma que uma fase de verdade **escreve**. Uma inversão da
  guarda mataria o diário da missão em silêncio com a suíte verde. Provei o caminho não-dry à
  mão nesta sessão; um probe descartável não protege ninguém amanhã. → `TODO.md`.
- **`cmd_close` (`bin/sdd:1114`) também passou a ser coberto pela guarda.** É a fase TICKET, onde
  `DRY_RUN` nunca é 1 hoje (`--dry-run` só é parseado em `cmd_run`), então o efeito prático é
  nulo — mas é mudança de comportamento por alcance da guarda única, não intenção explícita, e
  fica dito para não parecer descuido se alguém der `--dry-run` ao `close` um dia.
- **Não reverifiquei as bordas J1, J2 e J4** da QA. Toquei uma função que só o caminho `blocked`
  exercitava em dry-run, e a suíte inteira está verde, mas o julgamento das jornadas é da QA.

## Achados fora de escopo

**Da 2ª passagem (F1) — 1 novo, registrado no `TODO.md`:** a suíte não exercita o caminho real
(não-dry) de `pipeline_log_line` (`bin/sdd:557`), então uma quebra da guarda ao contrário mata o
diário da missão sem ninguém notar. Direção anotada lá: extrair as funções puras de `bin/sdd`
para um arquivo sourceável, ou um modo `--self-test` no runner. Não consertei aqui — é mudança
na estrutura do runner, escopo de missão própria, não do incremento de fix que peguei.

**Da 1ª passagem:** nenhum novo. O achado que travou a sessão EXEC anterior — sessão headless sem
`--allowedTools` não consegue rodar `TEST_CMD` nem commitar — **já foi corrigido** por `2083680`
(fora desta missão) e esta sessão é a prova viva do conserto: rodou a suíte, viu o Red, viu o
Green e commitou. O `TODO.md` continua com a proposta de sensor durável para isso
(`sdd preflight` afirmando que uma sessão headless de fato executa `TEST_CMD`), que segue de pé
e **não** foi feita aqui — corrigir a causa não é o mesmo que instrumentar contra a recaída.
