---
missao: 20261117-o-worker-orquestrador
fase: REVIEW
rodada: 11
status: done
sessao: rodada do worker (o ato review do commands/sdd-worker.md), feita por um subagente sdd-reviewer da sessão orquestradora, fora do runner, com escopo delta 2a46d61..0057e43 (a skill invocada com base=2a46d61bcd52ce79ea74fc8d27365360f61e1e4b, rodada de verificação)
data: 2026-11-19 13:00
gate: tests/run-all.sh no 0057e43 verde, rodado pela sessão orquestradora (rc 0, suite green, 2166 linhas ok e nenhuma linha FAIL, worker verbs 68 probe(s), anchors 904 de 904, 888 s, 12:38:51 a 12:53:39, head_after igual ao head) e run-checks.py sobre as 35 linhas done do checkpoint (35 de 35 no esperado, rc 0, 1846 s, R21 0 1 1, R22 1 1 0); nesta rodada o tests/check-worker.sh no head rc 0 com 68 probes e nenhuma linha FAIL (46 s), uma cópia mktemp com o bin/sdd-worker do ac1e2bd rc 1 só na spelling (mundo root, o P2 do Codex de volta), outra com uma passada no lugar de cada laço do dir_normalise rc 1 só na spelling (mundo worktree), check-mutation.sh --only WORKER_handoff_dir_unnormalized com controle verde e mutante pego (rc 1), --anchors 904 de 904, check-todo.sh rc 0 (93 achados) e --anchors TODO.md rc 0 (93 medidas, 0 fora do alvo), check-checkpoint.sh rc 0 e --check rc 0 (35 linhas, nenhuma pending), check-lang.sh rc 0, shellcheck -S warning e bash -n limpos nos três arquivos de código, segredos (regex e gitleaks, 11 arquivos, 303 linhas acrescentadas) sem achado, e o trecho do pager extraído do commands/sdd-worker.md entregando os cinco campos a um hook com SDD_PROJECT e SDD_PHASE obrigatórios, sob bash e sob zsh (o do 2a46d61 aborta, rc 127); cópias apagadas no fim; árvore limpa no 0057e43; nota A em todo critério, as mesmas letras da r10, nenhum achado de severidade e nenhum R novo
reviewed_head: 0057e43e67e6b6e2fa1deb57900f38f794c8e3ae
---

# Review — rodada r11 — O worker orquestrador

## TL;DR

Rodada delta do worker sobre `2a46d61..0057e43`: os consertos dos dois P2 do Codex (R21 em `b671a31`, R22 em `7ddc976`), a r10 (`491a976`), os dois LOW de forma do handoff de EXEC (`f8e3e02`) e os commits de checkpoint.
Os dois P2 fecharam, reproduzidos aqui nos dois sentidos: o código de antes reprova a família `spelling: ` no mundo do achado, o head passa, e o trecho do pager entrega os cinco campos.
Nenhum CRITICAL, HIGH nem MEDIUM de confiança: nota A em todo critério, como na r10. Nenhum `R<n>` novo.
Quatro LOW ficam citados abaixo, sem lote, como a régua manda; o dono decide depois do merge se algum vai ao `TODO.md`.

