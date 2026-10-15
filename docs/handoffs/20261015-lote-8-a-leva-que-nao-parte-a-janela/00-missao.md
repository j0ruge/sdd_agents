---
missao: 20261015-lote-8-a-leva-que-nao-parte-a-janela
titulo: os achados de sensor e do /sdd-plan que não partem a janela do juiz saem do backlog — a regra 2 do check-checkpoint lê a variável e aceita a marca de "passou", a âncora longa cabe no teto do check-todo, e o /sdd-plan não deixa a branch rastrear a main nem mostra uma devolução vencida
data: 2026-10-15
versao:
branch: fix/lote-8-a-leva-que-nao-parte-a-janela
aprovacao: humano-2026-10-15
adr: none
ddd: n/a
qa:
kaizen_log:
---

# Missão — o lote 8: a leva que não parte a janela

> Escrito pelo `sdd-planner` com o humano presente (relay do `/sdd-plan`, 2026-10-15 14:57–15:26).
> É a única fonte da **intenção**; o `01-plano.md` é a fonte do **como**. Toda sessão começa lendo
> estes dois.
>
> ⚠️ **Missão do próprio kit: executada INTERATIVA, no worktree ligado
> `/home/joruge/repos/sdd_agents-lote-8`, nunca por `sdd run` a partir do checkout principal**
> (ADR 0016 §2, `commands/sdd-plan.md` passo 2). Dentro do worktree, `health`, `preflight` e
> `install` rodam como `./bin/sdd`. O checkout principal `/home/joruge/repos/sdd_agents` é o kit que
> o `sdd` do PATH executa para os alvos: nada se escreve nele.

## Problema (Gemba)

O tema do humano foi "zerar as issues no github, ve o que pode ir junto na mesma leva de
resolucao". As issues (label `todo`) espelham o `TODO.md`, 13 ↔ 13 às 14:57. Mas **o kit está
congelado desde o merge do lote 7** (D11 de `20261012-a-rota-da-qa`, PR #252 `bad6168`): nada entra
em `bin agents templates config` até o veredito da janela do lote 7, e o veredito precisa de 3
missões de alvo com sessão sobre essa versão. Hoje há **1 de 3**: `./bin/sdd kaizen --series`
(14:58) responde `latest.kit_sha: bad6168`, `missions: 1`, `guard.sufficient: false`,
`why: [floor]`. A missão é a `20261014-amep-entrada-em-dois-niveis` do `lighthouse_project`, com 44
sessões e US$ 192,80, e havia um `sdd run` dela vivo às 15:03. O eixo do juiz agrupa pelo último
commit em `KIT_BEHAVIOR_PATHS=(bin agents templates config)` (`bin/sdd:4075`); `tests/`,
`commands/`, `docs/`, `TODO.md` e a catraca ficam fora do eixo.

Medido item por item, o conserto provável de 4 dos 13 itens fica fora do eixo, e é esta leva:

- **#258 — a regra 2 do `check-checkpoint.sh` vale por célula** (`tests/check-checkpoint.sh:307-319`).
  Um `2>&1` na célula obriga TODO `grep` dela a ancorar em `^  ok    `, até o que lê um arquivo.
  Reproduzido no HEAD com um checkpoint de fixture:
  `o=$(bash t.sh 2>&1); a=$(grep -c '^  ok    x' <<< "$o"); b=$(grep -c foo f)` → `the Check of I1
  greps a sensor's merged output with 1 of 2 pattern(s) anchored on the ok prefix`.
- **#249 — a regra 2 recusa a Check de alvo ancorada no `✓` do vitest** (`tests/check-checkpoint.sh:163`,
  `ANCHOR_SQ`). Reproduzido: `o=$(npm test 2>&1); grep -c '^ ✓ src/a.test.ts > caso' <<< "$o"` →
  `0 of 1 pattern(s)`. As 10 Checks da LH-4 do lighthouse
  (`/home/joruge/repos/lighthouse_project/docs/handoffs/20260927-idioma-da-spa-pelo-idp/checkpoint.md`)
  são recusadas no `--check`. O contorno já virou folclore no alvo: o `01-plano.md:39` da LH-6 diz
  "Nunca `2>&1` numa célula de Check que tem `grep`".
- **#257 — uma âncora de caminho longo não cabe no teto de largura** (`tests/check-todo.sh:211`,
  `WIDTH_CAP`). O caminho real do `sales_quote` tem 117 caracteres, mais `:420`. Num fixture, a linha
  que só carrega a âncora tem 125 caracteres e é recusada: `line 7: 125 characters on one physical
  line, cap is 120`. O símbolo na linha seguinte já passa no parser de âncora.
