%setup WBWT 
addpath("C:\Users\longt\Documents\mit-git\toolbox\toolbox\aawind\aawind");
addpath("C:/Users/longt/Documents/mit-git/UI/tools");

%v = aawind.Velmex('COM7');

% example for setting up a (square) grid
xpts = linspace(0,10,11);
ypts = linspace(0,2,3);

[a,b] = meshgrid(xpts,ypts);
positions = [a(:),b(:)];

% scanivalve setup

% set origin
% v.setOrigin

% absolute move (in inches)
% v.absoluteMove([1,0,0]) 


