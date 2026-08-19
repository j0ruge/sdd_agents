---
missao: 20260819-fecho-que-nao-mente
data: 2026-08-19
---

# Plano — O caminho que certifica o fecho de uma missão para de afirmar o que não mediu

> **Teste de autocontenção:** uma sessão nova, sem nenhuma memória da conversa que gerou este
> plano, lendo apenas `00-missao.md` + `01-plano.md` + `checkpoint.md`, consegue executar?
> Se a resposta for "só se souber X", **X vai escrito aqui**.

## Contexto verificado (não re-descobrir)

Tudo abaixo foi medido nesta sessão contra a `main` em **`7957a85`**, árvore limpa. O que **não**
foi medido está na tabela de riscos, marcado como risco — nunca aqui.

### O chão

- Suíte rápida verde — `./tests/run-all.sh` → última linha `suite green`, rc 0.
- `TEST_CMD="tests/run-all.sh"` — `.sdd/config.sh:6`. `BUDGET_PER_PHASE_USD=40` (`:24`),
  `JIRA_ENABLED=false` (`:28`), `OUTPUT_LANG="pt-BR"` (`:34`).
- `TODO.md` com **72 achados** — `./tests/check-todo.sh` → `  ok    72 finding(s), all within 8
  lines and carrying anchor + date`. A catraca concorda: `tests/health-baseline.txt:32` →
  `todo-findings 72`. ⚠️ Este número **nunca** sai de um `grep -c '^- \[ \]'`, que responde um a
  mais (conta a linha de exemplo do bloco cercado do cabeçalho).
- **Nenhum item do `TODO.md` carrega `RESOLVIDO por <hash>` hoje** — varredura desta sessão sobre
  os 4 casamentos de `RESOLVIDO por`: os quatro são texto do cabeçalho ou o corpo do item que fala
  *sobre* a convenção, nenhum é um fechamento. Portanto a lista de **resolvidos a apagar** desta
  triagem está **vazia**: a missão passada apagou os seus na hora (`6136d39`).

### Os quatro defeitos, reproduzidos

- **`bin/sdd:1818`** — a linha real é
   `elif grep -qE '^score: [0-9]+ caught, 0 known gap' <<< "$score_line"; then` seguida de
   `ok "mutation: $score_line"`. Reprodução:
   `grep -qE '^score: [0-9]+ caught, 0 known gap' <<< "score: 103 caught, 0 known gap(s), of 104"`
   → casa. O `caught` (103) e o `of` (104) nunca são comparados.
   ⚠️ O `TODO.md` ancora este achado em `bin/sdd:1801`, que hoje é um `fi` solto — a âncora
   apodreceu 17 linhas. Use `1818`.
- **`bin/sdd:529`** — âncora **exata**, conferida: a linha é
   `if (grade != "A") { print crit " = " (grade == "" ? "<empty>" : grade); exit }`. O bloco
   completo do extrator vive em `bin/sdd:520-533`, dentro de `gate_REVIEW()` (`bin/sdd:506`).
   Ele faz `crit = f[2]; grade = f[3]` e **nunca toca em `f[4]`**. Reprodução desta sessão: o
   `awk` do gate, copiado verbatim, sobre uma tabela `### Overall Grade` com `A` em toda linha e
   `PREENCHER` em toda `Rationale`, imprime **string vazia** — e vazio é o valor que faz
   `gate_REVIEW` retornar 0.
- **`tests/run-all.sh --list`** — com um `PATH` sem `shellcheck`, a saída traz
   `  (linter absent — skipped)` no meio dos 14 passos. A mensagem está fora do `run()`
   (`tests/run-all.sh:65-68`, onde o modo lista vive), no bloco
   `if command -v shellcheck …; else printf '\n  (linter absent — skipped)\n'` por volta de
   `tests/run-all.sh:150-157`. E `--list` **sai 0 tendo rodado nada** (`tests/run-all.sh:228`,
   `[ "$LIST_ONLY" = 1 ] && exit 0`), que é o contrato correto do modo — o perigo é o consumidor.
