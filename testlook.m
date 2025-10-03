% brief look at early tunnel stuff
addpath("C:\Users\longt\Dropbox (MIT)\Tunnel_Data\sum_fall_20\runs")
samplenum = 3;
runfiles = [];
for ii = 29:39
    for jj = 1:11
        runfile = sprintf("run_02_004_%03.0f_%02.0f.mat",ii,jj);
        runfiles = [runfiles runfile];
    end
end
calfile = 'cal02.mat';
tarefile ='tare003.mat';

out = cell(samplenum*6,1);
checkfile = [];
checkerror = [];
checknum = [];

for filenum = 1:numel(runfiles)
    filename = runfiles(filenum);
    if isfile(filename)
        [~,out{filenum}] = nonDimensionalize(runfiles(filenum),calfile,tarefile);

        DCJ = mean(out{filenum}.dCJ);
        cl = mean(out{filenum}.cl);
        cx = mean(out{filenum}.cx);
        if cl < -1
            checkfile = [checkfile filename];
             checknum = [checknum filenum];
            checkerror = [checkerror "cl"];


        elseif DCJ > 10
            checkfile = [checkfile filename];
            checknum = [checknum filenum];
            checkerror = [checkerror "DCJ"];
        end

        if  ~strcmp(checkfile,filename)
            figure(2)
            hold on
            scatter(cx,cl,20,DCJ,'filled')
            xlabel('cx')
            ylabel('cl')
        end

        %figure(2)
        %hold on
    end
    
end
figure(2)
colormap('jet')
colorbar
cax = [0 5];
caxis (cax);
hold off

