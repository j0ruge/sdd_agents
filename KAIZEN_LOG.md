# KAIZEN_LOG — `sdd_agents`

Registro de melhorias com **antes/depois medido**. Sem número, não entra.

---

## 2026-08-16 — O arquivo de achados para de crescer (5S no `TODO.md`)

**Problema medido:** o `TODO.md` chegou a **861 linhas / 75.331 bytes**, e o custo não era só de
leitura humana — o prompt de boot da fase KAIZEN (`bin/sdd:655`) manda a sessão paga de triagem
**ler o arquivo inteiro**. Duas causas, ambas de processo e não de conteúdo. (1) O contrato
mandava o item com `RESOLVIDO por <hash>` descer para "Feito" depois do merge do PR que o cita, e
ninguém executava a descida: **14 itens fechados** ocupavam a seção Aberto, incluindo cinco numa
**segunda convenção de fechamento não documentada** (`- [x]` com `[FEITO em <hash>]` no título) —
invisível para a triagem do kaizen, que procura `RESOLVIDO por` no corpo. (2) O formato prescrevia
uma linha por achado desde sempre; a prática eram corpos de até 31 linhas com análise completa,
reproduções e blocos "Atualização (data)" — profundidade que já existe no handoff que cada item
cita.

| | Antes (`fc304bf`) | Depois (`c5f5beb`, fecho do 5S) |
|---|---|---|
| Linhas / bytes do `TODO.md` | 861 / 75.331 | **362 / 26.566** (−58% / −65%) |
| Itens fechados parados na seção Aberto | 14 | **0** |
| Convenções de fechamento | 2 (uma não documentada) | **1** |
| Mediana / máximo de linhas por item | 10 / 31 | **6 / 8** |
| Itens no arquivo | 64 | **45** (14 resolvidos + 4 de "Feito" apagados, 2 fusões, 1 split) |
| Sensor sustentando a forma | 0 | **1** (`check-todo.sh`, 20 probes de selftest) |
| Suíte no default | 66,02 s | 67,08 s (o sensor custa **23 ms**; o resto é ruído de carga) |

Todas as linhas medidas na mesma máquina e na mesma sessão, `fc304bf` num worktree descartável
contra o `HEAD`, `./tests/run-all.sh` verde nos dois lados (mutação 30/30).

**A causa raiz não era o tamanho, era não haver dono do apagar.** A regra existia — em um lugar
só, um blockquote no meio do próprio arquivo — e dependia de alguém lembrar dela depois de um
merge, que é exatamente o momento em que a atenção está no PR seguinte. Por isso o conserto tem
duas metades, e a segunda é a que importa: a regra mudou de "desce para Feito" para **"é
apagado"** (a memória durável já existe em `git log -S`, `KAIZEN_LOG.md` e nos handoffs, e o item
cita o hash que o fecha), e a **triagem do `sdd-kaizen` virou o gatilho recorrente** — ela já lia
o arquivo corpo a corpo para não replanejar o que está fechado; agora também confere
`git merge-base --is-ancestor <hash> main` e lista os resolvidos a apagar no plano nascido. Sem
gatilho, um sweep manual seria pico isolado; com ele, o arquivo encolhe a cada volta do laço.

**Apagar prova por artefato, nunca por rótulo.** Os 14 hashes foram confirmados ancestrais de
`main` antes de qualquer remoção, e os identificadores ficaram anotados no corpo do commit
`c0193a7` — a rede de segurança mais barata que existe, e que só serve se for escrita antes.

**Padronizado em** (confirmado abrindo cada arquivo): `CLAUDE.md` § princípio 5 (teto de ~6
linhas, fechado é apagado, `- [x]` proibido), `agents/sdd-kaizen.md` § 5 e o espelho
`.claude/agents/sdd-kaizen.md`, `CONTEXT.md` (glossário "Triagem kaizen"), `.claude/napkin.md`
(itens 1 e 5), o cabeçalho do próprio `TODO.md` e o `CLAUDE.md` § "TDD aqui dentro" — onde a lista
de sensores voltou a bater com o disco (5 listados, 9 reais) e a regra do auto-teste passou de
"sensor que se auto-exclui" para "sensor que o catálogo de mutação não alcança", que é a
formulação que cobre os dois casos de hoje.

