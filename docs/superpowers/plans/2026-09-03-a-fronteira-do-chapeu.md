# A fronteira do chapéu — plano de implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** cada chapéu do kit declara no próprio frontmatter o que nega, onde escreve e que MCP vê; o runner aplica isso por flag em toda fase headless, para a linha quando um chapéu sai da fronteira, e o artefato (linha `init` do stream, `permission_denials`, ledger) prova que a fronteira valeu.

**Architecture:** três chaves de frontmatter (`disallowedTools:`, `writes:`, `mcp:`) lidas pelo `frontmatter()` que já existe; `run_phase` passa `--disallowedTools` e `--strict-mcp-config`; um marcador por guarda (`HAT_CROSSED_WHY`, `KIT_TOUCHED_WHY`), armado logo depois da sessão e lido por **uma** porta de escalada (`hat_crossed_escalation`) em quatro sítios, depois da linha de sessão do ledger; três campos novos na linha de sessão (`mcp_seen`, `tools_leaked`, `denials`) lidos do stream; `sdd census` como instrumento; ADR 0007 e `sdd health --release` como placar da aptidão.

**Tech Stack:** bash (`set -euo pipefail`), `jq`, `git`, markdown; a suíte `tests/run-all.sh` com sensores em bash e o catálogo de mutação `tests/check-mutation.sh`.

**Spec:** [`docs/superpowers/specs/2026-09-03-a-fronteira-do-chapeu-design.md`](../specs/2026-09-03-a-fronteira-do-chapeu-design.md) — o plano argumenta a partir dela; execute com as duas abertas.

## Global Constraints

- **Superfície do kit em inglês**: `bin/sdd`, `agents/`, `docs/adr/`, `docs/pipeline.md`, `tests/`, `README.md`, `config/` — prosa, comentários, mensagens. Arquivo novo entra na catraca de `tests/check-lang.sh`. Este plano e os commits ficam em pt-BR (`OUTPUT_LANG`).
- **`bash -n bin/sdd`** antes de todo commit que toca o runner; a última linha do `bin/sdd` é `{ main "$@"; exit $?; }` e não muda.
- **Captura sob `set -e`**: toda `x="$(cmd)"` cujo `cmd` pode devolver não-zero leva `|| x=""` ou `|| true`. Na região do `sdd health` isso é cobrado pela regra `guard:` do `tests/check-health.sh`.
- **`printf … | grep -q` é proibido** (SIGPIPE inverte sob `pipefail`): use herestring `<<< "$var"`. `grep -m<N>` sem `-q` também é proibido (RULE 3 do `check-pipefail.sh`).
- **`cd` com operando relativo dentro de `$(...)` leva `CDPATH=''`**.
- **Comentário nunca dentro de bloco continuado por `\`**.
- **Fixture que imita saída do harness é copiado de uma sessão real**, com o comando de captura no comentário de proveniência — nunca escrito de memória.
- **Gate/guarda/porta nova entra com mutante** em `tests/check-mutation.sh`, ancorado em CÓDIGO (nunca em prosa), e com um probe por porta.
- **Sensor novo entra em cinco lugares**: linha `run` do `tests/run-all.sh`, `LINT_FLOOR` (15 → 16), piso de superfície do `check-pipefail.sh` (`-lt 14` → `-lt 15`) mais o laço do fixture do selftest dele (13 → 14 arquivos), piso do `check-lang.sh` (`-lt 41` → `-lt 45`).
- **Um enum lido em mais de um ponto vira uma definição**: `phase_hat()` é a única tabela passo → chapéu; `HAT_DENY_BASE` e `HAT_WRITES_BASE` são definidos uma vez.
- **Achado fora de escopo → `TODO.md`** no formato de 6 linhas, e a catraca `todo-findings` em `tests/health-baseline.txt` move junto, num diff com autor.
- **`./bin/sdd health` roda depois do último commit de código** (a chave do carimbo é o conteúdo de `bin/ tests/ templates/ config/`); antes disso, `pgrep -af 'bin/sdd run'` tem de responder vazio.
- **Nunca `cp` nem Edit em `.claude/agents/`**: o espelho se sincroniza com `./bin/sdd install --force` rodado na raiz do kit.

---

### Task 1: Os chapéus declaram, e o TICKET ganha chapéu próprio

**Files:**
- Create: `tests/check-hat.sh`
- Create: `agents/sdd-ticket.md`
- Modify: `agents/sdd-executor.md`, `agents/sdd-reviewer.md`, `agents/sdd-qa.md`, `agents/sdd-docs.md`, `agents/sdd-publisher.md`, `agents/sdd-kaizen.md`, `agents/sdd-planner.md` (frontmatter)
- Modify: `bin/sdd:1597-1610` (`phase_agent` → `phase_hat` + derivado)
- Modify: `tests/run-all.sh:131` (LINT_FLOOR), `:213` (linha `run`); `tests/check-pipefail.sh:895` e `:831`; `tests/check-lang.sh:140`
- Modify: `tests/check-dry-run.sh:428` (`TICKET=sdd-publisher` → `TICKET=sdd-ticket`)
- Modify: `README.md:140,146-156`

**Interfaces:**
- Produces: frontmatter keys `disallowedTools:`, `writes:`, `mcp:` em todo `agents/sdd-*.md`, valor em linha única, itens separados por vírgula, placeholders `$HANDOFF_DIR`, `$MISSION`, `$TODO_FILE`, `$QA_DOCS_PATH`, `$E2E_DIR` em `writes:`.
- Produces: `phase_hat <step>` → nome do chapéu (`sdd-executor` … `sdd-ticket`, `""` se não há); `phase_agent <step>` → o chapéu que sobe com `--agent` (vazio para `QA:plan` e `QA:exec`).
- Produces: `tests/check-hat.sh` com modo `--check <arquivo>` e `selftest`.

- [ ] **Step 1: Escrever o sensor `tests/check-hat.sh` (vermelho por construção: nenhum chapéu declara nada ainda)**

```bash
#!/usr/bin/env bash
# Sensor for the hat's boundary DECLARATIONS — the frontmatter of agents/sdd-*.md.
#
# Every hat carries three keys: `disallowedTools:` (what it denies beyond HAT_DENY_BASE — a
# harness key), `writes:` (globs of what the phase may have touched when it ends — a kit key) and
# `mcp:` (MCP servers it may see — a kit key; empty ⇒ --strict-mcp-config). The runner reads them
# with frontmatter() and applies them by flag (bin/sdd: hat_disallowed, hat_writes, hat_mcp);
# what this file measures is the DECLARATION, because a hat that declares nothing is a hat that
# gets everything, silently. Spec: docs/superpowers/specs/2026-09-03-a-fronteira-do-chapeu-design.md.
#
# Rules, each with a selftest probe below:
#   R1  every agents/sdd-*.md carries the three keys (present; empty is a legal value)
#   R2  every `$name` in `writes:` is one of the placeholders the runner expands — an unknown one
#       would never match a path and the whole hat would read as "writes nowhere"
#   R3  every `disallowedTools:` item is `Name` or `Name(pattern)` — a stray quote or a bare `(`
#       is a token the harness would neither deny nor refuse
# Floor: at least 8 hats on disk, or the glob stopped matching and this sensor reads nothing.
#
# This file measures markdown, so no sabotage of bin/sdd can make it die: it carries a selftest
# (`tests/check-hat.sh selftest`, rc 90 = a probe failed, 93 = the probe floor shrank), and the
# selftest exercises the REPORTING path through `--check <file>`, never the parser alone.
#
# Usage: tests/check-hat.sh              (exit 0 = every hat declares its boundary)
#        tests/check-hat.sh --check <f>  (one file, exit 1 on any violation — the selftest's path)
#        tests/check-hat.sh selftest
set -uo pipefail
ROOT="$(CDPATH='' cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HAT_FLOOR=8
PLACEHOLDERS='HANDOFF_DIR|MISSION|TODO_FILE|QA_DOCS_PATH|E2E_DIR'
fails=0
pass() { printf '  ok    %s\n' "$1"; }
fail() { printf '  FAIL  %s\n' "$1" >&2; fails=$((fails + 1)); }

# fm_value <file> <key> — the frontmatter value, quotes stripped; prints the sentinel when absent
ABSENT='@absent@'
fm_value() {
  awk -v k="$2" -v absent="$ABSENT" '
    NR==1 && $0=="---" { inside=1; next }
    inside && $0=="---" { exit }
    inside {
      idx = index($0, ":"); if (idx == 0) next
      name = substr($0, 1, idx-1); gsub(/^[ \t]+|[ \t]+$/, "", name)
      if (name == k) { found = 1; val = substr($0, idx+1); gsub(/^[ \t]+|[ \t]+$/, "", val)
                       gsub(/^["'\'']|["'\'']$/, "", val); print val; exit }
    }
    END { if (!found) print absent }' "$1"
}

# check_file <agent file> — R1..R3 over one hat; prints one line per verdict, rc 1 on any FAIL
check_file() {
  local f="$1" name key v item bad=0
  name="$(basename "$f")"
  for key in disallowedTools writes mcp; do
    v="$(fm_value "$f" "$key")"
    if [ "$v" = "$ABSENT" ]; then fail "R1 $name: no '$key:' in the frontmatter"; bad=1; fi
  done
  v="$(fm_value "$f" writes)"
  if [ "$v" != "$ABSENT" ]; then
    while IFS= read -r item; do
      [ -n "$item" ] || continue
      if ! grep -qE "^\\\$($PLACEHOLDERS)\$" <<< "$item"; then
        fail "R2 $name: writes: names '\$$item', not a placeholder the runner expands ($PLACEHOLDERS)"; bad=1
      fi
    done <<< "$(grep -oE '\$[A-Za-z_]+' <<< "$v" | sed 's/^\$//' || true)"
  fi
  v="$(fm_value "$f" disallowedTools)"
  if [ "$v" != "$ABSENT" ] && [ -n "$v" ]; then
    while IFS= read -r item; do
      item="${item#"${item%%[![:space:]]*}"}"; item="${item%"${item##*[![:space:]]}"}"
      [ -n "$item" ] || continue
      if ! grep -qE '^[A-Za-z][A-Za-z0-9_]*(\([^()"]+\))?$' <<< "$item"; then
        fail "R3 $name: disallowedTools item '$item' is not Name or Name(pattern)"; bad=1
      fi
    done <<< "$(tr ',' '\n' <<< "$v")"
  fi
  [ "$bad" -eq 0 ] && pass "$name declares disallowedTools, writes and mcp"
  return "$bad"
}

selftest() {
  local box p PROBES=0 FAILS=0
  box="$(mktemp -d "${TMPDIR:-/tmp}/sdd-hat-selftest-XXXXXX")"
  trap 'rm -rf "$box"' RETURN
  # probe <description> <expected rc> <file body> — through --check, the reporting path
  probe() {
    local desc="$1" want="$2" body="$3" got
    printf '%s\n' "$body" > "$box/sdd-probe.md"
    "$ROOT/tests/check-hat.sh" --check "$box/sdd-probe.md" >/dev/null 2>&1; got=$?
    PROBES=$((PROBES + 1))
    if [ "$got" = "$want" ]; then printf '  ok    %s\n' "$desc"
    else printf '  FAIL  %s (rc %s, wanted %s)\n' "$desc" "$got" "$want" >&2; FAILS=$((FAILS + 1)); fi
  }
  probe 'a hat with the three keys passes' 0 $'---\nname: x\ndisallowedTools: "Agent, Bash(git push:*)"\nwrites: "$HANDOFF_DIR/$MISSION/**, $TODO_FILE"\nmcp: ""\n---\nbody'
  probe 'empty values are legal' 0 $'---\nname: x\ndisallowedTools: ""\nwrites: ""\nmcp: ""\n---\nbody'
  probe 'R1: a hat without writes: fails' 1 $'---\nname: x\ndisallowedTools: ""\nmcp: ""\n---\nbody'
  probe 'R1: a hat without mcp: fails' 1 $'---\nname: x\ndisallowedTools: ""\nwrites: ""\n---\nbody'
  probe 'R1: a hat without disallowedTools: fails' 1 $'---\nname: x\nwrites: ""\nmcp: ""\n---\nbody'
  probe 'R2: an unknown placeholder fails' 1 $'---\nname: x\ndisallowedTools: ""\nwrites: "$HANDOFFS/**"\nmcp: ""\n---\nbody'
  probe 'R3: a stray quote in a deny item fails' 1 $'---\nname: x\ndisallowedTools: "Agent, \\"Bash(git push:*)"\nwrites: ""\nmcp: ""\n---\nbody'
  probe 'R3: a bare pattern without a tool name fails' 1 $'---\nname: x\ndisallowedTools: "(git push:*)"\nwrites: ""\nmcp: ""\n---\nbody'
  probe 'negative control: a key AFTER the closing --- is body, not frontmatter' 1 $'---\nname: x\ndisallowedTools: ""\nwrites: ""\n---\nmcp: ""'
  if [ "$PROBES" -lt 9 ]; then printf '  probe floor shrank: %d < 9\n' "$PROBES" >&2; return 93; fi
  [ "$FAILS" -eq 0 ] || return 90
  printf '  ok    check-hat selftest: %d probes\n' "$PROBES"
}

case "${1:-}" in
  selftest) selftest; exit $? ;;
  --check)  check_file "$2"; exit $? ;;
esac

n=0
for f in "$ROOT"/agents/sdd-*.md; do
  [ -e "$f" ] || continue
  n=$((n + 1))
  check_file "$f" || true
done
if [ "$n" -lt "$HAT_FLOOR" ]; then
  printf '  hat surface shrank: %d agents/sdd-*.md, expected at least %d — did something move?\n' "$n" "$HAT_FLOOR" >&2
  exit 93
