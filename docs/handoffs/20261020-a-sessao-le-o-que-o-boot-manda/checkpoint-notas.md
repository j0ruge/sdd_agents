# Notas de execução — a sessão lê o que o boot manda ler

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

- 2026-10-20 12:02 · `PLAN` · plano nascido do `sdd kaizen` (veredito `melhorou` sobre `bad6168`, `05-verdict.md`), sem humano: `aprovacao:` vazio e `adr: none` até o I1, que é do humano
- 2026-10-20 12:02 · `PLAN` · no HEAD `4068f7e`: `check-checkpoint.sh --check` → 7 linhas, 5 sob a regra da âncora, nenhuma cega; `--red` → 7 de 7 vermelhos, rc 0, 453 s com `SDD_STATE_DIR` temporário
- 2026-10-20 12:02 · `PLAN` · sondas reais em 2.1.296 (11:41 e 11:42): sob `--allowedTools Bash` o `Read` de `$SDD_HOME/templates` é negado; a regra `Read(//dir/**)` libera só a leitura; o `--add-dir` libera também a escrita
- 2026-10-20 12:02 · `PLAN` · o I2 vem antes de qualquer mudança em `bin/`, porque as âncoras dos três itens são as do `4068f7e`; depois dele, todo commit em `bin/` reancora o `TODO.md` pelo símbolo
- 2026-10-20 17:38 · `PLAN` · grill do `/sdd-plan` com o humano por relay (15:59–): seis decisões no `00-missao.md`, todas `(recommended)`; ADR 0019 alocada por `./bin/sdd adr new` e escrita no PLAN; o antigo I1 (a ADR) e o antigo I2 (os três achados, agora chore do relay) saíram do checkpoint, e o `READ_EXTRA` se partiu em I5 e I6
- 2026-10-20 17:38 · `PLAN` · sondas reais em 2.1.304 (16:24–16:25, 13 sessões haiku, US$ 0,026): a regra continua só de leitura; `--setting-sources user,project,local` com `Read(*)` lê o template sem regra (o P2 do Codex); `--setting-sources ""` isola; symlink pede a regra do caminho e a do alvo (`~/.claude/skills/ticket`)
- 2026-10-20 18:11 · `PLAN` · grill fechado com sete decisões, todas `(recommended)`; o I6 ganhou o aviso da skill achada e não declarada (decisão 7); `--check` → 6 linhas, 6 sob a regra da âncora; `--red` → 6 de 6 vermelhos (o I6 remedido sozinho, `0 0`); o chore dos três achados já está na `origin/main` (#309, `b96f3d3`), e o passo "Antes do I1" do plano faz o merge

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
> `sdd run --phase X`, `sdd retry`, `--budget-override` — **e só na volta que abre sessão** (uma
> volta parada antes dela, por PLAN, carimbo, teto ou no-work, não grava nota), e a commita sozinha,
> na hora, para a árvore chegar limpa ao gate da fase seguinte. A linha escrita à mão continua valendo para o que
> o runner não vê: conserto manual, `BLOCKED` assumido. Fase feita à mão tem comando:
> `sdd note-manual <missão> <FASE>` escreve a nota e a linha `manual` do ledger, que não gradua
> nada — escrita só aqui, a fase não existe para o ledger. `sdd approve` não
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
- 2026-10-20 18:46 · `EXEC` · I1 feito em `7098b92`: `kit_read_rules` (uma definição, só imprime, lida por `mapfile < <( )`) e o `run_phase` soma a regra depois do valor do `--allowedTools`; Check → `1`; `check-dry-run.sh` 85 ok rc 0 (era 84; vermelho no HEAD com cinco `no-rule`); `check-autonomy.sh` 498 ok rc 0; `--only RUN_templates_read_rule_dropped check-dry-run.sh` → pego (rc 1); `--anchors` 717 de 717
- 2026-10-20 18:46 · `EXEC` · Ruling: as nove âncoras do `TODO.md` abaixo da função foram para número velho + 31 (o deslocamento do diff), e não para o "nearest" do `--anchors` — em três (`--no-gates` 7306, `shared_why` 11269, `inst_lang` 5882) ele, medido do número velho, caía noutra ocorrência (comentário, `local`), e o +31 é a mesma linha de código de antes — custo se errado: uma âncora a 3–18 linhas da linha certa, que o `check-todo.sh` aceita igual
- 2026-10-20 18:46 · `EXEC` · o ramo do alvo resolvido do `kit_read_rules` (`readlink -f` diferente) não tem probe no I1, e o comentário o declara: nenhum fixture symlinka `templates/`; o fixture de symlink do I5 é quem o mede, se o I5 reusar o mesmo ramo para o `READ_EXTRA`. A anatomia §2 nomeia as três portas e diz que cada porta que recebe a regra tem o seu probe — o I2 e o I3 acrescentam as deles a essa frase
- 2026-10-20 18:46 · `EXEC` · `tests/check-mutation.sh --only` pede o slug sem `mut_` e o nome nu do sensor (`check-dry-run.sh`); com `tests/check-dry-run.sh` sai rc 2 sem rodar nada
