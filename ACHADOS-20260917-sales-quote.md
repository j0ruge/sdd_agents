# Achados sobre o kit — sessão longa no `sales_quote` (2026-09-16/17)

> **O que é isto.** Observações sobre o **kit `sdd`** colhidas ao operar duas missões inteiras no
> `sales_quote` numa só sessão: `20260916-destino-frete-cif` (SQ-129, PR #167 mergeado em
> `3f0fa098`) e `20260916-quatro-silencios-da-tela` (SQ-130, em REVIEW). Nada aqui é sobre o
> `sales_quote` — o que era daquele repo já foi para o `TODO.md` de lá.
>
> ⚠️ **Estado: OITO DOS DEZ FECHADOS.** A frase original aqui dizia *"não mexi no `TODO.md` deste
> repo de propósito"* — era verdade em 2026-09-17 e deixou de ser em 2026-09-18. Os nove itens (mais
> o décimo, nascido no gemba) foram triados pelo humano no grill daquele dia e fechados em **duas**
> missões de kit: **T1** `20260918-a-sessao-morreu-e-o-gate-levou-a-culpa` (PR #46) levou os quatro
> em que o kit **mentia** sobre o que aconteceu — #1, #5, #8, #9; **T2**
> `20260918-a-excecao-do-chapeu-e-o-genero-diferido` levou os que o fazem **parar trabalho certo** ou
> **esconder um dado que existe** — #4, #10, #3, e o #2 **pelo** #3 (ADR 0009, que emenda a 0006).
> Restam **#6, #7 e a observação**, no `TODO.md` deste repo, para a **T3**. A tabela abaixo é o mapa;
> cada item carrega o seu desfecho no corpo.
>
> **Toda evidência é literal.** As transcrições vieram dos logs da própria execução, e os hashes
> são alcançáveis (`git log` do `sales_quote`, branches `develop` e `SQ-130_quatro_silencios_da_tela`).
> Onde não medi, está dito.

---

## Roteamento — onde cada achado foi parar (2026-09-18)

Missão de kit `20260918-a-sessao-morreu-e-o-gate-levou-a-culpa`, branch
`feat/a-sessao-morreu-e-o-gate-levou-a-culpa`, base `main` = `1321beb`. Tema **T1 — o runner não
mente sobre o que aconteceu**: os quatro achados em que o operador pergunta *"o que houve / onde eu
estou"* e o kit responde **errado** ou **caro**.

| # | Achado | Desfecho | Evidência |
|---|---|---|---|
| 1 | Motivo do gate mascara a causa da morte | **RESOLVIDO** — e vira Jidoka: para a linha antes do retry | `70d7785` `d1002b8` `e3c6671` |
| 2 | `gate_QA` conta bug de outra missão | **RESOLVIDO pelo #3** — lacuna no enum, não no escopo da âncora | `81e6f6c` |
| 3 | `Closable by:` é binário | **RESOLVIDO** — `deferred`, terceiro valor, visível por nome | `81e6f6c` |
| 4 | `writes:` não comporta obrigação do alvo | **RESOLVIDO** — `HAT_WRITES_EXTRA`, por chapéu e caminho | `350688a` `a09994a` |
| 5 | Não existe comando barato para ver o estado | **RESOLVIDO** — `sdd status --no-gates`, 0,037 s | `e0c95c8` `ea0923b` |
| 6 | Fase manual não tem como ser registrada | roteado ao `TODO.md` — pede o 6º `event` do ledger | `1fb120b` |
| 7 | Teto não conhece missão reaberta | roteado ao `TODO.md` | `1fb120b` |
| 8 | Background frágil; foreground sobrevive | **RESOLVIDO** — verbete em `docs/failure-modes.md` | `826b6b3` |
| 9 | CLOSE paga sessão que não pode concluir | **RESOLVIDO** — o prompt carrega a autorização | `a8526ad` |
| 10 | As skills de QA não conhecem `Closable by:` | **RESOLVIDO** — o `sdd install --force` semeia o campo no template | `f7bcf10` |
| obs | `Test Coverage = A` não implica caso negativo | roteado ao `TODO.md` | `1fb120b` |

**Verificação da missão que fechou os quatro:** `tests/run-all.sh` verde (1163 asserções);
`sdd health --with-mutation` = **`331 caught, 0 known gap(s), of 331`** (catálogo 326 → 331, cinco
mutantes novos, nenhum sobrevivente) com o carimbo escrito; `sdd preflight ok`. Antes/depois medido
em `KAIZEN_LOG.md`, entrada de 2026-09-18.

⚠️ **Um mutante foi deliberadamente NÃO registrado**, e está dito no catálogo: o
`SESSION_DIED_WHY=""` na entrada do `run_phase`. Removê-lo foi medido numa cópia e a suíte inteira
ficou verde — o setter roda em toda sessão real e as portas só são alcançáveis depois de uma. A
linha fica (ela decide *qual* falha uma porta futura produz) com a ausência de probe declarada na
própria linha. Registrar um mutante que nada pega seria um sobrevivente permanente no score.

---

## Itens para o `## Aberto`

### 1. O motivo do gate mascara a causa da morte da sessão

- [ ] **A mensagem de bloqueio culpa o gate quando a sessão morreu por outra coisa** — `bin/sdd`
  (caminho `claude exited 1` → `gate_*` → `BLOCKED`) — duas sessões de QA morreram por token
  expirado e o terminal acusou os 5 bugs abertos do registry; quem lê vai consertar o que não era o
  problema. Direção: quando o `.json` da sessão traz `is_error` com causa, **ela vence** o motivo do
  gate na mensagem — hoje ela só aparece atrás de um caminho de arquivo.
  — descoberto por `sessão coordenadora` na missão `20260916-destino-frete-cif` (2026-09-16)
  RESOLVIDO por `70d7785` + `d1002b8` + `e3c6671`: `run_phase` lê a causa do mesmo `result`
  destilado de onde já tirava custo e turnos, publica `LAST_PHASE_DIED`, e a imprime **antes** do
  ponteiro para os arquivos. A causa não só vence a mensagem — ela **para a linha**:
  `session_died_escalation` é a quinta Jidoka e a única cujo marcador é armado pelo `run_phase` e
  não por um gate, então dispara antes de qualquer gate opinar e **acima do retry**, que era o
  gasto que piorava o diagnóstico. A regra é escrita positivamente (`is_error == true` **e**
  `result` string não-vazia) porque os três regimes medidos aqui exigem isso: um `subtype` de erro
  erraria esta morte (`subtype: "success"`) e dispararia no teto de orçamento. Contrato em
  `docs/pipeline.md` (`kind` + `session_error`), decisão **D25** no `CONTEXT.md`, verbete em
  `docs/failure-modes.md`. Duas portas, um probe e um mutante cada.

**O que o operador viu** (log da execução, 6 linhas seguidas):

```text
▸ phase QA:close — sdd-qa (opus) — session 35d43e05-e692-4010-b635-20328f69be56
  warn  claude exited 1 in phase QA (see …/QA-20260916-165635-35d43e05.json and …err)
  warn  gate QA failed and the session changed nothing: 5 bug(s) with Status: open in the
        registry that an agent could close (an unmarked genre counts) — they become fix
        increments (QA⇄EXEC loop); …
  warn    retrying once with the gate reason in the prompt
▸ phase QA:close — sdd-qa (opus) — session 35d43e05-e692-4010-b635-20328f69be56
  warn  claude exited 1 in phase QA (see …/QA-20260916-170549-8c9f7027.json and …err)

  fail  BLOCKED in QA — two sessions without moving the disk: 5 bug(s) with Status: open …
```

**O que estava de fato acontecendo** (o `.json` que a linha 2 cita, aberto à mão):

```json
{ "is_error": true,
  "result": "Failed to authenticate: OAuth session expired and could not be refreshed",
  "num_turns": 35, "total_cost_usd": 4.5636, "duration_ms": 552423 }
```

Três detalhes que fazem o caso:

- **O `.err` está vazio** (0 bytes nas duas sessões). A causa só existe dentro do `.json`, num campo
  que ninguém abre sem suspeitar antes.
- **O retry piorou o diagnóstico**: a 2ª sessão morreu em **1 turno / US$ 0** — indistinguível, na
  tela, de "o agente tentou e não conseguiu mexer no disco".
- **A primeira queimou US$ 4,56 em 35 turnos** antes de morrer, ou seja, trabalhou bastante e perdeu
  tudo. O "the session changed nothing" é verdade e mentira ao mesmo tempo.

---

### 2. `gate_QA` cobra bugs `open` de outras missões

  RESOLVIDO por `81e6f6c`, **pelo #3 e sem reabrir a ADR 0006**: o caso real desta sessão nunca foi
  "bug de outra missão" — era "bug agent-closable que esta missão decidiu não pagar", que é lacuna
  no **enum** e não no escopo da âncora. O escopo da Âncora 3 não muda e a alternativa (A) da 0006
  segue recusada pelo argumento dela.

- [ ] **A missão herda a dívida inteira do registry como condição de bloqueio** — `bin/sdd`
  (Âncora 3 do `gate_QA`) — quanto mais honesta a QA de ontem, mais cara a missão de hoje.
  Direção: contar só bugs cuja procedência é a missão corrente, ou um `since:` explícito.
  — descoberto por `sessão coordenadora` na missão `20260916-destino-frete-cif` (2026-09-16)
  **ROTEADO para o `TODO.md` deste repo** (não implementado). ⚠️ A direção proposta acima — contar
  só a procedência da missão corrente — foi **recusada com argumento** na
  [ADR 0006](docs/adr/0006-qa-anchor-reads-genre-blocked-handoff-stops-the-line.md)/D17. O item
  registra isso por escrito: quem o pegar **reabre uma ADR**, não implementa um item.

**Exemplo real.** Os cinco que travaram a QA da SQ-129, todos de **2026-09-14**:

| Bug | Severidade | Origem |
| --- | --- | --- |
| `apos-o-422-a-tela-segue-oferecendo-o-que-nao-existe-mais` | Medium/P2 | QA da SQ-125 |
| `dialogo-nao-e-modal-para-leitor-de-tela-nem-devolve-o-foco` | Medium/P2 | QA da SQ-125 |
| `pill-enviada-nunca-tem-resultado` | Low/P3 | QA da SQ-125 |
| `toque-fora-descarta-a-data-digitada-sem-avisar` | Low/P3 | QA da SQ-125 |
| `card-de-aprovacao-legado-e-uma-caixa-vazia-sem-estado-vazio` | Low/P3 | QA da SQ-126 |

Prova de que **precedem** a missão: os cinco já estavam `open` no merge da SQ-128 —

```bash
git show fe25777c:docs/qa/bugs/BUG-20260914-pill-enviada-nunca-tem-resultado.md | sed -n 3p
# - **Status:** open <!-- open | fixed | verified | wont-fix | invalid -->
```

A SQ-129 tratava de destino de frete CIF; nenhum dos cinco está no raio do diff dela. O custo foi
uma sessão de QA inteira + a decisão humana de marcá-los, e a nota do próprio `agents/sdd-qa.md:108`
já registra que essa classe custou **US$ 73,32 de uma missão de US$ 144,88** antes de o campo
`Closable by:` existir. O campo aliviou o sintoma; a contagem cruzada continua.

---

### 3. `Closable by: human` é binário — falta "decidido, aguardando quem pague"

  RESOLVIDO por `81e6f6c`: `Closable by: deferred`, terceiro valor no MESMO campo e mesmo extrator.
  Não bloqueia como `human` e, ao contrário dele, o motivo do gate **nomeia** cada bug diferido em
  toda avaliação — a visibilidade que responde à objeção da ADR 0006 (*"envelhece fora de vista"*).
  ADR 0009 emenda a 0006; `agents/sdd-qa.md` § 5.1 exige a decisão gravada no corpo do bug.

- [ ] **Não há estado entre "trava a fase" e "nenhuma missão o pega"** — `agents/sdd-qa.md:118-136`
  — com a decisão humana já tomada e gravada, o bug continua invisível ao laço para sempre.
  Direção: um terceiro valor, ou um `decided-by: <data>` que o gate leia junto do gênero.
  — descoberto por `sessão coordenadora` na missão `20260916-destino-frete-cif` (2026-09-16)
  **ROTEADO para o `TODO.md` deste repo** (não implementado). Mesma família do #2, mesma ADR.
  ⚠️ Ver também o achado #10 abaixo, nascido no gemba desta missão: ele muda o custo estimado de
  qualquer missão que ataque o #2 e o #3 juntos.

**A sequência real, e o beco.** O humano decidiu os quatro bugs na mesma sessão
(commit `383df146`, seção `## Decisão (2026-09-16, dono do repositório)` no corpo de cada arquivo):

| Bug | Decisão gravada |
| --- | --- |
| diálogo não-modal | corrigir no primitivo; foco vai para o cabeçalho da cotação nos três caminhos |
| após o 422 | opções 1+2 juntas: invalidar o cache **e** manter o motivo no diálogo |
| card legado | frase de estado vazio cobrindo as duas lacunas |
| toque fora | confirmar só quando há conteúdo, **no diálogo** e não no primitivo |

Com a decisão tomada, o gênero certo passaria a ser `agent`. Mas trocá-lo **naquele momento** faria
os quatro voltarem a travar o `gate_QA` da SQ-129, que ainda estava em voo — exatamente o que a
decisão de escopo tinha acabado de evitar. Tive de inventar convenção e escrevê-la no rodapé de cada
arquivo:

> *"Gênero: segue `human` **até a missão que o paga ser aberta**. A pergunta técnica está respondida
> acima; o que resta é de escopo — qual missão paga. Ao abrir essa missão, troque para `agent`."*

Ou seja: **o dado certo (a decisão) fica guardado num campo que o gate não lê**, e a troca vira um
passo manual que alguém tem de lembrar. Na SQ-130 esse passo virou o incremento `I6`.

---

### 4. O hat guard barra trabalho que as regras do repo-alvo exigem

  RESOLVIDO por `350688a` + `a09994a`: `HAT_WRITES_EXTRA`, uma chave, por chapéu e por caminho,
  somada em `hat_writes` só para o chapéu que a nomeia, com guarda literal no molde do `adr_dir_ok`
  validada no `load_config`, e a recusa passa a carregar uma linha `HAT-REMEDY` que nomeia a chave.
  ADR 0009. ⚠️ O remendo literal do `PRODUCT.md` (`796e334`) **não** foi desfeito aqui — desfazê-lo
  é decisão de quem opera aquele repo, e a chave é o que torna a decisão possível.

- [ ] **`writes:` do chapéu não comporta obrigação do projeto** — `agents/sdd-qa.md:11` — ao
  acrescentar um spec e2e, a regra do `sales_quote` **obriga** a rever o piso de casos no workflow
  de CI, que está fora da faixa do chapéu. Direção: chave por projeto no `.sdd/config.sh` que some
  ao `writes:` de um chapéu nomeado.
  — descoberto por `sessão coordenadora` na missão `20260916-destino-frete-cif` (2026-09-16)
  **ROTEADO para o `TODO.md` deste repo, FUNDIDO com o irmão vivo** sobre `writes:`
  (`agents/sdd-docs.md:9`, o drift de comentário de código) — junto, não duplicado, porque as duas
  instâncias pedem a mesma direção: uma chave por projeto no `.sdd/config.sh` que some ao `writes:`
  de um chapéu nomeado.

**O bloqueio, literal:**

```text
  warn  the QA:close session (sdd-qa) touched 1 path(s) outside its writes:
        .github/workflows/e2e-staging.yml
  fail  BLOCKED in QA — the QA:close session (sdd-qa) touched 1 path(s) outside its writes: …
```

**A mudança que o causou** — uma linha, e ela está **certa**:

```diff
-            node scripts/e2e-piso-de-casos.mjs e2e-report.json 108
+            node scripts/e2e-piso-de-casos.mjs e2e-report.json 109
```

**Por que está certa**, nas palavras da regra do próprio repo-alvo
(`.claude/rules/e2e-playwright.md`):

> *"Ao acrescentar spec, **releia o `--list` e reveja a conta do piso**: um total defasado afrouxa o
> gate em silêncio, que é o oposto do que ele existe para fazer."*

O chapéu declara `$E2E_DIR/**` (onde o spec nasce) mas não o workflow que **mede** aquele diretório
— e é impossível cumprir a regra sem cruzar a fronteira. O guard não está errado em avisar; falta
ao alvo poder declarar a exceção. Custo real: uma sessão de QA de **759 s / US$ 11,32** terminou em
`BLOCKED` com o trabalho correto feito.

**Segunda ocorrência — outro chapéu, outra missão** (`agents/sdd-docs.md:9`, 2026-09-17):

```text
  warn  the DOCS session (sdd-docs) touched 1 path(s) outside its writes: .claude/napkin.md
  fail  BLOCKED in DOCS — the DOCS session (sdd-docs) touched 1 path(s) outside its writes:
        .claude/napkin.md
```

**A mudança que o causou** — 18 linhas acrescentadas a `.claude/napkin.md`, e elas estão
**certas**: descrevem o gotcha que custou o diagnóstico da fase QA *desta mesma missão*
(`npm run dev:backend` carrega o `.env`, que **vence** o `.env.local`; `/health/ready` responde
`"jwks":"ok"` e toda rota autenticada responde `401` — medido, 91 de 122 casos e2e vermelhos).

**Por que está certa**, nas palavras do repo-alvo (`CLAUDE.md`, seção `## Gotchas`):

> *"Runbook de gotchas recorrentes (build/run, CI/CD, migrations, seeds):
> [`.claude/napkin.md`](.claude/napkin.md)."*

O chapéu do `sdd-docs` autoriza `CLAUDE.md` e `.claude/rules/**` — as outras duas peças da mesma
família de documentação viva — e não o napkin, que é exatamente onde a regra do projeto manda pôr
gotcha recorrente. Mesma forma do caso do `sdd-qa` acima: o guard não está errado em avisar, falta
ao alvo poder **declarar a exceção**.

Duas diferenças que calibram a direção:

- **Aqui o custo não foi a sessão perdida.** O `gate_DOCS` é baseado em arquivo (`45-docs.md`
  existe, checklist sem `✗`), então o trabalho ficou commitado (`45f98e69` + `5c7ef60b`) e o
  `sdd run` seguinte vai direto ao PR sem refazer nada. O que se pagou foi a **parada**: 916 s /
  US$ 6,24 de fase concluída, e um humano chamado para decidir sobre 18 linhas corretas.
- **O caminho é de curadoria, não só de escrita.** A skill `napkin` manda **curar** a cada sessão,
  com teto por categoria — há argumento legítimo para não abrir esse caminho a um agente que só
  acrescenta. Se a chave por projeto nascer, ela precisa ser declarável **por caminho** e não por
  diretório: `.claude/rules/**` e `.claude/napkin.md` são decisões diferentes.

**Como foi resolvido nesta missão** (para não parecer que o item já tem conserto): o humano optou
por **manter o conteúdo e não alargar o chapéu** — as 18 linhas ficam, adotadas por revisão humana,
e o kit não foi tocado. A próxima missão que escrever no napkin bloqueia igual.

— medido por `sessão coordenadora` na missão `20260916-quatro-silencios-da-tela` (2026-09-17)

**Terceira ocorrência — mesmo chapéu do caso anterior, e desta vez o chapéu FOI alargado**
(`agents/sdd-docs.md:9`, 2026-09-18, missão `20260917-papeis-consultor-admin` do `sales_quote`):

```text
  warn  the DOCS session (sdd-docs) touched 1 path(s) outside its writes: PRODUCT.md
  fail  BLOCKED in DOCS — the DOCS session (sdd-docs) touched 1 path(s) outside its writes:
        PRODUCT.md
```

**A mudança que o causou** — 30 linhas em `PRODUCT.md`, e elas estão **certas**: a missão tornou
falsas quatro afirmações de produto, e a pior delas dizia que aprovar uma cotação é *"a única ação
exclusiva do sistema"* do administrador, num arquivo cuja primeira metade a própria fase EXEC já
tinha corrigido no incremento de documentação. A fase DOCS achou o resto.

**Por que está certa**: no repo-alvo, `PRODUCT.md` é irmã de `CONTEXT.md` e de `DESIGN.md` como
verdade viva — `.claude/rules/frontend-react.md` a declara *"verdade de **produto** (quem usa,
cenário, restrições duráveis)"*. O chapéu autorizava `CONTEXT.md` e não a irmã ao lado.

