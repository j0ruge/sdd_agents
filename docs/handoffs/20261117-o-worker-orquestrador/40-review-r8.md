---
missao: 20261117-o-worker-orquestrador
fase: REVIEW
rodada: 8
status: done
sessao: rodada do worker (o ato review do commands/sdd-worker.md), feita por um subagente sdd-reviewer da sessão orquestradora, fora do runner, com escopo delta 3a77d92..67fb6f9 (a skill invocada com base=3a77d92647a2df7b6b1ab4002ab9095bcff839dd, rodada de verificação)
data: 2026-11-19 01:33
gate: tests/run-all.sh no 67fb6f9 verde, rodado pela sessão orquestradora (rc 0, suite green, 2165 linhas ok e nenhuma linha FAIL, anchors 903 de 903, 881 s, 01:02:31 a 01:17:12, head_after igual ao head) e run-checks.py sobre as 30 linhas done do checkpoint (30 de 30 no esperado, rc 0, 2557 s); nesta rodada shellcheck -S warning limpo e bash -n rc 0 no bin/sdd-worker, no tests/check-worker.sh e no tests/check-mutation.sh, check-todo.sh rc 0 (91 achados, igual à catraca), check-checkpoint --check rc 0, segredos (regex e gitleaks, 13 arquivos, 586 linhas acrescentadas) sem achado, os dois mutantes discarded mortos por --only check-worker.sh numa cópia limpa, o mundo do R16, o remédio na ordem escrita e o upstream [gone] refeitos em cópias mktemp, o check-worker.sh inteiro rodado em duas cópias com o leitor da fonte (b) (verde com o fixture de hoje, vermelho com o campaign no fixture) e --red com o R18 vermelho no head; árvore limpa no 67fb6f9; nota A em todo critério, nenhum achado de severidade e um lote de LOW (R18); as letras sobem contra a r7 (Error Handling e Overall de B para A), com 998d077 e af6b320 atrás
reviewed_head: 67fb6f9290bab52fdb474dce7765c36de3b8fc1b
---

# Review — rodada r8 — O worker orquestrador

## TL;DR

Rodada delta do worker sobre `3a77d92..67fb6f9` (R16, R17, a ADR em `a8b09ee` e o handoff em `67fb6f9`), pela régua do dono das 20:30.
O MEDIUM da r7 (R16), os cinco LOW (R17) e a decisão do dono das 23:15 fecharam como os parágrafos prometiam, refeitos por fora do sensor.
Nenhum CRITICAL, HIGH nem MEDIUM de confiança: nota A em todo critério.
Dois LOW novos, ambos no delta, viram o lote R18, que não segura a nota. Nada foi consertado aqui.
O R18 cai depois do `reviewed_head:` e fora da pasta da missão, então o `pr-ready` pede uma rodada que releia o head (pendência 1).

