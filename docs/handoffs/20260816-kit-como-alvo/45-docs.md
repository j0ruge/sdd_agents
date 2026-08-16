---
missao: 20260816-kit-como-alvo
fase: DOCS
status: done
sessao: aa0d6eb9-82b9-436b-b403-11c05f0b5700
data: 2026-08-16 19:20
gate: "Checklist de drift abaixo com **19 linhas**, uma por área do diff: 15 `✅` com hash e 4 `n/a` com justificativa concreta. Nenhum `✗`. `bash tests/run-all.sh` verde no HEAD desta fase (rc `0`, `score: 44 caught, 0 known gap(s), of 44`, 457 asserções `ok`) e os quatro sensores que leem markdown — `check-lang.sh`, `check-todo.sh`, `check-checkpoint.sh`, `check-templates.sh` — verdes um a um. `bash bin/sdd health` → `kit healthy`. As 7 cópias em `.claude/agents/` byte-idênticas por `cmp -s`, que é o que o preflight passou a exigir nesta missão. Árvore limpa."
---

# Documentação — 20260816-kit-como-alvo

> A missão tocou o runner em quatro pontos, criou dois sensores e mudou duas regras de contrato.
> Boa parte da documentação **já aprendeu durante o EXEC e a REVIEW** — a regra do `CLAUDE.md` é
> que contrato quebrado em três lugares se conserta no mesmo commit, e ela foi obedecida. Esta
> fase fecha o que sobrou, re-deriva as âncoras podres do `TODO.md` e mede o kaizen.

## Drift checklist

| Área tocada pelo diff | Documento correspondente | Status | Evidência |
|---|---|---|---|
| `bin/sdd` — `ledger_row_is_local()` e os três leitores (I2) | `docs/pipeline.md` § "The autonomy ledger" | ✅ | seção "The file is global; the READING is per repo" + as três consequências, commit `d99a7fc`; autocontradição do § "The kaizen loop" corrigida em `5e3551e` |
| idem | `README.md` (linha do `sdd autonomy`) | ✅ | "for THIS repo", commit `d99a7fc`; alinhada ao `USAGE` em `5e3551e` |
| idem | `agents/sdd-kaizen.md` + cópia em `.claude/agents/` | ✅ | os **quatro** baldes de `excluded`, com `other_repo` a citar como os outros, commit `5e3551e` |
| idem | `CONTEXT.md` — verbetes "Ledger de autonomia" e "Série" | ✅ | commit `d199448`: o arquivo é global, a **leitura** é por repo; `excluded` com quatro baldes nos dois produtores |
| idem | `docs/failure-modes.md` — série vazia / linhas de outro repo | ✅ | seção nova "The series is empty, or the rows «were born in another repo»", commit `f82b975` |
| `bin/sdd` — preflight `cmp -s` em vez de `[ -f ]` (I3) | `README.md` | ✅ | "compares the installed copies with the kit source **byte for byte**", commit `ab64d2e` |
| idem | `docs/failure-modes.md` — agente `stale` | ✅ | seção nova "`sdd preflight` fails: an agent is `stale`", commit `f82b975` |
| `bin/sdd` — `{ main "$@"; exit $?; }` no entry point (I1) | `CLAUDE.md` § "Ao mexer no runner" | ✅ | a forma da última linha declarada como contrato, com o sensor e o mutante que a cobram, commit `afeb291` |
| `bin/sdd` — `warn_if_on_base_branch()` nas três portas (I4) | — | n/a | medido no I4 (`grep -rn 'base branch' docs/ README.md agents/`): **nenhum** doc afirmava que o aviso era exclusivo do preflight, e nenhum enumera os avisos do runner. Continua `warn` e não `die`, então nenhum contrato de comando mudou. A quarta porta que falta (`sdd retry`) está no `TODO.md` |
| `tests/check-entrypoint.sh` (novo) | `CLAUDE.md` § "TDD aqui dentro" | ✅ | lista de sensores dez → **doze** e a rubrica do auto-teste três → quatro, commit `5e3551e`; a passada de sabotagem passa a cobrir três camadas em `02b3b41` |
| `tests/check-checkpoint.sh` (novo) | `CLAUDE.md` § "TDD aqui dentro" | ✅ | entra na lista dos doze e na rubrica do auto-teste, commit `a981fd9` |
| `templates/checkpoint.md` — as duas regras da célula do Check | `agents/sdd-planner.md` + cópia | ✅ | o planner ensina o âncora `^  ok    ` e a proibição do `\|`, commit `a981fd9` (banner do pipe em `c9068ad`) |
| idem | `CLAUDE.md` § "TDD aqui dentro" | ✅ | uma linha de **roteamento** para as duas regras — o índice aponta, `templates/checkpoint.md` guarda o porquê medido, `tests/check-checkpoint.sh` cobra —, commit `02b3b41` |
| `TODO.md` — 13 achados novos e 4 itens fechados | o próprio `TODO.md` (ciclo de vida) | ✅ | commit `081e3f5`: `RESOLVIDO por` em `ab64d2e`/`bb373b5`/`d99a7fc`/`daa8687` e cinco âncoras re-derivadas |
| A missão inteira, com antes/depois medido | `KAIZEN_LOG.md` | ✅ | commit `5266116`: 8 grandezas medidas, os dois tempos de suíte na mesma máquina e sessão |
| Régua de tempo da suíte (catálogo 40 → 44) | `CONTEXT.md` 🚩 D7 | ✅ | commit `d199448`: 1:17,62 → **1:45,17** medido, alvo `<30 s` a 3,5× de distância, decisão cobrada do humano |
| `tests/check-{autonomy,gates,kaizen,mutation,preflight,pipefail}.sh`, `tests/run-all.sh` | — | n/a | asserções, mutantes e pisos anti-vacuidade de sensores **já existentes**. Nenhum doc enumera asserção; a única grandeza documentada é a contagem de sensores, e ela está no `CLAUDE.md` (linha acima). O score de mutação vive no `KAIZEN_LOG.md` |
| `docs/handoffs/20260816-kit-como-alvo/*` | — | n/a | artefatos **desta** missão (missão, plano, checkpoint, handoffs de fase). São o registro do trabalho, não documentação viva do repo — e esta fase é justamente quem os fecha |
| `bin/sdd` — mensagens de `USAGE`/`help` (I2, I3) | — | n/a | o texto de ajuda mora **dentro** do próprio `bin/sdd` e foi atualizado no mesmo commit do conserto (`d99a7fc`, `ab64d2e`): é código, não documento à parte. Registrado aqui para a linha não ficar sem dono |

