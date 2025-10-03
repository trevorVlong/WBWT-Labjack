function [] = tareLog(tarefile)
% writeLog adds
%   Detailed explanation goes here
    savedirectory = "C:\Users\longt\Dropbox (MIT)\Tunnel_Data\sum_fall_20\";
    
    filenums = split(tarefile,["tare",".mat"]);
    tarenum = filenums(2);
    
    dt = split(string(datetime),[" "]);
    date = dt(1);
    time = dt(2);

    goodpoint = "Y";

    filename = sprintf("%starelog.csv",savedirectory);

    newrow = [tarefile,tarenum,date,time,goodpoint];
    
    writematrix(newrow,filename,'WriteMode','append')

end

