---
missao: 20260817-eixo-do-juiz
fase: EXEC
status: done
sessao: 269c9347-5cfe-4e82-a5d2-1eceee1ec6e5
data: 2026-08-17 09:21
gate: "tests/run-all.sh → suite green · score: 60 caught, 0 known gap(s), of 60 · ./bin/sdd health → ok nos cinco (suíte, mutação 60, 8 gates com mutação, proveniência 3/3, catraca 6 débitos, nenhum novo) · checkpoint 5/5 done, hashes 3547a83 abac043 d62f08c c514e36 4ca8015 todos no git log"
---

# Handoff — EXEC — o eixo do juiz

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

Os 5 incrementos estão `done`. O juiz agora **explica** o `indeterminado` estrutural
(`guard.degenerate_axis: true` citando o ADR 0003), `--all-repos` reabre a leitura entre projetos,
worktree deixou de partir a identidade do repo, e linha sem `repo` ganhou balde próprio em vez de
inflar o piso em silêncio. Catálogo de mutação **55 → 60**, `0 known gap(s)`, suíte verde.
A próxima fase (QA) roda **sem interface**: o produto é CLI, e as jornadas são comandos.

## Estado do repo

- **Branch:** `missao/20260817-eixo-do-juiz` — nunca empurrada; `origin` não conhece esta branch.
- **Último commit:** `34c4875` `chore(todo): o item da linha sem repo carrega o hash que o fechou`
  (mais o commit do checkpoint/handoff que fecha esta sessão).
- **Working tree:** limpo.
- **Suíte:** `tests/run-all.sh` → **verde**. Doze sensores + lint + dry-runs;
  `score: 60 caught, 0 known gap(s), of 60`.
- **E2E:** `E2E_CMD` é vazio no `.sdd/config.sh` deste repo — não existe jornada de navegador. O
  equivalente aqui são os comandos da seção "Boot da próxima fase".

## O que foi feito

- `3547a83` — **I1**: nasce `docs/adr/0003-judge-axis-evidence-from-target-repos.md` (evidência de
  veredito vem de repo-alvo real; o eixo `kit_sha` não muda; o piso `>= 3` não afrouxa), e o
  `bin/sdd` passa a **citar** o número — ADR órfão de código é rótulo. 2 asserções `adr 0003`.
- `abac043` — **I2**: a série expõe `guard.degenerate_axis`, verdadeiro quando **todo** sha do
  recorte tem exatamente 1 sessão **e** há mais de um sha; `sdd kaizen` imprime a explicação
  citando o ADR 0003. Predicado como `def` único no programa `jq`.
- `d62f08c` — **I3**: `--all-repos` em `sdd autonomy` e `sdd kaizen --series`, ligando o predicado
  único e alcançando por herança o lembrete pós-pipeline. Default segue filtrado.
- `c514e36` — **I4**: `ledger_repo_root` deriva a identidade do `.git` **compartilhado**
  (`--git-common-dir` normalizado), no escritor **e** nos leitores — worktree volta a ser o mesmo
  repo.
- `4ca8015` — **I5**: `excluded.no_repo` nos dois leitores. Linha sem `repo` deixa de ser "local em
  todo repo" e deixa de poder virar `guard.sufficient` para `true` em silêncio.
- `e02319b`, `80cbea2`, `34c4875` — os itens do `TODO.md` fechados por I3, I4 e I5 carregam o hash.
- `b7d1c30`, `80cbea2` — dois achados fora de escopo registrados (ver a seção final).

## Artefatos

| Arquivo | O que contém |
|---|---|
| `docs/adr/0003-judge-axis-evidence-from-target-repos.md` | a decisão sobre o eixo do juiz, com a medição que a motivou e a alternativa descartada |
| `docs/handoffs/20260817-eixo-do-juiz/checkpoint.md` | a tabela 5/5 `done` com os hashes, e ~25 notas de execução (é onde mora o detalhe caro) |
| `bin/sdd` | `ledger_repo_root`, `ledger_row_is_local` + `ledger_row_no_repo`, `degenerate_axis`, `kaizen_axis_note`, os parsers de `--all-repos` |
| `tests/check-kaizen.sh` | asserções `adr 0003` (2) e `degenerate axis` (2) |
| `tests/check-autonomy.sh` | asserções `all-repos` (2), `worktree` (2), `no-repo` (2) |
| `tests/check-mutation.sh` | as 5 mutações novas: `KAIZEN_adr_0003_orphan`, `KAIZEN_degenerate_axis_blind`, `AUTONOMY_all_repos_ignored`, `LEDGER_repo_root_toplevel`, `LEDGER_no_repo_counted_as_local` |
| `docs/pipeline.md`, `agents/sdd-kaizen.md` | a prosa do schema da série (guard com 5 chaves, `excluded` com 5 baldes) |

## Boot da próxima fase