fi
selftest || exit $?
if [ "$fails" -eq 0 ]; then printf '  ok    %d hat(s) declare their boundary\n' "$n"; exit 0; fi
printf '%d hat check(s) failed\n' "$fails" >&2
exit 1
```

- [ ] **Step 2: Rodar o sensor e ver o vermelho pelo motivo certo**

Run: `chmod +x tests/check-hat.sh && tests/check-hat.sh; echo rc=$?`
Expected: 7 linhas `FAIL  R1 …` por chapéu (21 no total), depois `hat surface shrank: 7 agents/sdd-*.md, expected at least 8` e `rc=93`. O selftest ainda não roda porque o piso vem antes; confira-o à parte:

Run: `tests/check-hat.sh selftest; echo rc=$?`
Expected: 9 linhas `ok`, `check-hat selftest: 9 probes`, `rc=0`.

- [ ] **Step 3: Nascer `agents/sdd-ticket.md` da seção TICKET do publisher**

```bash
cd ~/repos/sdd_agents
{
cat <<'EOF'
---
name: sdd-ticket
description: >-
  Opens the mission's JIRA issue through the `ticket` skill, already in the active sprint, creates
  the branch and records 10-ticket.md. The TICKET phase of the `sdd` runner. A mechanical task —
  runs on Sonnet by explicit cost decision. Never pushes, never opens a PR.
disallowedTools: "Bash(git push:*), Bash(gh pr create:*), Bash(gh pr merge:*), Agent, ListAgents, ScheduleWakeup, Monitor"
writes: "$HANDOFF_DIR/$MISSION/**"
mcp: ""
---

# sdd-ticket

You are the first automated phase, and the only one that talks to JIRA. The `ticket` skill does
the work; your job is to feed it the truth already written in `00-missao.md` and to record what
it created where the runner can read it.

The runner confirms the issue **through `acli`**, not through your file: an `issue:` that is not
in the active sprint fails the gate — and it is good that it does.

EOF
sed -n '91,129p' agents/sdd-publisher.md | sed '1s/^## TICKET phase$/## What to do/'
cat <<'EOF'

## Language

Write the artifact prose in the language the target repo declares in `OUTPUT_LANG`
(`.sdd/config.sh`); when it is empty, follow whatever language the existing artifacts and commit
history already use. Frontmatter keys, file names and status tokens are contract — always English.

## Rules that are not negotiable

- Never push. Never open a PR. Never merge. The PR phase does that, on another hat.
- Never decide the version label — it comes from `00-missao.md`.
- Never leave the turn with a task still running in the background: in a headless session ending
  the turn ends the session, and nothing resumes it.
EOF
} > agents/sdd-ticket.md
# and take the section out of the publisher, whose description stops mentioning TICKET
sed -i '91,129d' agents/sdd-publisher.md
python3 - <<'PY'
p='agents/sdd-publisher.md'; s=open(p,encoding='utf-8').read()
old="  phase. Also the agent of the TICKET phase (opens the JIRA issue through the `ticket` skill).\n  A mechanical task"
new="  phase. A mechanical task"
assert old in s; s=s.replace(old,new,1); open(p,'w',encoding='utf-8').write(s)
PY
grep -c '^## ' agents/sdd-ticket.md   # → 4  (What to do, Language, Rules… plus the H1 is not counted)
```

Expected: `agents/sdd-ticket.md` existe com o passo a passo numerado 1–4 e o bloco YAML de `10-ticket.md` intactos; `agents/sdd-publisher.md` não tem mais `## TICKET phase` (`grep -c 'TICKET phase' agents/sdd-publisher.md` → `0`).

- [ ] **Step 4: Escrever as três chaves nos sete chapéus existentes**

Cada bloco entra **antes** do `---` que fecha o frontmatter (a linha vazia que precede `---` fica como está). Use `python3` para inserir logo antes do segundo `---`:

```bash
cd ~/repos/sdd_agents
add_keys() {   # add_keys <file> <disallowedTools> <writes>
python3 - "$1" "$2" "$3" <<'PY'
import sys
p, deny, writes = sys.argv[1:4]
s = open(p, encoding='utf-8').read()
head, rest = s.split('\n---\n', 1)          # head = the frontmatter without its closing fence
assert head.startswith('---\n'), p
block = f'disallowedTools: "{deny}"\nwrites: "{writes}"\nmcp: ""'
open(p, 'w', encoding='utf-8').write(head + '\n' + block + '\n---\n' + rest)
PY
}
BASE_DENY='Bash(git push:*), Bash(gh pr create:*), Bash(gh pr merge:*), ScheduleWakeup, Monitor'
MECH_DENY="$BASE_DENY, Agent, ListAgents, Skill"
add_keys agents/sdd-executor.md  "$BASE_DENY" ""
add_keys agents/sdd-reviewer.md  "$BASE_DENY" '$HANDOFF_DIR/$MISSION/**'
add_keys agents/sdd-qa.md        "$BASE_DENY" '$HANDOFF_DIR/$MISSION/**, $QA_DOCS_PATH/**, $E2E_DIR/**'
add_keys agents/sdd-docs.md      "$MECH_DENY" '$HANDOFF_DIR/$MISSION/**, README.md, CLAUDE.md, CONTEXT.md, CHANGELOG.md, KAIZEN_LOG.md, .claude/rules/**, docs/**'
add_keys agents/sdd-publisher.md 'Bash(gh pr merge:*), Bash(git merge:*), Agent, ListAgents, Skill, ScheduleWakeup, Monitor' '$HANDOFF_DIR/$MISSION/**'
add_keys agents/sdd-kaizen.md    "$BASE_DENY" '$HANDOFF_DIR/**, KAIZEN_LOG.md'
add_keys agents/sdd-planner.md   "$BASE_DENY" '$HANDOFF_DIR/$MISSION/**'
grep -c '^writes:' agents/sdd-*.md
```

Expected: cada um dos 8 arquivos responde `1`. O `$TODO_FILE` e o `tests/health-baseline.txt` **não** aparecem em nenhum `writes:` — são a base de todo chapéu (`HAT_WRITES_BASE`, Task 3), porque o princípio 5 manda todo agente registrar achado ali.

- [ ] **Step 5: Rodar o sensor de novo**

Run: `tests/check-hat.sh; echo rc=$?`
Expected: 8 linhas `ok    sdd-*.md declares disallowedTools, writes and mcp`, as 9 do selftest, `ok    8 hat(s) declare their boundary`, `rc=0`.

- [ ] **Step 6: `phase_hat()` vira a única tabela, e `phase_agent()` deriva dela**

Em `bin/sdd:1597-1610`, substitua a função `phase_agent()` inteira por:

```bash
# The ONE table step → hat (the agents/<hat>.md whose boundary the phase inherits). phase_agent()
# derives from it: the two skill-driven QA steps boot WITHOUT --agent (the slash IS their prompt,
# see phase_slash below) but still wear sdd-qa's boundary. Two `case`s over the same enum was the
# thing CLAUDE.md forbids; this is the definition, and the other one is a filter over it.
phase_hat() {
  case "$1" in
    EXEC)        printf '%s\n' "sdd-executor" ;;
    QA|QA:*)     printf '%s\n' "sdd-qa" ;;
    REVIEW)      printf '%s\n' "sdd-reviewer" ;;
    DOCS)        printf '%s\n' "sdd-docs" ;;
    PR)          printf '%s\n' "sdd-publisher" ;;
    TICKET)      printf '%s\n' "sdd-ticket" ;;
    KAIZEN)      printf '%s\n' "sdd-kaizen" ;;
    *)           printf '%s\n' "" ;;
  esac
}
phase_agent() {
  case "$1" in
    QA:plan|QA:exec) printf '%s\n' "" ;;
    *)               phase_hat "$1" ;;
  esac
}
```

Atualize o comentário de `bin/sdd:1617-1619` ("agents/sdd-publisher.md already tells the session to invoke `/ticket open`") para `agents/sdd-ticket.md`.

- [ ] **Step 7: Os cinco lugares da suíte e a projeção**

```bash
cd ~/repos/sdd_agents
sed -i 's/^LINT_FLOOR=15$/LINT_FLOOR=16/' tests/run-all.sh
sed -i 's|^run "preflight and the install guard" "$ROOT/tests/check-preflight.sh"$|&\nrun "every hat declares its boundary" "$ROOT/tests/check-hat.sh"|' tests/run-all.sh
sed -i 's/if \[ "\$n_files" -lt 14 \]; then/if [ "$n_files" -lt 15 ]; then/' tests/check-pipefail.sh
sed -i 's/for i in 1 2 3 4 5 6 7 8 9 10 11 12 13; do : > "\$tree\/tests\/check-\$i.sh"; done/for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14; do : > "$tree\/tests\/check-$i.sh"; done/' tests/check-pipefail.sh
sed -i 's/if \[ "\$n_surface" -lt 41 \]; then/if [ "$n_surface" -lt 45 ]; then/' tests/check-lang.sh
sed -i 's/"TICKET=sdd-publisher" "\$(printf/"TICKET=sdd-ticket" "$(printf/' tests/check-dry-run.sh
grep -nE 'LINT_FLOOR=|check-hat' tests/run-all.sh; grep -nE '\-lt 15|1[34]; do' tests/check-pipefail.sh; grep -n '\-lt 45' tests/check-lang.sh; grep -n 'TICKET=sdd-ticket' tests/check-dry-run.sh
```

Expected: cada `grep` acha a linha nova. O comentário em `tests/check-dry-run.sh:415-418` que explica o TICKET (fala em `sdd-publisher`) passa a dizer `sdd-ticket`.

- [ ] **Step 8: README: oito chapéus, contados do disco**

Em `README.md:140` troque `the 6 agents` por `the 8 agents`; em `:146` o título `## The 6 agents` por `## The 8 agents`; na tabela, a linha do `sdd-publisher` vira `| \`sdd-publisher\` | PR (push + opens the PR) | Sonnet | open PR + \`50-pr.md\` |` e ganha duas linhas novas logo abaixo:

```markdown
| `sdd-ticket` | TICKET (opens the issue, in the active sprint) | Sonnet | `10-ticket.md`, the mission branch |
| `sdd-kaizen` | KAIZEN — the kit judging its own last change (`sdd kaizen`, kit repo only) | Opus | `05-verdict.md` + the next mission's plan |
```

Run: `ls agents/sdd-*.md | wc -l; grep -c 'sdd-' <(sed -n '/^## The 8 agents/,/^$/p' README.md)`
Expected: `8` e uma contagem de linhas de tabela igual a `8` (uma por chapéu).

- [ ] **Step 9: Espelho, sintaxe, suíte rápida**

Run: `bash -n bin/sdd && ./bin/sdd install --force >/dev/null && git status --short .claude/agents/ && tests/run-all.sh 2>&1 | tail -5`
Expected: `bash -n` calado; `.claude/agents/sdd-ticket.md` novo e os outros sete modificados; a suíte verde com a linha `▸ every hat declares its boundary` presente e `score:` intacto.

- [ ] **Step 10: Commit**

```bash
git add tests/check-hat.sh agents/ .claude/agents/ bin/sdd tests/run-all.sh tests/check-pipefail.sh tests/check-lang.sh tests/check-dry-run.sh README.md
git commit -m "feat(agents): cada chapéu declara disallowedTools, writes e mcp; o TICKET ganha chapéu próprio

Três chaves de frontmatter por chapéu, lidas pelo frontmatter() que já existe: o que nega além da
base, onde pode ter escrito, que MCP pode ver. Sensor tests/check-hat.sh com selftest (mede
markdown, então a mutação não o alcança) e piso de 8 chapéus. sdd-ticket.md nasce da seção TICKET
do publisher: um chapéu, uma fronteira — só o PR empurra (spec § 3, D5). phase_hat() é a única
tabela passo → chapéu; phase_agent() deriva dela.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 2: O runner aplica: `--disallowedTools` por fase e `--strict-mcp-config`

**Files:**
- Modify: `bin/sdd` (novo bloco depois de `phase_agent()`, ~`:1622`; `run_phase()` `:2876-2915`; `load_config` nada)
- Modify: `tests/check-dry-run.sh` (asserções sobre a linha `boundary:` da projeção)
- Modify: `tests/check-mutation.sh` (dois mutantes)
- Modify: `docs/pipeline.md:536-541` (Permissions), `config/schema.md:106`

**Interfaces:**
- Consumes: `phase_hat`, `frontmatter` (Task 1).
- Produces: `HAT_DENY_BASE` (string), `HAT_WRITES_BASE` (string com placeholders), `hat_field <hat> <key>`, `hat_disallowed <step>`, `hat_mcp <step>`, `hat_expand <globs>`, `hat_writes <step>` (globs expandidos ou vazio = qualquer lugar); globais `LAST_PHASE_STREAM`, `LAST_PHASE_DISALLOWED`, `LAST_PHASE_MCP`; a linha `boundary: deny=… | writes=… | mcp=…` na projeção `--dry-run`.

- [ ] **Step 1: A asserção primeiro — a projeção tem de mostrar a fronteira de cada fase**

Em `tests/check-dry-run.sh`, logo depois da função `projected()` (`:47-56`), acrescente:

```bash
# boundary_of <phase> — the `boundary:` line the projection prints under that phase's `agent:`
boundary_of() {
  awk -v want="$1" '
    /^--- DRY RUN: phase .* ---$/ { ph = $5; next }
    ph == want && /boundary:/ { sub(/^.*boundary:[ \t]*/, ""); print; exit }
  '
}
```

E depois da asserção `"projects EXEC→QA→REVIEW→DOCS→PR, in order, each with its agent"` (`:141`):

```bash
echo "== every projected phase carries the hat's boundary =="
for ph in EXEC QA:close REVIEW DOCS PR; do
  b="$(printf '%s\n' "$out" | boundary_of "$ph")"
  assert_eq "$ph: the deny list starts with the base no phase ever used" "1" \
    "$(grep -c 'deny=CronCreate, CronDelete' <<< "$b")"
  assert_eq "$ph: MCP is strict when the hat declares none" "1" "$(grep -c 'mcp=<none: --strict-mcp-config>' <<< "$b")"
done
assert_eq "REVIEW denies the push the hat never needs" "1" \
  "$(printf '%s\n' "$out" | boundary_of REVIEW | grep -c 'Bash(git push:\*)')"
assert_eq "REVIEW writes only under the mission directory (plus the base)" "1" \
  "$(printf '%s\n' "$out" | boundary_of REVIEW | grep -c "writes=TODO.md, tests/health-baseline.txt, docs/handoffs/$MISSION/\*\*")"
assert_eq "EXEC writes anywhere" "1" "$(printf '%s\n' "$out" | boundary_of EXEC | grep -c 'writes=<anywhere>')"
assert_eq "DOCS denies the subagent it never used" "1" "$(printf '%s\n' "$out" | boundary_of DOCS | grep -c ', Agent, ListAgents, Skill')"
assert_eq "PR keeps push and gh pr create, denies merge" "1" \
  "$(printf '%s\n' "$out" | boundary_of PR | grep -c 'Bash(gh pr merge:\*)' )"
assert_eq "PR does not deny push" "0" "$(printf '%s\n' "$out" | boundary_of PR | grep -c 'git push')"
```

Run: `tests/check-dry-run.sh 2>&1 | grep -E 'FAIL|boundary' | head`
Expected: 16 `FAIL` (nenhuma linha `boundary:` existe ainda).

- [ ] **Step 2: As definições, uma vez, no `bin/sdd`**

Logo depois de `phase_agent()` (Task 1, ~`:1622`), antes do comentário de `phase_slash`:

```bash
# --- the hat's boundary --------------------------------------------------------------------------
# The hat DECLARES (agents/<hat>.md: disallowedTools:, writes:, mcp:), the runner APPLIES
# (--disallowedTools, --strict-mcp-config, hat_guard_check) and the artifact PROVES (the stream's
# init line and the result's permission_denials, read into the ledger). In a `-p` session the
# harness honours only model/permissionMode/skills from the --agent file's frontmatter
# (code.claude.com/docs/en/sub-agents.md, checked 2026-09-03), so a `disallowedTools:` line that
# only lived in the file would be a phrase; the flag is the rule. Spec:
# docs/superpowers/specs/2026-09-03-a-fronteira-do-chapeu-design.md.
#
# HAT_DENY_BASE: what NO phase used across the 43 sessions the spec measured (§ 2.1). A property of
# the pipeline, defined once; each hat adds its own line. `Agent` is NOT here: the reviewer's
# codereview skill dispatches subagents and the executor's prompt asks for them.
HAT_DENY_BASE="CronCreate, CronDelete, CronList, DesignSync, EnterWorktree, ExitWorktree, RemoteTrigger, SendMessage, PushNotification, Workflow, NotebookEdit, ReportFindings, ListMcpResourcesTool, ReadMcpResourceTool, ReadMcpResourceDirTool, WebSearch, WebFetch"
# HAT_WRITES_BASE: what EVERY hat may touch — principle 5 sends any agent's finding to TODO_FILE,
# and in the kit that moves the backlog ratchet in tests/health-baseline.txt.
HAT_WRITES_BASE='$TODO_FILE, tests/health-baseline.txt'

