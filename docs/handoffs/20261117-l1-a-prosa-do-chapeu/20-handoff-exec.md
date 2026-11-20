---
missao: 20261117-l1-a-prosa-do-chapeu
fase: EXEC
status: done
sessao: 5d9ebc05-bb88-4aaf-97b3-456ccb75cb9e
data: 2026-11-19 20:51
gate: "R1 (r1): tests/run-all.sh → suite green, rc=0, 0 linhas ^  FAIL; Check do R1 → 1 0; check-todo.sh --anchors TODO.md → 103 measured, 0 off target. I9: tests/run-all.sh → suite green, rc=0, 0 linhas ^  FAIL, 2181 linhas ^  ok (coordination: 192 passed, 0 failed); bash tests/check-hat.sh rc 0, 118 ok; check-templates.sh → 2 ok da frase do item M; cmp do espelho rc 0 para planner, executor, reviewer, docs e qa; check-todo.sh --check → 103 finding(s), all within 8 lines…, rc 0; --anchors → 103 measured, 0 off target; Check do I9 → 14"
---

# Handoff — EXEC — L1: a prosa do chapéu e dos docs

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

Os 9 incrementos estão `done`: os 14 achados de prosa (A a N) ganharam a frase e uma asserção cada
(13 em `tests/check-hat.sh`, 2 em `tests/check-templates.sh`), os cinco chapéus editados estão
iguais ao espelho, e os 14 itens do `TODO.md` carregam `RESOLVED by <hash>`, com os títulos
intactos e a catraca sem mudar. Suíte verde. A QA percorre a jornada no terminal (abaixo). Rodada r1 da REVIEW: o `R1` (`772540c`)
fechou o único achado, a receita de espera do revisor sem o `timeout: 600000` da chamada Bash.

## Estado do repo

- **Branch:** `fix/l1-a-prosa-do-chapeu` — 21 commits à frente da `origin/main`, nunca empurrada
- **Último commit:** o deste handoff; o do I9 é `c27e8c7` `docs(todo): RESOLVED by nos 14 itens do L1`
- **Working tree:** limpo
- **Suíte:** `tests/run-all.sh` → verde, rc 0, 0 `FAIL` (rodada destacada: no teto de 590 s do Bash ela não cabe)
- **E2E:** não há `E2E_CMD`; o kit não tem interface

## O que foi feito

- `2b01f33` — I1, itens A, B, C: o planner nomeia a base pelo `DEFAULT_BRANCH`, devolve ao relay em `OUTPUT_LANG`, e a Check de item novo aceita `RECURRED` num aberto equivalente
- `abe5808` — I2, itens D, E: o executor escreve o `20-handoff-exec.md` no incremento que zera os `pending` (e a resposta diz se escreveu); o mutante volta por `cp` + `rm`
- `b51657d` — I3, itens F, G: o revisor espera em primeiro plano sob teto abaixo do limite do Bash; sonda fora do repo por heredoc; filtro de teste que não acha nada é falha
- `781fe39` — I4, item H: a DOCS transforma lição que o próprio log chama de reincidente em linha `⛔` com texto proposto, ou escreve por que não
- `40c836b` — I5, item I: o `qa: skipped` declarado vai à confirmação do §2 nos dois caminhos
- `596627b` — I6, itens J, K, L: README sem "PRIVATE"; `failure-modes.md` acha o `sdd run` destacado com `[b]in/sdd run` e diz como esperar o fim; `finding-prs.md` só mergeia com zero threads abertos no head, com o comando ao lado
- `bc8710f` — I7, item M: as duas sementes do `TODO.md` dizem que número que muda vai no corpo, nunca no título
- `c02da26` — I8, item N: a entrada do `sdd why` no `sdd help` diz que o gate roda o `TEST_CMD` para EXEC, QA ou REVIEW
- `c27e8c7` — I9: `RESOLVED by` nos 14 itens; quatro linhas requebradas para caber em 120 colunas e 8 linhas

## Rodada r1 da REVIEW — os incrementos de conserto

