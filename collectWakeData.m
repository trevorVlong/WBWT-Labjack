function [runfiles,corrected_tables,uncorrected_tables, pointgrid, watchlist] = collectData(traverse,positions,espbox,weatherbox,Mensor,calnum,tarenum,runNumber,PWMvec,setup,flap_ang)
% Trevor Long
% 28 July, 2020
% script for running 3x2 windtunnel using:
% 1 Labjack T7
% pitot static ports on tunnel walls
%
% format for run #
% General Procedure:
% this code has 2 associated helper codes
% Code 1, runCalibration: used to get voltage-force relationships for the load cells
% Code 2, Tare: finds a local "0" for a set of tests
%
% calibration code (2 digits)
% tare code (3-digits)
% run code (3-digits)
%
%
% The data for each motor power level (or other run variable) is
% self-contained so that corrections for each position are made from the
% state of that instance.
%
%
% ============================================================================================================================================================
% Inputs:
% -traverse,  moves wake pitot reader
%
% -espbox,    instrument that controls the rapid-pitot readers for traverse
%             and wall interference
%
% -Mensor,    instrument for dynamic pressure readings
%
% -Weather,   series of boards that collect state variables (Temp and Amb
%             Pressure)
%
% -calnum,    number for a .mat file that contains a calnum (AA) and a 3x3 calibration matrix
%
%
% -tarenum,   number for a .mat file that contains a tarenum(BBB) and a 3x1 tare vector
%
%
% -runNumber, a 3-digit int that specifies the current run
%
% -PWMvec   , a vector of PWMs to output corresponding motor RPMs
% -AoA      , angle of attack of model during the run
%
% Outputs:
%
%
%
%% data collection setup


%logfile = sprintf("WTerrorlog.txt",runfileprefix);
logfile = NaN;

% directories
savedirectory = "C:\Users\longt\Dropbox (MIT)\Tunnel_Data\sum_fall_20";
rundirectory  = sprintf("%s\\runs",savedirectory);
taredirectory = sprintf("%s\\tares", savedirectory);
caldirectory  = sprintf("%s\\calibrations",savedirectory);
tarefile      = sprintf("tare%03.0f.mat",tarenum);
calfile       = sprintf("cal%02.0f.mat",calnum);

% set up empty lists for recording later
runfiles = [];
corrected_tables = [];
uncorrected_tables = [];
watchlist = [];


%% Setup Section
% in this section the code will prep and setup the labjack, then run N tests corresponding
% to the number of PWM values in PWMvec
% also being setup is the pitot scanner that is used to measure static pressure interference on the
% tunnel walls

% add aawind toolbox to path
addpath("C:\Users\longt\Documents\mit-git\toolbox\aawind\aawind");
addpath("C:\Users\longt\Documents\mit-git\3by2\labjack");
addpath(rundirectory);
addpath(caldirectory);
addpath(taredirectory);

% sampling parameters for force measurements
runtime = 3; % seconds
scanrate = 1e2; %Hz

% activate and connect to labjack, prime motors
LJbox1 = LJbox;
LJbox1.setup();
LJbox1.connect()
LJbox1.SSTOLsetup(runtime,scanrate);
LJbox1.setupPWMout();

%
disp('----------------------------------------------')
disp('-----------------Motors Armed-----------------');
disp('----------------------------------------------')

%% Run Section
% run N number of tests at PWM
% breakout for channel setup on SSTOL
% 1: Lift
% 2: Drag
% 3: Moment
% 4: AoA sensor
% 5: None
% 6: None
% 7: None


%
%
% zplus = 0:.125:30
%
%
for pos = 1:length(positions(:,1))
  % move traverse into position

    for N = 1:length(PWMvec)
        % run for every specified motor power

        % set run power and send to motor via PWM signal
        PWM = PWMvec(N);
        LJbox1.changePWMout(PWM);


        %% data collection block ===================================================
        pause(0.2) % wait for transients

        Mensor.startRecording; %read tunnelq
        weatherbox.startRecording; % read state variables
        espbox.acquireData(2,1e3) % read wall pitots
        walldata = espbox.PressureData;

        %collect force data
        data = LJbox1.recordData2;

        % stop collecting state and tunnel
        statevars = weatherbox.stopRecording;
        tunnelq   = Mensor.stopRecording;
        % .Temperature Celcius
        % .RelativeHumidity %?
        % .StaticPressure kPa
        %set motors to off
        LJbox1.changePWMout(900); % sets motors to 0 throttle for safety
        disp('----------test point complete-----------------')
        disp('----------------------------------------------')


        %% save data structures ===================================================
        % setup file saves with auto_increment if file exists
        runfileprefix = sprintf('run_%02.0f_%03.0f_%03.0f',calnum,tarenum,runNumber);
        runfile = sprintf("%s_%02.0f.mat",runfileprefix,N);
        while isfile(runfile)
            runfileprefix = sprintf('run_%02.0f_%03.0f_%03.0f',calnum,tarenum,runNumber);
            runfile = sprintf("%s_%02.0f.mat",runfileprefix,N);
            disp("Run number changed to %03.0f",runNumber)
            if ~isfile(runfile)
                break
            end
        end
        runLog(runfile,setup,flap_ang);
        save(sprintf('%s\\%s',rundirectory,runfile),'data','walldata','tarenum','calnum','PWMvec','flap_ang','setup','statevars','tunnelq');


        % transform and correct data
        [corr_d, uncorr_d] = nonDimensionalize(runfile,calfile,tarefile);


        % run readout
        fprintf("Tunnel Conditions\n")
        fprintf(" Static Pressure (MPa) \t Speed (mph) \t Amb. Temp (˚C) \t Amb. density (kg/m3) \n")
        fprintf("   %3.3f               \t %2.3f       \t %2.3f          \t %2.3f                \n\n",...
                uncorr_d.static_pressure, convvel(uncorr_d.tunnelspeed,'m/s','mph'), mean(uncorr_d.Temp), mean(uncorr_d.density));

        fprintf(" uncorrected results %s \n",runfile);
        fprintf("CL_average \t CX_average \t Cm_average \t ∆CJ_average \n");
        fprintf("%2.3f      \t %2.3f      \t %2.3f      \t %2.3f       \n\n",...
                uncorr_d.cl, uncorr_d.cx,  uncorr_d.cm, mean(uncorr_d.dCJ));
        fprintf(" standard deviations \n");
        fprintf("CL_std \t CX_std \t Cm_std \t ∆CJ_std \n");
        fprintf("%2.3f      \t %2.3f      \t %2.3f      \t %2.3f       \n",...
                uncorr_d.clstd, uncorr_d.cxstd,  uncorr_d.cmstd, std(uncorr_d.dCJ));

        % add number to runlog
        runfiles = [runfiles, runfile];
        corrected_tables = [corrected_tables corr_d];
        uncorrected_tables = [uncorrected_tables uncorr_d];


    end
end
    figure()
    plot(mean(walldata,2));
end
