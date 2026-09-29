---
missao: 20260928-os-achados-da-janela
fase: EXEC
status: done
sessao: 4d26d92f-6c4b-403b-b867-8ff2bc9e2a51
data: 2026-09-28 19:05
gate: "bash tests/run-all.sh no HEAD da rodada 7 (bots do PR #176) → o resultado é o status local/ci desse sha no PR; check-coordination.sh → 183 passed, 0 failed; check-mutation.sh --anchors → 490 mutants; os 7 novos (COORD_bash_remedy_unprobed, COORD_remedy_attribute_probe, COORD_capable_unchecked, COORD_remedy_probe_recurses, COORD_capable_skips_flock, COORD_bash_remedy_flagless, COORD_remedy_probe_flagless) mortos pelo probe que os nomeia; check-todo --check → 87 finding(s), every anchor on target; os 7 Checks do checkpoint com o esperado, I1 e I7 refixados na catraca 87 (87/11/placed/1, 1/1/1/1/1/87)"
---

# Handoff — EXEC — os achados da janela do juiz

## TL;DR

Os sete incrementos estão `done`, cada um com a suíte verde no próprio commit. Cinco achados foram
consertados: 4, relatório de QA da missão (`121a696`); 3, `APP_EXPECT` (`4423bb0`); 6, DOCS com
`⛔` e texto proposto (`1ffee16`); 7, o close faz fast-forward (`c320630`); 8, `CHECKOUT-UNAVAILABLE`
nomeado (`fbaf9a1`). Três foram registrados no `TODO.md` (1, 2 e 5; catraca 83 → 86, `48e89b7`).
O fechamento (`3ac59ee`) trouxe a ADR 0013 aceita, o KAIZEN_LOG, o `CONTEXT.md`, a anatomia e a
gaveta. A revisão final da branch (revisor de contexto novo) achou 3 Important, consertados em
`ec95baf`. O `/codereview` depois dela achou 2 MEDIUM e 4 LOW (nota B), consertados em
`a383150`..`9f17bfb`; uma segunda rodada, de contexto novo, sobre esses consertos deu B de novo
(2 MEDIUM, um deles criado pela rodada 1) e foi consertada em `68af14b`; a rodada 3 achou mais um
MEDIUM criado pela rodada 2; a rodada 4, holística sobre as duas unidades que quebravam, achou um
HIGH (range só com a base local) e reescreveu a leitura do relatório em três fatos (`e268a6d`); a
rodada 5 mediu o que a 4 deixou sem probe (`9318dc7`); a rodada 6 deu nota A, e seus dois LOW
foram consertados. No PR #176 os bots deixaram 5 comentários (Codex 1, CodeRabbit 4) e um nitpick,
consertados numa leva na rodada 7 (`ffb5bff`, `4f5358f`); o nitpick foi recusado com motivo. O
catálogo foi de 422 para 490 mutantes, e cada um novo morre pela asserção que o nomeia. A missão
rodou inline, sem `sdd run`. Falta o `sdd health` (carimbo) e o merge, que é do humano.

## Estado do repo

- **Branch:** `fix/os-achados-da-janela`, empurrada, **PR #176** contra `main` = `3d350ed`.
- **Último commit de código:** `ffb5bff` (rodada 7, o remédio sondado do `CHECKOUT-UNAVAILABLE`).
- **Working tree:** limpo depois do commit deste handoff.
- **Suíte:** `bash tests/run-all.sh` → verde, ~240 s.
- **E2E:** não se aplica (o kit não tem `E2E_CMD`).

## O que foi feito

- `48e89b7`: I1, três itens verbatim no `TODO.md` (achados 2, 1 e 5) e `todo-findings 86`.
- `121a696`: I2, `mission_qa_report` (o relatório que a branch adicionou, ou novo na árvore; recuo
  no range vazio), lido pela Âncora 1 do `gate_QA` e pelo `qa_substep`. Cinco mutantes.
- `4423bb0`: I3, chave `APP_EXPECT` e estado `wrong` no `app_probe`. O preflight falha com
  `E2E_CMD`; o `gate_QA` com e2e vermelho arma o `GATE_APP_DOWN`. Dois mutantes.
- `1ffee16`: I4, `.claude/rules/**` sai do `writes:` do `sdd-docs`. O `gate_DOCS` aceita `⛔` só com
  a proposta nomeando o documento, linha a linha, e passa em voz alta. O publisher e o template do
  PR levam o texto. Quatro mutantes.
- `c320630`: I5, `close_return_home` faz fetch e `merge --ff-only`. Nunca `die`; sem `timeout`,
  pula o fetch. Um mutante.
- `fbaf9a1`: I6, `Unavailable` com o requisito, o interpretador do PATH, o `sys.executable` e o
  remédio sondado. Um mutante.
