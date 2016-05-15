function [flist1_train, flist1_test, flist2_train, flist2_test] = pickTrainingImgs(pars)
	n1 = length(pars.flist1);
	n2 = length(pars.flist2);
	idx1 = randperm(n1); 
	idx2 = randperm(n2);	
	for i = 1 : n1 
		if(i <= pars.nTrainingImages)
			flist1_train{i} = pars.flist1{idx1(i)};
		else 
			flist1_test{i - pars.nTrainingImages} = pars.flist1{idx1(i)};
		end
	end
	for i = 1 : n2 
		if(i <= pars.nTrainingImages)
			flist2_train{i} = pars.flist2{idx2(i)};
		else 
			flist2_test{i - pars.nTrainingImages} = pars.flist2{idx2(i)};
		end
	end
end 

