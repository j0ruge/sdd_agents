---
missao: 20260911-o-juiz-nao-mente-sobre-a-janela
fase: EXEC
status: blocked
sessao: ad29a09e-616e-47f5-9f60-d02a9f9dd3c7
data: 2026-09-12 06:40
gate: "tests/run-all.sh → suite green (14 sensores, 0 FAIL) e os 6 hashes existem no git log; MAS ./bin/sdd health → RED: 'score: 286 caught, 0 known gap(s), of 289' + 'the catalogue ran 289 of the 293 mutant(s) tests/check-mutation.sh defines'. Sem carimbo de mutação (.sdd/logs/mutation-stamp ausente), logo gate_PR insatisfazível. I2, I4 e I5 marcados blocked."
---

# Handoff — EXEC — o juiz não mente sobre a janela

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

🛑 **A linha PAROU (Jidoka) e a EXEC não está `done`.** Os seis incrementos rodaram e a suíte
está verde, mas o `./bin/sdd health` que o plano manda rodar ao fim do I6 voltou **vermelho**:
três âncoras de mutante apodreceram (I2 e I4) e quatro mutantes do I5 nunca entraram no
`CATALOG=(`. Sem carimbo de mutação o `gate_PR` é insatisfazível, então **I2, I4 e I5 estão
`blocked`** no checkpoint e a próxima sessão de EXEC conserta — não é QA.
Nada precisa ser revertido: o código dos três incrementos está certo e verde; o que falta é o
**registro** deles no catálogo. Detalhe e direção na seção *Por que a linha parou*.

## Estado do repo

- **Branch:** `feat/o-juiz-nao-mente-sobre-a-janela` — local, **sem upstream** (nunca empurrada).
- **Último commit:** `19fec24` `chore(checkpoint): I6 done em 4d9b7b8 — catraca 105 → 95`
- **Working tree:** limpo.
- **Suíte:** `tests/run-all.sh` → **verde**, 14 sensores, 0 `FAIL`.
- **Catálogo de mutação:** `./bin/sdd health` → **VERMELHO**, 2 checks falhos.
  `score: 286 caught, 0 known gap(s), of 289` e
  `the catalogue ran 289 of the 293 mutant(s) tests/check-mutation.sh defines (floor 8)`.
  **Sem carimbo:** `.sdd/logs/mutation-stamp` não existe (o anterior era de 08/09 e foi invalidado).
- **E2E:** `E2E_CMD=""` no `.sdd/config.sh` — o kit não tem jornada de navegador; a "jornada" deste
  repo é a linha de comando, e é por ela que a QA tem de andar (ver boot abaixo).

## Por que a linha parou

O `TEST_CMD` está verde e todos os hashes existem, então o `gate_EXEC` passaria; o que reprova é o
sensor que o `gate_PR` lê. Os dois defeitos são de incrementos **anteriores** ao I6, e cada dono
foi provado por `git log -S`, não suposto:

**A — três âncoras de mutante apodrecidas pelo próprio conserto que elas guardavam.** O catálogo
reporta `CATALOGUE-BROKEN: <slug>` / *"the mutation did not apply — did the anchor change in
bin/sdd?"*, que **não** é o mesmo que `NOT caught`:

| Mutante | O `sed` procura | Quem moveu |
|---|---|---|
| `KAIZEN_composition_session_unit` | `composition: ($rows \| group_by(.repo // "")` | **I2**, `7e6b3f5` |
| `LEDGER_gate_pass_unrecognized` | `def is_unrecognized: (is_session or is_escalation or is_gate_pass) \| not;` | **I4**, `aa3c0a2` |
| `LEDGER_gate_pass_not_admitted` | `and (.event == "session" or is_escalation or is_gate_pass)` | **I4**, `aa3c0a2` |

Os dois do `LEDGER` quebraram porque o I4 ensinou o quarto evento aos dois leitores e a linha real
hoje é `… or is_gate_pass or is_close)`. É o achado nº 1 do `TODO.md` acontecendo ao vivo:
*"âncora morta de mutante só aparece no catálogo inteiro"*.

