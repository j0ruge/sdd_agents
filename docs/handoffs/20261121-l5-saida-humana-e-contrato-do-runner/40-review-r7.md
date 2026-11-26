---
missao: 20261121-l5-saida-humana-e-contrato-do-runner
fase: REVIEW
rodada: 7
status: done
sessao: 01a218ef-8ac2-7ba3-95e9-22e4cb1ca027
data: 2026-11-26 14:58
gate: "tests/run-all.sh em 7824ed81f6c0fdb4e0cca7d352e2c89a128cce86 deu rc 0, suite green, 21 etapas, 2498 linhas ok, 0 linhas FAIL, 1156 s. R8 1 1, R7 1 1, R6 1 1 1. Todos os critérios estritos em A. Documentation caiu de A para B por dois achados de prosa e Overall segue em B, ambos aceitos pelo gate. Nenhum R9. Na entrada só checkpoint-notas.md, 263 inserções locais mantidas fora do índice."
reviewed_head: 7824ed81f6c0fdb4e0cca7d352e2c89a128cce86
---

# Review — rodada r7 — L5 — saída humana e contrato do runner

## TL;DR

O delta confirma o R8 de `2defd63`. No ensaio de 1.000.000 de linhas vazias,
o leitor e o `sdd close` passaram de 10 s excedidos para menos de 1 s, com
as mesmas duas provas e os bytes do backlog intactos. A suíte passou.
Dois achados de prosa foram para o backlog. Nenhum incremento novo.

## Nota da rodada

**Escopo.** `/codereview:codereview base=2ab5f3469f61c2db62bbd83d4f86a7d804274c8b` aplicado em `7824ed81f6c0fdb4e0cca7d352e2c89a128cce86`.
A base é ancestral do HEAD. Dos seis caminhos no delta, dois são código Bash,
três são artefatos de missão verificados nos trechos alterados e o arquivo de
notas foi excluído da revisão de conteúdo. A QA original andou o pós-merge em
Git descartável. Esta rodada retestou o leitor e a mesma jornada afetada, sem
app, JIRA ou PR real.

### Segredos

| Estado | Ferramentas | Achados | Erros |
|---|---|---|---|
| PASS | regex, gitleaks | 0 | 0 |

### Cobertura, integridade e código morto

| Superfície | Prova no delta |
|---|---|
| `tests/check-todo.sh` | O selftest compara TSV exato e bytes nas entradas curta e longa. O piso passou a 20 regras. |
| `tests/check-gates.sh` | A jornada do `close` exige 999.999 linhas a mais, rc 0, listagem idêntica e backlog intacto. O oráculo fixo do R7 é verificado antes. |
| Prosa | `20-handoff-exec.md`, `checkpoint.md` e `40-review-r6.md` passaram por verificação de evidência. Os dois desvios estão abaixo. |
| Código morto | Varredura inline no delta. O leitor continua no mesmo ramo e não há função, interface ou chamador órfão. Varredura de dívida anterior não solicitada. |

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | A | A deduplicação atua no separador já usado pelo leitor. Não foi criado segundo parser nem novo caminho de listagem. |
| Type Safety | A | O último byte é lido com o índice de comprimento do corpo sob LC_ALL=C. A saída continua em três campos TSV, sem mudança na interface. |
| Error Handling | A | Os dois sensores tornam vermelho o rc 124 e verificam saída positiva, sem converter interrupção em sucesso. |
| Security | A | Pré-varredura sem credenciais. A ancestralidade foi provada em Git de rascunho e cada execução preservou o arquivo. |
| Performance | A | Com um milhão de linhas vazias, leitor e CLI caíram de pelo menos 10 s para 0,53 s e 0,74 s. A variante CRLF com espaços e tabs também ficou abaixo de 1 s. |
| Test Coverage | A | R8 passou nos dois sensores, R7 em dois e R6 em três. A restauração do leitor anterior reproduziu o prazo excedido nos dois caminhos. |
| Documentation | B | O handoff ficou uma linha atrás da tabela e a r6 não preservou a saída com quatro tempos intermediários. A prova do limite principal pôde ser refeita. |
| **Overall** | **B** | O R8 fechou nos dois caminhos e a suíte passou. Restaram dois desvios no registro em prosa, sem efeito funcional ou novo incremento. |

