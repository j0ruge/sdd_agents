---
missao: 20260816-runner-sem-dividas
fase: QA
status: done
sessao: aebac25f-824b-44de-b5af-46d93f065777
data: 2026-08-16 11:56
gate: "Projeto **sem interface** (`E2E_CMD=\"\"`, sem `APP_URL`): a árvore `docs/qa/` não existe e não foi criada; a evidência da jornada é este campo. **Sete jornadas andadas no terminal**, todas verdes. **J1 · `sdd install` sem `config/starter.conf`** — kit-cópia mutilada em `/tmp/qa-walk-j1/kit-broken` contra alvo git novo: `rc=1`, stderr `error: the kit at … has no config/starter.conf — .sdd/config.sh would be created empty…`, e `ls .sdd/config.sh` → `Arquivo ou diretório inexistente`; **segundo** `sdd install` repete o mesmo erro honesto em vez de `preserved`; caminho feliz com o kit inteiro → `ok .sdd/config.sh created`, 2210 bytes com `TEST_CMD`. **J2 · `latest_matching` com `r10` no diretório** — missão-fixture com `40-review-r1/r2/r3/r10` (r3 = Grade A, r10 = C): `sdd why <m> REVIEW` → `40-review-r10.md: Correctness = C`; a ordem lexicográfica leria `r3` e mandaria o pipeline para DOCS. **J3 · giro REVIEW→PR→REVIEW pós-degradação** — `REVIEW_MAX_ITER=1`, `PUBLISH_ON_REVIEW_BLOCKED=draft`, stub que move o disco: `RUN_RC=3`; aviso `moving on to PR in draft mode` impresso **1×**; **1** sessão de PR (a chance única); última linha `the draft PR did not satisfy its gate either — the run ends here`; ledger com `{degraded, review-to-draft, REVIEW}` + `{blocked, budget-exhausted, **REVIEW**}` — a fase que estourou o teto, não PR. **J4 · `sdd kaizen --series`** no ledger REAL: `guard` traz `missions_with_session: 1`, `sessions: 1` e `sufficient: false` (antes `true` sem dado). **J5 · sessão de fase observável** — 2 s dentro da 1ª sessão, `.sdd/logs/<m>/REVIEW-*.stream.jsonl` já existia com **92 bytes legíveis** (`{\"type\":\"system\"…}`) enquanto `.json` ainda não existia; no fim, **3 arquivos por sessão** (`.err`/`.json`/`.stream.jsonl`, 2 de cada para 2 sessões) e o `.json` destilado com `total_cost_usd = 0.0362104`. **J6 · o argv do `run_phase` contra o `claude` REAL** (2.1.233, não stub — fecha o risco declarado no 20-handoff-exec.md): `rc=0`, 14 linhas de stream (`system`×10, `assistant`×2, `rate_limit_event`, `result`), `stream_summary` destila **exatamente 1** objeto, `total_cost_usd = 0.0216704`, `.type == \"result\"` e custo numérico → `true`. Sem `--verbose`: `rc=1`, stdout **0 bytes**, `Error: When using --print, --output-format=stream-json requires --verbose` — a metade frágil confirmada contra o CLI instalado. Sessão morta no meio (linha parcial no fim do stream): `stream_summary` ainda entrega o `result` (1386 bytes, custo certo) — a promessa do comentário de `bin/sdd:892` verificada. **J7 · saúde do kit** — `bash tests/run-all.sh` → rc 0, `suite green`, `score: 37 caught, 0 known gap(s), of 37`, **42,4 s**; `./bin/sdd health` → verde nos 5 checks; `bash tests/check-todo.sh` → `49 finding(s), all within 8 lines` + `selftest: 75 probe(s)`. Métrica da missão reconferida: `grep -c 'Runner — defeitos e dívidas' TODO.md` → **0**. **Zero bugs sanáveis no diff → nenhum incremento `F<n>`.** Dois achados novos, ambos pré-existentes e fora de escopo, no `TODO.md`."
---

# Handoff — QA — a seção "Runner — defeitos e dívidas" do TODO.md é eliminada

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

Sete jornadas andadas no terminal (o kit não tem interface), **todas verdes** — os cinco pontos
visíveis ao usuário que o EXEC listou, mais o argv real contra o `claude` instalado e a saúde do
kit. **Zero achado confirmado no diff desta missão**, logo **nenhum incremento `F<n>`** e nada em
"Decisions for a Human" além do merge. Dois achados **pré-existentes** viraram linha no `TODO.md`.
O risco nº 1 do EXEC — "o I10 nunca rodou contra sessão real" — **foi fechado nesta sessão** (J6).

