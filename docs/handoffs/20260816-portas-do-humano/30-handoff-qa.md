---
missao: 20260816-portas-do-humano
fase: QA
status: done
sessao: c026c2fc-e4c4-41de-8d72-003eea803836
data: 2026-08-16 23:05
gate: "Projeto **sem interface** (`E2E_CMD=\"\"`, `APP_URL` ausente): as 4 jornadas foram andadas na linha de comando por esta sessão, num clone real do kit em `/tmp/qa-portas/clone` (stub de `claude` no PATH, `TEST_CMD=\"true\"`), nunca em fixture de sensor. **J1 approve:** `printf 'n' | ./bin/sdd approve <m>` imprime título+corpo+2 incrementos e deixa `aprovacao:` vazia, 0 commits; com `y` grava `humano-2026-08-16`, cria **1** commit `chore(missao): plan <m> approved by the human` tocando **1** arquivo, `sdd why` sai de PLAN; 2ª chamada → `already approved`, 0 commits; stdin fechado → 0 commits; `TODO.md` sujo continua sujo (não varre); sem a chave `aprovacao:` → `die` do read-back, 0 commits, 0 temporários órfãos. **J2 branch:** `--dry-run` deixou `main` intacta e não criou branch; run real criou `missao/20260901-jornada-qa` da branch ATUAL carregando um commit que `main` não tem (`git merge-base --is-ancestor` → SIM/NÃO); branch existente → checkout; placeholder do `templates/missao.md` → no-op (mesma branch, mesma contagem, 0 anúncios); working tree em conflito → `die` com a mensagem do git, branch intocada e **0** sessões abertas (`STUB-CLAUDE-WAS-CALLED` ausente). **J3 retry:** na base o aviso sai 1× na stderr, fora dela 0×; honra a branch declarada e avisa **depois** do checkout. **J4 kaizen-born:** `auto`+verdict recusa citando kaizen-born, `auto` sem verdict passa (EXEC), `humano-*`+verdict passa (EXEC); fluxo normal (`aprovacao:` vazia+verdict) fecha via `sdd approve`. **2 achados confirmados** viraram 2 asserções em `tests/check-gates.sh`, ambas medidas **vermelhas com o bug presente** e pelo motivo certo (`bash tests/check-gates.sh` → rc 1, 76 `ok`, 2 `FAIL`), e 2 incrementos `F1`/`F2` `pending`. `bash tests/run-all.sh` → **`2 suite(s) failed`**: `check-gates.sh` pelas 2 asserções novas e `check-mutation.sh` pela guarda de controle (`HARNESS-BROKEN`, `tests/check-mutation.sh:653`), que recusa pontuar com a cópia sem sabotagem vermelha — comportamento desenhado, não um terceiro bug. Os 4 Checks do EXEC continuam intactos: `sdd approve `→3, `branch `→3, `retry `→2, `kaizen-born`→3. `bash tests/check-checkpoint.sh` → verde, 29 linhas em 6 arquivos, 10 células sob a regra da âncora."
---

# Handoff — QA — as quatro portas entre humano e runner ganham dono

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

4 jornadas de linha de comando andadas (o kit não tem interface, e `docs/qa/` não existe — não foi
criado). 30 passos, 28 verdes. **2 achados confirmados, os dois nas costuras ENTRE incrementos** —
nenhum sensor de incremento os alcançava, porque cada um foi escrito na própria sessão contra o
próprio fixture. Viraram 2 asserções permanentes (vermelhas com o bug presente) e 2 incrementos de
fix `F1`/`F2`. **Nada para humano decidir**: os dois têm causa técnica clara. O runner já deriva
`EXEC — 2 of 6` e devolve a bola ao `sdd-executor`.

## Estado do repo

- **Branch:** `missao/20260816-portas-do-humano` — nunca empurrada (`git push` é da fase PR)
- **Último commit:** o desta sessão (sensores + checkpoint + este handoff); antes, `2a6bf97`
- **Working tree:** limpo
- **Suíte:** `tests/run-all.sh` → **vermelha por desenho**, `2 suite(s) failed` — as 2 asserções
  novas e o `HARNESS-BROKEN` do controle de mutação. Verde de novo quando F1/F2 fecharem.
- **E2E:** `E2E_CMD=""` — o kit não tem interface. **A jornada é de linha de comando e está no
  `gate:` acima**, que é o que o `gate_QA` mede neste caminho.

## Os dois achados

### 1 · O remédio que o gate nomeia não existe (→ `F1`)

`gate_PLAN` recusa um plano kaizen-born (`aprovacao: auto` + `05-verdict.md` ao lado) e nomeia **uma**
saída: `run 'sdd approve <missão>'`. `cmd_approve` (`bin/sdd:1774`) lê `auto` no `case` de bail,
responde `already approved — nothing to do` e volta 0 sem escrever nada.

