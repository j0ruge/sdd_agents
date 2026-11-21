---
missao: 20261120-l2-o-sdd-plan-e-o-planner
fase: EXEC
status: done
sessao: 24fa924e-7e20-46ec-9272-8d91f0e5a90e
data: 2026-11-20 22:31
gate: "R1 (502ab59), da r1 da REVIEW: no ambiente da corrida (EFFORT_EXEC=xhigh e CLAUDE_EFFORT=xhigh exportados) tests/run-all.sh → suite green, rc=0, 0 linhas ^  FAIL, 2231 linhas ^  ok (22:10 → 22:30); na base da sessão (33c78db), o mesmo resultado (21:59 → 22:09); Check do R1 → 96 (era 0); check-checkpoint.sh rc 0, linha rule: --red --list com 35 probes, PROBE_FLOOR 447; sabotagem 9 de 10 mortos, o 10º é o piso de volta a 443, declarado; check-todo.sh --anchors → 105 measured, 0 off target. I7 (d48f7c9, 748bea0): no ambiente da corrida (EFFORT_EXEC=xhigh e CLAUDE_EFFORT=xhigh exportados) tests/run-all.sh → suite green, rc=0, 0 linhas ^  FAIL, 2231 linhas ^  ok (20:41 → 20:56, sobre o TODO.md com o RESOLVED by do I7); antes do d48f7c9, no mesmo ambiente, 2 suite(s) failed (gate-exec-test-20261120-200512-nriksi.log: check-dry-run e check-autonomy, só os 2 de ambiente); Check do I7 → 1 1; o do I6 → 15 (os 14 do I6 e o do I7); check-checkpoint.sh --check → 7 row(s), 6 under the anchor rule, none blind; check-todo.sh --check TODO.md → 103 finding(s), all within 8 lines, carrying anchor + date, every anchor on target, rc 0; --anchors → 103 measured, 0 off target. I6 (c0afc7ba): os seis Checks → 1 1 1 1 / 1 1 1 1 0 / 1 1 1 1 0 / 1 1 1 1 1 0 / 1 1 / 14; 14 of 14 títulos byte a byte iguais"
---

# Handoff — EXEC — L2: o `/sdd-plan` e o planner

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

Os seis incrementos do plano estão `done`: as 15 regras do `/sdd-plan` e do planner têm texto e
asserção, o `--red` ganhou `--list` e `--only`, e os 14 itens do `TODO.md` carregam `RESOLVED by`.
O I7, fora do plano, consertou os dois sensores que liam o `EFFORT_*` do ambiente (`d48f7c9`): a
suíte agora sai verde também com `EFFORT_EXEC=xhigh` exportado, que é como o `gate_EXEC` a roda.
O Check do I6 passou a responder `15` (os 14 e o do I7). A QA é no terminal.
Depois da r1 da REVIEW, o R1 (`502ab59`) fechou o achado #1: o `--red --only` recusa, com rc 96 e
antes de rodar qualquer Check, a lista de ids com espaço ou quebra de linha. A próxima é a r2.

## Estado do repo

