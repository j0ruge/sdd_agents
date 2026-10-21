---
missao: 20261020-a-sessao-le-o-que-o-boot-manda
fase: EXEC
status: done
sessao: 1f921771-01eb-471d-b867-0c307054b548
data: 2026-10-20 22:46
gate: `tests/run-all.sh` em `e8fe91c` → `suite green`, rc 0 (10 min 50 s; 2024 linhas `ok`, eram 2019 na base de `aea4522`; nenhum `FAIL`); Check do I6 → `1 1`; `tests/check-checkpoint.sh --check` → `6 row(s), 6 under the anchor rule, none blind`; os seis incrementos `done`; rodada de conserto da revisão final: R1 `f9f3b34` (Check → `1`) e R2 `5f05cf4` (Check → `1 1`), com `check-preflight.sh` 146 `ok` e rc 0, `check-mutation.sh --anchors` 742 de 742, `check-todo.sh` e `--anchors` verdes; R3 `b96afd8` e R4 `8c72cfb` (Check → `1`), com `check-preflight.sh` 150 `ok` e rc 0, `check-mutation.sh --anchors` 746 de 746, os dois mutantes novos pegos com `--only`; R5 `4426c94` (Check → `1 1`), com `check-preflight.sh` 152 `ok`, `check-health.sh` 56, `check-dry-run.sh` 86 e `check-gates.sh` 479, todos rc 0, `check-mutation.sh --anchors` 751 de 751, os cinco mutantes novos pegos com `--only`; a suíte inteira depois da rodada é do relay
---

# Handoff — EXEC — a sessão lê o que o boot manda ler

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

Os seis incrementos estão `done`. Toda sessão do runner (fase, `sdd close`, sonda do `sdd preflight`) recebe
`Read(/$SDD_HOME/templates/**)` mais as regras do `READ_EXTRA`, só de leitura; cada negativa do harness vira
`DENIED` no journal; o preflight prova a regra numa sessão isolada e avisa, sem sessão, a entrada do `READ_EXTRA`
que não existe e a skill achada que nenhuma regra cobre. Suíte verde em ``e8fe91c``. Próximo: QA, que no kit
não tem interface (sub-etapa `close`), e a verificação end-to-end do `01-plano.md`. A revisão final da branch pediu
R1 e R2, feitos (seção "Rodada de conserto"), e o Codex no PR #315 o R3, na r2 o R4 e na r3 o lote R5, feitos; a
suíte inteira depois deles é do relay.

## Estado do repo

- **Branch:** `kaizen/20261020-a-sessao-le-o-que-o-boot-manda`, no worktree `/home/joruge/repos/sdd_agents-f9`. Não empurrada (nenhum `git push` nesta fase).
- **Último commit:** `chore(checkpoint): R5 done (4426c94)`, e antes dele o commit desta atualização do handoff
- **Working tree:** limpo
- **Suíte:** `tests/run-all.sh` → verde em `e8fe91c`: `suite green`, rc 0, 2024 linhas `ok`, nenhum `FAIL`. Depois
  de R1 a R5 só rodaram os sensores tocados (abaixo); a suíte inteira é do relay
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

## Artefatos

| Arquivo | O que contém |
|---|---|
| `bin/sdd` | `kit_read_rules`, `read_extra_each`, `read_extra_dir_ok`, `journal_denials`, `read_rules_cover`, `skill_read_entry`, `plugin_install_paths`, a sonda dos templates, os dois avisos e a recusa do caminho do kit no `cmd_preflight` |
| `tests/check-dry-run.sh`, `tests/check-gates.sh`, `tests/check-preflight.sh`, `tests/check-autonomy.sh` | as asserções dos seis Checks |
| `tests/check-mutation.sh` | os mutantes novos da missão, catálogo em 751 depois do R5 (`--anchors`: todos se aplicam) |
| `config/schema.md`, `config/starter.conf`, `docs/pipeline.md`, `docs/failure-modes.md`, `.claude/rules/anatomia-do-agente.md` | a regra, a chave e os avisos documentados |
| `docs/adr/0019-the-session-reads-what-the-boot-names.md` | o porquê de cada forma (escrita no PLAN) |
| `checkpoint-notas.md` | Checks, sensores, passadas de sabotagem e Rulings de cada incremento |

