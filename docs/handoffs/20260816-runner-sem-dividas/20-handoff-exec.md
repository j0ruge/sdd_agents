---
missao: 20260816-runner-sem-dividas
fase: EXEC
status: done
sessao: 4b71ea49-27b4-46ae-a43a-77b58d725c67
data: 2026-08-16 11:45
gate: "`bash tests/run-all.sh` → rc 0 · saída final `suite green` · `score: 37 caught, 0 known gap(s), of 37` (baseline da missão: 30) · 40,8 s medidos com `time` no default de `SDD_MUTATION_JOBS` (31,6 s na abertura do I2; o crescimento são os 7 mutantes novos, cada um uma suíte inteira, mais o lint de 11 arquivos que o I6 acrescentou). `shellcheck -S warning bin/sdd tests/*.sh` limpo. `./bin/sdd health` verde nos 5 checks: suíte, `mutation: score: 37 caught, 0 known gap(s), of 37`, `all 8 gates have a mutation in the catalogue`, `provenance: all 3 fixtures match the installed skills`, `ratchet: 6 known debt(s), none new`. `bash tests/check-todo.sh` → `47 finding(s), all within 8 lines and carrying anchor + date` + `selftest: 75 probe(s)`. Os 10 Checks do `checkpoint.md` batem com os commits `238497f`, `6c7b1df`, `86607f1`, `3ef23f4`, `fabd6c6`, `1bbacfb`, `f3eb013`, `2132cf5`, `4f98354` e `f4f859b`, **todos verificados ancestrais de HEAD** por `git merge-base --is-ancestor`. Métrica da missão: `grep -c 'Runner — defeitos e dívidas' TODO.md` → **0** — a seção não existe mais."
---

# Handoff — EXEC — a seção "Runner — defeitos e dívidas" do TODO.md é eliminada

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

> **Dez passagens pelo EXEC**, uma por incremento, todas nesta branch. Este handoff cobre as dez
> em resumo; **as lições caras estão linha a linha nas Notas de execução do `checkpoint.md`**, que
> é o documento a ler antes de tocar em qualquer coisa que esta missão mexeu. Não duplico aqui o
> que está lá.

## TL;DR

Os 11 itens da seção "Runner — defeitos e dívidas" foram fechados: 1 por obsolescência (hash
provado em `main`), 10 por conserto com sensor. A seção saiu do `TODO.md` — a métrica da missão.
Suíte verde, mutação **30/30 → 37/37**, `sdd health` verde nos 5 checks, lint agora cobrindo
`tests/`. Nenhum item foi devolvido ao TODO por corte de escopo. A QA começa por decidir se este
diff é visível ao usuário — ele é, em cinco pontos listados no "Boot da próxima fase".

## Estado do repo

- **Branch:** `missao/20260816-runner-sem-dividas` — nunca empurrada (`git push` é da fase PR)
- **Último commit:** `f4f859b` `feat(runner): a sessão de fase deixa de ser ponto cego enquanto roda`
  (mais o commit do checkpoint/handoff que fecha esta sessão)
- **Working tree:** limpo
- **Suíte:** `tests/run-all.sh` → **verde**, 40,8 s, mutação 37/37, 0 known gaps
- **E2E:** `E2E_CMD=""` — o kit não tem interface; não rodou por não existir

## O que foi feito

- `238497f` — **I1 · triagem por artefato.** Dos 11 itens só o do `gate_DOCS` já estava resolvido
  (`0f50fad`, ancestral de `main`, com sensor e mutação próprios): saiu sem conserto. Os outros 10
  foram re-verificados um a um contra o HEAD — **todos vivos**. Nenhum incremento virou no-op.
- `6c7b1df` — **I2 · `latest_matching` ordena por versão.** `sort` → `sort -V`; o runner lia
  literalmente `40-review-r3.md` num diretório com `r10`. Fixture `r1/r2/r3/r10` com **r10
  reprovado**, para que a ordem errada FALHE ABERTA em vez de só escolher outro arquivo.
