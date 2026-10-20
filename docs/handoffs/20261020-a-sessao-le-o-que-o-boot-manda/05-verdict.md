---
verdict: melhorou
kit_sha_judged: bad6168
date: 2026-10-20
---

# Veredito — o lote 7, sobre `bad6168`

Todos os números abaixo saem de `sdd kaizen --series`, lido uma vez nesta sessão com a linha que o
prompt de boot entregou (`"/home/joruge/repos/sdd_agents/bin/sdd" kaizen --series`). A contagem de
intervenções (D12/D16) não está na série: sai de `sdd autonomy --all-repos --by-mission` e vai citada
onde aparece. Os fatos que nenhum dos dois comandos imprime (o motivo de cada escalada, o reflog do
kit, as leituras negadas pelo harness) foram lidos no ledger, no `pipeline.log` e nos logs de sessão
dos alvos, e vão marcados como tal. Nenhum número da série foi recalculado.

## A resposta curta

**`melhorou`.** O que o lote 7 prometeu, o uso real entregou: o ritual da QA à mão sumiu (0 linhas
`manual` na fatia, contra 3 na anterior, que eram 3 das 5 intervenções dela). A única missão com
`qa: skipped` fechou a QA sem humano, em uma sessão de US$ 1,44. O reteste depois de um `F<n>` rodou
três vezes pela rota nova, sem chamar a ferramenta `Skill`.

Os agregados **não** mostram a melhora sozinhos: `advance_rate` 0,98 → 0,97, `refez` 2 → 4 e
intervenções 5 em 5 missões → 8 em 4. O `melhorou` vem da decomposição por causa: nenhum dos
quatro `refez` nem das oito intervenções nasce da mudança julgada. Duas causas ficam com o humano
(emenda do plano e REVIEW forçada, no lighthouse). Uma é um Jidoka bom. E duas lacunas do kit,
anteriores ao lote 7, passaram a aparecer nesta janela porque ela entrou em repositórios novos. A
mais cara delas, a fase que não consegue ler o que o boot manda ler, vira a missão nascida nesta
pasta.

## Que mudança está sendo julgada

