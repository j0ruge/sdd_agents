# Notas de execução — o número do ADR não é prosa

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

- 2026-09-17 14:47 · `PLAN` · plano aprovado em plan mode (grill de 9 perguntas + 3 injeções); execução será interativa numa sessão Opus, não por `sdd run` — decisão 10 do grill.
- 2026-09-17 14:47 · `PLAN` · `adr: TBD` no `00-missao.md` é deliberado: o I4 cria o ADR 0008 pelo próprio `sdd adr new --spec` e substitui o valor.

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
- 2026-09-17 · `I1` · desvio declarado: o `check-adr.sh` **não** tem modo `--check <arquivo>`. O selftest canônico existe para sensor que a mutação não alcança; este dirige o `bin/sdd` por subprocesso, então o catálogo o alcança. No lugar dele, piso de probes + controle negativo, com o porquê no cabeçalho do sensor.
- 2026-09-17 · `I1` · o `shellcheck` reprovou o esqueleto do plano: `ADR_LINK_RE`/`ADR_FILE_RE` nascidos sem leitor são SC2034. Foram adiados para o I2, que os lê — a regra "chave nova entra no commit que a lê" vale para constante também.
- 2026-09-17 · `I1` · `ADR_DIR=""` é inalcançável pela config (`: "${ADR_DIR:=docs/adr}"` dispara no vazio). O probe usa `ADR_DIR="/"`, que é alcançável e é o mesmo defeito (`hat_expand` corta a barra ⇒ `/**`); o mundo não construído está declarado no cabeçalho do sensor, nunca como "esse mundo não existe".
- 2026-09-17 · `I2` · a passada adversarial derrubou nove degradações (back-link cego, `Spec:` ausente cego, padrão do nome cego, arquivo ausente cego, `TBD` caindo no braço `none`, braço do `--phase` mudo, chave ausente aceita, `adr_fail` sem contar, só o dialeto em negrito lido). Todas vermelhas — está no cabeçalho do sensor.
- 2026-09-17 · `I2` · `grep -nE … | head -1` foi recusado na escrita: sob `pipefail` o `head` fecha o cano e o `grep` morre de SIGPIPE, então a captura responde 141 em arquivo grande e 0 em arquivo pequeno. Forma usada: `grep … || true` + `${hit%%$'\n'*}`.
- 2026-09-17 · `I3` · **decisão humana**: a regra (d) do plano (número solto `ADR NNNN` sem arquivo ⇒ FAIL) reprovava o PRÓPRIO kit — o `01-plano.md` desta missão cita `ADR 0042` (nome de probe) e `ADR 0030` (o ADR do outro repo, o assunto da missão). FAIL dentro de `SPEC_DIR` (onde o número é reivindicação), `info` em handoff (onde é narrativa). Reescrever o artefato aprovado para calar o detector foi recusado. O Check do I3 no checkpoint mudou de `... in 01-plano.md with no file fails` para `... in a spec with no file fails`, e o probe do lado `info` existe ao lado, diferencial.
- 2026-09-17 · `I3` · a segunda metade da regra (d) ("plano co-localizado citando ID diferente do declarado ⇒ FAIL") **não** foi implementada, com o porquê no cabeçalho do sensor: plano cita outras decisões legitimamente (este declara 0008 e cita 0003/0004/0007). Regra que grita lobo sob `block` transforma o gate inteiro em ruído.
- 2026-09-17 · `I3` · a passada adversarial achou TRÊS regras sem probe, e a terceira é a lição: `cmd_adr` lia `ADR_FAILS` **e** o rc do `adr_check_repo`. Dois leitores de um fato só ⇒ sabotar qualquer um deixa o outro respondendo, e NENHUM dos dois é pegável. Hoje só o rc é lido.
- 2026-09-17 · `I4` · o ADR 0008 nasceu do próprio comando (`sdd adr new --slug … --spec …`) e substituiu o `adr: TBD` na mesma chamada — o teste de bootstrap do mecanismo passou.
- 2026-09-17 · `I4` · achado novo, consertado no mesmo commit: o `check-lang.sh` lia a linha `Spec: docs/handoffs/20260917-o-numero-do-adr-**nao**-e-prosa/…` do ADR 0008 como prosa portuguesa. Linha de rastreabilidade é **dado** — é a string exata que o `sdd adr check` lê de volta, e `docs/handoffs/` está fora do escopo do sensor por declaração própria. Terceira exceção do sensor, com probe diferencial (rc 95) e as duas sabotagens vermelhas. A linha é **apagada**, não removida, para o `grep -n` continuar dando o número real.
- 2026-09-17 · `I4` · limite declarado no `adr_new`: o stub cita `OUTPUT_LANG` (aqui `pt-BR`), mas `docs/adr/*.md` é superfície **inglesa** do kit. No repo-alvo não há conflito. Não é achado pela régua D15 — nenhum sensor afirma medir o que não mede.
