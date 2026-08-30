---
missao: 20260829-o-incremento-que-andou
fase: REVIEW
rodada: 1
status: done
sessao: e208e254-ad71-4007-b959-3f3a0b3b1d64
data: 2026-08-30 07:10
gate: "`tests/run-all.sh` → rc 0, `suite green`, **700** `ok`, 0 FAIL (era 694 na entrada da rodada). Árvore **limpa** — `git status --porcelain` devolve 0 linhas —, 5 commits novos, todos com sensor vermelho→verde antes do commit: `06c0e5b`, `f00c2dc`, `d40d570`, `d77f2ae`, `354e1c8`. Catálogo de mutação **195**, e os **15** mutantes que esta missão acrescentou ou re-ancorou foram verificados um a um pela função do próprio catálogo extraída por `sed`: nenhum sai rc 90, nenhum sobrevive, cada um mata a asserção que o comentário dele nomeia. Os 6 Checks do `checkpoint.md` (I1–I5, F1) re-caminhados nesta sessão, os 6 verdes, incluindo o `walk-ok` da métrica 2 sobre o ledger real. Varredura determinística de segredos sobre o diff (`scan_secrets.sh`): `{\"findings\": []}`. Catraca `todo-findings` 77 → 85, movida em diff com autor. ⚠️ Carimbo de mutação inválido por desenho — a rodada mexeu em `bin/` e `tests/`; quem re-emite é o `sdd health` do `sdd-publisher`, depois deste commit."
---

# Review — rodada r1 — o incremento que andou

> Escrito ao fim de cada rodada de revisão, em `docs/handoffs/<missão>/40-review-r<N>.md`.
> O runner lê **a mais recente**. Uma rodada que não fechou também escreve o arquivo, com a nota
> real: nota inflada para passar no gate desliga o único sensor de qualidade da missão.

## TL;DR

Revisado o diff inteiro de `feat/o-incremento-que-andou` (16 arquivos, +2006/-63) em quatro passadas
adversariais paralelas — bash, jq, sensores/mutantes e sincronia de contrato. **11 achados
confirmados**, todos reproduzidos: 2 fail-open na direção da lisonja (a mesma família que a missão
existe para impedir), 1 porta sem probe, 4 defeitos de exatidão em documentação e comentário, e 4
regras que a sabotagem removeu com a suíte VERDE. **7 corrigidos nesta sessão**, com sensor vermelho
antes e mutante quando cabia; **8 registrados no `TODO.md`** com reprodução e direção; **1 refutado
com evidência.** Suíte 694 → 700, catálogo 193 → 195, árvore limpa.

## Nota da rodada

