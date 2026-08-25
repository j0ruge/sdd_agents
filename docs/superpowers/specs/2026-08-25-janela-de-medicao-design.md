# A janela de medição — o primeiro veredito do juiz do kaizen

**Data:** 2026-08-25 · **Estado:** Fase 0 **executada** por este commit (branch
`chore/abre-a-janela-de-medicao`). O eixo da medição é o merge dele na `main`. Fases 1-3 pendentes.

Este documento é auto-contido de propósito. A sessão que o ler não participou da conversa que o
gerou e não precisa dela. Leia inteiro antes de agir.

---

## 1. Onde o repo está

| | |
|---|---|
| `main` | `42e5845` — merge do PR #22 |
| suíte | verde (`tests/run-all.sh`, 656 asserções) |
| catálogo de mutação | `148 caught, 0 known gap(s), of 148` |
| carimbo | `192647c0…`, **válido** para a árvore commitada |
| catraca do backlog | `todo-findings 74` |

O PR #22 fechou os três defeitos que o piloto M2 expôs no kit, mais uma rodada de revisão que
derrubou dois dos consertos (o `DRY_RUN` da guarda do kit e o pré-cheque do `sdd close`). Nada
disso está pendente.

## 2. A decisão, e a medição que a motivou

**Decidido: congelar o kit e rodar 3 missões de repo-alvo sobre o MESMO sha, para o juiz do
kaizen emitir o primeiro veredito da vida dele.**

O motivo não é opinião. `./bin/sdd kaizen --series` responde:

```json
"guard": { "missions_after_change": 1, "floor": 3,
           "sufficient": false, "degenerate_axis": true }
```

E o ledger inteiro (`~/.sdd/autonomy-log.jsonl`, 110 linhas, 18 missões distintas):

| | |
|---|---|
| kit_shas com 1 missão | **97** |
| kit_shas com 2 missões | 1 |
| kit_shas com **3+** (o piso) | **0** |
| "latest" que o juiz enxerga | `671d432`, de 2026-08-19 — 65 commits atrás da `main` |

**O juiz nunca produziu um veredito. Nem uma vez.** Sete missões do kit sobre si mesmo mergeadas,
e a única coisa que poderia dizer se ajudaram responde `indeterminado`.

**Por que — e não é o que parece.** Não é cadência de missão. Durante uma missão DO KIT o sha muda
entre as linhas do ledger: `autonomy_kit_stamp` lê o HEAD na hora de escrever a linha, e a fase
EXEC commita o tempo todo. Daí 98 shas para 18 missões. Missão de **repo-alvo** é estável —
`sales_quote` gerou 1 sha para 2 linhas. O eixo funciona; só que o kit rodou **11 missões sobre si
mesmo e 1 sobre repo de cliente**:

| repo | missões no ledger |
|---|---|
| `sdd_agents` (o próprio kit) | 11 |
| `clone` + `manual-*` (fixtures) | 6 |
| `sales_quote` (trabalho real) | **1** |

O problema é a **prática**, não o desenho: o kit muda mais rápido do que se mede. É exatamente o
que o `CLAUDE.md` proíbe — *"Sem número, não é kaizen — é opinião."*

## 3. ⚠️ O achado sobre o SQ-98 — leia antes de planejar a missão 3

A pergunta era: o SQ-98 já foi diagnosticado ou resolvido na última sessão do `sales_quote`
(`20260825-cif-forma-pagamento`, o piloto M2)?

**Resolvido: não.** `SQ-98` está em *"Tarefas pendentes"*, a linha continua intocada, nenhum
commit a toca.

**Diagnosticado: TAMBÉM NÃO — e a leitura fácil está errada.** A última sessão achou um defeito
**vizinho**, no mesmo campo, e o registrou no `TODO.md` do `sales_quote`:

```js
// packages/frontend/src/components/quote/SalesQuoteForm.tsx:668-669
contatosAdicionais: mesmoCliente ? prev.cliente.contatosAdicionais : [],   // protegido
condicoesPagamento: erpCustomer.payment_terms || prev.condicoesPagamento,  // NAO protegido
```

É tentador ler a `:669` como a causa-raiz do SQ-98. **Não é.** A prova é uma linha: o select é
**controlado** — `packages/frontend/src/components/quote/CondicoesSection.tsx:268` faz
`value={formData.condicoesPagamento}`, o mesmo estado que a `:669` sobrescreve. Se a `:669`
trocasse o valor, **a tela trocaria junto**; o sintoma inteiro do SQ-98 é tela e valor gravado
**divergirem em silêncio**.

Mesmo campo, dois bugs diferentes. A causa-raiz do SQ-98 segue **desconhecida** — e o próprio
ticket já descartou o mapa (`LEGACY_TO_CANONICAL` em `lib/api/adapters/enums.ts` está correto).

Outros caminhos que também escrevem nesse estado, e que a investigação ainda não descartou:
`SalesQuoteForm.tsx:745` (`blocked=true` força `ANTECIPADO`) e `:752-753`
(`customer?.payment_terms || openingFormData.condicoesPagamento`).

