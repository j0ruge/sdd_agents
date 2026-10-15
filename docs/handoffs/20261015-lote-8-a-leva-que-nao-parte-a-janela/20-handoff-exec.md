---
missao: 20261015-lote-8-a-leva-que-nao-parte-a-janela
fase: EXEC
status: done
sessao: 12bf428b-7e12-4ad8-b297-15e355564067
data: 2026-10-15 17:36
gate: `tests/run-all.sh` em `fd124bc` → `suite green` (17:25 → 17:36; 2001 linhas `ok`, nenhum `FAIL`)
---

# Handoff — EXEC — o lote 8: a leva que não parte a janela

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

I1–I6 feitos, interativos, no worktree; a janela não partiu (nada em `bin agents templates config`).
A M1 mediu **2**, não "no máximo 1": a I8 da LH-4 é recusa da própria regra da decisão 5 e virou item.
Catraca 15 → **18** (decisão 7 + dois achados de sensor do EXEC), e o Check do I6 lê 18.
A revisão final achou duas falhas abertas da regra 2, fechadas em `fd124bc`.
Próximo: o PR, pelas pendências 1 a 3 do `00-missao.md`, com o carimbo depois da leva dos bots.

## Estado do repo

- **Branch:** `fix/lote-8-a-leva-que-nao-parte-a-janela` — sem upstream, não empurrada.
- **Último commit de código:** `fd124bc` `fix(tests): revisão final do lote 8 — a regra 2 fecha a indireção e o segundo padrão de um grep`; depois dele só este handoff, o `KAIZEN_LOG.md` e o checkpoint.
- **Working tree:** limpo.
- **Suíte:** `tests/run-all.sh` em `a5d70e7` → `suite green` (16:54 → 17:05); em `fd124bc` → `suite green` (17:25 → 17:36; 2001 linhas `ok`, nenhum `FAIL`)
- **E2E:** não se aplica (o kit não tem interface).

## O que foi feito

