:- encoding(utf8).
:- use_module('../rules/it/pipeline').
:- use_module(library(plunit)).

:- begin_tests(it_poems).

test(dante_endecasillabo1) :-
    core:verso_ln('Nel mezzo del cammin di nostra vita', ln(_, _, Cont, _)),
    member(10, Cont).

test(dante_endecasillabo2) :-
    core:verso_ln('mi ritrovai per una selva oscura', ln(_, _, Cont, _)),
    member(10, Cont).

test(petrarca_endecasillabo1) :-
    core:verso_ln('Pace non trovo e non ho da far guerra', ln(_, _, Cont, _)),
    member(10, Cont).

:- end_tests(it_poems).
