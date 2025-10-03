classdef LJbox < handle
    %LJBOX Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Access = private)
        % settings for .NET assembly, private because the user won't need them
        ljmAsm 
        LJM_CONSTANTS
        time
        handle
    end
    
    properties(Access = public)
    % data and other relevant properties for data collection and signal output from the labjack  
        scanTime
        scanRate
        scanNum
        
        % for analog recording
        numAIN
        rawdata
        aNames
        aTypes
        aValues
        anumFrames
        aScanList
        aScanListNames
        aScanRate
        
        % for combined Analog/Digital Recording
        numIN
        cNames
        cTypes
        cValues
        cnFrames
        cScanList
        cScanListNames
        
     % for DIO, PWM outputs
        ascanNUM
        signal_length
        
    end
    
    methods
        
        function setup(obj)
            %LJBOX Construct an instance of this class
            %   Detailed explanation goes here
            obj.ljmAsm = NET.addAssembly('Labjack.LJM');
            obj.time = obj.ljmAsm.AssemblyHandle.GetType('LabJack.LJM+CONSTANTS');
            obj.LJM_CONSTANTS = System.Activator.CreateInstance(obj.time);
            
        end
        
        function connect(obj)
            % connects to a labjack T7 device
            % *** NOTE to set this up for multiple devices****
            [ljmError, obj.handle] = LabJack.LJM.OpenS('T7','ANY','ANY',0);
            
        end

        function analogSetup(obj,numAIN,scantime,scanrate)
            % This sets up the labjack to only record analog signals for
            % scantime and scanrate. This sets up the labjack for a "burst"
            % run where it will record continously for the specified time
            %
            % Inputs:
            % --------------------
            % scantime :=  number of seconds to scan for
            % scanrate :=  sample rate, typically 1e3 +
            % numAIN   :=  number of analog inputs to labjack
            %   
            % The actual input for labjack is the number of scans, which is
            % backed out by scanNum = scantime * scanrate. This also means that the
            % dt between scans is approximate and chnages with scanNum. If
            % detailed time steps are required, one should refer to labjack
            % examples and use this code as a base
            
            
            % create list of channel names
            obj.numAIN          = numAIN;
            obj.scanNum         = scanrate;
            obj.anumFrames      = numAIN + 3;
            obj.aScanRate       = scanrate;
            obj.scanTime        = scantime;
            obj.ascanNUM        = scanrate*scantime;
            obj.aScanListNames  = NET.createArray('System.String',obj.numAIN);
            
            % adds cahnnels for each AIN
            for chan = 1:numAIN
               obj.aScanListNames(chan) = sprintf("AIN%s",num2str(chan-1));  
            end
 
            % create arrays of size numAIN
            obj.aTypes = NET.createArray('System.Int32',numAIN);
            obj.aScanList = NET.createArray('System.Int32',numAIN);
            
            
            % Assign each AIN to Labjack address
            LabJack.LJM.NamesToAddresses(obj.numAIN,obj.aScanListNames,...
                obj.aScanList,obj.aTypes);
            
            
            % create vector for data storage
            obj.rawdata = NET.createArray('System.Double',obj.numAIN*obj.ascanNUM);
            
            %skips directly to Labjack T7 setup
            %disable triggered stream and clock to reset
            LabJack.LJM.eWriteName(obj.handle,'STREAM_TRIGGER_INDEX',0);
            LabJack.LJM.eWriteName(obj.handle, 'STREAM_CLOCK_SOURCE', 0);
            %enable internally-clocked stream
            
            
            % All negative channels are single-ended, AIN ranges are
            % +/-10 V, stream settling is 0 (default) and stream resolution index
            % is 0 (default).
            
            obj.aNames = NET.createArray('System.String', obj.anumFrames);
            obj.aValues = NET.createArray('System.Double',obj.anumFrames);
            obj.aNames(1) = 'AIN_ALL_NEGATIVE_CH';
            obj.aValues(1) = obj.LJM_CONSTANTS.GND;
            
            
            for N = 1:obj.numAIN
                obj.aNames(N+1) = sprintf("AIN%s_RANGE",num2str(N));
                obj.aValues(N+1) = 10;
            end
            
            
            obj.aNames(numAIN+2) = 'STREAM_RESOLUTION_INDEX';
            obj.aNames(numAIN+3) = 'STREAM_SETTLING_US';
            obj.aValues(numAIN+2) = 0;
            obj.aValues(numAIN+3) = 0;
            
            LabJack.LJM.eWriteNames(obj.handle,obj.anumFrames, ...
                obj.aNames,obj.aValues,-1);
        end
        
        
        function setupPWMout(obj)
        %sets up and starts a PWM output from Labjack, this can be changed before 
        % the start of any stream of data, and will continue until changed again
        %
        % ***NOTE***  best practice is to always set motors back to 0 after each run
        % otherwise, it is likely that they will burn out if at high RPMs
        % 
        % this setup function will always intialize a motor at PWM = 1000, function below
        % will change the actual
        %
        % channel is always outputting PWM signal after DIO0,EF_ENABLE,1 line
        
        obj.signal_length = 1640000;

            name = "DIO0";
            % configure clock registers
            
            %turn clock off
            LabJack.LJM.eWriteName(obj.handle,"DIO_EF_CLOCK0_ENABLE",0);
            
            % set clock0's divsor and roll value to configure frequency
            LabJack.LJM.eWriteName(obj.handle,'DIO_EF_CLOCK0_DIVISOR',1);
            LabJack.LJM.eWriteName(obj.handle,"DIO_EF_CLOCK0_ROLL_VALUE",obj.signal_length)
            
            %turn clock back on
            LabJack.LJM.eWriteName(obj.handle,"DIO_EF_CLOCK0_ENABLE",1);
            
            
            % set intitial value to PWM = 1000
            % set low value
            LabJack.LJM.eWriteName(obj.handle, sprintf("%s_EF_ENABLE",name),0); 	%// Disable the EF system for initial configuration
            LabJack.LJM.eWriteName(obj.handle, sprintf("%s_EF_INDEX",name), 0); 	%// Configure EF system for PWM
            LabJack.LJM.eWriteName(obj.handle, sprintf("%s_EF_OPTIONS", name),000); 	%// Configure what clock source to use Clock0
            LabJack.LJM.eWriteName(obj.handle, sprintf("%s_EF_CONFIG_A",name), 80*1000); 	%// Configure duty cycle to be slightly less than 1000
            LabJack.LJM.eWriteName(obj.handle, sprintf("%s_EF_ENABLE",name), 1); 	%// Enable the EF system, PWM wave is now being outputted
            
            % set high value
            %LabJack.LJM.eWriteName(obj.handle,"DIO_EF_CLOCK0_DIVISOR",1); %RECONFIGURE DIVISOR
            %LabJack.LJM.eWriteName(obj.handle,"DIO_EF_CLOCK0_ROLL_VALUE",obj.signal_length); %RECONFIGURE ROLL VALUE
            %LabJack.LJM.eWriteName(obj.handle,sprintf("%s_EF_CONFIG_a",name),80*1000); % set to PWM < 1000
            
            %DUTY cycle info
            % 80000 ~ 1000 PWM, 16000 ~ 2000 PWM (slightly less)
            % states 1 = output_high, 0 = output_low
            %LabJack.LJM.eWriteName(handle,name,state)
        end
 
