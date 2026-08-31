---
missao: 20260831-a-rodada-que-andou
data: 2026-08-31
---

# Plano — A rodada que andou

> **Teste de autocontenção:** uma sessão nova, sem nenhuma memória da conversa que gerou este
> plano, lendo apenas `00-missao.md` + `01-plano.md` + `checkpoint.md`, consegue executar? Tudo o
> que ela precisa saber está abaixo. O `05-verdict.md` ao lado é **contexto**, não pré-requisito.
>
> A referência viva é `20260829-o-incremento-que-andou`: esta missão é a **mesma mudança**, uma
> fase adiante. Ler `KAIZEN_LOG.md` § 2026-08-29 antes do I1 economiza uma exploração cara — ele
> traz o desenho completo (foto × veredito, guarda de não-nulo, caminho datado) já revisado.

## Contexto verificado (não re-descobrir)

Cada linha abaixo foi confirmada nesta sessão por leitura de código ou saída de comando.

- **`review_rounds_on_disk()` já existe, é puro e já está no lugar certo** — `bin/sdd:2512`. Lê
  `latest_matching "$MISSION_DIR/40-review-r*.md"`, extrai o `<N>` do nome e imprime; `N`
  não-numérico responde `0` em vez de envenenar teste aritmético. É a mesma `latest_matching` que o
  `gate_REVIEW` usa, *"so the two cannot disagree about which round is latest"*.
- **Ele já é chamado ANTES da sessão, no `cmd_run`** — `bin/sdd:4046`, dentro do bloco do teto de
  rodadas. ⚠️ **Mas só sob `[ "$phase" = "REVIEW" ] && [ -z "$force_phase" ]`**: no caminho
  `--phase REVIEW` (humano pedindo uma rodada específica) ele **não** roda. A foto do I1 tem de
  ser tirada fora dessa condição, ou toda rodada forçada nasce com `rounds_before` nulo.
- **`REVIEW_MAX_ITER=3` e `QA_MAX_ITER=3`** — `bin/sdd:116`. O teto do REVIEW conta rodadas **em
  total**, derivadas do disco, e por isso `sdd run` não o reseta (`bin/sdd:4047-4049`).
- **`ledger_outcome_defs()` é a UMA definição, impressa como `jq`** — `bin/sdd:1924`. O `def
  outcome:` está em `bin/sdd:1925`, `def historic_progress:` em `:1926`, `def outcome_tally:` em
  `:1927`, `def phase_index:` em `:1928`. É costurada em **dois** consumidores, `cmd_autonomy` e
  `kaizen_series` — mexer aqui move os dois de uma vez, que é o ponto da função.
- **O braço de progresso do `outcome` é exclusivo do EXEC** — `bin/sdd:1925`, literal:
  `elif (.pending_before != null and .pending_after != null and .pending_after < .pending_before
  and .moved != false) then "advanced"`. A guarda de não-nulo é obrigatória: `jq` ordena `null`
  abaixo de todo número, então `null < 2` é **verdade**, e sem ela a sessão cujo gate recusou o
  artefato leria como o progresso mais alto do ledger — fail-open na direção da lisonja.
- **`def phase_label:` está em `bin/sdd:4935`**; a cláusula cega do `refez` é a **terceira**, em
  `bin/sdd:4938`: `((map(select(.event == "session")) | last | .gate) != "pass")`.
- **Os `GATE_WHY` de `gate_REVIEW` são oito, e seis carregam a rodada.** Enumerados nesta sessão
  com `awk '/^gate_REVIEW\(\)/,/^}/' bin/sdd | grep -n GATE_WHY`. Cinco começam com
  `$(basename "$last")`, que é literalmente `40-review-r<N>.md`; um é a string fixa
  `no 40-review-r<N>.md`, que significa **zero rodadas** (e cujo `<N>` não é dígito, então uma
  regex ancorada `^40-review-r([0-9]+)\.md` os separa sem ambiguidade). Os **dois** que não
  carregam nada são `TEST_CMD failed (...)` e `working tree dirty after the review`. Recuperação:
  6 de 8 motivos.
- **Os leitores de `.event` são 15, e foram contados, não estimados** — `grep -no '\.event ==
  "[a-z_]*"' bin/sdd | sort -u`. **Treze** selecionam `.event == "session"` explicitamente; os
  **dois** restantes são o par `def is_escalation: .event == "blocked" or .event == "degraded"`
  (`bin/sdd:4514` e `:4807`, uma definição por programa). Um valor de `event` novo é, portanto,
  **excluído por construção** em 15 de 15 sítios. É esta medição que sustenta o I4.
