---
missao: 20261121-l5-saida-humana-e-contrato-do-runner
fase: REVIEW
rodada: 5
status: done
sessao: 01a21863-1d85-7182-adf4-3f57bba3c416
data: 2026-11-26 12:20
gate: "tests/run-all.sh em 1591328ec9e1558c413838e1f8540a2d7518a6cd deu rc 0, 21 etapas, 2494 linhas ok, 0 linhas FAIL, 935 s, suite green. REVIEW não fecha. R7 pending, Code Quality (Zen) e Test Coverage B. Type Safety passou de B para A. As 261 inserções locais das notas ficaram fora do commit."
reviewed_head: 1591328ec9e1558c413838e1f8540a2d7518a6cd
---

# Review — rodada r5 — L5 — saída humana e contrato do runner

## TL;DR

O R6 passou nos casos da r4. O delta ainda cruza limites de parágrafo ao parear crases,
o que faz o fechamento recomendar a remoção de um exemplo e omitir uma prova real.
O caso vira R7. Duas lacunas fora do delta do código foram registradas no backlog.
Nenhum código foi alterado.

## Nota da rodada

`codereview:codereview base=956004b1576630dba29b2ba6e687bd0852294211`, preset Bash genérico.
A base é ancestral de `reviewed_head`. O delta tem cinco commits, 12 caminhos, 336 inserções
e 29 remoções. A revisão funcional se limitou a `bin/sdd`, `tests/check-adr.sh`,
`tests/check-gates.sh`, `tests/check-hat.sh` e `tests/check-todo.sh`. A revisão leu a
[QA](30-handoff-qa.md), os retestes do [EXEC](20-handoff-exec.md), os achados da
[r4](40-review-r4.md) e a prosa alterada. A QA cobriu as duas provas na CLI e a preservação
do backlog, mas precede o mascaramento de exemplos em linha.

### Detecção de credenciais

| Estado | Ocorrências | Evidência |
|---|---|---|
| PASS | 0 | Regex e Gitleaks leram o diff de 12 caminhos e 336 inserções, sem erros. |

### Qualidade, tipos, erros e impacto

O novo filtro de tipos do alocador conservou o ADR regular executável com modo `100755`
e ignorou a árvore `040000`, o link `120000` e o arquivo aninhado. No Git descartável,
a proposta passou de `10000-next.md` na base do delta para `0009-next.md` no HEAD,
com a origem `refs/heads/other`. Três alocações com 159 refs levaram 0,579 s, 0,609 s e
0,598 s, todas rc 0. Refaça a medida com `bash /tmp/sdd-l5-r5-review.yE8XIE/adr.sh "$PWD"`.
O tratamento de uma ref que Git não lê continua o do ADR 0025. O defeito confirmado é de
interpretação da prosa. A CLI não reescreve o backlog e continua exigindo ancestralidade,
mas a orientação ao humano é incorreta quando a extração classifica o exemplo como prova.

### Cobertura de testes

| Superfície | Provas e limites |
|---|---|
| Suíte do checkout | `tests/run-all.sh` em `1591328ec9e1558c413838e1f8540a2d7518a6cd` → `rc 0, 21 etapas, 2494 linhas ok, 0 linhas FAIL, 935 s, suite green`. Logs em `/tmp/sdd-l5-r5-review.yE8XIE/suite.log` e `suite.rc` no mesmo diretório. |
| R6 e ajuda | Os três marcadores do Check R6 deram `1 1 1` na suíte. A ajuda também tem seu próprio marcador `1` em `tests/check-hat.sh`. |
| Limites de parágrafo | O selftest contém exemplos em linha e crases soltas, mas não uma linha vazia separando parágrafos do mesmo item. A CLI tem o controle nominal da r4 e não o caso de contagem inalterada com troca de itens. |
| Fecho dos 17 itens | `bash tests/check-todo.sh --resolved TODO.md` em `1591328ec9e1558c413838e1f8540a2d7518a6cd` retornou os 17 títulos da missão, cada um com o hash do incremento correspondente no checkpoint. A contagem bruta do I18 inclui uma resolução adicional, descrita no achado 3. Confira por título e hash com `python /tmp/sdd-l5-r5-review.yE8XIE/i18.py` → `17/17`. |

### Sincronismo da documentação

O [ADR 0025](../../adr/0025-ids-across-refs-and-the-second-proof-of-a-resolution.md) e o
[guia do pipeline](../../pipeline.md) distinguem prova em prosa e exemplo em código. No caso
do achado 1, a promessa é correta como contrato e a classificação em execução é que falha.
O trecho da CLI que só falava de JIRA foi corrigido em `269ecc7` e seu item de backlog recebeu
a resolução em `1591328`. A busca literal pela redação antiga encontrou o verbete ainda ativo
no README e a citação histórica da r1. Apenas o README é um achado de documentação.

### Código morto e limpeza

