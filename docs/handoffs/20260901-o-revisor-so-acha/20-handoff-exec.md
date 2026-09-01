---
missao: 20260901-o-revisor-so-acha
fase: EXEC
status: done
sessao: ab979cf8-7817-4a40-a40e-461d4ade8a11
data: 2026-09-01 23:59
gate: "tests/run-all.sh → 855 asserções `ok`, última linha `suite green`, rc 0 (era 842 em `35863d9`); checkpoint sem linha `pending|doing` — I1 `88432ee`, I2 `03187e8`, I3 `c8c8ec7`, I4 `a84adeb`, todos ancestrais de HEAD; working tree limpa"
---

# Handoff — EXEC — O revisor só acha

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

Os quatro incrementos fecharam: o ledger carrega `turns` e imprime `review loop US$ X (N%)` por
missão (I1), o contrato mudou em cinco lugares no mesmo commit — o `sdd-reviewer` **só acha** e o
achado vira incremento `R<n>` (I2), a guarda de aviso `REVIEW-EDITED-CODE` registra a rodada que
voltou a consertar (I3), e a documentação + o "antes" do `KAIZEN_LOG` estão em disco (I4). Suíte
855 asserções verde; catálogo de mutação 218 → 222 mutantes, mas o **carimbo está morto** — quem
re-emite é a fase DOCS, depois do último commit de código. A fase REVIEW desta missão é o
**primeiro teste real** do desenho novo, e é dela que sai a coluna "Depois" do `KAIZEN_LOG`.

## Estado do repo

- **Branch:** `feat/o-revisor-so-acha` — 9 commits à frente de `main` (`35863d9`); **não** há push
  nesta fase.
- **Último commit:** `a84adeb` `docs(review): o contrato novo entra no schema, nos modos de falha e no KAIZEN_LOG`
- **Working tree:** limpo (só falta o commit de checkpoint desta sessão, que acompanha este arquivo).
- **Suíte:** `tests/run-all.sh` → **verde**, 855 asserções `ok`, rc 0 (~85 s).
- **E2E:** `E2E_CMD=""` — o kit não tem interface; não rodou por não existir.

## O que foi feito

- `88432ee` — **I1, o instrumento.** `run_phase` publica `LAST_PHASE_TURNS` lendo `.num_turns` do
  mesmo JSON destilado de onde já lia o custo; `autonomy_session_row` ganha `turns` **lido do
  global** (sem argumento novo, sem tocar os quatro chamadores); escalada e `gate_pass` **não**
  carregam o campo. `cmd_autonomy --by-mission` ganha o sufixo `· review loop US$ X (N%)`, que
  soma as sessões `REVIEW` mais as sessões `EXEC` **posteriores** à primeira REVIEW da mesma
  `(repo, missão)`. Esquema aditivo, `v` continua `1`.
- `03187e8` — **I2, o contrato, em cinco lugares no mesmo commit.** `phase_task REVIEW` passa a
  dizer *"…every finding that must be fixed becomes an R<n> increment in the checkpoint — you do
  NOT fix the code"* e `phase_extra REVIEW` foi reescrito para o laço achar → `R<n>` → (EXEC
  conserta) → a rodada seguinte re-avalia; `agents/sdd-reviewer.md § 3` virou *"findings become
  increments"* com as regras de rigor **intactas**; `agents/sdd-executor.md` aprendeu a linha
  `R<n>`; `templates/review.md` ganhou `## Incrementos de conserto (R<n>)` e
  `templates/checkpoint.md` virou `## Incrementos de fix (QA e REVIEW)`; `docs/pipeline.md § REVIEW`
  descreve o laço. Espelhos `.claude/agents/` sincronizados por `./bin/sdd install --force`.
- `c8c8ec7` — **I3, a guarda.** `review_scope_check` compara o HEAD anterior (o primeiro campo do
  `state_fingerprint`) com o HEAD de agora; qualquer arquivo fora de `<HANDOFF_DIR>/<missão>/`,
  `TODO_FILE` e `tests/health-baseline.txt` gera `warn` + `REVIEW-EDITED-CODE` no `pipeline.log`.
  **Três portas** (`cmd_run` ×2 + `cmd_retry`), aviso e não fronteira.
- `a84adeb` — **I4, a documentação e o "antes".** `config/schema.md` (`BUDGET_REVIEW_USD` fica 40,
  com o porquê; `REVIEW_MAX_ITER` ganha a consequência das duas rodadas), `docs/failure-modes.md`
  (três formas e três diagnósticos quando a review não fecha em A), `CONTEXT.md` (o verbete
  conferido contra o que pousou), `KAIZEN_LOG.md` (entrada no topo, coluna Depois em aberto) e
  `tests/check-lang.sh` (`docs/graphify.md` entra na superfície; piso 37 → **41**).

## Artefatos

