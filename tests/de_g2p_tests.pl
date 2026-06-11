:- encoding(utf8).
:- use_module('../rules/de/g2p').
:- use_module(library(plunit)).

:- begin_tests(g2p_de).

test(hallo)  :- g2p('hallo', _, IPA), sub_atom(IPA, _, _, _, 'hallɔ').
test(welt)   :- g2p('welt', _, IPA), sub_atom(IPA, _, _, _, 'ɛlt').
test(sonne)  :- g2p('sonne', _, IPA), sub_atom(IPA, _, _, _, 'sɔn').
test(mond)   :- g2p('mond', _, IPA), sub_atom(IPA, _, _, _, 'mɔnt').
test(nacht)  :- g2p('nacht', _, IPA), sub_atom(IPA, _, _, _, 'na').
test(baum)   :- g2p('baum', _, IPA), sub_atom(IPA, _, _, _, 'baʊ').
test(schon)  :- g2p('schön', _, IPA), sub_atom(IPA, _, _, _, 'ʃ').
test(grün)   :- g2p('grün', _, IPA), sub_atom(IPA, _, _, _, 'gr').

test(tag)    :- g2p('tag', _, IPA), sub_atom(IPA, _, _, _, 'ta').

test(determinism) :-
    forall(member(W, [hallo,welt,sonne,mond,nacht,baum]),
           once(g2p(W, _, _))).

:- end_tests(g2p_de).
