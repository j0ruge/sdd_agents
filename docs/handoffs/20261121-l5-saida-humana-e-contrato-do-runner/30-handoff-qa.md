---
missao: 20261121-l5-saida-humana-e-contrato-do-runner
fase: QA
status: done
sessao: 01a215ad-652a-7851-a3d7-c1baed2ce761
data: 2026-11-25 23:47
gate: No SHA 912788285263aa3c3017062235c32a39f4be20fe, `tests/run-all.sh` terminou com rc 0, `suite green` e zero linhas `FAIL`. Em Git de rascunho, `sdd install` trocou a semente intocada para pt-BR e preservou a editada. `sdd-link-agents` ligou os dois comandos sem alterar os links na repetição. `sdd why -l` recusou a opção e `sdd help` exibiu a forma destacada. `sdd adr new --slug x --dry-run` propôs 0018 em dois branches. `sdd status 20261125-qa-rascunho` distinguiu app fora do ar de app respondendo com e2e vermelha. `sdd run 20261125-qa-rascunho` e `sdd status 20261125-qa-rascunho` nomearam o pós-merge com e sem JIRA. `sdd close 20261125-qa-rascunho` listou só o que tinha prova de merge e manteve o backlog byte a byte.
---

# Handoff — QA — L5 — saída humana e contrato do runner

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

QA concluída após oito jornadas da CLI em repositórios descartáveis.
Nenhum achado confirmado, nenhum spec novo, nenhum incremento de fix e nenhuma decisão nova para o humano.
A suíte passou e o I18 confirmou os 17 registros de resolução. A REVIEW recebe os controles do pós-merge e de app fora do ar abaixo.

## Estado do repo

- **Branch:** `fix/l5-saida-humana-e-contrato-do-runner`, sem upstream configurado no Git desta sessão. A base medida de `origin/main...HEAD` é `60ec571`.
- **Último commit antes deste handoff:** `9127882` — chore(exec): fecha o checkpoint e entrega o L5 à QA.
- **Working tree na entrada:** só `checkpoint-notas.md` estava modificado, com 259 inserções preexistentes no `git diff --stat`. O arquivo não foi aberto, reescrito ou incluído no commit da QA.
- **Suíte:** `tests/run-all.sh` → rc 0, `suite green`, 21 etapas, 2473 linhas `ok` e zero linhas `FAIL`.
- **E2E:** `E2E_CMD=""` e sem `APP_URL` no kit. A jornada real do kit é a CLI. Os cenários de app usam transporte simulado e `E2E_CMD="false"` apenas na fixture.

## O que foi feito

Medições no SHA `912788285263aa3c3017062235c32a39f4be20fe`. Nos rascunhos, `$kit` foi o caminho absoluto deste checkout. Cada rascunho teve Git, home e estado próprios. Usei `gh` e `acli` de fixture e nenhuma sessão paga.

| Jornada | Comando e resultado |
|---|---|
| Instalar e preservar — `0c457ab` | `"$kit/bin/sdd" install` com idioma vazio explicou a semente em inglês. Com `OUTPUT_LANG="pt-BR"`, substituiu a semente intocada pela versão pt-BR. Após acrescentar um byte e mudar o idioma de novo, preservou o arquivo editado, confirmado com `cmp`. |
| Ligar os comandos — `8718ccf` | `"$kit/bin/sdd-link-agents"` ligou `sdd-plan.md` e `sdd-worker.md` a `$kit/commands/`. Ambos passaram em `git check-ignore`. A segunda chamada preservou os inodes dos links e os bytes do `.gitignore`. |
| Recusar opção no lugar de missão — `f7709e3` | `"$kit/bin/sdd" why -l` deu rc 1 e nomeou `-l` como opção, embora o rascunho tivesse a missão `20261125-lote-de-rascunho`. |
| Ler a ajuda — `03091ed` | `"$kit/bin/sdd" help` mostrou a forma com `setsid nohup`, o caminho `.sdd/logs/<mission>/pipeline.log` e `sdd status <mission> --no-gates`. O exemplo destacado não foi executado. |
| Alocar ADR — `436b1f2` | `"$kit/bin/sdd" adr new --slug x --dry-run` propôs `docs/adr/0018-x.md` tanto no branch com 0004 quanto no branch com 0017, sem criar arquivo. Do branch com 0004, nomeou `refs/heads/adr-high` como origem de 0017. |
| Retomar após falha — `51203f0` | `"$kit/bin/sdd" status 20261125-qa-rascunho` com relatório fechado da fixture e e2e vermelha. Sem resposta do app, disse que a QA estava fechada em disco, orientou subir o app e omitiu a linha de retomada. Com resposta, indicou `sdd run 20261125-qa-rascunho`. |
| Terminar a corrida — `70c956f` | `"$kit/bin/sdd" run 20261125-qa-rascunho` terminou com rc 0 e `pipeline complete`, sem abrir sessão, tanto com `JIRA_ENABLED=false` quanto com `true`. O comando e `"$kit/bin/sdd" status 20261125-qa-rascunho` apontaram `sdd close` para depois do merge nos dois casos. |
| Fechar após merge — `891712d`, `e30971f` | `"$kit/bin/sdd" close 20261125-qa-rascunho`, em árvore limpa, listou dois itens provados (pela base e pelo head do PR) e as duas referências obsoletas a `PR #7` com `MERGED`, com e sem JIRA. Confirmou a issue já `Done` e fez o fast-forward da base no caso com JIRA. Recusou `OPEN` com rc 1. Sem `pr_url`, voltou à base e mostrou só o item ancestral dela, sem listar referências ao PR. `cmp` confirmou que o TODO não mudou. |

