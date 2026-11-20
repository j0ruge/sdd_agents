---
missao: 20261119-l1b-a-rodada-delta
fase: REVIEW
rodada: 3
status: done
sessao: 64fb9147-ffdc-4240-948a-fb4c85e3eaf2
data: 2026-11-20 15:55
gate: "tests/run-all.sh rc=0 (suite green, 2212 linhas ok, 0 FAIL, 923 mutantes aplicam) sobre f6ea5fe; scan de segredos 0 achados (regex + gitleaks, 30 arquivos); sdd review-base → full — merge 59be5eb entered after 40-review-r2.md"
reviewed_head: f6ea5fefbe21081189ed87561f041bc06a8f6460
---

# Review — rodada r3 — L1b: a rodada delta

## TL;DR

Rodada **inteira** (`sdd review-base` → `full — merge 59be5eb entered after 40-review-r2.md`), pelo
`/codereview:codereview` sem `base=`, sobre `87ca025..f6ea5fe`: 30 arquivos, 2086 linhas; o merge
`59be5eb` só trouxe da `main` o que os PRs #450 e #451 já revisaram e fica fora. Feita como subagente
da sessão orquestradora (o `sessao:`). Os sete comentários do CodeRabbit sobre `ad32508` estão
fechados pelos sete commits, cada um com um mundo vermelho antes do conserto e um mutante. Quatro LOW,
dois deles reproduzidos: o `git status` que o `b7f9856` pôs no `review_base_line` reescreve o índice sob
o `index.lock` numa consulta que roda sem a trava (o conserto criou um efeito colateral; vira
`RECURRED` de um item aberto do `TODO.md` no chore pós-merge), e o intervalo do `review_head_ok` sai sem
`core.quotePath=false`. Nenhum `R<n>`. Nota: A em todos os critérios.

