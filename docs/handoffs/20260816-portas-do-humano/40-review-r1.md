---
missao: 20260816-portas-do-humano
fase: REVIEW
rodada: r1
status: done
sessao: 69d7f415-45d5-4dae-9d0e-da889af3b625
data: 2026-08-17 01:45
gate: "`bash tests/run-all.sh` → rc 0, saída final `suite green`, `score: 55 caught, 0 known gap(s), of 55`, **490** asserções `ok`. `shellcheck -S warning bin/sdd tests/*.sh` limpo (roda dentro do `run-all.sh`). Working tree limpo; os 4 commits desta rodada (`ad0c89d`, `ece1b33`, `b33aa6a`, `e5e8902`) e os 5 da rodada em voo que a sessão anterior deixou commitada (`1cc6c34`, `1280bf7`, `274ee45`, `7f9e660`, `d601c2d`) verificados ancestrais de HEAD. Os seis Checks do `checkpoint.md` remedidos DEPOIS dos commits: `sdd approve `→3, `branch `→3, `retry `→2, `kaizen-born`→3, `approve resolves`→1, `approve warns`→1. `bash tests/check-todo.sh` → 71 achados, todos dentro de 8 linhas com âncora. `agents/sdd-planner.md` e `.claude/agents/sdd-planner.md` byte-idênticos (`cmp -s`). Varredura determinística de segredos sobre o diff completo (`scan_secrets.sh`, catálogo de regex do `codereview` v1.17.1) → `{\"findings\": [], \"errors\": []}`."
---

# Review — rodada r1 — as quatro portas entre humano e runner ganham dono

> Rodada única desta missão, e ela tem duas metades. A primeira foi escrita por uma sessão de
> REVIEW que **morreu antes de commitar**; o que ela achou foi resgatado da árvore suja pela
> sessão de EXEC seguinte (`7f9e660`) e o artefato ficou devendo. Esta sessão fecha o artefato
> **e** roda a rodada de novo sobre o diff inteiro, que é o que impede o resgate de virar um
> carimbo. Achou dois fail-open que a primeira metade não tinha visto.

## TL;DR

Revisão sobre o diff `main...HEAD` (14 arquivos, +2454/-15): runner bash, dois sensores, quatro
markdowns de contrato e os artefatos da missão. **7 achados**, 4 consertados nesta sessão com
teste, 3 no `TODO.md`; **12 hipóteses refutadas com evidência** — várias delas caras, e refutar
sem mexer no código é metade do trabalho de uma rodada honesta.

Os dois achados que importam são **fail-open**: sensores verdes sobre propriedades que ninguém
media. Os dois foram encontrados degradando o `bin/sdd` e rodando a suíte — nunca por leitura — e
os dois estavam no `TODO.md` como "regra sem probe", registrados e adiados. Uma rodada de REVIEW
que os deixasse adiados de novo estaria confirmando a suposição em vez de medi-la, que é
exatamente o modo de falha que este repo escreve no próprio `CLAUDE.md`.

## Estado do repo

- **Branch:** `missao/20260816-portas-do-humano` — nunca empurrada (`git push` é da fase PR)
- **Último commit:** `e5e8902` `chore(todo): três regras sem probe carimbadas, três achados novos`
- **Working tree:** limpo
- **Suíte:** `tests/run-all.sh` → **verde**, 490 asserções, mutação **55/55**, `0 known gaps`
- **E2E:** `E2E_CMD=""` — o kit não tem interface; não rodou por não existir

## Os achados da rodada

