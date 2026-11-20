---
missao: 20261119-l1b-a-rodada-delta
fase: QA
status: done
sessao: 0b85af2e (QA-20261120-113137-0b85af2e.stream.jsonl)
data: 2026-11-20 11:52
gate: "sem interface (E2E_CMD e APP_URL vazios); jornada no terminal — `./bin/sdd review-base 20261119-l1b-a-rodada-delta` → `full — no earlier round` rc 0; num clone descartável em /tmp com um 40-review-r1.md de `reviewed_head: 808c95c…` commitado → `base=808c95ce… — 40-review-r1.md reviewed this head; its findings are the open ones` rc 0, e o mesmo depois de um commit fora da pasta da missão; com `reviewed_head: deadbeefdeadbeef` → `full — the reviewed_head: of 40-review-r1.md is no commit ('deadbeefdeadbeef')`; sem missão → `error: missing mission name` rc 1; missão inexistente → `error: mission 'nao-existe' not found` rc 1; `sdd help` lista o verbo (linha 41). TEST_CMD `tests/run-all.sh` → rc 0, `suite green`, 0 linhas `^  FAIL`, `anchors: all 914 mutants still apply`; no log: review-base 5 ok, gate_REVIEW reviewed_head 5 ok, prompt delta 1, prompt da 1ª rodada 1, chapéu fora do delta 1, ato review do worker 1"
---

# Handoff — QA — L1b: a rodada delta

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

Caminho sem interface: percorri a jornada no terminal (6 comandos do verbo `sdd review-base`, num
clone descartável para os mundos com rodada anterior) e rodei a suíte inteira (rc 0, 0 FAIL).
0 achados, 0 specs, 0 incrementos `F<n>`, 0 decisões para o humano. A REVIEW r1 é a próxima fase.

## Estado do repo

- **Branch:** `feat/l1b-a-rodada-delta`, no worktree `sdd_agents-lote-aceleracao`
- **Último commit antes deste handoff:** `808c95c` `chore(checkpoint): I5 done (7f7e32f) — a linha da tabela`
- **Working tree:** limpo antes do commit deste handoff
- **Suíte:** `tests/run-all.sh` → verde (`suite green`, rc 0, 0 `^  FAIL`, 914 mutantes aplicam)
- **E2E:** não se aplica (`E2E_CMD` vazio; o kit é CLI)

## O que foi feito

- Jornada do `sdd review-base`, no terminal:
  - missão real, sem rodada → `full — no earlier round` (rc 0);
  - clone em `/tmp/qa-l1b` (já apagado), `40-review-r1.md` do template com `reviewed_head:` = HEAD,
    commitado → `base=<sha> — 40-review-r1.md reviewed this head; its findings are the open ones`;
  - commit fora da pasta da missão (`README.md`) → continua `base=<o mesmo sha>`, como deve: o delta
    da r2 é o que mudou desde o head revisado;
  - `reviewed_head:` que não é commit → `full — … is no commit ('deadbeefdeadbeef')`: cai para a
    revisão inteira e diz por quê;
  - sem argumento e com missão inexistente → rc 1 com mensagem nomeada.
- Suíte inteira com as asserções da jornada contadas no log (os números estão no `gate:`).
- Nenhum código de produção tocado, nenhum spec novo (não houve achado).

## Artefatos

| Arquivo | O que contém |
|---|---|
| `docs/handoffs/20261119-l1b-a-rodada-delta/30-handoff-qa.md` | este handoff |

## Boot da próxima fase

Próxima fase: **REVIEW r1**. O que a QA viu:

- `./bin/sdd review-base 20261119-l1b-a-rodada-delta` responde `full — no earlier round`, então a r1
  é **inteira**, como o `20-handoff-exec.md` antecipa. Grave o `reviewed_head:` (o `HEAD` que você
  revisou) no `40-review-r1.md`, ou a r2 também sai inteira.
- Os três desfechos do juízo (`full` sem rodada, `base=` com rodada válida, `full` com head que não é
  commit) foram vistos ponta a ponta; o caminho de um `reviewed_head:` que é commit mas **não é
  ancestral** do HEAD (rebase) não foi percorrido à mão nesta QA — vale olhar o ramo no
  `review_base_line` e o probe correspondente no `tests/check-gates.sh`.
- A mensagem de missão inexistente do verbo novo sugere `sdd status <mission> --no-gates`; é a
  mensagem comum do runner, não um defeito do delta.

## Pendências / Decisions for a Human

- Nenhuma.

## Riscos e não-feitos

- Não abri uma sessão REVIEW real com o prompt novo (custaria uma sessão opus); o prompt é coberto
  pelas asserções de `check-dry-run.sh` e `check-gates.sh` contadas no log da suíte.
- O ato `review` do `commands/sdd-worker.md` só foi verificado pelo sensor (`check-worker.sh`), não
  numa campanha real.
- O catálogo de mutação inteiro não rodou (é do `sdd health`); só a metade `--anchors` da suíte.

## Achados fora de escopo

- Nenhum.
