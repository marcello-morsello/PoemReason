:- module(core, [
    aprovar_credito/2,
    aprovar_credito_json/1
]).

:- use_module(clients).
:- use_module(library(http/json)).

%! aprovar_credito(+Client, -Decision) is det.
%  Returns a single deterministic decision for Client.
aprovar_credito(Client, aprovado) :-
    cliente(Client, _, score(S), _),
    S >= 800, !.

aprovar_credito(Client, aprovado) :-
    cliente(Client, renda(R), score(S), divida(D)),
    S >= 700, S < 800,
    D < R * 0.3, !.

aprovar_credito(Client, analise_manual) :-
    cliente(Client, renda(R), score(S), divida(D)),
    S >= 600, S < 700,
    D < R * 0.4, !.

aprovar_credito(Client, negado) :-
    cliente(Client, _, _, _).

%! aprovar_credito_json(+Client) is det.
%  Writes the credit decision for Client as JSON to stdout.
aprovar_credito_json(Client) :-
    aprovar_credito(Client, Decision),
    json_write_dict(current_output, _{cliente: Client, decisao: Decision}),
    nl.
