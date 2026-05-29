:- module(diagnostics, [
    forma_estr/4,
    diagnostica/3,
    relatorio/2,
    estrofe_de/4
]).
:- encoding(utf8).
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
forma_estr(soneto_italiano, [4,4,3,3], todos(10),
           [a,b,b,a, a,b,b,a, c,d,c, d,c,d]).
forma_estr(vilanela, [3,3,3,3,3,4], livre,
           [a,b,a, a,b,a, a,b,a, a,b,a, a,b,a, a,b,a,a]).
forma_estr(trova_dupla, [4,4], todos(7),
           [a,b,a,b, c,d,c,d]).
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
    checa_estrutura(Estrofes, Versos,           P0),
    checa_metrica(Metrica,    Versos, Estrofes, P1),
    checa_rima(Rima,          Versos, Estrofes, P2),
    extra_diag(Nome,          Versos, Estrofes, P3),
    append([P0,P1,P2,P3], Probs).

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
checa_rima(livre, _, _, []) :- !.
checa_rima(Modelo, Versos, Estrofes, Probs) :-
    is_list(Modelo),
    setof(Letra, esta_no_modelo(Letra, Modelo), Letras),
    foldl(checa_grupo_rima(Modelo, Versos, Estrofes), Letras, [], Probs).

esta_no_modelo(L, Modelo) :- member(L, Modelo).

checa_grupo_rima(Modelo, Versos, Estrofes, Letra, Acc0, Acc) :-
    findall(G, (nth1(G, Modelo, L), L == Letra), Pos),
    findall(C, (member(G, Pos), nth1(G, Versos, verso(_,_,C))), Classes),
    ( Classes == [] -> Acc = Acc0
    ; maioria(Classes, Ref),
      findall(prob(E, G, rima, M),
          ( member(G, Pos), nth1(G, Versos, verso(_,_,C)), C \== Ref,
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

% Soneto italiano CORRETO
exemplo_diag(soneto_ok, poema([
    verso("verso 1",  [10], ar),  verso("verso 2",  [10], ento),
    verso("verso 3",  [10], ento), verso("verso 4",  [10], ar),
    verso("verso 5",  [10], ar),  verso("verso 6",  [10], ento),
    verso("verso 7",  [10], ento), verso("verso 8",  [10], ar),
    verso("verso 9",  [10], ia),  verso("verso 10", [10], or),
    verso("verso 11", [10], ia),  verso("verso 12", [10], or),
    verso("verso 13", [10], ia),  verso("verso 14", [10], or)
])).

% Soneto com DOIS erros: rima no v4 e métrica no v7
exemplo_diag(soneto_com_erros, poema([
    verso("verso 1",  [10], ar),  verso("verso 2",  [10], ento),
    verso("verso 3",  [10], ento), verso("verso 4 (rima errada)", [10], os),
    verso("verso 5",  [10], ar),  verso("verso 6",  [10], ento),
    verso("verso 7 (curto)", [7], ento),
    verso("verso 8",  [10], ar),
    verso("verso 9",  [10], ia),  verso("verso 10", [10], or),
    verso("verso 11", [10], ia),  verso("verso 12", [10], or),
    verso("verso 13", [10], ia),  verso("verso 14", [10], or)
])).

% Vilanela com REFRÃO quebrado no v18
exemplo_diag(vilanela_quebrada, poema(V)) :-
    A1  = verso("Nao entres docil nessa noite",  [10], a),
    A1x = verso("Verso trocado no lugar errado",  [10], a),
    A2  = verso("Esbraveja ao morrer da luz",     [10], a),
    M   = verso("verso do meio (rima b)",         [10], b),
    X   = verso("verso comum (rima a)",           [10], a),
    V = [A1, M, A2,
         X,  M, A1,
         X,  M, A2,
         X,  M, A1,
         X,  M, A2,
         X,  M, A1x, A2].
