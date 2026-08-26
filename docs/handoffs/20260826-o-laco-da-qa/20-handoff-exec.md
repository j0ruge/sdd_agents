---
missao: 20260826-o-laco-da-qa
fase: EXEC
status: done
sessao: 05f1def1-e838-4308-9d23-56c7894a9f5a
data: 2026-08-26 15:52
gate: "`tests/run-all.sh` → `suite green`, rc 0, 581 asserções `ok`, 0 FAIL. Sensores tocados: `check-gates.sh` rc 0, 129 → **132** `ok` (os 3 regimes de gênero do I2); `check-autonomy.sh` rc 0, 184 → **185** `ok` (o diferencial do I3). `./bin/sdd preflight` → `preflight ok`, `7 kit agent(s) checked`, working tree limpo — é ele que compara `agents/` com o espelho `.claude/agents/`. Catálogo de mutação: ver § Estado do repo."
---

# Handoff — EXEC — a fase QA para de girar em bug que ninguém pode fechar

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

Os 4 incrementos estão `done`, um commit cada, nenhum `blocked`. A Âncora 3 do `gate_QA` passou a
distinguir **gênero** de bug (`Closable by: agent | human`, ausente barra), `status: blocked` no
handoff escala em **uma** sessão em vez de duas, e o `§ 5` do `agents/sdd-qa.md` deixou de prometer
sem mecanismo. Suíte verde em 581 asserções. A QA desta missão anda no ramo **sem interface**: o
kit não tem `E2E_CMD` nem `APP_URL`, então a evidência da jornada é o campo `gate:` do próprio
`30-handoff-qa.md` — e a jornada a andar é a que esta missão mudou, no terminal.

## Estado do repo

- **Branch:** `fix/o-laco-da-qa` — **local só**, nunca empurrada (`git push` não é desta fase);
  base em `ef05eba` (`main`), 7 commits à frente, 0 atrás.
- **Último commit:** `cf43bb3` `docs(qa): o contrato do sdd-qa para de mentir e ganha o dever de marcar o gênero`
- **Working tree:** limpo no momento do commit do código; suja de novo com este handoff + o
  `checkpoint.md`, que vão no commit seguinte.
- **Suíte:** `tests/run-all.sh` → **verde**, rc 0, 581 asserções `ok`, 0 FAIL.
- **E2E:** `E2E_CMD=""` e `APP_URL` não definido — **projeto sem interface**, o ramo já previsto
  no `01-plano.md`. Não rodou porque não existe, não porque foi pulado.
- **Carimbo de mutação:** tirado **depois** do último commit de código (`cf43bb3`).
  `./bin/sdd health --with-mutation` → `kit healthy`, rc 0, com
  `mutation: score: 150 caught, 0 known gap(s), of 150`,
  `all 8 gates have a mutation in the catalogue`,
  `mutation stamp written — gate_PR can see that THIS content ran green`,
  `provenance: all 3 fixtures match the installed skills` e
  `ratchet: 1 known debt(s), none new`. Os dois mutantes desta missão
  (`mut_QA_bug_genre_ignored`, `RUN_blocked_not_escalated`) estão dentro dos 150.

## O que foi feito

- `525b216` — **I1**: `docs/qa/templates/bug.md` ganhou `- **Closable by:** agent <!-- agent |
  human -->`, na mesma forma do `Status:` irmão (valor colado ao campo, enum no comentário).
  Sozinho é formato: quem prova é o leitor do I2.
- `0a0f760` — **I2**: a Âncora 3 (`bin/sdd`, `gate_QA`) conta como bloqueante só o bug `Status:
  open` que **não** é `Closable by: human`. Ausente ⇒ conta, que é o comportamento de hoje e o
  fail-safe do registry legado. 3 regimes novos em `tests/check-gates.sh`, um deles
  **diferencial**, mais o mutante `mut_QA_bug_genre_ignored`.
- `4c9b080` — **I3**: gate reprovado **porque o handoff declara `status: blocked`** sai `3` na
  primeira sessão, sem passar pelo heurístico de `moved2`. O ramo lê o global
  `GATE_HANDOFF_BLOCKED` (forma do `GATE_EXEC_DIRTY`), **nunca** um substring de `GATE_WHY` — a
  palavra "blocked" também aparece na linha de Jidoka do `gate_EXEC`. Regime diferencial em
  `tests/check-autonomy.sh` + mutante `RUN_blocked_not_escalated`.
- `cf43bb3` — **I4**: `agents/sdd-qa.md`. O `§ 5` passou a explicar o mecanismo em vez de afirmar
  sem ele, e nasceu o `§ 5.1` com o **dever de marcar o gênero** — a única linha de um arquivo de
  bug que é do agente —, com a proibição de tocar em `Status:` repetida ali dentro. Marcar `human`
  exige procedência citada em `arquivo:linha` na seção "Decisions for a Human" do próprio handoff.
  Espelho `.claude/agents/sdd-qa.md` sincronizado por `./bin/sdd install --force`, nunca por `cp`.

## Artefatos