hat_field() { frontmatter "$SDD_HOME/agents/$1.md" "$2"; }   # hat_field <hat> <key> — "" when absent

hat_disallowed() {   # hat_disallowed <step> — the base plus the hat's own line, comma-separated
  local hat own=""
  hat="$(phase_hat "$1")"
  if [ -n "$hat" ]; then own="$(hat_field "$hat" disallowedTools)"; fi
  printf '%s%s\n' "$HAT_DENY_BASE" "${own:+, $own}"
}

hat_mcp() {   # hat_mcp <step> — the MCP servers the hat may see; "" ⇒ --strict-mcp-config
  local hat
  hat="$(phase_hat "$1")"
  if [ -n "$hat" ]; then hat_field "$hat" mcp; else printf '\n'; fi
}

hat_expand() {   # hat_expand <globs> — $HANDOFF_DIR $MISSION $TODO_FILE $QA_DOCS_PATH $E2E_DIR
  local s="$1" hd="$HANDOFF_DIR"
  while [ "${hd%/}" != "$hd" ]; do hd="${hd%/}"; done
  s="${s//\$HANDOFF_DIR/$hd}"
  s="${s//\$MISSION/$MISSION}"
  s="${s//\$TODO_FILE/$TODO_FILE}"
  s="${s//\$QA_DOCS_PATH/${QA_DOCS_PATH%/}}"
  s="${s//\$E2E_DIR/${E2E_DIR%/}}"
  printf '%s\n' "$s"
}