### Documentos conferidos e deliberadamente NÃO tocados

Toda linha `n/a` acima é sobre uma área do diff. Estes são o inverso — documentos candidatos que
foram abertos e cuja resposta foi "não mudou nada que eles afirmem":

| Documento | Por que não | Como foi conferido |
|---|---|---|
| `docs/adr/0001`, `0002` | Nenhuma decisão arquitetural foi tomada ou revertida: o `00-missao.md` diz "nenhuma decisão de design é tomada aqui", e os quatro consertos ficam dentro do contrato existente. A decisão que **pede** ADR — o eixo `kit_sha` do juiz — está no `TODO.md`, declarada fora de escopo, esperando o humano | os dois ADRs relidos; nenhum afirma coisa que o diff desminta |
| `CHANGELOG.md` | Não existe neste repo, e não deve nascer aqui: o kit não é distribuído por versão, e quem cumpre o papel de "o que mudou e por quê" é o `KAIZEN_LOG.md` com número | `ls *.md` |
| `config/schema.md` | Nenhuma chave de config nasceu, mudou de nome ou de semântica. `SDD_STATE_DIR` já existia e continua sendo o gancho dos fixtures | `git diff main...HEAD -- config/` → vazio |
| `docs/pipeline.md` § do preflight e do `sdd install` | Descrevem a quem o preflight pertence e o que ele prova sobre a sessão; nada ali afirmava que os agentes eram comparados por presença | `grep -n preflight docs/pipeline.md` |

## Achados do `TODO.md` conferidos nesta missão

O arquivo saiu de **52** achados (em `main`) para **65** — 13 novos, nenhum perdido, nenhum
movido de seção sem motivo. `bash tests/check-todo.sh` → verde: *"65 finding(s), all within 8
lines and carrying anchor + date"*.

**Fechados por artefato (4).** Os quatro itens que esta missão de fato consertou seguiam com o
corpo sem `RESOLVIDO por <hash>` — rótulo "aberto" sobre trabalho já feito, que é a família de
defeito desta missão inteira. Cada um carrega agora o commit do incremento, e **fica na seção
Aberto** até o PR ser mergeado (a exclusão se prova por `git merge-base --is-ancestor`, nunca pelo
rótulo do PR):

| Achado | Fechado por | Incremento |
|---|---|---|
| Nada compara `agents/*.md` com a cópia instalada | `ab64d2e` | I3 |
| `main "$@"` sem guarda, e o kit edita o runner em voo | `bb373b5` | I1 |
| O ledger é global e nenhum leitor filtra por repo | `d99a7fc` | I2 |
| O aviso de branch base mora só no preflight | `daa8687` | I4 |