A varredura textual do delta não encontrou símbolos novos sem uso ou referências órfãs.
`mask_inline_code` é chamada em `emit_resolved`. A varredura de código preexistente ficou fora
do recorte.

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | B | O mascaramento cruza parágrafos e inverte dois vereditos na listagem real do fechamento. |
| Type Safety | A | O alocador distingue arquivos regulares, inclusive executáveis, de árvore e link, com controle para o máximo em outra ref. |
| Error Handling | A | Os caminhos contratados da suíte preservam as provas Git e o fallback. O caso novo é de classificação em leitura bem-sucedida. |
| Security | A | Os scanners não encontraram credenciais. O delta não amplia autoridade nem escreve no backlog durante o fechamento. |
| Performance | A | Três alocações com 159 refs ficaram abaixo de 0,61 s e o mascaramento atua no corpo do item. |
| Test Coverage | B | Os sensores R6 passam, mas não exercitam o limite de parágrafo que troca os itens sem trocar a contagem. |
| Documentation | B | A ajuda nova e o guia explicam o pós-merge. A cópia antiga permanece no README e está registrada fora do delta. |
| **Overall** | **B** | O R6 avançou e os 17 itens foram confirmados por título e hash. O fechamento ainda classifica incorretamente um backlog válido. |

## Achados da rodada

| # | Severidade | Achado | Onde |
|---|---|---|---|
| 1 | MEDIUM | Ao parear crases de parágrafos distintos, o leitor recomenda remover um item sem prova e omite outro item com prova válida. | `tests/check-todo.sh:518` e `:536` |
| 2 | LOW | O exemplo ativo no README ainda anuncia uma sessão paga de JIRA e não descreve a lista pós-merge. Só prosa e fora do delta. | `README.md:94` |
| 3 | LOW | O Check histórico de I18 mede a diferença da contagem global e passa a dar 18, embora os 17 itens da missão estejam corretos. A expressão não mudou no delta. | `checkpoint.md:68`, disparado por `TODO.md:831` |

**Reprodução do achado 1.** Em `1591328ec9e1558c413838e1f8540a2d7518a6cd`, `bash /tmp/sdd-l5-r5-review.yE8XIE/repro.sh "$PWD"`
montou um Git sem remoto e sem JIRA. O backlog passou no `--check` com cinco itens. Cada corpo
continha um valor de resolução igual, o SHA abreviado de um commit local ancestral da base.
Com o mesmo cabeçalho e a atribuição válidos, estes dois casos isolam a diferença.

```markdown
- [ ] **Exemplo no segundo parágrafo** — `.sdd/config.sh:1` (`DEFAULT_BRANCH`) — crase solta `

  `RESOLVED by HASH como exemplo` não é uma prova.
  — descoberto por `sdd-reviewer` (DATA)
- [ ] **Prova no segundo parágrafo** — `.sdd/config.sh:1` (`DEFAULT_BRANCH`) — crase solta `

  RESOLVED by HASH — outra crase solta `

  — descoberto por `sdd-reviewer` (DATA)
