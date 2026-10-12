---
missao: 20261012-a-rota-da-qa
titulo: a QA que o grill dispensou e o reteste depois de um F<n> passam a ter rota no runner, sem ritual à mão nem skill chamada de improviso
data: 2026-10-12
versao:
branch: kaizen/a-rota-da-qa
aprovacao:
adr: none
ddd: n/a
---

# Missão — a rota da QA

> Nascida do laço `sdd kaizen` (sessão `sdd-kaizen`, 2026-10-12), **sem humano na sala**. O veredito
> que a originou está ao lado, em `05-verdict.md` (`melhorou` sobre `0270727`). `aprovacao:` fica
> vazio por regra: o laço não aprova o próprio plano (`plan_approves_itself`, `bin/sdd:1146`). O
> plano carrega **duas decisões de desenho** que são do humano — por isso o I1 é alocar a ADR.

## Problema (Gemba)

Duas lacunas no mesmo ponto do runner, o `qa_substep` (`bin/sdd:2672`), medidas na janela do lote 6
(cinco missões do `sales_quote` sobre `0270727`).

**1. O `skipped` que o grill decidiu não tem caminho headless.** Com `APP_URL` ou `E2E_CMD`
preenchidos, o `qa_substep` devolve `plan` sem charter (`bin/sdd:2679`) e `exec` sem relatório da
missão fechado (`bin/sdd:2681`); só depois devolve `close`, a única sub-etapa cujo chapéu
(`sdd-qa`) escreve `status: skipped`. O `agents/sdd-qa.md` § 2 promete que `skipped` é resposta
legítima para diff que não chega ao usuário, e no caminho com interface nenhuma sessão alcança a
promessa sem antes pagar `/qa-report` ou `/qa-execution` (navegador e stack). Medido: **3 das 5
missões** da janela tiveram a QA decidida como `skipped` no grill e gravada à mão
(`sdd note-manual`, linhas `manual` de 2026-10-11 09:19, 2026-10-11 15:22 e 2026-10-12 17:03). O
`pipeline.log` das três mostra o mesmo ritual — `sdd run` até o TICKET, `30-handoff-qa.md` escrito à
mão, `note-manual`, segundo `sdd run` —, e o segundo lançamento é **a** intervenção de cada uma:
**3 das 5** intervenções da fatia (`sdd autonomy --all-repos --by-mission`).

**2. Depois de um `F<n>` feito, nada reanda a jornada.** O relatório da missão já está `closed`, o
`qa_substep` vai direto ao `close`, e nenhuma sessão dona do `Status:` do bug volta a rodar — a
Âncora 3 do `gate_QA` (`bin/sdd:1733`) segue contando o bug consertado. A saída usada no alvo foi a
sessão `sdd-qa` chamar a skill `qa-execution` pela ferramenta `Skill`, que nenhum contrato descreve:
r2, r3 e r4 da `20261005-mascaras-ncm-e-painel` (na r3 foi esse reteste que achou o F5) e de novo
na `20261009-o-que-some-calado`. Funciona hoje só porque as duas skills instaladas declaram
`disable-model-invocation: false` — o comentário do runner diz o contrário (`bin/sdd:2651-2654`,
`bin/sdd:2915-2917`). Se a skill voltar a recusar, toda missão com `F` gira o `QA:close` até o
`QA_MAX_ITER`: o gate insatisfazível do princípio 1, escondido atrás de uma improvisação.

Os achados `kit:` de origem estão nos handoffs do alvo: `20261010-o-backlog-volta-a-medir`
(`20-handoff-exec.md`, § achados fora de escopo), `20261005-mascaras-ncm-e-painel` e
`20261009-o-que-some-calado` (`30-handoff-qa.md`, idem).

## Métrica

- **M1 (binário, fixture):** projeto com interface, charter presente, nenhum relatório da missão e
  `qa: skipped` no `00-missao.md` → `sdd run --dry-run --phase QA` projeta `QA:close=sdd-qa`. Hoje
  projeta `QA:exec=<none>`.
- **M2 (binário, fixture):** relatório da missão `closed` e um `F<n>` `done` cujo commit vem depois
  do último commit que tocou esse relatório → projeta `QA:exec=<none>`. Hoje projeta `QA:close=sdd-qa`.
