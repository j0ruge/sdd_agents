---
missao: 20261121-l4-preflight-health-e-sensores
fase: EXEC
status: done
sessao: dc0b246a-0178-42d3-a2c7-fe3331537632
data: 2026-11-22 02:57
gate: "R1 da r1 em 5369a53: `tests/run-all.sh` → `suite green`, rc 0, 2336 linhas `^  ok    `, `grep -cE '^  FAIL'` → 0, `anchors: all 986 mutants still apply and leave valid code`; Check R1 → `1 1 1 1 1 1`; `tests/check-mutation.sh --only KAIZEN_hat_guard_check_dropped check-kaizen.sh` → `check-kaizen.sh dies (rc 1)`; `bash tests/check-todo.sh --anchors TODO.md` → `anchors: 91 measured, 0 off target`. Antes (I13): 2331 ok, 985 mutantes"
---

# Handoff — EXEC — L4: preflight, health e sensores

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

Os 13 incrementos estão `done`: os 15 itens do lote fechados por 12 commits de código e marcados
`RESOLVED by` no `TODO.md` (I13, `54a8ffe`). A suíte está verde (rc 0, 0 FAIL), com 31 mutantes
novos (954 → 985), todos aplicando. Não há interface de produto: a QA é de CLI (`./bin/sdd
preflight`, `sdd run`/`retry` param na skill não coberta, `sdd kaizen` com guarda do chapéu).
Depois da r1 da REVIEW, o `R1` (`5369a53`) fechou os seis LOW do lote. A suíte segue verde, com 986 mutantes.

## Estado do repo

- **Branch:** `fix/l4-preflight-health-e-sensores`, só local (o push é da fase PR)
- **Último commit:** `5369a53` `fix(preflight): R1 da r1 do L4, seis LOW num lote`, mais o commit deste handoff e o do checkpoint
- **Working tree:** limpo
- **Suíte:** `tests/run-all.sh` → verde, 2336 asserções `ok`, rc 0 (log em `/tmp/l4-r1-post2.log`, efêmero)
- **E2E:** não há `E2E_CMD` (o kit é bash + markdown)

## O que foi feito

- `81f6ec6` — I1, itens 11 e 12: o preflight sem o ruído de pipe com a `READ_EXTRA` cheia, e a árvore suja com os caminhos (e o `.git/info/exclude` só quando todos são `??`)
- `641529b` — I2, item 6: a sonda do `Bash` dá `ok` pelo `tool_result` que carrega o marcador, nunca pela resposta; "Bash in the tool list" só sobre uma linha `init`
- `3612cb9` — I3, item 15: uma linha por evento de hook da sonda (contagem, exit codes, bytes), aviso pelo nome no hook que falha, e `_fail` na skill de uma fase ausente do `.skills` da `init`
- `9ef4cdc` — I4, item 1: o preflight mede a forma do `TODO_FILE` sozinho (`check-todo.sh --check --allow-empty`), só avisa, e nomeia o opt-in só quando o `TEST_CMD` não o carrega
- `6ca6f20` — I5, item 10: o preâmbulo do `TODO_FILE` comparado com o template de hoje e com cada revisão dele no git do kit (ok, desatualizado com revisão e diff, ou de autor); kit sem git cala
- `95598f4` — I6, item 7: `sdd run` e `sdd retry` param antes da sessão na skill achada e não coberta ou na instalação quebrada, com a entrada da `READ_EXTRA` a acrescentar; o `--dry-run` só avisa; `tests/isolate-git.sh` exporta um `SDD_SKILLS_ROOT` vazio
- `dfaeeb4` — I7, itens 3 e 13: o preflight nomeia por pid e executável (nunca argumentos) o processo que o `TEST_CMD` deixou vivo, e avisa do lint pulado sem o `shellcheck`; verbete novo no `docs/failure-modes.md`. A outra metade do item 13 (os 4 avisos) já estava em `3f96448`
- `a3e4c86` — I8, itens 2 e 14: aviso uma vez por processo do clone do kit fora da branch padrão do remoto dele ou atrás do upstream buscado; no worktree ligado sem espelho dos chapéus, a mensagem nomeia o `sdd link-agents`
- `261acc8` — I9, item 4: o `cmd_kaizen` arma e lê a guarda do chapéu nas duas sessões (primeira e retry) e para em `hat-crossed` depois da linha de sessão; o chapéu do juiz nomeia a base
- `21a9af7` — I10, item 5: regra 7 do `check-checkpoint.sh`, que recusa `atualizado:` posterior ao relógio no `--check` e na varredura
- `07fc265` — I11, item 8: a sonda de interrupção do `check-health.sh` lê o grupo depois que o passo lento começou, com controle negativo
- `46da749` — I12, item 9: regra 8 do `check-todo.sh`: sob `--baseline`, o `PR #N` solto de um item novo só passa citado num assunto de commit do histórico local; os dois templates dizem "deste repositório"
- `54a8ffe` — I13: `RESOLVED by <hash>` nos 15 itens; nos três que já estavam no teto de 8 linhas (7, 8 e 9) a direção foi encurtada, sem linha nova e sem mudar título

