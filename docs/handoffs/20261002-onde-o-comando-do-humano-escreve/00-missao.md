---
missao: 20261002-onde-o-comando-do-humano-escreve
titulo: o comando do humano escreve onde o plano manda — o approve leva o plano inteiro para a branch da missão, o close volta à base sem Jira, nenhum escritor atravessa symlink, e a suíte tem prazo e não reprova pelo ambiente de quem a chama
data: 2026-10-02
versao: n/a (JIRA_ENABLED=false)
branch: feat/onde-o-comando-do-humano-escreve
aprovacao: auto
adr: none
ddd: n/a
---

# Missão — Onde o comando do humano escreve

> Escrito pelo `sdd-planner` com o humano presente (via a sessão coordenadora, duas rodadas de
> grill em 2026-10-02). É a única fonte da **intenção**; o `01-plano.md` é a fonte do **como**.
> Toda sessão headless começa lendo estes dois.

## Problema (Gemba)

Os comandos que o humano roda no começo e no fim de toda missão escrevem no lugar errado, ou
deixam estado onde não deviam. E a suíte que todos os gates rodam reprova ou trava por causa do
ambiente de quem a chama, não por causa do código. Tudo abaixo foi reproduzido em 2026-10-02 sobre
`5e75fdc`, num repo de rascunho com `SDD_STATE_DIR` isolado, e não é suposto:

1. **#156 — `sdd approve` commita na branch padrão, e só o `00-missao.md`.** Na `main`, com
   `JIRA_ENABLED=false` e `branch: feat/x`, `echo y | sdd approve` gerou o commit
   `chore(missao): plan … approved by the human` **na `main`**, com 1 arquivo. `01-plano.md`,
   `checkpoint.md` e `checkpoint-notas.md` ficaram `??`. Código: `cmd_approve` (`bin/sdd:7339`), o
   commit com `-- "$rel"` está em `:7456-7461`. Reincidiu no `sales_quote` em 2026-09-30, quando o
   `gate_REVIEW` recusou `working tree dirty` até alguém commitar o plano à mão. A asserção atual
   `sdd approve commits only 00-missao.md, and approving twice makes no second commit`
   (`tests/check-gates.sh:3136`) **codifica o defeito**.
2. **#182 — `sdd close` sem JIRA não volta à base.** Em `feat/x`, `sdd close` respondeu
   `JIRA_ENABLED=false — nothing to close`, rc 0, e continuou em `feat/x`. O retorno antecipado
   está em `bin/sdd:10599`, antes de `close_return_home` (`:10539`), que só o ramo JIRA alcança. No
   fechamento do PR #176 a volta à `main` foi feita à mão.
3. **#193 — `checkpoint_note_intervention` vaza um arquivo vazio em `/tmp` a cada nota.** O
   `mktemp` (`bin/sdd:455`) roda antes do `if`, e o ramo de append em `checkpoint-notas.md` (o de
   toda missão nova) nunca o usa nem o apaga. Medido hoje: três suítes deixaram três
   `/tmp/sdd-ck-*` vazios (09:39, 09:43, 09:47), um por execução. Em 2026-10-01 foram apagados
   13 713. **Inferido do código** (o mecanismo foi conferido num `bash -c` com `set -euo pipefail`):
   com `TMPDIR` inacessível, o `mktemp` mata o comando antes de a nota ser escrita, no ramo que nem
   precisa dele.
4. **#81 — `frontmatter_write` confia em três coisas que não valem sempre** (`bin/sdd:376`).
   - Com `00-missao.md` como symlink, o approve trocou o link por arquivo comum, o alvo real ficou
     com `aprovacao:` vazio e o commit levou a troca de tipo.
   - O `chmod --reference … 2>/dev/null || true` (`:399`) engole a falha e deixa o artefato 0600
     em userland sem `--reference`.
   - `awk -v v="$value"` interpreta escapes de barra invertida.
   - São **dois** chamadores, e não um como diz o `TODO.md`: `cmd_approve` (`:7444`) e `adr_declare`
     (`:6949`). Este último recebe o caminho já resolvido por `readlink -f` (`adr_spec_relative`),
     então o symlink só alcança o approve.
5. **#173 — `sdd install --force` escreve através de symlink.** Com `.claude/agents/sdd-qa.md`
   ligado a um arquivo de fora, `install --force` respondeu `updated (--force)`, o link continuou
   link e o **destino** foi sobrescrito com o conteúdo do kit. O `cp` está em `bin/sdd:5082`. Um
   link quebrado cai no ramo `[ ! -f "$target" ]`, e o `cp` cria o arquivo no destino do link.
