---
missao: 20260911-o-juiz-nao-mente-sobre-a-janela
fase: EXEC
status: done
sessao: ad29a09e-616e-47f5-9f60-d02a9f9dd3c7
data: 2026-09-12 05:10
gate: "tests/run-all.sh → suite green (14 sensores, 0 FAIL); checkpoint sem linha pending (I1–I6 done, hashes 5956e80 7e6b3f5 392f526 aa3c0a2 5e3c427 4d9b7b8, todas em git log); bash tests/check-todo.sh → 'ok 95 finding(s)'"
---

# Handoff — EXEC — o juiz não mente sobre a janela

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

Os seis incrementos fecharam: o ledger real está limpo e protegido contra fixture, os dois
programas que leem a janela concordam por asserção diferencial, `reopened`/fronteira do laço leem
a população que prometem, `sdd close` e `sdd retry` escrevem a linha que deviam, a guarda do juiz
recusa fatia com duas versões de harness e publica `window_broken`, e dez itens de dívida
declarada saíram do backlog para o cabeçalho do sensor dono (105 → 95).
A QA começa lendo **`docs/pipeline.md`**: o contrato de linha do ledger ganhou um quarto evento
(`close`) e a série ganhou dois campos publicados (`harness`, `window_broken`).

## Estado do repo

- **Branch:** `feat/o-juiz-nao-mente-sobre-a-janela` — local, **sem upstream** (nunca empurrada).
- **Último commit:** `19fec24` `chore(checkpoint): I6 done em 4d9b7b8 — catraca 105 → 95`
- **Working tree:** limpo.
- **Suíte:** `tests/run-all.sh` → **verde**, 14 sensores, 0 `FAIL`.
- **E2E:** `E2E_CMD=""` no `.sdd/config.sh` — o kit não tem jornada de navegador; a "jornada" deste
  repo é a linha de comando, e é por ela que a QA tem de andar (ver boot abaixo).

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
| `docs/handoffs/20260911-o-juiz-nao-mente-sobre-a-janela/checkpoint.md` | A tabela: I1–I6 `done`, com hash cada |
| `docs/handoffs/20260911-o-juiz-nao-mente-sobre-a-janela/checkpoint-notas.md` | As notas de execução (append-only); as de I6 explicam o corte do décimo item |
| `docs/pipeline.md` | Contrato da **forma de linha** do ledger — quarto evento `close` — e da **forma da série** (`harness`, `window_broken`) |
| `CONTEXT.md` | Nova tabela **Decisões adiadas por YAGNI** (Y1–Y3), cada uma com o evento que a reabre |
| `KAIZEN_LOG.md` | Entrada de 2026-09-12: a régua D15 aplicada, 105 → 95 com a tabela item a item |
| `TODO.md` | 95 achados; a seção que se chamava "Adiados por YAGNI" foi renomeada porque ficou sem adiamentos |
| `tests/health-baseline.txt` | `todo-findings 95` — a catraca que morde nos dois sentidos |

## Boot da próxima fase

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

- **O carimbo de mutação tem de existir antes do `gate_PR`.** `tests/health-baseline.txt` está
  dentro da chave do carimbo, e o I6 mexeu nele. Esta sessão disparou `./bin/sdd health` **depois**
  do último commit de código (`4d9b7b8`) — o carimbo mora em `.sdd/logs/mutation-stamp`, fora do
  git. ⚠️ **Qualquer commit novo em `bin/ tests/ templates/ config/` invalida o carimbo**, e
  registrar achado no `TODO.md` também, porque o baseline está entre esses caminhos. Se a QA ou a
  REVIEW tocarem qualquer um dos quatro, o `sdd health` roda de novo (20–50 min) antes do PR.
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
