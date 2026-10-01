---
missao: 20261001-a-janela-nao-se-parte
fase: DOCS
status: done
sessao: n/a (sessão do sdd-docs lançada pela sessão coordenadora, fora do sdd run)
data: 2026-10-01
gate: bash tests/check-todo.sh → "ok    87 finding(s) … every anchor on target"; bash tests/check-lang.sh → "0 of 56 surface path(s) still in the allowlist, 0 new"; bash tests/check-adr.sh → "adr traceability: 73 probes"
---

# Documentação — 20261001-a-janela-nao-se-parte

## TL;DR

Cinco documentos ainda descreviam o mundo de antes da ADR 0014: a chave do carimbo como o conteúdo
inteiro de `bin/ tests/ templates/ config/` e a catraca invalidando o carimbo (`CLAUDE.md`,
`README.md`, `docs/pipeline.md`, `docs/failure-modes.md`, `CONTEXT.md`), e o eixo do juiz como o
`kit_sha` cru com a válvula "o agente interpreta" (`CONTEXT.md`, D4). Todos consertados em
`16177c9`, `35d4155` e `f0b5e8c`; o one-liner de conferência do `failure-modes.md` dava resposta
errada e foi trocado pela listagem do `mutation_stamp_key`. Verbete novo **Versão de comportamento**
no `CONTEXT.md` e entrada medida no `KAIZEN_LOG.md`. Nenhum `⛔`: nenhuma frase da
`.claude/rules/anatomia-do-agente.md` descreve a chave do carimbo nem o eixo do juiz.

## Drift checklist

| Area touched by the diff | Corresponding document | Status | Evidence |
|---|---|---|---|
| `bin/sdd` (`mutation_stamp_key`, `mutation_stamp_why`, `gate_PR`: chave rastreada menos a catraca, quatro caminhos obrigatórios) | `docs/pipeline.md` | ✅ | requisito do carimbo no `gate_PR` reescrito em `16177c9`, condensado em `35d4155` |
| `bin/sdd` (chave do carimbo, motivos de chave vazia, `warn` do kit sem git) | `docs/failure-modes.md` | ✅ | verbete "no green mutation catalogue" com o 4º estado, verbete "`sdd health` ran three times" com o one-liner `git ls-files -c` e o fim da colisão da catraca, em `16177c9` |
| `bin/sdd` (chave do carimbo) | `README.md` | ✅ | parágrafo "In the kit repo it is also a gate" (chave rastreada, catraca fora, link da ADR 0014) em `16177c9` |
| `bin/sdd` (chave do carimbo: consequência operacional) | `CLAUDE.md` | ✅ | o parágrafo "Consequência operacional" dizia que a catraca matava o carimbo — falso desde `89d8e62`; reescrito em `f0b5e8c` |
| `bin/sdd` (`autonomy_kit_stamp` + quatro escritores: `kit_rev`/`kit_rev_dirty`) | `docs/pipeline.md` | ✅ | field reference e narrativa do eixo em `85039c7` (commit do escritor) |
| `bin/sdd` (`ledger_kit_version_defs` nos dois leitores, `kit_shas_raw`) | `docs/pipeline.md` | ✅ | "Both readers group escalations on the same axis" ganhou a versão de comportamento em `16177c9`; âncora obsoleta `bin/sdd:4929` → `comparable_row` no mesmo commit |
| `bin/sdd` (termos novos: versão de comportamento, caminhos de comportamento, sha cru, chave rastreada) | `CONTEXT.md` | ✅ | verbete novo "Versão de comportamento"; Veredito, Série, Carimbo de mutação, Eixo degenerado, Janela de medição e D4 emendados em `f0b5e8c` |
| `bin/sdd` (antes/depois medido) | `KAIZEN_LOG.md` | ✅ | entrada "A janela não se parte" com o par `5b98087` → `6323c6f` medido em worktrees limpos (eixo 2 fatias → 1; chave `27c54e9d` ≠ `e6d16990` → `57ba9896` = `57ba9896`) em `f0b5e8c` |
| `bin/sdd` (componentes verificação, memória e sandbox da anatomia) | `.claude/rules/anatomia-do-agente.md` | n/a | as duas menções a carimbo na rule (§4 "catálogo de mutação com carimbo no `sdd health`", §6 o incidente das 18:45) seguem verdadeiras, e nenhuma frase dela descreve a chave do carimbo, o `kit_sha` ou o eixo do juiz (`grep -n 'kit_sha\|kit_dirty\|carimbo\|stamp'`) |
| `bin/sdd` (chaves de config) | `config/schema.md` | n/a | nenhuma chave de config nova: `KIT_BEHAVIOR_PATHS`, `MUTATION_STAMP_PATHS` e `MUTATION_STAMP_EXCLUDE` são `readonly` do runner, e o arquivo não cita `kit_sha` nem a chave do carimbo |
| `agents/sdd-kaizen.md` | `.claude/agents/sdd-kaizen.md` | ✅ | §1 e §2 (eixo de comportamento, `kit_shas_raw`) em `eedc6d3`; `cmp` dos dois arquivos sem diferença |
| `docs/adr/0014-a-identidade-do-kit-e-o-que-ele-executa.md` | `docs/adr/0003-judge-axis-evidence-from-target-repos.md` | ✅ | `Amended by: 0014` em linha própria em `915008b`; a 0014 fica `proposed` até o humano virar no merge |
| `docs/superpowers/specs/2026-09-23-a-gaveta-do-kit.md` | — | n/a | o índice da gaveta foi atualizado no commit do plano `05321f3` (decisão 8 do grill), que é a regra do `CLAUDE.md` para frente que nasce |
| `tests/check-autonomy.sh`, `tests/check-kaizen.sh`, `tests/check-gates.sh`, `tests/check-health.sh` | — | n/a | asserções `kit_rev:`, `kit-version:`, `stamp-key:` e `stamp:`; nenhum doc enumera as asserções de um sensor, e o censo de sensores segue 16 (`ls tests/check-*.sh`) |
| `tests/check-mutation.sh` | — | n/a | mutantes novos (515 → 532 âncoras); o `CLAUDE.md` manda ler o número da linha `score:` e nunca o fixa |
| `TODO.md` | — | n/a | quatro `RESOLVED by` e uma linha decidida em `c9820de`; entradas conferidas na seção abaixo |
| `docs/handoffs/20261001-a-janela-nao-se-parte/*` | — | n/a | artefatos da própria missão, que são a fonte, não o alvo, do drift |

