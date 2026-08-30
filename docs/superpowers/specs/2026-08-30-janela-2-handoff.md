# Handoff — a janela 2: o primeiro veredito do juiz, e o que fecha o M2

**Data:** 2026-08-30 · **Estado:** planejado com o humano presente (grill de 3 perguntas, decisões
D18–D20 no `CONTEXT.md`). **A Fase 0 é o commit que carrega este arquivo**; o sha do merge dele
na `main` é o **EIXO** da medição. Fases 1–3 ainda não rodaram.

Auto-contido de propósito. A sessão que ler isto não participou da conversa que o gerou. Onde há
número, ele foi medido em 2026-08-30 com o comando ao lado.

---

## 1. Comece por aqui

```bash
cd ~/repos/sdd_agents
git status --porcelain                       # TEM de sair vazio (untracked conta — § 4)
git log --oneline -1                         # o EIXO, ou adiante se a janela já foi contaminada
./bin/sdd kaizen --series | jq -c '{guard, sha: .latest.kit_sha, comp: .latest.composition}'
```

Antes da primeira missão a última linha responde `latest 25029d5 · missions_with_session 1` —
**a Fase 0 não move o eixo** (medido na janela 1, § 8 da spec de 2026-08-25): o `latest` só reancora
quando a missão 1 escrever a primeira linha dela. Depois de cada missão, `missions_with_session`
tem de subir 1, 2, 3 com `sha` = EIXO. Se não subiu, pare e leia o § 4.

## 2. Por que esta é a última peça do desenho

