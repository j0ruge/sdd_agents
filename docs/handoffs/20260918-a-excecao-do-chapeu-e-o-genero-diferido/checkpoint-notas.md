# Notas de execução — a exceção do chapéu e o gênero diferido

> **Append-only.** Uma linha por evento; nunca reescreva o arquivo, nunca o releia inteiro.
>
> Este arquivo nasceu em `20260904-a-dieta-de-contexto`, separado do `checkpoint.md` por medição:
> as notas eram **69% daquele arquivo** (67 166 B de 97 865 B em `20260901-o-revisor-so-acha`), e
> aquele arquivo era **44,7% de tudo que a missão releu** — 160 leituras, 1 114 571 B. Enquanto
> tabela e notas dividiam o arquivo havia um piso mecânico: em sessão headless o `Edit` exige um
> `Read` prévio, então toda sessão que atualizasse a tabela pagava o arquivo inteiro. Separadas,
> escrever nota é `>>` e custa **zero leitura**.
>
> O prompt de boot **inlina as últimas 10 notas** (`BOOT_NOTES_TAIL` no `bin/sdd`) e manda
> explicitamente **não abrir este arquivo**. Se você precisa de uma nota mais antiga, ela é
> história — e história se lê no `git log`, não no boot de toda sessão.

## Notas de execução

> Uma linha por evento relevante: bloqueio, decisão tomada, desvio do plano com justificativa.
> É o que a próxima sessão lê para não repetir um erro que já custou caro.

- <YYYY-MM-DD HH:MM> · `<ID>` · <o que aconteceu>

> **Toda vez que um humano precisou entrar na linha** — um `sdd retry`, um conserto à mão, um
> `BLOCKED` assumido — sai uma linha com o marcador `intervention:`. É a **narrativa** do que o
> humano fez. O **número** de intervenções o `sdd autonomy --by-mission` lê do ledger, em
> `launch(es)` (`run_id` distintos — cada `sdd run`/`sdd retry`), e imprime estas notas ao lado
> como `intervention note(s)`. Medido em 2026-08-28: a missão de três lançamentos tinha zero
> notas — o contador não pode depender de alguém lembrar de escrever; a narrativa, sim, e é a
> única fonte que diz o que o humano *fez*.
>
> ⚠️ O marcador é **inglês e minúsculo**, como `pending`/`done`/`blocked`: é contrato, não prosa.
> O texto depois dos dois-pontos vai no idioma do `OUTPUT_LANG`, como o resto deste arquivo.
> Só conta quando abre a linha — `intervention` no meio de uma frase é prosa e não é contado.
>
> Desde 2026-09-03 o **runner escreve a linha sozinho** quando é ele quem recebe a mão do humano —
> `sdd run --phase X`, `sdd retry`, `--budget-override` — e a commita sozinha, na hora, para a
> árvore chegar limpa ao gate da fase seguinte. A linha escrita à mão continua valendo para o que
> o runner não vê: conserto manual, fase feita à mão, `BLOCKED` assumido. `sdd approve` não
> escreve nenhuma: aprovar o plano é o gate humano desenhado, não uma entrada na linha. A nota
> diz o que o runner **sabe** ("forçada pela CLI"), nunca quem estava na CLI: outro agente com
> shell entra pela mesma porta, e o runner não distingue — medido em 2026-09-03.
>
> O exemplo abaixo mora **dentro** desta citação de propósito: o `>` quebra o casamento com
> `^[[:space:]]*-`, e sem ele o exemplo era contado verbatim — todo checkpoint recém-instanciado
> nascia devendo uma intervenção fantasma ao instrumento que mede autonomia. Copie a forma para
> fora da citação ao registrar uma intervenção de verdade.
>
> - intervention: <o que o humano teve de fazer> — <fase> — <custo, se houver>


- I0 (`79dd4df`) — missão criada, branch de `main` (`a96923d`), ADR 0009 alocada por `sdd adr new`.
- I1 — probes ANTES do código, RED observado com o motivo certo (`lived|0`: a chave era ignorada
  inteira). Passada de sabotagem: **9 mutações, 9 pegas, 0 sobreviventes**.
  ⚠️ A sabotagem achou um defeito meu: `case "$p" in /*) return 1` era **redundante** — um caminho
  absoluto abre com `/`, então o primeiro componente é vazio e a cláusula `''` já o recusa. O
  probe ficou VERDE com a cláusula removida. Removi a cláusula (regra do `CLAUDE.md`) e **mantive
  o probe**, que mede a propriedade e não a linha: a nova sabotagem "a leading slash is stripped
  like a trailing one" o deixa vermelho, então a propriedade segue medida.
  ⚠️ Duas tentativas de sabotagem foram descartadas pelo próprio arnês antes de virarem conclusão:
  âncora `''|.|..) return 1 ;;` casa **2x** (existe igual no `adr_dir_ok`), e um primeiro arnês
  restaurava o arquivo com `git checkout`, que reverte para o HEAD — anterior ao I1. Nos dois casos
  o arnês gritou em vez de concluir sobre um arquivo que não mudou.
