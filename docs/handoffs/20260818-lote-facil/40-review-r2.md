---
missao: 20260818-lote-facil
fase: REVIEW
rodada: 2
status: blocked
sessao: 7ee576d7-b15d-43f3-8110-2c475c99d854
data: 2026-08-19 01:20
gate: "NÃO passou, e a nota abaixo é a real. Árvore limpa e suíte verde (`tests/run-all.sh` → `suite green`, rc 0, `score: 101 caught, 0 known gap(s), of 101`, `72 finding(s)`), consertos commitados em `bb3551e` e `75c9d2a` — mas quatro critérios não são A. O que reprova é achado CONFIRMADO e não consertado, com reprodução no `TODO.md`: a regra `guard:` do `check-health.sh` — a contribuição durável da r1/r2 — conhece UMA grafia de captura, então `x=$(cmd)` sem aspas, crase e `$(` no fim de linha passam limpos E encolhem o censo calado, e a forma sem aspas engole as linhas seguintes deixando uma captura guardada LAVAR a desguardada. Medido: `mut_HEALTH_gates_capture_aborts` reescrita sem aspas deixa a suíte VERDE enquanto o `sdd health` morre em três linhas. Mais o `REVIEW_FLOOR` do `check-templates.sh`, que conta CHAMADAS e por isso certifica um `templates/review.md` de zero byte com `23 assertion(s)`, e os três helpers de asserção do `check-todo.sh`, cada um neutralizável com uma linha enquanto o selftest segue dizendo `88 probe(s), the sensor measures what it claims`. Sensor que afirma ter medido o que não mediu é o pior modo de falha deste kit, e são três. Continua em r3."
---

# Review — rodada r2 — O `sdd health` para de morrer calado, e 18 achados baratos saem do backlog

> Escrito ao fim de cada rodada de revisão, em `docs/handoffs/<missão>/40-review-r<N>.md`.
> O runner lê **a mais recente**. Uma rodada que não fechou também escreve o arquivo, com a nota
> real: nota inflada para passar no gate desliga o único sensor de qualidade da missão.

## TL;DR

Quatro passadas adversariais paralelas sobre o diff (28 arquivos, +3566), cada achado reproduzido
antes de virar conserto. **Uma HIGH consertada** — regressão desta missão: recusar a forma do
`--path-format` ecoado não bastava, e devolver vazio matava o ledger inteiro, calado e para sempre,
em git < 2.31. Mais **quatro afirmações que o artefato ao lado desmentia**. Sobram **três achados
de sensor que falha aberto**, confirmados e não consertados por orçamento; estão no `TODO.md` com a
reprodução. `TODO.md` 57 → 72, catraca junto. **A rodada não fecha: Test Coverage é C.**

## Nota da rodada

⚠️ **O heading abaixo é `###` — três sustenidos — e a tabela é a do `codereview`.** O
`gate_REVIEW` procura o literal `^###[[:space:]]+Overall Grade` e faz parse das colunas
`Criterion` / `Grade` / `Rationale`. Escrito como `##`, o gate responde `NO-TABLE` e a rodada
não fecha.

Qualquer critério com nota diferente de `A` reprova — inclusive `—` para "não analisado". Revisão
parcial não é revisão: se um critério não foi analisado, analise. Os sete abaixo foram analisados.

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | B | O runner é cuidadoso e os consertos são corretos, mas o `health_provenance` conta como conferida uma fixture cujo laço não iterou, e o `diverged` repete o literal `3` que a rubrica de três estados existe para ter num dono só. |
| Type Safety | A | O campo `repo` do ledger é o único contrato de forma do diff, e ele foi ESTREITADO: uma linha absoluta ou nada, agora com fallback que resolve em vez de devolver vazio, e asserção diferencial exigindo os dois gits na mesma string. |
| Error Handling | B | A família do aborto calado é o eixo da missão e fechou em dezesseis sítios com regra própria; mas a catraca ainda manda APAGAR uma linha viva da baseline quando a suíte morre truncada — remédio destrutivo tirado de uma medição que se declarou cega. |
| Security | A | Pré-scan determinístico sobre o diff da missão: `findings: []`, scanner `regex`, zero erros. Nenhuma superfície nova; o `CDPATH` — a única classe de env hostil aqui — foi fechada no repo inteiro e tem par diferencial com veneno armado. |
| Performance | A | Nenhum caminho quente tocado. O custo do catálogo (101 mutantes × suíte) é decisão declarada do humano e já está no `TODO.md`, seção "Custo e escala"; o fallback novo custa um `rev-parse` a mais só em git < 2.31. |
| Test Coverage | C | Três sensores afirmam ter medido o que não mediram: a regra `guard:` conhece uma grafia de captura e é lavada pela vizinha; o `REVIEW_FLOOR` conta chamadas e certifica um template de zero byte; os três helpers do `check-todo.sh` viram no-op com uma linha cada e o selftest segue se elogiando. |
| Documentation | B | As quatro derivas que esta rodada achou foram consertadas com evidência, e as âncoras que a missão quebrou sozinha foram re-derivadas; mas dois cabeçalhos de sensor seguem afirmando propriedade que a sabotagem derruba ("not reachable in one edit" é alcançável em uma edição, medido). |
| **Overall** | **C** | Achados reais, consertos provados nos dois sentidos e árvore limpa; a rodada não fecha porque o instrumento que esta missão criou para tornar a classe inreinstaurável falha aberto em cinco grafias, e isso não é dívida a registrar — é o entregável. |

