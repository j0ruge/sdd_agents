# Handoff — implementar a ADR 0005 (o eixo do juiz)

**Data:** 2026-08-26 · **Estado:** a ADR está mergeada e **nada dela está codado**.

Auto-contido de propósito. A sessão que ler isto não participou da conversa que o gerou.
Onde há número, ele foi medido.

---

## 1. Comece por aqui

```bash
cd ~/repos/sdd_agents
git log --oneline -1                       # esperado: b5235dd (merge do PR #25) ou adiante
cat docs/adr/0005-judge-reads-every-repo-with-visible-composition.md
./bin/sdd kaizen --series | jq -c .guard
./bin/sdd kaizen --series --all-repos | jq -c '{latest:.latest.kit_sha,guard:.guard,excluded:.excluded}'
```

As duas últimas linhas respondem **diferente sobre o mesmo arquivo**. Essa diferença é o problema
inteiro.

## 2. O que já está feito, e não precisa ser refeito

| | |
|---|---|
| `main` | `b5235dd` — merge do PR #25 |
| ADR 0005 | mergeada em `6e82acb`, com `Implementation: NOT YET IN THE RUNNER` no cabeçalho |
| ADR 0006 | nascida da missão `20260826-o-laco-da-qa` (a Âncora 3 e a escalada) |
| missão do laço da QA | mergeada, PR #25 — **US$ 85,01, 10 sessões, 0 escaladas, 0 intervenções** |
| catraca | `todo-findings 74` |
| carimbo | `3437945b…`, válido para a árvore da `main` |
| janela de medição | **encerrada** — ver seção 9 de `2026-08-25-janela-de-medicao-design.md` |

## 3. A tarefa: as três partes da ADR 0005

Leia a ADR inteira; o resumo abaixo é índice, não substituto.

1. **`sdd kaizen` lê todos os repos.** O padrão per-repo fica no `sdd autonomy`, cuja pergunta é
   outra ("quanto ESTE repo custou").
2. **A série publica a composição da fatia do eixo** — quantas missões cada repo contribuiu para
   `latest` e para `previous`. É o que torna a parte 1 segura: contaminação vira coisa que se vê.
   ⚠️ **Derive a composição sobre as MESMAS linhas que a guarda admite, não sobre `event: session`.**
   O primeiro rascunho da ADR contou sobre sessões e respondeu "quatro repos"; são **sete** — três
   fixtures só têm linha de escalada. O erro ficou escrito dentro da ADR de propósito.
3. **O runner recusa o ledger real para repo-alvo sob `TMPDIR`.** Limite declarado no cabeçalho da
   guarda: é heurística de **caminho** e é frágil (macOS usa `/var/folders`). Catraca, não fronteira.

**Não decidido pela ADR, e não re-litigue:** o piso de 3 (`KAIZEN_GUARD_FLOOR`) e o eixo `kit_sha`
ficam como a ADR 0003 os deixou. Ler mais repos torna o piso **satisfazível**; não o abaixa.

⚠️ **Tire a linha `Implementation: NOT YET IN THE RUNNER`** do cabeçalho da ADR **no commit que
entregar a última das três partes** — nem antes, nem depois. A própria ADR diz isso.

## 4. 🔧 Conserto PRONTO e AINDA NÃO APLICADO — o teto da QA conta voltas, não sessões

Independente da ADR 0005. Cabe na mesma missão ou em outra.

**Medido:** `attempts["$phase"]` incrementa **uma vez por volta do laço**, antes do primeiro
`run_phase`. O caminho do retry chama `run_phase "$phase" "$LAST_PHASE_SID"` **sem incrementar**.
Com o teto da QA em `$(( QA_MAX_ITER * 3 ))` = 9 voltas, o teto real de **sessões** é 18.

Na missão `20260825-frete-cif-fob` o teto **funcionou** — 9 voltas, exatamente o limite. O que
estourou foi o gasto: 3 voltas compraram retry, virando 12 sessões, ao custo de **US$ 11,27**.

**Direção:** o teto passa a contar sessões, ou o retry incrementa `attempts` também.
**Âncoras em CÓDIGO, porque as linhas se movem** (mudaram duas vezes numa sessão):
`grep -n 'QA_MAX_ITER \* 3' bin/sdd` e `grep -n 'retrying once' bin/sdd` — o segundo devolve
**dois** sítios (`run_phase` e `cmd_retry`), e os dois precisam da mesma decisão.
**Sensor obrigatório:** mutante novo em `tests/check-mutation.sh` — `sdd health` reprova gate sem
mutação no catálogo.

## 5. O que a missão do laço provou, e o que ela NÃO provou

**Provou:** a fase QA caiu de **12 sessões / US$ 73,32** para **1 sessão / US$ 13,24**, e a missão
inteira de US$ 144,88 para US$ 85,01 com metade das sessões.

**Não provou:** a QA rodou contra o código já corrigido na mesma branch. Isso mostra que o conserto
funciona, **não** que a classe está fechada. A prova da classe vem na próxima missão de repo-alvo —
que é a missão 2 da janela.

⚠️ **O REVIEW virou a fase mais cara do pipeline:** US$ 32,94 numa sessão, mais que os 6 EXEC
somados, contra US$ 22,36 na missão anterior. Ninguém olhou para isso ainda.

## 6. A ordem do que vem

1. **Implementar a ADR 0005** (esta tarefa) — torna a janela **contável**.
2. **Aplicar o § 4** (teto da QA), com mutante.
3. **Reabrir a janela** com as missões 2 e 3 do `sales_quote`. Âncoras no § 4 do doc da janela; a
   missão 3 (SQ-98) segue com causa-raiz **desconhecida**, e a `:669` do `SalesQuoteForm.tsx`
   **não** é a causa — a armadilha está no § 3 daquele doc.

## 7. Pendências fora do kit

- **PRs #128 e #129 do `sales_quote` estão ABERTOS**, esperando merge. #128 corta o `push` em
  `develop` no CI (cota de Actions esgotada); #129 põe `MODEL_DOCS="sonnet"`.
- **O CI do `sales_quote` está quebrado por cota de Actions**, não por código: jobs falham com
  `"steps": []`, zero passos, em todas as branches desde 2026-08-24.

## 8. Armadilhas medidas nesta sessão, para não repetir

- **`pgrep -f '<padrão>'` dentro de um laço que espera por `<padrão>` casa a si mesmo.** Um
  esperador `until ! pgrep -f 'bin/sdd run X'; do sleep 30; done` nunca sai: a linha de comando
  dele contém a string. Custou 25 minutos de "ainda rodando" falso. Filtre com `grep -v` ou case
  no binário, não na linha inteira.
- **Números de linha do `bin/sdd` mudam sob os pés** durante uma missão que o edita. Ancore em
  código.
- **`sdd status` e `sdd phase` rodam os gates**, portanto o `TEST_CMD` e o `E2E_CMD`. Não são
  consultas baratas — dois deles estouraram timeout nesta sessão.
- **`sdd approve` recusa em silêncio sem TTY.** `read -r ans || ans=""`, e qualquer coisa que não
  seja `y` é não. Rode num terminal de verdade.
