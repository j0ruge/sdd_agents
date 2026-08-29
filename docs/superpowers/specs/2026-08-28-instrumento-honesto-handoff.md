# O instrumento honesto — handoff

**Data:** 2026-08-28 · **Estado:** plano **executado ponta a ponta** — as Tarefas 1 a 10 estão
commitadas (12 commits desta missão mais este handoff). Falta **abrir os dois PRs**: o desta branch
e o da branch de baixo, que ainda não existe. Carimbo `667a87cc54751f564783c6bdfceaf4a4`,
`score: 173 caught, 0 known gap(s), of 173`, catraca `todo-findings 78`.

Auto-contido de propósito. A sessão que ler isto não participou da conversa que o gerou, e não
precisa dela: o spec, o plano, o `git log` e este arquivo bastam. Onde há número, ele foi medido.

---

## 1. Comece por aqui

```bash
cd ~/repos/sdd_agents
git branch --show-current                  # esperado: feat/instrumento-honesto
git log --oneline main..HEAD | wc -l       # esperado: 26 — 12 da branch de baixo, 1 do spec,
                                           #   12 do plano e este handoff
git status --porcelain                     # TEM de sair vazio
```

- **spec:** [`docs/superpowers/specs/2026-08-28-instrumento-honesto-design.md`](2026-08-28-instrumento-honesto-design.md)
  — autoridade sobre o que era para ser feito.
- **plano:** [`docs/superpowers/plans/2026-08-28-instrumento-honesto.md`](../plans/2026-08-28-instrumento-honesto.md)
  — as dez tarefas, com os blocos de código que cada uma escreveu.
- **branch:** `feat/instrumento-honesto`, **empilhada** sobre `feat/o-gate-sabe-que-o-app-caiu`
  (`cfb5fa7`, 12 commits sobre a `main` em `d30d199`). O PR de baixo **ainda não foi aberto**
  (`gh pr list --state open` responde vazio). Quando ele mergear, `git rebase main` aqui é trivial —
  a base já estará lá; ramificar da `main` compraria dois conflitos por construção (spec §1).

**A aceitação do §13 do spec, rodada nesta sessão** (saída completa em
`~/.sdd/measure/2026-08-28-instrumento-honesto/acceptance.txt`, fora do git — carrega caminho de
repo de cliente):

```bash
./tests/run-all.sh | tail -3                       # suite green (663 linhas `  ok    `)
cat .sdd/logs/mutation-stamp                       # 667a87cc54751f564783c6bdfceaf4a4
git diff --stat 9122478..HEAD -- bin tests templates config   # VAZIO — a chave do carimbo
                                                   #   não foi tocada desde o último commit de código
./bin/sdd autonomy --all-repos --by-mission | grep condicoes-pagamento
#   sales_quote/20260827-condicoes-pagamento-mesmo-cliente  6 session(s) · 5 advanced · 1 churned ·
#   0 idle · 3 launch(es) · 1 reopened · US$ 68.87
./bin/sdd autonomy --all-repos --by-mission | grep -c '?'     # 0
./bin/sdd kaizen --series | jq -c '.latest.outcomes, .latest.advance_rate'
#   {"advanced":5,"churned":1,"idle":0}
#   0.83
git diff main -- KAIZEN_LOG.md | grep -c 'churned'  # 5  (≥ 1: a entrada existe, com os dois lados)
```

⚠️ **Não rode `./bin/sdd health` de leve.** Ele não tem flag e **sempre** roda o catálogo de
mutação inteiro — ~15 minutos (§6, decisão 5). A evidência do carimbo desta missão está guardada em
`~/.sdd/measure/2026-08-28-instrumento-honesto/health.txt`, e o `git diff --stat` acima é o que prova
que ela ainda vale.

## 2. Por que esta missão existe

