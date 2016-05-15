function pars = init_pars(pars, hh)
	ext1                 = get(hh.edittext_ext_1, 'String');		% extension of images in dataset
	ext2                 = get(hh.edittext_ext_2, 'String');
	pars.flist1          = getAllFiles_ext(get(hh.edittext_dir_1, 'String'), ext1); %get all filenames with extention = ext
	pars.flist2          = getAllFiles_ext(get(hh.edittext_dir_2, 'String'), ext2);
	pars.nTrainingImages = str2num(get(hh.edittext_ntrain, 'String')); % get number of training images per class
	pars.nTestImages1    = str2num(get(hh.edittext_ntest1,'String')); % get number of test images per class
	pars.nTestImages2    = str2num(get(hh.edittext_ntest2,'String'));
	pars.patchSize       = str2num(get(hh.edittext_patchsize, 'String')); % size(pixel) of training patches
	pars.numPatches      = str2num(get(hh.edittext_train_ptchs, 'String')); %number of patches per class for training
	pars.dictsize        = str2num(get(hh.edittext_train_bases, 'String')); %#bases in each class
	pars.rho             = str2double(get(hh.edittext_rho, 'String')); % parameter rho in the paper
	N1                   = length(pars.flist1);  	% #file in parsflist1
	% --------------- % randomly choosing images for training and test -------------------------
	mixid                = randperm(N1); 			
	pars.train_img_ids1  = mixid(1:pars.nTrainingImages); 
	pars.test_img_ids1   = mixid(pars.nTrainingImages+1: pars.nTrainingImages + pars.nTestImages1);
	N2                   = length(pars.flist2); 
	mixid                = randperm(N2); 
	pars.train_img_ids2  = mixid(1:pars.nTrainingImages); 
	pars.test_img_ids2   = mixid(pars.nTrainingImages+1: pars.nTrainingImages + pars.nTestImages2);
	% --------------- resize ratio -------------------------
    pars.imresize_ratio  = str2double(get(hh.imresize, 'String'));
end 