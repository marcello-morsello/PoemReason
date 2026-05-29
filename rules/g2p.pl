:- module(g2p, [g2p/3]).
:- encoding(utf8).
% ============================================================
%  g2p.pl — Grapheme-to-Phoneme converter (Brazilian Portuguese)
%
%  Conversor grafema-fonema para o português brasileiro.
%
%  g2p(+Word, -Syllables, -IPA)
%     Syllables : list of sil(Onset, Nucleus, Coda, Weight, Accent)
%                 → plugs directly into escande/3 and cauda_consoante/2
%     IPA       : atom with the transcription (ˈ before stressed syllable)
%
%  Pipeline: fonemiza → ajusta (sonoriza s, nasaliza, /l/, /r/,
%  ditongos) → silabifica (ataque máximo) → tonicidade
%  (acento gráfico, senão regra de terminação) → reduz
%  (vogal final átona) + palataliza (ti>tʃi, di>dʒi) → IPA.
%
%  Cobertura honesta / Known limitations:
%  NÃO resolve abertura de e/o tônicos sem acento (default fechado),
%  "x" (default ʃ), redução pretônica, clíticos átonos, nem
%  hiato/ditongo de natureza lexical.
% ============================================================

%! g2p(+Word, -Syllables, -IPA) is det.
%  Main entry point.  Takes an atom and returns enriched syllables
%  (sil/5) plus an IPA transcription atom.
%
%  Ponto de entrada principal.  Recebe um átomo e devolve sílabas
%  enriquecidas (sil/5) e a transcrição IPA.

% ---- inventário fonológico / phonological inventory ----------
nasal('ɐ̃'). nasal('ẽ'). nasal('ĩ'). nasal('õ'). nasal('ũ').
frontal(e). frontal(i). frontal('é'). frontal('ê'). frontal('í').
vogal_g(a). vogal_g(o). vogal_g(u). vogal_g('á'). vogal_g('ó'). vogal_g('ô'). vogal_g('ú').
consoante_simples(C) :- member(C, [p,b,t,d,k,f,v,r,l,m,n]).

vogal_map(a,a,0). vogal_map(e,e,0). vogal_map(i,i,0). vogal_map(o,o,0). vogal_map(u,u,0).
vogal_map('á',a,1). vogal_map('â',a,1). vogal_map('é','ɛ',1). vogal_map('ê',e,1).
vogal_map('í',i,1). vogal_map('ó','ɔ',1). vogal_map('ô',o,1). vogal_map('ú',u,1).
vogal_map('ã','ɐ̃',0). vogal_map('õ','õ',0). vogal_map('à',a,0).

% ============================================================
%  ENTRY POINT
% ============================================================
g2p(Palavra, Sils, IPA) :-
    downcase_atom(Palavra, Low),
    atom_chars(Low, Chars0),
    exclude(==(' '), Chars0, Chars),
    fonemiza(Chars, Toks0),
    ajusta(Toks0, Toks1),
    silabifica(Toks1, Sibs),                % sib(Ons,Nuc,Cod,Ac)
    tonicidade(Chars, Sibs, ITon),
    reduz(Sibs, ITon, Sils),
    ipa_de(Sils, IPA).

% ============================================================
%  1. FONEMIZA  (chars -> tokens vo(Q,Ac)|cons(P)|ong(w))
%     Converte caracteres em tokens fonêmicos.
% ============================================================
fonemiza([], []).
fonemiza([c,h|T], [cons('ʃ')|R]) :- !, fonemiza(T, R).
fonemiza([l,h|T], [cons('ʎ')|R]) :- !, fonemiza(T, R).
fonemiza([n,h|T], [cons('ɲ')|R]) :- !, fonemiza(T, R).
fonemiza([r,r|T], [cons('ʁ')|R]) :- !, fonemiza(T, R).
fonemiza([s,s|T], [cons(s)|R])   :- !, fonemiza(T, R).
fonemiza([s,c,V|T], [cons(s)|R]) :- frontal(V), !, fonemiza([V|T], R).
fonemiza([q,u,V|T], [cons(k)|R])         :- frontal(V), !, fonemiza([V|T], R).
fonemiza([q,u,V|T], [cons(k),ong(w)|R])  :- vogal_g(V), !, fonemiza([V|T], R).
fonemiza([g,u,V|T], [cons(g)|R])         :- frontal(V), !, fonemiza([V|T], R).
fonemiza([g,u,V|T], [cons(g),ong(w)|R])  :- vogal_g(V), !, fonemiza([V|T], R).
fonemiza([c,V|T], [cons(s)|R]) :- frontal(V), !, fonemiza([V|T], R).
fonemiza([c|T], [cons(k)|R]) :- !, fonemiza(T, R).
fonemiza(['ç'|T], [cons(s)|R]) :- !, fonemiza(T, R).
fonemiza([g,V|T], [cons('ʒ')|R]) :- frontal(V), !, fonemiza([V|T], R).
fonemiza([g|T], [cons(g)|R]) :- !, fonemiza(T, R).
fonemiza([j|T], [cons('ʒ')|R]) :- !, fonemiza(T, R).
fonemiza([x|T], [cons('ʃ')|R]) :- !, fonemiza(T, R).   % default (irregular)
fonemiza([h|T], R) :- !, fonemiza(T, R).               % h mudo
fonemiza([z|T], [cons(Z)|R]) :- !, ( T == [] -> Z = s ; Z = z ), fonemiza(T, R).
fonemiza([s|T], [cons(sv)|R]) :- !, fonemiza(T, R).    % 'sv' = s vozeável (só a letra s)
fonemiza([C|T], [cons(C)|R]) :- consoante_simples(C), !, fonemiza(T, R).
fonemiza([V|T], [vo(Q,Ac)|R]) :- vogal_map(V, Q, Ac), !, fonemiza(T, R).
fonemiza([_|T], R) :- fonemiza(T, R).

