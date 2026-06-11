:- module(phonetics, [
    escande/3,
    soma_moras/2,
    contagens/3,
    cauda_consoante/2,
    cauda_toante/2,
    rima_consoante/2,
    rima_toante/2,
    tradicao_padrao/1
]).
:- encoding(utf8).

% ---- local forms / formas locais -----------------------------
% Registered via multifile into structural_validator and diagnostics.
% All Japanese forms use livre rhyme (no rhyme scheme).
:- multifile structural_validator:forma/4.
:- multifile diagnostics:forma_estr/4.
% ============================================================
%  phonetics.pl — Japanese phonetic versification engine
%
%  Motor de escansão e rima para japonês (moraico).
%
%  Japanese poetry counts morae (on), not syllables.
%  Each kana character = 1 mora.  No synaloepha.
%  No stress-based cut — the whole line counts.
%
%  Poesia japonesa conta moras (on), não sílabas.
%  Cada kana = 1 mora.  Sem sinalefa.
%  Sem corte na tônica — o verso inteiro conta.
% ============================================================

tradicao_padrao(haiku_japones).

% ---- mora count / contagem moraica ---------------------------
% Each sil/5 carries weight (slot 4).  Sum weights.
soma_moras([], 0).
soma_moras([sil(_,_,_,P,_)|R], N) :- soma_moras(R, N0), N is N0 + P.

% ---- scansion / escansão -------------------------------------
% Japanese: sum weights of all syllables (no cut, no synaloepha).
escande(haiku_japones, Verso, N) :-
    !, soma_moras(Verso, N).

%! contagens(+Tradition, +Verse, -Counts) is det.
contagens(Trad, Verso, Lista) :-
    findall(N, escande(Trad, Verso, N), Bruta), sort(Bruta, Lista).

% ---- rhyme / rima --------------------------------------------
% Same logic as Portuguese: extract from last syllable to end.
% For Japanese, rhyme is typically not used, but the structure
% is available for forms that might need it.

cauda_consoante(Verso, Cauda) :-
    reverse(Verso, [sil(_, Nuc, Coda, _, _)|_]),
    append(Nuc, Coda, Cauda).

cauda_toante(Verso, Vogais) :-
    reverse(Verso, [sil(_, Nuc, _, _, _)|_]),
    Vogais = Nuc.

rima_consoante(V1, V2) :- cauda_consoante(V1, C), cauda_consoante(V2, C).
rima_toante(V1, V2)    :- cauda_toante(V1, C),    cauda_toante(V2, C).

% ============================================================
%  JAPANESE FORMS (multifile into common modules)
%  Formas japonesas (multifile nos módulos comuns)
% ============================================================

% Chōka: 5-7-5-7...5-7-7 (long poem, odd number of verses)
% Representamos como "N versos, métrica alternada, livre rima"
% A checagem exata do padrão 5-7-5-7...5-7-7 fica em restricao_extra.
% structural_validator:forma(choka, N, M, livre) :-
%     N >= 3, N mod 2 =:= 1,
%     alterna_5_7(N, M).

% Para simplificar na Fase 3: chōka como sequência fixa de 5-7-5-7-5-7-7
% (7 versos = exemplo didático). Uso real exigiria restricao_extra.
structural_validator:forma(choka, 7, [5,7,5,7,5,7,7], livre).

% Sedōka: 6 versos 5-7-7-5-7-7 (dois katauta)
structural_validator:forma(sedoka, 6, [5,7,7,5,7,7], livre).

% Bussokusekika: 6 versos 5-7-5-7-7-7 (tanka + 7 extra)
structural_validator:forma(bussokusekika, 6, [5,7,5,7,7,7], livre).

% Katauta: 3 versos 5-7-7 (half-poem, incomplete)
structural_validator:forma(katauta, 3, [5,7,7], livre).

% Dodoitsu: 4 versos 7-7-7-5 (popular, comical)
structural_validator:forma(dodoitsu, 4, [7,7,7,5], livre).

% ---- diagnostics stanza info / info de estrofes -------------
% For Japanese forms, each poem is a single stanza.
diagnostics:forma_estr(choka, [7], [5,7,5,7,5,7,7], livre).
diagnostics:forma_estr(sedoka, [6], [5,7,7,5,7,7], livre).
diagnostics:forma_estr(bussokusekika, [6], [5,7,5,7,7,7], livre).
diagnostics:forma_estr(katauta, [3], [5,7,7], livre).
diagnostics:forma_estr(dodoitsu, [4], [7,7,7,5], livre).
