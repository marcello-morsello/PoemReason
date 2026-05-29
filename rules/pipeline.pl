:- module(pipeline, [
    linha_sils/3,
    verso_ln/2,
    gera_de_texto/4
]).
:- encoding(utf8).
% ============================================================
%  pipeline.pl — End-to-end: raw text -> HTML report
%
%  Fecha o ciclo: TEXTO CRU -> relatório HTML.
%
%  The user provides only the poem text; the G2P layer generates
%  IPA + sil/5, escande/3 counts syllables, cauda_consoante/2
%  extracts the rhyme class, and the HTML generator assembles
%  everything with the TTS vocalizer.
%
%  O usuário digita só o texto; o G2P gera IPA + sil/5, o
%  escande/3 conta as sílabas, a cauda_consoante extrai a rima,
%  e o gerador HTML monta tudo com o vocalizador.
% ============================================================

:- use_module(g2p, [g2p/3]).
:- use_module(phonetic_validator, [contagens/3, cauda_consoante/2]).
:- use_module(html_report, [gera_html/5]).

%! linha_sils(+Text, -Syllables, -IPA) is det.
%  Converts a verse text into concatenated sil/5 structures and IPA.
%  Converte um verso de texto em sílabas sil/5 concatenadas e IPA.
linha_sils(Texto, Sils, IPA) :-
    split_string(Texto, " ", "", P0),
    exclude(==(""), P0, Pedacos),
    maplist(palavra_sils, Pedacos, Listas, IPAs),
    append(Listas, Sils),
    atomic_list_concat(IPAs, ' ', IPA).

palavra_sils(Str, Sils, IPA) :- atom_string(A, Str), g2p(A, Sils, IPA).

%! verso_ln(+Text, -LnRecord) is det.
%  Converts verse text into ln(Text, IPA, Counts, RhymeClass).
%  Converte texto de verso em ln(Texto, IPA, Contagens, ClasseDeRima).
verso_ln(Texto, ln(Texto, IPA, Cont, Classe)) :-
    linha_sils(Texto, Sils, IPA),
    contagens(portugues_silabico, Sils, Cont),
    ( cauda_consoante(Sils, Classe) -> true ; Classe = '?' ).

%! gera_de_texto(+File, +Title, +Form, +StanzasText) is det.
%  End-to-end: list of stanzas of text strings -> HTML file.
%  De ponta a ponta: lista de estrofes de strings -> arquivo HTML.
gera_de_texto(Arquivo, Titulo, Forma, EstrofesTxt) :-
    maplist(maplist(verso_ln), EstrofesTxt, EstrofesLn),
    gera_html(Arquivo, Titulo, Forma, "pt-BR", EstrofesLn).
