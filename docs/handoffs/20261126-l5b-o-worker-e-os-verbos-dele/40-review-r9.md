---
missao: 20261126-l5b-o-worker-e-os-verbos-dele
fase: REVIEW
rodada: 9
status: done
sessao: 01a220b3-3396-72f1-a620-a038dd500a60
data: 2026-11-28 03:06
gate: SDD_MUTATION_FIXTURE_ROOT="$PWD" tests/run-all.sh em 1446b62810107a9c0c12b61fa93e2bc8e71e3194 → rc 0, suite green, 21 etapas, 114 sondas do worker, 3 casos skipped do Codex. Árvore limpa durante a execução. Check R12 → 1. Os critérios estritos passaram e não há incremento pendente.
reviewed_head: 1446b62810107a9c0c12b61fa93e2bc8e71e3194
---

# Review — rodada r9 — O worker e os verbos dele

## TL;DR

R12 fechou em `8b093116`. O título dentro de HTML não autoriza o despacho nem invalida um
título visível. Os dois vermelhos da r8 viraram verde pela jornada pública de `run`.
R10, R11 e a reserva única mantiveram o resultado. Nenhum achado novo no delta.
A rodada não alterou código nem abriu incrementos.

## Nota da rodada

Revisão `codereview:codereview base=94efef27ebc012c36d3904bb75ccd86d9219acff`.
O delta termina em `1446b62810107a9c0c12b61fa93e2bc8e71e3194`, com a árvore limpa.
A QA em `ada1e29` já percorreu planejamento e retomada, parada e revisão/merge.
Esta rodada retestou o leitor de âncora e os efeitos da mudança pela mesma entrada pública.
A r8 serviu de histórico para fechar o achado aberto. A verificação de prosa nova cobriu
14 unidades do procedimento, pipeline, handoff EXEC e checkpoint.

### Detecção de segredos

`PASS`. Zero achados e zero erros em oito arquivos e 260 linhas adicionadas,
com `regex` e `gitleaks`. O registro append-only de notas ficou fora da leitura e da varredura.

### Cobertura e sanidade do delta

O código troca o estado de parágrafo depois de um separador temático confirmado no recuo
do contêiner. Os deslocamentos continuam inteiros, avançam com o marcador e ficam no
mesmo escopo do ramo sem cerca. Não há chamadas externas, alterações nas guardas de
delegação, orçamento e ownership nem interfaces renomeadas no delta.

`ruff check --no-cache --select F401,F811,F821,F841 bin/sdd-worker-ahead tests/check-worker-ahead.py`
e `bash -n tests/check-worker.sh` saíram 0. Sem símbolo novo órfão ou último uso removido.
A varredura de dívida preexistente ficou fora do delta.

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | A | A decisão sobre o separador reaproveita a mesma expressão no recuo do contêiner, sem trocar o caminho de despacho. |
| Type Safety | A | Os deslocamentos são inteiros e o acesso a grupos de expressão regular continua condicionado ao casamento. |
| Error Handling | A | Os 30 retestes conservaram uma espera, stderr vazio e o mesmo diagnóstico do runner, inclusive os cinco vermelhos no blob anterior. |
| Security | A | O título oculto deixou de autorizar o relay na fixture e o delta não alterou as guardas de delegação, orçamento e ownership. A varredura não encontrou segredos. |
| Performance | A | A mesma medição deu 4.023 e 8.023 caracteres para 2.000 e 4.000 marcadores iguais, com hífens e sinais de mais, antes e depois de R12. |
| Test Coverage | A | O sensor R12 falhou no blob anterior pelo evento de despacho e passou no head. R10, R11, a reserva única e a retomada concorrente também passaram. |
| Documentation | A | O procedimento e o pipeline descrevem a fronteira que o reteste confirmou. O Check e as medidas do handoff foram corroborados em nova execução. |
| **Overall** | **A** | R12 foi confirmado por reprodução diferencial e pela suíte integral no head, sem novo achado no delta. |

## Achados da rodada

Nenhum.

### Reprodução diferencial

Usei `python3 tests/check-worker-ahead.py "$PWD" --preceding-markup` nas cópias
isoladas, com o mesmo procedimento público e os mesmos simuladores. Troquei apenas
`bin/sdd-worker-ahead` entre o blob de `3731d796` (pai da implementação, com o
mesmo código de `94efef27`) e o de `1446b628`. A cópia da sonda imprimiu eventos
e veredito antes de avaliar as asserções. Cada caso rodou com teto de 25 s.
O prefixo dos sete casos na tabela é
`thematic-after-html-`.

