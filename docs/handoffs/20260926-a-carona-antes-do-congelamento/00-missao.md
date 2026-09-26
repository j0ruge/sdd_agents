---
missao: 20260926-a-carona-antes-do-congelamento
titulo: o último PR antes do congelamento fecha as issues #50, #51 e #52, as lacunas 2 e 3 de portabilidade e a faxina pós-#57, carimbando uma vez só
data: 2026-09-26
versao: n/a — JIRA_ENABLED=false
branch: fix/a-carona-antes-do-congelamento
aprovacao:
adr: docs/adr/0012-o-commit-tem-dono.md
ddd: aplicado
---

# Missão — a carona antes do congelamento

> Escrito pelo `sdd-planner` em 2026-09-26. O humano respondeu o grill pela sessão coordenadora,
> que repassou as nove respostas. Este arquivo é a única fonte da **intenção**; o `01-plano.md` é a
> fonte do **como**.
>
> ⚠️ **A execução é INTERATIVA** (Opus + `superpowers:executing-plans`), **nunca `sdd run` no
> kit.** O `claude -p` aninhado herda o socket do harness e morre, e o kit se sabotaria editando o
> `bin/sdd` que o executa.
>
> ⚠️ **Este é o último PR antes do congelamento do kit** (F3 da gaveta). Depois do merge, a `main`
> não deve receber commit até o veredito do juiz: qualquer commit muda o `kit_sha` e encalha a janela
> de 3 missões de alvo. Por isso tudo o que precisa mudar entra **aqui**, os ADRs saem `accepted`
> dentro do PR (precedente: ADR 0009) e nenhum item nasce `RESOLVED by` esperando chore pós-merge.

## Problema (Gemba)

Seis frentes, todas medidas em `3c44df8` (`main`, 2026-09-26). Os números de linha estão no
`01-plano.md`, e andam quando os incrementos editam o `bin/sdd`.

1. **#50 — o `adr_link` lê a grafia idiomática do markdown como lixo.** Reproduzido com a regex do
   runner (`ADR_LINK_PRE`/`ADR_LINK_POST`): `**Spec:** docs/handoffs/x/00-missao.md` captura `**`, e
   `` **Spec**: `docs/handoffs/x/00-missao.md` `` captura o caminho com as crases. A mensagem que sai
   é "points somewhere else … fix whichever side is wrong", quando nenhum lado aponta para nada.
   **Yokoten, mesma classe:** o `gate_REVIEW` tira só `*` da célula da nota, então `` `A` `` reprova
   como `` Correctness = `A` ``; o `gate_DOCS` compara o Status literal com `✅`/`n/a`, então `` `n/a` ``
   ou `**✅**` contam como pendentes. Falham fechados, mas cada vermelho falso compra uma rodada paga.
2. **#51 — o sensor da fronteira culpa o chapéu por commit que não é da sessão.** O
   `hat_guard_check` lê `git diff --name-only <HEAD antes> <HEAD depois>`: todo commit que cai na
   janela da fase é atribuído ao chapéu. No `lighthouse_project` um commit do humano, feito de outra
   sessão durante o TICKET, virou `hat-crossed` com dois remédios errados (restaurar à mão, alargar
   `HAT_WRITES_EXTRA`). A transcrição da sessão não serve para atribuir: o executor commita com
   `git commit -q`, e nenhum dos 8 streams EXEC mais recentes do `sales_quote` traz um SHA de commit.
   O **reflog** serve: com `GIT_REFLOG_ACTION` no ambiente, `commit`, `commit --amend`, `checkout` e
   `reset` gravam o rótulo (git 2.43.0, medido: `sdd-session abc123: session commit` contra
   `commit: human commit`).
3. **#52 — `sdd approve` sem ninguém para responder sai 0.** Com o stdin fechado, `read` falha, a
   resposta vira vazia e o comando imprime "not approved — nothing was written" com rc 0, igual a um
   humano que digitou N. No Bash do harness o stdin é `/dev/null` e `read` sai 1 (medido nesta
   sessão).