## Achados do `TODO_FILE` conferidos nesta missão

`bash tests/check-todo.sh --check TODO.md` → `ok    87 finding(s), all within 8 lines, carrying
anchor + date, every anchor on target`, rodado depois de `f0b5e8c`.

- Nenhum achado novo nasceu nesta missão (a catraca segue 87); o executor remapeou por conteúdo as
  âncoras que cada incremento deslocou.
- Os quatro itens fechados (#107 `RESOLVED by 162e923`, #119 e #117 `RESOLVED by 89d8e62`, a ruptura
  da janela `RESOLVED by eedc6d3`) estão bem formados e seguem abertos até o merge, como manda o
  template; o apagamento é do chore pós-merge, provado por `git merge-base --is-ancestor`.
- A linha decidida **Aviso de merge durante a janela do juiz** está sob `<!-- sdd:decided -->`, em uma
  linha, com a evidência (`docs/adr/0014`, missão, data).
- O item da âncora `docs/pipeline.md:1003` (seções longas do `pipeline.md`) quase saiu do alvo com o
  primeiro texto desta fase (`16177c9` empurrou `## The autonomy ledger` para a linha 1019); o
  parágrafo foi condensado em `35d4155` e a âncora voltou a valer sem tocar o `TODO.md`, que não
  está no `writes:` deste chapéu.

## Pendências / Decisions for a Human

- Virar o `Status` da ADR 0014 de `proposed` para aceito no merge (decisão do humano, não da DOCS).
- Rodar `./bin/sdd health` uma vez antes do `gate_PR`: nenhum commit desta fase tocou `bin/ tests/
  templates/ config/`, então a chave não se moveu por causa dela.

## Riscos e não-feitos

- Entre `16177c9` e `35d4155` o `check-todo.sh` esteve vermelho (âncora fora do alvo); a ponta da
  branch está verde. Não rodei o `tests/run-all.sh` completo: esta fase não tocou nenhum dos quatro
  diretórios medidos, e os três sensores que leem os arquivos editados (`check-lang.sh`,
  `check-todo.sh`, `check-adr.sh`) estão verdes.
- O `docs/pipeline.md` ainda chama de "`kit_sha` slice" as fatias em vários parágrafos (1216–1496);
  a chave de saída continua `kit_sha` (agora guardando a versão), e o parágrafo dos leitores diz que
  toda fatia abaixo é lida nesse eixo — não reescrevi as ocorrências uma a uma.
