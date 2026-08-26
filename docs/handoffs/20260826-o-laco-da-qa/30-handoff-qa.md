---
missao: 20260826-o-laco-da-qa
fase: QA
status: done
sessao: 0cab0a45-7a5a-4792-baeb-b3b521152f1d
data: 2026-08-26 16:45
gate: "Ramo **sem interface** (`E2E_CMD=\"\"`, sem `APP_URL`): não há navegador nem skill `qa-report`/`qa-execution`, então as jornadas foram andadas por mim, no terminal, e a evidência é esta. **J1 — o gênero do bug decide se ele barra:** fixture do `check-gates.sh` reescrito bug a bug, `sdd phase` lido a cada volta — `human` → `REVIEW` (passa), `agent` → `QA` (barra), campo ausente → `QA` (barra); as 3 asserções antigas verdes. Mas `humano`, `humans`, `human-ish` e `humanoid` → **`REVIEW`** (casa por PREFIXO), e um bug cujo campo diz `agent` que apenas CITA a linha humana num bloco cercado → **`REVIEW`** (casa em QUALQUER linha). Os dois passam com `why` dizendo *'registry clean, suites green'*. Medido limpo no mesmo fixture: o campo é inerte nos outros 4 status, 8 regimes. **J2 — `status: blocked` escala:** fixture do `check-autonomy.sh`, ledger lido com `jq` — `blocked` na 1ª sessão → `rc 3`, **1** sessão, `kind: handoff-blocked`; falha ordinária → `rc 3`, **2** sessões, `kind: no-progress`. Mas quando quem declara é o **retry inline**, a corrida gasta **3** sessões, e se a sessão também abriu uma linha `F<n> pending` — que é o que o `§ 4` manda a QA fazer — o marcador SOBREVIVE à volta e a escalada sai `{phase: EXEC, kind: handoff-blocked}`, com o runner afirmando que o handoff da EXEC declara `blocked` quando ele diz `done`. Controle diferencial no mesmo fixture, mudando só essa palavra: `{phase: EXEC, kind: no-progress}`, 4 sessões. **J3 — o espelho do agente:** `./bin/sdd preflight` → `preflight ok`, `7 kit agent(s) checked`, medido ANTES desta sessão tocar o disco. **Suítes:** `./tests/run-all.sh` → `suite green`, rc 0, 581 asserções, 0 FAIL, também antes das minhas edições; `bash tests/check-gates.sh` → rc 0, 132 `ok`; `bash tests/check-autonomy.sh` → rc 0, 185 `ok`. **Depois** dos 4 sensores novos, de propósito: `check-gates.sh` 132 `ok` + **2 FAIL**, `check-autonomy.sh` 184 `ok` + **2 FAIL** — sensor que passa com o bug presente não é sensor, é decoração."
---

# Handoff — QA — a fase QA para de girar em bug que ninguém pode fechar

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

3 jornadas andadas no terminal, **2 achados confirmados** — cada um com um sintoma barato e um caro,
e o caro só apareceu na segunda passada. Viraram **4 sensores permanentes vermelhos** e **`F1`/`F2`**
no checkpoint; nenhum foi para decisão humana, os dois têm causa técnica clara. Mais **3 drifts de
documentação** roteados para a DOCS, um deles contrato (`docs/pipeline.md`). Os 4 incrementos do
plano fazem o que prometem — os achados são a **fronteira** de cada um. Próxima fase é **EXEC**
(`sdd phase` → `EXEC`), não REVIEW: o laço QA⇄EXEC está armado.

## Estado do repo

- **Branch:** `fix/o-laco-da-qa` — **local só**, nunca empurrada; base em `ef05eba` (`main`).
- **Último commit:** `ea0480f` `chore(checkpoint): I4 done em cf43bb3, e o handoff que fecha a fase EXEC`
- **Working tree:** sujo com os 2 sensores + `checkpoint.md` + este handoff, que vão no commit desta
  fase. **`bin/sdd` intocado** — `sdd-qa` não conserta produção.