**O que o sensor ensinou sobre si mesmo.** Duas decisões saíram diferentes do plano, as duas por
medição e não por gosto. A primeira: todas as regras do `check-todo.sh` são **estruturais**
(pontuação, crase, data `(YYYY-MM-DD)`), nunca uma palavra em português — um sensor amarrado a
"descoberto por" quebraria num repo-alvo com `OUTPUT_LANG="en"` e alargaria o buraco de cobertura
que o próprio `TODO.md` registra contra a `surface()` do `check-lang`. Com isso o arquivo novo
**não** precisou de entrada na `lang-allowlist` nem de exclusão da superfície, ao contrário do que
o plano previa. A segunda: o `check-lang` reprovou a primeira versão deste sensor por **duas
citações em português nos meus próprios comentários** — o sensor de idioma pegou o autor do
sensor de forma, que é o laço funcionando.

⚠️ **O alvo de 300 linhas não foi atingido: foram 362 no fecho.** As sete seções `###` custaram
~46 linhas e ficaram porque agrupar por natureza (sensores, contrato, runner, saída humana,
comentário, custo, YAGNI) é o que torna dezenas de itens navegáveis. Registrado como número, não
como sucesso.

⚠️ **Toda linha desta tabela é medida NO COMMIT que o cabeçalho nomeia, não "hoje".** O `TODO.md`
é arquivo vivo: um achado novo entra e o número sobe no mesmo dia — como aconteceu horas depois
deste fecho. Três correções seguidas desta entrada tiveram a mesma causa raiz (medir num commit e
rotular outro), então a âncora agora está no cabeçalho e a prosa fala no passado.

⚠️ **A primeira versão desta tabela trazia "Achados abertos 47 → 46", e os dois números estavam
errados** — corrigidos para 64 → 45 pela revisão de código. Duas causas somadas, e as duas
instrutivas. A primeira: o "antes" foi medido no commit do próprio sweep (`c0193a7`), não no
`fc304bf` que o cabeçalho da tabela promete — baseline errada sob rótulo certo. A segunda: o
contador era um `grep -cE '^- \[[ x]\] '` que conta também o exemplo de formato dentro do bloco
cercado do cabeçalho do `TODO.md`, então inflava **os dois** lados em um. O mesmo `grep` estava no
`check-todo.sh` recém-escrito, ao lado de um parser awk que pula cercas corretamente — dois
mecanismos respondendo à mesma pergunta, que é a família de defeito que este repo já pagou três
vezes (os dois leitores do ledger, as duas definições de comparabilidade, e agora o contador).
Consertado com um parser só em dois modos (`lint`/`count`) e um probe fim-a-fim que reprova se a
contagem reportada divergir da que o parser vê.

