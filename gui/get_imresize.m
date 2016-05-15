function get_imresize(hObject,~, hh, pars)    
    val = get(hObject, 'Value');
    set(hh.imresize , 'string', num2str(val));
	pars = init_pars(pars, hh);	
	pars.imresize_ratio = val;    
    display(pars)
    viewPatches(pars, hh);
end