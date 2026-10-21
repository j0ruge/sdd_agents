---
missao: 20261020-a-sessao-le-o-que-o-boot-manda
fase: EXEC
status: done
sessao: 1f921771-01eb-471d-b867-0c307054b548
data: 2026-10-20 22:46
gate: `tests/run-all.sh` em `e8fe91c` → `suite green`, rc 0 (10 min 50 s; 2024 linhas `ok`, eram 2019 na base de `aea4522`; nenhum `FAIL`); Check do I6 → `1 1`; `tests/check-checkpoint.sh --check` → `6 row(s), 6 under the anchor rule, none blind`; os seis incrementos `done`; rodada de conserto da revisão final: R1 `f9f3b34` (Check → `1`) e R2 `5f05cf4` (Check → `1 1`), com `check-preflight.sh` 146 `ok` e rc 0, `check-mutation.sh --anchors` 742 de 742, `check-todo.sh` e `--anchors` verdes; R3 `b96afd8` e R4 `8c72cfb` (Check → `1`), com `check-preflight.sh` 150 `ok` e rc 0, `check-mutation.sh --anchors` 746 de 746, os dois mutantes novos pegos com `--only`; R5 `4426c94` (Check → `1 1`), com `check-preflight.sh` 152 `ok`, `check-health.sh` 56, `check-dry-run.sh` 86 e `check-gates.sh` 479, todos rc 0, `check-mutation.sh --anchors` 751 de 751, os cinco mutantes novos pegos com `--only`; R6 `df5bdb6` (Check → `1`), com `check-preflight.sh` 154 `ok` e rc 0, `check-adr.sh` 81, `check-lang.sh`, `check-pipefail.sh`, `check-todo.sh` e `--anchors` (33 achados, 0 fora do alvo) verdes, `check-mutation.sh --anchors` 755 de 755, os quatro mutantes novos e os três de âncora movida pegos com `--only`; R7 `0b8c140` (Check → `1`), com `check-preflight.sh` 155 `ok`, `check-dry-run.sh` 86, `check-gates.sh` 479, `check-health.sh` 56 e `check-adr.sh` 81, todos rc 0, `check-lang.sh`, `check-pipefail.sh`, `check-todo.sh` e `--anchors` (34 achados, 0 fora do alvo) verdes, `check-mutation.sh --anchors` 757 de 757, os dois mutantes novos e os oito tocados pegos com `--only`; R8 `6b70968` e `f6ce468` (Check → `1 1 0 1`; o do R2 → `1 1 1`), com `check-dry-run.sh` 87 `ok`, `check-gates.sh` 479 e `check-preflight.sh` 155, todos rc 0, `check-lang.sh`, `check-pipefail.sh`, `check-todo.sh` e `--anchors` (38 achados, 0 fora do alvo) verdes, `check-checkpoint.sh --check` 14 linhas sem cega, `check-mutation.sh --anchors` 762 de 762, os cinco mutantes novos e os quatro de âncora movida pegos com `--only`; R9 `8f94a3a` (Check → `1 1`; os de I3, I6 e R1 a R7 conferidos sobre a mesma saída, cada um no esperado), com `check-preflight.sh` 159 `ok`, `check-dry-run.sh` 87 e `check-health.sh` 56, todos rc 0, `check-lang.sh`, `check-pipefail.sh`, `check-todo.sh` e `--anchors` (38 achados, 0 fora do alvo) verdes, `check-checkpoint.sh --check` 15 linhas sem cega, `check-mutation.sh --anchors` 769 de 769, os sete mutantes novos pegos com `--only`; a suíte inteira depois da rodada é do relay
---

# Handoff — EXEC — a sessão lê o que o boot manda ler

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

Os seis incrementos estão `done`. As fases e o `sdd close` recebem `Read(/$SDD_HOME/templates/**)` quando o caminho
do kit passa na gramática (desde o R5 o recusado não ganha a regra, e a sonda não abre), mais as regras do
`READ_EXTRA`, só de leitura, e a sonda do `sdd preflight` só a dos templates; cada negativa do harness vira `DENIED`
no journal; o preflight prova a regra numa sessão isolada e avisa, sem sessão, a entrada do `READ_EXTRA` que não
existe e a skill achada (pela forma como a fase a chama) que nenhuma regra cobre. Suíte verde em ``e8fe91c``. Próximo:
QA (sub-etapa `close`) e a verificação end-to-end do `01-plano.md`. A revisão final pediu R1 e R2, o Codex no PR #315
do R3 ao R7 e o R9, e o CodeRabbit o lote R8, todos feitos ("Rodada de conserto"); a suíte depois deles é do relay.