**A lição mais cara da sessão: selftest verde prova as regras que têm probe, e só essas.** Depois
de a auto-revisão desta sessão dar Grade A ao sensor, uma leitura **adversarial independente**
achou **17 defeitos** — 2 CRITICAL, 5 HIGH, todos com reprodução. Os dois piores eram da mesma
espécie e a pior que existe num sensor: **falhar aberto**. Um `TODO.md` existente mas ilegível
fazia o `awk` imprimir nada, e contagem vazia num teste numérico é erro de sintaxe do `[` (rc 2)
que, sem `set -e`, cai fora do `if` — o run terminava em `ok 0 finding(s)`, rc 0. E uma única
cerca ``` sem fechamento travava o latch do parser e pulava **todas** as regras até o fim do
arquivo, também verde. Nos dois casos o sensor dizia "medi e está limpo" sobre o que não mediu.

| | Auto | 1ª | 2ª | 3ª | 4ª | 5ª | 6ª | 7ª | 8ª | 9ª | 10ª | 11ª | 12ª |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Defeitos achados | 0 | 17 | 9 | 11 | 11 | 11 | 11 | 10 | 5 | 3 | 5 | 7 | **3** |
| Herdados de rodadas anteriores | — | 17 | 2 | 3 | 5 | 4 | 5 | 5 | 3 | 0 | 1 | 6 | **3** |
| Probes do selftest | 14 | 20 | 30 | 37 | 45 | 49 | 48 | 58 | 63 | 67 | 69 | 75 | **75** |
| Linhas do parser `awk` † | 47 | 62 | 71 | 84 | 107 | 107 | 75 | 82 | 79 | 74 | 126 | 132 | **132** |
| Estado de cerca no parser | sim | sim | sim | sim | sim | sim | não | não | sim | não | não | não | **não** |

Procedência das três colunas novas, porque metade delas é derivada e não medida. **Probes** e
**linhas** saem do commit de cada rodada (`e339baf`, `0552110`; a 12ª não commitou conserto, então
repete a 11ª). **Defeitos** e **herdados** das rodadas 10 e 11 são contados do corpo do commit —
os relatórios daquelas rodadas não foram persistidos, e é por isso que o da 12ª está em
[`docs/handoffs/20260816-todo-enxuto/`](docs/handoffs/20260816-todo-enxuto/r12-caixa-partida.md).

† A linha de tamanho do parser serve à **tendência, não à comparação coluna a coluna**: as colunas
Auto–9ª foram medidas ao longo da sessão e não reproduzem do commit sob nenhuma definição única
(o programa `awk` entre aspas casa a 7ª; o bloco `todo_awk()` inteiro casa a 5ª e a 6ª; as demais,
nenhuma das duas). As colunas 10ª–12ª usam o bloco `todo_awk()` inteiro, que é o número maior — o
salto de 74 para 126 é mudança de régua, não crescimento do parser.

**O número que mais ensina não é nenhum defeito: é que cada rodada achou um defeito criado pela
anterior — três vezes seguidas.** A 1ª consertou a âncora com uma classe negada de travessão, e a
2ª mostrou que sob mawk isso nega *bytes*. A 2ª partiu a regra de cerca em duas, e a 3ª mostrou
que isso criou um latch de mão única. A 3ª acrescentou a regra de sub-item marcado, e a 4ª mostrou
que ela acusava amostras de código — contradizendo o comentário três linhas acima, no mesmo commit.

**A 4ª rodada achou a causa comum das três** — o parser não tinha estado para "dentro do bloco de
código de um item" — e acrescentou esse estado. Fechou quatro defeitos e a 5ª rodada achou mais
quatro **dentro do estado novo**: uma `- [x]` em coluna 0 entre a abertura e o fechamento do bloco
sumia com o run verde, um span inline abria bloco fantasma, e as formas `+ [x]` / `1. [x]` /
indentada seguiam invisíveis.

**O que finalmente quebrou o ciclo foi apagar a feature, não consertá-la.** O estado saiu inteiro:
nenhum dos 46 achados carrega bloco de código e o teto de ~6 linhas não deixa caber, então item
simplesmente **não pode** carregar cerca — uma linha no lugar de uma máquina de estado, falhando
fechado e nomeando a causa raiz. Junto, caixa marcada virou regra **por linha** em vez de por
item, que é o que finalmente cobriu todas as formas que o GitHub renderiza marcadas. O parser
`awk` encolheu para 107 linhas e a família de defeitos foi embora com o estado que a hospedava.

**A 6ª rodada mostrou que nem isso bastava**, e o diagnóstico final é mais amplo: **este arquivo
tinha virado um parser CommonMark escrito em awk.** Cerca de 4 espaços que o CommonMark chama de
bloco de código, fechador com info string, delimitador `1)`, tab no lugar do espaço, blockquote —
uma enumeração exaustiva de 117.649 documentos de 6 linhas achou 24 fail-opens, **100% deles na
lógica de cerca**. Markdown é genuinamente difícil, e cada rodada acertava um caso de borda
criando outro.

Então o rastreamento de cerca saiu inteiro. A seção de achados não tem cerca nenhuma — a única do
arquivo é o exemplo de formato, no cabeçalho —, então o parser **pula o cabeçalho** e **proíbe
cerca depois dele**. Não sobrou estado para dessincronizar. Parser de **107 → 75 linhas**, e a
regra da caixa marcada, agora independente de cerca, cobre as dez formas que o GitHub renderiza
marcadas em vez das cinco de que eu tinha partido.

**As duas lições, e nenhuma é sobre bash.** A primeira: YAGNI não é só sobre o que custa escrever,
é sobre o que custa *manter correto* — cinco rodadas foram gastas defendendo bloco de código
dentro de item, que nenhum dos achados usa e que o teto de ~6 linhas já proíbe. A segunda, mais
geral: **um sensor deve RECUSAR o que não sabe interpretar com segurança, não adivinhar.** Ser
mais estrito que o formato de entrada é uma decisão de projeto legítima e barata; tentar
interpretar tudo é o que custou seis gerações de defeito.

**A linha da tabela que mais ensina é "estado de cerca no parser".** Ele saiu na 6ª rodada e a 7ª
e a 8ª não acharam nada nessa família. Aí eu o reintroduzi na 8ª — limitado ao cabeçalho, "seguro
por construção" — e a 9ª achou nele exatamente o mesmo fail-open de sempre: uma cerca solta fazia
o arquivo inteiro renderizar como código com o run reportando "ok". A guarda que eu tinha escrito
para pegar isso era código morto inalcançável. **Terceira vez aprendendo a mesma coisa.** O
substituto não tem estado: uma contagem de paridade calculada fora do awk, que não pode
dessincronizar porque não lembra de nada.

**E a curva de convergência é o número que mais mudou de sinal:** achados herdados de rodadas
anteriores foram 17 → 2 → 3 → 5 → 4 → 5 → 5 → 3 → 0 → 1 → 6 → **3**. O zero da 9ª parecia fechar o
argumento — enquanto o conserto era remendo o herdado não caía, e ele só foi a zero depois que a
estrutura virou lista-branca sem estado. O laço não converge por esforço, converge por
simplificação; isso continua verdade. **Mas o zero não se sustentou**, e é essa a parte nova: ele
media a ausência dos defeitos que aquela rodada sabia procurar, não a ausência de defeitos.

As três rodadas seguintes mostraram o quê. A **10ª** derrubou a contagem de paridade que a 9ª
tinha escrito — quarta e última tentativa de modelar cerca, e a quarta a falhar dos dois lados
(silêncio com marcadores mistos, vermelho em três formas legítimas). A **11ª** achou a regressão
que a 10ª criou — um predicado alargado de "abre com placeholder" para "contém `<`", que escondia
288 das 18.720 formas de item no cabeçalho — mais seis regras que a varredura de mutação mostrou
sem probe, uma delas falhando aberta. E a **12ª** não achou **nada** criado pela 11ª, e ainda
assim achou três defeitos, todos herdados. Um deles é uma classe nova de fail-open que atravessou
as onze rodadas anteriores intacta: uma caixa marcada que cai na linha **seguinte** ao marcador
ainda é renderizada marcada pelo GFM, e a regra 2, que é por linha, não a vê.

Duas consequências para o processo viraram três. **Revisão adversarial é laço, não etapa**: o
critério de parada não pode ser "consertei os achados". E **quando três rodadas seguidas acham
defeitos na mesma vizinhança, o defeito não é nenhum deles — é a estrutura que os hospeda**; a
saída é parar de remendar e perguntar que estado está faltando. A terceira é da 12ª: **"uma rodada
que não acha nada" também não é critério de parada** — é só evidência sobre o que aquela rodada
sabia atacar. A 12ª usou um oráculo que nenhuma anterior tinha usado (um parser CommonMark de
verdade, para comparar o veredito do sensor com o que o GitHub renderiza) e por isso viu o que
onze leituras não viram. O que faz uma rodada valer não é o esforço nem o número dela — é ela
trazer um instrumento que as anteriores não tinham.

**A segunda rodada achou um defeito que a primeira rodada CRIOU, e essa é a parte que ensina.** O
conserto da âncora usava `sub(/ — [^—]*$/, ...)`, e o `awk` desta máquina é o **mawk 1.3.4**, que é
orientado a byte em qualquer locale: `[^—]` não nega o caractere, nega os bytes `{0xE2,0x80,0x94}`.
Como toda a faixa U+2000..U+2FFF começa com `0xE2`, bastava uma aspa curva na cauda do item —
`the team’s mission` — para o `sub()` falhar, o `head` continuar o item inteiro e a regra degradar
de volta para "crase em qualquer lugar", que a própria atribuição satisfaz. **Falhando aberto em
pontuação corriqueira**, com todos os 30 probes verdes, porque todo probe era ASCII puro. Vale como
regra geral e está no `CLAUDE.md`: classe negada só com ASCII; separador literal se procura com
`index()`/`substr()`.

O padrão por trás dos 17: toda regra que **nenhum probe distinguia** podia ser degradada sem que
nada notasse — a régua da data virava "qualquer parêntese", a do título virava "`**` em qualquer
lugar", a da âncora virava "crase em qualquer lugar" (satisfeita pela própria atribuição). O
selftest ficava verde nas três. Sabotagem adversarial é o que encontra a regra sem probe; o
selftest é o que impede que ela volte. **São instrumentos diferentes e um não substitui o outro** —
que é a mesma relação entre a suíte e o `check-mutation.sh` que o I13.2 já tinha registrado, um
nível abaixo. Duas regras, aliás, eram decoração pura e foram **removidas** em vez de ganharem
probe: o `/^#/` virou redundante quando a regra de coluna 0 entrou, e o piso de 20 itens punia
exatamente o encolhimento que o sensor existe para causar.