- **`tests/run-all.sh:23`** — âncora exata, conferida: o comentário
   `# The mutation catalogue is OPT-IN, and that is a decision with a measured reason.` Não há
   `.github/` neste repo. O único chamador de `--with-mutation` é `cmd_health` (`bin/sdd:1794`,
   `out="$( cd "$kit" && tests/run-all.sh --with-mutation 2>&1 )" || rc=$?`).

### Onde cada sensor mora (não procure de novo)

- **O `--list` é território do `tests/check-health.sh`.** Ele já lê as duas listas
  (`SURFACE_PLAIN` em `:846`, `SURFACE_FULL` em `:847`), compara uma com a outra, tem
  `SURFACE_FLOOR` anti-vacuidade (`:822`) e uma passada de sabotagem pronta (`surface_degrade`,
  `:918`). A asserção nova do I2 entra ali, ao lado das regras 1–4.
- **Gate é território do `tests/check-gates.sh`.** É lá que vivem as asserções diferenciais de
  `gate_REVIEW` e `gate_PR`. ⚠️ Os fixtures desse arquivo **não** carregam `tests/check-mutation.sh`
  (conferido: nenhum `cp` de `tests/` neles), o que é exatamente o que mantém o I4 invisível para
  eles — e por isso o I4 precisa de um fixture **novo**, que tenha o arquivo, para medir os dois
  ramos.
- **O catálogo (`tests/check-mutation.sh`) só sabota `bin/sdd`.** Convenção: uma função
  `mut_<AREA>_<o_que_cega>()` recebendo o caminho do `bin/sdd` da sandbox e aplicando `sed -i`
  (exemplo em `tests/check-mutation.sh:195`, `mut_PR_no_artifact`).
- **`cmd_health()` começa em `bin/sdd:1774`.** A checagem 1 é a suíte (`:1794`), a 2 é o `score:`
  (`:1815-1822`), a 3 é a contagem do `TODO.md`.

### Armadilhas desta casa que valem dinheiro (do `CLAUDE.md` e das missões recentes)

- **Captura sob `set -euo pipefail` mata na atribuição.** `x="$(cmd)"` derruba o processo quando
  `cmd` sai não-zero — e para `grep` "não achou nada" já é não-zero. Todo `health_bad` escrito
  abaixo de uma captura desguardada é código morto. Use `|| rc=$?`, `|| true` ou
  `if out="$(…)"; then`. A regra `guard:` do `check-health.sh` cobra isso enumerando a região.
- **`printf … | grep -q` devolve 141 sob `pipefail`.** Use herestring (`<<< "$var"`).
- **`grep -m<N>` sem quiet é a mesma família** e é cobrado pela RULE 3 do `check-pipefail.sh`.
- **`cd` com operando relativo dentro de `$(...)` leva `CDPATH=''`.** Cobrado pela RULE 2.
- **`sed` de mutante precisa de endereço.** Duas mutações do catálogo hoje sabotam um segundo
  sítio calado por não endereçarem o corpo da função (item vivo no `TODO.md`,
  `tests/check-mutation.sh:203` e `:508`). Os quatro mutantes novos **endereçam a função**.
- **`&` numa substituição de `sed` é "todo o trecho casado"** — escape com `\&`.
- **Probe de sabotagem prova primeiro que sabotou.** Ancore em CÓDIGO, nunca em número de linha, e
  faça o probe **morrer alto** quando o trecho esperado não mudou.
- **Sessão headless que encerra o turno esperando comando morre.** Nunca termine o turno com um
  comando rodando — três rodadas de REVIEW e US$ 104 foram queimados assim.
- **Fase que morre com a árvore suja faz o runner rederivar EXEC em laço.** Se isso acontecer duas
  vezes, pare e escreva nas notas do checkpoint em vez de deixar o laço girar (~US$ 25 a volta).
- **Mexeu em `agents/*.md`? O espelho é `sdd install --force`, nunca `cp` nem Edit.**

### A medição que contraria o handoff humano de hoje

`docs/handoffs/zerar-todo-20260819.md:53-58` chama a re-derivação das 33 âncoras do `TODO.md` de
bloqueadora — *"enquanto isso não for consertado, todo item é suspeito"*. Esta sessão testou a
afirmação usando as âncoras de que **este lote** precisava, e ela não se sustenta como bloqueio:

