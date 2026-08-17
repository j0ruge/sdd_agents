---
missao: 20260817-eixo-do-juiz
fase: REVIEW
rodada: r1
status: done
data: 2026-08-17
---

# Review — rodada r1 — o eixo do juiz

> Rodada de revisão dirigida pelo `sdd-reviewer` **dentro desta sessão**: achar, consertar,
> re-medir. Os consertos estão commitados; a árvore fecha limpa.

## TL;DR

**Esta rodada NÃO fecha em A.** Dez achados foram consertados aqui (R1–R10, dois commits, suíte
verde nos dois); **doze não**, e dois deles são regressão de correção contra a `main`, provada com
fixture. O gate vai reprovar de propósito: a régua está no lugar certo e a r2 tem uma lista de
trabalho explícita.

O que fechou: uma **asserção que falhava aberto** (shape do ADR, nascida nesta missão), uma
**afirmação falsa repetida em três artefatos** (`--all-repos` alcançaria o `kaizen_reminder`; não
alcança — e por consequência o item do `TODO.md` que a missão contava como fechado **não** está), e
todo o drift de prosa do contrato.

O que **não** fechou, e é o motivo do C: `ledger_repo_root` devolve **a mesma identidade para dois
submódulos irmãos** e **o diretório-pai para um repo bare** — as duas contra `main`, as duas
silenciosas (`excluded.other_repo: 0`), que é exatamente a contaminação que o filtro existe para
impedir. E `--all-repos` agrega por slug de missão **sem o repo na chave**, então dois projetos com
o mesmo slug no mesmo `kit_sha` viram uma missão só: medido, `guard.sufficient` vira `true → false`
e o `refez` de um projeto rotula a missão limpa do outro — e a flag agora chega ao prompt do juiz.

Uma passada de sabotagem adversarial de **27 degrades** achou **10 sobreviventes verdes** — entre
eles um que reproduz o `BUG-1` da QA *verbatim*, uma função adiante, com a seção escrita para
impedi-lo inteira verde.

A missão entrega os cinco binários do `00-missao.md` — medidos ao vivo, não pelo rótulo do handoff.
O problema não é a entrega; é a régua embaixo dela.

## O que foi medido ao vivo (não lido de handoff)

| Métrica do `00-missao.md` | Observado nesta sessão |
|---|---|
| `guard.degenerate_axis: true` e o ADR citado | `{"missions_after_change":1,…,"sufficient":false,"degenerate_axis":true}`; `sdd kaizen --dry-run` imprime `the kit_sha axis is degenerate here` e `(ADR 0003)` ✅ |
| `--all-repos` diferencial | `sdd autonomy` 54 linhas / `--all-repos` 65; cabeçalho `all repos (--all-repos)`; `other_repo` 11 → 0 nos dois leitores ✅ |
| linha de worktree lida como local | asserções `worktree` verdes, com escritor real e `git worktree add` ✅ |
| 3 linhas sem `repo` não movem `sufficient` | asserções `no-repo` verdes; par diferencial `3 0 false` × `0 0 true` ✅ |
| catálogo 55 → 60, `0 known gap(s)` | **61** (o `F1` da QA acrescentou a sexta), `0 known gap(s)` ✅ |
| 5 itens do `TODO.md` com `RESOLVIDO por <hash>` | ⚠️ **4 de 5** — ver o achado R2. O quinto **não pode** ser estampado |

`sdd health`: ok nos cinco. `missions` não sobe com `--all-repos` no ledger desta máquina — é o
eixo degenerado, não a flag, e já estava registrado pelo EXEC e pela QA.

## Achados e o que foi feito

### R1 — a asserção de shape do ADR falha aberto · **CRITICAL** · consertado em `23467ca`

`tests/check-kaizen.sh` media a forma do ADR 0003 com **um** `grep -c` sobre cinco `-e`. `grep -c`
conta **linhas que casam**, não elementos distintos do formato — e o comentário ao lado afirmava
literalmente o contrário ("the count is the number of format elements present").

Medido, não suposto: uma cópia do ADR que perde o título `# 0003 — ` e ganha um segundo
`## Context` continua marcando **5**, e a asserção passa verde tendo deixado de medir o elemento
que sumiu.

