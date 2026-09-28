# Handoff — a janela do juiz fechou; próxima sessão: veredito, descongelar e tratar os achados do kit

> Escrito em 2026-09-28, ao fechar a sessão que rodou as missões 2 e 3 da janela. Autocontido: uma
> sessão nova, lendo só este arquivo, sabe o estado, a ordem e cada achado.
> Histórico completo da janela: `~/.claude/plans/2026-09-27-handoff-kit-congelado-janela-do-juiz.md`
> (cópia de transporte na branch `handoff/janela-do-juiz` do remoto do kit, lida com `git show`).

## Estado

**A JANELA ESTÁ COMPLETA** (medido em 2026-09-28 10:50): `./bin/sdd kaizen --series` responde
`latest=4fd0f31`, `missions_with_session: 3`, `sessions: 35`, `harness: ["2.1.283"]`,
`sufficient: true`, `why: []`. O veredito pode sair.


- **Kit `sdd_agents`:** `main` = **`4fd0f31`**, árvore limpa, **ainda congelado** até o veredito.
  Nenhum commit na `main` antes do passo 1 abaixo.
- **Harness:** `claude` **2.1.283**, travado por `"DISABLE_AUTOUPDATER": "1"` no `env` do
  `~/.claude/settings.json` (backup de antes da janela: `~/.claude/settings.json.bak-2026-09-27`).
- **As 3 missões da janela, todas sobre `4fd0f31`:**

| # | Alvo | Missão | Jira | PR | Custo | Paradas |
|---|---|---|---|---|---|---|
| 1 | `lighthouse_project` | `20260927-idioma-da-spa-pelo-idp` | LH-4 | #12 (`5da3f65`) | US$ 35,91 | 3, todas humanas |
| 2 | `sales_quote` | `20260927-breadcrumb-numero-cotacao` | SQ-145 | #382 (`3279e722`) | US$ 18,66 | 0 |
| 3 | `sales_quote` | `20260928-ver-vira-olho-na-lista` | SQ-146 | #383 (`3d80ed5b`) | US$ 13,31 | 0 |

## A ordem da próxima sessão (não inverta)

0. **Nada rodando e janela intacta:**
   `ps -eo pid,etime,cmd | grep -E 'bin/sdd (run|retry|close|health|kaizen)' | grep -v grep` vazio;
   `git -C ~/repos/sdd_agents log --oneline -1` → `4fd0f31`, `status --short` vazio; `claude --version`
   → `2.1.283`; `./bin/sdd kaizen --series | jq '{latest: .latest.kit_sha, guard}'` →
   `sufficient: true` com `missions_with_session: 3` e `harness: ["2.1.283"]`.
   O `window_broken: true` não veta (`agents/sdd-kaizen.md:98`); o juiz só cita as 7 missões antigas.
1. **Veredito:** `sdd kaizen` numa branch `kaizen/…` do kit (~US$ 5, teto US$ 15), criada a partir
   de `4fd0f31` (`git -C ~/repos/sdd_agents switch -c kaizen/<nome>`; o `cmd_kaizen` só avisa se
   estiver na base). Ele NÃO lê stdin (`bin/sdd:9399`, só `run_phase KAIZEN`), então pode sair da
   sessão do Claude Code com a receita
   `bash -c 'unset $(compgen -e | grep ^CLAUDE); cd ~/repos/sdd_agents && setsid nohup sdd kaizen > <out> 2>&1 < /dev/null & disown'`.
   ⚠️ Se for do terminal do humano, o `python3` do `PATH` lá é o do hermes, sem `pidfd` (achado 8):
   `PATH="/usr/bin:$PATH" sdd kaizen`.
2. **Descongelar:** o merge da branch `kaizen/…` descongela o kit. Só então tirar o
   `"DISABLE_AUTOUPDATER": "1"` do `~/.claude/settings.json` (o `env` só tem essa chave).
3. **Os achados viram `TODO.md` do kit** (decisão humana de 2026-09-28), um item por achado da
   lista abaixo:
   - formato do `templates/todo.pt-BR.md` (~6 linhas, teto 8, âncora em código, último campo
     `— descoberto por \`<agente>\` na missão \`<slug>\` (AAAA-MM-DD)`), conferidos com
     `bash tests/check-todo.sh`;
   - **antes de escrever, procure duplicata** no `TODO.md` e nas 83 issues `todo`
     (`gh issue list -R j0ruge/sdd_agents -l todo -L 200`): os achados 4 e 5 podem já existir;
   - pela régua D15 do `CLAUDE.md` do kit, entra o que for fail-open ou tiver consumidor fora da
     suíte; os 8 abaixo têm consumidor (as missões de alvo);
   - a catraca `todo-findings` do `sdd health` se move: atualize `tests/health-baseline.txt` no
     mesmo diff;
   - PR → esperar os revisores → consertar numa leva → `sdd health` UMA vez depois do último commit
     de código (~18 min) → merge.
4. **Espelho:** só depois do merge, `/todo-to-github-issues` a partir da `main` do kit.
5. **Tratar:** escolher quais achados viram missão de kit (`/sdd-plan` no kit, interativo). Ordem
   sugerida por dano: 8 → 7 → 6 → 4/5 → 3 → 2 → 1.