**A decisão divergiu da ocorrência anterior, a pedido do humano**: em vez de manter o conteúdo e
deixar o chapéu como estava, `PRODUCT.md` entrou na lista literal do `writes:`, ao lado de
`CONTEXT.md`. Duas consequências que valem estar escritas:

- **Alarga para todo projeto que usa o kit**, não só para o `sales_quote` — é o remendo literal, não
  a chave por projeto que este item propõe. O risco é baixo porque um caminho que não existe no alvo
  não é escrito; o custo é que a lista literal cresce um nome por projeto, que é exatamente o que a
  direção deste item existe para evitar.
- **`DESIGN.md` fica de fora e é da mesma família.** Não entrou porque não foi pedido e nenhuma
  missão o mediu ainda; a próxima que tocar design bloqueia igual.

O item **continua aberto**: três ocorrências, dois chapéus, e as duas primeiras seguem sem conserto.
A direção não muda — chave por projeto no `.sdd/config.sh`, declarável **por caminho**.

— medido por `sessão coordenadora` na missão `20260917-papeis-consultor-admin` (2026-09-18)

---

### 5. Não existe comando barato para ver o estado

- [ ] **`sdd status` e `sdd why` rodam os gates** — `bin/sdd` — responder "em que fase estou?" custa
  minutos porque executa `TEST_CMD` (e a suíte e2e, no `gate_QA`). Direção: `sdd status --no-gates`,
  ou fazer disso o default com `--verify` para o comportamento atual.
  — descoberto por `sessão coordenadora` na missão `20260916-quatro-silencios-da-tela` (2026-09-17)
  RESOLVIDO por `e0c95c8` (+ `ea0923b`): `sdd status <missão> --no-gates`, flag **aditiva**.
  Responde artefatos em disco, incrementos (pelo `checkpoint_rows`, o leitor único) e o fim do
  journal, diz em letras que **nenhum gate foi avaliado** e nunca imprime `next phase`. Medido
  neste repo: **0,037 s** contra os 120 s da tabela acima. As duas formas recusadas no grill estão
  no comentário do comando: derivar a fase pelos artefatos criaria uma **segunda** derivação do
  enum mais lido do kit, e inverter o default faria a resposta barata ser lida como veredito.
  ⚠️ A asserção conta **invocações de `TEST_CMD`**, não segundos: no fixture `TEST_CMD="true"` e
  `E2E_CMD` é vazio, então um limiar de tempo passaria com a flag não fazendo nada.

