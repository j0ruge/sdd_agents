---
missao: 20261117-o-worker-orquestrador
fase: REVIEW
rodada: 5
status: done
sessao: sessão interativa (orquestradora), fora do runner
data: 2026-11-18 11:40
gate: tests/run-all.sh no 0976b0d verde (rc 0, 2140 ok, as mesmas 12 ocorrências de FAIL dentro de linhas ok, anchors 854 de 854, 14 min); a rodada não fecha: 28 achados reais do CodeRabbit no PR #414 viram R6 a R10
---

# Review — rodada r5 — O worker orquestrador

> Esta rodada não foi escrita pela fase REVIEW do runner. Ela registra a revisão do CodeRabbit sobre
> o PR #414 (head `3b8c711`, 38 achados), conferida achado por achado contra o código no `0976b0d`
> pela sessão interativa, e as três decisões do dono sobre ela. Sem `reviewed_head:`, de propósito:
> é rodada de achados, e o `pr-ready` espera a rodada do worker que vier depois dos consertos.

## TL;DR

O CodeRabbit revisou o `3b8c711` e deixou 20 achados inline e 18 no corpo (17 Minor e 1 Major fora do diff).
Conferidos no `0976b0d`, 28 são reais, 3 não se aplicam, 2 viram limite declarado e 5 são prosa de decisão.
Oito deles fazem um verbo de confiança dizer "pode" onde devia dizer "não": o `pr-ready` com nota `---`, com rodada não commitada, com faixa reescrita ou com recibo truncado, e o `budget` com listagem de worktree que falhou.
Também é real o diário da campanha no checkout principal: ele para com `KIT-TOUCHED` uma missão do kit em voo.
O dono decidiu às 11:3x: consertar todos aqui; o conjunto estreito de configs; e o L6 com um lote por missão.
Cinco incrementos: R6 (`pr-ready`), R7 (teto, pager e configs), R8 (`next` e `delegate`), R9 (sensores) e R10 (prosa).
Nada foi consertado nesta rodada.

