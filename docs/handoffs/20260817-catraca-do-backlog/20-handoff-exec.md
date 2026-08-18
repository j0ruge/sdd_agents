---
missao: 20260817-catraca-do-backlog
fase: EXEC
status: done
sessao: 6f45760c-f025-4156-8ed7-4f4a50f38883
data: 2026-08-17 23:31
gate: "`tests/run-all.sh` → rc 0 · saída final `suite green` · `score: 81 caught, 0 known gap(s), of 81` · **533** asserções `ok` no total (baseline da missão: 70 mutações; I1 levou a 72, I2 a 73, I4 a 81). `shellcheck -S warning bin/sdd tests/*.sh` limpo (roda dentro do `run-all.sh`). `./bin/sdd health` → rc 0, `kit healthy`, os **5** checks verdes: `suite green`, `mutation: score: 81 caught, 0 known gap(s), of 81`, `all 8 gates have a mutation in the catalogue`, `provenance: all 3 fixtures match the installed skills`, `ratchet: 7 known debt(s), none new` — as 6 dívidas de antes mais `todo-findings 73`, que é a catraca desta missão existindo. Os **5** Checks do `checkpoint.md` rodados contra este HEAD: I1→`1`, I2→`1`, I3→`5`, I4→`81`, I5→`1`, todos batendo com o esperado. Os 5 commits `afe5db6`, `36a6eb6`, `02e5da6`, `f0bbf82` e `ca017f9` **verificados ancestrais de HEAD** por `git merge-base --is-ancestor`. Métrica 1 provada no repo REAL e não só no fixture: baseline em 72 contra 73 reais reprova com **as duas** mensagens (`finding outside the baseline: todo-findings 73` e `stale baseline: 'todo-findings 72' … delete the line`), rc 1, baseline restaurada por `trap`. Métrica 2: `tests/check-health.sh` existe, executa `cmd_health` e é o **único** sensor que o faz — os demais hits de `sdd health` em `tests/` são 5 comentários (`check-autonomy.sh:1571`, `check-mutation.sh:97/840/862/874`) mais o rótulo com que o `run-all.sh:152` invoca este próprio arquivo. De **0** para **1**. Métrica 4: `grep -c 'RESOLVIDO por' TODO.md` → **12**, os 10 itens fechados mais as 2 ocorrências da prosa do cabeçalho."
---

# Handoff — EXEC — a catraca do backlog

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

O `sdd health` passou a emitir `todo-findings <N>` e a congelá-lo na baseline, então o backlog não
cresce mais calado — e o `cmd_health`, que nunca teve sensor, ganhou o primeiro (8 asserções).
Junto vieram 8 mutações novas (catálogo 70 → **81**, `0 known gap(s)`), os 5 defeitos de saída do
`sdd autonomy` e a política escrita no `CLAUDE.md` e no `TODO.md`. Suíte verde, `kit healthy`,
10 achados fechados com hash no corpo. **QA começa por `sdd health` e `sdd autonomy` — as duas
únicas superfícies visíveis ao humano que mudaram.**

## Estado do repo

- **Branch:** `missao/20260817-catraca-do-backlog` — local, **nunca empurrada** (é da fase PR)
- **Último commit:** `ca017f9` `docs(health): a política da catraca escrita onde a próxima missão a encontra`
- **Working tree:** limpo (o commit do checkpoint/handoff fecha a fase)
- **Suíte:** `tests/run-all.sh` → **verde**, rc 0, 533 asserções `ok`, `score: 81 caught, 0 known gap(s), of 81`
- **E2E:** `E2E_CMD` vazio no `.sdd/config.sh` — o kit não tem interface; as jornadas são comandos de CLI, exercitados pela própria suíte

## O que foi feito

- `afe5db6` — **I1: `tests/check-health.sh`**, o primeiro sensor da vida do `cmd_health`. Mede que
  as checagens dele **discriminam** (mundos diferentes, frases diferentes), não que rodam. Fixture
  hermético com suíte-stub (senão `run-all` → `check-health` → `sdd health` → `run-all`, para
  sempre) e `bin/sdd` copiado **vivo**, que é o que faz a sabotagem chegar. Entram
  `mut_HEALTH_ratchet_one_way` e `mut_HEALTH_provenance_blind`.
- `36a6eb6` — **I2: a catraca da contagem.** `cmd_health` extrai `N` da linha que o
  `check-todo.sh` já imprime na stdout da suíte e chama `health_finding "todo-findings $N"`;
  `health_ratchet` faz o resto, nos dois sentidos, sem mecanismo novo. Entra
  `mut_HEALTH_todo_count_blind`.
- `02e5da6` — **I3: os cinco defeitos de saída do `sdd autonomy`** — `US$ 2` virou `US$ 2.00`,
  duas mensagens de `die` distintas, helper para o bloco "no data" duplicado, tabela na mesma ordem
  do `kaizen_series`, linha em branco dupla removida. Cinco asserções `output:` no
  `check-autonomy.sh`.
- `f0bbf82` — **I4: oito sabotagens** para os quatro pontos cegos do catálogo (o plano previu 4;
  três dos quatro itens pediam mais de uma). Catálogo 73 → **81**.
- `ca017f9` — **I5: a política escrita e a baseline no número real.** `CLAUDE.md` (princípio 5) e o
  cabeçalho do `TODO.md` passam a dizer a regra; a asserção 8 do `check-health.sh` cobra os dois.
  10 achados fecham com `RESOLVIDO por <hash>` no corpo.