% ============================================================
%  2. AJUSTA — post-processing adjustments
%     Ajustes pós-fonemização.
% ============================================================
ajusta(Toks, Out) :-
    sonoriza(Toks, T1),       % s intervocálico -> z
    nasaliza(T1, T2),         % vogal + m/n coda -> vogal nasal
    resolve_rl(inicio, T2, T3), % l->w coda ; r tepe/forte
    ditonga(T3, Out).         % ditongos decrescentes / onglides

% --- s sonoro entre vogais / intervocalic voicing -------------
sonoriza([], []).
sonoriza([vo(Q,A), cons(sv), vo(Q2,A2) | T], [vo(Q,A), cons(z) | R]) :- !,
    sonoriza([vo(Q2,A2) | T], R).
sonoriza([cons(sv)|T], [cons(s)|R]) :- !, sonoriza(T, R).   % s não-intervocálico
sonoriza([X|T], [X|R]) :- sonoriza(T, R).

% --- nasalização / nasalization --------------------------------
nasaliza([], []).
nasaliza([vo(Q,Ac), cons(N) | T], [vo(QN,Ac) | R]) :-
    member(N, [m,n]), coda_contexto(T), !,
    nasaliza_q(Q, QN), nasaliza(T, R).
nasaliza([X|T], [X|R]) :- nasaliza(T, R).

coda_contexto([]).
coda_contexto([cons(_)|_]).
coda_contexto([ong(_)|_]).

nasaliza_q(a,'ɐ̃'). nasaliza_q(e,'ẽ'). nasaliza_q('ɛ','ẽ'). nasaliza_q(i,'ĩ').
nasaliza_q(o,'õ'). nasaliza_q('ɔ','õ'). nasaliza_q(u,'ũ').
nasaliza_q('ɐ̃','ɐ̃'). nasaliza_q('õ','õ').

% --- /l/ coda -> [w] ; r tepe vs forte / lateral & rhotic ------
resolve_rl(_, [], []).
resolve_rl(_, [cons(l)|T], [gl(w)|R]) :- coda_contexto(T), !, resolve_rl(meio, T, R).
resolve_rl(inicio, [cons(r)|T], [cons('ʁ')|R]) :- !, resolve_rl(meio, T, R).
resolve_rl(_, [cons(r)|T], [cons('ʁ')|R]) :- coda_contexto(T), !, resolve_rl(meio, T, R).
resolve_rl(_, [cons(r)|T], [cons('ɾ')|R]) :- !, resolve_rl(meio, T, R).
resolve_rl(_, [X|T], [X|R]) :- resolve_rl(meio, T, R).

% --- ditongos / diphthongs ------------------------------------
ditonga([], []).
ditonga([vo(QN,Ac), vo(o,0) | T], [vo(QN,Ac), g(w) | R]) :- nasal(QN), !, ditonga(T, R).
ditonga([vo(QN,Ac), vo(e,0) | T], [vo(QN,Ac), g(j) | R]) :- nasal(QN), !, ditonga(T, R).
ditonga([vo(Q,Ac), vo(i,0) | T], [vo(Q,Ac), g(j) | R]) :- !, ditonga(T, R).
ditonga([vo(Q,Ac), vo(u,0) | T], [vo(Q,Ac), g(w) | R]) :- !, ditonga(T, R).
ditonga([ong(w)|T], [g(w)|R]) :- !, ditonga(T, R).
ditonga([gl(w)|T], [g(w)|R])  :- !, ditonga(T, R).
ditonga([X|T], [X|R]) :- ditonga(T, R).

% ============================================================
%  3. SILABIFICA — syllabification (maximum onset)
%     Silabificação por ataque máximo.
% ============================================================
silabifica(Toks, Sibs) :-
    segmentos(Toks, Segs),
    pega_cons(Segs, Ataque0, Resto),
    blocos(Resto, Blocos),
    ( Blocos == [] -> Sibs = [] ; constroi(Ataque0, Blocos, Sibs) ).

% tokens -> segmentos: c(C) | preonset(G) | nuc(Vs,Ac)
segmentos([], []).
segmentos([vo(Q,Ac)|T], [nuc([Q|Gs],Ac)|R]) :- !, pega_glides(T, Gs, T2), segmentos(T2, R).
segmentos([g(G)|T], [preonset(G)|R]) :- !, segmentos(T, R).   % onglide antes de vogal
segmentos([ong(G)|T], [preonset(G)|R]) :- !, segmentos(T, R).
segmentos([gl(G)|T], [preonset(G)|R]) :- !, segmentos(T, R).
segmentos([cons(C)|T], [c(C)|R]) :- !, segmentos(T, R).
segmentos([_|T], R) :- segmentos(T, R).