## Nota da rodada

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | A | O delta de código é comentário no `bin/sdd-worker`, dois mutantes e a família `discarded: `; todo símbolo novo tem leitor (Bucket A vazio) e o `shellcheck -S warning` passa limpo nos três arquivos. |
| Type Safety | A | Nenhuma linha executável do `bin/sdd-worker` mudou no delta, e o mundo da r7 refeito em cópia dá as mesmas linhas inteiras e os mesmos rc (US$ 85.00 com o worktree vivo, US$ 0.00 depois). |
| Error Handling | A | O achado #1 da r7 fechou como o R16 dizia: o limite e o remédio estão nos quatro lugares, o remédio na ordem escrita dá `no room` antes da remoção e a soma certa depois, e o upstream `[gone]` para `budget`, `level` e `next` com rc 1, nomeando-o. |
| Security | A | Os verbos que concedem não mudaram no delta, e um upstream `[gone]` sob uma delegação assinada em `pr` faz o `level` responder `assisted — unread`, rc 1, nunca o nível assinado. |
| Performance | A | Nada executável mudou; a família nova monta um repo com três worktrees, e o `check-worker.sh` inteiro rodou em 82 s nas duas cópias em paralelo. |
| Test Coverage | A | A família `discarded: ` está verde no head e os dois mutantes `mut_WORKER_discarded_*` morrem por `--only` numa cópia limpa; a promessa do cabeçalho, de ficar vermelha no dia da fonte (b), não se cumpre (achado #1), e esse LOW está no lote R18, que pela régua não segura a nota. |
| Documentation | A | Os achados #2 a #6 da r7 e a sexta parte fecharam como o R17 dizia, e o ADR, o template e o `docs/pipeline.md` contam os três gastos; sobra a frase irmã do comentário do `cmd_budget` (achado #2), no lote R18. |
| **Overall** | **A** | Nenhum CRITICAL, HIGH nem MEDIUM de confiança: o MEDIUM da r7 fechou pelo R16, os cinco LOW pelo R17, e os dois LOW novos vão ao lote R18. |

## Movimento contra a r7

Na r7, duas linhas abaixo de A (Error Handling e o Overall, ambas pelo MEDIUM do `budget`); aqui,
nenhuma. Error Handling e Overall sobem de B para A, nenhuma letra desce, e há commits de conserto
atrás da subida: `998d077` (R16) e `af6b320` (R17), mais `a8b09ee`, da sessão orquestradora, na ADR.
O laço anda, e esta é a primeira rodada da missão sem nada que segure a nota.

## Relatório da skill

- **Round:** verificação sobre `3a77d92...67fb6f9` (`base=` colado do `40-review-r7.md`,
  `git merge-base --is-ancestor` rc 0, os achados abertos da r7 lidos da tabela dela, codereview
  2.30.1). Não rodou inteira.
- **Secrets Detection:** PASS, 0 linhas (`scan_secrets.sh`, regex e gitleaks, 13 arquivos, 586
  linhas acrescentadas, nenhum erro).
- **Fase B:** três arquivos de código (`bin/sdd-worker`, só comentário no delta; `tests/check-worker.sh`;
  `tests/check-mutation.sh`), lidos inline pela sessão, como a skill manda com até três. A varredura
  de código morto também foi inline: as duas funções e as sete globais novas do sensor (`dn`,
  `disc_is`, `discarded_missing`, `DUP`, `DISC_*`, `SETC`, `BUDC`) e os dois mutantes têm leitor
  (Bucket A vazio).
- **Verificador:** um agente sobre os nove arquivos de prosa (43 unidades, 213 linhas), relançado uma
  vez, como o contrato manda quando o `Units read:` fica abaixo do que recebeu: voltou com 38 e depois
  40 de 43, juntando unidades vizinhas do handoff (28 e 29, 95 a 97, 104 e 105, 123 a 127). Os nove
  arquivos tomaram então o fluxo de hoje, feito inline pela sessão sobre o diff inteiro deles, como
  na r7, não por um agente por arquivo, para manter o custo de uma rodada delta. As duas passadas
  não acharam nada contradito; o que trouxeram está em "O que foi refutado" e em "Achados fora de
  escopo".
- **Fora do verificador:** o `40-review-r7.md`, o relatório da rodada anterior, cujas afirmações
  datam do `3a77d92`. Os achados dele fecham em "O que virou incremento", refeitos aqui.
- **Cost footprint:** dois verificadores sonnet (cerca de 312 mil tokens somados), nenhum agente por
  arquivo, Fases A, B, B2 e C no modelo principal; quatro corridas do `check-worker.sh` em cópias (as
  duas da fonte (b) e as duas do `--only`).

## Achados da rodada

| # | Severidade | Achado | Onde |
|---|---|---|---|
| 1 | LOW | O cabeçalho da família `discarded: ` promete que, no dia em que uma fonte achar as duas missões ("the session line of the ledger carrying campaign:"), o mundo dela fica vermelho, e o handoff repete a promessa. Para essa fonte, a que o dono escolheu, não fica: as linhas de ledger que o fixture escreve (`spent`) não levam `campaign`, então um `budget` que também soma por `.campaign` responde no fixture o mesmo que hoje, e a família segue verde enquanto as quatro declarações passam a descrever um limite que a fonte fechou | `tests/check-worker.sh:453` (Declared limits of R69), `tests/check-worker.sh:4791` (o `spent` do fixture), `docs/handoffs/20261117-o-worker-orquestrador/20-handoff-exec.md:95` |
| 2 | LOW | Frase irmã da contagem de gastos que o R16, o R17 (c) e o `a8b09ee` mudaram em três lugares: o comentário do `cmd_budget` ainda diz que a campanha termina "never past the one signed", contradito pelos Declared limits do mesmo comentário (linhas 759 e 760, o excesso do runner) e pelo parágrafo do R16 (770 a 772, a missão que o `budget` não acha), e pelo `docs/pipeline.md:2000`, que conta os três gastos | `bin/sdd-worker:757` (`cmd_budget`) |

### Reprodução

- **#1:** duas cópias do head (`git clone` em scratchpad, `67fb6f9`), cada uma com o leitor da fonte
  (b) posto no `cmd_budget` (o `select` do jq passa a admitir também `.campaign == $cid`, com `cid`
  lido do `campaign:` da delegação). Antes, um mundo de sanidade com o campo no ledger provou que o
  leitor acha a missão largada: depois do `git worktree remove`, `no room — campaign US$ 85.00 of
  115.00 …`, onde o código de hoje dá US$ 0.00. Na cópia A, só com o leitor: `tests/check-worker.sh`
  rc 0, `ok    discarded: …`, 67 probes verdes. Na cópia B, com o leitor e as três linhas do fixture
  levando `campaign: "di-gone"` (`spent … | jq -c '. + {campaign: "di-gone"}'`): rc 1, `FAIL
  discarded: …`, com `closed removed: … 'campaign US$ 102.00 of 200.00 — 2 mission(s) …' (want …
  17.00 …)`, e nenhuma outra família vermelha. Hoje o campo não muda nada: o `budget` não o lê.
- **#2:** `grep -n 'never past the one signed' bin/sdd-worker` → `757`; no `docs/pipeline.md`,
  em `templates/delegation.md` e na ADR 0022 a frase correspondente conta os três gastos.

## Incrementos de conserto (R<n>)

| R<n> | Achado | Check escrito no checkpoint |
|---|---|---|
| R18 | #1 e #2 (lote de LOW) | `o=$(bash tests/check-worker.sh 2>&1); a=$(grep -c '^  ok    discarded: ' <<< "$o"); b=$(sed -n '/^# --- R69:/,/^# --- verdict/p' tests/check-worker.sh); c=$(grep -cF 'campaign: "di-gone"' <<< "$b"); d=$(grep -c 'never past the one signed' bin/sdd-worker); e=$(grep -cF 'R18 da r8' KAIZEN_LOG.md); f=$(grep -c 'dezessete .R<n>.' KAIZEN_LOG.md); test "$c" -ge 1 && test "$e" -ge 1; echo "$a $? $d $f"` → `1 0 0 0` |

Nasceu vermelho no head: `check-checkpoint.sh --red` imprime `1 1 1 1` para o R18. O R18 não
acrescenta linha `ok` a família nenhuma; a `discarded: ` continua tendo de imprimir uma.

## O que virou incremento

- **#1 e #2 viraram o lote `R18`**, com Check de comando e a suíte, sem passada de sabotagem nem
  mutante (régua do dono, item 3):
  - (a) as três linhas de ledger que o fixture da R69 escreve levam `campaign: "di-gone"`, como o
    runner as escreverá pela direção do dono: hoje o `budget` não lê o campo e as respostas fixadas
    ficam as mesmas, e no dia em que o leitor da fonte (b) entrar a família fica vermelha, que é o
    que o cabeçalho e o handoff já dizem (a cópia B da reprodução é exatamente esse conserto);
  - (b) o comentário do `cmd_budget` deixa de dizer "never past the one signed" e passa a dizer, como
    o `docs/pipeline.md`, que a campanha só passa do assinado pelos três gastos dos Declared limits,
    sem tocar a frase "never passes the signed" (linha 755), que a família `ceiling: ` lê;
  - (c) consequência do próprio lote, não achado: o `KAIZEN_LOG.md` passa a contar dezoito `R<n>`,
    com "R18 da r8" na lista por rodada.

**Achados da r7 e a decisão das 23:15, fechados pelos consertos e conferidos aqui:**

- **#1 → R16, `998d077`.** O limite e o remédio estão nos quatro lugares (cabeçalho do
  `campaign_set`, comentário do `cmd_budget`, Declared limits do `docs/pipeline.md`, seção do teto no
  `templates/delegation.md`), e a declaração diz o que o código faz, refeito num mundo próprio: com o
  worktree vivo, `campaign US$ 85.00 of 200.00 — 1 mission(s) …`, rc 0; o branch `fix/l1` ainda
  carrega a missão e o `origin/main` não, e nenhum branch além do upstream é lido. O remédio na ordem
  escrita (teto de 200 trocado por 115 antes da remoção) dá `no room — … US$ 85.00 of 115.00 leaves
  US$ 30.00 …`, rc 1, o lado seguro, e depois da remoção `US$ 0.00 of 115.00`, rc 0, o mesmo resto de
  antes; na ordem inversa a soma fica menor sob o teto antigo (`US$ 0.00 of 200.00`). O ledger do
  runner não sabe de campanha (`grep -c campaign bin/sdd` → `0`). A família `discarded: ` compara a
  linha inteira e o rc, então qualquer mudança na resposta do `budget` nesse mundo a deixa vermelha;
  o que não a deixa é a fonte (b) com o fixture de hoje (achado #1). Os dois mutantes
  `mut_WORKER_discarded_*` morrem por `--only … check-worker.sh` numa cópia limpa (controle verde,
  mutante rc 1). O item do `TODO.md` está aberto com a direção do dono, e a catraca está em 91.
- **#2 → R17 (a), `af6b320`.** As três linhas do `docs/pipeline.md` são as três grafias de
  `BASE_WHY` no `base_copies`. O `[gone]` refeito num clone cujo branch acompanha `origin/feat`,
  apagado e podado: `* feat refs/remotes/origin/feat [gone]`, e `budget` (`no spend — the upstream
  refs/remotes/origin/feat of … does not read: git ls-tree … failed (rc 128)`), `level` sob
  delegação assinada (`assisted — unread: …`) e `next` (`stop - - — unread: …`) saem com rc 1.
- **#3 → R17 (b).** O comando está ao lado da medida no comentário do `cmd_next` e no parágrafo do
  `next`; rodado sobre a lista salva às 00:00 (`prs.json`), imprime `0 of 161 merged, 162 in all`,
  e a frase que o `reuse: ` lê segue no parágrafo.
- **#4 → R17 (c), e `a8b09ee`.** O template, o parágrafo do teto duro do `docs/pipeline.md` e a ADR
  0022 (§8 e Consequences) contam os três gastos; a irmã que ficou é o achado #2 desta rodada.
- **#5 → R17 (d).** A linha do R11 no handoff diz "a mesma lacuna".
- **#6 → R17 (e).** O cabeçalho do sensor diz `R63 to R68`, com uma frase própria sobre a R68.
- **Sexta parte → R17 (f).** O `KAIZEN_LOG.md` conta dezessete `R<n>` (2+2+1+5+3+2+2 pelas rodadas).
- **Decisão das 23:15 → `e59e163`.** A fonte é (b), o item do `TODO.md` leva essa direção, o R16 só
  declara, e o handoff tem a linha em "Riscos e não-feitos".
- **Grafias antigas procuradas** em `bin/`, `tests/`, `commands/`, `docs/` (fora os handoffs, que são
  registro), `templates/`, `KAIZEN_LOG.md`, `CONTEXT.md` e `README.md`: "só passa do assinado pelo
  que o runner gasta", "dois gastos" e "quinze `R<n>`" dão zero; em inglês, "only by what the
  runner", "only by the phase" e "two spends" dão zero, e "never past the one signed" dá uma, a do
  achado #2. Nenhuma interface de verbo mudou no delta.

## O que foi refutado

- **"O `[gone]` do `docs/pipeline.md:1864` não tem saída salva"** (verificador, LOW). A afirmação
  vale: refeita nesta rodada, com a saída acima (o `%(upstream)` ainda impresso, `git ls-tree` rc 128).
- **"A frase do handoff `porque existe pelo R16` dá a origem errada do R17"** (verificador, LOW form,
  `20-handoff-exec.md:117`). O sujeito de "existe" é a r8 ("Ela confere também o lote R17, porque
  existe pelo R16"): a r8 existe por causa do R16, e o lote só é conferido por uma rodada que existe
  por outro motivo, que é a regra 2 da régua do dono (nota `REVIEW`). A origem do R17 está certa na
  linha 96 do mesmo arquivo e na linha 50 do checkpoint.
- **"O remédio do R16 para o `budget` antes da hora"** não é defeito: assinar o teto menor com o
  worktree vivo conta o gasto duas vezes por um instante e dá `no room`, rc 1, que é o lado seguro, e
  a ordem inversa é a que deixa a soma menor sob o teto antigo.
- **"O `level` não para num upstream `[gone]`"** com a delegação sem assinatura: ele responde
  `assisted — unsigned`, rc 0, antes de ler o conjunto, o lado seguro; assinada, para com rc 1. A
  frase "budget, level and next stop" é do R12 e já valia assim.

## Achados fora de escopo

Nenhum registrado no `TODO.md` nesta rodada. Citados, fora do delta ou de forma:

- As âncoras `bin/sdd-worker:1210` (`cmd_pr_ready`) e `:690` (`campaign_set`) do `TODO.md` andaram 8
  e 3 linhas com o `af6b320`, dentro da tolerância do `check-todo.sh` (rc 0, every anchor on target).
  Forma, e o R18 vai mexer no `bin/` de novo: o executor roda o `check-todo.sh` antes do commit.
- `docs/pipeline.md:1863` diz que o upstream que não lê para os verbos "naming it", e a grafia do
  `for-each-ref` não tem ref a nomear; o parágrafo das três linhas (1967 a 1969) já qualifica. Forma,
  texto de antes do delta.
- O `commands/sdd-worker.md` não leva o remédio do R16 a quem recebe o `next-stop` de um PR fechado
  sem merge. A sessão nunca remove worktree ("Never"), e o remédio está no template que o dono assina;
  o fail-open de fundo já está aberto no `TODO.md` (item do R16). Não entra pela régua D15.

## Pendências / Decisions for a Human

1. **O R18 compra uma rodada.** O item `review` do `pr-ready` exige que todo commit depois do
   `reviewed_head:` toque só a pasta da missão (`bin/sdd-worker:1187`), e o R18 mexe em
   `tests/check-worker.sh`, `bin/sdd-worker` e `KAIZEN_LOG.md`. Depois dele, o `pr-ready` responde
   `not-ready review` até uma rodada reler o head. Duas rotas:
   - (a) o executor fecha o R18, e uma r9 delta sobre `67fb6f9..<head>`, só do lote, regrava o
     `reviewed_head:`, pela mesma régua;
   - (b) o lote fica para depois do merge, e o merge sai sobre esta rodada; o R18 fica `pending` no
     checkpoint que chega à `main`, a linha que o `gate_EXEC` do runner leria se a missão voltasse a
     rodar, e os dois LOW seguem citados aqui.

   Recomendo (a): os dois consertos custam uma sessão leve, e a r9 lê três arquivos.
2. **Seguem as da r7, da r6 e da missão.** A fonte da missão largada é o item do `TODO.md` (o
   `campaign:` na linha `session` do ledger, no `bin/sdd`). O `pr-ready` não lê o corpo de uma revisão
   nem o `local/ci` (item aberto no `TODO.md`). Seguem as pendências do `00-missao.md`: assinar a
   delegação, o pager do kit, o espelho de issues, o `aprovacao:` sob `full`, a rule e o carimbo. O
   merge do PR #414 continua com você.

## Boot da próxima fase

EXEC do `R18`, uma sessão, no worktree `/home/joruge/repos/sdd_agents-worker`, se o dono ficar com a
rota (a). Leia a linha do R18 no `checkpoint.md` e o parágrafo dele em "O que virou incremento"
acima; a reprodução do #1 está em "Reprodução" (a cópia B é o conserto da parte (a)).

- É um lote de LOW: Check de comando e a suíte, sem passada de sabotagem nem mutante.
- Na parte (b), não toque a frase "never passes the signed" do mesmo comentário, que a família
  `ceiling: ` lê, nem a frase do limite e a do remédio que a `discarded: ` lê.
- Rode `shellcheck -S warning` nos arquivos tocados e o `tests/check-todo.sh` (as âncoras do `bin/`)
  antes do commit, não a suíte inteira: a sessão orquestradora a roda no fim.

Se houver r9, ela é do worker, delta, com `base=67fb6f9290bab52fdb474dce7765c36de3b8fc1b` e esta
tabela de achados.
