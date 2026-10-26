---
missao: 20261020-a-sessao-le-o-que-o-boot-manda
fase: DOCS
status: done
sessao: 1f921771-01eb-471d-b867-0c307054b548
data: 2026-10-21 00:44
gate: `tests/check-lang.sh` → `0 of 64 surface path(s) still in the allowlist, 0 new`; `tests/check-todo.sh` → `29 finding(s), all within 8 lines, carrying anchor + date, every anchor on target`; `--anchors TODO.md` → `29 measured, 0 off target`; `tests/check-adr.sh` → `adr traceability: 79 probes`; docs em `f826567`, `5705ebe` e `9959b32`; três linhas `⛔` na `.claude/rules/anatomia-do-agente.md`, com o texto proposto abaixo
---

# Handoff — DOCS — a sessão lê o que o boot manda ler

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

O EXEC já tinha levado a regra, a chave e os avisos ao `config/schema.md`, ao `config/starter.conf`, ao
`docs/pipeline.md`, ao `docs/failure-modes.md`, ao `CLAUDE.md` e à anatomia, no mesmo commit de cada
incremento. Esta fase fechou a prosa que a revisão final mandou para cá: a ADR 0019 diz a gramática que o
código cobra (#7), o custo medido da sonda (#6) e três limites novos (#3, #4, #5); o `README.md` e o
`docs/plan-only.md` contam duas sessões pagas no preflight (#9); o `docs/pipeline.md` diz que a sonda do
`Bash` leva as flags do `run_phase` menos as regras de leitura (#8). Entrada nova no `KAIZEN_LOG.md`, linha
F9 da gaveta atualizada, e 14 citações do `TODO.md` que a missão deslocou de volta à linha que citam. A
anatomia (fora do `writes:`) fica com três linhas `⛔`. Nada em `bin/ tests/ templates/ config/ agents/`.

## Estado do repo

- **Branch:** `kaizen/20261020-a-sessao-le-o-que-o-boot-manda`, no worktree `/home/joruge/repos/sdd_agents-f9`,
  sem push. A `origin/main` andou depois do merge-base `b96f3d3`: `56db923` (PR #308) acrescenta quatro achados
  ao `TODO.md` e leva a catraca a 33 (ver Pendências).
- **Último commit:** o deste `45-docs.md`, sobre `9959b32`.
- **Working tree:** limpo depois do commit.
- **Suíte:** não rodou inteira nesta fase (é do relay; verde em `259222b`, 2027 `ok`). Rodaram os sensores que
  leem o que esta fase tocou: `check-lang`, `check-todo` (e `--anchors`) e `check-adr`, verdes.
- **E2E:** não se aplica (o kit não declara `E2E_CMD` nem `APP_URL`).

## O que foi feito

- `f826567`: ADR 0019 §2 com a gramática literal do `read_extra_dir_ok`, o alvo do symlink só com regra
  quando passa na mesma gramática, e os avisos do preflight (com o `installed_plugins.json` do R2); §3 com a
  sonda do `Bash` "menos as regras de leitura"; Consequences com o custo medido às 22:59 e os três limites.
  `README.md` (requisitos e aviso do custo), `docs/plan-only.md` e `docs/pipeline.md` (§ Permissions: a
  ressalva da gramática no alvo resolvido, o teto de custo sem teto de tempo, e a sonda do `Bash` sem as
  regras de leitura).
- `5705ebe`: `TODO.md`, cinco âncoras principais uma linha acima do que citavam e nove citações de corpo que
  nenhum incremento moveu, cada uma reposta pelo número velho mais o deslocamento do diff de `b96f3d3`, com o
  conteúdo da linha conferido nos dois lados.
- `9959b32`: a entrada `2026-10-21 — A sessão lê o que o boot manda ler` do `KAIZEN_LOG.md` (antes e depois
  medidos, e o que fica para a próxima janela do juiz como pendente), e a linha F9 e o parágrafo da F3 da
  gaveta.

## Drift checklist

| Area touched by the diff | Corresponding document | Status | Evidence |
|---|---|---|---|
| `bin/sdd` (`kit_read_rules` e o `--allowedTools` do `run_phase`, I1) | `docs/pipeline.md` | ✅ | § Permissions, parágrafo "Since `20261020-a-sessao-le-o-que-o-boot-manda`…", em `7098b92` |
| `bin/sdd` (`kit_read_rules`, I1) | `config/schema.md` | ✅ | linha `ALLOWED_TOOLS` da tabela, em `7098b92` |
| `bin/sdd` (`kit_read_rules`, I1) | `.claude/rules/anatomia-do-agente.md` | ✅ | § 2 e § 6, "Onde mora hoje", em `7098b92` (sessão interativa) |
| `bin/sdd` (`cmd_close` recebe as mesmas linhas, I2) | `docs/pipeline.md` | ✅ | "`sdd close` is the only invocation of `claude` outside `run_phase()`…" e § Permissions, em `7e2353d` |
| `bin/sdd` (`cmd_preflight`, a sonda isolada dos templates, I3) | `CLAUDE.md` | ✅ | § "Ao mexer no runner", as exceções ao `run_phase` passam a ser as duas sondas e o `sdd close`, em `1608dae` |
| `bin/sdd` (`cmd_preflight`, sonda dos templates, I3) | `docs/pipeline.md` | ✅ | § Permissions, parágrafo "No argv assertion says…", em `1608dae`; o teto de custo sem teto de tempo, em `f826567` |
| `bin/sdd` (`cmd_preflight`, duas sessões pagas, I3) | `README.md` | ✅ | § Runtime requirements ("the paid preflight probes") e o aviso ⚠️ do custo, em `f826567` |
| `bin/sdd` (`cmd_preflight`, duas sessões pagas, I3) | `docs/plan-only.md` | ✅ | aviso "Do not run `sdd preflight` in this mode", em `f826567` |
| `bin/sdd` (`cmd_preflight`, sonda dos templates, I3) | `.claude/rules/anatomia-do-agente.md` | ⛔ | § 4, "Onde mora hoje", a última frase do parágrafo da sonda (o custo); texto em "Texto proposto" |
| `bin/sdd` (`cmd_preflight`, as duas sondas sem teto de tempo, #5 da revisão final) | `docs/adr/0019-the-session-reads-what-the-boot-names.md` | ✅ | Consequences, "Declared limits of the reach and of the probe", em `f826567` |
| `bin/sdd` (`cmd_preflight`, as duas sondas sem teto de tempo, #5) | `.claude/rules/anatomia-do-agente.md` | ⛔ | § 4, "Dívida declarada", depois da frase do "Resíduo"; texto em "Texto proposto" |
| `bin/sdd` (comentário da sonda do `Bash`, "minus the read rules", R2 #8) | `docs/pipeline.md` | ✅ | parágrafo "`sdd preflight` proves this by firing a real headless session **as the executor hat**…", em `f826567` |
| `bin/sdd` (sonda do `Bash` sem as regras de leitura, R2 #8) | `docs/adr/0019-the-session-reads-what-the-boot-names.md` | ✅ | § 3, primeira frase, em `f826567` |
| `bin/sdd` (`journal_denials` no `run_phase` e no `cmd_close`, I4) | `docs/pipeline.md` | ✅ | § Costs and logs, a linha `DENIED  <X>  tool=<name>  path=<path>`, em `42fbdb4` |
| `bin/sdd` (`journal_denials`, I4) | `docs/failure-modes.md` | ✅ | verbete novo "The phase cannot read what the boot names", em `42fbdb4` |
| `bin/sdd` (`journal_denials`, I4) | `.claude/rules/anatomia-do-agente.md` | ✅ | § 7, "Onde mora hoje", a linha `DENIED` ao lado da `PHASE`, em `42fbdb4` |
| `bin/sdd` (`load_config`, `read_extra_each`, `read_extra_dir_ok`, `kit_read_rules`: a chave `READ_EXTRA`, I5) | `config/schema.md` | ✅ | seção nova "What the phases read beyond the repo", em `52f9fdf`; a gramática ali já é a do código |
| `bin/sdd` (`READ_EXTRA`, I5) | `config/starter.conf` | ✅ | bloco "what the phases read beyond the repo", comentado com o exemplo, em `52f9fdf` |
| `bin/sdd` (`READ_EXTRA`, I5) | `docs/pipeline.md` | ✅ | § Permissions, parágrafo "The **project** adds its own…", em `52f9fdf`; a ressalva da gramática no alvo resolvido, em `f826567` |
| `bin/sdd` (`read_extra_dir_ok`: só nome literal, e o alvo do symlink só com regra quando passa, #7 da revisão final) | `docs/adr/0019-the-session-reads-what-the-boot-names.md` | ✅ | § 2, a gramática positiva e a regra do alvo resolvido, em `f826567` |
| `bin/sdd` (`READ_EXTRA`: o alcance de uma entrada igual a `$HOME` e o `readlink -f` na montagem do argv, #3 e #4) | `docs/adr/0019-the-session-reads-what-the-boot-names.md` | ✅ | Consequences, "Declared limits of the reach and of the probe", em `f826567` |
| `bin/sdd` (`READ_EXTRA`, alcance e `readlink -f`, #3 e #4) | `.claude/rules/anatomia-do-agente.md` | ⛔ | § 6, "Dívida declarada", depois de "— os dois saem como `DENIED` no journal."; texto em "Texto proposto" |
| `bin/sdd` (`READ_EXTRA`, I5) | `.claude/rules/anatomia-do-agente.md` | ✅ | § 2 ("Depois da regra dos templates vêm as do **projeto**…") e § 6, em `52f9fdf` |
| `bin/sdd` (`skill_findable` publica `SKILL_FOUND_DIR`, `read_rules_cover`, `skill_read_entry` e os dois avisos do preflight, I6) | `config/schema.md` | ✅ | linha `READ_EXTRA`, a skill achada e a entrada a declarar, em `e8fe91c` |
| `bin/sdd` (avisos do preflight, I6) | `docs/failure-modes.md` | ✅ | o mesmo verbete, "What you do", em `e8fe91c` |
| `bin/sdd` (avisos do preflight, I6) | `docs/pipeline.md` | ✅ | § Permissions, "`sdd preflight` warns, with no session…", em `e8fe91c` |
| `bin/sdd` (o alvo do symlink que a gramática recusa, sem entrada a declarar, R1) | `config/schema.md` | ✅ | linha `READ_EXTRA`, "The one exception hands no entry…", em `f9f3b34` |
| `bin/sdd` (R1) | `docs/failure-modes.md` | ✅ | verbete "The phase cannot read what the boot names", última frase do item das skills, em `f9f3b34` |
| `bin/sdd` (o `skill_findable` lê o `installPath` do `installed_plugins.json`, R2) | `config/schema.md` | ✅ | linha `READ_EXTRA`, "A plugin skill is the copy whose `installPath`…", em `5f05cf4` |
| `bin/sdd` (R2) | `config/starter.conf` | ✅ | a linha "A plugin skill is the copy ~/.claude/plugins/installed_plugins.json records", em `5f05cf4` |
| `bin/sdd` (R2) | `docs/failure-modes.md` | ✅ | verbete "The phase cannot read what the boot names", o registro e a frase do cache, em `5f05cf4` |
| `bin/sdd` (R2) | `docs/pipeline.md` | ✅ | § Permissions, "A plugin skill is the copy whose `installPath`…", em `5f05cf4` |
| `bin/sdd` (R2) | `docs/adr/0019-the-session-reads-what-the-boot-names.md` | ✅ | § 2, a cópia que o preflight confere é o `installPath` do registro, em `f826567` |
| `bin/sdd` (avisos do preflight, I6, R1 e R2) | `.claude/rules/anatomia-do-agente.md` | ✅ | § 2, "Onde mora hoje", em `e8fe91c`, `f9f3b34` e `5f05cf4` |
| `bin/sdd` (a regra de leitura e a sonda, o custo da sessão a mais, #6) | `docs/adr/0019-the-session-reads-what-the-boot-names.md` | ✅ | Consequences, o custo com uma grafia só, US$ 0.002 (US$ 0.00197 medidos em 2026-10-20 às 22:59, 2.1.304), em `f826567`; a mesma grafia está no ⛔ da anatomia § 4 |
| `tests/check-dry-run.sh`, `tests/check-gates.sh`, `tests/check-preflight.sh`, `tests/check-autonomy.sh` (as asserções dos Checks I1–I6, R1, R2) | — | n/a | asserções e mundos de fixture novos; o que os nomeia como probe (`docs/pipeline.md` § Permissions e a anatomia § 2 e § 4) foi escrito nos commits de cada incremento acima, e nenhum doc descreve os fixtures; o número de sensores (16) não mudou (`ls tests/check-*.sh` → 16) |
| `tests/check-mutation.sh` (26 mutantes novos, catálogo 716 → 742) | — | n/a | nenhum doc vivo escreve o tamanho do catálogo (`grep -n 716` em `README.md`, `CLAUDE.md`, `CONTEXT.md`, `docs/pipeline.md`, `docs/failure-modes.md` e na anatomia → vazio; o `CLAUDE.md` manda ler o número da linha `score:`); os nomes dos mutantes que a anatomia § 2 cita foram conferidos contra o diff (7 `mut_RUN_read_extra_*`, 9 `mut_PRE_*` dos avisos) |
| `TODO.md` (âncoras reancoradas pelos incrementos) | `TODO.md` | ✅ | 14 citações repostas na linha que citam, em `5705ebe`; conferência abaixo |
| `docs/adr/0019-the-session-reads-what-the-boot-names.md` (nova, escrita no PLAN) | `docs/adr/0019-the-session-reads-what-the-boot-names.md` | ✅ | alinhada ao código em `f826567`; `./bin/sdd adr check --mission 20261020-a-sessao-le-o-que-o-boot-manda --phase plan` → "and that ADR points back" |
| `docs/superpowers/specs/2026-09-23-a-gaveta-do-kit.md` (a F9 aprovada, `71fcc19`) | `docs/superpowers/specs/2026-09-23-a-gaveta-do-kit.md` | ✅ | linha F9 do índice (executada; o próximo passo é o PR) e o parágrafo da F3, em `9959b32` |
| missão inteira (antes e depois medidos, `kaizen_log:` vazio) | `KAIZEN_LOG.md` | ✅ | entrada "2026-10-21 — A sessão lê o que o boot manda ler", com o id da missão na linha **Missão:**, em `9959b32` |
| termos novos (`READ_EXTRA`, a linha `DENIED`, a regra de leitura do kit) | `CONTEXT.md` | n/a | nenhum termo de domínio novo: `READ_EXTRA` é chave de config (documentada no `config/schema.md`), `DENIED` é token do journal (no `docs/pipeline.md`), e a decisão mora na ADR 0019; as ADRs 0016 e 0017 também entraram sem verbete próprio, só citadas dentro de verbetes que já existiam (`grep -n '0016\|0017' CONTEXT.md` → linhas 45, 48 e 97) |
| `docs/handoffs/20261020-a-sessao-le-o-que-o-boot-manda/**` | — | n/a | artefatos da própria missão, não documentação viva |

## Texto proposto
<!-- sdd:proposed -->

Os três trechos são da `.claude/rules/anatomia-do-agente.md`, que o `writes:` do `sdd-docs` não cobre
(ADR 0013). O relay, que é a sessão interativa, os aplica, e o corpo do PR nomeia cada um numa linha com `⛔`.

**1.** Em `.claude/rules/anatomia-do-agente.md`, § 4 (Mecanismos de verificação), parágrafo "Onde mora hoje",
no fim do parágrafo da sonda dos templates, trocar
"Custa uma sessão haiku por preflight (US$ 0,0005 a 0,002, medido em 2.1.304)." por:

> Custa uma sessão haiku por preflight: US$ 0,002 (US$ 0,00197 medidos em 2026-10-20 às 22:59, Claude Code
> 2.1.304, com a regra lendo o template) e uns 6 s (as sondas p5 e p6 do grill, 16:24).

**2.** Em `.claude/rules/anatomia-do-agente.md`, § 4, parágrafo "Dívida declarada", depois de
"Resíduo: outra missão que reescreve o checkpoint byte a byte igual a uma versão da branch passa.", acrescentar:

> As duas sondas pagas do `sdd preflight` (a do `Bash` e a dos templates) têm teto de custo
> (`--max-budget-usd 1` cada) e nenhum de tempo: nada no runner encerra uma sessão de sonda que não responde
> (ADR 0019, Consequences).

**3.** Em `.claude/rules/anatomia-do-agente.md`, § 6 (Sandboxes), parágrafo "Dívida declarada", depois de
"regra — os dois saem como `DENIED` no journal.", acrescentar:

> A gramática segura o nome, não o alcance: uma entrada igual a `$HOME`, ou um symlink cujo alvo é a home,
> passa e vira `Read(//home/<usuário>/**)`, e toda fase lê a home inteira — só leitura, e a fase já tem
> `Bash`, então é higiene, não fronteira. O `readlink -f` roda na montagem do argv, uma vez por sessão: um
> symlink redirecionado durante a sessão falha fechado, com o alvo novo negado e nomeado pelo `DENIED`
> (ADR 0019, Consequences).

## Achados do `TODO_FILE` conferidos nesta missão

`bash tests/check-todo.sh` → `ok    29 finding(s), all within 8 lines, carrying anchor + date, every anchor on target`;
`--anchors TODO.md` → `ok    anchors: 29 measured, 0 off target`.

- **Nenhum achado nasceu nesta missão.** Os três da janela de `bad6168` entraram pelo chore #309 (`b96f3d3`),
  antes do I1 (decisão 4 do grill), já bem formados e revisados no PR dele. O § Achados fora de escopo do
  `20-handoff-exec.md` diz "Nenhum", e o `00-missao.md` não aponta outro.
- **Nenhum foi refutado ou decidido** por esta missão, então nada passou para `<!-- sdd:decided -->`, e nenhum
  corpo ganhou `RESOLVED by`.
- **As citações que a missão deslocou** (`5705ebe`): o sensor mede só a âncora principal, com tolerância de
  10 linhas. Conferidas uma a uma contra o diff de `b96f3d3`, cinco âncoras principais estavam uma linha acima
  do que citam (`bin/sdd:1856`, `:1924`, `:2712`, `:4115`, `:4348` → `1857`, `1925`, `2713`, `4116`, `4349`), e
  nove citações de corpo nunca tinham sido movidas: `bin/sdd:2183` (`k8_base_refusal`, → `2201`), `:1849`
  (→ `1867`), `:5877` (→ `6079`), `:7341` (→ `7644`), `:11444` (`cmd_link_agents`, → `11747`), `:11595`
  (`main`, → `11898`), `tests/check-autonomy.sh:2528` (→ `2557`), e o motivo literal do `sdd kaizen` em
  `docs/failure-modes.md:628` e `docs/pipeline.md:1482` (→ `665` e `1525`). Depois do conserto, as 46
  citações da seção aberta batem com o número velho mais o deslocamento.

## Boot da próxima fase

- **Leia primeiro:** este TL;DR e as três linhas `⛔` com o "Texto proposto" acima.
- **Antes do PR:** o relay aplica os três trechos na `.claude/rules/anatomia-do-agente.md` (sessão interativa;
  headless o `Edit` é recusado ali) e decide o merge da `origin/main` (`56db923`, que conflita no `TODO.md`).
- **PR:** o corpo leva as três linhas `⛔` (o `gate_PR` confere que cada documento `⛔` aparece numa linha com
  `⛔`), o antes e o depois do `KAIZEN_LOG.md` e as Pendências do `00-missao.md`. Depois, `@codex review`, os
  consertos numa leva, o `./bin/sdd health` (carimbo) e o merge humano.

## Pendências / Decisions for a Human

- **Aplicar o texto proposto** na `.claude/rules/anatomia-do-agente.md` (§ 4, duas vezes, e § 6).
- **O merge da `origin/main`:** o PR #308 (`56db923`) entrou depois do merge-base e acrescenta quatro achados ao
  `TODO.md` (catraca 29 → 33, `tests/health-baseline.txt`). Esta branch reancorou 14 citações do mesmo arquivo,
  então o merge vai conflitar ali; os itens novos do #308 citam `bin/sdd` pela numeração de `b96f3d3` e
  precisam do mesmo deslocamento (o `--anchors` diz quais). `tests/health-baseline.txt` é catraca e fica fora da
  chave do carimbo.
- **Opcional, `config/schema.md`:** a seção "What the phases read beyond the repo" diz a gramática como o código,
  mas não o limite do alcance (#3: uma entrada igual a `$HOME` passa). A frase que caberia no parágrafo ⚠️ dela:
  *"The grammar holds the name, not the reach: an entry equal to `$HOME`, or a symlink pointing there, passes it
  and lets every phase read the whole home — for reading only, and the phases already have `Bash`, so it is
  hygiene, not a boundary (ADR 0019)."* Ficou fora porque `config/` está na chave do carimbo e a fase de código
  acabou (ordem do relay); como o carimbo ainda não foi tirado, aplicá-la antes do `./bin/sdd health` não custa
  corrida a mais.
- As do `00-missao.md`, itens 2 a 4: o `additionalDirectories` posto à mão e o `"Read(*)"` do `sales_quote`; o
  yokoten do `READ_EXTRA` no lighthouse e no jrc-libs; o carimbo depois da revisão do PR. O `.sdd/config.sh` do
  próprio kit também tem o `READ_EXTRA` vazio, então o `./bin/sdd preflight` daqui avisa a `codereview` com a
  entrada `$HOME/.claude/plugins/cache/chewiesoft-marketplace/codereview`.

## Riscos e não-feitos

- Nenhum drift em `bin/ tests/ templates/ config/ agents/` ficou como pendência de código: os comentários de
  `kit_read_rules`, `read_extra_dir_ok`, `skill_findable` e da sonda do `Bash` já dizem o que o código faz (o
  último desde o R2). O único texto proposto para `config/` é o opcional acima, que é limite novo e não drift.
- O "uns 6 s" da sonda vem das sondas p5 e p6 do grill (16:24); a medição das 22:59 não registrou duração.
- A anatomia § 5 diz "`CLAUDE.md` em 491 linhas", e ele já tinha 577 no merge-base (578 agora): drift anterior
  a esta missão, fora do escopo, não proposto.
- A suíte inteira não rodou depois destes commits: só `check-lang`, `check-todo` e `check-adr`, que são os que
  leem `docs/`, `TODO.md` e a ADR.
