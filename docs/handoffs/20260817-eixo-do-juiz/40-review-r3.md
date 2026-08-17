---
missao: 20260817-eixo-do-juiz
fase: REVIEW
rodada: r3
status: done
data: 2026-08-17
---

# Review — rodada r3 — o eixo do juiz

## TL;DR

**Fecha em A nos oito critérios, com a suíte verde e o catálogo em `70 caught of 70`.** As cinco
pendências que a r2 deixou (C2–C6) foram consertadas com prova, e a C1 — a CRITICAL do `CDPATH` que
tinha ficado a meio — já estava fechada por `d0a3b59` antes desta sessão começar.

Mas o que muda esta rodada é o que uma **auditoria adversarial independente sobre o diff inteiro**
achou depois: **duas HIGH que a r1 e a r2 não viram**, ambas dentro do campo que esta missão existe
para criar. Uma é uma resposta errada alcançável com uma única retentativa; a outra é um sensor
**falhando aberto** sobre a propriedade central do conserto que a própria r2 fez.

## O que fechou nesta rodada (com hash)

| # | Achado | Sev | Origem | Conserto |
|---|---|---|---|---|
| C1 | `CDPATH` colapsa todos os repos numa identidade | CRITICAL | r2 | `d0a3b59` (antes desta sessão) |
| C6 | um bare em `/x/.git` tem duas identidades; comentário promete sensor inexistente | LOW | r2 | `3ef0753` |
| C5 | asserção sem testemunha de leitura | MEDIUM | r2 | `3ef0753` |
| C4 | o par `help`/parsers mede a *frase* da morte, não a aceitação | MEDIUM | r2 | `3ef0753` |
| C2 | o gate confunde corrupção com "ainda não julgado" | HIGH | r2 | `b03d2f8` |
| C3 | a janela do `degenerate_axis` falsa-positiva num repo saudável | MEDIUM | r2 | `b03d2f8` |
| **F1** | **a janela conta SESSÕES onde o piso conta MISSÕES** | **HIGH** | **r3** | `b03d2f8` |
| **F2** | **a ordem-de-arquivo da janela não tem probe (falha aberta)** | **HIGH** | **r3** | `b03d2f8` |
| F3 | `docs/adr/0003` é o **sexto** lugar do schema, e descrevia a regra antiga | MEDIUM | r3 | `b03d2f8` |
| F4 | sinopse do `help` contradiz a flag na própria linha; README sem `kaizen --all-repos` | LOW | r3 | `b03d2f8` |
| F5 | `CONTEXT.md` D4 com o piso pré-I8 | LOW | r3 | `b03d2f8` |
| F6 | comentário diz ao contrário qual forma o escritor produz | LOW | r3 | `b03d2f8` |
| — | performance da cláusula nova: O(versões × linhas) → O(n log n) | — | r3 | `b03d2f8` |

## As duas HIGH que duas rodadas não viram

### F1 — a janela contava SESSÕES enquanto o piso conta MISSÕES

`bin/sdd:2632`. `guard.sufficient` é `missions_with_session >= 3`; o `degenerate_axis` existe para
explicar **esse** piso, e contava `sessions == 1`. As duas unidades discordam numa forma de linha que
**o próprio runner escreve**: duas sessões da MESMA missão numa versão do kit — a retentativa em laço
de `run_phase`, ou qualquer segundo `sdd run` sobre uma fase que não commita e não suja a árvore do
kit (a fase PR é exatamente essa forma, e é a linha do gemba do próprio ADR).

Medido com o runner real, três versões e a mais nova com duas sessões de uma missão:

```
{"degenerate_axis":false,"sufficient":false,"missions_with_session":1,"sessions":2}
```

`missions_with_session: 1` — o piso segue tão insatisfazível quanto antes — e ainda assim o campo diz
`false` e o `kaizen_axis_note` imprime a frase **zero vezes**. O humano lê um `sufficient: false` pelado
e espera missões que não podem ajudar: é a leitura errada que o ADR 0003 criou este campo para acabar,
e **uma retentativa bastava** para calar o sensor. Hoje conta `missions_on($sha) == 1`. Zero segue não
sendo um — versão só com escalada observou NADA, silêncio diferente com remédio diferente.

### F2 — a propriedade central do conserto N8 da r2 não tinha probe

`bin/sdd:2620`. "As últimas `guard_floor` versões **em ordem de ARQUIVO**" é todo o conteúdo do
conserto do N8. Degrade medido: `shas_in_file_order | sort` dentro da janela deixa **os dois sensores
verdes** — `check-kaizen.sh` rc 0 com zero FAIL, `check-autonomy.sh` rc 0. Sobrevivia porque toda
fixture que alcança a janela usava shas cuja ordem lexical **coincide** com a ordem de arquivo
(`s000d01..04`, `s000e01..05`, `s000f01..05`) — o regime do fixture satisfazendo a asserção em vez da
propriedade, exatamente o modo que o `CLAUDE.md` manda desconfiar.

