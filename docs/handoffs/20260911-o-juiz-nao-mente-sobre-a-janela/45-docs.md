---
missao: 20260911-o-juiz-nao-mente-sobre-a-janela
fase: DOCS
status: done
sessao: 3e65f25e-97e1-4659-88ec-9f1e1e2e661f
data: 2026-09-12 22:50
gate: `bash tests/run-all.sh` → verde, 1061 asserções; checklist de drift abaixo sem `✗`, toda linha com hash ou `n/a` justificado
---

# Documentação — o juiz não mente sobre a janela

## TL;DR

A documentação viva já vinha sendo atualizada **dentro** dos incrementos (é o padrão certo, e é por
isso que sete das doze áreas do diff fecham com hash de EXEC). Esta fase fechou o que sobrou: os
**quatro achados de prosa** que a REVIEW endereçou explicitamente à DOCS (r2 #6 e #7, r3 #6 e #7) e
**dois drifts que o próprio diff criou e ninguém tinha registrado** — o `CONTEXT.md` ainda dizia que
o ledger real carrega linhas de fixture (o I1 as apagou) e o `README.md` não roteava nem a linha de
ledger do `sdd close` nem a guarda que recusa a fatia. Tudo num commit, `599ee0a`. Como ele toca
`bin/sdd` (dois comentários), o **carimbo de mutação foi refeito depois dele** — é a ordem que o
`gate_PR` exige.

## Drift checklist

| Área tocada pelo diff | Documento correspondente | Status | Evidência |
|---|---|---|---|
| `bin/sdd` — `autonomy_close_row`, quarta forma de linha `event:"close"` (I4) | `docs/pipeline.md` (§ ledger: formas de linha + tabela de schema), `CONTEXT.md` (verbete *Fechamento de ticket gravado*), `README.md` (linha do `sdd close`) | ✅ | `aa3c0a2` (pipeline + CONTEXT, no mesmo commit do código) e `599ee0a` (schema nomeia `cost_usd`/`dur_s`/`turns`/`cache_read`/`harness` na linha de `close` — r2 #7; README passa a rotear) |
| `bin/sdd` — `AUTONOMY_INVOCATION="close"` e o campo `invocation` | `docs/pipeline.md`, linha `invocation` da tabela de schema | ✅ | `599ee0a` — enum vira `run \| retry \| close` e ganha o **limite declarado** do r3 #7: três valores para quatro escritores (`cmd_kaizen` carimba `run`); quem separa o juiz é `phase == "KAIZEN"` |
| `bin/sdd` — `is_close` e `$closes` no `cmd_autonomy`; `$meta` no mesmo somatório (R1, R2) | comentário de `cmd_autonomy`, `docs/pipeline.md`, `docs/failure-modes.md` | ✅ | `599ee0a` — as **três** âncoras da mesma frase podre (r2 #6 + r3 #6) passam de "cinco"/"seis" para **sete** termos, e as três mandam contar pelos bindings `as $…` do código, nunca pela frase |
| `bin/sdd` — `autonomy_blocked_row "retry-gate-red"` no `cmd_retry` | `docs/pipeline.md`, enum `kind` da tabela de schema | ✅ | `aa3c0a2` — `retry-gate-red` está no enum publicado |
| `bin/sdd` — `reopened`/laço de revisão sobre toda sessão local; `gate_pass` lido como passe (I3) | `docs/pipeline.md` (§ `--by-mission`, parágrafo de contabilidade) | ✅ | `392f526` |
| `bin/sdd` — `kaizen_series`: `guard.why`, `guard.harness`, `harness_mixed`, `window_broken`, `window_missions_stranded` (I5) | `docs/pipeline.md` (§ série), `CONTEXT.md` (verbetes *Série* e *Janela de medição*), `agents/sdd-kaizen.md` + espelho | ✅ | `5e3c427` (docs + CONTEXT) e `477cb9a` (o chapéu do juiz aprende a **ler** as chaves novas; espelho por `sdd install --force`, byte-idêntico) |
| `bin/sdd` — `cmd_close` manda stderr para o `.err` irmão e nomeia os três arquivos (R6) | — | n/a | Mudança **interna** de um comando cujo contrato publicado não mudou: nenhum documento descreve onde `cmd_close` grava o stream cru. O que sobrava de prosa virou sensor no `R8`, não doc — `close names the raw stream and the stderr beside the summary` |
| `bin/sdd` — `autonomy_no_data` passa a nomear os quatro escritores (R7) | — | n/a | A frase **é** a interface (sai na tela do `sdd autonomy` quando não há ledger) e foi consertada no próprio código; `docs/pipeline.md` não enumera escritores em lugar nenhum. Hoje tem sensor: `autonomy_no_data names every writer the runner has` (`12b15b8`) |
| `~/.sdd/autonomy-log.jsonl` — as 11 linhas de fixture saem (I1) | `CONTEXT.md`, verbete *Recusa do ledger real (checkout temporário)* | ✅ | `599ee0a` — o verbete afirmava que cinco dos sete repos do ledger real são fixture sob `/tmp`, o que o I1 tornou falso. Passa a registrar a limpeza (backup por `grep -v`, nunca `jq`) e a mandar ler o número do comando: `grep -c '"repo":"/tmp' ~/.sdd/autonomy-log.jsonl` → `0` |
| `TODO.md` — 105 → 96 achados; dez dívidas declaradas migram para o cabeçalho do sensor dono (I6) | `KAIZEN_LOG.md`, `tests/health-baseline.txt`, os cabeçalhos dos sensores | ✅ | `4d9b7b8` (entrada de kaizen com antes/depois medido + catraca 105 → 95) e `12b15b8` (o achado da r3 entra, catraca 95 → 96). Hoje: `tests/check-todo.sh` → `96 finding(s)`, baseline `todo-findings 96` |
| `tests/check-autonomy.sh`, `check-kaizen.sh`, `check-mutation.sh`, `check-gates.sh`, `check-health.sh`, `check-pipefail.sh`, `check-entrypoint.sh` | — | n/a | Sensores novos **dentro** de sensores que já existem: nenhum arquivo `tests/check-*.sh` nasceu nesta missão, então os quatro lugares que o `CLAUDE.md` exige ao acrescentar um sensor (linha do `run-all.sh`, `LINT_FLOOR`, piso do `check-pipefail.sh`, piso do `check-lang.sh`) não se movem. A dívida declarada de cada regra sem probe mora no **cabeçalho do próprio sensor** (I6), que é onde a régua D15 a manda morar |
| `CLAUDE.md` e `.claude/rules/anatomia-do-agente.md` | — | n/a | **Nenhuma convenção mudou.** A missão *aplicou* três regras que já estavam escritas (uma definição de enum por programa — o `is_close` entrou nos dois leitores no mesmo commit; predicado de admissão positivo; régua D15 de admissão de achado) e não criou nenhuma. Regra inventada por agente é dívida que a próxima sessão obedece sem questionar — a régua do `CLAUDE.md` é escrever só quando a convenção **de fato** mudou |
| `docs/adr/` | — | n/a | Nenhuma decisão arquitetural nova nem revertida: a leitura larga do juiz segue a ADR 0005 e a guarda de escrita é a parte 3 dela. O único candidato — o veto `harness_mixed` sem remédio nem override — é **pendência aberta e sem dono** (pendência 2 da r3), e ADR se escreve sobre decisão tomada, não sobre decisão adiada |
| `config/schema.md`, `templates/` | — | n/a | Nenhuma chave de config e nenhum contrato de artefato mudou nesta missão; o diff não toca `config/` nem `templates/` |

## Carimbo de mutação

⚠️ O commit `599ee0a` toca `bin/sdd` (dois comentários), e `bin/` está dentro de
`MUTATION_STAMP_PATHS` — então o carimbo anterior (`784f8334…`, escrito pelo `R8`) morreu com ele.
`./bin/sdd health` foi rodado **depois** do último commit de código, que é a ordem que custa 20 a 50
minutos quando se erra:

```
$ ./bin/sdd health          # rodado sobre a árvore de 599ee0a, o último commit de código
  ok   suite green
  ok   mutation: score: 304 caught, 0 known gap(s), of 304
  ok   mutation stamp written — gate_PR can see that THIS content ran green
  ok   all 8 gates have a mutation in the catalogue
  ok   provenance: all 3 fixtures match the installed skills
  ok   ratchet: 1 known debt(s), none new
  ok   kit healthy

$ cat .sdd/logs/mutation-stamp
12ff9adf76ae98839c8e79fffba5f488   # era 784f8334… antes do 599ee0a
```

## Entradas do `TODO.md` conferidas nesta missão

> A régua é a do template: **o quê + onde (`arquivo:linha`) + por que importa + quem descobriu
> (agente/missão/data)**, em no máximo 8 linhas. Quem cobra a forma é `tests/check-todo.sh`, e ele
> responde `96 finding(s), all within 8 lines and carrying anchor + date`.

| Entrada | Nascida em | Estado |
|---|---|---|
| `check-templates.sh` imprime `ok` com três espaços contra os quatro que todo Check ancora — `tests/check-templates.sh` | r3 desta missão, levada pelo `R8` (`12b15b8`) | Bem formada, nada a completar: tem âncora, tem o "por que importa" (85 de 1058 asserções fora da grafia que o `CLAUDE.md` declara), diz que falha **fechada**, dá a direção e carrega `descoberto por sdd-reviewer na missão … (2026-09-12)` |
| Os **nove** itens que a missão fechou (`grep 'RESOLVIDO por'` citando os shas desta branch) | backlog anterior | Conferidos: cada um cita o hash que o fechou e o mutante que o segura, e continuam na seção Aberto até o PR mergear — apagar é o ato do `sdd close`, provado por `git merge-base --is-ancestor`, nunca pelo rótulo do PR |
| Os **dez** itens que saíram do backlog por serem limite e não defeito (I6) | backlog anterior | Conferidos no destino: cada um está no cabeçalho do sensor dono, que é onde a régua D15 os manda morar. Dívida escrita é limite; dívida calada é o fail-open que a régua separa |

Nenhum achado novo nasceu nesta fase: os quatro que eram meus estavam nomeados com âncora exata
pelas rodadas r2 e r3 e foram **consertados**, não registrados.

## Riscos e não-feitos

- **O `R8` não foi re-avaliado por um revisor que não o escreveu** — `REVIEW_MAX_ITER=3` esgotou e a
  decisão humana registrada nas notas foi aceitar a r3 como última rodada de nota. A nota `B` da r3
  é, portanto, **anterior** aos consertos que ela mesma pediu. A segunda leitura independente virá
  de fora do kit (`@codex review` no PR). Isso tem de estar no corpo do PR.
- **Pendência 2 da r3 segue aberta e sem dono:** `harness_mixed` veta `guard.sufficient` sem remédio
  nem override, então um `kit_sha` que atravessou um bump de harness nunca poderá ser graduado
  `melhorou`/`piorou`. As três saídas estão escritas na r1. A missão fecha com ela aberta, por
  decisão consciente.
- **Não refatorei documento alheio no meio da missão.** A seção `## Boot da próxima fase` sem teto
  (8 829 B na medição da dieta) continua sendo o terceiro maior termo do boot e continua sem teto;
  é dívida declarada da rule `anatomia-do-agente.md`, não trabalho desta fase.

## Boot da próxima fase

A próxima fase é **PR**. Comece por aqui:

1. `git log --oneline fa02fc6..HEAD` — 30+ commits, o último de documentação é `599ee0a`.
2. O carimbo de mutação está **vivo e é o mais recente**: foi refeito depois do último commit que
   tocou `bin/`. ⚠️ Não toque em `bin/ tests/ templates/ config/` antes de abrir o PR, ou o
   `gate_PR` volta a pedir 20–50 minutos de `./bin/sdd health`.
3. O corpo do PR precisa carregar, além do resumo: (a) que o `R8` **não teve re-avaliação
   independente** e por quê (teto de rodadas + decisão humana), com o pedido de `@codex review`;
   (b) a pendência 2 da r3 (`harness_mixed`), aberta e sem dono; (c) as três métricas do
   `00-missao.md` re-medidas — hoje `96 finding(s)` (a métrica pedia 95, e o delta é o achado da r3
   que o `R8` registrou, com a catraca movida no mesmo diff), `grep -c '"repo":"/tmp'` → `0`, e a
   guarda de duas versões de harness respondendo `sufficient: false` com a razão nomeada.
