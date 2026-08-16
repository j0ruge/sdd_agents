---
missao: 20260815-ledger-sem-ponto-cego
atualizado: 2026-08-16 00:45
---

# Checkpoint — o ledger e o Jidoka param de mentir

> **Este arquivo é lido por máquina.** O runner faz parse da tabela abaixo para decidir a
> próxima fase. Não mude as colunas, não mude os tokens de status, não quebre linhas dentro de
> uma célula. Detalhe narrativo vai no `01-plano.md`, não aqui.
>
> Atualizar o checkpoint é o **último ato** de cada incremento — depois do commit, nunca antes.
> Status válidos: `pending` · `doing` · `done` · `blocked`.

| ID | Incremento | Check (comando → esperado) | Status | Commit |
|---|---|---|---|---|
| I1 | Jidoka do `blocked` com herestring, sem depender do buffer do pipe | `./tests/run-all.sh` → `suite green` com `score: 26 caught, 0 known gap(s), of 26` | done | 3521b9a |
| I2 | auto-degradação `review-to-draft` escreve no ledger e a série a reconhece | `./tests/run-all.sh` → `suite green` com `score: 27 caught, 0 known gap(s), of 27` | done | 6853796 |
| I3 | escaladas do `sdd autonomy` agrupadas por `kit_sha`, como a série já faz | `./tests/run-all.sh` → `suite green` com `score: 28 caught, 0 known gap(s), of 28` | done | e9a74aa |

## Notas de execução

> Uma linha por evento relevante: bloqueio, decisão tomada, desvio do plano com justificativa.
> É o que a próxima sessão lê para não repetir um erro que já custou caro.

- 2026-08-15 23:40 · — · Missão nascida pelo laço kaizen (`sdd kaizen`), a partir do veredito
  `indeterminado` em `05-verdict.md` (série vazia, `guard.sufficient: false`) e da triagem do
  `TODO.md`. Baseline medida nesta sessão sobre o `HEAD` `90f9ce9`: suíte verde, mutação
  **23/23**, `KNOWN_GAPS` vazio, **37,4 s** no default de `SDD_MUTATION_JOBS`.
- 2026-08-15 23:40 · `I1` · Lembrete para a sessão EXEC: a asserção do checkpoint >64 KB **tem de
  ser observada vermelha** antes do herestring entrar. Se ela nascer verde, o fixture não alcançou
  o regime de falha — marcar `blocked` e aumentar o fixture, nunca relaxar a asserção.
- 2026-08-15 23:40 · `I2` · O `select` de `bin/sdd:1767` só aceita `session` e `blocked`. Escrever
  a linha `degraded` sem abrir esse filtro a manda para `excluded.unrecognized` — trocaria um
  ponto cego por outro. Os dois passos vão no mesmo incremento.
- 2026-08-15 23:40 · `I3` · Não tocar em `kaizen_series`: ela já agrupa escalada dentro da fatia
  de `kit_sha` (`bin/sdd:1774`). Só o `cmd_autonomy` está sem eixo.
- 2026-08-16 · — · O code review do I13.3 (pré-merge, duas rodadas) acrescentou a 24ª e a 25ª
  mutações (`KAIZEN_guard_ignored` — o gate cruza `guard.sufficient` com o veredito; e
  `KAIZEN_approved_bailout_dead` — aprovação preenchida nunca alcança sessão) e renomeou
  `SERIES_refez_dropped` → `RUN_refez_dropped` (contrato de prefixos do catálogo). A régua desta
  missão foi deslocada +2 (Checks agora 26 → 27 → 28) e a linha de baseline do `01-plano.md`
  atualizada de 23 para 25 — o número que a sessão EXEC verá de fato na abertura.

- 2026-08-16 · — · Revisão pré-run: os três defeitos re-conferidos vivos no `bin/sdd` de `main`
  (`fdf8708`); suíte re-medida verde, `score: 25 caught, 0 known gap(s), of 25` (52,6 s sob
  carga). Números defasados pela régua +2 corrigidos no `00-missao.md` (métrica 28/28, K2 25→28)
  e no `01-plano.md` (baseline `of 25`, e2e 25→28). Aprovação: `humano-2026-08-16`.

