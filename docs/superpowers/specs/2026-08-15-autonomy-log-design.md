# I13.1 — `autonomy-log.jsonl`: o runner vira sensor de autonomia

**Status:** design aprovado em conversa (2026-08-15), seção a seção; consolidado aqui após
revisão com modelo trocado (Fable), que achou 1 furo e 5 ajustes — todos incorporados.

**Idioma deste arquivo:** pt-BR — artefato de missão (`OUTPUT_LANG` deste repo), não superfície
do kit. O código e os comentários que este spec descreve são ingleses, como manda o `CLAUDE.md`.

## Propósito

O laço kaizen do kit (memória `sdd-agents-kaizen-loop`) precisa de um **juiz** (I13.3) que
responda "a última mudança no kit melhorou ou piorou a autonomia?". Juiz sem série histórica é
opinião. O I13.1 constrói a série: o runner passa a registrar, **por sessão**, os fatos que ele
já observa — e nada além de fatos.

As duas métricas escolhidas pelo usuário:

1. **Desperdício** = sessões que **não** moveram o disco / sessões totais. ⚠️ O design original
   dizia "sessões que moveram / totais" — essa fração é o *oposto* de desperdício (sobe quando o
   kit melhora). A conta adotada é a que casa com o nome; fica registrado para o juiz não ler o
   número invertido.
2. **Maturidade acumulada entre projetos** — rubrica `ok|leve|refez` do usuário
   (`~/.claude/skills/release-notes/references/autonomy-rubric.md`). A rubrica pergunta "o
   humano reescreveu?", que o runner **não vê**. O runner grava o fato (tentativas, retry,
   `moved`, escalada); o rótulo é derivação do juiz, no I13.3.

## Decisões tomadas (com o porquê)

| Decisão | Escolha | Por quê |
|---|---|---|
| Onde vive | **Global**: `${SDD_STATE_DIR:-$HOME/.sdd}/autonomy-log.jsonl` | "Maturidade entre projetos" só existe num arquivo que atravessa projetos. Nunca suja árvore de repo-alvo — elimina por construção o modo de falha do `pipeline.log` (gate_REVIEW derrubado por arquivo untracked, resolvido em `53cf63a`). Custo aceito: não é versionado; máquina morta = histórico morto. |
| Conteúdo | **Só fatos, nenhum score** | Princípio 1 do kit: gate = artefato, nunca rótulo. `ok|leve|refez` é rótulo. O juiz pontua lendo os fatos — e pode trocar a régua sem reescrever o passado. |
| Granularidade | **Uma linha por sessão** (mais linhas de escalada) | A métrica de desperdício só é computável por sessão. À prova de morte de sessão: o que já aconteceu está gravado. Agregado por fase é soma, feita pelo leitor. |
| Formato | **JSONL** | `jq` já é dependência dura (preflight reprova sem ele). Campo novo não invalida linha velha — o que mantém a comparação antes/depois honesta ao longo de meses. Legibilidade humana é papel do `sdd autonomy`, não do arquivo. |
| Leitor | **`sdd autonomy` mínimo, junto** | Formato sem consumidor atravessa verde sendo ilegível. O leitor prova o formato e torna o incremento demonstrável por comando. |

## O registro (contrato)

Toda linha carrega `"v":1` (versão do esquema) e `event`. Dois tipos de linha:

**`event:"session"`** — uma por sessão (retry incluso), escrita depois que `run_phase()` retorna
**e** o gate foi avaliado — a linha carrega o resultado do gate, então nasce depois dele:

```json
{"v":1,"ts":"2026-08-15T14:22:40-03:00","event":"session","run_id":"<uuid do cmd_run>",
 "kit_sha":"60d4e41","kit_dirty":false,
 "project":"sales_quote","repo":"/home/joruge/repos/sales_quote",
 "mission":"20260814-sq94-spinner-reblur","phase":"EXEC","step":"EXEC",
 "agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"8f3c…",
 "rc":0,"dur_s":412,"cost_usd":3.87,"moved":true,
 "gate":"fail","gate_why":"2 of 5 increment(s) still to execute"}
```

