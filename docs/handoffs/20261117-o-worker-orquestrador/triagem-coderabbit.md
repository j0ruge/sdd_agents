# Triagem dos 16 threads do CodeRabbit no PR #414

Os threads saíram da revisão do CodeRabbit sobre o `f8e3e02`, às 14:38Z de 2026-11-19, e a triagem os
conferiu no `7555d22`, o head que foi mergeado. A decisão do dono, às 13:30: mergear sem mudar código e
levar os achados reais ao `TODO.md` num PR de chore logo depois do merge, pela régua D15. Os números de
linha abaixo são os do `7555d22`; as âncoras vivas moram nos itens do `TODO.md`.

## Destino de cada item, no chore pós-merge

- **`TODO.md`** (11 itens): 1, 2, 3, 5, 6, 7, 8, 9, 12, 13 e 16.
- **Consertados no chore, que são só prosa:** o 10 (`45-docs.md`) e o 11 (`docs/pipeline.md`).
- **Limite declarado no cabeçalho do `tests/check-worker.sh`:** o 15, que falha fechado e só tem
  consumidor dentro da suíte, então não passa na D15.
- **Já fechados antes da triagem:** o 4, consertado pelo R21 (`b671a31`), e o 14, já declarado no
  cabeçalho do `lots_of`.

## A triagem

| # | id | arquivo:linha | CR | classe | régua | tamanho | evidência |
|---|----|---------------|----|--------|-------|---------|-----------|
| 1 | 4630262622 | bin/sdd-worker:333 | Major | REAL | ALTA | pequeno | `printf -v` no subshell de `config_key` não exporta; reproduzido: filho vê `[]`, com `export K=` antes vê `[40]` |
| 2 | 4630262634 | bin/sdd-worker:487 | Major | REAL | BAIXA | pequeno | `expired` só roda antes de `campaign_set`/`checkouts_of`; janela de ms, não reproduzida; o laço pergunta `allows` antes de cada ato |
| 3 | 4630262642 | bin/sdd-worker:611 | Major | REAL | ALTA | médio | `git worktree list --porcelain` (2.43) imprime o `\n` do caminho cru (`worktree …/wt` + linha `nl`); `sed 's/^worktree //p'` corta o caminho |
| 4 | 4630262654 | bin/sdd-worker:724 | Major | JÁ-CONSERTADO | - | - | R21: `dir_normalise hd` e `dir_normalise whd` antes do `!=` (linhas 714-722) |
| 5 | 4630262663 | bin/sdd-worker:901 | Minor | REAL | BAIXA | pequeno | `gh pr list --head … --state all` sem `--limit` (padrão 30); sem TODO que o cubra |
| 6 | 4630262670 | bin/sdd-worker:1100 | Major | REAL | ALTA | médio | os 3 awks fazem `$0 !~ /^[ \t]*\|/ { next }` e seguem lendo após linha em branco; paridade com `gate_REVIEW` do `bin/sdd` |
| 7 | 4630262684 | commands/sdd-worker.md:77 | Major | REAL | BAIXA | pequeno | "the yes stands for this step's rc 0" não amarra o sha do merge; prosa (o dono pode elevar) |
| 8 | 4630262694 | commands/sdd-worker.md:227 | Major | REAL | BAIXA | pequeno | `postmerge`: "the journal line of the merge names it", sem exigir nº do PR nem estado da revisão |
| 9 | 4630262703 | commands/sdd-worker.md:247 | Minor | REAL | BAIXA | pequeno | `why="$(sdd-worker budget …)"` roda `budget` de novo; o teto pode ter subido |
| 10 | 4630262723 | docs/handoffs/…/45-docs.md:194 | Minor | REAL | BAIXA | pequeno | checklist já diz ✅ em `48b6bc3` (`0976b0d`); "Boot da próxima fase" e a pendência 1 ainda mandam aplicar as 2 linhas ⛔ |
| 11 | 4630262739 | docs/pipeline.md:1829 | Minor | REAL | BAIXA | pequeno | "worktree that holds a mission" é lido no `HANDOFF_DIR` da raiz (`$wt/$hd`); a prosa de 2097 diz que o outro fica fora; o código é coerente, a frase é imprecisa |
| 12 | 4630262752 | templates/delegation.md:74 | Major | REAL | ALTA | grande | `config_reload` restaura o env e re-sourceia o arquivo; `BUDGET_MISSION_USD=0` desabilita (`mission_budget_blown`, bin/sdd:6091); nenhum limite declarado o lista |
| 13 | 4630262767 | tests/check-mutation.sh:7168 | Minor | REAL | BAIXA | pequeno | o mutante troca só `anc -eq 1`; `anc != 0` (1306) ainda recusa, então só a mensagem muda |
| 14 | 4630262784 | tests/check-templates.sh:182 | Minor | DECIDIDO | - | - | limite declarado (D15) no cabeçalho de `lots_of`, linhas 161-165 ("header matched on any line, the reader takes its first line") |
| 15 | 4630262805 | tests/check-worker.sh:1444 | Minor | REAL | BAIXA | pequeno | `sed -e "s\|<SDD_HOME>\|$ROOT\|g"` com `\|` em `$ROOT` quebra; sem checagem do `sed` antes do `budget_is` |
| 16 | 4630262815 | tests/check-worker.sh:1902 | Minor | REAL | BAIXA | médio | probes editam o disco sem `land`; `ready_is` casa só `not-ready review: `; o `dirty` (1335) também reprova, então grade frouxo passaria |

