---
missao: 20260818-lote-facil
fase: QA
status: done
sessao: dfbae5c2-f5a4-4cbc-811c-0e9a18d5a78e
data: 2026-08-18 22:19
gate: "Repo sem interface (E2E_CMD e APP_URL vazios): as jornadas são a linha de comando do runner e foram andadas nesta sessão, num kit copiado (SDD_HOME é readonly). J1 `./bin/sdd health`, 5 sítios da família do aborto calado, um a um — A0 controle com a suíte real → `kit healthy`, rc 0; A1 com a suíte GENUINAMENTE vermelha (conserto do I3 revertido em bin/sdd:2253, piso do probe 1→1, bash -n limpo) → diz `suite red (rc 1) — run tests/run-all.sh to see it`, imprime as 15 linhas finais e SEGUE por mutação, gates, proveniência e catraca até `2 check(s) failed`, rc 1; A2 sem a linha `score:` → `health went blind to the mutation` e segue → `1 check(s) failed`; A3 com HOME sem .claude/plugins/cache → `provenance: 0 fixture(s) checked, 3 skipped` e segue → `kit healthy`, rc 0; A4 baseline só com comentários → 7× `finding outside the baseline` e segue → `7 check(s) failed`; A5 catraca ACHANDO algo (linha stale) → `stale baseline: …` e ainda assim `1 check(s) failed`. Antes da missão cada um dos cinco imprimia só o cabeçalho e saía rc 1. J2 `./bin/sdd autonomy` com um representante de cada um dos 4 baldes de exclusão (ledger sintético via SDD_STATE_DIR, derivado da forma real de uma linha do ledger) → conferido com `cat -A`: uma linha em branco antes do bloco, ZERO entre as quatro. J3 `./bin/sdd kaizen --dry-run` com eixo degenerado, DIFERENCIAL: floor 3 → série `.guard.floor = 3` e nota `floor of 3 missions`; movido para 7 (piso 1→1) → série `7` e nota `floor of 7 missions`, zero `floor of 3` sobrando. J4 a linha BLOCKED conta sessões: `sessions[]` incrementado só em bin/sdd:2326 e :2364, colado ao autonomy_session_row, e reverter isso reprova `tests/check-autonomy.sh` em EXATAMENTE uma asserção (`output: the blocked line counts the sessions the phase spent, not the laps of the loop`, `1 autonomy check(s) failed`). J5 `CDPATH=/tmp/poison ./bin/sdd version` → `sdd 0.1.0 (/home/joruge/repos/sdd_agents)`, rc 0, nada vazado. J6 DIFERENCIAL do `templates/review.md` contra o extrator literal do gate_REVIEW → `rows=13`, e com o heading degradado para `##` → `NO-TABLE`. Fidelidade da réplica usada em A2–A5 MEDIDA e não afirmada: `sdd health` sobre a réplica é byte a byte idêntico ao `sdd health` sobre a suíte real, fora o path do sandbox. `tests/run-all.sh` → `suite green`, rc 0, `score: 98 caught, 0 known gap(s), of 98`, `43 finding(s)`; `./bin/sdd health` → `kit healthy`, rc 0, `ratchet: 7 known debt(s), none new` com `todo-findings 43`, e com a baseline deixada em 42 de propósito ele reprova em 2 — a catraca morde nos dois sentidos. 6 jornadas, 14 sondas, 0 vermelhas; 1 achado confirmado (fora de escopo, decisão do humano, no TODO.md); 0 incrementos de fix."
---

# Handoff — QA — o `sdd health` para de morrer calado, e 18 achados baratos saem do backlog

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

**6 jornadas andadas, 14 sondas, todas verdes** — este repo não tem interface (`E2E_CMD` vazio),
então a jornada é a linha de comando do runner e quem a andou foi esta sessão. **1 achado
confirmado**, pré-existente e fora do escopo, que virou linha do `TODO.md` e pendência do humano.
**0 specs e2e** (não há navegador) e **0 incrementos de fix**: nenhum defeito sanável no diff da
missão. A próxima fase é **REVIEW**, e ela é a primeira a usar o `templates/review.md` novo.

## Estado do repo

- **Branch:** `chore/lote-facil` — nunca empurrada; `origin` não a conhece.
- **Último commit:** o desta sessão (TODO.md + baseline + este handoff); antes dele, `557c39c`.
- **Working tree:** limpo depois do commit.
- **Suíte:** `tests/run-all.sh` → **verde**, rc 0, `score: 98 caught, 0 known gap(s), of 98`,
  `43 finding(s)` (era 42 — este handoff registrou 1 achado, com a catraca movida no mesmo commit).
