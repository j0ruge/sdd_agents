---
missao: 20261117-o-worker-orquestrador
fase: REVIEW
rodada: 1
status: done
sessao: e93723d8-0bf1-4524-92e5-88c07547bea1
data: 2026-11-18 04:43
gate: tests/run-all.sh no d5eee41 verde (rc 0, 2132 ok, 0 FAIL, 13 min 50 s, anchors 839 de 839 aplicam); tests/check-worker.sh 37 ok em 20 s; árvore limpa ao abrir; varredura de segredos (regex e gitleaks) sem achado; nota B, quatro achados reproduzidos, que viraram R1 e R2
---

# Review — rodada r1 — O worker orquestrador

> Escrito ao fim de cada rodada de revisão, em `docs/handoffs/<missão>/40-review-r<N>.md`.
> O runner lê **a mais recente**. Uma rodada que não fechou também escreve o arquivo, com a nota
> real: nota inflada para passar no gate desliga o único sensor de qualidade da missão.

## TL;DR

Revisado o diff `7ea43e3..d5eee41` (`bin/sdd-worker`, o sensor, o comando, os templates e as docs) com a QA em mãos.
Quatro achados reproduzidos em cópias `mktemp -d`: 1 HIGH (o teto por missão assinado não chega ao `sdd run` quando o `.sdd/config.sh` do alvo fixa `BUDGET_MISSION_USD`, que o starter fixa em 150), 2 MEDIUM e 1 LOW.
O HIGH virou `R1`; os outros três viraram o lote `R2`. Nada foi consertado aqui.
Suíte verde no `d5eee41`. Nota B em Error Handling, Security e Test Coverage, e B em Documentation.
Para a DOCS: as três derivas da QA, a frase da ADR 0022 §3 (decidida abaixo) e o "dezesseis sensores" do `CLAUDE.md`.

## Nota da rodada

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | A | Uma definição por fato (escada, atos, termos assinados, regra do id, leitor do frontmatter), motivo nomeado em toda recusa, `shellcheck -S warning` limpo e nenhuma função morta. |
| Type Safety | A | Toda fronteira valida o valor antes de usá-lo: sha de 40 hex, número do PR, `owner/name` antes do GraphQL, tetos numéricos e o instante conferido pela volta do `date -d`. |
| Error Handling | B | Falha fechada quase em todo lugar, com duas exceções reproduzidas: o teto por missão do ambiente perde para o `.sdd/config.sh` sem aviso (achado 1) e um `allows` sem `--lot` responde o nível sem o teto do lote (achado 3). |
| Security | B | O `pr-ready`, a régua do merge sem humano, lê só a letra da nota e aceita justificativa `<…>` e `gate: <…>`, que o `gate_REVIEW` recusa (achado 2); o `delegate` assina o arquivo da hora do `y`, não o que mostrou (achado 4). |
| Performance | A | Leituras pequenas por `awk`, chamadas ao `gh` limitadas por verbo, sensor inteiro em 20 s e a suíte no tempo de sempre (13 min 50 s). |
| Test Coverage | B | 37 linhas ok e 26 mutantes vivos, mas o fixture do `budget` nunca fixa `BUDGET_MISSION_USD` no config (o regime que esconde o achado 1), e nenhum probe cobre a justificativa placeholder, o `allows` sem `--lot` nem a edição com a pergunta aberta. |
| Documentation | B | `config/schema.md`, `templates/delegation.md` e `commands/sdd-worker.md` prometem que o teto do ambiente chega ao runner, o que é falso em todo alvo semeado pelo starter; somam-se as derivas de prosa que a QA e esta rodada deixam para a DOCS. |
| **Overall** | **B** | Programa sólido e bem medido, com um HIGH no teto por missão e três buracos menores na régua e na assinatura, todos reproduzidos e entregues ao executor como R1 e R2. |

## Achados da rodada

