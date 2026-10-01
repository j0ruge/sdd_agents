---
missao: 20261001-a-janela-nao-se-parte
titulo: registrar um achado deixa de partir a janela do juiz e de invalidar o carimbo de mutação — a identidade do kit passa a ser o que ele executa
data: 2026-10-01
versao: n/a (JIRA_ENABLED=false)
branch: feat/a-janela-nao-se-parte
aprovacao:
adr: docs/adr/0014-a-identidade-do-kit-e-o-que-ele-executa.md
ddd: aplicado
---

# Missão — A janela não se parte

> Escrito pelo `sdd-planner` com o humano presente (via a sessão coordenadora, 2026-10-01). É a
> única fonte da **intenção**; o `01-plano.md` é a fonte do **como**. Toda sessão headless começa
> lendo estes dois.

## Problema (Gemba)

Duas perguntas — "que versão do kit rodou?" e "que conteúdo o catálogo de mutação mediu?" — têm
respostas largas demais, e o princípio 5 (achado fora de escopo vira item do `TODO.md`) colide com
as duas. Fatos medidos em `c19e987`:

1. **O eixo do juiz é o `HEAD` cru.** `autonomy_kit_stamp` (`bin/sdd:3355`) grava
   `git -C "$SDD_HOME" rev-parse --short HEAD` e `kit_dirty` = qualquer linha de
   `git status --porcelain` da árvore inteira. Os quatro escritores do ledger
   (`autonomy_escalation_row`, `autonomy_gate_pass_row`, `autonomy_close_row`,
   `autonomy_session_row`, `bin/sdd:3910–4125`) o copiam para `kit_sha`/`kit_dirty`. Qualquer commit
   move o eixo, inclusive um que não toca nada que uma fase de alvo executa.
