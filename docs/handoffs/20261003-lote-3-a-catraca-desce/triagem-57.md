> Triagem cética dos 57 itens abertos, feita no planejamento desta missão (2026-10-03, sobre
> `5d55571`), guardada aqui porque a leva 4 parte dela. As 22 linhas DEC são o insumo do grill da
> leva 4: opções e reescopo já medidos. Números de linha envelhecem; ache pelo símbolo.

# Triagem cética dos 57 itens abertos do TODO.md do kit — 2026-10-03, sobre `5d55571`

Quatro verificadores paralelos, só leitura, cada alegação conferida no código (4 reproduzidas em
rascunho: #213, #63, #127 e a contagem do #88). Dois vereditos conferidos de novo pelo planner
(#113: `eb0ee9e` é ancestral e não sobra `ok` de 3 espaços em `tests/`; #138: `boot_prompt` em
`148f693` diz "goes to $TODO_FILE" e `TODO_FILE="TODO.md"`).

## Resumo

| classe | n | itens |
|---|---|---|
| MEC — conserto mecânico, sensor claro | 13 (11 P, 2 M) | 63, 87, 113 (resíduo), 115, 121, 127, 169, 211, 212, 213, 216 · M: 192, 217 |
| DEC — decisão de desenho antes de código | 22 (~17 decisões) | 67, 88, 92, 95, 98, 108, 109, 129, 130, 134, 135, 141, 142, 153, 155, 178, 179, 180, 191, 194, 198, 218 |
| D15 — sai sem código (limite declarado, decidido, YAGNI) | 20 | 66, 74, 77, 90, 93, 101, 102, 122, 123, 124, 125, 128, 137, 140, 143, 152, 154, 158, 181, 214 |
| STALE — premissa refutada | 2 | 138, 187 |

Fail-open (pela régua D15 não saem por declaração; só por commit ou por decisão que elimine a
afirmação falsa): MEC 63, 87, 113, 127, 169 · DEC 67, 95, 108, 129, 141, 155, 178, 179, 191.

Decisões DEC que se fundem: 142+198 (onde se carimba a fase PR) · 180+218 (enum de status do
checkpoint; com o MEC 216 ao lado) · 141+108 (superfície de idioma e pisos; 102/140 saem por D15) ·
98+130 (estrutura do pipeline.md; depois do 141) · 155+194 (sabotagem como evidência) · 92 (+93) ·
95 (só depois do MEC 217) · 88 (+128).

D15 que tocam `tests/*.sh` (cabeçalho de sensor ⇒ invalida o carimbo; pagar junto com o código):
66 (check-health), 77 (check-todo), 90 (run-all), 125 (check-pipefail), 140 (check-lang).
Os outros só tocam TODO.md/CONTEXT.md/ADR (fora da chave do carimbo, ADR 0014).

Âncoras velhas achadas no caminho: 63, 90, 98, 115, 122, 128, 129, 130, 135, 158, 169, 180, 187.
Prosa velha lateral: `tests/run-all.sh:309-311` diz que o sandbox nunca copia TODO.md (falso,
`check-mutation.sh:5859`); comentário `bin/sdd:1773` "6 of the 14" (hoje 6 de 30).

Velocidade da catraca (git log de tests/health-baseline.txt): últimas ~24 h fecharam 42 e nasceram
~10 (5 de sessões em repo-alvo). Idade: 24 itens de agosto, 21 de setembro, 12 de outubro.

## Detalhe por grupo
# Grupo 1 (verificador, 5d55571)
| # | still true | class | size | cluster | nota curta |
|---|---|---|---|---|---|
| 211 | yes (scan_file só pipe+âncora; nenhum check-ignore) | MEC | P | checkpoint-rules | resolver paths de test -f/-e contra o toplevel do checkpoint e reprovar ignorado; probe selftest |
| 191 | yes (nearest hit de qualquer span 4+ a ≤10; GATE_WHY cobre 1809/11032 linhas) — exemplo do item NÃO reproduz; caso vivo: #109 README.md:158 | DEC (fail-open) | M | todo-lint-laxity | emendar ADR 0011: símbolo na linha/bloco x recusar símbolo ubíquo x limite declarado |
| 77 | yes (4 itens vivos com rabo não-agente) | D15 limite declarado → decidido (prática já aceita atribuição não-agente) | P | todo-lint-laxity | mover a declaração do comentário p/ o cabeçalho |
| 217 | yes (sem --baseline; ui24-agent hoje 10 violações) | MEC | M | kit-sensors-in-targets | --baseline <ref>, violações chaveadas sem nº de linha; anchor_base override |
| 95 | yes (nenhum wiring do check-todo no alvo) | DEC (bloqueado por 217) | M | kit-sensors-in-targets | onde ligar: TEST_CMD sugerido / preflight-health warn / gate_DOCS-PR |
| 216 | yes (nenhuma regra de blocked; 0 casos reais em kit/sales_quote/lighthouse) | MEC | P | checkpoint-rules | regra estrutural em scan_file + probe; metade planner = prosa |
| 74 | yes (já declarado no cabeçalho check-checkpoint :44-47) | D15 decidido | P | check-cell-semantics | |
| 212 | yes (templates/checkpoint.md:19 e :33; 13 checkpoints no sales_quote) | MEC | P | kit-sensors-in-targets | reescrever p/ "--check do kit" como todo.pt-BR.md:5; check() no check-templates |
| 92 | yes | DEC | M | check-cell-semantics | planner registra vermelho num critério g (rótulo) x gate_PLAN roda Check no HEAD |
| 93 | yes (fail-closed, 1 caso) | D15 decidido/YAGNI ou dobra no texto do 92 | P | check-cell-semantics | |
| 113 | partial (metade 3 espaços CONSERTADA em eb0ee9e; resta calibrate() vê 9 de 16 sensores) | MEC | P | checkpoint-rules | alargar calibrate a toda def pass() + printf inline; subir piso |
| 109 | yes | DEC | M | docs-contract-drift | refute() na superfície de docs x gerar tabela de agentes do README do frontmatter x declarar DOCS dona |
| 137 | yes (8 filtrado; "13 sem filtro" também falso: 10) | D15 decidido (handoff fechado não se reescreve) | P | audit-trail | |
| 138 | NO — REFUTADO (boot_prompt em 148f693 expande $TODO_FILE=TODO.md) | STALE → decidido | P | audit-trail | |
Obs: 113+211+216 = um commit de regras scan_file/calibrate; 95/212/217 família, 217 antes; 74/92/93 = "nenhum gate roda Check".

# Grupo 2 (verificador, 5d55571)
| # | still true | class | size | cluster | nota curta |
|---|---|---|---|---|---|
| 192 | yes | MEC | M | killers-map | --touched <base>: mapa killer→sensor (census_file_of), --only por mutante |
| 67 | yes (ADR 0004 descarta chave larga; ADR 0014:114 "#67 stands"; agents/ lido por preflight/hat dentro dos mutantes) | DEC (fail-open estreito) | P | stamp | + agents/ + docs/adr (já em KIT_BEHAVIOR_PATHS) / os 8 / decidido citando ADR 0004 |
| 66 | partial (todas as chamadas fixam cd; step_timeout #112 torna a falha alta) | D15 limite declarado | P | suite-hygiene | |
| 90 | yes (guardas run-all :277-321; nenhum sensor guardado invoca o runner) | D15 limite declarado | P | suite-hygiene | lateral: run-all.sh:309-311 diz que sandbox nunca copia TODO.md — FALSO |
| 169 | yes (comentário run-all :91-93 admite "no sensor asserts it") | MEC (fail-open) | P | killers-map | controle do catálogo roda 1x por assassino distinto na frente; mutante que derruba o controle |
| 143 | yes (~300 s; duplica 🚩 CONTEXT.md:96) | D15 decidido (assinatura humana) | P | suite-cost | aposentar D7(4) ou trocar pela tabela step_timeout; fechar 🚩 junto |
| 108 | yes (classe; instâncias alinhadas hoje) | DEC (fail-open) | M | lang-surface/floors | catraca de igualdade x censo independente x limite declarado; decidir com 141 |
| 102 | partial (`que` nunca foi stopword; selftest :132-136 AFIRMA que slug em prosa é pego) | D15 decidido | P | lang-surface | direção contradiz probe deliberado |
| 140 | yes (declarado no cabeçalho e no CLAUDE.md) | D15 limite declarado | P | lang-surface | |
| 141 | yes, instância VIVA (docs/plan-only.md fora da superfície com pt-BR; sensor verde) | DEC (fail-open) | M | lang-surface/floors | glob + isenção de bloco cercado / glob + allowlist / lista + regra "todo docs/*.md escaneado ou declarado" |
| 125 | yes (declarado no CD_RE; 22 capturas com var absoluta) | D15 limite declarado | P | cdpath | estreitar "not a fail-open" para "seguro pela população de hoje" |
| 87 | partial (preflight roda stream real mas não lê total_cost_usd/num_turns) | MEC (fail-open de dinheiro: BUDGET_MISSION_USD cego) | P | harness-drift | preflight cobra total_cost_usd numérico; mundo stub com chave renomeada → _fail |
| 98 | partial (paridade de chaves jq x literal JÁ medida; prosa sem sensor; drift histórico foi SEMÂNTICO) | DEC | M | docs-structure/kaizen | bloco canônico + links, depois sensor de chave / só chave / limite |
| 130 | yes (523/1554 = 33,7%, cresceu) | DEC | M | docs-structure/kaizen | dividir em docs/ledger.md + docs/kaizen.md, ou aceitar; depois do 141 |
Obs: 141/108/102/140 = uma decisão (141 é o único fail-open vivo); 130/98 depois do 141; 192/169/67 família killers-map/carimbo; 66/90/125/140 = escrituração dupla (D15 sem código).

# Grupo 3 (verificador, 5d55571)
| # | still true | class | size | cluster | nota curta |
|---|---|---|---|---|---|
| 63 | yes (reproduzido; bin/sdd:1526-1530; limite declarado :1512-1517) | MEC (fail-open) | P | gate_QA-anchor3 | gênero do bloco contíguo que traz Status:; probe check-gates + mutante |
| 101 | yes (6 de 30 rodadas sem gate:, todas < 2026-08-18; comentário :1773 diz "6 of 14") | D15 limite declarado → decidido (ou MEC: exigir p/ missões ≥ 20260819) | P | review-seal | |
| 115 | yes (gate_REVIEW :1811 git status sem escopo; US$ 37,30) | MEC | P | dead-session-resume | escopar ao hat_writes REVIEW; probe DOCS sujo após r<N> deriva DOCS; mutante |
| 121 | yes (:10311-10319; mesma comparação em kaizen_reminder :10066 e kit_guard_check :3722) | MEC | P | worktree-identity | ledger_repo_root dos dois lados; par diferencial check-kaizen + mutante |
| 127 | yes, PIOR (TODO_FILE='*' casa bin/sdd → alarga writes de todo chapéu = fail-open) | MEC | P | config-path-hygiene | normalizar+validar no load_config com a gramática do hat_extra_path_ok; probe por chave |
| 128 | yes (falha alta e fechada, sem custo; irmão run_check_cmd :807) | D15 YAGNI/limite (ou `|| die`) | P | session-logs-dir | |
| 129 | yes (âncora velha; leitura do ledger fail-open; SQ-141 US$ 5,90) | DEC | P-M | run-snapshot | (a) avisar/parar se md5 mudou; (b) reler config por derive; (c) re-exec entre voltas |
| 178 | yes (sdd-ticket.md:18-19 promete acli; gate não chama) | DEC (fail-open) | P(b)/M(a) | jira-ticket | (a) gate chama acli (rede a cada derive) x (b) chapéu para de prometer + limite |
| 179 | yes (declarado :930-934) | DEC (fail-open) | M | qa-report-ownership | direção do item NÃO funciona (blob igual nos dois casos); aceitar risco x heurística de ordem |
| 180 | yes (gate_EXEC exige hash) | DEC | P-M | checkpoint-status-enum | grafia de evidência fora do git x regra "todo incremento deixa commit de registro" |
| 218 | yes (:1320 blocked = Jidoka) | DEC | G | checkpoint-status-enum | token novo (`waiting`) toca enum em N lugares x reordenar plano/--phase; decidir com 180 |
| 181 | yes (by design) | D15 decidido (ADR 0009 :77-83 mantém (A) recusada; deferred é a saída humana) | G se reabrir | gate_QA-anchor3 | |
| 187 | partial, premissa REFUTADA (status sem --no-gates roda TEST_CMD+E2E sob a trava; LOCK_NB não enfileira) | STALE → decidido | P | coordination-ux | lateral: run_check_cmd sem timeout |
| 88 | yes (385 MB sales_quote, 399 MB kit; gate-*.log ~400 KB cada) | DEC ou D15 YAGNI | P | session-logs-dir | gzip do stream / podar gate-*.log / N por missão; census lê *.stream.jsonl |
Obs: 180+218 uma decisão (+216); 63 e 181 mesma âncora; 127 primeiro entre os MEC; 179 re-escopar; 128+88 mesmo diretório.

# Grupo 4 (verificador, 5d55571)
| # | still true | class | size | cluster | nota curta |
|---|---|---|---|---|---|
| 213 | yes (reproduzido rc5 jq cru; array rc0 contra pipeline.md:1062) | MEC | P | ledger-readers | recusa de forma + stderr do jq no die, ou doc; par de probes check-kaizen + mutante |
| 214 | partial (código sim; premissa do rubric FALSA: linhas KAIZEN são $meta, fora do eixo) | D15 limite declarado | P | ledger-readers | pipeline.md já declara o laço próprio do kaizen |
| 135 | yes (sdd-docs.md:10 writes sem bin/**; reviewer manda prosa ao TODO, nunca R<n>) | DEC | M | hat-boundary | R<n> barato da EXEC x caminho estreito da DOCS (só hunk de comentário) |
| 142 | partial (regra do turno mitiga; direção não implementada) | DEC (fundir com 198) | M | stamp-timing | |
| 198 | yes (gate_PR exige carimbo; publisher carimba ao abrir PR) | DEC | M | stamp-timing | (a) runner pré-carimba; (b) carimbo vira passo pré-merge pós-bots (emenda ADR 0004); (c) aceitar re-carimbo |
| 152 | partial (kit fechou: f7bcf10 semeia, preflight _fail, sdd-qa §5.1; skill de terceiro segue sem) | D15 limite declarado → retrofit-skill no qa-report | P | qa-genre | ausente ⇒ bloqueia = fail-safe |
| 153 | yes (sem subcomando; enum 5 eventos) | DEC | M | ledger-events | 6º evento manual x leitores lerem intervention: x limite declarado |
| 154 | yes (mission_budget_blown soma tudo) | D15 decidido (porta humana = override + nota, anatomia §7) | P | budget | |
| 155 | yes (nota é rótulo; anatomia §4 já declara) | DEC | M | sabotage-evidence | coluna "sabotagem provada" lida pelo gate x limite declarado; P1 escapou p/ sales_quote #167 |
| 158 | yes (âncora velha :10430 → :10640) | D15 limite declarado (anatomia §6) | M se for feito (ADR) | coordination-perf | 30 ms imperceptível |
| 194 | yes (sdd-executor.md:76 sem sabotar o conserto) | DEC condicionado a medição (git blame r N+1 x commits R<n>; 0 casos ⇒ YAGNI) | P | sabotage-evidence | |
| 122 | partial (DOCS é condicional, nenhum gate cobra; SDD_VERSION em :16) | D15 decidido (salvo humano querer releases versionadas do kit público) | P | i18n-publication | |
| 123 | yes, PIOR (chaves 222 refs, nomes 364 refs; CLAUDE.md diz que quebra missão em voo) | D15 YAGNI (reabre no 1º alvo não-pt-BR) senão DEC-G | G | i18n-publication | editar CLAUDE.md § Idioma junto |
| 124 | yes | D15 YAGNI (mesmo evento do 123) | M-G | i18n-publication | |
| 134 | yes (0001-0007 sem Spec; 14 de 23 missões sem adr:) | DEC (humano mapeia 7 ou corte pre-0008 = adr: none) | P | adr-backfill | prova: sdd adr check 0 undecided → block |
Observações: 142+198 = uma decisão; 155+194 = "sabotagem como evidência"; premissas mudadas: 214, 123 (5x), 122; âncoras velhas: 158, 122, 135.
