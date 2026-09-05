# A dieta de contexto — o boot manda um orçamento, o runner aplica, o artefato prova (2026-09-04)

> Spec da missão 2 do roteiro do kit, escrita com o humano presente, no dia em que o PR #37 (a
> faxina do backlog) e o PR #140 do `sales_quote` (os espelhos da fronteira) foram mergeados.
> Fecha a dívida da **seção 3** da rule [`anatomia-do-agente.md`](../../../.claude/rules/anatomia-do-agente.md)
> ("Gestão de contexto"). Não fecha linha nenhuma do `sdd health --release` — segue 2 de 6.
>
> Todo número aqui foi **medido**, e o instrumento que os mede entrou antes de qualquer corte
> (I1, commits `7eac87e` e `5b6d6ca`). Base: `main` = `314de35`, branch `feat/a-dieta-de-contexto`.

---

## 1. O problema, na frase da rule

> *A sessão lê o que o boot manda, e o boot manda **um orçamento**: as últimas N notas do
> checkpoint, o último handoff, nunca as rodadas anteriores inteiras.*

Isso é a regra-alvo. O que existia era o contrário: o `boot_prompt()` mandava ler `00-missao.md`,
`01-plano.md`, o `checkpoint.md` **inteiro**, "o handoff mais recente" (sem dizer qual) e o
diretório de templates **inteiro**. A missão de 2026-09-02 custou US$ 174, com 76% num laço de
revisão sem achado funcional.

## 2. Antes — a baseline, medida em 2026-09-04

### 2.1 O que as sessões releram

| | kit `20260901-o-revisor-so-acha` | alvo `20260902-o-rascunho-legado-fala-cru` |
|---|---|---|
| relido de `docs/handoffs/` | **2 494 272 B** | **1 688 679 B** |
| diretório em disco | 327 KB | 281 KB |
| **`checkpoint.md`** | **1 114 571 B — 160 leituras — 44,7%** | **574 311 B — 99 leituras — 34,0%** |
| `01-plano.md` | 358 894 B — 23 | 306 850 B — 17 |
| `00-missao.md` | 336 289 B — 29 | 194 540 B — 22 |
| `20-handoff-exec.md` | 206 495 B — 72 | 122 074 B — 59 |

Comando: `sdd census <missão>`. O censo por arquivo nomeia **99,96%** do agregado `handoff_read`;
o resto é o limite declarado no cabeçalho do `census_files` (token de comando truncado fora do
charset ASCII).

**Os itens 1–3 do boot são 72,6% de tudo que a missão releu.** Não é "os artefatos incharam" — é
a lista de leitura que o runner dita.

### 2.2 O boot bill

| | último handoff | pior ponto |
|---|---|---|
| kit `20260901-o-revisor-so-acha` | 170 187 B (`50-pr.md`) | **214 222 B** (`20-handoff-exec.md`) |
| alvo `20260902-o-rascunho-legado-fala-cru` | 121 270 B | — |

Decomposição do kit: `00-missao.md` 12 645 + `01-plano.md` 33 114 + `checkpoint.md` 97 865 +
handoff + `templates/` 20 957.

Dos 97 865 B do `checkpoint.md`, **67 166 B (69%) são a seção `## Notas de execução`** — 128 notas,
média de 524 B cada.

### 2.3 A medição que refutou a premissa do brainstorming

O handoff do brainstorming supunha que `Edit` exige `Read` prévio, e por isso toda sessão releria
o checkpoint inteiro. Medido nos dois regimes:

| Regime | `Edit` sem `Read` prévio |
|---|---|
| sessão **interativa** | **passa** — provado em arquivo que a sessão nunca tocou por via nenhuma |
| `claude -p` **headless**, `--permission-mode acceptEdits` | **recusado**: *"File has not been read yet. Read it first before writing to it."* — arquivo intocado, `denials=0` |

O regime de toda fase do `sdd` é o headless, então a premissa está **certa** — mas por um fio, e a
medição interativa dizia o oposto. Custo do probe: US$ 0,045.

⚠️ **Lição que vale além desta missão: intuição colhida em sessão interativa não transfere para a
fase.** É a mesma classe do "fixture escrito de memória" que o `CLAUDE.md` já proíbe.