**Medido nesta sessão:**

| Pergunta | Caminho | Tempo |
| --- | --- | --- |
| "em que fase estou?" | `sdd status <missão>` | **estourou 120 s** (duas vezes) |
| "o gate PLAN passa?" | `sdd why <missão> PLAN` | 0,3 s (não roda gate) |
| "o gate QA passa?" | `sdd why <missão> QA` | **estourou 120 s** — roda a e2e |
| a mesma resposta do `status` | `awk -F'\|' '/^\| [IF][0-9]+ \|/…' checkpoint.md` | **0,00 s** |

Referência do custo embutido, cronometrada no alvo: `npm test` = **30,86 s**, e o `TEST_CMD` do
`sales_quote` é `npm test && npm run lint && npm run build`. Na prática passei a ler o
`checkpoint.md` com `awk` e a só chamar `sdd status` quando precisava do veredito de gate.

---

### 6. Fase executada à mão não tem como ser registrada

- [ ] **O ledger afirma que a fase não aconteceu** — `agents/sdd-publisher.md` + journal — a fase PR
  foi feita à mão depois de três mortes por memória; não há sessão de publisher no ledger e o custo
  não entra na soma. Direção: um `sdd note-manual <fase>`, irmão do `intervention:`.
  — descoberto por `sessão coordenadora` na missão `20260916-destino-frete-cif` (2026-09-16)
  **ROTEADO para o `TODO.md` deste repo** (não implementado). ⚠️ O mais caro dos nove: pede o
  **sexto** `event` do ledger, um contrato fechado com dois leitores a ensinar no mesmo commit.