Sob o degrade, um ledger com `zzz0001` antigo (2 missões) e `aaa0002..04` recentes lê `false`: o sha
antigo calando para sempre o que os recentes dizem — **o N8 verbatim, com a suíte verde**. A fixture
nova é descendente de propósito, então `sort` e `reverse` arrastam o antigo para dentro da janela e as
duas morrem. As três asserções juntas (duas ascendentes da r2 + esta) prendem recência à ordem de
arquivo e a nada mais.

## O resto, em uma linha cada

- **C2** (HIGH): `series="$(kaizen_series)"` descartava o rc, e o errexit está **desligado** dentro de
  todo gate (todo chamador usa `gate_KAIZEN || gate_rc=$?`). Ledger ilegível virava string vazia e o
  gate respondia `no verdict for kit  yet` — o espaço duplo era o único sinal. Medido em `--dry-run`:
  chegava a montar a linha de comando do `claude`, isto é, **gastaria uma sessão opus** sobre um
  arquivo que ninguém conseguiu ler. Hoje `ledger_parses` é UMA definição para os dois leitores, o
  gate publica `GATE_KAIZEN_UNREADABLE` e `cmd_kaizen` morre antes da sessão. O comentário do
  `kaizen_axis_note` que jurava "reportar corrupção é trabalho do gate, e ele ainda o faz" passou a
  ser verdade.
- **C3** (MEDIUM): janela **e** nenhuma versão do histórico tendo alcançado o piso. Alcançá-lo uma vez
  é fato **permanente** do repositório, então travar a explicação nisso é correto — ao contrário de
  "algum sha um dia comprou duas sessões", coincidência que nada diz sobre atingibilidade.
- **C4** (MEDIUM): o par lia `grep -c 'unknown'`, a *frase* da morte. Dois fail-open medidos: trocar
  os dois braços por `*) : ;;` ficava verde (um parser que aceita tudo não diz "unknown" sobre nada, e
  o typo `--allrepos` que o par existe para caçar passava), e matar `--all-repos)` com outra frase
  também. Hoje lê rc 0 no token anunciado e exige rejeição do near-miss `<token>x`.
- **C5** (MEDIUM): `[.guard.sessions, .excluded.no_repo]` numa invocação (`0 3`) — a testemunha diz que
  as três linhas foram vistas, só então o `0` significa "vista e recusada".
- **C6** (LOW): `--is-bare-repository` responde sobre o **ponto de entrada**. Um bare em `/x/.git` diz
  `true` lido de si e `false` lido de uma worktree sua — medido, `/tmp/c6r/hidden/.git` contra
  `/tmp/c6r/hidden`, um repositório com duas identidades. Trocado por `core.bare`, que mora na config
  do common dir. E o comentário de `def mission_key` prometia que o `check-autonomy.sh` compara os dois
  leitores: **não comparava**, e o mutante do catálogo reescreve as duas grafias de uma vez (`/g`),
  então nem ele os veria divergir. O sensor foi escrito, não o comentário apagado.
- **F3** (MEDIUM): o ADR 0003 era o **sexto** lugar que descreve o schema — e o único que o runner
  **cita na saída**, e o único que a r2 deixou descrevendo a regra antiga ("every sha in the slice").
  O item do `TODO.md` que conta esses lugares foi de cinco para seis e de 4× para 5× de preço cobrado.
- **F4/F5/F6** (LOW): sinopse do `help` não contradiz mais a flag na própria linha; README ganha
  `kaizen --series --all-repos`, que é a metade que chega ao juiz; `CONTEXT.md` D4 volta a dizer
  `missions_with_session`; e o comentário de `ledger_row_no_repo` dizia **ao contrário** qual forma o
  escritor produz — ele sempre passa `--arg repo`, então chave-ausente é a única que ele não emite.

## Sabotagem adversarial

**9 degrades, 9 vermelhos**, cada um na asserção dona da regra, e cada probe provando **primeiro** que
sabotou o que dizia sabotar (âncora `2 -> 0` nos dois braços do parser, `2 -> 1` no fork do
`mission_key`, `sort`/`reverse` conferidos na linha):

| Degrade | Asserção que morre |
|---|---|
| bare por ponto de entrada (`--is-bare-repository`) | `identity: and a worktree of that bare repo…` |
| os dois parsers aceitam tudo (`*) : ;;`) | `BOTH parsers accept…` |
| `--all-repos)` rejeita com outra frase | `BOTH parsers accept…` |
| `mission_key` só-slug nos DOIS leitores | `mission identity:…` |
| `mission_key` **forkado** (um leitor só) | `mission identity:…` |
| a leitura da série que não aconteceu | `unattributable shapes: and standing outside…` |
| janela contando SESSÕES | `axis unit:…` |
| janela com `sort` | `axis order:…` |
| janela com `reverse` | `axis order:…` |

