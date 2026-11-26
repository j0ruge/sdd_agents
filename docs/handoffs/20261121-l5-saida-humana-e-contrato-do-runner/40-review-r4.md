---
missao: 20261121-l5-saida-humana-e-contrato-do-runner
fase: REVIEW
rodada: 4
status: done
sessao: 01a2181c-1856-7cb0-86fb-e86b958ef878
data: 2026-11-26 11:03
gate: "tests/run-all.sh em 956004b1576630dba29b2ba6e687bd0852294211 deu rc 0, 21 etapas, 2490 linhas ok, 0 linhas FAIL, 960 s e suite green. REVIEW não fecha. R6 pending, Type Safety caiu de A para B na revisão completa, Code Quality (Zen) e Test Coverage ficaram em B. Na entrada, só checkpoint-notas.md tinha 260 inserções preexistentes, preservadas fora do commit."
reviewed_head: 956004b1576630dba29b2ba6e687bd0852294211
---

# Review — rodada r4 — L5 — saída humana e contrato do runner

## TL;DR

A revisão completa confirmou o R5 e encontrou dois defeitos. O fechamento confunde um
exemplo de resolução com uma prova, e o alocador conta diretórios como arquivos de ADR.
Os dois achados vão para R6. Nenhum código foi alterado.

## Nota da rodada

`codereview:codereview` em modo FULL, com preset Bash, sobre
`origin/main...HEAD` no intervalo `a6fff8e9993aac14a80bd9c9bfb244e0c2478743` → `956004b1576630dba29b2ba6e687bd0852294211`.
O merge `956004b` mudou apenas `TODO.md` e `tests/health-baseline.txt` em relação ao primeiro pai.
A análise do diff não ficou limitada ao merge nem ao delta da r3. Foram 48 caminhos fora das
notas, com 3.796 inserções e 271 remoções. A QA em [disco](30-handoff-qa.md) cobriu a CLI no
fluxo nominal, inclusive as duas provas de resolução, sem caso de citação em linha ou entrada
de outro tipo no Git.

### Detecção de credenciais

| Estado | Ocorrências | Evidência |
|---|---|---|
| PASS | 0 | Regex e Gitleaks, sem erros, sobre as 3.796 linhas adicionadas em 48 arquivos. O caminho das notas foi excluído. |

### Qualidade, tipos, erros e impacto

Os 13 arquivos Bash na revisão foram `bin/sdd`, `bin/sdd-link-agents`, `bin/sdd-worker`
e os sensores `tests/check-{adr,coordination,gates,hat,kaizen,mutation,preflight,templates,todo,worker}.sh`.
Arquivos grandes foram lidos nas regiões tocadas e nos chamadores diretos. A revisão cruzou
a CLI e os sensores com README, guias de operação, ADR 0025, backlog, chapéus e espelhos, comandos,
templates e artefatos da própria missão. O desvio de tipo está na interpretação de texto como
registro e de árvore Git como arquivo. Os dois defeitos ocorrem em chamadas sequenciais sem
rede. A CLI de fechamento não edita o backlog. A rotina nova de alocação lê uma árvore por ref,
e as provas de ancestralidade usam Git local. No SHA revisado, `bash /tmp/sdd-l5-review.VHrOu4/perf.sh` mediu
três chamadas de `sdd adr new --slug next --dry-run` com 159 refs em Git descartável.
As três deram rc 0 e 0,76 s, 0,63 s e 0,59 s. Isso mede o custo na fixture, não uma base
grande ou operação em produção. Não houve teste com app real.

### Cobertura de testes

| Superfície | Provas nesta rodada |
|---|---|
| Runner e worker | A suíte mede aviso de base, status sem trava e sem reescrita do índice, indicações de próximo passo e fechamento com e sem JIRA. |
| Instalação e migração | R4 → `1 1 1` e R5 → `1 1`. Os controles distinguem retomada após falha, conteúdo local, links rastreados e destinos absolutos com a mesma raiz. |
| Alocação e prova de resolução | Os Checks anteriores têm controles de refs, worktree, Git sem `-z`, resolução malformada e ref homônima. Os dois casos reproduzidos abaixo não estão nesses controles. |

`tests/run-all.sh` no SHA `956004b1576630dba29b2ba6e687bd0852294211` → rc 0, 21 etapas, 2490 linhas `ok`, 0 linhas `FAIL`, 960 s, com `suite green`. Os 22 Checks com asserções ancoradas no [checkpoint](checkpoint.md) anterior à r4
foram conferidos no log da suíte e, nas células mistas do I3 e I6, nos arquivos de
documentação que elas leem. I3 → `1 1` e I6 → `1 2`.
O Check I18 devolveu `17`. `bash tests/check-todo.sh --check TODO.md` e
`bash tests/check-todo.sh --anchors TODO.md` deram 96 achados válidos, zero fora do alvo e
a catraca em 96. `./bin/sdd adr check --mission 20261121-l5-saida-humana-e-contrato-do-runner --phase plan` validou a referência
de ida e volta. Os seis espelhos coincidem. A suíte validou 1.017 âncoras do catálogo,
mas o catálogo integral de mutação não foi executado.
Log e RC da suíte em `/tmp/sdd-l5-review.VHrOu4/suite.log` e `/tmp/sdd-l5-review.VHrOu4/suite.rc`.

