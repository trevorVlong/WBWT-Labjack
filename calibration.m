function [] = calibration()
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
addpath("C:\Users\longt\Documents\mit-git\3by2\WTrun");


caldir  = "C:/Users/longt/Dropbox (MIT)/Tunnel_Data/sum_fall_20/calibrations";
calnum  = input('input cal number: ');
calfile = sprintf("%s/cal%02.0f",caldir,calnum);

%% add Labjack
%silenced for debug
LJbox1 = LJbox;
LJbox1.setup();
LJbox1.connect();
LJbox1.analogSetup(2,3,1e2);
numAIN = 3; %only reading first 3 channels for Lift,Drag,Moment

%% calibration
masses = zeros(3,5);
raw_voltages = cell(3,5);
voltage_average = cell(3,5);
moment_arm = input('arm of applied moment: ');

for ax = 1:3
    if ax == 1
        disp('Drag Calibration')
    elseif ax == 2
        disp('Lift Calibration')    
    elseif ax == 3
        disp('Moment Calibration');
        fprintf('Moment arm in m = %2.2f\n\n', moment_arm)
    end
               
           
    for step = 1:5
        masses(ax,step) = input('calibration mass in kg: ');
        
        raw_voltages{ax,step} = LJbox1.recordData;
        %raw_voltages{ax,step}  = rand(3,3000);
        voltage_average{ax,step} = mean(raw_voltages{ax,step},2);
        
    end
end


B1 = zeros(3,3);
B2 = zeros(3,3);
B  = zeros(3,3);

% make calibration matrix in this section
B1(:,1) = ((voltage_average{2,2}-voltage_average{2,1})/-masses(1,2));
B1(:,2) = (voltage_average{1,2}-voltage_average{1,1})/masses(1,2);
B1(:,3) = ((voltage_average{3,2}-voltage_average{3,1})/(-masses(1,2)) + B1(:,1))/moment_arm;

B2(:,1) = (voltage_average{2,3}-voltage_average{2,1})/(-2*masses(1,2));
B2(:,2) = (voltage_average{1,3}-voltage_average{1,1})/(2*masses(1,2));
B2(:,3) = ((voltage_average{3,3}-voltage_average{3,1}/(-2*masses(1,2))) + B2(:,1))/moment_arm;

B = (B1+B2)/2;

C = inv(B);
C1 = inv(B1);
C2 = inv(B2);



%display things for debug of calibration
fprintf('Calibration matrix output: \n')
disp(C)
fprintf('Delta between mat1 and mat2: \n')
disp(C1-C2);

%% output files
% make logfile

% convert cell of voltages into csv file
writecell(raw_voltages,calfile)

% make matfile
% save calibration matrices for easy handling
save(sprintf('%s.mat',calfile),'C','C1','C2');

end




