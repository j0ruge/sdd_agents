# Handoff — o gate aprende a dizer "o mundo está quebrado"

**Data:** 2026-08-28 · **Estado:** plano **aprovado**, I1 **commitado com o vermelho observado**.
Faltam I2 a I8.

Auto-contido de propósito. A sessão que ler isto não participou da conversa que o gerou.
Onde há número, ele foi medido.

---

## 1. Comece por aqui

```bash
cd ~/repos/sdd_agents
git branch --show-current                  # esperado: feat/o-gate-sabe-que-o-app-caiu
git log --oneline -2                       # esperado: 8ca8470 sobre d30d199
git status --porcelain                     # TEM de sair vazio

bash tests/check-gates.sh; echo "rc=$?"    # esperado rc=1, com 7 FAIL nomeadas no § 4
```

O plano completo está em `~/.claude/plans/isso-t-um-inferno-fluttering-glade.md`. **Leia-o antes
de escrever código** — este handoff é o estado, não o desenho.

## 2. Por que esta missão existe

A missão anterior (SQ-111, repo-alvo `sales_quote`) fechou, mas exigiu **~8 resgates humanos**. O
dono do kit perguntou quando ele fica utilizável. A investigação achou **uma causa, não oito**:

- todo `gate_*` devolve **0 ou 1** (`bin/sdd:406-409`). Não existe terceiro resultado;
- o único conceito de "um humano precisa agir" é `status: blocked` no frontmatter — **prosa do
  modelo**, lida por **um gate só** (`gate_QA`, `bin/sdd:595`);
- em `gate_QA:712`, app fora do ar, banco parado, browser faltando e asserção genuinamente
  quebrada colapsam no **mesmo `return 1` com a mesma frase**;
- aí `cmd_run:3684` vê `moved=true` e **compra outra sessão**.

Custo medido: **US$ 14,16** (QA reprovada por ambiente) + **US$ 7,61** (o retorno depois do PR
aberto) + **US$ 37,30** (o `gate_REVIEW` reabrindo a fase mais cara quando o DOCS morreu).

**Alvo escolhido pelo dono:** o kit nunca gasta sessão paga contra o que nenhuma sessão pode
consertar. Subir o app segue sendo trabalho do operador (`config/schema.md:47`); o que muda é que o
runner passa a **perguntar** e **parar**.

## 3. O que já está feito, e não precisa ser refeito

| | |
|---|---|
| `main` | `d30d199` — PRs #26 e #27 mergeados |
| branch | `feat/o-gate-sabe-que-o-app-caiu`, um commit à frente |
| I1 | `8ca8470` — asserções do gate, **vermelhas pelo motivo certo** |
| plano | aprovado, em `~/.claude/plans/isso-t-um-inferno-fluttering-glade.md` |
| carimbo de mutação | **morto** desde `8ca8470` (`tests/` entra na chave). Normal — o plano manda recarimbar no I7 |
| catraca | `todo-findings 77`, não se moveu |

## 4. O vermelho que o I1 deixou, e o que ele significa

`bash tests/check-gates.sh` → rc 1. **7 FAIL, e elas são o contrato do I2:**

```
ok    dead-app floor: 127.0.0.1:53821 refuses connections     ← o piso, verde
ok    e2e red over a dead app does not advance → QA
FAIL  the reason names the address nothing is listening on
ok    a dead app does NOT block a green e2e → REVIEW          ← controle, já verde
FAIL  path, query and fragment are stripped
FAIL  userinfo is stripped
FAIL  an IPv6 literal reads as an address
FAIL  http with no port defaults to 80
FAIL  an empty APP_URL is not probed
ok    an empty APP_URL never claims a dead app                ← ausência do ramo errado
FAIL  an unparseable APP_URL is not probed
ok    an unparseable APP_URL never claims a dead app
ok    the fixture is back where the next block starts → REVIEW
```

⚠️ **Os quatro `ok` não são decoração — são o que impede o conserto largo demais.** "a dead app
does NOT block a green e2e" passa **hoje** e tem de continuar passando: se ficar vermelho depois do
I2, você sondou **antes** do gate em vez de depois do e2e vermelho, e acabou de bloquear todo repo
cujo e2e sobe o próprio servidor. O fixture `example.invalid` de `check-gates.sh:453` existe ao lado
de um `E2E_CMD` **verde** exatamente por isso.

## 5. A ordem do que falta

Do plano, § Incrementos. **I2 é o próximo.**

- **I2** — a sonda e a fiação: `APP_PROBE_TIMEOUT`, `app_url_hostport`, `app_probe`,
  `GATE_APP_DOWN` + reset na entrada do `gate_QA`, os três arms de `GATE_WHY`.
  Check: `tests/check-gates.sh` verde **inteiro** e `./tests/run-all.sh` verde.
