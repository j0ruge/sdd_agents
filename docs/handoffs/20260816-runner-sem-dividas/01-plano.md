---
missao: 20260816-runner-sem-dividas
data: 2026-08-16
---

# Plano — a seção "Runner — defeitos e dívidas" do TODO.md é eliminada

> **Teste de autocontenção:** uma sessão nova, sem nenhuma memória da conversa que gerou este
> plano, lendo apenas `00-missao.md` + `01-plano.md` + `checkpoint.md`, consegue executar?
> Se a resposta for "só se souber X", **X vai escrito aqui**.

## Contexto verificado (não re-descobrir)

Tudo abaixo foi confirmado em `7045e0f`/`a807971` na sessão de planejamento. Os números de linha
do `TODO.md` **driftaram** — use os daqui.

- A suíte é `bash tests/run-all.sh` (~33 s, mediana medida hoje); score de mutação **30/30**;
  `sdd health` verde nos 5 checks. Baseline desta missão.
- `printf | grep -q` sob `pipefail` devolve 141 quando o grep ACHA (SIGPIPE) — ocorrências vivas:
  `tests/check-gates.sh:53` (`assert_why`) e `tests/check-dry-run.sh:144,163,171,199,251`.
  O conserto-padrão do repo é herestring (`grep -q … <<< "$var"`), como `assert_jidoka` já usa.
- `shellcheck -S warning tests/*.sh` reprova com **exatamente 2×SC2318**, ambas em
  `tests/check-mutation.sh` (`local slug="$1" box="$WORK/$slug"` — o `$slug` da direita é a
  global do laço). O passo de lint em `tests/run-all.sh:32` cobre só `bin/sdd`.
- `latest_matching()` está em `bin/sdd:219-224`; o defeito é `ls -1d $pattern | sort | tail -1`
  (lexicográfico: `r10` < `r2`). O comentário em `bin/sdd:1334` cita o defeito como conhecido —
  atualizá-lo faz parte do conserto. Consumidores: `gate_QA` e `gate_REVIEW` (grep por
  `latest_matching` acha os call sites).
- `bad_rows` em `bin/sdd:276,300`: incrementado no mesmo comando que dá `return 1` — valor final
  nunca lido por ninguém (confirmado por grep: nenhuma outra referência).
- ⚠️ **`gate_DOCS` (bin/sdd:422-450) JÁ lê a coluna Status da tabela de drift** — a `Direção` do
  item do TODO está implementada, com comentário descrevendo o conserto e o piloto SQ-97. O item
  é obsoleto; o hash do conserto entrou em `main` antes de `4933e82` (o rewrite inglês o
  carregou; `git log -S 'Reads the `Status` COLUMN' -- bin/sdd` acha). Fechar por artefato.
- `${var:0:200}` em `bin/sdd:821,827,850` com comentário prometendo "CHARACTER slice" — verdade
  só em locale multibyte; nem runner nem suíte fixam `LC_ALL`/`LANG`.
- `sdd install` em `bin/sdd:1015`: `sed … "$SDD_HOME/config/starter.conf" > "$CONFIG_FILE"` sem
  guarda de existência — faltando o starter, o redirect cria config **vazio** e a linha seguinte
  imprime `ok`. O padrão de guarda do repo é o de `autonomy_append` (`[ -f … ] || die`).
- O laço de auto-degradação: `bin/sdd:1554-1566`. `force_phase="PR"; continue` com o orçamento
  estourado; se o gate do PR falhar, `current_phase` devolve REVIEW e o ramo é re-entrado (o
  registro é one-shot via `degraded_logged`, medido: ramo 3×, ledger 1×). O `return 3` com
  `autonomy_blocked_row "budget-exhausted"` já existe logo abaixo (`:1567-1570`) — o conserto
  reusa esse par, não inventa evento novo.
- Duas definições de comparabilidade no MESMO programa jq: `bin/sdd:1735`
  (`def comparable: .event == "session" and .kit_dirty == false …`) vs `:1742`
  (`def on_axis: .kit_dirty != true and .kit_sha != null`). Hoje não divergem porque o produtor
  (`autonomy_kit_stamp`) só emite `kit_dirty: null` junto com `kit_sha: null`, e `on_axis` já
  reprova pelo sha. `kit_dirty: null` + `kit_sha` preenchido é o input que as separa.
- `guard.sufficient` em `bin/sdd:1854`: `(($latest.missions // 0) >= 3)`, e `missions` conta
  `unique` sobre TODAS as linhas admitidas — três missões só-escalada dão `sufficient: true` com
  `sessions: 0` (reproduzido em fixture na revisão r1 da missão anterior).
