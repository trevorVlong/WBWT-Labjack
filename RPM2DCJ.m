function [dCJ,VJ_V,CQ,wing_geom] = RPM2DCJ(RPM,qinf,rho,wing_geom)            
% returns DCJ from RPM data and Vinf data and correlating them with thrust from a qprop model of the Tmotor P40 (or whatever)

    %pull geom from table
    c = wing_geom.c_wing;
    b = wing_geom.b_wing;
    R = wing_geom.R_tip;
    rh = wing_geom.r_hub;
    

    Ad= pi*R^2; %disc area in m^2
    % from dataset
    
    % logic for bad counts
    for rpm_idx = 1:length(RPM)
        if RPM(rpm_idx) < 0
            if rpm_idx > 1 && rpm_idx < length(RPM)
                RPM(rpm_idx) = mean([RPM(rpm_idx-1),RPM(rpm_idx+1)]);
                
                
            elseif rpm_idx == 1
                RPM(rpm_idx) = mean([RPM(rpm_idx+2),RPM(rpm_idx+1)]);
                
                
            elseif rpm_idx == length(RPM)
                RPM(rpm_idx) = mean([RPM(rpm_idx-1),RPM(rpm_idx-2)]);
                
                
            end
        end
    end
    
    %
    Vinf = mean(sqrt(2/rho*qinf));
    
    omega    = RPM*2*pi/60; %get angular velocity
    %lam      = Vinf/(omega*R); %useful for debug
    CT       = CTlambda(RPM,Vinf*ones(length(RPM),1)); %thrust coeff from qprop surface
    Cpd      = 0; %?
    hd       = c*pi*((R/c)^2-(rh/c)^2)*4/(b/c)*sqrt(1-Cpd);%disc height
    Tr       = CT*.5*rho.*(omega'*R).^2*pi*R^2;
    VJ_V     = sqrt(2*Tr./(rho*Ad*Vinf^2)+1); %Vj/Vinf
    CQ       = .5*(1+VJ_V)*hd/c;
    
    for t = 1:length(omega)
        if omega(t)>0
            %dCJ(t)  = hd/c*(VJ_V(t)^2-1)*(1/(VJ_V(t))+1);
            %dCJ(t)  =  hd/c * (1+VJ_V(t)) * (VJ_V(t) - 1/VJ_V(t))
            dCJ(t)  =  2*CQ(t) * (VJ_V(t) - 1/VJ_V(t));
        elseif isnan(omega)
            dCJ(t)         = NaN; %jet velocity excess coefficient
        else
            dCJ(t)         = 0; %jet velocity excess coefficient
        end
    end
    
    % append some geometry values
    wing_geom.hd_c = hd/c;

end