**O leitor humano mentia na direção que lisonjeia o kit.** `stalled` estava definido como
`moved == false` — "a sessão não escreveu nada no disco" —, que não é "a fase não avançou". Censo das
145 sessões do ledger real, antes de qualquer edição: 64 `pass/true` (avançou), **68 `fail/true`**
(escreveu algo, o gate reprovou, o runner leu "moveu" como progresso e comprou outra sessão) e 13
`fail/false`. As 68 do meio eram **invisíveis**: nenhuma célula da tela as nomeava. Sobre a missão
real SQ-111 (`20260827-condicoes-pagamento-mesmo-cliente`), que o handoff anterior descreve como
*"~8 resgates humanos"*, o instrumento imprimia `6 session(s) · 0 stalled · ? intervention(s)`.

**O juiz lia `ok` sobre uma fase que girou cinco vezes.** A rubrica `phase_label` só chegava a
`refez` com escalada, `sdd retry` humano ou última sessão reprovada, e a `leve` com `auto_retry` ou
`moved == false`. O EXEC de `20260825-frete-cif-fob` — **7 sessões, 5 reprovações de gate**, cada uma
commitando algo, nenhum retry automático — caía no `else` e lia **`ok`**. Um juiz que não vê churn
não pode responder "a última mudança do kit melhorou ou piorou".

**A contagem de intervenções lia prosa que ninguém escrevia.** A D16 mandava contar as linhas
`- intervention:` do `checkpoint.md`. As três missões do piloto escreveram **0, 1 e 0** delas — e a
de três lançamentos escreveu zero. Fora do repo do kit o contador nem tentava: respondia `?`, em
**5** das missões da tabela. O `run_id`, ao contrário, está em **toda** linha do ledger, de todo
repo. O handoff anterior escreveu a frase que fecha o argumento: *"Sem isso não dá para provar que
esta missão funcionou."*

## 3. O que foi feito

| | |
|---|---|
| `main` | `d30d199` |
| branch de baixo | `feat/o-gate-sabe-que-o-app-caiu`, 12 commits, **sem PR** |
| `d763098` | o spec desta missão (commit anterior ao plano; não conta como execução) |
| `f60b26a` | o plano de execução — as dez tarefas |
| `b79bfc6` | T1: o achado do `sdd close` entra no `TODO.md`; catraca `77 → 78` num diff com autor |
| `324514d` | correção do plano: `sdd health` sempre roda o catálogo, não é checagem rápida |
| `4e6d3fe` | T2: `ledger_outcome_defs` — a tri-estado, UMA definição costurada nos dois leitores |
| `16c967e` | T2 (rodada de conserto): `comparable_row` — sessão sem `moved` sai do eixo do juiz |
| `79e455e` | T3: `waste` muda de régua — `churned + idle`, não `idle` sozinho |
| `adfc884` | T4: a cláusula de churn na rubrica — qualquer `gate: fail` na fase ⇒ ao menos `leve` |
| `4c68c0b` | T5: `launch(es)` e `reopened` na linha por missão, sobre TODA sessão da missão |
| `687b4f0` | T5 (rodada de conserto): os três limites declarados, no cabeçalho do jq |
| `9122478` | T6: as notas viram narrativa (`intervention note(s)`), o `?` desaparece — **último commit de código** |
| `443ce69` | T8: `pipeline.md`, `agents/sdd-kaizen.md` (+ espelho), `README.md`, `failure-modes.md` |
| `a406112` | T9: `CONTEXT.md` (D16 emendada, verbete **Churn**) e a entrada do `KAIZEN_LOG` |
| este commit | T10: a aceitação rodada e este handoff |

T7 (o carimbo) não tem commit: é uma corrida de verificação. T0 (a medição do "antes") também não —
as saídas moram fora do git, em `~/.sdd/measure/2026-08-28-instrumento-honesto/`, porque carregam o
caminho dos repos de cliente.

## 4. O desenho, em três frases

**Uma definição, emitida uma vez, costurada nos dois programas.** `ledger_outcome_defs()` imprime
jq (`outcome`, `outcome_tally`, `phase_index`) e nasce ao lado de `ledger_row_is_local()`, que já
usava a forma. `cmd_autonomy` e `kaizen_series` costuram a mesma string e recebem os mesmos
`--arg phases "$PHASES"`. A paridade entre os dois é **afirmada por asserção diferencial** — o
histograma impresso pela janela humana comparado com `.latest.outcomes` da série, sobre o MESMO
fixture —, nunca por um comentário jurando "mesma grafia nos dois". `advanced` = o gate passou (o
gate é o artefato); `churned` = escreveu e reprovou; `idle` = nem escreveu.