- **E2E:** `E2E_CMD` vazio. **Não existe jornada de navegador neste repo** — as skills
  `qa-report`/`qa-execution` não rodaram e a árvore `docs/qa/` não existe, por contrato. A
  evidência da jornada é o campo `gate:` deste arquivo, que é o que o `gate_QA` mede
  (`bin/sdd:501`).

## O que foi feito

> QA não escreve produção. O único commit desta fase registra o achado fora de escopo e move a
> catraca junto, como o `CLAUDE.md` exige.

- **o commit desta sessão** (o mesmo que carrega este handoff — um commit não cita o próprio hash;
  `git log --oneline -1` na branch dá o valor) — o achado da contabilidade do `sdd autonomy` entra
  no `TODO.md`, seção "Saída humana e cosmética", e `tests/health-baseline.txt` vai de
  `todo-findings 42` para `43` **no mesmo commit**, como a catraca do `CLAUDE.md` exige.
- Nenhum outro arquivo foi tocado: **QA não escreve produção**, e `bin/sdd`, `tests/*.sh` e
  `templates/` saem desta fase byte a byte como o EXEC os deixou em `557c39c`.

## As 6 jornadas, e como cada uma foi medida

> Toda sonda de sabotagem **prova primeiro que sabotou o que dizia sabotar** (o "piso do probe"),
> porque conclusão de probe vazio não vale — regra do `CLAUDE.md` que já custou quatro conclusões
> falsas neste kit. Onde a alegação é "duas vozes concordam", a asserção é **diferencial**.

### J1 — `sdd health` com cada um dos 5 sítios da família do aborto calado

A prova que mais importa da missão, e a única que não é sensor da suíte. Andada num **kit copiado**
(`/tmp/qa-lote*`, `SDD_HOME` é `readonly` e não se aponta por env), com controle verde antes.

| sonda | sabotagem | o que o operador vê hoje | segue? |
|---|---|---|---|
| A0 | nenhuma (controle, suíte real) | `kit healthy`, rc 0, os 5 checks | — |
| A1-real | o conserto do I3 revertido no `bin/sdd` — suíte **genuinamente** vermelha | `fail suite red (rc 1) — run tests/run-all.sh to see it` + as 15 linhas finais da suíte | **sim**, e ainda diz `went blind to the mutation`, roda gates, proveniência e catraca, e fecha em `fail 2 check(s) failed`, rc 1 |
| A2 | corpus sem a linha `score:` | `fail the suite did not print the 'score:' line — health went blind to the mutation` | **sim** → `1 check(s) failed` |
| A3 | `HOME` sem `.claude/plugins/cache` nem skills | `ok provenance: 0 fixture(s) checked, 3 skipped (skill not installed)` | **sim** → catraca roda, `kit healthy`, rc 0 |
| A4 | baseline sem uma linha viva (só comentários) | 7× `fail finding outside the baseline: …` | **sim** → `7 check(s) failed` |
| A5 | catraca **acha** algo (linha stale plantada) | `fail stale baseline: '…' is no longer a finding` | **sim** → `1 check(s) failed` — é o 5º sítio, o que o I1 descobriu |

Antes da missão, cada uma dessas cinco linhas era **uma linha de cabeçalho e rc 1, calado**.

⚠️ **Como o A1-real foi feito, e por que ele vale mais que a réplica.** A suíte foi deixada vermelha
por um **defeito de verdade**: o `${sessions[$phase]}` da linha `BLOCKED` (`bin/sdd:2253`) voltou a
ser `${attempts[$phase]}`, que é exatamente o conserto do I3. Piso do probe: 1 ocorrência antes, 1
depois, `bash -n` limpo. Resultado colateral e valioso — `tests/check-autonomy.sh` reprovou em
**uma** asserção e só nela: `FAIL output: the blocked line counts the sessions the phase spent, not
the laps of the loop`, `1 autonomy check(s) failed`. A asserção que o I3 escreveu está viva e morde
o defeito que ela nomeia, e nada mais.

⚠️ **Limite declarado das sondas A2–A5.** Elas usam um `tests/run-all.sh` de réplica que reproduz
uma execução **capturada da suíte real** (`/tmp/qa-suite-corpus.txt`, 779 linhas, tirado do
`tests/run-all.sh` deste repo — nunca escrito de memória) e escolhe o `rc`. A fidelidade da réplica
foi **medida, não afirmada**: a sonda A0' (réplica, rc 0) produz saída idêntica à do A0 (suíte real)
— asserção diferencial. O sítio 1 não depende disso, porque foi andado também com a suíte
genuinamente vermelha (A1-real).

### J2 — `sdd autonomy` com as quatro exclusões (o parágrafo único do I3)

Ledger sintético com um representante de cada balde (não-comparável, evento desconhecido, outro
repo, sem repo), derivado da **forma real** de uma linha do ledger (`head -1` do
`~/.sdd/autonomy-log.jsonl`), lido com `SDD_STATE_DIR` para não encostar no ledger real.
Verificado com `cat -A`: **uma linha em branco antes do bloco, zero entre as quatro**. Verde.