Consequência para o desenho: enquanto tabela e notas moram no mesmo arquivo, existe um **piso
mecânico de uma releitura inteira por sessão** que nenhuma instrução de boot remove. Mas o piso é
**1**, e o `checkpoint.md` foi lido **6,2× por sessão de EXEC** (111 em 18). Os outros 5,2 são o
item 3 do boot mandando reler — e esses o boot corta.

## 3. O alvo (decisão humana, e ele não se move)

**`boot bill` ≤ 105 000 B, cobrado no PIOR PONTO da missão.**

Vinculante. `handoff_read` por sessão de EXEC e a fatia do `checkpoint.md` entram como evidência
reportada, **sem poder de veto** — uma razão pode ser "atingida" por outra coisa inchar, que é o
modo de falha que o `KAIZEN_LOG.md` nomeia.

Por que o pior ponto: "o handoff mais recente" depende do estado em que o disco por acaso está.
Numa missão fechada ele resolve para `50-pr.md`, o menor artefato que a missão produziu — 44 KB
de diferença no número contra o qual o mesmo desenho é julgado.

⚠️ **Risco de instrumento, declarado antes do corte.** O `boot bill` hoje conta arquivos inteiros
porque é isso que o boot aponta; depois dos cortes ele contará fatias inlinadas. A definição que
vale nos dois mundos é **"bytes que o prompt de boot faz a sessão ingerir"**, apontando ou
inlinando. O "antes" está congelado nas mensagens de `7eac87e` e `5b6d6ca`, escritas antes de
qualquer corte existir.

## 4. O desenho

Princípio que atravessa tudo: **o boot manda um orçamento; o runner o aplica (determinístico); o
artefato prova (`sdd census`)**. Frase no prompt sem sensor é lembrete, não regra (princípio 1).

| ID | O quê | Onde |
|---|---|---|
| I1 ✅ | o instrumento: `sdd census` por arquivo, `boot bill` (último e pior ponto), `cache_read` no ledger | `7eac87e`, `5b6d6ca` |
| I2 | as notas saem do `checkpoint.md` para `checkpoint-notas.md`; `BOOT_NOTES_TAIL=10`; o boot inlina as últimas 10 e manda **não** ler o arquivo | `boot_prompt()`, writer da `- intervention:`, leitor do `sdd autonomy`, templates, agentes |
| I3 | o boot **nomeia** o handoff mais recente e inlina só `## TL;DR` + `## Boot da próxima fase`; teto de **20 linhas** no TL;DR cobrado pelo gate da fase que o escreve | `boot_prompt()`, `gate_<FASE>` |
| I3b | o boot nomeia o **template da fase** em vez do diretório inteiro | `boot_prompt()`, novo mapa fase→template |
| I4 | linha de sensor no `sdd preflight`: bytes de `CLAUDE.md` + `.claude/rules/*.md` do alvo — **nunca `_fail`** | `cmd_preflight` |
| I5 | a frase dos subagentes sai do executor; `Agent` no `disallowedTools:` **do executor** | `agents/sdd-executor.md`, `bin/sdd:1634` |
| I6 | `sdd boot <missão> <FASE>` read-only; probes headless; docs, kaizen, carimbo, PR | — |

### A aritmética do alvo

Medida no pior ponto do kit, que é o boot da REVIEW contra o `20-handoff-exec.md`:

| Item | hoje | depois | de onde sai o "depois" |
|---|---|---|---|
| `00-missao.md` | 12 645 | 12 645 | não é tocado |
| `01-plano.md` | 33 114 | 33 114 | não é tocado |
| `checkpoint.md` | 97 865 | **30 699** | o arquivo sem a seção de notas, medido |
| últimas 10 notas inlinadas | — | **+5 044** | as 10 últimas notas reais, medidas |
| handoff `20-handoff-exec.md` | 49 641 | **10 432** | TL;DR capado em 20 linhas (1 603) + `## Boot da próxima fase` (8 829), medidos |
| `templates/` | 20 957 | **9 012** | `review.md` + `handoff.md`, os que a REVIEW escreve |
| **total** | **214 222** | **100 946** ✓ | margem de 4 054 B (3,9%) sobre o teto |

Sem o I3b (templates) o mesmo desenho dá **112 891 B** — acima do teto. A quinta alavanca é o que
faz o alvo ser cumprido em vez de perdido por 7,5 KB.