| Arquivo | O que contém |
|---|---|
| `docs/qa/templates/bug.md` | o campo `Closable by:` que a Âncora 3 lê |
| `bin/sdd` (`gate_QA`) | Âncora 3 com gênero; comentário longo com o porquê medido |
| `bin/sdd` (`run_phase`) | o ramo de escalada imediata + o contrato do `GATE_HANDOFF_BLOCKED` |
| `tests/check-gates.sh` | 3 regimes de gênero, um diferencial |
| `tests/check-autonomy.sh` | o diferencial de `status: blocked` (1 sessão × 2) |
| `tests/check-mutation.sh` | `mut_QA_bug_genre_ignored`, `RUN_blocked_not_escalated` |
| `agents/sdd-qa.md` + espelho | `§ 5` verdadeiro e `§ 5.1`, o dever de marcar |
| `docs/handoffs/20260826-o-laco-da-qa/checkpoint.md` | 4 linhas `done` com hash, e as notas |

## Boot da próxima fase

A próxima é **QA**, e ela cai no ramo **sem interface** (`.sdd/config.sh`: `E2E_CMD=""`, sem
`APP_URL`). Ler, nesta ordem: `00-missao.md` (a métrica são 5 fatos binários), este handoff, e o
`checkpoint.md` inteiro — as notas de execução carregam três avisos que custaram caro.

**O que no diff é visível para o usuário.** O "usuário" do kit é quem roda `sdd`, e três coisas
mudaram para ele:

1. **A fase QA deixa de barrar em bug de decisão humana.** Antes, um `docs/qa/bugs/*.md` com
   `Status: open` reprovava o `gate_QA` fosse de que gênero fosse. Agora `Closable by: human`
   passa; `agent` e **ausente** continuam barrando.
2. **`status: blocked` num `30-handoff-qa.md` encerra a corrida na hora**, com `rc 3` e a linha de
   ledger `event: blocked`. Antes custava mais uma sessão para provar a mesma coisa.
3. **O `sdd-qa` tem um dever novo:** marcar `Closable by:` ao triar. Quem executar a QA desta
   missão está lendo a versão nova do próprio contrato — o espelho já está sincronizado.

**Jornadas tocadas, e como andar cada uma no terminal** (não há navegador; a evidência vai no
campo `gate:` do `30-handoff-qa.md`):

- `bash tests/check-gates.sh` → rc 0, 132 `ok`. As três asserções da jornada 1 se chamam
  `genre differential: human-closable passes, agent-closable blocks, reasons differ`,
  `only the agent-closable regime carries the blocking marker` e
  `an open bug with no genre field still blocks (fail-safe for the legacy registry) → QA`.
- `bash tests/check-autonomy.sh` → rc 0, 185 `ok`. A da jornada 2:
  `status: blocked escalates on the first session, where an ordinary gate failure still spends two`.
- `./bin/sdd preflight` → `preflight ok` (é ele que pega espelho de agente desatualizado).
- `./tests/run-all.sh` → `suite green`.

**Como subir o ambiente:** não há ambiente a subir. `bash`, `git`, `jq`, `gh` e `shellcheck` já
estão na máquina — o `preflight` mede todos e passou.

⚠️ **O registry do próprio kit está limpo** (`docs/qa/bugs/*.md` → 6 arquivos, 5 `verified`, 1
`fixed`, **0 `open`**), então o regime que esta missão conserta **não é reproduzível pelo registry
real**. Os testes o constroem em fixture. Não "arrume" um bug aberto para testar à mão.

⚠️ **Se a QA precisar mexer em `agents/*.md`:** o espelho é sincronizado por
`./bin/sdd install --force`, nunca por `cp` e nunca por Edit — o harness trata `.claude/` como
caminho sensível e em sessão headless a ferramenta leva negativa, com a fase parecendo travada.

⚠️ **Ordem que custa 12min quando se erra:** o carimbo de mutação tem como chave o conteúdo de
`bin/ tests/ templates/ config/`. Ele foi tirado **depois** do último commit de código
(`cf43bb3`). Commit em `docs/`, `CLAUDE.md`, `CONTEXT.md` ou `TODO.md` **não** o invalida; mexer em
`tests/health-baseline.txt` **invalida** — e é lá que mora a catraca do backlog, então registrar
achado no `TODO.md` **depois** de carimbar mata o carimbo que o `gate_PR` exige.

## Pendências / Decisions for a Human

> Só julgamento humano genuíno (política de UX, decisão de produto, pagamento real, acesso
> externo). **Não bloqueiam o pipeline** — viram seção do PR. Bug sanável não entra aqui: vira
> incremento de fix no `checkpoint.md`.

Vazio. Nenhum incremento precisou de decisão de produto, e nenhuma intervenção humana entrou na
linha durante a EXEC — as notas do `checkpoint.md` não têm nenhuma linha `intervention:`.

## Riscos e não-feitos

- **A prosa corrigida do `§ 5` não tem sensor próprio — limite declarado.** É contrato em texto, e
  a régua de admissão do D15 manda declarar em vez de inventar probe. O que tem sensor é o
  **mecanismo** (os 3 regimes do `check-gates.sh` + o mutante) e a **sincronia do espelho** (o
  `sdd preflight`). Se alguém reescrever o `§ 5` de volta para a promessa sem mecanismo, nada fica
  vermelho.