## Artefatos

| Arquivo | O que contém |
|---|---|
| `tests/check-health.sh` | O sensor do `cmd_health` — 8 asserções + 6 probes da regra de documento |
| `tests/health-baseline.txt` | A baseline da catraca: 7 dívidas, `todo-findings 73` na última linha |
| `tests/check-mutation.sh` | +11 mutações nesta missão (70 → 81) e o `sandbox()` copiando os dois documentos |
| `CLAUDE.md` | A política da catraca, dentro do princípio 5 |
| `TODO.md` | O cabeçalho com a política, e 10 itens com `RESOLVIDO por <hash>` no corpo |
| `docs/handoffs/20260817-catraca-do-backlog/checkpoint.md` | 5 incrementos `done` + 25 notas de execução |

## Boot da próxima fase (QA)

**Ambiente:** nenhum. Não há servidor, banco nem browser — `git checkout
missao/20260817-catraca-do-backlog` e os comandos abaixo bastam. ⚠️ A suíte agora leva **~7 min**
(era 2m34s): o sensor novo custa ~2 s **por mutante**, e são 81. Não é travamento.

**O que no diff é visível ao humano — são duas superfícies, e só duas:**

1. **`./bin/sdd health`** — ganhou um sexto achado. A jornada a repetir: rodar e conferir
   `ratchet: 7 known debt(s), none new` e `kit healthy`. Depois **quebrar de propósito**: trocar o
   `73` da última linha de `tests/health-baseline.txt` por `72`, rodar de novo e exigir **as duas**
   mensagens (`finding outside the baseline` **e** `stale baseline`) — é essa bidirecionalidade que
   a missão inteira existe para entregar. Restaurar o arquivo depois (`git checkout`).
2. **`./bin/sdd autonomy`** — cinco defeitos cosméticos consertados. A jornada: rodar e olhar a
   coluna de dinheiro (`US$ 2.00`, nunca `US$ 2`), a ordem das versões na tabela (primeira aparição
   no arquivo, igual à do `sdd kaizen --series`) e o espaçamento das linhas de exclusão.
   ⚠️ Ainda sobra **uma** linha em branco entre duas exclusões consecutivas — é achado **aberto** e
   registrado, não regressão desta missão.

**O que NÃO precisa ser re-andado:** nada em `sdd run`, `sdd plan`, `sdd approve`, `sdd retry`,
`sdd kaizen` mudou de comportamento. As 8 mutações do I4 são sabotagens de teste, não código de
produção.

## Pendências / Decisions for a Human

- **A linha da catraca não tem dono no formato que a baseline exigia** — o cabeçalho dizia que toda
  linha tem um item do `TODO.md` que a paga, e a contagem não tem: o dono dela é o **arquivo**. O I5
  passou a admitir a classe em vez de inventar um dono falso. Se o humano preferir outra saída, é
  decisão dele — **não bloqueia o pipeline**. Ver `tests/health-baseline.txt`, cabeçalho.
- **O multiplicador do harness de mutação** — um sensor novo custa uma vez **por mutante**, não uma
  vez. A saída ("rodar por mutante só o sensor que a mutação alcança") muda a régua do `sdd health`
  e é decisão humana. Já registrado no `TODO.md`, seção "Custo e escala".

## Riscos e não-feitos

- **A suíte está em ~7 min**, bem acima do alvo "<30 s" da D7. Dois itens do `TODO.md` cobrem a
  causa (multiplicador de mutação + alvo da D7); nenhum foi resolvido aqui, por escopo.
- **Cluster 3 do handoff de triagem (9 itens, família "asserção que falha aberta") não foi tocado**
  — é o não-feito declarado no `00-missao.md`. Cada uma falha aberta por um motivo diferente: são 9
  investigações, não um incremento.
- **Clusters 4 e 5 e o eixo de i18n seguem abertos.** O cluster 5 precisa de 4 decisões humanas.
- **Os 10 itens fechados NÃO foram apagados** — levam `RESOLVIDO por <hash>` e saem só depois do
  merge, provados por `git merge-base --is-ancestor <hash> main`. Logo a contagem continua **73**, e
  é na varredura pós-merge que a catraca vai cobrar a baseline de novo. Quem apagar tem de mover
  `todo-findings 73` no mesmo commit, ou o `sdd health` reprova — de propósito.
- **Não verificado:** o comportamento da catraca num repo-alvo (não-kit). O `sdd health` só roda no
  repo do kit por desenho, então a regra nova não tem efeito fora daqui.

## Achados fora de escopo

> Registrados no `TODO.md` do `sdd_agents`. Aqui fica só o ponteiro, para o PR conseguir citar.

- `sdd health` aborta calado quando `~/.claude/plugins/cache` não existe → `TODO.md` (Sensores que faltam)
- A checagem do `score:` do `sdd health` promete reprovar e morre calada → `TODO.md` (Sensores que faltam)
- `sdd health` morre mudo quando a suíte está vermelha — **visto ao vivo nesta sessão**, quando o
  controle do harness quebrou: só o cabeçalho e rc 1 → `TODO.md` (Sensores que faltam)
- O `moved` do `cmd_kaizen` não tem asserção, logo não pode ter mutação → `TODO.md` (Sensores que faltam)
- As linhas de exclusão do `sdd autonomy` levam uma linha em branco entre cada duas → `TODO.md` (Saída humana e cosmética)
- Sensor novo na suíte é multiplicador, não parcela → `TODO.md` (Custo e escala)
