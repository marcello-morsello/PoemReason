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
%  phonetics.pl — Italian phonetic versification engine
%
%  Motor di scansione e rima per l'italiano.
%
%  Italian poetry counts syllables (endecasillabo = 11).
%  Features: synaloepha (sinalefa), stress-based cut,
%  consonant and assonant rhyme.
%
%  La poesia italiana conta le sillabe (endecasillabo = 11).
%  Caratteristiche: sinalefe, taglio sull'ultimo accento,
%  rima consonante e assonante.
% ============================================================

tradicao_padrao(italiano_silabico).

% ---- tradition table / tabella delle tradizioni --------------
unita(italiano_silabico, sillaba).
permetti_sinalefe(italiano_silabico).
conta_fino_accento(italiano_silabico).

% ---- mora count (not used by Italian, present for compat) ---
somma_more([], 0).
somma_more([sil(_,_,_,P,_)|R], N) :- somma_more(R, N0), N is N0 + P.

% ---- CORE SCANSION ------------------------------------------
escande(Trad, Verso, N) :-
    unita(Trad, sillaba), !,
    ( conta_fino_accento(Trad) -> prefisso_accento(Verso, Alvo) ; Alvo = Verso ),
    length(Alvo, Len),
    ( Len > 20
      -> N = Len
      ; sillabe_con_sinalefe(Trad, Alvo, N) ).

contagens(Trad, Verso, Lista) :-
    findall(N, escande(Trad, Verso, N), Bruta), sort(Bruta, Lista).

% ---- synaloepha search / ricerca sinalefe --------------------
sillabe_con_sinalefe(_, [], 0).
sillabe_con_sinalefe(_, [_], 1).
sillabe_con_sinalefe(Trad, [S1,S2|R], N) :-
    ( elidibile(Trad, S1, S2)
      -> ( sillabe_con_sinalefe(Trad, [S2|R], N)
         ; sillabe_con_sinalefe(Trad, [S2|R], N0), N is N0 + 1 )
      ;  sillabe_con_sinalefe(Trad, [S2|R], N0), N is N0 + 1 ).

elidibile(Trad, sil(_,_,[],_,_), sil([],_,_,_,_)) :- permetti_sinalefe(Trad).

% ---- stress cut / taglio sull'accento ------------------------
prefisso_accento(Verso, Pref) :-
    indice_ultimo_accento(Verso, I),
    length(Pref, I),
    append(Pref, _, Verso).

indice_ultimo_accento(Verso, I) :-
    nth1(I, Verso, sil(_,_,_,_,tonica)),
    \+ ( nth1(J, Verso, sil(_,_,_,_,tonica)), J > I ).

% ---- rhyme / rima -------------------------------------------
cauda_consoante(Verso, Cauda) :-
    indice_ultimo_accento(Verso, I),
    nth1(I, Verso, sil(_, Nuc, Coda, _, _)),
    length(Pref, I), append(Pref, Pos, Verso),
    fonemi(Pos, FPos),
    append(Nuc, Coda, T0), append(T0, FPos, Cauda).

cauda_toante(Verso, Vocali) :-
    indice_ultimo_accento(Verso, I),
    nth1(I, Verso, sil(_, Nuc, _, _, _)),
    length(Pref, I), append(Pref, Pos, Verso),
    nuclei(Pos, NPos), append(Nuc, NPos, Vocali).

rima_consoante(V1, V2) :- cauda_consoante(V1, C), cauda_consoante(V2, C).
rima_toante(V1, V2)    :- cauda_toante(V1, C),    cauda_toante(V2, C).

fonemi([], []).
fonemi([sil(O,Nu,Co,_,_)|R], F) :-
    fonemi(R, F0),
    append(O, Nu, A), append(A, Co, B), append(B, F0, F).

nuclei([], []).
nuclei([sil(_,Nu,_,_,_)|R], V) :- nuclei(R, V0), append(Nu, V0, V).

% ============================================================
%  ITALIAN FORMS (multifile into common modules)
% ============================================================
:- multifile structural_validator:forma/4.
:- multifile diagnostics:forma_estr/4.

% Terza rima (Dante): chain of tercets, ABA BCB CDC ... YZY Z
% N = 3K+1 endecasillabi; unique rhyme pattern verified by restricao_extra
structural_validator:forma(terza_rima, N, M, catena_terzine) :-
    N > 3, (N - 1) mod 3 =:= 0,
    length(M, N), maplist(=(11), M).
diagnostics:forma_estr(terza_rima, [3,3,3,3,3,3,3], _, catena_terzine).

% Ottava rima (Ariosto): stanzas of 8 endecasillabi, ABABABCC
structural_validator:forma(ottava_rima, N, M, [a,b,a,b,a,b,c,c]) :-
    N mod 8 =:= 0,
    length(M, N), maplist(=(11), M).
diagnostics:forma_estr(ottava_rima, [8], _, [a,b,a,b,a,b,c,c]).

% Madrigale: 6-12 lines, mix of endecasillabi and settenari, libre rhyme
structural_validator:forma(madrigale, N, M, livre) :-
    between(6, 12, N),
    length(M, N).
diagnostics:forma_estr(madrigale, [N], _, livre) :-
    between(6, 12, N).
