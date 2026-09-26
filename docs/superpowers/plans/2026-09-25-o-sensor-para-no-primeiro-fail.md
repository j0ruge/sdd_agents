# O sensor para no primeiro FAIL — plano de implementação (2026-09-25)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** levar o `sdd health` de 37 min 42 s para **20 min ou menos**, sem mudar veredito nenhum.
Três mudanças: o sensor para no primeiro FAIL sob `SDD_MUTANT`, o controle do catálogo roda como
primeiro job do pool, e o pool lança os mutantes do mais longo ao mais curto.

**Architecture:** uma cláusula no ponto único de falha de nove sensores (`fail()` em bash,
`check()` no Python do coordination), segura por um censo comportamental no `check-health.sh`
que enumera os sensores a partir da própria suíte. No `check-mutation.sh`, o mapa de assassinos
ganha uma coluna de segundos, e três funções novas (`load_killer_map`, `launch_order`, `run_pool`)
têm selftests próprios que rodam a cada invocação, inclusive no passo `--anchors` da suíte rápida.

**Tech Stack:** bash 5 (compatível com 4.3+ onde há `wait -n`), mawk (orientado a byte), Python
3.9+, GNU coreutils. Sem dependência nova.

**Spec:** [`docs/superpowers/specs/2026-09-25-o-sensor-para-no-primeiro-fail-design.md`](../specs/2026-09-25-o-sensor-para-no-primeiro-fail-design.md)
(commit `95e356a`). Leia o spec antes da Task 1: os números, o argumento de por que nenhum
veredito muda e os limites declarados moram lá.

**Branch:** `perf/sensor-para-no-primeiro-fail`, criado a partir de `main` = `8f2f2a9`. O spec já
está commitado nele.

## Global Constraints

- **Nenhum veredito muda.** O catálogo continua 406 de 406, e o diferencial da amostra dá 0 de 24
  rc diferentes.
- **Fora de mutante nada muda.** A cláusula só age com `SDD_MUTANT` não vazio.
- **A saída vem depois de imprimir e contar.** O log do mutante continua nomeando o que o matou,
  porque o `killer_of` lê o passo desse log.
- **Meta:** `sdd health` ≤ 20 min na 2ª rodada depois do código final (a 1ª grava os tempos).
- **Idioma:** o que vai em `tests/` (código, comentários, mensagens) é inglês. O plano, o spec, o
  `KAIZEN_LOG.md`, o `TODO.md` e o `CLAUDE.md` são pt-BR.
- **bash do kit:**
  - os sensores rodam com `set -uo pipefail`, sem `-e`;
  - herestring (`<<< "$x"`), nunca `printf … | grep -q`;
  - `grep -m` só com `-q`;
  - `cd` relativo dentro de `$(...)` leva `CDPATH=''`;
  - nenhum comentário dentro de bloco continuado por `\`;
  - no mawk, nenhuma classe negada com caractere multibyte.
- **Commits:** `<tipo>(<escopo>): <o quê>`, com o porquê no corpo e as linhas de atribuição que o
  system reminder da sessão der.
- **Nunca commitar com um `sdd health` ou o harness da Task 4 rodando.** O hook de commit do repo
  apaga `/tmp/sdd-*` com mais de 10 min, e isso mata as sandboxes em voo.
- **Suíte ou health destacados só pelo lançador** da seção "Antes de começar" (`SIG_DFL` em
  HUP/INT/QUIT/PIPE, sem `CLAUDE*` no ambiente). Com `setsid nohup … &` o SIGINT nasce ignorado e
  o probe de sinal do `check-coordination.sh` estoura o timeout de 8 s.
- **Nunca rode `tests/check-mutation.sh` sem argumento à mão** (é o catálogo inteiro, ~40 min).
  O catálogo roda só pelo `sdd health`, na Entrega.
- **Push** no branch da missão é permitido. **Merge**, só com o ok do humano.

## Review Focus

1. **Um sensor chama `fail()` num controle negativo, esperando seguir em frente.** Sob
   `SDD_MUTANT=1`, no kit intacto, ele sairia vermelho. Pino: a Task 1, passo 7, roda a suíte
   inteira sob `SDD_MUTANT=1` e exige rc 0.
2. **O controle do catálogo, agora sob carga total, dá vermelho só por tempo** (frente P3). Pino:
   a Task 4 roda o CONTROL dentro de um pool de 12 jobs, 3 vezes, e exige rc 0 nas três.
3. **Mapa antigo, torto ou ausente:** duas colunas (o mapa do #168), tempo não numérico, arquivo
   que não existe. Pino: `order_selftest` (Task 2).
4. **O `SystemExit` do coordination deixa processo ou lock para trás.** Pino: a Task 4 roda dois
   mutantes que o coordination mata e exige zero `sdd-coordination` vivos depois.
5. **Um sensor que roda a si mesmo como filho perde o nome da regra.** É o selftest do `hat`. Pino:
   a asserção do censo sobre o `env -u SDD_MUTANT` (Task 1) e `SDD_MUTANT=1 tests/check-hat.sh`
   verde (Task 1, passo 7).

Limite declarado, sem pino: um `fail()` chamado dentro de um subshell faria o `exit` parar só o
subshell. Hoje não existe nenhum caso assim, e um caso desses já perderia o `fails`. O censo não
enxerga o ponto de chamada, e o comentário dele diz isso.

---

## Antes de começar

- [ ] **A. Confira o estado.**

```bash
cd /home/joruge/repos/sdd_agents
git switch perf/sensor-para-no-primeiro-fail && git status --short && git log --oneline -2
ps -eo pid,etime,cmd | grep -E 'bin/sdd|run-all|check-mutation' | grep -v grep
```

Expected: branch `perf/sensor-para-no-primeiro-fail`, árvore limpa, HEAD com o commit do plano
logo acima de `95e356a docs(spec): …`, e nenhum processo listado.

- [ ] **B. Grave o lançador e o conferidor de carimbo no scratchpad desta sessão.** Guarde o
  caminho do scratchpad em `$SP` em cada comando (o system prompt da sessão diz qual é).

```bash
cat > "$SP/health-launch.py" <<'EOF'
#!/usr/bin/env python3
# Detached launcher for `sdd health` / the suite: restores SIG_DFL on HUP/INT/QUIT/PIPE (setsid
# nohup leaves SIGINT ignored and check-coordination's signal probe times out), drops CLAUDE* from
# the env, new session, stdout+stderr to a log, parent returns at once.
import os, signal, sys
log, cwd, argv = sys.argv[1], sys.argv[2], sys.argv[3:]
if os.fork():
    sys.exit(0)
os.setsid()
if os.fork():
    os._exit(0)
for s in (signal.SIGHUP, signal.SIGINT, signal.SIGQUIT, signal.SIGPIPE):
    signal.signal(s, signal.SIG_DFL)
env = {k: v for k, v in os.environ.items() if not k.startswith("CLAUDE")}
os.chdir(cwd)
fd = os.open(log, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o644)
nul = os.open(os.devnull, os.O_RDONLY)
os.dup2(nul, 0); os.dup2(fd, 1); os.dup2(fd, 2)
os.execvpe("bash", ["bash", "-c", 'date "+START %F %T"; "$@"; rc=$?; date "+END %F %T"; echo "RC=$rc"', "launch"] + argv, env)
EOF
cat > "$SP/stamp-check.sh" <<'EOF'
#!/usr/bin/env bash
# Same recipe as mutation_stamp_key in bin/sdd (paths bin tests templates config).
set -euo pipefail
cd /home/joruge/repos/sdd_agents
listing="$(find bin tests templates config -type f -print0 | LC_ALL=C sort -z | xargs -0 -r md5sum)"
key="$(md5sum <<< "$listing" | cut -d' ' -f1)"
stamp="$(cat .sdd/logs/mutation-stamp 2>/dev/null || true)"
echo "key=$key"; echo "stamp=$stamp"
[ "$key" = "$stamp" ] && echo "STAMP VALID" || { echo "STAMP INVALID"; exit 1; }
EOF
chmod +x "$SP/stamp-check.sh"
```

Uso do lançador: `python3 "$SP/health-launch.py" <log> /home/joruge/repos/sdd_agents <comando…>`.
Para esperar, use um `until grep -q '^RC=' <log>; do sleep 20; done` em segundo plano (Bash com
`run_in_background`). **Nunca** rode a suíte ou o health como tarefa de fundo do próprio Bash tool.

- [ ] **C. Grave o remapeador de âncoras do `TODO.md`.** Toda task que desloca linhas de um
  arquivo citado por âncora roda este script antes do commit. Ele compara a linha que a âncora
  aponta no `HEAD` com o arquivo editado e troca o número quando o conteúdo mudou de lugar. O
  `tests/check-todo.sh` (passo "findings file holds its shape" da suíte) reprova âncora a mais de
  10 linhas do símbolo.

```bash
cat > "$SP/remap-anchors.py" <<'EOF'
#!/usr/bin/env python3
# Remap TODO.md anchors `tests/<file>:<N>` whose file changed since HEAD, by the CONTENT of line N
# at HEAD. One pass through re.sub, so a remap never feeds another.
import re, subprocess, pathlib
todo = pathlib.Path("TODO.md"); text = todo.read_text()
changed = set(subprocess.run(["git", "diff", "--name-only", "HEAD", "--", "tests/"],
                             capture_output=True, text=True).stdout.split())
