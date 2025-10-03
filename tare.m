function rawdata = tare(Initium,LJbox1,tarenum,scantime,scanrate)
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
    taredir  = "C:\Users\longt\Dropbox (MIT)\Tunnel_Data\sum_fall_20\tares";
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
    LJbox1.analogSetup(4,scantime,scanrate);
    raw_voltages = cell(1,1);
    
%% Initium tare
    Initium.acquireData(1,1e3);
    pitot_tare = Initium.PressureData;
    
%% collect 
%--------------------------------------------------------------------------
    rawdata = LJbox1.recordData();
    average_voltages = mean(rawdata,2);
    raw_voltages{1} = rawdata;
    disp('Tare Voltages');
    disp(average_voltages);
    
    tarevec = average_voltages(1:3,:);

%% save and log 
%--------------------------------------------------------------------------
    % save .csv file for logging
    writematrix(average_voltages,sprintf('%s.csv',tarefile));

    % save .mat file for easy access
    save(sprintf('%s.mat',tarefile),'tarevec','rawdata','pitot_tare');
    % save 
    tareLog(tarefile);
end