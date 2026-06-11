:- encoding(utf8).
:- use_module('../rules/common/html_report').
:- use_module(library(plunit)).

% ============================================================
%  html_report_tests.pl — Unit tests for the HTML report generator
%
%  Tests generate HTML content and verify output via file I/O.
% ============================================================

:- dynamic tc/1.
tc(0).

tmp(P) :- retract(tc(N)), N1 is N + 1, asserta(tc(N1)),
          atomic_list_concat(['/tmp/poem_ht_', N1], P).

file_content(Path, Content) :-
    setup_call_cleanup(
        open(Path, read, S, [encoding(utf8)]),
        read_string(S, _, Content),
        close(S)).

:- begin_tests(html_report).

test(creates_file) :-
    tmp(F),
    E = [ln('V', 'I', [10], rima([a],[a]))],
    gera_html(F, 'T', 'soneto_italiano', 'pt-BR', [E]),
    exists_file(F),
    delete_file(F).

test(has_doctype) :-
    tmp(F), E = [ln('V','I',[10],rima([a],[a]))],
    gera_html(F, 'T', 'soneto_italiano', 'pt-BR', [E]),
    file_content(F, C),
    sub_string(C, _, _, _, '<!doctype html>'),
    delete_file(F).

test(has_close_html) :-
    tmp(F), E = [ln('V','I',[10],rima([a],[a]))],
    gera_html(F, 'T', 'soneto_italiano', 'pt-BR', [E]),
    file_content(F, C),
    sub_string(C, _, _, _, '</html>'),
    delete_file(F).

test(has_title) :-
    tmp(F), E = [ln('V','I',[10],rima([a],[a]))],
    gera_html(F, 'Meu Título', 'soneto_italiano', 'pt-BR', [E]),
    file_content(F, C),
    sub_string(C, _, _, _, 'Meu Título'),
    delete_file(F).

test(has_form_name) :-
    tmp(F), E = [ln('V','I',[10],rima([a],[a]))],
    gera_html(F, 'X', 'soneto_italiano', 'pt-BR', [E]),
    file_content(F, C),
    sub_string(C, _, _, _, 'soneto_italiano'),
    delete_file(F).

test(has_ipa) :-
    tmp(F), E = [ln('Verso','ˈtesːi',[10],rima([a],[a]))],
    gera_html(F, 'X', 'soneto_italiano', 'pt-BR', [E]),
    file_content(F, C),
    sub_string(C, _, _, _, 'ˈtesːi'),
    delete_file(F).

test(has_static_css) :-
    tmp(F), E = [ln('V','I',[10],rima([a],[a]))],
    gera_html(F, 'X', 'soneto_italiano', 'pt-BR', [E]),
    file_content(F, C),
    sub_string(C, _, _, _, 'static/style.css'),
    delete_file(F).

test(has_static_js) :-
    tmp(F), E = [ln('V','I',[10],rima([a],[a]))],
    gera_html(F, 'X', 'soneto_italiano', 'pt-BR', [E]),
    file_content(F, C),
    sub_string(C, _, _, _, 'static/script.js'),
    delete_file(F).

test(escapes_amp) :-
    tmp(F), E = [ln('A & B','I',[10],rima([a],[a]))],
    gera_html(F, 'X', 'soneto_italiano', 'pt-BR', [E]),
    file_content(F, C),
    sub_string(C, _, _, _, '&amp;'),
    delete_file(F).

test(escapes_ltgt) :-
    tmp(F), E = [ln('<x>','I',[10],rima([a],[a]))],
    gera_html(F, '<T>', 'soneto_italiano', 'pt-BR', [E]),
    file_content(F, C),
    sub_string(C, _, _, _, '&lt;x&gt;'),
    sub_string(C, _, _, _, '&lt;T&gt;'),
    delete_file(F).

:- end_tests(html_report).