- **Suíte:** `./tests/run-all.sh` → `suite green`, rc 0, 581 asserções, 0 FAIL — medido **antes**
  das minhas edições. **Depois**, VERMELHA de propósito: 4 FAIL. É o artefato que o `§ 3` do
  `agents/sdd-qa.md` manda commitar, e é o que `F1`/`F2` apagam.
- **E2E:** `E2E_CMD=""` e `APP_URL` não definido — **projeto sem interface**. Não rodou porque não
  existe, não porque foi pulado; a evidência da jornada é o campo `gate:` acima.

## O que foi feito

Nenhum commit ainda no momento da escrita — o desta fase carrega os quatro arquivos abaixo.

- `tests/check-gates.sh` — 2 regimes: o gênero é a **palavra inteira** (diferencial de UMA LETRA,
  `human` × `humano`) e o gênero é do **campo** (diferencial `human` real × `human` citado sob um
  campo `agent`). A metade exata carrega a legenda `<!-- agent | human -->` que os arquivos reais
  preservam, então um conserto que ancore o fim da linha sem admitir a legenda fica vermelho aqui em
  vez de passar calado.
- `tests/check-autonomy.sh` — 2 regimes: a escalada de `blocked` vale no **retry inline**, e ela
  **nomeia a fase que a declarou**. O segundo par tem **controle**: os dois lados acrescentam a mesma
  linha `F<n> pending`, então os dois de fato oferecem a EXEC como fase seguinte — sem isso,
  "escalona QA" passaria num fixture que nunca saiu da QA. O fixture é devolvido no estado em que foi
  achado (stub morto, checkpoint restaurado, handoff não-`blocked`).
- `docs/handoffs/20260826-o-laco-da-qa/checkpoint.md` — `F1` e `F2` `pending`, mais 10 notas de QA.
- `docs/handoffs/20260826-o-laco-da-qa/30-handoff-qa.md` — este arquivo.

## Artefatos

| Arquivo | O que contém |
|---|---|
| `tests/check-gates.sh` | os 2 diferenciais do gênero (sensores do achado 1 / `F1`) |
| `tests/check-autonomy.sh` | os 2 diferenciais da escalada (sensores do achado 2 / `F2`) |
| `docs/handoffs/20260826-o-laco-da-qa/checkpoint.md` | `F1`/`F2` `pending` + a procedência de cada um |
| `docs/handoffs/20260826-o-laco-da-qa/30-handoff-qa.md` | este arquivo; o `gate:` é a evidência das jornadas |

## Os dois achados, com reprodução

### Achado 1 — a Âncora 3 não lê o gênero: lê duas palavras em qualquer lugar (→ `F1`)

`bin/sdd:639` é um `grep -qE '…\*\*Closable by:\*\*[[:space:]]+human'`. Duas coisas erradas na mesma
linha, e as duas fazem o bug **parar de barrar**, que é a direção permissiva:

**(a) Casa por PREFIXO** — não há fronteira à direita, então todo valor que apenas COMEÇA por `human`
é lido como o gênero `human`:

```
humano -> REVIEW    humans -> REVIEW    human-ish -> REVIEW    humanoid -> REVIEW
Human  -> QA        HUMAN  -> QA
```

**`humano` é a grafia pt-BR**, e `.sdd/config.sh` deste repo declara `OUTPUT_LANG="pt-BR"`: a
tradução que o contrato proíbe era exatamente a que passava. O `agents/sdd-qa.md`, seção `Language`,
afirma o **oposto** com todas as letras — *"a translated genre is a genre the gate cannot read, and
it reads as absent, which blocks"*.

**(b) Casa em QUALQUER LINHA** — `grep -q` é verdadeiro para o arquivo inteiro. Um bug cujo **campo**
diz `agent` para de barrar assim que o corpo **cita** a linha humana:

```
open + Closable by: agent, citando a linha humana num bloco ```md  ->  phase=REVIEW
why = "journey walked without a browser interface (evidence in the handoff), suite green"
```

Não é corpo rebuscado: o `§ 5.1` do `agents/sdd-qa.md` **imprime essa linha exata** para o agente
copiar, então um bug arquivado *sobre o campo de gênero* é a primeira vítima provável. A assimetria é
o que faz disso defeito e não mania: a âncora irmã (`Status: open`) também casa em qualquer linha,
mas lá isso só pode fazer o bug **barrar**. Esta é a primeira do gate em que casar em qualquer lugar
é **permissivo** — e o comentário do `bin/sdd:631-637` chama a âncora de *"strict about it"* sendo
estrita só contra a armadilha da legenda.

Os dois são **fail-open**: o gate afirma medir o que não mede, e responde *"registry clean, suites
green"* com um bug `open` e sanável no registry. **Medido limpo** no mesmo fixture: o campo é inerte
nos outros 4 status (`fixed`/`verified`/`wont-fix`/`invalid` × `agent`/`human`, 8 regimes, todos
`REVIEW`) — a Âncora 3 só consulta o gênero em arquivo que o grep de `Status: open` já listou.

### Achado 2 — a escalada imediata não vale no retry, e o marcador sobrevive à volta (→ `F2`)

O ramo do I3 (`bin/sdd:3498`) está só na **primeira volta**. O retry inline (`:3538`) chama o mesmo
gate, que arma o mesmo `GATE_HANDOFF_BLOCKED`, mas abaixo dele só se lê `moved2`. Dois sintomas:

**(a) Custa uma sessão.** Retry que declara `blocked` e **commita** lê como *"moved forward, carrying
on"*:

```
hoje:            rc=3  sessions=3  kind=handoff-blocked
com o conserto:  rc=3  sessions=2  kind=handoff-blocked
```

**(b) Escalona a FASE ERRADA, com motivo falso — e este é o caro.** O marcador é global,
`current_phase` roda em **subshell** e não limpa a cópia do pai, e `gate_EXEC` — como todo gate que
não é o `gate_QA` — nunca o toca. A volta que o retry compra roda `gate_EXEC` com o marcador ainda
`1`, e o leitor do `:3498` dispara **para EXEC**:

```
fail  BLOCKED in EXEC — 1 of 2 increment(s) still to execute
      The line stopped on purpose: the phase's handoff declares 'status: blocked'.
{"event":"blocked","kind":"handoff-blocked","phase":"EXEC"}
```

O `20-handoff-exec.md` desse fixture diz **`done`**. O runner manda o humano consertar um status que
não existe, engole o retry que a EXEC tinha direito, e grava `kind` errado no ledger que o juiz do
kaizen lê. **Controle diferencial**, mesmo fixture, mesma linha `F<n> pending`, mudando só a palavra
do handoff da QA: `{phase: EXEC, kind: no-progress}`, 4 sessões. Uma palavra no handoff da **QA**
troca a escalada da **EXEC** de motivo verdadeiro para motivo falso.

É exatamente a falha que o CONTRATO do `bin/sdd:508-511` avisa para um **segundo setter** —
alcançada com só o primeiro, porque o marcador sobrevive à **volta** e não a um gate. ⚠️ E o gatilho
é o pipeline seguindo as próprias instruções: o `§ 4` do `agents/sdd-qa.md` manda a QA responder bug
sanável com linha `F<n>` `pending`, e linha `pending` é justamente o que manda a volta seguinte para
EXEC. **A QA fazendo o trabalho dela é o gatilho** — inclusive esta sessão, que escapou só por ter
declarado `done` na primeira volta em vez de passar pelo retry.

## Boot da próxima fase

**A próxima é EXEC, não REVIEW** — `./bin/sdd phase 20260826-o-laco-da-qa` → `EXEC`, com
`2 of 6 increment(s) still to execute`. É o laço QA⇄EXEC do `QA_MAX_ITER`, funcionando.

**Para quem executar `F1` e `F2` — os dois consertos já foram MEDIDOS, numa cópia do repo em
`/tmp`, nunca aqui.** `sdd-qa` não conserta produção, mas entregar um Check que ninguém sabe se é
satisfazível custaria uma volta inteira. O que a medição diz, com as 4 asserções no lugar:

- `F1`: extrair primeiro a **linha do campo** e só então casar contra ela —
  `genre_line="$(grep -m1 -E '^\-[[:space:]]+\*\*Closable by:\*\*' "$bugfile" || true)"`, depois
  `grep -qE '…[[:space:]]+human([[:space:]]|$)' <<< "$genre_line"`. Resolve posição e grafia de uma
  vez. `check-gates.sh` 132 → **134** `ok`, rc 0.
- `F2`: o mesmo ramo do `:3498` copiado para **depois** do `gate_"$phase"` do retry (`:3538`).
  `check-autonomy.sh` 185 → **187** `ok`, rc 0.
- Os dois juntos: `./tests/run-all.sh` → `suite green`, rc 0, **585** asserções, 0 FAIL (hoje 581).

⚠️ **Três armadilhas na forma, todas medidas:** a âncora **tem de aceitar a legenda**
`human <!-- agent | human -->` que os arquivos reais preservam — um `$` puro no fim reprova a metade
exata do diferencial; consertar só a grafia deixa a metade `the genre is the FIELD` vermelha; e o
casamento final vai por **herestring**, nunca `grep -m1 … | grep -q …`, que é a família de `pipefail`
que este repo já paga (o `grep` que acha e sai antes devolve 141).

⚠️ **Não mova o ponto de amostragem de `moved2`** — a proibição do `01-plano.md` continua de pé, e o
conserto não precisa dela.

⚠️ **Os dois ramos novos nascem sem mutante**, e o precedente é desta própria missão: o I2 e o I3
entregaram cada um o seu. Sem isso o catálogo segue dizendo `all 8 gates have a mutation` enquanto as
linhas novas não têm quem as meça. **Ancore no CÓDIGO**, nunca em `.*Closable by.*human.*` nem em
`.*GATE_HANDOFF_BLOCKED.*`: as duas frases vivem em comentário logo ao lado, e mutante que reescreve
só comentário **aplica**, passa da guarda `cmp -s` e não sabota nada — lição que o I2 já pagou.
(Medido e **limpo**: os 150 mutantes de hoje aplicam em `bin/sdd` sem nenhum no-op, então nenhuma
âncora apodreceu com o que a missão moveu.)

⚠️ **O carimbo de mutação está morto e tem de ser retirado de novo.** `F1` e `F2` tocam `bin/` e
`tests/`, que são a chave. Rode `./bin/sdd health --with-mutation` **depois do último commit de
código** — ~12min32s nesta máquina — e lembre que `tests/health-baseline.txt` também invalida.

⚠️ **`./bin/sdd preflight` acusa 2 fails agora** (`TEST_CMD FAILED`, `working tree dirty`), e os dois
são desta sessão: os sensores vermelhos e este commit. Era `preflight ok` antes. Limpam com `F1` e
`F2` verdes — não são achado, são o estado esperado do laço.

**O que o REVIEW precisa saber quando chegar a vez dele:** os 4 incrementos do plano fazem o que
prometem — as 3 asserções de gênero do I2 e o diferencial do I3 estão verdes e foram andadas à mão,
não só lidas. Os 2 achados são a **fronteira** de cada um (as duas bordas de uma âncora; a segunda
porta de um ramo), não a negação. E a prosa corrigida do `§ 5`/`§ 5.1` do `agents/sdd-qa.md` segue
**sem sensor próprio** — limite já declarado pela EXEC, e o achado 1(a) é exatamente o caso em que a
prosa (`Language`) e o código discordavam sem nada ficar vermelho.

## Drift para a fase DOCS (não é achado fora de escopo — é a documentação desta missão)

A EXEC já deixou 3 itens aqui (`docs/qa/README.md:109-113`, `KAIZEN_LOG.md`, `CLAUDE.md`). A QA achou
mais **3**, todos causados por esta missão e nenhum deles na lista da EXEC:

- **`docs/pipeline.md:142` ficou FALSO.** Diz *"no file in `<QA_DOCS_PATH>/bugs/` has
  `**Status:** open` (true in both cases)"* como condição do `gate_QA` — e desde o I2 um bug
  `Closable by: human` com `Status: open` passa. `:140` (*"Anchor 3 below (`bugs/` with no
  `Status: open`)"*) e `:145` (que lista `wont-fix` e `invalid` como os **únicos** que não barram)
  são a mesma frase em outras palavras. Reproduzido: bug `open` + gênero humano → `phase=REVIEW`.
- **`docs/pipeline.md:538` documenta o `kind` do ledger como um enum FECHADO de quatro valores**
  (`increment-blocked | budget-exhausted | no-progress | review-to-draft`), e o I3 escreveu um
  quinto: `bin/sdd:3508` grava `handoff-blocked`. `grep -rn 'handoff-blocked' docs/ config/ agents/
  templates/` → **0** ocorrências fora dos artefatos desta missão. É o caso que o `CLAUDE.md` nomeia
  — *"Mudou o contrato de artefato? Atualize `templates/`, `docs/pipeline.md` e o agente afetado no
  mesmo commit"* —, e `docs/pipeline.md` é o **esquema de registro** do ledger. Os leitores em tempo
  de execução estão a salvo (medido: `is_escalation` é definido só sobre `.event`, e as duas
  agregações usam `group_by(.kind)` dinâmico, então `handoff-blocked` é admitido, contado e impresso,
  sem cair em `excluded.unrecognized`) — o estrago é no documento, que é de onde o próximo leitor de
  enum vai ser escrito.
- **`agents/sdd-qa.md:92` ficou impreciso:** *"It repeats until the registry is empty, capped by
  `QA_MAX_ITER`"*. Desde o I2 ele repete até não sobrar bug **sanável por agente** — que é o ponto
  inteiro da missão. ⚠️ Mexer nesse arquivo exige `./bin/sdd install --force` para sincronizar o
  espelho, nunca `cp` nem Edit.

## Pendências / Decisions for a Human

> Só julgamento humano genuíno (política de UX, decisão de produto, pagamento real, acesso
> externo). **Não bloqueiam o pipeline** — viram seção do PR. Bug sanável não entra aqui: vira
> incremento de fix no `checkpoint.md`.

**Vazio, e é uma decisão, não uma omissão.** Os dois achados têm causa técnica clara e o ciclo
`F<n>` fecha sobre eles, então pelo `§ 4` do `agents/sdd-qa.md` viram fix e **não** entram aqui.
Nenhum bug foi marcado `Closable by: human` nesta sessão — marcar exige procedência citada em
`arquivo:linha` nesta seção, e nenhum dos dois espera decisão de produto, política ou acesso que só
um humano tenha. Nenhuma intervenção humana entrou na linha: o `checkpoint.md` não tem linha
`intervention:`.

## Riscos e não-feitos

- **Nenhum arquivo de `docs/qa/` foi criado, editado ou apagado.** A árvore é das skills, o ramo é
  sem interface, e não bootstrapar ≠ apagar. O registry do kit segue com 6 bugs, 0 `open` — então
  esta missão **não** exercitou a Âncora 3 contra um registry real, só contra fixture. O efeito
  medido (12 sessões de QA numa missão) só reaparece numa missão de repo-alvo.
- **O campo `Closable by:` não chega sozinho a repo-alvo nenhum, e isso não está escrito em lugar
  nenhum.** `docs/qa/templates/bug.md` deste repo é cópia byte a byte do asset da skill instalada, e
  a linha do I1 é hoje a **única** diferença entre os dois; a skill `qa-report` semeia o template do
  projeto a partir do **asset dela**, e `cmd_install` não distribui árvore `docs/qa/`. Ou seja: em
  repo-alvo todo bug escrito pela skill nasce **sem** o campo e barra — que é o fail-safe pedido, e o
  `§ 5.1` manda o `sdd-qa` marcar —, mas ninguém documenta semear o campo, e **nenhum sensor cobre
  `docs/qa/templates/`** (`check-templates.sh` lê só `templates/`). Fica dito aqui, e não no
  `TODO.md`, pela régua de admissão do D15: não é fail-open e o caminho previsto funciona.
- **O campo `Closable by:` nunca foi exercitado por um agente de verdade.** O `§ 5.1` é dever novo
  desta missão e esta sessão é a primeira a lê-lo — e não teve bug para marcar.
- **A caixa do gênero não foi decidida, só medida.** `Human` e `HUMAN` barram (o casamento é sensível
  a caixa). Isso é fail-**safe**, então não virou `F<n>`; mas ninguém escreveu em lugar nenhum que o
  gênero é minúsculo, e um agente que escreva `Human` verá o bug barrar sem explicação.
- **O conserto de `F2` fecha a reprodução, mas o comentário-contrato do `bin/sdd:507-511` continua
  descrevendo uma garantia mais forte do que o código dá.** Com o ramo no retry o marcador não
  sobrevive a volta nenhuma (toda volta em que ele está armado devolve 3), então a propriedade passa
  a valer — mas por consequência do fluxo, não por construção. Quem escrever um **segundo** setter ou
  um segundo leitor tem de reler as duas notas, não só o comentário.
- **Não verificado:** o comportamento sob `sdd retry` (o comando, não o retry inline).
  `cmd_retry` (`:3590-3595`) devolve `3` em qualquer reprovação de gate, então um handoff `blocked`
  já escala por lá — mas ele **não escreve linha de escalada no ledger** em caso nenhum, o que é
  anterior a esta missão e fora do escopo dela.
- **`F1` e `F2` foram medidos numa cópia, não aqui** — a árvore real nunca recebeu conserto de
  produção desta sessão, por regra não-negociável.

## Achados fora de escopo

> Dois destinos, e a diferença já custou uma `main` vermelha (`2d28d13`).
>
> **Achado sobre o repo-alvo:** registrado no `TODO.md` dele; aqui fica só o ponteiro, para o PR
> conseguir citar.
>
> **Achado sobre o kit** (runner, agente, template), numa missão cujo repo NÃO é o kit: a sessão
> não escreve, não commita e não entra no repositório do kit. A linha **completa** do achado mora
> aqui, marcada `kit:`, e quem a transporta é um humano ou a triagem do `sdd kaizen`. Ponteiro para
> um arquivo que ninguém escreveu é achado perdido.
>
> O exemplo abaixo mora **dentro** desta citação pelo mesmo motivo que o `- intervention:` do
> `checkpoint.md` (`cd49351`): exemplo que abre a linha com `-` é contado verbatim por quem vier
> varrer os handoffs atrás de `kit:`, e todo handoff nasceria devendo um achado fantasma. Copie a
> forma para fora da citação ao registrar um achado de verdade.
>
> - kit: <o quê> — <arquivo:linha do kit> — <por que importa>

Nenhum. **Esta missão é do próprio kit**, então achado de kit iria ao `TODO.md` daqui pela regra
normal — e tudo o que apareceu está **dentro** do escopo: os dois defeitos moram em linhas que esta
missão escreveu (viraram `F<n>`) e os três drifts descrevem o que ela mudou (foram para a DOCS). O
`TODO.md` não foi tocado, e isso também protege o carimbo de mutação (`tests/health-baseline.txt` é
a catraca dele).
