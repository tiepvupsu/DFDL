function DFDL_main(pars)
	%%%%%%%%%%%%%%%%%%%%%%%% Description %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% DFDL_main: Run the procedure described in section III-C1 in our TMI paper
	% INPUT:
	%	1) pars : structure of parameters selected in GUI, see init_pars.m for more info
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	%% ========= Step 0. Initialization parameters ==============================	
    % pars
	pars.K              = pars.dictsize*ones(1,2); % pars.K: array indicating #bases of each class
	pars.max_iter       = 50;	% number of maximum iterations in the main DFDL
	pars.lambda         = 0.1;  % lambda for ODL, see TMI paper
	pars.gamma          = 0.1;	% gamma for SRC, see TMI paper  
	% --------------- OMP pars for mexOMP - see SPAMS document for info--------------------
	% http://spams-devel.gforge.inria.fr/doc/html/index.html
	paramOMP.eps        = 1e-5;
	paramOMP.numThreads = -1;  
	pars.paramOMP       = paramOMP;

	%% ========= Step 1 ==============================	
	fprintf('Step 1.1. Building patches...\n');
	[X, label]          = color_buildPatches(pars);	% buding training patches
	fprintf('done\n');
	Y = normc(double(X)); 	% normalize training patches before training
	pars.C = [sum(label == 1) sum(label == 2)]; % number of actual training patches each class
	%% ========= 1.2 Train dictionaries ==============================
	fprintf('Step 1.2. Training dictionaries...\n');
	[Model, pars] = DFDL(Y, pars);	% Run the main DFDL
	D1    = Model.Dict(:,:,1);
	D2    = Model.Dict(:,:,2);
	% --------------- display example bases from each dictionary -------------------------
	drawnow;
	figure(2);	
	subplot(1,2,1); displayPatches(D1(:, 1: min(100, pars.dictsize))); title('Example bases from class 1');
	subplot(1,2,2); displayPatches(D2(:, 1: min(100, pars.dictsize))); title('Example bases from class 2');
	%% ========= 2.1. Find proportional of healthy patches (training images) ==============================
	fprintf('Step 2. Find threshod theta\n')
	ftr1 = zeros(1, pars.nTrainingImages);
	ftr2 = zeros(1, pars.nTrainingImages);
	trainlabel = [ones(size(ftr1)) 2*ones(size(ftr2))];
	for i = 1: pars.nTrainingImages
		filename = pars.flist1{pars.train_img_ids1(i)};
		feature = DFDLonImage(Model, pars, filename);
		fprintf('id = %3d, filename = %41s, feature = %6f\n', i, filename(end - 25:end), feature);
		ftr1(i) = feature;
	end
	fprintf('Class 2...\n');
	for i = 1: pars.nTrainingImages
		filename = pars.flist2{pars.train_img_ids2(i)};
		feature = DFDLonImage(Model, pars, filename);
		fprintf('id = %3d, filename = %41s, feature = %6f\n', i, filename(end - 25:end), feature);
		ftr2(i) = feature;
	end
	%% ========= 2.2. Finding the threshold ==============================
	F               = [ftr1 ftr2];
	[thresh, signH] = thrsh_roc_2(F, trainlabel);
	fprintf('Threshold = %f\n', thresh);
	%% ========= 3. Testing ==============================		
	fprintf('Step 3. Test')
	fprintf('Class 1 - test...\n');
	ftest1 = zeros(1, numel(pars.test_img_ids1));
	ftest2 = zeros(1, numel(pars.test_img_ids2));
	for i = 1: numel(pars.test_img_ids1)
		filename  = pars.flist1{pars.test_img_ids1(i)};
		feature   = DFDLonImage(Model, pars, filename);
		ftest1(i) = feature;
		pred1(i)  = -0.5*signH*(2*(feature > thresh) -1) + 1.5;
		fprintf('id = %3d, filename = %41s, feature = %6f, class = %d\n', i, filename(end - 25:end), feature, pred1(i));
	end
	fprintf('Class 2 - test...\n');
	for i = 1:  numel(pars.test_img_ids2)
		filename  = pars.flist2{pars.test_img_ids2(i)};
		feature   = DFDLonImage(Model, pars, filename);
		ftest2(i) = feature;
		pred2(i)  = -0.5*signH*(2*(feature > thresh) -1) + 1.5;
		fprintf('id = %3d, filename = %41s, feature = %6f, class = %d\n', i, filename(end - 25:end), feature, pred2(i));
	end
	%% ========= Report results ==============================
	acc1 = sum(pred1 == 1)/numel(pred1);
	acc2 = sum(pred2 == 2)/numel(pred2);
	acc = (sum(pred1 == 1) + sum(pred2 == 2))/numel([pred1 pred2]);
	fprintf('Accuracy: \n');
	fprintf('--------------------------------------\n');
	fprintf('| Class 1    | Class 2   | Overall   |\n')
	fprintf('--------------------------------------\n');
	fprintf('| %4f  | %4f | %4f |\n', 100*acc1, 100*acc2, 100*acc);
	fprintf('--------------------------------------\n');
	%% ========= ROC curve ==============================
	[FAR, MR] = DFDL_ROC(ftest1, ftest2);
	figure(3);
	plot(FAR, MR, 'bx-'); axis equal;
	hold on;
	plot(1-acc1, 1 - acc2, 'xr');
	title('Receiver Operating Characteristic curve');
	xlabel('Probability of false alarm');
	ylabel('Probability of miss');
	axis([0 1 0 1]);
	% pars
end

function feature = DFDLonImage(Model, pars, img)
	%% ========= 1. Build non-overlapping patches ==============================
	X = buildNonOverlappingPatches(pars, img);
	Y = normc(double(X));
	%% ========= SRC ==============================	
	D1                = Model.Dict(:,:,1);
	D2                = Model.Dict(:,:,2);	
	dictsize          = pars.dictsize;
	paramLasso.lambda = pars.gamma;
	paramLasso.eps    = 1e-5;
	D                 = [D1 D2];
	S                 = mexLasso(Y, D, paramLasso);
	S1                = S(1:dictsize,:);
	S2                = S(dictsize+1:end,:);
	R1                = Y - D1*S1;
	R2                = Y - D2*S2;
	e                 = [	sum(R1.^R1); sum(R2.^R2)];
	[~, pred]         = min(e);
	feature           = sum(pred == 1)/numel(pred);
end

function X = buildNonOverlappingPatches(pars, img)
	p       = pars.patchSize;
	F       = imread(img);
	F       = imresize(F, pars.imresize_ratio);
	[h,w,~] = size(F);
	F       = F(1:p*floor(h/p), 1: p*floor(w/p),:);
	X1      = im2col(F(:,:,1), [p p], 'distinct');
	X2      = im2col(F(:,:,2), [p p], 'distinct');
	X3      = im2col(F(:,:,3), [p p], 'distinct');
	X       = [X1; X2; X3];
end

function [FAR, MR] = DFDL_ROC(ftest1, ftest2)
	N1      = numel(ftest1);
	N2      = numel(ftest2);
	Npoints = 100;
	MR      = zeros(Npoints, 1); % miss rate
	F       = zeros(Npoints, 1); % false alarm rate
	for i = 1:Npoints
		th     = (i)/Npoints;
		acc1   = sum(ftest1 < th)/N1;
		acc2   = sum(ftest2 >= th)/N2;
		MR(i)  = 1 - acc2;
		FAR(i) = 1 - acc1;
	end
end

