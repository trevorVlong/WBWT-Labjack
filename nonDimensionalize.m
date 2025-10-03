function [corrected2D,uncorrected2D,wing_geom] = nonDimensionalize(runfile,calfile,tarefile,correct)
% this function corrects voltage data to non-dimensional coefficient data based on 
% the tunnel conditions and atmospheric conditions based on "weatherman" the 
% in-built weather system (in progress). Returns a vector of averaged values
%
%
% Summary:
% data a 7 x [N] vector of values from the wind tunnel that has the breakout--
%  1. Lift cell         ----> Cl
%  2. Drag cell         ----> Cx
%  3. Moment cell       ----> Cm
%  4. AoA sensor        ----> degrees
%  5. RPM1              ----> dCj1
%  6. RPM2              ----> dCj2
%  7. RPM3              ----> dCj3
%  8. RPM4              ----> dCj4
% and returns the extra channel
% these all correspond to analog inputs N-1 on the labjack
%
% Mensor ?
%
%
% weather box
% statevars.StaticPressure : static pressure in kPa
% statevars.Temperature    : Temp in celcius
% RelativeHumidity          : % relative humidity
%
%
% Inputs:
% data: a matrix as described above
% calfile: pointer to calibration file
% tarefile: pointer to tare file
% 
%
%% setup =================================================================
    %addpath("C:\Users\longt\Dropbox (MIT)\Tunnel_Data\sum_fall_20\calibrations")
    %addpath("C:\Users\longt\Dropbox (MIT)\Tunnel_Data\sum_fall_20\tares")
    %addpath("C:\Users\longt\Dropbox (MIT)\Tunnel_Data\sum_fall_20\runs")
    
    addpath("/Users/trevorlong/Dropbox (MIT)/Tunnel_Data/sum_fall_20/runs/")
    addpath("/Users/trevorlong/Dropbox (MIT)/Tunnel_Data/sum_fall_20/tares/")
    addpath("/Users/trevorlong/Dropbox (MIT)/Tunnel_Data/sum_fall_20/calibrations/")
% add cal, tare files
    load(calfile,'C')
    load(tarefile)
    load(runfile)
    
    
% pull out data as vectors (to be converted to averaged values later)
    LDMraw          = data(1:3,:);
    alfa          = data (4,:);
    COUNTs         = data(8:11,:);
    Temp            = statevars.Temperature;
    SPressure       = statevars.StaticPressure;
    relHumid        = statevars.RelativeHumidity;
    
    uncorrected2D = table;
    
% constants
    R = 287;
    g = 9.81;
    Mensor_offset = - 0.055;
    Mensor_multiplier = 1.869; %inches of water --> Torr
    %...
    
%----------------------------------------------------------
% wing geometry (switch to datasheet) 17 Sept 2020
    wing_geom = table();
    wing_geom.c_wing = 9 * 0.0254; % meters
    wing_geom.b_wing = 24* 0.0254; % meters
    wing_geom.prop_diam = 5 * 0.0254; % meters
    wing_geom.flap_chord = 3*0.0254; % meters
    wing_geom.prop_pitch = NaN ; % idk
    wing_geom.R_tip = 0.0635; %meters (prop radius)
    wing_geom.r_hub = 0.014; %meters  (hub radius)

    
    
    
%% corrections

