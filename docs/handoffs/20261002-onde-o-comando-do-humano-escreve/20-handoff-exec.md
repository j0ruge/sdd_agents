---
missao: 20261002-onde-o-comando-do-humano-escreve
fase: EXEC
status: done
sessao: dea94cc3-2442-49ae-abd9-9b8234a3a57e
data: 2026-10-02 16:55
gate: "tests/run-all.sh → rc 0, 'suite green' (1690 linhas '  ok ', 0 FAIL; coordination: 187 passed, 0 failed; anchors: all 541 mutants still apply and leave valid code); checkpoint I1–I10 done, cada Commit um sha no git log; check-todo: '87 finding(s), all within 8 lines, carrying anchor + date, every anchor on target'"
---

# Handoff — EXEC — Onde o comando do humano escreve

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

Os 10 incrementos estão `done`, cada um com Red medido e a suíte verde. O approve entra na branch
declarada e commita o diretório da missão. O close sem JIRA confere o PR e volta à base. Nenhum
escritor atravessa symlink, a nota de intervenção não deixa temporário, e a suíte tem prazo por passo
(dentro de mutante o estouro dá rc 124 = inconclusivo). Os dois sensores de ambiente armam o próprio veneno.
O `TODO.md` marca os 8 itens com `RESOLVED by`, e a catraca foi de 86 para 87. Próximo: QA (ou REVIEW, conforme o runner), depois a DOCS com a lista de drift do plano.

## Estado do repo

- **Branch:** `feat/onde-o-comando-do-humano-escreve`, só local (nunca empurrada; o push é da fase PR)
- **Último commit:** o commit deste handoff, sobre `41d8837` `chore(todo): RESOLVED by nos oito itens…`
- **Working tree:** limpo depois do commit deste handoff
- **Suíte:** `tests/run-all.sh` → verde (rc 0, ~300 s; 1690 asserções `ok`, 541 mutantes com âncora válida)
- **E2E:** não se aplica (o kit não tem `E2E_CMD`)

## O que foi feito

- `4815fe0` — I1 (#186): o mundo da ida e volta do `check-autonomy.sh` roda sob o rótulo REVIEW que o próprio sensor arma, e um piso prova que o veneno está armado
- `d0a6aa4` — I2 (#157): o probe de sinal do `check-coordination.sh` nasce com SIGINT ignorado e o filho o recebe em SIG_DFL (`preexec_fn`)
- `813f808` — I3 (#193): `checkpoint_note_intervention` cria o `mktemp` só no ramo do awk, e o ramo de `checkpoint-notas.md` escreve mesmo com `TMPDIR` inacessível
- `46919f6` — I4 (#182): o `sdd close` sem JIRA confere o PR (recusa o que não está MERGED) e chama o `close_return_home`
- `ce1d2ed` — I5 (#81): o `frontmatter_write` recusa symlink (`die`), avisa quando o `chmod --reference` falha e lê o valor por `ENVIRON`
- `e303e4f` — I6 (#173): o `sdd install` nunca escreve através de agente ligado, link quebrado incluído (`warn`, rc 0)
- `a64a69c` — I7 (#156): o approve chama o `ensure_mission_branch` depois do `y`, commita o diretório da missão mais o arquivo do `adr:`, recusa branch com outro plano e, com `branch:` placeholder, avisa e fica
- `a3d3996` — I8 (#112, parte 1): o `run()` do `run-all.sh` recusa passo sem prazo; o estouro é vermelho nomeado e a suíte segue; o Ctrl-C continua parando
- `8449ab8` — I9 (#112, parte 2): sob `SDD_MUTANT` o estouro sai com 124, e o catálogo (`rc_verdict`) o lê como inconclusivo, nunca como pego
- `41d8837` — I10: `RESOLVED by` nos 8 itens do `TODO.md`, o achado novo do `adr_declare` e a catraca de 86 para 87

## Artefatos

| Arquivo | O que contém |
|---|---|
| `docs/handoffs/20261002-onde-o-comando-do-humano-escreve/checkpoint.md` | tabela I1–I10, todas `done` com sha |
| `docs/handoffs/20261002-onde-o-comando-do-humano-escreve/checkpoint-notas.md` | uma nota por incremento, com o Red medido e as decisões |
| `TODO.md` | 8 itens com `RESOLVED by` e um achado novo no fim da seção aberta |
| `tests/health-baseline.txt` | `todo-findings 87` |

## Boot da próxima fase

- **Nada é visível para um usuário de browser.** A superfície são as portas de CLI: `sdd approve`,
  `sdd close`, `sdd install --force` e a nota `- intervention:` de `--phase`/`retry`/`--budget-override`,
  mais a saída de `tests/run-all.sh` (`timed out after N s`) e o veredito `TIMED-OUT` do catálogo.
- **As jornadas tocadas**, todas reproduzíveis num repo de rascunho com `SDD_STATE_DIR` isolado (os
  mundos estão nos probes nomeados no `checkpoint.md`):
  1. approve na `main` com `branch: feat/x` → o HEAD termina em `feat/x` e o commit leva `00`/`01`/`checkpoint*`;
  2. close com `JIRA_ENABLED=false` em `feat/x` → volta à base com ff, e recusa PR aberto;
  3. `00-missao.md` como symlink → o approve morre sem escrever; agente ligado → o `install --force` avisa e não toca no destino;
  4. `bash -c 'tests/check-coordination.sh & wait $!'` e `GIT_REFLOG_ACTION=sdd:REVIEW:x bash tests/check-autonomy.sh` ficam verdes.
- **Ambiente:** nenhum app. `tests/run-all.sh` é o `TEST_CMD` (~5 min em primeiro plano). Nunca o rode como
  tarefa de fundo do harness.
- A DOCS tem a lista de drift pronta no `01-plano.md`, § "Para a fase DOCS".

## Pendências / Decisions for a Human

- `./bin/sdd health` **uma vez**, depois do último commit de código **e** da última rodada de revisão
  do PR, antes do `gate_PR`. É o carimbo: mutantes novos 541 de 541 esperados. A DOCS pode tocar
  `templates/` (que está na chave do carimbo), por isso o health vem **depois** dela.
- O merge do PR é humano. O chore pós-merge apaga os 8 itens `RESOLVED by` e sincroniza as issues.

## Riscos e não-feitos

- **O catálogo de mutação inteiro não rodou nesta fase.** Cada mutante novo foi provado pela receita
  isolada (aplicou e o sensor morreu), e o `--anchors` está verde com 541. O `N de N` sai do `sdd health`.
- **Prazos de passo calibrados nesta máquina** (8 vezes o ocioso, piso de 60 s). Sob carga pesada, um
  vermelho falso é nomeado e, dentro de mutante, inconclusivo, nunca um ponto falso.
- O `--foreground` do `timeout` pode deixar descendentes vivos num estouro: limite declarado no comentário do `run()`.
- O `ENVIRON` do `frontmatter_write` não tem mundo de probe (nenhum chamador produz `\`): limite declarado.
- `docs/pipeline.md:584` ainda diz "nothing to close" para o close sem JIRA. Fica para a DOCS.

## Achados fora de escopo

- `adr_declare` engole a falha do `chmod --reference` (`bin/sdd:7003` e `:7022`) → `TODO.md`, seção
  `<!-- sdd:open -->` › "Sem seção — chegaram depois da última classificação" (catraca 87)