**B — quatro mutantes definidos e nunca registrados.** `grep -c '^mut_' tests/check-mutation.sh`
responde **293**; o `CATALOG=(` tem **289**. Os quatro que faltam são exatamente os do I5
(`5e3c427`): `mut_KAIZEN_guard_harness_blind`, `mut_KAIZEN_guard_why_silent`,
`mut_KAIZEN_window_break_blind`, `mut_KAIZEN_window_ignores_verdict`. O `score:` **não** reclama
sozinho — `caught == of` continua verdadeiro sobre a lista encolhida; quem pega é a asserção de
piso do `sdd health`, que compara o que **rodou** com o que está **definido**.

**A causa comum, e é ela que interessa mais que os sete sintomas:** o catálogo é opt-in desde
`4c86712`, então rodá-lo é dever do incremento — e I2, I4 e I5 acrescentaram 12 mutantes
verificando cada um numa sandbox à mão, sem nunca rodar o catálogo inteiro. Sandbox por mutante
responde *"este mutante morde"*; só a passada completa responde *"a lista ainda é a lista"* e
*"nenhuma âncora apodreceu"*. As duas perguntas são diferentes e três sessões seguidas fizeram só
a primeira.

**Direção para a próxima sessão de EXEC** (é EXEC, não QA — nada aqui é bug de usuário):

1. re-ancorar os três `sed` na forma que o `bin/sdd` tem hoje (`tests/check-mutation.sh:837`,
   `:3020`, `:3036`), confirmando com `grep` no `bin/sdd` antes e depois;
2. acrescentar os quatro nomes ao `CATALOG=(` (`tests/check-mutation.sh:3274`);
3. provar que cada um dos sete **morde** — e que o `sed` mudou o arquivo, senão a conclusão é vazia;
4. só então `./bin/sdd health` (**20–50 min**), que escreve o carimbo e reabre o `gate_PR`;
5. voltar I2, I4 e I5 para `done` no checkpoint, **depois** do carimbo.

## O que foi feito

- `5956e80` — **I1.** As 11 linhas de fixture (`"repo":"/tmp…`) saem do
  `~/.sdd/autonomy-log.jsonl` com backup, e o runner passa a recusar escrever o ledger real a
  partir de um checkout sob `$TMPDIR`. Sem isto, todo número medido por I2–I5 seria ruído.
- `7e6b3f5` + `d93b9bd` — **I2.** O `$order` do `cmd_autonomy` e o `comparable_row` do
  `kaizen_series` param de divergir sobre a linha `gate_pass`; a paridade virou asserção
  **diferencial** (as duas saídas comparadas entre si sobre o mesmo arquivo), nunca o comentário
  que antes jurava *"same spelling on purpose, in both programs"*.
- `392f526` + `47113c7` — **I3.** `reopened` e a fronteira do laço de revisão leem a população que
  prometem, em vez de depender de a fase ter custado dinheiro.
- `aa3c0a2` + `659acf0` — **I4.** `sdd close` e `sdd retry` escrevem a linha de ledger que devem.
  O quarto evento `event: "close"` entrou pela **definição** (`is_close` nos dois leitores) e pelo
  contrato em `docs/pipeline.md`, no mesmo commit; a asserção do `close` é diferencial porque o
  comando tem dois braços e só um compra sessão.
- `5e3c427` + `a5d99a0` — **I5.** A guarda do juiz recusa fatia com **duas versões de harness** e
  publica `window_broken` como **instrumento**, não como cláusula de `sufficient` — pôr a ruptura
  dentro de `sufficient` reprovaria o veredito já escrito, que é gate insatisfazível.
- `4d9b7b8` — **I6.** Dez itens que não são fail-open e não têm consumidor fora da suíte saem do
  `TODO.md` e viram limite declarado no cabeçalho do sensor dono (sete) ou adiamento com evento de
  reabertura no `CONTEXT.md` (três, Y1–Y3). Catraca `todo-findings 105 → 95`, entrada de
  antes/depois no `KAIZEN_LOG.md`.

## Artefatos