---

## 2026-08-16 — O ledger e o Jidoka param de mentir (missão `20260815-ledger-sem-ponto-cego`)

**Problema medido:** a primeira missão **planejada pelo próprio kit** (Marco 2) atacou o
instrumento que o laço kaizen lê, enquanto a série ainda estava vazia (`latest: null`) — o único
momento em que consertar não obriga a reinterpretar histórico. Três pontos cegos verificados no
`bin/sdd` de `fdf8708`: (1) o Jidoka do incremento `blocked` decidia por `printf | grep -qx` sob
`pipefail`, então **silenciava** em checkpoint grande e o runner queimava o `phase_budget` inteiro
contra a parede que já conhecia; (2) a auto-degradação `PUBLISH_ON_REVIEW_BLOCKED=draft` — o evento
de autonomia mais interessante que uma missão produz — dava `continue` antes do diário e do ledger
e **não escrevia linha nenhuma**; (3) `sdd autonomy` (humano) e `sdd kaizen --series` (juiz)
contavam escalada em eixos diferentes e podiam reportar números diferentes para o mesmo período.

| | Antes (`fdf8708`) | Depois (`fba1afa`) |
|---|---|---|
| Jidoka do `blocked` com checkpoint de 20000 linhas | **não dispara** (silencia sempre a partir de ~5000 linhas de `ckstatus`; 10/10 medido) | dispara, `rc 3` pelo ramo certo |
| Linhas no ledger quando o runner se auto-degrada | **0** | **1 por `run_id`** (medido no re-walk: ramo entrado 3×, registro 1×) |
| Leitores que agrupam escalada por `kit_sha` | 1 de 2 (só a série) | **2 de 2**, com asserção que compara dado com dado |
| Consumidores do enum de escalada que enxergam o mesmo conjunto | 2 de 3 (`phase_label` ficou cego) | **3 de 3**, por um `is_escalation` único por programa |
| Mutações no catálogo | 25 (score 100%) | **30** (score 100%, `KNOWN_GAPS` vazio) |
| Chamadas de asserção em `tests/*.sh` | 219 | **260** |
| Suíte no default (`SDD_MUTATION_JOBS=4`) | 47,9 s | **66,3 s** |

