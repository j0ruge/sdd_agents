---
missao: 20260816-portas-do-humano
data: 2026-08-16
---

# Plano — as portas de controle do humano

> **Teste de autocontenção:** uma sessão nova, sem nenhuma memória da conversa que gerou este
> plano, lendo apenas `00-missao.md` + `01-plano.md` + `checkpoint.md`, consegue executar?
> Se a resposta for "só se souber X", **X vai escrito aqui**.

## Contexto verificado (não re-descobrir)

- `gate_PLAN` aceita `auto|humano-*` sem olhar a origem do plano — `bin/sdd:262-266`.
- `frontmatter()` é **read-only** — `bin/sdd:148-168`. Escrever frontmatter exige helper novo.
- `cmd_retry` não chama `warn_if_on_base_branch` — `bin/sdd:1856-1877`. A função está em
  `bin/sdd:1226-1231`; as três chamadas existentes em `:1361` (preflight), `:1667` (cmd_run),
  `:2309` (cmd_kaizen). O comentário "as três portas" a corrigir fica no bloco de `:1209`.
- Nada no runner lê o campo `branch:`; ele só existe em `templates/missao.md:6`.
- Dispatch de comandos: `main()` em `bin/sdd:2433-2449`. `usage()` por volta de `:2360+`.
- Infra de fixture com repo git de brinquedo + stub `claude` já existe em
  `tests/check-gates.sh:506-575` (asserções da base branch) — copiar o padrão, não inventar outro.