| Arquivo | O que contém |
|---|---|
| `docs/handoffs/20260911-o-juiz-nao-mente-sobre-a-janela/checkpoint.md` | A tabela: I1, I3 e I6 `done`; **I2, I4 e I5 `blocked`** com o hash real preservado |
| `docs/handoffs/20260911-o-juiz-nao-mente-sobre-a-janela/checkpoint-notas.md` | As notas de execução (append-only); as de I6 explicam o corte do décimo item |
| `docs/pipeline.md` | Contrato da **forma de linha** do ledger — quarto evento `close` — e da **forma da série** (`harness`, `window_broken`) |
| `CONTEXT.md` | Nova tabela **Decisões adiadas por YAGNI** (Y1–Y3), cada uma com o evento que a reabre |
| `KAIZEN_LOG.md` | Entrada de 2026-09-12: a régua D15 aplicada, 105 → 95 com a tabela item a item |
| `TODO.md` | 95 achados; a seção que se chamava "Adiados por YAGNI" foi renomeada porque ficou sem adiamentos |
| `tests/health-baseline.txt` | `todo-findings 95` — a catraca que morde nos dois sentidos |

## Boot da próxima fase

⚠️ **A próxima fase é EXEC de novo, não QA** — três linhas do checkpoint estão `blocked`, e a
tarefa dela são os 5 passos da seção *Por que a linha parou*. O que segue abaixo é o boot da **QA**,
escrito agora porque o diff já está pronto e não muda com o conserto do catálogo: quando as três
linhas voltarem a `done` e o carimbo existir, esta seção é o que a QA lê.

**O que é user-visible neste diff.** Nada de navegador: o produto é a CLI `bin/sdd` e os artefatos
que ela escreve. As superfícies que mudaram, e que é por onde a jornada anda:

1. **`sdd kaizen` / a série do juiz** — ganhou dois campos publicados. A guarda recusa a fatia com
   mais de uma versão de harness e a série carrega `window_broken`. Confirmado no recorte real da
   janela 4 (`head -280` do ledger): `sufficient: true`, `harness: ["2.1.263"]`,
   `window_broken: true` com 3 missões encalhadas.
   ⚠️ **Não rodar `sdd kaizen` de verdade nesta branch** — o piso é 3 e ele commita na branch
   corrente. Para exercitar, use um ledger de fixture, como os probes fazem.
2. **`sdd autonomy`** — `reopened`, a fronteira do laço de revisão e a admissão da série agora leem
   a mesma população. Compare `sdd autonomy --by-mission` com `--series` sobre o mesmo arquivo: a
   divergência que o I2 fechou aparecia exatamente aí.
3. **O ledger `~/.sdd/autonomy-log.jsonl`** — quarto evento `event: "close"`, e o arquivo real foi
   limpo de 11 linhas de fixture (backup ao lado). Toda view humana que conta linhas tem de
   escopar por `.event == "session"`; foi assim que dois probes vizinhos quebraram no I4.
4. **`sdd health`** — a catraca do backlog passou a 95.

**Por onde começar, concretamente:**

```bash
cd /home/joruge/repos/sdd_agents
git log --oneline main..HEAD          # os 10 commits da missão
tests/run-all.sh                      # ~45 s, tem de sair verde
bash tests/check-todo.sh              # ok 95 finding(s)
./bin/sdd autonomy --series           # a forma da série, com harness e window_broken
sed -n '/event/,/window_broken/p' docs/pipeline.md   # o contrato que a QA confere contra a saída
```

**Ambiente:** nenhum. Sem stack, sem `.env`, sem credencial — o kit é bash + markdown e a suíte é
hermética.

## Pendências / Decisions for a Human

- **O veredito `melhorou` sobre `a0e34df` foi escrito com o instrumento que esta missão consertou**
  (`05-verdict.md`, já no diretório da missão). Nada nesta missão o reescreve, de propósito: mudar
  a régua depois de conhecer o resultado é o modo de falha que o `KAIZEN_LOG.md` nomeia. Se o
  veredito deve ser **reemitido** com o instrumento novo, é decisão do humano, não do pipeline.
- **O alvo "<30 s" da D7 continua não atingido e sem dono.** Os dois itens de custo da suíte foram
  deliberadamente **mantidos** no `TODO.md` no I6: não são fail-open, mas são decisão humana
  pendente (subir o alvo ou aposentá-lo por escrito), e cabeçalho de sensor não é lugar de decisão
  de humano.

## Riscos e não-feitos

