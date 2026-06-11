:- module(g2p, [g2p/3]).
:- encoding(utf8).
:- discontiguous g2p:g2p/3.
% ============================================================
%  g2p.pl — German G2P (grapheme-to-phoneme, simplified)
%
%  Phonem-Graphem-Umsetzung für das Deutsche (vereinfacht).
%
%  German spelling is largely regular.  Handles umlauts, ß,
%  ch/sch/ie/ei/au/eu, final devoicing, and basic stress
%  (default: first syllable).
%
%  Limitations / Einschränkungen:
%    - No /x/ vs /ç/ distinction for 'ch'
%    - Vowel length not marked (long vs short)
%    - Diphthongs approximated
%    - No compound word stress rules
% ============================================================

vowel_code(C) :-
    char_code(Ch, C),
    member(Ch, [a,e,i,o,u,ä,ö,ü,y]).

vowel_out(C, Q) :-
    char_code(Ch, C),
    member(Ch-Q, [a-'a', e-'ɛ', i-'ɪ', o-'ɔ', u-'ʊ',
                  ä-'ɛ', ö-'œ', ü-'ʏ', y-'ʏ']).

%! g2p(+Word, -Syllables, -IPA) is det.
g2p(Word, Syllables, IPA) :-
    downcase_atom(Word, Low),
    atom_codes(Low, Codes),
    phrase(phonemes(Codes), Tokens),
    syllabify(Tokens, Sibs),
    add_stress(Sibs, Syllables),
    build_ipa(Syllables, IPA), !.

g2p(_, [], '?').

% ---- DCG: char codes -> phoneme tokens -----------------------
phonemes([]) --> [].
% Digraphs (greedy: 3 then 2 chars)
phonemes([0's,0'c,0'h|T]) --> [cons('ʃ')], !, phonemes(T).  % sch
phonemes([0'e,0'u|T]) --> [vo('ɔʏ', 0)], !, phonemes(T).
phonemes([0'ä,0'u|T]) --> [vo('ɔʏ', 0)], !, phonemes(T).
phonemes([0'e,0'i|T]) --> [vo('aɪ', 0)], !, phonemes(T).
phonemes([0'a,0'i|T]) --> [vo('aɪ', 0)], !, phonemes(T).
phonemes([0'a,0'u|T]) --> [vo('aʊ', 0)], !, phonemes(T).
phonemes([0'i,0'e|T]) --> [vo(i, 0)], !, phonemes(T).  % ie = long i
phonemes([0'c,0'h|T]) --> [cons('ç')], !, phonemes(T).  % default ch -> ç
phonemes([0'p,0'f|T]) --> [cons(pf)], !, phonemes(T).
phonemes([0'z,0'w|T]) --> [cons('tsv')], !, phonemes(T).  % zw
phonemes([0's,0'p|T]) --> [cons('ʃp')], !, phonemes(T).  % sp
phonemes([0's,0't|T]) --> [cons('ʃt')], !, phonemes(T).  % st
phonemes([0't,0's|T]) --> [cons('ts')], !, phonemes(T).  % ts
phonemes([0's,0'c,0'h|T]) --> [cons('ʃ')], !, phonemes(T).  % sch (redundant but safe)
% ß -> s
phonemes([0'ß|T]) --> [cons(s)], !, phonemes(T).
% qu -> kv
phonemes([0'q,0'u|T]) --> [cons(k), gl(v)], !, phonemes(T).
% Silent h after vowel (dehnungs-h)
phonemes([C,0'h|T]) --> {vowel_code(C)}, !, phonemes(T).
% Final devoicing: b,d,g at end -> p,t,k
phonemes([0'b|T]) --> {T == []}, [cons(p)], !, phonemes(T).
phonemes([0'd|T]) --> {T == []}, [cons(t)], !, phonemes(T).
phonemes([0'g|T]) --> {T == []}, [cons(k)], !, phonemes(T).
% Simple consonants
phonemes([C|T]) --> {simple_cons(C, A)}, [cons(A)], !, phonemes(T).
% Vowels
phonemes([V|T]) --> {vowel_out(V, Q)}, [vo(Q, 0)], !, phonemes(T).
phonemes([_|T]) --> phonemes(T).

simple_cons(C, A) :- char_code(A, C), member(A, [p,b,t,d,k,g,f,v,s,z,m,n,r,l,h,j]).

% ---- syllabify -----------------------------------------------
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
    ( valid_grp(A, B) -> On = [A,B], Cd = Pref
    ; On = [B], append(Pref, [A], Cd) ).

valid_grp(O, r) :- member(O, [p,b,t,d,k,g,f,v]).
valid_grp(O, l) :- member(O, [p,b,t,d,k,g,f,v,ʃ,ʃp,ʃt]).

% ---- stress (default: first syllable for German) -------------
add_stress([], []).
add_stress([sil(O,V,C,_,_)|T], [sil(O,V,C,1,tonica)|R]) :-
    add_stress_atone(T, R).

add_stress_atone([], []).
add_stress_atone([sil(O,V,C,_,_)|T], [sil(O,V,C,1,atona)|R]) :-
    add_stress_atone(T, R).

% ---- IPA / transcription -------------------------------------
build_ipa([], '').
build_ipa(Sibs, IPA) :-
    maplist(syl_ipa, Sibs, Parts),
    atomic_list_concat(Parts, IPA).

syl_ipa(sil(O,V,C,_,_), Str) :-
    append(O, V, ON), append(ON, C, Fs),
    atomic_list_concat(Fs, Str).
