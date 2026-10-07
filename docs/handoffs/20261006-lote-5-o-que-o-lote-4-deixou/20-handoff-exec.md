---
missao: 20261006-lote-5-o-que-o-lote-4-deixou
fase: EXEC
status: done
sessao: 773a289e-20ea-4203-817a-084658e86831
data: 2026-10-06 14:03
gate: "tests/run-all.sh → rc 0, 'suite green' (1897 linhas '  ok ', 0 FAIL, 404 s com TMPDIR=/tmp/l5pr/s4, depois da 3ª rodada dos bots do PR #237); anchors: all 668 mutants still apply and leave valid code; checkpoint I1–I12 done, cada Commit um sha no git log; check-todo: '14 finding(s), all within 8 lines, carrying anchor + date, every anchor on target' = todo-findings 14, 12 com RESOLVED by"
---

# Handoff — EXEC — Lote 5: o que o lote 4 deixou

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

Os 12 incrementos estão `done`, executados de forma interativa no worktree ligado
`~/repos/sdd_agents-lote-5` (ADR 0016 §2), cada um com o Check do plano medido vermelho antes e
verde depois. As 12 issues (#223–#230, #232–#235) carregam `RESOLVED by` no `TODO.md`; a 13ª (o
`sdd kaizen` no checkout principal, #236) fica aberta, decisão 11b. Comportamento novo: a suíte, o
catálogo e todo sensor limpam o `GIT_DIR` de quem chama (I1); a linha curta da tabela é recusada
pelo nome (I2); `deferred` sem `## Decis…` no bug barra a QA (I4); o relatório da base exige blob de
checkpoint da missão (I5, ADR 0016 §1); a guarda do kit vê o kit sujo editado de novo e diz o que
mudou (I6); a nota `intervention:` só existe na volta que abre sessão, nas três portas (I7); a
página do `sdd status` cala sem `session` local e o `ok` do `note-manual` diz o que fez (I8); o
supervisor nomeia quem segura o checkout e o `turn_rule` avisa toda fase (I9); o `/sdd-plan` no kit
abre um worktree ligado (I10). ADR 0016 aceita, 0015 ganha `Amended by: 0016`. Revisão final:
3 consertos, 4 minors decididos pelo humano. PR #237: os bots deram 6 achados, consertados numa
leva, e a leva achou a sandbox do catálogo sem o `.gitignore`; a 2ª e a 3ª rodadas do Codex, 1 P2 cada
(bit de execução e alvo do symlink na árvore do kit). Catálogo 619 → 668, todos aplicam.
Catraca 14 na branch (N = 1, a #238) → 2 depois do chore. Próximo: `./bin/sdd health` UMA vez no
worktree (com o `mutation-killers.tsv` copiado), merge pelo humano.

## Estado do repo

- **Branch:** `fix/lote-5-o-que-o-lote-4-deixou`, só local, no worktree `~/repos/sdd_agents-lote-5`
  (nunca empurrada; base `origin/main` = `89df2e5`)
- **Último commit:** o registro da 3ª rodada dos bots do PR #237, sobre `a55b53c`
- **Working tree:** limpo depois do commit deste handoff
- **Suíte:** `tests/run-all.sh` → verde (rc 0, 404 s; 1897 linhas `ok`; 668 mutantes com âncora válida)
- **E2E:** não se aplica (o kit não tem `E2E_CMD`)
- **Carimbo de mutação:** inválido para esta branch desde o I12 (esperado); o `sdd health` roda UMA
  vez, depois dos bots, no worktree

## O que foi feito

- `5df5176` — I12 (feito no planejamento): o `/sdd-plan` commita o que o `sdd approve` deixa; o relay segura o que não é resposta
- `fc763ef` — I1 (#226): `tests/isolate-git.sh` em 17 arquivos; 12 de 16 sensores moviam a isca, 0 depois
- `dfd9ab5` — I2 (#224): a linha `|`-led com menos de cinco células é recusada pelo nome nos dois leitores
- `802b6d5` — I3 (#223): o `red_norm` guarda o array vazio (docker `bash:4.3`: 1 → 0)
- `4d72973` — I4 (#232): `deferred` só vale com `## Decis…` fora de cerca no corpo do bug
- `ed5ef44` — I5 (#225): relatório da ponta da base exige blob de checkpoint escrito pela missão
- `6a5c3bb` — I6 (#233): a guarda do kit compara a árvore suja por caminho e conteúdo, e diz o que mudou
- `8778be8`, `0f5ad85`, `92f7d5c` — I7 (#228, #227, decisão 11a): remédio do carimbo impossível; nota só com sessão nas três portas
- `e892814`, `57ea34f` — I8 (#229, #230): status cala sem `session` local; o `ok` do `note-manual` lê `CHECKPOINT_NOTE`
- `daf3a8e` — I9 (#234): `name_stragglers` no supervisor; o `turn_rule` ganha o processo em background
- `4e9c854` — I10 (#235): passo 2 do `/sdd-plan` (worktree ligado no próprio kit)
- `6bc4b37` — I11: `RESOLVED by` nos 12, ADR 0016 aceita, emenda na 0015, drift, `KAIZEN_LOG.md` e este handoff

## Revisão final da branch (depois do I11)

Um revisor de contexto novo leu `89df2e5..3df598f`, só leitura, de uma cópia por `git archive`.
Veredito: mergeável depois de uma leva pequena; 0 Critical, 1 Important, 7 Minor. Re-graduados por
efeito e consertados numa leva, cada um com vermelho medido antes:

- `3b1c4dc` — **Important (I6):** o swap do vim, reescrito a cada poucos segundos de digitação,
  parava o `sdd run` de um alvo num kit já sujo, sem nada salvo. Os temporários de editor entram no
  `.gitignore` do kit; o kit falso do `check-autonomy.sh` passa a carregar o `.gitignore` real e o
  regime 2c é o sensor (red pelo `sdd run`: `kind:kit-touched same:1`). O `failure-modes.md` ganha o
  verbete `kit-touched`, que não existia.
- `875538b` — **Minor → Important (I4):** `## Decisões …`/`## Decisoes …` liam como decisão, e o
  `deferred` só com a pergunta aberta passava: a falha aberta da #232 por outra grafia. Red
  `REVIEW|REVIEW|REVIEW` → `REVIEW|QA|QA`; 1 mutante novo, 1 re-ancorado.
- `0d6c165` — **Minor (I8, decisão minha errada):** o `README.md` descrevia a dica do `sdd status`
  sem a condição nova.

Recusado: o achado 7 (`descendants()` calado sem `CONFIG_PROC_CHILDREN`) não procede — a admissão já
recusa esse kernel (`bin/sdd-coordination.py:186`). Os minors 2, 4, 6 e 8 foram ao humano, que
decidiu na rodada dos bots (seção abaixo):

- **2 (I1):** o censo não conta `/usr/bin/git` nem `$GIT` como "primeiro git" (a classe exclui `/`):
  falha aberta sem caso hoje.
- **4 (I2):** comentário, ADR e prosa dizem "cabeçalho de cinco células"; o predicado admite quatro
  com a barra final. Comportamento antigo; só a prosa exagera.
- **6 (I6):** o ramo `(no longer dirty)` do motivo não tem mutante próprio.
- **8:** ordem de hash nos itens `(no longer dirty)`; tab num caminho do kit corta a chave; o `—` no
  `Status:` das ADRs 0014–0016.

## Rodada dos bots (PR #237)

Codex: 1 P1. CodeRabbit: 2 Major e 3 Minor. Copilot sem cota (lacuna de cobertura, não aprovação).
Tudo numa leva, com vermelho medido antes onde há lógica e cada mutante novo provado por `--only`:

- `06e0235` — **Codex P1 (I4):** a decisão do `deferred` valia só pelo título, e um `## Decision`
  vazio passava. A seção agora precisa de uma data `AAAA-MM-DD` (no título ou no corpo, fora de
  cerca, antes do próximo `##`). As 18 seções reais dos alvos têm data: nenhum veredito muda. Red
  `REVIEW|REVIEW|REVIEW|REVIEW` → `REVIEW|QA|QA|QA`; 2 mutantes.
- `592a74f` — **CodeRabbit, 2 Major (I9):** o aviso copiava a `cmdline` (credencial possível no
  stderr) e agora nomeia só o executável; um stderr fechado matava o supervisor antes do `ECHILD` e
  soltava a trava, e a escrita do aviso virou melhor esforço. 2 probes, 2 mutantes.
- **CodeRabbit, 3 Minor:** pipes da tabela do `KAIZEN_LOG.md` escapados; a contagem de hoje do
  `--check` acrescentada ao critério d do `00-missao.md` (12/11, sem reescrever a medição do
  planejamento); o 656 deste handoff. No commit deste handoff.

Os minors da revisão final, pela decisão do humano: 6 e 8 em `f2ef238` (o `(no longer dirty)`
inteiro e na ordem do git; regime 2d, 3 mutantes), 4 em `d7ddf46` (a prosa do cabeçalho de seis
campos), e o 2 virou item do `TODO.md` e a issue #238 (`251d7be`, catraca 13 → 14). Recusado do 8: o
`—` no `Status:` das ADRs é o marcador de ticket ausente que o `sdd adr new` escreve
(`bin/sdd:7713`), igual de 0010 a 0016.

**Achado da própria leva:** os `--only` contra o `check-autonomy.sh` deram `HARNESS-BROKEN`. A
sandbox do catálogo não copiava o `.gitignore` que o regime 2c (`3b1c4dc`) lê, e o `sdd health`
teria parado antes do primeiro mutante, como o `commands/` no PR #222. `8c8be78` copia o arquivo.

**2ª rodada do Codex (sobre `a3aeac4`):** 1 P2, procedente. Num caminho do kit já sujo, uma fase que
só troca o bit de execução não mudava o porcelain nem o md5, e a guarda calava — a classe da #233
por outro lado. `6a93d14` põe o bit ao lado do digest e o motivo diz `(mode changed)`; regime 2e, red
`sessions:2 rc:3 kind:no-progress named:0 x:1`; 2 mutantes. O CodeRabbit confirmou os cinco consertos.

**3ª rodada do Codex (sobre `aa18052`):** 1 P2, procedente. Um symlink já sujo, reapontado para um
arquivo de mesmo conteúdo e modo, passava calado: o digest seguia o link. Terceira dimensão na mesma
vizinhança, e ali o remendo parou: `a55b53c` faz o digest ser a identidade inteira que o git dá à entrada
(tipo, modo, conteúdo; o symlink é o texto do alvo), com o gitlink declarado. Regime 2f, red
`sessions:2 rc:3 kind:no-progress named:0 c:1`; 2 mutantes.

## Artefatos

| Arquivo | O que contém |
|---|---|
| `docs/handoffs/20261006-lote-5-o-que-o-lote-4-deixou/checkpoint-notas.md` | uma nota por incremento: Red medido, desvios, sabotagens, re-provas |
| `docs/adr/0016-the-mission-checkpoint-and-the-kit-worktree.md` | §1 posse do relatório (emenda a 0015 §3), §2 missão do kit em worktree; `accepted` |
| `tests/isolate-git.sh` | a definição única que limpa as variáveis de repositório do git |
| `KAIZEN_LOG.md` | entrada `2026-10-06 — Lote 5: o que o lote 4 deixou` |

## Boot da próxima fase

Execução interativa (decisão 2 do grill), no worktree, nunca `sdd run` no kit. Ordem, a mesma do
lote 4 (`CLAUDE.md` § carimbo):

1. `git push -u origin fix/lote-5-o-que-o-lote-4-deixou` e abrir o PR com o corpo do
   `templates/pr-body.md`, declarando as quatro mudanças de comportamento (abaixo);
2. esperar **todos** os bots (`@codex review`; `@coderabbitai review` se pausar) e consertar numa leva;
3. `mkdir -p .sdd/cache && cp /home/joruge/repos/sdd_agents/.sdd/cache/mutation-killers.tsv .sdd/cache/`
   no worktree, e só então `./bin/sdd health` UMA vez (lançador `setsid`, env sem `CLAUDE*`/`GIT_*`,
   `TMPDIR` curto, vigiar pelo PID);
4. merge pelo humano; depois o chore pós-merge (catraca 13 → 1) e o re-sync do espelho de issues.

**Mudanças de comportamento a declarar no PR:** I4 (um bug `deferred` sem a seção de decisão
bloqueia a QA); I6 (um kit sujo editado durante a fase de um alvo para a linha); I7 (a nota
`intervention:` do `--phase`, do `retry` e do `--budget-override` só existe quando a volta abre
sessão, e a da override carrega a fase da sessão comprada); I9 (o supervisor imprime uma linha a
mais no stderr).

## Pendências / Decisions for a Human

- O momento do `sdd health` (passo 3 acima) — o carimbo é do humano (ADR 0015 §1).
- O merge, o chore pós-merge e o re-sync do espelho de issues (`todo_issues.py --apply`, depois
  `--apply --close-orphans`).
- A remoção do worktree e da branch local depois do merge; o yokoten nos repos-alvo.
- O desenho da #236 (`sdd kaizen` no checkout principal), aberta de propósito (decisão 11b).

## Riscos e não-feitos

- **Carimbo não medido:** o catálogo de 668 mutantes só roda no `sdd health`; as re-provas desta
  leva foram por `--only` (dica), cada mutante novo e os vizinhos que o plano nomeia.
- **`TMPDIR` longo:** cinco `--only` contra o `check-autonomy.sh` deram `HARNESS-BROKEN` com o nome
  do mutante no `TMPDIR` (limite já declarado no sensor desde `0c0e13a`); com `TMPDIR` curto, todos
  pegos. O `sdd health` roda com `TMPDIR=/tmp`.
- **Sem probe, declarados no código:** o `GIT_OPTIONAL_LOCKS=0` do `kit_guard_tree` (I6); o
  `GITENV_FLOOR=0` sozinho (I1); o reset do `CHECKPOINT_NOTE` e o braço `*` do `case` (I8); o grace e
  o "não nomear quando chegou sinal" (I9); o re-arm da árvore do kit (I6).
- **Desvios do protótipo, todos medidos e anotados nas notas do checkpoint:** I6 ganhou o
  `GIT_OPTIONAL_LOCKS=0` que o plano pedia e o patch não tinha; I10 ganhou a frase do `./bin/sdd` e a
  8ª verificação do probe; I7 corrigiu "decision 10a" para 11a.

## Achados fora de escopo

Um, por decisão do humano na rodada dos bots: o minor 2 da revisão final (o censo do `GIT_DIR` não
conta o git chamado por caminho ou variável), item do `TODO.md` e issue #238. A catraca fica em 14
na branch e desce a 2 no chore pós-merge.