**`launches` e `reopened` são fatos sobre a história humana da missão, não sobre uma versão do
kit.** Por isso são derivados sobre **todas** as sessões locais da missão (`is_session`), enquanto
`session(s)`, `outcomes` e `US$` continuam sobre as comparáveis — a soma de dinheiro entre as duas
tabelas tem de fechar. Um lançamento que caiu num kit sujo foi um lançamento: sem essa população, a
SQ-111 leria `0 reopened` exatamente na missão que motivou o campo. Quando as duas populações
divergem, o parágrafo de contabilidade ganha **uma** frase dizendo isso.

**Leve ganha do silêncio.** Qualquer sessão da fase com `gate == "fail"` puxa o rótulo para pelo
menos `leve`, mesmo que a última tenha passado. Três rótulos, não quatro: a magnitude mora em
`outcomes` (grupo e `detail` por fase), e um quarto rótulo mudaria o conjunto de chaves
`{ok, leve, refez}` para dizer o que um número ao lado já diz. Nenhum campo novo na linha do
ledger, `v` continua `1`, zero migração — as 145 linhas históricas se releem com a régua nova.

## 5. Verificação ponta a ponta

A tabela antes/depois é a entrada do [`KAIZEN_LOG.md`](../../../KAIZEN_LOG.md) de 2026-08-28 — é lá
que ela mora, com a ressalva de população por extenso. O resumo:

| | Antes (régua `moved`) | Depois (régua `gate` + `moved`) |
|---|---|---|
| SQ-111, por missão | `6 session(s) · 0 stalled · ? intervention(s)` | `6 session(s) · 5 advanced · 1 churned · 0 idle · 3 launch(es) · 1 reopened` |
| `frete-cif-fob` · EXEC, no juiz ⚠️ | `ok` | `leve` — do censo do §2 do spec, **não** de `sdd kaizen --series`: essa fase está fora da janela de duas versões (`.latest` `25d4e1c`, `.previous` `06e49bc`), e o `detail` responde vazio dos dois lados |
| `25d4e1c` (latest), série | `moved_rate: 1, labels: {ok:5, leve:0, refez:1}` | `outcomes: {advanced:5, churned:1, idle:0}, advance_rate: 0.83`; `labels` **não** muda |
| `lote-facil` | `9 session(s)` | `4 launch(es) · 2 reopened` — bate com a contagem à mão do handoff anterior §9 |
| `?` na tabela por missão | **5** missões | **0** |
| `waste` de `25d4e1c` | **0%** | **16%** (a régua mudou, não a sessão) |
| tabela de versão, sessões **comparáveis** (133 de 145) | `8 stalled` | `64 advanced · 61 churned · 8 idle` |
| asserções de `tests/run-all.sh` | 637 | **663** |
| `check-autonomy.sh` / `check-kaizen.sh` | 202 / 137 | **222** / **143** |
| catálogo de mutação | 166 de 166 | **173** de 173 |
| achados abertos no `TODO.md` | 77 | 78 |

⚠️ **Duas populações, e nenhuma célula mistura as duas.** A tabela de versão soma só as sessões
**comparáveis** (133 de 145; exclui kit sujo e `sha`/`moved` nulos) e lê `64/61/8`. O censo do §2 do
spec lê as **145** linhas e responde `64/68/13`. As duas contagens são corretas para populações
diferentes; a tabela, por desenho, nunca soma 145. Isso está escrito na entrada do `KAIZEN_LOG` em
vez de arredondado.

**Os sete mutantes, cada um com o assassino nomeado** (`166 → 173`, todos verificados no
`mut_verify` da tarefa que os escreveu, e o catálogo inteiro reverificado no carimbo):

