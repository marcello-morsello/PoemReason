:- module(g2p, [g2p/3]).
:- encoding(utf8).
:- discontiguous g2p:g2p/3.
% ============================================================
%  g2p.pl — English G2P (highly simplified)
%
%  Extremely simplified English phoneme mapper.
%  Handles common digraphs and silent-e patterns.
%  Outputs sil/5 with approximate syllable count.
%
%  WARNING: English spelling is notoriously irregular. This
%  module provides rough syllable counts only, not accurate
%  IPA.  Use a pronunciation dictionary for precision.
%
%  Limitations:
%    - No dictionary lookup (words like "colonel", "women"
%      will be wrong)
%    - No stress marking on IPA
%    - Vowel quality is approximate
%    - Does not distinguish /ð/ vs /θ/ for 'th'
% ============================================================

vowel_code(C) :-
    char_code(Ch, C),
    member(Ch, [a,e,i,o,u,y]).

%! g2p(+Word, -Syllables, -IPA) is det.
g2p(Word, Syllables, IPA) :-
    atom_codes(Word, Codes),
    phrase(phonemes(Codes), Tokens),
    syllabify(Tokens, Sibs),
    build_ipa(Sibs, Syllables, IPA), !.

g2p(_, [], '?').

% ---- DCG: char codes -> phoneme tokens -----------------------
phonemes([]) --> [].
% Digraphs (greedy: match 2 chars first)
phonemes([0't,0'h|T]) --> [cons('θ')], !, phonemes(T).
phonemes([0's,0'h|T]) --> [cons('ʃ')], !, phonemes(T).
phonemes([0'c,0'h|T]) --> [cons('tʃ')], !, phonemes(T).
phonemes([0'p,0'h|T]) --> [cons(f)], !, phonemes(T).
phonemes([0's,0'h|T]) --> [cons(ʒ)], !, phonemes(T).  % zh
phonemes([0'n,0'g|T]) --> [cons('ŋ')], !, phonemes(T).
% c+e/i/y -> s
phonemes([0'c,C|T]) --> {vowel_code(C), member(C, [0'e,0'i,0'y])}, [cons(s)], !, phonemes([C|T]).
% c otherwise -> k
phonemes([0'c|T]) --> [cons(k)], !, phonemes(T).
% g+e/i/y -> dʒ
phonemes([0'g,C|T]) --> {vowel_code(C), member(C, [0'e,0'i,0'y])}, [cons('dʒ')], !, phonemes([C|T]).
% g otherwise -> g
phonemes([0'g|T]) --> [cons(g)], !, phonemes(T).
% qu -> kw
phonemes([0'q,0'u|T]) --> [cons(k), gl(w)], !, phonemes(T).
% kn -> n (silent k)
phonemes([0'k,0'n|T]) --> [cons(n)], !, phonemes(T).
% wr -> r (silent w)
phonemes([0'w,0'r|T]) --> [cons(r)], !, phonemes(T).
% wh -> w
phonemes([0'w,0'h|T]) --> [cons(w)], !, phonemes(T).
% x -> ks
phonemes([0'x|T]) --> [cons(k), cons(s)], !, phonemes(T).
% Silent e at end
phonemes([0'e|T]) --> {T == []}, !, phonemes(T).
% y as vowel at end
phonemes([0'y|T]) --> {T == []}, [vo(i, 0)], !, phonemes(T).
% Simple consonants
phonemes([C|T]) --> {simple_cons(C, A)}, [cons(A)], !, phonemes(T).
% Vowels (approximate)
phonemes([0'a|T]) --> [vo('æ', 0)], !, phonemes(T).
phonemes([0'e|T]) --> [vo('ɛ', 0)], !, phonemes(T).
phonemes([0'i|T]) --> [vo('ɪ', 0)], !, phonemes(T).
phonemes([0'o|T]) --> [vo('ɒ', 0)], !, phonemes(T).
phonemes([0'u|T]) --> [vo('ʌ', 0)], !, phonemes(T).
phonemes([0'y|T]) --> [vo(j, 0)], !, phonemes(T).
phonemes([_|T]) --> phonemes(T).

simple_cons(C, A) :- char_code(A, C), member(A, [p,b,t,d,k,g,f,v,s,z,l,m,n,r,w,j]).

% ---- syllabify (max onset) -----------------------------------
syllabify(Toks, Sibs) :-
    segs(Toks, Ss),
    take_cons(Ss, Ons, Rest),
    blocks(Rest, Blks),
    build(Ons, Blks, Sibs).

segs([], []).
segs([vo(Q,Ac)|T], [nuc([Q],Ac)|R]) :- !, segs(T, R).
segs([cons(C)|T], [c(C)|R]) :- !, segs(T, R).
segs([gl(G)|T], [gl(G)|R]) :- !, segs(T, R).
segs([_|T], R) :- segs(T, R).

take_cons([C|T], [X|Xs], R) :- C = c(X), !, take_cons(T, Xs, R).
take_cons(T, [], T).

blocks([], []).
blocks([nuc(Vs,Ac)|T], [blk(Vs,Ac,Cs)|R]) :-
    !, take_cons(T, Cs, T2), blocks(T2, R).

build(Ons, [blk(Vs,Ac,Cs)], [sil(Ons,Vs,Cs,1,Ac)]) :- !.
build(Ons, [blk(Vs,Ac,Cs)|Rest], [sil(Ons,Vs,Cd,1,Ac)|Rs]) :-
    max_onset(Cs, Cd, Next),
    build(Next, Rest, Rs).

max_onset([], [], []).
max_onset([C], [], [C]).
max_onset(Cs, Cd, On) :-
    append(Pref, [A,B], Cs),
    (valid_grp(A, B) -> On = [A,B], Cd = Pref
    ; On = [B], append(Pref, [A], Cd)).

valid_grp(O, r) :- member(O, [p,b,t,d,k,g,f,v]).
valid_grp(O, l) :- member(O, [p,b,t,d,k,g,f,v]).

% ---- IPA / transcription -------------------------------------
build_ipa([], [], '').
build_ipa(Sibs, Sibs, IPA) :-
    maplist(syl_ipa, Sibs, Parts),
    atomic_list_concat(Parts, IPA).

syl_ipa(sil(O,V,C,_,_), Str) :-
    append(O, V, ON), append(ON, C, Fs),
    atomic_list_concat(Fs, Str).
