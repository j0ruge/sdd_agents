---
missao: 20260817-catraca-do-backlog
fase: QA
status: done
sessao: 31ecbac9-a07d-4e40-8051-70b5b725376a
data: 2026-08-17 21:55
gate: "**7 jornadas caminhadas à mão, todas no terminal — o kit não tem interface.** `tests/run-all.sh` → rc 0, `suite green`, `score: 81 caught, 0 known gap(s), of 81`, **533** asserções `ok`, `  ok    73 finding(s)`, 3m29s. `./bin/sdd health` no repo íntegro → rc 0 e os **5** checks verdes mais `kit healthy`: `suite green`, `mutation: score: 81 caught, 0 known gap(s), of 81`, `all 8 gates have a mutation in the catalogue`, `provenance: all 3 fixtures match the installed skills`, `ratchet: 7 known debt(s), none new`. **Métrica 1 caminhada nos DOIS sentidos, e num deles pela primeira vez.** Sentido faxina (baseline 72 contra 73 reais) → rc 1 com as duas mensagens: `fail  finding outside the baseline: todo-findings 73` **e** `fail  stale baseline: 'todo-findings 72' is no longer a finding — delete the line`. Sentido crescimento, que o EXEC nunca andou (item novo no `TODO.md`, baseline parada em 73) → `tests/check-todo.sh` passa a imprimir `  ok    74 finding(s)` — **a contagem é VIVA, ela seguiu o arquivo** — e `./bin/sdd health` → rc 1 com `fail  finding outside the baseline: todo-findings 74` **e** `fail  stale baseline: 'todo-findings 73' …`. As três caminhadas do `health` rodaram numa **cópia descartável** do kit em `/tmp/qa-kit` (o `SDD_HOME` é resolvido do caminho do próprio script), então a árvore real nunca foi tocada — provado por `git status --short` limpo antes e depois. `./bin/sdd autonomy` → coluna de dinheiro **0** células fora de duas casas, ordem por primeira aparição no arquivo e não lexicográfica, e a aritmética do cabeçalho fecha (76 linhas do ledger − 11 de outro repo = 65; 65 − 2 não-comparáveis = 63 exibidas). Os dois `die` do ledger são **diferenciais** (`malformed row … the ledger is not readable` × `unreadable row … valid JSON but not an object`), e o bloco no-data fala com **uma** voz nos dois caminhos. Métrica 2 re-derivada por conta própria: **1** sensor executa `cmd_health` (`tests/check-health.sh:168`), todo o resto é comentário. Métrica 4: os **10** hashes `RESOLVIDO por` verificados um a um com `git merge-base --is-ancestor` → 10 de 10 ancestrais de HEAD. **0 achados novos, 0 incrementos de fix, 0 specs novas.**"
---

# Handoff — QA — a catraca do backlog

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

7 jornadas caminhadas à mão, **0 achados confirmados novos**, logo **0 specs novas** e **0
incrementos de fix** — a tabela do `checkpoint.md` continua com 5 linhas, sem `F<n>`. As duas
superfícies visíveis (`sdd health` e `sdd autonomy`) entregam o que o EXEC prometeu. O QA fechou
uma lacuna de evidência: o EXEC provou a catraca **movendo a baseline**, mas ninguém tinha provado
que a contagem é **viva** — a jornada do sentido crescimento (item novo no `TODO.md`) foi andada
aqui pela primeira vez e passa. **2 pendências vão ao humano, herdadas do EXEC; nenhuma bloqueia.**

## Como esta fase foi rodada

**Projeto sem interface.** `.sdd/config.sh` traz `E2E_CMD=""` e não traz `APP_URL`; `docs/qa/` não
existe e **não foi criada** — é o caminho em que o `sdd-qa` é a única sessão da fase e caminha as
jornadas ele mesmo, no terminal. As jornadas deste kit são comandos de CLI. Por isso a evidência
mora no campo `gate:` acima, e não num relatório datado em `reports/`.