É o modo de falha que o `CLAUDE.md` desta casa chama de pior defeito possível num sensor — ele
afirma ter medido o que não mediu —, e nasceu **nesta missão**, no incremento (I1) cujo propósito
inteiro é impedir que o ADR vire decoração.

**Conserto:** um `grep -qE` por elemento, cada um contribuindo no máximo 1.
**Prova pelo caminho, não pela função:** cópia do kit em `/tmp` com a sabotagem aplicada (título
removido + `## Context` duplicado, os dois conferidos por `grep -c` **antes** de rodar) →
`tests/check-kaizen.sh` rc 1, a asserção de shape vermelha, `ok adr 0003` cai de 2 para 1. Sem
sabotagem: rc 0 e 2 de 2 — o Check do I1 no `checkpoint.md` segue satisfeito.

### R2 — três artefatos afirmam que `--all-repos` alcança o `kaizen_reminder`; não alcança · **HIGH** · consertado em `8f069f5`

`bin/sdd` (comentário de `cmd_kaizen`), `docs/pipeline.md` e — antes deles — o `01-plano.md` (I3) e
o `20-handoff-exec.md` afirmam que a flag chega ao lembrete pós-pipeline "por herança".

Falso, e verificável em uma linha: `kaizen_reminder` é chamado de **um** lugar (`bin/sdd:2074`,
dentro de `cmd_run`), e `cmd_run` não parseia `--all-repos` — morre em qualquer `-*` desconhecido.
`LEDGER_ALL_REPOS` é sempre `0` quando o lembrete roda. A arquitetura é verdadeira (o predicado é
único, ele *herdaria*); a operação é falsa (nenhuma invocação que o alcança pode carregar a flag).

**Consequência que importa mais que o comentário:** o item do `TODO.md` "o lembrete pós-pipeline
manda o humano a um comando que não enxerga o que ele contou" **não foi fechado por esta missão**.
`kaizen_reminder()` é byte-idêntico ao da `main`. Nenhuma das duas direções do item foi tomada — o
lembrete não foi silenciado fora do kit, e "decidir o eixo" (ADR 0003), que *foi* feito, torna a
má-indicação **pior**: o lembrete agora aponta para um repo que o próprio ADR diz não poder
produzir veredito.

**Conserto:** as duas afirmações falsas corrigidas com o ⚠️ e o motivo, na convenção que esta casa
já usa; o item do `TODO.md` ganhou `segue aberto, não estampar` no corpo, para que a fase DOCS não
o feche por engano. Contá-lo nos 5/5 da métrica seria um fechamento falso.

### R3 — `usage()` proíbe o único mecanismo de que o ADR 0003 depende · **HIGH** · consertado em `8f069f5`

`bin/sdd` `usage()`: *"the judge must never take another project's rows as a verdict about this
kit"*. `docs/pipeline.md` repetia a mesma frase. Contra `docs/adr/0003`: *"Evidence for a kaizen
verdict comes from real target repos"* e *"até a evidência chegar de outro lugar"*.

Um repo-alvo real **é** "outro projeto". E não há terceiro caminho: `cmd_kaizen` morre a menos que
`$kit_root = $REPO_ROOT`, então o juiz só roda no repo do kit, cujas linhas o próprio ADR prova
degeneradas. `--all-repos` é o **único** mecanismo pelo qual "a evidência chega de outro lugar" — e
as duas frases mandam o leitor não usá-lo para veredito. Quem seguisse o ADR para destravar o I13.4
esbarraria no `usage()` e concluiria que o remédio do ADR é proibido.

A distinção que o autor claramente pretende — linha de **fixture descartável** é contaminação,
linha de **alvo real** é evidência — não estava escrita em lugar nenhum.

**Conserto:** a prosa passa a separar o que a medição separa (fixture × alvo real), nomeia a
pergunta em aberto e a manda para o **ADR 0004**, sem decidi-la aqui. É a mesma pergunta que a QA
registrou como "Decisions for a Human"; ela continua para o humano — o que mudou é que o runner
deixou de dar duas respostas contraditórias a ela.

### R4 — `CONTEXT.md` publica a shape antiga da série · **HIGH** · consertado em `8f069f5`

