---
missao: 20260829-o-incremento-que-andou
fase: EXEC
status: done
sessao: 5e325a08-71e9-46d4-a97e-bbfe56e1c6db
data: 2026-08-30 03:10
gate: "`tests/run-all.sh` → `suite green`, rc 0, **692** asserções `ok`, **0** FAIL (era 666 em `ebe9702`). Sensores tocados: `check-autonomy.sh` rc 0, 223 → **246** `ok`; `check-kaizen.sh` rc 0, 143 → **146** `ok`; `check-lang.sh` rc 0 (mede o inglês de `docs/pipeline.md` e de `agents/sdd-kaizen.md`, os dois arquivos de superfície que o I5 tocou). Checks dos 5 incrementos, um por um: I1 `grep -c '^  ok    an EXEC row carries pending_before, pending_after and increments_total'` → `1`; I2 `'^  ok    a session that advanced its increment reads advanced, not churned'` → `1`; I3 `'^  ok    the historical path and the fields agree on one history'` → `1`; I4 `'^  ok    a designed loop reads ok, and advance_rate counts the increments that advanced'` → `1`; I5 `grep -l 'o-incremento-que-andou'` nos cinco arquivos → `5` e `diff -q agents/sdd-kaizen.md .claude/agents/sdd-kaizen.md` → `rc=0`. `./bin/sdd preflight` → `ok TEST_CMD ran green`, `ok 7 kit agent(s) checked` (é ele que compara `agents/` com o espelho `.claude/agents/`); o único `fail` era `working tree dirty`, medido ANTES do commit `3d697c6` e resolvido por ele. Efeito medido no ledger real, com a definição do próprio runner (`ledger_outcome_defs` extraída por `sed`, nunca uma cópia): sessões EXEC lidas `churned` **46 de 72 → 2 de 76**; versões a `100% waste` **49 de 107 → 10 de 111**; `sdd_agents/20260816-runner-sem-dividas` `5 advanced · 10 churned` → **`14 advanced · 1 churned`**, o alvo exato da métrica 2. ⚠️ Carimbo de mutação **inválido** (chave atual `d273cfac…` × carimbada `b097c5e3…`): I1–I4 mudaram `bin/` e `tests/`, e quem re-emite é o `sdd health` da fase PR."
---

# Handoff — EXEC — o incremento que andou

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

Os 5 incrementos estão `done`. O runner passa a escrever na linha EXEC do ledger quantos
incrementos faltavam **antes** e **depois** da sessão, e os dois leitores passam a chamar `advanced`
a sessão que fez o incremento andar — não só aquela cujo gate passou. As 53 linhas EXEC anteriores
ao esquema recuperam o mesmo fato do `gate_why`, por caminho datado e **contado na tela**. O juiz
lê `outcome` no rótulo e no `advance_rate`. Suíte verde, 692 `ok`; catálogo 179 → 192 mutantes.
QA começa por `docs/pipeline.md` § "The autonomy ledger" — a mudança é **toda** na saída de dois
comandos de CLI, não há interface.

## Estado do repo

- **Branch:** `feat/o-incremento-que-andou` — 9 commits à frente de `origin/feat/o-incremento-que-andou`, 11 à frente de `main`. **Não foi feito push** (não é desta fase).
- **Último commit:** `3d697c6` `docs(kaizen): o que o numero passou a significar, com antes e depois medidos`
- **Working tree:** limpo (medido depois do commit do I5; o `fail` do preflight citado no `gate:` foi tirado antes dele).
- **Suíte:** `tests/run-all.sh` → **verde**, rc 0, **692** asserções `ok`, 0 FAIL.
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

## Artefatos

| Arquivo | O que contém |
|---|---|
| `docs/handoffs/20260829-o-incremento-que-andou/checkpoint.md` | 5 incrementos `done` com hash, e **19 notas de execução** — é onde moram as lições de sabotagem de cada sessão |
| `KAIZEN_LOG.md` (entrada de 2026-08-29) | a tabela antes/depois medida, os 13 mutantes novos e o § "o que ISTO NÃO PROVA" |
| `CONTEXT.md` | verbete **Churn** e decisão **D16** re-escritos |
| `docs/pipeline.md` | tabela de campos do ledger (`pending_before`/`pending_after`/`increments_total`, `moved`) e a rubrica do juiz |
| `agents/sdd-kaizen.md` + `.claude/agents/sdd-kaizen.md` | o aviso ao juiz de que a régua mudou duas vezes em dois dias |

