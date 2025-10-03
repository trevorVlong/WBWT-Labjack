function [u w phi psi] = vortex(x,z,xp,zp)

% Computes velocities u,w,phi,psi at field point x,z of a unit-strength vortex at xp,zp

rsq = (x-xp).^2 + (z-zp).^2;

u =  (z-zp)./(2*pi*rsq);
w = -(x-xp)./(2*pi*rsq);

phi = -atan2( z-zp , x-xp )/(2*pi);
psi = 0.5*log(rsq)/(2*pi);

