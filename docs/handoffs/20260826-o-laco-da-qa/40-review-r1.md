---
missao: 20260826-o-laco-da-qa
fase: REVIEW
rodada: 1
status: done
sessao: b06d97ba-7e80-4f5d-b097-5fd67c650507
data: 2026-08-26 18:45
gate: "Árvore **limpa** (`git status --short` vazio) com 6 commits de revisão sobre `b0f8d7a`. `./tests/run-all.sh` → `suite green`, rc 0, **592** asserções `ok`, 0 FAIL (581 quando a missão começou, 585 ao fim da EXEC). Por sensor: `bash tests/check-gates.sh` rc 0, **139** `ok` (134 antes desta rodada); `bash tests/check-autonomy.sh` rc 0, **189** `ok` (187 antes). Carimbo de mutação tirado **depois** do último commit de código (`319239b`): `./bin/sdd health --with-mutation` → `kit healthy`, rc 0, `mutation: score: 154 caught, 0 known gap(s), of 154`, `all 8 gates have a mutation in the catalogue`, `mutation stamp written — gate_PR can see that THIS content ran green`, `provenance: all 3 fixtures match the installed skills`, `ratchet: 1 known debt(s), none new`. Varredura determinística de segredos sobre o diff da missão (`scan_secrets.sh` do skill `codereview`): `{\"findings\":[],\"scanners\":[\"regex\"],\"errors\":[]}` — 0 achados, 0 erros de scanner, então o portão F não dispara. Todo achado CRITICAL/HIGH/MEDIUM desta rodada foi corrigido e commitado; os 2 que não cabiam viraram linha no `TODO.md` (72 → 74) com a catraca do `sdd health` movida no mesmo diff."
---

# Review — rodada r1 — a fase QA para de girar em bug que ninguém pode fechar

> Escrito ao fim de cada rodada de revisão, em `docs/handoffs/<missão>/40-review-r<N>.md`.
> O runner lê **a mais recente**. Uma rodada que não fechou também escreve o arquivo, com a nota
> real: nota inflada para passar no gate desliga o único sensor de qualidade da missão.

## TL;DR

Revisado o diff inteiro da missão (`ef05eba..HEAD`, 14 arquivos). **11 achados**, todos fechados
nesta sessão em **6 commits**: 2 defeitos de comportamento reproduzidos (um fail-open na Âncora 3,
um `rc 0` engolindo a escalada nova), 5 de contrato/documentação que a própria missão tornou
falsos, e 4 regras permissivas que nenhuma asserção media. Suíte 585 → **592**, catálogo de mutação
153 → **154 caught of 154**. **8 suspeitas foram refutadas com evidência** e o código ficou como
estava. 2 achados que não cabiam aqui viraram linha no `TODO.md`.

## Nota da rodada

