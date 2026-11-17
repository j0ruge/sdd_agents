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