## Nota da rodada

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | A | Cada conserto mora na definição única que corrige (`review_base_line`, `review_head_ok`, `fm_scalar`), com o porquê no comentário; a única deriva de gramática (o intervalo sem `core.quotePath=false`, LOW #2) falha fechado. |
| Type Safety | A | O valor do frontmatter passa pela regex hex de 7–64 e pelo `rev-parse --verify ^{commit}` antes de chegar a qualquer comando, nos dois programas, e o `fm_scalar` lê as aspas e os brancos como o `frontmatter` do runner (seis grafias comparadas, todas iguais). |
| Error Handling | A | O diff do intervalo que falha recusa a rodada em vez de passá-la vazia, a consulta do commit desliga o `log.showSignature`, e a rodada que o git não carrega vira `full`; só o ramo do `git status` que falha ficou sem mundo (LOW #4). |
| Security | A | Scan de segredos limpo (regex + gitleaks, 30 arquivos, 2086 linhas adicionadas, `errors: []`); nenhum valor do frontmatter chega a um comando sem passar pela regex. |
| Performance | A | Os testes de git do gate rodam antes do `TEST_CMD`, e o `git status` novo é de um caminho só; o custo real que ele traz é a escrita do índice, que é LOW #1 e não é de tempo. |
| Test Coverage | A | Cada um dos cinco consertos de código tem um mundo com testemunha do estado (o git status do arquivo, a assinatura impressa, o stub que falha só aquele diff, o repositório SHA-256 de verdade) e um mutante; na suíte em curso o `check-gates.sh` já respondeu 5, 6 e as sete asserções novas verdes. |
| Documentation | A | A anatomia ganhou o § 3 e o § 4, o ADR, o `pipeline.md` e o verbete dizem o mesmo contrato, e os dois consertos de handoff batem com o comando; só a quarta recusa do `review_head_ok` não chegou ao texto que conta três (LOW #3). |
| **Overall** | **A** | Os sete comentários do CodeRabbit estão fechados com sensor, nenhum conserto regrediu o que outro fechou, e os quatro achados são LOW sem mudança de nota. |

## Achados da rodada

| # | Severidade | Achado | Onde |
|---|---|---|---|
| 1 | LOW | O `git status --porcelain --untracked-files=all --ignored -- "$last"` que o `b7f9856` pôs no `review_base_line` roda com os optional locks do git: toma o `index.lock` e reescreve o índice. O `sdd review-base` é admitido **sem** a trava do checkout (o `check-coordination.sh` asserta `query stays available: review-base` com outro dono), e o cabeçalho da função diz "Pure: it only prints". Reproduzido (git 2.43): depois de um `touch`, o `sdd review-base` muda o mtime do `.git/index`; com `GIT_OPTIONAL_LOCKS=0`, não. Um `git add`/`git commit` de uma sessão em voo no mesmo checkout pode bater no `index.lock` durante essa janela de milissegundos. É a classe do item aberto "O `sdd status --no-gates` roda o `git status` sem `GIT_OPTIONAL_LOCKS=0`", e o `kit_guard_tree` já usa a variável. Direção: `GIT_OPTIONAL_LOCKS=0` nessa leitura. | `bin/sdd` (`review_base_line`, a linha do `st=`) |
| 2 | LOW | O intervalo do `review_head_ok` sai de `git diff --name-only` sem `-c core.quotePath=false`, enquanto a guarda do chapéu lê os mesmos caminhos pela definição única `hat_diff_names`, que liga a opção. Um caminho não ASCII dentro do próprio `writes:` do revisor volta entre aspas e com escapes octais, não casa o glob, e o gate recusa uma rodada que a guarda aceitou. Reproduzido num repo descartável: `docs/handoffs/<missão>/reprodução.md` no commit da rodada dá `"docs/handoffs/…/reprodu\303\247\303\243o.md" changed between reviewed_head`; um nome ASCII no mesmo lugar passa. Falha fechada, custa uma rodada, e não foi observada: 0 caminhos não ASCII em `docs/handoffs` no kit, no `sales_quote`, no `lighthouse_project` e no `warehouse_explorer_web`. | `bin/sdd` (`review_head_ok`, a captura do `changed=`) |
| 3 | LOW | A quarta recusa do `review_head_ok` (o diff do intervalo falhou, `626526d`) não chegou ao texto que enumera as recusas: a ADR 0023 diz "It refuses three cases", e o § 4 da anatomia e o `docs/pipeline.md` listam três. É a classe que o CodeRabbit apontou e que o `feb1078` fechou: mudança do runner sem a seção da anatomia no mesmo commit. O texto não erra o que lista, só não o completa. Só prosa. | `docs/adr/0023-the-next-round-reviews-the-delta.md` (Decision, item 4) |
| 4 | LOW | O ramo `full — git status cannot say whether … is committed` do `review_base_line` não tem mundo nem mutante, e o comentário não o declara sem probe. Trocar o `if ! st="$(…)"` por uma captura guardada com `or true` deixaria um `git status` que falha ler como rodada commitada e dar `base=`, e nenhuma asserção ficaria vermelha. O stub de git do `626526d` constrói esse mundo. | `bin/sdd` (`review_base_line`, regra 2) |

## Incrementos de conserto (R<n>)

Nenhum. Os quatro achados são LOW e não movem a nota (régua da rodada: só um HIGH, ou um MEDIUM de
confiança, abre `R<n>`). O #1 tem rota pelo `TODO.md`, como reincidência de um item aberto, no chore pós-merge; os
outros três ficam registrados aqui.

## O que virou incremento

Nenhum `R<n>` nesta rodada. O que a rodada conferiu, um por um, sobre os sete comentários do
CodeRabbit no head `ad32508` (consertados pela sessão orquestradora, sob a delegação `full`):

- **Anatomia no mesmo diff do runner** (bin/sdd:3190) — fechado em `feb1078`: o § 3 ganhou a rodada
  delta e o § 4 o `reviewed_head:` do gate; o `b7f9856` acrescentou ao § 3 a rodada que o git não
  carrega. O `626526d` repetiu a classe para a quarta recusa (LOW #3).
- **Rodada não commitada não é base** (bin/sdd:13005, Major) — fechado em `b7f9856`: a regra 2 do
  `review_base_line` responde `full — … is not committed` para modificada, não rastreada e ignorada,
  com o commitado como controle; a asserção `delta base: a round git does not carry …` está verde na
  suíte em curso, com os mutantes `RUN_review_base_uncommitted_round` e
  `RUN_review_base_ignored_round_unseen`. O efeito colateral do conserto é o LOW #1.
- **SHA-256 de 64 hex** (bin/sdd:13075) — fechado em `7cfc841`: os dois leitores, o `pr-ready`, o
  template e o chapéu (espelho idêntico) aceitam 7–64; um repositório `--object-format=sha256` de
  verdade prova `base=<64 hex>` e a chegada à regra do intervalo, sem `is no commit`.
- **Assinatura fora do `rc_commit`, diff que falha recusa** (bin/sdd:13087) — fechado em `626526d`: a
  consulta roda com `-c log.showSignature=false`; o mundo assina o commit da rodada com chave ssh
  descartável e prova que o `git log` imprime mais que o hash; o diff que falha (stub que falha só
  aquele diff, com testemunha) recusa nomeando a rodada. Os dois mutantes morrem pela mensagem.
- **Exemplo da r2 espera `base=`** (20-handoff-exec.md:93) — fechado em `d795ed0`: o comentário diz
  `base=a6f1817… — 40-review-r1.md reviewed this head`, a resposta no estado do boot da r2.
- **Check do I3 espera `6 1`** (checkpoint.md:53) — fechado em `5da6183`: na suíte em curso,
  `^  ok    gate_REVIEW: reviewed_head` conta 6 e `^  ok    review-base: ` conta 5; as asserções
  novas dos consertos levam prefixo próprio, então o I1 e o R1 seguem certos. Era o LOW #1 da r2.
- **`pr-ready` lê o `reviewed_head:` como o runner** (bin/sdd-worker:1258, fora do diff) — fechado em
  `f6ea5fe`: o `fm_scalar` apara e tira uma aspa de cada ponta, na ordem do `frontmatter`; seis
  grafias (aspas duplas, simples com brancos, tab, nua, aspa só de um lado, aspa sozinha) dão o mesmo
  valor nos dois leitores; o `gate:` passou pelo mesmo leitor, mais estrito do que antes.
- Achado #1 da r1 (MEDIUM, `review_head_ok` lia o último commit que tocou a rodada) — segue fechado em
  `c6c381f`: a asserção do R1 está verde na suíte em curso.

## O que foi refutado

- **"O `b7f9856` faz a rodada seguinte a uma rodada morta revisar menos"** — refutado: a rodada não
  commitada responde `full`, que revisa tudo; a base mais exata (o `reviewed_head:` da rodada
  commitada anterior) seria uma otimização, nunca uma lacuna.
- **"Com a rodada commitada e o código depois dela, o `gate_REVIEW` passa sem que ninguém tenha lido
  esse código"** — não é defeito desta missão: o intervalo que o gate confere vai do `reviewed_head:`
  ao commit que **adicionou** a rodada (R1), por desenho, e o código depois dela é o que a rodada
  seguinte revisa; a r2 já registrou isso. O `pr-ready` é quem exige que depois dele só a pasta da
  missão tenha mudado.
- **"Um rename de código para dentro da pasta da missão esconde a remoção no `--name-only`"** — não
  vira achado: exige que a própria sessão de REVIEW mova código, o que a guarda do chapéu já para, e
  o `hat_diff_names` tem a mesma gramática de rename.
- **"O `fm_scalar` e o `frontmatter` divergem em CRLF"** — divergem (o `fm_value` tira o `\r` do fim,
  o runner não), mas aí o gate recusa a rodada como `is no commit` e o runner não avança: nenhum
  caminho chega ao `pr-ready` com a rodada que o gate recusou.

## Achados fora de escopo

- LOW #1 vai ao `TODO.md` pelo chore pós-merge (fora da pasta da missão depois do `reviewed_head:`, o
  `pr-ready` o leria como código mudado) como `RECURRED 1: sdd_agents/20261119-l1b-a-rodada-delta`
  do item aberto **O `sdd status --no-gates` roda o `git status` sem `GIT_OPTIONAL_LOCKS=0` sobre a
  run em voo**: é a mesma classe, numa segunda leitura sem trava (`sdd review-base`, pelo
  `review_base_line`). A contagem de itens não muda, e a catraca fica em 98.

## Pendências / Decisions for a Human

Nenhuma.
