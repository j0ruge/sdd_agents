---
missao: 20260831-a-rodada-que-andou
fase: EXEC
status: done
sessao: 3bad3c60-be1d-4f7c-9266-f52c7ee7c4ca
data: 2026-08-31 12:10
gate: "tests/run-all.sh → `suite green`, 826 asserções ok, 0 FAIL (13 sensores; check-mutation.sh é opt-in desde 4c86712). Checkpoint: 4 de 4 incrementos `done`, cada um com hash presente no git log — 99f65bf, 60d2c88, c7c2e2e, 715da79."
---

# Handoff — EXEC — A rodada que andou

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

O ledger passou a saber, para REVIEW e para a fase que fecha de graça, o que já sabia para o EXEC:
se a **rodada andou** e se a **fase fechou**. Quatro incrementos, quatro commits, suíte verde em
826 asserções e 15 mutantes novos no catálogo. A mudança é **aditiva** — nenhuma linha do ledger
foi reescrita — e por isso o número medido não é o que o plano previu: `bf001fe` fica inalterada
**por mérito**, e quem se move são `d89ea43`, `e9a3681` e `353b4b1`. A QA é a próxima fase e o
diff **não tem nada visível ao usuário**: é um script bash sem interface.

## Estado do repo

- **Branch:** `feat/a-rodada-que-andou` — 6 commits à frente de `main` (`bf001fe`); nunca empurrada,
  sem `origin/feat/a-rodada-que-andou`.
- **Último commit:** `715da79` `feat(ledger): a fase que fechou sem gastar sessão para de ler refez`
  (mais o commit de checkpoint/handoff que fecha esta fase).
- **Working tree:** limpo depois do commit do checkpoint.
- **Suíte:** `tests/run-all.sh` → **verde**, 826 asserções `ok`, 0 `FAIL`, ~100 s.
- **E2E:** `E2E_CMD=""` no `.sdd/config.sh` — este repo é um script bash e seis markdowns, não tem
  interface nem app. Não rodou porque não existe.

## O que foi feito

- `99f65bf` — **I1.** A linha de sessão de REVIEW carrega `rounds_before`, `rounds_after` e
  `rounds_max`. A foto é tirada em `cmd_run` **e** em `cmd_retry` antes do `run_phase`, e
  deliberadamente **fora** da guarda `[ -z "$force_phase" ]`: `sdd run --phase REVIEW` é o caminho
  em que a rodada mais interessa. `rounds_after`/`rounds_max` são publicados pelo `gate_REVIEW` no
  **resolve** do arquivo, não na aprovação — assimetria deliberada com o `pending_after` do EXEC,
  porque o `N` de `40-review-r<N>.md` é estrutural e ninguém o auto-declara.
- `60d2c88` — **I2.** `def outcome` ganhou o terceiro braço: uma rodada de REVIEW que subiu lê
  `advanced` mesmo com o gate reprovando. Uma definição só (`ledger_outcome_defs`), os dois
  consumidores herdam. Guarda de não-nulo em `rounds_before`; a segunda guarda foi **removida com
  prova** (em jq 1.7 `null > 2` é falso, ao contrário do `null < 2` do braço do EXEC).
- `c7c2e2e` — **I3.** `def historic_rounds`, o caminho **datado** que recupera a rodada do
  `gate_why` que a linha já carrega verbatim, para as 24 de 25 linhas de REVIEW anteriores ao
  esquema. A linha anotada leva `rounds_source: "gate_why"` e o `cmd_autonomy` **imprime quantas
  alcançou** — que é o sinal de apagamento desta `def`.
- `7a34766` — de lambuja, fechou um item do `TODO.md`: a frase de divulgação passou a contar sobre
  `is_session and comparable`. Medido no ledger real, a do EXEC caiu de 53 para 51.
- `715da79` — **I4.** O runner **grava o fato** de que uma fase fechou sem gastar sessão
  (`event: "gate_pass"`), e a cláusula 3 do `phase_label` passa a ler "a fase fechou?" em vez de "a
  última sessão passou?". Os dois leitores e o `docs/pipeline.md` no mesmo commit — o enum de
  `event` é documentado como fechado, então valor novo é mudança de contrato.