## Rodada r1 da REVIEW — `R1`

O lote dos achados #1–#6 da `40-review-r1.md`, num commit. Cada conserto tem um probe que a
sabotagem deixou vermelho (as notas têm a lista):

- `5369a53` — #1: o `git status` que falha no `cmd_preflight` tem `_fail` próprio ("git status failed in …"), e nenhum caminho nem o `info/exclude` é nomeado. O sentinela `?? (…)` saiu
- `5369a53` — #2: o jq que falha sobre o stream da sonda do `Bash` dá `probe_ran=unread`, com o motivo "the stream of the Bash probe could not be read", e o modelo não é mais culpado por repetir o marcador
- `5369a53` — #3: os mundos `wt` e `det` do `kit_stale_check` têm testemunha (`--absolute-git-dir` ≠ `--git-common-dir`; HEAD sem `symbolic-ref`) antes de o silêncio ser lido
- `5369a53` — #4: as duas contagens do bloco de hooks são lidas antes da subtração (`the hooks block reads both failure counts it subtracts`), e a subtração não pula mais a asserção
- `5369a53` — #5: probe CRLF na regra 7 do `check-checkpoint.sh` (`PROBE_FLOOR` 460 → 461, `RULE_FLOOR` 11 → 12)
- `5369a53` — #6: `mut_KAIZEN_hat_guard_check_dropped` (catálogo 985 → 986), pego pelo `check-kaizen.sh`

Limite declarado nas notas: tirar o default `${fo_…:-0}` da subtração não tem probe próprio, porque
no único mundo em que ele pesa a asserção de leitura já fica vermelha. As 21 âncoras do `TODO.md`
que as linhas novas deslocaram foram remapeadas pelo diff.

## Artefatos

| Arquivo | O que contém |
|---|---|
| `docs/handoffs/20261121-l4-preflight-health-e-sensores/checkpoint.md` | a tabela, 13 linhas `done` |
| `docs/handoffs/20261121-l4-preflight-health-e-sensores/checkpoint-notas.md` | uma nota por incremento, com os mutantes pegos e a sabotagem à mão |
| `TODO.md` | os 15 itens com `RESOLVED by`; catraca intocada (91) |

## Boot da próxima fase

**Depois do `R1`, a próxima fase é a REVIEW r2**, sobre o delta desde o `reviewed_head:` da r1. O
diff de código é o `5369a53` (o `bin/sdd` no `cmd_preflight`, três sensores e o catálogo). Nada
visível ao usuário mudou além de duas mensagens novas do `sdd preflight`, que só aparecem quando o
`git status` ou o jq falham. O roteiro de QA abaixo vale como foi escrito para o I13.

QA de CLI, sem navegador: o kit não tem interface de produto. Rode no worktree da missão, com o
`./bin/sdd` do worktree (o `sdd` do PATH é o checkout principal, o runner velho):

1. `env -u CLAUDECODE ./bin/sdd preflight` (roda o `TEST_CMD` inteiro, 12 a 17 min, mais duas
   sessões haiku). A saída tem de trazer: a linha dos hooks por evento, a forma do `TODO_FILE`
   (`ok`), o preâmbulo (linha neutra: o do kit é de autor), a sonda do `Bash` verde pelo
   `tool_result`, e nenhum `printf: erro de escrita`.
2. Os mundos que o I6 para (skill não coberta, instalação de plugin sem a skill) se reproduzem pelos
   probes de `tests/check-preflight.sh`; não rode `sdd run` real contra o próprio kit a partir do
   checkout principal (regra do `CLAUDE.md`, §6 da anatomia).
3. Verificação end-to-end do `01-plano.md` (itens 3 a 6): já medida aqui, valores no `gate:` acima
   e no censo: `if …_escalation "$phase"` 13 → 15 e `hat_guard_check "` 4 → 6.

## Pendências / Decisions for a Human

- O `CLAUDE.md` ainda diz 13 portas de escalada no censo (agora são 15) e a rule da anatomia não
  cita a guarda do juiz: são as linhas `⛔` da fase DOCS, por decisão do plano (o chapéu não edita
  `.claude/rules/**`).
- Pendência 4 do `00-missao.md`: o alvo sem a entrada do `codereview` na `READ_EXTRA` para no
  primeiro `sdd run` depois do merge, o que é o comportamento desenhado (decisão 3). A mensagem
  traz a linha a acrescentar.

## Riscos e não-feitos

- O catálogo de mutação inteiro (`./bin/sdd health`) não rodou: cada mutante novo foi provado por
  `--only` contra o seu sensor (notas do checkpoint), e o `--anchors` diz que os 985 aplicam. O
  carimbo é do `sdd health`, depois do último commit de código e da revisão.
- O texto de três itens do `TODO.md` (7, 8 e 9) foi encurtado para caber o token no teto; o chore
  depois do merge os apaga.
- Não-feitos por decisão do plano: a parada da skill no `sdd close` e no `sdd kaizen`, a duração
  dos hooks, `issue #N` de outro repositório, `tests/health-baseline.txt`.

## Achados fora de escopo

- Nenhum novo nesta sessão.
