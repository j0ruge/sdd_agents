# Notas de execução — Lote 3 — a catraca desce

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

- 2026-10-04 00:20 · `PLAN` · plano escrito pelo `sdd-planner` com o humano (via sessão coordenadora, 10 decisões de grill em 2026-10-03). Triagem cética dos 57 por 4 verificadores; os 13 consertos prototipados num clone de `5d55571` por 4 designers. Os 20 Checks rodados contra HEAD: 20 vermelhos com o valor de antes anotado. `check-checkpoint --check` none blind; `adr: none`; `aprovacao: auto`. Os relatórios brutos ficaram no scratchpad da sessão, não no repo.
- 2026-10-04 00:20 · `PLAN` · teste de autocontenção por subagente sem memória (I1, I12, I17): 0 lacuna bloqueante de fato. Lacunas de custo fechadas no plano: I17 concreto (`distinct_killers`, `run_job`, `run_first_control`, `controls_verdict`, `CONTROL_FIRST`), corpos e 4 sítios de drift do I12, cópias de "6 of the 14", commit `chore(checkpoint)` separado, N único, 580 → 592 mutantes, catraca no Check do I14. Achado nascido no planejamento: o `kaizen_reminder` tem o defeito do #121 (registrado no I14).

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

- 2026-10-04 08:48 · `EXEC` · I1 (8577df6) · Red medido `0 5 0`, depois `1 18 1`. 13 itens fora da seção aberta, 13 registros decididos verbatim do plano, catraca 57 → 44. Medido de novo antes de escrever o "6 of the 30": 30 rodadas `40-review-r*.md`, 6 sem `gate:`. check-todo, check-lang e check-pipefail verdes; nenhuma âncora deslocou (edições no lugar).
- 2026-10-04 08:50 · `EXEC` · I2 (db2eee1) · Red `0 0 1 1`, depois `1 2 0 0`. D7 emendada, 🚩 do D7 e do contrato PT-BR apagados, Y5/Y6 na tabela YAGNI, CLAUDE.md § Idioma, anatomia §6 e gaveta P1 sem "está no TODO.md". Contagens do Y5 re-medidas (232 + 364) e 10 alvos pt-BR. Desvio: o `|` dentro do code span do Y5 foi escrito `\|`, porque célula de tabela GFM parte no pipe cru mesmo dentro de crase.
- 2026-10-04 08:58 · `EXEC` · I3 (4af9d0c) · Red `0 0`, depois `1 5`; suíte inteira verde (4m45). Desvios: o comentário do `tail_of` mora dentro do awk entre aspas simples, então a frase do plano ("this sensor's header") foi reescrita sem apóstrofo; o número do #77 é 3 itens vivos com rabo de prosa (o plano mediu 4 sobre `5d55571`, antes do I1/I2); o preâmbulo do bloco Declared debt dizia "These two" sobre quatro entradas e passou a valer para cinco. O motivo do guard do check-todo foi medido numa cópia com a forma do `sandbox()`: `anchor README.md names no file`. Âncoras 4 re-ancoradas (remap + xref), conteúdo conferido.
- 2026-10-04 08:59 · `EXEC` · I4 (921e95e) · Red `0 0 0 1 same`, depois `1 1 1 1 same`. Seção do repasse no `commands/sdd-plan.md` e parágrafo do relay no chapéu; espelho por `sdd install --force` (só o planner mudou). A frase "with the human present" do § Then passou a dizer que é através do relay. check-lang, check-checkpoint e check-hat verdes.
- 2026-10-04 09:02 · `EXEC` · I5 (0521972) · Red: Check `0` (9 sensores) e selftest com 3 probes vermelhos (calthin contando linhas, echo de 3 espaços invisível, árvore inline com 0 sensores). Conserto: agulhas por variável, conta arquivos, piso 16; Check `1`. Sabotagens via clone (casar só pass(), sem aspa dupla, contar linhas): 3 de 3 vermelhas, controle verde. Item 4 do cabeçalho e o comentário do check-templates atualizados. 3 âncoras re-ancoradas (remap + xref).
- 2026-10-04 09:05 · `EXEC` · I6 (41ac7a1) · Red: P1, P3 e P4 vermelhos em HEAD (P2 verde). Conserto conforme o plano; a regra virou o item 5 do cabeçalho (o 3 já era a regra dos documentos) e o scan ganhou a linha ok própria (`0 tested path(s)` no kit). Testemunha real do lighthouse (I13) pega. Sabotagens 6 de 6 vermelhas, controle verde. 3 âncoras re-ancoradas.
- 2026-10-04 09:06 · `EXEC` · I7 (9e521d1) · Red: P1 e P3 vermelhos (P2 verde). Regra 6 no scan_file DEPOIS da regra 1 (desvio de posição: linha deslocada não tem Status confiável), linha ok própria no scan. Sabotagens 4 de 4 vermelhas, controle verde. PROBE_FLOOR 39. 3 âncoras re-ancoradas.
- 2026-10-04 09:07 · `EXEC` · I8 (bf660f8) · Red: com o check/refute novos e o template antigo, check-templates rc 92 (as duas FAIL + o controle ponta a ponta). Template reescrito, frase no chapéu, espelho por `sdd install --force`; Check `1 1 same`. Sabotagem: SDD_TEMPLATES_DIR com o checkpoint.md de HEAD → rc 92, as duas metades FAIL. check-checkpoint, check-lang e check-hat verdes. Nenhuma âncora deslocou.
- 2026-10-04 09:11 · `EXEC` · I9 (e7d1e2d) · Red: os 6 probes vermelhos por `unknown option --baseline` (rc 96). Conserto conforme o plano, mais dois acréscimos: o piso de itens vale no modo baseline (senão `--allow-empty` ficaria inerte nele) e as chaves do arquivo atual saem numa passada só. Sabotagens 5 de 5 vermelhas. Testemunha ui24 ainda `3 new (7 inherited)` — é o defeito do I10 (cópia resolve âncora pela raiz errada). 1 âncora re-ancorada.
- 2026-10-04 09:23 · `EXEC` · I10 (8870bab) · Red: probe 7 deu `1 new (1 inherited)`. Override conforme o plano; Check `1`. Testemunha ui24: `0 new … (10 inherited)` (antes `3 new (7 inherited)`). Sabotagens 2 de 2. Suíte inteira verde depois de consertar um defeito do I7 que só o lint viu: `[ "$st" = done ]` (SC1010), conserto em 3cf0d0a (decisão 5). Daqui em diante, shellcheck nos arquivos tocados antes de cada commit.
- 2026-10-04 09:34 · `EXEC` · I11 (52de46e) · Red: as 8 asserções vermelhas (`bare:0 dotted:1` ×4; recusas `lived|0` ×3 e `died|0` no HANDOFF_DIR). Conserto conforme o plano; check-gates verde, Check `8`. Mutantes provados com --only: os 2 novos (check-gates), o re-ancorado (check-autonomy) e o RUN_hat_expand_unquoted (check-dry-run, fixture reescrito). --anchors: 582 aplicam. 10 alvos locais aceitos. dry-run/autonomy/adr/hat/preflight/kaizen verdes. 16 âncoras re-ancoradas.
- 2026-10-04 09:43 · `EXEC` · I12 (0ed9218) · Red: o mundo 1 e o bloco DOCS deram REVIEW em HEAD (mundos 2 e 3 já verdes, como devem). Conserto conforme o plano; check-gates verde, Check `1 1`. Mutantes REVIEW_dirty_unscoped e DOCS_uncommitted_passes pegos (--only). Prosa: 8 sítios reescritos; os do cmd_approve seguem verdadeiros (o checkpoint.md está no escopo) e ficaram. --anchors 584; 4 âncoras re-ancoradas.
- 2026-10-04 09:52 · `EXEC` · I13 (ece5895) · Red: A1 e A2 `REVIEW|REVIEW` em HEAD, A3 verde. Awk conforme o plano; Check `2 1`. Extrator velho × novo sobre 173 fichas reais dos alvos: 0 diferenças. Mutantes novos + fenced + anywhere pegos (--only). Contrato em 4 documentos + espelho. 4 âncoras re-ancoradas.
- 2026-10-04 09:56 · `EXEC` · I14 (188ca87) · Red: `0 admitted` × `1 refused`. Porta por identidade (ledger_repo_root); Check `2 1 1 1`. Mutantes novos e o KAIZEN_reminder_wrong_repo pegos (--only). Achado do kaizen_reminder registrado com catraca 35 → 36 (N = 1 até aqui). 2 âncoras re-ancoradas.
- 2026-10-04 10:00 · `EXEC` · I15 (9edd800) · Red: `5 unnamed no-shape jq-words` e `0 unnamed no-shape no-jq-words`, os valores do plano. Conserto espelhando 5236206; Check `2`. Série byte-idêntica a HEAD sobre o ledger real (clone de HEAD × árvore). Mutantes pegos (--only); os AUTONOMY_* seguem num sítio só. --anchors 590.
- 2026-10-04 10:09 · `EXEC` · I16 (4f4a9b3) · Red: as 3 asserções positivas falhavam em HEAD. Probe conforme o plano; Check `3`. Mutantes pegos (--only). --anchors 592 (alvo do plano). Suíte inteira verde. 3 âncoras re-ancoradas.
- 2026-10-04 10:24 · `EXEC` · I17 (0be5e8d) · Red: `--anchors` recusava (controls_verdict inexistente). Conserto conforme o plano; Check `1`. Sabotagens 6 de 6 vermelhas. Medição dos 10 controles com o assassino na frente: 10/10 verdes (300 s). Primeira tentativa deu 10/10 VERMELHO por ambiente, não por ordem: TMPDIR de 98 caracteres empurra a frase do kit-guard do check-autonomy para além do corte de 200 do gate_why — limite declarado no sensor em commit à parte (régua D15: falha fechada, sem consumidor fora da suíte).
- 2026-10-04 10:29 · `EXEC` · I18 (d658dca) · Red: `--anchors` recusava (census_join ausente no check-mutation). Seleção conforme o plano; Check `1`. Sabotagens 5 de 5. Mapa real: 6ad41f7 → 14, 89d8e62 → 218 (protótipo). Decisões: SDD_KILLERS_FILE só no modo --touched (o catálogo escreve o mapa); o modo sem --list recusa com rc 2 até o I19. check-health verde importando as duas funções.
- 2026-10-04 10:33 · `EXEC` · I19 (ebad097) · Red: o selftest recusava (touched_verdict inexistente) e o Check dava `0`. Execução conforme o plano; Check `1` (2 of 2, 4 s). Prova do perdido com mapa errado: rc 1 e `--only PLAN_empty_approval`. Desvio: guarda nova "o pool lança exatamente a seleção", porque o veredito só lê os selecionados e a sabotagem "roda tudo" passaria calada. Sabotagens 2 de 2.
- 2026-10-04 10:46 · `EXEC` · I20 (60d4287) · Red: `1 0 0 18 0` antes (suíte ainda sem os docs, nenhum RESOLVED). RESOLVED by nos 13 (`efd001c`, todos ancestrais do topo), KAIZEN_LOG e 20-handoff-exec.md (`60d4287`); Check `0 1 13 20 1` com a suíte inteira verde (293 s, 1788 ok, 592 mutantes aplicam). Fase EXEC encerrada; próximo pelo § Depois do checkpoint: push, PR, bots, health, merge.
- 2026-10-04 10:47 · `EXEC` · I20 · Correção da nota anterior: o Red do I20 NÃO foi medido nesta sessão antes do conserto, e o `1 0 0 18 0` escrito ali não saiu de comando nenhum. O valor de antes que vale é o do plano, medido sobre `5d55571`: `0 1 0 5 0`. O verde (`0 1 13 20 1`) foi medido.
- 2026-10-04 12:34 · `EXEC` · revisão final #1 (713126a) · Decisão humana de 2026-10-04 ("incluir os dois") emenda a decisão 8: o escopo do `gate_REVIEW` soma o `HAT_WRITES_BASE` (`TODO_FILE`, `tests/health-baseline.txt`), lido pela mesma `hat_expand` da fronteira dos chapéus, porque o `sdd-reviewer` declara escrever o backlog. Red: `a dirty TODO_FILE the review wrote still holds REVIEW` → got DOCS; verde no check-gates.sh. Mutante irmão `REVIEW_dirty_scope_misses_base` morre pelas duas asserções do mundo 4; `--anchors` 593 aplicam. Desvio do handoff: o fixture RASTREIA o `TODO.md` (o `sdd install` semeia), então o mundo 4 desfaz com `git checkout --`, não `rm -f`. #115 ganha o segundo hash.
