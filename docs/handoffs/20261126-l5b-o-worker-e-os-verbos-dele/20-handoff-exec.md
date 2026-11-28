---
missao: 20261126-l5b-o-worker-e-os-verbos-dele
fase: EXEC
status: done
sessao: 01a21f8c-a507-76f0-9f25-a1f577298024
data: 2026-11-27 22:04
gate: tests/run-all.sh no conteúdo de 1a50dd42 → rc 0, suite green, 21 etapas. bash tests/check-worker.sh no mesmo conteúdo → rc 0, 110 sondas e Check R8 → 1.
---

# Handoff — EXEC — O worker e os verbos dele

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.


## TL;DR

Os 24 incrementos estão concluídos, incluindo R8 da REVIEW r5.
O título visível após um item de lista volta a contar, inclusive quando torna o pedido ambíguo.
O Check R8 imprimiu `1` e a suíte ficou verde. O reteste começa pelos três casos da r5 e seu controle.

## Estado do repo

- **Branch:** `fix/l5b-o-worker-e-os-verbos-dele` — sem upstream configurado.
- **Último commit de implementação:** `1a50dd42` — encerra o HTML bruto junto com o item de lista.
- **Árvore de trabalho:** o commit de fechamento registra apenas o checkpoint, as notas e este handoff.
- **Suíte:** `tests/run-all.sh` → rc 0, `suite green`, 21 etapas e 110 sondas do worker.
- **E2E:** não há `E2E_CMD` configurado. As jornadas usam Git local e simulam GitHub, runner, relay, fila e aprovação.

## O que foi feito

- `064098e` — I1 — Preservou a lista de worktrees com separadores NUL.
- `d1e8d0f` — I2 — Exportou o teto ao ler o config e conferiu a validade ao conceder autoridade.
- `1af340a` — I3 — Incluiu o gasto de missão removida sem dupla contagem.
- `ac581c8` — I4 — Revalidou o teto delegado antes de novas sessões.
- `d7ca654` — I5 — Conservou a causa original da parada e distinguiu teto de fase de teto de missão.
- `9ce1943` — I6 — Impediu que páginas de forks ocultassem o PR próprio.
- `f7b8071` — I7 — Separou a prova do ancestral da prova das notas de revisão.
- `6ed4ddc` — I8 — Vinculou `local/ci` ao SHA testado.
- `2d81fe7` — I9 — Exigiu o tratamento verificável do corpo da revisão e dos threads.
- `4edda89` — I10 — Vinculou as escolhas publicadas e o aceite do merge ao head.
- `20ffaab` — I11 — Preservou o delta elegível e releu a revisão depois de integrar conflito.
- `f3b4056` — I12 — Documentou a fila assinada e retomou o PR de acompanhamento.
- `2e8bd53` — I13 — Fez do pré-voo no worktree e no engine da missão uma condição para iniciar o runner.
- `6344f01` — I14 — Disparou um único relay Codex autorizado antes da espera, com retomada e aprovação revalidada.

## Correções do ciclo de QA

- `5ac9b42` — F1 (BUG-01) — Reutilizou a reserva concorrente validada durante a leitura do orçamento. A jornada simulada registrou um único `start` e a retomada via `status`.
- `9837b00` — F2 (BUG-02) — Passou a extrair o bloco que define `review_scope` e a exigir que cada cenário termine depois de conferir o código de saída, a resposta e a ordem das chamadas. Os controles rejeitaram um carregamento interrompido e uma rodada `full` no lugar do delta elegível.

## Correções da REVIEW r1

- `297f072` — R1 — Só publica sucesso em `local/ci` quando `TEST_CMD` termina no SHA testado.
- `a83df3e` — R2 — Identifica o lote e aponta o relay para a fila canônica no primário.
- `9b0e168` — R3 — Exige referência local recuperável e estável antes do despacho antecipado.
- `4d5bdb4` — R4 — Distingue aprovação informativa de corpo acionável e valida metadados de comentários presentes também em threads resolvidas. Inventário e prontidão recusam a mesma página inválida.

## Correção da REVIEW r2

- `ebeda0b` — R5 — Reconhece um título visível depois de comentário HTML ou de linha inválida como abertura de cerca de crases.
  Os dois casos abrem um turno antes da espera. Títulos em comentários ou cercas reais não abrem turno.
  A espera continua única e preserva `rc=3`, `phase-ceiling` e o diagnóstico do predecessor na fixture.
  As 15 sabotagens do leitor foram detectadas. Os controles com as mesmas limitações passaram antes e depois.

## Correção da REVIEW r3

- `9551b6e3` — R6 — Uma marca de comentário em código cercado não oculta o título que segue o item de lista.
  Na jornada pública de `run`, um título único gera `start, wait` e dois títulos iguais geram só `wait`.
  A espera permanece única com `rc=3`, `phase-ceiling` e o diagnóstico original.
  As 21 sabotagens do leitor foram detectadas. Os controles com limite de 12 s e 256 MiB passaram antes e depois.

## Correção da REVIEW r4

- `9d53509f` — R7 — O leitor respeita os limites de blocos HTML brutos antes de interpretar cercas e títulos Markdown.
  Depois do bloco, um título visível único inicia um turno antes de esperar. Dois títulos iguais ou um título
  contido em comentário mantêm só a espera. Nos três casos, a espera única conserva `rc=3`, `phase-ceiling`
  e o diagnóstico original.
  Passaram os 19 cenários de R7, os controles R5/R6 e a reserva única. As 28 sabotagens do leitor e as 37 dos sensores
  foram detectadas em cópia descartável, com controles verdes antes e depois sob os mesmos limites.

