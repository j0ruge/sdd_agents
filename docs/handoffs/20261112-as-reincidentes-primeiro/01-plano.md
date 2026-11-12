---
missao: 20261112-as-reincidentes-primeiro
data: 2026-11-12
---

# Plano — as reincidentes primeiro (lote 1 de zerar a catraca)

> **Teste de autocontenção:** uma sessão nova, sem nenhuma memória da conversa que gerou este
> plano, lendo apenas `00-missao.md` + `01-plano.md` + `checkpoint.md`, consegue executar?
> Se a resposta for "só se souber X", **X vai escrito aqui**.

## Como esta missão é executada (leia antes de tudo)

Você é uma sessão interativa nova, sem memória do planejamento. **Não rode `sdd run`, `sdd retry`
nem `sdd kaizen`** nesta missão (decisão 5 do `00-missao.md`): você executa a tabela do
`checkpoint.md` à mão, pelo `superpowers:executing-plans` (ou
`superpowers:subagent-driven-development`), com `superpowers:test-driven-development` em cada
incremento.

**Onde.** Tudo acontece no worktree `/home/pc_admin/repos/sdd_agents-zerar-catraca`, na branch
`fix/as-reincidentes-primeiro`. O checkout principal do kit, `/home/pc_admin/repos/sdd_agents`,
**não pode ser tocado**: todo `sdd run` de outro repositório desta máquina executa aquele checkout e
para com `KIT-TOUCHED` se o `HEAD` ou o `git status --porcelain` dele mudar. Então:

- todo comando roda como `cd /home/pc_admin/repos/sdd_agents-zerar-catraca && …`; nunca um caminho
  relativo num redirecionamento, nunca um arquivo de rascunho fora do worktree ou do seu scratchpad;
- dentro do worktree o runner é `./bin/sdd`, nunca o `sdd` do PATH (que é o checkout principal e
  instalaria os `agents/` dele por cima dos seus);
- nunca `git pull` no worktree nem no checkout principal; `git fetch` é livre.

**Primeiro ato.** No worktree: `git branch --show-current` → `fix/as-reincidentes-primeiro`;
`git status --short` → vazio; `grep '^aprovacao:' docs/handoffs/20261112-as-reincidentes-primeiro/00-missao.md`
→ `aprovacao: humano-<data>` (o `sdd approve` do aceite escreve o valor, corta a branch e commita a
pasta; neste arquivo o campo aparece vazio porque foi escrito antes). **Se o campo está vazio, a
pasta não está commitada ou a árvore está suja, pare e diga ao humano** — não aprove, não commite o
plano você. O `TODO.md` traz, commitadas pelo planejamento, três linhas `RECURRED 1:
sdd_agents/20261112`, que são o que faz serem 13 reincidentes: `grep -c '^  RECURRED [0-9]*:'
TODO.md` → `13`. Depois guarde o estado do checkout principal, para comparar no fim:
`git -C /home/pc_admin/repos/sdd_agents rev-parse HEAD` (era `a48cf3c` no planejamento; pode ter
andado, o que importa é não mudar **durante** a sua sessão por ato seu) e
`git -C /home/pc_admin/repos/sdd_agents status --porcelain` → vazio. Anote os dois em
`checkpoint-notas.md`.

**O worktree é um `git worktree` ligado** ao checkout principal: seus commits, o `fetch` e o `push`
gravam objetos e refs no `.git` comum, e isso é esperado — não move o `HEAD` nem o
`status --porcelain` de lá, que é o que a guarda de kit compara. `./bin/sdd` resolve o próprio
`SDD_HOME` pelo caminho do executável (o worktree), e cada `tests/check-*.sh` resolve a raiz pelo
próprio caminho: chamados pelo caminho do worktree, nenhum toca o checkout principal.

**O laço de cada incremento** (na ordem da tabela; um por vez; um commit por incremento):

1. Leia a seção do incremento abaixo e o item do `TODO.md` que ele fecha (procure pelo título, que
   está na tabela do `00-missao.md`; o corpo do item traz o caso medido).
2. **Red.** Escreva primeiro o probe no sensor nomeado, com o texto **exato** da asserção do Check
   (o Check faz `grep` da linha `  ok    <asserção>`). Rode o sensor e veja a linha `  FAIL  …` na
   stderr. Vermelho pelo motivo certo: o `FAIL` tem de ser o do probe novo.
3. **Green.** Faça a mudança. Rode o sensor de novo.
4. **Sabotagem.** Desfaça à mão a parte da mudança que o probe lê (uma frase, uma linha) e confirme
   que o sensor volta a vermelho; restaure. Para mudança em `bin/sdd` (I9 a I14), escreva também o
   mutante no catálogo (`tests/check-mutation.sh`: uma função `mut_<slug>` e o slug na lista, no
   molde de `mut_COORD_linker_unlocked`) e prove-o com
   `tests/check-mutation.sh --only <slug> <sensor>.sh` → rc 0 (pego). É dica, não veredito.
5. **Vizinhança.** Antes do commit, na raiz do worktree:
   - `shellcheck -S warning <cada arquivo de bin/ ou tests/ tocado>` → sem saída;
   - `bash tests/check-todo.sh --anchors TODO.md` → `0 off target`. Você moveu linhas de um arquivo
     que o `TODO.md` ancora (`` `arquivo:N` (`símbolo`) ``): item cuja âncora saiu do alvo é
     reancorado **no mesmo commit** (só o número da linha muda);
   - `bash tests/check-mutation.sh --anchors` → rc 0 (segundos). Mutante cuja âncora você quebrou é
     consertado no mesmo commit;
   - mexeu em `agents/*.md`? `./bin/sdd install --force` sincroniza o espelho rastreado
     `.claude/agents/` — nunca `cp`, nunca edição direta — e o espelho entra no commit;
   - mexeu num componente descrito em `.claude/rules/anatomia-do-agente.md` (o plano diz quais
     incrementos)? A seção correspondente muda no mesmo commit. Mudou contrato de artefato?
     `templates/`, `docs/pipeline.md` e o agente afetado no mesmo commit.
6. **A suíte rápida:** `bash tests/run-all.sh` → rc 0, última linha `suite green`. Medido em
   `a48cf3c`: 583 s (quase dez minutos, com outros sensores rodando ao lado). Rode-a **em segundo
   plano** e espere a última linha; enquanto itera no Red/Green, rode só o sensor do incremento
   (segundos a minutos). Vermelho para a linha: conserte antes de seguir. Um sensor vermelho sai
   com rc diferente de 0 e imprime `  FAIL  …` na stderr.
7. **Check.** Rode o comando da célula do `checkpoint.md` e confira o esperado, byte a byte.
8. **Commit**, `<tipo>(<escopo>): <o quê>` em pt-BR com o porquê no corpo (`git log --oneline -15`
   mostra o estilo), só os caminhos do incremento (`git add -- <caminhos>`, nunca `-A`).
9. **Checkpoint, último ato:** na linha do incremento, `pending` → `done` e o hash curto **nu** (sem
   crase) na coluna Commit; `atualizado:` com a saída de `date '+%Y-%m-%d %H:%M'` rodado na hora;
   uma linha em `checkpoint-notas.md` (o arquivo já existe; `>>`, no formato
   `- <data hora> · \`<ID>\` · <o que aconteceu>`) se houve desvio ou medida a guardar. Commite o
   checkpoint e as notas num commit próprio (`chore(missao): …`). O commit do incremento usa
   `docs(...)` para prosa de contrato, `test(...)` para sensor e `fix(runner)` para `bin/sdd`.

