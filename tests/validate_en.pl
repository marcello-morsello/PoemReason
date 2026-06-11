:- encoding(utf8).
:- use_module('../rules/en/pipeline').
:- use_module(library(plunit)).

:- begin_tests(en_poems).

test(shakespeare_pentameter1) :-
    core:verso_ln('Shall I compare thee to a summers day', ln(_, _, Cont, _)),
    member(10, Cont).

test(shakespeare_pentameter2) :-
    core:verso_ln('Thou art more lovely and more temperate', ln(_, _, Cont, _)),
    member(10, Cont).

test(milton_blank_verse) :-
    core:verso_ln('Of Mans first disobedience and the fruit', ln(_, _, Cont, _)),
    member(10, Cont).

test(thomas_villanelle_line) :-
    core:verso_ln('Do not go gentle into that good night', ln(_, _, Cont, _)),
    member(10, Cont).

:- end_tests(en_poems).