- `86607f1` — **I3 · `sdd install` morre alto sem o `starter.conf`.** O dano real não era o rótulo
  `ok`: era o `.sdd/config.sh` de **0 byte** que sobrava, que o install seguinte reporta como
  `preserved` — o alvo ficava sem `TEST_CMD` para sempre.
- `3ef23f4` — **I4 · `bad_rows` sai; o comentário do slice para de prometer.** Código morto
  removido e três comentários que prometiam corte por caractere incondicional passaram a dizer a
  verdade (caractere sob locale multibyte, byte sob `C`/`POSIX`), com os números medidos.
- `fabd6c6` — **I5 · a família `printf | grep -q` sai da suíte**, e um sensor novo
  (`tests/check-pipefail.sh`, com 18 probes próprios) impede a volta. Regra por **cluster de
  flags**, não pelo token `-q`: `-qE`/`--quiet` reintroduziriam o defeito com uma letra a mais.
- `1bbacfb` — **I6 · o lint cobre `tests/`.** ~2400 linhas de suíte deixaram de ser terra de
  ninguém; piso de 12 caminhos e probe com um SC2318 real contra o linter virar decoração.
- `f3eb013` — **I7 · uma definição de comparabilidade** nos **três** leitores do ledger (o plano
  falava em dois; o terceiro estava inline no `kaizen_series`). Asserção **diferencial**: os dois
  leitores comparados entre si, não contra constante.
- `2132cf5` — **I8 · `guard.sufficient` conta missão com sessão comparável.** Três missões
  só-escalada davam `sufficient: true` com `sessions: 0` — o juiz autorizado a julgar sem dado.
- `4f98354` — **I9 · o giro REVIEW→PR→REVIEW pós-degradação acaba.** O dano era maior que o item
  dizia: o run escalava `budget-exhausted` na fase **PR**, que nunca esteve acima do orçamento.
  Ledger, `sdd autonomy` e juiz herdavam a culpa trocada.
- `f4f859b` — **I10 · a sessão de fase deixa de ser ponto cego.** `--output-format stream-json
  --verbose`, com a sessão escrita ao vivo em `<FASE>-<ts>.stream.jsonl` e o resumo destilado no
  `<FASE>-<ts>.json` de sempre.

## Artefatos

| Arquivo | O que contém |
|---|---|
| `docs/handoffs/20260816-runner-sem-dividas/checkpoint.md` | a tabela dos 10 incrementos com hash **e as Notas de execução — o documento de valor desta missão** |
| `docs/handoffs/20260816-runner-sem-dividas/01-plano.md` | o plano; três desvios registrados nas Notas (I2, I7 e I10, todos ampliação com justificativa) |
| `TODO.md` | 47 achados; a seção "Runner — defeitos e dívidas" **não existe mais** |
| `tests/check-pipefail.sh` | sensor novo do I5, com auto-teste (o catálogo de mutação não o alcança) |
| `docs/pipeline.md`, `docs/failure-modes.md`, `config/schema.md`, `agents/sdd-kaizen.md` | docs atualizadas nos mesmos commits dos consertos (I8, I9, I10) |

## Boot da próxima fase

Leia, nesta ordem: `00-missao.md` (a métrica), **as Notas de execução do `checkpoint.md`** (é onde
está o caro) e depois este arquivo. Ambiente: nada a subir — `bash tests/run-all.sh` na raiz é
tudo, ~41 s, sem rede e sem token (todo `claude` é stub).

**O diff é visível ao usuário em cinco pontos** — é isto que a QA precisa julgar, e não há
interface para andar:

1. `sdd install` sem `config/starter.conf` agora **morre** em vez de criar config vazio e dizer
   `ok`. Mensagem nomeia o arquivo; `$CONFIG_FILE` não é criado.
2. `sdd run` a partir da 10ª rodada de REVIEW/QA passa a escolher `r10`, não `r2`. Só aparece com
   `*_MAX_ITER` > 9 — nenhum projeto está lá hoje.
