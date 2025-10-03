function [u w phi psi] = source(x,z,xp,zp)

% Computes velocities u,w,phi,psi at field point x,z of a unit-strength source at xp,zp

rsq = (x-xp).^2 + (z-zp).^2;

u =  (x-xp)./(2*pi*rsq);
w =  (z-zp)./(2*pi*rsq);

phi = 0.5*log(rsq)/(2*pi);
psi = atan2( z-zp , x-xp )/(2*pi);
