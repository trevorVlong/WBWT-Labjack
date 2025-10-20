% run a PWM sweep of propeller data. 

name = "PWM_mapping_static";




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
PWM = [1000:50:1700,1800,1900,2000];

sweep_data = struct(); % empty struct for holing array

% run loop
for pwm_idx = 1:length(PWM)
    run_data = struct();
    lj.setPWM(PWM(pwm_idx))
    
    % settle
    pause(wait_time);
    
    % record and save data
    [data,runtime] = lj.timedRead(record_time);
    run_data.('Vx') = data(2,:);
    run_data.('q_inf') = data(1,:);
    run_data.('RPM_counts') = data(3,:);
    run_data.('PWM') = PWM(pwm_idx);
    run_data.('runtime') = runtime;

    % do some post processing
    run_data.('Fx') = cal*(run_data.('Vx')-tare);
    
    % save
    sweep_data.(sprintf('run_%d',PWM(pwm_idx))) = run_data;
    
end
lj.setPWM(1000)

filename = sprintf('%s.mat',name);
if ~isfile(filename)
    save(sprintf('%s.mat',name),'sweep_data');  
else
    warning('could not save file because file with same name already exists');
end