hat_writes() {   # hat_writes <step> — expanded globs; "" when the hat may write anywhere
  local hat own=""
  hat="$(phase_hat "$1")"
  if [ -n "$hat" ]; then own="$(hat_field "$hat" writes)"; fi
  if [ -z "$own" ]; then printf '\n'; return 0; fi
  hat_expand "$HAT_WRITES_BASE, $own"
}
```

- [ ] **Step 3: `run_phase` passa as flags, publica o que passou, e a projeção mostra**

Em `run_phase()` (`bin/sdd:2876`), depois de `prompt="$(boot_prompt "$pstep")"` e antes de `local -a cmd=(`:

```bash
  local disallowed mcp writes
  disallowed="$(hat_disallowed "$pstep")"
  mcp="$(hat_mcp "$pstep")"
  writes="$(hat_writes "$pstep")"
```

Na montagem de `cmd`, depois de `--allowedTools "$ALLOWED_TOOLS"` acrescente a linha `--disallowedTools "$disallowed"`, e depois do `if [ -n "$agent" ]; then cmd+=(--agent "$agent"); fi`:

```bash
  # Empty mcp: ⇒ the session sees no MCP server at all. A hat that declares some sees the whole
  # set (a declared exception, measured by hat_init_facts against its list) — carving the human's
  # servers into a --mcp-config of our own is YAGNI until a hat needs one.
  if [ -z "$mcp" ]; then cmd+=(--strict-mcp-config); fi
```

No bloco `DRY_RUN`, logo depois do `printf '%smodel:%s %s   %sagent:%s %s …'`:

```bash
    printf '%sboundary:%s deny=%s | writes=%s | mcp=%s\n' "$C_DIM" "$C_RESET" \
      "$disallowed" "${writes:-<anywhere>}" "${mcp:-<none: --strict-mcp-config>}"
```

E junto das publicações `LAST_PHASE_*` (depois de `LAST_PHASE_MODEL="$model"`):

```bash
  LAST_PHASE_STREAM="$streamfile"
  LAST_PHASE_DISALLOWED="$disallowed"
  LAST_PHASE_MCP="$mcp"
```

Com as declarações ao lado das outras (`LAST_PHASE_MODEL=""` no fim da função): `LAST_PHASE_STREAM=""`, `LAST_PHASE_DISALLOWED=""`, `LAST_PHASE_MCP=""`.

- [ ] **Step 4: Verde**

Run: `bash -n bin/sdd && tests/check-dry-run.sh 2>&1 | grep -cE '^  ok'; tests/check-dry-run.sh >/dev/null 2>&1; echo rc=$?`
Expected: contagem de `ok` maior que antes em 16, `rc=0`.

- [ ] **Step 5: Dois mutantes — cada flag some, a suíte morre**

Em `tests/check-mutation.sh`, depois de `mut_RUN_app_down_retry_not_escalated()`:

```bash
# The hat's boundary (2026-09-03 spec). Two flags, one mutant each: dropping either one leaves the
# session with the human's whole harness — 9 MCP servers including Gmail and Jira, 104 tools —
# which is the measured "before". The projection prints what run_phase passes, and
# check-dry-run.sh reads the `boundary:` line, so each of these dies there.
mut_RUN_strict_mcp_dropped() {
  sed -i 's|^  if \[ -z "\$mcp" \]; then cmd+=(--strict-mcp-config); fi$|  if false; then cmd+=(--strict-mcp-config); fi|' "$1"
}
mut_RUN_disallowed_dropped() {
  sed -i '/^run_phase() {/,/^}/ s|^    --disallowedTools "\$disallowed"$|    --disallowedTools "$ALLOWED_TOOLS"|' "$1"
}
```

⚠️ O segundo mutante troca a lista negada pela permitida (`Bash`) em vez de apagar a linha: apagar deixaria o array `cmd` válido mas a projeção idêntica à de hoje só na linha `boundary:`, que é impressa a partir de `$disallowed` e não de `cmd`. Por isso o Step 3 imprime `boundary:` a partir das **mesmas** variáveis que entram em `cmd`; se um dia as duas divergirem, este mutante é o que avisa — e a mutação do `mcp` mata pela mesma linha porque `${mcp:-<none: --strict-mcp-config>}` lê a variável, não a flag. Confira que o mutante **aplica** e **morre**:

Run: `tests/run-all.sh --with-mutation 2>&1 | grep -E 'strict_mcp_dropped|disallowed_dropped|score:'`
Expected: as duas linhas com `caught`, e `score: N caught of N` com N dois acima do valor anterior. (Leva ~15 min. Se preferir só os dois: `SDD_MUTATION_ONLY='RUN_strict_mcp_dropped RUN_disallowed_dropped' tests/check-mutation.sh` **se** essa variável existir — confira com `grep -n 'MUTATION_ONLY\|--only' tests/check-mutation.sh`; se não existir, rode o catálogo inteiro.)

- [ ] **Step 6: Docs do contrato, no mesmo commit**

`docs/pipeline.md:536-541`, seção `## Permissions`, substitua o primeiro parágrafo por:

```markdown
The runner passes `--permission-mode acceptEdits` **and** `--allowedTools "$ALLOWED_TOOLS"`
(default `Bash`). Both are necessary: `acceptEdits` auto-approves file edits, but **not** `Bash` —
without the allowlist the session cannot run the suite nor commit, and the EXEC phase becomes
unsatisfiable by construction. `bypassPermissions` is never the kit's default.

Since the 2026-09-03 spec every phase also gets **the hat's boundary**: `--disallowedTools` with
`HAT_DENY_BASE` (the tools no phase used in 43 measured sessions — cron, worktree, remote trigger,
web search…) plus the `disallowedTools:` line of the phase's `agents/<hat>.md`, and
`--strict-mcp-config` whenever the hat's `mcp:` is empty — which is every hat today. A deny beats
an allow, so `Bash` stays allowed while `Bash(git push:*)` is denied to every hat but the
publisher. `sdd run --dry-run` prints a `boundary:` line per phase with exactly what will be
passed; `tests/check-dry-run.sh` asserts it. The frontmatter keys are the declaration, the flag is
the rule: in a `-p` session the harness reads only `model`, `permissionMode` and `skills` from an
agent file.
```

`config/schema.md:106`, no fim da célula de `ALLOWED_TOOLS`, acrescente: `Since 2026-09-03 the runner also passes \`--disallowedTools\` (the hat's \`disallowedTools:\` line plus \`HAT_DENY_BASE\`) and \`--strict-mcp-config\` (unless the hat's \`mcp:\` names servers); a deny beats this allow, so \`Bash\` stays on while \`Bash(git push:*)\` is off for every hat but the publisher. The \`writes:\` globs accept \`$HANDOFF_DIR\`, \`$MISSION\`, \`$TODO_FILE\`, \`$QA_DOCS_PATH\` and \`$E2E_DIR\`, expanded from this file.`

- [ ] **Step 7: Suíte rápida e commit**

Run: `bash -n bin/sdd && tests/run-all.sh 2>&1 | tail -4`
Expected: verde.

```bash
git add bin/sdd tests/check-dry-run.sh tests/check-mutation.sh docs/pipeline.md config/schema.md
git commit -m "feat(runner): toda fase leva --disallowedTools do chapéu e --strict-mcp-config

Medido em 43 sessões: 0 negações, 9 servidores MCP (Gmail, Drive, Jira do humano) e 104
ferramentas à vista de toda fase, nenhum MCP usado por fase nenhuma. HAT_DENY_BASE é o que
nenhuma fase usou; cada chapéu acrescenta a sua linha; mcp vazio ⇒ strict. A projeção imprime a
linha boundary: a partir das mesmas variáveis que entram no comando, e check-dry-run.sh a lê —
é por ali que os dois mutantes novos morrem.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 3: O runner para: `hat_guard_check`, `hat_crossed_escalation` em quatro portas, `KIT-TOUCHED` vira parada

**Files:**
- Modify: `bin/sdd:2347-2400` (`kit_guard_check`), `:2470-2540` (`review_scope_check` some; `hat_guard_check` e `hat_crossed_escalation` nascem no lugar), `:4834`, `:4947`, `:5069` (sítios), portas em `:~4903`, `:~4950`, `:~5079`, `:~6597`
- Modify: `tests/check-autonomy.sh` (regimes KG1, KG4, KG5, KG7; probes novos de `hat-crossed`)
- Modify: `tests/check-mutation.sh` (seis mutantes)
- Modify: `docs/pipeline.md:56`, `:223-224`, `:432-490`, `:730`; `docs/failure-modes.md:433-437`; `CLAUDE.md` (o censo de escaladas)

**Interfaces:**
- Consumes: `hat_writes`, `phase_hat` (Task 2); `LAST_PHASE_STEP`; `autonomy_blocked_row <kind> <phase> <why>`; `pipeline_log_line`.
- Produces: `hat_path_allowed <path> <globs>` (rc 0 = dentro); `hat_guard_check <phase> <head_before>` (arma `HAT_CROSSED_WHY`, escreve `HAT-CROSSED` no pipeline.log; nunca para); `kit_guard_check` arma `KIT_TOUCHED_WHY`; `hat_crossed_escalation <phase>` (rc 0 = PAROU, linha `blocked` com `kind` `hat-crossed` ou `kit-touched`; rc 1 = segue); ledger `kind` ganha os dois valores.

- [ ] **Step 1: Os probes primeiro — em `tests/check-autonomy.sh`, antes do bloco `== reader: a target-repo session that edits the kit ==` (`:4095`)**

```bash
# --- the hat's boundary: a session that writes outside its writes: stops the line ------------
# The reviewer of SQ-115 wrote a scratch test into the code tree three times and the runner only
# warned (REVIEW-EDITED-CODE). Since the 2026-09-03 spec the runner reads the hat's `writes:` and
# a path outside it — committed OR left dirty — arms HAT_CROSSED_WHY, which the one door
# (hat_crossed_escalation) turns into rc 3 and a `hat-crossed` ledger row AFTER the session row.
# `--phase REVIEW` forces the phase: the fixture is stalled at EXEC and the reviewer is the hat
# whose writes: is narrow (executor writes anywhere).
echo "== hat boundary: the reviewer that edits code stops the line =="
: > "$LEDGER"
hat_stub() {   # hat_stub <path the session writes, relative to the repo> <commit|leave> [fire on]
  local fire="${3:-1}"
  cat > "$OUTSIDE/stub/claude" <<STUB
n=\$(( \$(cat "$OUTSIDE/hat-count" 2>/dev/null || echo 0) + 1 ))
printf '%s\n' "\$n" > "$OUTSIDE/hat-count"
if [ "\$n" -eq $fire ]; then
  mkdir -p "\$(dirname "$1")"
  printf 'probe\n' > "$1"
  if [ "$2" = commit ]; then git add -A; git commit -qm "chore: the session wrote $1"; fi
fi
cat "$STREAM_SAMPLE"
exit 0
STUB
  chmod +x "$OUTSIDE/stub/claude"
}
hat_rows() { jq -r -s '[.[] | select(.event == "blocked") | .kind] | join(",")' "$LEDGER" 2>/dev/null; }
rm -f "$OUTSIDE/hat-count"
hat_stub "src/zz-scratch-probe.test.ts" commit
"$SDD" run "$MISSION" --phase REVIEW >/dev/null 2>&1; rc=$?
assert_eq "hat: a REVIEW session that commits a code file stops the line with rc 3" "3" "$rc"
assert_eq "hat: the escalation row is hat-crossed and comes after the session row" "session,blocked hat-crossed" \
  "$(jq -r -s '[.[0].event, .[1].event] | join(",")' "$LEDGER") $(hat_rows)"
assert_eq "hat: the pipeline log names the file" "1" \
  "$(grep -c 'HAT-CROSSED  REVIEW .*src/zz-scratch-probe.test.ts' "$PIPELINE_LOG")"
assert_eq "hat: one session, not two — the door is read before the inline retry" "1" "$(cat "$OUTSIDE/hat-count")"
git -C "$FIX" reset -q --hard HEAD~1; git -C "$FIX" clean -qfd

rm -f "$OUTSIDE/hat-count"; : > "$LEDGER"
hat_stub "src/zz-scratch-probe.test.ts" leave
"$SDD" run "$MISSION" --phase REVIEW >/dev/null 2>&1; rc=$?
assert_eq "hat: a file LEFT in the tree outside writes: is a crossing too" "3 hat-crossed" "$rc $(hat_rows)"
git -C "$FIX" clean -qfd; git -C "$FIX" checkout -q -- .

rm -f "$OUTSIDE/hat-count"; : > "$LEDGER"
hat_stub "docs/handoffs/$MISSION/40-review-r1.md" commit
"$SDD" run "$MISSION" --phase REVIEW >/dev/null 2>&1; rc=$?
assert_eq "hat: a review that writes only its own artifact is not accused" "0" "$(grep -c 'hat-crossed' <<< "$(hat_rows)")"
assert_eq "hat: …nor is TODO.md, the base every hat may touch" "0" "$(grep -c HAT-CROSSED "$PIPELINE_LOG")"
git -C "$FIX" reset -q --hard HEAD~1 2>/dev/null || true; git -C "$FIX" clean -qfd

rm -f "$OUTSIDE/hat-count"; : > "$LEDGER"
hat_stub "src/zz-scratch-probe.test.ts" commit 2
"$SDD" run "$MISSION" --phase REVIEW >/dev/null 2>&1; rc=$?
assert_eq "hat: door 2 — the inline retry's crossing is caught by the retry's own read" "3 2 session,session,blocked" \
  "$rc $(cat "$OUTSIDE/hat-count") $(jq -r -s '[.[].event] | join(",")' "$LEDGER")"
git -C "$FIX" reset -q --hard HEAD~1; git -C "$FIX" clean -qfd
cat > "$OUTSIDE/stub/claude" <<'STUB'
echo "ERROR: the test invoked the real claude" >&2
exit 97
STUB
```

⚠️ Dois cuidados que o probe cobra: `--phase REVIEW` escreve uma nota `intervention:` no checkpoint e a commita **antes** de amostrar `before` (L4) — o checkpoint está em `writes:`, então não acusa; e o terceiro probe usa `git reset --hard HEAD~1 || true` porque o stub commitou dentro de `docs/handoffs/`, o que é permitido, e o gate pode ter avançado a fase. Se o rc do terceiro probe não for 3 por `no-progress`, tudo bem — a asserção só olha `hat-crossed`.

Run: `tests/check-autonomy.sh 2>&1 | grep -E '^  FAIL.*hat:' | wc -l`
Expected: `7` (todos os probes novos vermelhos: não existe `HAT-CROSSED` nem `hat-crossed`).

- [ ] **Step 2: Os regimes de kit-guard mudam de "avisa" para "para"**

Em `tests/check-autonomy.sh`, quatro asserções ganham o rc e o `kind`. Capture o rc logo após cada `KG?_ERR="$( … )"` com `; KG?_RC=$?` **na mesma linha** e troque os esperados:

- KG1 (`:4219`): esperado `"sessions:1 moved:1 lines:1 warns:1 phase:EXEC differ:1 rc:3 kind:kit-touched"`, e o `got` ganha ` rc:$KG1_RC kind:$(jq -r -s '[.[] | select(.event=="blocked") | .kind] | join(",")' "$LEDGER")` — ⚠️ o ledger deste regime é o do `KGT`: o `SDD_STATE_DIR` é o mesmo do arquivo (`$LEDGER`), esvazie-o com `: > "$LEDGER"` antes de cada regime.
- KG4 (`:4261`): `"sessions:2 moved:1 lines:1 warns:1 rc:3 kind:kit-touched"`.
- KG5 (`:4274`): `"sessions:1 moved:1 lines:1 warns:1 rc:3 kind:kit-touched"`.
- KG7 (`:4324`): `"sessions:1 moved:1 lines:1 warns:1 phase:CLOSE rc:3 kind:kit-touched"`.
- KG2, KG3, KG6 não mudam (ninguém toca o kit, ou o repo É o kit).

Run: `tests/check-autonomy.sh 2>&1 | grep -E '^  FAIL.*kit-guard' | wc -l`
Expected: `4`.

- [ ] **Step 3: `hat_path_allowed`, `hat_guard_check`, `hat_crossed_escalation` — e `review_scope_check` some**

Substitua a função `review_scope_check()` inteira (`bin/sdd:~2470-2540`, inclusive o comentário que a precede a partir de `:2424`) por:

```bash
# --- the hat crossed its boundary --------------------------------------------------------------
# review_scope_check used to WARN when a REVIEW session committed outside the mission directory
# (REVIEW-EDITED-CODE). It is now the general case for every hat, and it STOPS: the hat's `writes:`
# says where the phase may have left a mark, committed or dirty, and a path outside it arms
# HAT_CROSSED_WHY. The marker follows the contract every marker in this file follows — reset at
# the entry of its ONLY setter, read by the doors after the session's ledger row, never surviving
# the lap — and hat_crossed_escalation is the ONE door for it and for KIT_TOUCHED_WHY alike: two
# markers, two ledger kinds, one definition of "the line stops because a session went where its
# hat does not reach".
#
# ⚠️ `grep -c HAT-CROSSED <pipeline.log>` answering 0 is not evidence that the run behaved: bash
# parses this script once, so a `sdd run` that predates this guard runs the bin/sdd it parsed.
# The ledger row is the artifact; this line is the diagnosis.
HAT_CROSSED_WHY=""
KIT_TOUCHED_WHY=""

hat_path_allowed() {   # hat_path_allowed <path> <expanded globs, comma-separated> — rc 0 = inside
  local f="$1" globs="$2" g
  [ -n "$globs" ] || return 0
  local -a arr
  IFS=',' read -r -a arr <<< "$globs"
  for g in "${arr[@]}"; do
    g="${g#"${g%%[![:space:]]*}"}"; g="${g%"${g##*[![:space:]]}"}"
    [ -n "$g" ] || continue
    # shellcheck disable=SC2254
    case "$f" in $g) return 0 ;; esac
  done
  return 1
}

hat_guard_check() {   # hat_guard_check <phase> <HEAD before the session> — arms, never stops
  local phase="${1:-}" before="${2:-}" step hat globs head_now changed status f outside="" n=0
  HAT_CROSSED_WHY=""
  [ "$DRY_RUN" = "1" ] && return 0
  step="$LAST_PHASE_STEP"; [ -n "$step" ] || step="$phase"
  hat="$(phase_hat "$step")"; [ -n "$hat" ] || return 0
  globs="$(hat_writes "$step")"
  [ -n "$globs" ] || return 0
  changed=""
  head_now="$( git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || echo "-" )"
  if [ -n "$before" ] && [ "$before" != "-" ] && [ "$head_now" != "-" ] && [ "$head_now" != "$before" ]; then
    changed="$( git -C "$REPO_ROOT" -c core.quotePath=false diff --name-only "$before" "$head_now" 2>/dev/null || true )"
  fi
  status="$( git -C "$REPO_ROOT" -c core.quotePath=false status --porcelain --untracked-files=all 2>/dev/null | cut -c4- || true )"
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    f="${f##* -> }"; f="${f#\"}"; f="${f%\"}"
    hat_path_allowed "$f" "$globs" && continue
    n=$((n + 1)); outside="${outside:+$outside }$f"
  done <<< "$changed"$'\n'"$status"
  [ "$n" -gt 0 ] || return 0
  HAT_CROSSED_WHY="the $step session ($hat) touched $n path(s) outside its writes: $outside"
  warn "$HAT_CROSSED_WHY"
  pipeline_log_line "$(date -Iseconds)  HAT-CROSSED  $phase  $HAT_CROSSED_WHY"
}

hat_crossed_escalation() {   # hat_crossed_escalation <phase> — rc 0 = STOP (row written), rc 1 = go on
  local phase="$1" kind why
  if [ -n "$HAT_CROSSED_WHY" ]; then kind="hat-crossed"; why="$HAT_CROSSED_WHY"
  elif [ -n "$KIT_TOUCHED_WHY" ]; then kind="kit-touched"; why="$KIT_TOUCHED_WHY"
  else return 1; fi
  GATE_WHY="$why"
  info ""
  bad "BLOCKED in $phase — $why"
  dim "  The hat declares what it may write (agents/<hat>.md, key writes:) and the kit is never a"
  dim "  target's to edit. Restore or move by hand what belongs elsewhere; to widen a hat, edit it"
  dim "  in the kit and 'sdd install --force'. Then 'sdd run' again."
  pipeline_log_line "$(date -Iseconds)  BLOCKED  $phase  $why"
  autonomy_blocked_row "$kind" "$phase" "$why"
  return 0
}
```

Em `kit_guard_check()` (`:2371`): a primeira linha do corpo passa a ser `KIT_TOUCHED_WHY=""` (antes de qualquer `return`), e depois do `pipeline_log_line "$(date -Iseconds)  KIT-TOUCHED …"` acrescente `KIT_TOUCHED_WHY="the kit at $kit_root changed during $phase (kit_before=$KIT_GUARD_BEFORE kit_after=$kit_after) — a session committing outside its mission's repo"`. O `warn` existente fica.

- [ ] **Step 4: Os três sítios e as quatro portas**

Os três `review_scope_check "$phase" "${before%%|*}"` (`:4834`, `:4947`, `:5069`) viram `hat_guard_check "$phase" "${before%%|*}"`.

Porta 1, em `cmd_run` logo depois de `if app_down_escalation "$phase"; then return 3; fi` (a de `:~4903`, acima de `phases_run=$((phases_run + 1))`):

```bash
    if hat_crossed_escalation "$phase"; then return 3; fi
```

Porta 2, dentro do retry inline, logo depois do segundo `if app_down_escalation "$phase"; then return 3; fi` (o do bloco entre `if [ "$gate_rc2" -eq 0 ]; then` e `if [ "$moved2" = "false" ]; then`): a mesma linha.

Porta 3, em `cmd_retry` (`:~5079`), entre `autonomy_session_row … "$review_before" "$review_after" "$review_max"` e `if [ "$gate_rc" -eq 0 ]; then ok …`: a mesma linha.

Porta 4, em `cmd_close` (`:~6597`): acrescente `local phase="CLOSE"` logo antes de `kit_guard_arm`, troque `kit_guard_check "CLOSE"` por `kit_guard_check "$phase"`, e logo depois dele: `if hat_crossed_escalation "$phase"; then return 3; fi`. (Não há linha de sessão no close, então a porta pode vir imediatamente.)

Run: `bash -n bin/sdd && grep -cE '^ +if [a-z_]+_escalation "\$phase"; then' bin/sdd; grep -cE '^[a-z_]+_escalation\(\) \{' bin/sdd; grep -c 'review_scope_check' bin/sdd`
Expected: `8`, `3`, `0`.

- [ ] **Step 5: Verde nos dois sensores**

Run: `tests/check-autonomy.sh 2>&1 | grep -E '^  FAIL' ; tests/check-autonomy.sh >/dev/null 2>&1; echo rc=$?`
Expected: nenhuma `FAIL`, `rc=0`. Se um probe de `hat:` falhar com `rc 0`, o mais provável é a ordem da porta (ela tem de vir **antes** de `phases_run` e do `continue` do gate verde); se falhar com `session,session,blocked` onde se esperava `session,blocked`, a porta 1 ficou dentro do ramo `gate_rc -eq 0`.

- [ ] **Step 6: Seis mutantes**

Em `tests/check-mutation.sh`, depois dos dois da Task 2:

```bash
# hat_guard_check goes blind: it still resets the marker and returns, so the door has nothing to
# read. check-autonomy.sh's "commits a code file stops the line" dies.
mut_RUN_hat_guard_blind() {
  sed -i '/^hat_guard_check() {/,/^}/ s|^  \[ -n "\$globs" \] \|\| return 0$|  return 0|' "$1"
}
# One probe per door, the rule this file's CLAUDE.md states for every port: a door removed is a
# lap the marker survives, and only the probe of THAT door notices. Range-addressed so each sed
# touches exactly one of the four identical lines.
mut_RUN_hat_door1_missing() {
  sed -i '/^    gate_failed\["\$phase"\]=/,/^    phases_run=\$((phases_run + 1))$/ s|^    if hat_crossed_escalation "\$phase"; then return 3; fi$|    :|' "$1"
}
mut_RUN_hat_door2_missing() {
  sed -i '/^    if \[ "\$gate_rc2" -eq 0 \]; then$/,/^    if \[ "\$moved2" = "false" \]; then$/ s|^    if hat_crossed_escalation "\$phase"; then return 3; fi$|    :|' "$1"
}
mut_RUN_hat_retry_door_missing() {
  sed -i '/^cmd_retry() {/,/^}/ s|^  if hat_crossed_escalation "\$phase"; then return 3; fi$|  :|' "$1"
}
mut_RUN_hat_close_door_missing() {
  sed -i '/^cmd_close() {/,/^}/ s|^  if hat_crossed_escalation "\$phase"; then return 3; fi$|  :|' "$1"
}
# The kit guard back to a warning: the marker is never armed, so KIT-TOUCHED is a line and not a
# stop — the 2d28d13 world. KG1's "rc:3 kind:kit-touched" dies.
mut_RUN_kit_touched_silent() {
  sed -i '/^kit_guard_check() {/,/^}/ s|^  KIT_TOUCHED_WHY="the kit at |  : "the kit at |' "$1"
}
```

⚠️ Antes de confiar, prove que cada `sed` **aplica** (o `run_mutant` já reprova com rc 90 quando o arquivo não muda — leia o `.log` do mutante) e que a porta que ele apaga é a que o nome diz: `diff <(cat bin/sdd) <(cp bin/sdd /tmp/m && mut_RUN_hat_door2_missing /tmp/m && cat /tmp/m)` tem de mostrar **uma** linha, dentro do bloco do retry inline.

Run: `tests/run-all.sh --with-mutation 2>&1 | grep -E 'hat_|kit_touched_silent|score:'`
Expected: seis linhas `caught`, `score: N caught of N` com N seis acima da Task 2.

- [ ] **Step 7: Docs no mesmo commit**

- `docs/pipeline.md:56`: a lista de escaladas ganha `` `hat-crossed`, `kit-touched` `` (mesma ordem no `:730`, coluna `kind`).
- `docs/pipeline.md:223-224` ("A REVIEW session that commits a code file anyway is not stopped — it is **recorded**…"): substitua por `A REVIEW session that commits — or leaves dirty — a file outside its hat's \`writes:\` **stops the line**: \`HAT-CROSSED\` in \`.sdd/logs/<mission>/pipeline.log\`, a \`hat-crossed\` row in the ledger after the session's own row, rc 3, and the pager. The hat's \`writes:\` is the mission directory plus \`TODO_FILE\` (principle 5) and, in the kit, \`tests/health-baseline.txt\`.`
- `docs/pipeline.md:432-490` (seções sobre a guarda de kit e `review_scope_check`): reescreva em três parágrafos — (1) a guarda de kit amostra o stamp nas quatro portas como antes, mas agora **arma** `KIT_TOUCHED_WHY` e a linha para com `kind: kit-touched` (o falso positivo do humano editando o kit em outro terminal continua real e agora custa um `sdd run` a mais, o que é o preço declarado da fronteira — D6 da spec); (2) `hat_guard_check` corre nos três sítios onde `review_scope_check` corria, para **toda** fase com chapéu, lendo commits **e** `git status`, contra `writes:` expandido; (3) `hat_crossed_escalation` é a única porta, em quatro sítios, lida depois da linha de sessão do ledger. Mantenha o parágrafo sobre `grep -c … answering 0 is not evidence` trocando `REVIEW-EDITED-CODE` por `HAT-CROSSED`.
- `docs/failure-modes.md:433-437`: o item "A round that fixed instead of finding" passa a dizer que a linha **para** (`hat-crossed`), e que `grep HAT-CROSSED` é diagnóstico, não prova.
- `CLAUDE.md`, seção do princípio 5, o bloco de censo: `definições de escalada → 3`, `portas delas → 8`, `portas da guarda de kit → 4`; e o parágrafo "O runner hoje avisa e registra (`KIT-TOUCHED`…), mas **não para a linha**" vira "Desde `<sha desta task>` o runner **para** (`kind: kit-touched`), pela mesma porta da fronteira do chapéu". Acrescente o terceiro marcador à lista com uma linha: `hat_crossed_escalation`, desde `20260903-a-fronteira-do-chapeu`: UMA definição, DOIS marcadores (`HAT_CROSSED_WHY`, `KIT_TOUCHED_WHY`), QUATRO portas (as duas do laço, `cmd_retry`, `cmd_close`), um probe por porta em `check-autonomy.sh` e um mutante por porta.

- [ ] **Step 8: Suíte e commit**

Run: `bash -n bin/sdd && tests/run-all.sh 2>&1 | tail -4`
Expected: verde.

```bash
git add bin/sdd tests/check-autonomy.sh tests/check-mutation.sh docs/pipeline.md docs/failure-modes.md CLAUDE.md
git commit -m "feat(runner): chapéu que sai da fronteira para a linha, e KIT-TOUCHED deixa de ser aviso

hat_guard_check lê commits e git status contra o writes: do chapéu, em toda fase, nos três sítios
onde review_scope_check só avisava o REVIEW; arma um marcador, e hat_crossed_escalation é a única
porta — quatro sítios, depois da linha de sessão — para ele e para o KIT_TOUCHED_WHY que a guarda
de kit passa a armar. Medido: o revisor da SQ-115 escreveu três vezes um teste na árvore de
código e nada parou. Um probe por porta, um mutante por porta.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 4: O artefato prova: a linha `init` e `permission_denials` entram no ledger

**Files:**
- Modify: `bin/sdd` (`hat_init_facts` perto de `stream_summary` `:~3005`; `run_phase` depois de `stream_summary "$streamfile" > "$logfile"`; `autonomy_session_row` `:~2775-2800`; `hat_guard_check` ganha o ramo de vazamento)
- Modify: `tests/check-autonomy.sh` (fixture `INIT_SAMPLE` com proveniência; probes)
- Modify: `tests/check-mutation.sh` (um mutante)
- Modify: `docs/pipeline.md:~730` (três linhas na tabela de campos do ledger)

**Interfaces:**
- Consumes: `LAST_PHASE_STREAM`, `LAST_PHASE_DISALLOWED`, `LAST_PHASE_MCP` (Task 2); `HAT_CROSSED_WHY` (Task 3).
- Produces: `hat_init_facts <stream> <result json> <deny list> <declared mcp>` publica `LAST_PHASE_MCP_SEEN`, `LAST_PHASE_TOOLS_LEAKED`, `LAST_PHASE_DENIALS` (inteiros ou vazio) e `LAST_PHASE_LEAK_NAMES`; campos de ledger `mcp_seen`, `tools_leaked`, `denials` (número ou `null`).

- [ ] **Step 1: Capturar a linha `init` de uma sessão real, com e sem `Agent` negado, e fixar o nome**

```bash
cd "$(mktemp -d)" && git init -q .
UNS=(-u CLAUDECODE -u CLAUDE_CODE_CHILD_SESSION -u CLAUDE_CODE_MESSAGING_SOCKET -u CLAUDE_CODE_MESSAGING_TOKEN -u CLAUDE_PID -u CLAUDE_CODE_SESSION_ID -u CLAUDE_CODE_BRIDGE_SESSION_ID)
env "${UNS[@]}" claude -p 'Reply with exactly: OK' --model haiku --max-turns 1 --output-format stream-json --verbose \
  --permission-mode acceptEdits --allowedTools Bash --strict-mcp-config --setting-sources project,local \
  --disallowedTools "CronCreate, WebSearch" --max-budget-usd 1 > with-agent.jsonl
env "${UNS[@]}" claude -p 'Reply with exactly: OK' --model haiku --max-turns 1 --output-format stream-json --verbose \
  --permission-mode acceptEdits --allowedTools Bash --strict-mcp-config --setting-sources project,local \
  --disallowedTools "CronCreate, WebSearch, Agent" --max-budget-usd 1 > no-agent.jsonl
diff <(jq -r 'select(.subtype=="init") | .tools[]' with-agent.jsonl | sort) <(jq -r 'select(.subtype=="init") | .tools[]' no-agent.jsonl | sort)
jq -c 'select(.subtype=="init") | {mcp: (.mcp_servers|length), n: (.tools|length), cron: (.tools|index("CronCreate")), web: (.tools|index("WebSearch"))}' with-agent.jsonl
claude --version
```

Expected: o `diff` mostra **uma** linha só presente em `with-agent.jsonl` — o nome com que a linha `init` grafa a ferramenta de subagente (`Task` era a grafia nas sessões de 2026-09-02). A segunda linha mostra `mcp: 0`, e `cron`/`web` **null** (a ferramenta negada some da lista). Anote o nome e a versão: entram no comentário de proveniência e no mapa de alias do Step 3. Se o `diff` não mostrar diferença, a negação de `Agent` não altera a lista `init` — então `tools_leaked` não pode contar essa ferramenta; registre isso no comentário e deixe o alias fora.

- [ ] **Step 2: O fixture com proveniência, e os probes (vermelhos)**

Em `tests/check-autonomy.sh`, logo depois do bloco `STREAM_SAMPLE` (`:~135`):

```bash
# The `init` line the hat sensor reads — tools and mcp_servers as the session saw them.
# PROVENANCE: captured on <YYYY-MM-DD> with
#     claude -p 'Reply with exactly: OK' --model haiku --max-turns 1 --output-format stream-json --verbose \
#       --permission-mode acceptEdits --allowedTools Bash --strict-mcp-config --setting-sources project,local \
#       --disallowedTools "CronCreate, WebSearch" --max-budget-usd 1
# on Claude Code <version>, first line pasted VERBATIM. Under --strict-mcp-config the list has no
# MCP server, and the two denied tools are absent from `tools`; the leaking fixtures below are
# DERIVED from this line with jq, never typed.
INIT_SAMPLE="$OUTSIDE/init-sample.jsonl"
cat > "$INIT_SAMPLE" <<'EOF'
<a linha init inteira, colada do with-agent.jsonl do Step 1>
EOF
INIT_CLEAN="$OUTSIDE/stream-init-clean.jsonl"
{ cat "$INIT_SAMPLE"; cat "$STREAM_SAMPLE"; } > "$INIT_CLEAN"
INIT_LEAK="$OUTSIDE/stream-init-leak.jsonl"
{ jq -c '.mcp_servers = [{"name":"atlassian","status":"connected"}] | .tools += ["WebSearch"]' "$INIT_SAMPLE"; cat "$STREAM_SAMPLE"; } > "$INIT_LEAK"
```

E antes do bloco de kit-guard (depois dos probes da Task 3):

```bash
echo "== hat boundary: what the session SAW is read off the init line into the ledger =="
: > "$LEDGER"
cat > "$OUTSIDE/stub/claude" <<STUB
cat "$INIT_CLEAN"
exit 0
STUB
chmod +x "$OUTSIDE/stub/claude"
"$SDD" run "$MISSION" >/dev/null 2>&1 || true
assert_eq "init: a clean session records 0 MCP seen, 0 tools leaked, 0 denials" "0 0 0" \
  "$(jq -r -s '.[0] | "\(.mcp_seen) \(.tools_leaked) \(.denials)"' "$LEDGER")"
assert_eq "init: nothing crossed" "0" "$(jq -r -s '[.[] | select(.kind == "hat-crossed")] | length' "$LEDGER")"
: > "$LEDGER"
cat > "$OUTSIDE/stub/claude" <<STUB
cat "$INIT_LEAK"
exit 0
STUB
"$SDD" run "$MISSION" >/dev/null 2>&1; rc=$?
assert_eq "init: an MCP server the hat did not declare, and a denied tool still visible, stop the line" \
  "3 1 1 hat-crossed" \
  "$rc $(jq -r -s '.[0] | "\(.mcp_seen) \(.tools_leaked)"' "$LEDGER") $(jq -r -s '[.[] | select(.event=="blocked") | .kind] | join(",")' "$LEDGER")"
assert_eq "init: the reason names what leaked" "1" "$(grep -c 'atlassian' <<< "$(jq -r -s '.[1].gate_why' "$LEDGER")")"
: > "$LEDGER"
cat > "$OUTSIDE/stub/claude" <<STUB
cat "$STREAM_SAMPLE"
exit 0
STUB
"$SDD" run "$MISSION" >/dev/null 2>&1 || true
assert_eq "init: a stream without an init line (a session dead before it) records null, not 0" "null null null" \
  "$(jq -r -s '.[0] | "\(.mcp_seen) \(.tools_leaked) \(.denials)"' "$LEDGER")"
cat > "$OUTSIDE/stub/claude" <<'STUB'
echo "ERROR: the test invoked the real claude" >&2
exit 97
STUB
```

Run: `tests/check-autonomy.sh 2>&1 | grep -cE '^  FAIL.*init:'`
Expected: `5`.

- [ ] **Step 3: `hat_init_facts` e a leitura no `run_phase`**

Logo depois de `stream_summary()` (`bin/sdd:~3005`):

```bash
# What the session could SEE, read off the stream's `init` line, and what it was refused, read
# off the result's `permission_denials`. Published like the other LAST_PHASE_* facts and written
# into the session row; a stream without an init line (a session that died before it) publishes
# "" and the row carries null — unmeasured is not zero.
#
# Naming: the init line spells the subagent tool `<name from Task 4 step 1>` where the deny flag
# spells `Agent` (measured <YYYY-MM-DD> on Claude Code <version>, see INIT_SAMPLE's provenance in
# tests/check-autonomy.sh); the alias below is that one measurement, not a guess.
hat_init_facts() {   # hat_init_facts <stream> <result json> <deny list> <declared mcp>
  local stream="$1" result="$2" deny="$3" declared="$4" init facts
  LAST_PHASE_MCP_SEEN=""; LAST_PHASE_TOOLS_LEAKED=""; LAST_PHASE_DENIALS=""; LAST_PHASE_LEAK_NAMES=""
  autonomy_have_jq || return 0
  init="$( jq -c 'select(.type == "system" and .subtype == "init")' "$stream" 2>/dev/null | head -1 )" || init=""
  [ -n "$init" ] || return 0
  facts="$( jq -r --arg deny "$deny" --arg declared "$declared" '
      def names($s): [ $s | split(",")[] | gsub("^\\s+|\\s+$"; "") | select(. != "" and (contains("(") | not)) ];
      (names($deny) | map(if . == "Agent" then "Task" else . end)) as $deny_names
      | names($declared) as $ok_mcp
      | ((.mcp_servers // []) | map(.name) | map(select(. as $n | ($ok_mcp | index($n)) == null))) as $mcp_leak
      | ((.tools // []) | map(select(. as $t | ($deny_names | index($t)) != null))) as $tool_leak
      | "\($mcp_leak | length)\t\($tool_leak | length)\t\(($mcp_leak + $tool_leak) | join(" "))"
    ' <<< "$init" )" || facts=""
  [ -n "$facts" ] || return 0
  IFS=$'\t' read -r LAST_PHASE_MCP_SEEN LAST_PHASE_TOOLS_LEAKED LAST_PHASE_LEAK_NAMES <<< "$facts"
  LAST_PHASE_DENIALS="$( jq -r '.permission_denials // [] | length' "$result" 2>/dev/null )" || LAST_PHASE_DENIALS=""
}
LAST_PHASE_MCP_SEEN=""
LAST_PHASE_TOOLS_LEAKED=""
LAST_PHASE_DENIALS=""
LAST_PHASE_LEAK_NAMES=""
```

⚠️ Se o Step 1 mostrou que a `init` grafa `Agent` (não `Task`), apague o `map(if . == "Agent" then "Task" else . end)`. Se mostrou que negar `Agent` não muda a lista, mantenha o mapa fora **e** escreva no comentário que `Agent` não é contável por este caminho.

Em `run_phase()`, logo depois de `stream_summary "$streamfile" > "$logfile"`:

```bash
  hat_init_facts "$streamfile" "$logfile" "$disallowed" "$mcp"
```

Em `autonomy_session_row()`, acrescente aos `--arg`: `--arg mcp_seen "$LAST_PHASE_MCP_SEEN" --arg tools_leaked "$LAST_PHASE_TOOLS_LEAKED" --arg denials "$LAST_PHASE_DENIALS"` (linha própria, sem comentário dentro do bloco `\`), e ao objeto, depois de `turns: ($turns | tonumber? // null),`:

```
      mcp_seen: ($mcp_seen | tonumber? // null),
      tools_leaked: ($tools_leaked | tonumber? // null),
      denials: ($denials | tonumber? // null),
```

Em `hat_guard_check()` (Task 3), logo depois do laço `while … done <<< "$changed"$'\n'"$status"` e antes de `[ "$n" -gt 0 ] || return 0`:

```bash
  if [ "${LAST_PHASE_MCP_SEEN:-0}" -gt 0 ] || [ "${LAST_PHASE_TOOLS_LEAKED:-0}" -gt 0 ]; then
    HAT_CROSSED_WHY="the $step session ($hat) saw what it did not declare — ${LAST_PHASE_MCP_SEEN:-0} MCP server(s), ${LAST_PHASE_TOOLS_LEAKED:-0} denied tool(s) still listed: $LAST_PHASE_LEAK_NAMES"
    warn "$HAT_CROSSED_WHY"
    pipeline_log_line "$(date -Iseconds)  HAT-CROSSED  $phase  $HAT_CROSSED_WHY"
    return 0
  fi
```

⚠️ Este ramo vem **antes** do `[ -n "$globs" ] || return 0`? Não — o executor (`writes` vazio) também tem de ser medido pelo vazamento. Mova o `[ -n "$globs" ] || return 0` para logo antes do `changed=""`, e ponha o ramo de vazamento **antes** dele, logo depois de `hat="$(phase_hat "$step")"; [ -n "$hat" ] || return 0`. Ajuste o mutante `mut_RUN_hat_guard_blind` da Task 3 se a âncora mudou de lugar (ele ancora em `[ -n "$globs" ] || return 0` — continua existindo, só mudou de linha).

- [ ] **Step 4: Verde**

Run: `bash -n bin/sdd && tests/check-autonomy.sh 2>&1 | grep -E '^  FAIL'; tests/check-autonomy.sh >/dev/null 2>&1; echo rc=$?`
Expected: nenhuma `FAIL`, `rc=0`.

- [ ] **Step 5: Um mutante**

```bash
# The init line goes unread: mcp_seen/tools_leaked are always "" (null in the row), and a
# session that saw the human's Jira is indistinguishable from one that saw nothing. Dies on
# "an MCP server the hat did not declare … stop the line".
mut_RUN_init_blind() {
  sed -i '/^hat_init_facts() {/,/^}/ s|^  \[ -n "\$init" \] \|\| return 0$|  return 0|' "$1"
}
```

Run: `tests/run-all.sh --with-mutation 2>&1 | grep -E 'init_blind|score:'`
Expected: `caught`, N um acima.

- [ ] **Step 6: A tabela do ledger em `docs/pipeline.md:~730`** — três linhas depois de `turns`:

```markdown
| `mcp_seen` | number \| null | on `event:"session"` rows | MCP servers the session could see that its hat did not declare (`mcp:`), read off the stream's `init` line. `null` = no init line (the session died before one). Any value above 0 stops the line (`hat-crossed`). |
| `tools_leaked` | number \| null | idem | tools from the deny list still listed in `init` — the harness did not honour `--disallowedTools`. Above 0 stops the line. |
| `denials` | number \| null | idem | `permission_denials` of the result: how often the session asked for what its hat denies. Not an escalation — a fact about the hat's fit. |
```

- [ ] **Step 7: Suíte e commit**

Run: `bash -n bin/sdd && tests/run-all.sh 2>&1 | tail -4`
Expected: verde.

```bash
git add bin/sdd tests/check-autonomy.sh tests/check-mutation.sh docs/pipeline.md
git commit -m "feat(ledger): a linha de sessão diz o que a sessão viu — mcp_seen, tools_leaked, denials

Lidos da linha init do stream e do permission_denials do resultado, que já estavam em .sdd/logs
desde o I10. Servidor MCP não declarado ou ferramenta negada ainda visível é a mesma escalada
hat-crossed, com motivo próprio: uma fase que enxerga o que não declarou não é fase do pipeline.
Fixture init copiado de sessão real, com o comando no comentário; os vazamentos são derivados
dele com jq, nunca digitados.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 5: `sdd census <mission>` — o instrumento

**Files:**
- Modify: `bin/sdd` (`cmd_census` antes de `cmd_autonomy`; `main` `:~6475`; o bloco USAGE `:~6400`)
- Modify: `tests/check-hat.sh` (probes do censo sobre um diretório de logs de fixture)
- Modify: `tests/check-mutation.sh` (um mutante)
- Modify: `docs/pipeline.md` (seção "Costs and logs": um parágrafo)

**Interfaces:**
- Consumes: `.sdd/logs/<mission>/<FASE>-*.stream.jsonl` e `.json`; `HANDOFF_DIR`.
- Produces: `sdd census <mission>` — por fase: `sessions`, `turns`, `cost`, `cache_read_M`, `mcp_seen` (máximo), `denials` (soma), `handoff_read_KB`, e a linha `tools:` com `Nome=N` em ordem decrescente.

- [ ] **Step 1: Os probes primeiro — em `tests/check-hat.sh`, antes do `case "${1:-}"`**

Precisa de um stream com um `tool_use`/`tool_result` reais. Capture-os:

```bash
T=$(mktemp -d) && cd "$T" && git init -q . && mkdir -p docs/handoffs/x && printf 'hello handoff\n' > docs/handoffs/x/00-missao.md
env -u CLAUDECODE -u CLAUDE_CODE_CHILD_SESSION -u CLAUDE_CODE_MESSAGING_SOCKET -u CLAUDE_CODE_MESSAGING_TOKEN -u CLAUDE_PID -u CLAUDE_CODE_SESSION_ID -u CLAUDE_CODE_BRIDGE_SESSION_ID \
  claude -p 'Read docs/handoffs/x/00-missao.md with the Read tool, then reply with exactly: OK' --model haiku --max-turns 3 \
  --output-format stream-json --verbose --permission-mode acceptEdits --allowedTools Bash --strict-mcp-config --setting-sources project,local --max-budget-usd 1 > census.jsonl
jq -c 'select(.type=="assistant" and (.message.content[]? | .type=="tool_use"))' census.jsonl | head -1 > tool_use.line
jq -c 'select(.type=="user" and (.message.content[]? | .type=="tool_result"))' census.jsonl | head -1 > tool_result.line
jq -c 'select(.type=="result")' census.jsonl > result.line
wc -c tool_use.line tool_result.line result.line
```

Cole as três linhas (verbatim, com o comando acima e a versão do CLI no comentário de proveniência) em `tests/check-hat.sh`:

```bash
# --- sdd census: the instrument reads the logs, never memory ------------------------------------
# PROVENANCE: the three lines below were captured on <YYYY-MM-DD> on Claude Code <version> with
#     claude -p 'Read docs/handoffs/x/00-missao.md with the Read tool, then reply with exactly: OK' \
#       --model haiku --max-turns 3 --output-format stream-json --verbose --permission-mode acceptEdits \
#       --allowedTools Bash --strict-mcp-config --setting-sources project,local --max-budget-usd 1
# in a scratch repo holding a 14-byte docs/handoffs/x/00-missao.md — one tool_use (Read), its
# tool_result, and the result object, pasted VERBATIM.
census_fixture() {   # census_fixture <dir> — a .sdd/logs/<mission> with one EXEC and one REVIEW session
  mkdir -p "$1"
  cat > "$1/EXEC-20260101-000000-aaaaaaaa.stream.jsonl" <<'EOF'
<tool_use.line>
<tool_result.line>
<result.line>
EOF
  cp "$1/EXEC-20260101-000000-aaaaaaaa.stream.jsonl" "$1/REVIEW-20260101-000100-bbbbbbbb.stream.jsonl"
  jq -c 'select(.type=="result")' "$1/EXEC-20260101-000000-aaaaaaaa.stream.jsonl" > "$1/EXEC-20260101-000000-aaaaaaaa.json"
  jq -c 'select(.type=="result") | .permission_denials = [{"tool_name":"Bash","tool_input":{"command":"git push"}}]' \
     "$1/EXEC-20260101-000000-aaaaaaaa.stream.jsonl" > "$1/REVIEW-20260101-000100-bbbbbbbb.json"
}
census_probes() {
  local box out
  box="$(mktemp -d "${TMPDIR:-/tmp}/sdd-census-XXXXXX")"
  ( cd "$box" && git init -q . && "$ROOT/bin/sdd" install >/dev/null 2>&1 \
      && printf 'PROJECT_NAME="census"\nDEFAULT_BRANCH="main"\nTEST_CMD="true"\nHANDOFF_DIR="docs/handoffs"\n' > .sdd/config.sh \
      && mkdir -p docs/handoffs/20260101-fixture && : > docs/handoffs/20260101-fixture/00-missao.md )
  census_fixture "$box/.sdd/logs/20260101-fixture"
  out="$( cd "$box" && "$ROOT/bin/sdd" census 20260101-fixture 2>&1 )" || true
  if grep -qE '^  EXEC +sessions 1 +turns [0-9]+' <<< "$out"; then pass "census: EXEC counts its one session and its turns"
  else fail "census: EXEC row missing — got: $(head -3 <<< "$out" | tr '\n' '|')"; fi
  if grep -qE '^  REVIEW .*denials 1' <<< "$out"; then pass "census: denials are summed off the result"
  else fail "census: REVIEW denials not 1"; fi
  if grep -qE 'tools: .*Read=1' <<< "$out"; then pass "census: the tool census names Read once"
  else fail "census: tool census missing Read=1"; fi
  if grep -qE '^  EXEC .*handoff_read [1-9][0-9]*B' <<< "$out"; then pass "census: bytes read under docs/handoffs are counted"
  else fail "census: handoff_read is 0 or absent"; fi
  rm -rf "$box"
}
```

E no caminho principal, antes de `selftest || exit $?`: `census_probes`.

Run: `tests/check-hat.sh 2>&1 | grep -c 'FAIL  census'`
Expected: `4`.

- [ ] **Step 2: `cmd_census`**

Antes de `cmd_autonomy()`:

```bash
# sdd census <mission> — what each phase's sessions used and re-read, from .sdd/logs. The
# instrument the 2026-09-03 spec measured its "before" with, now a command so the "after" is one
# line and not a scratchpad: tools by name, MCP seen, denials, bytes re-read under HANDOFF_DIR.
cmd_census() {
  load_config
  resolve_mission "${1:-}"
  autonomy_have_jq || die "sdd census needs jq"
  local dir ph streams jsons agg tools mcp denials kb hd
  dir="$(log_dir)"
  hd="$HANDOFF_DIR"; while [ "${hd%/}" != "$hd" ]; do hd="${hd%/}"; done
  step "sdd census — $MISSION ($dir)"
  for ph in TICKET EXEC QA REVIEW DOCS PR KAIZEN; do
    streams="$( ls -1 "$dir"/"$ph"-*.stream.jsonl 2>/dev/null || true )"
    [ -n "$streams" ] || continue
    jsons="$( ls -1 "$dir"/"$ph"-*.json 2>/dev/null || true )"
    agg="0 0 0 0"
    if [ -n "$jsons" ]; then
      # shellcheck disable=SC2086
      agg="$( jq -rs '"\(length) \(map(.num_turns // 0) | add) \(map(.total_cost_usd // 0) | add | . * 100 | round / 100) \(map(.usage.cache_read_input_tokens // 0) | add / 1e6 | . * 10 | round / 10)"' $jsons 2>/dev/null )" || agg="0 0 0 0"
      # shellcheck disable=SC2086
      denials="$( jq -rs 'map(.permission_denials // [] | length) | add' $jsons 2>/dev/null )" || denials="?"
    else denials="?"; fi
    # shellcheck disable=SC2086
    tools="$( jq -r 'select(.type == "assistant") | .message.content[]? | select(.type == "tool_use") | .name' $streams 2>/dev/null \
              | sort | uniq -c | sort -rn | awk '{ printf "%s%s=%s", (NR > 1 ? ", " : ""), $2, $1 } END { print "" }' )" || tools=""
    # shellcheck disable=SC2086
    mcp="$( jq -r 'select(.type == "system" and .subtype == "init") | (.mcp_servers // []) | length' $streams 2>/dev/null | sort -n | tail -1 )" || mcp=""
    # shellcheck disable=SC2086
    kb="$( jq -rs --arg hd "$hd/" '
        ( [ .[] | select(.type == "assistant") | .message.content[]? | select(.type == "tool_use")
              | select(((.input.file_path // .input.command // "") | contains($hd))) | .id ] ) as $ids
        | [ .[] | select(.type == "user") | .message.content[]? | select(.type == "tool_result")
            | select((.tool_use_id as $i | $ids | index($i)) != null)
            | (.content | if type == "array" then map(.text // "") | join("") else (. // "") end) | length ]
        | add // 0' $streams 2>/dev/null )" || kb="0"
    # shellcheck disable=SC2086
    set -- $agg
    printf '  %-7s sessions %-3s turns %-5s cost %-8s cache_read %sM  mcp_seen %s  denials %s  handoff_read %sB\n' \
      "$ph" "$1" "$2" "$3" "$4" "${mcp:-?}" "$denials" "$kb"
    printf '          tools: %s\n' "${tools:-(none)}"
  done
}
```

⚠️ `set -- $agg` reatribui os parâmetros posicionais da função; `$1` da missão já foi consumido por `resolve_mission` antes. Se `resolve_mission` ler `$1` depois, mova o `set --` para variáveis nomeadas (`read -r n_sess n_turns cost cache <<< "$agg"`).

No `main` (`:~6475`), acrescente `census)    cmd_census "$@" ;;` depois de `autonomy)`. No bloco USAGE, depois das linhas de `sdd autonomy`:

```
  sdd census <mission>       what each phase's sessions used and re-read, from .sdd/logs: tools by
                             name, MCP seen, denials, bytes re-read under HANDOFF_DIR
```

- [ ] **Step 3: Verde**

Run: `bash -n bin/sdd && tests/check-hat.sh 2>&1 | grep -E 'census'; ./bin/sdd help | grep -c 'sdd census'`
Expected: 4 `ok    census: …`, e `1`.

- [ ] **Step 4: Mutante**

```bash
# The census stops reading tool_use names — the line that turns the "before" of the 2026-09-03
# spec into a command prints "(none)" for every phase. check-hat.sh's "the tool census names
# Read once" dies.
mut_CENSUS_tools_blind() {
  sed -i '/^cmd_census() {/,/^}/ s|select(.type == "tool_use") \| .name'"'"' \$streams|select(.type == "never") \| .name'"'"' $streams|' "$1"
}
```

Run: `tests/run-all.sh --with-mutation 2>&1 | grep -E 'CENSUS_tools_blind|score:'`
Expected: `caught`.

- [ ] **Step 5: Doc e commit**

Em `docs/pipeline.md`, seção `## Costs and logs`, um parágrafo novo: `\`sdd census <mission>\` reads those logs back: per phase, sessions, turns, cost, cache-read tokens, MCP servers the sessions saw, permission denials, bytes re-read under \`HANDOFF_DIR\`, and every tool by name with its count. It is the instrument the 2026-09-03 spec measured its "before" with (0 denials, 9 MCP servers, 104 tools in 43 sessions); the "after" of the hat's boundary is this command on the first mission after it.`

Run: `tests/run-all.sh 2>&1 | tail -4`
Expected: verde.

```bash
git add bin/sdd tests/check-hat.sh tests/check-mutation.sh docs/pipeline.md
git commit -m "feat(census): sdd census lê dos logs o que cada fase usou e releu

Ferramentas por nome, MCP visto, negações e bytes relidos sob HANDOFF_DIR, por fase. É o
instrumento com que a spec mediu o antes (0 negações, 9 MCP, 104 ferramentas em 43 sessões),
agora um comando para que o depois seja uma linha e a dieta (missão 2) nasça com baseline no kit.
Fixture de stream copiado de sessão real, proveniência no comentário.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 6: ADR 0007 e `sdd health --release`

**Files:**
- Create: `docs/adr/0007-apt-for-another-repo-is-six-green-lines.md`
- Modify: `bin/sdd` (`cmd_health` `:3709` parse de `--release`; `health_release` e `skill_origin` antes de `cmd_health`; `load_config` `:150` default `RELEASE_FORBIDDEN_WORDS`; USAGE)
- Modify: `config/schema.md` (linha da chave nova), `.sdd/config.sh` do kit (`RELEASE_FORBIDDEN_WORDS="sales_quote SQ- JRC jrcbrasil"`), `LICENSE` **não** nasce aqui (é a missão 3)
- Modify: `tests/check-hat.sh` (probes), `tests/check-mutation.sh` (um mutante), `tests/check-lang.sh:140` (o ADR entra na superfície: piso 45 → 46 se o Task 1 já contou só quatro novos; confira com `tests/check-lang.sh` que o número real de arquivos bate)

**Interfaces:**
- Produces: `sdd health --release` — só as seis linhas, sem rodar a suíte, rc 1 se alguma reprova; `skill_origin <name>` → URL ou `local`; chave `RELEASE_FORBIDDEN_WORDS` (lista separada por espaço, vazio ⇒ a linha 5 só olha `LICENSE`).

- [ ] **Step 1: Os probes (vermelhos) — em `tests/check-hat.sh`, uma função `release_probes` chamada depois de `census_probes`**

```bash
# --- sdd health --release: the six lines of ADR 0007 read artifacts, never labels ---------------
release_probes() {
  local box ledger out
  box="$(mktemp -d "${TMPDIR:-/tmp}/sdd-release-XXXXXX")"
  ledger="$box/state/autonomy-log.jsonl"; mkdir -p "$box/state"
  cp -r "$ROOT/bin" "$ROOT/templates" "$ROOT/config" "$ROOT/agents" "$ROOT/tests" "$box/"
  mkdir -p "$box/.sdd"; printf 'PROJECT_NAME="kit"\nDEFAULT_BRANCH="main"\nTEST_CMD="tests/run-all.sh"\nRELEASE_FORBIDDEN_WORDS="acme_corp"\n' > "$box/.sdd/config.sh"
  ( cd "$box" && git init -q -b main && git config user.email f@x && git config user.name f && git add -A && git commit -qm kit ) >/dev/null
  release() { ( cd "$box" && SDD_STATE_DIR="$box/state" "$box/bin/sdd" health --release 2>&1 ); }
  : > "$ledger"
  out="$(release)"; rc=$?
  if [ "$rc" = 1 ] && [ "$(grep -cE '^  (ok|FAIL|✗|✓)' <<< "$out")" -ge 6 ]; then pass "release: prints six lines and exits 1 while red"
  else fail "release: expected rc 1 and six verdict lines — got rc $rc: $(tr '\n' '|' <<< "$out" | cut -c1-300)"; fi
  if grep -q 'line 1.*second repo.*0 of 2' <<< "$out"; then pass "release: line 1 counts target repos in the ledger (none yet)"; else fail "release: line 1 wording"; fi
  if grep -q 'line 5.*LICENSE' <<< "$out"; then pass "release: line 5 wants a LICENSE"; else fail "release: line 5 wording"; fi
  # a ledger with two target repos, a PR in the second, and a last mission whose rows saw nothing
  kitroot="$(cd "$box" && git rev-parse --show-toplevel)"
  cat > "$ledger" <<EOF
{"v":1,"ts":"2026-09-01T10:00:00-03:00","event":"session","run_id":"a","invocation":"run","kit_sha":"abc1234","kit_dirty":false,"project":"one","repo":"/repos/one","mission":"20260901-x","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"s1","rc":0,"dur_s":1,"cost_usd":1,"turns":3,"moved":true,"mcp_seen":9,"tools_leaked":0,"denials":0,"gate":"pass","gate_why":""}
{"v":1,"ts":"2026-09-02T10:00:00-03:00","event":"session","run_id":"b","invocation":"run","kit_sha":"abc1234","kit_dirty":false,"project":"two","repo":"/repos/two","mission":"20260902-y","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"s2","rc":0,"dur_s":1,"cost_usd":1,"turns":3,"moved":true,"mcp_seen":0,"tools_leaked":0,"denials":0,"gate":"pass","gate_why":""}
{"v":1,"ts":"2026-09-02T11:00:00-03:00","event":"session","run_id":"b","invocation":"run","kit_sha":"abc1234","kit_dirty":false,"project":"two","repo":"/repos/two","mission":"20260902-y","phase":"PR","step":"PR","agent":"sdd-publisher","model":"sonnet","attempt":1,"auto_retry":false,"session":"s3","rc":0,"dur_s":1,"cost_usd":1,"turns":3,"moved":true,"mcp_seen":0,"tools_leaked":0,"denials":0,"gate":"pass","gate_why":""}
EOF
  printf 'MIT\n' > "$box/LICENSE"
  out="$(release)"
  if grep -q 'line 1.*2 of 2' <<< "$out"; then pass "release: line 1 green with two target repos"; else fail "release: line 1 should be green"; fi
  if grep -qE 'line 3.*ok' <<< "$out"; then pass "release: line 3 green when the last mission saw nothing it did not declare"; else fail "release: line 3 should be green — $(grep 'line 3' <<< "$out")"; fi
  if grep -qE 'line 4.*ok' <<< "$out"; then pass "release: line 4 green with a PR phase in the second repo"; else fail "release: line 4 should be green"; fi
  printf 'the client acme_corp\n' >> "$box/README.md" 2>/dev/null || printf 'acme_corp\n' > "$box/README.md"
  out="$(release)"
  if grep -qE 'line 5.*acme_corp' <<< "$out"; then pass "release: line 5 names the forbidden word it found"; else fail "release: line 5 should name acme_corp"; fi
  rm -rf "$box"
}
```

Run: `tests/check-hat.sh 2>&1 | grep -c 'FAIL  release'`
Expected: `7`.

- [ ] **Step 2: `skill_origin`, `health_release`, a flag, a chave**

Em `load_config` (`bin/sdd:~150`), depois de `: "${ALLOWED_TOOLS:=Bash}"`: `: "${RELEASE_FORBIDDEN_WORDS:=}"`.

Antes de `cmd_health()`:

```bash
# Where each third-party skill the pipeline boots comes from. ONE table: the preflight names the
# missing ones with it, and release line 2 is green only when every origin is a URL a stranger can
# install from — `local` is the honest word for "lives in the author's ~/.claude".
skill_origin() {   # skill_origin <skill> — a URL, or `local`
  case "$1" in
    *) printf '%s\n' "local" ;;
  esac
}

# The six lines of ADR 0007 — "apt for another repo of the organisation" as artifacts, never as a
# label. Reads the global ledger, the skill table, the tree and the mutation stamp; never runs the
# suite (the stamp IS the suite's artifact). Red is a finding, and four are red on purpose today.
health_release() {   # rc 0 = six green lines
  local kit ledger sha reds=0 n_repos pr_repos last_ok wanted sk origin bad_origin="" hits="" w key stamp
  kit="$(health_kit_root || true)"
  ledger="$(autonomy_log_path)"
  step "sdd health --release — apt for another repo? (ADR 0007)"
  line() {   # line <n> <ok|bad> <text>
    if [ "$2" = ok ]; then ok "line $1 · $3"; else bad "line $1 · $3"; reds=$((reds + 1)); fi
  }
  # 1 — a second target repo has run sessions
  n_repos="$( jq -r --arg kit "$kit" '[ .[] | select(.event == "session" and .repo != null and .repo != $kit) | .repo ] | unique | length' \
               <(jq -c . "$ledger" 2>/dev/null | jq -s . 2>/dev/null || printf '[]') 2>/dev/null )" || n_repos=0
  [ -n "$n_repos" ] || n_repos=0
  if [ "$n_repos" -ge 2 ]; then line 1 ok "installed and run in a second repo ($n_repos of 2 target repos in the ledger)"
  else line 1 bad "second repo: $n_repos of 2 target repos have sessions in the ledger — the kit has one target"; fi
  # 2 — every third-party skill has an origin a stranger can install from
  wanted="codereview ticket qa-report qa-execution grill-with-docs kaizen-software ddd"
  for sk in $wanted; do
    origin="$(skill_origin "$sk")"
    case "$origin" in http://*|https://*) ;; *) bad_origin="$bad_origin $sk" ;; esac
  done
  if [ -z "$bad_origin" ]; then line 2 ok "every third-party skill has an installable origin"
  else line 2 bad "skills without an installable origin (local to this machine):$bad_origin"; fi
  # 3 — the last target mission's sessions saw nothing they did not declare
  last_ok="$( jq -r --arg kit "$kit" '
      [ .[] | select(.event == "session" and .repo != null and .repo != $kit) ] as $s
      | if ($s | length) == 0 then "none"
        else ($s[-1].mission) as $m
          | ([ $s[] | select(.mission == $m) ] | map(select(.mcp_seen == null or .tools_leaked == null))) as $unmeasured
          | ([ $s[] | select(.mission == $m) ] | map(select((.mcp_seen // 0) > 0 or (.tools_leaked // 0) > 0))) as $leaks
          | if ($unmeasured | length) > 0 then "unmeasured \($m)"
            elif ($leaks | length) > 0 then "leaked \($m) \($leaks | length)"
            else "ok \($m)" end
        end' <(jq -s . "$ledger" 2>/dev/null || printf '[]') 2>/dev/null )" || last_ok="none"
  case "$last_ok" in
    ok\ *)   line 3 ok "the last target mission (${last_ok#ok }) saw only what its hats declare" ;;
    none)    line 3 bad "no target mission in the ledger yet" ;;
    *)       line 3 bad "the last target mission: $last_ok (mcp_seen / tools_leaked in its session rows)" ;;
  esac
  # 4 — a PR phase in a second target repo
  pr_repos="$( jq -r --arg kit "$kit" '[ .[] | select(.repo != null and .repo != $kit and .phase == "PR" and (.event == "session" or .event == "gate_pass")) | .repo ] | unique | length' \
               <(jq -s . "$ledger" 2>/dev/null || printf '[]') 2>/dev/null )" || pr_repos=0
  [ -n "$pr_repos" ] || pr_repos=0
  if [ "$pr_repos" -ge 2 ]; then line 4 ok "a mission reached its PR phase in $pr_repos target repos"
  else line 4 bad "end-to-end mission in a second repo: PR phase seen in $pr_repos of 2 target repos"; fi
  # 5 — LICENSE, and no client identifier on the surface
  for w in $RELEASE_FORBIDDEN_WORDS; do
    if [ -n "$( cd "$kit" && grep -rlF -- "$w" bin agents docs/pipeline.md docs/failure-modes.md docs/adr README.md config templates tests 2>/dev/null | head -1 )" ]; then
      hits="$hits $w"
    fi
  done
  if [ -f "$kit/LICENSE" ] && [ -z "$hits" ]; then line 5 ok "LICENSE present, surface free of client identifiers"
  elif [ ! -f "$kit/LICENSE" ]; then line 5 bad "no LICENSE at the kit root${hits:+; and client identifiers on the surface:$hits}"
  else line 5 bad "client identifiers on the surface:$hits"; fi
  # 6 — the mutation stamp matches this content (the suite's artifact; never re-run here)
  key="$(mutation_stamp_key "$kit" || true)"
  stamp="$(cat "$kit/$MUTATION_STAMP_REL" 2>/dev/null || true)"
  if [ -n "$key" ] && [ "$stamp" = "$key" ]; then line 6 ok "suite, ratchet and mutation catalogue green for this content (stamp matches)"
  else line 6 bad "mutation stamp absent or stale — run ./bin/sdd health after the last code commit"; fi
  if [ "$reds" -eq 0 ]; then ok "apt for another repo of the organisation: 6 of 6"; return 0; fi
  bad "apt for another repo: $reds line(s) red — each is a finding with an owner in ADR 0007"
  return 1
}
```

⚠️ Três notas de forma: (a) toda captura leva `|| x=…` — a região de `cmd_health` é enumerada pela regra `guard:` do `check-health.sh`, e `health_release` fica fora dela, mas o hábito é o mesmo; (b) `<(jq -s . "$ledger" …)` é substituição de processo dentro de `$( )` — se o `shellcheck` do `run-all.sh` reclamar (SC2216/SC1090 não se aplicam; se vier SC2312, converta para um arquivo temporário em `mktemp`); (c) a linha 1 lê o ledger duas vezes por `jq -s`; se o `check-pipefail.sh` acusar `grep -q` nenhum é usado aqui.

Em `cmd_health()` (`:3709`), no topo:

```bash
  local release=0
  while [ $# -gt 0 ]; do
    case "$1" in
      --release) release=1 ;;
      *) die "sdd health: unknown option '$1'" ;;
    esac
    shift
  done
  if [ "$release" = 1 ]; then health_release; return $?; fi
```

No USAGE, a linha de `sdd health` ganha uma segunda: `             [--release]   the six lines of ADR 0007 — apt for another repo? — from artifacts; never runs the suite`.

Em `config/schema.md`, na tabela de chaves (perto de `ON_ESCALATION_CMD`): `| \`RELEASE_FORBIDDEN_WORDS\` | *(empty)* | Space-separated words that must not appear on the kit's surface (\`bin agents docs/adr docs/pipeline.md … tests\`) — client and target identifiers. Read by \`sdd health --release\` line 5 (ADR 0007). Empty ⇒ line 5 checks only \`LICENSE\`. Set it in the **kit's** \`.sdd/config.sh\`; a target repo never needs it. |`

No `.sdd/config.sh` do kit: `RELEASE_FORBIDDEN_WORDS="sales_quote SQ- JRC jrcbrasil"`.

- [ ] **Step 3: Verde**

Run: `bash -n bin/sdd && tests/check-hat.sh 2>&1 | grep -E 'release'; ./bin/sdd health --release; echo rc=$?`
Expected: 7 `ok    release: …`; no kit real, quatro linhas vermelhas (1, 2, 4, 5), a 3 vermelha até a primeira missão pós-merge, a 6 verde **só depois** do carimbo da Task 7; `rc=1`.

- [ ] **Step 4: Mutante**

```bash
# Release line 3 goes green whatever the ledger says — the one line THIS mission closes, read as
# a label. check-hat.sh's "line 3 green when…" survives but "prints six lines and exits 1 while
# red" does not: with an empty ledger the line must be red.
mut_HEALTH_release_line3_blind() {
  sed -i '/^health_release() {/,/^}/ s|^    none)    line 3 bad "no target mission in the ledger yet" ;;$|    none)    line 3 ok "no target mission in the ledger yet" ;;|' "$1"
}
```

⚠️ Esse mutante só morre se a asserção de rc contar linhas vermelhas com o ledger vazio **e** a linha 3 for a que faz a diferença — com o ledger vazio as linhas 1, 2, 4 e 5 também são vermelhas e o rc continua 1. Fortaleça o probe: `if grep -qE 'line 3.*(bad|✗|FAIL)' <<< "$out"` na primeira rodada (ledger vazio) → `pass "release: line 3 red with no target mission"`. Confira o `bad` real: leia como `bad()` imprime (`grep -n '^bad() {' bin/sdd`) e ancore a regex no prefixo dela.

Run: `tests/run-all.sh --with-mutation 2>&1 | grep -E 'release_line3|score:'`
Expected: `caught`.

- [ ] **Step 5: ADR 0007 (inglês — está na superfície do `check-lang.sh`)**

`docs/adr/0007-apt-for-another-repo-is-six-green-lines.md`:

```markdown
# 0007 — "Apt for another repo of the organisation" is six green lines, and a real mission in a second repo is one of them

Date: 2026-09-03 · Status: accepted

## Context

The kit has one target. Every shape assumption it carries — the `TODO.md` genre, the QA docs
tree, the ticket skill's `.jira-project`, the e2e directory — was learned on `sales_quote` and
never contradicted, because nothing else ever ran it. "Ready to be used by other projects" was a
sentence with no artifact behind it, which is the one thing principle 1 of `CLAUDE.md` refuses.

Measured on 2026-09-03 (spec `docs/superpowers/specs/2026-09-03-a-fronteira-do-chapeu-design.md`,
§ 6): no LICENSE; 7 surface files name the first target and 15 name its ticket prefix; every
third-party skill the pipeline boots lives in the author's `~/.claude`; every headless phase saw
9 MCP servers and 104 tools it never used; 48 of 729 commits mention the client.

## Decision

"Apt" is the command `sdd health --release` printing six green lines, each read from an artifact:

| # | Line | Artifact | Owner | Closed by |
|---|---|---|---|---|
| 1 | installed and run in a second repo | ≥ 2 distinct non-kit `repo` values with `session` rows in the global ledger | the human who picks the second repo | mission 3 |
| 2 | every third-party skill has an installable origin | `skill_origin()` answers a URL for each of the seven | the kit | mission 3 |
| 3 | the last target mission saw only what its hats declare | `mcp_seen == 0` and `tools_leaked == 0` on every session row of that mission | the runner | mission 1 (the hat's boundary) |
| 4 | an end-to-end mission in the second repo | a `PR` phase row in ≥ 2 non-kit repos | the human + the pipeline | mission 3 |
| 5 | a LICENSE, and no client identifier on the surface | `LICENSE` exists; `RELEASE_FORBIDDEN_WORDS` finds nothing under `bin agents docs/adr docs/pipeline.md … tests` | the kit | mission 3 |
| 6 | suite, ratchet and mutation catalogue green for this content | the mutation stamp matches the tree | `sdd health` | already |

The command never runs the suite: line 6 reads the stamp, which is the suite's own artifact. It
is opt-in (`--release`), exits 1 while any line is red, and was born with four red lines on
purpose — a "ready" that cannot fail is a label.

**"Apt" is not "public".** Publishing the repository in the open is a separate decision with its
own number (48 of 729 commits mention the client, so it means rewriting history), and this ADR
does not take it.

## Alternatives discarded

- **A dry-run in a fixture repo as the proof of line 4.** It proves installation and projection,
  not a headless session in a repo of another shape — and every shape assumption above is
  exactly what a projection cannot exercise.
- **A public toy repo as the second target.** A demo for strangers, not evidence about the
  organisation's own repos, whose shapes are the ones the kit will meet next.
- **A checklist in the README.** Verifiable by nobody; the ratchet on the backlog exists because
  a list that only a human re-reads is the most silent drift there is.

## Consequences

- Each mission of the roadmap (1 boundary, 2 context diet, 3 aptitude) names the line it closes.
- Line 5 puts client names in the kit's **own** `.sdd/config.sh`, never on the surface — the list
  of what must not appear is itself something that must not appear.
- The second repo (lines 1 and 4) is the human's choice; the pipeline proves it by the ledger,
  which already stamps `repo` and `kit_sha` per session (ADR 0005).
```

- [ ] **Step 6: Suíte e commit**

Run: `bash -n bin/sdd && tests/run-all.sh 2>&1 | tail -4`
Expected: verde (o `check-lang.sh` lê o ADR novo; se o piso `-lt 45` reprovar por **excesso** não há problema — o piso é mínimo).

```bash
git add bin/sdd tests/check-hat.sh tests/check-mutation.sh docs/adr/0007-apt-for-another-repo-is-six-green-lines.md config/schema.md .sdd/config.sh
git commit -m "feat(health): sdd health --release — as seis linhas do ADR 0007, lidas de artefato

Apto para outro repo da organização deixa de ser frase: seis linhas, cada uma com comando, dono e
missão que a fecha, nascidas com quatro vermelhas de propósito. A linha 3 é a desta missão. Apto
não é público: 48 dos 729 commits citam o cliente, e isso é decisão à parte.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 7: A rule, o glossário, o kaizen, o backlog, o carimbo e o PR

**Files:**
- Modify: `.claude/rules/anatomia-do-agente.md:40-44` (seção 2), `:103-106` (seção 6), `:130-131` (seção 7)
- Modify: `CONTEXT.md` (verbete no Glossário), `KAIZEN_LOG.md` (duas entradas), `TODO.md:663-668` (fecha), `tests/health-baseline.txt` (`todo-findings 109` → o número que `tests/check-todo.sh` responder)
- Modify: `docs/pipeline.md` (tabela de fases: TICKET → `sdd-ticket`), `CONTEXT.md:116` (cita `sdd-publisher.md:64` — confira a linha)

- [ ] **Step 1: A rule apaga o que fechou e corrige o que estava errado**

Seção 2, substitua o parágrafo `**Dívida declarada.**` (`:40-44`) por:

```markdown
**Dívida declarada.** Fechada em `20260903-a-fronteira-do-chapeu`: cada `agents/*.md` declara
`disallowedTools:`, `writes:` e `mcp:`, o runner passa `--disallowedTools` e `--strict-mcp-config`
por fase, e a linha `init` do stream prova no ledger (`mcp_seen`, `tools_leaked`). O que fica:
`--setting-sources user,project,local` continua carregando as skills do humano — medido, é 2% do
prefixo e três fases dependem delas (`codereview`, `ticket`, `qa-*`); a rota é a linha 2 do ADR
0007, não uma flag.
```

Seção 6, no parágrafo `**Dívida declarada.**` (`:103-106`), troque `a guarda de kit é aviso, não fronteira — furada em \`2d28d13\`` por `a guarda de kit **para a linha** desde \`20260903-a-fronteira-do-chapeu\` (\`kind: kit-touched\`), e o chapéu que escreve fora de \`writes:\` também (\`hat-crossed\`)`. O resto do parágrafo (worktree, incidente das 18:45) fica.

Seção 7, substitua `**Dívida declarada.**` (`:130-131`) por:

```markdown
**Dívida declarada.** "Pare depois desta fase" existe: `--phase X --max-phases 1` — a linha
anterior desta seção dizia que não existia, e estava errada (foi o comando do incidente das 18:45).
O que falta é o inverso: `--phase X` sem `--max-phases` segue em frente, e a DOCS emendou sozinha
depois da r4 em 2026-09-02.
```

Nas seções 2 e 6, em **Onde mora hoje**, acrescente uma frase cada: `phase_hat()` + `hat_disallowed()` + `hat_writes()` em `run_phase()`; `hat_guard_check` nos três sítios e `hat_crossed_escalation` em quatro portas.

- [ ] **Step 2: Glossário, kaizen, backlog, tabela de fases**

`CONTEXT.md`, tabela do Glossário, uma linha: `| **Fronteira do chapéu** | Desde \`20260903-a-fronteira-do-chapeu\`: o chapéu **declara** no frontmatter (\`disallowedTools:\`, \`writes:\`, \`mcp:\`), o runner **aplica** por flag (\`--disallowedTools\`, \`--strict-mcp-config\`) e conferindo commits e árvore contra \`writes:\` depois da sessão, e o artefato **prova** (linha \`init\` do stream → \`mcp_seen\`/\`tools_leaked\` no ledger). Sair da fronteira é escalada \`hat-crossed\`; tocar o kit de outro repo é \`kit-touched\` — a mesma porta. Medido antes: 0 negações em 43 sessões, 9 MCP e 104 ferramentas em toda fase. Outros harnesses ignoram \`writes:\` e \`mcp:\`; o agente segue portátil, a fronteira não. |`

`KAIZEN_LOG.md`, duas entradas no topo (formato das existentes: `## AAAA-MM-DD — título (missão …)`, **Problema (Gemba)**, **Contramedida**, tabela Antes/Depois com os comandos):

1. `## 2026-09-03 — Hipótese refutada por medição: tirar user do --setting-sources (missão 20260903-a-fronteira-do-chapeu)` — Antes: 70 718 tokens; Depois: 69 268 (2%), e REVIEW/TICKET/QA quebram; decisão: não mexer. Comando: o probe do apêndice da spec.
2. `## 2026-09-03 — A fronteira do chapéu (missão 20260903-a-fronteira-do-chapeu)` — Antes: 0 negações / 43 sessões, `mcp_servers` 9, ferramentas 104, 1 arquivo fora do chapéu; Depois: **em aberto, de propósito** — quem preenche é `sdd census <missão>` na primeira missão do `sales_quote` depois do merge, e a linha 3 do `sdd health --release`.

`TODO.md:663-668` (o item "diz the 6 agents e existem 7"): acrescente ao corpo `RESOLVIDO por <sha da Task 1>` — o item sai do arquivo no chore pós-merge, como manda a regra. Em seguida:

Run: `tests/check-todo.sh --check TODO.md | tail -1`
Expected: `ok    109 finding(s)…` (o número não muda até o item ser apagado; se você registrou achados novos durante a missão — a contradição do executor com subagentes é um candidato, formato de 6 linhas —, o número sobe e `tests/health-baseline.txt` sobe junto, no mesmo commit).

`docs/pipeline.md`, tabela de fases (linha `TICKET`): o agente passa a `sdd-ticket`. `CONTEXT.md:116` cita `agents/sdd-publisher.md:64` — confira se a linha ainda é a da união das seções (`grep -n 'Pend' agents/sdd-publisher.md`) e corrija o número.

- [ ] **Step 3: Suíte, commit de docs**

Run: `tests/run-all.sh 2>&1 | tail -4`
Expected: verde.

```bash
git add .claude/rules/anatomia-do-agente.md CONTEXT.md KAIZEN_LOG.md TODO.md tests/health-baseline.txt docs/pipeline.md
git commit -m "docs(anatomia): a rule apaga a dívida 2, corrige a 7 e nomeia a fronteira; glossário e kaizen

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

- [ ] **Step 4: O carimbo — depois do último commit de código, sem runner vivo**

Run: `pgrep -af 'bin/sdd run' || echo none; git status --short; ./bin/sdd health 2>&1 | tail -8`
Expected: `none`, árvore limpa, `mutation: score: N caught of N` com N = 227 + 12 (2 + 6 + 1 + 1 + 1 + 1 desta missão; confira com `grep -c '^mut_' tests/check-mutation.sh`), `mutation stamp written`, `todo-findings` igual ao baseline, `kit healthy`. Leva ~15 min. Se o carimbo reprovar com `ran N of the M defined`, alguém trocou a branch debaixo dele — refaça.

Run: `./bin/sdd health --release`
Expected: linhas 1, 2, 4 vermelhas; 3 vermelha (`no target mission… mcp_seen`) até a primeira missão pós-merge; 5 vermelha (sem LICENSE, e `sales_quote`/`SQ-` na superfície); **6 verde**. `rc=1`.

- [ ] **Step 5: PR**

```bash
git push -u origin feat/a-fronteira-do-chapeu
gh pr create --base main --title "feat: a fronteira do chapéu — o chapéu declara, o runner aplica, o artefato prova" --body "$(cat <<'EOF'
Spec: docs/superpowers/specs/2026-09-03-a-fronteira-do-chapeu-design.md · Plano: docs/superpowers/plans/2026-09-03-a-fronteira-do-chapeu.md

**Medido antes** (43 sessões de duas missões): 0 negações de permissão; 9 servidores MCP (Gmail, Drive, Calendar, Jira do humano) e 104 ferramentas à vista de toda fase; o revisor read-only escreveu 3× um teste na árvore de código e o runner só avisou.

**O que muda**
- cada `agents/sdd-*.md` declara `disallowedTools:`, `writes:`, `mcp:`; `sdd-ticket.md` nasce (um chapéu, uma fronteira)
- `run_phase` passa `--disallowedTools` (base + chapéu) e `--strict-mcp-config`; a projeção imprime `boundary:` por fase
- `hat_guard_check` confere commits e árvore contra `writes:`; `hat_crossed_escalation` para a linha em 4 portas (`hat-crossed`, e `KIT-TOUCHED` vira `kit-touched`)
- a linha `init` do stream entra no ledger: `mcp_seen`, `tools_leaked`, `denials`
- `sdd census <mission>`: o instrumento
- ADR 0007 + `sdd health --release`: apto para outro repo = seis linhas verdes; nasce com quatro vermelhas

**Sensores:** `tests/check-hat.sh` (14º, com selftest), asserções novas em `check-dry-run.sh` e `check-autonomy.sh`, 12 mutantes novos; carimbo `sdd health` verde neste sha.

**Depois:** `sdd census` na primeira missão do `sales_quote` após o merge preenche o `KAIZEN_LOG.md`; e `sdd install --force` no alvo (o espelho do revisor já estava stale).

Pendências: a contradição do executor (o prompt manda usar subagentes, o censo mede 0 em 27 sessões) → `TODO.md`; `ticket` skill e MCP como fallback → verificar na missão 3.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

https://claude.ai/code/session_01UYCcb1ygF1afWpgwwYazsp
EOF
)"
```

Expected: URL do PR. Merge é humano.

---

## Self-review (feito ao escrever)

**Cobertura da spec.** § 4.1 chaves → Task 1; § 4.2 tabela → Task 1 Step 4 (com `$TODO_FILE`/baseline movidos para `HAT_WRITES_BASE`, Task 2); § 5.1 aplicar → Task 2; § 5.2 parar (3 sítios, 4 portas, `REVIEW-EDITED-CODE` some, `KIT-TOUCHED` para) → Task 3; § 5.3 provar (3 campos, `init`, alias `Task`/`Agent` por probe) → Task 4; § 6 ADR + `--release` → Task 6; § 7 lugares do contrato → distribuídos (Task 1 README/suíte, Task 2 pipeline/schema, Task 3 pipeline/failure-modes/CLAUDE.md, Task 4 tabela do ledger, Task 7 rule/glossário/kaizen/TODO/baseline); § 8 números → `sdd census` (Task 5) e a entrada em aberto do `KAIZEN_LOG` (Task 7); § 10 pendências → PR body e `TODO.md` (Task 7). A `mcp:` não vazia (exceção declarada) está implementada como "sem strict + sensor compara com a lista" (Task 2 Step 3, Task 4 Step 3), como a spec § 4.1 permite.

**Nomes consistentes entre tasks.** `phase_hat`/`phase_agent` (T1) ← `hat_disallowed`/`hat_writes`/`hat_mcp`/`hat_expand` (T2) ← `hat_path_allowed`/`hat_guard_check`/`hat_crossed_escalation`/`HAT_CROSSED_WHY`/`KIT_TOUCHED_WHY` (T3) ← `hat_init_facts`/`LAST_PHASE_MCP_SEEN`/`LAST_PHASE_TOOLS_LEAKED`/`LAST_PHASE_DENIALS`/`LAST_PHASE_LEAK_NAMES` (T4); `LAST_PHASE_STREAM`/`LAST_PHASE_DISALLOWED`/`LAST_PHASE_MCP` publicados em T2 e lidos em T4; campos `mcp_seen`/`tools_leaked`/`denials` (T4) lidos por `health_release` (T6); `HAT-CROSSED`/`hat-crossed`/`kit-touched` grafados igual em runner, probes, mutantes e docs.

**Sem placeholder** exceto os quatro marcados `<…>` que **só** o executor pode preencher por medição (a linha `init` colada, a versão do CLI, a data, o nome `Task`/`Agent`) — cada um vem com o comando que o produz.
