:- module(diagnostics, [
    forma_estr/4,
    diagnostica/3,
    relatorio/2,
    estrofe_de/4
]).
:- encoding(utf8).
:- multifile forma_estr/4.
% ============================================================
%  diagnostics.pl — Reporting layer for structural validation
%
%  Camada de RELATÓRIO: valida o formato e, quando NÃO adere,
%  aponta a estrofe, o verso e o ponto exato do problema.
%
%  Principle: checks NEVER fail — they COLLECT violations as
%    prob(Stanza, GlobalVerse, Type, Message)
%  and the resulting list (empty = adherent) is printed by stanza.
%
%  Princípio: as checagens NÃO falham — elas COLETAM violações
%    prob(Estrofe, VersoGlobal, Tipo, Mensagem)
%  e a lista resultante (vazia = aderente) é impressa por estrofe.
% ============================================================

% ---- catalog with stanza structure / catálogo COM estrofes ---
% forma_estr(Name, StanzaSizes, Metrics, Rhyme)
%   Rhyme : livre | [a,b,...] (consoante) | toante([a,b,...])
forma_estr(soneto_italiano, [4,4,3,3], todos(10),
           [a,b,b,a, a,b,b,a, c,d,c, d,c,d]).
forma_estr(vilanela, [3,3,3,3,3,4], livre,
           [a,b,a, a,b,a, a,b,a, a,b,a, a,b,a, a,b,a,a]).
forma_estr(trova_dupla, [4,4], todos(7),
           [a,b,a,b, c,d,c,d]).
% Cordel sextilha: assonant rhyme; letter b appears at positions 2,4,6
% so the outlier detection has an unambiguous majority of 2 to 1.
% Cordel sextilha: rima toante; letra 'b' aparece nas posições 2,4,6
% — maioria de 2 vs 1 dá outlier sem ambiguidade.
forma_estr(cordel_sextilha, [6], todos(7),
           toante([a,b,c,b,d,b])).
forma_estr(cancao, [4,4], livre,
           [a,b,a,b, c,d,c,d]).


% ============================================================
%  DIAGNOSTICS (collects, never fails)
% ============================================================

%! diagnostica(+FormName, +Poem, -Problems) is det.
%  Collects all structural/metric/rhyme problems.
%  Coleta todos os problemas de estrutura/métrica/rima.
diagnostica(Nome, poema(Versos), Probs) :-
    forma_estr(Nome, Estrofes, Metrica, Rima),
    checa_estrutura(Estrofes, Versos, P0),
    ( P0 \== []
      -> Probs = P0  % Short-circuit: skip metrics and rhyme checks if line count is wrong
      ;  checa_metrica(Metrica,    Versos, Estrofes, P1),
         checa_rima(Rima,          Versos, Estrofes, P2),
         extra_diag(Nome,          Versos, Estrofes, P3),
         append([P0,P1,P2,P3], Probs) ).

% ---- structure: total verse count ----------------------------
checa_estrutura(Estrofes, Versos, Probs) :-
    sum_list(Estrofes, Esperado),
    length(Versos, Obtido),
    ( Esperado =:= Obtido
      -> Probs = []
      ;  format(atom(M), "numero de versos: esperado ~w, obtido ~w", [Esperado, Obtido]),
         Probs = [prob(0, 0, estrutura, M)] ).

% ---- metrics: per verse, with address ------------------------
checa_metrica(livre, _, _, []) :- !.
checa_metrica(Metrica, Versos, Estrofes, Probs) :-
    expande_metrica(Metrica, Versos, Alvos),
    findall(prob(E, G, metrica, M),
        ( nth1(G, Versos, verso(_, Sil, _)),
          nth1(G, Alvos, Alvo),
          \+ member(Alvo, Sil),
          estrofe_de(Estrofes, G, E, _),
          format(atom(M), "esperado ~w silaba(s); escansoes possiveis ~w", [Alvo, Sil]) ),
        Probs).

expande_metrica(todos(N), Versos, L) :- !, length(Versos, K), length(L, K), maplist(=(N), L).
expande_metrica(L, _, L).

% ---- rhyme: by group, pointing the outlier -------------------
%  Each verse arrives annotated with rima(ConsTail, AssoTail).
%  The rhyme scheme decides which slot is read:
%    livre        — no comparison
%    toante(L)    — assonant tail (AssoTail)
%    [a,b,...]    — consonant tail (ConsTail)
%
%  Cada verso já chega com rima(CaudaCons, CaudaToa).  O esquema
%  diz qual slot é lido.
checa_rima(livre, _, _, []) :- !.
checa_rima(toante(Modelo), Versos, Estrofes, Probs) :- !,
    is_list(Modelo),
    checa_rima_modo(toante, Modelo, Versos, Estrofes, Probs).
checa_rima(Modelo, Versos, Estrofes, Probs) :-
    is_list(Modelo),
    checa_rima_modo(consoante, Modelo, Versos, Estrofes, Probs).

