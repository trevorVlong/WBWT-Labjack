function [u1 u2 w1 w2 phi1 phi2 psi1 psi2] = vorlin(x,z,xp1,zp1,xp2,zp2)

% Computes velocities u,w,phi,psi at field point x,z of a linear unit-strength 
% vortex panel (+ clockwise) with endpoints xp1,zp1 and xp2,zp2
%
% vortex sheet strength is linear over panel, from gam1 to gam2:
%
%    gam(t) = gam1*(1-t) + gam2*t    ,  t = 0 .. 1
%
% velocity at (x,z) is:   
%
%    u = u1*gam1 + u2*gam2
%    w = w1*gam1 + w2*gam2
%

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
phic = x2.*t2 - x1.*t1 + zz.*(g2-g1);
psic = x1.*g1 - x2.*g2 + zz.*(t2-t1);

phil = x1.*phic + 0.5*(rsq1.*t1 - rsq2.*t2) + 0.5*zz*ds;
psil = x1.*psic - 0.5*(rsq1.*g1 - rsq2.*g2) - 0.5*x1*ds;

phi1 = (phic - phil/ds)/(2*pi);
psi1 = (psic - psil/ds)/(2*pi);

phi2 = (       phil/ds)/(2*pi);
psi2 = (       psil/ds)/(2*pi);


% velocities in panel-aligned axes
ubc = t2-t1;
wbc = g2-g1;

ubl = x1*(t2-t1) + zz*(g2-g1);
wbl = x1*(g2-g1) - zz*(t2-t1) + ds;

ub1 = (uc - ul/ds)/(2*pi);
wb1 = (wc - wl/ds)/(2*pi);

ub2 = (     ul/ds)/(2*pi);
wb2 = (     wl/ds)/(2*pi);

% rotate velocities to input axes
u1 = ub1.*sx - wb1.*sz;
w1 = ub1.*sz + wb1.*sx;

u2 = ub2.*sx - wb2.*sz;
w2 = ub2.*sz + wb2.*sx;