⚠️ **Renomeado na revisão final do branch:** o campo nasceu `retry` e virou `auto_retry` antes da
primeira missão real gravar uma linha (ledger com zero linhas — o único momento em que renomear é
grátis). Motivo: `invocation:"retry"` junto com `retry:false` lê como a própria negação — um autor
de juiz que escreva `select(.retry == true)` perde em silêncio todo `sdd retry` humano, e um que
escreva `select(.invocation == "retry")` perde em silêncio todo retry automático do laço. O campo
responde "isto foi a segunda tentativa automática do `cmd_run` dentro do mesmo laço?" — nunca teve
nada a ver com qual comando abriu a sessão, que é o que `invocation` já responde.

**`event:"blocked"`** — escrita nas escaladas, que acontecem **sem** sessão. Os campos de sessão
(`rc`, `cost_usd`, `dur_s`, `moved`, `session`, `agent`, `model`, `attempt`, `auto_retry`, `gate`)
ficam **ausentes**, nunca falsamente zerados. Um enum distingue os três caminhos — o `gate_why`
também distingue, mas por prosa, e juiz que parseia prosa quebra quando a prosa melhora:

```json
{"v":1,"ts":"…","event":"blocked","kind":"increment-blocked","run_id":"…",
 "kit_sha":"…","kit_dirty":false,"project":"…","repo":"…","mission":"…","phase":"EXEC",
 "gate_why":"1 increment(s) 'blocked' — Jidoka: the line stops"}
```

`kind` ∈ `increment-blocked` (Jidoka deliberado do executor — pode ser *bom* sinal) ·
`budget-exhausted` (`phase_budget` estourado — atrito puro) · `no-progress` (retry sem mudança
no disco — sessão improdutiva duas vezes).

Semântica dos campos que carregam decisão:

- **`kit_sha` + `kit_dirty`** — o eixo antes/depois do juiz. `git -C "$SDD_HOME" rev-parse
  --short HEAD`; sem `.git` ⇒ `kit_sha:null`. `kit_dirty` via `git status --porcelain`. Linha
  com `kit_dirty:true` ou `kit_sha:null` é **real mas não-comparável**: SHA sujo/ausente não
  identifica um kit. É o `kit_sha` que permite ao juiz responder `indeterminado` com menos de 3
  missões *depois da mudança* — ele conta missões por SHA, não por calendário.
- **`moved`** — `state_fingerprint()` antes ≠ depois. ⚠️ Mudança de comportamento no runner:
  hoje o retry roda **sem** medição (`before`/`after` só na primeira sessão). O retry ganha seu
  próprio par de fingerprints — o `after` da primeira sessão é o `before` do retry.
- **`run_id`** — uuid por invocação de `cmd_run`. Sem ele, missão retomada produz dois
  `attempt:1` indistinguíveis para a mesma fase; com ele, "esta missão precisou de N runs" vira
  contável — sinal de atrito melhor que contagem de sessões.
- **`cost_usd`** — o `run_phase` cai para `"?"` quando o jq não acha o campo no log da sessão;
  no ledger isso vira **`null`** (via `--argjson`), nunca string, senão o juiz soma lixo.
- **`gate_why`** — truncado em 200 caracteres (tem quebra de linha em alguns gates).
- **`gate`** — `"pass"`/`"fail"`, resultado da avaliação única do gate após a sessão.
- **`phase` vs `step`** — `phase` é a fase do pipeline (`EXEC`, `QA`, …); `step` é o sub-passo
  que a sessão de fato rodou (`QA:plan`, `QA:exec`, `QA:close` — derivado, como sempre, dos
  artefatos). Fora da QA os dois coincidem.
- **`ts`** — `date -Iseconds` (GNU-only por decisão declarada, ver `docs/failure-modes.md`).

## O escritor

Uma função em `bin/sdd`, `autonomy_log_line()`, **com as guardas dentro dela** — lição paga
pelo `pipeline_log_line`: as escaladas são três e uma quarta acrescentada amanhã nasceria com o
defeito se a guarda morasse nos chamadores.

Guardas, em ordem:

1. **`DRY_RUN=1` ⇒ não escreve.** Linha projetada não suja só auditoria — entra na conta do juiz
   e desloca a métrica para sempre. (Defesa em profundidade: no fluxo atual o dry-run nem chega
   ao ponto de escrita, mas a guarda não depende disso.)
2. **`jq` ausente ⇒ não escreve, avisa alto.** Nunca linha malformada: JSONL quebrado é o único
   jeito de o juiz ler lixo achando que é dado.