## Boot da próxima fase

**Ler primeiro:** `00-missao.md` § Métrica (é a lista de coisas a verificar), depois este handoff,
depois `docs/pipeline.md` § "The autonomy ledger" e a entrada de 2026-08-29 do `KAIZEN_LOG.md`.

**O que é visível para o usuário** — não há interface; **a mudança inteira é a saída de dois
comandos de CLI**, e é isso que a QA anda:

```bash
./bin/sdd autonomy --all-repos --by-mission | grep -E 'runner-sem-dividas|incremento-que-andou'
#   sdd_agents/20260816-runner-sem-dividas  15 session(s) · 14 advanced · 1 churned · 0 idle · …
#   sdd_agents/20260829-o-incremento-que-andou  4 session(s) · 4 advanced · 0 churned · 0 idle · …
./bin/sdd autonomy --all-repos | grep 'read their progress from gate_why'
#   (53 EXEC row(s) older than the pending fields read their progress from gate_why)
./bin/sdd autonomy --all-repos | grep -cE '^  [0-9a-f]{7}  .* 100% waste '   # 10  (era 49)
./bin/sdd autonomy                       # texto de uso e a tabela por versão, no repo do kit
./bin/sdd kaizen --series | jq -c '.latest | {kit_sha, outcomes, advance_rate, labels}'
```

**Como subir o ambiente:** não há ambiente a subir. `APP_URL` está vazio, `E2E_CMD` está vazio.
Basta o checkout na branch `feat/o-incremento-que-andou` e `tests/run-all.sh` (~3,5 min).

**Jornadas tocadas**, na ordem em que valem a pena ser andadas:

1. **`sdd autonomy` (janela humana)** — histograma por missão, tabela por versão, `waste`, e a
   frase nova de contabilidade do caminho histórico. É a jornada que mudou mais.
2. **`sdd kaizen --series` / `sdd kaizen` (juiz)** — `outcomes`, `advance_rate` e `labels`.
   ⚠️ No repo do kit o eixo degenera por construção (ADR 0003): `sufficient: false` e
   `degenerate_axis: true` são o **estado esperado**, não um bug a reportar.
3. **`sdd run` / `sdd retry` (escritor)** — toda linha EXEC nova carrega os três campos. A prova
   barata é a própria missão: `jq -rs 'map(select(.mission=="20260829-o-incremento-que-andou" and .phase=="EXEC")) | .[] | {pending_before, pending_after, increments_total}' ~/.sdd/autonomy-log.jsonl`.
   ⚠️ A **primeira** dessas linhas (a sessão do I1) tem os três `null` de propósito: ela foi escrita
   pelo runner carregado **antes** da edição do I1. Não é defeito; é o caminho histórico funcionando
   sobre a própria missão.
4. **`sdd preflight` / `sdd install`** — tocados só pelo espelho do agente do juiz.

**⚠️ Duas armadilhas que já custaram sessão nesta missão** e que a QA herda:

- **Nunca copiar a definição de `outcome` para dentro de um `jq` de verificação.** Ela é UMA
  definição costurada nos dois leitores; a cópia envelhece e passa a medir outra coisa. Extraia:
  `defs="$(sed -n '/^ledger_outcome_defs() {/,/^}/p' bin/sdd | grep "^  printf" | sed "s/^  printf '%s' '//; s/'\$//")"`.
- **A guarda do caminho histórico é `.pending_before == null`, nunca `has("pending_before")`.**
  `autonomy_session_row` monta o objeto com `tonumber? // null`, então a **chave existe em toda
  linha** — `has(...)` responde `true` para as 53 linhas antigas e não anotaria nenhuma.

## Pendências / Decisions for a Human

- **Nenhuma que bloqueie.** As duas do `00-missao.md` § Pendências foram fechadas por medição: (a)
  o `churned` que sobra em `runner-sem-dividas` é **1** e as versões a `100% waste` são **10 de
  111**, e o `KAIZEN_LOG` cita o medido e não o alvo; (b) a semente da missão seguinte (custo do
  REVIEW) segue desenhada em `01-plano.md` § "Próxima missão", com o comando de re-medição — ela
  nasce de um grill com o humano, **não** de `sdd kaizen`.

