:- encoding(utf8).
:- use_module('../rules/structural_validator').
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

% --- NEGATIVE VALIDATION / VALIDAÇÃO NEGATIVA -----------------

test(trova_wrong_rhyme, [fail]) :-
    exemplo(trova_errada, P),
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