3. **Falha de escrita ⇒ `warn` e a fase continua.** `~/.sdd` sem permissão, disco cheio: sob
   `set -e` um `>>` que falha abortaria o runner, e a missão vale mais que o registro dela.
4. **Um `write()` por linha.** A linha é montada numa variável com `jq -cn --arg/--argjson` e
   escrita com um único `printf '%s\n' >> "$arquivo"` (open com `O_APPEND`). O `jq` nunca
   escreve direto no arquivo — o stdio dele pode fatiar a saída, e o arquivo agora é global:
   dois repos podem escrever ao mesmo tempo. JSON nunca é montado à mão com `printf` — o
   `gate_why` tem aspas e quebras de linha.

Pontos de escrita — **somente no `cmd_run`**:

- **Duas escritas de sessão, não quatro.** Hoje o laço avalia `gate_"$phase"` em quatro ramos.
  Refactor: avaliar o gate **uma vez** para variáveis (`gate_rc`, `GATE_WHY`), escrever a
  linha, e só então ramificar. Uma escrita após a sessão normal, uma após o retry (que agora é
  medido).
- **Três escritas de escalada**, uma por caminho, cada uma com seu `kind`.
- **`sdd close`, `sdd preflight` e o `return 2` do PLAN interativo não escrevem.** Não são fase;
  não há sessão gasta nem atrito a medir — o PLAN interativo é o desenho, não fricção.

**`SDD_STATE_DIR`** é variável de ambiente, e é **peça obrigatória do desenho**, não
conveniência: é o que permite à suíte redirecionar toda escrita para um diretório efêmero (ver
Sensores). ⚠️ Não é chave do `.sdd/config.sh` — o arquivo é global por decisão, e chave por repo
sugeriria o contrário. ⚠️ Documentar **em prosa** (README/schema.md), nunca como linha `| `CHAVE` |`
da tabela do `config/schema.md`: a checagem 4 do `sdd health` compara a tabela com o
`load_config()` e acusaria `doc-without-key`.

## O leitor — `sdd autonomy`

Lê o ledger e imprime, agrupado por `kit_sha`:

```
▸ sdd autonomy — ~/.sdd/autonomy-log.jsonl · 147 linhas · 4 projetos

  kit_sha   sessões  paradas  desperdício  escaladas  missões  US$
  60d4e41        12        1          8%          0        2   41.20
  e4606db        31        7         23%          2        5   98.70
  (3 linhas não-comparáveis excluídas: 2 kit_dirty, 1 sem 'moved')

  por fase, no kit corrente (60d4e41)
    EXEC  7 sessões · 1 parada · 0 escaladas
```

Contas: `desperdício = moved:false / sessões comparáveis`, por `kit_sha`. Sessão comparável =
`event:"session"` com `moved` presente, `kit_dirty:false`, `kit_sha` não-nulo. Escaladas contadas
por `kind`. A coluna `missões` (distintas por `kit_sha`) existe para amostra pequena ficar
visível — é o mesmo dado com que o juiz responde `indeterminado` abaixo de 3.

O que ele **se recusa** a responder:

- **Não diz se melhorou.** Imprime número; veredito é do `sdd-kaizen` (I13.3). Leitor que opina
  hoje vira a régua que o juiz teria de contradizer amanhã.
- **Não compara linha não-comparável.** Exclui e **diz quantas excluiu**, por motivo. Campo
  `moved` ausente (esquema velho) é excluído, nunca somado como "não mexeu" — somar `null` como
  zero inflaria o desperdício do passado e faria qualquer mudança futura parecer melhoria.
- **Ledger vazio ou ausente ⇒ "sem dados", rc 1.** Nunca `0%` — zeros que parecem excelência são
  a mesma vacuidade que os pisos do `check-lang` e do `cmd_health` matam.
- **Linha malformada ⇒ erro alto, rc 1.** Não pula em silêncio.

O cabeçalho imprime caminho e contagem de linhas: backup do ledger é decisão informada do
usuário, não descoberta tardia (perda foi custo aceito da escolha "global").

**O comando é a janela do humano; o arquivo é a interface do juiz.** O I13.3 lê o JSONL com
`jq`, nunca parseia esta tabela.

`sdd autonomy` entra no `sdd help` **no mesmo commit** — a checagem 5 do `sdd health` reprova
subcomando fora do help.

## Modos de falha

