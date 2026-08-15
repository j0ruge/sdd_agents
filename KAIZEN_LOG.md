# KAIZEN_LOG — `sdd_agents`

Registro de melhorias com **antes/depois medido**. Sem número, não entra.

---

## 2026-08-15 — Idioma era convenção, virou configuração (I13.5)

**Problema (Gemba):** o kit era utilizável só por quem lê português, embora nada no mecanismo
dependesse disso — **1.517 linhas acentuadas em 24 arquivos** da superfície (runner, agentes,
docs, README, config, testes), medidas por comando antes de começar. E não havia alavanca nenhuma
para um repo-alvo pedir artefatos noutro idioma.

### 5 Porquês

- **Sintoma:** o kit fala um idioma só, e não é escolha de ninguém — é herança.
1. Por quê? Toda a prosa foi escrita em PT-BR.
2. Por quê? O `CLAUDE.md` mandava: "PT-BR em tudo que é lido por humano".
3. Por quê? A regra nasceu quando o único leitor humano era o autor e o único repo-alvo era
   brasileiro — na época, uma simplificação correta.
4. Por quê? A regra não separou **duas audiências**: quem usa o kit (superfície) e quem lê os
   artefatos de uma missão (o time do repo-alvo). Uma regra só para as duas obriga a escolher um
   idioma para ambas.
5. Por quê (**causa raiz de processo**)? **Idioma foi tratado como convenção, não como
   configuração.** Convenção não tem chave, não tem default e não tem sensor — então não havia
   onde declarar o idioma, nem o que percebesse a regra sendo violada.

**Contramedida (as duas metades, uma não fecha a causa sem a outra):** `OUTPUT_LANG` dá à
audiência 2 uma chave, injetada pelo `boot_prompt()` em toda fase; `tests/check-lang.sh` dá à
audiência 1 um sensor. Traduzir sem a chave só trocaria a prisão de idioma; a chave sem o sensor
apodreceria no primeiro commit em português.

| | Antes (medido) | Depois (medido) |
|---|---|---|
| Linhas acentuadas na superfície | **1.517** em 24 arquivos | **0** |
| Arquivos da superfície com prosa PT-BR | 24 de 24 | 0 de 24 (2 exceções documentadas: contrato e dicionário) |
| Sensor que reprova PT-BR novo | **nenhum** | `check-lang.sh` na suíte, com catraca bidirecional e auto-teste |
| Chave para o idioma dos artefatos | **nenhuma** | `OUTPUT_LANG`, default vazio = comportamento idêntico |
| Mutações no catálogo | 15 | **16** (`RUN_ignores_output_lang`) |
| Catraca de tradução | — | 24 → **0** entradas |
| Tempo da suíte | 12,81s | ~14,0s (mediana de 3; o `check-lang` custa ~1,2s) |
| `sdd health` | rc 0, 6 dívidas | rc 0, **as mesmas 6** — nenhuma dívida nova |

**O sensor pegou três coisas que eu não teria pego**, e as três valem mais do que a tradução:

1. **Ele reprovou a si mesmo.** O dicionário de stopwords e os probes do auto-teste *são*
   português — escaneá-lo é acusar o detector de conter aquilo que detecta. Virou exclusão
   documentada, com o `selftest()` (rc 90/91/92) e um piso de caminhos (rc 93) como guarda no
   lugar do grep.
2. **Ele reprovou o `check-templates.sh`**, cujas regexes são os headings de `templates/` — ou
   seja, contrato de conteúdo em `OUTPUT_LANG`. Segunda exclusão, mesma categoria: português como
   **dado**, não como prosa. O custo (prosa PT-BR poderia entrar nesses dois arquivos sem ninguém
   ver) está escrito no arquivo e virou entrada de `TODO.md` com a direção que devolve a cobertura.