```

Substitua `HASH` por `git rev-parse --short=10 HEAD` de um commit já na base do repositório
descartável e `DATA` pela data da atribuição. Com `DEFAULT_BRANCH="main"`, `JIRA_ENABLED=false`,
um `00-missao.md` e sem PR ou upstream, rode `bash tests/check-todo.sh --resolved <backlog>`
e `bin/sdd close <missão>` no alvo, usando os caminhos absolutos do kit. CommonMark renderizou
a resolução do primeiro item como `<code>` em outro parágrafo, e a segunda como texto.
A saída do leitor e a do fechamento trouxeram `Prova simples` e `Exemplo no segundo parágrafo`.
A lista esperada tinha `Prova simples` e `Prova no segundo parágrafo`.
Os dois diffs de títulos deram rc 1, embora o `close` tenha saído com rc 0 e mantido
o arquivo byte a byte. A versão anterior também listava o exemplo, mas não escondia a prova
real. Os controles sem linha vazia, incluindo um span em continuação do mesmo parágrafo,
passaram no HEAD. O log do fixture fica com `repro.log` no diretório acima.

**Reprodução dos achados 2 e 3.** `git grep -n -A2 -F -- 'post-merge: close the JIRA issue' README.md`
mostrou a descrição antiga incluindo `a real paid session`. `./bin/sdd help` em `1591328ec9e1558c413838e1f8540a2d7518a6cd`
mostrou `post-merge: update the base, list TODO cleanup, and close JIRA when enabled`.
Para I18, a base de comparação `git merge-base HEAD origin/main` foi
`a6fff8e9993aac14a80bd9c9bfb244e0c2478743` com dois registros. A expressão
`grep -cE 'RESOLVED by [0-9a-f]{7,40}'` contou 19 em `269ecc7:TODO.md` e 20 em
`1591328:TODO.md`. Com a mesma base, o Check de I18 mudou de `17` para `18`.
O registro extra é do conserto da ajuda e não faz parte dos 17 títulos.

## Incrementos de conserto (R<n>)

| R<n> | Achado | Check escrito no checkpoint |
|---|---|---|
| R7 | Achado 1 da r5 | `t=$(bash tests/check-todo.sh --selftest 2>&1); g=$(bash tests/check-gates.sh 2>&1); echo "$(grep -c '^  ok    rule: --resolved keeps inline code within its paragraph' <<< "$t") $(grep -c '^  ok    sdd close distinguishes example and proof in separate TODO paragraphs$' <<< "$g")"` → `1 1` |

## O que virou incremento

Linha acrescentada ao [checkpoint](checkpoint.md).

| R7 | Achado 1 da r5 — distinguir exemplo e prova de resolução em parágrafos distintos | `t=$(bash tests/check-todo.sh --selftest 2>&1); g=$(bash tests/check-gates.sh 2>&1); echo "$(grep -c '^  ok    rule: --resolved keeps inline code within its paragraph' <<< "$t") $(grep -c '^  ok    sdd close distinguishes example and proof in separate TODO paragraphs$' <<< "$g")"` → `1 1` | pending | — |

- No selftest, exija saída exata com as provas e sem os exemplos. Cubra a linha em branco e
  mantenha o controle de código em linha que atravessa uma quebra simples dentro do parágrafo.
  Na jornada de `sdd close`, confirme os títulos e a prova de ancestralidade, não apenas a
  contagem. Exija também que o backlog fique byte a byte igual.
- R6 da r4 fechou em `0426916`. Confirmados `1 1 1` no log da suíte e os controles
  independentes da proposta `0009` e da resolução no mesmo parágrafo. Nenhum Check anterior
  foi reescrito. Os dois marcadores novos deram 0 0 no log do HEAD. I1–I18 e R1–R6 continuam `done` com os mesmos hashes.

## O que foi refutado

- **O filtro novo perderia o ADR executável.** `git ls-tree` mostrou `0008-executable.md`
  com modo `100755`, acima do arquivo regular `0007`. O dry run escolheu `0009` e nomeou o
  ref correto, mesmo com o diretório `9999` e o link `9998`.
- **O defeito demandaria mudar a prova Git ou a leitura de toda quebra de linha.** As duas
  linhas indevidas da classificação usam o mesmo hash ancestral. Em CommonMark e no leitor,
  o controle com quebra simples segue em código. O erro medido é a junção entre parágrafos.
- **O I18 perdeu um dos itens planejados.** O confronto por título e hash confirmou 17 de 17.
  Mudou a soma de todos os registros, não o conteúdo requerido.
- **A documentação do EXEC precisa de um conserto separado.** A lacuna apontada nas
  linhas 17 e 33–35 é o efeito do achado 1. A evidência histórica dos casos originais
  foi confirmada. A promessa de ignorar o exemplo adicional precisa do conserto funcional.

## Achados fora de escopo

- Achado 2 registrado em [TODO.md](../../../TODO.md) como “O exemplo de sdd close no README ainda promete
  uma sessão paga de JIRA”. O registro antigo é sobre a saída de `sdd help`, consertada e preservada.
- Achado 3 registrado no mesmo backlog como “O Check I18 do L5 conta resoluções de fora da missão”.
  A expressão histórica está fora do delta, então não virou incremento. A catraca acompanha as duas entradas.
- Permanecem os registros preexistentes para reserva concorrente de ADR e fallback de worktree com LF.
  Não houve limpeza pós-merge.

## Pendências / Decisions for a Human

Nenhuma decisão de produto nova. Permanecem as escolhas delegadas a levar ao PR e a mudança
reservada ao dono em `CLAUDE.md`, descritas na [missão](00-missao.md#pendências-para-o-humano).
A REVIEW não fecha enquanto R7 estiver pendente. Type Safety subiu de B para A com a prova
do R6. Code Quality (Zen) e Test Coverage seguem em B, sem queda de critério. Há movimento
para outra revisão depois de um conserto real, não sobre o mesmo SHA.

## Boot da próxima fase

Comece pelo R7 em [checkpoint.md](checkpoint.md) e pela reprodução acima. Crie o vermelho
nos dois sensores, preserve os controles do R6 e os anteriores e confirme a CLI sem mudar o
backlog. A próxima REVIEW delta parte de `reviewed_head` deste relatório. O checkout abriu
com 261 inserções locais em `checkpoint-notas.md`, deixadas fora do commit. Só a linha desta
rodada entrou no índice. Nenhum outro caminho local estava alterado na entrada.

### Ações recomendadas

- **CRITICAL** — nenhuma.
- **HIGH** — nenhuma.
- **MEDIUM/LOW** — fechar R7 com os dois controles e deixar o README e a contagem histórica no backlog.
- **Prosa** — nenhum incremento de reescrita.

_Pegada de custo — codereview 2.27.38 pelo caminho do boot, quatro análises por grupo e uma
varredura, todas gpt-6.1-terra. Os agentes reportaram de 1 a 9 chamadas e três arquivos
lidos integralmente. Custo monetário não aferido._
