---
missao: 20260817-eixo-do-juiz
fase: REVIEW
rodada: r2
status: done
data: 2026-08-17
---

# Review — rodada r2 — o eixo do juiz

## TL;DR

**Esta rodada NÃO fecha em A, e a suíte termina VERMELHA.** As três HIGH que a r1 deixou (N1, N2,
N3) foram consertadas com prova, e mais nove achados dela também. Mas uma passada adversarial
independente sobre o **meu próprio diff de r2** achou uma **CRITICAL nova** (`CDPATH`), e o conserto
dela ficou a meio caminho quando o orçamento da sessão acabou: o `sed` que trocaria `CDPATH=` por
`CDPATH=''` (para o `shellcheck` SC1007) **não aplicou**, então a âncora de
`mut_LEDGER_repo_root_common_parent` não casa e o catálogo lê `63 caught of 64`.

O gate vai reprovar de propósito. A r3 tem uma lista curta e explícita.

## O que fechou nesta rodada (com hash)

| # | Achado da r1 | Sev | Conserto |
|---|---|---|---|
| N1 | dois submódulos irmãos colapsam numa identidade | HIGH | `913cb3f` |
| N7 | repo bare devolve o diretório-pai | MEDIUM | `913cb3f` |
| N2 | `--all-repos` agrega por slug sem o repo na chave | HIGH | `913cb3f` |
| N3 | a metade do **gate** do `one series` não tem probe | HIGH | `913cb3f` |
| N4 | guarda do `axis_note` intercambiável com `sufficient == false` | MEDIUM | `913cb3f` |
| N5 | três enfraquecimentos de `degenerate_axis` sem probe | MEDIUM | `913cb3f` |
| N6 | a normalização `pwd -P` sem probe | MEDIUM | `913cb3f` |
| N8 | `degenerate_axis` é interruptor de mão única sobre o histórico | MEDIUM | `913cb3f` |
| N9 | quatro asserções menores sem probe | LOW | `913cb3f` |
| N10 | `adr 0003 is named by bin/sdd` media um comentário | MEDIUM | `913cb3f` |
| N11 | `no data` de ledger misto dá conselho impossível | LOW | `913cb3f` |
| N12a | diagnóstico do `jq` impresso em dobro | LOW | `913cb3f` |
| — | prosa do contrato em 5 arquivos | — | `d0288fe` |
| — | escrituração do `TODO.md` (âncoras + hash duplo) | — | `f14c60c` |

**Medido, não suposto.** `ledger_repo_root` passou a ser o `.git` compartilhado **em si** (não o
pai), com `/repo/.git → /repo` só como cosmética e retida em bare. Verificado em 10 formas de git:
`solo`, subdiretório, worktree, symlink → **uma** identidade; `suba`/`subb`, `bare1`/`bare2` →
**distintas**; fora de repo → vazio. `mission_key` virou **array** `[repo, mission]`: a grafia com
`|` colidia (`a|b`+`c` = `a`+`b|c`, duas missões lidas como uma) e `+` sobre `repo` numérico
**matava** o `jq` — `sdd autonomy` morria com `malformed row` sobre um arquivo que o próprio
`jq -se .` acabara de certificar legível. `degenerate_axis` passou a olhar as últimas
`guard_floor` versões, com par diferencial de 4 shas / 5 sessões que diferem só em **qual** sha
ganhou a segunda.

**Sabotagem adversarial: 16 degrades, 16 vermelhos, cada um na asserção dona da regra.** O do N3
é o que importa mais: forçar `gate_KAIZEN` a ler por repo (`LEDGER_ALL_REPOS=0 kaizen_series`)
deixava as **três** asserções `one series` verdes — o `BUG-1` da QA *verbatim*, uma função adiante.
Hoje o par `real gate:` dirige o gate de verdade (veredito em disco citando o sha que o **prompt**
entrega; rc do runner é a asserção) e **as duas metades** morrem sob o degrade.

20 asserções novas em `check-autonomy.sh` e `check-kaizen.sh`; catálogo 61 → 64 com três mutações
novas. ⚠️ As novas ficaram **fora** dos prefixos `all-repos`/`no-repo`/`one series`/`degenerate
axis`, que os Checks do `checkpoint.md` contam com `-c` e exigem em exatamente 2 — os seis Checks
seguem satisfeitos (`2/2/2/2/2` e `2 1`).

## Achados NOVOS desta rodada — trabalho da **r3**

