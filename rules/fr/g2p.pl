:- module(g2p, [g2p/3]).
:- encoding(utf8).
:- discontiguous g2p:phonemes/3.
% ============================================================
%  g2p.pl — French G2P (simplified)
%
%  Conversion graphème-phonème pour le français (simplifiée).
%
%  Handles: e-muet, nasal vowels, basic liaison.
%  Produces sil/5 with weight=1 per syllable.
%
%  Limitations:
%    - No /e/-/ɛ/ distinction without accent
%    - Final consonants: only t,d,s,x,z,p silenced
%    - No full liaison (only basic)
% ============================================================

vowel_code(C) :-
    char_code(Ch, C),
    member(Ch, [a,à,â,e,é,è,ê,ë,i,î,ï,o,ô,u,ù,û,ü,y]).

vowel_out(C, Q) :-
    char_code(Ch, C),
    vow_map(Ch, Q).

vow_map(a, a). vow_map('à', a). vow_map('â', 'ɑ').
vow_map(e, 'ə'). vow_map('é', e). vow_map('è', 'ɛ'). vow_map('ê', 'ɛ'). vow_map('ë', 'ɛ').
vow_map(i, i). vow_map('î', i). vow_map('ï', i).
vow_map(o, o). vow_map('ô', o).
vow_map(u, y). vow_map('ù', y). vow_map('û', y). vow_map('ü', y).
vow_map(y, i).

%! g2p(+Word, -Syllables, -IPA) is det.
g2p(Word, Syllables, IPA) :-
    atom_codes(Word, Codes),
    phrase(phonemes(Codes), Tokens),
    syllabify(Tokens, Sibs),
    assign_ipa(Sibs, Syllables, IPA).

