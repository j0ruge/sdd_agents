---
missao: 20260819-fecho-que-nao-mente
fase: EXEC
status: done
sessao: 5a129c75-96ae-4d73-9d9f-c2a86cc14a79
data: 2026-08-19 18:05
gate: "tests/run-all.sh → `suite green`, rc 0, 1m36s (58% cpu), 14 passos; as quatro asserções da métrica presentes com `^  ok    `: `mutation: a score whose caught differs from total is refused`, `surface: --list prints steps only, and a TEST_CMD carrying it is refused`, `gate_REVIEW: a placeholder Rationale does not buy an A`, `gate_PR: the mutation stamp is demanded only where the catalogue lives`. Checkpoint: 4 de 4 incrementos `done`, hashes 7a6653b / 2f71646 / 9fa5b0b / c962e2e, todos ancestrais de HEAD."
---

# Handoff — EXEC — O caminho que certifica o fecho de uma missão para de afirmar o que não mediu

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

Os quatro instrumentos que certificam o fecho de uma missão pararam de poder dizer "verde" sem ter
medido: o `sdd health` compara os dois números do próprio `score:`, o `--list` não passa mais por
uma suíte que rodou, o `gate_REVIEW` recusa selo com justificativa de placeholder, e o catálogo de
mutação ganhou dono — o `gate_PR` exige carimbo de catálogo verde sobre o conteúdo atual.
Suíte verde; catálogo de 104 → 109 mutantes. **A fase QA começa por rodar `./bin/sdd health`**: sem
ele o `gate_PR` desta própria missão reprova, e isso é o I4 funcionando.

## Estado do repo

- **Branch:** `fix/fecho-que-nao-mente` — **sem upstream**; nada foi empurrado (é da fase PR).
- **Último commit:** `0af6654` `chore(checkpoint): I4 done em c962e2e, com o defeito que a passada adversarial achou na própria asserção`
- **Working tree:** limpo.
- **Suíte:** `tests/run-all.sh` → **verde**, rc 0, 1m36s. Ponto de partida da missão: 1m24s.
- **E2E:** `E2E_CMD=""` — o kit não tem interface; n/a por configuração, não por omissão.
- **Catálogo de mutação:** opt-in, **não** roda no `TEST_CMD`. Rodada completa em andamento no fim
  desta sessão; o `N` do `CATALOG=(` foi de **104** (`9bc65dd`) para **109**.

## O que foi feito

- `7a6653b` — **I1.** A checagem 2 do `sdd health` lê os **três** números do `score:` e só diz `ok`
  com `gaps == 0` **e** `caught == total`. Antes, `score: 103 caught, 0 known gap(s), of 104` —
  exatamente o que a `main` carregou entre os PRs #12 e #13 — imprimia `ok`. Ganhou um ramo para a
  linha que **não parseia**, senão um `sed` que deixasse de casar pularia a comparação em silêncio.
  Mutante `mut_HEALTH_mutation_survivor_blind`.
- `2f71646` — **I2.** Duas metades do mesmo buraco: `--list` imprime só passos (a mensagem
  `(linter absent — skipped)` saiu do caminho da lista), e um `TEST_CMD` que carregue `--list` é
  recusado pelo `sdd health` — é um comando que sai 0 tendo rodado nada e faria **todo gate**
  passar. Mutante `mut_HEALTH_testcmd_list_blind`.
- `9fa5b0b` — **I3.** O `awk` do `gate_REVIEW` passou a ler `f[4]`: `A` em toda linha com
  `PREENCHER` em toda justificativa deixou de comprar o selo. O campo `gate:` do frontmatter entra
  no **mesmo** `awk` via `-v`, para não haver duas grafias da lista de tokens. Nove mundos
  diferenciais; mutantes `mut_REVIEW_placeholder_rationale_blind` e `mut_REVIEW_gate_field_blind`.
- `c962e2e` — **I4.** `cmd_health` grava um carimbo — o md5 do conteúdo de
  `bin/ tests/ templates/ config/` — depois das checagens 1 e 2 passarem, e o **remove** quando
  qualquer uma reprova. `gate_PR` exige esse carimbo como **último** requisito, e **só** onde
  `tests/check-mutation.sh` existe (escopo por artefato, nunca por identidade de repo). Sete mundos
  em três pares; mutante `mut_PR_stamp_blind`.
