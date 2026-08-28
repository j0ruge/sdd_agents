# Handoff — o gate aprende a dizer "o mundo está quebrado"

**Data:** 2026-08-28 · **Estado:** plano **aprovado**, **I1 a I8 commitados**. Falta abrir o PR.

Auto-contido de propósito. A sessão que ler isto não participou da conversa que o gerou.
Onde há número, ele foi medido.

---

## 1. Comece por aqui

```bash
cd ~/repos/sdd_agents
git branch --show-current                  # esperado: feat/o-gate-sabe-que-o-app-caiu
git log --oneline d30d199..HEAD | wc -l    # esperado: 9
git status --porcelain                     # TEM de sair vazio

./tests/run-all.sh                         # suite green
./bin/sdd health --with-mutation           # score N+6, carimbo escrito
```

O plano completo está em `~/.claude/plans/isso-t-um-inferno-fluttering-glade.md`.

## 2. Por que esta missão existe

A missão anterior (SQ-111, repo-alvo `sales_quote`) fechou, mas exigiu **~8 resgates humanos**. A
investigação achou **uma causa, não oito**: todo `gate_*` devolve 0 ou 1, e em `gate_QA` app fora
do ar, banco parado, browser faltando e asserção genuinamente quebrada colapsavam no **mesmo
`return 1` com a mesma frase**. Aí `cmd_run` via `moved=true` e comprava outra sessão.

Custo medido: **US$ 14,16** (QA reprovada por ambiente) + **US$ 7,61** (o retorno depois do PR
aberto) + **US$ 37,30** (o `gate_REVIEW` reabrindo a fase mais cara quando o DOCS morreu).

**Alvo:** o kit nunca gasta sessão paga contra o que nenhuma sessão pode consertar. Subir o app
segue sendo trabalho do operador; o que mudou é que o runner **pergunta** e **para**.

## 3. O que foi feito

| | |
|---|---|
| `main` | `d30d199` |
| branch | `feat/o-gate-sabe-que-o-app-caiu`, 9 commits à frente |
| I1 `8ca8470` | asserções do gate, vermelhas pelo motivo certo |
| I2 `ab0278f` | `app_url_hostport` + `app_probe` + `GATE_APP_DOWN` + os três arms de `GATE_WHY` |
| I3 `8f333ea` | o par da escalada, vermelho (`3\|2\|blocked\|no-progress`, o laço de hoje) |
| I4 `2ce6ce8` | `app_down_escalation` e as duas portas |
| I5 `0507b8e` | o par retry/fase-errada, provado por sabotagem em cópia |
| I6 `0184ace` | `cmd_preflight` + as asserções do preflight |
| I7 `2516d14` | as seis mutações, cada uma com o assassino nomeado |
| I8 `f7bb72c` | `pipeline.md`, `failure-modes.md`, `schema.md`, `starter.conf`, `TODO.md` |

## 4. O desenho, em três frases

**A sonda roda no caminho vermelho, nunca como precondição.** Só depois de `E2E_CMD` já ter
voltado não-zero. Sondar antes bloquearia todo repo cujo e2e sobe o próprio servidor — e um
BLOCKED falso gasta uma pessoa, enquanto o laço só gasta dinheiro. É o que a asserção verde
`a dead app does NOT block a green e2e` protege, ao lado do fixture `example.invalid`.

**Tri-estado, e o default `unknown` nunca escala.** `APP_URL` vazio, bash sem `/dev/tcp`,
`timeout` ausente, DNS que não resolve, string de erro diferente: tudo cai em `unknown`, onde o
comportamento é byte a byte o de antes. Só `Connection refused` vira `down`. O sensor é unilateral
por construção — vermelho vira vermelho **nomeado**, verde nunca vira vermelho.

**Nenhuma chave de config nova.** `APP_URL` já existia; o contrato dela alargou.

## 5. Verificação ponta a ponta

```bash
./tests/run-all.sh                      # suite green
./bin/sdd health --with-mutation        # score N+6, carimbo escrito
bash tests/check-gates.sh               # o par da app morta, nas duas metades
bash tests/check-autonomy.sh            # 3|1|blocked|app-down vs 3|2|blocked|no-progress
bash tests/check-preflight.sh
tests/check-lang.sh
```

