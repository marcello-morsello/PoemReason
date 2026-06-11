# Poem Examples / Exemplos de Poemas

Example poems organized by language for testing the PoemReason engine.
Each file follows the convention `<author>_<year>_<title>.md` with
`# Title — Author (Year)` as the first line and stanzas separated by
blank lines.

Poemas de exemplo organizados por idioma para testar o motor PoemReason.

---

## Legend / Legenda

| Form / Forma | Description / Descrição |
|---|---|
| soneto_italiano | 14 endecasílabos, ABBA ABBA CDC DCD |
| soneto_ingles | 14 decassílabos, ABAB CDCD EFEF GG |
| sonnet_fr | 14 alexandrinos, ABBA ABBA CCD EED |
| trova | 4 setessílabos, ABAB |
| quadra | 4 setessílabos, toante ABCB |
| redondilla | 4 octosílabos, abba |
| haiku | 3 versos, 5-7-5 moras |
| tanka | 5 versos, 5-7-5-7-7 moras |
| limerick | 5 versos, AABBA |
| terza_rima | Tercetos encadeados, ABA BCB CDC |
| ballade | 3×8 + envoi 4, ababbcbC |
| vilanela | 19 versos, refrões alternados |
| blank_verse | Versos brancos, pentâmetro iâmbico |
| knittelvers | Parelhas, 4 acentos, AABB |
| alexandrin | Verso de 12 sílabas (metro, não forma) |

---

## Português (PT)

| File / Arquivo | Author / Autor | Form / Forma |
|---|---|---|
| `camões_1595_sobolos-rios.md` | Luís de Camões | canção / ode |
| `goncalves-dias_1843_cancao-do-exilio.md` | Gonçalves Dias | quadra / canção |
| `bilac_1888_via-lactea-xiii.md` | Olavo Bilac | soneto_italiano |
| `augusto-dos-anjos_1912_versos-intimos.md` | Augusto dos Anjos | soneto_italiano |

## 日本語 (JA)

| File / Arquivo | Author / Autor | Form / Forma |
|---|---|---|
| `basho_1686_furu-ike-ya.md` | 松尾芭蕉 (Bashō) | haiku |
| `ki-no-tsurayuki_905_koromo.md` | 紀貫之 (Tsurayuki) | tanka |

## Italiano (IT)

| File / Arquivo | Author / Autor | Form / Forma |
|---|---|---|
| `dante_1320_inferno-canto-i.md` | Dante Alighieri | terza_rima |
| `petrarca_1345_pace-non-trovo.md` | Francesco Petrarca | soneto_italiano |

## Français (FR)

| File / Arquivo | Author / Autor | Form / Forma |
|---|---|---|
| `du-bellay_1558_heureux-qui-comme-ulysse.md` | Joachim du Bellay | sonnet_fr |
| `villon_1462_ballade-des-pendus.md` | François Villon | ballade |
| `hugo_1856_demain-des-laube.md` | Victor Hugo | alexandrin (quartains) |

## English (EN)

| File / Arquivo | Author / Autor | Form / Forma |
|---|---|---|
| `shakespeare_1609_sonnet-18.md` | William Shakespeare | soneto_ingles |
| `milton_1667_paradise-lost.md` | John Milton | blank_verse |
| `lear_1846_book-of-nonsense.md` | Edward Lear | limerick |
| `thomas_1951_do-not-go-gentle.md` | Dylan Thomas | vilanela |

## Deutsch (DE)

| File / Arquivo | Author / Autor | Form / Forma |
|---|---|---|
| `goethe_1782_erlkonig.md` | Johann Wolfgang von Goethe | knittelvers |

## Español (ES)

| File / Arquivo | Author / Autor | Form / Forma |
|---|---|---|
| `marti_1891_cultivo-una-rosa-blanca.md` | José Martí | redondilla |

---

## Testando com o CLI / Testing with CLI

```bash
# Português (default)
cat poems/pt/goncalves-dias_1843_cancao-do-exilio.md | ./poemreason -f table

# Japonês
cat poems/ja/basho_1686_furu-ike-ya.md | ./poemreason -l ja -f table

# Italiano
cat poems/it/petrarca_1345_pace-non-trovo.md | ./poemreason -l it -f table

# Francês
cat poems/fr/hugo_1856_demain-des-laube.md | ./poemreason -l fr -f table

# Inglês
cat poems/en/shakespeare_1609_sonnet-18.md | ./poemreason -l en -f table

# Alemão
cat poems/de/goethe_1782_erlkonig.md | ./poemreason -l de -f table

# Espanhol
cat poems/es/marti_1891_cultivo-una-rosa-blanca.md | ./poemreason -l es -f table
```

Note: Japanese poems contain kanji; for CLI testing use kana-only input.
Nota: Poemas japoneses contêm kanji; para testar no CLI use apenas kana.

---

## Missing examples / Exemplos pendentes

| Form | Language | Suggested poem |
|------|----------|----------------|
| ottava_rima | IT | Ariosto — Orlando Furioso |
| décima_espinela | ES | Vicente Espinel |
| romance | ES | Romance del Conde Olinos |
| seguidilla | ES | Traditional |
| lira | ES | Garcilaso — A la flor de Gnido |
| cordel_sextilha | PT | Leandro Gomes de Barros |
| triolet | FR | Medieval French |
| rondeau | FR | Charles d'Orléans |
| pantoum | FR | Baudelaire — Harmonie du soir |
| rhyme_royal | EN | Chaucer — Troilus and Criseyde |
| common_metre | EN | Traditional ballad |
| spenserian_stanza | EN | Spenser — The Faerie Queene |
| heroic_couplet | EN | Pope — The Rape of the Lock |
| volksliedstrophe | DE | Traditional |
| alexandriner | DE | Gryphius |
| distichon | DE | Goethe — Xenien |
| dodoitsu | JA | Traditional |