Todas as linhas medidas na fase DOCS, mesma máquina e mesma sessão: `fdf8708` num worktree
descartável contra o `HEAD` da missão, `./tests/run-all.sh` verde nos dois lados.

**O achado que vale mais que os três consertos: cinco asserções vácuas numa missão só.** Cada uma
passava por causa do **regime do fixture**, não da propriedade que o nome prometia — o `rc 3` do I1
era compartilhado com o esgotamento de orçamento; o ramo `draft` do I2 nunca era alcançado; a
cardinalidade do `F1` era garantida pelo stub que movia o disco uma vez só. A quinta, achada na
revisão, é de outra espécie: `"nothing had to be taught to phase_label"` **afirmava a decisão
errada** — e por causa dela a única missão em que o runner baixou a própria régua lia `ok` para o
juiz assim que um `sdd run` posterior passasse no gate de REVIEW.

| | Antes | Depois |
|---|---|---|
| Asserções vácuas conhecidas nesta missão | 5 (4 achadas em execução, 1 na revisão) | 0 |
| Técnica contra vacuidade registrada como convenção | nenhuma | 3 perguntas no `CLAUDE.md` § "TDD aqui dentro" |
| Asserção **diferencial** (dois fixtures comparados entre si) | 0 | 1 (`degraded` vs `blocked`, `tests/check-kaizen.sh`) |
| Testemunha de **regime** (conta quantas vezes o ramo foi entrado) | 0 | 1 (`tests/check-autonomy.sh`, exige ≥2) |

