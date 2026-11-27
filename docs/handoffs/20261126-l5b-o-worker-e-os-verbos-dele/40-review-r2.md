---
missao: 20261126-l5b-o-worker-e-os-verbos-dele
fase: REVIEW
rodada: 2
status: done
sessao: 01a21eb9-13b5-7ff3-911a-53eea9ba31a7
data: 2026-11-27 17:53
gate: tests/run-all.sh em 65862f397633e348b2bf430cbcd08a0953797076 → rc 0, suite green em 21 etapas, 106 sondas do worker, 100 âncoras do backlog no SHA revisado e 1.017 do catálogo. A etapa Codex registrou 3 skipped. Árvore limpa durante a suíte. Checks R1–R4 deram 1 por incremento. Retestes de F1 e F2 deram 1 cada. REVIEW não passou em Code Quality (Zen), Error Handling e Test Coverage. R5 pending.
reviewed_head: 65862f397633e348b2bf430cbcd08a0953797076
---

# Review — rodada r2 — O worker e os verbos dele

> Escrito ao fim de cada rodada de revisão, em `docs/handoffs/<missão>/40-review-r<N>.md`.
> O runner lê **a mais recente**. Uma rodada que não fechou também escreve o arquivo, com a nota
> real: nota inflada para passar no gate desliga o único sensor de qualidade da missão.

## TL;DR

O delta das correções da r1 fecha os cinco casos reproduzidos naquela rodada.
A revisão confirmou uma regressão do R3. O worker pode ignorar um pedido válido se o texto anterior ao título parecer abrir uma cerca Markdown.
O caso volta ao EXEC como R5. Um falso verde preexistente de `local/ci` foi registrado no backlog. Não houve mudança de código.

## Nota da rodada

A skill `codereview` foi executada com `base=27c94acb55c18b785db213b2aed3f45ecacce5f1` e head `65862f397633e348b2bf430cbcd08a0953797076`, a partir do handoff EXEC e dos dois achados de QA.
São nove commits e 12 caminhos no inventário, três de código, dois de testes e sete de prosa ou registros.
O conteúdo de `checkpoint-notas.md` ficou fora da leitura e da varredura. Foram usadas as notas já fornecidas no boot.
A revisão de código leu os hunks e seus consumidores imediatos nos arquivos do delta.

### Detecção de segredos

| Varredores | Arquivos | Linhas acrescentadas | Achados | Erros |
|---|---:|---:|---:|---:|
| `regex`, `gitleaks` | 11 | 579 | 0 | 0 |

Rodou `git diff 27c94acb55c18b785db213b2aed3f45ecacce5f1...HEAD --unified=0` com pathspec que exclui apenas `checkpoint-notas.md`, entregue ao `scan_secrets.sh` da skill.

### Cobertura do delta

| Arquivo de produto | Sensor atualizado | O que foi exercitado |
|---|---|---|
| `bin/sdd-worker` | `tests/check-worker.sh` | Suíte ausente, vermelha e verde, com status e prontidão no SHA de cada cenário. Classificação do corpo da revisão e concordância entre inventário e prontidão. |
| `bin/sdd-worker-ahead` | `tests/check-worker-ahead.py`, chamado por `tests/check-worker.sh` | Lançamento, reserva e retomada. Referências íntegras, ausentes, vencidas, ambíguas, em cerca de código ou alteradas durante o despacho. Faltava o título verdadeiro depois de texto que apenas se parece com uma cerca. |
| `bin/sdd-plan-codex` | `tests/check-worker-ahead.py`, com relay real e adaptador simulado | Caminho de `campaign.md` no primário e lote no primeiro prompt, mesmo sem a fila no checkout reservado. |

