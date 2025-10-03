% brief look at early tunnel stuff
close all
addpath('/Users/longt/Dropbox (MIT)/Tunnel_Data/sum_fall_20/runs/')
addpath('/Users/longt/Dropbox (MIT)/Tunnel_Data/sum_fall_20/tares/')
addpath('/Users/longt/Dropbox (MIT)/Tunnel_Data/sum_fall_20/calibrations/')
runfiles = [];
checkfiles = [];
checkerror = [];
checknum = [];
flap_ang = [20];
%  runset = [40,46;... %0 deg flaps
%            47,52;... %20 deg flaps
%            58,63;... % 40 deg ailerons
%            64,69;... % 50 deg flaps
%            70,75]; %55 deg flaps

%runset = [64,69;... %50 deg solid
%          70,75;... %55 deg solid
%          96,102;...%50 deg slotted
%          83,89];   %55 deg slotted
% runset = [96,102;...
%           83,89;...
%           90,95];

runset = [60:80]; %ailerons 20˚
      
tarenum = [6];
calnum  = [2];
uncorrected2D = [];
dcj = [];
cl2D = [];
cx2D = [];
cm2D = [];
alfa = [];
Vinf = [];
Fz   = [];

h(1) = figure('Visible', 'off');
h(2) = figure('Visible', 'off');
h(3) = figure('Visible', 'off');
h(4) = figure('Visible', 'off');
h(5) = figure('Visible', 'off');
h(6) = figure('Visible', 'off');
cax = [0 7];
alfarange = [-25,40];
clrange   = [-1,9];
cmrange   = [-.8,1.2];
cxrange   = [-10,1];


active_axis = 0;
for flap = 1:length(flap_ang)
    % specify which calibration and tare files will be used

    for runn = runset
        for cn = calnum
            calfile  = sprintf("cal%02.0f",calnum); 
            for tn = 1:length(tarenum)
                tarefile = sprintf("tare%03.0f",tarenum(tn));
                for Nrpm = 1:11
                    tempfile = sprintf("run_%02.0f_%03.0f_%03.0f_%02.0f.mat",calnum,tarenum(tn),runn,Nrpm);

                    if isfile(tempfile)
                        runfile  = tempfile;
                        runfiles = [runfiles, runfile];
% 
                        [corrected2D,uncorrected2D] = nonDimensionalize(runfile,calfile,tarefile);

                        dcj(Nrpm)  = mean(uncorrected2D.dCJ);
                        cl(Nrpm) = uncorrected2D.cl_average;
                        cx(Nrpm) = uncorrected2D.cx_average;
                        Vinf(Nrpm) = uncorrected2D.Vinf_measured; 
                        alfa(Nrpm) = mean(uncorrected2D.alfa); 
                        Fz(Nrpm)   = uncorrected2D.Fz;
                        disp(tempfile);
                        fprintf('Vinf = %2.2f  \ncl = %2.2f \n',Vinf(Nrpm),cl(Nrpm));
                    end
                end
                
                %Cl-Cx
                set(0, 'CurrentFigure', h(1))
                subplot(1,1,flap)
                scatter(Vinf,cx,'b','filled');
                xlabel('V_inf (m/s)')
                ylabel('X-force Coefficient, cx')
%                 xlim(Vinf)
%                 ylim(clrange)
                grid on
                axis square
                title(sprintf('X Coefficient as Function of Vinf, %2.0f˚ flaps',flap_ang(flap)))
                hold on
                
                %Cl-Cx
                set(0, 'CurrentFigure', h(3))
                subplot(1,1,flap)
                scatter(Vinf,Fz,'b','filled');
                xlabel('V_inf (m/s)')
                ylabel('Lift Force, L (N)')
%                 xlim(Vinf)
%                 ylim(clrange)
                grid on
                axis square
                title(sprintf('X Coefficient as Function of Vinf, %2.0f˚ flaps',flap_ang(flap)))
                hold on
                
                % Cm-Cx
                set(0, 'CurrentFigure', h(2))
                subplot(1,1,flap)
                scatter(Vinf,cl,'b','filled');
                xlabel('V_inf (m/s)')
                ylabel('Lift-force Coefficient, cl')