- **I3** — asserções de escalada em `tests/check-autonomy.sh`, vermelhas. O par app-down tem como
  controle **o mesmo fixture com `APP_URL=""`**: só essa linha difere, então o par isola a sonda e
  não a vermelhidão.
- **I4** — `app_down_escalation` e **as duas portas** (`:3671` e `:3724`).
- **I5** — o par retry/fase-errada e a projeção (`--dry-run` escreve zero linhas).
- **I6** — `cmd_preflight` + `tests/check-preflight.sh`.
- **I7** — as seis mutações. **Depois dele**, `./bin/sdd health --with-mutation`.
- **I8** — docs, por último.

## 6. Armadilhas medidas nesta sessão

- ⚠️ **O `check-lang.sh` reprova slug de missão pt-BR em arquivo de superfície inglesa.** Custou
  uma reprovação no I1; contornei citando "SQ-111 mission of 2026-08-27". É o item aberto *"Slug de
  missão em pt-BR não pode ser citado na superfície inglesa"* — você vai reencostar nele no I8, que
  escreve `docs/`.
- ⚠️ **A porta 2 (`:3724`) não é simetria.** Sem ela o marcador sobrevive à volta e a escalada sai
  carimbando **EXEC** sobre um problema da QA. É o bug F2 medido em `20260826-o-laco-da-qa`, uma
  casa adiante — o contrato acima de `GATE_HANDOFF_BLOCKED` (`bin/sdd:508-511`) manda re-derivar
  essa propriedade para todo marcador novo.
- ⚠️ **Ordem do carimbo, 20 a 50 min se errada.** `bin/ tests/ templates/ config/` compõem a chave;
  `docs/` e `TODO.md` não, mas `tests/health-baseline.txt` sim. `sdd health --with-mutation` roda
  **depois do I7 e antes do I8**.
- **Piso que usa a função sob teste não é piso.** O do I1 é um `timeout bash -c 'exec 3<>…'` cru, e
  morre por nome quando não acha porta recusada.
- `tests/check-gates.sh` roda com `set -uo pipefail` — **sem `-e`**. Capture rc com `|| rc=$?`.

## 7. O que NÃO está provado

- **A sonda não existe ainda.** Todo o § 4 é a ausência dela, não o comportamento dela.
- **A classificação `up` (rc 0) não tem fixture sem dependência.** O plano deixa a escolha aberta:
  `git daemon` como listener opcional com aviso alto quando não sobe, ou o buraco declarado no
  **cabeçalho do sensor** — nunca no `TODO.md`, porque item novo move a catraca e mata o carimbo.
- **Nada disso é mensurável ponta a ponta ainda.** O `sdd autonomy` diz `0 stalled · 0% waste` para
  a missão que exigiu 8 resgates: `stalled` está definido como `moved == false` (`bin/sdd:4053`),
  ou seja "o modelo escreveu algo", não "a fase avançou". Das 145 sessões da história, **81
  reprovaram o gate** e o leitor lê 0% de desperdício. É a missão seguinte, e ela já está desenhada
  (§ 8).

## 8. Depois desta

1. **O instrumento honesto.** O leitor deriva `advanced`/`churned`/`idle` de `gate` + `moved` —
   campos que **as 145 linhas históricas já têm**, então zero migração. Mais `launches` (contagem
   de `run_id` distintos ≈ as intervenções humanas) e `reopened`. Medido: `20260818-lote-facil`
   aparece como 9 sessões/US$ 120,38 e na verdade foram **14 sessões, 4 lançamentos, US$ 230,44** —
   subestimou US$ 110, 91%. Sem isso não dá para provar que **esta** missão funcionou.
2. **Faxina D15.** ~12 itens são limites já declarados que deviam morar no cabeçalho do sensor, e
   os 3 de `Adiados por YAGNI` são roadmap inflando a catraca. 77 → ~62, num diff com autor.
3. **O REVIEW** — 49% do custo de uma missão, US$ 37,30, a US$ 2,70 do próprio teto.

⚠️ **A régua que importa, e que o backlog viola hoje:** dos 77 achados, **49% não têm consumidor
fora do repo do kit**; toda intervenção do operador rastreia para **18** achados de três classes, e
**nenhuma** para os 27 de "sensor sobre sensor" que dominam o arquivo. 32 dos 77 nasceram do
`sdd-reviewer` auditando o próprio kit; só **4** vieram de trabalho real em repo-alvo. Missão de
kit que não encosta nessas três classes está polindo o eixo errado.