- **O enum de `event` é documentado como fechado** — `docs/pipeline.md:584`,
  ``string enum: `session` | `blocked` | `degraded` ``. Ao contrário do `kind` (linha 585), que a
  própria doc declara *"a documented enum with an open tail"*. Logo: valor novo de `event` é
  **mudança de contrato** e o `docs/pipeline.md` entra no MESMO commit.
- **Estado do ledger real hoje**, para o antes/depois:
  `"$SDD_HOME/bin/sdd" autonomy --all-repos | grep bf001fe` →
  `bf001fe  23 session(s) · 21 advanced · 2 churned · 0 idle · 8% waste · 3 mission(s) · US$ 175.96`
- ⚠️ **Âncora podre encontrada de passagem.** O item aberto do `TODO.md` sobre o gate que passa sem
  sessão aponta `bin/sdd:1080`; `pipeline_log_line()` está hoje em **`bin/sdd:1618`**. É o achado
  *"22 das 33 âncoras do `TODO.md` apontam para a linha errada"*, já aberto. Não conserte aqui —
  use `1618`.
- **`current_phase()` re-avalia todos os gates a cada derivação** (`bin/sdd:1357`) — medido no
  grill de revisão de 2026-08-31. Consequência para o I4: "gate que passa sem sessão" é o estado
  NORMAL de toda fase já fechada em toda retomada, e `sdd status` chama os mesmos gates. O
  contador que separa o caso interessante já existe no laço: `sessions[$phase]`, incrementado a
  cada `autonomy_session_row`. É ele que governa o escritor do I4.
- **O ledger real reforça o I3 além do que o plano previa**: 25 linhas de REVIEW hoje, **24
  recuperáveis** pela regex ancorada (15 `pass` + 8 `fail` com `40-review-r<N>.md`/`no
  40-review-r<N>.md`); a única fora é 1 `TEST_CMD failed`. O motivo "dirty tree" tem zero linhas.

## Arquitetura da mudança

O desenho é a cópia deliberada do que `20260829-o-incremento-que-andou` fez para o EXEC, e a cópia
é a virtude: aquele desenho já passou por revisão, por catálogo de mutação e por uma janela inteira.

```
cmd_run / cmd_retry ──foto──> rounds_before      (antes de run_phase; a pergunta é
   (bin/sdd:4046, fora da                         irrespondível depois: o revisor já
    guarda de force_phase)                        escreveu 40-review-r<N>.md)

gate_REVIEW ────────veredito──> rounds_after      (assim que `last` é resolvido — o N é
   (bin/sdd:1011)                rounds_max        ESTRUTURAL, está no nome do arquivo,
                                                   ninguém o auto-declara)

ledger_outcome_defs ──── def outcome ganha o braço da rodada, com guarda de não-nulo
   (bin/sdd:1924)     └── def historic_rounds: caminho DATADO para as linhas antigas
                           (irmão de historic_progress, mesma forma, mesmo sinal de apagamento)

phase_label (bin/sdd:4935) ──── a cláusula 3 do `refez` aprende que a fase pode ter fechado
                                sem gastar sessão, lendo um FATO gravado e não uma ausência
```

**Três campos, não dois**, e `rounds_max` não é enfeite: sem ele a leitura "3 de 3, a fase acabou o
orçamento" é indistinguível de "3 de 10", e é exatamente o par que o `increments_total` do EXEC
existe para fechar. `v` continua `1` — o esquema é **aditivo**, e nenhuma linha do ledger é
reescrita nem migrada. O ledger é append-only por contrato.

## Incrementos

A tabela executável vive em `checkpoint.md` (é ela que o runner lê). Aqui fica o **porquê**.

### I1 — A linha de REVIEW carrega `rounds_before`, `rounds_after` e `rounds_max`

**O quê:** três campos aditivos na linha de sessão da fase REVIEW. `rounds_before` é a foto tirada
por `cmd_run` **e** por `cmd_retry` antes de `run_phase`, via `review_rounds_on_disk()`.
`rounds_after` e `rounds_max` (`$REVIEW_MAX_ITER`) são publicados por `gate_REVIEW` assim que o
arquivo da rodada é resolvido. Fora do REVIEW os três são `null`, exatamente como o
`pending_before` é `null` fora do EXEC.

