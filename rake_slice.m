function [pavg, pstd] = rake_slice(dsa, npts)
% first number is # of points delivered
% second is # averaged for each point
dsa.acquireData(npts, 1);

% returns the pressure data in p as a 16 x n matrix
% waits until acquisition is done
p = dsa.PressureData;

% row-wise std of p
pstd = std(p,[],2);

% average of the points
pavg = mean(p, 2);

end