pega_glides([g(G)|T], [G|Gs], T2) :- !, pega_glides(T, Gs, T2).
pega_glides(T, [], T).

% consoantes/preonsets iniciais até o 1o núcleo
pega_cons([S|T], [C|Cs], R) :- seg_cons(S, C), !, pega_cons(T, Cs, R).
pega_cons(T, [], T).
seg_cons(c(C), C).
seg_cons(preonset(G), G).

% blocos: cada núcleo + consoantes que o seguem
blocos([], []).
blocos([nuc(Vs,Ac)|T], [bloco(Vs,Ac,Cons)|R]) :- !, pega_cons(T, Cons, T2), blocos(T2, R).
blocos([_|T], R) :- blocos(T, R).

% constrói sílabas distribuindo as consoantes por ataque máximo
constroi(Ons, [bloco(Vs,Ac,Cons)], [sib(Ons,Vs,Cons,Ac)]) :- !.
constroi(Ons, [bloco(Vs,Ac,Cons)|Resto], [sib(Ons,Vs,Coda,Ac)|Rs]) :-
    ataque_maximo(Cons, Coda, OnsProx),
    constroi(OnsProx, Resto, Rs).

ataque_maximo([], [], []) :- !.
ataque_maximo([C], [], [C]) :- !.
ataque_maximo(Cs, Coda, Onset) :-
    append(Pref, [A,B], Cs),
    ( grupo_valido(A, B) -> Onset = [A,B], Coda = Pref
    ; Onset = [B], append(Pref, [A], Coda) ).

grupo_valido(O, 'ɾ') :- member(O, [p,b,t,d,k,g,f,v]).
grupo_valido(O, l)    :- member(O, [p,b,t,d,k,g,f,v]).
grupo_valido(k, w).
grupo_valido(g, w).

% ============================================================
%  4. TONICIDADE — stress assignment
%     Atribui tonicidade: acento gráfico primeiro, senão regra
%     de terminação (oxítona/paroxítona).
% ============================================================
tonicidade(Chars, Sibs, ITon) :-
    length(Sibs, N),
    ( N =< 1 -> ITon = 1
    ; nth1(IAcc, Sibs, sib(_,_,_,1)) -> ITon = IAcc      % acento gráfico
    ; oxitona(Chars) -> ITon = N
    ; ITon is N - 1 ).

oxitona(Chars) :-
    ( append(_, ['ã',o], Chars) -> true                  % -ão
    ; append(_, ['ã',e], Chars) -> true                  % -ãe
    ; append(_, ['õ',e], Chars) -> true                  % -õe
    ; last(Chars, U), termina_aguda(U) ).
termina_aguda(U) :- member(U, [i,u,'í','ú','ã','õ',r,l,z,x,n,'á','ó']).

% ============================================================
%  5. REDUZ + PALATALIZA — vowel reduction & palatalization
%     Redução de vogal final átona + palatalização (ti>tʃi, di>dʒi).
% ============================================================
reduz(Sibs, ITon, Sils) :-
    length(Sibs, N),
    reduz_(Sibs, 1, N, ITon, S0),
    palataliza(S0, Sils).

reduz_([], _, _, _, []).
reduz_([sib(O,Nuc,C,_)|T], I, N, ITon, [sil(O,Nuc2,C,1,Ac)|R]) :-
    ( I =:= ITon -> Ac = tonica ; Ac = atona ),
    ( I =:= N, Ac == atona -> reduz_final(Nuc, Nuc2) ; Nuc2 = Nuc ),
    I1 is I+1, reduz_(T, I1, N, ITon, R).

reduz_final([V|Gs], [V2|Gs]) :- ( red(V,V2) -> true ; V2 = V ).
red(a,'ɐ'). red(e,i). red(o,u). red('ɛ',i). red('ɔ',u).

palataliza([], []).
palataliza([sil(O,Nuc,C,P,Ac)|T], [sil(O2,Nuc,C,P,Ac)|R]) :-
    ( append(Pre,[t],O), Nuc=[i|_] -> append(Pre,['tʃ'],O2)
    ; append(Pre,[d],O), Nuc=[i|_] -> append(Pre,['dʒ'],O2)
    ; O2 = O ),
    palataliza(T, R).

% ============================================================
%  6. IPA — build IPA transcription from sil/5 list
%     Monta a transcrição IPA a partir da lista de sil/5.
% ============================================================
ipa_de(Sils, IPA) :-
    maplist(ipa_sil, Sils, Parts),
    atomic_list_concat(Parts, IPA).

ipa_sil(sil(O,Nuc,C,_,Ac), Str) :-
    append(O, Nuc, ON), append(ON, C, Fones),
    atomic_list_concat(Fones, Seg),
    ( Ac == tonica -> atom_concat('ˈ', Seg, Str) ; Str = Seg ).
