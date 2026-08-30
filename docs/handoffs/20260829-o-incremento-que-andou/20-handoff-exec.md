---
missao: 20260829-o-incremento-que-andou
fase: EXEC
status: done
sessao: a34d8542-be5e-4220-a37c-038d7f30717e
data: 2026-08-30 05:20
gate: "**Suíte:** `o=$(bash tests/run-all.sh 2>&1)` → rc **0**, `suite green`, **694** asserções (`grep -c '^  ok    '`, quatro espaços — a âncora que o `CLAUDE.md` nomeia), **0** FAIL (`grep -c '^  FAIL'`). ⚠️ O número reconcilia com os handoffs anteriores: 666 em `ebe9702` → 692 no HEAD de I5 (`60f0ee7`) → **694** com o sensor do `F1` verde. Sensores tocados: `check-autonomy.sh` rc 0, 246 → **248** `ok`; `check-kaizen.sh` rc 0, **146** `ok` (inalterado — o `F1` não toca o juiz); `check-lang.sh` rc **0**, que é o que autoriza o slug `20260825-cif-forma-pagamento` citado em `tests/check-mutation.sh` e em `docs/pipeline.md`, dois arquivos de superfície inglesa (conferido antes de escrever, nunca suposto). **Check do `F1`, verbatim da célula:** `grep -c '^  ok    a blocked increment publishes no pending_after'` → `1`; `grep -c '^  ok    and the refusal that produced it is the Jidoka one'` → `1`; e o re-walk `case` sobre `./bin/sdd autonomy --all-repos --by-mission` → **`walk-ok`** (`runner-sem-dividas  15 session(s) · 14 advanced · 1 churned`, o alvo exato da métrica 2, intacto depois do conserto). **Mutante novo provado pelo caminho EXATO do harness** (sandbox do `run_mutant` reproduzida à mão: `bin tests templates config agents` + `CLAUDE.md` + `TODO.md` + `docs/adr`, mutação aplicada pela função do catálogo extraída por `sed`, `cmp` ⇒ aplicou, `bash -n` verde, `SDD_MUTANT=1 run-all.sh`): rc **1** com **uma** única FAIL, `a blocked increment publishes no pending_after`, `expected: 2 null null / got: 2 1 2` — a testemunha Jidoka verde ao lado. Catálogo `grep -cE '^mut_[A-Za-z0-9_]+\\(\\) \\{'` → **193** (era 192). **6 de 6 incrementos `done`** com hash no `git log`. ⚠️ Carimbo de mutação **inválido** (I1–I4 e o `F1` mudaram `bin/` e `tests/`); quem re-emite é o `sdd health` da fase PR."
---

# Handoff — EXEC — o incremento que andou

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

Os 6 incrementos estão `done` (5 do plano + o `F1` da QA). O runner escreve na linha EXEC do ledger
quantos incrementos faltavam **antes** e **depois** da sessão, e os dois leitores chamam `advanced`
a sessão que fez o incremento andar — não só aquela cujo gate passou. As 53 linhas EXEC anteriores
ao esquema recuperam o mesmo fato do `gate_why`, por caminho datado e **contado na tela**. O juiz lê
`outcome` no rótulo e no `advance_rate`. O `F1` fechou a regressão que a QA achou: **bloquear um
incremento não é fechá-lo**. Suíte verde, 694 `ok`; catálogo 179 → **193** mutantes. Próxima fase:
**REVIEW**.

## Estado do repo

- **Branch:** `feat/o-incremento-que-andou` — 12 commits à frente de `origin/feat/o-incremento-que-andou`, 14 à frente de `main`. **Não foi feito push** (não é desta fase).
- **Último commit de código:** `99da6d8` `fix(gate): bloquear um incremento não é fechá-lo, e o ledger volta a dizer isso`
- **Working tree:** limpo depois do commit do `F1` (medido: `git status --short` vazio antes de escrever este handoff).
- **Suíte:** `tests/run-all.sh` → **verde**, rc 0, **694** asserções `ok`, 0 FAIL. ⚠️ Ela estava **vermelha de propósito** entre `14c6f08` (a QA commitou o sensor do achado) e `99da6d8` — 1 FAIL, o Red do `F1`. Essa janela acabou.
- **E2E:** `E2E_CMD=""` — não existe e não rodou. O kit não tem interface; a jornada é linha de comando.

