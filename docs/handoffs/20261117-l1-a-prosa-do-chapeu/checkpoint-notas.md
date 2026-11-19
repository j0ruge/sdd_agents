# Notas de execução — L1: a prosa do chapéu e dos docs

> **Append-only.** Uma linha por evento; nunca reescreva o arquivo, nunca o releia inteiro.
>
> O prompt de boot **inlina as últimas 10 notas** (`BOOT_NOTES_TAIL` no `bin/sdd`) e manda
> explicitamente **não abrir este arquivo**. Se você precisa de uma nota mais antiga, ela é
> história — e história se lê no `git log`, não no boot de toda sessão.

## Notas de execução

> Uma linha por evento relevante: bloqueio, decisão tomada, desvio do plano com justificativa.
> É o que a próxima sessão lê para não repetir um erro que já custou caro.
>
> Toda vez que um humano precisou entrar na linha sai uma linha com o marcador em inglês e
> minúsculo, abrindo a linha, fora desta citação. A forma:
>
> - intervention: <o que o humano teve de fazer> — <fase> — <custo, se houver>

- 2026-11-17 18:42 · `PLAN` · plano escrito sobre `7ea43e3`; a `main` já estava em `380ffb0` (PR 412, catraca 85). Antes do `sdd run`: `git fetch origin && git merge origin/main` por quem lança a corrida (pendência 1 do `00-missao.md`).
- 2026-11-17 18:42 · `PLAN` · espelho de chapéu só por `./bin/sdd install --force`, com o `./`; se responder `CHECKOUT-BUSY`, anote o comando e a saída aqui, marque `blocked` e pare.
- 2026-11-19 16:21 · `I1` · I1 red: hat: the planner names the base branch by DEFAULT_BRANCH of the target, never by the literal main → FAIL antes da prosa (junto, o K8 de hat_promise_probes ficou vermelho pelo literal trocado, como o plano previa)
- 2026-11-19 16:21 · `I1` · I1 red: hat: the planner writes every hand-back to the relay in OUTPUT_LANG → FAIL antes da prosa
- 2026-11-19 16:21 · `I1` · I1 red: hat: a planner Check for a new TODO_FILE item also accepts a RECURRED entry on an equivalent open item → FAIL antes da prosa
- 2026-11-19 16:21 · `I1` · `./bin/sdd install --force` dentro da corrida respondeu `ok   agent sdd-planner.md updated (--force)`, rc 0, sem CHECKOUT-BUSY; âncoras 103 medidas, 0 fora do alvo; suíte verde antes e depois
- 2026-11-19 16:32 · `I2` · I2 red: hat: the executor writes 20-handoff-exec.md in the increment that leaves no row pending, and its answer says whether it did → FAIL antes da prosa
- 2026-11-19 16:32 · `I2` · I2 red: hat: the executor restores a mutant with cp and rm, so an incremental build sees a new mtime → FAIL antes da prosa (junto, a asserção das sobras ficou vermelha pelo literal trocado, como o plano previa)
- 2026-11-19 16:32 · `I2` · desvio do plano: a frase do item D não diz "subagente de um relay" e sim "another session's relay", porque executor_agent_probes proíbe a palavra subagent no chapéu (o Agent é negado); install --force respondeu `updated`, sem CHECKOUT-BUSY; suíte verde
- 2026-11-19 17:03 · `I3` · I3 red: hat: the reviewer waits for a slow command in the foreground, under a ceiling below the Bash limit → FAIL antes da prosa
- 2026-11-19 17:03 · `I3` · I3 red: hat: the reviewer writes a probe outside the repo by heredoc, and a test filter that matches nothing is a failure → FAIL antes da prosa
- 2026-11-19 17:03 · `I3` · install --force respondeu `updated`, sem CHECKOUT-BUSY; a 1ª suíte saiu vermelha só no check-health (sensor sozinho, check-hat rc 1) porque editei as asserções Red com ela em curso; refeita depois da prosa: suite green, 0 FAIL
- 2026-11-19 17:30 · `I4` · I4 red: hat: the docs phase turns a lesson its own log calls recurrent into a proposed rule, or writes why not → FAIL antes da prosa
- 2026-11-19 17:30 · `I4` · install --force respondeu `updated`, sem CHECKOUT-BUSY; âncoras 103 medidas, 0 fora do alvo; suíte verde antes (14m54s) e depois, 0 FAIL
- 2026-11-19 18:05 · `I5` · I5 red: hat: the qa hat sends a declared qa: skipped to the confirmation of section 2 on both paths → FAIL antes da prosa
- 2026-11-19 18:05 · `I5` · install --force respondeu `updated`, sem CHECKOUT-BUSY; âncoras 103 medidas, 0 fora do alvo; suíte verde antes e depois, 0 FAIL
- 2026-11-19 18:41 · `I6` · I6 red: doc: the README shows the clone line without calling the repository private → FAIL antes da prosa
- 2026-11-19 18:41 · `I6` · I6 red: doc: failure-modes.md finds a detached sdd run without matching the watcher, and says how to wait for its end → FAIL antes da prosa
- 2026-11-19 18:41 · `I6` · I6 red: doc: the finding-PR recipe merges only with zero unresolved review threads on the head, with the command beside it → FAIL antes da prosa
- 2026-11-19 18:41 · `I6` · âncoras J e K re-apontadas (`git clone`, `[b]in/sdd run`): 103 medidas, 0 fora do alvo; suíte verde antes e depois, 0 FAIL (a 1ª depois foi cortada pelo teto de 590 s do comando, e refeita destacada)
- 2026-11-19 18:53 · `I7` · I7 red: todo.md e todo.pt-BR.md: a number that changes goes in the body, never in the title → FAIL antes da prosa
- 2026-11-19 18:53 · `I7` · esqueleto das duas sementes intacto e 0 achados de forma; âncoras 103 medidas, 0 fora do alvo; suíte verde depois, 0 FAIL
- 2026-11-19 19:06 · `I8` · I8 red: help: the sdd why entry of sdd help does not say that its gate runs TEST_CMD for EXEC, QA or REVIEW → FAIL antes da prosa (e de novo com o literal partido na quebra de linha, refeito numa linha só)
- 2026-11-19 19:06 · `I8` · âncoras de bin/sdd re-apontadas no TODO.md (12436→12448, 12471→12474, 12729→12732 ×2, 12361→12370): 103 medidas, 0 fora do alvo; suíte verde depois, 0 FAIL, 904 mutantes aplicáveis
- 2026-11-19 19:31 · `I9` · I9 red: Check → 0 antes; 14 depois; 4 linhas requebradas (120 col) e o item F mantido em 8 linhas; check-todo --check rc 0, --anchors 103 medidas, 0 fora do alvo; suíte verde (destacada, rc 0, 0 FAIL); 20-handoff-exec.md em c8251cc