checa_rima_modo(Modo, Modelo, Versos, Estrofes, Probs) :-
    setof(Letra, esta_no_modelo(Letra, Modelo), Letras),
    foldl(checa_grupo_rima(Modo, Modelo, Versos, Estrofes), Letras, [], Probs).

esta_no_modelo(L, Modelo) :- member(L, Modelo).

cauda_de(consoante, rima(C, _), C).
cauda_de(toante,    rima(_, A), A).

checa_grupo_rima(Modo, Modelo, Versos, Estrofes, Letra, Acc0, Acc) :-
    findall(G, (nth1(G, Modelo, L), L == Letra), Pos),
    findall(C, ( member(G, Pos), nth1(G, Versos, verso(_,_,R)),
                 cauda_de(Modo, R, C) ),
            Classes),
    ( Classes == [] -> Acc = Acc0
    ; maioria(Classes, Ref),
      findall(prob(E, G, rima, M),
          ( member(G, Pos), nth1(G, Versos, verso(_,_,R)),
            cauda_de(Modo, R, C), C \== Ref,
            estrofe_de(Estrofes, G, E, _),
            format(atom(M), "rima '~w' destoa do grupo de rima ~w (os demais rimam em '~w')",
                   [C, Letra, Ref]) ),
          Novos),
      append(Acc0, Novos, Acc) ).

% majority rhyme class in the group (the "reference")
maioria(Lista, X) :-
    setof(E, member(E, Lista), Distintas),
    findall(N-E, (member(E, Distintas), include(==(E), Lista, Es), length(Es, N)), Pares),
    sort(0, @>=, Pares, [_-X | _]).

% ---- form-specific extra (villanelle refrain) ----------------
extra_diag(vilanela, Versos, Estrofes, Probs) :- !,
    checa_refrao(Versos, Estrofes, [1,6,12,18], P1),
    checa_refrao(Versos, Estrofes, [3,9,15,19], P2),
    append(P1, P2, Probs).
extra_diag(_, _, _, []).

checa_refrao(Versos, Estrofes, [Ref | Resto], Probs) :-
    nth1(Ref, Versos, verso(TxtRef, _, _)),
    findall(prob(E, G, refrao, M),
        ( member(G, Resto), nth1(G, Versos, verso(Txt, _, _)), Txt \== TxtRef,
          estrofe_de(Estrofes, G, E, _),
          format(atom(M), "refrao diverge do verso ~w (esperado ~q)", [Ref, TxtRef]) ),
        Probs).


% ============================================================
%  Location: global -> (stanza, local position)
%  Localização: global -> (estrofe, posição local)
% ============================================================
estrofe_de(Estrofes, G, E, L) :- estrofe_de_(Estrofes, G, 1, E, L).
estrofe_de_([S | _], G, E, E, G)        :- G =< S, !.
estrofe_de_([S | Ss], G, E0, E, L)      :- G > S, G1 is G - S, E1 is E0 + 1, estrofe_de_(Ss, G1, E1, E, L).
estrofe_de_([], G, E, E, G).


% ============================================================
%  REPORT (prints by stanza)
%  RELATÓRIO (impressão por estrofe)
% ============================================================

%! relatorio(+FormName, +Poem) is det.
%  Prints a human-readable report of adherence to a poetic form.
%  Imprime um relatório legível da aderência a uma forma poética.
relatorio(Nome, poema(Versos)) :-
    diagnostica(Nome, poema(Versos), Probs),
    forma_estr(Nome, Estrofes, _, _),
    length(Probs, NP),
    nl,
    ( Probs == []
      -> format("[OK] Poema ADERENTE ao formato '~w'.~n", [Nome])
      ;  format("[!!] Poema NAO aderente a '~w'  --  ~w problema(s):~n", [Nome, NP]) ),
    forall(member(prob(0, 0, T, M), Probs),
           format("   * [estrutura/~w] ~w~n", [T, M])),
    fatia(Estrofes, Versos, Chunks, Extra),
    imprime_estrofes(Chunks, 1, 0, Probs),
    ( Extra == [] -> true ; format("~n   (versos excedentes nao previstos: ~w)~n", [Extra]) ).

imprime_estrofes([], _, _, _).
imprime_estrofes([C | Cs], E, Base, Probs) :-
    format("~n   Estrofe ~w:~n", [E]),
    imprime_versos(C, Base, Probs),
    length(C, K), Base1 is Base + K, E1 is E + 1,
    imprime_estrofes(Cs, E1, Base1, Probs).

imprime_versos([], _, _).
imprime_versos([verso(Txt, _, _) | Vs], Base, Probs) :-
    G is Base + 1,
    findall(Tp-M, member(prob(_, G, Tp, M), Probs), Falhas),
    ( Falhas == []
      -> format("     v~w  [ok]  ~q~n", [G, Txt])
      ;  format("     v~w  [X ]  ~q~n", [G, Txt]),
         forall(member(Tp-M, Falhas), format("              -> (~w) ~w~n", [Tp, M])) ),
    imprime_versos(Vs, G, Probs).