## Estado do repo

- **Branch:** `missao/20260816-runner-sem-dividas` — nunca empurrada (o push é da fase PR)
- **Último commit:** `b82522e` `chore(checkpoint): I10 done em f4f859b; a seção do TODO.md sai do arquivo`
  (mais o commit desta sessão, que toca só `TODO.md`, o checkpoint e este arquivo)
- **Working tree:** limpo
- **Suíte:** `tests/run-all.sh` → **verde**, 42,4 s, mutação **37/37**, 0 known gaps
- **E2E:** `E2E_CMD=""` — sem interface; a jornada é o terminal, e está no `gate:` acima

## O que foi feito

QA não muda produção. O único commit desta fase carrega os dois achados fora de escopo e este
handoff; o valor da sessão é a **evidência**, que mora no `gate:` do frontmatter.

- as sete jornadas do `gate:` — nenhuma reprovou
- `TODO.md` — dois achados novos, ambos pré-existentes ao diff (ver "Achados fora de escopo")
- `checkpoint.md` — seção "Incrementos de fix (QA)" declara **zero** `F<n>`, com o porquê

## O que a jornada mediu, e o que não mediu

| Ponto visível (do `20-handoff-exec.md`) | Jornada | Veredito |
|---|---|---|
| 1 · `sdd install` morre em vez de criar config vazio | J1 | ✅ morre, nomeia o arquivo, não deixa artefato; 2ª rodada não mente `preserved` |
| 2 · REVIEW/QA escolhem `r10`, não `r2`/`r3` | J2 | ✅ `sdd why` nomeia `40-review-r10.md` |
| 3 · pós-degradação o run encerra em vez de girar | J3 | ✅ rc 3, aviso 1×, 1 sessão de PR, `blocked` em **REVIEW** |
| 4 · `guard` ganha `sessions`/`missions_with_session` | J4 | ✅ no ledger real, `sufficient: false` onde antes era `true` |
| 5 · três arquivos por sessão, stream vivo | J5 | ✅ legível 2 s dentro da sessão; paridade de custo mantida |
| (risco declarado) o I10 contra sessão real | J6 | ✅ CLI 2.1.233, parse certo, `--verbose` confirmado obrigatório |

**O que a jornada NÃO mediu, e é honesto dizer:** a jornada 3 usou `PUBLISH_ON_REVIEW_BLOCKED=draft`
num fixture com stub; nenhum `sdd run` real chegou a degradar. E a J6 exercitou o argv **menos
`--agent`** — subir um agente de verdade custaria uma sessão inteira e não muda o caminho de parse,
que é onde estava o risco.

## Boot da próxima fase

Leia, nesta ordem: `00-missao.md` (a métrica), as **Notas de execução do `checkpoint.md`** (onde
está o caro), `20-handoff-exec.md` e este arquivo. Ambiente: nada a subir — `bash tests/run-all.sh`
na raiz, ~42 s, sem rede e sem token.

**O que o REVIEW precisa saber que a QA viu, e que não está em nenhum outro artefato:**

1. **O `sdd run` desta missão está rodando o `bin/sdd` de `7045e0f`, não o do HEAD.** O processo
   vivo (PID 3568794) começou às 09:31; o I10 entrou às 11:39. O bash já tinha `run_phase` parseado
   em memória, então **esta fase QA — e as fases REVIEW/DOCS/PR que vêm — escrevem no formato
   ANTIGO**: `.sdd/logs/20260816-runner-sem-dividas/QA-20260816-114530.json` está com **0 bytes** e
   não há `.stream.jsonl` ao lado. Isso **não é defeito do diff** (provado pela J5, que roda o HEAD
   num sandbox) — é a consequência de trocar o runner em voo. Quem for revisar e for conferir os
   logs desta missão procurando os três arquivos **não vai achá-los**, e a conclusão certa não é
   "o I10 não funciona".
2. Por isso o **primeiro `sdd run` depois do merge** é o teste de campo do I10. Sintoma a vigiar,
   já nomeado pelo EXEC: `cost_usd: null` em toda linha do ledger, ou `.json` vazio com
   `.stream.jsonl` cheio. A J6 torna isso improvável — o parse foi exercitado contra o CLI real —
   mas não impossível, porque a J6 não passou `--agent`.