| âncora citada no `TODO.md` | conferida hoje |
|---|---|
| `bin/sdd:529` (`gate_REVIEW` lê só `Grade`) | **exata** |
| `tests/run-all.sh:23` (catálogo sem dono) | **exata** |
| `bin/sdd:1801` (`sdd health` diz `ok`) | podre — o alvo está em `1818` |
| `tests/run-all.sh:146` (`--list`) | podre — a linha é vazia; o alvo está por volta de `150-157` |

Duas de quatro erradas **atrasam** a triagem; nenhuma a impediu, porque o **título** do item
identifica o alvo sozinho. E há o argumento de custo, medido na missão passada: re-derivar cedo é
desperdício, porque a própria missão move as linhas depois (8 âncoras podres no planejamento, mais
5 quebradas de novo no I4 pela mesma missão). Por isso a re-derivação fica **para a missão
seguinte**, feita depois desta.

⚠️ Achado desta varredura, que a missão seguinte deve usar: **há uma classe pior que "linha
errada" — a âncora que nomeia um arquivo inexistente.** Duas instâncias vivas hoje:
`check-autonomy.sh:140` (falta o prefixo `tests/`) e `docs/adr/0003:57` (falta o `.md`). Essa
classe é **sintática e barata de cobrar**, ao contrário da re-derivação semântica que o `TODO.md`
declara fora de alcance. Não vira incremento aqui; fica registrada para quem pegar o item.

## Arquitetura da mudança

Quatro pontos independentes do mesmo mecanismo, e nenhum deles inventa estrutura nova — três
apertam uma comparação que já existe, e o quarto troca um rótulo por um artefato.

**I1, I2 e I3 são apertos locais.** O `sdd health` passa a extrair os dois números da mesma linha
`score:` e a exigir que sejam iguais; o `--list` passa a imprimir só o que sai de `run()`; o `awk`
do `gate_REVIEW` passa a ler também `f[4]` e a recusar placeholder. Nenhum toca em contrato de
artefato, nenhum muda tabela de fase.

**I4 é o único desenho.** O problema é "o catálogo não tem dono automático", e a tentação óbvia —
`gate_PR` **rodar** o catálogo — é justamente o que `4c86712` desfez, porque segurar a árvore por
~17 a 21 minutos dentro de um gate tornou a fase REVIEW insatisfazível headless. Então o gate não
roda o catálogo: ele **exige a evidência** de que ele rodou.

- **Quem carimba:** `cmd_health()` (`bin/sdd:1774`), depois de as checagens 1 e 2 passarem — e
  **só** então. Carimbar antes do I1 gravaria em disco a certificação de um catálogo com
  sobrevivente; é essa a dependência que ordena os incrementos.
- **O que o carimbo é:** um arquivo em `.sdd/` (já gitignored, já o diretório de estado local)
  cujo nome ou conteúdo é o **hash do conteúdo** de `bin/ tests/ templates/ config/` — os quatro
  diretórios que a sandbox de mutação copia, e portanto exatamente o que o catálogo mede. **Não**
  é o `HEAD`: a fase PR commita markdown de handoff, o que moveria o `HEAD` e invalidaria um
  carimbo ainda válido.
- **Quem cobra:** `gate_PR()` (`bin/sdd:589`), como **último** requisito, depois do `50-pr.md` e
  do `gh pr view` que já existem — assim a mensagem mais provável continua sendo a que já é.
- **Onde ele se cala:** o requisito só existe se `$REPO_ROOT/tests/check-mutation.sh` existir.
  Escopo por **artefato**, jamais por identidade de repositório: a porta por identidade que já
  existe (`cmd_kaizen`) tem bug vivo em worktree, registrado no `TODO.md`, e herdá-lo seria
  comprar um defeito conhecido. Em repo-alvo o arquivo não existe e nada muda.
- **`GATE_WHY` nomeia o comando que resolve:** `sdd health` — a mesma regra da mensagem de suíte
  vermelha (`bin/sdd:1799`), que existe porque uma mensagem sem o comando manda o operador rodar a
  suíte rápida, ver verde, e concluir que o health mente.

## Incrementos

