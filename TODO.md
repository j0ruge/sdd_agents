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

## Aberto
<!-- sdd:open -->

### Sensores que faltam

- [ ] **O Red do `R<n>` prova o achado, não o conserto: nenhum passo sabota a linha nova** —
  `agents/sdd-executor.md:83` (`Watch it fail`) — o conserto tira o sintoma e pode abrir um fail-open
  ao lado com o probe verde. Medido só no laço interativo (PR #45, #46; `coderabbit-pr` 2.4.0 já
  sabota); no headless, nunca. Direção: medir antes. O `40-review-r*.md` não grava o commit que
  gerou o achado, então um achado da rodada N+1 só conta se o `git blame` da âncora dele cair num
  commit `R<n>` da N; se houver caso, o executor sabota o conserto antes do commit. RESOLVED by 9c9c5e1.
  — descoberto pela sessão interativa ao avaliar o `/insights`, sem missão (2026-10-01)

- [ ] **A regra da âncora aceita qualquer símbolo citado que reapareça perto, e uma âncora podre passa** —
  `tests/check-todo.sh:2122` (`ANCHOR_REACH`) — um span de 4+ letras citado no item a até 10 linhas
  basta; identificador que se repete no arquivo inteiro casa em qualquer lugar. Medido em `b3b6b98`:
  `tests/check-autonomy.sh:6674` apontava para `exit 0` e passou verde porque `GIT_REFLOG_ACTION`
  está em 6400 — o sensor disse `every anchor on target`. Direção: exigir o símbolo na própria linha
  (ou no bloco da função), ou contar ocorrências e recusar símbolo que aparece em todo canto. RESOLVED by c2e508a.
  — descoberto por `revisor de tarefa` na missão `20261001-a-janela-nao-se-parte` (2026-10-01)

- [ ] **O carimbo de mutação cobre 4 dos 8 caminhos que a sandbox do catálogo copia** —
  `bin/sdd:2136` (`MUTATION_STAMP_PATHS`) contra `tests/check-mutation.sh:6269` — a chave lê
  `bin tests templates config`, mas `sandbox()` também copia `agents/`, `CLAUDE.md`, `TODO.md` e `docs/adr`. Mudança
  confinada a esses quatro mantém o carimbo válido sobre conteúdo que o catálogo de fato mede — a regra 12 do
  `check-health.sh` lê o `CLAUDE.md`. Estreitamento deliberado (a fase DOCS edita `CLAUDE.md`, e chavear nele custaria
  uma segunda rodada de ~20 min por missão). Direção: ler a lista do próprio `sandbox()`, decidido o custo.
  RESOLVED by f05aa7a.
  — descoberto por `sdd-executor` na missão `20260819-fecho-...` (2026-08-19)

