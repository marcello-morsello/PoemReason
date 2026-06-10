:- encoding(utf8).
:- use_module('../rules/phonetic_validator').
:- use_module(library(plunit)).

% ============================================================
%  phonetic_tests.pl — Unit tests for the phonetic validator
%
%  Testes unitários para o validador fonético.
%  Covers scansion (escansão), mora counting, rhyme, and
%  form validation for both Portuguese and Japanese traditions.
% ============================================================

:- begin_tests(phonetic_validator).

% --- SCANSION / ESCANSÃO --------------------------------------

% p1 (oxítono, 11 sílabas com sinalefa) -> escansões possíveis: [10,11]
test(scansion_p1) :-
    exemplo_pt(p1, P1),
    contagens(portugues_silabico, P1, [10,11]).

% p2 (oxítono, 10 sílabas limpas) -> só [10]
test(scansion_p2) :-
    exemplo_pt(p2, P2),
    contagens(portugues_silabico, P2, [10]).

% p3 (paroxítono, 11 sílabas, corte na tônica) -> [10]
test(scansion_p3) :-
    exemplo_pt(p3, P3),
    contagens(portugues_silabico, P3, [10]).

% Long line shield test (25 syllables): should bypass synaloepha and return [25] instantly.
% Final syllable is tonic so prefixo_tonica/2 succeeds and the full 25-syllable prefix
% reaches the Len > 20 shield in escande/3.
test(scansion_long_line_shield) :-
    findall(sil([k],[a],[],1,atona), between(1, 24, _), Atonas),
    append(Atonas, [sil([k],[a],[],1,tonica)], LongVerse),
    contagens(portugues_silabico, LongVerse, [25]).

% --- MORA vs SYLLABLE / MORA vs SÍLABA -----------------------

test(haiku_mora_line1) :-
    exemplo_haiku([L1,_,_]),
    soma_moras(L1, 5).

test(haiku_mora_line2) :-
    exemplo_haiku([_,L2,_]),
    soma_moras(L2, 7).

test(haiku_mora_line3) :-
    exemplo_haiku([_,_,L3]),
    soma_moras(L3, 5).

% syllable count != mora count for line 1
test(haiku_syl_vs_mora) :-
    exemplo_haiku([L1,_,_]),
    length(L1, SylCount),
    soma_moras(L1, MoraCount),
    SylCount =\= MoraCount.

% --- FORM VALIDATION / VALIDAÇÃO POR FORMA -------------------

test(p1_is_decasyllable, [nondet]) :-
    exemplo_pt(p1, P1),
    valida_fon(decassilabo, [P1]).

test(p3_is_decasyllable_via_cut, [nondet]) :-
    exemplo_pt(p3, P3),
    valida_fon(decassilabo, [P3]).

test(p1_p2_decasyllable_couplet) :-
    exemplo_pt(p1, P1), exemplo_pt(p2, P2),
    valida_fon(parelha_decassilaba, [P1, P2]).

test(haiku_5_7_5_moras, [nondet]) :-
    exemplo_haiku([L1, L2, L3]),
    valida_fon(haiku, [L1, L2, L3]).

% --- NEGATIVE: wrong haiku (line 1 with 4 moras) -------------
test(haiku_wrong_moras, [fail]) :-
    exemplo_haiku([_, L2, L3]),
    L1b = [ sil([t],[o],[],1,_), sil([k,y],[o],[],2,_), sil([n],[o],[],1,_) ],
    valida_fon(haiku, [L1b, L2, L3]).

% --- RHYME / RIMA --------------------------------------------

test(p1_p2_consonant_rhyme) :-
    exemplo_pt(p1, P1), exemplo_pt(p2, P2),
    rima_consoante(P1, P2).

test(p1_rhyme_tail) :-
    exemplo_pt(p1, P1),
    cauda_consoante(P1, [a,r]).

:- end_tests(phonetic_validator).