- **Runner morto no meio (SIGKILL):** a linha é escrita *depois* que a sessão retorna; perde-se
  no máximo a linha em voo. Append-only de observação concluída, não transaction log — a
  alternativa ("iniciou" + correção) quebraria o append-only que torna a escrita concorrente
  segura.
- **Privacidade:** o arquivo global acumula nome de projeto e **caminho absoluto** de todo
  repo-alvo, inclusive material de cliente, num arquivo só. Fica em `$HOME`, não é commitado em
  lugar nenhum, e o `sdd install` **não o toca** (nenhuma linha de `.gitignore` — ele nunca está
  dentro de um repo). Este parágrafo existe para ninguém "melhorar" isso depois versionando o
  ledger.
- **Evolução de esquema:** campo novo ⇒ linhas velhas continuam válidas e o leitor as exclui
  **com contagem** quando lhes faltar campo essencial. `"v"` torna a exclusão precisa em vez de
  adivinhada.

## Sensores (o que prova que isto mede)

**`tests/run-all.sh` exporta `SDD_STATE_DIR` para um diretório temporário no topo.** Achado da
revisão, e o mais importante dela: o `check-dry-run.sh` exercita o caminho real de escalação
(`blocked` → rc 3 sem sessão), que agora **escreve no ledger** — sem o export, cada rodada da
suíte, em qualquer máquina, injetaria uma linha do projeto `fixture` no ledger real, e o juiz
leria fixture como missão. Com o export no topo, nenhum teste — existente ou **futuro** — toca o
ledger real, por construção e não por disciplina.

**`tests/check-autonomy.sh`** (novo; piso de superfície do `check-lang` vai de 25 para 26):

- Roda **dentro dos mutantes** (padrão `check-dry-run`, não `check-preflight`): as mutações novas
  sabotam `bin/sdd`, e quem tem de morrer é a suíte do sandbox — guardado por `SDD_MUTANT`, o
  mutante passaria verde. Consequência: hermético, stub de `claude`, `SDD_STATE_DIR` próprio, e
  **rápido — alvo <0,5s**, porque o custo multiplica pelos 18 sandboxes.
- Asserções do escritor: o caminho real de escalação escreve linha válida (`jq -e`) com `kind`
  certo; `--dry-run` não escreve; `gate_why` hostil (aspas + quebra de linha) ainda parseia.
- Asserções do leitor, contra ledger de fixture (formato nosso ⇒ fixture à mão é legítimo; a
  regra de proveniência é para saída de skill de terceiro): `kit_dirty:true` excluída e
  reportada; linha sem `moved` excluída e reportada; ledger vazio ⇒ rc 1 "sem dados".
- **Piso anti-vacuidade:** o teste afirma **quantas** linhas o leitor enxergou — filtro `jq`
  quebrado reportaria "0 sessões, tudo ótimo" para sempre.

**Duas mutações novas** em `tests/check-mutation.sh` (score 16 → 18):

- `RUN_autonomy_ignores_dry_run` — guarda de projeção removida; a suíte morre.
- `AUTONOMY_null_moved_as_zero` — leitor tratando `moved` ausente como `false`; a suíte morre.

**Custo na suíte, medido e declarado:** hoje ~15,9s contra alvo ≤15s do plano. O
`check-autonomy` soma o próprio tempo × 18 sandboxes + 2 mutantes novos × suíte-de-mutante.
Números antes/depois vão no commit; se o alvo estourar, a decisão (subir o alvo ou paralelizar)
é humana e explícita — não escondida.

## Fora de escopo (explícito)

- O **juiz** (`agents/sdd-kaizen.md` + `sdd kaizen`) — I13.3.
- **Graduação** e `KAIZEN_AUTO_APPROVE` — I13.4.
- Qualquer **score** no ledger ou no leitor — decisão "só fatos".
- Sync/backup do ledger, ledger por repo, rotação de arquivo — YAGNI até doer.

## Critério de sucesso do incremento

1. `tests/run-all.sh` verde, mutação 18/18, `sdd health` rc 0 (help e schema sem drift).
2. `sdd run` de uma missão real produz linhas `session` válidas; uma escalada produz `blocked`
   com `kind`.
3. `sdd autonomy` imprime desperdício por `kit_sha` sobre o ledger real e recusa ledger vazio.
4. Rodar a suíte **não** altera `~/.sdd/autonomy-log.jsonl` (mtime/tamanho iguais antes/depois).