**Sensor durável:** as 5 mutações novas (`RUN_jidoka_pipefail`, `RUN_degraded_row_dropped`,
`RUN_escalations_no_axis`, `RUN_degraded_repeats`, `RUN_degraded_label_blind`) — cada conserto tem
um mutante que o mata, e `sdd health` reprova gate sem mutação. Red observado antes de cada Green.

**Custo dito como custo:** o critério (4) da D7 ("suíte < 30 s no default") continua não atingido e
esta missão **piora** o número de propósito — 5 mutantes a mais, cada um rodando a suíte inteira
numa cópia, e o fixture mais caro abrindo mais sessões de stub desde o `F1`. Cortar mutação para
ganhar tempo violaria o princípio que motivou o I13.2. As três saídas (subir o alvo, subir
`SDD_MUTATION_JOBS`, aceitar) estão no `TODO.md` com a medição, como decisão do humano.

---

## 2026-08-15 — I13.3: o laço fecha — o kit julga a própria mudança e planeja a próxima

**Problema medido:** o kit detectava 5× mais do que fechava (20 achados / 4 fechados na missão
medida do I13.1) porque ninguém julgava a mudança anterior nem planejava a próxima — detecção
sem fechamento é inventário. O I13.3 constrói o juiz híbrido (ADR 0001) e o planejador headless
com Jidoka (ADR 0002): `sdd kaizen --series` (série determinística), `gate_KAIZEN` (veredito
achado por conteúdo, plano nascido com `aprovacao:` vazio), `piorou` ⇒ exit 3, o 7º agente
`sdd-kaizen`, e o lembrete pós-pipeline (D6/D8).

| | Antes (I13.3.0, `302b9b8`) | Depois (fecho + review, mesma máquina e sessão) |
|---|---|---|
| Mutações no catálogo | 20 (score 100%) | **25** (score 100%, `KNOWN_GAPS` vazio) |
| Gates com mutação cobrada pelo `sdd health` | 7 | **8** (`gate_KAIZEN` incluso) |
| Asserções de sensor do laço kaizen | 0 | **67** (`tests/check-kaizen.sh`) |
| Piso da superfície do `check-lang` | 26 caminhos | **31** (ADRs + sensor + 2× agente) |
| Suíte no default (`SDD_MUTATION_JOBS=4`) | 26,0 s (1 rodada) | 38,0 s no fecho (mediana de 3); **52,1 s** pós-review (mediana de 3, 25 mutantes) |
| Suíte com `SDD_MUTATION_JOBS=10` | — | 27,3 s (23 mutantes, no fecho) |
| Missões do kit planejadas pelo próprio kit | 0 | **1** (`20260815-ledger-sem-ponto-cego`) |

**A primeira volta real** (Check de fecho, D7): sessão `a0e24b4e`, opus, **618 s**,
**US$ 3,36**, rc 0. Com o ledger real vazio (medido: `~/.sdd/` sem o arquivo), o veredito saiu
`indeterminado` com `kit_sha_judged: none`, citando a série verbatim e respeitando a guarda;
a triagem real do `TODO.md` achou 1 item já resolvido sem marca (`4ec9752`) e recalibrou outro
pela metade; a missão nascida tem 3 incrementos com Check executável e passou o `gate_KAIZEN`
com `aprovacao:` vazio — **o plano espera o humano** (Marco 2: o gate funcionando). O ledger
real ganhou 1 linha KAIZEN (`kit_dirty: false`, `gate: pass`), que a própria série exclui como
`meta`. Idempotência provada: o segundo `sdd kaizen` respondeu "already judged" sem gastar
sessão. O frontmatter do veredito real virou o fixture do gate no sensor (proveniência
`c2dd298`), fechando o risco "gate e fixture do mesmo autor".

**Critério D7 não atingido, dito como não atingido:** a meta "(4) suíte < 30 s no default"
falhou — 38,0 s. O custo cresce com o catálogo (13,98 s/16 mutantes → 22,34/19 → 38,0/23), que
é exatamente o que deve crescer; a triagem do agente registrou o estouro no `TODO.md` com as
três saídas conhecidas (subir o alvo, subir o default, aceitar o custo) — decisão do humano.