Os 4 incrementos do plano e os 2 `F<n>` fazem o que prometem — isso foi conferido, não assumido, e
as duas passadas adversariais desta rodada confirmaram que os diferenciais do I2/I3/F1/F2 recusam
as quatro versões *over-broad* do conserto. Os achados abaixo são **fronteira**: as bordas de uma
âncora que a missão reescreveu e a ordem de uma porta que a missão criou.

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | A | Uma definição e duas portas para a escalada; o extrator do gênero virou `awk` porque cerca é estado, e não um segundo `grep`. Comentário que dizia "TWO STEPS" enumerando três foi corrigido em `21c2532`. Sem duplicação e sem código morto: os 9 símbolos novos têm referência, e os 5 mutantes novos estão no `CATALOG`. |
| Type Safety | A | Em bash a régua é disciplina de enum e de contrato. O `kind` do ledger ganhou o quinto valor `handoff-blocked` **na tabela do `docs/pipeline.md` e no código**, com a ressalva medida de que os leitores não validam `kind` (`is_escalation` só sobre `.event`, agregações com `group_by` dinâmico). O enum do gênero é `agent`/`human`, minúsculo, declarado no `§ 5.1` e medido por asserção desde `02b6c2d`. |
| Error Handling | A | Toda captura nova leva `\|\| true`; o laço é alimentado por **herestring** e não por pipe, então o contador sobrevive; `handoff_blocked_escalation` é CHAMADA e nunca substituída. A auditoria confirmou que `errexit` é inerte no corpo de `gate_QA` (todo call site o suspende). Direção de falha correta em todos os casos: ausente, grafia errada e caixa errada **barram**. |
| Security | A | Varredura determinística de segredos sobre o diff: 0 achados, 0 erros de scanner — o portão F não dispara. Nenhum `eval`, todo caminho citado, nenhum `cd` novo e nenhuma classe negada multibyte no `awk`. A superfície nova é o registry, que já pertence às skills; o gênero exige procedência citada em `arquivo:linha` para valer `human`. |
| Performance | A | A Âncora 3 passou de um `grep -rl` para um `awk` por bug **aberto** — limite que o próprio gate impõe, já que bug aberto barra a fase. Ordem de grandeza inalterada e nenhuma suíte extra: `run-all.sh` segue em ~50s nesta máquina. |
| Test Coverage | A | 592 asserções, 0 FAIL, +7 nesta rodada. Cada regra nova foi **sabotada uma a uma** e matou exatamente a sua asserção; as que não mataram viraram achado (4 regras permissivas sem probe, agora com probe). Catálogo `154 caught of 154`, `all 8 gates have a mutation`, e o mutante `RUN_blocked_not_escalated` foi reancorado antes de virar no-op silencioso. A redundância da regra de coluna zero está **declarada** com as 4 combinações medidas. |
| Documentation | A | Os três documentos que a missão tornou FALSOS foram corrigidos no mesmo diff, como o `CLAUDE.md` exige: a condição do `gate_QA` no `docs/pipeline.md`, o enum do ledger, a Âncora 3 no `docs/qa/README.md` (com a âncora de linha podre trocada por âncora de nome) e o `agents/sdd-qa.md:92`. Nenhum documento vivo contradiz mais o código — conferido por grep. O que resta para a fase DOCS é aditivo, não falso. |
| **Overall** | **A** | 11 achados levantados, 11 fechados com hash; 8 suspeitas refutadas com evidência em vez de consertadas por deferência; 2 fora de escopo registrados no `TODO.md` com a catraca movida. Árvore limpa, suíte verde, carimbo de mutação vivo. |

## Achados da rodada

> Um item por achado, com severidade e âncora em `arquivo:linha`. O achado que virou correção
> aparece de novo na seção seguinte, com hash; o que foi refutado, na de baixo, com evidência.

| # | Severidade | Achado | Onde |
|---|---|---|---|
| 1 | MEDIUM | Extração do gênero falha ABERTA: linha `Closable by: human` citada **acima** do campo do próprio arquivo vira o gênero, e o gate responde `registry clean` com bug sanável aberto | `bin/sdd:686` (`gate_QA`, Âncora 3) |
| 2 | MEDIUM | `--max-phases` engolia a escalada `handoff-blocked`: `rc 0`, sem linha de ledger e sem `pipeline.log`, enquanto as duas Jidokas irmãs escalam sob o mesmo flag | `bin/sdd:3595` (DOOR 1, `cmd_run`) |
| 3 | MEDIUM | Condição do `gate_QA` documentada como "nenhum arquivo com `Status: open`" — tornada falsa pelo I2, e repetida em três frases | `docs/pipeline.md:140,142,145` |
| 4 | MEDIUM | `kind` do ledger documentado como enum FECHADO de 4 valores; o I3 escreve um quinto, e nenhum leitor em runtime valida `kind` | `docs/pipeline.md:551` |
| 5 | MEDIUM | A recusa da Âncora 3 manda transformar em `F<n>` todo bug contado — instrução errada justamente para o bug de gênero AUSENTE, que é o caso pelo qual a âncora foi reescrita | `bin/sdd:695` |
| 6 | MEDIUM | Quatro regras permissivas da Âncora 3 sem asserção nenhuma: caixa do gênero, o `exit` do extrator, a cerca `~~~` e a coluna zero. Degradar cada uma deixava `run-all.sh` VERDE | `bin/sdd:686-691` |
| 7 | MEDIUM | A escalada nomeia a fase em dois lugares e só o do ledger era medido: fase errada na prosa do terminal passava a suíte inteira | `bin/sdd:3328` |
| 8 | LOW | `docs/qa/README.md` descreve a Âncora 3 como "refuses the phase while any exist", e sua âncora `bin/sdd:485-491` já apontava para prosa do `gate_TICKET` | `docs/qa/README.md:108` |
| 9 | LOW | "It repeats until the registry is empty" ficou impreciso: repete até não sobrar bug sanável por AGENTE | `agents/sdd-qa.md:92` |
| 10 | LOW | Comentário afirmando "TWO STEPS, and both are load-bearing" enquanto enumerava três | `bin/sdd:648` |
| 11 | LOW | Caixa do gênero medida pela QA e escrita em lugar nenhum: quem escrever `Human` vê o bug barrar sem explicação | `agents/sdd-qa.md` § 5.1 |

