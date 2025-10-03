function [] = calLog(calfile)
% writeLog adds
%   Detailed explanation goes here
    savedirectory = "C:\Users\longt\Dropbox (MIT)\Tunnel_Data\sum_fall_20\";
%     savedirectory = "~/Dropbox (MIT)/Tunnel_Data/sum_fall_20/";
    
    filenums = split(calfile,["cal",".mat"]);
    calnum = filenums(2);
    
    dt = split(string(datetime),[" "]);
    date = dt(1);
    time = dt(2);

    goodpoint = "Y";

    filename = sprintf("%scalibrationlog.csv",savedirectory);

    newrow = [calfile,calnum,date,time,goodpoint];
    
    writematrix(newrow,filename,'WriteMode','append')

end