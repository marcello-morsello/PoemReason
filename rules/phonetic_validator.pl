:- module(phonetic_validator, [
    escande/3,
    soma_moras/2,
    contagens/3,
    cauda_consoante/2,
    cauda_toante/2,
    rima_consoante/2,
    rima_toante/2,
    forma_fon/4,
    valida_fon/2,
    exemplo_pt/2,
    exemplo_haiku/1
]).
:- encoding(utf8).
% ============================================================
%  phonetic_validator.pl — Multilingual phonetic versification engine
%
%  Núcleo multilíngue de escansão e rima fonética.
%
%  Uses the enriched sil/5 representation from the G2P layer.
%  Each tradition picks the phonetic trait it needs:
%    - Weight (duration) → used by haiku (mora count), ignored by
%      decasyllable (syllable count).
%    - Accent (stress)   → used by decasyllable (cut at last stressed),
%      ignored by haiku.
%
%  Usa a representação enriquecida sil/5 da camada G2P.
%  Cada tradição usa exatamente o traço que a outra descarta:
%  peso (duração) para haiku; acento (tonicidade) para decassílabo.
% ============================================================

%! escande(+Tradition, +Verse, -N) is nondet.
%  N is a valid metric count for Verse under Tradition.
%  For syllabic traditions, backtracks over possible synaloepha
%  (sinalefa) combinations.
%
%  N é uma contagem métrica válida para Verso na Tradição dada.
%  Para tradições silábicas, faz backtracking sobre as sinalefas
%  possíveis (gera todas as escansões legais).

% ---- tradition table / tabela de tradições -------------------

% Que unidade cada tradição conta:
unidade(portugues_silabico, silaba).
unidade(haiku_japones,      mora).

% Quem aplica a licença de sinalefa (elisão vogal+vogal):
permite_sinalefa(portugues_silabico).

% Quem conta só até a última tônica (resto pós-tônico não conta):
conta_ate_tonica(portugues_silabico).


% ============================================================
%  CORE SCANSION ENGINE / MOTOR DE ESCANSÃO
% ============================================================

escande(Trad, Verso, N) :-
    unidade(Trad, silaba), !,
    ( conta_ate_tonica(Trad) -> prefixo_tonica(Verso, Alvo) ; Alvo = Verso ),
    length(Alvo, Len),
    ( Len > 20
      -> N = Len  % Shield: bypass synaloepha search for extremely long/prose lines
      ;  silabas_com_sinalefa(Trad, Alvo, N) ).
escande(Trad, Verso, N) :-
    unidade(Trad, mora), !,
    soma_moras(Verso, N).

% ---- mora count: sum weights (uses DURATION) -----------------
soma_moras([], 0).
soma_moras([sil(_,_,_,P,_)|R], N) :- soma_moras(R, N0), N is N0 + P.

% ---- syllable count with synaloepha search -------------------
silabas_com_sinalefa(_, [], 0).
silabas_com_sinalefa(_, [_], 1).
silabas_com_sinalefa(Trad, [S1,S2|R], N) :-
    ( elidivel(Trad, S1, S2)
      -> ( silabas_com_sinalefa(Trad, [S2|R], N)               % COM elisão: S1 funde
         ; silabas_com_sinalefa(Trad, [S2|R], N0), N is N0 + 1 ) % SEM elisão
      ;  silabas_com_sinalefa(Trad, [S2|R], N0), N is N0 + 1 ).

% sinalefa: sílaba 1 termina em vogal (coda vazia) e
%           sílaba 2 começa em vogal (onset vazio)
elidivel(Trad, sil(_,_,[],_,_), sil([],_,_,_,_)) :- permite_sinalefa(Trad).

% ---- corte na última tônica (usa ACENTO) ---------------------
prefixo_tonica(Verso, Pref) :-
    indice_ultima_tonica(Verso, I),
    length(Pref, I),
    append(Pref, _, Verso).

indice_ultima_tonica(Verso, I) :-
    nth1(I, Verso, sil(_,_,_,_,tonica)),
    \+ ( nth1(J, Verso, sil(_,_,_,_,tonica)), J > I ).


% ============================================================
%  RHYME / RIMA
%  Anchors at the nucleus of the last stressed syllable.
%  Ancora no núcleo da última tônica e vai até o fim.
% ============================================================

%! cauda_consoante(+Verse, -Tail) is semidet.
%  Consonant rhyme tail: vowels AND consonants from last stress onward.
%  Cauda de rima consoante: vogais E consoantes da última tônica em diante.
cauda_consoante(Verso, Cauda) :-
    indice_ultima_tonica(Verso, I),
    nth1(I, Verso, sil(_, Nuc, Coda, _, _)),
    length(Pref, I), append(Pref, Pos, Verso),
    fonemas(Pos, FPos),
    append(Nuc, Coda, T0), append(T0, FPos, Cauda).

%! cauda_toante(+Verse, -Vowels) is semidet.
%  Assonant rhyme tail: only the vowels from last stress onward.
%  Cauda de rima toante: só as vogais da última tônica em diante.
cauda_toante(Verso, Vogais) :-
    indice_ultima_tonica(Verso, I),
    nth1(I, Verso, sil(_, Nuc, _, _, _)),
    length(Pref, I), append(Pref, Pos, Verso),
    nucleos(Pos, NPos), append(Nuc, NPos, Vogais).

rima_consoante(V1, V2) :- cauda_consoante(V1, C), cauda_consoante(V2, C).
rima_toante(V1, V2)    :- cauda_toante(V1, C),    cauda_toante(V2, C).