**Onde:** `bin/sdd` — `cmd_run` (perto de `:4046`), `cmd_retry`, `gate_REVIEW` (`:1011`), e o
construtor `autonomy_session_row`. `docs/pipeline.md` § "The autonomy ledger" (a tabela de campos).

**Como (TDD):** o probe vem primeiro, em `tests/check-autonomy.sh`. Fixture que roda uma fase
REVIEW e afirma que a linha do ledger traz os três campos com os valores certos. Antes da mudança
ele falha por campo ausente.

⚠️ **A foto tem de sair de fora da guarda `[ -z "$force_phase" ]`** (contexto verificado). Um
`sdd run --phase REVIEW` é o caminho que o humano usa para destravar uma missão, e é justamente
aquele em que a rodada mais interessa.

⚠️ **A publicação de `rounds_after` é assimétrica com o `pending_after` do EXEC de propósito** — o
`pending_after` é veredito porque o checkpoint é rótulo que o executor escreve sobre si mesmo; o
`N` de `40-review-r<N>.md` é estrutural. Escreva o porquê no comentário da função, ou a próxima
revisão vai "consertar" a assimetria.

**Check:** `` o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    the REVIEW row carries rounds_before, rounds_after and rounds_max' <<< "$o" `` → `1`
**Sensor durável:** o probe acima + `mut_RUN_review_rounds_photo_missing` no `tests/check-mutation.sh`.
**Reversível por:** reverter o commit. Campos aditivos que ninguém lê ainda são inertes — o I1
sozinho não muda número nenhum, e isso é a propriedade que o torna seguro.

### I2 — `def outcome` aprende que a rodada andou

**O quê:** o braço `advanced` ganha `(.rounds_before != null and .rounds_after != null and
.rounds_after > .rounds_before and .moved != false)`. **A guarda de não-nulo é obrigatória** pelo
mesmo motivo do EXEC: `jq` ordena `null` abaixo de todo número, então sem ela `2 > null` é
verdadeiro e a sessão de REVIEW cujo gate recusou o artefato leria como o progresso mais alto do
ledger. Uma definição só (`ledger_outcome_defs`, `bin/sdd:1924`); os dois consumidores herdam.

**Onde:** `bin/sdd:1925`.

**Como (TDD):** dois probes, e o segundo é o que importa. (1) uma sessão de REVIEW que subiu a
rodada e reprovou o gate lê `advanced`; (2) **asserção diferencial** — a mesma fatia lida por
`cmd_autonomy` e por `kaizen_series` responde **igual**, as duas saídas comparadas entre si. A
casa não aceita "mesma grafia nos dois programas" como prova de paridade: o `$order` do
`cmd_autonomy` e o `on_axis` do `kaizen_series` já divergiram uma vez sob um comentário jurando o
contrário (`20260817-catraca-do-backlog`, r1).

⚠️ **Prove o vermelho pelo motivo certo.** Um fixture em que `rounds_after > rounds_before`
coincide com `gate == "pass"` é satisfeito pelo **primeiro** braço do `outcome` e não mede nada. O
fixture tem de ter o gate reprovando.

**Check:** `` o=$(bash tests/check-kaizen.sh 2>&1); grep -c '^  ok    a REVIEW round that advanced reads advanced, never churned' <<< "$o" `` → `1`
**Sensor durável:** os dois probes + `mut_LEDGER_outcome_rounds_unguarded` (apaga a guarda de
não-nulo — tem de morrer) e `mut_LEDGER_outcome_rounds_blind` (apaga o braço inteiro).
**Reversível por:** reverter o commit; o I1 fica e volta a ser inerte.

### I3 — O caminho datado: as linhas de REVIEW anteriores ao esquema

**O quê:** `def historic_rounds`, irmão de `historic_progress` (`bin/sdd:1926`), recuperando
`rounds_after` do `gate_why` que a linha já carrega verbatim. Regex ancorada
`^40-review-r([0-9]+)\.md` sobre `gate_why`; a string fixa `no 40-review-r<N>.md` recupera **0**
(e não casa a regex, porque `<N>` não é dígito). `rounds_before` é o `rounds_after` da linha de
REVIEW anterior da mesma `[repo, mission]` em ordem de arquivo, com a memória zerada por um gate
que **passou** — as mesmas duas regras do EXEC, cada uma com fixture próprio.

A linha anotada carrega `rounds_source: "gate_why"`, para que a leitura nunca seja confundida com
uma medição, e `cmd_autonomy` **imprime quantas linhas alcançou** — que é também o **sinal de
apagamento**: o dia em que a frase sumir, esta `def` não tem mais linha a servir e sai.