> Todos no diff **desta** missão; nada vai para o `TODO.md`. Os três primeiros vieram de uma
> revisão adversarial independente do meu próprio diff de r2 — isto é, de código que **eu** escrevi
> nesta sessão e que ninguém mais havia revisado.

### C1 — `CDPATH` colapsa todos os repos da máquina numa identidade só · **CRITICAL** · conserto A MEIO

`bin/sdd:906`. `$common` é **relativo** na raiz (`.git`), e o bash consulta `CDPATH` para qualquer
operando que não comece com `/` — **imprimindo o diretório no stdout** quando o resolve por lá,
dentro da substituição de comando. Medido: com `CDPATH=/tmp/rr/poison` (um checkout), quatro repos
distintos devolveram **a mesma** identidade, e escritor e leitores concordam nela — `other_repo: 0`,
nada excluído, nada dito. É exatamente a contaminação silenciosa que esta missão existe para
impedir, alcançável por variável de ambiente. `CDPATH=.` sozinho acrescenta uma **segunda linha** à
resposta, metendo um `\n` no campo `repo:` do ledger.

Pré-existente em espécie (o `cd "$common/.."` da r1 era igualmente relativo) mas vive numa linha
que **esta** missão mudou.

**Estado:** o conserto (`CDPATH=` nos dois `cd`) está no arquivo e **funciona** — medido, a
identidade fica estável com `CDPATH=.` e com `CDPATH` envenenado. Mas o `shellcheck` reprova com
**SC1007** ("remove space after =") e o `run-all.sh` roda o linter, então a suíte fica vermelha. A
troca para `CDPATH=''` **não aplicou** (o `sed` falhou), e por consequência a âncora de
`mut_LEDGER_repo_root_common_parent` não casa mais: `63 caught of 64`, `CATALOGUE-BROKEN`.
**Direção para a r3:** trocar por `CDPATH='' cd` (ou `unset CDPATH` num subshell), atualizar a
âncora da mutação no mesmo commit, e acrescentar a asserção que hoje **não existe** — identidade
estável sob `CDPATH` envenenado.

### C2 — `gate_KAIZEN` não checa o status de `kaizen_series`, e confunde corrupção com "ainda não julgado" · **HIGH**

`bin/sdd:2727`. `series="$(kaizen_series)"` sem verificação, e `cmd_kaizen` chama `gate_KAIZEN ||
gate_rc=$?`, o que **desliga o errexit** para tudo dentro. Com o `jq` morrendo, `series=""` ⇒
`expected=""` ⇒ `GATE_WHY="no verdict for kit  yet"`: ledger ilegível fica indistinguível de "não
julgado", e `sdd kaizen` **gasta uma sessão opus** sobre uma série que não conseguiu ler.
`cmd_autonomy` re-levanta com `die`; este caminho não. O gatilho que eu tinha (o `mission_key`
fatal) está fechado pelo array, mas **o buraco do gate continua aberto** para qualquer outra causa.

### C3 — a janela de `degenerate_axis` falsa-positiva num repo saudável · **MEDIUM**

`bin/sdd:2554-2567`. Fixture: duas versões com 3 sessões/3 missões cada, depois três versões com 1
sessão cada ⇒ a regra nova diz `true`, a antiga dizia `false`. Mas um trecho quieto de três versões
**não** é prova de que o eixo não funciona ali — o **mesmo ledger** prova que 3-missões-por-versão é
alcançável, e aconteceu duas vezes. O campo passa a errar exatamente a distinção que ele foi criado
para fazer, e alimenta o prompt do juiz. O N8 era real; **esta é a troca que o conserto dele
introduziu**, e ela precisa de uma terceira formulação (por exemplo: janela **e** nenhuma versão do
histórico tendo alcançado o piso).

### C4 — o par `help`/parsers mede a *frase* da morte, não a aceitação · **MEDIUM**

`tests/check-autonomy.sh`. As duas asserções novas leem `grep -c 'unknown'`. Medido: (a) trocar os
dois braços `*) die "unknown … option"` por `*) : ;;` deixa **tudo verde** — inclusive somando o
typo `--allrepos` no help, que é o defeito que o par diz caçar; (b) fazer `--all-repos)` **morrer**
com outra frase deixa a asserção `ok` enquanto o comando rejeita a flag. Direção: ler aceitação por
**rc 0**, e acrescentar a cláusula de que um *near-miss* (`${HELPFLAG}x`) é rejeitado.