% fatia a lista de versos conforme os tamanhos das estrofes
fatia([], Resto, [], Resto).
fatia([S | Ss], Lista, [C | Cs], Extra) :-
    tomar(S, Lista, C, Resto),
    fatia(Ss, Resto, Cs, Extra).

tomar(0, L, [], L) :- !.
tomar(_, [], [], []) :- !.
tomar(N, [X | Xs], [X | C], R) :- N > 0, N1 is N - 1, tomar(N1, Xs, C, R).


% ============================================================
%  EXAMPLES / EXEMPLOS
% ============================================================

:- module_transparent exemplo_diag/2.

% Fixture convention: each verse uses rima(ConsAtom, AssoAtom).
% Sonnets and the broken-villanelle fixtures exercise consonant rhyme,
% so the same stub goes in both slots.  The cordel sextilha fixtures
% deliberately disagree in the cons slot to prove the toante check
% ignores it.
%
% Convenção de fixture: cada verso usa rima(AtomCons, AtomToa).
% Sonetos e a vilanela quebrada testam rima consoante, então repete-se
% o mesmo stub nos dois slots.  As fixtures do cordel sextilha usam
% stubs consoantes divergentes para provar que o modo toante os ignora.

% Soneto italiano CORRETO
exemplo_diag(soneto_ok, poema([
    verso("verso 1",  [10], rima(ar,   ar)),   verso("verso 2",  [10], rima(ento, ento)),
    verso("verso 3",  [10], rima(ento, ento)), verso("verso 4",  [10], rima(ar,   ar)),
    verso("verso 5",  [10], rima(ar,   ar)),   verso("verso 6",  [10], rima(ento, ento)),
    verso("verso 7",  [10], rima(ento, ento)), verso("verso 8",  [10], rima(ar,   ar)),
    verso("verso 9",  [10], rima(ia,   ia)),   verso("verso 10", [10], rima(or,   or)),
    verso("verso 11", [10], rima(ia,   ia)),   verso("verso 12", [10], rima(or,   or)),
    verso("verso 13", [10], rima(ia,   ia)),   verso("verso 14", [10], rima(or,   or))
])).

% Soneto com DOIS erros: rima no v4 e métrica no v7
exemplo_diag(soneto_com_erros, poema([
    verso("verso 1",  [10], rima(ar,   ar)),   verso("verso 2",  [10], rima(ento, ento)),
    verso("verso 3",  [10], rima(ento, ento)),
    verso("verso 4 (rima errada)", [10], rima(os, os)),
    verso("verso 5",  [10], rima(ar,   ar)),   verso("verso 6",  [10], rima(ento, ento)),
    verso("verso 7 (curto)", [7], rima(ento, ento)),
    verso("verso 8",  [10], rima(ar,   ar)),
    verso("verso 9",  [10], rima(ia,   ia)),   verso("verso 10", [10], rima(or,   or)),
    verso("verso 11", [10], rima(ia,   ia)),   verso("verso 12", [10], rima(or,   or)),
    verso("verso 13", [10], rima(ia,   ia)),   verso("verso 14", [10], rima(or,   or))
])).

% Vilanela com REFRÃO quebrado no v18
exemplo_diag(vilanela_quebrada, poema(V)) :-
    A1  = verso("Nao entres docil nessa noite",  [10], rima(a, a)),
    A1x = verso("Verso trocado no lugar errado", [10], rima(a, a)),
    A2  = verso("Esbraveja ao morrer da luz",    [10], rima(a, a)),
    M   = verso("verso do meio (rima b)",        [10], rima(b, b)),
    X   = verso("verso comum (rima a)",          [10], rima(a, a)),
    V = [A1, M, A2,
         X,  M, A1,
         X,  M, A2,
         X,  M, A1,
         X,  M, A2,
         X,  M, A1x, A2].

% Cordel sextilha CORRETO: v2/v4/v6 compartilham a vogal 'a', restantes
% têm vogais distintas entre si.  Caudas consoantes propositalmente
% diferentes — só o modo toante valida.
exemplo_diag(cordel_toante_ok, poema([
    verso("v1", [7], rima(im,   i)),
    verso("v2", [7], rima(ar,   a)),
    verso("v3", [7], rima(or,   o)),
    verso("v4", [7], rima(az,   a)),
    verso("v5", [7], rima(eu,   e)),
    verso("v6", [7], rima(ato,  a))
])).

% Cordel sextilha QUEBRADA: v4 troca a vogal 'a' por 'u'.  As outras
% duas posições da letra 'b' (v2, v6) continuam em 'a', formando
% maioria clara — o outlier no v4 deve ser apontado.
exemplo_diag(cordel_toante_outlier_v4, poema([
    verso("v1", [7], rima(im,   i)),
    verso("v2", [7], rima(ar,   a)),
    verso("v3", [7], rima(or,   o)),
    verso("v4", [7], rima(uz,   u)),
    verso("v5", [7], rima(eu,   e)),
    verso("v6", [7], rima(ato,  a))
])).
