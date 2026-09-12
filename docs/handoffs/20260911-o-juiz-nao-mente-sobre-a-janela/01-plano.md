---
missao: 20260911-o-juiz-nao-mente-sobre-a-janela
data: 2026-09-11
---

# Plano — o juiz não mente sobre a janela

> **Teste de autocontenção:** uma sessão nova, sem nenhuma memória da conversa que gerou este
> plano, lendo apenas `00-missao.md` + `01-plano.md` + `checkpoint.md`, consegue executar?
> Tudo que ela precisa saber e que não é óbvio está abaixo.

## Contexto verificado (não re-descobrir)

Cada linha foi confirmada por comando nesta sessão de kaizen (2026-09-11), no HEAD
`ef7e22c`, branch `kaizen/o-veredito-da-janela-4`.

- **O ledger real e sua contaminação** — `grep -o '"repo":"[^"]*"' ~/.sdd/autonomy-log.jsonl | sort | uniq -c | sort -rn`
  responde: 155 `/home/joruge/repos/sdd_agents`, 125 `/home/joruge/repos/sales_quote`, 5
  `/tmp/qa-portas/clone`, 3 `/tmp/sddrev.q49jXD/r7b`, e 1 cada para `/tmp/manual-XB2BJO`,
  `/tmp/manual-sWv4nl`, `/tmp/manual-kIca1U`. Total 291 linhas, **11 sob `/tmp`**.
- **O backlog hoje** — `bash tests/check-todo.sh` termina com
  `ok    105 finding(s), all within 8 lines and carrying anchor + date`, e
  `tests/health-baseline.txt:26` diz `todo-findings 105`. ⚠️ `grep -c '^- \[ \]' TODO.md` responde
  **106**: conta a linha de exemplo do bloco cercado do cabeçalho. **A contagem sai do sensor,
  nunca do grep.**
- **A fatia julgada** — `sdd kaizen --series` sobre `latest.kit_sha = a0e34df`:
  `guard.sufficient: true`, `floor: 3`, `degenerate_axis: false`, `harness: ["2.1.263"]`,
  `excluded.other_repo: 0`, `excluded.no_repo: 0`. O veredito está em `05-verdict.md`.
- ⚠️ **As âncoras `arquivo:linha` do `TODO.md` derivaram e não são confiáveis.** Medido: o item
  que cita `bin/sdd:4929` para o `$order` do `cmd_autonomy` cai hoje dentro de `cmd_approve`
  (`frontmatter_write "$m" aprovacao …`); o que cita `bin/sdd:1918` cai no bloco de handoff do
  `boot_prompt`. É o item aberto `TODO.md:264` (o sensor mede a **forma** da âncora, nunca se ela
  aponta o alvo). **Localize todo sítio por código** — `grep -n` pelo identificador —, jamais
  abrindo a linha citada. Isto vale para cada incremento abaixo.
- **A composição da série** vem de `group_by(.repo // "")` dentro do `kaizen_series` no `bin/sdd`
  (o bloco que emite `composition:`, `sessions:`, `harness:`, `outcomes:`). O campo `harness:` já
  existe e é `($sess | map(.harness // empty) | unique)` — ou seja, **o dado para I5 já está
  coletado**; o que falta é a guarda que o lê.
- **O `sdd health` carimba o catálogo de mutação** e a chave é o conteúdo de
  `bin/ tests/ templates/ config/`. ⚠️ `tests/health-baseline.txt` **está dentro da chave**: mexer
  na catraca do backlog **mata o carimbo**. Consequência operacional dura: o `sdd health` roda
  **depois** do último commit que toca esses quatro diretórios, e I6 é o último incremento por
  isso. É o item aberto `TODO.md:523`, e esta missão convive com ele em vez de consertá-lo.
- **Gate novo/conserto de gate entra com mutante** — `sdd health` reprova gate sem mutação no
  catálogo (`tests/check-mutation.sh`). Vale para I2, I3, I4 e I5.
- **A suíte é `tests/run-all.sh`** (13 sensores; `check-mutation.sh` é opt-in desde `4c86712`).
  Sensor novo entra em **quatro** lugares: a linha `run` do `run-all.sh`, o `LINT_FLOOR` do mesmo
  arquivo, o piso de superfície do `check-pipefail.sh` e o do `check-lang.sh` — mais o fixture do
  selftest do `check-pipefail.sh`, que é construído no piso. Esta missão **não cria sensor novo**,
  só acrescenta probes a sensores existentes, então os pisos sobem em vez de nascer.