### C5 — duas asserções sem testemunha de leitura · **MEDIUM** · uma consertada

`axis_case` não tinha piso anti-vacuidade: stubbar `axis_row` para não escrever nada deixava
**quatro** das seis asserções verdes, porque ledger vazio lê `false/no/false`, que era exatamente a
expectativa delas. **Consertado nesta sessão** (quarto campo com a soma das sessões; re-medido: o
mesmo stub agora derruba **6 de 6**). Segue aberta a irmã: `unattributable shapes: … outside any
repo` lê `0` de um comando que talvez não tenha lido nada — o `0` é indistinguível de recusa. Par
numa invocação (`[.guard.sessions, .excluded.no_repo]` ⇒ `0 3`).

### C6 — identidade partida num bare cujo basename é `.git`, e o comentário mentiroso · **LOW**

`--is-bare-repository` é propriedade do **ponto de entrada**, não do repositório, então um bare em
`/x/.git` lido de si mesmo devolve `/x/.git` e lido de um worktree seu devolve `/x` — um repo, duas
identidades. E `bin/sdd:2436` afirma que "check-autonomy.sh compara os dois `mission_key`": **não
compara**. A mutação usa `sed …/g` e sabota os dois de uma vez, então nem ela os veria divergir.
Comentário que promete sensor inexistente é a mesma falta que esta missão já removeu três vezes.

## O que foi refutado (com evidência)

- **N12b — `GIT_DIR`/`GIT_COMMON_DIR` no ambiente sobrepõem a identidade.** A r1 marcou como
  especulativo. **Refutado nos casos alcançáveis, por medição**: nos dois cenários reais de git hook
  — `GIT_DIR=.git` na raiz, e `GIT_DIR=<...>/worktrees/wt` dentro de um worktree — a identidade volta
  **correta** (`/tmp/envprobe/main` nas quatro leituras), porque `--git-common-dir` deriva o dir
  compartilhado a partir do `GIT_DIR`, que é justamente o que se quer. Um `GIT_DIR` apontado à mão
  para outro repo reetiqueta a linha, mas isso é comportamento do git e não desta função. Nenhuma ação.
- **A guarda do bare é redundante** (hipótese minha ao ver a sabotagem "C" sobreviver verde).
  **Refutada por medição**: um bare em `/x/hidden/.git` devolve `/x/hidden/.git` com a guarda e
  `/x/hidden` — um diretório que não é repo nenhum — sem ela. A guarda é alcançável e carrega
  asserção própria agora. Era a sabotagem que estava incompleta, não a regra.

## Estado ao fim da rodada

- **Commits:** `913cb3f` (N1–N12a + sensores + 3 mutações), `d0288fe` (prosa do contrato em 5
  arquivos), `f14c60c` (escrituração do `TODO.md`), mais o commit deste handoff.
- **Suíte:** ⚠️ **VERMELHA.** `shellcheck` SC1007 em `bin/sdd:906` e
  `CATALOGUE-BROKEN: LEDGER_repo_root_common_parent` (`63 caught, 0 known gap(s), of 64`). As duas
  são a **mesma** causa: o conserto da C1 a meio caminho. Antes da C1 a suíte estava verde com
  `64 caught of 64` e `sdd health` ok nos cinco — medido em `f14c60c`.
- **Métricas do `00-missao.md`:** todas seguem verdes, medidas ao vivo —
  `degenerate_axis: true` / `sufficient: false`, ADR 0003 citado no `--dry-run`, `autonomy` 55
  linhas vs `--all-repos` 66, worktree e `no-repo` verdes, catálogo ≥ 60.
- **Nada empurrado, nenhum PR aberto.**

## Boot da rodada **r3**