O `gate_REVIEW` lê a tabela abaixo — critério e justificativa. As sete justificativas nomeiam o que
sobrou, porque o `A` é comprado pela frase e não pela letra.

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | A | Dois defeitos de lógica consertados com uma linha cada (`${exec_after:-$exec_before}`, `.moved != false`), ambos com o porquê medido no comentário; a simplificação maior — um invariante de "total feito" no lugar das duas regras especiais do caminho histórico — foi prototipada, medida (muda 0 de 158 linhas) e **não** aplicada, porque reescreve a decisão 3 do grill: vai ao humano, não ao diff de uma revisão. |
| Type Safety | A | Disciplina de `null`/ausência auditada de forma adversarial em jq: `tonumber? // null`, as duas guardas de não-nulo (`null < 2` é `true`, confirmado), `!= false` e não `== true` para não mexer na linha de escalada que não tem `moved`, e `type == "object"` provado suficiente — três hipóteses de aborto foram construídas e refutadas. O único buraco restante (um `gate_why` não-string mata o leitor) é inalcançável a partir de qualquer escritor, que usa `--arg`. |
| Error Handling | A | As três recusas do `gate_EXEC` publicam veredito na ordem certa — a do rótulo sem artefato, a Jidoka do F1 e agora a do próprio `tally` ilegível, cuja herestring engolia o status do produtor e deixava as duas outras recusas serem puladas por comparação com string vazia. A guarda que faltava passou a ser local em vez de depender do `[ -n "$rows" ]` do vizinho. |
| Security | A | Varredura determinística de segredos sobre o diff unificado: `{"findings": [], "errors": []}`. O programa jq é splice de `printf` fixo e todo dado de fora entra por `--arg`, nunca por interpolação; a rodada não abriu superfície de entrada nova, não acrescentou rede, e o único arquivo global tocado é o ledger append-only. |
| Performance | A | Medido, não suposto: `gate_EXEC` passou a ler o checkpoint duas vezes (validação + `checkpoint_tally`), e 5 chamadas sobre um checkpoint de 20 000 linhas custam 1192 ms contra 1103 ms na `main` — ~8% sobre um arquivo três ordens de grandeza maior que o real. O `historic_progress` é um `reduce` único aplicado uma vez por programa, antes de qualquer balde. |
| Test Coverage | A | 700 asserções e 195 mutantes; os **15** desta missão aplicam, nenhum sobrevive e cada um mata a asserção nomeada. Uma passada de sabotagem degradou 31 regras uma a uma: 26 ficaram vermelhas com o nome de quem as pegou, e as 5 que ficaram verdes viraram achado — 1 fechada aqui (a terceira porta de fase, que o fixture já escrevia e ninguém olhava) e 4 no `TODO.md` com a sabotagem que as expõe. Os diferenciais têm testemunha de não-vacuidade. |
| Documentation | A | O contrato foi atualizado nos três lugares no mesmo commit (runner, tabela do ledger, sensor) — conferido no `99da6d8` —, o espelho `agents/` × `.claude/agents/` é idêntico e nenhuma frase descreve a régua velha como atual. Os quatro defeitos de exatidão achados nesta rodada foram corrigidos: a coluna "Absent when" que contradizia a própria célula, dois comentários cuja razão a medição desmentia, e os números do `KAIZEN_LOG` que os commits posteriores ao I5 tinham envelhecido. |
| **Overall** | **A** | Os dois fail-open alcançáveis estão fechados com sensor e mutante, a suíte está verde e a árvore limpa; o que sobrou está registrado com reprodução e dono, e o único item de julgamento arquitetural está isolado abaixo, com o protótipo já medido. |

## Achados da rodada

| # | Severidade | Achado | Onde |
|---|---|---|---|
| 1 | HIGH | O retry inline nasce com `pending_before: null`; `null` é o mesmo sentinela de "linha anterior aos campos", então a linha cai no caminho histórico, recebe um `pending_before` fabricado (`M`) e lê `advanced` sobre um retry que não fechou nada | `bin/sdd:4194` |
| 2 | HIGH | O caminho histórico infere `M` com a memória vazia, e o braço `advanced` passa a creditar até a sessão que **não mexeu no disco** — `0% waste` sobre quem não fez nada | `bin/sdd:1896` |
| 3 | HIGH | A coluna "Absent when" dos três campos novos diz "ausente fora do EXEC"; a outra metade da MESMA célula diz o contrário, e quem está certo é a segunda | `docs/pipeline.md:595-597` |
| 4 | HIGH | Números do `KAIZEN_LOG` envelhecidos pelos commits posteriores ao I5 (catálogo 192, suíte 692, `check-autonomy` 246) e um número de controle (`14 de 63`) que não reconcilia com nenhuma leitura possível | `KAIZEN_LOG.md:45-48` |
| 5 | MEDIUM | A terceira das cinco portas `if [ "$phase" = "EXEC" ]` não tinha probe; sem ela uma linha de QA sai carregando os números do EXEC, e a suíte fica verde | `bin/sdd:4232` |
| 6 | MEDIUM | A razão registrada para preferir `== null` a `has(...)` afirma um fato que o arquivo desmente (`grep -c pending_before` no ledger real responde 0, não 49) | `bin/sdd:1878` |
| 7 | MEDIUM | Dois comentários justificam a sobrevivência dos globais entre fases por `current_phase`, que roda em subshell e não pode ser o vetor | `bin/sdd:729`, `bin/sdd:4134` |
| 8 | MEDIUM | A herestring do `checkpoint_tally` engole o status do produtor, e com os três campos vazios as duas recusas do gate são puladas | `bin/sdd:786` |
| 9 | MEDIUM | `gate_EXEC` valida por `IFS=$'\t' read` (colapsa tabs) e conta por `awk -F'\t' $4` (não colapsa): uma célula vazia separa os dois leitores | `bin/sdd:786` |
| 10 | MEDIUM | Quatro regras novas somem sem a suíte perceber: a `doing` do `tally`, as duas portas do `cmd_retry`, a metade `repo` da chave de memória e a guarda `phase == "EXEC"` do caminho histórico | `bin/sdd:328`, `:1918`, `:4291` |
| 11 | LOW | A frase de divulgação do caminho datado conta linhas que nenhum balde mostra — e ela é o sinal de apagamento desse caminho | `bin/sdd:4535` |