## Estado do repo

- **Branch:** `kaizen/20261020-a-sessao-le-o-que-o-boot-manda`, no worktree `/home/joruge/repos/sdd_agents-f9`. Não empurrada (nenhum `git push` nesta fase).
- **Último commit:** o commit de checkpoint do R9, cuja mensagem é `chore(checkpoint): R9 done (8f94a3a)` (o hash
  entre parênteses é o do conserto, não o dele), e antes dele o commit desta atualização do handoff
- **Working tree:** limpo
- **Suíte:** `tests/run-all.sh` → verde em `e8fe91c`: `suite green`, rc 0, 2024 linhas `ok`, nenhum `FAIL`. Depois
  de R1 a R9 só rodaram os sensores tocados (abaixo); a suíte inteira é do relay
- **E2E:** sem `E2E_CMD` nem `APP_URL` no kit; não se aplica. A métrica de ponta a ponta é a sonda de rascunho do `01-plano.md`, § Verificação end-to-end, que gasta sessão real e fica para o relay.

## O que foi feito

- `7098b92` — I1: `kit_read_rules`, uma definição, imprime `Read(/$SDD_HOME/templates/**)`, e o `run_phase` a passa como argumentos próprios do `--allowedTools` em toda fase (`tests/check-dry-run.sh`).
- `7e2353d` — I2: o `cmd_close` recebe as mesmas linhas da mesma função (`tests/check-gates.sh`, argv da sessão de fechamento).
- `1608dae` — I3: o `sdd preflight` abre uma segunda sessão isolada (`--setting-sources ""`, cwd num `mktemp -d`, env do harness limpo) que pede o `Read` de `templates/handoff.md`; negativa → `_fail`, leitura → `ok`, sem tentativa → `warn` (`tests/check-preflight.sh`, veredito por par de stubs e argv).
- `42fbdb4` — I4: `journal_denials`, chamado logo depois do `hat_init_facts` no `run_phase` e no `cmd_close`, escreve `DENIED  <fase>  tool=<nome>  path=<caminho>` por par distinto (`tests/check-autonomy.sh`).
- `52f9fdf` — I5: a chave `READ_EXTRA` (default vazio), gramática `read_extra_each`, guarda positiva `read_extra_dir_ok`, recusa no `load_config`; o `kit_read_rules` emite uma regra por entrada e a do alvo de `readlink -f` (`tests/check-dry-run.sh`, `tests/check-gates.sh`).
- `e8fe91c` — I6: dois avisos do `sdd preflight`, `warn` e nunca `_fail`, sem sessão: a entrada do `READ_EXTRA` que não é diretório nesta máquina, e a skill achada (o `skill_findable` publica `SKILL_FOUND_DIR`) cujo diretório ou alvo do `readlink -f` nenhuma regra cobre (`read_rules_cover`, que lê as próprias linhas do `kit_read_rules`), com a entrada a declarar (`skill_read_entry`: para plugin, o pai sem versão, escrita `$HOME/…`). `tests/check-preflight.sh` 138 → 143 `ok`, seis mutantes `mut_PRE_*`.

## Rodada de conserto — revisão final da branch (R1, R2)

Revisor de contexto novo, só leitura, sobre `b96f3d3..d8ef2aa`: "With fixes", 0 Critical, 1 Important, 8 Minor.
O Important virou o R1; os Minor baratos #2 e #8, o lote R2; a prosa (#3, #4, #6, #7, #9) ficou com o relay.

