# TODO — `sdd_agents`

Achados que **não cabem na missão atual**, registrados por qualquer agente ou humano
(kaizen princípio 10: oportunidade registrada, nunca desvio de escopo, nunca achado perdido).
Formato, esqueleto e ciclo de vida: [`templates/todo.pt-BR.md`](templates/todo.pt-BR.md) — a
semente que o `sdd install` grava nos repos-alvo, uma variante por `OUTPUT_LANG`, com a forma
medida por `tests/check-todo.sh`. Os planos estacionados do kit moram na gaveta,
[`docs/superpowers/specs/2026-09-23-a-gaveta-do-kit.md`](docs/superpowers/specs/2026-09-23-a-gaveta-do-kit.md).

Achados sobre **repos-alvo** vão para o `TODO.md` daquele repo. Este arquivo é só sobre o kit.

> **Catraca do volume — crescer é permitido, crescer calado não.** Quantos itens este arquivo
> carrega é o achado `todo-findings <N>` do `sdd health`, congelado em `tests/health-baseline.txt`.
> Reprova nos **dois** sentidos: número que subiu sem registro, e baseline que ficou para trás
> depois de uma faxina. Quem acrescenta item aqui **e** move a linha da baseline no mesmo commit
> está certo — o número tem dono e aparece no diff. Quem só acrescenta descobre no `sdd health`.
> Ela mora lá e não no `TEST_CMD` porque um teto dentro da suíte reprovaria toda missão em voo.
> ⚠️ A contagem sai de `tests/check-todo.sh`, nunca de um `grep -c '^- \[ \]'`, que não sabe
> onde a seção aberta termina.
> A fila de PRs de achado (cada um move a mesma linha da catraca e o fim da mesma seção, e
> conflita com o seguinte) tem receita em [`docs/finding-prs.md`](docs/finding-prs.md), que também
> serve ao chore pós-merge que apaga os itens `RESOLVED by` de uma missão.

## Aberto
<!-- sdd:open -->

### Prioridade — resolver logo

- [ ] **O `review-ci` publica `local/ci` verde com `TEST_CMD` só de espaços** — `bin/sdd-worker:1598` (`TEST_CMD`) —
  Dois espaços passam no teste de vazio. O Bash retorna zero sem executar comando e `pr-ready` lê `ready` no mesmo SHA.
  Direção: tratar valor composto só de espaços como vazio e testar que a prontidão continua bloqueada.
  Fonte: `docs/handoffs/20261126-l5b-o-worker-e-os-verbos-dele/40-review-r2.md` — descoberto por `sdd-reviewer`
  na missão `20261126-l5b-o-worker-e-os-verbos-dele` (2026-11-27)

- [ ] **Missão: fazer o worker de campanhas funcionar também no Codex** — `commands/sdd-worker.md:59`
  (`harness:`) — só aceita `claude`, embora o Codex já consiga chamar os verbos de `bin/sdd-worker`.
  Direção: aceitar `harness: codex`, retomar planner e grill e definir a integração com `sdd run` (hoje `claude -p`).
  Preservar o fluxo Claude e as regras de delegação, orçamento, aprovação e retomada.
  Aceite: campanha de teste no Codex real, sem publicação, e regressão do fluxo Claude.
  **Preferir o próprio Codex para planejar, implementar e validar a missão**, para medir o harness real.
  — registrado a pedido do dono ao planejar a S10 do `ui24_agent` (2026-11-21)

