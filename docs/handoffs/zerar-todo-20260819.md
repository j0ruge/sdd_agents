# Handoff — o backlog do kit, para a próxima missão

> Escrito em 2026-08-19, ao fim da missão `20260818-lote-facil`, com o humano presente.
> Sucessor de [`lote-facil-20260817.md`](lote-facil-20260817.md), que é a triagem anterior e
> continua valendo como método.

## Estado do repo, medido agora

| | |
|---|---|
| `main` | `5da0109` |
| `sdd health` | **`kit healthy`**, rc 0, em 318 s |
| suíte rápida (`TEST_CMD`) | `suite green`, rc 0, **46 s** |
| catálogo de mutação | **`104 caught, 0 known gap(s), of 104`** |
| PRs abertos | nenhum (#12 e #13 mergeados) |
| `TODO.md` | **72 achados abertos**, catraca em `todo-findings 72` |

Duas mudanças da última missão alteram como a próxima trabalha:

1. **A mutação saiu do `TEST_CMD`.** Os gates rodam a suíte rápida (46 s); o catálogo inteiro só
   roda em `tests/run-all.sh --with-mutation`, que é o que o `sdd health` chama. Isso é o que
   tornou a fase REVIEW satisfazível headless — antes ela morria esperando a suíte.
2. **O `agents/sdd-reviewer.md` aprendeu três coisas** (`b36f8e2`): quando parar o laço (platô ou
   regressão contra a tabela da rodada anterior, nunca contagem de rodadas), nunca encerrar o turno
   com comando rodando, e commitar cada conserto ao verificar.

## ⚠️ Antes de planejar: "zerar o TODO" não é meta de uma missão

Isto não é pessimismo, é a medição da missão que acabou:

- ela prometeu `56 → 38` e entregou os **18 achados que prometeu**, todos;
- o arquivo terminou em **72**, porque os instrumentos da própria missão acharam 36 coisas novas —
  **29 delas numa única rodada de revisão**;
- custo: **US$ 230,45**.

O backlog deste repo **cresce quando se trabalha nele**, e cresce mais rápido do que se fecha
enquanto os sensores estiverem ficando melhores. Alvo escrito como número absoluto (`72 → 0`) é
frágil por construção e vai falhar do mesmo jeito que o `56 → 38` falhou.

**Formas de meta que sobrevivem à medição**, em vez de "zerar":

- **por família**: "a família do `check-todo.sh` sai inteira" — verificável, e o custo por item cai
  porque fechar 5 da mesma família custa quase o mesmo que fechar 1;
- **por propriedade**: "nenhum sensor do kit afirma ter medido o que não mediu" — a classe que
  aparece em 3 de cada 4 achados abertos;
- **por saldo declarado**: "fechar 20, aceitar que nasçam N, e a catraca registra os dois números".

## A triagem, por mecanismo

Agrupada por **mecanismo e não por arquivo** — foi essa a alavanca de custo comprovada na missão
anterior. Os números entre parênteses são contagens de achados.

### Bloqueia todo o resto — fazer primeiro (1)

- **22 das 33 âncoras do `TODO.md` apontam para a linha errada** (§ Comentário e registro).
  Enquanto isso não for consertado, **todo item é suspeito**: a missão passada mediu 8 de 18
  âncoras podres no planejamento e mais 5 podres de novo no I4, quebradas pela própria missão.
  Re-derivar as 33 é barato, mecânico, e torna todo o resto planejável.

### Famílias grandes de sensor (≈25)

| família | itens | forma |
|---|---|---|
| `check-todo.sh` | 6 | regras que o selftest diz medir e não mede; duas formas bem formadas recusadas; `tail_of` aceita qualquer par de crases; ramo de lista ordenada sem probe |
| `check-health.sh` | 4 | quatro regras sobrevivem à passada adversarial; o `guard:` reprova código correto em três formas e é cego a helper fora da região; `stub-argv.txt` nunca apagado |
| catálogo de mutação | 5 | `sdd health` diz `ok` sobre catálogo com sobrevivente; duas mutações com `sed` sem endereço sabotam um segundo sítio calado; `check-templates.sh` sem auto-teste **e** fora do alcance; sensor pulado por `SDD_MUTANT` vira ponto cego |
| CDPATH / `ledger_repo_root` | 4 | `pushd "$(…)"` tem o mesmo bug e não é medido; braço 1 da guarda de forma sem probe; piso do shim prova o shim, não a consulta; `cdpath:` não vê `cd --` |
| runner e gates | ~6 | árvore suja rederiva EXEC **para sempre** (mordeu 2× nesta missão); parser do checkpoint não conhece `\|`; `gate_REVIEW` lê só a coluna `Grade`; `frontmatter_write` confia em três coisas |

### Decisão humana antes de qualquer código (≈10, § Contrato e configuração)

Nenhuma delas é trabalho de agente até você decidir. Estão em `TODO.md` com a direção:

- as **5 chaves fantasma** do `config/schema.md` (`LINT_CMD`, `BUILD_CMD`, `DEV_UP_CMD`,
  `DEV_READY_CMD`, `DEV_READY_TIMEOUT`) — o schema promete comportamento que o runner não tem;
- **`E2E_DIR`** — default no runner, lida só pelo agente;
- **`CHANGELOG.md`** — não existe, e a fase DOCS cobra um;
- **a fase TICKET** recebe agente **e** slash ao mesmo tempo;
- **o contrato PT-BR em 5 pontos** (`aprovacao`, `versao`, `titulo`, `00-missao.md`, `01-plano.md`)
  — renomear quebra missão em voo;
- **`templates/` single-language**;
- **`BUDGET_PER_PHASE_USD` global** enquanto o custo por fase não é (REVIEW ~US$ 34, PR ~US$ 3);
- **o ciclo de vida do `RESOLVIDO por` × a catraca** — não cabem juntos hoje;
- **`REVIEW_MAX_ITER`** conta por invocação de `sdd run`, não "in total" como o schema promete.

### Custo e escala (2) — e agora com um caso medido atrás

- **O alvo "<30 s" da D7.** Hoje: `TEST_CMD` em 46 s, catálogo completo em ~310 s. A decisão
  (subir o alvo, aposentá-lo, ou rodar por mutante só o sensor que o alcança) segue sua.
- **Sensor novo é multiplicador, não parcela** — custa uma vez por mutante, hoje 104.

### Investigação de verdade (3) — não são consertos

`check-autonomy.sh` vermelho intermitente (não reproduziu em 152 runs); preflight que prove
execução de `TEST_CMD` headless; `check-todo.sh` re-derivar âncoras semanticamente.

### Adiados por YAGNI (3)

São decisões de **não fazer**, não dívida. Não entram em missão.

## A lacuna que a última missão abriu, e que já cobrou

**Sem CI neste repo, o catálogo de mutação só roda quando alguém digita `sdd health`.** Isso não é
hipótese: aconteceu entre os PRs #12 e #13. Um conserto da rodada r3 (`f6ecf73`) trocou `if` por
`elif` e apodreceu a âncora de `mut_HEALTH_grade_table_blind`; os gates de REVIEW e PR rodam o
`TEST_CMD` rápido, passaram verdes, e a `main` recebeu `score: 103 caught of 104`. O #13 consertou.

**Isto é forte candidato a primeiro incremento da próxima missão**, porque protege todas as outras:
CI rodando `tests/run-all.sh --with-mutation`, ou o `gate_PR` chamando `sdd health` uma vez por
missão.

## Armadilhas que não devem ser reaprendidas

Todas custaram sessão ou dinheiro nesta missão. As genéricas estão no `CLAUDE.md`; estas são as que
a próxima sessão encontra primeiro:

1. **Probe que não prova ter sabotado o que dizia sabotar conclui em falso.** Aconteceu 11 vezes no
   I2, 4 no I5 (por `awk -v` processar escapes), e comigo (caixa sem `CLAUDE.md`/`TODO.md`, que o
   `sandbox()` real copia). Ancore em CÓDIGO e faça o probe **morrer alto** quando o trecho não mudou.
2. **`&` numa substituição de `sed` é "todo o trecho casado".** Produziu um mutante-lixo que era
   bash válido, matava a asserção e teria entrado no catálogo. Escape: `2>\&1`.
3. **`check-health.sh` roda com `SDD_MUTANT=1` dentro dos mutantes.** Probe sobre a composição da
   suíte precisa de `env -u SDD_MUTANT`, ou reprova em todo mutante e mata o controle.
4. **Fase que morre com a árvore suja faz o runner reentrar no EXEC em laço**, sem teto
   (`--max-phases` é 0 por padrão). Mordeu 2× nesta missão. Pare na segunda volta.
5. **Sessão headless que encerra o turno esperando um comando morre.** Três rodadas de REVIEW,
   US$ 104, nenhuma revisão entregue. Já está gravado no `agents/sdd-reviewer.md`.

## Primeiros comandos da próxima sessão

```bash
cd /home/joruge/repos/sdd_agents && git checkout main && git pull
./bin/sdd health                 # ~320 s — confirma o chão antes de planejar
sdd kaizen                       # veredito da missão anterior + plano da próxima
```

⚠️ O runner deixou pendente: `1 mission(s) on kit ce76188 without a verdict`. O `sdd kaizen` é o
caminho previsto para dar o veredito **e** gerar o plano da missão seguinte — vale rodá-lo antes de
planejar à mão.

Para planejar à mão, o fluxo é o mesmo da missão passada: `sdd-planner` interativo produzindo
`00-missao.md` + `01-plano.md` + `checkpoint.md` em `docs/handoffs/<slug>/`, depois
`sdd approve <slug>` (**precisa de TTY** — `! echo y | ./bin/sdd approve <slug>` funciona daqui),
depois `sdd run <slug>`.

## Higiene, se quiser

Há **13 branches locais** de missões já mergeadas (`chore/*`, `missao/*`, `docs/*`,
`fix/mutation-anchor-grade-table`). Não foram tocadas.