- 2026-08-16 · `I1` · **O Red que o plano exigia aconteceu, mas só na segunda tentativa da
  asserção** — e o motivo vale mais que o conserto. Com o checkpoint de 20000 linhas, a primeira
  versão do teste (`rc 3` + `BLOCKED in EXEC`, herdada da asserção pequena que já existia) nasceu
  **verde sobre o bug**: o esgotamento de `phase_budget` escala com o **mesmo rc e o mesmo prefixo
  de mensagem** que o Jidoka. O runner de fato deixava de disparar, abria duas sessões de EXEC
  contra a parede e só então escalava — e a asserção não sabia distinguir. O fixture estava no
  regime de falha desde o começo; quem não media era a asserção. Endurecida para exigir o ramo
  certo (`The line stopped on purpose`) e a **ausência** do marcador do stub do `claude` — que é o
  que "sem gastar sessão" significa, e que o stub do `check-gates.sh` só reportava sem ninguém
  afirmar desde que foi plantado. Lição para I2/I3: "a asserção ficou vermelha" não basta; tem de
  ficar vermelha **pelo motivo certo**, e um `rc` compartilhado com outro ramo é asserção vácua
  disfarçada.
- 2026-08-16 · `I1` · Limiar medido no fixture: até ~4000 linhas de `ckstatus` o Jidoka dispara;
  a partir de ~5000 ele silencia de forma determinística (10/10). O teste usa 20000 linhas por
  margem, geradas por `awk` no setup (nada de ~1 MB de fixture versionado). Custo: suíte
  **50,4 s** contra os 48,5 s medidos nesta sessão no `HEAD` `7751ce1` (baseline do plano: 37,4 s
  em máquina descarregada) — `check-gates.sh` sozinho foi de 2,6 s para 2,9 s, e ele roda 27 vezes
  dentro do `check-mutation.sh`.
- 2026-08-16 · `I1` · Fora de escopo, registrados no `TODO.md`: (a) a própria suíte ainda usa
  `printf | grep -q` em `check-gates.sh:53` e em cinco pontos do `check-dry-run.sh` — mesma
  família, lado do teste, fora do Check do I1; (b) `shellcheck -S warning tests/` reprova
  (SC2318, pré-existente em `check-mutation.sh:246`) e o `LINT_CMD` do repo só olha `bin/sdd`.

- 2026-08-16 · `I2` · **A lição do I1 se aplicou, e desta vez antes do prejuízo.** O fixture novo
  termina com `rc 3`, exatamente como os outros dois caminhos de escalada — então `rc 3` sozinho
  manteria o bloco inteiro verde sobre um fixture que nunca chegou ao ramo `draft`. A guarda
  anti-vacuidade é **estrutural**, não de prosa: uma sessão de fase **PR** com o gate de REVIEW
  ainda falhando só pode existir PORQUE o runner degradou — `current_phase()` devolveria REVIEW
  para sempre. Ela vale verde antes e depois do conserto, e é o que aponta as outras asserções
  para o ramo certo.
- 2026-08-16 · `I2` · Chegar ao ramo custou o fixture mais caro da suíte: PLAN+TICKET+EXEC+QA
  todos satisfeitos, `REVIEW_MAX_ITER=1`, e um stub que **move o disco na primeira chamada só** —
  com stub morto a escalada `no-progress` dispara na retentativa inline e o ramo de orçamento
  nunca é alcançado. Um degradação por run, determinístico.
- 2026-08-16 · `I2` · **Desvio do plano, deliberado:** o plano listava dois pontos a mudar (o
  escritor e o `select` da série). Foram **quatro**: o `is_escalation` do `cmd_autonomy`
  (`bin/sdd:1707`) também só aceitava `blocked`, então sem ele o `sdd autonomy` passaria a
  imprimir "1 unrecognized row" para uma linha que o próprio runner escreveu — o ponto cego
  mudado do juiz para o humano, que é exatamente o que a missão fecha. O quarto é o
  `pipeline_log_line`, que o `continue` também saltava.
- 2026-08-16 · `I2` · **Mutação: 1 no catálogo, 4 metades medidas.** O Check fixa o score em 27,
  e sabotar várias âncoras num mutante só derrubaria a detecção de "âncora apodreceu" que o
  cabeçalho do `check-mutation.sh` promete. O catálogo levou `RUN_degraded_row_dropped` (o
  escritor) por ser também a **guarda de alcance do fixture caro**. As outras três foram
  sabotadas à mão nesta sessão, uma a uma, e as três mataram a suíte: `select` da série →
  `check-kaizen.sh` rc 1, 2 FAILs; `pipeline_log_line` → `check-autonomy.sh` rc 1;
  `is_escalation` → `check-autonomy.sh` rc 1, 2 FAILs. Evidência de sessão não roda no CI —
  registrado no `TODO.md`.
- 2026-08-16 · `I2` · Refatoração feita (duplicação real, não estética): `autonomy_blocked_row` e
  o escritor novo seriam 15 linhas de `jq` idênticas menos um literal. Viraram
  `autonomy_escalation_row <event> <kind> <phase> <why>` com dois wrappers de uma linha. O
  carimbo do kit continua **chamado, nunca substituído** (`$( )` mataria a guarda one-shot no
  subshell) — a lição do `CLAUDE.md` vale para o escritor novo igual.
