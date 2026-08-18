---
missao: 20260818-lote-facil
titulo: O sdd health para de morrer calado, e 18 achados baratos saem do backlog com sensor
data: 2026-08-18
versao: n/a — JIRA_ENABLED=false neste repo
branch: chore/lote-facil
aprovacao:
ddd: n/a
---

# Missão — O `sdd health` para de morrer calado, e 18 achados baratos saem do backlog

> Escrito com o humano presente, a partir de `docs/handoffs/lote-facil-20260817.md` (a triagem por
> mecanismo) e do Lote 0 já mergeado no PR #11. É a única fonte da **intenção**; o `01-plano.md` é
> a fonte do **como**. Toda sessão headless começa lendo estes dois.

## Problema (Gemba)

O `TODO.md` carrega 56 achados abertos. A triagem de 2026-08-17 separou os que satisfazem quatro
critérios ao mesmo tempo — defeito **localizado e reproduzido**, direção mecânica, sensor já
existente onde a asserção vai morar, e nenhuma decisão humana pendente. Dez deles não tocavam
lógica e saíram à mão no PR #11 (66 → 56). Sobram **18 que precisam de código e sensor**.

O mais caro deles é uma família de quatro, e ela foi **reproduzida nesta sessão de planejamento**,
não suposta. `cmd_health` captura saída com `out="$(cmd)"` sob `set -euo pipefail`: quando `cmd`
devolve não-zero, o script morre **na atribuição**, e o `health_bad` da linha seguinte é código
morto. Medido com o runner real, num kit copiado, quatro sondas:

| sonda | onde | o que o operador vê hoje |
|---|---|---|
| suíte vermelha | `bin/sdd:1708` | **só o cabeçalho**, rc 1 — nunca diz "suite red", e os checks 2–5 não rodam |
| suíte sem a linha `score:` | `bin/sdd:1721` | `ok suite green`, rc 1 — nunca diz "went blind to the mutation" |
| `~/.claude/plugins/cache` ausente | `bin/sdd:1854` | morre depois do check de gates, rc 1 — proveniência e catraca nunca rodam |
| baseline sem linha viva | `bin/sdd:1882` | morre depois da proveniência, rc 1 — nunca diz "kit healthy" nem reprova |

É o comando que existe para responder "o kit ainda mede o que diz medir?", e **a suíte vermelha é
exatamente o caso que ele existe para relatar**. Ele morre justo aí, em silêncio.

Os outros 14 são da mesma classe barata: `cd` com operando relativo sem `CDPATH=''` em 14 arquivos
de `tests/`, três linhas de saída humana que contam a grandeza errada, cinco caminhos de código sem
asserção nenhuma (logo sem mutação possível), e cinco regras de sensor — mais o único artefato do
kit **com gate e sem template**, o `40-review-r<N>.md`, que já levou duas rodadas independentes a
escrever `##` em vez de `###` e colher `NO-TABLE`.

## Métrica

Binária e verificável por comando, medida em três lugares:

1. **A prova da família do aborto calado:** com a suíte propositalmente vermelha, `./bin/sdd health`
   **imprime `suite red` e segue** para os checks restantes. Hoje imprime uma linha e sai rc 1.
2. **Cinco Checks de incremento**, todos medidos **vermelhos contra o HEAD de hoje** (contagens na
   tabela do `checkpoint.md`): `abort:` 0→4, `cdpath:` 2→3, `output:` 6→9, `covered:` 0→5,
   `rule:` 0→5.
3. **O backlog:** `tests/check-todo.sh` → `38 finding(s)`, com `todo-findings 38` em
   `tests/health-baseline.txt` movido **no mesmo commit**, e `score:` do catálogo de mutação
   **acima de 81** (todo gate/asserção nova entra com mutação).

## Resultado esperado

O `sdd health` deixa de ser um comando que mente por omissão: qualquer um dos quatro modos de falha
passa a ser **dito em voz alta**, e os checks seguintes continuam rodando em vez de sumirem juntos.

A classe do `cd` relativo desaparece do repo inteiro em vez de ficar consertada só no ledger — e o
`ledger_repo_root` fica **menor**, porque `git rev-parse --path-format=absolute --git-common-dir`
(2.31+, aqui 2.43) dispensa os dois `cd`, o `pwd -P` e a guarda de `CDPATH`.

Cinco caminhos que hoje não têm asserção nenhuma passam a ter — e portanto passam a poder ter
mutação, que é o que distingue asserção viva de decoração. O `40-review-r<N>.md` ganha template.

O `TODO.md` cai de 56 para 38 achados abertos, com a catraca acompanhando no mesmo commit.

## Fora de escopo

Deliberadamente **não** entram, e a triagem já registrou o porquê em
`docs/handoffs/lote-facil-20260817.md`:

- **Investigação de verdade** — `gate_EXEC` rederivando por árvore suja (é redesenho de gate);
  `check-autonomy.sh` vermelho intermitente (não reproduziu em 152 runs; o corpo manda medir de
  novo antes de consertar); preflight que prove execução de `TEST_CMD` (exige probe headless real,
  custa dinheiro); `check-todo.sh` re-derivar âncoras semanticamente.
- **Decisão humana antes de qualquer código** — as 5 chaves fantasma do `config/schema.md`;
  `E2E_DIR`; TICKET recebendo agente **e** slash; `CHANGELOG.md`; o lembrete pós-pipeline (pede
  ADR 0004); o alvo da D7; o multiplicador do harness de mutação; teto por fase granular.