6. **#186 — a suíte reprova dentro de sessão REVIEW.** Com
   `GIT_REFLOG_ACTION=sdd:REVIEW:deadbeef`, `tests/run-all.sh` deu rc 1 num único passo
   (`autonomy ledger`), com `expected trips:2 … got trips:4`. Os `git checkout` de
   `foreign_elsewhere` (`tests/check-autonomy.sh:6465`) herdam o rótulo de quem chama. O gate
   passa porque o runner não carrega o rótulo; quem paga é a sessão de REVIEW, que vê vermelho.
7. **#157 — `check-coordination.sh` reprova quando nasce com SIGINT ignorado.**
   `bash -c 'tests/check-coordination.sh & wait $!'` (filho com `SigIgn 0x6`) deu rc 1. O SIGTERM
   passa (`signal status: 15`), e o SIGINT estoura `subprocess.TimeoutExpired … after 8 seconds`,
   com traceback e sem linha FAIL. O `start()` do probe está em `tests/check-coordination.sh:202`,
   e o laço de sinais em `:789`.
8. **#112 — a suíte não tem `timeout` em lugar nenhum.** `run()` (`tests/run-all.sh:101`) roda cada
   passo sem prazo, e uma regra quebrada que recursa vira travamento sem mensagem. Achado de desenho
   ao medir: o catálogo de mutação conta como **pego** todo rc diferente de 0, 90, 91 e 99
   (`tests/check-mutation.sh:5723-5745`). Um timeout ingênuo dentro do mutante seria lido como
   morte (fail-open), e hoje um mutante que trava deixa o `sdd health` travado para sempre.

**Cinco porquês (a raiz é de processo, a mesma nos itens 1, 2 e 3).**
1. O approve commita na base. Por quê?
2. Porque nasceu (`96a1f68`, 2026-08-16) escrevendo onde o humano estivesse, e a regra "o runner
   entra na branch declarada" (`b3b8c2f`, mesmo dia) foi ligada só ao `run` e ao `retry`. Por quê?
3. Porque cada regra de "onde escrever" foi aplicada à porta que a motivou. A volta à base
   (`147add7`, 2026-09-22) chegou só ao ramo JIRA do close, e o append em `checkpoint-notas.md`
   chegou sem tirar o `mktemp` do caminho antigo.
4. Contramedida: **as portas irmãs passam a chamar a mesma definição**, `ensure_mission_branch` no
   approve e `close_return_home` nos dois ramos do close, e cada porta ganha probe e mutante.

## Métrica

Fatos binários, cada um com sensor durável em `tests/run-all.sh` e asserção nomeada (os nomes
exatos estão nos Checks do `checkpoint.md`):

1. **A suíte não reprova pelo ambiente de quem a chama.**
   - Com um rótulo de sessão REVIEW herdado, `check-autonomy.sh` fica verde.
   - Lançado com SIGINT ignorado, `check-coordination.sh` responde `signal status: 2`.
   - Os dois sensores **armam o veneno sozinhos** em toda execução, com um piso provando que o
     veneno está armado.
2. **Nota de intervenção não deixa temporário.** Com um `TMPDIR` privado, 0 `sdd-ck-*` depois de
   uma nota; com `TMPDIR` inacessível, o ramo de `checkpoint-notas.md` ainda escreve e commita.
3. **O close sem JIRA volta à base**, e recusa PR que não está MERGED.
4. **Nenhum escritor atravessa symlink.**
   - O approve sobre um `00-missao.md` ligado morre sem escrever nem commitar.
   - O `install --force` deixa o destino do link byte a byte intacto, link quebrado incluído.
5. **O approve leva o plano para a branch declarada.**
   - Na base, com `branch:` real, o commit da aprovação cai na branch da missão e leva o diretório
     da missão inteiro, mais o arquivo do `adr:` quando é caminho, e nada além disso.
   - Branch existente com outro plano: recusa depois do `y`, sem escrever nada.
   - `branch:` placeholder: avisa, fica e commita o diretório.
6. **Nenhum passo da suíte roda sem prazo.**
   - Passo estourado: vermelho nomeado ("timed out after N s"), e a suíte segue.
   - Dentro de mutante: rc 124, que o catálogo lê como **inconclusivo** (erro nomeado), nunca como
     pego.
   - O Ctrl-C do humano continua parando a suíte.