Três de três arquivos de produto têm sensor atualizado. `bash -n` passou nos dois scripts Bash do delta e `ast.parse` nos três arquivos Python. A varredura de código morto não achou símbolos introduzidos ou órfãos no delta. Não houve varredura de legado.
Os procedimentos e o handoff EXEC conferem quanto ao que as sondas medem. A divergência de R5 está no comportamento do leitor, não na prosa.

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | B | O reconhecimento de cercas em local_anchors confunde texto ou comentário com abertura de bloco e descarta um título verdadeiro. |
| Type Safety | A | O inventário e a prontidão agora recusam juntos metadados presentes com formato inválido e aceitam os dois controles válidos de thread resolvida. |
| Error Handling | B | O falso negativo toma a rota silenciosa de pedido ausente e o operador só vê o veredito original do predecessor. |
| Security | A | O produtor não publica êxito quando o config encerra antes da suíte. Os casos locais ausente, vencido e alterado durante o despacho não abriram turno. |
| Performance | A | O despacho preserva um turno por sucessor na jornada e não acrescenta consulta remota para conferir o fragmento local. |
| Test Coverage | B | As sondas novas do R3 cobrem cercas reais, mas deixam verde o leitor que rejeita o título válido nos dois casos de R5. |
| Documentation | A | O runbook distingue a fila canônica, a verificação do pedido, a conclusão da suíte e os resultados da revisão. |
| **Overall** | **B** | Os cinco contraexemplos da r1 estão cobertos e ficou uma regressão reproduzida no reconhecimento de um pedido válido. |

As notas de Type Safety e Security subiram de B para A, com os commits de produto abaixo. Não houve platô nem queda de nota. A próxima rodada deve reavaliar só o delta do R5.

## Achados da rodada

| # | Severidade | Achado | Onde |
|---|---|---|---|
| 1 | MEDIUM | O despacho mantém apenas a sugestão mesmo com título válido, se linhas anteriores forem confundidas com abertura de cerca Markdown. | `bin/sdd-worker-ahead:60–71`, `bin/sdd-worker-ahead:92–94`, `bin/sdd-worker-ahead:112–114` |

### Reprodução

Em uma cópia descartável de `tests/check-worker-ahead.py`, na rota `--owner-request`, mantive o
mesmo `ahead-request` apontado para `#owner-request`, com orçamento, delegação e checkout do
predecessor válidos. No controle positivo, o arquivo começa com `# Owner request` seguido pelo
pedido. Em dois mundos, só acrescentei um prefixo antes desse título. No primeiro, usei um
comentário HTML terminado que contém uma linha de exemplo com três crases. No segundo, usei
uma linha que começa com três crases, mas que tem crases também no texto de informação.
Os prefixos exatos, em notação de string Python, foram os seguintes.

~~~~python
'<!--\n```text\n-->\n\n'
'``` informação com `inline`\n\n'
~~~~

O parser CommonMark do `markdown-it-py` retornou exatamente o título `Owner request` nos três
mundos. No segundo, CommonMark não reconhece a linha como abertura de cerca.

| Caso | Turnos em `7ba4bc9`, antes de R3 | Turnos em `65862f3` | Esperas em `65862f3` |
|---|---:|---:|---:|
| Controle sem texto anterior | 1 | 1 | 1 |
| Exemplo de cerca dentro de um comentário encerrado | 1 | 0 | 1 |
| Falsa abertura com crases na informação | 1 | 0 | 1 |

A cópia rodou o bloco público de `run`, Git local e relay real com adaptador simulado. A espera
preservou `rc=3`, `phase-ceiling` e o diagnóstico original nos seis ensaios. No comparativo,
somente o binário do despachante foi trocado pela versão de `7ba4bc9`. A regressão surgiu
em `9b0e168`, quando o leitor passou a tomar as linhas de exemplo por cercas e deixou de coletar o
título verdadeiro. As sondas existentes não exercitam esses controles positivos. A rota manual permanece disponível.

## Incrementos de conserto (R<n>)

| R<n> | Achado | Check escrito no checkpoint |
|---|---|---|
| R5 | #1 | `o=$(bash tests/check-worker.sh 2>&1) && [ "$(grep -c '^  ok    valid markdown owner request survives preceding markup$' <<< "$o")" = 1 ] && grep -c '^  ok    authorized ahead planning starts once before wait$' <<< "$o"` → `1` |

## O que virou incremento