**O que para a linha (Jidoka).** Suíte vermelha; âncora do `TODO.md` fora do alvo; mutante que não
se aplica; um Check que não dá o esperado; qualquer mudança no checkout principal. Pare, diga o que
quebrou e onde, conserte, e só então siga. Incremento que não fecha em uma sessão vira `blocked` na
tabela, com nota, e o humano decide.

**Achado novo** durante a execução não vira incremento: vai para o `TODO.md` (item novo move
`todo-findings` em `tests/health-baseline.txt` no mesmo commit; achado já aberto ganha entrada na
`RECURRED` do item, sem mover a catraca; formato em `templates/todo.pt-BR.md`). Cada item novo
soma um aos números deste plano que dizem `86` (a contagem) e `73` (depois do chore): eles valem
para a execução sem achado novo.

**O que os gates do runner leriam, e o que os substitui aqui.** Ninguém chama os gates nesta
missão; eles continuam podendo ser lidos por `./bin/sdd status <missão>` e `./bin/sdd why <missão>
<FASE>`, e isto é o que respondem:

| Gate | O que ele lê | Nesta missão |
|---|---|---|
| `gate_PLAN` | `aprovacao:`, `branch:`, `adr:` do `00-missao.md` | fechado pelo `sdd approve` do aceite, antes de você abrir (confira no primeiro ato) |
| `gate_EXEC` | a tabela sem `pending`, o `TEST_CMD` (`tests/run-all.sh`) verde, e `20-handoff-exec.md` com `## TL;DR` de até 20 linhas (`bin/sdd`, função `gate_EXEC`) | os passos 6 e 9 do laço; o handoff é escrito no I15 |
| `gate_QA`, `gate_REVIEW`, `gate_DOCS` | `30-handoff-qa.md`, `40-review-r<N>.md`, `45-docs.md` (e, o último, a entrada do `KAIZEN_LOG.md` que cita a missão) | **não são escritos aqui**: a revisão é a do PR (bots e humano), e a documentação viva é atualizada dentro de cada incremento e no I15 |
| `gate_PR` | PR aberto, `50-pr.md`, e o carimbo de mutação | o PR é aberto à mão; o carimbo não é exigido (seção seguinte) |

`./bin/sdd why <missão> EXEC` roda a suíte inteira antes de responder: use-o uma vez, no fim.

**Depois do I15.** `superpowers:finishing-a-development-branch`: `git push -u origin
fix/as-reincidentes-primeiro`, PR contra `main` com `gh pr create` — **só** a opção de push e PR
da skill: nunca o merge local, nunca remover o worktree (as duas agem no checkout principal). O corpo
do PR, em pt-BR, traz: o que mudou, como verificar, a tabela dos 13 itens com o hash de cada um, as
Pendências do `00-missao.md`, e a frase "sem carimbo de mutação por decisão do humano: o
`sdd health` roda quando a catraca zerar".
Espere **todos** os bots (Codex, CodeRabbit, Copilot), conserte numa leva (cada conserto de código
com o seu probe), e deixe o merge para o humano. **Não rode `./bin/sdd health`.**

## O que fica sem carimbo (consequências da decisão 6, medidas no código)

- **O que o `gate_PR` exige.** Num repositório com `tests/check-mutation.sh`, o `gate_PR` reprova
  sem o carimbo do catálogo para a chave do conteúdo rastreado de `bin/ tests/ templates/ config/
  agents/` (`bin/sdd`: `gate_PR`, `mutation_stamp_key`, `mutation_stamp_valid`; o motivo sai em
  `GATE_PR_STAMP_WHY` e o `sdd run` para com rc 2 nomeando `./bin/sdd health`). Só o `sdd run`, o
  `sdd status` e o `sdd why` avaliam esse gate. Como o PR desta missão é aberto à mão, nada o
  barra; `./bin/sdd why <missão> PR` vai dizer que falta o carimbo, e isso é esperado.
- **O que substitui o catálogo em cada incremento.** A suíte rápida (`tests/run-all.sh`, 15 dos 16
  sensores), que já roda `tests/check-mutation.sh --anchors` — cada mutante do catálogo (`anchors:
  all 792 mutants still apply and leave valid code` em `a48cf3c`) ainda se aplica e deixa bash e Python válidos; e, para cada mutante **novo**,
  `tests/check-mutation.sh --only <slug> <sensor>.sh`. As duas são dica: nenhuma prova que os
  mutantes **antigos** continuam sendo pegos depois de um sensor mudar. Para isso existe
  `tests/check-mutation.sh --touched <rev>` (os mutantes cujo último assassino é um sensor tocado
  desde `<rev>`, cada um só contra ele); rode `tests/check-mutation.sh --touched a48cf3c --list`
  no fim e anote a seleção nas notas — rodá-la inteira é opcional, e também é dica.
- **O que a `main` passa a carregar.** Conteúdo cuja chave nenhum catálogo mediu. Enquanto durar:
  `./bin/sdd health --release` tem a linha 6 vermelha ("mutation stamp absent or stale"); toda
  missão do kit que rode por `sdd run` para no `gate_PR` com rc 2 pedindo o carimbo; e um mutante
  antigo que deixou de ser pego só aparece no `sdd health` do fim da série, somado aos dos lotes
  seguintes — mais difícil de atribuir a um commit. O `sdd health` continua rodando o catálogo
  inteiro quando for chamado (a chave nova não está entre as medidas verdes, então ele não pula).
- **Nada disso bloqueia este plano.** Fica como pendência do humano no `00-missao.md`.

## Contexto verificado (não re-descobrir)

Medido no worktree em `a48cf3c`, 2026-11-12, salvo indicação.

- Base e contagem — `tests/check-todo.sh --count TODO.md` → `86`; `tests/health-baseline.txt:26` →
  `todo-findings 86`; `tests/check-todo.sh --check TODO.md` rc 0; `--anchors TODO.md` →
  `anchors: 86 measured, 0 off target`; `grep -cE 'RESOLVED by [0-9a-f]{7,40}' TODO.md` → `0`.
- Config do kit — `.sdd/config.sh`: `TEST_CMD="tests/run-all.sh"`, `DEFAULT_BRANCH="main"`,
  `OUTPUT_LANG="pt-BR"`, `JIRA_ENABLED=false`, `ADR_CHECK="block"`, `E2E_CMD=""`.
- Idioma — `bin/`, `agents/`, `commands/`, `docs/*.md`, `tests/` são **inglês** (sensor
  `tests/check-lang.sh`; um `docs/*.md` novo entra na superfície por glob, sem lista a mover).
  `templates/`, `TODO.md`, `KAIZEN_LOG.md`, `docs/handoffs/` e as mensagens de commit são pt-BR.
- Tempo dos sensores, rodados em paralelo — `check-templates.sh` 1 s; `check-todo.sh` 5 s;
  `check-hat.sh` 5 s; `check-dry-run.sh` 11 s; `check-adr.sh` 12 s; `check-preflight.sh` 115 s;
  `check-gates.sh` 153 s. Todos rc 0. Nenhum sensor novo nasce nesta missão, então os pisos de
  `tests/run-all.sh` (`step_timeout`, `LINT_FLOOR`) não se movem.
