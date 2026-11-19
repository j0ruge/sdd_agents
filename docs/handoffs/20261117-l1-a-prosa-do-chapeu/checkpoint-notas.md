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
