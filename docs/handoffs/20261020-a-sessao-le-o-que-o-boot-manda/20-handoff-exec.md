---
missao: 20261020-a-sessao-le-o-que-o-boot-manda
fase: EXEC
status: done
sessao: 1f921771-01eb-471d-b867-0c307054b548
data: 2026-10-20 22:46
gate: `tests/run-all.sh` em `e8fe91c` → `suite green`, rc 0 (10 min 50 s; 2024 linhas `ok`, eram 2019 na base de `aea4522`; nenhum `FAIL`); Check do I6 → `1 1`; `tests/check-checkpoint.sh --check` → `6 row(s), 6 under the anchor rule, none blind`; os seis incrementos `done`
---

# Handoff — EXEC — a sessão lê o que o boot manda ler

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

Os seis incrementos estão `done`. Toda sessão do runner (fase, `sdd close`, sonda do `sdd preflight`) recebe
`Read(/$SDD_HOME/templates/**)` mais as regras do `READ_EXTRA`, só de leitura; cada negativa do harness vira
`DENIED` no journal; o preflight prova a regra numa sessão isolada e avisa, sem sessão, a entrada do `READ_EXTRA`
que não existe e a skill achada que nenhuma regra cobre. Suíte verde em ``e8fe91c``. Próximo: QA, que no kit
não tem interface (sub-etapa `close`), e a verificação end-to-end do `01-plano.md`.

## Estado do repo

- **Branch:** `kaizen/20261020-a-sessao-le-o-que-o-boot-manda`, no worktree `/home/joruge/repos/sdd_agents-f9`. Não empurrada (nenhum `git push` nesta fase).
- **Último commit:** ``3e0420f` `chore(checkpoint): I6 done (e8fe91c)`, e depois dele o commit deste handoff`
- **Working tree:** limpo
- **Suíte:** `tests/run-all.sh` → verde em `e8fe91c`: `suite green`, rc 0, 2024 linhas `ok`, nenhum `FAIL`
- **E2E:** sem `E2E_CMD` nem `APP_URL` no kit; não se aplica. A métrica de ponta a ponta é a sonda de rascunho do `01-plano.md`, § Verificação end-to-end, que gasta sessão real e fica para o relay.

## O que foi feito

- `7098b92` — I1: `kit_read_rules`, uma definição, imprime `Read(/$SDD_HOME/templates/**)`, e o `run_phase` a passa como argumentos próprios do `--allowedTools` em toda fase (`tests/check-dry-run.sh`).
- `7e2353d` — I2: o `cmd_close` recebe as mesmas linhas da mesma função (`tests/check-gates.sh`, argv da sessão de fechamento).
- `1608dae` — I3: o `sdd preflight` abre uma segunda sessão isolada (`--setting-sources ""`, cwd num `mktemp -d`, env do harness limpo) que pede o `Read` de `templates/handoff.md`; negativa → `_fail`, leitura → `ok`, sem tentativa → `warn` (`tests/check-preflight.sh`, veredito por par de stubs e argv).
- `42fbdb4` — I4: `journal_denials`, chamado logo depois do `hat_init_facts` no `run_phase` e no `cmd_close`, escreve `DENIED  <fase>  tool=<nome>  path=<caminho>` por par distinto (`tests/check-autonomy.sh`).
- `52f9fdf` — I5: a chave `READ_EXTRA` (default vazio), gramática `read_extra_each`, guarda positiva `read_extra_dir_ok`, recusa no `load_config`; o `kit_read_rules` emite uma regra por entrada e a do alvo de `readlink -f` (`tests/check-dry-run.sh`, `tests/check-gates.sh`).
- `e8fe91c` — I6: dois avisos do `sdd preflight`, `warn` e nunca `_fail`, sem sessão: a entrada do `READ_EXTRA` que não é diretório nesta máquina, e a skill achada (o `skill_findable` publica `SKILL_FOUND_DIR`) cujo diretório ou alvo do `readlink -f` nenhuma regra cobre (`read_rules_cover`, que lê as próprias linhas do `kit_read_rules`), com a entrada a declarar (`skill_read_entry`: para plugin, o pai sem versão, escrita `$HOME/…`). `tests/check-preflight.sh` 138 → 143 `ok`, seis mutantes `mut_PRE_*`.

## Artefatos

| Arquivo | O que contém |
|---|---|
| `bin/sdd` | `kit_read_rules`, `read_extra_each`, `read_extra_dir_ok`, `journal_denials`, `read_rules_cover`, `skill_read_entry`, a sonda dos templates e os dois avisos do `cmd_preflight` |
| `tests/check-dry-run.sh`, `tests/check-gates.sh`, `tests/check-preflight.sh`, `tests/check-autonomy.sh` | as asserções dos seis Checks |
| `tests/check-mutation.sh` | os mutantes novos da missão, catálogo em 739 (`--anchors`: todos se aplicam) |
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
  `READ_EXTRA entry to add: <entrada>`.
- **Nesta máquina:** o `READ_EXTRA` do kit é vazio, e a `codereview` está no cache do plugin, então o
  `./bin/sdd preflight` passa a avisar `READ_EXTRA entry to add: $HOME/.claude/plugins/cache/chewiesoft-marketplace/codereview`
  (o `find` acha o diretório do plugin, acima das versões; medido). O mesmo vale para todo alvo sem a chave; é o
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
- O catálogo de mutação não rodou (é o `sdd health`, último passo da missão); só o `--anchors` e o `--only` de cada
  mutante novo.

## Achados fora de escopo

- Nenhum: o `TODO.md` segue com os 29 achados do início da missão (`tests/check-todo.sh`), com nove âncoras reancoradas pelo I6.