- `R5` — o novo sensor deve observar exatamente um turno antes da espera nos dois mundos com
  título válido, como no controle simples. Conservar a espera e o resultado do predecessor.
  Preservar zero turnos para fragmento vencido, ambíguo ou realmente dentro de uma cerca.
  O segundo sensor do Check repete a jornada de reserva única e retomada.
- `R1`, achado #1 da r1 — fechado em `297f072`. Config que sai antes da suíte conserva apenas
  `pending`. A jornada distingue uma execução com falha, que publica `failure`, de uma com
  sucesso, que publica `success` e permite `ready` no mesmo SHA.
- `R2`, achado #2 da r1 — fechado em `a83df3e`. O adaptador simulado capturou o caminho da fila
  no primário e o lote em cada primeiro prompt. A jornada confirma que não há cópia de
  `campaign.md` nos checkouts reservados.
- `R3`, achado #3 da r1 — fechado nos contraexemplos anteriores em `9b0e168`. Arquivo ausente,
  fragmento vencido e edição do arquivo durante `budget` não abriram turno. A referência simples
  íntegra abriu um turno. R5 cobre a regressão em um pedido diferente, que continua recuperável.
- `R4`, achados #4 e #5 da r1 — fechado em `4d5bdb4`. Aprovação simples em inglês e português
  não impede `ready`. Corpo acionável e pedido de alteração vigente impedem. Inventário e
  prontidão devolvem rc 3 para metadados inválidos e preservam a thread resolvida válida.

## O que foi refutado

- **Isolar o retorno da suíte engole sua saída normal ou publica o texto do config como resultado.**
  O sensor de R1 separa stdout e status. O config que encerra antes da suíte imprime `0` mas fica
  em `pending`. A saída da suíte continua visível nos mundos verde e vermelho.
- **A correção do fragmento impede qualquer título após uma cerca.** O controle de R3 com cerca
  de til e título posterior em `tests/check-worker-ahead.py:210` abriu um turno. R5 exige que o texto
  anterior apenas pareça uma cerca, sem ser uma.
- **A aprovação curta libera um pedido de alteração vigente ou um corpo acionável.**
  `tests/check-worker.sh:2343–2385` mede os três casos separadamente e só libera a aprovação sem
  achado e sem pedido vigente.

## Achados fora de escopo

**HIGH — Configuração de suíte só com espaços publica verde.** Em uma cópia descartável da
fixture de `tests/check-worker.sh:2009–2044`, mantive o GitHub simulado e usei `review-ci` e
`pr-ready` reais no mesmo SHA limpo por cenário. Com uma configuração de dois espaços, houve
somente os eventos `pending` e `success`, sem a marca da execução da suíte. Produtor e
consumidor saíram 0 e o consumidor imprimiu `ready <sha>`. O resultado se repetiu com os
binários de `27c94ac` e `65862f3`. A configuração vazia bloqueou a prontidão em ambos, e
o controle com um comando de teste válido rodou uma vez e ficou pronto.

O predicado de vazio de `bin/sdd-worker:1598` não mudou no delta, como mostra
`git diff -w 27c94ac...65862f3 -- bin/sdd-worker`. R1 passou a comprovar que a avaliação
retorna, mas não mudou a aceitação de uma string composta apenas por espaços. O defeito
do produtor foi para `TODO.md`, com a catraca de contagem, e não integra a nota do delta
nem ganhou um incremento de EXEC.

## Pendências / Decisions for a Human

Nenhuma decisão de produto nesta rodada. Não foram acionados o GitHub, o Codex real nem a campanha real. O primeiro prompt foi observado no adaptador simulado, sem verificar permissões externas ou resposta do modelo.


## Ações recomendadas

- **CRITICAL** — nenhuma.
- **HIGH** — nenhuma.
- **MEDIUM/LOW** — executar R5 em TDD, distinguindo cerca válida, comentário e texto, e repetir a jornada antes de outra revisão DELTA.

_Pegada de custo — skill codereview 2.27.38 indicada no boot, registro do plugin Claude em 2.30.2. Dois agentes de documentação gpt-6.1-terra, quatro arquivos lidos integralmente, 7–13 chamadas por agente. Código e varredura de código morto na sessão principal. Custo faturado indisponível._