7. Todo mutante novo é pego, `tests/check-mutation.sh --anchors` segue verde, e o `sdd health` final
   carimba N de N.

## Resultado esperado

Ao aprovar um plano, o humano passa a cair na branch que o plano declara, com o plano inteiro
commitado lá. A base não ganha commit de missão, e nenhum arquivo do plano fica para trás. Ao
fechar uma missão sem Jira, o humano volta à base atualizada, como já acontecia com Jira. Nenhum
comando do kit escreve através de um link que o humano montou. A suíte (o `TEST_CMD` de todo gate)
passa a dizer "o passo X estourou N s" em vez de travar, e deixa de reprovar quando é chamada de
dentro de uma sessão REVIEW ou de um lançamento destacado. O catálogo de mutação nunca confunde
estouro com morte.

## Fora de escopo

- **#187** (`sdd status` preso 2 min segurando a trava): a causa não foi diagnosticada e não há
  reprodução. Fica no `TODO.md`.
- **O mesmo `chmod --reference … || true` em `adr_declare`** (`bin/sdd:~6962` e `~6981`): é o
  yokoten da #81 fora do `frontmatter_write`. O symlink não alcança esse escritor (caminho resolvido
  por `readlink -f`). Vira **achado novo no `TODO.md`** no I10, com a catraca +1 no mesmo commit.
- **Um prazo por mutante no catálogo**, além do prazo por passo que cada mutante herda: não é pedido
  por nenhuma das oito issues.
- **Prazo no `run_check_cmd`** (o runner rodando `TEST_CMD`): a suíte ganha prazo por dentro, e um
  `TEST_CMD` de alvo é decisão daquele repo.
- **Fase DOCS:** `README.md`, `docs/pipeline.md`, `CONTEXT.md`, `CLAUDE.md`, `docs/failure-modes.md`,
  `KAIZEN_LOG.md` e a proposta `⛔` para `.claude/rules/anatomia-do-agente.md`. A lista de drift está
  no `01-plano.md`, § "Para a fase DOCS".

## Gate PLAN-AUTO