- **M3 (binário):** `agents/sdd-qa.md` descreve o reteste pela rota do runner e o idioma do spec de
  bug `human`/`deferred`; os dois templates do `TODO.md` dizem onde vai o `RESOLVED by` no teto.
- **M4 (uso real, depois do merge — é o Check da próxima janela, não desta missão):** missão com
  `qa: skipped` decidido no grill roda com **1** lançamento e **nenhuma** linha `manual` de QA no
  ledger; missão com `F<n>` fecha a QA sem a sessão `sdd-qa` chamar a ferramenta `Skill`.

## Resultado esperado

O humano decide no grill que a QA não se aplica, escreve `qa: skipped` no plano, e o `sdd run` vai
do TICKET ao PR num lançamento só: a sessão `sdd-qa` confere o diff real contra a justificativa do
plano e escreve o `skipped`, ou para a linha com `blocked` se o diff alcançou o usuário. Depois de um
`F<n>` feito, o runner devolve a QA à `qa-execution`, que reanda e move o `Status:` do bug — a rota
que hoje só existe porque uma sessão improvisou. O comentário do runner sobre as skills volta a
dizer a verdade, e a ADR registra as alternativas recusadas.

## Fora de escopo

- O histórico de quedas do caso e2e no `GATE_WHY` (achado `kit:` da `mascaras-ncm-e-painel`) e a
  âncora de caminho longo que não cabe no `WIDTH_CAP` (achado `kit:` da `o-backlog-volta-a-medir`):
  transportados para o `TODO.md` neste mesmo commit, catraca 0 → 2.
- A fila (a)–(k) de achados do `commands/sdd-plan.md` que o humano guarda em
  `~/.claude/plans/` (handoffs da campanha do `sales_quote`): fora do repo, não verificada por esta
  sessão. Vai para as pendências — plano de kit mora no repo.
- Baixar o modelo da sub-etapa `QA:close` para o `skipped`: sem número de custo ainda (risco no plano).

## Gate PLAN-AUTO

Preenchido pelo `sdd-kaizen` **com evidência**. Sem humano na sala, `aprovacao` fica vazio de
qualquer forma.

| # | Critério | Status | Evidência |
|---|---|---|---|
| a | Grill sem perguntas abertas não endereçadas (🚩 vazia ou itens deferidos com dono) | ✗ | Não houve grill — sessão headless do laço kaizen. As duas decisões de desenho estão em "Decisões do grill", com recomendação e alternativas, e o dono é o humano no I1 |
| b | Checklist kaizen 100% ✅ e checklist DDD 100% ✅ ou `n/a` justificado | ✅ | seções abaixo; DDD `n/a` |
| c | Plano passa no teste de autocontenção (sessão nova só com 00/01/checkpoint executa) | ✗ | Não testado com sessão fria; o `01-plano.md` traz `arquivo:linha` de cada ponto tocado e o desenho das duas condições, mas o I1 depende da decisão humana |
| d | Todo incremento do `checkpoint.md` tem Check executável (comando → esperado), vermelho no HEAD pelo `tests/check-checkpoint.sh --red` do kit | ✅ | 7 de 7; `--check` e `--red` rodados nesta sessão sobre o checkpoint (saídas no `01-plano.md` § Contexto verificado) |
| e | `versao:` confirmada pelo humano (ou `JIRA_ENABLED=false`) | ✅ | `JIRA_ENABLED=false` (`.sdd/config.sh`) |
| f | `adr:` é uma decisão — um caminho, ou o literal `none` (alocado por `sdd adr new`) | ✅ | `none` por regra do laço kaizen: alocar ADR é decisão de trade-off, que esta sessão não toma. A mudança **tem** trade-off, e o I1 aloca a ADR com o humano; o `sdd adr new --spec` reescreve este campo |

## Checklist kaizen (`kaizen-software`)