## Nota da rodada

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | A | A normalização do `HANDOFF_DIR` virou uma definição só (`dir_normalise`, chamada e nunca substituída), usada pelo `base_copies` e pelos dois lados do `campaign_set`, e `shellcheck -S warning` e `bash -n` passam limpos nos três arquivos de código. |
| Type Safety | A | O `dir_normalise` escreve pela variável nomeada (`printf -v`) os mesmos laços do `load_config` (`bin/sdd:303-304`), e nenhum leitor do worker usa o valor cru: os dois `config_key … HANDOFF_DIR` passam pela função antes de comparar ou virar caminho. |
| Error Handling | A | Duas pastas que diferem de verdade continuam recusadas pelo mesmo `SET_WHY`, rc 1, agora com as grafias que o runner lê (`docs/missions` contra `docs/handoffs`), e o pager não aborta mais num hook que exige `SDD_PROJECT` ou `SDD_PHASE`. |
| Security | A | Nenhum verbo que concede ficou mais frouxo: o `level` só deixa de rebaixar o par de grafias que o runner lê como a mesma pasta, e a varredura de segredos (regex e gitleaks, 11 arquivos, 303 linhas) não achou nada. |
| Performance | A | Dois laços de expansão de parâmetro por leitura de config, sem processo novo; o `check-worker.sh` rodou em 46 s no head. |
| Test Coverage | A | A família `spelling: ` reprova o código de antes no mundo do P2 e reprova a sabotagem refeita aqui, o mutante `mut_WORKER_handoff_dir_unnormalized` é pego com controle verde, e a `stops:` cobra os dois nomes dentro da chamada com três controles negativos. |
| Documentation | A | O `docs/pipeline.md`, o `config/schema.md` e o `commands/sdd-worker.md` dizem o que o código faz; sobram quatro LOW de forma, citados, que pela régua não seguram a nota. |
| **Overall** | **A** | Nenhum CRITICAL, HIGH nem MEDIUM de confiança: os dois P2 do Codex fecharam por `b671a31` e `7ddc976`, reproduzidos nos dois sentidos, e nenhum lote novo foi aberto. |

## Movimento contra a r10

As mesmas letras: A em todo critério na r10 e aqui. Atrás desta rodada há dois commits de
conserto, `b671a31` (R21) e `7ddc976` (R22), e o que cada um prometia está refeito abaixo, nos dois
sentidos (o código de antes reprova, o head passa).

## Relatório da skill

- **Round:** verificação sobre `2a46d61...0057e43` (`base=` colado do `reviewed_head:` da
  `40-review-r10.md`, `git merge-base --is-ancestor 2a46d61 HEAD` rc 0, os achados abertos da r10
  lidos da tabela dela, codereview 2.30.1, `prose_units.py` rc 0 com 8 arquivos de prosa, 3 de
  código, 73 unidades). Não rodou inteira.
- **Secrets Detection:** PASS, 0 linhas (`scan_secrets.sh`, regex e gitleaks, 11 arquivos, 303
  linhas acrescentadas, nenhum erro).
- **Fase B, inline:** três arquivos `CODE` (`bin/sdd-worker`, `tests/check-worker.sh`,
  `tests/check-mutation.sh`), nenhum escrito por esta sessão, lidos pelo diff no modelo principal.
  A varredura de código morto também inline: o diff não deixa símbolo órfão (os dois laços que o
  `base_copies` tinha à mão saíram para o `dir_normalise`, e o `grep` acha a função chamada em três
  sítios).