Ordem: **C1** (fechar o conserto: `CDPATH=''`, âncora da mutação no mesmo commit, asserção nova →
suíte verde), depois **C2**, **C3**, **C4**, **C5** (a metade que sobrou), **C6**.
⚠️ Não re-litigar R1–R10 (r1), N1–N12a (r2), nem os dois refutados acima.

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | C | As três HIGH da r1 fecharam com prova, e a disciplina de definição única foi estendida em vez de diluída (`guard_floor`, `shas_in_file_order`, `mission_key` — este último como array, que mata delimitador e coerção de tipo de uma vez). Mas o `shellcheck` está **vermelho** em `bin/sdd:906` e o conserto da C1 ficou a meio; a C3 é uma troca introduzida pelo próprio conserto do N8; e a C6 deixa um comentário prometendo um sensor que não existe — a mesma falta que esta missão já removeu três vezes. |
| Type Safety | B | A shape do contrato fecha: os dois produtores da série recebem as chaves novas e são comparados como conjuntos de chave; `degenerate_axis` é sempre booleano (janela vazia, fatia só-escalada, ledger vazio ⇒ `false`, nunca `null`); `guard.sufficient` e o campo exposto seguem na binding única `$observed`, e o piso agora vem de `guard_floor`. O array em `mission_key` removeu a classe inteira de erro de tipo que derrubava o `jq`. Desconta a C2: `gate_KAIZEN` lê `$(kaizen_series)` sem checar status, então uma série ilegível chega ao gate como string vazia e passa por "ainda não julgado". |
| Error Handling | C | Direção segura preservada e ampliada (`ledger_repo_root` devolve vazio em vez de morrer; o balde `no_repo` cobre ausente/null/vazio; o quinto estado de "no data" separa o remédio alcançável do impossível; leitor não morre mais sobre `repo` não-string). Mas a C2 é um caminho em que **corrupção vira "pendente"** e custa uma sessão opus, com o `errexit` desligado pelo `||` do chamador — e o `-z "$repo"` (C-F5 do revisor) ainda imprime "all of them belonging to some repo" sobre um ledger em que uma linha não pertence a nenhum. |
| Security | A | Varredura sobre o diff completo desta rodada: nenhum segredo, nenhuma entrada de rede, nenhum `eval` de dado externo (o único `eval` novo é num teste, sobre a linha que o próprio runner acabou de escrever, e é deliberado). A C1 é a única superfície de ambiente e ela é de **integridade de dado**, não de execução: `CDPATH` só desvia `cd`, nunca injeta comando. O `repo:` do ledger pode carregar caminho de cliente — já era assim, e a doc repete por que o arquivo mora em `$HOME` e nunca é commitado. |
| Performance | A | `jq` sobre JSONL de dezenas de linhas. A janela do `degenerate_axis` é O(janela × linhas) com janela 3, e a segunda leitura da série no `kaizen_axis_note` foi medida na r1 em 0,19 s para 3000 linhas / 1,1 MB. As 20 asserções novas acrescentam seis `git init` e um `git worktree add` em `/tmp`; a suíte com 64 mutantes segue no orçamento de sempre. |
| Test Coverage | B | 20 asserções novas, todas diferenciais, com piso anti-vacuidade, e a identidade lida **de volta do runner** em vez de composta pelo teste. A passada adversarial fechou 16 de 16 degrades, incluindo o do gate que deixava as três asserções `one series` verdes. Mas a auditoria independente ainda achou **duas** asserções fail-open (C4 inteira, C5 pela metade) — e uma delas reproduz o typo `--allrepos` que o próprio comentário do par diz caçar. Verde continua medindo menos do que afirma em dois pontos, e a C1 não tem asserção nenhuma. |
| Documentation | A | O schema da série está em passo nos cinco lugares que o descrevem (`bin/sdd`, `docs/pipeline.md`, `agents/sdd-kaizen.md` + a cópia `.claude/` byte-idêntica via `install --force`, `CONTEXT.md`), com `detail` nomeando o `repo`, o rótulo por repo×missão×fase e a janela do eixo. A frase que o **runner imprime** era falsa desde a janela e foi corrigida sem número no texto, para não criar uma terceira cópia do piso. O `failure-modes.md` prescrevia exatamente a fórmula que esta rodada removeu — um runbook mandando reproduzir o defeito — e hoje prescreve a que funciona. O `TODO.md` conta que `c514e36` sozinho fundia repos, e as quatro âncoras que **esta rodada** deslocou voltaram ao lugar. |
| **Overall** | **C** | Doze achados da r1 fechados com prova, incluindo as três HIGH que mudavam número que o juiz lê. Mas a revisão adversarial do **meu próprio** diff achou uma CRITICAL (`CDPATH` colapsando todos os repos da máquina numa identidade, por variável de ambiente) e o conserto dela ficou a meio quando o orçamento acabou: a suíte termina **vermelha** em duas linhas, as duas da mesma causa. Mais uma HIGH (gate confundindo corrupção com "pendente") e quatro achados médios, dois deles asserções que falham abertas. Inflar isto para A desligaria o sensor exatamente onde ele acabou de achar o defeito mais grave da missão. |