| Arquivo | O que contém |
|---|---|
| `docs/handoffs/20260901-o-revisor-so-acha/checkpoint.md` | I1–I4 `done` com hash; notas de execução com cada desvio do plano e o porquê medido |
| `KAIZEN_LOG.md` (entrada de 2026-09-01) | o "antes" medido, a régua reprodutível, a correção do 60% → 57% da janela 2, e a coluna **Depois em aberto** |
| `CONTEXT.md` (verbete *Laço REVIEW⇄EXEC*, D22, D23) | o desenho novo e como ele pousou, um hash por fatia |
| `config/schema.md` · `docs/failure-modes.md` · `docs/pipeline.md § REVIEW` | o contrato onde alguém procura quando algo dá errado |
| `agents/sdd-reviewer.md` · `agents/sdd-executor.md` · `templates/review.md` · `templates/checkpoint.md` | o contrato dos artefatos que a próxima fase escreve |

## Boot da próxima fase

A próxima fase derivada do disco é **QA**. No kit não há interface: `E2E_CMD` é vazio, `docs/qa/`
não existe e o runner só abre `QA:close` — a sessão de QA caminha a jornada ela mesma, e a jornada
aqui é **de linha de comando**.

**O que no diff é visível ao usuário do kit** (o humano que roda `sdd`):

1. `./bin/sdd autonomy --by-mission` e `--all-repos --by-mission` ganharam o sufixo
   `· review loop US$ X (N%)`, que só aparece em missão que teve sessão REVIEW. Hoje **16 células**
   o imprimem no ledger real. Confirmação independente: `20260831-a-rodada-que-andou` lê
   `review loop US$ 66.34 (50%)`, exatamente o número que o `00-missao.md` cita para o PR #33.
2. Linha de sessão do ledger tem campo novo `turns`; linhas de escalada e `gate_pass` **não**.
   Leitor antigo ignora campo desconhecido.
3. `./bin/sdd run <missão> --phase REVIEW --dry-run` imprime um boot prompt **diferente**: manda
   achar e escrever `R<n>`, e não contém mais `review and fix, INSIDE`.
4. Uma sessão REVIEW que commitar código fora do diretório da missão passa a emitir um `warn` na
   stderr e uma linha `REVIEW-EDITED-CODE` em `.sdd/logs/<missão>/pipeline.log`.
5. `sdd install --force` re-sincroniza dois agentes (`sdd-reviewer`, `sdd-executor`); os espelhos
   já estão em dia nesta branch (`diff -q` vazio para os sete).

**Como subir o ambiente:** não há ambiente para subir. `cd ~/repos/sdd_agents && ./bin/sdd preflight`
e `tests/run-all.sh` são o mundo inteiro. ⚠️ **Não rodar `./bin/sdd health` nas fases QA/REVIEW** —
ele leva 15–50 min (roda o catálogo de mutação) e o carimbo pertence à fase DOCS, depois do último
commit de código.

⚠️ **Para a fase REVIEW, que é a primeira a rodar o contrato novo:** o desenho que ela deve seguir
está no seu próprio boot prompt e em `agents/sdd-reviewer.md`. Duas coisas que a M2 do
`00-missao.md` mede sobre esta própria missão: cada sessão REVIEW **≤ 60 turnos e ≤ US$ 15**, e o
laço de revisão inteiro (REVIEW + EXEC dos `R<n>`) **≤ US$ 40**. A M3 é invariante: o
`gate_REVIEW` **não mudou** (A em toda linha + `Rationale` com frase), e o diff de
`agents/sdd-reviewer.md` **não removeu** nenhuma regra de reprodução ou refutação — isso é para ser
**conferido** na revisão, não assumido.

## Pendências / Decisions for a Human

- **A coluna "Depois" do `KAIZEN_LOG.md` está em aberto de propósito.** Ela só pode ser preenchida
  depois de a REVIEW desta missão rodar, e quem a preenche é a fase DOCS com os comandos de
  `01-plano.md § Para a fase DOCS`. Não é bloqueio: é a recusa deste repo em registrar previsão
  como medição.
- **A janela 3 abre no sha do merge desta missão** (padrão D19) e o veredito é do `sdd kaizen`
  depois de 2–3 missões reais do `sales_quote`, sem commit na `main` do kit. Decisão de quando
  abrir e fechar é humana.

## Riscos e não-feitos

- **Nenhum número de custo mudou ainda.** O diff é contrato, instrumento e guarda; o efeito é a
  próxima rodada de REVIEW. A M1 (mediana ≤ 25%, máximo ≤ 50%) só fecha na janela 3.
- **O carimbo de mutação (`.sdd/logs/mutation-stamp`) está morto** desde `88432ee`: `bin/`,
  `tests/` e `templates/` mudaram. `gate_PR` o exige. Re-emitir é tarefa da DOCS, **depois** do
  último commit de código — e registrar achado no `TODO.md` invalida a chave outra vez
  (`tests/health-baseline.txt` está dentro dela). Ordem: achados → catraca → `./bin/sdd health`.
- **O catálogo de mutação (222) não foi rodado ponta a ponta nesta fase** — é opt-in desde
  `4c86712` e seguraria a árvore por >10 min por gate. Cada um dos quatro mutantes novos foi
  provado numa cópia da árvore (aplica, `cmp` acusa diferença, `bash -n` compila, e o sensor
  nomeado fica vermelho **só** na asserção nomeada), mas a verificação do catálogo inteiro é da
  DOCS.
