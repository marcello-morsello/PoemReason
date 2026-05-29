:- module(structural_validator, [
    forma/4,
    valida/2,
    identifica/2,
    diagnostico/2,
    exemplo/2
]).
:- encoding(utf8).
% ============================================================
%  structural_validator.pl — Structural poetry form validator
%
%  Validador ESTRUTURAL de formas poéticas.
%
%  Architecture premise: Prolog does NOT perform scansion or
%  phonetic rhyme analysis here.  Each verse arrives pre-annotated:
%    - admissible syllable counts (from escande/3)
%    - rhyme class atom (from cauda_consoante/2)
%
%  Premissa de arquitetura: o Prolog NÃO faz escansão nem análise
%  fonética da rima aqui.  Cada verso já chega anotado com as
%  contagens silábicas admissíveis e a classe de rima.
% ============================================================

% ---- Poem representation / Representação de um poema ---------
%   poema(ListOfVerses)
%   verso(Text, PossibleSyllables, RhymeClass)

% ============================================================
%  FORM CATALOG / CATÁLOGO DE FORMAS
%  forma(Name, NumVerses, Metrics, RhymeScheme)
% ============================================================

forma(haiku,           3,  [5,7,5],            livre).
forma(tanka,           5,  [5,7,5,7,7],        livre).
forma(trova,           4,  [7,7,7,7],          [a,b,a,b]).
forma(quadra,          4,  [7,7,7,7],          [a,b,c,b]).
forma(limerick,        5,  livre,              [a,a,b,b,a]).
forma(cordel_sextilha, 6,  [7,7,7,7,7,7],      [a,b,c,b,d,b]).
forma(decima,          10, M,                  [a,b,b,a,a,c,c,d,d,c]) :- repete(7,10,M).
forma(soneto_italiano, 14, M, [a,b,b,a, a,b,b,a, c,d,c, d,c,d])       :- repete(10,14,M).
forma(soneto_ingles,   14, M, [a,b,a,b, c,d,c,d, e,f,e,f, g,g])       :- repete(10,14,M).
forma(vilanela,        19, livre,
      [a,b,a, a,b,a, a,b,a, a,b,a, a,b,a, a,b,a,a]).
forma(sextina,         39, livre,              livre).
forma(verso_branco,    _,  _,                  branco).

% ============================================================
%  VALIDATION / VALIDAÇÃO
% ============================================================

%! valida(+FormName, +Poem) is semidet.
%  Succeeds if Poem adheres to the named form.
%  Sucede se o Poema adere à forma nomeada.
valida(Nome, poema(Versos)) :-
    forma(Nome, NVersos, Metrica, Rima),
    ( integer(NVersos) -> length(Versos, NVersos) ; true ),
    checa_metrica(Metrica, Versos),
    checa_rima(Rima, Versos),
    restricao_extra(Nome, Versos).

%! identifica(+Poem, -FormName) is nondet.
%  Enumerates all forms that Poem satisfies.
%  Enumera todas as formas que o Poema satisfaz.
identifica(Poema, Nome) :- valida(Nome, Poema).

% ---- metrics / métrica ----------------------------------------
checa_metrica(livre, _).
checa_metrica([S|Ss], [verso(_, Sil, _)|Vs]) :-
    member(S, Sil),
    checa_metrica(Ss, Vs).
checa_metrica([], []).

% ---- rhyme / rima ---------------------------------------------
checa_rima(livre, _).
checa_rima(branco, Versos) :-
    sons(Versos, Sons),
    todos_distintos(Sons).
checa_rima(Modelo, Versos) :-
    is_list(Modelo),
    sons(Versos, Sons),
    mesma_particao(Modelo, Sons).

sons(Versos, Sons) :- findall(R, member(verso(_,_,R), Versos), Sons).

mesma_particao(Modelo, Sons) :-
    length(Modelo, N), length(Sons, N),
    forall( ( nth1(I, Modelo, Mi), nth1(J, Modelo, Mj), I < J ),
            ( nth1(I, Sons, Si), nth1(J, Sons, Sj),
              ( Mi == Mj -> Si == Sj ; Si \== Sj ) ) ).

todos_distintos(L) :- sort(L, S), length(L, N), length(S, N).

% ---- utility / utilitário ------------------------------------
repete(_, 0, []) :- !.
repete(X, N, [X|T]) :- N > 0, N1 is N - 1, repete(X, N1, T).

% ============================================================
%  FORM-SPECIFIC CONSTRAINTS / RESTRIÇÕES ESPECÍFICAS
% ============================================================

restricao_extra(vilanela, V) :- !, checa_refrao_vilanela(V).
restricao_extra(sextina,  V) :- !, checa_sextina(V).
restricao_extra(_, _).

% ---- VILLANELLE: refrains / VILANELA: refrões ----------------
checa_refrao_vilanela(V) :-
    textos_iguais(V, [1, 6, 12, 18]),
    textos_iguais(V, [3, 9, 15, 19]).

textos_iguais(_, [_]).
textos_iguais(V, [I, J | Resto]) :-
    nth1(I, V, verso(Ti, _, _)),
    nth1(J, V, verso(Tj, _, _)),
    Ti == Tj,
    textos_iguais(V, [J | Resto]).