- I2 — o par diferencial ficou RED duas vezes por motivo de FIXTURE, não de produto, e as duas
  valem registro: (1) `hwx_cfg` deixava o `.sdd/config.sh` sujo e o `git add -A` do stub o varria
  para o commit da sessão — `.sdd/` também está fora do `writes:` do `sdd-docs`, então TODO regime
  lia `hat-crossed`, por um caminho que o fixture escreveu e não o que estava sob teste; (2) sem
  `--max-phases 1`, a corrida que a chave DEIXA PASSAR anda para a fase seguinte, onde o stub não
  faz nada, e termina `no-progress` — rc 3 sobre o fixture, não sobre a fronteira.
  ⚠️ O remédio saiu de DENTRO do `HAT_CROSSED_WHY`: três asserções antigas leem a lista de
  caminhos como o ÚLTIMO campo `': '` (`reviewscope_files`), e conselho no `why` também vira ruído
  no ledger. Ele viaja ao lado, numa linha `HAT-REMEDY` do `pipeline.log` e no bloco `dim`.
  ⚠️ O `mut_RUN_hat_extra_unguarded` nasceu com `|` de delimitador do `s///` numa linha que
  CONTÉM `|` — o sed morria e não mudava nada. Pego pelo arnês que exige `diff` não-vazio antes de
  concluir; os três mutantes estão provados um a um (`diff` 2 linhas, `bash -n` ok, a asserção
  esperada vermelha).
- I3 — RED observado (`deferred` bloqueava e carregava o marcador de recusa). O `deferred` ganhou
  um `grep` PRÓPRIO em vez de a linha do `human` virar `(human|deferred)`: (a) só um ramo próprio
  pode NOMEAR o bug, e (b) mover a linha do `human` apodreceria as âncoras de
  `QA_bug_genre_{ignored,prefix}`. Verificado depois da mudança — as quatro âncoras antigas ainda
  casam 1, 1, 2 e 1 vez, e as seis mutações matam a asserção certa.
  ⚠️ Dívida DECLARADA no comentário do gate: a forma do campo está escrita duas vezes, a três
  linhas de distância. É a regex que duplica, nunca a decisão — o enum é decidido nesse único laço
  — e o ramo novo ganhou mutante próprio (`QA_bug_genre_deferred_prefix`) em vez de pegar carona.
- I4 — cinco regimes RED antes do código. O `sed` do seed nasceu com `|` de delimitador e o valor
  semeado CARREGA `|` (a legenda do enum) — mesma família do mutante do I3, terceira vez na missão.
  ⚠️ Correção de FATO do plano: o kit **tem** `docs/qa/templates/bug.md` (nasceu em `525b216`), então
  o `sdd preflight` daqui cai no ramo `ok` e não no `---` que o plano previa. Preflight segue verde,
  e a idempotência ficou provada num arquivo real: o install não tocou nele.
  ⚠️ A legenda daquele arquivo estava velha (`<!-- agent | human -->`); atualizada à mão. O
  instalador **não** reescreve legenda — limite declarado no comentário: o gate lê o VALOR.
  ⚠️ Uma frase do `preflight` foi reescrita para não conter `qa-report`: o `check-preflight.sh`
  afirma que um repo sem interface nunca vê esse token na saída, e alargar o sensor alheio para
  caber uma linha de prosa é a direção errada.
- I5 — ADR 0009 escrita em INGLÊS: `docs/` é a superfície inglesa do kit e o `check-lang.sh` cobra.
  ⚠️ O stub do `sdd adr new` manda escrever "in OUTPUT_LANG=pt-BR" — correto para repo-alvo, errado
  para o kit, onde produziria um arquivo que a suíte reprova. Falha ALTO (não é fail-open), então
  pela régua D15 é limite e não achado; fica registrado aqui.
  A rule § 6 já entrou no commit do I1, pela regra da própria rule.
- I7 — a catraca MOVE nesta missão, ao contrário do que o plano previu: 105 → **106**. Os quatro
  `RESOLVIDO` só saem do arquivo no chore pós-merge (não movem), mas a instância (a) do item `:647`
  — drift de comentário em código — **não fecha** e virou item próprio, como o plano admitiu que
  poderia. `HAT_WRITES_EXTRA` não é a saída dela: declarar `bin/sdd` para o chapéu da DOCS entrega
  o runner inteiro a quem não edita código.
  ⚠️ `RESOLVIDO por` entra **antes** da cauda `— descoberto por …` e dentro do teto de 8 linhas: é a
  convenção que o `check-todo.sh` cobra e que os fechamentos de `5e3c427` já seguiam. A primeira
  tentativa pôs a linha depois da cauda e deu 9 violações de forma.
  ⚠️ A célula do catálogo no `KAIZEN_LOG.md` diz **339 definidos** (contados por comando), nunca
  "0 sobreviventes" — esse veredito é do carimbo, que roda depois da revisão do PR.
