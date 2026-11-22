---
missao: 20261121-l4-preflight-health-e-sensores
fase: DOCS
status: done
sessao: 372e8e42
data: 2026-11-22 03:49
gate: "docs em `8a36baa` (pipeline.md, failure-modes.md, ADR 0019, README.md, config/schema.md, CLAUDE.md, KAIZEN_LOG.md, gaveta); em `ba7e614` + o diff da fase: `bash tests/check-lang.sh` → `0 of 73 surface path(s) still in the allowlist, 0 new`; `bash tests/check-todo.sh --check TODO.md` → `91 finding(s), all within 8 lines, carrying anchor + date, every anchor on target`; `bash tests/check-todo.sh --anchors TODO.md` → `anchors: 91 measured, 0 off target`; `bash tests/check-adr.sh` → rc 0"
---

# Documentação — L4: preflight, health e sensores

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

O `docs/failure-modes.md` (duas seções), o `config/schema.md`, os templates do `TODO.md` e o chapéu
do juiz mudaram nos commits dos incrementos. Esta fase escreveu o que ficou para trás, em `8a36baa`:
a sonda do `Bash` pelo `tool_result`, os hooks, o `.skills` e a parada do `sdd run` no
`docs/pipeline.md`, com as seis portas da `hat_crossed_escalation`. Mais duas seções no
`failure-modes.md` (itens 2 e 14), a linha datada da ADR 0019 (decisão 8) e o censo medido no
`CLAUDE.md`. Também a entrada do `KAIZEN_LOG.md` e a linha F6 da gaveta. Uma linha `⛔`: a
`.claude/rules/anatomia-do-agente.md`, §2, §4, §6 e §7, com o texto proposto abaixo.
Nenhum item novo no `TODO.md`.

## Estado do repo