O verbete **Série** enumerava **quatro** baldes de `excluded` e afirmava que o literal do ledger
vazio carrega os quatro. São cinco desde `4ca8015`, nos dois produtores. O verbete **Ledger de
autonomia** descrevia a leitura por repo como incondicional e a identidade como o toplevel. A
decisão **D4** (o eixo do juiz) estava com `—` na coluna de ADR, sendo o 0003 exatamente o registro
dela.

Não é menção incidental: é o glossário, e o `KAIZEN_LOG.md` registra uma missão anterior
atualizando **este mesmo verbete** quando `other_repo` nasceu — o precedente existia e não foi
seguido. A causa-raiz é conhecida e segue aberta no `TODO.md` ("o schema da série não tem sensor de
drift contra a prosa que o descreve"); confirmado que o `sdd health` só compara
`load_config()` ↔ `config/schema.md`, então nada poderia ter pego isto.

### R5 — `docs/failure-modes.md` prescreve um diagnóstico que a missão tornou errado · **MEDIUM** · consertado em `8f069f5`

A seção "the rows were born in another repo" mandava o leitor comparar
`git rev-parse --show-toplevel` com `jq -r .repo`. Depois de `c514e36` as linhas carregam o caminho
derivado do `--git-common-dir`, então essa comparação **diverge exatamente no caso de worktree que
a própria seção nomeia como causa**. A seção ainda dobrava a aposta ("a `realpath` invented here
would silently merge two checkouts the ledger deliberately keeps apart") — o que a missão fez de
propósito. Faltavam também `excluded.no_repo`, a quarta voz de "no data" e `--all-repos`, que é hoje
a resposta suportada para a segunda causa que a própria seção lista.

**Conserto:** causa, diagnóstico e "do not" reescritos para o comportamento de hoje, mais um ⚠️
separando `sufficient: false` **estrutural** (eixo degenerado, ADR 0003) do modo de falha da seção.

### R6 — `README.md` e a sinopse do `usage()` não conhecem a flag · **MEDIUM** · consertado em `8f069f5`

`README.md:61` documentava `sdd autonomy` como "for THIS repo" sem escape; o README documenta
`--dry-run` em dois lugares, então é onde uma flag pertence. A sinopse do `usage()` mostrava
`sdd kaizen [--dry-run]` mas nenhuma das três linhas carregava `[--all-repos]` — a qualificação
existia só quatro linhas abaixo.

### R7 — o piso da superfície do `check-lang.sh` carregava 3 caminhos de folga · **MEDIUM** · consertado em `8f069f5`

O piso estava em `33` contra **36** caminhos reais, e o comentário dizia "32 paths today" e "the
`docs/adr/*.md` glob with its **two** ADRs". Uma guarda contra vacuidade com folga é uma guarda que
não guarda: três caminhos podiam sumir em silêncio. Dois dos três vieram de missões anteriores
(`check-entrypoint.sh`, `check-checkpoint.sh`) e **um desta** (o ADR 0003). Recontado para 36, com
o histórico no comentário — o piso move só de propósito, e este moveu de propósito.

### R8 — âncoras `bin/sdd:<N>` desatualizadas, uma criada nesta missão · **MEDIUM** · consertado em `8f069f5`

O item `sdd kaizen recusa rodar de um worktree do próprio kit`, **criado nesta missão** (`80cbea2`),
cita `bin/sdd:2735`. A âncora estava certa quando escrita e envelheceu +40 linhas dentro da própria
missão, porque `abac043`/`c5c9a9f` inseriram `kaizen_axis_note` e o bloco `ledger_flags` acima dela.
Hoje `:2735` cai dentro de `kaizen_axis_note`; a porta que o item nomeia está em `:2775`. Item
recém-escrito com âncora errada derrota o motivo de a âncora existir. Corrigida, junto com três
outras dos itens que esta missão editou.

### R9 — o item da guarda insatisfazível estava fechado e sem hash · **MEDIUM** · consertado em `8f069f5`

A direção declarada do item era *"decidir qual pergunta o juiz responde"*. O ADR 0003 decide
exatamente isso (eixo fica `kit_sha`, carimbo por missão descartado **com motivo**, evidência vem
de alvo), e o `degenerate_axis` reporta. Era falta de escrituração, não item inacabado: ganhou
`RESOLVIDO por 3547a83+abac043`.

### R10 — o comentário gêmeo em `bin/sdd:927` repetia a afirmação falsa do R2 · **MEDIUM** · consertado no commit deste handoff

O R2 corrigiu o comentário de `cmd_kaizen`; o gêmeo, acima de `LEDGER_ALL_REPOS=0`, ficou dizendo o
contrário — dois comentários do mesmo arquivo afirmando coisas opostas sobre a mesma função.
Corrigido junto, com o ⚠️ e o motivo.

## Achados que NÃO fecharam nesta rodada — trabalho da **r2**

> Nada aqui vai para o `TODO.md`: são todos do diff **desta** missão. Sair da missão sem eles é o
> que a rodada r2 existe para impedir.

### N1 — dois submódulos irmãos colapsam numa identidade só · **HIGH** · regressão contra a `main`

`bin/sdd:894-899`. Num submódulo, `git rev-parse --git-common-dir` devolve
`/pai/.git/modules/<nome>`, então `cd "$common/.."` cai em `/pai/.git/modules` — **a mesma string
para todo submódulo daquele pai**. Escritor e leitores concordam nela, então nada é excluído e
nada é reportado: `excluded.other_repo` fica `0`. É a contaminação citada no próprio comentário da
função (`the judge read 66% waste · 2 mission(s) where the truth was 0% · 1`), de volta por outra
porta. `--show-toplevel` (a `main`) acertava.

Medido, dois submódulos com uma sessão cada (uma `pass/moved`, outra `fail/not-moved`): HEAD lê
`2 row(s) · /tmp/…/parent/.git/modules` e `50% waste · 2 mission(s)`; a `main`, no mesmo fixture,
lê `1 row(s) · …/suba`, `0% waste · 1 mission(s)` e `(1 row(s) excluded: born in another repo)`.
Repare também que o cabeçalho passa a imprimir um caminho **dentro do `.git`** como "o repo".

### N2 — `--all-repos` agrega por slug de missão sem o repo na chave · **HIGH**

`bin/sdd:2516` (`group_by(.mission + "|" + .phase)`), `:2521`, `:2528`, e `:2411` no
`cmd_autonomy`. A linha carrega `repo`, mas toda chave de agrupamento é o slug sozinho. Com a flag
que **esta missão criou**, dois repos que rodaram um slug igual no mesmo `kit_sha` viram UM grupo.
Medido: três repos, uma sessão cada, `kit_sha` comum — com dois slugs colidindo,
`missions_with_session` cai de 3 para 2, `guard.sufficient` vira `true → false`, e o `refez` de um
projeto absorve a missão `ok` do outro. Slugs são datados (`YYYYMMDD-<nome>`) e o `cmd_kaizen`
cunha `MISSION="$(date +%Y%m%d)-kaizen"` — idêntico em todo repo no mesmo dia. E desde o `F1` a
flag chega ao prompt do juiz, então isto alcança o veredito. Direção: chave composta
(`repo + "|" + mission + "|" + phase`), no-op no escopo por repo.

### N3 — a metade do **gate** do `one series` não tem probe · **HIGH**

`tests/check-kaizen.sh:934` (`gate_sha`) faz proxy do gate por `sdd kaizen --series`, e a seção
inteira nunca roda `gate_KAIZEN`. Degradar o gate para forçar leitura por repo
(`series="$( LEDGER_ALL_REPOS=0 kaizen_series )"`) passa **as três** asserções. Testemunhado ponta
a ponta em fixture com `05-verdict.md` na mão: base → `already judged` rc 0; degradado →
`BLOCKED in KAIZEN — two sessions without satisfying the gate`, rc 3. **É o `BUG-1` verbatim, uma
função adiante, com a seção escrita para impedi-lo inteira verde.** Direção: dirigir o gate de
verdade, não o proxy.

### N4 — a guarda do `kaizen_axis_note` é intercambiável com `sufficient == false` · **MEDIUM**

Trocar `.guard.degenerate_axis == true` por `.guard.sufficient == false` passa nos dois fixtures
(degenerado ⇒ também insuficiente; saudável ⇒ suficiente). Testemunhado num ledger de alvo
**saudável mas abaixo do piso** (2 shas × 2 missões): base cala, degradado imprime "the kit_sha
axis is degenerate here" — exatamente a leitura errada que o ADR 0003 existe para impedir, impressa
pelo runner. Falta o terceiro fixture que separa as duas guardas.

### N5 — `degenerate_axis` tem três enfraquecimentos sem probe · **MEDIUM**

`all` → `any` (verde: sha1 com 3 sessões + sha2 com 1 ⇒ vira `true`); `== 1` → `<= 1` (verde: fatia
com **zero** sessões passa a contar como degenerada); `map(select(.event=="session"))|length` →
`length` (verde ao contrário: fatia com sessão + escalada deixa de contar e a explicação some em
silêncio). Faltam três fixtures: mista, com fatia de zero sessões, e degenerada com escalada ao
lado.

### N6 — a normalização `pwd -P` não tem probe · **MEDIUM**

Os probes de worktree exercitam só a metade `--git-common-dir`. Testemunhado com checkout alcançado
por symlink: base lê `1 row(s) · …/real`; sem o `pwd -P`, `no data for …/link` — o mesmo "um repo
lido como dois" que o I4 fechou. O comentário do próprio arquivo já avisa que "TMPDIR may be a
symlink".

### N7 — repo bare devolve o diretório-pai, e cala o aviso honesto · **MEDIUM**

Em repo bare `--git-common-dir` é `.`, então `cd "./.."` dá o **pai** — dois bares irmãos colidem, e
o pai não é repo nenhum. A `main` devolvia `""` (honesto) e o `kaizen_series` avisava "not inside a
git repository"; hoje `$repo` é não-vazio-e-errado, a guarda `[ -n "$repo" ]` cala o aviso, e a
série volta vazia sem explicação.

### N8 — `degenerate_axis` é interruptor de mão única sobre o histórico inteiro · **MEDIUM**

`all($slices[]; …)` roda sobre **todo** `$ok`, isto é, toda linha comparável já escrita. Um único
`kit_sha` histórico que tenha comprado duas sessões desliga a explicação **para sempre**, mesmo com
as N versões mais recentes todas com uma sessão — e o ledger é append-only, não se migra. Medido:
20 shas × 1 sessão ⇒ `true`; acrescentando uma sessão ao sha **mais antigo** ⇒ `false`. Hoje o
ledger real dá `true`, então o recurso funciona; frágil é a durabilidade. Direção: derivar das
últimas K fatias, ou de `$latest`+`$previous`.

### N9 — quatro asserções menores sem probe · **LOW**

O cabeçalho de escopo do `--all-repos` (renomeá-lo para `$repo` é verde); a condição da quarta voz
de "no data" (`-eq "$lines"` → `-gt 0` é verde, e passa a afirmar falsidade sobre linhas que **têm**
`repo`); o nome do flag no `sdd help` (`--allrepos` é verde nos dois sensores — nada casa o que o
help anuncia com o que os parsers aceitam); e a grafia de `ledger_row_no_repo`
(`has("repo")|not` × `.repo == null`).

### N10 — `adr 0003 is named by bin/sdd` mede um comentário · **MEDIUM**

`ADR 0003` aparece 4× no `bin/sdd`, **3 delas em comentário**. Sob o degrade que tira a citação da
frase *impressa* ao humano, esta asserção seguiu `ok` — só o helper `axis_note` da outra seção ficou
vermelho. A afirmação da própria asserção ("a decision record no code cites is a label") está,
portanto, sem probe: ela mede prosa. Direção: ancorar em string de runtime.

### N11 — `no data` de ledger misto dá conselho impossível · **LOW**

Com 2 linhas sem `repo` + 1 estrangeira + 0 locais, a manchete é verdadeira mas o remédio é falso
para 2 das 3: nenhum `cwd` e nenhuma flag as trazem à tona (`--all-repos` exclui `no_repo` de
propósito). As quatro vozes nomeadas são na verdade cinco estados.

### N12 — dois ruídos menores · **LOW**

`kaizen_axis_note` faz uma segunda leitura da série logo antes do gate, então um ledger ilegível
imprime o diagnóstico cru do `jq` **duas vezes** seguidas (custo em si é irrelevante: 3000
linhas/1,1 MB ⇒ 0,19 s por leitura). E `GIT_DIR`/`GIT_COMMON_DIR` no ambiente passam a sobrepor a
identidade do `cwd`, o que a `main` não fazia — alcançabilidade real (rodar de um git hook) é
especulativa.

## O que foi refutado (com evidência, não com opinião)

- **"`--git-common-dir` volta relativo e o conserto não normaliza"** — o risco de maior
  probabilidade do plano. **Refutado por medição**: as três formas foram sondadas num repo de
  teste — raiz devolve `.git`, subdiretório devolve `../.git`, worktree (raiz e subdiretório)
  devolve o caminho absoluto do `.git` principal —, e `( cd "$start" && cd "$common/.." && pwd -P )`
  faz as três convergirem para a **mesma** string. Confere com `--show-toplevel` do checkout
  principal, e o worktree passa a devolver essa mesma string em vez da própria.
- **A explicação do eixo sai partida em dois streams** (`warn`→stderr, três `dim`→stdout).
  Considerado e **não** tratado como achado: é o padrão estabelecido do arquivo — `cmd_autonomy`
  faz igual nos quatro ramos de "no data". Corrigir só aqui criaria a inconsistência que não
  existe hoje. Se virar problema, é decisão do arquivo inteiro, não deste diff.
- **Âncoras `bin/sdd:<N>` dos três itens já `RESOLVIDO`** — estavam erradas **já na `main`**, logo
  não são drift desta missão. Corrigidas mesmo assim, por serem uma linha cada; registrado aqui
  para não contarem como defeito introduzido.
- **A mutação `KAIZEN_prompt_series_unflagged` não cobre o degrade complementar** (um "conserto"
  que fixasse a flag no prompt para sempre). O EXEC registrou isso como escolha, não esquecimento,
  e **está certo**: quem cobre esse degrade é a asserção de controle do par (`sem flag ⇒ os dois
  nus`), e um mutante para ele mediria a mesma linha duas vezes, inflando o score sem medir nada
  novo. Nenhuma ação.

## Fora de escopo → `TODO.md`

Nada novo. Os dois achados fora de escopo desta missão já estavam registrados pelo EXEC
(`b7d1c30`, `80cbea2`), e a causa-raiz do R4 — o schema da série sem sensor de drift contra a prosa
— já é item aberto do `TODO.md`; o R4 é a terceira vez que ele cobra o preço, e isso está anotado
no próprio item da missão que o registrou.

## Pendências para a fase DOCS

1. **Não estampar** `RESOLVIDO` no item do lembrete pós-pipeline — ver R2. O corpo do item já
   carrega o aviso.
2. O `KAIZEN_LOG.md` segue intocado (item K8 do checklist kaizen), com o antes/depois medido da
   série.

## Estado ao fim da rodada

- **Commits desta sessão:** `23467ca` (R1), `8f069f5` (R2–R9), mais o commit deste handoff (R10).
- **Working tree:** limpo.
- **Suíte:** `tests/run-all.sh` verde, `score: 61 caught, 0 known gap(s), of 61`, rodada depois de
  cada commit. ⚠️ **Verde aqui não quer dizer medido**: N3–N10 são doze regras que a suíte não
  sonda, e a passada de sabotagem é o instrumento que provou isso — não o `score`.
- **`sdd health`:** ok nos cinco.
- **Nada empurrado, nenhum PR aberto.**

## Boot da rodada **r2**

Ler `00-missao.md`, este arquivo e `30-handoff-qa.md`. A lista de trabalho é a seção "Achados que
NÃO fecharam", nesta ordem: **N1, N2, N3** (as três que mudam número que o juiz lê), depois
N4–N8, depois N9–N12. Cada conserto entra com sensor **e** com o degrade que o sobreviveu hoje
transformado em probe — a passada de sabotagem já entregou o probe pronto para cada um.

⚠️ Não re-litigar o que a r1 já fechou (R1–R10) nem o que ela refutou com evidência.

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | C | A disciplina de "uma definição por programa" está impecável (`is_escalation`, `on_axis`, `degenerate_axis`, `ledger_row_no_repo`; a flag entra pelo predicado único), `shellcheck -S warning` limpo em `bin/sdd` e `tests/*.sh`, e nenhuma armadilha da casa reintroduzida. Mas `ledger_repo_root` tem **duas respostas erradas provadas contra a `main`** (N1 submódulos irmãos colapsando numa identidade; N7 repo bare devolvendo o diretório-pai), e `--all-repos` agrega sem o repo na chave (N2). Três defeitos de correção no coração da mudança. |
| Type Safety | A | O análogo em bash/jq é a **shape** do contrato, e ela fecha: os dois produtores da série receberam as duas chaves novas no mesmo commit e são comparados como conjuntos de chave; `diff` de `jq -S '[paths(scalars)]'` entre eles é vazio; `degenerate_axis` é sempre booleano (fatia vazia, só-escalada, ledger vazio ⇒ `false`, nunca `null`); `guard.sufficient` e o campo exposto seguem na binding única `$observed`. |
| Error Handling | B | Direção segura preservada (`ledger_repo_root` devolve vazio em vez de morrer; `kaizen_axis_note` sai calado sem `jq`; opção desconhecida morre alto nos dois parsers; as exclusões saem **contadas**, nunca sumidas). Desconta N7 — em repo bare o aviso honesto "not inside a git repository" foi **silenciado** por um `$repo` não-vazio-e-errado, e a série volta vazia sem explicação, que é o zero que este arquivo gasta suas linhas recusando — e N11/N12 (conselho impossível em ledger misto; diagnóstico do `jq` impresso em dobro). |
| Security | A | Varredura determinística de segredos sobre o diff completo (catálogo canônico + regex): `{"findings":[],"scanners":["regex"],"errors":[]}`. Sem entrada de rede, sem `eval` de dado externo, sem escrita fora de `$SDD_STATE_DIR`/repo. O único `eval` novo está num **teste**, sobre uma linha que o próprio runner acabou de escrever, e é deliberado. O `repo:` do ledger pode carregar caminho de cliente — já era assim, e a doc repete por que o arquivo mora em `$HOME` e nunca é commitado. |
| Performance | A | `jq` sobre um JSONL de dezenas de linhas. As passadas novas (`norepo` no `cmd_autonomy`, a segunda leitura da série no `kaizen_axis_note`) foram **medidas**: 0,19 s por leitura em 3000 linhas / 1,1 MB, irrelevante nesta ordem de grandeza. A suíte com 61 mutantes segue no orçamento de sempre. |
| Test Coverage | C | 10 asserções novas, todas diferenciais, 3 com testemunha de regime, escritor real exercitado por `git worktree add` — e catálogo 55 → 61 com `0 known gap(s)`. Mas a passada de sabotagem adversarial que o `CLAUDE.md` exige de sensor novo **não tinha sido feita**, e ela achou **10 de 27 degrades sobrevivendo verdes**, um deles reproduzindo o `BUG-1` da QA *verbatim* uma função adiante (N3) com a seção escrita para impedi-lo inteira verde. Mais a asserção do ADR que media prosa (N10) e a que falhava aberto (R1, fechada). Verde estava medindo menos do que afirmava. |
| Documentation | A | Depois de R2–R10: o schema da série está em passo nos **cinco** lugares que o descrevem (`bin/sdd`, `docs/pipeline.md`, `agents/sdd-kaizen.md` + a cópia `.claude/` byte-idêntica, `CONTEXT.md`); `--all-repos` documentado em `usage()`, `README.md` e `pipeline.md`; o runbook de `failure-modes.md` prescreve o diagnóstico que hoje funciona; o ADR 0003 confere no formato dos dois anteriores e **todas** as suas afirmações sobre o código foram verificadas uma a uma. As três afirmações falsas sobre o `kaizen_reminder` saíram, e o item de `TODO.md` que não pode ser fechado carrega o aviso de por quê. |
| **Overall** | **C** | Dez achados consertados nesta sessão com prova (um sensor que falhava aberto, três afirmações falsas, todo o drift de contrato). **Doze não fecharam**, e três deles mudam número que o juiz lê, em silêncio: dois submódulos irmãos lidos como um repo só, repo bare lido como o pai, e `--all-repos` fundindo missões de projetos diferentes pelo slug. O gate reprova de propósito — este é o número real, e a r2 continua o laço com a lista pronta. Inflar isto para A desligaria o único sensor de qualidade da missão exatamente onde ele acabou de encontrar alguma coisa. |