## Boot da próxima fase

- **Leia primeiro:** este TL;DR, o `00-missao.md` (Métrica) e o `01-plano.md`, § Verificação end-to-end.
- **Interface:** nenhuma. O kit não declara `E2E_CMD` nem `APP_URL`, então a QA é a sub-etapa `close`. O que o
  humano vê está na CLI: o argv de cada fase no `./bin/sdd run <missão> --dry-run` (as regras `Read(…)` depois do
  `"$ALLOWED_TOOLS"`), as linhas `DENIED` no `pipeline.log`, as recusas do `load_config` diante de um
  `READ_EXTRA` inválido, e três linhas novas do `./bin/sdd preflight`: a sonda dos templates (`ok`/`fail`/`warn`),
  `READ_EXTRA names <dir>, which does not exist on this machine…` e `skill <nome> is found in <dir>…` seguida de
  `READ_EXTRA entry to add: <entrada>`. Desde o R5, num kit cujo caminho a gramática recusa, um `fail` a mais
  (`the kit's templates are at <caminho>/templates, a path the grammar of the read rules refuses`) e a linha
  `template probe not opened` no lugar do veredito da sonda; nesta máquina o caminho é literal e nada disso aparece.
- **Nesta máquina:** o `READ_EXTRA` do kit é vazio, e a `codereview` está no cache do plugin, então o
  `./bin/sdd preflight` passa a avisar `READ_EXTRA entry to add: $HOME/.claude/plugins/cache/chewiesoft-marketplace/codereview`.
  Desde o R2 o diretório achado é a cópia do `installed_plugins.json`,
  `…/chewiesoft-marketplace/codereview/2.26.0/skills/codereview` (medido em 2026-10-21 00:05, o `skill_findable`
  isolado), e o aviso ganha a frase do cache; a entrada não muda. O mesmo vale para todo alvo sem a chave; é o
  yokoten das Pendências que o cala.
- **Ambiente:** worktree `/home/joruge/repos/sdd_agents-f9`; dentro dele, `./bin/sdd`. Nunca `sdd run` a partir do
  checkout principal. O `./bin/sdd preflight` roda o `TEST_CMD` inteiro (~7,5 min) e abre duas sessões `haiku`.

## Pendências / Decisions for a Human

- As do `00-missao.md`, § Pendências para o humano, itens 2 a 4: o `additionalDirectories` posto à mão e o
  `"Read(*)"` do `sales_quote`; o yokoten do `READ_EXTRA` no lighthouse e no jrc-libs; o carimbo de mutação
  (`./bin/sdd health`) depois do último commit de código e da revisão do PR.

## Riscos e não-feitos

- A sonda de rascunho da Métrica e o preflight desta máquina com o `kit_read_rules` sabotado (itens 2 e 3 da
  Verificação end-to-end) gastam sessão real e não rodaram nesta fase; o relay os roda.
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
  para o 4º destino mesmo com a negativa ou a leitura nele: vermelho falso, nunca verde falso, e a frase diz "could
  read". A sonda do `Bash` (anterior a esta missão) segue jogando o stderr em `/dev/null` e lê o stream linha a
  linha; quando ela cala por um motivo só dela e a dos templates cala por outro, o preflight mostra uma falha e um
  aviso, e a segunda causa só aparece depois do conserto da primeira (dois passos, nunca verde).

## Achados fora de escopo

- Nenhum desta missão: o `TODO.md` tem 33 achados (`tests/check-todo.sh`), os 29 do início mais os quatro que os merges
  da `origin/main` trouxeram (`8c02d4e`), com nove âncoras reancoradas pelo I6, 16 pelo R1, 16 pelo R2, 17 pelo R3,
  nove pelo R4 (sete do `bin/sdd` e duas citações cruzadas de docs) e 21 pelo R5 (17 do `bin/sdd`, quatro delas
  citações curtas `:N`, e quatro cruzadas de docs) — número velho + deslocamento do diff, a mesma linha de código.
