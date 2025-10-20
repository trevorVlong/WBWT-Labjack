% run a sweep of calibration points

name = 'calLoads_01';

% 0: take data
% 1: load data and plot
caseflag = 1;

if caseflag==1

    load([name '.mat']);
    f = fieldnames(sweep_data);
    Nruns = length(f);

    FX_meas = zeros(Nruns,1);
    FX_app  = zeros(Nruns,1);

    for NN=1:Nruns
        FX_meas(NN) = mean(sweep_data.(f{NN}).Fx);
        FX_app(NN)  = sweep_data.(f{NN}).Fx_app_lbf;
    end

    figure;
    plot(FX_app, FX_meas, 'x');
    grid on; xlabel('Applied Load [lbf]'); ylabel('Measured FX [V]');

else

    sweepflag = 1;
    counter = 0;

    %% setup
    % tare and calibration
    tarefile = 'tare_file.mat';
    calibration = 'calibration.mat';

    % if cal, tare don't exist use 0 and identity
    try
        tare = load(tarefile,'tare_voltage');
    catch e
        tare = 0;
    end
    try
        cal = load(calibration,'V2F');
    catch e
        cal = 1;
    end

    % test params
    wait_time = 0.5; %s
    record_time = 3; %s

    sweep_data = struct(); % empty struct for holing array

    while sweepflag

        appliedLoad = input('Input applied load in lbs. Type -99 to stop sweep : ');
        if appliedLoad==-99
            sweepflag = 0;
        else
            counter = counter+1;
            run_data = struct();

            % settle
            pause(wait_time);

            % record and save data
            [data,runtime] = lj.timedRead(record_time);
            run_data.('Vx') = data(2,:);
            run_data.('q_inf') = data(1,:);
            run_data.('runtime') = runtime;

            % do some post processing
            run_data.('Fx') = cal*(run_data.('Vx')-tare);
            run_data.('Fx_app_lbf') = appliedLoad;

            % save
            sweep_data.(sprintf('run_%d',counter)) = run_data;
        end
    end
    % end
    % lj.setPWM(1000)

    filename = sprintf('%s.mat',name);
    if ~isfile(filename)
        save(sprintf('%s.mat',name),'sweep_data');
    else
        warning('could not save file because file with same name already exists');
    end

end
