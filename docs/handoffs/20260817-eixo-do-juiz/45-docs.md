---
missao: 20260817-eixo-do-juiz
fase: DOCS
status: done
data: 2026-08-17 14:25
---

# Documentação — 20260817-eixo-do-juiz

> Uma linha por área que o diff tocou. `✅` carrega o hash do commit que atualizou o doc; `n/a`
> carrega justificativa concreta. Nenhum `✗` fica pendente.

## TL;DR

O diff que esta fase auditou é de **13 arquivos** fora de `docs/handoffs/` (`96a9bf1..5056709`;
com esta fase, 15 — entraram `CLAUDE.md` e `KAIZEN_LOG.md`), e as fases anteriores
sincronizaram a prosa no mesmo commit do conserto na maior parte dos casos — como o `CLAUDE.md`
manda. Mesmo assim esta fase achou **o drift mais caro da missão**, e ele nasceu da última rodada de
review: o F1 da r3 trocou a unidade do `degenerate_axis` de **sessões** para **missões** e
**oito dos dez lugares** que enunciam a unidade ficaram na velha — inclusive
`docs/adr/0003`, o único documento que o runner **cita na saída**, `agents/sdd-kaizen.md`, a folha
que o próprio juiz segue, e — os piores — **três comentários e a frase impressa dentro do próprio
`bin/sdd`**: a fonte da verdade tinha driftado de si mesma. O `jq` contava missões, o comentário
duas linhas acima dizia sessões, e o `warn` que o humano lê dizia "each bought exactly one session".

Fechados nesta fase, em `c53500b` (os 4 docs) e `43f7eb2` (as 4 de dentro do runner): a unidade
nos oito lugares, o modo de falha novo da C2 em
`docs/failure-modes.md` (ledger ilegível morre antes da sessão), o verbete **Eixo degenerado** no
`CONTEXT.md`, a forma de sessão de `--all-repos` no `README.md` e a armadilha do `CDPATH` na
`CLAUDE.md`. O registro do `KAIZEN_LOG.md` que o K8 do plano cobra e a escrituração do `TODO.md`
saíram em `9939fba`.

## Drift checklist

