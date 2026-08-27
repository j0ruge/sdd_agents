# Handoff — rodar a missão 2 da janela de medição

**Data:** 2026-08-27 · **Estado:** a ADR 0005 e o teto da QA estão **implementados e mergeados**;
a missão 2 está **planejada, aprovada e commitada**, faltando um merge para poder rodar.

Auto-contido de propósito. A sessão que ler isto não participou da conversa que o gerou.
Onde há número, ele foi medido.

---

## 1. Comece por aqui

```bash
cd ~/repos/sdd_agents
git log --oneline -1                       # esperado: f01c0bd (ou adiante)
git status --porcelain                     # TEM de sair vazio
./bin/sdd kaizen --series | jq -c '.latest.composition'

cd ~/repos/sales_quote
gh pr view 131 --json state,title | jq -c .        # MERGED? então o § 3 pode rodar
git branch --show-current                  # esperado: SQ-condicoes-pagamento-mesmo-cliente
SDD_HOME=~/repos/sdd_agents ~/repos/sdd_agents/bin/sdd status 20260827-condicoes-pagamento-mesmo-cliente
```

A última linha tem de responder `✓ PLAN plan approved (auto), 1 increment(s)` e
`next phase: TICKET`. Se responder outra coisa, pare e leia o § 5 antes de mexer.

## 2. O que já está feito, e não precisa ser refeito

**No kit (`~/repos/sdd_agents`), tudo mergeado na `main` e empurrado:**

| | |
|---|---|
| `main` | `f01c0bd`, igual a `origin/main` |
| ADR 0005 | **implementada, as três partes** — `60fe724` (recusa de ledger sob `$TMPDIR`), `0a84833` (a série publica a `composition`), `28af7ea` (o juiz lê todos os repos). A linha `Implementation: NOT YET IN THE RUNNER` saiu no último |
| teto de fase | `ee6404e` — conta **sessões**, não voltas do laço. `QA_MAX_ITER * 3` = 9 valia 18 sessões; agora vale 9 (teto superior 10) |
| catálogo de mutação | `158 caught, 0 known gap(s), of 158` |
| carimbo | `e84fd31767aff62bfdb7d9c547f61e9a` — **válido para esta árvore**. Não rode `sdd health` sem necessidade: ele sempre roda o catálogo, 20-50 min, e não tem modo barato |
| catraca | `todo-findings 74` (não se moveu) |
| KAIZEN_LOG | entrada de 2026-08-27 com o antes/depois medido |

**No `sales_quote`:**

| | |
|---|---|
| `develop` | `ed45cda` |
| PR #128, #129 | **mergeados** em 2026-08-26 22:47 — as pendências do handoff anterior caíram |
| PR **#131** | **ABERTO** — `chore/sdd-espelhos-dos-agentes` (`7c7d347`). Sincroniza três espelhos de agente (`sdd-executor`, `sdd-qa`, `sdd-kaizen`) que estavam atrasados. **É o único bloqueio da missão 2** |
| branch `SQ-condicoes-pagamento-mesmo-cliente` | criada **a partir da branch do #131** (não da `develop`), com `a08fed6` — os três artefatos da missão. **Não empurrada** |
| missão `20260827-condicoes-pagamento-mesmo-cliente` | `docs/handoffs/…` — `aprovacao: auto`, 1 incremento, gate PLAN ✓ |

⚠️ A branch da missão sai da branch do #131 **de propósito**: assim ela já carrega os espelhos
certos. Depois que o #131 mergear, o commit `7c7d347` vira ancestral da `develop` e o diff do PR da
missão fica só com a missão. Se o #131 for fechado sem merge, a branch da missão carrega o chore
junto — o que é correto, só não é o desenho pretendido.

## 3. A tarefa: rodar a missão 2

```bash
# 1. mergear o #131 (é o bloqueio)
cd ~/repos/sales_quote && gh pr merge 131 --merge      # ou pela UI

# 2. rodar a missão — TICKET → EXEC → QA → REVIEW → DOCS → PR, sozinho
git checkout SQ-condicoes-pagamento-mesmo-cliente
SDD_HOME=~/repos/sdd_agents ~/repos/sdd_agents/bin/sdd run 20260827-condicoes-pagamento-mesmo-cliente
```

⚠️ **A árvore do kit tem de continuar limpa e sem commit novo durante a corrida.** Linha de ledger
nascida com o kit sujo carrega `kit_dirty: true` e fica fora da série comparável para sempre.

⚠️ **`sdd status` e `sdd phase` rodam os gates**, portanto o `TEST_CMD` inteiro
(`npm test && npm run lint && npm run build`). Não são consultas baratas.

## 4. O que a missão 2 é, em uma tela

**Defeito:** `packages/frontend/src/components/quote/SalesQuoteForm.tsx:638` escreve
`condicoesPagamento` sem guarda de posse. Reaplicar o **mesmo** cliente (Revalidar, ou recarregar
com rascunho restaurado) troca a escolha do consultor pelo `payment_terms` do ERP, em silêncio. A
linha vizinha `:636` protege `contatosAdicionais` com `mesmoCliente`; a `:638` ignora a mesma guarda.

**As quatro armadilhas medidas no planejamento**, todas escritas no `01-plano.md` § Contexto
verificado — se você as redescobrir, o plano falhou:

1. **A âncora do `TODO.md` (`:669`) está errada por 31 linhas** e hoje aponta para um **sósia**: um
   segundo `const mesmoCliente`, de outro efeito, cujo `condicoesPagamento` vizinho (`:688`) lê
   outra expressão. O defeito real é a `:638`.