## Achados da rodada

| # | Severidade | Achado | Onde |
|---|---|---|---|
| 1 | HIGH | Recusar a forma não bastava: em git < 2.31 o ledger inteiro morria calado | `bin/sdd:922` |
| 2 | CRITICAL | A regra `guard:` conhece UMA grafia de captura; cinco formas passam limpas | `tests/check-health.sh:761` |
| 3 | HIGH | O `REVIEW_FLOOR` conta chamadas e certifica um `review.md` de zero byte | `tests/check-templates.sh:113` |
| 4 | HIGH | Os três helpers de asserção do `check-todo.sh` viram no-op com uma linha | `tests/check-todo.sh:361` |
| 5 | HIGH | O token de guarda é procurado no enunciado inteiro: comentário certifica | `tests/check-health.sh:767` |
| 6 | MEDIUM | O `check-pipefail.sh` mandava ver um comentário do `CD_RE` que não existia | `tests/check-pipefail.sh:29` |
| 7 | MEDIUM | O `docs/pipeline.md` se contradizia dentro do mesmo hunk | `docs/pipeline.md:518` |
| 8 | MEDIUM | Duas âncoras que esta missão criou e quebrou sozinha | `TODO.md:393` |
| 9 | MEDIUM | O Check do I2 dizia `3` e responde `4` | `checkpoint.md:24` |
| 10 | MEDIUM | O `health_provenance` conta fixture cujo laço não iterou | `bin/sdd:1965` |
| 11 | MEDIUM | A catraca manda apagar linha viva da baseline na suíte truncada | `bin/sdd:2021` |
| 12 | MEDIUM | Duas formas bem formadas recusadas pelo `check-todo.sh` | `tests/check-todo.sh:176` |
| 13 | MEDIUM | Os literais "estruturais" da regra 3 afrouxam em verde | `tests/check-checkpoint.sh:227` |
| 14 | LOW | O `pushd "$(…)"` tem o mesmo bug de CDPATH, não medido nem declarado | `tests/check-pipefail.sh:252` |

## O que foi corrigido

### 1 (HIGH) — recusar a forma era metade do conserto; a outra metade matava o ledger

`75c9d2a`. A r1 fechou a CRITICAL do `--path-format` ecoado virando identidade, e fechou
**devolvendo vazio**. Só que vazio é o contrato de "não é um repo": em git 2.25 (Ubuntu 20.04) e
2.30 (Debian 11) toda linha passaria a ser escrita `repo: ""`, todo leitor a arquivaria em
`no_repo` — balde que o `--all-repos` deliberadamente **não** admite —, o `sdd autonomy` responderia
`no data` e o `sdd kaizen` só saberia dizer `indeterminado`. Silencioso, permanente (append-only,
nunca migrado) e **estritamente pior que a grafia anterior**, que respondia certo nesses mesmos
gits. O comentário da própria r1 admitia isso — *"the `cd`-based form it replaced answered correctly
on the same git"* — e escolhia o vazio assim mesmo.

A grafia antiga volta como **fallback**, segura hoje pelo motivo que a tornava perigosa antes: as
guardas `CDPATH=''` que esta missão espalhou. Piso do probe provado antes de qualquer conclusão — o
shim ecoa a bandeira, duas linhas, rc 0, e segue transparente para os outros `rev-parse`:

| | git 2.43 real | shim pré-2.31 |
|---|---|---|
| antes de `75c9d2a` | `/tmp/…/repo` | `[]` — o ledger morre |
| depois, raiz | `/tmp/…/repo` | `/tmp/…/repo` — **AGREE** |
| depois, subdiretório | `/tmp/…/repo` | `/tmp/…/repo` — **AGREE** |
| depois, worktree ligado | `/tmp/…/repo` | `/tmp/…/repo` — **AGREE** |

