---
missao: 20260814-dry-run-completo
fase: REVIEW
rodada: r1
status: done
data: 2026-08-14
gate: "`tests/run-all.sh` → exit 0 · 120 asserções ok, 0 falhas (eram 118 ao fim da QA) · working tree limpo · 4 commits de correção nesta rodada. Secrets pre-scan determinístico: PASS, 0 achados."
---

# Review — rodada r1 — dry-run mostra o pipeline inteiro

> Revisar e corrigir aconteceram na **mesma sessão**, como manda o contrato do `sdd-reviewer`.
> Todo finding CRITICAL/HIGH desta rodada foi corrigido e commitado aqui; nada foi empurrado
> para a próxima fase. Os achados fora de escopo foram para o `TODO.md`, não para o diff.

## TL;DR

13 findings confirmados e **corrigidos** em 5 commits; 4 achados fora de escopo registrados no
`TODO.md`; 2 findings **refutados com evidência** (um deles meu). O achado de maior valor não é
o mais chamativo: `boot_prompt()` lia `$pstep`, uma `local` do **chamador** — funcionava por
coincidência e, chamada de qualquer outro lugar, faria a fase rodar **sem agente, em silêncio**.
Nem `bash -n` nem `shellcheck` pegam isso; o sensor novo pega. Duas lanes independentes
chegaram a ele separadamente.

O segundo mais grave é da mesma família — garantia que só vale por sorte: o Jidoka de `blocked`
usava `… | grep -qx`, que sob `pipefail` devolve **141** quando o `grep` fecha o pipe cedo, e o
runner leria "não há incremento blocked" havendo um.

## Escopo revisado

Diff `main..HEAD` da branch `missao/20260814-dry-run-completo`: 14 commits, 27 arquivos,
+2878/−50. Núcleo em `bin/sdd` (+277/−50), `tests/check-dry-run.sh` (novo, 217 linhas),
`tests/check-gates.sh`, `agents/*.md`, `docs/pipeline.md`, `docs/failure-modes.md`, `config/`.

