:- module(credit_tests, []).

:- use_module('../rules/core').
:- use_module(library(plunit)).

:- begin_tests(credit_approval).

% Auto-approve: score >= 800 regardless of debt
test(auto_approve_high_score) :-
    aprovar_credito(ana, aprovado).

% Standard approve: score >= 700, debt < 30% income
test(approve_standard) :-
    aprovar_credito(joao, aprovado).

% Manual review: score in [600,700), debt < 40% income
test(manual_review) :-
    aprovar_credito(maria, analise_manual).

% Denied: score < 600
test(denied_low_score) :-
    aprovar_credito(pedro, negado).

% Determinism: each client yields exactly one answer
test(deterministic, [forall(core:cliente(C,_,_,_))]) :-
    once(aprovar_credito(C, _)).

:- end_tests(credit_approval).