## O que foi feito

- `4571faf` — **I1**: `checkpoint_tally()` (helper puro sobre `checkpoint_rows`) vira a **única** contagem de status do runner; `gate_EXEC` publica `GATE_EXEC_PENDING`/`GATE_EXEC_TOTAL` **depois** da validação; `autonomy_session_row` ganha os três campos; `cmd_run` (2 portas) e `cmd_retry` fotografam o "antes" **antes** do `run_phase`, porque depois da sessão a pergunta é irrespondível.
- `1fbb726` — chore: checkpoint do I1 (3 mutantes em vez de 2 — a guarda de fase é código novo com modo de falha real).
- `4a33f78` — **I2**: `def outcome:` ganha o braço `pending_after < pending_before` **com guarda de não-nulo**; texto de uso do `sdd autonomy` atualizado; `mut_AUTONOMY_outcome_reads_moved_only` re-ancorado.
- `adc2a56` — chore: checkpoint do I2 (a guarda de null que o plano não previa: `jq` ordena `null` abaixo de todo número).
- `7615536` — **I3**: `def historic_progress:` — as linhas EXEC sem os campos recuperam `N of M` do `gate_why`, anotadas com `progress_source: "gate_why"`; aplicado uma vez em cada leitor, logo após o filtro de repo; `cmd_autonomy` imprime quantas leu.
- `b715dea` — chore: checkpoint do I3 (o fixture que a sabotagem reprovou por apontar para a regra certa pelo motivo errado).
- `7cc0210` — **I4**: `phase_label` passa a `(.auto_retry == true or outcome != "advanced")`; `advance_rate` conta `advanced`; `agents/sdd-kaizen.md` atualizado; `mut_KAIZEN_churn_reads_ok` re-ancorado.
- `e97d96b` — chore: checkpoint do I4 (os dois fail-open da rubrica que a sabotagem achou).
- `3d697c6` — **I5**: `docs/pipeline.md`, `agents/sdd-kaizen.md` (+ espelho por `sdd install --force`), `CONTEXT.md` (verbete Churn + D16) e `KAIZEN_LOG.md` com antes/depois **medido**.
- `60f0ee7` — chore: checkpoint do I5 e a primeira versão deste handoff.
- `14c6f08` — **QA**: o sensor do achado, commitado **vermelho** (`tests/check-autonomy.sh`, bloco `== a blocked increment publishes no count ==`), a linha `F1` no checkpoint e o `30-handoff-qa.md`.
- `99da6d8` — **F1**: a recusa Jidoka do `gate_EXEC` passa a vir **antes** da publicação de `GATE_EXEC_PENDING`/`GATE_EXEC_TOTAL`; mutante `EXEC_blocked_publishes_count` (192 → 193); a célula `pending_after` de `docs/pipeline.md` passa a nomear **as duas** recusas.

## O `F1`, por extenso

`checkpoint_tally` conta `pending|doing` e arquiva `blocked` num balde próprio. Com a publicação
acima da recusa Jidoka, **desistir** de um incremento baixava `pending` exatamente como
**terminá-lo**: a única sessão do pipeline que *parou a linha* saía do ledger com
`pending_before 2 · pending_after 1` e era lida `advanced`, a `0% waste`. Fail-open na direção da
lisonja — mesma família da guarda de null do I2, e o modo de falha que esta missão inteira existe
para impedir.