⚠️ **Limite declarado (D15), medido e não corrigido nesta missão:** depois do corte, a seção
`## Boot da próxima fase` (8 829 B, 112 linhas) passa a ser o **terceiro maior termo do boot**, e o
teto do I3 não a toca — ele cobra só o `## TL;DR`, que é 2 994 B em 38 linhas. O alvo é cumprido
sem mexer nela, então ela não entra: capá-la é candidata a missão futura, e está escrita aqui em
vez de calada porque dívida calada é o fail-open que a régua do D15 separa de limite.

### Por que a separação estrutural do I2, e não uma frase no boot

A alternativa barata ("leia a tabela; as últimas N notas estão abaixo; não leia a seção") depende
de disciplina do modelo, e § 2.3 mostrou que ela também não remove o piso mecânico: o executor
**edita** o checkpoint no fim de toda sessão, e no headless `Edit` exige `Read`. Com as notas num
arquivo próprio, escrever nota vira `printf >>` — **zero leituras** — e o corte deixa de ser
instruído para ser **impossível de errar**.

Leitores que mudam no mesmo commit, aceitando **os dois mundos** (arquivo de notas se existe,
senão a seção — missões antigas não migram): o writer da `- intervention:` do runner, o leitor do
`sdd autonomy`, `templates/checkpoint.md`, `docs/pipeline.md`, os agentes que escrevem nota,
`tests/check-checkpoint.sh` e `check-templates.sh`.

## 5. O que esta missão deliberadamente NÃO corta

- **O `CLAUDE.md` do repo-alvo.** São ~52K tokens (73%) do prefixo fixo, e o kit não corta o livro
  de regras de ninguém — I4 é **sensor**, nunca corte. Fixado pela spec da fronteira (`:86`).
- **As 318 pendências de handoff sem rota** (`CONTEXT.md:125`, `:142`). É a rule 5 (memória), não a
  rule 3 (contexto). As duas mudam de dono **por escrito** para a triagem do `sdd kaizen` /
  missão 3 — o oposto de deixar apodrecer sob um rótulo que aponta para uma missão que já chegou.
- **`--autocompact`.** A janela não estoura: zero compactações medidas. O problema é a conta, não
  a janela. `docs/pipeline.md:606-619` ("Context is not the bottleneck") é verdade sobre a JANELA e
  enganoso sobre a CONTA — reconciliado no I6, não apagado.
- **`sdd digest` para o vault Obsidian**, a linha 4 do `--release` (missão 3), `docs/pipeline.md`
  43% num subsistema.
- **Uma célula de `cache_read` em `sdd autonomy --by-mission`.** O campo está na linha do ledger,
  que era a dívida real; a view humana é conforto, e `TODO.md:656-660` já registra que nem `turns`
  aparece nela. Limite declarado (D15), não achado novo.

## 6. Como o "depois" é provado

1. **`boot bill` no pior ponto** — estático, determinístico, grátis, zero sessão. É o alvo.
2. **`sdd boot <missão> <FASE>`** (I6, read-only) imprime o `boot_prompt()` sem abrir fase. Sem
   ele, os probes precisariam do prompt reconstruído **de memória** — o fixture imaginado que o
   `CLAUDE.md` proíbe, e que já custou três bugs de gate.
3. **Probes headless com haiku** (~US$ 0,15–0,50 cada), antes/depois de I2/I3/I3b, para EXEC e
   REVIEW: bytes sob `$HANDOFF_DIR` pelo mesmo `jq` do censo, e o prefixo do 1º turno. Evidência
   de apoio; o dólar real da missão fica para a **janela 4**, declarado.

## 7. A janela 4

A janela 3 foi declarada partida (`indeterminado`, emenda da D22). A janela 4 abre no `kit_sha`
que a **primeira missão do `sales_quote`** carimbar. Consequência aceita: ela julga o **pacote**
D22 + anatomia + fronteira + dieta. O juiz compara fatias por sha; a atribuição fina é limitada e
fica escrita na entrada do `KAIZEN_LOG.md`.

⚠️ O I5 mexe num `agents/*.md`, o que deixa o espelho do `sales_quote` stale. **Um segundo PR de
espelho lá** (`sdd install --force`, nunca `cp`) antes da primeira missão do alvo.