2. **A janela 2 morreu disso.** `git show --stat 6323c6f` = `TODO.md` (+18) e
   `tests/health-baseline.txt` (1 linha, a catraca 87 → 89) — nenhuma linha de `bin/`, `agents/`,
   `templates/`, `config/`. O veredito `docs/handoffs/20260930-a-sub-etapa-que-andou/05-verdict.md`
   saiu `indeterminado`: as 3 missões e US$ 110,18 de `5b98087` foram para `previous`,
   `window_missions_stranded: 3`. O veredito recusou somar as fatias à mão ("seria recalcular a
   série") — a válvula da D4 do `CONTEXT.md` ("o agente interpreta dois SHAs como uma mudança")
   **falhou na prática**.
3. **Não foi caso isolado.** Mapeando cada `kit_sha` das linhas de alvo do ledger real
   (`~/.sdd/autonomy-log.jsonl`, 593 linhas) para
   `git log -1 --first-parent <sha> -- bin agents templates config`: **10 das 17** versões de alvo
   eram um commit de chore/docs (ex.: `5b98087`→`8dd5080`, `6323c6f`→`8dd5080`,
   `a0e34df`→`4c7783f`), e dois pares que viraram fatias separadas eram o mesmo comportamento
   (`5b98087`/`6323c6f` e `5aa21af`/`2d28d13`).
4. **O carimbo de mutação paga o mesmo achado.** `mutation_stamp_key` (`bin/sdd:2023`) faz
   `find bin tests templates config -type f`, e `tests/health-baseline.txt` mora em `tests/`: todo
   achado registrado invalida o carimbo e cobra outro `sdd health` (~18 min) antes do `gate_PR`
   (#117). O conteúdo da baseline não decide o destino de nenhum mutante — quem a lê na suíte é só
   o `check-lang.sh:54`, independente de mutante; o `health_ratchet` (`bin/sdd:6163`) está no
   `cmd_health`, fora da suíte.
5. **O mesmo `find` lê lixo ignorado** (#119): um `tests/debug.log` (ignorado por `*.log`) move a
   chave. E a guarda de vazio só pega a ausência **total** dos quatro caminhos (#107): sem `bin/`,
   a chave sai de uma listagem parcial sem sinal.

## Métrica

Fatos binários, cada um com sensor durável na suíte (`tests/run-all.sh`):

1. **A janela não se parte por commit sem comportamento.** Um ledger de fixture com 3 missões cujas
   linhas atravessam um commit fora dos caminhos de comportamento (dois `kit_sha`, um `kit_rev`)
   responde `sufficient: true`, `window_missions_stranded: 0`; o gêmeo sem `kit_rev` responde a
   ruptura da janela 2 (`window_broken: true`). Asserções `kit-version:` do `check-kaizen.sh`.
2. **O escritor grava a identidade de comportamento.** Num kit de fixture, um commit só de `TODO.md`
   move `kit_sha` e deixa `kit_rev` no último commit de comportamento; um commit em `bin/` move os
   dois; sujeira fora dos caminhos não suja `kit_rev_dirty`. Asserções `kit_rev:` do
   `check-autonomy.sh`.
3. **A guarda do kit não estreitou.** O regime 1 da guarda (sessão que commita `TODO.md` no kit)
   continua dando `KIT-TOUCHED` + `kit-touched`, e um mutante que a faz ler `kit_rev` é pego.
4. **Registrar achado não custa carimbo.** Um commit só de `tests/health-baseline.txt` + `TODO.md`
   deixa o carimbo de pé (`gate_PR` → `DONE`); arquivo ignorado dentro de `tests/` não move a chave;
   raiz sem um dos quatro caminhos nunca é carimbada. Asserções `stamp-key:` do `check-gates.sh`.
5. **Todo mutante novo é pego**, e `tests/check-mutation.sh --anchors` segue verde.

## Resultado esperado

Toda linha do ledger passa a carregar, além do `kit_sha` cru (o fato: onde estava o `HEAD`), o
`kit_rev` — o último commit de primeiro pai que mudou `bin agents templates config` — e um
`kit_rev_dirty` restrito aos mesmos caminhos. Os dois leitores (`sdd kaizen --series` e
`sdd autonomy`) agrupam por `kit_rev` quando ele existe, por uma definição jq única, e mostram os
shas crus que cada fatia cobre. Um PR só de `TODO.md` + catraca deixa de partir a janela e deixa de
invalidar o carimbo. A guarda do kit continua vendo qualquer commit no kit.

## Fora de escopo

- **#67** (o carimbo cobre 4 dos 8 caminhos que a sandbox copia): estreitamento já decidido na ADR
  0004; o item segue aberto no `TODO.md`. A listagem desta missão muda (só rastreados), o texto do
  item continua verdadeiro.
- **Aviso para quem mergeia** commit de comportamento durante uma janela (resto da #188): depois do
  conserto, a única ruptura que sobra é mudança real do kit, que é ruptura legítima. Não passa pela
  régua D15 (nem fail-open, nem consumidor fora da suíte) → linha na seção decidida do `TODO.md`
  (I5).
- **Retroatividade:** linhas antigas não ganham `kit_rev` nem são remapeadas. Medido: a cura
  alcançaria só dois pares históricos, nenhum em `latest`/`previous` (hoje os dois são linhas da
  própria missão de kit da sub-etapa, `5f8df0c`/`954409c`). O `indeterminado` da janela 2 fica como
  está.
- **Missões de kit ocupando `latest`/`previous`** da série (ADR 0003/0005): inalterado.
- O `warn` de árvore suja do `cmd_kaizen` (`bin/sdd:9911`) continua falando da árvore inteira (as
  linhas KAIZEN são `meta`, fora do eixo).
- `CLAUDE.md`, `CONTEXT.md` (D4, *Janela de medição*, *Carimbo de mutação*), `docs/failure-modes.md`,
  `KAIZEN_LOG.md` e a proposta `⛔` para `.claude/rules/anatomia-do-agente.md`: fase DOCS.

## Gate PLAN-AUTO

| # | Critério | Status | Evidência |
|---|---|---|---|
| a | Grill sem perguntas abertas não endereçadas (🚩 vazia ou itens deferidos com dono) | ✅ | 9 perguntas, 9 respostas do humano (todas pela recomendação), registradas em "Decisões do grill" |
| b | Checklist kaizen 100% ✅ e checklist DDD 100% ✅ ou `n/a` justificado | ✅ | seções abaixo |
| c | Plano passa no teste de autocontenção (sessão nova só com 00/01/checkpoint executa) | ✅ | o I1 foi relido só com os três arquivos: funções, linhas, helpers de fixture (`FAKEKIT`, `kitguard_*`), nomes de asserção, mutantes e a receita de verificar mutante isolado estão no `01-plano.md` |
| d | Todo incremento do `checkpoint.md` tem Check executável (comando → esperado) | ✅ | 5 de 5, todos ancorados em `^  ok    ` ou em contagem exata, sem `\|` cru |
| e | `versao:` confirmada pelo humano (ou `JIRA_ENABLED=false`) | ✅ | `JIRA_ENABLED=false` |
| f | `adr:` é uma decisão — um caminho, ou o literal `none` (alocado por `sdd adr new`) | ✅ | ADR alocada por `sdd adr new` (substitui só a parte 1 da ADR 0003; registra também a chave do carimbo) |

`aprovacao:` fica **vazio** por decisão do humano (pergunta 9): ele fecha o gate com
`sdd approve 20261001-a-janela-nao-se-parte`.

## Checklist kaizen (`kaizen-software`)

| # | Item | Status | Nota |
|---|---|---|---|
| K1 | Gemba — fui ver onde o trabalho acontece | ✅ | código lido (`autonomy_kit_stamp`, `kit_guard_check`, os 4 escritores, `kaizen_series`, `cmd_autonomy`, `mutation_stamp_key`, `cmd_health` 2c, `gate_PR`), ledger real medido (202 shas, mapa em 0,4 s, 0 irresolvíveis), suíte rodada verde em 259 s |
| K2 | Problema declarado com métrica | ✅ | 5 fatos binários, cada um com asserção nomeada |
| K3 | Desperdícios identificados e cortados | ✅ | corta o `sdd health` extra por achado (~18 min) e as janelas perdidas (US$ 110,18 na janela 2); descartados o mapa retroativo no leitor (D2, valor medido baixo) e mover a baseline (S2, churn em 7 arquivos) |
| K4 | Fatiamento incremental, cada fatia verificável | ✅ | 5 incrementos, um Red de uma frase cada; escritor antes do leitor, #107 antes de #119/#117 |
| K5 | Check por artefato (rótulo ≠ artefato) | ✅ | Checks leem `^  ok    <asserção>` dos sensores e contam exato; asserções diferenciais (gêmeo com/sem `kit_rev`) |
| K6 | Jidoka — o que para a linha está definido | ✅ | suíte vermelha para; mutante novo não pego = incremento não está pronto; Check de anchors |
| K7 | SDCA — a melhoria vira padrão (doc/rule/teste) | ✅ | poka-yoke no escritor e na chave (não regra escrita); sensores na suíte; mutantes no catálogo; ADR; `docs/pipeline.md` e `agents/sdd-kaizen.md` no mesmo commit do contrato |
| K8 | Registro no KAIZEN_LOG | ✅ | fase DOCS escreve a entrada com o antes/depois medido (antes: PR só de `TODO.md` cunhava versão e matava o carimbo; depois: os sensores `kit-version:` e `stamp-key:`) |

Cinco porquês (raiz de processo): a janela partiu → o PR #184 cunhou `kit_sha` novo → o `kit_sha`
é o `HEAD` → a identidade foi definida como "commit", não "comportamento" → a D4 delegou a nuance
ao agente, e o agente, corretamente, recusou recalcular a série. Contramedida: a identidade de
comportamento vira campo gravado pelo escritor (poka-yoke), não interpretação.

## Checklist DDD (`ddd`) — condicional

Acionado, e não `n/a`: a missão muda o significado do eixo do juiz (um conceito central da
linguagem do kit) e o contrato entre o escritor do ledger e seus dois leitores.

| # | Item | Status | Nota |
|---|---|---|---|
| D1 | Linguagem ubíqua nomeada | ✅ | **versão de comportamento** (`kit_rev`: último commit de primeiro pai que mudou `bin agents templates config`); **caminhos de comportamento** (`KIT_BEHAVIOR_PATHS`); **sha cru** (`kit_sha`, o `HEAD` — continua sendo fato); **chave do carimbo** passa a ser "conteúdo rastreado dos quatro diretórios, menos a catraca". Entram no `CONTEXT.md` na DOCS |
| D2 | Fronteira do contexto | ✅ | identidade de comportamento (juiz) ≠ identidade de toque (guarda do kit) ≠ conteúdo medido (carimbo): três perguntas, três respostas, nenhuma derivada da outra. A guarda do kit continua no par cru |
| D3 | Invariante | ✅ | (i) linha com `kit_rev` presente e `kit_rev_dirty` nulo cai fora do eixo (fail-safe); (ii) incluir caminho a mais só parte janela, nunca funde comportamentos; (iii) os dois leitores aplicam a MESMA normalização no MESMO ponto (depois de `historic_steps`); (iv) a chave do carimbo nunca sai de listagem parcial nem de raiz sem git |
| D4 | Eventos | ✅ | nenhum `event` nem `kind` novo; dois campos novos em toda forma de linha (`kit_rev`, `kit_rev_dirty`) |
| D5 | Contrato entre módulos | ✅ | `docs/pipeline.md` (field reference do ledger) no commit do escritor; `agents/sdd-kaizen.md` §2 (o eixo deixa de ser "o `kit_sha` cru") + espelho por `sdd install --force` no commit do leitor; a saída da série mantém a chave `kit_sha` (agora a versão), então `gate_KAIZEN`/`kit_sha_judged` não mudam [Evans Reference: Published Language] |
| D6 | Decisão registrada | ✅ | ADR nova (substitui a parte 1 da ADR 0003; registra a chave do carimbo e as alternativas descartadas) |

## Decisões do grill (não re-litigar)

1. **Escopo: #188, #117, #107, #119; #67 fora** — mesma raiz ("o que entra na identidade"); #67 já é decisão da ADR 0004.
2. **ADR nova substitui só a parte 1 da ADR 0003** ("o eixo fica `kit_sha`; `autonomy_kit_stamp` intocado") — a válvula "o agente interpreta" foi refutada pelo veredito da janela 2.
3. **D1: campo `kit_rev` (+ `kit_rev_dirty`) no escritor**, leitores normalizam por uma definição jq única, cru preservado, **não retroativo** — leitor puro (a sandbox do catálogo não é checkout git), fato preservado, retroatividade de valor medido baixo.
4. **Caminhos de comportamento = `bin agents templates config`** — `tests/` não roda em fase de alvo; `commands/`, `docs/` também não; na dúvida, caminho a mais só parte janela.
5. **Sujeira restrita ao mesmo conjunto (`kit_rev_dirty`)**; a guarda do kit segue no par cru (`HEAD` + porcelain inteira), com prova (regime 1 + mutante) de que não estreitou — o incidente `2d28d13` foi um commit de `TODO.md`.
6. **S1 para a chave do carimbo**: `git ls-files` (só rastreados), `tests/health-baseline.txt` excluída, cada um dos quatro caminhos obrigatório, raiz sem git não é carimbada — arquivo novo não rastreado fica fora, e quando é commitado o gate recusa (direção segura).
7. **Aviso de merge: fora de escopo**; não passa pela D15 → linha na seção decidida do `TODO.md`.
8. **Gaveta F3**: "janela 3 abandonada por decisão humana em 2026-10-01, sem veredito; a janela 4 abre no primeiro carimbo de alvo após o merge desta missão" — editada no commit do plano.
9. **Branch `feat/a-janela-nao-se-parte`**, `aprovacao:` vazio, fecha com `sdd approve`.

## Pendências para o humano

- **Rodar `./bin/sdd health` uma vez**, depois do último commit de código **e** da última rodada de
  revisão, antes do `gate_PR` (carimbo; ~18 min). Desde esta missão, registrar achado no `TODO.md`
  não o invalida mais.
- Merge do PR é humano. A janela 4 do juiz abre no primeiro carimbo de alvo depois desse merge.