**Review pré-merge (2026-08-16), medido dos dois lados:** o `/codereview` sobre o diff da
branch achou **9 achados (2 HIGH, 2 MEDIUM, 5 LOW)** que 51 asserções e 23 mutações não viam —
os dois HIGH da mesma família de sempre, rótulo confiado sem verificação: (1) `gate_KAIZEN`
aceitava `melhorou`/`piorou` sem cruzar com `guard.sufficient` da própria série e sem validar o
enum; (2) o retry genérico ("fix exactly that") podia instruir uma sessão a **apagar uma
`aprovacao:` preenchida pelo humano**. A rodada de verificação (r2) confirmou os 9 fixes e achou
o **10º**: faltava o mesmo bailout depois da retentativa — aprovação escrita pelo retry virava
escalada `no-progress` espúria. Correções: o gate cruza guarda e enum, aprovação preenchida faz
bailout **antes** de qualquer sessão nos três pontos (`auto` para a linha com rc 3; valor humano
⇒ "done, sdd run", rc 0), e as mutações 24 e 25 (`KAIZEN_guard_ignored`,
`KAIZEN_approved_bailout_dead`) provam por sabotagem que as 16 asserções novas medem. Custo do
review na suíte: 38,0 s → **52,1 s** (mediana de 3) — 2 mutantes a mais e um sensor mais pesado
rodando dentro de cada um dos 26 sandboxes; entra na mesma conta do estouro já registrado no
`TODO.md`.

**Problema medido:** o `/codereview` sobre o merge `6f2b59e` achou dois defeitos que a suíte de 19
mutações e 63 asserções não via, e os dois são da mesma família — **guarda que lê como medida e
não é**.

1. `AUTONOMY_SHA_WARNED` prometia, no próprio comentário, "one-shot per process so it does not
   repeat on every row". Não repetia por linha: repetia **sempre**. `autonomy_kit_stamp` só era
   lida como `stamp="$(autonomy_kit_stamp)"`, então o corpo inteiro — inclusive
   `AUTONOMY_SHA_WARNED=1` — rodava num **subshell** que morria com a substituição de comando. O
   flag voltava a `0` a cada chamada e o ramo `[ "$AUTONOMY_SHA_WARNED" = "1" ]` era inalcançável.
   Reproduzido isolado: **5 avisos em 5 chamadas, flag final `0`**. O gêmeo `AUTONOMY_WARNED`
   (jq ausente) funciona — `autonomy_have_jq` é chamada direto —, e foi a assimetria que entregou
   o defeito.
2. `tests/check-autonomy.sh` apontava `SDD_STATE_DIR` para **dentro da árvore git do fixture**,
   exatamente a configuração que o design do ledger declara proibida e que `check-gates.sh` e
   `check-dry-run.sh` evitam de propósito, cada uma com o comentário explicando por quê. O stub que
   commita roda `git add -A`: o ledger entrava **rastreado e commitado no repo sob teste**.

**Antes → depois**

| | antes | depois |
|---|---|---|
| avisos "kit sem `.git`" por `sdd run` de 3 linhas | 3 (um por linha) | 1 |
| mutação | 19/19 | 20/20 |
| asserções em `check-autonomy.sh` | 63 | 68 |
| instrumentos rastreados pelo repo sob teste | 2 (`state/autonomy-log.jsonl`, `.stub/claude`) | 0 |
| caminhos sujos na árvore do fixture ao fim | 6 | 0 |
| suíte | 24,54s (mediana de 3, `HEAD` em worktree) | 23,26s (mediana de 3) |

**Sobre o tempo:** neutro, e de propósito. O 20º mutante cabe na 5ª leva de 4 que já existia
(`SDD_MUTATION_JOBS=4`), então não há leva nova para pagar. A linha da suíte foi **remedida dos dois
lados hoje**, na mesma sessão, em vez de comparar com os 22,34s que o log registra para o I13.1: a
máquina não está no mesmo estado, e comparar contra número guardado teria transformado ruído de
ambiente em regressão inventada.

**O conserto ataca a causa, não o sintoma:** `autonomy_kit_stamp` publica `AUTONOMY_KIT_STAMP` como
global em vez de imprimir — o mesmo padrão que `run_phase` já usa para `LAST_PHASE_*`, e pelo mesmo
motivo. Some o subshell, e a guarda que o comentário descreve passa a existir de fato.

