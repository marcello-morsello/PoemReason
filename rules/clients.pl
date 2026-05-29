:- module(clients, [cliente/4]).

%! cliente(+Name, +Income, +Score, +Debt) is nondet.
%  Client facts: cliente(Name, renda(Income), score(Score), divida(Debt)).
cliente(joao,  renda(5000), score(720), divida(800)).
cliente(maria, renda(3000), score(680), divida(200)).
cliente(pedro, renda(8000), score(550), divida(3000)).
cliente(ana,   renda(4000), score(850), divida(5000)).
