---
verdict: indeterminado
kit_sha_judged: none
date: 2026-08-15
---

# Veredito — a série nasceu vazia, e isso é o resultado esperado da primeira volta

> Primeira execução do laço kaizen. O julgamento abaixo cita **exclusivamente** a saída de
> `sdd kaizen --series` (ADR 0001: o runner deriva os números, este artefato os interpreta).

## A série, verbatim

```json
{"v":1,"latest":null,"previous":null,
 "guard":{"missions_after_change":0,"sufficient":false},
 "excluded":{"non_comparable":0,"unrecognized":0,"meta":0}}
```

## Por que `indeterminado`

`guard.sufficient` é **`false`**, com `guard.missions_after_change: 0`. A regra não admite
julgamento: guarda insuficiente ⇒ o veredito **é** `indeterminado`. A guarda pertence ao runner
e este artefato não a sobrepõe — nem teria o que sobrepor, porque não há número algum para
interpretar contra ela.

`latest` e `previous` são os dois **`null`**: não existe um único grupo de `kit_sha` comparável.
Por isso `kit_sha_judged` é `none` — não há sha mais novo que a série reconheça, e o campo é
lido pelo `gate_KAIZEN` (`bin/sdd:1829`, `.latest.kit_sha // "none"`), que casa o veredito por
conteúdo e nunca por "arquivo mais novo".

## O detalhe que separa "vazio" de "descartado"

O bloco `excluded` é o que dá confiança no `null` acima: `non_comparable: 0`,
`unrecognized: 0`, `meta: 0`. **Nada foi excluído.** Não é o caso de um ledger cheio de linhas
com `kit_dirty: true` que a série teve de jogar fora, nem de linhas mal formadas, nem de
sessões do próprio laço kaizen contadas como meta — é ausência total de dado. Confirmado no
gemba: `~/.sdd/` existe e está **vazio**, sem `autonomy-log.jsonl`.

A distinção importa porque as duas situações pedem ações opostas. Ledger sujo pediria conserto
do instrumento; ledger vazio pede apenas que missões rodem. É o segundo caso.

## O que isso diz sobre a mudança anterior

Pelo `git log --oneline -20`, os seis commits no topo — `f5161d4`, `a846f41`, `31db012`,
`f206569`, `1bc291a`, `90f9ce9` — são **uma única mudança lógica**: o I13.3, o próprio laço
kaizen (série determinística, `gate_KAIZEN` e o Jidoka, a fase KAIZEN nas tabelas, o sétimo
agente, as mutações e o lembrete pós-pipeline). Julgo a mudança, não o sha.

E essa mudança é, por construção, a única que a série **nunca poderia** julgar: ela é o
instrumento de medição. Nenhuma missão rodou sob ela ainda, então não há linha no ledger; a
primeira volta do laço mede o vazio que ela mesma criou. A mudança que a série tentaria julgar
seria a anterior — o I13.1 (`6f2b59e`), que criou o ledger —, mas ele nasceu vazio e nenhuma
missão foi executada desde então.

Não há, portanto, sinal de regressão a interpretar: não há `moved_rate`, não há tally de
`ok`/`leve`/`refez`, não há escalada por `kind` e não há custo. Ausência de sinal não é sinal
negativo — pela D5 (`CONTEXT.md`), `indeterminado` é o estado normal do começo da série e **não**
para a linha. O laço segue para a triagem e para o plano.

## O que faria a próxima volta ser conclusiva

A guarda pede 3 missões distintas sob um mesmo `kit_sha` limpo, com um grupo anterior para
comparar. A missão nascida ao lado deste veredito é a primeira delas: rodá-la com `sdd run`
escreve as primeiras linhas do ledger sob o sha do I13.3 e começa a série de verdade.

Enquanto `latest` for `null`, todo veredito futuro repetirá este — o que é honesto, mas custa
uma sessão. O lembrete do `cmd_run` (D6/D8) existe justamente para o disparo do `sdd kaizen`
acontecer quando há dado novo, e não antes.
