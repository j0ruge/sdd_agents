---
missao: 20260826-o-laco-da-qa
fase: EXEC
status: done
sessao: 9988254d-d42f-4f33-8489-017c40aab9c0
data: 2026-08-26 18:40
gate: "`tests/run-all.sh` → `suite green`, rc 0, **585** asserções `ok`, 0 FAIL. Sensores tocados pelos 6 incrementos: `check-gates.sh` rc 0, 129 → **134** `ok` (3 regimes de gênero no I2, 2 no F1); `check-autonomy.sh` rc 0, 184 → **187** `ok` (1 diferencial no I3, 2 no F2). Re-walk das duas metades de cada diferencial de escalada, com VALOR e não com 'passou', numa cópia em `/tmp` com piso contra vacuidade: primeira volta `3|1|blocked|handoff-blocked` × `3|2|blocked|no-progress`; retry `3|1|…handoff-blocked` × `3|2|…handoff-blocked` (antes do F2 era `3|3`); fase `QA|handoff-blocked` × `EXEC|no-progress` (antes do F2 era `EXEC|handoff-blocked`). `./bin/sdd preflight` → `preflight ok`, `7 kit agent(s) checked` — é ele que compara `agents/` com o espelho `.claude/agents/`. Carimbo de mutação tirado **depois** do último commit de código (`26b74a0`): `./bin/sdd health --with-mutation` → `kit healthy`, rc 0, `mutation: score: 153 caught, 0 known gap(s), of 153`, `all 8 gates have a mutation in the catalogue`, `mutation stamp written — gate_PR can see that THIS content ran green`, `provenance: all 3 fixtures match the installed skills`, `ratchet: 1 known debt(s), none new`."
---

# Handoff — EXEC — a fase QA para de girar em bug que ninguém pode fechar

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

**6 incrementos `done`, um commit cada, nenhum `blocked`** — os 4 do plano mais os 2 `F<n>` que a
QA abriu. A Âncora 3 do `gate_QA` distingue **gênero** de bug e o lê do **campo**, como palavra
inteira; `status: blocked` no handoff escala na primeira sessão **e no retry inline**, nomeando a
fase que declarou. Suíte verde em **585** asserções. Próxima fase é **REVIEW** — o laço QA⇄EXEC
fechou, e o `sdd status` já o diz.

## Estado do repo

- **Branch:** `fix/o-laco-da-qa` — **local só**, nunca empurrada (`git push` não é desta fase);
  base em `ef05eba` (`main`), **12 commits à frente, 0 atrás**.
- **Último commit:** `26b74a0` `fix(runner): a escalada de `blocked` vale também no retry inline`
- **Working tree:** limpo no momento do commit do código; suja de novo com este handoff + o
  `checkpoint.md`, que vão no commit seguinte.
- **Suíte:** `tests/run-all.sh` → **verde**, rc 0, **585** asserções `ok`, 0 FAIL.
- **E2E:** `E2E_CMD=""` e `APP_URL` não definido — **projeto sem interface**, o ramo já previsto
  no `01-plano.md`. Não rodou porque não existe, não porque foi pulado.
- **Carimbo de mutação:** tirado **depois** do último commit de código (`26b74a0`).
  `./bin/sdd health --with-mutation` → `kit healthy`, rc 0, com
  `mutation: score: 153 caught, 0 known gap(s), of 153`,
  `all 8 gates have a mutation in the catalogue`,
  `mutation stamp written — gate_PR can see that THIS content ran green`,
  `provenance: all 3 fixtures match the installed skills` e
  `ratchet: 1 known debt(s), none new`. Eram **150** quando a EXEC fechou os 4 incrementos do
  plano; os **5** desta missão estão dentro dos 153, cada um conferido **na lista `CATALOG` e não
  só definido** — `QA_bug_genre_ignored`, `QA_bug_genre_prefix`, `QA_bug_genre_anywhere`,
  `RUN_blocked_not_escalated` e `RUN_blocked_retry_not_escalated`.

## O que foi feito

**Os 4 incrementos do plano:**

- `525b216` — **I1**: `docs/qa/templates/bug.md` ganhou `- **Closable by:** agent <!-- agent |
  human -->`, na mesma forma do `Status:` irmão (valor colado ao campo, enum no comentário).
  Sozinho é formato: quem prova é o leitor do I2.
