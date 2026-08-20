---
missao: 20260819-fecho-que-nao-mente
fase: DOCS
data: 2026-08-19
status: done
gate: "Checklist de drift com 24 linhas, uma por área que o diff tocou: **16 ✅** com hash e **8 n/a** justificados por artefato, nenhum `✗` — contagem tirada do PRÓPRIO `awk` do `gate_DOCS` rodado sobre este arquivo (`16 ✅`, `8 n/a`, nenhum outro valor), nunca de um `grep` meu. Seis commits desta fase (`933b905`, `56d8233`, `3407fe3`, `7c25b5f`, `3b0623a`, mais este). `tests/run-all.sh` → `suite green`, rc 0, **1m42,70s**, **487** linhas `^  ok    `, zero `FAIL`. `tests/check-lang.sh` → `0 of 38 surface path(s) still in the allowlist, 0 new` (a superfície inglesa cresceu de 37 para 38 com o `docs/adr/0004`, e o sensor a lê limpa). Espelho de `.claude/agents/` sincronizado por `./bin/sdd install --force` → `agent sdd-publisher.md updated (--force)`, nunca `cp`. **Carimbo do `gate_PR` PRESERVADO**: `git diff --name-only ce25226..HEAD -- bin tests templates config` devolve vazio, `.sdd/logs/mutation-stamp` segue `bbdd6ab12c34d4381b88c7e8f756648b`, e nenhuma rodada de catálogo foi cobrada por esta fase. Catraca `todo-findings` **não movida** (89), porque esta fase não abriu achado novo."
---

# Documentação — 20260819-fecho-que-nao-mente

> Escrito depois do código final e antes do PR. A pergunta não é "o que seria bom escrever",
> é **"que documento passou a descrever um mundo que não existe mais?"**. Documentação que mente
> custa confiança toda vez que alguém a segue e se queima.

## TL;DR

O diff tem 18 arquivos e ~2.900 linhas acrescentadas, e a maior parte dele é **sensor** — código
sem documento correspondente por construção. O que de fato derivou foi **uma afirmação do
`CLAUDE.md` que a missão tornou falsa** (a lacuna do catálogo opt-in, que existia e agora está
fechada), **um gate do `docs/pipeline.md` que passou a ter três requisitos e listava dois**, **um
comando do `README.md` que virou escritor de artefato** e **um agente que baterá no requisito novo
sem saber que ele existe**.

Também nasceram dois documentos, e os dois são profundidade, nunca índice: o **ADR 0004**, que
registra a decisão arquitetural da missão com as quatro alternativas descartadas, e uma **seção
nova de `docs/failure-modes.md`** para a mensagem que o operador vai ler mais vezes por causa desta
missão.

**Nenhum achado novo foi aberto por esta fase**, e isso é decisão medida, não omissão — ver
"Pendências". Por consequência a catraca não se moveu, e por consequência disso **o carimbo do
`gate_PR` sobreviveu à fase DOCS inteira**: a fase PR não precisa de outra rodada de catálogo.

## Checklist de drift

