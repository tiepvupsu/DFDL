function A2 = normc2(A) 
    s = sqrt(sum(A.^2));
    B = repmat(s, size(A,1), 1);
    A2 = A./B;
end 