- `0a0f760` — **I2**: a Âncora 3 (`bin/sdd`, `gate_QA`) conta como bloqueante só o bug `Status:
  open` que **não** é `Closable by: human`. Ausente ⇒ conta, que é o comportamento de hoje e o
  fail-safe do registry legado. 3 regimes novos em `tests/check-gates.sh`, um deles
  **diferencial**, mais o mutante `mut_QA_bug_genre_ignored`.
- `4c9b080` — **I3**: gate reprovado **porque o handoff declara `status: blocked`** sai `3` na
  primeira sessão, sem passar pelo heurístico de `moved2`. O ramo lê o global
  `GATE_HANDOFF_BLOCKED` (forma do `GATE_EXEC_DIRTY`), **nunca** um substring de `GATE_WHY` — a
  palavra "blocked" também aparece na linha de Jidoka do `gate_EXEC`. Regime diferencial em
  `tests/check-autonomy.sh` + mutante `RUN_blocked_not_escalated`.
- `cf43bb3` — **I4**: `agents/sdd-qa.md`. O `§ 5` passou a explicar o mecanismo em vez de afirmar
  sem ele, e nasceu o `§ 5.1` com o **dever de marcar o gênero** — a única linha de um arquivo de
  bug que é do agente —, com a proibição de tocar em `Status:` repetida ali dentro. Marcar `human`
  exige procedência citada em `arquivo:linha` na seção "Decisions for a Human" do próprio handoff.
  Espelho `.claude/agents/sdd-qa.md` sincronizado por `./bin/sdd install --force`, nunca por `cp`.

**Os 2 `F<n>` que a QA abriu** (`142c3c3` trouxe os 4 sensores vermelhos que os definem):

- `878b37c` — **F1**: a Âncora 3 lê o gênero do **campo** e como **palavra inteira**. Antes casava
  por prefixo (`humano`, a grafia pt-BR deste repo, passava) e em **qualquer linha** (um bug
  `Closable by: agent` deixava de barrar assim que o corpo **citasse** a linha humana — e o
  `§ 5.1` imprime essa linha exata para o agente copiar). O conserto extrai primeiro a linha do
  campo (`grep -m1`) e só então casa contra ela, por **herestring**, resolvendo posição e grafia de
  uma vez. Dois mutantes, porque as duas metades falham aberto independentemente:
  `QA_bug_genre_prefix` e `QA_bug_genre_anywhere`.
- `26b74a0` — **F2**: a escalada de `blocked` vale também no **retry inline**. O ramo do I3 estava
  só na primeira volta; o retry chamava o mesmo gate, que armava o mesmo marcador, mas abaixo dele
  só se lia `moved2`. Custava uma sessão — e, pior, **a fase errada**: o marcador é global,
  `current_phase` roda em subshell e não limpa a cópia do pai, e `gate_EXEC` nunca o toca, então a
  volta que o retry comprava disparava a escalada **para EXEC**, com o runner afirmando que o
  `20-handoff-exec.md` declara `blocked` quando ele diz `done`, engolindo o retry a que a EXEC
  tinha direito e gravando `kind` errado no ledger que o juiz do kaizen lê. Uma definição
  (`handoff_blocked_escalation()`) e **duas portas**, com um mutante por porta.

## Artefatos

| Arquivo | O que contém |
|---|---|
| `docs/qa/templates/bug.md` | o campo `Closable by:` que a Âncora 3 lê |
| `bin/sdd` (`gate_QA`) | Âncora 3 com gênero, lido do campo e como palavra inteira |
| `bin/sdd` (`handoff_blocked_escalation` + `cmd_run`) | a escalada de `blocked`: uma definição, duas portas |
| `bin/sdd` (`GATE_HANDOFF_BLOCKED`) | o contrato do marcador, reancorado no commit do F2 |
| `tests/check-gates.sh` | 5 regimes de gênero (3 do I2 + 2 do F1), diferenciais |
| `tests/check-autonomy.sh` | 3 diferenciais de escalada (1 do I3 + 2 do F2) |
| `tests/check-mutation.sh` | 5 mutantes desta missão — ver § Boot |
| `agents/sdd-qa.md` + espelho | `§ 5` verdadeiro e `§ 5.1`, o dever de marcar |
| `docs/handoffs/20260826-o-laco-da-qa/checkpoint.md` | 6 linhas `done` com hash, e as notas |
| `docs/handoffs/20260826-o-laco-da-qa/30-handoff-qa.md` | os 2 achados com reprodução; o `gate:` é a evidência das jornadas |