A tabela executável vive em `checkpoint.md` (é ela que o runner lê). Aqui fica o **porquê** de
cada fatia — o detalhe que não cabe numa célula.

> ⚠️ **O texto de cada asserção nova é contrato entre dois arquivos**, como o `score:` já é: o
> sensor imprime a frase, o Check do `checkpoint.md` a procura ancorada em `^  ok    `. Mudar a
> frase de um lado só deixa a suíte verde e o Check vazio. Use as frases **exatas** abaixo.

### I1 — O `sdd health` compara os dois números do `score:`

**O quê:** a checagem 2 de `cmd_health` extrai `caught` e `of` da mesma linha `score:` e só diz
`ok` quando são iguais **e** `known gap` é `0`. Diferentes ⇒ `health_bad` nomeando os dois números.
**Onde:** `bin/sdd:1815-1822`; asserção em `tests/check-health.sh`; mutante em
`tests/check-mutation.sh`.
**Como (TDD):** primeiro a asserção, com um mundo de fixture cuja suíte imprime
`score: 103 caught, 0 known gap(s), of 104` — ela tem de **reprovar** contra o `bin/sdd` de hoje
(esse é o vermelho que prova que a asserção mede algo). Só então o conserto.
⚠️ A asserção precisa do par: um fixture com `104 caught … of 104` seguindo `ok`, e o de
sobrevivente indo para `health_bad`. Um lado só não distingue nada.
**Check:** `o=$(bash tests/check-health.sh 2>&1); grep -c '^  ok    mutation: a score whose caught differs from total is refused' <<< "$o"` → `1`
**Sensor durável:** a asserção acima + `mut_HEALTH_mutation_survivor_blind` no catálogo (o `sed`
endereçado ao corpo de `cmd_health`), devolvendo a comparação à forma frouxa de hoje.
**Reversível por:** `git revert` do commit — a checagem 2 volta ao `elif` de uma condição só.

### I2 — O `--list` imprime só passos, e um `TEST_CMD` com `--list` é recusado

**O quê:** duas metades do mesmo buraco. (a) a mensagem `(linter absent — skipped)` sai do caminho
da lista — ela pertence à stderr ou ao ramo não-lista, porque `--list` promete "os passos que
rodariam" e ela não é um passo, e ainda infla o `SURFACE_FLOOR`. (b) `sdd health` reprova um
`TEST_CMD` que carregue `--list`: é um comando que sai 0 tendo rodado nada, e como `TEST_CMD` faria
**todo gate do runner** passar na hora com um log de 14 linhas plausíveis.
**Onde:** `tests/run-all.sh` (o bloco do linter, por volta de `:150-157`); `bin/sdd`, dentro de
`cmd_health()`; asserções em `tests/check-health.sh` (ao lado das regras de superfície, `:807-966`);
mutante para a metade (b), que é a que vive no `bin/sdd`.
**Como (TDD):** a asserção de (a) roda `--list` com um `PATH` sem `shellcheck` e exige que **toda**
linha da saída seja um nome de passo — hoje ela reprova, e é esse o vermelho. A de (b) é
diferencial: `TEST_CMD="tests/run-all.sh"` passa, `TEST_CMD="tests/run-all.sh --list"` reprova.
⚠️ O probe de (a) precisa provar que **armou o veneno** — que o `shellcheck` de fato não está no
`PATH` do sub-processo — antes de concluir qualquer coisa; probe de ambiente sem veneno armado é
decoração. `env -u SDD_MUTANT` continua obrigatório, como as regras vizinhas já fazem.
**Check:** `o=$(bash tests/check-health.sh 2>&1); grep -c '^  ok    surface: --list prints steps only, and a TEST_CMD carrying it is refused' <<< "$o"` → `1`
**Sensor durável:** a asserção acima (as duas metades sob uma frase) + `mut_HEALTH_testcmd_list_blind`.
**Reversível por:** `git revert` — o `--list` volta a vazar a mensagem e o `health` volta a aceitar
qualquer `TEST_CMD`.

### I3 — O `gate_REVIEW` recusa placeholder na `Rationale`

