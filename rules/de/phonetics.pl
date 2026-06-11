:- module(phonetics, [
    escande/3,
    contagens/3,
    cauda_consoante/2,
    cauda_toante/2,
    rima_consoante/2,
    rima_toante/2,
    tradicao_padrao/1
]).
:- encoding(utf8).
% ============================================================
%  phonetics.pl — German phonetic versification engine
%
%  German poetry accentual-syllabic (Knittelvers, Blankvers).
%  Simplified: syllable count with stress cut, tradition:
%  deutsch_silabico.
% ============================================================

tradicao_padrao(deutsch_silabico).
unidade(deutsch_silabico, silaba).
% German is accentual-syllabic: no stress cut, all syllables count.
% No synaloepha — vowels in hiatus remain separate.
% These predicates exist with empty facts so core:escande/3
% doesn't error — the call just fails and the fallback applies.
conta_ate_tonica(_) :- fail.
permite_sinalefa(_) :- fail.

escande(Trad, Verso, N) :-
    unidade(Trad, silaba), !,
    ( conta_ate_tonica(Trad) -> prefisso_accento(Verso, Alvo) ; Alvo = Verso ),
    length(Alvo, Len),
    ( Len > 20 -> N = Len
    ; silabas_com_sinalefa(Trad, Alvo, N) ).

contagens(Trad, Verso, Lista) :-
    findall(N, escande(Trad, Verso, N), Bruta), sort(Bruta, Lista).

silabas_com_sinalefa(_, [], 0).
silabas_com_sinalefa(_, [_], 1).
silabas_com_sinalefa(Trad, [S1,S2|R], N) :-
    ( elidivel(Trad, S1, S2)
      -> ( silabas_com_sinalefa(Trad, [S2|R], N)
         ; silabas_com_sinalefa(Trad, [S2|R], N0), N is N0 + 1 )
      ;  silabas_com_sinalefa(Trad, [S2|R], N0), N is N0 + 1 ).

elidivel(Trad, sil(_,_,[],_,_), sil([],_,_,_,_)) :- permite_sinalefa(Trad).

prefisso_accento(Verso, Pref) :-
    ( indice_ultimo_accento(Verso, I) -> true ; length(Verso, I) ),
    length(Pref, I),
    append(Pref, _, Verso).

indice_ultimo_accento(Verso, I) :-
    nth1(I, Verso, sil(_,_,_,_,tonica)),
    \+ ( nth1(J, Verso, sil(_,_,_,_,tonica)), J > I ).

cauda_consoante(Verso, Cauda) :-
    ( indice_ultimo_accento(Verso, I) -> true ; length(Verso, I) ),
    nth1(I, Verso, sil(_, Nuc, Coda, _, _)),
    length(Pref, I), append(Pref, Pos, Verso),
    fonemas(Pos, FPos),
    append(Nuc, Coda, T0), append(T0, FPos, Cauda).

cauda_toante(Verso, Vocali) :-
    ( indice_ultimo_accento(Verso, I) -> true ; length(Verso, I) ),
    nth1(I, Verso, sil(_, Nuc, _, _, _)),
    length(Pref, I), append(Pref, Pos, Verso),
    nuclei(Pos, NPos), append(Nuc, NPos, Vocali).

rima_consoante(V1, V2) :- cauda_consoante(V1, C), cauda_consoante(V2, C).
rima_toante(V1, V2)    :- cauda_toante(V1, C),    cauda_toante(V2, C).

fonemas([], []).
fonemas([sil(O,Nu,Co,_,_)|R], F) :-
    fonemas(R, F0),
    append(O, Nu, A), append(A, Co, B), append(B, F0, F).

nuclei([], []).
nuclei([sil(_,Nu,_,_,_)|R], V) :- nuclei(R, V0), append(Nu, V0, V).

% ============================================================
%  GERMAN FORMS (multifile into common modules)
% ============================================================
:- multifile structural_validator:forma/4.
:- multifile diagnostics:forma_estr/4.

% Knittelvers (Goethe's Faust): rhyming couplets, 4 stresses
% ~8-9 syllables per line, AABB.  Represented as free meter.
structural_validator:forma(knittelvers, N, livre,
    [a,a,b,b]) :-
    N mod 4 =:= 0, N >= 4.

% Blankvers: unrhymed iambic pentameter (10-11 syllables)
structural_validator:forma(blankvers, N, M, branco) :-
    repete(10, N, M).

% Volksliedstrophe: quatrain, alternating 4/3 stresses
structural_validator:forma(volksliedstrophe, 4,
    [8,6,8,6], [a,b,a,b]).

% Alexandriner: 12-13 syllables, AABB couplets
structural_validator:forma(alexandriner, N, M,
    [a,a,b,b]) :-
    N mod 4 =:= 0, repete(12, N, M).

% Distichon: couplet of hexameter + pentameter
structural_validator:forma(distichon, 2, [16,14], branco).
diagnostics:forma_estr(distichon, [2], [16,14], branco).
