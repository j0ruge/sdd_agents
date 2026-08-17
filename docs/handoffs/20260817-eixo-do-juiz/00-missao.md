---
missao: 20260817-eixo-do-juiz
titulo: O juiz do kaizen para de parecer quebrado quando o kit é o próprio alvo, e o ledger global volta a ser legível entre projetos
data: 2026-08-17
versao:
branch: missao/20260817-eixo-do-juiz
aprovacao: humano-2026-08-17
ddd: aplicado
---

# Missão — o eixo do juiz

> Escrito pelo `sdd-planner` com o humano presente. É a única fonte da **intenção**; o `01-plano.md`
> é a fonte do **como**. Toda sessão headless começa lendo estes dois.

## Problema (Gemba)

O `sdd kaizen` julga a mudança anterior do kit e dá à luz o plano da próxima missão. **O
julgamento está morto na água**, medido no ledger real em 2026-08-16:

```
latest    kit_sha 818b800 · 1 sessão · fase PR   · US$ 1,48
previous  kit_sha 4126b50 · 1 sessão · fase DOCS · US$ 7,31
guard     missions_after_change 1 · sessions 1 · sufficient false
```

`latest` e `previous` são **a mesma missão**, fases consecutivas. Comparar isso não mede kit
nenhum: mede que publicar é mais barato que documentar.

A causa: `autonomy_kit_stamp` (`bin/sdd:901`) carimba `kit_sha` = `HEAD` do kit **no instante de
cada linha**, e a fase EXEC commita no `bin/sdd` entre sessões. O eixo agrupa por esse sha
(`bin/sdd:2455`) e o piso exige `missions_with_session >= 3` no sha corrente (`bin/sdd:2469`) —
**24 shas distintos no ledger, todos com exatamente 1 sessão, nenhum com 2**.

Três defeitos adjacentes, todos verificados nesta sessão:

- **`--all-repos` não existe.** `ledger_row_is_local` (`bin/sdd:887`) filtra por repo nos três
  leitores — conserto certo para a contaminação de fixture (`d99a7fc`) —, mas o ledger existe para
  medir maturidade **entre** projetos (`docs/pipeline.md:274`) e nenhum leitor consegue mais.
- **Worktree parte a identidade do repo.** `ledger_repo_root` (`bin/sdd:865`) usa
  `git rev-parse --show-toplevel`, que é **por worktree**: missão rodada num worktree grava
  `repo: .../wt` e a leitura do checkout principal a devolve como `other_repo`, série vazia.
- **Linha sem `repo` é local em todo repo.** `ledger_row_is_local` faz `else true end`, e o
  comentário de `bin/sdd:785` afirma que os leitores as classificam em voz alta — mas
  `is_unrecognized` (`bin/sdd:2311`) olha `.event`, não `.repo`. Medido em fixture: 3 dessas linhas
  bastaram para virar `guard.sufficient` para `true`. Hoje são 0 no ledger real.

## Métrica

- `sdd kaizen --series` no repo do kit informa `guard.degenerate_axis: true` e o comando cita o
  **ADR 0003** — binário. Hoje informa só `sufficient: false`, indistinguível de "faltam missões".
- `sdd autonomy --all-repos` num ledger de dois repos devolve `other_repo: 0` e `missions` **maior**
  que sem a flag — diferencial medido, as duas saídas comparadas entre si.
- Linha escrita num worktree é lida como local no checkout principal — binário, hoje falso.
- 3 linhas sem `repo` **não** movem `sufficient` — binário, hoje movem.
- Catálogo de mutação **55 → 60**, `0 known gap(s)`.
- Os 5 itens correspondentes do `TODO.md` ganham `RESOLVIDO por <hash>`.

## Resultado esperado

O humano que roda `sdd kaizen` no repo do kit passa a ler *por que* o veredito é `indeterminado`:
não faltam missões, é o eixo `kit_sha` degenerando no repo que desenvolve o próprio kit — com o
ADR 0003 citado na saída. Quem quer o número entre projetos pede `--all-repos` e recebe. O ledger
para de perder identidade em worktree, e linha sem `repo` deixa de poder inflar o piso do juiz em
silêncio. O I13.4 (graduação de autonomia) deixa de estar travado por uma pergunta em aberto.

## Fora de escopo

- **Afrouxar o piso `>= 3`** — recusado pela decisão 3 do grill; era a saída que a decisão 1 evita.
- **Política de `SDD_VERSION`/CHANGELOG** — pré-requisito da alternativa "eixo = versão publicada",
  que foi descartada. Segue no `TODO.md`.
- **Budget por fase, 5 chaves fantasma do `config/schema.md`, renomeação PT-BR do contrato,
  espelho global de vereditos** — seguem no `TODO.md`.
- **Mexer em `autonomy_kit_stamp`** — a decisão 1 deixa o carimbo como está.

## Gate PLAN-AUTO

Preenchido pelo `sdd-planner` **com evidência**. Todos ✅ → `aprovacao: auto` e o pipeline segue
sozinho. Qualquer ✗ → `aprovacao` fica vazio e o runner para pedindo aprovação humana explícita.

