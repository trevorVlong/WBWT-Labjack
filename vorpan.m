function [u w phi psi] = vorpan(x,z,xp1,zp1,xp2,zp2)

% Computes velocities u,w,phi,psi at field point x,z of a constant unit-strength 
% vortex panel (+ clockwise) with endpoints xp1,zp1 and xp2,zp2

ds = sqrt((xp2-xp1).^2 + (zp2-zp1).^2);

% unit vector along panel
sx = (xp2-xp1)./ds;
sz = (zp2-zp1)./ds;

% field point in panel-aligned axes
x1 = (x-xp1).*sx + (z-zp1).*sz;
x2 = x1 - ds;
zz = (z-zp1).*sx - (x-xp1).*sz;

rsq1 = x1.^2 + zz.^2;
rsq2 = x2.^2 + zz.^2;

g1 = 0.5*log(rsq1);
g2 = 0.5*log(rsq2);
t1 = atan2( zz , x1 );
t2 = atan2( zz , x2 );

% potential and streamfunction
phi = (x2.*t2 - x1.*t1 + zz.*(g2-g1))/(2*pi);
psi = (x1.*g1 - x2.*g2 + zz.*(t2-t1))/(2*pi);

% velocities in panel-aligned axes
ub = (t2-t1)/(2*pi);
wb = (g2-g1)/(2*pi);

% rotate velocities to input axes
u = ub.*sx - wb.*sz;
w = ub.*sz + wb.*sx;