% set up or changre PWM out        
        function changePWMout(obj,PWM)
            % changes the PWM output from the labjack to specified value
            % channel is streaming the whole time
             
            LabJack.LJM.eWriteName(obj.handle,"DIO0_EF_ENABLE",0);
            LabJack.LJM.eWriteName(obj.handle,"DIO0_EF_INDEX", 0); 	%// Configure EF system for PWM
            LabJack.LJM.eWriteName(obj.handle, "DIO0_EF_OPTIONS",000); 	%// Configure what clock source to use: Clock0
            LabJack.LJM.eWriteName(obj.handle, "DIO0_EF_CONFIG_A", 80*PWM);
            LabJack.LJM.eWriteName(obj.handle,"DIO0_EF_ENABLE",1);
        end

        
% For SSTOL project setup has PWMout and AnalogIN
        function data = recordData(obj)
            % 
            %
            %
            %
            %
            
            [~, scanrate] = LabJack.LJM.StreamBurst(obj.handle, obj.numAIN, obj.aScanList, obj.aScanRate, obj.scanNum, obj.rawdata);
            % runs the "StreamBurst" function for
            
            % create matrix to store obj.rawdata which is output as a
            % 1xN vector
            for ii = 1:(obj.ascanNUM)
                for jj = 1:obj.numAIN
                    data(jj,ii) = obj.rawdata(jj+obj.numAIN*(ii-1));
                end
            end
            
            
        end
        
        function SSTOLsetup(obj)
    %        sets up the burst stream for SSTOL
    %        
    %        AIN0: Lift
    %        AIN1: Drag
    %        AIN2: Moment
    %        AIN3: Angle
    %        AIN4: Temperature (temporary, sanity check sensor)
    %        AIN5: Baratron (temporary, sanity check sensor)
    %        AIN6: None
    %        FIO0: PWMout
    %        FIO1: RPM 1 in
    %        FIO2: RPM 2 in
    %        FIO3: RPM 3 in
    %        FIO4: RPM 4 in
    %        Internal: Internal Counter

            
            obj.scanNum = obj.scanTime * obj.scanRate;
            
            
    %% setup up channels
            obj.numIN = 11; % number of total inputs
            obj.cScanListNames = NET.createArray('System.String',obj.numIN+1);
            obj.cTypes = NET.createArray('System.Int32',obj.numIN);
            obj.cScanList = NET.createArray('System.Int32',obj.numIN);
            obj.rawdata = NET.createArray('System.Double',obj.scanNum*obj.numIN);

            obj.cScanListNames(1) = 'AIN0';
            obj.cScanListNames(2) = 'AIN1';
            obj.cScanListNames(3) = 'AIN2';
            obj.cScanListNames(4) = 'AIN3';
            obj.cScanListNames(5) = 'AIN4';
            obj.cScanListNames(6) = 'AIN5';
            obj.cScanListNames(7) = 'AIN6';
            obj.cScanListNames(8) = 'DIO1_EF_READ_A_AND_RESET';
            obj.cScanListNames(9) = 'DIO2_EF_READ_A_AND_RESET';
            obj.cScanListNames(10) = 'DIO3_EF_READ_A_AND_RESET';
            obj.cScanListNames(11) = 'DIO6_EF_READ_A_AND_RESET';
            obj.cScanListNames(12) = 'STREAM_DATA_CAPTURE_16'; % I forget what this does, but I think it's accuracy

            
            % get LabJack address for inputs above
            LabJack.LJM.NamesToAddresses(obj.numIN,obj.cScanListNames,obj.cScanList,obj.cTypes)


            % set up DIO to count pulses (to count RPM)
            LabJack.LJM.eWriteName(obj.handle,sprintf('DIO1_EF_ENABLE'),0)
            LabJack.LJM.eWriteName(obj.handle,sprintf('DIO2_EF_ENABLE'),0)
            LabJack.LJM.eWriteName(obj.handle,sprintf('DIO3_EF_ENABLE'),0)
            LabJack.LJM.eWriteName(obj.handle,sprintf('DIO6_EF_ENABLE'),0)
            
            % number of channels being recorded
            obj.cnFrames = 11;
            obj.cNames = NET.createArray('System.String',obj.cnFrames);
            
            
            obj.cNames(1) = 'AIN_ALL_NEGATIVE_CH';
            obj.cNames(2) = 'AIN0_RANGE';
            obj.cNames(3) = 'AIN1_RANGE';
            obj.cNames(4) = 'AIN2_RANGE';
            obj.cNames(5) = 'AIN3_RANGE';
