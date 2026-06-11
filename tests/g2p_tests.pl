:- encoding(utf8).
:- use_module('../rules/pt/g2p').
:- use_module(library(plunit)).

% ============================================================
%  g2p_tests.pl — Unit tests for the G2P (grapheme-to-phoneme) layer
%
%  Testes unitários para a camada G2P (grafema-fonema).
%  Each test checks that g2p/3 produces the expected IPA for a
%  Brazilian Portuguese word.
% ============================================================

:- begin_tests(g2p).

test(casa)       :- g2p(casa,       _, 'ˈkazɐ').
test(caro)       :- g2p(caro,       _, 'ˈkaɾu').
test(carro)      :- g2p(carro,      _, 'ˈkaʁu').
test(mar)        :- g2p(mar,        _, 'ˈmaʁ').
test(noite)      :- g2p(noite,      _, 'ˈnojtʃi').
test(dia)        :- g2p(dia,        _, 'ˈdʒiɐ').
test(agua, [nondet])  :- g2p('água',     _, 'ˈagwɐ').
test(campo)      :- g2p(campo,      _, 'ˈkɐ̃pu').
test(bom)        :- g2p(bom,        _, 'ˈbõ').
test(mae)        :- g2p('mãe',      _, 'ˈmɐ̃j').
test(pao)        :- g2p('pão',      _, 'ˈpɐ̃w').
test(mal)        :- g2p(mal,        _, 'ˈmaw').
test(alto)       :- g2p(alto,       _, 'ˈawtu').
test(chave)      :- g2p(chave,      _, 'ˈʃavi').
test(trabalho)   :- g2p(trabalho,   _, 'tɾaˈbaʎu').
test(felicidade) :- g2p(felicidade, _, 'felisiˈdadʒi').
test(coracao)    :- g2p('coração',  _, 'koɾaˈsɐ̃w').
test(voce)       :- g2p('você',     _, 'voˈse').
test(luz)        :- g2p(luz,        _, 'ˈlus').
test(sapo)       :- g2p(sapo,       _, 'ˈsapu').
test(mesa)       :- g2p(mesa,       _, 'ˈmezɐ').
test(gato)       :- g2p(gato,       _, 'ˈgatu').
test(porta, [nondet]) :- g2p(porta, _, 'ˈpoʁtɐ').  % default fechado (sem acento gráfico)
test(prato)      :- g2p(prato,      _, 'ˈpɾatu').
test(tia)        :- g2p(tia,        _, 'ˈtʃiɐ').

% Determinism: g2p/3 must return exactly one answer per word.
test(determinism) :-
    forall(
        member(W, [casa, mar, noite, campo, trabalho]),
        once(g2p(W, _, _))
    ).

:- end_tests(g2p).