O desenho de 2026-08-14 tem dois marcos (`CONTEXT.md`, verbete *Marco 1 / Marco 2*). **M1** — kit
executa, humano planeja e faz merge — está provado três vezes em repo real (`sales_quote`, PRs
#105, #127, #132). **M2** — kit planeja e executa, humano aprova o plano e faz merge — existe em
código (`sdd kaizen`, I13.3) mas **nunca aconteceu de fato**: as três rodadas do juiz responderam
`indeterminado` por construção. O piso é **3 missões com sessão no MESMO `kit_sha`**
(`KAIZEN_GUARD_FLOOR=3`), e nenhum sha da história inteira chegou a 2:

```bash
jq -sr '[.[] | select(.event=="session" and (.repo // "" | test("sales_quote")))]
  | group_by(.kit_sha) | .[] | "\(.[0].kit_sha)\tmissions=\(map(.mission)|unique|length)\tsessions=\(length)\tdirty=\(map(.kit_dirty)|unique)"' \
  ~/.sdd/autonomy-log.jsonl
# 25d4e1c  missions=1  sessions=7   dirty=[false,true]   ← condicoes-pagamento (SQ-111), 2026-08-27
# 5a82f12  missions=1  sessions=23  dirty=[false]        ← frete-cif-fob (SQ-110), 2026-08-25
# 2d28d13 / 5aa21af    missions=1  sessions=1            ← cif-forma-pagamento (refutada), 2026-08-25
```

Cada missão do alvo caiu num sha diferente porque **o kit mudou entre elas**. O I13.4 (graduação
de autonomia) é o único incremento do desenho nunca iniciado, e a ADR 0003 diz que ele se destrava
**por evidência, nunca por régua menor** — exatamente estas três missões sobre um sha só.

A janela 1 (spec de 2026-08-25) fechou depois da missão 1 por dois motivos medidos, **os dois
consertados desde então**: a QA girava num gate insatisfazível (PR #25, ADR 0006) e o juiz não lia
linha de repo-alvo (ADR 0005, implementada em `60fe724…f01c0bd`). O passo 3 do § 9 dela —
*"Reabrir a janela"* — é o único nunca executado. A missão 2 rodou **sozinha, como medição de
custo** (US$ 68,87, 6 sessões comparáveis, 3 launches, PR #132 mergeado), fora de qualquer janela.

## 3. As três decisões (não re-litigar — o porquê está no `CONTEXT.md`)

| # | Escolha |
|---|---|
| **D18 — o que é "pronto"** | O primeiro `sdd kaizen` com `guard.sufficient: true`, escrevendo `05-verdict.md` sobre o EIXO, **mais** o plano nascido decidido pelo humano via `sdd approve` (ou recusado por escrito). O token do veredito é do juiz: `indeterminado` é admissível, porque a fatia `previous` será só-kit (uma sessão) e um `melhorou`/`piorou` honesto exigiria uma segunda janela |
| **D19 — onde o eixo abre** | Na `main` de 2026-08-30 (`0408639`) **sem mudança de código**; o EIXO é o sha do merge do commit de docs que carrega este arquivo. A missão do custo do REVIEW (39% de todo o gasto) fica para **depois** do veredito — é a primeira mudança do kit que nasce com número atrás |
| **D20 — as três missões** | Duas baratas com direção escrita, e o **SQ-98** por último (§ 5). Todas no `sales_quote` |

## 4. As regras da janela — cada uma confirmada no código, não na prosa

- **`latest` = o sha cuja PRIMEIRA linha aparece por último no ledger** (`shas_in_file_order`,
  `bin/sdd`). Logo, **nenhum `sdd run`, `sdd retry` ou `sdd close` no repo do kit** enquanto a
  janela estiver aberta: qualquer um grava linha com sha novo e rouba o `latest`. `tests/run-all.sh`
  é seguro (exporta `SDD_STATE_DIR`); trabalho manual em branch/worktree do kit é permitido, desde
  que o checkout principal fique limpo e sem `sdd run`.
- **Nenhum commit na `main` do kit** até o veredito. Commit reabre o eixo e a contagem recomeça.
- **Árvore do checkout principal do kit LIMPA em todo `sdd run` do alvo** — `autonomy_kit_stamp`
  deriva `kit_dirty` de `git status --porcelain`, que conta **untracked**, e linha suja fica fora da
  série **para sempre** (ledger append-only). ⚠️ Já aconteceu: a missão 2 nasceu com **7 sessões e
  6 comparáveis** — uma linha `kit_dirty: true` (comando do § 2). Antes de cada `sdd run`:
  `git -C ~/repos/sdd_agents status --porcelain` vazio.
- **Não mexer no piso** (`KAIZEN_GUARD_FLOOR`), não instrumentar um segundo repo-alvo, não atacar
  os 51 itens de "Sensores que faltam" do `TODO.md`.
- **Missão que escala ainda conta** — `blocked`, `app-down`, `handoff-blocked` — se comprou ao
  menos uma sessão (`missions_with_session`). Retomar com `sdd retry`/`sdd run` **não** cria sha
  novo. `sdd close` no alvo **não escreve linha** no ledger (item do `TODO.md`), então é seguro.
- **Contingência:** eixo contaminado (commit na `main` ou linha suja) ⇒ a janela **recomeça** no
  sha novo. As missões já mergeadas mantêm o valor; só a contagem recomeça.
- **Custo:** medido US$ 68,87 (missão 2, pós-consertos) e US$ 144,88 (missão 1, pré-consertos);
  esperado 3 × US$ 70–100 ≈ US$ 200–300; pior caso por missão com os tetos da config
  (`BUDGET_PER_PHASE_USD=15`, `QA_MAX_ITER=3`, `REVIEW_MAX_ITER=3`) ≈ US$ 290. **Uma missão acima
  de US$ 150 ⇒ parar e replanejar com o humano antes da próxima.**

## 5. As três missões — todas em `~/repos/sales_quote`, contra `develop`

| ordem | missão | âncora | por quê / armadilha |
|---|---|---|---|
| 1 | Em modo edit, redigitar o mesmo CNPJ troca a condição de pagamento salva | `packages/frontend/src/hooks/use-posse-condicoes-pagamento.ts:108` | Mesma família da SQ-111, no único regime que ela deixou de fora; direção escrita no `TODO.md` do alvo ("tratar `initialData` como dono, ao lado de *abriu sobre rascunho*") |
| 2 | A invariante do frete imposta no agregado `Cotacao`, não só calculada no frontend | `packages/backend/src/modules/sales-quote/application/commands/criar-rascunho-command.ts:52` | Direção DDD escrita (motivo novo no Shared Kernel ao lado de `validar-condicoes-envio.ts`, imposição no agregado, `ProblemCode` RFC 7807). Backend: não toca o `SalesQuoteForm.tsx`, que está na catraca de 1821 linhas com folga zero |
| 3 | **SQ-98** — pagamento gravado diverge do exibido; PDF ao cliente imprime "À VISTA" | causa-raiz **desconhecida** | P1 Data-Loss, board 51, 3 pontos, critério de aceite no ticket. ⚠️ `SalesQuoteForm.tsx:669` **não** é a causa (§ 3 da spec de 2026-08-25: o select é controlado, e o sintoma é tela e valor gravado divergirem). Caminhos não descartados: `:745` (`blocked=true` força `ANTECIPADO`), `:752-753`, `openingFormData.condicoesPagamento`. **Não** concluir causa comparando cenários com duas variáveis mudadas — foi o erro da missão refutada de 2026-08-25. Terminar `blocked` com diagnóstico é desfecho válido, e conta para o piso |

Os achados `TODO.md:11` (CNPJ incompleto apaga a condição) e `:693` (ramo `notFound`) do alvo
**esperam o diagnóstico do SQ-98** — a expressão que eles tocam está na lista de caminhos não
descartados. Não os escolher antes. O item `TODO.md:33` do alvo (frete CIF → FOB) foi fechado pelo
PR #127 (`971d6f4` é ancestral de `develop`) e sai na Fase 1.

## 6. Fase 1 — preparar o alvo (nenhum commit no kit)

`sdd preflight` compara **todos** os `agents/sdd-*.md` com a cópia em `.claude/agents/` do alvo,
byte a byte, e falha em `agent <nome> stale`. Medido em 2026-08-30: 6 de 7 idênticos, `sdd-kaizen.md`
**stale** (33 linhas — a rubrica `advanced · churned · idle` e a leitura do `launch(es)`).

```bash
cd ~/repos/sales_quote && git switch develop && git pull
git switch -c chore/sdd-espelho-do-kaizen
SDD_HOME=~/repos/sdd_agents ~/repos/sdd_agents/bin/sdd install --force   # só sdd-kaizen.md muda
# apagar o item TODO.md:33 (fechado por 971d6f4): git merge-base --is-ancestor 971d6f4 develop → 0
git commit -am 'chore(sdd): sincroniza o espelho do sdd-kaizen com o kit, e o item fechado sai do TODO'
gh pr create --base develop ...   # mesma forma do #131; merge humano
SDD_HOME=~/repos/sdd_agents ~/repos/sdd_agents/bin/sdd preflight        # UMA sessão paga (≤ US$ 1); rc 0
```

**O runner não sobe o app.** A QA roda `npm run e2e` contra `http://localhost:5173`; desde o PR #28
o gate escala `app-down` (rc 3) em vez de queimar sessões, mas escalar ainda custa a volta. Antes de
cada `sdd run`: `docker compose up -d postgres`, `npm run dev:backend`, `npm run dev`,
`npm run dev:fake-jwks --workspace=packages/backend`, e `curl -sf http://localhost:5173`.

## 7. Fase 2 — o laço por missão

1. **Pré-voo:** `git -C ~/repos/sdd_agents status --porcelain` vazio **e**
   `git -C ~/repos/sdd_agents rev-parse --short HEAD` = EIXO; app no ar.
2. **Planejar** com o `sdd-planner` interativo (humano presente) em `~/repos/sales_quote` →
   `docs/handoffs/<slug>/00-missao.md` + `01-plano.md` + `checkpoint.md`. PLAN-AUTO 5/5 ✅ ⇒
   `aprovacao: auto` (como a missão 2 fez); senão `sdd approve <slug>` (precisa de TTY:
   `! echo y | sdd approve <slug>`, e leia o que ele mostra antes do `y`).
3. **Rodar:** `SDD_HOME=~/repos/sdd_agents ~/repos/sdd_agents/bin/sdd run <slug>` — TICKET →
   EXEC → QA → REVIEW → DOCS → PR, sozinho. Monitorar por incremento
   (`EXEC, I2/4, 37min, US$ 15,79`); **parar na segunda volta** da mesma fase; diagnosticar com
   `sdd why <slug>`. ⚠️ `status`, `phase` e `why` rodam o `TEST_CMD` inteiro
   (`npm test && npm run lint && npm run build`) — não são consultas baratas.
4. **Merge humano** do PR — conferir `gh pr view <url> --json baseRefName` → `develop` — e depois
   `sdd close <slug>` (fecha a issue SQ; sem linha no ledger).
5. **Conferir a guarda** (comando do § 1): `missions_with_session` subiu e `sha` = EIXO. Se não:
   `sdd autonomy --all-repos --by-mission` e
   `jq 'select(.mission=="<slug>") | {kit_sha, kit_dirty}' ~/.sdd/autonomy-log.jsonl` dizem se foi
   linha suja ou sha novo — diagnosticar **antes** da próxima missão.

## 8. Fase 3 — o veredito (fecha o M2)

`gate_KAIZEN` acha o veredito por `kit_sha_judged == latest.kit_sha` no frontmatter de
`docs/handoffs/*/05-verdict.md`; com `sufficient: false` só aceita `indeterminado`. O `sdd kaizen`
completo roda **só no checkout principal do kit** (`kit_root == REPO_ROOT`), avisa se estiver na
branch base, e abre uma sessão paga (~US$ 3–5; a linha dela é `meta` e não entra no eixo).

```bash
cd ~/repos/sdd_agents && git status --porcelain && [ "$(git rev-parse --short HEAD)" = "<EIXO>" ]
git switch -c "kaizen/$(date +%Y%m%d)"        # evita commitar na main
./bin/sdd kaizen                              # lê a série (sufficient: true pela 1ª vez) e planeja
```

A sessão escreve em `docs/handoffs/<missão-nascida>/`: `05-verdict.md` (`kit_sha_judged: <EIXO>`,
`verdict: melhorou|piorou|indeterminado`, citando outcomes, `advance_rate`, custo, guarda e a
`composition` — `sales_quote · 3 missions` — mais o `launch(es)` de
`sdd autonomy --all-repos --by-mission`), `00-missao.md` com `aprovacao:` **vazio**, `01-plano.md`
e `checkpoint.md`, commitados.

- **Ler o veredito.** `indeterminado` é aceitável se o porquê for a fatia `previous` só-kit.
  `piorou` ⇒ Jidoka: sem plano, escalar para o humano e parar — o "pronto" ainda vale, o juiz falou.
- **Decidir o plano nascido:** `sdd approve <missão-nascida>` (`y`) ou recusar por escrito no
  `05-verdict.md`. Entrada no `KAIZEN_LOG.md` com o antes/depois: `sufficient: false → true`, custo e
  launches das três missões, o veredito.
- PR contra `main` com veredito + plano + KAIZEN_LOG; merge humano. **A janela fecha aqui** e o kit
  pode voltar a mudar — a primeira mudança com número atrás é o plano nascido (provavelmente o custo
  do REVIEW: US$ 461,95 = 39% do gasto; números e `jq` em
  `docs/handoffs/20260829-o-incremento-que-andou/01-plano.md` § Próxima missão).

**Check de fecho:** `./bin/sdd kaizen` de novo responde `already judged: no session to spend`;
`./bin/sdd kaizen --series | jq .guard.sufficient` = `true`;
`grep -l 'kit_sha_judged: <EIXO>' docs/handoffs/*/05-verdict.md` acha o arquivo.

## 9. O que fica de fora, e por quê

- **O I13.4 em si** (`KAIZEN_AUTO_APPROVE`, gatilho automático da D6, espelho de vereditos da D3):
  exige uma **segunda janela** para um `previous` comparável, e uma ADR. Vem depois deste veredito.
- Missão do custo do REVIEW; faxina D15 do backlog; os dois achados do PR #31; a contaminação do
  ledger por fixtures (`clone/*` são shas antigos e não alcançam o `latest`).
- As decisões humanas pendentes do `CONTEXT.md` 🚩 (D11, alvo da D7) não bloqueiam a janela.
