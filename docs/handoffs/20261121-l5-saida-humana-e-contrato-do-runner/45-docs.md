---
missao: 20261121-l5-saida-humana-e-contrato-do-runner
fase: DOCS
status: done
sessao: 01a2193e-97cb-7eb3-98b4-8cd5fa9068cc
data: 2026-11-26 16:27
gate: "`tests/run-all.sh` em 1a8b1cfe3d8200ab8891b0923c2b4071250b68f4 → rc 0, suite green, 21 etapas, 2498 linhas ok, zero FAIL, 1180 s. As 46 asserções ancoradas de I1–I17 passaram, e o Check R8 deu 1 1. Checklist de drift abaixo com commits e os textos reservados ao dono."
---

# Handoff — DOCS — L5: saída humana e contrato do runner

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

O guia, o esquema de configuração e o README descrevem os limites do runner do L5.
O Kaizen registra os 17 itens entregues e 27 sessões de EXEC, com custo em dólares desconhecido.
O dono ainda decide sobre a segunda prova de resolução e aplica os textos de convenção no PR.

## Estado do repo

- **Branch:** `fix/l5-saida-humana-e-contrato-do-runner`, sem upstream configurado e com divergência da referência local `origin/main`.
- **Último commit antes deste handoff:** `2068f0e` — docs(l5): liga as provas ao procedimento pós-merge.
- **Working tree antes deste handoff:** limpo.
- **Suíte:** `tests/run-all.sh` em `1a8b1cf` → rc 0, suite green, 21 etapas, 2498 linhas ok, zero FAIL, 1180 s. As 46 asserções ancoradas de I1–I17 passaram, e o Check R8 deu 1 1.
- **Delta de prosa após a suíte:** `bash tests/check-lang.sh` e `bash tests/check-hat.sh` em `2068f0e` → rc 0.
- **E2E:** `E2E_CMD=""`. A QA percorreu a CLI. Não há jornada de interface para repetir.

## O que foi feito

- `1a8b1cf` — documenta a alocação de ADR e os limites da reserva, a troca da semente do TODO e o aviso quando falta `/sdd-plan`.
- `2068f0e` — liga os guias da fila e da catraca à prova e ao procedimento pós-merge.
- `1a8b1cf` — registra o antes e o depois de I1–I17, confere os 17 pares de título e hash e coloca o L5 na série de custo e tempo.
- `1a8b1cf` — completa a direção e a atribuição dos registros da REVIEW r1 sem remover itens do backlog.

## Artefatos

| Arquivo | O que contém |
|---|---|
| [KAIZEN_LOG.md](../../../KAIZEN_LOG.md) | Antes/depois do L5 e custo da EXEC na série da campanha. |
| [README.md](../../../README.md), [pipeline](../../pipeline.md), [PLAN-only](../../plan-only.md) e [esquema](../../../config/schema.md) | Rotas de uso e detalhes dos contratos que mudaram. |
| [ADR 0025](../../adr/0025-ids-across-refs-and-the-second-proof-of-a-resolution.md) | Alcance da reserva de números e segunda prova de resolução. |

## Boot da próxima fase

