# Módulo Español — PoemReason

## Archivos

- **`g2p.pl`** — Conversión grafema-fonema simplificada para el español.
  Usa seseo (c+e/i, z -> /s/). Maneja ñ, ll, ch, j, h muda, b/v.
- **`phonetics.pl`** — Escansión silábica con sinalefa y corte en la
  última tónica. Tradición: espanhol_silabico.

## Tradición poética

La métrica española es silábica:
- Versos de arte menor (octosílabo) y arte mayor (endecasílabo)
- Sinalefa opcional entre vocales
- Corte en la última sílaba tónica
- Rima consonante y asonante

## Formas locales

- **seguidilla** — 7-5a-7-5a, asonante en pares
- **redondilla** — 4 octosílabos, abba
- **cuarteta** — 4 octosílabos, abab
- **copla** — 4 octosílabos, asonante (-a-a)
- **lira** — 5 versos (7a-11B-7a-7b-11B), Garcilaso
- **décima espinela** — 10 octosílabos, abbaaccddc
- **octava real** — 8 endecasílabos, ABABABCC
- **cuaderna vía** — 4 alejandrinos (14), AAAA
- **silva** — Combinación libre de 7 y 11 sílabas

## ⚠ Pendiente: romance

El **romance** (serie ilimitada de octosílabos con rima asonante en
pares) requiere el esquema `toante_par` que aún no está implementado
en el validador estructural común.  Agendado para revisión con
especialista en métrica.

## Limitaciones

- Seseo (no distingue /θ/ de /s/)
- Diptongos no siempre detectados (ie, ue)
- No se marca la vibrante múltiple (ɾ vs r)