## O que foi corrigido

- **#1 — retry inline com `pending_before` nulo** — corrigido em `06c0e5b` — reproduzido ponta a ponta
  com `sdd run` real (a passada fotografa 1, o retry deixa 1, e o leitor respondia `advanced` sobre um
  2 fabricado). O fallback `${exec_after:-$exec_before}` é exato porque o retry inline só é alcançável
  pela guarda `moved == "false"`. Sensor vermelho antes (`expected: true 1 1 2 / got: true null 1 2`),
  com piso verde ao lado provando que o fixture chega ao retry; mutante `RUN_retry_pending_before_null`.
- **#2 — inferência creditando quem não mexeu no disco** — corrigido em `f00c2dc` — a guarda
  `.moved != false` é tautologia (fechar incremento é editar o checkpoint, e o `state_fingerprint` o
  hasheia), então não custa nada ao caminho medido. Medido antes de escrevê-la: 53 linhas recuperadas,
  48 `advanced`, e a guarda **não move nenhuma** — `runner-sem-dividas` segue `14 advanced · 1 churned`.
  Mutante `AUTONOMY_progress_outranks_moved`, com testemunha de não-omissão.
- **#3, #4, #6, #7 — exatidão de documentação e comentário** — corrigidos em `d40d570` — a coluna
  adotou a redação que o `kit_sha` já usa; as duas razões desmentidas foram reescritas dizendo o que a
  medição mostra (a escolha estava certa, a razão não); os números do `KAIZEN_LOG` viraram 699/253/195
  com a trilha de onde saíram, e o número de controle virou **19 de 68** com o predicado escrito por
  extenso e o tamanho do ledger no momento da leitura.
- **#5 — a terceira porta de fase** — corrigida em `354e1c8` — o fixture já escrevia a linha que a
  prova; bastou olhar para `.[2]`. Provado que a asserção nova é a **única** que reprova com a guarda
  removida (`QA true false` contra o `QA true true` exigido).
- **#8 — herestring engolindo o status** — corrigido em `354e1c8` (guarda escrita em `bin/sdd`) — a
  recusa deixou de depender do `[ -n "$rows" ]` do vizinho, que é uma leitura diferente do arquivo.

## O que foi refutado

- **"Mudar a frase `N of M` do `gate_EXEC` quebraria a leitura das 53 linhas em silêncio"** (limite
  declarado pelo EXEC no `20-handoff-exec.md` § Riscos) — **refutado com sabotagem**: mudei a redação
  do produtor numa cópia e rodei a suíte inteira; ela ficou verde, e isso é **correto**, não um
  fail-open. As 53 linhas são imutáveis e já carregam a frase antiga — o ledger é append-only —, e
  depois do conserto #1 nenhuma linha nova nasce elegível ao caminho histórico. O acoplamento que o
  handoff temia não existe: o leitor casa a prosa CONGELADA, não a que o gate imprime hoje. O limite
  como escrito superestima o risco; o caminho é datado de verdade.
- **"O `historic_progress` pode não preservar o comprimento da lista, ou abortar num `$r + {...}`
  sobre linha não-objeto"** — refutado por fixture com string, número, `null`, booleano, array,
  escalada e `{}`: `{"in":9,"out":9,"same":true}`, e o `($r|type) == "object"` curto-circuita tudo
  para o ramo identidade. `$local_total` e `assert_bucket_sum` seguem significando o que significavam.