- **A guarda `REVIEW-EDITED-CODE` avisa, não impede**, e é cega a um `commit --amend` que
  reescreva o HEAD anterior — limite declarado no cabeçalho da própria função.
- **`turns` é um contador do harness, não uma medida de contexto.** Correlaciona com o cache-read
  (corr 0,94 sobre 28 rodadas, R² 0,36 — ordem de grandeza) e não o substitui.
- **O desenho novo gasta duas rodadas no caminho normal** (r1 é B por desenho quando há o que
  consertar), então `rounds` deixa de ser comparável entre janelas. Régua declarada no
  `KAIZEN_LOG.md`, no `CONTEXT.md` (D22) e no `config/schema.md`.
- **Não verificado:** nenhuma sessão REVIEW real rodou ainda no contrato novo. O que existe é o
  prompt projetado pelo dry-run e a máquina de estados medida por fixture.

## Achados fora de escopo

> ⚠️ **Nada foi escrito no `TODO.md` nesta fase, e é deliberado:** `tests/health-baseline.txt` está
> na chave do carimbo de mutação, então registrar achado aqui mataria o carimbo outra vez
> (`01-plano.md § Configuração e pitfalls`). Os itens abaixo são para a **fase DOCS** transportar
> ao `TODO.md` **com a catraca no mesmo diff**, antes do `./bin/sdd health`. Este repo **é** o kit,
> então o destino é o `TODO.md` daqui — nenhum item precisa da rota `kit:`.

- `run_phase` não limpa o ambiente do harness antes do `claude -p` — `bin/sdd` (função
  `run_phase`) — um `sdd run` lançado de dentro de uma sessão do Claude Code herda
  `CLAUDE_CODE_CHILD_SESSION`, `CLAUDE_CODE_MESSAGING_SOCKET` e afins e é morto pelo harness sem
  ação humana (2× em 2026-08-30); a saída é `env -u CLAUDECODE -u CLAUDE_CODE_* …` no próprio
  `run_phase`, com o probe correspondente — descoberto por `humano` na missão
  `20260830-invariante-do-frete-no-agregado` (2026-08-30), registrado em `01-plano.md § Achados do
  planejamento` por `sdd-planner` (2026-09-01) → `TODO.md`
- `tests/check-lang.sh` `surface()` **enumera** arquivos em vez de casar `docs/*.md` —
  `tests/check-lang.sh:50` — um doc novo em `docs/` nasce **fora** da régua de idioma enquanto o
  `CLAUDE.md § Idioma` promete `docs/` inteiro; o I4 cobriu `docs/graphify.md` **um arquivo por
  vez**, o glob fica como decisão — descoberto por `sdd-planner` na missão
  `20260901-o-revisor-so-acha` (2026-09-01) → `TODO.md`
- **Achado novo desta fase (I4):** o piso anti-vacuidade do `tests/check-lang.sh` **ficou três
  caminhos para trás** e ninguém percebeu — ele dizia 37 enquanto a superfície real já era 40,
  porque as ADRs 0004, 0005 e 0006 entraram pelo glob `docs/adr/*.md` sem tocar o número. Piso que
  fica para trás continua **passando** medindo uma superfície menor que a que lê, que é a falha
  que o próprio comentário do sensor já nomeia uma vez (r1 de `20260817-eixo-do-juiz`). Corrigido
  aqui para 41, mas a **classe** continua viva: todo piso deste repo que convive com um glob tem o
  mesmo modo de falha, e nenhum instrumento avisa quando um deles fica para trás — só o humano
  que recontar. Candidato: derivar o piso, ou um sensor que compare piso × superfície real em
  todos os sensores que têm um → `TODO.md` (descoberto por `sdd-executor` na missão
  `20260901-o-revisor-so-acha`, 2026-09-01)
- **Achado novo desta fase (F2):** a asserção vizinha `review_check '^## Incrementos de conserto'`
  (`tests/check-templates.sh`) tem o **mesmo formato** do defeito que o `F2` acabou de fechar — o
  rótulo promete `Incrementos de conserto (R<n>)` e a regex para em `conserto`. **Medido** nesta
  sessão: com o heading do template trocado para `## Incrementos de conserto (F<n>)`, o sensor
  responde `rc=0`. É um caso mais fraco que o do `F2` — nenhum heading foi *substituído* aqui, então
  a regex frouxa não certifica um contrato antigo, só admite um sufixo que nunca existiu —, e por
  isso ficou **fora** do diff: o `F2` nomeia uma linha, e apertar a vizinha é o "já que estou aqui"
  que esta fase recusa. Uma varredura da família inteira do arquivo devolve **só** essa (`grep -nE
  '^ *(check\|review_check\|refute) ' tests/check-templates.sh` filtrando parêntese não escapado)
  → `TODO.md` (descoberto por `sdd-executor` na missão `20260901-o-revisor-so-acha`, 2026-09-01)