fonemas([], []).
fonemas([sil(O,Nu,Co,_,_)|R], F) :-
    fonemas(R, F0),
    append(O, Nu, A), append(A, Co, B), append(B, F0, F).

nucleos([], []).
nucleos([sil(_,Nu,_,_,_)|R], V) :- nucleos(R, V0), append(Nu, V0, V).


% ============================================================
%  PHONETIC FORMS / FORMAS FONÉTICAS
%  forma_fon(Name, Tradition, Metrics, Rhyme)
%    Metrics : todos(N) | [N1,N2,...]
%    Rhyme   : livre | list-model [a,a] etc. (consonant)
% ============================================================

forma_fon(decassilabo,          portugues_silabico, todos(10), livre).
forma_fon(parelha_decassilaba,  portugues_silabico, todos(10), [a,a]).
forma_fon(haiku,                haiku_japones,      [5,7,5],   livre).

%! valida_fon(+Name, +Verses) is semidet.
%  Validates verses against a phonetic form definition.
%  Valida versos contra uma definição de forma fonética.
valida_fon(Nome, Versos) :-
    forma_fon(Nome, Trad, Metrica, Rima),
    checa_metrica_fon(Trad, Metrica, Versos),
    checa_rima_fon(Rima, Versos).

checa_metrica_fon(Trad, todos(N), Versos) :- !,
    forall(member(V, Versos), escande(Trad, V, N)).
checa_metrica_fon(_, [], []).
checa_metrica_fon(Trad, [N|Ns], [V|Vs]) :-
    escande(Trad, V, N),
    checa_metrica_fon(Trad, Ns, Vs).

checa_rima_fon(livre, _).
checa_rima_fon(Modelo, Versos) :-
    is_list(Modelo),
    maplist(cauda_consoante, Versos, Classes),
    mesma_particao(Modelo, Classes).

% mesma estrutura de partição / same partition structure
mesma_particao(Modelo, Classes) :-
    length(Modelo, N), length(Classes, N),
    forall( ( nth1(I, Modelo, Mi), nth1(J, Modelo, Mj), I < J ),
            ( nth1(I, Classes, Ci), nth1(J, Classes, Cj),
              ( Mi == Mj -> Ci == Cj ; Ci \== Cj ) ) ).


% ============================================================
%  BRIDGE / PONTE with structural validator
%  contagens/3 returns all valid scansion counts for a verse.
% ============================================================

%! contagens(+Tradition, +Verse, -Counts) is det.
%  All distinct valid metric counts for Verse under Tradition.
%  Todas as contagens métricas válidas distintas para Verso na Tradição.
contagens(Trad, Verso, Lista) :- findall(N, escande(Trad, Verso, N), Bruta), sort(Bruta, Lista).


% ============================================================
%  EXAMPLES / EXEMPLOS (phonetic input = what Layer 1 produces)
% ============================================================

% --- PORTUGUESE: two decasyllables that rhyme in /ar/ ----------
% p1: oxítono, 11 sílabas com UMA sinalefa possível -> 10 ou 11
exemplo_pt(p1, [
    sil([k],[a],[],1,atona),   sil([s],[a],[],1,atona),
    sil([t],[e],[],1,atona),   sil([b],[o],[s],1,atona),
    sil([], [a],[],1,atona),
    sil([], [e],[],1,atona),
    sil([m],[i],[],1,atona),   sil([z],[o],[],1,atona),
    sil([l],[u],[],1,atona),   sil([p],[a],[],1,atona),
    sil([m],[a],[r],1,tonica)
]).

% p2: oxítono, 10 sílabas limpas (sem sinalefa) -> só 10
exemplo_pt(p2, [
    sil([v],[o],[],1,atona),   sil([s],[o],[],1,atona),
    sil([n],[o],[],1,atona),   sil([d],[e],[],1,atona),
    sil([t],[u],[],1,atona),   sil([d],[o],[],1,atona),
    sil([l],[a],[],1,atona),   sil([z],[a],[],1,atona),
    sil([b],[o],[],1,atona),   sil([d],[a],[r],1,tonica)
]).

% p3: PAROXÍTONO, 11 sílabas; tônica na 10, 11a pós-tônica.
% Demonstra o corte: 11 sílabas gramaticais -> métrica 10.
exemplo_pt(p3, [
    sil([k],[a],[],1,atona),   sil([k],[a],[],1,atona),
    sil([k],[a],[],1,atona),   sil([k],[a],[],1,atona),
    sil([k],[a],[],1,atona),   sil([k],[a],[],1,atona),
    sil([k],[a],[],1,atona),   sil([k],[a],[],1,atona),
    sil([k],[a],[],1,atona),   sil([l],[a],[],1,tonica),
    sil([d],[o],[],1,atona)
]).

% --- JAPANESE: haiku 5-7-5 MORAS (mora != syllable) -----------
% Linha 1: "Tō-kyō-no" = 3 sílabas, mas 5 MORAS (2+2+1)
% Linha 2: 7 sílabas monomoraicas = 7 moras
% Linha 3: "hon-no-yu-me" = 4 sílabas, 5 moras (2+1+1+1)
exemplo_haiku([
    [ sil([t],[o],[],2,_),  sil([k,y],[o],[],2,_),  sil([n],[o],[],1,_) ],
    [ sil([k],[a],[],1,_),  sil([w],[a],[],1,_),    sil([z],[u],[],1,_),
      sil([t],[o],[],1,_),  sil([b],[i],[],1,_),    sil([k],[o],[],1,_),
      sil([m],[u],[],1,_) ],
    [ sil([h],[o],[n],2,_), sil([n],[o],[],1,_),    sil([y],[u],[],1,_),
      sil([m],[e],[],1,_) ]
]).
