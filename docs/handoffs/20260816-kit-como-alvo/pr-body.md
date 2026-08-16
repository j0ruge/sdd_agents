# quando o kit é o próprio alvo, quatro instrumentos param de afirmar o que nunca mediram

Quando o kit roda contra si mesmo, quatro instrumentos deixam de só rotular "medido" e passam a
medir de fato — e um quinto, achado pela própria fase QA desta missão, se soma a eles.

> Gerado pelo pipeline `sdd` — missão `20260816-kit-como-alvo`. Único gate humano: **o merge**.

## O que mudou

- **`sdd autonomy` e `sdd kaizen --series` param de contar linhas de outros repos.** O ledger
  continua global (é uma escolha de propósito), mas cada leitura agora enxerga só as linhas do
  repo corrente. Antes, um teste isolado em `/tmp` conseguia mudar os números que o laço de
  melhoria do kit cita como verdade — e já mudou.
- **`sdd preflight` volta a provar o que diz.** Ele comparava só se o agente instalado existia;
  agora compara byte a byte com a fonte. Cópia desatualizada reprova com "stale" e pede
  `sdd install --force` — antes, ficava rodando texto velho em silêncio.
- **`sdd run` e `sdd kaizen` avisam quando você está na branch base**, do mesmo jeito que o
  `sdd preflight` já avisava. Continua sendo aviso — nunca erro, nunca trava o comando.
- **O runner deixou de poder reexecutar a si mesmo por acidente.** A fase EXEC edita `bin/sdd`
  durante a própria execução (dez vezes na missão anterior); o entry point agora se protege dessa
  situação.
- **O Check de qualquer checkpoint de missão do kit passou a distinguir "a asserção passou" de
  "a asserção apareceu na saída".** Antes os dois liam o mesmo texto e o Check dizia "passou" para
  os dois — o quinto instrumento da mesma família, achado pela QA desta própria missão.

## Como verificar

```bash
bash tests/run-all.sh          # suíte completa + mutação — score: 44 caught, 0 known gap(s), of 44
bash bin/sdd health             # kit healthy
bash tests/check-entrypoint.sh  # sensor novo do I1, diferencial
bash tests/check-checkpoint.sh  # sensor novo do F1, mede todo checkpoint do repo
bash bin/sdd preflight          # agente com cópia divergente reprova com "stale"
bash bin/sdd autonomy           # só linhas deste repo entram na tabela
```

## Evidências