## Achados da rodada

| # | Severidade | Achado | Onde |
|---|---|---|---|
| 1 | LOW | O inventário do handoff manteve 25 linhas `done` depois que o R8 elevou o total a 26. | `20-handoff-exec.md:110` |
| 2 | LOW | Os TSVs preservados dos ensaios intermediários da r6 não trazem os quatro tempos exatos que o relato cita. | `40-review-r6.md:86` |

- **1.** `awk -F'|' '$2~/^ (I|R)[0-9]+ $/ && $5==" done "{n++} END{print n+0}' docs/handoffs/20261121-l5-saida-humana-e-contrato-do-runner/checkpoint.md`
  deu 26 no HEAD. O mesmo comando sobre a tabela de `2ab5f34` deu 25.
  A descrição não acompanhou a nova linha. O status e o hash do R8 no checkpoint estão certos.
- **2.** `wc -l /tmp/sdd-l5-review-r6.tEsKk8/perf-{250000,500000}.md.{after,before}`
  mostrou três linhas por arquivo, todas TSV. Os logs de reprodução curta,
  longa e histórica nesse diretório não trazem os tempos desses dois tamanhos.
  Isso registra falta de evidência dos quatro valores, sem afirmar que eram
  incorretos. O caso de um milhão de linhas tem evidência e foi reproduzido abaixo.

## Incrementos de conserto (R<n>)

Nenhum. Os dois achados são de prosa e não alteram o código nem os Checks.

## O que virou incremento

- **R8 da r6**, fechado em `2defd6334fef3c06a4c377887748a7c425f2e50a`.
  `bash /tmp/sdd-l5-review-r7.AhVXIfxz/repro-r8.sh "$PWD"` extrai os dois SHAs
  do delta em cópias descartáveis, monta o mesmo Git com a prova ancestral da
  base e chama o leitor e a CLI com `timeout -k 2s 10s`.
  `--check` aceitou as três entradas. O teste compara os bytes após cada
  chamada e, quando ela retorna rc 0, compara as duas linhas de prova
  esperadas, com linha, hash, título e base na CLI. O exemplo com o mesmo
  hash é omitido.

| Entrada | Leitor na base do delta | CLI na base do delta | Leitor no HEAD | CLI no HEAD |
|---|---|---|---|---|
| Curta, 550 bytes | rc 0 em 0,02 s | rc 0 em 0,15 s | rc 0 em 0,02 s | rc 0 em 0,17 s |
| 1.000.000 de vazias, 1.000.549 bytes | rc 124 em 10,00 s | rc 124 em 10,01 s | rc 0 em 0,53 s | rc 0 em 0,74 s |
| CRLF com espaço e tab, 3.000.563 bytes | Não ensaiado | Não ensaiado | rc 0 em 0,73 s | rc 0 em 0,88 s |

- `tests/run-all.sh` em `7824ed81f6c0fdb4e0cca7d352e2c89a128cce86` deu rc 0, `suite green`, 21 etapas, 2498 linhas `ok`, 0 linhas `FAIL` e 1156 s. Check R8 `1 1`, R7 `1 1` e R6 `1 1 1`. A saída e o rc estão em `/tmp/sdd-l5-review-r7.AhVXIfxz/suite.log` e
  `/tmp/sdd-l5-review-r7.AhVXIfxz/suite.rc`. A reprodução independente está em
  `/tmp/sdd-l5-review-r7.AhVXIfxz/repro.log`. `bash -n` e `shellcheck -S warning` também
  passaram nos dois arquivos Bash do delta.
