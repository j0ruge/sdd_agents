# Notas de execução — a rota da QA

> **Append-only.** Uma linha por evento; nunca reescreva o arquivo, nunca o releia inteiro.
>
> Este arquivo nasceu em `20260904-a-dieta-de-contexto`, separado do `checkpoint.md` por medição:
> as notas eram **69% daquele arquivo** (67 166 B de 97 865 B em `20260901-o-revisor-so-acha`), e
> aquele arquivo era **44,7% de tudo que a missão releu** — 160 leituras, 1 114 571 B. Enquanto
> tabela e notas dividiam o arquivo havia um piso mecânico: em sessão headless o `Edit` exige um
> `Read` prévio, então toda sessão que atualizasse a tabela pagava o arquivo inteiro. Separadas,
> escrever nota é `>>` e custa **zero leitura**.
>
> O prompt de boot **inlina as últimas 10 notas** (`BOOT_NOTES_TAIL` no `bin/sdd`) e manda
> explicitamente **não abrir este arquivo**. Se você precisa de uma nota mais antiga, ela é
> história — e história se lê no `git log`, não no boot de toda sessão.

## Notas de execução

> Uma linha por evento relevante: bloqueio, decisão tomada, desvio do plano com justificativa.
> É o que a próxima sessão lê para não repetir um erro que já custou caro.

- 2026-10-12 20:05 · `—` · plano nascido do `sdd kaizen` (veredito `melhorou` sobre `0270727`, `05-verdict.md`); `aprovacao:` vazio por regra; o I1 é do humano

> **Toda vez que um humano precisou entrar na linha** — um `sdd retry`, um conserto à mão, um
> `BLOCKED` assumido — sai uma linha com o marcador `intervention:`. É a **narrativa** do que o
> humano fez. O **número** de intervenções o `sdd autonomy --by-mission` lê do ledger, em
> `launch(es)` (`run_id` distintos — cada `sdd run`/`sdd retry`), e imprime estas notas ao lado
> como `intervention note(s)`.
>
> ⚠️ O marcador é **inglês e minúsculo**, como `pending`/`done`/`blocked`: é contrato, não prosa.
> Só conta quando abre a linha — `intervention` no meio de uma frase é prosa e não é contado.
>
> - intervention: <o que o humano teve de fazer> — <fase> — <custo, se houver>
- 2026-10-12 20:53 · `—` · plano replanejado com o humano (grill de 10 perguntas, D1–D10, todas `(recommended)`): 11 incrementos; ADR 0018 alocada por `./bin/sdd adr new` e escrita; o (e) foi ao `TODO.md` (catraca 2 → 3); a correção do I10 medida (o `RESOLVED by` no fim da linha `Fonte:` reprova no `check-todo.sh`); os tokens da D8 viraram inglês por causa do `check-lang.sh`
- 2026-10-12 21:14 · `—` · teste de autocontenção real do I1 (subagente novo, clone descartável, 21:01–21:12): Check `1 1`, mutantes pegos; três lacunas escritas no plano (`--only` com o nome nu do sensor; formato e commit da nota; o I1 já move a âncora `bin/sdd:1800` do `TODO.md` em 2 linhas); clone apagado
