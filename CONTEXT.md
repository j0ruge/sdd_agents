# CONTEXT — glossário e decisões do `sdd_agents`

> Mantido pelo grill-with-docs. Termos do domínio do kit e decisões resolvidas em entrevista,
> com as perguntas ainda abertas sinalizadas. Sessão inicial: **2026-08-15, planejamento do
> I13.3 (`sdd-kaizen`)**.

## Glossário

| Termo | Definição |
|---|---|
| **Ledger de autonomia** | `~/.sdd/autonomy-log.jsonl` (global, fora dos repos). Uma linha JSON por sessão gasta ou escalada, escrita pelo runner. Grava **fato, nunca rótulo**. Interface completa em `docs/pipeline.md` § "The autonomy ledger". |
| **Rótulo** | `ok \| leve \| refez` por fase/sessão, derivado **depois** a partir dos fatos do ledger — nunca gravado pelo runner. Vem da rubrica de maturidade do usuário (`~/.claude/skills/release-notes/references/autonomy-rubric.md`). |
| **Veredito** | A resposta "a última mudança do kit **melhorou, piorou ou indeterminado**?", dada por mudança de versão do kit (eixo `kit_sha`). |
| **Série** | Os agregados comparados por grupo de `kit_sha`: desperdício (`moved:false`/total), escaladas por `kind`, custo, retentativas. `sdd autonomy` já imprime a visão humana disso. |
| **Escalada** | Guarda-chuva: qualquer linha do ledger que **não gastou sessão**. Duas hoje — `event:"blocked"` (a linha parou, o runner devolve rc 3) e `event:"degraded"` (o runner baixou a própria régua e **seguiu**). Predicado único por programa (`is_escalation`): escrever o par à mão em três pontos foi como eles divergiram. |
| **Degradação (`review-to-draft`)** | O único `degraded` de hoje: `PUBLISH_ON_REVIEW_BLOCKED=draft` + review sem rodadas ⇒ PR em draft em vez de parada. **No máximo uma linha por `run_id`** — o ramo é reentrado a cada volta do laço REVIEW→PR→REVIEW, mas a régua baixou uma vez. Logo, `review-to-draft: 3` são três runs, nunca um run que degradou três vezes. |
| **Juiz** | O papel que produz rótulos + veredito. Pela **D1**, é dividido: a parte mecânica é sensor do runner; a interpretação final é do agente. |
| **Triagem kaizen** | Escolher do `TODO.md` do kit o próximo lote de trabalho que vira missão — sem desviar escopo, sem perder achado. ⚠️ Caixa desmarcada com "RESOLVIDO por `<hash>`" no corpo já está fechada; se o hash já alcançou `main`, o item entra na lista de **resolvidos a apagar** do plano nascido (fechado é apagado, nunca arquivado). |
| **Guarda das 3 missões** | O juiz responde `indeterminado` quando há menos de 3 missões observadas depois da mudança julgada (decisão do design de 2026-08-14). |
| **Marco 1 / Marco 2** | M1: kit executa, humano planeja e faz merge. M2: kit **planeja** e executa; humano aprova o plano e faz merge. O I13.3 é a peça que falta para o M2. |
| **`KAIZEN_AUTO_APPROVE`** | Chave futura (I13.4): plano kaizen nasce aprovado quando a rubrica recomendar graduação. **Fora de escopo no I13.3.** |

## Decisões resolvidas