## Riscos e não-feitos

- **A régua mudou pela segunda vez em dois dias.** Todo número de handoff anterior a 2026-08-29 é
  incomparável com número de hoje sem dizer que o instrumento mudou. Está escrito no
  `agents/sdd-kaizen.md`, no `CONTEXT.md` e no `KAIZEN_LOG.md`, mas nenhum sensor cobra — o juiz
  pode continuar comparando maçã com laranja se ignorar o aviso. Limite declarado, não conserto.
- **A segunda metade da métrica 3 do `00-missao.md` não se confirmou** e isso está registrado como
  achado, não como falha: a fase EXEC de `frete-cif-fob` lê **`ok`** (7 sessões, todas `advanced`),
  e não `leve`. A linha que o planejador contou à mão como churn é a de `22:30` (`7→2/7`), em que o
  total havia crescido de 4 para 7 porque a QA escreveu incrementos de fix — a regra "`M` mudou ⇒
  compara com o `M` novo" a lê como o incremento de fix que ela é. A regra tem asserção e mutante
  (`mut_AUTONOMY_historic_total_change_blind`); a contagem à mão não tinha. O controle que a métrica
  queria continua de pé: **14 de 63** grupos de fase de repos reais seguem com sessão não-`advanced`
  (⇒ `leve`), dois deles EXEC (`cif-forma-pagamento`, `lote-facil`).
- **O caminho histórico depende de o `gate_EXEC` nunca mudar a frase `N of M increment(s)`.** É
  **dado**, não contrato: mudar a frase quebraria a leitura das 53 linhas em silêncio, sem nenhum
  sensor vermelho (as asserções usam fixtures próprios). Declarado no cabeçalho de
  `ledger_outcome_defs`; o caminho é apagável no dia em que a frase de contabilidade imprimir zero.
- **`pass/false` continua classificado `advanced` sem fixture próprio** — limite herdado de
  `20260828-instrumento-honesto`, não introduzido aqui.
- **A sessão que fecha o último incremento sobre uma suíte vermelha lê `advanced` pela contagem**
  enquanto a volta que ela compra lê `churned`. Declarado em `docs/pipeline.md` e no `CONTEXT.md`:
  o gate é o artefato da volta **seguinte**.
- **⚠️ Carimbo de mutação inválido**, e isso é esperado: chave atual `d273cfac…` contra a carimbada
  `b097c5e3…`, porque I1–I4 mudaram `bin/` e `tests/`. O `gate_PR` **exige** o carimbo e quem o
  re-emite é `./bin/sdd health` (~15–20 min, 192 mutantes), rodado pelo `sdd-publisher`. ⚠️ Ele tem
  de rodar **depois do último commit de código**: `tests/health-baseline.txt` está dentro da chave,
  então **registrar achado novo no `TODO.md` mata o carimbo** e obriga a re-rodar.
- **Não foi rodado o catálogo de mutação nesta fase** (é opt-in desde `4c86712`, e rodá-lo dentro de
  um gate já tornou uma fase insatisfazível). Os 13 mutantes novos foram provados **um a um numa
  cópia** antes de cada commit — aplica, `diff` mostra **uma** linha, `bash -n` verde, e o assassino
  nomeado fica vermelho —, mas o `score: N caught of N` de ponta a ponta só sai do `sdd health`.

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
  da fase PR — a colisão que `01-plano.md` § Riscos já nomeia ("achado vai para o handoff, o humano
  transporta"). As três coisas que mereceriam entrada, se alguém quiser transportá-las depois do
  merge, estão descritas por extenso em **Riscos e não-feitos** acima: (1) o `N of M` como dado e
  não contrato do caminho histórico; (2) a ausência de sensor para o aviso de "a régua mudou"; e
  (3) `pass/false` sem fixture. As três são **limites declarados no cabeçalho do código**, o que
  pela régua D15 (`CONTEXT.md`) as tira do backlog: nenhuma é fail-open — nenhum sensor afirma medir
  o que não mede — e nenhuma tem consumidor fora da suíte do próprio kit.