- [ ] **O gate PLAN-AUTO aceita Check que já nasce verde** — `templates/missao.md:45` (`Check executável`) — o critério
  `d` cobra `Check executável (comando → esperado)`, não "Check que
  reprova o HEAD de hoje". Medido: o Check do I1 desta missão era `grep -c 'gate_DOCS reprova'
  TODO.md` → `0`, mas o título no `TODO.md` traz crases (`` `gate_DOCS` reprova ``), então o
  comando já devolvia `0` **antes** da remoção — verde por construção, exatamente o que a casa
  proíbe em teste. Direção: o planner roda cada Check contra o HEAD e registra o vermelho.
  RESOLVED by ac0a6b2 e ee5c550.
  — descoberto por `sdd-executor` na missão `20260816-runner-sem-dividas` (2026-08-16)

- [ ] **O formato de achado vale para os repos-alvo, mas o sensor só guarda o arquivo do kit** —
  `tests/check-todo.sh` (`--allow-empty`) vs `CLAUDE.md` (princípio 5) — o esqueleto de duas seções e o ciclo
  "fechado é apagado" valem para o `TODO.md` de **qualquer** repo. Desde o marcador, o sensor roda
  num alvo (`--check <arquivo> --allow-empty`, e a skill `todo-to-github-issues` o chama antes de
  espelhar), mas nada o põe na suíte do alvo: o inchaço volta sem ninguém medir a cada missão.
  Direção: o `starter.conf` sugerir o `--check` do kit no `TEST_CMD` do alvo. RESOLVED by ef1bc82.
  — descoberto por `humano` revisando o sensor novo (2026-08-16)

- [ ] **O schema da série não tem sensor de drift contra a prosa que o descreve** — `bin/sdd:9829`
  (`kaizen_series`) vs `docs/pipeline.md:1400`, `docs/adr/0003:59`, `agents/sdd-kaizen.md:40` e
  `docs/failure-modes.md:102` — produzido em dois lugares (o `jq` e o literal vazio, `:9350`) e
  descrito em **dez**, QUATRO deles dentro do `bin/sdd`. Cobrado 6×: na DOCS de
  `20260817-eixo-do-juiz`, **oito** dos dez diziam a unidade que o F1 da r3 trocara horas antes
  (sessão → missão) — o ADR que o runner cita, a folha do juiz, e a própria frase que o runner
  IMPRIME. Direção: extrair os campos do `jq` e cobrá-los na doc. RESOLVED by dcfb072.
  — descoberto por `sdd-executor` na missão `20260816-runner-sem-dividas` (2026-08-16)

- [ ] **Piso anti-vacuidade que fica para trás continua PASSANDO, e nada avisa** —
  `tests/check-lang.sh:308` (`n_surface`) — o piso dizia 37 caminhos contra 40 reais: as ADRs 0004–0006 entraram
  pelo glob `docs/adr/*.md` sem tocar o número, e piso menor que a superfície certifica menos do
  que lê. Corrigido para 41 no I4, mas a **classe** segue viva — todo piso que convive com um glob
  (`REVIEW_FLOOR`, `LINT_FLOOR`, os de `check-pipefail.sh`) falha igual, e é a segunda vez que este
  mesmo piso paga. Direção: derivar o piso, ou um sensor que compare piso × superfície real.
  RESOLVED by 76a2a06 e 83d9258.
  — descoberto por `sdd-executor` na missão `20260901-o-revisor-so-acha` (2026-09-01)

- [ ] **`gate_TICKET` não confere no Jira a issue que o chapéu diz que ele confirma** — `bin/sdd:1136`
  (`gate_TICKET`) — o `agents/sdd-ticket.md:18` promete que o runner confirma a issue por `acli`,
  mas o gate só lê `issue:` e `sprint:` do frontmatter do `10-ticket.md`. Uma issue duplicada (LH-5
  no lugar da LH-4) passa verde, e a LH-4 só se defendeu com um Check próprio no I1. Fail-open: o
  chapéu afirma uma medição que ninguém faz. Direção: o gate chama o `acli` (a issue existe e está
  no sprint ativo), ou o chapéu deixa de prometer. RESOLVED by ae81ed3.
  — descoberto por `sdd-planner` na missão `20260927-idioma-da-spa-pelo-idp` (2026-09-27)

- [ ] **Relatório trazido do histórico POSTERIOR da base conta como da missão** —
  `bin/sdd:894` (`path_in_commits`) — a posse exige caminho ausente da árvore do merge-base; um
  relatório que outra missão mergeou em `origin/<base>` DEPOIS do corte, trazido por `git checkout
  origin/<base> -- f`, `merge --squash` ou `cherry-pick`, é novo para o merge-base e conta: a SQ-146
  por outra porta. Checar a ponta da base recusaria o próprio relatório de missão mergeada por
  squash (o fluxo do `sales_quote`). Direção: distinguir pelo blob na ponta, não pelo caminho. RESOLVED by 48e7870.
  — descoberto por `revisor de contexto novo` na missão `20260928-os-achados-da-janela` (2026-09-29)

- [ ] **O `--red` aborta sob `set -u` em bash 4.0–4.3 quando o Check não imprime nada** —
  `tests/check-checkpoint.sh:519` (`red_norm`) — `read -ra w` de uma saída vazia deixa o array vazio, e
  `"${w[*]}"` é "unbound variable" antes do bash 4.4: o caso que o `--red` existe para recusar (o Check
  mudo) vira aborto do sensor. Não reproduz no bash 5.2 daqui; o kit promete bash 4+. Direção:
  `${w[@]+"${w[*]}"}`, o idioma que o `check-todo.sh` já usa.
  — descoberto por `revisor final` na missão `20261004-lote-4-a-catraca-zera` (2026-10-05)

### Contrato e configuração

- [ ] **O `kaizen_reminder` diz a frase de repo-alvo quando roda de um worktree do kit** —
  `bin/sdd:10367` (`kit_id`) — a grafia que a porta do `sdd kaizen` tinha antes do #121:
  compara o `--show-toplevel` de `$SDD_HOME` com o `$REPO_ROOT`, e o toplevel é por worktree. Do
  worktree, o `sdd` do checkout principal imprime "N mission(s) of this repo … The kaizen judge
  counts them" no lugar da frase do kit. Direção: o mesmo `ledger_repo_root` dos dois lados, e
  re-ancorar o `mut_KAIZEN_reminder_wrong_repo`. O `kit_guard_check` usa a grafia e não é defeito. RESOLVED by efb5db1.
  — descoberto por `sdd-planner` na missão `20261003-lote-3-a-catraca-desce` (2026-10-03)

- [ ] **Uma sessão escreve o ledger com o `bin/sdd` que tinha em MEMÓRIA ao ser lançada** —
  `bin/sdd:4520` (`autonomy_session_row`) — a missão que ACRESCENTA um campo é a única que não o registra (3 de 4
  rodadas com `turns` nulo), e o ledger não distingue "medido nulo" de "não medido": fail-open de leitura. O
  `.sdd/config.sh` tem o mesmo defeito (`bin/sdd:147`, `source` único): o `TEST_CMD` consertado a meio do run não vale,
  e o EXEC da SQ-141 queimou 4 retries (~US$ 5,90) num gate insatisfazível. Direção: o `sdd run` avisar quando `bin/sdd`
  ou config mudou sob ele (ou reler o config por gate). RESOLVED by ed252ce e 44de239.
  — descoberto por `sdd-qa` na missão `20260901-o-revisor-so-acha` (2026-09-01); config por `claude` na missão
  `20260924-transacao-honra-o-timeout` (2026-09-24)

- [ ] **`sdd run --phase PR` com só o carimbo faltando grava uma intervenção e não abre sessão** —
  `bin/sdd:8187` (`checkpoint_note_intervention`) — a nota "forced from the CLI" é commitada antes de a
  volta chegar à parada no carimbo (rc 2), e o `sdd autonomy --by-mission` conta uma intervenção numa
  corrida que não fez nada. Mesma forma da porta do PLAN, anterior ao lote. Direção: escrever a nota só
  quando a volta forçada abre sessão, ou declarar o limite nas duas portas.
  — descoberto por `revisor final` na missão `20261004-lote-4-a-catraca-zera` (2026-10-05)

### Saída humana e cosmética

- [ ] **As ADRs 0001–0007 não têm `Spec:`, e por isso 14 missões deste repo não podem declarar
  `adr:`** — `docs/adr/0001-judge-split-deterministic-series-model-verdict.md:1` (`Status`) — nenhuma das sete
  liga-se a uma missão por artefato (`git log --diff-filter=A` de cada uma não toca
  `docs/handoffs/`), então o par das duas direções não fecha e `adr: none` seria rótulo sem
  artefato. É o que segura este repo em `ADR_CHECK=warn`: o `sdd adr check` conta 14 sem decisão, e
  `block` mandaria as 14 de volta para PLAN. Direção: o humano mapeia as sete, `sdd adr new --spec`
  escreve os dois lados, o resto vira `adr: none`, e aí a chave volta para `block`. RESOLVED by 7cb9328.
  — descoberto por `codereview` na missão `20260917-o-numero-do-adr-nao-e-prosa` (2026-09-17)

- [ ] **A parada no carimbo manda rodar o `sdd health` mesmo quando o carimbo é impossível** —
  `bin/sdd:8289` (`GATE_PR_STAMP_WHY`) — numa cópia do kit fora do git, ou com um caminho medido
  ausente, nenhum `sdd health` carimba aquela árvore; o remédio certo só vem dentro do motivo, na linha
  de cima, e as linhas `dim` repetem a ordem genérica. Parar está certo; a prosa engana. Lido do
  código, não reproduzido. Direção: quando o motivo é "impossível", trocar as linhas de remédio.
  — descoberto por `revisor final` na missão `20261004-lote-4-a-catraca-zera` (2026-10-05)

- [ ] **A dica do `sdd status` pergunta "feita à mão?" de toda fase verde de missão rodada noutra máquina** —
  `bin/sdd:6833` (`status_unrecorded`) — o ledger é por máquina, então missão executada noutro
  computador não tem linha `session` aqui e toda fase verde recebe o `sdd note-manual`; quem seguir a
  dica grava como feita à mão uma fase que não foi. A frase diz "this machine's ledger" (declarado no
  plano do I19). Direção: calar quando o ledger local não tem nenhuma linha da missão.
  — descoberto por `revisor final` na missão `20261004-lote-4-a-catraca-zera` (2026-10-05)

- [ ] **O `ok` do `sdd note-manual` diz que gravou a nota mesmo sem `checkpoint.md`** —
  `bin/sdd:11094` (`checkpoint_note_intervention`) — sem o arquivo o escritor volta 0 em silêncio, a
  linha `manual` vai para o ledger e a mensagem final afirma "the note in the checkpoint": rótulo sem
  artefato, na saída humana. Direção: o escritor publicar se escreveu, e o `ok` dizer só o que
  aconteceu.
  — descoberto por `revisor final` na missão `20261004-lote-4-a-catraca-zera` (2026-10-05)

### Comentário e registro

### Idioma

- [ ] **`surface()` do `check-lang.sh` ENUMERA arquivos em vez de casar `docs/*.md`** —
  `tests/check-lang.sh:74` (`surface`) — um doc novo em `docs/` nasce **fora** da régua de idioma enquanto o
  `CLAUDE.md § Idioma` promete `docs/` inteiro; o I4 cobriu `docs/graphify.md` **um arquivo por
  vez**, que é o remendo e não o conserto. Direção: glob, com o piso derivado junto — é decisão,
  porque glob e piso enumerado são a mesma discussão do item do piso acima. RESOLVED by 76a2a06.
  — descoberto por `sdd-planner` na missão `20260901-o-revisor-so-acha` (2026-09-01)

### Custo e escala

- [ ] **O `sdd-publisher` não consegue esperar o `sdd health` dentro de uma sessão headless** —
  `agents/sdd-publisher.md:38` (`sdd health`) — o agente iniciou o health "em background" e encerrou o turno
  "esperando a notificação": em `claude -p` encerrar o turno encerra a sessão, e o health morreu
  com ela (US$ 1,46 por nada); a sessão seguinte rodou em primeiro plano e levou 82 min (US$ 2,73).
  É a classe do *"waiting for the suite"* de `4c86712`, agora na fase PR. Direção: o **runner** roda
  `sdd health` antes de abrir a sessão de PR quando o carimbo está inválido — é comando, não
  julgamento. RESOLVED by bee7a63 e fd05345.
  — descoberto por `humano` na missão `20260829-o-incremento-que-andou` (2026-08-30)

- [ ] **O carimbo da fase PR é medido antes da revisão dos bots, e o primeiro achado de código o descarta** —
  `agents/sdd-publisher.md:71` (`./bin/sdd health`) — o `CLAUDE.md` manda esperar os revisores,
  consertar numa leva e carimbar uma vez; a fase PR carimba logo depois de abrir o PR. Medido no #196:
  health às 18:13, CodeRabbit às 18:27 com um achado em `bin/sdd`, run interrompido com 123 de 542
  mutantes. A direção do item acima (o runner carimbar antes da sessão de PR) agrava isto. Direção, à
  luz do ADR 0004: abrir o PR, esperar a rodada dos bots e só então carimbar. RESOLVED by bee7a63 e fd05345.
  — descoberto pela sessão interativa que monitorava `20261002-onde-o-comando-do-humano-escreve` (2026-10-02)

### Sem seção — chegaram depois da última classificação

> ⚠️ Esta seção **chamava-se "Adiados por YAGNI"** e não guarda mais nenhum adiamento: os três que
> havia (espelho global de vereditos, multi-missão por `git worktree`, `sdd digest`) viraram Y1–Y3
> da tabela **Decisões adiadas por YAGNI** do [`CONTEXT.md`](CONTEXT.md), onde cada um nomeia o
> evento que o reabre — pela régua D15, ausência de consumidor é decisão adiada, não achado. Os
> itens abaixo são achados de verdade que foram apendados ao fim do arquivo e nunca classificados;
> quem mexer num deles o move para a seção a que ele pertence.

- [ ] **Fase executada à mão não tem como ser registrada, e o ledger afirma que ela não aconteceu** —
  `agents/sdd-publisher.md:1` (`sdd-publisher`) — a fase PR da SQ-129 foi montada à mão depois de três mortes por
  memória; não há sessão de publisher no ledger e o custo não entra na soma (US$ 161,29 é o total
  que o journal conhece, e ele para na DOCS). A lacuna virou prosa no `50-pr.md`, que nem o
  `sdd autonomy` nem o `sdd kaizen` leem. Direção: `sdd note-manual <fase>`, irmão do `intervention:`
  — ⚠️ pede o **sexto** `event` do ledger, com dois leitores a ensinar no mesmo commit.
  RESOLVED by 6eca40a, e03ca8b e 82c2986.
  — descoberto por `sessão coordenadora` na missão `20260916-destino-frete-cif` (2026-09-16)

## Decidido — não reabrir
<!-- sdd:decided -->
- **O laço de melhoria da sessão interativa não enxergaria o kit** — resolvido fora do kit, sem commit deste repo: `retrofit-watch` 0.2.0 (`j0ruge/skills@960e47b`) reconhece `/sdd-*`, subagente `sdd-*` e o CLI `sdd` (2026-10-01)
- **O `sdd preflight` não provaria que a sessão headless executa comando** — refutado: `bin/sdd:5168` manda rodar `bash -c 'echo sdd-preflight-ok'` sob as flags do `run_phase` desde `2083680`, e sob o chapéu do executor desde 2026-09-06 (2026-09-25)
- **O `RESOLVED by` não deixa a catraca descer na missão que conserta** — decidido: o item fica até o merge e sai no chore pós-merge, `templates/todo.pt-BR.md` § Ciclo de vida (2026-09-25)
- **O stub do `sdd adr new` manda escrever em `OUTPUT_LANG`, e o `check-lang.sh` lê `docs/adr/` como inglês** — limite declarado pela D15, não achado: `bin/sdd:7030` (2026-09-25)
- **Aviso de merge durante a janela do juiz** — decidido fora: depois do conserto do eixo (I2) só mudança real do kit rompe a janela, e essa é ruptura legítima — `docs/adr/0014`, missão `20261001-a-janela-nao-se-parte` (2026-10-01)
- **A refutação R2 do handoff de QA citaria evidência que não existe** — refutado: o prompt renderizado nomeava o arquivo, porque o boot_prompt expande `$TODO_FILE` para TODO.md; o item conferiu a fonte, não o prompt — `148f693:bin/sdd:1621` (2026-10-03)
- **O sdd status travaria mais de 2 min segurando a trava do checkout** — refutado como defeito sem causa e como fila: sem `--no-gates` o status avalia todo gate sob a trava, TEST_CMD e E2E_CMD incluídos, e a segura enquanto eles rodam, sem prazo; a trava é não-bloqueante, então quem chega depois não enfileira, recebe CHECKOUT-BUSY com o dono; a leitura sem trava é `sdd status --no-gates` — `bin/sdd-coordination.py:504` (2026-10-03)
- **O cmd_kaizen escalaria no-progress como fricção no rubric depois de um retry que moveu** — decidido: o código escala sem olhar o moved2, mas as linhas KAIZEN são `$meta` e ficam fora do eixo do juiz nos dois leitores; o humano lê "two sessions without satisfying the gate", que é verdade — `bin/sdd:9943` (2026-10-03)
- **A Âncora 3 do gate_QA bloquearia a missão com bug aberto de OUTRA missão** — decidido por desenho: a ADR 0009 mantém recusada a alternativa (A) da 0006, porque contar só o bug da missão troca o laço por dívida calada; a saída humana é `deferred` — `docs/adr/0009-the-genre-gains-deferred-and-hats-gain-project-exceptions.md` (2026-10-03)
- **Slug de missão em pt-BR não poderia ser citado na superfície inglesa** — decidido: o selftest do check-lang afirma de propósito que slug em prosa é pego (exit 95); slug se cita numa linha `Spec:`/`ADR:` ou sem stopword — `tests/check-lang.sh:195` (2026-10-03)
- **As skills qa-report e qa-execution não conhecem o campo Closable by** — decidido: o lado do kit fechou (o sdd install semeia o campo, o sdd preflight reprova sem ele, o sdd-qa marca); ensinar a skill de terceiro é retrofit no marketplace, não item do kit — `f7bcf10` (2026-10-03)
- **O rows=13 do gate: da QA de 20260818-lote-facil não sai do extrator** — decidido: o número citado não reproduz (o extrator dá 8, o próprio item o mediu) e a conclusão da J6 segue certa; handoff de fase encerrada não se reescreve — `docs/handoffs/20260818-lote-facil/30-handoff-qa.md:7` (2026-10-03)
- **Nada mediria se o esperado de um Check do checkpoint ainda reproduz** — limite declarado: o cabeçalho do sensor diz que ele não mede o valor ao lado da seta, de propósito; rodar os Checks custaria a suíte por célula — `tests/check-checkpoint.sh:45` (2026-10-03)
- **O kit não tem CHANGELOG.md, e a fase DOCS cobraria um** — decidido: a linha do CHANGELOG na DOCS é condicional (só quando a missão entrega algo visível) e nenhum gate a cobra; o registro do kit é KAIZEN_LOG.md, handoffs, git log e corpo do PR — `agents/sdd-docs.md:49` (2026-10-03)
- **O teto de orçamento não conhece "missão reaberta"** — decidido: a porta humana para gastar mais é `--budget-override` com a nota intervention: que o runner escreve (anatomia §7) — `bin/sdd:5031` (2026-10-03)
- **O gate: do frontmatter da revisão só é cobrado quando existe** — decidido, sem conserto: as 6 rodadas sem o campo (de 30) são de 2026-08-16/17, anteriores a ele, e as 24 seguintes o trazem — `bin/sdd:1773` (2026-10-03)
- **run_phase cria o diretório de log da sessão sem guarda** — decidido, sem conserto: a falha é alta e fechada (rc 1 antes de abrir sessão, zero gasto) e nunca foi observada — `bin/sdd:4670` (2026-10-03)
- **Check de ausência reprovaria o conserto que precisa citar o defeito** — decidido: falha fechada, um caso em 2026-08-16; a regra de redação de Check do planner vem com o achado do Check que nasce verde, na leva 4 — `docs/handoffs/20260816-runner-sem-dividas/checkpoint.md:20` (2026-10-03)
- **A suíte segue acima do alvo "<30 s" da D7** — decidido: o critério (4) da D7 passa a ser o prazo por passo do step_timeout (8× o tempo ocioso, piso 60 s), que já é o orçamento medido e cobrado; o 🚩 do CONTEXT.md fecha — `tests/run-all.sh:168` (2026-10-03)
- **O 2º Python do worker custa ~30 ms em toda chamada coordenada** — decidido: 30 ms por chamada não chega ao humano; provar o worker por FD herdado pede ADR e fica na gaveta, F1 P1 — `docs/superpowers/specs/2026-09-23-a-gaveta-do-kit.md:63` (2026-10-03)
- **35% do docs/pipeline.md seria um subsistema só, e cresceria a cada missão do ledger** — decidido, sem refator: as seções do ledger e do juiz são 525 de 1562 linhas (33,6%), estáveis em 33–34% desde 2026-09-29 depois do pico de 48% em 2026-08-31, e nenhum boot_prompt lê o pipeline.md, então nenhuma fase paga o índice inteiro; reabre se a fatia passar de 40% ou se um boot passar a ler o arquivo — `docs/pipeline.md:1050` (2026-10-04)
- **Test Coverage = A do revisor implicaria que os casos negativos existem** — decidido como limite: a nota de revisão é rótulo que o próprio modelo escreve, e a anatomia §4 o declara; a parte barata e real, o executor sabotar a linha nova de um R<n>, é o I3 de 20261004-lote-4-a-catraca-zera; reabre quando um segundo P1 escapar de um Test Coverage = A numa missão headless — `.claude/rules/anatomia-do-agente.md:94` (2026-10-04)
- **Nenhum instrumento mediria prosa de CONTRATO fora de templates/** — decidido: a fase DOCS é a dona dessa prosa (a checklist de drift do 45-docs.md percorre o diff inteiro da missão), o config/schema.md já é medido contra o load_config pelo sdd health, a tabela de agentes do README bate 8 = 8, e os drifts registrados foram pegos antes do merge; o limite está no cabeçalho do sensor; reabre quando um drift de contrato escapar para a main — `tests/check-templates.sh:39` (2026-10-04)
- **O checkpoint não teria grafia para incremento cujo produto não é commit** — decidido: a grafia é o commit de registro — o ato fora do git (e-mail, página da KB, config no IdP) deixa na pasta da missão um record-<ID>.md com o que foi feito, a URL ou o ID e a data, e o hash dele vai na célula Commit que o gate_EXEC já lê; passo pós-merge ou de janela externa sai da tabela para as Pendências para o humano do 00-missao.md ou para a missão seguinte (o token de espera é o Y8 do CONTEXT.md); os casos medidos (o I5 da LH-3, KB sem commit; o I6 de 20260918-a-excecao-do-chapeu-e-o-genero-diferido, pending eterno; os I1–I3 de 20260825-cif-forma-pagamento no sales_quote, blocked eterno) não são migrados, porque handoff fechado não se reescreve — `templates/checkpoint.md:35` (2026-10-04)
- **Drift de comentário em código não teria dono: nem a DOCS nem a EXEC** — decidido: comentário de código é do código — a REVIEW o manda para um lote R<n> da EXEC, a DOCS marca ⛔ com o texto proposto (o bin/sdd fica fora do writes: dela, e o gate só recusa ⛔ em documento que ela pode escrever), ou ele vai para o TODO_FILE quando o carimbo não compensa; o caminho estreito "a DOCS edita só hunk de comentário" falharia aberto, porque o bin/sdd tem 6 heredocs e # dentro de string, awk e jq; 0 hat-crossed por código em 15 sessões DOCS desde 2026-09-12 — `agents/sdd-docs.md:104` (2026-10-04)
