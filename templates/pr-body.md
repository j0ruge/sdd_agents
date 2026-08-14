# <título da missão>

<Uma frase: o que o usuário ganha com este PR.>

> Gerado pelo pipeline `sdd` — missão `<YYYYMMDD>-<slug>`. Único gate humano: **o merge**.

## O que mudou

<3–6 bullets, em linguagem de produto. O leitor do PR não leu o plano.>

## Como verificar

```bash
<comandos que provam que funciona, na ordem>
```

## Evidências

| Fase | Resultado | Artefato |
|---|---|---|
| Execução | <N incrementos, suíte verde> | [`checkpoint.md`](<link>) |
| QA | <aprovado / aprovado após N fixes / skipped — sem mudança user-visible> | [`<report>`](<link>) |
| Review | <todos os itens Grade A em r<N>> | [`40-review-r<N>.md`](<link>) |
| Docs | <checklist de drift ✅> | [`45-docs.md`](<link>) |

**Sensores novos** (rodam no CI a partir deste PR):

- `<spec/teste>` — <o que ele prova>

## Plano

[`01-plano.md`](<link>) · [`00-missao.md`](<link>) — leia se quiser o porquê das decisões.

## Pendências (Decisions for a Human)

> Não bloqueiam este PR; são escolhas que exigem julgamento humano.

- [ ] <pendência — contexto — onde decidir>

## Achados fora de escopo

<Registrados no `TODO.md`; viram candidatas a missões futuras.>

- <o quê> — `arquivo:linha`

## Riscos e não-feitos

- <explícito, honesto>

---
<!-- ticket: <chave da issue, se JIRA_ENABLED> · versão: <versao> -->