**Onde:** `bin/sdd:1926` (vizinhança), mais a frase de divulgação em `cmd_autonomy`.

**Como (TDD):** fixture `histfix` de REVIEW com linhas sem os campos, afirmando (1) que a rodada é
recuperada, (2) que uma linha `TEST_CMD failed` **não** é anotada — e é isso que a torna um limite
declarado em vez de um fail-open — e (3) que a frase de divulgação sai com a contagem certa.

⚠️ **Use `.rounds_before == null` e NUNCA `has("rounds_before")`.** O construtor do I1 põe a
**chave** em toda linha que este runner escreve, com valor `null` fora do REVIEW; as linhas
anteriores ao esquema não têm chave nenhuma. `== null` é a única grafia certa sobre as duas
populações, e a versão anterior deste comentário no EXEC tinha o fato **invertido** até alguém
medir com `grep -c`.

⚠️ **A frase de divulgação do irmão tem bug aberto** (`TODO.md`, `bin/sdd:4535`): `$historic` é
ligado depois do filtro de repo e **antes** da comparabilidade, então conta linhas que depois saem
como não-comparáveis. **Não repita a forma** — ligue sobre `is_session and comparable`. Isto
fecha o item aberto de graça; registre `RESOLVIDO por <hash>` nele.

**Check:** `` o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    a pre-schema REVIEW row recovers its round from gate_why' <<< "$o" `` → `1`
**Sensor durável:** os três probes + `mut_LEDGER_historic_rounds_blind`.
**Reversível por:** reverter o commit. As linhas antigas voltam ao braço `moved`; nada é perdido,
porque nada foi reescrito.

> **Ponto de corte da métrica — MEDIDO em 2026-08-31, e a linha parou aqui como mandava.** A
> previsão original (`bf001fe` → `22 advanced · 1 churned`) tinha a premissa factual errada; a
> medição real (diff dos dois `bin/sdd` contra o MESMO ledger) move as fatias `d89ea43`,
> `e9a3681` e `353b4b1` e deixa `bf001fe` inerte **por mérito** (a churn dela não pousou rodada).
> O humano decidiu pelo caminho (a): a métrica (1) do `00-missao.md` foi reescrita para a medição
> real e o I4 voltou a `pending`. **Não re-litigar** — o relato completo está nas notas do
> `checkpoint.md`.

### I4 — A fase que fechou sem gastar sessão para de ler `refez`

**O quê:** o runner **grava o fato** de que uma fase fechou de graça — uma linha
`event: "gate_pass"`, sem custo, sem sessão, nomeando `phase` e `mission`. A cláusula 3 do `refez`
(`bin/sdd:4938`) passa a ler "a fase fechou?" em vez de "a última sessão passou?".