**O sensor que faltava, e o que ele achou sozinho:** a asserção nova precisa de um kit **sem
`.git`** para alcançar o ramo (o kit real é um checkout), então `check-autonomy.sh` copia
`bin/ templates/ config/` — o mesmo conjunto do `sandbox()` da mutação — para fora do repo sob
teste e conta os avisos de um `sdd run` que escreve 3 linhas. A mutação `RUN_autonomy_sha_warn_repeats`
prova que a asserção mede: sabotar o flag para `0` mata a suíte. E a asserção genérica de higiene
("a árvore do repo sob teste termina limpa") pegou, na primeira execução, um instrumento que
ninguém tinha listado: o próprio stub `claude`, que morava em `$FIX/.stub` e vinha sendo commitado
junto. Foi para fora também.

**Onde a linha ficou:** o marcador `.moved-once` **continua dentro** do repo sob teste. Ele é o
produto de trabalho simulado da sessão — é o que faz `state_fingerprint` andar —, não instrumento.
Instrumento (ledger, stub, fixtures do leitor, cópia do kit) fica fora; trabalho fica dentro.

---

## 2026-08-15 — O runner passou a observar a si mesmo (I13.1)

**Problema medido:** o kit tinha 6 fases por missão e **zero** observabilidade sobre a própria
autonomia. A pergunta "a última mudança melhorou ou piorou?" só tinha resposta por memória
humana, e o piloto SQ-97 já mostrara que memória humana perde o dado: as 6 sessões foram
reconstruídas à mão, depois, a partir de logs.

**Antes → depois**

| | antes | depois |
|---|---|---|
| linhas de série histórica | 0 | 1 por sessão + 1 por escalada |
| sessões de retry medidas | 0 (rodavam sem `state_fingerprint`) | todas |
| mutação | 16/16 | 19/19 |
| suíte | 13,98s (mediana de 3, merge-base pré-I13.1) | 22,34s (mediana de 3) |
| pontos de escrita com guarda própria | 3 (diário) | 6, todos por uma função só |

**O que mudou de verdade:** o gate passou a ser avaliado **uma vez** por sessão em vez de até
quatro vezes nos ramos do `cmd_run` — menos `TEST_CMD` rodando por fase, e a linha do ledger
nasce depois do gate porque carrega o resultado dele.

**O ramo `moved="true"` não tinha sensor nenhum, e o revisor da Task 2 mediu isso:** até esta
task, todo stub `claude` do repositório era morto (`rc 1`) ou nunca chegava a rodar (dry-run) —
nenhuma sessão de teste jamais mudou o disco de verdade, então a atribuição
`[ "$before" != "$after" ] && moved="true"` podia virar um `true` (no-op) sem que a suíte
notasse. Isso importa porque `moved` é o numerador do desperdício que `sdd autonomy` relata: uma
regressão ali tanto escala BLOCKED em fases que estavam progredindo de verdade quanto registra
toda sessão como desperdício, com a suíte verde. `tests/check-autonomy.sh` ganhou um stub com
marcador em ARQUIVO — o stub é um processo novo a cada invocação, então uma variável de shell não
sobrevive entre chamadas — que commita de verdade na primeira invocação e nada faz depois. A
mutação `RUN_moved_never_true` prova que o sensor pega o mesmo no-op que o revisor tinha usado à
mão: catálogo 16 → 19, as duas do brief (`RUN_autonomy_ignores_dry_run`,
`RUN_autonomy_null_moved_as_zero`) mais esta.

**Custo da suíte, sem disfarce:** de ~14,0s (merge-base `c8bb535`, pré-I13.1, medido nesta
mesma máquina) para ~22,3s — acima do alvo de ≤15s do plano. A maior parte do aumento é o
catálogo de mutação: 19 mutantes contra 16, cada um rodando a suíte inteira num sandbox isolado
(`SDD_MUTATION_JOBS=4` por padrão, e a máquina tem 20 núcleos — paralelismo é uma alavanca não
usada). Decisão sobre subir o alvo do plano ou o `SDD_MUTATION_JOBS` default é humana; registrada
em `TODO.md` com o número medido, como o próprio plano manda.

**O que não mudou de propósito:** nenhum score. O runner grava fato; quem julga é o `sdd-kaizen`
do I13.3, que nasce com série histórica em vez de opinião.

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