## Nota da rodada

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | B | O `round_grades` decide o separador pela nota e não pela forma da linha, e o `checkouts_of` engole a falha do `git worktree list` com `\|\| true`. |
| Type Safety | B | O `budget` compara dinheiro em ponto flutuante do jq, aceita `1e2` que o runner recusa e arredonda um teto de 0.004 para 0.00, que é sem teto. |
| Error Handling | B | O `pr-ready` escolhe um recibo mais velho quando o mais novo não parseia, e o `budget` conta só o checkout da campanha quando a listagem de worktrees falha. |
| Security | B | O `budget` e o `level` executam o `.sdd/config.sh` de todo worktree do repo, inclusive de branches que nenhuma missão da campanha usa (achado #3, pendência 2 da r4). |
| Performance | A | Nenhum achado de custo: os consertos trocam leituras, não acrescentam laço sobre o repo. |
| Test Coverage | B | Nenhum probe constrói a nota `---`, a rodada suja nem o recibo truncado, e o `check-worker.sh` dá 8 FAIL sob um `TMPDIR` com `[ci]` e aspas. |
| Documentation | B | O comando não escreve as transições `run` → `pr` → `review` → `merge`, e o `exec_model:` e o diário prometem o que o runner não faz. |
| **Overall** | **B** | Os verbos de confiança do worker ainda deixam passar oito mundos reproduzíveis, e o merge delegado depende deles. |

## Achados da rodada

Numeração da conferência (1 a 20 inline, 21 a 37 do corpo, 38 o Major fora do diff). Veredicto
conferido no código do `0976b0d`; o destino está na última coluna.

| # | Onde | Achado | Veredicto | Destino |
|---|---|---|---|---|
| 1 | `bin/sdd-worker:135` | `lots:` do template passa no `delegation_legible` | real: `<all, ou L1 L2 …>` dá os tokens `L1` e `L2` | R8 |
| 2 | `bin/sdd-worker:272` | o pager herdado sobrevive ao `source` | não se aplica: o runner também herda o `ON_ESCALATION_CMD` exportado quando o config não cita a chave (refutação 1 da r4), e é a rota que a delegação do kit usa | refutado |
| 3 | `bin/sdd-worker:272` | executa o config de worktree que não é da campanha | real, e é a pendência 2 da r4; o dono escolheu o conjunto estreito | R7 |
| 4 | `bin/sdd-worker:523` | soma de custo em ponto flutuante no teto | real: `0.10 + 0.70` fica abaixo de `0.80` | R7 |
| 5 | `bin/sdd-worker:527` | teto impresso com `%.2f` | real: `0.004` sai `0.00`, que o runner lê como sem teto | R7 |
| 6 | `bin/sdd-worker:563` | `gh pr list --head` casa PR de fork | real: falta filtrar `isCrossRepository` | R8 |
| 7 | `bin/sdd-worker:617` | cópia velha não aprovada pede `approve` antes de ver o merge | real | R8 |
| 8 | `bin/sdd-worker:703` | a nota `---` pula a linha do critério | real: `g ~ /^:?-+:?$/` decide pela nota, e `Security \| --- \| …` some | R6 |
| 9 | `bin/sdd-worker:822` | o `reviewed_head:` não precisa ser ancestral do head | real | R6 |
| 10 | `bin/sdd-worker:851` | diff de ponta a ponta não vê o commit revertido | real | R6 |
| 11 | `bin/sdd-worker:878` | recibo mais novo truncado faz valer um mais velho | real: o `capture` sem casamento some, e o `last` pega o anterior | R6 |
| 12 | `bin/sdd-worker:887` | recusa de cota do Codex devia passar | não se aplica ao código: o recibo do Codex é obrigatório (decisão 9 do dono); o "não bloqueia" da ADR 0022 §5 vale para os outros bots, e a frase fica ambígua | prosa, R10 |
| 13 | `bin/sdd-worker:917` | leituras separadas não valem juntas no merge | limite: leituras de shell não são atômicas, e o `--match-head-commit` só segura o sha | limite declarado, R6 |
| 14 | `commands/sdd-worker.md:56` | o teto lido antes de uma espera vale depois dela | real: depois de esperar o sim do dono o laço não volta ao passo 1 | R10 |
| 15 | `commands/sdd-worker.md:114` | `setsid` sem `--wait` com controle de jobs | real: com job control o `$!` é um pai que já saiu | R10 |
| 16 | `commands/sdd-worker.md:130` | o ato `pr` nunca é derivado | real: para PR aberto o `next` só diz `review` | R10 |
| 17 | `commands/sdd-worker.md:146` | não há transição para `merge` | real: idem | R10 |
| 18 | `docs/pipeline.md:1954` | rodada não commitada autoriza `ready` | real: o `newest_round` lê o disco, e o item `head` não prova árvore limpa (limite declarado que é fail-open) | R6 |
| 19 | `campaign.md:133` | o `next` não sabe de várias missões no L6 | real; o dono escolheu um lote por missão | R10 |
| 20 | `campaign.md:150` | os ◆ do L6 sem o dono | prosa: a decisão 8 vale para os 24, e o teto `plan` faz o dono aprovar cada plano do L6 antes do EXEC; a frase da seção L6 diz outra coisa | R10 |
| 21 | `bin/sdd-worker:508` | `1e2` passa no `budget` | real | R7 |
| 22 | `bin/sdd-worker:890` | só 100 threads | não se aplica: mais de 100 já é not-ready, limite declarado e lado seguro | refutado |
| 23 | `bin/sdd-worker:198` | edição entre o `awk` e o `mv` da assinatura | real e estreito | R8 |
| 24 | `bin/sdd-worker:429` | `checkouts_of` engole a falha do `git worktree list` | real: o `budget` conta menos em silêncio | R7 |
| 25 | `bin/sdd-worker:312` | `effective_level` lê o `campaign.md` duas vezes | real e estreito | R8 |
| 26 | `tests/check-templates.sh:529` | frontmatter sem `---` de fecho passa | real | R9 |
| 27 | `tests/check-templates.sh:553` | linhas de lote fora de `## Lotes` passam | real | R9 |
| 28 | `tests/check-worker.sh:821` | ledger do fixture sem JSON | real: 8 FAIL com `TMPDIR` de aspas e `[ci]` | R9 |
| 29 | `tests/check-worker.sh:324` | `grep` de regex com caminho | real | R9 |
| 30 | `commands/sdd-worker.md:188` | `campaign-ceiling` para ledger ilegível | real | R10 |
| 31 | `commands/sdd-worker.md:176` | diagnóstico com aspa simples no `SDD_GATE_WHY` | real | R10 |
| 32 | `commands/sdd-worker.md:43` | `exec_model:` não governa o EXEC | real: o runner lê `MODEL_EXEC` | R10 |
| 33 | `commands/sdd-worker.md:64` | diário no checkout do `sdd` do PATH | real: o `kit_guard_arm` arma sobre o `SDD_HOME` em toda corrida | R10 |
| 34 | `README.md:160` | como a sessão ganha o `/sdd-worker` | a conferir no R10 contra o `sdd install` | R10 |
| 35 | `CLAUDE.md:293` | o `TEST_CMD` roda o `--anchors` do catálogo | a conferir no R10 | R10 |
| 36 | `tests/run-all.sh:196` | prazo do `check-worker.sh` | a medir no R9 (8× o ocioso, piso 60 s) | R9 |
| 37 | `40-review-r4.md:102` | `HANDOFF_DIR` divergente num worktree | real | R7 |
| 38 | `docs/pipeline.md:1931` | `config_key` faz `source` sem `cd` | real e hipotético: um include relativo resolveria contra o cwd | R7 |

## Incrementos de conserto (R<n>)

| ID | Achados | Família(s) de probe | Resumo |
|---|---|---|---|
| R6 | 8, 9, 10, 11, 13, 18 | `sep:`, `committed:`, `range:`, `receipt:` | o `pr-ready` diz não aos quatro mundos; o #13 vira limite declarado |
| R7 | 3, 4, 5, 21, 24, 37, 38 | `narrow:`, `listed:`, `spend:`, `cwd:` | o conjunto estreito, a listagem que falha fechada, dinheiro exato e o `cd` |
| R8 | 1, 6, 7, 23, 25 | `lots:`, `fork:`, `stale:` | `lots:` pela gramática, PR do próprio repo, merge antes do `approve`; #23 e #25 estreitos ou declarados |
| R9 | 26, 27, 28, 29, 36 | `worker templates:` | os sensores resistem a `TMPDIR` hostil, e o prazo medido |
| R10 | 12, 14, 15, 16, 17, 19, 20, 30–35 | `command:` | as transições do comando, o L6 em lotes, e a prosa |

## O que virou incremento

- **R6.** (a) O `round_grades` reconhece o cabeçalho e o separador pela forma da linha (todas as
  células `:?-+:?`), nunca pela nota; uma linha de critério com nota `---` é lida e não é A. A
  mesma forma vale para o `round_unjustified`, que lê as mesmas linhas. (b) O `pr-ready` recusa
  (`not-ready review:`) quando a pasta da missão tem mudança não commitada ou arquivo não
  rastreado (`git status --porcelain -- <pasta>`), porque o merge leva o head, não o disco.
  (c) O `reviewed_head:` tem de ser ancestral do head (`git merge-base --is-ancestor`, o próprio
  head aceito). (d) Todo commit da faixa `reviewed_head..head` só toca a pasta da missão, não só a
  ponta. (e) O recibo é o comentário mais novo do bot que **traz o marcador**; se ele não parseia, é
  not-ready, nunca um recibo mais velho. (f) O cabeçalho do verbo declara o #13: as leituras não
  valem juntas, e quem mergeia relê o `pr-ready` imediatamente antes do `gh pr merge`.
  O `docs/pipeline.md` (item 1 da lista do `pr-ready`) diz a regra da rodada commitada.
- **R7.** (a) O `budget` e o `level` leem o `.sdd/config.sh` do checkout da campanha e dos
  worktrees que guardam uma missão dela (o conjunto do `campaign_mission_dirs`), e de nenhum
  outro; a prosa que diz "todo checkout do repo" (ADR 0022, `docs/pipeline.md`, `config/schema.md`,
  `templates/delegation.md`, a delegação da campanha do kit) muda no mesmo commit, e os limites da
  DOCS sobre o conjunto largo saem. As famílias `worktree:` e `pager:` passam a provar o conjunto
  estreito: um worktree sem missão da campanha não é lido. (b) O `checkouts_of` devolve não-zero
  quando o `git worktree list` falha, e todo chamador (`budget`, `level`, `next`) para com rc 1
  nomeando o comando (`listed:`). (c) Dinheiro em centavos inteiros: a soma e o teto comparados
  depois de `* 100 | round`; o teto da missão impresso como assinado (o valor que o `run` passa),
  com recusa de teto abaixo de 0.01; o override do config aceita só a gramática do runner
  (`spend:`). (d) O `config_key` faz `cd` para o checkout antes do `source` (`cwd:`). (e) Um
  `HANDOFF_DIR` de um checkout lido diferente do da raiz para com rc 1, nomeando o arquivo; o de um
  worktree fora do conjunto não é lido e fica como limite declarado.
- **R8.** (a) `lots:` é `all` ou uma lista não vazia de lotes que a tabela do `campaign.md` tem; o
  valor do template é ilegível (`lots:`). (b) O `pr_states` pede `isCrossRepository` e conta só PR
  do próprio repo (`fork:`). (c) O `next` olha o merge do branch antes de pedir `approve` a uma
  cópia (`stale:`). (d) #23 e #25: o executor fecha se um probe consegue construir o mundo
  (comparar o arquivo com a cópia lida antes do `mv`; um só snapshot do `campaign.md` no
  `effective_level`); senão, limite declarado no cabeçalho, nomeando o mundo que não se construiu.
- **R9.** O `check-worker.sh` monta o ledger do fixture com `jq --arg`/`--argjson` e compara a
  mensagem de assinatura como texto literal, e passa sob `TMPDIR` com `[ci]` e aspas. O
  `check-templates.sh` só aceita o frontmatter com o `---` de fecho e as linhas de lote dentro de
  `## Lotes`, cada regra com controle negativo (duas linhas `worker templates:` novas). O prazo do
  `check-worker.sh` no `run-all.sh` sai de uma medida ociosa nova, 8× e piso 60 s, com a medida na
  nota.
- **R10.** O comando escreve as transições: depois do `run`, o `pr`; depois do `pr`, o `review`;
  depois da rodada A e do recibo, `pr-ready` e `allows merge` para o `merge`; depois de toda espera,
  de volta ao passo 1 (`budget`). O lançamento usa `setsid -w`. O `campaign-ceiling` fica para gasto
  medido, e o ledger ilegível é outra parada. O diagnóstico vai por variável (`SDD_GATE_WHY="$why"`).
  O `exec_model:` diz o que governa o EXEC (`MODEL_EXEC`). O diário não se escreve no checkout do
  `sdd` do PATH com uma missão do kit em voo. A ADR 0022 §5 diz que o recibo do Codex é obrigatório
  e que o "não bloqueia" vale para os outros bots. O L6 do `campaign.md` vira um lote por item
  (L6a…L6k, teto `plan`, um item cada), a seção L6 diz que a decisão 8 vale e que o teto `plan` faz
  o dono aprovar cada plano; o Check do I11 segue `1 83`. README e `CLAUDE.md` conferidos contra o
  código e corrigidos só se a frase não confere. Uma linha `command:` nova prova as transições e o
  `setsid -w`.

## O que foi refutado

- **#2, o pager herdado.** O runner herda o ambiente da sessão que o lança, e o `load_config` não
  apaga uma chave que o config não cita; ler o valor herdado é ler o que o runner lê.
- **#22, mais de 100 threads.** Já é `not-ready threads: … the rest unseen`, declarado no cabeçalho.
- **#12, no código.** O recibo do Codex é a régua do dono (decisão 9); só a frase da ADR muda (R10).

## Achados fora de escopo

- Nenhum novo. O separador pela nota (#8) foi copiado do `gate_REVIEW` do runner: o R6 confere se o
  `bin/sdd` tem a mesma regra e, se tiver, registra o achado no `TODO.md` em vez de mexer no runner.

## Pendências / Decisions for a Human

As três foram decididas pelo dono às 11:3x, nesta sessão, pelas opções recomendadas:

1. **Consertar todos aqui**, à mão no worktree, em TDD, e o merge fica com o dono (o CodeRabbit
   comentou, então o merge delegado não vale).
2. **O conjunto estreito** de configs para o teto e o pager (fecha o #3 e a pendência 2 da r4).
3. **O L6 com um lote por missão**, e a decisão 8 vale para os seus ◆.

## Boot da próxima fase

EXEC, um incremento por sessão, na ordem R6 → R10, no worktree `/home/joruge/repos/sdd_agents-worker`.
Leia a linha do incremento no `checkpoint.md` e a seção dele em "O que virou incremento" acima; o
achado original está no PR #414 (`gh api repos/j0ruge/sdd_agents/pulls/414/comments`). Cada achado
de código ganha probe na família nomeada e ao menos um mutante `mut_WORKER_<família>_*`, provado por
`tests/check-mutation.sh --only <slug> tests/check-worker.sh`, e uma passada de sabotagem anotada.
Rode `shellcheck -S warning` nos arquivos tocados antes do commit. Não rode a suíte inteira por
incremento: a sessão orquestradora a roda no fim.
