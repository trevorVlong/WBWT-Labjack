function [RPM,RPMavg,RPMstd] = count2RPM(count,samplefreq)
% takes in a single line of count data and the sample frequency it was taken at
% the function then gives 100ms (10Hz) snapshots of the RPM based on that count data
% 
% Inputs:
% count      --a 1xN line of data that is the count of pulses recieved from that motor
% samplefreq --an integer value giving the sampling frequency of the data taken
%
% Outputs:
% RPM    -- a 1xM line of RPMs returned
% RPMavg -- an integer RPM average for the interval
% RPMstd -- an integer standard deviation for RPM values over the interval
%
%
% **NOTE** 
% as of 7/6/2020 data is being recorded at 100Hz, though this might at some point change
%------------------------------

% T40 correction
% T40 motor has 8 poles, so divide RPM/8 to get motor RPM
T40pole = 6;

outfreq = 10; %Hz
infreq = samplefreq;
sampleInt = samplefreq/outfreq;

sampledcounts = count(1:sampleInt:numel(count));

CPS = (sampledcounts(2:end)-sampledcounts(1:end-1))*outfreq;
RPM = 60/T40pole * CPS;
RPMavg = mean(RPM);
RPMstd = std(RPM);
    
end