**A asserção do sensor era a outra metade do defeito:** ela pedia *silêncio* do git velho, então
chamava de aprovado exatamente o que este commit conserta. Agora pede **acordo** — quatro campos,
e o novo (`same`) é diferencial, os dois gits comparados um com o outro, exigindo `old` não-vazio
para que "não resolveu nada" não compre o verde uma terceira vez. Verificado nos dois sentidos,
cada sabotagem com o diff provado antes:

- `mut_LEDGER_repo_root_shape_blind`, **reancorada** (o `|| return 0` das duas armas virou
  `|| gitdir=""`, então a mutação virara no-op e teria reportado `CATALOGUE-BROKEN`) → `1 autonomy
  check(s) failed`, na asserção nomeada e em nenhuma outra;
- o "conserto plausível" que a revisão propôs no lugar deste — pegar a **última** linha em vez de
  recusar — colapsa todo repo da máquina em `.git` e **passava** na asserção velha; agora reprova,
  também em uma só.

`sdd preflight` deixa de reprovar e passa a **avisar**: com o fallback o kit está correto em git
velho. A mensagem antiga mandava o operador para o remédio errado (`--all-repos` não alcança
`no_repo`).

### 6–9 (MEDIUM) — quatro afirmações que o artefato ao lado desmentia

`bb3551e`. Nenhuma é lógica errada; as quatro são a classe que o `CLAUDE.md` nomeia —
*comentário que jura paridade não é paridade* — repetida dentro da missão que a condena.

- **`check-pipefail.sh:29`** mandava *"see the CD_RE comment for the two shapes left unmeasured on
  purpose"* e o comentário nunca foi escrito; a regra irmã tem o seu (`maxc_violations`, :246-251) e
  **duas** entradas do `TODO.md` citavam o do `CD_RE` como se existisse. Escrito, com as duas formas
  **medidas**: operando variável (176 sítios, comando ao lado) e operando literal relativo (zero
  instâncias vivas — os hits do `grep` são prosa dentro de descrição de probe, conferidos um a um).
  Para a primeira o comentário diz **onde** ela é medida: o par diferencial em runtime.
- **`docs/pipeline.md`** ganhou *"publicado porque uma segunda cópia derivaria no dia em que ele se
  mover"* e carregava, duas linhas abaixo, a segunda cópia — `the last three kit versions`, escrito
  à mão, quando `bin/sdd:2886` lê `guard_floor`.
- **`TODO.md`**: `bin/sdd:2473` **era** a linha `total=` quando a QA a escreveu (conferido em
  `e0074ec`); `d62b40e` somou 125 linhas e a empurrou para `:2568`, e o commit **seguinte** —
  `1272690`, "com âncora re-derivada" no título — re-derivou quatro e passou ao lado desta.
- **`checkpoint.md`**: o Check do I2 dizia `3` e responde `4` desde `8812a9c`. O incremento segue
  `done`; o que mudou é a população. ⚠️ O `check-checkpoint.sh` é verde sobre isso **por
  construção** — mede a forma da célula, nunca se o valor ainda reproduz.

## O que foi refutado

- **"Asserte que o git velho não resolve NADA"** — a passada do `check-autonomy.sh` propôs, como
  conserto do seu CRITICAL nº 1, exigir que o runner sob o shim responda vazio. **Recusado, e é o
  defeito nº 1 deste relatório com o sinal trocado:** vazio é justamente o que mata o ledger em git
  velho. A propriedade certa é acordo, não silêncio — e a asserção que escrevi é estritamente mais
  forte que a proposta, porque mata também o mutante que ela citava (o "pega a última linha", que
  responde `.git` e agora colhe `split:.git|/tmp/…/one`). Medido nos dois sentidos.
- **"As cinco âncoras `cdpath:`/`covered:`/`rule:` da missão não reproduzem"** — falso para quatro:
  rodados literais contra este HEAD, `abort: 4`, `output: 9`, `covered: 5`, `rule: 5`. Só o I2 se
  moveu, e por asserção nova legítima (achado 9).
- **"O catálogo de mutação tem âncora podre depois de +3566 linhas"** — falso: as 101 entradas
  aplicadas uma a uma a um `bin/sdd` limpo dão **zero no-ops, zero quebras de sintaxe**. Os dois
  `sed` sem endereço já estão no `TODO.md` e não foram re-reportados. Medido nos dois sentidos:
  suíte íntegra + `mut_REVIEW_accepts_B` → rc 1; o mesmo mutante com `check-gates.sh` fora do
  `run-all.sh` → `suite green`, rc 0.