| Mutante | Quem mata, e com que número |
|---|---|
| `AUTONOMY_outcome_reads_moved_only` | o histograma fixado `3 advanced · 2 churned · 1 idle` — o mutante lê `5 0 1`. ⚠️ **A paridade NÃO o pega**: os dois leitores compartilham a definição quebrada e continuam concordando entre si |
| `KAIZEN_outcome_inlined_old` | a paridade janela × série — é o mutante que prova que ela é **medida** e não afirmada (mata em `check-autonomy.sh` e em `check-kaizen.sh`) |
| `AUTONOMY_waste_idle_only` | `waste counts churned and idle, not idle alone` — exige `50%` **e a ausência** de `16%` na mesma linha |
| `KAIZEN_churn_reads_ok` | `a phase that wrote, failed its gate and then passed reads leve, never ok` — o mutante lê `ok` |
| `AUTONOMY_launches_counts_rows` | `launches count distinct run_id per mission` — o mutante lê `m1:3` em vez de `m1:1` |
| `AUTONOMY_reopened_ignores_gate` | o par diferencial `pass:1 fail:0` — o mutante lê `fail:1`, e só o gêmeo `QA(fail)` vira |
| `AUTONOMY_reopened_comparable_only` | a população `1 session(s) · 2 launch(es)` — o mutante lê `1 1` |

## 6. As decisões que se afastaram do plano, e por quê

Nove decisões foram tomadas durante a execução. O ledger que as registrou
(`.superpowers/sdd/2026-08-28-instrumento-honesto/progress.md`, linhas `Ruling:`) é **local e não
versionado** — está no `.gitignore` —, então as nove estão reproduzidas aqui por inteiro, cada uma
com o que custa se estiver errada. Esta lista é a fonte, não um resumo dela:

1. **Trabalhar no lugar, sem worktree.** Este checkout **é** o `$SDD_HOME`: `sdd health` carimba,
   `sdd install --force` espelha e o preflight lê ESTA árvore, e o `CLAUDE.md` registra um bug vivo
   de worktree no portão de identidade do `cmd_kaizen`. *Custa nada se errada* — a branch é a que o
   spec nomeia, e a `main` não está em checkout em lugar nenhum.
2. **`outcome_tally` fica na emissão compartilhada** (o spec §4.1 listava duas `def`s, não três). As
   três chaves são o enum, e a regra do runner é UMA definição por programa para enum lido em mais
   de um ponto. O mutante `KAIZEN_outcome_inlined_old` substitui a costura inteira, então a tabela
   segue o `outcome` local. *Custa um `sed` de mutante um pouco mais longo se errada.*
3. **A guarda `$r == $repo` na célula de notas** (não estava no spec). O §4.5 diz que missão cujo
   checkpoint não é legível não imprime nada; sem a guarda, uma missão de **outro** repo com o mesmo
   slug tomaria emprestadas as notas deste e imprimiria uma célula falsa sob `--all-repos`. *Custa
   um probe se errada* — e o probe existe (`noteclash`).
4. **O comentário do `ledger_outcome_defs` diz o que o jq 1.7 foi medido a fazer, não o que o spec
   supôs.** O §4.1 afirmava que um programa que costura o `def` sem o `--arg` morre com *"$phases is
   not defined"*; medido, o jq 1.7 **compila** um `$var` não ligado dentro de uma `def` que ninguém
   chama (`def f: $x; 1` compila). O comentário registra a medição. *Custa nada* — os dois leitores
   continuam passando o `--arg`, que é o que o spec queria garantir.
5. **`sdd health` não tem flag e SEMPRE roda o catálogo** (`cmd_health` → `tests/run-all.sh
   --with-mutation`, `bin/sdd:2917`). A "checagem rápida" da T1 e o re-run da T8 estavam errados no
   plano e foram reescritos em `324514d`; as sandboxes órfãs das corridas abortadas foram mortas e
   os `/tmp/sdd-mut-*` removidos. *Custa uma corrida de catálogo se errada.*
6. **A série passa a admitir sessão só com `moved` presente** (`comparable_row`) — o achado
   Important da revisão da T2. Os dois leitores classificavam **populações diferentes**: uma linha
   de schema velho sem `moved` era `idle` para o juiz e excluída para o humano. Medido no fixture
   misto: `sdd autonomy` lia `2 session(s)` e a série lia `{"sessions":3, …, "idle":2}`. O fixture
   de paridade da T2 não conseguia ver a divergência, porque não tinha essa linha. Medido antes de
   mexer: o ledger real tem **145 sessões, 0 sem `moved`, 0 sem `gate`** — a mudança é invisível em
   dado real. *Custa, se errada, uma troca de balde para um formato de linha que o runner parou de
   escrever antes de o ledger ter juiz.*