**O que a sabotagem NÃO fecha, registrado em voz alta:** com `ledger_row_no_repo` sempre `true` a
asserção da C5 segue verde; quem a cobre são as **58 irmãs** que ficam vermelhas. A recusa em bloco é
pega no arquivo, não nesta linha — e isso é diferente de estar coberta.

## O que foi refutado / não virou conserto

- **Nada foi refutado nesta rodada.** Os doze achados foram medidos antes de consertados, e os seis do
  auditor independente reproduziram-se todos com o runner real.
- ⚠️ **A cláusula nova nasceu O(versões × linhas)** e isso foi pego na própria rodada, medindo em vez
  de supondo: 3000 linhas / 750 versões custavam **1,40 s**, e o repo que **constrói** o kit é
  precisamente onde o número de versões cresce sem limite (uma por sessão, para sempre). Reescrita com
  um `group_by` único: **0,23 s**. O `group_by` ordena, e aqui isso é seguro porque só o **máximo**
  interessa e máximo não tem ordem — a propriedade de ordem-de-arquivo vive em `$order`, intocada.
- ⚠️ **E a reescrita de performance quebrou a âncora do mutante da C3**, porque a cláusula deixou de
  ser `all($order[]; …)` e passou a ser `$best_reach`. A suíte reprovou com
  `CATALOGUE-BROKEN: KAIZEN_degenerate_axis_reach_blind` e `69 caught of 70` — **falha honesta**, a
  guarda do harness fazendo exatamente o trabalho dela, e a mesma armadilha que o apóstrofo de
  `mut_LEDGER_repo_root_common_parent` armou na r2. Consertar significou reancorar o mutante e provar
  de novo que ele morde (2 linhas, `bash -n` ok) — não relaxar a guarda. Fica registrado porque este
  handoff afirmou "suíte verde" **antes** desta rodada da suíte terminar: a afirmação estava certa por
  antecipação e errada por método, e o método é o que o gate mede.
- **Nada foi para o `TODO.md` como achado novo:** os doze cabiam no diff desta missão. O que o
  `TODO.md` recebeu foi **escrituração**: o item do schema passou a contar seis lugares e cinco
  cobranças (F3), e as **três** âncoras `bin/sdd:` que esta rodada deslocou voltaram ao lugar
  (`:972 → :989`, `:2580 → :2738`, `:2675/:2828 → :2757/:2924`).

## Estado ao fim da rodada

- **Commits:** `3ef0753` (C6/C5/C4 + 1 mutante), `b03d2f8` (C2/C3/F1–F6 + 4 mutantes + prosa em 6
  lugares + escrituração do `TODO.md`), mais o commit deste handoff.
- **Suíte:** ✅ **VERDE.** `bash tests/run-all.sh` → `suite green`, `score: 70 caught, 0 known gap(s),
  of 70`, rc 0. `shellcheck -S warning` limpo em `bin/sdd` **e** `tests/*.sh`. Catálogo 65 → 70.
- **Métricas do `00-missao.md`:** todas verdes, medidas ao vivo — `degenerate_axis: true` /
  `sufficient: false` no repo do kit, ADR 0003 citado na saída, `--all-repos` diferencial, worktree e
  `no-repo` verdes, catálogo ≥ 60 (é 70).