| Área tocada pelo diff | Documento correspondente | Status | Evidência |
|---|---|---|---|
| `bin/sdd` — `guard.degenerate_axis`: campo, frase impressa, janela, cláusula de alcance | `docs/pipeline.md`, `docs/adr/0003`, `agents/sdd-kaizen.md` + cópia `.claude/`, `CONTEXT.md`, `docs/failure-modes.md` | ✅ | nasceu com a prosa em `abac043`+`8f069f5`; a r3 reescreveu regra e ADR em `b03d2f8`; a **unidade** (missão, não sessão) chegou aos oito lugares que ficaram atrás em `c53500b`+`43f7eb2` |
| `bin/sdd` — a unidade do eixo é `missions_on($sha) == 1`, não `sessions == 1` (F1 da r3) | os dez lugares que enunciam a unidade, quatro deles dentro do `bin/sdd` | ✅ | `c53500b` (os 4 docs: `pipeline.md`, `adr/0003`, `agents/sdd-kaizen.md` + cópia, `failure-modes.md`) + `43f7eb2` (os comentários de `:2586`, `:2648`, `:2735` e o `warn` de `:2926`, que é o que o humano lê). **Oito dos dez** diziam "exactly one session"; só o `jq` estava certo, e o `CONTEXT.md` não enunciava unidade nenhuma. Conferido contra `bin/sdd:2620-2668` |
| `bin/sdd` — `--all-repos` nos dois parsers, ligando o predicado único | `README.md`, `docs/pipeline.md`, `usage()` do runner, `CONTEXT.md` | ✅ | `8f069f5` (a porta de volta à pergunta entre projetos, no pipeline e no README), `d0288fe` (glossário), `b03d2f8` (help e README na forma `--series`), `c53500b` (o README prendia a flag ao `--series` e omitia a forma de sessão, que é a que o F1 fez chegar às duas metades) |
| `bin/sdd` — `boot_prompt` propaga `--all-repos` ao prompt do juiz (F1 da QA) | `docs/pipeline.md` § kaizen loop, `agents/sdd-kaizen.md` | ✅ | `c5c9a9f` — os três lugares no mesmo commit, com o motivo escrito: uma metade com flag e a outra sem tornam a fase **insatisfazível**, não só imprecisa |
| `bin/sdd` — `ledger_repo_root`: identidade é o `.git` comum, `core.bare`, `CDPATH=''` | `docs/pipeline.md`, `docs/failure-modes.md`, `CONTEXT.md`, `CLAUDE.md` § armadilhas | ✅ | `8f069f5` (worktree não é outro repo), `d0288fe` (o ⚠️ do **pai** do `.git` e o strip só em repo não-bare, nos três docs), `c53500b` (a armadilha do `CDPATH` entra na seção que cataloga as outras quatro da mesma família). A troca de `--is-bare-repository` por `core.bare` em `3ef0753` **não** devia doc: a prosa descreve o comportamento (strip só quando não-bare), que o conserto preservou ao trocar quem responde |
| `bin/sdd` — `excluded.no_repo`, quinto balde nos dois produtores da shape | `docs/pipeline.md`, `CONTEXT.md`, `agents/sdd-kaizen.md` | ✅ | `4ca8015` (o próprio commit do I5 já levou a prosa do pipeline e do agente, como a `CLAUDE.md` manda), `8f069f5`+`d0288fe` — "nasceu em outro repo" e "não diz de onde veio" ficaram descritas como acusações diferentes, e a quarta voz de "no data" está no texto |
| `bin/sdd` — `ledger_parses` + `GATE_KAIZEN_UNREADABLE`: corrupção deixa de virar pendência | `docs/failure-modes.md` | ✅ | `c53500b` — seção nova, medida no runner real: linha truncada ⇒ rc 1 e **zero** sessão; antes o gate lia string vazia e gastava uma opus |
| `bin/sdd` — `mission_key` = `(repo, missão)`, definição única movida para cima | `CONTEXT.md`, `agents/sdd-kaizen.md`, `docs/pipeline.md` | ✅ | `d0288fe` — o ⚠️ de "slug sozinho não chaveia" está nos três, e o `detail` nomeando o próprio `repo` também; `b03d2f8` reverificou quando a r3 moveu o `def` para cima do `degenerate_axis` |
| `docs/adr/0003-judge-axis-evidence-from-target-repos.md` (arquivo novo) | `CONTEXT.md` § decisões (D4), citação obrigatória no `bin/sdd` | ✅ | `3547a83` (ADR + as 2 asserções, uma delas exigindo a citação no código), `b03d2f8` (D4 reaberta e fechada de novo), `c53500b` (a consequência do ADR passou a citar a unidade certa) |
| `tests/check-kaizen.sh`, `tests/check-autonomy.sh` — asserções novas e fixtures | — | n/a | nenhum doc descreve asserção individual, por decisão: o contrato dos **prefixos** vive no `checkpoint.md` da missão (que os Checks contam com `grep -c`) e cada sensor documenta as próprias regras no cabeçalho. Doc externa aqui seria uma sétima cópia a driftar |
| `tests/check-mutation.sh` — catálogo 55 → 70 | `CLAUDE.md` § TDD | n/a | a regra "gate novo entra com mutação" **não mudou**, e a `CLAUDE.md` deliberadamente não fixa o número: "o número de hoje sai da linha `score:` do `run-all.sh`, e fixá-lo aqui era uma data de validade escrita à mão" |
| `tests/check-lang.sh` — piso de vacuidade 33 → 36 | `CLAUDE.md` § Idioma | n/a | o mecanismo descrito (sensor + catraca bidirecional em `lang-allowlist.txt`) não mudou; o número da catraca mora no cabeçalho do sensor, onde a r1 o recontou contra a superfície real |
| `README.md`, `CONTEXT.md`, `docs/pipeline.md`, `docs/failure-modes.md` — tocados pelo próprio diff | eles mesmos | ✅ | reauditados nesta fase contra o `bin/sdd` do HEAD, não contra o que as fases anteriores afirmaram: é essa releitura que achou os oito lugares na unidade velha e o modo de falha da C2 sem seção |
| `TODO.md` — 4 itens fechados, 1 aberto por refutação, 4 novos na missão (2 nesta fase) | ele mesmo, e a triagem do `sdd kaizen` que o lê | ✅ | `9939fba` — detalhe na seção "Achados do `TODO.md`" abaixo |
| `KAIZEN_LOG.md` — a missão mede antes/depois | ele mesmo (K8 do checklist kaizen) | ✅ | `9939fba` — 9 linhas de antes/depois medidas, mais a subseção do drift de unidade e a do que ficou sabido e não foi consertado |
| `docs/handoffs/20260817-eixo-do-juiz/*` | — | n/a | artefatos da missão, não documentação viva: descrevem o que aconteceu numa data e não são lidos como instrução pela próxima sessão |

