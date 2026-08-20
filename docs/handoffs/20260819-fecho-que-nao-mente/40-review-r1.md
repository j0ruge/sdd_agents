---
missao: 20260819-fecho-que-nao-mente
fase: REVIEW
rodada: 1
status: done
sessao: ccb102b3-710f-4a9b-bd3d-439d8ec9be9a
data: 2026-08-19 19:18
gate: "tests/run-all.sh → `suite green`, rc 0, 1m36s, 487 linhas `ok` e zero `FAIL`, com as sete asserções da métrica presentes ancoradas em `^  ok    `. Árvore LIMPA (`git status --porcelain` vazio) sobre `ce25226`, o último dos quatro commits desta rodada (`53586c5`, `e2e5252`, `162fb97`, `ce25226`). Catálogo de mutação rodado ponta a ponta sobre ESTE conteúdo, 20 min, log em /tmp/rev-health-final.log: `ok mutation: score: 118 caught, 0 known gap(s), of 118`, `ok all 8 gates have a mutation in the catalogue`, `ok ratchet: 7 known debt(s), none new`, `ok kit healthy`, rc 0 — `caught == of`, e N = 118 contra o `N >= 108` que o `00-missao.md` pede (partida 104). Carimbo gravado e conferido igual à chave de conteúdo do momento: `bbdd6ab12c34d4381b88c7e8f756648b`. Varredura determinística de segredos sobre o diff da missão: 0 achados, 0 erros."
---

# Review — rodada r1 — O caminho que certifica o fecho de uma missão para de afirmar o que não mediu

> Escrito ao fim de cada rodada de revisão, em `docs/handoffs/<missão>/40-review-r<N>.md`.
> O runner lê **a mais recente**. Uma rodada que não fechou também escreve o arquivo, com a nota
> real: nota inflada para passar no gate desliga o único sensor de qualidade da missão.

## TL;DR

Dez achados, **sete consertados nesta sessão** com quatro commits e **três registrados no
`TODO.md`**; um refutado com evidência. Os três mais caros são todos da tese da missão, e um deles
nasceu **dentro desta própria rodada**: o conserto do `gate_REVIEW` criou um falso VERMELHO que a
segunda passada achou. Suíte verde e catálogo de mutação verde ponta a ponta — 118 mutantes.

## Nota da rodada

⚠️ **O heading abaixo é `###` — três sustenidos — e a tabela é a do `codereview`.** O
`gate_REVIEW` procura o literal `^###[[:space:]]+Overall Grade` e faz parse das colunas
`Criterion` / `Grade` / `Rationale`.

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | A | Três defeitos de leitura no `gate_REVIEW` fechados e nenhuma estrutura nova inventada; o que sobrou de dívida está declarado no comentário da função ou no `TODO.md`, nunca escondido numa frase. |
| Type Safety | A | Em bash o análogo é disciplina de contrato, e ela foi medida: as 22 capturas da região do `sdd health` seguem todas guardadas contra `set -e` (censo de duas mãos verde), o `rm -rf` de limpeza ganhou o `${MDIR:?}` que faltava, e a remontagem de colunas do `awk` passou a contar a paridade da barra em vez de adivinhá-la. |
| Error Handling | A | O comentário que afirmava que o `set -e` derruba a substituição de comando foi medido e corrigido — é falso sem `inherit_errexit`; o ramo real que isso deixa (config que não parseia lida como "declares no TEST_CMD") virou item do `TODO.md` com direção, em vez de virar prosa tranquilizadora. |
| Security | A | Varredura determinística de segredos sobre o diff da missão: zero achados, zero erros de scanner. Nenhuma superfície nova de rede, e o único operando de `rm -rf` sem guarda no diff foi fechado. |
| Performance | A | Medido, não estimado: `TEST_CMD` em 1m36s contra 1m26s no começo da rodada, dentro da banda que a missão já registrava; a chave de conteúdo do carimbo custa 53 ms e o catálogo continua opt-in, fora de todo gate. |
| Test Coverage | A | Quatro mundos diferenciais novos e três mutantes novos (115 para 118), cada mutante provado mudando UMA linha e avermelhando exatamente o seu mundo, sem colateral — e o catálogo inteiro rodado ponta a ponta sobre esta árvore, com `caught == of`. |
| Documentation | A | `docs/pipeline.md`, `templates/review.md` e `agents/sdd-reviewer.md` já descreviam a regra nova e foram conferidos contra o código célula por célula; os três comentários que afirmavam mais do que mediam foram corrigidos ou viraram item do backlog, com a catraca movida no mesmo commit. |
| **Overall** | **A** | Nenhum achado CRITICAL ou HIGH ficou aberto, a suíte e o catálogo de mutação fecharam verdes sobre o conteúdo exato desta árvore, e todo achado que não coube na missão está no `TODO.md` com âncora, medição e direção. |

