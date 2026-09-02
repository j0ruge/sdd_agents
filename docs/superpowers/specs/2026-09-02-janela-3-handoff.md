# Handoff — a janela 3: o que a abre, o que a segura, e a missão que a semeia

> Escrito em 2026-09-02, logo depois do merge do PR #34. Sucede
> [`2026-08-30-janela-2-handoff.md`](2026-08-30-janela-2-handoff.md), que fechou o M2.
> **Este arquivo é a sessão anterior falando com a próxima.** Leia a seção 1 e pare de ler se só
> quiser agir.

## 1. Comece por aqui

O kit está **congelado**. A missão `20260901-o-revisor-so-acha` foi mergeada (PR #34), e a próxima
sessão **não é no kit** — é no `sales_quote`. Nesta ordem:

```bash
# 1. o kit tem de estar limpo e na main durante TODA missão do alvo
cd ~/repos/sdd_agents && git switch main && git pull && git status --short   # tem de sair vazio

# 2. sincronizar o espelho de agentes do alvo (dois estão stale)
cd ~/repos/sales_quote && git switch develop && git pull
git switch -c chore/sdd-espelho-do-revisor
SDD_HOME=~/repos/sdd_agents ~/repos/sdd_agents/bin/sdd install --force
SDD_HOME=~/repos/sdd_agents ~/repos/sdd_agents/bin/sdd preflight            # tem de sair verde
# commitar o espelho NO ALVO, abrir PR, mergear em develop

# 3. planejar a missão com o humano presente (grill), depois rodar headless
```

⚠️ **Não rode `sdd kaizen`.** A seção 3 diz por quê, com números. Se quiser inspecionar o juiz,
`sdd kaizen --dry-run` é read-only.

## 2. De onde viemos — o que a missão do PR #34 mediu

`20260901-o-revisor-so-acha` implementou a **D22**: o revisor vira read-only e só acha; o achado
vira incremento `R<n>`; o executor conserta em sessão de contexto zerado; a rodada seguinte
re-julga. 18 incrementos (I1–I4 do plano, F1–F4 do QA, R1–R10 das rodadas), 25 sessões,
3 lançamentos, 4 intervenções humanas registradas. Carimbo de mutação **227 caught of 227**.

**O resultado, pelo instrumento que a própria missão construiu (I1):**

```
review loop US$ 102.39 (61%) · US$ 167.35
```

A hipótese **se confirmou por rodada e se refutou no total**. Preço da rodada caiu 3× (US$ 37,10 e
29,24 na janela 2 → 17,92 / 16,00 / 6,83 / 6,00 aqui) e os achados convergiram a zero
(12 → 8 → 3 → 0, sem CRITICAL nunca, sem HIGH a partir da r3). Mas o laço ficou nos **mesmos 61%**:
o revisor liberado de consertar **acha mais**, e cada achado compra a rodada seguinte. Os alvos da
D22 (mediana ≤ 25%, máximo ≤ 50%) **não foram atingidos** — e é a janela 3 que dá o veredito
formal, não esta medição de uma missão só.

A alavanca que sobrou está nomeada: **quantas linhas `R<n>` a rodada escreve**. A régua de lote da
decisão 6 do grill supôs US$ 1–2 por boot do executor; medido, o boot custou **US$ 5,46**. Está
como pergunta aberta com dono no `CONTEXT.md`.

## 3. Por que NÃO rodar `sdd kaizen` agora — dois motivos independentes

Medido em 2026-09-02 com `./bin/sdd kaizen --series`:

```
guard = {missions_after_change:1, missions_with_session:1, sessions:1,
         floor:3, sufficient:false, degenerate_axis:false}
latest.kit_sha = 4ed8580    previous.kit_sha = 4e6a47f     ← ambos: 1 missão, 1 sessão, repo do KIT
```

**(a) O veredito já está escrito.** O piso é 3 e há 1. O verbete *Guarda das 3 missões* e o prompt
do runner (`bin/sdd:1622`) obrigam `indeterminado` quando `sufficient` é falso — e o
`gate_KAIZEN` **reprova** veredito diferente disso (`bin/sdd:5890-5894`). Mas `cmd_kaizen` **nunca
lê `guard.sufficient`**: abre a sessão **opus** do mesmo jeito. É pagar por uma resposta conhecida.
Além disso o sha julgado seria `4ed8580` — a sessão do publisher desta mesma missão, uma só, do
próprio kit —, que é o eixo degenerado que o ADR 0003 existe para impedir.

**(b) Ele contamina, e não pela porta que se espera.** A *linha de ledger* do kaizen é inócua: a
série parte por `.phase != "KAIZEN"` (`bin/sdd:5730-5731`) e ela cai em `excluded.meta`. Quem
contamina é o **commit**: a sessão escreve e commita quatro artefatos (`bin/sdd:1628`,
`agents/sdd-kaizen.md:204-208`) e `cmd_kaizen` **não cria branch** — `ensure_mission_branch` só tem
dois chamadores, `cmd_run` e `cmd_retry` (`bin/sdd:3133-3134`), e `warn_if_on_base_branch` só
avisa. Rodado da `main`, ele commita na `main` e move o eixo. **Quando chegar o dia, rode-o de uma
branch.**

## 4. As regras da janela — cada uma confirmada no código

- **O eixo só existe quando uma linha de ledger o nomeia.** Hoje **nenhuma** linha carrega o sha
  desta `main`: a janela 3 materializa na primeira sessão do `sales_quote`. Consequência prática:
  commit no kit **antes** dela apenas desloca o sha; commit **depois** parte a janela em dois e o
  piso de 3 não fecha em nenhum dos dois.
- **O piso é `missions_with_session`, não `missions_after_change`** (`bin/sdd:5742`): missão que só
  escalou conta como missão mas não comprou observação. Missão que termina `blocked` com
  diagnóstico **conta** para o piso.
- **Árvore suja no kit durante um `sdd run` do alvo** carimba `kit_dirty:true` e tira a linha da
  série **para sempre** (`kit_dirty` conta untracked).
- **`kit_sha` sai do `$SDD_HOME`** (`autonomy_kit_stamp`, `bin/sdd:2159-2161`). Se o `$SDD_HOME` do
  alvo não for um checkout git, as linhas nascem `kit_sha:null` e ficam fora da série.

## 5. A missão que semeia a janela 3

**O residual do SQ-98** — `TODO.md:341` do alvo, âncora `SalesQuoteForm.tsx:357`:

> *"O rascunho restaurado ainda entrega o SQ-98 inteiro, e a premissa que o excluiu do escopo é
> falsa."*

Reprodução **medida no navegador**: rascunho com `condicoesPagamento: "A VISTA"` → o select exibe
`30 dias`, o Resumo imprime `A VISTA`, e salva `A_VISTA`. Direção escrita: sanear na hidratação com
`mapFormaPagamentoErpToForm`.

⚠️ **O SQ-98 principal já foi consertado** — missão `20260830-a-tela-que-mente-o-pagamento`, ticket
SQ-114, PR #137 mergeado. A causa-raiz medida não era o `SalesQuoteForm.tsx:669`: a JRC devolve
`payment_terms` cru, nenhum rótulo casa, o `<select>` controlado pinta a primeira opção. **O banco
sempre gravou certo**, e por isso o bug caiu de Data-Loss para Trust-Damage. O que ficou de fora
foi o caminho do rascunho legado do `localStorage`, excluído do escopo citando a R-022 — e **essa
premissa foi refutada por medição** (a `migrarRascunhoPersistido` só migra `embarcacao`; a R-022 foi
revertida na SQ-22).

**Levar ao grill:**

- os dois achados **`✅ LIVRE`** que o diagnóstico do SQ-98 desimpediu e que tocam o mesmo campo —
  `TODO.md:112` (ramo `notFound` devolve o pagamento ao default sem guarda, `:693`) e `TODO.md:141`
  (sair do CNPJ incompleto apaga a condição escolhida, `:856`, o quarto escritor). Decidir se
  entram nesta missão ou na seguinte;
- **a catraca**: `SalesQuoteForm.tsx` está congelado em **1808 linhas** e subiu três vezes seguidas
  (`TODO.md:218`). Esta missão o toca — a folga é o primeiro risco a medir;
- `JIRA_ENABLED=true` (projeto SQ, board 51): a fase TICKET roda e abre issue;
- `gate_QA` **sem bloqueio herdado**: 18 bugs no registry, **zero `open`**, nenhum
  `Closable by: human`.

**Fora de escopo, e nomeado:** `TODO.md:360` (modalidade desconhecida descartada em silêncio, sem
toast nem telemetria) é **decisão de produto**, não regressão — vai para as pendências.

## 6. Estado medido dos dois repos (2026-09-02)

| | kit `sdd_agents` | alvo `sales_quote` |
|---|---|---|
| branch | `main`, árvore limpa | `develop` @ `143a4e4`, árvore limpa |
| espelho `.claude/agents/` | fonte | ⚠️ `sdd-executor.md` e `sdd-reviewer.md` **stale** |
| backlog | 109 achados (catraca `todo-findings`) | 22 achados `- [ ]` + ~90 seções do gênero antigo |
| suíte | 866 asserções, catálogo 227/227 | `npm test && npm run lint && npm run build`; e2e 90/28, piso 82 |
| perguntas abertas | 8 no `CONTEXT.md`, 5 com dono | — |

## 7. O que fica de fora desta janela, e por quê

- **Qualquer missão de kit.** Cada uma move o sha e reabre a contagem. As cinco perguntas abertas
  do `CONTEXT.md` (régua de lote, famílias da r3, retrofit graphify, rota de pendência, custo do
  kit sobre si mesmo) **esperam o veredito** — é a triagem do `sdd kaizen` que as pega.
- **O retrofit lean na skill `graphify` do `sales_quote`** (0.2.0, intocada desde 2026-08-24): é
  trabalho no alvo e não move o sha do kit, mas o destino tem ambiguidade registrada — o
  `CLAUDE.md` roteia lição **sobre a ferramenta**, e o payload são lições de **bash**.
- **Fechar SQ-98 e SQ-80 no Jira** — pendência humana registrada no `50-pr.md` da SQ-114, com a
  ressalva de que o SQ-98 fecha para toda escrita nova e **não** para o rascunho legado, que é
  justamente a missão da seção 5.

## 8. Correções que esta sessão registrou — erros pagos, não repita

- **`--phase X` força o ponto de partida e o runner SEGUE em frente**; não isola a fase. Foi assim
  que a DOCS emendou sozinha depois da r4.
- **A ordem antes do PR é `DOCS → sdd health → sdd run`.** A DOCS commita achados no `TODO.md`, e
  isso move o `tests/health-baseline.txt`, que está na chave do carimbo de mutação.
- **Para matar o runner, use o PID literal do líder do `setsid`** (`kill -TERM -- -<pgid>`):
  `pgrep -f 'bin/sdd run…'` casa o **próprio shell** que o executa e derruba o grupo errado.
- **A referência à D20 no verbete `Janela de medição` estava errada** e foi corrigida no mesmo
  commit deste arquivo: as três missões que a D20 nomeia **já rodaram** na janela 2. A janela 3
  precisa de três novas.
