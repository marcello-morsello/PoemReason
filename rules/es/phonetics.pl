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
%  phonetics.pl — Spanish phonetic versification engine
%
%  Motor de escansión y rima para el español.
%
%  Spanish: syllabic scansion with synaloepha, stress cut.
%  Tradición: espanhol_silabico.
% ============================================================

tradicao_padrao(espanhol_silabico).
unidad(espanhol_silabico, silaba).
permite_sinalefa(espanhol_silabico).
cuenta_hasta_tonica(espanhol_silabico).

escande(Trad, Verso, N) :-
    unidad(Trad, silaba), !,
    ( cuenta_hasta_tonica(Trad) -> prefijo_tonico(Verso, Alvo) ; Alvo = Verso ),
    length(Alvo, Len),
    ( Len > 20 -> N = Len
    ; silabas_con_sinalefa(Trad, Alvo, N) ).

contagens(Trad, Verso, Lista) :-
    findall(N, escande(Trad, Verso, N), Bruta), sort(Bruta, Lista).

silabas_con_sinalefa(_, [], 0).
silabas_con_sinalefa(_, [_], 1).
silabas_con_sinalefa(Trad, [S1,S2|R], N) :-
    ( elidible(Trad, S1, S2)
      -> ( silabas_con_sinalefa(Trad, [S2|R], N)
         ; silabas_con_sinalefa(Trad, [S2|R], N0), N is N0 + 1 )
      ;  silabas_con_sinalefa(Trad, [S2|R], N0), N is N0 + 1 ).

elidible(Trad, sil(_,_,[],_,_), sil([],_,_,_,_)) :- permite_sinalefa(Trad).

prefijo_tonico(Verso, Pref) :-
    ( indice_ultimo_tonico(Verso, I) -> true ; length(Verso, I) ),
    length(Pref, I), append(Pref, _, Verso).

indice_ultimo_tonico(Verso, I) :-
    nth1(I, Verso, sil(_,_,_,_,tonica)),
    \+ ( nth1(J, Verso, sil(_,_,_,_,tonica)), J > I ).

cauda_consoante(Verso, Cauda) :-
    ( indice_ultimo_tonico(Verso, I) -> true ; length(Verso, I) ),
    nth1(I, Verso, sil(_, Nuc, Coda, _, _)),
    length(Pref, I), append(Pref, Pos, Verso),
    fonemas(Pos, FPos),
    append(Nuc, Coda, T0), append(T0, FPos, Cauda).

cauda_toante(Verso, Vocales) :-
    ( indice_ultimo_tonico(Verso, I) -> true ; length(Verso, I) ),
    nth1(I, Verso, sil(_, Nuc, _, _, _)),
    length(Pref, I), append(Pref, Pos, Verso),
    nucleos(Pos, NPos), append(Nuc, NPos, Vocales).

rima_consoante(V1, V2) :- cauda_consoante(V1, C), cauda_consoante(V2, C).
rima_toante(V1, V2)    :- cauda_toante(V1, C),    cauda_toante(V2, C).

fonemas([], []).
fonemas([sil(O,Nu,Co,_,_)|R], F) :-
    fonemas(R, F0),
    append(O, Nu, A), append(A, Co, B), append(B, F0, F).

nucleos([], []).
nucleos([sil(_,Nu,_,_,_)|R], V) :- nucleos(R, V0), append(Nu, V0, V).

% ============================================================
%  SPANISH FORMS (multifile into common modules)
% ============================================================
:- multifile structural_validator:forma/4.
:- multifile diagnostics:forma_estr/4.

% Seguidilla: 7-5a-7-5a (assonant in pairs)
structural_validator:forma(seguidilla, 4, [7,5,7,5],
    toante([-,a,-,a])).
diagnostics:forma_estr(seguidilla, [4], [7,5,7,5],
    toante([-,a,-,a])).

% Redondilla: 4 octosílabos, abba
structural_validator:forma(redondilla, 4, [8,8,8,8],
    [a,b,b,a]).
diagnostics:forma_estr(redondilla, [4], [8,8,8,8],
    [a,b,b,a]).

% Cuarteta: 4 octosílabos, abab
structural_validator:forma(cuarteta, 4, [8,8,8,8],
    [a,b,a,b]).

% Copla: 4 octosílabos, asonante en pares (-a-a)
structural_validator:forma(copla, 4, [8,8,8,8],
    toante([-,a,-,a])).

% Lira: 7a-11B-7a-7b-11B (Garcilaso)
structural_validator:forma(lira, 5, [7,11,7,7,11],
    [a,b,a,b,b]).
diagnostics:forma_estr(lira, [5], [7,11,7,7,11],
    [a,b,a,b,b]).

% Décima espinela: 10 octosílabos, abbaaccddc
structural_validator:forma(decima_espinela, 10, M,
    [a,b,b,a,a,c,c,d,d,c]) :- repete(8, 10, M).
diagnostics:forma_estr(decima_espinela, [10], repete(8, 10, _),
    [a,b,b,a,a,c,c,d,d,c]).

% Octava real: 8 endecasílabos, ABABABCC
structural_validator:forma(octava_real, 8, M,
    [a,b,a,b,a,b,c,c]) :- repete(11, 8, M).

% Cuaderna vía: 4 alejandrinos (14 sílabas), AAAA
structural_validator:forma(cuaderna_via, 4, [14,14,14,14],
    [a,a,a,a]).

% Silva: libre combinación de 7 y 11 sílabas, rima libre
structural_validator:forma(silva, N, M, livre) :-
    N >= 4.

repete(_, 0, []).
repete(X, N, [X|T]) :- N > 0, N1 is N - 1, repete(X, N1, T).