| # | Critério | Status | Evidência |
|---|---|---|---|
| a | Grill sem perguntas abertas não endereçadas (🚩 vazia ou itens deferidos com dono) | ✅ | 2 perguntas (eixo; cross-repo); 🚩 vazia — decisões abaixo |
| b | Checklist kaizen 100% ✅ e checklist DDD 100% ✅ ou `n/a` justificado | ✅ | seções abaixo; DDD **acionado**, não `n/a` |
| c | Plano passa no teste de autocontenção (sessão nova só com 00/01/checkpoint executa) | ✅ | "Contexto verificado" do `01-plano.md`, âncoras relidas em `main` pós-merge do PR #5 |
| d | Todo incremento do `checkpoint.md` tem Check executável (comando → esperado) | ✅ | 5/5, rodados contra o HEAD em 2026-08-17 e **vermelhos** (contagem 0, sensores rc 0) |
| e | `versao:` confirmada pelo humano (ou `JIRA_ENABLED=false`) | ✅ | `JIRA_ENABLED=false` no kit |

⚠️ **`aprovacao:` fica vazio apesar dos cinco ✅, por escolha registrada.** A regra do planner
autorizaria `auto` (o humano esteve no grill), mas `sdd approve` nasceu na missão anterior
(`96a1f68`) e nunca rodou fora de fixture. Esta missão é a primeira chance de exercitá-lo no repo
real — o gate humano com comando, que é exatamente o que ele existe para ser. Rodar
`./bin/sdd approve 20260817-eixo-do-juiz`.

## Checklist kaizen (`kaizen-software`)

| # | Item | Status | Nota |
|---|---|---|---|
| K1 | Gemba — fui ver onde o trabalho acontece | ✅ | série real rodada; todo fato tem `arquivo:linha` conferido em `main` |
| K2 | Problema declarado com métrica | ✅ | 4 binários + score 55→60 |
| K3 | Desperdícios identificados e cortados | ✅ | veredito inútil todo ciclo; número entre projetos inacessível; série vazia em worktree |
| K4 | Fatiamento incremental, cada fatia verificável | ✅ | 5 incrementos, 1 sessão cada, Check próprio |
| K5 | Check por artefato (rótulo ≠ artefato) | ✅ | Checks ancoram em `^  ok    `; o do I1 exige o ADR **e** a citação no código |
| K6 | Jidoka — o que para a linha está definido | ✅ | sensor vermelho para a suíte; `sufficient` que se move sem explicação é o que o I5 mata |
| K7 | SDCA — a melhoria vira padrão (doc/rule/teste) | ✅ | ADR 0003 + predicado único no jq + 5 mutações |
| K8 | Registro no KAIZEN_LOG | ✅ | a cargo da fase DOCS, com o antes/depois da série |

## Checklist DDD (`ddd`)

Acionado, não `n/a`: a missão redefine **que pergunta o agregado "versão do kit" responde** e o
contrato entre ledger (fatos) e juiz (veredito).

| # | Item | Status | Nota |
|---|---|---|---|
| D1 | Linguagem ubíqua nomeada | ✅ | `eixo` (kit_sha), `recorte` (slice de um sha), `piso` (guard), `eixo degenerado` (1 sessão por sha) |
| D2 | Fronteira do contexto | ✅ | ledger = fatos, imutável; juiz = veredito. O runner nunca opina, o agente nunca recalcula |
| D3 | Invariante do agregado | ✅ | um recorte comparável exige `kit_dirty == false and kit_sha != null`; o eixo degenerado é propriedade do **conjunto** de recortes, não da linha |
| D4 | Eventos | ✅ | `session`, `blocked`, `degraded` intocados; nenhum evento novo — o I2 acrescenta campo derivado, não fato |
| D5 | Contrato entre módulos | ✅ | `guard.degenerate_axis` e `excluded.no_repo` entram no schema da série que o agente é mandado citar; a prosa que o descreve muda no mesmo commit |
| D6 | Decisão registrada | ✅ | ADR 0003 (I1), na sequência de 0001 (juiz dividido) e 0002 (kaizen headless) |

## Decisões do grill (não re-litigar)

1. **Evidência vem de repo-alvo real.** O eixo `kit_sha` não muda; no alvo o kit não muda durante a
   missão, várias missões compartilham um sha e o piso de 3 funciona como projetado. No repo do kit
   `indeterminado` é a **resposta correta** — e o runner tem de dizer isso, não parecer quebrado.
2. **`--all-repos` explícito.** Default segue filtrado (mata a contaminação que `d99a7fc`
   consertou); a flag reabre a leitura entre projetos, que é a razão de o ledger ser global.
3. **Nenhum afrouxamento de régua.** O piso `>= 3` fica.
4. **Carimbar por missão foi descartado com motivo:** cada missão do kit produz o próprio sha ao
   commitar, então seguiria 1 missão por sha e `>= 3` continuaria insatisfazível. O problema nunca
   foi *quando* carimbar.
5. **`aprovacao:` vazio para dogfood do `sdd approve`** (ver ⚠️ acima).
6. **PR #5 mergeado antes desta missão nascer** (`8481f43`): duas missões concorrentes em
   `bin/sdd` seria conflito garantido, e o modelo declarado é uma missão por branch por vez.

## Pendências para o humano

<vazio>