| Fase | Resultado | Artefato |
|---|---|---|
| Execução | I1–I4 + F1 (5 incrementos, todos `done`), suíte verde, mutação 44/44 (100%) | [`checkpoint.md`](https://github.com/j0ruge/sdd_agents/blob/missao/20260816-kit-como-alvo/docs/handoffs/20260816-kit-como-alvo/checkpoint.md) |
| QA | aprovado após 1 fix (`F1`) — projeto sem interface, 4 jornadas de CLI caminhadas como diferencial contra o runner de antes | [`30-handoff-qa.md`](https://github.com/j0ruge/sdd_agents/blob/missao/20260816-kit-como-alvo/docs/handoffs/20260816-kit-como-alvo/30-handoff-qa.md) |
| Review | fecha na rodada 2, todos os 7 critérios em Grade A (3 HIGH fail-open fechados com probe, um deles achado pela própria r2) | [`40-review-r2.md`](https://github.com/j0ruge/sdd_agents/blob/missao/20260816-kit-como-alvo/docs/handoffs/20260816-kit-como-alvo/40-review-r2.md) |
| Docs | checklist de drift com 19 áreas do diff: 15 ✅ com hash, 4 `n/a` justificado, nenhum ✗ | [`45-docs.md`](https://github.com/j0ruge/sdd_agents/blob/missao/20260816-kit-como-alvo/docs/handoffs/20260816-kit-como-alvo/45-docs.md) |

**Métrica do `00-missao.md`, cumprida número a número:** os 4 Checks foram `127`/`0`/`0`/`0` no
HEAD do plano e são `0`/`1`/`1`/`1` agora; o catálogo de mutação foi de 40 para 44 mutantes, a
100%. Antes/depois completo, com mais 4 grandezas medidas, no `KAIZEN_LOG.md`.

**Sensores novos** (rodam no CI a partir deste PR):

- `tests/check-entrypoint.sh` — prova, de forma diferencial (duas cópias de um script que crescem
  in-place durante a própria execução), que o runner não volta a executar a si mesmo quando o
  arquivo cresce em voo. Passou por uma passada de sabotagem adversarial de 25 degradações; 20
  morrem no sensor, as 5 restantes estão nomeadas no cabeçalho.
- `tests/check-checkpoint.sh` — mede, em todo checkpoint do repo (23 arquivos hoje, incluindo o
  template), se a célula do Check ancora em `^  ok    ` (a asserção rodou **e** passou) e não usa
  `|` cru. Passou por 44 degradações em 4 rodadas de sabotagem.
- 4 mutantes novos no catálogo de mutação: `RUN_entrypoint_unguarded`, `RUN_ledger_no_repo_filter`,
  `PRE_agent_presence_only`, `RUN_base_branch_warn_dead`.

## Plano

[`01-plano.md`](https://github.com/j0ruge/sdd_agents/blob/missao/20260816-kit-como-alvo/docs/handoffs/20260816-kit-como-alvo/01-plano.md) ·
[`00-missao.md`](https://github.com/j0ruge/sdd_agents/blob/missao/20260816-kit-como-alvo/docs/handoffs/20260816-kit-como-alvo/00-missao.md) —
leia se quiser o porquê das decisões.

## Pendências (Decisions for a Human)

> Não bloqueiam este PR; são escolhas que exigem julgamento humano. União do que cada fase deixou
> em aberto.

- [ ] **O eixo do juiz do laço de melhoria (`kit_sha` a cada linha do ledger) e a guarda das 3
  missões.** Enquanto não for decidido, todo veredito do `sdd kaizen` neste repo é
  `indeterminado` por construção — duas voltas já terminaram assim. Esta missão conserta os
  instrumentos que alimentam o juiz, não a régua dele. Pede ADR. Detalhe em `05-verdict.md`.
- [ ] **A régua de tempo da suíte** (`CONTEXT.md`, D7, alvo "<30 s"). O catálogo foi de 40 para 44
  mutantes e a suíte, medida na mesma máquina e sessão, foi de 1:17,62 para 1:45,17 (+35%) — o
  alvo está agora 3,5× distante. Falta subir o alvo ou aceitar o estouro por escrito.
- [ ] **Confirmar a D11** (`event: "degraded"` próprio vs `blocked` com `kind` novo) — 🚩 aberta em
  `CONTEXT.md:41`, sem relação direta com esta missão.

## Achados fora de escopo

> Registrados no `TODO.md`; viram candidatas a missões futuras.

- A linha `N kit agent(s) checked` não é observável por nenhum fixture offline — `bin/sdd:1356`
- `checkpoint_rows` (`bin/sdd:174`) faz `awk -F'|'` cru e não conhece o escape `\|` do GFM
- Aprovar plano é editar `aprovacao:` à mão — não existe `cmd_approve`
- Duas regras conflitantes sobre `aprovacao:` entre `sdd-planner.md` e `sdd-kaizen.md`
- `40-review-r<N>.md` é o único artefato com gate e sem template em `templates/`
- Os dois ramos de diagnóstico do `differential()` não têm probe — `tests/check-entrypoint.sh:234`
- A regra do `|` na célula do Check não tem `doc_rule` que a cobre — `tests/check-checkpoint.sh:239-241`
- `check-todo.sh` mede a forma da âncora, nunca se ela aponta o alvo certo (15 âncoras erradas
  achadas em 11 itens durante esta missão)
- O eixo do juiz e a guarda das 3 missões — achado completo em `05-verdict.md`

## Riscos e não-dones

- **`repo` no ledger é caminho absoluto e o filtro compara string.** Symlink ou repo movido não
  casam. Medido antes de decidir: `0` linhas sem o campo `repo` em 26 linhas nesta máquina. Decisão
  tomada por regra e não pelo dado: linha que não sabe dizer de onde veio nunca é excluída pelo
  filtro — esconder corrupção é a única coisa que ele não pode fazer.
- **O ramo de sucesso do preflight (`N kit agent(s) checked`) segue sem sensor.** A asserção que o
  plano previa era vácua (nenhum fixture offline chega lá); trocada por um diferencial de contagem
  que cobre o ramo de falha. Direção registrada no `TODO.md`.
- **A suíte ficou ~35% mais lenta** (1:17,62 → 1:45,17): catálogo de mutação, não desperdício — 4
  mutantes novos são 4 suítes inteiras a mais. A decisão sobre o alvo é a pendência acima.
- **Nenhum teste roda em macOS.** Pressuposto GNU userland do kit, agora medido pelo preflight,
  nunca exercitado em CI.

---
<!-- ticket: n/a (JIRA_ENABLED=false) · versão: n/a -->
