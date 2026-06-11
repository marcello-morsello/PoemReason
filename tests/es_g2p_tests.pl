:- encoding(utf8).
:- use_module('../rules/es/g2p').
:- use_module(library(plunit)).

:- begin_tests(g2p_es).

test(casa)   :- g2p('casa', _, IPA), sub_atom(IPA, _, _, _, 'kasa').
test(perro)  :- g2p('perro', _, IPA), sub_atom(IPA, _, _, _, 'p').
test(noche)  :- g2p('noche', _, IPA), sub_atom(IPA, _, _, _, 'notʃ').
test(lluvia) :- g2p('lluvia', _, IPA), sub_atom(IPA, _, _, _, 'ʝ').
test(mañana) :- g2p('mañana', _, IPA), sub_atom(IPA, _, _, _, 'maɲa').
test(sol)    :- g2p('sol', _, IPA), sub_atom(IPA, _, _, _, 'sol').
test(rosa)   :- g2p('rosa', _, IPA), sub_atom(IPA, _, _, _, 'rosa').
test(cielo)  :- g2p('cielo', _, IPA), sub_atom(IPA, _, _, _, 'siel').
test(gente)  :- g2p('gente', _, IPA), sub_atom(IPA, _, _, _, 'xent').
test(jamón)  :- g2p('jamón', _, IPA), sub_atom(IPA, _, _, _, 'xam').

test(determinism) :-
    forall(member(W, [casa,perro,noche,sol,rosa,cielo]),
           once(g2p(W, _, _))).

:- end_tests(g2p_es).