**Aceitação:** com o app fora do ar e `E2E_CMD` configurado, `sdd run` gasta **uma** sessão de QA,
sai rc 3, e a linha do ledger diz `app-down` nomeando o endereço.

## 6. As três decisões que se afastaram do plano, e por quê

- ⚠️ **A asserção da projeção (`--dry-run` escreve zero linhas) foi escrita e removida.** Nenhuma
  sabotagem a deixava vermelha. Três mundos construídos e medidos: escalada içada acima do
  early-exit da projeção (verde); guarda de `DRY_RUN` do `autonomy_append` removida (12 vermelhas,
  todas do bloco de dry-run do topo); guarda do `pipeline_log_line` removida (3 vermelhas, do
  `check-dry-run.sh`). A escalada só chega ao ledger **pelo** `autonomy_append`. O que foi medido
  ficou escrito no lugar onde ela estava.
- ⚠️ **O `mut_QA_hostport_no_default_port` nasceu apagando a linha e o mutante não compilava** —
  a linha é o corpo inteiro de um `if`. `run_mutant` teria devolvido rc 91, que é ponto para o
  shell e zero para as asserções. Hoje ele **neutraliza** os arms.
- ⚠️ **A ordem do carimbo inverteu.** O plano mandava carimbar entre I7 e I8; o I8 toca `config/`,
  que **compõe** a chave. `sdd health --with-mutation` roda depois do I8.

## 7. Armadilhas medidas

- **`check-lang.sh` reprova slug de missão pt-BR na superfície inglesa** — o gatilho aqui foi a
  palavra `mesmo` do slug de 2026-08-27, que está na lista de stopwords. Contornado citando
  "SQ-111 mission of 2026-08-27". É item aberto no `TODO.md`.
- **Piso que usa a função sob teste não é piso.** Os três pisos de porta-morta (`check-gates`,
  `check-autonomy`, `check-preflight`) são `timeout bash -c 'exec 3<>…'` crus, e morrem por nome
  quando não acham porta recusada.
- **`check-gates.sh` e `check-autonomy.sh` rodam com `set -uo pipefail` — sem `-e`.** Capture rc
  com `|| rc=$?`.
- **Probe de sabotagem morre alto** quando o trecho que ele esperava mudar não mudou. Todos os
  desta missão fazem isso com `assert` em Python antes de concluir.

## 8. O que falta

1. **Abrir o PR** contra `main` (`d30d199`), citando o carimbo e o score.
2. Depois do merge, **apagar** o item `RESOLVIDO por 2516d14` do `TODO.md` e baixar a catraca
   `todo-findings` no `tests/health-baseline.txt` — provado por
   `git merge-base --is-ancestor 2516d14 main`, nunca pelo rótulo do PR.

## 9. A próxima missão, já desenhada

1. **O instrumento honesto.** `sdd autonomy` diz `0 stalled · 0% waste` para a missão que exigiu 8
   resgates: `stalled` está definido como `moved == false`, ou seja "o modelo escreveu algo", não
   "a fase avançou". Das 145 sessões da história, **81 reprovaram o gate** e o leitor lê 0% de
   desperdício. O leitor deriva `advanced`/`churned`/`idle` de `gate` + `moved` — campos que as 145
   linhas históricas **já têm**, então zero migração. Mais `launches` e `reopened`. Medido:
   `20260818-lote-facil` aparece como 9 sessões/US$ 120,38 e foram **14 sessões, 4 lançamentos,
   US$ 230,44** — subestimou US$ 110, 91%. **Sem isso não dá para provar que esta missão
   funcionou.**
2. **Faxina D15.** ~12 itens são limites já declarados que deviam morar no cabeçalho do sensor, e
   os 3 de `Adiados por YAGNI` são roadmap inflando a catraca. 77 → ~62, num diff com autor.
3. **O REVIEW** — 49% do custo de uma missão, US$ 37,30, a US$ 2,70 do próprio teto.

⚠️ **A régua que o backlog viola hoje:** dos 77 achados, **49% não têm consumidor fora do repo do
kit**; toda intervenção do operador rastreia para **18** achados de três classes, e **nenhuma**
para os 27 de "sensor sobre sensor". 32 dos 77 nasceram do `sdd-reviewer` auditando o próprio kit;
só **4** vieram de trabalho real em repo-alvo. Missão de kit que não encosta nessas três classes
está polindo o eixo errado.