⚠️ **`status: skipped` foi considerado e recusado.** O diff **alcança** o usuário: mexe na saída de
dois comandos que o humano lê. `skipped` é para diff que não chega a ninguém, não para projeto sem
browser.

**As duas superfícies visíveis ao humano** são `sdd health` e `sdd autonomy` — o mesmo par que o
`20-handoff-exec.md` mandou re-andar. Re-derivado por conta própria, e o resultado corrige uma
leitura fácil de errar: os hunks de `bin/sdd` caem em `cmd_health`, `cmd_autonomy` e num terceiro
que o cabeçalho do `git diff` rotula `cmd_retry()` — mas **não é ele**. É o helper novo
`autonomy_no_data()`, que mora entre as duas funções, e o `git diff` só sabe nomear a última linha
de contexto que parecia uma função. `cmd_retry` está **intocado**, e a afirmação do EXEC ("nada em
`sdd retry` mudou de comportamento") procede.

### As 7 jornadas caminhadas

| # | Jornada | Comando | Resultado |
|---|---|---|---|
| J1 | a suíte, que é a jornada de CI | `tests/run-all.sh` | ✅ rc 0, `suite green`, 533 `ok`, `score: 81 caught, 0 known gap(s), of 81`, 3m29s |
| J2 | `sdd health` no repo íntegro | `./bin/sdd health` | ✅ rc 0, 5 checks verdes, `kit healthy`, `ratchet: 7 known debt(s), none new` |
| J3 | catraca no sentido **faxina** (baseline ficou para trás) | baseline 73→72, `./bin/sdd health` | ✅ reprova, rc 1, **as duas** mensagens |
| J4 | catraca no sentido **crescimento** (item novo, baseline parada) | item novo no `TODO.md`, `./bin/sdd health` | ✅ conta 74, reprova, rc 1, **as duas** mensagens |
| J5 | `sdd autonomy` no ledger real | `./bin/sdd autonomy` | ✅ dinheiro com 2 casas, ordem do arquivo, aritmética fecha |
| J6 | `sdd autonomy` sem ledger e com ledger vazio | `SDD_STATE_DIR=<tmp> ./bin/sdd autonomy` | ✅ uma voz só nos dois caminhos |
| J7 | `sdd autonomy` ilegível × shape errada | dois ledgers de fixture | ✅ diferencial: frases distintas |

### A lacuna que o QA fechou (J4)

O EXEC provou a bidirecionalidade **editando a baseline** — 72 contra 73 reais. Isso mede que o
`health_ratchet` compara, mas **não** mede que o número segue o arquivo: com a contagem congelada
num valor fixo, um `check-todo.sh` que tivesse parado de contar passaria despercebido dos dois
lados. A jornada que um autor de missão de verdade anda é a outra — ele **acrescenta um item** e
descobre no `sdd health`. Ela nunca tinha sido andada.

Andada aqui, numa cópia descartável: item bem-formado acrescentado ao `TODO.md`,
`tests/check-todo.sh` → `CHECKTODO_RC=0` e `  ok    74 finding(s)` (a contagem **se moveu**), e
`./bin/sdd health` → rc 1 com `finding outside the baseline: todo-findings 74` **e**
`stale baseline: 'todo-findings 73' is no longer a finding — delete the line`. O contrato
`check-todo.sh` escreve → `bin/sdd` lê está fechado ponta a ponta, no repo, não no fixture.

### Por que numa cópia, e não na árvore real

A sessão anterior de QA morreu no meio da caminhada, com a baseline sabotada — e só não deixou
sujeira porque o `trap` alcançou. `trap` não sobrevive a `SIGKILL`. Como `SDD_HOME` é resolvido do
caminho do próprio script (`_resolve_self`, `bin/sdd:47`, e é `readonly`), basta rodar o `bin/sdd`
de uma **cópia** para que toda a sabotagem caia nela: `cp -a` do repo para `/tmp/qa-kit`, as três
caminhadas lá dentro, `rm -rf` no fim. A árvore real foi conferida limpa antes e depois. Quem for
caminhar a catraca de novo: é esta a forma, e ela não depende de `trap` nenhum.

## Estado do repo

- **Branch:** `missao/20260817-catraca-do-backlog` — local, **nunca empurrada** (é da fase PR)
- **Último commit:** `84177ae` `chore(missao): checkpoint I5 done — ca017f9, e o handoff da fase EXEC`
- **Working tree:** limpo (o commit deste handoff fecha a fase)
- **Suíte:** `tests/run-all.sh` → **verde**, rc 0, 533 asserções `ok`, `score: 81 caught, 0 known gap(s), of 81`
- **E2E:** `E2E_CMD` vazio — o kit não tem interface; as jornadas são comandos de CLI, caminhadas à mão

## O que foi feito

> QA não produz commit de código. O único artefato desta fase é este handoff — e é deliberado:
> nenhuma jornada reprovou, então não há spec nova nem incremento de fix para escrever.

- **0 achados confirmados novos** nas 7 jornadas → **0 specs novas** e **0 linhas `F<n>`** no
  `checkpoint.md`. A regra "achado confirmado de jornada vira sensor commitado" não foi dispensada:
  ela não teve o que morder. O sensor que cobriria essas jornadas **já existe e já roda no CI** —
  `tests/check-health.sh`, 8 asserções, nascido no I1/I2 desta mesma missão, e verde nas 533.
- **0 incrementos de fix.** Nenhum bug sanável atribuível ao diff desta missão.

## Artefatos

| Arquivo | O que contém |
|---|---|
| `docs/handoffs/20260817-catraca-do-backlog/30-handoff-qa.md` | Este handoff — as 7 jornadas e a evidência de cada uma no `gate:` |

Nenhum outro arquivo foi tocado: `checkpoint.md` fica como o EXEC deixou (5 incrementos `done`,
sem `F<n>`), e `TODO.md` fica em **73** achados, batendo com a baseline — por isso `sdd health`
segue verde.

## Boot da próxima fase (REVIEW)

**Ambiente:** nenhum. `git checkout missao/20260817-catraca-do-backlog` basta.
⚠️ **A suíte leva ~3m30s nesta máquina** (o EXEC mediu ~7 min numa mais carregada), e
`./bin/sdd health` custa **uma suíte inteira** porque a roda por dentro. `sdd phase` e `sdd status`
também disparam gate, logo também custam isso — não são travamento.

**O que o revisor precisa saber que o QA viu:**

1. **As duas superfícies humanas estão íntegras** e não precisam ser re-andadas — a evidência
   comando a comando está no `gate:`. Se o revisor mexer em `cmd_health` ou `cmd_autonomy`, aí sim
   as jornadas J2–J7 têm de voltar.
2. **O diff NÃO toca `cmd_retry`**, apesar de um hunk do `git diff` parecer dizer que sim. É o
   helper `autonomy_no_data()` entre as duas funções. Não "conserte" isso.
3. **A revisão de código ainda não foi feita** — o QA caminha jornada, não lê linha. Os 485
   novos em `tests/check-health.sh` e os 166 de `tests/check-mutation.sh` chegam à REVIEW sem
   nenhuma passada de leitura crítica.
4. **`TODO.md` está em 73 e a baseline em 73.** Qualquer achado que a REVIEW registrar tem de mover
   `todo-findings` no **mesmo commit**, ou `sdd health` reprova — de propósito. É a catraca desta
   missão funcionando contra a própria missão, e o caminho está medido em J4.

## Pendências / Decisions for a Human

> Só julgamento humano genuíno. **Não bloqueiam o pipeline** — viram seção do PR.

- **A linha da catraca não tem dono no formato que a baseline exigia** — o cabeçalho dizia que toda
  linha é paga por um item do `TODO.md`, e a contagem não tem um item: o dono dela é o **arquivo**.
  O I5 passou a admitir a classe em vez de inventar um dono falso. O QA leu o cabeçalho novo e ele
  é honesto sobre isso. Outra saída é escolha do humano — ver `tests/health-baseline.txt`, topo.
- **O multiplicador do harness de mutação** — sensor novo custa uma vez **por mutante**, não uma
  vez. A saída ("rodar por mutante só o sensor que a mutação alcança") muda a régua do `sdd health`
  e é decisão humana. Já em `TODO.md`, seção "Custo e escala".

## Riscos e não-feitos

- **Nenhuma jornada exercitou o `sdd health` com a suíte VERMELHA**, e esse é justamente o caminho
  em que ele morre mudo (achado **aberto e pré-existente**, `TODO.md:104`, descoberto na missão
  `20260816-portas-do-humano`). Verificado por leitura: `out="$( … run-all.sh )"` é atribuição de
  substituição de comando, e sob `set -e` a suíte vermelha mata o script antes do
  `health_bad "suite red"` — que é código morto. Fora do escopo desta missão, não regressão dela.
- ⚠️ **O `20-handoff-exec.md` lista 6 achados fora de escopo como "Registrados no `TODO.md`", mas
  só 5 são novos.** O sexto (`sdd health` mudo com a suíte vermelha) **já existia em `main`** —
  medido com `git show main:TODO.md`. A nota do `checkpoint.md` (I5) está correta e diz
  "avistamento, não item novo"; foi a prosa do handoff que ficou solta. **Quem escrever o corpo do
  PR não deve contar 6 achados novos — são 5.** Não virou item de `TODO.md`: seria exatamente a
  inflação que esta missão combate, e o registro correto já existe em dois lugares.
- **Um probe meu falhou em construir o que prometia, e foi descartado em vez de virar conclusão.**
  Eu quis medir o espaçamento com 2 classes de exclusão num ledger de fixture, mas a classe
  "não-comparável" liga em **kit sujo**, não em campo nulo, e o meu `jq` selecionou 0 linhas: o
  mundo "two" saiu idêntico ao "one". Conclusão de probe vazio não vale (regra do `CLAUDE.md`), e o
  ledger real já exibe as duas classes de qualquer modo. O que ficou medido de verdade: **0**
  exclusões → nenhuma linha em branco sobrando; **1** exclusão → exatamente uma linha em branco
  separando da tabela. A linha em branco **entre duas exclusões consecutivas** continua lá, no
  ledger real — achado aberto e registrado, não regressão.
- **Não verificado:** o comportamento da catraca num repo-alvo (não-kit) — o `sdd health` só roda
  no repo do kit por desenho. E **nenhuma leitura crítica de código** foi feita: é da REVIEW.
- **Cluster 3 (9 itens), clusters 4 e 5 e o eixo de i18n** seguem abertos, como o `00-missao.md`
  declarou. O cluster 5 depende de 4 decisões humanas.

## Achados fora de escopo

> Nada de novo nesta fase. Os 5 achados que a missão registrou são do EXEC e já estão no `TODO.md`;
> aqui fica só o ponteiro, para o PR conseguir citar.

- `sdd health` aborta calado quando `~/.claude/plugins/cache` não existe → `TODO.md` (Sensores que faltam)
- A checagem do `score:` do `sdd health` promete reprovar e morre calada → `TODO.md` (Sensores que faltam)
- O `moved` do `cmd_kaizen` não tem asserção, logo não pode ter mutação → `TODO.md` (Sensores que faltam)
- As linhas de exclusão do `sdd autonomy` levam uma linha em branco entre cada duas → `TODO.md` (Saída humana e cosmética)
- Sensor novo na suíte é multiplicador, não parcela → `TODO.md` (Custo e escala)

⚠️ O sexto item que o handoff do EXEC cita (`sdd health` mudo com a suíte vermelha) **não** entra
nesta lista: ele é anterior à missão e já vivia em `main`. Ver "Riscos e não-feitos".
