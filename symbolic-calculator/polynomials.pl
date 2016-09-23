:-ensure_loaded(integer_algorithms).
:-ensure_loaded(monomials).
:-ensure_loaded(numbers).
:-ensure_loaded(lists).

% POLYNOMIALS
% A polynomial is a sum of monomials.
% These are monomials:
% 	x^3, -2*x, 6*x^2, x, -2
% These are not monomials:
% 	(x + 3)*(x - 2), x*x, x*y

some_expr(A + B):- write(A), write( ' -=- '), write(B).

polynomial_monomials(M, [R]):- red_monomial(M, R), !.
polynomial_monomials(A + B, S):- polynomial_monomials(A, L), polynomial_monomials(B, R), concat(L, R, S), !.
polynomial_monomials(A - B, S):- polynomial_monomials(A, L), polynomial_monomials(-B, R), concat(L, R, S), !.

%L: INCREASINGLY sorted list of monomials by exponent
padded_poly_mons_incr([], []).
padded_poly_mons_incr([M], R):- monomial_degree(M, D), D > 0, padded_list([M], D, 0, R), !.
padded_poly_mons_incr([M], [M]):- !.
padded_poly_mons_incr([M|MS], [M|P]):- first(MS, F, _), monomial_degree(M, D1), monomial_degree(F, D2), 1 is D1 - D2, padded_poly_mons_incr(MS, P), !.
padded_poly_mons_incr([M|MS], P):-
	first(MS, F, _), monomial_degree(M, D1), monomial_degree(F, D2), K is D1 - D2 - 1,
	padded_list([M], K, 0, R), padded_poly_mons_incr(MS, Q), concat(R, Q, P), !.

%padded_poly_mons_incr( [x^4, -10*x^2, 9], P ).

first_monomial(A + B, A, B):- monomial(A), monomial(B), !.
first_monomial(A - B, A, N):- monomial(A), monomial(B), monomial_neg(B, N), !.
first_monomial(A + B, F, S + B):- first_monomial(A, F, S), !.
first_monomial(A - B, F, S - B):- first_monomial(A, F, S), !.
first_monomial(F, F, _).

last_monomial(A + B, A, B):- monomial(B), !.
last_monomial(A - B, A, N):- monomial(B), monomial_neg(B, N), !.

list_polynomial([M], M).
list_polynomial([M|L], S + M):- monomial_positive_coefficient(M), list_polynomial(L, S), !.
list_polynomial([M|L], S - N):- monomial_neg(M, N), list_polynomial(L, S), !.

polynomial_eq(P1, P2):- polynomial_monomials(P1, M1), monomial_sort(M1, S1), polynomial_monomials(P2, M2), monomial_sort(M2, S1).

polynomial(P):- polynomial_monomials(P, _).

polynomial_neg(P, N):- polynomial_monomials(P, L1), map(monomial_neg, L1, L2), polynomial_list(L2, N).

polynomial_degree(P, D):- polynomial_monomials(P, MS), map(monomial_degree, MS, DS), max(DS, D).

pretty_polynomial_roots([X], (x + XX)):- X < 0, rational_neg(X, XX).
pretty_polynomial_roots([X], (x - X)).
pretty_polynomial_roots([X|L], P*(x + XX)):- X < 0, rational_neg(X, XX), pretty_polynomial_roots(L, P), !.
pretty_polynomial_roots([X|L], P*(x - X)):- pretty_polynomial_roots(L, P), !.

ruffini([_], _, []):- !.
ruffini(CS, [D|_], [D|L]):- ladder_prod(D, 0, CS, RS, 0), last(RS, _, NC), divisors(NC, ND), ruffini(RS, ND, L), !.
ruffini(CS, [_|Ds], L):- ruffini(CS, Ds, L).

% find all the integer roots of the polynomial P.
% this polynomial should have one free term (a constant multiplied by x^0).
integer_roots_polynomial(P, R):-
	polynomial_monomials(P, M), monomial_inv_sort(M, MIS), padded_poly_mons_incr(MIS, PAD_MIS), % extract the padded monomial list of P
	last(PAD_MIS, _, L), monomial_coefficient(L, CF), divisors(CF, DVS), % obtain all the divisors of the free term
	map(monomial_coefficient, PAD_MIS, MCFS), ruffini(MCFS, DVS, R).