| # | Decisão | Escolha | Por quê | ADR |
|---|---|---|---|---|
| D1 | Juiz: sensor, percepção ou híbrido? | **Híbrido (C)** — o runner deriva rótulos e série determinística (com mutação na suíte); o agente `sdd-kaizen` dá o veredito final por cima dos números e escreve o artefato interpretando. A régua do agente **evolui pelo uso**. | Números auditáveis onde dá para medir; interpretação onde ela agrega. A fronteira precisa ficar cirúrgica para o agente não virar dono dos números. | [0001](docs/adr/0001-judge-split-deterministic-series-model-verdict.md) |
| D2 | `sdd kaizen`: headless ou interativo? | **Headless com Jidoka (C)** — sessão via `run_phase()`, plano nasce com `aprovacao:` vazio sob o mesmo contrato do `sdd-planner` (PLAN-AUTO com evidência); veredito "piorou" **para a linha** e escala para o humano em vez de planejar por cima. O plano interativo de início de task (`sdd-planner`) continua existindo, intocado — o kaizen é o meta-laço. | É o Marco 2: o humano sai da sala e passa a revisar o plano pronto + merge. O Jidoka impede empilhar mudança sobre mudança ruim (drift). | [0002](docs/adr/0002-kaizen-plans-headless-bad-verdict-stops-the-line.md) |
| D3 | Onde mora o veredito? | **Artefato da missão nascida (A)** — arquivo próprio no `docs/handoffs/<missão>/` criado pelo kaizen (template próprio; rótulos citando a série do runner + veredito + porquê). O `gate_KAIZEN` grepa ali. Veredito "piorou" não gera plano: o diretório nasce só com veredito + escalação — artefato honesto do Jidoka. Espelho global legível por máquina (JSONL em `~/.sdd/`) fica **adiado até o I13.4 pedir** (YAGNI). | Viaja no PR: o revisor humano vê o julgamento junto do plano que ele motivou — PDCA físico (Check da mudança N = contexto da missão N+1). | — |
| D4 | O que é "a mudança anterior" (eixo do juiz)? | **`kit_sha` cru (A)** — o runner agrupa por `kit_sha` na ordem do arquivo (como `cmd_autonomy` já faz), exclui `kit_dirty`, compara o grupo mais novo contra o anterior; guarda das 3 = missões distintas no grupo mais novo. O agente interpreta por cima ("dois SHAs = uma mudança lógica") usando o `git log` do checkout. | Zero resolução git no runner; a nuance fica no lado que a D1 reservou para nuance. Guarda conservadora demais erra para o lado seguro (`indeterminado` a mais atrasa, nunca empilha mudança ruim); se atrasar demais, a régua muda com commit — o mecanismo que a D1 previu. | — |
| D5 | `indeterminado` para a linha? | **Não (A)** — hierarquia: `melhorou`/`indeterminado` → registra o veredito e segue para triagem + plano; só `piorou` → Jidoka. | O gate humano (`aprovacao:` vazio + merge) já é o freio real; o Jidoka é para sinal vermelho, não para ausência de sinal. `indeterminado` é o estado normal do começo da série. | — |
| D6 | Gatilho do `sdd kaizen`? | **Manual + lembrete (B)** — o disparo é sempre humano (pull, não push: enquanto a aprovação é humana, disparo automático só move o custo para mais cedo sem mover o laço). `sdd close` imprime uma linha calculada da série ("N missões desde a última mudança julgada") — texto, zero sessão. Disparo automático volta à mesa no I13.4. | O humano é o kanban. O modo de morte do laço manual (desuso) já está catalogado no TODO.md; a mitigação custa ~5 linhas sem sessão paga. | — |
| D8 | Forma de implementação? | **KAIZEN como fase de verdade (1)** — entra nas tabelas `phase_*` (`MODEL_KAIZEN`, agente `sdd-kaizen`); `cmd_kaizen` = guarda kit-repo → série → `run_phase KAIZEN` → `gate_KAIZEN`. A parte determinística vira `sdd kaizen --series` (JSON), que a sessão do agente roda como fonte da verdade — a fronteira do ADR 0001 vira mecânica. Pseudo-missão `<data>-kaizen` para logs; o agente cria o diretório real da missão nascida. ⚠️ Gemba: o lembrete da D6 vai no ramo "pipeline complete" do `cmd_run` (`bin/sdd:1427`), não só no `close` — `cmd_close` retorna cedo com `JIRA_ENABLED=false`, o caso do kit. | Respeita a regra do `run_phase()` do CLAUDE.md; logs/teto/ledger de graça; `--series` testável puro na suíte. Alternativa "duas sessões" fica como evolução se a sessão única estourar teto. | — |
| D7 | Métrica de sucesso do I13.3? | **Sensores sintéticos + rodada real como Check de fecho (C)** — (1) rodada real produz veredito + plano nascido passando `gate_KAIZEN`; (2) mutação 20 → ≥23 (gate_KAIZEN, Jidoka "piorou", derivação de rótulo), score 100%; (3) `sdd health` cobrando as novas; (4) suíte < 30s no default. | Padrão consagrado no repo (preflight `fc2fa50`, dry-run): sensor durável na suíte + prova no caminho real. A sessão paga do fecho é a primeira volta produtiva do laço — dela saem o veredito real do I13.1 e o plano candidato da missão seguinte. | — |
| D9 | `docs/adr/` entra na `surface()` do `check-lang`? | **Sim, no I13.3.5** — glob `docs/adr/*.md` na lista enumerada; piso recontado 26 → 31 (sensor novo + 2 cópias do agente + 2 ADRs), com o histórico no comentário do piso. | ADR é superfície do kit (inglês), não artefato de missão; deixar fora abriria a porta que a catraca existe para fechar. | — |
| D10 | A sessão kaizen ganha linha no ledger? Com qual `mission`? | **Sim, uma linha por sessão**, com a pseudo-missão `<YYYYMMDD>-kaizen` (`cmd_kaizen` a seta só para logs/prompt; o diretório nunca é criado pelo runner). A série exclui `phase == "KAIZEN"` dos grupos e a conta em `excluded.meta` — asserção própria no `check-kaizen.sh`. | O custo/fricção do próprio laço fica medido sem deslocar o eixo que ele julga: o juiz nunca vê a própria sessão inflar a guarda do próprio veredito. | — |
| D11 | Degradação: `event` novo ou reusar `blocked` com um `kind` novo? | **`event: "degraded"` próprio** (`kind: "review-to-draft"`), com `blocked` reservado para o run que de fato **para** (rc 3). Os dois compartilham um `is_escalation` por programa, então respondem igual à rubrica de rótulo e ao eixo de `kit_sha` sem serem o mesmo evento. | Reusar `blocked` era mais barato — herdava eixo e agregação sem tocar em `jq` nenhum —, mas gravaria "parou" para um run que **continuou**, e o ledger existe para gravar fato. A revisão r1 fortaleceu o argumento em vez de enfraquecê-lo: a rubrica agrupa por `(mission, phase)` sobre a fatia inteira de `kit_sha`, então ensinar os dois eventos ao mesmo predicado era obrigatório de qualquer jeito. ⚠️ Confirmação humana pendente (🚩 abaixo). | — |

## 🚩 Perguntas abertas

- **D11 espera confirmação humana.** O código já foi escrito com `event: "degraded"`; a alternativa
  barata continua a um valor de campo e às asserções correspondentes de distância.
- **O critério (4) da D7 — "suíte < 30 s no default" — segue não atingido e piorando de
  propósito.** Medido na fase DOCS da missão `20260815-ledger-sem-ponto-cego`, mesma máquina e
  mesma sessão: **47,9 s** com 25 mutantes (`fdf8708`) → **66,3 s** com 30 (`HEAD`). Cortar mutação
  para ganhar tempo violaria o princípio que motivou o I13.2, então as saídas são subir o alvo,
  subir `SDD_MUTATION_JOBS` (⚠️ `nproc` é GNU-only) ou aceitar o custo. Decisão do humano; a
  medição completa e o histórico moram no `TODO.md`.

_As duas perguntas abertas no grill (D9, D10) foram resolvidas na execução do I13.3 e movidas para
a tabela acima._
