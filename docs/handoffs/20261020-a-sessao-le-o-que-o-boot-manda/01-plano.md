---
missao: 20261020-a-sessao-le-o-que-o-boot-manda
data: 2026-10-20
---

# Plano — a sessão lê o que o boot manda ler

> **Teste de autocontenção:** uma sessão nova, sem nenhuma memória da conversa que gerou este
> plano, lendo apenas `00-missao.md` + `01-plano.md` + `checkpoint.md`, consegue executar?
> Se a resposta for "só se souber X", **X vai escrito aqui**.

> Plano nascido do `sdd kaizen` em 2026-10-20 12:00, sem humano na sala, com o veredito
> `05-verdict.md` ao lado, e replanejado no grill do `/sdd-plan` no mesmo dia, a partir das 15:59,
> com o humano presente por relay. As sete decisões estão no `00-missao.md`, e o porquê de cada
> forma de permissão na ADR 0019 (`docs/adr/0019-the-session-reads-what-the-boot-names.md`). O
> kaizen mediu no HEAD `4068f7e`; o grill remediu no HEAD `45a16a6`, que difere do `4068f7e` só em
> `docs/`, `CONTEXT.md` e `KAIZEN_LOG.md` (`git diff --stat 4068f7e 45a16a6 -- bin agents templates
> config tests` → vazio). Todo `bin/sdd:N` deste plano é do `45a16a6`; depois do I1 os números
> deslocam, e o símbolo entre parênteses é o que se procura.

## Contexto verificado (não re-descobrir)

**O defeito, reproduzido pelo kaizen.** Sondas `claude -p` reais em Claude Code 2.1.296, num repo
de rascunho sob `mktemp -d`, com `--setting-sources "project,local"` para tirar do caminho o
`additionalDirectories` posto à mão no `~/.claude/settings.json`. O ambiente foi limpo como o
`HARNESS_ENV_UNSET` limpa. Todas em haiku, menos de US$ 0,02 somadas:

| Hora | Flags além de `-p --permission-mode acceptEdits --model haiku` | Pedido | Resultado |
|---|---|---|---|
| 11:41 | `--allowedTools "Bash"` | `Read` de `$SDD_HOME/templates/handoff.md` | `DENIED`, e `permission_denials` nomeia o arquivo |
| 11:41 | `--allowedTools "Bash" --add-dir $SDD_HOME/templates` | o mesmo `Read` | lido (`---`) |
| 11:42 | `--allowedTools "Bash" "Read(//<dir>/**)"` | `Read` de `<dir>/f.md` | lido |
| 11:42 | `--allowedTools "Bash" "Read(//<dir>/**)"` | `Write` de `<dir>/c.md` | `DENIED` |
| 11:42 | `--allowedTools "Bash" --add-dir <dir>` | `Write` de `<dir>/b.md` | **escrito** |

O `<dir>` foi um `mktemp -d` sob `/tmp`, nunca o kit. A regra absoluta leva **duas** barras:
`Read(/` seguido do caminho absoluto (nesta tabela, `//<dir>` é a grafia literal, com `<dir>` sem a
barra inicial). O `--allowedTools` aceita a regra como **segundo argumento**
depois do `"$ALLOWED_TOOLS"`; a forma de um argumento só, separada por espaço, não foi medida.

**Remedido no grill, em Claude Code 2.1.304** (o harness subiu depois do kaizen; `claude --version`
→ `2.1.304 (Claude Code)`), em 2026-10-20 16:24–16:25: 13 sessões haiku, US$ 0,026 somadas, em
repos de rascunho sob o scratchpad da sessão, com o ambiente limpo como o `HARNESS_ENV_UNSET`,
`--permission-mode acceptEdits`, `--output-format stream-json --verbose` e `--strict-mcp-config`.
O script e a saída crua ficaram fora do repo; a tabela é o que eles imprimiram (`result` e
`permission_denials` da linha `result`). **Notação, que vale para o plano inteiro, para o
`00-missao.md` e para a ADR:** a regra é sempre `Read(/` + um caminho absoluto + `/**)`, e como o
caminho começa por `/` a grafia literal tem **duas** barras (`Read(//home/…/**)`). Três barras
nunca foram medidas. O `$SDD_HOME` desta máquina é `/home/joruge/repos/sdd_agents` para os alvos e
`/home/joruge/repos/sdd_agents-f9` dentro do worktree da missão.

| # | `--setting-sources` | cwd | regras além de `Bash` | Pedido | Resultado |
|---|---|---|---|---|---|
| p1 | `project,local` | repo limpo | — | `Read` de `$SDD_HOME/templates/handoff.md` | `DENIED`, nomeado no `permission_denials` |
| p2 | `project,local` | repo limpo | `Read(//home/joruge/repos/sdd_agents/templates/**)` | o mesmo `Read` | lido (`---`) |
| p3 | `project,local` | repo limpo | `Read(/<dir>/**)`, `<dir>` absoluto | `Write` de `<dir>/c.md` | `DENIED` |
| p9 | `project,local` | repo limpo | `--add-dir <dir>` | `Write` de `<dir>/b.md` | **escrito** |
| p4 | `user,project,local` | repo com `.claude/settings.local.json` = `{"permissions":{"allow":["Read(*)"]}}` | — (**nenhuma regra**) | `Read` do template | **lido**: as settings do ambiente mascaram a regra ausente |
| p5 | `""` (vazio) | o mesmo repo com `Read(*)` | — | `Read` do template | `DENIED`: a string vazia é aceita e não carrega nenhuma settings |
| p6 | `""` (vazio) | o mesmo repo com `Read(*)` | `Read(//home/joruge/repos/sdd_agents/templates/**)` | `Read` do template | lido |
| p7 | `project,local` | repo limpo | `Read(//home/joruge/.claude/skills/ticket/**)` | `Read` de `~/.claude/skills/ticket/SKILL.md` | **`DENIED`** — `ticket` é symlink |
| p8 | `project,local` | repo limpo | `Read(~/.claude/skills/ticket/**)` | o mesmo | **`DENIED`** |
| p10 | `project,local` | repo limpo | só o alvo do symlink, `Read(//home/joruge/repos/skills/plugins/ticket/skills/ticket/**)` | o mesmo | **`DENIED`** |
| p12 | `project,local` | repo limpo | as **duas** regras, a do caminho pedido e a do alvo resolvido | o mesmo | lido |
| p11 | `project,local` | repo limpo | `Read(//home/joruge/.claude/skills/qa-report/**)` (diretório real) | `Read` do `SKILL.md` dela | lido: `~/.claude` não é o obstáculo, o symlink é |
| p13 | `project,local` | repo limpo | `Read(//home/joruge/.claude/plugins/cache/chewiesoft-marketplace/codereview/**)` (o pai, sem versão) | `Read` de `…/codereview/2.17.0/skills/codereview/references/configuration.md` | lido |

