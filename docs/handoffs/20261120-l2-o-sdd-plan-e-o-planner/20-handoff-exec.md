---
missao: 20261120-l2-o-sdd-plan-e-o-planner
fase: EXEC
status: done
sessao: c0afc7ba-4721-4cc3-b270-3a41bfa9b30e
data: 2026-11-20 20:03
gate: "I6: env -u EFFORT_EXEC -u CLAUDE_EFFORT tests/run-all.sh → suite green, rc=0, 0 linhas ^  FAIL, 2231 linhas ^  ok (19:51, sobre o TODO.md do I6); no ambiente da corrida (EFFORT_EXEC=xhigh e CLAUDE_EFFORT=xhigh exportados) tests/run-all.sh → 2 suite(s) failed, rc=1, só check-dry-run (with no EFFORT_* configured, no phase carries --effort) e check-autonomy (covered: the journal records effort=settings…), os mesmos 2 de ambiente do I1 (TODO.md, 1c8de6a); os seis Checks do checkpoint → 1 1 1 1 / 1 1 1 1 0 / 1 1 1 1 0 / 1 1 1 1 1 0 / 1 1 / 14; check-todo.sh --check TODO.md → 103 finding(s), all within 8 lines, carrying anchor + date, every anchor on target, rc 0; --anchors → 103 measured, 0 off target; 14 of 14 títulos byte a byte iguais"
---

# Handoff — EXEC — L2: o `/sdd-plan` e o planner

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

Os seis incrementos estão `done`: as 15 regras do `/sdd-plan` e do planner têm texto e asserção, e
o `--red` ganhou `--list` e `--only`. As 19 asserções novas estão verdes e os 14 itens do `TODO.md`
carregam `RESOLVED by`. ⚠️ A suíte só fica verde **sem** o `EFFORT_EXEC`/`CLAUDE_EFFORT` exportado:
no ambiente desta corrida ela sai com 2 FAIL de ambiente (`check-dry-run`, `check-autonomy`), e o
`gate_EXEC` os lê. A decisão é do humano (Pendência 1); a QA é no terminal.

## Estado do repo

- **Branch:** `fix/l2-o-sdd-plan-e-o-planner`, à frente de `origin/fix/l2-o-sdd-plan-e-o-planner` (nada empurrado nesta fase)
- **Último commit:** o deste handoff com o checkpoint; o do incremento é `df7b55e` `docs(todo): RESOLVED by nos 14 itens do L2, cada um com o hash do incremento que o fechou`
- **Working tree:** limpo
- **Suíte:** `tests/run-all.sh` → com `env -u EFFORT_EXEC -u CLAUDE_EFFORT`: `suite green`, rc 0, 0 `FAIL`, 2231 linhas `ok`. No ambiente da corrida: `2 suite(s) failed`, rc 1, só os 2 de ambiente
- **E2E:** `E2E_CMD` vazio: o kit não tem interface

## O que foi feito

| Incremento | Commit | Itens do `TODO.md` | O quê |
|---|---|---|---|
| I1 | `256e9d4` | 3, 7, 8, 11 | o "Before anything else" do `/sdd-plan` lê árvore, branch, missões em disco e dono do checkout, com três saídas; a vigia de `status` e `HEAD` a cada devolução vale também sem worktree |
| I2 | `9bea822` | 2, 6, 9, 13 | o grill dos dois lados: retomar o mesmo planner pelo id quando a sessão do relay cai, a pergunta repetida por job em background, a contagem das marcas a cada devolução, a resposta delegada por escrito |
| I3 | `96d1bc5` | 4, 5, 10 | o aceite: amostra dos comandos do contexto verificado, o ramo `auto` do passo 4, o `git status` inteiro; o planner grava o comando ao lado de cada contagem (`templates/plano.md`) |
| I4 | `8a21366` | 1, 12, (15) | o planner roda o sensor que uma mitigação nomeia, escreve o passo do `20-handoff-exec.md` em plano executado fora do `sdd run` (`docs/plan-only.md`), e declara `model: fable` no frontmatter |
| I5 | `972a482` | 14 | `--red <cp> --list` e `--red <cp> --only <ids>` no `tests/check-checkpoint.sh`, com 31 probes e a linha `rule:` do selftest; o "Measure again" procura `sdd run` vivo antes do `--red` |
| I6 | `df7b55e` | os 14 | `RESOLVED by <hash>` em cada item, com o hash do incremento que o fechou |

Fora dos incrementos, nesta fase: `1c8de6a` registrou no `TODO.md` o achado dos dois sensores que
leem o `EFFORT_*` do ambiente (catraca 102 → 103). Os commits `chore(checkpoint)` só fecham linhas.

No I6, seis itens (6, 9, 10, 11, 13 e 14) tinham a última linha do corpo cheia demais para o
`RESOLVED by` sem passar de 120 caracteres: a linha foi quebrada numa fronteira de frase, o token
fecha a nova última linha, nenhuma palavra do corpo mudou, e esses itens ficaram com 8 linhas, o
teto. Os outros oito levam o token no fim da linha que já existia.

## Artefatos