Para preparar o PR, leia a [métrica](00-missao.md#métrica), a
[QA](30-handoff-qa.md), o [comparativo da r7](40-review-r7.md#o-que-virou-incremento),
a [revisão final](40-review-r8.md) e as propostas abaixo. Use `git diff origin/main...HEAD --stat`
para o inventário e a base `main` configurada para este kit. Separe os comandos verificáveis da
evidência histórica, especialmente o R8 e os 17 títulos. Não use a contagem global de I18.
A dependência anterior à corrida foi atendida: os PRs do L3 e do L4 entraram em `1f7f527`
e `cef90b1`, ancestrais da janela de EXEC. Leve ao PR um item para cada documento com texto proposto, incluindo `CLAUDE.md`, que o plano
reservou ao dono. Registre as pendências já resolvidas do plano com a evidência que as responde.
O exemplo de encerramento do PR deve indicar `sdd close` depois do merge, mesmo sem JIRA.

## Pendências / Decisions for a Human

- Confirme no PR as escolhas 1–9 e os mecanismos 10–18 do [grill](00-missao.md#decisões-do-grill-não-re-litigar), feitos por delegação escrita.
- Decida separadamente se aceita a segunda prova no squash, que diverge do `CLAUDE.md` atual. Se não aceitar, o plano prevê reverter I10 e o braço de prova pelo head do PR no I11.
- Aplique no PR os textos propostos para `CLAUDE.md` e `.claude/rules/anatomia-do-agente.md`. O plano reservou essas edições ao dono.
- Decida se a sessão `QA:close` comprada por `sdd run` antes de escalar `app-down` merece item próprio. O L5 alterou só a orientação de `sdd status`.
- Após o merge, faça o yokoten nos alvos com `sdd preflight` e, onde se usa links, `sdd-link-agents`. O retrofit de `todo-to-github-issues` está em outro repo e fica com o dono.
- O PR do kit segue a regra do dono de merge commit sem carimbo. A retirada dos 17 itens e o ajuste da catraca são do chore pós-merge.

## Riscos e não-feitos

- Não houve catálogo completo de mutação, carimbo, edição de código nem limpeza do TODO nesta fase.
- O alocador não vê branches só presentes em outra máquina e não impede duas alocações simultâneas em worktrees diferentes. A reserva exclusiva é por caminho.
- A segunda prova do `sdd close` vale somente para o head disponível localmente do PR desta missão, confirmado como `MERGED`.
- O pipeline e o guia de falhas mantêm seções de referência separadas por assunto. O bloco de ledger e juiz ocupa cerca de 25% do pipeline, abaixo do limiar de 40% do registro decidido no TODO. Não houve divisão de documentos nesta fase.
- Os recibos Codex das sessões EXEC não fornecem cobrança ou estimativa numérica. Não há comparação em dólares entre L5 e L1–L4.

## Achados fora de escopo

Nenhum item novo. A seção final lista os registros conferidos e o que ficou no backlog.

## Checklist de drift

| Área tocada pelo diff | Documento correspondente | Status | Evidência |
|---|---|---|---|
| Reserva de ADR em `bin/sdd` (I1, R2, R6) | `README.md`, `docs/pipeline.md`, `config/schema.md`, ADR 0025 | ✅ | Uso e limites em `1a8b1cf`. Decisão em `ec0f995`, limites e provas na versão atual em `0426916`. |
| Links de comandos e aviso de preflight (I2, R1, R4, R5) | `README.md`, `docs/plan-only.md` | ✅ | Instalação em `8718ccf`, migração e preservação em `6ac31be`, localização do aviso em `1a8b1cf`. |
| Instalação e preflight de semente em outro idioma (I15) | `config/schema.md` | ✅ | Comando e preservação de bytes editados em `1a8b1cf`. |
| Ajuda de execução destacada (I3) | `README.md`, `docs/failure-modes.md` | ✅ | Rota em `03091ed` para a receita já existente no guia de falhas. |
| Leituras Git de status, selo do kit e prontidão de PR em `bin/sdd-worker` (I4) | `docs/pipeline.md` | ✅ | Contrato de observação em `012044b`. A leitura interna do selo e de `pr-ready` não muda o comando nem a decisão que ele retorna. |
| Resolução de argumento iniciado por hífen e ajuda global (I5) | — | n/a | A gramática de nomes e os exemplos seguem válidos. O delta recusa entrada inválida e conserva a ajuda anterior. |
| Admissão por trava e diagnóstico de app fora do ar (I7, I8) | `docs/failure-modes.md`, `docs/pipeline.md` | ✅ | A rota sem trava já está nos guias. A restauração do app e a distinção do relatório em disco foram registradas em `51203f0`. |
| Aviso de commit na base, run e retry (I13, R3) | `docs/pipeline.md` | ✅ | Exceção TICKET em `f27e0f8` e limite do EXEC forçado em `234b734`. |
| Receita e lembrete do Kaizen (I6, I14) | `docs/failure-modes.md`, `docs/pipeline.md` | ✅ | Receita com `--no-track` em `0fe8217`, backlog e teto por sessão em `ca5260b`. |
| Encerramento e lista de referências a PR aberto (I9, I12) | `README.md`, `docs/pipeline.md`, `templates/pr-body.md` | ✅ | Próximo passo e template em `70c956f`, linhas obsoletas em `e30971f`, resumo de JIRA opcional em `d21723f`. |
| Provas e leitor de resoluções (I10, I11, R3, R6–R8) | `docs/pipeline.md`, `templates/todo.md`, `templates/todo.pt-BR.md`, `agents/sdd-kaizen.md` e espelho | ✅ | Duas provas em `5348c7d`, listagem em `891712d`, hashes malformados em `234b734` e limite de parágrafo em `a3518ea`. R8 só limita trabalho sem mudar a saída. |
| Ciclo de vida resumido no princípio 5 | `CLAUDE.md` | n/a | Alteração de política reservada ao dono pela pendência 4 da missão. Proposta explícita abaixo. O gate recusa ⛔ neste caminho por ele constar no chapéu padrão. |
| Memória do ADR e portas de intervenção humana | `.claude/rules/anatomia-do-agente.md` | ⛔ | §§ 5 e 7. Caminho de regra fora das escritas da fase. |
| Regra de âncora e teto de largura (I16) | `templates/checkpoint.md`, templates TODO, `agents/sdd-planner.md`, `agents/sdd-executor.md` e espelhos | ✅ | Prosa alinhada às exceções efetivamente medidas em `3faad6c`. |
| Citações nos chapéus, em `commands/sdd-plan.md` e `commands/sdd-worker.md`, nos templates e no aviso do worker | Chapéus, espelhos, comandos e templates tocados | ✅ | Citações qualificadas pelo kit em `dfd5f25`, com sensor anti-regressão. Não muda o ADR do alvo nem sua sintaxe. |
| Fechamento I18, achados e catraca | `TODO.md` | ✅ | Vínculos dos 17 títulos em `a033008`. Registros da r7 em `8310b12` e `178bf75`. Complementos de gramática em `1a8b1cf`. Os ajustes de baseline anteriores à DOCS incluem achados novos, não retirada dos 17. |
| Sensores ADR, coordenação, gates, chapéus, Kaizen, mutação, preflight, templates, TODO e worker | — | n/a | Asserções, fixtures e catálogo verificam os contratos das linhas acima. Não houve nova forma de executar a suíte ou alteração da gramática de entrada. |
| Handoffs, aceite, checkpoint e trilha interna da missão | `20-handoff-exec.md`, `30-handoff-qa.md`, relatórios de REVIEW | ✅ | Evidência da fase com 26 incrementos em `dfd2197`, QA em `267be6b` e revisão final em `04376a7`. |
| Série de entrega e custo da campanha | `KAIZEN_LOG.md` | ✅ | Entrada própria do L5 e comparação com L1–L4 em `1a8b1cf`. |
| Limpeza pós-merge e catraca do volume | `docs/finding-prs.md`, `docs/failure-modes.md` | ✅ | A receita começa com `sdd close` e distingue listagem de remoção. As duas provas e a regra de merge do kit estão em `2068f0e`. |

## Texto proposto para o dono
<!-- sdd:proposed -->

Em `CLAUDE.md`, no princípio 5, substitua o trecho de “Consertado por commit” até
“próxima QA o registraria de novo” por:

> Consertado por commit, o corpo ganha `RESOLVED by <hash>` (token do kit, igual em todo idioma).
> O item **é apagado** no pós-merge quando cada hash passa uma de duas provas.
> `git merge-base --is-ancestor <hash> <DEFAULT_BRANCH>` deve retornar 0, ou
> `git merge-base --is-ancestor <hash> <head do PR>` deve retornar 0 e
> `gh pr view <PR> --json state,headRefOid` deve mostrar `MERGED` para esse mesmo head na hora da consulta.
> O rótulo do PR por si só nunca prova uma resolução. Refutado ou decidido, o item vira
> uma linha na seção decidida, porque não há commit que o feche e a próxima QA o registraria de novo.

Em `.claude/rules/anatomia-do-agente.md`, § 5, na abertura do parágrafo sobre `docs/adr/`,
substitua as duas primeiras frases, até “em dois escopos”, por:

> O `docs/adr/` deixou de ser memória **sem rota**. `sdd adr new` escolhe o número seguinte ao
> maior arquivo regular de ADR visível no checkout, nos refs locais e de rastreamento remoto e no
> disco dos demais worktrees. A saída indica a origem do máximo quando ela fica fora do checkout.
> A criação exclusiva protege o arquivo de destino, não serializa alocações entre worktrees e
> não enxerga branches que só existem em outra máquina. Com `--spec`, o comando escreve os dois
> lados do vínculo. `sdd adr check` lê de volta em dois escopos.

No mesmo documento, § 7, substitua o trecho de “Admissão não é escalada” até “expõe o proprietário” por:

> **Admissão não é escalada.** `CHECKOUT-BUSY`/75 não abre sessão, não altera checkpoint,
> não escreve ledger de missão e não chama hook. A recusa indica `sdd status --no-gates`, que expõe o proprietário e lê o disco sem disputar a trava.

No fim do parágrafo “Onde mora hoje”, substitua “merge do PR é humano; `sdd close`” por:

> O merge do PR é humano. Se a QA for a próxima fase e o app não responder, `sdd status` manda
> restaurá-lo e distingue o handoff `done` em disco da e2e que não pôde revalidar.
> Ao terminar a corrida, `sdd run` e `sdd status` indicam `sdd close` após o merge, com ou sem JIRA.
> De volta à base limpa, o fechamento lista as resoluções comprovadas sem remover itens.
> Se confirmou o PR como `MERGED` e a URL termina com o número do PR, também lista as linhas
> versionadas que ainda o dão como aberto, fora dos handoffs, sem editar os arquivos.

## Registros do TODO conferidos

- **EXEC:** intermitência do probe de processo residual, cópia do catálogo sem guias e preparação do fixture de fast-forward. Continuam abertos, com âncora, direção e fonte.
- **REVIEW r1:** reserva simultânea de ADR continua aberta. Ajuda de fechamento mantém `RESOLVED by 269ecc7`. Direção e atribuição completadas.
- **REVIEW r2:** o fallback por linhas com LF no caminho consta no `RECURRED` do item de `checkouts_of`. Continua um item só.
- **REVIEW r5:** README pós-merge conserva `RESOLVED by d21723f`. A expressão histórica do I18 fica no item aberto existente, sem duplicação.
- **REVIEW r7–r8:** a contagem no handoff EXEC e os tempos sem registro da r6 conservam `RESOLVED by dfd2197`. Saem apenas no pós-merge, assim como os 17 itens do Gemba.
- `bash tests/check-todo.sh --check TODO.md` e `bash tests/check-todo.sh --anchors TODO.md` em `1a8b1cf` mediram 100 achados e zero âncoras fora do alvo.