**O quê:** o `awk` do `gate_REVIEW` passa a ler `f[4]` e a reprovar a linha cuja justificativa é um
placeholder — vazia, `PREENCHER`, ou um texto entre `<` e `>` como os que `templates/review.md:37-44`
carrega. A mesma recusa vale para o campo `gate:` do frontmatter, que é a outra metade do selo.
**Onde:** `bin/sdd:520-533`; asserção diferencial em `tests/check-gates.sh`; mutante em
`tests/check-mutation.sh`.
**Como (TDD):** asserção **diferencial**, que é a forma que nenhum regime de fixture satisfaz por
acidente — dois artefatos comparados entre si: `40-review-rN.md` com `A` + justificativa real
**passa**; o mesmo arquivo com `A` + `PREENCHER` **reprova**, e a mensagem de `GATE_WHY` nomeia o
critério ofensor. Hoje os dois passam; esse é o vermelho.
⚠️ Não invente o fixture de memória: a instância viva é
`docs/handoffs/20260818-lote-facil/40-review-r1.md`, e o template é `templates/review.md:33-44`.
⚠️ Recusar `<…>` sem recusar `<empty>` (que o próprio gate já imprime como diagnóstico) é a
fronteira fina aqui — a lista de tokens recusados vai escrita no comentário da função, não
adivinhada pelo leitor seguinte.
**Check:** `o=$(bash tests/check-gates.sh 2>&1); grep -c '^  ok    gate_REVIEW: a placeholder Rationale does not buy an A' <<< "$o"` → `1`
**Sensor durável:** a asserção diferencial acima + `mut_REVIEW_placeholder_rationale_blind`
(devolve o extrator a ler só `f[3]`), endereçado ao corpo de `gate_REVIEW`.
**Reversível por:** `git revert` — o extrator volta a ignorar `f[4]`.

### I4 — O catálogo de mutação ganha dono: `sdd health` carimba, `gate_PR` exige

**O quê:** o desenho descrito em § Arquitetura. `cmd_health` grava o carimbo depois de a suíte
completa **e** o `score:` (já consertado pelo I1) passarem; `gate_PR` reprova enquanto não houver
carimbo válido para o conteúdo atual de `bin/ tests/ templates/ config/`, e **só** onde
`$REPO_ROOT/tests/check-mutation.sh` existe.
**Onde:** `bin/sdd` — `cmd_health()` (`:1774`) e `gate_PR()` (`:589`); asserção em
`tests/check-gates.sh` com **fixture novo**; mutante em `tests/check-mutation.sh`.
**Como (TDD):** asserção diferencial de três ramos, escrita antes: (1) fixture **sem**
`tests/check-mutation.sh` → o gate se comporta exatamente como hoje (é isto que prova que nenhum
repo-alvo foi afetado, e é o ramo que os fixtures atuais já exercitam); (2) fixture **com** o
arquivo e **sem** carimbo → reprova, com `GATE_WHY` nomeando `sdd health`; (3) o mesmo fixture com
carimbo válido → passa. Depois de gravado o carimbo, mexer num arquivo de `tests/` tem de fazer o
ramo (3) virar (2) — é esse termo que prova que o carimbo chaveia no **conteúdo** e não no relógio.
⚠️ Este incremento muda `gate_PR`, que `current_phase()` reavalia em **todo** comando. Rode
`./bin/sdd status`, `./bin/sdd why` e `./bin/sdd run --dry-run` desta missão antes de commitar: um
gate que passou a reprovar em silêncio muda a fase projetada de toda missão do repo.
**Check:** `o=$(bash tests/check-gates.sh 2>&1); grep -c '^  ok    gate_PR: the mutation stamp is demanded only where the catalogue lives' <<< "$o"` → `1`
**Sensor durável:** a asserção de três ramos acima + `mut_PR_stamp_blind` (o gate volta a não olhar
o carimbo), endereçado ao corpo de `gate_PR`.
**Reversível por:** `git revert` do commit — o carimbo vira um arquivo órfão em `.sdd/`, inerte e
gitignored; nenhum gate volta a depender dele.

## Riscos e não-feitos