| Arquivo | O que contém |
|---|---|
| `commands/sdd-plan.md` | as regras do relay (I1, I2, I3, I4, I5) |
| `agents/sdd-planner.md` e o espelho `.claude/agents/sdd-planner.md` | as regras do planner nos §§ 1, 2 e 4 e a chave `model: fable`; `cmp -s` rc 0 |
| `templates/plano.md` | o comando ao lado do fato medido e a mitigação que nomeia sensor |
| `docs/plan-only.md` | o que o `gate_EXEC` lê antes de uma missão executada à mão voltar ao `sdd run` |
| `tests/check-checkpoint.sh` | `--red --list`, `--red --only`, `probe_on`, `red_args`; `PROBE_FLOOR` 443, `RULE_FLOOR` 10 |
| `tests/check-hat.sh` | 16 asserções novas (140 linhas `ok` hoje) |
| `tests/check-templates.sh` | 2 asserções do `plano.md` |
| `TODO.md` | âncoras re-apontadas a cada incremento, `RESOLVED by` nos 14 itens, e o achado do `1c8de6a` |
| `docs/handoffs/20261120-l2-o-sdd-plan-e-o-planner/checkpoint-notas.md` | Red, Green e sabotagem de cada incremento |

## Boot da próxima fase

A QA desta missão é **no terminal**: o kit não tem interface, e `qa:` do `00-missao.md` está vazio,
então o `sdd-qa` percorre a jornada da seção "Verificação end-to-end" do `01-plano.md`, em ordem:

1. **Antes de qualquer suíte, o ambiente.** Se `env | grep -E '^(EFFORT_|CLAUDE_EFFORT)'` mostrar
   alguma variável, a suíte sai com os 2 FAIL de ambiente do `TODO.md` (`1c8de6a`), que não são
   desta missão. A medida que vale é `env -u EFFORT_EXEC -u CLAUDE_EFFORT tests/run-all.sh`
   (cerca de 11 min nesta máquina); registre as duas no relatório, sem misturá-las.
2. Os seis Checks do `checkpoint.md`, um a um (cada um imprime o esperado da célula).
3. O espelho e o frontmatter: `cmp -s agents/sdd-planner.md .claude/agents/sdd-planner.md; echo $?`
   → `0`, e `git diff origin/main -- agents/sdd-planner.md` mostra no frontmatter só a linha
   `model: fable`.
4. **A jornada do `--red`**, a parte que um usuário toca: num repositório descartável (`mktemp -d`,
   `git init`, um `checkpoint.md` com duas linhas `pending`, uma com Check que cria um arquivo),
   `tests/check-checkpoint.sh --red <cp> --list` lista as duas e não cria o arquivo;
   `--red <cp> --only I1` roda só a I1 e termina em `1 of 2 pending Check(s) run, each red at HEAD;
   1 not run — a partial measure`; `--red <cp>` roda as duas e termina em
   `2 pending Check(s), every one red at HEAD`. A gramática está no cabeçalho de uso do sensor
   (`--list` e `--only <id>[,<id>…]`).
5. A leitura do passo 1 do "Before anything else" do `commands/sdd-plan.md`: cada um dos quatro
   comandos que ele nomeia responde neste worktree (`sdd status --no-gates <missão>` pede o nome de
   uma missão de `docs/handoffs`).
6. `bash tests/check-todo.sh --check TODO.md` → rc 0, e os 14 títulos da tabela do `00-missao.md`
   seguem no arquivo, um de cada.

O que é visível ao usuário no diff: as frases novas do `/sdd-plan` (o relay) e do chapéu do planner,
a chave `model: fable`, e os dois modos do `--red`. Nenhuma linha do `bin/sdd` nem do `bin/sdd-worker`
mudou.

## Pendências / Decisions for a Human

- **O `gate_EXEC` desta corrida lê a suíte vermelha, por ambiente.** A corrida foi lançada com
  `EFFORT_EXEC=xhigh` exportado (pendência 10 do `00-missao.md`, a variável do teste de effort), e
  dois sensores leem a variável do ambiente de quem chama: `tests/check-dry-run.sh`
  (`with no EFFORT_* configured, no phase carries --effort`) e `tests/check-autonomy.sh`
  (`covered: the journal records effort=settings…`). Sem a variável, rc 0. Duas saídas, as duas do
  humano: consertar os dois sensores (a direção está no item do `TODO.md`, `1c8de6a`; é `tests/`,
  fora do escopo desta missão) ou relançar sem a variável exportada, o que põe em `medium` qualquer
  incremento `F`/`R` que a QA ou a REVIEW abrirem e muda a variável medida.
- As pendências 1 a 10 do `00-missao.md` seguem como estão; nenhuma foi fechada nesta fase.

## Riscos e não-feitos

- A seção Métrica do `00-missao.md` diz que a catraca fica em 92; ela está em **103**, e a diferença
  é medida, não deriva: a `main` trouxe 98 no merge `20ada71` (o planner tinha contado 91 sobre
  `336640e`), os dois commits de achado antes da corrida somaram 4 (`a30076d` 91 → 92, `b91d13d` 92 → 95), e o `1c8de6a` desta fase
  somou 1. O `tests/health-baseline.txt` diz 103 e o `check-todo.sh --count` também. O I6 não tocou
  na catraca, como o plano manda.
- Que o `model: fable` do chapéu faz o subagente abrir em Fable não foi medido: é a pendência 4 do
  `00-missao.md`, para a primeira `/sdd-plan` depois do merge. As asserções provam o arquivo.
- As regras novas só valem depois do merge (pendência 5): o `/sdd-plan` e o chapéu que o harness
  carrega vêm do checkout principal.
- O `./bin/sdd health` (carimbo de mutação) não rodou, por regra do dono (pendência 7).

## Achados fora de escopo

- Dois sensores leem o `EFFORT_*` do ambiente de quem chama → `TODO.md`, seção `<!-- sdd:open -->`,
  `1c8de6a` (item "Dois sensores leem o `EFFORT_*` do ambiente de quem chama, e a suíte fica
  vermelha sob `EFFORT_EXEC=xhigh`").
- No I6, nenhum achado novo.