7. **A asserção de controle da T4 fica, mesmo duplicando uma consulta pré-existente** (`m3` → `ok`).
   O par (churn + controle) lê como um diferencial só. *Custa uma asserção redundante se errada.*
8. **Os limites declarados da T5 entram como texto de comentário, no mesmo bloco** — o achado
   Important da revisão da T5 era defeito do **plano**: o §11 do spec roteou quatro limites para os
   comentários de `launches`/`reopened` e o texto do plano trazia só um. Junto entrou a Minor 2 do
   revisor (um lançamento que escalou antes de qualquer linha de sessão é invisível, porque a
   população é `is_session` por spec §4.4). A população **continua** `is_session`: contar linha de
   escalada em `launches` tornaria a frase de contabilidade falsa, e não é decisão desta missão.
   *Custa nada se errada* — é comentário.
9. **O carimbo (T7) roda no controlador, em segundo plano, com a T8 em paralelo.** É um comando de
   verificação sem edição, e um subagente vigiando 15 minutos de corrida foi o que gerou as
   sandboxes órfãs da T1. A T8 mexe só em `agents/`, `docs/` e `README.md`, fora da chave do
   carimbo. *Custa uma re-corrida do catálogo se um sensor de árvore viva ler um doc meio escrito
   durante a corrida* — não aconteceu: o `git diff --stat 9122478..HEAD -- bin tests templates
   config` sai vazio.

## 7. Armadilhas medidas

- ⚠️ **A precedência do `|` em jq quase entrou no código.** A fórmula ilustrativa da decisão 6,
  `(.event == "session") | not or has("moved")`, **não compila do jeito que se lê**: `|` tem a
  precedência mais baixa, então o booleano é canalizado para `not or has("moved")` e o `has` roda
  contra um booleano — `Cannot check whether boolean has a string key`, em toda linha de sessão.
  Pego à mão no `jq` antes de ser ligado. A forma que ficou é `(.event != "session") or
  has("moved")`.
- ⚠️ **O RED do probe `noteclash` leu `2 0 0`, não o `2 1 1` que a prosa do plano previa.** Motivo:
  naquele ponto a célula ainda dizia `intervention(s)` e a asserção nova já procurava
  `intervention note`, então não casava **nenhum** dos dois lados. O vermelho é real e pelo motivo
  certo — o empréstimo de notas acontece mesmo, antes da guarda —, só não era visível por aquele
  `grep` antes de a mudança de texto chegar junto. As duas guardas foram confirmadas por
  **sabotagem em cópia** na revisão da T6.
- ⚠️ **Âncora de inserção é código citado, nunca número de linha.** O ponto de inserção da T5 tinha
  saído de 1758 para 1820 entre a escrita do plano e a execução; ancorar na linha `rm -rf` citada
  salvou a tarefa. O mesmo vale para o `KAIZEN_LOG`: a âncora `## 2026-08-26` **não é única** (há
  duas entradas com o mesmo prefixo de data), e a asserção de unicidade pegou isso antes de
  qualquer escrita.
- ⚠️ **Renomear um texto impresso quebra os `grep` dos sensores que o liam.** Três ocorrências de
  `grep -oE '[0-9]+ intervention'` viraram `'[0-9]+ intervention note'` no `check-autonomy.sh` — o
  mesmo commit que mudou a célula.
- ⚠️ **Evidência antes da afirmação, também para o processo.** Na T1 o implementador commitou
  enquanto o `./bin/sdd health` ainda rodava e ofereceu a suíte como prova da catraca. O artefato
  estava certo, mas a prova não era a prova: quem verificou a propriedade foi o revisor, direto
  (`check-todo` 78 == baseline 78).