## Boot da próxima fase

**A próxima é REVIEW, não QA** — `./bin/sdd phase 20260826-o-laco-da-qa` → `REVIEW`, com
`no 40-review-r<N>.md`. O laço QA⇄EXEC do `QA_MAX_ITER` fechou: a QA achou 2 defeitos, viraram
`F1`/`F2`, a EXEC os fechou, e o `gate_QA` hoje responde
*"journey walked without a browser interface (evidence in the handoff), suite green"*.

Ler, nesta ordem: `00-missao.md` (a métrica são 5 fatos binários), `01-plano.md` (o "contexto
verificado" poupa re-descoberta), este handoff, o `30-handoff-qa.md` (os 2 achados com reprodução)
e o `checkpoint.md` inteiro — as notas de execução carregam os avisos que custaram caro.

**O que no diff é visível para o usuário.** O "usuário" do kit é quem roda `sdd`, e quatro coisas
mudaram para ele:

1. **A fase QA deixa de barrar em bug de decisão humana.** Antes, um `docs/qa/bugs/*.md` com
   `Status: open` reprovava o `gate_QA` fosse de que gênero fosse. Agora `Closable by: human`
   passa; `agent` e **ausente** continuam barrando. O gênero é lido do **campo**, como palavra
   inteira e em minúsculas — `humano` não é `human`, e citar a linha humana no corpo não conta.
2. **`status: blocked` num handoff encerra a corrida na hora**, com `rc 3` e a linha de ledger
   `event: blocked`, `kind: handoff-blocked` — na primeira volta **e** no retry inline. Antes
   custava uma sessão a mais para provar a mesma coisa, e no caminho do retry escalava a **fase
   seguinte** com motivo falso.
3. **`handoff-blocked` é um `kind` novo no ledger.** `docs/pipeline.md:538` ainda o documenta como
   enum fechado de quatro valores — está na lista de drift da DOCS.
4. **O `sdd-qa` tem um dever novo:** marcar `Closable by:` ao triar.

**Jornadas tocadas, e como andar cada uma no terminal** (não há navegador):

- `bash tests/check-gates.sh` → rc 0, **134** `ok`. As cinco asserções da jornada do gênero:
  `genre differential: human-closable passes, agent-closable blocks, reasons differ`,
  `only the agent-closable regime carries the blocking marker`,
  `an open bug with no genre field still blocks (fail-safe for the legacy registry) → QA`,
  `the genre is the whole word: 'human' passes, the near-miss 'humano' still blocks` e
  `the genre is the FIELD: a bug that merely quotes the human line still blocks`.
- `bash tests/check-autonomy.sh` → rc 0, **187** `ok`. As três da jornada de escalada:
  `status: blocked escalates on the first session, where an ordinary gate failure still spends two`,
  `a retry session that declares blocked escalates on that declaration, not a lap later` e
  `the escalation names the phase whose handoff declared it, never the one that came next`.
- `./bin/sdd preflight` → `preflight ok` (é ele que pega espelho de agente desatualizado).
- `./tests/run-all.sh` → `suite green`, 585 asserções.

**Como subir o ambiente:** não há ambiente a subir. `bash`, `git`, `jq`, `gh` e `shellcheck` já
estão na máquina — o `preflight` mede todos e passou.

⚠️ **Os 5 mutantes desta missão, para quem for reancorar qualquer um deles:**
`QA_bug_genre_ignored`, `QA_bug_genre_prefix`, `QA_bug_genre_anywhere`,
`RUN_blocked_not_escalated` (**reancorado** no F2) e `RUN_blocked_retry_not_escalated` (novo).
Os dois últimos são **ranged por necessidade** — desde o F2 as duas portas da escalada são o
**mesmo texto**, então um `s|…|…|` sem range reescreveria as duas e nenhum isolaria porta nenhuma.
Ancore sempre em **código**: `handoff_blocked_escalation` e `Closable by … human` vivem em
comentário logo ao lado, e mutante que reescreve só comentário **aplica**, passa da guarda `cmp -s`
e não sabota nada.

⚠️ **O registry do próprio kit está limpo** (`docs/qa/bugs/*.md` → 6 arquivos, 5 `verified`, 1
`fixed`, **0 `open`**), então o regime que esta missão conserta **não é reproduzível pelo registry
real**. Os testes o constroem em fixture. Não "arrume" um bug aberto para testar à mão.

⚠️ **Se a REVIEW precisar mexer em `agents/*.md`:** o espelho é sincronizado por
`./bin/sdd install --force`, nunca por `cp` e nunca por Edit — o harness trata `.claude/` como
caminho sensível e em sessão headless a ferramenta leva negativa, com a fase parecendo travada.

⚠️ **Ordem que custa 12min quando se erra:** o carimbo de mutação tem como chave o conteúdo de
`bin/ tests/ templates/ config/`. Ele foi tirado **depois** do último commit de código
(`26b74a0`). Commit em `docs/`, `CLAUDE.md`, `CONTEXT.md` ou `TODO.md` **não** o invalida; mexer em
`tests/health-baseline.txt` **invalida** — e é lá que mora a catraca do backlog, então registrar
achado no `TODO.md` **depois** de carimbar mata o carimbo que o `gate_PR` exige. Se a REVIEW
consertar qualquer coisa em `bin/` ou `tests/`, o carimbo tem de ser tirado de novo.

## Pendências / Decisions for a Human

> Só julgamento humano genuíno (política de UX, decisão de produto, pagamento real, acesso
> externo). **Não bloqueiam o pipeline** — viram seção do PR. Bug sanável não entra aqui: vira
> incremento de fix no `checkpoint.md`.

Vazio. Nenhum incremento precisou de decisão de produto, e **nenhuma intervenção humana entrou na
linha** durante a EXEC nem durante a QA — o `checkpoint.md` não tem nenhuma linha `intervention:`.

## Riscos e não-feitos

- **A prosa corrigida do `§ 5`/`§ 5.1` não tem sensor próprio — limite declarado.** É contrato em
  texto, e a régua de admissão do D15 manda declarar em vez de inventar probe. O que tem sensor é o
  **mecanismo** (os 5 regimes do `check-gates.sh` + 3 mutantes) e a **sincronia do espelho** (o
  `sdd preflight`). ⚠️ E o achado 1(a) da QA é exatamente o caso em que a prosa e o código
  discordaram sem nada ficar vermelho: a seção `Language` do agente afirmava que gênero traduzido
  não é lido, e `humano` passava.
- **O corpo da escalada (`handoff_blocked_escalation`) não tem mutante próprio — limite declarado**
  no cabeçalho do catálogo. Ele só é alcançado pelas duas portas, então neutralizá-lo é
  indistinguível de neutralizar as duas de uma vez: evidência estritamente mais fraca que o par de
  mutantes que já existe.
- **O marcador não sobreviver a volta nenhuma é consequência do FLUXO, não da construção.** Com as
  duas portas, toda volta que o encontra armado devolve 3 — mas quem acrescentar uma terceira
  porta, um segundo setter, ou um caminho que possa terminar uma volta com o marcador ainda `1`
  tem de **re-derivar** a propriedade. O comentário do `bin/sdd:508-511` foi reescrito no `26b74a0`
  para dizer isso; antes ele prometia mais do que o código dava.
- **`Closable by:` não chega sozinho a repo-alvo nenhum.** `docs/qa/templates/bug.md` deste repo é
  cópia byte a byte do asset da skill instalada, e a linha do I1 é hoje a **única** diferença entre
  os dois; a skill `qa-report` semeia o template do projeto a partir do **asset dela**, e
  `cmd_install` não distribui árvore `docs/qa/`. Em repo-alvo todo bug nasce **sem** o campo e
  barra — que é o fail-safe pedido, e o `§ 5.1` manda marcar —, mas ninguém documenta semear o
  campo, e **nenhum sensor cobre `docs/qa/templates/`** (`check-templates.sh` lê só `templates/`).
- **O campo `Closable by:` nunca foi exercitado por um agente de verdade.** O `§ 5.1` é dever novo
  desta missão; a QA foi a primeira sessão a lê-lo e não teve bug para marcar.
- **A caixa do gênero não foi decidida, só medida.** `Human` e `HUMAN` barram (o casamento é
  sensível a caixa). É fail-**safe**, então não virou `F<n>`; mas ninguém escreveu em lugar nenhum
  que o gênero é minúsculo, e um agente que escreva `Human` verá o bug barrar sem explicação.
- **Limite declarado no `bin/sdd` (F1):** o `-m1` significa "a primeira linha com forma de campo
  **é** o campo", que é a ordem do próprio template. Arquivo que citasse a linha humana **acima**
  do próprio campo ainda falharia aberto — malformado pelo template, e nenhum probe o prende.
- **Não verificado:** o comportamento sob `sdd retry` (o comando, não o retry inline). `cmd_retry`
  devolve `3` em qualquer reprovação de gate, então um handoff `blocked` já escala por lá — mas ele
  **não escreve linha de escalada no ledger** em caso nenhum, o que é anterior a esta missão e fora
  do escopo dela.
- **Não verificado:** o comportamento novo num repo-alvo de verdade. A missão inteira roda no kit,
  e o efeito medido (12 sessões de QA numa missão) só reaparece na próxima missão de repo-alvo.
- **Desvios registrados no `checkpoint.md`, todos com justificativa medida:** I1 (o valor virou o
  default concreto `agent` em vez de `<agent | human>`), I3 (a saída ficou antes do teste de
  `moved`, não de `moved2` — sem mover o ponto de amostragem, que é o que o plano proíbe), I4 (três
  comentários citando `agents/sdd-qa.md:142` reancorados no mesmo commit) e F2 (uma definição e
  duas portas, em vez da cópia literal que a QA mediu — verde obtido primeiro com a cópia, e só
  então refatorado).
- **Fora de escopo, e continua fora:** a ADR 0005 (`6e82acb`, `Implementation: NOT YET IN THE
  RUNNER`) é a missão seguinte.

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
normal — e nada apareceu que não estivesse **dentro** do escopo: os 2 defeitos da QA moram em
linhas que esta missão escreveu (viraram `F1`/`F2`) e os 6 drifts descrevem o que ela mudou (foram
para a DOCS). O `TODO.md` não foi tocado, o que também protege o carimbo de mutação
(`tests/health-baseline.txt` é a catraca dele).

- **Não é achado (D15), já resolvido no commit que o criou:** três comentários vivos citavam
  `agents/sdd-qa.md:142` — `bin/sdd` (2×) e `tests/check-gates.sh` (1×) — e o `§ 5.1` do I4
  empurrou a regra para a linha 172. Reancorados no **mesmo commit** (`cf43bb3`) e no **heading**
  (`"Rules that are not negotiable"`) em vez do número. Não virou item de backlog porque não é
  fail-open e não tem consumidor fora do kit.

### Drift para a fase DOCS (não é achado fora de escopo — é a documentação desta missão)

Seis itens, três da EXEC e três da QA:

- `docs/qa/README.md:109-113` descreve a Âncora 3 como *"counts files … matching `- **Status:**
  open` and refuses the phase while any exist"*, que o I2 **tornou falso**. O mesmo parágrafo cita
  `bin/sdd:485-491`, e hoje esse trecho é prosa do `gate_TICKET`. Reescrever e re-ancorar juntos.
- `docs/pipeline.md:142` **ficou FALSO**: dá *"no file in `<QA_DOCS_PATH>/bugs/` has `**Status:**
  open`"* como condição do `gate_QA`. `:140` e `:145` são a mesma frase em outras palavras.
- `docs/pipeline.md:538` documenta o `kind` do ledger como enum **fechado** de quatro valores, e o
  I3 escreveu um quinto: `handoff-blocked`. É o caso que o `CLAUDE.md` nomeia — contrato de
  artefato mudado se atualiza junto —, e `docs/pipeline.md` é o **esquema de registro** do ledger.
  Os leitores em tempo de execução estão a salvo (medido); o estrago é no documento.
- `agents/sdd-qa.md:92` ficou impreciso: *"It repeats until the registry is empty"*. Desde o I2 ele
  repete até não sobrar bug **sanável por agente**. ⚠️ Mexer nesse arquivo exige
  `./bin/sdd install --force`.
- `KAIZEN_LOG.md`: a missão tem antes/depois medido (12 sessões de QA / US$ 73,32 numa missão de
  repo-alvo → o que a próxima medir). O K8 do checklist kaizen já o previu.
- `CLAUDE.md`: a lição do **gate insatisfazível** — um gate cuja condição nenhum agente do
  pipeline tem permissão de satisfazer é um gate errado, e o sintoma é a fase girar comprando
  volta com achado legítimo. O K7 já o previu.
