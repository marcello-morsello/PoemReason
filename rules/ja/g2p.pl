:- module(g2p, [g2p/3]).
:- encoding(utf8).
:- discontiguous g2p:g2p/3.
% ============================================================
%  g2p.pl — Japanese G2P (simplified: kana → mora counting)
%
%  G2P japonês simplificado: kana → contagem de moras.
%
%  Japanese kana (hiragana/katakana) are phonetic: each character
%  represents one mora.  This module counts characters and builds
%  sil/5 structures with weight=1 per mora.
%
%  O kana japonês (hiragana/katakana) é fonético: cada caractere
%  representa uma mora.  Este módulo conta caracteres e constrói
%  sil/5 com peso 1 por mora.
%
%  Known limitations / Limitações conhecidas:
%    - Does not handle っ (gemination) — adds an extra mora
%    - Does not handle ん (nasal coda) — adds an extra mora
%    - Small kana (ゃ, ゅ, ょ, ぁ, etc.) are counted as full morae
%      instead of palatalization (should be 0.5 mora)
%    - Full IPA transcription is TODO
%    - Mixed kanji input is NOT supported (pre-convert to kana)
% ============================================================

hiragana(C) :- C >= 0x3041, C =< 0x3096.
katakana(C) :- C >= 0x30A1, C =< 0x30F6.
kana(C) :- hiragana(C) ; katakana(C).

%! g2p(+Word, -Syllables, -IPA) is det.
%  For kana input, each character = 1 mora = 1 syllable with weight 1.
%  Returns sil/5 per character with weight 1.  IPA is '(kana)'.
%
%  Para input kana, cada caractere = 1 mora = 1 sílaba peso 1.
g2p(Palavra, Sils, IPA) :-
    atom_string(Palavra, Str),
    string_codes(Str, Codes),
    include(kana, Codes, KanaCodes),
    KanaCodes \== [],
    maplist(kana_sil, KanaCodes, Sils),
    ( Sils == [] -> IPA = '' ; IPA = '(kana)' ).

kana_sil(Code, sil([], [C], [], 1, atona)) :-
    atom_codes(Atom, [Code]),
    atom_string(Atom, C).

% Handle space-separated morae (e.g. "to u kyo u" = 5 morae)
g2p(Palavra, Sils, IPA) :-
    atom_string(Palavra, Str),
    \+ (string_codes(Str, Codes), include(kana, Codes, [_|_])),
    split_string(Str, " ", "", Parts),
    Parts \== [],
    maplist(mora_sil, Parts, Sils),
    atomic_list_concat(Parts, ' ', IPA).

mora_sil(Str, sil([], [C], [], 1, atona)) :-
    sub_string(Str, 0, 1, _, C).
