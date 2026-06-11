:- encoding(utf8).
:- use_module('../rules/fr/pipeline').
:- use_module(library(plunit)).

:- begin_tests(fr_poems).

test(hugo_alexandrin1) :-
    core:verso_ln('Demain des laube', ln(_, _, Cont, _)),
    Cont \== [].

test(hugo_alexandrin2) :-
    core:verso_ln('je partirai vois tu je sais', ln(_, _, Cont, _)),
    Cont \== [].

test(dubellay_alexandrin) :-
    core:verso_ln('Heureux qui comme Ulysse a fait un beau voyage', ln(_, _, Cont, _)),
    Cont \== [].

:- end_tests(fr_poems).