- ⚠️ **Pisos anti-vacuidade sobem junto com os probes.** Vários sensores carregam um `*_FLOOR`
  contando asserções. Acrescentar probe sem subir o piso é inofensivo; **remover** sem baixar
  reprova. Confira o piso do arquivo que você tocar antes de commitar.
- ⚠️ Este repo roda sob `set -euo pipefail`: `printf … | grep -q` devolve **141** quando o grep
  ACHA (SIGPIPE). Use herestring (`<<< "$var"`). Idem `grep -m<N>` sem quiet, cobrado pela RULE 3
  do `check-pipefail.sh`.
- ⚠️ `cd` com operando relativo dentro de `$(...)` leva `CDPATH='' cd` **sempre** — RULE 2
  (`cdpath:`) do `check-pipefail.sh` varre `bin/` e `tests/` linha a linha e reprova.
- ⚠️ A última linha do `bin/sdd` é `{ main "$@"; exit $?; }` e a forma é contrato
  (`tests/check-entrypoint.sh`). Não mexa nela.
- ⚠️ Missão de repo do kit escreve no `TODO.md` **deste** repo — é o caso aqui, e é permitido.

## Arquitetura da mudança

Quatro camadas, de baixo para cima, e a ordem não é negociável:

1. **O dado** (I1) — o ledger real deixa de receber escrita de fixture, e as 11 linhas já escritas
   saem. Tudo acima mede sobre dado limpo ou não mede nada.
2. **A população** (I2, I3) — quem entra na conta. As duas metades da guarda passam a concordar por
   asserção diferencial, e as duas métricas cegas (`reopened`, fronteira do laço de revisão)
   passam a ler a população que prometem.
3. **Os eventos que faltam** (I4) — `sdd close` e `sdd retry` passam a escrever sua linha. Sem
   isso a população de (2) continua tendo buracos legítimos.
4. **A recusa** (I5) — com dado, população e eventos corretos, a guarda passa a **recusar** as
   fatias sobre as quais não pode responder, em vez de responder alto sobre elas.

E depois, fora da pilha: (I6) a dívida que é limite e não defeito sai do backlog para o cabeçalho
do sensor dono, e a catraca desce num diff com autor.

**Nenhum `gate_<FASE>` é tocado.** É deliberado: é o que impede esta missão de tornar uma missão em
voo insatisfazível (princípio 1), e é por isso que o lote é de risco baixo apesar de nove itens.

## Incrementos

A tabela executável vive em `checkpoint.md` (é ela que o runner lê). Aqui fica o **porquê** de
cada fatia.

### I1 — o ledger real deixa de ser escrivível por fixture, e sai o que já entrou

**O quê:** duas coisas, e a segunda não vale sem a primeira. (a) Uma guarda de escrita: quando a
corrida está sob fixture — checkout sob `$TMPDIR`/`/tmp`, ou `SDD_MUTANT` armado — o escritor do
ledger **recusa** escrever no ledger real e escreve no estado apontado por `SDD_STATE_DIR`. (b) As
11 linhas `/tmp` já presentes saem de `~/.sdd/autonomy-log.jsonl`, com o arquivo original copiado
ao lado antes (`autonomy-log.jsonl.bak-<data>`) — é dado histórico do humano, não artefato do repo.

**Onde:** `bin/sdd`, o escritor do ledger (localize por `grep -n 'autonomy_log_path\|autonomy_.*_row' bin/sdd`);
`tests/check-autonomy.sh` para o probe.

**Como (TDD):** primeiro o probe — uma corrida de fixture sob `/tmp` tenta escrever e a asserção
exige que o ledger real **não cresça**. Ele fica vermelho antes da guarda existir, porque hoje o
arquivo cresce: é exatamente como as 11 linhas chegaram lá.

**Check:** `grep -c '"repo":"/tmp' ~/.sdd/autonomy-log.jsonl` → `0`

**Sensor durável:** o probe novo em `tests/check-autonomy.sh`, mais um mutante no catálogo que
neutraliza a guarda e exige que a suíte morra.

**Reversível por:** reverter o commit e restaurar o `.bak`. A guarda é aditiva; nada que hoje
escreve legitimamente deixa de escrever.

⚠️ **Jidoka:** se o probe não conseguir ficar vermelho antes da guarda — isto é, se você não
conseguir construir o mundo em que o fixture contamina —, **pare a linha** e escreva no
`checkpoint-notas.md` **qual mundo você não conseguiu construir**. Nunca escreva que ele não
existe: a contaminação está medida em 11 linhas reais.

### I2 — `$order` e `comparable_row` param de divergir, e a paridade vira asserção

