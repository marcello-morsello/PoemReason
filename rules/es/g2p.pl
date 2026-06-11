:- module(g2p, [g2p/3]).
:- encoding(utf8).
% ============================================================
%  g2p.pl — Spanish G2P (grapheme-to-phoneme, simplified)
%
%  Conversión grafema-fonema para el español (simplificada).
%
%  Uses seseo (c+e/i, z -> /s/) as default.
%  Handles ñ, ll, ch, j, silent h, b/v neutralization.
%  Default stress: penultimate (paroxytone).
% ============================================================

vocal_code(C) :- char_code(Ch, C), member(Ch, [a,e,i,o,u,á,é,í,ó,ú,ü,y]).

vocal_sal(C, Q, Ac) :-
    char_code(Ch, C),
    member(Ch-Q-Ac, [a-'a'-0, e-'e'-0, i-'i'-0, o-'o'-0, u-'u'-0,
                     á-'a'-1, é-'e'-1, í-'i'-1, ó-'o'-1, ú-'u'-1,
                     ü-'u'-0, y-'i'-0]).

simple_cons(C, A) :-
    char_code(A, C),
    member(A, [p,b,t,d,k,g,f,s,l,m,n,r,j,ʝ]).

%! g2p(+Word, -Syllables, -IPA) is det.
g2p(Word, Syllables, IPA) :-
    atom_codes(Word, Codes),
    downcase_codes(Codes, Low),
    phrase(fonemas(Low), Tokens),
    silabifica(Tokens, Sibs),
    tonicidad(Sibs, ITon),
    ipa_final(Sibs, ITon, Syllables, IPA), !.

g2p(_, [], '?').

downcase_codes([], []).
downcase_codes([C|T], [L|R]) :-
    ( C >= 0x41, C =< 0x5A -> L is C + 32 ; L = C ),
    downcase_codes(T, R).

% ---- DCG: caracteres -> fonemas -------------------------------
fonemas([]) --> [].
fonemas([0'c,0'h|T]) --> [cons('tʃ')], !, fonemas(T).
fonemas([0'l,0'l|T]) --> [cons('ʝ')], !, fonemas(T).
fonemas([0'ñ|T]) --> [cons('ɲ')], !, fonemas(T).
fonemas([0'c,C|T]) --> {member(C, [0'e,0'i])}, [cons('s')], !, fonemas([C|T]).
fonemas([0'c|T]) --> [cons(k)], !, fonemas(T).
fonemas([0'g,C|T]) --> {member(C, [0'e,0'i])}, [cons('x')], !, fonemas([C|T]).
fonemas([0'g|T]) --> [cons(g)], !, fonemas(T).
fonemas([0'q,0'u|T]) --> [cons(k)], !, fonemas(T).
fonemas([0'j|T]) --> [cons('x')], !, fonemas(T).
fonemas([0'h|T]) --> fonemas(T).  % h muda
fonemas([0'v|T]) --> [cons(b)], !, fonemas(T).  % v=b
fonemas([0'z|T]) --> [cons(s)], !, fonemas(T).
fonemas([0'ñ|T]) --> [cons('ɲ')], !, fonemas(T).
fonemas([C|T]) --> {simple_cons(C, A)}, [cons(A)], !, fonemas(T).
fonemas([V|T]) --> {vocal_sal(V, Q, Ac)}, [vo(Q, Ac)], !, fonemas(T).
fonemas([_|T]) --> fonemas(T).

% ---- silabificación (ataque máximo) ---------------------------
silabifica(Toks, Sibs) :-
    segs(Toks, Ss),
    toma_cons(Ss, Ons, Rest),
    bloques(Rest, Blks),
    construye(Ons, Blks, Sibs).

segs([], []).
segs([vo(Q,Ac)|T], [nuc([Q],Ac)|R]) :- !, segs(T, R).
segs([cons(C)|T], [c(C)|R]) :- !, segs(T, R).
segs([_|T], R) :- segs(T, R).

toma_cons([C|T], [X|Xs], R) :- C = c(X), !, toma_cons(T, Xs, R).
toma_cons(T, [], T).

bloques([], []).
bloques([nuc(Vs,Ac)|T], [blk(Vs,Ac,Cs)|R]) :-
    !, toma_cons(T, Cs, T2), bloques(T2, R).

construye(Ons, [blk(Vs,Ac,Cs)], [sib(Ons,Vs,Cs,Ac)]) :- !.
construye(Ons, [blk(Vs,Ac,Cs)|Rest], [sib(Ons,Vs,Cd,Ac)|Rs]) :-
    ataque_max(Cs, Cd, Next),
    construye(Next, Rest, Rs).

ataque_max([], [], []).
ataque_max([C], [], [C]).
ataque_max(Cs, Cd, On) :-
    append(Pref, [A,B], Cs),
    ( grupo_val(A, B) -> On = [A,B], Cd = Pref
    ; On = [B], append(Pref, [A], Cd) ).

grupo_val(O, r) :- member(O, [p,b,t,d,k,g,f,v]).
grupo_val(O, l) :- member(O, [p,b,t,d,k,g,f,v]).

% ---- tonicidad (acento gráfico, sino penúltima) --------------
tonicidad(Sibs, ITon) :-
    length(Sibs, N),
    ( N =< 1 -> ITon = 1
    ; nth1(I, Sibs, sib(_,_,_,1)), !, ITon = I
    ; ITon is N - 1 ).

% ---- IPA final ------------------------------------------------
ipa_final([], _, [], '').
ipa_final(Sibs, ITon, Salidas, IPA) :-
    length(Sibs, N),
    marca_ton(Sibs, 1, ITon, N, Stonate),
    maplist(ipa_syl, Stonate, Parts),
    atomic_list_concat(Parts, IPA),
    Salidas = Stonate.

marca_ton([], _, _, _, []).
marca_ton([sib(O,V,C,_)|T], I, ITon, N, [sil(O,V,C,1,Ac)|R]) :-
    ( I =:= ITon -> Ac = tonica ; Ac = atona ),
    I1 is I + 1,
    marca_ton(T, I1, ITon, N, R).

ipa_syl(sil(O,V,C,_,_), Str) :-
    append(O, V, ON), append(ON, C, Fs),
    atomic_list_concat(Fs, Str).
