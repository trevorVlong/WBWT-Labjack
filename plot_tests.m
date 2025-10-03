% brief look at early tunnel stuff
close all
addpath('/Users/trevorlong/Dropbox (MIT)/Tunnel_Data/sum_fall_20/runs/')
addpath('/Users/trevorlong/Dropbox (MIT)/Tunnel_Data/sum_fall_20/tares/')
addpath('/Users/trevorlong/Dropbox (MIT)/Tunnel_Data/sum_fall_20/calibrations/')
runfiles = [];
checkfiles = [];
checkerror = [];
checknum = [];
flap_ang = [40];


runset = [1,8]; %ailerons 20˚
      
tarenum = [202];
calnum  = [10];
uncorrected2D = [];
dcj = [];
cl2D = [];
cx2D = [];
cm2D = [];
alfa = [];


h(1) = figure('Visible', 'off');
h(2) = figure('Visible', 'off');
h(3) = figure('Visible', 'off');
h(4) = figure('Visible', 'off');
h(5) = figure('Visible', 'off');
h(6) = figure('Visible', 'off');
cax = [0 8];
alfarange = [-25,40];
clrange   = [-1,9];
cmrange   = [-.8,1.2];
cxrange   = [-10,1];


active_axis = 0;
for flap = 1:length(flap_ang)
    % specify which calibration and tare files will be used

    for runn = runset(flap,1):1:runset(flap,2)
        for cn = calnum
            calfile  = sprintf("cal%02.0f",calnum); 
            for tn = 1:length(tarenum)
                tarefile = sprintf("tare%03.0f",tarenum(tn));
                for Nrpm = 1:20
                    tempfile = sprintf("run_%02.0f_%03.0f_%03.0f_%02.0f.mat",calnum,tarenum(tn),runn,Nrpm);

                    if isfile(strcat('/Users/trevorlong/Dropbox (MIT)/Tunnel_Data/sum_fall_20/runs/',tempfile))
                        runfile  = tempfile;
                        runfiles = [runfiles, runfile];