| # | Sev | Onde | O quê | Destino |
|---|---|---|---|---|
| 1 | CRITICAL | `bin/sdd:1986` / `tests/check-gates.sh` | **fail-open:** trocar a ordem de `ensure_mission_branch` e `warn_if_on_base_branch` no `cmd_run` deixa a suíte inteira verde | consertado · `ad0c89d` |
| 2 | HIGH | `bin/sdd:198` / `tests/check-gates.sh` | **fail-open:** apagar a guarda `inside &&` do `frontmatter_write` deixa a suíte verde e o comando reescreve prosa de missão | consertado · `ad0c89d` |
| 3 | HIGH | `agents/sdd-planner.md` | o campo `branch:` virou carga executável e o agente que o escreve nunca soube — contrato aberto no lugar mais caro dos três | consertado · `ece1b33` |
| 4 | HIGH | `agents/sdd-publisher.md:98` vs `bin/sdd:1363` | a branch criada pela fase TICKET vive no `10-ticket.md`; `ensure_mission_branch` só lê o `00-missao.md` — com `JIRA_ENABLED=true` a guarda não existe | `TODO.md` (decisão 6 do `00-missao.md`) |
| 5 | MEDIUM | `20-handoff-exec.md:90` | contagem do `TODO.md` errada em dois eixos, e o próprio arquivo se contradiz | consertado · `b33aa6a` |
| 6 | LOW | `bin/sdd:1405` | a releitura pós-checkout confere o campo `branch:`, não a identidade do plano | `TODO.md` |
| 7 | LOW | `tests/check-mutation.sh:635` | o call site do `ensure_mission_branch` no `cmd_retry` não tem entrada no catálogo | `TODO.md` |

### 1 · A ordem das duas guardas no `cmd_run` não era medida por nada

`cmd_retry` ganhou a asserção de ordem no I3 (`3ffa586`), com o comentário dizendo por quê. O
`cmd_run` — a porta por onde quase toda invocação passa — tem a mesma ordem pelo mesmo motivo e
**nenhuma asserção**. Medido, não deduzido: trocando as duas linhas dentro do `cmd_run`,
`check-gates.sh` devolve **82 `ok`, 0 `FAIL`, rc 0** e `run-all.sh` fecha em `suite green`.

O que a ordem errada produz não é um crash, é um **aviso falso**: o humano é informado de que o
pipeline vai commitar na branch base por um runner que o tira da base na linha seguinte. Aviso que
grita lobo é como se aprende a não ler aviso — e este repo tem três outros comentários dizendo
isso, o que faz da inversão um refactor que alguém chega a fazer de boa-fé.

A asserção nova é **diferencial e autocontida**, as duas metades no mesmo comando, mesmo fixture e
mesmo texto: `branch:` vazia ⇒ o run fica na base e avisa **exatamente 1×**; branch declarada ⇒
sai da base e avisa **0×**. Só a ausência seria satisfeita por um runner que nunca avisa; só a
presença, por um que sempre avisa. Nenhum regime de fixture a satisfaz por acidente.

### 2 · A guarda de escopo do `frontmatter_write` também estava sem probe

O `frontmatter_write` promete, no próprio comentário, escrever **só** dentro do bloco entre os dois
primeiros `---`, "porque o corpo de uma missão é prosa que legitimamente cita o próprio
frontmatter". Apagar `inside && ` da condição de escrita — passando a reescrever a primeira linha
com a forma da chave em qualquer lugar do arquivo — deixa **82 `ok`, rc 0** e a suíte verde.

Sobrevivia por um motivo que o `TODO.md` já tinha diagnosticado: os cinco fixtures de approve
trazem a chave **dentro** do frontmatter, e como essa cópia vem primeiro o `!written` para nela.
A guarda de escopo nunca era quem decidia. O fixture novo (`20260102-nokey`) é a missão **sem** a
chave no frontmatter e **com** ela no corpo — o estado exato para o qual as duas guardas foram
escritas.

O probe são os **bytes do arquivo**, nunca o rc: com a chave ausente, a versão correta e a
sabotada morrem no **mesmo** `die` (o `frontmatter()` não enxerga linha de corpo em nenhum dos
dois casos), então rc 1 e "nenhum commit" são compartilhados pelo defeito e pelo conserto. O que
os separa é o corpo ter sobrevivido. Como brinde o mesmo fixture fecha a segunda regra sem probe
do arquivo — a guarda de read-back —, que era o que o item do `TODO.md` previa por escrito.

