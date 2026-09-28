---
missao: 20260928-os-achados-da-janela
titulo: A QA julga o relatório da própria missão, o close deixa a base em dia, o Python recusado diz por quê, e os achados da janela ganham dono
data: 2026-09-28
versao:
branch: kaizen/os-achados-da-janela
aprovacao:
adr: none
ddd: n/a
---

# Missão — os achados da janela do juiz

> Nascida do `sdd kaizen` de 2026-09-28, junto do veredito `melhorou` sobre `4fd0f31`
> (`05-verdict.md` nesta pasta). Escrita **sem humano na sala**: `aprovacao:` fica vazio de
> propósito, e o humano decide com o grill de sempre antes do `sdd approve`.

## Problema (Gemba)

A janela do juiz (3 missões sobre `4fd0f31`, `lighthouse_project` + 2× `sales_quote`) deixou oito
achados `kit:` medidos, listados no handoff humano `~/.claude/plans/2026-09-28-handoff-achados-do-kit.md`
e transcritos aqui porque aquele arquivo não está no repo:

1. a célula Commit do checkpoint não diz o que vai num incremento cujo produto não é commit;
2. `gate_TICKET` só lê o frontmatter do `10-ticket.md`, embora `agents/sdd-ticket.md` diga que o
   runner confirma a issue;
3. o preflight aceita app de **outro produto** na `APP_URL` (`sales_quote` na `:5173` do `lighthouse`);
4. o `qa_substep` escolhe `close` e a Âncora 1 do `gate_QA` aprova com o relatório de **outra
   missão** — repetiu em duas das três missões;
5. a Âncora 3 conta bug legado de outra missão, e a QA fica sem saída honesta (foi a escalada
   `handoff-blocked` da fatia);
6. a DOCS contorna pelo Bash a negativa do harness em `.claude/rules/` (duas de duas missões do
   `sales_quote`);
7. o `sdd close` volta à `DEFAULT_BRANCH` sem fast-forward, e a missão seguinte nasce sobre base velha;
8. o `CHECKOUT-UNAVAILABLE` lista todos os requisitos e não diz qual falhou: um CPython 3.11 sem
   `os.pidfd_open` primeiro no `PATH` do humano parou todo comando coordenado.

Verificado nesta sessão:

- O achado 4 **já é item aberto** do `TODO.md` (`gate_QA aceita relatório de QA de OUTRA missão`,
  âncora `bin/sdd:1155`, de 2026-08-27). Duas recorrências novas o confirmam como fail-open:
  `qa_substep` (`bin/sdd:1873`) e `gate_QA` (`bin/sdd:1160`) escolhem o relatório por
  `latest_matching "$qa/reports/*.md"` e nada o amarra à missão.
- O achado 7: `close_return_home` (`bin/sdd`, logo acima de `cmd_close`) faz só
  `git checkout "$DEFAULT_BRANCH"` e anuncia `back on '<branch>'`. `grep -n "merged and spent\|staying on\|could not return" tests/*.sh`
  responde **vazio**: a função não tem probe nenhum hoje.
- O achado 8: `bin/sdd-coordination.py`, no `except` do `__main__`, imprime a lista inteira
  (`Linux >=5.3 procfs/pidfd …, Python 3.9+ …`) e cola o erro cru; `pidfd_capability()` chama
  `os.pidfd_open` sem dizer que a ausência dele é o requisito que caiu. O `die` do `bin/sdd`
  (`CHECKOUT-UNAVAILABLE: coordinated commands require Python 3 and Linux procfs`) idem.
- `TODO.md` tem 83 achados abertos (`bash tests/check-todo.sh --count TODO.md` → `83`) e **nenhum**
  `RESOLVED by` na seção aberta.

## Métrica

- Um fixture em que o relatório `closed` mais recente de `docs/qa/reports/` pertence a outra
  missão faz `qa_substep` responder **diferente de `close`** e `gate_QA` **reprovar** com motivo que
  nomeia a missão; hoje responde `close` e aprova.
- Um fixture de `sdd close` com a `DEFAULT_BRANCH` local atrás da remota termina com a local
  **igual** à remota; hoje fica atrás.
- Um Python sem `os.pidfd_open` faz a mensagem de `CHECKOUT-UNAVAILABLE` conter o **interpretador**
  (`sys.executable`) e o requisito que caiu; hoje não contém.
- `bash tests/check-todo.sh --count TODO.md` → `88` e `tests/health-baseline.txt` com
  `todo-findings 88`, os cinco achados não consertados registrados com dono.

## Resultado esperado

