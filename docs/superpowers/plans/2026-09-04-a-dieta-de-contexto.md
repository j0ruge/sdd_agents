# Plano — a dieta de contexto (2026-09-04)

> Spec: [`../specs/2026-09-04-a-dieta-de-contexto-design.md`](../specs/2026-09-04-a-dieta-de-contexto-design.md).
> Branch `feat/a-dieta-de-contexto` a partir de `main` = `314de35`.
> **Alvo (não se move): `boot bill` ≤ 105 000 B no pior ponto.** Antes: 214 222 B. **Depois: 102 016 B ✓** (−52,4%).
> Cada Check é escrito **antes** do incremento. TDD da casa: probe antes, mutante depois.

| ID | Estado | Incremento |
|---|---|---|
| I1 | ✅ `7eac87e` | censo por arquivo, `boot bill`, `cache_read` no ledger |
| I1b | ✅ `5b6d6ca` | `boot bill` no pior ponto |
| I5 | ✅ `8ecf2a1` | a frase dos subagentes sai; `Agent` no deny do executor |
| I2 | ✅ `e68be5f` | notas fora do `checkpoint.md`; `BOOT_NOTES_TAIL=10`; boot inlina as últimas 10 |
| I3 | ✅ `38f3b17` | boot nomeia o handoff e inlina TL;DR (teto 20 linhas, no gate) + Boot da próxima fase |
| I3b | ✅ `56cb6de` | boot nomeia o template da FASE em vez do diretório |
| I4 | ✅ `7902ee5` | linha de sensor no `sdd preflight` (bytes do `CLAUDE.md` + rules do alvo) |
| I6 | 🔄 docs ✅, health/PR | `sdd boot`; probes; docs, kaizen, carimbo, PR |

---

## I5 — a frase dos subagentes sai do executor

**Por quê.** Censo: `Agent=0` em 27 sessões de EXEC de duas missões. A frase manda usar subagentes
e ninguém usou; `Agent` está fora do `HAT_DENY_BASE` só por causa dela.

**Check (antes).**
```
grep -c 'subagents' agents/sdd-executor.md              → 0
grep -A2 'disallowedTools:' agents/sdd-executor.md      → contém Agent
bash tests/check-hat.sh                                  → verde
```
**Sensor.** `check-hat.sh` (o chapéu declara a fronteira). **Mutante.** `HAT_executor_allows_agent`.
⚠️ Mexe em `agents/*.md` ⇒ espelho do `sales_quote` stale ⇒ PR de espelho lá (`sdd install --force`).

## I2 — as notas saem do checkpoint

**Por quê.** 67 166 B dos 97 865 B do `checkpoint.md` (69%) são a seção de notas, e no headless
`Edit` exige `Read`: enquanto tabela e notas dividem o arquivo, existe um piso de uma releitura
inteira por sessão que nenhuma instrução remove.

**Check (antes).**
```
fixture com 30 notas → o prompt de boot contém exatamente as 10 últimas e NÃO a 1ª
sdd autonomy --by-mission lê `intervention` do arquivo novo E da seção antiga (dois mundos)
sdd census <missão> → o checkpoint.md do boot bill cai para <= 35 000 B
```
**Sensores.** `check-checkpoint.sh`, `check-templates.sh`, `check-dry-run.sh`, `check-autonomy.sh`.
**Mutantes.** um por porta: writer da `- intervention:`, leitor do `sdd autonomy`, o `tail`.
⚠️ Antes de fechar: `grep -rn 'Notas de execução\|checkpoint.md' agents/ docs/ templates/ README.md bin/sdd tests/`
— o contrato do laço REVIEW⇄EXEC já morou em SETE lugares.

## I3 — o boot nomeia o handoff e inlina só duas seções

**Check (antes).**
```
fixture com 20- e 40-r2 → o prompt cita 40-review-r2.md e contém o TL;DR dele
TL;DR de 21 linhas → o gate da fase reprova, com o motivo em stderr
```
**Sensor.** `check-gates.sh`. **Mutante.** `GATE_tldr_uncapped`.

## I3b — o boot nomeia o template da fase

**Check (antes).**
```
sdd boot <missão> EXEC   → cita templates/checkpoint.md e NÃO cita templates/review.md
sdd census <missão>      → o termo templates do boot bill cai de 20 957 para <= 9 012 B
```
**Sensor.** `check-hat.sh` / `check-dry-run.sh`. **Mutante.** `BOOT_templates_whole_dir`.

## I4 — sensor do CLAUDE.md do alvo no preflight

**Check (antes).**
```
sdd preflight (com env -u CLAUDECODE …) → `  ok    context bill: N file(s), M bytes` ; NUNCA fail
```
**Sensor.** `check-preflight.sh`. **Mutante.** `PREFLIGHT_context_bill_silent`.

## I6 — sdd boot, probes e o fecho

**Check (antes).**
```
sdd boot <missão> EXEC | wc -c    → prompt curto, contendo as 10 notas e o TL;DR
tests/run-all.sh                   → suite green
tests/check-todo.sh --check TODO.md e tail -1 tests/health-baseline.txt → o MESMO número
./bin/sdd health                   → carimbo (SÓ depois do último commit de código)
./bin/sdd health --release         → segue 2 de 6
```
Fecho: rule 3, `CONTEXT.md` (verbete + D24 + as duas pendências mudam de dono),
`docs/pipeline.md:606-619`, `KAIZEN_LOG.md`, `TODO.md:42-46` `RESOLVIDO`.

---

## Ordem e armadilhas

I1 ✅ → I1b ✅ → **I5** → **I2** → **I3** → **I3b** → **I4** → **I6**.

- **Carimbo:** chave = `bin/ tests/ templates/ config/`; `tests/health-baseline.txt` invalida.
  Ordem: código → achados → `health` → PR.
- **Captura sob `set -e`**, `printf | grep -q` (141), `cd` relativo em `$( )` sem `CDPATH=''`,
  `mawk` byte-oriented, `${!k}` não existe no zsh do Bash tool.
- **Probe de sabotagem prova primeiro que sabotou**; ancore em código, morra alto.
- **`agents/*.md` ⇒ `sdd install --force`**, nunca `cp`.