## O que foi corrigido

> Um hash por item. Correção sem hash é rótulo — o gate exige árvore limpa, então tudo que foi
> corrigido está commitado.

- **Achados 3, 4, 8, 9** — corrigidos em `7201632` — a condição do `gate_QA`, o enum do ledger, a
  Âncora 3 do `docs/qa/README.md` (reancorada no NOME do bloco, não na linha) e o `sdd-qa.md:92`.
  Prova: `grep` por cada frase antiga em `docs/ agents/ config/ README.md` devolve **0** ocorrências
  vivas — só os handoffs desta missão, que registram o achado e devem mantê-lo.
- **Achado 1** — corrigido em `0af30ab` — extração passa a pular blocos cercados e pegar a primeira
  linha com forma de campo fora de um. Prova: os 6 regimes medidos à mão em mawk 1.3.4 (`human`
  passa; `agent`, ausente, `humano`, citação abaixo e citação acima barram), mais a asserção
  diferencial na ORDEM sozinha e o mutante `QA_bug_genre_fenced`, que sai rc 1 matando **exatamente**
  a asserção nova e deixando verdes as duas do F1.
- **Achados 5, 10** — corrigidos em `21c2532` — a recusa passa a nomear a saída (`Closable by:
  human`, `§ 5.1`) preservando o substring `with Status: open in the registry` de que duas asserções
  dependem; o comentário passa a dizer TRÊS. O `§ 5.1` ganhou de onde o campo é lido.
- **Achado 11** — corrigido em `50752a9` — o `§ 5.1` passa a dizer que o valor é minúsculo e que o
  casamento é sensível a caixa. Fica no contrato e **não** virou asserção neste commit por ser
  fail-safe; virou asserção no seguinte, quando a sabotagem mostrou que a frouxidão era alcançável.
- **Achados 2, 6** — corrigidos em `02b6c2d` — a DOOR 1 subiu para antes do teto, e as quatro regras
  permissivas ganharam um regime cada. Prova do 2: com a ordem antiga, `check-autonomy.sh` sai rc 1
  e a asserção pré-existente `--max-phases 1 stops after one phase` fica **verde**, o que mostra que
  o conserto não mexeu na semântica normal do flag. Prova do 6: cada regra sabotada isoladamente
  mata só a sua asserção (`case`, `exit`, `tilde` medidos; a de coluna zero está declarada abaixo).
  `mut_RUN_blocked_not_escalated` foi **reancorado** — o range antigo não continha mais a porta.
- **Achado 7** — corrigido em `319239b` — a fase nomeada ao HUMANO virou asserção diferencial, no
  mesmo par de corridas e sem custo de sessão. Prova: fixando a fase errada só na prosa e deixando
  a linha de ledger correta — a sabotagem que antes passava com a suíte inteira verde —
  `check-autonomy.sh` mata exatamente esta asserção.

## O que foi refutado

> Achado que você acredita estar errado **não** se resolve mudando o código para agradá-lo.
> Verifique; se estiver errado, registre aqui o porquê, com evidência. Concordar
> performaticamente com uma crítica equivocada é pior que o achado original.

- **`grep -m1` sem flag quiet seria a família `pipefail` que este repo já paga** — refutado. A
  RULE 3 do `check-pipefail.sh` mede *pipe* para dentro de `grep -m<N>`, e o sensor carrega um probe
  para exatamente esta forma: `tests/check-pipefail.sh:775-777`, `grep -m1 on a FILE (no pipe) is
  accepted`. Sem escritor a montante não há SIGPIPE. Nada mudado por causa disto.
- **O `while read` perderia `openbugs` num subshell** — refutado. É **herestring** (`done <<< "$(…)"`),
  não pipe; medido com 3 bugs (1 `human`, 1 `agent`, 1 sem campo), o gate responde `2`.
