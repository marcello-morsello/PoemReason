:- module(html_report, [gera_html/5]).
:- encoding(utf8).
% ============================================================
%  html_report.pl — Interactive HTML poetry report generator
%
%  Gerador de relatório HTML interativo para poemas.
%
%  Generates an HTML report with:
%    - Verses grouped by stanza
%    - IPA transcription per line
%    - TTS buttons (Web Speech API)
%    - Diagnostic badges from diagnostica/3
%
%  Gera relatório HTML com versos agrupados em estrofes,
%  transcrição IPA, botões TTS (Web Speech API) e marcas
%  de aderência ao formato (do diagnostica/3).
%
%  CSS and JS are loaded from external files in static/.
% ============================================================

:- use_module(diagnostics, [diagnostica/3]).

% ---- main API / API principal --------------------------------

%! gera_html(+File, +Title, +Form, +Lang, +Stanzas) is det.
%  Writes an HTML report to File.  Stanzas is a list of lists of
%  ln(Text, IPA, Syllables, rima(ConsonantTail, AssonantTail)).
%
%  Escreve um relatório HTML em File.  Stanzas é uma lista de listas
%  de ln(Texto, IPA, Silabas, rima(CaudaConsoante, CaudaToante)).
gera_html(Arquivo, Titulo, Forma, Lang, Estrofes) :-
    aplaina(Estrofes, Versos),
    diagnostica(Forma, poema(Versos), Probs),
    length(Probs, NP),
    setup_call_cleanup(
        open(Arquivo, write, S, [encoding(utf8)]),
        ( emite_topo(S, Titulo, Forma, NP),
          emite_estrofes(S, Estrofes, 1, 0, Probs, Lang),
          emite_fundo(S) ),
        close(S)).

% ln(Text, IPA, Syl, rima(C,A)) -> verso(Text, Syl, rima(C,A))
% The rhyme compound is passed straight through; diagnostica/3 picks
% the consonant or assonant slot based on the form's mode.
aplaina(Estrofes, Versos) :-
    findall(verso(T, Sil, C),
            ( member(Est, Estrofes), member(ln(T,_,Sil,C), Est) ),
            Versos).

% ============================================================
%  HTML EMISSION
% ============================================================
emite_topo(S, Titulo, Forma, NP) :-
    ( NP =:= 0 -> Badge = "aderente", BadgeCls = "ok"
    ; format(atom(Badge), "~w ponto(s) fora do formato", [NP]), BadgeCls = "bad" ),
    escape_html(Titulo, TitH),
    format(S, '<!doctype html><html lang="pt-BR"><head><meta charset="utf-8">~n', []),
    format(S, '<meta name="viewport" content="width=device-width, initial-scale=1">~n', []),
    format(S, '<title>~w</title>~n', [TitH]),
    format(S, '<link rel="preconnect" href="https://fonts.googleapis.com">~n', []),
    format(S, '<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>~n', []),
    format(S, '<link href="https://fonts.googleapis.com/css2?family=EB+Garamond:ital,wght@0,400;0,500;1,400&family=Gentium+Book+Plus:ital@0;1&display=swap" rel="stylesheet">~n', []),
    format(S, '<link rel="stylesheet" href="static/style.css">~n', []),
    format(S, '</head><body>~n', []),
    format(S, '<main class="folha">~n', []),
    format(S, '  <header class="cabeca">~n', []),
    format(S, '    <p class="forma">~w</p>~n', [Forma]),
    format(S, '    <h1>~w</h1>~n', [TitH]),
    format(S, '    <span class="badge ~w">~w</span>~n', [BadgeCls, Badge]),
    format(S, '    <button class="dizer-tudo" id="lerTudo">&#9654; ouvir o poema</button>~n', []),
    format(S, '  </header>~n', []).

emite_estrofes(_, [], _, _, _, _).
emite_estrofes(S, [Est|Ests], E, Base, Probs, Lang) :-
    format(S, '  <section class="estrofe">~n', []),
    format(S, '    <div class="num">~w</div>~n', [E]),
    format(S, '    <div class="versos">~n', []),
    emite_linhas(S, Est, Base, Probs, Lang),
    format(S, '    </div>~n  </section>~n', []),
    length(Est, K), Base1 is Base + K, E1 is E + 1,
    emite_estrofes(S, Ests, E1, Base1, Probs, Lang).

emite_linhas(_, [], _, _, _).
emite_linhas(S, [ln(Txt,Ipa,_,_)|Ls], Base, Probs, Lang) :-
    G is Base + 1,
    findall(Tp-M, member(prob(_,G,Tp,M), Probs), Falhas),
    ( Falhas == [] -> Cls = "ok" ; Cls = "bad" ),
    escape_html(Txt, TxtH), escape_html(Ipa, IpaH), escape_html(Txt, TxtA),
    format(S, '      <div class="linha ~w">~n', [Cls]),
    format(S, '        <span class="marca" title="~w"></span>~n', [Cls]),
    format(S, '        <button class="dizer" data-text="~w" data-lang="~w" aria-label="ouvir verso">&#128266;</button>~n', [TxtA, Lang]),
    format(S, '        <div class="texto">~n', []),
    format(S, '          <p class="verso">~w</p>~n', [TxtH]),
    format(S, '          <p class="ipa">/ ~w /</p>~n', [IpaH]),
    ( Falhas == [] -> true
    ; format(S, '          <ul class="notas">~n', []),
      forall(member(Tp-M, Falhas),
             ( escape_html(M, MH),
               format(S, '            <li><b>~w:</b> ~w</li>~n', [Tp, MH]) )),
      format(S, '          </ul>~n', []) ),
    format(S, '        </div>~n      </div>~n', []),
    emite_linhas(S, Ls, G, Probs, Lang).

emite_fundo(S) :-
    format(S, '</main>~n<script src="static/script.js"></script>~n</body></html>~n', []).

% ---- HTML escape / escape HTML -------------------------------
escape_html(In, Out) :-
    ( string(In) -> string_chars(In, Cs) ; atom_chars(In, Cs) ),
    maplist(esc, Cs, Ps),
    atomic_list_concat(Ps, Out).
esc('&', '&amp;')  :- !.
esc('<', '&lt;')   :- !.
esc('>', '&gt;')   :- !.
esc('"', '&quot;') :- !.
esc(C, C).