- Os logs de sabotagem do EXEC mostram que recolocar a acumulação fez os
  dois sensores falharem por prazo. Reduzir as entradas, mudar a prova e
  alterar o backlog derrubaram os respectivos sensores. Apagar a fronteira
  fez os oráculos fixos do R7 falharem, inclusive na CLI, em que apenas a
  comparação diferencial do R8 ainda ficaria verde.
  Evidência em `/tmp/sdd-l5-r8-mutations.log` e `/tmp/sdd-l5-r8-test-mutations.log`.

## O que foi refutado

- **O caso longo poderia estar verde com uma prova a menos ou sem preservar o arquivo.**
  Na reprodução independente, as duas linhas de prova foram comparadas com
  uma expectativa fixa, inclusive posição física e hash Git. O `cmp`
  confirmou preservação em cada chamada. O leitor da base do delta e o do
  HEAD também deram os mesmos 21 TSVs, byte a byte, no backlog real.
- **A suíte do EXEC e a igualdade do TSV estariam sem evidência.**
  `/tmp/sdd-l5-r8-baseline.log` e `/tmp/sdd-l5-r8-final.log` terminam em
  `suite green`, com 21 etapas cada, 2496 e 2498 linhas `ok`, sem `FAIL`.
  `/tmp/sdd-l5-r8-final.seconds` traz 884,22 s. Os dois arquivos
  `/tmp/sdd-l5-r8-todo-before.tsv` e `/tmp/sdd-l5-r8-todo-after.tsv` têm
  21 linhas cada e `cmp` deu rc 0. São evidências do EXEC, separadas da
  nova execução desta rodada.
- **O `0 0` do R8 na r6 não seria verificável.** As duas buscas ancoradas
  do Check deram zero em `/tmp/sdd-l5-review-r6.tEsKk8/suite.log`, que contém
  2496 linhas `ok` e cujo `suite.rc` registra rc 0. Já o relato de que
  o EXEC não registrou achado novo no R8 descreve o registro de execução,
  sem alegar que aquele delta não pudesse ser revisto nem que a r7 não encontraria nada.

## Achados fora de escopo

- Os achados 1 e 2 de prosa foram registrados no [backlog](../../../TODO.md).
  A catraca acompanha apenas as duas inclusões. A contagem histórica de
  resoluções do I18 segue no item já aberto, sem recorrência duplicada.

## Pendências / Decisions for a Human

Nenhuma decisão nova. Performance e Test Coverage subiram de B para A
com o commit do R8. Documentation caiu de A para B e Overall ficou em B.
A queda ficou só na prosa tolerada pelo gate, sem abrir rodada nova.
Permanecem as pendências de aceite descritas na [missão](00-missao.md#pendências-para-o-humano).

## Boot da próxima fase

A próxima fase é DOCS se o runner confirmar os gates. Comece pela evidência
do R8 neste relatório e pelas métricas e pendências do [documento da missão](00-missao.md).
Não reabra os dois registros de prosa como incrementos de código.
Se uma mudança de código reabrir REVIEW, a base do delta é o `reviewed_head`
desta rodada. Na entrada havia 263 inserções locais apenas em
`checkpoint-notas.md` e nada preparado no índice. Só a linha desta
rodada foi acrescentada ao índice, sem incluir aquelas inserções.

### Ações recomendadas

- **CRITICAL** — nenhuma.
- **HIGH** — nenhuma.
- **MEDIUM/LOW funcional** — nenhuma.
- **Prosa** — manter os dois registros no backlog para triagem e não repetir
  os quatro tempos intermediários sem saída registrada.
- **Fora de escopo** — manter o Check histórico de I18 no item existente.

_Pegada de custo — codereview 2.27.38 no caminho solicitado, com a etapa
de verificação da instalada 2.30.2. Dois verificadores gpt-6.1-terra leram 71
unidades, com 4 e 20 chamadas reportadas. Análise do Bash e varredura inline.
Custo monetário não aferido._