%                 xlim(cxrange)
%                 ylim(cmrange)
                grid on
                axis square
                title(sprintf('Lift Coefficient as Function of Vinf, %2.0f˚ flaps',flap_ang(flap)))
%                colorbar
%                b = colorbar;
%                caxis(cax)
%                set(get(b,'label'),'string','∆CJ');
                hold on 
                
%                 %Cm-Cl
%                 set(0, 'CurrentFigure', h(3))
%                 subplot(2,3,flap)
%                 scatter(cl2D,cm2D,30,dcj,'filled');
%                 xlabel('cl')
%                 ylabel('cm')
%                 grid on
%                 axis square
%                 xlim(clrange)
%                 ylim(cmrange)
%                 title(sprintf('measured cm-cl curve, %2.0f˚ flaps',flap_ang(flap)))
%                 colorbar
%                 b = colorbar;
%                 caxis(cax)
%                 set(get(b,'label'),'string','˝∆CJ');
%                 hold on
                
%                 % Cl-alpha
%                 set(0, 'CurrentFigure', h(4))
%                 subplot(2,3,flap)
%                 scatter(alfa,cl2D,30,dcj,'filled');
%                 ylabel('Lift Coefficient')
%                 xlabel('Angle of Attack')
%                 xlim(alfarange)
%                 ylim(clrange)
%                 grid on
%                 axis square
%                 title(sprintf('cl-alpha curve, %2.0f˚ flaps',flap_ang(flap)))
%                 colorbar
%                 b = colorbar;
%                 caxis(cax)
%                 set(get(b,'label'),'string','˝∆CJ');
%                 hold on
                
                
%                 % Cm-alpha
%                 set(0, 'CurrentFigure', h(5))
%                 subplot(2,3,flap)
%                 scatter(alfa,cm2D,30,dcj,'filled');
%                 ylabel('Moment Coefficient')
%                 xlabel('Angle of Attack')
%                 xlim(alfarange)
%                 ylim(cmrange)
%                 grid on
%                 axis square
%                 title(sprintf('cm-alpha curve, %2.0f˚ flaps',flap_ang(flap)))
%                 colorbar
%                 b = colorbar;
%                 caxis(cax)
%                 set(get(b,'label'),'string','˝∆CJ');
%                 hold on
                
                
%                 % Cx-alpha
%                 set(0, 'CurrentFigure', h(6))
%                 subplot(2,3,flap)
%                 scatter(alfa,cx2D,30,dcj,'filled');
%                 ylabel('X-force Coefficient')
%                 xlabel('Angle of Attack')
%                 xlim(alfarange)
%                 ylim(cxrange)
%                 grid on
%                 axis square
%                 title(sprintf('cx-alpha curve, %2.0f˚ flaps',flap_ang(flap)))
%                 colorbar
%                 b = colorbar;
%                 caxis(cax)
%                 set(get(b,'label'),'string','˝∆CJ');
%                 hold on
 
            end
        end    
    end
end
set(h(1), 'Visible', get(0,'DefaultFigureVisible'))
set(h(2), 'Visible', get(0,'DefaultFigureVisible'))
 set(h(3), 'Visible', get(0,'DefaultFigureVisible'))
% set(h(4), 'Visible', get(0,'DefaultFigureVisible'))
% set(h(5), 'Visible', get(0,'DefaultFigureVisible'))
% set(h(6), 'Visible', get(0,'DefaultFigureVisible'))
figure(1)
sgtitle('Cx')

figure(2)
sgtitle('Cl')

% figure(3)
% sgtitle('Cm-Cl Slotted Flap--corrected')
% colormap('jet')
% 
% figure(4)
% sgtitle('Cl-alpha Slotted Flap--corrected')
% colormap('jet')
% 
% figure(5)
% sgtitle('Cm-alpha Slotted Flap--corrected')
% colormap('jet')
% 
% figure(6)
% sgtitle('Cx-alpha Slotted Flap--corrected')
% colormap('jet')


