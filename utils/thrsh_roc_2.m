function [thresh, signH] = thrsh_roc_2(X_train, trainLabel)
    % trainLabel = 1 or -1;
    % find the best thresh for X_train with two classes, 1 dimension
    % return the best thresh and sign of samples from class 1
    thr_min = min(X_train);
    thr_max = max(X_train);
    step = (thr_max - thr_min)/1000;
    acc = [];
    k = 0;
    h = [];
    for thr = thr_min + step : step:  thr_max - step
        k = k + 1;
        h1 = sum(X_train(find(trainLabel == 1)) > thr) - sum(X_train(find(trainLabel ~=1)) > thr);
        h1 = h1/numel(X_train);
        h = [h h1];
    end
    [accmax, idmax] = max(abs(h));
    maxindex = find(abs(h) == accmax);
    medmax = median(maxindex);

    [~,iid] = min(abs(maxindex - medmax));
    idmax = maxindex(iid);

    thresh = thr_min + (medmax)*step;

    signH = sign(h(idmax));
end