> Um item por achado, com severidade e âncora em `arquivo:linha`. O achado que precisa de conserto
> aparece de novo na seção seguinte, como incremento `R<n>` — nunca com hash: quem conserta é o
> executor, na sessão de depois. O que foi refutado vai para `## O que foi refutado`, com evidência.

| # | Severidade | Achado | Onde |
|---|---|---|---|
| 1 | HIGH | O teto por missão assinado (`budget_mission_usd:`) não chega ao `sdd run` quando o `.sdd/config.sh` do repo fixa `BUDGET_MISSION_USD`: o `load_config` faz `source` do arquivo antes do default, e a atribuição do arquivo passa por cima do ambiente. O `config/starter.conf:100` que o `sdd install` semeia (`bin/sdd:6228-6232`) fixa `150`, e os dois alvos reais conferidos também (`sales_quote` linha 154, `warehouse_explorer_api` linha 52). Reproduzido no runner desta branch, numa cópia: `BUDGET_MISSION_USD=40 sdd run <m> --dry-run` imprime `mission budget: US$ 0.00 of 150`; com a linha do arquivo apagada, `of 40`. O `schema.md` desta missão afirma o contrário ("this key comes from the delegation, not from this file"). No kit o efeito não aparece só porque o `.sdd/config.sh` daqui não fixa a chave | `bin/sdd:147` e `bin/sdd:196` (o mecanismo); `commands/sdd-worker.md:100`; `bin/sdd-worker:458-459`; `config/schema.md:290`; `templates/delegation.md:6` |
| 2 | MEDIUM | O item `review` do `pr-ready` lê só a coluna `Grade`: uma rodada com `A` nas oito linhas, `<…>` nas oito justificativas e `gate: <…>` responde `ready <sha>`, rc 0 (reproduzido com stub do `gh` numa cópia). É a rodada que o `gate_REVIEW` recusa (`bin/sdd:2065`, `PLACEHOLDER`) e a falha medida em `20260818-lote-facil` r1. O `review` do comando manda um subagente devolver "só as notas" e o worker escrever o arquivo, que é o caminho mais curto para essa rodada. A ADR e o `pipeline.md:1958` ressalvam "on the grade alone", mas o buraco não está declarado como limite, e sob `merge` o `pr-ready` é a régua sem humano | `bin/sdd-worker:601-614` (`round_grades`), `bin/sdd-worker:681-687`; `commands/sdd-worker.md:126-128` |
| 3 | MEDIUM | `allows <dir> <ato>` sem `--lot` responde o nível assinado sem o teto do lote: numa campanha com o L6 em `plan`, assinada `full`, `allows approve --lot L6` é `ask … capped by the lot` (rc 1) e `allows approve` é `allowed approve at full` (rc 0). Todo ato do comando é de um lote, então o teto da decisão 8 depende de a sessão lembrar o argumento, o tipo de leitura do modelo que o programa existe para tirar dela | `bin/sdd-worker:366-385`, `bin/sdd-worker:307` |
| 4 | LOW | O `delegate` mostra os termos, pergunta e só depois calcula o digest, sobre o arquivo como ele está na hora do `y`. Reproduzido com um FIFO no stdin: mostrado `level: pr` e `budget_mission_usd: 40`, editado com a pergunta aberta, o `y` assinou `level: full` e `999`, e o `level` responde `full — signed until …`. A nota do F1 afirma que "o que o `delegate` mostra é exatamente o que ele assina". LOW pela calibração de TOCTOU de CLI de um usuário só: o escritor concorrente plausível é o editor do próprio dono ou um `git pull` no checkout | `bin/sdd-worker:215`, `bin/sdd-worker:239` |

## Incrementos de conserto (R<n>)

> **Esta rodada não conserta.** Cada achado que precisa de conserto vira uma linha `R<n>` na tabela
> de incrementos do `checkpoint.md`, e o `sdd-executor` a fecha em TDD, numa sessão de contexto
> próprio; a rodada seguinte re-avalia sem ter escrito o conserto. CRITICAL/HIGH → um `R<n>` cada;
> MEDIUM/LOW baratos → **um** `R<n>` de lote na rodada; caros → `TODO_FILE`; o que exige julgamento
> humano → seção de pendências, nunca `R<n>`; achado **só de prosa** (`Documentation` abaixo de A)
> → `TODO_FILE`, nunca `R<n>` — o gate tolera B ali, e foi esse laço que custou quatro rodadas.