## Achados do `TODO.md` desta missão

**Os 5 itens da métrica do `00-missao.md`: 4 fechados, 1 aberto com o motivo escrito.**

| Item | Situação |
|---|---|
| A guarda do juiz é insatisfazível quando o kit desenvolve a si mesmo | `RESOLVIDO por 3547a83+abac043` |
| Worktree do git parte a identidade do repo no ledger | `RESOLVIDO por c514e36+913cb3f` |
| Linha sem `repo` é "local" em TODO repo | `RESOLVIDO por 4ca8015` |
| O juiz no repo do kit deixou de enxergar missão de repo-alvo | `RESOLVIDO por d62f08c` |
| O lembrete pós-pipeline manda o humano a um comando que não enxerga o que ele contou | **aberto, deliberadamente** |

⚠️ **A quinta métrica não foi cumprida, e estampá-la seria rótulo sem artefato.** O lembrete só é
chamado de `cmd_run`, e `sdd run` não tem `--all-repos` (morre em qualquer `-*` desconhecido), então
a flag desta missão **não** o alcança. A EXEC do I3 e a r3 mediram isso e escreveram o motivo no
corpo do item, que é a conduta certa: fechá-lo exige responder se o juiz pode pesar linha de outro
projeto — possível **ADR 0004**, e é ele que destrava o I13.4. O `00-missao.md` fica com a métrica
como planejada e este handoff com a leitura real; corrigir a métrica depois do fato é apagar a
evidência de que uma previsão do plano estava errada.

**Um marcador de fechamento estava invisível para a triagem.** No item do eixo degenerado a palavra
`RESOLVIDO` terminava uma linha e `por` começava a seguinte. A triagem do kaizen procura
a frase inteira (`agents/sdd-kaizen.md:110`, e a `CLAUDE.md:63` a declara convenção), então
`grep -c 'RESOLVIDO por'` via **3** itens onde havia 4: item fechado que a próxima sessão leria como
aberto, e que o plano nascido não listaria para apagar. Reencapado. A classe é a de sempre nesta
casa — convenção lida por `grep` sem sensor que a meça —, e o `tests/check-todo.sh` mede âncora,
data e tamanho, não isto.

**Itens bem formados verificados** (o quê + `arquivo:linha` + por que importa + quem descobriu e
quando, dentro do teto de 8 linhas): os dois que esta missão abriu — `sdd kaizen` recusando rodar de
um worktree do próprio kit (`bin/sdd:2735`, achado pela EXEC do I4, a mesma classe que o I4 fechou no
ledger e viva na porta vizinha) e a regra que manda sincronizar `.claude/agents/` sem dizer que `cp`
e Edit são barrados (achado pela EXEC do I2 e reencontrado pela EXEC do F1). Os dois passam
`tests/check-todo.sh`, que fecha em `69 finding(s), all within 8 lines and carrying anchor + date`.

**Escrituração feita nesta fase:**

- o item "o schema da série não tem sensor de drift contra a prosa que o descreve" foi de **seis**
  lugares para **dez** e de 5× para **6×** de preço cobrado: `docs/failure-modes.md` nunca estava no
  inventário, e contar `bin/sdd` como **um** lugar era grosseiro demais — ele enuncia a própria regra
  em três comentários (`:2586`, `:2648`, `:2735`) e na frase que imprime (`:2926`), e os quatro
  driftaram do `jq` que fica entre eles. Âncoras reancoradas contra o HEAD;
- item novo: o `kaizen_axis_note` jura em comentário que não repete o piso "para não criar uma
  terceira cópia de um número que o `jq` já possui", e duas linhas abaixo imprime "The floor of 3
  missions per kit version". É a cópia que drifta calada no dia em que o piso mudar, e a única voz
  do schema que o humano lê em voz alta;
- o item do `sdd kaizen` em worktree foi reancorado de `bin/sdd:2735` para `:2963` — a âncora velha
  caiu justamente no comentário mentiroso acima, e foi assim que ele apareceu. Âncora podre não é só
  ruído: seguir uma até o lugar errado foi o que achou os dois drifts de dentro do runner;
