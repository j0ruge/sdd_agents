---
missao: 20261119-l1b-a-rodada-delta
fase: REVIEW
rodada: 4
status: done
sessao: 823b8171-8721-4f1e-a420-bcb26e5ba167
data: 2026-11-20 17:04
gate: "tests/run-all.sh rc=0 (suite green, 2216 linhas ok, 0 FAIL, 926 mutantes aplicam) sobre 1c4e8c4; scan de segredos 0 achados (regex + gitleaks, 13 arquivos); sdd review-base → full — merge 079bc39 entered after 40-review-r3.md"
reviewed_head: 1c4e8c4cea5d1a74f9c70297949e9f2de933dd0b
---

# Review — rodada r4 — o pós-merge do L1b (PR #454)

## TL;DR

Rodada do worker sobre o chore pós-merge (`chore/l1b-pos-merge`, PR #454), **inteira** pelo
`sdd review-base` (`full — merge 079bc39 entered after 40-review-r3.md`: o merge do próprio #452),
pelo `/codereview:codereview` sem `base=`. O merge-base com a `main` é o próprio `079bc39`, então a
rodada leu só o diff do chore: `079bc39..1c4e8c4`, 7 commits, 13 arquivos, +199/−30. Os 4 LOW da r3
estão fechados, cada conserto de código com um mundo vermelho antes e um mutante que o
`check-gates.sh` mata (os três medidos com `--only`). O #436 sai pela regra (`a3d0b72` ancestral da
`main`), a catraca fica em 98 (−1 +1) e o item novo do L5b confere com o comando. Seis LOW de forma
ou de ambiente, nenhum reproduzido como dano. Feita como subagente da sessão orquestradora (o
`sessao:`). Nenhum `R<n>`. Nota: A em todos os critérios.

## Nota da rodada

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | A | Os dois consertos são de uma linha, cada um na definição única que corrige e com o porquê no comentário; só falta declarar o resíduo de quoting (LOW #2). |
| Type Safety | A | Nada de tipo mudou: o valor do frontmatter continua passando pela regex hex e pelo `rev-parse --verify ^{commit}` antes de qualquer comando. |
| Error Handling | A | O `git status` que falha agora tem mundo e mutante, o diff do intervalo segue falhando fechado, e a consulta sem trava não escreve nada (índice idêntico antes e depois, medido). |
| Security | A | Scan de segredos limpo (regex + gitleaks, 13 arquivos, 199 linhas, `errors: []`) e nenhum caminho novo do frontmatter até um comando. |
| Performance | A | Uma variável de ambiente e um `-c` a mais em comandos que já rodavam; nenhum custo novo de tempo. |
| Test Coverage | A | Cada conserto tem um mundo com testemunha do estado e um mutante que o `check-gates.sh` mata; a testemunha do índice depende de o ambiente não exportar `GIT_OPTIONAL_LOCKS` (LOW #1, falha fechada). |
| Documentation | A | ADR, pipeline, verbete, anatomia e chapéu dizem as quatro recusas, o espelho está idêntico e os números do item novo batem com o comando; restam cinco LOW de forma. |
| **Overall** | **A** | Nenhum achado acima de LOW; os seis LOW são de forma ou de ambiente e, pela régua A, não abrem rodada. |

## Achados da rodada

| # | Severidade | Achado | Onde |
|---|---|---|---|
| 1 | LOW | A testemunha "a plain git status rewrites it" do mundo novo depende de quem chama **não** exportar `GIT_OPTIONAL_LOCKS=0`: exportada, o `git status` sem a variável também não reescreve o índice e a asserção fica vermelha com o kit correto. Reproduzido num repo de rascunho (git 2.43): `unset … REWRITTEN` × `exported … untouched`. Falha fechada e alta, e o `tests/isolate-git.sh` não a limpa (não está no `git rev-parse --local-env-vars`). Direção: `env -u GIT_OPTIONAL_LOCKS` na testemunha. | `tests/check-gates.sh` (o mundo do índice do `review_base_line`) |
| 2 | LOW | O comentário do `review_head_ok` não declara que, mesmo sob `core.quotePath=false`, o git põe entre aspas o nome com `"`, `\` ou byte de controle, que não casa glob e recusa a rodada (o lado seguro). Reproduzido: `NO MATCH: "m/a\"b.md"`, `match: m/notes-ü.md`. O `bin/sdd-worker` (`pr-ready`) já declara esse limite. | `bin/sdd` (`review_head_ok`, o comentário da captura do `changed=`) |
| 3 | LOW | A enumeração dos casos `full` do ADR 0023 §2 e do `docs/pipeline.md` não traz o ramo `git status cannot say whether … is committed`, que este PR passou a cobrir com mundo e mutante. Só prosa. | `docs/adr/0023-the-next-round-reviews-the-delta.md` (§2), `docs/pipeline.md` |
| 4 | LOW | "o `git status` da rodada não commitada leva `GIT_OPTIONAL_LOCKS=0`" sugere que ele só roda para a rodada não commitada; roda em toda consulta, e é ele que descobre se ela está commitada. Texto de regra do dono, para o aceite. | `.claude/rules/anatomia-do-agente.md` (§ 3) |
| 5 | LOW | O handoff do lote diz que o chore leva "a catraca de 98 para 97", e o estado final é 98: foi escrito em `3a93245`, antes do item do L5b (`1c4e8c4`). O corpo do PR já diz 98 → 97 → 98. | `docs/superpowers/campaigns/20261117-zerar-as-issues/handoff-L1b.md` |
| 6 | LOW | O título do item novo diz que o `review-base` "responde `full` toda vez"; o corpo diz o caso exato, quando a `main` andou. O título é a chave da linha do `campaign.md`, então o conserto muda as duas linhas no mesmo commit. | `TODO.md` (o item do ato `review`), `campaign.md` (lista do L5b) |

## Incrementos de conserto (R<n>)

Nenhum. Os seis achados são LOW e não movem a nota (régua da rodada: só um HIGH, ou um MEDIUM de
confiança, abre `R<n>`). Vão num lote ao chore pós-merge do L2, cuja rodada os confere, como os LOW
da r3 vieram a este.

## O que virou incremento

Nenhum `R<n>` nesta rodada. O que a rodada conferiu sobre os 4 LOW da r3:

- **LOW #1 da r3** (`git status` sem `GIT_OPTIONAL_LOCKS=0`) — fechado em `327710d`: o
  `sdd review-base` rodado no worktree deixa o `stat` do índice idêntico antes e depois, e o
  `find -newer` vazio no worktree, no git-dir dele e no common dir (fora `objects/`); mutante
  `RUN_review_base_status_locks_index`, morto pelo `check-gates.sh` (128 s).
- **LOW #2 da r3** (intervalo sem `core.quotePath=false`) — fechado em `b6f2885`: a grafia do
  `hat_diff_names`, com o stub do range-diff ajustado ao argv novo sem deixar a asserção passar pelo
  motivo errado (ela exige o texto do `GATE_WHY` do `review_head_ok`); mutante
  `REVIEW_head_range_quoted` (125 s).
- **LOW #3 da r3** (a quarta recusa na prosa) — fechado em `554b6ad`: ADR 0023 §4 ("four cases"),
  anatomia § 4, `docs/pipeline.md`, o verbete "Rodada delta" do `CONTEXT.md` e o
  `agents/sdd-reviewer.md`, com o espelho idêntico (`cmp`).
- **LOW #4 da r3** (o ramo "git status cannot say" sem cenário) — fechado em `f074df0`: stub que falha
  só aquele `status`, contra o mesmo mundo sem ele, que dá `base=`; mutante
  `RUN_review_base_status_failure_committed` (125 s).
- `TODO.md`: `a3d0b72` é ancestral de `origin/main` (`git merge-base --is-ancestor` rc 0);
  `todo-findings 98` no head e no base; a âncora `commands/sdd-worker.md:196` (`bring the base in`)
  está no alvo; `git diff --shortstat 87ca025...f6ea5fe` dá `30 files changed, 2086 insertions(+)`, e
  `git log --first-parent 64a5e5f..f6ea5fe` dá 12 commits, um deles o merge `59be5eb`; a lista do L5b
  tem 15 linhas e o `sdd-worker level` segue `full`.

## O que foi refutado

Nada a refutar: nenhum achado acima de LOW foi levantado.

## Achados fora de escopo

- **`bin/sdd-worker` (`pr-ready`, o `git status` da pasta da missão) roda sem `GIT_OPTIONAL_LOCKS=0`**:
  é a terceira leitura da classe do item aberto **O `sdd status --no-gates` roda o `git status` sem
  `GIT_OPTIONAL_LOCKS=0` sobre a run em voo**, depois do `session_leftovers` e do `review_base_line`.
  Pré-existente (`ecc2dee0`), não reproduzido como dano: o `pr-ready` roda depois da corrida, sem
  escritor esperado no worktree. Vai ao chore do L2, como uma linha na `Direção:` do item aberto.
- No corpo do PR #454, o comando `tests/check-mutation.sh --only <slug> tests/check-gates.sh` falha
  como escrito (rc 2, `the sensor is a file name under tests/`); a grafia certa é
  `--only <slug> check-gates.sh`, com a qual os três mutantes foram conferidos. Consertado no corpo.

## Pendências / Decisions for a Human

Nenhuma.