- `f9f3b34` — R1 (Important #1): com a entrada declarada coberta e só o alvo do symlink dela recusado pela
  gramática, o aviso mandava declarar a própria entrada já declarada, um laço sem saída. Agora nomeia o alvo e o
  remédio (mover ou renomear), sem `entry to add`. Check: `a declared skill whose symlink target the grammar
  refuses is named as such, never as undeclared` → `1`. Mutante `mut_PRE_skill_target_refused_undeclared`.
- `5f05cf4` — R2 (Minor #2): o `skill_findable` lê o `installed_plugins.json` antes do `find` (primeiro
  `installPath` de escopo `user` com `skills/<nome>`; registro ausente ou ilegível = sem registro), e o aviso sob
  `<raiz>/plugins/cache/` diz que o cache pode ter mais de uma cópia e nomeia o registro. (Minor #8): o comentário
  da sonda do `Bash` diz `minus the read rules (ADR 0019 §3)`. Check → `1 1`, e uma segunda asserção para a cópia
  do registro. Mutantes `mut_PRE_skill_cache_registry_unnamed` e `mut_PRE_skill_registry_ignored`.
- `b96afd8` — R3 (P3 do Codex no PR #315, `bin/sdd:6493`, decisão humana "só a regra do kit"): a sonda dos
  templates leva no `--allowedTools` só as linhas do `kit_read_rules`, nunca o `ALLOWED_TOOLS` (com um `Read` largo
  ali ela lia o template sem a regra e dizia que a regra funciona); `kit_read_rules` vazio é `_fail` sem sessão, e o
  `(none)` da recusa sumiu. Check: `the template probe carries only the kit read rules, never ALLOWED_TOOLS` → `1`.
  Mutantes `mut_PRE_template_probe_allowlist_widened` e `mut_PRE_template_probe_empty_unguarded`.
- `8c72cfb` — R4 (P2 do Codex na r2 do PR #315, `bin/sdd:6522`, decisão humana "falhar nomeado"): a cadeia de
  veredito da sonda dos templates termina num `else` e cobre os quatro destinos. Um stream sem init e sem `result`
  que o jq leia (vazio, ou que não é JSON) é `_fail` que diz que a CLI não respondeu às flags desta sonda e que a
  regra não foi medida, com a 1ª linha do stderr (antes jogado em `/dev/null`; até 200 caracteres, controles fora,
  `(none)` se vazio). Quando a sonda do `Bash` também não respondeu (`probe_silent`), é uma causa e uma falha, e a
  dos templates só avisa. A sessão abre mesmo assim, e a exceção lê as duas sondas. Check: `a template probe that
  emits no init and no result fails by name, and a dead CLI fails once` → `1`, em quatro mundos (vazio com stderr
  longo, lixo com o stderr desligado, as duas mortas, só a do `Bash` morta). Mutantes
  `mut_PRE_template_probe_silent_unnamed` e `mut_PRE_template_probe_dead_counted_twice`.
- `4426c94` — R5 (os dois P2 do Codex na r3 do PR #315, decisões humanas "Filtrar pela identidade" e "Fechar e
  nomear"). #1: o registro de plugins tem um leitor só, `plugin_install_paths <registro> <plugin>` (chaves
  `<plugin>@…`, escopo `user`, ordem de arquivo), que o `skill_findable` e o `health_provenance` chamam; outro plugin
  listado antes com um `skills/codereview`, ou um `codereview-x@`, deixa de ser a cópia do preflight, e o health
  responde igual (mundo novo no `check-health.sh`, mesma resposta no jq antigo). #2: o `kit_read_rules` passa toda
  entrada pelo `read_extra_dir_ok`, e o caminho do kit que a gramática recusa não ganha regra (nem o alvo
  resolvido); o preflight reprova uma vez, fora do bloco do `claude`, nomeando o caminho e mandando mover o kit, e
  a sonda dos templates não abre (linha `dim`). Check → `1 1`: `a plugin skill is looked up in the registry only
  under its own plugin key, never another plugin` e `a kit path the read-rule grammar refuses gets no template
  rule, and preflight names it` (cópia do kit em `sdd*kit`, `READ_EXTRA` vazio e com entrada, contra o kit real, o
  argv de toda chamada e a projeção do `--dry-run`). Mutantes `mut_PRE_registry_any_plugin`,
  `mut_PRE_registry_prefix_unbounded`, `mut_PRE_kit_path_unnamed`, `mut_PRE_kit_path_probe_opened` e
  `mut_RUN_kit_path_unchecked`.
- `df5bdb6` — R6 (P2 do Codex na r4 do PR #315, `bin/sdd:6587`, decisão humana "Classificar o Read uma vez"): o
  `Read` do template que voltava com `is_error` e sem entrada em `permission_denials` caía no aviso de que a sessão
  não tentou, e o preflight ficava verde. Terceiro achado seguido na mesma sonda; o estado que faltava era o
  desfecho do `Read`. Um jq só imprime um de cinco (`denied` > `read` > `errored` > `not-tried` > `no-session`) e um
  `case` despacha, com default que reprova; os quatro de antes caem no braço e na mensagem de antes, e o `errored` é
  `_fail` com o caminho e a 1ª linha do erro (string ou 1º bloco de texto, 200 caracteres, sem controle, `(none)`).
  Check: `the template probe names the outcome of its Read once, and a Read that comes back with an error fails by
  name` → `1` (errored em três mundos, precedência em dois, `not-tried` em cinco, os mundos de antes), mais `an
  outcome the template probe's verdict does not know fails by name, never green` numa cópia sabotada. Mutantes
  `mut_PRE_template_outcome_error_warned`, `mut_PRE_template_outcome_default_green`,
  `mut_PRE_template_outcome_error_over_read` e `mut_PRE_template_outcome_error_over_denied`.
- `0b8c140` — R7 (P3 do Codex na r5 do PR #315, `bin/sdd:6587`, decisão humana "Sondar só a regra do kit"): o
  `tpl_rules` da sonda era o `kit_read_rules` inteiro, que traz uma regra por entrada do `READ_EXTRA`; uma entrada
  que cubra o kit (`$HOME`, com o `SDD_HOME` abaixo) lia o template sozinha, e o preflight certificava a regra dos
  templates sabotada ou quebrada (a classe do R3 com uma segunda fonte). Uma definição das regras de um diretório,
  `dir_read_rules`; o `kit_template_rules` é ela sobre os templates, e o `kit_read_rules` é ele mais um
  `dir_read_rules` por entrada, com a saída byte a byte igual à do HEAD; a sonda leva só o `kit_template_rules`.
  Check: `the template probe carries the templates rule alone, never a READ_EXTRA rule that covers the kit` → `1`
  (um stub que responde como o harness: o kit real lê, a cópia com a regra quebrada é negada, as fases carregam as
  duas regras nos dois mundos). Mutantes `mut_PRE_template_probe_reads_every_rule` e
  `mut_RUN_read_rules_templates_dropped`; quatro mutantes do corpo antigo reancorados.
- `6b70968` e `f6ce468` — R8 (CodeRabbit no PR #315, o lote dos baratos, decisão humana "Lote R8 pelo executor"):
  (1) as três listas de regras (`read_rules` no `run_phase`, `close_read_rules` no `cmd_close`, `tpl_rules` na sonda
  dos templates) chegam ao `claude` por `${lista[@]+"${lista[@]}"}`, a guarda do `probe_agent`: desde o R5 a lista
  pode ser vazia, e o bash 4.0 a 4.3, que o kit aceita, aborta na forma crua sob `set -u`. Probe estático, porque
  aqui só há bash 5.2: `every read-rule array reaches claude through an expansion that set -u accepts on bash 4.0
  too` (`tests/check-dry-run.sh`), que acha as listas pelos `mapfile` e morre alto com menos de três ou com uma sem
  expansão. Mutantes `mut_RUN_read_rules_bare_expansion`, `mut_RUN_close_read_rules_bare_expansion`,
  `mut_PRE_template_probe_rules_bare_expansion`, `mut_RUN_read_rules_bare_beside_guarded` e
  `mut_RUN_read_rules_list_unscanned`; quatro reancorados. (2) a (6), em `f6ce468`: o Check do R2 lê também a
  asserção do registro (`1 1 1`); o decidido "refutado" da sonda do `Bash` saiu do `TODO.md`, e o sobrevivente é o
  item aberto do `6c182cc`; a anatomia §2 nomeia o `mut_PRE_template_probe_empty_unguarded`; o TL;DR e a Interface
  qualificam a regra dos templates e o aviso do R1. Check → `1 1 0 1`.
- `8f94a3a` — R9 (os dois P2 do Codex na r7 do PR #315, `bin/sdd:5723` e `:5744`, decisão humana "Ler a skill como a
  fase a chama"): terceira falha seguida da vizinhança (R2, R5, R9), e o estado que faltava era a forma da chamada.
  O `wanted` do preflight carrega `codereview:codereview`, `ticket`, `qa-report` e `qa-execution`; a forma com plugin
  lê só o registro, pelo `plugin_install_paths` na chave do plugin, e nenhum diretório simples (#1); a chave sem
  instalação que tenha a skill é instalação quebrada, `warn` próprio com o registro, os `installPath` e o remédio,
  sem cair no cache e sem a linha `present` (#2; `SKILL_BROKEN_WHY`, global); a forma simples segue o caminho de
  antes. Check → `1 1`: `a skill the phase invokes as plugin:skill is looked up in the plugin registry before any
  plain skills directory` e `a recorded plugin install that lacks the skill is warned as broken, never replaced by a
  cache copy`, mais a paridade entre a lista do preflight e as invocações dos chapéus e do `phase_slash`, e o aviso
  de não achado. Os mundos de symlink, de alvo recusado e de diretório de skills passaram de `codereview` para
  `ticket`, porque o valor esperado deles era o defeito #1. Sete mutantes `mut_PRE_*` novos.

## Artefatos

| Arquivo | O que contém |
|---|---|
| `bin/sdd` | `kit_read_rules`, `kit_template_rules`, `dir_read_rules`, `read_extra_each`, `read_extra_dir_ok`, `journal_denials`, `read_rules_cover`, `skill_read_entry`, `plugin_install_paths`, a sonda dos templates, os dois avisos e a recusa do caminho do kit no `cmd_preflight` |
| `tests/check-dry-run.sh`, `tests/check-gates.sh`, `tests/check-preflight.sh`, `tests/check-autonomy.sh` | as asserções dos seis Checks |
| `tests/check-mutation.sh` | os mutantes novos da missão, catálogo em 769 depois do R9 (`--anchors`: todos se aplicam) |
| `config/schema.md`, `config/starter.conf`, `docs/pipeline.md`, `docs/failure-modes.md`, `.claude/rules/anatomia-do-agente.md` | a regra, a chave e os avisos documentados |
| `docs/adr/0019-the-session-reads-what-the-boot-names.md` | o porquê de cada forma (escrita no PLAN) |
| `checkpoint-notas.md` | Checks, sensores, passadas de sabotagem e Rulings de cada incremento |

## Boot da próxima fase

- **Leia primeiro:** este TL;DR, o `00-missao.md` (Métrica) e o `01-plano.md`, § Verificação end-to-end.
- **Interface:** nenhuma. O kit não declara `E2E_CMD` nem `APP_URL`, então a QA é a sub-etapa `close`. O que o
  humano vê está na CLI: o argv de cada fase no `./bin/sdd run <missão> --dry-run` (as regras `Read(…)` depois do
  `"$ALLOWED_TOOLS"`), as linhas `DENIED` no `pipeline.log`, as recusas do `load_config` diante de um
  `READ_EXTRA` inválido, e três linhas novas do `./bin/sdd preflight`: a sonda dos templates (`ok`/`fail`/`warn`),
  `READ_EXTRA names <dir>, which does not exist on this machine…` e `skill <forma> is found in <dir>…`, em duas
  formas, com a skill nomeada pela forma como a fase a chama (`codereview:codereview`, `ticket`; desde o R9). Desde o
  R9 também `skill codereview:codereview is not where the harness loads it: <registro> records the codereview plugin
  installed at <installPath>…`, com o remédio (reinstalar o plugin), quando o registro grava o plugin e nenhuma
  instalação tem a skill, e o `skills not found` diz onde procurou para cada forma. A skill que nenhuma regra cobre (`…, and no read rule …`) vem seguida de `READ_EXTRA entry to add:
  <entrada>`. Desde o R1, a skill declarada cujo alvo de symlink a gramática recusa (`… (a symlink to <alvo>), whose
  target no read rule can cover:`) nomeia o alvo e o remédio, mover ou renomear o alvo, sem `entry to add`: nenhuma
  entrada o alcança. Desde o R5, num kit cujo caminho a gramática recusa, um `fail` a mais
  (`the kit's templates are at <caminho>/templates, a path the grammar of the read rules refuses`) e a linha
  `template probe not opened` no lugar do veredito da sonda; nesta máquina o caminho é literal e nada disso aparece.
- **Nesta máquina:** o `READ_EXTRA` do kit é vazio, e a `codereview` está no cache do plugin, então o
  `./bin/sdd preflight` passa a avisar `READ_EXTRA entry to add: $HOME/.claude/plugins/cache/chewiesoft-marketplace/codereview`.
  Desde o R2 o diretório achado é a cópia do `installed_plugins.json`,
  `…/chewiesoft-marketplace/codereview/2.26.0/skills/codereview` (medido em 2026-10-21 00:05, o `skill_findable`
  isolado), e o aviso ganha a frase do cache; a entrada não muda. Em 2026-10-21 19:33 o registro grava a `2.26.9`,
  que tem `skills/codereview`, e não há `~/.claude/skills/codereview`: o aviso sai como
  `skill codereview:codereview is found in …/2.26.9/skills/codereview`, com a mesma entrada. O mesmo vale para todo alvo sem a chave; é o
  yokoten das Pendências que o cala.
- **Ambiente:** worktree `/home/joruge/repos/sdd_agents-f9`; dentro dele, `./bin/sdd`. Nunca `sdd run` a partir do
  checkout principal. O `./bin/sdd preflight` roda o `TEST_CMD` inteiro (~7,5 min) e abre duas sessões `haiku`.

## Pendências / Decisions for a Human

- As do `00-missao.md`, § Pendências para o humano, itens 2 a 4: o `additionalDirectories` posto à mão e o
  `"Read(*)"` do `sales_quote`; o yokoten do `READ_EXTRA` no lighthouse e no jrc-libs; o carimbo de mutação
  (`./bin/sdd health`) depois do último commit de código e da revisão do PR.

## Riscos e não-feitos

- A sonda de rascunho da Métrica e o preflight desta máquina com o `kit_read_rules` sabotado (itens 2 e 3 da
  Verificação end-to-end) gastam sessão real e não rodaram nesta fase; o relay os roda. Desde o R7 a sabotagem do
  item 3 é no `kit_template_rules`, que é o que a sonda lê: o `kit_read_rules` imprimindo nada tira a regra das
  fases e deixa a sonda verde.
- Os avisos do I6 decidem a cobertura pela gramática do runner, não pelo harness: uma regra `deny` nas settings do
  alvo nega o que o preflight julga coberto, e só o `DENIED` do I4 o diz na corrida.
- A entrada sugerida pelo aviso não passa pelo `read_extra_dir_ok`: um nome de marketplace ou plugin com `@`,
  espaço ou acento é sugerido e depois recusado pelo `load_config`, nomeando a entrada (alto, nunca calado).
- O limite "symlink abaixo de uma entrada declarada" da ADR 0019 continua: o runner não resolve o que está abaixo
  da entrada. O que mudou é que o preflight agora o **nomeia** quando a skill achada é esse symlink (a entrada
  é o pai, o alvo fica descoberto), com a entrada certa a declarar.
- O registro do R2 lê só o escopo `user`, como o `health_provenance`: uma skill instalada só em escopo `project`
  cai no `find` de antes. Um registro que o jq para de ler no meio (entrada que não é objeto) entrega o que veio
  antes da quebra e o resto cai no `find`. Sem jq não há probe: o `2>/dev/null` que o probe do registro ilegível
  segura é o mesmo que cala o `command not found`.
- O catálogo de mutação não rodou (é o `sdd health`, último passo da missão); só o `--anchors` e o `--only` de cada
  mutante novo.
- R5: um kit (ou um checkout do kit) sob um caminho com espaço, `+`, glob ou acento perde a regra dos templates em
  toda sessão, e a suíte rodada de lá fica vermelha nas asserções do I1, I2 e I3, que a esperam: é a verdade
  daquela máquina, que o preflight nomeia. O braço `could not create a scratch directory` da sonda (anterior à
  missão; o R5 só o trocou de `if` para `elif`) segue sem probe: nenhum mundo do sensor faz o `mktemp -d` falhar.
  O leitor do registro agora pula um valor que o jq não itera em vez de parar ali (antes o `skill_findable` parava
  e caía no `find`); o health já pulava.
- R4: o jq lê o stream da sonda dos templates inteiro (`-s`), então uma linha que ele não entende manda o stream
  para o `no-session` (o 4º destino até o R6) mesmo com a negativa ou a leitura nele: vermelho falso, nunca verde falso, e a frase diz "could
  read". A sonda do `Bash` (anterior a esta missão) segue jogando o stderr em `/dev/null` e lê o stream linha a
  linha; quando ela cala por um motivo só dela e a dos templates cala por outro, o preflight mostra uma falha e um
  aviso, e a segunda causa só aparece depois do conserto da primeira (dois passos, nunca verde).
- R6: o filtro `select(.type == "result")` da negativa (anterior à missão) segue sem probe: nenhuma linha real de
  stream além do `result` carrega `permission_denials` (o evento `permission_denied` da 2.1.296 nomeia a chamada
  pelo `tool_use_id`), e o mundo que o distinguiria seria inventado. A negativa casa pelo caminho e não pelo nome da
  ferramenta, como antes: um `Write` negado do template sai como "DENIED reading". O default do `case` só é
  alcançável numa cópia sabotada do kit, que é onde o sensor o prova.
- R7: nenhuma sessão mede as regras do `READ_EXTRA`: a sonda leva só a dos templates, e as entradas ficam com os
  avisos do I6, que julgam pela gramática do runner, não pelo harness. O braço da lista vazia da sonda só é
  alcançável com o kit recusado (atendido antes) ou numa cópia sabotada, onde o sensor o prova. Devolver o laço
  antigo ao `kit_read_rules` dá duas definições que imprimem o mesmo; quem o vê é o termo `phases` do mundo
  sabotado do R7 (as fases levam a regra boa, a sonda a quebrada) e o `--anchors` (dois mutantes deixam de se
  aplicar), nunca a saída da função.
- R8: o bash 4.0 a 4.3 não rodou; a guarda é a grafia que o kit já usava, e quem a cobra é uma leitura estática do
  `bin/sdd`, não uma corrida. Ela acha as listas pelo `mapfile -t <lista> < <(…_rules)`: uma lista enchida por
  outra forma (`readarray`, um laço) sai da varredura, e só o piso de três a nota quando ela é uma das três de hoje.
  O `"${tpl_rules[*]}"` da mensagem da sonda segue sem guarda: ela só roda no braço da lista não vazia.
- R9: a chave sob a qual o registro é lido é o plugin da forma, mas em toda forma que o preflight pede hoje o plugin e
  a skill têm o mesmo nome (`codereview:codereview`), então trocar o `$plugin` pelo `$name` nessa chamada fica verde:
  nenhum mundo alcançável pelo `sdd preflight` os distingue. A forma simples segue o caminho de antes por decisão, e
  com ele a classe do #2: um `ticket` cuja chave grava uma instalação sem a skill continua indo ao cache. A paridade
  lê as invocações em crase dos `agents/*.md` e os `printf` do `phase_slash`; uma invocação escrita fora desses dois
  lugares ou sem crase sai da comparação.

## Achados fora de escopo

- Nenhum desta missão: o `TODO.md` tem 38 achados (`tests/check-todo.sh`), os 29 do início, os quatro que o merge
  `8c02d4e` da `origin/main` trouxe, o da sonda do `Bash` que o relay registrou (`6c182cc`) e os quatro do merge
  `dadeb61`, com nove âncoras reancoradas pelo I6, 16 pelo R1, 16 pelo R2, 17 pelo R3,
  nove pelo R4 (sete do `bin/sdd` e duas citações cruzadas de docs), 21 pelo R5 (17 do `bin/sdd`, quatro delas
  citações curtas `:N`, e quatro cruzadas de docs), 13 pelo R6 (dez do `bin/sdd` e três cruzadas de docs) e 18 pelo
  R7 (14 do `bin/sdd`, três cruzadas de docs e uma da anatomia), 16 pelo R8 (15 do `bin/sdd` e a da anatomia, que
  andou duas vezes) e 19 pelo R9 (15 do `bin/sdd`, três cruzadas de docs e a da anatomia) — número velho +
  deslocamento do diff, a mesma linha de código.