O que isso fixa para o código:
- **symlink pede duas regras.** O harness confere o caminho pedido **e** o resolvido (p7, p10,
  p12). Medido: `readlink -f ~/.claude/skills/ticket` →
  `/home/joruge/repos/skills/plugins/ticket/skills/ticket`;
- **as settings do ambiente mascaram a regra** (p4). É o P2 do Codex no PR #302
  (https://github.com/j0ruge/sdd_agents/pull/302#discussion_r4328046838), e ele se confirma;
- **`--setting-sources ""` isola** (p5, p6): a string vazia é aceita, nenhuma settings é carregada,
  e o resultado depende só das flags;
- **a forma do stream** (p1 e p2, para o veredito da sonda do I3 e para os stubs):
  - o pedido é uma linha `type: "assistant"` com `message.content[]` =
    `{type: "tool_use", id, name: "Read", input: {file_path}}`. O modelo pode pedir mais de um
    `Read` do mesmo arquivo (p2 pediu dois, o segundo com `limit: 1`);
  - a resposta é uma linha `type: "user"` com `message.content[]` =
    `{type: "tool_result", tool_use_id, content}`. Negada, ela traz `is_error: true` e o `content`
    começa por `Claude requested permissions to read from <caminho>`; lida, não traz `is_error`;
  - a linha `type: "result"` traz `permission_denials:
    [{tool_name: "Read", tool_use_id, tool_input: {file_path}}]`, vazio (`[]`) quando nada foi
    negado.

**Onde o boot manda ler.**
- `bin/sdd:3181`: `phase_templates`, a lista de templates por fase.
- `bin/sdd:3319-3326`: o item 6 do `boot_prompt` — "the artifact templates this phase writes from,
  in $SDD_HOME/templates/ … NEVER from memory".
- Toda fase recebe esse item, e o KAIZEN também.
- `SDD_HOME` é o diretório **físico** do kit: `_resolve_self` (`bin/sdd:59`) resolve o symlink do
  executável e faz `cd -P`. A regra dos templates não precisa da regra do alvo resolvido, mas o
  `kit_read_rules` a emite pela mesma regra de toda entrada, e ela é no-op quando os dois coincidem.

**Os três `claude -p` do runner, e as flags de cada um.**
- `run_phase`: o array `cmd` em `bin/sdd:5302-5310`; o `--allowedTools "$ALLOWED_TOOLS"` está em
  `bin/sdd:5307`, seguido de `--disallowedTools`.
- A sonda do `sdd preflight`: `bin/sdd:6212-6217`; o `--allowedTools "$ALLOWED_TOOLS"` está em
  `bin/sdd:6214`. Ela roda no `$REPO_ROOT` com `--setting-sources "user,project,local"`, sob o
  chapéu do executor, e prova o `Bash` (`_fail` sem ele, `ok` com o marcador `sdd-preflight-ok`).
  Logo depois vem a prova das chaves de dinheiro da linha `result` (issue 87), cujo comentário
  diz a regra que a sonda nova copia: "a dead stub gives none, so it is never counted twice".
- O `cmd_close`: `bin/sdd:11957-11962`; o `--allowedTools` está em `bin/sdd:11960`.
- Fora dos três: o `HARNESS_ENV_UNSET` (`bin/sdd:5224`) e o `hat_init_facts` (`bin/sdd:5140`),
  chamado em `bin/sdd:5379` (`run_phase`) e em `bin/sdd:11965` (`cmd_close`). Ele publica
  `LAST_PHASE_DENIALS` como contagem (`bin/sdd:5164`), que a linha de sessão grava como `denials`
  (`bin/sdd:5072`).
- O journal da missão se escreve com `pipeline_log_line` (`bin/sdd:3473`). Exemplo de linha:
  `KIT-TOUCHED`, em `bin/sdd:4373`.

**Config.**
- `ALLOWED_TOOLS="Bash"` em `config/starter.conf:94`, documentado em `config/schema.md:261`.
- `HAT_WRITES_EXTRA` é o molde de chave validada no `load_config` (`bin/sdd:241-270`): o
  `: "${HAT_WRITES_EXTRA:=}"` mantém o valor exportado no ambiente quando o arquivo não o define,
  a quebra de linha é recusada antes do parser, e cada violação morre com motivo nomeado. O `die`
  mora no `load_config` e **nunca** no ponto de uso, porque lá ele cairia num subshell (anatomia
  §6).
- O `config_reload` relê as chaves de `health_default_keys` (`bin/sdd:6600`) a cada volta do
  `cmd_run`. A lista é **derivada**: um `awk` sobre o corpo do `load_config` colhe todo
  `${CHAVE:=`. Chave nova entra nela sozinha, pelo `: "${READ_EXTRA:=}"` — sem editar a função.
- O `cmd_preflight` já procura as skills de terceiro por convenção: `skill_findable`
  (`bin/sdd:5519`), chamado em `bin/sdd:6407`, olha `${SDD_SKILLS_ROOT:-$HOME/.claude}/skills/<nome>`,
  `$REPO_ROOT/.claude/skills/<nome>` e um `find -maxdepth 6 -type d -name <nome>` em
  `…/plugins/cache`, responde só rc (nunca o caminho), e o preflight só **avisa** quando não acha,
  porque as raízes são convenção. O `SDD_SKILLS_ROOT` existe para os sensores injetarem a raiz. As
  que ele pede dependem da config: `codereview` sempre, `ticket` com `JIRA_ENABLED=true`, `qa-*`
  com `E2E_CMD` ou `APP_URL`.
- O `.sdd/config.sh` é **rastreado** no kit e nos três alvos (`git ls-files .sdd` →
  `.sdd/config.sh` no lighthouse, no jrc-libs e no sales_quote). Por isso o `READ_EXTRA` se escreve
  com `$HOME`: o arquivo é `source` de bash, e o valor chega expandido ao `load_config`.
- `.sdd/config.sh` do kit: `JIRA_ENABLED=false` (linha 49), `ADR_CHECK="block"` (linha 32),
  `ADR_DIR="docs/adr"` (linha 33) e `OUTPUT_LANG="pt-BR"` (linha 55).
- Nenhum chapéu nega `Read`: os `disallowedTools:` e `permissionsDeny:` de `agents/*.md` só tiram
  `ScheduleWakeup`, `Monitor`, `Agent`, `ListAgents`, `Skill` e regras de `Bash(git push:*)` e
  vizinhas.

**Os sensores que os Checks leem.** Todos imprimem `  ok    <asserção>` na stdout e
`  FAIL  …` na stderr (`pass()` e `fail()` em `tests/check-dry-run.sh:41-45`,
`tests/check-autonomy.sh:42-46` e `tests/check-preflight.sh:41-45`).
- `tests/check-dry-run.sh` lê o argv **real** de cada fase no bloco `--- DRY RUN: phase X ---` (o
  parser `effort_of` está em `tests/check-dry-run.sh:349`; a asserção que o usa, em
  `tests/check-dry-run.sh:364`, cobre os blocos EXEC, QA:close, REVIEW, DOCS e PR). ⚠️ O runner
  imprime esse argv com `printf '  %q'` (`bin/sdd:5331`), então a regra sai escapada
  (`Read\(//…/templates/\*\*\)`), e a asserção tem de ler o escape ou desfazê-lo.
- `tests/check-gates.sh` grava o argv do `sdd close` com um argumento por linha (`$CLOSE_ARGV`,
  `tests/check-gates.sh:5845-5860`), e a recusa do `HAT_WRITES_EXTRA` é cobrada em
  `tests/check-gates.sh:6270` ("HAT_WRITES_EXTRA with ../ is refused, and the reason names it",
  pelo `hwx_probe`).
- `tests/check-preflight.sh`: o `claude` é um stub em `$FIX/.stub/claude`, e a seção da sonda do
  Bash é `tests/check-preflight.sh:269-326` (as capturas em 292-299, o stub A em 301, o B em 311). O stub
  `gh` do fixture sai 1 (`tests/check-preflight.sh:86`), então **todo** preflight do fixture já sai
  com rc ≠ 0: o rc não distingue dois stubs de `claude`, só as linhas da saída. O init (`init-with-bash.jsonl`) e o resultado
  (`result-real.jsonl`) são uma sessão **real** de 2026-09-06, e as variantes são derivadas com
  `jq`, nunca digitadas. ⚠️ Os stubs de hoje respondem **toda** chamada com o mesmo stream: com uma
  segunda sessão no preflight, eles passam a responder também a ela (I3).
- `tests/check-autonomy.sh` tem o `STREAM_SAMPLE`, com a proveniência em
  `tests/check-autonomy.sh:150-160`.
- Fixture com negativa **real**, para os stubs do I3 e do I4:
  `/home/joruge/repos/jrc-libs/.sdd/logs/20261016-object-storage-distribuivel/TICKET-20261016-201644-1924a656.json`.
  É o resumo da sessão (a saída do `stream_summary`), e o `permission_denials` dele tem três `Read`:
  `/home/joruge/.claude/skills/ticket/references/start.md` (`toolu_01FLvWkCuYTFuBUX4PUGfjbS`),
  `…/campos.md` (`toolu_016ourfWg7Zu88Tcf5ySp2Pd`) e
  `/home/joruge/repos/sdd_agents/templates/handoff.md` (`toolu_014J3i9bJz2vEo2L4ivXyL4Z`). Foi
  capturado em Claude Code 2.1.296 e é colado verbatim, com a proveniência no comentário (CLAUDE.md,
  § fixture de skill de terceiro).

**As âncoras do `TODO.md` que esta missão desloca.** O `tests/check-todo.sh` da suíte reprova a
âncora cujo símbolo não está a até 10 linhas da linha citada (`tests/check-todo.sh:45`). As âncoras
dos 26 itens abertos dentro de `bin/sdd`, no `45a16a6`: `1839` (`gate-qa-e2e`), `2695` (`PHASES`),
`4098` (`autonomy_kit_stamp`), `5774` (`--force`), `5790` (`--show-current`), `5856` (`inst_lang`),
`6340` (`preflight-test`), `7288` (`--no-gates`), `7345` (`run: sdd run`), `8817` (`pipeline
complete`), `11241` (`shared_why`) e `11500` (`/sdd-plan`). O chore dos três achados (pendência 1)
acrescenta `1907` (`gate_REVIEW`) e `4331` (`kit_guard_check`). Nenhuma âncora aberta cai em
`tests/`, `config/` ou `docs/failure-modes.md`. Cada incremento diz quais ele move.

**O estado no HEAD `45a16a6`.**
- `bash tests/check-todo.sh` → `26 finding(s), all within 8 lines, carrying anchor + date, every
  anchor on target`; `bash tests/check-todo.sh --anchors TODO.md` → `anchors: 26 measured, 0 off
  target`. A catraca é `todo-findings 26` (`tests/health-baseline.txt:26`).
- `bash tests/check-lang.sh` → rc 0, `0 of 64 surface path(s) still in the allowlist, 0 new`, com a
  ADR 0019 nova no glob `docs/adr/*.md`.
- `./bin/sdd adr check --mission 20261020-a-sessao-le-o-que-o-boot-manda --phase plan` → `adr:
  docs/adr/0019-the-session-reads-what-the-boot-names.md — and that ADR points back`.
- `bash tests/check-checkpoint.sh --check <este checkpoint>` → `checkpoint.md: 6 row(s), 6 under the
  anchor rule, none blind`, rc 0.
- `SDD_STATE_DIR=<temporário> bash tests/check-checkpoint.sh --red <este checkpoint>` → rc 0 em 10 min
  45 s (17:38–17:49), `6 pending Check(s), every one red at HEAD`. O I6 foi reescrito depois (decisão
  7) e remedido sozinho às 18:10, numa cópia de uma linha do checkpoint, apagada em seguida:
  `I6 is red at HEAD (prints '0 0', wants '1 1')`, rc 0. O antes de cada Check: I1, I2 e I4 imprimem
  `0` (querem `1`); I3, I5 e I6 imprimem `0 0` (querem `1 1`).

**Pitfalls desta casa que esta missão vai pisar.**
- Toda mudança em `bin/sdd` desloca as âncoras `bin/sdd:N` do `TODO.md`. Antes de cada commit em
  `bin/`, rode `bash tests/check-todo.sh --anchors TODO.md`; para cada âncora fora do alvo, troque só
  o número pela linha que o sensor diz (`nearest <símbolo> is at line N`), no mesmo commit.
- `shellcheck -S warning bin/sdd tests/<tocado>.sh` antes de cada commit em `bin/` ou `tests/`. O lint
  só roda na suíte inteira.
- Mutante novo: uma função `mut_<slug>() { sed -i '…' "$1"; }` em `tests/check-mutation.sh` (o
  `$1` é o `bin/sdd` da sandbox; exemplo `mut_RUN_entrypoint_unguarded`, `tests/check-mutation.sh:3109`)
  **e** o `<slug>` sem o prefixo `mut_` na lista `CATALOG=(` (`tests/check-mutation.sh:6128`); sem a
  entrada, a checagem de órfãos (`tests/check-mutation.sh:7144`) reprova com `CATALOGUE-BROKEN`. Os
  nomes `mut_…` deste plano são os das funções. Prove com
  `tests/check-mutation.sh --only <slug> <sensor.sh>` (o slug sem `mut_`), que é dica e não veredito.
  O carimbo é do `./bin/sdd health`, rodado pelo operador depois do último commit de código e da
  revisão do PR.
- `bin/` e `tests/` são superfície do kit em inglês (`tests/check-lang.sh`): comentário, mensagem
  ao usuário, nome de asserção e de mutante. Os textos de asserção dos Checks já estão em inglês.
- A missão se executa de forma **interativa** no worktree. Ali o `Edit` em `.claude/rules/` passa;
  numa fase headless seria recusado.
- Um `claude -p` lançado de dentro de uma sessão do Claude Code precisa de
  `env -u CLAUDECODE -u CLAUDE_CODE_ENTRYPOINT -u CLAUDE_CODE_CHILD_SESSION -u CLAUDE_CODE_SESSION_ID -u CLAUDE_CODE_EFFORT_LEVEL -u CLAUDE_EFFORT`.

## Arquitetura da mudança

**Uma definição, três portas (decisão 1, ADR 0019 §1).** Uma função nova, `kit_read_rules`, imprime
as regras de leitura que toda sessão do runner recebe, uma por linha:
`Read(/$SDD_HOME/templates/**)` (com o `SDD_HOME` absoluto, isso dá as duas barras), e depois do I5
as do `READ_EXTRA`. Ela é **chamada** por cada porta que monta um `claude -p` e nunca copiada: o
`run_phase`, a sonda nova do `cmd_preflight` e o `cmd_close`. Cada porta acrescenta as linhas como
argumentos a mais do `--allowedTools`, logo depois do `"$ALLOWED_TOOLS"`. A função só imprime: ela
é lida por substituição (`mapfile -t … < <(kit_read_rules)`), então não pode ter `die` nem efeito em
global; a validação mora no `load_config`. Cada porta tem o seu probe (I1, I2, I3).

**O sensor de quem ficou de fora (I4).** O `hat_init_facts` já lê o resultado da sessão. Logo
depois dele, nos dois sítios, uma linha `DENIED  <fase>  <ferramenta>  <caminho>` no journal por
negativa distinta. Assim o humano no `tail -F` vê o que a fase não conseguiu ler sem abrir o
`.json`. A contagem no ledger não muda.

**A sonda que fica vermelha (decisão 3, ADR 0019 §3).** A sonda do `Bash` fica intacta. O I3
acrescenta ao `cmd_preflight` uma segunda sessão, **isolada**: `env "${HARNESS_ENV_UNSET[@]}"
claude -p "<prompt>" --model haiku --permission-mode "$PERMISSION_MODE" --output-format stream-json
--verbose --setting-sources "" --allowedTools "$ALLOWED_TOOLS" <linhas do kit_read_rules>
--strict-mcp-config --max-budget-usd 1`, com cwd num `mktemp -d`. O `stream-json --verbose` é
obrigatório: as linhas `tool_use`/`tool_result` que o veredito lê só existem nele. Ela pede o `Read` de
`$SDD_HOME/templates/handoff.md` e o veredito lê o **artefato** do stream, nunca a resposta:
- negativa no `permission_denials` da linha `result` nomeando o template (casada pelo
  `tool_input.file_path`, nunca pelo `tool_use_id`) → `_fail`, com o remédio;
- um `tool_use` de `Read` daquele caminho cujo `id` tem um `tool_result` sem `is_error: true` → `ok`;
- stream sem init e sem `result` → nada: a sonda do `Bash` já disse "did not answer", e a falha não
  conta duas vezes;
- o resto (a sessão respondeu e nunca tentou o `Read`) → `warn`, porque não medido não é zero.

**A chave do projeto (decisão 2, ADR 0019 §2).** `READ_EXTRA` é uma lista de diretórios absolutos
separados por espaço, de default vazio, escrita como `$HOME/…` no `.sdd/config.sh` do alvo ou
exportada no ambiente. O `load_config` morre com motivo nomeado diante de quebra de linha, caminho
relativo, `..` como componente, ou metacaractere (`*`, `?`, `[`, `]`, `(`, `)`); os parênteses
entram na lista porque fechariam a regra `Read(…)`. O `kit_read_rules` emite `Read(/<dir>/**)` por
entrada e, quando o diretório existe e `readlink -f <dir>` difere de `<dir>`, também
`Read(/<resolvido>/**)`. Diretório inexistente não para nada: a regra sai igual, e o `sdd
preflight` avisa (I6). Documentada no `config/schema.md`, no `config/starter.conf` (comentada, com
o exemplo das quatro entradas) e no `health_default_keys`.

**O `SDD_HOME` que não é caminho literal** (um espaço, um metacaractere) entra na regra como está:
essa grafia não foi medida, e quem diz se o harness a lê é a sessão isolada do I3, que fica
vermelha. O `load_config` não o recusa, porque recusar mataria todo comando do kit numa máquina que
hoje funciona sem a leitura dos templates.

## Incrementos

A tabela executável vive em `checkpoint.md` (é ela que o runner lê). Aqui fica o **porquê** de
cada fatia — o detalhe que não cabe numa célula.

**Antes do I1:** o chore dos três achados (decisão 4) já está na `origin/main` (PR #309, merge
`b96f3d3`, `todo-findings 29`), e o worktree foi cortado antes dele. Rode `git fetch origin && git
merge --no-edit origin/main` no worktree, depois `bash tests/check-todo.sh` → `29 finding(s) …
every anchor on target`. Assim cada reancoramento abaixo já cobre os 29 itens, inclusive `1907`
(`gate_REVIEW`) e `4331` (`kit_guard_check`).

### I1 — Uma definição da regra de leitura dos templates, e toda fase a recebe

**O quê:** criar `kit_read_rules` (uma regra por linha; neste incremento só
`Read(/$SDD_HOME/templates/**)`, mais a do alvo resolvido quando `readlink -f` difere) e fazer o
`run_phase` acrescentar cada linha como argumento do `--allowedTools`, depois do
`"$ALLOWED_TOOLS"` e antes do `--disallowedTools`. O comentário da função diz a forma medida (a
regra como argumento próprio, duas barras, 2.1.296 e 2.1.304, com a data), que a forma de um
argumento só não foi medida, e cita a ADR 0019. Acrescentar às seções §2 (Ferramentas) e §6
(Sandboxes) da `.claude/rules/anatomia-do-agente.md` no mesmo commit, e à linha `ALLOWED_TOOLS` do
`config/schema.md:261`, que passa a dizer que o runner soma a regra de leitura dos templates.
**Onde:** `bin/sdd` (a função perto do `HARNESS_ENV_UNSET`, `bin/sdd:5224`; o array `cmd` do
`run_phase`, `bin/sdd:5302-5310`), `tests/check-dry-run.sh`, `tests/check-mutation.sh`,
`config/schema.md`, a seção `## Permissions` do `docs/pipeline.md` (que descreve as flags do
`run_phase`) e a anatomia.
**Como (TDD):** a asserção primeiro, no `check-dry-run.sh`. Em **cada** bloco `--- DRY RUN: phase`
projetado (EXEC, QA:close, REVIEW, DOCS, PR, os mesmos do `effort_of` em
`tests/check-dry-run.sh:364`), a linha `claude -p` carrega a regra de leitura dos templates logo
depois do valor do `--allowedTools`, ela começa por `Read(` (nunca `Edit(` nem `Write(`), e
**nenhuma** carrega `--add-dir`. Uma asserção só, sobre os cinco blocos. Vermelha no HEAD, pela
falta da regra. ⚠️ O caminho esperado sai do `SDD_HOME` **físico** do kit sob teste (`cd -P … &&
pwd`, como o `_resolve_self`), não do `$ROOT` do sensor, que é lógico (`tests/check-dry-run.sh:20`,
`cd` sem `-P`); e o argv sai escapado por `%q`, então a asserção compara com
`printf '%q' "Read(/$home_fisico/templates/**)"` ou desfaz o escape antes.
**Check:** `o=$(bash tests/check-dry-run.sh 2>&1); grep -c '^  ok    every phase may read the kit templates, and only read them' <<< "$o"` → `1`
**Sensor durável:** a asserção e o mutante `mut_RUN_templates_read_rule_dropped`, que tira o
acréscimo do `run_phase` e tem de ser pego pelo `check-dry-run.sh`.
**Âncoras do `TODO.md`:** a função nova entra perto da linha 5224 e a edição do `run_phase` logo
abaixo; se as duas somarem mais de 10 linhas, movem as de `5774` (`--force`) a `11500`
(`/sdd-plan`), nove itens, que este commit reancora. O `--anchors` diz quais, em todo caso.
**Reversível por:** `git revert`. A fase volta a depender das settings do alvo.

### I2 — O sdd close recebe a mesma regra

**O quê:** o `cmd_close` chama o `kit_read_rules` e acrescenta as linhas ao seu `--allowedTools`
(`bin/sdd:11960` no `45a16a6`; procure `--allowedTools "$ALLOWED_TOOLS"` dentro do `cmd_close`). O
fechamento lê a skill `ticket`, e o `CLOSE` do lighthouse teve 3 negativas nas referências dela.
**Onde:** `bin/sdd` (`cmd_close`), `tests/check-gates.sh` e `tests/check-mutation.sh`.
**Como (TDD):** no `check-gates.sh`, perto da asserção do `EFFORT_TICKET`
(`tests/check-gates.sh:5858`), o `$CLOSE_ARGV` (um argumento por linha) tem a linha
`Read(/<SDD_HOME do fixture>/templates/**)` logo depois do valor do `--allowedTools`, e não tem
`--add-dir`. Vermelha no HEAD.
**Check:** `o=$(bash tests/check-gates.sh 2>&1); grep -c '^  ok    close: the session may read the kit templates, and only read them' <<< "$o"` → `1`
**Sensor durável:** a asserção e o mutante `mut_RUN_close_templates_read_rule_dropped`.
**Âncoras do `TODO.md`:** o `cmd_close` fica abaixo de todas; nenhuma se move.
**Reversível por:** `git revert`.

### I3 — O preflight prova a regra do kit numa sessão isolada, e reprova quando ela não lê

**O quê:** a sessão isolada da Arquitetura (decisão 3), dentro do mesmo `if command -v claude` do
`cmd_preflight`, depois da prova das chaves de dinheiro. Ela roda como a fase roda quanto ao
ambiente: `env "${HARNESS_ENV_UNSET[@]}" claude -p …` (a sonda do `Bash` de hoje não limpa, e não é
tocada). O prompt é o das sondas do grill: `Use the
Read tool (never Bash) to read $SDD_HOME/templates/handoff.md and reply with ONLY its first line.
If the Read is refused, reply DENIED and try nothing else.` O cwd é um `mktemp -d` apagado em
seguida. Os textos ficam em inglês (superfície do kit):
- `_fail`: nomeia o caminho, diz que a sessão rodou **sem settings** e com as flags que o runner dá
  às fases, e dá o remédio (a regra do `kit_read_rules`, ou a sintaxe que o harness mudou; o
  `harness:` da linha de sessão do ledger diz a versão);
- `ok`: `a session with no settings reads the kit templates under the phase flags (the kit's read rule works)`;
- `warn`: a sessão respondeu sem tentar o `Read`.
Acrescentar à §4 (Verificação) da anatomia uma linha com a sonda nova e o porquê do isolamento.
**Onde:** `bin/sdd` (`cmd_preflight`, perto de `bin/sdd:6250`), `tests/check-preflight.sh`,
`tests/check-mutation.sh` e a anatomia.
**Como (TDD):** no `check-preflight.sh`, depois dos stubs do `Bash`:
- **o stub novo distingue as duas sessões pelo argv**: a da sonda dos templates é a que leva
  `--setting-sources` seguido de um argumento vazio. Ele grava o argv dessa chamada, um por linha,
  num arquivo, como o `$CLOSE_ARGV` do `check-gates.sh`, e responde à outra como os stubs de hoje;
- **as linhas do stream vêm de uma captura real**: rode uma vez a sonda da Verificação end-to-end
  (§ 2, as duas variantes, com e sem a regra; ~US$ 0,004 em haiku; o `SDD_HOME` dela é o do
  worktree, `/home/joruge/repos/sdd_agents-f9`, exportado antes) e cole verbatim, com a
  proveniência no comentário (data, versão do harness, comando), as linhas `assistant` (o
  `tool_use`) e `user` (o `tool_result`) de cada uma. O `file_path` é trocado por `jq` para o
  `$SDD_HOME` do fixture. A linha `result` é derivada do `result-real.jsonl` por `jq`: com
  `.permission_denials = [<a entrada do template do .json do jrc-libs, § Contexto verificado, com o
  caminho trocado>]` no stub **T-negado**, com `[]` no stub **T-lido**. O `tool_use_id` dessa
  entrada (do jrc-libs) não casa com o das linhas capturadas: o veredito casa a negativa pelo
  caminho, e é por isso que o fixture pode misturar as duas fontes;
- **asserção diferencial, pelas linhas da saída**: T-negado → a linha `_fail` da sonda e nenhuma
  linha `ok` dela; T-lido → a linha `ok` e nenhum `_fail` dela. Uma asserção só, que exige os dois.
  O rc não serve: o stub `gh` já faz todo preflight do fixture sair ≠ 0
  (`tests/check-preflight.sh:86`);
- **asserção de argv**: o argv gravado tem `--setting-sources` seguido de vazio, tem
  `Read(/<SDD_HOME do fixture>/templates/**)` depois do valor do `--allowedTools` (o caminho
  **físico**: o `ROOT` do `check-preflight.sh` é lógico, `tests/check-preflight.sh:35`, `cd` sem
  `-P`, e o runner usa o `SDD_HOME` físico), e não tem
  `--add-dir` nem `--agent`; e o ambiente gravado pelo stub não tem `CLAUDECODE` (exporte-o no
  teste, como o `check-gates.sh` faz com o `CLAUDE_CODE_EFFORT_LEVEL`);
- ⚠️ os stubs de hoje (A, B, dinheiro) passam a responder também à sessão nova com o init e o
  `result-ok`, que não têm `tool_use`: a sessão nova diz `warn` neles. Confira que nenhum
  `assert_lacks` existente casa o texto do `warn`.
Vermelhas no HEAD, pela falta da sessão.
**Check:** `o=$(bash tests/check-preflight.sh 2>&1); a=$(grep -c '^  ok    preflight fails when the kit rule alone cannot read the templates' <<< "$o"); b=$(grep -c '^  ok    the template probe runs with no settings and carries the kit rule' <<< "$o"); echo "$a $b"` → `1 1`
**Sensor durável:** as duas asserções e três mutantes: `mut_PRE_template_read_unchecked` (o `_fail`
vira `ok`), `mut_PRE_template_probe_reads_settings` (o `""` vira `"user,project,local"`) e
`mut_PRE_template_probe_rule_dropped` (a sonda deixa de chamar o `kit_read_rules`). Os dois últimos
só a asserção de argv pega, porque o stub responde o que o fixture manda. É também o sensor do dia em
que o harness mudar a sintaxe da regra, como já mudou o `disallowedTools:` em 2.1.263.
**Âncoras do `TODO.md`:** a sessão nova entra perto da linha 6250 e move as de `6340`
(`preflight-test`) a `11500` (`/sdd-plan`), seis itens, que este commit reancora.
**Reversível por:** `git revert`.

### I4 — Toda negativa do harness é nomeada no journal

**O quê:** uma função nova, chamada logo depois do `hat_init_facts` nos dois sítios (`bin/sdd:5379`
no `run_phase` e `bin/sdd:11965` no `cmd_close`), escreve cada par `(ferramenta, caminho)` distinto
do `permission_denials` do resultado como
`pipeline_log_line "$(date -Iseconds)  DENIED  <fase>  <ferramenta>  <caminho>"`. O caminho é o
`tool_input.file_path`, ou o `tool_input.path`; quando não há caminho, como no `Bash`, a linha leva
só a ferramenta. Resultado sem `permission_denials` não escreve nada, e não medido não é zero. O
`docs/failure-modes.md` ganha o verbete "the phase cannot read what the boot names", com o sintoma
(`DENIED` no journal, `handoff-blocked` no TICKET) e a saída (a regra do I1 para os templates, o
`READ_EXTRA` para as skills, com o symlink resolvido pelo runner).
**Onde:** `bin/sdd` (a função perto do `hat_init_facts`, `bin/sdd:5140`), `tests/check-autonomy.sh`,
`tests/check-mutation.sh` e `docs/failure-modes.md`.
**Como (TDD):** um stub de sessão cujo resultado carrega duas negativas reais (as duas da `ticket`,
copiadas do `.json` do jrc-libs, com proveniência). A asserção exige as duas linhas `DENIED` no
`pipeline.log`, com os caminhos, e **zero** linhas `DENIED` na corrida de controle com o
`STREAM_SAMPLE`, que tem `permission_denials: []`. Vermelha no HEAD.
**Check:** `o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    every tool call the harness denied is named in the journal' <<< "$o"` → `1`
**Sensor durável:** a asserção e o mutante `mut_RUN_denials_not_journaled`.
**Âncoras do `TODO.md`:** a função entra perto da linha 5140 e move as de `5774` a `11500`, nove
itens, que este commit reancora.
**Reversível por:** `git revert`. A contagem `denials` do ledger não muda em nenhum dos dois sentidos.

### I5 — READ_EXTRA: o projeto declara os diretórios das skills, só para leitura

**O quê:** a chave da Arquitetura (decisão 2). No `load_config`, no molde do `HAT_WRITES_EXTRA`:
`: "${READ_EXTRA:=}"`, a quebra de linha recusada antes do laço, e cada entrada (separada por
espaço) recusada com motivo que a nomeia quando é relativa, tem `..` como componente ou tem
metacaractere (`*`, `?`, `[`, `]`, `(`, `)`). O `kit_read_rules` acrescenta, depois da regra dos
templates, `Read(/<dir>/**)` por entrada e a regra do alvo resolvido quando `readlink -f` difere, e
as três portas a recebem de graça. O `health_default_keys` a colhe sozinho do `: "${READ_EXTRA:=}"`
(é derivado do corpo do `load_config`), e o `config_reload` passa a relê-la. Documentada no
`config/schema.md` (uma linha na tabela, perto do `HAT_WRITES_EXTRA`: só leitura, `$HOME`, symlink,
`warn` do preflight), no `config/starter.conf` (comentada, com o exemplo das quatro entradas:
`$HOME/.claude/skills/ticket`, `$HOME/.claude/skills/qa-report`, `$HOME/.claude/skills/qa-execution`
e `$HOME/.claude/plugins/cache/<marketplace>/codereview`, o pai sem versão) e na anatomia §2.
**Onde:** `bin/sdd` (`load_config`, `kit_read_rules`), `config/schema.md`,
`config/starter.conf`, a anatomia, `tests/check-dry-run.sh`, `tests/check-gates.sh` e
`tests/check-mutation.sh`.
**Como (TDD):**
- no `check-dry-run.sh`: um `READ_EXTRA` com dois diretórios do fixture, um real e um symlink para
  um terceiro, aparece como **três** regras `Read(…/**)` (o real, o symlink e o alvo dele) em cada
  bloco de fase, e sem a chave nenhuma regra além da dos templates. Asserção diferencial, sobre as
  duas corridas;
- no `check-gates.sh`, ao lado da do `HAT_WRITES_EXTRA` (`tests/check-gates.sh:6270`): uma asserção
  de rc e de motivo que cobre as quatro recusas (relativo, `*`, `..`, quebra de linha).
**Check:** `o=$(bash tests/check-dry-run.sh 2>&1); p=$(bash tests/check-gates.sh 2>&1); a=$(grep -c '^  ok    READ_EXTRA reaches every phase as a read-only rule, symlink resolved' <<< "$o"); b=$(grep -c '^  ok    READ_EXTRA that is not a literal absolute directory is refused, and the reason names it' <<< "$p"); echo "$a $b"` → `1 1`
**Sensor durável:** as asserções e os mutantes `mut_RUN_read_extra_ignored`,
`mut_RUN_read_extra_relative_accepted` e `mut_RUN_read_extra_symlink_unresolved`. A chave
**alarga** permissão (só de leitura), e por isso a passada de sabotagem é obrigatória antes do merge,
como foi a do `HAT_WRITES_EXTRA`: degrade cada recusa e a resolução do symlink, uma por vez, e exija
o vermelho.
**Âncoras do `TODO.md`:** a validação entra no `load_config` (linhas 241-270) e move **todas** as
âncoras de `bin/sdd`: as doze do `45a16a6` e, se o chore já entrou, `1907` (`gate_REVIEW`) e `4331`
(`kit_guard_check`). Este commit reancora todas.
**Reversível por:** `git revert`. Sem a chave, o comportamento é o do I1.

### I6 — O preflight avisa o que as fases não vão conseguir ler: a entrada que não existe e a skill que ninguém declarou

**O quê:** dois avisos no `cmd_preflight`, os dois `warn` e nunca `_fail`, e nenhum abre sessão:
- **a entrada que não existe** (decisão 2): antes das sondas do `claude`, para cada entrada do
  `READ_EXTRA` que não é diretório, `warn "READ_EXTRA names <dir>, which does not exist on this
  machine — the phases cannot read it; install the skill or remove the entry"`. O plugin pode não
  estar instalado em outra máquina. Entrada que existe não imprime nada;
- **a skill achada e não declarada** (decisão 7): o `skill_findable` (`bin/sdd:5519`) passa a
  publicar o diretório que achou num global (`SKILL_FOUND_DIR`, zerado na entrada da função; vazio
  quando não acha), e continua sendo **chamado**, nunca lido por `$( )`, como já é em
  `bin/sdd:6407`. Ali, para cada skill pedida **e** achada cujo diretório (e o `readlink -f` dele) não
  cai sob nenhuma entrada do `READ_EXTRA` (igual a ela, ou começando por `<entrada>/`), um `warn`
  que nomeia a skill, o diretório achado e a entrada exata a declarar:
  - achada em `<raiz>/skills/<nome>` → a entrada é esse diretório;
  - achada em `<raiz>/plugins/cache/<marketplace>/<plugin>/<versão>/…` → a entrada é o pai sem
    versão, `<raiz>/plugins/cache/<marketplace>/<plugin>` (a sonda p13 mostra que ele cobre a
    versão);
  - achada em `$REPO_ROOT/.claude/skills/<nome>` → nenhum aviso: o repo já é o diretório da sessão;
  - o caminho sugerido sai com o prefixo do `$HOME` escrito `$HOME`, quando cabe, porque é assim
    que ele vai para o `.sdd/config.sh` rastreado (decisão 2).
**Onde:** `bin/sdd` (`skill_findable` e `cmd_preflight`), `tests/check-preflight.sh` e
`tests/check-mutation.sh`.
**Como (TDD):** no `check-preflight.sh`, com o `SDD_SKILLS_ROOT` apontando para uma raiz do
fixture (a `codereview` é pedida em toda config, `bin/sdd:6400`):
- **entrada que não existe**: um `READ_EXTRA` com um diretório que existe e um que não existe. A
  asserção exige o `warn` nomeando o que falta, a ausência de qualquer `warn` que nomeie o que
  existe, e que o rc do preflight não mude por causa dele (o mesmo fixture sem a chave responde o
  mesmo rc);
- **skill não declarada**: a `codereview` posta em `<raiz>/plugins/cache/mk/codereview/1.0.0/skills/codereview`
  e o `READ_EXTRA` vazio → o `warn` nomeia `<raiz>/plugins/cache/mk/codereview`; o mesmo fixture
  com o `READ_EXTRA` declarando esse pai → nenhum `warn` dela. Asserção diferencial, uma só, que
  exige os dois lados.
Vermelhas no HEAD.
**Check:** `o=$(bash tests/check-preflight.sh 2>&1); a=$(grep -c '^  ok    preflight warns about a READ_EXTRA directory that does not exist, and only about it' <<< "$o"); b=$(grep -c '^  ok    preflight names a skill it finds that READ_EXTRA does not declare, with the entry to add' <<< "$o"); echo "$a $b"` → `1 1`
**Sensor durável:** as duas asserções e os mutantes `mut_PRE_read_extra_missing_silent` (o primeiro
aviso some) e `mut_PRE_undeclared_skill_silent` (o segundo aviso some).
**Âncoras do `TODO.md`:** o `skill_findable` (5519) ganha poucas linhas; os avisos entram no
`cmd_preflight`, acima de `6340` (`preflight-test`), e movem as de `6340` a `11500`, que este commit
reancora. O `--anchors` diz quais, em todo caso.
**Reversível por:** `git revert`.

## Riscos e não-feitos

| Risco | Probabilidade | Mitigação |
|---|---|---|
| A sintaxe `Read(/<abs>/**)` mudar num bump do harness, como o `disallowedTools:` mudou em 2.1.263 | média | A sessão isolada do I3 deixa o `sdd preflight` vermelho no dia do bump, em qualquer máquina, e o `harness:` da linha de sessão o mostra |
| As settings do ambiente (`additionalDirectories`, `Read(*)`) mascararem a regra numa medição | alta, nesta máquina | A sessão do I3 roda com `--setting-sources ""` num `mktemp -d` (p5, p6); a sonda end-to-end também |
| Uma regra `deny` nas settings do alvo bloquear a fase real e não a sonda isolada | baixa | A linha `DENIED` do I4 a nomeia na corrida; limite escrito na ADR 0019 |
| Um symlink **abaixo** de um diretório do `READ_EXTRA` (a `ticket` dentro de `~/.claude/skills`, se alguém declarar o pai) | média | O runner resolve só a entrada declarada; o `config/schema.md` diz para declarar o diretório da skill, e a negativa sai como `DENIED` no journal |
| `$SDD_HOME` com espaço ou metacaractere quebrar a regra | baixa | Não medido. Entra na regra como está, e a sessão do I3 é quem diz; limite na ADR 0019 |
| A forma de um argumento só (`--allowedTools "Bash Read(…)"`) ser a única que outro harness aceita | baixa | Medida só a de argumentos separados. O comentário do `kit_read_rules` diz qual forma foi medida, quando e em que versão |
| Regra de leitura em `~/.claude/plugins/cache/…` expor à sessão mais do que a skill | média | Só leitura, só o que o projeto declarar (I5); o kit não acrescenta nada além dos próprios templates, e as fases já têm `Bash` |
| Uma sessão a mais por `sdd preflight` | certa | US$ 0,0018 a 0,0023 e ~6 s medidos (p5, p6); a sonda do `Bash` continua uma só |

**Não-feitos, por escolha:**
- as leituras e escritas negadas sob `/tmp`, que são rascunho da sessão (o I4 as nomeia, e só);
- os três achados da janela, que entraram no backlog por um chore fora desta missão (decisão 4, #309);
- a regra `Read(*)` larga, que é o que o `sales_quote` tem e é exatamente o que o kit não deve
  impor a ninguém;
- o default não-vazio do `READ_EXTRA`, o `reads:` no chapéu e o "só settings" (ADR 0019, Discarded).

## Verificação end-to-end

Com os seis incrementos `done`:

1. `bash tests/run-all.sh` verde, e cada linha `ok` dos Checks presente.
2. A sonda de rascunho, que é a métrica da missão. Roda isolada (`--setting-sources ""`), então
   independe das settings da máquina:

```bash
export SDD_HOME=/home/joruge/repos/sdd_agents-f9   # o kit da missão; depois do merge, o principal
S=$(mktemp -d) && cd "$S"
# os argumentos do `--allowedTools` saem do dry-run do runner, nunca da memória:
# `./bin/sdd run <missão> --dry-run` imprime a linha `claude -p` de cada fase
env -u CLAUDECODE -u CLAUDE_CODE_ENTRYPOINT -u CLAUDE_CODE_CHILD_SESSION -u CLAUDE_CODE_SESSION_ID \
  -u CLAUDE_CODE_EFFORT_LEVEL -u CLAUDE_EFFORT \
  claude -p "Use the Read tool (never Bash) to read $SDD_HOME/templates/handoff.md and reply with ONLY its first line. If the Read is refused, reply DENIED and try nothing else." \
  --model haiku --permission-mode acceptEdits --setting-sources "" --strict-mcp-config \
  --output-format stream-json --verbose --max-budget-usd 0.2 \
  --allowedTools "Bash" "Read(/$SDD_HOME/templates/**)" > with-rule.jsonl
jq -c 'select(.type=="result") | {result, permission_denials}' with-rule.jsonl
# esperado: result "---", permission_denials []
# a mesma linha sem o "Read(…)" → result "DENIED", permission_denials com o template (p5)
# e o par de controle de escrita no mesmo diretório, com a regra: DENIED (p3)
```

3. `./bin/sdd preflight` **nesta** máquina, que tem o `additionalDirectories` com os templates: a
   linha nova em `ok`. O mesmo preflight com o `kit_read_rules` sabotado (a função imprimindo
   nada): **vermelho** — é a prova de que o P2 do Codex está fechado.
4. Na próxima janela do juiz: 0 `Read` negados em `$SDD_HOME/templates/` nos logs de sessão dos
   alvos, e toda negativa restante nomeada como `DENIED` no `pipeline.log`.

## Triagem do TODO.md

Lidos os 26 itens abertos corpo a corpo pelo kaizen, no HEAD `4068f7e`; o grill não mexeu neles, e
o humano decidiu que zerar a catraca é um lote próprio, com `/sdd-plan` próprio, depois do merge
desta missão. O PR #303 (2026-10-20) fundiu as duas lições do `magic_tutor` em itens existentes, e
a catraca segue em 26.

**O lote desta missão não vem do `TODO.md`.** A janela mediu um defeito maior que qualquer item
aberto, e que ainda não estava lá. Ele custou a escalada do jrc-libs, 2 sessões fora de `advanced` e
54 leituras negadas nas referências da `codereview` (40 no lighthouse, 14 no jrc-libs), e vai custar
a todo alvo novo (o `dotp-remake`, o `ui24_agent` e o `magic_tutor` estão na fila). Nenhum dos 26 é
do mesmo tema. Os mais próximos são os de instalação e de preflight do `dotp-remake`:
- o `sdd preflight` não mede a forma do `TODO_FILE`;
- o `sdd install` adota a branch atual como base;
- a primeira instalação semeia o `TODO.md` em inglês;
- nada instala o `/sdd-plan`;
- o preflight diz "ok" com um `TEST_CMD` que deixa servidor vivo.

Ficam onde estão, intocados, como o candidato natural ao lote seguinte.

### Resolvidos a apagar

Nenhum. Nenhum corpo da seção aberta traz `RESOLVED by <hash>`. As duas ocorrências do token no
arquivo são o **tema** de um item aberto (`TODO.md:69`) e um registro decidido (`TODO.md:244`).

### Saem para o cabeçalho do sensor (régua D15)

Nenhum. Os 26 têm consumidor fora da suíte do kit, e cada um nomeia o alvo em que foi medido:
`sales_quote`, `lighthouse_project`, `ui24_agent`, `dotp-remake` ou o yokoten
`JRC-Brasil/sales_quote#484`. Os dois mais próximos da fronteira continuam abertos:
- **"a prosa congelada diz a regra 2 mais estrita que os sensores"** falha fechado, mas os templates
  e os chapéus são semeados nos alvos;
- **"o remédio do `sdd kaizen` sem `--no-track`"** ensina, por enquanto, uma receita que este próprio
  juiz usaria.

## Os três achados da janela

Entraram no `TODO.md` pelo chore do relay (decisão 4): PR #309, merge `b96f3d3` na `origin/main`,
catraca `todo-findings 26` → `29`. Na revisão do PR o texto de dois deles foi reescrito (a direção
da guarda de kit e o achado do `writes:` do juiz), então o texto vigente é o do `TODO.md` da
`origin/main`, nunca o que este plano carregava. As âncoras são as mesmas: `bin/sdd:4331`
(`kit_guard_check`), `bin/sdd:1907` (`gate_REVIEW`) e `agents/sdd-kaizen.md:11` (`writes:`). O
worktree da missão foi cortado antes dele (`45a16a6`) e só os recebe pelo merge do passo "Antes do
I1".
