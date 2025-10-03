function [aData] = stream(handle,numFrames,aData,aNames,aValues,scanRate,aScanList,aScanListNames,scansPerRead,maxRequests)
    try
        try
                % Write the analog inputs' negative channels (when applicable), ranges
            % stream settling time and stream resolution configuration.
            LabJack.LJM.eWriteNames(handle, numFrames, aNames, aValues, -1);

            % Configure and start stream
            numAddresses = aScanList.Length;
            [~, scanRate] = LabJack.LJM.eStreamStart(handle, scansPerRead, ...
                numAddresses, aScanList, scanRate);

            disp(['Stream started with a scan rate of ' ...
                  num2str(scanRate) ' Hz.'])

            tic

            disp(['Performing ' num2str(maxRequests) ' stream reads.'])

            totalScans = 0;
            curSkippedSamples = 0;
            totalSkippedSamples = 0;

            for i = 1:maxRequests-1
                [~, devScanBL, ljmScanBL] = LabJack.LJM.eStreamRead( ...
                    handle, aData, 0, 0);

                totalScans = totalScans + scansPerRead;

                % Count the skipped samples which are indicated by -9999
                % values. Skipped samples occur after a device's stream buffer
                % overflows and are reported after auto-recover mode ends.
                % When streaming at faster scan rates in MATLAB, try counting
                % the skipped packets outside your eStreamRead loop if you are
                % getting skipped samples/scan.
                curSkippedSamples = sum(double(aData) == -9999.0);
                totalSkippedSamples = totalSkippedSamples + curSkippedSamples;

                disp(['eStreamRead ' num2str(i)])
                fprintf('  1st scan out of %d : ', scansPerRead)
   %             for j = 1:numAddresses
                    %fprintf('%s = %.4f ', char(aScanListNames(j)), aData(j))
                %end
                fprintf('\n')
                disp(['  Scans Skipped = ' ...
                      num2str(curSkippedSamples/numAddresses) ...
                      ', Scan Backlogs: Device = ' num2str(devScanBL) ...
                      ', LJM = ' num2str(ljmScanBL)])
            end
            %timeElapsed = toc;

%             disp(['Total scans = ' num2str(totalScans)])
%             disp(['Skipped Scans = ' ...
%                   num2str(totalSkippedSamples/numAddresses)])
%             disp(['Time Taken = ' num2str(timeElapsed) ' seconds'])
%             disp(['LJM Scan Rate = ' num2str(scanRate) ' scans/second'])
%             disp(['Timed Scan Rate = ' num2str(totalScans/timeElapsed) ...
%                   ' scans/second'])
%             disp(['Sample Rate = ' ...
%                   num2str(numAddresses*totalScans/timeElapsed) ...
%                   ' samples/second'])
        aData(1)
        catch e
            showErrorMessage(e)
        end
        disp('Stop Stream')
        LabJack.LJM.eStreamStop(handle);

        % Close handle
        %LabJack.LJM.Close(handle);
    catch e
        showErrorMessage(e)
        %LabJack.LJM.CloseAll();
    end
end
