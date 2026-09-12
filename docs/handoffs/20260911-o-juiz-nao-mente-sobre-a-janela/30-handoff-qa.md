---
missao: 20260911-o-juiz-nao-mente-sobre-a-janela
fase: QA
status: done
sessao: headless (sdd run --phase QA)
data: 2026-09-12 09:51
gate: |
  Projeto SEM interface (E2E_CMD="" e sem APP_URL): a jornada é a CLI e eu a andei nesta sessão.
  1) `tests/run-all.sh` → `suite green` (14 sensores, sem FAIL).
  2) `bash tests/check-todo.sh` → `ok    95 finding(s), all within 8 lines and carrying anchor + date`.
  3) `./bin/sdd kaizen --series` sobre o ledger REAL → JSON válido, `guard` publica os campos novos:
     `harness: ["2.1.269"]`, `window_missions_stranded: 0`, `window_broken: false`, `sufficient: false`
     com `why: ["floor"]` (1 missão sobre o sha corrente, piso 3) — recusa correta.
  4) Guarda de harness misturado exercitada à mão em ledger de FIXTURE (`SDD_STATE_DIR` num
     `mktemp -d`, `head -280` do ledger real + 1 linha `event:"session"` com `harness:"9.9.9"`):
     antes `sufficient: true, why: [], harness: ["2.1.263"]`; depois
     `sufficient: false, why: ["harness_mixed"], harness: ["2.1.263","9.9.9"]`. Métrica 3 da missão
     confirmada por comando, não por rótulo.
  5) Ledger real limpo: `grep -c '"repo":"/tmp' ~/.sdd/autonomy-log.jsonl` → `0` (métrica 2).
     Quarto evento vivo na população: `jq .event | sort | uniq -c` → 273 session, 13 blocked, 2 gate_pass.
  6) `sdd autonomy --by-mission` sobre o ledger real → 12 missões, `reopened` e o laço de revisão
     publicados por missão, escaladas listadas, exclusões nomeadas (meta 5, outro repo 125).
  7) Os 6 Checks do checkpoint re-executados nesta sessão: `differential` 4, `guard: two harness` 1,
     `reopened` 1, `close writes` 3, `95 finding(s)` 1, `"repo":"/tmp"` 0 — todos satisfeitos.
  8) Contrato conferido contra a saída: `docs/pipeline.md:790,834,1053-1065` documenta
     `event:"close"`, `harness`, `why`/`harness_mixed`, `window_missions_stranded` e `window_broken`
     exatamente com a forma que a CLI imprime.
  9) Carimbo de mutação INTACTO: a chave recomputada à mão sobre `bin tests templates config` dá
     `17591a682fecf870219142b1ee8438d5`, igual ao `.sdd/logs/mutation-stamp` — o `gate_PR` continua
     satisfazível, e esta fase não tocou nenhum dos quatro diretórios.
  Nenhum achado confirmado ⇒ nenhuma spec nova e nenhum incremento `F<n>`.
---

# Handoff — QA — o juiz não mente sobre a janela

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

4 jornadas de CLI andadas à mão (série do juiz, guarda de harness, ledger/`--by-mission`, catraca
do backlog) + os 6 Checks do checkpoint re-executados: **0 achados confirmados**, logo 0 spec nova
e 0 incremento `F<n>`. A suíte está verde, o ledger real está limpo (`/tmp` → 0) e a guarda de
harness misturado foi reproduzida em fixture: `sufficient: true` → `false` com `why: ["harness_mixed"]`.
O carimbo de mutação continua válido (`17591a68…`) — **a próxima fase não pode tocar
`bin/ tests/ templates/ config/` sem re-carimbar** (20–50 min). Próxima fase: REVIEW.

## Estado do repo

- **Branch:** `feat/o-juiz-nao-mente-sobre-a-janela` — 21 commits à frente de `main`, sem push
- **Último commit:** `267d269` `fix(checkpoint): a coluna Commit volta a ser um sha só, que é o que o gate parseia`
- **Working tree:** limpo na entrada desta sessão; sai com este handoff + a nota do checkpoint
- **Suíte:** `tests/run-all.sh` → **verde** (`suite green`, 14 sensores)
- **E2E:** `E2E_CMD=""` — o projeto não tem interface; a jornada é a CLI e está no `gate:` acima

## O que foi feito

Esta fase **não produz código** (é a regra: quem acha não conserta). O que ela produziu foi
evidência e artefato:

- `—` — 4 jornadas de CLI andadas e registradas no `gate:`, incluindo a reprodução em fixture da
  guarda de harness misturado, que é a **métrica 3** da missão
- `<este commit>` — `30-handoff-qa.md` + uma linha em `checkpoint-notas.md`

## Artefatos

| Arquivo | O que contém |
|---|---|
| `docs/handoffs/20260911-o-juiz-nao-mente-sobre-a-janela/30-handoff-qa.md` | este handoff; o `gate:` é a evidência da jornada (projeto sem interface) |
| `docs/handoffs/20260911-o-juiz-nao-mente-sobre-a-janela/checkpoint-notas.md` | nota de QA (append-only) |
| `checkpoint.md` | **inalterado** — nenhum `F<n>`, porque não houve bug sanável |

