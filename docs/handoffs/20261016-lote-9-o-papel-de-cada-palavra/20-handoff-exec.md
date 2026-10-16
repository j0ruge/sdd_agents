---
missao: 20261016-lote-9-o-papel-de-cada-palavra
fase: EXEC
status: done
sessao: d5bc87f9-f280-4f5b-ae08-fc6d807f8a31
data: 2026-10-16 11:51
gate: `tests/run-all.sh` na árvore do fecho (sobre `c286edf`) → `suite green`, rc 0 (11:43 → 11:51; 2005 linhas `ok`, nenhum `FAIL`); Check do I5 → `1 0 3 1 0`
---

# Handoff — EXEC — o lote 9: o papel de cada palavra

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

I1–I5 feitos, interativos, no worktree; a janela não partiu (`git diff fec0cca..HEAD -- bin agents
templates config` vazio; `kaizen --series` segue em `bad6168`, `missions: 1`).
A regra 2 do `check-checkpoint.sh` lê o grep como o grep se lê: toda grafia de mescla (#269), cada
palavra pelo valor e o argv pelo getopt_long, só o padrão deve âncora (#270), e o par de zeros (#272).
Alvos: **114 → 105** recusas, LH-4 **2 → 1** (a I9 fica); a previsão de 103 errou por duas células
que caem na regra da célula. Probes 128 → 316, 321 sabotagens, quatro linhas `ok    rule:` novas.
Catraca **15** (não 14: o achado de `commands/` de `6e20c92`); no chore pós-merge ela vai a **12**.
Próximo: o PR (pendências 1 a 4 do `00-missao.md`), parado pela decisão 4, sem carimbo.

## Estado do repo

- **Branch:** `fix/lote-9-o-papel-de-cada-palavra` — sem upstream, não empurrada.
- **Último commit de código:** `c48623d` (I4); o commit do fecho (o hash está na linha I5 do
  `checkpoint.md`) só toca `TODO.md`, `KAIZEN_LOG.md`, a gaveta e a pasta da missão.
- **Working tree:** limpo.
- **Suíte:** `tests/run-all.sh` na árvore do fecho (sobre `c286edf`) → `suite green`, rc 0 (11:43 → 11:51; 2005 linhas `ok`, nenhum `FAIL`).
- **E2E:** não se aplica (o kit não tem interface).
- **Congelamento:** `git diff fec0cca..HEAD -- bin agents templates config` → vazio.

## O que foi feito

- `61bc9e9` — I1: `r2_merges` nos três sítios do literal `2>&1`; as 13 grafias de mescla do gemba põem a
  célula sob a regra, as 6 que não mesclam (`&>/dev/null`, `&>>/dev/null`, `>&/dev/null`, `>&2`, `1>&2`,
  `2>&-`) ficam fora (#269).
- `5c5596a` — I2: `r2_word`/`r2_dollar` leem cada palavra do grep como o bash a entrega (valor, prefixo
  literal, classe); o redirecionamento sai das palavras (#270, metade 1).
- `3de6c5c` — I3: `r2_argv` lê o argv com a tabela do GNU grep 3.11 (`R2_SHORT_ARG`, `R2_SHORT_NONE`,
  `R2_LONG`, `R2_MATCHERS`); só o padrão deve âncora; `F v z f` desarmam (#270, metade 2).
- `c48623d` — I4: `r2_pairs`/`r2_zero_pair`/`r2_counts_zero`; o grep contador no topo de um par de
  esperado só zeros, com a lista positiva `R2_ZERO_OPTS`, não deve âncora (#272).
- o commit do fecho (hash na linha I5 do `checkpoint.md`) — I5: a medida final, `RESOLVED by` nos três
  itens e a linha do #271 (com a `todo-to-github-issues` consultada antes), a entrada do `KAIZEN_LOG.md`,
  a gaveta F3 e este handoff.

Os commits `docs(missao): I<n> feito` (`047d7d3`, `88882b6`, `5171233`, `c286edf`) só fecham a linha do
checkpoint.

## Artefatos

| Arquivo | O que contém |
|---|---|
| `tests/check-checkpoint.sh` | a regra 2 nova (quatro camadas), 316 probes, `RULE_FLOOR=8`, os limites declarados no cabeçalho (`DECLARED, lote 9`, `DECLARED LIMITS of the merge`, `… of the zero pair`) |
| `TODO.md` | #269, #270 e #272 com `RESOLVED by`; o #271 com a linha do lote 9 |
| `KAIZEN_LOG.md` | a entrada `## 2026-10-16 — Lote 9: o papel de cada palavra`, com o antes e o depois |
| `docs/superpowers/specs/2026-09-23-a-gaveta-do-kit.md` | a linha F3 e o parágrafo `**Hoje (2026-10-16).**` |
| `docs/handoffs/20261016-lote-9-o-papel-de-cada-palavra/checkpoint-notas.md` | os números, as sabotagens e as decisões fora do plano de cada incremento |

## Boot da próxima fase

Missão do kit: o PR é do relay, interativo, a partir do worktree `/home/joruge/repos/sdd_agents-lote-9`
(nunca `sdd run` do checkout principal). Leia este TL;DR, as pendências do `00-missao.md` e, se a
revisão pedir um porquê, a nota do incremento no `checkpoint-notas.md`.

1. **PR e revisão (pendência 1, decisão 4).** `git push -u origin HEAD`; o corpo do
   `templates/pr-body.md`; `@codex review` num comentário (neste repo o Codex só revisa a pedido); o
   `local/ci` pela API de Statuses só com a suíte rodada naquele sha
   (`gh api -X POST repos/j0ruge/sdd_agents/statuses/<sha> -f state=success -f context=local/ci …`).
   A parada é a rodada limpa. Achado que cai num dos três itens e cabe no modelo (uma linha da tabela
   de opções, uma grafia de mescla, um caso do par de zeros) se conserta no PR; classe nova vai ao
   `TODO.md` com a catraca; a partir da 4ª rodada todo achado vai ao `TODO.md` e o humano decide o merge.
   Cada conserto em `tests/` roda `bash tests/check-todo.sh --anchors TODO.md` antes do commit: as
   âncoras do #269 (`:1136`), do #270 (`:795`) e do #272 (`:1141`) andam com o arquivo.
2. **Sem carimbo (pendência 2).** O `./bin/sdd health` não roda (decisão do humano no PR #267: só quando
   a catraca das issues zerar). Merge por merge commit, nunca squash.
3. **O pull ocioso (pendência 3).** Depois do merge, `git -C /home/joruge/repos/sdd_agents pull --ff-only`
   só quando `ps -eo pid,etime,cmd | grep -E 'bin/sdd (run|retry|close)'` vier vazio. Sem o pull o
   conserto não chega ao planner de nenhum alvo.
4. **O chore pós-merge (pendência 4), da `main`, com a `todo-to-github-issues`.** Apagar os 3 itens com
   `RESOLVED by` (prova: `git merge-base --is-ancestor <hash> main` para `61bc9e9`, `3de6c5c` e `c48623d`),
   descer a catraca de **15 para 12** (não 14 → 11, como o `00-missao.md` diz: o achado de `6e20c92` nasceu
   depois do aceite) e sincronizar o espelho (plano → `--apply` → `--close-orphans`). O plano esperado,
   da `main` e com os três itens apagados: `ORPHAN … fixed by` nos #269, #270 e #272 (o
   `--close-orphans` os fecha), `UPDATE (text)` no #271 e `CREATE` para o item de `6e20c92`, que ainda não
   tem issue (o plano rodado da branch no fecho, só leitura, deu `create=1 update=4`).

## Pendências / Decisions for a Human

- **A parada da revisão (decisão 4)** é do humano a partir da 4ª rodada.
- **A triagem depois do veredito** recebe os 11 itens congelados do plano. O 12º, o de `6e20c92`, toca só
  `commands/sdd-plan.md`, fora de `bin agents templates config`: não parte a janela e cabe numa leva como
  esta ou como a do lote 8; quando entra é escolha do humano.

## Riscos e não-feitos

O que a revisão deve olhar, por incremento (detalhe e medida em `checkpoint-notas.md`):

- **I1, fora da letra do plano:** `&>` e `&>>` mesclam para qualquer nome, dígito ou `-` inclusive
  (`&>1` grava o arquivo `1`); `12>&1` segue lido como mescla (lado fechado); `2>&10` deixou de ser mescla
  (terceiro descritor, declarado e ABERTO).
- **I2, fora da letra:** o padrão colado a `-e`/`--regexp=` é lido e deve a âncora (`--regexp=caso
  '^  ok    x'`, que a base aceitava, agora é recusado); opção cujo nome traz expansão é recusada (a base
  aceitava); `&>`, `>&` e `<&` deixaram de terminar o grep; `&>>`, `<<` e `<<-` lidos como dois operadores.
- **I3, fora da letra:** o operando ANSI-C segue recusado também como FILE (`$'-v'` é opção para o grep,
  medido); o `fgrep` entra como `F` implícito; com `-f`, o primeiro operando é publicado como padrão
  (o `f` desarma, nenhum veredito depende disso); o argv ilegível deixa `?` no `R2_OPTS`. O `R2_WP` não é
  lido por ninguém além do `wd_tok`.
- **I4, fora da letra:** duas condições a mais no "topo" (o grep abre um comando: início do span, depois
  de `;` ou `&&`, nunca depois de `||`; e não vem depois de palavra que abre comando composto ou `exec`).
  Só fecham; nenhuma mudou o número nos alvos.
- **Limites declarados no cabeçalho, ABERTOS:** a palavra que abre com expansão é operando, e o valor
  dela poderia ser opção (o controle `"$l"` do kit); a tabela é a do GNU grep 3.11 sem `POSIXLY_CORRECT`
  (outro grep lê o argv por outra regra); a mescla por um terceiro descritor (`3>&1 2>&3`, `2>&10`); um
  nome que troca o grep antes dele (`PATH`, `grep () (echo 0)`). **FECHADOS:** o par de esperado misto
  (`3 0`), `>&`/`&>` dentro de aspas e `>/dev/null 2>&1`, a contagem capturada e reimpressa.
- **O selftest** leva ~14 s sob carga 5 (12 s na base), longe do prazo de 60 s.
- **Não-feitos, por decisão:** os 11 itens congelados e o de `commands/` (`6e20c92`, nascido depois do
  aceite), o esperado misto, a mescla por terceiro descritor, o carimbo de mutação.

## Achados fora de escopo

- Nenhum novo nesta fase. O achado de `commands/` registrado depois do aceite (`6e20c92`, o passo 2 do
  `/sdd-plan` pede a branch antes de o id existir) → `TODO.md`, seção `<!-- sdd:open -->`.