- **Verificador:** um agente sonnet sobre 15 unidades de sete arquivos (`TODO.md`, o
  `commands/sdd-worker.md`, o `config/schema.md`, o `20-handoff-exec.md`, as quatro notas novas, as
  linhas R21 e R22 do `checkpoint.md` e o `docs/pipeline.md:1822-1834`), com `Units read: 15` e
  `END_OF_VERIFICATION`. Deu um `behavior` (MEDIUM), recalibrado aqui a LOW (achado #1), e dois LOW
  de forma.
- **Fora do verificador**, por escolha da rodada, como a r10 fez com a r9: o `40-review-r10.md`, o
  relatório da rodada anterior, cujas afirmações datam do `2a46d61`.
- **Cost footprint:** um verificador sonnet (cerca de 131 mil tokens), Fases A, B e C no modelo
  principal; o `check-worker.sh` no head, duas cópias dele e o `--only` em paralelo (46 s).

## Os dois P2 do Codex, reproduzidos

- **#1, o `HANDOFF_DIR` cru (R21).** A família `spelling: ` mede o mundo que o brief pede: o
  checkout da campanha com `./docs/handoffs/` e o worktree da missão com `docs/handoffs` é o mundo
  `root` dela, e cada mundo tem as duas respostas (`budget` e `level`) comparadas inteiras com as do
  mundo de grafias iguais, fixado em `0.00 … 1 40` e `level pr — signed until …`; o `1` do `budget`
  é a missão achada. Numa cópia `mktemp` do head com o `bin/sdd-worker` do `ac1e2bd` (o código de
  antes), a família reprova no mundo `root` com exatamente o P2:
  `rc 1: no spend — HANDOFF_DIR 'docs/handoffs' in …/spell-w/.sdd/config.sh is not the campaign
  checkout's './docs/handoffs/'` e `rc 1: level assisted — unread: …`. No head, verde. A pasta
  diferente (`./docs/handoffs/` contra `docs/missions/`) segue recusada nos dois verbos, rc 1, com o
  `SET_WHY` nomeando `docs/missions` e `docs/handoffs`, já normalizados.
- **#2, o pager sem `SDD_PROJECT` e `SDD_PHASE` (R22).** O trecho extraído do
  `commands/sdd-worker.md` (da linha `why=` até a cerca), com os placeholders trocados, um `sdd-worker`
  de mentira no `PATH` e um `ON_ESCALATION_CMD` que exige os cinco campos por `${…:?}`: sob bash e
  sob zsh o hook recebe `next-stop|review|20990101-m|proj-x|campaign US$ 12.00 of 100.00`, rc 0. O
  mesmo trecho no `2a46d61` aborta, rc 127, `SDD_PHASE: parâmetro nulo ou não inicializado`.
- **A definição única.** `grep -n 'HANDOFF_DIR' bin/sdd-worker`: as duas leituras (`:711` e `:721`)
  passam pelo `dir_normalise` antes da comparação e do glob, e o `base_copies` recebe o valor já
  normalizado e o normaliza de novo (idempotente). Nenhum outro laço `#./`/`%/` no arquivo.
- **O mutante e uma sabotagem.** `check-mutation.sh --only WORKER_handoff_dir_unnormalized
  check-worker.sh`: controle verde e mutante pego (rc 1); `--anchors` 904 de 904. Refeita a
  sabotagem "uma passada no lugar de cada laço" da nota do R21: a família reprova no mundo `worktree`
  (`././docs/handoffs//` lido como `./docs/handoffs/`), e só ela, como a nota diz.

## Achados da rodada

| # | Severidade | Achado | Onde |
|---|---|---|---|
| 1 | LOW | O "Boot da próxima fase" do handoff de EXEC diz que depois da r10 a próxima é o `merge`, e desde o `ac1e2bd` vieram o R21, o R22 e esta r11 (verificador, `behavior`, recalibrado) | `docs/handoffs/20261117-o-worker-orquestrador/20-handoff-exec.md:136` |
| 2 | LOW | A cláusula nova "with the same five fields" aponta para `docs/pipeline.md#the-worker`, que não diz que as paradas do worker chamam o pager (a nota do R22 admite) (verificador, form) | `config/schema.md:292` |
| 3 | LOW | "…in `SDD_GATE_WHY`; and five seconds for the pager:" deixa os cinco segundos lerem como um sexto campo da lista (verificador, form) | `commands/sdd-worker.md:233-236` |
| 4 | LOW | Carregado da r10 (#1), linhas que o delta não tocou: as aspas em "ao ato que conserta o item" leem como citação literal de uma frase que é inglesa | `TODO.md:174-175` |

### Reprodução e recalibragem

- **#1:** `sed -n 136,137p` dá "Depois da r10 (`491a976`, A em todo critério, nenhum R): a próxima é o
  `merge`", e a nota das 11:41 (`checkpoint-notas.md:133`) registra os dois P2 e a decisão da r11.
  Recalibrado de MEDIUM a LOW porque nenhum verbo nem gate lê essa seção: o boot do runner inlina a
  do handoff mais recente (`mission_latest_handoff`, `[1-9][0-9]-*.md` por versão, hoje o
  `50-pr.md`), e o `pr-ready` recusa todo commit fora da pasta da missão depois do `reviewed_head:`,
  então uma sessão que lesse a frase e fosse ao `merge` sobre o `2a46d61` seria parada pelo verbo. É
  o registro do momento do `f8e3e02`, a mesma leitura que a r10 deu à frase que esta substituiu.
- **#2:** `grep -n 'ON_ESCALATION_CMD' docs/pipeline.md` não acha frase sobre as paradas do worker
  chamarem o pager; o link é anterior ao R22, que só acrescentou "with the same five fields".
- **#3:** a frase é verdadeira (o trecho leva `timeout -k 1 5`); é só a pontuação.
- **#4:** o delta tocou `TODO.md:165` e `:183`, nunca `:174-175`; segue aberto como LOW, decisão do
  dono depois do merge, como a r10 deixou.

## Incrementos de conserto (R<n>)

Nenhum. Os quatro achados são LOW de prosa, e a régua do dono (item 2) diz que LOW não segura a nota
e que esta rodada não abre lote de LOW. Nenhuma linha nova vai para o `checkpoint.md`.

## O que virou incremento

Nada desta rodada virou incremento. **Fechados e conferidos aqui:**

- **P2 #1 do Codex → R21, `b671a31`.** Ver "Os dois P2 do Codex, reproduzidos": o código de antes
  reprova a `spelling: ` no mundo do achado, o head passa, o mutante é pego e a sabotagem refeita
  reprova. As âncoras que o diff deslocou (`campaign_set` 690 → 703, `cmd_pr_ready` 1214 → 1229)
  seguram: `check-todo.sh --anchors TODO.md` rc 0, 93 medidas e 0 fora do alvo.
- **P2 #2 do Codex → R22, `7ddc976`.** O trecho entrega os cinco campos sob bash e zsh; a família
  `stops:` lê os dois nomes só dentro da chamada (o `awk` da linha `why=` até a cerca) e tem os três
  controles negativos que a nota do R22 descreve.
- **r10 #2 (a linha de 157 colunas) → `f8e3e02`.** O trecho foi reescrito e nenhuma linha de
  `20-handoff-exec.md:134-150` passa de 105 colunas.
- **A nota fora de escopo da r10 (o boot que dizia "a próxima é a r9") → `f8e3e02`.** Reescrita; a
  frase nova é o achado #1 desta rodada, pelo mesmo motivo (o laço andou depois dela).
- **O checkpoint.** `check-checkpoint.sh` rc 0 e `--check` rc 0 (35 linhas, 30 sob a regra da
  âncora, nenhuma cega), nenhuma linha `pending`; os Checks do R21 e do R22 dão `0 1 1` e `1 1 0`
  pelo `run-checks.py` da sessão orquestradora.

## O que foi refutado

- **O `behavior` do verificador como MEDIUM** — refutado na severidade, não no fato: a frase está
  velha, mas nenhum verbo nem gate a lê, e o verbo que decide o merge a recusaria (Reprodução do #1).
- **Examinado e descartado:** `HANDOFF_DIR="./"` normaliza a vazio no worker, mas o runner morre
  nesse mesmo valor (`adr_dir_ok` recusa o vazio, `bin/sdd:9046`), então nenhuma missão roda ali; a
  ordem default-antes-de-normalizar é a mesma nos dois (`bin/sdd:151` e `bin/sdd-worker:712`).

## Achados fora de escopo

Nenhum registrado no `TODO.md` nesta rodada; o verificador não deu nada fora das unidades (`Cut: 0`).

## Pendências / Decisions for a Human

1. **Os quatro LOW** (#1 a #4): pela régua, decisão sua depois do merge, ir ao `TODO.md` ou ficar
   como estão. Nenhum muda verbo, sensor ou gate.
2. **O push e o `@codex review`.** Esta rodada leu o `0057e43`; o ato `review` pede de novo o
   `@codex review` sobre o head empurrado, como a nota das 11:41 registra.
3. **Seguem as da r10 e da missão:** a fonte da missão largada (`campaign:` na linha `session` do
   ledger), o `pr-ready` que não lê o corpo de uma revisão nem o `local/ci`, os threads do #414 que
   nenhum ato resolve, e as do `00-missao.md`. O merge do PR #414 continua com você.

## Boot da próxima fase

Nenhum `R<n>` pendente: a próxima volta é o push, o `@codex review` e o `pr-ready` do worker sobre o
head que contém esta rodada. Depois do `reviewed_head:` só pode entrar commit na pasta da missão.
