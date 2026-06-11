:- encoding(utf8).
:- use_module('../rules/common/structural_validator').
:- use_module(library(plunit)).

% ============================================================
%  structural_tests.pl — Unit tests for the structural validator
%
%  Testes unitários para o validador estrutural.
%  Covers haiku, trova, villanelle, and sestina validation,
%  including positive, negative, and diagnostic tests.
% ============================================================

:- begin_tests(structural_validator).

% --- POSITIVE VALIDATION / VALIDAÇÃO POSITIVA -----------------

test(haiku_valid, [nondet]) :-
    exemplo(meu_haiku, P),
    valida(haiku, P).

test(trova_valid) :-
    exemplo(minha_trova, P),
    valida(trova, P).

test(vilanela_valid, [nondet]) :-
    exemplo(minha_vilanela, P),
    valida(vilanela, P).

test(sextina_valid, [nondet]) :-
    exemplo(minha_sextina, P),
    valida(sextina, P).

% Quadra in the popular tradition: rhyme matches only on the vowel
% tail.  The fixture verses share vowels per [a,b,c,b] but disagree
% on consonants, so the strict trova check (consonant rhyme) would
% reject the same poem.
%
% Quadra na tradição popular: rima casa só pelas vogais.  Os versos
% compartilham as vogais no padrão [a,b,c,b] mas divergem nas
% consoantes, então a trova estrita (rima consoante) rejeitaria.
test(quadra_toante_valid, [nondet]) :-
    exemplo(minha_quadra_toante, P),
    valida(quadra, P).

% --- NEGATIVE VALIDATION / VALIDAÇÃO NEGATIVA -----------------

test(trova_wrong_rhyme, [fail]) :-
    exemplo(trova_errada, P),
    valida(trova, P).

% Same body as the quadra fixture, but v4 swaps the vowel tail and
% breaks the assonant pattern, so even the popular-mode quadra fails.
test(quadra_toante_broken, [fail]) :-
    exemplo(quadra_toante_quebrada, P),
    valida(quadra, P).

% The same assonant fixture is rejected when validated as a strict
% trova, because the consonant tails disagree at v2 vs v4.
% Locks in that flipping a form to toante actually loosens it.
%
% O mesmo poema toante é rejeitado quando validado como trova
% estrita, pois as caudas consoantes divergem em v2/v4.  Prova que
% mudar o modo afrouxa a checagem.
test(quadra_toante_rejected_as_strict_trova, [fail]) :-
    exemplo(minha_quadra_toante, P),
    valida(trova, P).

test(vilanela_broken_refrain, [fail]) :-
    exemplo(vilanela_quebrada, P),
    valida(vilanela, P).

test(sextina_broken_permutation, [fail]) :-
    exemplo(sextina_quebrada, P),
    valida(sextina, P).

% --- IDENTIFICATION / IDENTIFICAÇÃO --------------------------

test(identify_sextina, [nondet]) :-
    exemplo(minha_sextina, P),
    identifica(P, sextina).

% --- DIAGNOSTICS / DIAGNÓSTICO --------------------------------

test(diagnostico_vilanela_quebrada, [nondet]) :-
    exemplo(vilanela_quebrada, P),
    \+ valida(vilanela, P).

:- end_tests(structural_validator).