**O quê:** fecha dois itens do `TODO.md` que são o mesmo defeito visto de dois lados. (a) O
`$order` do `cmd_autonomy` decide "qual é a versão mais recente" sobre `is_session and comparable`,
enquanto o `kaizen_series` decide sobre toda linha `on_axis` — e o comentário entre os dois **jura**
paridade. (b) Uma missão que só tem `gate_pass` numa fatia entra em `missions` sem produzir célula.

**Onde:** `bin/sdd` — localize por `grep -n 'comparable_row\|shas_in_file_order\|is_escalation' bin/sdd`.
Fixtures e asserções em `tests/check-kaizen.sh` e `tests/check-autonomy.sh`.

**Como (TDD):** a asserção é **diferencial** — dois programas lidos sobre **o mesmo arquivo de
fixture**, saídas comparadas entre si. Nunca uma frase de comentário, e nunca cada lado contra um
número fixo: é a regra que este repo já aplicou três vezes. O fixture precisa carregar uma escalada
como **primeira linha de uma versão** e uma missão só com `gate_pass`, que são os dois regimes em
que as janelas divergem hoje.

⚠️ **O predicado de admissão se escreve positivamente** (`session or escalation`), nunca
`is_gate_pass | not`: a forma negativa concorda sobre a população de hoje e faz o **quarto** evento
cunhar versão por omissão.

**Check:** `o=$(bash tests/check-kaizen.sh 2>&1); grep -c '^  ok    differential' <<< "$o"` → ao menos `1`

**Sensor durável:** o par diferencial em `tests/check-kaizen.sh` + um mutante por lado no catálogo
(mexer em qualquer das duas janelas tem de reprovar).

**Reversível por:** reverter o commit; as duas janelas voltam a divergir e a asserção diferencial
sai junto.

### I3 — `reopened` e a fronteira do laço de revisão leem a população que prometem

**O quê:** (a) `reopened` é cego à closure e a resposta depende de a fase ter **custado dinheiro**;
(b) a fronteira do laço de revisão é calculada sobre o subconjunto `comparable` e **sub-reporta** —
é a métrica que o veredito de hoje cita como 52%, 23% e 66%. Uma decisão de população fecha as duas.

**Onde:** `bin/sdd`, no `cmd_autonomy` — localize por `grep -n 'reopened\|review loop' bin/sdd`.

**Como (TDD):** fixture com uma fase reaberta de custo **zero** e uma missão cujo laço de revisão
tem rodadas fora do `comparable`; asserção exige o número **maior** (o que inclui), e uma
testemunha que conte quantas vezes o ramo foi entrado — a propriedade é universal mas o fixture só
anda num regime, então sem a testemunha o verde é do fixture e não da propriedade.

**Check:** `o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    reopened' <<< "$o"` → ao menos `1`

**Sensor durável:** os probes novos em `tests/check-autonomy.sh` + mutantes no catálogo.

**Reversível por:** reverter o commit. ⚠️ O número do laço de revisão **vai subir** para missões
já medidas: isso é o conserto, não uma regressão. Registre o antes/depois no `KAIZEN_LOG` (I6).

### I4 — `sdd close` e `sdd retry` escrevem a linha que devem

**O quê:** `sdd close` abre sessão e não escreve linha no ledger; `sdd retry` devolve 3 sem linha
de escalada nem `BLOCKED` no `pipeline.log`. O `docs/pipeline.md` promete "uma linha JSON por
sessão gasta ou escalada" e as duas quebram a promessa — fail-open com consumidor fora da suíte (o
juiz e a D12, que conta `launches`).

**Onde:** `bin/sdd`, `cmd_close` e `cmd_retry` (localize por `grep -n '^cmd_close()\|^cmd_retry()' bin/sdd`).
Probes em `tests/check-autonomy.sh`.

**Como (TDD):** o probe conta linhas do ledger de fixture antes e depois de um `close` e de um
`retry` que escala; vermelho antes, porque hoje a contagem não muda.

⚠️ `sdd close` é uma das **duas** invocações deliberadas de `claude -p` que não rodam fase. Ele
continua não sendo fase: ganha linha de ledger, não gate.

⚠️ Se a linha nova de `close` precisar de um campo que a distinga da linha de sessão (o
`CONTEXT.md` já descreve **três** formas de linha), acrescente-o **explicitamente** e atualize o
leitor no mesmo commit — enum lido em mais de um ponto é UMA definição por programa.

**Check:** `o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    close writes' <<< "$o"` → ao menos `1`

**Sensor durável:** os dois probes + dois mutantes no catálogo, um por porta.

