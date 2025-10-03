% Generates interpolant structures for Qprop data

%% Qprop data
% 
%import data
[V,rpm,Dbeta,T,Q,Pshaft,Volts,Amps,effmot,effprop,adv,ct,CP,DV,eff,Pelec,Pprop,clavg,cdavg] = QPimport('F40.txt');
% N1       = 11; %number of velocity inputs per RPM step
% N2       = 26; %number of rpm steps
% 
% %reshape relevant paramters
% rs      = [N1,N2];
% Vmat    = reshape(V,rs)'; %matrix then transpose for scattered interp
% ctmat   = reshape(ct,rs)';
% rpmmat  = reshape(rpm,rs)';
% advmat  = reshape(adv,rs)';

%create interpolant struct and save
ctVadv  = scatteredInterpolant(adv,V,ct);
ctVrpm  = scatteredInterpolant(rpm,V,ct);

save('ctinterp2.mat','ctVadv','ctVrpm')