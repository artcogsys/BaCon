function [A,P] = struct_conn_density_prior(A0, N, structparam, priorparam, T)
% MCMC-Metropolis sampler for structural connectivity based on a Dirichlet
% compund multinomial distribution, as described in [1], together with a
% stochastic prior on the probability of an edge. 
%
% Mandatory parameters: 
%       A0: previous state of connectivity
%       N: streamline count matrix (N_ij = count from i to j)
%
% Optional parameters:
%       structparam.ap, .an: Dirichlet distribution hyperparameters
%       corresponding to a true or a false edge, respectively.
%       priorparam.a, .b: Beta distribution hyperparameters determining the
%       probability of an edge.
%       T: temperature at which to sample (T=1: true distribution). Used in
%       simulated annealing.
%
% References:
%
% [1] Hinne, M., Heskes, T., Beckmann, C.F., & van Gerven, M.AJ. (2013).
% Bayesian inference of structural brain networks. NeuroImage, 66C,
% 543�552.
%
% Last modified: April 8th, 2014


if nargin <= 3 || isempty(structparam)
    ap = 1;
    an = 0.1;
else
    ap = structparam.ap;
    an = structparam.an;
end

if nargin <= 4 || isempty(priorparam)
    a = 1;
    b = 1;
else
    a = priorparam.a;
    b = priorparam.b;
end

if nargin < 5 || isempty(T)
    T = 1;
end

A = A0;
P = 0;
n = length(A);

linidx = find(triu(ones(n),1));
E = length(linidx);
for e=linidx(randperm(E))'
    Aprop = A;
    [i, j] = ind2sub([n n], e);
    Aprop(i,j) = 1 - A(i,j);
    Aprop(j,i) = 1 - A(j,i);

    dL = delta_log_dcm(N, ap, an, i, j, Aprop, A);    
    dP = (1 - 2 * Aprop(i,j)) * log( a /  b);

    alpha = dL + dP;
    
    if rand <= min(1,exp(alpha)^(1/T))
        A = Aprop;
        P = P + alpha;    
    end     
end