**Reversível por:** reverter o commit; as duas voltam a ser silenciosas.

### I5 — a guarda recusa a fatia sobre a qual não pode responder

**O quê:** duas recusas novas na `guard` da série. (a) `harness`: a fatia que carrega **duas ou
mais** versões de harness responde `sufficient: false` com o motivo nomeado — hoje responde `true`,
e o sha julgado nesta janela é justamente o que consertou um estrago de bump de harness. (b) a
janela que foi **rompida** (declarada partida à mão) passa a ter instrumento que a perceba, em vez
de `degenerate_axis: false` sobre uma janela partida.

**Onde:** `bin/sdd`, no bloco `guard:` do `kaizen_series` — localize por
`grep -n 'sufficient\|degenerate_axis\|harness:' bin/sdd`. O campo `harness` **já é coletado**
(`($sess | map(.harness // empty) | unique)`); falta só lê-lo na guarda.

**Como (TDD):** dois fixtures de ledger — um com `harness` de duas versões na mesma fatia, outro
com a janela rompida — e asserção exigindo `sufficient: false` **e o motivo**, não só o booleano:
`false` é compartilhado com "faltam missões", e asserção que lê só o `rc`/booleano não distingue
nada. Exija o texto do ramo certo **e a ausência** do marcador do outro.

⚠️ A guarda se escreve **positivamente**: declare qual composição de harness é aceita, nunca
`not <o que recusa>` — a forma negativa admite todo harness futuro por omissão.

⚠️ **Isto muda o veredito de fatias futuras, não o de hoje:** `latest.harness` é `["2.1.263"]`,
uma só. Confirme que a fatia real continua `sufficient: true` depois da mudança — se ela virar
`false`, a guarda está errada e a linha para.

**Check:** `o=$(bash tests/check-kaizen.sh 2>&1); grep -c '^  ok    guard: two harness' <<< "$o"` → ao menos `1`

**Sensor durável:** os dois fixtures em `tests/check-kaizen.sh` + um mutante por cláusula de guarda.

**Reversível por:** reverter o commit; a guarda volta a aceitar tudo.

### I6 — a dívida que é limite sai do backlog para o cabeçalho do sensor dono

**O quê:** a régua D15 aplicada. Dez itens que **não** são fail-open e **não** têm consumidor fora
da suíte do kit saem do `TODO.md` e viram **limite declarado** no cabeçalho do sensor a que
pertencem. Nada se perde: o fato passa a morar onde quem lê o sensor o encontra. Mais o registro
do antes/depois no `KAIZEN_LOG.md` e a catraca movida num diff com autor.

**Onde (cada item e o arquivo para o qual ele se muda):**