- **Branch:** `fix/l4-preflight-health-e-sensores`, no worktree `/home/joruge/repos/sdd_agents-l4`,
  merge-base `86e16c0` (PR #458) com a `origin/main`; sem push nesta fase.
- **Último commit:** o deste `45-docs.md`, sobre `8a36baa`.
- **Working tree:** limpo depois do commit.
- **Suíte:** não rodou inteira nesta fase. O diff da fase é só prosa (`docs/`, `README.md`,
  `config/schema.md`, `CLAUDE.md`, `KAIZEN_LOG.md`, este handoff). Rodei os sensores que leem esses
  arquivos (`check-lang.sh`, `check-todo.sh --check` e `--anchors`, `check-adr.sh`), todos rc 0. A
  última suíte verde é a da r2, em `5d705ac` (2336 ok, 0 FAIL, 986 mutantes aplicam).
- **E2E:** não se aplica (kit sem interface).

## O que foi feito

- `8a36baa`, `docs/pipeline.md`: a parada do `sdd run`/`sdd retry` no lançamento, logo depois do
  parágrafo dos avisos de skill do preflight (item 7). A sonda do `Bash` lê o marcador num
  `tool_result` de uma chamada `Bash`, nunca na resposta, e os hooks e o `.skills` da `init` (itens
  6 e 15). A `hat_crossed_escalation` passa de quatro portas a seis, com as duas do `sdd kaizen`
  (item 4), no parágrafo da guarda e na linha `foreign-commit` da tabela do ledger.
- `8a36baa`, `docs/failure-modes.md`: "`sdd run` refuses a phase: agent … is not installed, in a
  linked worktree" (item 14) e "the kit is off its default branch, or behind it" (item 2).
- `8a36baa`, `config/schema.md`: na linha do `READ_EXTRA`, a parada no lançamento; na seção dos
  comandos de verificação, o `SDD_CHECK_TAG` que todo comando recebe (item 3).
- `8a36baa`, `README.md`: uma frase que roteia para a parada (a mudança de uso que todo alvo vai
  encontrar, pendência 4 do `00-missao.md`).
- `8a36baa`, `docs/adr/0019-…`: linha datada em Consequences, sem ADR nova (decisão 8).
- `8a36baa`, `CLAUDE.md`: censo medido. `grep -cE '^ +if [a-z_]+_escalation "\$phase"; then'
  bin/sdd` → 15 (era 13); `grep -cF 'escalation "$phase"' bin/sdd` → 17 (era 15); a
  `hat_crossed_escalation` com SEIS portas. O `writes:` deste chapéu cobre o `CLAUDE.md`, então é
  ✅ e não `⛔` (a pendência 3 do `00-missao.md` previa `⛔`, e o `gate_DOCS` recusa `⛔` em
  documento que o chapéu escreve).
- `8a36baa`, `KAIZEN_LOG.md`: entrada `## 2026-11-22 — O L4: …`, com o id inteiro da missão.
  Antes 954 `mut_`, depois 986; 46 asserções; a EXEC com 14 sessões, US$ 34,51, 2,30 por item;
  a rodada delta 0,35.
- `8a36baa`, gaveta: linha F6 (L3 mergeado pelo #458 e chore #460; L4 até a DOCS).

## Drift checklist

| Área tocada pelo diff | Documento correspondente | Status | Evidência |
|---|---|---|---|
| `bin/sdd` — sonda do `Bash` pelo `tool_result`, `probe_ran=unread` (I2, R1) | `docs/pipeline.md` | ✅ | parágrafo "`sdd preflight` proves this by firing a real headless session", commit `8a36baa` |
| `bin/sdd` — hooks e `.skills` da `init` na sonda (I3) | `docs/pipeline.md` | ✅ | mesmo parágrafo, "The same stream, paid already", commit `8a36baa` |
| `bin/sdd` — forma do `TODO_FILE` no preflight (I4) | `config/schema.md` | ✅ | seção do opt-in do `TODO.md`, commit `9ef4cdc` |
| `bin/sdd` — preâmbulo do `TODO_FILE` contra o template (I5) | `config/schema.md` | n/a | a frase é do preflight e do `install`, e a linha do `warn` traz a revisão, a data e o `diff`; nenhuma chave ou contrato novo; descrito na §4 proposta abaixo |
| `bin/sdd` — `phase_skills_check`, a parada do `sdd run`/`sdd retry` (I6) | `docs/failure-modes.md` | ✅ | seção "`sdd run` stops at launch", commit `95598f4` |
| `bin/sdd` — `phase_skills_check` | `docs/pipeline.md` | ✅ | parágrafo "Since `20261121-l4-preflight-health-e-sensores` the same sentences", commit `8a36baa` |
| `bin/sdd` — `phase_skills_check` (a linha do `READ_EXTRA`) | `config/schema.md` | ✅ | linha do `READ_EXTRA`, commit `8a36baa` |
| `bin/sdd` — `phase_skills_check` (mudança de uso nos alvos) | `README.md` | ✅ | parágrafo depois do aviso das duas sondas, commit `8a36baa` |
| `bin/sdd` — decisões 3 e 6 | `docs/adr/0019-the-session-reads-what-the-boot-names.md` | ✅ | linha datada no fim de Consequences, commit `8a36baa` |
| `bin/sdd` — `run_check_cmd` com `SDD_CHECK_TAG` e o processo que sobra (I7) | `docs/failure-modes.md` | ✅ | seção "TEST_CMD leaves a process running", commit `dfaeeb4` |
| `bin/sdd` — `SDD_CHECK_TAG` no ambiente do comando | `config/schema.md` | ✅ | "Verification commands", commit `8a36baa` |
| `bin/sdd` — aviso do `shellcheck` ausente (I7) | — | n/a | o aviso nomeia o passo e o remédio; o lint da suíte já está no `CLAUDE.md` ("O passo de lint do `run-all.sh`") |
| `bin/sdd` — árvore suja com os caminhos, sem ruído de pipe (I1, R1) | — | n/a | a linha do preflight nomeia os caminhos sozinha; nenhum doc descrevia a frase antiga |
| `bin/sdd` — `kit_stale_check` (I8) | `docs/failure-modes.md` | ✅ | seção "the kit is off its default branch, or behind it", commit `8a36baa` |
| `bin/sdd` — remédio `sdd link-agents` no worktree (I8) | `docs/failure-modes.md` | ✅ | seção "agent … is not installed, in a linked worktree", commit `8a36baa` |
| `bin/sdd` — `cmd_kaizen` pela guarda do chapéu (I9) | `docs/pipeline.md` | ✅ | parágrafo da `hat_crossed_escalation` e linha `foreign-commit`, commit `8a36baa` |
| `bin/sdd` — `cmd_kaizen` (censo das portas) | `CLAUDE.md` | ✅ | bloco do censo e item da `hat_crossed_escalation`, commit `8a36baa` |
| `bin/sdd` — preflight, parada do `sdd run` e portas do juiz | `.claude/rules/anatomia-do-agente.md` | ⛔ | §2, §4, §6 e §7; texto em "Texto proposto" |
| `agents/sdd-kaizen.md` (a base que o juiz escreve) | `agents/sdd-kaizen.md` | ✅ | o chapéu é o doc, commit `261acc8`, com asserção em `tests/check-hat.sh` |
| `.claude/agents/sdd-kaizen.md` | — | n/a | espelho do `sdd install --force`; `cmp -s` contra `agents/` → rc 0 (Check do I9) |
| `templates/todo.md` e `templates/todo.pt-BR.md` (`PR #N` solto) | `templates/todo.md` | ✅ | o template é o doc, commit `46da749`, com asserção em `tests/check-templates.sh` |
| `tests/check-todo.sh` — regra 8, `PR #N` sob `--baseline` (I12) | `config/schema.md` | ✅ | limites do opt-in, commit `46da749` |
| `tests/check-checkpoint.sh` — regra 7, `atualizado:` no futuro (I10, R1) | — | n/a | o `atualizado:` já sai de `date` pelo `turn_rule` do boot; a recusa nova vive no cabeçalho do sensor |
| `tests/check-health.sh` — sonda de interrupção (I11) | — | n/a | conserto de corrida dentro do sensor; nenhum doc descreve a sonda |
| `tests/isolate-git.sh` — `SDD_SKILLS_ROOT` vazio | `docs/failure-modes.md` | ✅ | fim da seção "`sdd run` stops at launch", commit `95598f4` (e no `docs/pipeline.md`, `8a36baa`) |
| `tests/check-preflight.sh`, `check-dry-run.sh`, `check-kaizen.sh`, `check-hat.sh`, `check-mutation.sh`, `check-templates.sh` | — | n/a | asserções e mutantes em sensores que já existem; nenhum sensor novo, a lista "Os dezessete" do `CLAUDE.md` segue certa |
| `TODO.md` (15 `RESOLVED by`, âncoras deslocadas) | `TODO.md` | ✅ | `54a8ffe` e os commits de cada incremento; `--check` e `--anchors` → 91, 0 fora do alvo |
| a missão inteira (`kaizen_log:` vazio) | `KAIZEN_LOG.md` | ✅ | entrada `## 2026-11-22 — O L4: …`, que cita `20261121-l4-preflight-health-e-sensores`, commit `8a36baa` |
| a frente F6 (o L4 rodou) | `docs/superpowers/specs/2026-09-23-a-gaveta-do-kit.md` | ✅ | linha F6, commit `8a36baa` |
| nenhum termo de domínio novo | `CONTEXT.md` | n/a | `phase_skills_check`, `kit_stale_check` e `SDD_CHECK_TAG` são identificadores de código, descritos onde moram; nenhum conceito novo de pipeline |
| `docs/handoffs/20261121-l4-preflight-health-e-sensores/*` | — | n/a | artefatos da própria missão |

## Texto proposto
<!-- sdd:proposed -->

Em `.claude/rules/anatomia-do-agente.md`, quatro trechos.

**§2 ("Ferramentas"), no fim do parágrafo "Onde mora hoje", depois de "e o `tests/check-health.sh`
do lado da tabela.", acrescente:**

> Desde `20261121-l4-preflight-health-e-sensores` o mesmo juízo (`phase_skills_check`, uma
> definição, duas vozes) é dito no lançamento do `sdd run` e do `sdd retry`, antes de qualquer gate
> ou sessão. Lá, a instalação de plugin quebrada e a skill achada que nenhuma regra cobre **param**
> com `die`, nomeando a entrada do `READ_EXTRA` (na `--dry-run`, só aviso). O aviso do preflight não
> foi lido três vezes, e uma REVIEW custou US$ 5,61 com 3 de 5 agentes parados. A skill não achada e
> o alvo que a gramática recusa seguem aviso, porque nenhuma entrada os conserta. A sonda do `Bash`
> do preflight reprova (`_fail`) a skill que uma fase vai invocar e que o `.skills` da linha `init`
> não lista: é a resposta do harness, e a busca em diretórios é convenção. A suíte do kit roda com o
> `SDD_SKILLS_ROOT` vazio (`tests/isolate-git.sh`).

**§4 ("Mecanismos de verificação"), no fim do parágrafo "Onde mora hoje", depois de "nenhuma
tolerância de prosa.", acrescente:**

> Desde `20261121-l4-preflight-health-e-sensores` o `sdd preflight` deixa de afirmar o que não
> mediu. A sonda do `Bash` dá `ok` pelo `tool_result` de uma chamada `Bash` que carrega o marcador,
> nunca pela resposta, e o stream que o `jq` não lê tem motivo próprio. O mesmo stream lista os hooks
> que toda fase carrega (contagem, rc e bytes por evento) e avisa pelo nome o hook de rc diferente de
> 0 ou `outcome` diferente de `success`. A forma do `TODO_FILE` é medida pelo `check-todo.sh` do kit,
> com ou sem o opt-in (nunca `_fail`), e o preâmbulo é comparado com cada revisão do template no git
> do kit. A árvore suja sai com os caminhos, e o processo que o `TEST_CMD` deixou vivo sai pelo pid e
> pelo executável (`SDD_CHECK_TAG`). Dois sensores ganharam regra: o `check-checkpoint.sh` recusa
> `atualizado:` no futuro (regra 7) e o `check-todo.sh`, sob `--baseline`, o `PR #N` solto sem
> commit que o cite (regra 8).

**§6 ("Sandboxes"), na "Dívida declarada", troque "as duas pela mesma porta,
`hat_crossed_escalation`, em quatro sítios" por:**

> as duas pela mesma porta, `hat_crossed_escalation`, em seis sítios (desde
> `20261121-l4-preflight-health-e-sensores` também a sessão do juiz do `sdd kaizen` e o retry dela,
> só com a guarda do chapéu: o juiz roda no kit, e escrever nele é o trabalho dele)

**§7 ("Hooks"), no fim do parágrafo "Onde mora hoje", depois de "medida, nunca escrita à mão.",
acrescente:**

> Desde `20261121-l4-preflight-health-e-sensores` o `sdd run` e o `sdd retry` param **antes** da
> sessão que será negada: a skill de uma fase que nenhuma regra de leitura cobre é `die` no
> lançamento (rc 1, sem sessão, sem linha de ledger e sem hook, como o chapéu não instalado), com a
> entrada do `READ_EXTRA` a declarar. Não é escalada, é a porta humana antes do gasto. Os avisos do
> clone do kit fora da `main` ou atrás dela (`kit_stale_check`) e do worktree sem o espelho dos
> chapéus (`sdd link-agents`) nomeiam o comando.

## Achados do `TODO_FILE` conferidos nesta missão

- **Forma do arquivo:** `bash tests/check-todo.sh --check TODO.md` → `91 finding(s), all within 8
  lines, carrying anchor + date, every anchor on target`; `--anchors` → `91 measured, 0 off target`.
  A contagem é 91 em `86e16c0` e 91 agora.
- **Os 15 itens do lote** levam `RESOLVED by <hash>` com o hash do incremento que os consertou
  (I13, `54a8ffe`), com os títulos intactos. Seguem abertos até o chore de pós-merge.
- **Nenhum item novo** nasceu nesta missão. O diff do `TODO.md` contra `86e16c0` é `RESOLVED by` e
  deslocamento de âncora, inclusive nos registros de `<!-- sdd:decided -->` e nas linhas `RECURRED`
  (só número de linha).
- **O LOW residual da r2** (o `hat_guard_check` da porta do retry do `cmd_kaizen` sem mutante
  próprio, que o sensor pega) não entrou no `TODO.md`, e concordo. Pela régua de admissão (D15) não
  é sensor que afirme medir o que não mede: a remoção foi reproduzida numa cópia e o
  `check-kaizen.sh` ficou vermelho. Os seis limites da r1 (#7–#12) seguem na `40-review-r1.md`.
- Nada foi refutado nem decidido nesta fase.

## Boot da próxima fase

A PR lê o TL;DR e a tabela acima. Há **uma linha `⛔`**: o corpo do PR tem de nomear
`.claude/rules/anatomia-do-agente.md` numa linha com `⛔` e levar ao humano o texto proposto (§2,
§4, §6 e §7). O corpo lista as escolhas feitas sob delegação, para o aceite do dono (pendência 2 do
`00-missao.md`): os três `◆` (decisões 2, 3 e 4), as decisões 5 a 9 e os três mecanismos do
planner. Ele avisa também do yokoten (pendência 4): todo alvo sem a entrada do `codereview` no
`READ_EXTRA` para no primeiro `sdd run` depois do merge. O merge é por **merge commit**, nunca
squash, para os 15 hashes chegarem à `main`. O rc 2 do `gate_PR` por falta do carimbo quer dizer "PR
pronto para revisão" (pendência 5).

## Pendências / Decisions for a Human

- **Aplicar o `⛔`** da `anatomia-do-agente.md` (§2, §4, §6 e §7).
- **O yokoten da parada** (pendência 4 do `00-missao.md`): conferir o `READ_EXTRA` de
  `sales_quote`, `lighthouse_project`, `warehouse`, `dotp-remake` e `ui24_agent` antes do próximo
  `sdd run` deles.
- **O chore de pós-merge:** apagar os 15 itens provados por `git merge-base --is-ancestor`, descer
  `todo-findings` e sincronizar o espelho de issues.

## Riscos e não-feitos

- A suíte inteira não rodou nesta fase (só prosa no diff); os sensores que leem os arquivos tocados
  rodaram.
- A tabela do `KAIZEN_LOG.md` conta as sessões até a abertura da DOCS; a DOCS e a PR fecham no
  diário da campanha.
- O `CLAUDE.md` foi editado direto (✅), contra o que a pendência 3 do `00-missao.md` previa
  (`⛔`): o `writes:` do `sdd-docs` o cobre, e o `gate_DOCS` recusa `⛔` ali. A mudança é só o
  censo medido, com o comando ao lado.

## Achados fora de escopo

Nenhum novo nesta fase.