- Formato da saída — todo sensor imprime `  ok    <asserção>` na stdout e `  FAIL  <asserção>` na
  stderr. `check-hat.sh` usa `pass "<asserção>"` / `fail "<asserção>"`; as asserções de prosa têm
  prefixo `command:` (para `commands/sdd-plan.md`) ou `hat:` (para `agents/*.md`); o sensor já tem
  outros (`boot:`, `release:`), e o I6 acrescenta `doc:`.
- Como o `check-hat.sh` prova prosa — uma função `*_probes` recorta a seção com `awk` e exige
  literais com `grep -qF`; modelo: `command_branch_cwd_probes` (`tests/check-hat.sh`, perto da
  linha 643). As funções são chamadas numa **lista** no fim do arquivo (linhas 978–991:
  `census_probes … release_stamps_probes`, depois `selftest || exit $?`); probe novo entra numa
  função existente ou numa nova **acrescentada à lista**.
- `commands/sdd-plan.md` (215 linhas) — seções: `## Before anything else` (passos 1–4), `## Then`
  (a delegação ao `sdd-planner`, linha 74), `## Relaying the grill to the human` (os marcadores
  do relay; "Long work between two questions" na linha 131; "Approval." na 140),
  `## When the artifacts exist` (passo 3 do aceite nas linhas 148–188; a frase "Only the human's
  answer to that question approves" na 186).
- `agents/sdd-planner.md` (289 linhas) — frontmatter linha 7:
  `disallowedTools: "ScheduleWakeup, Monitor"`; linha 41: ``Invoke `Skill(grill-with-docs)`.``; o
  parágrafo "When you run as a subagent…" fica no fim do § 1. Os outros sete chapéus também vetam
  o `Monitor` e **não mudam** aqui.
- O espelho — `.claude/agents/sdd-*.md` é rastreado no kit (`git ls-files .claude`), e
  `./bin/sdd install --force` é quem o sincroniza a partir de `agents/`.
- Skills do grill — a lista de skills desta máquina tem `grilling` e `domain-modeling`; não tem
  `grill-with-docs` (ela traz `disable-model-invocation: true`). `bin/sdd:7175`:
  `KIT_THIRD_PARTY_SKILLS="codereview ticket qa-report qa-execution grill-with-docs kaizen-software ddd"`
  — fica como está (fora de escopo).
- `templates/pr-body.md:26` — `**Sensores novos** (rodam no CI a partir deste PR):`, frase fixa.
  `agents/sdd-publisher.md:61` — "the tests and specs that start running in CI from this PR
  onwards". Nenhum gate lê essa linha (`grep` em `bin/sdd` e `tests/` só acha esses dois sítios).
  `tests/check-templates.sh:441–448` prova o `pr-body.md` com `check pr-body.md '<regex>' "<rótulo>"`,
  que imprime `  ok    pr-body.md: <rótulo>`.
- `tests/check-todo.sh` — `lint_todo()` (linha ~768) chama `todo_awk <arquivo> <cap> lint`; as
  regras moram no `awk` de `todo_awk`; o `selftest()` (linha ~934) agrupa probes por regra e
  imprime `  ok    rule: <nome> (N probe(s))`. `bash tests/check-todo.sh` sem argumento roda o
  selftest **e** mede o `TODO.md` do repo (15 linhas `  ok    ` hoje). O `TODO.md` do kit **não** numera itens e cita PRs
  como `#N`; o do `magic_tutor` numera (`**57. …**`).
- `bin/sdd` (12 708 linhas), funções por nome, com a linha de hoje só como dica:
  - `main()` ~12267: `coordination_enter "$@"` e depois um `case "$subcmd"`; `help|--help|-h` só
    é lido na **primeira** posição.
  - `cmd_install()` ~6079: `if [ "${1:-}" = "--force" ]; then force=1; fi` e mais nada; grava
    `.sdd/config.sh`, `docs/handoffs/`, o `TODO.md` e os agentes. A base: `git symbolic-ref
    --quiet --short refs/remotes/origin/HEAD`, e vazio cai em `git branch --show-current`
    (~6093–6095).
  - `cmd_link_agents()` ~12116: não lê argumento nenhum; escreve só no repositório do cwd
    (`git rev-parse --show-toplevel`) e recusa o próprio kit. O executável `bin/sdd-link-agents`
    termina em `exec "$SDD_HOME/bin/sdd" link-agents "$@"`: entra pelo mesmo `main()`.
  - `coordination_enter "$@"` (primeira linha do `main()`) é a admissão por `flock` do checkout:
    não instala nem liga nada, só pode recusar com `CHECKOUT-BUSY`. `coordination_owner` imprime o
    dono vivo do checkout (é o que a face `--no-gates` do status já mostra).
  - `log_dir` → `$REPO_ROOT/.sdd/logs/<missão>`; o `log=` do journal é esse caminho **absoluto**
    terminado em `<FASE>-<carimbo>-<sid8>.json`.
  - `hat_status_lines [-z] [root]` (~4618) é o leitor de `git status --porcelain` da casa.
  - Os outros parsers já recusam opção desconhecida: `cmd_status` ("unknown status option"),
    `cmd_run`, `cmd_retry`, `cmd_health`, `cmd_autonomy`, `cmd_kaizen`, `cmd_adr`.
  - `cmd_approve()` ~8952: lê `adr:` com `frontmatter "$m" adr`; quando é caminho de arquivo que
    existe, soma-o a `paths` e commita (`chore(missao): plan … approved by the human`). O
    `sdd adr new` escreve `- **Status**: proposed (<ticket ou —>, <data>)` (`bin/sdd:8672`).
  - `cmd_status()` ~7951: a face `--no-gates` lê só o disco (artefatos, `status_increments`, as 5
    últimas linhas do `pipeline.log`); a face completa roda `gate_<FASE>` para cada fase, em
    silêncio até o gate voltar. `resolve_mission` (~340–353) morre com
    `mission '<x>' not found in <HANDOFF_DIR>/`.
  - `run_phase()` ~5415: o stream da sessão é
    `.sdd/logs/<missão>/<FASE>-<AAAAMMDD-HHMMSS>-<sid8>.stream.jsonl` (o `.json` irmão é o log); a
    linha da sessão no journal (`.sdd/logs/<missão>/pipeline.log`) só é escrita **no fim**, por
    `pipeline_log_line "… $phase  agent=…  session=…  rc=…  log=$logfile"` (~5628). Uma sessão
    morta com o runner deixa o stream sem linha que o cite.
  - `boot_prompt()` ~3286: monta o prompt de toda fase; a linha `Why this phase:` (~3375) é o
    modelo de linha condicional.
  - `pipeline_log_line` é **chamada**, nunca `$( )`; e captura `x="$(cmd)"` na região do
    `sdd health` precisa de guarda (`CLAUDE.md`, "Ao mexer no runner").
- Onde os probes de `bin/sdd` moram — `tests/check-preflight.sh` tem as seções de `sdd install`
  (`== sdd install with the real kit (positive control) ==`, e a asserção "a DEFAULT_BRANCH that
  exists on origin is accepted"); `tests/check-gates.sh` tem `== sdd approve ==` e
  `== sdd status --no-gates ==`; `tests/check-dry-run.sh` lê os boot prompts projetados.
- ⚠️ **Nunca rode `sdd install --help` nem `sdd link-agents --help` fora de um repositório de
  rascunho em `mktemp -d`** antes do I9: hoje eles instalam e ligam de verdade.
- ⚠️ Pitfalls do `CLAUDE.md` que mordem aqui: `printf … | grep -q` sob `pipefail` (use herestring);
  `cd` relativo dentro de `$(...)` leva `CDPATH=''`; o `awk` é o `mawk`, orientado a byte (classe
  negada só com ASCII); comentário `#` dentro de bloco continuado por `\` quebra o comando.

## Arquitetura da mudança

Treze consertos locais, sem contrato novo entre módulos. Três famílias:

1. **Prosa de contrato** (`commands/sdd-plan.md`, `agents/sdd-planner.md`, `agents/sdd-publisher.md`,
   `templates/pr-body.md`, um `docs/finding-prs.md` novo): a frase muda e um probe do
   `tests/check-hat.sh` (ou do `check-templates.sh`) passa a exigir os literais dela, na seção certa.
2. **Sensor** (`tests/check-todo.sh`): uma regra nova no `awk`, com probes no `selftest()`.
3. **Runner** (`bin/sdd`): quatro comandos ganham comportamento (`install`, `link-agents`,
   `approve`, `status`) e o `boot_prompt` ganha uma linha condicional. Cada um com probe no sensor
   que já cobre o comando e mutante no catálogo. Nenhum gate novo, nenhuma chave de config nova,
   nenhum evento novo no ledger.

O I15 fecha o ciclo no `TODO.md` (13 `RESOLVED by`), no `KAIZEN_LOG.md` e na pasta da missão.

## Incrementos

A tabela executável vive em `checkpoint.md`. Aqui fica o **porquê** de cada fatia. O texto da
asserção de cada probe é o da célula do Check, **copiado dela**.

### I1 — A: o `/sdd-plan` nomeia a saída quando o agente `sdd-planner` não está registrado

**O quê:** em `## Then`, logo depois do parágrafo "Delegate to the `sdd-planner` subagent…", um
parágrafo para quando o tipo de agente não existe na sessão (`Agent type 'sdd-planner' not found`):
a lista de tipos é lida quando a sessão abre, então o agente instalado depois, ou instalado num
diretório filho de onde a sessão abriu, não aparece. Saída preferida: dizer isso ao humano e pedir
que reabra a sessão **na raiz do alvo**, depois de `sdd install && sdd-link-agents`. Reserva, só se
o humano escolher seguir: delegar a um agente genérico mandando-o ler `agents/sdd-planner.md` pelo
caminho absoluto como contrato, com os três vetos do `permissionsDeny` do chapéu **escritos no
briefing** (`git push`, `gh pr create`, `gh pr merge`), porque o agente genérico não os carrega, e
com uma linha ao humano dizendo que o grill corre sem o chapéu registrado.
**Onde:** `commands/sdd-plan.md`, `tests/check-hat.sh`.
**Como (TDD):** probe novo numa função `command_*_probes` (nova, na lista do fim), lendo a seção
`## Then`; literais sugeridos: `not registered`, `reopen the session at the repository root`,
`sdd install && sdd-link-agents`, `permissionsDeny`. Falha hoje porque a seção não tem nenhum.
**Check:** `o=$(bash tests/check-hat.sh 2>&1); grep -c '^  ok    command: /sdd-plan names the way out when the sdd-planner agent type is not registered' <<< "$o"` → `1` (hoje `0`)
**Sensor durável:** o probe em `tests/check-hat.sh`, que roda na suíte.
**Reversível por:** `git revert` do commit.

### I2 — B: pergunta nenhuma fica atrás de tarefa viva em segundo plano

**O quê:** a causa medida é do harness: ele só avisa o relay quando o agente para **sem filho vivo
em segundo plano**. Três regras, nos dois arquivos: (1) o planner não encerra o turno com uma
pergunta enquanto tem subagente ou comando seu rodando em segundo plano — espera terminar, ou
encerra a tarefa, antes de devolver; (2) toda pergunta ainda sem resposta volta **inteira** (texto
e opções) em cada devolução seguinte, nunca só o número dela; (3) o relay que lê o número de uma
pergunta cujo texto não repassou pede o texto antes de qualquer outra coisa.
**Onde:** `commands/sdd-plan.md` (`## Relaying the grill to the human`, junto de "Long work between
two questions"), `agents/sdd-planner.md` (parágrafo "When you run as a subagent…"),
`.claude/agents/sdd-planner.md` (via `./bin/sdd install --force`), `tests/check-hat.sh`.
**Como (TDD):** um probe que exige literais nos **dois** arquivos (as regras 1 e 2 no planner, 1 e
3 no comando). Falha hoje.
**Check:** `o=$(bash tests/check-hat.sh 2>&1); grep -c '^  ok    command: /sdd-plan and the planner leave no question behind a live background task' <<< "$o"` → `1` (hoje `0`)
**Sensor durável:** o probe em `tests/check-hat.sh`.
**Reversível por:** `git revert`.

### I3 — D: o planner pode usar o `Monitor` e espera a tarefa viva com ele

**O quê:** `disallowedTools: "ScheduleWakeup"` no frontmatter do planner (sai o `Monitor`), e uma
frase no parágrafo de subagente: para esperar uma tarefa em segundo plano, o planner usa o
`Monitor` com um laço `until`, nunca um laço de chamadas de espera (medido: umas 60 chamadas em
19 min). Depois do I2 a regra "não devolva com filho vivo" passa a ter um jeito barato de ser
cumprida. Os outros sete chapéus não mudam.
**Onde:** `agents/sdd-planner.md`, `.claude/agents/sdd-planner.md` (install `--force`),
`tests/check-hat.sh`. Confira com `grep -n 'Monitor' tests/check-hat.sh bin/sdd` se algum probe ou
censo afirma que **todo** chapéu veta o `Monitor`; se afirmar, ele muda no mesmo commit. A seção 2
de `.claude/rules/anatomia-do-agente.md` ganha uma linha (o planner é o único chapéu com `Monitor`,
e por quê).
**Como (TDD):** probe em `planner_agent_probes`: o frontmatter do planner não lista `Monitor` em
`disallowedTools`, **e** o corpo tem a frase da espera. Falha hoje nas duas metades.
**Check:** `o=$(bash tests/check-hat.sh 2>&1); grep -c '^  ok    hat: the planner may use Monitor, and waits on a live task with it' <<< "$o"` → `1` (hoje `0`)
**Sensor durável:** o probe. ⚠️ Ele prova o arquivo, não que um subagente consegue chamar o
`Monitor` no harness: isso não cabe na suíte (pede uma sessão real) e está nas Pendências do
`00-missao.md`.
**Reversível por:** `git revert` e `./bin/sdd install --force`.

### I4 — M: o planner chama as skills `grilling` e `domain-modeling`

**O quê:** a linha ``Invoke `Skill(grill-with-docs)`.`` do § 1 passa a nomear as duas skills que o
modelo consegue invocar — `Skill(grilling)` para o grill e `Skill(domain-modeling)` para o
vocabulário e os ADRs —, dizendo em meia frase que `grill-with-docs` é o pacote que as traz e que
o modelo não o invoca. `KIT_THIRD_PARTY_SKILLS` não muda.
**Onde:** `agents/sdd-planner.md`, `.claude/agents/sdd-planner.md`, `tests/check-hat.sh`.
**Como (TDD):** probe em `planner_agent_probes`: `Skill(grilling)` e `Skill(domain-modeling)`
presentes, e nenhuma linha manda `Invoke` a `grill-with-docs`. Falha hoje.
**Check:** `o=$(bash tests/check-hat.sh 2>&1); grep -c '^  ok    hat: the planner invokes the grilling and domain-modeling skills, which the model can call' <<< "$o"` → `1` (hoje `0`)
**Sensor durável:** o probe.
**Reversível por:** `git revert` e install `--force`.

### I5 — K: o `/sdd-plan` diz o que fazer com a aprovação dada antes do plano

**O quê:** no passo 3 de `## When the artifacts exist`, um caso para a aprovação antecipada: quando
o humano escreveu, **nas próprias palavras e nesta sessão**, que aprova o plano antes de ele
existir ("escolha as recomendadas e aprovo"), essa mensagem vale como o `YES` da pergunta, e o
relay ainda (a) mede de novo (`--check` e `--red`), (b) mostra o plano e a contagem `N
(recommended) of M`, e só então roda o `sdd approve`; e **para**, voltando a perguntar, se uma
medida falha, se algum critério do PLAN-AUTO está ✗, ou se o plano saiu do recorte que o humano
aprovou. A frase "Only the human's answer to that question approves" continua valendo para
mensagem relayada por **agente**: o caso novo é só a palavra do próprio humano.
**Onde:** `commands/sdd-plan.md`, `tests/check-hat.sh`.
**Como (TDD):** probe em `command_approval_probes` (existe), lendo a seção
`## When the artifacts exist`. Falha hoje. ⚠️ Não quebre os probes vizinhos dessa função, que
exigem a pergunta `YES`/`NO` e a frase sobre agente.
**Check:** `o=$(bash tests/check-hat.sh 2>&1); grep -c '^  ok    command: /sdd-plan says what an approval given before the plan still shows, and what stops it' <<< "$o"` → `1` (hoje `0`)
**Sensor durável:** o probe.
**Reversível por:** `git revert`.

### I6 — L: a fila de PRs de achado ganha receita em `docs/finding-prs.md`

**O quê:** um doc novo, em inglês, com a receita que hoje só mora no histórico (commit `9593497` e
os merges dos PRs 378, 380 e 383): por que todo PR de achado conflita (a linha `todo-findings` de
`tests/health-baseline.txt` e o fim da mesma seção do `TODO.md`), e os passos, na ordem — merge da
`main` na branch do PR; resolver o `TODO.md` mantendo os itens dos dois lados; recontar com
`tests/check-todo.sh --count TODO.md` e escrever o número na baseline ("catraca X + n → Y" na
mensagem do merge); `tests/check-todo.sh --check TODO.md`, `--anchors TODO.md` e
`--check TODO.md --baseline origin/main` (nessa ordem: medido, a outra dá rc 96); push; esperar os checks; `gh pr merge
--match-head-commit <sha>`. Leia `git show 9593497` e `git log --merges -6` antes de escrever: os
comandos do doc são os que rodaram, não os de memória. O cabeçalho do `TODO.md` (o bloco "Catraca
do volume") ganha uma linha apontando o doc. O mesmo doc serve ao chore pós-merge desta missão.
**Onde:** `docs/finding-prs.md` (novo), `TODO.md` (cabeçalho), `tests/check-hat.sh`.
**Como (TDD):** probe novo (função `doc_finding_prs_probes`, na lista): o doc existe, tem os
literais `--baseline origin/main`, `--match-head-commit` e `todo-findings`, e o `TODO.md`
cita `docs/finding-prs.md`. Falha hoje (o arquivo não existe).
**Check:** `o=$(bash tests/check-hat.sh 2>&1); grep -c '^  ok    doc: the queue of finding PRs has its recipe, and the TODO header points at it' <<< "$o"` → `1` (hoje `0`)
**Sensor durável:** o probe; e `tests/check-lang.sh` passa a ler o doc novo por glob. Script foi
recusado (YAGNI: a receita rodou quatro vezes à mão e passou).
**Reversível por:** `git revert`.

### I7 — J: o corpo do PR só promete CI onde há workflow

**O quê:** `templates/pr-body.md:26` deixa de afirmar CI: a linha vira um preenchimento de duas
alternativas, `**Sensores novos** (<rodam no CI a partir deste PR | rodam na suíte local, pelo
\`<TEST_CMD>\`; o repositório não tem CI>):`. `agents/sdd-publisher.md` (o marcador "new sensors")
passa a mandar: afirmar CI **só** quando existe um workflow em `.github/workflows/` do alvo; sem
ele, dizer onde a suíte rodou, pelo `TEST_CMD`.
**Onde:** `templates/pr-body.md`, `agents/sdd-publisher.md`, `.claude/agents/sdd-publisher.md`
(install `--force`), `tests/check-templates.sh`, `tests/check-hat.sh`. Confira se
`docs/pipeline.md` repete a promessa (`grep -n 'CI' docs/pipeline.md`); se repetir, mesmo commit.
**Como (TDD):** em `check-templates.sh`, um `check pr-body.md '<regex das duas alternativas>'
"the new-sensors line promises CI only as one of two fill-ins"`; em `check-hat.sh`, um probe em
`publisher_stamp_probes` (ou função nova) exigindo `.github/workflows/` e `TEST_CMD` no marcador.
⚠️ O `check-templates.sh` tem pisos de contagem (`REVIEW_FLOOR` e vizinhos): se um piso contar as
asserções do `pr-body.md`, ele sobe um no mesmo commit.
**Check:** `a=$(bash tests/check-templates.sh 2>&1); b=$(bash tests/check-hat.sh 2>&1); echo "$(grep -c '^  ok    pr-body.md: the new-sensors line promises CI only as one of two fill-ins' <<< "$a") $(grep -c '^  ok    hat: the publisher claims CI only with a workflow on disk, and names TEST_CMD otherwise' <<< "$b")"` → `1 1` (hoje `0 0`)
**Sensor durável:** os dois probes.
**Reversível por:** `git revert` e install `--force`.

### I8 — C: o `check-todo.sh` recusa o `#N` solto que nomeia um item

**O quê:** regra nova no `lint`: num arquivo que **numera os itens** (o título do item começa por
`**<N>. `), um `#N` no corpo de um item aberto é recusado quando `N` é o número de um item do
arquivo **e** o `#N` não vem logo depois de `PR`, `issue` (qualquer caixa) nem colado a
`dono/repo` (`j0ruge/magic_tutor#115`). Num arquivo que não numera itens (o do kit) a regra não
age: `PR #378` e `#257` soltos continuam passando. A mensagem, em inglês como o resto do sensor, diz a linha
e o remédio (escrever `item N`, ou `PR #N` / `owner/repo#N`). Definições, para não adivinhar: o
arquivo **numera** quando pelo menos um item aberto tem o título começando por `**<dígitos>. `;
"logo depois de" é a palavra imediatamente anterior ao `#N`, separada por um espaço, ser `PR`,
`PRs`, `issue` ou `issues` em qualquer caixa; "colado a `dono/repo`" é o caractere antes do `#`
ser letra ASCII, dígito, `.`, `_`, `/` ou `-`.
**Onde:** `tests/check-todo.sh` (o `awk` de `todo_awk` e o `selftest()`), e o cabeçalho do sensor
(a lista de regras). `templates/todo.md` e `templates/todo.pt-BR.md` ganham a frase da regra no
bloco de formato, no mesmo commit (contrato de artefato).
**Como (TDD):** probes no `selftest()`, num grupo novo cujo rótulo é o do Check: arquivo numerado
com `#57` solto apontando o item 57 → recusado; o mesmo com `PR #57`, `issue #57` e
`dono/repo#57` → limpo; `#999` sem item 999 → limpo; arquivo **não** numerado com `#57` → limpo; e
o caminho `--check <arquivo>` devolvendo rc diferente de 0 no primeiro caso (meça o rc que o
`--check` dá hoje a um arquivo com violação e exija esse) (o selftest exercita o caminho, não
só o parser). Sabotagem: afrouxe a regra para "todo `#N`" e para "nenhum `#N`" e exija vermelho nas
duas. ⚠️ `mawk`: sem classe negada multibyte; os números dos itens são colhidos numa passada (ou
num `END`), porque a citação pode vir antes do item citado.
**Check:** `o=$(bash tests/check-todo.sh 2>&1); grep -c '^  ok    rule: a bare #N that names an item is refused in a file that numbers its items' <<< "$o"` → `1` (hoje `0`)
**Sensor durável:** os probes do `selftest()`. Confira depois que o `TODO.md` do kit continua
`--check` rc 0 e `--count` 86.
**Reversível por:** `git revert`.

### I9 — E: `--help` depois do subcomando só imprime a ajuda

**O quê:** duas mudanças em `bin/sdd`. (1) No `main()`, antes do `case "$subcmd"`: se algum dos
argumentos restantes é `-h` ou `--help`, chama `cmd_help` e retorna 0 — um ponto só, para todo
subcomando (o `--help` do `kaizen` deixa de responder "unknown kaizen option"). (2) `cmd_install`
e `cmd_link_agents` passam a recusar o que não conhecem, no molde do `cmd_status`: `cmd_install`
aceita só `--force`; `cmd_link_agents` não aceita argumento; o resto é
`die "unknown install option: $1"` / `die "unknown link-agents option: $1"`. O `bin/sdd-link-agents`
(o executável irmão) entra pela mesma porta: confira como ele chega ao `cmd_link_agents` e cubra-o.
⚠️ A varredura do `main()` fica **antes** de qualquer efeito, e depois do `coordination_enter` como
hoje. Nenhum id de missão casa `--help` (`^[0-9]{8}-[a-z0-9-]+$`).
**Onde:** `bin/sdd`, `tests/check-preflight.sh`, `tests/check-mutation.sh`; a ajuda (`cmd_help`)
ganha uma linha dizendo que `-h`/`--help` vale depois de qualquer subcomando; `README.md` ou
`docs/` só se já descrevem a ajuda.
**Como (TDD):** dois probes em `check-preflight.sh`, cada um num repositório de rascunho
(`mktemp -d`, `git init`): `sdd install --help` → rc 0, a saída tem o uso, e **nada** foi criado
(`.sdd/`, `docs/handoffs/`, `TODO.md`, `.claude/`); `sdd link-agents --help` num repo já instalado
→ rc 0 e nenhum symlink nem `.gitignore` novo. Mais um caso de `sdd install --bogus` → rc ≠ 0 e
nada criado, numa terceira asserção de texto livre. "A saída tem o uso" = uma linha que o
`cmd_help` imprime hoje (leia-a em `./bin/sdd help`, que não tem efeito). Os probes seguem os
helpers e as fixtures que as seções de install do próprio `check-preflight.sh` já usam; o Red
roda o install e o link-agents **atuais**, que instalam de verdade — sempre dentro do `mktemp -d`. Dois mutantes: um tira a varredura do
`main()`, outro tira a recusa do `cmd_install`.
**Check:** `o=$(bash tests/check-preflight.sh 2>&1); echo "$(grep -c '^  ok    install --help prints the help and writes nothing' <<< "$o") $(grep -c '^  ok    link-agents --help prints the help and links nothing' <<< "$o")"` → `1 1` (hoje `0 0`)
**Sensor durável:** os probes e os mutantes.
**Reversível por:** `git revert`.

### I10 — F: o install não adota a branch de trabalho como base

**O quê:** em `cmd_install`, a derivação de `DEFAULT_BRANCH` ganha degraus antes da branch atual:
(1) `refs/remotes/origin/HEAD`, como hoje; (2) `git ls-remote --symref origin HEAD` (com prazo
curto e `|| true`: repositório sem remoto ou sem rede não pode derrubar o install); (3)
`origin/main` e depois `origin/master`, se a ref existe localmente; (4) só então
`git branch --show-current`, e nesse caso a saída do install **diz que é palpite** (uma linha de
aviso nomeando a branch e mandando conferir `DEFAULT_BRANCH` em `.sdd/config.sh`). O comentário
"Detected from origin/HEAD" que o `config/starter.conf` põe ao lado da chave não pode mentir no
caso 4: se o texto é fixo no starter, ajuste-o para dizer de onde veio, ou escreva o aviso no
próprio config gerado.
**Onde:** `bin/sdd` (`cmd_install`), `config/starter.conf` se o comentário mudar,
`config/schema.md` (a linha de `DEFAULT_BRANCH`), `docs/plan-only.md` (a tabela de chaves cita a
derivação), `tests/check-preflight.sh`, `tests/check-mutation.sh`.
**Como (TDD):** um probe com três mundos, cada um num rascunho com um remoto local (`git init
--bare`) e **sem** `origin/HEAD`, instalando a partir de uma branch de trabalho `wip/x`: remoto
cujo `HEAD` aponta `develop` → `DEFAULT_BRANCH="develop"`; sem `--symref` útil mas com
`origin/main` → `main`; sem remoto → `wip/x` **e** o aviso de palpite na saída. Mutantes: um por
degrau novo (2 e 3) e um para o aviso.
**Check:** `o=$(bash tests/check-preflight.sh 2>&1); grep -c '^  ok    install without origin/HEAD asks the remote, then an existing origin/main or origin/master, and calls the current branch a guess' <<< "$o"` → `1` (hoje `0`)
**Sensor durável:** o probe e os mutantes.
**Reversível por:** `git revert`.

### I11 — G: o `sdd approve` aceita o ADR que commita

**O quê:** em `cmd_approve`, quando `adr:` é um caminho de arquivo que existe e a linha de status
dele é a que o `sdd adr new` escreve (`- **Status**: proposed (…)`), o approve troca `proposed` por
`accepted` **nessa linha só**, antes do `git add`, e o arquivo entra no commit da aprovação como já
entra. ADR já `accepted`, ou com outro status escrito à mão, não é tocado. A resposta `n` e a
ausência de resposta continuam não mudando nada.
**Onde:** `bin/sdd` (`cmd_approve`; a linha que o `sdd adr new` escreve é a fonte da grafia — uma
definição, não duas regexes), `agents/sdd-planner.md` § 6.1 (uma frase: o status vira `accepted` na
aprovação) com o espelho, `docs/pipeline.md` se descreve o approve, `tests/check-gates.sh`
(seção `== sdd approve ==`), `tests/check-mutation.sh`.
**Como (TDD):** probe na seção do approve: missão de fixture com `adr: docs/adr/0001-x.md` criado
por `sdd adr new`, `sdd approve` respondido `y` → o arquivo **no commit** (`git show HEAD:<adr>`)
tem `accepted` e não tem `proposed` na linha de status; controle: um ADR `accepted` à mão sai byte
a byte igual. Mutante: tira a troca.
**Check:** `o=$(bash tests/check-gates.sh 2>&1); grep -c '^  ok    sdd approve turns the proposed ADR that adr: names into accepted, in the approval commit' <<< "$o"` → `1` (hoje `0`)
**Sensor durável:** o probe e o mutante. Rode também `bash tests/check-adr.sh` (12 s): o sensor de
ADR lê status e não pode regredir.
**Reversível por:** `git revert`.

### I12 — I: o `sdd status` fala antes de rodar o `TEST_CMD`

**O quê:** duas linhas. (1) Na face completa do `cmd_status`, antes de o laço chamar o gate que
roda a suíte, uma linha na stderr ou stdout — `running TEST_CMD (<cmd>) for the EXEC gate…` — só
quando o gate vai mesmo rodá-la (a tabela sem `pending`; com `pending` o `gate_EXEC` volta antes
da suíte e a linha não sai). A decisão de "vai rodar" não pode duplicar a lógica do gate: o lugar
natural é dentro do caminho que chama `run_check_cmd "$TEST_CMD"`, com um aviso que só o
`cmd_status` liga (um global lido ali), ou um aviso do próprio `run_check_cmd` quando o chamador é
o status. (2) A mensagem `mission '<x>' not found in <HANDOFF_DIR>/` e o uso do `status` no
`cmd_help` passam a citar `sdd status <missão> --no-gates` como a leitura que não roda gate.
**Onde:** `bin/sdd` (`cmd_status`, `gate_EXEC`/`run_check_cmd`, `resolve_mission`, `cmd_help`),
`tests/check-gates.sh` (junto de `== sdd status --no-gates ==`), `tests/check-mutation.sh`;
`.claude/rules/anatomia-do-agente.md` § 7 ganha uma linha (o humano deixa de vigiar um status mudo).
**Como (TDD):** probe: fixture com todos os incrementos `done` e um `TEST_CMD` de dublê que grava
um carimbo ao começar; `sdd status <m>` → a linha "running TEST_CMD" aparece **antes** da linha do
EXEC na saída, e nomeia o comando; com um `pending`, a linha não aparece; `sdd status
missao-que-nao-existe` → a mensagem cita `--no-gates`. ⚠️ `sdd run --dry-run` e `sdd why` também
passam pelo `gate_EXEC`: a linha é do **status** (confira que as saídas deles, que outros probes
leem, não mudam). Mutantes: um para a linha, um para o `--no-gates` na mensagem.
**Check:** `o=$(bash tests/check-gates.sh 2>&1); grep -c '^  ok    sdd status names the TEST_CMD before the gate that runs it, and a missing mission is told about --no-gates' <<< "$o"` → `1` (hoje `0`)
**Sensor durável:** o probe e os mutantes.
**Reversível por:** `git revert`.

### I13 — H1: o `sdd status` mostra o stream órfão e a árvore suja

**O quê:** uma função nova, uma definição, lida pelas duas faces do `cmd_status` (e pelo I14):
`session_leftovers` (nome sugerido), que **publica** em globais, e é chamada, nunca `$( )`:
(a) os streams órfãos da missão — cada `.sdd/logs/<missão>/*.stream.jsonl` cujo caminho de log
irmão (`…<sid8>.json`, comparado pelo **nome do arquivo**) **nenhuma** linha do `pipeline.log` cita em `log=` (a sessão abriu e o
runner morreu antes de escrever a linha dela); (b) os caminhos sujos, de `git status --porcelain`
(pelo leitor que o arquivo já tem, `hat_status_lines`, se couber). O status imprime, quando há
algo: `  leftovers of a session that never closed:` com o nome de cada stream órfão, e
`  uncommitted paths:` com até dez caminhos e a contagem do resto, mais uma linha dizendo que o
próximo `sdd run` abre uma sessão **sobre** essa árvore. Sem órfão e com a árvore limpa, nada sai.
Na face `--no-gates` ela continua sem rodar gate nenhum.
⚠️ Uma sessão **em curso** também tem stream sem linha no journal: quando o `coordination_owner`
diz que há um dono vivo do checkout, o stream mais novo (pelo carimbo do nome) é "em curso", não
órfão. Os nomes dos globais, o texto exato das linhas e stdout/stderr são seus de escolher (o
status de hoje imprime na stdout); o I14 lê os mesmos globais. O `git status --porcelain` é do
repositório inteiro. Em `docs/failure-modes.md`, procure o verbete da sessão que morre
(`grep -n -i 'died\|orphan' docs/failure-modes.md`); se não houver, escreva um curto.
**Onde:** `bin/sdd` (função nova **abaixo** de `cmd_status`, pelo aviso que já está lá sobre a
região do `sdd health`; e as duas faces do status), `tests/check-gates.sh`,
`tests/check-mutation.sh`, `docs/failure-modes.md` (o verbete da sessão que morre com o runner),
`.claude/rules/anatomia-do-agente.md` § 7.
**Como (TDD):** probe em `check-gates.sh`: fixture com um `X.stream.jsonl` sem linha no journal,
outro **com** linha, e um arquivo modificado sem commit → as duas faces nomeiam o primeiro stream,
não nomeiam o segundo, e listam o caminho sujo; controle limpo → nenhuma das duas linhas. Mutantes:
um por face (porta acrescentada sem probe é porta que ninguém vê cair) e um para o filtro "citado
no journal".
**Check:** `o=$(bash tests/check-gates.sh 2>&1); grep -c '^  ok    sdd status names a stream no journal line closed and the paths left dirty, on both faces' <<< "$o"` → `1` (hoje `0`)
**Sensor durável:** o probe e os mutantes.
**Reversível por:** `git revert`.

### I14 — H2: o boot da fase cita a sobra da sessão morta

**O quê:** o `boot_prompt` ganha uma linha condicional, no molde de `Why this phase:`: quando a
`session_leftovers` do I13 acha stream órfão **ou** árvore suja na abertura da fase, o prompt diz
que uma sessão anterior desta missão não fechou, nomeia os streams e os caminhos sujos (mesmo teto
de dez), e manda a sessão olhar `git status` e `git diff` **antes** de editar e nunca commitar um
`.bak` ou um mutante aplicado que não é dela (o caso medido: a sessão que morreu na sabotagem
deixou o mutante aplicado para a seguinte commitar). O journal ganha a linha
`LEFTOVER <FASE> streams=<n> dirty=<n>` por `pipeline_log_line` (chamada, e calada no `--dry-run`
pela guarda que a função já tem). Sem sobra, o prompt é byte a byte o de hoje.
**Onde:** `bin/sdd` (`boot_prompt`, e o ponto do `run_phase` que escreve o journal antes da
sessão), `agents/sdd-executor.md` (uma frase na parte da sabotagem: sobra de sessão anterior não é
sua) com o espelho, `tests/check-dry-run.sh`, `tests/check-mutation.sh`,
`.claude/rules/anatomia-do-agente.md` § 3 (o boot ganhou uma linha) e § 7 (a linha `LEFTOVER`).
**Como (TDD):** probe em `check-dry-run.sh` usando `sdd boot <missão> EXEC` (imprime o prompt sem
abrir sessão): fixture com um stream órfão e um arquivo sujo → o prompt nomeia os dois; fixture
limpa → o prompt **não** tem a linha (diferencial: as duas saídas comparadas). ⚠️ Vários probes
desse sensor comparam prompts inteiros: o caso limpo tem de continuar idêntico. Mutantes: um para a
linha do prompt, um para a do journal.
**Check:** `o=$(bash tests/check-dry-run.sh 2>&1); grep -c '^  ok    the boot prompt names the orphan stream and the dirty tree a dead session left' <<< "$o"` → `1` (hoje `0`)
**Sensor durável:** o probe e os mutantes.
**Reversível por:** `git revert`.

### I15 — Fecho: `RESOLVED by` nos 13 itens, `KAIZEN_LOG.md` e `20-handoff-exec.md`

**O quê:** quatro escritas, um commit (mais o do checkpoint).
1. **`TODO.md`:** cada um dos 13 itens da tabela do `00-missao.md` ganha `RESOLVED by <hash>` com o
   hash curto do incremento que o consertou (coluna Commit do `checkpoint.md`: A→I1, B→I2, D→I3,
   M→I4, K→I5, L→I6, J→I7, C→I8, E→I9, F→I10, G→I11, I→I12, H→I14 — o item H fecha no segundo
   incremento dele). Onde vai: no fim da última linha do corpo, **antes** do `— descoberto por`,
   nunca numa linha própria, nunca depois do descoberto-por, nunca na linha `RECURRED`
   (`templates/todo.pt-BR.md`, "Onde vai o `RESOLVED by`"); sem espaço nos 120 caracteres, encurte
   o corpo. Os itens **ficam** no arquivo e a catraca **fica** em 86: quem apaga é o chore
   pós-merge.
2. **`KAIZEN_LOG.md`:** uma entrada nova no topo (o arquivo é do mais novo para o mais velho; copie
   a forma da entrada mais recente, `## 2026-10-26 — O \`sdd health\` pula o catálogo com a chave já
   medida`, na linha 7), com um título `## <data de hoje> — <frase>` novo, uma linha que cita o id
   inteiro `20261112-as-reincidentes-primeiro`, e o antes/depois **medido**: 13 achados com
   `RECURRED` e 25 voltas sem conserto → 13 com `RESOLVED by`; asserções novas por sensor (conte
   com `grep -c '^  ok    '` na saída de cada sensor antes e depois; o antes de `a48cf3c`:
   `check-hat.sh` 96, `check-templates.sh` 113, `check-gates.sh` 484, `check-preflight.sh` 162,
   `check-dry-run.sh` 87, `check-todo.sh` 15); mutantes novos (a linha `anchors: all <N> mutants still apply` de `tests/check-mutation.sh
   --anchors`: 792 antes). A seleção do `--touched a48cf3c --list` entra nas notas, no commit do
   checkpoint.
3. **`20-handoff-exec.md`** na pasta da missão, de `/home/pc_admin/repos/sdd_agents-zerar-catraca/templates/handoff.md`:
   `fase: EXEC`, `status: done`, `sessao:` com o id desta sessão interativa (ou `manual`),
   `data:` de `date`, `gate:` com o comando e a saída resumida da suíte; `## TL;DR` com no máximo
   5 linhas (o gate aceita até 20); a lista de I1 a I14 com hash, e o I15 como "este commit"; e a
   frase de que a execução foi fora do `sdd run`.
4. **A gaveta:** `docs/superpowers/specs/2026-09-23-a-gaveta-do-kit.md` ganha um parágrafo
   "**Hoje (<data>).**", depois do último parágrafo desse tipo (`grep -n '^\*\*Hoje' <arquivo>`),
   dizendo que a série de zerar a catraca começou, que o lote 1 fechou as 13
   reincidentes, e que o `sdd health` da série roda no zero (decisão 6).
**Onde:** `TODO.md`, `KAIZEN_LOG.md`, `docs/handoffs/20261112-as-reincidentes-primeiro/20-handoff-exec.md`,
`docs/superpowers/specs/2026-09-23-a-gaveta-do-kit.md`.
**Como (TDD):** o Check é a contagem; rode antes (`0`), escreva, rode depois. Em seguida
`bash tests/check-todo.sh --check TODO.md` rc 0, `--count TODO.md` → `86`, `--anchors TODO.md` →
`0 off target`.
**Check:** `grep -cE 'RESOLVED by [0-9a-f]{7,40}' TODO.md` → `13` (hoje `0`)
**Sensor durável:** `tests/check-todo.sh` (a forma do `RESOLVED by` e o teto de 8 linhas) e a
catraca do `sdd health`. A entrada do `KAIZEN_LOG.md` e o handoff são lidos por `gate_DOCS` e
`gate_EXEC`, que ninguém chama aqui: a prova deles é o `./bin/sdd why <missão> EXEC` da
verificação end-to-end. Checagem manual só para a gaveta, que é prosa de índice.
**Reversível por:** `git revert`.

## Riscos e não-feitos

| Risco | Probabilidade | Mitigação |
|---|---|---|
| Mover linhas de `bin/sdd`, `commands/sdd-plan.md` ou `agents/sdd-planner.md` tira do alvo âncoras do `TODO.md` (49 itens ancoram `bin/sdd`, 19 os dois arquivos do planner) | alta | `tests/check-todo.sh --anchors TODO.md` no passo 5 de todo incremento; reancorar no mesmo commit. O sensor mede o próprio alvo: roda sobre o `TODO.md` deste repo e reprova a suíte se ficar para trás |
| Um conserto em `bin/sdd` quebra a âncora de um mutante antigo | média | `tests/check-mutation.sh --anchors` no passo 5 e dentro da suíte rápida; ele aplica os mutantes deste repo, sem amostra |
| Um mutante antigo deixa de ser pego e ninguém vê até o `sdd health` do fim da série | média | aceito pelo humano (decisão 6); `--only` nos novos e `--touched a48cf3c --list` no fim reduzem, não fecham |
| O `Monitor` liberado ao planner não funciona em subagente | média | Pendência do humano; o item D reabre com a medida |
| A varredura de `--help` no `main()` engole um argumento legítimo | baixa | nenhum subcomando recebe `-h`/`--help` como valor; o probe do I9 e a suíte inteira (que chama todo subcomando) cobrem |
| A linha "running TEST_CMD" muda saídas que outros probes comparam | média | a linha é só do `cmd_status`; a suíte no passo 6 |
| Um incremento de `bin/sdd` não cabe numa sessão (I13 é o maior) | média | já está partido em I13 e I14; se ainda assim não couber, `blocked` com nota e o humano decide |
| A revisão do PR pede conserto de código | alta | cada conserto vira `R<n>` na tabela, com probe; nada de carimbo depois |

Não-feitos: os outros 73 achados; o `sdd health` e o carimbo; a troca de `grill-with-docs` em
`KIT_THIRD_PARTY_SKILLS`; a prova do `Monitor` num harness real; o chore pós-merge.

## Verificação end-to-end

Na raiz do worktree, com os 15 incrementos `done`:

1. `bash tests/run-all.sh` → rc 0.
2. `bash tests/check-checkpoint.sh --check docs/handoffs/20261112-as-reincidentes-primeiro/checkpoint.md` → rc 0.
3. Cada Check da tabela devolve o esperado (15 de 15).
4. `grep -cE 'RESOLVED by [0-9a-f]{7,40}' TODO.md` → `13`; `bash tests/check-todo.sh --count TODO.md` → `86`.
5. `./bin/sdd why 20261112-as-reincidentes-primeiro EXEC` → `15 increment(s) done, suite green, handoff written`.
6. `git -C /home/pc_admin/repos/sdd_agents status --porcelain` → vazio, e o `HEAD` dele não mudou
   desde o começo da sessão (o checkout principal não foi tocado).
7. `git status --short` no worktree → vazio.
