:- encoding(utf8).
:- use_module('../rules/fr/g2p').
:- use_module(library(plunit)).

:- begin_tests(g2p_fr).

test(soleil) :- g2p('soleil', _, IPA), sub_atom(IPA, _, _, _, 'əil').
test(chat)   :- g2p('chat', _, IPA), IPA = 'ʃa'.
test(bon)    :- g2p('bon', _, IPA), sub_atom(IPA, _, _, _, 'ɔ̃').
test(lune)   :- g2p('lune', _, _).
test(mer)    :- g2p('mer', _, IPA), sub_atom(IPA, _, _, _, 'mər').
test(porte)  :- g2p('porte', _, IPA), sub_atom(IPA, _, _, _, 'port').
test(rouge)  :- g2p('rouge', _, IPA), sub_atom(IPA, _, _, _, 'ʒ').
test(chanson):- g2p('chanson', _, IPA), sub_atom(IPA, _, _, _, 'ʃɑ̃').

test(determinism) :-
    forall(member(W, [soleil,chat,bon,mer,porte,rouge]),
           once(g2p(W, _, _))).

:- end_tests(g2p_fr).