**Esta é a armadilha que a M2 já pagou uma vez:** ela concluiu que CIF causava o pagamento errado
porque comparou cotações em que **duas** variáveis mudaram (CNPJ e tipo de frete). A refutação
está no `TODO.md` do `sales_quote`, preservada de propósito. Não repita atribuindo o SQ-98 à
`:669` sem medir.

## 4. As três missões — todas em `~/repos/sales_quote`

O `sales_quote` é o **único** repo-alvo real instrumentado hoje (`.sdd/` existe só nele e no kit).
Está em `develop`, `JIRA_ENABLED=true` (projeto SQ, board 51), `TEST_CMD="npm test && npm run lint
&& npm run build"`, `E2E_CMD="npm run e2e"`.

| ordem | missão | âncora | estado |
|---|---|---|---|
| 1 | frete digitado sobrevive à troca CIF → FOB e é gravado assim | `packages/frontend/src/lib/api/adapters/cotacao.ts:184` | direção escrita no `TODO.md` |
| 2 | `condicoesPagamento` sobrescrita ao reaplicar o MESMO cliente | `packages/frontend/src/components/quote/SalesQuoteForm.tsx:669` | direção escrita no `TODO.md` |
| 3 | **SQ-98** — pagamento gravado diverge do exibido; PDF ao cliente imprime A VISTA | causa-raiz **desconhecida** | P1/Data-Loss, board 51, 3 pontos, critério de aceite escrito no ticket |

**A ordem é decisão, não acaso:** as duas primeiras têm direção escrita, são baratas e produzem
linhas de ledger cedo; o SQ-98 é investigação de causa desconhecida e é a que pode esticar. No fim,
se esticar, não bloqueia as outras duas.

Os textos completos dos itens 1 e 2 estão no `TODO.md` do `sales_quote`. O item 3 está no ticket:
`acli jira workitem view SQ-98 --fields "key,summary,status,description"`.

## 5. O plano, em quatro fases

**Fase 0 — o último commit do kit (o chore). ✅ FEITA — é este commit.**
Este é o commit que **abre a janela**: o sha resultante é o eixo da medição.
1. Apagar do `TODO.md` do kit os dois itens marcados `RESOLVIDO` (o do `sdd close`, por `5f1798f`,
   e o do stub `- intervention:`, por `cd49351`). A prova por artefato já foi feita:
   `git merge-base --is-ancestor` dos dois responde 0 contra a `main`.
2. Baixar `tests/health-baseline.txt` de `todo-findings 74` para **72**.
3. Escrever no `CLAUDE.md:283` o contra-exemplo medido ao lado da frase *"Regra que a sabotagem não
   consegue quebrar de forma alguma é redundante: remova"* — foi essa frase que autorizou a remoção
   do `DRY_RUN` que virou regressão. Dizer que "não consegui construir o mundo" ≠ "o mundo não
   existe", e que a saída é escrever o probe antes de apagar a regra.
4. `./bin/sdd health --with-mutation` (20-50 min — `tests/health-baseline.txt` está na chave do
   carimbo, então o passo 2 o mata e ele tem de ser reconquistado). Commitar, empurrar.

Medido ao executar: `check-todo.sh` respondeu **72** depois do passo 1, confirmando a aritmética
74 → 72; os dois `git merge-base --is-ancestor` (de `5f1798f` e `cd49351` contra a `main`)
responderam 0 antes de qualquer apagar. A ressalva do passo 3 ficou ancorada em `d4deb35` (a
remoção) e `7cbc8e2` (a volta, no `kit_guard_arm`) em vez de num slug de missão — esta missão foi
planejada pelo `superpowers`, não pelo `sdd-planner`, e não tem `docs/handoffs/`.

**Fase 1 — congelar. Sem sensor novo.**
O instrumento já existe: `./bin/sdd kaizen --series | jq .guard` responde `missions_after_change`.
Se alguém tocar no kit, o número **zera sozinho** e a janela se denuncia. Construir sensor para
isso seria YAGNI — o que existe já mede. Anote o sha da Fase 0 e confira o `guard` depois de cada
missão.

**Fase 2 — as três missões, na ordem da tabela acima.**
Cada uma começa com `sdd-planner` interativo (humano presente) e segue pelo `sdd run`. É aqui que
está o tempo do humano; o dinheiro é pequeno.

**Fase 3 — o veredito.**
`./bin/sdd kaizen` com `sufficient: true` pela primeira vez em 110 linhas de ledger. A partir daí,
a próxima mudança do kit tem número atrás dela.

**Custo estimado pelo próprio ledger:** US$ 3,35 a 9,08 por missão. Três ≈ **US$ 15–25**.

## 6. O que NÃO fazer enquanto a janela estiver aberta

- **Nenhum commit no kit** depois da Fase 0, até as 3 missões estarem no ledger. Um commit zera a
  contagem e a janela recomeça.