4. **Lacuna 2 da F4 — sem Jira, ninguém preenche `branch:`.** O `ensure_mission_branch` trata vazio e
   o placeholder `<…>` como no-op, e com `JIRA_ENABLED=false` (default do `config/starter.conf`) a
   fase TICKET, que escrevia o campo, é pulada. O pipeline commita onde o humano estiver. É a única
   lacuna que corrompe a `main` de um repo novo por omissão.
5. **Lacuna 3 da F4 — o `TEST_CMD` herda o stdin do runner e pode pendurar o gate.** O
   `run_check_cmd` faz `eval "$cmd"` sem redirecionar o stdin e sem timeout. O vitest 3.2.4 liga o
   watch quando o stdin é terminal (`watch: !isCI && process.stdin.isTTY`), e o `test` do `erp_api` é
   `vitest` puro: um `sdd run` lançado de um terminal pendura o gate para sempre, sem rc. O preflight
   roda o `TEST_CMD` pela mesma função.
6. **Faxina (F2 da gaveta).** As ADRs 0010 e 0011 seguem `proposed`, com as missões mergeadas (#57,
   #167). O item `TODO.md:244` ("A economia de `current_phase()` …") está pago pelo probe
   `deriving the phase runs TEST_CMD exactly as often as forcing it` (`3245bfd`, ancestral da
   `main`). O outro item do memo que a gaveta cita já saiu em `f43788f`. As lacunas 4 e 5 da F4 não
   estão no `TODO.md`.

## Métrica

Fatos binários, todos lidos por comando no `01-plano.md` § Verificação end-to-end:

- `**Spec:** <caminho>` e `` **Spec**: `<caminho>` `` passam o `sdd adr check` como a grafia de hoje.
  Um valor que não é caminho reprova dizendo "not a path", e nunca "points somewhere else".
- A nota `` `A` `` passa o `gate_REVIEW` e `` `B` `` continua reprovando. O Status `` `✅` `` ou
  `**n/a**` completa o `gate_DOCS`, e `` `✗` `` continua pendente.
- `sdd approve` com o stdin sem nenhuma linha sai **66**, sem escrever nem commitar. `n` e Enter
  continuam rc 0, e `y` continua aprovando.
- Um commit **sem** o rótulo da sessão, feito durante a fase e fora do `writes:`, para a linha como
  `foreign-commit`, com sha e assunto no journal. O **mesmo** commit com o rótulo é `hat-crossed`.
  Sem reflog, o comportamento é o de hoje.
- Com `JIRA_ENABLED=false`, `branch:` vazio ou placeholder deixa a missão em PLAN, com o remédio no
  motivo. Com o Jira ligado, a mesma missão segue para TICKET.
- O `TEST_CMD` roda com o stdin em `/dev/null`, qualquer que seja o stdin de quem chama.
- As ADRs 0010, 0011 e 0012 estão `accepted`, o `TODO.md:244` saiu, as lacunas 4 e 5 entraram, e a
  catraca é `todo-findings 83`, igual ao `--count`.
- O catálogo de mutação vai de 406 para **419** mutantes (13 novos), e o único `sdd health` do PR
  pega todos.

## Resultado esperado

O kit que congela depois deste PR não culpa um chapéu por commit alheio, não confunde "ninguém
respondeu" com "o humano disse não", não lê a grafia idiomática de um link de ADR nem uma nota entre
crases como outra coisa, não deixa um repo novo sem Jira commitar na `main` por omissão e não
pendura o gate num test runner em watch. As issues #50, #51 e #52 fecham com o PR. A gaveta sai
atualizada, com F2 fechada, F4 e F5 sem pendência de código, F1-P3 esperando o próximo aumento de
paralelismo e a F3 marcando o congelamento a partir do merge.

## Fora de escopo

- **F1-P3, a varredura das probes sensíveis a tempo sob carga.** Fica na F1 da gaveta como
  pré-requisito do próximo aumento de paralelismo, que não acontece com o kit congelado (decisão 6).
- **A guarda de kit com o rótulo.** O `TODO.md:525` ("a linha `kit-touched` afirma uma atribuição
  que o runner nunca mediu") continua aberto (decisão 1).
- **Sujeira NÃO commitada de um escritor concorrente.** A metade `git status` do `hat_guard_check`
  continua atribuindo ao chapéu. O limite é declarado no cabeçalho da função e na ADR 0012.
- **Lacuna 4** (o `sdd install --force` escreve no kit através do symlink) e **lacuna 5** (a prosa dos
  chapéus cita o `sales_quote`): só registradas no `TODO.md`. A **lacuna 6** já é limite declarado na
  ADR 0007.
- **#53** já está fechada, e as pendências D15 do handoff do #170 (`/tmp/sdd-ck-*` e
  `/tmp/sdd-coordination-*`) ficam sem rota, como o handoff decidiu.
- **A T3 e a janela do juiz (F3):** o congelamento começa no merge deste PR; a T3 vem depois.
- Qualquer achado novo durante a execução vai para o `TODO.md`, com a catraca movida no mesmo diff.

## Gate PLAN-AUTO

| # | Critério | Status | Evidência |
|---|---|---|---|
| a | Grill sem perguntas abertas não endereçadas (🚩 vazia ou itens deferidos com dono) | ✅ | As nove perguntas do grill foram respondidas pelo humano (§ Decisões). As interpretações do planejador estão em Pendências e não bloqueiam. |
| b | Checklist kaizen 100% ✅ e checklist DDD 100% ✅ ou `n/a` justificado | ✅ | Tabelas abaixo; o DDD foi acionado por causa do `kind` novo no ledger. |
| c | Plano passa no teste de autocontenção (sessão nova só com 00/01/checkpoint executa) | ✅ | O I1 foi relido só com os três arquivos: funções, linhas, forma dos probes, mutantes, pisos e a receita M estão no `01-plano.md`. |
| d | Todo incremento do `checkpoint.md` tem Check executável (comando → esperado) | ✅ | 7 de 7, em herestring, sem `\|` cru, ancorados em `^  ok    `. `tests/check-checkpoint.sh --check` sobre o arquivo passou. |
| e | `versao:` confirmada pelo humano (ou `JIRA_ENABLED=false`) | ✅ | `JIRA_ENABLED=false`. |
| f | `adr:` é uma decisão — um caminho, ou o literal `none` (alocado por `sdd adr new`) | ✅ | `docs/adr/0012-o-commit-tem-dono.md`, alocada por `sdd adr new`, com a decisão escrita; `sdd adr check --mission … --phase plan` verde. |

> `aprovacao:` fica **vazia** por instrução da sessão coordenadora: quem fecha o gate é o humano,
> com `sdd approve 20260926-a-carona-antes-do-congelamento`.

## Checklist kaizen (`kaizen-software`)

| # | Item | Status | Nota |
|---|---|---|---|
| K1 | Gemba — fui ver onde o trabalho acontece | ✅ | #50 reproduzido com a regex do runner; o rótulo do reflog medido num repo de scratch; o stdin do harness medido; o watch do vitest lido no `node_modules` do `erp_api`; a regra da lacuna 2 prototipada numa cópia do kit, com a quebra dos fixtures contada sensor a sensor. |
| K2 | Problema declarado com métrica | ✅ | Seção Métrica: fatos binários, mais 406 → 419 mutantes e a catraca 82 → 83. |
| K3 | Desperdícios identificados e cortados | ✅ | O F1-P3 sai (o paralelismo que ele destrava não acontece no congelamento). A atribuição pela transcrição é descartada: 0 de 8 streams trazem SHA. A guarda de kit com rótulo fica fora. |
| K4 | Fatiamento incremental, cada fatia verificável | ✅ | 7 incrementos. A atribuição do #51 vem em dois (o rótulo primeiro, depois a leitura), e a regra da lacuna 2 entra junto com os fixtures que ela quebra, para a suíte nunca ficar vermelha entre commits. |
| K5 | Check por artefato (rótulo ≠ artefato) | ✅ | Todo Check lê a asserção do sensor ancorada em `^  ok    `, e o I7 lê a catraca contra o `--count`. Cada mutante novo se prova pela receita M antes do commit. |
| K6 | Jidoka — o que para a linha está definido | ✅ | `tests/run-all.sh` vermelho para; mutante que sobrevive à receita M para; o `--anchors` do catálogo e do `TODO.md` vermelho para. |
| K7 | SDCA — a melhoria vira padrão (doc/rule/teste) | ✅ | Poka-yoke primeiro: a lacuna 2 vira gate, o #52 vira rc, o #51 vira atribuição por artefato. Sensores e mutantes no catálogo; contrato em `docs/pipeline.md`, `config/schema.md`, `templates/missao.md`, nos dois chapéus que planejam, no `CONTEXT.md`, na rule da anatomia e na ADR 0012. |
| K8 | Registro no KAIZEN_LOG | ✅ | O I7 escreve a entrada com o antes/depois de cada fato binário da Métrica. |

## Checklist DDD (`ddd`)

Acionado, e não `n/a`: a missão acrescenta um valor novo ao `kind` do evento `blocked` do ledger,
que é um contrato entre o runner (que escreve) e o juiz (que lê), e introduz um conceito de domínio,
"de quem é este commit".

| # | Item | Status | Nota |
|---|---|---|---|
| D1 | Linguagem ubíqua nomeada | ✅ | **rótulo da sessão** (`sdd:<passo>:<sid8>`, no `GIT_REFLOG_ACTION`), **commit alheio** (entrada do reflog da janela sem o rótulo), **janela da sessão** (as entradas do reflog de HEAD escritas entre o `hat_guard_arm` e o `hat_guard_check`). Os três entram no verbete "Fronteira do chapéu" do `CONTEXT.md` no I4. |
| D2 | Fronteira do contexto | ✅ | O runner atribui, por artefato (o reflog). O ledger guarda o fato (`kind`). O juiz só conta: `group_by(.kind)` dinâmico nos dois leitores, sem lista fechada de kinds. |
| D3 | Invariante do agregado | ✅ | Todo caminho fora do `writes:` visto depois de uma sessão é atribuído a exatamente um dono, a sessão ou o alheio, e **os dois param a linha**: a atribuição escolhe o `kind` e o remédio, nunca se a linha para. Sem reflog que explique o movimento do HEAD, tudo é da sessão, como hoje. |
| D4 | Eventos | ✅ | Nenhum `event` novo. O `blocked` ganha o `kind` `foreign-commit`, na cauda aberta que o `docs/pipeline.md` documenta, e o valor novo entra na tabela no mesmo commit do código. |
| D5 | Contrato entre módulos | ✅ | O `docs/pipeline.md` (lista das rc 3 e a coluna `kind`), o `config/schema.md` (`ON_ESCALATION_CMD`, `SDD_REASON`) e o `CONTEXT.md` mudam no I4, junto com o código. O `hat_crossed_escalation` continua a porta única, agora com três marcadores. |
| D6 | Decisão registrada | ✅ | ADR 0012, alocada por `sdd adr new`, com as três alternativas descartadas. |

## Decisões do grill (não re-litigar)

1. **#51 = atribuição pelo rótulo do reflog.** O `run_phase` exporta
   `GIT_REFLOG_ACTION=sdd:<PASSO>:<sid8>`, e o `cmd_close` também. O `hat_guard_check` lê as entradas
   do reflog de HEAD desde o início da sessão: rotulada é da sessão e é conferida contra o `writes:`;
   sem rótulo é alheia, e a linha **para mesmo assim**, com `kind` próprio (`foreign-commit`), o
   commit nomeado e o remédio certo. Sem reflog, o comportamento é o de hoje. A guarda de kit **não**
   passa para o rótulo, e o `TODO.md:525` fica aberto. Porquê: parar é fail-safe (uma sessão que tira
   o próprio rótulo não escapa), e o juiz deixa de ler um commit humano como fricção do chapéu.
2. **#52 = rc 66 quando não chega resposta nenhuma.** `n` e Enter continuam rc 0, e um `y` enviado
   por pipe continua aprovando. Porquê: é o único caso em que a pergunta nunca foi feita; 66 é o
   `EX_NOINPUT` do sysexits, a mesma família do 75 que o kit já usa para `CHECKOUT-BUSY`.
3. **Lacuna 2 = o `gate_PLAN` recusa `branch:` vazio ou placeholder quando `JIRA_ENABLED` não é
   `true`**, nomeando o remédio. O prompt do planner, o `templates/missao.md`, o `config/schema.md` e
   o `docs/pipeline.md` mudam no mesmo incremento, com probe e mutante. Porquê: é o espelho do
   `versao:` com Jira ligado, e o dono do artefato é o `sdd-planner` com o humano na sala.
4. **Lacunas 3–5:** a 3 é consertada (`</dev/null` no `run_check_cmd`, que é também o caminho do
   preflight), com probe e mutante; a 4 e a 5 são registradas no `TODO.md`. A catraca vai de 82 para
   83.
5. **Yokoten:** tirar a crase (e o `*` no DOCS) antes de comparar, no `gate_REVIEW` e no
   `gate_DOCS`, com probes e mutantes, **no mesmo incremento do #50**.
6. **F1-P3 fica fora** deste PR, na F1 da gaveta, como pré-requisito do próximo aumento de
   paralelismo.
7. **F2:** as ADRs 0010 **e** 0011 vão para `accepted`; sai só o `TODO.md:244`.
8. **ADR sim:** uma nova, alocada com `sdd adr new --slug o-commit-tem-dono`. Decisão: os commits da
   sessão carregam um rótulo no reflog, e um commit sem ele não é do chapéu, mas a linha para mesmo
   assim. Alternativas recusadas: o diff do intervalo, os SHAs da transcrição e o `--trailer`.
9. **Nome `20260926-a-carona-antes-do-congelamento`, branch `fix/a-carona-antes-do-congelamento`.**
10. **Do grill anterior, confirmadas:**
    - execução interativa, nunca `sdd run` no kit;
    - `versao: n/a`;
    - as linhas da gaveta mudam no mesmo PR;
    - o PR leva `Closes #50`, `Closes #51` e `Closes #52`;
    - o espelho de issues é re-sincronizado depois do merge;
    - `sdd health` roda **uma vez**, depois do último commit de código e de todos os revisores;
    - nada congela antes do merge deste PR, e o kit congela depois dele.

## Pendências para o humano

Nenhuma bloqueia o pipeline. São leituras do planejador que o grill não perguntou; se o humano
discordar de alguma, o incremento citado muda antes de rodar.

- **O corpo da ADR 0012 foi escrito já no PLAN.** A resposta 8 dizia "o corpo vai no I3"; a regra do
  planejador diz que um corpo que ninguém escreveu é uma decisão que ninguém tomou. A decisão, o
  contexto medido e as três alternativas já estão escritos; o I3 acrescenta a seção de
  implementação (a forma exata da leitura do reflog e as condições do fallback), e o I7 muda o
  status para `accepted`.
- **Lacuna 2: `branch:` igual à `DEFAULT_BRANCH` é aceito.** A resposta 3 recusa vazio e placeholder;
  `branch: main` é uma decisão explícita e passa. Os fixtures da suíte usam exatamente isso, porque é
  o valor em que o `ensure_mission_branch` não faz nada.
- **Lacuna 2: o `agents/sdd-kaizen.md` também muda**, além dos quatro arquivos que a resposta 3
  nomeia. Ele é o outro chapéu que escreve `00-missao.md`, e o `CLAUDE.md` manda atualizar o agente
  afetado no mesmo commit de uma mudança de contrato.
- **Lacuna 2: o raio foi medido antes.** A regra, prototipada numa cópia do kit, derruba 296
  asserções em seis sensores (`check-autonomy` 163, `check-gates` 84, `check-dry-run` 31,
  `check-adr` 10, `check-kaizen` 7, `check-coordination` 1), todas pelo mesmo motivo: cerca de vinte
  fixtures escrevem missão aprovada sem `branch:`. O I5 conserta os fixtures, nunca as asserções.
- **#52: uma linha parcial, sem `\n`, mantém o comportamento de hoje** (é descartada, "not approved",
  rc 0). Só o caso "nenhum caractere chegou" muda para 66. É a leitura mínima da resposta 2.