| Área tocada pelo diff | Documento correspondente | Status | Evidência |
|---|---|---|---|
| `bin/sdd` — `cmd_health` checagem 2: os dois números do `score:` comparados | `README.md`, parágrafo do `sdd health` | ✅ | `56d8233` — a promessa "requires a 100% mutation score" deixou de ser aspiracional e ganhou o que ela compara |
| `bin/sdd` — `cmd_health` checagem 2b: `TEST_CMD` que carrega `--list` é recusado | `README.md`, mesmo parágrafo | ✅ | `56d8233` — com o porquê em meia frase ("exits 0 having run nothing") |
| `bin/sdd` — `cmd_health` checagem 2c e `MUTATION_CATALOGUE_FLOOR`: catálogo pequeno demais | `README.md`, mesmo parágrafo | ✅ | `56d8233` |
| `bin/sdd` — `cmd_health`: o carimbo, sua escrita, sua remoção e a guarda de janela | `README.md` (parágrafo novo) e `docs/failure-modes.md` (seção nova, os três estados que produzem a recusa) | ✅ | `56d8233` |
| `bin/sdd` — `gate_PR`: o terceiro requisito, o último da fila | `docs/pipeline.md` § "PR — confirmed by gh, not by the file" | ✅ | `56d8233` — o gate listava dois requisitos e tem três |
| `bin/sdd` — `gate_PR`: o que o operador vê quando ele recusa | `docs/failure-modes.md`, seção nova ordenada ao lado da outra falha de `sdd health` | ✅ | `56d8233` — sintoma, três causas, o que o kit faz, o que você faz |
| `bin/sdd` — `gate_PR`: quem bate nele primeiro, e em laço se não souber | `agents/sdd-publisher.md` + espelho `.claude/agents/` | ✅ | `3407fe3` — quarto item do "Check before pushing", sincronizado por `sdd install --force` |
| `bin/sdd` — `has_mutation_catalogue`, `health_kit_root`, `mutation_stamp_key`, `MUTATION_STAMP_PATHS` | `CONTEXT.md`, verbete novo "Carimbo de mutação" | ✅ | `933b905` — instrumento novo do vocabulário do kit, ao lado de Catraca e Piso |
| `bin/sdd` — a decisão de desenho por trás dos quatro (carimbo em vez de CI, escopo por artefato, chave no conteúdo, uma árvore só) | `docs/adr/0004-mutation-catalogue-owner-stamp-not-ci.md` (novo) | ✅ | `56d8233` — as 4 partes e as 4 alternativas descartadas, para que ninguém as re-litigue por parecerem óbvias |
| `bin/sdd` — o catálogo opt-in deixa de depender de alguém lembrar | `CLAUDE.md` § "TDD aqui dentro" — o parágrafo afirmava o contrário | ✅ | `933b905` — mais a consequência operacional (rodar depois do último commit de código) que custa 20 a 50 min quando se erra a ordem |
| `bin/sdd` — `gate_REVIEW`: `f[4]`, `placeholder()`, `gate_present` | `docs/pipeline.md` § REVIEW, `templates/review.md` e `agents/sdd-reviewer.md` + espelho | ✅ | `9fa5b0b` e `272cb91` — contrato de artefato atualizado no MESMO commit da mudança, como o `CLAUDE.md` exige |
| `bin/sdd` — remontagem de coluna com pipe escapado, e `ENVIRON` no lugar de `awk -v` | — | n/a | são consertos de LEITURA dentro da regra já documentada na linha acima: a promessa ao autor da rodada não mudou, mudou a fidelidade com que o gate a lê. Documentar isso na prosa faria o leitor achar que existe uma regra nova a obedecer |
| `bin/sdd` — `frontmatter` e `frontmatter_has` | — | n/a | helper interno de leitura de frontmatter. Nenhum documento descreve funções do runner uma a uma, e o contrato que elas servem (`gate:` presente é julgado, ausente é deixado em paz) está documentado três vezes na linha do `gate_REVIEW` |
| `tests/run-all.sh` — o aviso `(linter absent — skipped)` foi para a stderr | — | n/a | nenhum documento descreve a saída do `--list`, que é bandeira interna da suíte. O único consumidor é o `sdd health`, e a recusa dele está no `README.md` (linha 2 desta tabela). O porquê mora no comentário da própria linha, que é onde quem edita o bloco está olhando |
| `tests/check-health.sh` — 3 asserções novas e `CAPTURE_FLOOR` 16 → 22 | — | n/a | asserção e piso internos de sensor. A CLASSE (piso contra vacuidade, censo `guard:` enumerando a região) já está no `CLAUDE.md` e não mudou; o limite novo que a r1 achou na regra `guard:` está no `TODO.md`, que é onde limite não pago mora |
| `tests/check-gates.sh` — 4 asserções diferenciais novas, 12 mundos | — | n/a | idem. Documentar cada mundo seria o inverso da disclosure progressiva: o índice roteia, e a profundidade de um mundo mora no comentário dele |
| `tests/check-mutation.sh` — catálogo 104 → 118, 14 mutantes novos | `CLAUDE.md` § "TDD aqui dentro" — "gate novo entra com mutação" | n/a | a regra não mudou e continua paga: `sdd health` reprova gate sem mutação, e os 8 de 8 seguem cobertos. O número nunca é escrito em prosa aqui de propósito — sai da linha `score:`, e fixá-lo no `CLAUDE.md` seria uma data de validade escrita à mão |
| `tests/health-baseline.txt` — `todo-findings` 72 → 89 | `CLAUDE.md` princípio 5 e `docs/failure-modes.md` | ✅ | `933b905` e `56d8233` — o mecanismo da catraca não mudou, mas o arquivo passou a morar DENTRO da chave do carimbo, e essa colisão é nova: registrar um achado agora custa uma rodada de catálogo. Documentada nos dois lugares, e o item que a paga está no `TODO.md` |
| `agents/sdd-reviewer.md` + espelho `.claude/agents/` | o próprio agente, sincronizado por `sdd install --force` | ✅ | `9fa5b0b` e `272cb91` — conferidos byte a byte nesta sessão pelo `install --force`, que reportou `identical` para os dois |
| `templates/review.md` — a regra da `Rationale` e do campo `gate:` | o próprio template, mais `docs/pipeline.md` § REVIEW | ✅ | `9fa5b0b` e `272cb91` |
| `TODO.md` — 4 achados fechados com `RESOLVIDO por <hash>`, 15 abertos pela missão | `CLAUDE.md` princípio 5 e o cabeçalho do próprio `TODO.md` | n/a | formato e ciclo de vida inalterados. As 15 entradas foram lidas uma a uma nesta sessão — seção abaixo |
| `docs/handoffs/20260819-fecho-que-nao-mente/*` | — | n/a | artefato de missão, não documentação viva do repo. É o registro que os documentos acima citam quando precisam de profundidade |
| A missão como um todo — antes/depois medido | `KAIZEN_LOG.md` | ✅ | `7c25b5f` — tabela de 11 linhas com a entrada exata que produz cada mudança de resposta, o custo real e o relógio que subiu 20% sem corte de asserção |
| Os dois documentos que a missão escreveu e o índice não citava | `README.md`, tabela "Documentation" | ✅ | `3b0623a` — `docs/adr/` e `CONTEXT.md`. Índice que não roteia deixa a profundidade invisível, que é a outra metade da regra desta fase |