- **`set -e` mataria `gate_QA` numa captura cujo `grep` não acha** — refutado duas vezes: as capturas
  levam `|| true`, e **todo** call site de `gate_QA` a põe em contexto que suspende `errexit`
  (`if !`, `|| true`, `|| gate_rc=$?`). `openbugs=$((openbugs + 1))` é atribuição, cujo status é
  sempre 0 — a armadilha é `(( x++ ))`, que o código não usa.
- **O marcador `GATE_HANDOFF_BLOCKED` poderia sobreviver a uma volta e escalar a fase errada** —
  refutado por enumeração de **todas** as saídas do corpo do laço, mais uma corrida instrumentada
  com `$$`/`BASHPID` sobre as populações inteiras de fixture dos dois sensores: **0** eventos de
  `gate_QA` entrando com o marcador já armado. Continua sendo consequência do FLUXO e não da
  construção, e é isso que o comentário do `bin/sdd:505-523` já declara.
- **Remover o `GATE_HANDOFF_BLOCKED=0` da entrada de `gate_QA` seria fail-open sem probe** —
  refutado: o mundo não é construível hoje (nenhum caminho roda `gate_QA` duas vezes no shell pai
  com o marcador aceso entre as duas). Declarado, não consertado — e dito qual mundo não se
  conseguiu construir, nunca que ele não existe.
- **`cd` relativo sem `CDPATH=''` e classe negada multibyte em `awk`** — refutados: o diff da EXEC
  não introduz `cd` nenhum, e o `awk` que esta rodada acrescentou só usa classes **positivas** ASCII
  (`[[:space:]]`, `[*]`), sem classe negada.
- **A regra de coluna zero estaria sem probe** — refutada pela medição, e o resultado virou limite
  declarado em vez de conserto: a regra é defendida **duas** vezes (o `^-` do `awk` e o `^\-` do
  matcher). Medidas as quatro combinações no mesmo fixture — só `awk LOOSE + grep LOOSE` deixa
  passar. A asserção é *property probe* e não *rule probe*, e o comentário diz isso com a tabela.
- **Nome de arquivo com espaço quebraria o laço novo** — refutado (`IFS= read -r` resolve). Nome com
  **quebra de linha** de fato divide errado, mas conta **a mais** (falha fechada) e o `grep -rl | wc
  -l` anterior contava igual: não é regressão.

## Achados fora de escopo

> O que não cabe nesta missão vai para o `TODO_FILE`, nunca para o diff. Uma linha por item, no
> formato do repo, e a referência aqui.

- **`sdd retry` devolve 3 sem escrever linha de escalada no ledger** — registrado no `TODO.md`
  (2026-08-26). Anterior a esta missão e vale para TODA escalada, não só a nova; reproduzido aqui
  (rc 3, ledger só com a linha de sessão). O juiz do kaizen lê um ledger sem eventos que aconteceram.
- **Citação NÃO-cercada acima do cabeçalho ainda vira o gênero** — registrado no `TODO.md`
  (2026-08-26). É o resíduo do achado 1, de alcance baixo (exige arquivo que viole a ordem do
  template), declarado no comentário do `bin/sdd` — e entra no backlog assim mesmo, porque pela
  régua do D15 fail-open declarado continua entrando: escrever não conserta, só deixa de mentir.
  Não foi consertado nesta rodada porque a direção certa (ancorar o gênero no mesmo bloco contíguo
  de campos que traz a linha `Status:`) é desenho, não remendo.

Catraca movida no mesmo diff, que é a regra: `todo-findings` 72 → **74** em
`tests/health-baseline.txt`, e `sdd health` responde `ratchet: 1 known debt(s), none new`.

## Pendências / Decisions for a Human

> O que exige julgamento humano: trade-off de arquitetura, quebra de contrato, decisão de produto.
> Se não houver, escreva `Nenhuma.` — a seção vazia é ambígua.

Nenhuma. Nenhum achado desta rodada precisou de decisão de produto, política ou acesso externo, e
nenhuma intervenção humana entrou na linha. O que resta para a fase DOCS (`KAIZEN_LOG.md` e a lição
do gate insatisfazível no `CLAUDE.md`) é aditivo e já estava previsto nos itens K7/K8 do checklist
kaizen — não é pendência desta rodada.
