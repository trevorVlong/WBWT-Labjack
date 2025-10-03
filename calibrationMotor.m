function [] = calibrationMotor(labjack)
%Trevor Long
% 30 July, 2020
% calibration for 3x2 WT for SSTOL tests
%
% Use whatever units you'd like but make sure they're consistent. SSTOL project, use 
% metric, as that is what the rest of the code works off of.
%
%
%% setup for files and other

addpath("C:\Users\longt\Documents\mit-git\toolbox\aawind");
addpath("C:\Users\longt\Documents\mit-git\3by2\labjack");


caldir  = "C:\Users\longt\Dropbox (MIT)\Tunnel_Data\spring21\motormap\calibrations";
calnum  = input('input cal number: ');
calfile = sprintf("%s/cal%02.0f",caldir,calnum);

%% add Labjack
%silenced for debug
%labjack = LJbox;
%LJbox1.setup();
%LJbox1.connect();

numAIN = 2; %only reading first 3 channels for Lift,Drag,Moment
labjack.analogSetup(numAIN,5,100); % takes readings of first 2


%% calibration
masses = zeros(1,5);
raw_voltages = cell(1,5);
voltage_average = cell(1,5);

for ax = 1:1
    
    disp('X-force cell calibration \n')

               
           
    for step = 1:5
        masses(1,step) = input('calibration mass in kg: ');
        
        raw_voltages{ax,step} = labjack.record_data;
        %raw_voltages{ax,step}  = rand(3,3000);
        voltage_average(ax,step) = mean(raw_voltages{ax,step},2); 
        disp(voltage_average); % show table just because
    end
    
end

dmdV1 = masses(2)/((voltage_average(2) + voltage_average(4))/2-(voltage_average(1)+ voltage_average(5))/2)
dmdV2 = masses(3)/(voltage_average(3)-(voltage_average(1)+ voltage_average(5))/2)

dMdV = 0.5 * (dmdV1 + dmdV2);
calX = dMdV


%% output files

% make matfile
% save calibration matrices for easy handling
save(sprintf('%s.mat',calfile),'raw_voltages','voltage_average','dMdV','calX');

end