- `772540c` — R1, achado #1 da r1 (MEDIUM): a seção "Two ways this session dies" do
  `agents/sdd-reviewer.md` (e o espelho) manda rodar o laço `timeout 590` numa chamada Bash com o
  parâmetro `timeout: 600000`, porque o padrão de 120 000 ms a manda para segundo plano aos 120 s;
  o probe novo de `tests/check-hat.sh` (`the reviewer runs the wait loop in a Bash call whose own
  timeout is raised to 600000 ms`) foi vermelho antes da frase. R de prosa: sem linha a degradar; o
  parágrafo foi relido inteiro, e a única repetição da receita fora do chapéu é o corpo do item F do
  `TODO.md`, que é registro do achado e fica como está. Nesta sessão a suíte passou dos 600 s numa
  chamada direta e foi para segundo plano no teto; o laço da receita, numa chamada com o mesmo
  `timeout: 600000`, leu o `rc=0` em primeiro plano.

Para a r2: o delta é `517eeac..772540c` (três arquivos), mais este handoff e o checkpoint.

## Artefatos

| Arquivo | O que contém |
|---|---|
| `docs/handoffs/20261117-l1-a-prosa-do-chapeu/checkpoint.md` | tabela, 9 linhas `done` com hash |
| `docs/handoffs/20261117-l1-a-prosa-do-chapeu/checkpoint-notas.md` | os Reds de cada incremento e as âncoras re-medidas |
| `agents/sdd-{planner,executor,reviewer,docs,qa}.md` e o espelho `.claude/agents/` | as frases dos itens A a I |
| `README.md`, `docs/failure-modes.md`, `docs/finding-prs.md` | itens J, K, L |
| `templates/todo.md`, `templates/todo.pt-BR.md` | item M |
| `bin/sdd` (só o texto de ajuda do `sdd why` em `cmd_help`) | item N |
| `tests/check-hat.sh`, `tests/check-templates.sh` | as 15 asserções novas |

## Boot da próxima fase

QA (`sdd-qa`). O kit não tem interface: a sessão percorre a jornada no terminal e descreve o que viu
no `gate:` do `30-handoff-qa.md`. `qa:` está vazio no `00-missao.md`. O que no diff chega ao usuário
do kit: o texto do `sdd help`, o README e os dois docs; os chapéus chegam às sessões das fases.

Jornada (a do `01-plano.md`, "Verificação end-to-end"), na raiz do worktree:

1. `./bin/sdd help` e ler a entrada do `sdd why` (diz que o gate roda o `TEST_CMD` para EXEC, QA ou REVIEW).
2. `./bin/sdd install` e ler `agent sdd-<nome>.md identical` para os oito chapéus.
3. Abrir o `README.md` na linha do `git clone`: sem "PRIVATE".
4. Ler, no `docs/failure-modes.md`, a seção do `sdd run` que sumiu, e rodar o
   `pgrep -af '[b]in/sdd run'` que ela ensina (não casa com a própria shell).
5. Rodar a consulta de threads do `docs/finding-prs.md` contra um PR real do repo e ler `unresolved:`.

Use `./bin/sdd`, nunca o `sdd` do PATH: o do PATH é o checkout principal, com os chapéus de antes
(pendência 6 do `00-missao.md`: `agent … stale` é esperado até o merge).

## Pendências / Decisions for a Human

- As quatro escolhas da decisão 5 (J, K, E, H seguiram a leitura mais estreita) — o corpo do PR as lista para o aceite do dono.
- O chore de depois do merge: apagar os 14 itens provados por `git merge-base --is-ancestor`, descer `todo-findings` e sincronizar o espelho de issues. O PR mergeia por **merge commit**, nunca squash.
- O carimbo de mutação não roda nesta missão: o `gate_PR` sairá com rc 2 pedindo `./bin/sdd health`, que se lê como "PR pronto para revisão".

## Riscos e não-feitos

- A contagem do Check do I9 (`14`) é efêmera por natureza: o chore apaga os itens.
- A suíte inteira não cabe nos 590 s do Bash nesta máquina; rodada destacada, esperada pelo `rc=` no log. Quem a rodar de dentro de uma sessão precisa do mesmo laço.
- Nenhum mutante, sensor ou gate novo (fora de escopo, decisão 1). As asserções leem prosa: provam que a frase está lá, não que a sessão a obedece.

## Achados fora de escopo

- Nenhum achado novo nesta sessão.
