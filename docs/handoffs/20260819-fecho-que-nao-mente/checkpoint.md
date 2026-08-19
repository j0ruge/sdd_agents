---
missao: 20260819-fecho-que-nao-mente
atualizado: 2026-08-19 15:20
---

# Checkpoint — O caminho que certifica o fecho de uma missão para de afirmar o que não mediu

> **Este arquivo é lido por máquina.** O runner faz parse da tabela abaixo para decidir a
> próxima fase. Não mude as colunas, não mude os tokens de status, não quebre linhas dentro de
> uma célula. Detalhe narrativo vai no `01-plano.md`, não aqui.
>
> ⚠️ **Nada de `|` na célula do Check — nem escapado como `\|`.** O parser é `awk -F'|'` cru e
> não conhece o escape do GFM: a célula vira duas, o Status lido passa a ser um pedaço do
> comando e o Commit passa a ser `pending`. O `gate_EXEC` reprova por "invalid status" e o
> `sdd status` imprime algo de aparência saudável — custou uma missão inteira até alguém olhar.
> Check que precisaria de pipe vira herestring: `` o=$(cmd 2>&1); grep -c 'x' <<< "$o" ``.
>
> ⚠️ **Check que lê a saída de um sensor ancora em `^  ok    ` — quatro espaços, com o `^`.**
> Todo sensor da suíte imprime `  ok    <asserção>` na **stdout** e `  FAIL  <asserção>` na
> **stderr**, com o *mesmo* `<asserção>`. Um Check que faz `2>&1` e grepa o texto solto devolve o
> mesmo número com a asserção verde e com ela vermelha: ele responde "a asserção existe", nunca
> "a asserção passou". Custou uma missão inteira, achado só na fase QA. A forma certa:
> `` o=$(bash tests/check-x.sh 2>&1); grep -c '^  ok    <asserção>' <<< "$o" `` → `1`.
> O sensor é `tests/check-checkpoint.sh`.
>
> Atualizar o checkpoint é o **último ato** de cada incremento — depois do commit, nunca antes.
> Status válidos: `pending` · `doing` · `done` · `blocked`.

| ID | Incremento | Check (comando → esperado) | Status | Commit |
|---|---|---|---|---|
| I1 | O `sdd health` compara os dois números do `score:` | `o=$(bash tests/check-health.sh 2>&1); grep -c '^  ok    mutation: a score whose caught differs from total is refused' <<< "$o"` → `1` | done | 7a6653b |
| I2 | O `--list` imprime só passos, e `TEST_CMD` com `--list` é recusado | `o=$(bash tests/check-health.sh 2>&1); grep -c '^  ok    surface: --list prints steps only, and a TEST_CMD carrying it is refused' <<< "$o"` → `1` | done | 2f71646 |
| I3 | O `gate_REVIEW` recusa placeholder na `Rationale` | `o=$(bash tests/check-gates.sh 2>&1); grep -c '^  ok    gate_REVIEW: a placeholder Rationale does not buy an A' <<< "$o"` → `1` | pending | — |
| I4 | O catálogo ganha dono: `sdd health` carimba, `gate_PR` exige | `o=$(bash tests/check-gates.sh 2>&1); grep -c '^  ok    gate_PR: the mutation stamp is demanded only where the catalogue lives' <<< "$o"` → `1` | pending | — |

## Notas de execução

> Uma linha por evento relevante: bloqueio, decisão tomada, desvio do plano com justificativa.
> É o que a próxima sessão lê para não repetir um erro que já custou caro.