### Sincronismo da documentação

O guia PLAN-only descreve a migração e a exceção da cópia regular idêntica. O guia do pipeline
distingue as duas provas e documenta o retorno à base sem JIRA. O resumo de `sdd close` na
ajuda ainda fala só de JIRA, lacuna já registrada na r1. O handoff do EXEC descreve um reteste
delta, mas o merge posterior e o boot desta sessão exigiram FULL. A regra de duas provas no
`CLAUDE.md` continua pendente da mudança reservada ao dono.

### Código morto e limpeza

A varredura de símbolos e consumidores não encontrou código introduzido sem uso nem referência
órfã. Foi feita por busca textual no repositório para o diff, sem ampliar a código morto
preexistente.

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | B | O parser de resoluções confunde citação em linha com registro e leva o fechamento a recomendar a remoção de um achado aberto. |
| Type Safety | B | A leitura das refs descarta o tipo da entrada Git e aceita um diretório como ADR. A saída pode ter cinco dígitos e falhar na checagem do próprio kit. |
| Error Handling | A | A retomada após falha de escrita e o fallback para Git sem saída NUL passaram nos casos contratados. O erro do alocador aqui é de classificação em uma leitura bem-sucedida. |
| Security | A | Não foram detectadas credenciais. Os defeitos medidos são de integridade dos dados locais, sem escrita no backlog nem alteração de autoridade. |
| Performance | A | As leituras novas ficam em Git e arquivos locais. Não foi identificado gargalo novo no escopo revisado. |
| Test Coverage | B | A suíte cobre as regressões anteriores, mas não a prova vinda só de exemplo em linha nem a entrada de diretório no máximo das refs. |
| Documentation | B | O guia cobre o pós-merge sem JIRA, mas a linha da ajuda ainda omite esse caminho, já registrado no backlog. |
| **Overall** | **B** | O R5 avançou em um commit verificável. Dois achados funcionais do diff completo ainda impedem o aceite. |

## Achados da rodada

| # | Severidade | Achado | Onde |
|---|---|---|---|
| 1 | MEDIUM | `sdd close` recomenda remover um achado sem conserto porque um exemplo em código em linha contém um hash ancestral da base. | `tests/check-todo.sh:523`, `bin/sdd:13983` |
| 2 | LOW | `sdd adr new` trata uma árvore chamada `NNNN-nome.md` em outra ref como ADR. Um único diretório pode fazer a CLI reservar um ID que ela não aceita. | `bin/sdd:9711`, `bin/sdd:9733` |

**Reprodução no HEAD revisado.** `bash /tmp/sdd-l5-review.VHrOu4/probes.sh` → rc 0 no diagnóstico.
A saída está em `/tmp/sdd-l5-review.VHrOu4/probes.log`. Cada cenário usa Git descartável, sem JIRA, servidor
ou PR real.

1. Num backlog que passou em `--check` com dois itens, o primeiro tinha só um exemplo de
   mensagem em crases, com a forma `RESOLVED by <hash> como exemplo`. O segundo tinha um registro
   real com o mesmo hash. `--resolved` imprimiu as duas linhas e `sdd close` afirmou que os
   dois itens podiam sair. O hash era de um commit local ancestral de `main`. O primeiro item
   não tinha registro fora das crases e o arquivo ficou intacto.
2. Com apenas o ADR `0001-one.md`, uma branch lateral continha o diretório
   `docs/adr/9999-directory.md/`. `git ls-tree` mostra `040000 tree`. Em `main`, o dry run
   disse que o 9999 estava em uso nessa ref e propôs 10000. A chamada real criou
   `docs/adr/10000-real.md` e `sdd adr check` devolveu rc 1 por nome fora de `NNNN-slug.md`.
   Retirados o arquivo gerado e a ref lateral do repositório descartável, o dry run propôs 0002.
   A falha não depende de exaurir IDs válidos.

## Incrementos de conserto (R<n>)

| R<n> | Achado | Check escrito no checkpoint |
|---|---|---|
| R6 | Achados 1 e 2 da r4 | `t=$(bash tests/check-todo.sh --selftest 2>&1); g=$(bash tests/check-gates.sh 2>&1); a=$(bash tests/check-adr.sh 2>&1); echo "$(grep -c '^  ok    rule: --resolved distinguishes inline examples from resolution records' <<< "$t") $(grep -c '^  ok    sdd close lists the real resolution and omits its quoted example$' <<< "$g") $(grep -c '^  ok    adr new does not count a directory named like an ADR on another ref$' <<< "$a")"` → `1 1 1` |

