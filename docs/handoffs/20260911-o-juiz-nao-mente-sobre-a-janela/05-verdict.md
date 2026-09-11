---
verdict: melhorou
kit_sha_judged: a0e34df
date: 2026-09-11
---

# Veredito — a janela 4, sobre `a0e34df`

Todos os números abaixo saem de `sdd kaizen --series`, lidos uma vez nesta sessão. A contagem de
intervenções (D12/D16) não está na série e sai de `sdd autonomy --all-repos --by-mission`, citada
onde aparece.

## Que mudança está sendo julgada

O eixo da série é o `kit_sha` cru, e `a0e34df` é o merge do PR #41. Como **uma** mudança lógica ele
abrange `6ad41f7..024d515` (PR #40, `fix/o-chapeu-sem-bash`) mais o chore de backlog
`9782006`: as regras de permissão saíram do `disallowedTools:` do chapéu para a chave
`permissionsDeny:`, o `sdd preflight` passou a disparar o chapéu do executor e ler `Bash` na linha
`init`, a linha `session` do ledger ganhou o campo `harness:`, e `status: blocked` no `10-ticket.md`
passou a parar a linha na primeira sessão. Julgo a mudança, não o sha.

Duas coisas pousaram **depois** e não estão nesta fatia: `a03cb25` (modo PLAN-only) e `ef7e22c`
(link do plano do time). Elas serão eixo da próxima janela, não desta.

## O antes e o depois

| | `previous` = `6b82c13` | `latest` = `a0e34df` |
|---|---|---|
| missões (com sessão) | 1 (1) | 3 (3) |
| sessões | 3 | 37 |
| `outcomes` | 0 advanced · 1 churned · 2 idle | **33 advanced · 4 churned · 0 idle** |
| `advance_rate` | 0 | **0,89** |
| `moved_rate` | 0,33 | **1,0** |
| rótulos | 0 ok · 0 leve · 1 refez | **11 ok · 3 leve · 2 refez** |
| escaladas | `no-progress: 1` | `budget-exhausted: 3` · `increment-blocked: 1` |
| custo | US$ 3,39 | US$ 264,40 |
| `harness` | (vazio) | `2.1.263` |

`guard`: `missions_after_change: 3`, `missions_with_session: 3`, `floor: 3`,
**`sufficient: true`**, `degenerate_axis: false`. É a primeira fatia em muitas janelas que satisfaz
o piso por artefato, e é o que autoriza um veredito que não seja `indeterminado`.

`excluded`: `non_comparable: 15`, `unrecognized: 0`, `meta: 4`, `other_repo: 0`, `no_repo: 0`. O
`other_repo: 0` é o esperado desde a ADR 0005 e o `no_repo: 0` diz que nenhuma linha sem projeto
esvaziou a fatia por baixo.

## A composição — de que mistura estes números são feitos

`composition` da `latest` tem **um único repositório**: `/home/joruge/repos/sales_quote`, com
3 missões e 3 delas com sessão. As duas somas fecham contra a guarda (3 = `missions_after_change`,
3 = o número em que o piso morde). A `previous` tem a mesma composição, com 1 e 1.

Isso importa mais do que qualquer taxa: a evidência vem inteira de um **repo-alvo real**, não de um
clone descartável nem de fixture sob `/tmp`, que é exatamente o que a ADR 0003 exige e o que o repo
do kit nunca consegue dar de si mesmo. Não há contaminação a descontar nesta fatia.

## Por que isto é `melhorou`

**A fatia `previous` É o defeito que `a0e34df` consertou.** Ela não é uma janela normal que foi
superada: são 3 sessões de uma fase TICKET só, `0 advanced`, `2 idle`, `moved_rate 0,33`,
`refez`, e uma escalada `no-progress` — o Claude Code 2.1.263 lendo `disallowedTools:` como nomes e
tirando o `Bash` inteiro de toda fase, US$ 3,39 gastos para não produzir nada. Depois da mudança, a
mesma fase TICKET lê `ok` em duas das três missões, e a terceira lê `leve`.

O que a `latest` diz por si, sem depender da comparação:

- **`idle: 0` em 37 sessões.** Nenhuma sessão ficou sem escrever nem avançar. É o oposto direto do
  modo de falha do sha anterior, onde 2 das 3 sessões eram `idle`.
- **`moved_rate: 1,0`.** Toda sessão escreveu no disco.
- **`advance_rate: 0,89`** — a fatia `advanced` do mesmo `outcomes` acima, 33 de 37, lida sob a
  régua de `20260829-o-incremento-que-andou` (gate passou **ou** o incremento andou). Não comparo
  este número com nenhum citado em handoff anterior a essa data.
- **11 dos 16 pares fase×missão são `ok`**, e as três missões chegaram a PR/close.
- **Zero `review-to-draft`.** Nenhuma volta foi comprada baixando a própria régua.
- **Zero `no-progress`** — a escalada que definia a fatia anterior desapareceu.

## O que os rótulos que não são `ok` realmente dizem

`leve` custa algo para ser ganho, então cada um leva uma frase:

- **TICKET de `20260906-o-pagamento-e-do-consultor`** — 2 sessões, 1 churned: um retry dentro do
  laço, não uma sessão vazia.
- **EXEC de `20260907-o-descarte-do-pagamento-fala`** — 11 sessões, 10 advanced, 1 churned. Um
  retry em onze sessões de execução é o laço desenhado, não fricção.
- **QA de `20260907-o-descarte-do-pagamento-fala`** — 1 sessão, 0 advanced, 1 churned: a única
  sessão que escreveu e não moveu incremento nenhum. É o `leve` mais caro dos três (US$ 9,21) e o
  único que descreve trabalho sem produto.

Os dois `refez`:

- **EXEC de `20260906-o-pagamento-e-do-consultor`** (`increment-blocked: 1`) — este é o caso em que
  o número diz `refez` e a história diz **bom**. A linha parou por Jidoka e foi destravada por
  decisão humana registrada em artefato. Kit funcionando, não kit falhando.
- **REVIEW de `20260907-o-descarte-do-pagamento-fala`** — 4 sessões, 4 advanced, US$ 52,99. Aqui o
  rótulo é honesto: quatro rodadas de revisão.

As **3 escaladas `budget-exhausted`** são o teto por missão (`BUDGET_MISSION_USD`) operando como a
porta humana que ele é. Mas três vezes em três missões, com a terceira missão custando US$ 152,30,
não é o teto pegando um caso extremo — é o teto calibrado **abaixo** do que uma missão custa hoje.
Isso é decisão humana e está nas pendências abaixo, não dissolvido na contagem.

## O que não melhorou, e fica dito

- **Custo.** US$ 264,40 em 3 missões (~US$ 88/missão). O kit ficou mais autônomo, não mais barato.
- **O laço de revisão continua sendo o maior termo.** Por `sdd autonomy --all-repos --by-mission`:
  52% em `20260906-o-contato-sobrevive-ao-notfound`, 23% em `20260906-o-pagamento-e-do-consultor` e
  **66% (US$ 100,94 de US$ 152,30)** em `20260907-o-descarte-do-pagamento-fala`. É a mesma classe
  que a auditoria da anatomia mediu em 76% e que motivou a rule `anatomia-do-agente.md`. Não
  regrediu ao pior ponto, mas também não está resolvida.
- **Intervenções (D12), lidas por D16 como `launches − 1`**, de
  `sdd autonomy --all-repos --by-mission`: as três missões têm 2, 2 e 4 launches →
  **5 intervenções em 3 missões**. Não é uma linha autônoma ponta a ponta; é uma linha que precisa
  do humano uma a três vezes por missão.

## A ressalva estrutural — e o que ela manda fazer

A `previous` tem 1 missão contra um `floor` de 3: **não é uma fatia suficiente**. A comparação
entre as duas colunas é direcional e vale porque o "antes" é um incidente conhecido e nomeado, não
porque as duas sejam medidas equivalentes. O veredito se sustenta na `latest` ser suficiente
sozinha — `sufficient: true`, `degenerate_axis: false`, composição num alvo real.

E há um limite que pertence ao próprio instrumento: `harness: ["2.1.263"]`, uma versão só. O item
aberto do `TODO.md` (L856) diz que o juiz **não recusa** uma fatia com duas versões de harness e
segue respondendo `sufficient: true`. Nesta fatia isso não disparou por sorte, não por guarda — e o
sha julgado aqui é justamente o que consertou um estrago causado por um bump de harness. Somado a
isso, `~/.sdd/autonomy-log.jsonl` carrega hoje **11 de 291 linhas** sob `/tmp`, escritas por
fixtures dos próprios testes. Nada disso muda o veredito; tudo isso decide qual é a próxima missão,
e é por isso que ela nasce apontada para o juiz.

## Pendências para o humano

1. **`BUDGET_MISSION_USD` está calibrado abaixo do custo real de uma missão** (3 escaladas
   `budget-exhausted` em 3 missões; a mais cara custou US$ 152,30). Subir o teto, ou aceitar a
   parada como ritual por missão — as duas são decisões legítimas, nenhuma é do runner.
2. **O laço de revisão a 66% numa missão** continua sendo o maior desperdício medido. A missão que
   nasce aqui **não** ataca isso; ela conserta o instrumento que mede. Se a prioridade for o
   dólar e não o juiz, esta é a hora de dizer.