O conserto é de **ordem**, e não de regra nova: `pending_after` é **veredito**, e um gate que vai
recusar não tem veredito a dar sobre o quanto a missão andou. `pending_before` fica onde estava —
é **fotografia**, tirada pelo `cmd_run` antes de a sessão abrir, e é ela que impede a asserção de
passar sobre um ledger vazio. Nenhuma asserção vizinha mudou de lado (`an EXEC row carries…` segue
`2 1 2`; `a done without commit…` segue `2 null null`; `the EXEC row that closed the last increment
says so` segue `EXEC pass 1 0 1`).

## Artefatos

| Arquivo | O que contém |
|---|---|
| `docs/handoffs/20260829-o-incremento-que-andou/checkpoint.md` | 6 incrementos `done` com hash, e as notas de execução — é onde moram as lições de sabotagem de cada sessão |
| `docs/handoffs/20260829-o-incremento-que-andou/30-handoff-qa.md` | as 4 jornadas de CLI andadas e o achado que virou o `F1` |
| `KAIZEN_LOG.md` (entrada de 2026-08-29) | a tabela antes/depois medida, os mutantes novos e o § "o que ISTO NÃO PROVA" |
| `CONTEXT.md` | verbete **Churn** e decisão **D16** re-escritos |
| `docs/pipeline.md` | tabela de campos do ledger (`pending_before`/`pending_after`/`increments_total`, `moved`) e a rubrica do juiz |
| `agents/sdd-kaizen.md` + `.claude/agents/sdd-kaizen.md` | o aviso ao juiz de que a régua mudou duas vezes em dois dias |

## Boot da próxima fase

**A próxima fase é REVIEW** — a QA já rodou (`30-handoff-qa.md`, `status: done`) e o `F1` que ela
escreveu está `done`. Não há incremento `pending`.

**Ler primeiro:** `00-missao.md` § Métrica, este handoff, `30-handoff-qa.md` § "Boot da próxima
fase" (a seção "Para o `sdd-reviewer`" tem 4 itens que a QA deixou de propósito), depois
`docs/pipeline.md` § "The autonomy ledger".

**O que é visível para o usuário** — não há interface; a mudança inteira é a saída de dois comandos
de CLI:

```bash
./bin/sdd autonomy --all-repos --by-mission | grep -E 'runner-sem-dividas|incremento-que-andou'
./bin/sdd autonomy --all-repos | grep 'read their progress from gate_why'
./bin/sdd autonomy --all-repos | grep -cE '^  [0-9a-f]{7}  .* 100% waste '   # 10  (era 49)
./bin/sdd kaizen --series | jq -c '.latest | {kit_sha, outcomes, advance_rate, labels}'
```

**Como subir o ambiente:** não há ambiente a subir. `APP_URL` vazio, `E2E_CMD` vazio. Basta o
checkout na branch e `tests/run-all.sh` (~3,5 min).

**⚠️ Três armadilhas que já custaram sessão nesta missão** e que o REVIEW herda:

- **Nunca copiar a definição de `outcome` para dentro de um `jq` de verificação.** Ela é UMA
  definição costurada nos dois leitores; a cópia envelhece e passa a medir outra coisa. Extraia:
  `defs="$(sed -n '/^ledger_outcome_defs() {/,/^}/p' bin/sdd | grep "^  printf" | sed "s/^  printf '%s' '//; s/'\$//")"`.
- **A guarda do caminho histórico é `.pending_before == null`, nunca `has("pending_before")`.**
  `autonomy_session_row` monta o objeto com `tonumber? // null`, então a **chave existe em toda
  linha** — `has(...)` responde `true` para as 53 linhas antigas e não anotaria nenhuma.
- **Conte a suíte com a âncora de QUATRO espaços** (`grep -c '^  ok    '` → 694). A de dois espaços
  responde 773 porque casa linhas de prosa aninhada, e foi o que quase fez este handoff publicar um
  número 80 acima do que os handoffs anteriores dizem. É a mesma régua do `44 caught of 44` do
  `CLAUDE.md`: conte a propriedade, não a palavra.

## Pendências / Decisions for a Human

