function alfa = readAoA(LabJbox)
%
%   TO DO make alfa0 work programatically from calibration

    Valfa0        = 2.0196;  %volts
    
    % set up for simple analog run
    LabJbox.analogSetup();
    LabJbox.scanRate = 1e5;
    rawdata = LJbox1.recordData();
    aoa_correction = 360/5; % degrees / Volt
    
    % pull out AoA data line
    Vaoa = mean(rawdata(4,:)); % volts
    
    
    % return AoA in degrees
    alfa = (Vaoa-Valfa0)*aoa_correction;

end