## Correção da REVIEW r5

- `1a50dd42` — R8 — O HTML bruto acompanha o recuo do item. Ao sair dele, a mesma
  linha volta ao leitor de marcação. Título único visível gera `start, wait`. Título duplicado
  ou ainda oculto gera só `wait`. A espera única mantém `rc=3`, `phase-ceiling` e o diagnóstico original.
  Passaram os 15 cenários de R8, os controles R5–R7 e a jornada de reserva única.
  As 16 sabotagens do leitor e as 34 dos sensores foram detectadas em cópias
  descartáveis. Os controles rodaram verdes antes e depois, em grupo próprio, com 256 MiB por processo
  e teto de 12 s por sonda. A jornada de reserva usou 40 s com o mesmo limite de memória.

## Artefatos

| Arquivo | O que contém |
|---|---|
| `checkpoint.md` | Checks e commits de implementação dos 24 incrementos. |
| `commands/sdd-worker.md` | Procedimentos de despacho, retomada, aprovação e espera. |
| `bin/sdd-worker-ahead` | Confirmação do dono do checkout, reserva do sucessor e chamada ao relay. |
| `tests/check-worker-ahead.py` | Jornada de três lotes, concorrência, recusas, revalidação e leitura do pedido com marcação Markdown. |
| `tests/check-worker.sh` | Executa o bloco público de seleção da revisão e mede os 13 cenários com controles negativos. |
| `e2e/check-worker-lookahead-race.py` e `e2e/check-worker-review-probe.py` | Reproduções dos dois achados de QA. |

## Boot da próxima fase

Leia `00-missao.md`, `01-plano.md`, `checkpoint.md` e as seções da REVIEW r1 a r5 neste handoff. Rode `tests/run-all.sh` neste checkout e refaça os Checks R1–R8 do checkpoint com `bash tests/check-worker.sh`. Para reteste de QA, use também os registros BUG-01 e BUG-02 de `30-handoff-qa.md`. Não é necessário subir uma aplicação, chamar o GitHub ou iniciar um planner pago.

Na jornada de merge, confira que só chega a `ready <sha>` um PR cujo `local/ci` resulta da suíte completa naquele head. No mesmo SHA, uma aprovação curta é informativa, mas um corpo acionável ou pedido vigente bloqueia. Inventário e prontidão recusam um campo `comments` presente e inválido, sem reabrir uma thread resolvida válida.

Na jornada de retomada, confirme a ordem runner → relay → espera, a reserva única e o acesso do relay à fila canônica sem cópia na base. Para a campanha `20261117-zerar-as-issues`, `ahead-request` referencia o pedido original do dono, identificado nas decisões 1 e 7 de `00-missao.md`. Referência local vencida ou alterada antes do despacho mantém a sugestão e preserva o resultado da espera. Aprovar o sucessor ainda depende de merge, revalidação e autoridade própria.

No reteste de R5, a asserção `valid markdown owner request survives preceding markup` exercita o bloco público de `run`
com um runner simulado. Os casos com título visível, inclusive os dois reproduzidos na REVIEW r2, devem registrar
`start` antes de `wait`. Os títulos ocultos devem registrar só `wait`. Os controles de R3 ainda recusam referências
vencidas, ambíguas ou dentro de código real. A asserção `authorized ahead planning starts once before wait` repete
a jornada de reserva única, retomada e revalidação sem disparar um planner real.

No reteste de R6, rode `bash tests/check-worker.sh` e confira a asserção
`owner request distinguishes unique and duplicate headings after list code`. Os casos
`list-fenced-comment-marker` e `duplicate-after-list-code` reproduzem a REVIEW r3. O primeiro deve
registrar `start, wait` e o segundo só `wait`. Rode também a jornada de reserva única do mesmo Check.

No reteste de R7, `bash tests/check-worker.sh` deve marcar `owner request ignores list fence lookalikes in raw html`.
Para isolar a reprodução, rode `python3 tests/check-worker-ahead.py "$PWD" --preceding-markup <caso>`
com `html-before-unique`, `html-before-duplicate` e `html-before-comment`. Só o primeiro deve registrar
`start, wait`. Os outros devem registrar apenas `wait`, e todos devem preservar o mesmo diagnóstico do runner.

No reteste de R8, o Check do checkpoint exige a marca `owner request bounds raw html by its list item`
e a jornada de reserva única. Para isolar R8, rode
`python3 tests/check-worker-ahead.py "$PWD" --preceding-markup <caso>` com `html-list-end-unique`,
`html-list-end-duplicate`, `html-list-end-script` e `html-list-still-inside`. Os casos de título único e
de `script` devem registrar `start, wait`. O duplicado e o título ainda recuado devem registrar só `wait`.
O runner simulado conserva `phase-ceiling` e `sdd run stop: phase-ceiling — fixture` nos quatro.

## Pendências / Decisions for a Human

- Nenhuma decisão nova de produto em aberto. A emissão de termos assinados continua com o dono.

## Riscos e não-feitos

- O leitor continua restrito às construções que usa para resolver a âncora. Não substitui um renderizador Markdown.
- O fluxo real com Codex e GitHub não foi iniciado nesta fase. A fixture não prova permissões de publicação, status ou threads.
- O despacho automático usa o relay Codex. Sem pedido verificável, ou em outro harness, a rota manual permanece disponível.
- Não foi alterada a política por lote do `curso-ddd`. Não houve publicação, aprovação externa nem merge real.

## Achados fora de escopo

- Nenhum achado novo nos incrementos R5 a R8. O falso verde de `local/ci` com `TEST_CMD` só de espaços continua no `TODO.md`, conforme a REVIEW r2.
