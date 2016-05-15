function [X, label] = color_buildPatches(pars)
	fprintf('Class 1...');
	[X1] = buildPatches_class(pars, pars.flist1, pars.train_img_ids1);
	fprintf('done\nClass 2...');
	[X2] = buildPatches_class(pars, pars.flist2, pars.train_img_ids2);
	fprintf('done\n');
	X = [X1 X2]; X = double(X);
	label = [ones(1, size(X1,2)) 2*ones(1, size(X2,2))];
end

function [X] = buildPatches_class(pars, flist, ids)
	numFiles = numel(ids);
	patchSize = pars.patchSize;
	ratio = pars.imresize_ratio;
	% --------------- calculate pro -------------------------
	% area = zeros(1, numFiles);
	% for i = 1: numFiles
	% 	img = imread(flist{ids(i)});
	% 	sz = size(img);
	% 	area(i) = sz(1) * sz(2);
	% end
	% patchesPerFile = round(pars.numPatches*area/sum(area));
	patchesPerFile = round(pars.numPatches/numFiles);
	idpatch = 1;
	Npatches = patchesPerFile*numFiles;

    X1 = zeros(patchSize^2, Npatches);
    X2 = zeros(patchSize^2, Npatches);
    X3 = zeros(patchSize^2, Npatches);
    for i = 1: numFiles
        img = imread(flist{ids(i)});
        img = imresize(img, ratio);
        [h, w, ~] = size(img);
        if( h < patchSize || w < patchSize)
            continue;
        end
        for j = 1: patchesPerFile
			top = randi(h - patchSize + 1);
            left = randi(w - patchSize + 1);
            rows = top: top + patchSize - 1;
            cols = left : left + patchSize - 1;
            imdata_patch = img(rows, cols, 1); X1(:,idpatch) = imdata_patch(:);
            imdata_patch = img(rows, cols, 2); X2(:,idpatch) = imdata_patch(:);
            imdata_patch = img(rows, cols, 3); X3(:,idpatch) = imdata_patch(:);
            idpatch = idpatch + 1;
            if mod(idpatch, 1000) == 0
            	fprintf('%d/%d...', idpatch, Npatches);
            end
        end
	end
	X = [X1; X2; X3];
end
	

