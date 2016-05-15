function [Model, pars] = DFDL(Y, pars)	
	%%%%%%%%%%%%%%%%%%%% Description %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% Given training data Y and parameters pars, learn L and dictionaries
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	cumK = [0 cumsum(pars.K)];
	cumC = [0 cumsum(pars.C)];	
    rho = pars.rho;
    C = pars.C;
    paramOMP = pars.paramOMP;
	numClasses = numel(pars.K);
	% --------------- initial dicts -------------------------
    K = pars.dictsize;
	D = [];
	L = zeros(numClasses, 1);
	for i = 1: numClasses
		Yi = Y(:, cumC(i) + 1: cumC(i+1));
		ids = randperm(size(Yi,2));
		D(:,:,i) = Yi(:, ids(1:K));
		fprintf('Calculating L for class %d:...\n', i);
		[D(:,:,i), L(i)] = findL(D(:,:,i), Yi, K, pars.lambda);		
		fprintf('Choose L%d = %d\n', i, L(i));
    end	
    pars.L = L;
	% ----------------------------------------
	iter = 1;
	N = size(Y,2);
	printheader(numClasses);
	tic
	while iter <= pars.max_iter
		fprintf('|   %3d/%d    |',iter, pars.max_iter);
		for j = 1: numClasses
			%% ========= Sparse coding step ==============================
			Dj = D(:,:,j);
			paramOMP.L = L(j);
			S = mexOMP(Y, Dj, paramOMP);
			%% ========= Dictionary update step ==============================
			rangei 		= (cumC(j) + 1): cumC(j+1);
			range_bari 	= setdiff(1:N, rangei);
			Xi 			= Y(:, rangei); Xibar = Y(:, range_bari);
			Si 			= S(:, rangei); Sibar = S(:, range_bari);
			Ni 			= C(j)	 ; Nibar = N - Ni;
			A 			= Si*Si'/Ni    ; B = Sibar*Sibar'/Nibar;
           	F 			= A - rho*B;
            F2 			= F - min(eig(F))*eye(size(F,1));
	        E 			= Xi*Si'/Ni - rho*Xibar*Sibar'/Nibar;
			% % --------------- Update Dj -------------------------
            Dj 			= updateD(Dj, E, F2);
            cost = 1/Ni*norm(Xi - Dj*Si,'fro')^2 - rho/Nibar*norm(Xibar - Dj*Sibar,'fro')^2;
            D(:,:,j) = Dj;
            fprintf(' %5f  |', cost );
        end
        t = toc;
        t = t*(pars.max_iter - iter)/iter;
        time_estimate(t);
        iter = iter + 1;
    end
    fprintf('-----------------------------------------------------------------\n');
	Model.Dict = D;
    Model.paramOMP = paramOMP;
end

function Dj = getDj(D, j, cumK)
    range = cumK(j) + 1: cumK(j+1); 
	Dj = D(:, range);
end

function D = updateD(D, E, F)
	Dnew = zeros(size(D));
	cost_new = -2*trace(E*D') + trace(D*F*D');
	cost_old = cost_new + 100;
	max_iter = 200;
	iter = 0;
	while (abs(cost_old - cost_new) > 1e-10 & iter < max_iter)
    	cost_old = cost_new;
		for j0 = 1: size(D,2)
	        if(F(j0,j0) ~= 0)
	            a = 1/F(j0,j0) * (E(:,j0) - D*F(:, j0)) + D(:,j0);
	            D(:,j0) = a/(max( norm(a,2),1));
	        else
	            D(:,j0) = D(:,j0);
	        end
	    end	   
	    cost_new = -2*trace(E*D') + trace(D*F*D');
	    iter = iter + 1;
	end
end

function [D, L] = findL(D, Y, K, lambda);
	%% ================== block: Pick randomly 75% of pathces for learning ==========================
	N = size(Y,2);
	p = randperm(N);
	N2 = round(0.75*N);
	Xtrain = Y(:, p(1:N2));
	Xtest = Y;%(:, p(N2+1:end));
	Y = Xtrain;
	%% ------------------end of block: Pick randomly 2000 pathces for learn ----------------------------
	iter = 1;
	max_iter = 20 ;
	% --------------- pars for Lasso - see SPAMS documentation -------------------------
	param.lambda = lambda;
    param.lambda2 = 0;
	param.numThreads = -1; % number of processors/cores to use; the default choice is -1
							% and uses all the cores of the machine
	param.mode = 2; % penalized formulation
	fprintf('------------------------------------------------------\n');	
	fprintf('|iter/max_iter| average(L) | estimated remaining time|\n');
	fprintf('------------------------------------------------------\n');
	tic
	while(iter <= max_iter)
		% --------------- sparse coding -------------------------		
		S = mexLasso(Y, D, param);
		% --------------- dictionary update -------------------------
		E = Y*S';
		F = S*S';
		D = updateD(D,E,F);		
		% --------------- estimate remaining time -------------------------
		t = toc;
		t = t*(max_iter - iter)/iter;
		L = sum(vec(S~=0))/size(S,2);
		fprintf('|    %2d/%d    |  %8.4f  |', iter, max_iter, full(L));
		time_estimate(t); % convert t(seconds) to hour/minute/second
		iter = iter + 1;
	end
	fprintf('------------------------------------------------------\n');
	Y = Xtest;
	S = mexLasso(Y, D, param);
	L =  round(sum(vec(S ~= 0)) / size(S, 2));
end

function time_estimate(t)
	t = round(t);
	h = floor(t/3600);
	t = t - 3600*h;
	m = floor(t/60);
	t = t - m*60;
	fprintf('      %2dh%2dm%2ds          |\n', h, m, t);
end

function printheader(numClasses)
	fprintf('Main DFDL...\n');	
	fprintf('-----------------------------------------------------------------\n');	
	fprintf('|iter/max_iter|');
	for i = 1: numClasses
		fprintf('  cost %d   |', i);
    end
    fprintf('estimated remaining time |\n');
	fprintf('-----------------------------------------------------------------\n');
end