Os conjuntos não se sobrepõem, eles se **aninham**: o gate só recusa quando o valor é `auto`, e
`auto` é exatamente o que faz o approve desistir. **Todo** plano que o gate para é um plano que o
remédio nomeado se recusa a consertar — não "às vezes", nunca. Andado:

```
$ ./bin/sdd why 20261001-nascido-do-kaizen
PLAN: kaizen-born plan (05-verdict.md sits beside it) may not approve itself —
      a human must: run 'sdd approve 20261001-nascido-do-kaizen'
$ ./bin/sdd approve 20261001-nascido-do-kaizen     # o humano obedece
plan 20261001-nascido-do-kaizen is already approved (aprovacao: auto) — nothing to do
$ ./bin/sdd why 20261001-nascido-do-kaizen         # e o gate?
PLAN: kaizen-born plan … run 'sdd approve 20261001-nascido-do-kaizen'   ← laço infinito
```

`sdd why`, `sdd status` (2×) e `sdd run` imprimem a mesma instrução. A única saída é editar o
frontmatter à mão — **a falha que esta missão existe para matar**, e que o comentário da própria
recusa diz querer evitar.

**Por que o I4 passou verde:** a última asserção kaizen-born do `tests/check-gates.sh` alcança o
estado aprovado com `sed -i 's/^aprovacao: auto/aprovacao: humano-2026-01-06/'`. Simular o remédio
prova que o **gate aceita** o que o comando escreveria, nunca que o **comando chega lá**. O
comentário dessa asserção já dizia, por escrito, "unrunnable FOREVER, `sdd approve` included" — a
frase estava certa e a asserção media a outra metade.

**Severidade honesta:** a propriedade de segurança **se sustenta** (o plano não roda). O que quebra
é a instrução de recuperação. Hoje **não há instância viva**: as 2 missões com verdict
(`20260815-ledger-sem-ponto-cego`, `20260816-kit-como-alvo`) carregam `humano-*`, e o fluxo normal
do kaizen (`aprovacao:` vazia + verdict → `sdd approve` → `humano-<hoje>`) foi andado e **fecha**.
É latente, e morde o próximo plano kaizen-born que chegar com `auto` preenchido — que é exatamente
o caso para o qual o gate foi construído.

### 2 · A quinta porta commita em silêncio (→ `F2`)

`warn_if_on_base_branch` tem uma definição e o comentário dela (`bin/sdd:1271`) enumera "the **four**
doors that can end up committing": preflight, run, retry, kaizen. `cmd_approve` commita e **não**
chama a guarda. É a quinta porta, escrita na mesma missão que fechou o silêncio da quarta.

Andado: de pé na branch base, `sdd approve` deixou `chore(missao): plan … approved by the human` na
base sem uma palavra (0 ocorrências de `base branch` em stdout **e** stderr). É a classe SQ-97 —
16 commits em branch alheia, ~US$ 45 de `rebase --onto` — reaberta pela porta que a missão criou.

O critério que o próprio código escreve é "portas que **commitam**", não "portas que abrem sessão";
por isso o approve conta, mesmo sem abrir sessão.

## Artefatos

| Arquivo | O que contém |
|---|---|
| `tests/check-gates.sh` | **2 asserções novas**, medidas vermelhas com o bug presente: `approve resolves the refusal that names it, and still declines an 'auto' with no verdict` e `approve warns about the base branch it is about to commit into, and is silent off it` |
| `docs/handoffs/20260816-portas-do-humano/checkpoint.md` | linhas `F1` e `F2` `pending` + 8 notas de execução da QA (qual achado gerou qual fix, e por que o I4 passou verde) |
| `docs/handoffs/20260816-portas-do-humano/30-handoff-qa.md` | este arquivo; o `gate:` carrega a jornada andada |
| `TODO.md` | intocado — nenhum achado desta sessão é fora de escopo (ver abaixo) |

## Boot da próxima fase

O runner já deriva **`EXEC — 2 of 6 increment(s) still to execute`**: a bola volta ao
`sdd-executor`, um incremento por sessão, pelo laço QA⇄EXEC (`QA_MAX_ITER=3`).

Leia nesta ordem: as **Notas de execução do `checkpoint.md`** (as 8 linhas `QA` no fim), depois a
seção "Os dois achados" acima. O que a sessão de EXEC precisa saber e não descobriria sozinha:

1. **As duas asserções já existem e já estão vermelhas.** É TDD com o red pronto — não escreva
   asserção nova, faça a que existe ficar verde. A direção de cada conserto está na seção
   "Incrementos de fix (QA)" do `checkpoint.md`.
