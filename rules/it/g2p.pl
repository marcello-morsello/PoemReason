:- module(g2p, [g2p/3]).
:- encoding(utf8).
% ============================================================
%  g2p.pl — Italian G2P (grapheme-to-phoneme, simplified)
%
%  Conversione grafema-fonema per l'italiano (semplificata).
%
%  Based on standard Italian phonology.  Produces sil/5 structures
%  compatible with the common scansion engine (synaloepha, stress cut).
%
%  Known limitations / Limitazioni note:
%    - Does not distinguish open vs closed e/o without graphic accent
%    - z -> /ts/ always (no /dz/ distinction)
%    - s intervocalic -> /z/ always
%    - Double consonants treated as coda+onset for gemination
%    - Syntactic doubling (raddoppiamento) not handled
% ============================================================

vogale(a). vogale(e). vogale(i). vogale(o). vogale(u).
vogale('à'). vogale('è'). vogale('é'). vogale('ì'). vogale('ò'). vogale('ó'). vogale('ù').
frontale(e). frontale(i). frontale('è'). frontale('é'). frontale('ì').

vocal_map(a, a, 0). vocal_map(e, e, 0). vocal_map(i, i, 0). vocal_map(o, o, 0). vocal_map(u, u, 0).
vocal_map('à', a, 1). vocal_map('è', 'ɛ', 1). vocal_map('é', e, 1).
vocal_map('ì', i, 1). vocal_map('ò', 'ɔ', 1). vocal_map('ó', o, 1). vocal_map('ù', u, 1).

consonante_semplice(C) :- member(C, [p,b,t,d,k,g,f,v,s,z,l,m,n,r]).

%! g2p(+Word, -Syllables, -IPA) is det.
g2p(Parola, Sillabe, IPA) :-
    downcase_atom(Parola, Low),
    atom_chars(Low, Chars),
    exclude(==(' '), Chars, Chars1),
    fonemizza(Chars1, Toks),
    sillabifica(Toks, Sibs),
    tonicita(Sibs, ITon),
    ipa_di(Sibs, ITon, Sillabe, IPA), !.

% ---- 1. FONEMIZZA / phonemization ---------------------------
fonemizza([], []).
% sc + e/i -> ʃʃ
fonemizza([s,c,C|T], [cons('ʃ'),cons('ʃ')|R]) :- frontale(C), !, fonemizza([C|T], R).
% gn -> ɲ (palatal nasal)
fonemizza([g,n|T], [cons('ɲ')|R]) :- !, fonemizza(T, R).
% gl + i -> ʎ (palatal lateral)
fonemizza([g,l,C|T], [cons('ʎ')|R]) :- C == i, !, fonemizza(T, R).
% ch -> k (before e/i)
fonemizza([c,h|T], [cons(k)|R]) :- !, fonemizza(T, R).
% gh -> g (before e/i)
fonemizza([g,h|T], [cons(g)|R]) :- !, fonemizza(T, R).
% c + e/i -> tʃ
fonemizza([c,C|T], [cons('tʃ')|R]) :- frontale(C), !, fonemizza([C|T], R).
% c otherwise -> k
fonemizza([c|T], [cons(k)|R]) :- !, fonemizza(T, R).
% g + e/i -> dʒ
fonemizza([g,C|T], [cons('dʒ')|R]) :- frontale(C), !, fonemizza([C|T], R).
% g otherwise -> g
fonemizza([g|T], [cons(g)|R]) :- !, fonemizza(T, R).
% h -> silent
fonemizza([h|T], R) :- !, fonemizza(T, R).
% q -> k
fonemizza([q|T], [cons(k)|R]) :- !, fonemizza(T, R).
% Double consonants: two identical = geminate (coda + onset)
fonemizza([C,C|T], [cons(C),cons(C)|R]) :- member(C, [p,b,t,d,k,g,f,v,s,z,l,m,n,r]), !,
    fonemizza(T, R).