**Medido nos dois sentidos**, e cada degradação mata **só** a asserção nova (rc 1, 83 `ok`, 1
`FAIL`), nunca uma vizinha. Os seis Checks do `checkpoint.md` seguem 3/3/2/3/1/1: os dois nomes
novos ficam fora dos prefixos contados de propósito.

### 3 · O contrato do `branch:` estava aberto no lugar que mais custa

`ensure_mission_branch` (I2) tirou o campo de decorativo: antes do primeiro gate de todo `sdd run`
e todo `sdd retry` o runner faz checkout dele e, se não existir, **cria a branch a partir de onde o
humano estiver de pé**. O I2 sincronizou `templates/missao.md`; o `docs/pipeline.md` ganhou a linha
do dry-run uma rodada depois (`1280bf7`). O `agents/sdd-planner.md` — o agente que **preenche** o
campo — nunca soube: `grep -n branch agents/sdd-planner.md` devolvia nada, enquanto `versao:` e
`aprovacao:` têm seção própria cada um. A §8 nova enuncia os três valores e os três comportamentos,
e a cópia instalada foi sincronizada byte-idêntica no mesmo commit.

### 4 · A métrica "a classe SQ-97 morre" precisa de uma qualificação

`agents/sdd-publisher.md:98` manda a fase TICKET registrar `branch:` no `10-ticket.md`;
`ensure_mission_branch` lê **só** o `00-missao.md`, e nada copia um para o outro. Em repo com
`JIRA_ENABLED=true` o campo fica no placeholder para sempre e a guarda que esta missão construiu
**não roda**. Não é regressão e não é escopo: a decisão 6 do `00-missao.md` manteve o TICKET fora
de propósito. Mas a métrica diz "a classe SQ-97 morre" sem ressalva, e a ressalva é real — morre
no caminho sem JIRA, que é o único que esta missão andou. Está no `TODO.md` com direção, e o corpo
do PR deve carregar a qualificação em vez do absoluto.

## O que foi refutado, e com que evidência

Uma crítica que se acredita errada não se resolve mudando o código para agradá-la. Doze
hipóteses foram levantadas e derrubadas; as que custaram medição de verdade:

- **Injeção de argumento no `git checkout`.** A hipótese era que o guarda `case "$want" in -*)`
  deixasse passar outras formas hostis. Testados contra o git real (2.43.0), num repo de
  brinquedo: `HEAD`, `--`, valores com espaço, `master@{1}`, `foo..bar`, `.foo`, `foo.lock`,
  `foo/`, `foo*bar`, conflito D/F (`release` × `release/1.0` nos dois sentidos), e o nome que é
  **também** um caminho existente. Todos morrem em `check-ref-format` com rc 128 **antes** de
  qualquer checkout, e o `ensure_mission_branch` os transforma no `die` com a mensagem do git.
  O caso ambíguo branch-versus-tag resolve para a **branch**, coerente com o `show-ref --verify`
  que já rodou. **Refutado.**
- **Perda de trabalho não commitado no checkout.** Montado o cenário pior — arquivo rastreado
  sujo na árvore e conflitante na branch alvo: o git **recusa** (`would be overwritten`), a branch
  e o arquivo ficam intactos, e a recusa vira `die`. **Refutado** — e é o mesmo caminho que a
  asserção 4 do `check-gates.sh` já cobra.
- **`printf "%s: %s\n", k, v` corromper um valor com `%`.** `v` é **argumento** do `printf` do
  awk, não formato. Medido com `v="100% done"`: sai `100% done`. **Refutado.**
- **`git commit -- <path>` levar junto o que o humano tinha em stage.** É commit parcial por
  definição do git: leva só o caminho e deixa o resto em stage. A asserção 3 do approve já mede a
  metade que importa (o arquivo sujo continua sujo). **Refutado.**
- **A tabela de artefatos do `20-handoff-exec.md` afirmar que I2 e I4 tocaram os mesmos quatro
  arquivos.** A célula é uma lista **distributiva** e cada arquivo está num dos dois commits:
  `templates/missao.md` em `b3b8c2f` (I2); `agents/sdd-planner.md`, a cópia instalada e
  `docs/pipeline.md` em `2510c3c` (I4), conferido por `git show --stat`. **Refutado.**
