# Notas de execução — A janela não se parte

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

- 2026-10-01 11:20 · `PLAN` · plano escrito pelo `sdd-planner` com o humano (via sessão coordenadora); 9 decisões do grill no `00-missao.md`; ADR 0014 alocada; suíte verde em `c19e987` (259 s, 515 mutantes aplicam)

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

- I1 (85039c7): RED observado pelo motivo certo (4 asserções kit_rev: com kit_rev/kit_rev_dirty = null, campos crus corretos). Mutantes provados isolados pela receita contra check-autonomy.sh: RUN_kit_rev_is_head rc=1 (pego por 'outside the behaviour paths'), RUN_kit_rev_dirty_whole_tree rc=1 (pego por 'dirt outside'), RUN_kit_guard_reads_rev rc=1 (regime 1 + regimes 4, 5, 7 da guarda). Check do I1 → 5. tests/run-all.sh → suite green, rc 0, anchors 518 mutants. 22 âncoras do TODO.md remapeadas pelo diff (contagem 87 inalterada). Mundo 4 usa agents/kr-probe.txt (não .md) para não tocar o espelho de agentes do install.
- I2 (eedc6d3): RED observado pelo motivo certo (5 asserções kit-version:, A agrupava por aaa0002 e o gêmeo B já respondia certo — controle). Mutantes provados isolados pela receita contra check-kaizen.sh: KAIZEN_kit_version_ignored rc=1 (pega as 4 do juiz), AUTONOMY_kit_version_ignored rc=1 (pega 'the human table'), KAIZEN_kit_rev_dirty_ignored rc=1 (pega 'dirt outside'). Surpresa: com bin/ sujo durante a sessão, duas asserções de check-autonomy.sh (degradação e harness) caíram porque normalizavam só kit_sha/kit_dirty — agora normalizam também kit_rev/kit_rev_dirty. KAIZEN_historic_steps_series_blind reancorado (rc 90 → aplica; pego por 'recover the QA sub-step alike'). Check do I2 → 5. tests/run-all.sh → suite green, rc 0, 263 s, anchors 521 mutants. Âncoras do TODO.md remapeadas (bin/sdd, check-mutation.sh, check-autonomy.sh), contagem 87.
- I3 (162e923): RED observado pelo motivo certo (mundo 9 do check-gates: DONE|written com config/ removido). Guarda por caminho em mutation_stamp_key antes do find; linha md5sum <<< "$listing" intacta. Mutante PR_stamp_key_partial_listing provado isolado pela receita contra check-gates.sh: rc=1 (pego por 'stamp-key: a root missing…'). Fixtures que esperam carimbo ganharam templates/ e config/ com arquivo (check-gates mundo 3 + TREE_KIT; check-health build_fixture — sem isso o mundo 'real' de OUT_CAT_REAL deixava de carimbar). Check do I3 → 2. tests/run-all.sh → suite green, rc 0, 265 s, anchors 522 mutants. Âncoras do TODO.md remapeadas pelo diff em bin/sdd (+9 após 2020), check-health.sh (+5 após 181) e check-mutation.sh (+9 após o catálogo), verificadas por conteúdo; contagem 87. Achado não registrado (prosa sem sensor): docs/pipeline.md:1364 cita bin/sdd:4929 para comparable_row, já obsoleto antes do I3.
- I3 r1 (883e91e): conserto da revisão — mutation_stamp_missing (uma definição, chamada) alimenta a guarda da chave, a frase do gate_PR e um health_bad novo no cmd_health para raiz parcial com catálogo verde; comentário obsoleto do gate_PR reescrito. Asserção nova no mundo 9 (sem prefixo stamp-key:, Check do I3 segue 2). Mutantes PR_partial_root_blind_remedy e HEALTH_unstampable_silent novos, PR_stamp_key_partial_listing reancorado; os três rc=1 isolados contra check-gates.sh. run-all verde, 263 s, anchors 524. TODO.md: âncoras completas e as seis curtas (:9272, :5831/:5904, :6248, :10008, :9995, :3535) remapeadas por conteúdo; 87.
- I4 (89d8e62): RED observado pelo motivo certo (mundos 10 e 11 do check-gates: DONE antes, PR depois do commit da catraca / do tests/debug.log ignorado — o mundo 11 re-carimba antes para não herdar o PR do 10; mundo 12 e a asserção stamp: do check-health também vermelhos: carimbo parcial escrito, nada nomeado). Listagem git ls-files -c sobre MUTATION_STAMP_PATHSPEC (montado uma vez de MUTATION_STAMP_PATHS + MUTATION_STAMP_EXCLUDE), `|| listing=""` torna o rastreado apagado chave vazia; mutation_stamp_why (uma definição) dá motivo+remédio para caminho ausente, raiz sem git, rastreado apagado e nada rastreado — gate_PR e cmd_health leem dele. TREE_KIT e o fixture do check-health viraram repos git (mundo 3 das duas árvores agora parte de $SDD_STATE_FIX/no-repo). Mutantes isolados pela receita, todos rc=1: PR_stamp_key_keeps_baseline, PR_stamp_key_reads_ignored, PR_stamp_key_partial_on_deleted, PR_stamp_why_deleted_blind (check-gates), PR_stamp_why_not_git_blind (check-health); reancorados em MUTATION_STAMP_WHY e re-provados: PR_partial_root_blind_remedy, HEALTH_unstampable_silent; PR_stamp_key_partial_listing e PR_stamp_key_follows_head seguem pegos. Check do I4 → 5. tests/run-all.sh → suite green, rc 0, 274 s, anchors 529. TODO.md: âncoras completas e curtas remapeadas pelo diff e conferidas por conteúdo; #67 e o piso do catálogo apontavam para linhas de tests/check-mutation.sh já obsoletas desde c19e987 (corrigidas para sandbox() e errors=0); 87.
- I4 r1 (f8c2a86): conserto da revisão — mutation_stamp_why publica MUTATION_STAMP_WHY_KIND; cmd_health 2c trata not-git como warn (kit instalado como cópia: nenhum gate exige carimbo ali), remove carimbo velho, sem falha; motivo unreadable novo (symlink quebrado, gitlink, sparse); limites D15 no comentário da chave (vendorizado e ignorado, GIT_DIR/GIT_WORK_TREE, GIT_LITERAL_PATHSPECS). RED contra o runner de 89d8e62: stamp: do check-health (rc 1, fail "nothing was stamped"), mundo 13 (absent|0|0), mundo 4 das árvores (absent|0|1). Mutantes HEALTH_not_git_counts_failure rc=1 (check-health e check-gates) e PR_stamp_why_unreadable_blind rc=1 (check-gates); vizinhos re-provados rc=1. Check do I4 → 5. run-all verde, 408 s, anchors 531. TODO.md: âncoras completas e curtas remapeadas por conteúdo; 87.
- I5: RESOLVED by nos quatro itens (eedc6d3, 89d8e62 x2, 162e923) e uma linha decidida; catraca segue 87; suite verde (4m42).
- revisão final (915008b): 4 achados Minor — 'até ser commitado' → 'até ser rastreado (git add)' em bin/sdd e ADR 0014; ramo genérico do cmd_health 2c declarado defensivo/inalcançável (D15) e comentário do gate_PR corrigido; probe 'kit-rev-dirty: …' (fora do prefixo kit-version:) + mutante KAIZEN_kit_rev_dirty_failopen provado isolado rc=1; ADR 0003 'Amended by: 0014' em linha própria (na linha do Status quebrava a forma medida). Catálogo 532 âncoras ok; TODO.md remapeado por conteúdo, 87. run-all verde, rc 0, 284 s. Checks: I1 5, I2 5, I3 4 (deriva prévia: o I4 acrescentou dois 'stamp-key:'; check-gates.sh não tocado aqui), I4 5, I5 1.

- **2026-10-01 — correção do Check do I3 (sessão coordenadora):** o Check do I3 contava todo `stamp-key:` e passou a dar 4 depois que o I4 acrescentou duas asserções com o mesmo prefixo; agora ancora no nome exato da asserção do I3 e volta a dar `2`. Defeito do plano (os dois Checks dividiam o prefixo), não do código.