## Achados da rodada

| # | Severidade | Achado | Onde |
|---|---|---|---|
| 1 | HIGH | Pipe escapado do GFM (`\|`) numa célula quebra a linha, e a justificativa real vira placeholder — falso VERMELHO | `bin/sdd:596` |
| 2 | HIGH | A remontagem do achado 1 não distinguia corrida ÍMPAR de PAR de barras; célula terminada em `\\` colava duas colunas | `bin/sdd:609` |
| 3 | HIGH | O bloco do carimbo AFIRMAVA que a chave é o conteúdo e nunca o `HEAD`, e nenhum mundo media isso | `tests/check-gates.sh:923` |
| 4 | MEDIUM | Duas mensagens de `fail()` diziam "the 6 worlds above" com nove e oito mundos rodando embaixo | `tests/check-gates.sh:630` |
| 5 | MEDIUM | `awk -v` roda o valor do `gate:` pelo processamento de escape, e a recusa citava texto que o arquivo não tem | `bin/sdd:553` |
| 6 | LOW | O comentário do source do `.sdd/config.sh` afirmava que o `set -e` derruba a substituição — é falso | `bin/sdd:2179` |
| 7 | LOW | `$MDIR` sem `${VAR:?}` na linha de `rm -rf` cujos quatro irmãos todos o carregam | `tests/check-gates.sh:1090` |
| 8 | LOW | O censo `guard:` conta captura escrita dentro de COMENTÁRIO — falha fechada, mas proíbe documentar a armadilha | `tests/check-health.sh:1352` |
| 9 | LOW | A guarda de vazio do `mutation_stamp_key` só cobre a ausência TOTAL dos quatro caminhos | `bin/sdd:806` |
| 10 | LOW | Colons de alinhamento GFM na linha separadora reprovam o gate com motivo que não nomeia critério | `bin/sdd:617` |

## O que foi corrigido

- **Achado 1** — corrigido em `53586c5`. Reproduzido antes com o `awk` extraído verbatim: a linha
  `` | Code Quality (Zen) | A | `TODO\|` list references removed. | `` era reportada como
  `placeholder Rationale (TODO\)`. As colunas passam a ser remontadas antes de qualquer leitura, e
  o mundo 10 do `check-gates.sh` faz a jornada inteira pelo CLI real.
- **Achado 2** — corrigido em `ce25226`, e é o achado mais importante da rodada porque nasceu
  **dela**. Medido diferencialmente contra o runner de um commit atrás, que aceita a mesma linha:
  `| Escaping (\\| A | Confirmed no leaks. |` virava `Escaping (\| A = Confirmed no leaks.`, uma
  rodada Grade A barrada por um critério que ninguém escreveu. `escaped_pipe()` conta a corrida de
  barras; mundo 12 e dois mutantes na mesma linha de aplicação.
- **Achado 3** — corrigido em `e2e5252`. Medido reescrevendo `mutation_stamp_key` para hashear
  `git rev-parse HEAD`: os mundos 1 a 7 ficavam todos VERDES e só o 8 avermelhava, com a frase
  errada na boca. Mundo 3b é o falseador que faltava (um commit que move o `HEAD` e nenhum byte
  medido, que é literalmente o commit da fase PR), mais o mutante `PR_stamp_key_follows_head`.
- **Achado 4** — corrigido em `e2e5252`. As quatro contagens saem de `_worlds`, incrementado pelo
  próprio helper de mundo: a frase só pode errar se a contagem errar.
- **Achado 5** — corrigido em `53586c5`. Medido lado a lado no mawk 1.3.4 desta máquina: sob `-v` o
  valor `<a\tb>` chega como `<a` TAB `b>`, sob ENVIRON chega byte a byte. Mundo 11 exige o eco
  verbatim, e a sabotagem que devolve o `-v` o avermelha sozinho.
- **Achado 6** — corrigido em `53586c5`. Medido: sem `inherit_errexit` a substituição alcança o
  `printf` e sai 0. O comentário passou a dizer o que foi medido, e o ramo real virou achado 8 do
  `TODO.md`.
- **Achado 7** — corrigido em `e2e5252`, uma tecla: `"${MDIR:?}/50-pr.md"`.