## Entradas do `TODO.md` conferidas nesta missão

`tests/check-todo.sh` já cobra forma — âncora, data, teto de 8 linhas — e responde
`89 finding(s)` verde, batendo com `tests/health-baseline.txt`. O que ele **não** cobra é se o item
diz por que importa e para onde ir: essa parte foi lida à mão.

**15 entradas carregam o slug desta missão**, e as 15 são bem formadas: o quê em negrito, âncora
`arquivo:linha`, o mecanismo, o que foi **medido**, uma direção e o rodapé
`descoberto por <agente> na missão <slug> (data)`.

| Autor | Entradas | Observação |
|---|---|---|
| `sdd-qa` | 7 | as sete da fase QA, incluindo a colisão entre a catraca do backlog e o carimbo, que é a que esta fase DOCS teve de decidir na prática |
| `sdd-executor` | 5 | limites declarados do que a própria missão construiu: a checagem 2b lendo o `TEST_CMD` do kit, `FIXME`/`XXX` sem mundo que os prove, o piso do catálogo que mora só no consumidor |
| `sdd-reviewer` | 3 | os três da r1, todos com reprodução literal — o censo `guard:` contando comentário, a guarda de vazio parcial do `mutation_stamp_key`, o config que não parseia lido como chave ausente |
| `sdd-docs` | 0 | esta sessão não abriu nenhum — ver "Pendências" |

**Nenhuma precisou ser completada.** Quatro foram conferidas contra o código de hoje por serem as
mais fáceis de envelhecer, e as quatro âncoras ainda apontam para o que o corpo descreve:
`bin/sdd:806` (guarda de vazio do `mutation_stamp_key`), `tests/check-health.sh:1352` (censo
`guard:`), `bin/sdd:578` (a lista de palavras de preenchimento) e `tests/health-baseline.txt` (a
colisão com o carimbo).

Os **4 fechados** carregam `RESOLVIDO por <hash>` no corpo com a caixa desmarcada, seguindo o
cabeçalho escrito do `TODO.md` — `7a6653b`, `2f71646`, `9fa5b0b` e `c962e2e`. Eles só saem do
arquivo depois que o PR mergear, provado por `git merge-base --is-ancestor <hash> main`, e é por
isso que `todo-findings` não desce nesta missão. Que essa convenção coexista com a da missão
passada, que apagou na hora, continua sendo a pendência 2 abaixo.

## O que foi deliberadamente NÃO escrito

- **Nada sobre asserção individual de sensor.** São dezenas nesta missão. O índice roteia; a
  profundidade mora no cabeçalho de cada `tests/check-*.sh` e no comentário de cada mundo, que é
  onde quem edita o sensor está olhando. `CLAUDE.md` que cresce toda missão vira documento que
  ninguém lê e que estoura a janela da próxima sessão — e doc que estoura a janela é doc quebrado.
- **Nenhuma regra nova de review no `CLAUDE.md`.** A regra da `Rationale` e do campo `gate:` é
  contrato de artefato e já está escrita em **três** lugares que o autor de uma rodada lê
  (`templates/review.md`, `agents/sdd-reviewer.md`, `docs/pipeline.md` § REVIEW), todos atualizados
  no mesmo commit da mudança. Uma quarta cópia no `CLAUDE.md` seria a que envelheceria primeiro.
- **Nenhuma regra inventada.** Uma única afirmação do `CLAUDE.md` mudou, e mudou porque o mundo que
  ela descrevia acabou num commit com hash. Regra escrita por agente sem mudança correspondente é
  dívida que o próximo agente obedece sem questionar.