3. **`check-autonomy.sh` é vermelho intermitente** (~2 em 15 runs, item próprio no `TODO.md`). Não
   reproduziu nesta sessão. Se cair a asserção de "clean tree", rode de novo antes de investigar.

## Pendências / Decisions for a Human

> Só julgamento humano genuíno. **Não bloqueiam o pipeline.**

- **Merge do PR ao final** — a única pendência prevista pelo `00-missao.md`. Nada mais foi
  encontrado que exigisse decisão humana: as sete jornadas passaram e os dois achados novos são
  pré-existentes, registrados no `TODO.md` e não bloqueantes.

## Riscos e não-feitos

- **Nenhuma jornada rodou um `sdd run` real de ponta a ponta** — o kit não tem interface e um run
  real custa uma missão inteira. Os fixtures usam stub `claude`; a J6 cobre a única metade onde o
  stub mentiria (o formato de saída do CLI), e cobre contra o CLI de verdade.
- **A J3 não exercita o caminho com `PUBLISH_ON_REVIEW_BLOCKED=off`**, que é o default e o que
  todo projeto usa hoje. Nesse regime o ramo degradado nem é entrado — não há o que medir, mas fica
  dito.
- **A suíte está em 42,4 s** (era 40,8 s no fim do EXEC; a diferença é ruído de máquina, não
  código). O alvo de <30 s segue como item próprio em "Custo e escala" e **não** deve ser pago
  cortando mutação.
- **Efeito colateral da própria QA, detectado e revertido nesta sessão:** a primeira jornada de
  sandbox rodou sem `SDD_STATE_DIR` e escreveu **3 linhas de fixture no ledger de produção**
  (`~/.sdd/autonomy-log.jsonl`), levando `sdd autonomy` a reportar `66% waste · 2 mission(s)` para
  o kit_sha corrente. Linhas removidas (`jq 'select(.mission != "20260101-jornada")'`, backup em
  `~/.sdd/autonomy-log.jsonl.qa-backup`), ledger reconferido: `b82522e  1 session(s) · 0 stalled ·
  0% waste · 1 mission(s) · US$ 9.44`, e `sdd kaizen --series` de volta a `sessions: 1`,
  `moved_rate: 1`. **A causa virou item do `TODO.md`** — nenhum leitor filtra por repo, então
  qualquer fixture envenena o juiz em silêncio.
- **Não foi tocada nenhuma linha de produção.** QA não conserta; se algo tivesse reprovado, viraria
  `F<n>` no checkpoint e a bola voltaria para o `sdd-executor`.

## Achados fora de escopo

> Registrados no `TODO.md` deste repo. Aqui fica só o ponteiro, para o PR conseguir citar.

- **`main "$@"` sem guarda, com o kit editando o próprio runner em voo** → `TODO.md`
  ("Sensores que faltam"). Reproduzido em script de 114 KB: edição in-place durante a execução fez
  o bash **re-executar o entry point** e rodar um fragmento de comentário, com **rc 0**. Nesta
  missão não mordeu porque o editor troca o inode — `/proc/3568794/fd/255` aponta para
  `bin/sdd (deleted)` com `pos: 107313`, exatamente o tamanho do arquivo em `7045e0f`, enquanto o
  HEAD tem 114960 (+7647 bytes). É invariante de ferramenta alheia, que ninguém mede. Pré-existente
  ao diff; direção de uma linha (`{ main "$@"; exit $?; }`).
- **O ledger de autonomia é global e nenhum leitor filtra por `repo`** → `TODO.md`
  ("Sensores que faltam"). Medido pelo acidente descrito em "Riscos" acima.

**Duas hipóteses investigadas e DESCARTADAS**, para ninguém pagar de novo:

- *"o `run_phase` não redireciona stdin, então cada sessão perde 3 s"* — o probe manual viu
  `Warning: no stdin data received in 3s`, mas o runner real herda `/dev/null` (`/proc/3568794/fd/0`)
  e **todos os `.err` das 8 sessões de EXEC desta missão estão com 0 byte**. Não é alcançável.
- *"uma linha inválida antes do `result` faz o `jq` abortar e o custo virar `null`"* — verdade
  mecânica (medido: `jq` aborta e perde o `result` posterior), mas o CLI escreve JSON puro em
  stdout e manda aviso para stderr, que vai para o `.err`. Sem reachability medida, é opinião — e
  o caso que o comentário de `bin/sdd:892` promete cobrir (truncagem no fim) **foi verificado e
  cumpre**.