⚠️ **Registro de processo que vale mais que qualquer um dos consertos:** a primeira escrita do
mundo 10 era **decoração**. Com a célula começando por `the `, o toco deixado pelo corte virava
`THETODO`, que não é palavra de preenchimento, e o mundo ficava VERDE contra o runner defeituoso.
Quem acusou foi a passada de sabotagem, não a leitura. Probe que conclui sem ter reproduzido vale
zero, e desta vez a regra pegou o próprio revisor.

## O que foi refutado

- **Achado 10 como achado desta rodada** — refutado. A segunda passada o levantou como possível
  regressão da remontagem de colunas. Conferido com `git show 03d427a:bin/sdd`: a linha
  `crit ~ /^-+$/` é **byte a byte idêntica** à de antes da missão, e a reprodução (`|:---|:---:|`
  lido como linha de dados) acontece igual nos dois runners. É anterior ao I3, já está no
  `TODO.md` § Sensores que faltam desde a fase QA, e consertá-lo aqui seria mexer fora do escopo
  por conveniência, não por artefato. Nenhuma linha nova de backlog: seria a segunda cópia do
  mesmo item.
- **"As três asserções novas do `check-health.sh` podem passar vazias"** — refutado por execução.
  Cada uma foi medida contra o mutante que deveria pegá-la, com o `sed` aplicado a uma cópia:
  `mutation: a score whose caught differs from total is refused` pega
  `HEALTH_mutation_survivor_blind` sozinha, `…a catalogue too small…` pega
  `HEALTH_catalogue_floor_blind` sozinha, e a de superfície pega `HEALTH_testcmd_list_blind`
  sozinha. A metade `(a)` da de superfície, de que eu mais desconfiei (o `2>/dev/null` da captura
  poderia cegá-la), foi testada devolvendo o defeito histórico ao `tests/run-all.sh`: fica
  vermelha, nomeando a linha que não é passo. Nenhuma é vácuo.
- **Os 118 mutantes** — os 11 que a missão acrescentou antes desta rodada foram conferidos um a um:
  cada `sed` muda **exatamente uma linha** do `bin/sdd`. Nenhuma âncora podre, nenhum segundo
  sítio sabotado calado. Os 9 do catálogo que mudam mais de uma linha são todos anteriores à
  missão e já estão no `TODO.md`.

## Achados fora de escopo

> O que não cabe nesta missão vai para o `TODO_FILE`, nunca para o diff. Catraca `todo-findings`
> **86 → 89**, movida no mesmo commit `162fb97`, contada por `tests/check-todo.sh`.

- **Achado 8** — o censo `guard:` conta captura escrita dentro de comentário — registrado no
  `TODO.md` § Sensores que faltam (2026-08-19). Achado ao vivo: um exemplo de reprodução colado num
  comentário do `cmd_health` virou a 23ª captura e a catraca reprovou a suíte.
- **Achado 9** — a guarda de vazio do `mutation_stamp_key` só cobre a ausência TOTAL dos quatro
  caminhos — registrado no `TODO.md` § Sensores que faltam (2026-08-19).
- **Achado 6, o ramo que sobra** — `.sdd/config.sh` que não parseia é reportado como "declares no
  TEST_CMD", com o erro real engolido — registrado no `TODO.md` § Contrato e configuração
  (2026-08-19).

## Pendências / Decisions for a Human

As três que a missão já carregava seguem de pé, e esta rodada não abriu nenhuma nova:

1. **As três decisões de desenho do plano kaizen-born** (carimbo em vez de CI; escopo por artefato;
   chave no conteúdo). Esta rodada as **sustenta com medição**, e é isso que muda desde a QA: a
   terceira era afirmada e não medida, e agora tem mundo próprio (o 3b). — `00-missao.md`
   § Decisões do grill.
2. **A convenção do `RESOLVIDO por` × a catraca do backlog.** — `TODO.md` § Contrato e configuração.
3. **CI rodando o catálogo.** O número que a decisão de custo precisa foi re-medido aqui: a rodada
   completa de **118 mutantes levou 20 min** nesta máquina, contra os 30 min de 110 mutantes que a
   QA mediu. Cresceu o catálogo e caiu o relógio — a diferença é contenção de CPU, não melhoria, e
   nenhum dos dois números serve como estimativa de runner de CI. — `00-missao.md` § Fora de escopo.

⚠️ **Para a fase DOCS e a fase PR:** o carimbo do `gate_PR` foi gravado ao fim desta rodada, sobre
o conteúdo de `ce25226`. `CLAUDE.md`, `docs/` e `TODO.md` **não** o invalidam, então a fase DOCS
pode trabalhar à vontade; qualquer commit que toque `bin/ tests/ templates/ config/` o invalida e
exige `./bin/sdd health` de novo antes do PR.
