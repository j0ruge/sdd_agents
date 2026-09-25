---
missao: 20260925-o-sensor-le-o-que-a-ancora-diz
titulo: o sensor do TODO passa a ler o que a âncora diz, o teto de linhas deixa de ter um atalho, e o TEST_CMD deixa de ser certificado por grafia
data: 2026-09-25
versao: n/a — JIRA_ENABLED=false
branch: feat/todo-esqueleto-neutro
aprovacao: humano-2026-09-25
adr: docs/adr/0011-ancora-do-todo-carrega-simbolo.md
ddd: n/a
---

# Missão — o sensor lê o que a âncora diz

> Escrito pelo `sdd-planner` em 2026-09-25. O humano respondeu o grill pela sessão coordenadora, que
> repassou as respostas do AskUserQuestion. Este arquivo é a única fonte da **intenção**; o
> `01-plano.md` é a fonte do **como**.
>
> ⚠️ **A execução é INTERATIVA** (Opus + `superpowers:executing-plans`) e **nunca `sdd run` no
> kit**. Pela memória do projeto, o `claude -p` aninhado herda o socket do harness e morre, e o kit
> se sabotaria editando o `bin/sdd` que o executa.
>
> ⚠️ **A branch é a CORRENTE, `feat/todo-esqueleto-neutro`.** Foi decisão humana: um PR só, junto
> com os três commits que já estão nela (`3286c2f` esqueleto do `TODO.md` por marcador, `07e47f6`
> achado do teto de 8 linhas, `5cb0101` `TEST_CMD` Node com lint/typecheck/build). Ainda não há PR.
> Não crie outra branch.

## Problema (Gemba)

São quatro famílias de defeito, todas medidas em `5cb0101`. Os números de linha estão no
`01-plano.md`.

1. **O teto de 8 linhas tem um atalho.** A regra 5 do `tests/check-todo.sh` conta linhas **físicas**
   (`nlines`), e nunca o comprimento delas. Medido: um item de 1794 caracteres numa linha física só
   passa com `ok 1 finding(s), all within 8 lines`, rc 0. O `TODO.md` do kit, hoje, não tem nenhuma
   linha acima de 120 caracteres na seção aberta; a maior tem 115.
