function [outputArg1,outputArg2] = motorTest(labjack,weather,calnumber,tarenumber,runnumber,PWMvec)
%
%   Detailed explanation goes here

%--------------------------------------------------------------------------   
% set up directories
    savedirectory = "C:\Users\longt\Dropbox (MIT)\Tunnel_Data\spring21\motormaps";
    rundirectory  = sprintf("%s\\runs",savedirectory);
    taredirectory = sprintf("%s\\tares", savedirectory);
    caldirectory  = sprintf("%s\\calibrations",savedirectory);
    tarefile      = sprintf("tare%03.0f.mat",tarenum);
    calfile       = sprintf("cal%02.0f.mat",calnum);
    addpath(rundirectory);
    addpath(taredirectory);
    addpath(caldirectory);
    load(calfile,'calX');
    load(tarefile,'tareX');

    
%--------------------------------------------------------------------------       
    % motor information
    dprop = 5; %inches
    Aprop = pi*(d/2)^2;
    motorName = "F40ProII1600KV";
    
%--------------------------------------------------------------------------       
    % setup labjack
    labjack.setupPWMout();
    labjack.motorMapSetup(); % set up for motor map
    labjack.scanRate = 100; %Hz
    labjack.scanTime = 5; %seconds
    
%--------------------------------------------------------------------------    
    %loop through each PWM signal strength, recording at each step
    data = cell(length(PWMvec),1);
    avgdata = cell(length(PWMvec),1);
    
    for Npwm = 1:length(PWMvec)
        
        weather.startRecording; % start gathering state vars
        % change motor speed
        labjack.changePWMout(PWMvec(Npwm));
        
        % record data and save raw and average
        data{Npwm} = labjack.recordData2();
        statevars = weather.stopRecording;
        
        
        avg = mean(data{PWM},2);
        % channel 1: dynamic pressure in torr
        % channel 2: X-force in volts (requires tare and calibration)
        % channel 3: RPM pulses out (divide by 8 for F40 pro II)
        
        
%--------------------------------------------------------------------------            
        % In situ data correction for real-time head's up
        % 
        R = 287;
        Temp            = mean(statevars.Temperature + 272); % ˚C 
        pambient        = mean(statevars.StaticPressure)*100; %Pascals
        relHumid        = mean(statevars.RelativeHumidity); %???
        rho             = pambient / ((Temp) * R); %kg/m^3
        
        qinf = 133.22 * avg(1); % torr to Pascals
        Vinf = sqrt(2*qinf/rho);
        Xforce = (avg(2)-tareX)*calX * 9.81; % volts to N
        
        % motor to RPM/lambda
        RPM = count2RPM(avg(3),labjack.scanRate);
        omega = RPMs*60; % angular rate of motor in rads/s
        qinfprop = rho*(omega*dprop/2)^2;
        lambda = Vinf / (omega*dprop/2);
        CT = Xforce / (qinfprop * Aprop);
        
        fprintf("------------------------------------------------------------------------\n");
        fprintf("Ambient Pressure (Pa)\t Ambient Temp (˚C)\t Ambient Density (kg/m^3) \n");
        fprintf("%6.0f\t %3.0f\t %1.3f \n",Spressure,Temp,rho)
        fprintf("X-force\t motor RPM\t PWM signal\t C_T\t lambda \n")
        fprintf("%3.3f\t %5.0f\t %4.0f\t %4.3f\t %4.3f \n",Xforce, RPM, PWMvec(Npwm),CT,lambda);
        fprintf("\n\n ")

%--------------------------------------------------------------------------              
        % save data
        
        runfileprefix = sprintf('run_%02.0f_%03.0f_%03.0f',calnum,tarenum,runNumber);
        
        runfile = sprintf("%s_%02.0f.mat",runfileprefix,N);        
        while isfile(strcat(rundirectory,'\',runfile))
            runfileprefix = sprintf('run_%02.0f_%03.0f_%03.0f',calnumber,tarenumber,runnumber);
            runfile = sprintf("%s_%02.0f.mat",runfileprefix,Npwm); 
            fprintf("Run number changed to %03.0f\n",runNumber)
            runNumber = runNumber + 1;
            if ~isfile(runfile)
                break
            end
        end
        
        save(sprintf('%s\\%s',rundirectory,runfile),...
            'data','dprop','motorName','Temp','pambient','rho',...
            'qinf','Xforce','RPM','omega','qinfprop','CT','lambda',...
            'Vinf');
        
    % PWM loop    
    end
    
    
end