3. Depois de uma auto-degradação REVIEW→PR, se o gate do PR também falhar o run **encerra** (rc 3,
   `blocked`/`budget-exhausted` em REVIEW), em vez de girar. A última linha impressa muda.
4. `sdd kaizen --series` ganhou `guard.sessions` e `guard.missions_with_session`; `guard.sufficient`
   fica `false` onde antes ficava `true`. Quem lê a série (o agente `sdd-kaizen`) vê shape nova.
5. `.sdd/logs/<missão>/` agora tem **três** arquivos por sessão em vez de dois — o
   `<FASE>-<ts>.stream.jsonl` é novo e é o que se acompanha com `tail -f`.

Nada disso muda saída de terminal em caminho feliz, exceto o item 3.

## Pendências / Decisions for a Human

- **Merge do PR ao final**, como sempre — está no `00-missao.md` e é a única pendência prevista.

## Riscos e não-feitos

- **O I10 não foi exercitado contra uma sessão de fase real.** A mudança de formato foi validada
  contra uma captura REAL do CLI 2.1.233 (as 37 linhas inteiras destilam para 1 objeto `result`
  com o custo certo), mas nenhum `sdd run` de verdade rodou sob o runner novo — a primeira missão
  a rodar depois deste merge é o teste. O plano previa isto: se o parse quebrar, o incremento
  reverte sozinho (uma fatia) e o item volta ao `TODO.md`. **Sintoma a vigiar:** `cost_usd: null`
  em toda linha do ledger, ou `.json` de fase vazio com `.stream.jsonl` cheio.
- **`--verbose` é a metade frágil**, e nenhum stub a enxerga. Se alguém tirar a flag, TODA fase de
  TODA missão morre com rc 1 e stdout vazio. O que segura é uma asserção na projeção do dry-run
  mais `mut_RUN_stream_no_verbose`; não há segunda linha de defesa.
- **`check-autonomy.sh` é vermelho intermitente** (~2 em 15 runs), por colisão de nome de log com
  resolução de 1 s num fixture que versiona `.sdd/logs/`. Já registrado no `TODO.md`. Se a QA vir
  a asserção de "clean tree" falhar, é isto — rode de novo antes de investigar.
- **A suíte passou de 31,6 s para 40,8 s** nesta missão. Aceito e declarado no plano; o alvo de
  <30 s tem item próprio em "Custo e escala" e **não** deve ser pago cortando mutação.
- Não foi tocado nada fora da seção alvo do `TODO.md` — em particular "Adiados por YAGNI",
  instrução explícita do humano.

## Achados fora de escopo

> Registrados no `TODO.md` deste repo. Aqui fica só o ponteiro, para o PR conseguir citar.

- Check do plano que **já nasce verde** (o do I1 era vácuo por crase no título) → `TODO.md`
  ("Sensores que faltam")
- Check que **reprova o conserto certo** (o do I4 casava o termo que o comentário honesto cita
  para desmenti-lo) — defeito distinto do anterior → `TODO.md` ("Sensores que faltam")
- Sensor pulado por `SDD_MUTANT` vira ponto cego sem aviso (o caso geral do achado do I3) →
  `TODO.md` ("Sensores que faltam")
- `grep -m<N>` é a mesma corrida de SIGPIPE que o `check-pipefail.sh` declara mas não fecha →
  `TODO.md` ("Sensores que faltam")
- `check-autonomy.sh` vermelho intermitente por nome de log com resolução de 1 s → `TODO.md`
  ("Sensores que faltam")
- O schema da série `sdd kaizen --series` é descrito em três lugares sem sensor de drift →
  `TODO.md` ("Contrato e configuração")
- `BLOCKED in <FASE> — N sessions` conta voltas do laço, não sessões → `TODO.md` ("Saída humana e
  cosmética")
- O fixture de `stream-json` não tem checagem automática de proveniência → `TODO.md` ("Sensores
  que faltam")
- `.sdd/logs/` não tem poda e agora guarda o stream inteiro de cada sessão → `TODO.md` ("Sensores
  que faltam")