3. **Ele achou um bug nele mesmo:** `[\x{00C0}-\x{00FF}]` inclui `×` (00D7) e `÷` (00F7), que não
   são letras, e reprovou `QA_MAX_ITER × 3` no `schema.md` como se fosse português. A tentação era
   reescrever o doc até o detector calar — **enfraquecer o conteúdo para agradar um instrumento
   quebrado**. O conserto foi a classe, e o probe de inglês do auto-teste passou a carregar `×` e
   `÷`: sabotar a classe de volta agora reprova com rc 92.

**Correção de fato:** a entrada do `TODO.md` que originou esta missão afirmava que "o contrato já
é inglês". Medido: **não é** — sobraram 3 chaves de frontmatter (`aprovacao`, `versao`, `titulo`,
45 referências) e 2 nomes de artefato (`00-missao.md`, `01-plano.md`, 72 referências). Ficaram
fora de propósito, porque renomeá-las quebra missão em voo e toda instalação existente. Entrada
nova aberta.

**Não reivindicado:** "o kit agora é usável por quem não fala português". É métrica retardatária —
só o primeiro usuário estrangeiro mede. Revisar em missões futuras.

**Padronizado em:** `CLAUDE.md`, seção "Idioma" (três audiências: superfície inglesa com sensor,
artefato em `OUTPUT_LANG`, contrato inglês) e seção "TDD aqui dentro" (sensor que se auto-exclui
carrega auto-teste). Confirmado abrindo o arquivo depois de escrever.

**Custo:** 6 commits, 27 arquivos, +2.584/−2.196 linhas. Fecha 3 entradas do `TODO.md`, abre 3.

---

## 2026-08-14 — O sensor do sensor: a suíte verde não provava nada (I13.2)

**Problema (Gemba):** três bugs de gate da **mesma família** atravessaram a suíte verde e só
apareceram em uso real, cada um custando sessão paga — âncora de `**Status:**` no início da
linha (~US$ 15/volta), a mesma âncora duplicada em dois lugares divergindo ao ser corrigida num
só (~US$ 15/volta), e o parser da grade parando em `###` quando a seção seguinte é `##`
(~US$ 10). Somou-se a isso uma asserção que virou decoração ao mudar de caminho num refactor e
seguiu imprimindo `ok` por **vacuidade**.

### 5 Porquês

- **Sintoma:** o gate reprovava relatório correto (ou aceitava errado) e a suíte não acusava.
1. Por quê? A âncora do gate não casava com o texto que a skill realmente emite.
2. Por quê? O fixture usava um formato **escrito de memória**, não o emitido.
3. Por quê? Nada obrigava a copiar da fonte — gate e fixture têm o mesmo autor e nasceram da
   mesma suposição.
4. Por quê? Fixture e gate concordarem entre si é indistinguível de estarem certos: a suíte
   verde **confirma** a suposição em vez de medi-la.
5. Por quê (**causa raiz de processo**)? **Não existia sensor do sensor** — nada exigia que a
   suíte ficasse vermelha quando o runner é sabotado, então asserção vazia passa verde sempre.

**Contramedida (as duas metades, uma não fecha a causa sem a outra):** `tests/check-mutation.sh`
com 15 sabotagens catalogadas — mede se a asserção é viva; e fixtures **copiados da fonte** com
comentário de proveniência — mede se a suposição é a certa. Só mutação provaria que o gate mede
o formato imaginado com rigor.

| | Antes | Depois (medido) |
|---|---|---|
| Sabotagens do runner que a suíte pega | **0 de 0** (não havia catálogo) | **15 de 15 (100%)** |
| Lacunas reveladas pelo catálogo | — | 2 encontradas, 2 fechadas |
| Gates com mutação | 0 de 7 | **7 de 7**, cobrado pelo `sdd health` |
| Sensor do kit em 1 comando | nenhum | `sdd health` → exit 0 |
| Dívida de drift medida e congelada | não medida | 6 itens, cada um com dono no `TODO.md` |
| Tempo da suíte | 3,7s | 12,2s (mutantes em levas de 4) |
| Entradas do `TODO.md` | 25 abertas | 23 fechadas + 3 novas = 26 |