## Boot da próxima fase

A próxima fase é **REVIEW**. O que ela precisa saber do que a QA viu:

1. **As três métricas da missão estão confirmadas por comando**, e os comandos estão no `gate:`
   deste arquivo. O revisor não precisa re-andar as jornadas para saber que andaram — mas precisa
   julgar o **desenho** das guardas novas, que a QA não julga.
2. **Não rode `sdd kaizen` de verdade** (sem `--series`) nesta branch: o piso é 3 e ele commita na
   branch corrente. Para exercitar a guarda, use `SDD_STATE_DIR` apontando para um `mktemp -d` com
   uma cópia do ledger — foi o que esta sessão fez, e a receita está no `gate:`, item 4.
3. **`./bin/sdd autonomy --series` NÃO EXISTE** (`error: unknown autonomy option: --series`). A
   série é `./bin/sdd kaizen --series`. A seção "Boot da próxima fase" do `20-handoff-exec.md`
   escreve o comando errado — ver *Riscos e não-feitos*.
4. **O carimbo de mutação está válido e é frágil.** Qualquer edição em `bin/`, `tests/`,
   `templates/` ou `config/` — incluindo registrar achado novo no `TODO.md`, que move
   `tests/health-baseline.txt` — mata o carimbo e torna o `gate_PR` insatisfazível até um
   `./bin/sdd health` de 20–50 min. Achado de prosa do revisor vai para o `TODO_FILE` **sabendo
   deste preço**.
5. Comandos por onde começar:

```bash
cd /home/joruge/repos/sdd_agents
git log --oneline main..HEAD            # 21 commits
tests/run-all.sh                        # ~45 s, verde
./bin/sdd kaizen --series | jq .guard    # os campos novos da guarda
grep -c '"repo":"/tmp' ~/.sdd/autonomy-log.jsonl   # 0
```

## Pendências / Decisions for a Human

As duas pendências continuam sendo as do `00-missao.md`, intocadas por esta fase e **não**
bloqueantes:

1. **`BUDGET_MISSION_USD` calibrado abaixo do custo real** — 3 escaladas `budget-exhausted` em 3
   missões da janela 4. Subir o teto ou aceitar a parada como ritual é decisão humana
   (`05-verdict.md`, pendência 1).
2. **Prioridade: o juiz ou o dólar?** — esta missão conserta o instrumento; o laço de revisão a
   66% é o maior desperdício medido e está fora de escopo (`05-verdict.md`, pendência 2).

Nenhum bug foi registrado nesta fase, logo não há bug marcado `Closable by: human`.

## Riscos e não-feitos

- **`20-handoff-exec.md` manda rodar `./bin/sdd autonomy --series`, que não existe.** Custa um
  comando morto a quem seguir o boot. Não virou `F<n>` (não é código, não tem sensor a criar) nem
  entrada no `TODO.md` (mataria o carimbo de mutação por um erro de digitação num handoff já
  consumido); fica corrigido **aqui**, que é o handoff que a próxima fase lê: o comando é
  `./bin/sdd kaizen --series`.
- **`sdd close` e `sdd retry` (I4) não foram exercitados de verdade** — `sdd close` compra uma
  sessão paga e `sdd retry` precisa de uma fase reprovada. A evidência deles é a dos probes
  (`check-autonomy.sh`: `close writes` × 3, verdes) e não uma corrida real. O ledger real ainda
  não tem nenhuma linha `event:"close"` — 273 `session`, 13 `blocked`, 2 `gate_pass`.
- **`window_broken` só foi visto `true` em recorte histórico** (`head -280`, janela 4: 3 missões
  encalhadas). No ledger vivo ele é `false`, que é a resposta correta hoje, mas é o ramo trivial.
- **`sdd health` não foi rodado nesta fase, de propósito** — 20–50 min e o carimbo já está válido.
  A QA verificou o carimbo recomputando a chave à mão, o que é o mesmo que o `gate_PR` faz.
- **A dívida que o I6 moveu para o cabeçalho dos sensores não foi re-lida item a item.** A QA
  confirmou o número (95) e a forma; se a prosa de cada cabeçalho diz o que o item dizia é
  julgamento de revisão, não de jornada.

## Achados fora de escopo

> Dois destinos, e a diferença já custou uma `main` vermelha (`2d28d13`).
>
> **Achado sobre o repo-alvo:** registrado no `TODO.md` dele; aqui fica só o ponteiro, para o PR
> conseguir citar.
>
> **Achado sobre o kit** (runner, agente, template), numa missão cujo repo NÃO é o kit: a sessão
> não escreve, não commita e não entra no repositório do kit. A linha **completa** do achado mora
> aqui, marcada `kit:`, e quem a transporta é um humano ou a triagem do `sdd kaizen`. Ponteiro para
> um arquivo que ninguém escreveu é achado perdido.
>
> - kit: <o quê> — <arquivo:linha do kit> — <por que importa>

Nenhum. O repo desta missão **é** o kit, e o único desvio que a QA achou (o comando errado no
handoff de EXEC) está em *Riscos e não-feitos*, com a correção escrita no lugar que a próxima fase
lê.
