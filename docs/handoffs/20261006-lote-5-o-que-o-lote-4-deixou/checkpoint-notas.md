# Notas de execução — Lote 5: o que o lote 4 deixou

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

- 2026-10-06 03:00 · `PLAN` · plano escrito pelo sdd-planner no worktree; protótipos dos grupos A–F em ~/.claude/plans/2026-10-06-lote-5-protos/

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

- 2026-10-06 03:15 · `PLAN` · `--red` sobre este checkpoint: 11 pending Check(s), every one red at HEAD (03:00–03:15); teste de autocontenção "sim, com ressalvas", ressalvas fechadas no plano
- 2026-10-06 09:25 · `PLAN` · decisão humana pós-aprovação ("Investiga E melhore", retro do planejamento): I12 entra fora dos 12 achados — o `/sdd-plan` commita o que o `sdd approve` deixa e o relay segura mensagem que não é resposta; feito em `5df5176` pela sessão do relay antes do I1, suíte verde (351 s)
- 2026-10-06 11:05 · `EXEC` · I1 (#226) em `fc763ef`. Red medido: Check `0`, e os quatro `surface:` FAIL no código de antes (isca MOVED nos três mundos, git mudo rc 0, censo com os 17 arquivos); verde `4`. Censo sensor-sozinho sob o veneno: 0 de 16 movem a isca, todos rc 0 (o `check-mutation.sh` por `--anchors`); suíte inteira sob o veneno `suite green` em 461 s, isca intacta. Sabotagem 8 de 8 vermelha pelo motivo certo (S1 kaizen sem source, S2 hat sem source, S3 gates com o source abaixo de `git init -q -b main`, S4 glob `check-a*` → 90, S5 ordem ignorada → 90, S6 sem unset, S7 recusa amolecida, S8 só `unset GIT_DIR`); S9 `GITENV_FLOOR=0` sobrevive, declarado no comentário do piso. `--only` pegos: RUN_entrypoint_unguarded, HEALTH_ratchet_one_way, HEALTH_suite_without_mutation, BOOT_notes_not_inlined, HEALTH_with_mutation_refused. Desvio do protótipo: a linha em branco extra que o patch punha no `check-mutation.sh` saiu. Re-âncora: `red_norm` 536 → 537, `SDD_TEST_STATE` 33 → 36.
- 2026-10-06 11:19 · `EXEC` · I2 (#224) em `dfd9ab5`. Red medido: Check `0`; com os probes e o código de antes, `check-gates` deu `got: QA` e `got: EXEC: 1 increment(s) done…` (sem o ID), e o selftest rc 90 nos dois probes novos (`wanted rc 1, got 0`); verde `2`. Mutantes novos 4 (619 → 623), todos pegos por `--only check-gates.sh`, mais 10 vizinhos (9 em `check-gates`, `EXEC_cell_marker_never_armed` em `check-autonomy`). Sabotagem do sensor 8 de 8 com os rc do plano (90/90/90/91/90/91/90/92). Desvio: o patch B junta I2 e I3; apliquei por hunk (`hunks.py`) e deixei o `PROBE_FLOOR` em 63, o I3 leva a 64. Re-âncora pelo `remap.py --root` do worktree; o item #224 virou `bin/sdd:600` (`if (n < 6)`), porque o símbolo antigo deixou de existir.
- 2026-10-06 11:31 · `EXEC` · I3 (#223) em `802b6d5`. Red medido: Check `0`; com a asserção e o código de antes, selftest rc 90 (`SENSOR-BROKEN: red_norm expands its array unguarded…`); verde `1`. Prova efêmera (decisão 7) em `docker run bash:4.3`: `grep -c "unbound variable"` → `1` antes, `0` depois. Sabotagens: guarda tirada → 90; asserção apagada → 92 (piso 64). Suíte inteira depois do I3: `suite green` em 532 s, `anchors: all 623 mutants still apply`. Ferramenta da sessão: vigília com `pgrep -f` sobre o próprio padrão nunca termina (casa a si mesma) — parada à mão.
- 2026-10-06 11:54 · `EXEC` · I4 (#232) em `4d72973`. Red medido: Check `0`; com os mundos novos e o código de antes, W1 `REVIEW|REVIEW|named:0`, W3 e W4 `REVIEW|REVIEW` (W2 controle verde); verde `3`. Mutantes novos 5 (623 → 628) e 10 vizinhos `QA_bug_genre_*`: 15 de 15 pegos. Espelho `sdd-qa` por `./bin/sdd install --force`; `./bin/sdd preflight` sem `stale`, mas com `TEST_CMD FAILED` porque rodou a suíte antes do `remap.py` no mesmo comando (âncoras do `TODO.md` fora do alvo, log `.sdd/logs/_geral/preflight-test-20261006-114029-*.log`); suíte inteira depois do remap `suite green` em 386 s. Texto: `agents/sdd-qa.md` §5.1, `docs/pipeline.md` (bullet da âncora 3 e o parágrafo do `wont-fix`), `CONTEXT.md` (Gênero do bug), anatomia §4.
- 2026-10-06 12:09 · `EXEC` · I5 (#225) em `ed5ef44`. Red medido: Check `0`; com os mundos (j)/(k)/(l) e o código de antes, (j) e (l) `expected: QA|1 got: REVIEW|0`, (k) controle verde; verde `1`. Mutantes novos 3 (628 → 631); os 33 `QA_report_*` (30 existentes, entre eles os 5 obrigatórios, + 3 novos) re-provados por `--only check-gates.sh` em lote de 8: 33 de 33. Código idêntico ao do protótipo, então os números da ADR 0016 §1 (10 → 10 e 13 → 16 processos `git`) ficam; não remedi. Texto: `docs/pipeline.md`, `CONTEXT.md` (Relatório da missão), anatomia §4.
- 2026-10-06 12:35 · `EXEC` · I6 (#233) em `6a5c3bb`. Red medido: Check `0`; regime 1b `expected: 1 got: 0`, regime 2b com o benigno igual ao editado (`sessions:2 lines:0 rc:3 kind:no-progress same:0 named:0` nos dois); verde `2`. Desvio do protótipo: o `GIT_OPTIONAL_LOCKS=0` do plano não estava no patch — entrou no `kit_guard_tree`, medido (git 2.43: sem ele o `git status` reescreveu o índice de um repo de rascunho depois de um `touch`, com ele não), sem probe e declarado no comentário. Mutantes novos 4 (631 → 635) + 10 vizinhos: 14 de 14 pegos; cinco deram `HARNESS-BROKEN` (controle sem sabotagem vermelho) com `TMPDIR=/tmp/l5-exec/o-<slug>`, porque o caminho longo da sandbox empurra o "was not measured" para além do corte de 200 do ledger (limite declarado no sensor desde `0c0e13a`) — refeitos com `TMPDIR` curto, todos pegos. Suíte inteira depois do I6: `suite green` em 511 s.
- 2026-10-06 13:14 · `EXEC` · I7 em três commits: #228 `8778be8`, #227 `0f5ad85`, decisão 11a `92f7d5c` (a célula leva o último). Red medido por parte: #228 mundo 9b `stale:1:0|impossible:2|0|1|0`; #227 `--phase PLAN` `rc:2 notes:3` e `--phase PR` no carimbo `2|0|1|+1` (o do salto draft vale `+0` antes e depois, existe para o mutante); 11a retry no teto `notes:+1 head:moved`, NW6B `notes:1 head:moved`, NW6D `on-pr:0`. Check do I7 inteiro: `10`. Mutantes 2 + 2 + 7 novos (635 → 646), 2 re-ancorados; re-provas 4 + 6 + 19, todas pegas. Desvios: os comentários do protótipo F diziam "decision 10a" — corrigido para 11a, a numeração do `00-missao.md`; a mensagem do 1º commit saiu truncada por aspas simples dentro de `bash -c` e foi refeita com `--amend -F` (commit local, não empurrado) — desde então toda mensagem vai por arquivo. Re-âncora: o item #227 virou `bin/sdd:8735` (a chamada nova acima do `before=`), o #228 `bin/sdd:8515`.
- 2026-10-06 13:33 · `EXEC` · I8 em dois commits: #229 `e892814`, #230 `57ea34f` (a célula leva o último). Red medido: #229 `hints:2>3` (EXEC, REVIEW e DOCS sugeridos em falso), verde `2>0` com a contagem de ✓ igual; #230 `claimed:1 said:0` nos mundos sem checkpoint, `mv` recusado e sujo. Check do I8: `2`. Mutantes 2 + 4 novos (646 → 652), re-provas 3 + 7, todas pegas. Nenhum doc fora da anatomia descreve a dica do `sdd status` (grep em `docs/`, `README.md`, `CONTEXT.md`, `config/`, `commands/`), então o `pipeline.md` não mudou; anatomia §5 (#229) e §7 (#230).
- 2026-10-06 13:48 · `EXEC` · I9 (#234) em `daf3a8e`. Red medido: Check `0`; dry-run `expected: 5 5 5 got: 5 0 0`, coordenação `pids=[…] left='PLAN\n' quiet='PLAN\n'` (o probe do hook calado é controle, verde antes e depois); verde `3`. Mutantes novos 4 (652 → 656) + 5 vizinhos: 9 de 9. Sintaxe do helper sob `python3 -I -S` ok. Suíte inteira depois do I9: `suite green` em 582 s.
- 2026-10-06 13:50 · `EXEC` · I10 (#235) em `4e9c854`. Red medido: Check `0`; com o probe e o comando de antes, `FAIL command: /sdd-plan no longer moves …`; verde `1`. Desvios: (a) o 2º hunk do `235.patch` não aplicava, porque o I12 já pusera `command_relay_probes` na lista de topo — inserção feita pelos nomes, `command_worktree_probes` depois de `command_relay_probes`; (b) a frase "dentro do worktree, `health`/`preflight`/`install` por `./bin/sdd`" que o plano exige não estava no patch — entrou no passo 2, e o probe ganhou a 8ª verificação. Sabotagem 10 de 10 vermelha (D1–D9 do plano + D10 sem o `./bin/sdd`). A âncora do item #235 (`commands/sdd-plan.md:15`) ficou no alvo: o passo novo entra depois da linha 15.
- 2026-10-06 14:04 · `EXEC` · I11 (fecho) em `6bc4b37`. Check `12 1 1 1 1` (12 `RESOLVED by`, entrada do KAIZEN_LOG, `Amended by: 0016` na 0015, 0016 `accepted`, `20-handoff-exec.md`). Suíte inteira no topo do código: `suite green`, 592 s, 1890 linhas `ok`, 0 FAIL, `anchors: all 656 mutants still apply`; `./bin/sdd adr check` rc 0. Drift: `docs/failure-modes.md` (supervisor nomeia o processo; `deferred` sem decisão barra) e `docs/pipeline.md` (o `ok` do `note-manual`). Corrigido antes do commit: o KAIZEN_LOG dizia "140 re-provas"; contadas nas listas, são 129.