- `3ac59ee`: I7, `RESOLVED by 121a696`, KAIZEN_LOG, ADR 0013 `accepted`, piso do `check-lang` em 55,
  `CONTEXT.md`, anatomia (§ 4 e § 6) e gaveta.

- `ec95baf`: revisão final. `app_probe` só lê `wrong` numa página 2xx (redirecionamento ou página de
  erro viram `unknown`). O remédio do Python aparece só para requisito de build. O `gate_DOCS` lê
  todas as seções marcadas, ignora `## ` dentro de bloco de código e exige que o documento seja um
  nome. Os resíduos do range (é do HEAD, não da missão) estão declarados. Stale e "achado" na
  superfície inglesa. Cinco mutantes.

- `/codereview` (2 MEDIUM, 4 LOW), um commit por achado, cada regra com probe e mutante:
  - `a383150`: `mission_qa_report` acha o relatório renomeado (commit e índice) e o não commitado
    com espaço (`--no-renames`, `-z`); a recusa diz "is not one this branch added"; o `unknown`
    diz "no verdict on", não "not probed" (#3, #4);
  - `5ea6b2d`: o marcador `<!-- sdd:proposed -->` é linha própria, fora de fence (#1, fail-open);
  - `b9b97b5`: `⛔` num documento que o chapéu escreve é recusado, `.claude/` excetuado (#5);
  - `91ae96c`: o `gate_PR` exige no corpo do PR cada documento `⛔`; o awk da tabela vira
    `docs_checklist_rows`, lido pelos dois gates (#2, fail-open);
  - `e97d23b`: os quatro avisos do `close_return_home` com probe (#6);
  - `442cdf7`: 22 âncoras do `TODO.md` re-ancoradas (duas passavam por coincidência);
  - `9f17bfb`: o `gh` que não lê o corpo do PR tem a própria razão (autorrevisão).
- Rodada 2 (`68af14b`), revisor de contexto novo sobre `d9df321..9f17bfb`: a posse do relatório
  segue a cadeia de renames (o `--no-renames` da rodada 1 dava posse a um relatório de OUTRA missão
  só renomeado); o `gate_PR` exige o nome numa linha com `⛔` e não relê PR mergeado; a célula `⛔`
  com vários documentos é julgada por documento; contagens velhas na prosa; cinco âncoras do
  `TODO.md` levadas ao assunto.
- Rodada 3, revisor de contexto novo sobre `9f17bfb..279b485`: o `split` da rodada 2 apagava a
  linha `⛔` de célula vazia (`split("")` é 0 no `mawk`) e o `gate_DOCS` passava — agora a linha que
  não rende nome imprime um nome vazio, recusado; a cópia staged (`status.renames=copies`) é da
  missão, como o log a leria; prosa da leitura antiga acertada; o `sdd-docs` põe um documento por
  célula `⛔`. As âncoras do `TODO.md` foram auditadas contra o diff desde `d9df321`: 17 que as
  remapeações por rodada deixaram até 69 linhas longe do conteúdo voltaram a ele; só as 13 levadas
  de propósito ao assunto divergem.
- Rodada 4 (`e268a6d`), holística sobre `mission_qa_report` e o caminho do `⛔` inteiros: os commits da
  missão são `HEAD --not` a base local e a remota (um `git pull origin <base>` com a base local velha
  dava posse a relatório de outra missão — HIGH); caminho que a base já tem nunca é novo (revert,
  `rm --cached`); rename replayado pais primeiro; leitura por plumbing (`log.showSignature`); ` A`
  conta; `-ef`, `.md`, add staged e `./docs/qa/` ganharam probe; tabela sem coluna `Status` é
  recusada e célula de `Status` vazia é pendente.
- Rodada 5 (`9318dc7`): o braço `C` cai na checagem de base do `??`; `@{upstream}` e `origin/<b>`
  com um mundo cada; sem merge-base (clone raso) volta a resposta de antes; limite de rename fixo em
  0; `Status` na última coluna; pendente por contagem. O resíduo "relatório posto na base depois do
  corte e trazido por checkout/squash/cherry-pick" foi para o `TODO.md` (catraca 86 → 87).
- Rodada 6: nota A — nenhum MEDIUM ou acima; os 482 mutantes e os 48 `45-docs.md` reais sem mudança
  de decisão. Dois LOW consertados: o rename na árvore (` R`, `mv` + `add -N`) carrega a posse, e
  este `gate:` diz a saída real dos Checks de I1/I7 depois da catraca.
- Rodada 7, os bots do PR #176 numa leva: o remédio `PATH=/usr/bin:$PATH` era oferecido sem sonda
  (bash: só `-x`; helper: só os atributos). Agora os dois lados rodam o modo `capable` do helper, e
  `SDD_SYSTEM_PYTHON` é o seam que monta o Python de sistema incapaz (`ffb5bff`, 4 mutantes). O
  `sdd-docs` deixou de nomear ferramentas do harness (`4f5358f`). Os Checks de I1/I7 foram
  refixados em 87, e a gaveta marca o F3 antigo como histórico. Recusado: extrair `start_page_server`
  para uma lib de teste (nitpick). Os sensores não compartilham biblioteca, o `port_is_free` já era
  triplicado, e uma lib nova moveria os quatro pisos de superfície. Um revisor de contexto novo,
  holístico sobre a rodada, deu nota A com LOWs, todos consertados na mesma leva: os mundos do
  wrapper provados pelo ramo que as asserções usam, as flags da sonda com probe (PYTHONHOME vazado;
  o `-S` sozinho fica declarado sem mundo) e a prosa. Catálogo 489.
- Rodada 7, segunda passada do CodeRabbit (sobre `65a0bfa`): o `capable` não sondava `flock`, que o
  `REQUIREMENTS` lista. Uma política que nega a syscall ganhava o remédio. Agora o modo faz um `flock`
  num arquivo temporário (a syscall, não o sistema de arquivos do checkout, que o `enter` encontra
  no lock antes de qualquer chamada pidfd), com mundo e mutante. O handoff deixou de dar o Copilot
  por atendido. Catálogo 490.

## Artefatos

| Arquivo | O que contém |
|---|---|
| `docs/handoffs/20260928-os-achados-da-janela/checkpoint.md` | a tabela, com os 7 incrementos `done` |
| `docs/handoffs/20260928-os-achados-da-janela/checkpoint-notas.md` | um desvio por incremento, com o porquê |
| `docs/adr/0013-o-relatorio-da-missao-e-o-texto-proposto.md` | as duas decisões de contrato, agora `accepted` |

## Boot da próxima fase

Esta missão roda **interativa**, nunca por `sdd run` no próprio kit (handoff em
`~/.claude/plans/2026-09-28-handoff-executar-os-achados-da-janela.md`). Os passos 1 a 3 abaixo
estão feitos; o próximo é o 4, o carimbo:

1. ~~`/codereview:codereview` até Grade A~~: seis rodadas, a última com nota A.
2. ~~Push e PR contra `main`~~: PR #176, com status `local/ci` pela API de Statuses.
3. Esperar **todos** os revisores e consertar numa leva: o Codex e o CodeRabbit foram atendidos na
   rodada 7. O Copilot **não revisou** (sem cota) e segue pendente. Esperar pela cota ou mergear sem
   ele é decisão do humano.
4. `./bin/sdd health` **uma vez**, depois do último commit de código. O `gate_PR` exige o carimbo.

O que o diff muda para quem usa o kit:

- a QA de missão em branch própria agora exige o relatório **dela**;
- `APP_EXPECT` é chave nova, vazia por default;
- a DOCS não escreve mais `.claude/rules/`;
- o `sdd close` anda a base;
- a recusa de coordenação diz qual Python caiu.

## Pendências / Decisions for a Human

- Depois do merge: `sdd install --force` no `sales_quote` e no `lighthouse_project`, para o espelho
  novo do `sdd-docs` e do `sdd-publisher` (o prompt só chega assim; a guarda do chapéu lê o kit e
  vale no merge). Também declarar `APP_EXPECT` no `.sdd/config.sh` de cada um: os dois usam a `:5173`.
- Depois do merge: apagar o item do achado 4 do `TODO.md` quando `121a696` for ancestral da `main`,
  e ressincronizar as issues (`/todo-to-github-issues`).

## Riscos e não-feitos

- **Mais estrito para quem já rodava QA em branch com relatório velho:** a fase passa a exigir o
  relatório da própria missão. É o custo pretendido (ADR 0013, Consequences). Continuam no resíduo
  declarado: a missão cuja `branch:` é a base, e a `DEFAULT_BRANCH` sem ref local.
- **Minors adiados da revisão final** (decisão do humano): a coluna do documento fixa em `$3`; o `sdd-docs` não nomeia o `sdd install --force` para os espelhos; o `start_page_server` não
  prova que o servidor na porta é o seu; `unavailable()` sob Python < 3.5; o close compara com o
  ref de rastreio, não com o `FETCH_HEAD`, em refspec fora do padrão. O relatório renomeado e o
  nome com espaço também estavam aqui, e saíram em `a383150`: o humano pediu os achados do
  `/codereview` consertados até a nota A.
- **Sem probe:** a linha sem prefixo no laço do `gate_DOCS` (nenhum ramo do awk a imprime hoje; o
  comentário declara isso). O mundo "sem `timeout(1)`" do close ganhou probe em `e97d23b`.
- **O `sdd health` (catálogo inteiro) não rodou.** Cada mutante novo foi aplicado numa cópia e morto
  pela asserção certa, mas o carimbo dos 490 é passo do PR.

## Achados fora de escopo

- Nenhum novo. Os achados 1, 2 e 5 foram para o `TODO.md` pelo I1: seções `Sensores que faltam` e
  `Contrato e configuração`.