- **Nenhuma reforma do `docs/pipeline.md`.** Ele passa de 40 KB e o item "merece a sua missão" já
  está no `TODO.md`; refatorar documento de outra pessoa no meio desta missão é desvio de escopo.
  O que entrou nele foi um parágrafo no gate que ficou incompleto, com link para a profundidade.
- **Nenhum conserto de código, e nenhuma correção de âncora.** A r1 registrou que `bin/sdd:528`
  cita `templates/review.md:37-44`, que o próprio commit empurrou para `48-55`. Está no `TODO.md`,
  e consertá-lo aqui tocaria `bin/` — matando o carimbo por uma linha de comentário.

## Pendências para o humano

1. **Os três achados que esta sessão VIU e não registrou, e o motivo, que é ele mesmo um achado.**
   Registrar um item no `TODO.md` obriga a mover `tests/health-baseline.txt` no mesmo commit
   (princípio 5 + catraca), e esse arquivo mora dentro da chave do carimbo: **cada achado novo
   custa uma rodada de 20 a 50 min de catálogo antes do `gate_PR`**. A colisão já está no `TODO.md`
   como item da fase QA, com direção. O que esta fase acrescenta é a medição do incentivo que ela
   cria: a fase mais barata do pipeline foi a primeira a ter motivo econômico para **não** anotar o
   que viu. As três coisas vistas, todas de índice e todas menores que o item que as pagaria, ficam
   registradas aqui e não lá — o `README.md` não citava `CONTEXT.md` nem `docs/adr/` (consertado em
   `3b0623a`), e a tabela "Documentation" não distingue índice de profundidade. Quem discordar do
   corte: os três cabem num commit e a catraca aceita o número.
2. **A convenção do `RESOLVIDO por` × a catraca do backlog.** Segue de pé, sem mudança: esta missão
   seguiu o cabeçalho escrito do `TODO.md` e a passada apagou na hora (`6136d39`). Enquanto as duas
   coexistirem, `todo-findings` significa coisas diferentes em missões diferentes. — `TODO.md`,
   § Contrato e configuração.
3. **CI rodando o catálogo.** O ADR 0004 registra por que o carimbo foi escolhido **sem** fechar a
   porta: as duas coisas compõem. O número que a decisão de custo precisa foi medido duas vezes
   nesta missão e não converge — 30 min para 110 mutantes na QA, 20 min para 118 na REVIEW —,
   porque a diferença é contenção de CPU. Nenhum dos dois serve como estimativa de runner de CI.
   — `00-missao.md` § Fora de escopo.
4. **As três decisões de desenho do plano kaizen-born.** Agora estão em ADR, que é onde decisão
   arquitetural para de ser re-litigada — mas o ADR registra a decisão **como tomada**, e ele nasceu
   de uma sessão sem humano. Ler o 0004 e discordar dele é trabalho legítimo, e é mais barato agora
   do que na próxima missão que o citar. — `docs/adr/0004`.

## Boot da próxima fase

**A próxima fase é PR** (`sdd-publisher`).

⚠️ **O carimbo do `gate_PR` está VIVO e é o mesmo que a REVIEW ganhou**:
`bbdd6ab12c34d4381b88c7e8f756648b`, sobre o conteúdo de `ce25226`. Esta fase commitou seis vezes e
não tocou `bin/ tests/ templates/ config/` — conferido com
`git diff --name-only ce25226..HEAD -- bin tests templates config`, saída vazia. **Não rode
`./bin/sdd health` de novo**: a fase PR não precisa dele, e ele custa 20 a 50 min.

Isso vale como evidência de desenho, além de economia: a decisão 3 do plano — chavear no
**conteúdo** e nunca no `HEAD` — foi tomada exatamente para que a fase DOCS pudesse trabalhar sem
invalidar o verde da REVIEW, e é a primeira missão em que ela é exercida ponta a ponta.

Se o `gate_PR` mesmo assim recusar com `no green mutation catalogue for this content`, alguma coisa
tocou os quatro diretórios depois deste handoff: rode `./bin/sdd health`, deixe terminar, e **nunca
encerre o turno esperando** — sessão headless que encerra o turno é sessão que acabou. A seção nova
de `docs/failure-modes.md` tem os três estados e a saída de cada um.

O corpo do PR tem material medido em quatro handoffs: a métrica do `00-missao.md` fechou com
`score: 118 caught, 0 known gap(s), of 118` contra o `N >= 108` pedido, os três defeitos que deixam
de reproduzir estão com reprodução literal no `40-review-r1.md`, e o `KAIZEN_LOG.md` tem a tabela
de antes/depois pronta para citar.