| Risco | Probabilidade | Mitigação |
|---|---|---|
| O I4 quebra fixtures de `check-gates.sh`/`check-dry-run.sh` que alcançam a fase PR | baixa | Conferido nesta sessão: nenhum fixture desses arquivos copia `tests/`, então o escopo por artefato os deixa no ramo (1). Se algum copiar, o ramo (1) da asserção acusa antes do commit. |
| O I4 torna o `gate_PR` insatisfazível para quem não roda `sdd health` | **alta — e é o objetivo** | É Jidoka: a linha para com `GATE_WHY` nomeando `sdd health`. O que não pode acontecer é parar **sem dizer o comando**; a mensagem é parte do incremento, não enfeite. |
| O carimbo custa caro a cada avaliação de gate (o `gate_PR` é reavaliado em todo comando) | média | O hash cobre ~4 diretórios de arquivos pequenos. **Medir** o tempo de `./bin/sdd status` antes e depois e registrar nas notas do checkpoint; se passar de ~1 s, chavear o carimbo por `git rev-parse HEAD:<dir>` das quatro árvores, que o git já tem calculado. |
| Recusar placeholder no I3 reprova uma revisão legítima que usou `<` e `>` na prosa | média | A recusa mira a célula **inteira** sendo um placeholder, nunca a presença do caractere. O fixture de quase-acerto (justificativa real contendo `<A>` no meio da frase) entra como probe. |
| O I2 (a) muda a saída de `--list`, de que o `SURFACE_FLOOR` depende | média | O piso é anti-vacuidade e conta linhas; tirar uma linha que **não** é passo pode cruzá-lo. Recontar o piso no mesmo commit, com o histórico no comentário — é o quarto lugar da regra "sensor novo entra em quatro lugares" do `CLAUDE.md`. |
| A suíte fica mais lenta com quatro asserções novas — e cada uma custa **uma vez por mutante** | média | Medir `time ./tests/run-all.sh` antes e depois e registrar nas notas. Se o `TEST_CMD` passar de ~60 s, o achado vai para o `TODO.md`; **não** se corta asserção para ganhar relógio. |
| Achados novos nascem durante a missão e a catraca reprova | **alta — aconteceu nas duas últimas** | Achado novo entra no `TODO.md` **e** move `tests/health-baseline.txt` no mesmo commit. Crescer é permitido; crescer calado, não. |
| Estimativa de custo: 4 incrementos + QA + REVIEW + DOCS + PR | — | A missão passada, com 6 incrementos e 3 rodadas de REVIEW, custou **US$ 230,45**. Esta é menor; ainda assim, se o orçamento apertar, o incremento a sacrificar é o **I2**, o único cujo defeito não tem instância viva. |

**Não-feitos declarados:** a re-derivação das âncoras do `TODO.md`; CI; o auto-teste do
`check-templates.sh`; as famílias grandes do `check-todo.sh` e do `check-health.sh`; e a decisão
`RESOLVIDO por` × catraca. Todos permanecem no `TODO.md`, intocados.

## Verificação end-to-end

Quando os quatro incrementos estiverem `done`:

1. **Os quatro sensores, na suíte rápida:**
   `./tests/run-all.sh` → `suite green`, rc 0, e as quatro frases de asserção dos Checks presentes
   com `^  ok    `.
2. **O catálogo, uma vez:** `./bin/sdd health` → `kit healthy`, rc 0, com a linha
   `score: N caught, 0 known gap(s), of N` em que **`caught == of`** e `N` é pelo menos **4** maior
   que o `N` medido no começo da missão (anote o de partida na primeira nota do checkpoint — o
   número não se escreve em prosa em lugar nenhum, sai sempre da linha `score:`).
3. **A prova de que o I1 não é decoração:** com o catálogo já verde, o `sdd health` de novo — desta
   vez ele também **gravou o carimbo**, e é ele que destrava o `gate_PR` da própria missão. Se a
   fase PR reprovar por falta de carimbo, o I4 está funcionando; rode `sdd health` e siga.
4. **Os três defeitos que deixam de reproduzir**, um comando cada, registrados no
   `40-review-r<N>.md`: o `score:` com sobrevivente indo para `health_bad`; o `awk` do
   `gate_REVIEW` nomeando o critério com `PREENCHER`; o `--list` sem linha que não seja passo.
