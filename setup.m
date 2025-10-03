%%% Sets up all the sensors that will be used for running the experiment.
%%% Also runs calibration on the scantron

% add paths of toolbox
toolbox_path = "C:\Users\longt\Documents\mit-git\toolbox_update\toolbox\aawind\aawind\";
tbt_path     = "C:\Users\longt\Documents\mit-git\3by2\WTrun\";
addpath(toolbox_path,tbt_path);

% create instances of sensors to be handed off
Weather = aawind.Weather('COM3');
Mensor  = aawind.Mensor('COM6');


% set up Initium and calibrate
Initium = aawind.Initium;
Initium.configureScanners([32 32 0 0]); %
Initium.configureTable(1,101:132);
Initium.configureTable(2,201:232); % double check that this is correct syntax
Initium.zeroCalibration;

%% set up velmex and zero
velmex = aawind.Velmex('COM7');
velmex.setOrigin

%% set up labjack


%% run a tare for this set of cases
tare(Initium);

fprintf('-----------------------------------------------------\n');
fprintf('----------------setup complete-----------------------\n');
fprintf('-----------------------------------------------------\n');