%             obj.cNames(6) = 'AIN4_RANGE'; % not currently used
%             obj.cNames(7) = 'AIN5_RANGE'; % not currently used
%             obj.cNames(8) = 'AIN6_RANGE'; % not currently used
            obj.cNames(6) = 'STREAM_SETTLING_US';
            obj.cNames(7) = 'STREAM_RESOLUTION_INDEX';
            obj.cNames(8) = 'DIO1_EF_INDEX';
            obj.cNames(9) = 'DIO2_EF_INDEX';
            obj.cNames(10) = 'DIO3_EF_INDEX';
            obj.cNames(11) = 'DIO6_EF_INDEX';

            
            obj.cValues = NET.createArray('System.Double',obj.cnFrames);
            obj.cValues(1) = obj.LJM_CONSTANTS.GND;
            obj.cValues(2) = 10.0;
            obj.cValues(3) = 10.0;
            obj.cValues(4) = 10.0;
            obj.cValues(5) = 10.0;
%             obj.cValues(6) = 10.0; % not currently used
%             obj.cValues(7) = 10.0; % not currently used
%             obj.cValues(8) = 10.0; % not currently used
            obj.cValues(6) = 0;
            obj.cValues(7) = 7;
            obj.cValues(8) = 8;
            obj.cValues(9) = 8;
            obj.cValues(10) = 8;
            obj.cValues(11) = 8;
  
            % 
            LabJack.LJM.eWriteNames(obj.handle,obj.cnFrames,obj.cNames,obj.cValues,-1);
            LabJack.LJM.eWriteName(obj.handle,sprintf('DIO1_EF_ENABLE'),1)
            LabJack.LJM.eWriteName(obj.handle,sprintf('DIO2_EF_ENABLE'),1)
            LabJack.LJM.eWriteName(obj.handle,sprintf('DIO3_EF_ENABLE'),1)
            LabJack.LJM.eWriteName(obj.handle,sprintf('DIO6_EF_ENABLE'),1)
        end
        