cache = {}
def head_lines(f):
    if f not in cache:
        cache[f] = subprocess.run(["git", "show", f"HEAD:{f}"], capture_output=True, text=True).stdout.splitlines()
    return cache[f]
def remap(m):
    f, n = m.group(1), int(m.group(2))
    if f not in changed:
        return m.group(0)
    old = head_lines(f)
    if not 0 < n <= len(old):
        print(f"OUT OF RANGE {f}:{n} — remap by hand"); return m.group(0)
    hits = [i + 1 for i, l in enumerate(pathlib.Path(f).read_text().splitlines()) if l == old[n - 1]]
    if len(hits) != 1:
        print(f"AMBIGUOUS {f}:{n} -> {hits} — remap by hand"); return m.group(0)
    if hits[0] != n:
        print(f"{f}:{n} -> {hits[0]}")
    return f"`{f}:{hits[0]}`"
todo.write_text(re.sub(r"`(tests/[a-z-]+\.sh):(\d+)`", remap, text))
EOF
```

---

### Task 1: o censo e a cláusula nos nove sensores

**Pré-requisito:** os passos A, B e C de "Antes de começar" feitos. O `$SP/health-launch.py` e o
`$SP/remap-anchors.py` são usados aqui e nas tasks seguintes.

**Files:**
- Modify: `tests/check-health.sh` — o censo novo, logo depois da probe
  `surface: outside a mutant SDD_MUTANT_FIRST changes nothing` (o `fi` dela, ~linha 1403) e antes do
  bloco `# surface: \`--list\` prints STEPS ONLY`; e o próprio `fail()`, linha 103.
- Modify: `tests/check-autonomy.sh:36-37`, `tests/check-gates.sh:34-35`,
  `tests/check-kaizen.sh:34-35`, `tests/check-preflight.sh:41-42`, `tests/check-adr.sh:207-209`,
  `tests/check-dry-run.sh:38-39` — o `fail()`.
- Modify: `tests/check-hat.sh:45` (o `fail()` de uma linha) e `:117` (o filho do selftest).
- Modify: `tests/check-coordination.sh:71-78` — o `check()` do Python.
- Modify: `TODO.md` — as âncoras deslocadas (remapeador).

**Interfaces:**
- Consumes: `pass`, `fail`, `broken` e `$ROOT` do `check-health.sh`; o modo `--list` do
  `tests/run-all.sh`.
- Produces: as funções `census_file_of <título>`, `census_src <arquivo> <bash|py>` e
  `census_call <bash|py> <definição> <valor de SDD_MUTANT | UNSET>`, esta última imprimindo
  exatamente `rc=<n> said=<n> back=<n>`. Nenhuma task seguinte as consome.

- [ ] **Step 1: Escreva o censo (o teste) no `check-health.sh`.** Localize o fim da probe
  `outside a mutant SDD_MUTANT_FIRST changes nothing`:

```bash
grep -n "outside a mutant SDD_MUTANT_FIRST changes nothing" tests/check-health.sh
```

Logo depois do `fi` que fecha esse `if` (e antes da linha `# ----…` que abre
`# surface: \`--list\` prints STEPS ONLY`), insira, com uma linha em branco antes:

```bash
# ---------------------------------------------------------------------------
# surface: inside a mutant every sensor stops at its FIRST red assertion
#
# The catalogue reads the suite's rc and nothing else, and a sensor that called fail() once has
# already decided that rc: everything it runs after is paid and read by no one. Measured on 24
# mutants of 8f2f2a9 (2026-09-25): the first FAIL lands, on the median, halfway through the killing
# sensor — 1328.7 s of sensor against 624.4 s up to the first FAIL. So each sensor that runs inside
# a mutant ends at its first fail() when SDD_MUTANT is set, AFTER printing it: the mutant's log still
# names what killed it, and killer_of reads the step off that log.
#
# A CENSUS, not a sample. The population is read off the suite itself — every step
# `SDD_MUTANT=1 run-all.sh --list` prints, joined to the tests/check-*.sh its `run` line executes —
# and every one of those files that defines a bash `fail() {` or a Python `def check(` is measured.
# Each definition is sourced (the killer_of guard: one short, closed block, or SENSOR-BROKEN) and
# called three times: under SDD_MUTANT=1 it must exit 1 with the FAIL already printed; with the
# variable unset, and set to the empty string, it must return with its counter up by one. A new
# sensor that runs inside mutants and forgets the clause turns this red, because the census walks
# the suite instead of a table somebody has to remember to extend.
# Outside the census, declared: check-entrypoint.sh and check-templates.sh run inside mutants with
# no single failure primitive (1 and 0 kills in the map of 2026-09-25, ~0.5 s each). Not measured
# here, and said: a fail() called inside a subshell would stop only the subshell — no such call
# exists today, and one would already lose its `fails` count; the census cannot see call sites.
# CENSUS_FLOOR is the nine of 2026-09-25 (autonomy, gates, kaizen, preflight, health, adr, hat,
# dry-run, coordination): the list or the join to tests/ that stops reading the suite fails loudly.
# ---------------------------------------------------------------------------
CENSUS_FLOOR=9
census_file_of() { # census_file_of <step title> — the tests/check-*.sh that step runs, or nothing
  local hits
  hits="$(grep -F -- "run \"$1\" \"\$ROOT/tests/check-" "$ROOT/tests/run-all.sh" \
          | sed -n 's|.*"\$ROOT/tests/\(check-[a-z-]*\.sh\)".*|\1|p')" || true
  printf '%s' "${hits%%$'\n'*}"
}
census_src() { # census_src <file> <bash|py> — the definition, printed only when short and closed
  local src n
  if [ "$2" = bash ]; then
    src="$(awk '/^fail\(\) \{/ { p = 1 } p { print; if ($0 ~ /\}[[:space:]]*$/) exit }' "$1")"
    n="$(grep -c . <<< "$src")"
    [ -n "$src" ] && [ "$n" -le 8 ] && [ "${src: -1}" = '}' ] || return 1
  else
    src="$(awk '/^def check\(/ { p = 1 } p { if ($0 ~ /^[[:space:]]*$/) exit; print }' "$1")"
    n="$(grep -c . <<< "$src")"
    [ -n "$src" ] && [ "$n" -le 16 ] || return 1
  fi
  printf '%s\n' "$src"
}
census_call() { # census_call <bash|py> <definition> <SDD_MUTANT value | UNSET> — "rc=<n> said=<n> back=<n>"
  local out rc=0 prog
  if [ "$1" = bash ]; then
    out="$( { fails=0; PROBES=0
               eval "$2"
               if [ "$3" = UNSET ]; then unset SDD_MUTANT; else export SDD_MUTANT="$3"; fi
               fail 'census probe' x y
               printf 'back=%s\n' "$fails"; } 2>&1 )" || rc=$?
  else
    prog="$(printf 'import os, sys\npassed = failed = 0\n%s\ncheck("census probe", False, "x")\nprint("back=%%d" %% failed)\n' "$2")"
    if [ "$3" = UNSET ]; then out="$(env -u SDD_MUTANT python3 -c "$prog" 2>&1)" || rc=$?
    else out="$(SDD_MUTANT="$3" python3 -c "$prog" 2>&1)" || rc=$?; fi
  fi
  printf 'rc=%s said=%s back=%s\n' "$rc" "$(grep -c 'FAIL  census probe' <<< "$out" || true)" \
         "$(grep -c '^back=1$' <<< "$out" || true)"
}
CENSUS_STEPS="$(SDD_MUTANT=1 "$ROOT/tests/run-all.sh" --list 2>/dev/null || true)"
census_n=0
while IFS= read -r census_step; do
  [ -n "$census_step" ] || continue
  census_f="$(census_file_of "$census_step")"
  [ -n "$census_f" ] || continue
  census_kind=''
  grep -q '^fail() {' "$ROOT/tests/$census_f" && census_kind=bash
  grep -q '^def check(' "$ROOT/tests/$census_f" && census_kind=py
  [ -n "$census_kind" ] || continue
  census_def="$(census_src "$ROOT/tests/$census_f" "$census_kind")" \
    || broken "census: $census_f defines its failure primitive, but not as one short closed block — refusing to source it"
  census_n=$((census_n + 1))
  census_in="$(census_call "$census_kind" "$census_def" 1)"
  census_out="$(census_call "$census_kind" "$census_def" UNSET)"
  census_empty="$(census_call "$census_kind" "$census_def" '')"
  if [ "$census_in" = 'rc=1 said=1 back=0' ] && [ "$census_out" = 'rc=0 said=1 back=1' ] \
     && [ "$census_empty" = 'rc=0 said=1 back=1' ]; then
    pass "surface: $census_f stops at its first FAIL inside a mutant, and only there"
  else
    fail "surface: $census_f stops at its first FAIL inside a mutant, and only there" \
         "SDD_MUTANT=1: rc=1 said=1 back=0 · unset and empty: rc=0 said=1 back=1" \
         "SDD_MUTANT=1: $census_in · unset: $census_out · empty: $census_empty"
  fi
done <<< "$CENSUS_STEPS"
[ "$census_n" -ge "$CENSUS_FLOOR" ] \
  || broken "census: $census_n sensor(s) with a failure primitive among the mutant steps, the floor is $CENSUS_FLOOR — the list or the join to tests/ stopped reading the suite"
# The hat selftest runs its own --check as a child and demands the output NAME the broken rule: that
# child measures the report a human reads, so it runs outside the mutant, where fail() never stops.
if grep -qF 'out="$(env -u SDD_MUTANT "$ROOT/tests/check-hat.sh" --check' "$ROOT/tests/check-hat.sh"; then
  pass 'surface: the hat selftest measures its report outside a mutant'
else
  fail 'surface: the hat selftest measures its report outside a mutant' \
       'the selftest child of tests/check-hat.sh runs under env -u SDD_MUTANT' \
       'the child inherits SDD_MUTANT, and a probe whose rule is named second would read red'
fi
```

- [ ] **Step 2: Rode o censo e veja o RED.**

Run: `tests/check-health.sh > "$SP/t1-red.out" 2>&1; echo "rc=$?"; grep -c '^  FAIL  surface: check-.*stops at its first FAIL' "$SP/t1-red.out"; grep -A2 'FAIL  surface: check-gates.sh' "$SP/t1-red.out"`
Expected: `rc=1`; `9` (uma linha FAIL por sensor: autonomy, gates, kaizen, preflight, health, adr,
hat, dry-run, coordination); o "got" da de `check-gates.sh` diz `SDD_MUTANT=1: rc=0 said=1 back=1`;
e há mais um FAIL, `the hat selftest measures its report outside a mutant`. Se aparecer
`SENSOR-BROKEN`, o erro está no censo, não nos sensores: pare e corrija o Step 1.

- [ ] **Step 3: A cláusula nos sete sensores de `fail()` em duas ou três linhas.** Em cada arquivo,
  a linha abaixo existe exatamente uma vez (conferido em 2026-09-25):

```
         fails=$((fails + 1)); }
```

Troque-a por:

```
         fails=$((fails + 1)); [ -z "${SDD_MUTANT:-}" ] || exit 1; }
```

e insira imediatamente **acima** da linha `fail() {` de cada um estas duas linhas de comentário:

```bash
# Inside a mutant the first red assertion is the verdict: fail() ends the sensor there, AFTER
# printing, so the mutant's log still names it. The census in check-health.sh holds all nine.
```

Arquivos: `tests/check-autonomy.sh`, `tests/check-gates.sh`, `tests/check-kaizen.sh`,
`tests/check-preflight.sh`, `tests/check-health.sh`, `tests/check-adr.sh`, `tests/check-dry-run.sh`.
Um script faz os sete de uma vez e recusa se a âncora não for única:

```bash
python3 - <<'EOF'
import pathlib
OLD = "         fails=$((fails + 1)); }\n"
NEW = '         fails=$((fails + 1)); [ -z "${SDD_MUTANT:-}" ] || exit 1; }\n'
NOTE = ("# Inside a mutant the first red assertion is the verdict: fail() ends the sensor there, AFTER\n"
        "# printing, so the mutant's log still names it. The census in check-health.sh holds all nine.\n")
for name in ["autonomy", "gates", "kaizen", "preflight", "health", "adr", "dry-run"]:
    p = pathlib.Path(f"tests/check-{name}.sh"); s = p.read_text()
    assert s.count(OLD) == 1, (name, "clause anchor")
    assert s.count("\nfail() {") == 1, (name, "fail() anchor")
    s = s.replace(OLD, NEW).replace("\nfail() {", "\n" + NOTE + "fail() {")
    p.write_text(s); print("ok", name)
EOF
```

Expected: sete linhas `ok <nome>`.

- [ ] **Step 4: A cláusula no `hat` e o filho do selftest fora do mutante.** Em `tests/check-hat.sh`:

Troque a linha 45:

```bash
fail() { printf '  FAIL  %s\n' "$1" >&2; fails=$((fails + 1)); }
```

por (com o mesmo comentário de duas linhas acima dela):

```bash
# Inside a mutant the first red assertion is the verdict: fail() ends the sensor there, AFTER
# printing, so the mutant's log still names it. The census in check-health.sh holds all nine.
fail() { printf '  FAIL  %s\n' "$1" >&2; fails=$((fails + 1)); [ -z "${SDD_MUTANT:-}" ] || exit 1; }
```

E, dentro do `probe()` do `selftest()`, troque:

```bash
    out="$("$ROOT/tests/check-hat.sh" --check "$box/sdd-probe.md" 2>&1)"; got=$?
```

por:

```bash
    # Outside a mutant on purpose: this child measures the report a human reads, every rule named.
    out="$(env -u SDD_MUTANT "$ROOT/tests/check-hat.sh" --check "$box/sdd-probe.md" 2>&1)"; got=$?
```

- [ ] **Step 5: A cláusula no `check()` do coordination.** Em `tests/check-coordination.sh`, troque:

```python
    else:
        failed += 1
        print("  FAIL  " + name + ": " + detail, flush=True)
```

por:

```python
    else:
        failed += 1
        print("  FAIL  " + name + ": " + detail, flush=True)
        # Inside a mutant the first red check is the verdict: stop here, after printing. The
        # finally at the bottom still releases every process family and lock this file started.
        if os.environ.get("SDD_MUTANT"):
            raise SystemExit(1)
```

- [ ] **Step 6: Rode o censo e veja o GREEN.**

Run: `bash -n tests/check-*.sh && tests/check-health.sh > "$SP/t1-green.out" 2>&1; echo "rc=$?"; grep -c '^  ok    surface: check-.*stops at its first FAIL' "$SP/t1-green.out"; grep -E 'FAIL|SENSOR-BROKEN' "$SP/t1-green.out" | head`
Expected: `rc=0`, `9`, e nenhuma linha FAIL ou SENSOR-BROKEN.

- [ ] **Step 7: O regime do controle: a suíte inteira sob `SDD_MUTANT=1` no kit intacto.** É a
  rede para o Review Focus 1 e 5. Rode pelo lançador e espere o `RC=`:

```bash
python3 "$SP/health-launch.py" "$SP/t1-mutant-suite.log" /home/joruge/repos/sdd_agents \
  env SDD_MUTANT=1 tests/run-all.sh
```

(A variável vai no comando lançado, nunca no seu shell: com `SDD_MUTANT` exportado ali, o
`check-mutation.sh` se recusa a rodar e todo sensor passa a parar no primeiro FAIL.)

Espere com um poll em segundo plano (`until grep -q '^RC=' "$SP/t1-mutant-suite.log"; do sleep 10; done`),
depois:

Run: `grep -E '^RC=|✗ failed|FAIL|SENSOR-BROKEN' "$SP/t1-mutant-suite.log" | head -20`
Expected: `RC=0` e nenhuma outra linha. Qualquer `✗ failed` aqui é um sensor que chama `fail()`
esperando continuar: leia o log do passo, conserte **o sensor** (nunca afrouxe o censo) e repita.
Rode também `SDD_MUTANT=1 tests/check-hat.sh > "$SP/t1-hat.out" 2>&1; echo "rc=$?"` e exija `rc=0`.

- [ ] **Step 8: A passada de sabotagem.** Cada sabotagem é aplicada, medida e desfeita com
  `git checkout -- <arquivo>` **antes** da próxima, e cada uma tem de deixar o censo vermelho pelo
  motivo nomeado. Rode o censo com `tests/check-health.sh > "$SP/sab.out" 2>&1; echo rc=$?` e leia
  a linha indicada. Antes de medir, prove que a sabotagem mudou o que dizia mudar: `git diff --stat`
  mostra só o arquivo da sabotagem, e `git diff` mostra só as linhas da coluna "Como". Uma
  sabotagem cujo texto não casou não prova nada, nem quando o censo fica vermelho por acaso.

| # | Sabotagem | Como | Tem de ler |
|---|---|---|---|
| a | um sensor sem a cláusula | em `tests/check-dry-run.sh`, apague `; [ -z "${SDD_MUTANT:-}" ] \|\| exit 1` | `FAIL  surface: check-dry-run.sh …`, got `SDD_MUTANT=1: rc=0 said=1 back=1` |
| b | `exit` virou `return` | em `tests/check-kaizen.sh`, troque `\|\| exit 1; }` por `\|\| return 1; }` | FAIL de `check-kaizen.sh`, got com `back=1` |
| c | a cláusula antes do `printf` | em `tests/check-gates.sh`, ponha `[ -z "${SDD_MUTANT:-}" ] \|\| exit 1; ` logo depois de `fail() { ` e apague a do fim | FAIL de `check-gates.sh`, got `SDD_MUTANT=1: rc=1 said=0 back=0` |
| d | o censo lê metade da suíte | no bloco do censo, troque `CENSUS_STEPS="$(SDD_MUTANT=1 …)"` por `CENSUS_STEPS="$(SDD_MUTANT=1 "$ROOT/tests/run-all.sh" --list 2>/dev/null \| head -n 6 \|\| true)"` | `SENSOR-BROKEN  census: … the floor is 9` e `rc=90` |
| e | o filho do `hat` herda a variável | em `tests/check-hat.sh`, apague `env -u SDD_MUTANT ` da linha do `out=` | `FAIL  surface: the hat selftest measures its report outside a mutant` |
| f | o coordination sem a cláusula | em `tests/check-coordination.sh`, apague as duas linhas `if os.environ.get("SDD_MUTANT"):` / `raise SystemExit(1)` | FAIL de `check-coordination.sh`, got `SDD_MUTANT=1: rc=0 …` |

Expected: as seis vermelhas pelo motivo da coluna; `git status --short` limpo (fora dos arquivos da
task) ao fim.

- [ ] **Step 9: Remapeie as âncoras e rode a suíte rápida inteira.**

```bash
python3 "$SP/remap-anchors.py"
tests/check-todo.sh > "$SP/t1-todo.out" 2>&1; echo "rc=$?"; tail -1 "$SP/t1-todo.out"
```

Expected: linhas `tests/…:N -> M` para as âncoras que andaram; `rc=0` e
`ok    83 finding(s), all within 8 lines, carrying anchor + date, every anchor on target`. Se o
script disser `AMBIGUOUS` ou `OUT OF RANGE`, ache a linha certa à mão pelo símbolo que o item cita.

Depois, a suíte rápida pelo lançador (3–4 min):
`python3 "$SP/health-launch.py" "$SP/t1-suite.log" /home/joruge/repos/sdd_agents tests/run-all.sh`
Expected: `RC=0` e a última linha verde `suite green`.

- [ ] **Step 10: Commit.**

```bash
git add tests/check-health.sh tests/check-autonomy.sh tests/check-gates.sh tests/check-kaizen.sh \
        tests/check-preflight.sh tests/check-adr.sh tests/check-dry-run.sh tests/check-hat.sh \
        tests/check-coordination.sh TODO.md
git commit -F - <<'EOF'
perf(sensors): inside a mutant every sensor stops at its first FAIL

The catalogue reads the suite's rc and nothing else, and a sensor that
called fail() once has already decided it. Measured on 24 mutants of
8f2f2a9: the first FAIL lands halfway through the killing sensor, 1328.7 s
of sensor against 624.4 s up to it.

fail() in the eight bash sensors that run inside mutants, and check() in
check-coordination.sh's Python, now end the sensor under SDD_MUTANT, after
printing and counting, so killer_of still reads the step off the log. The
coordination exit is a SystemExit, so its existing finally still releases
every process family and lock. The hat selftest runs its --check child
under env -u SDD_MUTANT: that child measures the report a human reads.

A behavioural census in check-health.sh walks `SDD_MUTANT=1 run-all.sh
--list`, joins each step to its tests/check-*.sh and sources every failure
primitive it finds: exit 1 with the FAIL printed inside a mutant, return
with the counter up outside it. Floor 9. Six sabotages each turn it red.

<linhas de atribuição do system reminder>
EOF
```

---

### Task 2: o mapa com tempos, o mais longo primeiro, o controle no pool

**Files:**
- Modify: `tests/check-mutation.sh`
  - logo depois de `trap 'rm -rf "$WORK"' EXIT` (~linha 106): as funções novas e os selftests;
  - `run_mutant()` (~linha 4606): a medida dos segundos;
  - o bloco do mapa (~linha 4630): o comentário e a remoção do `declare -A KILLER=()`;
  - a região do controle e do pool (de `# CONTROL run — the copy has to be green` até o `wait`
    antes de `caught=0; gaps=0; errors=0`): substituída inteira;
  - o gravador do mapa (depois do laço de pontuação): a terceira coluna.
- Modify: `TODO.md` — as âncoras deslocadas (remapeador).

**Interfaces:**
- Consumes: `JOBS`, `WORK`, `CATALOG`, `sandbox`, `run_mutant`, `pass`, `fail` e `KILLERS_FILE`,
  que já existem no `check-mutation.sh`.
- Produces:
  - `declare -A KILLER SECS` (globais);
  - `load_killer_map <tsv>`;
  - `launch_order` (stdin `<slug>\t<segundos ou vazio>` na ordem do catálogo, stdout os slugs na
    ordem de lançamento);
  - `control_red <dir>`;
  - `control_verdict <dir>` (rc 0 com o controle verde; senão imprime
    `HARNESS-BROKEN: … (control rc <rc|none>)` e rc 1);
  - `run_pool <dir> <control-fn> <mutant-fn> <slug…>`, que publica `POOL_LAUNCHED`;
  - o arquivo `$WORK/<slug>.secs`;
  - o formato do mapa `slug\tpasso\tsegundos`.
  A Task 4 consome o formato do mapa só para ler.

- [ ] **Step 1: Escreva os dois selftests (os testes) e as chamadas deles.** Em
  `tests/check-mutation.sh`, logo depois da linha `trap 'rm -rf "$WORK"' EXIT`, insira:

```bash

# ---------------------------------------------------------------------------
# The killer map, the launch order and the pool are functions so each can carry probes of its own:
# the catalogue cannot reach the harness, the same rule as jobs_selftest above. Both selftests run
# on every invocation, --anchors included, so the fast suite measures them.
# ---------------------------------------------------------------------------
declare -A KILLER=() SECS=()

order_selftest() {
  local got f="$WORK/order-selftest.tsv"
  load_killer_map "$WORK/no-such-map.tsv"
  [ "${#KILLER[@]}" = 0 ] || { echo "  SELFTEST FAIL  a missing map was not an empty one" >&2; return 1; }
  printf 'b\tstep one\t10\nc\tstep two\t50\ne\tstep one\t10\nf\tstep two\tx\ng\tstep three\n' > "$f"
  load_killer_map "$f"
  [ "${KILLER[g]:-}" = 'step three' ] || { echo "  SELFTEST FAIL  a two-column line was not read: KILLER[g]='${KILLER[g]:-}'" >&2; return 1; }
  [ "${SECS[c]:-}" = 50 ] || { echo "  SELFTEST FAIL  a recorded time was not read: SECS[c]='${SECS[c]:-}'" >&2; return 1; }
  [ -z "${SECS[f]:-}" ] || { echo "  SELFTEST FAIL  a time that is not digits was kept: SECS[f]='${SECS[f]}'" >&2; return 1; }
  got="$(for s in a b c d e f g; do printf '%s\t%s\n' "$s" "${SECS[$s]:-}"; done | launch_order | tr '\n' ' ')"
  [ "$got" = 'a d f g c b e ' ] || { echo "  SELFTEST FAIL  launch order '$got', expected 'a d f g c b e '" >&2; return 1; }
  KILLER=(); SECS=()
  return 0
}

pool_selftest() {
  local JOBS=2 d="$WORK/pool-selftest" why
  mkdir -p "$d"
  st_control_red()   { echo 1 > "$d/control.rc"; }
  st_control_green() { echo 0 > "$d/control.rc"; }
  st_mutant()        { sleep 0.3; }
  rm -f "$d/control.rc"
  run_pool "$d" st_control_red st_mutant m1 m2 m3 m4 m5 m6 m7 m8
  [ "$POOL_LAUNCHED" -le "$JOBS" ] || { echo "  SELFTEST FAIL  red control: $POOL_LAUNCHED of 8 mutants launched, expected at most $JOBS" >&2; return 1; }
  why="$(control_verdict "$d")" && { echo "  SELFTEST FAIL  a red control was read as green" >&2; return 1; }
  case "$why" in *HARNESS-BROKEN*) : ;; *) echo "  SELFTEST FAIL  a red control was refused without saying HARNESS-BROKEN: $why" >&2; return 1 ;; esac
  rm -f "$d/control.rc"
  control_verdict "$d" >/dev/null && { echo "  SELFTEST FAIL  a control with no rc was read as green" >&2; return 1; }
  run_pool "$d" st_control_green st_mutant m1 m2 m3
  [ "$POOL_LAUNCHED" = 3 ] || { echo "  SELFTEST FAIL  green control: $POOL_LAUNCHED of 3 mutants launched" >&2; return 1; }
  control_verdict "$d" >/dev/null || { echo "  SELFTEST FAIL  a green control was refused" >&2; return 1; }
  return 0
}

if ! order_selftest; then
  echo "the killer map or the launch order does not measure what it claims — refusing to schedule mutants with it" >&2
  exit 1
fi
if (: & wait -n) 2>/dev/null && ! pool_selftest; then
  echo "the pool does not stop on a red control — refusing to schedule mutants with it" >&2
  exit 1
fi
```

- [ ] **Step 2: Rode e veja o RED.**

Run: `tests/check-mutation.sh --anchors > "$SP/t2-red.out" 2>&1; echo "rc=$?"; head -5 "$SP/t2-red.out"`
Expected: `rc=1`, com `load_killer_map: command not found` (ou `launch_order`) e a linha
`the killer map or the launch order does not measure what it claims`.

- [ ] **Step 3: As funções.** Insira-as entre o `declare -A KILLER=() SECS=()` e o
  `order_selftest() {` do Step 1:

```bash
# load_killer_map <tsv> — fills KILLER[slug]=<step> and SECS[slug]=<seconds>. A line of two columns
# (the map before 2026-09-25) is read with no time; a time that is not digits is dropped, never
# guessed. A missing file is an empty map, and the catalogue runs in its usual order.
load_killer_map() {
  local k v s
  [ -r "$1" ] || return 0
  while IFS=$'\t' read -r k v s; do
    [ -n "$k" ] && [ -n "$v" ] || continue
    KILLER["$k"]="$v"
    case "$s" in ''|*[!0-9]*) ;; *) SECS["$k"]="$s" ;; esac
  done < "$1"
}

# launch_order — stdin: <slug> TAB <seconds or empty>, in catalogue order; stdout: the slugs in
# launch order. The ones with no recorded time come first (new mutants and survivors run the whole
# suite), in catalogue order; then the longest first, ties in catalogue order. A pool that starts
# its longest jobs last ends with one slot busy and the rest idle.
launch_order() {
  awk -F'\t' '{ s = ($2 ~ /^[0-9]+$/) ? $2 : 999999; printf "%s\t%d\t%s\n", s, NR, $1 }' \
    | LC_ALL=C sort -t "$(printf '\t')" -k1,1nr -k2,2n | cut -f3
}

# control_red <dir> — true once the control run has written a rc that is not 0.
control_red() {
  local rc
  rc="$(cat "$1/control.rc" 2>/dev/null || true)"
  [ -n "$rc" ] && [ "$rc" != 0 ]
}

# control_verdict <dir> — 0 when the control came back green; otherwise prints why and returns 1.
# A control that wrote no rc at all (it died before) is not green either.
control_verdict() {
  local rc
  rc="$(cat "$1/control.rc" 2>/dev/null || true)"
  [ "$rc" = 0 ] && return 0
  printf 'HARNESS-BROKEN: the copy is not green even without sabotage (control rc %s)\n' "${rc:-none}"
  return 1
}

# run_pool <dir> <control-fn> <mutant-fn> <slug...> — the control run is the pool's FIRST job and
# the mutants start beside it. Once the control is back red no further mutant is launched, and the
# ones already running are waited for, never killed: their sdd and coordination children have no
# process group of their own, and killing the subshell would orphan them. Publishes POOL_LAUNCHED.
# `wait -n` is bash 4.3+; the caller checks for it.
run_pool() {
  local dir="$1" control="$2" mutant="$3" slug running=1
  shift 3
  POOL_LAUNCHED=0
  "$control" &
  for slug in "$@"; do
    control_red "$dir" && break
    "$mutant" "$slug" &
    POOL_LAUNCHED=$((POOL_LAUNCHED + 1))
    running=$((running + 1))
    if [ "$running" -ge "$JOBS" ]; then wait -n; running=$((running - 1)); fi
  done
  wait
}
```

- [ ] **Step 4: Rode e veja o GREEN.**

Run: `tests/check-mutation.sh --anchors > "$SP/t2-green.out" 2>&1; echo "rc=$?"; tail -2 "$SP/t2-green.out"`
Expected: `rc=0` e `ok    anchors: all 406 mutants still apply and leave valid code`.

- [ ] **Step 5: Sabotagem dos selftests.** Cada uma aplicada, medida (`tests/check-mutation.sh --anchors`)
  e desfeita antes da próxima; todas têm de dar `rc=1` com a mensagem indicada:
  - no `launch_order`, troque `s = ($2 ~ /^[0-9]+$/) ? $2 : 999999` por `s = 0` →
    `SELFTEST FAIL  launch order` (o pool ignora os tempos);
  - no `load_killer_map`, troque `[ -n "$k" ] && [ -n "$v" ] || continue` por
    `[ -n "$k" ] && [ -n "$v" ] && [ -n "$s" ] || continue` → `SELFTEST FAIL  a two-column line was not read`;
  - no `run_pool`, apague a linha `control_red "$dir" && break` → `SELFTEST FAIL  red control: 8 of 8`;
  - no `control_verdict`, troque `[ "$rc" = 0 ] && return 0` por `[ "$rc" != 1 ] && return 0` →
    `SELFTEST FAIL  a control with no rc was read as green`.

- [ ] **Step 6: Religue a região do controle e do pool.** Apague a linha `declare -A KILLER=()`
  que fica logo depois de `KILLERS_FILE="$ROOT/.sdd/cache/mutation-killers.tsv"`: a declaração
  agora mora no topo. Substitua o comentário do mapa (o bloco que começa em
  `# The killer map: <slug> TAB <step name>, learned from the last catalogue`) trocando
  `<slug> TAB <step name>` por `<slug> TAB <step name> TAB <seconds>`, e acrescente ao fim do mesmo
  comentário a linha:

```bash
# The seconds are the mutant's own suite time; the pool reads them to launch the longest first.
```

Depois substitua a região inteira que vai de

```bash
# ---------------------------------------------------------------------------
# CONTROL run — the copy has to be green with NO sabotage at all.
```

até o `wait` que fica imediatamente antes de `caught=0; gaps=0; errors=0` (o texto atual inteiro
está no fim deste plano, no Anexo A; confira-o contra o arquivo com `Read` antes do `Edit`) por:

```bash
# ---------------------------------------------------------------------------
# CONTROL run — the copy has to be green with NO sabotage at all.
#
# Without it, a broken copy (a future test reading agents/ or docs/, for instance) would leave
# EVERY mutant red and the score would read 100% while measuring exactly nothing — the same
# vacuity the mutation exists to catch, now inside the measuring device itself.
#
# It is the pool's FIRST job, and the mutants start beside it: run alone first, it cost ~3.9 min
# of an otherwise idle pool (2026-09-25). No score is written before its rc is read below, so no
# verdict can come from a red control; a red control stops further launches (run_pool). `wait -n`
# is bash 4.3+; without it the control runs first and the mutants go in barriers of JOBS — a
# declared degradation, never a silent one.
# ---------------------------------------------------------------------------
echo "== control (the first job of the pool) =="
sandbox "$WORK/control"
run_control() {
  local rc=0
  SDD_MUTANT=1 "$WORK/control/tests/run-all.sh" > "$WORK/control.log" 2>&1 || rc=$?
  echo "$rc" > "$WORK/control.rc"
}

load_killer_map "$KILLERS_FILE"
echo "== killer map: ${#KILLER[@]} mutant(s) run their last killer first, ${#SECS[@]} with a recorded time =="
mapfile -t ORDER < <(for slug in "${CATALOG[@]}"; do printf '%s\t%s\n' "$slug" "${SECS[$slug]:-}"; done | launch_order)

# ---------------------------------------------------------------------------
# A pool, not batches: the old `[ i % JOBS -eq 0 ] && wait` was a barrier every JOBS mutants, so
# each batch cost its slowest member while the finished slots sat idle. `wait -n` frees a slot as
# soon as ANY mutant exits. Safe because run_mutant shares nothing — each writes its own
# $WORK/<slug>.rc/.log/.secs and the scoring loop below reads the catalogue in order afterwards.
# The launch order is launch_order's: no recorded time first, then the longest first.
if (: & wait -n) 2>/dev/null; then
  echo "== mutants (pool of $JOBS, longest first) =="
  run_pool "$WORK" run_control run_mutant "${ORDER[@]}"
else
  echo "== mutants (batches of $JOBS — this bash has no 'wait -n': the control runs first) =="
  run_control
  if ! control_red "$WORK"; then
    i=0
    for slug in "${ORDER[@]}"; do
      run_mutant "$slug" &
      i=$((i + 1))
      [ $((i % JOBS)) -eq 0 ] && wait
    done
    wait
  fi
fi

if why="$(control_verdict "$WORK")"; then
  pass "the kit copy is green with no sabotage"
else
  fail "$why" "the score would read 100% by vacuity — see $WORK/control.log"
  tail -20 "$WORK/control.log" >&2
  exit 1
fi
```

- [ ] **Step 7: Os segundos no `run_mutant` e no mapa.** Em `run_mutant()`, troque:

```bash
  local rc=0
  SDD_MUTANT=1 SDD_MUTANT_FIRST="${KILLER[$slug]:-}" "$box/tests/run-all.sh" > "$box.log" 2>&1 || rc=$?
  echo "$rc" > "$box.rc"
```

por:

```bash
  local rc=0 t0=$SECONDS
  SDD_MUTANT=1 SDD_MUTANT_FIRST="${KILLER[$slug]:-}" "$box/tests/run-all.sh" > "$box.log" 2>&1 || rc=$?
  echo "$((SECONDS - t0))" > "$box.secs"
  echo "$rc" > "$box.rc"
```

E no gravador do mapa (o bloco `if mkdir -p "${KILLERS_FILE%/*}" 2>/dev/null \`), troque:

```bash
        if [ -s "$WORK/$slug.killer" ]; then printf '%s\t%s\n' "$slug" "$(cat "$WORK/$slug.killer")"; fi
```

por:

```bash
        if [ -s "$WORK/$slug.killer" ]; then
          printf '%s\t%s\t%s\n' "$slug" "$(cat "$WORK/$slug.killer")" "$(cat "$WORK/$slug.secs" 2>/dev/null || true)"
        fi
```

- [ ] **Step 8: Sintaxe, lint, selftests, âncoras e suíte.**

```bash
bash -n tests/check-mutation.sh && shellcheck -S warning tests/check-mutation.sh && echo lint-ok
tests/check-mutation.sh --anchors > "$SP/t2-anchors.out" 2>&1; echo "rc=$?"; tail -1 "$SP/t2-anchors.out"
python3 "$SP/remap-anchors.py"
tests/check-todo.sh > "$SP/t2-todo.out" 2>&1; echo "rc=$?"; tail -1 "$SP/t2-todo.out"
```

Expected: `lint-ok`; `rc=0` e `anchors: all 406 mutants still apply`; o remapeador lista as
âncoras do `check-mutation.sh` que andaram; `rc=0` e `every anchor on target`. Depois, a suíte
rápida pelo lançador (`tests/run-all.sh`, `$SP/t2-suite.log`): `RC=0`.

O fluxo de ponta a ponta do catálogo (controle no pool, ordem, gravação dos segundos) é medido na
Entrega, pelo `sdd health`. As funções têm selftest; a cola de topo (o `if why=…` e o `exit 1`)
é a mesma forma de hoje.

- [ ] **Step 9: Commit.**

```bash
git add tests/check-mutation.sh TODO.md
git commit -F - <<'EOF'
perf(mutation): the control is the pool's first job, and the longest mutants go first

The control run cost ~3.9 min alone before the pool started. It is now the
pool's first job and the mutants start beside it; no score is written
before its rc is read, and a red control stops further launches (the ones
running are waited for, never killed).

The killer map gains a third column, the mutant's own suite seconds, and
the pool launches the mutants with no recorded time first, then the
longest first. A two-column map (before today) is read with no time.

load_killer_map, launch_order, control_red, control_verdict and run_pool
are functions with selftests (order_selftest, pool_selftest) that run on
every invocation, --anchors included, so the fast suite measures them.
Four sabotages each turn a selftest red.

<linhas de atribuição do system reminder>
EOF
```

---

### Task 3: a carona do `TODO.md`, o spec e o `CLAUDE.md`

**Files:**
- Modify: `TODO.md` — apaga o item do #144 (`RESOLVED by b874141`, já na `main`) e corrige
  `:198-221` para `:224-248`.
- Modify: `tests/health-baseline.txt` — `todo-findings 83` → `82`.
- Modify: `docs/superpowers/specs/2026-09-25-o-sensor-para-no-primeiro-fail-design.md` — o
  `check-templates.sh` entra nas exceções declaradas (§3.2 e §4).
- Modify: `CLAUDE.md` — a regra "o sensor para no primeiro FAIL".

**Interfaces:** nenhuma.

- [ ] **Step 1: Confira a premissa da carona.**

Run: `git merge-base --is-ancestor b874141 main && echo in-main; grep -n 'RESOLVED by b874141' TODO.md; grep -n ':198-221' TODO.md; grep -nE '^\[ -n "\$\{SDD_MUTANT:-\}" \] \|\| run' tests/run-all.sh | cut -c1-60`
Expected: `in-main`; uma linha do item "Sensor novo na suíte é multiplicador"; uma linha com
`:198-221`; os quatro `run` protegidos nas linhas 224, 233, 240 e 247 (o último continua na 248).

- [ ] **Step 2: Aplique.**

```bash
python3 - <<'EOF'
import pathlib, re
p = pathlib.Path("TODO.md"); s = p.read_text()
start = s.index("- [ ] **Sensor novo na suíte é multiplicador, não parcela")
end = s.index("\n\n", start) + 2
block = s[start:end]
assert "RESOLVED by b874141" in block and block.count("- [ ]") == 1, block
s = s[:start] + s[end:]
assert s.count("`:198-221`") == 1
s = s.replace("`:198-221`", "`:224-248`")
p.write_text(s)
b = pathlib.Path("tests/health-baseline.txt"); t = b.read_text()
assert "\ntodo-findings 83\n" in t
b.write_text(t.replace("\ntodo-findings 83\n", "\ntodo-findings 82\n"))
sp = pathlib.Path("docs/superpowers/specs/2026-09-25-o-sensor-para-no-primeiro-fail-design.md"); u = sp.read_text()
o1 = "- **Exceção declarada, com o motivo no comentário:** `check-entrypoint.sh` (1 morte, 0,5 s, sem\n  `fail()`)."
assert u.count(o1) == 1
u = u.replace(o1, "- **Exceções declaradas, com o motivo no comentário:** `check-entrypoint.sh` (1 morte, 0,5 s)\n  e `check-templates.sh` (0 mortes, 0,5 s); os dois rodam dentro de mutante sem um ponto único de\n  falha.")
o2 = "- **`check-entrypoint.sh`** fica sem a cláusula (1 morte, 0,5 s)."
assert u.count(o2) == 1
u = u.replace(o2, "- **`check-entrypoint.sh` e `check-templates.sh`** ficam sem a cláusula (1 e 0 mortes, 0,5 s\n  cada).")
sp.write_text(u)
c = pathlib.Path("CLAUDE.md"); v = c.read_text()
m = re.search(r"40 de 40 pegos antes\s+e depois\.", v)
assert m, "CLAUDE.md anchor"
v = v[:m.end()] + " Desde 2026-09-25 o **sensor** também para no\nprimeiro `fail()` sob `SDD_MUTANT` (nove sensores; o censo do `check-health.sh` os segura)." + v[m.end():]
c.write_text(v)
print("ok")
EOF
```

Expected: `ok`.

- [ ] **Step 3: Rode os sensores que leem esses arquivos.**

Run: `tests/check-todo.sh > "$SP/t3-todo.out" 2>&1; echo "rc=$?"; tail -1 "$SP/t3-todo.out"; tests/check-health.sh > "$SP/t3-health.out" 2>&1; echo "rc=$?"; tests/check-lang.sh >/dev/null 2>&1; echo "lang rc=$?"`
Expected: `rc=0` e `ok    82 finding(s), all within 8 lines, carrying anchor + date, every anchor on target`;
`rc=0`; `lang rc=0`. O `check-health.sh` lê o `CLAUDE.md` (regra da política da catraca), então
ele verde prova que a edição não quebrou a política.

- [ ] **Step 4: Commit.**

```bash
git add TODO.md tests/health-baseline.txt CLAUDE.md docs/superpowers/specs/2026-09-25-o-sensor-para-no-primeiro-fail-design.md
git commit -F - <<'EOF'
chore(todo): #144 leaves the file, a stale range fixed, and the rule written down

The #144 item carried RESOLVED by b874141, merged with PR #168; it leaves
TODO.md here because this branch re-stamps anyway (ratchet 83 -> 82). The
SDD_MUTANT blind-spot item cited `:198-221` for the four guarded sensors,
which sit at 224-248. CLAUDE.md gains one sentence: the sensor too stops
at its first fail() under SDD_MUTANT. The spec declares check-templates.sh
beside check-entrypoint.sh: both run inside mutants with no single failure
primitive.

<linhas de atribuição do system reminder>
EOF
```

---

### Task 4: a medição diferencial, o controle sob carga e o coordination sem órfão

Nada é commitado nesta task: ela mede o que as Tasks 1–3 fizeram, e os números vão para o ledger
(e, na Entrega, para o `KAIZEN_LOG.md`).

**Files:** só scratchpad (`$SP/p2b/`).

**Interfaces:**
- Consumes: `sandbox` e `apply_mutant` do `check-mutation.sh`, carregados do trecho anterior ao
  modo `--anchors`; o formato de log da `run-all.sh`.
- Produces: `$SP/p2b/out-<n>/<slug>.tlog` e os números do ledger.

**Antes (medido em 2026-09-25, `8f2f2a9`, 12 jobs):** soma do passo assassino nos 24 mutantes =
**1328,7 s** (autonomy 846,4; gates 404,4; kaizen 28,2; preflight 49,7). Tempo até o 1º FAIL =
624,4 s. CONTROL rc 0.

- [ ] **Step 1: Grave a amostra fixa, o carimbador de tempo, o harness e a análise.**

```bash
mkdir -p "$SP/p2b"
printf '%s\n' \
'RUN_degraded_journal_dropped	autonomy ledger' \
'EXEC_cell_marker_never_armed	autonomy ledger' \
'RUN_moved_never_true	autonomy ledger' \
'BOOT_reason_dropped	autonomy ledger' \
'RUN_intervention_anywhere	autonomy ledger' \
'RUN_retry_pending_before_null	autonomy ledger' \
'RUN_ticket_blocked_not_armed	autonomy ledger' \
'LEDGER_repo_root_toplevel	autonomy ledger' \
'RUN_retry_photographs_every_phase	autonomy ledger' \
'RUN_mission_budget_fractional_disabled	autonomy ledger' \
'RUN_hat_close_door_missing	autonomy ledger' \
'AUTONOMY_progress_outranks_moved	autonomy ledger' \
'REVIEW_stops_at_h3	gate state machine' \
'QA_bug_genre_deferred_join	gate state machine' \
'CENSUS_boot_bill_lexicographic	gate state machine' \
'QA_bug_genre_ignored	gate state machine' \
'QA_hostport_keeps_fragment	gate state machine' \
'QA_bug_enum_loose	gate state machine' \
'RUN_branch_orphan_blind	gate state machine' \
'RUN_branch_option_name	gate state machine' \
'KAIZEN_guard_harness_blind	kaizen series and gate' \
'LEDGER_gate_pass_membership_not_position	kaizen series and gate' \
'PRE_node_sed_unescaped	preflight and the install guard' \
'ADR_preflight_skips_validation	preflight and the install guard' > "$SP/p2b/sample.tsv"
grep -c $'\t' "$SP/p2b/sample.tsv"   # expected: 24 (the separator is a real TAB)
printf '%s\n' \
'COORD_adr_cwd_admission	one checkout has one execution owner' \
'COORD_adr_external_spec	one checkout has one execution owner' > "$SP/p2b/extras.tsv"

cat > "$SP/p2b/ts.py" <<'EOF'
import sys, time
t0 = time.monotonic()
for line in sys.stdin.buffer:
    sys.stdout.buffer.write(b"%.2f " % (time.monotonic() - t0) + line)
    sys.stdout.flush()
EOF

cat > "$SP/p2b/harness.sh" <<'EOF'
#!/usr/bin/env bash
# P2(b) differential: where does the killing sensor end now? Throwaway. Usage: harness.sh <out-dir>
set -uo pipefail
P2B="$(dirname "$(readlink -f "$0")")"
OUT="$1"; rm -rf "$OUT"; mkdir -p "$OUT"
awk '/^# --anchors: apply every mutant/ { exit } { print }' /home/joruge/repos/sdd_agents/tests/check-mutation.sh \
  | sed 's|^ROOT=.*|ROOT=/home/joruge/repos/sdd_agents|' > "$P2B/mutlib.sh"
source "$P2B/mutlib.sh"
one() {
  local slug=$1 killer=$2 box="$WORK/$1" arc=0
  sandbox "$box"
  if [ "$slug" != CONTROL ]; then apply_mutant "mut_$slug" "$box" || arc=$?; fi
  if [ "$arc" -ne 0 ]; then echo "APPLY $arc" > "$OUT/$slug.tlog"; return; fi
  SDD_MUTANT=1 SDD_MUTANT_FIRST="$killer" "$box/tests/run-all.sh" 2>&1 | python3 "$P2B/ts.py" > "$OUT/$slug.tlog"
  echo "RC ${PIPESTATUS[0]}" >> "$OUT/$slug.tlog"
}
{ printf 'CONTROL\t\n'; cat "$P2B/sample.tsv" "$P2B/extras.tsv"; } > "$P2B/queue.tsv"
while IFS=$'\t' read -r slug killer; do
  while [ "$(jobs -rp | wc -l)" -ge 12 ]; do wait -n; done
  one "$slug" "$killer" &
done < "$P2B/queue.tsv"
wait
echo "HARNESS DONE"
EOF
chmod +x "$SP/p2b/harness.sh"

cat > "$SP/p2b/analyze.py" <<'EOF'
import re, sys, pathlib
out = pathlib.Path(sys.argv[1])
sample = dict(l.rstrip('\n').split('\t') for l in open(sys.argv[2]))
extras = dict(l.rstrip('\n').split('\t') for l in open(sys.argv[3]))
HDR = re.compile(r'^(\d+\.\d+) \x1b\[1m▸ (.*)\x1b\[0m$')
FAILRE = re.compile(r'^(\d+\.\d+) \s*(FAIL|SENSOR-BROKEN)\b')
def parse(p):
    steps, cur, rc = [], None, None
    for raw in p.read_text(errors='replace').splitlines():
        if raw.startswith('RC '): rc = int(raw.split()[1]); continue
        m = HDR.match(raw)
        t = float(raw.split(' ', 1)[0]) if re.match(r'^\d+\.\d+ ', raw) else None
        if m:
            cur = {'name': m.group(2), 't0': float(m.group(1)), 't1': float(m.group(1)), 'first': None, 'nfail': 0}
            steps.append(cur); continue
        if cur and t is not None:
            cur['t1'] = t
            if FAILRE.match(raw):
                cur['nfail'] += 1
                if cur['first'] is None: cur['first'] = t
    return steps, rc
_, crc = parse(out / 'CONTROL.tlog')
print(f'CONTROL rc={crc}')
tot = 0.0; by = {}; bad = []
for group, table in (('sample', sample), ('extra', extras)):
    for slug, killer in table.items():
        steps, rc = parse(out / f'{slug}.tlog')
        ks = [s for s in steps if s['name'] == killer]
        if rc != 1 or not ks: bad.append((slug, rc, [s['name'] for s in steps])); continue
        dur = ks[0]['t1'] - ks[0]['t0']
        print(f'{group:6} {killer[:32]:32} {slug[:44]:44} rc={rc} dur={dur:6.1f} nFAIL={ks[0]["nfail"]}')
        if group == 'sample':
            tot += dur; by[killer] = by.get(killer, 0) + dur
for k, v in by.items(): print(f'  {k:32} {v:7.1f} s')
print(f'SAMPLE SUM {tot:.1f} s over {sum(1 for s in sample)} mutants (before: 1328.7 s)')
print('BAD', bad if bad else 'none')
EOF
```

Expected: `24` na checagem de TAB.

- [ ] **Step 2: Rode o harness três vezes, uma depois da outra.** Cada rodada leva uns 3 min.
  Confira antes que nada mais roda (`ps -eo pid,cmd | grep -E 'run-all|sdd-mu[t]-'`).

```bash
python3 "$SP/health-launch.py" "$SP/p2b/run1.log" /home/joruge/repos/sdd_agents bash "$SP/p2b/harness.sh" "$SP/p2b/out-1"
```

Espere o `RC=` com um poll em segundo plano, confira os órfãos e analise; depois repita com
`run2.log`/`out-2` e `run3.log`/`out-3`:

```bash
pgrep -af 'sdd-coordination|sdd-mu[t]-' | grep -v pgrep | wc -l
python3 "$SP/p2b/analyze.py" "$SP/p2b/out-1" "$SP/p2b/sample.tsv" "$SP/p2b/extras.tsv"
```

Expected, em **cada** rodada:
- `RC=0` no `runN.log`;
- `0` processos órfãos (Review Focus 4);
- `CONTROL rc=0` (Review Focus 2: o controle dentro de um pool de 12);
- `BAD none`: os 24 mais os 2 extras com rc 1, e o passo assassino rodando;
- `SAMPLE SUM` perto de 624 s e bem abaixo de 1328,7 s. Aceite até ~800 s: a carga varia entre
  rodadas.

Se `SAMPLE SUM` ficar acima de 1000 s, a cláusula não está agindo dentro do mutante. Confira o
`nFAIL`: com a cláusula ele é **1** em todo mutante. Em 2026-09-25, sem ela, chegou a 61.

- [ ] **Step 3: Registre no ledger** a linha
  `Task 4: SAMPLE SUM r1=<a> r2=<b> r3=<c> s (antes 1328,7); CONTROL rc 0 ×3; órfãos 0 ×3; nFAIL=1 em todos`.

---

## Entrega (depois da revisão final do executing-plans)

A revisão final do branch inteiro, por um revisor novo, vem **antes** desta seção: ela pode pedir
conserto em `tests/`, e cada conserto invalida o carimbo. Depois dela:

- [ ] **E1. Empurre e abra o PR.** `git push -u origin perf/sensor-para-no-primeiro-fail`, depois
  `gh pr create --base main` com título `perf: the sensor stops at its first FAIL — health under 20 min (P2(b))`
  e um corpo com:
  - resumo;
  - a tabela da amostra, antes e depois;
  - o que o censo prova;
  - as sabotagens;
  - `Refs` para a gaveta;
  - um test plan com `- [ ] sdd health twice (1st records the times, 2nd measures and stamps)`;
  - o rodapé de atribuição do system reminder.
- [ ] **E2. Espere todos os revisores:** CodeRabbit, Codex (comente `@codex review` no PR se ele
  não vier sozinho) e Copilot, que pode estar sem cota. Conserte numa leva só, com
  `/codereview:coderabbit_pr`. Cada conserto em `tests/` roda de novo a suíte rápida e o censo.
- [ ] **E3. Health nº 1** (grava os tempos; mede o P2(b) e o controle em paralelo, ainda na ordem
  do catálogo), pelo lançador:
  `python3 "$SP/health-launch.py" "$SP/health1.log" /home/joruge/repos/sdd_agents ./bin/sdd health`.
  Espere o `RC=`. Expected: `mutation: score: 406 caught, 0 known gap(s), of 406`, `kit healthy`,
  `RC=0`. Anote START e END. Confira `awk -F'\t' 'NF==3' .sdd/cache/mutation-killers.tsv | wc -l`
  → 406.
- [ ] **E4. Health nº 2** (mede tudo junto, com o mais longo primeiro, e carimba), pelo mesmo
  caminho, em `$SP/health2.log`. Expected: 406 de 406, `kit healthy`, `mutation stamp written`,
  **≤ 20 min**; depois `"$SP/stamp-check.sh"` → `STAMP VALID`.
- [ ] **E5. Números no `KAIZEN_LOG.md`, na gaveta e no spec**, que ficam fora da chave do carimbo:
  - no `KAIZEN_LOG.md`, uma entrada nova no topo, `## 2026-09-25 — O sensor para no primeiro FAIL`,
    no formato das vizinhas (Problema / Medição com tabela antes-depois / Contramedida / Limite
    declarado). Números: a amostra (1328,7 s → as três somas da Task 4), o health (37 min 42 s →
    nº 1 → nº 2) e o controle ×3 verde;
  - na gaveta, a linha da F1 e o item (b) passam a `FEITO`, com o número do health nº 2;
  - no topo do spec, uma linha `> **FEITO** em <data>: health <nº 2>`.
  Commit `docs(kaizen): …`, depois `"$SP/stamp-check.sh"` → `STAMP VALID`, depois push.
- [ ] **E6. Peça o merge ao humano.** Depois do merge, com o ok dele:
  - ressincronize o espelho de issues com a skill `todo-to-github-issues`. A issue #144 fica órfã:
    feche-a como `completed`, citando `b874141`. O plano precisa voltar `create=0 update=0`;
  - apague o branch.

---

## Anexo A — o texto atual da região do controle e do pool no `check-mutation.sh`

É o `old_string` do Task 2, Step 6 (em `8f2f2a9` e em `95e356a`, linhas 4743–4791):

```bash
# ---------------------------------------------------------------------------
# CONTROL run — the copy has to be green with NO sabotage at all.
#
# Without it, a broken copy (a future test reading agents/ or docs/, for instance) would leave
# EVERY mutant red and the score would read 100% while measuring exactly nothing — the same
# vacuity the mutation exists to catch, now inside the measuring device itself.
# ---------------------------------------------------------------------------
echo "== control =="
sandbox "$WORK/control"
if SDD_MUTANT=1 "$WORK/control/tests/run-all.sh" > "$WORK/control.log" 2>&1; then
  pass "the kit copy is green with no sabotage"
else
  fail "HARNESS-BROKEN: the copy is not green even without sabotage" \
       "the score would read 100% by vacuity — see $WORK/control.log"
  tail -20 "$WORK/control.log" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# A pool, not batches: the old `[ i % JOBS -eq 0 ] && wait` was a barrier every JOBS mutants, so
# each batch cost its slowest member while the finished slots sat idle. `wait -n` frees a slot as
# soon as ANY mutant exits. Safe because run_mutant shares nothing — each writes its own
# $WORK/<slug>.rc/.log and the scoring loop below reads the catalogue in order afterwards.
# `wait -n` is bash 4.3+; without it, fall back to the barrier and SAY so — a declared
# degradation, never a silent one.
if [ -r "$KILLERS_FILE" ]; then
  while IFS=$'\t' read -r k v; do
    [ -n "$k" ] && [ -n "$v" ] && KILLER["$k"]="$v"
  done < "$KILLERS_FILE"
fi
echo "== killer map: ${#KILLER[@]} mutant(s) run their last killer first =="

if (: & wait -n) 2>/dev/null; then
  echo "== mutants (pool of $JOBS) =="
  running=0
  for slug in "${CATALOG[@]}"; do
    run_mutant "$slug" &
    running=$((running + 1))
    if [ "$running" -ge "$JOBS" ]; then wait -n; running=$((running - 1)); fi
  done
else
  echo "== mutants (batches of $JOBS — this bash has no 'wait -n', falling back to barriers) =="
  i=0
  for slug in "${CATALOG[@]}"; do
    run_mutant "$slug" &
    i=$((i + 1))
    [ $((i % JOBS)) -eq 0 ] && wait
  done
fi
wait
```

O comentário do pool ("A pool, not batches: …") não se perde: ele volta, atualizado, dentro do
texto de substituição do Step 6, entre o `mapfile` e o `if (: & wait -n)`.