Ler, nesta ordem: `00-missao.md` (a métrica é uma lista de binários), este handoff, e as **notas de
execução** do `checkpoint.md` — elas contêm o que custou caro e não se re-descobre.

Não há interface. As jornadas do usuário são estes comandos, todos rodáveis do checkout:

```bash
bash tests/run-all.sh                    # suite green · score: 60 caught, 0 known gap(s), of 60
./bin/sdd health                         # ok nos cinco
./bin/sdd kaizen --series | jq '.guard'  # degenerate_axis: true, sufficient: false
./bin/sdd kaizen --dry-run               # a explicação impressa, citando ADR 0003
./bin/sdd autonomy                       # 51 linhas, excluded other_repo 11
./bin/sdd autonomy --all-repos           # 62 linhas, other_repo 0, header diz "all repos"
./bin/sdd help                           # --all-repos documentado, com o porquê do default
```

⚠️ Os dois números do `autonomy` (51 e 62) são do ledger **desta máquina em 2026-08-17** e sobem a
cada sessão — o ledger é append-only e global. O que não muda, e é o que a QA deve exigir, é a
**diferença**: `--all-repos` lê estritamente mais linhas que o default, e `excluded.other_repo`
cai a `0` com a flag. Comparar as duas saídas entre si, nunca contra a constante escrita aqui.

**O que no diff é visível ao humano** (é isto que a QA tem de andar):

1. `sdd kaizen` passa a **imprimir uma frase nova** quando o eixo degenera, citando o ADR 0003. É
   a métrica central da missão: hoje, neste repo, ela aparece.
2. `sdd autonomy` e `sdd kaizen --series` aceitam **`--all-repos`**; o cabeçalho da tabela humana
   passa a nomear o **escopo** (`all repos (--all-repos)`) em vez de um caminho de repo.
3. A tabela humana ganhou **uma linha de exclusão nova** (`N row(s) excluded: no repo field`) e uma
   **quarta voz de "no data"** (ledger inteiro de linhas que não dizem de onde vieram).
4. A série ganhou **duas chaves** (`guard.degenerate_axis`, `excluded.no_repo`). Consumidor que
   fizesse parse rígido do JSON veria shape nova — não há nenhum fora do próprio kit.
5. Rodar qualquer coisa **de um worktree** passa a gravar e ler a identidade do repo lógico.

⚠️ Para exercitar o item 5 de verdade é preciso `git worktree add` num diretório temporário; o
`tests/check-autonomy.sh` já faz isso com o escritor real (`blocked`, rc 3, zero token).

## Pendências / Decisions for a Human

- **Nenhuma.** A única decisão pendente do plano (`aprovacao:` vazio para dogfood do
  `sdd approve`) foi resolvida antes do EXEC: `bad17c8` registra a aprovação humana.

## Riscos e não-feitos

- **Linhas antigas do ledger seguem em `other_repo`.** A mudança de identidade do I4 reclassifica
  o histórico escrito antes dela. É **history, not a bug** — o ledger é append-only e não se
  migra; está dito no ADR 0003 e no `docs/pipeline.md`. No ledger real de hoje: `other_repo: 11`.
- **A varredura dos 5 itens do `TODO.md` está incompleta.** Os itens fechados por I3, I4 e I5
  carregam `RESOLVIDO por <hash>`; os do **I1 e do I2** ainda não. A "Verificação end-to-end" do
  plano cobra os cinco, e isso é da fase **DOCS**.
- **O `KAIZEN_LOG.md` não foi tocado.** O antes/depois medido da série é da fase DOCS (item K8 do
  checklist kaizen).
- **`missions` não sobe no ledger real com `--all-repos`** — sobe no fixture de dois repos. Não é
  defeito da flag: é o eixo degenerado que o I2 expôs (o sha corrente tem uma missão só). A
  métrica do `00-missao.md` que pede "`missions` maior" é satisfeita pelo sensor, não pelo ledger
  desta máquina, e a nota do `EXEC I3` no checkpoint registra isso.
- **Nada foi empurrado, nenhum PR foi aberto.** Isso é de outra fase, por regra.

## Achados fora de escopo

> Registrados no `TODO.md` deste repo (o kit é o próprio alvo desta missão). Aqui fica só o
> ponteiro, para o PR conseguir citar.

- `.claude/agents/` não é gravável por sessão headless; quem sincroniza é `sdd install --force`, e
  o `cmp -s` do preflight só fica verde depois disso → `TODO.md` (registrado em `b7d1c30`).
- `cmd_kaizen` (`bin/sdd:2735`) decide "estou no repo do kit?" com `--show-toplevel` — a **mesma**
  pergunta por worktree que o I4 acabou de tirar do ledger, em outra porta; de um worktree do kit o
  comando recusa rodar → `TODO.md` (registrado em `80cbea2`).