- `ca0a360` `dc6a6c9` `c8de654` — os `RESOLVIDO por <hash>` dos quatro achados que a missão fecha,
  mais os três que ela abriu, com a catraca `todo-findings` movida no mesmo commit (72 → 76).
- `742cc67` `66f482e` `5d72d72` `0af6654` — checkpoint, um por incremento, com as notas de desvio.

## Artefatos

| Arquivo | O que contém |
|---|---|
| `docs/handoffs/20260819-fecho-que-nao-mente/checkpoint.md` | Tabela 4/4 `done` + **30 notas de execução** — os desvios do plano, as medições e as armadilhas. É o documento mais denso da missão. |
| `bin/sdd` | `cmd_health` checagens 2, 2b e 2c; `gate_REVIEW` (extrator `f[4]` + `gate:`); `gate_PR` (carimbo); `mutation_stamp_key` e as duas constantes acima dele. |
| `tests/check-gates.sh` | As duas asserções diferenciais novas (I3, nove mundos; I4, sete mundos). |
| `tests/check-health.sh` | As duas asserções novas (I1, I2) e o `CAPTURE_FLOOR` 16 → 19 (medido em `git show 9bc65dd:`, não de memória). |
| `tests/check-mutation.sh` | Cinco mutantes novos; `CATALOG=(` de 104 para 109. |
| `TODO.md` + `tests/health-baseline.txt` | Quatro achados fechados, três abertos, catraca em 76. |

## Boot da próxima fase

A fase QA num projeto **sem interface** (é o caso: `E2E_CMD=""`, `APP_URL` ausente) é uma sessão só,
e o `sdd-qa` julga se o diff é visível ao usuário. Ler nesta ordem: `00-missao.md` (a métrica são
quatro fatos binários + o fecho do catálogo), este handoff, e as notas do `checkpoint.md`.

**Comece por isto, antes de qualquer outra coisa:**

```
./bin/sdd health            # ~20 a 50 min, é ele que roda o catálogo E grava o carimbo
```

Três razões que se somam: é o **fecho da métrica** (`00-missao.md` § Métrica pede
`score: N caught, 0 known gap(s), of N` com `caught == of` e `N >= 108`; hoje `N` é 109); é o único
lugar onde o catálogo roda, já que o `TEST_CMD` não o roda desde `4c86712`; e é ele que **destrava
o `gate_PR` desta própria missão**. Se o `gate_PR` reprovar com
`no green mutation catalogue for this content`, o I4 está funcionando — rode `sdd health` e siga.

⚠️ **Quando rodar importa.** O carimbo chaveia no conteúdo de `bin/ tests/ templates/ config/`.
Qualquer commit que toque esses quatro — um incremento de fix do QA, um conserto da REVIEW —
invalida o carimbo. `CLAUDE.md`, `docs/` e `TODO.md` **não** invalidam (foi decisão de desenho,
registrada com a fronteira no `TODO.md`). Regra prática: `sdd health` **depois** do último commit
de código.

**Superfície visível ao usuário** (o kit não tem UI; "usuário" é o operador do runner):

- `sdd health` ganhou duas linhas novas na saída (`TEST_CMD runs the suite (...)` e
  `mutation stamp written — ...`) e três mensagens de recusa novas.
- `sdd why <missao> PR` pode agora responder `no green mutation catalogue for this content — run
  'sdd health' (...)`. É a mensagem que um humano vai ler mais vezes por causa desta missão.
- `sdd why <missao> REVIEW` pode agora nomear um critério com `placeholder Rationale`.
- Ambiente: nenhum. Sem serviço, sem porta, sem migração — `bash` e a suíte.

**Jornadas tocadas:** a derivação de fase de toda missão do repo (o `gate_PR` é reavaliado em todo
comando) e o comando `sdd health`. `./bin/sdd status`, `./bin/sdd why` e `./bin/sdd run --dry-run`
desta missão foram rodados depois do I4 e projetam até a fase PR sem erro (`rc 0`).