% ---- SESTINA: end-word permutation / SEXTINA: permutação -----
% retrogradatio cruciata: [A,B,C,D,E,F] -> [F,A,E,B,D,C]
permuta_sextina([A,B,C,D,E,F], [F,A,E,B,D,C]).

checa_sextina(V) :-
    sons(V, Palavras),
    estrofes6(Palavras, [E1,E2,E3,E4,E5,E6, Envoi]),
    length(Envoi, 3),
    permuta_sextina(E1, E2),
    permuta_sextina(E2, E3),
    permuta_sextina(E3, E4),
    permuta_sextina(E4, E5),
    permuta_sextina(E5, E6),
    sort(E1, Conjunto), length(Conjunto, 6),
    forall(member(W, Envoi), member(W, E1)).

estrofes6(Palavras, [E1,E2,E3,E4,E5,E6, Envoi]) :-
    length(E1, 6), length(E2, 6), length(E3, 6),
    length(E4, 6), length(E5, 6), length(E6, 6),
    append([E1,E2,E3,E4,E5,E6, Envoi], Palavras).

% ============================================================
%  DIAGNOSTICS / DIAGNÓSTICO (shows WHICH constraint failed)
% ============================================================

%! diagnostico(+FormName, +Poem) is det.
%  Prints which constraints pass/fail for the given form.
%  Imprime quais restrições passam/falham para a forma dada.
diagnostico(Nome, poema(V)) :-
    forma(Nome, N, Met, Rim),
    length(V, Atual),
    ( ( N == Atual ; \+ integer(N) )
      -> format("[ok] n. de versos: ~w~n", [Atual])
      ;  format("[X ] n. de versos: esperado ~w, obtido ~w~n", [N, Atual]) ),
    ( checa_metrica(Met, V) -> writeln("[ok] metrica") ; writeln("[X ] metrica") ),
    ( checa_rima(Rim, V)    -> writeln("[ok] rima")    ; writeln("[X ] rima") ),
    ( restricao_extra(Nome, V)
      -> writeln("[ok] restricao especifica (refrao/permutacao)")
      ;  writeln("[X ] restricao especifica (refrao/permutacao)") ).

% ============================================================
%  EXAMPLES / EXEMPLOS
% ============================================================

% Haiku (rima livre -> classes irrelevantes, átomos distintos)
exemplo(meu_haiku, poema([
    verso("Velha lagoa quieta",   [5], s1),
    verso("o sapo salta para a agua", [7], s2),
    verso("o som da agua ao redor", [5], s3)
])).

% Trova ABAB
exemplo(minha_trova, poema([
    verso("Eu sinto um grande amor", [7], or),
    verso("que sopra como o vento",  [7], ento),
    verso("e cura toda a dor",       [7], or),
    verso("num passo doce e lento",  [7], ento)
])).

% Trova com erro de rima (v4 não rima com v2)
exemplo(trova_errada, poema([
    verso("Eu sinto um grande amor", [7], or),
    verso("que sopra como o vento",  [7], ento),
    verso("e cura toda a dor",       [7], or),
    verso("num passo bem feliz",     [7], iz)
])).

% --- VILLANELLE / VILANELA ------------------------------------
exemplo(minha_vilanela, poema(V)) :-
    A1 = verso("Nao entres docil nessa noite calma", [10], sa),
    A2 = verso("Esbraveja ao morrer da clara luz",   [10], sa),
    M  = verso("(verso do meio, rima b)",            [10], sb),
    A  = verso("(verso de rima a)",                  [10], sa),
    V  = [A1, M, A2,
          A,  M, A1,
          A,  M, A2,
          A,  M, A1,
          A,  M, A2,
          A,  M, A1, A2].

% Villanelle with broken refrain at v19
exemplo(vilanela_quebrada, poema(V)) :-
    exemplo(minha_vilanela, poema(Vok)),
    append(Inicio, [_Ultimo], Vok),
    append(Inicio, [verso("verso intruso", [10], sa)], V).

% --- SESTINA / SEXTINA ----------------------------------------
exemplo(minha_sextina, poema(V)) :-
    Estrofes = [[luz,  mar,   vento, noite, pedra, tempo],
                [tempo,luz,   pedra, mar,   noite, vento],
                [vento,tempo, noite, luz,   mar,   pedra],
                [pedra,vento, mar,   tempo, luz,   noite],
                [noite,pedra, luz,   vento, tempo, mar],
                [mar,  noite, tempo, pedra, vento, luz]],
    Envoi = [tempo, luz, mar],
    append(Estrofes, Corpo),
    append(Corpo, Envoi, Palavras),
    findall(verso("(verso da sextina)", [10], W), member(W, Palavras), V).

% Sestina with two swapped words in stanza 2
exemplo(sextina_quebrada, poema(V)) :-
    exemplo(minha_sextina, poema(Vok)),
    nth1(7, Vok, V7), nth1(8, Vok, V8),
    trocar(7, V8, Vok, T1),
    trocar(8, V7, T1, V).

trocar(I, Novo, Lista, Nova) :-
    nth1(I, Lista, _, Resto),
    nth1(I, Nova, Novo, Resto).
