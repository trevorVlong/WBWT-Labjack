function [wake_avg,wake_std] = collectWBwake(velmex,pscanner,positions,npnts)
% Trevor Long
% 9 Sept, 2021
% 
%
% inputs
% velmex := velmex object from aawind toolbox. Should be connected via COM
% port (check computer for port setup)
%
% scanivalve := scanivalve object from aawind toolbox. Connected via
% ethernet port
%
%  positions a N x 2 dimensional array with the absolute x,y positions the
%  velmex will move to. Units are inches.
%
%  npts: number of points collected and averaged at ecah position
   
    %% data collection setup
    velmex.goHome  




    %% Setup Section
    % in this section the code will prep and setup the labjack, then run N tests corresponding
    % to the number of PWM values in PWMvec
    % also being setup is the pitot scanner that is used to measure static pressure interference on the 
    % tunnel walls

    % add aawind toolbox to path
    addpath("C:\Users\longt\Documents\mit-git\toolbox_update\toolbox\aawind\aawind");
    addpath("C:\Users\longt\Documents\mit-git\3by2\labjack");


    wake_avg = [];
    wake_std = [];


    % current climate added separately
    for M = 1:length(positions)
        xpos = positions(M,1);
        ypos = positions(M,2);
        velmex.absoluteMove([xpos,0,ypos]);


    %% data collection block ===================================================
        pause(0.2) % wait for transients
        try 
            [pavg, pstd] = rake_slice(pscanner, npnts);
            
            wake_avg(M,:) = pavg;
            wake_std(M,:) = pstd;
        catch
            warning('data collection error at scanivalve, continuing (ctrl +c to cancel)')
        end

    end
    velmex.goHome
end
 

