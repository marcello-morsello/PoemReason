:- module(pipeline, [
    linha_sils/3,
    verso_ln/2,
    gera_de_texto/4
]).
:- encoding(utf8).
% ============================================================
%  pipeline.pl — Portuguese pipeline loader
%
%  Loader da pipeline para português.
%  Paths are relative to rules/pt/.
% ============================================================

:- use_module('g2p', [g2p/3]).
:- use_module('phonetics', [contagens/3, cauda_consoante/2, cauda_toante/2, tradicao_padrao/1]).
:- use_module('../common/structural_validator').
:- use_module('../common/diagnostics').
:- use_module('../common/html_report', [gera_html/5]).
:- use_module('../common/core').