- ⚠️ **E a árvore do kit tem de estar LIMPA durante cada missão — árvore suja custa mais caro que
  um commit.** `autonomy_kit_stamp` (`bin/sdd:1448`) deriva `kit_dirty` de
  `git -C "$SDD_HOME" status --porcelain`, que **conta arquivo untracked também**; e a fatia
  comparável do juiz é `on_axis: .kit_dirty == false and .kit_sha != null` (`bin/sdd:3945`). Linha
  nascida suja fica **permanentemente** fora da contagem do piso: o ledger é append-only e nunca é
  migrado. Um commit reabre a janela e a próxima missão volta a contar; um arquivo de rascunho
  esquecido em `~/repos/sdd_agents` durante uma missão do `sales_quote` queima aquela missão para
  sempre. O runner avisa uma vez (`bin/sdd:4365`), mas o aviso sai na saída da missão — não em
  nada que `--series` mostre depois. **Antes de cada `sdd run`:
  `git -C ~/repos/sdd_agents status --porcelain` tem de sair vazio.**
- **Não mexer no piso de 3** (`KAIZEN_GUARD_FLOOR` em `bin/sdd`). Baixá-lo é mudar o kit, o que
  reabre o sha, e ainda por cima baixa a confiança de um número já pequeno.
- **Não atacar os 47 itens de "Sensores que faltam"** do `TODO.md`. É a maior seção por larga
  margem e continuará lá; enquanto o juiz não falar, mais trabalho do kit sobre o kit é mais
  mudança não medida.
- **Não instrumentar um segundo repo-alvo agora.** O primeiro uso num repo novo gasta sessão com
  preflight/config, e isso entraria na medição como se fosse comportamento do kit.

## 7. Dois itens do backlog do kit que atravessam este plano

Achados na varredura que produziu este documento. Nenhum dos dois se resolve aqui — mas ignorá-los
custa sessão.

**`TODO.md:457` — o `RESOLVIDO por` e a catraca não cabem juntos.** O cabeçalho do `TODO.md` manda
o item fechado ficar no arquivo até o PR mergear; o `tests/check-todo.sh` conta `- [ ]` e não
conhece `RESOLVIDO por`, então `todo-findings` não consegue descer na missão que consertou. As duas
últimas missões apagaram na hora (`6136d39`) e a convenção ficou descrevendo outra prática. **A
Fase 0 está executando o apagar-na-hora**, que é o que as duas últimas fizeram — a aritmética
74 → 72 (duas linhas `- [ ]` a menos) está certa, e o item `:457` continua aberto porque a tensão
entre sensor e convenção não muda com isso.

**⚠️ `TODO.md:464` — `sdd kaizen` recusa rodar de um worktree do próprio kit.** A porta "estou no
repo do kit?" (`bin/sdd:2963`) compara `kit_root` (`--show-toplevel` de `$SDD_HOME`) com
`$REPO_ROOT`, e o toplevel é **por worktree**: de um worktree os dois divergem e o comando morre em
*"run it in the kit repo"*. Isso atravessa a **Fase 1 e a Fase 3 deste plano**, que dependem de
`./bin/sdd kaizen --series` para saber se a janela continua aberta e para colher o veredito. Se a
próxima sessão trabalhar num worktree (o fluxo do `superpowers` recomenda worktree), o monitoramento
morre calado. **Rode o `sdd kaizen` do checkout principal**, ou feche o item antes da Fase 1.

## 8. Por onde a próxima sessão começa

```bash
cd ~/repos/sdd_agents
git log --oneline -1                      # esperado: 42e5845 (ou adiante, se a Fase 0 já rodou)
git status --porcelain                    # TEM de sair vazio — ver a regra da árvore suja no §6
./bin/sdd kaizen --series | jq .guard     # missions_after_change diz onde a janela está
grep -n 'RESOLVIDO por' TODO.md           # 6 ocorrências = Fase 0 pendente; 4 = já rodou
```

O `grep` do `RESOLVIDO` conta a prosa do cabeçalho (2 linhas) e o item `:441`, que fala **sobre** a
convenção (2 linhas) — essas 4 ficam para sempre. As outras 2 eram os itens fechados que a Fase 0
apagou.

⚠️ **A Fase 0 NÃO move o eixo, e isso não é falha.** O `latest` do juiz sai do **ledger**, que só
ganha linha quando uma missão roda. Logo depois da Fase 0 o `--series` continua respondendo
`671d432` / `missions_after_change: 1`. O eixo reancora no sha novo quando a missão 1 escrever a
primeira linha dela — não antes.

⚠️ **Rode tudo do checkout principal, nunca de um worktree** — e não é só pelo `sdd kaizen` do §7.
O carimbo de mutação é escrito em `.sdd/logs/mutation-stamp`, que está no `.gitignore`, portanto é
**por checkout**: carimbar de um worktree deixa o checkout principal sem carimbo e o
`health --with-mutation` de 20-50 min é pago duas vezes. Já há artefato de QA sobre exatamente
isso — `docs/qa/bugs/BUG-20260819-stamp-written-where-gate-cannot-read.md` e
`docs/qa/charters/CH-stamp-round-trip-from-a-worktree.md`.

**Antes de implementar qualquer coisa, apresente o que pretende fazer e espere o "sim".** O rumo
está aprovado; cada passo, não.
