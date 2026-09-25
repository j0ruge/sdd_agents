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
- 2026-09-25 01:43 · `EXEC` · I6 `eb0ee9e`: ao subir o `CALIBRATE_FLOOR` para 9 o primeiro vermelho foi dos probes do próprio `calibrate()` (árvores de 4 sensores falsos ficaram "finas"); as árvores passaram a ter `seq 1 $CALIBRATE_FLOOR` sensores, e só então apareceu o RED esperado `only 8`. Sabotagem `pass()` com 3 espaços → `disagree about the ok prefix`, rc 1.
- 2026-09-25 01:51 · `EXEC` · I7 `fb6fb78`: `--anchors` sobre o `TODO.md` hoje: 100 medidos, **69** fora (49 C, 15 A, 5 B); só `bin/sdd`: 41 medidos, 32 fora (a auditoria do plano achou 63 erradas entre as 85 `arquivo:N`). Sabotagens, todas vermelhas no selftest (rc 91): base `$ROOT`; alcance 1000; mínimo 1; glob expandido (vira B em vez de A — a mensagem pega); pular A; última crase de caminho em vez da primeira.
- 2026-09-25 01:59 · `EXEC` · I8 `f43788f`: Red inicial `--anchors TODO.md bin/sdd` = 41 medidos, 32 fora; depois 34 medidos, 0 fora. Cada linha nova foi lida no código, não copiada do `nearest` (vários eram ruído: `sdd run`, `CLAUDE.md`, `else`).
- 2026-09-25 01:59 · `EXEC` · I8 conteúdo velho: `sdd approve` diz next com gate fechado → o código repergunta o `gate_PLAN` desde `a26f941`; item apagado.
- 2026-09-25 01:59 · `EXEC` · I8 conteúdo velho: releitura pós-checkout só confere `branch:` → compara hash de `00-missao.md`/`01-plano.md` desde `7b0c2df`; apagado.
- 2026-09-25 01:59 · `EXEC` · I8 conteúdo velho: fase corrente só no stdout → linha `PHASE <X> reason=` no journal desde `3245bfd`; apagado. Memo do `run_check_cmd` com zero acertos no `sdd run` → `derive_phase` chamado, não `$( )`, mesmo `3245bfd`; apagado.
- 2026-09-25 01:59 · `EXEC` · I8 conteúdo velho: `run_phase` não limpa env do harness → `HARNESS_ENV_UNSET` desde `bcfe27c`; apagado. Contabilidade do `sdd autonomy` não fecha → dois parágrafos desde `a035f25`; apagado.
- 2026-09-25 01:59 · `EXEC` · I8 refutado: preflight não provaria execução headless → o probe roda `bash -c 'echo sdd-preflight-ok'` sob as flags do `run_phase` desde `2083680`; virou registro decidido. Catraca 100 → 93 no mesmo diff. `review_scope_check` (`:547`) não caiu no `bin/sdd`: a âncora dele não é `bin/sdd`, fica para o I9.
- 2026-09-25 02:05 · `EXEC` · I8 (2ª volta) `9a123fa` + `19806c5`: a regra tomava a 1ª crase de caminho da cabeça **com o título**; título com `.sdd/config.sh` ou `bin/sdd` virava âncora de arquivo inteiro e escondia a real (fail-open). Conserto: a âncora é buscada depois do título (as crases do título seguem símbolo); 2 probes + 2 sabotagens vermelhas. Surgiram 6 itens `bin/sdd` fora, re-ancorados; conteúdo velho: `review_scope_check` → `hat_expand` (`:510`), e o item do ledger perdeu a 2ª superfície. Final: 39 medidos, 0 fora. A célula Commit do I8 passa a apontar o último commit.
- 2026-09-25 02:15 · `EXEC` · I9 `6904942`: Red `--anchors TODO.md` = 93 medidos, 25 fora; depois 90, 0 fora. Glob `templates/*.md` → `templates/handoff.md:2` (`missao:`); nomes entre aspas viraram crase para a regra poder lê-los como símbolo.
- 2026-09-25 02:15 · `EXEC` · I9 conteúdo velho: "quatro regras do `check-health.sh`" (piso 12 vs 16) → três fecharam em `a948f68` (piso exato hoje 37, probe aritmético, `RULE_REPORTS`); a quarta, `|| :` sem probe, foi **medida** (sabotagem numa cópia: verde) e o item ficou só com ela. `guard:` "fala alto em if/local/here-doc" → isentos e declarados; ficou a metade do helper fora da região.
- 2026-09-25 02:15 · `EXEC` · I9 conteúdo velho: #86 dizia que o sensor "confere que existe" — falso, nunca conferiu; corrigido. `docs/pipeline.md` 43% → 35% (497 de 1419). Suíte ~33 s → ~300 s (medido 4:58 nesta sessão). `README.md:152` passa na regra e ficou como está.
- 2026-09-25 02:15 · `EXEC` · I9 apagados (conserto já na `main`): âncora morta de mutante em segundos (`e09ca0c`, o `--anchors` do catálogo); dois `sed` sem endereço (`f6ffb34`). Decidido: ciclo do `RESOLVIDO por` × catraca → o template manda ficar até o merge; virou registro. Catraca 93 → 90.