**Como chegou nisso**: a 3ª tentativa **pushou a branch** e morreu antes do `gh pr create` — estado
meio-feito que só se descobre olhando o `git rev-parse --abbrev-ref --symbolic-full-name '@{u}'`.
O PR (#167) foi montado a partir dos mesmos handoffs que o publisher usaria, que é o insumo que a
nota do config descreve ao justificar `MODEL_PUBLISH="sonnet"` (*"montar PR a partir de handoffs
prontos é mecânico"*).

O buraco: **US$ 161,29** é o total que o journal conhece, e ele para na fase DOCS. Registrei a
lacuna à mão no `50-pr.md` —

```yaml
sessao: manual — a fase PR do runner foi morta por falta de memória do sistema três vezes
gate: "PR #167 aberto contra develop; branch pushada (48 commits, 205 arquivos, +30246/-400)"
```

— mas isso é prosa num arquivo, não um fato que o `sdd ledger` ou o `sdd kaizen` consigam ler.

---

### 7. O teto de orçamento não conhece "missão reaberta"

- [ ] **Conserto pós-review paga o preço do estouro que a entrega causou** — `bin/sdd`
  (`BUDGET_MISSION_USD`) — o teto pune justamente o ciclo que deveria ser incentivado: revisar
  depois do PR e voltar para consertar. Direção: distinguir gasto de entrega de gasto de conserto
  pós-review, ou estender o teto ao reabrir.
  — descoberto por `sessão coordenadora` na missão `20260916-destino-frete-cif` (2026-09-16)
  **ROTEADO para o `TODO.md` deste repo** (não implementado). Tema próprio: pede desenho sobre o
  que conta como "gasto de conserto" contra "gasto de entrega".

**A sequência real.** A missão fechou o PR com **US$ 161,29 de 150**, já sob override — três linhas
versionadas, que é o mecanismo funcionando:

```text
caad731c chore(checkpoint): intervention — sdd run --budget-override (US$ 153.47 …) — DOCS
cf827803 chore(checkpoint): intervention — sdd run --budget-override (US$ 161.29 …) — PR
b4ac3a7a chore(checkpoint): intervention — sdd run --budget-override (US$ 161.29 …) — EXEC
```

A terceira é a que interessa: ela é **posterior ao PR**. O `@codex review` achou um P1 real
(detalhado no fim deste documento), a missão reabriu com um incremento `R5`, e a fase EXEC do
conserto teve de ser autorizada com o mesmo override — com o número já estourado por causa da
entrega, não do conserto. O conserto custou US$ 9,03 e valeu cada centavo: sem ele, o PR levaria
para produção um caminho que grava endereço contraditório na nota fiscal.

---

### 8. Background é frágil; `--max-phases 1` em primeiro plano é o modo que sobrevive

- [ ] **Execução em background morre por pressão de memória; foreground não** — `docs/` (operação)
  — três `sdd run` mortos nesta estação, nenhum por culpa do kit, mas o tempo perdido superou o que
  as fases custariam. Direção: documentar como modo recomendado em estação apertada.
  — descoberto por `sessão coordenadora` na missão `20260916-quatro-silencios-da-tela` (2026-09-17)
  RESOLVIDO por `826b6b3`: verbete `## The \`sdd run\` process itself disappeared` em
  `docs/failure-modes.md`, com o sintoma (`ps -eo pid,etime,cmd | grep 'bin/sdd run'` vazio), o que
  fazer (primeiro plano, ou `setsid nohup` com o ambiente do harness limpo — nunca tarefa de fundo
  de uma sessão de agente) e o mérito deste item: as três mortes não corromperam nada **por
  desenho**, princípios 3 (estado em disco) e 4 (fase derivada). Não há arquivo de estado para
  ficar mentindo sobre um disco que andou, então qualquer morte do runner é recuperável rodando o
  mesmo comando.

**As três mortes, e o que cada uma custou:**

| # | Fase | Estado ao morrer |
| --- | --- | --- |
| 1 | EXEC/QA | 17 incrementos feitos, r2 da review escrita — **nada perdido**, árvore limpa |
| 2 | QA (arranque) | log com uma linha; HEAD intacto — **nada perdido** |
| 3 | PR | **branch pushada**, PR não criado → fase refeita à mão (item 6) |

A causa foi um processo alheio à missão (`qmd vsearch`, 6,5 GB) com o swap já saturado; o kit não
tem culpa. O que **é** do kit é a lição operacional: depois que passei a rodar
`sdd run <missão> --max-phases 1` em **primeiro plano**, nenhuma fase morreu — foram assim as fases
finais da SQ-129 (REVIEW r3, DOCS) e as nove da SQ-130.

Mérito que vale registrar no mesmo item: **nenhuma das três mortes corrompeu estado.** Nos três
casos a árvore ficou limpa e o `sdd run` seguinte retomou do ponto certo — é desenho, não sorte.

### 9. A fase CLOSE paga uma sessão para uma skill que exige humano

- [ ] **`sdd close` gasta uma sessão que, por construção, não pode concluir** — `bin/sdd`
  (`cmd_close` → `claude -p "/ticket close $issue"`) — a skill `ticket` manda *"Apresentar
  rascunho ao dev — pedir confirmação"* e repete na seção de regras (*"Mostre o resumo ao dev
  antes de postar"*). Numa sessão headless não há dev: ela redige o resumo, pergunta, e termina
  `success` sem ter escrito nada no JIRA. Direção: dizer no prompt do CLOSE que a autorização
  humana **é** o próprio `sdd close` — ou reconhecer esse desfecho e repetir uma vez com o motivo
  do gate, como `run_phase` já faz.
  — medido por `sessão coordenadora` na missão `20260916-quatro-silencios-da-tela` (2026-09-17)
  RESOLVIDO por `a8526ad`, pelo primeiro caminho da direção (o prompt), que é o que ataca a causa:
  repetir a sessão repete a pergunta, porque a regra está escrita duas vezes na `SKILL.md`. O
  prompt do CLOSE passa a dizer que a autorização humana **é** o próprio `sdd close`, que não há
  dev nesta sessão para confirmar, e que é para postar e transicionar sem perguntar.
  ⚠️ O risco que isto carregava — prosa **depois** de um slash command podendo ser descartada na
  expansão — foi **medido**, não declarado: um `claude -p` real com `/ticket close ZZZ-0` na
  primeira linha e uma instrução quatro linhas abaixo obedeceu a instrução (US$ 0,0475, haiku, um
  turno). A prosa chega, e o fallback `--append-system-prompt` não é preciso. Mutante
  `RUN_close_prompt_bare`; a asserção lê o argv do stub, que é o lado do runner na fronteira.

**O que o operador viu:**

```text
▸ closing SQ-130
  fail  SQ-130 is still open — JIRA does not confirm the close (the session may have only
        asked for confirmation); see …/CLOSE-20260917-122147-4b1a2a92.json
```

**O `.json` que a linha cita** — e aqui, ao contrário do item #1, **o gate acertou**: a hipótese
que ele levanta entre parênteses é exatamente o que houve.

```json
{ "is_error": false, "subtype": "success", "num_turns": 8,
  "duration_ms": 42678, "total_cost_usd": 0.8563728 }
```

A última linha do `result` é, literalmente, uma pergunta a um humano que não está lá:

> *"Posso postar esse resumo como comentário no Jira e seguir com a transição? E confirme se o
> fixVersion 0.8.1 está correto…"*

Três detalhes que fazem o caso:

- **É estrutural, não sorte de sessão.** A regra está escrita **duas vezes** na `SKILL.md` do
  `ticket` (o passo 4 do fluxo e a seção `### Regras`). Uma sessão que a cumpre **tem** de parar,
  então repetir o comando repete a pergunta — não é um caso de retry cego.
- **`cmd_close` não tem retry.** `run_phase` repete uma vez com o motivo do gate no prompt; aqui a
  única saída é humana, e o operador só descobre isso abrindo o `.json`.
- **O kit já cuida do vizinho deste problema.** O pre-check `close_query` evita abrir sessão quando
  a issue já está `Done` (*"and no session was spent"*) — o gasto que sobra é justamente este, e
  pela razão oposta: a sessão abre, roda inteira, e não pode terminar.

**Custo:** US$ 0,86 e 43 s por invocação, mais o fechamento à mão depois. Resolvido nesta sessão
pelo caminho manual (comentário via MCP `addCommentToJiraIssue` + transição `id 31` + releitura
REST); o `sdd close` seguinte respondeu `already Done — no session was spent`, e o journal ficou
com as duas linhas — `verified=false` na primeira, `verified=true session=none` na segunda.

⚠️ **Não é o item #4** (fronteira de escrita do chapéu) nem o #1 (motivo do gate mascarando a causa
da morte): aqui a sessão não morreu, não cruzou fronteira nenhuma, e a mensagem do gate nomeou a
causa certa. O que falta é a fase headless poder exercer uma autorização que o humano já deu ao
digitar o comando.


---

### 10. Nenhuma das skills de QA conhece o campo `Closable by:`

  RESOLVIDO por `f7bcf10`: o `sdd install --force` semeia a linha em `$QA_DOCS_PATH/templates/bug.md`
  (o `sdd install` sem a flag só RELATA o campo faltando, sem tocar no arquivo),
  imediatamente abaixo do `Status:`, idempotente e recusando um template fora da forma da skill; o
  `sdd preflight` fica vermelho com o remédio enquanto faltar. As skills seguem sem conhecer o
  campo — o kit o põe no template de que elas copiam, que é o ponto de extensão que existe.

> **Achado NOVO**, não estava na lista de 2026-09-17. Nasceu no gemba do planejamento de
> 2026-09-18, ao medir o custo real de atacar os itens #2 e #3.

- [ ] **`Closable by:` não existe nas skills que escrevem o registry** — `agents/sdd-qa.md:118` —
  `grep -rn Closable ~/.claude/skills/qa-*` responde **zero**, então o campo só chega ao disco pelo
  template local do repo ou pelo `sdd-qa` marcando arquivo por arquivo. Em repo-alvo novo a Âncora 3
  inteira roda em regime "ausente ⇒ bloqueia". Direção: ensinar o campo às skills, ou o `sdd-qa`
  assumir a marcação como passo declarado.
  — descoberto por `sessão coordenadora` na missão `20260918-a-sessao-morreu-e-o-gate-levou-a-culpa` (2026-09-18)
  **ROTEADO para o `TODO.md` deste repo** (não implementado).

**Por que importa antes de qualquer decisão sobre #2 e #3.** Os dois itens acima tratam o campo
`Closable by:` como um dado que existe e cujo **domínio** precisa crescer (#3) ou cuja **leitura**
precisa encolher (#2). Este achado diz que, fora deste repo, o campo **não é escrito por ninguém
automaticamente** — o que muda a conta: uma missão que ataque #2/#3 num alvo novo paga primeiro o
custo de fazer o campo existir. Precisa estar escrito **antes** de essa missão ser planejada, que é
exatamente por que ele entra aqui e não só no backlog.

⚠️ Medido no dia, com o comando acima, contra `~/.claude/skills/qa-report` e
`~/.claude/skills/qa-execution` — as duas presentes na estação. Não foi medido contra versões
futuras das skills: é uma fotografia, e o comando que a tira está na linha do achado.

---

## O que funcionou bem (não vira item; é para não regredir)

**O `sdd-planner` no gemba refutou premissas por medição, duas vezes, e as duas mudaram o plano.**

1. O registro de QA afirmava, sobre o pill `Enviada`: *"não é um zero de base vazia: é estrutural…
   inalcançável **por construção**"*, e recomendava **remover o pill**. O planner foi medir:

   ```text
   listaCotacoesConstants.ts:92 → enviada = { status: ["ENVIADA"], recente: true }
   cotacoes.ts:173              → recente ⇒ enviada_em > agora − 3 dias (PENDENTE_DIAS)
   banco de dev: ENVIADA total 323 · dentro de 3 dias 29 · fora 294
   ```

   O pill funciona e quer dizer *"enviadas nos últimos 3 dias"*; o zero de 14/set era base sem envio
   recente. Seguir a recomendação teria **apagado um filtro vivo** por causa de uma premissa falsa.

2. Sem ninguém pedir, achou um vizinho não registrado: **9 de 26** cotações `SUBSTITUIDA` sem
   `dados_faturamento` exibem *"Aguardando aprovação."* — numa cotação que nunca será aprovada. É o
   caso com **mais ocorrências** dos três daquela família, e não estava em relatório nenhum.

**`REVIEW_PROSE_CRITERIA` + `REVIEW_MAX_ITER` fizeram exatamente o que a nota do config promete.**
A SQ-129 fechou na r3 com `A` em tudo que exige `A` e `Documentation = B` tolerado. Sem a chave, a
rodada teria sido comprada por prosa — que é o caso que a própria nota cita
(`20260902-o-rascunho-legado-fala-cru`: quatro rodadas, zero achado funcional).

**As linhas `intervention:`** deixaram todo override versionado e legível (os três hashes do item 7).

---

## Uma observação que não é do kit, mas contamina a leitura dele

O `@codex review` achou no PR #167 um **P1 real** que passou por **três rodadas de `sdd-reviewer`**
— a última com `Test Coverage = A` — e por **quatro checks de CI verdes**.

**O defeito.** O efeito que reporta ao pai fazia:

```ts
if (tipoFrete === "CIF") { onLogistica(ramoCif(endereco)); return; }
```

`ramoCif` valida presença, `isUf` e forma do CEP — **não consulta a divergência**. Com o endereço
completo e a pergunta da tela sem resposta, o Confirmar habilitava: dava para gravar
`Rua da Quitanda, Centro` dentro de `Vila Bela da Santíssima Trindade (MT)` — exatamente o dado
contraditório que o incremento anterior existia para impedir.

**Por que ninguém viu**: o caso que faltava era o **negativo** — *"com divergência pendente, o
Confirmar não habilita"*. Nenhum sensor era obrigado a cair.

Não é falha do kit: o `01-plano.md` daquela missão prescrevia sabotagem por incremento, e ela foi
feita. Mas é evidência de que **`Test Coverage = A` do reviewer não implica que os casos negativos
existam**. Se virar item, a direção seria o reviewer ter de **enumerar qual sabotagem provou cada
nota** — hoje ele narra em prosa, e prosa não é verificável. O conserto (`22521387`) acrescentou
115 linhas de teste, e o caso central é uma única asserção que ninguém tinha escrito.

**ROTEADO para o `TODO.md` deste repo** (`1fb120b`), com a direção que este parágrafo já nomeia: o
revisor enumera qual sabotagem provou cada nota, porque hoje ele narra em prosa e prosa não é
verificável. Entrou como achado e não como "observação" por decisão do grill de 2026-09-18 — toca
`agents/sdd-reviewer.md` e o `gate_REVIEW`, então tem dono e tem tema próprio (T5).