**Âncoras re-derivadas (5).** Quatro delas em itens escritos **nesta** missão, o que confirma o
diagnóstico do item que já denuncia a classe: o `bin/sdd` foi de 2365 para 2492 linhas enquanto os
achados eram escritos, e o sensor mede a **forma** da âncora, nunca o alvo.

| Item | Âncora citada | Âncora real | Consequência se ficasse |
|---|---|---|---|
| `N kit agent(s) checked` sem fixture | `bin/sdd:1332` | `bin/sdd:1356` | linha em branco — o leitor conclui que o achado é falso |
| `40-review-r<N>.md` sem template | `bin/sdd:2196` | `bin/sdd:409` | apontava para dentro do `gate_KAIZEN`, o gate **errado** |
| Duas regras sobre `aprovacao:` | `agents/sdd-planner.md:101` / `sdd-kaizen.md:110` | `:111` / `:113` | as duas frases citadas não estavam nas linhas citadas |
| Lembrete pós-pipeline cego | `bin/sdd:2141` | `bin/sdd:2147` | apontava o comentário, não a função |

**Bem formados, sem retoque (9 dos 13 novos).** Conferidos um a um contra o disco — o quê, âncora
`arquivo:linha` que resolve, por que importa, direção, e o "descoberto por `<agente>` na missão
`<slug>` (data)". Os quatro do `sdd-reviewer` sobre o ledger (`bin/sdd:768`, `:785`, `:790`,
`:1868`) e o comentário das três portas (`:1209`) batem exatamente; os dois sobre sensor
(`tests/check-entrypoint.sh:234`, `tests/check-checkpoint.sh:239-241`) idem.

⚠️ **O que esta fase NÃO fez, de propósito:** re-derivar as âncoras dos achados de missões
anteriores. São ~50 itens, o defeito é sistêmico e tem item próprio no `TODO.md` com direção
("resolver cada âncora e cobrar que a linha contenha um termo do título") — varrer à mão de novo
seria pagar o custo pela terceira vez em vez de construir o sensor. As quatro que apodreceram
**nesta** missão foram consertadas porque são responsabilidade desta missão.

## Progressive disclosure — o que foi decidido não escrever

O `CLAUDE.md` cresceu **18 linhas** nesta fase (207 → 225) e o `README.md`, zero — segue em 122,
intocado desde `5e3551e`. Foi decisão, não acaso:

- a regra do âncora `^  ok    ` e a proibição do `|` na célula do Check entraram no `CLAUDE.md`
  como **uma linha de ponteiro**. O porquê medido (o `NF=8`, o `pending` na coluna Commit, o
  `fail()` imprimindo o mesmo texto que o `pass()`) já mora em `templates/checkpoint.md`, que é
  quem o executor lê no momento em que precisa, e `tests/check-checkpoint.sh` é quem cobra.
  Duplicar a explicação no índice seria a forma exata de o índice virar o arquivo que ninguém lê;
- a lição das três camadas de sabotagem entrou porque a regra anterior ("o selftest tem de
  exercitar o CAMINHO") **estava escrita e não bastou** — três fail-open passaram por cima dela.
  Convenção que falhou na prática é convenção que mudou; o detalhe fica no cabeçalho do
  `tests/check-entrypoint.sh`, que nomeia os cinco survivors;
- o aviso de branch base **não** virou linha de README. Ele é um `warn` que não muda nem a saída
  útil nem o `rc` de nenhum comando, e o README lista comandos e contratos.

Nenhum documento deste repo passou do limiar em que valeria propor um split para `references/`;
o maior é o `KAIZEN_LOG.md` (896 linhas), e ele é append-only por natureza — quem o lê procura uma
missão, não o arquivo inteiro.

## Para a fase PR

- Corpo do PR: a métrica do `00-missao.md` cumprida número a número (`127`/`0`/`0`/`0` →
  `0`/`1`/`1`/`1`), catálogo 40 → 44 a 100%, e a tabela do `KAIZEN_LOG.md` para o antes/depois.
- Três pendências de **humano** viajam com o PR e estão no `00-missao.md` § Pendências: o eixo do
  juiz (com ADR), a confirmação da D11 e — agora com número novo — a régua de tempo da suíte.
- Nada a publicar além do que já está commitado: esta fase não abriu PR, não fez push e não mexeu
  em `.sdd/config.sh`.
