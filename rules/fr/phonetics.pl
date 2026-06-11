:- module(phonetics, [
    escande/3,
    contagens/3,
    cauda_consoante/2,
    cauda_toante/2,
    rima_consoante/2,
    rima_toante/2,
    tradicao_padrao/1
]).
:- encoding(utf8).
% ============================================================
%  phonetics.pl — French phonetic versification engine
%
%  Moteur de scansion et rime pour le français.
%
%  French poetry counts syllables (alexandrin = 12).
%  No stress cut — count all syllables to the end.
%  No synaloepha — vowel elision handled by e-muet in G2P.
%
%  La poésie française compte les syllabes (alexandrin = 12).
%  Pas de coupe à l'accent — toutes les syllabes comptent.
%  Pas de sinalèphe — l'élision est gérée par le e-muet.
% ============================================================

tradicao_padrao(francais_syllabique).
unite(francais_syllabique, syllabe).

% ---- syllable count (whole line, no stress cut) --------------
escande(Trad, Vers, N) :-
    unite(Trad, syllabe), !,
    length(Vers, Len),
    N = Len.

contagens(Trad, Vers, [N]) :-
    escande(Trad, Vers, N).

% ---- rhyme / rime -------------------------------------------
% French rhyme is based on the last syllable's vowel + following
% consonants.  We extract from the last syllable to the end.

cauda_consoante(Vers, Cauda) :-
    reverse(Vers, [sil(_, Nuc, Coda, _, _)|_]),
    append(Nuc, Coda, Cauda).

cauda_toante(Vers, Vogais) :-
    reverse(Vers, [sil(_, Nuc, _, _, _)|_]),
    Vogais = Nuc.

rima_consoante(V1, V2) :- cauda_consoante(V1, C), cauda_consoante(V2, C).
rima_toante(V1, V2)    :- cauda_toante(V1, C),    cauda_toante(V2, C).

% ============================================================
%  FRENCH FORMS (multifile into common modules)
% ============================================================
:- multifile structural_validator:forma/4.
:- multifile diagnostics:forma_estr/4.

% Sonnet français: 14 alexandrins (12 syllabes)
structural_validator:forma(sonnet_fr, 14, M,
    [a,b,b,a, a,b,b,a, c,c,d, e,e,d]) :-
    repete(12, 14, M).
diagnostics:forma_estr(sonnet_fr, [4,4,3,3], repete(12, 14, _),
    [a,b,b,a, a,b,b,a, c,c,d, e,e,d]).

% Ballade: 3 huitains (8 vers, octosyllabes) + envoi (4 vers)
structural_validator:forma(ballade, 28, M,
    [a,b,a,b,b,c,b,c, a,b,a,b,b,c,b,c, a,b,a,b,b,c,b,c, b,c,b,c]) :-
    repete(8, 28, M).
diagnostics:forma_estr(ballade, [8,8,8,4], repete(8, 28, _),
    [a,b,a,b,b,c,b,c, a,b,a,b,b,c,b,c, a,b,a,b,b,c,b,c, b,c,b,c]).

% Triolet: 8 vers, 2 rimes, ABaAabAB
structural_validator:forma(triolet, 8, M,
    [a,b,a,a,a,b,a,b]) :- repete(8, 8, M).
diagnostics:forma_estr(triolet, [8], repete(8, 8, _),
    [a,b,a,a,a,b,a,b]).

% Rondeau: 15 vers, octosyllabes, aabba aabR aabbaR
structural_validator:forma(rondeau, 15, M,
    [a,a,b,b,a, a,a,b,r, a,a,b,b,a,r]) :-
    repete(8, 15, M).
diagnostics:forma_estr(rondeau, [15], repete(8, 15, _),
    [a,a,b,b,a, a,a,b,r, a,a,b,b,a,r]).

% Pantoum: quatrains à rimes croisées ABAB (pair number, >= 2 stanzas)
structural_validator:forma(pantoum, N, M,
    [a,b,a,b]) :-
    N mod 4 =:= 0, N >= 8,
    repete(8, N, M).
