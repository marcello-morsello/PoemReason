:- encoding(utf8).
:- use_module('../rules/diagnostics').
:- use_module(library(plunit)).

% ============================================================
%  diagnostics_tests.pl — Unit tests for the diagnostics/report layer
%
%  Testes unitários para a camada de diagnóstico/relatório.
%  Covers correct sonnets, sonnets with errors, and villanelle
%  with broken refrain — verifying problem lists.
% ============================================================

:- begin_tests(diagnostics).

% Correct Italian sonnet: zero problems
test(sonnet_ok_no_problems) :-
    diagnostics:exemplo_diag(soneto_ok, P),
    diagnostica(soneto_italiano, P, Probs),
    Probs == [].

% Sonnet with two errors: should find problems
test(sonnet_errors_detected) :-
    diagnostics:exemplo_diag(soneto_com_erros, P),
    diagnostica(soneto_italiano, P, Probs),
    Probs \== [].

% Sonnet with errors: should have metric problem on verse 7
test(sonnet_metric_error_v7, [nondet]) :-
    diagnostics:exemplo_diag(soneto_com_erros, P),
    diagnostica(soneto_italiano, P, Probs),
    member(prob(_, 7, metrica, _), Probs).

% Sonnet with errors: should have rhyme problem on verse 4
test(sonnet_rhyme_error_v4) :-
    diagnostics:exemplo_diag(soneto_com_erros, P),
    diagnostica(soneto_italiano, P, Probs),
    member(prob(_, 4, rima, _), Probs).

% Villanelle with broken refrain: should detect refrain problem
test(vilanela_refrain_problem) :-
    diagnostics:exemplo_diag(vilanela_quebrada, P),
    diagnostica(vilanela, P, Probs),
    member(prob(_, _, refrao, _), Probs).

% estrofe_de locates correctly
test(stanza_location) :-
    estrofe_de([4,4,3,3], 5, 2, _).

test(stanza_location_first) :-
    estrofe_de([4,4,3,3], 3, 1, _).

:- end_tests(diagnostics).