- **Árvore limpa. Nada empurrado, nenhum PR aberto.**

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | A | Os doze achados fecharam, e a disciplina de definição única foi **estendida** em vez de diluída: `ledger_parses` nasceu para acabar com as duas cópias de "o ledger é legível" (uma que morria alto, outra que nunca checava), `missions_on` unifica a unidade das duas cláusulas do eixo, e `mission_key` foi **movido** para cima do `degenerate_axis` em vez de copiado — jq resolve `def` só depois de aparecer, e uma segunda grafia da pergunta era exatamente o defeito que o parágrafo dela descreve. `shellcheck -S warning` limpo nos dois alvos, `bash -n` ok. A cláusula que nasceu quadrática foi medida e reescrita na mesma rodada, com o número antes/depois no comentário. |
| Type Safety | A | A shape do contrato fecha: os dois produtores da série seguem comparados como conjuntos de chave, `degenerate_axis` é sempre booleano (janela vazia, fatia só-escalada, ledger vazio ⇒ `false`, nunca `null`), `guard.sufficient` e o campo exposto seguem na binding única `$observed`, e o piso vem de `guard_floor`. A C2 fechou o último buraco de tipo do juiz: o rc de `kaizen_series` agora é **lido** em vez de descartado, então string vazia não pode mais impersonar uma série. E a unidade do `degenerate_axis` passou a ser a mesma do piso que ele explica — F1 era, no fundo, dois tipos de "quanto foi observado" com o mesmo nome. |
| Error Handling | A | Direção segura preservada e ampliada. O caminho em que **corrupção virava "pendente"** está fechado nas duas pontas: `kaizen_series` imprime a sentença uma vez e devolve rc, o gate publica `GATE_KAIZEN_UNREADABLE` com um `GATE_WHY` que nomeia o remédio, e `cmd_kaizen` **morre antes da sessão** — ledger corrompido não é estado que uma sessão conserte (o arquivo vive em `$HOME`, fora do repo), então abrir uma só gastaria opus para chegar na mesma frase. Medido: rc 1, zero sessões, e o stub barulhento silencioso. `ledger_repo_root` segue devolvendo vazio em vez de morrer, e os cinco baldes de `excluded` seguem contando o que saiu. |
| Security | A | Varredura determinística sobre o diff completo (`git diff main...HEAD`): nenhum segredo, nenhuma entrada de rede, nenhum `eval` de dado externo. A superfície de ambiente que a C1 abriu está fechada **e sondada** — o par diferencial do `CDPATH` carrega um piso que prova que o veneno está ARMADO no shell antes de qualquer conclusão, que é o que separa asserção de decoração numa regra do ambiente. A troca de `--is-bare-repository` por `core.bare` não amplia superfície: lê config do repositório, não caminho do chamador. O `repo:` do ledger pode carregar caminho de cliente — já era assim, e a doc repete por que o arquivo mora em `$HOME` e nunca é commitado. |
| Performance | A | `jq` sobre JSONL de dezenas de linhas no uso real. A janela é O(3 × linhas). A cláusula nova do histórico **nasceu** O(versões × linhas) e isso foi medido, não suposto: 3000 linhas / 750 versões custavam 1,40 s, e o repo do kit é justamente onde as versões crescem sem limite. Reescrita com um `group_by` único, **0,23 s** no mesmo fixture — a mesma ordem de grandeza dos 0,19 s que a r1 mediu antes de a missão acrescentar campo nenhum. As asserções novas somam um `git worktree add` e um `commit-tree` de plumbing em `/tmp`; a suíte com 70 mutantes segue no orçamento de sempre. |
| Test Coverage | A | 70 mutantes, `0 known gap(s)`, cinco novos nesta rodada — um por regra nova, incluindo os dois que a auditoria independente exigiu (`session_unit`, `window_sorted`). Nove degrades adversariais, nove vermelhos, cada um na asserção dona da regra, e **cada probe provando primeiro que sabotou o que dizia sabotar** — a regra que esta casa já quebrou quatro vezes concluindo sobre probe vazio. Os dois fail-open que a r2 deixou (C4 inteira, C5 pela metade) estão fechados, e o fail-open que **nenhuma das duas rodadas viu** — a ordem-de-arquivo da janela, F2 — está fechado com fixture descendente que mata `sort` e `reverse`. O que a sabotagem não alcança está escrito em voz alta em vez de contado como coberto. |
| Documentation | A | O schema da série está em passo nos **seis** lugares que o descrevem, e o sexto é a novidade: `docs/adr/0003` era o único que o runner **cita na saída** e o único que a r2 deixou descrevendo a regra antiga — um humano seguindo a citação lia uma regra que o código não implementa mais. Hoje `bin/sdd`, `docs/pipeline.md`, `agents/sdd-kaizen.md` + a cópia `.claude/` byte-idêntica, `CONTEXT.md` e o ADR dizem a mesma coisa, e a **frase que o runner imprime** também ("and none ever reached the floor") — nenhuma delas repetindo o número do piso, para não criar uma sétima cópia dele. Três comentários que prometiam sensor ou afirmavam o contrário do código foram corrigidos **medindo**: o do `mission_key` ganhou o sensor que prometia, o do `kaizen_axis_note` virou verdade, o do `ledger_row_no_repo` foi desinvertido. |
| **Overall** | **A** | As cinco pendências da r2 fecharam com prova, e a C1 já estava fechada. O que dá o A não é isso: é que a auditoria adversarial independente sobre o diff inteiro achou **duas HIGH dentro do campo que esta missão criou** — uma resposta errada alcançável com uma retentativa (F1) e um sensor verde sobre a propriedade central do conserto da rodada anterior (F2) — e as duas fecharam com asserção diferencial, mutante e sabotagem vermelha. A rodada que acha defeito no conserto da anterior e o fecha medindo é o critério de parada funcionando, não sendo contornado. Suíte verde, `70 caught of 70`, árvore limpa, métrica da missão intacta. |
