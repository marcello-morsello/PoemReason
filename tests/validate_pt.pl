:- encoding(utf8).
:- use_module('../rules/pt/pipeline').
:- use_module(library(plunit)).

:- begin_tests(pt_poems).

test(cancao_exilio_v1) :-
    core:verso_ln('Minha terra tem palmeiras', ln(_, _, Cont, _)),
    member(7, Cont).

test(cancao_exilio_v2) :-
    core:verso_ln('Onde canta o Sabiá', ln(_, _, Cont, _)),
    member(7, Cont).

test(camoes_setessilabo) :-
    core:verso_ln('Sôbolos rios que vão', ln(_, _, Cont, _)),
    member(7, Cont).

test(augusto_anjos_decassilabo) :-
    core:verso_ln('Vês Ninguém assistiu ao formidável', ln(_, _, Cont, _)),
    member(10, Cont).

test(pt_trova_valida) :-
    structural_validator:valida(trova, poema([
        verso("Eu sinto um grande amor", [7], rima(or, or)),
        verso("que sopra como o vento",  [7], rima(ento, ento)),
        verso("e cura toda a dor",       [7], rima(or, or)),
        verso("num passo doce e lento",  [7], rima(ento, ento))
    ])).

test(pt_quadra_toante) :-
    structural_validator:valida(quadra, poema([
        verso("vejo o seu olhar",   [7], rima(ar,   a)),
        verso("entrando pelo mato", [7], rima(ato, ao)),
        verso("eu sigo lá no muro", [7], rima(uro,  u)),
        verso("perdido pelo lago",  [7], rima(ago,  ao))
    ])).

:- end_tests(pt_poems).