% 
                        [corrected2D,uncorrected2D] = nonDimensionalize(runfile,calfile,tarefile,0);

                        dcj(Nrpm)  = mean(uncorrected2D.dCJ);
                        cl2D(Nrpm) = uncorrected2D.cl_average;
                        cx2D(Nrpm) = uncorrected2D.cx_average;
                        cm2D(Nrpm) = uncorrected2D.cm_average; 
                        alfa(Nrpm) = mean(uncorrected2D.alfa);
                        if active_axis == 1
                            %cl ranges
                            if cl2D(Nrpm) > clrange(2)
                                clrange(2) = cl2D(Nrpm)+1;

                            elseif cl2D(Nrpm) < clrange(1)
                                clrange(1) = cl2D(Nrpm)-1;
                            end
                            %cm ranges
                            if cm2D(Nrpm) > cmrange(2)
                                cmrange(2) = cm2D(Nrpm)+.2;

                            elseif cm2D(Nrpm) < cmrange(1)
                                cmragne(1) = cm2D(Nrpm)-.2;
                            end                        
                            %cx ranges
                            if cx2D(Nrpm) > cxrange(2)
                                cxrange(2) = cx2D(Nrpm)+1;

                            elseif cx2D(Nrpm) < cxrange(1)
                                cxragne(1) = cx2D(Nrpm)-1;
                            end                          
                            %alfa ranges
                            if alfa(Nrpm) > alfarange(2)
                                alfarange(2) = alfa(Nrpm)+2;

                            elseif alfa(Nrpm) < alfarange(1)
                                alfarange(1) = alfa(Nrpm)-2;
                            end
                        end
                        if alfa(Nrpm) > 40
                            fprintf("%s has strange AoA data\n",runfile);
                            checkfiles = [checkfiles, runfile];
                        end   
                    end
                end
                
                %Cl-Cx
                set(0, 'CurrentFigure', h(1))
                subplot(1,1,flap)
                scatter(cx2D,cl2D,30,dcj,'filled');
                xlabel('cx')
                ylabel('cl')
                xlim(cxrange)
                ylim(clrange)
                grid on
                axis square
                title(sprintf('%2.0f˚ flaps 23mph',flap_ang(flap)))
                colorbar
                b = colorbar;
                caxis(cax)
                set(get(b,'label'),'string','∆CJ');
                hold on
                
                % Cm-Cx
                set(0, 'CurrentFigure', h(2))
                subplot(1,1,flap)
                scatter(cx2D,cm2D,30,dcj,'filled');
                xlabel('cx')
                ylabel('cm')
                xlim(cxrange)
                ylim(cmrange)
                grid on
                axis square
                title(sprintf('%2.0f˚ flaps 23mph',flap_ang(flap)))
                colorbar
                b = colorbar;
                caxis(cax)
                set(get(b,'label'),'string','∆CJ');
                hold on 
                
                %Cm-Cl
                set(0, 'CurrentFigure', h(3))
                subplot(1,1,flap)
                scatter(cl2D,cm2D,30,dcj,'filled');
                xlabel('cl')
                ylabel('cm')
                grid on
                axis square
                xlim(clrange)
                ylim(cmrange)
                title(sprintf('%2.0f˚ flaps 23mph',flap_ang(flap)))
                colorbar
                b = colorbar;
                caxis(cax)
                set(get(b,'label'),'string','˝∆CJ');
                hold on
                
                % Cl-alpha
                set(0, 'CurrentFigure', h(4))
                subplot(1,1,flap)
                scatter(alfa,cl2D,30,dcj,'filled');
                ylabel('Lift Coefficient')
                xlabel('Angle of Attack')
                xlim(alfarange)
                ylim(clrange)
                grid on
                axis square
                title(sprintf('%2.0f˚ flaps 23mph',flap_ang(flap)))
                colorbar
                b = colorbar;
                caxis(cax)
                set(get(b,'label'),'string','˝∆CJ');
                hold on
                
                
                % Cm-alpha
                set(0, 'CurrentFigure', h(5))
                subplot(1,1,flap)
                scatter(alfa,cm2D,30,dcj,'filled');
                ylabel('Moment Coefficient')
                xlabel('Angle of Attack')
                xlim(alfarange)
                ylim(cmrange)
                grid on
                axis square
                title(sprintf('%2.0f˚ flaps 23mph',flap_ang(flap)))
                colorbar
                b = colorbar;
                caxis(cax)
                set(get(b,'label'),'string','˝∆CJ');
                hold on
                
                
                % Cx-alpha
                set(0, 'CurrentFigure', h(6))
                subplot(1,1,flap)
                scatter(alfa,cx2D,30,dcj,'filled');
                ylabel('X-force Coefficient')
                xlabel('Angle of Attack')
                xlim(alfarange)
                ylim(cxrange)
                grid on
                axis square
                title(sprintf('%2.0f˚ flaps 23mph',flap_ang(flap)))
                colorbar
                b = colorbar;
                caxis(cax)
                set(get(b,'label'),'string','˝∆CJ');
                hold on
 
            end
        end    
    end
end
set(h(1), 'Visible', get(0,'DefaultFigureVisible'))
set(h(2), 'Visible', get(0,'DefaultFigureVisible'))
set(h(3), 'Visible', get(0,'DefaultFigureVisible'))
set(h(4), 'Visible', get(0,'DefaultFigureVisible'))
set(h(5), 'Visible', get(0,'DefaultFigureVisible'))
set(h(6), 'Visible', get(0,'DefaultFigureVisible'))
figure(1)
sgtitle('Cl-Cx Slotted Flap--uncorrected')
colormap('jet')

figure(2)
sgtitle('Cm-Cx Slotted Flap--uncorrected')
colormap('jet')

figure(3)
sgtitle('Cm-Cl Slotted Flap--uncorrected')
colormap('jet')

figure(4)
sgtitle('Cl-alpha Slotted Flap--uncorrected')
colormap('jet')

figure(5)
sgtitle('Cm-alpha Slotted Flap--uncorrected')
colormap('jet')

figure(6)
sgtitle('Cx-alpha Slotted Flap--corrected')
colormap('jet')