- ⚠️ **um item que eu abri foi retirado por ser duplicata, e o achado da duplicata vale mais que ele:**
  a contagem de `selftest` da `CLAUDE.md` (cinco escritos, seis medidos) **já estava no `TODO.md`**,
  aberta pela fase DOCS da missão anterior no dia anterior, ancorada em `CLAUDE.md:135`. Escrevi a
  minha sem grepar o arquivo pelo tema primeiro — e o `tests/check-todo.sh` mede forma, âncora, data
  e teto, **nunca duplicata**, então as duas passariam verdes lado a lado para sempre, cada uma
  parecendo confirmar a outra. Não virou item novo: registrar "o TODO aceita duplicata" como achado
  do arquivo que aceita duplicatas seria a piada se repetindo. Fica aqui, e a conduta que ele ensina
  é de uma linha: **grepar o tema no `TODO.md` antes de abrir item**;
- item novo: o `KAIZEN_LOG.md` não fixa o instrumento das próprias linhas, e uma delas já mentiu.
  A entrada anterior registra **490** asserções para um `main` que mede **435** pela âncora de quatro
  espaços. O tree é o mesmo (`git diff c821ade..96a9bf1 -- tests/ bin/sdd` **vazio**: só docs
  mudaram entre a medição e o merge), então nada caiu — `490` é `grep -c '^  ok'`, que soma às
  asserções de sensor as **55** linhas `  ok   ` de **três** espaços que o runner imprime dentro dos
  fixtures. Achado ao tentar preencher a coluna "Antes" desta missão com um número medido em vez de
  copiado; os dois lados foram remedidos com a âncora de quatro espaços, sequencialmente, `main` num
  worktree descartável: **435 → 509**. É a mesma classe do `^  ok    ` que os Checks do
  `checkpoint.md` obrigam, aplicada ao arquivo que guarda a memória das medições.

## Disclosure progressiva

Nenhum índice cresceu para carregar profundidade. O `README.md` ganhou **uma** linha e meia de
comentário na lista de comandos, roteando; a profundidade de `--all-repos` está no
`docs/pipeline.md` e no `usage()`. No `CONTEXT.md` a operação foi de **movimento, não de adição**: a
célula de "Série" carregava seis linhas sobre o `degenerate_axis` e passou a roteá-lo para o verbete
próprio **Eixo degenerado**, que é o termo que a missão trouxe para a linguagem ubíqua (D1 do
checklist DDD do plano) e que agora é achável pelo nome. A `CLAUDE.md` ganhou um parágrafo na seção
que já cataloga as outras quatro armadilhas da mesma família — a alternativa era um documento novo
que ninguém leria no momento em que escreve um `cd`.

⚠️ **Proposta de split registrada, não executada:** medido, "The autonomy ledger" (149 linhas) +
"The kaizen loop" (94) somam **243 de 568** do `docs/pipeline.md` — **43%** do índice do pipeline
para um subsistema só, e esta missão engordou as duas seções. Está no `TODO.md` como direção
(`references/` para o ledger + juiz, índice roteando), não como conserto: refatorar a estrutura de um
doc alheio no meio desta missão é exatamente o que a regra da fase proíbe.

## Estado ao fim da fase

- **Commits:** `c53500b` (os cinco drifts de unidade + o modo de falha novo + verbete + README +
  armadilha do `CDPATH`), `9939fba` (`KAIZEN_LOG.md` + escrituração do `TODO.md`),
  mais o commit deste handoff.
- **Suíte:** ✅ **VERDE** com as edições de doc dentro. `bash tests/run-all.sh` → `suite green`,
  `509 ok`, `score: 70 caught, 0 known gap(s), of 70`, rc 0. `tests/check-lang.sh` verde nos dois
  sentidos (`0 of 36 surface path(s) still in the allowlist, 0 new`) — as edições em `docs/`,
  `agents/` e `README.md` são inglês, e as de `CLAUDE.md`, `CONTEXT.md`, `TODO.md` e `KAIZEN_LOG.md`
  são `OUTPUT_LANG=pt-BR`.
- **`.claude/agents/sdd-kaizen.md` byte-idêntico** a `agents/sdd-kaizen.md`, sincronizado por
  `./bin/sdd install --force` (o harness barra escrita direta em `.claude/`) e conferido por `cmp -s`.
- **Métricas do `00-missao.md` remedidas ao vivo nesta fase:** `degenerate_axis: true` com
  `sufficient: false` no repo do kit; `sdd kaizen --dry-run` citando `ADR 0003`; `other_repo`
  **11 → 0** entre `sdd autonomy` e `sdd autonomy --all-repos`, 57 linhas locais de 68; catálogo
  **70** contra os 60 do alvo.
- **Árvore limpa. Nada empurrado, nenhum PR aberto.** A fase PR é a próxima.