## O que virou incremento

Linha acrescentada ao [checkpoint](checkpoint.md).

| R6 | Achados 1 e 2 da r4 — ignorar exemplos de resolução e entradas que não são arquivos de ADR | `t=$(bash tests/check-todo.sh --selftest 2>&1); g=$(bash tests/check-gates.sh 2>&1); a=$(bash tests/check-adr.sh 2>&1); echo "$(grep -c '^  ok    rule: --resolved distinguishes inline examples from resolution records' <<< "$t") $(grep -c '^  ok    sdd close lists the real resolution and omits its quoted example$' <<< "$g") $(grep -c '^  ok    adr new does not count a directory named like an ADR on another ref$' <<< "$a")"` → `1 1 1` | pending | — |

- R6 agrupa os dois ajustes locais. No selftest do backlog, compare a saída exata de um
  exemplo em crases e de um registro real. No reteste da CLI, preserve o controle positivo,
  exija que só ele seja listado e verifique que o backlog não muda. No sensor de ADR, use um
  diretório com forma de ADR numa ref lateral e um ADR real nessa mesma ref. A proposta deve
  avançar apenas após o arquivo real e continuar nomeando a ref. As três âncoras novas deram
  `0 0 0` no log do HEAD e o vermelho funcional foi reproduzido separadamente.
- R5 da r3 fechou em `6ac31be`. O Check desta rodada deu `1 1` para a retomada da migração
  interrompida e a preservação do par local. R4, em `b23f936`, deu `1 1 1`. Os hashes de
  R1 (`21482a2`), R2 (`4376e32`) e R3 (`234b734`) também estão no HEAD e seus Checks foram
  medidos na suíte.

## O que foi refutado

- **Uma cópia regular versionada idêntica deveria necessariamente continuar no índice.**
  O probe confirmou que ela é convertida em link e sai do índice. Esse é o caso previsto no
  I2 do plano e na exceção expressa do guia PLAN-only. O R1 preserva cópias conflitantes, e
  o R5 protege links rastreados, inclusive para o kit ativo. Não se trata da perda do R1.
- **Uma ref individual ilegível deveria impedir toda alocação.** O ADR 0025, decisão 1,
  manda seguir sem a contribuição da ref que Git não consegue ler. O achado 2 usa uma ref
  legível e exige que os tipos já disponíveis na leitura sejam respeitados, sem mudar a
  política para refs ilegíveis.
- **O teste de citação exclui indevidamente o juiz do kit.** A exclusão
  em `tests/check-hat.sh:1741` é expressa em “Fora de escopo” e na decisão 16 da missão.
  O chapéu do juiz não é um chapéu de alvo e não entrou no I17. O probe mede esta superfície,
  e não as citações internas do kit.

## Achados fora de escopo

Nenhum achado novo inscrito no backlog. Permanecem os registros anteriores da reserva
concorrente de ADR, do fallback por linhas com LF no caminho e da descrição da ajuda de
`sdd close`. Não foi baixada a catraca nem foi feita a limpeza pós-merge dos 17 itens.

## Pendências / Decisions for a Human

A nota de Type Safety caiu de A para B no recorte FULL. O problema de tipo é do I1, não do R5.
Code Quality (Zen) e
Test Coverage ficaram em B. Error Handling subiu com o R5. O gate não fecha e reavaliar
o mesmo código não ajuda. Um novo giro de REVIEW exige o R6 comprovado pelo EXEC.
Nenhuma decisão de produto nova. Permanecem as escolhas delegadas a levar ao PR e a mudança
reservada ao dono em `CLAUDE.md`, da [missão](00-missao.md#pendências-para-o-humano).

## Boot da próxima fase

Comece pelo R6 no [checkpoint](checkpoint.md) e pelos dois controles da reprodução.
Crie o vermelho nos sensores nomeados antes de modificar código. Preserve R1–R5 e I1–I18.
Se houver nova REVIEW delta, use o `reviewed_head` deste relatório. O merge de entrada trouxe
só backlog e catraca. As 260 inserções de notas preexistentes ficam fora do commit. Apenas a
linha desta rodada foi acrescentada e incluída.

### Ações recomendadas

- **CRITICAL** — nenhuma.
- **HIGH** — nenhuma.
- **MEDIUM/LOW** — fechar R6 e manter os controles positivos de resolução e de alocação.
- **Prosa** — não reabrir um incremento para a ajuda já registrada.
- **Fora de escopo** — nenhum novo registro.

_Pegada de custo — codereview 2.27.38 carregada pelo caminho do boot, instalação Claude
2.30.2. Cinco verificações de código por arquivo ou grupo, duas de documentação e uma
varredura de referências, todas com gpt-6.1-terra. Dez leituras integrais e de duas a 13
chamadas por agente, pelos contadores reportados. Sem custo monetário aferido._
