:- encoding(utf8).
:- use_module('../rules/en/g2p').
:- use_module(library(plunit)).

:- begin_tests(g2p_en).

test(hello)   :- g2p('hello', _, IPA), sub_atom(IPA, _, _, _, 'ɛl').
test(world)   :- g2p('world', _, IPA), sub_atom(IPA, _, _, _, 'w').
test(shall)   :- g2p('shall', _, IPA), sub_atom(IPA, _, _, _, 'æ').
test(thee)    :- g2p('thee', _, IPA), sub_atom(IPA, _, _, _, 'θ').
test(day)     :- g2p('day', _, IPA), sub_atom(IPA, _, _, _, 'dæ').
test(summer)  :- g2p('summer', _, IPA), sub_atom(IPA, _, _, _, 's').
test(love)    :- g2p('love', _, IPA), sub_atom(IPA, _, _, _, 'lɒ').

test(determinism) :-
    forall(member(W, [hello,world,shall,thee,day,summer,love]),
           once(g2p(W, _, _))).

:- end_tests(g2p_en).