- **"O juiz e a janela humana podem ler históricos diferentes"** — refutado por rastreio dos dois
  programas: `historic_progress` é aplicado no MESMO ponto dos dois (logo após o filtro de repo,
  antes de qualquer classificação), e todo balde de `--by-mission` é ligado abaixo dele. Confirmado
  empiricamente sobre um fixture só: `2 advanced` nos dois. É o defeito que a missão existe para
  fechar, e ele está fechado.

## Achados fora de escopo

Oito, todos registrados no `TODO.md` (2026-08-30) pela régua D15 — os oito são fail-open, e a
catraca `todo-findings` subiu 77 → 85 em diff com autor, nos commits `d77f2ae` e `354e1c8`:

- **#9** divergência `IFS read` × `awk` no `gate_EXEC` — diferencial medido dá `MAIN rc=1` contra
  `HEAD rc=0` (o gate passa onde recusava) — registrado no `TODO.md` (2026-08-30)
- **#2 (resto)** a inferência de `M` para quem mexeu no disco, com o invariante já prototipado e
  medido — registrado no `TODO.md` (2026-08-30)
- **ledger global real contaminado por missões de fixture dos testes** — 4 dos 6 grupos EXEC do número
  de controle são fixture, e é por isso que a mesma pergunta devolveu quatro respostas durante a
  revisão — registrado no `TODO.md` (2026-08-30)
- **#11** a frase de divulgação conta linhas que nenhum balde mostra — registrado no `TODO.md` (2026-08-30)
- **#10, em quatro entradas**: a regra `doing` do `tally` (a mais séria — degradada, o `gate_EXEC`
  FECHA a fase por cima de um incremento em voo, com a suíte verde; herdada da `main`, mas esta missão
  moveu a regra para uma função nova e a reafirmou no cabeçalho); as duas portas do `cmd_retry`; a
  metade `repo` da chave de memória; a guarda `phase == "EXEC"` do caminho histórico — registrados no
  `TODO.md` (2026-08-30)

## Pendências / Decisions for a Human

- **O caminho histórico infere `M` quando a memória está vazia, e trocar isso reescreve uma decisão do
  grill.** Sem memória, `historic_progress` devolve `pending_before := M`, o maior valor possível, de
  modo que o braço `advanced` é satisfeito por qualquer prosa que não seja `M of M`. Está **certo** na
  primeira linha de uma missão (14 linhas do ledger real) e é **fabricação** depois de um gate que
  passou (4) ou quando `M` mudou (2). A guarda `.moved != false` fechou o buraco alcançável — creditar
  quem não mexeu no disco — e o resto é julgamento arquitetural, não conserto de revisão.
  **O trabalho já está feito e medido:** a memória guarda o total FEITO e `pending_before := M -
  done_before`; um invariante substitui as DUAS regras especiais (decisão 3 do grill: "`M` mudou ⇒
  compara com o `M` novo"; "`pass` zera a memória"), responde certo nos três casos, e sobre o ledger
  real muda **0 de 158** linhas — o histograma segue `114 advanced · 25 churned · 19 idle` e a métrica
  2 da missão não se move. O que impede de aplicá-lo numa revisão é o preço colateral: derruba a
  asserção `a passing gate clears the count the next session is measured against` (que hoje afirma a
  leitura lisonjeira) e re-ancora `AUTONOMY_historic_total_change_blind` e `..._pass_keeps_memory`.
  Decisão para o humano: adotar o invariante numa missão própria, ou manter as duas regras e declarar
  a inferência no cabeçalho. Está no `TODO.md` com a direção completa.
- **O ledger global que o kit usa para se julgar está contaminado por missões de fixture dos próprios
  testes.** Não bloqueia esta missão — os números publicados foram todos re-derivados com o predicado
  escrito —, mas toda estatística que o kit publica sobre si mistura corridas de teste com corridas
  reais, e é decisão de operação (limpar? separar o ledger de teste? recusar escrita fora de
  `SDD_STATE_DIR`?). Registrado no `TODO.md` com a direção.
