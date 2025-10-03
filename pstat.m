
function p = pstat(rho,Vinf,Lam,Gam,x,z)

rsq = x.^2 + z.^2;
u = Lam/(2*pi)*x./rsq + Gam/(2*pi)*z./rsq;
w = Lam/(2*pi)*z./rsq - Gam/(2*pi)*x./rsq;
p = 0.5*rho*(Vinf^2 - (Vinf+u).^2 - w.^2);

