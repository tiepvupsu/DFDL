function get_dir(hObject,callbackdata, hh, cl)
    global ext;
    if(cl == 1)
        dir1 = uigetdir(pwd());
        edittext = hh.edittext_dir_1;
        edittext2 = hh.edittext_nimg_1;
        edit_ext = hh.edittext_ext_1;
    else
        dir1 = uigetdir(get(hh.edittext_dir_1, 'String'));
        edittext = hh.edittext_dir_2;
        edittext2 = hh.edittext_nimg_2;
        edit_ext = hh.edittext_ext_2;
    end
    set(edittext, 'String', dir1);
    set(edittext, 'Visible', 'on');

    list_ext = cellstr(['.tif'; '.jpg'; '.png']);

    [flist, ext] = getAllFiles_ext2(dir1, list_ext);
    set(edit_ext, 'String', ext);
    % flist = getAllFiles_ext2(dir1, '.tif');
    n = length(flist);
    set(edittext2, 'Visible', 'on');
    set(edittext2, 'String', strcat('(',num2str(n), ' images)'));
    if (cl == 2)
        set(hh.panel2,'Visible','on');
    	set(hh.panel3,'Visible','on');    
    end
    hh.ext = ext;
end

function [flist, ext] = getAllFiles_ext2(dir1, list_ext)
	flist = [];
	for i = 1: length(list_ext)
		flist_tmp = getAllFiles_ext(dir1, list_ext{i});
		if length(flist_tmp) > length(flist) % select the extension with maximum number of files 
			flist = flist_tmp;
            ext = list_ext{i};
		end
	end
end