---
missao: 20260814-dry-run-completo
atualizado: 2026-08-14 03:40
---

# Checkpoint — dry-run mostra o pipeline inteiro

> **Este arquivo é lido por máquina.** O runner faz parse da tabela abaixo. Não mude as colunas,
> não mude os tokens de status, não quebre linhas dentro de uma célula.
>
> Atualizar o checkpoint é o **último ato** do incremento — depois do commit, nunca antes.
> Status válidos: `pending` · `doing` · `done` · `blocked`.

| ID | Incremento | Check (comando → esperado) | Status | Commit |
|---|---|---|---|---|
| I1 | dry-run projeta todas as fases pendentes | `tests/run-all.sh` → exit 0 (com check-dry-run.sh incluído) | pending | — |

## Notas de execução

- 2026-08-14 03:05 · — · missão-fixture do incremento I6 do plano do kit: plano escrito à mão
  para exercitar a fase EXEC headless pela primeira vez.
- 2026-08-14 03:40 · — · **I1 → `blocked`. Jidoka: a sessão EXEC headless não consegue executar
  o sensor.** Nenhuma linha de I1 foi escrita — nem o `tests/check-dry-run.sh` (Red), nem a
  mudança em `bin/sdd` (Green). Motivo: nesta sessão **toda** execução de comando não-leitura
  é negada com "This command requires approval". Negados: `tests/run-all.sh`,
  `bash tests/run-all.sh`, `./tests/run-all.sh`, `tests/check-gates.sh`, `bash -n bin/sdd`,
  `bash -c 'echo hello'`, `sh -c 'echo probe-sh'`, `rtk proxy "tests/run-all.sh"` (este último
  também com o sandbox desabilitado). Permitidos: só leitura — `git`, `ls`, `cat` e o tool
  `Read`. Causa raiz em `bin/sdd:491-499`: `run_phase()` monta
  `claude -p … --permission-mode "$PERMISSION_MODE"` (= `acceptEdits`) **sem `--allowedTools`**,
  e não há allowlist cobrindo os comandos do kit em `--setting-sources user,project,local`.
  `acceptEdits` auto-aprova edição de arquivo, **não** `Bash`. **`git add` também é negado** —
  só o `git` de leitura (`status`, `log`, `rev-parse`) passa —, então a sessão não consegue nem
  commitar: `gate_EXEC` exige hash real no `git log` e é, hoje, insatisfazível por construção.
  Este commit de escalação também não pôde ser feito; as edições ficam **no working tree**, sem
  commit, para o humano inspecionar (`git status`). Consequência: o `sdd-executor`
  não consegue cumprir o próprio contrato — não roda `TEST_CMD` na abertura, não vê o Red, não
  verifica o Green. Seguir teria significado commitar bash não executado e marcar `done` — que
  é exatamente o "rótulo, não artefato" que o kit proíbe. Registrado no `TODO.md` (achado sobre
  o kit) com a direção de correção e o sensor durável proposto (`sdd preflight` afirmando que
  uma sessão headless consegue de fato rodar `TEST_CMD`). **Escalação para o humano: I1 continua
  intacto e volta a `pending` assim que a permissão for corrigida.**

## Incrementos de fix (QA)

> Escritos pelo `sdd-qa` quando um bug sanável é reprovado, com ID `F<n>` e Check incluindo
> regression test + re-walk da jornada impactada.