⚠️ **A condição de escrita é ESTREITA, e foi decidida pelo humano no grill de 2026-08-31** (ver
Contexto verificado: `current_phase()` re-avalia TODOS os gates a cada derivação, então "gate que
passa sem sessão" acontece para toda fase já fechada, em toda retomada — e também em `sdd status`).
A linha só nasce **no laço do `cmd_run`**, e só quando `sessions[$phase] > 0` nesta invocação — a
fase comprou ao menos uma sessão nesta corrida, reprovou o gate, e ele fechou depois sem gastar
outra. No máximo **uma** linha por fase por corrida; `sdd status` e todo comando de leitura
continuam só-leitura. **Limite declarado** (vai no comentário do escritor): a fase que fecha de
graça numa corrida FUTURA — sessão paga na corrida N, gate fechando sozinho na N+1 — não gera
linha; o `refez` dela se corrige na primeira corrida em que o padrão se repete, e a alternativa
(gravar em toda derivação) despejava até 6 linhas por retomada num ledger append-only.

**Onde:** `bin/sdd` — o laço do `cmd_run`, um construtor de linha irmão do `autonomy_blocked_row`,
`def phase_label` (`:4935`), e **`docs/pipeline.md:584`** (o enum de `event`) no mesmo commit.

**Como (TDD):** três probes.
1. **Reprodução primeiro.** Fixture em que a fase gasta uma sessão que reprova o gate e o gate
   passa depois sem sessão. Antes da mudança o rótulo é `refez`; depois, não é. Sem este probe
   vermelho primeiro, o resto é decoração.
2. **A asserção DIFERENCIAL, que é o coração deste incremento.** Duas fatias idênticas, uma **com**
   as linhas `gate_pass` e outra **sem**, comparadas campo a campo: `outcomes`, `advance_rate`,
   `moved_rate`, `cost_usd`, `composition`, `guard` e os **cinco** baldes de `excluded` têm de ser
   **idênticos**. Só `labels` pode diferir. Isto é a medição que substitui a previsão.
3. `is_escalation` responde **false** para o evento novo, nos dois programas.

⚠️ **O risco real, e ele é nomeável: `excluded.unrecognized`.** A série publica cinco baldes, e o
juiz lê `unrecognized > 0` como **bug de kit**. Se o admissor da série filtrar por "é sessão ou é
escalada" e jogar o resto em `unrecognized`, este incremento faz o `sdd kaizen --series` acusar o
próprio kit. O probe (2) é o que pega isso, e é por isso que ele compara os cinco baldes e não só
os números bonitos.

⚠️ **A base para acreditar que o raio de alcance cabe num incremento é medida, não sentida:** dos
15 leitores de `.event`, **13** selecionam `session` explicitamente e os outros **2** são o par
`is_escalation`. Um valor novo é excluído em 15 de 15 sítios por construção. Mas medição de sítio
não é medição de comportamento — quem prova é o probe (2).

⚠️ **Jidoka.** Se a asserção diferencial acusar diferença em qualquer campo além de `labels`, ou se
o raio de alcance exceder os cinco leitores enumerados, **este incremento vira `blocked` e missão
própria**. I1–I3 já entregaram a métrica; empilhar contrato de ledger sobre uma surpresa é como se
compra a volta seguinte. O plano B, escrito e **não** recomendado, é inferir o fechamento pela
ordem das fases usando o `def phase_index` que já existe (`bin/sdd:1928`) — barato, sem mudança de
contrato, e é a forma que `f00c2dc` recusou com *"uma inferência não passa na frente do que o
runner mediu"*. Trocar a recomendação é decisão do humano, não da sessão.

**Check:** `` o=$(bash tests/check-kaizen.sh 2>&1); grep -c '^  ok    a phase that closed without a session does not read refez' <<< "$o" `` → `1`
**Sensor durável:** os três probes + `mut_RUN_gate_pass_row_missing` e
`mut_LEDGER_phase_label_last_session_blind`.
**Reversível por:** reverter o commit. O evento novo some do código; linhas `gate_pass` já
escritas em ledger local ficam órfãs e são inertes (nenhum leitor as seleciona) — o que é a mesma
propriedade medida acima, agora usada ao contrário.

## Triagem D15 — itens que saem do backlog para o cabeçalho do sensor

> Pela régua de admissão (D15): entra no `TODO.md` o achado cujo sensor **afirma medir o que não
> mede** (fail-open) ou cujo defeito tem **consumidor fora da suíte do próprio kit**. Os três
> abaixo não são nem um nem outro — pelo texto dos **próprios itens** — e por isso são dívida
> **declarada**, que mora no cabeçalho do sensor. ⚠️ Estes três **não** são executados nesta
> missão: ficam onde estão, com destino nomeado, para a faxina D15 já listada como missão própria
> em `docs/superpowers/specs/2026-08-30-janela-2-handoff.md:178`. Nomear o destino é a metade que
> ataca a **taxa de nascimento**; a outra metade é a faxina.

| Item (título abreviado) | Por que sai | Vai para |
|---|---|---|
| *"O censo `guard:` conta captura escrita dentro de COMENTÁRIO"* | O próprio item diz: **"Falha FECHADA, então não certifica nada de errado"**. Incomoda quem escreve neste repo, não mente sobre o que mede | cabeçalho de `tests/check-health.sh`, limites declarados |
| *"O `check-health.sh` diz 'the four silent aborts' e o catálogo tem cinco"* | O próprio item diz: **"Os dois mutantes são pegos, então não é fail-open — é o cabeçalho subcontando"**. Sem consumidor fora da suíte | cabeçalho de `tests/check-health.sh` (é literalmente o texto errado do cabeçalho) |
| *"A regra 3 nomeia o comando errado quando a linha tem DOIS greps"* | O item **cita o próprio limite já declarado** no comentário de `maxc_violations`, e registra "nenhuma instância no kit hoje". É duplicata da declaração | já está em `tests/check-pipefail.sh`; o item sai por redundância |

**Ficam abertos, e a régua diz por quê:** *"A regra `cdpath:` não vê `cd --` nem comando quebrado
com `\`"* é **fail-open** (a regra afirma medir a classe do `CDPATH` e não vê duas grafias dela) —
escrever no cabeçalho não conserta, só deixa de mentir. *"`sdd retry` devolve 3 sem escrever linha
de escalada no ledger"* tem consumidor **fora** da suíte: é o juiz, e é a mesma família desta
missão.

## Resolvidos a apagar

**Nenhum.** Provado por comando nesta sessão: `grep -n 'RESOLVIDO por' TODO.md` devolve apenas as
**quatro** linhas do cabeçalho e de um item que *fala sobre* a convenção (`TODO.md:16`, `:24`,
`:482`, `:484`) — zero itens fechados aguardando varredura. `tests/check-todo.sh` conta
`87 finding(s)`, e `tests/health-baseline.txt` congela `todo-findings 87`: a catraca está em dia
nos dois sentidos.

⚠️ **Se o I3 fechar o item da frase de divulgação** (`bin/sdd:4535`), ele ganha
`RESOLVIDO por <hash>` no corpo e **fica** no arquivo até o PR mergear — a catraca **não** desce
nesta missão. É a colisão que o item *"O ciclo de vida do `RESOLVIDO por` e a catraca do backlog não
cabem juntos"* já descreve; não tente resolvê-la aqui.

## Riscos e não-feitos

| Risco | Probabilidade | Mitigação |
|---|---|---|
| **A régua muda no meio do laço de medição**, e a janela 2 deixa de ser comparável com a 3 | **alta — é certeza, não risco** | Campos aditivos + caminho datado (I3): as 23 linhas de `bf001fe` continuam re-deriváveis, nada é migrado. O antes/depois vai medido para o `KAIZEN_LOG.md` (K8) e o aviso de régua já está escrito no `05-verdict.md` |
| O evento novo do I4 cai em `excluded.unrecognized` e o `sdd kaizen --series` passa a acusar bug de kit | média | É o probe (2) do I4, a asserção diferencial sobre os **cinco** baldes. Se acusar: Jidoka do I4 |
| A foto de `rounds_before` fica dentro da guarda `force_phase` e toda rodada forçada nasce nula | média — a linha já está escrita assim hoje | Nomeado no contexto verificado e no I1; o probe do I1 exercita o caminho `--phase REVIEW` |
| Guarda de não-nulo esquecida no I2 ⇒ fail-open na direção da **lisonja** | média | `mut_LEDGER_outcome_rounds_unguarded`. É o erro exato que o EXEC quase cometeu, e está documentado no `KAIZEN_LOG` de 2026-08-29 |
| A linha `bf001fe` do ledger real se move por outra causa e o antes/depois fica ilegível | baixa | As sessões desta missão nascem em shas **novos** do kit (cada commit muda o `kit_sha`), então não entram no grupo `bf001fe`. Se entrarem, é achado — registre, não remende |
| Mutantes novos empurram a suíte ainda mais longe do alvo "<30 s" da D7 | alta | Já é pendência declarada do humano (`00-missao.md` § Pendências, item 3). Não se corta mutação para ganhar relógio |
| O carimbo de mutação é invalidado por tudo que esta missão toca (`bin/`, `tests/`, `docs/pipeline.md` não) | **certeza** | Rode `./bin/sdd health` **depois do último commit de código** e antes do `gate_PR`. `CLAUDE.md` mede o custo do erro de ordem em 20 a 50 min |

## Verificação end-to-end

Com os quatro incrementos `done`:

1. **A métrica (1), no ledger real.**
   `"$SDD_HOME/bin/sdd" autonomy --all-repos | grep bf001fe`
   → tem de conter `22 advanced · 1 churned · 0 idle · 4% waste` (hoje: `21 advanced · 2 churned ·
   0 idle · 8% waste`), com `3 mission(s) · US$ 175.96` **inalterados** — se o custo ou a contagem
   de missões se mexerem, a mudança não foi aditiva e a verificação **falhou**.
2. **A métrica (2), por sensor.** Os quatro Checks do `checkpoint.md` verdes, que é o que prova que
   a mudança tem juiz depois que esta missão acabar.
3. **A suíte inteira e o catálogo.** `./tests/run-all.sh` verde e `./bin/sdd health` carimbando
   `N caught of N` com o catálogo **crescido** pelos seis mutantes novos — `sdd health` reprova
   regra nova sem mutação, e é ele quem carimba o `gate_PR`.
4. **O registro.** `KAIZEN_LOG.md` com a tabela antes/depois carregando os dois comandos e as duas
   saídas verbatim. Sem número medido não é kaizen — é opinião.