- `53057c2` — I1: a regra 2 do `check-checkpoint.sh` lê a variável que a captura `2>&1` contaminou, não a célula (#258).
- `3324d6c` — I2: a marca de "passou" `'^ *✓ '` (U+2713 e branco) ancora como o `^  ok    `, nos dois caminhos da regra 2 (#249).
- `3a7b12f` — I3: a linha que só carrega a âncora sai do teto de largura do `check-todo.sh`, e a mensagem do teto nomeia a saída (#257).
- `fcb8872` — I4: o relay do `/sdd-plan` descarta a devolução que um recado superou (#264).
- `708b10c` — I5: a receita do worktree do `/sdd-plan` corta a branch com `--no-track`.
- `a5d70e7` — I6: `RESOLVED by` nos 5 itens, três itens novos (catraca 15 → 18), a entrada do `KAIZEN_LOG.md` e a gaveta F3.
- `a576a27` — PR #267, Codex: `-F`/`--fixed-strings` e `-v`/`--invert-match` nunca ancoram, nos dois caminhos.
- `5c53e33` — PR #267, 2ª rodada do Codex: a isenção de largura do I3 só aceita `path:N` em ASCII imprimível sem `:`.
- `44339ab` — PR #267, 3ª rodada do Codex: a regra 2 recusa o grep com um padrão em aspas ANSI-C (`$'…\n…'` são dois padrões), nos dois caminhos.
- `67df1c5` — PR #267, 4ª rodada do Codex: a regra 2 lê opção longa por prefixo (`--fixed`, `--inv`, `--reg=`) e lê `egrep`/`fgrep`.
- (este commit) — PR #267, 5ª rodada do Codex: as três âncoras do `TODO.md` em `tests/check-checkpoint.sh` voltam ao alvo (650/651/655 → 672/673/677).
- (este commit) — PR #267, 6ª rodada do Codex: o argumento de opção contado como padrão vai para o `TODO.md` (catraca 18 → 19), por decisão do humano.
- `fd124bc` — revisão final: a regra 2 cai para a regra da célula com `${!v}`, nameref ou `eval`, e um grep só ancora com uma âncora por padrão que nomeia (`-e`, `--regexp`; nunca `-f`), nos dois caminhos.

Medido (os dois sensores reais, o da `fec0cca` e o desta branch): os 36 checkpoints dos alvos recusam
**122 → 114** células; a LH-4, **10 → 2**; o `sales_quote` fica em 98 (48 leem só a linha de resumo,
fora pela decisão 5; 29 têm grep de esperado `0`; 21 outras formas). Os selftests ganharam 50 probes;
a sabotagem somou 74 degradações, todas vermelhas no fim.

## Artefatos

| Arquivo | O que contém |
|---|---|
| `docs/handoffs/20261015-lote-8-a-leva-que-nao-parte-a-janela/checkpoint.md` | I1–I6 `done`, com hash |
| `docs/handoffs/20261015-lote-8-a-leva-que-nao-parte-a-janela/checkpoint-notas.md` | red, sabotagem, medições e os `Ruling:` de cada incremento |
| `tests/check-checkpoint.sh` | `rule2` (`r2_captures`, `r2_greps`), `r2_grep_anchored`, `r2_anchored`, `PASS_MARK`; 109 probes, 4 linhas `rule:` |
| `tests/check-todo.sh` | a isenção da linha-âncora; 192 probes, 12 linhas `rule:` |
| `tests/check-hat.sh` | os pares do relay (#264) e do `--no-track` |
| `commands/sdd-plan.md` | o bullet do relay e a receita com `--no-track` |
| `TODO.md`, `tests/health-baseline.txt` | 18 itens, 5 com `RESOLVED by`; `todo-findings 18` |
| `KAIZEN_LOG.md` | a entrada do lote 8, com o id inteiro da missão (o `gate_DOCS` lê) |

## Boot da próxima fase

O PR, no worktree, nesta ordem (pendências 1 a 3 do `00-missao.md`):

1. `git push -u origin HEAD` e o PR com o corpo do `templates/pr-body.md`.
2. `@codex review` num comentário (neste repo o Codex só revisa a pedido); vigie, com `--paginate`, o
   `Completed` dele no sha do head. O CodeRabbit "rate limited" é "não revisou".
3. `local/ci` pela API de Statuses só com a suíte rodada naquele sha (`gh api -X POST
   repos/j0ruge/sdd_agents/statuses/<sha> -f state=success -f context=local/ci -f description=…`).
4. Uma leva de consertos para todos os revisores.
5. Copie `/home/joruge/repos/sdd_agents/.sdd/cache/mutation-killers.tsv` para o `.sdd/cache/` do worktree
   e rode **um** `./bin/sdd health` (39–64 min; `tests/` está na chave do carimbo). Antes do
   `git worktree remove`, o mapa de assassinos volta ao checkout principal.
6. Merge commit, nunca squash. Depois, o pull do checkout principal só com
   `ps -eo pid,etime,cmd | grep -E 'bin/sdd (run|retry|close)'` vazio (decisão 2).

## Pendências / Decisions for a Human

- **A M1 não fechou como o plano previa** (2, não ≤ 1). Ruling do EXEC: não alargar a regra além da
  decisão 5; a I8 virou o item "A regra 2 recusa o grep de esperado `0`…" no `TODO.md`. Se o humano
  preferir consertar nesta leva, é só `tests/` — mas é uma regra nova, e a decisão é dele.
- **O Check do I6 lia `todo-findings 16`** e passou a ler 18, pelos dois achados do EXEC (princípio 5).
  O chore pós-merge desce a catraca de 19 para 14 (não 16 → 11), fecha #249, #257, #258 e #264 e
  abre **cinco** issues: o gêmeo do `--no-track`, a prosa congelada, o grep de esperado `0`, a mescla `&>`
  e o papel das palavras do grep (6ª rodada do Codex, registrado por decisão do humano).
- **Revisão final da branch:** 0 Critical, 2 Important (consertados em `fd124bc`), 4 Minor. Três Minor ficaram
  adiados e estão no `checkpoint-notas.md` (`Final: minor (deferred)`); o `-v` ficou declarado no cabeçalho.

## Riscos e não-feitos

- O carimbo de mutação está inválido desde o I1 (`tests/` na chave): o `./bin/sdd health` é a pendência 5 acima.
- A regra 2 segue cega para `&>`, `>&` e `&>>` (falha aberta anterior ao lote, medida nesta sessão): registrada, não consertada.
- A prosa congelada (`templates/`, `agents/`) segue mais estrita que os sensores, por decisão 7.
- O caminho entre o `^` e a marca só lê brancos (com ou sem `*`): `'^[[:space:]]*✓ '` é recusada, fechado e declarado no cabeçalho.
- `grep -v` e `grep -F` com padrão ancorado passavam como ancorados: declarados no cabeçalho até o Codex no PR #267 reproduzir o `-F`; recusados em `a576a27`.
- A isenção de largura do I3 aceitava um URL e prosa separada por TAB ou NBSP (o Minor "TAB/URL" adiado): recusados em `5c53e33`; a linha isenta segue sem prova de que é a âncora do item, declarado no cabeçalho.
- Um padrão em aspas ANSI-C (`$'^ ✓ a\ncaso'`) passava como ancorado: o `\n` vira um segundo padrão; recusado em `44339ab`, junto com um `\$'` escapado (o lado seguro).
- Opção longa abreviada (`--fixed`, `--inv`, `--reg=`) passava como a grafia que o grep não lia, e um `egrep` ancorado era recusado (regressão do lote): consertados em `67df1c5`. Segue não medido: `rg`, `awk`, e um FILE entre aspas com nome de âncora ao lado de um `-e` cego.

## Achados fora de escopo

- A regra 2 só vê a mescla escrita `2>&1` → `TODO.md`, seção `<!-- sdd:open -->` › Sensores que faltam
- A regra 2 não sabe o papel de cada palavra do grep (6ª rodada do Codex no PR #267) → `TODO.md`, seção `<!-- sdd:open -->` › Sensores que faltam
- A regra 2 recusa o grep de esperado `0` na saída mesclada de um build → `TODO.md`, seção `<!-- sdd:open -->` › Contrato e configuração
- A prosa congelada mais estrita que os sensores (decisão 7) → `TODO.md`, seção `<!-- sdd:open -->` › Contrato e configuração
