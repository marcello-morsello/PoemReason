:- encoding(utf8).
:- use_module('../rules/es/pipeline').
:- use_module(library(plunit)).

:- begin_tests(es_poems).

test(marti_redondilla1) :-
    core:verso_ln('Cultivo una rosa blanca', ln(_, _, Cont, _)),
    member(8, Cont).

test(marti_redondilla2) :-
    core:verso_ln('en julio como en enero', ln(_, _, Cont, _)),
    member(8, Cont).

test(sorjuana_redondilla) :-
    core:verso_ln('Hombres necios que acusáis', ln(_, _, Cont, _)),
    member(8, Cont).

:- end_tests(es_poems).