### J3 — `sdd kaizen`, o piso citado uma vez só

Ledger de eixo degenerado (4 versões × 1 missão), `SDD_STATE_DIR` próprio. **Diferencial:** com
`KAIZEN_GUARD_FLOOR=3` a série diz `.guard.floor = 3` e a nota diz `floor of 3 missions`; movido
para `7` (piso do probe: 1 ocorrência antes, 1 depois), a série diz `7` e a nota diz `floor of 7
missions`, com **zero** ocorrências de `floor of 3` sobrando. As duas vozes se movem juntas — não
há cópia escrita à mão.

⚠️ A primeira versão desta sonda **concluiu no vazio** e foi descartada: rodada num sandbox cujo
ledger não tinha linha nenhuma daquele repo, a nota simplesmente não imprimia, e o `grep`
respondia `0` nos dois lados — verde convincente, significado nenhum. Só valeu depois de o ledger
tornar o eixo degenerado de fato.

### J4 — a contagem de sessões da linha `BLOCKED`

Andada estruturalmente e pela sabotagem do A1-real. `sessions[]` é incrementado em exatamente dois
lugares (`bin/sdd:2326` e `:2364`), cada um colado ao `autonomy_session_row` que escreve a linha do
ledger; `attempts[]` ficou só com o teto e o campo `attempt` da linha. Reverter isso mata a
asserção nomeada, e só ela (ver J1/A1-real).

### J5 — `sdd` com `CDPATH` sujo

`CDPATH=/tmp/poison ./bin/sdd version` → `sdd 0.1.0 (/home/joruge/repos/sdd_agents)`, rc 0:
`SDD_HOME` resolve certo e nada vaza para a stdout.

⚠️ **O piso deste probe corrigiu uma suposição minha.** A primeira tentativa de armar o veneno não
armou, e eu quase concluí "sobrevive" sobre nada. A semântica real do bash 5.2 é: o `CDPATH` só
vence quando o operando **não existe** no diretório corrente — medido com três casos
(`cd bin` com `bin` local → local; `cd onlyhere` só no veneno → veneno, e impresso na stdout).
Como `_resolve_self` passa `<dir>/..`, que existe localmente, este caminho é difícil de envenenar
**a partir da raiz do repo**; a guarda `CDPATH=''` segue correta e barata, e quem mede a classe é
o par diferencial do `check-autonomy.sh` com o piso de veneno armado.

### J6 — `templates/review.md` contra o `gate_REVIEW`

**Diferencial**, com o extrator literal do `gate_REVIEW` (`bin/sdd`, `^###[[:space:]]+Overall
Grade`): o template como está entregue devolve `rows=13`; degradado o heading para `##` — que é o
erro exato que duas rodadas independentes cometeram e que o template existe para impedir —
devolve `NO-TABLE`. O template resolve o defeito que motivou sua criação.

## Achado confirmado — e por que ele NÃO virou incremento de fix

**A contabilidade do `sdd autonomy` não fecha na tela.** Medido no repo real, na saída entregue:

```
▸ sdd autonomy — /home/joruge/.sdd/autonomy-log.jsonl · 75 row(s) · /home/joruge/repos/sdd_agents
  … tabela somando 73 session(s) …
  (2 non-comparable row(s) excluded: …)
  (11 row(s) excluded: born in another repo — …)
```

O arquivo tem **86** linhas. O `total` do cabeçalho (`bin/sdd:2473`) conta **só as linhas locais**,
então as 11 de outro repo **já estavam fora** das 75 — mas aparecem no mesmo parágrafo, com a mesma
palavra `excluded`, ao lado das 2 que de fato saem do total. O leitor faz `75 − 2 − 11 = 62` e a
tabela mostra 73. O parágrafo mistura duas populações.

É **da mesma família** que o I3 consertou (número que o humano lê nomeando a grandeza errada), e
foi o próprio I3 que o tornou legível: antes as quatro linhas vinham separadas por brancos e liam
como quatro apartes soltos; coladas num parágrafo, elas convidam a uma soma que não fecha.

**Não é regressão do diff** — as duas populações sempre foram essas. E **não vira `F<n>`** porque o
remédio é uma escolha entre dois contratos, não uma correção mecânica:

1. o cabeçalho passar a contar o arquivo — fecha a aritmética, mas **quebra as 7 asserções
   `assert_bucket_sum`** do `tests/check-autonomy.sh`, que hoje exigem que os quatro baldes somem
   ao total; ou
2. as duas linhas fora de escopo saírem do parágrafo para uma frase que diga que elas nunca
   entraram.