- **Branch:** `fix/l2-o-sdd-plan-e-o-planner`, à frente de `origin/fix/l2-o-sdd-plan-e-o-planner` (nada empurrado nesta fase)
- **Último commit:** o deste handoff com o checkpoint; o do R1 é `502ab59` `fix(tests): o --red --only recusa a lista de ids com espaço ou quebra de linha`; os do I7 são `d48f7c9` e `748bea0` (o `RESOLVED by` do item)
- **Working tree:** limpo
- **Suíte:** `tests/run-all.sh` no ambiente da corrida (`EFFORT_EXEC=xhigh` e `CLAUDE_EFFORT=xhigh` exportados) → `suite green`, rc 0, 0 `FAIL`, 2231 linhas `ok`, no I7 (20:41 → 20:56) e de novo depois do R1 (22:10 → 22:30). Com `env -u EFFORT_EXEC -u CLAUDE_EFFORT` ela já saía verde no I6
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
| I7 | `d48f7c9` | o do `1c8de6a` | fora do plano: `tests/check-dry-run.sh` e `tests/check-autonomy.sh` limpam do próprio ambiente toda variável `EFFORT_*` antes do fixture; `RESOLVED by` em `748bea0` |
| R1 | `502ab59` | nenhum (achado #1 da r1) | o `red_args` recusa, com rc 96, a lista do `--only` que tem espaço, tab ou quebra de linha; 4 probes no selftest |

Fora dos incrementos, nesta fase: `1c8de6a` registrou no `TODO.md` o achado dos dois sensores que
leem o `EFFORT_*` do ambiente (catraca 102 → 103). Os commits `chore(checkpoint)` só fecham linhas.

### A volta do gate: o I7

O `gate_EXEC` reprovou depois do I6 (`TEST_CMD failed`, `gate-exec-test-20261120-200512-nriksi.log`):
a corrida roda com `EFFORT_EXEC=xhigh` exportado (pendência 10 do `00-missao.md`), o `load_config`
guarda a chave exportada quando o arquivo não a declara, e os dois sensores afirmavam "nenhum
`EFFORT_*` configurado" sobre um fixture que só apagava as chaves do config. O runner abriu o EXEC
sem linha `pending`, e o contrato do executor manda consertar a suíte quando é ela que o gate nomeia;
por isso a Pendência 1 do I6 não ficou para o humano.

- **O conserto (`d48f7c9`).** Os dois sensores, logo no topo, armam cinco `EFFORT_*` com `xhigh` e
  depois apagam toda variável de prefixo `EFFORT_` (`compgen -v EFFORT_`), no molde do
  `unset READ_EXTRA` que o `check-dry-run.sh` já tinha. O prefixo dispensa lista: uma chave de fase
  que o runner ganhar depois sai junto. O veneno armado é o que mede a limpeza em toda máquina.
- **A direção do item dizia "numa definição só", e o conserto são dois sítios iguais.** Um arquivo
  `tests/*.sh` novo, sourçado pelos dois, moveria o `LINT_FLOOR`, o piso do `check-pipefail.sh` e o
  fixture dele por duas linhas sem lista a sincronizar. A REVIEW pode discordar.
- **Sabotagem**, em ambiente limpo e com teto: sem a limpeza, 2 FAIL no `check-dry-run.sh` e 1 no
  `check-autonomy.sh`; com a limpeza estreitada a `unset EFFORT_EXEC`, 2 FAIL no primeiro e o segundo
  sobrevive, porque o par dele lê só a linha de EXEC e as outras chaves não movem asserção nenhuma.
- **O Check do I6 responde `15`.** Ele conta os `RESOLVED by` novos contra o merge-base, e o item do
  I7 é o 15º. A linha do I6 e o `df7b55e` ficaram como estavam.

No I6, seis itens (6, 9, 10, 11, 13 e 14) tinham a última linha do corpo cheia demais para o
`RESOLVED by` sem passar de 120 caracteres: a linha foi quebrada numa fronteira de frase, o token
fecha a nova última linha, nenhuma palavra do corpo mudou, e esses itens ficaram com 8 linhas, o
teto. Os outros oito levam o token no fim da linha que já existia.

### A r1 da REVIEW: o R1

O achado #1 da `40-review-r1.md` era um fail-open do `--red --only`. O `red_one` partia a lista com
`IFS=, read -ra`, que para na primeira linha, e o laço de execução casava contra a string inteira.
Por isso `--only $'I1\nI2'` validava só o I1, não rodava Check nenhum e saía com
`ok … 0 of 2 pending Check(s) run`, rc 0.

- **O conserto (`502ab59`).** Um ramo novo no `red_args`, `*[[:space:]]*`, recusa a lista com
  rc 96 e com a frase `no space or line break`, antes de o `red_one` abrir. A mensagem não ecoa a
  lista, porque a quebra de linha partiria a mensagem em duas. O espaço já era recusado antes, só
  que pelo nome do id e com rc 1. Agora entra na mesma recusa da gramática, como o R1 pedia.
- **Selftest.** São 4 probes novos: a quebra de linha, a quebra de linha sem rodar Check (pelo
  arquivo-testemunha), o espaço e o tab. O `PROBE_FLOOR` foi de 443 para 447.
- **Sabotagem**, com teto (grupo próprio, 180 s, 4 GB, restauração por `cp` num `finally`). Morreram
  9 de 10 mutantes: a classe estreitada a espaço, a quebra de linha ou `[[:blank:]]`, o ramo
  removido, a mensagem reescrita ou apagada, o ramo devolvendo 1 ou caindo no `red_one`, e um probe
  apagado (rc 92). Sobreviveu o `PROBE_FLOOR` de volta a 443, porque o piso é um mínimo. Quem mede o
  aperto dele é o mutante do probe apagado. Uma linha por mutante nas notas.
- O `TODO.md` não mudou: o achado #1 foi direto para o R1, sem item.

## Artefatos

| Arquivo | O que contém |
|---|---|
| `commands/sdd-plan.md` | as regras do relay (I1, I2, I3, I4, I5) |
| `agents/sdd-planner.md` e o espelho `.claude/agents/sdd-planner.md` | as regras do planner nos §§ 1, 2 e 4 e a chave `model: fable`; `cmp -s` rc 0 |
| `templates/plano.md` | o comando ao lado do fato medido e a mitigação que nomeia sensor |
| `docs/plan-only.md` | o que o `gate_EXEC` lê antes de uma missão executada à mão voltar ao `sdd run` |
| `tests/check-checkpoint.sh` | `--red --list`, `--red --only`, `probe_on`, `red_args` (com a recusa do R1); `PROBE_FLOOR` 447, `RULE_FLOOR` 10 |
| `tests/check-hat.sh` | 16 asserções novas (140 linhas `ok` hoje) |
| `tests/check-templates.sh` | 2 asserções do `plano.md` |
| `tests/check-dry-run.sh` e `tests/check-autonomy.sh` | o I7: o `EFFORT_*` do ambiente armado e limpo no topo |
| `TODO.md` | âncoras re-apontadas a cada incremento, `RESOLVED by` nos 14 itens, e o achado do `1c8de6a`, resolvido no I7 |
| `docs/handoffs/20261120-l2-o-sdd-plan-e-o-planner/checkpoint-notas.md` | Red, Green e sabotagem de cada incremento |

## Boot da próxima fase

**A próxima é a r2 da REVIEW, sobre o delta.** A r1 gravou `reviewed_head: 2fc48ac…`, e desde então
entraram o `33c78db` (a própria r1: o `40-review-r1.md`, o checkpoint, as notas, o `TODO.md` e a
catraca 103 → 105), o `502ab59` (o R1, só `tests/check-checkpoint.sh`) e o commit deste handoff.
O código do delta é um arquivo:

1. O Check do R1: `bash tests/check-checkpoint.sh --red docs/handoffs/20261120-l2-o-sdd-plan-e-o-planner/checkpoint.md --only $'R1\nR1' >/dev/null 2>&1; echo $?`
   → `96`. Com a linha R1 `done`, o `--only R1` puro sai 93 (não há linha `pending`). É a recusa
   do `red_args`, que roda antes do `red_one` e não depende do checkpoint.
2. `bash tests/check-checkpoint.sh; echo $?` → `0`, com a linha
   `ok    rule: --red --list runs no Check, and --red --only never says every one red at HEAD (35 probe(s))`.
3. O que olhar no diff do `502ab59`: o ramo `*[[:space:]]*` vem depois do de lista vazia e do `-*`,
   e a frase dele não ecoa o valor. Os 4 probes ficam logo abaixo do `with an empty id`, sobre o
   fixture de I1 e I2 `pending`. O comentário do código de saída 96 (`:402`) foi reescrito sem mudar
   o número de linhas, e por isso as âncoras `:1573` e `:1634` do `TODO.md` não se moveram.

A jornada da QA, que já rodou verde e sem achados, fica no `30-handoff-qa.md`. Os passos abaixo são
os que ela percorreu, e continuam valendo para quem quiser reproduzi-la:

1. **A suíte, no ambiente que a QA herdar.** Desde o I7 ela sai verde com ou sem `EFFORT_*`
   exportado; registre no relatório o que `env | grep -E '^(EFFORT_|CLAUDE_EFFORT)'` mostrou e o
   resultado de `tests/run-all.sh` (cerca de 15 min nesta máquina, 20:41 → 20:56 no I7).
2. Os sete Checks do `checkpoint.md`, um a um. Seis imprimem o esperado da célula; o do I6 imprime
   `15`, não `14`, porque o item do I7 é o 15º `RESOLVED by` novo da branch (seção "A volta do
   gate: o I7"). O do I7 leva uns 5 min, porque roda o `check-autonomy.sh` inteiro.
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

- **Aceitar o I7, que não estava no plano.** Ele toca `tests/check-dry-run.sh` e
  `tests/check-autonomy.sh`, fora dos arquivos da missão, porque o `gate_EXEC` não fecharia de outro
  jeito sem relançar a corrida sem a variável do teste de effort (pendência 10). O corpo do PR deve
  listá-lo ao lado das escolhas da pendência 3 do `00-missao.md`. A Pendência 1 do I6 (consertar
  os sensores ou relançar) está fechada pelo `d48f7c9`.
- **O item do `TODO.md` do I7 entra no chore de depois do merge** com os outros 14: tem
  `RESOLVED by d48f7c9`, e a catraca segue em 103 até lá.
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
  vermelha sob `EFFORT_EXEC=xhigh`"). Consertado no I7 (`d48f7c9`), `RESOLVED by` em `748bea0`.
- No I6 e no I7, nenhum achado novo. A mesma classe vale para qualquer chave de config exportada
  sobre um fixture que afirma a ausência dela; hoje só o `READ_EXTRA` e o `EFFORT_*` têm limpeza, e
  nenhuma outra asserção medida reprova por isso. Não virou item: não há defeito medido.
