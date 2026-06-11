# Modulo Italiano — PoemReason

Questo modulo contiene i componenti specifici per l'analisi della poesia
italiana.

## File

- **`g2p.pl`** — Conversione grafema-fonema (G2P) per l'italiano.
  Mappa i grafemi italiani in fonemi, sillabifica (attacco massimo) e
  assegna l'accento.
- **`phonetics.pl`** — Scansione sillabica con sinalefe e taglio
  sull'ultimo accento (endecasillabo). Estrazione di rime consonanti
  e assonanti. Registra `tradicao_padrao/1` come `italiano_silabico`.

## Tradizione poetica

La metrica italiana segue il modello sillabico:
- L'endecasillabo (11 sillabe grammaticali, 10 metriche dopo il taglio)
- Il settenario (7 sillabe)
- Sinalefe opzionale tra vocali
- Rima consonante e assonante

## Forme locali

- **Terza rima** — Catene di terzine in endecasillabi (ABA BCB CDC...)
- **Ottava rima** — Strofe di 8 endecasillabi (ABABABCC), usata da Ariosto
- **Madrigale** — 6-12 versi, endecasillabi e settenari misti, rima libera

## Limitazioni note

- Non distingue /ɛ/ da /e/ né /ɔ/ da /o/ senza accento grafico
- /z/ sempre reso come [ts] (nessuna distinzione [dz])
- Il raddoppiamento sintattico non è gestito
- Trascrizione IPA semplificata
