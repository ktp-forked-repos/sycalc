:-ensure_loaded(polynomial).
:-ensure_loaded(list).

% Takes a polynomial as a list of monomials and reduces it
list_red_monomials([], []):- !.
list_red_monomials([0], []):- !.
list_red_monomials([M], [RM]):- red_monomial(M, RM), !.
list_red_monomials([M1,M2], []):- mon_sum(M1, M2, 0), !.
list_red_monomials([M1,M2], [S]):- mon_sum(M1, M2, S), not(polynomial_eq(M1 + M2, S)), !.
list_red_monomials([M1,M2], [M1,M2]):- !.
list_red_monomials([M1,M2|L], R):- mon_sum(M1, M2, S), not(polynomial_eq(M1 + M2, S)), list_red_monomials([S|L], R), !.
list_red_monomials([M1,M2|L], [M1|R]):- list_red_monomials([M2|L], R), !.
list_red_monomials(X, X).

% Takes a polynomial as a list and returns it as a reduced list of monomials
list_red_list_polynomial(L, LR):- monomial_sort(L, R), list_red_monomials(R, LR).

% Takes an expanded polynomial and reduces it: x + x + 2 -> 2*x + 2
polynomial_sum(P, R):-
	polynomial_monomials(P, M), list_red_list_polynomial(M, L),
	list_polynomial(L, R).

% Takes two polynomials each of them as a list, adds the second from the first
% and returns it as a reduced list of monomials
list_polynomial_sum_list(P1, P2, R):- concat(P1, P2, P), list_red_list_polynomial(P, R).

% Takes two polynomials each of them as a list, substracts the second from the first
% and returns it as a reduced list of monomials
list_polynomial_sub_list(P1, P2, R):-
	map(monomial_neg, P2, NP2), concat(P1, NP2, P),
	list_red_list_polynomial(P, R).

% Takes two polynomials each of them as a list, multiplies them and returns it as
% a reduced list of monomials
list_polynomial_prod_list(L1, L2, L):-
	cartesian_product(L1, L2, CP), map(mon_prod, CP, MON_PROD),
	list_red_list_polynomial(MON_PROD, L).

% Takes two expanded polynomials and multiplies them
% polynomial_prod(P, Q, R), where R = P*Q
polynomial_prod(P1, P2, P):-
	polynomial_monomials(P1, L1), polynomial_monomials(P2, L2),
	list_polynomial_prod_list(L1, L2, MON_PROD), list_polynomial(MON_PROD, P).

% Takes a polynomial as a list, an integer number and performs the power P^N
list_polynomial_power_list(_, 0, [1]):- !.
list_polynomial_power_list(L, 1, L):- !.
list_polynomial_power_list(LP, N, LN):-
	natural(N), N1 is N - 1, list_polynomial_power_list(LP, N1, L),
	list_polynomial_prod_list(LP, L, LN).

% Takes an expanded polynomial, an integer number and performs the power P^N
% polynomial_prod(P, N, Q), where Q = P^N
polynomial_power(_, 0, 1):- !.
polynomial_power(P, 1, P):- !.
polynomial_power(P, N, PN):-
	polynomial_monomials(P, M), list_polynomial_power_list(M, N, L),
	list_polynomial(L, PN).

% POLYNOMIAL EXPRESSIONS' EVALUATION

polynomial_evaluation_list(Q1 + Q2, R):-
	polynomial_evaluation_list(Q1, L1), polynomial_evaluation_list(Q2, L2),
	concat(L1, L2, L), list_red_list_polynomial(L, R), !.
polynomial_evaluation_list(Q1 - Q2, R):-
	polynomial_evaluation_list(Q1, L1), polynomial_evaluation_list(Q2, L2),
	map(monomial_neg, L2, NL2),
	concat(L1, NL2, L), list_red_list_polynomial(L, R), !.
polynomial_evaluation_list(Q1 * Q2, R):-
	polynomial_evaluation_list(Q1, L1), polynomial_evaluation_list(Q2, L2),
	cartesian_product(L1, L2, L), map(mon_prod, L, PROD), list_red_list_polynomial(PROD, R), !.
polynomial_evaluation_list(Q1 ^ N, R):-
	polynomial_evaluation_list(Q1, L1), list_polynomial_power_list(L1, N, R), !.
polynomial_evaluation_list(P, [R]):- red_monomial(P, R), !.

% Takes a sequence of sums and substractions P of polynomials, contracted or expanded,
% and operates it.
polynomial_evaluation(P, R):- polynomial_evaluation_list(P, L), list_polynomial(L, R).

% Takes two polynomials, expanded or contracted, evaluates them, and fails if they are not equal
polynomial_eval_eq(P1, P2):- polynomial_evaluation(P1, EP1), polynomial_evaluation(P2, EP2), polynomial_eq(EP1, EP2).

% POLYNOMIAL EVALUATION

% Takes an expanded polynomial and evaluates it with the value VAL
% VAL: real value
% P(x): expanded polynomial
% E: P(VAL)
expanded_polynomial_evaluation(VAL, P, E):-
	polynomial_monomials(P, MS), map(monomial_evaluation(VAL), MS, R), foldl(eval_sum, 0, R, E).

% Takes a contracted polynomial and evaluates it with the value VAL
contracted_polynomial_evaluation(VAL, P, E):-
	polynomial_evaluation(P, EXP), expanded_polynomial_evaluation(VAL, EXP, E).