- **Nenhuma que bloqueie.** As duas do `00-missao.md` § Pendências foram fechadas por medição: (a)
  o `churned` que sobra em `runner-sem-dividas` é **1** e as versões a `100% waste` são **10**, e o
  `KAIZEN_LOG` cita o medido e não o alvo; (b) a semente da missão seguinte (custo do REVIEW) segue
  desenhada em `01-plano.md` § "Próxima missão", com o comando de re-medição — ela nasce de um grill
  com o humano, **não** de `sdd kaizen`.

## Riscos e não-feitos

- **⚠️ CORREÇÃO da versão anterior deste handoff, apontada pela QA.** A versão de `60f0ee7` dizia
  que só a **primeira** linha EXEC desta missão no ledger carrega os três campos `null`. É falso:
  as **cinco** carregam. Medido agora,
  `jq -rs 'map(select(.mission=="20260829-o-incremento-que-andou" and .phase=="EXEC")) | .[] | "\(.pending_before) \(.pending_after) \(.increments_total)"' ~/.sdd/autonomy-log.jsonl`
  → `null null null` cinco vezes. O motivo **não é defeito**: o `sdd run` inteiro correu num
  processo carregado antes da edição do I1, e a última linha `{ main "$@"; exit $?; }` impede o bash
  de reler o arquivo. Quem prova o escritor é a asserção e2e (`an EXEC row carries…`, com `sdd run`
  de verdade) e o `sdd retry` que a QA re-caminhou. A linha desta sessão do `F1`, escrita por um
  `sdd run` novo, deve ser a primeira da missão a sair preenchida — mas ela só nasce **depois** do
  gate, então isto é expectativa declarada e não medição.
- **Só o lado do ESCRITOR foi sondado no `F1`** (herdado do § Riscos da QA, e a decisão não mudou).
  A asserção pede que o `gate_EXEC` não publique; ela **não** prova o que o leitor faria com um par
  `2 / 1` fabricado à mão, porque esse par não pode mais nascer. Blindar o leitor também daria dois
  donos para uma regra, o que este repo recusa em toda outra família.
- **A régua mudou pela segunda vez em dois dias.** Todo número de handoff anterior a 2026-08-29 é
  incomparável com número de hoje sem dizer que o instrumento mudou. Está escrito no
  `agents/sdd-kaizen.md`, no `CONTEXT.md` e no `KAIZEN_LOG.md`, mas nenhum sensor cobra. Limite
  declarado, não conserto.
- **A segunda metade da métrica 3 do `00-missao.md` não se confirmou** e isso está registrado como
  achado, não como falha: a fase EXEC de `frete-cif-fob` lê **`ok`** (7 sessões, todas `advanced`),
  e não `leve`. A linha que o planejador contou à mão como churn é a de `22:30` (`7→2/7`), em que o
  total havia crescido de 4 para 7 porque a QA escreveu incrementos de fix — a regra "`M` mudou ⇒
  compara com o `M` novo" a lê como o incremento de fix que ela é. A regra tem asserção e mutante
  (`mut_AUTONOMY_historic_total_change_blind`); a contagem à mão não tinha. O controle que a métrica
  queria continua de pé: **18 de 67** grupos de fase seguem com sessão não-`advanced` (⇒ `leve`).
- **O caminho histórico depende de o `gate_EXEC` nunca mudar a frase `N of M increment(s)`.** É
  **dado**, não contrato: mudar a frase quebraria a leitura das 53 linhas em silêncio, sem nenhum
  sensor vermelho. Declarado no cabeçalho de `ledger_outcome_defs`; o caminho é apagável no dia em
  que a frase de contabilidade imprimir zero.
- **`pass/false` continua classificado `advanced` sem fixture próprio** — limite herdado de
  `20260828-instrumento-honesto`, não introduzido aqui.
- **A sessão que fecha o último incremento sobre uma suíte vermelha lê `advanced` pela contagem**
  enquanto a volta que ela compra lê `churned`. Declarado em `docs/pipeline.md` e no `CONTEXT.md`:
  o gate é o artefato da volta **seguinte**.