- **`Closable by:` é campo de arquivo de bug, e nenhum arquivo real do kit o tem ainda.** Os 6
  bugs do registry foram escritos antes do campo existir; todos estão `verified`/`fixed`, então
  nenhum barra hoje. Num repo-alvo com registry legado, o primeiro bug reaberto vai barrar até
  alguém marcá-lo — que é o fail-safe pedido, mas é uma surpresa se ninguém tiver lido isto.
- **O `sdd-executor` continua sem saber que o registry existe** (`grep -c 'qa/bugs\|Status:'
  agents/sdd-executor.md` → 1, e é sobre o `checkpoint.md`). Está **fora de escopo por decisão do
  plano**, não esquecido: sob a opção C ele não precisa saber.
- **Nenhum agente ganhou permissão de escrever `Status:`**, e isso é resultado, não omissão.
- **Não verificado:** o comportamento novo num repo-alvo de verdade. A missão inteira roda no kit,
  e o efeito medido (12 sessões de QA numa missão) só reaparece na próxima missão de repo-alvo.
- **Desvio de forma registrado no `checkpoint.md` (I1):** o plano grafa o valor como
  `<agent | human>`; foi implementado com o default concreto `agent`. Justificativa na nota.
- **Desvio registrado no `checkpoint.md` (I3):** a saída nova ficou antes do teste de `moved`, não
  de `moved2` como o plano escreveu — a Métrica 4 ("sai 3 na primeira sessão") só fecha aí. O
  ponto de amostragem de `moved2`, que é o que o plano de fato proíbe mover, **não** foi movido.
- **Fora de escopo, e continua fora:** a ADR 0005 (`6e82acb`, `Implementation: NOT YET IN THE
  RUNNER`) é a missão seguinte.

## Achados fora de escopo

> Dois destinos, e a diferença já custou uma `main` vermelha (`2d28d13`).
>
> **Achado sobre o repo-alvo:** registrado no `TODO.md` dele; aqui fica só o ponteiro, para o PR
> conseguir citar.
>
> **Achado sobre o kit** (runner, agente, template), numa missão cujo repo NÃO é o kit: a sessão
> não escreve, não commita e não entra no repositório do kit. A linha **completa** do achado mora
> aqui, marcada `kit:`, e quem a transporta é um humano ou a triagem do `sdd kaizen`. Ponteiro para
> um arquivo que ninguém escreveu é achado perdido.
>
> O exemplo abaixo mora **dentro** desta citação pelo mesmo motivo que o `- intervention:` do
> `checkpoint.md` (`cd49351`): exemplo que abre a linha com `-` é contado verbatim por quem vier
> varrer os handoffs atrás de `kit:`, e todo handoff nasceria devendo um achado fantasma. Copie a
> forma para fora da citação ao registrar um achado de verdade.
>
> - kit: <o quê> — <arquivo:linha do kit> — <por que importa>

Nenhum. **Esta missão é do próprio kit**, então achado de kit iria ao `TODO.md` daqui pela regra
normal — e nenhum foi registrado, de propósito: a régua de admissão do D15 recusou o único
candidato. Ele está descrito abaixo porque a **DOCS** precisa saber que já foi decidido.

- **Não é achado (D15), já resolvido no commit que o criou:** três comentários vivos citavam
  `agents/sdd-qa.md:142` — `bin/sdd` (2×) e `tests/check-gates.sh` (1×) — e o `§ 5.1` do I4
  empurrou a regra para a linha 172, deixando a 142 no meio do `§ 6`. Reancorados no **mesmo
  commit** (`cf43bb3`) e no **heading** (`"Rules that are not negotiable"`) em vez do número, que é
  o que impede a próxima podridão. Não virou item de backlog porque não é fail-open e não tem
  consumidor fora do kit, e porque a varredura (`grep -n '\.md:[0-9]' bin/sdd tests/*.sh
  agents/*.md`) mostrou que **os anchors restantes são de PROVENANCE de skill de terceiro**
  (`report-template.md`, `bug-template.md`), que apontam para fora do repo e cuja forma é
  deliberada.

### Drift para a fase DOCS (não é achado fora de escopo — é a documentação desta missão)

- `docs/qa/README.md:109-113` descreve a Âncora 3 como *"counts files … matching `- **Status:**
  open` and refuses the phase while any exist"*, que o I2 **tornou falso**. O mesmo parágrafo cita
  `bin/sdd:485-491`, e hoje esse trecho é prosa do `gate_TICKET` — a Âncora 3 está em `bin/sdd:620`.
  Reescrever e re-ancorar juntos.
- `KAIZEN_LOG.md`: a missão tem antes/depois medido (12 sessões de QA / US$ 73,32 numa missão de
  repo-alvo → o que a próxima medir). O K8 do checklist kaizen já o previu.
- `CLAUDE.md`: a lição do **gate insatisfazível** — um gate cuja condição nenhum agente do
  pipeline tem permissão de satisfazer é um gate errado, e o sintoma é a fase girar comprando
  volta com achado legítimo. O K7 já o previu.