- [ ] **O carimbo é tudo ou nada: uma linha de prosa em `agents/` refaz o catálogo inteiro** — `bin/sdd:2700`
  (`MUTATION_STAMP_PATHS`) — a chave é um md5 dos arquivos rastreados em `bin/ tests/ templates/ config/ agents/`,
  menos o `tests/health-baseline.txt`, e o pulo do catálogo (PR #330) só vale com ela igual. O PR #337 mudou
  prosa do `agents/sdd-executor.md` e uma sonda do `check-hat.sh`, e o `sdd health` refez o catálogo (775
  mutantes em 2026-10-26) por mais de 3 h, até o dono mandar parar: ele pediu não recarimbar o que já está
  carimbado. Nenhum veredito por mutante persiste (o mapa guarda o matador e o tempo). Direção: guardar o veredito
  com as dependências do mutante (alvo, sensores, runner, config) e refazer só o que mudou, e sempre o sobrevivente.
  — descoberto pelo relay da 3.5d do `dotp-remake`, com o dono (2026-11-02)

### Sensores que faltam

- [ ] **O probe do processo deixado pelo TEST_CMD falha de forma intermitente** —
  `tests/check-preflight.sh:1607` (`st_warn_at`) — o sensor isolado do I15 não viu o aviso do processo residual,
  embora a suíte de base e a execução isolada seguinte o tenham visto. Isso pode bloquear o controle de mutação.
  Direção: verificar a prontidão do filho antes de o fixture devolver o controle ao preflight.
  Fonte: `docs/handoffs/20261121-l5-saida-humana-e-contrato-do-runner/checkpoint-notas.md`
  — descoberto por `sdd-executor` na missão `20261121-l5-saida-humana-e-contrato-do-runner` (2026-11-25)

- [ ] **A cópia do catálogo deixa o controle do check-hat sem os guias que ele lê** —
  `tests/check-mutation.sh:8955` (`sandbox`) — `--only … check-hat.sh` retorna `HARNESS-BROKEN` sem sabotagem.
  Faltam `docs/finding-prs.md`, `docs/plan-only.md` e `docs/failure-modes.md`. Com os três, controle verde.
  Direção: copiar os guias e testar o controle do catálogo com o conjunto que o sensor lê.
  Fonte: `docs/handoffs/20261121-l5-saida-humana-e-contrato-do-runner/checkpoint-notas.md`
  — descoberto por `sdd-executor` na missão `20261121-l5-saida-humana-e-contrato-do-runner` (2026-11-25)

- [ ] **O fixture de fast-forward do close esconde falhas na criação do remoto** —
  `tests/check-gates.sh:7175` (`git clone`) — uma rodada de `--only` parou em `HARNESS-BROKEN` sem o diretório
  `peer`. O bloco descarta stderr do push e do clone e só acusa a comparação do fast-forward.
  Direção: validar a preparação do remoto e mostrar qual comando falhou antes de medir o close.
  Fonte: `docs/handoffs/20261121-l5-saida-humana-e-contrato-do-runner/checkpoint-notas.md`
  — descoberto por `sdd-executor` na missão `20261121-l5-saida-humana-e-contrato-do-runner` (2026-11-25)

- [ ] **A prosa que a DOCS escreve depois da REVIEW não passa por revisão nenhuma** — `bin/sdd:3118` (`PHASES`) —
  a ordem é `REVIEW DOCS PR`: o `gate_REVIEW` aceita B na prosa (`REVIEW_PROSE_MIN_GRADE`), o achado de prosa vai
  ao `TODO_FILE` e quem reescreve a prosa é a DOCS, cujo gate lê a checklist, não a prosa. Na 3.2a do `dotp-remake`
  uma r2 extra do `/codereview:codereview` achou 1 MEDIUM na prosa da DOCS (`3044b3c`): o ponteiro novo diz que
  toda condição do filtro está na linha do `Add`, e faltava o `FE_NUM_COLOURS` (consertado em `3a57106`).
  Direção: a REVIEW revê o diff da DOCS antes do PR, ou o corpo do PR diz que essa prosa ninguém revisou.
  Fonte: PR `j0ruge/dotp-remake#10`, Evidências (r2 e r3) — descoberto por `/codereview:codereview` (r2) na
  missão `20261019-plano-3-2-a-magicas-de-uma-vez` (2026-10-19)

- [ ] **Nenhum sensor relê os Checks `done`, e o R que estende a família de um I o deixa vermelho calado** —
  `tests/check-checkpoint.sh:1669` (`red_one`) — o `--red` roda só as linhas `pending`. Na r5 do worker, o R9 e
  o R10 puseram linhas nas famílias `worker templates:` e `command:`, que o I1 e o I9 contavam com número exato:
  os dois ficaram vermelhos no head sem aviso, achados por um script da sessão (`5565a41`, `995c4ad`). Direção:
  um `--green <checkpoint>` que roda o Check de cada linha `done` e nomeia a que não dá o esperado, e o
  `sdd-reviewer` avisado de que o R que conta uma família já contada acerta o esperado da linha antiga.
  Fonte: `docs/handoffs/20261117-o-worker-orquestrador/checkpoint-notas.md` — descoberto pela sessão
  orquestradora na missão `20261117-o-worker-orquestrador` (2026-11-18)

- [ ] **O `gate_REVIEW` aprova a tabela de notas a que falta um critério** — `bin/sdd:2160` (`gate_REVIEW`) —
  o comentário diz "a partial review is not a review", mas o gate conta linhas, não critérios: uma
  `### Overall Grade` só com a linha `**Overall**` em A passa (`rows > 0`), e o gate não nomeia os
  oito critérios do `templates/review.md`. O `pr-ready` do worker já tem uma lista explícita.
  Direção: o gate exige uma linha por critério do template e nomeia no motivo o que falta.
  Fonte: `docs/handoffs/20261117-o-worker-orquestrador/40-review-r6.md` — descoberto por `sdd-reviewer` na
  missão `20261117-o-worker-orquestrador` (2026-11-18)

- [ ] **O `pr-ready` não lê o corpo de uma revisão, a `CHANGES_REQUESTED` sem inline nem o `local/ci`** —
  `bin/sdd-worker:1955` (`cmd_pr_ready`) — a régua original só nomeava threads. No PR #414, 18 dos 38
  achados do CodeRabbit estavam no corpo da revisão. O I8 da L5b já exige `local/ci` no SHA testado e
  atribui a publicação ao ato `review`. Faltava ler o corpo da revisão e a `CHANGES_REQUESTED` sem inline.
  Direção: o I9 registra o tratamento dos achados e bloqueia o merge com pendência. RESOLVED by 2d81fe7
  Fonte: `docs/handoffs/20261117-o-worker-orquestrador/40-review-r6.md` — descoberto por `sdd-reviewer` na
  missão `20261117-o-worker-orquestrador` (2026-11-18)

- [ ] **Nenhum ato do worker resolve os threads de review, e o item `threads` do `pr-ready` fica sem dono** —
  `commands/sdd-worker.md:519` (`merge`) — um rc 1 do `pr-ready` manda voltar "to the act that fixes it", e
  para `not-ready threads` não havia ato: o `review` conserta o que a rodada acha e pede o `@codex review`, mas nada
  resolve o thread de bot cujo achado um commit já fechou. No PR #414 os R6–R10 consertaram os achados do
  CodeRabbit e os 20 threads seguiram abertos (princípio 1: item que nenhum ato escreve). Direção: o `review`
  resolve o thread cujo achado um commit fechou, nomeando o commit na resposta. RESOLVED by 2d81fe7
  Fonte: `docs/handoffs/20261117-o-worker-orquestrador/checkpoint-notas.md` — descoberto pela sessão
  orquestradora na missão `20261117-o-worker-orquestrador` (2026-11-19)

- [ ] **O LOW de comportamento que a rodada do worker manda ao chore volta como achado do Codex** —
  `commands/sdd-worker.md:581` (`Fix what the round finds`) — sob a régua A (decisão do dono, 2026-11-18) o
  LOW vai ao chore, mas o item `codex` do `pr-ready` pede recibo sem achado aberto. Duas vezes o Codex deu P2
  a um LOW deixado ao chore e a rodada voltou ao PR: no PR #457 (`af6d490`, um dos LOW da r4) e no PR #458
  (`f2559cb`, o LOW 3 da r3, consertado em `3000409`; 38 min do recibo ao merge). Os três LOW só de
  comentário da r5 do PR #460 ele não levantou. Direção (decisão do dono, toca a régua A): o `review` conserta
  na leva o LOW que nomeia entrada e saída errada; só o de prosa ou registro vai ao chore, como no `sdd-reviewer`.
  — descoberto pela sessão orquestradora na campanha `20261117-zerar-as-issues` (2026-11-21)

- [ ] **O `pr-ready` conta como fechado o thread que o próprio bot resolveu, sem resposta do worker** —
  `bin/sdd-worker:1657` (`reviewThreads`) — o item `threads` lê só o `isResolved`. No PR #458, 14 dos 16
  threads foram resolvidos pelo `coderabbitai[bot]`, 12 sem resposta do worker, com o bot sem cota (`Review
  limit reached` sobre `4ef8e23..f2559cb`), e o verbo deu `ready`. Os 12 eram consertos reais, mas o thread
  que o bot fecha porque a linha mudou passa calado. Vizinho de "Nenhum ato do worker resolve os threads".
  Direção: ler `resolvedBy` e os autores, e contar como aberto, pelo id, o thread resolvido por outra conta
  sem resposta da conta do PR.
  — descoberto pela sessão orquestradora na campanha `20261117-zerar-as-issues` (2026-11-21)

- [ ] **A parada `conflict` do worker leva ao dono a linha de estado que os dois lados reescreveram** —
  `commands/sdd-worker.md:755` (`conflict`) — só o conflito no `TODO.md` e na catraca fica com o worker. No L4
  (`20261121-l4-preflight-health-e-sensores`) o publisher parou (`b03993b`) num conflito com a `main` do PR #460 na
  linha F6 da gaveta, que todo lote reescreve: cada lado com a sua frase, e a união resolveu (`67d69db`), mas a
  campanha esperou o dono das 04:25 às 07:49. Direção (decisão do dono): a parada lista, com o `TODO.md` e a
  catraca, os arquivos de estado que o worker resolve pela união (hoje a gaveta), nomeada no merge e no diário.
  — registrado a pedido do dono na parada `conflict` do L4, campanha `20261117-zerar-as-issues` (2026-11-22)

- [ ] **O `/sdd-worker` chamado com argumento entrega o trecho do `sdd run` com o `$1` trocado** —
  `commands/sdd-worker.md:317` (`bash -c`) — o carregador de comando do Claude Code troca `$0`, `$1` e `$2` (base
  zero) pelas palavras do argumento, também dentro de aspas, e deixa `${1}`, `$@`, `$?`, `$!` e o `$N` sem argumento.
  Medido em 2.1.327: a sonda `/subst-probe alfa beta gama` deu `"$1"` → `"beta"` e `${1}` intacto, e o `/sdd-worker`
  chamado com "Continuar a campanha …" mostrou `sdd run "a"`. Quem copia o trecho roda a missão errada. Direção: o
  trecho sem parâmetro posicional (`${1}`, ou a missão numa variável) e um sensor que recuse `$<dígito>` em `commands/`.
  — descoberto pela sessão orquestradora na campanha `20261117-zerar-as-issues` (2026-11-22)

- [ ] **O `budget` esquece calado o gasto de uma missão que nunca chegou à base e cujo worktree saiu** —
  `bin/sdd-worker:908` (`cmd_budget`) — o conjunto lê o disco e a base, e o ledger não sabe de campanha: com o
  PR fechado sem merge ou a missão largada e o worktree removido, o `budget` dá US$ 0.00 no lugar dos US$ 85 do
  ledger, rc 0, e o teto que o R14 chama de limite duro passa por esse gasto. O R16 só o declara. Direção
  (decisão do dono na pendência 1 da r7): a linha `session` do ledger ganha `campaign:`, que o runner lê do
  `00-missao.md`, e o `budget` soma o gasto da campanha por esse campo. RESOLVED by 1af340a
  Fonte: `docs/handoffs/20261117-o-worker-orquestrador/40-review-r7.md` — descoberto por `sdd-reviewer` na
  missão `20261117-o-worker-orquestrador` (2026-11-18)

- [ ] **O PR sem conflito ainda quebra o `TODO.md` do alvo quando a missão paralela entra antes** —
  `agents/sdd-publisher.md:48` (`status: blocked`) — o publisher só para no conflito textual, o GitHub dá
  `MERGEABLE CLEAN` e o `TEST_CMD` mede o HEAD, não a mescla. O `j0ruge/magic_tutor#254` moveu o `descrever` da
  `monitor/bancada.py` meia hora antes de o `j0ruge/magic_tutor#259` abrir, com o item 150 ancorado no lugar velho
  (o espelho das issues trava; `b8cf0cc`); no `j0ruge/magic_tutor#176` (2026-11-04), dois itens 85. Direção: antes do
  push, o publisher mede a árvore de `git merge-tree --write-tree origin/<base> HEAD` (`--anchors` e número repetido) e
  para com `status: blocked`; a base que anda depois do push fica descoberta até quem faz o merge refazer essa medida.
  — descoberto pela sessão que acompanhou o `sdd run` no `magic_tutor` (2026-11-18)

- [ ] **Os leitores da tabela de notas seguem lendo depois da linha em branco, no worker e no runner** —
  `bin/sdd-worker:1405` (`round_grades`) — ele, o `round_unjustified` e o `round_missing` pulam a linha que não
  é de tabela e seguem até o próximo heading: uma linha de critério solta abaixo da tabela, na mesma seção
  `### Overall Grade`, conta. O `gate_REVIEW` do `bin/sdd` lê igual, e consertar só o worker quebra a paridade
  que o `check-worker.sh` segura. Direção: parar na primeira linha fora da tabela, nos três e no runner, com probe.
  Fonte: `docs/handoffs/20261117-o-worker-orquestrador/triagem-coderabbit.md`, item 6 — descoberto pelo
  `coderabbitai` no PR #414, triado pela sessão orquestradora (2026-11-19)

- [ ] **O mutante `range_ancestry_unchecked` só troca a mensagem, e o ancestral segue conferido** —
  `tests/check-mutation.sh:7526` (`mut_WORKER_range_ancestry_unchecked`) — ele desliga o `"$anc" -eq 1` do
  `cmd_pr_ready`, e o `"$anc" -ne 0` logo abaixo recusa o mesmo rc 1 com outra frase: o catálogo o pega pela
  mensagem, e o mundo que o comentário dele promete (uma rodada sobre um commit que o PR largou) nunca é montado.
  Direção: trocar também o `-ne 0` por `-gt 1`, provado por `--only WORKER_range_ancestry_unchecked check-worker.sh`.
  Fonte: `docs/handoffs/20261117-o-worker-orquestrador/triagem-coderabbit.md`, item 13 RESOLVED by f7b8071
  — descoberto pelo `coderabbitai` no PR #414, triado pela sessão orquestradora (2026-11-19)

- [ ] **Os probes de nota do `pr-ready` passariam pelo item `dirty` com o leitor de nota frouxo** —
  `tests/check-worker.sh:2103` (`grade_is`) — as sondas `Security B`, `Overall A-`, a da linha recuada e a da
  tabela sem linha editam o `40-review-r2.md` sem `land` e casam só `not-ready review: `, e o `dirty` também
  reprova a árvore suja com esse prefixo: um `pr-ready` que aceitasse B ou A- seguiria vermelho pelo motivo
  errado. Direção: `land` depois de cada edição e exigir o texto do ramo (`grades B`, `has no row for`), como a
  sonda do `deadbeefdead` já faz.
  Fonte: `docs/handoffs/20261117-o-worker-orquestrador/triagem-coderabbit.md`, item 16 RESOLVED by f7b8071
  — descoberto pelo `coderabbitai` no PR #414, triado pela sessão orquestradora (2026-11-19)

- [ ] **Dois leitores de "o que mudou" listam com detecção de rename, e um `git mv` esconde o caminho que saiu** —
  `bin/sdd:14422` (`review_head_ok`) — e `hat_diff_names`, a guarda do chapéu: `git diff --name-only` sem
  `--no-renames` mostra só o destino de um arquivo movido sem mudança (git 2.43.0: `git mv run.sh d/m/run.sh` dá
  só o destino; `--no-renames` e `diff-tree -r` dão os dois), e a saída de código de fora do `writes:` passa calada.
  O `gate_PR` ganhou `--no-renames` em j0ruge/sdd_agents#458 (CodeRabbit 4654284461). Direção: `--no-renames` nos
  dois, o mundo do `git mv` no `check-gates.sh` e no `check-hat.sh`, um mutante por sítio (censo `diff.*--name-only`).
  — descoberto na r3 da REVIEW do worker na missão `20261121-l3-gates-do-fim-da-linha` (2026-11-21)

- [ ] **Um Check por presença de um ID solto fica verde por outra mudança, e o `--red` não vê o termo cego** —
  `agents/sdd-planner.md:176` (`Write a Check by the PRESENCE`) — a regra não avisa que um ID curto (`D13`) pode
  nascer de outro PR entre o plano e o EXEC: num alvo, o `a=$(grep -c 'D13' …)` de um `test "$a" -ge 1 -a …`
  ficou sempre verdadeiro quando outro PR deu à D13 outro assunto, e o `--check` disse `none blind`, porque o
  Check inteiro seguia vermelho (faltava o registro): o `--red` prova "not green", não "red for the right reason".
  Direção: a presença do que só o incremento escreve (ID e texto, `^. D18 . .*texto`); mais caro, o `--red`
  avaliar cada termo de um `test … -a …`. Fonte: o `checkpoint.md` do alvo `expiry_guardian`, antes da aprovação
  — descoberto por `claude` na missão `20261124-m0-caracterizacao-do-mvp` (2026-11-25)

- [ ] **Ninguém remede as âncoras `arquivo:linha` do `01-plano.md` entre o plano e o `sdd run`** —
  `agents/sdd-planner.md:105` (`file:line`) — o planner exige a âncora com o comando que a mediu, mas só o
  `TODO_FILE` tem quem a remeça (`tests/check-todo.sh --anchors`), e a guarda de plano velho fica com cada plano:
  num alvo, ela conferia `git diff --stat <sha>..HEAD -- src supabase package.json` e daria vazio, mas as linhas
  97 e 252 do roadmap que um incremento edita por número tinham ido para 99 e 277 com outro PR (medido com
  `grep -n -F -x` da linha antiga). Direção: a guarda cobre todo caminho que o plano cita como `path:N`, ou um
  `--anchors` para o `01-plano.md` que compara o texto da linha no commit do plano com o HEAD. Fonte: o plano
  — descoberto por `claude` na missão `20261124-m0-caracterizacao-do-mvp` (2026-11-25)

### Contrato e configuração

- [ ] **O leitor de lookahead não conta o título ATX na linha de um marcador de lista** —
  `bin/sdd-worker-ahead:116` (`re.fullmatch`) — o título de `- # Owner request` não entra na contagem.
  A sonda pública reproduziu a recusa do título único e o disparo com dois títulos na base e no head.
  Direção: provar os dois casos e resolver o título pelo conteúdo Markdown do item.
  Fonte: `docs/handoffs/20261126-l5b-o-worker-e-os-verbos-dele/40-review-r7.md`
  — descoberto por `sdd-reviewer` na missão `20261126-l5b-o-worker-e-os-verbos-dele` (2026-11-27)

- [ ] **O plano manda o EXEC editar em `.claude/`, o `claude -p` recusa, e a sessão contorna pelo Bash** —
  `config/schema.md:149` (`claude -p`) — no I6 da missão `20261020-narracao-com-dicas` do `magic_tutor`
  (`49d2c89`) o "Onde" listava `.claude/skills/revisar-partida/`; o `Edit` foi recusado e o executor trocou o
  texto por um script Python via Bash, a rota que o `schema.md:144-148` fecha ao `sdd-docs` em `.claude/rules/**`.
  O planner aceitou o I6 sem aviso, e o `check-checkpoint.sh --check`/`--red` não olham caminhos. Direção: o
  planner (ou o `--check`) avisa o incremento EXEC que toca `.claude/`, e o executor deixa o texto proposto ao
  humano no PR, como o `sdd-docs`. Fonte: `20-handoff-exec.md:167` da missão.
  — descoberto por `retrofit-watch` no `magic_tutor` (2026-10-20)
  RECURRED 1: magic_tutor/20261118-o-que-a-mesa-nao-diz (2026-11-18)

- [ ] **O veredito da QA não é revalidado depois de um R<n>** — `docs/pipeline.md:99` (`R<n>`) — o REVIEW
  vem depois da QA e um `R<n>` muda o código sem reabri-la: o reteste do lote 7 só lê `F<n>`, e o `skipped`
  que o `sdd-qa` conferiu no diff não é reconferido (Codex no PR #247, 14ª rodada; 22 de 64 missões reais
  tiveram `R<n>`). Falha aberta, com consumidor fora da suíte do kit (D15). Direção: amarrar o veredito
  ao commit que a QA viu e decidir, com custo medido, o que um `R<n>` reabre (um reteste custou US$ 7,19).
  Fonte: `docs/handoffs/20261012-a-rota-da-qa/00-missao.md` — D21 do grill, registrado pelo `sdd-planner` (2026-10-14)
- [ ] **O platô da REVIEW lê só as letras, e pararia um laço que converge** — `agents/sdd-reviewer.md:68`
  (`Overall Grade`) — "as mesmas letras da rodada anterior" é platô, mas não separa o achado que a rodada
  não fechou do material que entrou entre as rodadas sem ser `R<n>`, nem da classe que a varredura pulou. No
  `lighthouse_project` a REVIEW ficou em B de r3 a r6, cada rodada com um achado real e menor, fechado pelo
  `R<n>` seguinte sem defeito novo; 4 dos 7 da r6 vieram de um bump commitado entre r5 e r6. A regra teria
  parado na r4; a r7, com só o `R7` entre as rodadas, deu A em tudo. Direção: só `R<n>` entra entre rodadas,
  o boot da rodada lista o commit que não fecha `R<n>`, e o platô compara a classe do achado, não só a letra.
  — descoberto por `sdd-reviewer` na missão `20261013-amep-alignment-review` (2026-10-14)

- [ ] **Num repo sem interface, a QA para em `BLOCKED` ao seguir a própria instrução de escrever o teste do achado** —
  `agents/sdd-qa.md:11` (`writes:`) — o § 3 manda o achado de lógica virar teste da suíte do `TEST_CMD` (linha 107),
  e o `writes:` não cobre a suíte. No `magic_tutor`, a `QA:close` da `20261024-mesa-e-escolhas` (1522 s, US$ 7,96)
  commitou o sensor vermelho do F1 em `tests/test_replays.py`: `touched 1 path(s) outside its writes`, rc 3; destravou
  com `HAT_WRITES_EXTRA="sdd-qa: tests/**"`, que todo repo sem interface repetiria (a lista que o `config/schema.md`
  diz que a chave substituiu). Direção: decidir de quem é o sensor do achado de lógica (a QA, com a suíte no
  `writes:`, ou o EXEC do `F<n>`) e alinhar o texto e o `writes:` do chapéu.
  — descoberto pelo `sdd run` da missão `20261024-mesa-e-escolhas` do `magic_tutor` (2026-10-24)
- [ ] **A guarda do kit para a corrida do alvo por um merge só de docs no checkout do kit** — `bin/sdd:4928`
  (`kit_guard_check`) — compara o par cru (HEAD e sujeira) e não lê o rótulo `sdd:` do reflog (anatomia §6). No
  lighthouse o operador puxou o #246 e o #254 (só `docs/`, `TODO.md` e catraca) para o checkout principal do kit
  com a corrida viva: `kit-touched` 2×, 2 células `refez` e 2 das 6 intervenções da missão; o reflog dizia
  `merge origin/main: Fast-forward`, sem rótulo. Direção: com ADR, só o HEAD movido por entrada do reflog sem o
  rótulo da sessão (alheia, como esse fast-forward) e que não toca `bin agents templates config` vira aviso no
  journal; a sujeira não commitada, que não deixa reflog, e o resto continuam parando a linha.
  — descoberto por `sdd-kaizen` na missão `20261014-amep-entrada-em-dois-niveis` (2026-10-20)

- [ ] **O chapéu não pode declarar MCP, e o executor fica sem o REA** — `bin/sdd:6090` (`--strict-mcp-config`) —
  toda fase roda sem servidor MCP, e um `mcp:` no chapéu para o runner ("carving those servers into a
  --mcp-config is not implemented"). No `dotp-remake`, ler o `DotP_D14.exe` pelo MCP `rea` só cabe no PLAN: na
  3.3d o planner levantou no REA o que o EXEC precisaria ler, e o dono pediu o REA também no `sdd run`. Direção:
  montar um `--mcp-config` com só os servidores que o chapéu declara, tirados da config do humano (o `rea` traz
  frida, gdb e adb: o recorte é a fronteira), e o `hat_init_facts` já compara o declarado com o visto.
  Fonte: grill da 3.3d do `dotp-remake` (2026-10-21) — descoberto por `sdd-plan` (relay) no `dotp-remake` (2026-10-21)

- [ ] **O remédio do `qa: skipped` refutado apaga, com o handoff, os achados fora de escopo dele** —
  `agents/sdd-qa.md:79` (`delete this handoff`) — o `git rm` do `30-handoff-qa.md` tira da árvore a seção
  "Achados fora de escopo", e o achado do kit que só existia ali (o item acima) ficou só no histórico do alvo:
  o humano seguiu a receita no `magic_tutor` (`74c5610`) e só o achou na retro da sessão. Direção: o passo 4
  manda levar antes os achados do kit ao `TODO.md` do kit, ou o runner os colhe antes do `git rm`.
  — descoberto pela retro do `sdd` no `20261103-perfil-por-tipo` do `magic_tutor` (2026-11-03)

- [ ] **O `config_key` do worker põe o valor do ambiente sem `export`, e o filho que o config abre lê vazio** —
  `bin/sdd-worker:372` (`config_key`) — o `printf -v "$key"` vale só para o shell que sourceia o `.sdd/config.sh`,
  e o runner lançado com a chave no ambiente a recebe exportada: um config que escolhe o teto num `bash -c` ou
  num `$(…)` dá o default (150) ao `budget` e o 40 ao `sdd run` (reproduzido: o filho lê `[]`, e com `export`
  antes, `[40]`). Direção: `export "$key"` depois do `printf -v`, antes de sourcear. RESOLVED by d1e8d0f
  Fonte: `docs/handoffs/20261117-o-worker-orquestrador/triagem-coderabbit.md`, item 1 — descoberto pelo
  `coderabbitai` no PR #414, triado pela sessão orquestradora (2026-11-19)

- [ ] **O `effective_level` confere o `expires:` antes do conjunto e publica o nível depois dele** —
  `bin/sdd-worker:487` (`expired`) — o `expired "$exp"` roda antes do `campaign_set` e do `checkouts_of`, e o
  `LEVEL` acima de `assisted`, o teto do lote incluso, sai depois: a delegação que vence nessa janela (de
  milissegundos, não reproduzida) ainda dá o nível assinado. O laço pergunta `allows` antes de cada ato, o que
  estreita a janela sem fechá-la. Direção: reler o `expired` logo antes de publicar um `LEVEL` acima de `assisted`.
  RESOLVED by d1e8d0f
  Fonte: `docs/handoffs/20261117-o-worker-orquestrador/triagem-coderabbit.md`, item 2 — descoberto pelo
  `coderabbitai` no PR #414, triado pela sessão orquestradora (2026-11-19)

- [ ] **O `checkouts_of` lê o `worktree list` sem `-z`, e o worktree com quebra de linha no caminho some** —
  `bin/sdd-worker:660` (`checkouts_of`) — o git 2.43 imprime o caminho cru, e o `sed 's/^worktree //p'` parte
  `…/wt` + `nl` em `…/wt` e uma linha solta (reproduzido): a missão desse worktree some calada do `budget`, do
  `level` e do `next`. Direção: `--porcelain -z`, lido por NUL e com o rc guardado; o `-z` pede git 2.36+, então
  antes decidir a versão mínima do git no kit. RESOLVED by 064098e
  Fonte: `docs/handoffs/20261117-o-worker-orquestrador/triagem-coderabbit.md`, item 3 — descoberto pelo
  `coderabbitai` no PR #414, triado pela sessão orquestradora (2026-11-19)
  RECURRED 1: sdd_agents/20261121-l5-saida-humana-e-contrato-do-runner (2026-11-26)

- [ ] **O `pr_states` descarta o PR de fork depois de o `gh pr list` cortar a lista em 30** —
  `bin/sdd-worker:1209` (`pr_states`) — o `gh pr list --head <branch> --state all` roda sem `--limit` (o padrão é
  30) e o `isCrossRepository` é lido depois do corte: com 30 PRs de fork na mesma branch, o PR da missão fica fora
  e o `next` não o vê. Direção: `--limit 1000`, ou parar com veredito não lido quando a contagem bater no limite.
  RESOLVED by 9ce1943
  Fonte: `docs/handoffs/20261117-o-worker-orquestrador/triagem-coderabbit.md`, item 5 — descoberto pelo
  `coderabbitai` no PR #414, triado pela sessão orquestradora (2026-11-19)

- [ ] **O yes do dono no passo 3 do laço do worker vale para o ato e não amarra o sha do merge** —
  `commands/sdd-worker.md:102` (`sdd-worker allows`) — "the yes stands for this step's rc 0" deixa o yes de um
  `merge` dado sobre o head A valer para o head B, quando os passos 1 e 2 trazem o mesmo ato. O `pr-ready` ainda
  exige rodada A e recibo do Codex no B; o risco é o dono não ter visto o B. Direção: o yes só se reaproveita com
  campanha, lote, missão, PR e comando iguais, e no `merge` também o sha.
  RESOLVED by 4edda89
  Fonte: `docs/handoffs/20261117-o-worker-orquestrador/triagem-coderabbit.md`, item 7 — descoberto pelo
  `coderabbitai` no PR #414, triado pela sessão orquestradora (2026-11-19)

- [ ] **O `postmerge` manda a linha do journal nomear o PR do que sobra para a base, sem dizer o que ela leva** —
  `commands/sdd-worker.md:657` (`postmerge`) — o `next` não deriva esse ato, e a frase não exige o número do PR de
  acompanhamento nem o estado da revisão dele: a sessão que retoma do journal não sabe se o PR abriu nem se a
  rodada dele fechou. Direção: a linha do merge traz o número do PR e `review pendente`, e a sessão retomada o
  conclui antes de chamar o `next`. RESOLVED by f3b4056
  Fonte: `docs/handoffs/20261117-o-worker-orquestrador/triagem-coderabbit.md`, item 8 — descoberto pelo
  `coderabbitai` no PR #414, triado pela sessão orquestradora (2026-11-19)

- [ ] **A parada do worker roda o `budget` de novo para montar o `SDD_GATE_WHY` do pager** —
  `commands/sdd-worker.md:85` (`sdd-worker budget`) — o `why` sai de rodar outra vez o verbo cuja linha parou o
  laço, e entre as duas leituras o teto pode ter subido ou um gasto entrado: o pager recebe uma linha que não é a
  que parou. Direção: guardar a saída do verbo no momento da parada (arquivo ou variável do mesmo lote) e reusá-la
  no journal e no `SDD_GATE_WHY`. RESOLVED by d7ca654
  Fonte: `docs/handoffs/20261117-o-worker-orquestrador/triagem-coderabbit.md`, item 9 — descoberto pelo
  `coderabbitai` no PR #414, triado pela sessão orquestradora (2026-11-19)

- [ ] **Uma edição do `.sdd/config.sh` durante a fase tira o teto de missão que a delegação assinou** —
  `bin/sdd:10748` (`delegated_claude_cap_check`) — o `config_reload` do runner relê o arquivo a cada volta, e
  a sessão que grava `BUDGET_MISSION_USD=0` desliga o teto nas voltas seguintes; o `budget` só roda entre atos. O
  template diz que a campanha só passa do assinado por três gastos, e este é um quarto. Direção: declarar o limite
  já, no `bin/sdd-worker` e no template; o conserto de verdade (o runner guardar o teto do lançamento) muda a
  precedência do `config_reload` e é decisão do dono. RESOLVED by ac581c8
  Fonte: `docs/handoffs/20261117-o-worker-orquestrador/triagem-coderabbit.md`, item 12 — descoberto pelo
  `coderabbitai` no PR #414, triado pela sessão orquestradora (2026-11-19)

### Saída humana e cosmética

### Comentário e registro

- [ ] **O handoff de R8 da L5b não vincula a saída das sabotagens aos resultados** —
  `docs/handoffs/20261126-l5b-o-worker-e-os-verbos-dele/20-handoff-exec.md:88`
  (`sabotagens do leitor`) — a contagem resume o resultado, mas não aponta a saída de cada mutante e controle.
  Direção: guardar os resultados por caso e vincular o comando, seu SHA, rc e saída ao resumo do handoff.
  Fonte: `docs/handoffs/20261126-l5b-o-worker-e-os-verbos-dele/40-review-r6.md`
  — descoberto por `sdd-reviewer` na missão `20261126-l5b-o-worker-e-os-verbos-dele` (2026-11-27)

- [ ] **O manual do pipeline acumula o guia completo do worker** — `docs/pipeline.md:1964` (`The worker`) —
  A seção do worker tem 507 linhas. Consultar só os verbos ou a prontidão de merge exige navegar pelo manual inteiro.
  Direção: extrair a seção para um guia do worker, manter um link no índice e verificar os links para os headings.
  Fonte: `docs/handoffs/20261126-l5b-o-worker-e-os-verbos-dele/45-docs.md`
  — descoberto por `sdd-docs` na missão `20261126-l5b-o-worker-e-os-verbos-dele` (2026-11-28)

### Idioma

### Custo e escala

- [ ] **Um incremento que roda por quase 1 h não cabe no `sdd-executor`, que não tem `Monitor`** —
  `agents/sdd-executor.md:7` (`disallowedTools`) — a fronteira do chapéu
  (`docs/superpowers/specs/2026-09-03-a-fronteira-do-chapeu-design.md`) tira o `Monitor` e o `ScheduleWakeup` do
  executor, e o Bash em primeiro plano para em 10 min. No `magic_tutor` (missão `20261021-dica-mais-rapida`), o I8 a
  I10 eram a bancada real (7 rodadas do coach, de 45 min a 1 h em segundo plano), e a sessão do relay os rodou à mão
  ("rodados pela sessão do relay", `checkpoint-notas.md`). Direção: o `/sdd-plan` marca como do operador o
  incremento cujo comando passa de 10 min, com o comando e o critério no plano, e o runner não o entrega ao executor.
  — descoberto pelo relay da missão `20261021-dica-mais-rapida` do `magic_tutor` (2026-10-21)

- [ ] **Um `sdd run` retomado sobre um handoff que já diz `status: blocked` compra uma sessão antes de parar** —
  `bin/sdd:10466` (`handoff_blocked_escalation`) — as duas portas do laço do `cmd_run` ficam depois do `run_phase`
  (desenho de `20260826-o-laco-da-qa`, mantido pelo I2 do L3), então o `50-pr.md` ou a rodada de REVIEW que já
  declaram `blocked` pagam uma sessão do chapéu (na REVIEW, opus) antes do rc 3 quando o humano relança sem ter agido;
  o `sdd retry` também. O marcador poupa a 2ª sessão, nunca a 1ª, e o comentário dele não diz isso. Direção a decidir:
  porta antes da sessão para o marcador que a derivação armou, ou o limite declarado no comentário.
  — descoberto pelo CodeRabbit em j0ruge/sdd_agents#458 ("Unverified", conferido na r3 da REVIEW do worker) na
  missão `20261121-l3-gates-do-fim-da-linha` (2026-11-21)

### Sem seção — chegaram depois da última classificação

> ⚠️ Esta seção **chamava-se "Adiados por YAGNI"** e não guarda mais nenhum adiamento: os três que
> havia (espelho global de vereditos, multi-missão por `git worktree`, `sdd digest`) viraram Y1–Y3
> da tabela **Decisões adiadas por YAGNI** do [`CONTEXT.md`](CONTEXT.md), onde cada um nomeia o
> evento que o reabre — pela régua D15, ausência de consumidor é decisão adiada, não achado. Os
> itens abaixo são achados de verdade que foram apendados ao fim do arquivo e nunca classificados;
> quem mexer num deles o move para a seção a que ele pertence.

- [ ] **O revisor não tem destino para o LOW que não move a nota** — `agents/sdd-reviewer.md:106`
  (`MEDIUM/LOW, cheap`) — a tabela manda todo MEDIUM/LOW barato para um `R<n>` de lote, mas a escala do
  `codereview` dá A com "minor MEDIUM/LOW", e as rodadas deixam o LOW no relatório com motivo escrito: na
  `20261028-whf-162-jdb-na-descricao` do `warehouse_explorer_web`, 11 LOW na r1, 2 na r2 e 6 na r3, e o gate
  passou na r3. Seguir a tabela compra uma EXEC que não muda nota; não seguir a contraria. Direção: uma linha
  "LOW sem efeito na nota → fica no relatório, com motivo", decidida junto da régua do `CONTEXT.md:140`.
  — descoberto pela retro do `codereview` na r3 da `20261028-whf-162-jdb-na-descricao` (2026-10-30)
  RECURRED 1: sdd_agents/20261117-o-worker-orquestrador (2026-11-18)

- [ ] **O `sdd approve` deixa fora do commit o que o planner escreveu fora da pasta da missão** —
  `bin/sdd:10249` (`cmd_approve`) — o commit leva só a pasta e o ADR. No `dotp-remake`, o planner da 7b1 deixou a página
  do llm_wiki, a linha dela no `indice.md`, no `log.md` e no índice do `CLAUDE.md`, sem commit; o relay as commitou à
  parte (`fa9bd84`). Com a regra do alvo de gravar o que se explora, isso vira rotina. Direção: o approve lista o que
  está modificado ou não rastreado fora da pasta e pergunta se entra, ou recusa com a lista.
  — descoberto pelo relay do `/sdd-plan` na missão `20261117-plano-7-b1-a-mesa-cheia` (2026-11-17)

- [ ] **Mitigação de risco do plano sem incremento se perde, e a REVIEW dá A mesmo assim** —
  `templates/plano.md:41` (`Riscos e não-feitos`) — o `01-plano.md:840` da 7b previu o engasgo da assadura e propôs
  assar os decks antes do primeiro quadro; nenhum incremento levou isso, o portão do I12 provava só que a arte chega,
  e a REVIEW deu A. O dono viu as janelas pretas no jogo, e o conserto foi à mão (`322aca8`..`1d1a0b7`). Direção: a
  coluna Mitigação aponta o incremento e o Check, ou "adiado → <missão>", e o PLAN-AUTO reprova a linha sem nenhum.
  — descoberto pelo dono e pelo relay na missão `20261116-plano-7-b-o-palco-3d` (2026-11-17)

- [ ] **A missão pedida fora da fila da campanha não tem rota, e a linha nova derruba a delegação** —
  `commands/sdd-worker.md:165` (`lot: <L>`) — o ato `plan` só conhece lote da tabela, e nada diz o que fazer
  quando o dono pede uma missão fora dela: sem `lot:` o `allows` dá `assisted`, com um `lot:` alheio o merge dá
  aquele lote por feito, e uma linha nova no `campaign.md` depois da assinatura muda o digest. Medido, diferencial
  sobre a delegação assinada de `cc8509a` com e sem a linha `L1b`: o L1 em voo passa a `edited after signing`.
  Com o L1b já planejado (17:58), o `next` responde `ahead plan L2` sem derivar o `approve` dele.
  Direção: publicar fila e `lots:` com a assinatura no mesmo commit. RESOLVED by f3b4056
  — descoberto pela sessão orquestradora na campanha `20261117-zerar-as-issues` (2026-11-19)

- [ ] **O ato `review` do worker mergeia a base antes da rodada, e o `review-base` dá `full` quando a `main` andou** —
  `commands/sdd-worker.md:490` (`review_scope`) — o ato manda `git merge origin/<base>` e só depois
  pergunta ao `sdd review-base`, que lê um merge depois da última rodada como rodada inteira; então a rodada
  do worker, a mais cara, só é delta quando a `main` não andou. Medido na r3 do #452: `full — merge 59be5eb
  entered after 40-review-r2.md`, 30 arquivos e 2 086 linhas, onde a branch andara 11 commits desde o
  `reviewed_head:` da r2. Direção: o `review-base` aceita o merge cujo lado da base não toca caminho que a
  branch mudou, ou o ato só mergeia a base quando o PR não é `MERGEABLE`. RESOLVED by 20ffaab
  — descoberto pela sessão orquestradora na missão `20261119-l1b-a-rodada-delta` (2026-11-20)

- [ ] **O merge delegado não confere que o corpo do PR lista as escolhas do grill** —
  `commands/sdd-worker.md:449` (`including ◆ choices`) — sob delegação o aceite do dono sobre as
  escolhas do grill vem depois do merge, pelo corpo do PR, e quem o escreve é o ato `pr`, que o `next` não deriva
  (todo PR aberto vira `review`). O `cmd_pr_ready` lê do PR só `headRefOid,mergeable,state`, e o único `.body`
  dele é o dos comentários do Codex: um lote pode mergear sem o registro que o dono aceitaria.
  Direção: o `pr-ready` confere no corpo uma linha por decisão `- answer:` do `00-missao.md` da missão.
  RESOLVED by 4edda89
  — descoberto pelo `coderabbitai` no PR #455, na campanha `20261117-zerar-as-issues` (2026-11-20)

- [ ] **A regra do teto da chamada `Bash` mora no revisor, e não no `turn_rule` de toda fase** —
  `bin/sdd:3878` (`turn_rule`) — a chamada `Bash` do harness para de esperar aos 120 s (600 s no máximo),
  e no L1 isso voltou três vezes: o item N (o `sdd why … EXEC` cortado aos 2 min no `magic_tutor`), a
  suíte do executor no I6 e no I9, e o R1 da r1. Só o revisor e a ajuda do `sdd why` dizem a regra.
  Direção: aplicar ao `turn_rule` o texto `⛔` do `45-docs.md` do L1, com asserção no `tests/check-dry-run.sh`.
  Fonte: `docs/handoffs/20261117-l1-a-prosa-do-chapeu/45-docs.md`
  — descoberto por `sdd-docs` na missão `20261117-l1-a-prosa-do-chapeu` (2026-11-19)

- [ ] **O planner manda chamar duas skills que a sessão pode não listar** — `agents/sdd-planner.md:42`
  (`Skill(grilling)`) — o § 1 manda `Skill(grilling)` e `Skill(domain-modeling)` e diz que o `grill-with-docs` é o
  pacote que "the model cannot invoke". No planner do L2 (subagente, Claude Code 2.1.327) a lista de skills trazia
  o `grill-with-docs` (cópia avulsa em `~/.claude/skills/`, sem `disable-model-invocation`) e nenhuma das duas, que
  só existem no clone do marketplace, sem plugin instalado; o grill seguiu só pelas regras do chapéu. Direção: o
  § 1 manda chamar a forma que a sessão lista, e o `sdd preflight` avisa quando nenhuma está instalada.
  — descoberto por `sdd-planner` na missão `20261120-l2-o-sdd-plan-e-o-planner` (2026-11-20)

- [ ] **O harness recusa o `rm` cujo alvo é um `$(…)`, e o `turn_rule` não avisa** — `bin/sdd:3878`
  (`turn_rule`) — no Claude Code 2.1.327 o `claude -p` nega a chamada `Bash` inteira quando um `rm` apaga a
  saída de uma substituição de comando ("cannot be auto-allowed by permission rules"). Na REVIEW r1 do L1b a
  negativa levou junto o `git add` e o `git commit` da rodada; a sessão refez com o caminho literal, ao custo de
  um turno, e uma que não refaça deixa a rodada fora do commit. Direção: uma frase no `turn_rule` (rodar a
  substituição antes e apagar o caminho literal), com asserção no `tests/check-dry-run.sh`.
  — descoberto por `sdd-worker` na missão `20261119-l1b-a-rodada-delta` (2026-11-20)

- [ ] **O ato `run` do worker lança o `sdd run` sem rodar o `sdd preflight`** — `commands/sdd-worker.md:316`
  (`setsid`) — e o `cmd_run` também não o chama, então a corrida de uma noite descobre na primeira fase o que as
  sondas achariam em segundos: sessão expirada, chapéu velho, skill ausente, hook quebrado. Custo a decidir no
  grill: o preflight roda o `TEST_CMD` inteiro, que no kit é a suíte toda. Direção, pedida pelo dono: o ato `run`
  roda o `sdd preflight` no worktree da missão antes de lançar, e para no `_fail`. RESOLVED by 2e8bd53
  — descoberto por `sdd-worker` na missão `20261119-l1b-a-rodada-delta` (2026-11-20)

- [ ] **O worker lê o `budget-exhausted` como o teto da missão, e o runner grava o mesmo `kind` no teto da fase** —
  `commands/sdd-worker.md:371` (`budget-exhausted`) — o `bin/sdd` grava `budget-exhausted` para os dois tetos e
  deixa o `gate_why` dizer qual (`bin/sdd:6656`). O ato `run` e a parada 4 do comando leem o `kind` sozinho como
  `mission-ceiling`. No L2, às 23:56, a fase PR esgotou as sessões dela (2 publishers sem `pr_url:`) com US$ 37 de
  60 gastos, e o ledger diz `budget-exhausted`. Um worker que lesse o ledger pararia a campanha pelo teto errado.
  Direção: o ato `run` separa os dois pelo `gate_why`, ou o runner ganha um `kind` próprio para o teto da fase.
  RESOLVED by d7ca654
  — descoberto por `sdd-worker` no pós-merge da missão `20261120-l2-o-sdd-plan-e-o-planner` (2026-11-21)

- [ ] **O `failure-modes.md` só conhece o `blocked` da suíte vermelha, e não o da parada que o plano manda** —
  `docs/failure-modes.md:161` (`found the suite red`) — a seção diz que a linha para "sem abrir sessão", porque a
  suíte de um incremento anterior ficou vermelha. Na 7b1 do `dotp-remake` o executor parou o I3 depois de uma
  sessão, num portão fora da faixa, e a decisão era do dono (o I8 parou do mesmo jeito); na 7c, o I9 parou no
  "Quando parar" do plano. O conserto verificado: a decisão no `01-plano.md` aprovado, o incremento em `pending`,
  um commit (`34738a8`, `b9fb061`) e o `sdd run`. Direção: a seção ganha essa causa, o sintoma e esse conserto.
  — descoberto pelo relay da missão `20261117-plano-7-b1-a-mesa-cheia` do `dotp-remake` (2026-11-17)
  RECURRED 1: dotp-remake/20261118-plano-7-c-o-hud-e-a-pilha (2026-11-20)

- [ ] **O `--budget-override` não aparece no `sdd run --help`, e quem o ensina é o `BLOCKED` do teto** —
  `bin/sdd:13602` (`--max-phases <N>`) — as opções do `run` na ajuda são `--dry-run`, `--phase` e `--max-phases`;
  a opção é lida no `cmd_run` (`:9647`) e no `cmd_retry` (`:10367`), e só o motivo do teto a nomeia (`:6118`),
  depois de a linha parar. Na 7b1 e na 7b2 do `dotp-remake` o teto de US$ 150 parou a run antes do PR, e o relance
  saiu dessa mensagem e do `docs/pipeline.md:1211`. Medido na `origin/main` `336640e`. Direção: a ajuda do `run`
  e a do `retry` listam `--budget-override`, com a nota de intervenção que ele escreve.
  — descoberto pelo relay da missão `20261117-plano-7-b1-a-mesa-cheia` do `dotp-remake` (2026-11-18)

- [ ] **O leitor D22 do aceite tira da conta, calado, o `- answer:` que leva nota depois do parêntese** —
  `commands/sdd-plan.md:296` (`N (recommended) of M`) — o `awk` casa só a linha inteira (`\)$`), e a linha
  `- answer: (recommended) — nota` some do `N` e do `M`. Na 7b2 do `dotp-remake`, 8 das 10 respostas tinham nota
  na mesma linha e a conta deu `2 (recommended) of 2`; com as notas numa linha `Revisão:` embaixo, `10 of 10`. A
  regra do planner (`agents/sdd-planner.md:59`) proíbe nota dentro do parêntese, não depois. Direção: o leitor
  conta toda linha `- answer:` da seção e nomeia a que não tem a forma inteira; o planner proíbe texto depois.
  — descoberto pelo relay na missão `20261117-plano-7-b2-o-selo-e-o-combate` do `dotp-remake` (2026-11-18)

- [ ] **O `⛔` que o humano aplica não tem grafia que o `gate_DOCS` aceite, e a DOCS roda de novo** —
  `bin/sdd:2420` (`cell == "n/a"`) — o gate rejeita texto adicional na célula de status, e nada diz como marcar o `⛔`
  já aplicado. Na 7b1 do `dotp-remake` o relay aplicou o texto (`756d51b`) e escreveu `⛔ → aplicado em 756d51b`;
  a run, ainda viva depois do PR, leu a célula como pendente, abriu uma DOCS de US$ 1,23 e a trocou por `✅` com o
  hash (`9c373d2`). Direção: a linha `- [ ] ⛔` do corpo do PR (`agents/sdd-publisher.md:79`) e o
  `docs/pipeline.md:510` dizem que o `⛔` aplicado vira `✅` com o hash do commit.
  — descoberto pelo relay da missão `20261117-plano-7-b1-a-mesa-cheia` do `dotp-remake` (2026-11-18)

- [ ] **A run segue viva depois de abrir o PR e rederiva tudo, e quem mexe no worktree antes do `rc` colide** —
  `bin/sdd:10840` (`derive_phase`) — o PR é a última fase, mas o laço volta à derivação, que roda o `TEST_CMD` nos
  gates e reabre a fase cujo artefato mudou. Na 7b1 do `dotp-remake` o PR abriu às 06:04, o relay commitou às
  06:06, a DOCS rodou de novo e o `rc=0` saiu às 06:21; na 7b2, 5,5 min de derivação depois do PR. O `ok gate PR`
  não avisa que a run continua. Direção: depois do `gate_PR`, uma linha diz que a run ainda deriva e manda esperar
  o `rc`, e o `docs/failure-modes.md` ensina o mesmo; ou a run sai no `gate_PR` sem rederivar.
  — descoberto pelo relay da missão `20261117-plano-7-b1-a-mesa-cheia` do `dotp-remake` (2026-11-18)

- [ ] **O teto da missão não soma a sessão que o ambiente matou junto com o runner** —
  `bin/sdd:6878` (`mission_cost_usd`) — a soma lê o `cost_usd=` das linhas do journal, e a linha da sessão só é
  escrita quando ela volta (`:5698`): morta junto com a run, não há linha, e sem `result` o custo vira `?`, que
  conta zero (`:5642`). Na 7b2 do `dotp-remake` a `5c6a936f` morreu no corte de luz, e 90,21 + 64,82 deram os
  155,03 do teto; na 7c a `159ca22a` (115 mensagens, 32,7 M de cache-read; a `5e44e390` leu 31,2 M e custou
  US$ 12,40) não tem linha. Direção: o `config/schema.md:294` declara o furo, e o `LEFTOVER` avisa o gasto órfão.
  — descoberto pelo relay da missão `20261117-plano-7-b2-o-selo-e-o-combate` do `dotp-remake` (2026-11-19)
  RECURRED 1: dotp-remake/20261118-plano-7-c-o-hud-e-a-pilha (2026-11-20)

- [ ] **O `failure-modes.md` solta a run com `setsid nohup`, e assim ela segue filha da tarefa que o host mata** —
  `docs/failure-modes.md:835` (`setsid nohup`) — sem `-f`, o `setsid` de um shell sem job control fica no mesmo
  PID, filho do shell (medido: com `-w` o `PPID` é o shell; com `-f`, um pai fora dele). Na 7c do `dotp-remake`, o
  `setsid -w nohup sdd run …` numa tarefa de fundo do Claude Code morreu no corte de memória com a sessão ociosa:
  `run-2.log` sem `rc=`, a `159ca22a` (I6) aberta, 47 entradas sujas. `git stash -u` e o relance por `setsid -f`
  passaram pelo corte das 02:05; na 7b2, depois do corte de luz, tree limpo e relance bastaram. Direção: a seção
  dá o `setsid -f` e diz o que fazer com o incremento pela metade (o boot o nomeia, ou `git stash -u`).
  — descoberto pelo relay da missão `20261118-plano-7-c-o-hud-e-a-pilha` do `dotp-remake` (2026-11-20)

- [ ] **Sem pasta de missão, o passo 1 do `/sdd-plan` lê corrida de qualquer repo como dona do checkout** —
  `commands/sdd-plan.md:31` (`pgrep -af '[b]in/sdd run'`) — o `pgrep` casa todo `sdd run` da máquina, e a saída
  "outro comando segura o checkout" fala de "a live `sdd run` of this repository": um alvo alheio rodando manda o
  relay cortar um worktree que não precisava. Falha para o lado seguro, mas custa uma pergunta e um worktree.
  Direção: casar o pid com este repo (o `cwd` em `/proc/<pid>/cwd`), ou mostrar a linha ao humano e deixá-lo decidir.
  Fonte: `docs/handoffs/20261120-l2-o-sdd-plan-e-o-planner/40-review-r1.md`
  — descoberto por `sdd-reviewer` na r1 da missão `20261120-l2-o-sdd-plan-e-o-planner` (2026-11-20)

- [ ] **O `sdd approve` com o `branch:` no placeholder commita onde a TICKET não corta** — `bin/sdd:7307`
  (`warn_if_on_base_branch`) — com `JIRA_ENABLED=true` e o `branch:` vazio ou `<...>`, o approve commita a pasta e
  o `adr:` no branch atual e só avisa quando ele é o `DEFAULT_BRANCH`. A skill `ticket` faz `checkout` e `pull` da
  base e corta dali: fora dela o plano não chega ao branch da missão, e o `checkout` tira a pasta da árvore da
  TICKET (reproduzido num repo de rascunho na r5). O aviso cala no único caso que perde o plano. Direção: com o
  placeholder, avisar fora da base e calar nela, um caso de cada lado no bloco 3c do `check-gates.sh`. Vizinho
  do item do `sdd run` que diz commitar na base: a mesma função, e o `cmd_run` cala nela.
  — descoberto pela r5 da REVIEW do worker na missão `20261120-l2-o-sdd-plan-e-o-planner` (2026-11-21)

- [ ] **O `/sdd-plan` manda dizer ao humano o id do planner, e o harness proíbe citá-lo na resposta** —
  `commands/sdd-plan.md:195` (`planner agent`) — o resultado do `Agent` no Claude Code manda não citar o id
  numa resposta ao usuário. O relay do L5 (2026-11-21 18:11) seguiu o harness e gravou o id num arquivo do
  scratchpad, que o handoff dele aponta; a retomada pelo id noutra sessão já está medida (3.2c do
  `dotp-remake`). Quem segue o comando expõe o id, e quem segue o harness perde o grill se a sessão cai sem
  handoff. Direção: o relay grava o id em disco (o handoff dele, ou a linha do diário da campanha) e diz ao
  humano onde está, nunca o id na resposta.
  — descoberto pela sessão orquestradora na campanha `20261117-zerar-as-issues` (2026-11-21)
  RECURRED 2: curso-ddd/relay-do-sdd-plan (2026-11-23); expiry_guardian/20261124 (2026-11-24)

- [ ] **Num projeto novo, o `/sdd-plan` para na árvore suja que o próprio `sdd install` deixou** —
  `commands/sdd-plan.md:43` (`A dirty tree with no command`) — a receita do `docs/plan-only.md` e o
  "Next: $ /sdd-plan" do `sdd-link-agents` levam direto ao passo 1, e o `git status --porcelain` logo depois
  da instalação já mostra `?? .gitignore`, `?? .sdd/` e `?? TODO.md`. A saída da árvore suja manda parar e
  perguntar a base, por caminhos que o kit acabou de criar. Direção: a receita commita a instalação antes do
  `/sdd-plan`, ou o passo 1 reconhece esses três caminhos e diz isso ao humano numa linha.
  — descoberto pelo relay do `/sdd-plan` no primeiro plano do repositório `curso-ddd` (2026-11-23)

- [ ] **O reteste do QA que só roda o sensor dá pass ao que a correção quebrou ao lado** — `config/schema.md:124`
  (`QA_DOCS_PATH`) — o `docs/qa` não diz como retestar. Num guia de estudo em HTML (2026-11-22), três retestes
  acharam bugs novos ao lado das correções: o anel de foco que o escuro forçado do Chrome levou a 2,03:1, a dica
  "arraste" que o mouse não faz, o magenta trocado no gráfico e esquecido no rótulo. Um reteste de conteúdo deu
  pass a um bug cuja frase ("a norma não fixa") saiu de duas lições e ficou numa terceira página, com todos os
  sensores verdes. Direção: o reteste refaz a reprodução pela persona, procura o efeito colateral perto da
  correção e varre o artefato inteiro pelo padrão corrigido, antes de dar `verified`.
  — descoberto no QA do guia de estudo do `PROJETO_FINAL`, com o método do kit aplicado à mão (2026-11-22)

- [ ] **O agente que corrige grava a seção Fix só no fim, e morto no meio deixa código mudado e bug vazio** —
  `config/schema.md:124` (`QA_DOCS_PATH`) — no mesmo QA, a máquina reiniciou com o agente de correção no meio:
  `quiz.js`, `estudo.css`, `diagramas.js` e sete sensores já estavam mudados, e os sete bugs dele seguiam com a
  seção Fix vazia e `Status: open`. O orquestrador teve de refazer, por cópia sabotada, a prova de que cada sensor
  falha com o bug presente. Direção: quem corrige preenche Fix (causa, correção, sensor antes e depois) e muda o
  status bug a bug, logo que cada um fecha, e não num lote no fim.
  — descoberto no QA do guia de estudo do `PROJETO_FINAL` (2026-11-22)

- [ ] **O planner marca o critério c com ✅ pela própria releitura e o deixa para um aceite que não o refaz** —
  `agents/sdd-planner.md:216` (`Self-containment test`) — o planner que leu a conversa inteira não é sessão nova.
  A evidência de c dizia "o aceite do `/sdd-plan` o refaz", e o aceite (`commands/sdd-plan.md:259`) só mede,
  renderiza e pergunta. Um teste independente (sessão nova, só leitura) achou 5 pontos de adivinhar e 2
  contradições, um deles uma variável sem padrão que gravava o commit do repo errado com rc 0. Direção: o hat
  recusa ✅ em c sem sessão independente, ou o aceite a despacha antes da pergunta YES/NO.
  — descoberto pelo relay da missão `20261123-curso-ddd-l1-base-e-aulas-1-4` do `curso-ddd` (2026-11-23)

- [ ] **Um fato de outro repositório no "Contexto verificado" é medido pelo topo do ramo, que anda sozinho** —
  `agents/sdd-planner.md:110` (`beside every count`) — `git -C <loja> log --oneline -1 main` → `fd39d62` provava
  um merge no `main` de outro repo. Um commit do relay lá, durante o aceite, mudou a saída com o fato intacto, e
  a regra do commit do relay (`commands/sdd-plan.md:163`) só cobre o repo alvo. Corrigido no plano por
  `merge-base --is-ancestor fd39d62 main; echo $?` → `0`. Direção: fato de outro repo se mede pelo próprio fato
  (ancestral, `grep` no arquivo), nunca pelo topo de um ramo.
  — descoberto pelo relay da missão `20261123-curso-ddd-l1-base-e-aulas-1-4` do `curso-ddd` (2026-11-23)

- [ ] **No alvo, o checkout da campanha é o da missão, e uma linha do journal durante o run para a fase** —
  `commands/sdd-worker.md:103` (`journal.md`) — o passo 5 só proíbe o journal no checkout do kit, e a seção do
  worktree (linha 122) supõe a missão fora do checkout da campanha. No `curso-ddd` os dois são o mesmo, no ramo da
  missão. Medido numa fixture com o `hat_guard_check` (`bin/sdd:5106`): uma linha nova num journal limpo durante a
  REVIEW dá `touched 1 path(s) outside its writes`, o `hat-crossed`; com o journal já sujo antes da fase, nada; na
  EXEC, nada. O `dirty-tree` só para a EXEC com a suíte vermelha. Direção: o passo 5 vale também para esse checkout.
  — descoberto pela sessão orquestradora na campanha `20261123-curso-ddd` do `curso-ddd` (2026-11-23)

- [ ] **O `!` do Claude Code fecha o stdin, e o `sdd-worker delegate` do dono sai 66 sem assinar** —
  `commands/sdd-worker.md:45` (`sdd-worker delegate`) — o texto manda o dono assinar "in a terminal of his own" e
  não fala do `!`. Pelo `! sdd-worker delegate <campanha>`, o `read` do `cmd_delegate` (`bin/sdd-worker:304`) achou
  o stdin fechado: `not signed — no answer reached the prompt`, rc 66. O `! printf 'y\n' | sdd-worker delegate`
  assinou. Os limites declarados da ADR 0022 (linha 168) dizem só que a assinatura prova uma resposta no stdin.
  Direção: o passo 2 diz que o `!` fecha o stdin e qual forma serve, e a frase do rc 66 nomeia o `!`.
  — descoberto pela sessão orquestradora na campanha `20261123-curso-ddd` do `curso-ddd` (2026-11-23)

- [ ] **O aviso "kit behind origin/main" conta commits e não separa um atraso só de `TODO.md`** —
  `bin/sdd:6584` (`rev-list --count`) — o `kit_stale_check` conta `HEAD..origin/<def>` e diz "every phase runs
  the older runner, hats and templates". Medido no checkout do kit em 2026-11-23: 6 commits atrás, e o diff deles
  só toca `TODO.md` e `tests/health-baseline.txt` (0 caminhos de `bin agents templates config`). O
  `KIT_BEHAVIOR_PATHS` (`bin/sdd:4534`) já separa o que uma fase executa. Direção: o aviso conta só os commits
  que tocam `KIT_BEHAVIOR_PATHS`, e um atraso só de achados vira linha `dim`, não `warn`.
  — descoberto pela sessão orquestradora na campanha `20261123-curso-ddd` do `curso-ddd` (2026-11-23)

- [ ] **O `ahead plan` não lê a intenção do dono de planejar o lote só depois do merge do anterior** —
  `bin/sdd-worker:1330` (`ahead plan`) — o `next` dá `ahead plan <lote seguinte>` sempre que o lote atual está em
  `run` ou `review` e o seguinte não tem missão. No `curso-ddd` respondeu `ahead plan L2`, e o `campaign.md` diz só
  na prosa "A missão do L2 se planeja depois do merge do L1". Nenhuma chave do frontmatter nem coluna da tabela
  (`templates/campaign.md:30`) diz isso, e o `lots_table` lê só `Lot` e `Ceiling`. Direção: uma coluna ou valor
  que o `next` lê e que cala o `ahead` daquele lote.
  — descoberto pela sessão orquestradora na campanha `20261123-curso-ddd` do `curso-ddd` (2026-11-23)

- [ ] **No `ListAgents` do worker, a fase do próprio `sdd run` parece outra sessão interativa do checkout** —
  `commands/sdd-worker.md:66` (`names who holds a checkout`) — o worker leu `curso-ddd-bf` e `curso-ddd-dc` como
  outro worker. Medido: o run tem um só filho `claude -p` por vez, e o `~/.claude/sessions/<pid>.json` dele diz
  `kind interactive`, nome `curso-ddd-<2 hex>` novo a cada fase e o `sessionId` da fase no log (PID 3041580,
  `20cac683…`). Em 2026-11-24, `curso-ddd-1c` era a fase `DOCS` (`7cb194af…`), e o dono perguntou se ela parara.
  Direção: o worker reconhece a fase pelo PID do run e pelo log, e o passo 4 diz isso; ou o runner passa
  `--name sdd-<missão>-<fase>` (`claude --help`: `-n, --name`) no `claude -p` (`bin/sdd:5924`), ainda não medido.
  — descoberto pela sessão orquestradora na campanha `20261123-curso-ddd` do `curso-ddd` (2026-11-23)

- [ ] **O ato `pr` do worker não diz que o `gh pr edit` falha, e o aviso mora só no chapéu do publisher** —
  `commands/sdd-worker.md:449` (`grill answers`) — o ato manda pôr no corpo do PR as respostas do grill e os bots
  que não revisaram, sem dizer como. O `agents/sdd-publisher.md:100` manda o `gh api -X PATCH`, com o corpo num
  arquivo, e proíbe o `gh pr edit`, que falha no gh 2.45; o worker não lê esse chapéu. Medido no PR
  j0ruge/curso-ddd#1, gh 2.45.0: o `gh pr edit 1 --body-file …` saiu rc 1 com `GraphQL: Projects (classic) is being
  deprecated …`, e o corpo ficou como estava; o `gh api -X PATCH` saiu rc 0, com as duas seções no corpo.
  Direção: o ato `pr` cita a mesma chamada REST.
  — descoberto pela sessão orquestradora na campanha `20261123-curso-ddd` do `curso-ddd` (2026-11-24)

- [ ] **Sob merge delegado, o run diz que só falta o merge com a REVIEW em B, e o `pr-ready` recusa** —
  `bin/sdd:10887` (`pipeline complete`) — a spec do merge delegado (§1 e M5) diz que o piso B do
  `REVIEW_PROSE_CRITERIA` não basta ao dono e que a régua é do alvo, mas nada a configura: o `curso-ddd` ficou
  com o `REVIEW_PROSE_MIN_GRADE="B"` do starter. A r3 deu Documentation B, o `gate_REVIEW` passou, e o run disse
  `only the merge is left`; o dono pediu o merge, o `pr-ready` deu `not-ready review: … every row must read A`
  (rc 1), e o ato `review` fez a r4 com o PR aberto, como na 5a do M5. Direção: o `allows run` avisa no nível
  `merge` com o piso abaixo de A no worktree da missão, e o fim do run nomeia o próximo ato do worker.
  — descoberto pela sessão orquestradora na campanha `20261123-curso-ddd` do `curso-ddd` (2026-11-24)

- [ ] **Os logs de sessão só existem no checkout da corrida, e o `sdd census` de outro checkout responde vazio** —
  `bin/sdd:1112` (`log_dir`) — a missão rodada num worktree ligado (ADR 0016 §2, ADR 0022 §7) deixa os streams
  só no `.sdd/logs/` dele, ignorado, e o `git worktree remove` os apaga sem aviso (5 worktrees, 278 arquivos).
  Do principal, `sdd census 20261112-as-reincidentes-primeiro` dá o cabeçalho e o boot bill, nenhuma fase, rc 0,
  sem dizer que a pasta não existe; o `e2e_red_history` do `gate_QA` também só lê o checkout atual. Direção: o
  census avisa a pasta ausente; o desenho maior leva o log ao diretório comum do git, como o carimbo (ADR 0021).
  — descoberto na limpeza dos worktrees da campanha `20261117-zerar-as-issues` (2026-11-24)

- [ ] **O `sdd install` grava um `TEST_CMD` vermelho num repo Node sem script `test`** — `bin/sdd:6705`
  (`npm test`) — o `node_test_cmd` encadeia os scripts de gate e termina sempre em `npm test`, declarado ou
  não, e sempre com `npm`, mesmo com `bun.lock`. No `expiry_guardian` (só `build`, `lint`, `dev`, sem `test`;
  `bun.lock` e `bunfig.toml`) saiu `npm run lint && npm run build && npm test`, e o `sdd preflight` reprovou
  (`TEST_CMD FAILED (rc 1)`); reproduzido num repo de rascunho, onde o `npm test` sozinho sai com rc 1.
  Direção: só pôr o `npm test` quando `scripts.test` existe, e escolher o runner pelo lockfile
  (`bun.lock`/`bun.lockb` → `bun run`, `pnpm-lock.yaml` → `pnpm`, `yarn.lock` → `yarn`).
  — descoberto pela retro do retrofit-watch ao instalar o kit no `expiry_guardian` (2026-11-23)

- [ ] **O `sdd install` deixa vazio o `READ_EXTRA` que o `sdd preflight` pede logo em seguida** —
  `config/starter.conf:60` (`READ_EXTRA=""`) — o preflight já acha a skill `codereview:codereview` e diz a
  entrada exata (`$HOME/.claude/plugins/cache/chewiesoft-marketplace/codereview`), mas o install semeia o
  starter com a chave vazia. Todo alvo novo nasce com a REVIEW sem ler as references da skill, a mesma
  leitura negada que a fase do `1fcb66cc` sofreu em 2026-11-18, até alguém copiar o aviso à mão.
  Direção: o install semear o `READ_EXTRA` com as entradas que a busca do preflight resolve (o mesmo
  `plugin_install_paths`), e avisar só do que não achou.
  — descoberto pela retro do retrofit-watch ao instalar o kit no `expiry_guardian` (2026-11-23)


- [ ] **Duas alocações concorrentes de ADR reservam o mesmo número em worktrees distintos** —
  `bin/sdd:9929` (`adr_next_id`) — duas chamadas reais sincronizadas após a leitura do máximo
  reservaram 0001 com rc 0 em ambos os worktrees. A exclusividade por caminho não serializa a
  escolha do número entre checkouts. Direção: desenhar uma reserva compartilhada por ID.
  Fonte: `docs/handoffs/20261121-l5-saida-humana-e-contrato-do-runner/40-review-r1.md`
  — descoberto por `sdd-reviewer` na missão `20261121-l5-saida-humana-e-contrato-do-runner` (2026-11-26)

- [ ] **O Check I18 do L5 conta resoluções de fora da missão** —
  `docs/handoffs/20261121-l5-saida-humana-e-contrato-do-runner/checkpoint.md:68` (`Fecho`) —
  a contagem global mudou de 17 para 18 com o conserto da ajuda, sem alterar os 17 hashes planejados.
  Direção: em checagens de fecho, comparar os títulos previstos e os hashes, sem somar resoluções alheias.
  Fonte: `docs/handoffs/20261121-l5-saida-humana-e-contrato-do-runner/40-review-r5.md`
  — descoberto por `sdd-reviewer` na missão `20261121-l5-saida-humana-e-contrato-do-runner` (2026-11-26)

## Decidido — não reabrir
<!-- sdd:decided -->
- **O laço de melhoria da sessão interativa não enxergaria o kit** — resolvido fora do kit, sem commit deste repo: `retrofit-watch` 0.2.0 (`j0ruge/skills@960e47b`) reconhece `/sdd-*`, subagente `sdd-*` e o CLI `sdd` (2026-10-01)
- **O `RESOLVED by` não deixa a catraca descer na missão que conserta** — decidido: o item fica até o merge e sai no chore pós-merge, `templates/todo.pt-BR.md` § Ciclo de vida (2026-09-25)
- **O stub do `sdd adr new` manda escrever em `OUTPUT_LANG`, e o `check-lang.sh` lê `docs/adr/` como inglês** — limite declarado pela D15, não achado: `bin/sdd:7388` (2026-09-25)
- **Aviso de merge durante a janela do juiz** — decidido fora: depois do conserto do eixo (I2) só mudança real do kit rompe a janela, e essa é ruptura legítima — `docs/adr/0014`, missão `20261001-a-janela-nao-se-parte` (2026-10-01)
- **A refutação R2 do handoff de QA citaria evidência que não existe** — refutado: o prompt renderizado nomeava o arquivo, porque o boot_prompt expande `$TODO_FILE` para TODO.md; o item conferiu a fonte, não o prompt — `148f693:bin/sdd:1683` (2026-10-03)
- **O sdd status travaria mais de 2 min segurando a trava do checkout** — refutado como defeito sem causa e como fila: sem `--no-gates` o status avalia todo gate sob a trava, TEST_CMD e E2E_CMD incluídos, e a segura enquanto eles rodam, sem prazo; a trava é não-bloqueante, então quem chega depois não enfileira, recebe CHECKOUT-BUSY com o dono; a leitura sem trava é `sdd status --no-gates` — `bin/sdd-coordination.py:504` (2026-10-03)
- **O cmd_kaizen escalaria no-progress como fricção no rubric depois de um retry que moveu** — decidido: o código escala sem olhar o moved2, mas as linhas KAIZEN são `$meta` e ficam fora do eixo do juiz nos dois leitores; o humano lê "two sessions without satisfying the gate", que é verdade — `bin/sdd:10322` (2026-10-03)
- **A Âncora 3 do gate_QA bloquearia a missão com bug aberto de OUTRA missão** — decidido por desenho: a ADR 0009 mantém recusada a alternativa (A) da 0006, porque contar só o bug da missão troca o laço por dívida calada; a saída humana é `deferred` — `docs/adr/0009-the-genre-gains-deferred-and-hats-gain-project-exceptions.md` (2026-10-03)
- **Slug de missão em pt-BR não poderia ser citado na superfície inglesa** — decidido: o selftest do check-lang afirma de propósito que slug em prosa é pego (exit 95); slug se cita numa linha `Spec:`/`ADR:` ou sem stopword — `tests/check-lang.sh:195` (2026-10-03)
- **As skills qa-report e qa-execution não conhecem o campo Closable by** — decidido: o lado do kit fechou (o sdd install semeia o campo, o sdd preflight reprova sem ele, o sdd-qa marca); ensinar a skill de terceiro é retrofit no marketplace, não item do kit — `f7bcf10` (2026-10-03)
- **O rows=13 do gate: da QA de 20260818-lote-facil não sai do extrator** — decidido: o número citado não reproduz (o extrator dá 8, o próprio item o mediu) e a conclusão da J6 segue certa; handoff de fase encerrada não se reescreve — `docs/handoffs/20260818-lote-facil/30-handoff-qa.md:7` (2026-10-03)
- **Nada mediria se o esperado de um Check do checkpoint ainda reproduz** — limite declarado: o cabeçalho do sensor diz que ele não mede o valor ao lado da seta, de propósito; rodar os Checks custaria a suíte por célula — `tests/check-checkpoint.sh:45` (2026-10-03)
- **O kit não tem CHANGELOG.md, e a fase DOCS cobraria um** — decidido: a linha do CHANGELOG na DOCS é condicional (só quando a missão entrega algo visível) e nenhum gate a cobra; o registro do kit é KAIZEN_LOG.md, handoffs, git log e corpo do PR — `agents/sdd-docs.md:49` (2026-10-03)
- **O teto de orçamento não conhece "missão reaberta"** — decidido: a porta humana para gastar mais é `--budget-override` com a nota intervention: que o runner escreve (anatomia §7) — `bin/sdd:5106` (2026-10-03)
- **O gate: do frontmatter da revisão só é cobrado quando existe** — decidido, sem conserto: as 6 rodadas sem o campo (de 30) são de 2026-08-16/17, anteriores a ele, e as 24 seguintes o trazem — `bin/sdd:1835` (2026-10-03)
- **run_phase cria o diretório de log da sessão sem guarda** — decidido, sem conserto: a falha é alta e fechada (rc 1 antes de abrir sessão, zero gasto) e nunca foi observada — `bin/sdd:4745` (2026-10-03)
- **Check de ausência reprovaria o conserto que precisa citar o defeito** — decidido: falha fechada, um caso em 2026-08-16; a regra de redação de Check do planner vem com o achado do Check que nasce verde, na leva 4 — `docs/handoffs/20260816-runner-sem-dividas/checkpoint.md:20` (2026-10-03)
- **A suíte segue acima do alvo "<30 s" da D7** — decidido: o critério (4) da D7 passa a ser o prazo por passo do step_timeout (8× o tempo ocioso, piso 60 s), que já é o orçamento medido e cobrado; o 🚩 do CONTEXT.md fecha — `tests/run-all.sh:168` (2026-10-03)
- **O 2º Python do worker custa ~30 ms em toda chamada coordenada** — decidido: 30 ms por chamada não chega ao humano; provar o worker por FD herdado pede ADR e fica na gaveta, F1 P1 — `docs/superpowers/specs/2026-09-23-a-gaveta-do-kit.md:67` (2026-10-03)
- **35% do docs/pipeline.md seria um subsistema só, e cresceria a cada missão do ledger** — decidido, sem refator: as seções do ledger e do juiz são 525 de 1562 linhas (33,6%), estáveis em 33–34% desde 2026-09-29 depois do pico de 48% em 2026-08-31, e nenhum boot_prompt lê o pipeline.md, então nenhuma fase paga o índice inteiro; reabre se a fatia passar de 40% ou se um boot passar a ler o arquivo — `docs/pipeline.md:1100` (2026-10-04)
- **Test Coverage = A do revisor implicaria que os casos negativos existem** — decidido como limite: a nota de revisão é rótulo que o próprio modelo escreve, e a anatomia §4 o declara; a parte barata e real, o executor sabotar a linha nova de um R<n>, é o I3 de 20261004-lote-4-a-catraca-zera; reabre quando um segundo P1 escapar de um Test Coverage = A numa missão headless — `.claude/rules/anatomia-do-agente.md:126` (2026-10-04)
- **Nenhum instrumento mediria prosa de CONTRATO fora de templates/** — decidido: a fase DOCS é a dona dessa prosa (a checklist de drift do 45-docs.md percorre o diff inteiro da missão), o config/schema.md já é medido contra o load_config pelo sdd health, a tabela de agentes do README bate 8 = 8, e os drifts registrados foram pegos antes do merge; o limite está no cabeçalho do sensor; reabre quando um drift de contrato escapar para a main — `tests/check-templates.sh:39` (2026-10-04)
- **O checkpoint não teria grafia para incremento cujo produto não é commit** — decidido: a grafia é o commit de registro — o ato fora do git (e-mail, página da KB, config no IdP) deixa na pasta da missão um record-<ID>.md com o que foi feito, a URL ou o ID e a data, e o hash dele vai na célula Commit que o gate_EXEC já lê; passo pós-merge ou de janela externa sai da tabela para as Pendências para o humano do 00-missao.md ou para a missão seguinte (o token de espera é o Y8 do CONTEXT.md); os casos medidos (o I5 da LH-3, KB sem commit; o I6 de 20260918-a-excecao-do-chapeu-e-o-genero-diferido, pending eterno; os I1–I3 de 20260825-cif-forma-pagamento no sales_quote, blocked eterno) não são migrados, porque handoff fechado não se reescreve — `templates/checkpoint.md:35` (2026-10-04)
- **Drift de comentário em código não teria dono: nem a DOCS nem a EXEC** — decidido: comentário de código é do código — a REVIEW o manda para um lote R<n> da EXEC, a DOCS marca ⛔ com o texto proposto (o bin/sdd fica fora do writes: dela, e o gate só recusa ⛔ em documento que ela pode escrever), ou ele vai para o TODO_FILE quando o carimbo não compensa; o caminho estreito "a DOCS edita só hunk de comentário" falharia aberto, porque o bin/sdd tem 6 heredocs e # dentro de string, awk e jq; 0 hat-crossed por código em 15 sessões DOCS desde 2026-09-12 — `agents/sdd-docs.md:104` (2026-10-04)
- **A entrada do índice na árvore do kit leva vírgula inicial (`@,100644:…`)** — decidido (D15): o mawk avalia o lado esquerdo de `ix[q] = (q in ix) ? … : e` antes do `in`, então toda entrada nasce com `,`; é representação interna, igual nas duas amostras que a guarda compara, e o motivo do `kit-touched` não a imprime — sem consumidor, não é achado — `bin/sdd:4078` (`kit_guard_tree`), revisão final de `20261008-lote-6-as-quatro-que-faltam` (2026-10-08)
- **`kit_checkout_targets_run` com `REPO_ROOT` vazio responderia "recusado"** — decidido (D15): inalcançável, a recusa de identidade do `cmd_kaizen` vem antes e o `load_config` sempre publica a raiz; reabre se a função ganhar outro chamador — `bin/sdd:11342` (`kit_checkout_targets_run`), revisão final de `20261008-lote-6-as-quatro-que-faltam` (2026-10-08)
- **A regra 2 do check-checkpoint deixa abertos os casos que só o runtime decide** — decidido sem conserto (decisão 1 do lote 10): um leitor de texto não decide o terceiro descritor, o alvo de runtime (`2>$f`), a grafia da stdout que o sistema resolve, a palavra que abre com expansão lida como operando, o `POSIXLY_CORRECT` ou outro grep, nem o nome que substitui o grep; a peça que mediria a Check em execução não tem dono (no PLAN a asserção ainda não existe, e gate não executa texto de modelo); 0 de 67 checkpoints escrevem uma dessas grafias, e o cabeçalho do sensor as declara; reabre quando uma Check real escrever uma delas — `docs/handoffs/20261016-lote-10-as-cinco-livres/00-missao.md` (2026-10-16)
- **A regra 2 aceita a âncora seguida de uma expansão no padrão** — decidido sem conserto (decisão 1 do lote 10), confirmando a decisão 8(a) do lote 9: o padrão `dq` ancora pelo prefixo literal antes da 1ª expansão, limite declarado no cabeçalho do sensor; recusá-lo deixaria vermelha a varredura do kit em 2 checkpoints fechados (a I10 de 20261002-onde-o-comando-do-humano-escreve e a I20 de 20261003-lote-3-a-catraca-desce, cuja expansão é uma contagem da catraca), e nenhum texto prova que a expansão não acrescenta padrão nem alternância; reabre quando uma Check real escrever, depois da âncora, uma expansão que possa trazê-los — `docs/handoffs/20261016-lote-10-as-cinco-livres/00-missao.md` (2026-10-16)
- **A menção `@codex review` no corpo do PR não pediria a revisão do Codex** — refutado: no PR `j0ruge/dotp-remake#11`, aberto às 22:34:17Z com a menção no corpo, o Codex abriu o Code Review de `d959395` 14 s depois ("Manual request" no resumo do bot), sem o aviso "create an environment" dos #9 e #10 — `j0ruge/dotp-remake#11` (2026-10-19)