| # | Item | Status | Nota |
|---|---|---|---|
| K1 | Gemba — fui ver onde o trabalho acontece | ✅ | `qa_substep`, `gate_QA` e `report_closed` lidos no código; ledger (`manual`, escaladas), `pipeline.log` e handoffs das cinco missões do alvo lidos; frontmatter das skills instaladas conferido |
| K2 | Problema declarado com métrica | ✅ | 3 de 5 missões com QA à mão; 3 de 5 intervenções; M1–M4 |
| K3 | Desperdícios identificados e cortados | ✅ | o ritual de dois lançamentos por missão sem QA; a sessão de caminhada paga para chegar ao `skipped`; a improvisação de skill que pode girar o `QA_MAX_ITER` |
| K4 | Fatiamento incremental, cada fatia verificável | ✅ | ADR, rota do `skipped`, contrato da chave, rota do reteste, idioma do spec, template do `TODO.md`, fecho |
| K5 | Check por artefato (rótulo ≠ artefato) | ✅ | Checks ancorados em `^  ok    ` do `check-dry-run.sh` e do `check-templates.sh`, e em greps dos arquivos de contrato |
| K6 | Jidoka — o que para a linha está definido | ✅ | `skipped` declarado com diff que alcança o usuário → `status: blocked` (escalada `handoff-blocked`); reteste que não produz relatório novo → `no-work` forma (a) |
| K7 | SDCA — a melhoria vira padrão (doc/rule/teste) | ✅ | asserções no `check-dry-run.sh`, mutantes no catálogo, ADR, `docs/pipeline.md`, `CONTEXT.md` |
| K8 | Registro no KAIZEN_LOG | ✅ | o I7 escreve a entrada; o antes é o veredito desta pasta |

## Checklist DDD (`ddd`) — condicional

`n/a — sem toque de domínio: muda o roteamento de uma fase do runner e o contrato de três artefatos; nenhum modelo de domínio.`

## Decisões do grill (não re-litigar)

> Não houve grill. As decisões abaixo são **recomendações** desta sessão, com a alternativa que o
> humano pode escolher no I1; o que ele escolher vira a ADR e manda nos incrementos seguintes.

1. **Quem decide o `skipped` no caminho com interface.** Recomendado: o plano aprovado declara
   `qa: skipped` no frontmatter do `00-missao.md` (escrito com o humano no grill), o `qa_substep`
   devolve `close`, e o `sdd-qa` **confere** o diff real contra a justificativa antes de escrever
   `skipped` — o gate continua lendo o artefato que uma sessão escreveu depois do EXEC. Alternativas:
   (b) o `gate_QA` passa direto sobre o plano, sem sessão nenhuma (mais barato; ninguém confere o
   diff, e o `30-handoff-qa.md` que DOCS/PR leem não existe); (c) manter o ritual e documentá-lo
   (custa a intervenção medida).
2. **A rota do reteste.** Recomendado: o runner devolve `exec` quando um `F<n>` `done` vem depois do
   último commit do relatório da missão — a `qa-execution` entra pelo slash, como em toda caminhada,
   e o `sdd-qa` continua sem tocar o `Status:`. Alternativa: autorizar no `sdd-qa.md` § 4 a chamada
   da skill pela ferramenta `Skill` (uma sessão a menos, medido como funcionando cinco vezes; depende
   de `disable-model-invocation: false` e põe dois system prompts numa sessão, o que o comentário do
   `phase_hat` recusa).
3. **O valor da chave é literal e positivo:** só `qa: skipped` desvia a rota; ausente, vazio ou
   qualquer outra grafia é a rota de hoje. Frouxidão aqui pularia QA de verdade — falha aberta.

## Pendências para o humano

- **I1 é seu:** escolher entre as alternativas acima e escrever a ADR que o `sdd adr new` alocar.
- **Carimbo de mutação:** `./bin/sdd health` depois do último commit de código **e** da rodada dos
  bots do PR (ADR 0015 §1; o carimbo não é headless).
- **`sdd install --force`** depois do merge, para o espelho de `.claude/agents/` dos alvos ler o
  `sdd-qa.md` novo.
- **A fila (a)–(k)** do `commands/sdd-plan.md` vive só em `~/.claude/plans/2026-10-11-…pos-l2.md` e
  `2026-10-12-…pos-l4.md`. Pelo `CLAUDE.md` do kit, plano de kit mora no repo: transportá-la para o
  `TODO.md` (com a régua D15) antes da próxima triagem, ou ela não entra em nenhuma.
- **Descongelar o kit** depois do merge desta branch: o veredito ao lado fecha a janela do lote 6.
