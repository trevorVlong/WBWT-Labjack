function [calfile,tarefile] = readRunfile(runfile)
% reads a runfile name and scans it for calibration number, tare number, etc.
%and spits back out filenames for those numbers
    filenums = split(runfile,["_","."]);
    
    calfile = sprintf("cal%s.mat",filenums(2));
    tarefile = sprintf("tare%s.mat",filenums(3));

end