## Artefatos

| Arquivo | O que contém |
|---|---|
| `docs/handoffs/20260831-a-rodada-que-andou/checkpoint.md` | 4 de 4 `done` com hash; **as notas de execução são a parte cara** — 18 linhas de sabotagem medida, três regras removidas com prova, uma declarada sem probe |
| `docs/handoffs/20260831-a-rodada-que-andou/00-missao.md` | A métrica (1) **reescrita em 2026-08-31** pela decisão humana do ponto de corte — não re-litigar |
| `bin/sdd` | `autonomy_gate_pass_row`, `gate_pass_rows`, o braço da rodada em `ledger_outcome_defs`, `historic_rounds`, e o `is_gate_pass` de cada um dos dois programas jq |
| `docs/pipeline.md` | § "The autonomy ledger": três formas de linha (era duas), o enum de `event` com `gate_pass`, e o quinto balde da aritmética do leitor humano |
| `tests/check-autonomy.sh` | O mundo do escritor: uma corrida real de 4 voltas `QA→EXEC→REVIEW→DOCS` |
| `tests/check-kaizen.sh` | A asserção **diferencial** do I4: duas fatias comparadas campo a campo, só `labels` podendo diferir |
| `tests/check-mutation.sh` | 15 mutantes novos na missão, 5 deles do I4 |

## Boot da próxima fase

A QA é a próxima. **Leia primeiro** este handoff e depois o `checkpoint.md` (notas de execução).

**O que no diff é visível ao usuário: nada de interface.** Este repo não tem app, não tem browser,
não tem `APP_URL` e não tem `E2E_CMD` — é `bin/sdd` (bash), `agents/*.md` e `templates/`. O
`gate_QA` já sabe disso: com `E2E_CMD` e `APP_URL` vazios ele pede o campo `gate:` do
`30-handoff-qa.md` carregando a evidência da jornada percorrida, e **não** o relatório datado das
skills `qa-report`/`qa-execution` (que nunca rodaram aqui). Não invente uma árvore `docs/qa/`.

**As jornadas tocadas são de linha de comando**, e são estas quatro:

```bash
./bin/sdd autonomy --all-repos          # a janela humana: a tabela por kit_sha + o parágrafo de contabilidade
./bin/sdd autonomy --by-mission         # a mesma população por missão
./bin/sdd kaizen --series               # a série determinística que o juiz lê
./bin/sdd status 20260831-a-rodada-que-andou
```

**Como subir o ambiente:** não há. `TEST_CMD="tests/run-all.sh"` roda em ~100 s e é tudo o que
existe de suíte. O comando caro é `./bin/sdd health --with-mutation` (~20–30 min, roda o catálogo
inteiro numa sandbox); a QA **não precisa dele** — quem o exige é o `gate_PR`.

**Três coisas que a QA deve olhar com olho crítico, porque são onde a mudança pode mentir:**

1. **A frase nova do leitor humano.** `sdd autonomy --all-repos` hoje imprime três linhas de
   divulgação; uma quarta (`N gate(s) closed without a session`) aparece assim que a primeira linha
   `gate_pass` existir. No ledger real de hoje há **0** delas, então a frase não sai — isso é o
   esperado, não uma falha.
2. **A aritmética dos cinco baldes.** A soma "sessões comparáveis + não-comparáveis + escalações +
   fechamentos + não-reconhecidas = total do cabeçalho" é o que impede uma linha de sumir em
   silêncio. `assert_bucket_sum` a fecha na suíte; olhar a saída real a confirma.
3. **`excluded.unrecognized` na série.** Tem de ser `0`. Se subir, é o próprio kit se acusando —
   e foi exatamente o defeito medido (e consertado) durante o I4.

## Pendências / Decisions for a Human

- **`KAIZEN_LOG.md` ainda não tem a entrada desta missão** — é da fase DOCS, não desta. O número
  medido que ela precisa está pronto e está aqui e no `checkpoint.md`: as três fatias `d89ea43`,
  `e9a3681` e `353b4b1` saíram de `0 advanced · 1 churned · 100% waste` para
  `1 advanced · 0 churned · 0% waste`, com `bf001fe` inalterada. Sem número medido não é kaizen.