## REAL

**1 (ALTA, pequeno).** `config_key` faz `printf -v "$key"` num subshell: sem export prévio, um config que escolhe o teto num `bash -c`/`$(…)` enxerga vazio e cai nos 150 enquanto o `sdd run` recebe o 40 exportado. Reproduzido com `bash -c` (acima). Conserto: `export "$key"` depois do `printf -v` e antes de sourcear. Contrived (config que lê o env de um filho), mas é verbo `budget`.

**2 (BAIXA, pequeno).** Reler `expired "$exp"` antes de publicar `LEVEL` acima de `assisted`, inclusive no retorno do teto do lote (`effective_level`, ~linha 487). Não reproduzido: a janela é a de `campaign_set` (ms) e o laço de `commands/sdd-worker.md` pergunta `allows` antes de cada ato.

**3 (ALTA, médio).** `checkouts_of` lê `worktree list --porcelain` sem `-z`; reproduzido em git 2.43 com worktree `wt\nnl`: o caminho vira `…/wt` e sobra uma linha solta. A missão desse worktree some do `budget`, do `level` e do `next`. Conserto: `--porcelain -z`, ler por NUL, manter o rc. Exige `-z` (git 2.36+), então decidir a versão mínima do git. Rarissímo na prática.

**5 (BAIXA, pequeno).** `pr_states` filtra `isCrossRepository` depois de o `gh` cortar em 30. Conserto: `--limit 1000`, ou parar com veredito não lido quando a contagem bate o limite.

**6 (ALTA, médio).** `round_grades`, `round_unjustified` e `round_missing` pulam linha em branco e continuam lendo, então um Security depois de uma linha em branco conta. O comentário diz "read as the runner's gate_REVIEW reads it": o runner tem o mesmo comportamento, então consertar só o worker quebra a paridade (que um sensor segura). Conserto: parar no primeiro não-linha depois da primeira linha da tabela, no `GRADE_ROW_AWK` dos três e no runner, com probe nos dois.

**7 (BAIXA, pequeno).** Passo 3 do loop: o yes vale para o ato, não para o sha. O `pr-ready` ainda exige rodada A e recibo do Codex no head B, então o risco é o dono não ter aprovado o B. Conserto em prosa: o yes só se reaproveita com campanha, lote, missão, PR e comando iguais, e no merge o sha também.

**8 (BAIXA, pequeno).** § `postmerge`: exigir que a linha do journal do merge traga o nº do PR de acompanhamento e `review pendente`, e que a sessão retomada o conclua antes do `next`.

**9 (BAIXA, pequeno).** § paradas: capturar a saída do `budget` no momento da parada (arquivo ou variável do mesmo lote) e reusar no journal e no `SDD_GATE_WHY`, em vez de rodar `budget` de novo.

**10 (BAIXA, pequeno).** Em `45-docs.md`, trocar o "Boot da próxima fase" e a pendência 1 pelo estado feito (aplicado em `48b6bc3`).

**11 (BAIXA, pequeno).** `docs/pipeline.md:1827`: dizer "that holds a mission of the campaign at the root's HANDOFF_DIR" e remeter ao parágrafo de 2097.

**12 (ALTA, grande).** Uma edição de `.sdd/config.sh` durante a fase vale para as voltas seguintes (`config_reload`, `bin/sdd`, documentado em `anatomia-do-agente.md` §6): `BUDGET_MISSION_USD=0` apaga o teto. O `budget` só roda entre atos e ninguém relê o teto assinado durante a corrida. Conserto mínimo: declarar o limite em `bin/sdd-worker` e no template (pequeno). Conserto de verdade: o runner mantém o teto vindo do ambiente do lançamento, o que muda a precedência do `config_reload` e é decisão do dono. Exige agente que edite o config, então a probabilidade é baixa.

**13 (BAIXA, pequeno).** O mutante `mut_WORKER_range_ancestry_unchecked` deve trocar também `"$anc" -ne 0` por `-gt 1`, de modo que o rc 1 seja admitido e o rc ≥ 2 siga recusado. Prove com `tests/check-mutation.sh --only range_ancestry_unchecked tests/check-worker.sh`.

**15 (BAIXA, pequeno).** Passar `$ROOT` por `awk`/`ENVIRON` ou escapar o delimitador no `sed`, e conferir o rc da geração do config antes de chamar `budget_is`.

**16 (BAIXA, médio).** O grade (1270) vem antes do dirty (1335), então os três probes de grade e o de tabela ausente passariam por "not committed" se o grade aceitasse B ou A-. Conserto: `land` depois de cada edição e exigir o texto `grades B` / `has no row for`, como o probe de `deadbeefdead` faz.