% MotorMap
        
        function motorMapSetup(obj)
    %        Set up to run
    %        
    %        AIN0: Baratron
    %        AIN1: X-force cell
    %        AIN2: None
    %        AIN3: None
    %        AIN4: None
    %        AIN5: None
    %        AIN6: None
    %        DIO0: PWMout ( set up in setPWM)
    %        DIO1: RPM 1 in
    %        DIO2: None
    %        DIO3: None
    %        DIO4: None
    %        Internal: Internal Counter

    

            
            obj.scanNum = obj.scanRate * obj.scanTime;
            
            
    %% setup up channels
            obj.numIN = 3; % number of total inputs
            obj.cScanListNames = NET.createArray('System.String',obj.numIN+1);
            obj.cTypes = NET.createArray('System.Int32',obj.numIN);
            obj.cScanList = NET.createArray('System.Int32',obj.numIN);
            obj.rawdata = NET.createArray('System.Double',obj.scanNum*obj.numIN);

            obj.cScanListNames(1) = 'AIN0';
            obj.cScanListNames(2) = 'AIN1';
            obj.cScanListNames(3) = 'DIO1_EF_READ_A_AND_RESET';
            obj.cScanListNames(4) = 'STREAM_DATA_CAPTURE_16'; % I forget what this does, but I think it's accuracy

            
            % get LabJack address for inputs above
            LabJack.LJM.NamesToAddresses(obj.numIN,obj.cScanListNames,obj.cScanList,obj.cTypes)


            % set up DIO to count pulses (to count RPM)
            LabJack.LJM.eWriteName(obj.handle,sprintf('DIO1_EF_ENABLE'),0)
            
            % number of channels being recorded
            obj.cnFrames = 3;
            obj.cNames = NET.createArray('System.String',obj.cnFrames);
            
            
            obj.cNames(1) = 'AIN_ALL_NEGATIVE_CH';
            obj.cNames(2) = 'AIN0_RANGE';
            obj.cNames(3) = 'AIN1_RANGE';
            obj.cNames(4) = 'STREAM_SETTLING_US';
            obj.cNames(5) = 'STREAM_RESOLUTION_INDEX';
            obj.cNames(6) = 'DIO1_EF_INDEX';

            
            obj.cValues = NET.createArray('System.Double',obj.cnFrames);
            obj.cValues(1) = obj.LJM_CONSTANTS.GND;
            obj.cValues(2) = 10.0;
            obj.cValues(3) = 10.0;
            obj.cValues(4) = 0;
            obj.cValues(5) = 7;
            obj.cValues(6) = 8;
  
            % re-enable DIO clocks ??
            LabJack.LJM.eWriteNames(obj.handle,obj.cnFrames,obj.cNames,obj.cValues,-1);
            LabJack.LJM.eWriteName(obj.handle,sprintf('DIO1_EF_ENABLE'),1)
            
        end

% Used to run StreamBurst with SSTOL tunnel setup
% example of usage is in collectData.m
        function data = recordData2(obj)
            [~] = LabJack.LJM.StreamBurst(obj.handle, obj.numIN, obj.cScanList, obj.scanRate, obj.scanNum, obj.rawdata);      
            for ii = 1:(obj.numIN*obj.scanTime*obj.scanRate)
                    data(ii) = obj.rawdata(ii);             
            end
            data = reshape(data,obj.numIN,[]);
        end
        
    end
end