- Sessão de fase: `bin/sdd:897` usa `--output-format json` (blob único no fim; o log fica 0 bytes
  durante a sessão). `run_phase` parseia o blob com jq; os stubs `claude` da suíte emitem JSON
  único. Mudar para `stream-json` exige: `--verbose` (o CLI exige com stream-json em `-p`), tee
  para `.stream.jsonl`, e extrair o ÚLTIMO objeto (`type == "result"`) para o parse existente.
- Regras da casa que esta missão vai esbarrar: mutação nova entra em `tests/check-mutation.sh`
  E no catálogo do `sdd health`; asserção verde tem de ser vermelha pelo motivo certo (fixture no
  regime que repete + testemunha); herestring, nunca `printf | grep -q`; comentário nunca DENTRO
  de bloco continuado por `\`; função com efeito em global é chamada, nunca `x="$(f)"`.
- `TODO.md`: os 11 itens da seção "Runner — defeitos e dívidas" (títulos exatos no arquivo).
  Fechar = **apagar** o item no mesmo commit do conserto, citando o hash no corpo do commit.
  `tests/check-todo.sh` mede o formato do que sobrar.

## Arquitetura da mudança

Nenhum contrato de artefato muda. Três frentes: (a) `bin/sdd` — quatro consertos pontuais
(sort -V, guarda do install, fim do giro pós-degradação, uma definição de comparabilidade +
piso do guard) e uma limpeza (`bad_rows`); (b) `tests/` — a família `printf | grep -q` sai,
o lint passa a cobrir `tests/*.sh`, e cada conserto de runner ganha asserção + mutação;
(c) observabilidade — `run_phase` passa a logar stream. A ordem dos incrementos é
risco-crescente: triagem barata primeiro, mudança de laço e de formato de log por último.

## Incrementos

### I1 — Triagem por artefato: o obsoleto sai sem conserto

**O quê:** confirmar no HEAD que o item do `gate_DOCS` está resolvido (`git log -S` acha o hash;
`git merge-base --is-ancestor <hash> main` prova) e apagá-lo do `TODO.md`. Re-verificar os outros
10 itens contra o código atual — qualquer outro já-resolvido segue o mesmo caminho.
**Onde:** `TODO.md`.
**Como (TDD):** n/a — triagem, não código. O Check é o artefato.
**Check:** `grep -c 'gate_DOCS reprova' TODO.md` → `0`, e o corpo do commit cita o hash provado.
**Sensor durável:** `tests/check-todo.sh` já mede o formato do arquivo (nada novo a criar).
**Reversível por:** revert do commit.

### I2 — `latest_matching` ordena por versão

**O quê:** `sort` → `sort -V` em `bin/sdd:224`; atualizar o comentário de `:1334` que cita o
defeito como vivo. Asserção nova: fixture com `40-review-r1/r2/r10`, o escolhido é `r10`.
**Onde:** `bin/sdd`, `tests/check-gates.sh`, `tests/check-mutation.sh` + catálogo do health.
**Como (TDD):** a asserção entra primeiro e fica VERMELHA (o sort atual escolhe `r2`); o conserto
a faz passar. Vermelho observado e pelo motivo certo (a mensagem nomeia o arquivo escolhido).
**Check:** `bash tests/check-gates.sh` → verde com a asserção nova; mutação `RUN_sort_lexi`
(reverte para `sort`) mata a suíte.
**Sensor durável:** a asserção + a mutação, ambas commitadas.
**Reversível por:** revert do commit (asserção sai junto).

### I3 — `sdd install` morre alto sem o starter

**O quê:** guarda `[ -f "$SDD_HOME/config/starter.conf" ] || die "…"` antes do `sed` de
`bin/sdd:1015`, no padrão de `autonomy_append`. Asserção: kit-cópia sem `starter.conf` →
`sdd install` rc≠0, mensagem nomeia o arquivo, e `$CONFIG_FILE` NÃO existe (as duas metades:
o texto do ramo certo E a ausência do artefato podre).
**Onde:** `bin/sdd`, `tests/check-preflight.sh` (já exercita `sdd install`),
`tests/check-mutation.sh` + catálogo.
**Como (TDD):** asserção primeiro, vermelha contra o runner atual (config vazio criado com `ok`).
**Check:** `bash tests/check-preflight.sh` → verde com a asserção; mutação `RUN_install_no_guard`
(remove a guarda) mata a suíte.
**Sensor durável:** asserção + mutação.
**Reversível por:** revert do commit.

### I4 — Limpeza dupla: `bad_rows` sai, e o slice para de prometer

**O quê:** (a) remover o contador `bad_rows` de `bin/sdd:276,300` — escrito e nunca lido; o
`GATE_WHY` da primeira linha ruim já diz o que importa. (b) O comentário de `bin/sdd:821,850`
para de prometer "CHARACTER slice" incondicional: passa a dizer que o corte é por caractere sob
locale multibyte e por byte em `C`/`POSIX`, e que ambos são ≥ o `head -c` anterior. Sem mudança
de comportamento em nenhum dos dois.
**Onde:** `bin/sdd`.
**Como (TDD):** n/a — remoção de código morto e honestidade de comentário; nenhum comportamento
novo para testar. `bash -n` + suíte verde provam a não-regressão.
**Check:** `grep -c bad_rows bin/sdd` → `0`; `grep -c 'CHARACTER slice' bin/sdd` → `0`;
`bash tests/run-all.sh` → verde.
**Sensor durável:** n/a justificado — não há asserção para ausência de promessa; o custo de um
sensor aqui excede o valor (é prosa de comentário).
**Reversível por:** revert do commit.

### I5 — A família `printf | grep -q` sai da suíte, e um sensor impede a volta

**O quê:** herestring nas 6 ocorrências (`tests/check-gates.sh:53`,
`tests/check-dry-run.sh:144,163,171,199,251`). E o sensor SDCA: um passo em `tests/run-all.sh`
(fora do modo mutante) que reprova `printf … | grep -q` em `tests/*.sh` e `bin/sdd` — a
assinatura da casa não volta despercebida.
**Onde:** `tests/check-gates.sh`, `tests/check-dry-run.sh`, `tests/run-all.sh`.
**Como (TDD):** o sensor entra primeiro e fica VERMELHO contra as 6 ocorrências atuais; as
conversões o fazem passar. Sabotagem manual: reintroduzir uma ocorrência → sensor vermelho.
**Check:** `bash tests/run-all.sh` → verde; `printf 'x' | grep -q x` colado em qualquer
`tests/check-*.sh` → suíte vermelha no passo novo.
**Sensor durável:** o passo novo no `run-all.sh`, commitado.
**Reversível por:** revert do commit.

### I6 — O lint cobre `tests/`

**O quê:** separar o `local` duplo de `tests/check-mutation.sh` em duas linhas (2×SC2318) e
estender o passo de lint de `tests/run-all.sh:32` para `bin/sdd tests/*.sh`.
**Onde:** `tests/check-mutation.sh`, `tests/run-all.sh`.
**Como (TDD):** o passo estendido entra primeiro e fica vermelho (SC2318); o split o faz passar.
**Check:** `shellcheck -S warning bin/sdd tests/*.sh` → rc 0; `bash tests/run-all.sh` → verde.
**Sensor durável:** o passo de lint estendido, commitado.
**Reversível por:** revert do commit.

### I7 — UMA definição de comparabilidade no leitor do ledger

**O quê:** no jq de `cmd_autonomy`, `on_axis` passa a derivar da mesma condição de `comparable`
(`.kit_dirty == false and .kit_sha != null`), definida UMA vez — a regra "enum lido em mais de um
ponto vira UMA definição". Comportamento hoje idêntico (o produtor nunca emite
`kit_dirty: null` com `kit_sha` preenchido); a asserção DIFERENCIAL prova: fixture com
`kit_dirty: null` + `kit_sha` preenchido → os dois leitores (contagem de sessões e mapa de
escaladas) concordam em excluí-la, comparados ENTRE SI, não contra constante.
**Onde:** `bin/sdd:1735,1742`, `tests/check-autonomy.sh`, `tests/check-mutation.sh` + catálogo.
**Como (TDD):** a diferencial entra primeiro — vermelha se as definições divergirem para o
fixture-testemunha; verde com a definição única.
**Check:** `bash tests/check-autonomy.sh` → verde com a asserção nova; mutação
`RUN_on_axis_forked` (re-separa as definições com `.kit_dirty != true`) mata a suíte.
**Sensor durável:** asserção diferencial + mutação.
**Reversível por:** revert do commit.

### I8 — `guard.sufficient` só conta missão com sessão comparável

**O quê:** o piso do juiz (`bin/sdd:1854`) passa a contar missões derivadas das linhas
`comparable`, e o objeto `guard` expõe `sessions` ao lado de `sufficient`. Fixture: 3 missões
só-escalada → `sufficient: false, sessions: 0`; 3 missões com sessão comparável →
`sufficient: true`.
**Onde:** `bin/sdd`, `tests/check-kaizen.sh`, `tests/check-mutation.sh` + catálogo.
**Como (TDD):** os dois fixtures entram primeiro; o de só-escalada fica VERMELHO contra o runner
atual (`sufficient: true` hoje — é o defeito) e verde com o conserto; o segundo prova que o
conserto não apertou demais.
**Check:** `bash tests/check-kaizen.sh` → verde com os dois casos; mutação
`KAIZEN_guard_counts_escalations` mata a suíte.
**Sensor durável:** os dois fixtures + mutação.
**Reversível por:** revert do commit.

### I9 — O giro REVIEW→PR→REVIEW pós-degradação acaba

**O quê:** depois de `force_phase="PR"` (bin/sdd:1566), se o run voltar ao ramo degradado
(`degraded_logged=1` já em 1), o runner **encerra**: `pipeline_log_line BLOCKED` +
`autonomy_blocked_row "budget-exhausted"` + `return 3` — o par que já existe em `:1567-1570`,
reusado; nenhum evento novo no enum. O PR em draft teve sua chance única.
**Onde:** `bin/sdd`, `tests/check-autonomy.sh` (o walk J2 já conta entradas no ramo),
`tests/check-mutation.sh` + catálogo.
**Como (TDD):** asserção primeiro, no fixture do regime que REPETE (o mesmo do F1): runner atual
→ ramo entrado 3×; conserto → ramo entrado 1×, run termina rc 3 com `blocked` no ledger. A
testemunha de contagem já existe no check-autonomy — reusar.
**Check:** `bash tests/check-autonomy.sh` → verde afirmando "ramo 1×, rc 3, 1 linha degraded +
1 blocked"; mutação `RUN_degraded_spins` (remove o encerramento) mata a suíte.
**Sensor durável:** asserção + mutação.
**Reversível por:** revert do commit.

### I10 — A sessão de fase deixa de ser ponto cego

**O quê:** `run_phase` troca `--output-format json` por `--output-format stream-json --verbose`,
com `tee` para `<FASE>-<ts>.stream.jsonl` ao lado do log atual; o resumo final que o `run_phase`
parseia passa a ser extraído da última linha `type == "result"` do stream (mesmos campos). Os
stubs `claude` da suíte passam a emitir stream-json (uma linha de evento + a linha result), no
formato copiado de uma sessão real — **proveniência anotada, nunca de memória** (regra da casa
para fixture de skill de terceiro).
**Onde:** `bin/sdd` (`run_phase`), stubs em `tests/` (grep por `output-format` os acha),
`tests/check-autonomy.sh`/`check-dry-run.sh` conforme os stubs tocados.
**Como (TDD):** asserção primeiro: depois de uma fase stub, `<FASE>-*.stream.jsonl` existe com
≥2 linhas E o ledger tem os MESMOS campos de custo/sessão de antes (diferencial contra o
comportamento pré-mudança, guardado no fixture).
**Check:** `bash tests/run-all.sh` → verde; `ls .sdd/logs/<missão>/*.stream.jsonl` num run stub →
existe e cresce durante a sessão.
**Sensor durável:** a asserção de paridade de campos + o arquivo de stream nos fixtures.
**Reversível por:** revert do commit — o formato antigo volta inteiro.

## Riscos e não-feitos

| Risco | Probabilidade | Mitigação |
|---|---|---|
| I10 quebra o parse do resumo em sessão real (stream-json difere entre versões do CLI) | média | o stub é copiado de sessão real com proveniência; se o parse real falhar, o incremento reverte sozinho (uma fatia) e o item volta ao TODO.md com o aprendido |
| O lint estendido (I6) achar mais que SC2318 em máquinas com shellcheck mais novo | baixa | medido hoje: 2×SC2318 e nada mais; se aparecer, consertar ou justificar por diretiva no arquivo, nunca baixar o `-S` |
| I9 mudar contagens que o `check-autonomy` já fixa (3× vira 1×) | certa — é o objetivo | as asserções existentes que afirmam `3×` no regime antigo são ATUALIZADAS no mesmo commit, com o porquê no corpo |
| Suíte passa de 33 s com as asserções novas | alta | aceito; o alvo de régua tem item próprio em "Custo e escala" — não cortar mutação para compensar |
| Um item se revelar já-resolvido além do gate_DOCS | baixa | I1 cobre: fecha por hash, o incremento correspondente vira no-op declarado nas Notas |

## Verificação end-to-end

Com todos os incrementos `done`: `grep -c '### Runner — defeitos e dívidas' TODO.md` → `0` (a
seção inteira saiu — itens consertados apagados citando hash, nenhum sobrevivente sem decisão);
`bash tests/run-all.sh` → verde com score ≥ 30+5 novos mutantes; `./bin/sdd health` → verde
(catálogo e health cobram as mutações novas); `./bin/sdd autonomy` → tabela com as linhas desta
missão. O PR final lista os 11 itens e o destino de cada um.
