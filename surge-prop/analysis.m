load('PWM_mapping_static.mat')

num_runs = numel(fieldnames(sweep_data));

RPM_values = zeros(num_runs, 1);
PWM_values = zeros(num_runs, 1);

sweeps = fieldnames(sweep_data);

for runidx = 1:numel(sweeps)
    sweep_name = sweeps{runidx};
    sweep = sweep_data.(sweep_name);
    runtime = sweep.runtime;
    RPM_count_max = max(sweep.RPM_counts);
    RPM_count_min = min(sweep.RPM_counts(sweep.RPM_counts ~= 0));
    delta_RPM_count = RPM_count_max - RPM_count_min;
    RPM = (delta_RPM_count / runtime) * (60 / 7);
    PWM_values(runidx) = sweep.PWM;
    RPM_values(runidx) = RPM;
end

T = table(PWM_values, RPM_values, 'VariableNames', {'PWM_Values', 'RPM_values'});
disp(T) 