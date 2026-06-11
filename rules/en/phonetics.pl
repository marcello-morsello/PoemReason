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
%  phonetics.pl — English phonetic versification engine
%
%  English poetry accentual-syllabic (iambic pentameter).
%  For simplified scansion: count syllables, cut at stress.
%  Tradition: ingles_silabico
% ============================================================

tradicao_padrao(ingles_silabico).
unidade(ingles_silabico, silaba).
permite_sinalefa(ingles_silabico).
conta_ate_tonica(ingles_silabico).

% ---- syllable count with stress cut & synaloepha -------------
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
    indice_ultimo_accento(Verso, I),
    length(Pref, I),
    append(Pref, _, Verso).

indice_ultimo_accento(Verso, I) :-
    ( nth1(I, Verso, sil(_,_,_,_,tonica)),
      \+ ( nth1(J, Verso, sil(_,_,_,_,tonica)), J > I )
    ; length(Verso, I) ).  % fallback: last syllable if no explicit stress

cauda_consoante(Verso, Cauda) :-
    indice_ultimo_accento(Verso, I),
    nth1(I, Verso, sil(_, Nuc, Coda, _, _)),
    length(Pref, I), append(Pref, Pos, Verso),
    fonemas(Pos, FPos),
    append(Nuc, Coda, T0), append(T0, FPos, Cauda).

cauda_toante(Verso, Vocali) :-
    indice_ultimo_accento(Verso, I),
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
%  ENGLISH FORMS (multifile into common modules)
% ============================================================
:- multifile structural_validator:forma/4.
:- multifile diagnostics:forma_estr/4.

% Blank verse: unrhymed iambic pentameter (10 syllables)
structural_validator:forma(blank_verse, N, M, branco) :-
    repete(10, N, M).

% Heroic couplet: 10 syllables, AA BB CC...
structural_validator:forma(heroic_couplet, N, M, [a,a]) :-
    N mod 2 =:= 0, repete(10, N, M).

% Common metre (ballad): alternating tetrameter/trimeter
% 4 lines per stanza: 8-6-8-6, ABCB
% Only 4-line form (single stanza) for simplicity
structural_validator:forma(common_metre, 4, [8,6,8,6],
    [a,b,c,b]).

% Rhyme royal: 7 lines, 10 syllables, ABABBCC
structural_validator:forma(rhyme_royal, 7, M,
    [a,b,a,b,b,c,c]) :-
    repete(10, 7, M).

% Spenserian stanza: 9 lines, 8×10 + 1×12, ABABBCBCC
structural_validator:forma(spenserian_stanza, 9, M,
    [a,b,a,b,b,c,b,c,c]) :-
    M = [10,10,10,10,10,10,10,10,12].
diagnostics:forma_estr(spenserian_stanza, [9], _,
    [a,b,a,b,b,c,b,c,c]).

repete(_, 0, []).
repete(X, N, [X|T]) :- N > 0, N1 is N - 1, repete(X, N1, T).