%correction factors
%-------------------------------------------------------------------------
    angle_conversion = 360/5; %volts to deg (360 deg ove 5 volt of output
    q_conversion =  2.8035*0.133322*1000; % 2.8035 Volt/Torr x .133322 kPa/Torr
%    alfa0        = 2.0739; %volts

%    alfa0        = 2.0573; %volts
%     alfa0        = -0.0070; %volts
    alfa0        = 2.0196;  %volts


% state variables "statistics" and averaging
%-------------------------------------------------------------------------
% get state and freestream variables
    Temp_std     = std(Temp); % C
    Temp         = mean(Temp)+272; % C
    pambient_std = std(SPressure)*100; % pascals
    pambient     = mean(SPressure)*100; %pascals
    % no statistics b/c is dual distribution of other two
    rho          = pambient / ((Temp) * R); %kg/m^3
    
% add to data table
    uncorrected2D.Temp = Temp;
    uncorrected2D.Temp_std = Temp_std;
    uncorrected2D.pambient_std = pambient_std;
    uncorrected2D.pambient = pambient;
    uncorrected2D.rho = rho;
    
% Tunnel and Wing Conditions
%-------------------------------------------------------------------------
    % for debug
    
    % as forces
    LDM   = C*(LDMraw-tarevec(1:3))*g;% convert voltages to forces
    %alfa0 = cal_alfa; % get 0 AoA during calibration of wing
    
    
    % Labjack Values
    tunnelq_raw = 133.322*Mensor_multiplier*(tunnelq+Mensor_offset);
    tunnelq_std = std(tunnelq_raw);
    tunnelq = double(mean(tunnelq_raw)); % corrected down 10% while I figure out how to make q more accurate 
% add to data table  
    uncorrected2D.tunnelq           = tunnelq;
    uncorrected2D.tunnelq_std       = tunnelq_std;
    uncorrected2D.Vinf_measured     = sqrt(2*mean(tunnelq)/rho);
    
    uncorrected2D.alfa_std          = std(alfa-alfa0)*angle_conversion;
    uncorrected2D.alfa              = (alfa-alfa0)*angle_conversion;
    
    uncorrected2D.Fz = mean(LDM(1,:));
    uncorrected2D.Fx = mean(LDM(2,:));
    
    
    % Dimensionless quantities
    %-------------------------------------------------------------------------
    % convert to coefficients

    cl     = (LDM(1,:)./ (tunnelq * wing_geom.c_wing*wing_geom.b_wing));
    cx     = (LDM(2,:)./ (tunnelq * wing_geom.c_wing*wing_geom.b_wing));
    cm     = LDM(3,:)./ (tunnelq * wing_geom.c_wing^2*wing_geom.b_wing);


    
    
    
    % motor coefficients
    udCJs = [];
    cdCJs = [];
    RPMs  = [];
    VJ_V  = [];
    uCQ   = [];
    for motor = 1:4
        RPMs(motor,:) = count2RPM(COUNTs(motor,:),100);
        [udCJs(motor,:),VJ_V(motor,:),CQ(motor,:),wing_geom] = RPM2DCJ(RPMs(motor,:),tunnelq,rho,wing_geom);
        cdCJs(motor,:) = RPM2DCJ(RPMs(motor,:),tunnelq,rho,wing_geom);
    end
    
% add to data table

    uncorrected2D.cl_average = mean(cl);
    uncorrected2D.cl_std     = std(cl);
    uncorrected2D.cx_average = mean(cx);
    uncorrected2D.cx_std     = std(cx);
    uncorrected2D.cm_average = mean(cm);
    uncorrected2D.cm_std     = std(cm);
    
    uncorrected2D.rpm1 = RPMs(1,:);
    uncorrected2D.rpm2 = RPMs(2,:);
    uncorrected2D.rpm3 = RPMs(3,:);
    uncorrected2D.rpm4 = RPMs(4,:);
    
    uncorrected2D.dCJ1 = udCJs(1,:);
    uncorrected2D.dCJ2 = udCJs(2,:);
    uncorrected2D.dCJ3 = udCJs(3,:);
    uncorrected2D.dCJ4 = udCJs(4,:);
    uncorrected2D.uCQ    = mean(CQ,1);
    uncorrected2D.dCJ  = mean(udCJs(1:4,:),1);
    uncorrected2D.flap = flap_ang;
    
    
    
%% correction and corrected table =========================================


% run corrections
%------------------------------------------------------------------------- 
    try
        corrected2D = twall(uncorrected2D,walldata);


% corrected data table
%------------------------------------------------------------------------- 
        corrected2D.alfa    = mean(uncorrected2D.alfa);
        corrected2D.tunnelq = .5*rho*corrected2D.Vinf^2;
        corrected2D.Vinf_measured = uncorrected2D.Vinf_measured;


        corrected2D.rpm1 = RPMs(1,:);
        corrected2D.rpm2 = RPMs(2,:);
        corrected2D.rpm3 = RPMs(3,:);
        corrected2D.rpm4 = RPMs(4,:);

        corrected2D.dCJ1 = cdCJs(1,:);
        corrected2D.dCJ2 = cdCJs(2,:);
        corrected2D.dCJ3 = cdCJs(3,:);
        corrected2D.dCJ4 = cdCJs(4,:);
        corrected2D.dCJ  = mean(cdCJs(1:4,:),1);
        corrected2D.CQ  = mean(CQ,1);
        corrected2D.VJ_V = mean(VJ_V);


        corrected2D.cl_std = uncorrected2D.cl_std;
        corrected2D.cx_std = uncorrected2D.cx_std;
        corrected2D.cm_std = uncorrected2D.cm_std; 
        corrected2D.cm_average = uncorrected2D.cm_average;

        corrected2D.Temp            = uncorrected2D.Temp;
        corrected2D.rho             = uncorrected2D.rho;
        corrected2D.static_pressure = uncorrected2D.pambient;
        corrected2D.flap            = flap_ang;

    catch
        warning('problem in corrected table')
    end
end