**As duas lacunas que o catálogo revelou** (nenhuma delas visível antes de existir mutação):
o fixture roda `TEST_CMD="true"`, que não pode falhar — então um gate que descartasse o rc da
suíte passava despercebido; e o fixture de bug do registry não tinha a legenda do enum
(`<!-- open | fixed | verified | wont-fix | invalid -->`), então afrouxar o grep para
`Status.*open` sobrevivia verde, bloqueando um `wont-fix` que é decisão humana.

**Padronizado em:** `CLAUDE.md` (§ TDD aqui dentro) — fixture copiado da fonte, gate novo entra
com mutação, e o aviso do `pipefail`. Conferido no arquivo, não só afirmado aqui.
Também em `docs/pipeline.md` (§ Quem mede os gates) e `README.md` (§ Uso).

### Desperdícios evitados (cortes conscientes)

- **Superprocessamento:** nada de motor de mutação genérico (mutmut/stryker) — mutante gerado
  produz centenas de equivalentes e um score que ninguém sabe agir. O catálogo é escrito à mão:
  uma entrada por bug que aconteceu ou por gate que existe.
- **Superprodução:** sem `--json`, sem histórico de score em disco (violaria "sem arquivo de
  estado"), sem mutar `agents/*.md`. Cortada também a checagem `bash -n` do health — a suíte
  já a roda.
- **Espera:** mutantes em levas de 4. Seriais seriam ~55s; medido: 12,2s a suíte inteira.

### O que aprendemos

- **`printf | grep -q` com `pipefail` inverte a lógica.** O `grep -q` sai no primeiro match e
  fecha o pipe; o `printf` morre de SIGPIPE (141) e o `pipefail` propaga — **achou vira erro**.
  Pior: depende do TAMANHO da entrada (o buffer de 64 KB absorve as pequenas), então passa nos
  testes e falha no repo-alvo grande. Duas ocorrências pré-existentes ficaram registradas no
  `TODO.md`, uma delas no Jidoka do `blocked`. Use herestring.
- **Regex de detector também apodrece.** A primeira medição contou 5 variáveis nunca lidas
  porque a classe `[A-Z_]+` não casa o dígito de `E2E_DIR`; e contou `QA_MAX_ITER` como morta
  porque procurava `$K`, e ela vive em contexto aritmético (`$(( QA_MAX_ITER * 3 ))`). Sensor
  que erra para os dois lados treina a ignorar o sensor.
- **O harness precisa da própria rede.** Três filtros: corrida de **controle** (a cópia sem
  sabotagem tem que ficar verde, senão o placar dá 100% por vacuidade), `cmp` (mutação que não
  aplicou é âncora perdida — erro do catálogo, nunca ponto) e `bash -n`.
- **Check negativo em trabalho não commitado apaga trabalho.** O Check do `sdd health` usa
  `git checkout bin/sdd` para desfazer a sabotagem; rodado antes do commit, levou junto a
  implementação inteira. Commite primeiro, sabote depois.

---

## 2026-08-14 — Nascimento do kit

**Problema (Gemba):** o fluxo de desenvolvimento documentado em
`obsidian/01 Projects/Sales Quote JRC/Fluxo-Desenvolvimento-Template-Prompt-QA.md` funciona, mas
exige **~6 intervenções manuais** depois do planejamento (`/clear` 2x, troca manual de modelo,
invocar QA, invocar review, push/PR) e sessões longas estouram a janela de contexto no meio da
execução — obrigando a recomeçar com estado só na cabeça do humano.

**Métrica-alvo:** 1 missão pequena atravessa do plano aprovado até **PR aberto** com
**0 intervenções humanas** e **0 estouros de contexto**.

| | Antes | Depois (alvo, medido no piloto SQ-94) |
|---|---|---|
| Intervenções humanas pós-plano | ~6 | 0 |
| Estouros de contexto por missão | frequente em missões médias | 0 (sessão por fase/incremento) |
| Gate de qualidade | rótulo ("está pronto") | artefato (teste, spec, grade, PR) |
| Achado fora de escopo | perdido ou vira desvio | entrada no `TODO.md` |

**Contramedida:** 6 agentes especializados + runner `bin/sdd` que encadeia sessões headless por
fase e por incremento, com gates por artefato e handoffs em disco.

**Desperdícios cortados no planejamento (K3):** claude-mem (injeção não curada gasta janela),
daemon/UI/banco de estado (estado derivado dos artefatos basta), Opus no publisher (tarefa
mecânica → Sonnet).

**Status:** implementação em curso (incrementos I0–I12 do plano). Resultado medido entra aqui
quando o piloto I11 fechar.

---

## 2026-08-14 — Shim quebrado do `agent-browser` (I0)

**Problema:** `~/.nvm/versions/node/v22.22.3/bin/agent-browser` era symlink para
`~/.hermes/hermes-agent/node_modules/...`, caminho inexistente — o binário `agent-browser`
simplesmente não existia no PATH (`command not found`), o que derrubaria a fase QA em silêncio.

**Contramedida:** re-link para o pacote são em `lib/node_modules/agent-browser/bin/agent-browser.js`.

**Sensor:** `agent-browser --version` entrou no `sdd preflight` — o ambiente passa a ser
verificado antes de cada missão, não descoberto no meio da fase QA.

| | Antes | Depois |
|---|---|---|
| `agent-browser --version` | `command not found` | `agent-browser 0.27.0` |
| Descoberta da quebra | no meio da fase QA | no preflight, antes de gastar sessão |

---

## 2026-08-14 — A fase headless não conseguia executar comando nenhum

> Missão `20260814-dry-run-completo`. O achado de maior valor da missão **não foi o que ela ia
> entregar** — foi o defeito estrutural que ela expôs no kit ao ser a primeira a rodar headless
> de verdade. Por isso a missão-fixture existe.

**Problema (Gemba):** `run_phase()` montava `claude -p … --permission-mode acceptEdits` **sem**
`--allowedTools`. `acceptEdits` auto-aprova **edição de arquivo**, não `Bash`. Na prática a sessão
de fase só conseguia ler: `tests/run-all.sh`, `bash -n bin/sdd` e até `bash -c 'echo hello'`
voltavam "This command requires approval". **`git add` também era negado.** O `sdd-executor` não
rodava a suíte na abertura, não via o Red, não verificava o Green e não conseguia commitar — e
`gate_EXEC` exige hash real no `git log`. **A fase EXEC era insatisfazível por construção**, e o
mesmo valia para QA/REVIEW (que rodam `TEST_CMD`) e PR (que precisa de `git push`/`gh`).

O modo de falha era do tipo mais caro: silencioso. Nada no runner acusava; a sessão simplesmente
não produzia artefato, e o gate reprovava com "1 de N incrementos ainda por executar" para sempre.

**Contramedida:** `ALLOWED_TOOLS` (default `Bash`) no `.sdd/config.sh`, passado como
`--allowedTools` em `run_phase()` — commit `2083680`.

| | Antes | Depois |
|---|---|---|
| Comandos que a sessão de fase consegue executar | 0 (só leitura) | os de `ALLOWED_TOOLS` |
| Fase EXEC | insatisfazível por construção | `357b401` rodou a suíte, viu Red, viu Green, commitou |
| Sessões gastas contra a parede por incremento `blocked` | 4 (até estourar `phase_budget`) | 0 — escala na hora, `exit 3` |
| Detecção | no meio da 1ª missão headless | — (sensor de preflight ainda pendente, no `TODO.md`) |

**Jidoka na prática:** a primeira sessão EXEC **não** contornou o impedimento. Marcou o incremento
`blocked`, escreveu a causa raiz no checkpoint e escalou sem escrever uma linha de código. Seguir
teria significado commitar bash não executado e marcar `done` — o "rótulo, não artefato" que o kit
existe para proibir. A linha parou, o defeito apareceu, o kit ficou mais forte.

**O que ainda falta (registrado no `TODO.md`, não fechado aqui):** o sensor durável. Hoje nada
impede a regressão silenciosa — o `sdd preflight` valida que o `claude -p` responde, o que **não**
cobre este modo de falha. O preflight precisa disparar uma sessão headless real com as mesmas
flags e exigir que ela **execute** um comando.

---

## 2026-08-14 — `--dry-run` mostrava o pipeline pela metade (I1)

**Problema (Gemba):** `sdd run <missão> --dry-run` existe para responder *"o que vai acontecer se
eu rodar isto?"* antes de gastar token. Respondia pela metade: imprimia a **primeira** fase e dava
`return 0`. Numa missão recém-planejada, o usuário via `EXEC` e não ficava sabendo que depois
viriam QA, REVIEW, DOCS e PR — nem com que agente e modelo cada uma rodaria.

**Contramedida:** cursor próprio sobre a lista `$PHASES` (`next_pending_phase()`), nunca
re-chamando `current_phase()` — que travaria na mesma fase para sempre, já que o dry-run não muda
o disco. Commit `357b401`.

| | Antes | Depois |
|---|---|---|
| Fases nomeadas pelo dry-run (missão recém-planejada) | 1 (`EXEC`) | 5 (`EXEC`, `QA`, `REVIEW`, `DOCS`, `PR`) |
| Agente/modelo por fase visíveis antes de gastar token | só da 1ª | de todas |
| Sensores na suíte | 2 | 3 (`check-dry-run.sh`) |
| Asserções na suíte | 90 | 120 |

**Sensor durável:** `tests/check-dry-run.sh`, permanente em `tests/run-all.sh`. Observado vermelho
antes do verde: projetava só `EXEC=sdd-executor`, faltando QA/REVIEW/DOCS/PR.

**Efeito colateral honesto, não escondido:** projetar exige avaliar os gates, e três deles rodam
`TEST_CMD`. O dry-run escreve `.sdd/logs/<missão>/gate-*-test-<ts>.log` (gitignored, memoizado por
processo). O `--help` e o [`docs/pipeline.md`](docs/pipeline.md) dizem isso com todas as letras —
a frase fácil "o dry-run não mexe em nada" seria mentira.

---

## 2026-08-14 — Asserção que virou decoração (dívida de sensor)

**Problema:** quando `53cf63a` moveu o `pipeline.log` para `.sdd/logs/`, a asserção
`projeção blocked não cria pipeline.log` continuou apontando para o caminho velho — onde o runner
não escreve mais em circunstância nenhuma. Ela seguia imprimindo `ok` **por vacuidade**: com o bug
que ela guardava reintroduzido à mão, continuava verde. Uma asserção que não pode falhar não se
distingue, na saída da suíte, de uma que passa.

**Como apareceu:** teste de mutação **à mão** — sabotar o código e exigir que a suíte fique
vermelha. Três rodadas seguidas (QA volta 2 e REVIEW r1) usaram a técnica e acharam frestas.

| | Antes | Depois |
|---|---|---|
| Asserções vácuas conhecidas | 4 (1 na QA, 3 no review r1) | 0 |
| Frestas provadas por mutação, não por leitura | — | 6 |
| Asserções na suíte | 118 (fim da QA) | 120 (fim do review) |
| Teste de mutação | manual, por sorte | ainda manual — `tests/check-mutation.sh` está no `TODO.md` |

**Contramedida parcial, dita como parcial:** as frestas foram fechadas, mas a **classe** do
problema continua. Enquanto a mutação for manual, a próxima asserção decorativa só aparece por
sorte. `tests/check-mutation.sh` — o sensor do sensor — é o item de maior alavancagem no
`TODO.md`. Registrar como "resolvido" seria exatamente o rótulo-sem-artefato que o kit proíbe.