- 2026-08-19 13:40 · `plano` · Nascido pela sessão `sdd kaizen` ao lado de `05-verdict.md`, sem humano. `aprovacao:` vazia por contrato — só `sdd approve 20260819-fecho-que-nao-mente` a preenche.
- 2026-08-19 13:40 · `I1` · **Primeira nota do executor deve registrar o `N` de partida do catálogo**: rode `./bin/sdd health` e anote a linha `score:` verbatim. Sem esse número, a verificação end-to-end ("N cresceu pelo menos 4") não tem contra o que comparar.
- 2026-08-19 13:40 · `I4` · A ordem I1 → I4 é dependência real: carimbar antes de consertar o veredito do `score:` gravaria em disco a certificação de um catálogo com sobrevivente.
- 2026-08-19 · `I1` · **`N` de partida do catálogo = 104**, medido no `9bc65dd` (a `main` desta missão) e não em prosa: `awk '/^CATALOG=\(/{f=1;next} f&&/^\)/{exit} f&&NF{n++} END{print n}' tests/check-mutation.sh` → `104`. Depois do I1 são **105**. O fecho exige `of N` com `N >= 108` e `caught == of`.
- 2026-08-19 · `I1` · A linha `score:` **verbatim** de partida não entrou nesta nota porque o catálogo leva ~20 a 50 min e a sessão headless morre se encerrar o turno esperando comando. Ela está sendo medida numa worktree limpa do `9bc65dd`, em background: saída em `/tmp/sdd-baseline-score.txt`, worktree em `/tmp/sdd-baseline` (apagar com `git worktree remove /tmp/sdd-baseline`). Quem a quiser, lê o arquivo; quem não a tiver, o `of 104` acima é o número que a métrica compara.
- 2026-08-19 · `I1` · Tempo do `TEST_CMD`: **1m29s** antes, **1m51s** depois — mas a segunda medição rodou com o catálogo de background ocupando 8 cores (`33% cpu` contra `53% cpu`), então o delta está **contaminado** e não vale como evidência. Re-medir só depois que `/tmp/sdd-baseline-score.txt` tiver a linha `score:` (é o fim do run de background que segura os cores), antes de decidir se vira achado do `TODO.md`.
- 2026-08-19 · `I1` · Desvio do plano, declarado: o `sed` do `sdd health` lê os **três** números da linha e o veredito compara `gaps` **antes** de `caught != total`. A ordem inversa (a do plano) tornaria a frase `mutation with an open gap` inalcançável — com gap aberto, `caught < total` sempre —, apagando uma mensagem existente. Ganhou também um ramo novo para a linha que **não parseia**: sem ele, o `sed` que deixasse de casar pularia a comparação inteira em silêncio, que é a mesma vacuidade do ramo "sem linha `score:`".
- 2026-08-19 · `I2` · **Tempo do `TEST_CMD` re-medido limpo, e a nota do I1 fica fechada**: `1m29s` antes do I1, `1m26s` depois do I1+I2 (52% cpu nas duas, sem catálogo em background). O `1m51s` registrado pelo I1 era contaminação dos 8 cores, como aquela nota suspeitava. Duas asserções novas não custaram relógio; nada vai para o `TODO.md` por isso.
- 2026-08-19 · `I2` · O run de background do baseline **morreu** sem imprimir a linha `score:` — `/tmp/sdd-baseline-score.txt` para no meio de `mutants (pool of 8)` e não há processo vivo. A worktree `/tmp/sdd-baseline` (no `9bc65dd`) continua lá para quem quiser retomar. O número que a métrica compara segue sendo o `of 104` derivado do `CATALOG=(`, que não depende de run nenhum.
- 2026-08-19 · `I2` · Desvio do plano, declarado: a checagem 2b lê o `TEST_CMD` do **`$kit/.sdd/config.sh`**, nunca do `$REPO_ROOT`. Três razões que concordam — `sdd health` é o sensor do kit e as outras oito checagens todas leem `$kit`; `--list` é flag da suíte **do kit**; e resolver `$REPO_ROOT` exigiria um repositório git, que nem o fixture do `check-health.sh` nem a sandbox de mutação são, então a checagem morreria onde foi escrita para falar. O que isso **não** cobre virou achado no `TODO.md`.
- 2026-08-19 · `I2` · Desvio do plano, declarado: o mundo sem linter é **construído** (`command -v shellcheck` degradado para `false` via `surface_degrade`) e não encontrado. Envenenar o `$PATH`, que era a letra do plano, foi escrito primeiro e jogado fora: nesta distribuição o `shellcheck` e todo o userland GNU dividem `/usr/bin`, então tirar o diretório de um tira `grep`, `sed` e `comm` do sub-processo — o probe passaria a medir uma suíte que não roda em vez de uma suíte sem linter. O veneno armado é provado em duas pernas: o `cmp -s` do `surface_degrade` e a ausência do passo `^lint: ` na lista degradada.
- 2026-08-19 · `I2` · ⚠️ **Para o I4: `.sdd/` NÃO é gitignored** — o `01-plano.md` § Arquitetura diz que é, e o `.gitignore` ignora só `.sdd/logs/`. O `.sdd/config.sh` é **rastreado** (`git ls-files .sdd/`). Um carimbo escrito em `.sdd/<nome>` entraria no `git status` e sujaria a árvore de toda fase — e fase que morre com a árvore suja faz o runner rederivar EXEC em laço. Escolha o caminho dentro de `.sdd/logs/` ou acrescente a linha ao `.gitignore` no mesmo commit.
- 2026-08-19 · `I2` · Catraca do backlog: um achado novo (a fronteira do que o I2 **não** fecha — `TEST_CMD` de repo-alvo que sai 0 sem rodar), `todo-findings` 72 → 73 no mesmo commit `ca0a360`. Nesse commit também entrou o `RESOLVIDO por` dos itens do I1 e do I2 — o do I1 tinha ficado para trás na sessão que o fechou, e o `00-missao.md` § Fora de escopo manda seguir o cabeçalho escrito do `TODO.md` (item fechado fica até o merge).

## Incrementos de fix (QA)

> Escritos pelo `sdd-qa` quando um bug sanável é reprovado. Entram na mesma tabela acima com ID
> `F<n>`, e o Check obrigatoriamente inclui **regression test passa** + **re-walk da jornada
> impactada verde**. Bug que exige julgamento humano NÃO vira fix — vai para
> "Decisions for a Human" no handoff de QA.
