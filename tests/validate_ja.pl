:- encoding(utf8).
:- use_module('../rules/ja/pipeline').
:- use_module(library(plunit)).

:- begin_tests(ja_poems).

test(basho_line1) :-
    core:verso_ln('ふるいけや', ln(_, _, Cont, _)),
    member(5, Cont).

test(basho_line2) :-
    core:verso_ln('かわずとびこむ', ln(_, _, Cont, _)),
    member(7, Cont).

test(basho_line3) :-
    core:verso_ln('みずのおと', ln(_, _, Cont, _)),
    member(5, Cont).

test(haiku_form) :-
    structural_validator:valida(haiku, poema([
        verso("F1", [5], rima(a,a)),
        verso("F2", [7], rima(b,b)),
        verso("F3", [5], rima(c,c))
    ])).

:- end_tests(ja_poems).