| R<n> | Achado | Check escrito no checkpoint |
|---|---|---|
| R1 | #1 | `o=$(bash tests/check-worker.sh 2>&1); a=$(grep -c '^  ok    cap: ' <<< "$o"); c=$(grep -c '^mut_WORKER_cap_' tests/check-mutation.sh); test "$c" -ge 1; echo "$a $?"` → `1 0` |
| R2 | #2, #3 e #4 (lote) | `o=$(bash tests/check-worker.sh 2>&1); a=$(grep -c '^  ok    rationale: ' <<< "$o"); b=$(grep -c '^  ok    lot: ' <<< "$o"); d=$(grep -c '^  ok    shown: ' <<< "$o"); r=$(grep -c '^mut_WORKER_rationale_' tests/check-mutation.sh); l=$(grep -c '^mut_WORKER_lot_' tests/check-mutation.sh); s=$(grep -c '^mut_WORKER_shown_' tests/check-mutation.sh); test "$r" -ge 1 && test "$l" -ge 1 && test "$s" -ge 1; echo "$a $b $d $?"` → `1 1 1 0` |

Os dois Checks foram rodados no `d5eee41` e são vermelhos pelo motivo certo: `R1` → `0 1` e `R2` →
`0 0 0 1`, porque nenhuma das quatro famílias (`cap: `, `rationale: `, `lot: `, `shown: `) nem
nenhum dos prefixos de mutante existe hoje; nenhum deles colide com os 26 `mut_WORKER_*` nem com as
11 famílias atuais do sensor. As famílias são novas de propósito, como as do F1 e do F2: nenhuma
linha nova nas famílias dos I, ou os Checks do I1 ao I8 mudam de conta.

## O que virou incremento

- #1, o teto por missão — virou `R1` — o worker deixa de prometer um teto que o runner não aplica,
  **sem editar `bin/sdd`** (fora do escopo da missão): quando o `.sdd/config.sh` do repo da campanha
  fixa `BUDGET_MISSION_USD` acima do `budget_mission_usd:` assinado, ou em `0` (sem teto), o verbo
  que imprime o teto do `run` (`budget`) sai rc 1 nomeando a chave e o arquivo, em vez de imprimir
  um teto que não vai valer. Um valor no arquivo menor ou igual ao assinado é mais estrito e passa.
  A leitura é a do `config_key`, com a chave **fora** do ambiente do subshell, ou o valor exportado
  pela sessão se passaria pelo do arquivo. Fixture com o config que o `sdd install` escreve (o
  `BUDGET_MISSION_USD=150` ativo). A prosa que diz o contrário muda no mesmo commit:
  `config/schema.md:290`, `templates/delegation.md:6` e o `run` do `commands/sdd-worker.md`. Frase
  sugerida: `cap: a repo config that sets BUDGET_MISSION_USD above the signed mission cap, or to 0, stops budget and names the key`.
- #2, #3 e #4 — viraram o lote `R2`, um Check por achado na mesma célula:
  - `rationale: ` — o item `review` do `pr-ready` recusa a linha cuja justificativa é placeholder
    pela mesma régua do `gate_REVIEW` (vazia, inteira entre `<` e `>`, só pontuação, ou uma das
    palavras de preenchimento, comparadas como palavra), e o `gate:` presente e placeholder; `clean`,
    `n/a` e `—` continuam sendo justificativa. É uma segunda cópia da regra num segundo programa: o
    comentário diz isso e o probe compara as duas sobre as mesmas linhas, diferencialmente.
  - `lot: ` — um ato pedido sem `--lot` nunca é permitido acima de um teto de lote da fila: ou o
    `allows` exige o `--lot` (uso, rc 2), ou responde sob o menor teto da tabela. A escolha é do
    executor; o probe é a campanha com um lote em `plan`, assinada `full`, e `allows approve` sem
    `--lot`.
  - `shown: ` — o `delegate` assina o que mostrou: guarda os termos exibidos, e depois do `y` recusa
    (`not signed`, nada escrito) se os termos relidos diferirem. O probe edita o arquivo com a
    pergunta aberta (FIFO no stdin, como reproduzido nesta rodada).