2. **`mesmoCliente` não conserta o bug.** No primeiro autofill o ref é `null` e o handler de
   digitação já gravou o CNPJ (`:606-609`), então ele responde `true` tanto para "cotação nova"
   (que precisa APLICAR) quanto para "rascunho restaurado" (que precisa PRESERVAR). A direção de
   uma linha escrita no `TODO.md` está errada nesse ponto.
3. **`applyJrcApiCustomerData` é `useCallback(..., [])` com deps vazias de propósito** (`:617`).
   Ler `wasRestored` direto captura o `false` inicial para sempre → tem de ser **ref**. E
   acrescentar às deps re-dispara o efeito de autofill (`:649-691`), que é o oposto do objetivo.
4. **`npm run lint` está dentro do `TEST_CMD`.** O closure ingênuo passa no teste e **reprova o
   gate**.

**A guarda escolhida pergunta um FATO, nunca um valor** — comparar com o default não serve porque o
default é `"30 dias"` (`lib/quoteFormDefaults.ts:38`), valor de negócio comum:

```
aplica o payment_terms  ⟺  ownerAnterior === null && !wasRestoredRef.current   (primeira vez)
                        OU  ownerAnterior !== cnpjDoCustomer                    (trocou de cliente)
```

`wasRestored` já existe (`:367`) e tem precedente no repo: `useInvarianteTipoFreteAoRestaurar`
(`:414`), escrito pela missão `20260825-frete-cif-fob` para esta mesma classe.

**Sensor:** `packages/frontend/src/test/condicoes-pagamento-ciclo-vida.test.tsx` (novo), 6 regimes,
**3 deles controle**. Molde a copiar: `contatos-adicionais-ciclo-vida.test.tsx`, que já prende os
análogos em `:176`, `:208` e `:387`.

**Fora de escopo, com motivo:** `:688`, `:714` e `:721-722`. Os dois últimos estão na lista de
caminhos **não descartados** como causa-raiz do SQ-98 (a missão 3) — encostar neles agora repete a
armadilha que a M2 já pagou: concluir causa comparando cenários com duas variáveis mudadas.

## 5. ⚠️ A aritmética do veredito, que o plano da janela não previu

Medido no ledger real hoje: **nenhum `kit_sha` da história inteira jamais teve 3 missões com
sessão.** A missão 1 ficou encalhada em `5a82f12` com **1**, e o kit já andou para `f01c0bd`.

O piso do juiz são **3 missões com sessão no MESMO `kit_sha`**. Logo, rodar as missões 2 e 3 agora
põe **duas** no sha novo — `sufficient: false`, `indeterminado` outra vez, por um motivo diferente
do que fechou a janela da primeira vez.

**A decisão tomada (2026-08-27):** rodar a **missão 2 sozinha, como medição de custo**, e só depois
decidir. Ela responde as quatro perguntas que importam — quanto custa hoje uma missão de repo-alvo,
se a QA parou de girar, se o teto segura, e se o REVIEW continua sendo a fase mais cara — e nenhuma
delas depende do veredito. Comprometer ~US$ 250 numa janela de três missões antes de saber se
**uma** ficou pagável é repetir o erro que fechou a janela.

Quem quiser o veredito depois precisa de **três** missões no sha novo, com o kit congelado o tempo
todo. A janela original planejou três e sobraram duas: faltaria inventar a terceira.

## 6. O que NÃO está provado

- **O conserto do teto nunca rodou contra missão real.** Ele foi provado contra um fixture
  construído para pôr voltas e sessões em números diferentes (8 → 4 sessões). A classe fecha na
  missão 2, não antes.
- **O conserto do laço da QA também não.** A missão do kit que o entregou rodou a QA contra código
  já corrigido na mesma branch.
- **A composição da ADR 0005 ainda não teve fatia com mais de um repo.** Hoje `latest` no ledger
  real é uma missão de um repo só — o eixo degenerado que a ADR 0003 descreve.
- ⚠️ **O REVIEW virou a fase mais cara do pipeline** — US$ 32,94 numa sessão na missão do laço da
  QA, mais que os 6 EXEC somados, contra US$ 22,36 na missão anterior. **Ninguém olhou.** É o
  candidato óbvio a próxima missão de kit se a missão 2 não revelar nada maior.

## 7. Armadilhas de operação medidas nesta sessão

- **Editar `bin/`, `tests/`, `templates/` ou `config/` enquanto `sdd health --with-mutation` roda
  invalida o carimbo.** O comando amostra a chave antes e depois e recusa carimbar se a árvore
  mexeu — corretamente. Custou uma edição de comentário revertida. `sdd health` **sempre** roda o
  catálogo: não existe modo barato.
- **Reescrever um `tests/*.sh` com `head`/`cat`/`mv` perde o bit de execução.** Use
  `cat > arquivo` (preserva o modo) ou refaça o `chmod +x`.
- **Verificar um mutante isolado** custa ~1 min em vez dos 20-50 do catálogo: copie
  `bin tests templates config agents` + `CLAUDE.md` + `TODO.md` + `docs/adr` para uma sandbox,
  aplique o `sed` do mutante, confira que ele **aplicou** (`cmp` contra o original) e rode
  `SDD_MUTANT=1 tests/run-all.sh` esperando rc ≠ 0.
- **`gh pr list` sem `--json` devolve vazio aqui**, mesmo com PRs abertos. Use
  `gh pr list --json number,title,state`.
- **Espelho de agente atrasado no repo-alvo** deixa o `sdd preflight` vermelho em
  `agent <nome> stale` e a fase parece travada. Sincronize com `sdd install --force` rodado **de
  dentro do repo-alvo**, nunca com `cp`.