- **A régua mudou no meio da janela de medição, de propósito.** Quem citar os números da janela 2
  depois desta missão tem de dizer com qual `bin/sdd` os leu. O aviso já está escrito no
  `05-verdict.md` desta missão. Decisão já tomada (grill de 2026-08-31, decisão 1) — está aqui
  como lembrete, não como pergunta aberta.
- **O destino do alvo "suíte < 30 s" da D7** (subir o alvo × aposentá-lo) ficou para a triagem do
  próximo `sdd kaizen`, com o número na mesa: 15 mutantes novos nesta missão. A suíte rápida segue
  em ~100 s; o catálogo é que cresceu.

## Riscos e não-feitos

- **O carimbo de mutação é invalidado por tudo que esta missão tocou** (`bin/`, `tests/`). O
  `./bin/sdd health --with-mutation` foi disparado **depois** do commit `715da79` — que é o último
  commit de código desta fase — e o resultado está registrado abaixo. ⚠️ Qualquer commit posterior
  em `bin/ tests/ templates/ config/` mata o carimbo e obriga a rodar de novo (20–50 min). O
  `checkpoint.md`, este handoff, `docs/` e `KAIZEN_LOG.md` **não** invalidam; o
  `tests/health-baseline.txt` **invalida** — então registrar achado no `TODO.md` mata o carimbo.
- **Uma regra ficou sem probe, e está declarada no código, não escondida.** O teste
  `sessions[$ph] > 0` do `gate_pass_rows` é redundante hoje (`gate_failed` só é escrito nos dois
  sítios que incrementam `sessions`) e sobrevive à sabotagem. Fica porque decide qual falha o
  próximo escritor de `gate_failed` produz. O comentário diz **qual mundo não consegui construir**,
  nunca que ele não existe — a distinção que este repo pagou em `d4deb35` e teve de desfazer em
  `7cbc8e2`.
- **Limite declarado do I4, e ele é real:** a fase cuja sessão foi paga na corrida *N* e cujo gate
  fecha de graça na corrida *N+1* **não** gera linha (`sessions` morre com o processo). O `refez`
  dela se corrige na primeira corrida em que o padrão inteiro acontece de uma vez. A alternativa
  (gravar em toda derivação) despejava até seis linhas por volta num ledger append-only.
- **Duas das oito recusas do `gate_REVIEW` não são recuperáveis pelo caminho datado** — `TEST_CMD
  failed` e `working tree dirty after the review` não nomeiam arquivo nenhum. 24 de 25 linhas reais
  alcançadas; a que sobra fica onde estava, em vez de ser adivinhada.
- **Não foi feito, e é escopo declarado:** cortar o custo do REVIEW (41% do gasto da janela 2). Esta
  missão torna o número honesto; ela não o reduz. A missão de corte vem depois, pelo mesmo argumento
  que fez `20260828-instrumento-honesto` vir antes de qualquer decisão sobre o EXEC.
- **Também não foi feita:** a faxina D15 do `TODO.md`. Os três itens triados têm destino nomeado em
  `01-plano.md` § "Triagem D15" e **não** foram executados aqui — mexer neles moveria
  `tests/health-baseline.txt` e mataria o carimbo de mutação no meio da fase.

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

**Nenhum registrado nesta fase, e a ausência é deliberada.** O repo desta missão **é** o kit, então
um achado iria para o `TODO.md` daqui — e o `TODO.md` mora dentro da chave do carimbo de mutação
através de `tests/health-baseline.txt`. Registrar durante o EXEC mataria o carimbo e compraria 20 a
50 min de catálogo. Duas dívidas encontradas de passagem foram, por isso, escritas onde a régua D15
manda escrevê-las — no **cabeçalho do próprio sensor**, como limite declarado, e não no backlog:

- a redundância medida do teste `sessions[$ph] > 0` (`bin/sdd`, comentário de `gate_pass_rows`);
- a recusa do sexto mutante de `gate_pass` por sabotar o `jq` em vez da regra
  (`tests/check-mutation.sh`, cabeçalho de `mut_LEDGER_gate_pass_not_admitted`).