- ⚠️ **A ordem do carimbo é uma restrição do plano, não uma preferência.** A chave é o conteúdo de
  `bin/ tests/ templates/ config/`, e `tests/health-baseline.txt` está nela — então a subida da
  catraca (T1, `77 → 78`) tem de vir **antes** do carimbo, e os docs (T8/T9) depois. É por isso que
  o §9 do spec ordena as tarefas assim.
- ⚠️ **`sdd health` custa ~15 minutos e não tem como pedir menos.** Duas corridas abortadas deixaram
  sandboxes órfãs em `/tmp/sdd-mut-*`.

## 8. O que falta

1. **Abrir os dois PRs.** A branch de baixo (`feat/o-gate-sabe-que-o-app-caiu`, 12 commits sobre
   `d30d199`) **ainda não tem PR**, e esta empilha nela. Hoje `gh pr list --state open` responde
   vazio. Esta branch cita o carimbo `667a87cc…` e o score `173 caught of 173`.
2. **Depois do merge da branch de baixo:** apagar o item `RESOLVIDO por 2ce6ce8` do `TODO.md` e
   baixar a catraca `todo-findings` no `tests/health-baseline.txt` — provado por
   `git merge-base --is-ancestor 2ce6ce8 main`, nunca pelo rótulo do PR (handoff anterior §8).
3. **`sdd close` continua fora do ledger.** Achado registrado em `b79bfc6`, não consertado — a
   missão era o instrumento, não o escritor. Direção no próprio item do `TODO.md`.
4. **Três dívidas menores, declaradas e sem asserção** (todas defensáveis, nenhuma fail-open):
   `outcomes` de um grupo vazio lê zeros enquanto `advance_rate` e `moved_rate` leem `null`; o par
   de população não tem piso explícito de "o gêmeo perdeu uma linha" (falha fechado de qualquer
   jeito); `history_of` é O(M²) por consulta, irrelevante no tamanho do ledger.
5. **A faxina D15 e o custo do REVIEW** — as duas missões seguintes do handoff anterior §9,
   intocadas por esta. Ver §9 abaixo.

## 9. A próxima missão, já desenhada

As duas do handoff anterior §9 continuam de pé, com os números de lá:

1. **Faxina D15.** ~12 itens do `TODO.md` são limites já declarados que deviam morar no cabeçalho
   do sensor, e os 3 de *Adiados por YAGNI* são roadmap inflando a catraca. O alvo de lá era
   `77 → ~62`; hoje o número é **78** (esta missão registrou o achado do `sdd close`). ⚠️ Alvo
   escrito como número absoluto já falhou uma vez, medido — o `CLAUDE.md` guarda o caso.
2. **O REVIEW** — 49% do custo de uma missão, US$ 37,30, a US$ 2,70 do próprio teto.

⚠️ **O que ESTA missão muda na leitura das duas.** A janela de medição passa a imprimir
`launch(es)` e `reopened` por missão, e `advanced · churned · idle` por versão e por missão — então
o piso de "3 missões no mesmo `kit_sha`" deixa de ser uma contagem à mão e passa a ter instrumento.
Duas consequências práticas para quem for planejar a próxima:

- **o juiz deixou de ler `ok` sobre uma fase que girou.** Verdicts anteriores a 2026-08-28 foram
  dados por outra régua mecânica — isso é o caso que a ADR 0001 desenhou (*"régua mecânica é
  código, datada no histórico"*), não uma emenda dela. Comparar rótulo velho com rótulo novo é
  comparar réguas diferentes;
- **o número oficial de intervenções da D12 agora é `launch(es)`** (D16 emendada no `CONTEXT.md`), e
  ele **subconta de propósito**: subir o app à mão entre dois lançamentos é um `run_id` novo, não
  dois. É um piso honesto no lugar de um teto que ninguém preenchia. A leitura *intervenções =
  lançamentos − 1* é do humano e do prompt do juiz; o instrumento imprime o fato.

⚠️ **E a régua que o backlog viola** continua valendo, do handoff anterior: dos achados abertos,
metade não tem consumidor fora do repo do kit, e 32 dos 77 de então nasceram do `sdd-reviewer`
auditando o próprio kit — só 4 vieram de trabalho real em repo-alvo. Missão de kit que não encosta
nessas classes está polindo o eixo errado.