| Caso | Antes de R12 | Head |
|---|---|---|
| `hidden`, `hyphens`, `underscores`, `in-item` | `start, wait`, rc 1 | `wait`, rc 0 |
| `duplicate` | `wait`, rc 1 | `start, wait`, rc 0 |
| `visible` | `start, wait`, rc 0 | `start, wait`, rc 0 |
| `root-duplicate` | `wait`, rc 0 | `wait`, rc 0 |

Os quatro controles de R10 e os quatro de R11 retornaram 0 nos dois blobs. Em todos
os 30 retestes houve uma espera, stderr vazio e o mesmo veredito, com código 3,
causa `phase-ceiling` e mensagem `sdd run stop: phase-ceiling — fixture`. O rc
da tabela é da sonda, não do runner. O parser de referência `MarkdownIt` no modo
CommonMark confirmou 0, 1, 1 e 2 títulos visíveis nos quatro casos originais
(`hidden`, `visible`, `duplicate` e `root-duplicate`). Isolei ainda o bloco R12 de `tests/check-worker.sh`.
O agregador saiu 1 antes da correção, com cinco asserções de eventos em vermelho,
e 0 no head, com uma ocorrência exata da marca verde.

## Incrementos de conserto (R<n>)

Nenhum incremento novo. Os 28 existentes permanecem `done`.

## O que virou incremento

- O achado #1 da r8 virou R12 e foi fechado pelo executor em `8b093116`. O Check
  R12, aplicado à saída da etapa do worker da suíte desta rodada, deu `1`.
  As quatro marcas exatas do Check, incluindo R10, R11 e a reserva única, aparecem
  uma vez cada. A retomada concorrente também teve uma marca verde.

## O que foi refutado

- **O sensor pode estar verde sem distinguir o defeito anterior.** No mesmo
  sensor e com apenas o blob do leitor trocado, a marca verde desapareceu e
  houve cinco asserções de eventos em vermelho. O veredito simulado não mudou.
- **A correção pode ter desfeito o limite de custo de R11.** O contador de
  caracteres submetidos a correspondência integral mediu `4.023 → 8.023`
  nos dois blobs e com os dois tipos de marcador.
- **A verificação de prosa não recebeu prova das contagens do EXEC e de R12.**
  Os logs históricos do EXEC não foram recuperados. A suíte, os marcadores do
  Check, o contador de R11 e os controles foram observados novamente neste head.
  Não há diferença de produto ou teste entre `8b093116` e o head revisado.
- **Faltou demonstrar zero entradas fora de escopo em R12.** A ausência aqui
  descreve o registro, não uma busca histórica por todos os problemas possíveis.
  `git diff --name-only 94efef27..1446b628 -- TODO.md tests/health-baseline.txt`
  retornou zero caminhos. Nenhuma nova entrada ou recorrência foi registrada
  no delta.

## Achados fora de escopo

Nenhum item ou recorrência novo. Os achados preexistentes nomeados na r8 não foram
reabertos nem reavaliados.

## Pendências / Decisions for a Human

Nenhuma. Em relação à r8, Code Quality (Zen), Error Handling, Security e Test Coverage
subiram de B para A com o reteste de `8b093116`. Os demais critérios estritos
mantiveram A. O resultado não é um platô, nem uma aprovação obtida só pela prosa.

## Boot da próxima fase

Não há correção pendente de REVIEW. Use o presente relatório e o checkpoint para
prosseguir pelo gate de DOCS. Se o head de produto mudar, reavalie a partir de
`1446b62810107a9c0c12b61fa93e2bc8e71e3194`.

## Ações recomendadas

- CRITICAL — nenhuma.
- HIGH — nenhuma.
- MEDIUM/LOW — nenhuma neste delta.

_Pegada de custo — skill Codex 2.27.38, com as regras de verificação da instalação
2.30.2. Uma verificadora gpt-6.1-terra leu 14 unidades e declarou 23 chamadas.
Código, varredura de símbolos e reproduções na sessão principal. Custo faturado
indisponível. Nenhum GitHub, planner Codex real ou mutação integral foi acionado._
