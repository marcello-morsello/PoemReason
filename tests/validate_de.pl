:- encoding(utf8).
:- use_module('../rules/de/pipeline').
:- use_module(library(plunit)).

:- begin_tests(de_poems).

test(goethe_erlkonig1) :-
    core:verso_ln('Wer reitet so spaet durch Nacht und Wind', ln(_, _, Cont, _)),
    Cont \== [].

test(goethe_erlkonig2) :-
    core:verso_ln('Es ist der Vater mit seinem Kind', ln(_, _, Cont, _)),
    Cont \== [].

:- end_tests(de_poems).