- **"Os cinco pisos que o `CLAUDE.md` manda mover juntos ficaram para trás"** — falso, os cinco
  conferidos por comando: 13 sensores no `run-all.sh` ≡ 13 `check-*.sh`; `LINT_FLOOR=15` ≡ `bin/sdd`
  + 14 `tests/*.sh`; piso do `check-pipefail.sh` = 14 ≡ superfície; piso do `check-lang.sh` = 37 ≡
  `surface()`; e o fixture do selftest tem exatamente 14, limpando o próprio piso.
- **"`mawk` byte-oriented mordeu de novo"** — falso, duas passadas independentes:
  `grep -nP '\[\^[^]]*[\x80-\xFF]'` não devolve nada em `bin/sdd` nem em `tests/*.sh`. O único
  `[^—]` é prosa no `check-todo.sh:164` documentando o perigo; todo tratamento de travessão passa
  por `index()`/`substr()`.
- **"`printf | grep -q`, `#` em bloco continuado, ou função com efeito em global lida por `$( )`"**
  — nenhum introduzido pelo diff; toda busca da região do health usa herestring, e
  `shellcheck -S warning bin/sdd tests/*.sh` está limpo.
- **"O template pode ser copiado cru e passar no gate"** — não: o placeholder é `<A>` e o awk
  compara depois de tirar `*` e espaço, então `<A>` ≠ `A` reprova na primeira linha. ⚠️ O que
  **passa** é `A` em toda linha com `<…>` em toda `Rationale` — já é item do `TODO.md`, confirmado
  aqui e não re-registrado.

## Achados fora de escopo

> Catorze achados que não cabem neste diff foram para o `TODO.md`, com a catraca movida no mesmo
> commit (58 → 72). Os três primeiros são o motivo de a rodada não fechar.

- Regra `guard:` cega a cinco grafias de captura; token de guarda casado no enunciado inteiro;
  quatro regras do `check-health.sh` sem probe; `guard:` reprovando três formas que não abortam
  → `TODO.md`, "Sensores que faltam" (2026-08-19)
- `REVIEW_FLOOR` contando chamadas; helpers do `check-todo.sh` neutralizáveis; quatro regras do
  `check-todo.sh` sem probe; duas formas bem formadas recusadas; literais da regra 3 do
  `check-checkpoint.sh` afrouxando em verde → `TODO.md`, "Sensores que faltam" (2026-08-19)
- Braço 1 da guarda de forma sem probe; piso do shim não provando interceptação;
  `health_provenance` contando laço que não iterou; catraca mandando apagar linha viva;
  `pushd` com o mesmo bug de `CDPATH`; Check do checkpoint sem sensor de reprodução
  → `TODO.md`, "Sensores que faltam" (2026-08-19)

## Pendências / Decisions for a Human

> Herdadas das fases anteriores. Nenhuma criada por esta rodada, nenhuma bloqueante — o que bloqueia
> é achado técnico, não decisão.

- **O que `N row(s)` significa no cabeçalho do `sdd autonomy`** — achado da QA, duas saídas
  escritas, uma delas mexe em 7 asserções de sensor. Âncora re-derivada nesta rodada (`bin/sdd:2568`).
- **O alvo "<30 s" da D7** segue estourado e esta rodada não o move (catálogo segue em 101).
- **`LINT_CMD` preenchido e não lido pelo runner** — uma das 5 chaves fantasma.

## Boot da próxima rodada

A r3 é uma **sessão nova sem memória**. O que ela precisa saber:

1. **O eixo é um só: sensor que falha aberto.** Três, todos com reprodução literal no `TODO.md`.
   O mais grave é a regra `guard:` do `check-health.sh`, porque é o entregável durável desta missão
   e porque a reprodução é a própria mutação do catálogo reescrita sem aspas.
2. **Não repetir as passadas verdes.** Segredos, `mawk`, catálogo, os cinco pisos, as quatro
   âncoras de Check e a classe do `CDPATH` foram medidos nesta rodada e estão na seção "O que foi
   refutado", com o comando.
3. **A r2 recusou uma crítica e por quê** — a de exigir silêncio do git velho. Se a r3 reabrir isso,
   leia primeiro a tabela diferencial do achado 1.
4. **`TODO.md` está em 72**, com `tests/health-baseline.txt` junto.
