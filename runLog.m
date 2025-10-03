function [] = runLog(runfile,setup,flap_ang)
% writeLog adds a run to the log for tracking purposes. Almost all data is contained within each
% runfile, but setup type and flap angle are included to be used as identifiers when searching the log
%  flap angle is simply the angle of the flap for that run
%  setup is a brief description of that setup (i.e. slotted flaps, 10degree motor mount) etc.
%  examples:
%
%   flap_ang = "20deg"
%   setup    = "slotted flap, 
%   Detailed explanation goes here
    savedirectory = "C:\Users\longt\Dropbox (MIT)\Tunnel_Data\sum_fall_20\";
    
    
% split filename
%--------------------------------------------------------------------------
    filenums = split(runfile,["_","."]);
    calnum = sprintf("%s",filenums(2));
    tarenum = sprintf("%s",filenums(3));
    runnum = sprintf("%s",filenums(4));
    pwrnum = sprintf("%s",filenums(5));
   
    % date and time
    dt = split(string(datetime),[" "]);
    date = dt(1);
    time = dt(2);

    goodpoint = "Y";
        
    %prep for storage and append to logfile
    filename = sprintf("%stestlog.csv",savedirectory);
    newrow = [runfile,setup,flap_ang,runnum,pwrnum,calnum,tarenum,date,time,goodpoint];
    writematrix(newrow,filename,'WriteMode','append')

end

