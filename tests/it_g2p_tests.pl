:- encoding(utf8).
:- use_module('../rules/it/g2p').
:- use_module(library(plunit)).

:- begin_tests(g2p_it).

test(casa)   :- g2p('casa', _, IPA), IPA = 'ˈkasa'.
test(vita)   :- g2p('vita', _, IPA), sub_atom(IPA, _, _, _, 'vita').
test(notte)  :- g2p('notte', _, IPA), sub_atom(IPA, _, _, _, 'notte').
test(gatto)  :- g2p('gatto', _, IPA), sub_atom(IPA, _, _, _, 'gatto').
test(sole)   :- g2p('sole', _, IPA), sub_atom(IPA, _, _, _, 'sole').
test(cane)   :- g2p('cane', _, IPA), sub_atom(IPA, _, _, _, 'kane').
test(gente)  :- g2p('gente', _, IPA), sub_atom(IPA, _, _, _, 'dʒente').
test(cibo)   :- g2p('cibo', _, IPA), sub_atom(IPA, _, _, _, 'tʃibo').
test(amore)  :- g2p('amore', _, IPA), sub_atom(IPA, _, _, _, 'more').
test(donna)  :- g2p('donna', _, IPA), sub_atom(IPA, _, _, _, 'donna').

test(determinism) :-
    forall(member(W, [casa,vita,notte,sole,amore]),
           once(g2p(W, _, _))).

:- end_tests(g2p_it).