- **#264 — um recado ao planner que está rodando chega depois da devolução** (`commands/sdd-plan.md:94-104`).
  A regra "Nothing else resumes the planner while a question is pending" supõe que o relay sabe que
  há pergunta pendente. Quando o planner já devolveu, o `SendMessage` o **retoma** a partir do
  transcript, e a devolução seguinte supera a anterior. Pela descrição da ferramenta (lida nesta
  sessão): "a send resumes it from its transcript"; com o agente ocupado, "messages enqueue and
  drain at the receiver's next tool round".
- **O achado nascido neste grill: a receita do worktree deixa a branch com upstream `origin/main`**
  (`commands/sdd-plan.md:35`; commit `ed78ff5`). Verificado com git 2.43.0 num repo de rascunho:
  - sem a flag, `t1@{u}` = `origin/main`;
  - com `--no-track` antes ou **depois** do caminho, `no upstream configured`.

  Entra pela decisão 1 (só toca `commands/`).

Os outros 9 itens tocam `bin/`, `agents/` ou `templates/` e esperam a triagem do `sdd kaizen` depois
do veredito (decisão 3).

## Métrica

- **M1 (#258 + #249, o consumidor medido):** o `tests/check-checkpoint.sh --check` sobre o checkpoint
  da LH-4 recusa **10** células hoje e **no máximo 1** depois. A que pode sobrar é a I9, que lê
  `^Total:` do `playwright --list` sem marca de "passou", uma recusa correta pela regra.
- **M2 (#258 + #249, o controle negativo):** a célula cega de verdade continua recusada. O probe
  `o=$(npm test 2>&1); grep -c 'caso' <<< "$o"` do selftest responde rc 1 antes e depois.
- **M3 (#258 + #249, o alcance):** o `--check` sobre todos os checkpoints dos dois alvos recusa **122**
  células em 19 missões hoje; o número de depois é medido pelo sensor real e vai para o
  `KAIZEN_LOG.md`. O protótipo descartável do planner previu ~113.
- **M4 (#257):** a linha de 125 caracteres que só carrega a âncora é recusada hoje e aceita depois.
  A mesma linha com prosa, ou com um span que tem espaço, continua recusada.
- **M5 (#264 e `--no-track`):** duas linhas `ok    command: /sdd-plan …` novas no `tests/check-hat.sh`
  (0 hoje, 1 depois).
- **M6 (o fecho):** os 5 itens carregam `RESOLVED by <hash>`, a catraca vai de 15 para 16 com o
  item da prosa congelada (decisão 7), e a entrada do `KAIZEN_LOG.md` cita o id inteiro da missão.

## Resultado esperado

Uma Check de alvo que lê a stdout do vitest ou do Playwright pela marca de "passou" (`^ *✓ `) passa
a ser aceita, e um `grep` que lê um arquivo deixa de ser cobrado como se lesse a saída misturada.
Um caminho de 121 caracteres pode ser a âncora de um achado. O `/sdd-plan` corta a branch da missão
sem upstream e manda o relay descartar a devolução que um recado superou. O backlog sai de 15 para
11 itens depois do chore pós-merge, todos congelados e com dono na triagem do `sdd kaizen`.

## Fora de escopo

- **Os 9 itens congelados** (#255, #256, #259, #260, #261, #262, #263, #265 e #266): vão para a
  triagem do `sdd kaizen` depois do veredito (decisões 1 e 3).
- **O gêmeo congelado da receita sem `--no-track`.** O motivo da recusa do `sdd kaizen`
  (`bin/sdd:11241`, `shared_why`) e as duas citações dele (`docs/failure-modes.md:624`,
  `docs/pipeline.md:1477`) ficam como estão, porque as citações reproduzem o motivo do runner
  palavra por palavra. Registrado no `TODO.md` pelo planner (commit `42b1a35`, catraca 14 → 15).
- **A prosa congelada que fica mais estrita que o sensor** (`templates/checkpoint.md:27`,
  `agents/sdd-planner.md:111`, `templates/todo.pt-BR.md:24`, `agents/sdd-executor.md:127`): vira um
  item no `TODO.md` no fecho (decisão 7), não edição.
- **Aceitar as linhas de resumo do runner** (`Tests  N passed`, `Test Files  N passed`, ` N passed`)
  como verde: recusado (decisão 5, opção 2).
- **Sincronizar o espelho de issues e apagar os itens resolvidos:** chore pós-merge, do humano.

## Gate PLAN-AUTO

Preenchido pelo `sdd-planner` **com evidência**. Todos ✅ → `aprovacao` fica vazio do mesmo jeito: o
humano lê o plano no passo de aceite do `/sdd-plan` e aprova com `sdd approve`. O `auto` só entra
quando o humano o pediu no grill, e aí o pipeline segue sozinho até o PR (ADR 0018 §3). Qualquer ✗ →
`aprovacao` fica vazio e o runner para pedindo aprovação humana explícita, nomeando o critério.

| # | Critério | Status | Evidência |
|---|---|---|---|
| a | Grill sem perguntas abertas não endereçadas (🚩 vazia ou itens deferidos com dono) | ✅ | 9 decisões, cada uma com a sua linha `- answer:`; os 9 itens congelados e os 2 nascidos congelados têm dono (triagem do `sdd kaizen`) |
| b | Checklist kaizen 100% ✅ e checklist DDD 100% ✅ ou `n/a` justificado | ✅ | K1–K8 ✅ abaixo; DDD `n/a` (sensores e prosa de comando, sem domínio) |
| c | Plano passa no teste de autocontenção (sessão nova só com 00/01/checkpoint executa) | ✅ | o I1 nomeia linha, função, fixture, probe, piso e texto exato da linha `ok`; ver `01-plano.md` § Teste de autocontenção |
| d | Todo incremento do `checkpoint.md` tem Check executável (comando → esperado), vermelho no HEAD pelo `tests/check-checkpoint.sh --red` do kit | ✅ | 6 de 6 vermelhos no HEAD; `--check` e `--red` rc 0 (antes de cada Check no `01-plano.md`) |
| e | `versao:` confirmada pelo humano (ou `JIRA_ENABLED=false`) | ✅ | `JIRA_ENABLED=false` (`.sdd/config.sh`) |
| f | `adr:` é uma decisão — um caminho, ou o literal `none` (alocado por `sdd adr new`) | ✅ | `none`, decisão 9: só `tests/` e `commands/`, reversível num commit, o porquê fica nos cabeçalhos dos sensores |

## Checklist kaizen (`kaizen-software`)

> O K8 desta tabela é prosa: quem dispensa a entrada do KAIZEN_LOG.md é só o literal kaizen_log: skipped no frontmatter, decidido com o humano no grill.

| # | Item | Status | Nota |
|---|---|---|---|
| K1 | Gemba — fui ver onde o trabalho acontece | ✅ | os três defeitos de sensor reproduzidos em fixture no HEAD; o `--check` rodado sobre os 36 checkpoints dos dois alvos; o `--no-track` medido com git 2.43.0 |
| K2 | Problema declarado com métrica | ✅ | M1–M6, cada uma com número de antes |
| K3 | Desperdícios identificados e cortados | ✅ | o contorno (`2>/dev/null`, ancorar outro arquivo) vira desnecessário; nenhuma lista de frases de runner para manter (decisão 5) |
| K4 | Fatiamento incremental, cada fatia verificável | ✅ | 6 incrementos, um sensor ou um comando por fatia, cada um com Check vermelho no HEAD |
| K5 | Check por artefato (rótulo ≠ artefato) | ✅ | toda Check lê a linha `ok` do sensor ancorada em `^  ok    `, ou o arquivo |
| K6 | Jidoka — o que para a linha está definido | ✅ | selftest vermelho (rc 90–92) para a suíte; piso apertado de probes; `tests/run-all.sh` no fecho |
| K7 | SDCA — a melhoria vira padrão (doc/rule/teste) | ✅ | probes duráveis em três sensores da suíte rápida; a prosa congelada vai para a triagem (decisão 7) |
| K8 | Registro no KAIZEN_LOG | ✅ | entrada no fecho (I6), com os números remedidos pelo sensor real (decisão 8) |

## Checklist DDD (`ddd`) — condicional

`n/a — sem toque de domínio`: a leva muda dois sensores de markdown (`tests/`), uma bateria de probes
de prosa e o texto de um comando. Nenhum aggregate, contexto, evento ou contrato entre módulos.

## Decisões do grill (não re-litigar)

1. **Duas levas, pela fronteira do congelamento.** Esta missão leva #249, #257, #258, #264 e o achado
   do `--no-track` (este entra pelo mesmo critério, porque só toca `commands/`), e mergeia quando
   estiver pronta. Os 9 que tocam `bin/`, `agents/` ou `templates/` vão para a triagem do
   `sdd kaizen` depois do veredito. Por quê: respeita a D11 do lote 7 e não descarta a 1/3 da
   janela já paga (44 sessões, US$ 192,80).
   - answer: (recommended)
2. **Merge livre, pull ocioso.** O merge no GitHub acontece quando o PR estiver pronto. O
   `git pull --ff-only` do checkout principal só roda com
   `ps -eo pid,etime,cmd | grep -E 'bin/sdd (run|retry|close)'` vazio. Por quê: a guarda de kit
   amostra só o checkout local (`kit_guard_arm` → `autonomy_kit_stamp` + `kit_guard_tree`), e as
   duas paradas `kit-touched` da missão do lighthouse (01:44 e 09:42) vieram 4 e 17 min depois dos
   merges #246 e #254. Sem o pull, o conserto não chega a ninguém: o `/sdd-plan` do humano é um
   symlink para `/home/joruge/repos/sdd_agents/commands/sdd-plan.md`.
   - answer: (recommended)
3. **Nenhum dos 9 congelados fecha agora por decisão escrita.** Todos têm defeito medido fora da
   suíte do kit. Por quê: a triagem do `sdd kaizen` é a dona da rota, e decide com a série na mão.
   - answer: (recommended)
4. **O id é `20261015-lote-8-a-leva-que-nao-parte-a-janela`**, branch
   `fix/lote-8-a-leva-que-nao-parte-a-janela`, sem upstream. Por quê: o nome carrega o critério da
   decisão 1; "zerar as issues" passaria a descrever o que a missão não faz.
   - answer: (recommended)
5. **A regra 2 (#249 + #258) conserta os dois itens como estão escritos.**
   - Seguir a variável: só o `grep` que lê uma variável capturada com `2>&1` precisa de âncora. Um
     `2>&1` fora de uma captura limpa cai na regra de hoje.
   - Aceitar o `✓` no começo da linha (`'^ *✓ '`) como âncora de "passou", ao lado de `^  ok    `.
   - As linhas de resumo do runner ficam fora.
   - Por quê: fecha o consumidor medido (a LH-4 cai de 10 para 1, pelo protótipo) sem criar uma lista
     de frases por runner para manter.
   - answer: (recommended)
6. **O teto de largura (#257) isenta a linha que só carrega a âncora:** depois do recuo, um único
   span com forma de caminho e sem espaço. O `` (`símbolo`) `` vai na linha seguinte, e a mensagem do
   teto nomeia essa saída quando a linha estourada carrega um span com forma de caminho. Por quê:
   isenta exatamente o caso medido, e nenhuma prosa ganha largura.
   - answer: (recommended)
7. **A prosa congelada que fica mais estrita que o sensor vira UM item no `TODO.md`**, registrado no
   fecho com a catraca no mesmo commit. Ancorado no banner do `^  ok    ` de
   `templates/checkpoint.md`, ele nomeia os quatro textos. Por quê: dívida escrita é limite, dívida
   calada é fail-open (D15); vai para a triagem como uma única mudança de prosa.
   - answer: (recommended)
8. **K8 ✅:** a entrada do `KAIZEN_LOG.md` vai no fecho, com os números remedidos pelo sensor real,
   não pelo protótipo. Por quê: é melhoria com antes e depois em número.
   - answer: (recommended)
9. **`adr: none`.** Só `tests/` e `commands/`; nenhum gate, nenhuma chave e nenhum contrato do runner;
   reversível num commit; o porquê fica nos cabeçalhos dos sensores, como no lote 3. Por quê: não há
   trade-off caro de reverter.
   - answer: (recommended)

## Pendências para o humano

1. **O carimbo, depois do último commit de código e da leva de consertos dos bots.** `tests/` está na
   chave do carimbo (`MUTATION_STAMP_PATHS`, `bin/sdd:2417`), então a leva o invalida. A ordem do
   `CLAUDE.md`: abrir o PR, esperar todos os revisores, consertar numa leva só, rodar
   `./bin/sdd health` no worktree **uma vez** (39–64 min medidos em 2026-10) e mergear. Antes do
   `git worktree remove`, o mapa de assassinos (`.sdd/cache/mutation-killers.tsv`) volta ao checkout
   principal; o carimbo também volta quando a linha 6 do `./bin/sdd health --release` de lá estiver
   vermelha (`commands/sdd-plan.md`, *Before anything else*).
2. **O pull ocioso (decisão 2).** Depois do merge no GitHub, `git -C /home/joruge/repos/sdd_agents
   pull --ff-only` só quando `ps -eo pid,etime,cmd | grep -E 'bin/sdd (run|retry|close)'` vier vazio.
3. **O chore pós-merge, da `main`.** Apagar os 5 itens com `RESOLVED by` (prova:
   `git merge-base --is-ancestor <hash> main`), descer a catraca de 16 para 11 e sincronizar o
   espelho (`todo-to-github-issues`). Isso fecha #249, #257, #258 e #264 e abre as issues dos dois
   itens congelados nascidos nesta missão (o gêmeo do `--no-track` e a prosa congelada). O achado do
   relay (`ed78ff5`) sai resolvido pelo I5 antes de ganhar issue.
4. **A triagem depois do veredito** recebe 11 itens, todos congelados: os 9 de antes, mais o gêmeo do
   `--no-track` e a prosa congelada.
