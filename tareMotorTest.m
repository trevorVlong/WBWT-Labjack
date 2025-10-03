function rawdata = tareMotorTest(labjack,tarenum)
% Trevor Long
% 30 July, 2020
%
% Takes a tare for 3 x 2 WT setup
%
% Tare is simply a "rezero" of a test rig
% in this case wind off tare gives a relative
% 0 for a group of runs of the WT

    disp('Taking zero tare-make sure WT is off or rerun');

%% setup
%--------------------------------------------------------------------------
    % add paths and create file dirs
    addpath("C:\Users\longt\Documents\mit-git\toolbox\aawind")
    addpath("C:\Users\longt\Documents\mit-git\3by2\WTrun");
    taredir  = "C:\Users\longt\Dropbox (MIT)\Tunnel_Data\spring21\motormap\tares";
    %tarenum  = input('input tare number: ');
    tarefile = sprintf("%s\\tare%03.0f",taredir,tarenum);
    n = 0;
    while isfile(tarefile)
         n = n + 1;
         tarefile = sprintf("%s\\tare%03.0f",taredir,tarenum + n);
    end
    
    fprintf('tarefile saved as %s\n',tarefile);
    disp('');
    disp('');
    
    % local instance of labjack so you don't screw with 
    %LJbox1 = LJbox;
    %LJbox1.setup();
    %LJbox1.connect();
    labjack.analogSetup(2,5,100); % takes readings of first 2

    raw_voltages = cell(1,1);
    
    
%% collect 
%--------------------------------------------------------------------------
    rawdata = labjack.recordData();
    average_voltages = mean(rawdata,2);
    raw_voltages{1} = rawdata;
    disp('Tare Voltages');
    disp(average_voltages);
    
    %only care about x-direction load cell for motor map tied to channel 2
    tareX = average_voltages(2);

%% save and log 
%--------------------------------------------------------------------------
    % save .csv file for logging
    writematrix(average_voltages,sprintf('%s.csv',tarefile));

    % save .mat file for easy access
    save(sprintf('%s.mat',tarefile),'tareX','rawdata');
    % save 
    tareLog(tarefile);
end