- **⚠️ Carimbo de mutação inválido**, e isso é esperado: I1–I4 e agora o `F1` mudaram `bin/` e
  `tests/`. O `gate_PR` **exige** o carimbo e quem o re-emite é `./bin/sdd health` (~15–20 min,
  **193** mutantes), rodado pelo `sdd-publisher`. ⚠️ Ele tem de rodar **depois do último commit de
  código**: `tests/health-baseline.txt` está dentro da chave, então **registrar achado novo no
  `TODO.md` mata o carimbo** e obriga a re-rodar.
- **O catálogo completo não foi rodado nesta fase** (opt-in desde `4c86712`; rodá-lo dentro de um
  gate já tornou uma fase insatisfazível). Os 14 mutantes novos foram provados um a um numa cópia
  antes de cada commit, e o do `F1` foi além — provado pelo **caminho exato do `run_mutant`**,
  sandbox e `SDD_MUTANT=1` incluídos. O `score: N caught of N` de ponta a ponta só sai do
  `sdd health`.

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
> - kit: <o quê> — <arquivo:linha do kit> — <por que importa>

**Este repo É o kit**, então achado de kit iria para o `TODO.md` daqui — e nenhum foi registrado,
por decisão medida e não por não ter havido nada a dizer:

- **Nada foi escrito no `TODO.md`.** `tests/health-baseline.txt` congela `todo-findings 77` e está
  **dentro** da chave do carimbo de mutação, então registrar achado agora mataria o carimbo antes
  da fase PR — a colisão que `01-plano.md` § Riscos já nomeia. As três coisas que mereceriam
  entrada, se alguém quiser transportá-las depois do merge, estão descritas por extenso em
  **Riscos e não-feitos** acima: (1) o `N of M` como dado e não contrato do caminho histórico;
  (2) a ausência de sensor para o aviso de "a régua mudou"; e (3) `pass/false` sem fixture. As três
  são **limites declarados no cabeçalho do código**, o que pela régua D15 (`CONTEXT.md`) as tira do
  backlog: nenhuma é fail-open — nenhum sensor afirma medir o que não mede — e nenhuma tem
  consumidor fora da suíte do próprio kit. O `F1` **não** entra aqui: é regressão da própria missão,
  achada dentro dela e fechada dentro dela.
</content>
</invoke>

**Dois achados de kit que a fase PR desta missão expôs, registrados pelo operador humano
(2026-08-30) e não pelo executor** — a mesma regra do carimbo os mantém fora do `TODO.md` até o
merge; quem transporta é o humano, com a catraca no mesmo diff:

- kit: **o `sdd-publisher` não consegue esperar o `sdd health` dentro de uma sessão headless** —
  `agents/sdd-publisher.md:31-39` — o agente iniciou o health "em background" e encerrou o turno
  "esperando a notificação"; em `claude -p` encerrar o turno encerra a sessão, e o health morreu
  com ela (US$ 1,46 por nada). A segunda sessão rodou o health em primeiro plano e levou **82 min**
  (US$ 2,73). É a classe do *"waiting for the suite"* de `4c86712`, agora na fase PR. Direção:
  o **runner** roda `sdd health` antes de abrir a sessão de PR quando o carimbo está inválido — é
  comando, não julgamento, e não cabe numa sessão paga.
- kit: **âncora morta de mutante só aparece no catálogo inteiro (15–20 min), mas detectá-la custa
  segundos** — `tests/check-mutation.sh:2647` — a guarda `cmp -s` (rc 90) só roda dentro do
  `sdd health`; aplicar os 195 `sed` numa cópia de `bin/sdd` e comparar não roda suíte nenhuma.
  Cinco mutantes desta missão apodreceram (I1 e REVIEW mexeram nas linhas ancoradas) e a REVIEW
  fechou Grade A sem ver — o carimbo pegou, ao preço de duas sessões de publisher. Direção: um
  passo do `run-all.sh` (ou do `gate_REVIEW`) que só prova que **cada mutante ainda aplica**.