A QA de uma missão só fecha com a QA **dela**: o fail-open aberto desde 2026-08-27, que repetiu em
duas das três missões da janela, deixa de comprar um verde com o relatório do vizinho. O `sdd close`
entrega a base em dia, e a missão seguinte não nasce sobre um `develop` velho. Quem cai no
`CHECKOUT-UNAVAILABLE` lê qual Python foi recusado e por quê. E os cinco achados que esta missão
não conserta passam a morar no `TODO.md`, com âncora e dono, em vez de num plano fora do repo.

## Fora de escopo

- Achados 1, 2, 3, 5 e 6 — registrados no `TODO.md` pelo I1, não consertados. O 6 (regra única do
  `sdd-docs` diante da negativa do harness) pede decisão de desenho sobre permissão; o 3 pede
  escolher o marcador de produto; o 5 depende de o registry de bugs saber a missão de origem.
- Sondar candidatos a Python (`/usr/bin/python3`) antes de desistir: muda **qual** interpretador
  decide a posse, e isso é decisão humana, não diagnóstico. Fica como direção no item do I3 se o
  humano não a trouxer para dentro no grill.
- Tirar o `DISABLE_AUTOUPDATER` do `~/.claude/settings.json` e espelhar o `TODO.md` em issues — passos
  humanos, depois do merge.

## Gate PLAN-AUTO

| # | Critério | Status | Evidência |
|---|---|---|---|
| a | Grill sem perguntas abertas não endereçadas | ✗ | Não houve grill: plano nascido do `sdd kaizen`, sem humano. Duas perguntas em "Pendências". |
| b | Checklist kaizen 100% ✅ e DDD `n/a` justificado | ✅ | seções abaixo |
| c | Plano passa no teste de autocontenção | ✅ | `01-plano.md` carrega as âncoras verificadas nesta sessão e o texto dos 5 achados a registrar |
| d | Todo incremento tem Check executável | ✅ | 5 de 5 no `checkpoint.md` |
| e | `versao:` confirmada (ou `JIRA_ENABLED=false`) | ✅ | `JIRA_ENABLED=false` no kit; `versao:` vazio |
| f | `adr:` é uma decisão | ✅ | `none`: o amarrar do relatório à missão aperta um gate existente sem trocar contrato entre fases; se o grill escolher o critério por data em vez de por branch, reavaliar |

## Checklist kaizen (`kaizen-software`)

| # | Item | Status | Nota |
|---|---|---|---|
| K1 | Gemba — fui ver onde o trabalho acontece | ✅ | série, ledger e `bin/sdd` lidos nesta sessão; âncoras acima |
| K2 | Problema declarado com métrica | ✅ | quatro fatos binários na Métrica |
| K3 | Desperdícios identificados e cortados | ✅ | QA que pula as skills com relatório alheio; base velha depois do close; humano diagnosticando Python à mão |
| K4 | Fatiamento incremental, cada fatia verificável | ✅ | 5 incrementos independentes, um defeito cada |
| K5 | Check por artefato | ✅ | Checks leem a saída ancorada dos sensores |
| K6 | Jidoka — o que para a linha está definido | ✅ | sensor vermelho para; `sdd health` carimba antes do PR |
| K7 | SDCA — a melhoria vira padrão | ✅ | probes em `check-gates.sh`, `check-autonomy.sh`, `check-coordination.sh`; mutantes no catálogo |
| K8 | Registro no KAIZEN_LOG | ✅ | I5 |

## Checklist DDD (`ddd`) — condicional

`n/a — sem toque de domínio: runner bash, sensores e backlog do kit; nenhum aggregate ou contexto.`

## Decisões do grill (não re-litigar)

1. Os achados 7 e 8 **não** entram no `TODO.md`: esta missão os conserta, e o registro deles é este
   handoff. Entram os cinco que ela não conserta.
2. O achado 4 não ganha item novo: o item aberto de 2026-08-27 recebe a recorrência e o
   `RESOLVED by` quando o I4 fechar.

## Pendências para o humano

1. **Critério de pertença do relatório de QA (I4).** O plano propõe: o relatório pertence à missão
   se foi **adicionado ou modificado** em `git merge-base "$DEFAULT_BRANCH" HEAD..HEAD` ou está sujo
   na árvore. Alternativa: prefixo de data ≥ `data:` do `00-missao.md` — mais simples, falha aberto
   em duas missões no mesmo dia. Confirme ou troque no grill.
2. **Aprovar** (`sdd approve`) e decidir se o I3 também **sonda** `/usr/bin/python3`.
