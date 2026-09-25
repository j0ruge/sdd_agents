# Notas de execução — o sensor lê o que a âncora diz

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

- 2026-09-25 01:10 · `PLAN` · plano escrito pelo `sdd-planner`, com o grill respondido pelo humano via sessão coordenadora; ADR 0011 alocada por `sdd adr new` e escrita em inglês, porque o `check-lang.sh` varre `docs/adr/`; `aprovacao:` vazia, à espera de `sdd approve`.

> **Toda vez que um humano precisou entrar na linha** — um `sdd retry`, um conserto à mão, um
> `BLOCKED` assumido — sai uma linha com o marcador `intervention:`. É a **narrativa** do que o
> humano fez. O **número** de intervenções o `sdd autonomy --by-mission` lê do ledger, em
> `launch(es)` (`run_id` distintos — cada `sdd run`/`sdd retry`), e imprime estas notas ao lado
> como `intervention note(s)`. Medido em 2026-08-28: a missão de três lançamentos tinha zero
> notas — o contador não pode depender de alguém lembrar de escrever; a narrativa, sim, e é a
> única fonte que diz o que o humano *fez*.
>
> ⚠️ O marcador é **inglês e minúsculo**, como `pending`/`done`/`blocked`: é contrato, não prosa.
> O texto depois dos dois-pontos vai no idioma do `OUTPUT_LANG`, como o resto deste arquivo.
> Só conta quando abre a linha — `intervention` no meio de uma frase é prosa e não é contado.
>
> Desde 2026-09-03 o **runner escreve a linha sozinho** quando é ele quem recebe a mão do humano —
> `sdd run --phase X`, `sdd retry`, `--budget-override` — e a commita sozinha, na hora, para a
> árvore chegar limpa ao gate da fase seguinte. A linha escrita à mão continua valendo para o que
> o runner não vê: conserto manual, fase feita à mão, `BLOCKED` assumido. `sdd approve` não
> escreve nenhuma: aprovar o plano é o gate humano desenhado, não uma entrada na linha. A nota
> diz o que o runner **sabe** ("forçada pela CLI"), nunca quem estava na CLI: outro agente com
> shell entra pela mesma porta, e o runner não distingue — medido em 2026-09-03.
>
> O exemplo abaixo mora **dentro** desta citação de propósito: o `>` quebra o casamento com
> `^[[:space:]]*-`, e sem ele o exemplo era contado verbatim — todo checkpoint recém-instanciado
> nascia devendo uma intervenção fantasma ao instrumento que mede autonomia. Copie a forma para
> fora da citação ao registrar uma intervenção de verdade.
>
> - intervention: <o que o humano teve de fazer> — <fase> — <custo, se houver>
- 2026-09-25 01:03 · `EXEC` · I1 `7bf0773`: regra de largura (120 caracteres) no awk do lint; sabotagens medidas no scratch, todas vermelhas no selftest: contar bytes (`length($0)`) → rc 91; `WIDTH_CAP=1200` → rc 91; só a primeira linha do item → rc 91. O caractere acentuado do probe sai por escape de bytes (`$'\xc3\xbc'`), porque o `check-lang.sh` lê letra acentuada no fonte como português.
- 2026-09-25 01:09 · `EXEC` · I2 `b517d10`: as 5 sabotagens do #70, cada uma numa cópia no scratch com `cmp -s` provando a mutação: (a) contagem → `3` rc 92; (c) `flush(); next` → `next` rc 92; (d) `${2:-$TODO}` rc 92, **também sem** `TODO.md` ao lado; b1 sem `^` rc 92; b2 sem `[[:space:]]*$` rc 92. Desvio do plano: o probe (d) aponta `SDD_TODO_FILE` para um arquivo **saudável**, porque com caminho inexistente o íntegro e o mutante respondem os dois 93.
- 2026-09-25 01:19 · `EXEC` · I3 `932a1ba`: `config_read_key` nos 7 sítios; o `health --release` não tinha ramo de erro no plano e ganhou um (linha 5 vermelha), porque palavras proibidas não lidas certificavam a superfície limpa — fail-open. `CAPTURE_FLOOR` 36 → 37 (a 2b captura diagnóstico e valor). Mutante `mut_HEALTH_config_parse_blind` aplicado numa cópia do repo: só a asserção nova reprova.
- 2026-09-25 01:29 · `EXEC` · I4 `2b5f492`: `test_cmd_lists_only` no health 2b e no preflight. O `mut_PRE_testcmd_noop_blind` **não** quebrou (a chamada `if test_cmd_looks_noop` do preflight ficou igual); só o `mut_HEALTH_testcmd_list_blind` foi re-ancorado. Dois mutantes novos em vez de um (`_unnormalised`, `_unquoted`), um por metade; cada um aplicado numa cópia do repo e pego pelas duas asserções novas.
- 2026-09-25 01:37 · `EXEC` · I5 `bc624f9`: `test_cmd_missing_manifest` (uma tabela) + ramo `warn` no preflight. O risco do plano sobre o fixture compartilhado (greenfield) não se materializou: nenhuma asserção lia o `fail` antigo; sensor inteiro verde sem ajuste. Mutante `mut_PRE_greenfield_warn_always` pego pelo probe (2).