- **Refator grande** — split do `docs/pipeline.md` (o próprio item diz "merece a sua missão");
  contrato PT-BR em 5 pontos; `templates/` multi-idioma.
- **Os 3 adiados por YAGNI** — são decisões de não-fazer, não dívida.

## Gate PLAN-AUTO

| # | Critério | Status | Evidência |
|---|---|---|---|
| a | Grill sem perguntas abertas não endereçadas | ✅ | Não houve sessão de grill: o papel foi feito pela triagem por mecanismo em `docs/handoffs/lote-facil-20260817.md`, que fixou os 4 critérios de "barato", o agrupamento por família e o que fica fora. A única pergunta aberta que restava (o destino do `.claude/napkin.md`) foi decidida pelo humano e fechada no PR #11. |
| b | Checklist kaizen 100% ✅ e DDD 100% ✅ ou `n/a` justificado | ✅ | tabelas abaixo |
| c | Plano passa no teste de autocontenção | ✅ | Os 18 itens estão no `01-plano.md` com âncora **re-derivada nesta sessão** (8 das 18 estavam podres, a pior por ~615 linhas), o mecanismo de cada família escrito, e a receita literal de cada asserção. Nenhum incremento exige ler o `TODO.md` nem esta conversa. |
| d | Todo incremento tem Check executável (comando → esperado) | ✅ | 5 de 5, e os cinco foram **executados contra o HEAD e registrados vermelhos** — ver Notas do `checkpoint.md`. Nenhum nasce verde. |
| e | `versao:` confirmada pelo humano (ou `JIRA_ENABLED=false`) | ✅ | `JIRA_ENABLED=false` em `.sdd/config.sh` — a fase TICKET é pulada |

⚠️ `aprovacao:` fica **vazio de propósito**. A sequência do handoff prevê `./bin/sdd approve
20260818-lote-facil` como passo próprio: é o único caminho que grava `aprovacao: humano-<data>`, e
o campo nunca se preenche à mão.

## Checklist kaizen (`kaizen-software`)

| # | Item | Status | Nota |
|---|---|---|---|
| K1 | Gemba — fui ver onde o trabalho acontece | ✅ | As 4 sondas da família do aborto calado foram **executadas** com o runner real num kit copiado, com controle verde (`kit healthy`, rc 0) antes de cada sabotagem |
| K2 | Problema declarado com métrica | ✅ | 3 métricas binárias, com as contagens de partida medidas |
| K3 | Desperdícios identificados e cortados | ✅ | Agrupamento **por mecanismo**, não por arquivo: fechar 3 itens da mesma família custa quase o mesmo que fechar 1. O I2 ainda **remove** código em vez de acrescentar |
| K4 | Fatiamento incremental, cada fatia verificável | ✅ | 5 incrementos, cada um com Check próprio e contagem própria |
| K5 | Check por artefato (rótulo ≠ artefato) | ✅ | Todo Check ancora em `^  ok    ` (4 espaços) sobre saída de sensor — nunca em texto solto, que responde igual com a asserção verde e vermelha |
| K6 | Jidoka — o que para a linha está definido | ✅ | Sensor vermelho para a linha. O I1 tem uma trava a mais: o incremento não fecha sem a prova de que o `sdd health` **segue** depois de relatar |
| K7 | SDCA — a melhoria vira padrão | ✅ | Toda asserção nova entra com mutação no catálogo; `sdd health` reprova gate sem mutação |
| K8 | Registro no KAIZEN_LOG | ✅ | Fase DOCS, com antes/depois medido — sem número não entra |

## Checklist DDD (`ddd`) — condicional

`n/a — sem toque de domínio: a missão mexe em runner bash, sensores e templates; não há aggregate,
bounded context, evento nem entidade envolvidos.`

## Decisões do grill (não re-litigar)

1. **Agrupar por mecanismo, não por arquivo.** É a alavanca de custo do lote: três itens da mesma
   família custam quase o mesmo que um; três de famílias diferentes custam três vezes.
2. **O Lote 0 foi separado e já está mergeado** (PR #11, 66 → 56). Não refazer, não re-triar.
3. **Re-derivar toda âncora antes de implementar.** No PR #7 as do cluster cosmético estavam ~870
   linhas defasadas; nesta sessão de planejamento, **8 das 18** estavam podres. A re-derivação
   costuma achar MAIS trabalho, não menos.
4. **`aprovacao` fica vazio** — a aprovação é do humano, por `sdd approve`.
5. **Nada de `|` na célula do Check**, nem escapado: o parser é `awk -F'|'` cru. Check que
   precisaria de pipe vira herestring.
6. **O `check-autonomy.sh` vermelho intermitente fica FORA.** Não reproduziu em 152 runs. Se
   aparecer durante a missão, é ruído conhecido: registrar nas Notas e seguir, não investigar.

## Pendências para o humano

Nenhuma bloqueante. Duas para o corpo do PR:

- O **alvo "<30 s" da D7** segue ~7× estourado e esta missão o piora um pouco (asserção nova roda
  dentro de cada mutante, hoje 81). A decisão — subir o alvo, aposentá-lo, ou rodar por mutante só
  o sensor que o alcança — continua no `TODO.md` e é do humano.
- O `LINT_CMD` está **preenchido** no `.sdd/config.sh` deste repo e o runner **não o lê** em lugar
  nenhum. É uma das 5 chaves fantasma, e está fora de escopo aqui.