- **NÃO HÁ carimbo de mutação, e é por isso que a linha parou.** `tests/health-baseline.txt` está
  dentro da chave do carimbo e o I6 mexeu nele, então esta sessão rodou `./bin/sdd health` depois
  do último commit de código (`4d9b7b8`), na ordem certa — e ele voltou vermelho. O
  `.sdd/logs/mutation-stamp` não existe (fica fora do git, então não aparece no diff). Enquanto os
  sete mutantes da seção *Por que a linha parou* não forem consertados, **o `gate_PR` não tem como
  passar**: é gate insatisfazível, e o kit prefere parar a fingir.
  ⚠️ Depois do conserto: qualquer commit em `bin/ tests/ templates/ config/` invalida o carimbo de
  novo, e registrar achado no `TODO.md` também, porque o baseline está entre esses caminhos.
- **A EXEC volta a ser chamada, e a próxima fase NÃO é a QA.** Três linhas do checkpoint estão
  `blocked`; o `gate_EXEC` reprova antes de qualquer gate posterior ser lido, e o runner escala
  (`increment-blocked`, rc 3). Isso é o desenho funcionando, não um acidente.
- **Custou duas passadas de catálogo (≈100 min) para nomear três mutantes**, e a segunda foi
  evitável: `./bin/sdd health 2>&1 | tail -25` **come a lista** — os `fail` saem em stderr no meio
  da saída. Redirecione para arquivo e grepe `CATALOGUE-BROKEN|NOT caught`.
- ⚠️ **`pgrep -f check-mutation.sh` casa o próprio shell que espera** (o padrão está no argv do
  `zsh -c`), então `until ! pgrep -f …` nunca termina. Espere pelo **PID**.
- **Os quatro achados marcados `RESOLVIDO por` continuam no `TODO.md`** (I4 e I5, hashes `aa3c0a2` e
  `5e3c427`) e **contam** nos 95. Eles só se apagam depois que o PR que cita a evidência for
  mergeado, provado por `git merge-base --is-ancestor <hash> main` — nunca pelo rótulo do PR. Ou
  seja: a catraca vai cair de novo num chore pós-merge, e isso é o ciclo de vida, não um defeito.
- **Os mutantes novos foram verificados à mão, em sandbox, e não pelo `TEST_CMD`** — o catálogo é
  opt-in desde `4c86712`. Cada verificação checou primeiro que o `sed` MUDOU o arquivo
  (`diff -q` ⇒ `ANCHOR ROTTEN`), senão "sabotei e a suíte caiu" seria conclusão de sabotagem vazia.
  ⚠️ `tests/check-mutation.sh --list` **não é flag**: ele ignora e roda o catálogo inteiro.
  Para contar mutantes, `grep -c '^mut_' tests/check-mutation.sh`.
- **Um mutante foi recusado com argumento escrito, não esquecido.**
  `mut_KAIZEN_guard_harness_negative` trocava `($n == 0 or $n == 1)` por `($n > 1 | not)`, que
  sobre inteiros é a MESMA função — nenhum probe poderia matá-lo. O comentário declara **qual
  mundo não consegui construir**, em vez de afirmar que ele não existe.
- **Não verificado:** o comportamento das mudanças do ledger sobre um `~/.sdd/autonomy-log.jsonl`
  de OUTRA máquina, e a migração de uma missão iniciada antes do split de notas. As duas formas
  convivem por desenho.

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

**O repo desta missão É o kit**, então achado de kit entra no `TODO.md` deste próprio repositório —
que é exatamente o que o I6 acabou de encolher. Nenhum achado novo foi registrado nesta sessão, e a
abstenção é deliberada e tem preço medido: o `tests/health-baseline.txt` está dentro da chave do
carimbo de mutação, então registrar um achado depois do `sdd health` mata o carimbo que o
`gate_PR` exige. O que a sessão encontrou e não virou item novo:

- A seção `### Adiados por YAGNI` do `TODO.md` ficou sem nenhum adiamento e guarda hoje doze
  achados que missões recentes apendaram ao fim do arquivo sem classificar. → **consertado no
  próprio diff** (`4d9b7b8`): a seção foi renomeada dizendo o que é, com ponteiro para Y1–Y3 do
  `CONTEXT.md`. Não virou item porque não sobrou defeito.
- O item aberto *"Slug de missão em pt-BR não pode ser citado na superfície inglesa"* foi
  **reproduzido de graça** nesta sessão: citar `20260819-fecho-que-nao-mente` num comentário de
  `tests/check-health.sh` reprovou o `check-lang.sh` na linha escrita. → **já é um dos 95**, com a
  reprodução agora nas notas de execução do I6. Nenhum item novo.
