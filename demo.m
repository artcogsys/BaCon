%% Bayesian Connectomics DEMO
addpath utility\;
clear all;
load demodata.mat;
[n,p] = size(X);

%% estimate structural connectivity

prior.a = 1;
prior.b = 4; % expected density = a/(a+b)

%% full distribution

nsamples = 5000;
structuralsamples = zeros(p,p,nsamples);
A = zeros(p);

tic;
for i=1:nsamples
    sample = struct_conn_density_prior(A,N);
    A = sample.A;
    structuralsamples(:,:,i) = A;
end
toc;

A_expectation = squeeze(mean(structuralsamples,3));

figure;
imagesc(A_expectation);
colormap hot;
axis square; colorbar;

%% MAP estimate

nsamples = 100;
A_map = zeros(p);
T = 10;
Tr = .5^(10/nsamples);

tic;
for i=1:nsamples    
    sample_map = struct_conn_density_prior(A_map,N,[],prior, T);
    A_map = sample.A;
    T = T*Tr;
end
toc;

figure;
imagesc(A_map);
colormap hot;
axis square; colorbar;

%% full distribution with edge-wise prior

nsamples = 100;
structuralsamples2 = zeros(p,p,nsamples);
A2 = zeros(p);

%% Here we specify a silly prior that favors intra-hemisphere connections
M = zeros(p);
M(1:34,1:34)   = 1; 
M(35:68,35:68) = 1; 
M(1:34,69:75)  = 1; 
M(69:75,1:34)  = 1; 
M(35:68,76:82) = 1; 
M(76:82,35:68) = 1; 
M(69:75,69:75) = 1; 
M(76:82,76:82) = 1;
M = 0.9*M + 0.1*~M;

tic;
for i=1:nsamples
    sample = struct_conn_edge_prior(A2,N,[],M);
    A2 = sample.A;
    structuralsamples2(:,:,i) = A2;
end
toc;

A2_expectation = squeeze(mean(structuralsamples2,3));

figure;
subplot 121;
imagesc(M);
colormap hot;
axis square; colorbar;
subplot 122;
imagesc(A2_expectation);
colormap hot;
axis square; colorbar;


%% estimate functional connectivity with structural constraint

nsamples = 1000;
functionalsamples = zeros(p,p,nsamples);
S = cov(X);
df = 3 + n;

tic;
for i=1:nsamples
    K = gwishrnd(A_map + eye(p), S, df); % diagonal must be ones
    functionalsamples(:,:,i) = prec2parcor(K);    
end
toc;

R_expectation = squeeze(mean(functionalsamples,3));

figure;
imagesc(R_expectation.*(A_map+eye(p)));
colormap jet;
axis square; colorbar;
caxis([-1 1]);

%% estimate MAP structural connectivity with nonparametric clustering prior

mem = crprnd(log(p),p);
Z = mem2cluster(mem);

Ns = {N};
nsubjects = length(Ns);
As = {};

for i=1:nsubjects
    As{i} = zeros(p);
end

nsamples = 1000;

conn_samples = cell(nsamples,nsubjects);
clust_samples = cell(nsamples,1);
num_clusters = zeros(nsamples,1);

T = 10;
Tr = .5^(10/nsamples);

prior.alpha = log(p);
prior.betap = [1 1]; % [1 1] for uninformative prior, [x y], with x>y for modular clusters
prior.betan = fliplr(prior.betap);

for i=1:nsamples    
    [As, Z] = struct_conn_irm_prior(As, Z, N, {}, prior, T);
    for n=1:nsubjects
        conn_samples{i,n} = As{n}+As{n}';
    end
    clust_samples{i} = Z;
    num_clusters(i) = size(Z,1);
    T = T*Tr;
end


figure;
for s=1:nsubjects
    A = conn_samples{end,s};
    Z = clust_samples{end};
    subplot(1,nsubjects,s);
    plot_clustering(A,Z);  
end

figure;
plot(num_clusters);

%% estimate P(G,K|X)

% cf. example in Lenkoski, A. (2013). 
% A direct sampler for G-Wishart variates. 
% Stat, 2(1), 119�128. doi:10.1002/sta4.23
load fisheriris;
irisv = meas(101:150,:);
[n, p] = size(irisv);
X = irisv - repmat(mean(irisv),[n 1]); % demean
S = X'*X;

nsamples = 1000;

% double reversible jump approach

G = eye(p);
Gsamples = zeros(p,p,nsamples);
Ksamples = zeros(p,p,nsamples);

for i=1:nsamples
    [G,K] = ggm_gwish_drj(G,S,n);
    Gsamples(:,:,i) = G;
    Ksamples(:,:,i) = K;
end

mean(Gsamples,3)

% double continuous-time approach
% NB: each iteration calculates the weight of the *previous* sample!

G = eye(p);
Gsamples = zeros(p,p,nsamples);
Ksamples = zeros(p,p,nsamples);
ws = zeros(nsamples,1);

for i=1:nsamples+1
    [G, K, w] = ggm_gwish_ct(G,S,n);
    Gsamples(:,:,i) = G;
    Ksamples(:,:,i) = K;
    ws(i) = w;
end
Gsamples(:,:,end) = [];
ws(1) = [];

Gmean = zeros(p);

max_w = max(ws);
for i=1:nsamples
    w = exp(ws(i) - max_w);
    Gmean = Gmean + Gsamples(:,:,i) * w;
end
Gmean = Gmean / sum(exp(ws - max_w))


% double conditional Bayes factors approach

G = eye(p);
Gsamples = zeros(p,p,nsamples);
Ksamples = zeros(p,p,nsamples);

for i=1:nsamples
    [G,K] = ggm_gwish_cbf_direct(G,S,n);
    Gsamples(:,:,i) = G;
    Ksamples(:,:,i) = K;
end

mean(Gsamples,3)