## O que foi refutado

- **O `$!` do `setsid nohup … &` do ato `run` seria o pai que o `setsid` bifurca e sai na hora, e a
  espera pelo PID terminaria cedo.** Refutado nesta máquina: com `bash -c` e com `bash -ic`, o `$!`
  foi o processo que sobreviveu (`ps` mostrou o `sleep` vivo, grupo próprio, `kill -0` verdadeiro).
- **`SDD_WORKER_NOW` ressuscitaria uma delegação vencida.** Refutado: `now()` só aceita a costura
  quando os dígitos dela são maiores que os do relógio real, e um valor malformado com mais dígitos
  só faz vencer mais cedo, o lado seguro.
- **O `config_key` deixaria o `ON_ESCALATION_CMD` do ambiente passar pelo do arquivo, divergindo do
  runner.** Refutado: as duas leituras dão a mesma precedência (o arquivo vence, o ambiente preenche
  quando o arquivo cala). No achado 1 a mesma regra é o problema, não a divergência.
- **O `round_grades` não reemenda o `\|` dentro da célula, como o `gate_REVIEW` faz.** Não levantado:
  a coluna só desliza num critério cujo nome contém `\|`, e o desvio é para o lado fechado (uma
  palavra que não é `A`); ler um `A` inexistente pede um critério chamado `X \| A`, que nenhum
  critério do `codereview` tem.

## Achados fora de escopo

- Nenhum registrado no backlog nesta rodada. O lado do runner do achado 1 (fazer o teto chegar ao
  `sdd run` por cima do arquivo) mexe no contrato de precedência de config do `bin/sdd`, que esta
  missão não edita: vai para as pendências abaixo, para o dono decidir, e não para o backlog.

## Pendências / Decisions for a Human

1. **Como o teto por missão chega ao runner, no lado do runner.** O `R1` só faz o worker falhar
   fechado. Fazer a delegação valer mesmo num alvo cujo config fixa a chave pede mudar o `bin/sdd`:
   uma flag (`sdd run --budget-usd <n>`), ou o ambiente vencer o arquivo para essa chave. As duas
   mexem no contrato de precedência que o `config_reload` documenta. Até lá, num alvo instalado pelo
   starter, a delegação só vale com a linha `BUDGET_MISSION_USD` apagada do `.sdd/config.sh`, ou com
   ela menor ou igual ao teto assinado.
2. **A frase da ADR 0022 §3** ("The signature carries a digest of the other fields"), que a QA deixou
   para a REVIEW ou a DOCS: **decidido que muda, e na DOCS**. A ADR nasce nesta missão e ainda não
   está na `main`, então corrigir a frase não reescreve decisão aceita de ninguém: ela passa a dizer
   que o digest cobre as outras seis chaves e o teto de cada lote da tabela do `campaign.md`.
3. **Para a DOCS, prosa só, nenhum `R`:** as três derivas do `30-handoff-qa.md` (o `sdd-worker` fora
   do `PATH` no arranjo de symlink do `README.md:46`/`:116`, o parágrafo do `budget` do
   `docs/pipeline.md` que esquece os worktrees, e a frase da §3 acima); o `CLAUDE.md:282` e `:293`,
   que dizem "dezesseis" sensores, e `ls tests/check-*.sh` responde 17 com o `check-worker.sh`; e a
   mesma conta na `.claude/rules/anatomia-do-agente.md:179`, que vai como linha ⛔ com texto proposto.