- Catálogo de mutação: `tests/check-mutation.sh`; score atual **44 caught, 0 known gap(s), of 44**
  (medido 2026-08-16, `main` pós-PR#4). `sdd health` reprova gate sem mutação no catálogo.
- Suíte = `tests/run-all.sh` (é o `TEST_CMD`; os gates a rodam). Lint cobre `bin/sdd` E `tests/*.sh`.
- `BUDGET_PER_PHASE_USD=25` neste repo — `.sdd/config.sh:24` (subido de 15 em 2026-08-16 após a
  fase REVIEW morrer no teto no meio do artefato).
- Os 4 Checks do checkpoint foram rodados contra o HEAD em 2026-08-16: **todos 0 (vermelhos)**,
  com `tests/check-gates.sh` rc 0 (verde) — nenhum Check nasce verde.
- Marcador kaizen-born verificado: `docs/handoffs/20260816-kit-como-alvo/05-verdict.md` existe;
  o `sdd kaizen` escreve o verdict no mesmo diretório do plano nascido (`agents/sdd-kaizen.md` §6).
- **Armadilhas da casa que mordem NESTES arquivos** (todas já custaram missões):
  - `printf … | grep -q` inverte sob `pipefail` (rc 141 quando ACHA) — use herestring.
  - Comentário `#` dentro de bloco continuado por `\` quebra em silêncio; `bash -n` não acusa.
  - Função com efeito colateral em global é **chamada**, nunca lida via `x="$(f)"` (subshell).
  - O awk desta máquina é mawk, byte-oriented: classe negada só com ASCII; para separador
    literal multibyte use `index()`/`substr()`.
  - Check que lê sensor ancora em `^  ok    ` (stdout); `fail()` escreve o MESMO texto na stderr.
  - Editar `agents/*.md` exige sincronizar `.claude/agents/` **byte-idêntica** (`cmp -s` no
    preflight) — no mesmo commit.

## Arquitetura da mudança

Tudo em `bin/sdd` + sensores em `tests/check-gates.sh` + mutações em `tests/check-mutation.sh`;
prosa em `agents/sdd-planner.md` e `docs/pipeline.md` (I4). Nenhum arquivo novo além dos
artefatos desta missão. Contratos tocados: o enum de `aprovacao:` ganha uma **restrição de
origem** (kaizen-born ⇒ nunca `auto`), imposta no gate; o campo `branch:` do frontmatter passa
de decorativo a **lido pelo runner** (uma definição, `ensure_mission_branch()`, dois call sites).

## Incrementos

A tabela executável vive em `checkpoint.md` (é ela que o runner lê). Aqui fica o **porquê** de
cada fatia — o detalhe que não cabe numa célula.

### I1 — `sdd approve <missão>`: o gate humano ganha comando

**O quê:** `cmd_approve()` + dispatch + `usage`. Imprime `titulo`, a tabela do Gate PLAN-AUTO, os
incrementos (`checkpoint_rows`) e a seção "Pendências para o humano"; pede `[y/N]` no stdin
(`read -r` — **nunca** abre sessão claude: approve não é fase, e as duas exceções deliberadas de
`claude -p` fora de `run_phase()` continuam sendo só preflight e close). `y` ⇒ escreve
`aprovacao: humano-$(date +%F)` e commita **só** `00-missao.md` com
`chore(missao): plano <missão> aprovado pelo humano`. `n` ⇒ nada muda. Já aprovado
(`auto`/`humano-*`) ⇒ no-op com mensagem, sem segundo commit. Artefato faltando ⇒ mesma mensagem
do `gate_PLAN`.
**Onde:** `bin/sdd` (`cmd_approve`, helper `frontmatter_write`, `main()`, `usage`).
**Como (TDD):** primeiro as 3 asserções em `tests/check-gates.sh` (prefixo exato `sdd approve `),
vermelhas; depois o comando. A asserção do valor exige `humano-` **e a ausência** de `auto`
(regra do rc compartilhado: exigir o texto do ramo certo e a ausência do marcador do outro).
**Check:** ver checkpoint (conta `^  ok    sdd approve` → 3).
**Sensor durável:** as 3 asserções + mutação `RUN_approve_writes_auto` (sabotar para escrever
`auto` ⇒ suíte morre) no catálogo.
**Reversível por:** remover `cmd_approve` + entrada do dispatch + asserções (1 commit).
⚠️ `frontmatter_write` opera **só** no bloco entre os dois primeiros `---` — nunca sed no arquivo
inteiro: o corpo pode conter `aprovacao:` em prosa.

### I2 — o runner troca para a branch declarada

**O quê:** `ensure_mission_branch()` — **uma definição** (regra do enum: comportamento lido em
mais de um ponto vira uma definição por programa), chamada por `cmd_run` e `cmd_retry` após
`resolve_mission`, com guarda `[ "$DRY_RUN" = "1" ] && return 0`. Lê
`frontmatter "$MISSION_DIR/00-missao.md" branch`. Casos: vazio ou começando com `<` (placeholder)
⇒ no-op; igual à corrente ⇒ no-op; existe (`git show-ref --verify --quiet refs/heads/<b>`) ⇒
`git checkout <b>`; não existe ⇒ `git checkout -b <b>` a partir da ATUAL (onde o commit do plano
vive — direção do humano registrada no TODO). Falha do git ⇒ `die` com a mensagem dele (Jidoka).
Troca ou criação real ⇒ `pipeline_log_line "... BRANCH <de> -> <para>"` (o guard de dry-run de
`pipeline_log_line` em `bin/sdd:734` já protege o log).
**Onde:** `bin/sdd` (função nova + 2 call sites).
**Como (TDD):** 3 asserções diferenciais primeiro (prefixo `branch `): declarada existente ⇒
`git branch --show-current` do fixture muda para ela; inexistente ⇒ criada a partir da corrente
(conferir com `git merge-base`); placeholder ⇒ corrente intocada.
**Check:** ver checkpoint (conta `^  ok    branch ` → 3).
**Sensor durável:** as 3 asserções + mutação `RUN_branch_switch_dead` (função vira no-op ⇒ suíte
morre).
**Reversível por:** remover função + 2 call sites + asserções (1 commit).

### I3 — `sdd retry` vira a quarta porta com aviso

**O quê:** `warn_if_on_base_branch` no início de `cmd_retry`, como nas outras três portas; e o
comentário "the three doors that commit" (bloco de `bin/sdd:1209`) passa a dizer quatro.
**Onde:** `bin/sdd:1856` (cmd_retry) + o comentário.
**Como (TDD):** 2 asserções diferenciais primeiro (prefixo `retry `): na base ⇒ o aviso sai na
stderr; fora da base ⇒ silêncio (não é aviso que sempre dispara). Espelhar o par existente de
`sdd run` em `tests/check-gates.sh:546-575`.
**Check:** ver checkpoint (conta `^  ok    retry ` → 2).
**Sensor durável:** as 2 asserções + mutação `RETRY_base_branch_warn_dead` (remover a chamada em
`cmd_retry` ⇒ suíte morre). Exceção deliberada à regra "sabote a definição, não o call site": o
defeito real desta fatia É o call site ausente, e a mutação da definição já existe
(`RUN_base_branch_warn_dead`) cobrindo o caminho do run.
**Reversível por:** remover a chamada + asserções (1 commit).

### I4 — plano kaizen-born nunca se auto-aprova

**O quê:** em `gate_PLAN`, `aprovacao: auto` **e** `05-verdict.md` presente em `$MISSION_DIR` ⇒
reprova com `kaizen-born plan requires human approval — run 'sdd approve <missão>'`. Prosa no
**mesmo commit** (contrato em três lugares): `agents/sdd-planner.md` §6 aprende a exceção ("plano
com `05-verdict.md` ao lado nasceu do kaizen: nunca `auto`"), `docs/pipeline.md` §PLAN-AUTO
(~linha 60) idem. Sincronizar `.claude/agents/sdd-planner.md` byte-idêntico.
**Onde:** `bin/sdd:255-278` (gate_PLAN) + os dois markdowns + a cópia instalada.
**Como (TDD):** 3 asserções diferenciais primeiro (prefixo `kaizen-born`): auto+verdict ⇒ gate
reprova **citando kaizen-born** (texto do ramo novo, não só rc); auto sem verdict ⇒ passa;
`humano-*`+verdict ⇒ passa. O par auto-com/auto-sem é a asserção diferencial que nenhum regime
de fixture satisfaz por acidente.
**Check:** ver checkpoint (conta `^  ok    kaizen-born` → 3).
**Sensor durável:** as 3 asserções + mutação `PLAN_kaizen_born_blind` (remover o ramo ⇒ suíte
morre). `gate_PLAN` já está no catálogo; a entrada nova cobre o ramo novo.
**Reversível por:** remover o ramo + prosa + asserções (1 commit).

## Riscos e não-feitos

| Risco | Probabilidade | Mitigação |
|---|---|---|
| `git checkout` com working tree suja falha no meio de `cmd_run` | média | é o desenho: `die` com a mensagem do git (decisão 4 do grill) — nunca stash automático |
| Asserção nova de fixture colide com contagens existentes do `check-gates.sh` | baixa | prefixos de asserção exclusivos (`sdd approve `, `branch `, `retry `, `kaizen-born`); conferir com `grep -c` antes de nomear |
| `frontmatter_write` corromper frontmatter com valor contendo `/` ou `&` (sed) | média | preferir awk com `index()`; probe com valor contendo os dois caracteres |
| Score de mutação diverge de 48 (catálogo mexido por outra missão) | baixa | o Check de cada incremento não fixa o score global; só a métrica final o cita |

## Verificação end-to-end

Com os 4 incrementos `done`: `bash tests/run-all.sh` → `suite green` e
`score: 48 caught, 0 known gap(s), of 48`; `./bin/sdd health` → verde. Jornada real: num clone
de teste, `./bin/sdd approve <missão-fixture>` com `y` deixa `gate_PLAN` verde e cria o commit
`chore(missao)`; `./bin/sdd run <missão-fixture> --dry-run` NÃO troca de branch; sem `--dry-run`
troca/cria conforme o campo `branch:`. Os 4 itens do `TODO.md` (approve sem comando; branch sem
checkout; retry quarta porta; regras conflitantes de `aprovacao:`) ganham `RESOLVIDO por <hash>`.