- **Contrato da missão.** Os Checks I1–I17 deram os valores esperados nas saídas dos respectivos sensores da suíte e nos arquivos que os Checks leem, com 46 asserções ancoradas. O Check I18, comparado com `git merge-base HEAD origin/main`, deu 17. Os 17 títulos da missão apontam no `TODO.md` para os hashes respectivos do `checkpoint.md`, todos ancestrais do HEAD medido.
- **Sensores e integridade.** Os 28 mutantes nomeados na seção “Verificação end-to-end” constam como função e entrada do catálogo em `tests/check-mutation.sh`. A etapa `tests/check-mutation.sh --anchors` da suíte validou 1017 âncoras. `bash tests/check-todo.sh --check TODO.md` deu rc 0 e `bash tests/check-todo.sh --anchors TODO.md` mediu 92 âncoras, zero fora do alvo.
- **Espelhos e rastreabilidade.** `cmp -s "agents/$h.md" ".claude/agents/$h.md"` deu rc 0 para `sdd-kaizen`, `sdd-planner`, `sdd-executor`, `sdd-docs`, `sdd-publisher` e `sdd-reviewer`. `./bin/sdd adr check --mission 20261121-l5-saida-humana-e-contrato-do-runner --phase plan` deu rc 0 e confirmou que o ADR 0025 aponta de volta à missão.

## Artefatos

| Arquivo | O que contém |
|---|---|
| [`30-handoff-qa.md`](30-handoff-qa.md) | Evidência durável da QA sem interface. |
| [`checkpoint.md`](checkpoint.md) | I1–I18 já concluídos, sem linha `F<n>` nova. |
| `docs/qa/` e `e2e/` | Nenhum relatório datado, bug ou spec novo. O histórico existente em `docs/qa/` foi preservado. |

## Boot da próxima fase

Na REVIEW, leia este handoff, a seção “Verificação end-to-end” do [plano](01-plano.md), o [checkpoint](checkpoint.md) e o [ADR 0025](../../adr/0025-ids-across-refs-and-the-second-proof-of-a-resolution.md). Use `git diff origin/main...HEAD -- bin/sdd bin/sdd-link-agents bin/sdd-worker tests/` para revisar os contratos. Nos controles de `tests/check-gates.sh`, separe a prova pela base da prova por head de PR `MERGED`. Confira que a listagem não edita o backlog e que `sdd status` conserva a QA fechada em disco quando o app está fora do ar. `tests/check-kaizen.sh` cobre a indicação pós-merge no fim da corrida.

## Pendências / Decisions for a Human

- Nenhuma decisão nova da QA. Levar ao PR as pendências já declaradas em [00-missao.md](00-missao.md#pendências-para-o-humano), inclusive o aceite das escolhas delegadas e a atualização, pelo dono, da regra sobre a segunda prova de merge no `CLAUDE.md`.

## Riscos e não-feitos

- Nenhum PR ou item JIRA real foi aberto, fechado ou mesclado. O sandbox restringiu loopback e o par app fora/respondendo usou as respostas TCP/HTTP simuladas de `tests/app-probe-fixture.sh`. A corrida foi só em fixture, em primeiro plano.
- A QA não repetiu as execuções individuais dos mutantes nem rodou o catálogo completo. Conferiu os 28 do plano e todas as âncoras na suíte, sem gerar carimbo.
- Continua fora do L5 antecipar a escalada `app-down` de `sdd run`. O lote mudou a orientação de `sdd status`, como decidido no [plano](01-plano.md).

## Achados fora de escopo

- Nenhum achado novo confirmado. Nenhuma alteração no `TODO.md` pela QA.
