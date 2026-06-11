:- encoding(utf8).
:- use_module('../rules/pt/pipeline').
:- use_module('../rules/pt/phonetics', [contagens/3, cauda_consoante/2]).
:- use_module(library(plunit)).

% ============================================================
%  pipeline_tests.pl — Unit tests for the end-to-end pipeline
%
%  Testes unitários para o pipeline de ponta a ponta.
%  Tests that raw text is correctly processed through
%  G2P -> scansion -> rhyme -> ln/4 records.
% ============================================================

:- begin_tests(pipeline).

% A single verse produces an ln/4 record with non-empty fields
test(verso_ln_produces_record) :-
    verso_ln("casa bonita", ln(_, IPA, Cont, Classe)),
    IPA \== '',
    is_list(Cont),
    Cont \== [],
    Classe \== '?'.

% linha_sils returns non-empty sil list and IPA
test(linha_sils_basic) :-
    linha_sils("bom dia", Sils, IPA),
    Sils \== [],
    IPA \== ''.

% Two rhyming verses should get the same rhyme class
test(rhyming_verses_same_class) :-
    verso_ln("cantar", ln(_, _, _, C1)),
    verso_ln("amar",   ln(_, _, _, C2)),
    C1 == C2.

% A 7-syllable verse should include 7 in its scansion counts
test(heptasyllable_count, [nondet]) :-
    verso_ln("Eu sinto um grande amor", ln(_, _, Cont, _)),
    member(7, Cont).

:- end_tests(pipeline).