2. **A asserção do F1 é um par diferencial de propósito.** `auto`+verdict tem de ser destravado E
   `auto` sem verdict tem de continuar recusado. **Medido:** o conserto preguiçoso — tirar `auto`
   do `case` de bail — deixa a asserção **vermelha**. Um approve que reescreve todo `auto` em
   `humano-<hoje>` apagaria a procedência do PLAN-AUTO em silêncio.
3. **A condição kaizen-born passa a ser lida em dois lugares** (`gate_PLAN` e `cmd_approve`). Pela
   regra do enum do `CLAUDE.md`, vira **uma** definição — foi assim que `is_escalation`,
   `warn_if_on_base_branch` e `ensure_mission_branch` ganharam casa única, e é o defeito que este
   achado é: dois pontos que leem a mesma regra e discordam.
4. **F2 é aviso, nunca `die`.** O plano legitimamente vive na branch base antes de a branch da
   missão ser cortada — é de lá que `ensure_mission_branch` corta. Recusar quebraria o fluxo normal.
5. **`check-mutation.sh` vai reportar `HARNESS-BROKEN` enquanto F1/F2 estiverem `pending`.** É a
   guarda de controle dele (`tests/check-mutation.sh:653`), que recusa pontuar quando a cópia sem
   sabotagem já está vermelha — sem ela o score leria 48/48 por vacuidade. **Não é um terceiro
   bug e não se conserta**: volta a pontuar sozinha quando os dois fixes fecharem.
6. **Mutação nova é esperada nos dois fixes** (`sdd health` reprova gate sem mutação). O F2 pede
   uma de **call site**, pelo mesmo motivo declarado que o `RETRY_base_branch_warn_dead` do I3: o
   defeito É o call site ausente, e a definição já tem a sua.
7. **Prefixos de asserção são contrato com os Checks.** `approve resolves` e `approve warns` foram
   escolhidos para não inflar `^  ok    sdd approve` (que o Check do I1 conta em 3). Medido depois
   de escritas: os quatro Checks do EXEC continuam **3/3/2/3**.

## Pendências / Decisions for a Human

- **Nenhuma.** Os dois achados têm causa técnica clara e comportamento pretendido inequívoco — o
  próprio runner diz por escrito o que deveria acontecer (a mensagem do gate nomeia o remédio; o
  comentário da guarda enumera as portas que commitam). Nada aqui é política de produto, UX,
  pagamento ou acesso externo, então nada bloqueia o pipeline por decisão humana.
- O que exigia julgamento humano nesta missão (o eixo do juiz / I13.4, que precisa de ADR) já
  estava **fora de escopo** no `00-missao.md` e segue no `TODO.md`. A QA não encostou.

## Riscos e não-feitos

- **A suíte está vermelha por desenho e a missão não fecha até F1/F2.** Se os dois fixes não
  couberem no `QA_MAX_ITER=3`, a decisão passa a ser humana — reverter as 2 asserções não é opção
  silenciosa: apagá-las devolve o kit ao estado em que o remédio impresso não funciona.
- **Não andei a jornada do `sdd kaizen` de ponta a ponta** (nascer o plano, escrever o verdict,
  aprovar, rodar). Custa uma sessão real de kaizen. O que andei foi o estado que ela produz,
  montado à mão nos 3 casos diferenciais — o suficiente para o achado, não o suficiente para
  afirmar que o laço inteiro fecha.
- **Não medi concorrência** (dois `sdd` no mesmo repo) nem `sdd approve` durante rebase/merge em
  curso. Fora do que a missão mexeu.
- **O marcador kaizen-born continua sendo a presença do arquivo, não seu conteúdo** — um
  `05-verdict.md` de zero byte conta como verdict. Já estava dito no handoff do EXEC; a QA
  confirma que segue verdadeiro e que o F1 não muda isso (ele lê a mesma condição do gate).
- **`docs/pipeline.md` continua sem seção para `sdd approve` e para o campo `branch:`** — trabalho
  da fase DOCS, já anotado 2× nas Notas do EXEC. A QA não escreveu prosa de documentação.

## Achados fora de escopo

> Registrados no `TODO.md` do repo-alvo (aqui, o próprio kit). Aqui fica só o ponteiro.

- **Nenhum.** Os 2 achados desta sessão nasceram do diff **desta** missão, nas costuras entre os
  próprios incrementos dela, e por isso viraram `F1`/`F2` no `checkpoint.md` em vez de linha no
  `TODO.md`. O `TODO.md` não foi tocado por esta sessão.
- Verificado e **descartado como achado**: `frontmatter_write` usa `chmod --reference` (GNU-only) —
  o kit declara e **sonda por comportamento** a userland GNU (`bin/sdd:22,29,1358`), então não é
  defeito. Registrado aqui para a próxima sessão não re-investigar.