- 2026-08-16 · `I2` · Suíte **59,9 s** (contra 53,3 s medidos nesta sessão no `HEAD` `0976fc9`),
  `sdd health` verde. O fixture novo do `check-autonomy.sh` roda 27 vezes dentro do
  `check-mutation.sh`, e agora abre 4 sessões de stub por vez em vez de 2.
- 2026-08-16 · `I2` · Fora de escopo, registrados no `TODO.md`: (a) as três metades sem mutante
  permanente; (b) o runner **se auto-degrada mais de uma vez no mesmo `sdd run`** — depois do
  `force_phase="PR"`, se PR mexer no disco e não passar no gate, o laço volta a REVIEW com o
  orçamento ainda estourado e o ramo dispara de novo, uma linha `degraded` por volta. O fixture
  só não vê porque a segunda sessão de PR não move o disco. É mudança de laço, não de registro.

- 2026-08-16 · `I3` · **O Red veio limpo e pelo motivo certo, de primeira** — 7 asserções novas
  vermelhas, todas no bloco novo, e o resto do arquivo verde. A que mais importa é a anti-vacuidade:
  `grep -cE '^  [A-Za-z][A-Za-z0-9_-]*: [0-9]+$'` devolveu **3** antes do conserto (linha de
  escalada sem versão nenhuma na frente) e **0** depois — e a linha `no-progress: 4` que ela pegou
  provava, num número só, as duas metades do defeito: escaladas de dois `kit_sha` somadas E as
  linhas de kit sujo / sha nulo somadas junto.
- 2026-08-16 · `I3` · A asserção que **é** a métrica da missão compara dado com dado, não prosa:
  extrai do `sdd autonomy` as escaladas do `kit_sha` mais recente e as confronta com o mapa
  `escalations` que `sdd kaizen --series` reporta para o mesmo sha. Os dois leitores discordarem
  volta a ser vermelho mesmo que cada lado, sozinho, pareça plausível.
- 2026-08-16 · `I3` · **Desvio do plano, deliberado (nome do mutante):** o plano pedia
  `AUTONOMY_escalations_no_axis`; entrou como `RUN_escalations_no_axis`. A regra do catálogo
  (`tests/check-mutation.sh:37`) é `mut_<GATE>_<slug>` para gate e `mut_RUN_<slug>` para o que não
  é gate — `cmd_autonomy` é leitor, não gate. É a mesma correção que o review do I13.3 já aplicou
  em `SERIES_refez_dropped` → `RUN_refez_dropped`.
- 2026-08-16 · `I3` · **Segundo desvio, forçado pelo próprio conserto:** as asserções de leitor do
  bloco de degradação passaram a **normalizar o carimbo do kit** no ledger antes de chamar o
  `sdd autonomy`. Com a tabela agora derrubando linha não-comparável, o carimbo real decide o
  resultado — e ele é árvore suja em qualquer sessão EXEC e cópia sem `.git` dentro do
  `check-mutation.sh`. Sem normalizar, o bloco passaria no CI e falharia na máquina de quem
  desenvolve (ou o inverso). As linhas seguem sendo as que o **runner** escreveu; que elas carregam
  carimbo é asserção separada, contra o ledger intocado.
- 2026-08-16 · `I3` · Suíte **59,4 s** e `score: 28 caught, 0 known gap(s), of 28` — contra os
  59,9 s medidos no I2. O mutante novo não custou tempo mensurável: o fixture do I3 é um ledger de
  6 linhas escrito à mão, sem sessão de stub.
- 2026-08-16 · `I3` · Fora de escopo, registrados no `TODO.md`: (a) o mesmo `jq` do `cmd_autonomy`
  tem **dois** testes de comparabilidade (`comparable` com `.kit_dirty == false`, `on_axis` com
  `.kit_dirty != true`) — hoje não divergem, mas é a família de defeito do I3 um nível abaixo;
  (b) a tabela do `sdd autonomy` ordena versões lexicograficamente enquanto a série usa ordem de
  aparição, então a última linha da tabela pode não ser a versão mais recente.

## Incrementos de fix (QA)

> Escritos pelo `sdd-qa` quando um bug sanável é reprovado. Entram na mesma tabela acima com ID
> `F<n>`, e o Check obrigatoriamente inclui **regression test passa** + **re-walk da jornada
> impactada verde**. Bug que exige julgamento humano NÃO vira fix — vai para
> "Decisions for a Human" no handoff de QA.
