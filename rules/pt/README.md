# Módulo Português — PoemReason

Este diretório contém os módulos específicos para análise de poesia em
português brasileiro.

## Estrutura

- **`g2p.pl`** — Conversor grafema-fonema (G2P) para o português brasileiro.
  Produz a estrutura `sil/5` (onset, núcleo, coda, peso, acento) e a
  transcrição IPA.
- **`phonetics.pl`** — Motor de escansão silábica (com sinalefa) e extração
  de caudas de rima (consoante e toante). Registra `tradicao_padrao/1`
  como `portugues_silabico`.

## Tradição poética

A escansão para português brasileiro segue o modelo silábico:
- Contagem de sílabas (não moras)
- Corte na última tônica
- Sinalefa opcional entre vogais

## Limitações conhecidas

- Abertura de `e`/`o` tônicos sem acento gráfico (default: fechados)
- Letra `x` com pronúncia irregular (default: `/ʃ/`)
- Redução pretônica
- Clíticos átonos
- Hiato/ditongo de natureza lexical