- **TOCTOU na janela do prompt do `sdd approve`.** O kit é explicitamente monoperador (YAGNI no
  `CLAUDE.md`: sem daemon, sem servidor), o `frontmatter_write` reabre o arquivo na hora de
  escrever, e a guarda de read-back confere o valor pelo parser do gate antes do commit. Sem
  cenário de falha concreto e sem segundo escritor, mudar o código aqui seria complexidade paga
  para agradar a crítica. **Refutado.**
- Também refutados por leitura dirigida do `set -e`: os `&& return 0` de `ensure_mission_branch`
  não vazam status (a lista `A && B` isenta o teste do `errexit`); `out="$( … )" || rc=$?` é a
  forma **certa** e não o defeito conhecido do `cmd_health`; `MISSION_DIR` é sempre absoluto, então
  a releitura pós-checkout é válida; `GATE_WHY` está sempre preenchido quando o `cmd_approve` o lê,
  e o `gate_PLAN` não tem efeito colateral; `checkpoint_rows` sempre emite as 5 colunas, então o
  `read` de 5 campos não tem caso curto.

## O que foi para o `TODO.md`

Três achados novos (#4, #6, #7 da tabela), com âncora, direção e data — nenhum sumiu. E três itens
antigos foram **fechados** com `RESOLVIDO por ad0c89d`: o escopo do `frontmatter_write`, a guarda
de read-back do `sdd approve` e a ordem sem probe do `cmd_run`. Os três eram "regra sem probe" e
os três estavam esperando exatamente o fixture que esta rodada escreveu.

Continua aberto e **deliberadamente não consertado** o item das três suposições do
`frontmatter_write` (`chmod --reference` engolido, `mv` sobre symlink, `awk -v` interpretando
escape de barra invertida). O terceiro foi confirmado por medição — no mawk 1.3.4 desta máquina
um `\n` no valor vira quebra de linha real e permite forjar um `---` de fechamento — mas **nenhum
chamador de hoje o alcança** (o único passa `humano-$(date +%F)`), e o item já traz a direção
certa (`ENVIRON` no awk). Consertar um terço de um item de três partes, sem chamador que o probe
consiga alcançar, seria trocar uma dívida registrada por código sem sensor.

## Riscos e não-feitos

- **`docs/pipeline.md` continua sem seção própria para `sdd approve` e para o campo `branch:`.**
  O comando está no `usage()`, no `README.md` e citado na seção PLAN; o campo ganhou a linha do
  dry-run. Uma casa própria na superfície de comandos é **trabalho da fase DOCS**, anotado três
  vezes nas Notas do `checkpoint.md`.
- **A jornada do `sdd kaizen` de ponta a ponta continua não andada** (nascer o plano, escrever o
  verdict, aprovar, rodar) — herdado do handoff da QA, e esta rodada não a andou também.
- **O marcador kaizen-born segue sendo a presença do arquivo, não seu conteúdo.**
- **Duas colocações alternativas do aviso do F2 sobrevivem à sabotagem de propósito** — são
  controle, não buraco: uma asserção que as matasse estaria medindo estilo.

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | A | Uma definição por regra, sem exceção: `plan_approves_itself`, `ensure_mission_branch` e `warn_if_on_base_branch` têm casa única e call sites que a leem em vez de restatá-la — que é a regra do enum do `CLAUDE.md` aplicada aos três defeitos que ela existe para impedir. Cada desvio do plano está registrado no `checkpoint.md` com o motivo. Varredura de código morto: nenhum símbolo órfão introduzido pelo diff. |
| Type Safety | A | Bash não tem tipos; o análogo é contrato, e os quatro foram fechados nesta rodada. O enum de `aprovacao:` ganhou restrição de origem imposta por gate e não por prosa; o campo `branch:` está agora enunciado nos **quatro** lugares que o tocam (`templates/missao.md`, `bin/sdd`, `docs/pipeline.md`, `agents/sdd-planner.md` §8 + cópia instalada byte-idêntica); os prefixos de asserção seguem contrato com os Checks, remedidos 3/3/2/3/1/1 depois dos commits. |
| Error Handling | A | Cada `die` versus `warn` é decisão declarada e testada: checkout recusado ⇒ `die` com a mensagem do git (asserção com o `BLOCKED in EXEC` ausente como prova de que a linha parou); base branch ⇒ sempre `warn`, porque o plano vive legitimamente na base. `mktemp` que falha ⇒ `die`, `awk` falho ⇒ temporário removido e `die`, `mv -f` sem pergunta, read-back antes do commit — e o read-back **agora tem probe**, que era o buraco desta coluna. |
| Security | A | Varredura determinística de segredos sobre o diff completo → 0 achados. A superfície de injeção real (o campo `branch:`, escrito por uma sessão LLM e entregue ao git) foi atacada com ~15 formas hostis contra o git real: todas recusadas antes do checkout, nenhuma perda de árvore suja, nenhum `eval` ou expansão sem aspas no diff. O único primitivo latente (escape de `awk -v`) não tem chamador que o alcance e está no `TODO.md` com a direção medida — registrado, não resolvido por decreto. |
| Performance | A | O custo acrescentado por invocação é um `git show-ref` e no máximo um `checkout`, ambos antes do primeiro gate e nenhum em `--dry-run`. Na suíte, as duas asserções novas somam ~4s sobre um `check-gates.sh` de ~7s, e as duas mutações levam o catálogo de 53 a 55 rodando no mesmo pool de 8. Nenhum laço, releitura ou `git` por linha introduzido. |
| Test Coverage | A | 490 asserções, mutação **55/55 com `0 known gaps`**. Os dois fail-open que esta rodada achou foram medidos **nos dois sentidos** — verde com o código certo, e cada degradação matando **só** a asserção nova (83 `ok`, 1 `FAIL`) —, que é o que separa asserção viva de decoração. Nenhum Check de incremento foi inflado. |
| Documentation | A | O contrato do `branch:` fechou no agente que o escreve, com a cópia de `.claude/agents/` sincronizada no mesmo commit. As duas contagens erradas do handoff do EXEC foram remedidas e corrigidas com a marca da correção. `tests/check-lang.sh` verde: prosa de kit em inglês, artefato de missão em `pt-BR`. O que falta (casa própria no `pipeline.md`) é escopo declarado da fase DOCS, não dívida silenciosa. |
| **Overall** | **A** | 7 achados, 4 consertados com teste que falha antes e passa depois, 3 no `TODO.md` com âncora e direção; 12 hipóteses refutadas com evidência medida. Suíte verde, mutação 55/55, árvore limpa. |

### Recommended Actions

**Must Fix (CRITICAL/HIGH)** — todos fechados nesta sessão:

- ~~fail-open da ordem das guardas no `cmd_run`~~ → `ad0c89d`
- ~~fail-open do escopo do `frontmatter_write`~~ → `ad0c89d`
- ~~contrato do `branch:` ausente no `sdd-planner`~~ → `ece1b33`
- branch da fase TICKET fora do campo que o runner lê → `TODO.md` (fora de escopo por decisão 6);
  **o corpo do PR deve qualificar a métrica**: a classe SQ-97 morre no caminho sem JIRA.

**Consider Fixing (MEDIUM/LOW)** — registrados, nenhum perdido:

- as três suposições do `frontmatter_write` (`chmod`, symlink no `mv`, `awk -v`) → `TODO.md`
- releitura pós-checkout confere o campo e não a identidade do plano → `TODO.md`
- call site do `ensure_mission_branch` no `cmd_retry` sem entrada no catálogo → `TODO.md`

**Para a fase DOCS:**

- casa própria para `sdd approve` e para o campo `branch:` na superfície de comandos do
  `docs/pipeline.md` — anotado três vezes nas Notas do `checkpoint.md`
- `KAIZEN_LOG.md` com o antes/depois medido: mutação **44 → 55**, `0 known gaps`, e a métrica do
  `00-missao.md` (que diz 44 → 48) reescrita para o número real
