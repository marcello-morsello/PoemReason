:- encoding(utf8).
:- use_module('../rules/common/diagnostics').
:- use_module(library(plunit)).

% ============================================================
%  diagnostics_tests.pl — Unit tests for the diagnostics/report layer
%
%  Testes unitários para a camada de diagnóstico/relatório.
%  Covers correct sonnets, sonnets with errors, and villanelle
%  with broken refrain — verifying problem lists.
% ============================================================

:- begin_tests(diagnostics).

% Correct Italian sonnet: zero problems
test(sonnet_ok_no_problems) :-
    diagnostics:exemplo_diag(soneto_ok, P),
    diagnostica(soneto_italiano, P, Probs),
    Probs == [].

% Sonnet with two errors: should find problems
test(sonnet_errors_detected) :-
    diagnostics:exemplo_diag(soneto_com_erros, P),
    diagnostica(soneto_italiano, P, Probs),
    Probs \== [].

% Sonnet with errors: should have metric problem on verse 7
test(sonnet_metric_error_v7, [nondet]) :-
    diagnostics:exemplo_diag(soneto_com_erros, P),
    diagnostica(soneto_italiano, P, Probs),
    member(prob(_, 7, metrica, _), Probs).

% Sonnet with errors: should have rhyme problem on verse 4
test(sonnet_rhyme_error_v4) :-
    diagnostics:exemplo_diag(soneto_com_erros, P),
    diagnostica(soneto_italiano, P, Probs),
    member(prob(_, 4, rima, _), Probs).

% Short-circuit: a sonnet with the wrong verse count must return ONLY the
% structural error, even when individual verses also carry metric/rhyme
% defects that would otherwise be flagged.
%
% Curto-circuito: um soneto com numero de versos errado deve devolver
% APENAS o erro estrutural, mesmo que versos individuais tenham defeitos
% de metrica/rima que seriam apontados normalmente.
test(sonnet_short_circuit_on_wrong_verse_count) :-
    % 13 verses instead of 14; v3 has wrong metric ([7]); v2 has off-group rhyme.
    BrokenSonnet = poema([
        verso("v1",  [10], a),
        verso("v2",  [10], zz),   % rhyme outlier (would trip rima check)
        verso("v3",  [7],  a),    % wrong metric (would trip metrica check)
        verso("v4",  [10], a),
        verso("v5",  [10], a),  verso("v6",  [10], b),
        verso("v7",  [10], b),  verso("v8",  [10], a),
        verso("v9",  [10], c),  verso("v10", [10], d),
        verso("v11", [10], c),  verso("v12", [10], d),
        verso("v13", [10], c)
    ]),
    diagnostica(soneto_italiano, BrokenSonnet, Probs),
    Probs = [prob(0, 0, estrutura, _)],
    \+ member(prob(_, _, metrica, _), Probs),
    \+ member(prob(_, _, rima, _), Probs).

% Villanelle with broken refrain: should detect refrain problem
test(vilanela_refrain_problem) :-
    diagnostics:exemplo_diag(vilanela_quebrada, P),
    diagnostica(vilanela, P, Probs),
    member(prob(_, _, refrao, _), Probs).

% A toante (assonant) form accepts verses whose consonant tails
% differ as long as the vowels align with the pattern.
%
% Forma toante aceita versos com caudas consoantes diferentes desde
% que as vogais sigam o padrão.
test(cordel_toante_ok) :-
    diagnostics:exemplo_diag(cordel_toante_ok, P),
    diagnostica(cordel_sextilha, P, Probs),
    Probs == [].

% Cordel sextilha breaks at v4 (vowel 'u' instead of 'a'); the
% majority of letter 'b' is at v2 and v6 (both 'a'), so v4 is the
% unambiguous outlier.
%
% No cordel sextilha, v4 quebra com vogal 'u' em vez de 'a'; a
% maioria da letra 'b' (em v2 e v6) está em 'a', então v4 é o
% outlier sem ambiguidade.
test(cordel_toante_outlier_v4) :-
    diagnostics:exemplo_diag(cordel_toante_outlier_v4, P),
    diagnostica(cordel_sextilha, P, Probs),
    member(prob(_, 4, rima, _), Probs),
    \+ member(prob(_, 2, rima, _), Probs),
    \+ member(prob(_, 6, rima, _), Probs).

% estrofe_de locates correctly
test(stanza_location) :-
    estrofe_de([4,4,3,3], 5, 2, _).

test(stanza_location_first) :-
    estrofe_de([4,4,3,3], 3, 1, _).

:- end_tests(diagnostics).