`previous.kit_sha` = `0270727` (merge do PR #244, lote 6; `kit_shas_raw` = `4f16a6d`, `f0b46fa`) e
`latest.kit_sha` = `bad6168` (merge do PR #252, lote 7, ADR 0018).
`git log --first-parent 0270727..HEAD -- bin agents templates config` devolve **uma** versão de
comportamento só, `bad6168`. A janela de congelamento (D11) foi respeitada nos caminhos que o eixo lê.

O lote 7 é uma mudança lógica só: a rota da QA para o `qa: skipped` (§1), o reteste depois de um
`F<n>` (§2), o frescor do `30-handoff-qa.md` cobrado pelo `gate_QA`, o K8 cobrado pelo `gate_DOCS`
(§4), o carimbo de hora tirado de `date` em toda fase, a gramática do id da missão e o aceite do
`/sdd-plan` que conta as respostas recomendadas (§3).

`latest.kit_shas_raw` lista **oito** shas crus: `bad6168`, `cb624d1`, `fec0cca`, `3208161`, `370b95f`,
`d5c45cc`, `d19f5b0` e `6a72673`. Os sete depois do primeiro são os lotes 8, 9 e 10, os chores do
`TODO.md` e as linhas do caderno de campo. Nenhum deles tocou `bin agents templates config`: os
diffs dos merges `47b9598`, `6f8bf1b` e `50c2f1e` mexem só em `tests/`, `docs/`, `commands/`,
`TODO.md` e `KAIZEN_LOG.md`. Antes da ADR 0014 isso partiria a janela em oito; aqui ela continuou
inteira. ⚠️ O eixo não lê `commands/`: o `/sdd-plan` que planejou as missões de 10-16, 10-17 e 10-18
já carregava as mudanças dos lotes 8 e 10. Essa diferença não aparece em número nenhum e fica dita
como limite.

## A composição

`latest.composition`: `/home/joruge/repos/sales_quote` 2 missões (2 com sessão),
`/home/joruge/repos/jrc-libs` 1 (1) e `/home/joruge/repos/lighthouse_project` 1 (1).
`previous.composition`: `/home/joruge/repos/sales_quote` 5 (5).

As somas fecham contra a guarda: 2 + 1 + 1 = 4 = `missions_after_change`, e 2 + 1 + 1 = 4 =
`missions_with_session`. Os três são repositórios-alvo reais. Não há clone descartável nem fixture sob
`/tmp`: é a evidência que a ADR 0003 pede.

**A mistura mudou de natureza, e isso pesa em toda comparação abaixo.** A `previous` era um repo só,
com três das cinco missões sem QA e de custo baixo. A `latest` traz dois projetos que a fatia
anterior não tinha. `lighthouse_project/20261014-amep-entrada-em-dois-niveis` sozinha soma 46
sessões e US$ 203,11 (`--by-mission`): 30 sessões de EXEC, duas emendas de plano depois do PR e
quatro rodadas de REVIEW. `jrc-libs/20261016-object-storage-distribuivel` é a **primeira** missão
daquele repositório e pagou o custo de instalação: 23 sessões, US$ 61,16. As duas missões do
`sales_quote` são o único pedaço comparável ao antes, repo com repo.

## A guarda

`missions_after_change: 4`, `missions_with_session: 4`, `sessions: 102`, `floor: 3`,
**`sufficient: true`**, `why: []`, `harness: ["2.1.296"]`, `window_missions_stranded: 0`,
`window_broken: false`, `degenerate_axis: false`.

- `why` vazio: nem `floor` nem `harness_mixed`, e a fatia julgada rodou inteira em 2.1.296. ⚠️ A
  `previous` rodou em **2.1.291**. A guarda olha a mistura dentro da fatia, não entre as fatias, e
  por isso digo eu: parte da diferença pode ser do harness. Para a causa mais cara desta janela eu
  tenho número que descarta o harness. As leituras negadas fora do repo (abaixo) já aconteciam no
  lighthouse em 2.1.278 (`20260921-amep-backend-0-1-0`: 7 sessões, 38 negativas nas referências da
  `codereview` e 4 nos templates do kit) e em 2.1.283 (`20260927-idioma-da-spa-pelo-idp`: 3 sessões,
  26 negativas na `codereview`), lidas nos logs de sessão sem contar `/tmp`.
- `window_broken: false` e `window_missions_stranded: 0`. Nenhuma missão gasta desde o último
  veredito ficou encalhada noutra versão, mesmo com sete merges no kit durante a janela. É a ADR
  0014 funcionando. A `lighthouse_project/20261013-amep-alignment-review` rodou entre os dois
  vereditos, mas com as fases todas à mão: cinco linhas `manual` sobre `0270727`, de 2026-10-13
  20:30 a 2026-10-14 15:41, lidas no ledger. Linha `manual` não conta como missão, então ela não
  encalha nem entra na série.

`excluded`: `non_comparable: 25`, `unrecognized: 0`, `meta: 8`, `other_repo: 0`, `no_repo: 0`.
`other_repo: 0` é o esperado desde a ADR 0005. `meta` subiu de 7 para 8 com a linha do juiz de
2026-10-12, e `no_repo: 0` diz que nenhuma linha sem projeto esvaziou a série.

## O antes e o depois

| | `previous` = `0270727` | `latest` = `bad6168` |
|---|---|---|
| missões (com sessão) | 5 (5) | 4 (4) |
| sessões | 66 | 102 |
| `outcomes` | 65 advanced · 1 churned · 0 idle | 99 advanced · 2 churned · 1 idle |
| `advance_rate` | 0,98 | 0,97 |
| `moved_rate` | 1 | 0,99 |
| rótulos | 25 ok · 0 leve · 2 refez | 20 ok · 0 leve · 4 refez |
| escaladas | `handoff-blocked: 1` · `hat-crossed: 1` | `handoff-blocked: 1` · `increment-blocked: 1` · `kit-touched: 2` |
| custo | US$ 192,06 | US$ 353,08 |
| `harness` | 2.1.291 | 2.1.296 |

A régua do `advanced` é a mesma nas duas fatias. As duas vêm depois de
`20260930-a-sub-etapa-que-andou`, o braço mais novo do yardstick, e nenhuma comparação aqui
atravessa troca de régua.

Custo por sessão, pela minha divisão dos números acima: ≈ US$ 2,91 → ≈ 3,46. A mistura explica a
alta: a missão do lighthouse é uma de 30 incrementos com quatro rodadas de REVIEW em opus. A
`previous` tinha ainda três QA feitas à mão, cujo custo nunca entrou no ledger.

Intervenções, de `sdd autonomy --all-repos --by-mission` (*intervenções = launches − 1*, D16):

- `previous` (veredito de 2026-10-12): **5 em 5 missões**, 3 delas o ritual da QA à mão.
- `latest`: `lighthouse_project/20261014-amep-entrada-em-dois-niveis` 7 → **6**;
  `jrc-libs/20261016-object-storage-distribuivel` 3 → **2**;
  `sales_quote/20261017-contratos-de-varredura-baratos` 1 → **0**;
  `sales_quote/20261018-silencios-do-formulario-e-dos-dialogos` 1 → **0**. **8 em 4 missões.**

## Por que isto é `melhorou`

1. **A fonte de intervenção que o lote 7 atacou secou.** Na `previous`, 3 das 5 intervenções foram
   o ritual da QA à mão. Na `latest` não há nenhuma linha `manual` sobre `bad6168` (lido no ledger).
   A única missão que declarou `qa: skipped`, `sales_quote/20261017-contratos-de-varredura-baratos`,
   foi de `PHASE QA reason="missing 30-handoff-qa.md"` direto a uma sessão `sdd-qa` de 196 s e
   US$ 1,44. A sessão conferiu a declaração contra o `git diff` e escreveu `status: skipped`, e a
   missão inteira rodou num lançamento só. Antes, a mesma forma de missão custava um `sdd note-manual`
   e um segundo `sdd run`.
2. **O reteste ganhou rota e foi usado.** No lighthouse, o `pipeline.log` registra o motivo novo
   `30-handoff-qa.md was not rewritten after F<n>` para o F1 (05:34), o F5 (09:18) e o F8 (09:58).
   Cada um abriu a sessão de reteste e depois o `QA:close`, sem humano. Nas 15 sessões de QA da
   fatia, as chamadas à ferramenta `Skill` são **0**, lidas no `.stream.jsonl` de cada uma. Na janela
   anterior houve cinco, em duas missões.
3. **O que mais o lote prometeu medir (M7 do `KAIZEN_LOG.md`) também passou:**
   - todos os 19 carimbos `data:` presentes nos handoffs das quatro missões caem dentro da janela da
     sessão da fase, de 0 a 4 min antes do fim dela. Na janela anterior havia carimbos com até 5 h
     de erro;
   - o leitor da D22 conta as respostas do grill nas quatro: `8 (recommended) of 8`,
     `10 (recommended) of 10` três vezes;
   - as quatro DOCS fecharam em uma sessão cada, com o K8 cobrado pelo gate.
4. **O repo comparável ficou melhor.** As duas missões do `sales_quote` fecharam com 0 intervenções,
   todas as 12 células `ok` e nenhuma sessão fora de `advanced` (`detail` da série). Na `previous`,
   com o mesmo repo, foram 5 intervenções em 5 missões e 2 células `refez`.
5. **Nada do que piorou nasce da mudança julgada.** As quatro escaladas, uma a uma:

- **`kit-touched` ×2, lighthouse, EXEC 01:44 e QA 09:42 de 2026-10-15.** Os dois motivos dizem
  `kit_before=bad6168 kit_after=cb624d1` e `kit_before=cb624d1 kit_after=fec0cca`. O reflog do
  checkout principal do kit mostra `merge origin/main: Fast-forward` às 01:40:47 e às 09:25:37, sem
  o rótulo `sdd:` de sessão nenhuma. Foi o operador puxando para o checkout principal do kit dois
  merges só de `docs/`, `TODO.md` e catraca (#246, #254), no meio de uma corrida do alvo. A guarda de
  kit compara o par cru `HEAD|sujeira`, de propósito (ADR 0014), e não lê o rótulo, que é limite
  declarado na anatomia §6. Deu 2 `refez` (EXEC e QA, as duas fases com 100% `advanced`) e 2 das 6
  intervenções do lighthouse. A causa é anterior ao lote 7 e agora tem custo medido: vai ao
  `TODO.md` pela missão nascida (I2).
- **`handoff-blocked`, jrc-libs, TICKET 20:17 de 2026-10-16.** A sessão `sdd-ticket` escreveu
  `status: blocked` porque o harness negou três `Read`: `~/.claude/skills/ticket/references/start.md`,
  `campos.md` e `/home/joruge/repos/sdd_agents/templates/handoff.md`. Isso está no
  `permission_denials` do log da sessão. Ela se recusou, por escrito, a contornar a negativa com `cat`
  no Bash. O operador acrescentou `additionalDirectories` com esses dois diretórios ao
  `~/.claude/settings.json` às 20:19:38 (mtime) e relançou, e a terceira sessão passou. A lacuna é
  do kit e vira a missão (abaixo). É 1 `refez`, 1 sessão `churned` e 1 `idle`, as duas primeiras
  sessões de TICKET, e 1 das 2 intervenções do jrc-libs.
- **`increment-blocked`, jrc-libs, EXEC 22:07 de 2026-10-16.** O I8, um smoke no Google Drive real,
  achou um defeito do driver herdado do `sales_quote`: a sobrescrita duplicava o arquivo, 4 de 5
  vezes. Ele parou a linha em vez de mascarar. O humano decidiu (decisão 13), nasceu o I8a, e o I8
  fechou 26/0/0. **Jidoka bom**: o rótulo diz `refez`, e a alternativa era publicar uma biblioteca
  1.0.0 que perde escrita. É a sessão `churned` do EXEC e a outra intervenção do jrc-libs.
- As outras quatro intervenções do lighthouse são do humano, por escolha:
  - duas emendas de plano depois do PR (E1–E6 às 08:45, com os bugs de fila achados no reteste;
    E7–E8 às 14:50, com o P2 do Codex no PR #29);
  - duas REVIEW forçadas por `--phase REVIEW`, que o runner registrou como notas `intervention:` às
    10:14 e às 15:07, para revisar o código que entrou depois da r2.

  O `gate_REVIEW` continuava satisfeito pela r2, que não viu o F5–F8 nem o R3. O revisor que só
  aprovou o que viu é a mesma família do D21 ("só `F<n>` reabre"), agora do lado da REVIEW. Vai ao
  `TODO.md` pela missão nascida (I2).

## O que a série não vê — e vira o plano

A série gradua células; ela não vê **o que a sessão foi impedida de ler**. O `bin/sdd` grava a
contagem (`LAST_PHASE_DENIALS`, `bin/sdd:5164`, campo `denials` da linha de sessão), mas nenhum
leitor a mostra a ninguém. Lido nos logs de sessão (`permission_denials` de cada `.json`):

- **lighthouse**: 13 dos 47 logs (46 de fase e o `sdd close`) têm `Read` negado fora do repo. Foram
  6 em `$SDD_HOME/templates`, 40 nas referências da skill `codereview` (a r1 sozinha levou 30), 13
  nas das skills `qa-*` e 5 nas da `ticket`. A sessão de TICKET contornou lendo os mesmos arquivos
  com `cat` no Bash.
- **jrc-libs**: 4 dos 23 logs. Foram 14 negativas nas referências da `codereview` em 2026-10-17,
  **depois** do ajuste manual de 2026-10-16, que não cobriu o cache de plugins, mais 2 nos templates
  do kit e 4 na `ticket`. Outros 3 logs só têm negativas em rascunhos sob `/tmp` que a própria sessão
  criou pelo Bash, e ficam fora desta conta.
- **sales_quote**: 0 de 33. O `.claude/settings.local.json` dele tem `"Read(*)"`, posto à mão em
  algum momento, e é só por isso que as janelas anteriores, todas desse repo, nunca viram o defeito.

Reproduzi a causa às 11:41 num repo de rascunho, com as flags do `run_phase` (`acceptEdits`,
`--allowedTools Bash`) e sem as settings do usuário, em Claude Code 2.1.296.
`Read /home/joruge/repos/sdd_agents/templates/handoff.md` → `DENIED`, com `permission_denials` nomeando
o arquivo. Com `--add-dir` daquele diretório → lido. Às 11:42, a regra `Read(//<dir>/**)` passada
como segundo argumento de `--allowedTools` libera a leitura, e a escrita no mesmo diretório continua
negada. Já o `--add-dir` deixa escrever lá sob `acceptEdits`. As sete sondas, em haiku, custaram
menos de US$ 0,02 somadas.

É a segunda metade do princípio 1 aplicada à **leitura**. O `boot_prompt` manda toda fase partir do
template em `$SDD_HOME/templates/` "NEVER from memory" (`bin/sdd:3321`), e o runner não dá à sessão
a permissão de abri-lo. A fase então contorna pelo Bash, que é a classe que a fronteira do chapéu
pune quando o caminho é de escrita. Ou trabalha sem a referência: a REVIEW do lighthouse rodou a
`codereview` com 30 leituras negadas das próprias referências. Ou para, como o TICKET do jrc-libs,
que foi a sessão honesta. O `sdd preflight` responde "ok" nos três casos. Todo alvo novo bate nisso
(o `dotp-remake` e o `ui24_agent` estão na fila), e é por isso que este é o plano nascido aqui, à
frente de qualquer item aberto do `TODO.md`.

## Limites deste `melhorou`, ditos em vez de calados

- Os agregados não melhoraram (`advance_rate` 0,98 → 0,97, `refez` 2 → 4, intervenções 5/5 → 8/4).
  O veredito se apoia na decomposição por causa e no repo comparável, e diz isso em vez de citar só
  o número que ajuda.
- Mistura diferente: dois projetos novos, um deles estreando o kit, contra um repo só.
- Harness diferente entre as fatias (2.1.291 × 2.1.296), que a guarda não mede. Para a lacuna de
  leitura, a causa está descartada por medição. Para o resto, não.
- O eixo não vê `commands/`: o `/sdd-plan` dos lotes 8 e 10 planejou três das quatro missões.
- O comparável repo com repo são **duas** missões.

O que atribuo ao kit com segurança: o fim do ritual da QA à mão e o reteste com rota. O resto é
coerente com o kit não ter piorado, e as duas causas de kit que apareceram são anteriores ao lote
julgado.

## Uma leitura lateral: a régua da D22

O `--by-mission` imprime a parcela do laço de revisão das quatro missões: 27%, 28%, 46% e 23%. A
mediana, pela minha conta, dá 27,5% e o máximo 46%. Na janela anterior foram mediana 38% e máximo
43%. O máximo cabe no alvo da D22 (≤ 50%) e a mediana chegou perto (alvo ≤ 25%). O lote julgado não
mexeu no laço de revisão, então isto não entra no veredito; fica registrado para a próxima janela.

## O que isto autoriza

O veredito fecha a janela do lote 7: o kit pode descongelar depois do merge desta branch, que é
passo humano. A triagem do `TODO.md` está no `01-plano.md`:

- **26** itens abertos;
- **0** resolvidos a apagar, porque nenhum corpo aberto traz `RESOLVED by <hash>`;
- **0** saem pela régua D15, porque todos os 26 têm consumidor fora da suíte do kit.

A missão nascida fecha a lacuna de leitura e registra no `TODO.md`, com a catraca, os três achados
desta janela que não cabem nela.