## Os 8 achados `kit:` (todos medidos nesta janela)

1. **Célula Commit de incremento fora do git** (missão 1, LH-4). O `templates/checkpoint.md` não diz
   o que vai na célula Commit de um incremento cujo produto não é commit (config no IdP, por
   exemplo), e o `gate_EXEC` exige hash.
2. **`gate_TICKET` só lê o frontmatter** (missão 1). O `agents/sdd-ticket.md:18-19` diz que o
   runner confirma a issue via `acli`, mas o gate só lê o `10-ticket.md`.
3. **O preflight aceita app de outro produto na `APP_URL`** (missão 1). Ele diz "something is
   listening at localhost:5173" e passa com o `sales_quote` na porta do `lighthouse`. Os dois usam
   a `:5173`. Remédio a desenhar: conferir o `<title>` ou um marcador do produto.
4. **O `qa_substep` escolhe `close` com o relatório de OUTRA missão** (missões 1 e 3 — repetiu).
   Ele pula `plan`/`exec` quando o relatório mais recente de `docs/qa/reports/` está `closed`, sem
   perguntar de qual missão é; a Âncora 1 do `gate_QA` aprova com esse relatório. Na SQ-146 o mais
   recente era o da SQ-143; as skills de QA não rodaram e o `sdd-qa` compensou andando a jornada.
5. **A Âncora 3 conta bug legado de outra missão** (missão 1). O agente fica sem saída honesta.
6. **A DOCS contorna pelo Bash a negativa do harness em `.claude/rules/`** (missões 2 e 3 —
   sistemático no `sales_quote`). O harness nega `Edit` em `.claude/` (caminho sensível) na sessão
   headless; o `sdd-docs` declara `.claude/rules/**` no `writes:` e não diz o que fazer com a
   negativa; a sessão escreveu o `.claude/rules/techspec.md` com `python3` pelo Bash (streams
   `DOCS-20260927-190735-f56b8aca` e `DOCS-20260928-091239-822e7bf8`). Na LH-4 a DOCS parou com ⛔ e o
   humano aplicou. O chapéu precisa de UMA regra: ⛔ com texto proposto, ou permissão explícita.
7. **O `sdd close` volta para a `DEFAULT_BRANCH` sem fast-forward** (missão 2). `bin/sdd`, bloco
   antes do `ok "back on '$DEFAULT_BRANCH'…"`: só `git checkout`. A `develop` local fica atrás do
   merge, a árvore parece ter desfeito a missão, e a TICKET seguinte criaria a branch sobre base
   velha. Contorno manual: `git fetch && git merge --ff-only origin/develop` no alvo. ⚠️ Não é
   determinístico: na SQ-146 a própria sessão do close (skill `ticket`) rodou `git pull origin develop`
   e a `develop` ficou em dia; na SQ-145, não. O runner deve fazer o fast-forward ele mesmo, sem
   depender do que a sessão decide.
8. **"Python 3.9+" não basta, e a mensagem não diz a causa** (missão 3). O
   `COORDINATION_PYTHON=(python3 -I -S)` (`bin/sdd:9718`) usa o primeiro `python3` do `PATH`; no
   terminal do humano é `~/.hermes/hermes-agent/venv/bin/python3`, CPython 3.11.15 do `uv`
   (python-build-standalone) com `HAVE_PIDFD_OPEN = None`, sem `os.pidfd_open` — todo comando
   coordenado para com `CHECKOUT-UNAVAILABLE`, embora o kernel e o `/usr/bin/python3` 3.12 aceitem.
   A mensagem (`bin/sdd-coordination.py:433`) lista todos os requisitos, "Python 3.9+" incluído, e
   cola o erro cru no fim. **Sugestão do humano:** dizer a causa explícita — o requisito que falhou,
   o interpretador (`sys.executable`, versão, veio do `PATH`) e o remédio. O `die` genérico em
   `bin/sdd:9754` idem. Remédio a avaliar: sondar candidatos (`/usr/bin/python3`) antes de desistir.

## Fora do kit (não é para a próxima sessão, mas não se perde)

- **Regra nova no `~/.claude/CLAUDE.md` global (2026-09-28):** não usar GitHub Actions em
  repositório privado; verificação local + status de commit `local/ci`; deploy por script/Ansible
  ou workflow inteiro em self-hosted. Motivo: bloqueio de cobrança da org JRC-Brasil em 2026-09-28.
- **`sales_quote`:** `ci.yml` e `runner-watchdog.yml` em `ubuntu-latest`; `cd-staging.yml` e
  `cd-production.yml` com 5 jobs hospedados antes do deploy self-hosted — **sob o bloqueio nenhum
  deploy sai**. Migração a propor ao humano (repo do alvo, não do kit).
- **`sales_quote`:** o `e2e-staging` (self-hosted) está vermelho de verdade em 2026-09-28 12:49Z
  (run 36424316515) — rodou, falhou com exit 1. Investigar à parte.
- **`sales_quote`:** item no `TODO.md` — o teste de alvo de 24px do `sq122` amostra 22px (mesma
  fraqueza que o Codex achou no `sq146`, consertada em `7bea914d`).
- **Billing** da org JRC-Brasil: humano, em Settings → Billing & plans.