% z -> ts
fonemizza([z|T], [cons('ts')|R]) :- !, fonemizza(T, R).
% s, simple consonant
fonemizza([C|T], [cons(C)|R]) :- consonante_semplice(C), !, fonemizza(T, R).
% vowels
fonemizza([V|T], [vo(Q,Ac)|R]) :- vocal_map(V, Q, Ac), !, fonemizza(T, R).
fonemizza([_|T], R) :- fonemizza(T, R).

% Intervocalic s -> z
aggiusta([], []).
aggiusta([vo(Q,A), cons(s), vo(Q2,A2)|T], [vo(Q,A), cons(z)|R]) :-
    !, aggiusta([vo(Q2,A2)|T], R).
aggiusta([X|T], [X|R]) :- aggiusta(T, R).

% ---- 2. SILLABIFICA / syllabification (maximum onset) --------
sillabifica(Toks, Sibs) :-
    segmenti(Toks, Segs),
    prendi_cons(Segs, Attacco0, Resto),
    blocchi(Resto, Blocchi),
    costruisci(Attacco0, Blocchi, Sibs).

segmenti([], []).
segmenti([vo(Q,Ac)|T], [nuc([Q],Ac)|R]) :- !, segmenti(T, R).
segmenti([cons(C)|T], [c(C)|R]) :- !, segmenti(T, R).
segmenti([_|T], R) :- segmenti(T, R).

prendi_cons([S|T], [C|Cs], R) :- S = c(C), !, prendi_cons(T, Cs, R).
prendi_cons(T, [], T).

blocchi([], []).
blocchi([nuc(Vs,Ac)|T], [blocco(Vs,Ac,Cons)|R]) :-
    !, prendi_cons(T, Cons, T2), blocchi(T2, R).

costruisci(Ons, [blocco(Vs,Ac,Cons)], [sib(Ons,Vs,Cons,Ac)]) :- !.
costruisci(Ons, [blocco(Vs,Ac,Cons)|Resto], [sib(Ons,Vs,Coda,Ac)|Rs]) :-
    attacco_massimo(Cons, Coda, OnsProx),
    costruisci(OnsProx, Resto, Rs).

attacco_massimo([], [], []).
attacco_massimo([C], [], [C]).
attacco_massimo(Cs, Coda, Attacco) :-
    append(Pref, [A,B], Cs),
    ( gruppo_valido(A, B) -> Attacco = [A,B], Coda = Pref
    ; Attacco = [B], append(Pref, [A], Coda) ).

gruppo_valido(O, r) :- member(O, [p,b,t,d,k,g,f,v]).
gruppo_valido(O, l) :- member(O, [p,b,t,d,k,g,f,v]).

% ---- 3. TONICITÀ / stress ------------------------------------
tonicita(Sibs, ITon) :-
    length(Sibs, N),
    ( N =< 1 -> ITon = 1
    ; nth1(I, Sibs, sib(_,_,_,1)), !, ITon = I   % graphic accent
    ; ITon is N - 1 ).                              % default: penultimate

% ---- 4. IPA + REDUCE -----------------------------------------
ipa_di([], _, [], '').
ipa_di(Sibs, ITon, Sillabe, IPA) :-
    length(Sibs, N),
    marca_tonicita(Sibs, 1, ITon, N, Stonate),
    maplist(ipa_sillaba, Stonate, Parti),
    atomic_list_concat(Parti, IPA),
    Sillabe = Stonate.

marca_tonicita([], _, _, _, []).
marca_tonicita([sib(O,V,C,_)|T], I, ITon, Tot, [sil(O,V,C,1,Ac)|R]) :-
    ( I =:= ITon -> Ac = tonica ; Ac = atona ),
    I1 is I + 1,
    marca_tonicita(T, I1, ITon, Tot, R).

ipa_sillaba(sil(O,V,C,_,Ac), Str) :-
    append(O, V, ON), append(ON, C, Foni),
    atomic_list_concat(Foni, Seg),
    ( Ac == tonica -> atom_concat('ˈ', Seg, Str) ; Str = Seg ).