| # | Critério | Status | Evidência |
|---|---|---|---|
| a | Grill sem perguntas abertas não endereçadas (🚩 vazia ou itens deferidos com dono) | ✅ | Duas rodadas: 5 perguntas na 1ª e 4 na 2ª, todas respondidas pelo humano (todas pela recomendação, mais a #112 escolhida contra a recomendação da 1ª rodada). Registro em "Decisões do grill". Os refinamentos de fatiamento do planner estão na decisão 12 e não mudam escopo nem decisão do humano |
| b | Checklist kaizen 100% ✅ e checklist DDD 100% ✅ ou `n/a` justificado | ✅ | seções abaixo |
| c | Plano passa no teste de autocontenção (sessão nova só com 00/01/checkpoint executa) | ✅ | Teste real: um subagente sem memória desta conversa leu só os três arquivos. **I1** (o critério): sem lacuna bloqueante. **I7** (o mais arriscado, testado a mais): 1 lacuna bloqueante (nenhum mundo matava `mut_APPROVE_adr_file_left_out`) e 5 de custo: dois mutantes cuja âncora o I7 muda, o fixture `SHUT` que também troca de branch, os fixtures dos probes 3 e 4, e a ambiguidade de "nome real". As 10 lacunas foram conferidas no código e escritas no `01-plano.md` antes do commit |
| d | Todo incremento do `checkpoint.md` tem Check executável (comando → esperado) | ✅ | 10 de 10, todos ancorados em `^  ok    ` ou em contagem exata, sem `\|` cru; o `tests/check-checkpoint.sh` passa sobre este checkpoint |
| e | `versao:` confirmada pelo humano (ou `JIRA_ENABLED=false`) | ✅ | `JIRA_ENABLED=false` (`.sdd/config.sh:47`) |
| f | `adr:` é uma decisão — um caminho, ou o literal `none` (alocado por `sdd adr new`) | ✅ | `none`, decidido pelo humano (2ª rodada, pergunta 4). A #156 **estende** a decisão registrada no comentário de `cmd_approve` em vez de revertê-la: o plano mora na base até a branch ser cortada "e é de lá que o corte é feito", e agora é o próprio approve que corta. Nenhuma das oito escolhe arquitetura cara de reverter. O veredito "inconclusivo" do catálogo é uma leitura nova de rc, local a `check-mutation.sh` e reversível num commit |

Todos ✅ → `aprovacao: auto`, por decisão do humano (2ª rodada, pergunta 4: `auto` só com o
PLAN-AUTO todo ✅). Não há `05-verdict.md` ao lado, então este plano não nasceu do `sdd kaizen`.

## Checklist kaizen (`kaizen-software`)

| # | Item | Status | Nota |
|---|---|---|---|
| K1 | Gemba — fui ver onde o trabalho acontece | ✅ | As 8 issues foram reproduzidas ou lidas no código com `arquivo:linha` (§ Problema). A suíte rodou 3 vezes: verde em 271,4 s com tempo por passo, vermelha sob rótulo REVIEW, vermelha lançada com `&`. O approve, o close, o symlink e o install rodaram num repo de rascunho |
| K2 | Problema declarado com métrica | ✅ | 7 fatos binários, cada um com asserção nomeada |
| K3 | Desperdícios identificados e cortados | ✅ | Inventário: 13 713 temporários vazios. Espera: suíte e `sdd health` travados sem prazo. Retrabalho: plano commitado à mão depois do approve, volta à `main` à mão no close, REVIEW vendo vermelho que o gate não vê. Defeito: escrita através de link. Ficou de fora o que nenhuma issue pede (prazo por mutante, prazo no `run_check_cmd`) |
| K4 | Fatiamento incremental, cada fatia verificável | ✅ | 10 incrementos, cada um com Red de uma frase. Os sensores de ambiente vêm primeiro (I1, I2), depois o runner e por último a suíte com prazo (I8, I9), que muda o `TEST_CMD` de todo gate. O I10 é contabilidade do `TODO.md` |
| K5 | Check por artefato (rótulo ≠ artefato) | ✅ | Os Checks leem `^  ok    <asserção>` dos sensores. As asserções exigem o artefato (o arquivo no commit, os bytes do destino do link, a branch em que o HEAD está, a contagem de `sdd-ck-*`), e não a frase do comando |
| K6 | Jidoka — o que para a linha está definido | ✅ | Suíte vermelha para. Mutante novo não pego quer dizer incremento não pronto. `--anchors` vermelho, idem. Estouro de prazo dentro de mutante é erro nomeado que deixa o `sdd health` vermelho, nunca ponto a favor |
| K7 | SDCA — a melhoria vira padrão (doc/rule/teste) | ✅ | Poka-yoke em vez de regra escrita: o approve chama a definição única de troca de branch; o `run()` recusa passo sem prazo declarado; os sensores armam o próprio veneno. Mutantes no catálogo. A DOCS atualiza README, pipeline e CONTEXT |
| K8 | Registro no KAIZEN_LOG | ✅ | A fase DOCS escreve a entrada com o antes e depois medido: suíte de 271 s sem prazo × com prazo; 1 temporário por suíte × 0; approve com 1 arquivo na base × diretório na branch |

## Checklist DDD (`ddd`) — condicional

`n/a — sem toque de domínio`: são portas de CLI e a suíte do kit. Nenhuma entidade, nenhum evento
de ledger e nenhum contrato entre módulos muda; o contrato de artefato do `00-missao.md` fica
idêntico.

## Decisões do grill (não re-litigar)

1. **Escopo: a missão A (#156, #182, #193, #81, #173) mais a carona só de `tests/` (#186, #157,
   #112).** A raiz é a mesma, "o comando do humano escreve ou deixa estado no lugar errado", e a
   carona entra no mesmo carimbo. A #187 fica fora: causa não diagnosticada.
2. **A missão mexe em `bin/` e empurra o começo da janela 4 do juiz, e o humano aceita.** O ledger
   real não tem nenhuma linha de alvo sobre `5e75fdc` (última linha: 2026-10-01 09:15, do próprio
   kit). Nada encalha.
3. **#156: o gatilho é o `branch:` real, pela mesma regra do `ensure_mission_branch`** (uma definição:
   vazio ou `<…>` é no-op). O approve o chama **depois do `y` e antes do `frontmatter_write`**. O
   commit leva o **diretório da missão inteiro** e o arquivo do `adr:` quando ele é caminho. Com
   `branch:` placeholder (o caso com JIRA ligado, até o TICKET), ele avisa, fica e commita o
   diretório. **Nunca `die`** por estar na base: a decisão do comentário em `bin/sdd:~7407` é
   preservada.
4. **#156, borda: branch declarada que já existe com outro plano.** O approve recusa depois do `y`,
   sem escrever nada. É o `die` que o `ensure_mission_branch` já tem ("differ or are missing on the
   destination branch; the working tree was not changed").
5. **#182: o close sem JIRA confere o PR antes de voltar.** `pr_url:` presente e PR não MERGED: `die`
   com a mesma frase do ramo JIRA. Nos outros casos, `close_return_home`.
6. **Symlink: recusar sempre, sem escrever através e sem substituir o link** (#81, #173). O
   `frontmatter_write` responde `die`. O `install --force` responde `warn`, com o arquivo intocado, e
   isso vale também para link quebrado. O `sdd-link-agents` é escolha explícita do humano, e
   substituir o link a desfaria em silêncio.
7. **#81, as outras duas metades:** `warn` quando o `chmod --reference` falha, e valor por `ENVIRON`
   no awk (a regra da casa, precedente no `gate_REVIEW`). O `ENVIRON` não tem mundo que o probe
   construa hoje, porque nenhum chamador produz `\`: limite declarado no comentário.
8. **#112: prazo por passo = 8 vezes o tempo ocioso, com piso de 60 s** (tabela no `01-plano.md`).
   - Fora do mutante: vermelho nomeado, e a suíte segue.
   - Dentro do mutante: rc **124**, que o catálogo lê como **inconclusivo** (erro nomeado, health
     vermelho), nunca como pego.
   - O passo do catálogo (`--with-mutation`) não tem prazo próprio; cada mutante herda os prazos
     dos passos.
9. **#186 e #157 são consertados no sensor, não no `run()`.** Medido: sob o rótulo, só o
   `check-autonomy.sh` reprova, e quem roda o sensor sozinho (uma sessão de REVIEW) também precisa do
   conserto. Cada sensor **arma o próprio veneno**, com um piso provando que está armado, para que a
   regressão fique vermelha em toda execução e não só quando alguém lança do jeito errado.
10. **`adr: none`, `ddd: n/a`, branch `feat/onde-o-comando-do-humano-escreve`.**
11. **Execução: `sdd run` headless, lançado pelo humano do próprio terminal**, nunca como tarefa de
    fundo do Claude Code. `aprovacao: auto` só com o PLAN-AUTO todo ✅; senão, vazio para
    `sdd approve`.
12. **Refinamentos do planner depois do grill**, sem mudar escopo nem decisão:
    - **A #112 virou dois incrementos** pela régua "Red numa frase": I8 (fora do mutante) e I9
      (dentro do mutante e veredito do catálogo).
    - **Entrou o I10 de contabilidade do `TODO.md`:** os `RESOLVED by` e o achado do `adr_declare`.
    - **I2 e I7 ganharam um termo de Check cada um:** o piso do veneno armado, e o mundo com
      `branch:` placeholder que a decisão 3 pede.
    - **O I8 exige que o Ctrl-C continue parando a suíte.** Um prazo que roubasse o SIGINT do humano
      seria regressão.
    - **O aviso de base no approve:** quando o approve vai trocar de branch, a linha antes do prompt
      anuncia a troca em vez de avisar "commits straight into it". Isso deriva da regra anti-alarme
      falso escrita em `cmd_run` (`bin/sdd:~7704`). Com `branch:` placeholder, o aviso fica como
      está.

## Pendências para o humano

- **Lançar a missão:** `./bin/sdd run 20261002-onde-o-comando-do-humano-escreve` do terminal
  interativo. Nunca com `&` de shell não interativo enquanto o I2 não estiver `done` (é a #157), e
  nunca como tarefa de fundo do Claude Code.
- **PR #195** (o 86º item e a catraca 85 → 86): **mergeado** em `a3d002f` (2026-10-02) e já
  incorporado por rebase antes do primeiro `sdd run`. A catraca parte de `todo-findings 86` e o I10
  a leva a 87 (o achado do `adr_declare`). O Check do I10 compara a catraca com a contagem real.
- **Rodar `./bin/sdd health` uma vez,** depois do último commit de código **e** da última rodada dos
  revisores do PR, antes do `gate_PR` (o carimbo; ~18 min com a máquina livre).
- O merge do PR é humano. Depois dele, o chore pós-merge apaga os oito itens com `RESOLVED by` e
  sincroniza as issues (skill `todo-to-github-issues`).