Escolher é decisão de produto sobre o que `N row(s)` significa. Por isso: `TODO.md` + "Decisions
for a Human", **sem bloquear o pipeline** (§5 do contrato do `sdd-qa`).

Pelo mesmo motivo **não** nasceu sensor: escrever um agora congelaria um dos dois contratos antes
de o humano escolher qual é o certo.

## Artefatos

| Arquivo | O que contém |
|---|---|
| `docs/handoffs/20260818-lote-facil/30-handoff-qa.md` | este handoff — e o `gate:` dele é a evidência que o `gate_QA` mede |
| `TODO.md` (seção "Saída humana e cosmética") | o achado da contabilidade do `sdd autonomy` |
| `tests/health-baseline.txt` | `todo-findings 43`, movido no mesmo commit do achado |
| `docs/handoffs/20260818-lote-facil/checkpoint.md` | a seção "Incrementos de fix (QA)" registra, com o porquê, que nenhum `F<n>` nasceu |

## Boot da próxima fase

A próxima é **REVIEW**. Leia, nesta ordem: `00-missao.md` (as 3 métricas), as **Notas de execução**
do `checkpoint.md` (o detalhe por incremento), o `20-handoff-exec.md` e este arquivo.

Ambiente: nada a subir.

```sh
bash tests/run-all.sh                 # ~5 min — treze sensores, lint, dry-runs, 98 mutantes
./bin/sdd health                      # os cinco checks do kit sobre si mesmo
./bin/sdd status 20260818-lote-facil
```

O que o revisor precisa saber que a QA viu:

1. **Os cinco sítios do `sdd health` foram andados um a um e todos falam.** Não é preciso repetir a
   passada; se quiser, o caminho barato é o A1-real (reverter `${sessions[…]}` para
   `${attempts[…]}` em `bin/sdd:2253` **num kit copiado**) — a suíte fica vermelha em exatamente
   uma asserção.
2. **`templates/review.md` é novo e esta fase é a primeira a usá-lo de verdade.** O heading tem de
   ficar em `###` — em `##` o `gate_REVIEW` colhe `NO-TABLE` e a fase não fecha. Medido em J6.
3. **O achado da contabilidade do `sdd autonomy` é conhecido, é decisão do humano e não deve virar
   conserto na revisão.** Está no `TODO.md` com as duas saídas escritas.
4. **`TODO.md` está em 43**, não 42: este handoff registrou um achado e moveu a catraca junto.

## Pendências / Decisions for a Human

> Só julgamento humano genuíno. **Não bloqueiam o pipeline** — viram seção do PR.

- **O que `N row(s)` significa no cabeçalho do `sdd autonomy`** — as duas saídas estão acima e no
  `TODO.md`; uma delas mexe em 7 asserções de sensor. Achado desta fase.
- **O alvo "<30 s" da D7 segue estourado e esta missão o piorou** (catálogo 81 → 98, suíte ~5 min).
  Herdado do `20-handoff-exec.md`; segue no `TODO.md`, seção "Custo e escala".
- **`LINT_CMD` está preenchido no `.sdd/config.sh` deste repo e o runner não o lê** — uma das 5
  chaves fantasma, declarada fora de escopo no `00-missao.md`. Herdado do EXEC.

## Riscos e não-feitos

- **Nenhuma spec e2e foi escrita, e isso é o contrato e não uma omissão:** `E2E_CMD` é vazio, não há
  navegador, e um achado de jornada aqui vira asserção na suíte — que é onde os 18 achados desta
  missão já foram parar, nas mãos do EXEC. O único achado desta fase não virou sensor **de
  propósito**, pelo motivo escrito acima.
- **A linha `BLOCKED` não foi vista num `sdd run` real que bloqueasse**, porque isso custaria
  sessões pagas de verdade. Foi andada estruturalmente (J4) e pela sabotagem do A1-real, que prova
  que a asserção do I3 morde. É um limite declarado, não uma verificação silenciosamente pulada.
- **A2–A5 usaram réplica da suíte, com a fidelidade medida por asserção diferencial** (A0' ≡ A0).
  O sítio 1 não depende da réplica.
- **`bin/sdd:2373` carrega um segundo `BLOCKED …` com "two sessions" escrito à mão.** Não foi
  tocado: ali a condição é literalmente duas, então o número está certo hoje. Não virou achado
  para não inflar o backlog com uma constante correta — fica dito aqui.
- **Nada foi empurrado, nenhum PR foi aberto, nada foi mergeado** — é de outra fase.

## Achados fora de escopo

> Registrados no `TODO.md` deste repo (é o kit). Aqui fica só o ponteiro, para o PR conseguir citar.

- A contabilidade do `sdd autonomy` não fecha na tela: o cabeçalho conta o escopo e o parágrafo
  mistura duas populações → `TODO.md` (Saída humana e cosmética) — descoberto nesta fase, em J2.
