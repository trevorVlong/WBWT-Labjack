function [u w phi psi] = srcpan(x,z,xp1,zp1,xp2,zp2)

% Computes velocities u,w,phi,psi at field point x,z of a constant-strength 
% source panel with endpoints xp1,zp1 and xp2,zp2

ds = sqrt((xp2-xp1).^2 + (zp2-zp1).^2);

% unit vector along panel
sx = (xp2-xp1)./ds;
sz = (zp2-zp1)./ds;

% field point in panel-aligned axes
x1 = (x-xp1).*sx + (z-zp1).*sz;
x2 = x1 - ds;
zz = (z-zp1).*sx - (x-xp1).*sz;

g1 = 0.5*log(x1.^2 + zz.^2);
g2 = 0.5*log(x2.^2 + zz.^2);
t1 = atan2( zz , x1 );
t2 = atan2( zz , x2 );

% velocities in panel-aligned axes
us = (t2-t1)/(2*pi);
ws = (g1-g2)/(2*pi);

% rotate velocities to original axes
u = us.*sx - ws.*sz;
w = us.*sz + ws.*sx;

% potential and streamfunction
phi =   x1.*g1 - x2.*g2 + zz.*(t2-t1);
psi = -(x2.*t2 - x1.*t1 + zz.*(g2-g1));