% ---- DCG: char codes -> phoneme tokens -----------------------
phonemes([]) --> [].
phonemes([C1,C2,C3|T]) --> nasal3(C1,C2,C3), !, phonemes(T).
phonemes([C1,C2|T]) --> nasal2(C1,C2), !, phonemes(T).
phonemes([0'c,0'h|T]) --> [cons('ʃ')], !, phonemes(T).
phonemes([0'c,0'ç|T]) --> [cons(s)], !, phonemes(T).
phonemes([0'c,0'e|T]) --> [cons(s)], !, phonemes(T).
phonemes([0'c,0'è|T]) --> [cons(s)], !, phonemes(T).
phonemes([0'c,0'ê|T]) --> [cons(s)], !, phonemes(T).
phonemes([0'c,0'é|T]) --> [cons(s)], !, phonemes(T).
phonemes([0'c,0'i|T]) --> [cons(s)], !, phonemes(T).
phonemes([0'c,0'y|T]) --> [cons(s)], !, phonemes(T).
phonemes([0'c|T]) --> [cons(k)], !, phonemes(T).
phonemes([0'ç|T]) --> [cons(s)], !, phonemes(T).
phonemes([0'g,0'u,C|T]) --> {vowel_code(C)}, [cons(g)], !, phonemes([C|T]).
phonemes([0'g,0'n|T]) --> [cons('ɲ')], !, phonemes(T).
phonemes([0'g,0'e|T]) --> [cons('ʒ')], !, phonemes(T).
phonemes([0'g,0'é|T]) --> [cons('ʒ')], !, phonemes(T).
phonemes([0'g,0'è|T]) --> [cons('ʒ')], !, phonemes(T).
phonemes([0'g,0'ê|T]) --> [cons('ʒ')], !, phonemes(T).
phonemes([0'g,0'i|T]) --> [cons('ʒ')], !, phonemes(T).
phonemes([0'g,0'y|T]) --> [cons('ʒ')], !, phonemes(T).
phonemes([0'g|T]) --> [cons(g)], !, phonemes(T).
phonemes([0'q,0'u|T]) --> [cons(k)], !, phonemes(T).
phonemes([0'p,0'h|T]) --> [cons(f)], !, phonemes(T).
phonemes([0'h|T]) --> phonemes(T).
phonemes([0's|T]) --> [cons(s)], !, phonemes(T).
phonemes([C|T]) --> {silent_final(C), T == []}, !, phonemes(T).

silent_final(C) :- char_code(Ch, C), member(Ch, [t,d,x,z,p]).

phonemes([C|T]) --> {guttural(C, A)}, [cons(A)], !, phonemes(T).

guttural(C, A) :- char_code(A, C), member(A, [k,g,f,ʃ,ʒ,ɲ,ɥ]).
phonemes([C|T]) --> {simple_cons(C, A)}, [cons(A)], !, phonemes(T).

simple_cons(C, A) :- char_code(A, C), member(A, [p,b,t,d,k,g,f,v,s,z,l,m,n,r]).
phonemes([V|T]) --> {vowel_out(V, Q)}, [vo(Q, 0)], !, phonemes(T).
phonemes([_|T]) --> phonemes(T).

nasal3(C1,C2,C3) -->
    { atom_codes(A, [C1,C2,C3]),
      member(A, [ein,aim,ain,oin,ien,yan,eyn,oen]) },
    [vo(N,0)], { nasal(A, N) }.

nasal2(C1,C2) -->
    { atom_codes(A, [C1,C2]),
      member(A, [an,am,en,em,in,im,on,om,un,um,yn,ym]) },
    [vo(N,0)], { nasal(A, N) }.

nasal(an, 'ɑ̃'). nasal(am, 'ɑ̃'). nasal(en, 'ɑ̃'). nasal(em, 'ɑ̃').
nasal(in, 'ɛ̃'). nasal(im, 'ɛ̃'). nasal(ain, 'ɛ̃'). nasal(aim, 'ɛ̃').
nasal(ein, 'ɛ̃'). nasal(yn, 'ɛ̃'). nasal(ym, 'ɛ̃').
nasal(on, 'ɔ̃'). nasal(om, 'ɔ̃').
nasal(un, 'œ̃'). nasal(um, 'œ̃').

% ---- syllabify / syllabification (max onset) -----------------
syllabify(Toks, Sibs) :-
    segs(Toks, Ss),
    take_cons(Ss, Ons, Rest),
    blocks(Rest, Blks),
    build(Ons, Blks, Sibs).

segs([], []).
segs([vo(Q,Ac)|T], [nuc([Q],Ac)|R]) :- !, segs(T, R).
segs([cons(C)|T], [c(C)|R]) :- !, segs(T, R).
segs([_|T], R) :- segs(T, R).

take_cons([C|T], [X|Xs], R) :- C = c(X), !, take_cons(T, Xs, R).
take_cons(T, [], T).

blocks([], []).
blocks([nuc(Vs,Ac)|T], [blk(Vs,Ac,Cs)|R]) :-
    !, take_cons(T, Cs, T2), blocks(T2, R).

build(Ons, [blk(Vs,Ac,Cs)], [sil(Ons,Vs,Cs,1,0)]) :- !.
build(Ons, [blk(Vs,Ac,Cs)|Rest], [sil(Ons,Vs,Cd,1,0)|Rs]) :-
    max_onset(Cs, Cd, NextOns),
    build(NextOns, Rest, Rs).

max_onset([], [], []).
max_onset([C], [], [C]).
max_onset(Cs, Cd, On) :-
    append(Pref, [A,B], Cs),
    ( valid_grp(A, B) -> On = [A,B], Cd = Pref
    ; On = [B], append(Pref, [A], Cd) ).

valid_grp(O, r) :- member(O, [p,b,t,d,k,g,f,v]).
valid_grp(O, l) :- member(O, [p,b,t,d,k,g,f,v]).

% ---- IPA / transcription -------------------------------------
assign_ipa([], [], '').
assign_ipa(Sibs, Sibs, IPA) :-
    maplist(syl_ipa, Sibs, Parts),
    atomic_list_concat(Parts, IPA).

syl_ipa(sil(O,N,C,_,_), Str) :-
    append(O, N, ON), append(ON, C, Fs),
    atomic_list_concat(Fs, Str).