2. **O selftest do `check-todo.sh` diz medir o que não mede (#70), re-medido depois da reescrita
   por marcador.** Três afirmações seguem abertas:
   - (a) trocar a contagem de violações pela constante `3` passa verde, porque o fixture tem
     exatamente 3;
   - (c) tirar o `flush()` do ramo da caixa marcada passa verde, porque o selftest não percebe que
     5 violações viram 3;
   - (d) o probe `--check ''` é vácuo quando não existe `$ROOT/TODO.md`.

   A afirmação (b), o `^## Aberto`, sumiu com a reescrita, mas o equivalente dela sobrevive: apagar
   o `^` ou o `[[:space:]]*$` do `OPEN_MARKER_ERE` passa verde. Com isso, um marcador indentado ou
   citado conta `0` com rc 0, onde o certo é rc 99.
3. **As âncoras do `TODO.md` apodreceram, e o sensor só mede a forma delas (#86, #136).** A regra
   aceita qualquer crase antes da cauda e nunca abre o arquivo. Medido: das 85 âncoras `arquivo:N`
   com N maior que 1, **63 apontam para o código errado**. Todas as 85 estão dentro do arquivo,
   então a regra óbvia, "existe e está no intervalo", reprovaria **0**. Quatro itens estão velhos
   além da âncora: o `review_scope_check` não existe mais, o `RESOLVIDO` saiu do cabeçalho, um piso
   foi de 12 para 36, e um item diz que o sensor "confere que existe" quando ele nunca conferiu.
4. **O `TEST_CMD` é certificado por grafia, e mal.**
   - **#116:** a checagem 2b do `sdd health` lê o config num subshell com `>/dev/null 2>&1`, então
     um config que não parseia vira `declares no TEST_CMD`. São **sete** sítios que sourceiam o
     config por uma chave só, e todos engolem o erro de parse.
   - **#118:** tanto a regra do `--list` (health 2b) quanto `test_cmd_looks_noop` (preflight)
     casam só espaço. Com TAB antes de `--list`, ou com `"--list"` entre aspas, as duas dizem `ok`,
     e o `eval` entrega `--list` à suíte.
   - **#53:** numa missão greenfield em que o I1 cria o `package.json`, o preflight dá `fail` com
     rc 254 e uma frase falsa, "a red suite makes the EXEC phase unsatisfiable".
5. **O `check-templates.sh` é o único sensor que imprime `ok` com três espaços (#151)**, e o
   `calibrate()` do `check-checkpoint.sh` não o vê: ele só lê linhas `pass() { printf '`, e o
   `check-templates.sh` não tem `pass()`.

## Métrica

Fatos binários, todos lidos por comando no `01-plano.md` § Verificação end-to-end:

- Um item de uma linha física com 121 caracteres ou mais reprova o `check-todo.sh`. Um item com 120
  caracteres **acentuados**, que passam de 120 bytes, passa.
- O selftest do `check-todo.sh` fica **vermelho** em cada uma das sabotagens a, c, d, b1 e b2 do #70.
- `bash tests/check-todo.sh --anchors TODO.md` reporta **0 off target**, e o lint padrão cobra a
  regra da âncora: o selftest fica vermelho sob a sabotagem de cada sub-regra.
- As **63** âncoras erradas foram re-derivadas, e os 4 itens velhos, reescritos.
- `sdd health` num config que não parseia diz "does not parse", com o stderr. Nenhum dos 7 sítios
  engole mais o erro.
- TAB e aspas antes de `--list` são recusados pelas duas regras, health 2b e preflight.
- Preflight greenfield (`npm test` sem `package.json`) dá `warn`, não `fail`. Com manifesto e suíte
  vermelha, segue `fail`.
- O `check-checkpoint.sh` imprime `(9 sensor(s))`. O `check-templates.sh` não tem mais nenhuma
  linha `ok` de 3 espaços.
- A catraca `todo-findings` é igual ao `--count`: −1 pela fusão do `:665` no `:523`, +1 pelo
  achado do stub do `sdd adr new` (ver Pendências), o que dá 100, mais qualquer movimento anotado
  na re-ancoragem. Os sete itens consertados levam `RESOLVED by <hash>`.

## Resultado esperado

Uma âncora de achado que perde o alvo reprova a suíte na mesma corrida que a moveu, e a mensagem
diz a linha certa. O teto de linhas de um item não pode mais ser contornado juntando tudo numa
linha. O selftest do `check-todo.sh` passa a ficar vermelho em cada sabotagem que o #70 listou. O
`sdd health` e o `sdd preflight` passam a dizer a verdade sobre o `TEST_CMD`: config que não
parseia, `--list` escondido por TAB ou aspas, e projeto que ainda não tem manifesto. O
`check-templates.sh` passa a falar o mesmo `ok` que os outros quinze sensores, e o
`check-checkpoint.sh` passa a vigiar isso.

## Fora de escopo

- **Renomear `aprovacao`/`versao`/`titulo` e `00-missao.md`/`01-plano.md`:** fica no item
  `TODO.md:515`, porque quebra missões em voo.
- **Variante `en` dos templates:** fica no item `TODO.md:523`, onde o `:665` é fundido. Não se
  traduz nada nesta missão.
- **Âncoras secundárias** (`(+ outro/arquivo:N)`): a regra mede só a primeira âncora do item. O
  limite é declarado no cabeçalho do sensor e na ADR 0011.
- **A seção decidida:** a regra da âncora vale só para a seção aberta.
- Qualquer achado novo durante a execução vai para o `TODO.md`, com a catraca movida no mesmo diff.

## Gate PLAN-AUTO

| # | Critério | Status | Evidência |
|---|---|---|---|
| a | Grill sem perguntas abertas não endereçadas (🚩 vazia ou itens deferidos com dono) | ✅ | Os 10 pontos do grill estão fechados (§ Decisões). Uma interpretação do planejador vai para as Pendências e não bloqueia. |
| b | Checklist kaizen 100% ✅ e checklist DDD 100% ✅ ou `n/a` justificado | ✅ | Tabelas abaixo; DDD `n/a` justificado. |
| c | Plano passa no teste de autocontenção (sessão nova só com 00/01/checkpoint executa) | ✅ | O I1 foi relido só com os três arquivos: função, linha, constante, formato de saída e o pitfall do `mawk` estão no `01-plano.md`. |
| d | Todo incremento do `checkpoint.md` tem Check executável (comando → esperado) | ✅ | 11 de 11. Todos em herestring, sem `\|` cru; os que leem sensor ancoram em `^  ok    `. |
| e | `versao:` confirmada pelo humano (ou `JIRA_ENABLED=false`) | ✅ | `JIRA_ENABLED=false`. |
| f | `adr:` é uma decisão — um caminho, ou o literal `none` (alocado por `sdd adr new`) | ✅ | `docs/adr/0011-ancora-do-todo-carrega-simbolo.md`, alocada por `sdd adr new`, com o corpo escrito. |

> `aprovacao:` fica **vazia** por instrução da sessão coordenadora: quem fecha o gate é o humano,
> com `sdd approve 20260925-o-sensor-le-o-que-a-ancora-diz`.

## Checklist kaizen (`kaizen-software`)

| # | Item | Status | Nota |
|---|---|---|---|
| K1 | Gemba — fui ver onde o trabalho acontece | ✅ | Os 4 defeitos foram reproduzidos em `5cb0101` com fixtures em scratch. As 85 âncoras foram auditadas uma a uma e cada sabotagem do #70 foi aplicada. |
| K2 | Problema declarado com métrica | ✅ | Seção Métrica: fatos binários mais os contadores 63 → 0 âncoras fora do alvo e 8 → 9 sensores calibrados. |
| K3 | Desperdícios identificados e cortados | ✅ | Renomear as chaves e traduzir os templates saem. A regra "existe/intervalo" (0 de 85) é descartada por medir nada. O item duplicado `:665` é fundido. |
| K4 | Fatiamento incremental, cada fatia verificável | ✅ | 11 incrementos. A regra da âncora nasce num modo de relatório (I3), o TODO é re-ancorado (I4, I5) e só então ela entra no lint (I6), sem suíte vermelha no meio. |
| K5 | Check por artefato (rótulo ≠ artefato) | ✅ | Todo Check lê a saída do sensor ancorada em `^  ok    `, ou uma contagem com testemunha de que o sensor rodou. |
| K6 | Jidoka — o que para a linha está definido | ✅ | `tests/run-all.sh` vermelho para. Uma sabotagem que sobrevive também para: vira probe antes de avançar, ou limite declarado se o humano decidiu assim (b4/b5). |
| K7 | SDCA — a melhoria vira padrão (doc/rule/teste) | ✅ | Regras novas no sensor, com selftest; mutantes no catálogo para o `bin/sdd`; o formato no `templates/todo*.md`; a ADR 0011. |
| K8 | Registro no KAIZEN_LOG | ✅ | O I11 escreve a entrada com antes/depois: 63 → 0 âncoras erradas, 1794 caracteres aceitos → recusados, 8 → 9 sensores calibrados. |

## Checklist DDD (`ddd`) — condicional

`n/a — sem toque de domínio`: a missão mexe em sensores bash, em mensagens de `health`/`preflight`
e no formato de um arquivo markdown. Não há aggregate, bounded context nem evento novo. O único
contrato tocado, a gramática da âncora, está decidido na ADR 0011.

## Decisões do grill (não re-litigar)

1. **Escopo B:** entram o check-todo (1800 caracteres + #70), as âncoras (#86/#136) e o `TEST_CMD`
   (#116/#118/#53). A família dos templates fica reduzida ao #151 mais o ponto cego do
   `calibrate()`. O item `TODO.md:665` é **fundido** no `:523`, e a catraca desce 1. Renomear
   `aprovacao`/`versao`/`titulo` está **fora**. Porquê: as famílias 1–3 são defeitos de sensor que
   falham aberto; a tradução é trabalho de tamanho, não de risco.
2. **Regra 5:** a contagem física fica, e passa a ser recusada qualquer linha física acima de **120
   CARACTERES** (não bytes) na seção aberta. Porquê: nenhuma violação hoje, e o `mawk` conta bytes,
   onde leria 166 falsas acima de 100.
3. **#70:** são fechados (a) com um segundo fixture de contagem diferente, (c) com um probe do
   `flush()` da caixa marcada, (d) com um probe sem `TODO.md`, e os sobreviventes do marcador b1
   (sem `^`) e b2 (sem `[[:space:]]*$`) como probes do selftest. b4/b5 só mudam a mensagem e viram
   **limite declarado** no cabeçalho (régua D15). O item do #70 é apagado depois do merge. Porquê:
   b4/b5 continuam vermelhos, só com outro texto.
4. **Regra da âncora = símbolo + distância:** o item cita em crase um símbolo que o `grep` acha no
   arquivo ancorado, e o N fica a até **10 linhas** de uma ocorrência dele. A âncora é resolvida
   contra o repo do arquivo **checado**, nunca contra o `$ROOT`. Entra com selftest e passada de
   sabotagem adversarial, e o `TODO.md` é re-ancorado em lote (#136). Porquê: medido, "existe e está
   no intervalo" reprova 0 de 85, e o termo do título a ±10 reprova âncoras certas.
5. **A re-ancoragem re-verifica o CONTEÚDO** dos itens velhos e corrige o texto deles, uma nota por
   item: `review_scope_check`, `RESOLVIDO`, o piso de 12 para 36, o "confere que existe" e qualquer
   outro achado no caminho.
6. **#116:** um helper só, `config_read_key` (`bash -n`, "does not parse" mais o stderr), usado nos
   sete sítios. Porquê: é a regra "uma definição por programa" do `CLAUDE.md`.
7. **#118:** um predicado compartilhado, que normaliza espaço em branco e aspas, usado pelo health
   2b e pelo `test_cmd_looks_noop`. Isso **reverte** a "duplicação deliberada" que o comentário
   perto de `bin/sdd:3935` declara, e o comentário é atualizado no mesmo commit.
8. **#53:** o `fail` rebaixa para `warn` de forma **estreita**: só quando o runner do `TEST_CMD`
   (npm/yarn/pnpm/cargo/go/pytest) não tem o seu manifesto na raiz do repo. A mensagem diz que é
   esperado se o I1 cria o scaffold. Em qualquer outro caso, o `fail` fica.
9. **#151:** o alinhamento para quatro espaços passa por um helper `pass()`, **e** o `calibrate()`
   do `check-checkpoint.sh` passa a cobrir o `check-templates.sh` como o 9º sensor.
10. **ADR sim:** `docs/adr/0011-ancora-do-todo-carrega-simbolo.md`, alocada por
    `sdd adr new --slug ancora-do-todo-carrega-simbolo`.
11. **Execução interativa** (Opus + executing-plans), **nunca `sdd run` no kit**.
    - Item consertado ganha `RESOLVED by <hash>` e é apagado depois do merge, provado por
      `git merge-base --is-ancestor`.
    - O PR leva `Closes #53`.
    - Depois do merge, o espelho de issues é re-sincronizado com a skill `todo-to-github-issues`.
    - `sdd health` roda **uma vez**, depois de todos os revisores do PR.

## Pendências para o humano

- **Interpretação do planejador, não perguntada no grill:** a âncora sem linha, ou com `:1`, é
  tratada como âncora de arquivo inteiro e passa quando o símbolo ocorre **em qualquer lugar** do
  arquivo. Porquê: a decisão 4 fala em "N a ±10 linhas", e para `:1` isso forçaria todo item de
  arquivo inteiro a citar algo das dez primeiras linhas. Está registrada na ADR 0011, § Decision 2.
  Se o humano discordar, muda o I3 antes de ele rodar.
- **Achado de kit desta sessão de planejamento, sem item ainda:** o stub do `sdd adr new` manda
  escrever o corpo "in OUTPUT_LANG=pt-BR", mas o `tests/check-lang.sh` varre `docs/adr/*.md` como
  superfície inglesa. Seguir o stub deixaria a suíte vermelha. A ADR 0011 foi escrita em inglês. O
  I11 registra o achado no `TODO.md`, com a catraca no mesmo diff.