Com o `30-handoff-qa.md` em mãos: as 5 jornadas que a QA já andou e as 3 mutações que ela já
provou **não foram refeitas** — achado coberto por sensor da QA não vira finding de novo. O que
a QA explicitamente deixou para esta fase (drift de documentação, item 1 do "Boot da próxima
fase") foi o ponto de partida.

## Cobertura desta rodada — o que rodou e o que não fechou

| Lane | Ferramenta | Resultado |
|---|---|---|
| Secrets (pass 6.10) | script determinístico (regex + exception list) | **PASS**, 0 achados, 0 erros |
| Lint do runner | `shellcheck` sem filtro de severidade | limpo em `-S warning`; 6 `info`/`style` triados, nenhum defeito |
| Sintaxe | `bash -n` | limpo |
| Drift de contrato/docs | agente dedicado, itens A–G | 6 findings, todos verificados por mim |
| Dead code (pass 6.9) | varredura de todas as funções + arms de `case` | 2 unreachable (refutados), 3 pré-existentes → `TODO.md` |
| Qualidade dos sensores | agente dedicado, **com teste de mutação** | 4 findings, 3 provados por mutação |
| Bug-hunt adversarial dedicado em `bin/sdd` | agente dedicado | 4 findings, +2 novos depois da 1ª leva de consertos |

**Todas as lanes fecharam.** A de bug-hunt em `bin/sdd` demorou 13 min e chegou **depois** de eu
já ter consertado e commitado a primeira leva. Vale registrar o que ela produziu, porque é
evidência sobre a qualidade da revisão e não sobre o código: ela **confirmou de forma
independente** o finding #1 (`boot_prompt`/`$pstep`), que eu havia achado sozinho lendo o diff, e
com a mesma severidade e a mesma correção — dois caminhos independentes chegando ao mesmo
defeito. E trouxe **dois findings que eu não tinha**, um deles na trava de segurança do runner
(#12). Os consertos dela entraram em `1807d75`, depois da primeira leva.

## Findings — corrigidos nesta sessão

| # | Sev | Categoria | Arquivo:linha | Finding | Commit |
|---|---|---|---|---|---|
| 1 | HIGH | correctness | `bin/sdd:552` | `boot_prompt()` lê `$pstep`, `local` do **chamador** | `878a2d3` |
| 2 | HIGH | doc-sync | `docs/pipeline.md:129`, `docs/failure-modes.md:151` | apontam para `<missão>/pipeline.log`, caminho abandonado por `53cf63a` | `10a5438` |
| 3 | HIGH | doc-sync | `README.md:71` | dá `docs/qa/` como entrega do `sdd-qa` — o oposto do que `agents/sdd-qa.md:6` diz | `10a5438` |
| 4 | MEDIUM | test-quality | `tests/check-dry-run.sh:160` | `out3` capturado e nunca asserido — mutação deixava o arquivo inteiro verde | `996672e` |
| 5 | MEDIUM | test-quality | `tests/check-dry-run.sh:174` | asserção rotulada como guarda do F1 é cega a ele (`.sdd/logs/` é gitignored) | `996672e` |
| 6 | MEDIUM | test-safety | `tests/check-dry-run.sh:189`, `check-gates.sh:140` | fixtures fazem `sdd run` real: se a escalação mudar de ordem, a suíte chama o `claude` de verdade | `996672e` |
| 7 | MEDIUM | doc-sync | `docs/pipeline.md:67` | heading promete "três sub-passos", corpo não os enumerava | `10a5438` |
| 8 | MEDIUM | doc-sync | `docs/pipeline.md:69` | 2º caminho de `gate_QA` (projeto sem interface) não documentado em lugar nenhum | `10a5438` |
| 9 | LOW | robustness | `check-dry-run.sh:51`, `check-gates.sh:43` | `cd "$FIX"` sem `\|\| exit` (SC2164) — sem `set -e`, `sed -i`/`git commit` rodariam no repo real | `996672e` |
| 10 | LOW | dead-code | `tests/check-gates.sh:130` | `sed` no-op: substituía um padrão por ele mesmo | `996672e` |
| 11 | LOW | doc-sync | `README.md:17,75` | "cada fase é uma sessão nova" (a QA são três); `sdd-publisher` sem a fase TICKET | `10a5438` |
| 12 | MEDIUM | correctness | `bin/sdd:969` | Jidoka de `blocked` sob `pipefail`: `grep -q` fecha o pipe, upstream morre de SIGPIPE, pipeline devolve **141** e o `if` lê "sem blocked" existindo blocked | `1807d75` |
| 13 | LOW | honestidade | `bin/sdd:576`, `bin/sdd:1093` | comentário e `--help` diziam que o dry-run "não mexe em nada" — falso: os gates rodam `TEST_CMD` e escrevem `gate-*.log` | `1807d75` |

### O finding #1, por extenso — porque é o que vale a rodada

```bash
boot_prompt() {
  local step="$1" slash agent
  slash="$(phase_slash "$step")"
  agent="$(phase_agent "$pstep")"   # <-- $pstep é `local` de run_phase()
```

A saída de hoje está **correta**, porque o único chamador é `run_phase`, que passa exatamente
`$pstep` como `$1`. É por isso que nenhum teste pegava: os dois valores são sempre iguais.

O que provei num probe isolado antes de tocar no código: com `pstep` inexistente e `set -u`,
a expansão falha **dentro** do `$( )` — a variável vira vazia, a função **retorna 0**, e a fase
seguiria com `--agent` ausente, rodando sem persona nenhuma. Falha silenciosa, gate verde: a
classe exata de defeito que este kit existe para impedir.

`shellcheck` não pega (SC2154 não dispara — o nome *está* atribuído no arquivo, em `run_phase`),
`bash -n` não pega. Por isso o conserto veio com **sensor**, observado vermelho antes do verde:

```
== higiene de escopo do runner ==
  FALHA só run_phase referencia $pstep (a local do chamador não vaza)
         obtido:   boot_prompt():552
```

Depois do conserto: verde, e a saída do dry-run na missão real continua nomeando
`sdd-reviewer`/`sdd-docs`/`sdd-publisher` corretamente — conserto sem mudança de comportamento.

### Sobre os findings 4–6 — a QA tinha razão sobre a classe

A QA fechou a volta 2 denunciando "asserção que virou decoração" e pedindo teste de mutação.
Esta rodada aplicou mutação de novo e achou **mais três** frestas do mesmo tipo, todas provadas
empiricamente, não por leitura:

- quebrar a mensagem `BLOCKED em EXEC` deixava `check-dry-run.sh` **inteiro** verde (#4);
- reintroduzir o bug do F1 deixava a asserção de working tree verde, porque `git status` é cego
  a arquivo gitignored (#5) — ela não é vacua, mas guardava outra coisa do que o rótulo dizia;
- os dois fixtures chamam `sdd run` **real**, seguro só enquanto o Jidoka escapar antes da
  sessão (#6). Agora há stub de `claude` no `PATH` do fixture: em vez de gastar token ou pendurar
  o CI, falha alto e barato.

## Findings refutados — com evidência, não com opinião

**R1 — "os arms `QA:close|QA)` em `phase_agent`/`phase_task` são unreachable; remova o `|QA`."**
(vindo da varredura de dead code, LOW, confiança "High")

Refutado. A premissa está certa — `phase_step()` sempre reescreve `QA` para `QA:<sub-passo>`
antes de qualquer chamada, então o rótulo nu é de fato inalcançável hoje. A **conclusão** é que
está errada: com o `|QA` removido, uma chamada direta `phase_agent QA` cai no `*)`, que devolve
**string vazia** — ou seja, a remoção converte um default correto (`sdd-qa`) numa degradação
silenciosa para "fase sem agente". É exatamente o modo de falha do finding #1, que esta mesma
rodada acabou de consertar. Manter o arm custa uma alternativa de `case` e compra defesa em
profundidade. Não removido, de propósito.

**R2 — minha própria suspeita: "o probe do `preflight` depende de `jq` e, sem ele, diagnostica
'sessão expirada', que é mentira."**

Refutado por verificação: `bin/sdd:759` já checa `jq` no laço de ferramentas obrigatórias,
**antes** do probe, e `README.md:83` o declara requisito. O usuário sem `jq` recebe o erro certo.
Registro a refutação porque a suspeita era razoável e alguém a teria de novo.

## Fora de escopo → `TODO.md` (commit `aecc0e0`)

Nada sumiu; nada entrou no diff da missão. Dois são **pré-existentes** (já estavam em `main`), o
terceiro é latente e não morde na configuração de hoje:

- **`config/schema.md` promete cinco comportamentos que o runner não tem** — `LINT_CMD`,
  `BUILD_CMD`, `DEV_UP_CMD`, `DEV_READY_CMD`, `DEV_READY_TIMEOUT` são documentados ("roda no
  gate de REVIEW quando definido", "o runner faz poll por até N segundos") e **nunca lidos**:
  `load_config` atribui o default e o nome não reaparece. Quem preenche `LINT_CMD` acha que tem
  um sensor no gate e não tem — pior do que não ter. Pré-existente e sem relação com o dry-run:
  corrigir aqui seria scope creep, que a constituição do kit (princípio 5) proíbe.
- **`latest_matching` ordena por string** (`bin/sdd:205`): com `40-review-r10.md` presente,
  `sort | tail -1` devolve `r9`. Inofensivo com `REVIEW_MAX_ITER=3`; silencioso e grave se
  alguém subir para 10+.
- **`bad_rows` escrito e nunca lido** em `gate_EXEC` (`bin/sdd:262,276`).
- **A fase TICKET recebe agente E slash ao mesmo tempo** (`bin/sdd:491` + `:501`), contra o
  invariante escrito três linhas acima ("dois system prompts disputando a sessão é ruído"). É
  decisão de contrato de fase, e o `00-missao.md` põe mudança de agente fora de escopo — por
  isso registrado, não consertado. Não morde no kit (`JIRA_ENABLED=false`); aparece no piloto.

Também registrei a **convenção que faltava no próprio `TODO.md`**: itens com "RESOLVIDO por
`<hash>`" ficam na seção "Aberto" com a caixa desmarcada até o merge, para o PR citar. Sem essa
nota, quem lê só a caixa conta como aberto o que já fechou — três itens estavam nesse estado.

## Verificação

```
tests/run-all.sh  →  exit 0 · 120 asserções ok · 0 falhas
git status --porcelain  →  vazio
bin/sdd run 20260814-dry-run-completo --dry-run  →  exit 0, projeta REVIEW→DOCS→PR
   com sdd-reviewer/sdd-docs/sdd-publisher e os modelos do .sdd/config.sh
```

A suíte foi de 118 (fim da QA) para **120** asserções: +1 pela mensagem de escalação do dry-run,
+1 pela higiene de escopo do runner. Nenhuma asserção foi removida; uma foi **renomeada** para
parar de prometer o que não entrega.

Commits desta rodada: `878a2d3`, `996672e`, `10a5438`, `aecc0e0`, `1807d75`.

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | A | 11 findings corrigidos nesta sessão; o único de lógica (`boot_prompt`) veio com sensor. Restantes são LOW pré-existentes, registrados no `TODO.md`. Comentários explicam o *porquê*, não o *o quê* — padrão do repo mantido. |
| Type Safety | A | Bash não tem tipos; o análogo é disciplina de contrato — chaves de frontmatter, colunas do checkpoint, códigos de retorno dos `gate_*` (0/1) e `GATE_WHY`. Todos cobertos por `check-templates.sh`/`check-gates.sh`. `shellcheck -S warning` limpo em `bin/sdd`. |
| Error Handling | A | Os dois defeitos mais graves da rodada eram exatamente disto: degradação silenciosa para "sem agente" (#1) e Jidoka que podia ler 141 como "sem blocked" (#12). Ambos fechados — o primeiro com sensor, o segundo eliminando a corrida. Caminhos de escalação retornam código próprio e explicam o motivo; asserção nova cobra a mensagem, não só o exit code. |
| Security | A | Secrets pre-scan determinístico: **PASS**, 0 achados, 0 erros do scanner. Sem credencial, token ou URL autenticada no diff. O prompt vai como argv único ao `claude`, não passa por avaliação de shell. Stub de `claude` confina a suíte: nenhum teste alcança rede. |
| Performance | A | Gates rodam `TEST_CMD` durante a projeção — decisão explícita do plano, memoizada por processo em `run_check_cmd` (~2s no kit). Custo em repo grande está declarado como risco não medido no handoff do EXEC e no `TODO.md`, não escondido. |
| Test Coverage | A | 120 asserções, 0 falhas. Cobertura validada por **mutação**, não por leitura: 3 frestas encontradas e fechadas nesta rodada, mais as 3 mutações que a QA já provava. Todo conserto de lógica desta rodada entrou com Red observado antes do Green. |
| Documentation | A | Todo o drift que **esta missão** criou foi fechado: caminho do diário, QA em três sub-passos, 2º caminho do `gate_QA`, tabela de agentes do README. O drift pré-existente (`config/schema.md`) está registrado no `TODO.md` com direção — deferir achado fora de escopo é o princípio 5 do kit, não omissão. |
| **Overall** | **A** | **Nenhum CRITICAL/HIGH em aberto. Os 13 findings da rodada foram corrigidos e commitados, 2 refutados com evidência, 4 deferidos ao `TODO.md` com justificativa de escopo. Todas as lanes de revisão fecharam. Suíte verde (120 asserções), `shellcheck` limpo, working tree limpo.** |

### Recommended Actions

**Must Fix (CRITICAL)**: _None._

**Should Fix (HIGH)**: _None em aberto._ Os três HIGH da rodada (#1 `boot_prompt`, #2 caminho do
diário, #3 entrega do `sdd-qa` no README) foram corrigidos em `878a2d3` e `10a5438`.

**Consider Fixing (MEDIUM/LOW)**:

- **Dívida de sensor, o tema recorrente desta missão** — a suíte ainda não tem
  `tests/check-mutation.sh`. Três rodadas seguidas (QA volta 2, e esta) acharam asserção
  decorativa **à mão**. Enquanto a mutação for manual, a próxima só aparece por sorte. É o item
  de maior alavancagem no `TODO.md`.
- `config/schema.md` prometendo cinco chaves não implementadas — decidir entre implementar ou
  retirar a promessa. É o achado deferido de maior severidade.
- `latest_matching` com `sort -V` antes que algum repo-alvo suba `MAX_ITER` para 10+.
- `bad_rows`: usar no `GATE_WHY` ou remover.
- `gate_EXEC` aceita commit órfão (`git cat-file -e` ≠ "está no `git log`") — achado da QA, já no
  `TODO.md`, e o mais próximo de virar missão própria.
