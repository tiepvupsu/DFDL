function viewPatches(pars, hh)  
	set(hh.axes1, 'Visible', 'off');
	set(hh.axes2, 'Visible', 'off');
	set(hh.panel4, 'Visible', 'on');
	set(hh.text_wait, 'Visible', 'on');
	drawnow; 
	fprintf('Building patches...');
	[X, label]          = color_buildPatches(pars);
	fprintf('done\n');
	set(hh.text_wait, 'Visible', 'off');
	set(hh.axes1, 'Visible', 'on');
	set(hh.axes2, 'Visible', 'on');
	drawnow;
	axes(hh.axes1);
	displayPatches(X(:, label == 1));
	axes(hh.axes2);
	displayPatches(X(:, label == 2));  
end