| Item do `TODO.md` | O quê | Vai para |
|---|---|---|
| `pushd "$(…)"` tem o mesmo bug de CDPATH | nenhuma instância viva; alargar `CD_RE` ou declarar | cabeçalho de `tests/check-pipefail.sh`, bloco de limites do `CD_RE` |
| `cdpath:` não vê `cd --` nem quebra com `\` | nenhuma instância viva; leitura é de linha física | cabeçalho de `tests/check-pipefail.sh`, mesmo bloco |
| regra 3 nomeia o comando errado com dois greps | nenhuma instância no kit; casar por comando pede parser de shell | comentário de `maxc_violations`, em `tests/check-pipefail.sh` |
| "the four silent aborts" e o catálogo tem cinco | não é fail-open: os dois mutantes são pegos, o cabeçalho subconta | cabeçalho de `tests/check-health.sh` |
| "all ten assertions" contra 14 probes | a frase fala de **todas**; escrever 14 nasce velho | comentário de `tests/check-entrypoint.sh`, com o `grep` ao lado e **sem** número fixo |
| `reviewscope_files()` não declara o limite dele | o arquivo usa `DECLARED LIMIT:` em três outros pontos e este não | `tests/check-autonomy.sh`, na forma `DECLARED LIMIT:` que o arquivo já usa |
| espelho global de vereditos (JSONL) | YAGNI declarado, D3 do `CONTEXT.md`, "criar junto com a graduação" | `CONTEXT.md`, decisões adiadas |
| multi-missão concorrente por `git worktree` | YAGNI declarado no plano original | `CONTEXT.md`, decisões adiadas |
| `sdd digest` para o vault Obsidian | YAGNI declarado no plano original | `CONTEXT.md`, decisões adiadas |
| (o décimo) | escolha do executor entre os itens restantes que sejam **comprovadamente** nem fail-open nem de consumidor externo; se nenhum passar no corte, **feche em 9** e ajuste a métrica para `96 finding(s)` | — |

**Resolvidos a apagar:** **nenhum**. Verificado nesta sessão: `grep -n 'RESOLVIDO' TODO.md` devolve
4 linhas e todas são metalinguagem (o bloco de citação do ciclo de vida, e o corpo de um item
aberto que cita o token). Não há hash a testar com `git merge-base --is-ancestor <hash> main`, e
portanto não há item a apagar por essa rota nesta missão.

⚠️ **Não é licença para esvaziar o backlog.** Um item só se muda se for demonstravelmente nenhum
dos dois casos da D15. Na dúvida, ele **fica**. Nove itens movidos com argumento valem mais que
dez com um chute.

**Como (TDD):** o Check é a contagem do sensor, e ele é o teste. Escreva o cabeçalho primeiro,
apague o item depois.

**Check:** `o=$(bash tests/check-todo.sh 2>&1); grep -c '^  ok    95 finding(s)' <<< "$o"` → `1`

**Sensor durável:** a catraca já existe — `tests/health-baseline.txt` passa a dizer
`todo-findings 95` e o `sdd health` reprova nos dois sentidos.

**Reversível por:** reverter o commit; itens e catraca voltam juntos.

⚠️ **Este incremento é o ÚLTIMO, e depois dele roda o `sdd health`.** `tests/health-baseline.txt`
está dentro da chave do carimbo de mutação: mexer nele invalida o carimbo, e o `gate_PR` exige o
carimbo. Errar a ordem custa 20 a 50 minutos.

## Riscos e não-feitos

| Risco | Probabilidade | Mitigação |
|---|---|---|
| I1 remove linhas de um arquivo do humano fora do repo | alta (é o desenho) | `.bak` datado ao lado antes de qualquer remoção; a pendência 3 do `00-missao.md` pede a decisão humana antes do EXEC |
| O probe de I1 não fica vermelho antes da guarda | média | Jidoka: pare a linha e escreva **qual mundo** não conseguiu construir. Nunca conclua que ele não existe — a contaminação está medida |
| I5 vira `sufficient: false` sobre a fatia real e trava o próximo kaizen | baixa (`harness` tem 1 valor) | Check explícito: re-rodar `sdd kaizen --series` depois de I5 e exigir que `latest.guard.sufficient` continue `true` |
| I3 faz o número do laço de revisão subir e parecer regressão | alta | É o conserto. Registrar antes/depois no `KAIZEN_LOG` (I6) e no corpo do PR |
| A catraca do backlog mata o carimbo de mutação | alta se a ordem errar | I6 é o último; `sdd health` só depois dele. Escrito no incremento e aqui |
| Achado novo durante a missão reabre a catraca depois do carimbo | média | Achado novo vai para o `TODO.md` **antes** do `sdd health`, e a métrica de I6 sobe de 95 para 95+N no mesmo diff |
| O lote (9 itens + faxina) estourar `BUDGET_MISSION_USD` | média-alta | É a pendência 1 do `00-missao.md`. Se estourar, a escalada `budget-exhausted` é a porta correta: I1–I5 são independentes depois de I1, e I6 pode virar missão própria |
| Ancorar por número de linha e mexer no sítio errado | média | Medido que as âncoras derivaram; o plano manda localizar por `grep -n` do identificador em **todo** incremento |

## Verificação end-to-end

Com todos os incrementos `done`, as três métricas do `00-missao.md`, na ordem:

```bash
# 1. o ledger real está limpo e protegido
grep -c '"repo":"/tmp' ~/.sdd/autonomy-log.jsonl          # → 0

# 2. o backlog encolheu num diff com autor, e a catraca sabe
o=$(bash tests/check-todo.sh 2>&1); grep -c '^  ok    95 finding(s)' <<< "$o"   # → 1
grep -n 'todo-findings' tests/health-baseline.txt                                # → todo-findings 95

# 3. a suíte inteira, e a série continua respondendo sobre a fatia real
bash tests/run-all.sh                                      # → verde, score: N caught of N
./bin/sdd kaizen --series | jq '.latest.guard.sufficient'  # → true (a fatia real tem 1 harness)
```

E, por último — **depois do último commit que toca `bin/ tests/ templates/ config/`**:

```bash
./bin/sdd health          # → carimbo do catálogo de mutação escrito, todos os mutantes pegos
```

O `gate_PR` exige esse carimbo. Rodar antes do último commit de código é o erro que custa 20 a 50
minutos, e ele está escrito em I6 pela terceira vez de propósito.
