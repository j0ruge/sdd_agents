---
missao: 20261012-a-rota-da-qa
fase: EXEC
status: done
sessao: 52d22ab5-b1b5-460e-b0f2-010f0e40b3b3
data: 2026-10-14 16:34
gate: "tests/run-all.sh → run-all rc=0 in 581s, 1995 ok, 0 FAIL, sobre 93bc43d; checkpoint I1–I12 done, I13 com este handoff"
---

# Handoff — EXEC — o lote 7: a rota da QA e o aceite que lê o plano

> Execução **interativa**, num worktree ligado (`~/repos/sdd_agents-lote-7`, ADR 0016 §2), nunca por
> `sdd run`: missão do kit.

## TL;DR

Os 13 incrementos estão feitos, com Check verde e um commit cada (mais o `docs(missao): I<n> feito`).
A suíte inteira passa no head do código (`93bc43d`), o catálogo vai de 687 a 716 mutantes, e cada
mutante novo foi rodado contra o seu sensor numa cópia mutada e derrubou exatamente os mundos que o
plano lista. Próximo: abrir o PR, esperar todos os bots, uma leva de consertos, `./bin/sdd health`
uma vez (carimbo), merge humano — e o kit congela nesse merge (D11).

## Estado do repo

- **Branch:** `fix/lote-7-a-rota-da-qa` — ainda **não empurrada**; o upstream configurado é
  `origin/main` (efeito do `worktree add -b … origin/main`), então o push leva `-u origin HEAD`.
- **Último commit de código:** `93bc43d` (I13, só prosa); o último em `bin/ tests/` é `8cf5cdd` (I12).
- **Working tree:** limpo antes deste handoff.
- **Suíte:** `tests/run-all.sh` → `run-all rc=0 in 581s`, 1995 linhas `ok`, 0 `FAIL`.
- **E2E:** não se aplica (o kit não tem interface).

## O que foi feito

- `4614701` — I1: `qa: skipped` literal leva o `qa_substep` ao `close` com interface; motivo do `skipped` diz o que leu.
- `1e82e36` — I2: o contrato da chave `qa:` (template, `sdd-qa` § 0/§ 2, planner, pipeline).
- `f0f0edd` — I3: `qa_fix_ahead_of`/`qa_rewritten_after`, a rota do reteste; comentários da flag das skills.
- `881c2a3` — I4: o frescor do `30-handoff-qa.md` no `gate_QA`; fixture do `check-autonomy.sh` (1ª correção).
- `4956c5c` — I5: `test.fail()` depois das pré-condições para o bug que nenhum agente fecha.
- `c491be4` — I6: o aceite do `/sdd-plan` mede de novo, renderiza o plano e conta as recomendadas.
- `bdcaf78` — I7: o planner marca cada resposta, lê as regras de nome do alvo, deixa `aprovacao:` vazio, reestima a 2×.
- `4f4affc` — I8: todo carimbo de hora sai de `date` (`turn_rule`).
- `c771947` — I9: o `gate_DOCS` cobra a entrada do `KAIZEN_LOG.md` (chave `kaizen_log: skipped`, bloco, id inteiro).
- `eeb7665` — I10: onde vai o `RESOLVED by` num item no teto.
- `4e54d22` — I11: a gramática do id da missão no `resolve_mission` (com a âncora do `TODO.md` reancorada).
- `8cf5cdd` — I12: `k8_base_refusal`, a missão na base não promete o K8.
- `93bc43d` — I13: CONTEXT, anatomia § 7, gaveta, ADR 0018 `accepted`, a entrada do `KAIZEN_LOG.md`.

Verificação de fecho, no `93bc43d` (a última linha de cada comando):
- `tests/run-all.sh` → `run-all rc=0 in 581s` (1995 ok, 0 FAIL);
- `tests/check-mutation.sh --anchors` → `anchors: all 716 mutants still apply and leave valid code`;
- `./bin/sdd adr check` → `ADR_CHECK=block, 18 ADR(s) in docs/adr`, rc 0;
- `./bin/sdd install --force` → nada a sincronizar (árvore limpa depois);
- `env -u CLAUDECODE ./bin/sdd preflight` → `preflight ok`, sem `agent … stale`.

## Artefatos

| Arquivo | O que contém |
|---|---|
| `docs/handoffs/20261012-a-rota-da-qa/checkpoint.md` | a tabela, I1–I13 |
| `docs/handoffs/20261012-a-rota-da-qa/checkpoint-notas.md` | uma nota por incremento: vermelho antes, mutantes e os mundos de cada um, sabotagens, desvios |
| `docs/adr/0018-the-qa-route-and-the-read-plan.md` | a ADR do lote, agora `accepted` |

## Boot da próxima fase

O PR (humano com a sessão interativa, não `sdd run`): `git push -u origin HEAD` do worktree, `gh pr
create` contra a `main` com a evidência acima, `@codex review` (e `@coderabbitai review` se a janela
permitir; ele não bloqueia), `local/ci` publicado pela API de Statuses com o resultado real da suíte
no head. Consertos numa leva só; depois, e só depois do último commit em `bin/ tests/ templates/
config/ agents/`, copiar o `mutation-killers.tsv` do checkout principal para o `.sdd/cache/` do
worktree e rodar `./bin/sdd health` uma vez (716 mutantes, ~40–60 min).

## Pendências / Decisions for a Human

- O merge do PR (merge commit), e com ele o congelamento da D11.
- O sync do espelho do `TODO.md` em issues: a âncora do item do `gate-qa-e2e` andou de `bin/sdd:1800`
  para `:1835`, e o espelho ainda tem os 4 itens do PR de docs a criar.
- Yokoten nos alvos (`sdd-qa.md`, `sdd-planner.md`, `sdd-docs.md` mudaram): `sdd install --force`
  numa branch `chore/kit-<sha>` do `sales_quote`.
- O caderno de campo (PR #246): a contagem das respostas recomendadas desta missão sai do leitor da
  D22 (`25 (recommended) of 25` no aceite).

## Riscos e não-feitos

- **Desvio do plano no I3, declarado:** as versões do relatório nos mundos do reteste são todas
  `closed` (o plano restaurava uma `open`, que manda ao `exec` sem chegar à regra); detalhe nas notas.
- **Fixture do I9 em inglês:** o texto pt-BR do protótipo reprova o `check-lang` em `tests/`; a
  estrutura dos 19 mundos é a do plano.
- A sabotagem da regex do id (faixas, sem `^`, sem `$`) não foi refeita: medida no protótipo do plano.
- Os riscos do plano seguem valendo (o frescor pode reabrir a QA de uma missão de alvo em voo; a D23
  cobra a entrada de toda missão em voo sem a chave).

## Achados fora de escopo

- Nenhum novo nesta execução.