## Pendências / Decisions for a Human

- **A convenção do `RESOLVIDO por` × a catraca do backlog.** Esta missão seguiu o cabeçalho escrito
  do `TODO.md` (item fechado fica, com a caixa desmarcada e o hash no corpo, até o merge), enquanto
  a missão passada apagou na hora (`6136d39`). Enquanto as duas coexistirem, `todo-findings`
  significa coisas diferentes em missões diferentes. — `TODO.md`, § Contrato e configuração.
- **CI rodando `tests/run-all.sh --with-mutation`.** É a outra saída que o achado do I4 nomeava, e
  depende de decisão de custo humana (repo privado, catálogo de ~20 a 50 min). O I4 fechou o buraco
  por dentro do kit, sem infraestrutura; o carimbo continua valendo como gate local se o humano
  quiser CI depois. — `00-missao.md` § Fora de escopo.
- **As três decisões de desenho que nasceram sem humano** (plano kaizen-born): carimbo em vez de
  CI, escopo por artefato em vez de identidade de repo, e chave no conteúdo em vez do `HEAD`. Estão
  em `00-missao.md` § Decisões do grill, e foram implementadas como escritas.

## Riscos e não-feitos

- **O carimbo cobre 4 dos 8 caminhos que a `sandbox()` do catálogo copia.** `agents/`, `CLAUDE.md`,
  `TODO.md` e `docs/adr` ficam de fora, então mudança confinada a eles mantém o carimbo válido
  sobre conteúdo que o catálogo de fato mede (a regra 12 do `check-health.sh` lê o `CLAUDE.md`).
  Estreitamento **deliberado** e declarado no `TODO.md`, não descuido — chavear no `CLAUDE.md`
  custaria uma segunda rodada de ~20 min por missão, porque a fase DOCS o edita a caminho do PR.
- **O ramo `[ -z "$key" ]` do `gate_PR` não tem mundo que o alcance** e está declarado como tal no
  comentário. Ele carrega peso real (carimbo ausente lê vazio, e uma chave vazia compararia igual),
  mas a passada adversarial confirma que degradá-lo não reprova nada. Dívida declarada, não coberta.
- **`sdd health` não foi visto verde ponta a ponta dentro desta sessão.** A rodada foi disparada em
  background no fim do EXEC; o log fica em `/tmp/sdd-health-i4.log`. O gate desta fase é o
  `TEST_CMD`, que está verde — mas a **métrica da missão** só fecha quando alguém ler a linha
  `score:` dessa rodada. É o primeiro comando do boot acima, e é por isso que ele está lá.
- **A suíte ficou mais lenta:** 1m24s → 1m36s (+14%). Registrado, não convertido em achado: o
  limiar de ~60 s da tabela de riscos do plano já estava vencido antes da missão começar, então
  mede a coisa errada. Se virar incômodo, o custo está nas quatro invocações reais de `sdd health`
  dentro do fixture do `check-gates.sh`.
- **Não-feitos declarados no plano, todos intactos:** a re-derivação das âncoras do `TODO.md`, o CI,
  o auto-teste do `check-templates.sh` e as famílias grandes do `check-todo.sh`/`check-health.sh`.

## Achados fora de escopo

> Registrados no `TODO.md` deste repo (é o kit). Aqui fica só o ponteiro, para o PR conseguir citar.

- O carimbo cobre 4 dos 8 caminhos que a `sandbox()` copia → `TODO.md` (achado do I4).
- A checagem 2b lê o `TEST_CMD` do kit e não do repo-alvo, então um `TEST_CMD` de repo-alvo que sai
  0 sem rodar nada continua invisível → `TODO.md` (achado do I2).
- `que`, `nao` e `sem` são stopwords do `check-lang.sh` e o `-w` as casa **dentro** do slug
  hifenizado, então citar o slug desta missão em `tests/` reprova → `TODO.md` (achado do I3).
- `gate:` **ausente** no `40-review-rN.md` é deixado em paz (6 das 14 rodadas em disco não têm o
  campo), então ausente e placeholder afirmam o mesmo nada → `TODO.md` (achado do I3).
